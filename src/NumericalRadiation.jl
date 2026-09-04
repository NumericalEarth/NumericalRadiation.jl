module NumericalRadiation

using Adapt
using Artifacts
using Dates
using DocStringExtensions
using LazyArtifacts

export AbstractRadiationScheme, AbstractLongwaveScheme, AbstractShortwaveScheme
export AbstractShortwaveTransmissivity, AbstractShortwaveClouds
export AbstractAtmosphericState, AbstractGasOpticsModel, AbstractCloudOpticsModel
export AbstractAerosolOpticsModel, AbstractRadiativeTransferSolver, AbstractRadiationBackend

export AtmosphereProfile, ColumnGrid, SurfaceState
export ColumnAtmosphere, RadiativeFluxes
export LongwaveOptics, CloudlessLongwave, LongwaveBoundaryConditions
export LongwaveCloudOverlapOptics, CloudOverlapLongwave
export ShortwaveOptics, CloudlessShortwave, ShortwaveBoundaryConditions
export ShortwaveCloudOverlapOptics, CloudOverlapShortwave
export CloudOptics, CloudyRegionCloudOptics
export LayerCloudOpticsModel, LayerLiquidIceCloudOpticsModel
export add_cloud_optical_depths!, add_mapped_cloud_scattering!
export AerosolOptics, LayerAerosolOpticsModel, add_aerosol_optical_depths!
export EcCKDGasOpticsModel, EcCKDTabulatedGasOpticsModel
export EcCKDDefinition, EcCKDSchemaSummary, EcCKDModelSpec
export read_ecckd_definition, summarize_ecckd_definition, validate_ecckd_definition
export read_ecckd_tabulated_gas_optics, read_reference_ecckd_gas_optics
export surface_longwave_emission
export reference_ecckd_model_inventory, reference_ecckd_definition_path,
       reference_ecckd_definition_paths, reference_ecckd_model_specs,
       reference_ecckd_model_spec, ecrad_data_path, ecckd_source_path
export CloudScatteringTable, EcCKDSpectralMapping
export read_cloud_scattering_table, read_ecckd_spectral_mapping
export cloud_scattering_properties, cloud_scattering_gpoint_properties
export RadiationErrorMetrics, RadiationThresholds, radiation_error_metrics,
       radiative_flux_error_metrics, passes_thresholds
export PhysicalConstants, ThermodynamicConstants, default_earth_constants

export LongwaveDiagnostics, ShortwaveDiagnostics

export planck_wavenumber

export AnalyticBandLongwave
export h2o_line_kappa_ref, h2o_cont_kappa_ref, co2_kappa_ref
export williams_delta_tau

export NoClouds, DiagnosticClouds
export ConstantShortwaveTransmissivity, BackgroundShortwaveTransmissivity
export OneBandShortwave, OneBandShortwaveRadiativeTransfer
export saturation_humidity

export optical_properties!, cloud_optical_properties!, cloudy_region_optical_properties!
export aerosol_optical_properties!
export radiative_fluxes!, heating_rates!, radiative_heating!, radiation_workspace
export solve_longwave!, solve_shortwave!

export RadiativeTransferColumn, reset!

export solar_declination, equation_of_time, cosine_solar_zenith

include("abstract_types.jl")
include("column_views.jl")
include("flux_to_tendency.jl")
include("planck.jl")
include("zenith.jl")
include("longwave/williams_absorption.jl")
include("longwave/williams_longwave.jl")
include("shortwave/clouds.jl")
include("shortwave/transmissivity.jl")
include("shortwave/transparent_shortwave.jl")
include("shortwave/one_band_shortwave.jl")
include("radiative_transfer_column.jl")
include("runtime_interfaces.jl")
include("io/ecckd_definition.jl")
include("io/cloud_scattering.jl")
include("solvers/cloudless_longwave.jl")
include("solvers/cloudless_shortwave.jl")
include("solvers/cloud_optics.jl")
include("solvers/cloud_overlap_shortwave.jl")
include("solvers/cloud_overlap_longwave.jl")
include("gas_optics/ecckd_forward.jl")
include("metrics.jl")

end # module
