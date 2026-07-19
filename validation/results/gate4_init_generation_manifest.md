# Gate-4 init-generation manifest

Status: **init_generation_manifest_ready_waiting_for_inputs**

init-generation specification only; nothing is generated; no optimizer, objective, floor, or recovery computation.

| Gate | Result |
|---|---|
| lw_acceptance_init_is_raw | passed |
| no_generation_executed | passed |
| no_optimizer_or_floor_computation | passed |
| required_inputs_enumerated | passed |
| scale_reference_direct_only_mu05 | passed |
| sw_acceptance_init_is_scaled | passed |

## Required inputs (7/9 present)

- [present] idealized LW spectra: `/shared/home/greg/data/ckdmip/idealized/lw_spectra`
- [present] idealized SW spectra: `/shared/home/greg/data/ckdmip/idealized/sw_spectra`
- [present] idealized conc: `/shared/home/greg/data/ckdmip/idealized/conc/ckdmip_idealized_concentrations.nc`
- [present] MMM conc: `/shared/home/greg/data/ckdmip/mmm/conc/ckdmip_mmm_concentrations.nc`
- [MISSING] MMM const conc (composite): `/shared/home/greg/data/ckdmip/mmm/conc/ckdmip_mmm-const_concentrations.nc`
- [present] MMM SSI: `/shared/home/greg/data/ckdmip/mmm/sw_spectra_extras/ckdmip_ssi.h5`
- [present] MMM LW spectra (create_lut averaging): `/shared/home/greg/data/ckdmip/mmm/lw_spectra`
- [present] MMM SW spectra: `/shared/home/greg/data/ckdmip/mmm/sw_spectra`
- [MISSING] g-point files (find_g_points output): `NOT FOUND (must be produced by find_g_points or extracted from the published workflow)`

SW acceptance init resolves to the scaled-ckd-definition output; LW to the raw-ckd-definition output (gated).

Provenance: branch `glw/gate4-recovery`, generated_from_head `9ce5821` (pre-own-commit).
