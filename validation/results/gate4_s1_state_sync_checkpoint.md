# Gate-4 S1 triple-arm state-sync hypothesis-test checkpoint

Status: **s1_checkpoint_ready**

triple-arm (A0a/A0b pristine control repeats sharing ONE saved binary, S1 one-line sync patch) from ONE source copy, one configure matching the extant 4515-era build (--with-adept --with-netcdf ONLY, string asserted), sequential builds with immutable saved binaries, SANDWICH execution order A0a -> S1 -> A0b, independent testcopy/work/log clones per arm, identical staged inputs/options/preloads and explicit OpenMP controls (OMP_NUM_THREADS=SLURM_CPUS_PER_TASK, OMP_DYNAMIC=FALSE, logged per arm); A0a-vs-A0b establishes the repeatability floor across the full treatment interval, A0-vs-S1 is primary, historical 4515 is an informational echo unless the A0 arms match it

| Gate | Result |
|---|---|
| evidence_adept_toolchain_pins | passed |
| evidence_input_pins | passed |
| evidence_modern_source_pins | passed |
| evidence_reviewed_b0_ledger | passed |
| evidence_runtime_pins | passed |
| evidence_sbatch_bash_syntax | passed |
| evidence_sbatch_text_gates | passed |
| evidence_toolchain_fingerprints | passed |
| fixtures | passed |

Patch pins: original `8c9822fac6e6efebadc3fd76c104fe563236221ca6297922e5e8a9467ee32091` -> patched `c23246d53a474540443a0e877992dc0d24cfda1ad6cbafa218e3a824cb72070b` (region 305-320 `cb0c801d9875acf0a76c315e0eb2ec5aec0d723f641beff0341527838216d30c`); tree manifest `a96e78e818e5343bead52a1d2ebf52436f8c0e0e67033bb314b6a00530a93aeb` (119 files)

Generated sbatch: `/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/results/gate4_s1_lw_state_sync.sbatch` sha256 `aba1d263fbacbdc8ce33f51a51d620e13c1698d24c87ae7e2c001088a0bf9ba5`

Pre-registered outcome matrix:
- A0a == A0b and S1 == A0a: sync had no effect in this paired deterministic trajectory
- A0a == A0b and S1 differs: patch-associated output change under a deterministic control trajectory; still report hash, exact effective-bound census, and external objective separately
- A0a != A0b: byte-level treatment inference is INCONCLUSIVE because baseline repeatability failed; S1 metrics are descriptive only
- historical 4515 comparison (4205489923dbc50c3c148a06f20e5781b3f1dbeb5a13d55d36b460c5f7b4378c) is a bridge ONLY if the rebuilt A0 arms match it; otherwise historical hash differences are non-causal (informational echo; 4515 executed the pre-existing binary 6c3600fe6001d92e0d067cde1d57f19c82bae0c208a32dd2c48cd77031c05692 via a wrapper named optimize_lut_h5preinit_v12)
- persistent effective-bound exceedances in S1 -> sync alone does not explain them; mapping/write behavior remains open
