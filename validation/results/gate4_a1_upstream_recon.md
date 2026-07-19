# Gate-4 A1 upstream reconnaissance

Status: **a1_recon_no_exact_upstream_source_found**

reconnaissance metadata only; nothing downloaded beyond HEAD/listing responses; no generation, objective, floor, or recovery computation.

| Gate | Result |
|---|---|
| github_release_listing_ok | passed |
| local_sources_scanned | passed |
| no_generation_or_objective | passed |
| no_large_downloads | passed |
| upstream_probes_recorded | passed |

Local pattern matches: 0 (exact A1: 0)

Upstream probes:
- 404 `https://aux.ecmwf.int/ecpds/home/ckdmip/gpoints/`
- 404 `https://aux.ecmwf.int/ecpds/home/ckdmip/ecckd/`
- 200 `https://aux.ecmwf.int/ecpds/home/ckdmip/results/`
- 404 `https://aux.ecmwf.int/ecpds/home/ckdmip/ckd-definitions/`
- 404 `https://aux.ecmwf.int/ecpds/home/ckdmip/gpoints/ecckd-1.0_lw_gpoints_climate_fsck-32b.h5`
- 404 `https://aux.ecmwf.int/ecpds/home/ckdmip/ecckd/ecckd-1.0_lw_raw-ckd-definition_climate_fsck-32b.nc`
- 404 `https://aux.ecmwf.int/ecpds/home/ckdmip/ecckd/ecckd-1.4_sw_scaled-ckd-definition_climate_rgb-32b.nc`

GitHub release assets matching patterns: 0 of 0 total assets

Next unit if not found: A2 rerun-with-proof manifest (find_g_points from idealized spectra + exact-reproduction gate against published support arrays)

Provenance: branch `glw/gate4-recovery`, generated_from_head `270044e` (pre-own-commit).
