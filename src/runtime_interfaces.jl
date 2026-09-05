"""
$(TYPEDEF)

Generic column atmosphere container for the staged radiation interface.

The existing analytic-band solvers use [`AtmosphereProfile`](@ref),
[`ColumnGrid`](@ref), and [`SurfaceState`](@ref) directly. `ColumnAtmosphere`
is a host-model-facing container for newer gas-optics and solver paths where
layer/interface pressure and temperature arrays need to be carried together.

Fields are

$(TYPEDFIELDS)
"""
struct ColumnAtmosphere{FT, A, G, S, Geo} <: AbstractAtmosphericState
    "Layer pressures, indexed top-down."
    pressure_layers::A
    "Interface pressures, indexed top-down."
    pressure_interfaces::A
    "Layer temperatures, indexed top-down."
    temperature_layers::A
    "Interface temperatures, indexed top-down."
    temperature_interfaces::A
    "Symbol-keyed gas concentrations or host-model property view."
    gases::G
    "Lower-boundary state."
    surface::S
    "Geometry, solar angles, or host-model geometry view."
    geometry::Geo
end

function ColumnAtmosphere(; pressure_layers::A,
                          pressure_interfaces::A,
                          temperature_layers::A,
                          temperature_interfaces::A,
                          gases::G,
                          surface::S,
                          geometry::Geo) where {A, G, S, Geo}
    FT = eltype(temperature_layers)
    return ColumnAtmosphere{FT, A, G, S, Geo}(
        pressure_layers,
        pressure_interfaces,
        temperature_layers,
        temperature_interfaces,
        gases,
        surface,
        geometry,
    )
end

Base.eltype(::ColumnAtmosphere{FT}) where FT = FT

"""
$(TYPEDEF)

Flux container for component radiation APIs.

Arrays are caller-owned and may be package work arrays, host-model views, or
device arrays. Interface flux arrays should have one more vertical point than
layer-centered heating arrays.

Fields are

$(TYPEDFIELDS)
"""
struct RadiativeFluxes{FT, A}
    "Upwelling longwave flux at interfaces."
    longwave_up::A
    "Downwelling longwave flux at interfaces."
    longwave_down::A
    "Upwelling shortwave flux at interfaces."
    shortwave_up::A
    "Downwelling shortwave flux at interfaces."
    shortwave_down::A
end

function RadiativeFluxes(; longwave_up::A,
                         longwave_down::A,
                         shortwave_up::A,
                         shortwave_down::A) where A
    FT = eltype(longwave_up)
    return RadiativeFluxes{FT, A}(longwave_up, longwave_down, shortwave_up, shortwave_down)
end

Base.eltype(::RadiativeFluxes{FT}) where FT = FT

"""
    RadiativeFluxes(atmosphere::ColumnAtmosphere)

Allocate a caller-owned [`RadiativeFluxes`](@ref) sized for `atmosphere`. Every
field is built via `similar` on `atmosphere.pressure_interfaces`, which already
has the required `nlayers + 1` length, so the allocation matches that array's
backend without a model or gas-optics dependency.
"""
function RadiativeFluxes(atmosphere::ColumnAtmosphere)
    prototype = atmosphere.pressure_interfaces
    flux_array() = similar(prototype)
    return RadiativeFluxes(longwave_up = flux_array(), longwave_down = flux_array(),
                           shortwave_up = flux_array(), shortwave_down = flux_array())
end

"""
    optical_properties!(optics, gas_model, atmosphere[, workspace])

Materialize gas optical properties. Concrete gas-optics models should overload
this method so host models can use gas optics without accepting the package's
solver or tendency path.
"""
function optical_properties!(args...)
    throw(MethodError(optical_properties!, args))
end

"""
    cloud_optical_properties!(optics, cloud_model, atmosphere[, workspace])

Materialize cloud optical properties independently of gas optics and solvers.
"""
function cloud_optical_properties!(args...)
    throw(MethodError(cloud_optical_properties!, args))
end

"""
    aerosol_optical_properties!(optics, aerosol_model, atmosphere[, workspace])

Materialize aerosol optical properties independently of gas optics and solvers.
"""
function aerosol_optical_properties!(args...)
    throw(MethodError(aerosol_optical_properties!, args))
end

"""
    radiative_fluxes!(fluxes, solver, optics, atmosphere, boundary_conditions[, workspace])

Compute radiative fluxes from optical properties/source terms. Concrete solvers
should overload this method.
"""
function radiative_fluxes!(args...)
    throw(MethodError(radiative_fluxes!, args))
end

"""
    heating_rates!(heating, fluxes, atmosphere[, workspace])

Convert flux divergence to heating rates. Concrete atmosphere/flux pairings
should overload this method when they do not use the existing column tendency
helpers.
"""
function heating_rates!(args...)
    throw(MethodError(heating_rates!, args))
end

"""
    heating_rates!(heating, fluxes::RadiativeFluxes, atmosphere::ColumnAtmosphere;
                   gravity, heat_capacity)

Convert interface fluxes to layer heating rates in K s^-1.

Conventions:
- vertical indexing is top-down;
- pressure interfaces increase downward;
- net flux is positive downward;
- positive heating means atmospheric warming.

For layer `k`, the heating rate is

```text
gravity / heat_capacity * (F_net[k] - F_net[k + 1]) / Δp[k]
```

where `F_net = longwave_down - longwave_up + shortwave_down - shortwave_up`.
"""
function heating_rates!(heating::AbstractVector,
                        fluxes::RadiativeFluxes,
                        atmosphere::ColumnAtmosphere;
                        gravity,
                        heat_capacity)
    p_interface = atmosphere.pressure_interfaces
    nlayers = length(atmosphere.temperature_layers)
    length(heating) == nlayers ||
        throw(DimensionMismatch("heating must have length nlayers"))
    length(p_interface) == nlayers + 1 ||
        throw(DimensionMismatch("pressure_interfaces must have length nlayers + 1"))
    length(fluxes.longwave_up) == nlayers + 1 ||
        throw(DimensionMismatch("longwave_up must have length nlayers + 1"))
    length(fluxes.longwave_down) == nlayers + 1 ||
        throw(DimensionMismatch("longwave_down must have length nlayers + 1"))
    length(fluxes.shortwave_up) == nlayers + 1 ||
        throw(DimensionMismatch("shortwave_up must have length nlayers + 1"))
    length(fluxes.shortwave_down) == nlayers + 1 ||
        throw(DimensionMismatch("shortwave_down must have length nlayers + 1"))

    FT = eltype(heating)
    g_over_cp = FT(gravity) / FT(heat_capacity)
    for k in 1:nlayers
        Δp = FT(p_interface[k + 1] - p_interface[k])
        Δp > zero(FT) || throw(ArgumentError("pressure_interfaces must increase downward"))
        net_top = FT(fluxes.longwave_down[k] - fluxes.longwave_up[k] +
                     fluxes.shortwave_down[k] - fluxes.shortwave_up[k])
        net_bottom = FT(fluxes.longwave_down[k + 1] - fluxes.longwave_up[k + 1] +
                        fluxes.shortwave_down[k + 1] - fluxes.shortwave_up[k + 1])
        heating[k] = g_over_cp * (net_top - net_bottom) / Δp
    end
    return heating
end

"""
    radiation_workspace(model, atmosphere; backend=nothing)

Construct reusable storage for repeated runtime calls. Host integrations may
also pass their own arrays/views directly to component methods.
"""
function radiation_workspace(model, atmosphere; backend = nothing)
    return nothing
end

"""
    radiation_workspace(rtm::RadiativeTransferColumn)

The existing single-column object is already a reusable workspace: it owns the
temperature-tendency vector, shortwave transmissivity scratch, and diagnostic
objects used by the analytic-band paths.
"""
radiation_workspace(rtm::RadiativeTransferColumn; backend = nothing) = rtm

"""
    radiative_heating!(rtm::RadiativeTransferColumn; reset=true, longwave=true, shortwave=true)

High-level analytic-band column update. This is a convenience wrapper around
the component calls [`solve_longwave!`](@ref) and [`solve_shortwave!`](@ref);
host models can keep using those lower-level calls directly when they own
their own vertical integrals or tendency insertion.
"""
function radiative_heating!(rtm::RadiativeTransferColumn;
                            reset::Bool = true,
                            longwave::Bool = true,
                            shortwave::Bool = true,
                            cloud_top_convective::Integer = length(rtm.profile.temperature) + 1)
    reset && reset!(rtm)
    longwave && solve_longwave!(rtm)
    shortwave && solve_shortwave!(rtm; cloud_top_convective)
    return rtm
end

"""
    heating_rates!(heating, rtm::RadiativeTransferColumn)

Copy the current column temperature tendency into `heating`. This method gives
the staged interface an allocation-free bridge to the existing analytic-band
workspace.
"""
function heating_rates!(heating::AbstractVector, rtm::RadiativeTransferColumn)
    length(heating) == length(rtm.temperature_tendency) ||
        throw(DimensionMismatch("heating must have length $(length(rtm.temperature_tendency))"))
    heating .= rtm.temperature_tendency
    return heating
end
