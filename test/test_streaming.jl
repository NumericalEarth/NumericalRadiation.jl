module TestStreaming
using Test
using NumericalRadiation
using NCDatasets   # extension trigger for the reference ecCKD reader

# The scalar per-layer gas optics of `src/gas_optics/ecckd_layer.jl` is the
# kernel-facing form of `optical_properties!`: a host builds one stencil per
# layer and calls the `*_optical_depth` / `longwave_source` functions per
# g point with scalar gas amounts. These tests pin (1) bitwise agreement of
# that scalar loop with the array methods, on the 2-layer fixed-coefficient
# model of `access_points_check.jl` and on the reference `climate_32x32`
# tables, and (2) inferrability and zero allocation of every scalar function.

const σ_SB = 5.670374419e-8
const GRAVITY = 9.80665
const DRY_AIR_MOLAR_MASS = 0.0289647
const WATER_MOLAR_MASS = 0.01801528

# Scalar gas amounts of layer `k` from a column container of per-layer vectors
# and column-wide scalars, built the way a host kernel would (not through
# `layer_gases`, which is tested separately against this).
layer_scalars(gases::NamedTuple, k) = map(value -> value isa Number ? value : value[k], gases)

# The scalar loop a host kernel runs: stencil once per layer, then one call
# per g point. `air_moles` is the hydrostatic molar amount `Δp / (g mᵈ)`.
function scalar_optical_properties!(longwave, shortwave, model, atmosphere)
    FT = eltype(model)
    nlayers = length(atmosphere.temperature_layers)
    interface_sources = longwave.source_top !== nothing
    for k in 1:nlayers
        gases = layer_scalars(atmosphere.gases, k)
        pressure = atmosphere.pressure_layers[k]
        temperature = atmosphere.temperature_layers[k]
        Δp = atmosphere.pressure_interfaces[k + 1] - atmosphere.pressure_interfaces[k]
        air_moles = FT(Δp) / (FT(GRAVITY) * FT(DRY_AIR_MOLAR_MASS))
        # H2O mole fraction relative to dry air: the `composite` amount when
        # the column carries one, else the hydrostatic molar amount.
        dry_air = haskey(gases, :composite) ? gases.composite : air_moles
        h2o_mole_fraction = haskey(gases, :h2o) ? gases.h2o / dry_air : zero(FT)

        stencil = gas_optics_stencil(model, pressure, temperature, h2o_mole_fraction)
        source_bracket = source_table_bracket(model, temperature)
        for ig in eachindex(model.longwave_weights)
            longwave.optical_depth[ig, k] = longwave_optical_depth(model, ig, gases, stencil)
            longwave.source[ig, k] = longwave_source(model, ig, temperature, source_bracket)
            if interface_sources
                T_top = atmosphere.temperature_interfaces[k]
                T_bottom = atmosphere.temperature_interfaces[k + 1]
                longwave.source_top[ig, k] =
                    longwave_source(model, ig, T_top, source_table_bracket(model, T_top))
                longwave.source_bottom[ig, k] =
                    longwave_source(model, ig, T_bottom, source_table_bracket(model, T_bottom))
            end
        end
        for ig in eachindex(model.shortwave_weights)
            shortwave.optical_depth[ig, k] = shortwave_optical_depth(model, ig, gases, stencil)
            shortwave.rayleigh_optical_depth[ig, k] = rayleigh_optical_depth(model, ig, air_moles)
            shortwave.scattering_asymmetry[ig, k] = zero(FT)
        end
    end
    longwave.weights .= model.longwave_weights
    shortwave.weights .= model.shortwave_weights
    return longwave, shortwave
end

function optics_arrays(FT, ng_lw, ng_sw, nlayers; interface_sources)
    longwave = LongwaveOptics(zeros(FT, ng_lw, nlayers), zeros(FT, ng_lw, nlayers);
                              source_top = interface_sources ? zeros(FT, ng_lw, nlayers) : nothing,
                              source_bottom = interface_sources ? zeros(FT, ng_lw, nlayers) : nothing,
                              weights = zeros(FT, ng_lw))
    shortwave = ShortwaveOptics(zeros(FT, ng_sw, nlayers); weights = zeros(FT, ng_sw))
    return longwave, shortwave
end

function assert_scalar_matches_array(model, atmosphere; interface_sources)
    FT = eltype(model)
    nlayers = length(atmosphere.temperature_layers)
    ng_lw, ng_sw = length(model.longwave_weights), length(model.shortwave_weights)
    array_lw, array_sw = optics_arrays(FT, ng_lw, ng_sw, nlayers; interface_sources)
    scalar_lw, scalar_sw = optics_arrays(FT, ng_lw, ng_sw, nlayers; interface_sources)
    optical_properties!(array_lw, array_sw, model, atmosphere)
    scalar_optical_properties!(scalar_lw, scalar_sw, model, atmosphere)

    @test all(isfinite, array_lw.optical_depth)
    @test !all(iszero, array_lw.optical_depth)
    @test scalar_lw.optical_depth == array_lw.optical_depth
    @test scalar_lw.source == array_lw.source
    if interface_sources
        @test scalar_lw.source_top == array_lw.source_top
        @test scalar_lw.source_bottom == array_lw.source_bottom
    end
    @test scalar_sw.optical_depth == array_sw.optical_depth
    @test scalar_sw.rayleigh_optical_depth == array_sw.rayleigh_optical_depth
    @test scalar_sw.scattering_asymmetry == array_sw.scattering_asymmetry
    @test scalar_lw.weights == array_lw.weights
    @test scalar_sw.weights == array_sw.weights
    return nothing
end

# The 2-layer fixed-coefficient model and column of `component_smoke()` in
# `access_points_check.jl`.
function smoke_fixture()
    atmosphere = ColumnAtmosphere(
        pressure_layers = [20_000.0, 70_000.0],
        pressure_interfaces = [1_000.0, 45_000.0, 100_000.0],
        temperature_layers = [240.0, 285.0],
        temperature_interfaces = [230.0, 260.0, 295.0],
        gases = (; h2o = [0.002, 0.014], co2 = 420.0e-6),
        surface = (; temperature = 295.0, albedo = 0.1),
        geometry = (; cos_zenith = 0.5),
    )
    model = EcCKDGasOpticsModel(
        names = (:h2o, :co2),
        longwave_absorption = [0.08 0.004; 0.03 0.002],
        shortwave_absorption = [0.010 0.0008],
        longwave_source_scale = [1.0, 1.05],
        longwave_weights = [0.55, 0.45],
        shortwave_weights = [1.0],
    )
    return model, atmosphere
end

# Synthetic tabulated model with every optional table populated (matrix
# temperature grid, H2O table, Rayleigh, Planck source table) in one `FT`.
function tabulated_fixture(FT)
    np, nt, nh2o = 4, 3, 3
    ng_lw, ng_sw, ngas = 3, 2, 3
    pressure_grid = FT.(exp.(range(log(5_000.0), log(100_000.0), length = np)))
    temperature_grid = FT[180 + 30 * (ip - 1) + 40 * (it - 1) for ip in 1:np, it in 1:nt]
    source_temperature_grid = FT[180, 240, 300]
    model = EcCKDTabulatedGasOpticsModel(
        names = (:h2o, :co2, :composite),
        pressure_grid = pressure_grid,
        temperature_grid = temperature_grid,
        h2o_mole_fraction_grid = FT[1e-6, 1e-4, 1e-2],
        gas_reference_mole_fractions = FT[0, 4e-4, 0],
        longwave_absorption =
            FT[1e-4 * (7ig + 3j) * (1 + 1e-5 * pressure_grid[ip]) * (1 + 1e-3 * temperature_grid[ip, it])
               for ig in 1:ng_lw, j in 1:ngas, ip in 1:np, it in 1:nt],
        shortwave_absorption =
            FT[1e-5 * (5ig + 2j) * (1 + 2e-5 * pressure_grid[ip]) * (1 + 2e-3 * temperature_grid[ip, it])
               for ig in 1:ng_sw, j in 1:ngas, ip in 1:np, it in 1:nt],
        longwave_h2o_absorption =
            FT[1e-3 * ig * (1 + 10ih) for ig in 1:ng_lw, ip in 1:np, it in 1:nt, ih in 1:nh2o],
        shortwave_h2o_absorption =
            FT[1e-4 * ig * (1 + 5ih) for ig in 1:ng_sw, ip in 1:np, it in 1:nt, ih in 1:nh2o],
        shortwave_rayleigh_molar_scattering = FT[1.1e-6, 3.7e-6],
        longwave_source_temperature_grid = source_temperature_grid,
        longwave_source_table = FT[(ig + 2) * st^2 for ig in 1:ng_lw, st in source_temperature_grid],
        longwave_weights = FT[0.2, 0.3, 0.5],
        shortwave_weights = FT[0.45, 0.55],
    )
    atmosphere = ColumnAtmosphere(
        pressure_layers = FT[7_500, 33_000, 88_000],
        pressure_interfaces = FT[1_000, 14_000, 52_000, 101_000],
        temperature_layers = FT[217.3, 263.9, 291.4],
        temperature_interfaces = FT[205.1, 231.7, 279.2, 297.8],
        gases = (h2o = FT[3.1, 12.7, 41.9], co2 = FT(8.3), composite = FT[4.2e2, 1.1e3, 2.6e3]),
        surface = (;),
        geometry = (;),
    )
    return model, atmosphere
end

# Hydrostatic reference column for the climate_32x32 tables. Layer amounts
# follow the moist-molar-mass convention of RRTMGP's compute_col_gas_kernel!:
# with `χ` the H2O mole fraction relative to dry air, the dry-air molar amount
# is `nᵈ = Δp / (g (mᵈ + mᵛ χ))`, every gas is `χ_gas nᵈ`, and the layer's
# mass closes: `mᵈ nᵈ + mᵛ n_h2o == Δp / g`.
function reference_column(nlayers)
    pressure_interfaces = exp.(range(log(100.0), log(101_325.0), length = nlayers + 1))
    Δp = diff(pressure_interfaces)
    pressure_layers = Δp ./ log.(pressure_interfaces[2:end] ./ pressure_interfaces[1:end - 1])
    temperature_interfaces = [200 + 95 * (p / 101_325.0)^0.3 for p in pressure_interfaces]
    temperature_layers = [200 + 95 * (p / 101_325.0)^0.3 for p in pressure_layers]
    χ_h2o = [max(2e-2 * (p / 101_325.0)^3, 3e-6) for p in pressure_layers]
    χ_o3 = [1e-7 + 8e-6 * exp(-((log(p) - log(2_000.0)) / 0.8)^2) for p in pressure_layers]
    dry_air = Δp ./ (GRAVITY .* (DRY_AIR_MOLAR_MASS .+ WATER_MOLAR_MASS .* χ_h2o))
    gases = (composite = dry_air,
             h2o = χ_h2o .* dry_air,
             o3 = χ_o3 .* dry_air,
             co2 = 420e-6 .* dry_air,
             ch4 = 1.9e-6 .* dry_air,
             n2o = 3.3e-7 .* dry_air,
             cfc11 = 2.2e-10 .* dry_air,
             cfc12 = 5.0e-10 .* dry_air)
    atmosphere = ColumnAtmosphere(; pressure_layers, pressure_interfaces,
                                  temperature_layers, temperature_interfaces,
                                  gases, surface = (;), geometry = (;))
    return atmosphere, Δp, χ_h2o
end

@testset "moist-molar-mass column amounts" begin
    atmosphere, Δp, χ_h2o = reference_column(4)
    dry_air = atmosphere.gases.composite
    h2o = atmosphere.gases.h2o
    @test dry_air ≈ Δp ./ (GRAVITY .* (DRY_AIR_MOLAR_MASS .+ WATER_MOLAR_MASS .* χ_h2o)) rtol = 1e-12
    @test DRY_AIR_MOLAR_MASS .* dry_air .+ WATER_MOLAR_MASS .* h2o ≈ Δp ./ GRAVITY rtol = 1e-12
    @test h2o ./ dry_air ≈ χ_h2o rtol = 1e-12
end

@testset "scalar layer optics reproduce optical_properties! bitwise" begin
    @testset "2-layer fixed-coefficient model" begin
        model, atmosphere = smoke_fixture()
        assert_scalar_matches_array(model, atmosphere; interface_sources = false)
        assert_scalar_matches_array(model, atmosphere; interface_sources = true)
        # The fixed-coefficient model has no stencil, no source table and no
        # Rayleigh scattering.
        @test gas_optics_stencil(model, 20_000.0, 240.0, 0.0) === nothing
        @test source_table_bracket(model, 240.0) === nothing
        @test rayleigh_optical_depth(model, 1, 100.0) === 0.0
        @test longwave_source(model, 2, 240.0, nothing) == 1.05 * (σ_SB * 240.0^4)
    end

    @testset "synthetic tabulated model, $FT" for FT in (Float64, Float32)
        model, atmosphere = tabulated_fixture(FT)
        assert_scalar_matches_array(model, atmosphere; interface_sources = false)
        assert_scalar_matches_array(model, atmosphere; interface_sources = true)
    end

    @testset "reference climate_32x32 tables" begin
        names = (:composite, :h2o, :o3, :co2, :ch4, :n2o, :cfc11, :cfc12)
        paths = reference_ecckd_definition_paths("32x32"; require = false)
        if paths.longwave === nothing || paths.shortwave === nothing
            @test_skip "ecrad_data artifact not installed"
        else
            model = read_reference_ecckd_gas_optics("32x32"; names)
            @test eltype(model) === Float64
            @test length(model.shortwave_rayleigh_molar_scattering) == length(model.shortwave_weights)
            @test length(model.h2o_mole_fraction_grid) > 0
            atmosphere, _, _ = reference_column(24)
            assert_scalar_matches_array(model, atmosphere; interface_sources = true)
            assert_scalar_matches_array(model, atmosphere; interface_sources = false)
        end
    end
end

@testset "layer_gases picks scalar layer amounts" begin
    column = (h2o = [1.0, 2.0, 3.0], co2 = 4.0, composite = [10.0, 20.0, 30.0], unused = [7.0, 8.0, 9.0])
    picked = layer_gases(column, Val((:h2o, :co2)), 2)
    # Names in order, then the composite the relative-linear convention reads.
    @test picked === (h2o = 2.0, co2 = 4.0, composite = 20.0)
    @test layer_gases(column, Val((:composite, :h2o)), 3) === (composite = 30.0, h2o = 3.0)
    @test layer_gases((h2o = [1.0, 2.0],), Val((:h2o,)), 1) === (h2o = 1.0,)
    # Property-backed containers and dictionaries follow the same contract.
    @test layer_gases(Dict(pairs(column)), Val((:h2o, :co2)), 2) == picked
    @test (@inferred layer_gases(column, Val((:h2o, :co2)), 2)) == picked
end

@testset "GasOpticsStencil rebuilds from six scalars" begin
    for FT in (Float64, Float32)
        model, atmosphere = tabulated_fixture(FT)
        k = 2
        gases = layer_scalars(atmosphere.gases, k)
        s = gas_optics_stencil(model, atmosphere.pressure_layers[k], atmosphere.temperature_layers[k],
                               gases.h2o / gases.composite)
        @test s isa GasOpticsStencil{FT}
        @test isbits(s)
        @test s.pressure[2] == s.pressure[1] + 1
        @test s.temperature[2] == s.temperature[1] + 1
        @test s.h2o[2] == s.h2o[1] + 1
        @test 0 <= s.pressure[3] <= 1 && 0 <= s.temperature[3] <= 1 && 0 <= s.h2o[3] <= 1
        rebuilt = GasOpticsStencil(Int32(s.pressure[1]), s.pressure[3],
                                   Int32(s.temperature[1]), s.temperature[3],
                                   Int32(s.h2o[1]), s.h2o[3])
        @test rebuilt === s
        @test GasOpticsStencil(s.pressure, s.temperature, s.h2o) === s
        for ig in eachindex(model.longwave_weights)
            @test longwave_optical_depth(model, ig, gases, rebuilt) ===
                  longwave_optical_depth(model, ig, gases, s)
        end
        # Off-table inputs clamp to the axis edges rather than erroring.
        low = gas_optics_stencil(model, FT(1), FT(50), FT(1e-12))
        high = gas_optics_stencil(model, FT(1e7), FT(1e3), FT(1))
        @test low.pressure == (1, 2, 0) && low.h2o == (1, 2, 0)
        @test high.pressure[2] == length(model.pressure_grid) && high.pressure[3] == 1
        @test high.h2o[2] == length(model.h2o_mole_fraction_grid) && high.h2o[3] == 1
        @test all(isfinite, (longwave_optical_depth(model, 1, gases, low),
                             longwave_optical_depth(model, 1, gases, high)))
    end

    # Without an H2O table the H2O bracket is a placeholder that is never indexed.
    model = EcCKDTabulatedGasOpticsModel(
        names = (:h2o, :co2),
        pressure_grid = [10_000.0, 100_000.0],
        temperature_grid = [220.0, 300.0],
        longwave_absorption = ones(2, 2, 2, 2),
        shortwave_absorption = ones(2, 2, 2, 2),
    )
    s = gas_optics_stencil(model, 50_000.0, 260.0, 0.0)
    @test s.h2o == (1, 1, 0)
    @test h2o_table_optical_depth(model, model.longwave_h2o_absorption, 1.0, 1, s) === 0.0
    @test longwave_optical_depth(model, 1, (h2o = 2.0, co2 = 3.0), s) == 5.0
    @test rayleigh_optical_depth(model, 1, 100.0) === 0.0
end

@testset "non-finite layer state gives NaN optics without throwing" begin
    # A kernel cannot recover from a throw, so a column whose state has gone
    # non-finite (a zero dry-air amount making χ = NaN, a blown-up
    # temperature) must come out as NaN fluxes a host check can catch, not
    # as an aborted launch. `floor(Int, NaN)` would throw an InexactError.
    for FT in (Float64, Float32)
        model, atmosphere = tabulated_fixture(FT)
        k = 2
        gases = layer_scalars(atmosphere.gases, k)
        p, T = atmosphere.pressure_layers[k], atmosphere.temperature_layers[k]
        χ = gases.h2o / gases.composite
        np, nt, nh = length(model.pressure_grid), size(model.temperature_grid, 2),
                     length(model.h2o_mole_fraction_grid)
        in_range(s) = 1 <= s.pressure[1] < s.pressure[2] <= np &&
                      1 <= s.temperature[1] < s.temperature[2] <= nt &&
                      1 <= s.h2o[1] < s.h2o[2] <= nh
        nan = FT(NaN)
        for (state, axis) in (((nan, T, χ), :pressure), ((p, nan, χ), :temperature), ((p, T, nan), :h2o))
            s = @inferred gas_optics_stencil(model, state...)
            @test s isa GasOpticsStencil{FT}
            @test in_range(s)
            @test isnan(getfield(s, axis)[3])
            @test isnan(longwave_optical_depth(model, 1, gases, s))
            @test isnan(shortwave_optical_depth(model, 1, gases, s))
        end
        # A NaN pressure also poisons the pressure-dependent temperature grid.
        @test isnan(gas_optics_stencil(model, nan, T, χ).temperature[3])
        # Infinite inputs clamp to the table edges like any off-table value.
        for state in ((FT(Inf), T, χ), (p, FT(Inf), χ), (p, T, FT(Inf)), (FT(-Inf), T, χ), (p, FT(-Inf), χ))
            s = gas_optics_stencil(model, state...)
            @test in_range(s)
            @test isfinite(longwave_optical_depth(model, 1, gases, s))
        end
        @test gas_optics_stencil(model, FT(Inf), T, χ).pressure == (np - 1, np, 1)
        @test gas_optics_stencil(model, p, T, FT(Inf)).h2o == (nh - 1, nh, 1)
        # The Planck bracket and source propagate NaN the same way.
        b = source_table_bracket(model, nan)
        @test isnan(b[3]) && isnan(longwave_source(model, 1, nan, b))
        @test isnan(TabulatedSurfaceEmission(model, nan)[1])
    end

    # The vector temperature grid goes through the same bracket.
    model = EcCKDTabulatedGasOpticsModel(
        names = (:h2o, :co2),
        pressure_grid = [10_000.0, 100_000.0],
        temperature_grid = [220.0, 300.0],
        longwave_absorption = ones(2, 2, 2, 2),
        shortwave_absorption = ones(2, 2, 2, 2),
    )
    s = gas_optics_stencil(model, 50_000.0, NaN, 0.0)
    @test s.temperature[1:2] == (1, 2) && isnan(s.temperature[3])
    @test isnan(longwave_optical_depth(model, 1, (h2o = 2.0, co2 = 3.0), s))
end

# Julia specializes the allocation measurement separately, so each scalar
# function is called through a `@noinline` wrapper, once to compile and once
# to measure.
Base.@noinline measure_stencil(model, p, T, χ) =
    @allocated gas_optics_stencil(model, p, T, χ)
Base.@noinline measure_longwave(model, ig, gases, s) =
    @allocated longwave_optical_depth(model, ig, gases, s)
Base.@noinline measure_shortwave(model, ig, gases, s) =
    @allocated shortwave_optical_depth(model, ig, gases, s)
Base.@noinline measure_h2o(model, table, h2o, ig, s) =
    @allocated h2o_table_optical_depth(model, table, h2o, ig, s)
Base.@noinline measure_rayleigh(model, ig, air) =
    @allocated rayleigh_optical_depth(model, ig, air)
Base.@noinline measure_source_bracket(model, T) =
    @allocated source_table_bracket(model, T)
Base.@noinline measure_source(model, ig, T, b) =
    @allocated longwave_source(model, ig, T, b)
Base.@noinline measure_layer_gases(gases, names, k) =
    @allocated layer_gases(gases, names, k)
Base.@noinline measure_rebuild(ip, wp, it, wt, ih, wh) =
    @allocated GasOpticsStencil(ip, wp, it, wt, ih, wh)

function assert_inferred_and_allocation_free(model, atmosphere)
    FT = eltype(model)
    k = 2
    gases = layer_scalars(atmosphere.gases, k)
    p = atmosphere.pressure_layers[k]
    T = atmosphere.temperature_layers[k]
    χ = haskey(gases, :composite) ? gases.h2o / gases.composite : zero(FT)
    air = FT(100)
    names = Val(NumericalRadiation.gas_names(model))

    s = @inferred gas_optics_stencil(model, p, T, χ)
    b = @inferred source_table_bracket(model, T)
    τ_lw = @inferred longwave_optical_depth(model, 1, gases, s)
    τ_sw = @inferred shortwave_optical_depth(model, 1, gases, s)
    τ_r = @inferred rayleigh_optical_depth(model, 1, air)
    B = @inferred longwave_source(model, 1, T, b)
    @test typeof(τ_lw) === FT
    @test typeof(τ_sw) === FT
    @test typeof(τ_r) === FT
    @test typeof(B) === FT
    @inferred layer_gases(atmosphere.gases, names, k)
    if model isa EcCKDTabulatedGasOpticsModel
        τ_h2o = @inferred h2o_table_optical_depth(model, model.longwave_h2o_absorption, gases.h2o, 1, s)
        @test typeof(τ_h2o) === FT
        @inferred GasOpticsStencil(Int32(s.pressure[1]), s.pressure[3], Int32(s.temperature[1]),
                                   s.temperature[3], Int32(s.h2o[1]), s.h2o[3])
    end

    for _ in 1:2   # compile on the first pass, measure on the second
        @test measure_stencil(model, p, T, χ) == 0
        @test measure_longwave(model, 1, gases, s) == 0
        @test measure_shortwave(model, 1, gases, s) == 0
        @test measure_rayleigh(model, 1, air) == 0
        @test measure_source_bracket(model, T) == 0
        @test measure_source(model, 1, T, b) == 0
        @test measure_layer_gases(atmosphere.gases, names, k) == 0
        if model isa EcCKDTabulatedGasOpticsModel
            @test measure_h2o(model, model.longwave_h2o_absorption, gases.h2o, 1, s) == 0
            @test measure_rebuild(Int32(s.pressure[1]), s.pressure[3], Int32(s.temperature[1]),
                                  s.temperature[3], Int32(s.h2o[1]), s.h2o[3]) == 0
        end
    end
    return nothing
end

@testset "scalar layer optics are inferrable and allocation-free" begin
    @testset "fixed-coefficient model" begin
        assert_inferred_and_allocation_free(smoke_fixture()...)
    end
    @testset "tabulated model, $FT" for FT in (Float64, Float32)
        assert_inferred_and_allocation_free(tabulated_fixture(FT)...)
    end
    @testset "reference climate_32x32 tables" begin
        names = (:composite, :h2o, :o3, :co2, :ch4, :n2o, :cfc11, :cfc12)
        paths = reference_ecckd_definition_paths("32x32"; require = false)
        if paths.longwave === nothing || paths.shortwave === nothing
            @test_skip "ecrad_data artifact not installed"
        else
            model = read_reference_ecckd_gas_optics("32x32"; names)
            atmosphere, _, _ = reference_column(8)
            assert_inferred_and_allocation_free(model, atmosphere)
        end
    end
end

# A copy of a column with every array in `FT`, for precision comparisons.
function convert_column(FT, atmosphere)
    return ColumnAtmosphere(
        pressure_layers = FT.(atmosphere.pressure_layers),
        pressure_interfaces = FT.(atmosphere.pressure_interfaces),
        temperature_layers = FT.(atmosphere.temperature_layers),
        temperature_interfaces = FT.(atmosphere.temperature_interfaces),
        gases = map(gas -> gas isa Number ? FT(gas) : FT.(gas), atmosphere.gases),
        surface = atmosphere.surface,
        geometry = atmosphere.geometry,
    )
end

# Clear-sky broadband fluxes of one column through the array path, in the
# model's element type.
function broadband_fluxes(model, atmosphere; surface_temperature, cos_zenith, surface_albedo)
    FT = eltype(model)
    nlayers = length(atmosphere.temperature_layers)
    ng_lw, ng_sw = length(model.longwave_weights), length(model.shortwave_weights)
    longwave, shortwave = optics_arrays(FT, ng_lw, ng_sw, nlayers; interface_sources = true)
    optical_properties!(longwave, shortwave, model, atmosphere)
    fluxes = RadiativeFluxes(longwave_up = zeros(FT, nlayers + 1),
                             longwave_down = zeros(FT, nlayers + 1),
                             shortwave_up = zeros(FT, nlayers + 1),
                             shortwave_down = zeros(FT, nlayers + 1))
    surface_up = surface_longwave_emission(model, FT(surface_temperature))
    radiative_fluxes!(fluxes, CloudlessLongwave(), longwave, atmosphere,
                      LongwaveBoundaryConditions(surface_longwave_up = surface_up))
    radiative_fluxes!(fluxes, CloudlessShortwave(), shortwave, atmosphere,
                      ShortwaveBoundaryConditions(toa_shortwave_down = FT(1361) * FT(cos_zenith),
                                                  surface_albedo = FT(surface_albedo)))
    return longwave, shortwave, fluxes
end

array_fields(model) = filter(name -> getfield(model, name) isa AbstractArray,
                             fieldnames(typeof(model)))

@testset "Float32 models" begin
    @testset "adapt derives the element type from the adapted arrays" begin
        gray, _ = smoke_fixture()
        @test NumericalRadiation.Adapt.adapt(Array{Float32}, gray) isa EcCKDGasOpticsModel{Float32}
        @test NumericalRadiation.Adapt.adapt(Array, gray) isa EcCKDGasOpticsModel{Float64}
        for FT in (Float64, Float32), other in (Float64, Float32)
            model, _ = tabulated_fixture(FT)
            adapted = NumericalRadiation.Adapt.adapt(Array{other}, model)
            @test adapted isa EcCKDTabulatedGasOpticsModel{other}
            @test NumericalRadiation.gas_names(adapted) === NumericalRadiation.gas_names(model)
            @test all(name -> eltype(getfield(adapted, name)) === other, array_fields(adapted))
        end
    end

    @testset "EcCKDTabulatedGasOpticsModel{FT} conversion runs Float32 optics" begin
        model, atmosphere = tabulated_fixture(Float64)
        model32 = EcCKDTabulatedGasOpticsModel{Float32}(model)
        @test model32 isa EcCKDTabulatedGasOpticsModel{Float32}
        @test eltype(model32) === Float32
        @test all(name -> eltype(getfield(model32, name)) === Float32, array_fields(model32))
        for name in array_fields(model32)
            @test getfield(model32, name) == Float32.(getfield(model, name))
        end
        # A same-type conversion shares storage instead of copying.
        @test all(name -> getfield(EcCKDTabulatedGasOpticsModel{Float64}(model), name) ===
                          getfield(model, name), array_fields(model))

        atmosphere32 = convert_column(Float32, atmosphere)
        nlayers = length(atmosphere.temperature_layers)
        ng_lw, ng_sw = length(model.longwave_weights), length(model.shortwave_weights)
        longwave32, shortwave32 = optics_arrays(Float32, ng_lw, ng_sw, nlayers; interface_sources = true)
        longwave64, shortwave64 = optics_arrays(Float64, ng_lw, ng_sw, nlayers; interface_sources = true)
        @test (@inferred optical_properties!(longwave32, shortwave32, model32, atmosphere32)) isa Tuple
        optical_properties!(longwave64, shortwave64, model, atmosphere)
        @test eltype(longwave32.optical_depth) === Float32
        @test all(isfinite, longwave32.optical_depth)
        @test longwave32.optical_depth ≈ longwave64.optical_depth rtol = 1e-4
        @test longwave32.source_top ≈ longwave64.source_top rtol = 1e-4
        @test shortwave32.optical_depth ≈ shortwave64.optical_depth rtol = 1e-4
        @test shortwave32.rayleigh_optical_depth ≈ shortwave64.rayleigh_optical_depth rtol = 1e-4
        @test all(isfinite, surface_longwave_emission(model32, 290f0))
        @test eltype(surface_longwave_emission(model32, 290f0)) === Float32
    end

    @testset "Float32 vs Float64 broadband fluxes on the reference column" begin
        names = (:composite, :h2o, :o3, :co2, :ch4, :n2o, :cfc11, :cfc12)
        paths = reference_ecckd_definition_paths("32x32"; require = false)
        if paths.longwave === nothing || paths.shortwave === nothing
            @test_skip "ecrad_data artifact not installed"
        else
            model64 = read_reference_ecckd_gas_optics("32x32"; names)
            model32 = read_reference_ecckd_gas_optics("32x32"; names, float_type = Float32)
            @test model32 isa EcCKDTabulatedGasOpticsModel{Float32}
            @test eltype(model32.longwave_absorption) === Float32
            @test eltype(model32.longwave_h2o_absorption) === Float32
            @test eltype(model32.longwave_source_table) === Float32
            @test eltype(model32.pressure_grid) === Float32
            @test eltype(model32.temperature_grid) === Float32
            # The reader converts the Float64 model it validates, so the two loads agree exactly.
            converted = EcCKDTabulatedGasOpticsModel{Float32}(model64)
            for name in array_fields(model32)
                @test getfield(model32, name) == getfield(converted, name)
            end

            atmosphere64, _, _ = reference_column(40)
            atmosphere32 = convert_column(Float32, atmosphere64)
            settings = (surface_temperature = atmosphere64.temperature_interfaces[end],
                        cos_zenith = 0.5, surface_albedo = 0.1)
            longwave64, shortwave64, fluxes64 = broadband_fluxes(model64, atmosphere64; settings...)
            longwave32, shortwave32, fluxes32 = broadband_fluxes(model32, atmosphere32; settings...)
            @test eltype(longwave32.optical_depth) === Float32
            @test eltype(fluxes32) === Float32
            # Observed on this 40-layer column: relative norm errors of 2e-7
            # (LW) to 2e-6 (SW), at most 6e-4 W m⁻² pointwise, so the 2e-3
            # gate leaves two orders of magnitude of headroom.
            for name in fieldnames(typeof(fluxes64))
                flux64, flux32 = getfield(fluxes64, name), getfield(fluxes32, name)
                @test all(isfinite, flux32)
                @test flux32 ≈ flux64 rtol = 2e-3
            end
            # Sanity: the column is opaque enough that the fluxes are not trivially zero.
            @test fluxes64.longwave_up[1] > 100
            @test fluxes64.longwave_down[end] > 100
            @test fluxes64.shortwave_down[end] > 100
        end
    end
end

#####
##### Streaming longwave solver and surface reflection
#####

# The no-scattering longwave branch of `radiative_fluxes!(…, CloudlessLongwave(), …)`
# as it stood before `streaming_longwave_fluxes!` (up first, then down, no
# surface reflection), copied verbatim so the reordered solver can be pinned
# bit for bit for the default albedo of zero.
function legacy_no_scattering_fluxes!(fluxes, optics::LongwaveOptics{FT}, boundary_conditions) where FT
    nlayers = NumericalRadiation.number_of_layers(optics)
    fluxes.longwave_up .= zero(FT)
    fluxes.longwave_down .= zero(FT)
    for ig in 1:NumericalRadiation.number_of_g_points(optics)
        w = FT(optics.weights[ig])

        up = NumericalRadiation.surface_longwave_up_at(boundary_conditions, ig)
        fluxes.longwave_up[nlayers + 1] += w * up
        for k in nlayers:-1:1
            tau = NumericalRadiation.tau_at(optics, ig, k)
            if NumericalRadiation.has_interface_sources(optics)
                tr, source_up, _ = NumericalRadiation.no_scattering_lw_sources(
                    FT, tau, NumericalRadiation.source_top_at(optics, ig, k),
                    NumericalRadiation.source_bottom_at(optics, ig, k))
                up = up * tr + source_up
            else
                tr = exp(-tau)
                src = NumericalRadiation.source_at(optics, ig, k)
                up = up * tr + src * (one(FT) - tr)
            end
            fluxes.longwave_up[k] += w * up
        end

        down = boundary_conditions.toa_longwave_down
        fluxes.longwave_down[1] += w * down
        for k in 1:nlayers
            tau = NumericalRadiation.tau_at(optics, ig, k)
            if NumericalRadiation.has_interface_sources(optics)
                tr, _, source_down = NumericalRadiation.no_scattering_lw_sources(
                    FT, tau, NumericalRadiation.source_top_at(optics, ig, k),
                    NumericalRadiation.source_bottom_at(optics, ig, k))
                down = down * tr + source_down
            else
                tr = exp(-tau)
                src = NumericalRadiation.source_at(optics, ig, k)
                down = down * tr + src * (one(FT) - tr)
            end
            fluxes.longwave_down[k + 1] += w * down
        end
    end
    return fluxes
end

longwave_fluxes(FT, nlayers) = RadiativeFluxes(longwave_up = zeros(FT, nlayers + 1),
                                               longwave_down = zeros(FT, nlayers + 1),
                                               shortwave_up = zeros(FT, nlayers + 1),
                                               shortwave_down = zeros(FT, nlayers + 1))

# The functor form of precomputed `(ng, nlayers)` interface-source optics.
struct MatrixLayerOptics{L}
    longwave :: L
end
(layer::MatrixLayerOptics)(ig, k) = (layer.longwave.optical_depth[ig, k],
                                     layer.longwave.source_top[ig, k],
                                     layer.longwave.source_bottom[ig, k])

# A layer functor for an isothermal gray column: every layer has the same
# optical depth and Planck source.
struct UniformLayerOptics{FT}
    τ :: FT
    B :: FT
end
(layer::UniformLayerOptics)(ig, k) = (layer.τ, layer.B, layer.B)

# Stream a column's longwave fluxes with the full g loop, returning
# `(up, down)` as fresh vectors.
function stream_longwave(FT, layer_optics, surface_emission, surface_albedo, toa_down, weights, ng, nlayers)
    up = zeros(FT, nlayers + 1)
    down = zeros(FT, nlayers + 1)
    streaming_longwave_fluxes!(up, down, layer_optics, surface_emission, surface_albedo, toa_down,
                               weights, ng, nlayers, zeros(FT, nlayers), zeros(FT, nlayers))
    return up, down
end

# Stream the same column through the array solver with the same boundary.
function solve_longwave_array(FT, model, longwave; surface_temperature, emissivity, surface_albedo, toa_down)
    nlayers = size(longwave.optical_depth, 2)
    fluxes = longwave_fluxes(FT, nlayers)
    surface_up = surface_longwave_emission(model, surface_temperature; emissivity)
    boundary = LongwaveBoundaryConditions(; surface_longwave_up = surface_up,
                                          toa_longwave_down = toa_down,
                                          surface_albedo)
    radiative_fluxes!(fluxes, CloudlessLongwave(), longwave, nothing, boundary)
    return fluxes
end

function assert_streaming_matches_array(model, atmosphere; surface_temperature, emissivity, surface_albedo, toa_down)
    FT = eltype(model)
    nlayers = length(atmosphere.temperature_layers)
    ng_lw, ng_sw = length(model.longwave_weights), length(model.shortwave_weights)
    longwave, shortwave = optics_arrays(FT, ng_lw, ng_sw, nlayers; interface_sources = true)
    optical_properties!(longwave, shortwave, model, atmosphere)

    fluxes = solve_longwave_array(FT, model, longwave; surface_temperature, emissivity, surface_albedo, toa_down)
    surface = TabulatedSurfaceEmission(model, surface_temperature; emissivity)
    up, down = stream_longwave(FT, MatrixLayerOptics(longwave), surface, FT(surface_albedo), FT(toa_down),
                               model.longwave_weights, ng_lw, nlayers)

    @test all(isfinite, up) && all(isfinite, down)
    @test up[1] > 0 && down[end] > 0
    @test up ≈ fluxes.longwave_up rtol = 1e-12
    @test down ≈ fluxes.longwave_down rtol = 1e-12
    # The array solver streams one g point at a time through the same
    # function, so the two are in fact bitwise equal.
    @test up == fluxes.longwave_up
    @test down == fluxes.longwave_down
    # Reflection is visible: with the same emission but no albedo the surface
    # upwelling flux is smaller by exactly the reflected downwelling flux.
    up0, down0 = stream_longwave(FT, MatrixLayerOptics(longwave), surface, zero(FT), FT(toa_down),
                                 model.longwave_weights, ng_lw, nlayers)
    @test down0 == down
    @test up[end] - up0[end] ≈ FT(surface_albedo) * down[end] rtol = (FT === Float64 ? 1e-10 : 1e-4)

    # A lazy `TabulatedSurfaceEmission` works as the boundary of the array
    # solver directly, in place of its `collect`.
    lazy_fluxes = longwave_fluxes(FT, nlayers)
    boundary = LongwaveBoundaryConditions(surface_longwave_up = surface,
                                          toa_longwave_down = toa_down,
                                          surface_albedo = surface_albedo)
    radiative_fluxes!(lazy_fluxes, CloudlessLongwave(), longwave, nothing, boundary)
    @test lazy_fluxes.longwave_up == fluxes.longwave_up
    @test lazy_fluxes.longwave_down == fluxes.longwave_down
    return nothing
end

@testset "TabulatedSurfaceEmission" begin
    @testset "matches surface_longwave_emission" begin
        gray, _ = smoke_fixture()
        for (model, T) in ((gray, 300), (gray, 287.5), (tabulated_fixture(Float64)[1], 300),
                           (tabulated_fixture(Float32)[1], 300))
            FT = eltype(model)
            emission = TabulatedSurfaceEmission(model, T)
            @test emission isa TabulatedSurfaceEmission{FT}
            @test emission isa AbstractVector{FT}
            @test eltype(emission) === FT
            @test length(emission) == length(model.longwave_weights)
            @test collect(emission) == surface_longwave_emission(model, T)
            @test collect(emission) isa Vector{FT}
            scaled = TabulatedSurfaceEmission(model, T; emissivity = 0.9)
            @test scaled.emissivity === FT(0.9)
            @test collect(scaled) == surface_longwave_emission(model, T; emissivity = 0.9)
            @test collect(scaled) ≈ 0.9 .* collect(emission) rtol = 4eps(FT)
            @test emission[end] == emission[length(emission)]
        end
        # Gray path: scale × σT⁴, emissivity folded in.
        @test TabulatedSurfaceEmission(gray, 300.0; emissivity = 0.5)[2] == 0.5 * (1.05 * (σ_SB * 300.0^4))
    end

    @testset "reference climate_32x32 tables" begin
        names = (:composite, :h2o, :o3, :co2, :ch4, :n2o, :cfc11, :cfc12)
        paths = reference_ecckd_definition_paths("32x32"; require = false)
        if paths.longwave === nothing || paths.shortwave === nothing
            @test_skip "ecrad_data artifact not installed"
        else
            model = read_reference_ecckd_gas_optics("32x32"; names)
            emission = TabulatedSurfaceEmission(model, 300)
            @test emission.bracket !== nothing
            @test collect(emission) == surface_longwave_emission(model, 300)
            @test collect(TabulatedSurfaceEmission(model, 300; emissivity = 0.98)) ==
                  surface_longwave_emission(model, 300; emissivity = 0.98)
            @test sum(model.longwave_weights .* collect(emission)) ≈ σ_SB * 300.0^4 atol = 0.2
        end
    end
end

@testset "streaming longwave reproduces CloudlessLongwave" begin
    settings = (surface_temperature = 295.0, emissivity = 0.98, surface_albedo = 0.02, toa_down = 0.0)

    @testset "2-layer fixed-coefficient model" begin
        model, atmosphere = smoke_fixture()
        assert_streaming_matches_array(model, atmosphere; settings...)
        assert_streaming_matches_array(model, atmosphere; settings..., toa_down = 12.5)
    end

    @testset "synthetic tabulated model, $FT" for FT in (Float64, Float32)
        model, atmosphere = tabulated_fixture(FT)
        assert_streaming_matches_array(model, atmosphere; settings...)
    end

    @testset "reference climate_32x32 tables" begin
        names = (:composite, :h2o, :o3, :co2, :ch4, :n2o, :cfc11, :cfc12)
        paths = reference_ecckd_definition_paths("32x32"; require = false)
        if paths.longwave === nothing || paths.shortwave === nothing
            @test_skip "ecrad_data artifact not installed"
        else
            model = read_reference_ecckd_gas_optics("32x32"; names)
            atmosphere, _, _ = reference_column(40)
            assert_streaming_matches_array(model, atmosphere; settings...,
                                           surface_temperature = atmosphere.temperature_interfaces[end])
        end
    end

    @testset "per-g surface albedo" begin
        model, atmosphere = tabulated_fixture(Float64)
        nlayers = length(atmosphere.temperature_layers)
        ng = length(model.longwave_weights)
        longwave, shortwave = optics_arrays(Float64, ng, length(model.shortwave_weights), nlayers; interface_sources = true)
        optical_properties!(longwave, shortwave, model, atmosphere)
        albedo = [0.01, 0.05, 0.1]
        fluxes = solve_longwave_array(Float64, model, longwave; surface_temperature = 290.0, emissivity = 0.95,
                                      surface_albedo = albedo, toa_down = 0.0)
        # The array solver applies each g point's albedo; streaming one g point
        # at a time with its own albedo and summing reproduces it.
        up = zeros(nlayers + 1)
        down = zeros(nlayers + 1)
        for ig in 1:ng
            # Only g point `ig` of the streamed result carries albedo[ig]; pick
            # it out by streaming with a one-hot weight vector.
            onehot = [j == ig ? model.longwave_weights[j] : 0.0 for j in 1:ng]
            up_g, down_g = stream_longwave(Float64, MatrixLayerOptics(longwave),
                                           TabulatedSurfaceEmission(model, 290.0; emissivity = 0.95),
                                           albedo[ig], 0.0, onehot, ng, nlayers)
            up .+= up_g
            down .+= down_g
        end
        @test up ≈ fluxes.longwave_up rtol = 1e-12
        @test down ≈ fluxes.longwave_down rtol = 1e-12
    end
end

# A fixed shuffle, so the optical depths below mix thin and thick layers
# across g points without a Random dependency.
shuffle_like(x) = x[sortperm(sin.(1:length(x)))]

@testset "reordered CloudlessLongwave is bitwise unchanged for zero albedo" begin
    for FT in (Float64, Float32)
        nlayers = 7
        ng = 3
        τ = FT.(10 .^ range(-4, 1, length = ng * nlayers))
        τ = reshape(shuffle_like(τ), ng, nlayers)
        source = FT.(100 .+ 150 .* rand(ng, nlayers))
        source_top = FT.(100 .+ 150 .* rand(ng, nlayers))
        source_bottom = FT.(100 .+ 150 .* rand(ng, nlayers))
        weights = FT[0.2, 0.3, 0.5]
        surface_up = FT[310, 330, 350]
        for (optics, boundary) in (
                (LongwaveOptics(τ, source; weights),
                 LongwaveBoundaryConditions(surface_longwave_up = surface_up)),
                (LongwaveOptics(τ, source; source_top, source_bottom, weights),
                 LongwaveBoundaryConditions(surface_longwave_up = surface_up)),
                (LongwaveOptics(τ, source; source_top, source_bottom, weights),
                 LongwaveBoundaryConditions(surface_longwave_up = FT(300), toa_longwave_down = FT(7))),
                (LongwaveOptics(vec(τ[1, :]), vec(source[1, :])),
                 LongwaveBoundaryConditions(surface_longwave_up = FT(300))),
                (LongwaveOptics(vec(τ[1, :]), vec(source[1, :]);
                                source_top = vec(source_top[1, :]), source_bottom = vec(source_bottom[1, :])),
                 LongwaveBoundaryConditions(surface_longwave_up = FT(300), toa_longwave_down = FT(3))))
            new = longwave_fluxes(FT, nlayers)
            legacy = longwave_fluxes(FT, nlayers)
            radiative_fluxes!(new, CloudlessLongwave(), optics, nothing, boundary)
            legacy_no_scattering_fluxes!(legacy, optics, boundary)
            @test new.longwave_up == legacy.longwave_up
            @test new.longwave_down == legacy.longwave_down
            @test !all(iszero, new.longwave_down)
        end
    end

    # The component-smoke fixture through the array solver, with and without
    # interface sources.
    model, atmosphere = smoke_fixture()
    nlayers = length(atmosphere.temperature_layers)
    for interface_sources in (false, true)
        longwave, shortwave = optics_arrays(Float64, 2, 1, nlayers; interface_sources)
        optical_properties!(longwave, shortwave, model, atmosphere)
        boundary = LongwaveBoundaryConditions(surface_longwave_up = surface_longwave_emission(model, 295.0))
        new = longwave_fluxes(Float64, nlayers)
        legacy = longwave_fluxes(Float64, nlayers)
        radiative_fluxes!(new, CloudlessLongwave(), longwave, atmosphere, boundary)
        legacy_no_scattering_fluxes!(legacy, longwave, boundary)
        @test new.longwave_up == legacy.longwave_up
        @test new.longwave_down == legacy.longwave_down
    end
end

@testset "surface reflection closes an opaque isothermal column" begin
    # Thick isothermal gray column: the downwelling flux at the surface is
    # the full Planck flux, so with `ε = 0.9` and `α = 0.1` the surface
    # upwelling flux `ε σT⁴ + α σT⁴` closes to `σT⁴`, as does every interior
    # interface in radiative equilibrium with the isothermal gas.
    gray = EcCKDGasOpticsModel(names = (:composite,),
                               longwave_absorption = [1.0;;],
                               shortwave_absorption = [0.5;;])
    for FT in (Float64, Float32)
        T = FT(280)
        B = FT(σ_SB) * T^4
        nlayers = 6
        layer = UniformLayerOptics(FT(50), B)
        model = NumericalRadiation.Adapt.adapt(Array{FT}, gray)
        surface = TabulatedSurfaceEmission(model, T; emissivity = 0.9)
        @test surface[1] ≈ FT(0.9) * B rtol = 4eps(FT)
        up, down = stream_longwave(FT, layer, surface, FT(0.1), zero(FT), model.longwave_weights, 1, nlayers)
        rtol = FT === Float64 ? 1e-12 : 200eps(Float32)
        @test up[end] ≈ B rtol = rtol
        @test down[end] ≈ B rtol = rtol
        @test down[1] == 0
        @test all(k -> isapprox(up[k], B; rtol), 1:nlayers + 1)
        @test all(k -> isapprox(down[k], B; rtol), 2:nlayers + 1)
        # Emission alone: without reflection the surface flux is only εσT⁴.
        up0, _ = stream_longwave(FT, layer, surface, zero(FT), zero(FT), model.longwave_weights, 1, nlayers)
        @test up0[end] ≈ FT(0.9) * B rtol = rtol
    end
end

Base.@noinline measure_streaming_longwave(up, down, layer, surface, albedo, toa, weights, ng, nlayers, tr, src) =
    @allocated streaming_longwave_fluxes!(up, down, layer, surface, albedo, toa, weights, ng, nlayers, tr, src)
Base.@noinline measure_surface_emission(model, T, ε) =
    @allocated TabulatedSurfaceEmission(model, T; emissivity = ε)
Base.@noinline measure_surface_index(surface, ig) = @allocated surface[ig]

@testset "streaming longwave is inferrable and allocation-free" begin
    for FT in (Float64, Float32)
        model, atmosphere = tabulated_fixture(FT)
        nlayers = length(atmosphere.temperature_layers)
        ng = length(model.longwave_weights)
        longwave, shortwave = optics_arrays(FT, ng, 2, nlayers; interface_sources = true)
        optical_properties!(longwave, shortwave, model, atmosphere)
        layer = MatrixLayerOptics(longwave)

        surface = @inferred TabulatedSurfaceEmission(model, FT(290); emissivity = FT(0.98))
        @test typeof(@inferred surface[1]) === FT

        # Column rows of `(Nc, N + 1)` and `(Nc, N)` workspaces, as a host
        # model stores them.
        Nc = 3
        up = zeros(FT, Nc, nlayers + 1)
        down = zeros(FT, Nc, nlayers + 1)
        transmittance = zeros(FT, Nc, nlayers)
        source_up = zeros(FT, Nc, nlayers)
        c = 2
        args = (view(up, c, :), view(down, c, :), layer, surface, FT(0.02), zero(FT),
                model.longwave_weights, ng, nlayers, view(transmittance, c, :), view(source_up, c, :))
        @inferred streaming_longwave_fluxes!(args...)
        for _ in 1:2   # compile, then measure
            @test measure_streaming_longwave(args...) == 0
            @test measure_surface_emission(model, FT(290), FT(0.98)) == 0
            @test measure_surface_index(surface, 2) == 0
        end
        # Only row `c` was written.
        @test all(iszero, up[[1, 3], :]) && all(iszero, down[[1, 3], :])
        @test !all(iszero, up[c, :]) && !all(iszero, down[c, 2:end])
        fluxes = solve_longwave_array(FT, model, longwave; surface_temperature = FT(290), emissivity = FT(0.98),
                                      surface_albedo = FT(0.02), toa_down = zero(FT))
        @test up[c, :] == fluxes.longwave_up
        @test down[c, :] == fluxes.longwave_down

        gray, _ = smoke_fixture()
        gray_surface = @inferred TabulatedSurfaceEmission(gray, 290.0)
        @test gray_surface.bracket === nothing
        @test typeof(@inferred gray_surface[1]) === Float64
        for _ in 1:2
            @test measure_surface_emission(gray, 290.0, 1.0) == 0
            @test measure_surface_index(gray_surface, 1) == 0
        end
    end
end

# ---------------------------------------------------------------------------
# Streaming shortwave solver
#
# `streaming_shortwave_fluxes!` is the kernel-facing form of the ecRad
# two-stream adding method that `ecrad_shortwave_column!` runs on the arrays of
# a `ShortwaveOptics`: g points stream through one `ShortwaveColumnScratch`,
# the weighted fluxes accumulate in place, and nothing is allocated. These
# tests pin it against (1) the per-g-point wrapper and the array solver
# `radiative_fluxes!(…, CloudlessShortwave(), …)`, (2) the adding algorithm as
# it stood before the scratch refactor, copied below, (3) exact zeros at night
# and (4) zero allocation.

# Shortwave layer-optics functor over plain matrices, the way a host kernel
# supplies optics: `(ig, k) -> (τ_absorption, τ_scattering, asymmetry)`. (The
# longwave `MatrixLayerOptics` above wraps a `LongwaveOptics`; Julia 1.10
# rejects a second `struct` of the same name in one module.)
struct ShortwaveMatrixOptics{M}
    absorption::M
    scattering::M
    asymmetry::M
end

@inline (optics::ShortwaveMatrixOptics)(ig, k) =
    (optics.absorption[ig, k], optics.scattering[ig, k], optics.asymmetry[ig, k])

# A 3-g-point, 6-layer column with Rayleigh scattering in every layer, a mix
# of forward- and back-scattering asymmetries and per-g-point albedos.
function shortwave_fixture(FT)
    ng, nlayers = 3, 6
    absorption = FT[0.02 * ig * (1 + 0.3 * k) for ig in 1:ng, k in 1:nlayers]
    scattering = FT[0.05 * (4 - ig) * (1 + 0.1 * k) for ig in 1:ng, k in 1:nlayers]
    asymmetry = FT[clamp(0.3 * (k - 2) - 0.1 * ig, -1, 1) for ig in 1:ng, k in 1:nlayers]
    weights = FT[0.2, 0.3, 0.5]
    direct_albedo = FT[0.05, 0.15, 0.25]
    diffuse_albedo = FT[0.1, 0.2, 0.3]
    optics = ShortwaveOptics(absorption; scattering_optical_depth = scattering,
                             scattering_asymmetry = asymmetry, weights)
    layer_optics = ShortwaveMatrixOptics(absorption, scattering, asymmetry)
    return (; ng, nlayers, optics, layer_optics, weights, direct_albedo, diffuse_albedo)
end

# The adding algorithm of `ecrad_shortwave_column!` before it became a wrapper
# over the streaming solver (per-layer temporaries, `inv_denominator` stored),
# kept as the reference the refactor must reproduce bitwise.
function reference_adding_column!(up::AbstractVector{FT}, down::AbstractVector{FT}, layer_optics, ig,
                                  μ0, incoming_horizontal, surface_albedo, surface_albedo_direct,
                                  nlayers) where FT
    incoming_normal = incoming_horizontal / μ0
    reflectance = Vector{FT}(undef, nlayers)
    transmittance = Vector{FT}(undef, nlayers)
    ref_dir = Vector{FT}(undef, nlayers)
    trans_dir_diff = Vector{FT}(undef, nlayers)
    trans_dir_dir = Vector{FT}(undef, nlayers)
    for k in 1:nlayers
        τ_absorption, τ_scattering, asymmetry = layer_optics(ig, k)
        absorption_tau = max(FT(τ_absorption), zero(FT))
        rayleigh_tau = max(FT(τ_scattering), zero(FT))
        total_tau = absorption_tau + rayleigh_tau
        ssa = total_tau == zero(FT) ? zero(FT) : rayleigh_tau / total_tau
        g = clamp(FT(asymmetry), -one(FT), one(FT))
        reflectance[k], transmittance[k], ref_dir[k], trans_dir_diff[k], trans_dir_dir[k] =
            NumericalRadiation.sw_two_stream_layer(FT, μ0, total_tau, ssa, g)
    end
    flux_direct = Vector{FT}(undef, nlayers + 1)
    flux_diffuse = Vector{FT}(undef, nlayers + 1)
    source = Vector{FT}(undef, nlayers + 1)
    stack_albedo = Vector{FT}(undef, nlayers + 1)
    inv_denominator = Vector{FT}(undef, nlayers)
    flux_direct[1] = incoming_normal
    for k in 1:nlayers
        flux_direct[k + 1] = flux_direct[k] * trans_dir_dir[k]
    end
    stack_albedo[nlayers + 1] = surface_albedo
    source[nlayers + 1] = surface_albedo_direct * flux_direct[nlayers + 1] * μ0
    for k in nlayers:-1:1
        below = stack_albedo[k + 1]
        inv_denominator[k] = inv(one(FT) - below * reflectance[k])
        stack_albedo[k] = reflectance[k] +
            transmittance[k] * transmittance[k] * below * inv_denominator[k]
        source[k] = ref_dir[k] * flux_direct[k] +
            transmittance[k] *
            (source[k + 1] + below * trans_dir_diff[k] * flux_direct[k]) *
            inv_denominator[k]
    end
    flux_diffuse[1] = zero(FT)
    up[1] += source[1]
    down[1] += flux_direct[1] * μ0
    for k in 1:nlayers
        flux_diffuse[k + 1] =
            (transmittance[k] * flux_diffuse[k] +
             reflectance[k] * source[k + 1] +
             trans_dir_diff[k] * flux_direct[k]) * inv_denominator[k]
        up[k + 1] += stack_albedo[k + 1] * flux_diffuse[k + 1] + source[k + 1]
        down[k + 1] += flux_diffuse[k + 1] + flux_direct[k + 1] * μ0
    end
    return nothing
end

function streamed_shortwave(fixture, FT, μ0, toa_irradiance)
    (; ng, nlayers, layer_optics, weights, direct_albedo, diffuse_albedo) = fixture
    up = fill(FT(NaN), nlayers + 1)   # the solver must zero its outputs
    down = fill(FT(NaN), nlayers + 1)
    scratch = ShortwaveColumnScratch(FT, nlayers)
    streaming_shortwave_fluxes!(up, down, layer_optics, μ0, toa_irradiance,
                                direct_albedo, diffuse_albedo, weights, ng, nlayers, scratch)
    return up, down
end

@testset "ShortwaveColumnScratch" begin
    for FT in (Float64, Float32)
        scratch = ShortwaveColumnScratch(FT, 5)
        @test scratch isa ShortwaveColumnScratch{Vector{FT}}
        @test eltype(scratch) === FT
        for name in (:reflectance, :transmittance, :direct_reflectance,
                     :direct_diffuse_transmittance, :direct_transmittance)
            @test length(getfield(scratch, name)) == 5
        end
        @test length(scratch.stack_albedo) == 6
        @test length(scratch.source) == 6
    end
    # Views of a host's own row-major column arrays are accepted as scratch.
    layers, interfaces = zeros(2, 5), zeros(2, 6)
    scratch = ShortwaveColumnScratch(view(layers, 1, :), view(layers, 2, :), view(layers, 1, :),
                                     view(layers, 2, :), view(layers, 1, :),
                                     view(interfaces, 1, :), view(interfaces, 2, :))
    @test eltype(scratch) === Float64
end

@testset "streaming shortwave reproduces the adding solver, $FT" for FT in (Float64, Float32)
    fixture = shortwave_fixture(FT)
    (; ng, nlayers, optics, layer_optics, weights, direct_albedo, diffuse_albedo) = fixture
    S0 = FT(1361)
    tolerance = FT === Float64 ? 1e-12 : 20 * eps(Float32)
    for μ0 in FT[1, 0.5, 0.1]
        toa_irradiance = S0 * μ0
        up, down = streamed_shortwave(fixture, FT, μ0, toa_irradiance)
        @test all(isfinite, up) && all(isfinite, down)
        @test down[1] == toa_irradiance
        @test up[1] > 0 && down[end] > 0

        # Weighted sum of the per-g-point wrapper, and the pre-refactor
        # reference algorithm: the same arithmetic in the same order.
        wrapped_up, wrapped_down = zeros(FT, nlayers + 1), zeros(FT, nlayers + 1)
        reference_up, reference_down = zeros(FT, nlayers + 1), zeros(FT, nlayers + 1)
        for ig in 1:ng
            scratch_up, scratch_down = zeros(FT, nlayers + 1), zeros(FT, nlayers + 1)
            NumericalRadiation.ecrad_shortwave_column!(scratch_up, scratch_down, optics, ig, μ0,
                                                       toa_irradiance, diffuse_albedo[ig],
                                                       direct_albedo[ig])
            wrapped_up .+= weights[ig] .* scratch_up
            wrapped_down .+= weights[ig] .* scratch_down
            scratch_up, scratch_down = zeros(FT, nlayers + 1), zeros(FT, nlayers + 1)
            reference_adding_column!(scratch_up, scratch_down, layer_optics, ig, μ0, toa_irradiance,
                                     diffuse_albedo[ig], direct_albedo[ig], nlayers)
            reference_up .+= weights[ig] .* scratch_up
            reference_down .+= weights[ig] .* scratch_down
        end
        @test up ≈ wrapped_up rtol = tolerance
        @test down ≈ wrapped_down rtol = tolerance
        @test up == reference_up
        @test down == reference_down

        # The array solver with solar geometry and per-g-point albedos.
        fluxes = RadiativeFluxes(longwave_up = zeros(FT, nlayers + 1),
                                 longwave_down = zeros(FT, nlayers + 1),
                                 shortwave_up = zeros(FT, nlayers + 1),
                                 shortwave_down = zeros(FT, nlayers + 1))
        radiative_fluxes!(fluxes, CloudlessShortwave(), optics, (; geometry = (; cos_zenith = μ0)),
                          ShortwaveBoundaryConditions(toa_shortwave_down = toa_irradiance,
                                                      surface_albedo = diffuse_albedo,
                                                      surface_albedo_direct = direct_albedo))
        @test fluxes.shortwave_up ≈ up rtol = tolerance
        @test fluxes.shortwave_down ≈ down rtol = tolerance
    end

    # Broadband albedos are accepted in place of per-g-point vectors.
    μ0 = FT(0.5)
    up, down = streamed_shortwave(fixture, FT, μ0, S0 * μ0)
    scalar_up, scalar_down = fill(FT(NaN), nlayers + 1), fill(FT(NaN), nlayers + 1)
    streaming_shortwave_fluxes!(scalar_up, scalar_down, layer_optics, μ0, S0 * μ0, FT(0.15), FT(0.2),
                                weights, ng, nlayers, ShortwaveColumnScratch(FT, nlayers))
    @test all(isfinite, scalar_up) && all(isfinite, scalar_down)
    @test scalar_down[1] == down[1]
    @test scalar_up != up
end

@testset "streaming shortwave mixes Beer-Lambert and adding g points" begin
    # A g point without scattering takes the closed-form Beer-Lambert branch of
    # `radiative_fluxes!`; the others take the adding method. The broadband
    # result is the weighted sum of both.
    nlayers = 3
    absorption = [0.1 0.2 0.3; 0.05 0.1 0.15]
    scattering = [0.0 0.0 0.0; 0.02 0.03 0.04]
    weights = [0.4, 0.6]
    optics = ShortwaveOptics(absorption; scattering_optical_depth = scattering, weights)
    μ0, S0, albedo = 0.5, 1361.0, 0.2
    fluxes = RadiativeFluxes(longwave_up = zeros(nlayers + 1), longwave_down = zeros(nlayers + 1),
                             shortwave_up = zeros(nlayers + 1), shortwave_down = zeros(nlayers + 1))
    radiative_fluxes!(fluxes, CloudlessShortwave(), optics, (; geometry = (; cos_zenith = μ0)),
                      ShortwaveBoundaryConditions(toa_shortwave_down = S0 * μ0, surface_albedo = albedo))

    τ_cumulative = [0.0; cumsum(absorption[1, :])]
    beer_down = S0 * μ0 .* exp.(-τ_cumulative ./ μ0)
    beer_up = albedo * beer_down[end] .* exp.(-(τ_cumulative[end] .- τ_cumulative) ./ μ0)
    # Streamed through the adding method, the scattering-free g point is
    # Beer-Lambert too, up to rounding.
    up, down = zeros(nlayers + 1), zeros(nlayers + 1)
    streaming_shortwave_fluxes!(up, down, ShortwaveMatrixOptics(absorption, scattering, zero(absorption)),
                                μ0, S0 * μ0, albedo, albedo, (1.0,), 1, nlayers,
                                ShortwaveColumnScratch(Float64, nlayers))
    @test down ≈ beer_down rtol = 1e-10
    @test up ≈ beer_up rtol = 1e-10
    scratch_up, scratch_down = zeros(nlayers + 1), zeros(nlayers + 1)
    NumericalRadiation.ecrad_shortwave_column!(scratch_up, scratch_down, optics, 2, μ0, S0 * μ0, albedo)
    @test fluxes.shortwave_down ≈ weights[1] .* beer_down .+ weights[2] .* scratch_down rtol = 1e-12
    @test fluxes.shortwave_up ≈ weights[1] .* beer_up .+ weights[2] .* scratch_up rtol = 1e-12
end

@testset "streaming shortwave is exactly zero at night, $FT" for FT in (Float64, Float32)
    fixture = shortwave_fixture(FT)
    S0 = FT(1361)
    # The host convention `toa_irradiance = S0 max(μ0, 0)`: the sun below or
    # on the horizon gives identically zero fluxes without a branch.
    for μ0 in FT[0, -0.3, -1]
        up, down = streamed_shortwave(fixture, FT, μ0, S0 * max(μ0, zero(FT)))
        @test all(iszero, up)
        @test all(iszero, down)
        @test !any(signbit, up) && !any(signbit, down)
    end
    # A nonzero irradiance at μ0 = 0 is treated as grazing incidence, like
    # `sw_path_factor`: finite, with the given horizontal flux at the top.
    up, down = streamed_shortwave(fixture, FT, zero(FT), S0)
    @test all(isfinite, up) && all(isfinite, down)
    @test down[1] ≈ S0 rtol = 1e-6
    @test down[end] < S0
end

Base.@noinline measure_streaming_shortwave(up, down, layer_optics, μ0, toa, α_dir, α_dif, weights,
                                           ng, nlayers, scratch) =
    @allocated streaming_shortwave_fluxes!(up, down, layer_optics, μ0, toa, α_dir, α_dif, weights,
                                           ng, nlayers, scratch)

@testset "streaming shortwave is inferrable and allocation-free, $FT" for FT in (Float64, Float32)
    fixture = shortwave_fixture(FT)
    (; ng, nlayers, layer_optics, weights, direct_albedo, diffuse_albedo) = fixture
    up, down = zeros(FT, nlayers + 1), zeros(FT, nlayers + 1)
    scratch = ShortwaveColumnScratch(FT, nlayers)
    μ0, toa = FT(0.5), FT(1361) * FT(0.5)
    @test (@inferred streaming_shortwave_fluxes!(up, down, layer_optics, μ0, toa, direct_albedo,
                                                 diffuse_albedo, weights, ng, nlayers, scratch)) === nothing
    for _ in 1:2   # compile on the first pass, measure on the second
        @test measure_streaming_shortwave(up, down, layer_optics, μ0, toa, direct_albedo, diffuse_albedo,
                                          weights, ng, nlayers, scratch) == 0
        # Scalar albedos and a tuple of weights, as a host with one g point passes.
        @test measure_streaming_shortwave(up, down, layer_optics, μ0, toa, FT(0.1), FT(0.2),
                                          (one(FT),), 1, nlayers, scratch) == 0
    end
    # Views of host matrices as scratch and flux storage allocate nothing either.
    layers, interfaces = zeros(FT, 5, nlayers), zeros(FT, 4, nlayers + 1)
    view_scratch = ShortwaveColumnScratch(view(layers, 1, :), view(layers, 2, :), view(layers, 3, :),
                                          view(layers, 4, :), view(layers, 5, :),
                                          view(interfaces, 1, :), view(interfaces, 2, :))
    view_up, view_down = view(interfaces, 3, :), view(interfaces, 4, :)
    for _ in 1:2
        @test measure_streaming_shortwave(view_up, view_down, layer_optics, μ0, toa, direct_albedo,
                                          diffuse_albedo, weights, ng, nlayers, view_scratch) == 0
    end
    streaming_shortwave_fluxes!(up, down, layer_optics, μ0, toa, direct_albedo, diffuse_albedo,
                                weights, ng, nlayers, scratch)
    @test view_up == up && view_down == down
end

end # module TestStreaming
