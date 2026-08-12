# Gate-4 R2 SW matching-version proof scaffold — HISTORICAL (executed as jobs 4094/4095/4096)

Status: **r2_scaffold_historical_executed**

HISTORICAL post-execution record: the plan below was executed (Greg-authorized) as jobs 4094/4095/4096 and verified against the R2 finding ledger; the pre-registered plan/expectation is preserved verbatim; nothing executed by this unit.

**Executed**: Greg, 2026-07-20: 'go for R2'; job 4094 FAILED at configure (adept.m4 -ladept in LDFLAGS dropped by --as-needed; latent at v1.2 whose weaker conftest was header-only satisfiable); job 4095 FAILED at configure sanity check (LIBS=-ladept applied before any -L path exists); job 4096 COMPLETED rc=0 at 2026-07-20T16:43:13Z with LDFLAGS='-L<adept>/lib -Wl,-rpath,<adept>/lib' LIBS=-ladept. finding ledger status r2_ssi_resolved_drift_version_independent: SSI PRESENT + elementwise EXACT (absence resolved as version skew); residual drift version-independent. v1.4 raw promoted under Option B as the accepted pre-scale SW artifact; scaled SW acceptance init verified against gate4_init_provenance_ledger (acceptance_inits_complete) and the live file: 74d8be65226f081f3d2882520ab374ed102d73cc3dd43bb2fa7c5a5c27602d74.

| Gate | Result |
|---|---|
| attempt_history_verified | passed |
| expected_outcome_pre_registered | passed |
| no_exec_in_this_unit | passed |
| option_b_promotion_of_v14_raw_verified | passed |
| promotion_not_automatic | passed |
| r1_mapping_prerequisite | passed |
| r2_finding_ledger_verified | passed |
| refuses_without_token | passed |
| scaled_sw_init_4099_verified | passed |
| sw_candidate_present_hash_pinned | passed |
| v14_binary_matches_finding_ledger | passed |
| v14_output_matches_finding_ledger | passed |
| v14_tree_matches_executed_commit | passed |

Authorization token at plan time (consumed): `r2_matching_version_go`

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

Provenance: branch `glw/gate4-recovery`, generated_from_head `8d82fcb` (pre-own-commit).
