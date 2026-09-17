using SpeedyWeather, Statistics
const SpeedyExt = Base.get_extension(NumericalRadiation, :NumericalRadiationSpeedyWeatherExt)

default_spectral_grid() = SpectralGrid(trunc=15, nlayers=8)

@testset "Model initializes and runs with SpeedyWeather" begin
    # Basic smoke test: construct, initialize, run one step in low resolution
    spectral_grid = default_spectral_grid()

    radiation = SpeedyExt.SpeedyAnalyticBandLongwave(spectral_grid)

    # use only longwave radiation as the only parameterization
    model = PrimitiveWetModel(spectral_grid; longwave_radiation=radiation, parameterizations=(:longwave_radiation,))

    initialize!(model.longwave_radiation, model)
    variables = Variables(model)
    variables.grid.pressure_prev .= 100000
    # k=1 is top layer, k=nlayers is bottom layer → temperature increases with k
    for k in 1:spectral_grid.nlayers
        variables.grid.temperature_prev[:, k] .= 220 + 9 * (k-1)
        variables.grid.humidity_prev[:, k]    .= 0.005
    end
    variables.prognostic.ocean.sea_surface_temperature .= 295
    variables.prognostic.land.soil_temperature[:, 1]   .= 285

    # run the parameterizations, here just longwave
    SpeedyWeather.column_parameterizations!(variables, model)

    # After one call, temperature tendency should be non-zero (atmosphere cools)
    @test any(!=(zero(spectral_grid.NF)), variables.tendencies.grid.temperature)
end

@testset "SpeedyWeather runs CO₂ forcing" begin
    # Construct, initialize, and run the column parameterization with two
    # different prescribed CO₂ concentrations. Verify that the tendency and
    # OLR respond in a physically sensible way (more CO₂ → less OLR, less
    # net longwave cooling of the column).
    spectral_grid = default_spectral_grid()
    NF = spectral_grid.NF

    radiation = SpeedyExt.SpeedyAnalyticBandLongwave(spectral_grid)

    co2 = CO2(spectral_grid, 280)

    model = PrimitiveWetModel(spectral_grid; longwave_radiation = radiation, parameterizations = (:longwave_radiation,),
                              greenhouse_gases = (; co2=co2))

    initialize!(model.longwave_radiation, model)
    variables = Variables(model)
    variables.grid.pressure_prev .= 100000
    # k=1 is top layer, k=nlayers is bottom layer → temperature increases with k
    for k in 1:spectral_grid.nlayers
        variables.grid.temperature_prev[:, k] .= 220 + 9 * (k-1)
        variables.grid.humidity_prev[:, k]    .= 0.005
    end
    variables.prognostic.ocean.sea_surface_temperature .= 295
    variables.prognostic.land.soil_temperature[:, 1]   .= 285

    # --- Run 1: 280 ppm CO₂ ---
    variables.prognostic.greenhouse_gases.co2[] = 280
    variables.tendencies.grid.temperature .= 0
    SpeedyWeather.column_parameterizations!(variables, model)
    Ṫ₁  = copy(variables.tendencies.grid.temperature)
    olr₁ = copy(variables.parameterizations.outgoing_longwave)

    # --- Run 2: 600 ppm CO₂ (much higher) ---
    variables.prognostic.greenhouse_gases.co2[] = 600
    variables.tendencies.grid.temperature .= 0
    SpeedyWeather.column_parameterizations!(variables, model)
    Ṫ₂  = copy(variables.tendencies.grid.temperature)
    olr₂ = copy(variables.parameterizations.outgoing_longwave)

    # Both runs produced finite, non-trivial tendencies.
    @test all(isfinite, Ṫ₁)
    @test all(isfinite, Ṫ₂)
    @test any(!=(zero(NF)), Ṫ₁)
    @test any(!=(zero(NF)), Ṫ₂)

    # Tendencies should differ between the two CO₂ levels (the forcing was applied).
    @test Ṫ₁ != Ṫ₂

    # OLR is positive and finite, and increasing CO₂ reduces OLR (greenhouse effect).
    @test all(isfinite, olr₁)
    @test all(>(zero(NF)), olr₁)
    @test all(>(zero(NF)), olr₂)
    @test all(olr₂ .< olr₁)

    # Global-mean OLR decreases at higher CO₂, confirming the forcing is active.
    @test mean(olr₂) < mean(olr₁)
end
