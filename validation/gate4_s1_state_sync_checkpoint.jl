# Gate-4 S1 PAIRED STATE-SYNC HYPOTHESIS-TEST CHECKPOINT (generator;
# writes ONLY its own JSON/MD results + the generated sbatch).
#
# TRIPLE-ARM DESIGN (monitor ruling after Agent 42 review, 2026-08-13):
# one job, ONE copied source tree, TWO sequential builds, THREE
# sequential runs --
#   A0a, A0b: the SAME saved pristine rebuilt binary, each with an
#     independently cloned starting-input/work/testcopy set (baseline
#     repeatability / threading-noise floor)
#   S1: the one-line-patched binary (minimizer.ensure_updated_state(1);
#     inserted after the Minimizer setter block at solve_adept.cpp:314)
#     with a third independent clone
# Identical explicit OpenMP controls are set AND logged for every arm
# (OMP_NUM_THREADS = SLURM_CPUS_PER_TASK, OMP_DYNAMIC=FALSE; all other
# env identical).
#
# BUILD RECIPE (corrected after the 4555 failure; see the reviewed
# gate4_s1_failure_ledger_4555): the fresh autoreconf configure's
# Adept >= 2.1 test is order-broken (the m4 embeds its own -ladept
# AHEAD of conftest.cpp), so the recipe carries path-only LDFLAGS
# (-L + rpath, NEVER -ladept) plus LIBS=-ladept (autoconf places user
# LIBS after conftest.cpp, supplying the resolving late -ladept). This
# is a BUILD-ENABLEMENT correction, not a scientific change and NOT
# historical build equivalence: the extant tree's generated configure
# (9ed1baac, Adept >= 1.1 check) is STALE GENERATED STATE relative to
# its own m4 source (m4/adept.m4 byte-identical across trees), so
# generated-configure vintage differs despite identical current m4
# source and config.status --config alone was insufficient
# build-equivalence evidence. The same corrected build is common to
# A0/S1, preserving the internal one-factor triple-arm test; the
# config.status rendering is asserted byte-exact.
#
# PRE-REGISTERED OUTCOME MATRIX (monitor ruling, verbatim substance):
#   - A0a == A0b and S1 == A0a: sync had no effect in this paired
#     deterministic trajectory.
#   - A0a == A0b and S1 differs: patch-associated output change under a
#     deterministic control trajectory; still report hash, exact
#     effective-bound census, and external objective separately.
#   - A0a != A0b: byte-level treatment inference is INCONCLUSIVE
#     because baseline repeatability failed; S1 metrics are descriptive
#     only.
#   - historical 4515 comparison is a bridge ONLY if the rebuilt A0
#     arms match it; otherwise historical hash differences are
#     non-causal (informational echo only).
# NO requirement that an extra final callback provably executed.
#
# PROVENANCE NOTE (corrected, monitor 2026-08-13): job 4515's RUNROOT
# wrapper was NAMED optimize_lut_h5preinit_v12 but exec'd the standard
# PRE-EXISTING optimize_lut binary (sha 6c3600fe...). The compile
# sources appear identical between the artifact and that local build,
# but build provenance/config differs -- hence the A0 control. Claims
# of "everything else held at the 4515 configuration" are conditional
# on the A0 bridge passing.
#
# SUBMISSION IS HELD for monitor re-review: this generator only
# produces the sbatch + evidence; it never submits.

include(joinpath(@__DIR__, "validation_results.jl"))

import JSON
using SHA: sha256

const S1_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
const S1_G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const S1_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"
const S1_CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"

# --- pinned modern (v1.2) ecckd source artifact ---------------------------------
const S1_SRC_ARTIFACT = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"
const S1_ORIG_SOLVE_ADEPT_SHA = "8c9822fac6e6efebadc3fd76c104fe563236221ca6297922e5e8a9467ee32091"
const S1_SOLVE_ADEPT_REL = "src/ecckd/solve_adept.cpp"
const S1_PATCH_ANCHOR = "  minimizer.set_converged_gradient_norm(convergence_criterion);"
const S1_PATCH_LINE = "  minimizer.ensure_updated_state(1);"
const S1_PATCHED_SOLVE_ADEPT_SHA = "c23246d53a474540443a0e877992dc0d24cfda1ad6cbafa218e3a824cb72070b"
const S1_PATCHED_REGION_SHA = "cb0c801d9875acf0a76c315e0eb2ec5aec0d723f641beff0341527838216d30c"
const S1_TREE_FILES = 119
const S1_TREE_EXEC = 24

# installed Adept toolchain pins (the behavior under test lives here)
const S1_ADEPT = "/shared/home/greg/local/adept-2-install"
const S1_MINIMIZER_H = "$S1_ADEPT/include/adept/Minimizer.h"
const S1_MINIMIZER_H_SHA = "dad747936a66304266d0dd31990afa3a7534c589ac6b7a9230eaafbe671a1f8d"
const S1_LIBADEPT = "$S1_ADEPT/lib/libadept.so.0.0.0"
const S1_LIBADEPT_SHA = "1f9016af1b6982493dc8d53dd3a11b2b0c54d4e84c4dbb548b4b06093d43dbcb"
const S1_NETCDF = "/shared/home/greg/local/ckdmip-stack"
# corrected recipe (monitor-tested; reviewed failure ledger 4555):
# path-only LDFLAGS (-L + rpath, never -ladept) + late LIBS=-ladept
const S1_CONFIGURE_ARGV = "./configure --with-adept=$S1_ADEPT " *
    "--with-netcdf=$S1_NETCDF " *
    "'LDFLAGS=-L$S1_ADEPT/lib -Wl,-rpath,$S1_ADEPT/lib' 'LIBS=-ladept'"
# exact config.status --config rendering observed for this recipe
const S1_CONFIG_STATUS_EXPECT = "--with-adept=$S1_ADEPT " *
    "--with-netcdf=$S1_NETCDF " *
    "'LDFLAGS=-L$S1_ADEPT/lib -Wl,-rpath,$S1_ADEPT/lib' LIBS=-ladept"

# reviewed attempt-1 failure ledger (prerequisite; fail-closed)
const S1_FL5_JSON = validation_results_path("gate4_s1_failure_ledger_4555.json")
const S1_FL5_CASE = "gate4_s1_failure_ledger_4555"
const S1_FL5_STATUS = "s1_4555_failure_recorded"
const S1_FL5_SHA = "865b8c65dc48d6500ca7f71c311a0fce1f40b1fd2bab7cd2c35d276907f582cb"

# fail-closed toolchain fingerprints: exact command paths + complete
# first version lines (monitor blocker 3)
const S1_TOOLCHAIN = [
    ("gcc", "/usr/bin/gcc", "gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"),
    ("g++", "/usr/bin/g++", "g++ (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"),
    ("make", "/usr/bin/make", "GNU Make 4.3"),
    ("autoreconf", "/usr/bin/autoreconf", "autoreconf (GNU Autoconf) 2.71")]
const S1_AUTOMAKE_VER = "1.16.5"
const S1_LIBTOOLIZE_VER = "2.4.7"

# --- proven Netlib remedy pins (verbatim from 4515/B0) --------------------------
const S1_SHIM_SO = "$S1_G4WORK/tools/h5open_before_traps.so"
const S1_SHIM_SO_SHA = "28003281a7f1c8470c1bfd94a654999a210581261a5c3e9cd662af2a13dd492f"
const S1_NETLIB_BLAS = "/usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0"
const S1_NETLIB_BLAS_SHA = "e748efcae5753fe4a652877fccdb5895ac6f7605668a2db878b19c914e78e3a8"
const S1_NETLIB_LAPACK = "/usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0"
const S1_NETLIB_LAPACK_SHA = "851bb1fc5833ede9ed704b4417a251a899976d5e0915de40452615187a65278f"

# --- prerequisite: the REVIEWED committed B0 completion ledger -------------------
const S1_B0_LEDGER = validation_results_path("gate4_b0_era_stack_completion_ledger.json")
const S1_B0_LEDGER_CASE = "gate4_b0_era_stack_completion_ledger"
const S1_B0_LEDGER_STATUS = "b0_run_completed_verified"
const S1_B0_LEDGER_SHA = "d109c0b6e5aa157716247cb05bdfdf806c96e7fc3367e3d5628c55baeda66012"

# historical secondary targets
const S1_MODERN_RAW2_SHA = "4205489923dbc50c3c148a06f20e5781b3f1dbeb5a13d55d36b460c5f7b4378c"
const S1_4515_BINARY_SHA = "6c3600fe6001d92e0d067cde1d57f19c82bae0c208a32dd2c48cd77031c05692"

# --- scientific inputs: identical pins to the 4515/B0 stage-0e manifest ---------
# (sha, size, path, staged-rel...) -- data/ is shared read-only; init/
# eval2/gpoints are staged into EACH arm's private work dir
const S1_DATA_INPUTS = [
    ("dde735608e57af934a2c1e99932c0ccce530883ab48910c7e17b621de7fa0bee", 450863,
     "$S1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-180.h5"),
    ("b0932f2648f720af74191d2a9d62f6178f73dfb9a620b773e55670f06ce2db85", 450863,
     "$S1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-280.h5"),
    ("01836becbc96e7da2b3b33d586d148948df136457216625b7e60225e093e1792", 450863,
     "$S1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-415.h5"),
    ("c8aa819b9e7ea7ed73a0af74862ab49d4209866b74988529b2dfce0ef99710e2", 450863,
     "$S1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-560.h5"),
    ("cfbda1d66decc14e6e91e8465f32f5a5e4bcf0310a73f620fe45bafbcec9ba7c", 450873,
     "$S1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-1120.h5"),
    ("75239df6dbf578b3be6267c09995ff050f5c846be3c75492fad96dcab25610e8", 450873,
     "$S1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-2240.h5")]
const S1_WORK_INPUTS = [
    ("e799eae4421afe12481533678963237198338b3979ec938c6e61c2759522d4bc", 451045,
     "$S1_G4WORK/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5",
     "lw_lbl_fluxes"),
    ("ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43", 2413144,
     "$S1_G4WORK/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc",
     "lw_raw-ckd-definition"),
    ("c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e", 58404939,
     "$S1_G4WORK/work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5",
     "lw_gpoints")]

const S1_V12_TEST_PINS = [
    ("f0d77b16b97612687818e85615a103adaa948627846c9819e40e7754ab0743ba",
     11792, "$S1_SRC_ARTIFACT/test/optimize_lut_lw.sh"),
    ("44dcddf099d69becab1c5e6674d013d6c676685e0b8a4ae51e85a1dda33cfc69",
     6357, "$S1_SRC_ARTIFACT/test/config.h"),
    ("34323fd3ecbcd64980b328eec463eedc692497ed3cdd685f2505ca4d1fdc5e2c",
     1369, "$S1_SRC_ARTIFACT/test/check_configuration.h"),
    ("a5fe514dbcb656c99c11ca39d1c88eba953bda592ca35983de9c42da33dab810",
     92, "$S1_SRC_ARTIFACT/test/version.h.in")]

const S1_RESULTS_JSON = validation_results_path("gate4_s1_state_sync_checkpoint.json")
const S1_RESULTS_MD = validation_results_path("gate4_s1_state_sync_checkpoint.md")
const S1_SBATCH = validation_results_path("gate4_s1_lw_state_sync.sbatch")

# --- primitives -----------------------------------------------------------------

s1_sha(path) = open(io -> bytes2hex(sha256(io)), path)
s1_try_sha(path) = try
    isfile(path) || return nothing
    s1_sha(path)
catch
    nothing
end

# deterministic tree gate of the pinned artifact (monitor blocker 2):
# an EXACT 119-file content + executable-semantics + zero-symlink
# census (sha256 + exec bit + relative path per file). Non-exec
# permission bits and empty directories are deliberately NOT pinned:
# script content/exec semantics are what matters and chmod
# intentionally changes writability on the working copy.
function s1_tree_manifest()
    entries = NamedTuple[]
    for (root, _, files) in walkdir(S1_SRC_ARTIFACT)
        for f in files
            p = joinpath(root, f)
            islink(p) && error("unexpected symlink in artifact: $p")
            rel = relpath(p, S1_SRC_ARTIFACT)
            push!(entries, (rel = rel, sha = s1_sha(p),
                            exec = (uperm(p) & 0x01) != 0))
        end
    end
    sort!(entries, by = e -> e.rel)
    entries
end

s1_manifest_hash(entries) = bytes2hex(sha256(join(
    ["F $(e.sha) $(e.exec ? 1 : 0) $(e.rel)" for e in entries], "\n")))

function s1_snapshot(path; readfn = read)
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

function s1_classify_ledger(path; expected_case = S1_B0_LEDGER_CASE,
                               expected_status = S1_B0_LEDGER_STATUS,
                               expected_sha = S1_B0_LEDGER_SHA,
                               readfn = read)
    snap = s1_snapshot(path; readfn = readfn)
    snap.ok || return (ok = false, class = snap.reason,
                       reason = "B0 ledger $(snap.reason)")
    c = get(snap.data, "case", nothing)
    c == expected_case || return (ok = false, class = "case mismatch",
        reason = "B0 ledger case mismatch (got $(repr(c)))")
    s = get(snap.data, "status", nothing)
    s == expected_status || return (ok = false, class = "status mismatch",
        reason = "B0 ledger status $(repr(s)) != $expected_status")
    snap.sha == expected_sha || return (ok = false, class = "sha drift",
        reason = "B0 ledger sha $(snap.sha) != reviewed $(expected_sha)")
    (ok = true, class = "green", reason = "")
end

function s1_derive_patched(orig_text)
    iss = String[]
    lines = split(orig_text, '\n'; keepempty = true)
    hits = findall(==(S1_PATCH_ANCHOR), lines)
    length(hits) == 1 ||
        (push!(iss, "patch anchor not exactly once ($(length(hits)))");
         return (iss, nothing))
    occursin("ensure_updated_state", orig_text) &&
        (push!(iss, "original source already references ensure_updated_state");
         return (iss, nothing))
    patched = vcat(lines[1:hits[1]], [S1_PATCH_LINE], lines[hits[1]+1:end])
    (iss, join(patched, '\n'))
end

# --- sbatch generation ------------------------------------------------------------

function s1_make_sbatch(tree)
    # per-arm staging rows: init/eval2/gpoints staged into BOTH arm work
    # dirs from the same pinned originals, each copy re-verified
    stage_rows = String[]
    for (sha, sz, path) in S1_DATA_INPUTS
        push!(stage_rows, "$sha $sz $path \$RUNROOT/data/evaluation1/lw_fluxes/$(basename(path))")
    end
    for arm in ("a0a", "a0b", "s1")
        for (sha, sz, path, rel) in S1_WORK_INPUTS
            push!(stage_rows, "$sha $sz $path \$RUNROOT/work-$arm/$rel/$(basename(path))")
        end
    end
    stage_lines = join(stage_rows, "\n")
    hash_lines = join(vcat(
        ["$sha  $path" for (sha, _, path) in S1_DATA_INPUTS],
        ["$sha  $path" for (sha, _, path, _) in S1_WORK_INPUTS],
        ["$sha  $path" for (sha, _, path) in S1_V12_TEST_PINS],
        ["$S1_MINIMIZER_H_SHA  $S1_MINIMIZER_H",
         "$S1_LIBADEPT_SHA  $S1_LIBADEPT"]), "\n")
    size_lines = join(vcat(
        ["$sz $path" for (_, sz, path) in S1_DATA_INPUTS],
        ["$sz $path" for (_, sz, path, _) in S1_WORK_INPUTS],
        ["$sz $path" for (_, sz, path) in S1_V12_TEST_PINS]), "\n")
    gate_pins = join(vcat(
        ["$(s1_sha(joinpath(S1_PROJECT_ROOT, f)))  $(joinpath(S1_PROJECT_ROOT, f))"
         for f in ("validation/gate4_quota_guard.sh",
                   "validation/gate4_s1_state_sync_checkpoint.jl",
                   "validation/validation_results.jl")],
        ["$S1_B0_LEDGER_SHA  $S1_B0_LEDGER",
         "$S1_FL5_SHA  $S1_FL5_JSON"]), "\n")
    # full-tree manifests (monitor blocker 2)
    artifact_tree_lines = join(["$(e.sha)  $S1_SRC_ARTIFACT/$(e.rel)"
                                for e in tree], "\n")
    copy_tree_lines = join(["$(e.sha)  $(e.rel)" for e in tree], "\n")
    postpatch_tree_lines = join(
        ["$(e.rel == S1_SOLVE_ADEPT_REL ? S1_PATCHED_SOLVE_ADEPT_SHA : e.sha)  $(e.rel)"
         for e in tree], "\n")
    execbit_lines = join(["$(e.exec ? 1 : 0) $(e.rel)" for e in tree], "\n")
    toolchain_checks = join([begin
        V = uppercase(replace(t, "+" => "X"))
        """
$(V)_P=\$(command -v $t) || { echo "REFUSED: $t missing" >&2; exit 65; }
[ "\$$(V)_P" = "$p" ] || { echo "REFUSED: $t path \$$(V)_P != pinned $p" >&2; exit 65; }
$(V)_FULL=\$($t --version); $(V)_L1=\${$(V)_FULL%%\$'\\n'*}
[ "\$$(V)_L1" = "$l1" ] || { echo "REFUSED: $t version line '\$$(V)_L1' != pinned '$l1'" >&2; exit 65; }"""
    end for (t, p, l1) in S1_TOOLCHAIN], "\n")
    adept_banner_3000 = "Optimizing coefficients with Adept LBFGS " *
        "algorithm: max iterations = 3000, convergence criterion = 0.02"
    """
#!/bin/bash
#SBATCH --job-name=g4-s1-lw-paired-sync
#SBATCH --output=$S1_LOG_DIR/g4-s1-lw-%j.log
#SBATCH --time=06:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=36
#SBATCH --mem=60G
#SBATCH --partition=cpu-large

# Gate-4 S1: TRIPLE-ARM state-sync hypothesis test (DIAGNOSIS unit;
# PRIVATE output only). Generated by gate4_s1_state_sync_checkpoint.jl.
# One source copy, two sequential builds, three sequential runs: A0a
# and A0b share the saved pristine binary (baseline repeatability /
# noise floor), S1 runs the one-line-patched binary; each arm has an
# independently cloned input/work/testcopy set and identical explicit
# OpenMP controls. ZERO canonical writes; RUNROOT preserved on success
# AND failure.
set -euo pipefail
if [ -z "\${SLURM_JOB_ID:-}" ]; then
    echo "REFUSED: head-node execution is not permitted; submit via sbatch." >&2
    exit 64
fi
case "\$SLURM_JOB_ID" in
    ''|*[!0-9]*) echo "REFUSED: SLURM_JOB_ID is not a positive integer" >&2; exit 64;;
esac

G4WORK=$S1_G4WORK
RUNROOT="\$G4WORK/g4-diag/\${SLURM_JOB_ID}/lw-s1"
SRCDIR="\$RUNROOT/src/ecckd-modern-paired"

echo "=== S1-lw stage 0a: gate-code identity (verify BEFORE sourcing) ==="
sha256sum -c <<'GATEPINS' || { echo "REFUSED: gate code/reviewed prerequisite ledgers changed since generation; regenerate the checkpoint" >&2; exit 75; }
$gate_pins
GATEPINS

echo "=== S1-lw stage 0b: quota health (read-only) ==="
source $S1_PROJECT_ROOT/validation/gate4_quota_guard.sh
quota_health \$((5*1024*1024*1024)) || { echo "REFUSED: quota not healthy" >&2; exit 67; }

echo "=== S1-lw stage 0c: pinned inputs + FULL artifact tree manifest + fail-closed toolchain ==="
sha256sum -c <<'HASHES' || { echo "REFUSED: pinned input/toolchain hash mismatch" >&2; exit 69; }
$hash_lines
HASHES
while read -r esz p; do
    asz=\$(stat -Lc %s "\$p") || { echo "REFUSED: cannot stat pinned input \$p" >&2; exit 69; }
    [ "\$asz" = "\$esz" ] || { echo "REFUSED: pinned input size mismatch \$p (\$asz != \$esz)" >&2; exit 69; }
done <<'SIZES'
$size_lines
SIZES
# complete 119-file artifact tree: content manifest, zero symlinks,
# executable-bit manifest (asserted BEFORE any copy)
sha256sum -c <<'ARTTREE' >/dev/null || { echo "REFUSED: artifact tree content manifest mismatch" >&2; exit 69; }
$artifact_tree_lines
ARTTREE
[ "\$(find "$S1_SRC_ARTIFACT" \\( -type f -o -type l \\) | wc -l)" = "$S1_TREE_FILES" ] || { echo "REFUSED: artifact tree file census != $S1_TREE_FILES" >&2; exit 69; }
[ "\$(find "$S1_SRC_ARTIFACT" -type l | wc -l)" = 0 ] || { echo "REFUSED: unexpected symlink in artifact tree" >&2; exit 69; }
while read -r xf rel; do
    if [ "\$xf" = 1 ]; then
        [ -x "$S1_SRC_ARTIFACT/\$rel" ] || { echo "REFUSED: artifact exec bit lost: \$rel" >&2; exit 69; }
    else
        [ ! -x "$S1_SRC_ARTIFACT/\$rel" ] || { echo "REFUSED: artifact exec bit gained: \$rel" >&2; exit 69; }
    fi
done <<'EXECBITS'
$execbit_lines
EXECBITS
[ "\$(grep -c 'ensure_updated_state' "$S1_MINIMIZER_H" || true)" -ge 1 ] || { echo "REFUSED: installed Minimizer.h lacks ensure_updated_state" >&2; exit 69; }
$toolchain_checks
AM_FULL=\$(automake --version); AM_LINE1=\${AM_FULL%%\$'\\n'*}; AM_V=\${AM_LINE1##* }
LT_FULL=\$(libtoolize --version); LT_LINE1=\${LT_FULL%%\$'\\n'*}; LT_V=\${LT_LINE1##* }
[ "\$AM_V" = "$S1_AUTOMAKE_VER" ] || { echo "REFUSED: automake \$AM_V != pinned $S1_AUTOMAKE_VER" >&2; exit 65; }
[ "\$LT_V" = "$S1_LIBTOOLIZE_VER" ] || { echo "REFUSED: libtoolize \$LT_V != pinned $S1_LIBTOOLIZE_VER" >&2; exit 65; }

echo "=== S1-lw stage 0d: S1 experiment lock (duplicate-diagnosis guard) ==="
mkdir -p "\$G4WORK/locks"
exec 9>"\$G4WORK/locks/s1-lw.lock"
flock -n 9 || { echo "REFUSED: another S1-lw diagnosis job holds the lock" >&2; exit 73; }

echo "=== S1-lw stage 1: job-private RUNROOT + per-arm scientific-input snapshot ==="
[ ! -e "\$RUNROOT" ] || { echo "REFUSED: RUNROOT already exists: \$RUNROOT" >&2; exit 72; }
mkdir -p "\$RUNROOT/data/evaluation1/lw_fluxes" "\$RUNROOT/src" "\$RUNROOT/bin" "\$RUNROOT/tools"
for arm in a0a a0b s1; do
    mkdir -p "\$RUNROOT/work-\$arm/lw_lbl_fluxes" \\
             "\$RUNROOT/work-\$arm/lw_raw-ckd-definition" \\
             "\$RUNROOT/work-\$arm/lw_ckd-definition" \\
             "\$RUNROOT/work-\$arm/lw_gpoints"
done
while read -r esha esz src dst; do
    cp -L -- "\$src" "\$dst" || { echo "REFUSED: staging copy failed: \$src" >&2; exit 76; }
    asz=\$(stat -Lc %s "\$dst") || { echo "REFUSED: cannot stat staged copy \$dst" >&2; exit 76; }
    [ "\$asz" = "\$esz" ] || { echo "REFUSED: staged copy size mismatch \$dst (\$asz != \$esz)" >&2; exit 76; }
    echo "\$esha  \$dst" | sha256sum -c - >/dev/null || { echo "REFUSED: staged copy hash mismatch: \$dst" >&2; exit 76; }
done <<STAGE
$stage_lines
STAGE
echo "per-arm staged scientific-input snapshots verified under \$RUNROOT"

echo "=== S1-lw stage 2: writable source copy + full-tree content identity ==="
mkdir -p "\$SRCDIR"
cp -rT "$S1_SRC_ARTIFACT" "\$SRCDIR"
chmod -R u+w "\$SRCDIR"
( cd "\$SRCDIR" && sha256sum -c <<'COPYTREE' >/dev/null ) || { echo "REFUSED: copied tree content manifest mismatch" >&2; exit 69; }
$copy_tree_lines
COPYTREE
[ "\$(find "\$SRCDIR" -type l | wc -l)" = 0 ] || { echo "REFUSED: unexpected symlink in copied tree" >&2; exit 69; }
while read -r xf rel; do
    if [ "\$xf" = 1 ]; then
        [ -x "\$SRCDIR/\$rel" ] || { echo "REFUSED: copy exec bit lost: \$rel" >&2; exit 69; }
    else
        [ ! -x "\$SRCDIR/\$rel" ] || { echo "REFUSED: copy exec bit gained: \$rel" >&2; exit 69; }
    fi
done <<'EXECBITS2'
$execbit_lines
EXECBITS2
cp -- "\$SRCDIR/$S1_SOLVE_ADEPT_REL" "\$RUNROOT/solve_adept.cpp.orig"
# FROZEN TEST TEMPLATE (TOCTOU fix): arms NEVER read the live mutable
# artifact again; the template snapshots the just-content-verified copy,
# is re-verified against the pinned test files, and made read-only
cp -r "\$SRCDIR/test" "\$RUNROOT/test-template"
sha256sum -c <<TEMPLATEPINS >/dev/null || { echo "REFUSED: frozen test-template pin mismatch" >&2; exit 69; }
$(join(["$sha  \$RUNROOT/test-template/$(basename(path))"
        for (sha, _, path) in S1_V12_TEST_PINS], "\n"))
TEMPLATEPINS
chmod -R a-w "\$RUNROOT/test-template"

echo "=== S1-lw stage 3: A0 pristine control build (corrected fresh-autoreconf recipe; build-enablement, not historical equivalence) ==="
cd "\$SRCDIR"
autoreconf -i
$S1_CONFIGURE_ARGV
make -j"\$SLURM_CPUS_PER_TASK"
test -x "\$SRCDIR/src/ecckd/optimize_lut" || { echo "REFUSED: A0 optimize_lut not built" >&2; exit 68; }
[ "\$(strings "\$SRCDIR/src/ecckd/optimize_lut" | grep -cF 'Adept LBFGS' || true)" -ge 1 ] || { echo "REFUSED: Adept LBFGS banner string absent from A0 binary" >&2; exit 68; }
cp -- "\$SRCDIR/src/ecckd/optimize_lut" "\$RUNROOT/bin/optimize_lut_a0"
chmod a-w "\$RUNROOT/bin/optimize_lut_a0"
cp -- "\$SRCDIR/config.log" "\$RUNROOT/config.log.a0"
./config.status --config > "\$RUNROOT/config.status.config.txt"
echo "--- config.status --config (all arms; single configure) ---"
cat "\$RUNROOT/config.status.config.txt"
# assert the config.status rendering EXACTLY matches the corrected
# reviewed recipe (path-only LDFLAGS + late LIBS=-ladept)
[ "\$(cat "\$RUNROOT/config.status.config.txt")" = "$S1_CONFIG_STATUS_EXPECT" ] || { echo "REFUSED: config.status --config != corrected reviewed recipe rendering" >&2; exit 68; }
sha256sum "\$RUNROOT/bin/optimize_lut_a0" "\$RUNROOT/config.log.a0" "\$RUNROOT/config.status.config.txt"
echo "historical 4515 pre-existing binary (informational echo only): $S1_4515_BINARY_SHA"

echo "=== S1-lw stage 4: EXACTLY ONE anchored sync-line patch + post-patch REGISTERED-FILE identity (119 artifact files; generated build files out of scope) ==="
SA="\$SRCDIR/$S1_SOLVE_ADEPT_REL"
echo "$S1_ORIG_SOLVE_ADEPT_SHA  \$SA" | sha256sum -c - >/dev/null || { echo "REFUSED: pre-patch solve_adept.cpp sha drift" >&2; exit 69; }
[ "\$(grep -cxF '$S1_PATCH_ANCHOR' "\$SA" || true)" = 1 ] || { echo "REFUSED: patch anchor not exactly once" >&2; exit 69; }
[ "\$(grep -c 'ensure_updated_state' "\$SA" || true)" = 0 ] || { echo "REFUSED: source already references ensure_updated_state" >&2; exit 69; }
sed -i 's|^  minimizer.set_converged_gradient_norm(convergence_criterion);\$|&\\n  minimizer.ensure_updated_state(1);|' "\$SA"
[ "\$(grep -cxF '$S1_PATCH_LINE' "\$SA" || true)" = 1 ] || { echo "REFUSED: sync line not inserted exactly once" >&2; exit 69; }
echo "$S1_PATCHED_SOLVE_ADEPT_SHA  \$SA" | sha256sum -c - >/dev/null || { echo "REFUSED: patched solve_adept.cpp sha != pinned" >&2; exit 69; }
[ "\$(sed -n '305,320p' "\$SA" | sha256sum | cut -d' ' -f1)" = "$S1_PATCHED_REGION_SHA" ] || { echo "REFUSED: patched insertion-region hash mismatch" >&2; exit 69; }
ORIG_LC=\$(wc -l < "\$RUNROOT/solve_adept.cpp.orig")
NEW_LC=\$(wc -l < "\$SA")
[ "\$NEW_LC" = "\$((ORIG_LC + 1))" ] || { echo "REFUSED: patch changed \$((NEW_LC - ORIG_LC)) lines, expected exactly 1" >&2; exit 69; }
# AMONG THE 119 REGISTERED ARTIFACT FILES, only solve_adept.cpp
# changed (manifest with exactly that one entry substituted). This does
# NOT prove literal whole-working-tree identity or the absence of
# generated extras: stage-3 autoreconf/make legitimately creates
# generated/build files outside the registered manifest. The pre-build
# stage-2 census remains the exact whole-copied-tree gate.
( cd "\$SRCDIR" && sha256sum -c <<'POSTPATCHTREE' >/dev/null ) || { echo "REFUSED: post-patch tree differs beyond the registered one-line change" >&2; exit 69; }
$postpatch_tree_lines
POSTPATCHTREE
echo "--- one-line unified diff (the ONLY scientific source change) ---"
diff -u "\$RUNROOT/solve_adept.cpp.orig" "\$SA" || true

echo "=== S1-lw stage 5: S1 patched rebuild (same tree/configure/toolchain) ==="
make -j"\$SLURM_CPUS_PER_TASK"
test -x "\$SRCDIR/src/ecckd/optimize_lut" || { echo "REFUSED: S1 optimize_lut not built" >&2; exit 68; }
cp -- "\$SRCDIR/src/ecckd/optimize_lut" "\$RUNROOT/bin/optimize_lut_s1"
chmod a-w "\$RUNROOT/bin/optimize_lut_s1"
cp -- "\$SRCDIR/config.log" "\$RUNROOT/config.log.s1"
A0_BIN_SHA=\$(sha256sum "\$RUNROOT/bin/optimize_lut_a0" | cut -d' ' -f1)
S1_BIN_SHA=\$(sha256sum "\$RUNROOT/bin/optimize_lut_s1" | cut -d' ' -f1)
echo "A0 binary: \$A0_BIN_SHA"
echo "S1 binary: \$S1_BIN_SHA"
# NECESSARY sanity only: identical binaries prove the patch did NOT
# change the executable; differing binaries do NOT by themselves prove
# the patch (timestamps can differ) -- the patch proof is the tree
# identity + patched-file pin + rebuild semantics above
[ "\$A0_BIN_SHA" != "\$S1_BIN_SHA" ] || { echo "REFUSED: A0 and S1 binaries identical; the patch did not enter the binary" >&2; exit 68; }

echo "=== S1-lw stage 6: per-arm wrappers (Netlib preload + FP-trap shim) + loader proofs ==="
sha256sum -c <<'RUNTIMEPINS' || { echo "REFUSED: runtime BLAS/LAPACK/shim pin mismatch" >&2; exit 79; }
$S1_NETLIB_BLAS_SHA  $S1_NETLIB_BLAS
$S1_NETLIB_LAPACK_SHA  $S1_NETLIB_LAPACK
$S1_SHIM_SO_SHA  $S1_SHIM_SO
RUNTIMEPINS
command -v readelf >/dev/null || { echo "MISSING readelf" >&2; exit 65; }
RE_BLAS=\$(readelf -d "$S1_NETLIB_BLAS")
RE_LAPACK=\$(readelf -d "$S1_NETLIB_LAPACK")
[ "\$(grep -cF 'Library soname: [libblas.so.3]' <<<"\$RE_BLAS" || true)" = 1 ] || { echo "REFUSED: netlib BLAS SONAME != libblas.so.3" >&2; exit 79; }
[ "\$(grep -cF 'Library soname: [liblapack.so.3]' <<<"\$RE_LAPACK" || true)" = 1 ] || { echo "REFUSED: netlib LAPACK SONAME != liblapack.so.3" >&2; exit 79; }
# one wrapper per ARM; A0a and A0b exec the SAME saved pristine binary
for arm in a0a a0b s1; do
    case "\$arm" in a0a|a0b) BINARM=a0;; s1) BINARM=s1;; esac
    W="\$RUNROOT/tools/optimize_lut_wrap_\$arm"
    cat > "\$W" <<WRAP
#!/bin/bash
export LD_PRELOAD="$S1_NETLIB_BLAS:$S1_NETLIB_LAPACK:$S1_SHIM_SO"
exec "\$RUNROOT/bin/optimize_lut_\$BINARM" "\\\$@"
WRAP
    chmod +x "\$W"
    sha256sum "\$W"
    [ "\$(grep -cxF 'export LD_PRELOAD="$S1_NETLIB_BLAS:$S1_NETLIB_LAPACK:$S1_SHIM_SO"' "\$W" || true)" = 1 ] || { echo "REFUSED: wrapper preload line/order drifted (\$arm)" >&2; exit 79; }
done
for b in a0 s1; do
    LDD_OUT=\$(LD_PRELOAD="$S1_NETLIB_BLAS:$S1_NETLIB_LAPACK:$S1_SHIM_SO" ldd "\$RUNROOT/bin/optimize_lut_\$b")
    echo "--- ldd (binary \$b) ---"
    echo "\$LDD_OUT"
    [ "\$(grep -cF "$S1_NETLIB_BLAS" <<<"\$LDD_OUT" || true)" = 1 ] || { echo "REFUSED: exact BLAS preload row count != 1 (\$b)" >&2; exit 79; }
    [ "\$(grep -cF "$S1_NETLIB_LAPACK" <<<"\$LDD_OUT" || true)" = 1 ] || { echo "REFUSED: exact LAPACK preload row count != 1 (\$b)" >&2; exit 79; }
    [ "\$(grep -cF 'liblapack.so.3 =>' <<<"\$LDD_OUT" || true)" = 0 ] || { echo "REFUSED: liblapack.so.3 alias row present (\$b)" >&2; exit 79; }
    [ "\$(grep -cF 'libblas.so.3 =>' <<<"\$LDD_OUT" || true)" = 0 ] || { echo "REFUSED: libblas.so.3 alias row present (\$b)" >&2; exit 79; }
    LN_B=\$(awk -v pat="$S1_NETLIB_BLAS" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
    LN_L=\$(awk -v pat="$S1_NETLIB_LAPACK" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
    LN_S=\$(awk -v pat="$S1_SHIM_SO" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
    { [ -n "\$LN_B" ] && [ -n "\$LN_L" ] && [ -n "\$LN_S" ] && [ "\$LN_B" -lt "\$LN_L" ] && [ "\$LN_L" -lt "\$LN_S" ]; } || { echo "REFUSED: preload row order is not BLAS<LAPACK<H5shim (\$b)" >&2; exit 79; }
done

# SANDWICH EXECUTION ORDER (monitor refinement): A0a -> S1 -> A0b, so
# the repeated pristine control brackets the treatment in time; both
# binaries are saved and immutable before any run
for arm in a0a s1 a0b; do
    echo "=== S1-lw stage 7-\$arm: \$arm relative-base run (bounds ON; identical staged inputs; explicit OpenMP controls) ==="
    TC="\$RUNROOT/testcopy-\$arm"
    cp -r "\$RUNROOT/test-template" "\$TC"
    chmod -R u+w "\$TC"
    cd "\$TC"
    sed 's/@PACKAGE_VERSION@/1.2/g' version.h.in > version.h
    sed -i \\
      -e "s|^CKDMIP_DIR=.*|CKDMIP_DIR=/shared/home/greg/build/ckdmip-1.0|" \\
      -e "s|^CKDMIP_DATA_DIR=.*|CKDMIP_DATA_DIR=\$RUNROOT/data|" \\
      -e "s|^WORK_DIR=.*|WORK_DIR=\$RUNROOT/work-\$arm|" \\
      -e "s|^BINDIR=.*|BINDIR=\$RUNROOT/bin|" \\
      -e "s|^TRAINING_BOTH=no\$|TRAINING_BOTH=yes|" \\
      -e "s|^OPTIMIZE_LUT=.*|OPTIMIZE_LUT=\$RUNROOT/tools/optimize_lut_wrap_\$arm|" \\
      config.h
    for kv in "CKDMIP_DIR=/shared/home/greg/build/ckdmip-1.0" "CKDMIP_DATA_DIR=\$RUNROOT/data" "WORK_DIR=\$RUNROOT/work-\$arm" "BINDIR=\$RUNROOT/bin" "TRAINING_BOTH=yes" "OPTIMIZE_LUT=\$RUNROOT/tools/optimize_lut_wrap_\$arm"; do
        grep -qxF "\$kv" config.h || { echo "BAD config override (\$arm): \$kv" >&2; exit 68; }
    done
    sed -i 's|^[[:space:]]*test "\\\${PIPESTATUS\\[0\\]}" -eq 0[[:space:]]*\$|\\trc="\${PIPESTATUS[0]}"; if [ "\$rc" -ne 0 ]; then if [ "\$rc" -ge 128 ]; then echo "OPTIMIZE_LUT CHILD KILLED BY SIGNAL \$((rc-128)) (rc=\$rc)" >\\&2; else echo "OPTIMIZE_LUT CHILD FAILED rc=\$rc" >\\&2; fi; exit "\$rc"; fi|' optimize_lut_lw.sh
    grep -q "OPTIMIZE_LUT CHILD" optimize_lut_lw.sh || { echo "BAD sed: child-status surfacing not applied (\$arm)" >&2; exit 68; }
    grep -qF 'test "\${PIPESTATUS[0]}" -eq 0' optimize_lut_lw.sh && { echo "BAD sed: raw PIPESTATUS test remains (\$arm)" >&2; exit 68; } || true
    echo "arm \$arm: OMP_NUM_THREADS=\$SLURM_CPUS_PER_TASK OMP_DYNAMIC=FALSE SLURM_CPUS_PER_TASK=\$SLURM_CPUS_PER_TASK" | tee "\$RUNROOT/\$arm-base-run.log"
    OMP_NUM_THREADS="\$SLURM_CPUS_PER_TASK" OMP_DYNAMIC=FALSE \\
        APPLICATION=climate BAND_STRUCTURE=fsck TOLERANCE=0.0161 \\
        bash optimize_lut_lw.sh relative-base |& tee -a "\$RUNROOT/\$arm-base-run.log"
    [ "\$(grep -cF '$adept_banner_3000' "\$RUNROOT/\$arm-base-run.log" || true)" = 1 ] || { echo "REFUSED: \$arm run did not show exactly one Adept banner (3000/0.02)" >&2; exit 71; }
    [ "\$(grep -cF 'Minimization is bounded' "\$RUNROOT/\$arm-base-run.log" || true)" = 1 ] || { echo "REFUSED: \$arm run did not log bounded mode" >&2; exit 71; }
    [ "\$(grep -cF 'number bounded below:' "\$RUNROOT/\$arm-base-run.log" || true)" = 1 ] || { echo "REFUSED: \$arm bounded-census line not exactly once" >&2; exit 71; }
    [ "\$(grep -cF 'Optimizing coefficients of: composite h2o o3 co2' "\$RUNROOT/\$arm-base-run.log" || true)" = 1 ] || { echo "REFUSED: \$arm base gas banner not exactly once" >&2; exit 71; }
done

echo "=== S1-lw stage 8: private outputs (independent schema verification; ZERO canonical writes by design) ==="
for arm in a0a a0b s1; do
    R2="\$RUNROOT/work-\$arm/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
    test -s "\$R2" || { echo "MISSING \$arm raw2 output" >&2; exit 71; }
    (cd $S1_PROJECT_ROOT && RAW2_PATH="\$R2" julia --project=test -e '
using NCDatasets
core = ["band_number", "cfc11_conc_dependence_code",
    "cfc11_molar_absorption_coeff", "cfc12_conc_dependence_code",
    "cfc12_molar_absorption_coeff", "ch4_conc_dependence_code",
    "ch4_molar_absorption_coeff", "ch4_reference_mole_fraction",
    "co2_conc_dependence_code", "co2_molar_absorption_coeff",
    "composite_conc_dependence_code", "composite_molar_absorption_coeff",
    "composite_mole_fraction", "gpoint_fraction",
    "h2o_conc_dependence_code", "h2o_molar_absorption_coeff",
    "h2o_mole_fraction", "n2o_conc_dependence_code",
    "n2o_molar_absorption_coeff", "n2o_reference_mole_fraction",
    "n_gases", "o3_conc_dependence_code", "o3_molar_absorption_coeff",
    "planck_function", "pressure", "temperature", "temperature_planck",
    "wavenumber1", "wavenumber1_band", "wavenumber2", "wavenumber2_band"]
mm = [g * "_molar_absorption_coeff_" * s for g in
      ("cfc11", "cfc12", "ch4", "co2", "composite", "h2o", "n2o", "o3")
      for s in ("min", "max")]
expected = sort(vcat(core, mm))
bad = String[]
NCDataset(ENV["RAW2_PATH"]) do ds
    for (d, v) in (("g_point", 32), ("pressure", 53), ("temperature", 6),
                   ("composite_gas", 4), ("h2o_mole_fraction", 12), ("band", 1))
        (haskey(ds.dim, d) && ds.dim[d] == v) ||
            push!(bad, "dim " * d * " != " * string(v))
    end
    have = sort([String(k) for k in keys(ds)])
    for v in setdiff(expected, have)
        push!(bad, "var missing: " * v)
    end
    for v in setdiff(have, expected)
        push!(bad, "unexpected extra var: " * v)
    end
    for k in have
        a = try
            Array(ds[k])
        catch
            push!(bad, "unreadable var " * String(k))
            continue
        end
        length(a) > 0 || push!(bad, "var empty: " * String(k))
        eltype(a) <: Union{Missing, Real} || continue
        (!any(ismissing, a) && all(isfinite, skipmissing(a))) ||
            push!(bad, "nonfinite/missing values in " * String(k))
    end
end
isempty(bad) || (foreach(println, bad); exit(1))
println("raw2 independent schema/finite verification passed")
') || { echo "REFUSED: \$arm raw2 failed independent netCDF schema/finite verification" >&2; exit 71; }
    sha256sum "\$R2"
done
A0A_R2="\$RUNROOT/work-a0a/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
A0B_R2="\$RUNROOT/work-a0b/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
S1_R2="\$RUNROOT/work-s1/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
if cmp -s "\$A0A_R2" "\$A0B_R2"; then
    echo "BASELINE REPEATABILITY: A0a and A0b raw2 are BYTE-IDENTICAL (determinism established across the treatment interval)"
else
    echo "BASELINE REPEATABILITY: A0a and A0b raw2 DIFFER (baseline repeatability failed; byte-level treatment inference INCONCLUSIVE; S1 metrics descriptive only)"
fi
if cmp -s "\$A0A_R2" "\$S1_R2"; then
    echo "PRIMARY COMPARISON: S1 and A0a raw2 are BYTE-IDENTICAL"
else
    echo "PRIMARY COMPARISON: S1 and A0a raw2 DIFFER (interpretation conditional on baseline repeatability; census/objective deltas decide post-terminal)"
fi
echo "secondary bridge target (4515 modern raw2; informational echo only): $S1_MODERN_RAW2_SHA"
sha256sum "\$RUNROOT/a0a-base-run.log" "\$RUNROOT/a0b-base-run.log" "\$RUNROOT/s1-base-run.log" "\$RUNROOT/solve_adept.cpp.orig" "\$SRCDIR/$S1_SOLVE_ADEPT_REL" "\$RUNROOT/bin/optimize_lut_a0" "\$RUNROOT/bin/optimize_lut_s1"
echo "RUNROOT preserved for diagnosis/forensics: \$RUNROOT (no cleanup by design)"
echo "=== S1-lw done \$(date -u +%FT%TZ) ==="
"""
end

# --- text gates -------------------------------------------------------------------

function s1_bash_syntax_ok(text)
    try
        p = joinpath(mktempdir(), "s1_syntax_check.sbatch")
        write(p, text)
        success(pipeline(`bash -n $p`, stdout = devnull, stderr = devnull))
    catch
        false
    end
end

function s1_text_gate_issues(text)
    iss = String[]
    req = [
        "REFUSED: head-node execution is not permitted",
        "RUNROOT=\"\$G4WORK/g4-diag/\${SLURM_JOB_ID}/lw-s1\"",
        "cp -rT \"$S1_SRC_ARTIFACT\" \"\$SRCDIR\"",
        S1_ORIG_SOLVE_ADEPT_SHA,
        S1_PATCHED_SOLVE_ADEPT_SHA,
        S1_PATCHED_REGION_SHA,
        S1_PATCH_LINE,
        "solve_adept.cpp.orig",
        "diff -u",
        "autoreconf -i",
        S1_CONFIGURE_ARGV,
        "optimize_lut_a0",
        "optimize_lut_s1",
        "chmod a-w \"\$RUNROOT/bin/optimize_lut_a0\"",
        "chmod a-w \"\$RUNROOT/bin/optimize_lut_s1\"",
        "config.status --config",
        "REFUSED: A0 and S1 binaries identical",
        "ARTTREE",
        "COPYTREE",
        "POSTPATCHTREE",
        "EXECBITS",
        "/usr/bin/gcc",
        "gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0",
        "GNU Make 4.3",
        "bash optimize_lut_lw.sh relative-base",
        "TRAINING_BOTH=yes",
        "APPLICATION=climate BAND_STRUCTURE=fsck TOLERANCE=0.0161",
        "Minimization is bounded",
        "number bounded below:",
        "PRIMARY COMPARISON",
        "BASELINE REPEATABILITY",
        "OMP_NUM_THREADS=\"\$SLURM_CPUS_PER_TASK\" OMP_DYNAMIC=FALSE",
        "REFUSED: config.status --config != corrected reviewed recipe rendering",
        S1_CONFIG_STATUS_EXPECT,
        "'LDFLAGS=-L$S1_ADEPT/lib -Wl,-rpath,$S1_ADEPT/lib'",
        "'LIBS=-ladept'",
        S1_FL5_SHA,
        S1_MODERN_RAW2_SHA,
        S1_4515_BINARY_SHA,
        "raw2 independent schema/finite verification passed",
        "RUNROOT preserved for diagnosis/forensics",
        "flock -n 9",
        # TOCTOU fix: arms clone ONLY the frozen read-only template
        "cp -r \"\$SRCDIR/test\" \"\$RUNROOT/test-template\"",
        "TEMPLATEPINS",
        "chmod -R a-w \"\$RUNROOT/test-template\"",
        "cp -r \"\$RUNROOT/test-template\" \"\$TC\"",
        "index(\$0, pat) && !ln { ln = NR }"]
    for r in req
        occursin(r, text) || push!(iss, "required text missing: $r")
    end
    # the live artifact test dir must NEVER be read after stage 0
    occursin("cp -r \"$S1_SRC_ARTIFACT/test\"", text) &&
        push!(iss, "forbidden stage-7 copy from the LIVE artifact test dir")
    # single relative-base invocation inside the sandwich-ordered arm loop
    n = length(collect(eachmatch(r"bash optimize_lut_lw\.sh relative-base", text)))
    n == 1 || push!(iss, "expected exactly 1 relative-base invocation (arm loop), got $n")
    n = length(collect(eachmatch(r"for arm in a0a a0b s1; do", text)))
    n == 3 || push!(iss, "expected exactly 3 a0a/a0b/s1 loops (mkdir/wrappers/outputs), got $n")
    n = length(collect(eachmatch(r"for arm in a0a s1 a0b; do", text)))
    n == 1 || push!(iss, "expected exactly 1 SANDWICH-ordered run loop (a0a s1 a0b), got $n")
    n = length(collect(eachmatch(r"for b in a0 s1; do", text)))
    n == 1 || push!(iss, "expected exactly 1 per-binary ldd loop, got $n")
    # exact occurrence counts (never mere substring presence) for the
    # corrected configure invocation and the config.status expectation
    n = length(collect(eachmatch(Regex("\\Q" * S1_CONFIGURE_ARGV * "\\E"), text)))
    n == 1 || push!(iss, "corrected configure invocation not exactly once ($n)")
    n = length(collect(eachmatch(Regex("\\Q" * S1_CONFIG_STATUS_EXPECT * "\\E"), text)))
    n == 1 || push!(iss, "config.status expectation not exactly once ($n)")
    n = length(collect(eachmatch(Regex("\\Q'LIBS=-ladept'\\E"), text)))
    n == 1 || push!(iss, "quoted LIBS assignment not exactly once ($n)")
    n = length(collect(eachmatch(Regex("\\Q" * S1_PATCH_LINE * "\\E"), text)))
    n == 2 || push!(iss, "sync line must appear exactly twice (sed payload + count assert), got $n")
    for bad in ("relative-ch4", "relative-n2o", "relative-cfc",
                "CANON_FINAL", "mv -n", ".g3.publish.",
                "$S1_G4WORK/work/lw_ckd-definition/ecckd-1.2_lw_ckd-definition")
        occursin(bad, text) && push!(iss, "forbidden text present: $bad")
    end
    # user LDFLAGS must be path+rpath ONLY; -ladept inside LDFLAGS is
    # the wrong (early, order-broken) position and is banned
    for m in eachmatch(r"LDFLAGS=[^']*-ladept", text)
        push!(iss, "-ladept inside LDFLAGS (order-broken position): $(m.match)")
    end
    for m in eachmatch(r"\|\s*head\b", text)
        push!(iss, "early-closing head pipeline present: $(m.match)")
    end
    for m in eachmatch(r"(?m)^.*\bstrings\b.*Adept LBFGS.*= 0.*$", text)
        push!(iss, "binary strings Adept-absence test (banned class): $(m.match)")
    end
    for m in eachmatch(r"(?m)^[^#\n]*> *\"?\$G4WORK/(?!g4-diag|locks/s1-lw\.lock)", text)
        push!(iss, "redirect toward shared G4WORK area: $(m.match)")
    end
    iss
end

# --- fixtures -----------------------------------------------------------------------

function s1_fixtures(tree)
    t = Dict{String, Bool}()
    fx = mktempdir()
    shaof(p) = bytes2hex(sha256(read(p)))

    cls(p; kw...) = s1_classify_ledger(p; kw...)
    t["ledger_missing_refuses"] =
        cls(joinpath(fx, "absent.json")).class == "missing"
    p = joinpath(fx, "bad.json"); write(p, "{oops")
    t["ledger_unparseable_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "unparseable (parse failure)"
    p = joinpath(fx, "st.json")
    write(p, JSON.json(Dict("case" => S1_B0_LEDGER_CASE,
                            "status" => "b0_completion_ledger_refused")))
    t["ledger_status_mismatch_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "status mismatch"
    p = joinpath(fx, "green.json")
    write(p, JSON.json(Dict("case" => S1_B0_LEDGER_CASE,
                            "status" => S1_B0_LEDGER_STATUS)))
    t["ledger_sha_drift_refuses"] =
        cls(p; expected_sha = "0" ^ 64).class == "sha drift"
    t["ledger_green_accepted"] = cls(p; expected_sha = shaof(p)).ok

    # tree manifest: census, exec-bit count, solve_adept presence, and
    # the patched manifest differing in EXACTLY one entry
    t["tree_census_119"] = length(tree) == S1_TREE_FILES
    t["tree_exec_census_24"] = count(e -> e.exec, tree) == S1_TREE_EXEC
    sa = [e for e in tree if e.rel == S1_SOLVE_ADEPT_REL]
    t["tree_contains_solve_adept_pin"] =
        length(sa) == 1 && sa[1].sha == S1_ORIG_SOLVE_ADEPT_SHA
    t["tree_patched_manifest_single_delta"] = begin
        orig_lines = ["$(e.sha)  $(e.rel)" for e in tree]
        patched_lines = ["$(e.rel == S1_SOLVE_ADEPT_REL ?
            S1_PATCHED_SOLVE_ADEPT_SHA : e.sha)  $(e.rel)" for e in tree]
        count(orig_lines .!= patched_lines) == 1
    end

    # patch derivation (the same transformation the job applies)
    orig = read("$S1_SRC_ARTIFACT/$S1_SOLVE_ADEPT_REL", String)
    iss, patched = s1_derive_patched(orig)
    t["patch_derivation_reproduces_pin"] =
        isempty(iss) && patched !== nothing &&
        bytes2hex(sha256(patched)) == S1_PATCHED_SOLVE_ADEPT_SHA
    t["patch_region_hash_reproduces_pin"] = patched !== nothing && begin
        pl = split(patched, '\n'; keepempty = true)
        bytes2hex(sha256(join(pl[305:320], '\n') * "\n")) ==
            S1_PATCHED_REGION_SHA
    end
    t["patch_missing_anchor_refuses"] =
        !isempty(s1_derive_patched(replace(orig, S1_PATCH_ANCHOR =>
            "  // anchor removed"))[1])
    t["patch_duplicate_anchor_refuses"] =
        !isempty(s1_derive_patched(orig * "\n" * S1_PATCH_ANCHOR * "\n")[1])
    t["patch_preexisting_sync_refuses"] =
        !isempty(s1_derive_patched(replace(orig, S1_PATCH_ANCHOR =>
            S1_PATCH_ANCHOR * "\n  minimizer.ensure_updated_state(1);"))[1])

    # text gates
    text = s1_make_sbatch(tree)
    t["text_good_accepted"] = isempty(s1_text_gate_issues(text))
    t["text_missing_patch_pin_refuses"] = !isempty(s1_text_gate_issues(
        replace(text, S1_PATCHED_SOLVE_ADEPT_SHA => "0" ^ 64)))
    # corrected-recipe integrity: omission or drift of EITHER link
    # assignment refuses; -ladept smuggled into LDFLAGS refuses
    t["text_missing_ldflags_assignment_refuses"] = !isempty(s1_text_gate_issues(
        replace(text, "'LDFLAGS=-L$S1_ADEPT/lib -Wl,-rpath,$S1_ADEPT/lib'" => "")))
    t["text_missing_libs_assignment_refuses"] = !isempty(s1_text_gate_issues(
        replace(text, " 'LIBS=-ladept'" => "")))
    t["text_ladept_inside_ldflags_refuses"] = !isempty(s1_text_gate_issues(
        replace(text, "'LDFLAGS=-L$S1_ADEPT/lib -Wl,-rpath,$S1_ADEPT/lib'" =>
                      "'LDFLAGS=-L$S1_ADEPT/lib -ladept'")))
    t["text_failure_ledger_pin_drift_refuses"] = !isempty(s1_text_gate_issues(
        replace(text, S1_FL5_SHA => "0" ^ 64)))
    t["text_duplicate_configure_refuses"] = !isempty(s1_text_gate_issues(
        text * "\n" * S1_CONFIGURE_ARGV * "\n"))
    t["text_duplicate_config_status_expect_refuses"] = !isempty(
        s1_text_gate_issues(text * "\n" * S1_CONFIG_STATUS_EXPECT * "\n"))
    # failure-ledger prerequisite classifier (same guarded loader)
    fx2 = mktempdir()
    p = joinpath(fx2, "fl5.json")
    write(p, JSON.json(Dict("case" => S1_FL5_CASE,
                            "status" => S1_FL5_STATUS)))
    t["fl5_ledger_green_accepted"] = s1_classify_ledger(p;
        expected_case = S1_FL5_CASE, expected_status = S1_FL5_STATUS,
        expected_sha = shaof(p)).ok
    t["fl5_ledger_status_mismatch_refuses"] = begin
        p2 = joinpath(fx2, "fl5bad.json")
        write(p2, JSON.json(Dict("case" => S1_FL5_CASE,
                                 "status" => "s1_4555_ledger_refused")))
        s1_classify_ledger(p2; expected_case = S1_FL5_CASE,
            expected_status = S1_FL5_STATUS,
            expected_sha = shaof(p2)).class == "status mismatch"
    end
    t["text_missing_a0_save_refuses"] = !isempty(s1_text_gate_issues(
        replace(text, "chmod a-w \"\$RUNROOT/bin/optimize_lut_a0\"" => "true")))
    t["text_missing_binary_diff_assert_refuses"] = !isempty(s1_text_gate_issues(
        replace(text, "REFUSED: A0 and S1 binaries identical" => "note")))
    t["text_missing_tree_manifest_refuses"] = !isempty(s1_text_gate_issues(
        replace(text, "POSTPATCHTREE" => "SKIPPED")))
    t["text_missing_toolchain_pin_refuses"] = !isempty(s1_text_gate_issues(
        replace(text, "gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0" => "any gcc")))
    t["text_extra_pass_refuses"] = !isempty(s1_text_gate_issues(
        replace(text, "bash optimize_lut_lw.sh relative-base" =>
                      "bash optimize_lut_lw.sh relative-base relative-ch4")))
    t["text_publish_machinery_refuses"] = !isempty(s1_text_gate_issues(
        text * "\nmv -n -- x \$CANON_FINAL\n"))
    t["text_shared_redirect_refuses"] = !isempty(s1_text_gate_issues(
        text * "\necho x > \"\$G4WORK/work/evil.txt\"\n"))
    t["text_head_pipeline_refuses"] = !isempty(s1_text_gate_issues(
        text * "\nfoo --version | head -1\n"))
    t["text_extra_sync_line_refuses"] = !isempty(s1_text_gate_issues(
        text * "\n" * S1_PATCH_LINE * "\n"))
    t["text_live_artifact_testcopy_refuses"] = !isempty(s1_text_gate_issues(
        replace(text, "cp -r \"\$RUNROOT/test-template\" \"\$TC\"" =>
                      "cp -r \"$S1_SRC_ARTIFACT/test\" \"\$TC\"")))
    t["text_strings_adept_absence_refuses"] = !isempty(s1_text_gate_issues(
        text * "\n[ \"\$(strings x | grep -cF 'Adept LBFGS' || true)\" = 0 ] || exit 99\n"))
    t["bash_syntax_good_accepted"] = s1_bash_syntax_ok(text)
    t["bash_syntax_broken_refuses"] =
        !s1_bash_syntax_ok(text * "\nif true; then\n")
    t
end

# --- main -------------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()

    tree = s1_tree_manifest()
    tests = s1_fixtures(tree)
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    groups = Dict{String, Vector{String}}()

    led = s1_classify_ledger(S1_B0_LEDGER)
    groups["reviewed_b0_ledger"] = led.ok ? String[] : [led.reason]

    fl5 = s1_classify_ledger(S1_FL5_JSON;
        expected_case = S1_FL5_CASE, expected_status = S1_FL5_STATUS,
        expected_sha = S1_FL5_SHA)
    groups["reviewed_failure_ledger_4555"] = fl5.ok ? String[] : [fl5.reason]

    src = String[]
    length(tree) == S1_TREE_FILES ||
        push!(src, "artifact tree census $(length(tree)) != $S1_TREE_FILES")
    count(e -> e.exec, tree) == S1_TREE_EXEC ||
        push!(src, "artifact exec census != $S1_TREE_EXEC")
    sa = [e for e in tree if e.rel == S1_SOLVE_ADEPT_REL]
    (length(sa) == 1 && sa[1].sha == S1_ORIG_SOLVE_ADEPT_SHA) ||
        push!(src, "artifact solve_adept.cpp pin mismatch")
    for (sha, sz, path) in S1_V12_TEST_PINS
        isfile(path) || (push!(src, "testcopy file missing: $path"); continue)
        filesize(path) == sz || push!(src, "testcopy size drift: $path")
        s1_try_sha(path) == sha || push!(src, "testcopy sha drift: $path")
    end
    groups["modern_source_pins"] = src

    ad = String[]
    s1_try_sha(S1_MINIMIZER_H) == S1_MINIMIZER_H_SHA ||
        push!(ad, "installed Minimizer.h sha drift")
    s1_try_sha(S1_LIBADEPT) == S1_LIBADEPT_SHA ||
        push!(ad, "installed libadept.so.0.0.0 sha drift")
    isdir(joinpath(S1_NETCDF, "lib")) || push!(ad, "netcdf stack missing")
    groups["adept_toolchain_pins"] = ad

    tc = String[]
    for (t_, p_, l1) in S1_TOOLCHAIN
        got = try
            strip(read(`which $t_`, String))
        catch
            "missing"
        end
        got == p_ || push!(tc, "$t_ path $got != pinned $p_")
        gotl1 = try
            first(split(read(`$t_ --version`, String), '\n'))
        catch
            "unreadable"
        end
        gotl1 == l1 || push!(tc, "$t_ version line drift: $gotl1")
    end
    groups["toolchain_fingerprints"] = tc

    inp = String[]
    for (sha, sz, path) in S1_DATA_INPUTS
        isfile(path) || (push!(inp, "missing: $path"); continue)
        filesize(path) == sz || push!(inp, "size drift: $path")
        s1_try_sha(path) == sha || push!(inp, "sha drift: $path")
    end
    for (sha, sz, path, _) in S1_WORK_INPUTS
        isfile(path) || (push!(inp, "missing: $path"); continue)
        filesize(path) == sz || push!(inp, "size drift: $path")
        s1_try_sha(path) == sha || push!(inp, "sha drift: $path")
    end
    groups["input_pins"] = inp

    rt = String[]
    for (path, sha, label) in ((S1_NETLIB_BLAS, S1_NETLIB_BLAS_SHA, "netlib blas"),
                               (S1_NETLIB_LAPACK, S1_NETLIB_LAPACK_SHA, "netlib lapack"),
                               (S1_SHIM_SO, S1_SHIM_SO_SHA, "h5 shim"))
        s1_try_sha(path) == sha || push!(rt, "$label pin mismatch: $path")
    end
    groups["runtime_pins"] = rt

    text = s1_make_sbatch(tree)
    groups["sbatch_text_gates"] = s1_text_gate_issues(text)
    groups["sbatch_bash_syntax"] = s1_bash_syntax_ok(text) ? String[] :
        ["generated sbatch fails bash -n syntax verification"]

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end
    ready = gates["fixtures"] == "passed" && all(isempty, values(groups))
    status = ready ? "s1_checkpoint_ready" : "s1_checkpoint_refused"
    if ready
        mkpath(dirname(S1_SBATCH))
        write(S1_SBATCH, text)
    end
    sb_sha = ready ? s1_sha(S1_SBATCH) : nothing

    result = Dict(
        "case" => "gate4_s1_state_sync_checkpoint",
        "data_mode" => "generator_checkpoint",
        "status" => status,
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "sbatch_path" => S1_SBATCH,
        "sbatch_sha256" => sb_sha,
        "design" => "triple-arm (A0a/A0b pristine control repeats " *
            "sharing ONE saved binary, S1 one-line sync patch) from ONE " *
            "source copy, ONE corrected fresh-autoreconf configure " *
            "(path-only LDFLAGS + late LIBS=-ladept; BUILD-ENABLEMENT, " *
            "not historical build equivalence -- see the reviewed 4555 " *
            "failure ledger; config.status rendering asserted " *
            "byte-exact), sequential builds with immutable saved " *
            "binaries, SANDWICH " *
            "execution order A0a -> S1 -> A0b, independent " *
            "testcopy/work/log clones per arm, identical staged " *
            "inputs/options/preloads and explicit OpenMP controls " *
            "(OMP_NUM_THREADS=SLURM_CPUS_PER_TASK, OMP_DYNAMIC=FALSE, " *
            "logged per arm); A0a-vs-A0b establishes the repeatability " *
            "floor across the full treatment interval, A0-vs-S1 is " *
            "primary, historical 4515 is an informational echo unless " *
            "the A0 arms match it",
        "source_tree" => Dict(
            "artifact" => S1_SRC_ARTIFACT,
            "gate_semantics" => "exact 119-file content + " *
                "executable-semantics + zero-symlink census; non-exec " *
                "permission bits and empty directories are NOT pinned " *
                "(content/exec semantics pinned; chmod intentionally " *
                "changes writability on the working copy)",
            "files" => S1_TREE_FILES,
            "executables" => S1_TREE_EXEC,
            "symlinks" => 0,
            "manifest_sha256" => s1_manifest_hash(tree),
            "patched_manifest_note" => "post-patch check proves that AMONG " *
                "THE 119 REGISTERED ARTIFACT FILES only solve_adept.cpp " *
                "changed; it does not prove whole-working-tree identity " *
                "or absence of legitimate generated build files " *
                "(stage-3 autoreconf/make creates those outside the " *
                "registered manifest); the manifest differs in " *
                "exactly one entry: $S1_SOLVE_ADEPT_REL " *
                "$S1_ORIG_SOLVE_ADEPT_SHA -> $S1_PATCHED_SOLVE_ADEPT_SHA"),
        "patch" => Dict(
            "original_solve_adept_sha256" => S1_ORIG_SOLVE_ADEPT_SHA,
            "patched_solve_adept_sha256" => S1_PATCHED_SOLVE_ADEPT_SHA,
            "patched_region_305_320_sha256" => S1_PATCHED_REGION_SHA,
            "anchor_line" => S1_PATCH_ANCHOR,
            "inserted_line" => S1_PATCH_LINE,
            "inserted_at_line" => 314,
            "note" => "EXACTLY ONE scientific source change between the " *
                "two arms; hypothesis test, never a presumed fix; no " *
                "requirement that an extra final callback provably " *
                "executed"),
        "toolchain" => Dict(
            "configure_argv" => S1_CONFIGURE_ARGV,
            "fingerprints" => [Dict("tool" => t_, "path" => p_,
                                    "version_line" => l1)
                               for (t_, p_, l1) in S1_TOOLCHAIN],
            "automake" => S1_AUTOMAKE_VER,
            "libtoolize" => S1_LIBTOOLIZE_VER,
            "adept_minimizer_h_sha256" => S1_MINIMIZER_H_SHA,
            "libadept_sha256" => S1_LIBADEPT_SHA),
        "prerequisites" => [
            Dict("ledger" => "B0 era-stack completion ledger",
                 "path" => S1_B0_LEDGER,
                 "required_case" => S1_B0_LEDGER_CASE,
                 "required_status" => S1_B0_LEDGER_STATUS,
                 "reviewed_sha256" => S1_B0_LEDGER_SHA),
            Dict("ledger" => "S1 attempt-1 (4555) failure ledger",
                 "path" => S1_FL5_JSON,
                 "required_case" => S1_FL5_CASE,
                 "required_status" => S1_FL5_STATUS,
                 "reviewed_sha256" => S1_FL5_SHA)],
        "preregistered_outcome_matrix" => [
            "A0a == A0b and S1 == A0a: sync had no effect in this " *
                "paired deterministic trajectory",
            "A0a == A0b and S1 differs: patch-associated output change " *
                "under a deterministic control trajectory; still report " *
                "hash, exact effective-bound census, and external " *
                "objective separately",
            "A0a != A0b: byte-level treatment inference is INCONCLUSIVE " *
                "because baseline repeatability failed; S1 metrics are " *
                "descriptive only",
            "historical 4515 comparison ($S1_MODERN_RAW2_SHA) is a " *
                "bridge ONLY if the rebuilt A0 arms match it; otherwise " *
                "historical hash differences are non-causal " *
                "(informational echo; 4515 executed the pre-existing " *
                "binary $S1_4515_BINARY_SHA via a wrapper named " *
                "optimize_lut_h5preinit_v12)",
            "persistent effective-bound exceedances in S1 -> sync alone " *
                "does not explain them; mapping/write behavior remains " *
                "open"],
        "post_terminal_requirements" => [
            "raw2 hashes (all three arms)",
            "corrected active-state effective-bound census (all arms)",
            "external pinned-comparator objective (all arms, incl. A0 " *
                "to quantify the historical build/configure delta)",
            "all in a dedicated completion ledger; NOT in-job"],
        "probe_omission_note" => "no 1-iteration probe stage in this " *
            "revision: a config failure costs up to one full arm and " *
            "A0a acts as the de facto probe (Agent 42 review nit, " *
            "accepted; probes must never mutate an arm)",
        "binary_difference_semantics" => "the A0!=S1 binary-hash " *
            "assertion is a NECESSARY sanity check only: identical " *
            "binaries prove the patch did not change the executable; " *
            "differing binaries do not by themselves prove the patch " *
            "entered it (timestamp embedding can differ across " *
            "builds) -- the patch proof is tree identity + patched-file " *
            "pin + rebuild semantics (Agent 42 review nit, adopted)",
        "non_authorizing_note" => "this checkpoint generates and " *
            "verifies the S1 sbatch; it never submits; submission " *
            "requires explicit monitor GO.",
        "disclaimer" => "generator checkpoint; writes nothing except " *
            "its own JSON/MD results and the generated sbatch plus " *
            "transient private temp fixtures (mktempdir).")

    mkpath(dirname(S1_RESULTS_JSON))
    open(S1_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(S1_RESULTS_MD, "w") do io
        println(io, "# Gate-4 S1 triple-arm state-sync hypothesis-test checkpoint\n")
        println(io, "Status: **$status**\n")
        println(io, result["design"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nPatch pins: original `$S1_ORIG_SOLVE_ADEPT_SHA` " *
                    "-> patched `$S1_PATCHED_SOLVE_ADEPT_SHA` (region " *
                    "305-320 `$S1_PATCHED_REGION_SHA`); tree manifest " *
                    "`$(s1_manifest_hash(tree))` ($S1_TREE_FILES files)")
        println(io, "\nGenerated sbatch: `$S1_SBATCH`" *
                    (sb_sha === nothing ? " (NOT written; refused)" :
                     " sha256 `$sb_sha`"))
        println(io, "\nPrerequisites (fail-closed, sha-chained): B0 " *
                    "completion ledger `$S1_B0_LEDGER_SHA` " *
                    "($S1_B0_LEDGER_STATUS) + 4555 failure ledger " *
                    "`$S1_FL5_SHA` ($S1_FL5_STATUS)")
        println(io, "\nPre-registered outcome matrix:")
        for o in result["preregistered_outcome_matrix"]
            println(io, "- ", o)
        end
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_s1_state_sync_checkpoint: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return ready ? 0 : 1
end

exit(main())
