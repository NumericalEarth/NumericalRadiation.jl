# Gate-4 X1 DIRECT POST-MINIMIZE STATE-CAPTURE CHECKPOINT (generator;
# writes ONLY its own JSON/MD results + the generated sbatch).
#
# FROZEN DESIGN (monitor-frozen, Agent 42 APPROVE):
# next_control_decision_DRAFT.md sha256
# d4f8a689aa4fcadb91922120b7806939bba88c115fb6281d51b2fc3dbe325398.
# X1-FIRST approved; C1 deferred; C2 deferred. This checkpoint
# implements the X1 CHECKPOINT PACKAGE ONLY: no submission, no commit.
#
# DESIGN (frozen draft + monitor implementation rulings, 2026-08-14):
#   - One job, ONE copied source tree, TWO sequential builds, THREE
#     sequential runs: PROBE (X1 binary, max_iterations=1; sidecar +
#     schema validation BEFORE any full arm is spent), PRISTINE
#     control (full 3000-iteration run, uninstrumented), X1 (full run,
#     instrumented). TWO immutable saved binaries from ONE pinned
#     source/configure tree.
#   - The X1 patch is BOUNDS-ON ONLY and consists of TWO anchored
#     edits: a global include (declarations only) and the
#     bounded-branch call-site block whose FIRST line is the
#     pre-minimize record_pre. ZERO X1 calls execute outside the
#     bounded branch: the gate4_x1 token census is exact (3 total,
#     2 calls, both inside the pinned capture region) and the ENTIRE
#     tail from the unbounded else block to EOF is gated
#     byte-identical between the original and patched files.
#   - The capture instrument (gate4_x1_capture.h, separately pinned)
#     fails CLOSED (process exit 93) on any env/path/mapping/write/
#     rename problem; the private atomic sidecar is written dot-temp ->
#     close -> rename INSIDE the job-private RUNROOT to the exact
#     target from required GATE4_X1_CAPTURE_PATH; the same-directory
#     temp name itself ends in .nc (OutputDataFile infers format from
#     the LAST extension); a missing/unwritable path is a refusal,
#     never a skip.
#   - lower_class/upper_active are computed PRE-minimize from the
#     PHYSICAL member state (record_pre), because ckd_model.x is
#     callback-mutated during minimize; bound vectors are stored
#     EXACTLY as passed, including inactive
#     -/+ numeric_limits<Real>::max() initialization values.
#   - NON-PERTURBATION IS AN EMPIRICAL ALL-VARIABLE IDENTITY GATE
#     (pristine-arm raw2 vs X1-arm raw2, logical comparison, value
#     differences allowed ONLY in config/history), never a
#     construction claim. Identity-gate violation is INSTRUMENT
#     REFUSAL, never elimination and never a finding.
#   - Zero canonical writes; RUNROOT preserved on success AND failure.
#
# BUILD RECIPE: the corrected fresh-autoreconf recipe from the
# reviewed 4555 failure ledger (path-only LDFLAGS + late LIBS=-ladept;
# BUILD-ENABLEMENT, not historical build equivalence).
#
# PREREQUISITE (fail-closed): the reviewed committed S1 completion
# ledger (commit 5b6cea7e97d552f0f2bbf80dbd5c998db065ddd4).
#
# SUBMISSION IS HELD for monitor review: this generator only produces
# the sbatch + evidence; it never submits.

include("/shared/home/greg/Projects/AnalyticBandRadiation-platform/validation/validation_results.jl")
include(joinpath(@__DIR__, "gate4_x1_sidecar_validator.jl"))

import JSON
using SHA: sha256

const X1_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
const X1_G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const X1_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"
const X1_CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"

# --- frozen design pin (DURABLE package file, byte-identical to the
# monitor-frozen reviewed draft; never an ephemeral scratch path) -----------------
const X1_DESIGN_SHA = "d4f8a689aa4fcadb91922120b7806939bba88c115fb6281d51b2fc3dbe325398"
const X1_DESIGN_FILE = joinpath(@__DIR__, "gate4_x1_frozen_design.md")
const X1_DESIGN_REPO_PATH = "validation/gate4_x1_frozen_design.md"

# --- pinned modern (v1.2) ecckd source artifact (the ONLY source authority) ------
const X1_SRC_ARTIFACT = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"
const X1_ORIG_SOLVE_ADEPT_SHA = "8c9822fac6e6efebadc3fd76c104fe563236221ca6297922e5e8a9467ee32091"
const X1_SOLVE_ADEPT_REL = "src/ecckd/solve_adept.cpp"
const X1_HELPER_REL = "src/ecckd/gate4_x1_capture.h"
const X1_TREE_FILES = 119
const X1_TREE_EXEC = 24

# --- the TWO anchored patch edits (bounds-ON only): one global
# include (declarations only, no execution) and ONE bounded-branch
# call-site block. ZERO X1 calls execute outside the bounded branch:
# record_pre runs as the FIRST line of the bounded call-site block,
# immediately before minimize (pre-minimize by construction AND
# bounded-branch-only by construction), and the entire tail from the
# unbounded else block to EOF is gated byte-identical. -----------------------------
const X1_INCLUDE_ANCHOR = "#include \"Timer.h\""
const X1_INCLUDE_LINE = "#include \"gate4_x1_capture.h\""
const X1_CALLSITE_ANCHOR = "    return minimizer.minimize(ckd_optimizable, x, x_min, x_max);"
const X1_CALLSITE_LINES = [
    "    gate4_x1::PreState x1_pre = gate4_x1::record_pre(ckd_model);",
    "    adept::MinimizerStatus x1_status = minimizer.minimize(ckd_optimizable, x, x_min, x_max);",
    "    gate4_x1::write_capture(ckd_model, x, x_min, x_max, x1_pre, x1_status, MIN_X);",
    "    return x1_status;"]
const X1_UNBOUNDED_LINE = "    return minimizer.minimize(ckd_optimizable, x);"

# --- capture-helper source (separately pinned sibling file) ----------------------
const X1_HELPER_PATH = joinpath(@__DIR__, "gate4_x1_capture.h")
isfile(X1_HELPER_PATH) ||
    error("REFUSED: capture helper missing: $X1_HELPER_PATH")
const X1_HELPER_TEXT = read(X1_HELPER_PATH, String)
const X1_HELPER_SHA = bytes2hex(sha256(X1_HELPER_TEXT))

# installed Adept toolchain pins (identical to the reviewed S1 set)
const X1_ADEPT = "/shared/home/greg/local/adept-2-install"
const X1_MINIMIZER_H = "$X1_ADEPT/include/adept/Minimizer.h"
const X1_MINIMIZER_H_SHA = "dad747936a66304266d0dd31990afa3a7534c589ac6b7a9230eaafbe671a1f8d"
const X1_LIBADEPT = "$X1_ADEPT/lib/libadept.so.0.0.0"
const X1_LIBADEPT_SHA = "1f9016af1b6982493dc8d53dd3a11b2b0c54d4e84c4dbb548b4b06093d43dbcb"
# authoritative installed source for the pinned status table
# (adept_source.h:464-499; Minimizer.h enum :27-38)
const X1_ADEPT_SOURCE_H = "$X1_ADEPT/include/adept_source.h"
const X1_ADEPT_SOURCE_H_SHA = "8f29a64a2d8227e881a7a541e154d80b752f7746c8607f6a9f280b54f0312351"
# shallow-link (alias) semantics authority: X1 reads caller-local x
# AFTER the by-value minimize returns; that is licensed ONLY because
# Adept Array copies are shallow links (Array.h copy constructors,
# lines 216-245: "links to the source data rather than copying").
# Bounded claim: caller-local x aliases the minimizer's by-value
# Vector storage under these pinned header semantics, so post-return x
# is the observed returned solution FOR THIS BUILD; no broader
# source-to-binary claim.
const X1_ARRAY_H = "$X1_ADEPT/include/adept/Array.h"
const X1_ARRAY_H_SHA = "e7ceba7e6a951e410446259de8c5e6b78f2ad4cc172548fa505b9d792a9099a1"
const X1_MINIMIZE_BOUNDED_SIG =
    "MinimizerStatus minimize(Optimizable& optimizable, Vector x,"

# behavioral alias probe: compiled AND RUN by a generator fixture, and
# recompiled/rerun IN-JOB under the pinned compiler/headers before any
# build; refuses unless mutating the by-value/copy alias mutates the
# original storage
const X1_ALIAS_PROBE_CPP = raw"""
// gate4_x1 alias probe: verifies that Adept Array/Vector copies are
// SHALLOW LINKS (by-value parameters and copy construction alias the
// SAME storage) under the pinned headers -- the semantic that
// licenses reading caller-local x after the by-value minimize
// returns (Axis A). Exit 0 + CONFIRMED line, else exit 1.
#include <adept_arrays.h>
#include <cstdio>
using namespace adept;
static void mutate_by_value(Vector v) { v(1) = 42.0; }
int main() {
  Vector x(3);
  x(0) = 1.0; x(1) = 2.0; x(2) = 3.0;
  Vector c = x; // copy construction
  c(0) = 41.0;
  mutate_by_value(x); // by-value parameter
  if (x(0) == 41.0 && x(1) == 42.0 && x(2) == 3.0) {
    std::printf("X1 ALIAS PROBE: shallow-link semantics CONFIRMED\n");
    return 0;
  }
  std::printf("X1 ALIAS PROBE: REFUSED (x = %g %g %g)\n",
              (double) x(0), (double) x(1), (double) x(2));
  return 1;
}
"""
const X1_ALIAS_PROBE_SHA = bytes2hex(sha256(X1_ALIAS_PROBE_CPP))
const X1_ALIAS_PROBE_OK = "X1 ALIAS PROBE: shallow-link semantics CONFIRMED"
const X1_NETCDF = "/shared/home/greg/local/ckdmip-stack"
# corrected recipe (reviewed 4555 failure ledger): path-only LDFLAGS
# (-L + rpath, never -ladept) + late LIBS=-ladept
const X1_CONFIGURE_ARGV = "./configure --with-adept=$X1_ADEPT " *
    "--with-netcdf=$X1_NETCDF " *
    "'LDFLAGS=-L$X1_ADEPT/lib -Wl,-rpath,$X1_ADEPT/lib' 'LIBS=-ladept'"
const X1_CONFIG_STATUS_EXPECT = "--with-adept=$X1_ADEPT " *
    "--with-netcdf=$X1_NETCDF " *
    "'LDFLAGS=-L$X1_ADEPT/lib -Wl,-rpath,$X1_ADEPT/lib' LIBS=-ladept"

# fail-closed toolchain fingerprints (exact command paths + complete
# first version lines)
const X1_TOOLCHAIN = [
    ("gcc", "/usr/bin/gcc", "gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"),
    ("g++", "/usr/bin/g++", "g++ (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"),
    ("make", "/usr/bin/make", "GNU Make 4.3"),
    ("autoreconf", "/usr/bin/autoreconf", "autoreconf (GNU Autoconf) 2.71")]
const X1_AUTOMAKE_VER = "1.16.5"
const X1_LIBTOOLIZE_VER = "2.4.7"

# --- proven Netlib remedy pins (verbatim from 4515/B0/S1) ------------------------
const X1_SHIM_SO = "$X1_G4WORK/tools/h5open_before_traps.so"
const X1_SHIM_SO_SHA = "28003281a7f1c8470c1bfd94a654999a210581261a5c3e9cd662af2a13dd492f"
const X1_NETLIB_BLAS = "/usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0"
const X1_NETLIB_BLAS_SHA = "e748efcae5753fe4a652877fccdb5895ac6f7605668a2db878b19c914e78e3a8"
const X1_NETLIB_LAPACK = "/usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0"
const X1_NETLIB_LAPACK_SHA = "851bb1fc5833ede9ed704b4417a251a899976d5e0915de40452615187a65278f"

# --- prerequisite: the REVIEWED committed S1 completion ledger -------------------
const X1_S1_LEDGER = "$X1_PROJECT_ROOT/validation/results/gate4_s1_state_sync_completion_ledger.json"
const X1_S1_LEDGER_CASE = "gate4_s1_state_sync_completion_ledger"
const X1_S1_LEDGER_STATUS = "s1_run_completed_verified"
const X1_S1_LEDGER_SHA = "de5b349e07b1f085e01f8a8fe6902ea50ac9ecce0821844ae99d8b3f9f40a586"
const X1_S1_LEDGER_COMMIT = "5b6cea7e97d552f0f2bbf80dbd5c998db065ddd4"

# historical echoes (informational only; never causal)
const X1_MODERN_RAW2_SHA = "4205489923dbc50c3c148a06f20e5781b3f1dbeb5a13d55d36b460c5f7b4378c"

# --- scientific inputs: identical pins to the 4515/B0/S1 manifest ----------------
const X1_DATA_INPUTS = [
    ("dde735608e57af934a2c1e99932c0ccce530883ab48910c7e17b621de7fa0bee", 450863,
     "$X1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-180.h5"),
    ("b0932f2648f720af74191d2a9d62f6178f73dfb9a620b773e55670f06ce2db85", 450863,
     "$X1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-280.h5"),
    ("01836becbc96e7da2b3b33d586d148948df136457216625b7e60225e093e1792", 450863,
     "$X1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-415.h5"),
    ("c8aa819b9e7ea7ed73a0af74862ab49d4209866b74988529b2dfce0ef99710e2", 450863,
     "$X1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-560.h5"),
    ("cfbda1d66decc14e6e91e8465f32f5a5e4bcf0310a73f620fe45bafbcec9ba7c", 450873,
     "$X1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-1120.h5"),
    ("75239df6dbf578b3be6267c09995ff050f5c846be3c75492fad96dcab25610e8", 450873,
     "$X1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-2240.h5")]
const X1_WORK_INPUTS = [
    ("e799eae4421afe12481533678963237198338b3979ec938c6e61c2759522d4bc", 451045,
     "$X1_G4WORK/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5",
     "lw_lbl_fluxes"),
    ("ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43", 2413144,
     "$X1_G4WORK/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc",
     "lw_raw-ckd-definition"),
    ("c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e", 58404939,
     "$X1_G4WORK/work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5",
     "lw_gpoints")]

const X1_V12_TEST_PINS = [
    ("f0d77b16b97612687818e85615a103adaa948627846c9819e40e7754ab0743ba",
     11792, "$X1_SRC_ARTIFACT/test/optimize_lut_lw.sh"),
    ("44dcddf099d69becab1c5e6674d013d6c676685e0b8a4ae51e85a1dda33cfc69",
     6357, "$X1_SRC_ARTIFACT/test/config.h"),
    ("34323fd3ecbcd64980b328eec463eedc692497ed3cdd685f2505ca4d1fdc5e2c",
     1369, "$X1_SRC_ARTIFACT/test/check_configuration.h"),
    ("a5fe514dbcb656c99c11ca39d1c88eba953bda592ca35983de9c42da33dab810",
     92, "$X1_SRC_ARTIFACT/test/version.h.in")]

# location-neutral reproducibility contract: never claims where this
# invocation ran; the computed generation location is recorded
# separately and accurately
const X1_CANONICAL_DIR = joinpath(X1_PROJECT_ROOT, "validation")
const X1_REPRO_NOTE = "reproducibility: the generator's sibling " *
    "package files (validator, capture helper, frozen design) are " *
    "hash-pinned; the generated sbatch addresses the canonical paths " *
    "under $X1_PROJECT_ROOT/validation regardless of where generation " *
    "ran, and sbatch stage 0a refuses unless the bytes at those paths " *
    "match the pins; final artifacts must be regenerated from the " *
    "promoted byte-identical package before commit."

const X1_RESULTS_JSON = validation_results_path("gate4_x1_direct_capture_checkpoint.json")
const X1_RESULTS_MD = validation_results_path("gate4_x1_direct_capture_checkpoint.md")
const X1_SBATCH = validation_results_path("gate4_x1_lw_direct_capture.sbatch")

# raw2 global attributes observed on this pipeline's outputs; the
# identity gate requires the exact set and allows VALUE differences
# only in config/history (per-arm paths/command lines)
const X1_RAW2_GLOBAL_ATTRS = "composite_constituent_id,config," *
    "constituent_id,history,model_id,software_version,source," *
    "source_id,summary,title"

# --- primitives -------------------------------------------------------------------

x1_sha(path) = open(io -> bytes2hex(sha256(io)), path)
x1_try_sha(path) = try
    isfile(path) || return nothing
    x1_sha(path)
catch
    nothing
end

# deterministic tree gate of the pinned artifact: an EXACT 119-file
# content + executable-semantics + zero-symlink census
function x1_tree_manifest()
    entries = NamedTuple[]
    for (root, _, files) in walkdir(X1_SRC_ARTIFACT)
        for f in files
            p = joinpath(root, f)
            islink(p) && error("unexpected symlink in artifact: $p")
            rel = relpath(p, X1_SRC_ARTIFACT)
            push!(entries, (rel = rel, sha = x1_sha(p),
                            exec = (uperm(p) & 0x01) != 0))
        end
    end
    sort!(entries, by = e -> e.rel)
    entries
end

x1_manifest_hash(entries) = bytes2hex(sha256(join(
    ["F $(e.sha) $(e.exec ? 1 : 0) $(e.rel)" for e in entries], "\n")))

function x1_snapshot(path; readfn = read)
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

function x1_classify_ledger(path; expected_case = X1_S1_LEDGER_CASE,
                            expected_status = X1_S1_LEDGER_STATUS,
                            expected_sha = X1_S1_LEDGER_SHA,
                            readfn = read)
    snap = x1_snapshot(path; readfn = readfn)
    snap.ok || return (ok = false, class = snap.reason,
                       reason = "S1 ledger $(snap.reason)")
    c = get(snap.data, "case", nothing)
    c == expected_case || return (ok = false, class = "case mismatch",
        reason = "S1 ledger case mismatch (got $(repr(c)))")
    s = get(snap.data, "status", nothing)
    s == expected_status || return (ok = false, class = "status mismatch",
        reason = "S1 ledger status $(repr(s)) != $expected_status")
    snap.sha == expected_sha || return (ok = false, class = "sha drift",
        reason = "S1 ledger sha $(snap.sha) != reviewed $(expected_sha)")
    (ok = true, class = "green", reason = "")
end

# --- three-edit patch derivation (bounds-ON only) ---------------------------------

function x1_derive_patched(orig_text)
    iss = String[]
    if occursin("gate4_x1", orig_text)
        push!(iss, "original source already references gate4_x1")
        return (iss, nothing)
    end
    lines = split(orig_text, '\n'; keepempty = true)
    for (anchor, what) in ((X1_INCLUDE_ANCHOR, "include"),
                           (X1_CALLSITE_ANCHOR, "callsite"))
        n = count(==(anchor), lines)
        n == 1 || push!(iss, "$what anchor not exactly once ($n)")
    end
    count(==(X1_UNBOUNDED_LINE), lines) == 1 ||
        push!(iss, "unbounded call line not exactly once")
    isempty(iss) || return (iss, nothing)
    out = String[]
    for l in lines
        if l == X1_CALLSITE_ANCHOR
            append!(out, X1_CALLSITE_LINES)
        else
            push!(out, l)
            l == X1_INCLUDE_ANCHOR && push!(out, X1_INCLUDE_LINE)
        end
    end
    (iss, join(out, '\n'))
end

# region-hash convention identical to S1: sha256 of `sed -n 'A,Bp'`
# output == sha256(join(lines[A:B], '\n') * '\n')
x1_region_sha(lines, a, b) =
    bytes2hex(sha256(join(lines[a:b], '\n') * "\n"))
# tail-hash convention: sha256 of `sed -n 'A,$p'` output; when the file
# ends in a newline the final split element is empty, so a plain join
# reproduces the sed byte stream exactly
x1_tail_sha(lines, a) = bytes2hex(sha256(join(lines[a:end], '\n')))

# generation-time patch pins, all derived from the pinned artifact
function x1_patch_pins()
    orig = read(joinpath(X1_SRC_ARTIFACT, X1_SOLVE_ADEPT_REL), String)
    bytes2hex(sha256(orig)) == X1_ORIG_SOLVE_ADEPT_SHA ||
        error("REFUSED: artifact solve_adept.cpp sha drift")
    iss, patched = x1_derive_patched(orig)
    isempty(iss) || error("REFUSED: patch derivation: $(join(iss, "; "))")
    ol = split(orig, '\n'; keepempty = true)
    pl = split(patched, '\n'; keepempty = true)
    # capture-region window: 2 context lines around the 4-line bounded
    # call-site block (record_pre is its FIRST line)
    ci = findfirst(==(X1_CALLSITE_LINES[1]), pl)
    cap_a, cap_b = ci - 2, ci + 5
    # BOUNDS-ON gates: (a) exactly two gate4_x1:: call lines, BOTH
    # inside the capture region; (b) the ENTIRE tail from the unbounded
    # else block to EOF is byte-identical between original and patched
    calls = [i for (i, l) in enumerate(pl) if occursin("gate4_x1::", l)]
    (length(calls) == 2 && all(cap_a .<= calls .<= cap_b)) ||
        error("REFUSED: gate4_x1:: call census violates the bounded-branch-only contract")
    uo = findfirst(==(X1_UNBOUNDED_LINE), ol)
    up = findfirst(==(X1_UNBOUNDED_LINE), pl)
    tail = x1_tail_sha(ol, uo - 2)
    tail == x1_tail_sha(pl, up - 2) ||
        error("REFUSED: unbounded-else-to-EOF tail not byte-identical")
    occursin("gate4_x1", join(pl[(up - 2):end], '\n')) &&
        error("REFUSED: X1 token present in the unbounded tail")
    (patched_sha = bytes2hex(sha256(patched)),
     patched_lines = length(pl),
     orig_lines = length(ol),
     capture_region = (a = cap_a, b = cap_b,
                       sha = x1_region_sha(pl, cap_a, cap_b)),
     unbounded_tail_orig_start = uo - 2,
     unbounded_tail_patched_start = up - 2,
     unbounded_tail_sha = tail,
     patched_text = patched)
end

# --- sbatch generation --------------------------------------------------------------

function x1_make_sbatch(tree, pins)
    stage_rows = String[]
    for (sha, sz, path) in X1_DATA_INPUTS
        push!(stage_rows, "$sha $sz $path \$RUNROOT/data/evaluation1/lw_fluxes/$(basename(path))")
    end
    for runset in ("probe", "pristine", "x1")
        for (sha, sz, path, rel) in X1_WORK_INPUTS
            push!(stage_rows, "$sha $sz $path \$RUNROOT/work-$runset/$rel/$(basename(path))")
        end
    end
    stage_lines = join(stage_rows, "\n")
    # post-run re-verification rows for the six shared staged data
    # files (SAME pinned manifest, addressed at the staged paths);
    # unquoted heredocs so \$RUNROOT expands in-job
    data_post_hash_lines = join(
        ["$sha  \$RUNROOT/data/evaluation1/lw_fluxes/$(basename(path))"
         for (sha, _, path) in X1_DATA_INPUTS], "\n")
    data_post_size_lines = join(
        ["$sz \$RUNROOT/data/evaluation1/lw_fluxes/$(basename(path))"
         for (_, sz, path) in X1_DATA_INPUTS], "\n")
    hash_lines = join(vcat(
        ["$sha  $path" for (sha, _, path) in X1_DATA_INPUTS],
        ["$sha  $path" for (sha, _, path, _) in X1_WORK_INPUTS],
        ["$sha  $path" for (sha, _, path) in X1_V12_TEST_PINS],
        ["$X1_MINIMIZER_H_SHA  $X1_MINIMIZER_H",
         "$X1_LIBADEPT_SHA  $X1_LIBADEPT",
         "$X1_ADEPT_SOURCE_H_SHA  $X1_ADEPT_SOURCE_H",
         "$X1_ARRAY_H_SHA  $X1_ARRAY_H"]), "\n")
    size_lines = join(vcat(
        ["$sz $path" for (_, sz, path) in X1_DATA_INPUTS],
        ["$sz $path" for (_, sz, path, _) in X1_WORK_INPUTS],
        ["$sz $path" for (_, sz, path) in X1_V12_TEST_PINS]), "\n")
    # gate-code pins: sha of the LOCAL package files, addressed at
    # their canonical repo paths (post-promotion the bytes must match
    # or stage 0a refuses; regeneration required if the package moves)
    gate_pins = join(vcat(
        ["$(x1_sha(joinpath(X1_PROJECT_ROOT, f)))  $(joinpath(X1_PROJECT_ROOT, f))"
         for f in ("validation/gate4_quota_guard.sh",
                   "validation/validation_results.jl")],
        ["$(x1_sha(abspath(@__FILE__)))  $X1_PROJECT_ROOT/validation/gate4_x1_direct_capture_checkpoint.jl",
         "$(x1_sha(joinpath(@__DIR__, "gate4_x1_sidecar_validator.jl")))  $X1_PROJECT_ROOT/validation/gate4_x1_sidecar_validator.jl",
         "$X1_HELPER_SHA  $X1_PROJECT_ROOT/validation/gate4_x1_capture.h",
         "$X1_DESIGN_SHA  $X1_PROJECT_ROOT/$X1_DESIGN_REPO_PATH",
         "$X1_S1_LEDGER_SHA  $X1_S1_LEDGER"]), "\n")
    artifact_tree_lines = join(["$(e.sha)  $X1_SRC_ARTIFACT/$(e.rel)"
                                for e in tree], "\n")
    copy_tree_lines = join(["$(e.sha)  $(e.rel)" for e in tree], "\n")
    postpatch_tree_lines = join(
        ["$(e.rel == X1_SOLVE_ADEPT_REL ? pins.patched_sha : e.sha)  $(e.rel)"
         for e in tree], "\n")
    execbit_lines = join(["$(e.exec ? 1 : 0) $(e.rel)" for e in tree], "\n")
    toolchain_checks = join([begin
        V = uppercase(replace(t, "+" => "X"))
        """
$(V)_P=\$(command -v $t) || { echo "REFUSED: $t missing" >&2; exit 65; }
[ "\$$(V)_P" = "$p" ] || { echo "REFUSED: $t path \$$(V)_P != pinned $p" >&2; exit 65; }
$(V)_FULL=\$($t --version); $(V)_L1=\${$(V)_FULL%%\$'\\n'*}
[ "\$$(V)_L1" = "$l1" ] || { echo "REFUSED: $t version line '\$$(V)_L1' != pinned '$l1'" >&2; exit 65; }"""
    end for (t, p, l1) in X1_TOOLCHAIN], "\n")
    banner_3000 = "Optimizing coefficients with Adept LBFGS " *
        "algorithm: max iterations = 3000, convergence criterion = 0.02"
    banner_1 = "Optimizing coefficients with Adept LBFGS " *
        "algorithm: max iterations = 1, convergence criterion = 0.02"
    template_pins = join(["$sha  \$RUNROOT/test-template/$(basename(path))"
                          for (sha, _, path) in X1_V12_TEST_PINS], "\n")
    """
#!/bin/bash
#SBATCH --job-name=g4-x1-lw-direct-capture
#SBATCH --output=$X1_LOG_DIR/g4-x1-lw-%j.log
#SBATCH --time=06:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=36
#SBATCH --mem=60G
#SBATCH --partition=cpu-large

# Gate-4 X1: DIRECT POST-MINIMIZE STATE CAPTURE (DIAGNOSIS unit;
# PRIVATE output only). Generated by
# gate4_x1_direct_capture_checkpoint.jl under the frozen X1 design
# $X1_DESIGN_SHA.
# One source copy, two sequential builds (pristine + X1-instrumented),
# three sequential runs: PROBE (X1 binary, max_iterations=1; sidecar
# schema/order/type/projection validated fail-closed BEFORE any full
# arm), PRISTINE control, X1 instrumented. Non-perturbation is decided
# ONLY by the post-run all-variable identity gate. ZERO canonical
# writes; RUNROOT preserved on success AND failure.
set -euo pipefail
if [ -z "\${SLURM_JOB_ID:-}" ]; then
    echo "REFUSED: head-node execution is not permitted; submit via sbatch." >&2
    exit 64
fi
case "\$SLURM_JOB_ID" in
    ''|*[!0-9]*) echo "REFUSED: SLURM_JOB_ID is not a positive integer" >&2; exit 64;;
esac

G4WORK=$X1_G4WORK
RUNROOT="\$G4WORK/g4-diag/\${SLURM_JOB_ID}/lw-x1"
SRCDIR="\$RUNROOT/src/ecckd-modern-x1"

echo "=== X1-lw stage 0a: gate-code identity (verify BEFORE sourcing) ==="
sha256sum -c <<'GATEPINS' || { echo "REFUSED: gate code/reviewed prerequisite ledger changed since generation; regenerate the checkpoint" >&2; exit 75; }
$gate_pins
GATEPINS

echo "=== X1-lw stage 0b: quota health (read-only) ==="
source $X1_PROJECT_ROOT/validation/gate4_quota_guard.sh
quota_health \$((5*1024*1024*1024)) || { echo "REFUSED: quota not healthy" >&2; exit 67; }

echo "=== X1-lw stage 0c: pinned inputs + FULL artifact tree manifest + fail-closed toolchain ==="
sha256sum -c <<'HASHES' || { echo "REFUSED: pinned input/toolchain hash mismatch" >&2; exit 69; }
$hash_lines
HASHES
while read -r esz p; do
    asz=\$(stat -Lc %s "\$p") || { echo "REFUSED: cannot stat pinned input \$p" >&2; exit 69; }
    [ "\$asz" = "\$esz" ] || { echo "REFUSED: pinned input size mismatch \$p (\$asz != \$esz)" >&2; exit 69; }
done <<'SIZES'
$size_lines
SIZES
sha256sum -c <<'ARTTREE' >/dev/null || { echo "REFUSED: artifact tree content manifest mismatch" >&2; exit 69; }
$artifact_tree_lines
ARTTREE
[ "\$(find "$X1_SRC_ARTIFACT" \\( -type f -o -type l \\) | wc -l)" = "$X1_TREE_FILES" ] || { echo "REFUSED: artifact tree file census != $X1_TREE_FILES" >&2; exit 69; }
[ "\$(find "$X1_SRC_ARTIFACT" -type l | wc -l)" = 0 ] || { echo "REFUSED: unexpected symlink in artifact tree" >&2; exit 69; }
while read -r xf rel; do
    if [ "\$xf" = 1 ]; then
        [ -x "$X1_SRC_ARTIFACT/\$rel" ] || { echo "REFUSED: artifact exec bit lost: \$rel" >&2; exit 69; }
    else
        [ ! -x "$X1_SRC_ARTIFACT/\$rel" ] || { echo "REFUSED: artifact exec bit gained: \$rel" >&2; exit 69; }
    fi
done <<'EXECBITS'
$execbit_lines
EXECBITS
$toolchain_checks
AM_FULL=\$(automake --version); AM_LINE1=\${AM_FULL%%\$'\\n'*}; AM_V=\${AM_LINE1##* }
LT_FULL=\$(libtoolize --version); LT_LINE1=\${LT_FULL%%\$'\\n'*}; LT_V=\${LT_LINE1##* }
[ "\$AM_V" = "$X1_AUTOMAKE_VER" ] || { echo "REFUSED: automake \$AM_V != pinned $X1_AUTOMAKE_VER" >&2; exit 65; }
[ "\$LT_V" = "$X1_LIBTOOLIZE_VER" ] || { echo "REFUSED: libtoolize \$LT_V != pinned $X1_LIBTOOLIZE_VER" >&2; exit 65; }

echo "=== X1-lw stage 0d: X1 experiment lock (duplicate-diagnosis guard) ==="
mkdir -p "\$G4WORK/locks"
exec 9>"\$G4WORK/locks/x1-lw.lock"
flock -n 9 || { echo "REFUSED: another X1-lw diagnosis job holds the lock" >&2; exit 73; }

echo "=== X1-lw stage 1: job-private RUNROOT + per-run-set scientific-input snapshot ==="
[ ! -e "\$RUNROOT" ] || { echo "REFUSED: RUNROOT already exists: \$RUNROOT" >&2; exit 72; }
mkdir -p "\$RUNROOT/data/evaluation1/lw_fluxes" "\$RUNROOT/src" "\$RUNROOT/bin" "\$RUNROOT/tools" \\
         "\$RUNROOT/sidecar/probe" "\$RUNROOT/sidecar/x1"
for runset in probe pristine x1; do
    mkdir -p "\$RUNROOT/work-\$runset/lw_lbl_fluxes" \\
             "\$RUNROOT/work-\$runset/lw_raw-ckd-definition" \\
             "\$RUNROOT/work-\$runset/lw_ckd-definition" \\
             "\$RUNROOT/work-\$runset/lw_gpoints"
done
while read -r esha esz src dst; do
    cp -L -- "\$src" "\$dst" || { echo "REFUSED: staging copy failed: \$src" >&2; exit 76; }
    asz=\$(stat -Lc %s "\$dst") || { echo "REFUSED: cannot stat staged copy \$dst" >&2; exit 76; }
    [ "\$asz" = "\$esz" ] || { echo "REFUSED: staged copy size mismatch \$dst (\$asz != \$esz)" >&2; exit 76; }
    echo "\$esha  \$dst" | sha256sum -c - >/dev/null || { echo "REFUSED: staged copy hash mismatch: \$dst" >&2; exit 76; }
done <<STAGE
$stage_lines
STAGE
echo "per-run-set staged scientific-input snapshots verified under \$RUNROOT"
# ARM-INPUT IMMUTABILITY, ENFORCED (monitor ruling): the shared data
# tree is locked read-only immediately after staging+verification;
# fail closed unless it exists and holds ZERO writable files or
# directories. The find exit status is checked explicitly (no
# early-closing pipeline; a scan failure is a refusal, never a pass).
[ -d "\$RUNROOT/data" ] || { echo "REFUSED: staged data tree missing" >&2; exit 76; }
chmod -R a-w "\$RUNROOT/data"
WLIST=\$(find "\$RUNROOT/data" -writable) || { echo "REFUSED: writable-entry scan failed on the staged data tree" >&2; exit 76; }
[ -z "\$WLIST" ] || { echo "REFUSED: writable entries remain in the staged data tree after chmod" >&2; printf '%s\\n' "\$WLIST" >&2; exit 76; }
echo "staged data tree locked read-only (zero writable entries)"
# frozen validator copy (TOCTOU guard: the job never re-reads the live
# repo copy after this point)
cp -- "$X1_PROJECT_ROOT/validation/gate4_x1_sidecar_validator.jl" "\$RUNROOT/tools/gate4_x1_sidecar_validator.jl"
echo "$(x1_sha(joinpath(@__DIR__, "gate4_x1_sidecar_validator.jl")))  \$RUNROOT/tools/gate4_x1_sidecar_validator.jl" | sha256sum -c - >/dev/null || { echo "REFUSED: frozen validator copy pin mismatch" >&2; exit 75; }
chmod a-w "\$RUNROOT/tools/gate4_x1_sidecar_validator.jl"

echo "=== X1-lw stage 2: writable source copy + full-tree content identity + frozen test template ==="
mkdir -p "\$SRCDIR"
cp -rT "$X1_SRC_ARTIFACT" "\$SRCDIR"
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
cp -- "\$SRCDIR/$X1_SOLVE_ADEPT_REL" "\$RUNROOT/solve_adept.cpp.orig"
cp -r "\$SRCDIR/test" "\$RUNROOT/test-template"
sha256sum -c <<TEMPLATEPINS >/dev/null || { echo "REFUSED: frozen test-template pin mismatch" >&2; exit 69; }
$template_pins
TEMPLATEPINS
chmod -R a-w "\$RUNROOT/test-template"

echo "=== X1-lw stage 3: PRISTINE control build (corrected fresh-autoreconf recipe; build-enablement, not historical equivalence) ==="
# by-value/copy SHALLOW-LINK alias probe under the pinned compiler and
# headers, BEFORE any build: licenses Axis A's post-return read of
# caller-local x for this build (bounded claim; no broader
# source-to-binary claim)
cat > "\$RUNROOT/tools/x1_alias_probe.cpp" <<'ALIASPROBE'
$(X1_ALIAS_PROBE_CPP)ALIASPROBE
echo "$X1_ALIAS_PROBE_SHA  \$RUNROOT/tools/x1_alias_probe.cpp" | sha256sum -c - >/dev/null || { echo "REFUSED: alias-probe source sha mismatch" >&2; exit 69; }
g++ -std=c++11 -o "\$RUNROOT/tools/x1_alias_probe" "\$RUNROOT/tools/x1_alias_probe.cpp" -I$X1_ADEPT/include -L$X1_ADEPT/lib -Wl,-rpath,$X1_ADEPT/lib -ladept || { echo "REFUSED: alias probe failed to compile" >&2; exit 68; }
AP_OUT=\$("\$RUNROOT/tools/x1_alias_probe") || { echo "REFUSED: alias probe exited nonzero" >&2; exit 68; }
[ "\$AP_OUT" = "$X1_ALIAS_PROBE_OK" ] || { echo "REFUSED: alias probe output '\$AP_OUT'" >&2; exit 68; }
echo "\$AP_OUT"
cd "\$SRCDIR"
autoreconf -i
$X1_CONFIGURE_ARGV
make -j"\$SLURM_CPUS_PER_TASK"
test -x "\$SRCDIR/src/ecckd/optimize_lut" || { echo "REFUSED: pristine optimize_lut not built" >&2; exit 68; }
[ "\$(strings "\$SRCDIR/src/ecckd/optimize_lut" | grep -cF 'Adept LBFGS' || true)" -ge 1 ] || { echo "REFUSED: Adept LBFGS banner string absent from pristine binary" >&2; exit 68; }
cp -- "\$SRCDIR/src/ecckd/optimize_lut" "\$RUNROOT/bin/optimize_lut_pristine"
chmod a-w "\$RUNROOT/bin/optimize_lut_pristine"
cp -- "\$SRCDIR/config.log" "\$RUNROOT/config.log.pristine"
./config.status --config > "\$RUNROOT/config.status.config.txt"
echo "--- config.status --config (both builds; single configure) ---"
cat "\$RUNROOT/config.status.config.txt"
[ "\$(cat "\$RUNROOT/config.status.config.txt")" = "$X1_CONFIG_STATUS_EXPECT" ] || { echo "REFUSED: config.status --config != corrected reviewed recipe rendering" >&2; exit 68; }
sha256sum "\$RUNROOT/bin/optimize_lut_pristine" "\$RUNROOT/config.log.pristine" "\$RUNROOT/config.status.config.txt"

echo "=== X1-lw stage 4: capture helper + TWO anchored edits (global include + bounded-branch call-site block; ZERO X1 calls outside the bounded branch) + post-patch REGISTERED-FILE identity ==="
SA="\$SRCDIR/$X1_SOLVE_ADEPT_REL"
HLP="\$SRCDIR/$X1_HELPER_REL"
echo "$X1_ORIG_SOLVE_ADEPT_SHA  \$SA" | sha256sum -c - >/dev/null || { echo "REFUSED: pre-patch solve_adept.cpp sha drift" >&2; exit 69; }
[ ! -e "\$HLP" ] || { echo "REFUSED: helper path already exists in tree" >&2; exit 69; }
cat > "\$HLP" <<'X1HELPER'
$(X1_HELPER_TEXT)X1HELPER
echo "$X1_HELPER_SHA  \$HLP" | sha256sum -c - >/dev/null || { echo "REFUSED: written capture helper sha != pinned" >&2; exit 69; }
[ "\$(grep -c 'gate4_x1' "\$SA" || true)" = 0 ] || { echo "REFUSED: source already references gate4_x1" >&2; exit 69; }
[ "\$(grep -cxF '$X1_INCLUDE_ANCHOR' "\$SA" || true)" = 1 ] || { echo "REFUSED: include anchor not exactly once" >&2; exit 69; }
[ "\$(grep -cxF '$X1_CALLSITE_ANCHOR' "\$SA" || true)" = 1 ] || { echo "REFUSED: callsite anchor not exactly once" >&2; exit 69; }
# TWO anchored edits ONLY: a global include (declarations, no
# execution) and the bounded-branch call-site block whose FIRST line
# is the pre-minimize record_pre (bounded-branch-only by construction)
sed -i 's|^#include "Timer.h"\$|&\\n#include "gate4_x1_capture.h"|' "\$SA"
sed -i 's|^    return minimizer.minimize(ckd_optimizable, x, x_min, x_max);\$|    gate4_x1::PreState x1_pre = gate4_x1::record_pre(ckd_model);\\n    adept::MinimizerStatus x1_status = minimizer.minimize(ckd_optimizable, x, x_min, x_max);\\n    gate4_x1::write_capture(ckd_model, x, x_min, x_max, x1_pre, x1_status, MIN_X);\\n    return x1_status;|' "\$SA"
[ "\$(grep -cxF '$X1_INCLUDE_LINE' "\$SA" || true)" = 1 ] || { echo "REFUSED: include line not inserted exactly once" >&2; exit 69; }
[ "\$(grep -cxF '$(X1_CALLSITE_LINES[1])' "\$SA" || true)" = 1 ] || { echo "REFUSED: prerecord line not exactly once" >&2; exit 69; }
[ "\$(grep -cxF '$(X1_CALLSITE_LINES[2])' "\$SA" || true)" = 1 ] || { echo "REFUSED: status call line not exactly once" >&2; exit 69; }
[ "\$(grep -cxF '$(X1_CALLSITE_LINES[3])' "\$SA" || true)" = 1 ] || { echo "REFUSED: capture call line not exactly once" >&2; exit 69; }
[ "\$(grep -cxF '$(X1_CALLSITE_LINES[4])' "\$SA" || true)" = 1 ] || { echo "REFUSED: status return line not exactly once" >&2; exit 69; }
[ "\$(grep -cxF '$X1_CALLSITE_ANCHOR' "\$SA" || true)" = 0 ] || { echo "REFUSED: original bounded return line still present" >&2; exit 69; }
# BOUNDED-BRANCH-ONLY census: the X1 token appears exactly 3 times
# (include + two call lines), the call lines exactly twice, and the
# capture-region hash below pins BOTH calls inside the bounded block
[ "\$(grep -c 'gate4_x1' "\$SA" || true)" = 3 ] || { echo "REFUSED: gate4_x1 token census != 3 (include + two bounded-branch calls)" >&2; exit 69; }
[ "\$(grep -c 'gate4_x1::' "\$SA" || true)" = 2 ] || { echo "REFUSED: gate4_x1:: call census != 2" >&2; exit 69; }
echo "$(pins.patched_sha)  \$SA" | sha256sum -c - >/dev/null || { echo "REFUSED: patched solve_adept.cpp sha != pinned" >&2; exit 69; }
[ "\$(sed -n '$(pins.capture_region.a),$(pins.capture_region.b)p' "\$SA" | sha256sum | cut -d' ' -f1)" = "$(pins.capture_region.sha)" ] || { echo "REFUSED: patched capture-region hash mismatch" >&2; exit 69; }
# BOUNDS-ON ONLY: the ENTIRE tail from the unbounded else block to EOF
# must hash IDENTICALLY in the original and the patched file (no X1
# hook executes on the unbounded path)
[ "\$(sed -n '$(pins.unbounded_tail_orig_start),\$p' "\$RUNROOT/solve_adept.cpp.orig" | sha256sum | cut -d' ' -f1)" = "$(pins.unbounded_tail_sha)" ] || { echo "REFUSED: original unbounded-tail hash mismatch" >&2; exit 69; }
[ "\$(sed -n '$(pins.unbounded_tail_patched_start),\$p' "\$SA" | sha256sum | cut -d' ' -f1)" = "$(pins.unbounded_tail_sha)" ] || { echo "REFUSED: unbounded branch/tail changed by the patch" >&2; exit 69; }
ORIG_LC=\$(wc -l < "\$RUNROOT/solve_adept.cpp.orig")
NEW_LC=\$(wc -l < "\$SA")
[ "\$NEW_LC" = "\$((ORIG_LC + 4))" ] || { echo "REFUSED: patch changed \$((NEW_LC - ORIG_LC)) lines, expected exactly 4" >&2; exit 69; }
# AMONG THE $X1_TREE_FILES REGISTERED ARTIFACT FILES, only
# solve_adept.cpp changed; the capture helper is the ONE registered
# addition (pinned above). Generated build files from stage 3 are
# legitimately outside the registered manifest.
( cd "\$SRCDIR" && sha256sum -c <<'POSTPATCHTREE' >/dev/null ) || { echo "REFUSED: post-patch tree differs beyond the registered one-file change" >&2; exit 69; }
$postpatch_tree_lines
POSTPATCHTREE
echo "--- unified diff (the ONLY scientific-source change; helper is a new pinned file) ---"
diff -u "\$RUNROOT/solve_adept.cpp.orig" "\$SA" || true

echo "=== X1-lw stage 5: X1 instrumented rebuild (same tree/configure/toolchain) ==="
make -j"\$SLURM_CPUS_PER_TASK"
test -x "\$SRCDIR/src/ecckd/optimize_lut" || { echo "REFUSED: X1 optimize_lut not built" >&2; exit 68; }
cp -- "\$SRCDIR/src/ecckd/optimize_lut" "\$RUNROOT/bin/optimize_lut_x1"
chmod a-w "\$RUNROOT/bin/optimize_lut_x1"
cp -- "\$SRCDIR/config.log" "\$RUNROOT/config.log.x1"
PR_BIN_SHA=\$(sha256sum "\$RUNROOT/bin/optimize_lut_pristine" | cut -d' ' -f1)
X1_BIN_SHA=\$(sha256sum "\$RUNROOT/bin/optimize_lut_x1" | cut -d' ' -f1)
echo "pristine binary: \$PR_BIN_SHA"
echo "X1 binary:       \$X1_BIN_SHA"
[ "\$PR_BIN_SHA" != "\$X1_BIN_SHA" ] || { echo "REFUSED: pristine and X1 binaries identical; the instrument did not enter the binary" >&2; exit 68; }

echo "=== X1-lw stage 6: per-run-set wrappers (Netlib preload + FP-trap shim) + loader proofs ==="
sha256sum -c <<'RUNTIMEPINS' || { echo "REFUSED: runtime BLAS/LAPACK/shim pin mismatch" >&2; exit 79; }
$X1_NETLIB_BLAS_SHA  $X1_NETLIB_BLAS
$X1_NETLIB_LAPACK_SHA  $X1_NETLIB_LAPACK
$X1_SHIM_SO_SHA  $X1_SHIM_SO
RUNTIMEPINS
command -v readelf >/dev/null || { echo "MISSING readelf" >&2; exit 65; }
RE_BLAS=\$(readelf -d "$X1_NETLIB_BLAS")
RE_LAPACK=\$(readelf -d "$X1_NETLIB_LAPACK")
[ "\$(grep -cF 'Library soname: [libblas.so.3]' <<<"\$RE_BLAS" || true)" = 1 ] || { echo "REFUSED: netlib BLAS SONAME != libblas.so.3" >&2; exit 79; }
[ "\$(grep -cF 'Library soname: [liblapack.so.3]' <<<"\$RE_LAPACK" || true)" = 1 ] || { echo "REFUSED: netlib LAPACK SONAME != liblapack.so.3" >&2; exit 79; }
for runset in probe pristine x1; do
    case "\$runset" in probe|x1) BINSET=x1;; pristine) BINSET=pristine;; esac
    W="\$RUNROOT/tools/optimize_lut_wrap_\$runset"
    cat > "\$W" <<WRAP
#!/bin/bash
export LD_PRELOAD="$X1_NETLIB_BLAS:$X1_NETLIB_LAPACK:$X1_SHIM_SO"
exec "\$RUNROOT/bin/optimize_lut_\$BINSET" "\\\$@"
WRAP
    chmod +x "\$W"
    sha256sum "\$W"
    [ "\$(grep -cxF 'export LD_PRELOAD="$X1_NETLIB_BLAS:$X1_NETLIB_LAPACK:$X1_SHIM_SO"' "\$W" || true)" = 1 ] || { echo "REFUSED: wrapper preload line/order drifted (\$runset)" >&2; exit 79; }
done
for b in pristine x1; do
    LDD_OUT=\$(LD_PRELOAD="$X1_NETLIB_BLAS:$X1_NETLIB_LAPACK:$X1_SHIM_SO" ldd "\$RUNROOT/bin/optimize_lut_\$b")
    echo "--- ldd (binary \$b) ---"
    echo "\$LDD_OUT"
    [ "\$(grep -cF "$X1_NETLIB_BLAS" <<<"\$LDD_OUT" || true)" = 1 ] || { echo "REFUSED: exact BLAS preload row count != 1 (\$b)" >&2; exit 79; }
    [ "\$(grep -cF "$X1_NETLIB_LAPACK" <<<"\$LDD_OUT" || true)" = 1 ] || { echo "REFUSED: exact LAPACK preload row count != 1 (\$b)" >&2; exit 79; }
    [ "\$(grep -cF 'liblapack.so.3 =>' <<<"\$LDD_OUT" || true)" = 0 ] || { echo "REFUSED: liblapack.so.3 alias row present (\$b)" >&2; exit 79; }
    [ "\$(grep -cF 'libblas.so.3 =>' <<<"\$LDD_OUT" || true)" = 0 ] || { echo "REFUSED: libblas.so.3 alias row present (\$b)" >&2; exit 79; }
    LN_B=\$(awk -v pat="$X1_NETLIB_BLAS" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
    LN_L=\$(awk -v pat="$X1_NETLIB_LAPACK" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
    LN_S=\$(awk -v pat="$X1_SHIM_SO" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
    { [ -n "\$LN_B" ] && [ -n "\$LN_L" ] && [ -n "\$LN_S" ] && [ "\$LN_B" -lt "\$LN_L" ] && [ "\$LN_L" -lt "\$LN_S" ]; } || { echo "REFUSED: preload row order is not BLAS<LAPACK<H5shim (\$b)" >&2; exit 79; }
done

# RUN ORDER (monitor ruling): PROBE first so a schema bug can never
# consume a full arm, then PRISTINE control, then X1 instrumented.
for runset in probe pristine x1; do
    echo "=== X1-lw stage 7-\$runset: \$runset relative-base run (bounds ON; identical staged inputs; explicit OpenMP controls) ==="
    case "\$runset" in
        probe)    CAPD="\$RUNROOT/sidecar/probe"; CAP="\$CAPD/x1_sidecar_probe.nc";;
        pristine) CAPD=""; CAP="";;
        x1)       CAPD="\$RUNROOT/sidecar/x1"; CAP="\$CAPD/x1_sidecar.nc";;
    esac
    if [ -n "\$CAP" ]; then
        export GATE4_X1_CAPTURE_PATH="\$CAP" GATE4_X1_ARM="\$runset"
    else
        unset GATE4_X1_CAPTURE_PATH GATE4_X1_ARM || true
    fi
    TC="\$RUNROOT/testcopy-\$runset"
    cp -r "\$RUNROOT/test-template" "\$TC"
    chmod -R u+w "\$TC"
    cd "\$TC"
    sed 's/@PACKAGE_VERSION@/1.2/g' version.h.in > version.h
    sed -i \\
      -e "s|^CKDMIP_DIR=.*|CKDMIP_DIR=/shared/home/greg/build/ckdmip-1.0|" \\
      -e "s|^CKDMIP_DATA_DIR=.*|CKDMIP_DATA_DIR=\$RUNROOT/data|" \\
      -e "s|^WORK_DIR=.*|WORK_DIR=\$RUNROOT/work-\$runset|" \\
      -e "s|^BINDIR=.*|BINDIR=\$RUNROOT/bin|" \\
      -e "s|^TRAINING_BOTH=no\$|TRAINING_BOTH=yes|" \\
      -e "s|^OPTIMIZE_LUT=.*|OPTIMIZE_LUT=\$RUNROOT/tools/optimize_lut_wrap_\$runset|" \\
      config.h
    for kv in "CKDMIP_DIR=/shared/home/greg/build/ckdmip-1.0" "CKDMIP_DATA_DIR=\$RUNROOT/data" "WORK_DIR=\$RUNROOT/work-\$runset" "BINDIR=\$RUNROOT/bin" "TRAINING_BOTH=yes" "OPTIMIZE_LUT=\$RUNROOT/tools/optimize_lut_wrap_\$runset"; do
        grep -qxF "\$kv" config.h || { echo "BAD config override (\$runset): \$kv" >&2; exit 68; }
    done
    sed -i 's|^[[:space:]]*test "\\\${PIPESTATUS\\[0\\]}" -eq 0[[:space:]]*\$|\\trc="\${PIPESTATUS[0]}"; if [ "\$rc" -ne 0 ]; then if [ "\$rc" -ge 128 ]; then echo "OPTIMIZE_LUT CHILD KILLED BY SIGNAL \$((rc-128)) (rc=\$rc)" >\\&2; else echo "OPTIMIZE_LUT CHILD FAILED rc=\$rc" >\\&2; fi; exit "\$rc"; fi|' optimize_lut_lw.sh
    grep -q "OPTIMIZE_LUT CHILD" optimize_lut_lw.sh || { echo "BAD sed: child-status surfacing not applied (\$runset)" >&2; exit 68; }
    grep -qF 'test "\${PIPESTATUS[0]}" -eq 0' optimize_lut_lw.sh && { echo "BAD sed: raw PIPESTATUS test remains (\$runset)" >&2; exit 68; } || true
    if [ "\$runset" = probe ]; then
        # 1-iteration PROBE: append max_iterations=1 as a command-line
        # config override (the generated cfg has no max_iterations key;
        # the compiled default is 3000); the runtime banner is the
        # authoritative proof below
        sed -i 's|model_id=lw_\${APPLICATION}_\${BANDSTRUCT}-tol\${TOL} \\\\\$|&\\n\\t    max_iterations=1 \\\\|' optimize_lut_lw.sh
        [ "\$(grep -cF 'max_iterations=1 \\' optimize_lut_lw.sh || true)" = 1 ] || { echo "REFUSED: probe max_iterations override not exactly once" >&2; exit 68; }
    else
        [ "\$(grep -cF 'max_iterations' optimize_lut_lw.sh || true)" = 0 ] || { echo "REFUSED: max_iterations override leaked into \$runset" >&2; exit 68; }
    fi
    echo "runset \$runset: OMP_NUM_THREADS=\$SLURM_CPUS_PER_TASK OMP_DYNAMIC=FALSE SLURM_CPUS_PER_TASK=\$SLURM_CPUS_PER_TASK GATE4_X1_CAPTURE_PATH=\${GATE4_X1_CAPTURE_PATH:-<unset>} GATE4_X1_ARM=\${GATE4_X1_ARM:-<unset>}" | tee "\$RUNROOT/\$runset-base-run.log"
    OMP_NUM_THREADS="\$SLURM_CPUS_PER_TASK" OMP_DYNAMIC=FALSE \\
        APPLICATION=climate BAND_STRUCTURE=fsck TOLERANCE=0.0161 \\
        bash optimize_lut_lw.sh relative-base |& tee -a "\$RUNROOT/\$runset-base-run.log"
    RLOG="\$RUNROOT/\$runset-base-run.log"
    if [ "\$runset" = probe ]; then
        [ "\$(grep -cF '$banner_1' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: probe did not show exactly one Adept banner (1/0.02)" >&2; exit 71; }
        [ "\$(grep -cF '$banner_3000' "\$RLOG" || true)" = 0 ] || { echo "REFUSED: probe unexpectedly ran 3000 iterations" >&2; exit 71; }
    else
        [ "\$(grep -cF '$banner_3000' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$runset run did not show exactly one Adept banner (3000/0.02)" >&2; exit 71; }
    fi
    [ "\$(grep -cF 'Minimization is bounded' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$runset run did not log bounded mode" >&2; exit 71; }
    [ "\$(grep -cF 'number bounded below:' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$runset bounded-census line not exactly once" >&2; exit 71; }
    [ "\$(grep -cF 'Optimizing coefficients of: composite h2o o3 co2' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$runset base gas banner not exactly once" >&2; exit 71; }
    [ "\$(grep -cF 'Convergence status: ' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$runset convergence-status line not exactly once" >&2; exit 71; }
    # extract the EXACT terminal status; ONLY 'Converged' or 'Maximum
    # iterations reached' are acceptable for this experiment -- error
    # or non-converged terminals refuse even though raw2 exists
    ST_LINE=\$(grep -F 'Convergence status: ' "\$RLOG")
    RUN_STATUS="\${ST_LINE#*Convergence status: }"
    { [ "\$RUN_STATUS" = "Converged" ] || [ "\$RUN_STATUS" = "Maximum iterations reached" ]; } || { echo "REFUSED: \$runset terminal status '\$RUN_STATUS' outside the experiment-allowed set (Converged | Maximum iterations reached)" >&2; exit 71; }
    printf '%s' "\$RUN_STATUS" > "\$RUNROOT/\$runset-status.txt"
    R2="\$RUNROOT/work-\$runset/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
    test -s "\$R2" || { echo "MISSING \$runset raw2 output" >&2; exit 71; }
    if [ -n "\$CAP" ]; then
        [ "\$(grep -cF 'X1 CAPTURE WRITTEN: ' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$runset capture-written line not exactly once" >&2; exit 71; }
        [ "\$(grep -cF 'X1 CAPTURE REFUSED' "\$RLOG" || true)" = 0 ] || { echo "REFUSED: \$runset logged a capture refusal" >&2; exit 71; }
        test -s "\$CAP" || { echo "REFUSED: \$runset sidecar missing/empty: \$CAP" >&2; exit 71; }
        [ "\$(find "\$CAPD" -name '.x1-capture.*' | wc -l)" = 0 ] || { echo "REFUSED: non-atomic capture remnant in \$CAPD" >&2; exit 71; }
        if [ "\$runset" = probe ]; then VEXIT=94; else VEXIT=96; fi
        (cd $X1_PROJECT_ROOT && julia --project=test "\$RUNROOT/tools/gate4_x1_sidecar_validator.jl" sidecar "\$CAP" "\$runset" "\$R2" "\$RUN_STATUS") || { echo "REFUSED: \$runset sidecar validation failed (schema/order/types/projection/status/Axis-C readback); instrument refusal, not a finding" >&2; exit \$VEXIT; }
        sha256sum "\$CAP"
    else
        [ "\$(grep -cF 'X1 CAPTURE' "\$RLOG" || true)" = 0 ] || { echo "REFUSED: pristine run logged capture activity" >&2; exit 71; }
    fi
done
unset GATE4_X1_CAPTURE_PATH GATE4_X1_ARM || true

echo "=== X1-lw stage 8: private outputs (independent schema verification; identity gate; ZERO canonical writes by design) ==="
# STAGED-INPUT IDENTITY ENFORCED THROUGH THE RUNS (monitor ruling):
# after probe+pristine+X1 and before ANY success claim, all six staged
# data files are re-verified size+sha against the SAME pinned manifest
# and the zero-writable state is reasserted
while read -r esz p; do
    asz=\$(stat -Lc %s "\$p") || { echo "REFUSED: cannot stat staged data file post-run: \$p" >&2; exit 78; }
    [ "\$asz" = "\$esz" ] || { echo "REFUSED: staged data input size drifted during the runs: \$p (\$asz != \$esz)" >&2; exit 78; }
done <<DATAPOSTSIZES
$data_post_size_lines
DATAPOSTSIZES
sha256sum -c <<DATAPOST >/dev/null || { echo "REFUSED: staged data input drifted during the runs (sha mismatch)" >&2; exit 78; }
$data_post_hash_lines
DATAPOST
WLIST2=\$(find "\$RUNROOT/data" -writable) || { echo "REFUSED: post-run writable-entry scan failed on the staged data tree" >&2; exit 78; }
[ -z "\$WLIST2" ] || { echo "REFUSED: writable entries appeared in the staged data tree during the runs" >&2; printf '%s\\n' "\$WLIST2" >&2; exit 78; }
echo "staged data inputs re-verified post-run (6 files, size+sha, zero writable entries)"
for runset in probe pristine x1; do
    R2="\$RUNROOT/work-\$runset/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
    test -s "\$R2" || { echo "MISSING \$runset raw2 output" >&2; exit 71; }
    (cd $X1_PROJECT_ROOT && RAW2_PATH="\$R2" julia --project=test -e '
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
') || { echo "REFUSED: \$runset raw2 failed independent netCDF schema/finite verification" >&2; exit 71; }
    sha256sum "\$R2"
done
PROBE_STATUS=\$(cat "\$RUNROOT/probe-status.txt")
PR_STATUS=\$(cat "\$RUNROOT/pristine-status.txt")
X1_STATUS=\$(cat "\$RUNROOT/x1-status.txt")
echo "STATUS RECORD (descriptive, for the completion ledger): probe='\$PROBE_STATUS' pristine='\$PR_STATUS' x1='\$X1_STATUS'"
# full-arm terminal statuses must be EQUAL before non-perturbation can
# be licensed by the identity gate
[ "\$PR_STATUS" = "\$X1_STATUS" ] || { echo "REFUSED: pristine/X1 terminal statuses differ ('\$PR_STATUS' vs '\$X1_STATUS'); non-perturbation not licensed" >&2; exit 95; }
PR_R2="\$RUNROOT/work-pristine/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
X1_R2="\$RUNROOT/work-x1/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
# THE identity gate: all-variable logical identity, value differences
# allowed ONLY in config/history. Violation is INSTRUMENT REFUSAL of
# X1 (never elimination, never a finding); RUNROOT is preserved either
# way. Non-perturbation is licensed ONLY by this gate passing.
if (cd $X1_PROJECT_ROOT && julia --project=test "\$RUNROOT/tools/gate4_x1_sidecar_validator.jl" identity "\$PR_R2" "\$X1_R2" config,history 47); then
    echo "X1 IDENTITY GATE: PASS (X1-arm raw2 logically identical to pristine-arm raw2 across all variables; non-perturbation licensed by this empirical gate)"
else
    echo "X1 IDENTITY GATE: REFUSED -- observed NetCDF LOGICAL differences between pristine and X1 arms; instrument refusal, not a finding; RUNROOT preserved" >&2
    exit 95
fi
echo "secondary historical echo (4515 modern raw2; informational only, never causal): $X1_MODERN_RAW2_SHA"
sha256sum "\$RUNROOT/probe-base-run.log" "\$RUNROOT/pristine-base-run.log" "\$RUNROOT/x1-base-run.log" \\
    "\$RUNROOT/solve_adept.cpp.orig" "\$SRCDIR/$X1_SOLVE_ADEPT_REL" "\$SRCDIR/$X1_HELPER_REL" \\
    "\$RUNROOT/bin/optimize_lut_pristine" "\$RUNROOT/bin/optimize_lut_x1" \\
    "\$RUNROOT/sidecar/probe/x1_sidecar_probe.nc" "\$RUNROOT/sidecar/x1/x1_sidecar.nc"
echo "RUNROOT preserved for diagnosis/forensics: \$RUNROOT (no cleanup by design)"
echo "=== X1-lw done \$(date -u +%FT%TZ) ==="
"""
end

# --- text gates ---------------------------------------------------------------------

function x1_bash_syntax_ok(text)
    try
        p = joinpath(mktempdir(), "x1_syntax_check.sbatch")
        write(p, text)
        success(pipeline(`bash -n $p`, stdout = devnull, stderr = devnull))
    catch
        false
    end
end

function x1_text_gate_issues(text, pins)
    iss = String[]
    req = [
        "REFUSED: head-node execution is not permitted",
        "RUNROOT=\"\$G4WORK/g4-diag/\${SLURM_JOB_ID}/lw-x1\"",
        "cp -rT \"$X1_SRC_ARTIFACT\" \"\$SRCDIR\"",
        X1_DESIGN_SHA,
        "$X1_PROJECT_ROOT/$X1_DESIGN_REPO_PATH",
        X1_ORIG_SOLVE_ADEPT_SHA,
        pins.patched_sha,
        pins.capture_region.sha,
        pins.unbounded_tail_sha,
        X1_HELPER_SHA,
        "X1HELPER",
        X1_INCLUDE_LINE,
        X1_CALLSITE_LINES[1],
        X1_CALLSITE_LINES[2],
        X1_CALLSITE_LINES[3],
        X1_CALLSITE_LINES[4],
        "REFUSED: gate4_x1 token census != 3 (include + two bounded-branch calls)",
        "REFUSED: gate4_x1:: call census != 2",
        "REFUSED: unbounded branch/tail changed by the patch",
        "solve_adept.cpp.orig",
        "diff -u",
        "autoreconf -i",
        X1_CONFIGURE_ARGV,
        "optimize_lut_pristine",
        "optimize_lut_x1",
        "chmod a-w \"\$RUNROOT/bin/optimize_lut_pristine\"",
        "chmod a-w \"\$RUNROOT/bin/optimize_lut_x1\"",
        "config.status --config",
        "REFUSED: pristine and X1 binaries identical",
        "ARTTREE", "COPYTREE", "POSTPATCHTREE", "EXECBITS",
        "TEMPLATEPINS",
        "/usr/bin/gcc",
        "gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0",
        "GNU Make 4.3",
        "bash optimize_lut_lw.sh relative-base",
        "TRAINING_BOTH=yes",
        "APPLICATION=climate BAND_STRUCTURE=fsck TOLERANCE=0.0161",
        "Minimization is bounded",
        "number bounded below:",
        "OMP_NUM_THREADS=\"\$SLURM_CPUS_PER_TASK\" OMP_DYNAMIC=FALSE",
        "REFUSED: config.status --config != corrected reviewed recipe rendering",
        X1_CONFIG_STATUS_EXPECT,
        "'LDFLAGS=-L$X1_ADEPT/lib -Wl,-rpath,$X1_ADEPT/lib'",
        "'LIBS=-ladept'",
        X1_S1_LEDGER_SHA,
        X1_S1_LEDGER,
        "CAP=\"\$CAPD/x1_sidecar_probe.nc\"",
        "CAP=\"\$CAPD/x1_sidecar.nc\"",
        "export GATE4_X1_CAPTURE_PATH=\"\$CAP\" GATE4_X1_ARM=\"\$runset\"",
        "unset GATE4_X1_CAPTURE_PATH GATE4_X1_ARM || true",
        "max_iterations=1",
        "max iterations = 1, convergence criterion = 0.02",
        "max iterations = 3000, convergence criterion = 0.02",
        "X1 CAPTURE WRITTEN: ",
        "X1 CAPTURE REFUSED",
        "chmod -R a-w \"\$RUNROOT/data\"",
        "REFUSED: writable entries remain in the staged data tree after chmod",
        "staged data tree locked read-only (zero writable entries)",
        "DATAPOSTSIZES",
        "DATAPOST",
        "REFUSED: staged data input drifted during the runs (sha mismatch)",
        "REFUSED: writable entries appeared in the staged data tree during the runs",
        "staged data inputs re-verified post-run (6 files, size+sha, zero writable entries)",
        "ALIASPROBE",
        X1_ALIAS_PROBE_SHA,
        X1_ALIAS_PROBE_OK,
        X1_ARRAY_H_SHA,
        "RUN_STATUS=\"\${ST_LINE#*Convergence status: }\"",
        "outside the experiment-allowed set (Converged | Maximum iterations reached)",
        "printf '%s' \"\$RUN_STATUS\" > \"\$RUNROOT/\$runset-status.txt\"",
        "STATUS RECORD (descriptive, for the completion ledger):",
        "REFUSED: pristine/X1 terminal statuses differ",
        X1_ADEPT_SOURCE_H_SHA,
        "gate4_x1_sidecar_validator.jl\" sidecar \"\$CAP\" \"\$runset\" \"\$R2\" \"\$RUN_STATUS\"",
        "gate4_x1_sidecar_validator.jl\" identity \"\$PR_R2\" \"\$X1_R2\" config,history 47",
        "X1 IDENTITY GATE: PASS",
        "X1 IDENTITY GATE: REFUSED",
        "VEXIT=94", "VEXIT=96", "exit 95", "exit \$VEXIT",
        "raw2 independent schema/finite verification passed",
        "RUNROOT preserved for diagnosis/forensics",
        "flock -n 9",
        "cp -r \"\$SRCDIR/test\" \"\$RUNROOT/test-template\"",
        "chmod -R a-w \"\$RUNROOT/test-template\"",
        "cp -r \"\$RUNROOT/test-template\" \"\$TC\"",
        "index(\$0, pat) && !ln { ln = NR }"]
    for r in req
        occursin(r, text) || push!(iss, "required text missing: $r")
    end
    occursin("cp -r \"$X1_SRC_ARTIFACT/test\"", text) &&
        push!(iss, "forbidden run-stage copy from the LIVE artifact test dir")
    # exact occurrence counts
    for (pat, n, what) in (
        (r"bash optimize_lut_lw\.sh relative-base", 1,
         "relative-base invocation (single line inside the run loop)"),
        (r"for runset in probe pristine x1; do", 4,
         "probe/pristine/x1 loops (mkdir, wrappers, run, outputs)"),
        (r"for b in pristine x1; do", 1, "per-binary ldd loop"),
        (Regex("(?m)^\\s*export GATE4_X1_CAPTURE_PATH=\"\\\$CAP\" GATE4_X1_ARM=\"\\\$runset\"\$"), 1,
         "capture-env export line"),
        (Regex("\\Q" * X1_CONFIGURE_ARGV * "\\E"), 1, "corrected configure invocation"),
        (Regex("\\Q" * X1_CONFIG_STATUS_EXPECT * "\\E"), 1, "config.status expectation"),
        (Regex("\\Q'LIBS=-ladept'\\E"), 1, "quoted LIBS assignment"),
        (Regex("\\Qmax_iterations=1\\E"), 4,
         "probe-only iteration override (header comment + probe comment + sed payload + count gate)"),
        (Regex("\\Q" * X1_CALLSITE_LINES[1] * "\\E"), 2,
         "bounded-branch record_pre line (sed payload + count assert)"),
        (Regex("\\Q" * X1_CALLSITE_LINES[3] * "\\E"), 2,
         "bounded-branch write_capture line (sed payload + count assert)"),
        (Regex("\\Qchmod -R a-w \"\$RUNROOT/data\"\\E"), 1,
         "data-tree immutability lock"),
        (Regex("\\Qfind \"\$RUNROOT/data\" -writable\\E"), 2,
         "writable-entry scans (post-staging + post-run)"))
        m = length(collect(eachmatch(pat, text)))
        m == n || push!(iss, "$what expected exactly $n, got $m")
    end
    # every literal CAP= assignment must be empty (pristine) or end .nc
    for m in eachmatch(r"(?m)CAP=\"([^\"]*)\"", text)
        v = m.captures[1]
        (v == "" || endswith(v, ".nc")) ||
            push!(iss, "capture path violates the .nc naming rule: $(m.match)")
    end
    for bad in ("relative-ch4", "relative-n2o", "relative-cfc",
                "CANON_FINAL", "mv -n", ".g3.publish.",
                "$X1_G4WORK/work/lw_ckd-definition/ecckd-1.2_lw_ckd-definition")
        occursin(bad, text) && push!(iss, "forbidden text present: $bad")
    end
    for m in eachmatch(r"LDFLAGS=[^']*-ladept", text)
        push!(iss, "-ladept inside LDFLAGS (order-broken position): $(m.match)")
    end
    for m in eachmatch(r"\|\s*head\b", text)
        push!(iss, "early-closing head pipeline present: $(m.match)")
    end
    for m in eachmatch(r"(?m)^.*\bstrings\b.*Adept LBFGS.*= 0.*$", text)
        push!(iss, "binary strings absence test (banned class): $(m.match)")
    end
    for m in eachmatch(r"(?m)^[^#\n]*> *\"?\$G4WORK/(?!g4-diag|locks/x1-lw\.lock)", text)
        push!(iss, "redirect toward shared G4WORK area: $(m.match)")
    end
    iss
end

# --- fixture synthetic-data writers --------------------------------------------------

const X1F_EXPECT = (
    nrows = 48,
    gas_names = ["composite", "h2o", "o3", "co2"],
    offsets = [0, 8, 32, 40],
    sizes = [8, 24, 8, 8],
    nconc = [-1, 3, -1, -1],
    nt = [2, 2, 2, 2],
    np = [2, 2, 2, 2],
    ng = [2, 2, 2, 2])

# build a fully-valid in-memory sidecar spec for X1F_EXPECT; fixtures
# tamper with the spec (or the file) before/after serialization
function x1f_sidecar_spec(; expect = X1F_EXPECT, arm = "probe")
    n = expect.nrows
    nblk = length(expect.gas_names)
    gid = zeros(Int32, n); goff = zeros(Int32, n)
    ic = fill(Int32(-1), n); it = zeros(Int32, n)
    ip = zeros(Int32, n); ig = zeros(Int32, n)
    for k in 1:nblk
        off = expect.offsets[k]
        nc = expect.nconc[k]
        ntk, npk, ngk = expect.nt[k], expect.np[k], expect.ng[k]
        pos = 0
        for c in 0:(nc == -1 ? 0 : nc - 1), t in 0:(ntk - 1),
            p in 0:(npk - 1), g in 0:(ngk - 1)
            r = off + pos + 1
            gid[r] = k - 1
            goff[r] = off
            ic[r] = nc == -1 ? -1 : c
            it[r] = t; ip[r] = p; ig[r] = g
            pos += 1
        end
        pos == expect.sizes[k] || error("fixture spec block size bug")
    end
    lc = Int32[i % 3 for i in 0:(n - 1)]
    ua = Int32[i % 2 for i in 0:(n - 1)]
    FMAX = floatmax(Float64)
    ret = [-5.0 + 0.001 * i for i in 0:(n - 1)]
    ret[3] = -1.0e20 # floor row: mapped must be exactly 0.0
    lo = [lc[i + 1] == 0 ? -FMAX : -30.0 - i for i in 0:(n - 1)]
    hi = [ua[i + 1] == 0 ? FMAX : 10.0 + i for i in 0:(n - 1)]
    mp = [ret[i + 1] > X1V_MIN_X_LOG_FLOOR ? exp(ret[i + 1]) : 0.0
          for i in 0:(n - 1)]
    ph = [1.0e-3 * (1 + i) + 1.0e-11 * i for i in 0:(n - 1)]
    f32 = Float32.(ph)
    Dict{String, Any}(
        "dims" => Dict{String, Int}("x_index" => n, "active_gas" => nblk),
        "vars" => Dict{String, Any}(
            "global_x_index" => (Int32, ("x_index",), collect(Int32, 0:(n - 1))),
            "gas_id" => (Int32, ("x_index",), gid),
            "gas_offset" => (Int32, ("x_index",), goff),
            "iconc" => (Int32, ("x_index",), ic),
            "itemp" => (Int32, ("x_index",), it),
            "ipress" => (Int32, ("x_index",), ip),
            "igpoint" => (Int32, ("x_index",), ig),
            "lower_class" => (Int32, ("x_index",), lc),
            "upper_active" => (Int32, ("x_index",), ua),
            "returned_x_log" => (Float64, ("x_index",), ret),
            "bound_lo_log" => (Float64, ("x_index",), lo),
            "bound_hi_log" => (Float64, ("x_index",), hi),
            "mapped_x_phys" => (Float64, ("x_index",), mp),
            "caller_phys" => (Float64, ("x_index",), ph),
            "caller_phys_f32" => (Float32, ("x_index",), f32),
            "gas_block_offset" => (Int32, ("active_gas",), Int32.(expect.offsets)),
            "gas_block_size" => (Int32, ("active_gas",), Int32.(expect.sizes)),
            "gas_block_nconc" => (Int32, ("active_gas",), Int32.(expect.nconc)),
            "gas_block_ntemperature" => (Int32, ("active_gas",), Int32.(expect.nt)),
            "gas_block_npressure" => (Int32, ("active_gas",), Int32.(expect.np)),
            "gas_block_ng_point" => (Int32, ("active_gas",), Int32.(expect.ng)),
            "minimizer_status" => (Int32, (), Int32(2)),
            "min_x_log_floor" => (Float64, (), X1V_MIN_X_LOG_FLOOR)),
        "attrs" => Dict{String, Any}(
            "gas_names" => join(expect.gas_names, " "),
            "index_base" => Int32(0),
            "arm" => arm,
            "job_id" => "12345",
            "capture_location" => X1V_CAPTURE_LOCATION,
            "minimizer_status_string" => "Maximum iterations reached",
            "contract" => X1V_CONTRACT))
end

function x1f_write_spec(path, spec)
    isfile(path) && rm(path)
    NCDataset(path, "c") do ds
        for (d, len) in sort(collect(spec["dims"]); by = first)
            defDim(ds, d, len)
        end
        for name in sort(collect(keys(spec["vars"])))
            ty, dims, data = spec["vars"][name]
            v = defVar(ds, name, ty, dims)
            if isempty(dims)
                v[] = convert(ty, data)
            else
                v[:] = convert(Vector{ty}, data)
            end
        end
        for (a, val) in sort(collect(spec["attrs"]); by = first)
            ds.attrib[a] = val
        end
    end
    path
end

# synthetic raw2 carrying EXACTLY the sidecar's caller_phys_f32 values
# at the mapped positions (Axis-C readback fixture target)
function x1f_write_raw2(path, spec; expect = X1F_EXPECT,
                        perturb::Union{Nothing, Int} = nothing,
                        permute_dims::Bool = false)
    f32 = Vector{Float32}(spec["vars"]["caller_phys_f32"][3])
    ic = spec["vars"]["iconc"][3]
    it = spec["vars"]["itemp"][3]
    ip = spec["vars"]["ipress"][3]
    ig = spec["vars"]["igpoint"][3]
    perturb !== nothing && (f32[perturb] = nextfloat(f32[perturb]))
    isfile(path) && rm(path)
    NCDataset(path, "c") do ds
        defDim(ds, "g_point", expect.ng[1])
        defDim(ds, "pressure", expect.np[1])
        defDim(ds, "temperature", expect.nt[1])
        defDim(ds, "h2o_mole_fraction", expect.nconc[2])
        for k in 1:length(expect.gas_names)
            gas = expect.gas_names[k]
            nc = expect.nconc[k]
            dims = nc == -1 ?
                ("g_point", "pressure", "temperature") :
                ("g_point", "pressure", "temperature", "h2o_mole_fraction")
            permute_dims && nc == -1 &&
                (dims = ("temperature", "pressure", "g_point"))
            A = nc == -1 ?
                zeros(Float32, expect.ng[k], expect.np[k], expect.nt[k]) :
                zeros(Float32, expect.ng[k], expect.np[k], expect.nt[k], nc)
            for i in (expect.offsets[k] + 1):(expect.offsets[k] + expect.sizes[k])
                if nc == -1
                    A[ig[i] + 1, ip[i] + 1, it[i] + 1] = f32[i]
                else
                    A[ig[i] + 1, ip[i] + 1, it[i] + 1, ic[i] + 1] = f32[i]
                end
            end
            v = defVar(ds, gas * "_molar_absorption_coeff", Float32, dims)
            v[:] = vec(A)
            v.attrib["units"] = "m2 mol-1"
        end
        ds.attrib["config"] = "fixture config"
        ds.attrib["history"] = "fixture history"
    end
    path
end

# small generic NetCDF pair for identity-gate fixtures
function x1f_write_pair(dir; tamper = :none, nvars = 2,
                        history_differs = false,
                        config_type_mismatch = false)
    a = joinpath(dir, "ident_a.nc")
    b = joinpath(dir, "ident_b.nc")
    for (p, second) in ((a, false), (b, true))
        isfile(p) && rm(p)
        NCDataset(p, "c") do ds
            defDim(ds, "n", 5)
            v = defVar(ds, "alpha", Float64, ("n",))
            v[:] = [1.0, 2.0, 3.0, 4.0, 5.0]
            v.attrib["units"] = tamper == :var_attr && second ? "m2" : "m"
            w = defVar(ds, "beta", Int32, ("n",))
            w[:] = Int32[1, 2, 3, 4, tamper == :value && second ? 99 : 5]
            for k in 3:nvars
                e = defVar(ds, "filler_" * lpad(k, 3, '0'), Float64, ("n",))
                e[:] = fill(Float64(k), 5)
            end
            if tamper == :extra_var && second
                e = defVar(ds, "gamma", Float64, ("n",))
                e[:] = zeros(5)
            end
            if config_type_mismatch && second
                ds.attrib["config"] = Int32(7) # TYPE mismatch vs string
            else
                ds.attrib["config"] = second ? "config B" : "config A"
            end
            ds.attrib["history"] = second && history_differs ?
                "history B" : "same history"
            ds.attrib["title"] = tamper == :global_attr && second ?
                "title B" : "title"
        end
    end
    (a, b)
end

# --- fixtures ------------------------------------------------------------------------

function x1_fixtures(tree, pins)
    t = Dict{String, Bool}()
    fx = mktempdir()
    shaof(p) = bytes2hex(sha256(read(p)))

    # A. prerequisite-ledger classifier
    cls(p; kw...) = x1_classify_ledger(p; kw...)
    t["ledger_missing_refuses"] =
        cls(joinpath(fx, "absent.json")).class == "missing"
    p = joinpath(fx, "bad.json"); write(p, "{oops")
    t["ledger_unparseable_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "unparseable (parse failure)"
    p = joinpath(fx, "st.json")
    write(p, JSON.json(Dict("case" => X1_S1_LEDGER_CASE,
                            "status" => "s1_completion_ledger_refused")))
    t["ledger_status_mismatch_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "status mismatch"
    p = joinpath(fx, "green.json")
    write(p, JSON.json(Dict("case" => X1_S1_LEDGER_CASE,
                            "status" => X1_S1_LEDGER_STATUS)))
    t["ledger_sha_drift_refuses"] =
        cls(p; expected_sha = "0" ^ 64).class == "sha drift"
    t["ledger_green_accepted"] = cls(p; expected_sha = shaof(p)).ok

    # B. artifact tree manifest
    t["tree_census_119"] = length(tree) == X1_TREE_FILES
    t["tree_exec_census_24"] = count(e -> e.exec, tree) == X1_TREE_EXEC
    sa = [e for e in tree if e.rel == X1_SOLVE_ADEPT_REL]
    t["tree_contains_solve_adept_pin"] =
        length(sa) == 1 && sa[1].sha == X1_ORIG_SOLVE_ADEPT_SHA
    t["tree_has_no_helper"] =
        !any(e -> e.rel == X1_HELPER_REL, tree)
    t["tree_patched_manifest_single_delta"] = begin
        orig_lines = ["$(e.sha)  $(e.rel)" for e in tree]
        patched_lines = ["$(e.rel == X1_SOLVE_ADEPT_REL ?
            pins.patched_sha : e.sha)  $(e.rel)" for e in tree]
        count(orig_lines .!= patched_lines) == 1
    end

    # C. patch derivation (bounds-ON only)
    orig = read(joinpath(X1_SRC_ARTIFACT, X1_SOLVE_ADEPT_REL), String)
    iss, patched = x1_derive_patched(orig)
    t["patch_derivation_reproduces_pin"] =
        isempty(iss) && patched !== nothing &&
        bytes2hex(sha256(patched)) == pins.patched_sha
    t["patch_line_count_plus4"] = patched !== nothing &&
        pins.patched_lines == pins.orig_lines + 4
    pl = patched === nothing ? String[] :
        split(patched, '\n'; keepempty = true)
    t["patch_include_inserted_once"] =
        count(==(X1_INCLUDE_LINE), pl) == 1
    t["patch_callsite_replaced"] =
        count(==(X1_CALLSITE_ANCHOR), pl) == 0 &&
        all(l -> count(==(l), pl) == 1, X1_CALLSITE_LINES)
    t["patch_record_pre_first_line_of_bounded_block"] = begin
        ci = findfirst(==(X1_CALLSITE_LINES[1]), pl)
        ci !== nothing &&
            pl[ci:(ci + 3)] == X1_CALLSITE_LINES &&
            occursin("gate4_x1::record_pre", pl[ci])
    end
    t["patch_calls_inside_bounded_region_only"] = begin
        calls = [i for (i, l) in enumerate(pl) if occursin("gate4_x1::", l)]
        length(calls) == 2 &&
            all(pins.capture_region.a .<= calls .<= pins.capture_region.b)
    end
    t["patch_capture_region_sha_reproduces"] = !isempty(pl) &&
        x1_region_sha(pl, pins.capture_region.a, pins.capture_region.b) ==
        pins.capture_region.sha
    ol = split(orig, '\n'; keepempty = true)
    t["patch_unbounded_tail_byte_identical"] = !isempty(pl) &&
        x1_tail_sha(ol, pins.unbounded_tail_orig_start) ==
        x1_tail_sha(pl, pins.unbounded_tail_patched_start) ==
        pins.unbounded_tail_sha
    t["patch_unbounded_tail_free_of_x1_hooks"] = !isempty(pl) &&
        !occursin("gate4_x1",
                  join(pl[pins.unbounded_tail_patched_start:end], '\n'))
    t["patch_missing_include_anchor_refuses"] =
        !isempty(x1_derive_patched(replace(orig,
            X1_INCLUDE_ANCHOR => "// include removed"))[1])
    t["patch_missing_callsite_anchor_refuses"] =
        !isempty(x1_derive_patched(replace(orig,
            X1_CALLSITE_ANCHOR => "    // callsite removed"))[1])
    t["patch_duplicate_anchor_refuses"] =
        !isempty(x1_derive_patched(orig * "\n" * X1_CALLSITE_ANCHOR * "\n")[1])
    t["patch_preexisting_token_refuses"] =
        !isempty(x1_derive_patched(replace(orig, X1_INCLUDE_ANCHOR =>
            X1_INCLUDE_ANCHOR * "\n// gate4_x1 already here"))[1])

    # D. capture-helper contract
    t["helper_requires_env_path"] =
        occursin("require_env(\"GATE4_X1_CAPTURE_PATH\")", X1_HELPER_TEXT)
    t["helper_naming_rule_present"] =
        occursin("must end in .nc", X1_HELPER_TEXT) &&
        occursin(".x1-capture.", X1_HELPER_TEXT)
    t["helper_noclobber_netcdf_open"] =
        occursin("open_absolute(tmp, OUTPUT_MODE_NOCLOBBER, NETCDF)",
                 X1_HELPER_TEXT)
    t["helper_atomic_rename_checked"] =
        occursin("std::rename(tmp.c_str(), target.c_str())", X1_HELPER_TEXT) &&
        occursin("atomic rename failed", X1_HELPER_TEXT)
    t["helper_pre_minimize_classification"] =
        occursin("PRE-minimize", X1_HELPER_TEXT) &&
        occursin("callback-mutated", X1_HELPER_TEXT)
    t["helper_global_scope_attr_writes"] =
        length(collect(eachmatch(r"DATA_FILE_GLOBAL_SCOPE",
                                 X1_HELPER_TEXT))) >= 7
    t["helper_exact_bounds_kept"] =
        occursin("EXACT passed entries", X1_HELPER_TEXT) &&
        !occursin("NAN", uppercase(replace(X1_HELPER_TEXT,
            "no NaN or" => "", "sentinel substitution" => "")))
    t["helper_exit_code_93"] =
        occursin("EXIT_CAPTURE_REFUSED = 93", X1_HELPER_TEXT)
    t["helper_global_x_index_var"] =
        occursin("define_variable(\"global_x_index\", INT, \"x_index\")",
                 X1_HELPER_TEXT) &&
        occursin("write(iv_gidx, \"global_x_index\")", X1_HELPER_TEXT)
    t["alias_probe_confirms_shallow_link"] = begin
        # behavioral: compile AND RUN the alias probe; fail unless
        # mutating the by-value/copy alias mutates the original
        d = mktempdir()
        p = joinpath(d, "x1_alias_probe.cpp")
        write(p, X1_ALIAS_PROBE_CPP)
        exe = joinpath(d, "x1_alias_probe")
        okc = success(pipeline(`g++ -std=c++11 -o $exe $p
            -I$X1_ADEPT/include -L$X1_ADEPT/lib
            -Wl,-rpath,$X1_ADEPT/lib -ladept`,
            stdout = devnull, stderr = devnull))
        okc && (try
            strip(read(`$exe`, String)) == X1_ALIAS_PROBE_OK
        catch
            false
        end)
    end
    t["helper_syntax_check_passes"] = begin
        d = mktempdir()
        write(joinpath(d, "gate4_x1_capture.h"), X1_HELPER_TEXT)
        write(joinpath(d, "tu.cpp"), """
            #include "gate4_x1_capture.h"
            void gate4_x1_syntax_anchor(CkdModel<true>& m, const Vector& a,
                                        const Vector& b, const Vector& c,
                                        adept::MinimizerStatus s) {
              gate4_x1::PreState p = gate4_x1::record_pre(m);
              gate4_x1::write_capture(m, a, b, c, p, s, -1.0e20);
            }
            """)
        success(pipeline(`g++ -std=c++11 -fsyntax-only
            -I$d -I$X1_SRC_ARTIFACT/src/include -I$X1_SRC_ARTIFACT/src/ecckd
            -I$X1_ADEPT/include -I$X1_NETCDF/include $(joinpath(d, "tu.cpp"))`,
            stdout = devnull, stderr = devnull))
    end

    # E. validator behavioral fixtures (the SAME code the job runs)
    vd = mktempdir()
    good = x1f_write_spec(joinpath(vd, "good.nc"), x1f_sidecar_spec())
    vs(p; kw...) = x1v_sidecar_issues(p; expect = X1F_EXPECT, kw...)
    t["sidecar_valid_accepted"] = isempty(vs(good; arm = "probe"))
    t["sidecar_missing_refuses"] =
        !isempty(vs(joinpath(vd, "nope.nc"); arm = "probe"))
    t["sidecar_arm_mismatch_refuses"] = !isempty(vs(good; arm = "x1"))
    t["sidecar_temp_remnant_refuses"] = begin
        rd = mktempdir()
        g2 = x1f_write_spec(joinpath(rd, "s.nc"), x1f_sidecar_spec())
        write(joinpath(rd, ".x1-capture.12345.s.nc"), "partial")
        !isempty(vs(g2; arm = "probe"))
    end
    t["sidecar_empty_file_refuses"] = begin
        e = joinpath(vd, "empty.nc"); write(e, "")
        !isempty(vs(e; arm = "probe"))
    end
    t["sidecar_wrong_rows_refuses"] = begin
        sp = x1f_sidecar_spec()
        sp["dims"]["x_index"] = 47
        for (k, (ty, dims, data)) in collect(sp["vars"])
            dims == ("x_index",) && (sp["vars"][k] = (ty, dims, data[1:47]))
        end
        !isempty(vs(x1f_write_spec(joinpath(vd, "rows.nc"), sp); arm = "probe"))
    end
    t["sidecar_wrong_type_refuses"] = begin
        sp = x1f_sidecar_spec()
        ty, dims, data = sp["vars"]["caller_phys_f32"]
        sp["vars"]["caller_phys_f32"] = (Float64, dims, Float64.(data))
        !isempty(vs(x1f_write_spec(joinpath(vd, "type.nc"), sp); arm = "probe"))
    end
    t["sidecar_missing_var_refuses"] = begin
        sp = x1f_sidecar_spec()
        delete!(sp["vars"], "bound_lo_log")
        !isempty(vs(x1f_write_spec(joinpath(vd, "mvar.nc"), sp); arm = "probe"))
    end
    t["sidecar_extra_var_refuses"] = begin
        sp = x1f_sidecar_spec()
        sp["vars"]["surprise"] = (Float64, ("x_index",),
                                  zeros(X1F_EXPECT.nrows))
        !isempty(vs(x1f_write_spec(joinpath(vd, "xvar.nc"), sp); arm = "probe"))
    end
    t["sidecar_wrong_gas_order_refuses"] = begin
        sp = x1f_sidecar_spec()
        ty, dims, data = sp["vars"]["gas_block_offset"]
        d2 = copy(data); d2[3], d2[4] = d2[4], d2[3]
        sp["vars"]["gas_block_offset"] = (ty, dims, d2)
        !isempty(vs(x1f_write_spec(joinpath(vd, "order.nc"), sp); arm = "probe"))
    end
    t["sidecar_duplicate_multiindex_refuses"] = begin
        sp = x1f_sidecar_spec()
        ty, dims, data = sp["vars"]["igpoint"]
        d2 = copy(data); d2[2] = d2[1]
        sp["vars"]["igpoint"] = (ty, dims, d2)
        !isempty(vs(x1f_write_spec(joinpath(vd, "dup.nc"), sp); arm = "probe"))
    end
    t["sidecar_index_out_of_range_refuses"] = begin
        sp = x1f_sidecar_spec()
        ty, dims, data = sp["vars"]["itemp"]
        d2 = copy(data); d2[1] = Int32(99)
        sp["vars"]["itemp"] = (ty, dims, d2)
        !isempty(vs(x1f_write_spec(joinpath(vd, "range.nc"), sp); arm = "probe"))
    end
    t["sidecar_nan_bound_refuses"] = begin
        sp = x1f_sidecar_spec()
        ty, dims, data = sp["vars"]["bound_lo_log"]
        d2 = copy(data); d2[1] = NaN
        sp["vars"]["bound_lo_log"] = (ty, dims, d2)
        !isempty(vs(x1f_write_spec(joinpath(vd, "nan.nc"), sp); arm = "probe"))
    end
    t["sidecar_sentinel_bound_refuses"] = begin
        sp = x1f_sidecar_spec()
        lcv = sp["vars"]["lower_class"][3]
        i0 = findfirst(==(Int32(0)), lcv)
        ty, dims, data = sp["vars"]["bound_lo_log"]
        d2 = copy(data); d2[i0] = -1.0e20 # MIN_X sentinel instead of -floatmax
        sp["vars"]["bound_lo_log"] = (ty, dims, d2)
        !isempty(vs(x1f_write_spec(joinpath(vd, "sent.nc"), sp); arm = "probe"))
    end
    t["sidecar_projection_mismatch_refuses"] = begin
        sp = x1f_sidecar_spec()
        ty, dims, data = sp["vars"]["caller_phys_f32"]
        d2 = copy(data); d2[5] = nextfloat(d2[5])
        sp["vars"]["caller_phys_f32"] = (ty, dims, d2)
        !isempty(vs(x1f_write_spec(joinpath(vd, "prj.nc"), sp); arm = "probe"))
    end
    t["sidecar_string_index_base_refuses"] = begin
        sp = x1f_sidecar_spec()
        sp["attrs"]["index_base"] = "0"
        !isempty(vs(x1f_write_spec(joinpath(vd, "ib.nc"), sp); arm = "probe"))
    end
    t["sidecar_global_x_index_shift_refuses"] = begin
        sp = x1f_sidecar_spec()
        ty, dims, data = sp["vars"]["global_x_index"]
        sp["vars"]["global_x_index"] = (ty, dims, data .+ Int32(1))
        !isempty(vs(x1f_write_spec(joinpath(vd, "gxi.nc"), sp); arm = "probe"))
    end
    t["sidecar_contract_mismatch_refuses"] = begin
        sp = x1f_sidecar_spec()
        sp["attrs"]["contract"] = "gate4-x1-sidecar-v0"
        !isempty(vs(x1f_write_spec(joinpath(vd, "ct.nc"), sp); arm = "probe"))
    end
    t["sidecar_status_string_mismatch_refuses"] = begin
        # code 2 with a case-mangled string must refuse: exact
        # code/string consistency against the pinned Adept table
        sp = x1f_sidecar_spec()
        sp["attrs"]["minimizer_status_string"] = "maximum iterations reached"
        !isempty(vs(x1f_write_spec(joinpath(vd, "stlc.nc"), sp); arm = "probe"))
    end
    t["sidecar_error_status_refuses"] = begin
        # table-consistent but DISALLOWED terminal (3 = Failed to
        # converge) must refuse even though the file is well-formed
        sp = x1f_sidecar_spec()
        sp["vars"]["minimizer_status"] = (Int32, (), Int32(3))
        sp["attrs"]["minimizer_status_string"] = "Failed to converge"
        !isempty(vs(x1f_write_spec(joinpath(vd, "sterr.nc"), sp); arm = "probe"))
    end
    t["sidecar_unpinned_status_refuses"] = begin
        # enum sentinel 9 falls to the default branch and is NOT pinned
        sp = x1f_sidecar_spec()
        sp["vars"]["minimizer_status"] = (Int32, (), Int32(9))
        sp["attrs"]["minimizer_status_string"] = "Status unrecognized"
        !isempty(vs(x1f_write_spec(joinpath(vd, "stq.nc"), sp); arm = "probe"))
    end
    t["sidecar_expected_status_match_accepted"] =
        isempty(vs(good; arm = "probe",
                   expected_status = "Maximum iterations reached"))
    t["sidecar_expected_status_mismatch_refuses"] =
        !isempty(vs(good; arm = "probe", expected_status = "Converged"))
    t["sidecar_nonfinite_returned_refuses"] = begin
        sp = x1f_sidecar_spec()
        ty, dims, data = sp["vars"]["returned_x_log"]
        d2 = copy(data); d2[7] = Inf
        sp["vars"]["returned_x_log"] = (ty, dims, d2)
        !isempty(vs(x1f_write_spec(joinpath(vd, "nfret.nc"), sp); arm = "probe"))
    end
    t["sidecar_nonfinite_caller_refuses"] = begin
        sp = x1f_sidecar_spec()
        ty, dims, data = sp["vars"]["caller_phys"]
        d2 = copy(data); d2[7] = NaN
        sp["vars"]["caller_phys"] = (ty, dims, d2)
        tyf, dimsf, dataf = sp["vars"]["caller_phys_f32"]
        d3 = copy(dataf); d3[7] = NaN32
        sp["vars"]["caller_phys_f32"] = (tyf, dimsf, d3)
        !isempty(vs(x1f_write_spec(joinpath(vd, "nfph.nc"), sp); arm = "probe"))
    end
    t["sidecar_nonfinite_mapped_refuses"] = begin
        sp = x1f_sidecar_spec()
        ty, dims, data = sp["vars"]["mapped_x_phys"]
        d2 = copy(data); d2[9] = Inf
        sp["vars"]["mapped_x_phys"] = (ty, dims, d2)
        !isempty(vs(x1f_write_spec(joinpath(vd, "nfmp.nc"), sp); arm = "probe"))
    end
    t["sidecar_mapped_floor_violation_refuses"] = begin
        sp = x1f_sidecar_spec()
        ty, dims, data = sp["vars"]["mapped_x_phys"]
        d2 = copy(data); d2[3] = 1.0e-9 # floor row must be exactly 0.0
        sp["vars"]["mapped_x_phys"] = (ty, dims, d2)
        !isempty(vs(x1f_write_spec(joinpath(vd, "map.nc"), sp); arm = "probe"))
    end
    # Axis-C readback
    spec = x1f_sidecar_spec()
    sc = x1f_write_spec(joinpath(vd, "ax_side.nc"), spec)
    r2 = x1f_write_raw2(joinpath(vd, "ax_raw2.nc"), spec)
    ax(a, b) = x1v_axis_c_issues(a, b; expect = X1F_EXPECT)
    t["axis_c_valid_accepted"] = isempty(ax(sc, r2))
    t["axis_c_value_mismatch_refuses"] =
        !isempty(ax(sc, x1f_write_raw2(joinpath(vd, "ax_bad.nc"), spec;
                                       perturb = 7)))
    t["axis_c_dim_order_refuses"] =
        !isempty(ax(sc, x1f_write_raw2(joinpath(vd, "ax_dims.nc"), spec;
                                       permute_dims = true)))
    t["axis_c_missing_var_refuses"] = begin
        pth = joinpath(vd, "ax_miss.nc")
        x1f_write_raw2(pth, spec)
        NCDataset(pth, "a") do ds
            # NCDatasets cannot delete vars; write a fresh file instead
        end
        p2 = joinpath(vd, "ax_miss2.nc")
        NCDataset(p2, "c") do ds
            defDim(ds, "g_point", 2)
            v = defVar(ds, "composite_molar_absorption_coeff", Float32,
                       ("g_point",))
            v[:] = Float32[1, 2]
        end
        !isempty(ax(sc, p2))
    end
    # identity gate
    a, b = x1f_write_pair(mktempdir())
    idn(x, y; kw...) = x1v_identity_issues(x, y; kw...)
    t["identity_config_history_allowed_accepted"] =
        isempty(idn(a, b; allowed_value_diff = ["config", "history"]))
    t["identity_disallowed_global_diff_refuses"] = begin
        a2, b2 = x1f_write_pair(mktempdir(); tamper = :global_attr)
        !isempty(idn(a2, b2; allowed_value_diff = ["config", "history"]))
    end
    t["identity_value_diff_refuses"] = begin
        a2, b2 = x1f_write_pair(mktempdir(); tamper = :value)
        !isempty(idn(a2, b2; allowed_value_diff = ["config", "history"]))
    end
    t["identity_extra_var_refuses"] = begin
        a2, b2 = x1f_write_pair(mktempdir(); tamper = :extra_var)
        !isempty(idn(a2, b2; allowed_value_diff = ["config", "history"]))
    end
    t["identity_var_attr_diff_refuses"] = begin
        a2, b2 = x1f_write_pair(mktempdir(); tamper = :var_attr)
        !isempty(idn(a2, b2; allowed_value_diff = ["config", "history"]))
    end
    t["identity_unallowed_by_default_refuses"] = !isempty(idn(a, b))
    t["identity_var_count_and_required_diffs_accepted"] = begin
        a2, b2 = x1f_write_pair(mktempdir(); nvars = 47,
                                history_differs = true)
        isempty(idn(a2, b2; allowed_value_diff = ["config", "history"],
                    required_value_diffs = ["config", "history"],
                    expected_var_count = 47))
    end
    t["identity_var_count_mismatch_refuses"] = begin
        a2, b2 = x1f_write_pair(mktempdir(); nvars = 46,
                                history_differs = true)
        !isempty(idn(a2, b2; allowed_value_diff = ["config", "history"],
                     required_value_diffs = ["config", "history"],
                     expected_var_count = 47))
    end
    t["identity_required_diff_missing_refuses"] = begin
        # history identical although the exact-set requirement names it
        a2, b2 = x1f_write_pair(mktempdir(); nvars = 47,
                                history_differs = false)
        !isempty(idn(a2, b2; allowed_value_diff = ["config", "history"],
                     required_value_diffs = ["config", "history"],
                     expected_var_count = 47))
    end
    t["identity_allowed_type_mismatch_refuses"] = begin
        # config value differences are allowed, TYPE differences never
        a2, b2 = x1f_write_pair(mktempdir(); nvars = 47,
                                history_differs = true,
                                config_type_mismatch = true)
        !isempty(idn(a2, b2; allowed_value_diff = ["config", "history"],
                     required_value_diffs = ["config", "history"],
                     expected_var_count = 47))
    end

    # provenance wording must stay location-neutral: no claim that the
    # current invocation was scratch or promoted (that is computed and
    # recorded separately), and the regeneration requirement is stated
    t["provenance_note_location_neutral"] =
        !occursin("scratch", lowercase(X1_REPRO_NOTE)) &&
        !occursin("before promotion", X1_REPRO_NOTE) &&
        occursin("regenerated from the promoted byte-identical package",
                 X1_REPRO_NOTE) &&
        occursin("hash-pinned", X1_REPRO_NOTE) &&
        occursin("stage 0a refuses", X1_REPRO_NOTE)

    # real-expectation arithmetic (binding numbers from the frozen draft)
    t["lw_expect_arithmetic"] =
        sum(X1V_LW_EXPECT.sizes) == X1V_LW_EXPECT.nrows == 152640 &&
        X1V_LW_EXPECT.offsets ==
            vcat(0, cumsum(X1V_LW_EXPECT.sizes)[1:end - 1]) &&
        X1V_LW_EXPECT.offsets == [0, 10176, 132288, 142464] &&
        X1V_LW_EXPECT.sizes[2] == 12 * 6 * 53 * 32 &&
        all(X1V_LW_EXPECT.sizes[k] == 6 * 53 * 32 for k in (1, 3, 4))

    # F. sbatch text gates
    text = x1_make_sbatch(tree, pins)
    tg(x) = x1_text_gate_issues(x, pins)
    t["text_good_accepted"] = isempty(tg(text))
    t["text_patched_pin_drift_refuses"] =
        !isempty(tg(replace(text, pins.patched_sha => "0" ^ 64)))
    t["text_helper_pin_drift_refuses"] =
        !isempty(tg(replace(text, X1_HELPER_SHA => "0" ^ 64)))
    t["text_missing_capture_export_refuses"] = !isempty(tg(replace(text,
        "export GATE4_X1_CAPTURE_PATH=\"\$CAP\" GATE4_X1_ARM=\"\$runset\"" =>
        "true")))
    t["text_capture_path_not_nc_refuses"] = !isempty(tg(replace(text,
        "CAP=\"\$CAPD/x1_sidecar.nc\"" => "CAP=\"\$CAPD/x1_sidecar.tmp\"")))
    t["text_extra_capture_export_refuses"] = !isempty(tg(text *
        "\nexport GATE4_X1_CAPTURE_PATH=\"\$CAP\" GATE4_X1_ARM=\"\$runset\"\n"))
    t["text_missing_identity_refuses"] = !isempty(tg(replace(text,
        "gate4_x1_sidecar_validator.jl\" identity" => "true # ")))
    t["text_missing_probe_iterations_refuses"] = !isempty(tg(replace(text,
        "max_iterations=1" => "max_iterations=3000")))
    t["text_missing_unbounded_gate_refuses"] = !isempty(tg(replace(text,
        "REFUSED: unbounded branch/tail changed by the patch" => "note")))
    t["text_missing_call_census_refuses"] = !isempty(tg(replace(text,
        "REFUSED: gate4_x1:: call census != 2" => "note")))
    t["text_missing_status_allowlist_refuses"] = !isempty(tg(replace(text,
        "outside the experiment-allowed set (Converged | Maximum iterations reached)" =>
        "recorded")))
    t["text_missing_status_equality_refuses"] = !isempty(tg(replace(text,
        "REFUSED: pristine/X1 terminal statuses differ" => "note")))
    t["text_missing_alias_probe_refuses"] = !isempty(tg(replace(text,
        X1_ALIAS_PROBE_OK => "skipped")))
    t["text_missing_data_lock_refuses"] = !isempty(tg(replace(text,
        "chmod -R a-w \"\$RUNROOT/data\"" => "true")))
    t["text_missing_data_reverify_refuses"] = !isempty(tg(replace(text,
        "REFUSED: staged data input drifted during the runs (sha mismatch)" =>
        "note")))
    t["text_single_writable_scan_refuses"] = !isempty(tg(replace(text,
        "WLIST2=\$(find \"\$RUNROOT/data\" -writable)" => "WLIST2=\"\"")))
    t["text_s1_ledger_pin_drift_refuses"] =
        !isempty(tg(replace(text, X1_S1_LEDGER_SHA => "0" ^ 64)))
    t["text_extra_pass_refuses"] = !isempty(tg(replace(text,
        "bash optimize_lut_lw.sh relative-base" =>
        "bash optimize_lut_lw.sh relative-base relative-ch4")))
    t["text_publish_machinery_refuses"] =
        !isempty(tg(text * "\nmv -n -- x \$CANON_FINAL\n"))
    t["text_shared_redirect_refuses"] =
        !isempty(tg(text * "\necho x > \"\$G4WORK/work/evil.txt\"\n"))
    t["text_head_pipeline_refuses"] =
        !isempty(tg(text * "\nfoo --version | head -1\n"))
    t["text_ladept_inside_ldflags_refuses"] = !isempty(tg(replace(text,
        "'LDFLAGS=-L$X1_ADEPT/lib -Wl,-rpath,$X1_ADEPT/lib'" =>
        "'LDFLAGS=-L$X1_ADEPT/lib -ladept'")))
    t["text_duplicate_configure_refuses"] =
        !isempty(tg(text * "\n" * X1_CONFIGURE_ARGV * "\n"))
    t["text_strings_absence_refuses"] = !isempty(tg(text *
        "\n[ \"\$(strings x | grep -cF 'Adept LBFGS' || true)\" = 0 ] || exit 99\n"))
    t["bash_syntax_good_accepted"] = x1_bash_syntax_ok(text)
    t["bash_syntax_broken_refuses"] =
        !x1_bash_syntax_ok(text * "\nif true; then\n")
    t
end

# --- main ----------------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()

    tree = x1_tree_manifest()
    pins = x1_patch_pins()
    tests = x1_fixtures(tree, pins)
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    groups = Dict{String, Vector{String}}()

    led = x1_classify_ledger(X1_S1_LEDGER)
    groups["reviewed_s1_completion_ledger"] = led.ok ? String[] : [led.reason]

    gitc = String[]
    commit = try
        strip(read(`git -C $X1_PROJECT_ROOT log -n1 --format=%H --
                    validation/results/gate4_s1_state_sync_completion_ledger.json`,
                   String))
    catch
        "unreadable"
    end
    commit == X1_S1_LEDGER_COMMIT ||
        push!(gitc, "S1 ledger last-touching commit $commit != pinned $X1_S1_LEDGER_COMMIT")
    groups["s1_ledger_commit_pin"] = gitc

    dd = String[]
    if isfile(X1_DESIGN_FILE)
        dsha = x1_sha(X1_DESIGN_FILE)
        dsha == X1_DESIGN_SHA ||
            push!(dd, "durable frozen-design file sha $dsha != $X1_DESIGN_SHA")
    else
        push!(dd, "durable frozen-design file missing: $X1_DESIGN_FILE")
    end
    groups["frozen_design_file"] = dd

    src = String[]
    length(tree) == X1_TREE_FILES ||
        push!(src, "artifact tree census $(length(tree)) != $X1_TREE_FILES")
    count(e -> e.exec, tree) == X1_TREE_EXEC ||
        push!(src, "artifact exec census != $X1_TREE_EXEC")
    sa = [e for e in tree if e.rel == X1_SOLVE_ADEPT_REL]
    (length(sa) == 1 && sa[1].sha == X1_ORIG_SOLVE_ADEPT_SHA) ||
        push!(src, "artifact solve_adept.cpp pin mismatch")
    for (sha, sz, path) in X1_V12_TEST_PINS
        isfile(path) || (push!(src, "testcopy file missing: $path"); continue)
        filesize(path) == sz || push!(src, "testcopy size drift: $path")
        x1_try_sha(path) == sha || push!(src, "testcopy sha drift: $path")
    end
    groups["modern_source_pins"] = src

    ad = String[]
    x1_try_sha(X1_MINIMIZER_H) == X1_MINIMIZER_H_SHA ||
        push!(ad, "installed Minimizer.h sha drift")
    x1_try_sha(X1_LIBADEPT) == X1_LIBADEPT_SHA ||
        push!(ad, "installed libadept.so.0.0.0 sha drift")
    x1_try_sha(X1_ADEPT_SOURCE_H) == X1_ADEPT_SOURCE_H_SHA ||
        push!(ad, "installed adept_source.h sha drift (status-table authority)")
    x1_try_sha(X1_ARRAY_H) == X1_ARRAY_H_SHA ||
        push!(ad, "installed Array.h sha drift (shallow-link authority)")
    if isfile(X1_ARRAY_H)
        areg = join(split(read(X1_ARRAY_H, String), '\n';
                          keepempty = true)[216:245], '\n')
        (occursin("Array(Array& rhs)", areg) &&
         occursin("links to the source data rather than copying", areg)) ||
            push!(ad, "Array.h copy-constructor region 216-245 does not " *
                "show the pinned shallow-link semantics")
    end
    if isfile(X1_MINIMIZER_H)
        occursin(X1_MINIMIZE_BOUNDED_SIG, read(X1_MINIMIZER_H, String)) ||
            push!(ad, "Minimizer.h by-value bounded minimize signature " *
                "not found")
    end
    isdir(joinpath(X1_NETCDF, "lib")) || push!(ad, "netcdf stack missing")
    groups["adept_toolchain_pins"] = ad

    tc = String[]
    for (t_, p_, l1) in X1_TOOLCHAIN
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
    for (sha, sz, path) in X1_DATA_INPUTS
        isfile(path) || (push!(inp, "missing: $path"); continue)
        filesize(path) == sz || push!(inp, "size drift: $path")
        x1_try_sha(path) == sha || push!(inp, "sha drift: $path")
    end
    for (sha, sz, path, _) in X1_WORK_INPUTS
        isfile(path) || (push!(inp, "missing: $path"); continue)
        filesize(path) == sz || push!(inp, "size drift: $path")
        x1_try_sha(path) == sha || push!(inp, "sha drift: $path")
    end
    groups["input_pins"] = inp

    rt = String[]
    for (path, sha, label) in ((X1_NETLIB_BLAS, X1_NETLIB_BLAS_SHA, "netlib blas"),
                               (X1_NETLIB_LAPACK, X1_NETLIB_LAPACK_SHA, "netlib lapack"),
                               (X1_SHIM_SO, X1_SHIM_SO_SHA, "h5 shim"))
        x1_try_sha(path) == sha || push!(rt, "$label pin mismatch: $path")
    end
    groups["runtime_pins"] = rt

    text = x1_make_sbatch(tree, pins)
    groups["sbatch_text_gates"] = x1_text_gate_issues(text, pins)
    groups["sbatch_bash_syntax"] = x1_bash_syntax_ok(text) ? String[] :
        ["generated sbatch fails bash -n syntax verification"]

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end
    ready = gates["fixtures"] == "passed" && all(isempty, values(groups))
    status = ready ? "x1_checkpoint_ready" : "x1_checkpoint_refused"
    if ready
        mkpath(dirname(X1_SBATCH))
        write(X1_SBATCH, text)
    end
    sb_sha = ready ? x1_sha(X1_SBATCH) : nothing

    design_text = isfile(X1_DESIGN_FILE) ?
        read(X1_DESIGN_FILE, String) : nothing

    result = Dict(
        "case" => "gate4_x1_direct_capture_checkpoint",
        "data_mode" => "generator_checkpoint",
        "status" => status,
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "fixture_count" => length(tests),
        "sbatch_path" => X1_SBATCH,
        "sbatch_sha256" => sb_sha,
        "frozen_design" => Dict(
            "sha256" => X1_DESIGN_SHA,
            "durable_file" => X1_DESIGN_REPO_PATH,
            "provenance" => "the durable package file is byte-identical " *
                "to the monitor-frozen reviewed draft (sha above) and is " *
                "pinned in the sbatch stage-0a gate set; no ephemeral " *
                "scratch path is load-bearing",
            "verbatim_text" => design_text),
        "design" => "paired direct-capture instrument test from ONE " *
            "pinned source/configure tree and TWO immutable saved " *
            "binaries: 1-iteration PROBE (X1 binary; sidecar " *
            "schema/rows/order/types/status/Axis-C Float32 readback " *
            "validated fail-closed BEFORE any full arm), PRISTINE " *
            "full-run control, X1 full run instrumented. The X1 patch " *
            "is bounds-ON only (unbounded branch gated byte-identical); " *
            "the capture executes strictly post-minimize; " *
            "NON-PERTURBATION IS AN EMPIRICAL ALL-VARIABLE IDENTITY " *
            "GATE against the in-job pristine arm, never a " *
            "construction claim. Zero canonical writes; RUNROOT " *
            "preserved as forensics; no submission without explicit " *
            "monitor GO.",
        "patch" => Dict(
            "original_solve_adept_sha256" => X1_ORIG_SOLVE_ADEPT_SHA,
            "patched_solve_adept_sha256" => pins.patched_sha,
            "helper_file" => X1_HELPER_REL,
            "helper_sha256" => X1_HELPER_SHA,
            "edits" => [
                Dict("anchor" => X1_INCLUDE_ANCHOR,
                     "inserted" => X1_INCLUDE_LINE,
                     "note" => "global include: declarations only, no " *
                         "execution on any path"),
                Dict("anchor" => X1_CALLSITE_ANCHOR,
                     "replaced_by" => X1_CALLSITE_LINES,
                     "note" => "bounded branch ONLY; record_pre is the " *
                         "FIRST line of the block, immediately before " *
                         "minimize: pre-minimize by construction AND " *
                         "bounded-branch-only by construction " *
                         "(lower_class/upper_active from the PHYSICAL " *
                         "member state before any callback mutation)")],
            "line_count_delta" => 4,
            "bounded_only_census" => "gate4_x1 token appears exactly 3 " *
                "times in the patched file (include + two call lines); " *
                "gate4_x1:: exactly 2, both inside the capture region; " *
                "ZERO X1 calls execute outside the bounded branch",
            "capture_region" => Dict(
                "lines" => "$(pins.capture_region.a)-$(pins.capture_region.b)",
                "sha256" => pins.capture_region.sha),
            "unbounded_tail" => Dict(
                "original_start_line" => pins.unbounded_tail_orig_start,
                "patched_start_line" => pins.unbounded_tail_patched_start,
                "sha256_identical" => pins.unbounded_tail_sha,
                "note" => "BOUNDS-ON ONLY: the ENTIRE tail from the " *
                    "unbounded else block to EOF is gated byte-identical " *
                    "in both trees and free of X1 tokens")),
        "sidecar_schema" => Dict(
            "contract" => X1V_CONTRACT,
            "rows" => X1V_LW_EXPECT.nrows,
            "gas_order" => X1V_LW_EXPECT.gas_names,
            "offsets" => X1V_LW_EXPECT.offsets,
            "sizes" => X1V_LW_EXPECT.sizes,
            "variables" => Dict(k => Dict("stored_type" => string(v[1]),
                                          "dims" => collect(v[2]))
                                for (k, v) in X1V_VARS),
            "global_attributes" => X1V_GLOBAL_ATTRS,
            "index_semantics" => "zero-based numeric positional " *
                "indices; indexing base recorded as the numeric " *
                "global attribute index_base=0; explicit " *
                "global_x_index variable = 0:n-1",
            "bound_semantics" => "bound_lo_log/bound_hi_log hold the " *
                "EXACT vectors passed to minimize, including inactive " *
                "-/+ numeric_limits<Real>::max() initialization " *
                "values from minimizer_initialize_bounds; no NaN or " *
                "sentinel substitution ever; lower_class " *
                "(0=none,1=file-lower,2=synthetic-lower) and " *
                "upper_active are computed PRE-minimize from the " *
                "physical member state",
            "atomicity" => "private atomic write: same-directory " *
                "dot-temp (name itself ends .nc because " *
                "OutputDataFile infers format from the LAST " *
                "extension) -> close -> rename to the exact required " *
                "GATE4_X1_CAPTURE_PATH; missing/unwritable path or " *
                "any write/rename failure exits 93 (refusal, never a " *
                "skip); X1/probe arms use DISTINCT paths; the " *
                "pristine arm is uninstrumented and exports nothing"),
        "probe" => Dict(
            "purpose" => "a schema bug must never consume a full arm",
            "iterations" => 1,
            "gates" => ["writer/path (capture-written line exactly " *
                "once, no refusal line, no temp remnant)",
                "schema (exact-set 23 variables, stored types, dims)",
                "152640 rows", "gas order/offsets",
                "status (enum range + consistency fields)",
                "Axis-C Float32 positional readback vs the probe raw2"]),
        "staged_input_immutability" => Dict(
            "semantics" => "ENFORCED, not intent-only (monitor ruling): " *
                "immediately after the six shared data files are staged " *
                "and hash-verified, the data tree is chmod -R a-w locked " *
                "and the job fails closed unless it exists with ZERO " *
                "writable files or directories (find exit status checked " *
                "explicitly; no early-closing pipeline); after " *
                "probe+pristine+X1 complete and BEFORE any success " *
                "claim, all six staged files are re-verified size+sha " *
                "against the SAME pinned manifest and the zero-writable " *
                "state is reasserted (exit 78 on any drift)",
            "per_runset_inputs" => "the three work inputs are per-runset " *
                "clones, each independently size+sha verified at staging",
            "deferred" => "no preserved-4558 live-data fixture in the " *
                "package (monitor ruling); Agent 42's independent " *
                "real-pair exercise remains non-load-bearing " *
                "corroboration"),
        "axis_a_alias_semantics" => Dict(
            "bounded_claim" => "caller-local x aliases the minimizer's " *
                "by-value Vector storage under these pinned header " *
                "semantics, so post-return x is the observed returned " *
                "solution FOR THIS BUILD; no broader source-to-binary " *
                "claim is made",
            "array_h" => X1_ARRAY_H,
            "array_h_sha256" => X1_ARRAY_H_SHA,
            "copy_constructor_region" => "Array.h:216-245 " *
                "('links to the source data rather than copying')",
            "copy_constructor_region_sha256" => (isfile(X1_ARRAY_H) ?
                x1_region_sha(split(read(X1_ARRAY_H, String), '\n';
                                    keepempty = true), 216, 245) : nothing),
            "minimize_by_value_signature" => "MinimizerStatus " *
                "minimize(Optimizable& optimizable, Vector x, const " *
                "Vector& x_lower, const Vector& x_upper); (installed " *
                "Minimizer.h:111-112, sha256 $X1_MINIMIZER_H_SHA; x by " *
                "value with shallow-link copy, bounds by const " *
                "reference so the caller's locals ARE the passed " *
                "vectors)",
            "behavioral_probe" => Dict(
                "source_sha256" => X1_ALIAS_PROBE_SHA,
                "generator_fixture" => "alias_probe_confirms_shallow_link " *
                    "(compiled AND run; fails unless mutating the " *
                    "by-value/copy alias mutates the original)",
                "in_job" => "recompiled and rerun under the pinned " *
                    "compiler/headers at stage 3 BEFORE any build; " *
                    "exact CONFIRMED line required")),
        "status_semantics" => Dict(
            "table_authority" => "installed " *
                "$X1_ADEPT/include/adept_source.h lines 464-499 " *
                "(sha256 $X1_ADEPT_SOURCE_H_SHA); MinimizerStatus " *
                "enum: installed Minimizer.h lines 27-38 (sha256 " *
                "$X1_MINIMIZER_H_SHA); the default branch incl. enum " *
                "sentinel 9 returns 'Status unrecognized' and is not " *
                "pinned",
            "pinned_table" => Dict(string(k) => v
                                   for (k, v) in X1V_STATUS_TABLE),
            "experiment_allowed" => Dict(string(k) => v
                                         for (k, v) in X1V_ALLOWED_STATUS),
            "gates" => [
                "sidecar minimizer_status must be a pinned code AND " *
                    "minimizer_status_string must equal the pinned " *
                    "table entry exactly",
                "sidecar status must lie in the experiment-allowed " *
                    "set {0 Converged, 2 Maximum iterations reached}",
                "each run's exact terminal status is extracted from " *
                    "its log's single 'Convergence status: ' line and " *
                    "must lie in the allowed set (error/non-converged " *
                    "terminals refuse even when raw2 exists)",
                "probe/X1 sidecar status string must equal the " *
                    "arm's log-extracted status",
                "pristine and X1 full-arm statuses must be EQUAL " *
                    "before the identity gate can license " *
                    "non-perturbation (exit 95 otherwise)",
                "a descriptive STATUS RECORD line is emitted for the " *
                    "completion ledger"]),
        "identity_gate" => Dict(
            "semantics" => "all-variable logical identity between " *
                "pristine-arm and X1-arm raw2: dimension census, " *
                "per-variable dims/stored types/typed attributes/" *
                "elementwise values, EXACTLY 47 variables in each " *
                "file, global attribute NAME-set equality, and the " *
                "ACTUAL differing-global-attribute set required to " *
                "EQUAL exactly [config, history] (typed comparison; " *
                "attribute TYPE equality required even for the " *
                "allowed value differences)",
            "on_violation" => "INSTRUMENT REFUSAL (exit 95), never " *
                "elimination and never a finding; RUNROOT preserved",
            "raw2_global_attrs_observed" => X1_RAW2_GLOBAL_ATTRS),
        "lattice" => Dict(
            "axis_a" => "returned internal x vs the EXACT x_min/x_max " *
                "vectors passed to minimize (log space, synthetic " *
                "lowers included)",
            "axis_b" => "callback mapping of x (exp with MIN_X " *
                "zero-floor, replicating solve_adept.cpp:225-234) vs " *
                "caller ckd_model.x",
            "axis_c" => "caller ckd_model.x vs serialized raw2 " *
                "coefficients under a PROVEN index/write mapping " *
                "(positional readback verified in-ledger)",
            "interpretations" => [
                "A in-bounds + B differs: supports a LOCAL " *
                    "caller-state/mapping discrepancy -- not automatic " *
                    "desync causation.",
                "A out-of-bounds: establishes ONLY that the captured " *
                    "returned x lies outside the provided vectors for " *
                    "this run; algorithm vs bound-construction " *
                    "semantics remain to be distinguished.",
                "B equal + C differs: supports serialization/index " *
                    "mapping.",
                "A/B/C mutually inconsistent with the existing " *
                    "census: instrument REFUSAL, never elimination."],
            "note" => "NO mechanism conclusion is licensed unless the " *
                "relevant mapping is demonstrated; all three mechanism " *
                "classes remain open/unranked globally"),
        "axis_c_projection" => "raw2 values must EQUAL the correctly " *
            "rounded Float32 projection (Float32(caller_phys[i])) of " *
            "caller state under the proven gas/shape/index order -- " *
            "covering BOTH the standard 3-D gas arrays " *
            "(composite/o3/co2: nt,np,ng) AND the LUT concentration " *
            "slices (h2o: nconc,nt,np,ng) -- with the active-gas " *
            "concatenation order itself gated. ANY mismatch in order, " *
            "dimensions, or the expected Float32 projection is " *
            "INSTRUMENT REFUSAL, never a finding.",
        "census_comparison_corollary" => "the committed census was " *
            "computed on raw2 (Float32-projected) values against " *
            "Float64 bounds; sidecar-based censuses on Float64 caller " *
            "state may differ marginally at bound-adjacent indices. " *
            "The A/B/C-inconsistent-with-census REFUSAL branch must " *
            "compare like-with-like: raw2-domain census vs " *
            "Float32-projected caller census; Float64-domain " *
            "comparisons reported separately.",
        "citation_note" => "byte-verified source anchors (pinned " *
            "artifact solve_adept.cpp $X1_ORIG_SOLVE_ADEPT_SHA): " *
            "MIN_X = -1.0e20 at :21; callback exp/MIN_X at :225-234; " *
            "Vector x declared :316; x = MIN_X floor :319; log init " *
            ":320; ckd_model.x_prior = x :322; bounds block :324-334 " *
            "(synthetic lower :332-333); bounded call :366; unbounded " *
            "call :370. The frozen draft's ':315-321' span includes " *
            "the :315 comment line and is consistent with these " *
            "anchors.",
        "toolchain" => Dict(
            "configure_argv" => X1_CONFIGURE_ARGV,
            "fingerprints" => [Dict("tool" => t_, "path" => p_,
                                    "version_line" => l1)
                               for (t_, p_, l1) in X1_TOOLCHAIN],
            "automake" => X1_AUTOMAKE_VER,
            "libtoolize" => X1_LIBTOOLIZE_VER,
            "adept_minimizer_h_sha256" => X1_MINIMIZER_H_SHA,
            "libadept_sha256" => X1_LIBADEPT_SHA),
        "prerequisites" => [
            Dict("ledger" => "S1 state-sync completion ledger",
                 "path" => X1_S1_LEDGER,
                 "required_case" => X1_S1_LEDGER_CASE,
                 "required_status" => X1_S1_LEDGER_STATUS,
                 "reviewed_sha256" => X1_S1_LEDGER_SHA,
                 "pinned_commit" => X1_S1_LEDGER_COMMIT)],
        "source_tree" => Dict(
            "artifact" => X1_SRC_ARTIFACT,
            "authority_note" => "the 7b210aef artifact is the ONLY " *
                "patch/source authority; extant work-tree reads were " *
                "exploratory and enter no pins",
            "files" => X1_TREE_FILES,
            "executables" => X1_TREE_EXEC,
            "symlinks" => 0,
            "manifest_sha256" => x1_manifest_hash(tree)),
        "provenance" => Dict(
            "generation_dir" => abspath(string(@__DIR__)),
            "generated_in_canonical_location" =>
                abspath(string(@__DIR__)) == abspath(X1_CANONICAL_DIR),
            "note" => X1_REPRO_NOTE),
        "post_terminal_requirements" => [
            "sidecar-based Axis-A/B/C evaluation with the committed " *
                "log-space census kernel definitions in a dedicated " *
                "completion ledger; NOT in-job",
            "raw2 hashes + corrected active-state effective-bound " *
                "census (pristine and X1 arms)",
            "external pinned-comparator objective (both full arms)",
            "all findings LOCAL to this rebuilt trajectory; no " *
                "historical attribution; ceiling discipline unchanged"],
        "non_authorizing_note" => "this checkpoint generates and " *
            "verifies the X1 sbatch; it never submits; submission " *
            "requires explicit monitor GO.",
        "disclaimer" => "generator checkpoint; writes nothing except " *
            "its own JSON/MD results and the generated sbatch plus " *
            "transient private temp fixtures (mktempdir).")

    mkpath(dirname(X1_RESULTS_JSON))
    open(X1_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(X1_RESULTS_MD, "w") do io
        println(io, "# Gate-4 X1 direct post-minimize state-capture checkpoint\n")
        println(io, "Status: **$status**\n")
        println(io, result["design"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nFrozen design: `$X1_DESIGN_SHA` (durable file " *
                    "`$X1_DESIGN_REPO_PATH`)")
        println(io, "\nPatch pins: original `$X1_ORIG_SOLVE_ADEPT_SHA` " *
                    "-> patched `$(pins.patched_sha)` (TWO anchored " *
                    "edits, +4 lines; capture region " *
                    "$(pins.capture_region.a)-$(pins.capture_region.b) " *
                    "`$(pins.capture_region.sha)`; unbounded else-to-EOF " *
                    "tail byte-identical `$(pins.unbounded_tail_sha)`; " *
                    "gate4_x1:: calls exactly 2, both in-region); helper " *
                    "`$X1_HELPER_REL` `$X1_HELPER_SHA`; tree manifest " *
                    "`$(x1_manifest_hash(tree))` ($X1_TREE_FILES files)")
        println(io, "\nGenerated sbatch: `$X1_SBATCH`" *
                    (sb_sha === nothing ? " (NOT written; refused)" :
                     " sha256 `$sb_sha`"))
        println(io, "\nPrerequisite (fail-closed, sha-chained): S1 " *
                    "completion ledger `$X1_S1_LEDGER_SHA` " *
                    "($X1_S1_LEDGER_STATUS; commit $X1_S1_LEDGER_COMMIT)")
        println(io, "\nFixtures: $(length(tests)) " *
                    "($(count(values(tests))) passed)")
        println(io, "\nRun order: PROBE (1 iteration, fail-closed " *
                    "sidecar validation) -> PRISTINE control -> X1 " *
                    "instrumented; identity gate decides " *
                    "non-perturbation; violation = instrument refusal " *
                    "(exit 95).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_x1_direct_capture_checkpoint: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    println("  fixtures: $(count(values(tests)))/$(length(tests)) passed")
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return ready ? 0 : 1
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end
