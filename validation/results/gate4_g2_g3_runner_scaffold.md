# Gate-4 G2/G3 runner scaffold (dry-run manifest)

Status: **runner_scaffold_ready_waiting_for_data**

dry-run manifest only; no floor, objective-value, or recovery claim; refuses execution without explicit real-data authorization.

| Gate | Result |
|---|---|
| derived_products_enumerated | passed |
| lw_base_init_raw_ckd | passed |
| minor_pass_relative_to_rel415 | passed |
| no_external_sw_4angle_products | passed |
| outcode_chain_continuous | passed |
| support_excluded_from_trainable | passed |
| sw_base_init_scaled_ckd | passed |

## LW pass chain

- relative-base: raw-ckd-definition -> raw2-ckd-definition; gases = composite, h2o, o3, co2; relative_to = nothing
- relative-ch4: raw2-ckd-definition -> raw3-ckd-definition; gases = ch4; relative_to = ckdmip_evaluation1_lw_fluxes_rel-415.h5
- relative-n2o: raw3-ckd-definition -> raw4-ckd-definition; gases = n2o; relative_to = ckdmip_evaluation1_lw_fluxes_rel-415.h5
- relative-cfc: raw4-ckd-definition -> ckd-definition; gases = cfc11, cfc12; relative_to = ckdmip_evaluation1_lw_fluxes_rel-415.h5

## SW pass chain

- relative-base: scaled-ckd-definition -> raw2-ckd-definition; gases = composite, h2o, o3, co2; relative_to = nothing
- relative-ch4: raw2-ckd-definition -> raw3-ckd-definition; gases = ch4; relative_to = ckdmip_evaluation1_sw_fluxes-rgb_rel-415.h5
- relative-n2o: raw3-ckd-definition -> ckd-definition; gases = n2o; relative_to = ckdmip_evaluation1_sw_fluxes-rgb_rel-415.h5

Derived products present: 0 / 18

Future execution: RH_CKDMIP_DATA_PATH=... julia --project=test validation/gate4_g2_g3_runner_scaffold.jl -- once the executor unit lands: execute_g2_g3(manifest; authorize = :real_data_preflight_green) after ckdmip_training_data_preflight reports ready_for_original_ecckd_objective

Provenance: branch `glw/gate4-recovery`, generated_from_head `87a93db` (pre-own-commit).
