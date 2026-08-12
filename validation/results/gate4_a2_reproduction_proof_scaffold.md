# Gate-4 A2 reproduction-proof scaffold — HISTORICAL (verdict rule superseded by Option B)

Status: **a2_proof_scaffold_ready**

**Superseded by**: gate4_option_b_decision_record (Greg-authorized amended acceptance rule); this unit's strict verdict_rule any_mismatch->sensitivity-only is explicitly listed there as superseded

**Outcome**: proof executed as job 4091 on the job-4082 A2 candidates: verdict proof_mismatch_sensitivity_only under the strict rule (structure all exact, support drift at storage precision); R2 job 4096 resolved the SSI absence as version skew; candidates promoted under Option B

HISTORICAL proof specification (the proof it specified was executed as job 4091 and its strict verdict rule superseded by Option B); no create_lut, objective, floor, or recovery computation.

| Gate | Result |
|---|---|
| comparison_spec_complete | passed |
| exec_checkpoint_prerequisite | passed |
| mismatch_means_sensitivity_only | passed |
| no_execution_in_this_unit | passed |
| prerequisite_loader_fixture_tests | passed |
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

Verdict (historical strict rule): all exact -> promote to acceptance raw inits; any mismatch -> sensitivity-only, no floor use without an explicit rule change. this strict rule was applied by proof job 4091 (verdict proof_mismatch_sensitivity_only) and then SUPERSEDED by the Greg-authorized Option-B amended rule (gate4_option_b_decision_record), under which the candidates were promoted; retained here as the historical spec.

Deferred hygiene note: RESOLVED: the previously flagged stale comment (claiming the May config already localizes paths) is absent from the current gate4_a2_dryrun.sbatch; no action remains

Provenance: branch `glw/gate4-recovery`, generated_from_head `759bb2f` (pre-own-commit).
