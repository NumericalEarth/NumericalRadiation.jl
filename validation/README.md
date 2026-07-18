# Validation reports

This directory contains runnable validation/report scripts. The current toy
case is a deterministic fixture for the staged ecCKD gas-optics path; it is
not an ecRad or CKDMIP scientific validation case. Its purpose is to exercise
the report format, stored reference comparison, and hard threshold failure
path before real reference datasets are added.

Run from the repository root:

```sh
julia --project=. validation/toy_ecckd_validation.jl
```

The reduced fixed-topology training fixture exercises loss reduction,
flux/heating-rate RMSE improvement, reproducible configuration reporting, and
finite-difference gradient consistency for toy ecCKD gas-optics parameters:

```sh
julia --project=. validation/toy_ecckd_training.jl
```

It writes `validation/results/toy_ecckd_training.json` and `.md`. When run in
an environment where Enzyme and Reactant are available, the report includes an
Enzyme gradient check through a pure two-stream radiative loss and a Reactant
toy loss compilation check. Full Enzyme differentiation through the mutating
radiative-transfer pipeline remains open.

The absorptive all-sky cloud scaffold has its own deterministic validation
fixture:

```sh
julia --project=. validation/toy_cloud_validation.jl
```

It writes `validation/results/toy_cloud_validation.json` and `.md`, validates
stored cloudy flux/heating references, and checks that surface shortwave flux is
reduced relative to the clear fixture. This is not an ecRad all-sky validation
case.

The host-model access-point check verifies that component APIs needed by
Breeze, SpeedyWeather-style integrations, and validation tools are exported and
callable separately:

```sh
julia --project=. validation/access_points_check.jl
```

It writes `validation/results/access_points_check.json` and `.md`.

The project-level completion audit is maintained in
`validation/goal_audit.md`. It maps each `/goal` deliverable to current
evidence and explicitly lists the remaining blockers before the goal can be
marked complete.

The executable audit check verifies that the current scaffold artifacts are
present and that known blockers are still recorded:

```sh
julia --project=. validation/goal_audit_check.jl
```

It writes `validation/results/goal_audit_check.json` and `.md`.

The recovery-goal audit is the current prompt-to-artifact checklist for the
latest ecCKD/Breeze recovery criteria: ecRad parity for full and reduced
models, RRTMGP comparisons on representative states, dynamic Breeze
integration, and Reactant/Enzyme recovery of a published ecCKD model:

```sh
julia --project=test validation/recovery_goal_audit.jl
```

It writes `validation/results/recovery_goal_audit.json` and `.md`. A
`not_complete` status is expected until reduced candidates pass hard
thresholds, `RH_CKDMIP_DATA_PATH` points at a complete public CKDMIP
line-by-line training tree, and the derived ecCKD `5gas-*` / `rel-*` training
flux products referenced by the published optimizer scripts have been generated
locally.

The derived ecCKD flux generation plan inventories those generated `5gas-*`
and `rel-*` products separately from the public CKDMIP files and maps each
missing product back to the upstream ecCKD LBL evaluation script and scenario
batch:

```sh
julia --project=test validation/ecckd_derived_flux_generation_plan.jl
```

It writes `validation/results/ecckd_derived_flux_generation_plan.json` and
`.md`. The companion `validation/generate_ecckd_derived_fluxes.sh` launcher
prepares a writable ecCKD working copy and patches the expected `SCENARIOS`,
`CKDMIP_DATA_DIR`, and `WORK_DIR` values. It defaults to dry-run mode; a real
run requires `RH_CKDMIP_TOOL_DIR` to point at a CKDMIP build containing
`ckdmip_lw` and `ckdmip_sw`. After a successful real run, the launcher installs
the generated final flux files into
`$RH_CKDMIP_DATA_PATH/evaluation1/{lw,sw}_fluxes`. If a run was started before
that install step existed, copy the finished work products into the CKDMIP tree
with:

```sh
RH_CKDMIP_DATA_PATH=/path/to/ckdmip \
RH_ECCKD_LBL_WORKDIR=/path/to/ecckd-derived-flux-work \
bash validation/install_ecckd_derived_fluxes.sh
```

The ecRad reference manifest defines the first external reference artifacts
required for final solver/gas-optics validation:

```sh
julia --project=test validation/ecrad_reference_manifest.jl
julia --project=test validation/ecrad_candidate_schema.jl
julia --project=test validation/ecrad_accuracy_gate.jl
```

These write `validation/results/ecrad_reference_manifest.json` / `.md` and
`validation/results/ecrad_candidate_schema.json` / `.md` and
`validation/results/ecrad_accuracy_gate.json` / `.md`. Use the `test` project
because `NCDatasets` is an optional dependency of the runtime package but is
required for NetCDF schema and accuracy checks. A `missing_references` status
means final ecRad/ecCKD validation is blocked until the listed NetCDF files are
generated or supplied. The candidate schema check is a preflight for the hard
gate: it verifies that each `radiative_heating_*` candidate variable exists
and has the same shape as the matching ecRad reference variable.

Reference-file placement and schema expectations are summarized in
`validation/reference/ecrad/README.md`.

## Artifact policy (post-cleanup)

`validation/results/` holds only artifacts that surviving code reads: gate and
audit evidence, the model inventory, and the compact accepted-move records that
`reduced_ecckd_accuracy.jl` replays to reconstruct the registered reduced
candidates. Bulky per-iteration optimizer logs must not be committed here —
write them outside the repo (or to S3) and commit only the accepted
moves/weights and the final summary. The complete pre-cleanup experiment
history (~120 optimizer scripts and ~480k lines of scan logs) is preserved on
the archived ref `audit-trail-2026-07-17` (branch `audit-trail-pre-cleanup`).
