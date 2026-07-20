# Gate-4 SW init failure ledger: job 4097

Status: **sw_init_job_4097_failed_no_outputs**

Job 4097 FAILED at `scale_lut_sw.sh` line 76:
`/home/parr/src/ckdmip-1.1/bin/ckdmip_sw: No such file or directory`.
Stage-0 had PASSED (both input hash checks OK). No partial state: the LBL
flux dir is empty and no scaled definition was produced — the failure was
atomic before any output.

Root cause: the pristine v1.4 clone's `test/config.h` hardcodes the
upstream author's `CKDMIP_DIR=/home/parr/src/ckdmip-1.1`; the R2 sed patch
localized five vars but not `CKDMIP_DIR`. The R2 create_lut run never
invokes `$CKDMIP_SW`, so the bad path stayed latent; scale_lut's
self-generated LBL reference is the first testcopy-v14 stage that calls it.
The v1.2-derived testcopy never hit this because the May workcopy's
config.h had been manually localized.

Fix: sed-patch `CKDMIP_DIR=/shared/home/greg/build/ckdmip-1.0` in
testcopy-v14 (fixes TOOL/LW/SW in one stroke), grep-verify, and preflight
the `ckdmip_sw` executable; new checkpoint gates `ckdmip_dir_localized`
and `ckdmip_sw_executable_preflight`.

Acceptance impact: none — promoted raw inits untouched, no scaled init
exists yet; G2/G3 remain blocked pending clean scaled-init hash review.
