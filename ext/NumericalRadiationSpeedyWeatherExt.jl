module NumericalRadiationSpeedyWeatherExt

using NumericalRadiation
using SpeedyWeather
using Adapt

import NumericalRadiation: AtmosphereProfile, ColumnGrid, SurfaceState,
    PhysicalConstants, ThermodynamicConstants, LongwaveDiagnostics,
    ShortwaveDiagnostics, solve_longwave!, solve_shortwave!,
    AnalyticBandLongwave, TransparentShortwave, OneBandShortwave, OneBandGreyShortwave

# -----------------------------------------------------------------------------
# Longwave adapter
# -----------------------------------------------------------------------------

"""
    SpeedyAnalyticBandLongwave{NF} <: SpeedyWeather.AbstractLongwave

SpeedyWeather wrapper around [`NumericalRadiation.AnalyticBandLongwave`](@ref). 
Allows for setting the default CO₂ concentration [ppmv], if the model does not specify one.

Usage: 

```julia 
spectral_grid = SpectralGrid()
model = PrimitiveWetModel(spectral_grid; longwave_radiation = SpeedyAnalyticBandLongwave(spectral_grid; CO₂=280))
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

@inline function _speedy_physical_constants(model)
    NF = typeof(model.planet.gravity)
    return PhysicalConstants{NF}(
        gravity          = model.planet.gravity,
        heat_capacity    = model.atmosphere.heat_capacity,
        stefan_boltzmann = model.atmosphere.stefan_boltzmann,
        solar_constant   = model.planet.solar_constant,
    )
end

@inline function _speedy_column_geometry(model)
    geom = model.geometry
    return ColumnGrid(geom.σ_levels_full, geom.σ_levels_half, geom.σ_levels_thick)
end

function SpeedyWeather.parameterization!(ij::Integer, vars,
                                         rad::SpeedyAnalyticBandLongwave{NF},
                                         model) where NF
    nlayers = size(vars.grid.temperature_prev, 2)

    T  = @view vars.grid.temperature_prev[ij, :]
    q  = @view vars.grid.humidity_prev[ij, :]
    Φ  = @view vars.grid.geopotential[ij, :]
    pₛ = vars.grid.pressure_prev[ij]

    CO₂ = let prog = vars.prognostic
        if hasproperty(prog, :greenhouse_gases) && haskey(prog.greenhouse_gases, :co2)
            NF(prog.greenhouse_gases.co2[])
        else
            rad.default_CO₂
        end
    end

    profile  = AtmosphereProfile(temperature = T, humidity = q,
                                 geopotential = Φ, surface_pressure = pₛ, 
                                 CO₂ = CO₂)
                             
    geometry = _speedy_column_geometry(model)
    surface  = SurfaceState{NF}(
        sea_surface_temperature  = vars.prognostic.ocean.sea_surface_temperature[ij],
        land_surface_temperature = vars.prognostic.land.soil_temperature[ij, 1],
        land_fraction            = model.land_sea_mask.mask[ij],
    )
    constants = _speedy_physical_constants(model)
    diag = LongwaveDiagnostics{NF}()
    dTdt = @view vars.tendencies.grid.temperature[ij, :]

    solve_longwave!(dTdt, diag, rad.scheme, profile, geometry, surface, constants)

    vars.parameterizations.outgoing_longwave[ij]        = diag.outgoing_longwave
    vars.parameterizations.surface_longwave_down[ij]    = diag.surface_longwave_down
    vars.parameterizations.surface_longwave_up[ij]      = diag.surface_longwave_up
    vars.parameterizations.ocean.surface_longwave_up[ij] = diag.ocean_surface_longwave_up
    vars.parameterizations.land.surface_longwave_up[ij]  = diag.land_surface_longwave_up

    return nothing
end

end # module
