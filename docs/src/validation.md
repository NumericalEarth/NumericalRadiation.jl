# Validation

## Running the package tests

The package test suite covers the solvers, ecCKD ingestion, cloud optics, and
the SpeedyWeather extension:

```
julia --project=. -e 'using Pkg; Pkg.test()'
```

The suite runs in about a minute and needs no large external data; the
official ecRad/ecCKD snapshots resolve through the lazy artifacts pinned in
`Artifacts.toml`.

## The validation platform

The development and validation harness is deliberately kept off this branch.
The `validation-platform` branch carries:

- the accuracy gate scripts (clean cloudless gate, all-sky IFS gate, RRTMGP
  comparison, published-model accuracy) and the frozen evidence they produced;
- the ecRad reference manifest and frozen diagnostics
  (`validation/FROZEN_DIAGNOSTICS.md`);
- the gate-4 training pipeline for published ecCKD model recovery.

The gate thresholds themselves — for example, TOA/surface forcing error
≤ 0.3 W m⁻² and heating-rate RMSE ≤ 0.05 K day⁻¹ — are package validation
gates inspired by ecRad/CKDMIP comparisons, chosen for this project rather
than quoted from a published standard. The full criteria and current gate
status are recorded in [Design and acceptance criteria](design.md).

## Reference data

The ecRad reference NetCDF data consumed by the validation platform ships as
the `validation-data-v1` release artifact (the lazy `ecrad_reference_data`
entry in `Artifacts.toml`). Large CKDMIP line-by-line inputs are not package
artifacts; point `RH_CKDMIP_DATA_PATH` at a local CKDMIP tree for
training-objective work.

## Campaign history

The full campaign history — audit ledgers, the pass-numbered working log, and
every optimizer-experiment artifact — is preserved on the archived git ref
`audit-trail-2026-07-17` (branch `audit-trail-pre-cleanup`).
