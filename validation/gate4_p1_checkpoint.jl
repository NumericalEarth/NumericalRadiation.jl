# Gate-4 P1 PUBLISHED COEFFICIENT-BLOCK INTERNAL-COST PROBE CHECKPOINT
# (generator; writes ONLY its own JSON/MD results + the generated
# sbatch, plus transient private temp fixtures).
#
# FROZEN DESIGN AUTHORITY (monitor + Agent 42 joint APPROVE):
# gate4_p1_frozen_design.md sha256
# 288dda9e8549da32bed972d55a58c0a3e2ca1d2f9c05cce3d2ad6001b4cdb4e1
# (the Gate-4 LW recovery decision document, rev 6; its P1 sections
# and preregistered conclusion ceiling are binding).
#
# DESIGN (binding highlights):
#   - SIX independent cloned-workspace UNBOUNDED 1-iteration probes
#     (bounded_minimization=0 + max_iterations=1; C1-proven injection)
#     from ONE saved immutable REPORTING-ONLY INSTRUMENTED binary, in
#     the symmetric drift-control order
#     init-a / published-a / plateau-a / plateau-b / published-b /
#     init-b (each target's duplicates straddle the job midpoint).
#   - THREE pinned input states: pinned init (ce057079...), pinned
#     plateau raw2 (49ff3df8...; 4561 pristine), and a PRIVATE in-job
#     published COEFFICIENT-BLOCK SPLICE (pinned init with ALL EIGHT
#     gas coefficient arrays replaced by the pinned published LW32
#     arrays 6087f62f...; never called "the published model"; never
#     canonical).
#   - REPORTING-ONLY PATCH (rev6 exact text): EDIT A adds
#     <sstream>/<iomanip>/<limits> after '#include "Timer.h"'; EDIT B
#     keeps the rounded report statement BYTE-UNCHANGED and appends a
#     niter==0-only block that formats cost/gradient at
#     std::numeric_limits<Real>::max_digits10 in a LOCAL
#     std::ostringstream (newline-free payload) with the four inline
#     proof fields sizeof_Real/mantissa_digits/digits10/max_digits10
#     (informational expectations 8/53/15/17; OBSERVED values binding),
#     flushed via the const-char overload: LOG << p1_full.str() <<
#     "\n"; (Logging.h:96-106). Prefix P1_ITER0_FULL: never collides
#     with "Iteration " extraction patterns.
#   - J0_reported TOKEN SEMANTICS (binding): max_digits10 round-trip
#     tokens of the represented Real values; duplicate gates are EXACT
#     TEXTUAL equality; deltas are EXACT DECIMAL arithmetic on the
#     tokens (Rational{BigInt}; canonical terminating decimals); the
#     sign partition (negative / zero-at-token-representation /
#     positive) is the exact rational sign; values are never averaged;
#     "bit-equality"/"exact underlying J0" language is banned.
#   - PROBE STATUSES are RECORDED observations with NONEMPTY capture
#     and per-target a/b EXACT EQUALITY; a membership allowlist is NOT
#     applied to probes (frozen rev6 section 5; monitor ruling
#     2026-08-14 supersedes the C1-era pattern).
#   - Serialized one-step outputs are STRUCTURAL EVIDENCE ONLY
#     (two-tier policy: structure/missing refuse; nonfinite values are
#     recorded observations, never refusals; no census claims).
#   - Zero canonical writes; RUNROOT preserved on success AND failure;
#     no submission without explicit monitor GO.
#
# PREREQUISITES (fail-closed, sha-chained): the reviewed committed
# B0/S1/X1/C1 completion ledgers.
#
# SHARED GATE CODE: validation/gate4_p1_splice_checker.jl (staged
# read-only into the RUNROOT and invoked as a CLI by the sbatch; the
# SAME file is included here so every gate function is behaviorally
# fixture-tested -- no dual implementation).

const P1_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
include(joinpath(P1_PROJECT_ROOT, "validation", "validation_results.jl"))
include(joinpath(P1_PROJECT_ROOT, "validation", "gate4_p1_splice_checker.jl"))

import JSON

const P1_G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const P1_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"
const P1_CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"

# --- frozen design pin (durable sibling file; rev6 is the authority) ---------
const P1_DESIGN_SHA = "288dda9e8549da32bed972d55a58c0a3e2ca1d2f9c05cce3d2ad6001b4cdb4e1"
const P1_DESIGN_FILE = joinpath(@__DIR__, "gate4_p1_frozen_design.md")
const P1_DESIGN_REPO_PATH = "validation/gate4_p1_frozen_design.md"

# --- shared checker (staged + included; pinned in GATEPINS) -------------------
const P1_CHECKER_FILE = joinpath(@__DIR__, "gate4_p1_splice_checker.jl")
const P1_CHECKER_REPO_PATH = "validation/gate4_p1_splice_checker.jl"

# --- pinned modern (v1.2) ecckd source artifact --------------------------------
const P1_SRC_ARTIFACT = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"
const P1_TREE_FILES = 119
const P1_TREE_EXEC = 24
const P1_SOLVE_ADEPT_REL = "src/ecckd/solve_adept.cpp"
const P1_SOLVE_ADEPT_SHA = "8c9822fac6e6efebadc3fd76c104fe563236221ca6297922e5e8a9467ee32091"
const P1_LOGGING_H = "$P1_SRC_ARTIFACT/src/include/Logging.h"
const P1_LOGGING_H_SHA = "99fc7869b4a08cbb0e14c178915109a5d68e8be4cf7e8974be68a0765ecc00fb"

# --- toolchain / build recipe (identical pins to X1/C1) -------------------------
const P1_ADEPT = "/shared/home/greg/local/adept-2-install"
const P1_MINIMIZER_H = "$P1_ADEPT/include/adept/Minimizer.h"
const P1_MINIMIZER_H_SHA = "dad747936a66304266d0dd31990afa3a7534c589ac6b7a9230eaafbe671a1f8d"
const P1_LIBADEPT = "$P1_ADEPT/lib/libadept.so.0.0.0"
const P1_LIBADEPT_SHA = "1f9016af1b6982493dc8d53dd3a11b2b0c54d4e84c4dbb548b4b06093d43dbcb"
const P1_ADEPT_SOURCE_H = "$P1_ADEPT/include/adept_source.h"
const P1_ADEPT_SOURCE_H_SHA = "8f29a64a2d8227e881a7a541e154d80b752f7746c8607f6a9f280b54f0312351"
const P1_NETCDF = "/shared/home/greg/local/ckdmip-stack"
const P1_CONFIGURE_ARGV = "./configure --with-adept=$P1_ADEPT " *
    "--with-netcdf=$P1_NETCDF " *
    "'LDFLAGS=-L$P1_ADEPT/lib -Wl,-rpath,$P1_ADEPT/lib' 'LIBS=-ladept'"
const P1_CONFIG_STATUS_EXPECT = "--with-adept=$P1_ADEPT " *
    "--with-netcdf=$P1_NETCDF " *
    "'LDFLAGS=-L$P1_ADEPT/lib -Wl,-rpath,$P1_ADEPT/lib' LIBS=-ladept"
const P1_TOOLCHAIN = [
    ("gcc", "/usr/bin/gcc", "gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"),
    ("g++", "/usr/bin/g++", "g++ (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"),
    ("make", "/usr/bin/make", "GNU Make 4.3"),
    ("autoreconf", "/usr/bin/autoreconf", "autoreconf (GNU Autoconf) 2.71")]
const P1_AUTOMAKE_VER = "1.16.5"
const P1_LIBTOOLIZE_VER = "2.4.7"

# --- Julia gate-instrument provenance (monitor blocker: the staged
# checker is a scientific gate instrument; its interpreter and
# environment are pinned and fail-closed, not resolved mutably) --------
const P1_JULIA_BIN = "/shared/home/greg/.juliaup/bin/julia"
const P1_JULIA_VERSION_LINE = "julia version 1.12.6"
const P1_TEST_PROJECT = joinpath(P1_PROJECT_ROOT, "test", "Project.toml")
const P1_TEST_MANIFEST = joinpath(P1_PROJECT_ROOT, "test", "Manifest.toml")

# --- proven Netlib remedy pins ---------------------------------------------------
const P1_SHIM_SO = "$P1_G4WORK/tools/h5open_before_traps.so"
const P1_SHIM_SO_SHA = "28003281a7f1c8470c1bfd94a654999a210581261a5c3e9cd662af2a13dd492f"
const P1_NETLIB_BLAS = "/usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0"
const P1_NETLIB_BLAS_SHA = "e748efcae5753fe4a652877fccdb5895ac6f7605668a2db878b19c914e78e3a8"
const P1_NETLIB_LAPACK = "/usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0"
const P1_NETLIB_LAPACK_SHA = "851bb1fc5833ede9ed704b4417a251a899976d5e0915de40452615187a65278f"

# --- prerequisites: ALL FOUR reviewed committed completion ledgers ----------------
const P1_LEDGERS = [
    (name = "B0", case = "gate4_b0_era_stack_completion_ledger",
     status = "b0_run_completed_verified",
     sha = "d109c0b6e5aa157716247cb05bdfdf806c96e7fc3367e3d5628c55baeda66012",
     commit = "f99efeaae466c1fde0d5641bffd28fb5f11d0787",
     path = "$P1_PROJECT_ROOT/validation/results/gate4_b0_era_stack_completion_ledger.json"),
    (name = "S1", case = "gate4_s1_state_sync_completion_ledger",
     status = "s1_run_completed_verified",
     sha = "de5b349e07b1f085e01f8a8fe6902ea50ac9ecce0821844ae99d8b3f9f40a586",
     commit = "5b6cea7e97d552f0f2bbf80dbd5c998db065ddd4",
     path = "$P1_PROJECT_ROOT/validation/results/gate4_s1_state_sync_completion_ledger.json"),
    (name = "X1", case = "gate4_x1_direct_capture_completion_ledger",
     status = "x1_run_completed_verified",
     sha = "bb1f87c597e673c8a5b5181d325d46eff7b4619c106e28e7ecf121db32c34170",
     commit = "4a3be7a596a3be1e4391c767f23de1f163e227f7",
     path = "$P1_PROJECT_ROOT/validation/results/gate4_x1_direct_capture_completion_ledger.json"),
    (name = "C1", case = "gate4_c1_bounds_flag_completion_ledger",
     status = "c1_run_completed_verified",
     sha = "3c584417d4eba3459f58bbd182b395f7f8ed6c2cddb48e4fef54c057799d116f",
     commit = "a60be91280aea7ae0d863c018520b7ee6b38ee2d",
     path = "$P1_PROJECT_ROOT/validation/results/gate4_c1_bounds_flag_completion_ledger.json")]

# --- three pinned input states (content pins; checker constants are authority) ----
const P1_INIT_PATH = P1C_INIT_PATH
const P1_INIT_SHA = P1C_INIT_SHA
const P1_INIT_BYTES = P1C_INIT_BYTES
const P1_PLATEAU_PATH = "$P1_G4WORK/g4-diag/4561/lw-x1/work-pristine/" *
    "lw_raw-ckd-definition/" *
    "ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
const P1_PLATEAU_SHA = P1C_PLATEAU_SHA
const P1_PLATEAU_BYTES = P1C_PLATEAU_BYTES
const P1_PUB_PATH = P1C_PUB_PATH
const P1_PUB_SHA = P1C_PUB_SHA
const P1_PUB_BYTES = P1C_PUB_BYTES

# --- scientific inputs: identical pins to the 4515/B0/S1/X1/C1 manifest -----------
const P1_DATA_INPUTS = [
    ("dde735608e57af934a2c1e99932c0ccce530883ab48910c7e17b621de7fa0bee", 450863,
     "$P1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-180.h5"),
    ("b0932f2648f720af74191d2a9d62f6178f73dfb9a620b773e55670f06ce2db85", 450863,
     "$P1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-280.h5"),
    ("01836becbc96e7da2b3b33d586d148948df136457216625b7e60225e093e1792", 450863,
     "$P1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-415.h5"),
    ("c8aa819b9e7ea7ed73a0af74862ab49d4209866b74988529b2dfce0ef99710e2", 450863,
     "$P1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-560.h5"),
    ("cfbda1d66decc14e6e91e8465f32f5a5e4bcf0310a73f620fe45bafbcec9ba7c", 450873,
     "$P1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-1120.h5"),
    ("75239df6dbf578b3be6267c09995ff050f5c846be3c75492fad96dcab25610e8", 450873,
     "$P1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-2240.h5")]
const P1_LBL_INPUT =
    ("e799eae4421afe12481533678963237198338b3979ec938c6e61c2759522d4bc", 451045,
     "$P1_G4WORK/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5",
     "lw_lbl_fluxes")
const P1_GPOINTS_INPUT =
    ("c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e", 58404939,
     "$P1_G4WORK/work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5",
     "lw_gpoints")
const P1_V12_TEST_PINS = [
    ("f0d77b16b97612687818e85615a103adaa948627846c9819e40e7754ab0743ba",
     11792, "$P1_SRC_ARTIFACT/test/optimize_lut_lw.sh"),
    ("44dcddf099d69becab1c5e6674d013d6c676685e0b8a4ae51e85a1dda33cfc69",
     6357, "$P1_SRC_ARTIFACT/test/config.h"),
    ("34323fd3ecbcd64980b328eec463eedc692497ed3cdd685f2505ca4d1fdc5e2c",
     1369, "$P1_SRC_ARTIFACT/test/check_configuration.h"),
    ("a5fe514dbcb656c99c11ca39d1c88eba953bda592ca35983de9c42da33dab810",
     92, "$P1_SRC_ARTIFACT/test/version.h.in")]

# --- probe wiring -------------------------------------------------------------------
const P1_WS_LIST = "init-a published-a plateau-a plateau-b published-b init-b"
const P1_RAWDEF_BASENAME = "ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc"
const P1_RAW2_BASENAME = "ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
const P1_MODEL_ID_ANCHOR = "model_id=lw_\${APPLICATION}_\${BANDSTRUCT}-tol\${TOL} \\"

# --- the reporting-only patch (rev6 EXACT preregistered text) ------------------------
const P1_ANCHOR0 = "#include \"Timer.h\""
const P1_INCLUDES = ["#include <sstream>", "#include <iomanip>",
                     "#include <limits>"]
# EDIT B anchor pair = the unique two-line rounded report statement at
# solve_adept.cpp:280-281, kept BYTE-UNCHANGED (trailing space on line
# one and the tab continuation are load-bearing bytes)
const P1_ANCHOR1 = "    LOG << \"Iteration \" << niter << \": cost function = \" << cost "
const P1_ANCHOR2 = "\t<< \", gradient norm = \" << gnorm << \"\\n\";"
const P1_BLOCK_LINES = [
    "    if (niter == 0) {",
    "      std::ostringstream p1_full;",
    "      p1_full << std::setprecision(std::numeric_limits<Real>::max_digits10)",
    "              << \"P1_ITER0_FULL: cost_function = \" << cost",
    "              << \", gradient_norm = \" << gnorm",
    "              << \", sizeof_Real = \" << sizeof(Real)",
    "              << \", mantissa_digits = \" << std::numeric_limits<Real>::digits",
    "              << \", digits10 = \" << std::numeric_limits<Real>::digits10",
    "              << \", max_digits10 = \" << std::numeric_limits<Real>::max_digits10;",
    "      LOG << p1_full.str() << \"\\n\";",
    "    }"]

const P1_RESULTS_JSON = validation_results_path("gate4_p1_checkpoint.json")
const P1_RESULTS_MD = validation_results_path("gate4_p1_checkpoint.md")
const P1_SBATCH = validation_results_path("gate4_p1_lw_splice_probe.sbatch")

const P1_CANONICAL_DIR = joinpath(P1_PROJECT_ROOT, "validation")
const P1_REPRO_NOTE = "reproducibility: the generator's sibling " *
    "package files (frozen design + shared checker) are hash-pinned; " *
    "the generated sbatch addresses the canonical paths under " *
    "$P1_PROJECT_ROOT/validation regardless of where generation ran, " *
    "and sbatch stage 0a refuses unless the bytes at those paths " *
    "match the pins; final artifacts must be regenerated from the " *
    "promoted byte-identical package before commit."

# --- primitives ------------------------------------------------------------------------

p1_sha(path) = p1c_sha(path)
p1_try_sha(path) = try
    isfile(path) || return nothing
    p1_sha(path)
catch
    nothing
end

function p1_tree_manifest()
    entries = NamedTuple[]
    for (root, _, files) in walkdir(P1_SRC_ARTIFACT)
        for f in files
            p = joinpath(root, f)
            islink(p) && error("unexpected symlink in artifact: $p")
            rel = relpath(p, P1_SRC_ARTIFACT)
            push!(entries, (rel = rel, sha = p1_sha(p),
                            exec = (uperm(p) & 0x01) != 0))
        end
    end
    sort!(entries, by = e -> e.rel)
    entries
end

p1_manifest_hash(entries) = bytes2hex(sha256(join(
    ["F $(e.sha) $(e.exec ? 1 : 0) $(e.rel)" for e in entries], "\n")))

function p1_snapshot(path; readfn = read)
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

function p1_classify_ledger(path; expected_case, expected_status,
                            expected_sha, readfn = read)
    snap = p1_snapshot(path; readfn = readfn)
    snap.ok || return (ok = false, class = snap.reason,
                       reason = "ledger $(snap.reason): $path")
    c = get(snap.data, "case", nothing)
    c == expected_case || return (ok = false, class = "case mismatch",
        reason = "ledger case mismatch (got $(repr(c))): $path")
    s = get(snap.data, "status", nothing)
    s == expected_status || return (ok = false, class = "status mismatch",
        reason = "ledger status $(repr(s)) != $expected_status: $path")
    snap.sha == expected_sha || return (ok = false, class = "sha drift",
        reason = "ledger sha $(snap.sha) != reviewed $(expected_sha): $path")
    (ok = true, class = "green", reason = "")
end

# --- patch machinery ----------------------------------------------------------------

# static invariants of the preregistered block text (fixture authority;
# includes the const-char literal-newline flush-form gate and the
# newline-free-payload gate)
function p1_block_static_issues(block)
    iss = String[]
    length(block) == 11 || push!(iss, "block line count $(length(block)) != 11")
    isempty(block) && return iss
    strip(block[1]) == "if (niter == 0) {" ||
        push!(iss, "block niter==0 gate line drift")
    joined = join(block, '\n')
    occursin("std::setprecision(std::numeric_limits<Real>::max_digits10)",
             joined) ||
        push!(iss, "setprecision(max_digits10) missing")
    occursin("std::ostringstream p1_full;", joined) ||
        push!(iss, "local ostringstream declaration missing")
    for lbl in ("P1_ITER0_FULL: cost_function = ", ", gradient_norm = ",
                ", sizeof_Real = ", ", mantissa_digits = ",
                ", digits10 = ", ", max_digits10 = ")
        any(occursin(lbl, l) for l in block) ||
            push!(iss, "payload label missing: $lbl")
    end
    flush_line = "      LOG << p1_full.str() << \"\\n\";"
    count(==(flush_line), block) == 1 ||
        push!(iss, "literal-newline const-char flush form " *
              "(LOG << p1_full.str() << newline-literal) not exactly once")
    any(occursin("\\n", l) && l != flush_line for l in block) &&
        push!(iss, "newline inside the ostringstream payload " *
              "(payload must be newline-free)")
    strip(block[end]) == "}" || push!(iss, "block close drift")
    iss
end

# stripped-line containment in the frozen design, restricted to the
# INSERTED patch text (P1_INCLUDES + P1_BLOCK_LINES): design-to-code
# fidelity requires every inserted line to be verbatim (stripped) what
# frozen rev6 specifies. ANCHORS are deliberately EXCLUDED (monitor
# ruling): they are PRE-EXISTING source lines whose provenance chain
# is code-to-pinned-source (exact source pin + uniqueness in
# p1_apply_patch + byte-preservation gates in the patched file); a
# prose design need not contain them as standalone lines, and prose
# mention can never substitute for inserted-line containment.
function p1_design_containment_issues(design, block, includes)
    dl = Set(strip.(split(design, '\n')))
    iss = String[]
    for l in vcat(includes, block)
        s = strip(l)
        (isempty(s) || s == "}") && continue
        s in dl ||
            push!(iss, "inserted patch line not present (stripped) in " *
                  "the frozen design: $s")
    end
    iss
end

# the EXACT textual transformation the job's awk performs (derivation
# authority for the patched/region sha pins and the census gates)
function p1_apply_patch(orig)
    iss = String[]
    occursin("P1_ITER0_FULL", orig) &&
        push!(iss, "source already instrumented (P1_ITER0_FULL present)")
    for inc in P1_INCLUDES
        occursin(inc, orig) && push!(iss, "include already present: $inc")
    end
    lines = split(orig, '\n'; keepempty = true)
    a0 = findall(==(P1_ANCHOR0), lines)
    length(a0) == 1 ||
        push!(iss, "EDIT A include anchor count $(length(a0)) != 1")
    ab = [i for i in 1:(length(lines) - 1)
          if lines[i] == P1_ANCHOR1 && lines[i + 1] == P1_ANCHOR2]
    length(ab) == 1 ||
        push!(iss, "EDIT B report anchor pair count $(length(ab)) != 1")
    isempty(iss) || return (iss, nothing)
    out = String[]
    for (i, l) in enumerate(lines)
        push!(out, String(l))
        i == a0[1] && append!(out, P1_INCLUDES)
        i == ab[1] + 1 && append!(out, P1_BLOCK_LINES)
    end
    (iss, join(out, '\n'))
end

p1_region_text() = join(vcat([P1_ANCHOR1, P1_ANCHOR2], P1_BLOCK_LINES),
                        '\n') * "\n"

# --- source-semantic gates (monitor chunk-2 blocker 1; Agent 42 four-region form) ---
# Mechanical exact-pinned extraction (S1/C1 pattern; line-anchored
# regions + content hashes, never prose): (a) the J_prior callback
# region in solve_adept.cpp (both prior forms at xdata-x_prior through
# J += J_prior), (b) the x_prior initialization site, (c) the
# ALGORITHM REQUEST line (MINIMIZER_ALGORITHM_LIMITED_MEMORY_BFGS --
# what makes the unbounded L-BFGS loop the executed path), (d) the
# adept_source.h unbounded loop region :3902-:3977 (definition line
# through report_progress(n_iterations_, ...) fired BEFORE any step).
# J_prior == 0 at iteration 0 then follows from the gated text
# (x_prior equals the start x at the first evaluation); the completion
# ledger source-cites these gates before any interpretation.
const P1_SEM_ALG_LINE = "  adept::Minimizer minimizer(MINIMIZER_ALGORITHM_LIMITED_MEMORY_BFGS);"
const P1_SEM_XPRIOR_LINE = "  ckd_model.x_prior = x;"
const P1_SEM_JPRIOR_START_FRAG = "Vector gradient_prior = (1.0/(data.prior_error*data.prior_error))"
const P1_SEM_JPRIOR_END_STRIP = "J += J_prior;"
const P1_SEM_AS_START = 3902
const P1_SEM_AS_END = 3977
const P1_SEM_AS_DEF_FRAG = "Minimizer::minimize_limited_memory_bfgs(Optimizable& optimizable, Vector x)"
const P1_SEM_AS_REPORT_FRAG = "report_progress(n_iterations_, x, cost_function_, gradient_norm_)"
# fifth region (monitor correction): calc_background_cost_function
# no-constant semantics in the pinned registered-tree ckd_model.cpp --
# cost_fn initialized 0, gradient zeroed, contributions purely
# linear/quadratic in delta_x, return cost_fn. With the J_prior region
# this source-proves J_prior == 0 at iteration 0 for BOTH prior
# branches (zero input -> zero returned cost), not inferred from a
# function name.
const P1_SEM_CM_REL = "src/ecckd/ckd_model.cpp"
const P1_SEM_CM_DEF_FRAG = "::calc_background_cost_function(const Vector& delta_x, Vector gradient)"
const P1_SEM_CM_END_STRIP = "return cost_fn;"

# parameterized ONLY enough for fixture paths/shas (monitor delta B);
# production defaults are unchanged, and the fixtures exercise the
# actual read/derivation paths (anchors/content), not just outer shas
function p1_semantic_derivation(patched_text, tree;
                                adept_path = P1_ADEPT_SOURCE_H,
                                adept_sha = P1_ADEPT_SOURCE_H_SHA,
                                cm_path = joinpath(P1_SRC_ARTIFACT,
                                                   P1_SEM_CM_REL),
                                cm_sha = nothing)
    iss = String[]
    lines = split(patched_text, '\n'; keepempty = true)
    count(==(P1_SEM_ALG_LINE), lines) == 1 ||
        push!(iss, "algorithm-request line not exactly once in the patched source")
    count(==(P1_SEM_XPRIOR_LINE), lines) == 1 ||
        push!(iss, "x_prior initialization line not exactly once in the patched source")
    js = findfirst(l -> occursin(P1_SEM_JPRIOR_START_FRAG, l), lines)
    js === nothing &&
        (push!(iss, "J_prior region start anchor missing"); return (iss, nothing))
    je = findnext(l -> strip(l) == P1_SEM_JPRIOR_END_STRIP, lines, js)
    je === nothing &&
        (push!(iss, "J_prior region end anchor missing"); return (iss, nothing))
    jr = join(lines[js:je], '\n') * "\n"
    occursin("J_prior = 0.5*sum((xdata-data.ckd_model->x_prior)", jr) ||
        push!(iss, "quadratic prior form missing from the J_prior region")
    occursin("calc_background_cost_function(xdata-data.ckd_model->x_prior",
             jr) ||
        push!(iss, "background-cost prior form missing from the J_prior region")
    asiss, aslines = p1c_bracketed(adept_path, adept_sha) do
        split(read(adept_path, String), '\n'; keepempty = true)
    end
    append!(iss, asiss)
    aslines === nothing && return (iss, nothing)
    length(aslines) >= P1_SEM_AS_END ||
        (push!(iss, "adept_source.h shorter than the pinned region");
         return (iss, nothing))
    occursin(P1_SEM_AS_DEF_FRAG, aslines[P1_SEM_AS_START]) ||
        push!(iss, "adept_source.h:$P1_SEM_AS_START is not the unbounded LBFGS definition line")
    occursin(P1_SEM_AS_REPORT_FRAG, aslines[P1_SEM_AS_END]) ||
        push!(iss, "adept_source.h:$P1_SEM_AS_END is not the pre-step report_progress call")
    asr = join(aslines[P1_SEM_AS_START:P1_SEM_AS_END], '\n') * "\n"
    cmsha = cm_sha
    if cmsha === nothing
        cmidx = findfirst(e -> e.rel == P1_SEM_CM_REL, tree)
        cmidx === nothing &&
            (push!(iss, "ckd_model.cpp missing from the registered tree");
             return (iss, nothing))
        cmsha = tree[cmidx].sha
    end
    cmiss, cmlines = p1c_bracketed(cm_path, cmsha) do
        split(read(cm_path, String), '\n'; keepempty = true)
    end
    append!(iss, cmiss)
    cmlines === nothing && return (iss, nothing)
    cs_hits = [i for (i, l) in enumerate(cmlines)
               if occursin(P1_SEM_CM_DEF_FRAG, l)]
    length(cs_hits) == 1 ||
        (push!(iss, "calc_background_cost_function definition not exactly once in ckd_model.cpp");
         return (iss, nothing))
    cs = cs_hits[1]
    ce = findnext(l -> strip(l) == P1_SEM_CM_END_STRIP, cmlines, cs)
    ce === nothing &&
        (push!(iss, "calc_background_cost_function return anchor missing");
         return (iss, nothing))
    cmr = join(cmlines[cs:ce], '\n') * "\n"
    for (frag, n, what) in (
        ("Real cost_fn = 0.0;", 1, "cost_fn zero initialization"),
        ("gradient = 0.0;", 1, "gradient zeroing"),
        ("0.5*dot_product(delta_x_local,gradient_local)", 2,
         "quadratic delta_x contributions (active + rayleigh)"),
        ("return cost_fn;", 1, "return of the accumulated cost"))
        m = length(collect(eachmatch(Regex("\\Q" * frag * "\\E"), cmr)))
        m == n ||
            push!(iss, "background-cost region: $what count $m != $n")
    end
    (iss, (jprior_start = js, jprior_end = je,
           jprior_sha = bytes2hex(sha256(jr)), jprior_text = jr,
           as_region_sha = bytes2hex(sha256(asr)),
           cm_start = cs, cm_end = ce,
           cm_region_sha = bytes2hex(sha256(cmr)), cm_text = cmr))
end

# derivation of ALL patch pins from the sha-bracketed pinned original
function p1_patch_derivation()
    iss = String[]
    biss, orig = p1c_bracketed(joinpath(P1_SRC_ARTIFACT, P1_SOLVE_ADEPT_REL),
                               P1_SOLVE_ADEPT_SHA) do
        read(joinpath(P1_SRC_ARTIFACT, P1_SOLVE_ADEPT_REL), String)
    end
    append!(iss, biss)
    orig === nothing && return (iss, nothing)
    aiss, patched = p1_apply_patch(orig)
    append!(iss, aiss)
    patched === nothing && return (iss, nothing)
    orig_wc = count(==('\n'), orig)
    patched_wc = count(==('\n'), patched)
    patched_wc == orig_wc + 14 ||
        push!(iss, "patched line-count delta $(patched_wc - orig_wc) != +14")
    occursin(P1_ANCHOR1 * "\n" * P1_ANCHOR2, patched) ||
        push!(iss, "rounded report statement not byte-unchanged in the patched text")
    for (pat, n, what) in (
        (P1_INCLUDES[1], 1, "sstream include"),
        (P1_INCLUDES[2], 1, "iomanip include"),
        (P1_INCLUDES[3], 1, "limits include"),
        ("P1_ITER0_FULL", 1, "P1_ITER0_FULL token"),
        ("if (niter == 0) {", 1, "niter==0 gate"),
        ("LOG << p1_full.str() << \"\\n\";", 1, "const-char flush"),
        ("std::setprecision(std::numeric_limits<Real>::max_digits10)", 1,
         "setprecision"))
        m = length(collect(eachmatch(Regex("\\Q" * pat * "\\E"), patched)))
        m == n || push!(iss, "patched-source census: $what count $m != $n")
    end
    p1full_lines = count(l -> occursin("p1_full", l),
                         split(patched, '\n'))
    p1full_lines == 3 ||
        push!(iss, "patched-source census: p1_full line count $p1full_lines != 3")
    region = p1_region_text()
    occursin(region, patched * "\n") ||
        push!(iss, "region text not contained in the patched source")
    (iss, (orig_sha = P1_SOLVE_ADEPT_SHA,
           patched_sha = bytes2hex(sha256(patched)),
           region_sha = bytes2hex(sha256(region)),
           orig_wc = orig_wc, patched_wc = patched_wc,
           patched_text = patched))
end

# derive the injected test-script text exactly as the job's sed does
# (probe injection is IDENTICAL for all six workspaces)
function p1_derive_injected(script_text)
    iss = String[]
    lines = split(script_text, '\n'; keepempty = true)
    anchor_hits = [i for (i, l) in enumerate(lines)
                   if endswith(l, P1_MODEL_ID_ANCHOR)]
    length(anchor_hits) == 1 ||
        (push!(iss, "model_id anchor not exactly once ($(length(anchor_hits)))");
         return (iss, nothing))
    occursin("bounded_minimization", script_text) &&
        (push!(iss, "script already references bounded_minimization");
         return (iss, nothing))
    inject = ["\t    bounded_minimization=0 \\", "\t    max_iterations=1 \\"]
    i = anchor_hits[1]
    (iss, join(vcat(lines[1:i], inject, lines[(i + 1):end]), '\n'))
end

# --- sbatch generation ---------------------------------------------------------------

function p1_make_sbatch(tree, patch, sem)
    checker_sha = p1_sha(P1_CHECKER_FILE)
    stage_rows = String[]
    for (sha, sz, path) in P1_DATA_INPUTS
        push!(stage_rows, "$sha $sz $path \$RUNROOT/data/evaluation1/lw_fluxes/$(basename(path))")
    end
    for ws in split(P1_WS_LIST)
        for (sha, sz, path, rel) in (P1_LBL_INPUT, P1_GPOINTS_INPUT)
            push!(stage_rows, "$sha $sz $path \$RUNROOT/work-$ws/$rel/$(basename(path))")
        end
    end
    for ws in ("init-a", "init-b")
        push!(stage_rows, "$P1_INIT_SHA $P1_INIT_BYTES $P1_INIT_PATH \$RUNROOT/work-$ws/lw_raw-ckd-definition/$P1_RAWDEF_BASENAME")
    end
    for ws in ("plateau-a", "plateau-b")
        push!(stage_rows, "$P1_PLATEAU_SHA $P1_PLATEAU_BYTES $P1_PLATEAU_PATH \$RUNROOT/work-$ws/lw_raw-ckd-definition/$P1_RAWDEF_BASENAME")
    end
    # immutable source-input masters (TOCTOU closure: state-gate checker
    # calls read ONLY these staged, hash-verified, a-w copies -- never
    # the canonical paths after stage 0)
    push!(stage_rows, "$P1_INIT_SHA $P1_INIT_BYTES $P1_INIT_PATH \$RUNROOT/source-inputs/init.nc")
    push!(stage_rows, "$P1_PUB_SHA $P1_PUB_BYTES $P1_PUB_PATH \$RUNROOT/source-inputs/published.nc")
    stage_lines = join(stage_rows, "\n")
    # post-run no-mutation rows: every per-workspace staged input
    # (sha  dst), excluding the data/ rows (re-verified separately)
    post_stage_lines = join([begin
        parts = split(r, ' ')
        "$(parts[1])  $(parts[4])"
    end for r in stage_rows if !occursin("/data/evaluation1/", r)], "\n") *
        "\n$(p1_sha(P1_TEST_PROJECT))  \$RUNROOT/julia-env/Project.toml" *
        "\n$(p1_sha(P1_TEST_MANIFEST))  \$RUNROOT/julia-env/Manifest.toml"
    post_master_sizes = join(
        ["$P1_INIT_BYTES \$RUNROOT/source-inputs/init.nc",
         "$P1_PUB_BYTES \$RUNROOT/source-inputs/published.nc",
         "$(filesize(P1_TEST_PROJECT)) \$RUNROOT/julia-env/Project.toml",
         "$(filesize(P1_TEST_MANIFEST)) \$RUNROOT/julia-env/Manifest.toml",
         "$(filesize(P1_CHECKER_FILE)) \$RUNROOT/tools/gate4_p1_splice_checker.jl"],
        "\n")
    data_post_hash_lines = join(
        ["$sha  \$RUNROOT/data/evaluation1/lw_fluxes/$(basename(path))"
         for (sha, _, path) in P1_DATA_INPUTS], "\n")
    data_post_size_lines = join(
        ["$sz \$RUNROOT/data/evaluation1/lw_fluxes/$(basename(path))"
         for (_, sz, path) in P1_DATA_INPUTS], "\n")
    hash_lines = join(vcat(
        ["$sha  $path" for (sha, _, path) in P1_DATA_INPUTS],
        ["$(P1_LBL_INPUT[1])  $(P1_LBL_INPUT[3])",
         "$P1_INIT_SHA  $P1_INIT_PATH",
         "$(P1_GPOINTS_INPUT[1])  $(P1_GPOINTS_INPUT[3])",
         "$P1_PLATEAU_SHA  $P1_PLATEAU_PATH",
         "$P1_PUB_SHA  $P1_PUB_PATH"],
        ["$sha  $path" for (sha, _, path) in P1_V12_TEST_PINS],
        ["$P1_MINIMIZER_H_SHA  $P1_MINIMIZER_H",
         "$P1_LIBADEPT_SHA  $P1_LIBADEPT",
         "$P1_ADEPT_SOURCE_H_SHA  $P1_ADEPT_SOURCE_H",
         "$P1_LOGGING_H_SHA  $P1_LOGGING_H",
         "$P1_SOLVE_ADEPT_SHA  $P1_SRC_ARTIFACT/$P1_SOLVE_ADEPT_REL"]), "\n")
    size_lines = join(vcat(
        ["$sz $path" for (_, sz, path) in P1_DATA_INPUTS],
        ["$(P1_LBL_INPUT[2]) $(P1_LBL_INPUT[3])",
         "$P1_INIT_BYTES $P1_INIT_PATH",
         "$(P1_GPOINTS_INPUT[2]) $(P1_GPOINTS_INPUT[3])",
         "$P1_PLATEAU_BYTES $P1_PLATEAU_PATH",
         "$P1_PUB_BYTES $P1_PUB_PATH"],
        ["$sz $path" for (_, sz, path) in P1_V12_TEST_PINS]), "\n")
    gate_pins = join(vcat(
        ["$(p1_sha(joinpath(P1_PROJECT_ROOT, f)))  $(joinpath(P1_PROJECT_ROOT, f))"
         for f in ("validation/gate4_quota_guard.sh",
                   "validation/validation_results.jl")],
        ["$(p1_sha(abspath(@__FILE__)))  $P1_PROJECT_ROOT/validation/gate4_p1_checkpoint.jl",
         "$checker_sha  $P1_PROJECT_ROOT/$P1_CHECKER_REPO_PATH",
         "$P1_DESIGN_SHA  $P1_PROJECT_ROOT/$P1_DESIGN_REPO_PATH",
         "$(p1_sha(P1_TEST_PROJECT))  $P1_TEST_PROJECT",
         "$(p1_sha(P1_TEST_MANIFEST))  $P1_TEST_MANIFEST"],
        ["$(l.sha)  $(l.path)" for l in P1_LEDGERS]), "\n")
    artifact_tree_lines = join(["$(e.sha)  $P1_SRC_ARTIFACT/$(e.rel)"
                                for e in tree], "\n")
    copy_tree_lines = join(["$(e.sha)  $(e.rel)" for e in tree], "\n")
    copy_tree_except = join(["$(e.sha)  $(e.rel)" for e in tree
                             if e.rel != P1_SOLVE_ADEPT_REL], "\n")
    execbit_lines = join(["$(e.exec ? 1 : 0) $(e.rel)" for e in tree], "\n")
    toolchain_checks = join([begin
        V = uppercase(replace(t, "+" => "X"))
        """
$(V)_P=\$(command -v $t) || { echo "REFUSED: $t missing" >&2; exit 65; }
[ "\$$(V)_P" = "$p" ] || { echo "REFUSED: $t path \$$(V)_P != pinned $p" >&2; exit 65; }
$(V)_FULL=\$($t --version); $(V)_L1=\${$(V)_FULL%%\$'\\n'*}
[ "\$$(V)_L1" = "$l1" ] || { echo "REFUSED: $t version line '\$$(V)_L1' != pinned '$l1'" >&2; exit 65; }"""
    end for (t, p, l1) in P1_TOOLCHAIN], "\n")
    banner_3000 = "Optimizing coefficients with Adept LBFGS " *
        "algorithm: max iterations = 3000, convergence criterion = 0.02"
    banner_1 = "Optimizing coefficients with Adept LBFGS " *
        "algorithm: max iterations = 1, convergence criterion = 0.02"
    template_pins = join(["$sha  \$RUNROOT/test-template/$(basename(path))"
                          for (sha, _, path) in P1_V12_TEST_PINS], "\n")
    p_includes = join(P1_INCLUDES, "\n")
    p_block = join(P1_BLOCK_LINES, "\n")
    """
#!/bin/bash
#SBATCH --job-name=g4-p1-lw-splice-probe
#SBATCH --output=$P1_LOG_DIR/g4-p1-lw-%j.log
#SBATCH --time=06:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=36
#SBATCH --mem=60G
#SBATCH --partition=cpu-large

# Gate-4 P1: PUBLISHED COEFFICIENT-BLOCK INTERNAL-COST PROBE
# (DIAGNOSIS unit; PRIVATE output only). Generated by
# gate4_p1_checkpoint.jl under the frozen rev6 design $P1_DESIGN_SHA.
# ONE pinned source tree, ONE reporting-only instrumented build, ONE
# immutable binary shared by ALL SIX unbounded 1-iteration probes in
# the symmetric drift-control order
# init-a / published-a / plateau-a / plateau-b / published-b / init-b.
# THREE pinned input states: pinned init, pinned plateau raw2 (staged
# AT the raw-definition input name), and the PRIVATE in-job published
# coefficient-block splice. J0_reported token semantics: max_digits10
# round-trip tokens; duplicate gates are EXACT TEXTUAL equality;
# deltas are EXACT DECIMAL arithmetic on the tokens; probe statuses
# are RECORDED (nonempty; per-target a/b equality; NO membership
# allowlist per the frozen design). Serialized one-step outputs are
# STRUCTURAL EVIDENCE ONLY. ZERO canonical writes; RUNROOT preserved
# on success AND failure.
set -euo pipefail
if [ -z "\${SLURM_JOB_ID:-}" ]; then
    echo "REFUSED: head-node execution is not permitted; submit via sbatch." >&2
    exit 64
fi
case "\$SLURM_JOB_ID" in
    ''|*[!0-9]*) echo "REFUSED: SLURM_JOB_ID is not a positive integer" >&2; exit 64;;
esac

G4WORK=$P1_G4WORK
RUNROOT="\$G4WORK/g4-diag/\${SLURM_JOB_ID}/lw-p1"
SRCDIR="\$RUNROOT/src/ecckd-modern-p1"
CHECKER="\$RUNROOT/tools/gate4_p1_splice_checker.jl"

echo "=== P1-lw stage 0a: gate-code identity (verify BEFORE sourcing) ==="
sha256sum -c <<'GATEPINS' || { echo "REFUSED: gate code/reviewed prerequisite ledger changed since generation; regenerate the checkpoint" >&2; exit 75; }
$gate_pins
GATEPINS

echo "=== P1-lw stage 0b: quota health (read-only; 50 GiB soft-quota headroom) ==="
source $P1_PROJECT_ROOT/validation/gate4_quota_guard.sh
quota_health \$((50*1024*1024*1024)) || { echo "REFUSED: quota not healthy (need soft-quota minus 50 GiB headroom)" >&2; exit 67; }

echo "=== P1-lw stage 0c: pinned inputs + FULL artifact tree manifest + fail-closed toolchain ==="
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
[ "\$(find "$P1_SRC_ARTIFACT" \\( -type f -o -type l \\) | wc -l)" = "$P1_TREE_FILES" ] || { echo "REFUSED: artifact tree file census != $P1_TREE_FILES" >&2; exit 69; }
[ "\$(find "$P1_SRC_ARTIFACT" -type l | wc -l)" = 0 ] || { echo "REFUSED: unexpected symlink in artifact tree" >&2; exit 69; }
while read -r xf rel; do
    if [ "\$xf" = 1 ]; then
        [ -x "$P1_SRC_ARTIFACT/\$rel" ] || { echo "REFUSED: artifact exec bit lost: \$rel" >&2; exit 69; }
    else
        [ ! -x "$P1_SRC_ARTIFACT/\$rel" ] || { echo "REFUSED: artifact exec bit gained: \$rel" >&2; exit 69; }
    fi
done <<'EXECBITS'
$execbit_lines
EXECBITS
$toolchain_checks
AM_FULL=\$(automake --version); AM_LINE1=\${AM_FULL%%\$'\\n'*}; AM_V=\${AM_LINE1##* }
LT_FULL=\$(libtoolize --version); LT_LINE1=\${LT_FULL%%\$'\\n'*}; LT_V=\${LT_LINE1##* }
[ "\$AM_V" = "$P1_AUTOMAKE_VER" ] || { echo "REFUSED: automake \$AM_V != pinned $P1_AUTOMAKE_VER" >&2; exit 65; }
[ "\$LT_V" = "$P1_LIBTOOLIZE_VER" ] || { echo "REFUSED: libtoolize \$LT_V != pinned $P1_LIBTOOLIZE_VER" >&2; exit 65; }
# Julia gate-instrument provenance: the pinned path is a juliaup
# launcher, so the BINDING gate is the exact runtime --version string
# (fail-closed), not the path alone; the checker environment is
# sha-chained in GATEPINS (test/Project.toml + test/Manifest.toml)
JULIA_BIN=$P1_JULIA_BIN
[ -x "\$JULIA_BIN" ] || { echo "REFUSED: pinned julia launcher missing/not executable: \$JULIA_BIN" >&2; exit 65; }
JL_FULL=\$("\$JULIA_BIN" --version); JL_L1=\${JL_FULL%%\$'\\n'*}
[ "\$JL_L1" = "$P1_JULIA_VERSION_LINE" ] || { echo "REFUSED: julia version line '\$JL_L1' != pinned '$P1_JULIA_VERSION_LINE'" >&2; exit 65; }

echo "=== P1-lw stage 0d: P1 experiment lock (duplicate-diagnosis guard) ==="
mkdir -p "\$G4WORK/locks"
exec 9>"\$G4WORK/locks/p1-lw.lock"
flock -n 9 || { echo "REFUSED: another P1-lw diagnosis job holds the lock" >&2; exit 73; }

echo "=== P1-lw stage 1: job-private RUNROOT + per-workspace scientific-input snapshot ==="
[ ! -e "\$RUNROOT" ] || { echo "REFUSED: RUNROOT already exists: \$RUNROOT" >&2; exit 72; }
mkdir -p "\$RUNROOT/data/evaluation1/lw_fluxes" "\$RUNROOT/src" "\$RUNROOT/bin" "\$RUNROOT/tools" "\$RUNROOT/patch" "\$RUNROOT/splice" "\$RUNROOT/source-inputs" "\$RUNROOT/julia-env"
for ws in $P1_WS_LIST; do
    mkdir -p "\$RUNROOT/work-\$ws/lw_lbl_fluxes" \\
             "\$RUNROOT/work-\$ws/lw_raw-ckd-definition" \\
             "\$RUNROOT/work-\$ws/lw_ckd-definition" \\
             "\$RUNROOT/work-\$ws/lw_gpoints"
done
while read -r esha esz src dst; do
    cp -L -- "\$src" "\$dst" || { echo "REFUSED: staging copy failed: \$src" >&2; exit 76; }
    asz=\$(stat -Lc %s "\$dst") || { echo "REFUSED: cannot stat staged copy \$dst" >&2; exit 76; }
    [ "\$asz" = "\$esz" ] || { echo "REFUSED: staged copy size mismatch \$dst (\$asz != \$esz)" >&2; exit 76; }
    echo "\$esha  \$dst" | sha256sum -c - >/dev/null || { echo "REFUSED: staged copy hash mismatch: \$dst" >&2; exit 76; }
done <<STAGE
$stage_lines
STAGE
echo "per-workspace staged scientific-input snapshots verified under \$RUNROOT (plateau bytes staged AT the raw-definition input name; published workspaces receive the private splice at stage 4)"
[ -d "\$RUNROOT/data" ] || { echo "REFUSED: staged data tree missing" >&2; exit 76; }
chmod -R a-w "\$RUNROOT/data"
WLIST=\$(find "\$RUNROOT/data" -writable) || { echo "REFUSED: writable-entry scan failed on the staged data tree" >&2; exit 76; }
[ -z "\$WLIST" ] || { echo "REFUSED: writable entries remain in the staged data tree after chmod" >&2; printf '%s\\n' "\$WLIST" >&2; exit 76; }
echo "staged data tree locked read-only (zero writable entries)"
cp -- "$P1_PROJECT_ROOT/$P1_CHECKER_REPO_PATH" "\$CHECKER"
echo "$checker_sha  \$CHECKER" | sha256sum -c - >/dev/null || { echo "REFUSED: staged checker hash mismatch" >&2; exit 76; }
chmod a-w "\$CHECKER"
# immutable julia-env (gate-instrument provenance: checker calls use
# ONLY this staged project environment, never the live repo)
cp -- "$P1_TEST_PROJECT" "\$RUNROOT/julia-env/Project.toml"
cp -- "$P1_TEST_MANIFEST" "\$RUNROOT/julia-env/Manifest.toml"
[ "\$(stat -Lc %s "\$RUNROOT/julia-env/Project.toml")" = "$(filesize(P1_TEST_PROJECT))" ] || { echo "REFUSED: julia-env Project.toml size mismatch" >&2; exit 76; }
[ "\$(stat -Lc %s "\$RUNROOT/julia-env/Manifest.toml")" = "$(filesize(P1_TEST_MANIFEST))" ] || { echo "REFUSED: julia-env Manifest.toml size mismatch" >&2; exit 76; }
sha256sum -c <<JENVPINS >/dev/null || { echo "REFUSED: julia-env staged copy hash mismatch" >&2; exit 76; }
$(p1_sha(P1_TEST_PROJECT))  \$RUNROOT/julia-env/Project.toml
$(p1_sha(P1_TEST_MANIFEST))  \$RUNROOT/julia-env/Manifest.toml
JENVPINS
MI="\$RUNROOT/source-inputs/init.nc"
MP="\$RUNROOT/source-inputs/published.nc"
JENV="\$RUNROOT/julia-env"
chmod -R a-w "\$RUNROOT/source-inputs" "\$RUNROOT/julia-env"
WLIST3=\$(find "\$RUNROOT/source-inputs" "\$RUNROOT/julia-env" -writable) || { echo "REFUSED: writable-entry scan failed on staged masters/julia-env" >&2; exit 76; }
[ -z "\$WLIST3" ] || { echo "REFUSED: writable entries remain in staged masters/julia-env" >&2; printf '%s\\n' "\$WLIST3" >&2; exit 76; }
echo "immutable source-input masters + julia-env staged and locked (TOCTOU closure: all state-gate checker calls read staged masters only; no live-repo cd)"

echo "=== P1-lw stage 2: writable source copy + full-tree content identity + frozen test template ==="
mkdir -p "\$SRCDIR"
cp -rT "$P1_SRC_ARTIFACT" "\$SRCDIR"
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
cp -r "\$SRCDIR/test" "\$RUNROOT/test-template"
sha256sum -c <<TEMPLATEPINS >/dev/null || { echo "REFUSED: frozen test-template pin mismatch" >&2; exit 69; }
$template_pins
TEMPLATEPINS
chmod -R a-w "\$RUNROOT/test-template"

echo "=== P1-lw stage 3: REPORTING-ONLY PATCH (rev6 exact text; anchored; exactly-once; full-sha + region + census gates) ==="
PD="\$RUNROOT/patch"
cat > "\$PD/anchor0.txt" <<'P1A0'
$P1_ANCHOR0
P1A0
cat > "\$PD/includes.txt" <<'P1INC'
$p_includes
P1INC
cat > "\$PD/anchor1.txt" <<'P1A1'
$P1_ANCHOR1
P1A1
cat > "\$PD/anchor2.txt" <<'P1A2'
$P1_ANCHOR2
P1A2
cat > "\$PD/block.txt" <<'P1BLK'
$p_block
P1BLK
SA="\$SRCDIR/$P1_SOLVE_ADEPT_REL"
echo "$P1_SOLVE_ADEPT_SHA  \$SA" | sha256sum -c - >/dev/null || { echo "REFUSED: pre-patch solve_adept.cpp sha != pinned original" >&2; exit 70; }
cp -- "\$SA" "\$RUNROOT/patch/solve_adept.cpp.orig"
awk -v af="\$PD/anchor0.txt" -v incf="\$PD/includes.txt" 'BEGIN{ getline a0 < af; while ((getline l < incf) > 0) inc[++m]=l; n=0 } { print; if (\$0 == a0) { for (i=1;i<=m;i++) print inc[i]; n++ } } END{ exit (n==1) ? 0 : 1 }' "\$SA" > "\$PD/step1.cpp" || { echo "REFUSED: EDIT A include anchor not exactly once" >&2; exit 70; }
awk -v a1f="\$PD/anchor1.txt" -v a2f="\$PD/anchor2.txt" -v bf="\$PD/block.txt" 'BEGIN{ getline a1 < a1f; getline a2 < a2f; while ((getline l < bf) > 0) blk[++m]=l; n=0 } { print; if (prev == a1 && \$0 == a2) { for (i=1;i<=m;i++) print blk[i]; n++ } prev=\$0 } END{ exit (n==1) ? 0 : 1 }' "\$PD/step1.cpp" > "\$PD/patched.cpp" || { echo "REFUSED: EDIT B report anchor pair not exactly once" >&2; exit 70; }
cp -- "\$PD/patched.cpp" "\$SA"
echo "$(patch.patched_sha)  \$SA" | sha256sum -c - >/dev/null || { echo "REFUSED: patched solve_adept.cpp sha != generation-derived pin" >&2; exit 70; }
[ "\$(wc -l < "\$SA")" = "$(patch.patched_wc)" ] || { echo "REFUSED: patched line count != $(patch.patched_wc) (orig $(patch.orig_wc) + 14)" >&2; exit 70; }
[ "\$(grep -cxF '#include <sstream>' "\$SA" || true)" = 1 ] || { echo "REFUSED: census: sstream include not exactly once" >&2; exit 70; }
[ "\$(grep -cxF '#include <iomanip>' "\$SA" || true)" = 1 ] || { echo "REFUSED: census: iomanip include not exactly once" >&2; exit 70; }
[ "\$(grep -cxF '#include <limits>' "\$SA" || true)" = 1 ] || { echo "REFUSED: census: limits include not exactly once" >&2; exit 70; }
[ "\$(grep -cF 'P1_ITER0_FULL' "\$SA" || true)" = 1 ] || { echo "REFUSED: census: P1_ITER0_FULL token not exactly once in source" >&2; exit 70; }
[ "\$(grep -cF 'if (niter == 0) {' "\$SA" || true)" = 1 ] || { echo "REFUSED: census: niter==0 gate not exactly once" >&2; exit 70; }
[ "\$(grep -cF 'std::setprecision(std::numeric_limits<Real>::max_digits10)' "\$SA" || true)" = 1 ] || { echo "REFUSED: census: setprecision(max_digits10) not exactly once" >&2; exit 70; }
[ "\$(grep -cF 'LOG << p1_full.str() << "\\n";' "\$SA" || true)" = 1 ] || { echo "REFUSED: census: const-char literal-newline flush form not exactly once" >&2; exit 70; }
[ "\$(grep -c 'p1_full' "\$SA" || true)" = 3 ] || { echo "REFUSED: census: p1_full line count != 3" >&2; exit 70; }
[ "\$(grep -cF 'LOG << "Iteration " << niter' "\$SA" || true)" = 1 ] || { echo "REFUSED: rounded report anchor not exactly once after patch (byte-unchanged gate)" >&2; exit 70; }
grep -F -A 12 'LOG << "Iteration " << niter' "\$SA" > "\$PD/region.txt"
echo "$(patch.region_sha)  \$PD/region.txt" | sha256sum -c - >/dev/null || { echo "REFUSED: patched region hash != generation-derived pin" >&2; exit 70; }
( cd "\$SRCDIR" && sha256sum -c <<'COPYTREEX' >/dev/null ) || { echo "REFUSED: registered-tree identity (except solve_adept.cpp) violated after patch" >&2; exit 70; }
$copy_tree_except
COPYTREEX
echo "reporting-only patch applied and gated (orig $P1_SOLVE_ADEPT_SHA -> patched $(patch.patched_sha); region $(patch.region_sha))"

echo "=== P1-lw stage 3c: SOURCE-SEMANTIC GATES (prior-term + executed-path; mechanical exact-pinned extraction; ledger source-cites these) ==="
[ "\$(grep -cxF '$P1_SEM_ALG_LINE' "\$SA" || true)" = 1 ] || { echo "REFUSED: semantic gate: algorithm-request line (MINIMIZER_ALGORITHM_LIMITED_MEMORY_BFGS) not exactly once" >&2; exit 70; }
[ "\$(grep -cxF '$P1_SEM_XPRIOR_LINE' "\$SA" || true)" = 1 ] || { echo "REFUSED: semantic gate: x_prior initialization line not exactly once" >&2; exit 70; }
sed -n '$(sem.jprior_start),$(sem.jprior_end)p' "\$SA" > "\$PD/jprior_region.txt"
echo "$(sem.jprior_sha)  \$PD/jprior_region.txt" | sha256sum -c - >/dev/null || { echo "REFUSED: semantic gate: J_prior callback region hash != generation-derived pin" >&2; exit 70; }
[ "\$(grep -cF 'calc_background_cost_function(xdata-data.ckd_model->x_prior' "\$PD/jprior_region.txt" || true)" = 1 ] || { echo "REFUSED: semantic gate: background-cost prior form missing from region" >&2; exit 70; }
sed -n '$(P1_SEM_AS_START),$(P1_SEM_AS_END)p' "$P1_ADEPT_SOURCE_H" > "\$PD/lbfgs_region.txt"
echo "$(sem.as_region_sha)  \$PD/lbfgs_region.txt" | sha256sum -c - >/dev/null || { echo "REFUSED: semantic gate: unbounded LBFGS loop region hash != generation-derived pin" >&2; exit 70; }
[ "\$(grep -cF '$P1_SEM_AS_REPORT_FRAG' "\$PD/lbfgs_region.txt" || true)" = 1 ] || { echo "REFUSED: semantic gate: pre-step report_progress call missing from the unbounded loop region" >&2; exit 70; }
[ "\$(grep -cF '$P1_SEM_AS_DEF_FRAG' "\$PD/lbfgs_region.txt" || true)" = 1 ] || { echo "REFUSED: semantic gate: unbounded LBFGS definition line missing from region" >&2; exit 70; }
CM="\$SRCDIR/$P1_SEM_CM_REL"
sed -n '$(sem.cm_start),$(sem.cm_end)p' "\$CM" > "\$PD/bgcost_region.txt"
echo "$(sem.cm_region_sha)  \$PD/bgcost_region.txt" | sha256sum -c - >/dev/null || { echo "REFUSED: semantic gate: calc_background_cost_function region hash != generation-derived pin" >&2; exit 70; }
[ "\$(grep -cF 'Real cost_fn = 0.0;' "\$PD/bgcost_region.txt" || true)" = 1 ] || { echo "REFUSED: semantic gate: cost_fn zero initialization missing" >&2; exit 70; }
[ "\$(grep -cF 'gradient = 0.0;' "\$PD/bgcost_region.txt" || true)" = 1 ] || { echo "REFUSED: semantic gate: gradient zeroing missing" >&2; exit 70; }
[ "\$(grep -cF '0.5*dot_product(delta_x_local,gradient_local)' "\$PD/bgcost_region.txt" || true)" = 2 ] || { echo "REFUSED: semantic gate: quadratic delta_x contributions not exactly twice (active + rayleigh)" >&2; exit 70; }
[ "\$(grep -cF 'return cost_fn;' "\$PD/bgcost_region.txt" || true)" = 1 ] || { echo "REFUSED: semantic gate: return of accumulated cost missing (no-constant semantics)" >&2; exit 70; }
echo "SOURCE-SEMANTIC GATES passed (five regions): J_prior callback region (patched lines $(sem.jprior_start)-$(sem.jprior_end); $(sem.jprior_sha)), x_prior init site, algorithm request, unbounded LBFGS pre-step report region (adept_source.h:$(P1_SEM_AS_START)-$(P1_SEM_AS_END); $(sem.as_region_sha)), calc_background_cost_function no-constant region (ckd_model.cpp:$(sem.cm_start)-$(sem.cm_end); $(sem.cm_region_sha)) -- J_prior == 0 at iteration 0 is source-proven for both prior branches"

echo "=== P1-lw stage 3b: SINGLE instrumented build (corrected fresh-autoreconf recipe; ONE binary for ALL SIX probes) ==="
cd "\$SRCDIR"
autoreconf -i
$P1_CONFIGURE_ARGV
make -j"\$SLURM_CPUS_PER_TASK"
test -x "\$SRCDIR/src/ecckd/optimize_lut" || { echo "REFUSED: optimize_lut not built" >&2; exit 68; }
[ "\$(strings "\$SRCDIR/src/ecckd/optimize_lut" | grep -cF 'Adept LBFGS' || true)" -ge 1 ] || { echo "REFUSED: Adept LBFGS banner string absent from binary" >&2; exit 68; }
[ "\$(strings "\$SRCDIR/src/ecckd/optimize_lut" | grep -cF 'P1_ITER0_FULL' || true)" -ge 1 ] || { echo "REFUSED: P1_ITER0_FULL instrumentation string absent from binary" >&2; exit 68; }
cp -- "\$SRCDIR/src/ecckd/optimize_lut" "\$RUNROOT/bin/optimize_lut_p1"
chmod a-w "\$RUNROOT/bin/optimize_lut_p1"
cp -- "\$SRCDIR/config.log" "\$RUNROOT/config.log.p1"
./config.status --config > "\$RUNROOT/config.status.config.txt"
echo "--- config.status --config (single configure/build) ---"
cat "\$RUNROOT/config.status.config.txt"
[ "\$(cat "\$RUNROOT/config.status.config.txt")" = "$P1_CONFIG_STATUS_EXPECT" ] || { echo "REFUSED: config.status --config != corrected reviewed recipe rendering" >&2; exit 68; }
sha256sum "\$RUNROOT/config.log.p1" "\$RUNROOT/config.status.config.txt"
BIN_SHA=\$(sha256sum "\$RUNROOT/bin/optimize_lut_p1" | cut -d' ' -f1)
echo "immutable instrumented binary content pin (captured ONCE after chmod; verified before EVERY probe and post-run): \$BIN_SHA  \$RUNROOT/bin/optimize_lut_p1"

echo "=== P1-lw stage 4: PRIVATE published coefficient-block SPLICE construction + three-state gates ==="
"\$JULIA_BIN" --project="\$JENV" "\$CHECKER" build-splice "\$MI" "\$MP" "\$RUNROOT/splice/splice_input.nc" || { echo "REFUSED: splice construction failed (fail-closed)" >&2; exit 77; }
"\$JULIA_BIN" --project="\$JENV" "\$CHECKER" gate-splice "\$RUNROOT/splice/splice_input.nc" "\$MI" "\$MP" || { echo "REFUSED: splice integrity gate failed (exact eight-variable typed diff / published equality / pinned counts / attrs / signature)" >&2; exit 77; }
"\$JULIA_BIN" --project="\$JENV" "\$CHECKER" gate-plateau "\$RUNROOT/work-plateau-a/lw_raw-ckd-definition/$P1_RAWDEF_BASENAME" "\$MI" || { echo "REFUSED: plateau state gate failed (four-active pinned counts / minor-four exact equality / signature)" >&2; exit 77; }
SPLICE_SHA=\$(sha256sum "\$RUNROOT/splice/splice_input.nc" | cut -d' ' -f1)
echo "splice runtime content sha (PRIVATE temp state; recorded, never canonical): \$SPLICE_SHA"
for pws in published-a published-b; do
    cp -- "\$RUNROOT/splice/splice_input.nc" "\$RUNROOT/work-\$pws/lw_raw-ckd-definition/$P1_RAWDEF_BASENAME"
    echo "\$SPLICE_SHA  \$RUNROOT/work-\$pws/lw_raw-ckd-definition/$P1_RAWDEF_BASENAME" | sha256sum -c - >/dev/null || { echo "REFUSED: staged splice copy hash mismatch (\$pws)" >&2; exit 77; }
done
chmod a-w "\$RUNROOT/splice/splice_input.nc"

echo "=== P1-lw stage 4b: per-workspace wrappers (Netlib preload + FP-trap shim; SAME binary) + loader proof ==="
sha256sum -c <<'RUNTIMEPINS' || { echo "REFUSED: runtime BLAS/LAPACK/shim pin mismatch" >&2; exit 79; }
$P1_NETLIB_BLAS_SHA  $P1_NETLIB_BLAS
$P1_NETLIB_LAPACK_SHA  $P1_NETLIB_LAPACK
$P1_SHIM_SO_SHA  $P1_SHIM_SO
RUNTIMEPINS
command -v readelf >/dev/null || { echo "MISSING readelf" >&2; exit 65; }
RE_BLAS=\$(readelf -d "$P1_NETLIB_BLAS")
RE_LAPACK=\$(readelf -d "$P1_NETLIB_LAPACK")
[ "\$(grep -cF 'Library soname: [libblas.so.3]' <<<"\$RE_BLAS" || true)" = 1 ] || { echo "REFUSED: netlib BLAS SONAME != libblas.so.3" >&2; exit 79; }
[ "\$(grep -cF 'Library soname: [liblapack.so.3]' <<<"\$RE_LAPACK" || true)" = 1 ] || { echo "REFUSED: netlib LAPACK SONAME != liblapack.so.3" >&2; exit 79; }
# the FP-trap shim lives on a USER-WRITABLE /shared path, so it is
# staged immutable into the RUNROOT and ONLY the staged copy is
# preloaded (Agent 42 same-class finding); the Netlib BLAS/LAPACK
# preloads remain canonical deliberately: they are root-owned /usr
# paths outside the user-writable class, pinned at stage 4b
cp -L -- "$P1_SHIM_SO" "\$RUNROOT/tools/h5open_before_traps.so"
SHIM="\$RUNROOT/tools/h5open_before_traps.so"
[ "\$(stat -Lc %s "\$SHIM")" = "$(filesize(P1_SHIM_SO))" ] || { echo "REFUSED: staged shim size mismatch" >&2; exit 79; }
echo "$P1_SHIM_SO_SHA  \$SHIM" | sha256sum -c - >/dev/null || { echo "REFUSED: staged shim hash mismatch" >&2; exit 79; }
chmod a-w "\$SHIM"
for ws in $P1_WS_LIST; do
    W="\$RUNROOT/tools/optimize_lut_wrap_\$ws"
    cat > "\$W" <<WRAP
#!/bin/bash
export LD_PRELOAD="$P1_NETLIB_BLAS:$P1_NETLIB_LAPACK:\$SHIM"
exec "\$RUNROOT/bin/optimize_lut_p1" "\\\$@"
WRAP
    chmod +x "\$W"
    sha256sum "\$W"
    [ "\$(grep -cxF "export LD_PRELOAD=\\"$P1_NETLIB_BLAS:$P1_NETLIB_LAPACK:\$SHIM\\"" "\$W" || true)" = 1 ] || { echo "REFUSED: wrapper preload line/order drifted (\$ws; staged shim required)" >&2; exit 79; }
done
LDD_OUT=\$(LD_PRELOAD="$P1_NETLIB_BLAS:$P1_NETLIB_LAPACK:\$SHIM" ldd "\$RUNROOT/bin/optimize_lut_p1")
echo "--- ldd (single binary) ---"
echo "\$LDD_OUT"
[ "\$(grep -cF "$P1_NETLIB_BLAS" <<<"\$LDD_OUT" || true)" = 1 ] || { echo "REFUSED: exact BLAS preload row count != 1" >&2; exit 79; }
[ "\$(grep -cF "$P1_NETLIB_LAPACK" <<<"\$LDD_OUT" || true)" = 1 ] || { echo "REFUSED: exact LAPACK preload row count != 1" >&2; exit 79; }
[ "\$(grep -cF 'liblapack.so.3 =>' <<<"\$LDD_OUT" || true)" = 0 ] || { echo "REFUSED: liblapack.so.3 alias row present" >&2; exit 79; }
[ "\$(grep -cF 'libblas.so.3 =>' <<<"\$LDD_OUT" || true)" = 0 ] || { echo "REFUSED: libblas.so.3 alias row present" >&2; exit 79; }
LN_B=\$(awk -v pat="$P1_NETLIB_BLAS" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
LN_L=\$(awk -v pat="$P1_NETLIB_LAPACK" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
LN_S=\$(awk -v pat="\$SHIM" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
{ [ -n "\$LN_B" ] && [ -n "\$LN_L" ] && [ -n "\$LN_S" ] && [ "\$LN_B" -lt "\$LN_L" ] && [ "\$LN_L" -lt "\$LN_S" ]; } || { echo "REFUSED: preload row order is not BLAS<LAPACK<H5shim" >&2; exit 79; }

# SYMMETRIC DRIFT-CONTROL RUN ORDER (frozen design):
# init-a -> published-a -> plateau-a -> plateau-b -> published-b -> init-b
for ws in $P1_WS_LIST; do
    echo "=== P1-lw stage 5-\$ws: unbounded 1-iteration probe (C1-proven injection; explicit OpenMP controls) ==="
    echo "\$BIN_SHA  \$RUNROOT/bin/optimize_lut_p1" | sha256sum -c - >/dev/null || { echo "REFUSED: immutable binary content drift before probe \$ws" >&2; exit 71; }
    TC="\$RUNROOT/testcopy-\$ws"
    cp -r "\$RUNROOT/test-template" "\$TC"
    chmod -R u+w "\$TC"
    cd "\$TC"
    sed 's/@PACKAGE_VERSION@/1.2/g' version.h.in > version.h
    sed -i \\
      -e "s|^CKDMIP_DIR=.*|CKDMIP_DIR=/shared/home/greg/build/ckdmip-1.0|" \\
      -e "s|^CKDMIP_DATA_DIR=.*|CKDMIP_DATA_DIR=\$RUNROOT/data|" \\
      -e "s|^WORK_DIR=.*|WORK_DIR=\$RUNROOT/work-\$ws|" \\
      -e "s|^BINDIR=.*|BINDIR=\$RUNROOT/bin|" \\
      -e "s|^TRAINING_BOTH=no\$|TRAINING_BOTH=yes|" \\
      -e "s|^OPTIMIZE_LUT=.*|OPTIMIZE_LUT=\$RUNROOT/tools/optimize_lut_wrap_\$ws|" \\
      config.h
    for kv in "CKDMIP_DIR=/shared/home/greg/build/ckdmip-1.0" "CKDMIP_DATA_DIR=\$RUNROOT/data" "WORK_DIR=\$RUNROOT/work-\$ws" "BINDIR=\$RUNROOT/bin" "TRAINING_BOTH=yes" "OPTIMIZE_LUT=\$RUNROOT/tools/optimize_lut_wrap_\$ws"; do
        grep -qxF "\$kv" config.h || { echo "BAD config override (\$ws): \$kv" >&2; exit 68; }
    done
    sed -i 's|^[[:space:]]*test "\\\${PIPESTATUS\\[0\\]}" -eq 0[[:space:]]*\$|\\trc="\${PIPESTATUS[0]}"; if [ "\$rc" -ne 0 ]; then if [ "\$rc" -ge 128 ]; then echo "OPTIMIZE_LUT CHILD KILLED BY SIGNAL \$((rc-128)) (rc=\$rc)" >\\&2; else echo "OPTIMIZE_LUT CHILD FAILED rc=\$rc" >\\&2; fi; exit "\$rc"; fi|' optimize_lut_lw.sh
    grep -q "OPTIMIZE_LUT CHILD" optimize_lut_lw.sh || { echo "BAD sed: child-status surfacing not applied (\$ws)" >&2; exit 68; }
    grep -qF 'test "\${PIPESTATUS[0]}" -eq 0' optimize_lut_lw.sh && { echo "BAD sed: raw PIPESTATUS test remains (\$ws)" >&2; exit 68; } || true
    # UNBOUNDED 1-ITERATION INJECTION (config-only; anchored;
    # exactly-once + leak gates; IDENTICAL for all six probes)
    sed -i 's|model_id=lw_\${APPLICATION}_\${BANDSTRUCT}-tol\${TOL} \\\\\$|&\\n\\t    bounded_minimization=0 \\\\\\n\\t    max_iterations=1 \\\\|' optimize_lut_lw.sh
    [ "\$(grep -cF 'bounded_minimization=0 \\' optimize_lut_lw.sh || true)" = 1 ] || { echo "REFUSED: \$ws flag injection not exactly once" >&2; exit 68; }
    [ "\$(grep -cF 'max_iterations=1 \\' optimize_lut_lw.sh || true)" = 1 ] || { echo "REFUSED: \$ws iteration injection not exactly once" >&2; exit 68; }
    [ "\$(grep -cF 'bounded_minimization' optimize_lut_lw.sh || true)" = 1 ] || { echo "REFUSED: \$ws stray bounded_minimization reference" >&2; exit 68; }
    echo "probe \$ws: OMP_NUM_THREADS=\$SLURM_CPUS_PER_TASK OMP_DYNAMIC=FALSE SLURM_CPUS_PER_TASK=\$SLURM_CPUS_PER_TASK" | tee "\$RUNROOT/\$ws-probe-run.log"
    OMP_NUM_THREADS="\$SLURM_CPUS_PER_TASK" OMP_DYNAMIC=FALSE \\
        APPLICATION=climate BAND_STRUCTURE=fsck TOLERANCE=0.0161 \\
        bash optimize_lut_lw.sh relative-base |& tee -a "\$RUNROOT/\$ws-probe-run.log"
    RLOG="\$RUNROOT/\$ws-probe-run.log"
    [ "\$(grep -cF '$banner_1' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$ws did not show exactly one Adept banner (1/0.02)" >&2; exit 71; }
    [ "\$(grep -cF '$banner_3000' "\$RLOG" || true)" = 0 ] || { echo "REFUSED: \$ws unexpectedly ran 3000 iterations" >&2; exit 71; }
    [ "\$(grep -cF 'Minimization is unbounded' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$ws did not log unbounded mode (probe mode gate)" >&2; exit 71; }
    [ "\$(grep -cF 'Minimization is bounded' "\$RLOG" || true)" = 0 ] || { echo "REFUSED: \$ws logged bounded mode (bounded-mode leak)" >&2; exit 71; }
    [ "\$(grep -cF 'number bounded below:' "\$RLOG" || true)" = 0 ] || { echo "REFUSED: \$ws bounded-census line present (bounded-mode leak)" >&2; exit 71; }
    [ "\$(grep -cF 'Optimizing coefficients of: composite h2o o3 co2' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$ws base gas banner not exactly once" >&2; exit 71; }
    [ "\$(grep -cF 'Convergence status: ' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$ws convergence-status line not exactly once" >&2; exit 71; }
    ST_LINE=\$(grep -F 'Convergence status: ' "\$RLOG")
    RUN_STATUS="\${ST_LINE#*Convergence status: }"
    [ -n "\$RUN_STATUS" ] || { echo "REFUSED: \$ws terminal status capture is empty" >&2; exit 71; }
    printf '%s' "\$RUN_STATUS" > "\$RUNROOT/\$ws-status.txt"
    echo "probe \$ws terminal status (RECORDED observation; membership NOT gated per the frozen design): '\$RUN_STATUS'"
    [ "\$(grep -cF 'Iteration 0: cost function = ' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$ws rounded Iteration-0 line not exactly once" >&2; exit 71; }
    [ "\$(grep -cF 'P1_ITER0_FULL: ' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$ws P1_ITER0_FULL line not exactly once" >&2; exit 71; }
    R2="\$RUNROOT/work-\$ws/lw_raw-ckd-definition/$P1_RAW2_BASENAME"
    test -s "\$R2" || { echo "MISSING \$ws one-step raw2 output" >&2; exit 71; }
    "\$JULIA_BIN" --project="\$JENV" "\$CHECKER" tokens "\$RLOG" "\$RUNROOT/\$ws-tokens.txt" "\$ws" || { echo "REFUSED: \$ws token extraction/instrument gate failed (exactly-once, proof fields, finite, 6-sig-fig round-back)" >&2; exit 74; }
done

echo "=== P1-lw stage 6: post-run re-verification + structural scans + six-probe comparison (ZERO canonical writes by design) ==="
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
# TARGET-DEFINING INPUT no-mutation evidence (monitor blocker 3): every
# staged per-workspace scientific input re-verified after ALL probes --
# this is what licenses treating the six J0_reported values as
# same-input comparisons
while read -r esz p; do
    asz=\$(stat -Lc %s "\$p") || { echo "REFUSED: cannot stat staged master/env post-run: \$p" >&2; exit 78; }
    [ "\$asz" = "\$esz" ] || { echo "REFUSED: staged master/env size drifted during the runs: \$p (\$asz != \$esz)" >&2; exit 78; }
done <<POSTMASTERSIZES
$post_master_sizes
POSTMASTERSIZES
sha256sum -c <<POSTSTAGE >/dev/null || { echo "REFUSED: staged per-workspace scientific input drifted during the runs (target-defining input mutation)" >&2; exit 78; }
$post_stage_lines
POSTSTAGE
echo "$P1_SHIM_SO_SHA  \$SHIM" | sha256sum -c - >/dev/null || { echo "REFUSED: staged shim drifted during the runs" >&2; exit 78; }
sha256sum -c <<TEMPLATEPOST >/dev/null || { echo "REFUSED: frozen test-template drifted during the runs" >&2; exit 78; }
$template_pins
TEMPLATEPOST
for pws in published-a published-b; do
    echo "\$SPLICE_SHA  \$RUNROOT/work-\$pws/lw_raw-ckd-definition/$P1_RAWDEF_BASENAME" | sha256sum -c - >/dev/null || { echo "REFUSED: published-splice input drifted during the runs (\$pws)" >&2; exit 78; }
done
echo "\$SPLICE_SHA  \$RUNROOT/splice/splice_input.nc" | sha256sum -c - >/dev/null || { echo "REFUSED: private splice master drifted during the runs" >&2; exit 78; }
echo "$checker_sha  \$CHECKER" | sha256sum -c - >/dev/null || { echo "REFUSED: staged checker drifted during the runs" >&2; exit 78; }
echo "\$BIN_SHA  \$RUNROOT/bin/optimize_lut_p1" | sha256sum -c - >/dev/null || { echo "REFUSED: immutable binary content drift post-run" >&2; exit 78; }
echo "staged per-workspace inputs re-verified post-run (LBL+gpoints x6, init x2, plateau x2, splice x2 + master, source-input masters, julia-env, checker, shim, test-template, binary; no-mutation evidence for same-input comparison)"
# STRUCTURAL-ONLY verification of the six serialized one-step outputs
# (two-tier policy: structure/missing refuse; nonfinite values are
# RECORDED observations, never refusals; no census claims)
for ws in $P1_WS_LIST; do
    R2="\$RUNROOT/work-\$ws/lw_raw-ckd-definition/$P1_RAW2_BASENAME"
    "\$JULIA_BIN" --project="\$JENV" "\$CHECKER" scan-structural "\$R2" "\$ws" "\$MI" || { echo "REFUSED: \$ws one-step output failed STRUCTURAL verification (structure faults refuse; nonfinite values never do)" >&2; exit 74; }
done
"\$JULIA_BIN" --project="\$JENV" "\$CHECKER" compare "\$RUNROOT" |& tee "\$RUNROOT/p1-compare.log" || { echo "REFUSED: six-probe duplicate/bridge/delta gates failed (drift recorded; branch assignment refused; values never averaged)" >&2; exit 74; }
sha256sum "\$RUNROOT/init-a-probe-run.log" "\$RUNROOT/published-a-probe-run.log" "\$RUNROOT/plateau-a-probe-run.log" \\
    "\$RUNROOT/plateau-b-probe-run.log" "\$RUNROOT/published-b-probe-run.log" "\$RUNROOT/init-b-probe-run.log" \\
    "\$RUNROOT/bin/optimize_lut_p1" "\$RUNROOT/splice/splice_input.nc" "\$RUNROOT/p1-compare.log"
for ws in $P1_WS_LIST; do
    sha256sum "\$RUNROOT/work-\$ws/lw_raw-ckd-definition/$P1_RAW2_BASENAME" "\$RUNROOT/\$ws-tokens.txt"
done
echo "RUNROOT preserved for diagnosis/forensics: \$RUNROOT (no cleanup by design)"
echo "=== P1-lw done \$(date -u +%FT%TZ) ==="
"""
end

# --- text gates ------------------------------------------------------------------------

function p1_bash_syntax_ok(text)
    try
        p = joinpath(mktempdir(), "p1_syntax_check.sbatch")
        write(p, text)
        success(pipeline(`bash -n $p`, stdout = devnull, stderr = devnull))
    catch
        false
    end
end

function p1_text_gate_issues(text, patch, sem)
    iss = String[]
    req = [
        sem.jprior_sha, sem.as_region_sha, sem.cm_region_sha,
        "sed -n '$(sem.jprior_start),$(sem.jprior_end)p'",
        "sed -n '$(P1_SEM_AS_START),$(P1_SEM_AS_END)p'",
        "sed -n '$(sem.cm_start),$(sem.cm_end)p'",
        "REFUSED: semantic gate: algorithm-request line (MINIMIZER_ALGORITHM_LIMITED_MEMORY_BFGS) not exactly once",
        "REFUSED: semantic gate: x_prior initialization line not exactly once",
        "REFUSED: semantic gate: J_prior callback region hash != generation-derived pin",
        "REFUSED: semantic gate: unbounded LBFGS loop region hash != generation-derived pin",
        "REFUSED: semantic gate: pre-step report_progress call missing from the unbounded loop region",
        "REFUSED: semantic gate: calc_background_cost_function region hash != generation-derived pin",
        "REFUSED: semantic gate: cost_fn zero initialization missing",
        "REFUSED: semantic gate: quadratic delta_x contributions not exactly twice (active + rayleigh)",
        "J_prior == 0 at iteration 0 is source-proven for both prior branches",
        "JULIA_BIN=$P1_JULIA_BIN",
        "REFUSED: julia version line",
        P1_JULIA_VERSION_LINE,
        "$(p1_sha(P1_TEST_PROJECT))  $P1_TEST_PROJECT",
        "$(p1_sha(P1_TEST_MANIFEST))  $P1_TEST_MANIFEST",
        "BIN_SHA=\$(sha256sum \"\$RUNROOT/bin/optimize_lut_p1\" | cut -d' ' -f1)",
        "REFUSED: immutable binary content drift before probe \$ws",
        "REFUSED: immutable binary content drift post-run",
        "POSTSTAGE", "POSTMASTERSIZES", "JENVPINS", "TEMPLATEPOST",
        "REFUSED: staged per-workspace scientific input drifted during the runs (target-defining input mutation)",
        "REFUSED: published-splice input drifted during the runs",
        "REFUSED: private splice master drifted during the runs",
        "REFUSED: staged checker drifted during the runs",
        "MI=\"\$RUNROOT/source-inputs/init.nc\"",
        "MP=\"\$RUNROOT/source-inputs/published.nc\"",
        "JENV=\"\$RUNROOT/julia-env\"",
        "$P1_INIT_SHA $P1_INIT_BYTES $P1_INIT_PATH \$RUNROOT/source-inputs/init.nc",
        "$P1_PUB_SHA $P1_PUB_BYTES $P1_PUB_PATH \$RUNROOT/source-inputs/published.nc",
        "chmod -R a-w \"\$RUNROOT/source-inputs\" \"\$RUNROOT/julia-env\"",
        "REFUSED: writable entries remain in staged masters/julia-env",
        "REFUSED: julia-env staged copy hash mismatch",
        "REFUSED: staged master/env size drifted during the runs",
        "$(p1_sha(P1_TEST_PROJECT))  \$RUNROOT/julia-env/Project.toml",
        "$(p1_sha(P1_TEST_MANIFEST))  \$RUNROOT/julia-env/Manifest.toml",
        "SHIM=\"\$RUNROOT/tools/h5open_before_traps.so\"",
        "$P1_SHIM_SO_SHA  \$SHIM",
        "export LD_PRELOAD=\"$P1_NETLIB_BLAS:$P1_NETLIB_LAPACK:\$SHIM\"",
        "REFUSED: staged shim hash mismatch",
        "REFUSED: staged shim drifted during the runs",
        "root-owned /usr",
        "paths outside the user-writable class, pinned at stage 4b",
        "REFUSED: frozen test-template drifted during the runs",
        "REFUSED: head-node execution is not permitted",
        "RUNROOT=\"\$G4WORK/g4-diag/\${SLURM_JOB_ID}/lw-p1\"",
        "CHECKER=\"\$RUNROOT/tools/gate4_p1_splice_checker.jl\"",
        "cp -rT \"$P1_SRC_ARTIFACT\" \"\$SRCDIR\"",
        P1_DESIGN_SHA,
        "$P1_PROJECT_ROOT/$P1_DESIGN_REPO_PATH",
        "$P1_PROJECT_ROOT/$P1_CHECKER_REPO_PATH",
        P1_LEDGERS[1].sha, P1_LEDGERS[2].sha, P1_LEDGERS[3].sha,
        P1_LEDGERS[4].sha,
        P1_INIT_SHA, P1_PLATEAU_SHA, P1_PUB_SHA,
        P1_SOLVE_ADEPT_SHA, patch.patched_sha, patch.region_sha,
        "quota_health \$((50*1024*1024*1024))",
        "autoreconf -i",
        P1_CONFIGURE_ARGV,
        P1_CONFIG_STATUS_EXPECT,
        "'LDFLAGS=-L$P1_ADEPT/lib -Wl,-rpath,$P1_ADEPT/lib'",
        "'LIBS=-ladept'",
        "optimize_lut_p1",
        "chmod a-w \"\$RUNROOT/bin/optimize_lut_p1\"",
        "REFUSED: P1_ITER0_FULL instrumentation string absent from binary",
        "GATEPINS", "ARTTREE", "COPYTREE", "EXECBITS", "TEMPLATEPINS",
        "COPYTREEX", "P1A0", "P1INC", "P1A1", "P1A2", "P1BLK",
        "/usr/bin/gcc",
        "gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0",
        "GNU Make 4.3",
        "bash optimize_lut_lw.sh relative-base",
        "TRAINING_BOTH=yes",
        "APPLICATION=climate BAND_STRUCTURE=fsck TOLERANCE=0.0161",
        "OMP_NUM_THREADS=\"\$SLURM_CPUS_PER_TASK\" OMP_DYNAMIC=FALSE",
        "chmod -R a-w \"\$RUNROOT/data\"",
        "REFUSED: writable entries remain in the staged data tree after chmod",
        "staged data tree locked read-only (zero writable entries)",
        "DATAPOSTSIZES", "DATAPOST",
        "REFUSED: staged data input drifted during the runs (sha mismatch)",
        "staged data inputs re-verified post-run (6 files, size+sha, zero writable entries)",
        "REFUSED: pre-patch solve_adept.cpp sha != pinned original",
        "REFUSED: EDIT A include anchor not exactly once",
        "REFUSED: EDIT B report anchor pair not exactly once",
        "REFUSED: patched solve_adept.cpp sha != generation-derived pin",
        "REFUSED: census: sstream include not exactly once",
        "REFUSED: census: iomanip include not exactly once",
        "REFUSED: census: limits include not exactly once",
        "REFUSED: census: P1_ITER0_FULL token not exactly once in source",
        "REFUSED: census: niter==0 gate not exactly once",
        "REFUSED: census: setprecision(max_digits10) not exactly once",
        "REFUSED: census: const-char literal-newline flush form not exactly once",
        "REFUSED: census: p1_full line count != 3",
        "REFUSED: rounded report anchor not exactly once after patch (byte-unchanged gate)",
        "REFUSED: patched region hash != generation-derived pin",
        "REFUSED: registered-tree identity (except solve_adept.cpp) violated after patch",
        "grep -cF 'LOG << p1_full.str() << \"\\n\";'",
        "REFUSED: splice construction failed (fail-closed)",
        "REFUSED: splice integrity gate failed (exact eight-variable typed diff / published equality / pinned counts / attrs / signature)",
        "REFUSED: plateau state gate failed (four-active pinned counts / minor-four exact equality / signature)",
        "REFUSED: staged splice copy hash mismatch",
        "chmod a-w \"\$RUNROOT/splice/splice_input.nc\"",
        "REFUSED: \$ws flag injection not exactly once",
        "REFUSED: \$ws iteration injection not exactly once",
        "REFUSED: \$ws did not log unbounded mode (probe mode gate)",
        "REFUSED: \$ws logged bounded mode (bounded-mode leak)",
        "REFUSED: \$ws bounded-census line present (bounded-mode leak)",
        "REFUSED: \$ws terminal status capture is empty",
        "RECORDED observation; membership NOT gated per the frozen design",
        "REFUSED: \$ws rounded Iteration-0 line not exactly once",
        "REFUSED: \$ws P1_ITER0_FULL line not exactly once",
        "REFUSED: \$ws token extraction/instrument gate failed (exactly-once, proof fields, finite, 6-sig-fig round-back)",
        "REFUSED: \$ws one-step output failed STRUCTURAL verification (structure faults refuse; nonfinite values never do)",
        "REFUSED: six-probe duplicate/bridge/delta gates failed (drift recorded; branch assignment refused; values never averaged)",
        "Minimization is unbounded",
        "Minimization is bounded",
        "number bounded below:",
        "flock -n 9",
        "locks/p1-lw.lock",
        "cp -r \"\$SRCDIR/test\" \"\$RUNROOT/test-template\"",
        "chmod -R a-w \"\$RUNROOT/test-template\"",
        "cp -r \"\$RUNROOT/test-template\" \"\$TC\"",
        "RUNROOT preserved for diagnosis/forensics",
        "index(\$0, pat) && !ln { ln = NR }"]
    for r in req
        occursin(r, text) || push!(iss, "required text missing: $r")
    end
    ws_loop = "for ws in $P1_WS_LIST; do"
    for (pat, n, what) in (
        (Regex("\\Q" * ws_loop * "\\E"), 5,
         "six-workspace loops (mkdir, wrappers, runs, structural scans, final hash echoes)"),
        (r"bash optimize_lut_lw\.sh relative-base", 1,
         "relative-base invocation (single line inside the run loop)"),
        (Regex("\\Q" * P1_CONFIGURE_ARGV * "\\E"), 1, "configure invocation"),
        (Regex("\\Q" * P1_CONFIG_STATUS_EXPECT * "\\E"), 1,
         "config.status expectation"),
        (Regex("\\Q'LIBS=-ladept'\\E"), 1, "quoted LIBS assignment"),
        (Regex("\\Qbounded_minimization\\E"), 4,
         "flag token (header comment + sed payload + 2 count gates)"),
        (Regex("\\Qmax_iterations=1\\E"), 2,
         "iteration token (sed payload + count gate)"),
        (Regex("\\Q\"\$JULIA_BIN\" --project=\"\$JENV\" \"\$CHECKER\"\\E"), 6,
         "checker CLI invocations via the staged julia-env (build/gate-splice/gate-plateau/tokens/scan/compare)"),
        (Regex("\\Q\$BIN_SHA  \$RUNROOT/bin/optimize_lut_p1\\E"), 3,
         "immutable-binary content gates (per-probe loop + post-run + capture echo)"),
        (Regex("\\QEND{ exit (n==1) ? 0 : 1 }\\E"), 2,
         "awk exactly-once patch insertions (EDIT A + EDIT B)"),
        (Regex("\\Q" * patch.patched_sha * "\\E"), 2,
         "patched-sha pin (gate + echo)"),
        (Regex("\\Q" * patch.region_sha * "\\E"), 2,
         "region-sha pin (gate + echo)"),
        (Regex("\\Qquota_health\\E"), 1, "quota guard invocation"),
        (Regex("\\Qchmod -R a-w \"\$RUNROOT/data\"\\E"), 1,
         "data-tree immutability lock"),
        (Regex("\\Qfind \"\$RUNROOT/data\" -writable\\E"), 2,
         "writable-entry scans (post-staging + post-run)"))
        m = length(collect(eachmatch(pat, text)))
        m == n || push!(iss, "$what expected exactly $n, got $m")
    end
    for bad in ("relative-ch4", "relative-n2o", "relative-cfc",
                "CANON_FINAL", "mv -n", ".g3.publish.",
                "gate4_x1_capture", "X1HELPER", "GATE4_X1_CAPTURE_PATH",
                "$P1_G4WORK/work/lw_ckd-definition/ecckd-1.2_lw_ckd-definition",
                "BOTH probes", "two probes", "four arrays",
                "published floor", "recovered-upstream", "bit-exact",
                "bit-equality", "bit-consistent",
                "outside the experiment-allowed set",
                "outside the allowed set",
                "--project=test",
                "cd $P1_PROJECT_ROOT &&")
        occursin(bad, text) && push!(iss, "forbidden text present: $bad")
    end
    # checker calls must never reference canonical (non-staged) inputs
    for m in eachmatch(Regex("(?m)^.*\\\$CHECKER\\\"[^\\n]*\\Q$P1_G4WORK\\E[^\\n]*\$"), text)
        push!(iss, "checker call references a canonical (non-staged) g4work path: $(m.match)")
    end
    for m in eachmatch(Regex("(?m)^.*\\\$CHECKER\\\"[^\\n]*\\Q/.julia/artifacts/\\E[^\\n]*\$"), text)
        push!(iss, "checker call references a canonical (non-staged) artifact path: $(m.match)")
    end
    for m in eachmatch(r"LDFLAGS=[^']*-ladept", text)
        push!(iss, "-ladept inside LDFLAGS (order-broken position): $(m.match)")
    end
    for m in eachmatch(r"\|\s*head\b", text)
        push!(iss, "early-closing head pipeline present: $(m.match)")
    end
    for m in eachmatch(r"(?m)^.*\bstrings\b.*grep -cF.*= 0.*$", text)
        push!(iss, "binary strings absence test (banned class): $(m.match)")
    end
    for m in eachmatch(r"(?m)^[^#\n]*> *\"?\$G4WORK/(?!g4-diag|locks/p1-lw\.lock)", text)
        push!(iss, "redirect toward shared G4WORK area: $(m.match)")
    end
    iss
end

# --- conclusion-ceiling extraction (rev6 verbatim; embedded in JSON/MD) ---------

function p1_ceiling_extract(design)
    i = findfirst("PREREGISTERED CONCLUSION CEILING for P1", design)
    j = findfirst("## 5. Implementation", design)
    (i === nothing || j === nothing || first(j) <= first(i)) &&
        return nothing
    String(strip(design[first(i):prevind(design, first(j))]))
end

# --- fixtures ------------------------------------------------------------------------------

function p1_fixtures(tree, patch, sem, design)
    t = Dict{String, Bool}()
    fx = mktempdir()
    sd = mktempdir()
    shaof(p) = bytes2hex(sha256(read(p)))

    # SHARED schema+value check behavioral fixtures (same code the job
    # runs via the staged checker)
    tinysig = ["alpha|Float32|n", "beta|Float64|n"]
    tinydims = [("n", 3)]
    function write_tiny(path; alpha_ty = Float32, beta = [1.0, 2.0, 3.0],
                        extra = false, drop_beta = false, alpha_dim = "n",
                        n_extent = 3, extra_dim = false)
        isfile(path) && rm(path)
        NCDataset(path, "c") do ds
            defDim(ds, "n", n_extent)
            alpha_dim == "m" && defDim(ds, "m", 3)
            extra_dim && defDim(ds, "spare", 2)
            va = defVar(ds, "alpha", alpha_ty, (alpha_dim,))
            va[:] = alpha_ty.(1:(alpha_dim == "n" ? n_extent : 3))
            if !drop_beta
                vb = defVar(ds, "beta", Float64, ("n",))
                vb[:] = beta
            end
            if extra
                ve = defVar(ds, "gamma", Float64, ("n",))
                ve[:] = zeros(3)
            end
        end
        path
    end
    good = write_tiny(joinpath(sd, "good.nc"))
    t["schema_conforming_strict_accepted"] = begin
        bad, nf = p1c_schema_value_check(good, "strict", tinysig, tinydims)
        isempty(bad) && isempty(nf)
    end
    t["schema_type_drift_refuses"] = begin
        p2 = write_tiny(joinpath(sd, "ty.nc"); alpha_ty = Float64)
        bad, _ = p1c_schema_value_check(p2, "strict", tinysig, tinydims)
        any(occursin("stored type", b) for b in bad)
    end
    t["schema_dim_drift_refuses"] = begin
        p2 = write_tiny(joinpath(sd, "dm.nc"); alpha_dim = "m")
        bad, _ = p1c_schema_value_check(p2, "strict", tinysig, tinydims)
        !isempty(bad)
    end
    t["schema_extra_var_refuses"] = begin
        p2 = write_tiny(joinpath(sd, "ex.nc"); extra = true)
        bad, _ = p1c_schema_value_check(p2, "strict", tinysig, tinydims)
        any(occursin("unexpected extra var", b) for b in bad)
    end
    t["schema_missing_var_refuses"] = begin
        p2 = write_tiny(joinpath(sd, "ms.nc"); drop_beta = true)
        bad, _ = p1c_schema_value_check(p2, "strict", tinysig, tinydims)
        any(occursin("var missing", b) for b in bad)
    end
    t["nonfinite_strict_refuses"] = begin
        p2 = write_tiny(joinpath(sd, "nfs.nc"); beta = [1.0, Inf, 3.0])
        bad, _ = p1c_schema_value_check(p2, "strict", tinysig, tinydims)
        any(occursin("nonfinite values in beta", b) for b in bad)
    end
    t["nonfinite_structural_recorded_not_refused"] = begin
        p2 = write_tiny(joinpath(sd, "nfr.nc"); beta = [1.0, NaN, Inf])
        bad, nf = p1c_schema_value_check(p2, "structural", tinysig, tinydims)
        isempty(bad) && nf == [("beta", 2)]
    end
    t["schema_type_drift_refuses_even_in_structural_mode"] = begin
        p2 = write_tiny(joinpath(sd, "tys.nc"); alpha_ty = Float64)
        bad, _ = p1c_schema_value_check(p2, "structural", tinysig, tinydims)
        any(occursin("stored type", b) for b in bad)
    end
    t["dims_extent_drift_refuses"] = begin
        p2 = write_tiny(joinpath(sd, "de.nc"); n_extent = 4,
                        beta = [1.0, 2.0, 3.0, 4.0])
        bad, _ = p1c_schema_value_check(p2, "strict", tinysig, tinydims)
        any(occursin("dim n != 3", b) for b in bad)
    end
    t["dims_unexpected_extra_refuses"] = begin
        p2 = write_tiny(joinpath(sd, "dx.nc"); extra_dim = true)
        bad, _ = p1c_schema_value_check(p2, "strict", tinysig, tinydims)
        any(occursin("dimension name set", b) for b in bad)
    end

    # EXACT DECIMAL token arithmetic (monitor blocker; Agent 42 items a-d)
    r(x) = p1c_decimal_to_rational(x)
    t["dec_parse_plain"] = r("2357.13") == 235713 // big(100)
    t["dec_parse_exponent_forms"] = r("1.5e+2") == 150 &&
        r("2.5e-03") == 1 // big(400) && r("1E2") == 100
    t["dec_parse_signed_zero"] = r("-0.0") == 0 && r("-0") == 0 &&
        r("0.0") == 0
    t["dec_parse_negative"] = r("-12.5") == -25 // big(2)
    t["dec_parse_garbage_nothing"] = r("nan") === nothing &&
        r("inf") === nothing && r("1.2.3") === nothing &&
        r("") === nothing
    t["dec_format_subtraction_exact_not_float64"] =
        p1c_rational_to_decimal(r("0.3") - r("0.1")) == "0.2"
    t["dec_format_terminating"] =
        p1c_rational_to_decimal(1 // big(400)) == "0.0025" &&
        p1c_rational_to_decimal(big(150) // 1) == "150" &&
        p1c_rational_to_decimal(-3 // big(1000)) == "-0.003" &&
        p1c_rational_to_decimal(big(0) // 1) == "0"
    t["dec_format_nonterminating_nothing"] =
        p1c_rational_to_decimal(1 // big(3)) === nothing
    t["dec_adjacent_17digit_tokens_exact"] = begin
        d = r("22.791293464348826") - r("22.791293464348823")
        p1c_rational_to_decimal(d) == "0.000000000000003"
    end

    # token extraction (instrument gates)
    fullline(c, g; proof = ", sizeof_Real = 8, mantissa_digits = 53, digits10 = 15, max_digits10 = 17") =
        "P1_ITER0_FULL: cost_function = $c, gradient_norm = $g" * proof
    goodlog = join(["noise",
        "Iteration 0: cost function = 2357.13, gradient norm = 1026.13",
        fullline("2357.1340000000001", "1026.1310000000001"),
        "Iteration 1: cost function = 2000.00, gradient norm = 900.000"],
        "\n")
    tokres = p1c_extract_tokens(goodlog)
    t["tokens_good_accepted"] = isempty(tokres[1]) &&
        tokres[2] !== nothing &&
        tokres[2].full_cost == "2357.1340000000001" &&
        tokres[2].rounded_cost == "2357.13"
    t["tokens_missing_full_refuses"] = !isempty(p1c_extract_tokens(
        "Iteration 0: cost function = 1.0, gradient norm = 2.0")[1])
    t["tokens_duplicate_full_refuses"] = !isempty(p1c_extract_tokens(
        goodlog * "\n" * fullline("2357.1340000000001",
                                  "1026.1310000000001"))[1])
    t["tokens_missing_rounded_refuses"] = !isempty(p1c_extract_tokens(
        fullline("1.0", "2.0"))[1])
    t["tokens_duplicate_rounded_refuses"] = !isempty(p1c_extract_tokens(
        goodlog * "\nIteration 0: cost function = 2357.13, gradient norm = 1026.13")[1])
    t["tokens_wrong_real_proof_fields_refuse"] = begin
        badlog = join(["Iteration 0: cost function = 2357.13, gradient norm = 1026.13",
            fullline("2357.1340000000001", "1026.1310000000001";
                     proof = ", sizeof_Real = 4, mantissa_digits = 24, digits10 = 6, max_digits10 = 9")],
            "\n")
        iss, _ = p1c_extract_tokens(badlog)
        any(occursin("OBSERVED Real proof fields", i) for i in iss)
    end
    t["tokens_nonfinite_refuses"] = begin
        badlog = join(["Iteration 0: cost function = nan, gradient norm = 1026.13",
                       fullline("nan", "1026.1310000000001")], "\n")
        !isempty(p1c_extract_tokens(badlog)[1])
    end
    t["tokens_roundtrip_mismatch_refuses"] = begin
        badlog = join(["Iteration 0: cost function = 2357.13, gradient norm = 1026.13",
                       fullline("2357.9990000000001", "1026.1310000000001")],
                      "\n")
        iss, _ = p1c_extract_tokens(badlog)
        any(occursin("does not round back", i) for i in iss)
    end
    t["tokens_malformed_refuses"] = !isempty(p1c_extract_tokens(
        "Iteration 0: cost function = 1.0, gradient norm = 2.0\n" *
        "P1_ITER0_FULL: garbage")[1])

    # six-probe comparison (duplicates, statuses, bridge, branches)
    mktok(fc, fg) = (full_cost = fc, full_gnorm = fg,
                     rounded_cost = @sprintf("%.6g", parse(Float64, fc)),
                     rounded_gnorm = @sprintf("%.6g", parse(Float64, fg)))
    function mkinputs(; js = "30.400000000000002", jp = "30.5",
                      status = "Maximum iterations reached")
        tok = Dict{String, Any}()
        st = Dict{String, String}()
        for w in P1C_WS
            tgt = p1c_target(w)
            fc = tgt == "init" ? "2357.1340000000001" :
                tgt == "plateau" ? jp : js
            fg = tgt == "init" ? "1026.1310000000001" : "900.5"
            tok[w] = mktok(fc, fg)
            st[w] = status
        end
        (tok, st)
    end
    t["compare_negative_branch"] = begin
        tok, st = mkinputs(js = "30.400000000000002", jp = "30.5")
        iss, out = p1c_compare(tok, st)
        isempty(iss) && any(occursin("NEGATIVE (D_reported < 0)", o)
                            for o in out)
    end
    t["compare_positive_branch"] = begin
        tok, st = mkinputs(js = "30.600000000000001", jp = "30.5")
        iss, out = p1c_compare(tok, st)
        isempty(iss) && any(occursin("POSITIVE (D_reported > 0)", o)
                            for o in out)
    end
    t["compare_zero_at_token_representation_branch"] = begin
        tok, st = mkinputs(js = "30.5", jp = "30.5")
        iss, out = p1c_compare(tok, st)
        isempty(iss) &&
            any(occursin("ZERO AT MAX_DIGITS10 TOKEN REPRESENTATION", o)
                for o in out)
    end
    t["compare_exact_decimal_delta_not_float64"] = begin
        tok, st = mkinputs(js = "22.791293464348826",
                           jp = "22.791293464348823")
        iss, out = p1c_compare(tok, st)
        isempty(iss) &&
            any(occursin("D_splice_plateau=0.000000000000003", o)
                for o in out)
    end
    t["compare_hidden_high_precision_drift_refuses"] = begin
        tok, st = mkinputs()
        tok["published-b"] = mktok("30.400000000000003", "900.5")
        iss, _ = p1c_compare(tok, st)
        any(occursin("duplicate token drift", i) for i in iss) &&
            tok["published-a"].rounded_cost ==
            tok["published-b"].rounded_cost
    end
    t["compare_status_inequality_refuses"] = begin
        tok, st = mkinputs()
        st["init-b"] = "Converged"
        iss, _ = p1c_compare(tok, st)
        any(occursin("terminal-status inequality", i) for i in iss)
    end
    t["compare_unexpected_identical_status_recorded_accepted"] = begin
        tok, st = mkinputs(status = "Bound constraints not applied")
        iss, out = p1c_compare(tok, st)
        isempty(iss) &&
            any(occursin("Bound constraints not applied", o) for o in out)
    end
    t["compare_empty_status_refuses"] = begin
        tok, st = mkinputs()
        st["plateau-a"] = ""
        st["plateau-b"] = ""
        iss, _ = p1c_compare(tok, st)
        any(occursin("status capture is empty", i) for i in iss)
    end
    t["compare_init_bridge_refuses"] = begin
        tok, st = mkinputs()
        for w in ("init-a", "init-b")
            tok[w] = mktok("9999.9899999999998", "1026.1310000000001")
        end
        iss, _ = p1c_compare(tok, st)
        any(occursin("committed bridge", i) for i in iss)
    end
    t["compare_missing_ws_refuses"] = begin
        tok, st = mkinputs()
        delete!(tok, "plateau-b")
        iss, _ = p1c_compare(tok, st)
        any(occursin("missing token record", i) for i in iss)
    end
    t["compare_never_averages"] = begin
        tok, st = mkinputs()
        tok["published-b"] = mktok("31.100000000000001", "900.5")
        iss, out = p1c_compare(tok, st)
        !isempty(iss) && isempty(out)
    end

    # splice construction + integrity (tiny synthetic states)
    tinycounts = [("composite", 5), ("h2o", 7), ("o3", 6), ("co2", 4),
                  ("ch4", 3), ("n2o", 2), ("cfc11", 1), ("cfc12", 2)]
    tinyplat = [("composite", 4), ("h2o", 5), ("o3", 3), ("co2", 2)]
    base(i) = Float32.(reshape(1:12, 4, 3)) .+ 100i
    function write_state(path, vals)
        isfile(path) && rm(path)
        NCDataset(path, "c") do ds
            ds.attrib["title"] = "tiny-p1"
            defDim(ds, "g_point", 4)
            defDim(ds, "pressure", 3)
            for (name, arr) in sort(collect(vals); by = first)
                v = defVar(ds, name, eltype(arr), ("g_point", "pressure"))
                v[:, :] = arr
            end
        end
        path
    end
    init_vals = Dict{String, Any}(p1c_coeff(g) => base(i)
                                  for (i, g) in enumerate(P1C_GASES))
    init_vals["planck_function"] = Float64.(reshape(1:12, 4, 3))
    init_vals["bound_lo"] = Float32.(zeros(4, 3))
    tinit = write_state(joinpath(sd, "tiny_init.nc"), init_vals)
    pub_vals = Dict{String, Any}()
    for (i, g) in enumerate(P1C_GASES)
        arr = copy(base(i))
        n = tinycounts[i][2]
        arr[1:n] .= arr[1:n] .+ 1
        pub_vals[p1c_coeff(g)] = arr
    end
    tpub = write_state(joinpath(sd, "tiny_pub.nc"), pub_vals)
    plat_vals = Dict{String, Any}(k => copy(v) for (k, v) in init_vals)
    for (j, (g, n)) in enumerate(tinyplat)
        arr = copy(plat_vals[p1c_coeff(g)])
        arr[1:n] .= arr[1:n] .- 1
        plat_vals[p1c_coeff(g)] = arr
    end
    tplat = write_state(joinpath(sd, "tiny_plat.nc"), plat_vals)
    tinit_sha = shaof(tinit)
    tpub_sha = shaof(tpub)
    tplat_sha = shaof(tplat)
    tspl = joinpath(sd, "tiny_splice.nc")
    biss = p1c_build_splice(tinit, tpub, tspl; init_sha = tinit_sha,
                            pub_sha = tpub_sha)
    giss, gcounts = p1c_gate_splice(tspl, tinit, tpub;
                                    pub_diff = tinycounts,
                                    init_sha = tinit_sha,
                                    pub_sha = tpub_sha)
    t["splice_build_and_gate_accepted"] = isempty(biss) && isempty(giss)
    t["splice_counts_match_pins"] =
        all(gcounts[p1c_coeff(g)] == n for (g, n) in tinycounts)
    t["splice_omitted_minor_gas_refuses"] = begin
        s7 = joinpath(sd, "tiny_splice7.nc")
        b7 = p1c_build_splice(tinit, tpub, s7;
                              gases = P1C_GASES[1:7],
                              init_sha = tinit_sha, pub_sha = tpub_sha)
        g7, _ = p1c_gate_splice(s7, tinit, tpub; pub_diff = tinycounts,
                                init_sha = tinit_sha, pub_sha = tpub_sha)
        isempty(b7) &&
            any(occursin("identical to init", i) ||
                occursin("logical typed diff set", i) for i in g7)
    end
    t["splice_extra_logical_diff_refuses"] = begin
        s9 = joinpath(sd, "tiny_splice9.nc")
        write(s9, read(tspl))
        NCDataset(s9, "a") do ds
            ds["planck_function"].var[1, 1] = 999.0
        end
        g9, _ = p1c_gate_splice(s9, tinit, tpub; pub_diff = tinycounts,
                                init_sha = tinit_sha, pub_sha = tpub_sha)
        any(occursin("logical typed diff set", i) for i in g9)
    end
    t["splice_wrong_values_refuse"] = begin
        sw = joinpath(sd, "tiny_splicew.nc")
        write(sw, read(tspl))
        NCDataset(sw, "a") do ds
            ds[p1c_coeff("co2")].var[1, 1] = 12345.0f0
        end
        gw, _ = p1c_gate_splice(sw, tinit, tpub; pub_diff = tinycounts,
                                init_sha = tinit_sha, pub_sha = tpub_sha)
        any(occursin("!= published values", i) for i in gw)
    end
    t["splice_count_pin_mismatch_refuses"] = begin
        wrong = [(g, n + (g == "o3" ? 1 : 0)) for (g, n) in tinycounts]
        gz, _ = p1c_gate_splice(tspl, tinit, tpub; pub_diff = wrong,
                                init_sha = tinit_sha, pub_sha = tpub_sha)
        any(occursin("differing-element count", i) for i in gz)
    end
    t["splice_attr_drift_refuses"] = begin
        sa = joinpath(sd, "tiny_splicea.nc")
        write(sa, read(tspl))
        NCDataset(sa, "a") do ds
            ds.attrib["title"] = "tampered"
        end
        ga, _ = p1c_gate_splice(sa, tinit, tpub; pub_diff = tinycounts,
                                init_sha = tinit_sha, pub_sha = tpub_sha)
        any(occursin("global attributes differ", i) for i in ga)
    end
    t["splice_type_mismatch_build_refuses"] = begin
        pv = Dict{String, Any}(k => copy(v) for (k, v) in pub_vals)
        pv[p1c_coeff("co2")] = Float64.(pv[p1c_coeff("co2")])
        pt = write_state(joinpath(sd, "tiny_pub_ty.nc"), pv)
        bt = p1c_build_splice(tinit, pt, joinpath(sd, "tiny_sp_ty.nc");
                              init_sha = tinit_sha, pub_sha = shaof(pt))
        any(occursin("type mismatch", i) for i in bt)
    end
    t["splice_source_sha_drift_refuses"] = begin
        bd = p1c_build_splice(tinit, tpub, joinpath(sd, "tiny_sp_sha.nc");
                              init_sha = "0"^64, pub_sha = tpub_sha)
        any(occursin("pre-open sha", i) for i in bd)
    end

    # plateau state gate (tiny)
    t["plateau_gate_accepted"] = begin
        pi_, pc = p1c_gate_plateau(tplat, tinit; plat_diff = tinyplat,
                                   init_sha = tinit_sha,
                                   plat_sha = tplat_sha)
        isempty(pi_) && all(pc[p1c_coeff(g)] == n for (g, n) in tinyplat)
    end
    t["plateau_minor_gas_diff_refuses"] = begin
        pv = Dict{String, Any}(k => copy(v) for (k, v) in plat_vals)
        arr = copy(pv[p1c_coeff("ch4")]); arr[1, 1] += 1
        pv[p1c_coeff("ch4")] = arr
        pm = write_state(joinpath(sd, "tiny_plat_m.nc"), pv)
        pi_, _ = p1c_gate_plateau(pm, tinit; plat_diff = tinyplat,
                                  init_sha = tinit_sha,
                                  plat_sha = shaof(pm))
        any(occursin("minor-gas array", i) ||
            occursin("logical diff set", i) for i in pi_)
    end
    t["plateau_count_pin_mismatch_refuses"] = begin
        wrong = [(g, n + 1) for (g, n) in tinyplat]
        pi_, _ = p1c_gate_plateau(tplat, tinit; plat_diff = wrong,
                                  init_sha = tinit_sha,
                                  plat_sha = tplat_sha)
        any(occursin("differing-element count", i) for i in pi_)
    end
    t["plateau_sha_drift_refuses"] = begin
        pi_, _ = p1c_gate_plateau(tplat, tinit; plat_diff = tinyplat,
                                  init_sha = tinit_sha,
                                  plat_sha = "0"^64)
        any(occursin("pre-open sha", i) for i in pi_)
    end

    # patch machinery (real pinned source)
    orig = read(joinpath(P1_SRC_ARTIFACT, P1_SOLVE_ADEPT_REL), String)
    t["patch_applies_plus14_lines"] =
        patch.patched_wc == patch.orig_wc + 14
    t["patch_derivation_deterministic"] = begin
        d2 = p1_patch_derivation()
        isempty(d2[1]) && d2[2] !== nothing &&
            d2[2].patched_sha == patch.patched_sha &&
            d2[2].region_sha == patch.region_sha
    end
    t["patch_missing_include_anchor_refuses"] = begin
        iss, _ = p1_apply_patch(replace(orig,
            P1_ANCHOR0 => "#include \"NotTimer.h\""))
        any(occursin("EDIT A include anchor", i) for i in iss)
    end
    t["patch_missing_report_anchor_refuses"] = begin
        iss, _ = p1_apply_patch(replace(orig,
            P1_ANCHOR2 => "\t<< \", gradient norm: \" << gnorm << \"\\n\";"))
        any(occursin("EDIT B report anchor", i) for i in iss)
    end
    t["patch_preexisting_instrument_refuses"] = begin
        iss, _ = p1_apply_patch(orig * "\n// P1_ITER0_FULL\n")
        any(occursin("already instrumented", i) for i in iss)
    end
    t["patch_rounded_line_byte_unchanged"] =
        occursin(P1_ANCHOR1 * "\n" * P1_ANCHOR2, patch.patched_text)
    t["patch_block_static_ok"] = isempty(p1_block_static_issues(P1_BLOCK_LINES))
    t["patch_block_missing_flush_refuses"] = begin
        blk = [l for l in P1_BLOCK_LINES
               if l != "      LOG << p1_full.str() << \"\\n\";"]
        any(occursin("flush form", i) for i in p1_block_static_issues(blk))
    end
    t["patch_block_payload_newline_refuses"] = begin
        blk = copy(P1_BLOCK_LINES)
        blk[5] = "              << \", gradient_norm = \\n\" << gnorm"
        any(occursin("newline inside the ostringstream payload", i)
            for i in p1_block_static_issues(blk))
    end
    t["patch_design_containment_ok"] =
        isempty(p1_design_containment_issues(design, P1_BLOCK_LINES,
                                             P1_INCLUDES))
    t["patch_design_containment_missing_line_refuses"] =
        !isempty(p1_design_containment_issues(design,
            vcat(P1_BLOCK_LINES, ["      int fake_inserted = 1;"]),
            P1_INCLUDES))
    t["patch_design_prose_mention_insufficient"] =
        !isempty(p1_design_containment_issues(
            "we mention ('#include <fake>') only in prose here",
            String[], ["#include <fake>"]))
    t["patch_design_anchors_not_required"] =
        isempty(p1_design_containment_issues(
            join(vcat(P1_INCLUDES, P1_BLOCK_LINES), '\n'),
            P1_BLOCK_LINES, P1_INCLUDES))

    # source-semantic gates (five regions)
    t["sem_derivation_ok"] = sem !== nothing &&
        isempty(p1_semantic_derivation(patch.patched_text, tree)[1])
    t["sem_algorithm_request_tamper_refuses"] = begin
        iss, _ = p1_semantic_derivation(replace(patch.patched_text,
            "MINIMIZER_ALGORITHM_LIMITED_MEMORY_BFGS" =>
            "MINIMIZER_ALGORITHM_CONJUGATE_GRADIENT"), tree)
        any(occursin("algorithm-request line", i) for i in iss)
    end
    t["sem_xprior_tamper_refuses"] = begin
        iss, _ = p1_semantic_derivation(replace(patch.patched_text,
            P1_SEM_XPRIOR_LINE => "  ckd_model.x_prior = x * 2.0;"), tree)
        any(occursin("x_prior initialization line", i) for i in iss)
    end
    t["sem_jprior_region_tamper_refuses"] = begin
        iss, _ = p1_semantic_derivation(replace(patch.patched_text,
            "J += J_prior;" => "J += J_prior + 1.0;"), tree)
        any(occursin("J_prior region end anchor", i) for i in iss)
    end
    t["sem_bgcost_region_pins_present"] = sem !== nothing &&
        occursin("Real cost_fn = 0.0;", sem.cm_text) &&
        occursin("return cost_fn;", sem.cm_text) &&
        length(collect(eachmatch(
            r"\Q0.5*dot_product(delta_x_local,gradient_local)\E",
            sem.cm_text))) == 2

    # BEHAVIORAL negatives for BOTH external source regions (monitor
    # delta B): temp copies with recomputed shas so the semantic
    # anchors/content -- not just the outer sha -- are exercised
    aslines_fx = split(read(P1_ADEPT_SOURCE_H, String), '\n';
                       keepempty = true)
    function write_adept_fx(name, mutate_line, newtext)
        ls = copy(aslines_fx)
        ls[mutate_line] = newtext
        p = joinpath(fx, name)
        write(p, join(ls, '\n'))
        p
    end
    t["sem_adept_missing_refuses"] = begin
        iss, _ = p1_semantic_derivation(patch.patched_text, tree;
            adept_path = joinpath(fx, "absent_adept.h"),
            adept_sha = "0"^64)
        any(occursin("missing pinned file", i) for i in iss)
    end
    t["sem_adept_mutated_report_refuses"] = begin
        p = write_adept_fx("adept_mut_report.h", P1_SEM_AS_END,
            "      optimizable.report_progress(n_iterations_ + 1, x, cost_function_, gradient_norm_);")
        iss, _ = p1_semantic_derivation(patch.patched_text, tree;
            adept_path = p, adept_sha = shaof(p))
        any(occursin("not the pre-step report_progress call", i)
            for i in iss)
    end
    t["sem_adept_mutated_definition_refuses"] = begin
        p = write_adept_fx("adept_mut_def.h", P1_SEM_AS_START,
            "  Minimizer::minimize_limited_memory_bfgs_renamed(Optimizable& o, Vector x)")
        iss, _ = p1_semantic_derivation(patch.patched_text, tree;
            adept_path = p, adept_sha = shaof(p))
        any(occursin("not the unbounded LBFGS definition line", i)
            for i in iss)
    end
    cmtext_fx = read(joinpath(P1_SRC_ARTIFACT, P1_SEM_CM_REL), String)
    t["sem_cm_missing_refuses"] = begin
        iss, _ = p1_semantic_derivation(patch.patched_text, tree;
            cm_path = joinpath(fx, "absent_ckd_model.cpp"),
            cm_sha = "0"^64)
        any(occursin("missing pinned file", i) for i in iss)
    end
    t["sem_cm_mutated_constant_refuses"] = begin
        p = joinpath(fx, "cm_mut_const.cpp")
        write(p, replace(cmtext_fx,
                         "Real cost_fn = 0.0;" => "Real cost_fn = 1.0;"))
        iss, _ = p1_semantic_derivation(patch.patched_text, tree;
            cm_path = p, cm_sha = shaof(p))
        any(occursin("cost_fn zero initialization", i) for i in iss)
    end
    t["sem_cm_mutated_return_refuses"] = begin
        p = joinpath(fx, "cm_mut_return.cpp")
        write(p, replace(cmtext_fx,
                         "return cost_fn;" => "return cost_fn + 1.0;"))
        iss, _ = p1_semantic_derivation(patch.patched_text, tree;
            cm_path = p, cm_sha = shaof(p))
        any(occursin("return anchor missing", i) for i in iss)
    end
    t["sem_cm_mutated_quadratic_refuses"] = begin
        p = joinpath(fx, "cm_mut_quad.cpp")
        write(p, replace(cmtext_fx,
            "cost_fn += 0.5*dot_product(delta_x_local,gradient_local);" =>
            "cost_fn += 0.5;"))
        iss, _ = p1_semantic_derivation(patch.patched_text, tree;
            cm_path = p, cm_sha = shaof(p))
        any(occursin("quadratic delta_x contributions", i) for i in iss)
    end

    # prerequisite-ledger classifier
    cls(p; kw...) = p1_classify_ledger(p;
        expected_case = P1_LEDGERS[4].case,
        expected_status = P1_LEDGERS[4].status,
        expected_sha = P1_LEDGERS[4].sha, kw...)
    t["ledger_missing_refuses"] =
        cls(joinpath(fx, "absent.json")).class == "missing"
    pth = joinpath(fx, "bad.json"); write(pth, "{oops")
    t["ledger_unparseable_refuses"] =
        cls(pth; expected_sha = shaof(pth)).class ==
        "unparseable (parse failure)"
    pth = joinpath(fx, "st.json")
    write(pth, JSON.json(Dict("case" => P1_LEDGERS[4].case,
                              "status" => "c1_completion_ledger_refused")))
    t["ledger_status_mismatch_refuses"] =
        cls(pth; expected_sha = shaof(pth)).class == "status mismatch"
    pth = joinpath(fx, "green.json")
    write(pth, JSON.json(Dict("case" => P1_LEDGERS[4].case,
                              "status" => P1_LEDGERS[4].status)))
    t["ledger_sha_drift_refuses"] =
        cls(pth; expected_sha = "0"^64).class == "sha drift"
    t["ledger_green_accepted"] = cls(pth; expected_sha = shaof(pth)).ok

    # artifact tree
    t["tree_census_119"] = length(tree) == P1_TREE_FILES
    t["tree_exec_census_24"] = count(e -> e.exec, tree) == P1_TREE_EXEC

    # probe injection derivation (authority: the pinned script)
    script = read("$P1_SRC_ARTIFACT/test/optimize_lut_lw.sh", String)
    inj_iss, injected = p1_derive_injected(script)
    t["inject_derives"] = isempty(inj_iss) && injected !== nothing
    if injected !== nothing
        t["inject_flag_exactly_once"] =
            count(==("\t    bounded_minimization=0 \\"),
                  split(injected, '\n')) == 1
        t["inject_iteration_exactly_once"] =
            count(==("\t    max_iterations=1 \\"),
                  split(injected, '\n')) == 1
    end
    t["inject_missing_anchor_refuses"] =
        !isempty(p1_derive_injected(replace(script,
            "model_id=lw_\${APPLICATION}_\${BANDSTRUCT}-tol\${TOL} \\" =>
            "model_id=other \\"))[1])
    t["inject_preexisting_flag_refuses"] =
        !isempty(p1_derive_injected(script *
                                    "\nbounded_minimization=1\n")[1])

    # sbatch text gates
    text = p1_make_sbatch(tree, patch, sem)
    tg(x) = p1_text_gate_issues(x, patch, sem)
    t["text_good_accepted"] = isempty(tg(text))
    t["text_design_pin_drift_refuses"] =
        !isempty(tg(replace(text, P1_DESIGN_SHA => "0"^64)))
    t["text_ledger_pin_drift_refuses"] =
        !isempty(tg(replace(text, P1_LEDGERS[4].sha => "0"^64)))
    t["text_b0_ledger_pin_drift_refuses"] =
        !isempty(tg(replace(text, P1_LEDGERS[1].sha => "0"^64)))
    t["text_init_pin_drift_refuses"] =
        !isempty(tg(replace(text, P1_INIT_SHA => "0"^64)))
    t["text_plateau_pin_drift_refuses"] =
        !isempty(tg(replace(text, P1_PLATEAU_SHA => "0"^64)))
    t["text_published_pin_drift_refuses"] =
        !isempty(tg(replace(text, P1_PUB_SHA => "0"^64)))
    t["text_patched_sha_tamper_refuses"] =
        !isempty(tg(replace(text, patch.patched_sha => "0"^64)))
    t["text_region_sha_tamper_refuses"] =
        !isempty(tg(replace(text, patch.region_sha => "0"^64)))
    t["text_semantic_region_tamper_refuses"] =
        !isempty(tg(replace(text, sem.cm_region_sha => "0"^64)))
    t["text_missing_flush_census_refuses"] = !isempty(tg(replace(text,
        "REFUSED: census: const-char literal-newline flush form not exactly once" =>
        "note")))
    t["text_missing_proof_fields_gate_refuses"] = !isempty(tg(replace(text,
        "REFUSED: \$ws token extraction/instrument gate failed (exactly-once, proof fields, finite, 6-sig-fig round-back)" =>
        "note")))
    t["text_missing_unbounded_gate_refuses"] = !isempty(tg(replace(text,
        "REFUSED: \$ws did not log unbounded mode (probe mode gate)" =>
        "note")))
    t["text_bounded_leak_gate_removed_refuses"] = !isempty(tg(replace(text,
        "REFUSED: \$ws logged bounded mode (bounded-mode leak)" => "note")))
    t["text_missing_injection_gate_refuses"] = !isempty(tg(replace(text,
        "REFUSED: \$ws flag injection not exactly once" => "note")))
    t["text_missing_status_nonempty_gate_refuses"] = !isempty(tg(replace(
        text, "REFUSED: \$ws terminal status capture is empty" => "note")))
    t["text_allowlist_reintroduced_refuses"] = !isempty(tg(text *
        "\n[ x ] || { echo 'status outside the allowed set'; exit 71; }\n"))
    t["text_missing_compare_gate_refuses"] = !isempty(tg(replace(text,
        "REFUSED: six-probe duplicate/bridge/delta gates failed (drift recorded; branch assignment refused; values never averaged)" =>
        "note")))
    t["text_missing_splice_gate_refuses"] = !isempty(tg(replace(text,
        "REFUSED: splice integrity gate failed (exact eight-variable typed diff / published equality / pinned counts / attrs / signature)" =>
        "note")))
    t["text_missing_plateau_gate_refuses"] = !isempty(tg(replace(text,
        "REFUSED: plateau state gate failed (four-active pinned counts / minor-four exact equality / signature)" =>
        "note")))
    t["text_missing_structural_scan_refuses"] = !isempty(tg(replace(text,
        "REFUSED: \$ws one-step output failed STRUCTURAL verification (structure faults refuse; nonfinite values never do)" =>
        "note")))
    t["text_missing_poststage_refuses"] = !isempty(tg(replace(text,
        "REFUSED: staged per-workspace scientific input drifted during the runs (target-defining input mutation)" =>
        "note")))
    t["text_missing_binary_gate_refuses"] = !isempty(tg(replace(text,
        "REFUSED: immutable binary content drift before probe \$ws" =>
        "note")))
    t["text_julia_version_pin_drift_refuses"] = !isempty(tg(replace(text,
        P1_JULIA_VERSION_LINE => "julia version 1.13.0")))
    t["text_missing_manifest_pin_refuses"] = !isempty(tg(replace(text,
        "$(p1_sha(P1_TEST_MANIFEST))  $P1_TEST_MANIFEST" => "")))
    t["text_missing_quota_refuses"] = !isempty(tg(replace(text,
        "quota_health \$((50*1024*1024*1024))" => "true")))
    t["text_missing_data_lock_refuses"] = !isempty(tg(replace(text,
        "chmod -R a-w \"\$RUNROOT/data\"" => "true")))
    t["text_capture_machinery_refuses"] =
        !isempty(tg(text * "\nexport GATE4_X1_CAPTURE_PATH=x\n"))
    t["text_publish_machinery_refuses"] =
        !isempty(tg(text * "\nmv -n -- x \$CANON_FINAL\n"))
    t["text_shared_redirect_refuses"] =
        !isempty(tg(text * "\necho x > \"\$G4WORK/work/evil.txt\"\n"))
    t["text_head_pipeline_refuses"] =
        !isempty(tg(text * "\nfoo --version | head -1\n"))
    t["text_strings_absence_refuses"] = !isempty(tg(text *
        "\n[ \"\$(strings x | grep -cF 'Adept LBFGS' || true)\" = 0 ] || exit 99\n"))
    t["text_stale_language_two_probes_refuses"] =
        !isempty(tg(text * "\n# two probes per target\n"))
    t["text_stale_language_floor_refuses"] =
        !isempty(tg(text * "\n# published floor\n"))
    t["text_stale_language_bit_exact_refuses"] =
        !isempty(tg(text * "\n# bit-exact\n"))
    t["text_extra_pass_refuses"] = !isempty(tg(replace(text,
        "bash optimize_lut_lw.sh relative-base" =>
        "bash optimize_lut_lw.sh relative-base relative-ch4")))
    t["text_ws_loop_count_drift_refuses"] = begin
        ws_loop = "for ws in $P1_WS_LIST; do"
        !isempty(tg(text * "\n" * ws_loop * " :; done\n"))
    end
    t["text_iteration_token_drift_refuses"] =
        !isempty(tg(text * "\n# max_iterations=1 stray token\n"))
    t["text_live_project_env_refuses"] = !isempty(tg(replace(text,
        "--project=\"\$JENV\" \"\$CHECKER\" compare" =>
        "--project=test \"\$CHECKER\" compare")))
    t["text_live_repo_cd_refuses"] = !isempty(tg(text *
        "\n( cd $P1_PROJECT_ROOT && \"\$JULIA_BIN\" --project=\"\$JENV\" \"\$CHECKER\" compare \"\$RUNROOT\" )\n"))
    t["text_canonical_g4work_checker_arg_refuses"] = !isempty(tg(text *
        "\n\"\$JULIA_BIN\" --project=\"\$JENV\" \"\$CHECKER\" build-splice \"$P1_INIT_PATH\" \"\$MP\" x\n"))
    t["text_canonical_artifact_checker_arg_refuses"] = !isempty(tg(text *
        "\n\"\$JULIA_BIN\" --project=\"\$JENV\" \"\$CHECKER\" gate-splice x \"\$MI\" \"$P1_PUB_PATH\"\n"))
    t["text_missing_init_master_row_refuses"] = !isempty(tg(replace(text,
        "$P1_INIT_SHA $P1_INIT_BYTES $P1_INIT_PATH \$RUNROOT/source-inputs/init.nc" =>
        "")))
    t["text_missing_masters_lock_refuses"] = !isempty(tg(replace(text,
        "chmod -R a-w \"\$RUNROOT/source-inputs\" \"\$RUNROOT/julia-env\"" =>
        "true")))
    t["text_missing_env_pin_refuses"] = !isempty(tg(replace(text,
        "REFUSED: julia-env staged copy hash mismatch" => "note")))
    t["text_missing_master_size_reverify_refuses"] = !isempty(tg(replace(
        text,
        "REFUSED: staged master/env size drifted during the runs" =>
        "note")))
    t["text_canonical_shim_in_wrapper_refuses"] = !isempty(tg(replace(text,
        "export LD_PRELOAD=\"$P1_NETLIB_BLAS:$P1_NETLIB_LAPACK:\$SHIM\"" =>
        "export LD_PRELOAD=\"$P1_NETLIB_BLAS:$P1_NETLIB_LAPACK:$P1_SHIM_SO\"")))
    t["text_missing_staged_shim_reverify_refuses"] = !isempty(tg(replace(
        text, "REFUSED: staged shim drifted during the runs" => "note")))
    t["text_missing_template_post_reverify_refuses"] = !isempty(tg(replace(
        text,
        "REFUSED: frozen test-template drifted during the runs" => "note")))
    t["text_duplicate_configure_refuses"] =
        !isempty(tg(text * "\n" * P1_CONFIGURE_ARGV * "\n"))
    t["text_ladept_inside_ldflags_refuses"] = !isempty(tg(replace(text,
        "'LDFLAGS=-L$P1_ADEPT/lib -Wl,-rpath,$P1_ADEPT/lib'" =>
        "'LDFLAGS=-L$P1_ADEPT/lib -ladept'")))
    t["bash_syntax_good_accepted"] = p1_bash_syntax_ok(text)
    t["bash_syntax_broken_refuses"] =
        !p1_bash_syntax_ok(text * "\nif true; then\n")

    # frozen-design prose guards (ceiling + token semantics + order +
    # status policy + eight-array pins)
    ceiling = p1_ceiling_extract(design)
    t["design_ceiling_extractable"] = ceiling !== nothing
    t["design_ceiling_phrases"] = ceiling !== nothing &&
        occursin("NOT recovered acceptance", ceiling) &&
        occursin("NOT a floor claim", ceiling) &&
        occursin("OPEN and UNRANKED globally", ceiling) &&
        occursin("LOCAL to this rebuilt trajectory", ceiling)
    t["design_token_semantics"] =
        occursin("EXACT TEXTUAL EQUALITY", design) &&
        occursin("never averaged", design) &&
        occursin("max_digits10", design)
    t["design_symmetric_order"] = occursin(
        "init-a / published-a / plateau-a / plateau-b / published-b / init-b",
        design)
    t["design_status_policy_recorded_not_gated"] =
        occursin("allowlist not applied to probes", design)
    t["design_eight_array_counts"] =
        occursin("composite 9686/10176", design) &&
        occursin("h2o 121016/122112", design) &&
        occursin("composite 9677, h2o 121461, o3 9997, co2 9641", design)
    t["design_unbounded_all_six"] =
        occursin("ALL SIX probes run UNBOUNDED", design)
    t
end

# --- main -----------------------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()
    groups = Dict{String, Vector{String}}()
    function finish(status_word)
        for (k, v) in groups
            gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
            isempty(v) || append!(fails, ["$k: " * i for i in v])
        end
        println("gate4_p1_checkpoint: $status_word")
        isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
        1
    end

    tree = p1_tree_manifest()
    piss, patch = p1_patch_derivation()
    groups["patch_derivation"] = piss
    patch === nothing && return finish("p1_checkpoint_refused (patch derivation)")
    siss, sem = p1_semantic_derivation(patch.patched_text, tree)
    groups["semantic_gates"] = siss
    sem === nothing && return finish("p1_checkpoint_refused (semantic gates)")

    # pinned-init sole signature authority; plateau must carry the
    # identical signature + dims (usable as a raw-definition input)
    sg = String[]
    i1, sd_init = p1c_bracketed(P1_INIT_PATH, P1_INIT_SHA) do
        p1c_signature_and_dims(P1_INIT_PATH)
    end
    append!(sg, i1)
    i2, sd_plat = p1c_bracketed(P1_PLATEAU_PATH, P1_PLATEAU_SHA) do
        p1c_signature_and_dims(P1_PLATEAU_PATH)
    end
    append!(sg, i2)
    if sd_init !== nothing && sd_plat !== nothing
        sd_init == sd_plat ||
            push!(sg, "pinned init signature/dims != plateau raw2 signature/dims")
        length(sd_init[1]) == 47 ||
            push!(sg, "signature entry count $(length(sd_init[1])) != 47")
        length(sd_init[2]) == 8 ||
            push!(sg, "dimension map count $(length(sd_init[2])) != 8")
    end
    groups["schema_signature"] = sg
    (sd_init === nothing || !isempty(sg)) &&
        return finish("p1_checkpoint_refused (schema signature)")

    # REAL three-state verification at generation (private temp splice)
    sp = String[]
    spl = joinpath(mktempdir(), "splice_preview.nc")
    append!(sp, p1c_build_splice(P1_INIT_PATH, P1_PUB_PATH, spl))
    real_counts = Dict{String, Int}()
    if isempty(sp)
        gs, real_counts = p1c_gate_splice(spl, P1_INIT_PATH, P1_PUB_PATH)
        append!(sp, gs)
    end
    pg, plat_counts = p1c_gate_plateau(P1_PLATEAU_PATH, P1_INIT_PATH)
    append!(sp, pg)
    groups["real_state_gates"] = sp

    design = isfile(P1_DESIGN_FILE) ? read(P1_DESIGN_FILE, String) : ""
    dd = String[]
    if isfile(P1_DESIGN_FILE)
        dsha = p1_sha(P1_DESIGN_FILE)
        dsha == P1_DESIGN_SHA ||
            push!(dd, "durable frozen-design file sha $dsha != $P1_DESIGN_SHA")
    else
        push!(dd, "durable frozen-design file missing: $P1_DESIGN_FILE")
    end
    ceiling = p1_ceiling_extract(design)
    ceiling === nothing &&
        push!(dd, "conclusion ceiling not extractable from the frozen design")
    append!(dd, p1_design_containment_issues(design, P1_BLOCK_LINES,
                                             P1_INCLUDES))
    groups["frozen_design_file"] = dd

    for l in P1_LEDGERS
        led = p1_classify_ledger(l.path; expected_case = l.case,
                                 expected_status = l.status,
                                 expected_sha = l.sha)
        groups["ledger_$(l.name)"] = led.ok ? String[] : [led.reason]
    end
    lc = String[]
    for l in P1_LEDGERS
        commit = try
            strip(read(`git -C $P1_PROJECT_ROOT log -n1 --format=%H --
                        $(relpath(l.path, P1_PROJECT_ROOT))`, String))
        catch
            "unreadable"
        end
        commit == l.commit ||
            push!(lc, "$(l.name) ledger last-touching commit $commit != pinned $(l.commit)")
    end
    groups["ledger_commit_pins"] = lc

    ck = String[]
    isfile(P1_CHECKER_FILE) ||
        push!(ck, "shared checker file missing: $P1_CHECKER_FILE")
    groups["checker_file"] = ck

    src = String[]
    length(tree) == P1_TREE_FILES ||
        push!(src, "artifact tree census $(length(tree)) != $P1_TREE_FILES")
    count(e -> e.exec, tree) == P1_TREE_EXEC ||
        push!(src, "artifact exec census != $P1_TREE_EXEC")
    for (sha, sz, path) in P1_V12_TEST_PINS
        isfile(path) || (push!(src, "test file missing: $path"); continue)
        filesize(path) == sz || push!(src, "test size drift: $path")
        p1_try_sha(path) == sha || push!(src, "test sha drift: $path")
    end
    groups["modern_source_pins"] = src

    ad = String[]
    p1_try_sha(P1_MINIMIZER_H) == P1_MINIMIZER_H_SHA ||
        push!(ad, "installed Minimizer.h sha drift")
    p1_try_sha(P1_LIBADEPT) == P1_LIBADEPT_SHA ||
        push!(ad, "installed libadept.so.0.0.0 sha drift")
    p1_try_sha(P1_ADEPT_SOURCE_H) == P1_ADEPT_SOURCE_H_SHA ||
        push!(ad, "installed adept_source.h sha drift")
    p1_try_sha(P1_LOGGING_H) == P1_LOGGING_H_SHA ||
        push!(ad, "in-tree Logging.h sha drift")
    isdir(joinpath(P1_NETCDF, "lib")) || push!(ad, "netcdf stack missing")
    groups["adept_toolchain_pins"] = ad

    tc = String[]
    for (t_, p_, l1) in P1_TOOLCHAIN
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
    jl1 = try
        first(split(read(`$P1_JULIA_BIN --version`, String), '\n'))
    catch
        "unreadable"
    end
    jl1 == P1_JULIA_VERSION_LINE ||
        push!(tc, "julia version line drift: $jl1")
    isfile(P1_TEST_PROJECT) || push!(tc, "test/Project.toml missing")
    isfile(P1_TEST_MANIFEST) || push!(tc, "test/Manifest.toml missing")
    groups["toolchain_fingerprints"] = tc

    inp = String[]
    for (sha, sz, path) in vcat(P1_DATA_INPUTS,
        [(P1_LBL_INPUT[1], P1_LBL_INPUT[2], P1_LBL_INPUT[3]),
         (P1_INIT_SHA, P1_INIT_BYTES, P1_INIT_PATH),
         (P1_GPOINTS_INPUT[1], P1_GPOINTS_INPUT[2], P1_GPOINTS_INPUT[3]),
         (P1_PLATEAU_SHA, P1_PLATEAU_BYTES, P1_PLATEAU_PATH),
         (P1_PUB_SHA, P1_PUB_BYTES, P1_PUB_PATH)])
        isfile(path) || (push!(inp, "missing: $path"); continue)
        filesize(path) == sz || push!(inp, "size drift: $path")
        p1_try_sha(path) == sha || push!(inp, "sha drift: $path")
    end
    groups["input_pins"] = inp

    rt = String[]
    for (path, sha, label) in ((P1_NETLIB_BLAS, P1_NETLIB_BLAS_SHA, "netlib blas"),
                               (P1_NETLIB_LAPACK, P1_NETLIB_LAPACK_SHA, "netlib lapack"),
                               (P1_SHIM_SO, P1_SHIM_SO_SHA, "h5 shim"))
        p1_try_sha(path) == sha || push!(rt, "$label pin mismatch: $path")
    end
    groups["runtime_pins"] = rt

    tests = p1_fixtures(tree, patch, sem, design)
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    text = p1_make_sbatch(tree, patch, sem)
    groups["sbatch_deterministic_render"] =
        text == p1_make_sbatch(tree, patch, sem) ? String[] :
        ["sbatch render is not deterministic"]
    groups["sbatch_text_gates"] = p1_text_gate_issues(text, patch, sem)
    groups["sbatch_bash_syntax"] = p1_bash_syntax_ok(text) ? String[] :
        ["generated sbatch fails bash -n syntax verification"]

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end
    ready = gates["fixtures"] == "passed" && all(isempty, values(groups))
    status = ready ? "p1_checkpoint_ready" : "p1_checkpoint_refused"
    if ready
        mkpath(dirname(P1_SBATCH))
        write(P1_SBATCH, text)
    end
    sb_sha = ready ? p1_sha(P1_SBATCH) : nothing

    result = Dict(
        "case" => "gate4_p1_checkpoint",
        "data_mode" => "generator_checkpoint",
        "status" => status,
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "fixture_count" => length(tests),
        "sbatch_path" => P1_SBATCH,
        "sbatch_sha256" => sb_sha,
        "frozen_design" => Dict(
            "sha256" => P1_DESIGN_SHA,
            "durable_file" => P1_DESIGN_REPO_PATH,
            "authority" => "rev6 Gate-4 LW recovery decision document " *
                "(design authority for P1; monitor + Agent 42 joint APPROVE)",
            "verbatim_text" => design),
        "conclusion_ceiling_verbatim" => ceiling,
        "design" => "SIX independent cloned-workspace UNBOUNDED " *
            "1-iteration probes (bounded_minimization=0 + " *
            "max_iterations=1; C1-proven anchored injection) from ONE " *
            "saved immutable REPORTING-ONLY instrumented binary, order " *
            "init-a/published-a/plateau-a/plateau-b/published-b/init-b. " *
            "Three pinned input states: pinned init, pinned plateau " *
            "raw2 staged AT the raw-definition input name, and a " *
            "PRIVATE in-job published coefficient-block splice (all " *
            "eight gas coefficient arrays replaced; exact " *
            "eight-variable typed diff gated; never canonical, never " *
            "called the published model). J0_reported max_digits10 " *
            "token semantics with EXACT DECIMAL token-derived deltas " *
            "and the sign partition; duplicate gates are exact textual " *
            "equality; probe statuses recorded (nonempty + per-target " *
            "equality; NO membership allowlist per the frozen design). " *
            "Serialized one-step outputs are structural evidence only. " *
            "Zero canonical writes; RUNROOT preserved; submission only " *
            "on explicit monitor GO.",
        "patch" => Dict(
            "orig_sha256" => patch.orig_sha,
            "patched_sha256" => patch.patched_sha,
            "region_sha256" => patch.region_sha,
            "orig_lines" => patch.orig_wc,
            "patched_lines" => patch.patched_wc,
            "includes" => P1_INCLUDES,
            "block_lines" => P1_BLOCK_LINES,
            "anchors" => Dict("edit_a" => P1_ANCHOR0,
                              "edit_b_line1" => P1_ANCHOR1,
                              "edit_b_line2" => P1_ANCHOR2),
            "design_containment" => "inserted text only (includes + " *
                "block, stripped-line verbatim); anchors are gated via " *
                "the source-pin/uniqueness/byte-preservation chain " *
                "(monitor ruling)"),
        "semantic_gates" => Dict(
            "jprior_region" => Dict("patched_lines" =>
                "$(sem.jprior_start)-$(sem.jprior_end)",
                "sha256" => sem.jprior_sha),
            "xprior_init_line" => P1_SEM_XPRIOR_LINE,
            "algorithm_request_line" => P1_SEM_ALG_LINE,
            "unbounded_lbfgs_region" => Dict(
                "adept_source_lines" => "$P1_SEM_AS_START-$P1_SEM_AS_END",
                "sha256" => sem.as_region_sha),
            "background_cost_region" => Dict(
                "ckd_model_lines" => "$(sem.cm_start)-$(sem.cm_end)",
                "sha256" => sem.cm_region_sha),
            "semantics" => "five-region set (monitor + Agent 42): " *
                "J_prior callback, x_prior init, algorithm request, " *
                "unbounded LBFGS pre-step report, and " *
                "calc_background_cost_function no-constant semantics; " *
                "J_prior == 0 at iteration 0 is source-proven for both " *
                "prior branches; the completion ledger source-cites " *
                "these gates before any interpretation"),
        "input_states" => Dict(
            "init" => Dict("sha256" => P1_INIT_SHA,
                           "bytes" => P1_INIT_BYTES, "path" => P1_INIT_PATH),
            "plateau" => Dict("sha256" => P1_PLATEAU_SHA,
                              "bytes" => P1_PLATEAU_BYTES,
                              "path" => P1_PLATEAU_PATH,
                              "staged_as" => P1_RAWDEF_BASENAME),
            "published" => Dict("sha256" => P1_PUB_SHA,
                                "bytes" => P1_PUB_BYTES,
                                "path" => P1_PUB_PATH),
            "splice_eight_gas_diff_counts_vs_init" => real_counts,
            "plateau_four_active_diff_counts_vs_init" => plat_counts,
            "splice_semantics" => "private in-job temp state; pinned " *
                "init bytes with the eight published coefficient arrays " *
                "spliced in; everything else (incl. min/max bounds, " *
                "planck_function, gpoint_fraction, dims, attrs) held " *
                "from init; a coefficient block under this fixed " *
                "spectral mapping, never a published parameter state"),
        "token_semantics" => Dict(
            "reported" => "J0_reported = max_digits10 round-trip tokens " *
                "of the represented Real values; ordinary rounded line " *
                "kept byte-unchanged; proof fields " *
                "sizeof_Real/mantissa_digits/digits10/max_digits10 " *
                "(expectations 8/53/15/17 informational; observed binding)",
            "duplicates" => "exact textual token equality per target; " *
                "mismatch = recorded drift + branch-assignment refusal; " *
                "values never averaged",
            "deltas" => "EXACT DECIMAL arithmetic on the tokens " *
                "(Rational{BigInt}; canonical terminating decimals); " *
                "sign partition negative / zero-at-token-representation " *
                "/ positive on D_splice_plateau; formulas Js-Jp, Js-Ji, " *
                "Jp-Ji",
            "bridge" => "init ordinary tokens must equal the committed " *
                "2357.13/1026.13; each full token must round back to " *
                "its ordinary token at 6 significant figures",
            "statuses" => "recorded observations; nonempty capture; " *
                "per-target a/b exact equality; NO membership allowlist " *
                "(frozen rev6 section 5; monitor ruling supersedes the " *
                "C1-era pattern)"),
        "prerequisites" => [Dict("ledger" => l.name, "path" => l.path,
                                 "required_case" => l.case,
                                 "required_status" => l.status,
                                 "reviewed_sha256" => l.sha,
                                 "pinned_commit" => l.commit)
                            for l in P1_LEDGERS],
        "gate_instrument_provenance" => Dict(
            "checker" => P1_CHECKER_REPO_PATH,
            "checker_sha256" => p1_sha(P1_CHECKER_FILE),
            "julia" => P1_JULIA_BIN,
            "julia_version_line" => P1_JULIA_VERSION_LINE,
            "julia_version_gate" => "in-job exact --version string " *
                "(binding; the pinned path is a juliaup launcher, so " *
                "the runtime check is the gate, not the path)",
            "test_project_sha256" => p1_sha(P1_TEST_PROJECT),
            "test_manifest_sha256" => p1_sha(P1_TEST_MANIFEST)),
        "source_tree" => Dict(
            "artifact" => P1_SRC_ARTIFACT,
            "files" => P1_TREE_FILES,
            "executables" => P1_TREE_EXEC,
            "symlinks" => 0,
            "manifest_sha256" => p1_manifest_hash(tree),
            "solve_adept_orig_sha256" => P1_SOLVE_ADEPT_SHA),
        "toolchain" => Dict(
            "configure_argv" => P1_CONFIGURE_ARGV,
            "fingerprints" => [Dict("tool" => t_, "path" => p_,
                                    "version_line" => l1)
                               for (t_, p_, l1) in P1_TOOLCHAIN],
            "automake" => P1_AUTOMAKE_VER,
            "libtoolize" => P1_LIBTOOLIZE_VER),
        "provenance" => Dict(
            "generation_dir" => abspath(string(@__DIR__)),
            "generated_in_canonical_location" =>
                abspath(string(@__DIR__)) == abspath(P1_CANONICAL_DIR),
            "note" => P1_REPRO_NOTE),
        "contract_notes" => [
            "probe-status allowlist REMOVED per monitor ruling (frozen " *
                "rev6 section 5 governs; statuses recorded, nonempty, " *
                "per-target equal)",
            "token deltas computed by exact decimal arithmetic " *
                "(monitor blocker; Float64 subtraction banned)",
            "design containment restricted to inserted patch text " *
                "(monitor ruling; anchors via source-pin chain)",
            "five-region source-semantic gate set (monitor blockers + " *
                "Agent 42 refinement + fifth-region correction)",
            "immutable binary content-gated before every probe and " *
                "post-run; all staged per-workspace inputs re-verified " *
                "post-run (no-mutation evidence)",
            "julia gate-instrument provenance pinned (path + exact " *
                "version string + test env shas)",
            "TOCTOU closure (monitor delta A; Agent 42 combined HOLD): " *
                "immutable RUNROOT source-input masters + julia-env; " *
                "all six checker calls use the staged env with no " *
                "live-repo cd; state gates read staged masters only; " *
                "post-run size+sha reverify of masters/env/checker",
            "same-class closures (Agent 42 2a/2b, monitor amendment): " *
                "user-writable FP-trap shim staged immutable into the " *
                "RUNROOT and preloaded ONLY from the staged copy " *
                "(root-owned Netlib BLAS/LAPACK deliberately canonical); " *
                "frozen test-template pins re-verified post-run",
            "behavioral semantic negatives (monitor delta B): " *
                "p1_semantic_derivation parameterized for fixture " *
                "paths/shas only; mutated/missing adept_source.h and " *
                "ckd_model.cpp temp copies exercise the read/derivation " *
                "anchor gates directly"],
        "post_terminal_requirements" => [
            "completion ledger applying the preregistered rev6 outcome " *
                "matrix mechanically (sign partition on the " *
                "duplicate-confirmed token-derived deltas), " *
                "source-citing the five semantic gates, carrying the " *
                "P1 ceiling verbatim and fixture-guarded, dual-custody " *
                "receipts, and the linkage paragraph to the " *
                "unevaluated-gates document; NOT in-job"],
        "non_authorizing_note" => "this checkpoint generates and " *
            "verifies the P1 sbatch; it never submits; submission " *
            "requires explicit monitor GO.",
        "disclaimer" => "generator checkpoint; writes nothing except " *
            "its own JSON/MD results and the generated sbatch plus " *
            "transient private temp fixtures (mktempdir).")

    mkpath(dirname(P1_RESULTS_JSON))
    open(P1_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(P1_RESULTS_MD, "w") do io
        println(io, "# Gate-4 P1 published coefficient-block internal-cost probe checkpoint\n")
        println(io, "Status: **$status**\n")
        println(io, result["design"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nFrozen design (rev6, authority): `$P1_DESIGN_SHA` " *
                    "(durable file `$P1_DESIGN_REPO_PATH`)")
        println(io, "\nGenerated sbatch: `$P1_SBATCH`" *
                    (sb_sha === nothing ? " (NOT written; refused)" :
                     " sha256 `$sb_sha`"))
        println(io, "\nPatch: orig `$(patch.orig_sha)` -> patched " *
                    "`$(patch.patched_sha)`; region `$(patch.region_sha)`")
        println(io, "\nPrerequisites (fail-closed, sha-chained): " *
                    join(["$(l.name) `$(l.sha)`" for l in P1_LEDGERS],
                         ", "))
        println(io, "\nFixtures: $(length(tests)) " *
                    "($(count(values(tests))) passed)")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_p1_checkpoint: $status")
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
