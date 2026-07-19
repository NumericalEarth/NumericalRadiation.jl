# Gate-4 g-point provenance policy

Status: **gpoint_policy_recorded**

policy decision record only; no extraction, generation, optimization, objective, floor, or recovery computation.

**Recommendation: PATH A** -- extract the g-point structure from the published targets for acceptance runs; g-points are part of the fixed problem definition under the optimizer-only-delta rule.

PATH B (rerun find_g_points) is a non-acceptance sensitivity/reproduction path; its outputs cannot feed the main recovery floor unless Greg explicitly changes the rule.

| Gate | Result |
|---|---|
| independent_blocker_mmm_const_identified | passed |
| no_optimization_or_floor_run | passed |
| path_b_barred_from_acceptance | passed |
| published_targets_resolved | passed |
| recommendation_is_path_a | passed |

Extraction inputs: ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc, ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc (gpoint_fraction + band arrays); future outputs under /shared/home/greg/ecckd-derived-flux-work/g4-init-generation/gpoints/.

Independent blocker: ckdmip_mmm-const_concentrations.nc (present: false).

Provenance: branch `glw/gate4-recovery`, generated_from_head `d49618e` (pre-own-commit).
