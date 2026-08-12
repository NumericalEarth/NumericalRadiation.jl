# Gate-4 G2c failure ledger: job 4440 (disk quota)

Status: **g2c_job_4440_failed_disk_quota**

Job 4440 FAILED (NonZeroExitCode, ExitCode=1:0, 00:10:42, 07:51:25–08:02:07
UTC). Stage 0 passed (compute-node AWS auth proven; df-based check passed);
stage 1 LW sync aborted when the five `o3_present` chunks failed with
`[Errno 122] Disk quota exceeded`; stage 2 (SW) never began. Nothing
deleted; 30 finalized LW files preserved (atomic aws-cli publication, no
temps on disk).

## Root cause

Per-user Lustre quota, invisible to `df`: `lfs quota -u greg /shared` =
used ~967 GiB (over the 900 GiB soft limit, grace 6d23h), hard limit
1000 GiB. Headroom measured post-failure (after the AWS CLI removed its partial temp files; usage transiently reached the hard boundary at the EDQUOT event): **32.83 GiB** vs **143.97 GiB** still needed
— shortfall ~111 GiB before rayleigh (~4.5 GB) and G2d outputs. The
preflight checked filesystem free space (1.9 TB) but not uid quota.

## Exact accounting (monitor-verified from live S3 metadata)

Source set 70 files = 329,989,234,896 B (LW 219,614,131,381 + SW
110,375,103,515). Local finalized 30 files = 175,407,705,620 B. Remaining
= 154,581,529,276 B. Hard headroom = 35,246,998,528 B. Shortfall =
119,334,530,748 B. S3 ETags are multipart (`-N` suffix) — opaque
provenance strings, not MD5.

## Cleanup-candidate inventory (read-only; nothing authorized)

CORRECTED (follow-up): evaluation1 spectra 383 GiB are NOT in the current
S3 archive (S3 holds only evaluation2 + idealized) — PRESERVE; eval1
sw_spectra also carries the G2d-required ckdmip_ssi.h5. idealized spectra
202.9 GiB (66 files; LW 133G + SW 71G) are the only verified-restorable
candidate (exact name+size match vs the S3 idealized prefix, live
2026-08-12; preserve idealized/conc). evaluation2 partial 164 GiB (KEEP);
mmm 44 GiB (KEEP); Gate-4 work 20 GiB (KEEP).

## Recovery options

- **A (recommended)**: raise uid hard limit to ≥1.3 TiB — preserves
  everything; needs Greg/admin (`lfs setquota` / pcluster config).
- **B**: alternate path under a different quota — none exists (uid quota
  covers all of /shared).
- **C**: chunk-streaming redesign (~44 GB peak) — still exceeds current
  headroom; only after partial cleanup + explicit review.
- **D (verified fallback)**: authorized deletion of idealized
  {lw,sw}_spectra ONLY (202.9 GiB; exact-match restorable from the S3
  idealized prefix; preserve idealized/conc and ALL evaluation1) — clears
  the shortfall; requires the G3 executor to use a scoped actual-input
  preflight; NOT executed. See gate4_g2c_quota_recovery_runbook.md.

## Checkpoint correction

Implemented and tested: `validation/gate4_quota_guard.sh` (fail-closed
parse of the lfs aggregate row, KiB→bytes, deliberate refusal on hard=0/
unlimited, remaining = audited source bytes − matching finalized files,
requires headroom ≥ remaining + 40 GiB) sourced by the regenerated sbatch
alongside the retained df guard; gates `quota_aware_preflight` +
`quota_guard_fixture_tests` (7/7 fixture verdicts pass, incl. the
subtraction verdict pair with a sparse 10 GiB expected file).
No retry under the current hard limit; G2d and optimizer remain blocked.
