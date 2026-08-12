# Gate-4 A2 reproduction-proof finding

Strict-rule status at finding: **a2_candidates_sensitivity_only_not_promotable**

> **Current disposition (updated 2026-08-12, additive annotation)**: the
> strict-rule verdict below and ALL mismatch evidence/hashes are preserved
> verbatim as generation-time truth under the then-binding
> exact-reproduction rule. That strict finding was later superseded by
> Greg-authorized **Option B** (2026-07-20, "take option B";
> `gate4_option_b_decision_record`, amended rule: structural
> elementwise-exact + support-array max|diff| <= 2.1e-5). Artifact-specific
> outcomes: the **A2 g-point candidates** (LW `c96e6492...`, SW
> `13dd686a...`) and the **LW v1.2 proof raw** (`ce057079...`, promoted to
> the LW acceptance init) were ACCEPTED under Option B; the **SW v1.2
> proof raw** (`3308cb7a...`) REMAINS sensitivity evidence only; the
> **v1.4 job-4096 SW raw** (`99333fb5...`) and **job-4099 scaled SW**
> (`74d8be65...`) became the accepted SW execution artifacts. All hashes
> live-verified 2026-08-12.

The A2 rerun candidates FAIL the exact-reproduction proof and are NOT
promotable to acceptance raw inits under the optimizer-only-delta rule.
They remain valid sensitivity-only artifacts. No floor, objective,
acceptance, or init-generation use unless Greg explicitly changes the rule.

## Proof run (job 4091)

COMPLETED rc=0 at 2026-07-20T08:20:58Z; stage-0 candidate hash checks OK.
LW raw `ce057079…edaf7b43` (2,413,144 B); SW raw `3308cb7a…e8137922`
(2,228,552 B); log-echoed hashes match local sha256sum. Review item: 117
occurrences of the `average_optical_depth.cpp:105` min-OD>average
correction warning (upstream numerical guard, not a failure).

## Comparison outcome (runner run twice, deterministic)

Exact (10 of 15 checks): `g_count` 32/32 both bands; `wavenumber1_band`,
`wavenumber2_band`, `band_number`, and the fine `wavenumber1`/`wavenumber2`
grids, both bands — the reconstructed g-point layout is structurally exact.

Mismatched:

| Band | Field | Mismatched | Max abs diff |
|---|---|---|---|
| lw | gpoint_fraction | 205 / 10432 | 2.68e-6 |
| sw | gpoint_fraction | 60 / 31840 | 1.60e-5 |
| sw | solar_irradiance | 2 / 32 | 2.05e-5 |
| sw | rayleigh_molar_scattering_coeff | 2 / 32 | 9.6e-16 |
| sw | solar_spectral_irradiance | **variable absent from proof raw definition** (structural failure) |

Pre-registered candidate cause: ecCKD version skew — published LW32 was
built with ecckd-1.0, SW32 with ecckd-1.4; the pinned rerun toolchain is
ecckd-1.2. The rule requires elementwise EXACT, so magnitude is irrelevant
to the verdict.

## Options for Greg

- **A**: keep the exact rule → candidates stay sensitivity-only; the
  acceptance init source remains open (A1/A3 upstream artifacts were not
  found in recon).
- **B**: explicitly amend the rule (structural-exact + bounded numeric
  tolerance) via a superseding decision record; the missing
  `solar_spectral_irradiance` would still need an accounted mechanism.
- **C**: investigate version skew — build ecckd 1.0 and 1.4 toolchains and
  rerun the proof to test whether exactness is achievable at matching
  versions.

Provenance: branch `glw/gate4-recovery`, HEAD at finding `ee039e9`.
