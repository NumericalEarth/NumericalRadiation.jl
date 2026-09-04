"""
$(TYPEDEF)

Precomputed shortwave optical properties for clear-sky solver tests and future
ecCKD gas-optics outputs.

`optical_depth` may be a vector of length `nlayers` or a matrix with shape
`(ng, nlayers)`. `weights` has length `ng` and is applied while accumulating
broadband fluxes.

Fields are

$(TYPEDFIELDS)
"""
struct ShortwaveOpticalProperties{FT, A, R, G, W}
    "Layer absorptive optical depth."
    optical_depth::A
    "Layer shortwave scattering optical depth. Historically this was Rayleigh-only."
    rayleigh_optical_depth::R
    "Layer shortwave scattering asymmetry factor."
    scattering_asymmetry::G
    "Spectral weights."
    weights::W
end

function ShortwaveOpticalProperties(optical_depth::AbstractVector{FT};
                                    rayleigh_optical_depth = zero.(optical_depth),
                                    scattering_optical_depth = rayleigh_optical_depth,
                                    scattering_asymmetry = zero.(optical_depth)) where FT
    length(scattering_optical_depth) == length(optical_depth) ||
        throw(DimensionMismatch("scattering_optical_depth must match optical_depth length"))
    length(scattering_asymmetry) == length(optical_depth) ||
        throw(DimensionMismatch("scattering_asymmetry must match optical_depth length"))
    weights = (one(FT),)
    return ShortwaveOpticalProperties{FT, typeof(optical_depth),
                                      typeof(scattering_optical_depth),
                                      typeof(scattering_asymmetry), typeof(weights)}(
        optical_depth, scattering_optical_depth, scattering_asymmetry, weights)
end

function ShortwaveOpticalProperties(optical_depth::AbstractMatrix{FT};
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
        throw(DimensionMismatch("weights must have length ng"))
    return ShortwaveOpticalProperties{FT, typeof(optical_depth),
                                      typeof(scattering_optical_depth),
                                      typeof(scattering_asymmetry), typeof(weights)}(
        optical_depth, scattering_optical_depth, scattering_asymmetry, weights)
end

Base.eltype(::ShortwaveOpticalProperties{FT}) where FT = FT

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

Fields are

$(TYPEDFIELDS)
"""
struct ShortwaveBoundaryConditions{FT, A, D}
    "Downwelling shortwave flux entering the top interface."
    toa_shortwave_down::FT
    "Lambertian surface albedo for diffuse radiation, either broadband scalar or per-g-point vector."
    surface_albedo::A
    "Lambertian surface albedo for direct radiation, either broadband scalar or per-g-point vector."
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

@inline _sw_ng(optics::ShortwaveOpticalProperties{<:Any, <:AbstractVector}) = 1
@inline _sw_nlayers(optics::ShortwaveOpticalProperties{<:Any, <:AbstractVector}) =
    length(optics.optical_depth)
@inline _sw_tau(optics::ShortwaveOpticalProperties{<:Any, <:AbstractVector}, ig, k) =
    optics.optical_depth[k]
@inline _sw_rayleigh_tau(optics::ShortwaveOpticalProperties{<:Any, <:AbstractVector}, ig, k) =
    optics.rayleigh_optical_depth[k]
@inline _sw_scattering_asymmetry(optics::ShortwaveOpticalProperties{<:Any, <:AbstractVector}, ig, k) =
    optics.scattering_asymmetry[k]

@inline _sw_ng(optics::ShortwaveOpticalProperties{<:Any, <:AbstractMatrix}) =
    size(optics.optical_depth, 1)
@inline _sw_nlayers(optics::ShortwaveOpticalProperties{<:Any, <:AbstractMatrix}) =
    size(optics.optical_depth, 2)
@inline _sw_tau(optics::ShortwaveOpticalProperties{<:Any, <:AbstractMatrix}, ig, k) =
    optics.optical_depth[ig, k]
@inline _sw_rayleigh_tau(optics::ShortwaveOpticalProperties{<:Any, <:AbstractMatrix}, ig, k) =
    optics.rayleigh_optical_depth[ig, k]
@inline _sw_scattering_asymmetry(optics::ShortwaveOpticalProperties{<:Any, <:AbstractMatrix}, ig, k) =
    optics.scattering_asymmetry[ig, k]

function _has_rayleigh_scattering(optics::ShortwaveOpticalProperties, ig)
    for k in 1:_sw_nlayers(optics)
        _sw_rayleigh_tau(optics, ig, k) > zero(eltype(optics)) && return true
    end
    return false
end

@inline _surface_albedo(boundary_conditions::ShortwaveBoundaryConditions{FT}, ig) where FT =
    boundary_conditions.surface_albedo isa AbstractArray ?
        FT(boundary_conditions.surface_albedo[ig]) :
        FT(boundary_conditions.surface_albedo)

@inline _surface_albedo_direct(boundary_conditions::ShortwaveBoundaryConditions{FT}, ig) where FT =
    boundary_conditions.surface_albedo_direct isa AbstractArray ?
        FT(boundary_conditions.surface_albedo_direct[ig]) :
        FT(boundary_conditions.surface_albedo_direct)

@inline function _sw_path_factor(::Type{FT}, atmosphere) where FT
    if atmosphere !== nothing && hasproperty(atmosphere, :geometry)
        geometry = getproperty(atmosphere, :geometry)
        if hasproperty(geometry, :cos_zenith)
            μ0 = max(FT(getproperty(geometry, :cos_zenith)), sqrt(eps(FT)))
            return inv(μ0)
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
@inline function _sw_delta_eddington(::Type{FT},
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
@inline function _sw_two_stream_layer(::Type{FT},
                                      μ0,
                                      optical_depth,
                                      single_scattering_albedo,
                                      asymmetry,
                                      direct_source_limit = Val(:unit)) where FT
    τ, ω, g = _sw_delta_eddington(FT, optical_depth, single_scattering_albedo, asymmetry)
    gamma1, gamma2, gamma3 = _sw_two_stream_gammas(FT, μ0, ω, g)
    return _sw_reflectance_transmittance(FT, μ0, τ, ω,
                                         gamma1, gamma2, gamma3,
                                         direct_source_limit)
end

@inline function _sw_two_stream_gammas(::Type{FT}, μ0, single_scattering_albedo, asymmetry) where FT
    factor = FT(0.75) * FT(asymmetry)
    gamma1 = FT(2) - FT(single_scattering_albedo) * (FT(1.25) + factor)
    gamma2 = FT(single_scattering_albedo) * (FT(0.75) - factor)
    gamma3 = FT(0.5) - FT(μ0) * factor
    return gamma1, gamma2, gamma3
end

@inline function _sw_reflectance_transmittance(::Type{FT},
                                               μ0,
                                               optical_depth,
                                               single_scattering_albedo,
                                               gamma1,
                                               gamma2,
                                               gamma3,
                                               direct_source_limit = Val(:unit)) where FT
    gamma4 = one(FT) - gamma3
    alpha1 = gamma1 * gamma4 + gamma2 * gamma3
    alpha2 = gamma1 * gamma3 + gamma2 * gamma4
    k_exponent = sqrt(max((gamma1 - gamma2) * (gamma1 + gamma2), FT(1.0e-12)))
    μ0_local = FT(μ0)
    if abs(one(FT) - k_exponent * μ0_local) < FT(1000) * eps(FT)
        μ0_local *= one(FT) - FT(10) * eps(FT)
    end

    od = max(FT(optical_depth), zero(FT))
    od_over_μ0 = max(od / μ0_local, zero(FT))
    direct = exp(-od_over_μ0)
    exponential = exp(-k_exponent * od)
    exponential2 = exponential * exponential
    k_2_exponential = FT(2) * k_exponent * exponential
    reftrans_factor = inv(k_exponent + gamma1 + (k_exponent - gamma1) * exponential2)

    reflectance = gamma2 * (one(FT) - exponential2) * reftrans_factor
    transmittance = k_2_exponential * reftrans_factor

    k_μ0 = k_exponent * μ0_local
    k_gamma3 = k_exponent * gamma3
    k_gamma4 = k_exponent * gamma4
    direct_factor = μ0_local * FT(single_scattering_albedo) * reftrans_factor /
        (one(FT) - k_μ0 * k_μ0)

    ref_dir = direct_factor *
        ((one(FT) - k_μ0) * (alpha2 + k_gamma3) -
         (one(FT) + k_μ0) * (alpha2 - k_gamma3) * exponential2 -
         k_2_exponential * (gamma3 - alpha2 * μ0_local) * direct)
    trans_dir_diff = direct_factor *
        (k_2_exponential * (gamma4 + alpha1 * μ0_local) -
         direct * ((one(FT) + k_μ0) * (alpha1 + k_gamma4) -
                   (one(FT) - k_μ0) * (alpha1 - k_gamma4) * exponential2))

    direct_scattering_limit = direct_source_limit isa Val{:horizontal} ?
        μ0_local * (one(FT) - direct) : one(FT)
    ref_dir = clamp(ref_dir, zero(FT), direct_scattering_limit)
    trans_dir_diff =
        clamp(trans_dir_diff, zero(FT), direct_scattering_limit - ref_dir)
    return reflectance, transmittance, ref_dir, trans_dir_diff, direct
end

function _ecrad_shortwave_column!(up::AbstractVector{FT},
                                  down::AbstractVector{FT},
                                  optics::ShortwaveOpticalProperties,
                                  ig,
                                  μ0,
                                  incoming_horizontal,
                                  surface_albedo,
                                  surface_albedo_direct = surface_albedo) where FT
    nlayers = _sw_nlayers(optics)
    incoming_normal = incoming_horizontal / μ0

    reflectance = Vector{FT}(undef, nlayers)
    transmittance = Vector{FT}(undef, nlayers)
    ref_dir = Vector{FT}(undef, nlayers)
    trans_dir_diff = Vector{FT}(undef, nlayers)
    trans_dir_dir = Vector{FT}(undef, nlayers)

    for k in 1:nlayers
        absorption_tau = max(FT(_sw_tau(optics, ig, k)), zero(FT))
        rayleigh_tau = max(FT(_sw_rayleigh_tau(optics, ig, k)), zero(FT))
        total_tau = absorption_tau + rayleigh_tau
        ssa = total_tau == zero(FT) ? zero(FT) : rayleigh_tau / total_tau
        asymmetry = clamp(FT(_sw_scattering_asymmetry(optics, ig, k)), -one(FT), one(FT))
        reflectance[k], transmittance[k], ref_dir[k], trans_dir_diff[k],
            trans_dir_dir[k] = _sw_two_stream_layer(FT, μ0, total_tau, ssa, asymmetry)
    end

    flux_direct = Vector{FT}(undef, nlayers + 1)
    flux_diffuse = Vector{FT}(undef, nlayers + 1)
    source = Vector{FT}(undef, nlayers + 1)
    stack_albedo = Vector{FT}(undef, nlayers + 1)
    inv_denominator = Vector{FT}(undef, nlayers)

    flux_direct[1] = incoming_normal
    for k in 1:nlayers
        flux_direct[k + 1] = flux_direct[k] * trans_dir_dir[k]
    end

    stack_albedo[nlayers + 1] = surface_albedo
    source[nlayers + 1] = surface_albedo_direct * flux_direct[nlayers + 1] * μ0

    for k in nlayers:-1:1
        below = stack_albedo[k + 1]
        inv_denominator[k] = inv(one(FT) - below * reflectance[k])
        stack_albedo[k] = reflectance[k] +
            transmittance[k] * transmittance[k] * below * inv_denominator[k]
        source[k] = ref_dir[k] * flux_direct[k] +
            transmittance[k] *
            (source[k + 1] + below * trans_dir_diff[k] * flux_direct[k]) *
            inv_denominator[k]
    end

    flux_diffuse[1] = zero(FT)
    up[1] += source[1]
    down[1] += flux_direct[1] * μ0
    for k in 1:nlayers
        flux_diffuse[k + 1] =
            (transmittance[k] * flux_diffuse[k] +
             reflectance[k] * source[k + 1] +
             trans_dir_diff[k] * flux_direct[k]) * inv_denominator[k]
        up[k + 1] += stack_albedo[k + 1] * flux_diffuse[k + 1] + source[k + 1]
        down[k + 1] += flux_diffuse[k + 1] + flux_direct[k + 1] * μ0
    end

    return nothing
end

"""
    radiative_fluxes!(fluxes, CloudlessShortwave(), optics, atmosphere, boundary_conditions)

Compute clear-sky shortwave interface fluxes from precomputed optical depth.
Arrays in `fluxes.shortwave_up` and `fluxes.shortwave_down` are overwritten.
When `atmosphere.geometry.cos_zenith` is present, optical depths are scaled by
the direct-beam path length `1 / cos_zenith`; otherwise the solver preserves the
historical vertical-path convention.
"""
function radiative_fluxes!(fluxes::RadiativeFluxes,
                           ::CloudlessShortwave,
                           optics::ShortwaveOpticalProperties{FT},
                           atmosphere,
                           boundary_conditions::ShortwaveBoundaryConditions{FT}) where FT
    nlayers = _sw_nlayers(optics)
    length(fluxes.shortwave_up) == nlayers + 1 ||
        throw(DimensionMismatch("shortwave_up must have length nlayers + 1"))
    length(fluxes.shortwave_down) == nlayers + 1 ||
        throw(DimensionMismatch("shortwave_down must have length nlayers + 1"))
    if boundary_conditions.surface_albedo isa AbstractArray
        length(boundary_conditions.surface_albedo) == _sw_ng(optics) ||
            throw(DimensionMismatch("surface_albedo vector must have length ng"))
    end
    if boundary_conditions.surface_albedo_direct isa AbstractArray
        length(boundary_conditions.surface_albedo_direct) == _sw_ng(optics) ||
            throw(DimensionMismatch("surface_albedo_direct vector must have length ng"))
    end

    fluxes.shortwave_up .= zero(FT)
    fluxes.shortwave_down .= zero(FT)

    for ig in 1:_sw_ng(optics)
        w = FT(optics.weights[ig])
        path_factor = _sw_path_factor(FT, atmosphere)
        μ0 = inv(path_factor)
        surface_albedo = _surface_albedo(boundary_conditions, ig)
        surface_albedo_direct = _surface_albedo_direct(boundary_conditions, ig)

        if _has_rayleigh_scattering(optics, ig)
            scratch_up = zeros(FT, nlayers + 1)
            scratch_down = zeros(FT, nlayers + 1)
            _ecrad_shortwave_column!(
                scratch_up,
                scratch_down,
                optics,
                ig,
                μ0,
                boundary_conditions.toa_shortwave_down,
                surface_albedo,
                surface_albedo_direct,
            )
            fluxes.shortwave_up .+= w .* scratch_up
            fluxes.shortwave_down .+= w .* scratch_down
            continue
        end

        down = boundary_conditions.toa_shortwave_down
        fluxes.shortwave_down[1] += w * down
        for k in 1:nlayers
            tr = exp(-_sw_tau(optics, ig, k) * path_factor)
            down *= tr
            fluxes.shortwave_down[k + 1] += w * down
        end

        up = surface_albedo_direct * down
        fluxes.shortwave_up[nlayers + 1] += w * up
        for k in nlayers:-1:1
            tr = exp(-_sw_tau(optics, ig, k) * path_factor)
            up *= tr
            fluxes.shortwave_up[k] += w * up
        end
    end

    return fluxes
end
