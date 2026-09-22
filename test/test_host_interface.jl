# Host-model facing preparations: element-type conversion of tabulated models
# and ColumnAtmosphere built from views of differently shaped host arrays. Wrapped in a module so the fixture
# helpers cannot clash with other test files.

module TestHostInterface

using Test
using NumericalRadiation

# Small tabulated model with every optional table populated, in Float64.
function host_fixture_model()
    np, nt, nh2o = 4, 3, 3
    ng_lw, ng_sw, ngas = 3, 2, 3
    pressure_grid = exp.(range(log(5_000.0), log(100_000.0), length = np))
    temperature_grid = [200.0, 250.0, 300.0]
    source_temperature_grid = [180.0, 240.0, 300.0]
    return EcCKDTabulatedGasOpticsModel(
        names = (:h2o, :co2, :composite),
        pressure_grid = pressure_grid,
        temperature_grid = temperature_grid,
        water_vapor_mole_fraction_grid = [1e-6, 1e-4, 1e-2],
        gas_reference_mole_fractions = [0.0, 4e-4, 0.0],
        longwave_absorption =
            [1e-4 * (7ig + 3j) * (1 + 1e-5 * pressure_grid[ip]) * (1 + 1e-3 * temperature_grid[it])
             for ig in 1:ng_lw, j in 1:ngas, ip in 1:np, it in 1:nt],
        shortwave_absorption =
            [1e-5 * (5ig + 2j) * (1 + 2e-5 * pressure_grid[ip]) * (1 + 2e-3 * temperature_grid[it])
             for ig in 1:ng_sw, j in 1:ngas, ip in 1:np, it in 1:nt],
        longwave_water_vapor_absorption =
            [1e-3 * ig * (1 + 10ih) for ig in 1:ng_lw, ip in 1:np, it in 1:nt, ih in 1:nh2o],
        shortwave_water_vapor_absorption =
            [1e-4 * ig * (1 + 5ih) for ig in 1:ng_sw, ip in 1:np, it in 1:nt, ih in 1:nh2o],
        shortwave_rayleigh_molar_scattering = [1.1e-6, 3.7e-6],
        longwave_source_temperature_grid = source_temperature_grid,
        longwave_source_table = [(ig + 2) * st^2 for ig in 1:ng_lw, st in source_temperature_grid],
        longwave_weights = [0.2, 0.3, 0.5],
        shortwave_weights = [0.45, 0.55],
    )
end

function host_fixture_optics(FT, model, nlayers)
    ng_lw = length(model.longwave_weights)
    ng_sw = length(model.shortwave_weights)
    longwave = LongwaveOptics(zeros(FT, ng_lw, nlayers), zeros(FT, ng_lw, nlayers);
                              source_top = zeros(FT, ng_lw, nlayers),
                              source_bottom = zeros(FT, ng_lw, nlayers),
                              weights = zeros(FT, ng_lw))
    shortwave = ShortwaveOptics(zeros(FT, ng_sw, nlayers);
                                rayleigh_optical_depth = zeros(FT, ng_sw, nlayers),
                                scattering_asymmetry = zeros(FT, ng_sw, nlayers),
                                weights = zeros(FT, ng_sw))
    return longwave, shortwave
end

@testset "EcCKDTabulatedGasOpticsModel{FT} element-type conversion" begin
    model = host_fixture_model()
    model32 = EcCKDTabulatedGasOpticsModel{Float32}(model)

    @test eltype(model) === Float64
    @test eltype(model32) === Float32
    @test NumericalRadiation.gas_names(model32) == NumericalRadiation.gas_names(model)
    for name in fieldnames(typeof(model))
        a, b = getfield(model, name), getfield(model32, name)
        a === nothing && (@test b === nothing; continue)
        @test eltype(b) === Float32
        @test size(b) == size(a)
        @test b ≈ a rtol = 1e-6
    end

    # converting to the same type reuses the arrays
    same = EcCKDTabulatedGasOpticsModel{Float64}(model)
    @test same.longwave_absorption === model.longwave_absorption
    @test same.pressure_grid === model.pressure_grid

    # the Float32 model produces Float32 optics close to the Float64 ones
    nlayers = 3
    atmosphere(FT) = ColumnAtmosphere(
        pressure_layers = FT[7_500, 33_000, 88_000],
        pressure_interfaces = FT[1_000, 14_000, 52_000, 101_000],
        temperature_layers = FT[217.3, 263.9, 291.4],
        temperature_interfaces = FT[205.1, 231.7, 279.2, 297.8],
        gases = (h2o = FT[3.1, 12.7, 41.9], co2 = FT(8.3), composite = FT[4.2e2, 1.1e3, 2.6e3]),
        surface = (;), geometry = (;))
    lw64, sw64 = host_fixture_optics(Float64, model, nlayers)
    lw32, sw32 = host_fixture_optics(Float32, model32, nlayers)
    optical_properties!(lw64, sw64, model, atmosphere(Float64))
    optical_properties!(lw32, sw32, model32, atmosphere(Float32))
    @test eltype(lw32.optical_depth) === Float32
    @test lw32.optical_depth ≈ lw64.optical_depth rtol = 1e-4
    @test lw32.source ≈ lw64.source rtol = 1e-4
    @test sw32.optical_depth ≈ sw64.optical_depth rtol = 1e-4
    @test sw32.rayleigh_optical_depth ≈ sw64.rayleigh_optical_depth rtol = 1e-4

    # absent optional tables stay absent
    plain = EcCKDTabulatedGasOpticsModel(
        names = (:h2o, :co2),
        pressure_grid = [10_000.0, 100_000.0],
        temperature_grid = [220.0, 300.0],
        longwave_absorption = ones(2, 2, 2, 2),
        shortwave_absorption = ones(2, 2, 2, 2),
    )
    plain32 = EcCKDTabulatedGasOpticsModel{Float32}(plain)
    @test isempty(plain32.longwave_water_vapor_absorption)
    @test isempty(plain32.water_vapor_mole_fraction_grid)
    @test plain32.longwave_source_table === nothing
    @test eltype(plain32.longwave_weights) === Float32

    # Reference-file-sized grids survive the Float32 round trip: the constructor
    # re-validates log-uniform spacing to 1e-5 relative, and a 53-point pressure
    # grid over five decades deviates by a few 1e-6 in Float32 arithmetic.
    np, nh2o = 53, 12
    wide = EcCKDTabulatedGasOpticsModel(
        names = (:h2o, :co2),
        pressure_grid = Float64.(Float32.(exp.(range(log(1.0), log(1.1e5), length = np)))),
        temperature_grid = [200.0, 250.0, 300.0],
        water_vapor_mole_fraction_grid = Float64.(Float32.(exp.(range(log(1e-7), log(0.1), length = nh2o)))),
        longwave_absorption = ones(2, 2, np, 3),
        shortwave_absorption = ones(2, 2, np, 3),
        longwave_water_vapor_absorption = ones(2, np, 3, nh2o),
        shortwave_water_vapor_absorption = ones(2, np, 3, nh2o),
    )
    wide32 = EcCKDTabulatedGasOpticsModel{Float32}(wide)
    @test eltype(wide32.pressure_grid) === Float32
    @test length(wide32.water_vapor_mole_fraction_grid) == nh2o
end

@testset "ColumnAtmosphere from differently shaped host views" begin
    model = host_fixture_model()
    nlayers = 3
    npoints = 5
    ij = 2

    # host-style storage: layers in a (npoints, nlayers) matrix, interfaces in a
    # (npoints, nlayers + 1) matrix, temperatures with a trailing step dimension
    pressure_layers = zeros(npoints, nlayers)
    pressure_interfaces = zeros(npoints, nlayers + 1)
    temperature_layers = zeros(npoints, nlayers, 2)
    temperature_interfaces = zeros(npoints, nlayers + 1)
    pressure_layers[ij, :] .= [7_500, 33_000, 88_000]
    pressure_interfaces[ij, :] .= [1_000, 14_000, 52_000, 101_000]
    temperature_layers[ij, :, 1] .= [217.3, 263.9, 291.4]
    temperature_interfaces[ij, :] .= [205.1, 231.7, 279.2, 297.8]
    gases = (h2o = [3.1, 12.7, 41.9], co2 = 8.3, composite = [4.2e2, 1.1e3, 2.6e3])

    view_atmosphere = ColumnAtmosphere(
        pressure_layers = view(pressure_layers, ij, :),
        pressure_interfaces = view(pressure_interfaces, ij, :),
        temperature_layers = view(temperature_layers, ij, :, 1),
        temperature_interfaces = view(temperature_interfaces, ij, :),
        gases = gases, surface = (;), geometry = (;))
    vector_atmosphere = ColumnAtmosphere(
        pressure_layers = pressure_layers[ij, :],
        pressure_interfaces = pressure_interfaces[ij, :],
        temperature_layers = temperature_layers[ij, :, 1],
        temperature_interfaces = temperature_interfaces[ij, :],
        gases = gases, surface = (;), geometry = (;))
    @test eltype(view_atmosphere) === Float64

    results = map((view_atmosphere, vector_atmosphere)) do atmosphere
        longwave, shortwave = host_fixture_optics(Float64, model, nlayers)
        optical_properties!(longwave, shortwave, model, atmosphere)
        fluxes = RadiativeFluxes(longwave_up = zeros(nlayers + 1), longwave_down = zeros(nlayers + 1),
                                 shortwave_up = zeros(nlayers + 1), shortwave_down = zeros(nlayers + 1))
        radiative_fluxes!(fluxes, CloudlessLongwave(), longwave, atmosphere,
                          LongwaveBoundaryConditions(surface_longwave_up = surface_longwave_emission(model, 297.8)))
        radiative_fluxes!(fluxes, CloudlessShortwave(), shortwave, atmosphere,
                          ShortwaveBoundaryConditions(toa_shortwave_down = 700.0, surface_albedo = 0.1))
        heating = zeros(nlayers)
        heating_rates!(heating, fluxes, atmosphere; gravity = 9.80665, heat_capacity = 1004.0)
        (longwave.optical_depth, fluxes.longwave_up, fluxes.shortwave_down, heating)
    end
    for (a, b) in zip(results[1], results[2])
        @test a == b
    end
    @test all(isfinite, results[1][4])
end

@testset "CloudlessShortwave with a caller-owned scratch" begin
    model = host_fixture_model()
    nlayers = 3
    atmosphere = ColumnAtmosphere(
        pressure_layers = [7_500.0, 33_000.0, 88_000.0],
        pressure_interfaces = [1_000.0, 14_000.0, 52_000.0, 101_000.0],
        temperature_layers = [217.3, 263.9, 291.4],
        temperature_interfaces = [205.1, 231.7, 279.2, 297.8],
        gases = (h2o = [3.1, 12.7, 41.9], co2 = 8.3, composite = [4.2e2, 1.1e3, 2.6e3]),
        surface = (;), geometry = (; cos_zenith = 0.6))
    longwave, shortwave = host_fixture_optics(Float64, model, nlayers)
    optical_properties!(longwave, shortwave, model, atmosphere)
    @test any(>(0), shortwave.rayleigh_optical_depth)      # the scattering path is exercised

    boundary = ShortwaveBoundaryConditions(toa_shortwave_down = 800.0, surface_albedo = 0.2)
    make_fluxes() = RadiativeFluxes(longwave_up = zeros(nlayers + 1), longwave_down = zeros(nlayers + 1),
                                    shortwave_up = zeros(nlayers + 1), shortwave_down = zeros(nlayers + 1))
    allocating = radiative_fluxes!(make_fluxes(), CloudlessShortwave(), shortwave, atmosphere, boundary)

    scratch = ShortwaveColumnScratch(Float64, nlayers)
    reused = make_fluxes()
    radiative_fluxes!(reused, CloudlessShortwave(), shortwave, atmosphere, boundary, scratch)
    @test reused.shortwave_up == allocating.shortwave_up
    @test reused.shortwave_down == allocating.shortwave_down
    @test all(>(0), reused.shortwave_up)                     # Rayleigh reflection reaches TOA
    radiative_fluxes!(reused, CloudlessShortwave(), shortwave, atmosphere, boundary, scratch)   # warm up
    @test (@allocated radiative_fluxes!(reused, CloudlessShortwave(), shortwave, atmosphere, boundary, scratch)) == 0

    # scratch built from views of host arrays, as a host model's column kernel does
    layers, interfaces = zeros(nlayers, 5), zeros(nlayers + 1, 2)
    from_views = ShortwaveColumnScratch(view(layers, :, 1), view(layers, :, 2), view(layers, :, 3),
                                        view(layers, :, 4), view(layers, :, 5),
                                        view(interfaces, :, 1), view(interfaces, :, 2))
    again = make_fluxes()
    radiative_fluxes!(again, CloudlessShortwave(), shortwave, atmosphere, boundary, from_views)
    @test again.shortwave_down == allocating.shortwave_down
end

@testset "shortwave two-stream near the direct-beam singularity k μ0 = 1" begin
    # Rayleigh-free absorbing layer: k = sqrt(γ1² - γ2²) with γ2 = 0, γ1 = 2 - 1.25 ω.
    for FT in (Float32, Float64), ω in (FT(6e-5), FT(0.3)), g in (FT(0), FT(0.5))
        γ1, γ2, _ = NumericalRadiation.shortwave_two_stream_coefficients(FT, FT(0.5), ω, g)
        k = sqrt((γ1 - γ2) * (γ1 + γ2))
        μ_singular = one(FT) / k
        for δ in FT.((0, 1e-7, -1e-7, 1e-6, -1e-6, 2e-6, 1e-5, 1e-4, 1e-3)), τ in FT.((0.01, 0.5, 4.5))
            μ0 = μ_singular + δ
            out = NumericalRadiation.shortwave_two_stream_layer(FT, μ0, τ, ω, g)
            @test all(isfinite, out)
            reflectance, transmittance, ref_dir, trans_dir_diff, direct = out
            @test 0 <= ref_dir <= 1
            @test 0 <= trans_dir_diff <= 1 - ref_dir
        end
        # away from the band the perturbation is inactive: results are continuous
        far = NumericalRadiation.shortwave_two_stream_layer(FT, μ_singular * (1 + FT(1e-2)), FT(0.5), ω, g)
        near = NumericalRadiation.shortwave_two_stream_layer(FT, μ_singular * (1 + FT(2e-3)), FT(0.5), ω, g)
        @test all(isapprox.(far[3:4], near[3:4]; atol = 0.05))
    end
end

end # module TestHostInterface
