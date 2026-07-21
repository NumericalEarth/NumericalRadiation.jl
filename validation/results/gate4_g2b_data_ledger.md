# Gate-4 G2b data ledger: SW-RGB minor+present training fluxes

Status: **sw_rgb_minor_training_fluxes_installed_and_verified**

Job **4104** (`g4-g2b-sw-rgb-minor`) COMPLETED, `G2b done rc=0` at
2026-07-21T08:42:43Z (~9 h 40 m). The stage-0 partial-RAW guard fired,
removing the canceled-4103 header-size partial before regenerating. Data
provenance record only; no optimizer/objective/floor/recovery computation.

## Generation provenance

Isolated `testcopy-rgb-g2b` from the pinned v1.2 artifact; same `ckdmip_sw`
binary as jobs 4078/4100; identical 9-band RGB grid to G2a (14300-variant);
scenarios present + ch4-{350,700,1200,2600,3500} + n2o-{190,270,405,540},
all supported by run_sw_lbl_evaluation.sh; Julia concat + reuse-skip
pipeline.

## Installed files (exact ten)

Location: `/shared/home/greg/data/ckdmip/evaluation1/sw_fluxes-rgb/`
(16 total now: 6 G2a rel + 10 G2b)

| File | Size | sha256 |
|---|---|---|
| present | 1,839,369 | `ceb5872d…736ab4b5` |
| ch4-350 | 1,839,368 | `d15967da…0726a7a2` |
| ch4-700 | 1,839,368 | `9c355b0c…830c987a` |
| ch4-1200 | 1,839,378 | `f31d7c56…d6ba2493` |
| ch4-2600 | 1,839,378 | `c22671d4…3329e53c` |
| ch4-3500 | 1,839,378 | `300adb48…9dfb3034` |
| n2o-190 | 1,839,369 | `d7bac1bc…def947fe` |
| n2o-270 | 1,839,369 | `551c532d…4799cad5` |
| n2o-405 | 1,839,369 | `d76927da…f59a37a5` |
| n2o-540 | 1,839,369 | `aac07193…e2452f01` |

Verification: exact-10 in-job gate before install; workdir↔installed `cmp`
byte-identical (in-job + repeated post-run); sha256 log-echo = local
post-run, all ten.

## SW optimizer training data: COMPLETE (evaluation1)

Every rgb file the SW passes reference is installed — rel-base×6 (G2a) +
present/ch4×5/n2o×4 (G2b).

## Remaining blockers for the optimizer

1. evaluation2 rel-415 both bands (`TRAINING_BOTH=yes`) for faithful
   `-32b` G3 acceptance — Greg's data ruling still pending (ECPDS 404;
   local gen needs the evaluation2 spectra download).
2. optimize_lut H5open-preinit FP-trap shim (same mechanism as scale_lut).
3. LW optimizer data already complete (fsck uses the plain evaluation1
   fluxes from job 4078).
4. Review of this ledger on origin.
