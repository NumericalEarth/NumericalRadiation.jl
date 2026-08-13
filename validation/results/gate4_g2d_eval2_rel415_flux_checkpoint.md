# Gate-4 G2d evaluation2 rel-415 flux checkpoint

Status: **g2d_checkpoint_ready**

script generation only; nothing submitted by this unit; rayleigh + LBL evaluation only; no optimizer, objective, floor, or recovery computation.

Prerequisite: committed Unit L completion ledger, guarded loader verdict: **green**

| Gate | Result |
|---|---|
| atomic_publication | passed |
| binary_pins_live | passed |
| df_gate_removed | passed |
| exact_g3_targets | passed |
| fixtures | passed |
| g2c_completion_ledger_green | passed |
| headnode_refusal_guard | passed |
| in_job_70_row_verification | passed |
| in_job_pins | passed |
| lbl_and_rayleigh_only | passed |
| ledger_loader_single_call_site | passed |
| manifest_integrity | passed |
| manifest_sha_pinned_live | passed |
| negative_conc_dependency | passed |
| no_broad_deletion | passed |
| postsed_pins_computed | passed |
| pristine_script_pins_live | passed |
| repo_dependency_pins_live | passed |
| retry_safe_reuse | passed |
| sbatch_written_not_submitted | passed |
| schema_validation_no_size_floor | passed |
| single_run_lock | passed |
| soft_quota_rechecks | passed |
| ssi_pins_live | passed |

Generated sbatch sha256: `06c1a97d49e289cb29a462bb1f1fb750d650c170f6aab8d5ab333568f7e2329d`

Path contract: install to `/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5`, `/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5`, `/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work-v14/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5` (two-phase, atomic, schema-gated; see JSON).

Wall/quota estimates: see JSON `estimates` (evidence-based derivations recorded).
