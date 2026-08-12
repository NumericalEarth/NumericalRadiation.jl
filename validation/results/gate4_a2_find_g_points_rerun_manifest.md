# Gate-4 A2 find_g_points rerun-with-proof manifest

Status: **a2_manifest_ready_waiting_for_inputs**

dry-run A2 manifest only; no find_g_points, create_lut, objective, floor, or recovery computation.

| Gate | Result |
|---|---|
| a1_recon_prerequisite | passed |
| acceptance_hinge_exact_reproduction | passed |
| future_outputs_named | passed |
| no_heavy_execution | passed |
| pinned_scripts_discovered | passed |
| pinned_source_scripts_readable | passed |
| prerequisite_loader_fixture_tests | passed |
| required_inputs_enumerated | passed |
| runtime_estimate_recorded | passed |
| unproven_reruns_sensitivity_only | passed |

## Stage readiness

| Stage | Present/Expected | Ready |
|---|---|---|
| find_g_points | 5/5 | true |
| create_lut_proof | 0/2 | false |

find_g_points prerequisites are currently COMPLETE; the overall rerun-with-proof manifest waits only on the absent create_lut proof-stage idealized spectra (the registered Path-D deletion scope)

## Required inputs (5/7)

- [present] [stage: find_g_points] pinned find_g_points binary: `/shared/home/greg/ecckd-derived-flux-work/ecckd/src/ecckd/find_g_points`
- [present] [stage: find_g_points] pinned reorder_spectrum binary: `/shared/home/greg/ecckd-derived-flux-work/ecckd/src/ecckd/reorder_spectrum`
- [present] [stage: find_g_points] MMM LW median spectra: `/shared/home/greg/data/ckdmip/mmm/lw_spectra` (glob: median)
- [present] [stage: find_g_points] MMM SW median spectra: `/shared/home/greg/data/ckdmip/mmm/sw_spectra` (glob: median)
- [MISSING] [stage: create_lut_proof] idealized LW spectra (create_lut PROOF stage, not find_g_points): `/shared/home/greg/data/ckdmip/idealized/lw_spectra`
- [MISSING] [stage: create_lut_proof] idealized SW spectra (create_lut PROOF stage, not find_g_points): `/shared/home/greg/data/ckdmip/idealized/sw_spectra`
- [present] [stage: find_g_points] MMM SSI: `/shared/home/greg/data/ckdmip/mmm/sw_spectra_extras/ckdmip_ssi.h5`

## Acceptance hinge

rerun gpoints.h5 + raw create_lut output must EXACTLY reproduce the published gpoint_fraction and band support arrays (wavenumber1/2_band, band_number) AND the g-counts (32 LW fsck / 32 SW rgb) BEFORE any floor use

If not exact: outputs are SENSITIVITY-ONLY; they cannot feed the acceptance floor unless Greg explicitly changes the optimizer-only-delta rule

Runtime estimate: 1-4 h per band per tolerance on cpu-large (60 GB, 16 cpu); tolerance loop multiplies -- run the published-matching tolerances first (Slurm cpu-large, never the head node)

Provenance: branch `glw/gate4-recovery`, generated_from_head `5114d66` (pre-own-commit).
