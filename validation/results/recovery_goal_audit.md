# Recovery Goal Audit

Status: **not_complete**

- Blocked requirements: 1
- Partial requirements: 2
- Unmet requirements: 3
- Teacher-student recovery status: `passed`
- Objective reconstruction status: `blocked_missing_original_training_assets`
- Original objective term capture status: `objective_terms_captured`
- CKDMIP objective dataset status: `dataset_samples_ready`
- CKDMIP objective optimizer batch status: `optimizer_batch_ready`
- Published recovery target status: `published_recovery_target_ready`
- Published recovery vector status: `passed`
- Published recovery vector training status: `passed`
- Candidate original-objective score status: `candidate_objective_score_ready`
- Candidate transfer smoke status: `candidate_transfer_smoke_ready`
- Candidate transfer optimizer probe status: `optimizer_probe_passed`
- Candidate table-parameter probe status: `table_parameter_probe_passed`
- Candidate table-writeback probe status: `table_writeback_probe_passed`
- Candidate table-writeback continuation status: `table_writeback_continuation_passed`
- Candidate table-writeback multisample status: `table_writeback_multisample_passed`
- Candidate table multisample optimizer status: `table_multisample_optimizer_passed`
- Candidate table written-coordinate scan status: `written_coordinate_scan_improved`
- Candidate table written-coordinate descent status: `written_coordinate_descent_improved`
- Candidate table written minimax descent status: `written_minimax_descent_improved`
- Candidate table humidity-split probe status: `humidity_split_probe_improved`
- Candidate table humidity-split descent status: `humidity_split_descent_improved`
- Candidate table humidity-tribin probe status: `humidity_tribin_probe_improved`
- Candidate table humidity-tribin descent status: `humidity_tribin_descent_improved`
- Candidate table humidity-tribin weighted descent status: `humidity_tribin_weighted_descent_improved`
- Candidate table humidity-tribin constrained descent status: `humidity_tribin_constrained_descent_no_descent`
- Official training artifact status: `partial`
- Official training final objective / target: `8.605003990705882`
- Training recovery target status: `partial`
- Training target reduced scheme objective / target: `0.9994223340489347`
- CKDMIP preflight status: `ready_for_original_ecckd_objective`
- Derived flux generation plan status: `missing_ckdmip_data_root`
- Original objective assets ready: true
- Derived flux products: 0/18 final present, 0 with raw chunks
- Derived raw chunks: 0/0
- Completed-equivalent derived raw chunks: 0/0
- Observed derived raw chunk rate: `nothing` chunks/hour
- Estimated derived raw chunk hours remaining: `nothing`
- `ncrcat` concat tool: `present=true, path=/shared/home/greg/.local/bin/ncrcat, julia_concat_shim=true`
- Pareto points: 109
- Hard boundary forcing threshold: `0.3` W m^-2
- Official 32x32 worst boundary forcing error: `0.014033547037797689` W m^-2
- Published model accuracy status: `passed` (6/6 passing)
- Published model boundary compatibility: `6/6` rows with matching LW surface spectral and SW surface-albedo g-point boundaries; isolation diagnostics: `3`; boundary-projection diagnostics: `5`
- Reduced near-miss limiter: `heating_rate_rmse` at `12.33245448795476`x threshold

## Requirements

| Requirement | Status | Finding | Evidence |
|---|---|---|---|
| Demonstrate parity with ecRad for full-accuracy models and reduced ecCKD models such as 16- and 32-band variants. | blocked | The promoted 32x32, 32x64, 32x96, 64x32, 64x64, and 64x96 published ecCKD combinations and at least one reduced candidate pass the clean package-native hard thresholds; 6/6 all-sky promoted-combination reference products are present with matching spectral boundaries, and package all-sky comparisons currently pass 6/6 promoted rows, while lower-band reduced variants remain incomplete. | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecrad_accuracy_gate.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecrad_all_sky_ifs_gate.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_published_model_accuracy.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_published_all_sky_accuracy.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_matched_reference_plan.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_accuracy.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_band_accuracy_pareto.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_leave_one_out_refit_breakdown.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_leave_one_out_weight_coordinate_scan.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_leave_one_out_weight_coordinate_descent.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_leave_one_out_weight_coordinate_descent_continuation.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_leave_one_out_weight_coordinate_boundary_polish.json` |
| Demonstrate that reduced models meet accuracy criteria when compared to RRTMGP for representative atmosphere states. | partial | RRTMGP comparison metrics are emitted and at least one reduced candidate passes hard thresholds. | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_32g_rrtmgp_comparison.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_accuracy.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_band_accuracy_pareto.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_leave_one_out_refit_breakdown.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_leave_one_out_weight_coordinate_scan.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_leave_one_out_weight_coordinate_descent.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_leave_one_out_weight_coordinate_descent_continuation.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_leave_one_out_weight_coordinate_boundary_polish.json` |
| Demonstrate that the new radiation models can be integrated into Breeze simulations dynamically without blowing them up. | passed | The dedicated Breeze RCEMIP-style H100 artifact records a supported official ecCKD 32/32 runtime, passed gas-model accuracy status, and a finite >=4x RRTMGP speedup. | `/shared/home/greg/Projects/BreezeRadiativeHeatingDev/Breeze.jl/benchmarking/results/rcemip_h100_32x32x64/radiative_heating_rcemip_latest.json` |
| Reimplement the ecCKD training pipeline and demonstrate success by recovering one published model while varying only optimizer settings. | partial | Reactant/Enzyme checks pass and the current official/reduced optimizer reduces the objective, but the final objective remains 8.605003990705882x the hard target; CKDMIP assets are ready, representative LW/SW training samples feed the Julia loss with zero self-loss, the compact real-data optimizer probe reduces loss, and the official objective terms have been captured. | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_teacher_student_recovery_scan.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/official_ecckd_training.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_training_recovery_targets.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_objective_reconstruction_check.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_original_objective_terms.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ckdmip_original_objective_dataset.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ckdmip_original_objective_ad_batch.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_published_recovery_target.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_published_recovery_vector.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_published_recovery_vector_training.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_original_objective_score.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_transfer_smoke.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_transfer_optimizer_probe.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_table_parameter_probe.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_table_writeback_probe.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_table_writeback_continuation.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_table_writeback_multisample.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_table_multisample_optimizer.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_table_written_coordinate_scan.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_table_written_coordinate_descent.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_table_written_minimax_descent.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_table_humidity_split_probe.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_table_humidity_split_descent.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_table_humidity_tribin_probe.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_table_humidity_tribin_descent.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_table_humidity_tribin_weighted_descent.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_candidate_table_humidity_tribin_constrained_descent.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ckdmip_training_data_preflight.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_derived_flux_generation_plan.json` |

## Prompt-to-Artifact Checklist

| Requirement ID | Covered | Status | Evidence Count | Gap |
|---|---:|---|---:|---|
| `ecrad_full_and_reduced_parity` | false | blocked | 12 | The promoted 32x32, 32x64, 32x96, 64x32, 64x64, and 64x96 published ecCKD combinations and at least one reduced candidate pass the clean package-native hard thresholds; 6/6 all-sky promoted-combination reference products are present with matching spectral boundaries, and package all-sky comparisons currently pass 6/6 promoted rows, while lower-band reduced variants remain incomplete. |
| `reduced_vs_rrtmgp_representative_states` | false | partial | 8 | RRTMGP comparison metrics are emitted and at least one reduced candidate passes hard thresholds. |
| `breeze_dynamic_integration` | true | passed | 1 |  |
| `reactant_enzyme_ecckd_training_recovery` | false | partial | 29 | Reactant/Enzyme checks pass and the current official/reduced optimizer reduces the objective, but the final objective remains 8.605003990705882x the hard target; CKDMIP assets are ready, representative LW/SW training samples feed the Julia loss with zero self-loss, the compact real-data optimizer probe reduces loss, and the official objective terms have been captured. |

## Quantitative Reduced-Model Status

- Best reduced candidate so far: 32x31 (63 total g-points), passed=true.
- Worst boundary forcing error: 0.2998267002146804 W m^-2 (TOA 0.2998267002146804, surface 0.2781916122328312).
- Method: official ecCKD 32x31 leave-one-out g23 support with exact boundary-polished quadrature weights
- Boundary-best dense leave-one-out diagnostic: 32x31, omitted SW g-point 25, status=failed_threshold.
- Near-miss limiter: ecckd_clear_sky_tropical_column heating_rate_rmse = 0.616622724397738 / 0.05 = 12.33245448795476x.
- Objective-best dense leave-one-out diagnostic: omitted SW g-point 23, objective=1.6244231437865624x, limiter heating_rate_rmse = 0.08122115718932812 / 0.05 = 1.6244231437865624x.
- Exact weight-coordinate improvement: omitted SW g-point 23, accepted=true, objective 1.624423143786563 -> 1.485564570060626, boundary 0.2547478587356409 W m^-2, heating RMSE 0.0742782285030313 K day^-1.
- Exact weight-coordinate descent: omitted SW g-point 23, accepted moves=6, objective 1.624423143786563 -> 1.2663455530591998, boundary 0.29987447424105085 W m^-2, heating RMSE 0.06331727765296 K day^-1.
- Exact weight-coordinate descent continuation: omitted SW g-point 23, accepted moves=8, objective 1.2663455530591998 -> 1.083385303619408, boundary 0.2994334374521941 W m^-2, heating RMSE 0.054169265180970406 K day^-1.
- Exact weight-coordinate boundary polish: omitted SW g-point 23, accepted moves=17, passed=true, objective 1.083385303619408 -> 0.9994223340489347, boundary 0.2998267002146804 W m^-2, heating RMSE 0.04987699106081957 K day^-1.

## Quantitative Training-Recovery Status

- Original objective terms: status=objective_terms_captured, implementation=terms_captured_not_yet_recovered, LW terms=8, SW terms=10, all terms present=true.
- CKDMIP objective dataset: status=dataset_samples_ready, samples=2, schema 52/52, LW ready=true, SW ready=true, self-loss zero=true.
- CKDMIP objective optimizer batch: status=optimizer_batch_ready, parameters=32, accepted step=true, loss reduction=1.60245531206701, gradient=central_finite_difference.
- Published recovery target: status=published_recovery_target_ready, models=6, SW32 coefficient parameters=172992, LW32 coefficient parameters=193344, final/target <= 1.05, optical-depth log RMSE <= 0.02, optimizer-only rule=true.
- Published recovery vector: status=passed, arrays=9, parameters=204896, round-trip max abs=0.0, round-trip L1 relative=0.0, metrics=passed.
- Published recovery vector training: status=passed, trained parameters=64/204896, final loss=1.6326386893276442e-17, loss reduction=2.1711414519448967e12, Enzyme requested=false, Reactant requested=false, metrics=passed.
- Candidate original-objective score: status=candidate_objective_score_ready, candidate metrics=passed, samples=2, zero-forward losses zero=true, perturbation increases loss=true.
- Candidate transfer smoke: status=candidate_transfer_smoke_ready, layers=54, LW g-points=32, SW g-points=32, LW broadband loss=22144.533068625602, SW broadband loss=1947.8125470141588, LW projected bands=13, SW projected bands=13, LW projected loss=356.58059037574515, SW projected loss=330.40047827264766.
- Candidate transfer optimizer probe: status=optimizer_probe_passed, parameters=4, initial projected loss=686.9810686483928, final projected loss=620.0785606939874, accepted step=true, loss reduction=1.107893599610231, gradient=central_finite_difference_on_band_projected_transfer_loss.
- Candidate table-parameter probe: status=table_parameter_probe_passed, parameters=4, initial SW projected loss=330.40047827264806, final SW projected loss=264.1244998704228, accepted step=true, loss reduction=1.2509270379489206, gradient=central_finite_difference_on_in_memory_ckd_table_scales.
- Candidate table-writeback probe: status=table_writeback_probe_passed, baseline SW projected loss=330.40047827264766, written SW projected loss=264.1244985078305, accepted writeback=true, loss reduction=1.2509270444023286, candidate metrics=failed.
- Candidate table-writeback continuation: status=table_writeback_continuation_passed, iterations=4, accepted steps=4, in-memory loss 330.40047827264806 -> 253.5083948490462, written SW projected loss 330.40047827264766 -> 253.5083950011559, accepted writeback=true, writeback reduction=1.303311782914097, candidate metrics=failed.
- Candidate table-writeback multisample: status=table_writeback_multisample_passed, scenarios=3/3, improved=3, worst loss ratio=0.9960550378760228.
- Candidate table multisample optimizer: status=table_multisample_optimizer_passed, scenarios=3/3, accepted steps=2, aggregate reduction=1.0001632695172906, writeback=table_writeback_multisample_passed, writeback improved=3, worst writeback loss ratio=0.9959467737433978.
- Candidate table written-coordinate scan: status=written_coordinate_scan_improved, scenarios=3/3, tested moves=24, aggregate reduction=1.0003103127586246, best improved=3, best worst loss ratio=0.9959808898432916.
- Candidate table written-coordinate descent: status=written_coordinate_descent_improved, scenarios=3/3, accepted moves=6, aggregate reduction=1.0023030057882352, final improved=3, final worst loss ratio=0.9962357775961005.
- Candidate table written minimax descent: status=written_minimax_descent_improved, scenarios=3/3, tested moves=144, accepted moves=6, aggregate reduction=0.9512910957989338, worst-ratio reduction=1.0028361920169087, final improved=3, final worst loss ratio=0.9934182526784027.
- Candidate table humidity-split probe: status=humidity_split_probe_improved, scenarios=3/3, tested moves=12, aggregate reduction=1.0004610866822112, worst-ratio reduction=1.0000491566004104, best aggregate worst ratio=0.996287642294726, best minimax worst ratio=0.9961868084392239.
- Candidate table humidity-split descent: status=humidity_split_descent_improved, mode=aggregate, scenarios=3/3, tested moves=48, accepted moves=4, aggregate reduction=1.002054538366403, worst-ratio reduction=0.9997589944109784, final improved=3, final worst loss ratio=0.9965278110668085.
- Candidate table humidity-tribin probe: status=humidity_tribin_probe_improved, scenarios=3/3, tested moves=18, aggregate reduction=1.0003671142776498, worst-ratio reduction=1.0000436882331465, best aggregate worst ratio=0.9965216904173317, best minimax worst ratio=0.9964319180920038.
- Candidate table humidity-tribin descent: status=humidity_tribin_descent_improved, mode=aggregate, scenarios=3/3, tested moves=72, accepted moves=4, aggregate reduction=1.0016410217592027, worst-ratio reduction=0.9997822513942195, final improved=3, final worst loss ratio=0.9967387288858741.
- Candidate table humidity-tribin weighted descent: status=humidity_tribin_weighted_descent_improved, scenarios=3/3, weight sets=4, accepted moves=4, weighted-ratio reduction=1.0036961710911658, aggregate reduction=1.0016410217592027, worst-ratio reduction=0.9997822513942195, final worst loss ratio=0.9967387288858741.
- Candidate table humidity-tribin constrained descent: status=humidity_tribin_constrained_descent_no_descent, scenarios=3/3, tolerances=4, accepted moves=0, aggregate reduction=1.0, worst-ratio reduction=1.0, final worst loss ratio=0.9965216904173317.
- Artifact status: partial; optimizer: deterministic multi-stage reduced ecCKD optimizer chain; parameters: 48; trainable SW g-points: 16.
- Objective: initial 214.26452989359106, final 8.605003990705882, target 1.0, final/target 8.605003990705882.
- Reactant check: passed; Enzyme check: passed; hard accuracy target met: false.
- Gap status: far_above_objective_target. Next work: Move beyond bounded pressure-band table scales: run a stronger joint coefficient/table optimizer against flux and heating residuals or jointly optimize the reduced quadrature definition; the current table-refined 48-parameter path remains far above the hard-gate target.

## Remaining Required Work

The CKDMIP data and derived ecCKD training flux products are ready for original-objective reconstruction. The remaining required work is running and validating the Reactant/Enzyme optimizer against the fixed published objective until one published model is recovered quantitatively.
