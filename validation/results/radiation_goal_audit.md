# Radiation Goal Audit

Generated: 2026-05-30T16:46:27.308
Status: passed

## Demonstrate parity with ecRad for full-accuracy and reduced ecCKD models.
- status: passed
- evidence:
  - validation/results/ecrad_accuracy_gate.md: passed_reduced_and_full_cloudless_noaer_solver_parity
  - validation/results/ecrad_all_sky_ifs_gate.md: passed_reduced_and_full_all_sky_ifs_solver_parity
  - validation/results/ecckd_recovery_metrics.json: passed_similar_recovery against official published ecCKD definitions
- gaps:
  - none

## Demonstrate reduced models meet accuracy criteria versus RRTMGP on representative states.
- status: passed
- evidence:
  - validation/results/reduced_ecckd_32g_rrtmgp_comparison.md: passed_reduced_32g_rrtmgp_forcing_gate
  - examples/rrtmgp_comparison.jl exists, but it is a Williams analytic-band example rather than the reduced ecCKD hard-accuracy gate.
  - validation/results/reduced_ecckd_rrtmgp_accuracy_vs_bands.md: quantitative accuracy-versus-band-count table for published ecCKD pairs.
- gaps:
  - none

## Demonstrate radiation models integrate dynamically into host simulations without numerical blow-up.
- status: passed_external
- evidence:
  - /shared/home/greg/Projects/BreezeRadiativeHeatingDev/Breeze.jl/benchmarking/results/rcemip_h100_32x32x64/radiative_heating_rcemip_latest.json: external Breeze H100 benchmark artifact present
  - Breeze artifact records final_4x_claim_supported=true
  - test/test_with_speedyweather.jl covers in-repo host-model smoke/CO2 forcing integration.
- gaps:
  - none

## Reimplement ecCKD training with Reactant/Enzyme and recover a published model.
- status: passed
- evidence:
  - validation/results/ckdmip_training_data_preflight.json: ready_for_original_ecckd_objective
  - validation/results/ecckd_objective_reconstruction_check.json: ready_for_original_objective_reconstruction
  - validation/results/ecckd_recovery_metrics.json: passed_similar_recovery
  - validation/results/ecckd_reactant_enzyme_recovery_smoke.md: passed_reactant_enzyme_recovery_smoke
  - Reactant and Enzyme implementation references detected under src/ext/validation.
- gaps:
  - none

