# ecCKD Files

The core package defines dependency-free ecCKD schema objects:

- [`EcCKDDefinition`](@ref) stores model name, version, dimensions, variables,
  and global attributes.
- [`summarize_ecckd_definition`](@ref) extracts benchmark/report metadata such
  as LW/SW band counts, g-point counts, gases, pressure/temperature grid sizes,
  and source/Rayleigh table availability.
- [`validate_ecckd_definition`](@ref) checks required dimensions and variable
  groups before any runtime gas-optics model is constructed.

NetCDF-backed loading lives in `NumericalRadiationNCDatasetsExt`, so
`NCDatasets.jl` is an optional dependency rather than a hard dependency of the
standalone runtime package. Load `NCDatasets` before calling
`read_ecckd_definition(path::String)`:

```julia
using NumericalRadiation
using NCDatasets

definition = read_ecckd_definition("ecckd-definition.nc")
summary = summarize_ecckd_definition(definition)
validate_ecckd_definition(definition)
```

Without `NCDatasets`, path-based loading throws a clear error while the core
schema types remain available.

## Official ecCKD Data

The package resolves official ecCKD definition files through
`Artifacts.toml`. The pinned `ecrad_data` artifact points at the upstream ecRad
source archive used by the validation suite. Users can override this with
`RH_ECRAD_DATA_PATH` when they already have an ecRad checkout or unpacked data
directory.

```julia
using NumericalRadiation

official_ecckd_model_inventory()
spec = official_ecckd_model_spec("32x32")
paths = official_ecckd_definition_paths(spec)
paths.longwave
paths.shortwave
```

Resolution order is:

1. `RH_ECRAD_DATA_PATH`
2. lazy `ecrad_data` artifact
3. a local developer checkout at `validation/external/ecrad` (the layout used
   by the `validation-platform` branch)

Individual files can be addressed by filename or by stable keys:
`:longwave_32`, `:shortwave_32`, `:longwave_64`, `:shortwave_64`, and
`:shortwave_96`.

Published model pairs can be selected with compact names:

```julia
official_ecckd_model_specs()
read_official_ecckd_gas_optics("64x32";
    names = (:composite, :h2o, :co2),
    h2o_mole_fraction = 0.005,
)
```

Path lookup with `require=false` is non-mutating: it checks environment paths,
installed artifacts, and local validation data without downloading the lazy
artifact. Use the default `require=true` in production workflows when the
official files should be downloaded automatically if needed.

## Official ecCKD Source

The package also resolves the official ecCKD source tree through the lazy
`ecckd_source` artifact. This is the small C++/shell source release containing
the original `optimize_lut`, cost-function, and training-script machinery. It
does not include the large CKDMIP line-by-line spectral absorption database.

```julia
using NumericalRadiation

source = ecckd_source_path()
joinpath(source, "src", "ecckd", "optimize_lut.cpp")
```

Resolution order is:

1. `RH_ECCKD_SOURCE_PATH`
2. lazy `ecckd_source` artifact
3. a local developer checkout at `validation/external/ecckd` (the layout used
   by the `validation-platform` branch)

Exact reconstruction of the published ecCKD training problem still requires the
CKDMIP line-by-line training database in addition to this source tree.
