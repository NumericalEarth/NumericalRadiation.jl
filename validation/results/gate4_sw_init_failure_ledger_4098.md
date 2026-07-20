# Gate-4 SW init failure ledger: job 4098

Status: **sw_init_job_4098_failed_sigfpe_in_hdf5_init**

Slurm: FAILED, ExitCode=1:0. Stage-0 passed (incl. the 4097-fix gates).
Produced: the LBL scaling reference
`ckdmip_mmm_sw_fluxes-raw_present_1.h5` (278,589,318 B, sha256
`ef9df390…d931acd`) — generated in-job from official MMM median inputs
before the crash, deterministic and reusable. NO scaled definition: the
scaled log is 176 bytes ending at the raw CKD definition read.

## Root cause (locally reproduced)

Identical command against scratchpad paths: **SIGFPE, exit 136**, core
dumped immediately after "Reading CKD definition file". gdb crash site:
`H5T__init_native_float_types` (HDF5 1.14, libhdf5.so.310) ←
`H5_init_library` ← `nc_open` ← `DataFileEngineNetcdf.cpp:50`.
Mechanism: `scale_lut.cpp:49` enables
`feenableexcept(FE_INVALID|FE_DIVBYZERO|FE_OVERFLOW)` before any file is
opened; HDF5 1.14's float-type detection intentionally raises FE_INVALID
under enabled traps, aborting the first `nc_open`. `create_look_up_table`
does not enable traps — which is why R2 job 4096 was clean on the same
stack. `optimize_lut` also enables traps: the same mitigation will be
needed at the optimizer stage.

## Fix (execution-environment shim; no scientific/numerical change)

- v1.4 `scale_lut` binary UNCHANGED, sha256 `a2d121b2…f12cc2`.
- Shim source, verbatim (its entire code):
  `#include <hdf5.h>` /
  `__attribute__((constructor)) static void init_h5_before_traps(void) { H5open(); }`
  — one ELF constructor calling HDF5 library init before `main()`;
  references nothing else, intercepts nothing, cannot alter arithmetic.
- Compiler command recorded in the JSON; the .so is rebuilt in-job from
  the embedded source and its sha256 echoed at stage-0.
- Injected ONLY for the scale_lut invocation via a wrapper (sed-patched
  `SCALE_LUT` in testcopy-v14 config.h) that sets LD_PRELOAD and execs the
  pinned binary.
- Verification: shim-preloaded scale_lut ran to completion (exit 0)
  against scratchpad output paths, printing per-g scalings and closing
  its output cleanly; no campaign artifact paths touched.

Acceptance impact: none — promoted raw inits untouched; no scaled init
yet; G2/G3 remain blocked pending clean scaled-init hash review.
