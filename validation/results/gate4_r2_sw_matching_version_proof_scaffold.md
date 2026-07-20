# Gate-4 R2 SW matching-version proof scaffold

Status: **r2_scaffold_ready_awaiting_authorization**

plan artifact only; no checkout, build, run, or submission; no floor, objective, acceptance, or init-generation promotion; execution requires the explicit authorization token.

| Gate | Result |
|---|---|
| expected_outcome_pre_registered | passed |
| no_exec_in_this_unit | passed |
| promotion_not_automatic | passed |
| r1_mapping_prerequisite | passed |
| refuses_without_token | passed |
| sw_candidate_present_hash_pinned | passed |
| v14_tree_not_yet_created | passed |

Authorization token required: `r2_matching_version_go`

## Plan

- **Objective**: SW-only matching-version proof: does a v1.4 (23adaca) build emit solar_spectral_irradiance and reproduce the published SW32 support arrays exactly?
- **Checkout**: `23adaca3344f4b53f109f3bd9533a5ed62998ec0` into `/shared/home/greg/ecckd-derived-flux-work/ecckd-v1.4-23adaca` with post-checkout verifications (configure.ac 1.4, ChangeLog v1.4 SSI entry, ckd_model.cpp persistence)
- **Build**: toolchain parity with the pinned v1.2 build (`--with-adept`/`--with-netcdf` flags from its config.log); record dep versions + binary sha256
- **Proof run**: reuse the hash-pinned 4082 SW candidate (find_g_points.cpp unchanged in v1.2..23adaca), isolated TESTCOPY with the five sed-patched vars, create_lut_sw.sh ONLY, new quarantined work-v14 subtree
- **Comparisons**: the 8 SW checks incl. the headline solar_spectral_irradiance PRESENT+EXACT

## Verdict rules

- **all_sw_fields_exact**: SW candidate promotable PENDING Greg's rule decision AND the open LW-1.0 mapping ambiguity; promotion is NOT automatic
- **drift_persists**: EXPECTED possibility: drift attributed to non-source factors (input data provenance, build config); remains sensitivity-only; feeds Greg's A/B decision
- **drift_worsens**: investigate before any further use
- **ssi_emitted_and_exact**: SSI-absence finding RESOLVED as version skew (strong confirmation of R1)
- **ssi_still_absent**: R1 mapping hypothesis WRONG for the build path used; escalate as new finding
- **ssi_emitted_but_inexact**: absence resolved; SSI values join the unresolved-drift set

**Expected outcome (pre-registered)**: SSI emission expected to resolve; support-array drift may remain unresolved (per R1's cautious statement -- not localized to any identified source diff)

Guardrails: this scaffold executes NOTHING (gated below); executor requires authorize=:r2_matching_version_go; quarantined v1.4 tree + separate work-v14 subtree; pinned v1.2 workcopy, its binaries, and the 4091 proof outputs are never modified; no floor/objective/acceptance/init-generation promotion regardless of outcome; promotion remains Greg's rule decision.

Provenance: branch `glw/gate4-recovery`, generated_from_head `5e8f96f` (pre-own-commit).
