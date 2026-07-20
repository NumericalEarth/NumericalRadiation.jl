# Gate-4 R2 SW comparisons (v1.4 build vs published SW32)

Status: **r2_ssi_emitted_drift_remains**

read-only comparisons; no build, objective, floor, or promotion.

**Provenance requirement**: valid evidence ONLY if the raw input above came from the authorized R2 sbatch (completion + log/hash review); otherwise unproven, promotes nothing

| Comparison | Exact | Detail |
|---|---|---|
| g_count | true | raw 32 vs published 32 |
| gpoint_fraction | false | (31840,) max_abs_diff=1.6033649444580078e-5 n=60 |
| wavenumber1_band | true | (5,) |
| wavenumber2_band | true | (5,) |
| band_number | true | (32,) |
| wavenumber1 | true | (995,) |
| wavenumber2 | true | (995,) |
| solar_irradiance | false | (32,) max_abs_diff=2.0503997802734375e-5 n=2 |
| rayleigh_molar_scattering_coeff | false | (32,) max_abs_diff=9.645062526431047e-16 n=2 |
| solar_spectral_irradiance | true | (995,) |

Verdict: SSI absence RESOLVED as version skew (v1.4 emits the variable) -- strong confirmation of R1. Remaining mismatches join the unresolved-drift set (expected possibility per the pre-registered outcome): attributed to non-source factors (input data provenance, build config); candidates remain sensitivity-only; feeds Greg's A/B decision.
