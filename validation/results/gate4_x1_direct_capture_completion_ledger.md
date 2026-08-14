# Gate-4 X1 direct-capture completion ledger (job 4561)

Status: **x1_run_completed_verified**

| Gate | Result |
|---|---|
| evidence_arm_logs | passed |
| evidence_array_loads | passed |
| evidence_axis_c_gate | passed |
| evidence_census_consistency | passed |
| evidence_commit_and_package_pins | passed |
| evidence_comparator_code_pins | passed |
| evidence_comparator_integrity | passed |
| evidence_custody_receipts | passed |
| evidence_frozen_validator_pin | passed |
| evidence_frozen_validator_rerun | passed |
| evidence_job_log | passed |
| evidence_observed_outcome_consistency | passed |
| evidence_pinned_definition_extraction | passed |
| evidence_probe_control_contract | passed |
| evidence_runroot_artifacts | passed |
| fixtures | passed |

Fixtures: 37 (37 passed)

## Axis results (FULL X1 arm; descriptive)
- AXIS A: below 134/152631, above 19/152640; worst dlog 0.41887798773359464 / 0.6268579317460752; exact-at-bound 0 / 0
- AXIS B: exact-bit mapped-vs-caller mismatches 0; max abs 0.0, max rel 0.0, max dlog 0.0; Float32(mapped) vs caller_f32 mismatches 0
- AXIS C: total mismatch 0 (zero required; per gas Dict("composite" => 0, "o3" => 0, "h2o" => 0, "co2" => 0))

## Probe control (descriptive)
- AXIS A: below 0/152631, above 0/152640
- AXIS B: exact-bit mismatches 0

## Census (pinned kernel)
- pristine_raw2: below 134/152631, above 19/152640; worst dlog 0.41887799902470135 / 0.6268579421960787; event sum 153, unique coordinates 153; B-intersections Dict("below_and_b_mismatch" => 0, "above_and_b_mismatch" => 0)
- x1_raw2: below 134/152631, above 19/152640; worst dlog 0.41887799902470135 / 0.6268579421960787; event sum 153, unique coordinates 153; B-intersections Dict("below_and_b_mismatch" => 0, "above_and_b_mismatch" => 0)
- caller_f64: below 134/152631, above 19/152640; worst dlog 0.41887798773359464 / 0.6268579317460752; event sum 153, unique coordinates 153; B-intersections Dict("below_and_b_mismatch" => 0, "above_and_b_mismatch" => 0)
- caller_f32: below 134/152631, above 19/152640; worst dlog 0.41887799902470135 / 0.6268579421960787; event sum 153, unique coordinates 153; B-intersections Dict("below_and_b_mismatch" => 0, "above_and_b_mismatch" => 0)
- mapped_f64: below 134/152631, above 19/152640; worst dlog 0.41887798773359464 / 0.6268579317460752; event sum 153, unique coordinates 153; B-intersections Dict("below_and_b_mismatch" => 0, "above_and_b_mismatch" => 0)
- mapped_f32: below 134/152631, above 19/152640; worst dlog 0.41887799902470135 / 0.6268579421960787; event sum 153, unique coordinates 153; B-intersections Dict("below_and_b_mismatch" => 0, "above_and_b_mismatch" => 0)
- x1_raw2 matches committed S1 census: true (informational)

## Objectives (secondary, pre-registered)
- delta_reconstruction_minus_serialized: 0.0
- published_selfcheck: 0.18218645425029933
- returned_state_reconstruction: 22.791293464348826
- x1_serialized: 22.791293464348826

## Observed outcome (local branch fired)

OBSERVED LOCAL OUTCOME (the branch that fired in THIS run): returned_x_log lies outside the CAPTURED supplied lower/upper bound vectors at 134 lower + 19 upper coordinates. The sidecar-recorded C++ callback mapping (mapped_x_phys) equals caller_phys bit-for-bit at all 152640 rows; Float32(mapped_x_phys) equals caller_phys_f32 bit-for-bit; and caller_phys_f32 equals the serialized raw2 coefficients bit-for-bit at every mapped position. The returned-log -> mapped-physical SEMANTIC validation relies on the frozen validator's declared <=4-ULP cross-library exp tolerance, so that link is NOT claimed bit-exact end-to-end: the chain is MIXED, one tolerance-bounded link followed by exact-bit links. The Axis-A exceedance counts are computed in the log domain directly against the exact captured bound vectors and are unaffected by the exp-tolerance caveat. The returned-state reconstruction changes zero coefficient values and the objective delta is exactly 0.0. LICENSED CONCLUSION: no observed returned-vs-caller or caller-vs-serialization discrepancy in this run; the ORIGIN of the returned-x bound exceedances and their relationship to the 22.791293464348826 objective remain UNRESOLVED; no historical or global claim.

## Interpretation ceiling

Findings are LOCAL to this rebuilt trajectory; the identity gate licenses non-perturbation ONLY for this pristine/X1 pair; Axis-A/B/C statements are DESCRIPTIVE and all three mechanism classes (final-state synchronization, mapping/write, bounded-algorithm behavior) remain OPEN and UNRANKED globally, with no localization and no causal attribution; any Axis-C, validator, like-with-like census, pin, or reconstruction-integrity inconsistency REFUSES rather than concludes, and refusal branches fire on domain-matched comparisons only. Historical byte differences license no causal inference; no expected probe scientific value was encoded or retrofitted.
