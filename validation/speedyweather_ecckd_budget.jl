# Whole-model comparison of NumericalRadiation's clear-sky ecCKD radiation against
# SpeedyWeather's default one-band schemes (plan Phase 4).
#
# Runs PrimitiveWetModel at T31 L8 with three radiation setups, spins up, then
# averages daily snapshots of the TOA/surface radiation budget and the
# temperature profile. Instantaneous global means of the insolation are exact
# (the global mean of cos_zenith is 1/4 at any instant), so snapshots suffice.
#
# Run from the repository root in an environment that develops NumericalRadiation
# and a SpeedyWeather with the `Radiation` bundle, plus NCDatasets and Statistics:
#   julia --project=<env> validation/speedyweather_ecckd_budget.jl
# Environment variables: SPINUP_DAYS (default 10), AVERAGE_DAYS (default 10),
# CONFIGS (comma separated subset of oneband,ecckd32,ecckd32_noo3,ecckd64x96).

using SpeedyWeather, NumericalRadiation, NCDatasets, Statistics, Printf, Dates
const SpeedyExt = Base.get_extension(NumericalRadiation, :NumericalRadiationSpeedyWeatherExt)

spinup_days = parse(Int, get(ENV, "SPINUP_DAYS", "10"))
average_days = parse(Int, get(ENV, "AVERAGE_DAYS", "10"))
configs = Symbol.(split(get(ENV, "CONFIGS", "oneband,ecckd32,ecckd32_noo3"), ","))

spectral_grid = SpectralGrid(truncation = 31, nlayers = 8)

radiation_for(::Val{:oneband}) = Radiation(spectral_grid)
radiation_for(::Val{:ecckd32}) = SpeedyExt.EcCKDRadiation(spectral_grid, "32x32")
radiation_for(::Val{:ecckd32_noo3}) = SpeedyExt.EcCKDRadiation(spectral_grid, "32x32"; ozone = 0.0)
radiation_for(::Val{:ecckd64x96}) = SpeedyExt.EcCKDRadiation(spectral_grid, "64x96")

# area weights of the reduced grid: ring weight cos(lat) shared equally by the ring's points
function area_weights(model)
    grid = model.spectral_grid.grid
    whichring = grid.whichring
    coslat = model.geometry.coslat
    npoints_ring = zeros(Int, length(coslat))
    for j in whichring
        npoints_ring[j] += 1
    end
    w = [coslat[whichring[ij]] / npoints_ring[whichring[ij]] for ij in eachindex(whichring)]
    return w ./ sum(w)
end
global_mean(field, w) = sum(Array(field) .* w)

function snapshot(simulation, w)
    P = simulation.variables.parameterizations
    model = simulation.model
    T = simulation.variables.grid.temperature
    T_now = SpeedyWeather.get_prognostic_step(T, model.time_stepping, model.radiation)
    insolation = model.planet.solar_constant .* Array(P.cos_zenith)
    return (
        olr = global_mean(P.outgoing_longwave, w),
        osr = global_mean(P.outgoing_shortwave, w),
        toa_insolation = sum(insolation .* w),
        surface_sw_down = global_mean(P.surface_shortwave_down, w),
        surface_lw_down = global_mean(P.surface_longwave_down, w),
        surface_lw_up = global_mean(P.surface_longwave_up, w),
        temperature = [sum(Array(T_now[:, k]) .* w) for k in 1:model.spectral_grid.nlayers],
        surface_pressure = global_mean(P.surface_pressure, w),
    )
end

average(snaps) = (; (k => mean(getproperty(s, k) for s in snaps) for k in keys(first(snaps)))...)

results = Dict{Symbol, Any}()
for config in configs
    println("\n=== $config ===")
    model = PrimitiveWetModel(spectral_grid; radiation = radiation_for(Val(config)))
    simulation = initialize!(model, time = DateTime(2000, 1, 1))
    w = area_weights(model)

    t_spinup = @elapsed run!(simulation, period = Day(spinup_days))
    snaps = []
    t_average = @elapsed for day in 1:average_days
        run!(simulation, period = Day(1))
        push!(snaps, snapshot(simulation, w))
    end
    steps_total = Int(round((spinup_days + average_days) * 86400 / (model.time_stepping.Δt_millisec.value / 1000)))
    seconds_per_step = (t_spinup + t_average) / steps_total
    m = average(snaps)
    results[config] = (; m..., seconds_per_step, final_time = simulation.variables.prognostic.clock.time)

    @printf("%-28s %10.2f W/m²\n", "TOA insolation", m.toa_insolation)
    @printf("%-28s %10.2f W/m²\n", "outgoing longwave", m.olr)
    @printf("%-28s %10.2f W/m²\n", "outgoing shortwave", m.osr)
    @printf("%-28s %10.2f W/m²\n", "TOA net (down)", m.toa_insolation - m.osr - m.olr)
    @printf("%-28s %10.3f\n", "planetary albedo", m.osr / m.toa_insolation)
    @printf("%-28s %10.2f W/m²\n", "surface shortwave down", m.surface_sw_down)
    @printf("%-28s %10.2f W/m²\n", "surface longwave down", m.surface_lw_down)
    @printf("%-28s %10.2f W/m²\n", "surface longwave up", m.surface_lw_up)
    @printf("%-28s %10.1f hPa\n", "surface pressure", m.surface_pressure / 100)
    println("global-mean temperature per layer (k = 1 top): ", join((@sprintf("%.1f", t) for t in m.temperature), "  "))
    @printf("%-28s %10.3f s (%d steps, final time %s)\n", "wall time per step", seconds_per_step, steps_total, results[config].final_time)
end

println("\n=== summary (means over $(average_days) days after $(spinup_days) days spin-up) ===")
@printf("%-14s %8s %8s %8s %8s %8s %10s\n", "config", "OLR", "OSR", "TOA net", "albedo", "T(k=1)", "s/step")
for config in configs
    r = results[config]
    @printf("%-14s %8.1f %8.1f %8.1f %8.3f %8.1f %10.3f\n", config, r.olr, r.osr,
            r.toa_insolation - r.osr - r.olr, r.osr / r.toa_insolation, r.temperature[1], r.seconds_per_step)
end
