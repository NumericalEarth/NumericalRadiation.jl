# Gate-4 g-point provenance policy

Status: **gpoint_policy_recorded**

policy decision record only; no extraction, generation, optimization, objective, floor, or recovery computation.

**Recommendation: PATH A (structural identity), MECHANISM AMENDED** -- direct extraction from published gpoint_fraction is proven invalid (see gate4_gpoint_extraction_feasibility); acceptance sources are A1 released find_g_points HDF5, A2 exact rerun with proof of reproducing published support arrays, or A3 upstream raw/scaled init definitions. G-points remain part of the fixed problem definition under the optimizer-only-delta rule.

Acceptance sources: A1 released original HDF5; A2 exact rerun WITH exact-reproduction proof against the published support arrays; A3 upstream raw/scaled init definitions. Sensitivity-only reruns are those WITHOUT exact reproduction proof; they cannot feed the main recovery floor unless Greg explicitly changes the rule.

| Gate | Result |
|---|---|
| independent_blocker_mmm_const_identified | passed |
| no_optimization_or_floor_run | passed |
| published_targets_resolved | passed |
| recommendation_is_path_a | passed |
| unproven_reruns_barred_from_acceptance | passed |

Verification support arrays (comparison targets for A1/A2 candidates, NOT extraction sources): ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc, ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc (gpoint_fraction + band arrays); future gpoints.h5 outputs under /shared/home/greg/ecckd-derived-flux-work/g4-init-generation/gpoints/.

Independent blocker: ckdmip_mmm-const_concentrations.nc (present: true).

Provenance: branch `glw/gate4-recovery`, generated_from_head `1433e9c` (pre-own-commit).
