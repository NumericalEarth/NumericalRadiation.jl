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
    cos_zenith = NF(surface.cos_zenith)
    D = S₀ * cos_zenith

    diagnostics.surface_shortwave_down       = D
    diagnostics.ocean_surface_shortwave_down = D
    diagnostics.land_surface_shortwave_down  = D

    ocean_up = NF(surface.ocean_albedo) * D
    land_up  = NF(surface.land_albedo)  * D
    albedo   = (1 - NF(surface.land_fraction)) * NF(surface.ocean_albedo) +
               NF(surface.land_fraction) * NF(surface.land_albedo)

    diagnostics.ocean_surface_shortwave_up = ocean_up
    diagnostics.land_surface_shortwave_up  = land_up
    diagnostics.surface_shortwave_up       = albedo * D
    diagnostics.albedo                     = albedo
    diagnostics.outgoing_shortwave         = diagnostics.surface_shortwave_up

    diagnostics.cloud_cover        = zero(NF)
    diagnostics.stratocumulus_cover = zero(NF)
    diagnostics.cloud_top          = length(profile.temperature) + 1
    return nothing
end
