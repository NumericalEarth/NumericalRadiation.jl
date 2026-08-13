# Gate-4 G2d EVALUATION2 REL-415 FLUX checkpoint (dry-run generation; NO
# submission). Final Option A data unit: produce the two TRAINING_BOTH=yes
# training flux files from the G2c-fetched evaluation2 spectra.
#
# 2026-08-13 monitor-specified implementation (binding corrections):
#   prerequisite = guarded loader over the COMMITTED Unit L completion
#   ledger (exact case/status/sha), never count-on-disk; in-job exact
#   size + HDF5 open of all 70 manifest rows; SSI pinned by size+sha+h5;
#   flock single-run lock; NO recursive deletion of work-eval2 and no
#   uncontrolled find -delete/rm -rf (exact-allowlisted removals only);
#   soft-primary quota_object_recheck (50 GiB standing reserve) before
#   every allocation and before every publish/install; rayleigh planning
#   allocation 15 GiB PER CHUNK (worst-case uncompressed per-chunk dims
#   10 x 54 x 3,126,494 at up to 8 B + overhead; five chunks imply a
#   75 GiB worst-case total; compression uncredited); full
#   evidence-based HDF5 schema validation (no size-floor proxies) of
#   every rayleigh, quarantine, and installed file; retry-safe reuse
#   ONLY after validation; atomic dot-temp + sync + mv publication and
#   installs with post-mv verification; live binary/script pins and
#   deterministic post-sed sha constants verified in-job.
#
# PATH CONTRACT (monitor-specified, two-phase): GENERATE in the
# quarantined work-eval2 tree, exact-2 output gate there, then INSTALL
# into the EXISTING executor trees (inits/gpoints untouched):
#   $G4WORK/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5
#   $G4WORK/work/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5
#   + $G4WORK/work-v14/sw_lbl_fluxes/<same SW file> (dual-install)
# G3 keeps WORK_DIR=work (LW) / work-v14 (SW): no repointing, no symlinks.
#
# U3 RESOLVED (monitor + history evidence): the pinned rel-415 scripts
# use spectra-embedded reference concentrations and literal VMR scaling
# (--conc 415e-6, --const ...); NO evaluation2 conc files are read. This
# negative dependency is asserted in-job and gated here. BINDIR is set
# to the established v1.2 path but is NON-COMPUTATIONAL for this unit:
# neither LBL script executes it.
#
# NO optimizer, create_lut, scale_lut, or find_g_points executable lines.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON
using SHA: sha256

const ECCKD_SRC = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"
const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"
const CKDMIP_BIN_ROOT = "/shared/home/greg/build/ckdmip-1.0"
const PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
const SPECIES = ["h2o_present", "o3_present", "co2_present", "ch4_present",
                 "n2o_present", "n2_constant", "o2_constant"]
const CHUNKS = ["1-10", "11-20", "21-30", "31-40", "41-50"]
const WORKEVAL2 = "$G4WORK/work-eval2"
const TESTCOPY = "$G4WORK/testcopy-eval2"
const LW_OUT = "$WORKEVAL2/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5"
const SW_OUT = "$WORKEVAL2/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5"
const LW_INSTALL = "$G4WORK/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5"
const SW_INSTALL = "$G4WORK/work/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5"
const SW_INSTALL_V14 = "$G4WORK/work-v14/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5"

# prerequisite: the COMMITTED Unit L completion ledger, pinned exactly
const GD_LEDGER_JSON = validation_results_path("gate4_g2c_fetch_completion_ledger.json")
const GD_LEDGER_CASE = "gate4_g2c_fetch_completion_ledger"
const GD_LEDGER_STATUS = "g2c_fetch_completed_verified"
const GD_LEDGER_SHA = "f979292c6db259eee552a76eca42cf91bba05b442e47dcf235359179e338dbf2"

# input pins (verified live at generation AND in-job)
const GD_SSI = "$CKDMIP_ROOT/evaluation1/sw_spectra/ckdmip_ssi.h5"
const GD_SSI_BYTES = 1981779
const GD_SSI_SHA = "440e1c4f481ad67bb67c352c36095da885475dd50cc9592ad4be68d179722a03"
const GD_BIN_PINS = [
    ("ckdmip_tool", "2334730bd2da322b603b5748c4076bba442928a2a9b05a3f2f53c8ad159c44cd"),
    ("ckdmip_lw", "ae7a2a9a2cd2f522627f4fd6e7a087b2539016eb45d1a4d6793602960d2bcd8a"),
    ("ckdmip_sw", "ab8176c5a41bf40d49ef814ff01c21092c4948f4f0b910077da20104511536db")]
const GD_PRISTINE_LW_SHA = "cbe9c3f3af4ca6872dc038bc7b1c5959baf1890f8f3b075acb02b21c2961f4dd"
const GD_PRISTINE_SW_SHA = "f53d18583c3e48ad16f6685945118b97f8229491e43e158424049b3fbc7f7e51"

const GD_MANIFEST = "$PROJECT_ROOT/validation/gate4_eval2_selected_manifest.tsv"
const GD_MANIFEST_COUNT = 70
const GD_MANIFEST_TOTAL = 329989234896
const GD_MANIFEST_SHA = "d72ecb4149c07a07f73972fc540d812f56d7e492d2f75208228e8541c925fca2"

# live executable repo dependencies the job sources/executes: pinned so
# they cannot drift without changing this unit (the generated sbatch
# carries the pins and refuses in-job before source/use)
const GD_GUARD_PATH = "$PROJECT_ROOT/validation/gate4_quota_guard.sh"
const GD_GUARD_SHA = "786506c29c07f3c7d4584d98a07f9a10b91b773b43763465f52966fb61f83e7d"
const GD_CONCAT_PATH = "$PROJECT_ROOT/validation/concat_ckdmip_flux_chunks.jl"
const GD_CONCAT_SHA = "b8cdf031a35c08236c068e01f8c55c43aba7cfbaa254ff0ebd2d473966f86fa8"
# --project=test is the live concat environment: both its Project AND
# resolved Manifest are pinned so the concat helper's dependency closure
# is provenance-bound, not just the entry-point script
const GD_TESTPROJ_PATH = "$PROJECT_ROOT/test/Project.toml"
const GD_TESTPROJ_SHA = "9136a5f68b97123017182b5afaf30c93148188a0ea8681ac3d17a808f6012ef0"
const GD_TESTMANIFEST_PATH = "$PROJECT_ROOT/test/Manifest.toml"
const GD_TESTMANIFEST_SHA = "cf9f318d43221280a8ca1116fbfea20d66678267f4e9d5dd1bdf519093ceb186"

const GD_RESERVE = 53687091200            # 50 GiB standing SOFT reserve
const GD_RAY_ALLOC = 16106127360          # 15 GiB/chunk planning allocation
const GD_LBL_ALLOC = 1073741824           # 1 GiB/stage (fluxes are MB-class:
                                          # eval1 finals 450,863 / 1,817,472 B)

const GD_RESULTS_JSON = validation_results_path("gate4_g2d_eval2_rel415_flux_checkpoint.json")
const GD_RESULTS_MD = validation_results_path("gate4_g2d_eval2_rel415_flux_checkpoint.md")
const GD_SBATCH = validation_results_path("gate4_g2d_eval2_rel415_flux.sbatch")

# evidence-based flux schema (read from the eval1 rel-415 precedents on
# disk, h5py-inspected 2026-08-13; matches the monitor's binding spec)
const LW_BANDS1 = "[0.0, 350.0, 500.0, 630.0, 700.0, 820.0, 980.0, 1080.0, 1180.0, 1390.0, 1480.0, 1800.0, 2080.0]"
const LW_BANDS2 = "[350.0, 500.0, 630.0, 700.0, 820.0, 980.0, 1080.0, 1180.0, 1390.0, 1480.0, 1800.0, 2080.0, 3260.0]"
const SW_BANDS1 = "[250.0, 2500.0, 4000.0, 8000.0, 14300.0, 16650.0, 20000.0, 25000.0, 31750.0]"
const SW_BANDS2 = "[2500.0, 4000.0, 8000.0, 14300.0, 16650.0, 20000.0, 25000.0, 31750.0, 50000.0]"

# in-job HDF5/schema validator (python3 + h5py, REQUIRED on the node).
# No $ characters: safe inside the sbatch quoted heredoc.
const PY_VALIDATOR = """
import sys, h5py

def die(msg):
    print("SCHEMA-INVALID: " + msg)
    sys.exit(1)

def opencheck(p):
    try:
        return h5py.File(p, "r")
    except Exception:
        die("h5 open failed: " + p)

def shapes(f, req):
    for k, s in req.items():
        if k not in f:
            die("missing dataset " + k)
        if s is not None and tuple(f[k].shape) != s:
            die("shape " + k + ": " + str(tuple(f[k].shape)) + " != " + str(s))

def attr_scenario(f):
    v = f.attrs.get("scenario", b"")
    v = v.decode() if isinstance(v, bytes) else str(v)
    if v != "rel-415":
        die("scenario attr '" + v + "' != rel-415")

def bands(f, n1, n2, v1, v2):
    a1 = [float(x) for x in f[n1][:]]
    a2 = [float(x) for x in f[n2][:]]
    if a1 != v1 or a2 != v2:
        die("band boundaries mismatch in " + n1 + "/" + n2)

mode = sys.argv[1]
p = sys.argv[2]
if mode == "open":
    opencheck(p).close()
    sys.exit(0)
if mode == "lw":
    f = opencheck(p)
    shapes(f, {"band_flux_up_lw": (50, 55, 13), "band_flux_dn_lw": (50, 55, 13),
               "flux_up_lw": (50, 55), "flux_dn_lw": (50, 55),
               "pressure_hl": (50, 55), "temperature_hl": (50, 55)})
    bands(f, "band_wavenumber1_lw", "band_wavenumber2_lw",
          $LW_BANDS1, $LW_BANDS2)
    attr_scenario(f)
    f.close()
    sys.exit(0)
if mode == "sw":
    f = opencheck(p)
    shapes(f, {"band_flux_up_sw": (50, 5, 55, 9),
               "band_flux_dn_sw": (50, 5, 55, 9),
               "band_flux_dn_direct_sw": (50, 5, 55, 9),
               "flux_up_sw": (50, 5, 55), "flux_dn_sw": (50, 5, 55),
               "flux_dn_direct_sw": (50, 5, 55),
               "mu0": (5,), "pressure_hl": (50, 55),
               "temperature_hl": (50, 55)})
    bands(f, "band_wavenumber1_sw", "band_wavenumber2_sw",
          $SW_BANDS1, $SW_BANDS2)
    attr_scenario(f)
    f.close()
    sys.exit(0)
if mode == "ssi":
    f = opencheck(p)
    shapes(f, {"wavenumber": (3126494,),
               "solar_spectral_irradiance": (3126494,),
               "total_solar_irradiance": ()})
    if float(f["total_solar_irradiance"][()]) != 1361.0:
        die("total_solar_irradiance != 1361.0")
    f.close()
    sys.exit(0)
if mode == "raw_lw":
    f = opencheck(p)
    shapes(f, {"band_flux_up_lw": (10, 55, 13), "band_flux_dn_lw": (10, 55, 13),
               "flux_up_lw": (10, 55), "flux_dn_lw": (10, 55),
               "pressure_hl": (10, 55), "temperature_hl": (10, 55)})
    bands(f, "band_wavenumber1_lw", "band_wavenumber2_lw",
          $LW_BANDS1, $LW_BANDS2)
    attr_scenario(f)
    f.close()
    sys.exit(0)
if mode == "raw_sw":
    f = opencheck(p)
    shapes(f, {"band_flux_up_sw": (10, 5, 55, 9),
               "band_flux_dn_sw": (10, 5, 55, 9),
               "band_flux_dn_direct_sw": (10, 5, 55, 9),
               "flux_up_sw": (10, 5, 55), "flux_dn_sw": (10, 5, 55),
               "flux_dn_direct_sw": (10, 5, 55),
               "mu0": (5,), "pressure_hl": (10, 55),
               "temperature_hl": (10, 55)})
    bands(f, "band_wavenumber1_sw", "band_wavenumber2_sw",
          $SW_BANDS1, $SW_BANDS2)
    attr_scenario(f)
    f.close()
    sys.exit(0)
if mode == "rayleigh":
    ray = opencheck(p)
    h2o = opencheck(sys.argv[3])
    # explicit eval2 source contract, asserted (never derived from an
    # arbitrary file; verified on the fetched eval2 h2o chunk 2026-08-13)
    shapes(h2o, {"wavenumber": (3126494,), "pressure_hl": (10, 55),
                 "level": (54,), "half_level": (55,), "column": (10,)})
    shapes(ray, {"wavenumber": (3126494,), "pressure_hl": (10, 55),
                 "level": (54,), "half_level": (55,), "column": (10,),
                 "optical_depth": (10, 54, 3126494),
                 "column_optical_depth": (10, 3126494),
                 "single_scattering_albedo": (),
                 "asymmetry_factor": ()})
    if float(ray["single_scattering_albedo"][()]) != 1.0:
        die("rayleigh single_scattering_albedo != 1")
    if float(ray["asymmetry_factor"][()]) != 0.0:
        die("rayleigh asymmetry_factor != 0")
    if not (ray["wavenumber"][:] == h2o["wavenumber"][:]).all():
        die("rayleigh wavenumber grid differs from h2o grid source")
    if not (ray["pressure_hl"][:] == h2o["pressure_hl"][:]).all():
        die("rayleigh pressure_hl differs from h2o grid source")
    # level/half_level VALUE equality is deliberately NOT required: the
    # pinned ckdmip_tool precedent writes zero coordinate values there
    ray.close()
    h2o.close()
    sys.exit(0)
die("unknown validator mode " + mode)
"""

# the sed pipeline, defined ONCE and used both by the sbatch (in
# TESTCOPY) and by the generation-side replication that computes the
# deterministic post-sed sha constants (all paths literal)
const SED_BLOCK = """
sed 's/@PACKAGE_VERSION@/1.2/g' version.h.in > version.h
sed -i \\
  -e 's|^CKDMIP_DIR=.*|CKDMIP_DIR=$CKDMIP_BIN_ROOT|' \\
  -e 's|^CKDMIP_DATA_DIR=.*|CKDMIP_DATA_DIR=$CKDMIP_ROOT|' \\
  -e 's|^WORK_DIR=.*|WORK_DIR=$WORKEVAL2|' \\
  -e 's|^BINDIR=.*|BINDIR=/shared/home/greg/ecckd-derived-flux-work/ecckd/src/ecckd|' \\
  config.h
# LW retarget: SET + explicit INDIR (INDIR is TRAINING-wired upstream)
sed -i \\
  -e 's|^SET=evaluation1\$|SET=evaluation2|' \\
  -e 's|^INDIR=\$TRAINING_LW_SPECTRA_DIR\$|INDIR=\${CKDMIP_DATA_DIR}/evaluation2/lw_spectra|' \\
  run_lw_lbl_evaluation.sh
sed -i -E "0,/^SCENARIOS=\\"[^\\"]*\\"/s||SCENARIOS=\\"rel-415\\"|" run_lw_lbl_evaluation.sh
# SW retarget: SET + rel-415 + rgb 9-band (14300-variant) edits
sed -i \\
  -e 's|^SET=evaluation1\$|SET=evaluation2|' \\
  -e 's|^BANDCODE=fluxes\$|BANDCODE=fluxes-rgb|' \\
  -e 's|^band_wavenumber1(1:13)|!band_wavenumber1(1:13)|' \\
  -e 's|^band_wavenumber2(1:13)|!band_wavenumber2(1:13)|' \\
  -e 's|^!band_wavenumber1(1:9) = 250, 2500, 4000, 8000, 14300, 16650, 20000, 25000, 31750,|band_wavenumber1(1:9) = 250, 2500, 4000, 8000, 14300, 16650, 20000, 25000, 31750,|' \\
  -e 's|^!band_wavenumber2(1:9) = 2500, 4000, 8000, 14300, 16650, 20000, 25000, 31750, 50000,|band_wavenumber2(1:9) = 2500, 4000, 8000, 14300, 16650, 20000, 25000, 31750, 50000,|' \\
  run_sw_lbl_evaluation.sh
sed -i -E "0,/^SCENARIOS=\\"[^\\"]*\\"/s||SCENARIOS=\\"rel-415\\"|" run_sw_lbl_evaluation.sh
# pipeline parity: no nco module, quieter, Julia concat with VALIDATED
# atomic publication, RAW reuse only after h5 validation
sed -i '/^module load nco\$/s/^/# /' run_lw_lbl_evaluation.sh run_sw_lbl_evaluation.sh
sed -i 's/iverbose = 3/iverbose = 1/g' run_lw_lbl_evaluation.sh run_sw_lbl_evaluation.sh
sed -i -E 's|ncrcat -O \\\$OUTFILES \\\$OUTFILE|julia --project=$PROJECT_ROOT/test $PROJECT_ROOT/validation/concat_ckdmip_flux_chunks.jl \\\$OUTFILES \\\$OUTFILE.g2dtmp \\&\\& g2d_concat_publish \\\$OUTFILE|' run_lw_lbl_evaluation.sh run_sw_lbl_evaluation.sh
sed -i '/OUTFILES="\$OUTFILES \$OUTFILE"/a\\
\\tif [ -s "\$OUTFILE" ] \\&\\& g2d_raw_valid "\$OUTFILE"\\
\\tthen\\
\\t    echo "*** REUSING validated \$OUTFILE ***"\\
\\t    continue\\
\\telse\\
\\t    rm -f -- "\$OUTFILE"\\
\\tfi' run_lw_lbl_evaluation.sh run_sw_lbl_evaluation.sh
"""

const SBATCH_TEXT = """
#!/bin/bash
#SBATCH --job-name=g4-g2d-eval2-rel415
#SBATCH --output=/shared/home/greg/data/ckdmip-logs/g4-g2d-%j.log
#SBATCH --time=08:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=60G
#SBATCH --partition=cpu-large

# Gate-4 G2d: evaluation2 rel-415 LBL fluxes ONLY (rayleigh generation +
# two LBL runs; no optimizer, no create/scale/find stages). Generated by
# gate4_g2d_eval2_rel415_flux_checkpoint.jl. Retry-safe: valid outputs
# are reused after HDF5/schema validation, never on nonempty alone; all
# publication is dot-temp + sync + atomic mv; removals are exact
# allowlisted names under the job lock; work-eval2 is NEVER wiped.
set -euo pipefail
if [ -z "\${SLURM_JOB_ID:-}" ]; then
    echo "REFUSED: head-node execution is not permitted; submit via sbatch." >&2
    exit 64
fi

G4WORK=$G4WORK
TESTCOPY=$TESTCOPY
WORKEVAL2=$WORKEVAL2
E2=$CKDMIP_ROOT/evaluation2
MANIFEST=$GD_MANIFEST
RESERVE=$GD_RESERVE      # 50 GiB standing SOFT-limit reserve
RAY_ALLOC=$GD_RAY_ALLOC  # 15 GiB/chunk rayleigh planning allocation
LBL_ALLOC=$GD_LBL_ALLOC  # 1 GiB/stage (fluxes are MB-class)
VAL="\$G4WORK/.g2d.validator.py"

echo "=== G2d stage 0: preflight ==="
command -v flock >/dev/null || { echo "MISSING flock" >&2; exit 65; }
# single-run lock BEFORE any cleanup/write
exec 9>"\$G4WORK/.g2d.lock"
flock -n 9 || { echo "REFUSED: another G2d run holds the lock" >&2; exit 68; }
python3 -c "import h5py" 2>/dev/null || { echo "REFUSED: python3+h5py required for schema validation" >&2; exit 65; }
cat > "\$VAL" <<'PYEOF'
$(PY_VALIDATOR)
PYEOF
g2d_pin() { # path expected_sha label
    local s; s=\$(sha256sum "\$1" | cut -d' ' -f1)
    [ "\$s" = "\$2" ] || { echo "REFUSED: \$3 sha mismatch (\$s != \$2)" >&2; exit 65; }
}
# binary pins (live)
$(join(["g2d_pin $CKDMIP_BIN_ROOT/bin/$(b) $(h) $(b)" for (b, h) in GD_BIN_PINS], "\n"))
for b in ckdmip_tool ckdmip_lw ckdmip_sw; do
    test -x "$CKDMIP_BIN_ROOT/bin/\$b" || { echo "MISSING/nonexecutable binary \$b" >&2; exit 65; }
done
# SSI pinned: exact path, exact size, exact sha, full schema (wavenumber
# + solar_spectral_irradiance at the eval grid length, TSI == 1361.0)
[ "\$(stat -c %s "$GD_SSI")" = "$GD_SSI_BYTES" ] || { echo "REFUSED: SSI size != $GD_SSI_BYTES" >&2; exit 65; }
g2d_pin "$GD_SSI" "$GD_SSI_SHA" "evaluation1 SSI"
python3 "\$VAL" ssi "$GD_SSI" || { echo "REFUSED: SSI failed schema validation" >&2; exit 65; }
# live repo dependencies: pinned BEFORE source/use (guard is sourced
# next; concat helper + its --project=test environment run inside the
# LBL scripts later)
g2d_pin "$GD_GUARD_PATH" "$GD_GUARD_SHA" "quota guard"
g2d_pin "$GD_CONCAT_PATH" "$GD_CONCAT_SHA" "concat helper"
g2d_pin "$GD_TESTPROJ_PATH" "$GD_TESTPROJ_SHA" "test/Project.toml"
g2d_pin "$GD_TESTMANIFEST_PATH" "$GD_TESTMANIFEST_SHA" "test/Manifest.toml"
# quota: soft-primary baseline health, then per-allocation rechecks
source $PROJECT_ROOT/validation/gate4_quota_guard.sh
export -f g4_quota_row quota_object_recheck
quota_object_recheck 0 "\$RESERVE" || { echo "REFUSED: quota baseline unhealthy" >&2; exit 67; }
# manifest: pinned sha AND complete in-job schema (count, sum,
# uniqueness, numeric size fields) -- a drifted/duplicate/compensating
# manifest cannot pass
g2d_pin "\$MANIFEST" "$GD_MANIFEST_SHA" "pinned manifest"
mcount=\$(awk -F'\\t' '!/^#/ && NF>=2 {n++} END{print n+0}' "\$MANIFEST")
ucount=\$(awk -F'\\t' '!/^#/ && NF>=2 {print \$1}' "\$MANIFEST" | sort -u | wc -l)
badnum=\$(awk -F'\\t' '!/^#/ && NF>=2 {if (\$2 !~ /^[0-9]+\$/) n++} END{print n+0}' "\$MANIFEST")
msum=\$(awk -F'\\t' '!/^#/ && NF>=2 {s+=\$2} END{printf "%.0f", s}' "\$MANIFEST")
[ "\$mcount" = "$GD_MANIFEST_COUNT" ] && [ "\$ucount" = "$GD_MANIFEST_COUNT" ] && [ "\$badnum" = 0 ] && [ "\$msum" = "$GD_MANIFEST_TOTAL" ] || { echo "REFUSED: manifest count/uniqueness/schema/sum drift" >&2; exit 65; }
# all 70 manifest rows: exact size AND HDF5 open (never name-only)
while IFS=\$'\\t' read -r name size _rest; do
    case "\$name" in ''|'#'*) continue;; esac
    case "\$name" in
        *_lw_spectra_*) sub=lw_spectra;;
        *_sw_spectra_*) sub=sw_spectra;;
        *) echo "REFUSED: manifest name without band dir: \$name" >&2; exit 65;;
    esac
    f="\$E2/\$sub/\$name"
    [ -e "\$f" ] || { echo "REFUSED: missing eval2 spectra \$name (G2c?)" >&2; exit 65; }
    sz=\$(stat -c %s "\$f")
    [ "\$sz" = "\$size" ] || { echo "REFUSED: eval2 spectra size mismatch \$name local=\$sz manifest=\$size" >&2; exit 65; }
    python3 "\$VAL" open "\$f" || { echo "REFUSED: eval2 spectra failed h5 open: \$name" >&2; exit 65; }
done < "\$MANIFEST"
echo "preflight: 70/70 eval2 spectra exact-size + h5-open verified"

echo "=== G2d stage 1: eval2 SW rayleigh (5 exact names; validated reuse) ==="
for chunk in $(join(CHUNKS, " ")); do
    R="\$E2/sw_spectra/ckdmip_evaluation2_sw_spectra_rayleigh_present_\$chunk.h5"
    H="\$E2/sw_spectra/ckdmip_evaluation2_sw_spectra_h2o_present_\$chunk.h5"
    if [ -e "\$R" ]; then
        # reuse ONLY a schema/grid-valid existing final; invalid REFUSES
        python3 "\$VAL" rayleigh "\$R" "\$H" || { echo "REFUSED: existing rayleigh final invalid: \$chunk (will not overwrite)" >&2; exit 66; }
        echo "REUSING validated rayleigh final: \$chunk"
        continue
    fi
    TMP="\$E2/sw_spectra/.g2d.ray.\$chunk.tmp"
    rm -f -- "\$TMP"   # exact allowlisted temp name, under lock
    quota_object_recheck "\$RAY_ALLOC" "\$RESERVE" || { echo "REFUSED: quota recheck before rayleigh \$chunk" >&2; exit 67; }
    $CKDMIP_BIN_ROOT/bin/ckdmip_tool --grid "\$H" --rayleigh -o "\$TMP"
    python3 "\$VAL" rayleigh "\$TMP" "\$H" || { echo "REFUSED: generated rayleigh temp invalid: \$chunk" >&2; exit 66; }
    quota_object_recheck 0 "\$RESERVE" || { echo "REFUSED: pre-publish quota recheck rayleigh \$chunk" >&2; exit 67; }
    sync "\$TMP"
    mv -- "\$TMP" "\$R"
done
echo "rayleigh provenance:"
sha256sum "\$E2/sw_spectra/"ckdmip_evaluation2_sw_spectra_rayleigh_present_*.h5

echo "=== G2d stage 2: isolated testcopy-eval2 from the PINNED artifact ==="
# pristine script pins BEFORE copy/sed
g2d_pin "$ECCKD_SRC/test/run_lw_lbl_evaluation.sh" "$GD_PRISTINE_LW_SHA" "pristine LW script"
g2d_pin "$ECCKD_SRC/test/run_sw_lbl_evaluation.sh" "$GD_PRISTINE_SW_SHA" "pristine SW script"
# TESTCOPY cleanup ONLY through the exact-path non-symlink safe helper
g2d_safe_rm_tree() {
    case "\$1" in
        "\$TESTCOPY") ;;
        *) echo "REFUSED: rm of non-allowlisted path \$1" >&2; exit 69;;
    esac
    [ -L "\$1" ] && { echo "REFUSED: allowlisted path is a symlink: \$1" >&2; exit 69; }
    rm -rf -- "\$1"
}
[ -e "\$TESTCOPY" ] && g2d_safe_rm_tree "\$TESTCOPY"
quota_object_recheck "\$LBL_ALLOC" "\$RESERVE" || { echo "REFUSED: quota recheck before testcopy" >&2; exit 67; }
cp -r "$ECCKD_SRC/test" "\$TESTCOPY"
cd "\$TESTCOPY"
$(SED_BLOCK)
# deterministic post-sed pins (constants computed at generation by
# replicating the exact sed pipeline above on the pinned artifact)
g2d_pin config.h "__POSTSED_CONFIG_SHA__" "post-sed config.h"
g2d_pin run_lw_lbl_evaluation.sh "__POSTSED_LW_SHA__" "post-sed LW script"
g2d_pin run_sw_lbl_evaluation.sh "__POSTSED_SW_SHA__" "post-sed SW script"
grep -E "^(CKDMIP_DIR|CKDMIP_DATA_DIR|WORK_DIR)=" config.h
# negative conc dependency (U3): the retargeted scripts must not read
# any evaluation2 conc file; --conc/--const literal VMR flags are the
# resolved mechanism and are expected
if grep -E "evaluation2/conc|conc/" run_lw_lbl_evaluation.sh run_sw_lbl_evaluation.sh; then
    echo "REFUSED: unexpected conc-file dependency in retargeted scripts" >&2; exit 65
fi
mkdir -p "\$WORKEVAL2/lw_lbl_fluxes" "\$WORKEVAL2/sw_lbl_fluxes"

# helpers used INSIDE the upstream scripts (bash-exported).
# RAW reuse validates the full per-10-column schema (shapes, band
# grids, scenario), selected by output name -- an interrupted but
# openable RAW chunk can never be reused
g2d_raw_valid() {
    case "\$(basename "\$1")" in
        *_lw_fluxes_*) python3 "\$VAL" raw_lw "\$1" >/dev/null 2>&1;;
        *_sw_fluxes-rgb_*) python3 "\$VAL" raw_sw "\$1" >/dev/null 2>&1;;
        *) return 1;;
    esac
}
g2d_concat_publish() { # <final>  (consumes <final>.g2dtmp)
    local final="\$1" tmp="\$1.g2dtmp"
    case "\$final" in
        *_lw_*) python3 "\$VAL" lw "\$tmp" || { echo "REFUSED: consolidated LW schema invalid" >&2; return 1; };;
        *) python3 "\$VAL" sw "\$tmp" || { echo "REFUSED: consolidated SW schema invalid" >&2; return 1; };;
    esac
    quota_object_recheck 0 "\$RESERVE" || { echo "REFUSED: pre-publish quota recheck (concat)" >&2; return 1; }
    sync "\$tmp"
    mv -- "\$tmp" "\$final"
}
export -f g2d_raw_valid g2d_concat_publish
export VAL RESERVE

echo "=== G2d stage 3: LW rel-415 LBL evaluation ==="
if [ -e "$LW_OUT" ]; then
    python3 "\$VAL" lw "$LW_OUT" || { echo "REFUSED: existing LW quarantine final invalid (will not overwrite)" >&2; exit 70; }
    echo "SKIP LW LBL: validated quarantine final exists"
else
    quota_object_recheck "\$LBL_ALLOC" "\$RESERVE" || { echo "REFUSED: quota recheck before LW LBL" >&2; exit 67; }
    bash run_lw_lbl_evaluation.sh
fi
echo "=== G2d stage 4: SW rel-415 RGB LBL evaluation ==="
if [ -e "$SW_OUT" ]; then
    python3 "\$VAL" sw "$SW_OUT" || { echo "REFUSED: existing SW quarantine final invalid (will not overwrite)" >&2; exit 70; }
    echo "SKIP SW LBL: validated quarantine final exists"
else
    quota_object_recheck "\$LBL_ALLOC" "\$RESERVE" || { echo "REFUSED: quota recheck before SW LBL" >&2; exit 67; }
    bash run_sw_lbl_evaluation.sh
fi

echo "=== G2d stage 5: quarantine schema gate (exact-2, full validation) ==="
python3 "\$VAL" lw "$LW_OUT" || { echo "REFUSED: LW quarantine output failed schema" >&2; exit 71; }
python3 "\$VAL" sw "$SW_OUT" || { echo "REFUSED: SW quarantine output failed schema" >&2; exit 71; }

echo "=== G2d stage 6: atomic installs into the exact G3 targets ==="
# >>> g2d_install_one
g2d_install_one() { # <src> <dst> <mode:lw|sw>
    local src="\$1" dst="\$2" mode="\$3" tmp
    if [ -e "\$dst" ]; then
        # SKIP only if schema-valid AND byte-identical to quarantine
        python3 "\$VAL" "\$mode" "\$dst" || { echo "REFUSED: existing install target invalid: \$dst" >&2; return 1; }
        cmp -s "\$src" "\$dst" || { echo "REFUSED: existing install target differs from quarantine: \$dst" >&2; return 1; }
        echo "SKIP install (validated identical): \$dst"
        return 0
    fi
    tmp="\$(dirname "\$dst")/.g2d.install.\$(basename "\$dst")"
    rm -f -- "\$tmp"
    quota_object_recheck "\$(stat -c %s "\$src")" "\$RESERVE" || { echo "REFUSED: quota recheck before install \$dst" >&2; return 1; }
    cp -- "\$src" "\$tmp"
    python3 "\$VAL" "\$mode" "\$tmp" || { echo "REFUSED: install temp failed schema: \$dst" >&2; return 1; }
    cmp -s "\$src" "\$tmp" || { echo "REFUSED: install temp differs from source: \$dst" >&2; return 1; }
    sync "\$tmp"
    mv -- "\$tmp" "\$dst"
    # post-mv verification
    python3 "\$VAL" "\$mode" "\$dst" || { echo "REFUSED: post-mv schema failure: \$dst" >&2; return 1; }
    cmp -s "\$src" "\$dst" || { echo "REFUSED: post-mv identity failure: \$dst" >&2; return 1; }
    echo "INSTALLED \$dst"
}
# <<< g2d_install_one
mkdir -p "$G4WORK/work/lw_lbl_fluxes" "$G4WORK/work/sw_lbl_fluxes" "$G4WORK/work-v14/sw_lbl_fluxes"
g2d_install_one "$LW_OUT" "$LW_INSTALL" lw || exit 72
g2d_install_one "$SW_OUT" "$SW_INSTALL" sw || exit 72
g2d_install_one "$SW_OUT" "$SW_INSTALL_V14" sw || exit 72

echo "=== G2d outputs ==="
sha256sum "$LW_OUT" "$SW_OUT" "$LW_INSTALL" "$SW_INSTALL" "$SW_INSTALL_V14"
echo "=== G2d done \$(date -u +%FT%TZ) ==="
"""

# --- guarded Unit L ledger loader (coupled byte snapshot) --------------------

function gd_snapshot(path)
    isfile(path) || return (ok = false, reason = "missing", sha = nothing,
                            data = nothing)
    bytes = try
        read(path)
    catch
        return (ok = false, reason = "unreadable", sha = nothing,
                data = nothing)
    end
    sha = bytes2hex(sha256(bytes))
    data = try
        JSON.parse(String(copy(bytes)))
    catch
        return (ok = false, reason = "unparseable (parse failure)",
                sha = sha, data = nothing)
    end
    data isa AbstractDict || return (ok = false,
        reason = "parses to a non-object (JSON null/array/scalar)",
        sha = sha, data = nothing)
    (ok = true, reason = "", sha = sha, data = data)
end

# fail-closed classifier: exact case, exact green status, exact byte sha
function classify_g2c_ledger(path; expected_case = GD_LEDGER_CASE,
                             expected_status = GD_LEDGER_STATUS,
                             expected_sha = GD_LEDGER_SHA)
    snap = gd_snapshot(path)
    snap.ok || return (ok = false, class = snap.reason,
                       reason = "completion ledger $(snap.reason)")
    c = get(snap.data, "case", nothing)
    c == expected_case || return (ok = false, class = "case mismatch",
        reason = "completion ledger case mismatch (got $(repr(c)))")
    s = get(snap.data, "status", nothing)
    s == expected_status || return (ok = false, class = "not green",
        reason = "completion ledger status $(repr(s)) != $expected_status")
    snap.sha == expected_sha || return (ok = false, class = "sha drift",
        reason = "completion ledger sha $(snap.sha) != pinned $(expected_sha)")
    (ok = true, class = "green", reason = "")
end

# --- fail-closed gate census -------------------------------------------------

function gd_close_failed_gates!(fails, gates)
    bad = sort([k for (k, v) in gates if v != "passed"])
    isempty(bad) ||
        push!(fails, "failed gates (fail-closed census): " * join(bad, ", "))
end

# --- fixtures ----------------------------------------------------------------

function gd_fixtures()
    t = Dict{String, Bool}()
    fx = mktempdir()
    green = Dict("case" => GD_LEDGER_CASE, "status" => GD_LEDGER_STATUS)
    wr(name, content) = begin
        p = joinpath(fx, name)
        content === nothing || write(p, content)
        p
    end
    cls(p; kw...) = classify_g2c_ledger(p; kw...)
    shaof(p) = bytes2hex(sha256(read(p)))

    # loader refusal classes
    t["ledger_missing_refuses"] =
        !cls(joinpath(fx, "absent.json")).ok &&
        cls(joinpath(fx, "absent.json")).class == "missing"
    p = wr("bad.json", "{ not json")
    t["ledger_unparseable_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "unparseable (parse failure)"
    p = wr("arr.json", "[1, 2]")
    t["ledger_non_object_refuses"] =
        cls(p; expected_sha = shaof(p)).class ==
        "parses to a non-object (JSON null/array/scalar)"
    p = wr("case.json", JSON.json(Dict("case" => "other_case",
                                       "status" => GD_LEDGER_STATUS)))
    t["ledger_case_mismatch_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "case mismatch"
    for tok in ("g2c_fetch_ledger_waiting_for_job",
                "g2c_fetch_ledger_resumable_timeout",
                "g2c_fetch_ledger_failed",
                "g2c_fetch_ledger_indeterminate_refused")
        p = wr("st_$tok.json", JSON.json(Dict("case" => GD_LEDGER_CASE,
                                              "status" => tok)))
        t["ledger_nongreen_$(tok)_refuses"] =
            cls(p; expected_sha = shaof(p)).class == "not green"
    end
    p = wr("green.json", JSON.json(green))
    t["ledger_hash_drift_refuses"] =
        cls(p; expected_sha = "0" ^ 64).class == "sha drift"
    t["ledger_green_accepted"] = cls(p; expected_sha = shaof(p)).ok

    # schema validators against the REAL eval1 rel-415 precedents
    vpath = joinpath(fx, "validator.py")
    write(vpath, PY_VALIDATOR)
    lw1 = "$CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-415.h5"
    sw1 = "$CKDMIP_ROOT/evaluation1/sw_fluxes-rgb/ckdmip_evaluation1_sw_fluxes-rgb_rel-415.h5"
    runval(args...) = success(pipeline(`python3 $vpath $(collect(args))`,
                                       stdout=devnull, stderr=devnull))
    t["schema_lw_accepts_eval1_precedent"] = runval("lw", lw1)
    t["schema_sw_accepts_eval1_precedent"] = runval("sw", sw1)
    t["schema_lw_rejects_sw_file"] = !runval("lw", sw1)
    t["schema_sw_rejects_lw_file"] = !runval("sw", lw1)
    t["schema_open_accepts_ssi"] = runval("open", GD_SSI)
    t["schema_open_rejects_non_h5"] = !runval("open", vpath)

    # synthetic RAW / rayleigh fixtures: malformed-but-OPEN files refuse
    builder = joinpath(fx, "builder.py")
    write(builder, """
import sys, h5py, numpy as np
mode = sys.argv[1]
f = h5py.File(sys.argv[2], "w")
lwb1 = np.array($LW_BANDS1, dtype="f4")
lwb2 = np.array($LW_BANDS2, dtype="f4")
swb1 = np.array($SW_BANDS1, dtype="f4")
swb2 = np.array($SW_BANDS2, dtype="f4")
def lwbase(drop=None, badshape=False):
    f["band_flux_up_lw"] = np.zeros((10, 55, 13))
    if drop != "band_flux_dn_lw":
        f["band_flux_dn_lw"] = np.zeros((9, 55, 13) if badshape else (10, 55, 13))
    f["flux_up_lw"] = np.zeros((10, 55))
    f["flux_dn_lw"] = np.zeros((10, 55))
    f["pressure_hl"] = np.zeros((10, 55))
    f["temperature_hl"] = np.zeros((10, 55))
    f["band_wavenumber1_lw"] = lwb1
    f["band_wavenumber2_lw"] = lwb2
    f.attrs["scenario"] = "rel-415"
if mode == "raw_lw_good":
    lwbase()
elif mode == "raw_lw_missing":
    lwbase(drop="band_flux_dn_lw")
elif mode == "raw_lw_badshape":
    lwbase(badshape=True)
elif mode == "raw_sw_good":
    for k in ("band_flux_up_sw", "band_flux_dn_sw", "band_flux_dn_direct_sw"):
        f[k] = np.zeros((10, 5, 55, 9))
    for k in ("flux_up_sw", "flux_dn_sw", "flux_dn_direct_sw"):
        f[k] = np.zeros((10, 5, 55))
    f["mu0"] = np.zeros((5,))
    f["pressure_hl"] = np.zeros((10, 55))
    f["temperature_hl"] = np.zeros((10, 55))
    f["band_wavenumber1_sw"] = swb1
    f["band_wavenumber2_sw"] = swb2
    f.attrs["scenario"] = "rel-415"
elif mode.startswith("h2o_") or mode.startswith("ray_"):
    # real eval2 contract shapes; big datasets are created LAZILY (no
    # data written -> tiny files, fill-value reads) so shape and value
    # comparisons exercise the exact production contract cheaply
    NW = 3126494
    def axes():
        f.create_dataset("column", shape=(10,), dtype="f4")
        f.create_dataset("level", shape=(54,), dtype="i2")
        if mode != "ray_missing_axis":
            f.create_dataset("half_level", shape=(55,), dtype="i2")
    if mode == "h2o_stub":
        f.create_dataset("wavenumber", shape=(NW,), dtype="f8")
        f.create_dataset("pressure_hl", shape=(10, 55), dtype="f4")
        axes()
    elif mode == "h2o_badshape":
        f.create_dataset("wavenumber", shape=(100,), dtype="f8")
        f.create_dataset("pressure_hl", shape=(10, 55), dtype="f4")
        axes()
    else:
        f.create_dataset("wavenumber", shape=(NW,), dtype="f8")
        if mode == "ray_wavemis":
            f["wavenumber"][0] = 1.0
        f.create_dataset("pressure_hl", shape=(10, 55), dtype="f4")
        axes()
        f.create_dataset("optical_depth",
                         shape=((10, 53, NW) if mode == "ray_badshape"
                                else (10, 54, NW)), dtype="f4")
        if mode != "ray_missing":
            f.create_dataset("column_optical_depth", shape=(10, NW),
                             dtype="f4")
        f["single_scattering_albedo"] = 0.5 if mode == "ray_badssa" else 1.0
        f["asymmetry_factor"] = 0.0
f.close()
""")
    mkh5(mode) = begin
        p = joinpath(fx, mode * ".h5")
        run(pipeline(`python3 $builder $mode $p`,
                     stdout=devnull, stderr=devnull))
        p
    end
    rawlw = mkh5("raw_lw_good"); rawsw = mkh5("raw_sw_good")
    t["schema_ssi_accepts_pinned_ssi"] = runval("ssi", GD_SSI)
    t["schema_ssi_rejects_generic_h5"] = !runval("ssi", rawlw)
    t["raw_lw_accepts_conforming_chunk"] = runval("raw_lw", rawlw)
    t["raw_sw_accepts_conforming_chunk"] = runval("raw_sw", rawsw)
    rawlw_missing = mkh5("raw_lw_missing")
    t["raw_lw_rejects_missing_dataset"] = !runval("raw_lw", rawlw_missing)
    t["raw_lw_rejects_bad_shape"] = !runval("raw_lw", mkh5("raw_lw_badshape"))
    t["raw_lw_rejects_50col_final"] = !runval("raw_lw", lw1)
    t["raw_lw_rejects_sw_chunk"] = !runval("raw_lw", rawsw)
    # open-mode would have accepted the malformed chunk: proves the raw
    # modes are strictly stronger than the old openability test
    t["raw_modes_stricter_than_open"] = runval("open", rawlw_missing)
    h2ostub = mkh5("h2o_stub")
    raygood = mkh5("ray_good")
    t["rayleigh_accepts_conforming"] =
        runval("rayleigh", raygood, h2ostub)
    t["rayleigh_rejects_missing_dataset"] =
        !runval("rayleigh", mkh5("ray_missing"), h2ostub)
    t["rayleigh_rejects_bad_od_shape"] =
        !runval("rayleigh", mkh5("ray_badshape"), h2ostub)
    t["rayleigh_rejects_wavenumber_mismatch"] =
        !runval("rayleigh", mkh5("ray_wavemis"), h2ostub)
    t["rayleigh_rejects_missing_axis"] =
        !runval("rayleigh", mkh5("ray_missing_axis"), h2ostub)
    t["rayleigh_rejects_nonunity_ssa"] =
        !runval("rayleigh", mkh5("ray_badssa"), h2ostub)
    t["rayleigh_rejects_bad_source_shape"] =
        !runval("rayleigh", raygood, mkh5("h2o_badshape"))
    t["rayleigh_source_contract_on_real_chunk"] =
        runval("rayleigh", raygood,
               "$CKDMIP_ROOT/evaluation2/sw_spectra/" *
               "ckdmip_evaluation2_sw_spectra_h2o_present_1-10.h5") == false

    # install helper extracted VERBATIM from the generated sbatch text
    # and exercised with a stubbed validator
    m1 = findfirst("# >>> g2d_install_one", SBATCH_TEXT)
    m2 = findfirst("# <<< g2d_install_one", SBATCH_TEXT)
    if m1 !== nothing && m2 !== nothing
        snippet = replace(SBATCH_TEXT[first(m1):first(m2)-1],
                          "\\\$" => "\$")
        hd = joinpath(fx, "inst"); mkpath(hd)
        src = joinpath(hd, "src.h5"); write(src, "SRCDATA")
        dst = joinpath(hd, "dst.h5")
        stubval = joinpath(fx, "stubval.py")
        write(stubval, "import sys\nsys.exit(0 if 'ok' in open(sys.argv[2], 'rb').read().decode('utf8','ignore') or sys.argv[2].endswith('src.h5') or '.g2d.install.' in sys.argv[2] or sys.argv[2].endswith('dst.h5') else 1)\n")
        # driver: stub VAL accepts everything; quota recheck stubbed OK
        drv(pre, target) = success(pipeline(`/bin/bash -c $("""
            set -u
            VAL=$stubval
            RESERVE=1
            quota_object_recheck() { return 0; }
            $snippet
            $pre
            g2d_install_one "$src" "$target" lw
            """)`, stdout=devnull, stderr=devnull))
        t["install_absent_target_installs"] =
            drv("", dst) && isfile(dst) && read(dst, String) == "SRCDATA"
        t["install_identical_target_skips"] = drv("", dst)
        write(joinpath(hd, "diff.h5"), "OTHER")
        t["install_mismatched_target_refuses"] =
            !drv("", joinpath(hd, "diff.h5"))
        # invalid target: stub validator rejects files containing REJECT
        stubval2 = joinpath(fx, "stubval2.py")
        write(stubval2, "import sys\nsys.exit(1 if b'REJECT' in open(sys.argv[2],'rb').read() else 0)\n")
        write(joinpath(hd, "bad.h5"), "REJECT")
        drv2(target) = success(pipeline(`/bin/bash -c $("""
            set -u
            VAL=$stubval2
            RESERVE=1
            quota_object_recheck() { return 0; }
            $snippet
            g2d_install_one "$src" "$target" lw
            """)`, stdout=devnull, stderr=devnull))
        t["install_invalid_target_refuses"] = !drv2(joinpath(hd, "bad.h5"))
    else
        for k in ("install_absent_target_installs",
                  "install_identical_target_skips",
                  "install_mismatched_target_refuses",
                  "install_invalid_target_refuses")
            t[k] = false
        end
    end

    # safe tree removal helper semantics (allowlist + non-symlink)
    saferm = """
        TESTCOPY=%TC%
        g2d_safe_rm_tree() {
            case "\$1" in
                "\$TESTCOPY") ;;
                *) echo "REFUSED: rm of non-allowlisted path \$1" >&2; exit 69;;
            esac
            [ -L "\$1" ] && { echo "REFUSED: allowlisted path is a symlink: \$1" >&2; exit 69; }
            rm -rf -- "\$1"
        }
        g2d_safe_rm_tree "%TARGET%"
        """
    tc = joinpath(fx, "tc"); mkpath(joinpath(tc, "inner"))
    ok1 = success(pipeline(`/bin/bash -c $(replace(replace(saferm, "%TC%" => tc), "%TARGET%" => tc))`,
                           stdout=devnull, stderr=devnull))
    t["saferm_allowlisted_tree_removed"] = ok1 && !isdir(tc)
    other = joinpath(fx, "other"); mkpath(other)
    t["saferm_non_allowlisted_refuses"] =
        !success(pipeline(`/bin/bash -c $(replace(replace(saferm, "%TC%" => tc), "%TARGET%" => other))`,
                          stdout=devnull, stderr=devnull)) && isdir(other)
    lnk = joinpath(fx, "lnk"); symlink(other, lnk)
    t["saferm_symlink_refuses"] =
        !success(pipeline(`/bin/bash -c $(replace(replace(saferm, "%TC%" => lnk), "%TARGET%" => lnk))`,
                          stdout=devnull, stderr=devnull)) && isdir(other)
    t
end

# --- main ---------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()

    # prerequisite: committed Unit L ledger, guarded loader (SINGLE call)
    led = classify_g2c_ledger(GD_LEDGER_JSON)
    gates["g2c_completion_ledger_green"] = led.ok ? "passed" : "failed"
    led.ok || push!(fails, led.reason)

    tests = gd_fixtures()
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    # single-call-site discipline for the guarded loader
    self_src = read(@__FILE__, String)
    n_led_calls = length(collect(eachmatch(
        r"classify_g2c_ledger\(GD_LEDGER_JSON\)", self_src)))
    gates["ledger_loader_single_call_site"] =
        n_led_calls == 1 ? "passed" : "failed"

    # live input pins at generation (checkpoint-side mirror of stage 0)
    pin_ok(path, expected) = try
        isfile(path) && bytes2hex(sha256(read(path))) == expected
    catch; false end
    gates["binary_pins_live"] =
        all(pin_ok(joinpath(CKDMIP_BIN_ROOT, "bin", b), h)
            for (b, h) in GD_BIN_PINS) ? "passed" : "failed"
    gates["pristine_script_pins_live"] =
        (pin_ok(joinpath(ECCKD_SRC, "test/run_lw_lbl_evaluation.sh"),
                GD_PRISTINE_LW_SHA) &&
         pin_ok(joinpath(ECCKD_SRC, "test/run_sw_lbl_evaluation.sh"),
                GD_PRISTINE_SW_SHA)) ? "passed" : "failed"
    gates["ssi_pins_live"] =
        (isfile(GD_SSI) && filesize(GD_SSI) == GD_SSI_BYTES &&
         pin_ok(GD_SSI, GD_SSI_SHA)) ? "passed" : "failed"
    man_rows = try
        [split(l, '\t') for l in eachline(GD_MANIFEST)
         if !startswith(l, '#') && !isempty(strip(l))]
    catch; nothing end
    gates["manifest_integrity"] =
        (man_rows !== nothing && length(man_rows) == GD_MANIFEST_COUNT &&
         length(unique(first.(man_rows))) == GD_MANIFEST_COUNT &&
         sum(parse(Int, r[2]) for r in man_rows) == GD_MANIFEST_TOTAL) ?
        "passed" : "failed"

    # deterministic post-sed sha constants: replicate the EXACT sed
    # pipeline on the pinned artifact in a temp dir
    postsed = Dict{String, String}()
    sed_ok = try
        td = mktempdir()
        for f in ("version.h.in", "config.h", "run_lw_lbl_evaluation.sh",
                  "run_sw_lbl_evaluation.sh")
            cp(joinpath(ECCKD_SRC, "test", f), joinpath(td, f))
        end
        write(joinpath(td, "apply.sh"), "set -e\ncd $td\n" * SED_BLOCK)
        run(pipeline(`/bin/bash $td/apply.sh`, stdout=devnull, stderr=devnull))
        for (k, f) in (("config", "config.h"),
                       ("lw", "run_lw_lbl_evaluation.sh"),
                       ("sw", "run_sw_lbl_evaluation.sh"))
            postsed[k] = bytes2hex(sha256(read(joinpath(td, f))))
        end
        true
    catch; false end
    gates["postsed_pins_computed"] = sed_ok ? "passed" : "failed"
    sed_ok || push!(fails, "post-sed sha replication failed")

    sbatch_text = sed_ok ?
        replace(replace(replace(SBATCH_TEXT,
            "__POSTSED_CONFIG_SHA__" => postsed["config"]),
            "__POSTSED_LW_SHA__" => postsed["lw"]),
            "__POSTSED_SW_SHA__" => postsed["sw"]) : SBATCH_TEXT

    open(GD_SBATCH, "w") do io
        write(io, sbatch_text)
    end
    sbatch_sha = bytes2hex(sha256(read(GD_SBATCH)))
    gates["sbatch_written_not_submitted"] = "passed"
    sb_tok = "sb" * "atch "
    isempty(collect(eachmatch(Regex("run\\(`" * sb_tok), self_src))) ||
        (gates["sbatch_written_not_submitted"] = "failed";
         push!(fails, "sbatch invocation found in checkpoint unit"))

    gates["headnode_refusal_guard"] =
        occursin("REFUSED: head-node execution", sbatch_text) ? "passed" : "failed"
    exec_lines = join([l for l in split(sbatch_text, '\n')
                       if !occursin(r"^\s*#", l)], '\n')
    gates["lbl_and_rayleigh_only"] =
        occursin("run_lw_lbl_evaluation.sh", exec_lines) &&
        occursin("run_sw_lbl_evaluation.sh", exec_lines) &&
        occursin("--rayleigh", exec_lines) &&
        !occursin("optimize_lut", exec_lines) &&
        !occursin("create_lut", exec_lines) &&
        !occursin("scale_lut", exec_lines) &&
        !occursin("find_g_points", exec_lines) ? "passed" : "failed"
    gates["lbl_and_rayleigh_only"] == "passed" ||
        push!(fails, "forbidden stage invocation in executable lines")
    gates["exact_g3_targets"] =
        occursin(LW_INSTALL, sbatch_text) &&
        occursin(SW_INSTALL, sbatch_text) &&
        occursin(SW_INSTALL_V14, sbatch_text) &&
        occursin("g2d_install_one \"$LW_OUT\" \"$LW_INSTALL\" lw", sbatch_text) &&
        occursin("g2d_install_one \"$SW_OUT\" \"$SW_INSTALL\" sw", sbatch_text) &&
        occursin("g2d_install_one \"$SW_OUT\" \"$SW_INSTALL_V14\" sw", sbatch_text) ?
        "passed" : "failed"
    flock_check = findfirst("command -v flock", sbatch_text)
    flock_use = findfirst("flock -n 9", sbatch_text)
    gates["single_run_lock"] =
        (flock_check !== nothing && flock_use !== nothing &&
         first(flock_check) < first(flock_use) &&
         occursin(".g2d.lock", sbatch_text)) ? "passed" : "failed"
    nrechecks = length(collect(eachmatch(r"quota_object_recheck", exec_lines)))
    gates["soft_quota_rechecks"] =
        (occursin("gate4_quota_guard.sh", sbatch_text) &&
         occursin("RESERVE=$GD_RESERVE", sbatch_text) &&
         occursin("RAY_ALLOC=$GD_RAY_ALLOC", sbatch_text) &&
         nrechecks >= 9) ? "passed" : "failed"
    gates["schema_validation_no_size_floor"] =
        occursin("band_flux_up_lw", sbatch_text) &&
        occursin("(50, 55, 13)", sbatch_text) &&
        occursin("(50, 5, 55, 9)", sbatch_text) &&
        occursin("(10, 55, 13)", sbatch_text) &&
        occursin("(10, 5, 55, 9)", sbatch_text) &&
        occursin("raw_lw", sbatch_text) &&
        occursin("raw_sw", sbatch_text) &&
        occursin("column_optical_depth", sbatch_text) &&
        occursin("(10, 54, 3126494)", sbatch_text) &&
        occursin("(3126494,)", sbatch_text) &&
        occursin("single_scattering_albedo != 1", sbatch_text) &&
        occursin("14300.0", sbatch_text) &&
        occursin("3260.0", sbatch_text) &&
        occursin("rel-415", sbatch_text) &&
        occursin("\"mu0\": (5,)", sbatch_text) ? "passed" : "failed"
    gates["retry_safe_reuse"] =
        occursin("REUSING validated rayleigh final", sbatch_text) &&
        occursin("SKIP LW LBL: validated quarantine final exists", sbatch_text) &&
        occursin("SKIP SW LBL: validated quarantine final exists", sbatch_text) &&
        occursin("g2d_raw_valid", sbatch_text) &&
        occursin("g2d_concat_publish", sbatch_text) &&
        !occursin("rm -rf \"\$WORKEVAL2\"", sbatch_text) ? "passed" : "failed"
    gates["atomic_publication"] =
        occursin(".g2d.ray.", sbatch_text) &&
        occursin(".g2dtmp", sbatch_text) &&
        occursin(".g2d.install.", sbatch_text) &&
        occursin("sync \"\$TMP\"", sbatch_text) &&
        occursin("sync \"\$tmp\"", sbatch_text) &&
        occursin("mv -- \"\$TMP\" \"\$R\"", sbatch_text) &&
        occursin("mv -- \"\$tmp\" \"\$dst\"", sbatch_text) ? "passed" : "failed"
    # deletion discipline: exactly one rm -rf, inside the safe helper;
    # no find -delete; every rm -f uses -- with an exact temp name
    n_rmrf = length(collect(eachmatch(r"rm -rf", sbatch_text)))
    gates["no_broad_deletion"] =
        (n_rmrf == 1 && occursin("rm -rf -- \"\$1\"", sbatch_text) &&
         !occursin("-delete", sbatch_text) &&
         !occursin(r"\bfind\b.*-exec"m, sbatch_text)) ? "passed" : "failed"
    gates["df_gate_removed"] =
        !occursin(r"\bdf\b", exec_lines) ? "passed" : "failed"
    gates["negative_conc_dependency"] =
        occursin("evaluation2/conc|conc/", sbatch_text) &&
        occursin("unexpected conc-file dependency", sbatch_text) ? "passed" : "failed"
    gates["in_job_pins"] =
        occursin(GD_SSI_SHA, sbatch_text) &&
        occursin("\"\$VAL\" ssi ", sbatch_text) &&
        occursin("total_solar_irradiance != 1361.0", sbatch_text) &&
        occursin("MISSING/nonexecutable binary", sbatch_text) &&
        occursin(GD_GUARD_SHA, sbatch_text) &&
        occursin(GD_CONCAT_SHA, sbatch_text) &&
        occursin(GD_TESTPROJ_SHA, sbatch_text) &&
        occursin(GD_TESTMANIFEST_SHA, sbatch_text) &&
        all(occursin(h, sbatch_text) for (_, h) in GD_BIN_PINS) &&
        occursin(GD_PRISTINE_LW_SHA, sbatch_text) &&
        occursin(GD_PRISTINE_SW_SHA, sbatch_text) &&
        (!sed_ok || (occursin(postsed["config"], sbatch_text) &&
                     occursin(postsed["lw"], sbatch_text) &&
                     occursin(postsed["sw"], sbatch_text))) ? "passed" : "failed"
    gates["in_job_70_row_verification"] =
        occursin("70/70 eval2 spectra exact-size + h5-open verified", sbatch_text) &&
        occursin("eval2 spectra size mismatch", sbatch_text) &&
        occursin("manifest count/uniqueness/schema/sum drift", sbatch_text) &&
        occursin(GD_MANIFEST_SHA, sbatch_text) &&
        !occursin("test -s \"\$f\"", sbatch_text) ? "passed" : "failed"
    man_sha_live = try
        bytes2hex(sha256(read(GD_MANIFEST)))
    catch; nothing end
    gates["manifest_sha_pinned_live"] =
        man_sha_live == GD_MANIFEST_SHA ? "passed" : "failed"
    gates["repo_dependency_pins_live"] =
        (pin_ok(GD_GUARD_PATH, GD_GUARD_SHA) &&
         pin_ok(GD_CONCAT_PATH, GD_CONCAT_SHA) &&
         pin_ok(GD_TESTPROJ_PATH, GD_TESTPROJ_SHA) &&
         pin_ok(GD_TESTMANIFEST_PATH, GD_TESTMANIFEST_SHA)) ?
        "passed" : "failed"

    status = if !led.ok && led.class in ("not green",) &&
                isempty([k for (k, v) in gates
                         if v != "passed" && k != "g2c_completion_ledger_green"])
        "g2d_checkpoint_waiting_for_g2c"
    elseif isempty(fails) && all(v -> v == "passed", values(gates))
        "g2d_checkpoint_ready"
    else
        "g2d_checkpoint_failed"
    end
    gd_close_failed_gates!(fails, gates)
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    ghead = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_g2d_eval2_rel415_flux_checkpoint",
        "data_mode" => "dry_run_script_generation_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)) * "Z",
        "gates" => gates, "failures" => fails,
        "fixture_verdicts" => tests,
        "sbatch_path" => GD_SBATCH,
        "sbatch_sha256" => sbatch_sha,
        "prerequisite" => Dict(
            "ledger" => GD_LEDGER_JSON,
            "expected_case" => GD_LEDGER_CASE,
            "expected_status" => GD_LEDGER_STATUS,
            "expected_sha256" => GD_LEDGER_SHA,
            "classifier_verdict" => led.ok ? "green" : led.class),
        "pins" => Dict(
            "binaries" => Dict(b => h for (b, h) in GD_BIN_PINS),
            "pristine_lw" => GD_PRISTINE_LW_SHA,
            "pristine_sw" => GD_PRISTINE_SW_SHA,
            "ssi" => Dict("path" => GD_SSI, "bytes" => GD_SSI_BYTES,
                          "sha256" => GD_SSI_SHA),
            "postsed" => postsed,
            "manifest" => Dict("path" => GD_MANIFEST,
                "sha256" => GD_MANIFEST_SHA,
                "count" => GD_MANIFEST_COUNT,
                "bytes" => GD_MANIFEST_TOTAL),
            "repo_dependencies" => Dict(
                "quota_guard" => Dict("path" => GD_GUARD_PATH,
                                      "sha256" => GD_GUARD_SHA),
                "concat_helper" => Dict("path" => GD_CONCAT_PATH,
                                        "sha256" => GD_CONCAT_SHA),
                "test_project" => Dict("path" => GD_TESTPROJ_PATH,
                                       "sha256" => GD_TESTPROJ_SHA),
                "test_manifest" => Dict("path" => GD_TESTMANIFEST_PATH,
                                        "sha256" => GD_TESTMANIFEST_SHA),
                "note" => "live executable repo dependencies pinned " *
                    "in-job before source/use; --project=test is the " *
                    "concat environment, so its Project AND resolved " *
                    "Manifest are both pinned (full dependency-closure " *
                    "provenance)"),
            "bindir_note" => "BINDIR points at the established v1.2 " *
                "path but is NON-COMPUTATIONAL for this unit: neither " *
                "LBL script executes it"),
        "estimates" => Dict(
            "rayleigh_alloc_per_chunk_bytes" => GD_RAY_ALLOC,
            "rayleigh_alloc_derivation" => "conservative 15 GiB PER " *
                "chunk: per-chunk source dims 10 x 54 x 3,126,494 at " *
                "up to 8 bytes + overhead, compression uncredited " *
                "(monitor-specified worst case); five chunks imply a " *
                "75 GiB worst-case total, gated per-chunk by live " *
                "rechecks",
            "flux_output_evidence_bytes" => Dict(
                "eval1_lw_rel415" => 450863,
                "eval1_sw_rgb_rel415" => 1817472),
            "lbl_stage_alloc_bytes" => GD_LBL_ALLOC,
            "wall_derivation" => "job 4078: 12 LW + 6 SW scenarios in " *
                "17h44 (~59 min/scenario); G2a 6 SW in 5h18; G2b 10 SW " *
                "in 9h46. Two G2d scenarios project ~2 h plus rayleigh; " *
                "the 08:00:00 wall is >3x margin",
            "quota_baseline_note" => "used ~508.2 GiB observed " *
                "2026-08-13 (live lfs read; NOT a code constant); " *
                "soft-primary guard with 50 GiB reserve gates every " *
                "allocation live"),
        "negative_conc_dependency" => "pinned rel-415 scripts use " *
            "spectra-embedded reference concentrations and literal VMR " *
            "scaling (--conc 415e-6/--const); NO evaluation2 conc files " *
            "are read; asserted in-job (U3 resolved)",
        "path_contract" => Dict(
            "generate_lw" => LW_OUT, "generate_sw" => SW_OUT,
            "install_lw" => LW_INSTALL, "install_sw" => SW_INSTALL,
            "install_sw_v14" => SW_INSTALL_V14,
            "rationale" => "two-phase: generate in quarantined " *
                "work-eval2, full schema gate, atomic install into the " *
                "EXISTING executor trees; G3 keeps WORK_DIR=work (LW) / " *
                "work-v14 (SW primary, work alt); final SW wiring " *
                "decided at the G3 spec review"),
        "provenance" => Dict("branch" => branch, "generated_from_head" => ghead,
            "provenance_note" => "artifact generated from the working " *
                "tree before its own commit"),
        "disclaimer" => "script generation only; nothing submitted by " *
            "this unit; rayleigh + LBL evaluation only; no optimizer, " *
            "objective, floor, or recovery computation.",
    )
    mkpath(dirname(GD_RESULTS_JSON))
    open(GD_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(GD_RESULTS_MD, "w") do io
        println(io, "# Gate-4 G2d evaluation2 rel-415 flux checkpoint\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "Prerequisite: committed Unit L completion ledger, ",
                "guarded loader verdict: **",
                led.ok ? "green" : led.class, "**\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nGenerated sbatch sha256: `$sbatch_sha`")
        println(io, "\nPath contract: install to `$(LW_INSTALL)`, " *
                    "`$(SW_INSTALL)`, `$(SW_INSTALL_V14)` (two-phase, " *
                    "atomic, schema-gated; see JSON).")
        println(io, "\nWall/quota estimates: see JSON `estimates` " *
                    "(evidence-based derivations recorded).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_g2d_eval2_rel415_flux_checkpoint: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status in ("g2d_checkpoint_ready",
                      "g2d_checkpoint_waiting_for_g2c") ? 0 : 1
end

exit(main())
