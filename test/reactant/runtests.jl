# Reactant compatibility of NumericalRadiation's kernel path: the lookup-table brackets, the
# gas optics, the Planck sources and the streaming column solvers, evaluated per column inside
# KernelAbstractions kernels, compiled by Reactant and checked against the same kernels run
# natively; and the gradient of the outgoing longwave radiation, differentiated by Enzyme
# through Reactant and checked against finite differences. Tables are bracketed with
# `FixedBinarySearch()` or `DirectIndexing()`: the default `BinarySearch()` stops each search
# when it finds its interval, a data-dependent loop that Reactant cannot compile in a kernel.

using NumericalRadiation
using NumericalRadiation: bracket
using KernelAbstractions
using CUDA # needed by Reactant to compile KernelAbstractions kernels, whatever the backend
using Reactant
using Enzyme
using Test

Reactant.set_default_backend("cpu")

#####
##### Tables
#####

# An ecCKD-like model with a pressure-dependent temperature grid, an H₂O table and a uniform
# Planck table, indexed directly
function matrix_grid_model(FT)
    Np, NT, Nh, Ngˡʷ, Ngˢʷ, Ngases = 4, 3, 3, 3, 2, 3
    pressure_grid = FT.(exp.(range(log(5_000.0), log(100_000.0), length=Np)))
    temperature_grid = FT[180 + 30 * (iᵖ - 1) + 40 * (iᵀ - 1) for iᵖ in 1:Np, iᵀ in 1:NT]
    source_temperature_grid = FT[180, 240, 300]
    return EcCKDTabulatedGasOpticsModel(
        names = (:h2o, :co2, :composite),
        pressure_grid = pressure_grid,
        temperature_grid = temperature_grid,
        water_vapor_mole_fraction_grid = FT[1e-6, 1e-4, 1e-2],
        gas_reference_mole_fractions = FT[0, 4e-4, 0],
        longwave_absorption = FT[1e-4 * (7g + 3j) * (1 + 1e-5 * pressure_grid[iᵖ]) * (1 + 1e-3 * temperature_grid[iᵖ, iᵀ])
                                 for g in 1:Ngˡʷ, j in 1:Ngases, iᵖ in 1:Np, iᵀ in 1:NT],
        shortwave_absorption = FT[1e-5 * (5g + 2j) * (1 + 2e-5 * pressure_grid[iᵖ]) * (1 + 2e-3 * temperature_grid[iᵖ, iᵀ])
                                  for g in 1:Ngˢʷ, j in 1:Ngases, iᵖ in 1:Np, iᵀ in 1:NT],
        longwave_water_vapor_absorption = FT[1e-3 * g * (1 + 10iᴴ) for g in 1:Ngˡʷ, iᵖ in 1:Np, iᵀ in 1:NT, iᴴ in 1:Nh],
        shortwave_water_vapor_absorption = FT[1e-4 * g * (1 + 5iᴴ) for g in 1:Ngˢʷ, iᵖ in 1:Np, iᵀ in 1:NT, iᴴ in 1:Nh],
        shortwave_rayleigh_molar_scattering = FT[1.1e-6, 3.7e-6],
        longwave_source_temperature_grid = source_temperature_grid,
        longwave_source_table = FT[(g + 2) * st^2 for g in 1:Ngˡʷ, st in source_temperature_grid],
        longwave_weights = FT[0.2, 0.3, 0.5],
        shortwave_weights = FT[0.45, 0.55],
        lookup_search = DirectIndexing())
end

# A model with a nonuniform temperature vector, which brackets the temperature by a fixed-count
# bisection, and the gray Planck source
function vector_grid_model(FT)
    Np, NT, Ngˡʷ, Ngˢʷ, Ngases = 3, 6, 2, 2, 3
    pressure_grid = FT.(exp.(range(log(5_000.0), log(100_000.0), length=Np)))
    temperature_grid = FT[170, 200, 215, 240, 270, 320]
    return EcCKDTabulatedGasOpticsModel(
        names = (:h2o, :co2, :composite),
        pressure_grid = pressure_grid,
        temperature_grid = temperature_grid,
        gas_reference_mole_fractions = FT[0, 4e-4, 0],
        longwave_absorption = FT[2e-4 * (3g + j) * (1 + 1e-5 * pressure_grid[iᵖ]) * (1 + 3e-3 * sin(temperature_grid[iᵀ] / 20))
                                 for g in 1:Ngˡʷ, j in 1:Ngases, iᵖ in 1:Np, iᵀ in 1:NT],
        shortwave_absorption = FT[1e-5 * (g + j) for g in 1:Ngˢʷ, j in 1:Ngases, iᵖ in 1:Np, iᵀ in 1:NT],
        longwave_weights = FT[0.4, 0.6],
        shortwave_weights = FT[0.5, 0.5],
        lookup_search = FixedBinarySearch())
end

#####
##### Columns: layer state in (column, layer) arrays, top-down
#####

function column_state(FT, Nc, Nz)
    pressure = FT[6_000 * (100_000 / 6_000)^((k - 0.5) / Nz) * (1 + 0.01c) for c in 1:Nc, k in 1:Nz]
    temperature = FT[205 + 85 * (k - 0.5) / Nz + 3c for c in 1:Nc, k in 1:Nz]
    temperature_interfaces = FT[202 + 85 * (k - 1) / Nz + 3c for c in 1:Nc, k in 1:Nz+1]
    dry_air = FT[100 + 900 * k / Nz for c in 1:Nc, k in 1:Nz]
    water_vapor = FT[dry_air[c, k] * 1e-5 * 10^(3 * k / Nz) * (1 + 0.2c) for c in 1:Nc, k in 1:Nz]
    return (; pressure, temperature, temperature_interfaces, dry_air, water_vapor)
end

struct ColumnOptics{S, M, A}
    model :: M
    state :: A
    column :: Int
end

ColumnOptics{S}(model, state, column) where S = ColumnOptics{S, typeof(model), typeof(state)}(model, state, column)

@inline function layer_gases_and_stencil(optics, k)
    state, c = optics.state, optics.column
    @inbounds begin
        p = state.pressure[c, k]
        T = state.temperature[c, k]
        h = state.water_vapor[c, k]
        d = state.dry_air[c, k]
    end
    gases = (h2o = h, co2 = 8 * h / 10 + d / 1250, composite = d)
    return gases, gas_optics_stencil(optics.model, p, T, h / d)
end

@inline planck(model, g, T) = longwave_source(model, g, T, source_table_bracket(model, T))

@inline function (optics::ColumnOptics{:longwave})(g, k)
    model = optics.model
    gases, stencil = layer_gases_and_stencil(optics, k)
    τ = longwave_optical_depth(model, g, gases, stencil)
    @inbounds begin
        Tₖ = optics.state.temperature_interfaces[optics.column, k]
        Tₖ₊₁ = optics.state.temperature_interfaces[optics.column, k + 1]
    end
    return τ, planck(model, g, Tₖ), planck(model, g, Tₖ₊₁)
end

@inline function (optics::ColumnOptics{:shortwave})(g, k)
    model = optics.model
    gases, stencil = layer_gases_and_stencil(optics, k)
    τₐ = shortwave_optical_depth(model, g, gases, stencil)
    τₛ = rayleigh_optical_depth(model, g, gases.composite)
    return τₐ, τₛ, zero(τₛ)
end

@kernel function _longwave_columns!(flux_up, flux_down, transmittance, source_up, model, state)
    c = @index(Global, Linear)
    Nz = size(state.pressure, 2)
    optics = ColumnOptics{:longwave}(model, state, c)
    @inbounds emission = TabulatedSurfaceEmission(model, state.temperature_interfaces[c, Nz + 1]; emissivity = 0.98)
    streaming_longwave_fluxes!(view(flux_up, c, :), view(flux_down, c, :), optics, emission, 0.02, 0,
                               model.longwave_weights, length(model.longwave_weights), Nz,
                               view(transmittance, c, :), view(source_up, c, :))
end

@kernel function _shortwave_columns!(flux_up, flux_down, layer_scratch, interface_scratch, model, state)
    c = @index(Global, Linear)
    Nz = size(state.pressure, 2)
    optics = ColumnOptics{:shortwave}(model, state, c)
    row(A) = view(A, c, :)
    scratch = ShortwaveColumnScratch(map(row, layer_scratch)..., map(row, interface_scratch)...)
    streaming_shortwave_fluxes!(view(flux_up, c, :), view(flux_down, c, :), optics, 0.6, 1361 * 0.6, 0.1, 0.1,
                                model.shortwave_weights, length(model.shortwave_weights), Nz, scratch)
end

function longwave_columns!(flux_up, flux_down, transmittance, source_up, model, state)
    backend = KernelAbstractions.get_backend(flux_up)
    _longwave_columns!(backend)(flux_up, flux_down, transmittance, source_up, model, state; ndrange = size(flux_up, 1))
    return nothing
end

function shortwave_columns!(flux_up, flux_down, layer_scratch, interface_scratch, model, state)
    backend = KernelAbstractions.get_backend(flux_up)
    _shortwave_columns!(backend)(flux_up, flux_down, layer_scratch, interface_scratch, model, state; ndrange = size(flux_up, 1))
    return nothing
end

function longwave_storage(FT, Nc, Nz)
    return (flux_up = zeros(FT, Nc, Nz + 1), flux_down = zeros(FT, Nc, Nz + 1),
            transmittance = zeros(FT, Nc, Nz), source_up = zeros(FT, Nc, Nz))
end

# The outgoing longwave radiation summed over the columns
function outgoing_longwave(storage, model, state)
    longwave_columns!(storage.flux_up, storage.flux_down, storage.transmittance, storage.source_up, model, state)
    return sum(view(storage.flux_up, :, 1))
end

function outgoing_longwave_gradient!(dstate, storage, dstorage, model, state)
    Enzyme.autodiff(Enzyme.Reverse, outgoing_longwave, Enzyme.Active,
                    Enzyme.Duplicated(storage, dstorage), Enzyme.Const(model), Enzyme.Duplicated(state, dstate))
    return nothing
end

host(x) = Array(x)

const FT = Float64
const Nc, Nz = 3, 6

@testset "Reactant compatibility" begin
    @testset "Table brackets in a kernel: $search" for (search, knots) in
            ((FixedBinarySearch(), FT[0, 0.5, 2, 3.5, 4, 7, 7.5, 11, 12, 15, 21]),
             (DirectIndexing(), FT.(collect(range(0, 21; length = 11)))))
        @kernel function _interpolate!(y, x, knots, values, search)
            i = @index(Global, Linear)
            i₀, i₁, w = bracket(knots, @inbounds(x[i]), search)
            @inbounds y[i] = (1 - w) * values[i₀] + w * values[i₁]
        end
        function interpolate!(y, x, knots, values, search)
            _interpolate!(KernelAbstractions.get_backend(y))(y, x, knots, values, search; ndrange = length(y))
            return nothing
        end
        values = knots .^ 2 .- 3 .* knots
        # Off the table, on every node and between nodes
        x = vcat(FT[-1, 30], knots, range(-0.5, 22; length = 61))
        y = similar(x)
        interpolate!(y, x, knots, values, search)
        rx, rknots, rvalues = Reactant.to_rarray.((x, knots, values))
        ry = Reactant.to_rarray(zero(x))
        compiled = Reactant.@compile raise=true interpolate!(ry, rx, rknots, rvalues, search)
        compiled(ry, rx, rknots, rvalues, search)
        @test host(ry) ≈ y
    end

    state = column_state(FT, Nc, Nz)
    rstate = Reactant.to_rarray(state)

    for (name, model) in (("matrix temperature grid, Planck table", matrix_grid_model(FT)),
                          ("vector temperature grid, gray source", vector_grid_model(FT)))
        @testset "Longwave columns: $name" begin
            storage = longwave_storage(FT, Nc, Nz)
            longwave_columns!(storage..., model, state)
            rmodel = Reactant.to_rarray(model)
            rstorage = Reactant.to_rarray(longwave_storage(FT, Nc, Nz))
            compiled = Reactant.@compile raise=true longwave_columns!(rstorage..., rmodel, rstate)
            compiled(rstorage..., rmodel, rstate)
            @test all(isfinite, storage.flux_up) && maximum(storage.flux_up) > 0
            @test host(rstorage.flux_up) ≈ storage.flux_up
            @test host(rstorage.flux_down) ≈ storage.flux_down
        end
    end

    @testset "Shortwave columns" begin
        model = matrix_grid_model(FT)
        flux_up, flux_down = zeros(FT, Nc, Nz + 1), zeros(FT, Nc, Nz + 1)
        layer_scratch = ntuple(_ -> zeros(FT, Nc, Nz), 5)
        interface_scratch = ntuple(_ -> zeros(FT, Nc, Nz + 1), 2)
        shortwave_columns!(flux_up, flux_down, layer_scratch, interface_scratch, model, state)
        r = Reactant.to_rarray((flux_up = zero(flux_up), flux_down = zero(flux_down),
                                layer_scratch, interface_scratch, model))
        compiled = Reactant.@compile raise=true shortwave_columns!(r.flux_up, r.flux_down, r.layer_scratch,
                                                                   r.interface_scratch, r.model, rstate)
        compiled(r.flux_up, r.flux_down, r.layer_scratch, r.interface_scratch, r.model, rstate)
        @test maximum(flux_down) > 0
        @test host(r.flux_up) ≈ flux_up
        @test host(r.flux_down) ≈ flux_down
    end

    @testset "Gradient of the outgoing longwave radiation" begin
        model = matrix_grid_model(FT)
        rmodel = Reactant.to_rarray(model)
        rstorage = Reactant.to_rarray(longwave_storage(FT, Nc, Nz))
        rdstorage = Reactant.to_rarray(longwave_storage(FT, Nc, Nz))
        rdstate = Reactant.to_rarray(map(zero, state))
        # Kernels are raised to StableHLO before Enzyme differentiates them
        options = CompileOptions(; raise_first = true, raise = true)
        compiled = Reactant.@compile compile_options=options outgoing_longwave_gradient!(rdstate, rstorage, rdstorage, rmodel, rstate)
        compiled(rdstate, rstorage, rdstorage, rmodel, rstate)
        gradient = map(host, rdstate)
        @test all(a -> all(isfinite, a), gradient)

        # Centred finite differences of the native kernel, at layers and interfaces of each column
        function finite_difference(name, c, k; h = 1e-4)
            perturbed(δ) = (s = map(copy, state); getproperty(s, name)[c, k] += δ; s)
            Lp = outgoing_longwave(longwave_storage(FT, Nc, Nz), model, perturbed(h))
            Lm = outgoing_longwave(longwave_storage(FT, Nc, Nz), model, perturbed(-h))
            return (Lp - Lm) / 2h
        end
        agrees = [isapprox(getproperty(gradient, name)[c, k],
                           finite_difference(name, c, k; h = 1e-4 * abs(getproperty(state, name)[c, k]));
                           rtol = 1e-5, atol = 1e-9)
                  for name in (:temperature, :temperature_interfaces, :water_vapor, :pressure), c in 1:Nc
                  for k in (1, Nz ÷ 2, size(getproperty(state, name), 2))]

        # The gradient compiles and runs, but Reactant (0.2.294, Reactant_jll 0.0.423) gets it wrong,
        # because of two Reactant bugs that need no NumericalRadiation to reproduce. Natively, Enzyme
        # gives these gradients to finite-difference accuracy.
        # 1. In a kernel loop whose increment does not depend on the loop counter, the increment is
        #    differentiated once: `s += x^2` over three iterations gives ∂s/∂x = 2x, not 6x. Every
        #    g-point loop over a layer's stencil or Planck bracket is such a loop.
        # 2. `x - unsafe_trunc(Int, x)` differentiates to 0, not 1: the bracket weights lose their
        #    derivative.
        @test_broken all(agrees)
    end
end

# The lookup derivatives of the Planck source and cloud radius tables (fixed binary search)
include(joinpath(@__DIR__, "..", "reactant_lookup_search.jl"))
