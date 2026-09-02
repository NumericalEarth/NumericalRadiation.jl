# ecCKD Training and Recovery

!!! warning "Status: recovery is a goal, not yet a demonstrated result"
    This page documents the *intended* training/recovery method. Recovering a
    published ecCKD model has **not yet been demonstrated**; recorded attempts
    and their evidence live on the validation platform
    (`glw/gate4-recovery` branch).

The training/recovery workflow has two goals:

1. reconstruct the published ecCKD objective closely enough to recover an
   official reduced model, and
2. use the same pipeline to fill new g-point counts such as 48 or 96 when the
   published set does not contain the desired pair.

Recovery means that an in-house optimization pipeline starts from the same
training data and nearly the same objective as the published ecCKD workflow,
then produces coefficients and validation metrics that are quantitatively
close to a published model. Exact bitwise equality is not expected if optimizer
settings, stopping tolerances, compiler math, or line-search choices differ.
The intended controlled experiment is to keep everything except optimizer
settings as similar as possible.

## Inputs

Small inputs are artifact-backed:

- `ecrad_data` provides the published CKD-definition files used for parity
  checks.
- `ecckd_source` provides the upstream ecCKD source and training scripts.

Large CKDMIP line-by-line spectra are not default package artifacts. Set
`RH_CKDMIP_DATA_PATH` to a local or mounted CKDMIP tree before running exact
training-objective reconstruction. The tree preflight distinguishes public
upstream inputs from derived ecCKD training fluxes: files named like `5gas-*`
and `rel-*` are generated products from the ecCKD/CKDMIP toolchain, not public
CKDMIP archive inputs.

## The Published Training Pipeline

Recovering a published model requires reproducing more than a k-coefficient
fit. The upstream pipeline (Hogan & Matricardi (2022), *J. Adv. Model. Earth
Syst.*, DOI 10.1029/2022MS003033; see
`doc/ecckd_documentation.tex` and the `test/do_all_{lw,sw}.sh` master scripts
in the [upstream ecCKD repository](https://github.com/ecmwf-ifs/ecckd), pinned
here as the `ecckd_source` artifact) has four stages after the g-point
selection described on the [correlated-k page](correlated_k.md):

1. **Initial look-up table.** `create_lut` reads the CKDMIP *Idealized*
   dataset and averages molar absorption coefficients into each g point —
   Planck-weighted in the longwave, weighted by the high-resolution solar
   spectral irradiance in the shortwave — plus one Rayleigh molar scattering
   coefficient per shortwave g point.
2. **Shortwave direct-beam scaling.** `scale_lut` computes, from line-by-line
   direct fluxes for the CKDMIP *MMM* median profile at 60° solar zenith angle
   (``\mu_0 = 0.5``), the layer optical depths that reproduce the direct-beam
   profile exactly in each g point, then applies the implied
   pressure-dependent scaling to all gas tables.
3. **Coefficient optimization.** `optimize_lut` minimizes CKD-vs-line-by-line
   flux and heating-rate differences over the 50 profiles of the CKDMIP
   *Evaluation-1* dataset, using Adept's bounded limited-memory BFGS
   (quasi-Newton with automatic differentiation) acting on the natural
   logarithm of the nonzero look-up-table coefficients, with a prior/error
   covariance term (default prior error 0.25 of the log-coefficient range,
   correlation 0.8 between adjacent pressure/temperature/concentration
   entries) and configurable TOA/surface flux, flux-profile, and broadband
   weights.
4. **Staged gas optimization.** For the climate application the optimization
   is *staged*, not simultaneous over all gases: major gases first
   (`relative-base`: H₂O, O₃, CO₂ and the composite background), then the
   CH₄ and N₂O forcing differences, plus CFCs in the longwave
   (`OPTIMIZE_MODE_LIST`: `relative-base relative-ch4 relative-n2o` in the
   shortwave, with `relative-cfc` appended in the longwave).

Details of the optimization internals beyond what the pinned source and its
documentation state should be attributed to the ecCKD papers rather than
asserted independently.

## Objective Reconstruction

The recovery pipeline should report the objective terms separately. The
training/recovery pipeline itself — the objective-term and recovery-target
scripts, the preflight, and the reports under `validation/results/` that
record which parts of the published problem are available — lives on the
`validation-platform` branch together with the rest of the validation platform,
its gates, and its evidence.

## Quantitative Recovery Metrics

A recovery attempt should publish at least:

- coefficient-vector distance to the published model after matching bands and
  g points,
- objective value and per-term objective differences,
- TOA, surface, and interface flux error metrics,
- layer heating-rate error metrics,
- pass/fail status against the same thresholds used for published-model
  validation.

This is why optimizer settings matter: if all other inputs are held fixed and
the objective has one dominant minimum, the recovered model should be very
similar to the published model. If it is not, the difference becomes a useful
diagnostic of missing objective terms, data mismatch, or optimizer behavior.

## Developing New Models

After one published model is recovered, new models should follow the same
workflow:

1. choose the target g-point count,
2. initialize from a nearby published model or from a deterministic spectral
   partition,
3. optimize against the reconstructed objective,
4. evaluate against ecRad and RRTMGP reference states,
5. add the new model only after its reports and plots pass review.

The reduced-model accuracy plot should include every published and recovered
candidate so users can see the accuracy/cost curve rather than a single model
choice.
