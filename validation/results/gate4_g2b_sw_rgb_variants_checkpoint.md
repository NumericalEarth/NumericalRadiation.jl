# Gate-4 G2b SW-RGB minor-gas training-flux checkpoint

Status: **g2b_checkpoint_ready**

script generation only; nothing submitted by this unit; LBL evaluation only; no optimizer, create_lut, scale_lut, find_g_points, objective, floor, or recovery computation.

| Gate | Result |
|---|---|
| exact10_completeness_gate_before_install | passed |
| g2a_prerequisite | passed |
| headnode_refusal_guard | passed |
| lbl_evaluation_only | passed |
| partial_raw_guard | passed |
| pipeline_parity | passed |
| quarantine_separate_from_g2a | passed |
| rgb_band_grid_14300_variant | passed |
| sbatch_written_not_submitted | passed |
| scenario_override_ten | passed |
| stale_output_refusal | passed |

**Attempt history**: job 4103 CANCELED before any valid output during monitor pre-submit review; it left a header-size partial RAW chunk, so the corrective sbatch wipes the G2b quarantine tree at stage 0 (partial-RAW guard) before regenerating.


Scenarios (10): present, ch4-350, ch4-700, ch4-1200, ch4-2600, ch4-3500, n2o-190, n2o-270, n2o-405, n2o-540

Scenario support: run_sw_lbl_evaluation.sh: 'present' explicit branch (415/1921/332); ch4-/n2o- prefix branches set the respective VMR

Quarantine: work-rgb-g2b / testcopy-rgb-g2b (disjoint from G2a's work-rgb); shared install dir evaluation1/sw_fluxes-rgb with disjoint filenames.

Provenance: branch `glw/gate4-recovery`, generated_from_head `ac37fc7` (pre-own-commit).
