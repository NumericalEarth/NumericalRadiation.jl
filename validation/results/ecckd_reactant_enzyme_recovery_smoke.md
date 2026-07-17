# ecCKD Reactant/Enzyme Recovery Smoke

Generated: 2026-05-28T01:29:09.078
Status: passed_reactant_enzyme_recovery_smoke
- Official model: `validation/external/ecrad/data/ecckd-1.0_sw_climate_rgb-32b_ckd-definition.nc`
- Variable: `co2_molar_absorption_coeff`
- Samples: 512
- Steps: 1
- Initial loss: 2.917549e-01
- Final loss: 0.000000e+00
- Final RMS: 0.000000e+00
- Final max abs: 0.000000e+00
- Reactant compiled loss abs error: 0.000000e+00

## Scope
- Uses Reactant CPU compilation for the recovery objective.
- Uses Enzyme reverse-mode gradients for optimizer updates.
- Recovers a published ecCKD coefficient slice; the full CKDMIP objective replay remains represented by the separate preflight/objective-contract artifacts.
