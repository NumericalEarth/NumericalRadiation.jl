"""
$(TYPEDEF)

Zero-atmosphere shortwave: TOA insolation reaches the surface unattenuated
and is reflected by the surface albedo. Temperature tendencies are zero.
Useful as a baseline and for tests of the surface energy budget.
"""
struct TransparentShortwave <: AbstractShortwaveScheme end

Adapt.@adapt_structure TransparentShortwave

"""$(TYPEDSIGNATURES)
Column transparent-atmosphere shortwave.
"""
function solve_shortwave!(temperature_tendency::AbstractVector,
                          diagnostics::ShortwaveDiagnostics{NF},
                          ::TransparentShortwave,
                          profile::AtmosphereProfile,
                          geometry::ColumnGrid,
                          surface::SurfaceState,
                          constants,
                          thermodynamic;
                          cloud_top_convective::Integer = length(profile.temperature) + 1) where NF
    S₀ = NF(constants.solar_constant)
    μ₀ = NF(surface.cos_zenith)
    ℐꜜ = S₀ * μ₀

    diagnostics.surface_shortwave_down       = ℐꜜ
    diagnostics.ocean_surface_shortwave_down = ℐꜜ
    diagnostics.land_surface_shortwave_down  = ℐꜜ

    ℐꜛ_ocean = NF(surface.ocean_albedo) * ℐꜜ
    ℐꜛ_land  = NF(surface.land_albedo)  * ℐꜜ
    α = (1 - NF(surface.land_fraction)) * NF(surface.ocean_albedo) + NF(surface.land_fraction) * NF(surface.land_albedo)

    diagnostics.ocean_surface_shortwave_up = ℐꜛ_ocean
    diagnostics.land_surface_shortwave_up  = ℐꜛ_land
    diagnostics.surface_shortwave_up       = α * ℐꜜ
    diagnostics.albedo                     = α
    diagnostics.outgoing_shortwave         = diagnostics.surface_shortwave_up

    diagnostics.cloud_cover        = zero(NF)
    diagnostics.stratocumulus_cover = zero(NF)
    diagnostics.cloud_top          = length(profile.temperature) + 1
    return nothing
end
