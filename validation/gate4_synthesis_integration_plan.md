# Gate-4 synthesis + integration plan

STATUS: DUAL-REVIEWED / APPROVED PLAN (Codex monitor + Agent42).
Synthesis-only; this plan authorizes NO experiment, NO branch
integration, NO commit beyond the separate commit GO, and NO PR
write. The PR comment posting requires its own separate Codex-monitor
hash/text GO, a PASS from the Section-4 guard on the final text, and
the pre-post live PR gate.

## 1. Established Gate-4 results (exact pins; recorded branches only)

All ledgers live on `glw/gate4-recovery` at the evidence-baseline
commit (one line):
8a6768803cd96d8100e83df474c67054ab5a0b28
(observed upstream-equal at drafting; repository state is not a plan
fact). Evidence artifacts (receipts, logs, RUNROOTs) are
sha-pinned and preserved with reviewer-read-only access; no
filesystem immutability seal is applied or claimed anywhere. Every
SHA/status pair below was mechanically re-verified from the on-disk
files at draft time.

| Unit | Ledger (validation/results/) | Status | sha256 | Licensed finding (ceiling-scoped) |
|---|---|---|---|---|
| G3 | gate4_g3_run_ledger.json | reviewed-complete | `6fd7791834fe1ceb184afd4623c0f95ab311685bb849cfad0837b3c6ffd4aa4e` | the G3 generation-chain run completed and its outputs/status were reviewed as recorded; NO acceptance of any output is implied by this status |
| G1 | gate4_g1_objective_ratio.json | g1_objective_ratio_failed | `5e65cbb184037195b0c60c8462547c4c695b2a63157c62e007c18240933bc4a7` | committed terminal state: recovered pair scores 22.824617997003102 against the external <=1.05 bound; FAILED |
| C1 | gate4_c1_bounds_flag_completion_ledger.json | c1_run_completed_verified | `3c584417d4eba3459f58bbd182b395f7f8ed6c2cddb48e4fef54c057799d116f` | fixed-setup branch: controls 22.791293464348826, C1 22.467263267279066, delta -0.3240301970697601; flag-associated only for this fixed setup; discriminates no mechanism |
| B0 | gate4_b0_era_stack_completion_ledger.json | b0_run_completed_verified | `d109c0b6e5aa157716247cb05bdfdf806c96e7fc3367e3d5628c55baeda66012` | bundled target-era stack viable; era raw2 22.788012978663616 still fails <=1.05 and offers no material recovery versus v1.2 raw2; source/backend/bounds confounded |
| S1 | gate4_s1_state_sync_completion_ledger.json | s1_run_completed_verified | `de5b349e07b1f085e01f8a8fe6902ea50ac9ecce0821844ae99d8b3f9f40a586` | all 47 scientific variables elementwise identical across A0a/A0b/S1/historical4515; objective 22.791293464348826; no observed S1 scientific effect in this rebuilt paired trajectory; all mechanism classes open/unranked |
| X1 | gate4_x1_direct_capture_completion_ledger.json | x1_run_completed_verified | `bb1f87c597e673c8a5b5181d325d46eff7b4619c106e28e7ecf121db32c34170` | returned_x_log outside captured bounds at 134 lower + 19 upper; the returned-log to mapped-physical link is tolerance-bounded; the subsequent mapping/caller/serialization links are exact; all link findings are local to this run; reconstruction changed zero coefficients and objective delta exactly 0.0; origin/relationship unresolved |
| P1 | gate4_p1_completion_ledger.json | p1_run_completed_verified | `9605cf64deb5cb14f2f3403d73c976b00ddfa2c7fc50adba9cb24e1dd51f2403` | published coefficient-block splice internal cost J0 16.89168448685135 > plateau 12.334952613051257 (POSITIVE branch; same-instrument placement only) |
| P2 | gate4_p2_completion_ledger.json | p2_run_completed_verified | `41cc574b28b1c55a6f2235d2dc9914e42c4806bb4ff5aac23b98e1379fdc2b2d` | four-state package-native placement: splice 0.18218653435647347; D_splice_plateau NEGATIVE (-22.60910692999235253); D_splice_published POSITIVE (+0.00000008010617414); ordering reversal is a recorded placement fact under two fixed instruments/setups, never an explanation or mechanism statement |
| C3-IB 4578 | gate4_c3_ib_4578_failure_ledger.json | c3ib_4578_failed_staging_manifest_gap | `472088a799ab4bc53b54dedd405509835dbeef923d8bb39a84f89268d272bf84` | harness failure (staging manifest gap); zero scientific inference |
| C3-IB 4580 | gate4_c3_ib_4580_failure_ledger.json | c3ib_4580_failed_downstream_banner_gate_false_refusal | `c87b07477839c4e8d2f9093ae1c099efe152a2358777d0a24129a46de9c6ebf9` | instrument-gate false refusal; science completed through the ch4 pass; zero scientific inference |
| C3-IB 4584 | gate4_c3_ib_4584_completion_ledger.json | c3ib_4584_run_completed_verified | `efda2db9a2d764b8435caeacf1523f621cd9190557d2524b0ef3b8905ea5e392` | FULL LICENSED CONSTANT (verbatim): "under this ONE fixed setup, the higher-cap (9000) base arm reported Converged at iteration 4211, and its pinned package objectives were +0.012812853359393 / +0.01281285335942 (raw2, primary/secondary evaluator) and +0.013840350139788 / +0.013840350140555 (final) relative to the two token-identical 3000-budget controls; raising this cap did not improve these measured pinned objectives. Nothing further. Converged is a REPORTED STATUS under one criterion in one fixed setup, never proof of an optimum" |

Supporting commit pins on `glw/gate4-recovery` (full 40-char):
P1 package 55c952f971cdf0833af56fe45d3c5daeb452da2d; P1 ledger
4501220e98fe37f3c877966849b632c83bf1e4a7; P2 package
3f872216a0001d093d5de06f5ad27141958f74a1; P2 ledger
b37de8acc1493aebad77330351609103bdae72a7; C3-IB package
88a8fbbb8a4a36dd55722228dbfaf55fde352827; staging recovery
01a6fa78d001c4f4e59cc02e0e9a245997361d8d; banner-gate fix
05f635b3ef025116d322a28f40ac22c51e5747f8; completion ledger
8a6768803cd96d8100e83df474c67054ab5a0b28. C3-IB authorities: design
e5af535f2d1c9efb478bb1b856f632fe05a5dfd01dec634cfecc41a67e44bb63
(terminal supersession rule durable); checker
06ce129768bafaa8dcf18e6cff063e030dafeeeca428447342c2a6033e5a1b82;
generator
46e55471bb3ba3ad0392c33c3d690ef0f4feb9a9e824cc4eae646c5753b60503;
sbatch
b564699530af5fa4569a4e29631772df6a49c717cda381463e1ebaa9ba0b24d3.
Deferred, unordered, unauthorized: C2, X2.

## 2. Conclusion ceilings (all preserved verbatim-in-substance)

- Every quantitative statement above is a RECORDED BRANCH on pinned
  tokens: same-instrument placements, exact-partition deltas, no
  averaging, printed-precision tokens only.
- NO recovered acceptance anywhere; the external <=1.05 Gate-1 state
  remains the committed terminal FAILED record; the 4584 anchor HIT
  licenses the current-G1-adjacent label only and does NOT refresh or
  reconfirm Gate-1.
- NO claim of a global or genuine optimum; Converged is a reported
  status under one criterion in one fixed setup.
- NO mechanism localization, candidate-space reduction, or candidate
  ranking. ALL mechanism classes remain OPEN and UNRANKED.
- NO optimizer- or backend-behavior characterization; NO
  other-budget or broader-configuration extrapolation.

## 3. What remains unresolved (stated without narrowing)

The G1 discrepancy (recovered pair at 22.824617997003102 vs the
<=1.05 bound) is UNEXPLAINED. The completed units record placements
and deltas under fixed setups; none of them localizes a cause.
Mechanism classes that remain open include, WITHOUT ranking, implied
ordering, or exhaustiveness: objective construction, training data
and its preprocessing, code/version provenance, training context and
configuration, evaluator construction, and any class not yet
enumerated. The enumeration is illustrative only; listing order
carries no information.

## 4. PR-facing status mechanism: exactly ONE PR comment

PR #8 state, OBSERVED 2026-08-14 (monitor-read; a snapshot, not a
durable invariant): open, non-draft, mergeable CLEAN, green checks;
head `glw/ecckd-radiation-platform` =
4c666606246e066d88b6831198371aa92cf70a7d; recovery =
8a6768803cd96d8100e83df474c67054ab5a0b28; merge-base
564f4d1b7d2ced3325434fda1afcb1f79a427c29; diverged 4 vs 143 commits.
The package branch's split intentionally deletes `validation/`; a
direct merge would reintroduce ~116k lines / 431 files.

Mechanism: ONE PR #8 comment, posted under monitor/Greg custody after
this plan's approval AND a separate Codex-monitor hash/text GO. The
PR body is currently accurate and is NOT edited. Diagnostics remain
on `glw/gate4-recovery` for this integration action; any change to
that placement requires a separately frozen and reviewed contract.

PRE-POST LIVE PR GATE: immediately before any GitHub write, reverify
that PR #8 remains open and non-draft at the expected head
4c666606246e066d88b6831198371aa92cf70a7d, and re-evaluate its
checks/merge state. ANY mismatch (head moved, state changed, checks
degraded) is a HOLD for Codex-monitor review; posting is never
automatic on a mismatch.

### Exact proposed comment text (verbatim; single placeholder)

> **Gate-4 recovery diagnostics: status pointer**
>
> The Gate-4 recovery diagnostics are documented through the C3-IB
> iteration-budget control and live on `glw/gate4-recovery` at
> 8a6768803cd96d8100e83df474c67054ab5a0b28. This comment is a status
> pointer only: no code integration is proposed or implied, and the
> diagnostics tree intentionally stays off this PR's branch for this
> integration action.
>
> Licensed C3-IB result (verbatim ledger constant): "under this ONE
> fixed setup, the higher-cap (9000) base arm reported Converged at
> iteration 4211, and its pinned package objectives were
> +0.012812853359393 / +0.01281285335942 (raw2, primary/secondary
> evaluator) and +0.013840350139788 / +0.013840350140555 (final)
> relative to the two token-identical 3000-budget controls; raising
> this cap did not improve these measured pinned objectives. Nothing
> further. Converged is a REPORTED STATUS under one criterion in one
> fixed setup, never proof of an optimum."
>
> Gate-1 status: the committed terminal Gate-1 state (FAILED at
> 22.824617997003102 against the <=1.05 bound) is unchanged and
> unexplained; all mechanism classes remain open and unranked.
>
> Linked records (commit-pinned, all eleven ledgers plus the plan):
> G3 <https://github.com/NumericalEarth/NumericalRadiation.jl/blob/8a6768803cd96d8100e83df474c67054ab5a0b28/validation/results/gate4_g3_run_ledger.json>,
> G1 <https://github.com/NumericalEarth/NumericalRadiation.jl/blob/8a6768803cd96d8100e83df474c67054ab5a0b28/validation/results/gate4_g1_objective_ratio.json>,
> C1 <https://github.com/NumericalEarth/NumericalRadiation.jl/blob/8a6768803cd96d8100e83df474c67054ab5a0b28/validation/results/gate4_c1_bounds_flag_completion_ledger.json>,
> B0 <https://github.com/NumericalEarth/NumericalRadiation.jl/blob/8a6768803cd96d8100e83df474c67054ab5a0b28/validation/results/gate4_b0_era_stack_completion_ledger.json>,
> S1 <https://github.com/NumericalEarth/NumericalRadiation.jl/blob/8a6768803cd96d8100e83df474c67054ab5a0b28/validation/results/gate4_s1_state_sync_completion_ledger.json>,
> X1 <https://github.com/NumericalEarth/NumericalRadiation.jl/blob/8a6768803cd96d8100e83df474c67054ab5a0b28/validation/results/gate4_x1_direct_capture_completion_ledger.json>,
> P1 <https://github.com/NumericalEarth/NumericalRadiation.jl/blob/8a6768803cd96d8100e83df474c67054ab5a0b28/validation/results/gate4_p1_completion_ledger.json>,
> P2 <https://github.com/NumericalEarth/NumericalRadiation.jl/blob/8a6768803cd96d8100e83df474c67054ab5a0b28/validation/results/gate4_p2_completion_ledger.json>,
> C3-IB 4578 <https://github.com/NumericalEarth/NumericalRadiation.jl/blob/8a6768803cd96d8100e83df474c67054ab5a0b28/validation/results/gate4_c3_ib_4578_failure_ledger.json>,
> C3-IB 4580 <https://github.com/NumericalEarth/NumericalRadiation.jl/blob/8a6768803cd96d8100e83df474c67054ab5a0b28/validation/results/gate4_c3_ib_4580_failure_ledger.json>,
> C3-IB 4584 <https://github.com/NumericalEarth/NumericalRadiation.jl/blob/8a6768803cd96d8100e83df474c67054ab5a0b28/validation/results/gate4_c3_ib_4584_completion_ledger.json>,
> synthesis plan <https://github.com/NumericalEarth/NumericalRadiation.jl/blob/SYNTHESIS_PLAN_COMMIT_SHA/validation/gate4_synthesis_integration_plan.md>.

### Mechanically checkable pre-post guard (REQUIRED before posting)

With the final comment text in `pr_comment.txt` (placeholder already
substituted), the guard first builds a whitespace-normalized copy so
that neither a required phrase nor a banned phrase can be hidden by
line wrapping, then runs ONE chained command that must exit 0 and
print `PR-COMMENT GUARD: PASS`. Fail-closed: banned-claim scan and
placeholder check (negative predicates), positive exact-content
checks for the recovery commit, the Gate-1 value/bound, the ENTIRE
whitespace-normalized C3-IB licensed constant (every numeric token
and the final ceiling; the shorter tail checks are retained as
defense-in-depth), the branch-separation sentence, per-link presence
for all eleven ledger links, exact ledger-link total (no extras),
and exactly one sha-shaped synthesis-plan URL
(blob/[0-9a-f]{40}/...) so garbage substitution refuses.
The negative scan alone is NOT sufficient; the separate Codex-monitor
posting GO must additionally pin sha256(pr_comment.txt) of the final
substituted text.

    tr '\n' ' ' < pr_comment.txt | tr -s ' ' > pr_comment_flat.txt

    ! grep -Piq '(genuine|global) optimum|budget starvation|optimizer side|exhaust(ed|ion)|faithfully|candidate space|narrow(ed|ing)|\branked\b|\branking\b|recovered acceptance|acceptance-equivalent|recover the target|immutable' pr_comment_flat.txt \
    && ! grep -q 'SYNTHESIS_PLAN_COMMIT_SHA' pr_comment_flat.txt \
    && grep -qF '8a6768803cd96d8100e83df474c67054ab5a0b28' pr_comment_flat.txt \
    && grep -qF 'FAILED at 22.824617997003102 against the <=1.05 bound' pr_comment_flat.txt \
    && grep -qF 'under this ONE fixed setup, the higher-cap (9000) base arm reported Converged at iteration 4211, and its pinned package objectives were +0.012812853359393 / +0.01281285335942 (raw2, primary/secondary evaluator) and +0.013840350139788 / +0.013840350140555 (final) relative to the two token-identical 3000-budget controls; raising this cap did not improve these measured pinned objectives. Nothing further. Converged is a REPORTED STATUS under one criterion in one fixed setup, never proof of an optimum' pr_comment_flat.txt \
    && grep -qF 'raising this cap did not improve these measured pinned objectives. Nothing further.' pr_comment_flat.txt \
    && grep -qF 'never proof of an optimum' pr_comment_flat.txt \
    && grep -qF "intentionally stays off this PR's branch for this integration action" pr_comment_flat.txt \
    && for f in gate4_g3_run_ledger.json gate4_g1_objective_ratio.json gate4_c1_bounds_flag_completion_ledger.json gate4_b0_era_stack_completion_ledger.json gate4_s1_state_sync_completion_ledger.json gate4_x1_direct_capture_completion_ledger.json gate4_p1_completion_ledger.json gate4_p2_completion_ledger.json gate4_c3_ib_4578_failure_ledger.json gate4_c3_ib_4580_failure_ledger.json gate4_c3_ib_4584_completion_ledger.json; do grep -qF "blob/8a6768803cd96d8100e83df474c67054ab5a0b28/validation/results/$f" pr_comment_flat.txt || exit 1; done \
    && [ "$(grep -oF 'blob/8a6768803cd96d8100e83df474c67054ab5a0b28/validation/results/' pr_comment_flat.txt | wc -l)" = 11 ] \
    && [ "$(grep -oP 'blob/[0-9a-f]{40}/validation/gate4_synthesis_integration_plan\.md' pr_comment_flat.txt | wc -l)" = 1 ] \
    && echo 'PR-COMMENT GUARD: PASS'

## 5. Preregistered selection criteria for any NEXT control
(criteria only; NOTHING is authorized or scheduled)

Any future objective/provenance control must, before any GO:
1. Target exactly ONE open mechanism class per unit, chosen by the
   monitor; plan order carries no ranking information.
2. Have a frozen design (dual-reviewed, sha-pinned) with
   preregistered decision branches and NO post-hoc thresholds.
3. Derive every manifest, gate constant, and expected value
   mechanically from sha-pinned authorities (the 4578 lesson: no
   hand-listed manifests; the 4580 lesson: no hand-assumed gate
   constants; every gate exercised by a fixture before reliance).
4. Carry the durable terminal contract (ANY terminal state including
   TIMEOUT is HOLD; no automatic resubmission; fresh RUNROOT; no
   reuse of prior partial outputs).
5. Declare conclusion ceilings at freeze time at least as strict as
   Section 2, including the retracted-claim scan.
6. Run under the standard custody chain: dual review, monitor
   commit/submission GOs, sole-receipt-writer discipline, completion
   or failure ledger with classifier + exact-field semantics +
   stage-0 pin in any successor unit.
7. Fit the standing budget envelope (bounded wall/quota) and place
   results as same-instrument records only.

## 6. Refusal gates (binding on this plan and any successor text)

- REFUSE any statement of optimum (global, genuine, local-as-proof),
  optimizer/backend exhaustion, causal ranking, candidate-space
  narrowing, or recovered acceptance, anywhere outside licensed
  negations.
- REFUSE importing this recovery diagnostics tree into the package
  branch, and REFUSE executing any part of this plan, absent a new
  explicit contract; the currently contemplated direct
  merge/cherry-pick/rebase between these two branches remains HOLD.
  The package branch may otherwise evolve legitimately; this gate
  does not constrain unrelated work on it.
- REFUSE any experiment, submission, or PR write on the basis of
  this plan alone; each requires its own explicit Codex-monitor GO
  with hash verification (the PR comment additionally requires the
  Section-4 mechanical guard to pass on the final text).
- REFUSE any edit to committed ledgers; corrections require new
  superseding ledgers under the established custody pattern.

DUAL-REVIEWED plan end.
