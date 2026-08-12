# Gate-4 pending-rulings register

Status: **pending_rulings_register_recorded**

derivative read-only register of source-proven OPEN rulings; no election, no inferred authority, no resolution recorded; deletion, quota change, and job submission remain unauthorized; quota figures are an observed-at snapshot from the pinned 4440 failure ledger, never a live read.

| Gate | Verdict |
|---|---|
| exact_authority_sentence_verified | passed |
| exact_ruling_id_set | passed |
| gate2_decision_map_verified_open | passed |
| guard_fixtures | passed |
| quota_path_sources_verified | passed |
| quota_snapshot_arithmetic_verified | passed |
| thresholds45_axes_source_verified | passed |
| unique_ids_and_no_election | passed |

## Open rulings (9)

- **R-G2-D1** [OPEN] Gate-2 binding decision D1_dataset_binding
  - deciding authority: UNASSIGNED
  - options (from source): {"alternative": "single present-day 50-column file (explicitly NOT the campaign set per design note rev 3)", "candidate_set": {"counts": {"eval2_present": 0, "lw_present": 20, "of_eval2": 2, "of_lw": 20, "of_sw": 16, "sw_present": 16}, "manifest_status": "gate2_dataset_manifest_pending_eval2", "note": "entries remain tied to the manifest inventory labels/sha256 fingerprints, joined live per scenario by manifest_fingerprint with size+hash re-verification; eval2 rel-415 pair PENDING G2c/G2d and refused as a metric row until present", "source_manifest": "gate4_gate2_od_dataset_manifest.json"}}
  - unblocks: the binding Gate-2 true-OD runner (with the other D rulings)
- **R-G2-D2** [OPEN] Gate-2 binding decision D2_aggregation
  - deciding authority: UNASSIGNED
  - options (from source): {"candidates": "worst-case (max per-scenario log-RMSE) vs pooled (sqrt(sum SSE / sum selected count)) -- BOTH computed by aggregation_candidates(); the unweighted mean of scenario RMSEs is NOT a candidate and is kept outside as a demonstrator"}
  - unblocks: the binding Gate-2 true-OD runner (with the other D rulings)
- **R-G2-D3** [OPEN] Gate-2 binding decision D3_nonpositive_pair_policy
  - deciding authority: UNASSIGNED
  - options (from source): {"invariant": "NEGATIVE totals in either definition are a finding/refusal under BOTH variants, never excluded or clamped; with no zeros the variants are numerically identical; they can diverge only when zeros are present", "variant_eps_clamping": "all nonnegative pairs included; log(x+eps) with eps = positive_eps over ALL values (unmodified positive_eps of ecckd_recovery_metrics.jl, reused by include)", "variant_pair_selection": "both totals > 0 selected; exact-zero pairs excluded and counted; log(x+eps) with eps = positive_eps over the SELECTED values"}
  - unblocks: the binding Gate-2 true-OD runner (with the other D rulings)
- **R-G2-D4** [OPEN] Gate-2 binding decision D4_active_gas_lists
  - deciding authority: UNASSIGNED
  - options (from source): {"constraint": "identical reference/candidate lists are ENFORCED for campaign-comparable metrics (single-list API); the binding runner needs recorded per-scenario lists (rel scenarios omit cfc11/cfc12 from their axes, so LW lists are scenario-dependent)", "self_test_lists": "labeled TEST inputs only"}
  - unblocks: the binding Gate-2 true-OD runner (with the other D rulings)
- **R-T45-AX1** [OPEN] Thresholds 4-5 open axis -- pairing: max paired per-scenario delta vs difference of model-level worsts
  - deciding authority: UNASSIGNED
  - options (from source): see the OPEN AXES section of the pinned evidence memo (quoted options preserved there verbatim)
  - unblocks: the thresholds 4-5 regression-margin evaluator (with the other axes)
- **R-T45-AX2** [OPEN] Thresholds 4-5 open axis -- forcing combination: TOA/surface conjunction vs max of the two deltas (no combined scalar exists in any primary source)
  - deciding authority: UNASSIGNED
  - options (from source): see the OPEN AXES section of the pinned evidence memo (quoted options preserved there verbatim)
  - unblocks: the thresholds 4-5 regression-margin evaluator (with the other axes)
- **R-T45-AX3** [OPEN] Thresholds 4-5 open axis -- heating-RMSE aggregation: per-case deltas vs worst-case delta vs pooled (no pooled precedent in the canonical published-accuracy path)
  - deciding authority: UNASSIGNED
  - options (from source): see the OPEN AXES section of the pinned evidence memo (quoted options preserved there verbatim)
  - unblocks: the thresholds 4-5 regression-margin evaluator (with the other axes)
- **R-T45-AX4** [OPEN] Thresholds 4-5 open axis -- signed vs absolute deltas ('may not regress beyond' reads signed; recorded phrasing, not an implementation)
  - deciding authority: UNASSIGNED
  - options (from source): see the OPEN AXES section of the pinned evidence memo (quoted options preserved there verbatim)
  - unblocks: the thresholds 4-5 regression-margin evaluator (with the other axes)
- **R-QUOTA-PATH-AD** [OPEN] Quota recovery path authorization: Path A (uid quota raise) vs Path D (authorization-required scoped cleanup fallback, idealized spectra only)
  - deciding authority: Greg -- explicitly assigned by the runbook: 'No `rm`, no quota change, and no job submission may be run from this document without Greg's explicit authorization of the chosen path.'
  - options (from source): {"path_a": "uid quota raise (runbook '## Path A', admin action; preserves everything)", "path_d_exact_byte_scope": "authorization-required scoped cleanup fallback: delete /shared/home/greg/data/ckdmip/idealized/{lw_spectra,sw_spectra} ONLY: 66 files / 217,901,253,443 B (~202.9 GiB); PRESERVE idealized/conc and ALL of evaluation1/ (eval1 is NOT in the S3 archive); remains UNAUTHORIZED until Greg rules"}
  - unblocks: G2c eval2 fetch resume -> G2d rel-415 fluxes -> scoped preflight ready -> G3 executor ready_awaiting_go
  - constraint: deletion, quota change, and job submission remain UNAUTHORIZED pending this ruling
  - quota snapshot observed at: 2026-08-12T08:20:00Z
  - snapshot note: pinned 4440 failure-ledger accounting, arithmetic-verified; NOT a live read -- the quota watcher runs separately so this register stays deterministic
  - quota snapshot (arithmetic-verified): {"hard_headroom_bytes_post_failure": 35246998528, "local_finalized": {"bytes": 175407705620, "files": 30, "note": "30 LW finals, 0 SW, 0 temps; all preserved, nothing deleted"}, "note": "headroom and shortfall measured POST-FAILURE after AWS removed partial temps (usage transiently reached the hard boundary at EDQUOT); spectra alone exceed post-failure headroom by ~111 GiB before ~4.5 GB rayleigh and G2d work outputs; S3 ETags are multipart (suffix -N) = opaque provenance strings, NOT MD5", "remaining_bytes": 154581529276, "shortfall_bytes_post_failure": 119334530748, "source_set_bytes": {"lw_35_files": 219614131381, "sw_35_files": 110375103515, "total_70": 329989234896}}

## Sources (fail-closed verified; path + sha256)

- `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_g2_binding_decision_scaffold.json` sha256 `8db2be8896247965da4f6287c7c4a8a14ca901fb0a8a206764980b9cfac87829` (json)
- `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/gate4_regression_margin_semantics_evidence.md` sha256 `a1888f64a55ee9fd5f6a63b92fb3a2ce57319c9b5eb8ad0c4dc177f85d1c555c` (md)
- `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_g2c_eval2_fetch_checkpoint.json` sha256 `cb9e6e26c4804052b3b6eb412f0a686c8bb07e87f20d9e52e5197bd64dc26e52` (json)
- `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_g2c_failure_ledger_4440.json` sha256 `e7f2e458435a1ffdeab9abb2d45090cfc5959973e2a566c55b77fade1e78c571` (json)
- `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/gate4_g2c_quota_recovery_runbook.md` sha256 `a3e59da88998d1b16a26ed6910ea9ce4115e3dc2522da98347f1798809c6251c` (md)

Provenance: branch `glw/gate4-recovery`, generated_from_head `0d82813` (pre-own-commit).
