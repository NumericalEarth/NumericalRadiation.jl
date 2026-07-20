# Gate-4 G2a SW-RGB training-flux checkpoint

Status: **g2a_checkpoint_ready**

script generation only; nothing submitted by this unit; LBL evaluation only; no optimizer, objective, floor, or recovery computation.

| Gate | Result |
|---|---|
| exact6_completeness_gate_before_install | passed |
| headnode_refusal_guard | passed |
| init_ledger_prerequisite | passed |
| lbl_evaluation_only | passed |
| pipeline_parity_with_4078 | passed |
| rgb_band_grid_14300_variant | passed |
| rgb_not_published_upstream_recorded | passed |
| sbatch_written_not_submitted | passed |
| stale_output_refusal | passed |
| testcopy_from_pinned_artifact | passed |

Band grid: 9-band 14300/16650/20000/25000/31750 variant activated; optimize_lut_sw maps 9 LBL bands to 5 CKD rgb bands via '0 0 0 0 1 2 3 4 4' which collapses exactly onto WN1_SW_RGB='250 14300 16650 20000 25000'; create_lut_sw uses base_wavenumber_boundary=14300

Upstream negatives: 404 ecpds/home/ckdmip/sw_fluxes-rgb/evaluation1/...; 404 ecpds/home/ckdmip/sw_fluxes/evaluation1/ckdmip_evaluation1_sw_fluxes-rgb_present.h5; 404 ecpds/home/ckdmip/evaluation1/sw_fluxes-rgb/...; 404 ecpds .../lw_fluxes/evaluation2/ckdmip_evaluation2_lw_fluxes_rel-415.h5; 404 ecpds .../sw_fluxes/evaluation2/ckdmip_evaluation2_sw_fluxes_rel-415.h5

## Scope

- **optimizer_blocked**: optimizer submission stays blocked until the six rgb files exist with hashes (this unit) AND the G2b/evaluation2 scope is ruled on for G3
- **this_unit**: the SIX rgb rel files (relative-base pass + relative_to reference) -- minimum to unblock G2 objective parity on the accepted inits
- **follow_on_evaluation2**: the published models are '-32b' = TRAINING_BOTH=yes (copy_to_ckdmip_lw.sh:76-81): faithful G3 additionally needs ckdmip_evaluation2_{lw,sw}_fluxes_rel-415 (ECPDS 404 for both; local generation requires the evaluation2 spectra download) -- Greg's deferred evaluation2 decision is now concrete and load-bearing for G3 acceptance
- **follow_on_g2b**: later SW passes need rgb variants of present, ch4-{350,700,1200,2600,3500}, n2o-{190,270,405,540} (~10 more scenarios, same pipeline)

Provenance: branch `glw/gate4-recovery`, generated_from_head `9df8421` (pre-own-commit).
