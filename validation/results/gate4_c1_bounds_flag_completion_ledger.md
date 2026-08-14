# Gate-4 C1 bounds-flag completion ledger (job 4562)

Status: **c1_run_completed_verified**

| Gate | Result |
|---|---|
| evidence_arm_logs | passed |
| evidence_array_loads | passed |
| evidence_census_consistency | passed |
| evidence_commit_and_package_pins | passed |
| evidence_comparator_code_pins | passed |
| evidence_comparator_integrity | passed |
| evidence_custody_receipts | passed |
| evidence_frozen_validator_pin | passed |
| evidence_full_scan_two_tier | passed |
| evidence_job_log | passed |
| evidence_nonfinite_aware_diff_structure | passed |
| evidence_pinned_definition_extraction | passed |
| evidence_runroot_artifacts | passed |
| fixtures | passed |

Fixtures: 43 (43 passed)

## Preregistered matrix (mechanical)
- INTERNAL VALIDITY HOLDS: C0a == C0b logically AND terminal statuses exactly equal; C1-vs-control differences are flag-associated FOR THIS FIXED SETUP (no mechanism claim)
- HISTORICAL BRIDGE HOLDS for both controls vs the 4561 pristine raw2 (extends the connection to the X1 trajectory; does NOT replace the internal gate)

## Census (pinned kernel)
- c0a: below 134/152631, above 19/152640; worst dlog 0.41887799902470135 / 0.6268579421960787; event sum 153, unique 153
- c0b: below 134/152631, above 19/152640; worst dlog 0.41887799902470135 / 0.6268579421960787; event sum 153, unique 153
- c1: below 124/152631, above 18/152640; worst dlog 0.4101159646151338 / 0.6321448857937266; event sum 142, unique 142

C1 census label: POST-HOC SERIALIZED-OUTPUT census of the C1 arm's serialized state against file-derived bounds that were NOT supplied to the unbounded solver; it measures NEITHER returned-x feasibility NOR bound enforcement (no capture instrument; callback-state lag possible; the returned minimizer x remains UNOBSERVED in C1 by design)

## Objectives (comparator; secondary)
- c0a: 22.791293464348826
- c0b: 22.791293464348826
- c1: 22.467263267279066
- delta_c0b_minus_c0a: 0.0
- delta_c1_minus_c0a: -0.3240301970697601
- delta_c1_minus_c0b: -0.3240301970697601
- published_selfcheck: 0.18218645425029933

## C1-vs-control value differences (counts only here; full per-variable table in JSON)
- c1-vs-c0a differing vars: 4
- c1-vs-c0b differing vars: 4

## Interpretation ceiling

C1 quantifies the bounded_minimization flag factor for this fixed setup only. It discriminates NO mechanism: the flag removes the bounded solver path AND the log-space bound construction simultaneously. Only if C0a-vs-C0b logical identity AND terminal-status exact equality hold may C1-vs-control differences be called flag-associated FOR THIS FIXED SETUP; the historical bridge is a SEPARATE question and neither substitutes for the other. No repair, recovery, or causal claim is made about any objective; the internal optimizer endpoint 16.7358 / 0.0290207 is descriptive and is not a comparator objective. All three mechanism classes -- final-state synchronization, mapping/write, bounded-algorithm behavior -- remain OPEN and UNRANKED globally; findings are LOCAL to this rebuilt trajectory; no historical or global claim.
