"""
$(TYPEDEF)

Constant atmospheric transmissivity, distributed across layers proportional
to their pressure thickness.

Fields:
- `transmissivity`: Column-integrated atmospheric transmissivity (0 .. 1) (default
  `NF(0.85)`)
"""
Base.@kwdef struct ConstantShortwaveTransmissivity{NF} <: AbstractShortwaveTransmissivity
    transmissivity::NF = NF(0.85)
end

Adapt.@adapt_structure ConstantShortwaveTransmissivity

ConstantShortwaveTransmissivity(::Type{NF}; kwargs...) where NF = ConstantShortwaveTransmissivity{NF}(; kwargs...)

"""$(TYPEDSIGNATURES)
Layer transmissivities under the constant-transmissivity model. Writes into
`t` (length `Nz`) and returns it.
"""
@inline function compute_transmissivity!(t::AbstractVector,
                                         transmissivity::ConstantShortwaveTransmissivity,
                                         clouds, profile::AtmosphereProfile,
                                         geometry::ColumnGrid,
                                         surface::SurfaceState)
    NF = eltype(t)
    Nz = length(t)
    τ = -log(NF(transmissivity.transmissivity))
    dσ = geometry.σ_thick
    for k in 1:Nz
        t[k] = exp(-τ * dσ[k])
    end
    return t
end

"""
$(TYPEDEF)

SPEEDY-style background shortwave transmissivity (Kucharski, Molteni &
Bracco, 2006; cf. Fortran SPEEDY `absdry`, `absaer`, `abswv1`/`abswv2`,
`abscl1`/`abscl2`, `azen`, `nzen`). The layer optical depth sums
contributions from dry air, aerosols (∝ σ_full²), water vapour (∝ q), and clouds
(active below the diagnosed cloud top); the column is weighted by a zenith
correction factor `1 + azen (1 − μ₀)^nzen`.

Fields:
- `zenith_amplitude`: Zenith correction amplitude (SPEEDY azen) (default `NF(1)`)
- `zenith_exponent`: Zenith correction exponent (SPEEDY nzen) (default `NF(2)`)
- `absorptivity_dry_air`: Absorptivity of dry air [per 10⁵ Pa] (default `NF(0.03135)`)
- `aerosols`: Include a constant aerosol concentration (default `true`)
- `absorptivity_aerosol`: Absorptivity of aerosols [per 10⁵ Pa] (default `NF(0.03135)`)
- `absorptivity_water_vapor`: Absorptivity of water vapour [per kg/kg per 10⁵ Pa] (default
  `NF(75)`)
- `absorptivity_cloud_base`: Base cloud absorptivity [per kg/kg per 10⁵ Pa] (default
  `NF(10)`)
- `absorptivity_cloud_limit`: Maximum cloud absorptivity [per 10⁵ Pa] (default `NF(0.14)`)
"""
Base.@kwdef struct BackgroundShortwaveTransmissivity{NF} <: AbstractShortwaveTransmissivity
    zenith_amplitude::NF = NF(1)
    zenith_exponent::NF = NF(2)
    absorptivity_dry_air::NF = NF(0.03135)
    aerosols::Bool = true
    absorptivity_aerosol::NF = NF(0.03135)
    absorptivity_water_vapor::NF = NF(75)
    absorptivity_cloud_base::NF = NF(10)
    absorptivity_cloud_limit::NF = NF(0.14)
end

Adapt.@adapt_structure BackgroundShortwaveTransmissivity

BackgroundShortwaveTransmissivity(::Type{NF}; kwargs...) where NF = BackgroundShortwaveTransmissivity{NF}(; kwargs...)

@inline function compute_transmissivity!(t::AbstractVector,
                                         transmissivity::BackgroundShortwaveTransmissivity,
                                         clouds, profile::AtmosphereProfile,
                                         geometry::ColumnGrid,
                                         surface::SurfaceState)
    NF = eltype(t)
    Nz = length(t)

    (; absorptivity_dry_air, absorptivity_aerosol, absorptivity_water_vapor,
       absorptivity_cloud_base, absorptivity_cloud_limit) = transmissivity
    cloud_top  = clouds.cloud_top
    cloud_cover = clouds.cloud_cover

    humidity   = profile.humidity
    σ_half     = geometry.σ_half
    σ_full     = geometry.σ_full
    p_normalized = profile.surface_pressure / NF(100000)
    μ₀ = surface.cos_zenith

    zenith_amplitude = transmissivity.zenith_amplitude
    zenith_exponent = transmissivity.zenith_exponent
    zenith_factor = 1 + zenith_amplitude * (1 - μ₀)^zenith_exponent

    q_base = Nz > 1 ? humidity[Nz - 1] : humidity[Nz]
    cloud_term = min(absorptivity_cloud_base * q_base, absorptivity_cloud_limit)

    for k in 1:Nz
        q_k = humidity[k]
        aerosol_factor = transmissivity.aerosols ? σ_full[k]^2 : zero(NF)
        layer_absorptivity = absorptivity_dry_air +
                    absorptivity_aerosol * aerosol_factor +
                    absorptivity_water_vapor * q_k
        if k >= cloud_top
            layer_absorptivity += cloud_term * cloud_cover
        end
        Δσ_k = σ_half[k + 1] - σ_half[k]
        optical_depth = layer_absorptivity * Δσ_k * p_normalized * zenith_factor
        t[k] = exp(-optical_depth)
    end

    return t
end
