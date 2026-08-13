# Gate-4 G3 optimizer run ledger

Status: **reviewed-complete**

read-only evidence ledger; writes nothing except its own JSON/MD results.

Evidence timestamp (fixed, = max EndTime): 2026-08-13T18:04:12Z

| Band | Job | State | Exit | RunTime | Output sha256 |
|---|---|---|---|---|---|
| lw | 4515 | COMPLETED | 0:0 | 00:52:34 | `a3d93d3eb4e69894862fad682563d25a5636e7dbbcc59c197ecaa1cceb6f24b4` |
| sw | 4516 | COMPLETED | 0:0 | 00:43:55 | `8b54392eeddd303299881d6405dcf3de4d738667a3dfe605964a64863e2fbee4` |

## Pass status (exact facts; never "all converged")

| Band | Pass | Terminal record |
|---|---|---|
| lw | relative-base | Iteration 2999: cost function = 16.7768, gradient norm = 0.114057 -> Convergence status: Maximum iterations reached |
| lw | relative-ch4 | Iteration 2999: cost function = 1.83547, gradient norm = 0.093339 -> Convergence status: Maximum iterations reached |
| lw | relative-n2o | Iteration 840: cost function = 0.417307, gradient norm = 0.000438281 -> Convergence status: Converged |
| lw | relative-cfc | Iteration 71: cost function = 0.023528, gradient norm = 0.000460102 -> Convergence status: Converged |
| sw | relative-base | Iteration 1999: cost function = 66.3659, gradient norm = 0.384829 -> Convergence status: Maximum iterations reached |
| sw | relative-ch4 | Iteration 203: cost function = 4.56198, gradient norm = 0.000410846 -> Convergence status: Converged |
| sw | relative-n2o | Iteration 132: cost function = 0.253514, gradient norm = 0.000465887 -> Convergence status: Converged |

PASS-STATUS FACTS (binding monitor correction 2026-08-13): LW relative-base and relative-ch4 terminated at the optimizer's iteration cap (Iteration 2999, "Maximum iterations reached"), as did SW relative-base (Iteration 1999); only LW relative-n2o (840) / relative-cfc (71) and SW relative-ch4 (203) / relative-n2o (132) report "Converged". It is NEVER claimed that all passes explicitly converged. Iteration caps are the upstream optimizer's own terminal state (child exit 0, outputs written); binding scientific acceptance belongs to the downstream consumers (G1 objective ratio, weight rel-L1).

## Gates

| Gate | Result |
|---|---|
| consumer_validator_selfcheck | passed |
| evidence_commit_ancestry | passed |
| evidence_executor_source_pin | passed |
| evidence_lw_canonical_output | passed |
| evidence_lw_dual_receipts | passed |
| evidence_lw_runroot_contents | passed |
| evidence_lw_sbatch_pin | passed |
| evidence_lw_terminal_log | passed |
| evidence_sw_canonical_output | passed |
| evidence_sw_dual_receipts | passed |
| evidence_sw_runroot_contents | passed |
| evidence_sw_sbatch_pin | passed |
| evidence_sw_terminal_log | passed |
| fixtures | passed |

Receipt custody: dual-custody receipts: session 40's watcher and Agent 42's watcher each captured scontrol show job -dd at first terminal observation with atomic O_CREAT|O_EXCL (noclobber) create-once semantics onto DISTINCT suffixed paths (-session40 / -agent42); for this attempt the two captures are byte-identical per band (equal pinned sha), unlike the 4503 single-path overwrite incident this protocol was adopted to prevent

Submission: both jobs submitted EXACTLY ONCE by session 40 directly under the monitor's g3_recovery_go #2 (2026-08-13; "This GO is for these two submissions only"); no retries, Restarts=0 bound from both receipts
