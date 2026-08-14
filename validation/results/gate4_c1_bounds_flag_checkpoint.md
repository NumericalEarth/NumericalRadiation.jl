# Gate-4 C1 bounded-minimization flag-factor checkpoint

Status: **c1_checkpoint_ready**

CONFIG-ONLY one-factor experiment on the identical modern pinned stack as X1: triple-arm SAME-BINARY sandwich C0a -> C1 -> C0b preceded by a 1-iteration UNBOUNDED probe (flag literal semantics; structural evidence only); the single factor is the command-line override bounded_minimization=0 (optimize_lut.cpp:148-149; compiled default true); pristine binary in ALL arms; no capture instrument, no sidecar; the returned solution is UNOBSERVED by design. C1 discriminates NO mechanism (the flag removes the bounded solver path AND the log-space bound construction simultaneously) and repairs nothing. TWO-TIER VALUE POLICY: structure failures refuse; nonfinite values in probe/C1 raw2 are recorded lawful observations; strict all-finite applies to C0a/C0b only. Internal validity (C0a==C0b logical identity AND terminal-status exact equality) is SEPARATE from the historical 4561 bridge; both are completion-ledger matters (in-job byte-compares are informational echoes). Zero canonical writes; RUNROOT preserved; no submission without explicit monitor GO.

| Gate | Result |
|---|---|
| evidence_adept_toolchain_pins | passed |
| evidence_bridge_target_pin | passed |
| evidence_frozen_design_file | passed |
| evidence_input_pins | passed |
| evidence_modern_source_pins | passed |
| evidence_reviewed_x1_completion_ledger | passed |
| evidence_runtime_pins | passed |
| evidence_sbatch_bash_syntax | passed |
| evidence_sbatch_text_gates | passed |
| evidence_schema_signature | passed |
| evidence_toolchain_fingerprints | passed |
| evidence_x1_ledger_commit_pin | passed |
| fixtures | passed |

Frozen design: `60f55abec74287a9aaec62070bbd393420de16dd10042fa63fbb5094a3ffa888` (durable file `validation/gate4_c1_frozen_design.md`)

Generated sbatch: `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_c1_lw_bounds_flag.sbatch` sha256 `817c16083af8eac2b335b70f68c10a6ecf3f465d171d22d17a3d4043f121017f`

Prerequisite (fail-closed, sha-chained): X1 completion ledger `bb1f87c597e673c8a5b5181d325d46eff7b4619c106e28e7ecf121db32c34170` (x1_run_completed_verified; commit 4a3be7a596a3be1e4391c767f23de1f163e227f7)

Bridge target (ledger matter): 4561 pristine raw2 `49ff3df8c02a1b62f7bfa6cd4b8dc2c6c96e93079c1d042eb8cfb5fc49c61e37` (re-verified at generation)

Fixtures: 62 (62 passed)

Run order: PROBE (unbounded, 1 iteration; structural only) -> C0a -> C1 -> C0b; single binary; two-tier value policy in-job; internal gate and bridge decided by the completion ledger.
