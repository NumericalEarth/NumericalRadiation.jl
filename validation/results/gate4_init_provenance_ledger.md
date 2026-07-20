# Gate-4 acceptance init provenance ledger

Status: **acceptance_inits_complete**

The gate-4 acceptance init set is complete under the Option B decision
record: LW raw init + SW scaled init = the upstream pre-optimization
states the recovery campaign starts from. Provenance record only; no
objective, floor, or recovery computation.

## LW acceptance init

`ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc`, sha256
`ce057079…edaf7b43` — proof job 4091 (pinned v1.2 build) from the
hash-pinned A2 LW candidate; promoted by Option B with the permanent
LW-1.0 builder-source caveat. (Upstream LW inits are unscaled raws.)

## SW acceptance init

`ecckd-1.4_sw_scaled-ckd-definition_climate_rgb-tol0.047.nc`, sha256
`74d8be65226f081f3d2882520ab374ed102d73cc3dd43bb2fa7c5a5c27602d74` —
g_point=32, band=5, SSI present, 40 vars. Chain:

1. A2 SW candidate `13dd686a…59b9b57` (job 4082)
2. SW raw `99333fb5…532c26` (R2 job 4096, v1.4 build, promoted)
3. LBL scaling reference `ef9df390…d931acd` (MMM median col 1, present,
   direct-only, μ0=0.5, albedo 0.15, no Rayleigh; produced in 4098,
   hash-verified on reuse)
4. `scale_lut` (v1.4 binary unchanged, `a2d121b2…f12cc2`) → job 4099
   rc=0, log-echoed hash matches independent local sha256sum.

## SW init job history

- 4097 FAILED (upstream-hardcoded CKDMIP_DIR; no outputs)
- 4098 FAILED (SIGFPE in HDF5 init under FP traps; LBL reference only)
- 4099 SUCCESS (CKDMIP_DIR localized + H5open-preinit shim)

## Execution-environment shim (numerically neutral)

Source `0b73f084…085e730`, .so `28003281…3dd492f`, wrapper
`ca3e4f9e…fa28cb7`; LD_PRELOAD scoped to scale_lut only; rebuilt in-job so
logged hashes describe the preloaded artifact. Note: `optimize_lut` also
enables FP traps — the same shim will be needed at the optimizer stage.

## Next

G2/G3 optimizer recovery runs from these inits (final/target ≤ 1.05,
weight L1 ≤ 0.02, OD log-RMSE ≤ 0.02); the G2/G3 executor scaffold's
preflight prerequisites are now satisfiable.
