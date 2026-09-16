"""
$(TYPEDEF)

Per-column scratch storage for [`streaming_shortwave_fluxes!`](@ref): five
layer vectors of length `nlayers` and two interface vectors of length
`nlayers + 1`. On the host `V` is a `Vector{FT}`; a host kernel hands in views
of one row of its own device matrices instead, so the solver never allocates.

The five layer vectors hold the delta-Eddington two-stream properties of each
layer, except that `direct_transmittance[k]` stores the normal-incidence
direct-beam flux at the *bottom* of layer `k` (the incoming normal flux times
the direct transmittance of layers `1:k`) rather than the layer's own direct
transmittance: the adding sweeps need that running product, not the factor.
`stack_albedo[k]` and `source[k]` are the diffuse albedo and upward diffuse
source of everything below interface `k`.

Every element is written before it is read, so the storage need not be
initialized. Fields are

$(TYPEDFIELDS)
"""
struct ShortwaveColumnScratch{V}
    "Layer diffuse reflectance, length `nlayers`."
    reflectance::V
    "Layer diffuse transmittance, length `nlayers`."
    transmittance::V
    "Layer reflectance of the direct beam into the diffuse upward stream, length `nlayers`."
    direct_reflectance::V
    "Layer transmittance of the direct beam into the diffuse downward stream, length `nlayers`."
    direct_diffuse_transmittance::V
    "Normal-incidence direct-beam flux at the bottom of each layer, length `nlayers`."
    direct_transmittance::V
    "Diffuse albedo of the stack below each interface, length `nlayers + 1`."
    stack_albedo::V
    "Upward diffuse source of the stack below each interface, length `nlayers + 1`."
    source::V
end

"""
$(TYPEDSIGNATURES)

Allocate host scratch storage of element type `FT` for a column of `nlayers`
layers.
"""
ShortwaveColumnScratch(::Type{FT}, nlayers) where FT =
    ShortwaveColumnScratch(Vector{FT}(undef, nlayers),
                           Vector{FT}(undef, nlayers),
                           Vector{FT}(undef, nlayers),
                           Vector{FT}(undef, nlayers),
                           Vector{FT}(undef, nlayers),
                           Vector{FT}(undef, nlayers + 1),
                           Vector{FT}(undef, nlayers + 1))

Base.eltype(::ShortwaveColumnScratch{V}) where V = eltype(V)

@inline gpoint_albedo(albedo::Number, ig) = albedo
@inline gpoint_albedo(albedo, ig) = @inbounds albedo[ig]

"""
$(TYPEDSIGNATURES)

Add the `weight`-scaled fluxes of g point `ig` to `flux_up` and `flux_down`
(length `nlayers + 1`, top down), by the two-stream adding method of
[`streaming_shortwave_fluxes!`](@ref) with scalar `direct_albedo` and
`diffuse_albedo`. This is the single g-point body that every clear-sky
shortwave path shares; `μ0` is clamped to `√eps(FT)` here.
"""
@inline function add_shortwave_gpoint_fluxes!(flux_up, flux_down, layer_optics, ig, weight,
                                              μ0, toa_irradiance, direct_albedo, diffuse_albedo,
                                              nlayers, scratch::ShortwaveColumnScratch)
    FT = eltype(flux_up)
    μ0 = max(FT(μ0), sqrt(eps(FT)))
    incoming_normal = FT(toa_irradiance) / μ0
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
    @inbounds for k in 1:nlayers
        τ_absorption, τ_scattering, asymmetry = layer_optics(ig, k)
        absorption_tau = max(FT(τ_absorption), zero(FT))
        scattering_tau = max(FT(τ_scattering), zero(FT))
        total_tau = absorption_tau + scattering_tau
        ssa = ifelse(total_tau == zero(FT), zero(FT), scattering_tau / total_tau)
        g = clamp(FT(asymmetry), -one(FT), one(FT))
        reflectance[k], transmittance[k], direct_reflectance[k], direct_diffuse_transmittance[k],
            direct_transmittance = sw_two_stream_layer(FT, μ0, total_tau, ssa, g)
        direct_above *= direct_transmittance
        direct_flux[k] = direct_above
    end
    direct_surface = direct_above

    # Bottom up (adding): diffuse albedo and upward diffuse source of the
    # stack below each interface, starting from the surface.
    @inbounds stack_albedo[nlayers + 1] = FT(diffuse_albedo)
    @inbounds source[nlayers + 1] = FT(direct_albedo) * direct_surface * μ0
    @inbounds for k in nlayers:-1:1
        below = stack_albedo[k + 1]
        inv_denominator = inv(one(FT) - below * reflectance[k])
        stack_albedo[k] = reflectance[k] +
            transmittance[k] * transmittance[k] * below * inv_denominator
        direct_above = ifelse(k == 1, incoming_normal, direct_flux[max(k - 1, 1)])
        source[k] = direct_reflectance[k] * direct_above +
            transmittance[k] *
            (source[k + 1] + below * direct_diffuse_transmittance[k] * direct_above) *
            inv_denominator
    end

    # Top down: downward diffuse flux through the stack, then the interface
    # fluxes. The denominator is recomputed rather than stored.
    flux_diffuse = zero(FT)
    @inbounds flux_up[1] += w * source[1]
    @inbounds flux_down[1] += w * (incoming_normal * μ0)
    direct_above = incoming_normal
    @inbounds for k in 1:nlayers
        below = stack_albedo[k + 1]
        inv_denominator = inv(one(FT) - below * reflectance[k])
        direct_below = direct_flux[k]
        flux_diffuse =
            (transmittance[k] * flux_diffuse +
             reflectance[k] * source[k + 1] +
             direct_diffuse_transmittance[k] * direct_above) * inv_denominator
        flux_up[k + 1] += w * (below * flux_diffuse + source[k + 1])
        flux_down[k + 1] += w * (flux_diffuse + direct_below * μ0)
        direct_above = direct_below
    end

    return nothing
end

"""
$(TYPEDSIGNATURES)

Clear-sky shortwave interface fluxes of one column by the two-stream adding
method of ecRad, with every g point streamed through one
[`ShortwaveColumnScratch`](@ref) and accumulated in place. `flux_up` and
`flux_down` have length `nlayers + 1`, are ordered top down (index 1 at the
top of the atmosphere), and are zeroed here; `FT = eltype(flux_up)`.

`layer_optics(ig, k)` returns the tuple `(τ_absorption, τ_scattering, asymmetry)`
of layer `k` for g point `ig`; the single-scattering albedo
`ω = τ_scattering / (τ_absorption + τ_scattering)` and the total optical depth
are formed here, and every layer passes through
[`sw_two_stream_layer`](@ref), which applies delta-Eddington scaling.
`weights[ig]` scales the g point's contribution. `direct_albedo` and
`diffuse_albedo` are broadband numbers or per-g-point indexables.

`toa_irradiance` is the downwelling shortwave flux through a horizontal
surface at the top of the atmosphere, `S₀ μ₀` for solar constant `S₀`, so the
normal-incidence flux entering the adding sweeps is
`toa_irradiance / max(μ₀, √eps(FT))`. The same clamped `μ₀` is used throughout,
matching [`sw_path_factor`](@ref). A host that passes
`toa_irradiance = S₀ max(μ₀, 0)` therefore gets exact zeros, and no `NaN`, at
night (`μ₀ ≤ 0`).

Allocation-free; `scratch` may hold views into a host's own arrays.
"""
@inline function streaming_shortwave_fluxes!(flux_up, flux_down, layer_optics, μ0, toa_irradiance,
                                             direct_albedo, diffuse_albedo, weights, ng, nlayers,
                                             scratch::ShortwaveColumnScratch)
    FT = eltype(flux_up)
    @inbounds for k in 1:nlayers + 1
        flux_up[k] = zero(FT)
        flux_down[k] = zero(FT)
    end
    for ig in 1:ng
        add_shortwave_gpoint_fluxes!(flux_up, flux_down, layer_optics, ig,
                                     @inbounds(weights[ig]), μ0, toa_irradiance,
                                     gpoint_albedo(direct_albedo, ig),
                                     gpoint_albedo(diffuse_albedo, ig),
                                     nlayers, scratch)
    end
    return nothing
end
