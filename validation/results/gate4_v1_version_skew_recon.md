# Gate-4 V1 version-skew reconnaissance

Status at recon (still true): **v1_version_skew_supported_mapping_unproven**

> **Current disposition (updated 2026-08-12, additive annotation)**: the
> at-recon record below (including the original "Next options") is
> preserved verbatim; this artifact was deliberately not regenerated
> because the recon performs live network reads. The status remains true
> (LW-1.0 mapping unproven, permanent per the R1 probe). Follow-ups since:
> **R1 executed** (`r1_sw_mapping_found_lw_ambiguous`); **R2 executed**
> (Greg: "go for R2"; built 23adaca per R1's refinement, not master as
> sketched here; jobs 4094/4095 failed configure, 4096 rc=0 -> SSI PRESENT
> + elementwise EXACT, absence RESOLVED as version skew; residual drift
> VERSION-INDEPENDENT per `gate4_r2_finding_ledger`); **R3 closed** (Greg
> adopted Option B, `gate4_option_b_decision_record`).

read-only reconnaissance; no builds, submissions, floor, objective, acceptance, or rule changes.

| Gate | Result |
|---|---|
| cited_commits_api_verified | passed |
| limit_stated | passed |
| no_build_or_submission | passed |
| pinned_artifact_is_exactly_v12 | passed |
| pinned_ckd_model_lacks_ssi_persistence | passed |
| upstream_exposes_only_v12_tag | passed |

Pinned toolchain: tag v1.2 = `6115f9b8e29a55cb0f48916857bdc77fec41badd` (exactly the artifact commit). Upstream exposes ONLY v1.2 and master (b1482b2) -- no v1.0/v1.4 tags.

## Cited upstream commits (API-verified)

- `23adaca` (2022-11-14T18:11:59Z): Add solar spectral irradiance to output file -- adds ckd_model.cpp read/define/write persistence of solar_spectral_irradiance in CKD definition files; post-v1.2. The v1.2 contrast is NARROW: SSI-input reads exist in v1.2 (find_g_points/create_look_up_table/reorder_spectrum), but ckd_model.cpp has no CKD-definition persistence for the variable -- accounts for the STRUCTURAL absence in the proof SW raw definition [verified: true]
- `4a3686f` (2023-05-03T21:18:48Z): Added hybrid-logarithmic-transmission-3 averaging, better min/max bounds -- changes averaging/bound handling in the optical-depth averaging used at create_lut time; candidate cause for 1e-6..1e-5 gpoint_fraction/solar/rayleigh value drift IF the published 1.4 build postdates it [verified: true]
- `a4fdf0a` (2023-05-18T11:57:09Z): Improved handling of average absorptions outside min-max bounds which can happen with transmission averaging -- directly touches the min/max-bound correction path behind the 117 average_optical_depth.cpp:105 warnings in proof job 4091 [verified: true]

## Hypothesis assessment

- **sw_missing_variable**: ACCOUNTED (strong): published SW32 is ecckd-1.4; commit 23adaca (2022-11-14, post-v1.2) added ckd_model.cpp read/define/write persistence of solar_spectral_irradiance in CKD definition files. The v1.2 contrast is narrow, NOT 'variable unknown': v1.2 reads the variable from SSI inputs (3 ssi_file.read hits in find_g_points/create_look_up_table/reorder_spectrum) but ckd_model.cpp has zero references (0 hits), so v1.2 CKD definitions structurally cannot carry it
- **sw_value_drift**: SUPPORTED (plausible): 4a3686f + a4fdf0a (2023-05) change averaging and min/max-bound handling in the exact code path that produced 117 correction warnings in the proof run; IF the 1.4 build postdates them, drift is expected
- **lw_value_drift**: WEAKLY SUPPORTED: published LW32 is ecckd-1.0, which PREdates v1.2, and no v1.0 tag or 1.0->1.2 diff is visible upstream; attribution for the LW 2.7e-6 drift is plausible but unverifiable from exposed source history
- **limit**: source diffs support version skew but do NOT prove the published ecckd-1.0/1.4 files map to buildable tags; only v1.2 (6115f9b) and master (b1482b2) are exposed; matching-version rebuild requires release provenance first

## Next options

- R1 (release provenance): probe ECPDS/ecRad packaging history or contact upstream for the exact source states behind the ecckd-1.0/1.4 released files
- R2 (bounded experiment, needs go): build master b1482b2 and rerun the SW proof only -- tests whether post-23adaca source emits solar_spectral_irradiance and shrinks the SW value drift; NOT a proof of 1.4 identity
- R3 (Greg rule decision): options A/B from the proof finding ledger remain open and are informed by this recon

Provenance: branch `glw/gate4-recovery`, generated_from_head `95c5e4e` (pre-own-commit).
