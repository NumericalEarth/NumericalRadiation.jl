# Gate-4 G3 EXECUTOR checkpoint (dry-run generation; NO submission, NO
# execution). Generates the two staged-optimizer sbatch scripts (LW, SW)
# for the recovery run, wired per the verbatim optimizer spec and the
# scoped actual-input preflight. Submission requires review/go -- this
# unit only writes artifacts.
#
# 2026-08-13 monitor-directed fail-closed revision: READY is the ONLY
# generation state. The immutable committed preflight artifact is
# consumed by coupled-byte snapshot (exact case gate4_g3_scoped_input_
# preflight, exact status g3_scoped_preflight_ready, exact byte sha
# f5b7e171...), with the preflight SOURCE sha and reviewed-commit
# ancestry pinned; every other observation -- including the former
# waiting-for-eval2 token -- refuses with a stable class and a nonzero
# exit. Stage-0e in the generated scripts pins EVERY scientific input
# the optimizer actually reads (exact size AND sha: per-band E1 training
# fluxes, eval2 TRAINING_BOTH file, init, gpoints, binary, FP shim,
# copied source files), the runtime no-write preflight preserves full
# diagnostics (combined output+exit captured without set-e interference,
# echoed to the Slurm log, rc=0 plus exactly one exact ready line), the
# workspace is job-private (validated numeric SLURM_JOB_ID; no
# unconditional rm -rf of a shared fixed path; preserved for forensics),
# and ALL config overrides are asserted exactly after sed.
#
# Wiring (all monitor-reviewed evidence):
#   LW: pinned v1.2 test scripts + v1.2 binary; WORK_DIR=work (accepted
#       raw init ce057079..., gpoints c96e6492..., eval2 LW flux installed
#       there by G2d); ECCKD_PREFIX=ecckd-1.2 via version.h; passes
#       relative-base relative-ch4 relative-n2o relative-cfc (CLI args);
#       chain raw->raw2->raw3->raw4->ckd.
#   SW: v1.4 tree test scripts (byte-identical to pinned v1.2 for
#       optimize_lut_sw.sh -- verified by diff) + v1.4 binary; WORK_DIR=
#       work-v14 (accepted scaled init 74d8be65..., gpoints symlink ->
#       1.2 candidate 13dd686a..., eval2 SW rgb flux dual-installed there
#       by G2d); ECCKD_PREFIX=ecckd-1.4; passes relative-base relative-ch4
#       relative-n2o; chain scaled->raw2->raw3->ckd.
#   TRAINING_BOTH=yes sed (config.h:71 default no) appends the eval2
#       rel-415 file to the relative-base pass, both bands = the faithful
#       '-32b' training set.
#   optimize_lut enables FP traps (optimize_lut.cpp:51) -> each sbatch
#       generates an OPTIMIZER-SPECIFIC wrapper (LD_PRELOAD the hash-pinned
#       4099 H5open-preinit .so, exec the band's pinned binary) and seds
#       OPTIMIZE_LUT= in the testcopy config to that wrapper.
#
# ACCEPTANCE METRICS (evaluated by SEPARATE post-run runners, never
# inside the executor) -- the FIVE canonical thresholds: (1) final/target
# objective ratio <= 1.05; (2) weight rel-L1 <= 0.02; (3) true OD
# log-RMSE <= 0.02; (4) forcing regression margin <= 0.03 W/m2; (5)
# heating-RMSE regression margin <= 0.005 K/day (see
# gate4_regression_margin_semantics_evidence.md for pending rulings).

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON
import SHA

const ECCKD_SRC = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"
const V14_TREE = "/shared/home/greg/ecckd-derived-flux-work/ecckd-v1.4-23adaca"
const V12_SRCDIR = "/shared/home/greg/ecckd-derived-flux-work/ecckd/src/ecckd"
const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"
const CKDMIP_BIN_ROOT = "/shared/home/greg/build/ckdmip-1.0"
const SHIM_SO = "$G4WORK/tools/h5open_before_traps.so"
const SHIM_SO_SHA = "28003281a7f1c8470c1bfd94a654999a210581261a5c3e9cd662af2a13dd492f"
# exact-version Netlib runtime libraries (4505/4506 SIGFPE remedy, per
# gate4_g3_failure_ledger_4505_4506: ATLAS raises spurious FP flags
# under the compiled-in feenableexcept traps at the first LAPACK call;
# the monitor's bounded probes validated this exact preload-only route)
const NETLIB_BLAS = "/usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0"
const NETLIB_BLAS_SHA = "e748efcae5753fe4a652877fccdb5895ac6f7605668a2db878b19c914e78e3a8"
const NETLIB_BLAS_BYTES = 677880
const NETLIB_LAPACK = "/usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0"
const NETLIB_LAPACK_SHA = "851bb1fc5833ede9ed704b4417a251a899976d5e0915de40452615187a65278f"
const NETLIB_LAPACK_BYTES = 7268368
# the committed 4505/4506 failure-ledger artifact (diagnosis of record):
# bound by exact reviewed sha -- identity supplies case/status/content
# without a new JSON parse edge; drift refuses generation AND refuses
# in-job via GATEPINS, so submitted scripts bind the diagnosis too
const FAILURE_LEDGER_JSON = validation_results_path("gate4_g3_failure_ledger_4505_4506.json")
const FAILURE_LEDGER_SHA = "7e54b22a87e057bbb99b4c9f7922bcb25530573cfb6c415de0eddeee0f411c53"
const LW_INIT_SHA = "ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43"
const SW_INIT_SHA = "74d8be65226f081f3d2882520ab374ed102d73cc3dd43bb2fa7c5a5c27602d74"
const V12_BIN_SHA = "6c3600fe6001d92e0d067cde1d57f19c82bae0c208a32dd2c48cd77031c05692"
const V14_BIN_SHA = "101e41ed77c83c81c138494a2b950bbffd12caad27b0c64028666550d7c30d65"

# repo root derived from THIS source (checkout directory names are
# transient and must never be bound into evidence)
const PROJECT_ROOT = dirname(@__DIR__)
sha256(p) = split(strip(read(`sha256sum $p`, String)))[1]

# immutable prerequisite pins (monitor contract, 2026-08-13)
const GX_PF_JSON = validation_results_path("gate4_g3_scoped_input_preflight.json")
const GX_PF_CASE = "gate4_g3_scoped_input_preflight"
const GX_PF_STATUS = "g3_scoped_preflight_ready"
const GX_PF_SHA = "f5b7e1714b107a7307842389ea3bdfbbd1bb0111f9509cafcdee464327955f0b"
const GX_PF_SRC = joinpath(PROJECT_ROOT, "validation/gate4_g3_scoped_input_preflight.jl")
const GX_PF_SRC_SHA = "d06d1608152303cbf6bf73794447bbf59cf8deb40a5baf26a0231984cf93fc71"
const GX_ANCESTOR = "e4bb81dee34a226ef0c007b7ad8f84ad9993aa6c"

# per-band scientific training sets (mirrors the preflight's pinned
# lists; the preflight itself gates drift vs the pinned scripts)
const CO2 = ["180", "280", "415", "560", "1120", "2240"]
const LW_TRAIN = vcat(["rel-$c" for c in CO2],
    ["present", "ch4-350", "ch4-700", "ch4-1200", "ch4-2600", "ch4-3500",
     "n2o-190", "n2o-270", "n2o-405", "n2o-540",
     "cfc11-0", "cfc11-2000", "cfc12-0", "cfc12-550"])
const SW_TRAIN = vcat(["rel-$c" for c in CO2],
    ["present", "ch4-350", "ch4-700", "ch4-1200", "ch4-2600", "ch4-3500",
     "n2o-190", "n2o-270", "n2o-405", "n2o-540"])

const GX_RESULTS_JSON = validation_results_path("gate4_g3_executor_checkpoint.json")
const GX_RESULTS_MD = validation_results_path("gate4_g3_executor_checkpoint.md")
const GX_SBATCH_LW = validation_results_path("gate4_g3_lw_optimizer.sbatch")
const GX_SBATCH_SW = validation_results_path("gate4_g3_sw_optimizer.sbatch")

# The future submit entrypoint. This checkpoint NEVER calls it.
function submit_g3(; authorize::Symbol = :refused)
    authorize === :g3_recovery_go ||
        error("submit_g3 refused: requires authorize=:g3_recovery_go " *
              "(explicit go after this checkpoint is reviewed)")
    error("not implemented in the checkpoint: submission is a human sbatch " *
          "command per the runbook sequence")
end

# --- guarded prerequisite (coupled byte snapshot; READY is the only
# --- accepted state; injectable readfn for deterministic fixtures) -----------

function gx_snapshot(path; readfn = read)
    isfile(path) || return (ok = false, reason = "missing", sha = nothing,
                            data = nothing)
    bytes = try
        readfn(path)
    catch
        return (ok = false, reason = "unreadable", sha = nothing,
                data = nothing)
    end
    sha = bytes2hex(SHA.sha256(bytes))
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

# exact case bound BEFORE status; exact status; exact byte sha. Every
# refusal carries a stable class; observed evidence comes from the SAME
# snapshot read.
function gx_classify_scoped_preflight(path; expected_case = GX_PF_CASE,
                                      expected_status = GX_PF_STATUS,
                                      expected_sha = GX_PF_SHA,
                                      readfn = read)
    snap = gx_snapshot(path; readfn)
    obs_case = snap.data === nothing ? nothing : get(snap.data, "case", nothing)
    obs_status = snap.data === nothing ? nothing : get(snap.data, "status", nothing)
    base = (observed_sha = snap.sha, observed_case = obs_case,
            observed_status = obs_status)
    snap.ok || return merge((ok = false, class = snap.reason,
        reason = "scoped preflight artifact $(snap.reason)"), base)
    obs_case == expected_case || return merge((ok = false,
        class = "case mismatch",
        reason = "scoped preflight case mismatch: $(repr(obs_case))"), base)
    obs_status == expected_status || return merge((ok = false,
        class = "status mismatch",
        reason = "scoped preflight status $(repr(obs_status)) != " *
                 "$expected_status (READY is the only generation state)"),
        base)
    snap.sha == expected_sha || return merge((ok = false, class = "sha drift",
        reason = "scoped preflight sha $(snap.sha) != pinned"), base)
    merge((ok = true, class = "green", reason = ""), base)
end

# READY is the ONLY generation state (fail-closed allowlist of one)
gx_should_generate(pf_state) = pf_state == "ready"
function gx_generate_scripts(genfn, pf_state)
    gx_should_generate(pf_state) || return nothing
    return Dict("lw" => genfn("lw"), "sw" => genfn("sw"))
end

# --- deterministic per-band scientific-input manifest -------------------------

function gx_band_params(band)
    lw = band == "lw"
    (lw = lw,
     srcdir = lw ? ECCKD_SRC : V14_TREE,
     ver = lw ? "1.2" : "1.4",
     bindir = lw ? V12_SRCDIR : "$V14_TREE/src/ecckd",
     workdir = lw ? "$G4WORK/work" : "$G4WORK/work-v14",
     initfile = lw ?
        "$G4WORK/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc" :
        "$G4WORK/work-v14/sw_raw-ckd-definition/ecckd-1.4_sw_scaled-ckd-definition_climate_rgb-tol0.047.nc",
     gpoints = lw ?
        "$G4WORK/work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5" :
        "$G4WORK/work-v14/sw_gpoints/ecckd-1.4_sw_gpoints_climate_rgb-tol0.047.h5",
     eval2 = lw ?
        "$G4WORK/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5" :
        "$G4WORK/work-v14/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5",
     script = lw ? "optimize_lut_lw.sh" : "optimize_lut_sw.sh")
end

# (path, size, sha, role) for EVERY scientific input the optimizer
# actually reads, plus binary/shim and the copied source files. Sizes
# and shas FOLLOW symlinks (the SW gpoints entry pins target content).
function gx_input_manifest(band)
    p = gx_band_params(band)
    ent(path, role) = Dict("path" => path, "size" => Int(filesize(path)),
                           "sha256" => sha256(path), "role" => role)
    entries = Any[]
    for s in (p.lw ? LW_TRAIN : SW_TRAIN)
        fp = joinpath(CKDMIP_ROOT, p.lw ?
            "evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_$s.h5" :
            "evaluation1/sw_fluxes-rgb/ckdmip_evaluation1_sw_fluxes-rgb_$s.h5")
        push!(entries, ent(fp, "training_flux"))
    end
    push!(entries, ent(p.eval2, "eval2_training_flux"))
    push!(entries, ent(p.initfile, "init"))
    push!(entries, ent(p.gpoints, "gpoints"))
    push!(entries, ent(joinpath(p.bindir, "optimize_lut"), "optimizer_binary"))
    push!(entries, ent(SHIM_SO, "fp_shim"))
    push!(entries, ent(NETLIB_BLAS, "runtime_blas"))
    push!(entries, ent(NETLIB_LAPACK, "runtime_lapack"))
    for f in (p.script, "config.h", "check_configuration.h", "version.h.in")
        push!(entries, ent(joinpath(p.srcdir, "test", f), "copied_source"))
    end
    entries
end

# staged destination (relative to \$RUNROOT at runtime) for each staged
# scientific-input role; binary/shim/copied sources are used from their
# pinned originals and are not staged
function gx_staged_rel(band, role, basename_)
    role == "training_flux" &&
        return "data/evaluation1/$(band == "lw" ? "lw_fluxes" : "sw_fluxes-rgb")/$basename_"
    role == "eval2_training_flux" &&
        return "work/$(band)_lbl_fluxes/$basename_"
    role == "init" &&
        return "work/$(band)_raw-ckd-definition/$basename_"
    role == "gpoints" && return "work/$(band)_gpoints/$basename_"
    nothing
end

function make_sbatch(band)
    p = gx_band_params(band)
    manifest = gx_input_manifest(band)
    vv = replace(p.ver, "." => "")
    bandstruct = p.lw ? "fsck" : "rgb"
    tol = p.lw ? "0.0161" : "0.047"
    modes = p.lw ? "relative-base relative-ch4 relative-n2o relative-cfc" :
                   "relative-base relative-ch4 relative-n2o"
    # canonical FINAL output (the ONLY canonical write of the whole job);
    # every intermediate lives under the job-private RUNROOT
    final_ckd = p.lw ?
        "$(p.workdir)/lw_ckd-definition/ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc" :
        "$(p.workdir)/sw_ckd-definition/ecckd-1.4_sw_ckd-definition_climate_rgb-tol0.047.nc"
    fb = basename(final_ckd)
    staged_final = "\$RUNROOT/work/$(band)_ckd-definition/$fb"
    staged_outputs = p.lw ?
        ["\$RUNROOT/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
         "\$RUNROOT/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw3-ckd-definition_climate_fsck-tol0.0161.nc",
         "\$RUNROOT/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw4-ckd-definition_climate_fsck-tol0.0161.nc",
         staged_final] :
        ["\$RUNROOT/work/sw_raw-ckd-definition/ecckd-1.4_sw_raw2-ckd-definition_climate_rgb-tol0.047.nc",
         "\$RUNROOT/work/sw_raw-ckd-definition/ecckd-1.4_sw_raw3-ckd-definition_climate_rgb-tol0.047.nc",
         staged_final]
    # EVERY scientific input pinned: sha lines + size lines from the SAME
    # deterministic manifest embedded in the checkpoint JSON
    hash_lines = join(["$(e["sha256"])  $(e["path"])" for e in manifest], "\n")
    size_lines = join(["$(e["size"]) $(e["path"])" for e in manifest], "\n")
    # staging table: sha size src dst (dst under \$RUNROOT, expanded at
    # runtime via an UNQUOTED heredoc; staged copies are re-verified
    # against the same embedded exact size+sha before the optimizer)
    stage_rows = String[]
    for e in manifest
        rel = gx_staged_rel(band, e["role"], basename(e["path"]))
        rel === nothing && continue
        push!(stage_rows, "$(e["sha256"]) $(e["size"]) $(e["path"]) \$RUNROOT/$rel")
    end
    stage_lines = join(stage_rows, "\n")
    # pin the MUTABLE GATE CODE itself (verified before sourcing/running),
    # including THIS generator's own source
    gate_pins = join(vcat(
        ["$(sha256(joinpath(PROJECT_ROOT, f)))  $(joinpath(PROJECT_ROOT, f))"
         for f in ("validation/gate4_quota_guard.sh",
                   "validation/gate4_g3_scoped_input_preflight.jl",
                   "validation/gate4_g3_executor_checkpoint.jl",
                   "validation/validation_results.jl",
                   "test/Project.toml",
                   "test/Manifest.toml")],
        # the diagnosis-of-record artifact, pinned by the REVIEWED sha
        # (not a live hash): drift refuses in-job at stage 0a
        ["$FAILURE_LEDGER_SHA  $FAILURE_LEDGER_JSON"]), "\n")
    text = """
#!/bin/bash
#SBATCH --job-name=g4-g3-$(band)-optimizer
#SBATCH --output=/shared/home/greg/data/ckdmip-logs/g4-g3-$(band)-%j.log
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=36
#SBATCH --mem=60G
#SBATCH --partition=cpu-large

# Gate-4 G3 $(uppercase(band)) staged optimizer: optimize_lut ONLY (no
# create/scale/find/LBL stages). Generated by gate4_g3_executor_checkpoint.jl.
# Faithful TRAINING_BOTH=yes recovery run from the accepted init.
# RESTARTABLE BY DESIGN: every intermediate lives under the job-private
# RUNROOT (validated numeric SLURM_JOB_ID); only the FINAL ckd file is
# published -- atomically -- to the canonical path, so a TIMEOUT can be
# resubmitted without any deletion. RUNROOT is preserved on success AND
# failure for ledger/forensics; no recursive deletion anywhere.
set -euo pipefail
if [ -z "\${SLURM_JOB_ID:-}" ]; then
    echo "REFUSED: head-node execution is not permitted; submit via sbatch." >&2
    exit 64
fi
case "\$SLURM_JOB_ID" in
    ''|*[!0-9]*) echo "REFUSED: SLURM_JOB_ID is not a positive integer" >&2; exit 64;;
esac

G4WORK=$G4WORK
RUNROOT="\$G4WORK/g3-runs/\${SLURM_JOB_ID}/$(band)"
WRAPPER="\$RUNROOT/tools/optimize_lut_h5preinit_v$vv"
TESTCOPY="\$RUNROOT/testcopy"
STAGED_FINAL="$staged_final"
CANON_FINAL="$final_ckd"

echo "=== G3-$(band) stage 0a: gate-code identity (verify BEFORE sourcing) ==="
sha256sum -c <<'GATEPINS' || { echo "REFUSED: gate code changed since generation; regenerate the checkpoint" >&2; exit 75; }
$gate_pins
GATEPINS

echo "=== G3-$(band) stage 0b: quota health (read-only; before controlled optimizer workspace/output allocation) ==="
source $PROJECT_ROOT/validation/gate4_quota_guard.sh
quota_health \$((5*1024*1024*1024)) || { echo "REFUSED: quota not healthy (soft-primary reserve shortfall or unhealthy state)" >&2; exit 67; }

echo "=== G3-$(band) stage 0c: fresh scoped preflight must be READY (no-write mode; full diagnostics preserved) ==="
set +e
PF_OUT=\$(cd $PROJECT_ROOT && G3_PREFLIGHT_CHECK_ONLY=1 julia --project=test validation/gate4_g3_scoped_input_preflight.jl 2>&1)
PF_RC=\$?
set -e
echo "\$PF_OUT"
[ "\$PF_RC" = 0 ] || { echo "REFUSED: scoped preflight exited rc=\$PF_RC at execution time (diagnostics above)" >&2; exit 74; }
[ "\$(printf '%s\\n' "\$PF_OUT" | grep -c '^gate4_g3_scoped_input_preflight: g3_scoped_preflight_ready\$')" = 1 ] || { echo "REFUSED: scoped preflight did not report exactly one exact READY status line" >&2; exit 74; }

echo "=== G3-$(band) stage 0d: band lock (acquired before campaign RUNROOT/input-snapshot/output mutation) ==="
mkdir -p "\$G4WORK/locks"
exec 9>"\$G4WORK/locks/g3-$(band).lock"
flock -n 9 || { echo "REFUSED: another G3-$(band) job holds the lock" >&2; exit 73; }

echo "=== G3-$(band) stage 0e: exact size+sha pin of EVERY optimizer input (originals) ==="
sha256sum -c <<'HASHES' || { echo "REFUSED: pinned input/source hash mismatch" >&2; exit 69; }
$hash_lines
HASHES
while read -r esz p; do
    asz=\$(stat -Lc %s "\$p") || { echo "REFUSED: cannot stat pinned input \$p" >&2; exit 69; }
    [ "\$asz" = "\$esz" ] || { echo "REFUSED: pinned input size mismatch \$p (\$asz != \$esz)" >&2; exit 69; }
done <<'SIZES'
$size_lines
SIZES
test -x "$(p.bindir)/optimize_lut" || { echo "REFUSED: optimize_lut not executable" >&2; exit 68; }
# the canonical FINAL must be absent at start (rechecked under lock
# again immediately before publish); intermediates are never canonical
test ! -e "\$CANON_FINAL" || { echo "REFUSED: canonical final output already exists: \$CANON_FINAL" >&2; exit 70; }

echo "=== G3-$(band) stage 1: job-private RUNROOT + scientific-input snapshot ==="
[ ! -e "\$RUNROOT" ] || { echo "REFUSED: RUNROOT already exists: \$RUNROOT" >&2; exit 72; }
mkdir -p "\$RUNROOT/data/evaluation1/$(p.lw ? "lw_fluxes" : "sw_fluxes-rgb")" \\
         "\$RUNROOT/work/$(band)_lbl_fluxes" \\
         "\$RUNROOT/work/$(band)_raw-ckd-definition" \\
         "\$RUNROOT/work/$(band)_ckd-definition" \\
         "\$RUNROOT/work/$(band)_gpoints" \\
         "\$RUNROOT/tools"
# stage each pinned input into the private snapshot, dereferencing
# symlinks, then RE-VERIFY the staged copy against the SAME embedded
# exact size+sha before the optimizer may read it
while read -r esha esz src dst; do
    cp -L -- "\$src" "\$dst" || { echo "REFUSED: staging copy failed: \$src" >&2; exit 76; }
    asz=\$(stat -Lc %s "\$dst") || { echo "REFUSED: cannot stat staged copy \$dst" >&2; exit 76; }
    [ "\$asz" = "\$esz" ] || { echo "REFUSED: staged copy size mismatch \$dst (\$asz != \$esz)" >&2; exit 76; }
    echo "\$esha  \$dst" | sha256sum -c - >/dev/null || { echo "REFUSED: staged copy hash mismatch: \$dst" >&2; exit 76; }
done <<STAGE
$stage_lines
STAGE
echo "staged scientific-input snapshot verified under \$RUNROOT"

echo "=== G3-$(band) stage 2: optimizer wrapper inside RUNROOT (Netlib preload + FP-trap shim; env-only) ==="
# exact-version preload-only order (BLAS, LAPACK, H5 shim); NO
# LD_LIBRARY_PATH by design: both Netlib libraries carry SONAMEs
# libblas.so.3/liblapack.so.3 and satisfy the DT_NEEDED entries
# directly, displacing the ATLAS implementation that SIGFPEd attempts
# 4505/4506 (see gate4_g3_failure_ledger_4505_4506). FP traps stay ON.
cat > "\$WRAPPER" <<WRAP
#!/bin/bash
export LD_PRELOAD="$NETLIB_BLAS:$NETLIB_LAPACK:$SHIM_SO"
exec "$(p.bindir)/optimize_lut" "\\\$@"
WRAP
chmod +x "\$WRAPPER"
sha256sum "\$WRAPPER"

echo "=== G3-$(band) stage 2b: loader-resolution proof (SONAME + exact preload rows + zero alias rows) ==="
# NOTE ldd shape under SONAME-satisfying preloads: each preloaded
# library prints ONE absolute row '/usr/.../lib*.so.3.12.0 (0x...)'
# and there are ZERO 'lib*.so.3 =>' alias rows for blas/lapack (the
# DT_NEEDED entries are satisfied by the preloads). All checks use
# captured text + counted here-string greps (pipefail-safe; no
# early-exit grep -q pipelines).
command -v readelf >/dev/null || { echo "MISSING readelf" >&2; exit 65; }
RE_BLAS=\$(readelf -d "$NETLIB_BLAS")
RE_LAPACK=\$(readelf -d "$NETLIB_LAPACK")
[ "\$(grep -cF 'Library soname: [libblas.so.3]' <<<"\$RE_BLAS" || true)" = 1 ] || { echo "REFUSED: netlib BLAS SONAME != libblas.so.3" >&2; exit 79; }
[ "\$(grep -cF 'Library soname: [liblapack.so.3]' <<<"\$RE_LAPACK" || true)" = 1 ] || { echo "REFUSED: netlib LAPACK SONAME != liblapack.so.3" >&2; exit 79; }
[ "\$(grep -cxF 'export LD_PRELOAD="$NETLIB_BLAS:$NETLIB_LAPACK:$SHIM_SO"' "\$WRAPPER" || true)" = 1 ] || { echo "REFUSED: wrapper preload line/order drifted" >&2; exit 79; }
LDD_OUT=\$(LD_PRELOAD="$NETLIB_BLAS:$NETLIB_LAPACK:$SHIM_SO" ldd "$(p.bindir)/optimize_lut")
echo "\$LDD_OUT"
[ "\$(grep -cF "$NETLIB_BLAS" <<<"\$LDD_OUT" || true)" = 1 ] || { echo "REFUSED: exact BLAS preload row count != 1" >&2; exit 79; }
[ "\$(grep -cF "$NETLIB_LAPACK" <<<"\$LDD_OUT" || true)" = 1 ] || { echo "REFUSED: exact LAPACK preload row count != 1" >&2; exit 79; }
[ "\$(grep -cF 'liblapack.so.3 =>' <<<"\$LDD_OUT" || true)" = 0 ] || { echo "REFUSED: liblapack.so.3 alias row present (second lapack in resolution)" >&2; exit 79; }
[ "\$(grep -cF 'libblas.so.3 =>' <<<"\$LDD_OUT" || true)" = 0 ] || { echo "REFUSED: libblas.so.3 alias row present (second blas in resolution)" >&2; exit 79; }
LN_B=\$(grep -nF "$NETLIB_BLAS" <<<"\$LDD_OUT" | cut -d: -f1 | head -1 || true)
LN_L=\$(grep -nF "$NETLIB_LAPACK" <<<"\$LDD_OUT" | cut -d: -f1 | head -1 || true)
LN_S=\$(grep -nF "$SHIM_SO" <<<"\$LDD_OUT" | cut -d: -f1 | head -1 || true)
{ [ -n "\$LN_B" ] && [ -n "\$LN_L" ] && [ -n "\$LN_S" ] && [ "\$LN_B" -lt "\$LN_L" ] && [ "\$LN_L" -lt "\$LN_S" ]; } || { echo "REFUSED: preload row order is not BLAS<LAPACK<H5shim" >&2; exit 79; }

echo "=== G3-$(band) stage 3: isolated testcopy inside RUNROOT (config overrides) ==="
cp -r "$(p.srcdir)/test" "\$TESTCOPY"
cd "\$TESTCOPY"
sed 's/@PACKAGE_VERSION@/$(p.ver)/g' version.h.in > version.h
sed -i \\
  -e "s|^CKDMIP_DIR=.*|CKDMIP_DIR=$CKDMIP_BIN_ROOT|" \\
  -e "s|^CKDMIP_DATA_DIR=.*|CKDMIP_DATA_DIR=\$RUNROOT/data|" \\
  -e "s|^WORK_DIR=.*|WORK_DIR=\$RUNROOT/work|" \\
  -e "s|^BINDIR=.*|BINDIR=$(p.bindir)|" \\
  -e "s|^TRAINING_BOTH=no\$|TRAINING_BOTH=yes|" \\
  -e "s|^OPTIMIZE_LUT=.*|OPTIMIZE_LUT=\$WRAPPER|" \\
  config.h
grep -E "^(CKDMIP_DIR|CKDMIP_DATA_DIR|WORK_DIR|BINDIR|TRAINING_BOTH|OPTIMIZE_LUT)=" config.h
# EVERY override asserted exactly (never TRAINING_BOTH alone); the
# optimizer must see ONLY the private snapshot paths
for kv in "CKDMIP_DIR=$CKDMIP_BIN_ROOT" "CKDMIP_DATA_DIR=\$RUNROOT/data" "WORK_DIR=\$RUNROOT/work" "BINDIR=$(p.bindir)" "TRAINING_BOTH=yes" "OPTIMIZE_LUT=\$WRAPPER"; do
    grep -qxF "\$kv" config.h || { echo "BAD config override: \$kv" >&2; exit 68; }
done
# surface the raw optimize_lut rc/signal (4505/4506 lesson: the
# upstream PIPESTATUS test flattened 128+sig to a silent shell rc 1);
# the child status now reaches the Slurm log and the pass exits with
# the child's own rc
sed -i 's|^[[:space:]]*test "\\\${PIPESTATUS\\[0\\]}" -eq 0[[:space:]]*\$|\\trc="\${PIPESTATUS[0]}"; if [ "\$rc" -ne 0 ]; then if [ "\$rc" -ge 128 ]; then echo "OPTIMIZE_LUT CHILD KILLED BY SIGNAL \$((rc-128)) (rc=\$rc)" >\\&2; else echo "OPTIMIZE_LUT CHILD FAILED rc=\$rc" >\\&2; fi; exit "\$rc"; fi|' $(p.script)
grep -q "OPTIMIZE_LUT CHILD" $(p.script) || { echo "BAD sed: child-status surfacing not applied" >&2; exit 68; }
grep -qF 'test "\${PIPESTATUS[0]}" -eq 0' $(p.script) && { echo "BAD sed: raw PIPESTATUS test remains" >&2; exit 68; } || true

echo "=== G3-$(band) stage 4: staged optimizer ($modes; all writes under RUNROOT) ==="
APPLICATION=climate BAND_STRUCTURE=$bandstruct TOLERANCE=$tol \\
    bash $(p.script) $modes

echo "=== G3-$(band) stage 5: staged outputs (hash echoes; nothing canonical yet) ==="
sha256sum $(join(map(f -> "\"$f\"", staged_outputs), " \\\n    "))
test -s "\$STAGED_FINAL" || { echo "MISSING staged final ckd-definition" >&2; exit 71; }

echo "=== G3-$(band) stage 6: FINAL-ONLY atomic publish to the canonical path ==="
# recheck under the still-held band lock immediately before publish
test ! -e "\$CANON_FINAL" || { echo "REFUSED: canonical final appeared during run: \$CANON_FINAL" >&2; exit 70; }
SF_SZ=\$(stat -Lc %s "\$STAGED_FINAL")
quota_object_recheck "\$SF_SZ" \$((5*1024*1024*1024)) || { echo "REFUSED: quota recheck before final publish" >&2; exit 67; }
SF_SHA=\$(sha256sum "\$STAGED_FINAL" | cut -d' ' -f1)
mkdir -p "\$(dirname "\$CANON_FINAL")"
# dot-prefixed AND job-specific temp; a leftover from a failed/timeout
# attempt is preserved forensics and REFUSES rather than being reused
FTMP="\$(dirname "\$CANON_FINAL")/.g3.publish.\${SLURM_JOB_ID}.$fb"
[ ! -e "\$FTMP" ] || { echo "REFUSED: publish temp already exists (prior-attempt forensics preserved): \$FTMP" >&2; exit 77; }
cp -- "\$STAGED_FINAL" "\$FTMP"
sync "\$FTMP"
FT_SZ=\$(stat -Lc %s "\$FTMP")
FT_SHA=\$(sha256sum "\$FTMP" | cut -d' ' -f1)
{ [ "\$FT_SZ" = "\$SF_SZ" ] && [ "\$FT_SHA" = "\$SF_SHA" ]; } || { echo "REFUSED: publish temp does not match staged final (temp preserved)" >&2; exit 77; }
# no-clobber atomic move: a canonical final appearing concurrently is
# NEVER overwritten; mv -n exits 0 on skip, so the move is PROVEN by
# the temp being gone plus canonical size+sha equality (a bare post-mv
# sha echo is insufficient)
mv -n -- "\$FTMP" "\$CANON_FINAL"
[ ! -e "\$FTMP" ] || { echo "REFUSED: no-clobber publish did not move (canonical appeared concurrently); temp preserved: \$FTMP" >&2; exit 78; }
CF_SZ=\$(stat -Lc %s "\$CANON_FINAL")
CF_SHA=\$(sha256sum "\$CANON_FINAL" | cut -d' ' -f1)
{ [ "\$CF_SZ" = "\$SF_SZ" ] && [ "\$CF_SHA" = "\$SF_SHA" ]; } || { echo "REFUSED: canonical final does not match staged size+sha after publish" >&2; exit 78; }
echo "\$CF_SHA  \$CANON_FINAL"
echo "RUNROOT preserved for ledger/forensics: \$RUNROOT (no cleanup by design)"
echo "=== G3-$(band) done \$(date -u +%FT%TZ) ==="
"""
    (text = text, manifest = manifest)
end

# every gate computed FROM generated script text: explicitly
# blocked_prerequisite when generation is refused, never evaluated on
# fabricated/empty text
const GX_TEXT_GATES = vcat(
    [g for nm in ("lw", "sw")
       for g in ["$(nm)_headnode_refusal", "$(nm)_optimize_only",
                 "$(nm)_training_both_sed", "$(nm)_shim_wrapper",
                 "$(nm)_stale_output_refusal", "$(nm)_input_hash_gate",
                 "$(nm)_input_size_gate", "$(nm)_flock_single_flight",
                 "$(nm)_readonly_gates_before_lock",
                 "$(nm)_gate_code_pinned", "$(nm)_failure_ledger_pinned",
                 "$(nm)_quota_health_gate",
                 "$(nm)_runtime_ready_preflight", "$(nm)_source_pins",
                 "$(nm)_config_asserts", "$(nm)_private_runroot",
                 "$(nm)_runroot_staging", "$(nm)_private_workdir",
                 "$(nm)_final_only_publish", "$(nm)_wrapper_in_runroot",
                 "$(nm)_netlib_preload_order",
                 "$(nm)_netlib_sha_pins",
                 "$(nm)_loader_resolution_gate",
                 "$(nm)_child_status_surfacing",
                 "$(nm)_bash_syntax", "$(nm)_input_manifest_counts"]],
    ["lw_mode_list", "sw_mode_list"])

function main()
    fails = String[]
    gates = Dict{String, String}()

    # loader fixtures FIRST, through the SAME guarded classifier
    tdir = mktempdir()
    lt = Dict{String, Bool}()
    shaof(p) = bytes2hex(SHA.sha256(read(p)))
    cls(p; kw...) = gx_classify_scoped_preflight(p; kw...)
    lt["missing_invalid"] =
        cls(joinpath(tdir, "absent.json")).class == "missing"
    fp = joinpath(tdir, "x.json"); write(fp, "{}")
    lt["unreadable_invalid"] =
        cls(fp; readfn = _ -> error("io")).class == "unreadable"
    write(fp, "{")
    lt["malformed_invalid"] =
        cls(fp; expected_sha = shaof(fp)).class == "unparseable (parse failure)"
    write(fp, "null")
    lt["null_invalid_non_object"] = occursin("non-object",
        cls(fp; expected_sha = shaof(fp)).class)
    write(fp, "[1]")
    lt["array_invalid_non_object"] = occursin("non-object",
        cls(fp; expected_sha = shaof(fp)).class)
    write(fp, "{\"case\": \"other\", \"status\": \"g3_scoped_preflight_ready\"}")
    lt["wrong_case_invalid"] =
        cls(fp; expected_sha = shaof(fp)).class == "case mismatch"
    write(fp, "{\"case\": \"gate4_g3_scoped_input_preflight\", " *
              "\"status\": \"g3_scoped_preflight_waiting_for_eval2\"}")
    lt["former_waiting_token_rejected"] =
        cls(fp; expected_sha = shaof(fp)).class == "status mismatch"
    write(fp, "{\"case\": \"gate4_g3_scoped_input_preflight\", " *
              "\"status\": \"tampered\"}")
    lt["unknown_status_invalid"] =
        cls(fp; expected_sha = shaof(fp)).class == "status mismatch"
    write(fp, "{\"case\": \"gate4_g3_scoped_input_preflight\", " *
              "\"status\": \"g3_scoped_preflight_ready\"}")
    lt["sha_drift_invalid"] =
        cls(fp; expected_sha = "0" ^ 64).class == "sha drift"
    lt["green_accepted"] = cls(fp; expected_sha = shaof(fp)).ok
    # call-site decision, proven with an injected counting generator:
    # anything but ready NEVER invokes generation; ready generates both bands
    lt["invalid_never_invokes_generator"] = begin
        n = Ref(0)
        r = gx_generate_scripts(b -> (n[] += 1; "T"), "invalid")
        r === nothing && n[] == 0
    end
    lt["former_waiting_never_invokes_generator"] = begin
        n = Ref(0)
        r = gx_generate_scripts(b -> (n[] += 1; "T"), "waiting")
        r === nothing && n[] == 0
    end
    lt["ready_generates_both_bands"] = begin
        n = Ref(0)
        r = gx_generate_scripts(b -> (n[] += 1; "T"), "ready")
        r !== nothing && n[] == 2 && sort(collect(keys(r))) == ["lw", "sw"]
    end
    rm(tdir, recursive = true, force = true)
    gates["preflight_loader_fixture_tests"] =
        all(values(lt)) ? "passed" : "failed"
    all(values(lt)) || push!(fails, "preflight loader fixture failures: " *
        join(sort([k for (k, v) in lt if !v]), ", "))

    # immutable prerequisite: coupled snapshot + source pin + ancestry
    led = gx_classify_scoped_preflight(GX_PF_JSON)
    pf_state = led.ok ? "ready" : "invalid"
    gates["scoped_preflight_prerequisite"] = led.ok ? "passed" : "failed"
    led.ok || push!(fails, led.reason)
    pf_src_sha = try sha256(GX_PF_SRC) catch; nothing end
    gates["preflight_source_pin"] =
        pf_src_sha == GX_PF_SRC_SHA ? "passed" : "failed"
    gates["preflight_source_pin"] == "passed" ||
        push!(fails, "preflight source sha drift")
    anc = try
        success(`git -C $PROJECT_ROOT merge-base --is-ancestor $GX_ANCESTOR HEAD`)
    catch; false end
    gates["reviewed_commit_ancestry"] = anc ? "passed" : "failed"
    anc || push!(fails, "reviewed commit $GX_ANCESTOR not an ancestor of HEAD")

    # netlib remedy pins enforced against the REVIEWED constants BEFORE
    # generation: a same-version library update must never be silently
    # repinned into freshly generated scripts
    netlib_ok = try
        isfile(NETLIB_BLAS) && filesize(NETLIB_BLAS) == NETLIB_BLAS_BYTES &&
        sha256(NETLIB_BLAS) == NETLIB_BLAS_SHA &&
        isfile(NETLIB_LAPACK) &&
        filesize(NETLIB_LAPACK) == NETLIB_LAPACK_BYTES &&
        sha256(NETLIB_LAPACK) == NETLIB_LAPACK_SHA
    catch; false end
    gates["netlib_pins_live"] = netlib_ok ? "passed" : "failed"
    netlib_ok ||
        push!(fails, "netlib runtime library size/sha drift vs reviewed pins")

    # the committed failure-ledger artifact bound by exact reviewed sha
    ledger_ok = try
        sha256(FAILURE_LEDGER_JSON) == FAILURE_LEDGER_SHA
    catch; false end
    gates["failure_ledger_pin_live"] = ledger_ok ? "passed" : "failed"
    ledger_ok ||
        push!(fails, "4505/4506 failure-ledger artifact sha drift vs reviewed pin")

    # generation ONLY behind the ready decision AND intact netlib AND
    # failure-ledger pins (generator reads/hashes mutable inputs and may
    # throw; invalid never invokes it)
    gen_state = (pf_state == "ready" && netlib_ok && ledger_ok) ?
        "ready" : "invalid"
    texts = gx_generate_scripts(make_sbatch, gen_state)
    sbatch_written = texts !== nothing

    gates["sbatch_written_not_submitted"] = "passed"
    self_src = read(@__FILE__, String)
    sb_tok = "sb" * "atch "
    isempty(collect(eachmatch(Regex("run\\(`" * sb_tok), self_src))) ||
        (gates["sbatch_written_not_submitted"] = "failed";
         push!(fails, "sbatch invocation found in checkpoint unit"))
    gen_scripts = Dict{String, Any}()
    if sbatch_written
        lw_text = texts["lw"].text
        sw_text = texts["sw"].text
        open(GX_SBATCH_LW, "w") do io; write(io, lw_text); end
        open(GX_SBATCH_SW, "w") do io; write(io, sw_text); end
        for (nm, txt, path) in (("lw", lw_text, GX_SBATCH_LW),
                                ("sw", sw_text, GX_SBATCH_SW))
            gen_scripts[nm] = Dict("path" => path,
                "bytes" => Int(filesize(path)), "sha256" => sha256(path))
            exec_lines = join([l for l in split(txt, '\n')
                               if !occursin(r"^\s*#", l)], '\n')
            gates["$(nm)_bash_syntax"] =
                success(pipeline(`bash -n $path`, stderr=devnull)) ?
                "passed" : "failed"
            gates["$(nm)_headnode_refusal"] =
                occursin("REFUSED: head-node execution", txt) ? "passed" : "failed"
            gates["$(nm)_optimize_only"] =
                occursin("optimize_lut", exec_lines) &&
                !occursin("create_lut", exec_lines) &&
                !occursin("create_look_up_table", exec_lines) &&
                !occursin("scale_lut_", exec_lines) &&
                !occursin("find_g_points", exec_lines) &&
                !occursin("run_ckd", exec_lines) &&
                !occursin("lbl_evaluation", exec_lines) ? "passed" : "failed"
            gates["$(nm)_optimize_only"] == "passed" ||
                push!(fails, "$nm: forbidden stage in executable lines")
            gates["$(nm)_training_both_sed"] =
                occursin("TRAINING_BOTH=no\$|TRAINING_BOTH=yes", txt) ? "passed" : "failed"
            gates["$(nm)_shim_wrapper"] =
                occursin("LD_PRELOAD", txt) && occursin(SHIM_SO_SHA, txt) &&
                occursin("OPTIMIZE_LUT=\$WRAPPER", txt) ? "passed" : "failed"
            gates["$(nm)_stale_output_refusal"] =
                occursin("canonical final output already exists", txt) &&
                occursin("canonical final appeared during run", txt) ?
                "passed" : "failed"
            gates["$(nm)_input_hash_gate"] =
                occursin("sha256sum -c", txt) &&
                occursin("pinned input/source hash mismatch", txt) ? "passed" : "failed"
            gates["$(nm)_input_size_gate"] =
                occursin("stat -Lc %s", txt) &&
                occursin("pinned input size mismatch", txt) &&
                occursin("<<'SIZES'", txt) ? "passed" : "failed"
            gates["$(nm)_flock_single_flight"] =
                occursin("flock -n 9", txt) && occursin("g3-$(nm).lock", txt) ? "passed" : "failed"
            i_gatepin = findfirst("GATEPINS", txt); i_health = findfirst("quota_health ", txt)
            i_source = findfirst("source $PROJECT_ROOT", txt); i_lock = findfirst("flock -n 9", txt)
            i_pf = findfirst("G3_PREFLIGHT_CHECK_ONLY=1", txt)
            i_runroot = findfirst("stage 1: job-private RUNROOT", txt)
            gates["$(nm)_readonly_gates_before_lock"] =
                (i_gatepin !== nothing && i_source !== nothing && i_health !== nothing &&
                 i_pf !== nothing && i_lock !== nothing && i_runroot !== nothing &&
                 first(i_gatepin) < first(i_source) < first(i_health) &&
                 first(i_health) < first(i_pf) < first(i_lock) &&
                 first(i_lock) < first(i_runroot)) ? "passed" : "failed"
            gp_block = split(txt, "GATEPINS")[2]
            gates["$(nm)_gate_code_pinned"] =
                all(occursin(f, gp_block) for f in ("gate4_quota_guard.sh",
                    "gate4_g3_scoped_input_preflight.jl",
                    "gate4_g3_executor_checkpoint.jl",
                    "validation_results.jl",
                    "test/Project.toml", "test/Manifest.toml")) ? "passed" : "failed"
            gates["$(nm)_failure_ledger_pinned"] =
                (occursin(FAILURE_LEDGER_SHA, gp_block) &&
                 occursin("gate4_g3_failure_ledger_4505_4506.json", gp_block)) ?
                "passed" : "failed"
            gates["$(nm)_quota_health_gate"] =
                occursin("quota_health ", txt) &&
                occursin("before controlled optimizer workspace/output allocation", txt) &&
                !occursin("before ANY /shared write", txt) &&
                !occursin("first /shared write", txt) ? "passed" : "failed"
            gates["$(nm)_runtime_ready_preflight"] =
                occursin("PF_RC=\$?", txt) &&
                occursin("grep -c '^gate4_g3_scoped_input_preflight: g3_scoped_preflight_ready\$'", txt) &&
                !occursin("2>/dev/null", txt) ? "passed" : "failed"
            gates["$(nm)_source_pins"] =
                occursin("config.h", split(txt, "HASHES")[2]) &&
                occursin("version.h.in", split(txt, "HASHES")[2]) ? "passed" : "failed"
            gates["$(nm)_config_asserts"] =
                occursin("grep -qxF \"\$kv\" config.h", txt) &&
                occursin("\"TRAINING_BOTH=yes\"", txt) &&
                occursin("\"WORK_DIR=\$RUNROOT/work\"", txt) &&
                occursin("\"BINDIR=", txt) &&
                occursin("\"CKDMIP_DIR=", txt) &&
                occursin("\"CKDMIP_DATA_DIR=\$RUNROOT/data\"", txt) &&
                occursin("\"OPTIMIZE_LUT=\$WRAPPER\"", txt) ? "passed" : "failed"
            gates["$(nm)_private_runroot"] =
                occursin("RUNROOT=\"\$G4WORK/g3-runs/\${SLURM_JOB_ID}/$(nm)\"", txt) &&
                occursin("SLURM_JOB_ID is not a positive integer", txt) &&
                occursin("RUNROOT already exists", txt) &&
                occursin("RUNROOT preserved for ledger/forensics", txt) &&
                !occursin("rm -rf", txt) ? "passed" : "failed"
            gates["$(nm)_runroot_staging"] =
                occursin("scientific-input snapshot", txt) &&
                occursin("<<STAGE", txt) &&
                occursin("staged copy hash mismatch", txt) &&
                occursin("staged copy size mismatch", txt) &&
                occursin("cp -L -- ", txt) ? "passed" : "failed"
            gates["$(nm)_private_workdir"] =
                occursin("WORK_DIR=\$RUNROOT/work", txt) &&
                !occursin("WORK_DIR=$G4WORK/work", txt) ? "passed" : "failed"
            gates["$(nm)_final_only_publish"] =
                occursin(".g3.publish.\${SLURM_JOB_ID}.", txt) &&
                occursin("publish temp already exists", txt) &&
                occursin("publish temp does not match staged final", txt) &&
                occursin("mv -n -- \"\$FTMP\" \"\$CANON_FINAL\"", txt) &&
                occursin("no-clobber publish did not move", txt) &&
                occursin("canonical final does not match staged size+sha after publish", txt) &&
                occursin("quota_object_recheck \"\$SF_SZ\"", txt) &&
                occursin("sync \"\$FTMP\"", txt) ? "passed" : "failed"
            gates["$(nm)_wrapper_in_runroot"] =
                occursin("WRAPPER=\"\$RUNROOT/tools/optimize_lut_h5preinit", txt) &&
                !occursin("\$G4WORK/tools/optimize_lut_h5preinit", txt) ? "passed" : "failed"
            gates["$(nm)_netlib_preload_order"] =
                occursin("export LD_PRELOAD=\"$NETLIB_BLAS:$NETLIB_LAPACK:$SHIM_SO\"", txt) &&
                !occursin("export LD_LIBRARY_PATH=", txt) ? "passed" : "failed"
            gates["$(nm)_netlib_sha_pins"] =
                occursin(NETLIB_BLAS_SHA, txt) &&
                occursin(NETLIB_LAPACK_SHA, txt) ? "passed" : "failed"
            gates["$(nm)_loader_resolution_gate"] =
                occursin("stage 2b: loader-resolution proof", txt) &&
                occursin("Library soname: [libblas.so.3]", txt) &&
                occursin("Library soname: [liblapack.so.3]", txt) &&
                occursin("wrapper preload line/order drifted", txt) &&
                occursin("exact BLAS preload row count != 1", txt) &&
                occursin("exact LAPACK preload row count != 1", txt) &&
                occursin("liblapack.so.3 alias row present", txt) &&
                occursin("libblas.so.3 alias row present", txt) &&
                occursin("preload row order is not BLAS<LAPACK<H5shim", txt) &&
                !occursin("| grep -q", txt) ? "passed" : "failed"
            gates["$(nm)_child_status_surfacing"] =
                occursin("OPTIMIZE_LUT CHILD KILLED BY SIGNAL", txt) &&
                occursin("OPTIMIZE_LUT CHILD FAILED rc=", txt) &&
                occursin("raw PIPESTATUS test remains", txt) ? "passed" : "failed"
        end
        for (nm, man) in (("lw", texts["lw"].manifest),
                          ("sw", texts["sw"].manifest))
            expected_n = nm == "lw" ? 31 : 27
            expected_flux = nm == "lw" ? 20 : 16
            paths = [e["path"] for e in man]
            gates["$(nm)_input_manifest_counts"] =
                (length(man) == expected_n &&
                 length(unique(paths)) == expected_n &&
                 count(e -> e["role"] == "training_flux", man) == expected_flux &&
                 count(e -> e["role"] == "runtime_blas", man) == 1 &&
                 count(e -> e["role"] == "runtime_lapack", man) == 1) ?
                "passed" : "failed"
        end
        gates["lw_mode_list"] =
            occursin("optimize_lut_lw.sh relative-base relative-ch4 relative-n2o relative-cfc",
                     lw_text) ? "passed" : "failed"
        gates["sw_mode_list"] =
            occursin("optimize_lut_sw.sh relative-base relative-ch4 relative-n2o",
                     sw_text) && !occursin("relative-cfc", sw_text) ? "passed" : "failed"
    else
        for g in GX_TEXT_GATES
            gates[g] = "blocked_prerequisite"
        end
    end
    # quota_health fixture tests (stubbed lfs; same sourced logic;
    # SOFT-primary reserve semantics)
    guard = joinpath(PROJECT_ROOT, "validation/gate4_quota_guard.sh")
    run_health(pathdir) = success(pipeline(
        `/usr/bin/env PATH=$pathdir /bin/bash -c "source $guard; quota_health 5368709120"`,
        stdout=devnull, stderr=devnull))
    fx = mktempdir()
    bin_min = joinpath(fx, "bin_min"); mkpath(bin_min)
    for t in ("awk", "stat", "id", "grep", "sed", "sort", "wc")
        tp = Sys.which(t); tp === nothing || symlink(tp, joinpath(bin_min, t))
    end
    mkfix(name, rowscript) = begin
        d = joinpath(fx, name); mkpath(d)
        for t in readdir(bin_min); symlink(joinpath(bin_min, t), joinpath(d, t)); end
        lf = joinpath(d, "lfs"); write(lf, "#!/bin/bash\necho \"" * rowscript * "\"\n")
        chmod(lf, 0o755); d
    end
    htests = Dict{String, Bool}()
    htests["healthy_passes"] =
        run_health(mkfix("h1", "/shared 100 900000000 1000000000 - 1 0 0 -")) == true
    htests["over_soft_grace_refuses"] =
        run_health(mkfix("h2", "/shared 950000000* 900000000 1000000000 6d23h 1 0 0 -")) == false
    htests["malformed_refuses"] =
        run_health(mkfix("h3", "/shared abc def ghi - 1 0 0 -")) == false
    htests["zero_limits_refuse"] =
        run_health(mkfix("h4", "/shared 100 0 0 - 1 0 0 -")) == false
    # SOFT-primary: soft reserve shortfall refuses even with ample hard
    htests["soft_reserve_shortfall_hard_ample_refuses"] =
        run_health(mkfix("h5", "/shared 899999000 900000000 2000000000 - 1 0 0 -")) == false
    # hard shortfall still refuses (secondary sanity)
    htests["hard_reserve_shortfall_refuses"] =
        run_health(mkfix("h6", "/shared 100 1900000000 4194404 - 1 0 0 -")) == false
    htests["used_over_soft_refuses"] =
        run_health(mkfix("h7", "/shared 999999000 900000000 2000000000 - 1 0 0 -")) == false
    gates["quota_health_fixture_tests"] = all(values(htests)) ? "passed" : "failed"
    all(values(htests)) ||
        push!(fails, "quota_health fixture failures: " *
                     join([k for (k, v) in htests if !v], ", "))
    gates["token_gated_submit"] = try
        submit_g3(); "failed"
    catch err
        occursin("refused", sprint(showerror, err)) ? "passed" : "failed"
    end
    gates["sw_script_version_identity"] = try
        success(pipeline(`diff -q $V14_TREE/test/optimize_lut_sw.sh $ECCKD_SRC/test/optimize_lut_sw.sh`,
                         stdout=devnull, stderr=devnull)) ? "passed" : "failed"
    catch; "failed" end

    # FAIL-CLOSED: ready-awaiting-go ONLY when every gate passed; the
    # former waiting status and its exit-0 path no longer exist
    status = (all(v -> v == "passed", values(gates)) && isempty(fails)) ?
        "g3_executor_ready_awaiting_go" : "g3_executor_checkpoint_failed"

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    ghead = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_g3_executor_checkpoint",
        "data_mode" => "dry_run_script_generation_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)) * "Z",
        "gates" => gates, "failures" => fails,
        "prerequisite" => Dict(
            "artifact" => GX_PF_JSON,
            "expected_case" => GX_PF_CASE,
            "expected_status" => GX_PF_STATUS,
            "expected_sha256" => GX_PF_SHA,
            "observed_case" => led.observed_case,
            "observed_status" => led.observed_status,
            "observed_sha256" => led.observed_sha,
            "classifier_verdict" => led.ok ? "green" : led.class,
            "source_expected_sha256" => GX_PF_SRC_SHA,
            "source_observed_sha256" => pf_src_sha,
            "ancestor_commit" => GX_ANCESTOR,
            "ancestor_observed" => anc),
        "sbatch_paths" => Dict("lw" => GX_SBATCH_LW, "sw" => GX_SBATCH_SW),
        "sbatch_written_this_run" => sbatch_written,
        "generated_scripts" => gen_scripts,
        "input_manifest" => sbatch_written ?
            Dict("lw" => texts["lw"].manifest,
                 "sw" => texts["sw"].manifest) : Dict(),
        "sbatch_scripts_state" => sbatch_written ?
            "generated this run (unsubmitted)" :
            "NOT generated this run (prerequisite blocked); any files " *
            "at sbatch_paths are PRESERVED HISTORICAL output of an " *
            "earlier run, not current",
        "preflight_loader_fixture_verdicts" => lt,
        "quota_health_fixture_verdicts" => htests,
        "authorization_token_required" => "g3_recovery_go (submission is " *
            "a reviewed human step)",
        "amendment_verification_summary" => Dict(
            "attribution" => "Codex monitor independent generated-shell " *
                "verification of the 4505/4506-remedy amendment " *
                "(2026-08-13), recorded as attributed evidence",
            "netlib_pins" => "live reviewed sizes+SHAs exact for both " *
                "Netlib libraries",
            "soname" => "readelf SONAME counts exact " *
                "(libblas.so.3/liblapack.so.3)",
            "loader_resolution" => "preload-only ldd shows exact " *
                "BLAS/LAPACK/H5-shim rows once each, ZERO generic " *
                "libblas/liblapack alias rows, preload order at lines " *
                "2<3<4",
            "child_status_sed" => "generated sed applied to a fresh " *
                "exact upstream LW script: bash -n passes, replacement " *
                "count 1, old PIPESTATUS test count 0",
            "child_status_semantics" => "transformed status line " *
                "executed against synthetic child rc 0/7/136: outer rc " *
                "preserved 0/7/136 with messages empty / 'CHILD FAILED " *
                "rc=7' / 'CHILD KILLED BY SIGNAL 8 (rc=136)'"),
        "acceptance_metrics_note" => "FIVE canonical thresholds, evaluated " *
            "by separate post-run runners, never inside the executor: " *
            "(1) final/target objective ratio <= 1.05; (2) weight rel-L1 " *
            "<= 0.02; (3) true OD log-RMSE <= 0.02; (4) forcing " *
            "regression margin <= 0.03 W/m2; (5) heating-RMSE regression " *
            "margin <= 0.005 K/day (aggregation semantics pending ruling)",
        "provenance" => Dict("branch" => branch, "generated_from_head" => ghead,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "script generation only; nothing submitted or " *
                        "executed; no objective, floor, or recovery " *
                        "computation in this unit.",
    )
    mkpath(dirname(GX_RESULTS_JSON))
    open(GX_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(GX_RESULTS_MD, "w") do io
        println(io, "# Gate-4 G3 executor checkpoint (dry-run)\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        if sbatch_written
            println(io, "\nGenerated (unsubmitted): `$(GX_SBATCH_LW)` " *
                        "($(gen_scripts["lw"]["bytes"]) B, sha256 " *
                        "$(gen_scripts["lw"]["sha256"])), `$(GX_SBATCH_SW)` " *
                        "($(gen_scripts["sw"]["bytes"]) B, sha256 " *
                        "$(gen_scripts["sw"]["sha256"]))")
            println(io, "\nInput manifests: LW " *
                        "$(length(texts["lw"].manifest)) entries, SW " *
                        "$(length(texts["sw"].manifest)) entries (path/" *
                        "size/sha/role in JSON; every entry embedded as " *
                        "runtime sha+size pins).")
        else
            println(io, "\nNO scripts generated this run (prerequisite " *
                        "blocked); any files at `$(GX_SBATCH_LW)`, " *
                        "`$(GX_SBATCH_SW)` are preserved historical " *
                        "output of an earlier run, not current.")
        end
        println(io, "\nAuthorization: token `g3_recovery_go` + review; " *
                    "READY is the only generation state.")
        println(io, "\n", result["acceptance_metrics_note"])
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$ghead` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_g3_executor_checkpoint: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "g3_executor_ready_awaiting_go" ? 0 : 1
end

exit(main())
