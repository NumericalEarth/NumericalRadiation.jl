# Per-step detector for the first non-finite value in a SpeedyWeather run with
# `ClearSkyEcCKDRadiation` (plan Phase 4). It found the two-stream singularity that made
# the coupled model go NaN after a few days: the callback keeps the previous
# step's surface state per column, stops at the first non-finite soil
# temperature, near-surface air temperature, surface flux or longwave flux, and
# dumps that column before and after, including the ecCKD work arrays.
#
#   julia --project=<env> validation/speedyweather_nan_detector.jl
# Environment variables: DAYS (default 12), ECCKD_MODEL (default 32x32).

using SpeedyWeather, NumericalRadiation, NCDatasets, Statistics, Printf, Dates

mutable struct NaNDetector <: SpeedyWeather.AbstractCallback
    step::Int
    previous::Dict{Symbol, Any}
end
NaNDetector() = NaNDetector(0, Dict{Symbol, Any}())

surface_fields(vars, model) = (
    soil_T = Array(vars.prognostic.land.soil_temperature[:, 1]),
    soil_T2 = Array(vars.prognostic.land.soil_temperature[:, 2]),
    air_T8 = Array(SpeedyWeather.get_prognostic_step(vars.grid.temperature, model.time_stepping, model.radiation)[:, 8]),
    air_q8 = Array(SpeedyWeather.get_prognostic_step(vars.grid.humidity, model.time_stepping, model.radiation)[:, 8]),
    sw_down = Array(vars.parameterizations.land.surface_shortwave_down),
    lw_down = Array(vars.parameterizations.surface_longwave_down),
    lw_up_land = Array(vars.parameterizations.land.surface_longwave_up),
    sensible = haskey(vars.parameterizations, :sensible_heat_flux) ? Array(vars.parameterizations.sensible_heat_flux) : nothing,
    evap = haskey(vars.parameterizations, :surface_humidity_flux) ? Array(vars.parameterizations.surface_humidity_flux) : nothing,
    soil_moisture = haskey(vars.prognostic.land, :soil_moisture) ? Array(vars.prognostic.land.soil_moisture[:, 1]) : nothing,
    cosz = Array(vars.parameterizations.cos_zenith),
    ps = Array(vars.parameterizations.surface_pressure),
)

SpeedyWeather.initialize!(cb::NaNDetector, vars, model) = (cb.previous = Dict(pairs(surface_fields(vars, model))); nothing)
SpeedyWeather.finalize!(::NaNDetector, vars, model) = nothing

function SpeedyWeather.callback!(cb::NaNDetector, vars, model)
    cb.step += 1
    now = surface_fields(vars, model)
    bad = Int[]
    for name in (:soil_T, :air_T8, :lw_down, :lw_up_land, :sw_down)
        x = getproperty(now, name)
        append!(bad, findall(!isfinite, x))
    end
    W = vars.parameterizations.ecckd
    for ij in 1:model.spectral_grid.npoints
        all(isfinite, @view W.longwave_up[ij, :]) || push!(bad, ij)
    end
    if cb.step % 24 == 0
        ij = argmax(now.soil_T)
        @printf("step %4d  land T max %6.1f at ij=%d (lat %.1f)  air T8 %6.1f  SWdn %6.1f  LWdn %6.1f  LWup %6.1f  sens %7.1f  moisture %s\n", cb.step, now.soil_T[ij], ij,
                model.geometry.latds[ij], now.air_T8[ij], now.sw_down[ij], now.lw_down[ij], now.lw_up_land[ij],
                now.sensible === nothing ? NaN : now.sensible[ij], now.soil_moisture === nothing ? "-" : string(round(now.soil_moisture[ij], digits = 3)))
    end
    if !isempty(bad)
        println("\nFIRST NON-FINITE at step ", cb.step, " (", vars.prognostic.clock.time, ") in ", length(unique(bad)), " columns")
        for ij in unique(bad)[1:min(3, end)]
            @printf("  ij=%d lat %.1f lon %.1f land %.2f\n", ij, model.geometry.latds[ij], model.geometry.londs[ij], model.land_sea_mask.land_fraction[ij])
            for name in keys(now)
                x = getproperty(now, name); x === nothing && continue
                p = cb.previous[name]
                println("     ", rpad(name, 14), " prev ", p[ij], "  now ", x[ij])
            end
            T = SpeedyWeather.get_prognostic_step(vars.grid.temperature, model.time_stepping, model.radiation)
            println("     air T column now  ", Array(T[ij, :]))
            println("     LW up/down now    ", Array(W.longwave_up[ij, :]), " / ", Array(W.longwave_down[ij, :]))
            println("     SW up/down now    ", Array(W.shortwave_up[ij, :]), " / ", Array(W.shortwave_down[ij, :]))
            println("     T_half now        ", Array(W.temperature_interfaces[ij, :]))
            println("     gas amounts now   ", Array(W.gas_amounts[ij, :, :]))
            println("     emission now      ", Array(W.surface_emission[ij, :]))
        end
        error("stop")
    end
    cb.previous = Dict(pairs(now))
    return nothing
end

spectral_grid = SpectralGrid(truncation = 31, nlayers = 8)
radiation = ClearSkyEcCKDRadiation(spectral_grid, get(ENV, "ECCKD_MODEL", "32x32"))
model = PrimitiveWetModel(spectral_grid; radiation)
add!(model.callbacks, :nan => NaNDetector())
simulation = initialize!(model, time = DateTime(2000, 1, 1))
try
    run!(simulation, period = Day(parse(Int, get(ENV, "DAYS", "12"))))
catch err
    println("stopped: ", err isa ErrorException ? err.msg : typeof(err))
end
println("finished at ", simulation.variables.prognostic.clock.time)
