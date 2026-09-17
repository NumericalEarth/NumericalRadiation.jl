"""
$(TYPEDEF)

SPEEDY-style one-band shortwave radiative transfer (Kucharski, Molteni &
Bracco, 2006, Appendix). Computes cloud albedo reflection at the diagnosed
cloud top, ozone absorption in the stratosphere, layer-by-layer transmission
with the configured [`AbstractShortwaveTransmissivity`](@ref), stratocumulus
reflection just above the surface, and surface-albedo reflection.

Fields:
- `ozone_absorption`: Total ozone absorption as a fraction of incoming TOA flux (default
  `NF(0.01)`)
- `ozone_distribution`: Ozone vertical distribution `ζ(σ) → weight`, normalised so
  ∫ ζ(σ) dσ = 1 (default `default_ozone_distribution(NF)`)
"""
Base.@kwdef struct OneBandShortwaveRadiativeTransfer{NF, F} <: AbstractShortwaveScheme
    ozone_absorption::NF = NF(0.01)
    ozone_distribution::F = default_ozone_distribution(NF)
end

Adapt.@adapt_structure OneBandShortwaveRadiativeTransfer

# SPEEDY default: ozone concentrated above σ = 0.2.
default_ozone_distribution(::Type{NF}) where NF = σ -> NF(50) * max(zero(NF), NF(1)/NF(5) - σ)

OneBandShortwaveRadiativeTransfer(::Type{NF}; kwargs...) where NF =
    OneBandShortwaveRadiativeTransfer{NF, typeof(default_ozone_distribution(NF))}(;
        ozone_distribution = default_ozone_distribution(NF), kwargs...)

"""
$(TYPEDEF)

Composite one-band shortwave scheme: a cloud diagnosis, a layer-transmissivity
model and a radiative-transfer solver are combined into a single scheme that
can be passed to [`solve_shortwave!`](@ref).

Fields:
- `clouds`: Cloud diagnosis, an [`AbstractShortwaveClouds`](@ref)
- `transmissivity`: Layer-transmissivity model, an [`AbstractShortwaveTransmissivity`](@ref)
- `radiative_transfer`: Radiative-transfer solver, an
  [`OneBandShortwaveRadiativeTransfer`](@ref)
"""
struct OneBandShortwave{C<:AbstractShortwaveClouds, T<:AbstractShortwaveTransmissivity,
                        R<:OneBandShortwaveRadiativeTransfer} <: AbstractShortwaveScheme
    clouds::C
    transmissivity::T
    radiative_transfer::R
end

Adapt.@adapt_structure OneBandShortwave

"""$(TYPEDSIGNATURES)
Convenience constructor with SPEEDY-like defaults for a moist simulation.
"""
OneBandShortwave(::Type{NF};
                 clouds = DiagnosticClouds(NF),
                 transmissivity = BackgroundShortwaveTransmissivity(NF),
                 radiative_transfer = OneBandShortwaveRadiativeTransfer(NF)) where NF =
    OneBandShortwave(clouds, transmissivity, radiative_transfer)

"""$(TYPEDSIGNATURES)
Convenience constructor with a dry-atmosphere default (no clouds, constant
column transmissivity).
"""
OneBandGreyShortwave(::Type{NF};
                     clouds = NoClouds(),
                     transmissivity = ConstantShortwaveTransmissivity(NF),
                     radiative_transfer = OneBandShortwaveRadiativeTransfer(NF)) where NF =
    OneBandShortwave(clouds, transmissivity, radiative_transfer)

"""$(TYPEDSIGNATURES)
Column shortwave radiative transfer for the one-band scheme.

`transmissivity_scratch` (length `Nz`) is overwritten with the layer
transmissivities; pre-allocate it outside of hot loops for GPU kernels.

`cloud_top_convective` is the cloud top set upstream by convection or
large-scale condensation; pass `length(profile.temperature) + 1` if none.

`rain_rate` for the diagnostic cloud scheme comes from `profile.rain_rate`.
"""
function solve_shortwave!(temperature_tendency::AbstractVector,
                          diagnostics::ShortwaveDiagnostics{NF},
                          scheme::OneBandShortwave,
                          profile::AtmosphereProfile,
                          geometry::ColumnGrid,
                          surface::SurfaceState,
                          constants,
                          thermodynamic;
                          transmissivity_scratch::AbstractVector = similar(profile.temperature),
                          cloud_top_convective::Integer = length(profile.temperature) + 1) where NF
    # `constants` and `thermodynamic` are duck-typed; see `solve_longwave!`.

    clouds = diagnose_clouds(scheme.clouds, profile, geometry, surface,
                             constants, thermodynamic, cloud_top_convective)

    t = transmissivity_scratch
    length(t) == length(profile.temperature) ||
        throw(DimensionMismatch("transmissivity_scratch must have length Nz"))
    compute_transmissivity!(t, scheme.transmissivity, clouds, profile, geometry, surface)

    radiative_transfer = scheme.radiative_transfer
    cos_zenith = NF(surface.cos_zenith)
    S₀ = NF(constants.solar_constant)
    cₚ = NF(constants.heat_capacity)

    Nz = length(profile.temperature)
    σ_full  = geometry.σ_full
    σ_thick = geometry.σ_thick

    D_toa = S₀ * cos_zenith
    D::NF = D_toa

    U_reflected::NF = zero(NF)
    cloud_top = clouds.cloud_top
    cloud_albedo = NF(clouds.cloud_albedo)
    cloud_cover  = NF(clouds.cloud_cover)

    # --- Downward sweep -----------------------------------------------------
    for k in 1:Nz
        if k == cloud_top
            R = cloud_albedo * cloud_cover
            U_reflected = D * R
            D *= (1 - R)
        end
        O₃ = NF(radiative_transfer.ozone_absorption) * radiative_transfer.ozone_distribution(σ_full[k]) * σ_thick[k]
        D_out = (D - O₃ * D_toa) * t[k]
        temperature_tendency[k] += flux_to_tendency((D - D_out) / cₚ, profile, geometry, constants, k)
        D = D_out
    end

    stratocumulus_cover  = NF(clouds.stratocumulus_cover)
    stratocumulus_albedo = NF(clouds.stratocumulus_albedo)
    U_stratocumulus = D * stratocumulus_albedo * stratocumulus_cover
    D_surface = D - U_stratocumulus

    albedo_ocean = NF(surface.ocean_albedo)
    albedo_land  = NF(surface.land_albedo)
    land_fraction = NF(surface.land_fraction)
    albedo = (1 - land_fraction) * albedo_ocean + land_fraction * albedo_land

    up_ocean = albedo_ocean * D_surface
    up_land  = albedo_land  * D_surface
    U_surface = albedo * D_surface

    # --- Upward sweep -------------------------------------------------------
    U::NF = U_surface + U_stratocumulus
    for k in Nz:-1:1
        U_out = U * t[k]
        temperature_tendency[k] += flux_to_tendency((U - U_out) / cₚ, profile, geometry, constants, k)
        if k == cloud_top
            U_out += U_reflected
        end
        U = U_out
    end

    diagnostics.surface_shortwave_down       = D_surface
    diagnostics.ocean_surface_shortwave_down = D_surface
    diagnostics.land_surface_shortwave_down  = D_surface
    diagnostics.ocean_surface_shortwave_up   = up_ocean
    diagnostics.land_surface_shortwave_up    = up_land
    diagnostics.surface_shortwave_up         = U_surface
    diagnostics.albedo                       = albedo
    diagnostics.outgoing_shortwave           = U
    diagnostics.cloud_cover                  = cloud_cover
    diagnostics.cloud_top                    = cloud_top
    diagnostics.stratocumulus_cover          = stratocumulus_cover

    return nothing
end
