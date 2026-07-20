# Gate-4 G2a data ledger: SW-RGB rel training fluxes

Status: **sw_rgb_rel_training_fluxes_installed_and_verified**

Job **4100** (`g4-g2a-sw-rgb-fluxes`) COMPLETED, `G2a done rc=0` at
2026-07-20T22:47:05Z (~5 h 18 m). All stage banners present, no
REFUSED/MISSING/error lines. Data provenance record only; no optimizer,
objective, floor, or recovery computation.

## Generation provenance

Isolated `testcopy-rgb` from the pinned v1.2 source artifact; `ckdmip_sw`
from the same build as job 4078; 9-band RGB grid
250/2500/4000/8000/14300/16650/20000/25000/31750/50000 activated by
full-line sed (13-band grid deactivated; edited lines echoed in the log) —
optimize_lut_sw maps these 9 LBL bands onto the 5 CKD rgb bands via
`0 0 0 0 1 2 3 4 4`, collapsing exactly onto `WN1_SW_RGB`; create_lut_sw
uses `base_wavenumber_boundary=14300`. Scenarios: the pinned default
rel-{180,280,415,560,1120,2240}. Same Julia concat + reuse-skip pipeline
as 4078. Upstream does NOT publish sw_fluxes-rgb (ECPDS 404s recorded).

## Installed files (exact six)

Location: `/shared/home/greg/data/ckdmip/evaluation1/sw_fluxes-rgb/`

| File | Size | sha256 |
|---|---|---|
| rel-180 | 1,817,472 | `19016e05…a658513b` |
| rel-280 | 1,817,472 | `01c5326f…81fa8879` |
| rel-415 | 1,817,472 | `55cf6fff…f1c58cf0` |
| rel-560 | 1,817,472 | `19c80165…1fd185d9` |
| rel-1120 | 1,817,482 | `dddeeb6b…04b1955f` |
| rel-2240 | 1,817,482 | `944c5957…8df22eb6` |

Verification: exact-6 in-job gate before install; workdir↔installed `cmp`
byte-identical (in-job + repeated post-run); sha256 triple agreement
(log echoes = monitor's independent check = local post-run).

## Remaining blockers for the optimizer

1. G2b: rgb variants of present, ch4×5, n2o×4 (later SW passes).
2. evaluation2 rel-415 both bands for `TRAINING_BOTH=yes` (published
   `-32b` models) — needs Greg's data ruling for G3 acceptance.
3. optimize_lut FP-trap shim (same H5open-preinit mechanism as scale_lut).
4. Review of this ledger on origin.
