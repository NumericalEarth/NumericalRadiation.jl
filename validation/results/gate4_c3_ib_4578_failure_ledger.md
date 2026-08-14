# Gate-4 C3-IB job 4578 terminal failure ledger

Status: **c3ib_4578_failed_staging_manifest_gap**

| Field | Value |
|---|---|
| JobState | FAILED (NonZeroExitCode, 134:0) |
| RunTime | 00:38:32 (limit 06:00:00) |
| EndTime | 2026-08-14T15:31:43 |
| Receipt | `f6f3a3618b5207c5e9a6645586cbe65a69038636fcfb2c406bd7dd953797c5c7` (epoch 1786721517) |
| Log | `698cab0bdf65d42ebcd29796e15ece5848d679a9cbf04b4f31d7f5e535f1fbba` |
| First missing input | `ckdmip_evaluation1_lw_fluxes_present.h5` |
| Staged eval1 | 6 of the 20-name selected-mode closure |
| RUNROOT | `/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/g4-diag/4578/lw-c3ib` (preserved, immutable) |

Classification (monitor): staging-manifest completeness gap. ZERO scientific inference; no resubmission without explicit Codex-monitor GO; a fresh job must rerun the full sandwich.
