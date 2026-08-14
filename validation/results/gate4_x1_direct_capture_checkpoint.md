# Gate-4 X1 direct post-minimize state-capture checkpoint

Status: **x1_checkpoint_ready**

paired direct-capture instrument test from ONE pinned source/configure tree and TWO immutable saved binaries: 1-iteration PROBE (X1 binary; sidecar schema/rows/order/types/status/Axis-C Float32 readback validated fail-closed BEFORE any full arm), PRISTINE full-run control, X1 full run instrumented. The X1 patch is bounds-ON only (unbounded branch gated byte-identical); the capture executes strictly post-minimize; NON-PERTURBATION IS AN EMPIRICAL ALL-VARIABLE IDENTITY GATE against the in-job pristine arm, never a construction claim. Zero canonical writes; RUNROOT preserved as forensics; no submission without explicit monitor GO.

| Gate | Result |
|---|---|
| evidence_adept_toolchain_pins | passed |
| evidence_frozen_design_file | passed |
| evidence_input_pins | passed |
| evidence_modern_source_pins | passed |
| evidence_reviewed_s1_completion_ledger | passed |
| evidence_runtime_pins | passed |
| evidence_s1_ledger_commit_pin | passed |
| evidence_sbatch_bash_syntax | passed |
| evidence_sbatch_text_gates | passed |
| evidence_toolchain_fingerprints | passed |
| fixtures | passed |

Frozen design: `d4f8a689aa4fcadb91922120b7806939bba88c115fb6281d51b2fc3dbe325398` (durable file `validation/gate4_x1_frozen_design.md`)

Patch pins: original `8c9822fac6e6efebadc3fd76c104fe563236221ca6297922e5e8a9467ee32091` -> patched `7405c87905aae02971476e4b7585ce8267c28ce01fab216be12a938bdd7b0fa1` (TWO anchored edits, +4 lines; capture region 365-372 `6181b7735fb1ed3612d56fa7127448289d24854ab5a86172dd915f7a2a839040`; unbounded else-to-EOF tail byte-identical `df4d69a8f597ed1182b353bc98731bbcefd528950cef2bb8f2974ee9be0b6848`; gate4_x1:: calls exactly 2, both in-region); helper `src/ecckd/gate4_x1_capture.h` `183d8a534781e6378ee40ce348402ec491beaa1b58357a7f26560a6c57ec1872`; tree manifest `a96e78e818e5343bead52a1d2ebf52436f8c0e0e67033bb314b6a00530a93aeb` (119 files)

Generated sbatch: `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_x1_lw_direct_capture.sbatch` sha256 `12b7bfeb5d20b595bd755436fa45a2e82a887febd999787e155385730b1c1e88`

Prerequisite (fail-closed, sha-chained): S1 completion ledger `de5b349e07b1f085e01f8a8fe6902ea50ac9ecce0821844ae99d8b3f9f40a586` (s1_run_completed_verified; commit 5b6cea7e97d552f0f2bbf80dbd5c998db065ddd4)

Fixtures: 103 (103 passed)

Run order: PROBE (1 iteration, fail-closed sidecar validation) -> PRISTINE control -> X1 instrumented; identity gate decides non-perturbation; violation = instrument refusal (exit 95).
