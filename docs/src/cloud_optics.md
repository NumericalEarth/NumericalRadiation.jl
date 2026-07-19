# Cloud and aerosol optics

Cloud and aerosol optics are separate stages: they fill their own containers,
which are then composed onto gas optical properties before the solver runs.
This keeps gas optics, cloud optics, and solvers independently testable.

## Containers

- [`CloudOpticalProperties`](@ref) stores grid-mean layer cloud optical depths:
  longwave absorption, shortwave absorption, shortwave scattering, and the
  shortwave scattering asymmetry factor.
- [`CloudyRegionCloudOpticalProperties`](@ref) stores the same channels for the
  *cloudy region only*, with `cloud_fraction` and `overlap_parameter` carried
  separately. This matches the all-sky solver convention: cloud cover must not
  be encoded by weakening in-cloud optical depth.
- [`AerosolOpticalProperties`](@ref) mirrors the cloud container for aerosols.

## Layer models

[`LayerCloudOpticsModel`](@ref) converts a condensed water path `CWP`
(kg m⁻²; scalar, per-layer vector, or read from
`atmosphere.cloud_water_path`) with mass absorption/extinction coefficients
(m² kg⁻¹):

```math
\tau_\mathrm{lw} = \kappa_\mathrm{lw}\,\mathrm{CWP}, \qquad
\tau_\mathrm{sw,abs} = (1 - \omega_0)\,\kappa_\mathrm{sw}\,\mathrm{CWP}, \qquad
\tau_\mathrm{sw,scat} = \omega_0\,\kappa_\mathrm{sw}\,\mathrm{CWP}.
```

[`LayerLiquidIceCloudOpticsModel`](@ref) keeps liquid water path, ice water
path, and cloud fraction separate, with per-phase coefficients, albedos, and
asymmetry factors. It fills either container:

- [`cloud_optical_properties!`](@ref) returns grid-mean optical depth (scaled
  by cloud fraction raised to `cloud_fraction_exponent`) — the shortcut for
  homogeneous-column smoke tests;
- [`cloudy_region_optical_properties!`](@ref) fills cloudy-region optical
  depths without cloud-fraction scaling, plus the fraction and overlap fields,
  for the all-sky solvers.

[`LayerAerosolOpticsModel`](@ref) is the aerosol analogue driven by
`aerosol_path`.

## Composition onto gas optics

[`add_cloud_optical_depths!`](@ref) and [`add_aerosol_optical_depths!`](@ref)
add the layer absorption channels to the gas absorption arrays (broadcast
across g-points when the gas optics are spectral) and mix the scattering
channel into the shortwave scattering optical depth, updating the asymmetry
factor as a scattering-optical-depth-weighted mean. After composition, the
shortwave solver sees a single absorption/scattering/asymmetry triple per
layer and g-point, and needs no cloud-specific logic.

## Scattering tables

For spectrally resolved cloud optics, the package reads ecRad's droplet and
ice scattering tables and maps them onto ecCKD g-point grids:

- [`CloudScatteringTable`](@ref) stores mass extinction, single-scattering
  albedo, and asymmetry factor as functions of wavenumber (cm⁻¹) and effective
  radius (m), read by [`read_cloud_scattering_table`](@ref) (requires the
  NCDatasets extension). The official files are the Mie liquid-droplet and
  Baum ice tables from the pinned ecRad data artifact.
- [`EcCKDSpectralMapping`](@ref) stores the resolved spectral intervals and
  the `gpoint_fraction` matrix from a CKD-definition file — ecCKD's fixed
  wavenumber-to-g mapping — read by [`read_ecckd_spectral_mapping`](@ref).
  Interval weights are the solar spectral irradiance (shortwave) or a Planck
  weight (longwave).

[`cloud_scattering_properties`](@ref) interpolates a table linearly in
effective radius at one wavenumber index.
[`cloud_scattering_gpoint_properties`](@ref) produces per-g-point mass
extinction, single-scattering albedo, and asymmetry: extinction is
weight-averaged, single-scattering albedo extinction-weighted, and asymmetry
scattering-weighted. Two mapping methods are available: `:midpoint` samples
the nearest table wavenumber at each interval midpoint, while `:ecrad`
reproduces ecRad's spectral averaging matrix; optional delta-Eddington and
optically-thick averaging follow ecRad's conventions.

[`add_mapped_cloud_scattering!`](@ref) then puts per-g-point liquid and ice
scattering into `(ng, nlayers)` shortwave optical properties from layer
liquid/ice water paths and cloud fraction, with optional delta-Eddington
forward-scattering scaling.
