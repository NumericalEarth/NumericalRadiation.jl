# Gate-4 Gate-1 objective-ratio runner

Status: **g1_waiting_for_optimizer_outputs**

refusing Gate-1 runner: binds ONLY on a reviewed run ledger + sha-matched recovered pair; published-pair numbers are self-test context, not recovered acceptance; the upstream objective/floor comparison is a separate outstanding item.

| Gate | Verdict |
|---|---|
| perturbed_candidate_raises_objective | passed |
| published_context_matches_archived_baseline | passed |
| refusal_ladder_fixtures | passed |
| run_ledger_schema_fixtures | passed |

Published-pair CONTEXT (not recovered acceptance): hard objective 0.18218645425029933 (heating_rate_max_abs on ecckd_clear_sky_tropical_column); archived baseline 0.18218645425029933, rel diff 0.0; perturbed 27.90958396366932.

Live recovered-pair gate: **g1_waiting_for_optimizer_outputs** (recovered pair absent (expected at the G3 executor output conventions); refusing to evaluate)
