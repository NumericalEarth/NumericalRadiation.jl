# SpeedyAnalyticBandLongwave: NumericalRadiation's analytic-band longwave scheme as a
# SpeedyWeather longwave component, to be used as Radiation(spectral_grid; longwave = ...).

"""
    SpeedyAnalyticBandLongwave{NF} <: SpeedyWeather.AbstractLongwave

SpeedyWeather wrapper around [`NumericalRadiation.AnalyticBandLongwave`](@ref).
Allows for setting the default CO₂ concentration [ppmv], used when the model has
no `greenhouse_gases` component with a `co2` entry.

Usage:

```julia
spectral_grid = SpectralGrid()
longwave = SpeedyAnalyticBandLongwave(spectral_grid; CO₂ = 280)
model = PrimitiveWetModel(spectral_grid; radiation = Radiation(spectral_grid; longwave))
```
"""
struct SpeedyAnalyticBandLongwave{NF} <: SpeedyWeather.AbstractLongwave
    scheme::AnalyticBandLongwave{NF}
    default_CO₂::NF
end

Adapt.@adapt_structure SpeedyAnalyticBandLongwave

function SpeedyAnalyticBandLongwave(SG::SpeedyWeather.SpectralGrid; CO₂ = 280, kwargs...)
    return SpeedyAnalyticBandLongwave(AnalyticBandLongwave{SG.NF}(; kwargs...), SG.NF(CO₂))
end

SpeedyWeather.initialize!(::SpeedyAnalyticBandLongwave, ::SpeedyWeather.PrimitiveEquation) = nothing

# Re-export under the PR's original name for drop-in compatibility.
const SimpleSpectralLongwave = SpeedyAnalyticBandLongwave

# Every constant comes from the SpeedyWeather model, so the radiation runs
# with the host's values; SpeedyWeather stores molar masses in g mol⁻¹.
@inline function speedy_physical_constants(model)
    NF = typeof(model.planet.gravity)
    (; planet, atmosphere) = model
    return PhysicalConstants{NF}(
        gravity                = planet.gravity,
        heat_capacity          = atmosphere.heat_capacity,
        stefan_boltzmann       = atmosphere.stefan_boltzmann,
        solar_constant         = planet.solar_constant,
        dry_air_molar_mass     = atmosphere.mol_mass_dry_air / 1000,
        water_molar_mass       = atmosphere.mol_mass_vapor / 1000,
        dry_air_gas_constant   = atmosphere.R_dry,
        universal_gas_constant = atmosphere.R_gas,
    )
end

@inline function speedy_column_geometry(model)
    geom = model.geometry
    return ColumnGrid(geom.σ_levels_full, geom.σ_levels_half, geom.σ_levels_thick)
end

Base.@propagate_inbounds function SpeedyWeather.parameterization!(ij, variables,
                                                                   radiation::SpeedyAnalyticBandLongwave{NF},
                                                                   model) where NF
    time_stepping = model.time_stepping
    T_all    = SpeedyWeather.get_prognostic_step(variables.grid.temperature, time_stepping, radiation)
    q_all    = SpeedyWeather.get_prognostic_step(variables.grid.humidity, time_stepping, radiation)
    dTdt_all = SpeedyWeather.get_tendency_step(variables.tendencies.grid.temperature, time_stepping, radiation)
    sst_all  = SpeedyWeather.get_prognostic_step(variables.prognostic.ocean.sea_surface_temperature,
                                                 time_stepping, radiation)

    T    = @view T_all[ij, :]
    q    = @view q_all[ij, :]
    Φ    = @view variables.dynamics.geopotential[ij, :]
    temperature_tendency = @view dTdt_all[ij, :]
    pˢ   = variables.parameterizations.surface_pressure[ij]            # [Pa]

    CO₂ = let prog = variables.prognostic
        if hasproperty(prog, :greenhouse_gases) && haskey(prog.greenhouse_gases, :co2)
            NF(prog.greenhouse_gases.co2[])
        else
            radiation.default_CO₂
        end
    end

    profile  = AtmosphereProfile(temperature = T, humidity = q,
                                 geopotential = Φ, surface_pressure = pˢ,
                                 CO₂ = CO₂)

    geometry = speedy_column_geometry(model)
    surface  = SurfaceState{NF}(
        sea_surface_temperature  = sst_all[ij],
        land_surface_temperature = variables.prognostic.land.soil_temperature[ij, 1],
        land_fraction            = model.land_sea_mask.land_fraction[ij],
    )
    constants = speedy_physical_constants(model)
    diagnostics = LongwaveDiagnostics{NF}()

    solve_longwave!(temperature_tendency, diagnostics, radiation.scheme, profile, geometry, surface, constants)

    variables.parameterizations.outgoing_longwave[ij]         = diagnostics.outgoing_longwave
    variables.parameterizations.surface_longwave_down[ij]     = diagnostics.surface_longwave_down
    variables.parameterizations.surface_longwave_up[ij]       = diagnostics.surface_longwave_up
    variables.parameterizations.ocean.surface_longwave_up[ij] = diagnostics.ocean_surface_longwave_up
    variables.parameterizations.land.surface_longwave_up[ij]  = diagnostics.land_surface_longwave_up

    return nothing
end
