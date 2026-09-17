#####
##### Streaming no-scattering longwave solver
#####
#
# The per-column, per-g-point core of the no-scattering longwave path of
# `radiative_fluxes!(…, CloudlessLongwave(), …)`, written so that a host
# kernel can run it with scalar layer optics: the caller supplies a functor
# `layer_optics(gpoint, k) -> (τ, B_top, B_bottom)` and an indexable per-g surface
# source, and the solver streams over g points accumulating weighted broadband
# fluxes into caller-owned interface arrays. The array solver in
# `cloudless_longwave.jl` calls this function one g point at a time, so the
# two paths agree bit for bit.
#
# Device-path rules: everything here is `@inline`, allocation-free, never
# throws, and takes `FT` from the flux arrays.

"""
$(TYPEDEF)

Per-g-point surface longwave source of an ecCKD gas-optics model at one
surface `temperature`, with the surface `emissivity` folded in:
`e[gpoint] = ε B(Tₛ)`, where `B` is the model's [`longwave_source`](@ref) at
that g point in its per-unit-weight flux convention. The Planck source-table bracket is
taken once at construction, so indexing is one table interpolation per
g point, and construction inside a kernel is allocation-free.

It is an `AbstractVector`, so it can be passed directly as
`surface_longwave_up` in [`LongwaveBoundaryConditions`](@ref) or as the
`surface_emission` of [`streaming_longwave_fluxes!`](@ref);
[`surface_longwave_emission`](@ref) is its `collect`.
"""
struct TabulatedSurfaceEmission{FT, M, B} <: AbstractVector{FT}
    model :: M
    temperature :: FT
    emissivity :: FT
    bracket :: B
end

const EcCKDModels{FT} = Union{EcCKDTabulatedGasOpticsModel{FT}, EcCKDGasOpticsModel{FT}}

"""
$(TYPEDSIGNATURES)

Surface longwave source of `model` at `temperature` (K) scaled by
`emissivity`, evaluated lazily per g point; see [`TabulatedSurfaceEmission`](@ref).
"""
@inline function TabulatedSurfaceEmission(model::EcCKDModels{FT},
                                          temperature;
                                          emissivity = one(FT)) where FT
    Tₛ = FT(temperature)
    bracket = source_table_bracket(model, Tₛ)
    return TabulatedSurfaceEmission{FT, typeof(model), typeof(bracket)}(model, Tₛ, FT(emissivity), bracket)
end

@inline Base.getindex(e::TabulatedSurfaceEmission, gpoint::Integer) =
    e.emissivity * longwave_source(e.model, gpoint, e.temperature, e.bracket)

Base.size(e::TabulatedSurfaceEmission) = (length(e.model.longwave_weights),)
Base.length(e::TabulatedSurfaceEmission) = length(e.model.longwave_weights)
Base.eltype(::TabulatedSurfaceEmission{FT}) where FT = FT
Base.IndexStyle(::Type{<:TabulatedSurfaceEmission}) = IndexLinear()

"""
$(TYPEDSIGNATURES)

Per-g-point surface longwave emission of `model` at the surface `temperature`,
scaled by `emissivity`, in the same per-unit-weight flux convention as the
model's Planck source tables, as a host `Vector`. Pass the result as
`surface_longwave_up` in [`LongwaveBoundaryConditions`](@ref). It is the
`collect` of a [`TabulatedSurfaceEmission`](@ref), which device code
indexes lazily instead.

For multi-g spectral models a scalar ``σT⁴`` boundary is a gray
approximation: it does not reproduce the model's tabulated Planck spectrum
across g points and may bias outgoing longwave fluxes.
"""
function surface_longwave_emission(model::EcCKDModels{FT},
                                   temperature;
                                   emissivity = one(FT)) where FT
    return collect(TabulatedSurfaceEmission(model, temperature; emissivity))
end

"""
$(TYPEDSIGNATURES)

No-scattering longwave interface fluxes of one column, streamed over g
points and accumulated into `flux_up` and `flux_down` (length `nlayers + 1`,
top-down, interface 1 at the top of the atmosphere; both are zeroed here).
Each layer is the ecRad half-level Planck path of
[`CloudlessLongwave`](@ref): with diffusivity `D = 1.66` and the layer's
`(τ, B_top, B_bottom)` from `layer_optics(gpoint, k)`, the layer transmittance
is `e^{-Dτ}` and its emission is that of a Planck function linear in optical
depth between the two interfaces (the thin-layer limit below `τ = 10⁻³`).

The column is swept downward first, from `toa_down` (the downwelling flux
entering the top interface, the same for every g point), then upward from
the surface, where `up = surface_emission[gpoint] + surface_albedo * down`:
`surface_emission` is indexable per g point with the emissivity already
included (a [`TabulatedSurfaceEmission`](@ref)) and `surface_albedo` is the
diffuse longwave surface albedo. Each g point's fluxes are added with
`weights[gpoint]` for `gpoint in 1:Ngpoints`. `transmittance` and `source_up` are caller
scratch of length `nlayers` that carry the layer coefficients from the
downward sweep to the upward one. Allocation-free.
"""
@inline function streaming_longwave_fluxes!(flux_up, flux_down, layer_optics, surface_emission, surface_albedo, toa_down,
                                            weights, Ngpoints, nlayers, transmittance, source_up)
    FT = eltype(flux_up)

    @inbounds for k in 1:nlayers + 1
        flux_up[k] = zero(FT)
        flux_down[k] = zero(FT)
    end

    @inbounds for gpoint in 1:Ngpoints
        w = FT(weights[gpoint])

        # Downward sweep from the top of the atmosphere, keeping each layer's
        # transmittance and upward source for the sweep back up.
        down = FT(toa_down)
        flux_down[1] += w * down
        for k in 1:nlayers
            τ, B_top, B_bottom = layer_optics(gpoint, k)
            transmittance[k], source_up[k], source_down =
                no_scattering_longwave_sources(FT, τ, B_top, B_bottom)
            down = down * transmittance[k] + source_down
            flux_down[k + 1] += w * down
        end

        # Upward sweep from the surface: emission plus the reflected
        # downwelling flux that just arrived there.
        up = FT(surface_emission[gpoint]) + FT(surface_albedo) * down
        flux_up[nlayers + 1] += w * up
        for k in nlayers:-1:1
            up = up * transmittance[k] + source_up[k]
            flux_up[k] += w * up
        end
    end

    return flux_up, flux_down
end
