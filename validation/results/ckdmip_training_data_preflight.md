# CKDMIP Training Data Preflight

Status: **incomplete_ckdmip_upstream_data**

CKDMIP data root: `/shared/home/greg/data/ckdmip`

Fixed objective manifest: `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/ecckd_published_training_manifest.json`

Expected training flux files: 52

- Upstream CKDMIP flux inputs: 34
- Derived ecCKD flux products: 18

## Blockers

- Missing required CKDMIP layout directory: evaluation2/lw_spectra
- Missing required CKDMIP layout directory: evaluation2/sw_spectra
- Missing required CKDMIP layout directory: evaluation2/lw_fluxes
- Missing required CKDMIP layout directory: evaluation2/sw_fluxes
- Missing or empty CKDMIP spectra directory: evaluation2/lw_spectra
- Missing or empty CKDMIP spectra directory: evaluation2/sw_spectra

## Derived Flux Products

None missing.

## Required Upstream Files

| Path | Present |
|---|---:|
| `mmm/conc/ckdmip_mmm_concentrations.nc` | true |
| `idealized/conc/ckdmip_idealized_concentrations.nc` | true |
| `evaluation1/conc/ckdmip_evaluation1_concentrations_present.nc` | true |
| `evaluation2/conc/ckdmip_evaluation2_concentrations_present.nc` | true |
| `mmm/sw_spectra_extras/ckdmip_ssi.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_cfc11-0.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_cfc11-2000.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_cfc12-0.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_cfc12-550.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-1200.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-2600.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-350.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-3500.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-700.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_co2-1120.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_co2-180.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_co2-2240.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_co2-280.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_co2-560.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_n2o-190.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_n2o-270.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_n2o-405.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_n2o-540.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_present.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_ch4-1200.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_ch4-2600.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_ch4-350.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_ch4-3500.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_ch4-700.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_co2-1120.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_co2-180.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_co2-2240.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_co2-280.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_co2-560.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_n2o-190.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_n2o-270.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_n2o-405.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_n2o-540.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_present.h5` | true |

## Derived Training Flux Products

| Path | Present |
|---|---:|
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_5gas-1120.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_5gas-180.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_5gas-2240.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_5gas-280.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_5gas-415.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_5gas-560.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-1120.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-180.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-2240.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-280.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-415.h5` | true |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-560.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_rel-1120.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_rel-180.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_rel-2240.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_rel-280.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_rel-415.h5` | true |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_rel-560.h5` | true |
