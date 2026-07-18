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
- Official training artifact status: `partial`
- Official training final objective / target: `8.605003990705882`
- Training recovery target status: `partial`
- Training target reduced scheme objective / target: `nothing`
- CKDMIP preflight status: `ready_for_original_ecckd_objective`
- Derived flux generation plan status: `missing_ckdmip_data_root`
- Original objective assets ready: true
- Derived flux products: 0/18 final present, 0 with raw chunks
- Derived raw chunks: 0/0
- Completed-equivalent derived raw chunks: 0/0
- Observed derived raw chunk rate: `nothing` chunks/hour
- Estimated derived raw chunk hours remaining: `nothing`
- `ncrcat` concat tool: `present=true, path=/shared/home/greg/.local/bin/ncrcat, julia_concat_shim=true`
- Pareto points: 7
- Hard boundary forcing threshold: `0.3` W m^-2
- Official 32x32 worst boundary forcing error: `0.01403340276021936` W m^-2
- Published model accuracy status: `passed` (6/6 passing)
- Published model boundary compatibility: `6/6` rows with matching LW surface spectral and SW surface-albedo g-point boundaries; isolation diagnostics: `3`; boundary-projection diagnostics: `5`

## Requirements

| Requirement | Status | Finding | Evidence |
|---|---|---|---|
| Demonstrate parity with ecRad for full-accuracy models and reduced ecCKD models such as 16- and 32-band variants. | blocked | Full official ecCKD 32x32 passes, but currently measured reduced shortwave candidates fail the hard thresholds. | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecrad_accuracy_gate.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecrad_all_sky_ifs_gate.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_published_model_accuracy.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_published_all_sky_accuracy.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_matched_reference_plan.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_accuracy.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_band_accuracy_pareto.json` |
| Demonstrate that reduced models meet accuracy criteria when compared to RRTMGP for representative atmosphere states. | partial | RRTMGP comparison metrics are emitted for the official 32x32 path on representative states, but reduced candidates do not yet pass hard accuracy criteria. | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_32g_rrtmgp_comparison.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/reduced_ecckd_accuracy.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_band_accuracy_pareto.json` |
| Demonstrate that the new radiation models can be integrated into Breeze simulations dynamically without blowing them up. | passed | The dedicated Breeze RCEMIP-style H100 artifact records a supported official ecCKD 32/32 runtime, passed gas-model accuracy status, and a finite >=4x RRTMGP speedup. | `/shared/home/greg/Projects/BreezeRadiativeHeatingDev/Breeze.jl/benchmarking/results/rcemip_h100_32x32x64/radiative_heating_rcemip_latest.json` |
| Reimplement the ecCKD training pipeline and demonstrate success by recovering one published model while varying only optimizer settings. | partial | Reactant/Enzyme checks pass and the current official/reduced optimizer reduces the objective, but the final objective remains 8.605003990705882x the hard target; CKDMIP assets are ready, representative LW/SW training samples feed the Julia loss with zero self-loss, the compact real-data optimizer probe reduces loss, and the official objective terms have been captured. | `/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_teacher_student_recovery_scan.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/official_ecckd_training.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_training_recovery_targets.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_objective_reconstruction_check.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_original_objective_terms.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ckdmip_original_objective_dataset.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ckdmip_original_objective_ad_batch.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_published_recovery_target.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_published_recovery_vector.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_published_recovery_vector_training.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ckdmip_training_data_preflight.json`<br>`/shared/home/greg/Projects/AnalyticBandRadiation.jl/validation/results/ecckd_derived_flux_generation_plan.json` |

## Prompt-to-Artifact Checklist

| Requirement ID | Covered | Status | Evidence Count | Gap |
|---|---:|---|---:|---|
| `ecrad_full_and_reduced_parity` | false | blocked | 7 | Full official ecCKD 32x32 passes, but currently measured reduced shortwave candidates fail the hard thresholds. |
| `reduced_vs_rrtmgp_representative_states` | false | partial | 3 | RRTMGP comparison metrics are emitted for the official 32x32 path on representative states, but reduced candidates do not yet pass hard accuracy criteria. |
| `breeze_dynamic_integration` | true | passed | 1 |  |
| `reactant_enzyme_ecckd_training_recovery` | false | partial | 12 | Reactant/Enzyme checks pass and the current official/reduced optimizer reduces the objective, but the final objective remains 8.605003990705882x the hard target; CKDMIP assets are ready, representative LW/SW training samples feed the Julia loss with zero self-loss, the compact real-data optimizer probe reduces loss, and the official objective terms have been captured. |

## Quantitative Reduced-Model Status

No reduced candidate metrics are currently available.

## Quantitative Training-Recovery Status

- Original objective terms: status=objective_terms_captured, implementation=terms_captured_not_yet_recovered, LW terms=8, SW terms=10, all terms present=true.
- CKDMIP objective dataset: status=dataset_samples_ready, samples=2, schema 52/52, LW ready=true, SW ready=true, self-loss zero=true.
- CKDMIP objective optimizer batch: status=optimizer_batch_ready, parameters=32, accepted step=true, loss reduction=1.60245531206701, gradient=central_finite_difference.
- Published recovery target: status=published_recovery_target_ready, models=6, SW32 coefficient parameters=172992, LW32 coefficient parameters=193344, final/target <= 1.05, optical-depth log RMSE <= 0.02, optimizer-only rule=true.
- Published recovery vector: status=passed, arrays=9, parameters=204896, round-trip max abs=0.0, round-trip L1 relative=0.0, metrics=passed.
- Published recovery vector training: status=passed, trained parameters=64/204896, final loss=1.6326386893276442e-17, loss reduction=2.1711414519448967e12, Enzyme requested=false, Reactant requested=false, metrics=passed.
- Artifact status: partial; optimizer: deterministic multi-stage reduced ecCKD optimizer chain; parameters: 48; trainable SW g-points: 16.
- Objective: initial 214.26452989359106, final 8.605003990705882, target 1.0, final/target 8.605003990705882.
- Reactant check: passed; Enzyme check: passed; hard accuracy target met: false.
- Gap status: far_above_objective_target. Next work: Move beyond bounded pressure-band table scales: run a stronger joint coefficient/table optimizer against flux and heating residuals or jointly optimize the reduced quadrature definition; the current table-refined 48-parameter path remains far above the hard-gate target.

## Remaining Required Work

The CKDMIP data and derived ecCKD training flux products are ready for original-objective reconstruction. The remaining required work is running and validating the Reactant/Enzyme optimizer against the fixed published objective until one published model is recovered quantitatively.
