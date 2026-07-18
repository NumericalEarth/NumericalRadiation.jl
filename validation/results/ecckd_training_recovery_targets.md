# ecCKD Training Recovery Targets

Status: **partial**

## Current Evidence

| Evidence | Value |
|---|---:|
| Official recovery final objective / target | 8.60500399071 |
| Official recovery hard target met | false |

## Recovery Criteria

| Metric | Acceptance |
|---|---:|
| Final objective / target | <= 1.05 |
| Relative L1 weight error | <= 0.02 |
| Optical-depth log RMSE | <= 0.02 |
| Forcing regression margin | <= 0.03 W m^-2 |
| Heating RMSE regression margin | <= 0.005 K day^-1 |

## New Band-Scheme Criteria

| Metric | Acceptance |
|---|---:|
| Hard-gate objective | <= 1.0 |
| TOA forcing absolute error | <= 0.3 W m^-2 |
| Surface forcing absolute error | <= 0.3 W m^-2 |
| Heating-rate RMSE | <= 0.05 K day^-1 |
| Required band-count points | 48, 96 |

new band-count rows only count when produced by the recovered training pipeline with source data, objective terms, and evaluation cases fixed; greedy/forward-evaluation candidates are frozen as evidence (validation/FROZEN_DIAGNOSTICS.md) and do not satisfy these targets

Published-model recovery remains partial until the Reactant/Enzyme training pipeline recovers a published ecCKD definition under the optimizer-only-delta rule; new band-count schemes only count when produced by that recovered pipeline.

Next required work:
- Run the original-objective Reactant/Enzyme recovery with source data/objective/evaluation fixed and only optimizer settings varied.
- Compare recovered weights and optical-depth tables against the published ecCKD model using the quantitative recovery metrics above.
- Use the recovered pipeline to generate missing band-count rows, starting with 48-g and 96-g, then refresh the accuracy-vs-band plot.
