# Gate-4 Cost Probe (P1a)

Status: **probe_complete**

Data mode: `synthetic_shapes_only`

> Disclaimer: no objective-value or recovery claims; synthetic shapes only; 204,896-vector work is flatten/write/reflatten plumbing plus FD-infeasibility evidence only

Coefficient-gradient status: `blocked_no_differentiable_forward_map` (P2 dependency: `coefficients_to_optical_depth_to_flux_forward_map`).

Shapes: 54 layers, 55 interfaces, 32 g-points; loss-input vector length 5248. median of 5 samples after one discarded warmup.

## Provenance

| Field | Value |
|---|---|
| Branch | `glw/gate4-recovery` |
| Worktree | `/shared/home/greg/Projects/AnalyticBandRadiation-platform/` |
| SW32 definition | `ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc` |
| Julia (runtime / test manifest) | 1.12.6 / 1.12.6 |
| Enzyme (test manifest) | 0.13.153 |
| Reactant (test manifest) | 0.2.274 |

## Loss-kernel timings

| Variant | Path | Median s | Samples s |
|---|---|---:|---|
| `lw_general` | general | 4.291e-5 | 4.429e-5, 6.213e-5, 4.042e-5, 4.128e-5, 4.291e-5 |
| `sw_general` | general | 4.389e-5 | 4.477e-5, 4.332e-5, 4.389e-5, 4.054e-5, 5.9e-5 |
| `sw_fast_path` | fast (early-return branch, ecckd_original_objective_loss.jl:128) | 8.762e-6 | 9.149e-6, 8.867e-6, 8.56e-6, 8.196e-6, 8.762e-6 |

## Enzyme loss-input adjoints

adjoints w.r.t. the assembled candidate heating/flux arrays only; NOT coefficient gradients.

| Variant | Median s | FD max rel error | Gate (< 1.0e-6) |
|---|---:|---:|---|
| `lw_general` | 0.0002175 | 1.032e-10 | passed |
| `sw_general` | 0.0002107 | 2.358e-11 | passed |
| `sw_fast_path` | 3.468e-5 | 3.156e-11 | passed |

## Reactant (real SW loss function with synthetic inputs, cpu backend)

| Metric | Value |
|---|---:|
| Status | reactant_ok |
| Package load s | 3.098 |
| Compile s | 37.62 |
| First call s | 0.421 |
| Steady-state median s | 2.014e-5 |
| Matches plain Julia | true |

## SW32 recovery-vector plumbing

| Metric | Value |
|---|---:|
| Reference | `ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc` |
| Arrays | 9 |
| Parameters | 204896 (expected 204896) |
| Flatten median s | 0.005119 |
| Write-candidate median s | 0.003371 |
| Reflatten median s | 0.004763 |
| Round-trip max abs error | 0.0 |
| Round-trip L1 relative error | 0.0 |

## FD-infeasibility extrapolation

| Metric | Value |
|---|---:|
| Single-loss median s | 4.389e-5 |
| Central-FD loss evaluations | 409792 |
| Extrapolated FD gradient s | 17.99 |
| Extrapolated FD gradient h | 0.004996 |

cost of ONE central-finite-difference gradient over the 204,896-parameter SW32 vector at a single-loss-evaluation price; the real objective sums many profiles, so this is a lower bound.

## Gates

| Gate | Outcome |
|---|---|
| Enzyme loss-input adjoint vs FD | passed |
| SW32 parameter count == 204896 | passed |
| SW32 round-trip exactly zero | passed |
| Reactant compile | passed |

## Failures

None.
