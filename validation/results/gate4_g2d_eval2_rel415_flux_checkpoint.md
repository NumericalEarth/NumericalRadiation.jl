# Gate-4 G2d evaluation2 rel-415 flux checkpoint

Status: **g2d_checkpoint_waiting_for_g2c**

script generation only; nothing submitted by this unit; rayleigh + LBL evaluation only; no optimizer, objective, floor, or recovery computation.

| Gate | Result |
|---|---|
| atomic_rayleigh_publication | passed |
| g2c_spectra_prerequisite | failed |
| headnode_refusal_guard | passed |
| lbl_and_rayleigh_only | passed |
| lw_indir_retarget | passed |
| path_contract_honored | passed |
| pipeline_parity | passed |
| rgb_band_grid_14300_variant | passed |
| sbatch_written_not_submitted | passed |
| ssi_stays_evaluation1 | passed |
| stale_output_refusal_and_partial_raw_guard | passed |

Path contract (two-phase): generate in work-eval2, install to `/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5`, `/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5`, and `/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work-v14/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5` (see JSON rationale).

Rayleigh: eval2 SW rayleigh is not published anywhere (S3 archive and ECPDS both lack it); generated in-job by the upstream author's make_rayleigh_evaluation.sh recipe into the fetched eval2 tree, mirroring evaluation1's official layout; sha256s echoed in the job log

eval2 spectra present at generation: 25/70

Provenance: branch `glw/gate4-recovery`, generated_from_head `9f80ed1` (pre-own-commit).

## Failures

- eval2 spectra incomplete: 25/70 (G2c pending?)
