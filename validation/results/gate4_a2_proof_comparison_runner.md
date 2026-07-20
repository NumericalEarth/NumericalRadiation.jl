# Gate-4 A2 proof comparisons

Status: **proof_mismatch_sensitivity_only**

read-only comparisons; no create_lut, objective, floor, or recovery computation.

**Provenance requirement**: path existence alone is NOT proof provenance: these comparisons are valid evidence ONLY if the raw inputs above were created by an explicitly authorized proof sbatch whose completion, log, and output hashes have been reviewed; otherwise the raw files are UNPROVEN and this result promotes nothing

| Band | Comparison | Exact | Detail |
|---|---|---|---|
| lw | g_count | true | raw 32 vs published 32 (must both be 32) |
| sw | g_count | true | raw 32 vs published 32 (must both be 32) |
| lw | gpoint_fraction | false | (10432,) max_abs_diff=2.682209014892578e-6 n=205 |
| sw | gpoint_fraction | false | (31840,) max_abs_diff=1.6033649444580078e-5 n=60 |
| lw | wavenumber1_band | true | (1,) |
| sw | wavenumber1_band | true | (5,) |
| lw | wavenumber2_band | true | (1,) |
| sw | wavenumber2_band | true | (5,) |
| lw | band_number | true | (32,) |
| sw | band_number | true | (32,) |
| lw | wavenumber1 | true | (326,) |
| sw | wavenumber1 | true | (995,) |
| lw | wavenumber2 | true | (326,) |
| sw | wavenumber2 | true | (995,) |
| sw | solar_irradiance | false | (32,) max_abs_diff=2.0503997802734375e-5 n=2 |
| sw | rayleigh_molar_scattering_coeff | false | (32,) max_abs_diff=9.645062526431047e-16 n=2 |
| sw | solar_spectral_irradiance | false | variable missing from proof raw definition |

Verdict: MISMATCH: candidates are SENSITIVITY-ONLY; the acceptance floor cannot use them unless Greg explicitly changes the optimizer-only-delta rule; record as finding (pre-registered risk: ecckd version skew 1.0/1.4 published vs 1.2 rerun)
