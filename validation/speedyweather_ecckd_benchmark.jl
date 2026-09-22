# Per-column cost of the radiation schemes inside SpeedyWeather's column kernel
# (plan Phase 4): the default one-band pair, the analytic-band longwave, and
# ecCKD with the 32x32 and 64x96 reference pairs. Times `column_parameterizations!`
# with radiation as the only parameterization on a realistic initialized state.
#
#   julia --project=<env> validation/speedyweather_ecckd_benchmark.jl

using SpeedyWeather, NumericalRadiation, NCDatasets, Printf, Statistics
const SpeedyExt = Base.get_extension(NumericalRadiation, :NumericalRadiationSpeedyWeatherExt)

spectral_grid = SpectralGrid(truncation = 31, nlayers = 8)
configs = (
    :oneband => () -> Radiation(spectral_grid),
    :analytic_lw => () -> Radiation(spectral_grid; longwave = SpeedyExt.SpeedyAnalyticBandLongwave(spectral_grid)),
    :ecckd32x32 => () -> SpeedyExt.EcCKDRadiation(spectral_grid, "32x32"),
    :ecckd64x96 => () -> SpeedyExt.EcCKDRadiation(spectral_grid, "64x96"),
)

@printf("%-14s %12s %12s %10s\n", "config", "s/step", "μs/column", "allocs")
for (name, make) in configs
    radiation = make()
    model = PrimitiveWetModel(spectral_grid; radiation, parameterizations = (:solar_zenith, :albedo, :radiation))
    simulation = initialize!(model)
    run!(simulation, steps = 2)                       # realistic state, everything compiled
    vars = simulation.variables
    SpeedyWeather.column_parameterizations!(vars, model)   # warm up this exact call
    n = 5
    t = @elapsed for _ in 1:n
        SpeedyWeather.column_parameterizations!(vars, model)
    end
    allocs = @allocated SpeedyWeather.column_parameterizations!(vars, model)
    per_step = t / n
    @printf("%-14s %12.4f %12.2f %10d\n", name, per_step, 1e6 * per_step / spectral_grid.npoints, allocs)
end
println("npoints = ", spectral_grid.npoints, ", nlayers = ", spectral_grid.nlayers, ", NF = ", spectral_grid.NF)
