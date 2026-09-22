module NumericalRadiationSpeedyWeatherExt

using NumericalRadiation
using SpeedyWeather
using Adapt
using DocStringExtensions

import NumericalRadiation: AtmosphereProfile, ColumnGrid, SurfaceState,
    PhysicalConstants, LongwaveDiagnostics, solve_longwave!, AnalyticBandLongwave
import NumericalRadiation: EcCKDTabulatedGasOpticsModel, ColumnAtmosphere, RadiativeFluxes,
    LongwaveOptics, ShortwaveOptics, CloudlessLongwave, CloudlessShortwave,
    ShortwaveColumnScratch, TabulatedSurfaceEmission, LongwaveBoundaryConditions,
    ShortwaveBoundaryConditions, optical_properties!, radiative_fluxes!,
    read_reference_ecckd_gas_optics

include("analytic_band_longwave.jl")   # SpeedyAnalyticBandLongwave: analytic-band longwave as Radiation(; longwave)
include("ecckd_radiation.jl")          # EcCKDRadiation: clear-sky ecCKD, both streams in one component

end # module
