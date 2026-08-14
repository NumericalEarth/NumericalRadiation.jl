# Gate-4 P2 FROZEN DESIGN: four-state package-native hard-objective
# placement (monitor NEXT-UNIT RULING 2026-08-14; Agent 42 review
# focus folded at design time)

## Unit identity
- DIAGNOSIS unit; PRIVATE outputs only; zero canonical writes; RUNROOT
  preserved on success AND failure; no optimizer anywhere; submission
  and commit only on explicit monitor GO.
- Grounding: committed P1 ledger (commit 4501220e; POSITIVE branch,
  neutral sequencing context), next-control decision memo rev 3
  (0b9f73f51a433e59e573b9957a781c4a820f482e36564a9d90089e008d677a09),
  monitor next-unit ruling text (binding), Agent 42 acknowledgment
  with the package-tree TOCTOU review focus (binding at design time).

## Question (fixed setup only)
Under the package-native hard-objective instrument -- hard_objective
(validation/ecckd_published_model_accuracy.jl:183) over REDUCED_CASES
via case_metrics and read_ecckd_tabulated_gas_optics -- where do FOUR
fixed LW states place relative to EACH OTHER, holding ONE pinned
published SW32 state fixed?

## Four LW states (content pins; committed P1 checker gates)
1. init: pinned campaign init raw (ce057079..., 2,413,144 B).
2. plateau: pinned 4561 pristine raw2 (49ff3df8..., 2,415,304 B).
3. splice: PRIVATE published-coefficient splice, reconstructed IN-JOB
   from the pinned init + published LW32 (6087f62f..., 869,280 B) by
   the COMMITTED P1 checker (gate4_p1_splice_checker.jl, abebffc6...):
   build-splice + gate-splice (exact eight-variable typed diff, pinned
   per-array counts, attrs/signature) + gate-plateau for state 2.
4. published-final: the pinned published LW32 ckd-definition itself
   (6087f62f...) -- the fourth control (monitor panel ruling).

## Arms and order (binding)
Eight arms, each a FRESH model load + scoring, palindromic
drift-control order:
  init-a plateau-a splice-a published-a published-b splice-b plateau-b init-b
(each state's duplicates straddle the job midpoint).

## Instrument (one immutable evaluator; canonical eight-gas)
- EXACT CALL SHAPE (the committed S1 kernel form,
  gate4_s1_state_sync_completion_ledger.jl:541-544):
  read_ecckd_tabulated_gas_optics(lw_path, sw_path;
      gas_names = (:composite, :h2o, :o3, :co2, :ch4, :n2o, :cfc11,
                   :cfc12),
      h2o_mole_fraction = 0.005)
  then hard_objective([case_metrics(c, model) for c in REDUCED_CASES]).
- SOURCE PINS (byte-containment at generation AND in-job): the exact
  REDUCED_CASES construction (reduced_ecckd_accuracy.jl:12-16 with
  REQUIRED_CASES from ecrad_reference_manifest.jl), the exact
  case_metrics text (reduced_ecckd_accuracy.jl:511+), the exact
  hard_objective text (ecckd_published_model_accuracy.jl:183-244),
  and the S1 kernel-identity containment (sl_swap_objective text in
  the committed S1 ledger) -- the instrument-identity claim is gated,
  not prose.
- FIXED SW (binding rationale, monitor; filename corrected per
  Agent 42 design review D1): the pinned published SW32 is
  ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc from the hash-pinned
  ecrad artifact tree (the published LW file is ecckd-1.0; the SW of
  the :climate_32x32 pair and the comparator :shortwave_32 selector
  is v1.4 -- verified read-only); 851,724 B, sha
  49abc7bf88b80252e4f9934f8659d108ffee6a101124b2fd080f2eb65d144eb3
  (S1 ledger provenance :200-202), re-derived and embedded at
  contract generation. The generator carries a REFUSAL FIXTURE for
  v1.0-SW substitution (any ecckd-1.0_sw staging/reference refuses). It reproduces the 0.18218645425029933 same-instrument
  control and removes recoverable SW error from the LW localization.
  All conclusions conditional on this SW.
- CASE-SET IDENTITY (Agent 42 R1, stated in the frozen text): the
  committed S1 kernel scored snapshot_cases built from SL_CASE_INPUTS
  = exactly the two REDUCED_CASE_NAMES reference files
  (ecckd_clear_sky_tropical_column + ecckd_rcemip_style_column_subset,
  sha/size-pinned), so the historical 102.67056437657112 /
  22.791293464348826 / 0.18218645425029933 values are
  same-instrument-SAME-CASESET readings and the refuse-on-miss
  reproduction gates are well-founded on committed provenance.

## Package-tree/environment TOCTOU closure (Agent 42 review focus;
## designed-in, not retrofitted)
The evaluator consumes THE PACKAGE ITSELF, so the package tree is a
scientific-code input staged/pinned exactly like the ecckd source
tree in P1:
- STAGED EVALUATOR WORKING SET, manifest-pinned at generation
  (per-file sha + exec bits + census) and content-verified in-job
  before use, chmod -R a-w, writable-scan, post-run reverified:
  * $RUNROOT/pkg/Project.toml + Artifacts.toml + src/ (full tree) +
    ext/ (all three extension files) -- the NumericalRadiation
    package. Artifacts.toml is REQUIRED (monitor hard-hold finding,
    reproduced staged-form failure): src/io/ecckd_definition.jl
    expands @artifact_str("ecrad_data") at MACRO TIME, which resolves
    the package's (Julia)Artifacts.toml relative to the package root
    -- a staged tree without it cannot even `using NumericalRadiation`.
    The generator carries (i) a REAL staged-form behavioral fixture
    (temp tree, rendered set, rendered invocation form) requiring
    pathof(NumericalRadiation) under the staged pkg/src,
    Base.get_extension(NumericalRadiation,
    :NumericalRadiationNCDatasetsExt) !== nothing, and the reader
    binding available -- a text gate is insufficient; and (ii) a
    NEGATIVE fixture with Artifacts.toml omitted/tampered that
    refuses. LOAD-TIME vs RUNTIME resolution (Agent 42 nuance; monitor
    wording ruling, licensed statement): staging Artifacts.toml
    enables MACRO-TIME resolution at `using`; live-depot artifact
    metadata/path checks MAY still occur during package load (the
    @artifact_str expansion may resolve/check/install via the live
    depot even though P2 never calls official path selectors) -- that
    behavior is exactly the recorded live-depot residual, and NO
    claim of globally zero post-freeze artifact-content reads is
    made. P2's SCIENTIFIC LW/SW payloads are nevertheless consumed
    ONLY from the explicit staged masters, and no evaluator/checker
    argument may carry a live artifact-tree path (text-gated); the
    behavioral fixture proves staged package/extension/reader
    resolution and explicit staged scientific paths, never the
    absence of all depot accesses;
  * $RUNROOT/pkg/validation/{validation_results.jl,
    ecrad_reference_manifest.jl, write_ecrad_candidates.jl,
    reduced_ecckd_accuracy.jl, ecckd_published_model_accuracy.jl} --
    the include-safe evaluator chain (ABR_ROOT resolves via @__DIR__
    to $RUNROOT/pkg, so the staged layout is self-consistent);
  * $RUNROOT/pkg/validation/reference/ecrad/<REDUCED case files> --
    the exact reference .nc files REDUCED_CASES consumes, resolved
    mechanically at generation (path list derived from the pinned
    chain, never hand-listed), sha+size pinned;
  * $RUNROOT/julia-env/{Project.toml, Manifest.toml} -- the staged
    test environment (sha-pinned; NCDatasets provider; NOTE the live
    test/Manifest.toml is git-ignored yet exists (S1-pinned
    cf9f318d...) -- usable ONLY under the staging bracket below);
- STAGING READ BRACKET (binding, applied uniformly to package/env/
  reference/scientific-input staging): stage 0 pins and preflights
  the live sources (sha/size); stage 1 COPIES from live into the
  RUNROOT and IMMEDIATELY verifies each staged copy's sha/size
  against the stage-0 pin (with a source post-copy sha re-check where
  a source is consumed more than once); after the successful stage-1
  freeze (chmod a-w + writable-scan), no EXPLICIT live
  repository/test-environment/scientific-input PATH is supplied to any
  evaluator/checker/gate -- their explicit code/reference/LW/SW path
  arguments resolve under $RUNROOT, while Julia
  loader/dependency/depot reads remain the recorded residual.
  * THREE external LW masters -- init, plateau, published LW -- plus
    the SW master under $RUNROOT/source-inputs/ (P1 pattern). The
    SPLICE IS NOT A MASTER and is NEVER copied from any
    mutable/preserved P1 output path: it is reconstructed INSIDE the
    RUNROOT from the staged init + staged published masters by the
    staged committed P1 checker, then sha-pinned and gated in place.
    The generator carries a NO-EXTERNAL-SPLICE-PATH fixture (any
    staging row or checker argument sourcing a splice from outside
    $RUNROOT refuses).
- PINNED ENV RESOLUTION (explicit in the sbatch): the ONLY evaluator
  invocation form is
    JULIA_LOAD_PATH="@:$RUNROOT/pkg:@stdlib"
    "$JULIA_BIN" --project="$RUNROOT/julia-env" <staged checker> ...
  with the pinned julia launcher + exact --version gate (P1 pattern).
  The live repository appears nowhere on evaluator LOAD_PATH; each
  evaluator command's explicit project/package/checker/reference/
  scientific path arguments are staged under $RUNROOT;
  manifest-resolved dependency content may load from the live depot
  under the recorded residual. A
  generation-time behavioral fixture proves the staged form loads the
  package and activates the NCDatasets extension from the staged
  tree. validation_reference_dir()/env redirects are pinned or
  explicitly neutralized so reference resolution stays inside
  $RUNROOT/pkg (NUMERICAL_RADIATION_VALIDATION_REFERENCE_DIR pinned
  to $RUNROOT/pkg/validation/reference).
- RECORDED RESIDUAL (Agent 42 D2; accepted, P1 source-to-linked-
  binary caveat precedent): julia-env Project/Manifest are staged and
  sha-pinned, but the ~/.julia depot's installed package CONTENT
  (NCDatasets and dependencies, compiled caches) remains a live
  system surface -- an accepted, RECORDED residual, not gated by this
  unit.

## Per-arm record (reported-precision discipline, preregistered)
For every arm: fresh load, then record
- the hard_objective value as BOTH a max_digits10 (%.17g) round-trip
  token AND the UInt64 bit pattern (reinterpret of the Float64);
- the COMPLETE ORDERED hard-objective row vector (case, metric,
  value token + UInt64 bit pattern, threshold, normalized token +
  bit pattern) in the exact order hard_objective produces;
- the arm label, state sha, SW sha, and evaluator invocation form.
DUPLICATE GATES (binding): for each state, EXACT bit-pattern equality
of the objective AND of EVERY row between the a/b arms; values are
NEVER averaged; any mismatch is recorded drift + refusal of ordering
assignment.

## Same-job control reproduction gates (binding; refuse-on-miss)
- published-final arms must reproduce 0.18218645425029933 exactly;
- init arms must reproduce 102.67056437657112 exactly;
- plateau arms must reproduce 22.791293464348826 exactly
(exact Float64 bit equality with the committed pinned literals; B0/S1
provenance). Any miss => the job records all values and REFUSES
interpretation (comparison stage refuses; RUNROOT preserved; the
S1/X1/C1 historical readings remain bridges only -- same-job
duplicates decide).

## Residual-label license (binding, before ANY residual language;
## tightened per monitor early review item 2)
- EXACT equality between the loaded splice model and the loaded
  published-final model of BOTH (a) EVERY ordered gas slice of the
  materialized longwave_absorption array AND (b) the COMPLETE
  longwave_h2o_absorption table (elementwise egal on the loaded
  arrays). Rationale (binding; source-cited): the loader materializes
  one 8-gas longwave_absorption array whose :h2o slice is ZEROED on
  this path (NumericalRadiationNCDatasetsExt.jl:151, dynamic_h2o
  returns zeros -- Agent 42 read-only confirmation) -- dynamic H2O is
  carried separately in longwave_h2o_absorption, so gating "all eight
  tables" alone would compare a trivially-equal zeroed slice and
  silently miss the operative H2O payload.
- a COMPLETE INVENTORY enumerating ALL EcCKDTabulatedGasOpticsModel
  fields BY EXACT FIELD NAME -- pressure_grid, temperature_grid,
  h2o_mole_fraction_grid, gas_reference_mole_fractions,
  longwave_absorption, shortwave_absorption,
  longwave_h2o_absorption, shortwave_h2o_absorption,
  shortwave_rayleigh_molar_scattering, longwave_source_scale,
  longwave_source_temperature_grid, longwave_source_table,
  longwave_weights, shortwave_weights -- plus the gas_names/type
  parameter ordering, comparing splice vs published-final, each field
  recorded equal/differs (with counts), reported AS A BLOCK.
- FIXED-SW FIELDS are EXACT-EQUALITY GATES across ALL FOUR states
  (shortwave_absorption, shortwave_h2o_absorption,
  shortwave_rayleigh_molar_scattering, shortwave_weights identical in
  every loaded model), not merely reported counts.
If any license gate fails, the residual label is REFUSED and the
difference itself is the recorded evidence. None of this localizes a
mechanism.

## Preregistered outcome structure (exhaustive; token-derived exact
## decimal, P1 checker machinery)
- D_splice_plateau = J(splice) - J(plateau) and
  D_splice_published = J(splice) - J(published-final), each computed
  by exact decimal arithmetic on the max_digits10 tokens, each with
  the exhaustive sign/equality partition
  (negative / zero-at-token-representation / positive), assigned ONLY
  after every duplicate, control, and schema gate; the full row
  vectors are recorded for the ledger, and LW-only submetrics are
  separately labeled (fixed-SW rows are constant by construction).
- INSTRUMENT-ORDERING STATEMENT (ceiling-bounded): a reversal
  relative to P1's upstream ordering may be REPORTED only if BOTH
  exact orderings hold on their own instruments' committed records
  (P1: J0_reported(splice) > J0_reported(plateau); P2: the exact
  hard-objective ordering); it is a recorded placement fact, never an
  explanation.

## Conclusion ceiling (binding)
P2 outcomes are PRIVATE DIAGNOSTIC PLACEMENT ONLY under this fixed
configuration, instrument, SW state, and pinned inputs: NO recovered
acceptance, NO objective-change authorization, NO optimizer
reachability, NO mechanism localization or ranking, NO raw-vs-final
claim beyond the licensed residual block, NO automatic next-control
decision (monitor sequencing ruling); the external <=1.05 gate and
its acceptance semantics are untouched; all three mechanism classes
remain OPEN and UNRANKED globally; findings are LOCAL to this rebuilt
trajectory and these fixed states.

## Evidence machinery (P1-class, binding)
Quota soft-minus-50GiB guard; p2-lw experiment lock; head-node
refusal; fresh fail-closed RUNROOT; staged immutable
masters/env/code with post-run size+sha reverification of EVERY
staged input incl. the package tree, evaluator chain, reference
files, checkers, julia-env, and shim-class runtime objects consumed;
dual-custody create-once receipts; pinned terminal-log +
emitted-inventory anchoring in the completion ledger; fixtures for
every gate class incl. behavioral negatives on the staged-evaluator
load path; deterministic double generation; restart-safe sbatch
(fresh RUNROOT per job id; no partial-state reuse). The six-file
pattern: this design, the shared P2 checker/evaluator, the checkpoint
generator, the generated sbatch, and the checkpoint JSON/MD.
