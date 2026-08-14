# PAPER-ONLY C1 NEXT-CONTROL OUTLINE (draft 1, for monitor review)
# No repo edits, no build, no submission, no code. Scratchpad only.
# Baseline: X1 completion ledger committed/pushed at 4a3be7a
# (checkpoint package at 9725cbb; frozen X1 design d4f8a689).

## 1. What C1 is and is not (binding non-goals)
C1 is a CONFIG-ONLY, one-factor experiment: the identical modern
pinned source/build/config/input/OMP stack as X1 (job 4561), with
exactly ONE factor changed -- bounded_minimization=false. It
quantifies the bounded-minimization flag factor FOR THIS FIXED SETUP
ONLY.
- C1 does NOT isolate a mechanism: switching the flag to false removes
  the bounded solver path AND the log-space bound construction
  (solve_adept.cpp:325-334) SIMULTANEOUSLY -- the two are confounded
  by design in this control, and the ledger must say so.
- C1 does NOT repair or explain the 22.791293464348826 objective; any
  objective movement is recorded as a flag-factor observation with no
  causal upgrade and no "recovery" language.
- All three mechanism classes remain OPEN and UNRANKED globally
  regardless of the C1 outcome.

## 2. Accounting for the X1 result (binding context)
The X1 ledger (bb1f87c5.../b588d18c...) established, LOCAL to that
rebuilt trajectory: the returned x carries the 134 lower + 19 upper
bound exceedances against the CAPTURED supplied bound vectors; no
discrepancy was observed at the returned-vs-caller or
caller-vs-serialization interfaces in that run (mixed chain: one
<=4-ULP tolerance-bounded exp link, then exact-bit links); the ORIGIN
of the exceedances remains UNRESOLVED, with
algorithm-vs-bound-construction semantics explicitly undistinguished.
Consequences for C1:
- C1 CANNOT distinguish those semantics either (Section 1); its value
  is a controlled measurement of what the flag is worth in serialized
  state, census, and objective under the same fixed setup.
- The X1 instrument is NOT carried into C1: the X1 patch is bounds-ON
  only with the unbounded branch gated byte-identical, so an unbounded
  run through the instrumented binary would execute NO capture. C1
  therefore runs the PRISTINE binary in all THREE arms (single build),
  and no sidecar exists. The unbounded path has the SAME possible
  callback-state lag semantics as the bounded path; the returned
  solution is UNOBSERVED in C1 by design. Axis-A/B/C language does not
  apply to C1; serialized-domain census/objective/identity comparisons
  are the instruments.
- Internal validity is measured INSIDE the job (C0a/C0b sandwich,
  Section 6); the historical connection to the 4561 pristine arm is a
  SEPARATE bridge question and neither substitutes for the other.

## 3. Design (triple-arm SAME-BINARY sandwich, one factor)
- One job, one copied pinned source tree (7b210aef artifact; 119-file
  census + exec bits + zero symlinks), ONE build with the corrected
  fresh-autoreconf recipe (path-only LDFLAGS + late LIBS=-ladept;
  config.status rendering asserted byte-exact), ONE saved immutable
  binary optimize_lut_c shared by ALL THREE arms (new build; sha
  recorded, not pre-pinned).
- THREE sequential runs from independently cloned inputs/work/
  testcopies off the frozen read-only test template, SANDWICH order
  C0a -> C1 -> C0b (the repeated bounded control brackets the
  treatment in time, per the S1 precedent: 36-thread run-to-run
  variability must be measured INSIDE the experiment):
    C0a, C0b (controls): defaults -- bounded (bounded_minimization
        unset; compiled default true at optimize_lut.cpp:148-149).
    C1 (treatment): the single injected command-line override
        `bounded_minimization=0` via the same anchored sed machinery
        as the X1 probe's max_iterations injection (model_id line
        anchor; exactly-once gates; leak gates proving the token
        absent from BOTH control testcopies).
- 1-ITERATION UNBOUNDED PROBE before the full arms (X1-probe pattern;
  Agent 42 minor A): a fourth cloned run-set injecting BOTH
  `bounded_minimization=0` AND `max_iterations=1`, gated on the
  "Minimization is unbounded" line and the 1-iteration banner, so a
  literal-semantics mistake in the Real-typed truthiness routing
  (optimize_lut.cpp:148-149) costs ~2 minutes, never a full arm.
  Probe outputs are structural evidence only; no scientific value is
  read from them.
- Run order: probe -> C0a -> C1 -> C0b.
- Identical explicit OMP controls
  (OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK, OMP_DYNAMIC=FALSE, logged per
  arm), identical staged inputs, Netlib preload + H5 shim wrappers
  with ldd proofs -- all verbatim from the X1 machinery.
- X1 hardening carried forward: staged data tree chmod -R a-w after
  hash verification with fail-closed writable-entry scans post-staging
  AND post-run, plus the six-file size+sha re-verification against the
  same pinned manifest before any success claim.

## 4. The single factor (source-cited)
- Key: `bounded_minimization` -- optimize_lut.cpp:148-149
  (`Real is_bounded = true; config.read(is_bounded,
  "bounded_minimization");`), passed to solve_adept (:295); neither
  test/optimize_lut_lw.sh nor test/config.h sets it, so the pinned
  pipeline defaults to bounded (consistent with every prior arm's
  "Minimization is bounded" banner).
- Runtime authority (never inferred from config alone):
    C0a/C0b log gates (each arm): "Minimization is bounded" exactly
        once + the "number bounded below:" census line exactly once;
        zero "unbounded" tokens.
    C1 log gates: "  Minimization is unbounded" exactly once
        (solve_adept.cpp:369) + ZERO "Minimization is bounded" lines +
        ZERO bounded-census lines.
- All three arms: Adept banner (3000/0.02) exactly once, gas banner
  exactly once, "Convergence status: " exactly once with the terminal
  status extracted and required in the allowed set {Converged, Maximum
  iterations reached} (per-arm EXECUTION gate). Control-vs-C1 status
  equality is NOT required -- different solver paths may lawfully
  terminate differently. C0a-vs-C0b terminal-status EXACT EQUALITY is
  part of the INTERNAL repeatability gate (Section 6), not a
  descriptive note.

## 5. Evidence pins and custody (S1/X1 pattern)
- Prerequisites (fail-closed classifiers): X1 completion ledger JSON
  (case gate4_x1_direct_capture_completion_ledger, status
  x1_run_completed_verified, sha bb1f87c5..., commit 4a3be7a...) and
  the committed X1 checkpoint chain (9725cbb pins).
- Stage-0 GATEPINS: generator self-sha, frozen validator 163363a6...
  (reused for the 47-var identity machinery), quota guard,
  validation_results.jl, prerequisite ledger sha.
- Input pins: identical 6 evaluation1 flux files + 3 work inputs
  (staged per arm), test pins, Minimizer.h/libadept/adept_source.h/
  Array.h, Netlib/shim, toolchain fingerprints -- all verbatim values
  from the X1 sbatch.
- Custody: dual create-once receipts (-session40 / -agent42),
  submission + terminal scontrol raw fields; fixed evidence timestamps
  = job EndTime; RUNROOT g4-diag/<jobid>/lw-c1 preserved on success
  and failure; zero canonical writes.

## 6. Pre-registered outcome matrix (no retrofitting; INTERNAL
## validity and the HISTORICAL bridge are SEPARATE questions)
- INTERNAL VALIDITY GATE (primary; BOTH conditions required):
  (a) C0a-vs-C0b logical scientific identity (frozen validator
  semantics: 47 vars, elementwise, typed attrs, value differences
  allowed ONLY in config/history) AND (b) C0a-vs-C0b terminal-status
  EXACT EQUALITY.
    (i) Both hold: baseline repeatability holds INSIDE this job;
        flag-associated interpretation of C1-vs-control differences
        is licensed FOR THIS SETUP (still no mechanism claim).
    (ii) Either fails: baseline repeatability FAILED; flag attribution
        is INCONCLUSIVE; all C1 comparisons/objectives/censuses remain
        DESCRIPTIVE; NO noise rule or threshold is invented post-hoc;
        monitor HOLD decides any follow-up.
- HISTORICAL BRIDGE (separate; connects to X1/history only): C0a and
  C0b each compared to the PINNED 4561 pristine raw2 (49ff3df8...;
  computed from the preserved RUNROOT on 2026-08-14 and re-verified
  fail-closed against g4-diag/4561/lw-x1 at implementation -- Agent 42
  minor B) under the same identity semantics.
    - Bridge success extends the connection to the X1 trajectory; it
      does NOT replace the C0a/C0b repeatability gate.
    - Bridge failure LIMITS the connection to X1/history but does NOT
      invalidate a repeatable same-job C0a/C1/C0b one-factor
      comparison (internal validity stands or falls on (i)/(ii)
      alone).
- C1-vs-control serialized comparison: NONFINITE-AWARE full 47-var
  logical diff against BOTH controls. The STRUCTURAL comparison
  (dims/vars/stored types/typed attrs) is always computable and always
  performed; the VALUE comparison uses isequal elementwise semantics
  (NaN-tolerant, deterministic -- the frozen validator's identity core
  is isequal-based and refuses nothing on nonfinite values; the strict
  all-finite gates live only in the raw2 schema checks, which the
  two-tier policy scopes to the controls) with EXPLICIT per-variable
  nonfinite masks and counts reported alongside (which variables
  differ, elementwise; coefficient-only vs broader), raw2
  hashes/sizes. Fallback ONLY if the validator cannot be cleanly
  extended: value diff marked "not evaluated by preregistered policy"
  with structure verified and nonfinite counts recorded -- never a
  silent route to instrument failure, and no post-hoc rules either
  way. Differences EXPECTED (the flag is upstream of the solve) but
  never presumed.
- Census (pinned S1 kernel by exact extraction, as in the X1 ledger),
  CONDITIONAL by the preregistered two-tier policy: C0a and C0b raw2
  are ALWAYS censused; C1 raw2 is censused ONLY if structurally valid
  and all-finite -- otherwise per-variable nonfinite counts and the
  explicit reason REPLACE the C1 census under the preregistered
  policy, never a refusal. Per gas, below/above separately,
  denominators, worst dlog, index sets, event-sum vs computed-unique
  with explicit overlap. Pre-registered reference points
  (informational, never gates): committed 134/19 for bounded-family
  arms. The C1 census is labeled EXACTLY: a POST-HOC SERIALIZED-OUTPUT
  census of the unbounded arm's SERIALIZED STATE against file-derived
  bounds that were NOT supplied to the unbounded solver; it measures
  NEITHER returned-x feasibility NOR bound enforcement (no sidecar;
  callback-state lag possible; the returned solution is unobserved in
  C1 by design).
- TWO-TIER VALUE POLICY for the C1 arm (Agent 42 challenge 1):
  STRUCTURE failures (schema/dims/vars/types) refuse as instrument
  faults in every arm. NONFINITE VALUES in the C1 arm's raw2 are a
  LAWFUL SCIENTIFIC OUTCOME of removing bounds: they are a RECORDED
  OBSERVATION (per-variable nonfinite counts) that gracefully HALTS
  that arm's census and comparator evaluation with an explicit
  recorded reason -- never a job refusal and never a ledger refusal.
  The X1-inherited all-finite verification applies STRICTLY to C0a and
  C0b only; applying it to C1 would destroy exactly the observation C1
  exists to make.
- Comparator (pinned, official_ecckd mode gated, H2O=0.005, code pins,
  published self-check 0.18218645425029933 bit-exact), CONDITIONAL by
  the preregistered two-tier policy: C0a and C0b are ALWAYS scored
  twice each with PER-ARTIFACT bit-equality required. C1 is scored
  twice (same bit-equality requirement) ONLY if its structurally
  valid raw2 is all-finite; if nonfinite, the ledger records the
  per-variable nonfinite counts and the explicit reason and marks the
  C1 comparator "not evaluated by preregistered policy" -- never a
  job or ledger refusal, and no post-hoc rule. Bounded reference
  point 22.791293464348826 informational; when evaluated, C1's
  objective is recorded exact with NO materiality threshold and NO
  repair language, whatever its value.

## 7. Runtime / quota
- One build (~5 min) + 1-iteration unbounded probe (~2-5 min) + THREE
  full arms: C0a (~35 min) + C1 (unknown; unbounded LBFGS at the same
  3000-iteration cap -- budget 35-min class, could differ either way)
  + C0b (~35 min). Wall estimate ~2 h; comfortably within the
  06:00:00 sbatch limit; cpu-large, 36 cpus, --mem=60G (explicit, per
  cluster discipline).
- Quota guard 5 GiB (RUNROOT footprint ~ three work trees + build,
  same class as 4561's; no sidecars).

## 8. Interpretation ceiling (verbatim candidate, fixture-guarded)
"C1 quantifies the bounded_minimization flag factor for this fixed
setup only. It discriminates NO mechanism: disabling the flag removes
the bounded solver path and the log-space bound construction
simultaneously, so algorithm-vs-bound-construction semantics remain
undistinguished, exactly as after X1. No repair, recovery, or causal
claim is made about the 22.791293464348826 objective or the published
0.18218645425029933 baseline; C1 objective/census values are
descriptive observations local to this rebuilt trajectory. The C1
census is a POST-HOC serialized-output census against file-derived
bounds that were NOT supplied to the unbounded solver; it measures
neither returned-x feasibility nor bound enforcement, and the returned
solution is unobserved in C1 by design. Nonfinite values in the C1
serialized output, if present, are a recorded observation, not an
instrument fault. The X1 finding (returned-x exceedances 134/19 with
zero observed discrepancy at the returned-vs-caller and
caller-vs-serialization interfaces) is carried as context only; C1
neither confirms nor localizes its origin.
All three mechanism classes -- final-state synchronization,
mapping/write, bounded-algorithm behavior -- remain OPEN and UNRANKED
globally; no historical or global claim; identity/bridge gates license
comparisons only for the pairs they test."

## 9. Deliverables when (and only when) authorized
Checkpoint generator + generated sbatch/JSON/MD + fixtures on the X1
machinery (text gates incl. exactly-once bounded/unbounded gates and
the single-factor leak gates; fixtures for the outcome-matrix
classifiers, census kernel reuse, comparator mode discrimination,
identity/bridge semantics, data-tree immutability); then a completion
ledger under the same review pipeline. NOTHING is built or submitted
before explicit monitor GO at each step.
