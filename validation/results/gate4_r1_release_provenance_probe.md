# Gate-4 R1 release-provenance probe

Status at probe (still true): **r1_sw_mapping_found_lw_ambiguous**

> **Current disposition (updated 2026-08-12, additive annotation)**: the
> at-probe record below (including the original "Next option") is
> preserved verbatim; this artifact was deliberately not regenerated
> because the probe performs live network reads. The status remains true:
> the SW 23adaca mapping stands (confirmed by R2 execution) and the
> LW-1.0 mapping remains unproven (permanent caveat). The recommended R2
> experiment was **EXECUTED** (Greg: "go for R2"; jobs 4094/4095 failed
> configure, 4096 COMPLETED rc=0): SSI PRESENT + elementwise EXACT --
> absence RESOLVED as version skew; the support-array drift proved
> unchanged/version-independent **across the tested v1.2-v1.4
> comparison** (not established for all versions), the pre-registered
> UNCERTAIN branch (verified dependencies: `gate4_r2_finding_ledger` /
> `r2_ssi_resolved_drift_version_independent`;
> `gate4_option_b_decision_record` /
> `option_b_adopted_candidates_promoted`). The optional LW rebuild at
> b42e5c0 was NOT exercised: Option B closed the strict-reproduction path
> for ACCEPTANCE-INIT SELECTION only -- it did NOT prove an LW rebuild
> scientifically unnecessary.

read-only metadata probes; no large downloads, builds, submissions, floor, objective, acceptance, or rule changes.

| Gate | Result |
|---|---|
| changelog_v10_january_2022 | passed |
| changelog_v14_is_ssi_save | passed |
| changelog_v15_owns_hybrid_averaging | passed |
| ecpds_probed_and_recorded | passed |
| ecrad_lw10_predates_v10_bump | passed |
| ecrad_sw14_packaged_week_after_v14_bump | passed |
| no_build_or_submission | passed |
| only_v12_tag_and_master | passed |
| v10_bump_commit_found | passed |
| v14_bump_commit_found | passed |

## Version -> commit map (configure.ac bump history)

- `dea3d4f` 2026-04-30T22:59:24Z: Upgraded to version 1.6
- `6f79065` 2024-02-21T10:13:46Z: Update to v1.6
- `23adaca` 2022-11-14T18:11:59Z: Add solar spectral irradiance to output file
- `f7d53a9` 2022-10-21T08:24:53Z: Version 1.3: added capability to use transmission averaging over 2, 3 & 10 layers, not just 1
- `c5d8044` 2022-04-29T19:37:56Z: Added "fine" and "window" shortwave band structures
- `7457724` 2022-01-13T21:38:45Z: Removed 3rd party lbfgs library
- `74a4893` 2022-01-13T21:01:09Z: Upgrade to v 1.1: Adept L-BFGS minimizer is the default
- `b42e5c0` 2022-01-13T20:58:05Z: Upgrade to version 1.0
- `0367e0a` 2021-07-12T22:17:32Z: Improved Adept detection
- `55224d4` 2021-06-10T15:44:28Z: Upgrade to version 0.8 and added LICENSE, ChangeLog and NOTICE
- `4edbd27` 2021-03-10T13:01:05Z: Upgraded to ecCKD 0.7
- `bfa2cc1` 2020-05-21T23:08:42Z: Upgrade to version 0.6
- `1c4f00f` 2020-04-29T21:34:58Z: Version to 0.5, available to write in output files
- `72cae12` 2020-02-18T15:30:30Z: Renamed fsck -> ecckd
- `cd5948e` 2020-02-18T13:02:33Z: First commit

## Mapping findings

**ecckd_1.4_sw**: MAPPING FOUND (strong)
- corroboration: ecRad packaged the SW 1.4 file at 8936a8c (2022-11-21), one week later, commit message naming the solar-spectrum feature
- source_state: commit 23adaca (2022-11-14) = the v1.4 configure.ac bump; ChangeLog v1.4 (November 2022) lists exactly one change: 'Save solar spectral irradiance (corresponding to gpoint_fraction) in output file'
- buildable: yes: git checkout 23adaca on master history

**ecckd_1.0_lw**: MAPPING AMBIGUOUS
- candidate_source_state: commit b42e5c0 (2022-01-13) = the v1.0 configure.ac bump; ChangeLog 'version 1.0 (January 2022)'
- anomaly: the released LW file was already in ecRad by 2021-09-08 (5be474e 'Changed default ecCKD definition files to 32 term'), PREdating the repo v1.0 bump by ~4 months; the released file's true builder source state is not established by public history (pre-release 0.7/0.8-era code or a private state labeled 1.0 in anticipation)
- buildable: b42e5c0 is buildable, but identity with the released file's builder is UNPROVEN

**SSI absence (strong)**: the SW solar_spectral_irradiance ABSENCE is accounted by v1.4 code: 23adaca adds ckd_model.cpp persistence and is the v1.4 configure.ac bump; ChangeLog v1.4 lists exactly this feature; ecRad packaged the 1.4 SW file a week later naming it

**Support-array drift (cautious)**: the small gpoint_fraction/solar_irradiance/rayleigh drift is NOT explained by any identified source diff: 4a3686f/a4fdf0a are v1.5-era and postdate the ecrad-tracked 1.4 file (no rebuild evidence); the v1.2..23adaca window changes average_optical_depth.cpp (transmission-3/10), ckd_model.cpp (SSI), and create_look_up_table logging but NOT find_g_points.cpp, and average_optical_depth affects gas OD table generation rather than the mismatched support arrays. The 117 proof-run warnings therefore do NOT explain the support-array mismatches. Drift remains UNRESOLVED: version-skew-plausible, or input/provenance/build-config differences

**Remaining blockers**:
- LW: released-file builder source state unestablished (ecRad packaging predates the v1.0 bump)
- SW/LW support-array drift unlocalized: no identified source diff explains it; input data, provenance, or build-config differences remain candidates
- both: build-time config (tolerances, averaging method) of the published builds is not pinned by version labels alone

**Next option**: R2 (needs go): build 23adaca and rerun the SW proof -- a targeted matching-version test that definitively answers the SSI-emission question; whether it also resolves the support-array value drift is UNCERTAIN since the drift is not localized to any identified source diff. LW rebuild at b42e5c0 is possible but its verdict would be conditional on the unproven 1.0 mapping.

ECPDS probes: 404 https://aux.ecmwf.int/ecpds/home/ckdmip/ecckd/; 404 https://aux.ecmwf.int/ecpds/home/ckdmip/ecckd/ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc

Provenance: branch `glw/gate4-recovery`, generated_from_head `a5611ba` (pre-own-commit).
