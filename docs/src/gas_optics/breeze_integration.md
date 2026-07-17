# Breeze Integration

NumericalRadiation provides the staged radiation pieces; Breeze owns the model
time stepping, grid layout, and GPU/CPU execution strategy. A Breeze coupling
should keep radiation setup separate from each radiation update.

## Setup in NumericalRadiation

During host-model construction:

1. choose an ecCKD model with [`official_ecckd_model_spec`](@ref),
2. load the gas-optics model with [`read_official_ecckd_gas_optics`](@ref),
3. allocate longwave, shortwave, cloud, aerosol, flux, and heating work arrays,
4. store those objects in the Breeze radiation state.

The package-level column example uses the same setup pattern:

```julia
using NumericalRadiation
using NCDatasets

spec = official_ecckd_model_spec("32x32")
gas_optics = read_official_ecckd_gas_optics(spec;
    gas_names = (:h2o, :co2),
    h2o_mole_fraction = 0.005,
)
```

## Breeze Constructor Pattern

The Breeze extension pattern is:

```julia
using Breeze
using NumericalRadiation
using NCDatasets

gas_optics = read_official_ecckd_gas_optics("64x32";
    gas_names = (:h2o, :co2),
    h2o_mole_fraction = 0.005,
)

radiation = RadiativeTransferModel(
    grid,
    RadiativeHeatingOptics(),
    constants;
    gas_optics,
    surface_temperature = 300,
    surface_albedo = 0.1,
    surface_emissivity = 1,
    schedule = IterationInterval(1),
)
```

`IterationInterval(1)` means radiation is updated every model time step. That
is the right starting point for stability and performance studies; after a
coupled simulation is validated, the interval can be increased and compared
against the every-step baseline.

## Update Contract

Each radiation update should follow the staged order:

```julia
optical_properties!(longwave, shortwave, gas_optics, atmosphere)
cloud_optical_properties!(cloud, cloud_model, atmosphere)
aerosol_optical_properties!(aerosol, aerosol_model, atmosphere)
radiative_fluxes!(fluxes, longwave_solver, longwave, atmosphere, longwave_boundary)
radiative_fluxes!(fluxes, shortwave_solver, shortwave, atmosphere, shortwave_boundary)
heating_rates!(heating, fluxes, atmosphere; gravity, heat_capacity)
```

The exact extension implementation lives in Breeze, not in this repository.
The important interface contract is that Breeze can build a
[`ColumnAtmosphere`](@ref)-compatible view for each column, fill caller-owned
optical arrays, and add the returned heating tendency to its thermodynamic
state.

## Performance Checklist

For three-dimensional simulations, avoid per-step allocation:

- keep gas-optics tables resident after setup,
- reuse optical-property and flux work arrays,
- evaluate columns in a layout that is contiguous for the host backend,
- call radiation less frequently than dynamics only after validating the
  coupled simulation with radiation every time step,
- benchmark each ecCKD pair because g-point count controls runtime cost.

Shared-memory or tiled GPU kernels are Breeze-side optimizations. They should
preserve the same staged interface so model selection, validation, and docs
examples remain independent of the host backend.
