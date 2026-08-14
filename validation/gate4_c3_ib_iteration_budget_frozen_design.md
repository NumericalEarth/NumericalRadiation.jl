# Gate-4 C3-IB FROZEN DESIGN: modern LW iteration-budget control
# (monitor SEQUENCING RULING; C2/X2 DEFERRED, not disproven --
# information-leverage sequencing, NOT mechanism ranking. Filename is
# C3-IB / iteration-budget to disambiguate from the B0-era "C3" census
# proposal.)

## Unit identity
- DIAGNOSIS unit; PRIVATE outputs only; ZERO canonical writes; RUNROOT
  preserved on success AND failure; submission/commit only on explicit
  monitor GO after the full package review chain.
- Grounding (committed): the live campaign question is the committed
  Gate-1 failure -- g1_objective_ratio_failed, recovered-pair
  package-native hard objective 22.824617997003102 vs <=1.05
  (validation/results/gate4_g1_objective_ratio.{json,md}); the C1
  machinery (commit 6db5a23 family), the P2 evaluator working-set
  pattern (commit 3f872216), and the P1/P2 completion ledgers (commits
  4501220e, b37de8ac). The BINDING dual-endpoint requirement is
  inherited from the MONITOR SEQUENCING RULING itself; the scratch
  next-control matrix is NON-DURABLE CORRESPONDENCE only and grounds
  nothing.

## Question (fixed setup only)
Is the modern bounded LW relative-base plateau budget-limited? Every
relevant committed modern LW relative-base arm terminates at
max_iterations=3000 with nonzero gradient norm (the SW chain's
2000-pass cap is a different setting and is NOT swept into this
statement); this unit measures the association of a 3x budget (9000) with
the upstream endpoint AND the package-native hard objective, under one
factor, and decides nothing beyond those recorded placements.

## Binding requirements (monitor ruling, verbatim-in-substance)
1. SOLE SCIENTIFIC FACTOR: LW relative-base max_iterations -- control
   3000 vs treatment 9000 (C1-proven anchored config-only injection
   for the treatment; the compiled default bounded mode is ON in ALL
   arms; no bounded_minimization override anywhere). HELD: the same
   immutable modern source/binary (single pristine build; no patch),
   the current pinned real-data inputs, wrapper/shim/netlib remedy,
   OMP controls, and downstream pass settings of the committed
   S1/X1/C1 family.
2. SANDWICH ORDER: C0a(3000) -> C3IB(9000) -> C0b(3000), each in an
   INDEPENDENT work dir; plus the cheap 1-iteration injection/identity
   PROBE (structural evidence only) preceding the sandwich, per the C1
   pattern. EXACT ARGV SHAPE (unambiguous, fail-closed exact-count
   gates): the C0a and C0b base-pass scripts carry an EXPLICIT
   max_iterations=3000 token EXACTLY ONCE each; the C3IB base-pass
   script carries max_iterations=9000 EXACTLY ONCE; the probe script
   carries max_iterations=1 EXACTLY ONCE; every downstream script in
   every arm carries ZERO max_iterations tokens. No "default"
   ambiguity exists anywhere.
   DOWNSTREAM LEAK PREVENTION (monitor design-hardening blocker,
   BINDING): the C1-style sed anchor injects at the COMMON optimize_lut
   invocation, so a single modified optimize_lut_lw.sh reused for all
   modes would leak the 9000 override into the downstream
   relative-ch4/relative-n2o/relative-cfc passes and violate the
   sole-factor contract. The contract therefore uses a TWO-SCRIPT
   DISCIPLINE inside every arm work tree: (a) a BASE-ONLY script/
   wrapper copy carrying the arm's max_iterations setting, used
   EXCLUSIVELY for the relative-base pass; (b) a SEPARATELY PINNED
   PRISTINE downstream script copy (byte-verified against the frozen
   template before use) for relative-ch4/relative-n2o/relative-cfc
   (equivalently: restore + re-pin the pristine script before the
   downstream chain). EXACT-COUNT GATES (all fail-closed): the
   treatment's max_iterations=9000 token appears EXACTLY ONCE and only
   in the base-pass script/invocation; the controls carry the
   EXPLICIT 3000 in the base pass ONLY; ZERO max_iterations
   override tokens exist in ANY downstream script/invocation in ANY
   arm; and the downstream scripts' convergence-relevant settings are
   BYTE-IDENTICAL across all three arms (sha-gated against one pinned
   downstream template). The generator carries a NEGATIVE LEAK FIXTURE
   (a downstream script containing a max_iterations override must
   refuse) alongside the exactly-once/leak fixtures of the C1 family.
3. COMPLETE PRIVATE LW PASS CHAIN in each arm: the base raw2 AND the
   final LW definition are BOTH produced and retained per arm inside
   the RUNROOT; no canonical writes at any point.
4. DUAL-ENDPOINT SCORING (BINDING, inherited from the MONITOR
   SEQUENCING RULING; the scratch matrix is non-durable): every
   arm's raw2 AND final LW definition are scored through the pinned
   package hard-objective evaluator (the committed P2 evaluator
   working-set pattern: staged package tree + chain + references +
   julia-env, canonical eight-gas call, h2o_mole_fraction=0.005,
   per-record tokens + UInt64 bit patterns, bit-exact same-artifact
   duplicate discipline) against the SAME pinned CURRENT RECOVERED SW
   from job 4516 (PRIMARY pairing -- directly adjacent to the current
   Gate-1 failure). PRIMARY SW PIN EMBEDDED NOW (monitor early-review
   fix; re-verified fail-closed at contract generation): the job-4516
   recovered final SW definition, committed-ledger path
   /shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work-v14/sw_ckd-definition/ecckd-1.4_sw_ckd-definition_climate_rgb-tol0.047.nc,
   854,508 B, sha256
   8b54392eeddd303299881d6405dcf3de4d738667a3dfe605964a64863e2fbee4.
   SECONDARY SCORING IS BINDING (not optional), with the FULL
   committed pin (monitor pin-completeness fix): filename
   ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc, 851,724 B, sha256
   49abc7bf88b80252e4f9934f8659d108ffee6a101124b2fd080f2eb65d144eb3,
   staged and re-verified fail-closed like every master. TWELVE
   arm-panel package scores are produced -- 3 arms x {raw2, final LW}
   x {primary recovered-SW panel, secondary published-v1.4-SW panel}.
   The <=1.05 placement test applies to the PRIMARY panel ONLY; the
   secondary panel is a separately labeled P2-bridge metric, never
   mixed with primary rows and never placement-tested.
   FIXED CURRENT-G1 ANCHOR (bridge/instrument gate, monitor ruling;
   NOT an experiment arm): the recovered LW from job 4515 at canonical
   path
   /shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work/lw_ckd-definition/ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc,
   872,004 B, sha256
   a3d93d3eb4e69894862fad682563d25a5636e7dbbcc59c197ecaa1cceb6f24b4,
   staged immutable and scored ONCE in-job through the SAME staged
   evaluator paired with the pinned recovered SW. REQUIRED exact
   reproduction: hard-objective token 22.824617997003102 with UInt64
   bits 4627117776501264964 (the committed Gate-1 failure value).
   THREE EXPLICIT PROPERTIES (Agent 42 challenge, binding):
   (i) SEVERABILITY: an anchor miss fails its OWN gate class
   (evidence_g1_anchor) and suppresses ONLY the adjacency
   labels/claims -- the anchor licenses exactly the bridge phrase
   "current-G1-adjacent" and nothing else; arm panels, duplicates,
   controls, and sign partitions remain independently valid as
   within-job placements. Suppression follows the P2
   finalizer-suppression pattern and is FIXTURE-PROVEN in BOTH
   directions (miss suppresses adjacency AND preserves arm evidence;
   hit licenses the phrase).
   (ii) NON-CIRCULARITY, both directions: the anchor is an INSTRUMENT
   REPRODUCTION of a committed value, never a re-evaluation of Gate 1;
   the committed acceptance state (g1_objective_ratio_failed) is
   terminal and untouchable by this unit in BOTH branches -- an anchor
   HIT does not refresh or reconfirm Gate 1, and an anchor MISS does
   not cast doubt on it (the committed value stands on its own
   ledger).
   (iii) NO-ACCEPTANCE-IMPLICATION, pre-empted BY NAME: any arm score
   placing at or below 1.05 on the primary panel is a PRIVATE
   PLACEMENT under this fixed setup, NOT recovered acceptance;
   acceptance remains exclusively the committed external gate on its
   own instruments and provenance chain.
   TOTAL PACKAGE SCORES: EXACTLY THIRTEEN (12 arm-panel + 1 fixed
   anchor).
5. UPSTREAM ENDPOINT RECORD: per-pass terminal status/cost/gradient
   tokens recorded at their ACTUAL PRINTED PRECISION (six-significant-
   figure formatted log tokens; the J0_reported max_digits10 semantics
   do NOT apply to unpatched prints and no patch exists in this unit);
   these upstream tokens are NEVER compared numerically to package
   objectives -- the two endpoints are separately labeled instruments.
6. SAME-JOB CONTROL REPEATABILITY GATES: C0a-vs-C0b exact equality on
   the SCIENTIFIC PAYLOAD (logical raw2/final-definition identity per
   the committed nonfinite-aware egal semantics) AND on the
   hard-objective records (bit-pattern equality per the P2 record
   discipline); terminal-status equality; NO log-byte claim of any
   kind (path/timestamp noise is out of scope).
7. OUTCOME STRUCTURE (preregistered, exhaustive): exact sign/equality
   partitions (negative / zero-at-representation / positive) for every
   treatment-minus-control delta on BOTH endpoints (upstream tokens as
   textual facts; hard-objective deltas by exact decimal on the
   recorded tokens), PLUS the source-grounded <=1.05 placement test
   (does any arm's hard objective place at or under the committed
   Gate-1 bound -- a recorded placement, not an acceptance statement).
   NO post-hoc materiality threshold exists or may be introduced; NO
   inference that longer internal descent implies hard-objective
   improvement; values never averaged; any duplicate/control mismatch
   is recorded drift + refusal of delta assignment.
8. CONCLUSION CEILING (binding): C3-IB outcomes are PRIVATE
   FIXED-SETUP BUDGET ASSOCIATION ONLY under this configuration,
   binary, inputs, and SW pairing: NO recovered acceptance, NO
   recovery claim, NO mechanism localization or ranking, NO
   objective/data change authorization, NO automatic escalation (a
   larger budget or any follow-on is a separate monitor ruling); the
   external <=1.05 gate and its acceptance semantics are untouched by
   this unit (its placement test is descriptive, and BY NAME: a
   sub-1.05 placement is a private placement, never recovered
   acceptance); all three mechanism
   classes remain OPEN and UNRANKED globally; findings LOCAL to this
   rebuilt trajectory.

## Evidence machinery (committed-pattern reuse; contract-time pins)
C1-family sbatch machinery (head-node refusal, quota soft-minus-50GiB,
c3ib-lw experiment lock, fresh fail-closed RUNROOT, staged immutable
masters/data with the stage-0 preflight -> stage-1 copy/verify/freeze
bracket, post-run no-mutation reverification of every staged input)
PLUS the P2 evaluator working-set staging (package tree incl.
Artifacts.toml, evaluator chain, reference files, julia-env, pinned
julia launcher + exact --version gate, JULIA_LOAD_PATH staged form,
NUMERICAL_RADIATION_VALIDATION_REFERENCE_DIR pin); committed P1/P2
checkers reused by byte pin where their gates apply; dual-custody
create-once receipts; pinned terminal-log + emitted-inventory
anchoring in the completion ledger; deterministic double generation;
independent bash -n; fixtures for every gate class including
mapping/decoy/census/language-guard patterns already reviewed in P2.

## Expected wall/quota and terminal stopping rule
- WALL: probe (~2 min) + C0a (~35 min) + C3IB (up to ~105 min at 3x
  budget; earlier if converged) + C0b (~35 min) + full pass-chain
  completion per arm + exactly 13 evaluator scorings (~minutes each; 12 arm-panel + 1 fixed current-G1 anchor) ~= 4 h
  envelope; SBATCH time limit 06:00:00.
- QUOTA: budget <=2 GiB RUNROOT footprint (the analogous preserved C1
  RUNROOT measured 547 MiB, and C3-IB adds full-chain outputs per arm
  plus the evaluator working-set staging); trivial relative to the 50
  GiB headroom guard.
- TERMINAL STOPPING RULE: the unit runs the probe + three sandwich
  arms EXACTLY ONCE each, scores the fixed endpoint set, and stops;
  any semantic/build/schema/proof failure refuses fail-closed with the
  RUNROOT preserved (no retry, no resubmission); the treatment arm
  stops at its own convergence or the 9000 cap, whichever first, and
  its terminal status is a recorded observation; NO budget escalation,
  re-run, or follow-on unit without a new frozen contract and explicit
  monitor GO.
- TERMINAL SUPERSESSION RULE (BINDING FOR THIS UNIT): ANY terminal
  state of the C3-IB job -- COMPLETED, FAILED, CANCELLED, NODE_FAIL,
  OUT_OF_MEMORY, and TIMEOUT alike -- is a HOLD;
  TIMEOUT is NOT a continuity exception, and the old campaign
  protocol's TIMEOUT-continuity default is EXPLICITLY SUPERSEDED for
  this unit; NO automatic retry or resubmission in any terminal
  state; the next action after ANY terminal state requires a new
  explicit Codex-monitor review and GO with hash verification; the
  RUNROOT, once created, is preserved as forensics in every terminal
  state.
