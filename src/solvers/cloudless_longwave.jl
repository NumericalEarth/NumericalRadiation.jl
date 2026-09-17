"""
$(TYPEDEF)

Precomputed longwave optical properties for clear-sky solver tests and future
ecCKD gas-optics outputs.

`optical_depth` and `source` may be vectors of length `nlayers` or matrices
with shape `(Ngpoints, nlayers)`. `source` is the layer source function in flux units
for each spectral point. Optional `source_top` and `source_bottom` arrays with
the same shape enable ecRad-style no-scattering longwave emission from
half-level Planck functions. Optional `single_scattering_albedo` and
`scattering_asymmetry` arrays activate the ecRad-style longwave scattering
adding path. `weights` has length `Ngpoints` and is applied while accumulating
broadband fluxes.

Fields are

$(TYPEDFIELDS)
"""
struct LongwaveOptics{FT, A, ST, SB, SA, SG, W}
    "Layer optical depth."
    optical_depth::A
    "Layer source function in flux units."
    source::A
    "Top-interface source function for each layer, or `nothing`."
    source_top::ST
    "Bottom-interface source function for each layer, or `nothing`."
    source_bottom::SB
    "Layer single-scattering albedo, or `nothing` for no scattering."
    single_scattering_albedo::SA
    "Layer scattering asymmetry factor, or `nothing` for no scattering."
    scattering_asymmetry::SG
    "Spectral weights."
    weights::W
end

function LongwaveOptics(optical_depth::AbstractVector{FT},
                                   source::AbstractVector{FT};
                                   source_top = nothing,
                                   source_bottom = nothing,
                                   single_scattering_albedo = nothing,
                                   scattering_asymmetry = nothing) where FT
    length(optical_depth) == length(source) ||
        throw(DimensionMismatch("optical_depth and source must have the same length"))
    source_top === nothing || length(source_top) == length(source) ||
        throw(DimensionMismatch("source_top must match source length"))
    source_bottom === nothing || length(source_bottom) == length(source) ||
        throw(DimensionMismatch("source_bottom must match source length"))
    single_scattering_albedo === nothing || length(single_scattering_albedo) == length(source) ||
        throw(DimensionMismatch("single_scattering_albedo must match source length"))
    scattering_asymmetry === nothing || length(scattering_asymmetry) == length(source) ||
        throw(DimensionMismatch("scattering_asymmetry must match source length"))
    (single_scattering_albedo === nothing) == (scattering_asymmetry === nothing) ||
        throw(ArgumentError("single_scattering_albedo and scattering_asymmetry must both be provided or both be nothing"))
    weights = (one(FT),)
    return LongwaveOptics{FT, typeof(optical_depth),
                                     typeof(source_top), typeof(source_bottom),
                                     typeof(single_scattering_albedo),
                                     typeof(scattering_asymmetry),
                                     typeof(weights)}(
        optical_depth, source, source_top, source_bottom,
        single_scattering_albedo, scattering_asymmetry, weights)
end

function LongwaveOptics(optical_depth::AbstractMatrix{FT},
                                   source::AbstractMatrix{FT};
                                   source_top = nothing,
                                   source_bottom = nothing,
                                   single_scattering_albedo = nothing,
                                   scattering_asymmetry = nothing,
                                   weights = fill(inv(FT(size(optical_depth, 1))),
                                                  size(optical_depth, 1))) where FT
    size(optical_depth) == size(source) ||
        throw(DimensionMismatch("optical_depth and source must have the same shape"))
    source_top === nothing || size(source_top) == size(source) ||
        throw(DimensionMismatch("source_top must match source shape"))
    source_bottom === nothing || size(source_bottom) == size(source) ||
        throw(DimensionMismatch("source_bottom must match source shape"))
    single_scattering_albedo === nothing || size(single_scattering_albedo) == size(source) ||
        throw(DimensionMismatch("single_scattering_albedo must match source shape"))
    scattering_asymmetry === nothing || size(scattering_asymmetry) == size(source) ||
        throw(DimensionMismatch("scattering_asymmetry must match source shape"))
    (single_scattering_albedo === nothing) == (scattering_asymmetry === nothing) ||
        throw(ArgumentError("single_scattering_albedo and scattering_asymmetry must both be provided or both be nothing"))
    length(weights) == size(optical_depth, 1) ||
        throw(DimensionMismatch("weights must have length Ngpoints"))
    return LongwaveOptics{FT, typeof(optical_depth),
                                     typeof(source_top), typeof(source_bottom),
                                     typeof(single_scattering_albedo),
                                     typeof(scattering_asymmetry),
                                     typeof(weights)}(
        optical_depth, source, source_top, source_bottom,
        single_scattering_albedo, scattering_asymmetry, weights)
end

Base.eltype(::LongwaveOptics{FT}) where FT = FT

"""
$(TYPEDEF)

Cloudless longwave two-stream solver for precomputed optical properties.

This solver is intentionally small and explicit: it is the first component
solver behind the staged `radiative_fluxes!` API and provides a validation
target before ecCKD gas optics are implemented.
"""
struct CloudlessLongwave <: AbstractRadiativeTransferSolver end

"""
$(TYPEDEF)

Longwave boundary fluxes for [`CloudlessLongwave`](@ref).

For spectral (multi-g) optics such as the tabulated ecCKD models,
`surface_longwave_up` must be a length-`Ngpoints` vector in the same
per-unit-weight convention as the optics' Planck sources — build it with
[`surface_longwave_emission`](@ref). A scalar is interpreted as
spectrally-gray emission (every g point emits the same flux), a gray
approximation that does not reproduce a tabulated model's Planck spectrum
and may bias outgoing longwave fluxes.

Fields are

$(TYPEDFIELDS)
"""
struct LongwaveBoundaryConditions{FT, S, A}
    "Upwelling longwave flux entering the bottom interface."
    surface_longwave_up::S
    "Downwelling longwave flux entering the top interface."
    toa_longwave_down::FT
    "Diffuse longwave surface albedo."
    surface_albedo::A
end

function LongwaveBoundaryConditions(; surface_longwave_up,
                                    toa_longwave_down = nothing,
                                    surface_albedo = nothing)
    FT = surface_longwave_up isa Number ?
        typeof(surface_longwave_up) :
        eltype(surface_longwave_up)
    down = toa_longwave_down === nothing ? zero(FT) : FT(toa_longwave_down)
    albedo = surface_albedo === nothing ? zero(FT) : surface_albedo
    return LongwaveBoundaryConditions{FT, typeof(surface_longwave_up), typeof(albedo)}(
        surface_longwave_up, down, albedo)
end

@inline number_of_gpoints(optics::LongwaveOptics{<:Any, <:AbstractVector}) = 1
@inline number_of_layers(optics::LongwaveOptics{<:Any, <:AbstractVector}) =
    length(optics.optical_depth)
@inline optical_depth_at(optics::LongwaveOptics{<:Any, <:AbstractVector}, gpoint, k) =
    optics.optical_depth[k]
@inline source_at(optics::LongwaveOptics{<:Any, <:AbstractVector}, gpoint, k) =
    optics.source[k]

@inline number_of_gpoints(optics::LongwaveOptics{<:Any, <:AbstractMatrix}) =
    size(optics.optical_depth, 1)
@inline number_of_layers(optics::LongwaveOptics{<:Any, <:AbstractMatrix}) =
    size(optics.optical_depth, 2)
@inline optical_depth_at(optics::LongwaveOptics{<:Any, <:AbstractMatrix}, gpoint, k) =
    optics.optical_depth[gpoint, k]
@inline source_at(optics::LongwaveOptics{<:Any, <:AbstractMatrix}, gpoint, k) =
    optics.source[gpoint, k]

@inline has_interface_sources(optics::LongwaveOptics) =
    optics.source_top !== nothing && optics.source_bottom !== nothing
@inline source_top_at(optics::LongwaveOptics{<:Any, <:AbstractVector}, gpoint, k) =
    optics.source_top[k]
@inline source_bottom_at(optics::LongwaveOptics{<:Any, <:AbstractVector}, gpoint, k) =
    optics.source_bottom[k]
@inline source_top_at(optics::LongwaveOptics{<:Any, <:AbstractMatrix}, gpoint, k) =
    optics.source_top[gpoint, k]
@inline source_bottom_at(optics::LongwaveOptics{<:Any, <:AbstractMatrix}, gpoint, k) =
    optics.source_bottom[gpoint, k]

@inline has_longwave_scattering(optics::LongwaveOptics) =
    optics.single_scattering_albedo !== nothing &&
    optics.scattering_asymmetry !== nothing
@inline single_scattering_albedo_at(optics::LongwaveOptics{<:Any, <:AbstractVector}, gpoint, k) =
    optics.single_scattering_albedo[k]
@inline scattering_asymmetry_at(optics::LongwaveOptics{<:Any, <:AbstractVector}, gpoint, k) =
    optics.scattering_asymmetry[k]
@inline single_scattering_albedo_at(optics::LongwaveOptics{<:Any, <:AbstractMatrix}, gpoint, k) =
    optics.single_scattering_albedo[gpoint, k]
@inline scattering_asymmetry_at(optics::LongwaveOptics{<:Any, <:AbstractMatrix}, gpoint, k) =
    optics.scattering_asymmetry[gpoint, k]

@inline function no_scattering_longwave_sources(::Type{FT}, τ, source_top, source_bottom) where FT
    diffusivity = FT(1.66)
    Dτ = diffusivity * FT(τ)
    transmittance = exp(-Dτ)
    if τ > FT(1.0e-3)
        gradient = (FT(source_bottom) - FT(source_top)) / Dτ
        source_up = gradient + FT(source_top) -
            transmittance * (gradient + FT(source_bottom))
        source_down = -gradient + FT(source_bottom) -
            transmittance * (-gradient + FT(source_top))
        return transmittance, source_up, source_down
    end
    source = Dτ * FT(0.5) * (FT(source_top) + FT(source_bottom))
    return transmittance, source, source
end

@inline function longwave_reflectance_transmittance_sources(::Type{FT}, τ, ω, asymmetry,
                                       source_top, source_bottom) where FT
    diffusivity = FT(1.66)
    scattering = clamp(FT(ω), zero(FT), one(FT))
    g = clamp(FT(asymmetry), -one(FT), one(FT))
    factor = (diffusivity * FT(0.5)) * scattering
    γ₁ = diffusivity - factor * (one(FT) + g)
    γ₂ = factor * (one(FT) - g)
    k_exponent = sqrt(max((γ₁ - γ₂) * (γ₁ + γ₂), FT(1.0e-12)))
    τ = max(FT(τ), zero(FT))
    if τ > FT(1.0e-3)
        exponential = exp(-k_exponent * τ)
        exponential2 = exponential * exponential
        inverse_denominator =
            inv(k_exponent + γ₁ + (k_exponent - γ₁) * exponential2)
        reflectance = γ₂ * (one(FT) - exponential2) * inverse_denominator
        transmittance = FT(2) * k_exponent * exponential * inverse_denominator
        gradient = (FT(source_bottom) - FT(source_top)) / (τ * (γ₁ + γ₂))
        source_up_top = gradient + FT(source_top)
        source_up_bottom = gradient + FT(source_bottom)
        source_down_top = -gradient + FT(source_top)
        source_down_bottom = -gradient + FT(source_bottom)
        source_up =
            source_up_top - reflectance * source_down_top - transmittance * source_up_bottom
        source_down =
            source_down_bottom - reflectance * source_up_bottom - transmittance * source_down_top
        return reflectance, transmittance, source_up, source_down
    end
    reflectance = γ₂ * τ
    transmittance = (one(FT) - k_exponent * τ) /
        (one(FT) + τ * (γ₁ - k_exponent))
    source = (one(FT) - reflectance - transmittance) *
        FT(0.5) * (FT(source_top) + FT(source_bottom))
    return reflectance, transmittance, source, source
end

@inline function longwave_fallback_planck_sources(::Type{FT}, optics, gpoint, k) where FT
    if has_interface_sources(optics)
        return source_top_at(optics, gpoint, k), source_bottom_at(optics, gpoint, k)
    end
    source = source_at(optics, gpoint, k)
    return source, source
end

@inline surface_longwave_up_at(boundary_conditions::LongwaveBoundaryConditions{FT}, gpoint) where FT =
    boundary_conditions.surface_longwave_up isa Number ?
    boundary_conditions.surface_longwave_up :
    FT(boundary_conditions.surface_longwave_up[gpoint])
@inline surface_longwave_albedo(boundary_conditions::LongwaveBoundaryConditions{FT}, gpoint) where FT =
    boundary_conditions.surface_albedo isa Number ?
    boundary_conditions.surface_albedo :
    FT(boundary_conditions.surface_albedo[gpoint])

# Adapters that present one g point of precomputed array optics and boundary
# conditions in the functor form of `streaming_longwave_fluxes!`: the streamed
# g-point index is always 1, so both ignore it and read the g point they were
# built for.
struct ArrayLayerOptics{O}
    optics :: O
    gpoint :: Int
end

@inline (layer::ArrayLayerOptics)(_, k) =
    (optical_depth_at(layer.optics, layer.gpoint, k),
     source_top_at(layer.optics, layer.gpoint, k),
     source_bottom_at(layer.optics, layer.gpoint, k))

struct BoundarySurfaceEmission{B}
    boundary_conditions :: B
    gpoint :: Int
end

@inline Base.getindex(emission::BoundarySurfaceEmission, _) =
    surface_longwave_up_at(emission.boundary_conditions, emission.gpoint)

"""
    radiative_fluxes!(fluxes, CloudlessLongwave(), optics, atmosphere, boundary_conditions)

Compute clear-sky longwave interface fluxes from precomputed optical depth and
source terms. Arrays in `fluxes` are overwritten. The atmosphere argument is
accepted for interface consistency and is not inspected by this solver.
"""
function radiative_fluxes!(fluxes::RadiativeFluxes,
                           ::CloudlessLongwave,
                           optics::LongwaveOptics{FT},
                           atmosphere,
                           boundary_conditions::LongwaveBoundaryConditions{FT}) where FT
    nlayers = number_of_layers(optics)
    length(fluxes.longwave_up) == nlayers + 1 ||
        throw(DimensionMismatch("longwave_up must have length nlayers + 1"))
    length(fluxes.longwave_down) == nlayers + 1 ||
        throw(DimensionMismatch("longwave_down must have length nlayers + 1"))

    fluxes.longwave_up .= zero(FT)
    fluxes.longwave_down .= zero(FT)

    if has_longwave_scattering(optics)
        has_interface_sources(optics) ||
            throw(ArgumentError("longwave scattering requires source_top and source_bottom interface Planck sources"))
        reflectance = zeros(FT, nlayers)
        transmittance = zeros(FT, nlayers)
        source_up = zeros(FT, nlayers)
        source_down = zeros(FT, nlayers)
        albedo = zeros(FT, nlayers + 1)
        source = zeros(FT, nlayers + 1)
        inv_denominator = zeros(FT, nlayers)

        for gpoint in 1:number_of_gpoints(optics)
            w = FT(optics.weights[gpoint])
            for k in 1:nlayers
                top, bottom = longwave_fallback_planck_sources(FT, optics, gpoint, k)
                reflectance[k], transmittance[k], source_up[k], source_down[k] =
                    longwave_reflectance_transmittance_sources(
                        FT, optical_depth_at(optics, gpoint, k), single_scattering_albedo_at(optics, gpoint, k),
                        scattering_asymmetry_at(optics, gpoint, k), top, bottom)
            end

            albedo[nlayers + 1] =
                clamp(surface_longwave_albedo(boundary_conditions, gpoint), zero(FT), one(FT))
            source[nlayers + 1] = surface_longwave_up_at(boundary_conditions, gpoint)
            for k in nlayers:-1:1
                inv_denominator[k] =
                    inv(one(FT) - albedo[k + 1] * reflectance[k])
                albedo[k] = reflectance[k] +
                    transmittance[k]^2 * albedo[k + 1] * inv_denominator[k]
                source[k] = source_up[k] +
                    transmittance[k] *
                    (source[k + 1] + albedo[k + 1] * source_down[k]) *
                    inv_denominator[k]
            end

            down = boundary_conditions.toa_longwave_down
            fluxes.longwave_down[1] += w * down
            fluxes.longwave_up[1] += w * (source[1] + albedo[1] * down)
            for k in 1:nlayers
                down = (transmittance[k] * down +
                        reflectance[k] * source[k + 1] +
                        source_down[k]) * inv_denominator[k]
                up = albedo[k + 1] * down + source[k + 1]
                fluxes.longwave_down[k + 1] += w * down
                fluxes.longwave_up[k + 1] += w * up
            end
        end

        return fluxes
    end

    # No scattering: sweep down from the top of the atmosphere, then up from
    # the surface, where the upwelling flux is the surface emission plus the
    # reflected downwelling flux, `up = ε B(Tₛ) + α down`. The interface-source
    # (ecRad half-level Planck) layers run through `streaming_longwave_fluxes!`
    # one g point at a time, so a host kernel streaming that function directly
    # reproduces this solver bit for bit.
    if has_interface_sources(optics)
        gpoint_up = zeros(FT, nlayers + 1)
        gpoint_down = zeros(FT, nlayers + 1)
        transmittance = zeros(FT, nlayers)
        source_up = zeros(FT, nlayers)
        for gpoint in 1:number_of_gpoints(optics)
            w = FT(optics.weights[gpoint])
            streaming_longwave_fluxes!(gpoint_up, gpoint_down,
                                       ArrayLayerOptics(optics, gpoint),
                                       BoundarySurfaceEmission(boundary_conditions, gpoint),
                                       surface_longwave_albedo(boundary_conditions, gpoint),
                                       boundary_conditions.toa_longwave_down,
                                       (w,), 1, nlayers, transmittance, source_up)
            fluxes.longwave_up .+= gpoint_up
            fluxes.longwave_down .+= gpoint_down
        end

        return fluxes
    end

    for gpoint in 1:number_of_gpoints(optics)
        w = FT(optics.weights[gpoint])

        down = boundary_conditions.toa_longwave_down
        fluxes.longwave_down[1] += w * down
        for k in 1:nlayers
            layer_transmittance = exp(-optical_depth_at(optics, gpoint, k))
            layer_source = source_at(optics, gpoint, k)
            down = down * layer_transmittance + layer_source * (one(FT) - layer_transmittance)
            fluxes.longwave_down[k + 1] += w * down
        end

        up = surface_longwave_up_at(boundary_conditions, gpoint) +
             surface_longwave_albedo(boundary_conditions, gpoint) * down
        fluxes.longwave_up[nlayers + 1] += w * up
        for k in nlayers:-1:1
            layer_transmittance = exp(-optical_depth_at(optics, gpoint, k))
            layer_source = source_at(optics, gpoint, k)
            up = up * layer_transmittance + layer_source * (one(FT) - layer_transmittance)
            fluxes.longwave_up[k] += w * up
        end
    end

    return fluxes
end
