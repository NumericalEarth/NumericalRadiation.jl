# PAPER-ONLY Gate-4 LW RECOVERY DECISION DRAFT (rev 6, for monitor
# review; supersedes rev 4 (4804ccd7/ad3fcfbe/bc05ecc7) and rev 5
# (228efcda/a2dc3ea2/6bb245d7) -- monitor rev-5 residual blockers 1-6
# folded on top of the rev-4/rev-5 corrections)
# Supersedes rev 1 (9e0bd9cd/14baf97f), rev 2 (da3fb8ef), and rev 3
# (c2869da7/8a9cce33); this
# revision folds the monitor rev-2 blockers (1-9), the monitor
# eight-array read-only closure, and the Agent 42 rev-2 items
# (A1-A4, N1 recorded) plus the monitor J0_reported precision
# correction.
# No repo edits, no code, no builds, no submissions. Scratchpad only.
# Grounding: committed ledgers at a60be91280aea7ae0d863c018520b7ee6b38ee2d
# (all values below quoted from committed ledger JSONs or byte-verified
# artifacts; nothing recomputed or invented here).

## 1. Hash-pinned fact table (committed evidence)

### B0 — bundled target-era stack viability (commit f99efea; ledger
### gate4_b0_era_stack_completion_ledger, status b0_run_completed_verified)
- MANIPULATED: the entire bundled v1.0-era stack at once. Binding
  confound note (verbatim class, committed): the b42e5c0..23adaca diff
  includes optimize_lut.cpp, ckd_model.cpp/.h, lbl_fluxes.cpp,
  average_optical_depth, plus build/script changes, the solve_lbfgs
  backend switch, and REMOVAL of the v1.2 bounded minimization --
  changed TOGETHER; the experiment is never described as
  single-variable. (This is the OPTIMIZER-ONLY-DELTA PROHIBITION: no
  claim that only the optimizer changed; carried unbroadened.)
- HELD: pinned scientific inputs (same manifest as all later units).
- OUTPUT: era raw2 swap objective 22.788012978663616; published
  self-check 0.18218645425029933; fails the <=1.05 objective gate
  (gate4_g1_objective_ratio contract); "no material recovery versus
  the v1.2 raw2".
- CEILING (committed): one deterministic bundled comparison with
  confounded source/backend/bounds deltas; era internal LBFGS
  cost/gradient records are runtime evidence only and are NEVER
  compared across stacks as a verdict; the pinned external comparator
  is the sole scoring instrument.

### S1 — state-sync one-line patch, triple-arm sandwich (commit 5b6cea7;
### ledger status s1_run_completed_verified)
- MANIPULATED: exactly one inserted line
  minimizer.ensure_updated_state(1) (bounded v1.2 modern stack).
- HELD: everything else (one tree, one configure, sandwich A0a-S1-A0b).
- OUTPUT: all 47 variables elementwise identical across A0a/A0b/S1 AND
  historical 4515; objectives bit-equal 22.791293464348826 in all four;
  census 134 below / 19 above everywhere.
- CEILING (committed): serialized-model effective-bound exceedances
  persist in every arm; ALL THREE mechanism classes (final-state
  synchronization, mapping/write, bounded-algorithm behavior) remain
  OPEN and UNRANKED globally; the internal returned x was unobserved
  in S1.

### X1 — direct post-minimize state capture (commit 4a3be7a; ledger
### status x1_run_completed_verified)
- MANIPULATED: observation only (bounds-ON capture instrument;
  non-perturbation licensed by the empirical all-variable identity
  gate against the in-job pristine arm).
- HELD: full modern pinned stack; pristine/X1 pair.
- OUTPUT (observed local outcome, durable in the ledger): returned_x_log
  lies outside the CAPTURED supplied bound vectors at 134 lower + 19
  upper coordinates; mapped==caller bit-for-bit at all 152,640 rows;
  Float32(mapped)==caller_f32 and caller_f32==raw2 bit-for-bit (mixed
  chain: one <=4-ULP exp link, then exact-bit links); reconstruction
  delta exactly 0.0; serialized objective 22.791293464348826 bit-exact.
- CEILING (committed): no observed returned-vs-caller or
  caller-vs-serialization discrepancy in that run; ORIGIN of the
  returned-x exceedances and their relationship to the objective
  remain UNRESOLVED; no historical or global claim.

### C1 — bounded_minimization flag factor (commit a60be91; ledger
### status c1_run_completed_verified)
- MANIPULATED: exactly one config-only factor, bounded_minimization=0
  (removes the bounded solver path AND the log-space bound
  construction TOGETHER -- confounded by design, stated).
- HELD: same binary in all arms (probe + C0a/C1/C0b sandwich), same
  inputs/OMP; internal validity gate (C0a==C0b logical identity AND
  terminal-status equality) HELD; historical bridge to the 4561
  pristine raw2 HELD for both controls.
- OUTPUT: controls 22.791293464348826 (bit-equal); C1
  22.467263267279066 (delta -0.3240301970697601, flag-associated FOR
  THIS FIXED SETUP); post-hoc serialized census: controls 134/19; C1
  124/18 (per-gas composite 0/15, h2o 124/3); all arms "Maximum
  iterations reached"; internal endpoints (descriptive only): controls
  16.7768 / grad 0.114057, C1 16.7358 / grad 0.0290207; iteration-0
  internal cost at the pinned init (both probe logs, identical):
  2357.13 / grad 1026.13.
- CEILING (committed): discriminates NO mechanism; no repair/recovery/
  causal claim; the returned minimizer x is UNOBSERVED in C1; C1
  census is POST-HOC serialized output vs bounds NOT supplied to the
  solver.

### Outstanding committed item (validation/gate4_unevaluated_gates_design.md)
- The earlier Gate-1 upstream definition (recovered-upstream-objective
  / published-upstream-objective, relative-base pass, "published
  floor") "was WRONG and is withdrawn" (doc rev history); the canonical
  Gate 1 is PACKAGE-NATIVE and "NOT a ratio of upstream optimizer
  costs". NO canonical upstream ratio/floor definition remains. What
  is outstanding is ONLY a full real-data UPSTREAM COST CROSS-CHECK:
  "the full real-data UPSTREAM objective/floor comparison remains
  unimplemented and unclaimed"; "Upstream's own cost values printed in
  the G3 optimizer logs are future cross-check evidence, not a current
  gate." Distinct from package-native Gate 1.

## 2. Cross-experiment statements (conjunctions of LOCAL findings only)
PROHIBITION (binding): no causal ranking by aggregation; conjunctions
below assert co-occurrence of committed local findings, never a joint
mechanism inference; the optimizer-only-delta prohibition is carried
verbatim and not broadened.
- (S1 AND X1 AND C1-controls): three independently built bounded
  modern binaries and the historical 4515 binary all serialize
  elementwise-identical scientific state with objective
  22.791293464348826 and census 134/19. LOCAL determinism/robustness
  of the bounded plateau across builds; no global claim.
- (X1): within one run, NO DISCREPANCY WAS OBSERVED at the
  returned-vs-caller and caller-vs-serialization interfaces; the
  134/19 exceedances enter at the returned x vs the exact captured
  bounds; origin unresolved.
- (B0 AND C1): the era bundle (unbounded-family, confounded deltas)
  lands at 22.788; the modern single-factor unbounded arm lands at
  22.467. These are DIFFERENT experiments under different confounds;
  no subtraction or ranking across them is licensed.
- (ALL, scoped): every RELATIVE-BASE DIAGNOSTIC TRAJECTORY observed in
  this campaign terminates at "Maximum iterations reached" with
  nonzero gradient norm (later minor-gas passes converged and are out
  of scope here). Every observed package objective (22.47-22.79)
  exceeds the <=1.05 gate by ~21x, and is ~123-125x the SEPARATELY
  LABELED published self-check 0.18218645425029933 (distinct metrics,
  never mixed numerically with internal costs). The gap is
  UNLOCALIZED: nothing committed yet establishes whether a published
  coefficient-block splice under the current fixed spectral mapping
  is even a low-cost initial point of THIS fixed internal
  objective/configuration.

## 3. Candidate-control table

### P1 — published coefficient-block internal-cost probe
### (initialization-provenance / upstream cost cross-check probe)
- EXACT QUESTION: with source/build recipe, inputs, and
  configuration PINNED to the modern campaign setup, and ONE NEW
  immutable reporting-instrumented P1 binary HELD across all six
  probes (the reporting patch is a COMMON HELD INSTRUMENT relative to
  history, not a manipulated factor), what are the REPORTED
  UPSTREAM (optimize_lut-internal) iteration-0 cost/gradient tokens
  (J0_reported) at THREE same-binary targets: PRECISION SEMANTICS
  (monitor corrections, binding): the UNPATCHED report_progress in
  pinned solve_adept.cpp:278-281 streams Real cost/gnorm with NO
  setprecision, so tokens like 2357.13/1026.13 are six-significant-
  digit FORMATTED LOG TOKENS -- NOT accepted as the primary
  instrument (the == branch could collapse at print resolution).
  P1 therefore builds its ONE saved binary with a REPORTING-ONLY
  PINNED PATCH (design below, Agent 42 to audit): report_progress
  additionally emits cost and gradient at
  std::numeric_limits<Real>::max_digits10 (round-trip decimal
  representation of the represented Real values), formatted entirely
  in a LOCAL std::ostringstream so shared logger formatting state is
  never touched. J0_reported means those max_digits10
  round-trip tokens; the ordinary rounded line REMAINS and must
  round back to the committed 2357.13/1026.13 for the init target as
  an INFORMATIONAL BRIDGE; signed pairwise deltas are token-derived
  and explicitly labeled, with NO claim beyond the represented Real
  values; "bit-equality" and "exact underlying J0" language is
  banned. Targets: (i) the pinned campaign init, (ii) the pinned
  plateau raw2 (4561 pristine, 49ff3df8...; signature-verified
  schema-identical to the init family, usable as a raw-definition
  input -- to be gated at contract time), and (iii) a private
  published COEFFICIENT-BLOCK splice? Primary outputs are the
  J0_reported token comparisons among these three; each target is
  DUPLICATED (two probes per target) to establish in-job
  repeatability by EXACT TEXTUAL EQUALITY of the extracted tokens.
- CHANGED (scoped to the WITHIN-P1 target contrast; the reporting
  instrument is common and held): ONLY the initial coefficient state
  -- a private temp
  raw-ckd-definition byte-derived from the pinned init (ce057079...)
  with ALL EIGHT gas coefficient arrays (composite/h2o/o3/co2/ch4/
  n2o/cfc11/cfc12 _molar_absorption_coeff) replaced by the pinned
  published LW32 coefficients -- a published COEFFICIENT-BLOCK SPLICE,
  never called "the published model" (planck_function,
  gpoint_fraction, min/max arrays and all other variables remain the
  init's; the splice is a coefficient block under this configuration's
  fixed spectral mapping) and never a hybrid of
  active-published/inactive-init coefficients. Integrity gate: exact
  EIGHT-variable typed diff (only those eight differ from init).
  SHAPE COMPATIBILITY VERIFIED read-only (session40 for the four
  active arrays; monitor independently for all eight): Float32,
  32x53x6 for seven gases, 32x53x6x12 for h2o, identical named
  dimensions and the identical 8-dim map incl. temperature_planck=231/
  wavenumber=326. Everything else held from the pinned init, including
  min/max bound arrays, planck_function, and gpoint_fraction (so the
  probe evaluates published COEFFICIENTS under this configuration's
  spectral mapping -- part of the scope statement below).
- MECHANISM (verified to exist AND source-verified): the "Iteration 0:
  cost function = X, gradient norm = Y" line prints in 1-iteration
  probe-class runs (byte-identical 2357.13/1026.13 in the 4561 and
  4562 unbounded probes at the pinned init; the bounded C0a emits the
  same iteration-0 values -- monitor read-only evidence). SOURCE
  SEMANTICS VERIFIED on the EXECUTED PATH (Agent 42 correction
  adopted; my earlier ~:2925-2950 citation was the CONJUGATE-GRADIENT
  variant at :2876 and is WITHDRAWN): ecckd requests
  MINIMIZER_ALGORITHM_LIMITED_MEMORY_BFGS (solve_adept.cpp:310); in
  the installed adept_source.h (8f29a64a...) the UNBOUNDED LBFGS loop
  is minimize_limited_memory_bfgs at :3902 with
  report_progress(n_iterations_, x, cost, gnorm) at :3977 firing
  BEFORE the convergence branch or any step -- so Iteration 0 IS the
  initial objective evaluation at the supplied start point on the
  executed unbounded path; the BOUNDED variant is
  minimize_limited_memory_bfgs_bounded at :4093 with the
  initial-x clamp at :4125-4128 and report_progress at :4212. All six
  line pins byte-verified this session.
  REPORTING-ONLY PATCH: EXACT TEXT (preregistered; formatting only
  -- no state, cost, gradient, or control-flow change; the virtual
  signature is unchanged; report_progress has a single override in
  this TU (Agent 42 verified) and the base-class default is not
  otherwise invoked on this path).
  Agent 42 refinement ADOPTED: LOG is a PER-CALL
  log_stream(LOG_LEVEL_INFO,...) object (src/include/Logging.h:123),
  so set/reset of "the stream" precision is not a stable concept;
  the added line is therefore formatted in a LOCAL std::ostringstream
  and streamed as a completed string (zero logger-state interaction),
  and the original rounded line is kept VERBATIM so every committed
  log gate and extraction tool survives unchanged.
  EDIT A (headers; anchored once after the pinned include
  '#include "Timer.h"'):
      #include <sstream>
      #include <iomanip>
      #include <limits>
  EDIT B (report body; anchored on the unique two-line statement at
  solve_adept.cpp:280-281, kept verbatim incl. trailing space and tab
  continuation -- BYTE-UNCHANGED -- with the block appended after it.
  MECHANISM (Agent 42 correction, binding): the payload is built in a
  LOCAL std::ostringstream WITHOUT a trailing newline and sent to the
  existing LOG as a completed string followed by a SEPARATE
  char-literal newline, because flush-on-newline exists ONLY in the
  const char[] overload (Logging.h:96-106) while the templated
  overload (Logging.h:87-93) never flushes -- so
  LOG << p1_full.str() << "\n"; flushes deterministically and leaves
  shared LogStream formatting state untouched in both directions.
  Emitted ONLY for niter == 0; gated EXACTLY ONCE per probe on the
  distinct non-colliding prefix P1_ITER0_FULL: (does not begin with
  "Iteration ", so existing extraction patterns cannot match it)):
      LOG << "Iteration " << niter << ": cost function = " << cost 
      	<< ", gradient norm = " << gnorm << "\n";
      if (niter == 0) {
        std::ostringstream p1_full;
        p1_full << std::setprecision(std::numeric_limits<Real>::max_digits10)
                << "P1_ITER0_FULL: cost_function = " << cost
                << ", gradient_norm = " << gnorm
                << ", sizeof_Real = " << sizeof(Real)
                << ", mantissa_digits = " << std::numeric_limits<Real>::digits
                << ", digits10 = " << std::numeric_limits<Real>::digits10
                << ", max_digits10 = " << std::numeric_limits<Real>::max_digits10;
        LOG << p1_full.str() << "\n";
      }
  (Direct includes <sstream>, <iomanip>, <limits> via EDIT A --
  REQUIRED: solve_adept.cpp:15-19 currently includes local headers
  only. The proof fields travel INLINE, labeled
  sizeof_Real/mantissa_digits/digits10/max_digits10, informational
  expectations 8/53/15/17; the OBSERVED runtime values are BINDING.
  The existing rounded report line is BYTE-UNCHANGED and separately
  gated exactly-once per iteration record.
  COMPILABILITY (Agent 42, source-grounded): the templated
  operator<<(LogStream&, T const&) at Logging.h:87-93 accepts the
  completed string, and Real is the bare TU signature type so the
  numeric_limits/sizeof expressions are constexpr-fine.)
  Informational expectation
  (source-grounded, Agent 42: no ADEPT_REAL_TYPE_SIZE override in
  configure/Makefiles; adept/base.h:323-330 defaults to 8):
  Real=double, digits10=15, max_digits10=17 -- the runtime proof row
  is the BINDING gate, the expectation is informational.
  BRIDGE GATES, BOTH DIRECTIONS, ALL TARGETS: ordinary rounded line
  exactly-once AND P1_ITER0_FULL line exactly-once per iteration
  record; init ordinary tokens must equal the committed
  2357.13/1026.13; and EACH full-precision token must ROUND to its
  ordinary token (6-significant-figure equivalence) -- any mismatch
  is INSTRUMENT REFUSAL.
  OMP CONSIDERATION (contract-binding): 17-digit tokens can expose
  reduction-order nondeterminism that 6-digit tokens hid; the probes
  pin the EXACT OMP settings of the committed 4561/4562 probes
  (bridge comparability); duplicate token mismatch = recorded drift
  + branch refusal; any single-thread contingency is PREDECLARED as
  a separate later monitor decision, never improvised.
  The source diff is preregistered with anchored pins (orig
  8c9822fa... -> patched sha computed at generation; region hash;
  token census); ALL SIX probes use this SAME immutable instrumented
  binary, so the three-target comparison is held (no unpatched
  second binary needed -- the bridge is internal via the rounded
  line); source-to-linked-binary provenance remains a caveat and the
  rebuilt binary/config are pinned at run time. Independent
  verification (Agent 42, read-only): Iteration 0 IS the pre-step
  initial objective evaluation in the UNBOUNDED Adept path
  (solve_adept.cpp:278-281; adept_source.h unbounded loop). BINDING
  CAVEAT (Agent 42, source-cited): the BOUNDED variant clamps x into
  bounds BEFORE the first evaluation (adept_source.h:4125-4128), so a
  spliced-init probe would read a CLAMPED state under bounded mode.
  Therefore ALL SIX probes run UNBOUNDED (bounded_minimization=0,
  C1-proven injection) -- the iteration-0 evaluation cannot be
  perturbed by bound clamping/projection of the start point, and
  target-contrast cleanliness is preserved (all six probes identical
  mode). Any future bounded variant of this probe would require an
  explicit clamp no-op demonstration first. Prior-term note,
  SOURCE-VERIFIED (monitor): x_prior is reset to each arm's start
  point and J_prior = 0 at iteration 0, making J0 a comparable
  DATA-FIT cost under the fixed covariance/RT inputs; each
  trajectory's prior anchor differs, so whole-trajectory objectives
  are NEVER called identical across targets. solve_adept.cpp is
  pinned (8c9822fa...); source-to-linked-binary provenance remains a
  caveat.
- SCOPE (binding): any P1 result is scoped to the RELATIVE-BASE PASS
  and the INTERNAL UPSTREAM OBJECTIVE under this fixed configuration
  ONLY -- never a statement about other passes, the external
  comparator, or upstream's own historical cost values.
- CONFOUNDS (stated): internal J is NOT the external comparator and is
  never a cross-stack verdict (B0 internal-cost rule honored: this is
  a WITHIN-job, same-binary, same-config comparison); the published
  model was trained upstream under its own data/config, so the probe
  answers INITIAL-COST PLACEMENT under OUR configuration only and
  establishes NO optimizer reachability; splice-integrity
  risk is closed by the committed nonfinite-aware-diff semantics
  proving an EXACT EIGHT-variable typed diff vs the pinned init.
  This binds WITHOUT qualification: monitor read-only verification
  (2026-08-14) confirmed all eight published arrays are Float32,
  dimension/shape compatible, and EACH differs wholesale from init
  (exact differing-element counts: composite 9686/10176,
  h2o 121016/122112, o3 9936/10176, co2 9643/10176, ch4 7039/10176,
  n2o 8752/10176, cfc11 3207/10176, cfc12 3395/10176). The in-job
  contract still carries the PER-VARIABLE NONZERO-DIFF GATE (each of
  the eight must differ; any identical array is evidence). The plateau
  state carries its own PINNED EXPECTATION (monitor read-only
  verification): it differs from init in exactly the four base-active
  arrays (composite 9677, h2o 121461, o3 9997, co2 9641) with the
  minor four exact-equal -- gated in-contract as the plateau
  four-active/four-exact-equal signature.
- RUNTIME/QUOTA: one build (~5 min) + SIX independent
  cloned-workspace 1-iteration probes (~5-10 min each; duplicates of
  init/plateau/published in the symmetric drift-control order
  init-a / published-a / plateau-a / plateau-b / published-b / init-b)
  ~= 1-1.5 h wall; RUNROOT footprint trivial; 06:00:00 limit vastly
  sufficient.
- OUTCOME MATRIX (preregistered, NARROWED per monitor correction; the
  probe DECIDES NO MECHANISM and licenses no causal redirection of
  the recovery decision; J0_reported max_digits10 TOKEN-DERIVED
  signed deltas ONLY, no thresholds -- the underlying mathematical J0
  is never exact-observed):
  Branches are SIGN-PARTITIONED on the DUPLICATE-CONFIRMED reported
  delta D_reported = J0_reported(splice) - J0_reported(plateau), a
  signed DECIMAL delta computed on the reported tokens only and
  explicitly bounded by stream precision:
  (a) D_reported < 0 (negative): the current reconstructed relative-base
      objective assigns the spliced private state a lower initial
      cost than the plateau state. This does NOT establish a basin,
      initialization failure, trajectory failure, solver
      reachability, or recovery.
  (b) D_reported == 0 (zero at max_digits10 REPRESENTATION --
      distinct from exact mathematical equality of the underlying
      Reals), or
  (b') D_reported > 0 (positive): the current reconstructed relative-base
      objective does not prefer that splice at its initial
      evaluation. This is CONSISTENT with data/objective/version/
      training-context mismatch but ATTRIBUTES NONE of them.
  (No COMPARABLE or material class exists: the branches are the
  exhaustive sign partition of the reported delta, and ALL THREE
  pairwise signed DECIMAL deltas, defined by formula --
  D_splice_plateau = Js - Jp, D_splice_init = Js - Ji,
  D_plateau_init = Jp - Ji (Ji/Jp/Js = J0_reported of init, plateau,
  splice) -- are recorded on the reported tokens, bounded by stream
  precision.)
  DUPLICATE REFUSAL SEMANTICS (binding): per-target duplicates
  require EXACT TEXTUAL EQUALITY of each extracted reported cost
  token and gradient token before any branch assignment; a mismatch
  is RECORDED DRIFT and a REFUSAL for branch assignment -- values are
  NEVER averaged; this applies to ALL THREE targets (init, plateau,
  splice).
  (c) In every branch: the published model need not be the minimizer
      of this exact reconstructed pass; all coefficient splicing
      changes initialization AS A BLOCK; the unit can NARROW the
      outstanding upstream cost cross-check item, not decide the
      mechanism. Without the plateau target, plateau-relative
      inferences would be WITHDRAWN; with it, they are direct
      same-binary iteration-0 comparisons.
  INTERNAL-COST COMPARISONS ONLY: J0_reported tokens are compared
  only to other J0_reported tokens from the same job (init / plateau
  raw2 / published-splice, each duplicated; token-derived signed
  decimal deltas) and never numerically to the 22.x
  package/comparator objectives except as separately labeled metrics;
  trajectory endpoint prints (16.7768/16.7358) are descriptive
  context, never J0_reported comparators. The init rounded tokens
  must reproduce the committed 2357.13/1026.13 (informational bridge,
  cross-checked against the two committed probe logs; drift is
  evidence, not silently absorbed).
- RECOVERY RELEVANCE: the lowest-cost unit that produces the first
  real-data published-coefficient-block internal-cost value under this
  configuration, narrowing the committed outstanding UPSTREAM
  cost cross-check item; its outcome INFORMS monitor sequencing of the
  remaining candidates without any automatic priority or causal
  redirection claim. Explicitly NOT recovered acceptance and NOT
  permission to change objective/data: the external comparator and
  the <=1.05 gate remain untouched.

### C2 — era-internal minimizer-backend switch
- QUESTION: within the era bundle, does routing the era build from
  solve_lbfgs to era solve_adept (by removing USE_LBFGS_LIBRARY)
  change the era raw2/objective? This is a MINIMIZER-BACKEND switch
  inside the era stack -- NOT an Adept linkage or gradient-engine
  swap (B0 call-path proof pinned the dispatch at USE_LBFGS_LIBRARY).
- CHANGED: the compile-time backend routing only. HELD: era
  sources/scripts/inputs otherwise.
- CONFOUNDS: still inside the confounded era bundle (B0 confound note
  verbatim); source-to-binary provenance caveats persist.
- RUNTIME: build + 1-2 arms, ~1-2 h.
- OUTCOME MATRIX: objective/census move vs B0 era values, recorded;
  either way the era bundle remains confounded for recovery purposes.
- RECOVERY RELEVANCE: LOW. The cited modern relative-base arms
  (S1/X1/C1-control family) reproduce the plateau bit-exactly; the
  era bundle already showed no
  material recovery; a minimizer-backend switch inside the era bundle does
  not address the unlocalized gap to the separately labeled published self-check.

### C3 — modern iteration-budget control
- QUESTION: is the modern plateau budget-limited? (Every arm caps at
  3000 with nonzero gradient norm.)
- CHANGED: max_iterations only (e.g., 9000), C1-proven injection;
  bounded default held; same-binary sandwich control.
- CONFOUNDS: none structural; runtime scaling only.
- RUNTIME: ~3x arm (~105 min) + control (~35 min) + probe; ~3 h.
- OUTCOME MATRIX: exact objective/census deltas of the budget arm vs
  the same-job control, recorded with no threshold ("materially"
  language withdrawn); no mechanism ranking; next sequencing requires
  a later monitor ruling.
- RECOVERY RELEVANCE: MODERATE; P1's outcome is NEUTRAL sequencing
  context only -- initial-cost placement does not predict
  iteration-budget response, and no prediction, priority collapse, or
  causal conditionality is claimed; sequencing is a later monitor
  ruling.

### X2 — unbounded direct-capture control
- QUESTION: in the unbounded path, does the returned x equal the
  callback/serialized state (B/C analogs), and where does the returned
  x sit vs the file-derived bounds (descriptive A analog)?
- CHANGED: a new unbounded-branch capture instrument (new patch,
  new review surface; the X1 patch deliberately gates that branch
  unchanged). HELD: C1 machinery otherwise.
- CONFOUNDS: new instrument code path; same callback-lag semantics.
- RUNTIME: ~X1-class (~2 h) incl. probe + pristine + instrumented.
- OUTCOME MATRIX: B/C-analog zero or nonzero, recorded; A-analog
  descriptive.
- RECOVERY RELEVANCE: LOW-MODERATE: completes instrumentation symmetry
  but does not advance the plateau-vs-published question.

## 4. Ranking (information gain per compute cost) and recommendation
Explicit reasoning, including the monitor's addendum constraint that
C2/iteration-budget may not outrank the upstream cost cross-check probe without
justification:
- P1: HIGHEST gain/cost by a wide margin (~1-1.5 h; each
  sign-partitioned branch on the token-derived deltas is informative
  for monitor sequencing; it is the only candidate that narrows the
  committed outstanding upstream cost cross-check item; the
  Iteration-0 executed-path semantics are SOURCE-VERIFIED and the
  max_digits10 instrument's high-precision repeatability is
  EXPLICITLY TESTED in-job -- historical six-digit repeatability is
  only an informational bridge; shape compatibility verified for all
  eight arrays).
- C3: moderate gain at ~3 h; sequencing after P1 is preferred because
  P1's ~1-hour result is relevant context for whether 3 h of budget
  extension is the next-best spend -- a sequencing judgment for the
  monitor, not a causal conditionality.
- X2: instrumentation completeness, low decision leverage now.
- C2: lowest gain/cost; confounded era bundle; nothing in the
  committed record makes the era minimizer backend a live recovery
  lever.
RECOMMENDATION: exactly ONE next unit -- P1, the published
coefficient-block internal-cost probe, under the preregistered
conclusion ceiling below.

PREREGISTERED CONCLUSION CEILING for P1 (binding, fixture-guard
candidate): P1 outcomes speak ONLY to whether the published LW32
COEFFICIENT BLOCK, spliced under the current fixed spectral mapping,
constitutes a lower internal-cost initial point under THIS fixed
modern configuration, binary, and pinned full real-data inputs --
never the full published parameter state/model. They
are NOT recovered acceptance, NOT a floor claim of any kind (the single
computed value is an upstream internal-cost value at the published
coefficient block under this configuration), NOT
permission to change objective or data, and NOT a mechanism ranking;
internal J values are within-job descriptive instruments, never
cross-stack verdicts; J0_reported token values are never numerically
compared to the 22.x package/comparator objectives except as
separately labeled metrics; the published model need not be the
minimizer of this exact reconstructed pass and coefficient splicing
changes initialization AS A BLOCK; the external pinned comparator and
the <=1.05 gate remain the sole acceptance instruments; all three
mechanism classes remain OPEN and UNRANKED globally; findings are
LOCAL to this rebuilt trajectory; no historical or global claim.

## 5. Implementation/evidence contract outline for P1 (when authorized)
- Checkpoint generator + sbatch on the C1 machinery (pins, custody,
  OMP controls, data-tree immutability, frozen template, single
  build OF THE REPORTING-ONLY INSTRUMENTED BINARY (patch design
  above; anchored pins, exactly-once gates, inline proof fields
  gating sizeof_Real/mantissa_digits/digits10/max_digits10), zero
  canonical writes, RUNROOT preserved).
- THREE PINNED/GATED INPUT STATES: (i) pinned init (ce057079...,
  2,413,144 B), (ii) pinned plateau raw2 (49ff3df8..., 2,415,304 B;
  full 47-variable pinned-signature scan gating its use as a
  raw-definition input), (iii) published LW32 artifact pinned in full
  (6087f62f9052653f8e7dbee26cef8bf1977c2516669a169bee8d110b62912ed9,
  869,280 B) feeding the IN-JOB SPLICE CONSTRUCTION (private temp,
  never canonical):
  copy the pinned init byte-verified; replace ALL EIGHT gas
  coefficient arrays with the pinned published LW32 arrays (both
  files sha-bracketed); integrity gate = the committed
  nonfinite-aware-diff semantics proving an exact EIGHT-variable
  typed diff vs init with a per-array differs-proof, and everything
  else (incl. min/max arrays, dims, attrs) identical; full
  47-variable pinned-signature scan on the spliced file.
- SIX independent cloned-workspace 1-iteration UNBOUNDED probes --
  duplicates of each target -- ALL SIX from the SAME saved immutable
  binary, identical config overrides, and identical logged OMP
  controls, in the symmetric drift-control order
  init-a / published-a / plateau-a / plateau-b / published-b / init-b
  (monitor-specified symmetric order, RETAINED because it brackets
  each target symmetrically in time -- each target's duplicates
  straddle the job midpoint, so slow monotonic drift shows up as
  within-target token mismatch; Agent 42's non-blocking interleave
  alternative is recorded);
  per-probe gates: unbounded banner exactly once, 1-iteration banner
  exactly once, "Iteration 0: cost function" line exactly once,
  status recorded (allowlist not applied to probes); iteration-0
  cost/gradient tokens extracted verbatim into the ledger;
  REPEATABILITY GATE: EXACT TEXTUAL EQUALITY of the extracted
  max_digits10 round-trip cost token and gradient token WITHIN each
  duplicated target (a/b); mismatch = recorded drift + refusal for
  branch assignment (never averaged); arm status/schema gates must
  agree; the ordinary rounded init line must still round back to the
  committed 2357.13/1026.13 tokens (informational bridge; drift is
  evidence). PRIMARY OUTPUTS: the three J0_reported max_digits10
  token values and ALL THREE pairwise signed DECIMAL deltas,
  token-derived and labeled, with no claim beyond the represented
  Real values.
- Prior-term source verification (both prior forms at x == x_prior)
  recorded as a source-cited gate before interpretation.
- Completion ledger: preregistered outcome matrix applied
  mechanically; the P1 ceiling verbatim and fixture-guarded;
  REPEATABILITY is gated on the extracted per-target Iteration-0
  tokens plus status/schema -- BYTE determinism is NOT inferred for
  logs/outputs (path/timestamp/build noise) and would be claimed only
  for an explicitly normalized artifact actually byte-compared; dual
  custody receipts; no census claims (probe outputs are not
  scientific arms; any serialized one-step outputs are STRUCTURAL
  evidence only).
- Explicit linkage paragraph to gate4_unevaluated_gates_design.md:
  what the computed upstream cost value at the published coefficient
  block closes or narrows (a first real-data upstream internal-cost
  value at the published coefficient block under THIS configuration) and what remains open
  (upstream's own historical cost values, any cross-configuration
  floor claim, package-native Gate 1 -- all untouched).
