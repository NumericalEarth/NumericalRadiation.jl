# Sigma-coordinate flux → tendency helpers.
#
# A net downward flux F  [W m⁻²] crossing a layer whose pressure thickness is
# pₛ · Δσₖ  contributes (F / (pₛ Δσₖ / g))  [W / (kg m⁻²)] = (g / pₛ Δσₖ) · F
# to the column's enthalpy. Callers divide by cₚ before passing the flux so
# the helper returns a temperature tendency directly.
#
# These are the same three one-liners used in SpeedyWeather's
# `src/parameterizations/tendencies.jl` — reproduced here so the package has
# no dependency on SpeedyWeather.

@inline flux_to_tendency(flux, surface_pressure, gravity, σ_thick_k) = gravity / (surface_pressure * σ_thick_k) * flux

@inline flux_to_tendency(flux, profile::AtmosphereProfile, geometry::ColumnGrid, constants, k::Integer) =
    flux_to_tendency(flux, profile.surface_pressure, constants.gravity, geometry.σ_thick[k])

@inline surface_flux_to_tendency(flux, profile::AtmosphereProfile, geometry::ColumnGrid, constants) =
    flux_to_tendency(flux, profile.surface_pressure, constants.gravity, geometry.σ_thick[end])
