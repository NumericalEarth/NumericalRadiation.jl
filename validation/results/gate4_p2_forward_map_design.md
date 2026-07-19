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
    --upstream heating convention--> heating rates (SW: downwelling-only
      divergence per Appendix A; LW: per upstream source, net-flux)
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
- G1 forward parity, TERM-RESOLVED and TARGET-SPLIT BY BAND: for the
  PUBLISHED model on shared profiles (pinned tool run once to emit
  references; provenance-stamped). LW: compare flux_up AND flux_dn
  directly against run_ckd's emitted spectral/broadband LW fluxes
  (identical RT). SW: run_ckd emits only the direct-down component at
  mu0=0.5 — compare that component directly; SW upwelling, heating, and
  objective-term parity must be established against the cost-function
  recurrences and internally verified analytic fixtures (G0 hand
  cases), NEVER against the external *_fluxes-4angle_* / ckdmip_sw
  two-stream products, which use a different RT.
  Compared per term: flux_dn and flux_up profiles, heating rates AS THE
  UPSTREAM CONVENTION DEFINES THEM (SW downwelling-only per Appendix A;
  never generic net-flux heating), and
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

## Appendix A — pinned upstream conventions (source-verified)

- SW heating in the training cost uses DOWNWELLING flux divergence only:
  calc_cost_function_ckd_sw computes heating via
  heating_rate(pressure_hl, flux_dn_fwd, aMatrix(), heating_rate_fwd)
  (~lines 195-198; empty upwelling matrix), even though upwelling flux
  exists and feeds the surface/TOA/profile cost terms (direct vs
  norayleigh branch selection ~149-159). HIGH-RISK PARITY REQUIREMENT:
  gate4_forward_map.jl must encode this convention explicitly — a
  generic net-flux (dn - up) divergence for SW heating would fail G1
  with a systematic signed bias. Consistent with the Julia loss port
  (SW heating targets computed down-only in
  ckdmip_original_objective_dataset.jl).
- The 20x multiplier applies to the TOA UPWELLING spectral boundary
  term (~line 214), matching the Julia port's placement
  (ecckd_original_objective_loss.jl:137,146).
- The full anchored inventory landed as Appendix B (source recon
  complete); Appendix A is retained for the two highest-risk
  conventions it pinned first.

## Appendix B — upstream semantics spec (from source recon, anchored)

Parity targets (G1): LW compares directly against run_ckd's
spectral_flux_{up,dn}_lw / flux_{up,dn}_lw (identical RT: diffusivity
1.66, black surface, CKD Planck LUT; run_ckd.cpp:340-357). SW has NO
direct target — run_ckd emits only direct downwelling at mu0=0.5
(run_ckd.cpp:358-368) and the external ckdmip_sw 4-angle/two-stream
fluxes use a DIFFERENT RT: replicate the cost-function SW RT and test
against run_ckd's direct-dn component plus internally-verified
recurrences. Never target the *_fluxes-4angle_* products for G1.

REQUIRED OBJECTIVE COMPONENTS BEYOND THE PORTED KERNELS (design
correction): the full training objective adds (a) a PRIOR term
0.5·(1/bg_err_g^2)·Δx^T S^-1 Δx per active gas/g over the log-coeff LUT
(S = tcorr^|Δt|·pcorr^|Δp|·ccorr^|Δc|, corr=0.8 climate; prior_error
8.0 LW / 2.0 SW; ckd_model.cpp:616-849) and (b) a negative-OD penalty
1e4·Σ od² (1e1 in LW relative-ch4) with od clamped ≥0 after
(solve_adept.cpp:105-114). ecckd_original_objective_loss.jl covers the
flux/heating kernels ONLY — G3 floor and recovery runs are invalid
without (a)+(b).

Reimplementation checklist (values; anchors in the recon brief):
 1. LW diffusivity 1.66; emissivity 1-exp(-1.66 τ).
 2. LW source factor: 1-(1/1.66)·emiss/τ if emiss>1e-5 else 0.5·emiss.
 3. LW recurrences: Fdn(TOA)=0; dn weights (emiss-factor, factor);
    surface Fup=ε·B_s+(1-ε)·Fdn; up weights swapped.
 4. Surface emissivity 1.0 (black) everywhere in training.
 5. LW Planck from CKD planck_function LUT (T grid 120:350, linear;
    T<120 scales to zero); π-integrated band irradiance W m^-2.
 6. SW direct: Fdn(0)=cos_sza·ssi; Fdn(l+1)=Fdn(l)·exp(-τ/cos_sza).
 7. SW upwelling secant 2.0 (Zdunkowski 60°): Fup(sfc)=albedo·Fdn;
    Fup(l)=Fup(l+1)·exp(-2τ). No two-stream Rayleigh.
 8. SW Rayleigh τ added into total τ; rayleigh_molar_scattering_coeff
    read fixed from the CKD file; Δmoles=Δp/(g·0.001·M_air), M=28.970.
 9. SW albedo = per-band effective_spectral_albedo from LBL up/down
    ratio, mapped by iband_per_g; zeroed for bands with wavenumber2 >
    max_no_rayleigh_wavenumber (10000; 15000 minor SW passes).
10. SW mu0 = LBL mu0[{0,2,4}] = {0.1, 0.5, 0.9}; each col×angle is a
    training column.
11. SW TOA normalization: ssi scaled by tsi_lbl/Σ solar_irradiance,
    tsi_lbl = Fdn(0,0)/mu0(0).
12. Heating: HR = -(9.80665/1004.0)/Δp · (ΔFdn - ΔFup); SW Fdn ONLY
    (Appendix A); pressure increases with index (TOA=0).
13. hr_weight 86400, squared inside the cost.
14. layer_weight = normalized diff(sqrt(p_hl)); interface_weight =
    flux_profile_weight·midpoint(layer_weight).
15. Cost: per-band terms scaled (1-broadband_weight)/nband + broadband
    blend; SW per-band TOA-up ×20, NO ×20 in broadband part.
16. Band aggregation via iband_per_g: climate LW FSCK = 1 band;
    SW rgb = [0 0 0 0 1 2 3 4 4].
17. OD interpolation: bilinear (log-p, T), + log-conc for LUT gases;
    LINEAR in coefficient; relative-linear uses (vmr - ref_vmr)
    [CH4 1921e-9, N2O 332e-9]; indices clamped to [0, n-1.0001].
18. Negative-OD penalty per Appendix B above.
19. Prior term per Appendix B above; prior mean = initial log-coeffs.
20. Bounds [log min, log max] from create_lut min/max arrays; where
    min==0: x_min = 3x - 2·x_max. Bounded minimization ALWAYS ON (the
    SW script's bounded_optimization=0 is a dead key/typo).
21. Optimizer envelope (upstream): L-BFGS, max_step_size 2.0, converge
    on grad-norm ≤ 0.02 (base passes) / 0.0005 (minor), max_iter 3000
    LW / 2000 SW. Ours may differ (optimizer-only-delta rule) but must
    report the same convergence diagnostic.
22. Fixed arrays never optimized: gpoint_fraction, solar_irradiance,
    rayleigh_molar_scattering_coeff, planck_function/temperature_planck,
    coordinates/bands. Trainables per stage: LW relative-base
    {composite,h2o,o3,co2} (from raw-ckd-definition), then ch4, n2o,
    {cfc11,cfc12}; SW relative-base {composite,h2o,o3,co2} (from
    scaled-ckd-definition), then ch4, n2o. Minor-gas passes use
    relative_to rel-415 flux DIFFERENCES in the cost.
23. Weights (climate): LW prior 8.0, broadband 0.8, profile 0.2,
    spectral_boundary 0.1, flux_weight 0.02 base / 0.5 ch4,n2o / 0.2
    cfc; SW prior 2.0, broadband 0.4, flux 0.4, profile 0.1.
