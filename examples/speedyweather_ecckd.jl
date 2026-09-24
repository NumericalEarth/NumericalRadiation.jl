# # ecCKD radiation inside SpeedyWeather
#
# NumericalRadiation's clear-sky ecCKD gas optics can replace SpeedyWeather's
# one-band radiation as a single `radiation` component. This example runs the
# global model twice, once with SpeedyWeather's default one-band schemes and
# once with ecCKD, and compares the radiation budgets: global means at the top
# of the atmosphere and the surface, zonal-mean outgoing fluxes, and the
# global-mean temperature profile. It is a short version of the validation in
# `docs/plans/ecckd_speedyweather.md` (Phase 4), which averaged over ten days
# after ten days of spin-up; here both are five days so the script runs in
# about a minute.
#
# SpeedyWeather ≥ 0.23 is needed for the `Radiation` bundle (the `examples`
# environment points at the development branch until that is released), and
# `NCDatasets` loads the reference ecCKD tables:

using SpeedyWeather, NumericalRadiation, NCDatasets
using CairoMakie, Statistics, Printf, Dates

spinup_days  = 5
average_days = 5
spectral_grid = SpectralGrid(truncation = 31, nlayers = 8)

# ## The two radiation setups
#
# `Radiation(spectral_grid)` is SpeedyWeather's default pair, `OneBandShortwave`
# with diagnostic clouds and `OneBandLongwave`. `ClearSkyEcCKDRadiation` loads the
# 32-g-point longwave and shortwave reference tables, converts them to the
# grid's number format, and solves both streams from one gas-optics evaluation.
# It is clear-sky, takes CO₂ from the model's greenhouse gases (280 ppm here by
# default) and ozone from an analytic default profile.

setups = (
    oneband = Radiation(spectral_grid),
    ecckd   = ClearSkyEcCKDRadiation(spectral_grid, "32x32"),
)

# ## Area-weighted global and zonal means
#
# On SpeedyWeather's reduced grid every ring shares its cos(latitude) weight
# equally among its points.

function area_weights(model)
    whichring = model.spectral_grid.grid.whichring
    coslat = model.geometry.coslat
    points_per_ring = zeros(Int, length(coslat))
    foreach(j -> points_per_ring[j] += 1, whichring)
    w = [coslat[whichring[ij]] / points_per_ring[whichring[ij]] for ij in eachindex(whichring)]
    return w ./ sum(w)
end

global_mean(field, w) = sum(Array(field) .* w)

function zonal_mean(field, model)
    whichring = model.spectral_grid.grid.whichring
    nrings = length(model.geometry.latd)
    sums, counts = zeros(nrings), zeros(Int, nrings)
    for (ij, j) in enumerate(whichring)
        sums[j] += field[ij]
        counts[j] += 1
    end
    return sums ./ counts
end

# ## Run and average
#
# After the spin-up, daily snapshots are averaged. Snapshots are fine for
# global means of the shortwave budget because the global mean of the cosine
# of the solar zenith angle is exactly 1/4 at any instant.

function run_and_average(radiation)
    model = PrimitiveWetModel(spectral_grid; radiation)
    simulation = initialize!(model, time = DateTime(2000, 1, 1))
    run!(simulation, period = Day(spinup_days))
    w = area_weights(model)
    P = simulation.variables.parameterizations
    nlayers = spectral_grid.nlayers
    acc = (; olr = 0.0, osr = 0.0, insolation = 0.0, surface_sw_down = 0.0, surface_lw_down = 0.0,
             olr_zonal = zeros(length(model.geometry.latd)), osr_zonal = zeros(length(model.geometry.latd)),
             temperature = zeros(nlayers))
    for _ in 1:average_days
        run!(simulation, period = Day(1))
        T = SpeedyWeather.get_prognostic_step(simulation.variables.grid.temperature, model.time_stepping, radiation)
        acc = (;
            olr = acc.olr + global_mean(P.outgoing_longwave, w),
            osr = acc.osr + global_mean(P.outgoing_shortwave, w),
            insolation = acc.insolation + model.planet.solar_constant * global_mean(P.cos_zenith, w),
            surface_sw_down = acc.surface_sw_down + global_mean(P.surface_shortwave_down, w),
            surface_lw_down = acc.surface_lw_down + global_mean(P.surface_longwave_down, w),
            olr_zonal = acc.olr_zonal .+ zonal_mean(P.outgoing_longwave, model),
            osr_zonal = acc.osr_zonal .+ zonal_mean(P.outgoing_shortwave, model),
            temperature = acc.temperature .+ [global_mean(T[:, k], w) for k in 1:nlayers],
        )
    end
    means = map(x -> x ./ average_days, acc)
    return (; means..., latitude = model.geometry.latd, σ = Array(model.geometry.σ_levels_full))
end

results = map(run_and_average, setups)

# ## Global budgets

@printf("%-22s %10s %10s\n", "", "one-band", "ecCKD")
for (label, key) in (("TOA insolation", :insolation), ("outgoing longwave", :olr),
                     ("outgoing shortwave", :osr), ("surface SW down", :surface_sw_down),
                     ("surface LW down", :surface_lw_down))
    @printf("%-22s %10.1f %10.1f  W/m²\n", label, results.oneband[key], results.ecckd[key])
end
net(r) = r.insolation - r.osr - r.olr
@printf("%-22s %10.1f %10.1f  W/m²\n", "TOA net (down)", net(results.oneband), net(results.ecckd))
@printf("%-22s %10.3f %10.3f\n", "planetary albedo", results.oneband.osr / results.oneband.insolation,
        results.ecckd.osr / results.ecckd.insolation)

# The ecCKD atmosphere is clear-sky, so its planetary albedo is that of
# Rayleigh scattering plus the surface, and the top-of-atmosphere budget shows
# the missing cloud effect as a net downward imbalance of several tens of
# W m⁻². The one-band scheme's diagnostic clouds reflect about twice as much
# shortwave.

# ## Zonal means and temperature profile

fig = Figure(size = (1000, 400))
ax1 = Axis(fig[1, 1], xlabel = "latitude [˚N]", ylabel = "W/m²", title = "Outgoing longwave (zonal mean)")
ax2 = Axis(fig[1, 2], xlabel = "latitude [˚N]", ylabel = "W/m²", title = "Outgoing shortwave (zonal mean)")
ax3 = Axis(fig[1, 3], xlabel = "global-mean temperature [K]", ylabel = "σ", title = "Temperature profile",
           yreversed = true)
for (name, r, color) in ((:oneband, results.oneband, :steelblue), (:ecckd, results.ecckd, :firebrick))
    lines!(ax1, r.latitude, r.olr_zonal; color, label = String(name))
    lines!(ax2, r.latitude, r.osr_zonal; color, label = String(name))
    scatterlines!(ax3, r.temperature, r.σ; color, label = String(name))
end
axislegend(ax3, position = :rb)
figure_path = get(ENV, "FIGURE_PATH", joinpath(tempdir(), "speedyweather_ecckd.png"))
save(figure_path, fig)
println("figure written to ", figure_path)

# With the analytic ozone profile the ecCKD stratosphere (σ ≈ 0.06) sits
# within a few kelvin of the one-band model's; without ozone it would be
# about 20 K colder. The 64-longwave × 96-shortwave g-point pair
# (`ClearSkyEcCKDRadiation(spectral_grid, "64x96")`) gives the same budget to within
# 0.3 W m⁻² at twice the cost, so 32x32 is the sensible default.
