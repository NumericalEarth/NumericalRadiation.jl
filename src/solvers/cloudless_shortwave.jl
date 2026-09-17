"""
$(TYPEDEF)

Precomputed shortwave optical properties for clear-sky solver tests and future
ecCKD gas-optics outputs.

`optical_depth` may be a vector of length `Nz` or a matrix with shape
`(Ngpoints, Nz)`. `weights` has length `Ngpoints` and is applied while accumulating
broadband fluxes.

Fields:
- `optical_depth`: Layer absorptive optical depth
- `rayleigh_optical_depth`: Layer shortwave scattering optical depth. Historically this was
  Rayleigh-only
- `scattering_asymmetry`: Layer shortwave scattering asymmetry factor
- `weights`: Spectral weights
"""
struct ShortwaveOptics{FT, A, R, G, W}
    optical_depth::A
    rayleigh_optical_depth::R
    scattering_asymmetry::G
    weights::W
end

function ShortwaveOptics(optical_depth::AbstractVector{FT};
                                    rayleigh_optical_depth = zero.(optical_depth),
                                    scattering_optical_depth = rayleigh_optical_depth,
                                    scattering_asymmetry = zero.(optical_depth)) where FT
    length(scattering_optical_depth) == length(optical_depth) ||
        throw(DimensionMismatch("scattering_optical_depth must match optical_depth length"))
    length(scattering_asymmetry) == length(optical_depth) ||
        throw(DimensionMismatch("scattering_asymmetry must match optical_depth length"))
    weights = (one(FT),)
    return ShortwaveOptics{FT, typeof(optical_depth),
                                      typeof(scattering_optical_depth),
                                      typeof(scattering_asymmetry), typeof(weights)}(
        optical_depth, scattering_optical_depth, scattering_asymmetry, weights)
end

function ShortwaveOptics(optical_depth::AbstractMatrix{FT};
                                    rayleigh_optical_depth = zero.(optical_depth),
                                    scattering_optical_depth = rayleigh_optical_depth,
                                    scattering_asymmetry = zero.(optical_depth),
                                    weights = fill(inv(FT(size(optical_depth, 1))),
                                                   size(optical_depth, 1))) where FT
    size(scattering_optical_depth) == size(optical_depth) ||
        throw(DimensionMismatch("scattering_optical_depth must match optical_depth shape"))
    size(scattering_asymmetry) == size(optical_depth) ||
        throw(DimensionMismatch("scattering_asymmetry must match optical_depth shape"))
    length(weights) == size(optical_depth, 1) ||
        throw(DimensionMismatch("weights must have length Ngpoints"))
    return ShortwaveOptics{FT, typeof(optical_depth),
                                      typeof(scattering_optical_depth),
                                      typeof(scattering_asymmetry), typeof(weights)}(
        optical_depth, scattering_optical_depth, scattering_asymmetry, weights)
end

Base.eltype(::ShortwaveOptics{FT}) where FT = FT

"""
$(TYPEDEF)

Cloudless shortwave solver for precomputed absorptive optical depths.

This is a deterministic clear-sky component solver. It transmits downwelling
TOA shortwave flux through the column, reflects a configurable fraction at the
surface, and transmits that reflected flux upward through the same optical
depths.
"""
struct CloudlessShortwave <: AbstractRadiativeTransferSolver end

"""
$(TYPEDEF)

Shortwave boundary conditions for [`CloudlessShortwave`](@ref).

Fields:
- `toa_shortwave_down`: Downwelling shortwave flux entering the top interface
- `surface_albedo`: Lambertian surface albedo for diffuse radiation, either broadband scalar
  or per-g-point vector
- `surface_albedo_direct`: Lambertian surface albedo for direct radiation, either broadband
  scalar or per-g-point vector
"""
struct ShortwaveBoundaryConditions{FT, A, D}
    toa_shortwave_down::FT
    surface_albedo::A
    surface_albedo_direct::D
end

function ShortwaveBoundaryConditions(; toa_shortwave_down,
                                     surface_albedo,
                                     surface_albedo_direct = surface_albedo)
    albedo_type = surface_albedo isa AbstractArray ? eltype(surface_albedo) :
        typeof(surface_albedo)
    direct_albedo_type = surface_albedo_direct isa AbstractArray ?
        eltype(surface_albedo_direct) : typeof(surface_albedo_direct)
    FT = promote_type(typeof(toa_shortwave_down), albedo_type, direct_albedo_type)
    albedo = surface_albedo isa AbstractArray ? FT.(surface_albedo) :
        FT(surface_albedo)
    direct_albedo = surface_albedo_direct isa AbstractArray ?
        FT.(surface_albedo_direct) : FT(surface_albedo_direct)
    return ShortwaveBoundaryConditions{FT, typeof(albedo), typeof(direct_albedo)}(
        FT(toa_shortwave_down), albedo, direct_albedo)
end

@inline number_of_gpoints(optics::ShortwaveOptics{<:Any, <:AbstractVector}) = 1
@inline number_of_layers(optics::ShortwaveOptics{<:Any, <:AbstractVector}) =
    length(optics.optical_depth)
@inline optical_depth_at(optics::ShortwaveOptics{<:Any, <:AbstractVector}, gpoint, k) =
    optics.optical_depth[k]
@inline rayleigh_optical_depth_at(optics::ShortwaveOptics{<:Any, <:AbstractVector}, gpoint, k) =
    optics.rayleigh_optical_depth[k]
@inline scattering_asymmetry_at(optics::ShortwaveOptics{<:Any, <:AbstractVector}, gpoint, k) =
    optics.scattering_asymmetry[k]

@inline number_of_gpoints(optics::ShortwaveOptics{<:Any, <:AbstractMatrix}) =
    size(optics.optical_depth, 1)
@inline number_of_layers(optics::ShortwaveOptics{<:Any, <:AbstractMatrix}) =
    size(optics.optical_depth, 2)
@inline optical_depth_at(optics::ShortwaveOptics{<:Any, <:AbstractMatrix}, gpoint, k) =
    optics.optical_depth[gpoint, k]
@inline rayleigh_optical_depth_at(optics::ShortwaveOptics{<:Any, <:AbstractMatrix}, gpoint, k) =
    optics.rayleigh_optical_depth[gpoint, k]
@inline scattering_asymmetry_at(optics::ShortwaveOptics{<:Any, <:AbstractMatrix}, gpoint, k) =
    optics.scattering_asymmetry[gpoint, k]

function has_rayleigh_scattering(optics::ShortwaveOptics, gpoint)
    for k in 1:number_of_layers(optics)
        rayleigh_optical_depth_at(optics, gpoint, k) > zero(eltype(optics)) && return true
    end
    return false
end

@inline surface_albedo_at(boundary_conditions::ShortwaveBoundaryConditions{FT}, gpoint) where FT =
    boundary_conditions.surface_albedo isa AbstractArray ?
        FT(boundary_conditions.surface_albedo[gpoint]) :
        FT(boundary_conditions.surface_albedo)

@inline surface_albedo_direct_at(boundary_conditions::ShortwaveBoundaryConditions{FT}, gpoint) where FT =
    boundary_conditions.surface_albedo_direct isa AbstractArray ?
        FT(boundary_conditions.surface_albedo_direct[gpoint]) :
        FT(boundary_conditions.surface_albedo_direct)

"""
$(TYPEDSIGNATURES)

Direct-beam slant-path factor `1 / μ₀` of a column, with `μ₀` read from
`atmosphere.geometry.cos_zenith` and clamped to `√eps(FT)` so that a sun on
or below the horizon gives a finite path; `1` (a vertical path) when the
atmosphere carries no solar geometry. [`streaming_shortwave_fluxes!`](@ref)
applies the same clamp to the `μ₀` it is handed directly.
"""
@inline function shortwave_path_factor(::Type{FT}, atmosphere) where FT
    if atmosphere !== nothing && hasproperty(atmosphere, :geometry)
        geometry = getproperty(atmosphere, :geometry)
        if hasproperty(geometry, :cos_zenith)
            μ₀ = max(FT(getproperty(geometry, :cos_zenith)), sqrt(eps(FT)))
            return inv(μ₀)
        end
    end
    return one(FT)
end

"""
$(TYPEDSIGNATURES)

Delta-Eddington scaling (Joseph, Wiscombe and Weinman 1976) of a layer's optical
depth, single-scattering albedo and asymmetry factor.

A fraction `f = g²` of the phase function is treated as an unscattered forward
peak and removed, and the remaining optics are rescaled so that the transported
energy is unchanged. Two-stream solutions only resolve weakly anisotropic phase
functions, so without this the strongly forward-scattering layers that clouds
produce (`g ≈ 0.85`) are not just inaccurate but non-conservative: the two-stream
layer solution then creates energy, by as much as 13% of the incident beam at
`g = 0.95`.

Backscattering layers have no forward peak to remove, so `g ≤ 0` — including the
`g = 0` Rayleigh case — passes through unscaled.
"""
@inline function shortwave_delta_eddington(::Type{FT},
                                     optical_depth,
                                     single_scattering_albedo,
                                     asymmetry) where FT
    τ = FT(optical_depth)
    ω = FT(single_scattering_albedo)
    g = FT(asymmetry)
    forward_peak = max(g, zero(FT))^2
    # A pure forward peak scatters nothing back into either stream, leaving a
    # purely absorbing layer. Taking it separately also keeps the ω = g = 1
    # corner, where the rescaling below is 0/0, finite.
    forward_peak >= one(FT) && return (one(FT) - ω) * τ, zero(FT), zero(FT)
    scale = one(FT) - ω * forward_peak
    return scale * τ,
           (one(FT) - forward_peak) * ω / scale,
           (g - forward_peak) / (one(FT) - forward_peak)
end

"""
$(TYPEDSIGNATURES)

Delta-Eddington-scale a layer and return its two-stream reflectance and
transmittance. This is the single entry point every shortwave two-stream path
uses, so the scaling cannot be skipped by one caller and applied by another.
"""
@inline function shortwave_two_stream_layer(::Type{FT},
                                      μ₀,
                                      optical_depth,
                                      single_scattering_albedo,
                                      asymmetry,
                                      direct_source_limit = Val(:unit)) where FT
    τ, ω, g = shortwave_delta_eddington(FT, optical_depth, single_scattering_albedo, asymmetry)
    γ₁, γ₂, γ₃ = shortwave_two_stream_coefficients(FT, μ₀, ω, g)
    return shortwave_reflectance_transmittance(FT, μ₀, τ, ω,
                                         γ₁, γ₂, γ₃,
                                         direct_source_limit)
end

@inline function shortwave_two_stream_coefficients(::Type{FT}, μ₀, single_scattering_albedo, asymmetry) where FT
    factor = FT(0.75) * FT(asymmetry)
    γ₁ = FT(2) - FT(single_scattering_albedo) * (FT(1.25) + factor)
    γ₂ = FT(single_scattering_albedo) * (FT(0.75) - factor)
    γ₃ = FT(0.5) - FT(μ₀) * factor
    return γ₁, γ₂, γ₃
end

@inline function shortwave_reflectance_transmittance(::Type{FT},
                                               μ₀,
                                               optical_depth,
                                               single_scattering_albedo,
                                               γ₁,
                                               γ₂,
                                               γ₃,
                                               direct_source_limit = Val(:unit)) where FT
    γ₄ = one(FT) - γ₃
    α₁ = γ₁ * γ₄ + γ₂ * γ₃
    α₂ = γ₁ * γ₃ + γ₂ * γ₄
    k_exponent = sqrt(max((γ₁ - γ₂) * (γ₁ + γ₂), FT(1.0e-12)))
    μ₀_local = FT(μ₀)
    if abs(one(FT) - k_exponent * μ₀_local) < FT(1000) * eps(FT)
        μ₀_local *= one(FT) - FT(10) * eps(FT)
    end

    τ = max(FT(optical_depth), zero(FT))
    τ_over_μ₀ = max(τ / μ₀_local, zero(FT))
    direct = exp(-τ_over_μ₀)
    exponential = exp(-k_exponent * τ)
    exponential2 = exponential * exponential
    two_k_exponential = FT(2) * k_exponent * exponential

    # In the conservative limit ω → 1 the two-stream coefficients satisfy
    # γ₁ → γ₂, so k → 0 (held at √1e-12 above) and every reflectance and
    # transmittance below is an O(k) result. Written as ecRad does, with
    # `1 - e^{-2kτ}` and `k + γ₁ + (k - γ₁) e^{-2kτ}`, each is the difference
    # of O(1) terms, and the relative rounding error `eps / (2kτ)` reaches 1e-10
    # in Float64 and a few percent in Float32, breaking energy conservation of
    # non-absorbing layers. The same expressions rearranged so that only the
    # accurately computable small differences
    #     m₁ = 1 - e^{-kτ},   m₂ = 1 - e^{-2kτ},   d = 1 - e^{-τ/μ₀}
    # (from `expm1`) and sums of like-signed terms appear are the same algebra:
    #     k + γ₁ + (k - γ₁) e²      = k (1 + e²) + γ₁ m₂,
    #     (1 - kμ₀)(α₂ + kγ₃) - (1 + kμ₀)(α₂ - kγ₃) e² - 2ke(γ₃ - α₂μ₀) D
    #                               = (α₂ - k²μ₀γ₃) m₂ + k(γ₃ - μ₀α₂)(m₁² + 2e d),
    #     2ke(γ₄ + α₁μ₀) - D[(1 + kμ₀)(α₁ + kγ₄) - (1 - kμ₀)(α₁ - kγ₄) e²]
    #                               = k(γ₄ + μ₀α₁)(d (1 + e²) - m₁²) - D(α₁ + k²μ₀γ₄) m₂,
    # with e = e^{-kτ} and D = e^{-τ/μ₀}, using 1 + e² - 2eD = m₁² + 2e d and
    # 2e - D(1 + e²) = d(1 + e²) - m₁².
    one_minus_exponential = -expm1(-k_exponent * τ)
    one_minus_exponential2 = -expm1(-FT(2) * k_exponent * τ)
    one_minus_direct = -expm1(-τ_over_μ₀)
    one_plus_exponential2 = one(FT) + exponential2
    inverse_denominator = inv(k_exponent * one_plus_exponential2 + γ₁ * one_minus_exponential2)

    reflectance = γ₂ * one_minus_exponential2 * inverse_denominator
    transmittance = two_k_exponential * inverse_denominator

    kμ₀ = k_exponent * μ₀_local
    direct_factor = μ₀_local * FT(single_scattering_albedo) * inverse_denominator /
        (one(FT) - kμ₀ * kμ₀)

    direct_reflectance = direct_factor *
        ((α₂ - kμ₀ * k_exponent * γ₃) * one_minus_exponential2 +
         k_exponent * (γ₃ - μ₀_local * α₂) *
         (one_minus_exponential * one_minus_exponential +
          FT(2) * exponential * one_minus_direct))
    direct_diffuse_transmittance = direct_factor *
        (k_exponent * (γ₄ + μ₀_local * α₁) *
         (one_minus_direct * one_plus_exponential2 -
          one_minus_exponential * one_minus_exponential) -
         direct * (α₁ + kμ₀ * k_exponent * γ₄) * one_minus_exponential2)

    direct_scattering_limit = direct_source_limit isa Val{:horizontal} ?
        μ₀_local * (one(FT) - direct) : one(FT)
    direct_reflectance = clamp(direct_reflectance, zero(FT), direct_scattering_limit)
    direct_diffuse_transmittance =
        clamp(direct_diffuse_transmittance, zero(FT), direct_scattering_limit - direct_reflectance)
    return reflectance, transmittance, direct_reflectance, direct_diffuse_transmittance, direct
end

"""
$(TYPEDEF)

Layer-optics functor over precomputed [`ShortwaveOptics`](@ref) arrays for
[`streaming_shortwave_fluxes!`](@ref): `(gpoint, k)` returns the tuple
`(τ_absorption, τ_scattering, asymmetry)` of layer `k`. With `gpoint::Int` the
functor ignores the g index it is called with and always reads that g point,
so a single g point can be streamed with `Ngpoints = 1`.
"""
struct PrecomputedShortwaveLayerOptics{O, G}
    optics::O
    gpoint::G
end

PrecomputedShortwaveLayerOptics(optics::ShortwaveOptics) =
    PrecomputedShortwaveLayerOptics(optics, nothing)

@inline (layer_optics::PrecomputedShortwaveLayerOptics{<:Any, Nothing})(gpoint, k) =
    precomputed_shortwave_layer(layer_optics.optics, gpoint, k)

@inline (layer_optics::PrecomputedShortwaveLayerOptics{<:Any, <:Integer})(gpoint, k) =
    precomputed_shortwave_layer(layer_optics.optics, layer_optics.gpoint, k)

@inline precomputed_shortwave_layer(optics::ShortwaveOptics, gpoint, k) =
    (optical_depth_at(optics, gpoint, k), rayleigh_optical_depth_at(optics, gpoint, k), scattering_asymmetry_at(optics, gpoint, k))

"""
$(TYPEDSIGNATURES)

Two-stream adding fluxes of g point `gpoint` of `optics` for cosine zenith `μ₀`,
written into `up` and `down` (length `Nz + 1`, top down, zeroed here).
`incoming_horizontal` is the downwelling flux through a horizontal surface at
the top of the atmosphere. A wrapper over
[`streaming_shortwave_fluxes!`](@ref) with `Ngpoints = 1` that allocates its own
[`ShortwaveColumnScratch`](@ref).
"""
function ecrad_shortwave_column!(up::AbstractVector{FT},
                                  down::AbstractVector{FT},
                                  optics::ShortwaveOptics,
                                  gpoint,
                                  μ₀,
                                  incoming_horizontal,
                                  surface_albedo,
                                  surface_albedo_direct = surface_albedo) where FT
    Nz = number_of_layers(optics)
    scratch = ShortwaveColumnScratch(FT, Nz)
    layer_optics = PrecomputedShortwaveLayerOptics(optics, gpoint)
    streaming_shortwave_fluxes!(up, down, layer_optics, μ₀, incoming_horizontal,
                                surface_albedo_direct, surface_albedo, (one(FT),), 1, Nz, scratch)
    return nothing
end

"""
    radiative_fluxes!(fluxes, CloudlessShortwave(), optics, atmosphere, boundary_conditions)

Compute clear-sky shortwave interface fluxes from precomputed optical depth.
Arrays in `fluxes.shortwave_up` and `fluxes.shortwave_down` are overwritten.
When `atmosphere.geometry.cos_zenith` is present, optical depths are scaled by
the direct-beam path length `1 / cos_zenith`; otherwise the solver preserves the
historical vertical-path convention.

Every g point with scattering runs the two-stream adding method of
[`streaming_shortwave_fluxes!`](@ref), so those g points match the streaming
path bit for bit. A g point with no scattering at all takes a closed-form
Beer–Lambert branch instead: the direct beam down the slant path, one
Lambertian reflection, and the reflected flux attenuated back up along the
same slant path, `e^{-τ / cos_zenith}`. The adding method treats the reflected
flux as diffuse and attenuates it with the two-stream diffusivity factor 2,
`e^{-2τ}`, so for such a g point the two paths agree on the downwelling flux
but differ in the reflected flux except at `cos_zenith = 1/2`, where the two
attenuations coincide.
"""
function radiative_fluxes!(fluxes::RadiativeFluxes,
                           ::CloudlessShortwave,
                           optics::ShortwaveOptics{FT},
                           atmosphere,
                           boundary_conditions::ShortwaveBoundaryConditions{FT}) where FT
    Nz = number_of_layers(optics)
    length(fluxes.shortwave_up) == Nz + 1 ||
        throw(DimensionMismatch("shortwave_up must have length Nz + 1"))
    length(fluxes.shortwave_down) == Nz + 1 ||
        throw(DimensionMismatch("shortwave_down must have length Nz + 1"))
    if boundary_conditions.surface_albedo isa AbstractArray
        length(boundary_conditions.surface_albedo) == number_of_gpoints(optics) ||
            throw(DimensionMismatch("surface_albedo vector must have length Ngpoints"))
    end
    if boundary_conditions.surface_albedo_direct isa AbstractArray
        length(boundary_conditions.surface_albedo_direct) == number_of_gpoints(optics) ||
            throw(DimensionMismatch("surface_albedo_direct vector must have length Ngpoints"))
    end

    fluxes.shortwave_up .= zero(FT)
    fluxes.shortwave_down .= zero(FT)

    # One scratch for every scattering g point; the adding method accumulates
    # its weighted fluxes in place.
    scratch = ShortwaveColumnScratch(FT, Nz)
    layer_optics = PrecomputedShortwaveLayerOptics(optics)

    for gpoint in 1:number_of_gpoints(optics)
        w = FT(optics.weights[gpoint])
        path_factor = shortwave_path_factor(FT, atmosphere)
        μ₀ = inv(path_factor)
        surface_albedo = surface_albedo_at(boundary_conditions, gpoint)
        surface_albedo_direct = surface_albedo_direct_at(boundary_conditions, gpoint)

        if has_rayleigh_scattering(optics, gpoint)
            add_shortwave_gpoint_fluxes!(fluxes.shortwave_up, fluxes.shortwave_down, layer_optics,
                                         gpoint, w, μ₀, boundary_conditions.toa_shortwave_down,
                                         surface_albedo_direct, surface_albedo, Nz, scratch)
            continue
        end

        # Without scattering the direct beam is the whole solution: Beer-Lambert
        # down the slant path, one Lambertian reflection, and Beer-Lambert back
        # up. Kept separate from the adding method so that this closed form is
        # reproduced exactly.
        down = boundary_conditions.toa_shortwave_down
        fluxes.shortwave_down[1] += w * down
        for k in 1:Nz
            layer_transmittance = exp(-optical_depth_at(optics, gpoint, k) * path_factor)
            down *= layer_transmittance
            fluxes.shortwave_down[k + 1] += w * down
        end

        up = surface_albedo_direct * down
        fluxes.shortwave_up[Nz + 1] += w * up
        for k in Nz:-1:1
            layer_transmittance = exp(-optical_depth_at(optics, gpoint, k) * path_factor)
            up *= layer_transmittance
            fluxes.shortwave_up[k] += w * up
        end
    end

    return fluxes
end
