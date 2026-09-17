"""
$(TYPEDEF)

Per-column scratch storage for [`streaming_shortwave_fluxes!`](@ref): five
layer vectors of length `Nz` and two interface vectors of length
`Nz + 1`. On the host `V` is a `Vector{FT}`; a host kernel hands in views
of one row of its own device matrices instead, so the solver never allocates.

The five layer vectors hold the delta-Eddington two-stream properties of each
layer, except that `direct_transmittance[k]` stores the normal-incidence
direct-beam flux at the *bottom* of layer `k` (the incoming normal flux times
the direct transmittance of layers `1:k`) rather than the layer's own direct
transmittance: the adding sweeps need that running product, not the factor.
`stack_albedo[k]` and `source[k]` are the diffuse albedo and upward diffuse
source of everything below interface `k`.

Every element is written before it is read, so the storage need not be
initialized.

Fields:
- `reflectance`: Layer diffuse reflectance, length `Nz`
- `transmittance`: Layer diffuse transmittance, length `Nz`
- `direct_reflectance`: Layer reflectance of the direct beam into the diffuse upward stream,
  length `Nz`
- `direct_diffuse_transmittance`: Layer transmittance of the direct beam into the diffuse
  downward stream, length `Nz`
- `direct_transmittance`: Normal-incidence direct-beam flux at the bottom of each layer,
  length `Nz`
- `stack_albedo`: Diffuse albedo of the stack below each interface, length `Nz + 1`
- `source`: Upward diffuse source of the stack below each interface, length `Nz + 1`
"""
struct ShortwaveColumnScratch{V}
    reflectance::V
    transmittance::V
    direct_reflectance::V
    direct_diffuse_transmittance::V
    direct_transmittance::V
    stack_albedo::V
    source::V
end

"""
$(TYPEDSIGNATURES)

Allocate host scratch storage of element type `FT`, passed as the first
positional argument, for a column of `Nz` layers.
"""
ShortwaveColumnScratch(::Type{FT}, Nz) where FT = ShortwaveColumnScratch(Vector{FT}(undef, Nz),
                                                                         Vector{FT}(undef, Nz),
                                                                         Vector{FT}(undef, Nz),
                                                                         Vector{FT}(undef, Nz),
                                                                         Vector{FT}(undef, Nz),
                                                                         Vector{FT}(undef, Nz + 1),
                                                                         Vector{FT}(undef, Nz + 1))

"""
$(TYPEDSIGNATURES)

Allocate `Float64` host scratch storage for a column of `Nz` layers.
"""
ShortwaveColumnScratch(Nz::Integer) = ShortwaveColumnScratch(Float64, Nz)

Base.eltype(::ShortwaveColumnScratch{V}) where V = eltype(V)

@inline gpoint_albedo(albedo::Number, g) = albedo
@inline gpoint_albedo(albedo, g) = @inbounds albedo[g]

"""
$(TYPEDSIGNATURES)

Add the `weight`-scaled fluxes of g point `g` to `flux_up` and `flux_down`
(length `Nz + 1`, top down), by the two-stream adding method of
[`streaming_shortwave_fluxes!`](@ref) with scalar `direct_albedo` and
`diffuse_albedo`. This is the single g-point body that every clear-sky
shortwave path shares; `μ₀` is clamped to `√eps(FT)` here.
"""
@inline function add_shortwave_gpoint_fluxes!(flux_up, flux_down, layer_optics, g, weight,
                                              μ₀, toa_irradiance, direct_albedo, diffuse_albedo,
                                              Nz, scratch::ShortwaveColumnScratch)
    FT = eltype(flux_up)
    μ₀ = max(FT(μ₀), sqrt(eps(FT)))
    incoming_normal = FT(toa_irradiance) / μ₀
    w = FT(weight)

    reflectance = scratch.reflectance
    transmittance = scratch.transmittance
    direct_reflectance = scratch.direct_reflectance
    direct_diffuse_transmittance = scratch.direct_diffuse_transmittance
    direct_flux = scratch.direct_transmittance
    stack_albedo = scratch.stack_albedo
    source = scratch.source

    # Top down: delta-Eddington two-stream properties of each layer and the
    # direct beam, attenuated by the direct transmittance of every layer above.
    direct_above = incoming_normal
    @inbounds for k in 1:Nz
        τₐ, τₛ, 𝒢 = layer_optics(g, k)
        τₐ = max(FT(τₐ), zero(FT))
        τₛ = max(FT(τₛ), zero(FT))
        τ = τₐ + τₛ
        ω = ifelse(τ == zero(FT), zero(FT), τₛ / τ)
        𝒢 = clamp(FT(𝒢), -one(FT), one(FT))
        reflectance[k], transmittance[k], direct_reflectance[k], direct_diffuse_transmittance[k],
            direct_transmittance = shortwave_two_stream_layer(FT, μ₀, τ, ω, 𝒢)
        direct_above *= direct_transmittance
        direct_flux[k] = direct_above
    end
    direct_surface = direct_above

    # Bottom up (adding): diffuse albedo and upward diffuse source of the
    # stack below each interface, starting from the surface.
    @inbounds stack_albedo[Nz + 1] = FT(diffuse_albedo)
    @inbounds source[Nz + 1] = FT(direct_albedo) * direct_surface * μ₀
    @inbounds for k in Nz:-1:1
        below = stack_albedo[k + 1]
        inverse_denominator = inv(one(FT) - below * reflectance[k])
        stack_albedo[k] = reflectance[k] + transmittance[k] * transmittance[k] * below * inverse_denominator
        direct_above = ifelse(k == 1, incoming_normal, direct_flux[max(k - 1, 1)])
        source[k] = direct_reflectance[k] * direct_above +
            transmittance[k] *
            (source[k + 1] + below * direct_diffuse_transmittance[k] * direct_above) *
            inverse_denominator
    end

    # Top down: downward diffuse flux through the stack, then the interface
    # fluxes. The denominator is recomputed rather than stored.
    flux_diffuse = zero(FT)
    @inbounds flux_up[1] += w * source[1]
    @inbounds flux_down[1] += w * (incoming_normal * μ₀)
    direct_above = incoming_normal
    @inbounds for k in 1:Nz
        below = stack_albedo[k + 1]
        inverse_denominator = inv(one(FT) - below * reflectance[k])
        direct_below = direct_flux[k]
        flux_diffuse = (transmittance[k] * flux_diffuse +
                        reflectance[k] * source[k + 1] +
                        direct_diffuse_transmittance[k] * direct_above) * inverse_denominator
        flux_up[k + 1] += w * (below * flux_diffuse + source[k + 1])
        flux_down[k + 1] += w * (flux_diffuse + direct_below * μ₀)
        direct_above = direct_below
    end

    return nothing
end

"""
$(TYPEDSIGNATURES)

Clear-sky shortwave interface fluxes of one column by the two-stream adding
method of ecRad, with every g point streamed through one
[`ShortwaveColumnScratch`](@ref) and accumulated in place. `flux_up` and
`flux_down` have length `Nz + 1`, are ordered top down (index 1 at the
top of the atmosphere), and are zeroed here; `FT = eltype(flux_up)`.

`layer_optics(g, k)` returns the tuple `(τₐ, τₛ, 𝒢)`
of layer `k` for g point `g`; the single-scattering albedo
`ω = τₛ / (τₐ + τₛ)` and the total optical depth
are formed here, and every layer passes through
[`shortwave_two_stream_layer`](@ref), which applies delta-Eddington scaling.
`weights[g]` scales the g point's contribution. `direct_albedo` and
`diffuse_albedo` are broadband numbers or per-g-point indexables.

`toa_irradiance` is the downwelling shortwave flux through a horizontal
surface at the top of the atmosphere, `S₀ μ₀` for solar constant `S₀`, so the
normal-incidence flux entering the adding sweeps is
`toa_irradiance / max(μ₀, √eps(FT))`. The same clamped `μ₀` is used throughout,
matching [`shortwave_path_factor`](@ref). A host that passes
`toa_irradiance = S₀ max(μ₀, 0)` therefore gets exact zeros, and no `NaN`, at
night (`μ₀ ≤ 0`).

Allocation-free; `scratch` may hold views into a host's own arrays.
"""
@inline function streaming_shortwave_fluxes!(flux_up, flux_down, layer_optics, μ₀, toa_irradiance,
                                             direct_albedo, diffuse_albedo, weights, Ng, Nz,
                                             scratch::ShortwaveColumnScratch)
    FT = eltype(flux_up)
    @inbounds for k in 1:Nz + 1
        flux_up[k] = zero(FT)
        flux_down[k] = zero(FT)
    end
    for g in 1:Ng
        add_shortwave_gpoint_fluxes!(flux_up, flux_down, layer_optics, g,
                                     @inbounds(weights[g]), μ₀, toa_irradiance,
                                     gpoint_albedo(direct_albedo, g),
                                     gpoint_albedo(diffuse_albedo, g),
                                     Nz, scratch)
    end
    return nothing
end
