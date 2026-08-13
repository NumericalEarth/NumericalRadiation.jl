# Gate-4 B0 ERA-LBFGS MECHANISM-ISOLATION CHECKPOINT (generator; writes
# ONLY its own JSON/MD results + the generated sbatch). Diagnosis unit
# downstream of the reviewed G3 run ledger: G1 objective FAILED at
# 22.8246 with damage isolated to the LW relative-base pass, and public
# history shows the v1.2 recovery ran a post-v1.0 optimizer mechanism
# (Adept L-BFGS + bounded minimization with *_min/*_max arrays) while
# the target-era v1.0/b42e5c0 code runs the in-tree third-party
# solve_lbfgs backend, unbounded (USE_LBFGS_LIBRARY=1).
#
# B0 (monitor-approved design, 2026-08-13): hold init/g-points/training
# FIXED and change EXACTLY the optimizer mechanism --
#   - same ce057079... v1.2 LW raw init (16 min/max arrays retained;
#     static source review: the old reader requests named variables and
#     ignores extras; a controlled 1-iteration schema-open probe proves
#     readability in-job and REFUSES rather than stripping)
#   - same seven size+sha-pinned training flux files
#   - old solve_lbfgs backend built in-job from the pinned b42e5c0
#     commit via git archive into a job-private source dir (never a
#     worktree; no shared-repo mutation)
#   - leg-1 options ruling (APPROVED, exclusive): the exact 4515
#     relative-base config -- same v1.2 testcopy generation machinery,
#     era defaults max_iterations=3000 / convergence_criterion=0.02
#     equal the v1.2-generated values by construction
#   - PRIVATE output only: everything under
#     $G4WORK/g4-diag/$SLURM_JOB_ID/lw-b0; ZERO canonical writes, no
#     publish stage, no band lock needed (nothing shared is mutated)
# Era code still calls enable_floating_point_exceptions()
# (optimize_lut.cpp:52 at b42e5c0), so the proven exact-version Netlib
# preload trio + ldd proof are carried over verbatim from 4515.
#
# SUBMISSION IS HELD for monitor review: this generator only produces
# the sbatch + evidence; it never submits.

include(joinpath(@__DIR__, "validation_results.jl"))

import JSON
using SHA: sha256

const B0_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
const B0_G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const B0_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"
const B0_CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"

# --- era toolchain pins (monitor-supplied, independently verified) -------------
const B0_ERA_REPO = "/shared/home/greg/ecckd-derived-flux-work/ecckd-v1.4-23adaca"
const B0_ERA_COMMIT = "b42e5c0b188f1e7b747990bc2b35e6c53c2c7258"
const B0_ERA_TREE = "0d2a0454f758de7bec04790c1ece54551e465b94"
const B0_ERA_ARCHIVE_SHA = "801542f43e6d9c0f444d6966fbe30d28fc3df7aabf147551c4485f352fbafa22"
const B0_ERA_BLOBS = [
    ("src/ecckd/optimize_lut.cpp",
     "c0ec54b57c25be734f7dcde1d1afadd812df73e188d8f152b465390b0bb519a9"),
    ("src/ecckd/solve_lbfgs.cpp",
     "c10dec6bd4bdb6b3589ca0e2fa82c48886384ed8213d67c873c7040a70807f4a"),
    ("src/lbfgs/lbfgs.c",
     "2f0e2a1a8b1bb278e17691ce65d0421d518d5d05c7efc41052bd8f91633e6e3f"),
    ("test/optimize_lut_lw.sh",
     "06e7fb62a17cef5106ade44c12a54618006fe8a966402c8cf31200a2e7e6e906"),
    ("configure.ac",
     "30d590aa8240f2760f0ee68bdd34ac0b8041ba299124d00667f9cb0d4697f260")]

# working local build stack (recorded by the v1.4 checkout's config.log)
const B0_ADEPT = "/shared/home/greg/local/adept-2-install"
const B0_NETCDF = "/shared/home/greg/local/ckdmip-stack"
const B0_CONFIGURE_ARGV = "./configure --with-adept=$B0_ADEPT " *
    "--with-netcdf=$B0_NETCDF " *
    "'LDFLAGS=-L$B0_ADEPT/lib -Wl,-rpath,$B0_ADEPT/lib' 'LIBS=-ladept'"
# b42e5c0 archive carries no generated configure; autoreconf runs
# in-job with these exact pinned tool versions (drift refuses)
const B0_AUTOCONF_VER = "2.71"
const B0_AUTOMAKE_VER = "1.16.5"
const B0_LIBTOOLIZE_VER = "2.4.7"

# --- proven Netlib remedy pins (verbatim from the 4515 executor) ---------------
const B0_SHIM_SO = "$B0_G4WORK/tools/h5open_before_traps.so"
const B0_SHIM_SO_SHA = "28003281a7f1c8470c1bfd94a654999a210581261a5c3e9cd662af2a13dd492f"
const B0_NETLIB_BLAS = "/usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0"
const B0_NETLIB_BLAS_SHA = "e748efcae5753fe4a652877fccdb5895ac6f7605668a2db878b19c914e78e3a8"
const B0_NETLIB_LAPACK = "/usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0"
const B0_NETLIB_LAPACK_SHA = "851bb1fc5833ede9ed704b4417a251a899976d5e0915de40452615187a65278f"

# v1.2 testcopy source (same artifact tree 4515 staged its testcopy from);
# the four copied files are pinned by the SAME exact size+sha the 4515
# manifest pinned (directory existence is insufficient for the
# exact-config claim -- monitor correction 2)
const B0_V12_TEST_SRC = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"
const B0_V12_TEST_PINS = [
    ("f0d77b16b97612687818e85615a103adaa948627846c9819e40e7754ab0743ba",
     11792, "$B0_V12_TEST_SRC/test/optimize_lut_lw.sh"),
    ("44dcddf099d69becab1c5e6674d013d6c676685e0b8a4ae51e85a1dda33cfc69",
     6357, "$B0_V12_TEST_SRC/test/config.h"),
    ("34323fd3ecbcd64980b328eec463eedc692497ed3cdd685f2505ca4d1fdc5e2c",
     1369, "$B0_V12_TEST_SRC/test/check_configuration.h"),
    ("a5fe514dbcb656c99c11ca39d1c88eba953bda592ca35983de9c42da33dab810",
     92, "$B0_V12_TEST_SRC/test/version.h.in")]

# --- prerequisite: the REVIEWED committed run ledger (diagnosis-of-record) -----
const B0_RUN_LEDGER = validation_results_path("gate4_g3_run_ledger.json")
const B0_RUN_LEDGER_CASE = "gate4_g3_run_ledger"
const B0_RUN_LEDGER_STATUS = "reviewed-complete"
const B0_RUN_LEDGER_SHA = "6fd7791834fe1ceb184afd4623c0f95ab311685bb849cfad0837b3c6ffd4aa4e"

# --- scientific inputs: identical pins to the 4515 stage-0e manifest -----------
const B0_INPUTS = [
    ("dde735608e57af934a2c1e99932c0ccce530883ab48910c7e17b621de7fa0bee", 450863,
     "$B0_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-180.h5",
     "data/evaluation1/lw_fluxes"),
    ("b0932f2648f720af74191d2a9d62f6178f73dfb9a620b773e55670f06ce2db85", 450863,
     "$B0_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-280.h5",
     "data/evaluation1/lw_fluxes"),
    ("01836becbc96e7da2b3b33d586d148948df136457216625b7e60225e093e1792", 450863,
     "$B0_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-415.h5",
     "data/evaluation1/lw_fluxes"),
    ("c8aa819b9e7ea7ed73a0af74862ab49d4209866b74988529b2dfce0ef99710e2", 450863,
     "$B0_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-560.h5",
     "data/evaluation1/lw_fluxes"),
    ("cfbda1d66decc14e6e91e8465f32f5a5e4bcf0310a73f620fe45bafbcec9ba7c", 450873,
     "$B0_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-1120.h5",
     "data/evaluation1/lw_fluxes"),
    ("75239df6dbf578b3be6267c09995ff050f5c846be3c75492fad96dcab25610e8", 450873,
     "$B0_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-2240.h5",
     "data/evaluation1/lw_fluxes"),
    ("e799eae4421afe12481533678963237198338b3979ec938c6e61c2759522d4bc", 451045,
     "$B0_G4WORK/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5",
     "work/lw_lbl_fluxes"),
    ("ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43", 2413144,
     "$B0_G4WORK/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc",
     "work/lw_raw-ckd-definition"),
    ("c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e", 58404939,
     "$B0_G4WORK/work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5",
     "work/lw_gpoints")]

const B0_RESULTS_JSON = validation_results_path("gate4_b0_era_lbfgs_isolation_checkpoint.json")
const B0_RESULTS_MD = validation_results_path("gate4_b0_era_lbfgs_isolation_checkpoint.md")
const B0_SBATCH = validation_results_path("gate4_b0_lw_era_lbfgs.sbatch")

# --- primitives -----------------------------------------------------------------

b0_sha(path) = open(io -> bytes2hex(sha256(io)), path)
b0_try_sha(path) = try
    isfile(path) || return nothing
    b0_sha(path)
catch
    nothing
end

# coupled byte snapshot + guarded run-ledger classifier (pattern carried
# from the G3 executor's prerequisite gate; injectable readfn for
# deterministic fixtures)
function b0_snapshot(path; readfn = read)
    isfile(path) || return (ok = false, reason = "missing", sha = nothing,
                            data = nothing)
    bytes = try
        readfn(path)
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

function b0_classify_run_ledger(path; expected_case = B0_RUN_LEDGER_CASE,
                                expected_status = B0_RUN_LEDGER_STATUS,
                                expected_sha = B0_RUN_LEDGER_SHA,
                                readfn = read)
    snap = b0_snapshot(path; readfn = readfn)
    snap.ok || return (ok = false, class = snap.reason,
                       reason = "run ledger $(snap.reason)")
    c = get(snap.data, "case", nothing)
    c == expected_case || return (ok = false, class = "case mismatch",
        reason = "run ledger case mismatch (got $(repr(c)))")
    s = get(snap.data, "status", nothing)
    s == expected_status || return (ok = false, class = "status mismatch",
        reason = "run ledger status $(repr(s)) != $expected_status")
    snap.sha == expected_sha || return (ok = false, class = "sha drift",
        reason = "run ledger sha $(snap.sha) != reviewed $(expected_sha)")
    (ok = true, class = "green", reason = "")
end

# --- sbatch generation ------------------------------------------------------------

function b0_make_sbatch()
    hash_lines = join(vcat(
        ["$sha  $path" for (sha, _, path, _) in B0_INPUTS],
        ["$sha  $path" for (sha, _, path) in B0_V12_TEST_PINS]), "\n")
    size_lines = join(vcat(
        ["$sz $path" for (_, sz, path, _) in B0_INPUTS],
        ["$sz $path" for (_, sz, path) in B0_V12_TEST_PINS]), "\n")
    stage_lines = join(["$sha $sz $path \$RUNROOT/$rel/$(basename(path))"
                        for (sha, sz, path, rel) in B0_INPUTS], "\n")
    blob_lines = join(["$sha  \$SRCDIR/$path" for (path, sha) in B0_ERA_BLOBS], "\n")
    gate_pins = join(vcat(
        ["$(b0_sha(joinpath(B0_PROJECT_ROOT, f)))  $(joinpath(B0_PROJECT_ROOT, f))"
         for f in ("validation/gate4_quota_guard.sh",
                   "validation/gate4_b0_era_lbfgs_isolation_checkpoint.jl",
                   "validation/validation_results.jl")],
        ["$B0_RUN_LEDGER_SHA  $B0_RUN_LEDGER"]), "\n")
    era_banner = "Optimizing coefficients with LBFGS algorithm: " *
                 "max iterations = 3000, convergence criterion = 0.02"
    probe_banner = "Optimizing coefficients with LBFGS algorithm: " *
                   "max iterations = 1, convergence criterion = 0.02"
    raw2 = "\$RUNROOT/work/lw_raw-ckd-definition/" *
           "ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
    """
#!/bin/bash
#SBATCH --job-name=g4-b0-lw-era-lbfgs
#SBATCH --output=$B0_LOG_DIR/g4-b0-lw-%j.log
#SBATCH --time=06:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=36
#SBATCH --mem=60G
#SBATCH --partition=cpu-large

# Gate-4 B0: era-LBFGS mechanism isolation (DIAGNOSIS unit; PRIVATE
# output only). Generated by gate4_b0_era_lbfgs_isolation_checkpoint.jl.
# Same ce057079 init, same seven pinned training fluxes, exact 4515
# relative-base config; ONLY the optimizer mechanism changes to the
# pinned v1.0/b42e5c0 solve_lbfgs backend built in-job. ZERO canonical
# writes; no publish stage; RUNROOT preserved on success AND failure.
set -euo pipefail
if [ -z "\${SLURM_JOB_ID:-}" ]; then
    echo "REFUSED: head-node execution is not permitted; submit via sbatch." >&2
    exit 64
fi
case "\$SLURM_JOB_ID" in
    ''|*[!0-9]*) echo "REFUSED: SLURM_JOB_ID is not a positive integer" >&2; exit 64;;
esac

G4WORK=$B0_G4WORK
RUNROOT="\$G4WORK/g4-diag/\${SLURM_JOB_ID}/lw-b0"
SRCDIR="\$RUNROOT/src/ecckd-b42e5c0"
WRAPPER="\$RUNROOT/tools/optimize_lut_era_lbfgs"
TESTCOPY="\$RUNROOT/testcopy"
PROBECOPY="\$RUNROOT/probe-testcopy"

echo "=== B0-lw stage 0a: gate-code identity (verify BEFORE sourcing) ==="
sha256sum -c <<'GATEPINS' || { echo "REFUSED: gate code/reviewed ledger changed since generation; regenerate the checkpoint" >&2; exit 75; }
$gate_pins
GATEPINS

echo "=== B0-lw stage 0b: quota health (read-only) ==="
source $B0_PROJECT_ROOT/validation/gate4_quota_guard.sh
quota_health \$((5*1024*1024*1024)) || { echo "REFUSED: quota not healthy" >&2; exit 67; }

echo "=== B0-lw stage 0c: era-source identity (pinned commit/tree/archive; read-only on the shared repo) ==="
[ "\$(git -C $B0_ERA_REPO cat-file -t $B0_ERA_COMMIT)" = commit ] || { echo "REFUSED: era commit object missing" >&2; exit 69; }
[ "\$(git -C $B0_ERA_REPO rev-parse $B0_ERA_COMMIT^{commit})" = "$B0_ERA_COMMIT" ] || { echo "REFUSED: era commit sha mismatch" >&2; exit 69; }
[ "\$(git -C $B0_ERA_REPO rev-parse $B0_ERA_COMMIT^{tree})" = "$B0_ERA_TREE" ] || { echo "REFUSED: era tree sha mismatch" >&2; exit 69; }
AR_SHA=\$(git -C $B0_ERA_REPO archive $B0_ERA_COMMIT | sha256sum | cut -d' ' -f1)
[ "\$AR_SHA" = "$B0_ERA_ARCHIVE_SHA" ] || { echo "REFUSED: era archive sha \$AR_SHA != pinned" >&2; exit 69; }
git --version

echo "=== B0-lw stage 0d: exact size+sha pin of EVERY input + toolchain versions ==="
sha256sum -c <<'HASHES' || { echo "REFUSED: pinned input hash mismatch" >&2; exit 69; }
$hash_lines
HASHES
while read -r esz p; do
    asz=\$(stat -Lc %s "\$p") || { echo "REFUSED: cannot stat pinned input \$p" >&2; exit 69; }
    [ "\$asz" = "\$esz" ] || { echo "REFUSED: pinned input size mismatch \$p (\$asz != \$esz)" >&2; exit 69; }
done <<'SIZES'
$size_lines
SIZES
for t in autoreconf autoconf automake libtoolize gcc g++ make; do
    command -v "\$t" >/dev/null || { echo "REFUSED: build tool missing: \$t" >&2; exit 65; }
done
AC_V=\$(autoconf --version | head -1 | grep -oE '[0-9.]+\$')
AM_V=\$(automake --version | head -1 | grep -oE '[0-9.]+\$')
LT_V=\$(libtoolize --version | head -1 | grep -oE '[0-9.]+\$')
[ "\$AC_V" = "$B0_AUTOCONF_VER" ] || { echo "REFUSED: autoconf \$AC_V != pinned $B0_AUTOCONF_VER" >&2; exit 65; }
[ "\$AM_V" = "$B0_AUTOMAKE_VER" ] || { echo "REFUSED: automake \$AM_V != pinned $B0_AUTOMAKE_VER" >&2; exit 65; }
[ "\$LT_V" = "$B0_LIBTOOLIZE_VER" ] || { echo "REFUSED: libtoolize \$LT_V != pinned $B0_LIBTOOLIZE_VER" >&2; exit 65; }
gcc --version | head -1
g++ --version | head -1
test -d "$B0_V12_TEST_SRC/test" || { echo "REFUSED: v1.2 testcopy source missing" >&2; exit 68; }
test -d "$B0_ADEPT/lib" || { echo "REFUSED: adept install missing" >&2; exit 68; }
test -d "$B0_NETCDF/lib" || { echo "REFUSED: netcdf stack missing" >&2; exit 68; }

echo "=== B0-lw stage 0e: B0 experiment lock (duplicate-diagnosis guard) ==="
mkdir -p "\$G4WORK/locks"
exec 9>"\$G4WORK/locks/b0-lw.lock"
flock -n 9 || { echo "REFUSED: another B0-lw diagnosis job holds the lock" >&2; exit 73; }

echo "=== B0-lw stage 1: job-private RUNROOT + scientific-input snapshot ==="
[ ! -e "\$RUNROOT" ] || { echo "REFUSED: RUNROOT already exists: \$RUNROOT" >&2; exit 72; }
mkdir -p "\$RUNROOT/data/evaluation1/lw_fluxes" \\
         "\$RUNROOT/work/lw_lbl_fluxes" \\
         "\$RUNROOT/work/lw_raw-ckd-definition" \\
         "\$RUNROOT/work/lw_ckd-definition" \\
         "\$RUNROOT/work/lw_gpoints" \\
         "\$RUNROOT/src" "\$RUNROOT/tools"
while read -r esha esz src dst; do
    cp -L -- "\$src" "\$dst" || { echo "REFUSED: staging copy failed: \$src" >&2; exit 76; }
    asz=\$(stat -Lc %s "\$dst") || { echo "REFUSED: cannot stat staged copy \$dst" >&2; exit 76; }
    [ "\$asz" = "\$esz" ] || { echo "REFUSED: staged copy size mismatch \$dst (\$asz != \$esz)" >&2; exit 76; }
    echo "\$esha  \$dst" | sha256sum -c - >/dev/null || { echo "REFUSED: staged copy hash mismatch: \$dst" >&2; exit 76; }
done <<STAGE
$stage_lines
STAGE
echo "staged scientific-input snapshot verified under \$RUNROOT"

echo "=== B0-lw stage 2: pinned era source extraction (git archive; job-private; no worktree) ==="
mkdir -p "\$SRCDIR"
git -C $B0_ERA_REPO archive $B0_ERA_COMMIT | tar -x -C "\$SRCDIR"
sha256sum -c <<BLOBS || { echo "REFUSED: extracted era source blob mismatch" >&2; exit 69; }
$blob_lines
BLOBS

echo "=== B0-lw stage 3: era build (autoreconf + pinned configure argv; config.log preserved in RUNROOT) ==="
cd "\$SRCDIR"
autoreconf -i
$B0_CONFIGURE_ARGV
make -j"\$SLURM_CPUS_PER_TASK"
test -x "\$SRCDIR/src/ecckd/optimize_lut" || { echo "REFUSED: era optimize_lut not built" >&2; exit 68; }
# binary-level mechanism proof: era banner string present, Adept-LBFGS
# banner absent (the v1.2 mechanism string must NOT appear)
[ "\$(strings "\$SRCDIR/src/ecckd/optimize_lut" | grep -cF 'Optimizing coefficients with LBFGS algorithm' || true)" -ge 1 ] || { echo "REFUSED: era LBFGS banner string absent from binary" >&2; exit 68; }
[ "\$(strings "\$SRCDIR/src/ecckd/optimize_lut" | grep -cF 'Adept LBFGS' || true)" = 0 ] || { echo "REFUSED: Adept LBFGS string present in era binary" >&2; exit 68; }

echo "=== B0-lw stage 4: optimizer wrapper (Netlib preload + FP-trap shim; env-only) ==="
cat > "\$WRAPPER" <<WRAP
#!/bin/bash
export LD_PRELOAD="$B0_NETLIB_BLAS:$B0_NETLIB_LAPACK:$B0_SHIM_SO"
exec "\$SRCDIR/src/ecckd/optimize_lut" "\\\$@"
WRAP
chmod +x "\$WRAPPER"
sha256sum "\$WRAPPER"
sha256sum -c <<'RUNTIMEPINS' || { echo "REFUSED: runtime BLAS/LAPACK/shim pin mismatch" >&2; exit 79; }
$B0_NETLIB_BLAS_SHA  $B0_NETLIB_BLAS
$B0_NETLIB_LAPACK_SHA  $B0_NETLIB_LAPACK
$B0_SHIM_SO_SHA  $B0_SHIM_SO
RUNTIMEPINS
command -v readelf >/dev/null || { echo "MISSING readelf" >&2; exit 65; }
RE_BLAS=\$(readelf -d "$B0_NETLIB_BLAS")
RE_LAPACK=\$(readelf -d "$B0_NETLIB_LAPACK")
[ "\$(grep -cF 'Library soname: [libblas.so.3]' <<<"\$RE_BLAS" || true)" = 1 ] || { echo "REFUSED: netlib BLAS SONAME != libblas.so.3" >&2; exit 79; }
[ "\$(grep -cF 'Library soname: [liblapack.so.3]' <<<"\$RE_LAPACK" || true)" = 1 ] || { echo "REFUSED: netlib LAPACK SONAME != liblapack.so.3" >&2; exit 79; }
[ "\$(grep -cxF 'export LD_PRELOAD="$B0_NETLIB_BLAS:$B0_NETLIB_LAPACK:$B0_SHIM_SO"' "\$WRAPPER" || true)" = 1 ] || { echo "REFUSED: wrapper preload line/order drifted" >&2; exit 79; }
LDD_OUT=\$(LD_PRELOAD="$B0_NETLIB_BLAS:$B0_NETLIB_LAPACK:$B0_SHIM_SO" ldd "\$SRCDIR/src/ecckd/optimize_lut")
echo "\$LDD_OUT"
[ "\$(grep -cF "$B0_NETLIB_BLAS" <<<"\$LDD_OUT" || true)" = 1 ] || { echo "REFUSED: exact BLAS preload row count != 1" >&2; exit 79; }
[ "\$(grep -cF "$B0_NETLIB_LAPACK" <<<"\$LDD_OUT" || true)" = 1 ] || { echo "REFUSED: exact LAPACK preload row count != 1" >&2; exit 79; }
[ "\$(grep -cF 'liblapack.so.3 =>' <<<"\$LDD_OUT" || true)" = 0 ] || { echo "REFUSED: liblapack.so.3 alias row present" >&2; exit 79; }
[ "\$(grep -cF 'libblas.so.3 =>' <<<"\$LDD_OUT" || true)" = 0 ] || { echo "REFUSED: libblas.so.3 alias row present" >&2; exit 79; }
LN_B=\$(grep -nF "$B0_NETLIB_BLAS" <<<"\$LDD_OUT" | cut -d: -f1 | head -1 || true)
LN_L=\$(grep -nF "$B0_NETLIB_LAPACK" <<<"\$LDD_OUT" | cut -d: -f1 | head -1 || true)
LN_S=\$(grep -nF "$B0_SHIM_SO" <<<"\$LDD_OUT" | cut -d: -f1 | head -1 || true)
{ [ -n "\$LN_B" ] && [ -n "\$LN_L" ] && [ -n "\$LN_S" ] && [ "\$LN_B" -lt "\$LN_L" ] && [ "\$LN_L" -lt "\$LN_S" ]; } || { echo "REFUSED: preload row order is not BLAS<LAPACK<H5shim" >&2; exit 79; }

echo "=== B0-lw stage 5: isolated v1.2 testcopy (exact 4515 config overrides; era binary via wrapper) ==="
cp -r "$B0_V12_TEST_SRC/test" "\$TESTCOPY"
cd "\$TESTCOPY"
sed 's/@PACKAGE_VERSION@/1.2/g' version.h.in > version.h
sed -i \\
  -e "s|^CKDMIP_DIR=.*|CKDMIP_DIR=/shared/home/greg/build/ckdmip-1.0|" \\
  -e "s|^CKDMIP_DATA_DIR=.*|CKDMIP_DATA_DIR=\$RUNROOT/data|" \\
  -e "s|^WORK_DIR=.*|WORK_DIR=\$RUNROOT/work|" \\
  -e "s|^BINDIR=.*|BINDIR=\$SRCDIR/src/ecckd|" \\
  -e "s|^TRAINING_BOTH=no\$|TRAINING_BOTH=yes|" \\
  -e "s|^OPTIMIZE_LUT=.*|OPTIMIZE_LUT=\$WRAPPER|" \\
  config.h
grep -E "^(CKDMIP_DIR|CKDMIP_DATA_DIR|WORK_DIR|BINDIR|TRAINING_BOTH|OPTIMIZE_LUT)=" config.h
for kv in "CKDMIP_DIR=/shared/home/greg/build/ckdmip-1.0" "CKDMIP_DATA_DIR=\$RUNROOT/data" "WORK_DIR=\$RUNROOT/work" "BINDIR=\$SRCDIR/src/ecckd" "TRAINING_BOTH=yes" "OPTIMIZE_LUT=\$WRAPPER"; do
    grep -qxF "\$kv" config.h || { echo "BAD config override: \$kv" >&2; exit 68; }
done
sed -i 's|^[[:space:]]*test "\\\${PIPESTATUS\\[0\\]}" -eq 0[[:space:]]*\$|\\trc="\${PIPESTATUS[0]}"; if [ "\$rc" -ne 0 ]; then if [ "\$rc" -ge 128 ]; then echo "OPTIMIZE_LUT CHILD KILLED BY SIGNAL \$((rc-128)) (rc=\$rc)" >\\&2; else echo "OPTIMIZE_LUT CHILD FAILED rc=\$rc" >\\&2; fi; exit "\$rc"; fi|' optimize_lut_lw.sh
grep -q "OPTIMIZE_LUT CHILD" optimize_lut_lw.sh || { echo "BAD sed: child-status surfacing not applied" >&2; exit 68; }
grep -qF 'test "\${PIPESTATUS[0]}" -eq 0' optimize_lut_lw.sh && { echo "BAD sed: raw PIPESTATUS test remains" >&2; exit 68; } || true

echo "=== B0-lw stage 5b: controlled schema-open probe (max_iterations=1; REFUSES rather than strips) ==="
cp -r "\$TESTCOPY" "\$PROBECOPY"
cd "\$PROBECOPY"
mkdir -p "\$RUNROOT/probe-work/lw_raw-ckd-definition" "\$RUNROOT/probe-work/lw_lbl_fluxes" "\$RUNROOT/probe-work/lw_ckd-definition" "\$RUNROOT/probe-work/lw_gpoints"
# every probe-work copy re-verified against the SAME pinned sha
# (monitor correction 1: the g-point file is REQUIRED in probe-work,
# not just in the real work tree)
cp -L -- "\$RUNROOT/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc" "\$RUNROOT/probe-work/lw_raw-ckd-definition/"
cp -L -- "\$RUNROOT/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5" "\$RUNROOT/probe-work/lw_lbl_fluxes/"
cp -L -- "\$RUNROOT/work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5" "\$RUNROOT/probe-work/lw_gpoints/"
sha256sum -c <<PROBEPINS || { echo "REFUSED: probe-work copy hash mismatch" >&2; exit 76; }
ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43  \$RUNROOT/probe-work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc
e799eae4421afe12481533678963237198338b3979ec938c6e61c2759522d4bc  \$RUNROOT/probe-work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5
c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e  \$RUNROOT/probe-work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5
PROBEPINS
sed -i "s|^WORK_DIR=.*|WORK_DIR=\$RUNROOT/probe-work|" config.h
grep -qxF "WORK_DIR=\$RUNROOT/probe-work" config.h || { echo "BAD probe WORK_DIR override" >&2; exit 68; }
sed -i 's|^COMMON_OPTIONS="prior_error=8.0 |COMMON_OPTIONS="max_iterations=1 prior_error=8.0 |' optimize_lut_lw.sh
[ "\$(grep -cE '^COMMON_OPTIONS="max_iterations=1 prior_error=8.0 ' optimize_lut_lw.sh || true)" = 1 ] || { echo "BAD probe max_iterations sed" >&2; exit 68; }
set +e
APPLICATION=climate BAND_STRUCTURE=fsck TOLERANCE=0.0161 \\
    bash optimize_lut_lw.sh relative-base |& tee "\$RUNROOT/probe-run.log"
PROBE_RC=\${PIPESTATUS[0]}
set -e
[ "\$PROBE_RC" = 0 ] || { echo "REFUSED: schema-open probe failed rc=\$PROBE_RC (old reader may reject the v1.2 init; NO stripping without monitor review; probe log preserved)" >&2; exit 71; }
[ "\$(grep -cF '$probe_banner' "\$RUNROOT/probe-run.log" || true)" = 1 ] || { echo "REFUSED: probe did not show exactly one era banner with max iterations = 1" >&2; exit 71; }
test -s "\$RUNROOT/probe-work/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc" || { echo "REFUSED: probe produced no raw2 output" >&2; exit 71; }
echo "schema-open probe PASSED: old reader accepted the v1.2 init with min/max arrays present (no strip needed)"

echo "=== B0-lw stage 6: era relative-base run (3000 iterations / 0.02 criterion; all writes under RUNROOT) ==="
cd "\$TESTCOPY"
APPLICATION=climate BAND_STRUCTURE=fsck TOLERANCE=0.0161 \\
    bash optimize_lut_lw.sh relative-base |& tee "\$RUNROOT/b0-base-run.log"
[ "\$(grep -cF '$era_banner' "\$RUNROOT/b0-base-run.log" || true)" = 1 ] || { echo "REFUSED: era run did not show exactly one era banner (3000/0.02)" >&2; exit 71; }
[ "\$(grep -cF 'Adept LBFGS' "\$RUNROOT/b0-base-run.log" || true)" = 0 ] || { echo "REFUSED: Adept LBFGS banner appeared in era run" >&2; exit 71; }
[ "\$(grep -cF 'Optimizing coefficients of: composite h2o o3 co2' "\$RUNROOT/b0-base-run.log" || true)" = 1 ] || { echo "REFUSED: base gas banner not exactly once" >&2; exit 71; }

echo "=== B0-lw stage 7: private outputs (independent schema verification; ZERO canonical writes by design) ==="
test -s "$raw2" || { echo "MISSING B0 raw2 output" >&2; exit 71; }
# independent netCDF readability + core schema + ALL-numeric-variable
# finite verification through the test Julia environment (monitor
# correction 4: test -s alone is insufficient)
(cd $B0_PROJECT_ROOT && RAW2_PATH="$raw2" julia --project=test -e '
using NCDatasets
bad = String[]
NCDataset(ENV["RAW2_PATH"]) do ds
    for (d, v) in (("g_point", 32), ("pressure", 53), ("temperature", 6),
                   ("composite_gas", 4), ("h2o_mole_fraction", 12), ("band", 1))
        (haskey(ds.dim, d) && ds.dim[d] == v) ||
            push!(bad, "dim " * d * " != " * string(v))
    end
    req = vcat([g * "_molar_absorption_coeff" for g in
                ("cfc11", "cfc12", "ch4", "co2", "composite", "h2o",
                 "n2o", "o3")],
               ["planck_function", "gpoint_fraction", "band_number",
                "wavenumber1_band", "wavenumber2_band", "wavenumber1",
                "wavenumber2"])
    for v in req
        haskey(ds, v) || push!(bad, "required var missing: " * v)
        haskey(ds, v) && length(ds[v]) == 0 &&
            push!(bad, "required var empty: " * v)
    end
    for k in keys(ds)
        a = try
            Array(ds[k])
        catch
            push!(bad, "unreadable var " * String(k))
            continue
        end
        eltype(a) <: Union{Missing, Real} || continue
        (!any(ismissing, a) && all(isfinite, skipmissing(a))) ||
            push!(bad, "nonfinite/missing values in " * String(k))
    end
end
isempty(bad) || (foreach(println, bad); exit(1))
println("raw2 independent schema/finite verification passed")
') || { echo "REFUSED: B0 raw2 failed independent netCDF schema/finite verification" >&2; exit 71; }
sha256sum "$raw2"
sha256sum "\$RUNROOT/probe-run.log" "\$RUNROOT/b0-base-run.log"
echo "RUNROOT preserved for diagnosis/forensics: \$RUNROOT (no cleanup by design)"
echo "=== B0-lw done \$(date -u +%FT%TZ) ==="
"""
end

# --- text gates (computed FROM the generated script text) --------------------------

# fail-closed bash syntax gate on the exact generated text (monitor
# correction 3); any write/exec failure classifies as NOT ok
function b0_bash_syntax_ok(text)
    try
        p = joinpath(mktempdir(), "b0_syntax_check.sbatch")
        write(p, text)
        success(pipeline(`bash -n $p`, stdout = devnull, stderr = devnull))
    catch
        false
    end
end

function b0_text_gate_issues(text)
    iss = String[]
    req = [
        "REFUSED: head-node execution is not permitted",
        "RUNROOT=\"\$G4WORK/g4-diag/\${SLURM_JOB_ID}/lw-b0\"",
        "git -C $B0_ERA_REPO archive $B0_ERA_COMMIT | tar -x -C \"\$SRCDIR\"",
        B0_ERA_COMMIT, B0_ERA_TREE, B0_ERA_ARCHIVE_SHA,
        "autoreconf -i",
        "--with-adept=$B0_ADEPT",
        "--with-netcdf=$B0_NETCDF",
        "export LD_PRELOAD=\"$B0_NETLIB_BLAS:$B0_NETLIB_LAPACK:$B0_SHIM_SO\"",
        "max_iterations=1 prior_error=8.0",
        "bash optimize_lut_lw.sh relative-base",
        "TRAINING_BOTH=yes",
        "APPLICATION=climate BAND_STRUCTURE=fsck TOLERANCE=0.0161",
        "RUNROOT preserved for diagnosis/forensics",
        # monitor corrections 1/4 + duplicate-diagnosis flock
        "flock -n 9",
        "probe-work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5",
        "raw2 independent schema/finite verification passed",
        "RAW2_PATH=\"\$RUNROOT/work/lw_raw-ckd-definition/" *
            "ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc\" " *
            "julia --project=test"]
    for r in req
        occursin(r, text) || push!(iss, "required text missing: $r")
    end
    # single-pass only: the two real+probe invocations, never the later
    # relative passes and never any canonical publish machinery
    n = length(collect(eachmatch(r"bash optimize_lut_lw\.sh relative-base", text)))
    n == 2 || push!(iss, "expected exactly 2 relative-base invocations (probe+run), got $n")
    for bad in ("relative-ch4", "relative-n2o", "relative-cfc",
                "CANON_FINAL", "mv -n", ".g3.publish.",
                "$B0_G4WORK/work/lw_ckd-definition/ecckd-1.2_lw_ckd-definition")
        occursin(bad, text) && push!(iss, "forbidden text present: $bad")
    end
    # the ONLY $G4WORK writes allowed are under \$RUNROOT (g4-diag) plus
    # the single duplicate-diagnosis lock file; the canonical
    # init/eval2/gpoints paths appear ONLY as pinned read sources in
    # HASHES/SIZES/STAGE blocks (cp -L sources)
    for m in eachmatch(r"(?m)^[^#\n]*> *\"?\$G4WORK/(?!g4-diag|locks/b0-lw\.lock)", text)
        push!(iss, "redirect toward shared G4WORK area: $(m.match)")
    end
    iss
end

# --- fixtures ----------------------------------------------------------------------

function b0_fixtures()
    t = Dict{String, Bool}()
    fx = mktempdir()
    shaof(p) = bytes2hex(sha256(read(p)))

    cls(p; kw...) = b0_classify_run_ledger(p; kw...)
    t["ledger_missing_refuses"] =
        cls(joinpath(fx, "absent.json")).class == "missing"
    p = joinpath(fx, "bad.json"); write(p, "{oops")
    t["ledger_unparseable_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "unparseable (parse failure)"
    p = joinpath(fx, "arr.json"); write(p, "[]")
    t["ledger_non_object_refuses"] =
        cls(p; expected_sha = shaof(p)).class ==
        "parses to a non-object (JSON null/array/scalar)"
    p = joinpath(fx, "case.json")
    write(p, JSON.json(Dict("case" => "x", "status" => B0_RUN_LEDGER_STATUS)))
    t["ledger_case_mismatch_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "case mismatch"
    p = joinpath(fx, "st.json")
    write(p, JSON.json(Dict("case" => B0_RUN_LEDGER_CASE,
                            "status" => "g3_run_ledger_refused")))
    t["ledger_status_mismatch_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "status mismatch"
    p = joinpath(fx, "green.json")
    write(p, JSON.json(Dict("case" => B0_RUN_LEDGER_CASE,
                            "status" => B0_RUN_LEDGER_STATUS)))
    t["ledger_sha_drift_refuses"] =
        cls(p; expected_sha = "0" ^ 64).class == "sha drift"
    t["ledger_green_accepted"] = cls(p; expected_sha = shaof(p)).ok
    t["ledger_unreadable_refuses"] =
        cls(p; expected_sha = shaof(p),
            readfn = _ -> error("io")).class == "unreadable"

    # text gates: generated text passes; controlled mutations refuse
    text = b0_make_sbatch()
    t["text_good_accepted"] = isempty(b0_text_gate_issues(text))
    t["text_missing_probe_refuses"] = !isempty(b0_text_gate_issues(
        replace(text, "max_iterations=1 prior_error=8.0" => "prior_error=8.0")))
    t["text_extra_pass_refuses"] = !isempty(b0_text_gate_issues(
        replace(text, "bash optimize_lut_lw.sh relative-base |& tee \"\$RUNROOT/b0-base-run.log\"" =>
                      "bash optimize_lut_lw.sh relative-base relative-ch4 |& tee \"\$RUNROOT/b0-base-run.log\"")))
    t["text_publish_machinery_refuses"] = !isempty(b0_text_gate_issues(
        text * "\nmv -n -- x \$CANON_FINAL\n"))
    t["text_shared_redirect_refuses"] = !isempty(b0_text_gate_issues(
        text * "\necho x > \"\$G4WORK/work/evil.txt\"\n"))
    t["text_foreign_lock_redirect_refuses"] = !isempty(b0_text_gate_issues(
        text * "\nexec 8>\"\$G4WORK/locks/other.lock\"\n"))
    t["text_wrong_commit_refuses"] = !isempty(b0_text_gate_issues(
        replace(text, B0_ERA_COMMIT => "f" ^ 40)))
    t["text_missing_flock_refuses"] = !isempty(b0_text_gate_issues(
        replace(text, "flock -n 9" => "true")))
    t["text_missing_probe_gpoints_refuses"] = !isempty(b0_text_gate_issues(
        replace(text,
            "probe-work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5"
            => "probe-work/lw_gpoints/other.h5")))
    # bash -n syntax gate: exact generated text passes; a broken
    # mutation (unterminated if) refuses
    t["bash_syntax_good_accepted"] = b0_bash_syntax_ok(text)
    t["bash_syntax_broken_refuses"] =
        !b0_bash_syntax_ok(text * "\nif true; then\n")
    t
end

# --- main --------------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()

    tests = b0_fixtures()
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    groups = Dict{String, Vector{String}}()

    led = b0_classify_run_ledger(B0_RUN_LEDGER)
    groups["reviewed_run_ledger"] = led.ok ? String[] : [led.reason]

    era = String[]
    treearg = B0_ERA_COMMIT * "^{tree}"
    try
        strip(read(`git -C $B0_ERA_REPO cat-file -t $B0_ERA_COMMIT`, String)) == "commit" ||
            push!(era, "era commit object missing/not a commit")
        strip(read(`git -C $B0_ERA_REPO rev-parse $treearg`, String)) == B0_ERA_TREE ||
            push!(era, "era tree sha mismatch")
        ar = read(pipeline(`git -C $B0_ERA_REPO archive $B0_ERA_COMMIT`))
        bytes2hex(sha256(ar)) == B0_ERA_ARCHIVE_SHA ||
            push!(era, "era archive sha mismatch")
        for (path, sha) in B0_ERA_BLOBS
            blob = read(pipeline(`git -C $B0_ERA_REPO show $B0_ERA_COMMIT:$path`))
            bytes2hex(sha256(blob)) == sha ||
                push!(era, "era blob sha mismatch: $path")
        end
    catch err
        push!(era, "era repo inspection failed: $(sprint(showerror, err))")
    end
    groups["era_source_pins"] = era

    inp = String[]
    for (sha, sz, path, _) in B0_INPUTS
        isfile(path) || (push!(inp, "missing: $path"); continue)
        filesize(path) == sz || push!(inp, "size drift: $path")
        b0_try_sha(path) == sha || push!(inp, "sha drift: $path")
    end
    groups["input_pins"] = inp

    rt = String[]
    for (path, sha, label) in ((B0_NETLIB_BLAS, B0_NETLIB_BLAS_SHA, "netlib blas"),
                               (B0_NETLIB_LAPACK, B0_NETLIB_LAPACK_SHA, "netlib lapack"),
                               (B0_SHIM_SO, B0_SHIM_SO_SHA, "h5 shim"))
        b0_try_sha(path) == sha || push!(rt, "$label pin mismatch: $path")
    end
    isdir(joinpath(B0_V12_TEST_SRC, "test")) ||
        push!(rt, "v1.2 testcopy source missing")
    for (sha, sz, path) in B0_V12_TEST_PINS
        isfile(path) || (push!(rt, "testcopy file missing: $path"); continue)
        filesize(path) == sz || push!(rt, "testcopy size drift: $path")
        b0_try_sha(path) == sha || push!(rt, "testcopy sha drift: $path")
    end
    isdir(joinpath(B0_ADEPT, "lib")) || push!(rt, "adept install missing")
    isdir(joinpath(B0_NETCDF, "lib")) || push!(rt, "netcdf stack missing")
    groups["runtime_and_build_stack"] = rt

    text = b0_make_sbatch()
    groups["sbatch_text_gates"] = b0_text_gate_issues(text)
    groups["sbatch_bash_syntax"] = b0_bash_syntax_ok(text) ? String[] :
        ["generated sbatch fails bash -n syntax verification"]

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end

    ready = gates["fixtures"] == "passed" && all(isempty, values(groups))
    status = ready ? "b0_checkpoint_ready" : "b0_checkpoint_refused"

    if ready
        mkpath(dirname(B0_SBATCH))
        write(B0_SBATCH, text)
    end
    sb_sha = ready ? b0_sha(B0_SBATCH) : nothing

    result = Dict(
        "case" => "gate4_b0_era_lbfgs_isolation_checkpoint",
        "data_mode" => "generator_checkpoint",
        "status" => status,
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "sbatch_path" => B0_SBATCH,
        "sbatch_sha256" => sb_sha,
        "era" => Dict(
            "repo" => B0_ERA_REPO, "commit" => B0_ERA_COMMIT,
            "tree" => B0_ERA_TREE, "archive_sha256" => B0_ERA_ARCHIVE_SHA,
            "blobs" => [Dict("path" => p, "sha256" => s)
                        for (p, s) in B0_ERA_BLOBS],
            "configure_argv" => B0_CONFIGURE_ARGV,
            "autotools" => Dict("autoconf" => B0_AUTOCONF_VER,
                                "automake" => B0_AUTOMAKE_VER,
                                "libtoolize" => B0_LIBTOOLIZE_VER)),
        "prerequisite" => Dict(
            "run_ledger" => B0_RUN_LEDGER,
            "reviewed_sha256" => B0_RUN_LEDGER_SHA,
            "required_case" => B0_RUN_LEDGER_CASE,
            "required_status" => B0_RUN_LEDGER_STATUS),
        "inputs" => [Dict("sha256" => sha, "size" => sz, "path" => path,
                          "staged_rel" => rel)
                     for (sha, sz, path, rel) in B0_INPUTS],
        # causal to the exact-4515-config claim: the v1.2 testcopy root
        # and the four copied files verified at generation AND in-job
        "v12_testcopy" => Dict(
            "root" => B0_V12_TEST_SRC,
            "pins" => [Dict("sha256" => sha, "size" => sz, "path" => path)
                       for (sha, sz, path) in B0_V12_TEST_PINS]),
        "design_note" => "B0 mechanism isolation: same ce057079 init " *
            "(min/max arrays retained; controlled max_iterations=1 " *
            "schema-open probe REFUSES rather than strips), same seven " *
            "pinned training fluxes, exact 4515 relative-base config; " *
            "ONLY the optimizer mechanism changes to the pinned " *
            "v1.0/b42e5c0 solve_lbfgs backend built in-job. PRIVATE " *
            "output under g4-diag; zero canonical writes; submission " *
            "HELD for monitor review.",
        "non_authorizing_note" => "this checkpoint generates and " *
            "verifies the B0 sbatch; it never submits; submission " *
            "requires explicit monitor GO.",
        "disclaimer" => "generator checkpoint; writes nothing except " *
            "its own JSON/MD results and the generated sbatch.")

    mkpath(dirname(B0_RESULTS_JSON))
    open(B0_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(B0_RESULTS_MD, "w") do io
        println(io, "# Gate-4 B0 era-LBFGS isolation checkpoint\n")
        println(io, "Status: **$status**\n")
        println(io, result["design_note"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nEra pins: commit `$(B0_ERA_COMMIT)` tree " *
                    "`$(B0_ERA_TREE)` archive `$(B0_ERA_ARCHIVE_SHA)`")
        println(io, "\nGenerated sbatch: `$(B0_SBATCH)`" *
                    (sb_sha === nothing ? " (NOT written; refused)" :
                     " sha256 `$sb_sha`"))
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_b0_era_lbfgs_isolation_checkpoint: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return ready ? 0 : 1
end

exit(main())
