# Gate-4 A2 reproduction-proof scaffold

Status: **a2_proof_scaffold_ready**

proof specification only; refuses until A2 gpoints candidates exist; no create_lut, objective, floor, or recovery computation.

| Gate | Result |
|---|---|
| comparison_spec_complete | passed |
| mismatch_means_sensitivity_only | passed |
| no_execution_in_this_unit | passed |
| proof_commands_recorded | passed |
| published_targets_resolved | passed |
| refuses_without_candidates | passed |

Candidates found: LW 1, SW 1

## Exact comparisons (all must pass for acceptance)

- [both] g_count: exactly 32 g-points in each proof definition
- [both] gpoint_fraction: shape AND elementwise values EXACT vs published (LW (326,32), SW (995,32) per the feasibility stats)
- [both] wavenumber1_band: elementwise EXACT
- [both] wavenumber2_band: elementwise EXACT
- [both] band_number: elementwise EXACT
- [sw] solar_irradiance: elementwise EXACT vs published SW32 (per-g SSI is a fixed support array, item 22)
- [sw] rayleigh_molar_scattering_coeff: elementwise EXACT vs published SW32 (fixed support array produced at create_lut time)
- [both] wavenumber1: elementwise EXACT (fine per-bin lower bounds of the definition wavenumber grid)
- [both] wavenumber2: elementwise EXACT (fine per-bin upper bounds)
- [sw] solar_spectral_irradiance: elementwise EXACT vs published SW32

Verdict: all exact -> promote to acceptance raw inits; any mismatch -> sensitivity-only, no floor use without an explicit rule change.

Deferred hygiene note: gate4_a2_dryrun.sbatch retains a stale comment claiming the May config already localizes paths (superseded by the sed-patch block that follows it); remove at the next checkpoint amend -- not blocking, the executable sed block is authoritative

Provenance: branch `glw/gate4-recovery`, generated_from_head `2f45d6f` (pre-own-commit).
