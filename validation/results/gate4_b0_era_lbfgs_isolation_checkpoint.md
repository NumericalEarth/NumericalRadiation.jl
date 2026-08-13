# Gate-4 B0 era-LBFGS isolation checkpoint

Status: **b0_checkpoint_ready**

B0 mechanism isolation: same ce057079 init (min/max arrays retained; controlled max_iterations=1 schema-open probe REFUSES rather than strips), same seven pinned training fluxes, exact 4515 relative-base config; ONLY the optimizer mechanism changes to the pinned v1.0/b42e5c0 solve_lbfgs backend built in-job. PRIVATE output under g4-diag; zero canonical writes; submission HELD for monitor review.

| Gate | Result |
|---|---|
| evidence_era_source_pins | passed |
| evidence_input_pins | passed |
| evidence_reviewed_run_ledger | passed |
| evidence_runtime_and_build_stack | passed |
| evidence_sbatch_bash_syntax | passed |
| evidence_sbatch_text_gates | passed |
| fixtures | passed |

Era pins: commit `b42e5c0b188f1e7b747990bc2b35e6c53c2c7258` tree `0d2a0454f758de7bec04790c1ece54551e465b94` archive `801542f43e6d9c0f444d6966fbe30d28fc3df7aabf147551c4485f352fbafa22`

Generated sbatch: `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_b0_lw_era_lbfgs.sbatch` sha256 `1339163ed81e6596a7e8555037387ac555a72b99ed4a0d41665e7ae59c73d9c0`
