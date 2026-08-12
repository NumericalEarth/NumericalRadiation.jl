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

evaluation1 spectra 383 GiB (LW 253 + SW 130; S3 byte-verified archive);
idealized 203 GiB (LW 133 + SW 71; S3-sourced; consumed by completed init
generation); evaluation2 partial 164 GiB (KEEP); mmm 44 GiB (KEEP); Gate-4
work 20 GiB (KEEP).

## Recovery options

- **A (recommended)**: raise uid hard limit to ≥1.3 TiB — preserves
  everything; needs Greg/admin (`lfs setquota` / pcluster config).
- **B**: alternate path under a different quota — none exists (uid quota
  covers all of /shared).
- **C**: chunk-streaming redesign (~44 GB peak) — still exceeds current
  headroom; only after partial cleanup + explicit review.
- **D (fast fallback)**: authorized deletion of S3-byte-verified eval1
  spectra (383 GiB) and/or idealized (203 GiB) — either clears the
  shortfall; recoverable from the verified archive; NOT executed.

## Checkpoint correction

Implemented and tested: `validation/gate4_quota_guard.sh` (fail-closed
parse of the lfs aggregate row, KiB→bytes, deliberate refusal on hard=0/
unlimited, remaining = audited source bytes − matching finalized files,
requires headroom ≥ remaining + 40 GiB) sourced by the regenerated sbatch
alongside the retained df guard; gates `quota_aware_preflight` +
`quota_guard_fixture_tests` (7/7 fixture verdicts pass, incl. the
subtraction verdict pair with a sparse 10 GiB expected file).
No retry under the current hard limit; G2d and optimizer remain blocked.
