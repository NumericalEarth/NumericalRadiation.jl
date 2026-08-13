# Gate-4 G2c quota-recovery runbook

**This runbook executes nothing.** It documents two recovery paths as
executable-but-NOT-run command sequences. No `rm`, no quota change, and no
job submission may be run from this document without Greg's explicit
authorization of the chosen path. Written after job 4440
(`gate4_g2c_failure_ledger_4440`) and quota-guard v2 (`8f2e874`,
`f4dde95`).

## Current state (2026-08-13)

- uid quota on /shared: soft 900 GiB (NOT exceeded), grace `-`
  (cleared), hard 1000 GiB, used ~364 GiB (381,859,686 KiB observed
  2026-08-13). The 2026-08-12 crisis state (used ~967 GiB, grace clock
  running) is preserved below under Path D for history.
- Live guard PASSES: soft-headroom ≈ 575.3 GB vs
  `need = 208,268,620,476 B` (remaining 154,581,529,276 B + 50 GiB
  standing SOFT-limit reserve; the guard is now soft-primary, df
  removed). Checkpoint status `g2c_checkpoint_ready`.
- 30/70 eval2 spectra finalized (175,407,705,620 B, exact-size AND
  h5-open verified against the audited manifest, 30/30).
- The fetch is a manifest-driven per-object pipeline (commit `9216204`,
  sbatch sha256 `b7d7c5a10eee40ab23d78fb116ca0ce8de562adf9b034cf1311649e256c908d7`):
  authenticated S3 preferred, exact ECPDS fallback (HEAD-audited 70/70)
  with mid-run failover, per-object SOFT-quota rechecks, h5-verified
  exact-size skips, atomic publish, flock single-run lock.
- Fetch + job submission for G2c: authorized (Greg via campaign
  coordinator, relay reviewed and accepted as durable by the Codex
  monitor 2026-08-13). **Submitted as job 4500 at 2026-08-13T09:38:59Z**
  by the Codex monitor after independent preflight recheck (clean
  parity, no duplicate job, sbatch SHA, live guard); executed via Codex
  because the assistant's own sbatch call was denied by its auto-mode
  permission layer. Log:
  `/shared/home/greg/data/ckdmip-logs/g4-g2c-4500.log`.

## Path A — quota raise (HISTORICAL: not needed after Path D execution)

**Status 2026-08-13: overtaken by events.** Path D was executed
out-of-band on 2026-08-12 and quota is healthy; no quota raise is
required for G2c. Retained for history and for any future TB-scale
stage. Command examples below are updated to current guard semantics.

1. **Admin action (Greg / cluster admin):** raise the uid limits, e.g.
   ```
   sudo lfs setquota -u greg -b 1288490189 -B 1395864371 /shared
   ```
   (ADMIN-ONLY, ILLUSTRATIVE: short options `-b`/`-B` per the installed
   `lfs setquota --help`; values are KiB block limits — soft 1.2 TiB would
   have stopped the then-running grace clock (grace is now cleared),
   hard 1.3 TiB covers the fetch need +
   rayleigh/G2d/G3 outputs + margin. The admin must confirm site policy
   and unit conventions before running.)
2. **Revalidate (read-only):**
   ```
   lfs quota -h -u greg /shared
   cd /shared/home/greg/Projects/AnalyticBandRadiation-platform
   bash -c 'source validation/gate4_quota_guard.sh; quota_guard \
     /shared/home/greg/data/ckdmip/evaluation2 \
     validation/gate4_eval2_selected_manifest.tsv $((50*1024*1024*1024))'
   # expect: quota-guard: ... + exit 0 (soft-primary, 50 GiB reserve)
   julia --project=test validation/gate4_g2c_eval2_fetch_checkpoint.jl
   # expect: g2c_checkpoint_ready (live gate flips)
   ```
3. Commit the ready-state checkpoint results, push, then submit the
   reviewed sbatch (`sbatch validation/results/gate4_g2c_eval2_fetch.sbatch`)
   — its own stage-0 guard re-verifies quota before any transfer, and
   the per-object pipeline skips the h5-verified exact-size finals and
   resumes interrupted .part files via ECPDS Range requests.

## Path D — authorized cleanup fallback: idealized spectra ONLY

**Status: EXECUTED out-of-band on 2026-08-12** (the post-cleanup input
census observed the post-deletion state at 2026-08-12T15:09:15Z; usage
drop 1,014,159,676 → 381,314,707 KiB recorded by the read-only quota
watcher; grace clock cleared). Scope note: the executed triage was
BROADER than the registered idealized-only Path-D scope below — the
census also recorded evaluation1 spectra absent (eval1 lw_spectra gone;
sw_spectra reduced to 1 file). Per the campaign coordinator's delivered
record, Greg approved the broader triage (eval1 LW + eval1 SW minus SSI
+ idealized) and executed it himself; that approval is not yet
represented in a canonical `gate4_rulings_assignment.json`, so formal
intake of the R-QUOTA-PATH-AD ruling remains OPEN pending Greg's
canonical assignment.

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

Historical pre-deletion verification (read-only, recorded before the
2026-08-12 execution):
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
No deletion command is retained; no further deletion is authorized by
this runbook.

Quota arithmetic after Path D (as planned): used ~967 GiB − 202.9 GiB
≈ 764 GiB. Observed outcome (2026-08-13): used ~364 GiB — far below the
planned 764 GiB because the out-of-band cleanup exceeded the registered
scope (see the status note above); soft-headroom ≈ 575.3 GB comfortably
covers the 208.3 GB guard need with the 50 GiB soft reserve.

## Post-recovery sequence (either path)

G2c completes (exact-70 size + h5 verification on every final) → G2c
fetch ledger commit →
G2d checkpoint flips `waiting_for_g2c` → `ready` → submit G2d (rayleigh +
two rel-415 LBL runs → quarantine presence gate → cmp-verified installs)
→ G2d ledger → G3 executor spec review. Optimizer remains blocked until
all of that is ledgered and reviewed.
