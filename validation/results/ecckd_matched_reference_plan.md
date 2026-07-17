# ecCKD Matched Reference Plan

Status: **ready_for_published_parity_validation**

Published 64/96 ecCKD parity cannot be established against the current 32-g package-native references because spectral boundary arrays do not match the target g-point grids; the projection diagnostic reduces SW surface forcing but still fails TOA forcing and invalidates LW boundaries.

- Missing matched reference cases: 0
- Existing ecRad output files inspected: 26

## Required Matched References

| Case | LW | SW | Present | Boundary matches | Output |
|---|---:|---:|---:|---:|---|
| ecckd_32x64_clear_sky_tropical_column | 32 | 64 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_32x64_clear_sky_tropical_column.nc` |
| ecckd_32x96_clear_sky_tropical_column | 32 | 96 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_32x96_clear_sky_tropical_column.nc` |
| ecckd_64x32_clear_sky_tropical_column | 64 | 32 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_64x32_clear_sky_tropical_column.nc` |
| ecckd_64x64_clear_sky_tropical_column | 64 | 64 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_64x64_clear_sky_tropical_column.nc` |
| ecckd_64x96_clear_sky_tropical_column | 64 | 96 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_64x96_clear_sky_tropical_column.nc` |
| ecckd_32x64_rcemip_style_column_subset | 32 | 64 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_32x64_rcemip_style_column_subset.nc` |
| ecckd_32x96_rcemip_style_column_subset | 32 | 96 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_32x96_rcemip_style_column_subset.nc` |
| ecckd_64x32_rcemip_style_column_subset | 64 | 32 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_64x32_rcemip_style_column_subset.nc` |
| ecckd_64x64_rcemip_style_column_subset | 64 | 64 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_64x64_rcemip_style_column_subset.nc` |
| ecckd_64x96_rcemip_style_column_subset | 64 | 96 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_64x96_rcemip_style_column_subset.nc` |
| ecckd_32x32_all_sky_tropical_column | 32 | 32 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_all_sky_tropical_column.nc` |
| ecckd_32x64_all_sky_tropical_column | 32 | 64 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_32x64_all_sky_tropical_column.nc` |
| ecckd_32x96_all_sky_tropical_column | 32 | 96 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_32x96_all_sky_tropical_column.nc` |
| ecckd_64x32_all_sky_tropical_column | 64 | 32 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_64x32_all_sky_tropical_column.nc` |
| ecckd_64x64_all_sky_tropical_column | 64 | 64 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_64x64_all_sky_tropical_column.nc` |
| ecckd_64x96_all_sky_tropical_column | 64 | 96 | true | true | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/reference/ecrad/ecckd_64x96_all_sky_tropical_column.nc` |

## Required ecRad Namelist Overrides

Each listed case requires the appropriate ecRad ecCKD template plus these case-specific gas-optics override files:

| Case | LW override | SW override |
|---|---|---|
| ecckd_32x64_clear_sky_tropical_column | `gas_optics_lw_override_file_name="ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.2_sw_climate_window-64b_ckd-definition.nc"` |
| ecckd_32x96_clear_sky_tropical_column | `gas_optics_lw_override_file_name="ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc"` |
| ecckd_64x32_clear_sky_tropical_column | `gas_optics_lw_override_file_name="ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc"` |
| ecckd_64x64_clear_sky_tropical_column | `gas_optics_lw_override_file_name="ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.2_sw_climate_window-64b_ckd-definition.nc"` |
| ecckd_64x96_clear_sky_tropical_column | `gas_optics_lw_override_file_name="ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc"` |
| ecckd_32x64_rcemip_style_column_subset | `gas_optics_lw_override_file_name="ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.2_sw_climate_window-64b_ckd-definition.nc"` |
| ecckd_32x96_rcemip_style_column_subset | `gas_optics_lw_override_file_name="ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc"` |
| ecckd_64x32_rcemip_style_column_subset | `gas_optics_lw_override_file_name="ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc"` |
| ecckd_64x64_rcemip_style_column_subset | `gas_optics_lw_override_file_name="ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.2_sw_climate_window-64b_ckd-definition.nc"` |
| ecckd_64x96_rcemip_style_column_subset | `gas_optics_lw_override_file_name="ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc"` |
| ecckd_32x32_all_sky_tropical_column | `gas_optics_lw_override_file_name="ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc"` |
| ecckd_32x64_all_sky_tropical_column | `gas_optics_lw_override_file_name="ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.2_sw_climate_window-64b_ckd-definition.nc"` |
| ecckd_32x96_all_sky_tropical_column | `gas_optics_lw_override_file_name="ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc"` |
| ecckd_64x32_all_sky_tropical_column | `gas_optics_lw_override_file_name="ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc"` |
| ecckd_64x64_all_sky_tropical_column | `gas_optics_lw_override_file_name="ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.2_sw_climate_window-64b_ckd-definition.nc"` |
| ecckd_64x96_all_sky_tropical_column | `gas_optics_lw_override_file_name="ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc"` | `gas_optics_sw_override_file_name="ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc"` |

## Next Step

Run the published-model accuracy, Pareto, and recovery-audit validations against the matched reference products; all required matched reference files are present with compatible spectral boundary arrays.
