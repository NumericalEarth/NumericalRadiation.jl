# Gate-4 stage/objective configuration audit

Status: **stage_config_audit_passed**

configuration audit of the pinned upstream staged-training scripts only; no floor, objective-value, or recovery claim.

| Gate | Result |
|---|---|
| lw_cfc_gaslist | passed |
| lw_ch4_negative_od_override | passed |
| lw_pass_order | passed |
| optimize_lut_cpp_defaults | passed |
| per_pass_options_explicit | passed |
| relative_to_recorded | passed |
| remove_min_max_final_passes | passed |
| sw_base_from_scaled | passed |
| sw_bounded_optimization_dead_key_flagged | passed |
| sw_pass_order | passed |
| sw_rgb_band_mapping | passed |
| sw_rgb_rewrite_recorded | passed |

LW passes: relative-base -> relative-ch4 -> relative-n2o -> relative-cfc

SW passes: relative-base -> relative-ch4 -> relative-n2o

## LW per-pass configuration

### relative-base (lines [125, 152])
- GASLIST: `composite h2o o3 co2`
- INCODE: `raw-ckd-definition`
- OUTCODE: `raw2-ckd-definition`
### relative-ch4 (lines [154, 172])
- GASLIST: `ch4`
- INCODE: `raw2-ckd-definition`
- OUTCODE: `raw3-ckd-definition`
- relative_to: `ckdmip_evaluation1_lw_fluxes_rel-415.h5`
- SPECIFIC_OPTIONS: `convergence_criterion=0.0005 flux_weight=0.5 negative_od_penalty=1.0e1`
### relative-n2o (lines [192, 204])
- GASLIST: `n2o`
- INCODE: `raw3-ckd-definition`
- OUTCODE: `raw4-ckd-definition`
- relative_to: `ckdmip_evaluation1_lw_fluxes_rel-415.h5`
- SPECIFIC_OPTIONS: `convergence_criterion=0.0005 flux_weight=0.5`
### relative-cfc (lines [222, 234])
- GASLIST: `cfc11 cfc12`
- INCODE: `raw4-ckd-definition`
- OUTCODE: `ckd-definition`
- relative_to: `ckdmip_evaluation1_lw_fluxes_rel-415.h5`
- SPECIFIC_OPTIONS: `convergence_criterion=0.0005 flux_weight=0.2 remove_min_max=1`

## SW per-pass configuration

### relative-base (lines [98, 130])
- GASLIST: `composite h2o o3 co2`
- INCODE: `scaled-ckd-definition`
- OUTCODE: `raw2-ckd-definition`
- SPECIFIC_OPTIONS: `convergence_criterion=0.01 spectral_boundary_weight=0.0`
### relative-ch4 (lines [132, 147])
- GASLIST: `ch4`
- INCODE: `raw2-ckd-definition`
- OUTCODE: `raw3-ckd-definition`
- relative_to: `ckdmip_evaluation1_sw_fluxes_rel-415.h5`
- SPECIFIC_OPTIONS: `convergence_criterion=0.0005 max_no_rayleigh_wavenumber=15000`
### relative-n2o (lines [149, 164])
- GASLIST: `n2o`
- INCODE: `raw3-ckd-definition`
- OUTCODE: `ckd-definition`
- relative_to: `ckdmip_evaluation1_sw_fluxes_rel-415.h5`
- SPECIFIC_OPTIONS: `convergence_criterion=0.0005 max_no_rayleigh_wavenumber=15000 remove_min_max=1`

Merge precedence: SPECIFIC_OPTIONS/EXTRA_ARGS > COMMON_OPTIONS (last assignment wins) > optimize_lut.cpp compiled defaults

Provenance: pinned source `/shared/home/greg/.julia/artifacts/7b210aef53e908cfe3c709945f0763c37ca82aaa/ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd`; branch `glw/gate4-recovery`, generated_from_head `33febdc` (pre-own-commit).
