# Gate-4 B0 era-stack completion ledger

Status: **b0_run_completed_verified**

evidence ledger; writes nothing except its own JSON/MD results plus transient private temp fixtures/snapshots (mktempdir); zero campaign/canonical writes.

Evidence timestamp (fixed, = job 4546 EndTime): 2026-08-13T20:38:33Z

## Scientific result (reported; never a completion gate)

| Quantity | Value |
|---|---|
| era raw2 swap objective | 22.788012978663616 |
| published-context self-check | 0.18218645425029933 |
| delta vs raw_init (102.67056437657112; recomputed bit-exact: true) | -79.8825513979075 (ratio 0.2219527390059202) |
| delta vs v12_raw2 (22.791293464348826; recomputed bit-exact: true) | -0.0032804856852095554 (ratio 0.9998560640847198) |
| delta vs recovered_final_lw (22.824890243604344; recomputed bit-exact: true) | -0.03687726494072763 (ratio 0.9983843398786524) |
| delta vs published_pair (0.18218645425029933; recomputed bit-exact: true) | 22.605826524413317 (ratio 125.08072058615288) |

B0 execution completed and the bundled target-era stack is viable, but its fixed-input raw2 still fails the 1.05 objective gate and offers no material recovery versus the v1.2 raw2. This is one deterministic bundled comparison with confounded source/backend/bounds; it is never phrased as statistically equivalent/indistinguishable, backend disproven, hypothesis collapsed, or causality shifted (binding monitor wording 2026-08-13).

## Gates

| Gate | Result |
|---|---|
| evidence_attempt_4540_evidence | passed |
| evidence_attempt_4545_evidence | passed |
| evidence_attempt_4546_evidence | passed |
| evidence_commit_ancestry | passed |
| evidence_comparator_code_pins | passed |
| evidence_comparator_integrity | passed |
| evidence_era_raw2_schema | passed |
| evidence_generator_and_sbatch_pins | passed |
| evidence_job_log_contract | passed |
| evidence_runroot_artifacts | passed |
| fixtures | passed |

## Attempts

| Job | State | Exit | Classification |
|---|---|---|---|
| 4540 | FAILED | 141:0 | stage-0d SIGPIPE (pipefail + version/head pipelines); pre-RUNROOT; fixed and text-gate ban... |
| 4545 | FAILED | 68:0 | designed proof-gate false positive after a green era build (solve_adept.o pulled into the ... |
| 4546 | COMPLETED | 0:0 | COMPLETED to design; base pass at the 3000-iteration cap (first record Iteration 1: cost f... |

Confound note: the b42e5c0..23adaca diff includes optimize_lut.cpp, ckd_model.cpp/.h, lbl_fluxes.cpp, and average_optical_depth, plus build/script changes, the solve_lbfgs backend switch, and removal of the v1.2 bounded minimization -- changed TOGETHER; some underlying files (calc_cost_function_lw.cpp, radiative_transfer_lw.cpp) remain identical across that range. The experiment is never described as single-variable, mechanism-isolated, or backend-confirmed; the token 'isolation' persists only in legacy filenames/case identifiers for path stability.
