# Gate-4 Gate-2 binding-decision scaffold

Status: **g2_binding_scaffold_ready_awaiting_rulings**

decision map + neutral deterministic calculations only; NO dataset, aggregation, nonpositive-pair-policy, or gas-list election; NO threshold verdict; the binding Gate-2 runner remains unimplemented pending the D1-D4 rulings.

| Gate | Verdict |
|---|---|
| all_zero_per_policy_outcomes | passed |
| diagnostic_ch4_only_negative_total_refuses | passed |
| manifest_join_live_verified | passed |
| one_sided_zero_divergence | passed |
| policies_numerically_identical_without_zeros | passed |
| pooled_is_sse_over_count_not_mean_of_rmse | passed |
| real_two_scenario_aggregation | passed |
| refuse_axes_mismatch | passed |
| refuse_empty_arrays | passed |
| refuse_inf | passed |
| refuse_negative_total_finding | passed |
| refuse_nonfinite | passed |
| refuse_pending_eval2_as_metric_row | passed |
| refuse_scenario_outside_manifest | passed |
| refuse_unknown_policy | passed |
| refuse_unknown_policy_aggregation | passed |
| self_zero_both_policies_lw_sw | passed |
| synthetic_perturbation_detected | passed |

## Open decision points

- **D1_dataset_binding** [UNRESOLVED (requires recorded ruling)]
  - alternative: single present-day 50-column file (explicitly NOT the campaign set per design note rev 3)
  - candidate_set: {"counts":{"eval2_present":0,"lw_present":20,"of_eval2":2,"of_lw":20,"of_sw":16,"sw_present":16},"manifest_status":"gate2_dataset_manifest_pending_eval2","note":"entries remain tied to the manifest inventory labels/sha256 fingerprints, joined live per scenario by manifest_fingerprint with size+hash re-verification; eval2 rel-415 pair PENDING G2c/G2d and refused as a metric row until present","source_manifest":"gate4_gate2_od_dataset_manifest.json"}
- **D2_aggregation** [UNRESOLVED (requires recorded ruling)]
  - candidates: worst-case (max per-scenario log-RMSE) vs pooled (sqrt(sum SSE / sum selected count)) -- BOTH computed by aggregation_candidates(); the unweighted mean of scenario RMSEs is NOT a candidate and is kept outside as a demonstrator
- **D3_nonpositive_pair_policy** [UNRESOLVED (requires recorded ruling) -- the design-note wording 'positive-pair selection / epsilon clamping' is not a unique algorithm]
  - invariant: NEGATIVE totals in either definition are a finding/refusal under BOTH variants, never excluded or clamped; with no zeros the variants are numerically identical; they can diverge only when zeros are present
  - variant_eps_clamping: all nonnegative pairs included; log(x+eps) with eps = positive_eps over ALL values (unmodified positive_eps of ecckd_recovery_metrics.jl, reused by include)
  - variant_pair_selection: both totals > 0 selected; exact-zero pairs excluded and counted; log(x+eps) with eps = positive_eps over the SELECTED values
- **D4_active_gas_lists** [UNRESOLVED (requires recorded ruling)]
  - constraint: identical reference/candidate lists are ENFORCED for campaign-comparable metrics (single-list API); the binding runner needs recorded per-scenario lists (rel scenarios omit cfc11/cfc12 from their axes, so LW lists are scenario-dependent)
  - self_test_lists: labeled TEST inputs only

thresholds 4-5 aggregation semantics are a SEPARATE ruling: gate4_regression_margin_semantics_evidence.md (four open axes)

Demo aggregation (labeled synthetic x1.001, no election): worst 0.0009995003313265987 / pooled sqrt(SSE-sum/n-sum) 0.0009995003306626298; non-candidate unweighted mean 0.0009995003306626296.

Provenance: branch `glw/gate4-recovery`, generated_from_head `ecf641b` (pre-own-commit).
