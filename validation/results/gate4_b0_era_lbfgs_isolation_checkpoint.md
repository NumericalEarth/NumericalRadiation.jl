# Gate-4 B0 bundled target-era stack viability checkpoint

Status: **b0_checkpoint_ready**

B0 bundled target-era stack viability: same ce057079 init (min/max arrays retained; controlled max_iterations=1 schema-open probe REFUSES rather than strips), same seven pinned training fluxes, exact 4515 relative-base config; the FULL pinned v1.0/b42e5c0 stack is built in-job -- a full executable source version change, including optimize_lut/ckd_model/lbl_fluxes, plus the old solve_lbfgs backend and no v1.2 bounds. Source, backend, and bounds are CONFOUNDED by design: this experiment tests target-era stack viability with fixed init/g-points/training/config and can never prove the backend alone causes any outcome. PRIVATE output under g4-diag; zero canonical writes; submission HELD for monitor review.

| Gate | Result |
|---|---|
| evidence_attempt_4540_evidence | passed |
| evidence_attempt_4545_evidence | passed |
| evidence_era_source_pins | passed |
| evidence_input_pins | passed |
| evidence_reviewed_run_ledger | passed |
| evidence_runtime_and_build_stack | passed |
| evidence_sbatch_bash_syntax | passed |
| evidence_sbatch_text_gates | passed |
| fixtures | passed |

Era pins: commit `b42e5c0b188f1e7b747990bc2b35e6c53c2c7258` tree `0d2a0454f758de7bec04790c1ece54551e465b94` archive `801542f43e6d9c0f444d6966fbe30d28fc3df7aabf147551c4485f352fbafa22`

Generated sbatch: `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_b0_lw_era_lbfgs.sbatch` sha256 `87a529e865633133e9f6d548720c597c5e1021a2143af1a52c17c590ac76e575`
