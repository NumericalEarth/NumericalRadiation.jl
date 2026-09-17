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
- `ozone_distribution`: Ozone vertical distribution `ζ(σ_level) → weight` over the
  sigma coordinate, normalised so ∫ ζ dσ_level = 1 (default `default_ozone_distribution(NF)`)
"""
Base.@kwdef struct OneBandShortwaveRadiativeTransfer{NF, F} <: AbstractShortwaveScheme
    ozone_absorption::NF = NF(0.01)
    ozone_distribution::F = default_ozone_distribution(NF)
end

Adapt.@adapt_structure OneBandShortwaveRadiativeTransfer

# SPEEDY default: ozone concentrated above the sigma level 0.2.
default_ozone_distribution(::Type{NF}) where NF = σ_level -> NF(50) * max(zero(NF), NF(1)/NF(5) - σ_level)

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

    clouds = diagnose_clouds(scheme.clouds, profile, geometry, surface, constants, thermodynamic, cloud_top_convective)

    # Layer transmissivities 𝒯[k] of the configured transmissivity model.
    𝒯 = transmissivity_scratch
    length(𝒯) == length(profile.temperature) || throw(DimensionMismatch("transmissivity_scratch must have length Nz"))
    compute_transmissivity!(𝒯, scheme.transmissivity, clouds, profile, geometry, surface)

    radiative_transfer = scheme.radiative_transfer
    μ₀ = NF(surface.cos_zenith)
    S₀ = NF(constants.solar_constant)
    cᵖ = NF(constants.heat_capacity)

    Nz = length(profile.temperature)
    σ_full  = geometry.σ_full
    σ_thick = geometry.σ_thick

    # Downwelling flux ℐꜜ entering the top of the atmosphere, S₀ μ₀.
    ℐꜜ_toa = S₀ * μ₀
    ℐꜜ::NF = ℐꜜ_toa

    ℐꜛ_reflected::NF = zero(NF)
    cloud_top = clouds.cloud_top
    α_cloud = NF(clouds.cloud_albedo)
    cloud_cover = NF(clouds.cloud_cover)

    # --- Downward sweep -----------------------------------------------------
    for k in 1:Nz
        if k == cloud_top
            ℛ_cloud = α_cloud * cloud_cover
            ℐꜛ_reflected = ℐꜜ * ℛ_cloud
            ℐꜜ *= (1 - ℛ_cloud)
        end
        # Fraction of the TOA flux absorbed by ozone in layer k.
        ozone_absorption_k = NF(radiative_transfer.ozone_absorption) * radiative_transfer.ozone_distribution(σ_full[k]) * σ_thick[k]
        ℐꜜ_out = (ℐꜜ - ozone_absorption_k * ℐꜜ_toa) * 𝒯[k]
        temperature_tendency[k] += flux_to_tendency((ℐꜜ - ℐꜜ_out) / cᵖ, profile, geometry, constants, k)
        ℐꜜ = ℐꜜ_out
    end

    stratocumulus_cover = NF(clouds.stratocumulus_cover)
    α_stratocumulus = NF(clouds.stratocumulus_albedo)
    ℐꜛ_stratocumulus = ℐꜜ * α_stratocumulus * stratocumulus_cover
    ℐꜜ_surface = ℐꜜ - ℐꜛ_stratocumulus

    α_ocean = NF(surface.ocean_albedo)
    α_land  = NF(surface.land_albedo)
    land_fraction = NF(surface.land_fraction)
    α = (1 - land_fraction) * α_ocean + land_fraction * α_land

    ℐꜛ_ocean = α_ocean * ℐꜜ_surface
    ℐꜛ_land  = α_land  * ℐꜜ_surface
    ℐꜛ_surface = α * ℐꜜ_surface

    # --- Upward sweep -------------------------------------------------------
    ℐꜛ::NF = ℐꜛ_surface + ℐꜛ_stratocumulus
    for k in Nz:-1:1
        ℐꜛ_out = ℐꜛ * 𝒯[k]
        temperature_tendency[k] += flux_to_tendency((ℐꜛ - ℐꜛ_out) / cᵖ, profile, geometry, constants, k)
        if k == cloud_top
            ℐꜛ_out += ℐꜛ_reflected
        end
        ℐꜛ = ℐꜛ_out
    end

    diagnostics.surface_shortwave_down       = ℐꜜ_surface
    diagnostics.ocean_surface_shortwave_down = ℐꜜ_surface
    diagnostics.land_surface_shortwave_down  = ℐꜜ_surface
    diagnostics.ocean_surface_shortwave_up   = ℐꜛ_ocean
    diagnostics.land_surface_shortwave_up    = ℐꜛ_land
    diagnostics.surface_shortwave_up         = ℐꜛ_surface
    diagnostics.albedo                       = α
    diagnostics.outgoing_shortwave           = ℐꜛ
    diagnostics.cloud_cover                  = cloud_cover
    diagnostics.cloud_top                    = cloud_top
    diagnostics.stratocumulus_cover          = stratocumulus_cover

    return nothing
end
