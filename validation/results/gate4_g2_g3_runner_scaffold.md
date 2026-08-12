# Gate-4 G2/G3 runner scaffold (dry-run manifest) — HISTORICAL/SUPERSEDED

Status: **runner_scaffold_ready_historical_superseded**

**Superseded by**: gate4_g3_scoped_input_preflight.jl + gate4_g3_executor_checkpoint.jl (token g3_recovery_go, human sbatch submission) + the G2a-G2d training-flux chain; the previously advertised execute_g2_g3 future command is WITHDRAWN -- that entrypoint is retired (intentionally unimplemented, refuses on every path) and the broad ckdmip_training_data_preflight gating was replaced by the scoped preflight

retained as read-only manifest evidence; pass-chain/audit gates remain valid checks of the pinned upstream scripts; 'ready' statuses assert manifest coherence + 4078-era derived-data presence, never execution readiness

HISTORICAL/SUPERSEDED dry-run manifest; no floor, objective-value, or recovery claim; execution refused on every path -- authority moved to the scoped-preflight + executor-checkpoint chain.

| Gate | Result |
|---|---|
| covariance_stride_prerequisite | passed |
| derived_products_enumerated | passed |
| lw_base_init_raw_ckd | passed |
| minor_pass_relative_to_rel415 | passed |
| no_external_sw_4angle_products | passed |
| outcode_chain_continuous | passed |
| prerequisite_loader_fixture_tests | passed |
| stage_config_prerequisite | passed |
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

Derived products present: 18 / 18

Provenance: branch `glw/gate4-recovery`, generated_from_head `2f84829` (pre-own-commit).
