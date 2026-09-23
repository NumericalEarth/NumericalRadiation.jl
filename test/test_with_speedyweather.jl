using SpeedyWeather, Statistics

# The coupling is SpeedyWeather's extension SpeedyWeatherNumericalRadiationExt, active once
# both packages are loaded: it makes this package's AnalyticBandLongwave and ClearSkyEcCKDRadiation
# SpeedyWeather radiation schemes, with constructors from a SpectralGrid.
@test Base.get_extension(SpeedyWeather, :SpeedyWeatherNumericalRadiationExt) !== nothing

default_spectral_grid() = SpectralGrid(truncation = 16, nlayers = 8)

# Longwave-only model: the analytic-band scheme as the longwave part of the Radiation
# bundle, no shortwave, and no other parameterizations.
function longwave_only_model(spectral_grid; kwargs...)
    longwave = AnalyticBandLongwave(spectral_grid)
    radiation = Radiation(spectral_grid; shortwave = nothing, longwave)
    model = PrimitiveWetModel(spectral_grid; radiation, parameterizations = (:radiation,), kwargs...)
    initialize!(model.radiation, model)
    return model
end

# Idealised column state: temperature increasing towards the surface
# (k = 1 is the top layer), moist, warm ocean and land surfaces.
function set_test_state!(variables, model)
    nlayers = model.spectral_grid.nlayers
    variables.parameterizations.surface_pressure .= 100000        # [Pa]
    for k in 1:nlayers
        variables.grid.temperature[:, k, :] .= 220 + 9 * (k - 1)   # all time steps
        variables.grid.humidity[:, k, :] .= 0.005
    end
    variables.prognostic.ocean.sea_surface_temperature .= 295
    variables.prognostic.land.soil_temperature .= 285
    variables.tendencies.grid.temperature .= 0
    return nothing
end

@testset "Model initializes and runs with SpeedyWeather" begin
    spectral_grid = default_spectral_grid()
    model = longwave_only_model(spectral_grid)
    @test model.radiation.longwave isa AnalyticBandLongwave{spectral_grid.NF}

    variables = Variables(model)
    set_test_state!(variables, model)

    # run the parameterizations, here just longwave
    SpeedyWeather.column_parameterizations!(variables, model)

    # After one call, temperature tendency should be non-zero (atmosphere cools)
    @test any(!=(zero(spectral_grid.NF)), variables.tendencies.grid.temperature)
    @test all(isfinite, variables.tendencies.grid.temperature)
    @test all(>(zero(spectral_grid.NF)), variables.parameterizations.outgoing_longwave)
end

@testset "SpeedyWeather runs CO2 forcing" begin
    # Two prescribed CO₂ concentrations: more CO₂ → less OLR, different tendency.
    spectral_grid = default_spectral_grid()
    NF = spectral_grid.NF

    co2 = CO2(spectral_grid, 280)
    model = longwave_only_model(spectral_grid; greenhouse_gases = (; co2 = co2))
    variables = Variables(model)

    # --- Run 1: 280 ppm CO₂ ---
    set_test_state!(variables, model)
    variables.prognostic.greenhouse_gases.co2[] = 280
    SpeedyWeather.column_parameterizations!(variables, model)
    dT1  = copy(variables.tendencies.grid.temperature)
    olr1 = copy(variables.parameterizations.outgoing_longwave)

    # --- Run 2: 600 ppm CO₂ ---
    set_test_state!(variables, model)
    variables.prognostic.greenhouse_gases.co2[] = 600
    SpeedyWeather.column_parameterizations!(variables, model)
    dT2  = copy(variables.tendencies.grid.temperature)
    olr2 = copy(variables.parameterizations.outgoing_longwave)

    @test all(isfinite, dT1)
    @test all(isfinite, dT2)
    @test any(!=(zero(NF)), dT1)
    @test any(!=(zero(NF)), dT2)
    @test dT1 != dT2

    @test all(isfinite, olr1)
    @test all(>(zero(NF)), olr1)
    @test all(>(zero(NF)), olr2)
    @test all(olr2 .< olr1)
    @test mean(olr2) < mean(olr1)
end

@testset "Full model time steps with the analytic-band longwave" begin
    # Default wet model with only the longwave scheme swapped; a few steps run through.
    spectral_grid = default_spectral_grid()
    longwave = AnalyticBandLongwave(spectral_grid)
    model = PrimitiveWetModel(spectral_grid; radiation = Radiation(spectral_grid; longwave))
    simulation = initialize!(model)
    run!(simulation, steps = 4)
    @test all(isfinite, simulation.variables.parameterizations.outgoing_longwave)
    @test all(isfinite, simulation.variables.prognostic.temperature)
end
