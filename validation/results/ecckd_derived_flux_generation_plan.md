# ecCKD Derived Flux Generation Plan

Status: **missing_ckdmip_data_root**

CKDMIP data root: `nothing`

ecCKD source root: `/shared/home/greg/.julia/artifacts/7b210aef53e908cfe3c709945f0763c37ca82aaa/ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd`

The 5gas-* and rel-* flux products are generated ecCKD training targets, not public CKDMIP archive files. Generate them in a writable ecCKD working copy, then rerun the CKDMIP preflight.

## Progress

- Expected derived flux products: 18
- Final products present: 0
- Products with raw chunks present: 0
- Raw chunks present: 0/0
- Completed-equivalent raw chunks: 0/0
- Observed raw chunk rate: `nothing` chunks/hour
- Estimated raw chunk hours remaining: `nothing`

## Missing Derived Products

Missing derived flux products: 18

| Path | Domain | Scenario | Script |
|---|---|---|---|
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_5gas-1120.h5` | `lw` | `5gas-1120` | `test/run_lw_lbl_evaluation.sh` |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_5gas-180.h5` | `lw` | `5gas-180` | `test/run_lw_lbl_evaluation.sh` |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_5gas-2240.h5` | `lw` | `5gas-2240` | `test/run_lw_lbl_evaluation.sh` |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_5gas-280.h5` | `lw` | `5gas-280` | `test/run_lw_lbl_evaluation.sh` |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_5gas-415.h5` | `lw` | `5gas-415` | `test/run_lw_lbl_evaluation.sh` |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_5gas-560.h5` | `lw` | `5gas-560` | `test/run_lw_lbl_evaluation.sh` |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-1120.h5` | `lw` | `rel-1120` | `test/run_lw_lbl_evaluation.sh` |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-180.h5` | `lw` | `rel-180` | `test/run_lw_lbl_evaluation.sh` |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-2240.h5` | `lw` | `rel-2240` | `test/run_lw_lbl_evaluation.sh` |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-280.h5` | `lw` | `rel-280` | `test/run_lw_lbl_evaluation.sh` |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-415.h5` | `lw` | `rel-415` | `test/run_lw_lbl_evaluation.sh` |
| `evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-560.h5` | `lw` | `rel-560` | `test/run_lw_lbl_evaluation.sh` |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_rel-1120.h5` | `sw` | `rel-1120` | `test/run_sw_lbl_evaluation.sh` |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_rel-180.h5` | `sw` | `rel-180` | `test/run_sw_lbl_evaluation.sh` |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_rel-2240.h5` | `sw` | `rel-2240` | `test/run_sw_lbl_evaluation.sh` |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_rel-280.h5` | `sw` | `rel-280` | `test/run_sw_lbl_evaluation.sh` |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_rel-415.h5` | `sw` | `rel-415` | `test/run_sw_lbl_evaluation.sh` |
| `evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_rel-560.h5` | `sw` | `rel-560` | `test/run_sw_lbl_evaluation.sh` |

## Raw Chunk Progress

No raw chunks are present yet.

## Required ecCKD Scripts

| Path | Present |
|---|---:|
| `test/run_lw_lbl_evaluation.sh` | true |
| `test/run_sw_lbl_evaluation.sh` | true |
| `test/copy_to_ckdmip_lw.sh` | true |
| `test/copy_to_ckdmip_sw.sh` | true |
| `test/config.h` | true |

## Concatenation Tool

- `ncrcat` present: true
- `ncrcat` path: `/shared/home/greg/.local/bin/ncrcat`
- Julia concat shim: true
- Note: ncrcat resolves to the Julia concat shim used for CKDMIP raw chunk assembly.

## Scenario Batches

- LW scenarios: `5gas-180 5gas-280 5gas-415 5gas-560 5gas-1120 5gas-2240 rel-180 rel-280 rel-415 rel-560 rel-1120 rel-2240`
- SW scenarios: `rel-180 rel-280 rel-415 rel-560 rel-1120 rel-2240`

## Suggested Working-Copy Commands

```sh
RH_ECCKD_DERIVED_FLUX_DRY_RUN=true RH_CKDMIP_DATA_PATH=$RH_CKDMIP_DATA_PATH RH_ECCKD_SOURCE_PATH=/shared/home/greg/.julia/artifacts/7b210aef53e908cfe3c709945f0763c37ca82aaa/ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd RH_ECCKD_LBL_WORKDIR=/shared/home/greg/ecckd-derived-flux-work bash validation/generate_ecckd_derived_fluxes.sh
RH_ECCKD_DERIVED_FLUX_DRY_RUN=false RH_CKDMIP_DATA_PATH=$RH_CKDMIP_DATA_PATH RH_ECCKD_SOURCE_PATH=/shared/home/greg/.julia/artifacts/7b210aef53e908cfe3c709945f0763c37ca82aaa/ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd RH_ECCKD_LBL_WORKDIR=/shared/home/greg/ecckd-derived-flux-work RH_CKDMIP_TOOL_DIR=/path/to/ckdmip/bin bash validation/generate_ecckd_derived_fluxes.sh
# The launcher patches run_lw_lbl_evaluation.sh to SCENARIOS="5gas-180 5gas-280 5gas-415 5gas-560 5gas-1120 5gas-2240 rel-180 rel-280 rel-415 rel-560 rel-1120 rel-2240".
# The launcher patches run_sw_lbl_evaluation.sh to SCENARIOS="rel-180 rel-280 rel-415 rel-560 rel-1120 rel-2240".
RH_CKDMIP_DATA_PATH="$RH_CKDMIP_DATA_PATH" julia --project=test validation/ckdmip_training_data_preflight.jl
```

## Upstream Blockers

- RH_CKDMIP_DATA_PATH is unset or does not point to a directory.
- Missing required CKDMIP layout directory: mmm/conc
- Missing required CKDMIP layout directory: mmm/lw_spectra
- Missing required CKDMIP layout directory: mmm/sw_spectra
- Missing required CKDMIP layout directory: mmm/sw_spectra_extras
- Missing required CKDMIP layout directory: idealized/conc
- Missing required CKDMIP layout directory: idealized/lw_spectra
- Missing required CKDMIP layout directory: idealized/sw_spectra
- Missing required CKDMIP layout directory: evaluation1/conc
- Missing required CKDMIP layout directory: evaluation1/lw_spectra
- Missing required CKDMIP layout directory: evaluation1/sw_spectra
- Missing required CKDMIP layout directory: evaluation1/lw_fluxes
- Missing required CKDMIP layout directory: evaluation1/sw_fluxes
- Missing required CKDMIP layout directory: evaluation2/conc
- Missing required CKDMIP layout directory: evaluation2/lw_spectra
- Missing required CKDMIP layout directory: evaluation2/sw_spectra
- Missing required CKDMIP layout directory: evaluation2/lw_fluxes
- Missing required CKDMIP layout directory: evaluation2/sw_fluxes
- Missing required upstream CKDMIP file: mmm/conc/ckdmip_mmm_concentrations.nc
- Missing required upstream CKDMIP file: idealized/conc/ckdmip_idealized_concentrations.nc
- Missing required upstream CKDMIP file: evaluation1/conc/ckdmip_evaluation1_concentrations_present.nc
- Missing required upstream CKDMIP file: evaluation2/conc/ckdmip_evaluation2_concentrations_present.nc
- Missing required upstream CKDMIP file: mmm/sw_spectra_extras/ckdmip_ssi.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_cfc11-0.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_cfc11-2000.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_cfc12-0.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_cfc12-550.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-1200.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-2600.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-350.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-3500.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-700.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_co2-1120.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_co2-180.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_co2-2240.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_co2-280.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_co2-560.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_n2o-190.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_n2o-270.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_n2o-405.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_n2o-540.h5
- Missing required upstream CKDMIP file: evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_present.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_ch4-1200.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_ch4-2600.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_ch4-350.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_ch4-3500.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_ch4-700.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_co2-1120.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_co2-180.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_co2-2240.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_co2-280.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_co2-560.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_n2o-190.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_n2o-270.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_n2o-405.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_n2o-540.h5
- Missing required upstream CKDMIP file: evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_present.h5
- Missing or empty CKDMIP spectra directory: mmm/lw_spectra
- Missing or empty CKDMIP spectra directory: mmm/sw_spectra
- Missing or empty CKDMIP spectra directory: idealized/lw_spectra
- Missing or empty CKDMIP spectra directory: idealized/sw_spectra
- Missing or empty CKDMIP spectra directory: evaluation1/lw_spectra
- Missing or empty CKDMIP spectra directory: evaluation1/sw_spectra
- Missing or empty CKDMIP spectra directory: evaluation2/lw_spectra
- Missing or empty CKDMIP spectra directory: evaluation2/sw_spectra
