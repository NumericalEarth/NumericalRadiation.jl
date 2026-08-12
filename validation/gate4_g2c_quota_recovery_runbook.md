# Gate-4 G2c quota-recovery runbook

**This runbook executes nothing.** It documents two recovery paths as
executable-but-NOT-run command sequences. No `rm`, no quota change, and no
job submission may be run from this document without Greg's explicit
authorization of the chosen path. Written after job 4440
(`gate4_g2c_failure_ledger_4440`) and quota-guard v2 (`8f2e874`,
`f4dde95`).

## Current state (2026-08-12)

- uid quota on /shared: soft 900 GiB (EXCEEDED, grace ~6d23h from
  08-12; when grace expires ALL writes by uid greg fail until usage
  < 900 GiB), hard 1000 GiB, used ~967 GiB.
- Live guard: `headroom≈35.2 GB` vs `need=197,531,202,236 B`
  (remaining 154,581,529,276 B + 40 GiB margin) → REFUSED; checkpoint
  status `g2c_checkpoint_blocked_by_quota`.
- 30/70 eval2 spectra finalized (175,407,705,620 B, exact-size verified
  against the audited manifest); fetch sbatch is resumable as-is.

## Path A — quota raise (recommended; preserves everything)

1. **Admin action (Greg / cluster admin):** raise the uid limits, e.g.
   ```
   sudo lfs setquota -u greg -b 1288490189 -B 1395864371 /shared
   ```
   (ADMIN-ONLY, ILLUSTRATIVE: short options `-b`/`-B` per the installed
   `lfs setquota --help`; values are KiB block limits — soft 1.2 TiB stops
   the running grace clock, hard 1.3 TiB covers the fetch need +
   rayleigh/G2d/G3 outputs + margin. The admin must confirm site policy
   and unit conventions before running.)
2. **Revalidate (read-only):**
   ```
   lfs quota -h -u greg /shared
   cd /shared/home/greg/Projects/AnalyticBandRadiation-platform
   bash -c 'source validation/gate4_quota_guard.sh; quota_guard \
     /shared/home/greg/data/ckdmip/evaluation2 \
     validation/gate4_eval2_selected_manifest.tsv $((40*1024*1024*1024))'
   # expect: quota-guard: ... + exit 0
   julia --project=test validation/gate4_g2c_eval2_fetch_checkpoint.jl
   # expect: g2c_checkpoint_ready (live gate flips)
   ```
3. Commit the ready-state checkpoint results, push, then submit the
   existing resumable sbatch (`sbatch validation/results/gate4_g2c_eval2_fetch.sbatch`)
   — its own stage-0 guard re-verifies quota before any transfer, and
   `aws s3 sync` resumes from the 30 preserved finals.

## Path D — authorized cleanup fallback: idealized spectra ONLY

**Scope (monitor-reviewed): `/shared/home/greg/data/ckdmip/idealized/{lw_spectra,sw_spectra}` only.**
66 files / 217,901,253,443 B (~202.9 GiB). PRESERVE `idealized/conc`
(local-only, not in the S3 prefix) and ALL of `evaluation1/` —
**correction to the 4440 ledger: evaluation1 spectra are NOT in the
current S3 archive** (only evaluation2 + idealized are; eval1's upstream
source is ECPDS, but with no verified same-cloud copy it must be
preserved, not deleted).

Restore source (verified live, exact): `s3://aeolus-dev/users/greg@aeolus.earth/ckdmip/idealized/`
— exact 66-name + Size metadata match (live S3 listing vs local stat),
0 mismatches (independent checks by assistant and monitor, 2026-08-12).
This is a name+size identity, NOT a checksum verification: S3 multipart
ETags are not content hashes.

Dependency proof (recorded):
- G2d's generated sbatch: zero `idealized` references.
- Pinned `optimize_lut_{lw,sw}.sh` and `run_{lw,sw}_lbl_evaluation.sh`:
  zero `IDEALIZED` references — the optimizer consumes the accepted WORK
  init/gpoints and TRAINING/WORK flux dirs only.
- idealized spectra fed only the COMPLETED create_lut init/proof stages
  (jobs 4091/4096 via the create_lut append_path; outputs exist,
  hash-pinned). A2 find_g_points consumed MMM+reordered spectra, and the
  pinned scale_lut has no IDEALIZED reference.
- CAVEAT for the G3 executor: the historical broad
  `ckdmip_training_data_preflight` requires idealized directories to
  exist and would report red after this cleanup. The G3 executor MUST
  gate on a scoped actual-input preflight (its real inputs: inits,
  gpoints, flux dirs, quota guard) instead of that layout check. This
  requirement is binding on the G3 spec.

Dry-run verification BEFORE any deletion (read-only):
```
find /shared/home/greg/data/ckdmip/idealized/lw_spectra -maxdepth 1 -type f | wc -l  # 33 (32 .h5 + hidden .ecpds_mkdir.txt)
find /shared/home/greg/data/ckdmip/idealized/sw_spectra -maxdepth 1 -type f | wc -l  # 33 (32 .h5 + hidden .ecpds_mkdir.txt)
ls /shared/home/greg/data/ckdmip/idealized/lw_spectra/*.h5 | wc -l  # 32
ls /shared/home/greg/data/ckdmip/idealized/sw_spectra/*.h5 | wc -l  # 32
du -sb /shared/home/greg/data/ckdmip/idealized/{lw_spectra,sw_spectra}
aws s3 ls s3://aeolus-dev/users/greg@aeolus.earth/ckdmip/idealized/lw_spectra/ --summarize | tail -2
aws s3 ls s3://aeolus-dev/users/greg@aeolus.earth/ckdmip/idealized/sw_spectra/ --summarize | tail -2
# rerun the exact per-name/size comparison before authorizing:
#   (assistant will re-verify on request; comparison script in session log)
```
The deletion command is left unwritten by design: it must be typed by (or
explicitly delegated by) Greg after Path D authorization.

Quota arithmetic after Path D: used ~967 GiB − 202.9 GiB ≈ 764 GiB →
below the 900 GiB soft limit (grace clock cleared); hard headroom
~236 GiB (~253 GB) vs the 197.5 GB guard need — sufficient, with ~56 GB
spare for rayleigh/G2d/G3 outputs (tighter than Path A; another reason A
is primary).

## Post-recovery sequence (either path)

G2c completes (exact-70 + sync-convergence) → G2c fetch ledger commit →
G2d checkpoint flips `waiting_for_g2c` → `ready` → submit G2d (rayleigh +
two rel-415 LBL runs → quarantine presence gate → cmp-verified installs)
→ G2d ledger → G3 executor spec review. Optimizer remains blocked until
all of that is ledgered and reviewed.
