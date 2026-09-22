# Sigma-coordinate flux → tendency helpers.
#
# A net downward flux ℐ [W m⁻²] crossing a layer whose pressure thickness is
# pˢ Δσ_k contributes (ℐ / (pˢ Δσ_k / g)) [W / (kg m⁻²)] = (g / pˢ Δσ_k) ℐ
# to the column's enthalpy. Callers divide by cᵖ before passing the flux so
# the helper returns a temperature tendency directly.
#
# These are the same three one-liners used in SpeedyWeather's
# `src/parameterizations/tendencies.jl` — reproduced here so the package has
# no dependency on SpeedyWeather.

@inline flux_to_tendency(ℐ, pˢ, g, Δσ_k) = g / (pˢ * Δσ_k) * ℐ

@inline flux_to_tendency(flux, profile::AtmosphereProfile, geometry::ColumnGrid, constants, k::Integer) =
    flux_to_tendency(flux, profile.surface_pressure, constants.gravity, geometry.σ_thick[k])

@inline surface_flux_to_tendency(flux, profile::AtmosphereProfile, geometry::ColumnGrid, constants) =
    flux_to_tendency(flux, profile.surface_pressure, constants.gravity, geometry.σ_thick[end])
