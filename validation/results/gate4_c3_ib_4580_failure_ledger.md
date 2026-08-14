# Gate-4 C3-IB job 4580 terminal failure ledger

Status: **c3ib_4580_failed_downstream_banner_gate_false_refusal**

| Field | Value |
|---|---|
| JobState | FAILED (NonZeroExitCode, 71:0) |
| RunTime | 00:52:49 (limit 06:00:00) |
| EndTime | 2026-08-14T17:29:30 |
| Receipt | `28e71c26bc69834b145ce78fb3c8c5ac8e5eef1a2be9506a2832660de7276c19` (epoch 1786728580) |
| Log | `292c9ce6fabba8a23ba27206718d33d22dfbec466e24c9874a40c582be897873` (1247306 B) |
| Base criterion authority | `3ebaef95...` optimize_lut.cpp compiled default (template has ZERO base override) |
| Root cause | instrument-gate false-refusal: committed gate (sbatch `834cd0d3...` line 1261) expected downstream criterion 0.02; template (`f0d77b16...`) sets 0.0005; observed banner log:3663 |
| Science before refusal | 20-file staging + census passed; c0a base capped; relative-ch4 completed, raw3 closed (log:16553) |
| RUNROOT | `/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/g4-diag/4580/lw-c3ib` (preserved; partial outputs prohibited from reuse; reviewer accesses read-only) |

Classification (monitor): instrument-gate false-refusal -- not scientific, not staging. ZERO scientific inference; no resubmission without explicit Codex-monitor GO; a fresh job must rerun the full sandwich.
