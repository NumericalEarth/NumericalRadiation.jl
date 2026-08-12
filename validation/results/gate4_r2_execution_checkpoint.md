# Gate-4 R2 execution checkpoint — HISTORICAL (executed as jobs 4094/4095/4096)

Status: **r2_execution_checkpoint_historical_executed**

HISTORICAL post-execution record: the generated sbatch was executed as jobs 4094/4095/4096 (ledger-verified); the executed script is preserved byte-identically, never regenerated; nothing executed or submitted by this unit.

Authorization: Greg: 'go for R2' (2026-07-20) = r2_matching_version_go per the scaffold

| Gate | Result |
|---|---|
| adept_link_workaround_documented | passed |
| attempt_history_ledger_verified | passed |
| authorization_recorded | passed |
| candidate_identity_pinned | passed |
| ckd_model_has_ssi_persistence | passed |
| configure_ac_is_14 | passed |
| create_lut_only | passed |
| finding_ledger_structure_valid | passed |
| headnode_refusal_guard | passed |
| mechanism1_placement | passed |
| prerequisite_loader_fixture_tests | passed |
| preserved_sbatch_consistent_with_current_generator_text | passed |
| preserved_sbatch_matches_executed_blob | passed |
| quarantine_isolation | passed |
| r2_finding_ledger_verified | passed |
| sbatch_not_regenerated_or_submitted | passed |
| sbatch_preserved_not_regenerated | passed |
| scaffold_prerequisite | passed |
| stale_output_refusal | passed |
| sw_candidate_hash_pinned | passed |
| toolchain_parity_flags | passed |
| v14_raw_output_matches_finding_ledger | passed |
| v14_tree_at_pinned_commit | passed |

Executed batch script (preserved; byte-verified against the repository-pinned final submitted-script record, the git blob at `6937d473c4cb22daea38f38cd5bbaaed7dd98416` committed 2026-07-20T16:27:59Z before job 4096 completed 16:43:13Z): `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_r2_dryrun.sbatch` sha256 `30d0a2ce4735f9d52d36b3e23789824cbc058ab3167dff17e6e921ba7624839c`

Ledger-verified attempts:
- job 4094 FAILED at configure (adept.m4 -ladept in LDFLAGS dropped by --as-needed; latent at v1.2 whose weaker conftest was header-only satisfiable)
- job 4095 FAILED at configure sanity check (LIBS=-ladept applied before any -L path exists)
- job 4096 COMPLETED rc=0 at 2026-07-20T16:43:13Z with LDFLAGS='-L<adept>/lib -Wl,-rpath,<adept>/lib' LIBS=-ladept

Verified v1.4 SW raw output: `/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work-v14/sw_raw-ckd-definition/ecckd-1.4_sw_raw-ckd-definition_climate_rgb-tol0.047.nc` sha256 `99333fb5f3c1a3e7ee343a8abd5bbe599f61419c89b8f9b13320a85105532c26`

Provenance: branch `glw/gate4-recovery`, generated_from_head `2f9fa6d` (pre-own-commit).
