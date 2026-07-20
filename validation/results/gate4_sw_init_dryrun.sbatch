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
