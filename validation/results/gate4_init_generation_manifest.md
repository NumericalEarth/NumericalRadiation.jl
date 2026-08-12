# Gate-4 init-generation manifest — HISTORICAL/SUPERSEDED

Status: **init_generation_manifest_ready_historical_superseded**

**Superseded by**: executed init generation: job 4082 (find_g_points only -- g-point candidates; A2 ledger records NO create_lut), job 4091 (create_lut proof run producing the accepted LW raw init), job 4096 (v1.4 SW raw rebuild), job 4099 (scale_lut under the H5open-preinit shim); outputs accepted under the Option-B rule (gate4_option_b_decision_record) and sha-pinned by gate4_g3_scoped_input_preflight.jl

retained as read-only pre-execution specification evidence; execution deviations not in this spec (CKDMIP_DIR sed, v1.4 rebuild, H5open shim) are recorded in the execution ledgers; 'ready' statuses assert spec coherence + input presence, never generation readiness

HISTORICAL/SUPERSEDED init-generation specification; nothing is generated; no optimizer, objective, floor, or recovery computation.

| Gate | Result |
|---|---|
| lw_acceptance_init_is_raw | passed |
| no_generation_executed | passed |
| no_optimizer_or_floor_computation | passed |
| required_inputs_enumerated | passed |
| scale_reference_direct_only_mu05 | passed |
| sw_acceptance_init_is_scaled | passed |

## Required inputs (9/9 present)

- [present] idealized LW spectra: `/shared/home/greg/data/ckdmip/idealized/lw_spectra`
- [present] idealized SW spectra: `/shared/home/greg/data/ckdmip/idealized/sw_spectra`
- [present] idealized conc: `/shared/home/greg/data/ckdmip/idealized/conc/ckdmip_idealized_concentrations.nc`
- [present] MMM conc: `/shared/home/greg/data/ckdmip/mmm/conc/ckdmip_mmm_concentrations.nc`
- [present] MMM const conc (composite): `/shared/home/greg/data/ckdmip/mmm/conc/ckdmip_mmm-const_concentrations.nc`
- [present] MMM SSI: `/shared/home/greg/data/ckdmip/mmm/sw_spectra_extras/ckdmip_ssi.h5`
- [present] MMM LW spectra (create_lut averaging): `/shared/home/greg/data/ckdmip/mmm/lw_spectra`
- [present] MMM SW spectra: `/shared/home/greg/data/ckdmip/mmm/sw_spectra`
- [present] g-point files (find_g_points output): `/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work-v14/sw_gpoints/ecckd-1.4_sw_gpoints_climate_rgb-tol0.047.h5; /shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5; /shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work/sw_gpoints/ecckd-1.2_sw_gpoints_climate_rgb-tol0.047.h5`

SW acceptance init resolves to the scaled-ckd-definition output; LW to the raw-ckd-definition output (gated).

Provenance: branch `glw/gate4-recovery`, generated_from_head `305a54c` (pre-own-commit).
