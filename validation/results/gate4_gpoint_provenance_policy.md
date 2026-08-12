# Gate-4 g-point provenance policy — HISTORICAL (acceptance mechanism superseded by Option B)

Status: **gpoint_policy_recorded**

**Superseded by**: gate4_option_b_decision_record (Greg-authorized amended acceptance rule: structural elementwise-exact + support arrays within storage precision <= 2.1e-5); the structural-identity policy intent and Path-B sensitivity rule remain in force

**Outcome**: A2 rerun (job 4082) candidates + create_lut proof (job 4091) accepted under the amended rule: LW gpoints c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e, SW 13dd686acd0c3ca2201775270f876ce3e3a326576b58b24323b5ce95659b9b57; sha-pinned by gate4_g3_scoped_input_preflight.jl

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

Verification support arrays (comparison targets for A1/A2 candidates, NOT extraction sources): ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc, ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc (gpoint_fraction + band arrays). the previously recorded future-output paths (/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/gpoints/extracted_*.h5) and extractor schema anchor are WITHDRAWN: extraction was proven invalid and no extractor unit was ever built; the actual accepted g-point files came from the A2 rerun (job 4082) at /shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work/lw_gpoints/ and /shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work-v14 (symlinked), accepted under Option B (LW c96e6492..., SW 13dd686a...)

Historical requirement (was an independent blocker at decision time, RESOLVED): ckdmip_mmm-const_concentrations.nc (present: true).

Provenance: branch `glw/gate4-recovery`, generated_from_head `b890429` (pre-own-commit).
