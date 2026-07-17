# Examples

Standalone scripts that exercise `NumericalRadiation` in richer settings
than the docs examples. They live in their own Julia environment
(`examples/Project.toml`) so the main package stays dep-light.

## `rrtmgp_comparison.jl`

Compare Williams (2026) clear-sky longwave heating rates against RRTMGP on a
shared idealized tropical column.

Breeze's `RadiativeTransferModel(grid, ClearSkyOptics(), …)` provides the
RRTMGP reference; we extract the same `T(z)`, `qᵥ(z)`, and reference-state
pressure profile and feed them to
[`NumericalRadiation.solve_longwave!`](../src/longwave/williams_longwave.jl).

### Run it

```bash
julia --project=examples examples/rrtmgp_comparison.jl
```

The first run will download RRTMGP lookup-table artifacts via `NCDatasets`.
After that the script prints OLR for both schemes and saves a figure next
to itself.

### What to expect

Running the script on a 64-layer idealized tropical column (surface 300 K,
exponential moisture with `q₀ = 0.02` and scale height 3 km) prints

```
OLR (RRTMGP)        = 252.68 W/m²
OLR (Williams SSM)  = 272.04 W/m²
Mean column heating rate:
  RRTMGP   = -1.269 K/day
  Williams = -1.864 K/day
```

The heating-rate profiles overlap through the free troposphere and diverge
only near the surface (where Williams's two-band continuum under-represents
far-IR cooling to space) and in the stratosphere (where Williams has no
ozone line and the CO₂ 15 μm band is a single Laplace-shaped wing rather
than RRTMGP's full correlated-k g-point stack).

The point of the comparison is *not* bit-equivalence — it's to confirm
Williams stays within the factor-2 band of a reference line-by-line-derived
scheme, which is the claim of the paper.

### Output

The script writes `rrtmgp_comparison.png` next to itself: a temperature
profile on the left and the two heating-rate profiles overlaid on the right.

## `analytic_column.jl`

Run a single analytic-band column through the staged `radiative_heating!`
wrapper and print surface fluxes, TOA flux, column-integrated heating, energy
closure residual, and runtime.

```bash
julia --project=. examples/analytic_column.jl
```

## `ecckd_column.jl`

Select a published ecCKD model pair, load its official CKD-definition files,
run one clear-sky staged column, and print flux/heating diagnostics.

```bash
julia --project=examples examples/ecckd_column.jl
ECCKD_MODEL=64x32 julia --project=examples examples/ecckd_column.jl
```
