# Longwave: Williams (2026) Simple Spectral Model

The [`AnalyticBandLongwave`](@ref) solver advances Schwarzschild's two-stream
equations

```math
\frac{dF^{\uparrow}}{d\tau} = F^{\uparrow} - \pi B(T), \qquad
\frac{dF^{\downarrow}}{d\tau} = \pi B(T) - F^{\downarrow}
```

at each of `nwavenumber = 41` evenly spaced wavenumbers between 10 and
2500 cm⁻¹ (inclusive of both endpoints, spacing 62.25 cm⁻¹) and integrates
the resulting fluxes spectrally.

## Absorption spectra

The scheme represents three analytic sources of clear-sky absorption:

```@example absorption
using NumericalRadiation
using CairoMakie

lw = AnalyticBandLongwave(Float64)
ν̃  = range(lw.wavenumber_min, lw.wavenumber_max, length = 500)

# Replace zeros with NaN so the log-y plot shows gaps where a band is inactive.
nan_zero(v) = [x == 0 ? NaN : x for x in v]

κ_h2o_line = nan_zero([h2o_line_kappa_ref(ν, lw) for ν in ν̃])
κ_h2o_cont =          [h2o_cont_kappa_ref(ν, lw) for ν in ν̃]
κ_CO₂      = nan_zero([co2_kappa_ref(ν, lw)      for ν in ν̃])

fig = Figure(size = (760, 440))
ax  = Axis(fig[1, 1];
           xlabel = "Wavenumber ν̃ [cm⁻¹]",
           ylabel = "κ [m² kg⁻¹]",
           yscale = log10,
           title  = "Williams (2026) reference absorption (T = 260 K, p = 500 hPa)")
lines!(ax, ν̃, κ_h2o_line; label = "H₂O line",      linewidth = 2)
lines!(ax, ν̃, κ_h2o_cont; label = "H₂O continuum", linewidth = 2)
lines!(ax, ν̃, κ_CO₂;      label = "CO₂ 15 μm",      linewidth = 2, linestyle = :dash)
axislegend(ax; position = :rt)
save("absorption.png", fig); nothing # hide
```

![](absorption.png)

All three curves are evaluated at the paper's reference state
`(T, p, RH) = (260 K, 500 hPa, 100 %)`. At runtime
[`williams_delta_tau`](@ref)
applies pressure broadening (`κ ∝ p / p_ref`), continuum temperature scaling
(`exp(σ_cont (T_ref − T))`, Mlawer et al. 1997), and the two-stream
diffusivity factor `D = 1.5` (Armstrong 1968).

## 2 × CO₂ clear-sky forcing

A standard clear-sky CO₂-doubling benchmark. The column is a lapse-rate
atmosphere from 220 K at the top to 295 K at the surface with constant
specific humidity `q = 5 g kg⁻¹` and surface pressure 1000 hPa.

```@example forcing
using NumericalRadiation
using CairoMakie

nlayers = 32
σ_half  = collect(range(0.0, 1.0, length = nlayers + 1))
geom    = ColumnGrid(σ_half)

surface   = SurfaceState{Float64}(sea_surface_temperature = 295.0,
                                   land_surface_temperature = 285.0,
                                   land_fraction = 0.3)
constants = PhysicalConstants{Float64}()
lw        = AnalyticBandLongwave(Float64)

# Sweep CO₂
co2s = [50.0, 100.0, 200.0, 280.0, 400.0, 560.0, 800.0, 1120.0]
olrs = Float64[]
for c in co2s
    profile = AtmosphereProfile(
        temperature      = collect(range(220.0, 295.0, length = nlayers)),
        humidity         = fill(0.005, nlayers),
        geopotential     = zeros(nlayers),
        surface_pressure = 100_000.0,
        CO₂              = c,
    )
    dT  = zeros(nlayers)
    dg  = LongwaveDiagnostics{Float64}()
    solve_longwave!(dT, dg, lw, profile, geom, surface, constants)
    push!(olrs, dg.outgoing_longwave)
end

fig = Figure(size = (820, 360))
ax1 = Axis(fig[1, 1];
           xlabel = "CO₂ [ppmv]",
           ylabel = "ℐꜛˡʷ at TOA [W m⁻²]",
           xscale = log10,
           title  = "Clear-sky outgoing longwave vs CO₂")
lines!(ax1, co2s, olrs;   color = :black, linestyle = :dash)
scatter!(ax1, co2s, olrs; markersize = 10, color = :black)

ax2 = Axis(fig[1, 2];
           xlabel = "CO₂ [ppmv]",
           ylabel = "ℐꜛˡʷ(280) − ℐꜛˡʷ(CO₂) [W m⁻²]",
           xscale = log10,
           title  = "Clear-sky CO₂ radiative forcing")
lines!(ax2, co2s, olrs[4] .- olrs; color = :crimson, linewidth = 2)
scatter!(ax2, co2s, olrs[4] .- olrs; markersize = 10, color = :crimson)
vlines!(ax2, 560; color = :gray70, linestyle = :dot)
hlines!(ax2, 0;   color = :gray70)

forcing_280_560 = olrs[4] - olrs[6]
Label(fig[2, 1:2], "2× CO₂ forcing (280 → 560 ppmv) = $(round(forcing_280_560, digits = 2)) W m⁻²";
      tellwidth = false, fontsize = 12)
save("forcing.png", fig); nothing # hide
```

![](forcing.png)

The forcing of `OLR(280) − OLR(560)` is in the physically plausible range
for clear-sky 2×CO₂ (2–5 W m⁻², cf. IPCC AR6 WG1 Ch. 7).
