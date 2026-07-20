#!/bin/bash
#SBATCH --job-name=g4-sw-init-scale-lut
#SBATCH --output=/shared/home/greg/data/ckdmip-logs/g4-sw-init-%j.log
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=60G
#SBATCH --partition=cpu-large

# Gate-4 SW init generation: scale_lut_sw ONLY (self-generated LBL
# reference + scale_lut; no optimize_lut, no objective stages). Generated
# by gate4_sw_init_generation_checkpoint.jl under the Option B decision.
set -euo pipefail
if [ -z "${SLURM_JOB_ID:-}" ]; then
    echo "REFUSED: head-node execution is not permitted; submit via sbatch." >&2
    exit 64
fi

G4WORK=/shared/home/greg/ecckd-derived-flux-work/g4-init-generation
TESTCOPY="$G4WORK/testcopy-v14"

echo "=== SW-init stage 0: environment + input identity checks ==="
test -d "$TESTCOPY" || { echo "REFUSED: testcopy-v14 missing" >&2; exit 68; }
test -x "/shared/home/greg/ecckd-derived-flux-work/ecckd-v1.4-23adaca/src/ecckd/scale_lut" || { echo "REFUSED: v1.4 scale_lut binary missing" >&2; exit 68; }
grep -q '^WORK_DIR=/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work-v14$' "$TESTCOPY/config.h" || { echo "BAD config: WORK_DIR" >&2; exit 68; }
# 4097 fix: the pristine v1.4 config.h hardcodes the upstream author's
# CKDMIP_DIR (/home/parr/...); localize it (idempotent) -- this fixes
# CKDMIP_TOOL/LW/SW in one stroke since all derive from CKDMIP_DIR.
sed -i 's|^CKDMIP_DIR=.*|CKDMIP_DIR=/shared/home/greg/build/ckdmip-1.0|' "$TESTCOPY/config.h"
grep -q '^CKDMIP_DIR=/shared/home/greg/build/ckdmip-1.0$' "$TESTCOPY/config.h" || { echo "BAD config: CKDMIP_DIR" >&2; exit 68; }
test -x "/shared/home/greg/build/ckdmip-1.0/bin/ckdmip_sw" || { echo "REFUSED: ckdmip_sw executable missing" >&2; exit 68; }

echo "=== SW-init stage 0b: HDF5-preinit shim (4098 SIGFPE fix; env-only) ==="
# scale_lut.cpp:49 enables FP traps before any nc_open; HDF5 1.14's type
# detection raises FE_INVALID under traps (4098 ledger). The shim's ENTIRE
# code is one ELF constructor calling H5open() before main(); it cannot
# alter arithmetic. The pinned v1.4 scale_lut binary is verified unchanged
# and invoked via a wrapper so LD_PRELOAD applies to scale_lut ONLY.
sha256sum -c <<'BINHASH' || { echo "REFUSED: v1.4 scale_lut binary hash changed" >&2; exit 69; }
a2d121b2ce5e480c56284cb10aa70dc043ee41185b3377da4af33bafb9f12cc2  /shared/home/greg/ecckd-derived-flux-work/ecckd-v1.4-23adaca/src/ecckd/scale_lut
BINHASH
TOOLS="$G4WORK/tools"
mkdir -p "$TOOLS"
cat > "$TOOLS/h5open_before_traps.c" <<'SHIMSRC'
#include <hdf5.h>
__attribute__((constructor)) static void init_h5_before_traps(void) { H5open(); }
SHIMSRC
gcc -shared -fPIC -I/shared/home/greg/local/ckdmip-stack/include "$TOOLS/h5open_before_traps.c" \
    -o "$TOOLS/h5open_before_traps.so" \
    -L/shared/home/greg/local/ckdmip-stack/lib -Wl,-rpath,/shared/home/greg/local/ckdmip-stack/lib -lhdf5
cat > "$TOOLS/scale_lut_h5preinit" <<WRAP
#!/bin/bash
export LD_PRELOAD="$TOOLS/h5open_before_traps.so"
exec "/shared/home/greg/ecckd-derived-flux-work/ecckd-v1.4-23adaca/src/ecckd/scale_lut" "\$@"
WRAP
chmod +x "$TOOLS/scale_lut_h5preinit"
echo "shim provenance:"
sha256sum "$TOOLS/h5open_before_traps.c" "$TOOLS/h5open_before_traps.so" "$TOOLS/scale_lut_h5preinit"
sed -i "s|^SCALE_LUT=.*|SCALE_LUT=$TOOLS/scale_lut_h5preinit|" "$TESTCOPY/config.h"
grep -q "^SCALE_LUT=$TOOLS/scale_lut_h5preinit$" "$TESTCOPY/config.h" || { echo "BAD config: SCALE_LUT" >&2; exit 68; }
# reusable LBL reference from 4098: verify identity if present (the script
# regenerates it only when absent)
if [ -e "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work-v14/sw_lbl_fluxes/ckdmip_mmm_sw_fluxes-raw_present_1.h5" ]; then
sha256sum -c <<'LBLHASH' || { echo "REFUSED: existing LBL reference hash mismatch vs 4098 ledger" >&2; exit 69; }
ef9df390a2cd546a73cf75ecfcea9c9ae32ad0ea0f5a6437df4e15588d931acd  /shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work-v14/sw_lbl_fluxes/ckdmip_mmm_sw_fluxes-raw_present_1.h5
LBLHASH
fi
sha256sum -c <<'HASHES' || { echo "REFUSED: input hash mismatch vs Option B decision record" >&2; exit 69; }
99333fb5f3c1a3e7ee343a8abd5bbe599f61419c89b8f9b13320a85105532c26  /shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work-v14/sw_raw-ckd-definition/ecckd-1.4_sw_raw-ckd-definition_climate_rgb-tol0.047.nc
13dd686acd0c3ca2201775270f876ce3e3a326576b58b24323b5ce95659b9b57  /shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work/sw_gpoints/ecckd-1.2_sw_gpoints_climate_rgb-tol0.047.h5
HASHES
test -L "$G4WORK/work-v14/sw_gpoints/ecckd-1.4_sw_gpoints_climate_rgb-tol0.047.h5" || { echo "REFUSED: mechanism-1 candidate symlink missing" >&2; exit 68; }
test ! -e "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work-v14/sw_raw-ckd-definition/ecckd-1.4_sw_scaled-ckd-definition_climate_rgb-tol0.047.nc" || { echo "REFUSED: stale scaled output already exists" >&2; exit 70; }
test -s "/shared/home/greg/data/ckdmip/evaluation1/sw_spectra/ckdmip_ssi.h5" || { echo "MISSING TRAINING_SW_SSI" >&2; exit 65; }
for gas in h2o_median o3_median co2_present ch4_present n2o_present n2_constant o2_constant; do
    test -e "$G4WORK/input/mmm/sw_spectra/ckdmip_mmm_sw_spectra_${gas}.h5" || { echo "MISSING overlay input: $gas" >&2; exit 65; }
done

echo "=== SW-init stage 1: scale_lut_sw (self-generates LBL reference) ==="
cd "$TESTCOPY"
APPLICATION=climate BAND_STRUCTURE=rgb TOLERANCE=0.047 bash scale_lut_sw.sh

echo "=== SW-init outputs ==="
sha256sum "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work-v14/sw_lbl_fluxes/ckdmip_mmm_sw_fluxes-raw_present_1.h5" "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work-v14/sw_raw-ckd-definition/ecckd-1.4_sw_scaled-ckd-definition_climate_rgb-tol0.047.nc"
echo "=== SW-init done rc=$? $(date -u +%FT%TZ) ==="
