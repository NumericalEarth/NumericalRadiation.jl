# Gate-4 P2 design: differentiable coefficients → optical depth → flux forward map

Status: reviewed scratch design moved into repo artifact (Codex-monitor pass, 4 revisions applied).
Branch: glw/gate4-recovery (P1a HEAD 3663b64). Author: main session, 2026-07-19.

## 1. Objective

Provide L(θ): a differentiable map from the trainable ecCKD coefficient
vector θ to the reconstructed original CKDMIP objective, so that staged
gradient optimization (SW relative-base → relative-ch4 → relative-n2o;
LW + relative-cfc) can run from the upstream pre-optimization state.
This is the piece P1a certified as missing
(coefficient_gradient_status = blocked_no_differentiable_forward_map).

## 2. Inputs / outputs

- θ as STATE vs θ as TRAINABLE (distinct concepts, reviewer-mandated):
  the full flat SW32 (later LW32) recovery vector from
  flatten_recovery_arrays — per-gas molar-absorption LUTs plus support
  arrays (g-point fractions, solar irradiance, Rayleigh) — is the
  plumbing/state representation (204,896 entries for SW32). The
  TRAINABLE set per stage is strictly what the corresponding upstream
  pass optimizes (from pass_sequence metadata in
  ecckd_original_objective_terms.jl, verified against the pinned tool's
  optimize_lut invocations): stage masks activate only those blocks;
  everything else is FROZEN state. Freeze/constraint policy must be
  documented per array class in the implementation PR: support arrays
  frozen unless the upstream pass provably optimizes them; any
  normalization/simplex constraint the upstream tool enforces (e.g. on
  g-point weight structures) replicated as an explicit constraint, not
  left to the optimizer to discover.
- Data sample: one CKDMIP evaluation-1 column × scenario — layer T, p,
  gas concentrations (converted to layer absorber amounts, mol m^-2,
  composite included — per the adopted unit rule), plus the LBL target
  fluxes/heating from the restored flux files.
- Output: scalar loss via the existing ecckd_{lw,sw}_ckd_loss kernels
  (AD-verified at 1e-10 in P1a); per-sample fluxes exposed for
  diagnostics.

## 3. Critical scientific decision: match UPSTREAM RT semantics

The recovery claim requires our CKD-side fluxes to be computed the way
the upstream tool computes them inside optimize_lut
(calc_cost_function_ckd_{lw,sw} + its radiative transfer), NOT the way
ecRad or our production streaming solver would. Action item before
implementation: read the pinned ecckd artifact sources
(src/ecckd/*.cpp: calc_cost_function*, radiative transfer used in LW
up/down exchange and SW direct+Rayleigh path) and document, in the
implementation PR: diffusivity factor(s), mu0 quadrature set, Rayleigh
treatment, surface albedo/emissivity conventions, and band/g mapping.
UNCERTAINTY FLAG (for reviewer): this is where a silent mismatch would
poison the floor check; the design gates below are built to catch it.

## 4. Architecture and AD ownership

Pure-Julia, validation-side module (validation/gate4_forward_map.jl):
does NOT touch src/ solvers (package stays frozen; optimizer-only-delta
rule keeps the objective/data fixed and puts all novelty in the
optimizer stack).

Chain, all Enzyme-reverse differentiable:
  θ (log LUT entries) --exp--> molar absorption
    --interpolate (T, log-p, [H2O] trilinear, matching upstream table
      axes)--> per-layer per-g optical depth (54×32)
    --RT recurrence (upstream semantics, sequential over layers)-->
      fluxes at 55 interfaces
    --flux divergence--> heating rates
    --ecckd_{lw,sw}_ckd_loss--> scalar.

AD boundaries:
- Differentiated: exp/log reparameterization, interpolation weights
  application, RT recurrences, loss kernels.
- Constant (no grad): pressure grids, layer weights, LBL targets,
  concentrations, stage masks, interpolation INDEX selection (indices
  precomputed per sample; only weights enter the tape) — avoids
  Enzyme control-flow pathologies.

## 5. Memory & compute strategy

Per-sample tape is tiny (54×32 chain). Strategy: sample-at-a-time
reverse pass, accumulate ∇θ (1.6 MB) across samples; never batch tapes.
Full SW stage epoch ≈ 50 columns × ~20 scenario files ≈ 1000 samples.
Cost model from P1a: kernel ~50 µs; forward map estimated ~0.5–2 ms per
sample; adjoint ~4×. Full-gradient epoch: seconds to ~10 s on one
cpu-large node — a SIZING HYPOTHESIS until measured; G1/G2 runs must
carry wall-clock and MaxRSS instrumentation (per-phase timings in their
artifacts, same style as gate4_cost_probe), and the hypothesis is
confirmed or revised from those measurements before any long optimizer
run is scheduled. CPU-feasible if confirmed; H100/Reactant remains an
opt-in acceleration (per-sample loss+grad compile, the pattern P1a
validated), not a requirement.

## 6. Optimizer plan (P4 preview, constrains P2 interfaces)

Bounded L-BFGS in log-coefficient space (upstream uses L-BFGS/Adept;
ours may differ per the optimizer-only-delta rule). P2 must expose:
loss(θ, batch, mask), grad!(∇, θ, batch, mask), and bounds metadata.
Staged executor consumes pass_sequence metadata; each stage freezes
non-stage gases via the mask.

## 7. Validation gates (each becomes an artifact with provenance)

- G0 unit: interpolation reproduces table nodes exactly; adjoint of
  each stage vs FD on 32-entry subsets (<1e-6), synthetic inputs.
- G1 forward parity, TERM-RESOLVED: our values for the PUBLISHED model
  vs the upstream tool's own CKD evaluation outputs on shared profiles
  (run the pinned tool once to emit references; provenance-stamped).
  Compared per term: flux_dn and flux_up profiles, heating rates, and
  each objective term — with explicit absolute AND relative thresholds
  set per quantity in the implementation PR (initial proposal:
  |Δflux| ≤ 1e-3 W m^-2 or rel ≤ 1e-6, heating rel ≤ 1e-6, objective
  terms rel ≤ 1e-6; to be tightened/relaxed with evidence), PLUS a
  no-systematic-signed-bias check (sign-balanced residuals across
  layers/columns; a one-sided residual at ANY magnitude = RT semantics
  mismatch, stop and fix). "Near float precision" alone is neither
  sufficient (hides bias) nor necessary (implementations may differ in
  summation order).
- G2 real-data gradient check: Enzyme vs FD at real rel-415 samples.
- G3 floor check (absorbs the P1b gate): L(published-final) on the full
  fixed dataset; require CONSTRAINED ACTIVE-SET STATIONARITY under the
  same stage masks, bounds, and stage ordering the upstream tool used —
  i.e., for each upstream stage in order, the projected gradient on
  that stage's trainable set (bounds-active components projected out)
  admits no descent direction improving beyond tolerance. NOT
  unconstrained FD descent across all flattened parameters (frozen
  support arrays and bound-active entries would produce spurious
  "descent" and falsely fail the floor). Validates the objective
  reconstruction itself.
- G4 controlled recovery smoke: perturb published coefficients by a
  known delta (e.g., +2% on one gas block), recover within the
  recovery metrics (weight L1 ≤ 0.02, OD log-RMSE ≤ 0.02). Catches
  optimizer/mask bugs before the real raw-init acceptance run.

## 8. Connection to the real-data floor gate and acceptance run

G3 IS the floor gate, on real data, once 4078 installs the derived
products and preflight goes green. The acceptance run then starts from
the upstream pre-optimization state (LW raw-ckd-definition;
SW scaled-ckd-definition — to be produced by the pinned tool's
create_lut/scale_lut stages against fixed CKDMIP inputs, provenance
recorded), runs the staged executor, and is scored by
ecckd_recovery_metrics.jl + the published-model accuracy harness.
Published-final-initialized runs remain diagnostic-only, labeled.

## 9. Deliverables & order

1. validation/gate4_forward_map.jl (interpolation + RT + wiring) + G0.
2. Upstream-semantics notes + G1 parity artifact.
3. Dataset generalization (all columns/scenarios; mol m^-2 conversion
   helper WITH the regression test required by the adopted rule).
4. G2/G3 artifacts (real data).  5. G4 smoke.  6. Staged executor (P4).
