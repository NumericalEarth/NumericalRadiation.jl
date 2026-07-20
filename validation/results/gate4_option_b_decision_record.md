# Gate-4 Option B decision record

Status: **option_b_adopted_candidates_promoted**

Authorization: Greg, 2026-07-20: "take option B".

decision record; promotes the named artifacts to acceptance inits under the amended rule; no objective, floor, or recovery computation in this unit.

| Gate | Result |
|---|---|
| drift_within_amended_bounds | passed |
| evidence_gate4_a2_proof_finding_ledger | passed |
| evidence_gate4_r1_release_provenance_probe | passed |
| evidence_gate4_r2_finding_ledger | passed |
| evidence_gate4_v1_version_skew_recon | passed |
| lw_caveat_recorded | passed |
| promoted_artifact_verified_lw | passed |
| promoted_artifact_verified_sw | passed |
| supersession_clause_honored | passed |

## Amended acceptance rule

- **structural**: elementwise EXACT: g_point count, band_number, wavenumber1/2_band, fine wavenumber1/2 grids, and solar_spectral_irradiance where the toolchain emits it
- **provenance**: all artifacts sha256-pinned; version skew accounted where testable
- **scope**: gate-4 acceptance init candidates ONLY; the optimizer-only-delta rule itself (data/objective/evaluation/g-point structure fixed) is unchanged
- **support_arrays**: numerically equivalent at storage precision: per-array max|diff| <= 2.1e-5; mismatch counts recorded as descriptive provenance (not bounded)

## Observed drift vs bounds (all within)

| Array | Mismatched | Max abs diff |
|---|---|---|
| solar_irradiance | 2/32 | 2.0503997802734375e-5 |
| rayleigh_molar_scattering_coeff | 2/32 | 9.645062526431047e-16 |
| gpoint_fraction | 60/31840 | 1.6033649444580078e-5 |
| lw_gpoint_fraction | 205/10432 | 2.682209014892578e-6 |

## Promoted artifacts

- **LW acceptance raw init**: `ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc`
  - sha256: `ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43`
  - builder: pinned v1.2 (proof job 4091)
  - caveat: LW-1.0 builder-source ambiguity (permanent, documented)
- **SW acceptance raw init (pre-scale_lut)**: `ecckd-1.4_sw_raw-ckd-definition_climate_rgb-tol0.047.nc`
  - sha256: `99333fb5f3c1a3e7ee343a8abd5bbe599f61419c89b8f9b13320a85105532c26`
  - builder: v1.4 23adaca build (R2 job 4096; binary sha256 1c79dfa3b963773d4e01437a0f79cb855c7257938d82d0b912d37630aa5412d3)
  - caveat: version-matched to the published SW32 (ecckd-1.4); emits solar_spectral_irradiance bit-exactly
- **g-point candidates (structure source)**: `ecckd-1.2_lw,sw_gpoints_*.h5`
  - sha256: `LW c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e; SW 13dd686acd0c3ca2201775270f876ce3e3a326576b58b24323b5ce95659b9b57`
  - builder: A2 job 4082 (find_g_points unchanged v1.2..23adaca)
  - caveat: none: candidate-derived structure verified bit-exact

Next: init generation: scale_lut_sw applied to the promoted SW raw (per gate4_init_generation_manifest: LBL direct-only mu0=0.5 albedo 0.15 reference); G2/G3 optimizer recovery runs from the promoted inits (acceptance metrics unchanged: final/target <= 1.05, weight L1 <= 0.02, OD log-RMSE <= 0.02)

Provenance: branch `glw/gate4-recovery`, generated_from_head `fd74174` (pre-own-commit).
