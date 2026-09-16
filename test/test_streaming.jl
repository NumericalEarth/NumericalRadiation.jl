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

end # module TestStreaming
