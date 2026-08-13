# Gate-4 status/case-projection dependency contract audit

Status: **dependency_contract_audit_consistent**

status/case projection of every literal JSON.parsefile-MEDIATED cross-artifact contract in validation/gate4*.jl (other parsing forms, e.g. JSON.parse over network responses in the V1/R1 recon units, are not artifact contracts and are not censused), plus declared extensions (register snapshot-hash, E9 prerequisite truth table + reviewed-complete ledger schema, fingerprint-join post-hoc rows with artifact identity, authority-input truth table for the rulings intake); structural requirements beyond that projection are enforced in-unit by consumers and listed in structural_out_of_scope

derivative read-only STATUS/CASE-PROJECTION contract audit; consumer contracts modeled faithfully (status-only contracts are hardening findings, not upgraded); no election, no state mutation, no unit execution, no submission/fetch/deletion/quota action.

| Gate | Verdict |
|---|---|
| census_reconciles_with_edge_linkage | passed |
| fixtures | passed |
| manifest_edge_count_43 | passed |
| manifest_ids_unique | passed |
| manifest_schema_valid | passed |
| no_contract_violations | passed |
| snapshot_extension_count_6 | passed |

Census: 23 parse sites reconciled with edge linkage; modes a2=historical r2=historical sw_init=output_present g3_ledger_present=true.

## Contract verdicts (42 satisfied / 1 inactive / 0 selftest-state / 0 violated)

- dep:sw_init_checkpoint<-option_b [exact]: **satisfied** -- contract satisfied
- dep:sw_init_checkpoint<-init_provenance_ledger:output_present [exact]: **satisfied** -- contract satisfied
- dep:r2_proof_scaffold<-r1_probe [exact]: **satisfied** -- contract satisfied
- dep:r2_proof_scaffold<-r2_finding_ledger:historical [mode_dependent]: **satisfied** -- contract satisfied
- dep:r2_proof_scaffold<-option_b:historical [mode_dependent]: **satisfied** -- contract satisfied
- dep:r2_proof_scaffold<-init_provenance_ledger:historical [mode_dependent]: **satisfied** -- contract satisfied
- dep:r2_exec_checkpoint<-r2_proof_scaffold [mode_dependent]: **satisfied** -- contract satisfied
- dep:r2_exec_checkpoint<-r2_finding_ledger:historical [mode_dependent]: **satisfied** -- contract satisfied
- dep:a2_proof_scaffold<-a2_exec_checkpoint [set]: **satisfied** -- contract satisfied
- dep:a2_proof_driver<-a2_proof_scaffold [exact]: **satisfied** -- contract satisfied
- dep:a2_proof_driver<-a2_proof_finding_ledger:historical [mode_dependent]: **satisfied** -- contract satisfied
- dep:a2_proof_driver<-a2_proof_submission_ledger:historical [mode_dependent]: **satisfied** -- contract satisfied
- dep:a2_proof_driver<-option_b:historical [mode_dependent]: **satisfied** -- contract satisfied
- dep:a2_exec_checkpoint<-a2_submission_ledger:mode_selection [mode_dependent]: **satisfied** -- contract satisfied
- dep:a2_exec_checkpoint<-a2_rerun_manifest:preexecution [mode_dependent]: **inactive_branch** -- contract branch not exercised in the current mode; anchors verified
- dep:a2_exec_checkpoint<-a2_proof_finding_ledger:later_disposition [mode_dependent]: **satisfied** -- contract satisfied
- dep:a2_exec_checkpoint<-option_b:later_disposition [mode_dependent]: **satisfied** -- contract satisfied
- dep:a2_rerun_manifest<-a1_upstream_recon [exact]: **satisfied** -- contract satisfied
- dep:init_generation_manifest<-g2_g3_runner_scaffold [prefix]: **satisfied** -- contract satisfied
- dep:g2_g3_runner_scaffold<-stage_config_audit [exact]: **satisfied** -- contract satisfied
- dep:g2_g3_runner_scaffold<-covariance_stride_audit [exact]: **satisfied** -- contract satisfied
- dep:g2a_checkpoint<-init_provenance_ledger [exact]: **satisfied** -- contract satisfied
- dep:g2b_checkpoint<-g2a_data_ledger [exact]: **satisfied** -- contract satisfied
- dep:g3_executor<-scoped_preflight [exact]: **satisfied** -- contract satisfied
- dep:g2_binding_scaffold<-gate2_od_dataset_manifest:fingerprint_join [fingerprint_join]: **satisfied** -- all 3 manifest-joined rows re-verified (label, sha, live size+hash); manifest status gate2_dataset_manifest_pending_eval2 recorded as info only
- dep:rulings_register<-g2_binding_scaffold [register_snapshot]: **satisfied** -- snapshot and live contract both satisfied
- dep:rulings_register<-g2c_fetch_checkpoint [register_snapshot]: **satisfied** -- snapshot and live contract both satisfied
- dep:rulings_register<-g2c_failure_ledger_4440 [register_snapshot]: **satisfied** -- snapshot and live contract both satisfied
- dep:rulings_intake<-pending_rulings_register [exact]: **satisfied** -- contract satisfied
- dep:rulings_intake<-rulings_assignment:authority_input [authority_input]: **satisfied** -- register healthy; authority input absent; allowed=["rulings_intake_awaiting_assignments"]; consumer status=rulings_intake_awaiting_assignments
- dep:post_cleanup_census<-g3_scoped_preflight [exact]: **satisfied** -- contract satisfied
- dep:g3_scoped_preflight<-g2d_completion_ledger [exact]: **satisfied** -- contract satisfied
- dep:post_cleanup_census<-g2c_fetch_checkpoint [exact]: **satisfied** -- contract satisfied
- dep:g2d_checkpoint<-g2c_completion_ledger [exact]: **satisfied** -- contract satisfied
- dep:g2d_completion_ledger<-g2d_checkpoint [exact]: **satisfied** -- contract satisfied
- dep:post_cleanup_census<-pending_rulings_register [exact]: **satisfied** -- contract satisfied
- dep:r1_probe<-r2_finding_ledger:followup [exact]: **satisfied** -- contract satisfied
- dep:r1_probe<-option_b:followup [exact]: **satisfied** -- contract satisfied
- dep:v1_recon<-r1_probe:followup [exact]: **satisfied** -- contract satisfied
- dep:v1_recon<-r2_finding_ledger:followup [exact]: **satisfied** -- contract satisfied
- dep:v1_recon<-option_b:followup [exact]: **satisfied** -- contract satisfied
- dep:g1_objective_ratio<-g3_run_ledger [absence_tolerant]: **satisfied** -- outputs present; ledger present (parse_success=true, object_ok=true, schema_ok=true); allowed=["g1_blocked_ledger_hash_mismatch", "g1_blocked_structural_mismatch", "g1_blocked_boundary_compatibility_drift", "g1_objective_ratio_passed", "g1_objective_ratio_failed"]; consumer status=g1_objective_ratio_failed
- dep:g3_acceptance<-g3_run_ledger [absence_tolerant]: **satisfied** -- outputs present; ledger present (parse_success=true, object_ok=true, schema_ok=true); allowed=["g3_acceptance_blocked_ledger_hash_mismatch", "g3_acceptance_structural_mismatch", "g3_acceptance_incomplete_pending_objective_and_od", "g3_acceptance_failed_weight_l1"]; consumer status=g3_acceptance_incomplete_pending_objective_and_od

## Hardening findings (0)


## Structural checks out of scope

- **a2/r2 historical edges**: attempt strings, output/binary/sbatch hashes, job ids, outcome markers -- enforced in-unit
- **absence_tolerant**: full acceptance/objective logic -- this audit verifies the branch statuses and the reviewed-complete ledger schema only
- **authority_input**: assignment schema, register pin, authority, and vocabulary enforcement -- lives in the rulings intake itself; this audit projects register health, source presence, and parse shape into the faithful allowed status set only
- **fingerprint_join**: per-scenario schema/dims -- enforced by the manifest; this audit verifies the post-hoc row label/sha/live size+hash contract
- **register edges**: D-key set, quota arithmetic, MD anchors -- enforced by the register itself; this audit adds the snapshot-hash staleness projection

Provenance: branch `glw/gate4-recovery`, generated_from_head `559892b` (pre-own-commit).
