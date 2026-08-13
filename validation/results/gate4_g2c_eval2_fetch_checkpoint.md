# Gate-4 G2c evaluation2 spectra fetch checkpoint

Status: **g2c_checkpoint_ready**

script generation only; nothing submitted by this unit; fetch+verify only; no LBL, optimizer, objective, floor, or recovery computation.

Authorization: Greg: 'go with option A' (2026-07-30) + SSO re-auth and 'keep going' (2026-08-12) + G2c resume: Greg via campaign coordinator 'of course, keep going; the fetch/job gate is lifted', relay reviewed and accepted as durable authorization by the Codex monitor (2026-08-13); submission itself additionally gated on Codex diff review

| Gate | Result |
|---|---|
| df_gate_removed | passed |
| ecpds_fallback | passed |
| exact70_gate | passed |
| fetch_only | passed |
| headnode_refusal_guard | passed |
| live_quota_headroom | passed |
| manifest_integrity | passed |
| per_object_pipeline | passed |
| probe_size_matches_manifest | passed |
| quota_aware_preflight | passed |
| quota_guard_fixture_tests | passed |
| sbatch_written_not_submitted | passed |
| single_run_lock | passed |
| soft_primary_reserve | passed |
| source_available_at_generation | passed |
| species_scope_correct | passed |

Live quota guard: **pass** -- quota-guard: soft-headroom=575334382592B hard-headroom=682708564992B exact-matched=175407705620B remaining=154581529276B need=208268620476B (remaining+margin; soft is primary ceiling)

Source: s3://aeolus-dev/users/greg@aeolus.earth/ckdmip/evaluation2 (byte-verified ECPDS archive per archive_to_s3.log 2026-05-27; ECPDS live as fallback, HEAD-audited 70/70 exact vs pinned manifest by the Codex monitor 2026-08-13)

Scope: 7 species x 5 chunks x 2 bands = 70 files, ~330 GB; cfc/rayleigh/ssi excluded (see JSON).

Follow-on: G2d: rayleigh generation (make_rayleigh_evaluation.sh recipe, ckdmip_tool --rayleigh on the 5 eval2 h2o_present SW chunks) + rel-415 LBL runs (LW plain, SW rgb-banded) -> 2 flux files -> ledger -> G3

Provenance: branch `glw/gate4-recovery`, generated_from_head `db5ed3a` (pre-own-commit).
