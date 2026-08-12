# Gate-4 G2c evaluation2 spectra fetch checkpoint

Status: **g2c_checkpoint_ready**

script generation only; nothing submitted by this unit; fetch+verify only; no LBL, optimizer, objective, floor, or recovery computation.

Authorization: Greg: 'go with option A' (2026-07-30) + SSO re-auth and 'keep going' (2026-08-12)

| Gate | Result |
|---|---|
| aws_auth_at_generation | passed |
| disk_guard | passed |
| exact70_gate | passed |
| fetch_only | passed |
| headnode_refusal_guard | passed |
| manifest_integrity | passed |
| quota_aware_preflight | passed |
| quota_guard_fixture_tests | passed |
| sbatch_written_not_submitted | passed |
| species_scope_correct | passed |

Source: s3://aeolus-dev/users/greg@aeolus.earth/ckdmip/evaluation2 (byte-verified ECPDS archive per archive_to_s3.log 2026-05-27; ECPDS live as fallback)

Scope: 7 species x 5 chunks x 2 bands = 70 files, ~330 GB; cfc/rayleigh/ssi excluded (see JSON).

Follow-on: G2d: rayleigh generation (make_rayleigh_evaluation.sh recipe, ckdmip_tool --rayleigh on the 5 eval2 h2o_present SW chunks) + rel-415 LBL runs (LW plain, SW rgb-banded) -> 2 flux files -> ledger -> G3

Provenance: branch `glw/gate4-recovery`, generated_from_head `d82322f` (pre-own-commit).
