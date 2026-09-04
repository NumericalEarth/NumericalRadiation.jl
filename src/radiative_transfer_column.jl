"""
$(TYPEDEF)

Bundles everything a single-column radiation calculation needs: grid,
atmosphere profile, surface state, longwave and shortwave schemes, the
thermodynamic and physical constants, and pre-allocated buffers for the
temperature tendency, layer transmissivity, and diagnostic fluxes.

The high-level API is [`solve_longwave!`](@ref) and
[`solve_shortwave!`](@ref) on a `RadiativeTransferColumn`:

```julia
rtm = RadiativeTransferColumn(; grid, profile, surface)
solve_longwave!(rtm)
solve_shortwave!(rtm)
@show rtm.longwave_diagnostics.outgoing_longwave
```

Fields are

$(TYPEDFIELDS)
"""
struct RadiativeTransferColumn{NF, LW, SW, PC, TC, V<:AbstractVector{NF}, G<:ColumnGrid{NF},
                               AP<:AtmosphereProfile{NF}}
    "Column vertical grid (sigma coordinates)"
    grid::G
    "Atmosphere profile (temperature, humidity, geopotential, surface pressure, rain rate)"
    profile::AP
    "Lower boundary state (SST/LST, albedos, emissivities, cos-zenith)"
    surface::SurfaceState{NF}
    "Longwave scheme, e.g. [`AnalyticBandLongwave`](@ref)"
    longwave_scheme::LW
    "Shortwave scheme, e.g. [`OneBandShortwave`](@ref) or [`TransparentShortwave`](@ref)"
    shortwave_scheme::SW
    "Physical constants (gravity, heat capacity, Stefan–Boltzmann, solar constant)"
    physical_constants::PC
    "Thermodynamic constants (Clausius–Clapeyron parameters for saturation humidity)"
    thermodynamic_constants::TC
    "Per-layer temperature tendency written by `solve_longwave!` / `solve_shortwave!`"
    temperature_tendency::V
    "Per-layer scratch for the shortwave transmissivity"
    transmissivity_scratch::V
    "Scalar longwave diagnostics (OLR, surface up/down, ocean/land split)"
    longwave_diagnostics::LongwaveDiagnostics{NF}
    "Scalar shortwave diagnostics (TOA up, surface up/down, albedo, clouds)"
    shortwave_diagnostics::ShortwaveDiagnostics{NF}
end

"""$(TYPEDSIGNATURES)
Construct a [`RadiativeTransferColumn`](@ref).

Required:
- `grid`     — a [`ColumnGrid`](@ref).
- `profile`  — an [`AtmosphereProfile`](@ref) whose temperature vector drives `nlayers`.
- `surface`  — a [`SurfaceState`](@ref).

Optional schemes and constants default to sensible Earth choices of the same
floating-point type as `profile.temperature`.
"""
function RadiativeTransferColumn(;
        grid::ColumnGrid,
        profile::AtmosphereProfile,
        surface::SurfaceState,
        longwave_scheme         = AnalyticBandLongwave(eltype(profile.temperature)),
        shortwave_scheme        = OneBandShortwave(eltype(profile.temperature)),
        physical_constants      = PhysicalConstants{eltype(profile.temperature)}(),
        thermodynamic_constants = ThermodynamicConstants{eltype(profile.temperature)}(),
    )
    NF      = eltype(profile.temperature)
    nlayers = length(profile.temperature)
    V       = typeof(profile.temperature)
    G       = typeof(grid)
    AP      = typeof(profile)
    LW      = typeof(longwave_scheme)
    SW      = typeof(shortwave_scheme)
    PC      = typeof(physical_constants)
    TC      = typeof(thermodynamic_constants)

    temperature_tendency   = zeros(NF, nlayers)
    transmissivity_scratch = similar(profile.temperature)
    longwave_diagnostics   = LongwaveDiagnostics{NF}()
    shortwave_diagnostics  = ShortwaveDiagnostics{NF}(nlayers)

    return RadiativeTransferColumn{NF, LW, SW, PC, TC, V, G, AP}(
        grid, profile, surface,
        longwave_scheme, shortwave_scheme,
        physical_constants, thermodynamic_constants,
        temperature_tendency, transmissivity_scratch,
        longwave_diagnostics, shortwave_diagnostics,
    )
end

"""$(TYPEDSIGNATURES)
Zero the temperature tendency and scalar diagnostics on `rtm` so a fresh
`solve_longwave!` / `solve_shortwave!` doesn't accumulate onto stale values.
"""
function reset!(rtm::RadiativeTransferColumn)
    rtm.temperature_tendency .= 0
    reset!(rtm.longwave_diagnostics)
    reset!(rtm.shortwave_diagnostics)
    return rtm
end

function reset!(d::LongwaveDiagnostics{NF}) where NF
    d.outgoing_longwave = zero(NF)
    d.surface_longwave_down = zero(NF)
    d.surface_longwave_up = zero(NF)
    d.ocean_surface_longwave_up = zero(NF)
    d.land_surface_longwave_up = zero(NF)
    return d
end

function reset!(d::ShortwaveDiagnostics{NF}) where NF
    d.outgoing_shortwave = zero(NF)
    d.surface_shortwave_down = zero(NF)
    d.surface_shortwave_up = zero(NF)
    d.ocean_surface_shortwave_down = zero(NF)
    d.land_surface_shortwave_down = zero(NF)
    d.ocean_surface_shortwave_up = zero(NF)
    d.land_surface_shortwave_up = zero(NF)
    d.albedo = zero(NF)
    d.cloud_cover = zero(NF)
    d.cloud_top = 0
    d.stratocumulus_cover = zero(NF)
    return d
end

"""$(TYPEDSIGNATURES)
Column longwave radiative transfer using the scheme stored on `rtm`.
Accumulates into `rtm.temperature_tendency` (call `reset!(rtm)` first if you
want a clean slate) and writes scalars into `rtm.longwave_diagnostics`.
"""
function solve_longwave!(rtm::RadiativeTransferColumn)
    solve_longwave!(
        rtm.temperature_tendency,
        rtm.longwave_diagnostics,
        rtm.longwave_scheme,
        rtm.profile,
        rtm.grid,
        rtm.surface,
        rtm.physical_constants,
    )
    return rtm
end

"""$(TYPEDSIGNATURES)
Column shortwave radiative transfer using the scheme stored on `rtm`.
"""
function solve_shortwave!(rtm::RadiativeTransferColumn;
                          cloud_top_convective::Integer = length(rtm.profile.temperature) + 1)
    solve_shortwave!(
        rtm.temperature_tendency,
        rtm.shortwave_diagnostics,
        rtm.shortwave_scheme,
        rtm.profile,
        rtm.grid,
        rtm.surface,
        rtm.physical_constants,
        rtm.thermodynamic_constants;
        transmissivity_scratch = rtm.transmissivity_scratch,
        cloud_top_convective   = cloud_top_convective,
    )
    return rtm
end
