# Published ecCKD All-Sky Accuracy

Status: **passed**

Each row rewrites package candidate variables into the matched all-sky ecRad reference using the same Tripleclouds/aerosol configuration as the current all-sky IFS gate, but with model-specific ecCKD gas-optics and cloud-scattering mapping files.

| Model | LW | SW | Passed | TOA forcing | Surface forcing | LW TOA | LW surface | SW TOA | SW surface | Hard objective | Limiting metric |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| official ecCKD 1.0 32-LW x 32-SW all-sky climate model | 32 | 32 | true | 0.116188256575 W m^-2 | 0.0128536244561 W m^-2 | 0.111466467535 | 0.00646439036603 | 0.006874839391 | 0.00764450172312 | 0.387294188582 | `toa_forcing_abs_error` |
| official ecCKD 1.0/1.2 32-LW x 64-SW all-sky climate/window model | 32 | 64 | true | 0.231391178593 W m^-2 | 0.171693190487 W m^-2 | 0.111466467535 | 0.00646439036603 | 0.230988375443 | 0.171384584582 | 0.771303928644 | `toa_forcing_abs_error` |
| official ecCKD 1.0/1.4 32-LW x 96-SW all-sky climate/vfine model | 32 | 96 | true | 0.116158872896 W m^-2 | 0.0129957468071 W m^-2 | 0.111466467535 | 0.00646439036603 | 0.00681068526001 | 0.00774535229891 | 0.387196242987 | `toa_forcing_abs_error` |
| official ecCKD 1.2/1.4 64-LW x 32-SW all-sky narrow/rgb model | 64 | 32 | true | 0.111711794029 W m^-2 | 0.0126801196348 W m^-2 | 0.106990004989 | 0.00603254364034 | 0.006874839391 | 0.00764450172312 | 0.372372646763 | `toa_forcing_abs_error` |
| official ecCKD 1.2 64-LW x 64-SW all-sky climate model | 64 | 64 | true | 0.231170230724 W m^-2 | 0.17175512047 W m^-2 | 0.106990004989 | 0.00603254364034 | 0.230988375443 | 0.171384584582 | 0.770567435746 | `toa_forcing_abs_error` |
| official ecCKD 1.2/1.4 64-LW x 96-SW all-sky climate/vfine model | 64 | 96 | true | 0.11168241035 W m^-2 | 0.0127809702105 W m^-2 | 0.106990004989 | 0.00603254364034 | 0.00681068526001 | 0.00774535229891 | 0.372274701167 | `toa_forcing_abs_error` |

## Candidate Configuration

| Environment variable | Value |
|---|---|
| `RH_AEROSOL_OPTICS` | `true` |
| `RH_CANDIDATE_GAS_OPTICS` | `official_ecckd` |
| `RH_CLOUD_FRACTION_EXPONENT` | `1.0` |
| `RH_CLOUD_INHOM_OVERLAP_EXPONENT` | `2.0` |
| `RH_CLOUD_OVERLAP_LONGWAVE` | `true` |
| `RH_CLOUD_OVERLAP_LONGWAVE_RULE` | `tripleclouds_alpha` |
| `RH_CLOUD_OVERLAP_RULE` | `tripleclouds_alpha` |
| `RH_CLOUD_OVERLAP_SHORTWAVE` | `true` |
| `RH_CLOUD_OVERLAP_USE_CLOUDY_REGION_OPTICS` | `true` |
| `RH_CLOUD_SCATTERING_TABLE_OPTICS` | `true` |
| `RH_IFS_AEROSOL_TABLE_OPTICS` | `true` |
| `RH_LW_CLOUD_SCATTERING` | `true` |
