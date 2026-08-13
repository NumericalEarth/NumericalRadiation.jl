# Gate-4 post-cleanup input census

Status: **post_cleanup_census_recorded**

read-only observed-at census; neutral facts only -- no election, no ruling/intake change, no authorization or attribution claim, no content-integrity conclusion, no deletion/creation outside its own artifacts, no job/quota/fetch action.

| Gate | Verdict |
|---|---|
| fixtures | passed |
| no_observation_errors | passed |
| no_recorded_present_now_absent | passed |
| pinned_sources_verified | passed |

## Preflight inventory re-stat (46 rows)

Counts: {"observation_error": 0, "recorded_absent_now_absent": 3, "recorded_absent_now_present": 0, "recorded_present_now_absent": 0, "recorded_present_now_present": 43}

- [recorded_absent_now_absent] eval2 LW rel-415 flux: `/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5`
- [recorded_absent_now_absent] eval2 SW rgb rel-415 flux (work-v14): `/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work-v14/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5`
- [recorded_absent_now_absent] eval2 SW rgb rel-415 flux (work alt): `/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5`

(recorded_present_now_present rows omitted above for brevity; all rows are in the JSON.)

## Registered scope claim vs observation

Register RECORDED wording (a claim recorded at register time, not a statement of current authorization): "authorization-required scoped cleanup fallback: delete /shared/home/greg/data/ckdmip/idealized/{lw_spectra,sw_spectra} ONLY: 66 files / 217,901,253,443 B (~202.9 GiB); PRESERVE idealized/conc and ALL of evaluation1/ (eval1 is NOT in the S3 archive); EXECUTED out-of-band 2026-08-12 (runbook '## Path D' status note; the census recorded a broader triage than this registered scope, incl. eval1 spectra absent, per the coordinator's delivered record of Greg's broader approval); formal intake of this ruling remains OPEN pending Greg's canonical assignment"

- `/shared/home/greg/data/ckdmip/idealized/lw_spectra`: present=false files=0 bytes=0
- `/shared/home/greg/data/ckdmip/idealized/sw_spectra`: present=false files=0 bytes=0
- `/shared/home/greg/data/ckdmip/idealized/conc`: present=true files=1 bytes=74296
- `/shared/home/greg/data/ckdmip/evaluation1` (root): present=true node_type=directory
  - `conc` [directory]: files=34 bytes=8514984
  - `lw_fluxes` [directory]: files=83 bytes=38620885
  - `sw_fluxes` [directory]: files=24 bytes=59736761
  - `sw_fluxes-rgb` [directory]: files=16 bytes=29298567
  - `sw_spectra` [directory]: files=1 bytes=1981779

registered_scope_claim_vs_observation: the register's RECORDED wording names idealized/conc and ALL of evaluation1/ in its PRESERVE clause; the live subdir set above is the observation. Both sides are facts about recorded text and current existence -- neither is a statement of current authorization, and this unit makes no claim about who removed anything or under what approval

Provenance: branch `glw/gate4-recovery`, generated_from_head `9216204` (pre-own-commit).
