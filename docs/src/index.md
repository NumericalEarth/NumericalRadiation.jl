# NumericalRadiation.jl

NumericalRadiation.jl is a standalone, GPU-oriented atmospheric radiation and
gas-optics library compatible with ECMWF's ecRad/ecCKD data. It ingests
official ecCKD CKD-definition files into typed look-up tables, evaluates
g-point optical depths in a streaming, allocation-free runtime path, and
solves clear-sky and all-sky two-stream column transport. It also bundles two
analytic-band column schemes for intermediate-complexity models: the Williams
(2026) 41-wavenumber clear-sky longwave and a SPEEDY-style one-band shortwave
with diagnostic clouds.

## Installation

```julia
using Pkg
Pkg.add(url = "https://github.com/NumericalEarth/AnalyticBandRadiation.jl")
```

## Quickstart

Run a clear-sky column with an official ecCKD model (the CKD-definition files
resolve through lazy artifacts on first use; arrays are ordered top-to-bottom,
with pressure increasing downward, and gas entries are layer column amounts in
mol m⁻²):

```julia
using NumericalRadiation
using NCDatasets   # activates the NetCDF reader extension

gas_optics = read_official_ecckd_gas_optics("32x32"; gas_names = (:h2o, :co2))

nlayers = 24
p_i = collect(range(10_000.0, 100_000.0; length = nlayers + 1))  # Pa, TOA first
air = diff(p_i) ./ (9.80665 * 0.0289647)                          # mol m⁻²
atmosphere = ColumnAtmosphere(;
    pressure_layers = 0.5 .* (p_i[1:end-1] .+ p_i[2:end]),
    pressure_interfaces = p_i,
    temperature_layers = collect(range(220.0, 295.0; length = nlayers)),
    temperature_interfaces = collect(range(215.0, 300.0; length = nlayers + 1)),
    gases = (composite = air, h2o = 0.005 .* air, co2 = 420.0e-6 .* air),
    surface = (temperature = 300.0,),
    geometry = (cos_zenith = 0.55,))

ng_lw, ng_sw = length(gas_optics.longwave_weights), length(gas_optics.shortwave_weights)
longwave = LongwaveOpticalProperties(zeros(ng_lw, nlayers), zeros(ng_lw, nlayers);
                                     source_top = zeros(ng_lw, nlayers),
                                     source_bottom = zeros(ng_lw, nlayers),
                                     weights = zeros(ng_lw))
shortwave = ShortwaveOpticalProperties(zeros(ng_sw, nlayers); weights = zeros(ng_sw))
fluxes = RadiativeFluxes(longwave_up = zeros(nlayers + 1),
                         longwave_down = zeros(nlayers + 1),
                         shortwave_up = zeros(nlayers + 1),
                         shortwave_down = zeros(nlayers + 1))

optical_properties!(longwave, shortwave, gas_optics, atmosphere)
radiative_fluxes!(fluxes, CloudlessLongwave(), longwave, atmosphere,
                  LongwaveBoundaryConditions(surface_longwave_up = 5.67e-8 * 300.0^4))

heating = zeros(nlayers)
heating_rates!(heating, fluxes, atmosphere; gravity = 9.80665, heat_capacity = 1004.0)
```

The complete script, including the shortwave leg, is
`examples/ecckd_column.jl`.

## Where to go next

- [Design and acceptance criteria](design.md) — what the package is and the
  architecture rules it keeps.
- Tutorials: the [staged ecCKD column](generated/02_staged_ecckd_column.md)
  and [single-column radiation](single_column.md) examples.
- [Gas optics](gas_optics/ecckd_files.md) — ecCKD files, model selection, the
  runtime workflow, and training/recovery.
- [Column solvers](solvers.md) and [cloud and aerosol optics](cloud_optics.md)
  — the solver stack; [notation](notation.md) for symbol conventions.
- [API reference](api.md) — the exported interface, by subsystem.
- [Validation](validation.md) — tests, the validation platform, and reference
  data.
