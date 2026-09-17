"""
$(TYPEDEF)

Precomputed longwave optical properties for clear-sky solver tests and future
ecCKD gas-optics outputs.

`optical_depth` and `source` may be vectors of length `Nz` or matrices
with shape `(Ng, Nz)`. `source` is the layer source function in flux units
for each spectral point. Optional `source_top` and `source_bottom` arrays with
the same shape enable ecRad-style no-scattering longwave emission from
half-level Planck functions. Optional `single_scattering_albedo` and
`scattering_asymmetry` arrays activate the ecRad-style longwave scattering
adding path. `weights` has length `Ng` and is applied while accumulating
broadband fluxes.

Fields:
- `optical_depth`: Layer optical depth
- `source`: Layer source function in flux units
- `source_top`: Top-interface source function for each layer, or `nothing`
- `source_bottom`: Bottom-interface source function for each layer, or `nothing`
- `single_scattering_albedo`: Layer single-scattering albedo, or `nothing` for no scattering
- `scattering_asymmetry`: Layer scattering asymmetry factor, or `nothing` for no scattering
- `weights`: Spectral weights
"""
struct LongwaveOptics{FT, A, ST, SB, SA, SG, W}
    optical_depth::A
    source::A
    source_top::ST
    source_bottom::SB
    single_scattering_albedo::SA
    scattering_asymmetry::SG
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
    size(optical_depth) == size(source) || throw(DimensionMismatch("optical_depth and source must have the same shape"))
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
    length(weights) == size(optical_depth, 1) || throw(DimensionMismatch("weights must have length Ng"))
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
`surface_longwave_up` must be a length-`Ng` vector in the same
per-unit-weight convention as the optics' Planck sources — build it with
[`surface_longwave_emission`](@ref). A scalar is interpreted as
spectrally-gray emission (every g point emits the same flux), a gray
approximation that does not reproduce a tabulated model's Planck spectrum
and may bias outgoing longwave fluxes.

Fields:
- `surface_longwave_up`: Upwelling longwave flux entering the bottom interface
- `toa_longwave_down`: Downwelling longwave flux entering the top interface
- `surface_albedo`: Diffuse longwave surface albedo
"""
struct LongwaveBoundaryConditions{FT, S, A}
    surface_longwave_up::S
    toa_longwave_down::FT
    surface_albedo::A
end

function LongwaveBoundaryConditions(; surface_longwave_up, toa_longwave_down=nothing, surface_albedo=nothing)
    FT = surface_longwave_up isa Number ? typeof(surface_longwave_up) : eltype(surface_longwave_up)
    down = toa_longwave_down === nothing ? zero(FT) : FT(toa_longwave_down)
    albedo = surface_albedo === nothing ? zero(FT) : surface_albedo
    return LongwaveBoundaryConditions{FT, typeof(surface_longwave_up), typeof(albedo)}(
        surface_longwave_up, down, albedo)
end

@inline number_of_gpoints(optics::LongwaveOptics{<:Any, <:AbstractVector}) = 1
@inline number_of_layers(optics::LongwaveOptics{<:Any, <:AbstractVector}) = length(optics.optical_depth)
@inline optical_depth_at(optics::LongwaveOptics{<:Any, <:AbstractVector}, g, k) = optics.optical_depth[k]
@inline source_at(optics::LongwaveOptics{<:Any, <:AbstractVector}, g, k) = optics.source[k]

@inline number_of_gpoints(optics::LongwaveOptics{<:Any, <:AbstractMatrix}) = size(optics.optical_depth, 1)
@inline number_of_layers(optics::LongwaveOptics{<:Any, <:AbstractMatrix}) = size(optics.optical_depth, 2)
@inline optical_depth_at(optics::LongwaveOptics{<:Any, <:AbstractMatrix}, g, k) = optics.optical_depth[g, k]
@inline source_at(optics::LongwaveOptics{<:Any, <:AbstractMatrix}, g, k) = optics.source[g, k]

@inline has_interface_sources(optics::LongwaveOptics) = optics.source_top !== nothing && optics.source_bottom !== nothing
@inline source_top_at(optics::LongwaveOptics{<:Any, <:AbstractVector}, g, k) = optics.source_top[k]
@inline source_bottom_at(optics::LongwaveOptics{<:Any, <:AbstractVector}, g, k) = optics.source_bottom[k]
@inline source_top_at(optics::LongwaveOptics{<:Any, <:AbstractMatrix}, g, k) = optics.source_top[g, k]
@inline source_bottom_at(optics::LongwaveOptics{<:Any, <:AbstractMatrix}, g, k) = optics.source_bottom[g, k]

@inline has_longwave_scattering(optics::LongwaveOptics) =
    optics.single_scattering_albedo !== nothing &&
    optics.scattering_asymmetry !== nothing
@inline single_scattering_albedo_at(optics::LongwaveOptics{<:Any, <:AbstractVector}, g, k) =
    optics.single_scattering_albedo[k]
@inline scattering_asymmetry_at(optics::LongwaveOptics{<:Any, <:AbstractVector}, g, k) = optics.scattering_asymmetry[k]
@inline single_scattering_albedo_at(optics::LongwaveOptics{<:Any, <:AbstractMatrix}, g, k) =
    optics.single_scattering_albedo[g, k]
@inline scattering_asymmetry_at(optics::LongwaveOptics{<:Any, <:AbstractMatrix}, g, k) =
    optics.scattering_asymmetry[g, k]

# Transmittance 𝒯 = e^{-Dτ} and upward and downward emission Sꜛ, Sꜜ of a
# non-scattering layer whose Planck source is linear in optical depth between
# B_top and B_bottom, with diffusivity factor D = 1.66 (ecRad's half-level
# Planck path); the thin-layer limit below τ = 10⁻³ emits Dτ (B_top + B_bottom)/2
# in each direction.
@inline function no_scattering_longwave_sources(::Type{FT}, τ, B_top, B_bottom) where FT
    D = FT(1.66)
    Dτ = D * FT(τ)
    𝒯 = exp(-Dτ)
    if τ > FT(1.0e-3)
        ∂B = (FT(B_bottom) - FT(B_top)) / Dτ
        Sꜛ = ∂B + FT(B_top) - 𝒯 * (∂B + FT(B_bottom))
        Sꜜ = -∂B + FT(B_bottom) - 𝒯 * (-∂B + FT(B_top))
        return 𝒯, Sꜛ, Sꜜ
    end
    S = Dτ * FT(0.5) * (FT(B_top) + FT(B_bottom))
    return 𝒯, S, S
end

# Reflectance ℛ, transmittance 𝒯 and upward and downward emission Sꜛ, Sꜜ of
# a scattering longwave layer (single-scattering albedo ω, asymmetry factor 𝒢)
# with the hemispheric-mean two-stream coefficients
#     γ₁ = D - (D/2) ω (1 + 𝒢),   γ₂ = (D/2) ω (1 - 𝒢),   λ = √((γ₁ - γ₂)(γ₁ + γ₂)),
# D = 1.66, and a Planck source linear in τ between B_top and B_bottom.
@inline function longwave_reflectance_transmittance_sources(::Type{FT}, τ, ω, 𝒢, B_top, B_bottom) where FT
    D = FT(1.66)
    ω = clamp(FT(ω), zero(FT), one(FT))
    𝒢 = clamp(FT(𝒢), -one(FT), one(FT))
    factor = (D * FT(0.5)) * ω
    γ₁ = D - factor * (one(FT) + 𝒢)
    γ₂ = factor * (one(FT) - 𝒢)
    λ = sqrt(max((γ₁ - γ₂) * (γ₁ + γ₂), FT(1.0e-12)))
    τ = max(FT(τ), zero(FT))
    if τ > FT(1.0e-3)
        e = exp(-λ * τ)
        e₂ = e * e
        inverse_denominator = inv(λ + γ₁ + (λ - γ₁) * e₂)
        ℛ = γ₂ * (one(FT) - e₂) * inverse_denominator
        𝒯 = FT(2) * λ * e * inverse_denominator
        ∂B = (FT(B_bottom) - FT(B_top)) / (τ * (γ₁ + γ₂))
        Sꜛ_top = ∂B + FT(B_top)
        Sꜛ_bottom = ∂B + FT(B_bottom)
        Sꜜ_top = -∂B + FT(B_top)
        Sꜜ_bottom = -∂B + FT(B_bottom)
        Sꜛ = Sꜛ_top - ℛ * Sꜜ_top - 𝒯 * Sꜛ_bottom
        Sꜜ = Sꜜ_bottom - ℛ * Sꜛ_bottom - 𝒯 * Sꜜ_top
        return ℛ, 𝒯, Sꜛ, Sꜜ
    end
    ℛ = γ₂ * τ
    𝒯 = (one(FT) - λ * τ) / (one(FT) + τ * (γ₁ - λ))
    S = (one(FT) - ℛ - 𝒯) * FT(0.5) * (FT(B_top) + FT(B_bottom))
    return ℛ, 𝒯, S, S
end

# Interface Planck sources `(B_top, B_bottom)` of layer `k`, or the layer
# source on both interfaces when the optics carry none.
@inline function longwave_fallback_planck_sources(::Type{FT}, optics, g, k) where FT
    if has_interface_sources(optics)
        return source_top_at(optics, g, k), source_bottom_at(optics, g, k)
    end
    B = source_at(optics, g, k)
    return B, B
end

@inline surface_longwave_up_at(boundary_conditions::LongwaveBoundaryConditions{FT}, g) where FT =
    boundary_conditions.surface_longwave_up isa Number ?
    boundary_conditions.surface_longwave_up :
    FT(boundary_conditions.surface_longwave_up[g])
@inline surface_longwave_albedo(boundary_conditions::LongwaveBoundaryConditions{FT}, g) where FT =
    boundary_conditions.surface_albedo isa Number ?
    boundary_conditions.surface_albedo :
    FT(boundary_conditions.surface_albedo[g])

# Adapters that present one g point of precomputed array optics and boundary
# conditions in the functor form of `streaming_longwave_fluxes!`: the streamed
# g-point index is always 1, so both ignore it and read the g point they were
# built for.
struct ArrayLayerOptics{O}
    optics :: O
    g :: Int
end

@inline (layer::ArrayLayerOptics)(_, k) = (optical_depth_at(layer.optics, layer.g, k),
                                           source_top_at(layer.optics, layer.g, k),
                                           source_bottom_at(layer.optics, layer.g, k))

struct BoundarySurfaceEmission{B}
    boundary_conditions :: B
    g :: Int
end

@inline Base.getindex(emission::BoundarySurfaceEmission, _) =
    surface_longwave_up_at(emission.boundary_conditions, emission.g)

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
    Nz = number_of_layers(optics)
    length(fluxes.longwave_up) == Nz + 1 || throw(DimensionMismatch("longwave_up must have length Nz + 1"))
    length(fluxes.longwave_down) == Nz + 1 || throw(DimensionMismatch("longwave_down must have length Nz + 1"))

    fluxes.longwave_up .= zero(FT)
    fluxes.longwave_down .= zero(FT)

    if has_longwave_scattering(optics)
        has_interface_sources(optics) ||
            throw(ArgumentError("longwave scattering requires source_top and source_bottom interface Planck sources"))
        reflectance = zeros(FT, Nz)
        transmittance = zeros(FT, Nz)
        source_up = zeros(FT, Nz)
        source_down = zeros(FT, Nz)
        albedo = zeros(FT, Nz + 1)
        source = zeros(FT, Nz + 1)
        inverse_denominator = zeros(FT, Nz)

        for g in 1:number_of_gpoints(optics)
            w = FT(optics.weights[g])
            for k in 1:Nz
                B_top, B_bottom = longwave_fallback_planck_sources(FT, optics, g, k)
                reflectance[k], transmittance[k], source_up[k], source_down[k] = longwave_reflectance_transmittance_sources(
                        FT, optical_depth_at(optics, g, k), single_scattering_albedo_at(optics, g, k),
                        scattering_asymmetry_at(optics, g, k), B_top, B_bottom)
            end

            albedo[Nz + 1] = clamp(surface_longwave_albedo(boundary_conditions, g), zero(FT), one(FT))
            source[Nz + 1] = surface_longwave_up_at(boundary_conditions, g)
            for k in Nz:-1:1
                inverse_denominator[k] = inv(one(FT) - albedo[k + 1] * reflectance[k])
                albedo[k] = reflectance[k] + transmittance[k]^2 * albedo[k + 1] * inverse_denominator[k]
                source[k] = source_up[k] +
                    transmittance[k] *
                    (source[k + 1] + albedo[k + 1] * source_down[k]) *
                    inverse_denominator[k]
            end

            down = boundary_conditions.toa_longwave_down
            fluxes.longwave_down[1] += w * down
            fluxes.longwave_up[1] += w * (source[1] + albedo[1] * down)
            for k in 1:Nz
                down = (transmittance[k] * down +
                        reflectance[k] * source[k + 1] +
                        source_down[k]) * inverse_denominator[k]
                up = albedo[k + 1] * down + source[k + 1]
                fluxes.longwave_down[k + 1] += w * down
                fluxes.longwave_up[k + 1] += w * up
            end
        end

        return fluxes
    end

    # No scattering: sweep down from the top of the atmosphere, then up from
    # the surface, where the upwelling flux is the surface emission plus the
    # reflected downwelling flux, `up = ε B(Tˢ) + α down`. The interface-source
    # (ecRad half-level Planck) layers run through `streaming_longwave_fluxes!`
    # one g point at a time, so a host kernel streaming that function directly
    # reproduces this solver bit for bit.
    if has_interface_sources(optics)
        gpoint_up = zeros(FT, Nz + 1)
        gpoint_down = zeros(FT, Nz + 1)
        transmittance = zeros(FT, Nz)
        source_up = zeros(FT, Nz)
        for g in 1:number_of_gpoints(optics)
            w = FT(optics.weights[g])
            streaming_longwave_fluxes!(gpoint_up, gpoint_down,
                                       ArrayLayerOptics(optics, g),
                                       BoundarySurfaceEmission(boundary_conditions, g),
                                       surface_longwave_albedo(boundary_conditions, g),
                                       boundary_conditions.toa_longwave_down,
                                       (w,), 1, Nz, transmittance, source_up)
            fluxes.longwave_up .+= gpoint_up
            fluxes.longwave_down .+= gpoint_down
        end

        return fluxes
    end

    for g in 1:number_of_gpoints(optics)
        w = FT(optics.weights[g])

        down = boundary_conditions.toa_longwave_down
        fluxes.longwave_down[1] += w * down
        for k in 1:Nz
            layer_transmittance = exp(-optical_depth_at(optics, g, k))
            layer_source = source_at(optics, g, k)
            down = down * layer_transmittance + layer_source * (one(FT) - layer_transmittance)
            fluxes.longwave_down[k + 1] += w * down
        end

        up = surface_longwave_up_at(boundary_conditions, g) +
             surface_longwave_albedo(boundary_conditions, g) * down
        fluxes.longwave_up[Nz + 1] += w * up
        for k in Nz:-1:1
            layer_transmittance = exp(-optical_depth_at(optics, g, k))
            layer_source = source_at(optics, g, k)
            up = up * layer_transmittance + layer_source * (one(FT) - layer_transmittance)
            fluxes.longwave_up[k] += w * up
        end
    end

    return fluxes
end
