"""
$(TYPEDEF)

Generic column atmosphere container for the staged radiation interface.

The existing analytic-band solvers use [`AtmosphereProfile`](@ref),
[`ColumnGrid`](@ref), and [`SurfaceState`](@ref) directly. `ColumnAtmosphere`
is a host-model-facing container for newer gas-optics and solver paths where
layer/interface pressure and temperature arrays need to be carried together.

Fields:
- `pressure_layers`: Layer pressures, indexed top-down
- `pressure_interfaces`: Interface pressures, indexed top-down
- `temperature_layers`: Layer temperatures, indexed top-down
- `temperature_interfaces`: Interface temperatures, indexed top-down
- `gases`: Symbol-keyed gas concentrations or host-model property view
- `surface`: Lower-boundary state
- `geometry`: Geometry, solar angles, or host-model geometry view
- The four arrays may have different array types (host-model views into arrays of
  different shape); `FT` is the element type of `temperature_layers`.
- `constants`: Physical constants of the host ([`PhysicalConstants`](@ref) in the column's
  element type by default): gravity and the dry-air molar mass for the hydrostatic layer air
  amounts of `optical_properties!`, gravity and the heat capacity for
  [`heating_rates!`](@ref)
"""
struct ColumnAtmosphere{FT, PL, PI, TL, TI, G, S, Geo, C} <: AbstractAtmosphericState
    pressure_layers::PL
    pressure_interfaces::PI
    temperature_layers::TL
    temperature_interfaces::TI
    gases::G
    surface::S
    geometry::Geo
    constants::C
end

function ColumnAtmosphere(; pressure_layers::PL,
                            pressure_interfaces::PI,
                            temperature_layers::TL,
                            temperature_interfaces::TI,
                            gases::G,
                            surface::S,
                            geometry::Geo,
                            constants::C = PhysicalConstants(float(eltype(temperature_layers)))) where {PL, PI, TL, TI, G, S, Geo, C}
    FT = eltype(temperature_layers)
    return ColumnAtmosphere{FT, PL, PI, TL, TI, G, S, Geo, C}(
        pressure_layers,
        pressure_interfaces,
        temperature_layers,
        temperature_interfaces,
        gases,
        surface,
        geometry,
        constants,
    )
end

Base.eltype(::ColumnAtmosphere{FT}) where FT = FT

"""
$(TYPEDEF)

Flux container for component radiation APIs.

Arrays are caller-owned and may be package work arrays, host-model views, or
device arrays. Interface flux arrays should have one more vertical point than
layer-centered heating arrays.

Fields:
- `longwave_up`: Upwelling longwave flux at interfaces
- `longwave_down`: Downwelling longwave flux at interfaces
- `shortwave_up`: Upwelling shortwave flux at interfaces
- `shortwave_down`: Downwelling shortwave flux at interfaces
"""
struct RadiativeFluxes{FT, A}
    longwave_up::A
    longwave_down::A
    shortwave_up::A
    shortwave_down::A
end

function RadiativeFluxes(; longwave_up::A, longwave_down::A, shortwave_up::A, shortwave_down::A) where A
    FT = eltype(longwave_up)
    return RadiativeFluxes{FT, A}(longwave_up, longwave_down, shortwave_up, shortwave_down)
end

Base.eltype(::RadiativeFluxes{FT}) where FT = FT

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
                   gravity = atmosphere.constants.gravity,
                   heat_capacity = atmosphere.constants.heat_capacity)

Convert interface fluxes to layer heating rates in K s^-1. `gravity` and
`heat_capacity` default to the column's [`PhysicalConstants`](@ref); pass them
to override.

Conventions:
- vertical indexing is top-down;
- pressure interfaces increase downward;
- net flux is positive downward;
- positive heating means atmospheric warming.

For layer `k`, the heating rate is

```text
Ṫ[k] = g / cᵖ (ℐ[k] - ℐ[k + 1]) / Δp[k]
```

where `ℐ = ℐꜜˡʷ - ℐꜛˡʷ + ℐꜜˢʷ - ℐꜛˢʷ` is the net downward flux
(`longwave_down - longwave_up + shortwave_down - shortwave_up`), and `g` and
`cᵖ` are `gravity` and `heat_capacity`.
"""
function heating_rates!(heating::AbstractVector,
                        fluxes::RadiativeFluxes,
                        atmosphere::ColumnAtmosphere;
                        gravity = atmosphere.constants.gravity,
                        heat_capacity = atmosphere.constants.heat_capacity)
    pᵢ = atmosphere.pressure_interfaces
    Nz = length(atmosphere.temperature_layers)
    length(heating) == Nz || throw(DimensionMismatch("heating must have length Nz"))
    length(pᵢ) == Nz + 1 || throw(DimensionMismatch("pressure_interfaces must have length Nz + 1"))
    length(fluxes.longwave_up) == Nz + 1 || throw(DimensionMismatch("longwave_up must have length Nz + 1"))
    length(fluxes.longwave_down) == Nz + 1 || throw(DimensionMismatch("longwave_down must have length Nz + 1"))
    length(fluxes.shortwave_up) == Nz + 1 || throw(DimensionMismatch("shortwave_up must have length Nz + 1"))
    length(fluxes.shortwave_down) == Nz + 1 || throw(DimensionMismatch("shortwave_down must have length Nz + 1"))

    FT = eltype(heating)
    g = FT(gravity)
    cᵖ = FT(heat_capacity)
    for k in 1:Nz
        Δp = FT(pᵢ[k + 1] - pᵢ[k])
        Δp > zero(FT) || throw(ArgumentError("pressure_interfaces must increase downward"))
        ℐₖ = FT(fluxes.longwave_down[k] - fluxes.longwave_up[k] +
                fluxes.shortwave_down[k] - fluxes.shortwave_up[k])
        ℐₖ₊₁ = FT(fluxes.longwave_down[k + 1] - fluxes.longwave_up[k + 1] +
                  fluxes.shortwave_down[k + 1] - fluxes.shortwave_up[k + 1])
        heating[k] = g / cᵖ * (ℐₖ - ℐₖ₊₁) / Δp
    end
    return heating
end

"""
    radiation_workspace(model, atmosphere; backend=nothing)

Construct reusable storage for repeated runtime calls. Host integrations may
also pass their own arrays/views directly to component methods.
"""
function radiation_workspace(model, atmosphere; backend=nothing)
    return nothing
end

"""
    radiation_workspace(column::RadiativeTransferColumn)

The existing single-column object is already a reusable workspace: it owns the
temperature-tendency vector, shortwave transmissivity scratch, and diagnostic
objects used by the analytic-band paths.
"""
radiation_workspace(column::RadiativeTransferColumn; backend=nothing) = column

"""
    radiative_heating!(column::RadiativeTransferColumn; reset=true, longwave=true, shortwave=true)

High-level analytic-band column update. This is a convenience wrapper around
the component calls [`solve_longwave!`](@ref) and [`solve_shortwave!`](@ref);
host models can keep using those lower-level calls directly when they own
their own vertical integrals or tendency insertion.
"""
function radiative_heating!(column::RadiativeTransferColumn;
                            reset::Bool = true,
                            longwave::Bool = true,
                            shortwave::Bool = true,
                            cloud_top_convective::Integer = length(column.profile.temperature) + 1)
    reset && reset!(column)
    longwave && solve_longwave!(column)
    shortwave && solve_shortwave!(column; cloud_top_convective)
    return column
end

"""
    heating_rates!(heating, column::RadiativeTransferColumn)

Copy the current column temperature tendency into `heating`. This method gives
the staged interface an allocation-free bridge to the existing analytic-band
workspace.
"""
function heating_rates!(heating::AbstractVector, column::RadiativeTransferColumn)
    length(heating) == length(column.temperature_tendency) ||
        throw(DimensionMismatch("heating must have length $(length(column.temperature_tendency))"))
    heating .= column.temperature_tendency
    return heating
end
