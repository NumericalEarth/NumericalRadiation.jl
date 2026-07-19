# Gate-4 A2 failure ledger: job 4079

Status: **a2_job_4079_failed_non_acceptance**

Failure event record only; no generation, objective, floor, or recovery
computation in this unit.

Job 4079 FAILED at its first stage (LW reorder) ~3 minutes after start and
left the queue at 2026-07-19T05:59:07Z. Log evidence
(`/shared/home/greg/data/ckdmip-logs/g4-a2-4079.log`): `reorder_spectrum`
aborted because
`work/lw_spectra/ckdmip_mmm_lw_spectra_composite_present.h5` did not exist
in the quarantined WORK_DIR.

## Root cause

1. **Primary**: the generated sbatch skipped do_all stage 1
   (`merge_well_mixed_lw.sh` / `merge_well_mixed_sw.sh`), so the composite
   spectra consumed by reorder were never created in the fresh quarantined
   WORK_DIR. Not a path-localization problem — the sed-patched paths were
   correct and echoed in the log.
2. **Secondary (latent)**: the SW chain also requires
   `ckdmip_mmm_sw_spectra_rayleigh_present.h5`
   (`COMPOSITE_SW_INCLUDES_RAYLEIGH=yes` in the pinned config), absent from
   the local MMM tree and 404 on ECPDS.
3. **Third (latent)**: pristine `CLOUD_SPECTRUM=../data/mie_droplet_scattering.nc`
   is test-dir-relative and breaks in the relocated TESTCOPY (used by the
   cloud reorder at the end of `reorder_spectrum_sw.sh`).

## Recovery (applied to the checkpoint generator before resubmission)

- Stage order per band now matches pinned do_all: merge → reorder →
  find_g_points; still NO create_lut/optimize/objective/floor executable
  lines.
- SW rayleigh provisioned in a **quarantined input overlay**
  (`$G4WORK/input/mmm/sw_spectra`: symlinks to official per-gas files +
  generated rayleigh); `MMM_SW_SPECTRA_DIR` sed-patched to the overlay; the
  official data tree is never written to. Recipe provenance: upstream
  author's own `ckdmip-1.0/work/sw/make_rayleigh_mmm.sh` —
  `ckdmip_tool --grid <mmm sw h2o_median> --rayleigh`.
  Tool sha256 `2334730b…159c44cd`; grid input sha256 `3ec54991…6098ea40`;
  generated-file sha256 `36ad9c9a…ebdad2` (recorded post-run from the 4082
  log; attempt 2 completed rc=0 with this overlay in effect). Any residual
  deviation is caught by the elementwise-EXACT rayleigh/solar comparisons
  in the reproduction-proof scaffold.
- `CLOUD_SPECTRUM` sed-patched absolute to the workcopy's
  `data/mie_droplet_scattering.nc`.
- Stage-0 in-job preflight: all per-band merge/reorder/find inputs
  (7 well-mixed gases, h2o/o3 median AND minimum), MMM SSI extra, mie file,
  evaluation1 TRAINING_SW_SSI, six required binaries; `test -s` on the
  overlay rayleigh after generation.

## Acceptance impact

NONE promoted: 4079 produced no gpoints candidates; the reproduction-proof
scaffold remains at `a2_proof_scaffold_ready_waiting_for_candidates`.

Provenance: branch `glw/gate4-recovery`, HEAD at failure `42a74c3`;
attempt-1 record in `gate4_a2_submission_ledger.json`.
