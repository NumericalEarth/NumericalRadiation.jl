# Gate-4 C1 BOUNDED-MINIMIZATION FLAG-FACTOR CHECKPOINT (generator;
# writes ONLY its own JSON/MD results + the generated sbatch).
#
# FROZEN DESIGN (monitor FINAL APPROVE + Agent 42 APPROVE):
# gate4_c1_frozen_design.md sha256
# 60f55abec74287a9aaec62070bbd393420de16dd10042fa63fbb5094a3ffa888.
#
# DESIGN (frozen; binding highlights):
#   - CONFIG-ONLY one-factor experiment: identical modern pinned
#     source/build/config/input/OMP stack as X1 (job 4561); the ONLY
#     factor is the command-line override `bounded_minimization=0`
#     (key read at optimize_lut.cpp:148-149; compiled default true).
#   - TRIPLE-ARM SAME-BINARY SANDWICH: one build, ONE saved immutable
#     binary shared by all arms; run order PROBE -> C0a -> C1 -> C0b.
#     The 1-iteration UNBOUNDED PROBE (bounded_minimization=0 +
#     max_iterations=1) proves the flag's literal semantics cheaply;
#     probe outputs are STRUCTURAL evidence only.
#   - PRISTINE BINARY IN ALL ARMS; no capture instrument, no sidecar;
#     the unbounded path has the same possible callback-state lag
#     semantics; the returned solution is UNOBSERVED by design;
#     Axis-A/B/C language does not apply to C1.
#   - TWO-TIER VALUE POLICY: STRUCTURE failures refuse everywhere;
#     NONFINITE VALUES in the probe/C1 raw2 are a LAWFUL outcome of
#     removing bounds -- recorded per-variable, never a job refusal.
#     The strict all-finite verification applies to C0a/C0b ONLY.
#   - INTERNAL validity (ledger matter): C0a-vs-C0b logical identity
#     AND terminal-status exact equality; measured INSIDE the job;
#     SEPARATE from the historical bridge to the 4561 pristine raw2.
#     In-job byte-compare lines are informational echoes, NON-gating.
#   - C1 discriminates NO mechanism (flag removal disables the bounded
#     solver path AND the log-space bound construction simultaneously)
#     and repairs NOTHING; the C1 census is a POST-HOC
#     serialized-output census (ledger matter, conditional).
#   - Zero canonical writes; RUNROOT preserved on success AND failure.
#
# PREREQUISITE (fail-closed): the reviewed committed X1 completion
# ledger (commit 4a3be7a596a3be1e4391c767f23de1f163e227f7).
#
# SUBMISSION IS HELD for monitor review: this generator only produces
# the sbatch + evidence; it never submits.

const C1_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
include(joinpath(C1_PROJECT_ROOT, "validation", "validation_results.jl"))

import JSON
using SHA: sha256
using NCDatasets

const C1_G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const C1_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"
const C1_CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"

# --- frozen design pin (durable sibling file) --------------------------------------
const C1_DESIGN_SHA = "60f55abec74287a9aaec62070bbd393420de16dd10042fa63fbb5094a3ffa888"
const C1_DESIGN_FILE = joinpath(@__DIR__, "gate4_c1_frozen_design.md")
const C1_DESIGN_REPO_PATH = "validation/gate4_c1_frozen_design.md"

# --- pinned modern (v1.2) ecckd source artifact ------------------------------------
const C1_SRC_ARTIFACT = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"
const C1_TREE_FILES = 119
const C1_TREE_EXEC = 24

# --- toolchain / build recipe (identical pins to X1) --------------------------------
const C1_ADEPT = "/shared/home/greg/local/adept-2-install"
const C1_MINIMIZER_H = "$C1_ADEPT/include/adept/Minimizer.h"
const C1_MINIMIZER_H_SHA = "dad747936a66304266d0dd31990afa3a7534c589ac6b7a9230eaafbe671a1f8d"
const C1_LIBADEPT = "$C1_ADEPT/lib/libadept.so.0.0.0"
const C1_LIBADEPT_SHA = "1f9016af1b6982493dc8d53dd3a11b2b0c54d4e84c4dbb548b4b06093d43dbcb"
const C1_ADEPT_SOURCE_H = "$C1_ADEPT/include/adept_source.h"
const C1_ADEPT_SOURCE_H_SHA = "8f29a64a2d8227e881a7a541e154d80b752f7746c8607f6a9f280b54f0312351"
const C1_NETCDF = "/shared/home/greg/local/ckdmip-stack"
const C1_CONFIGURE_ARGV = "./configure --with-adept=$C1_ADEPT " *
    "--with-netcdf=$C1_NETCDF " *
    "'LDFLAGS=-L$C1_ADEPT/lib -Wl,-rpath,$C1_ADEPT/lib' 'LIBS=-ladept'"
const C1_CONFIG_STATUS_EXPECT = "--with-adept=$C1_ADEPT " *
    "--with-netcdf=$C1_NETCDF " *
    "'LDFLAGS=-L$C1_ADEPT/lib -Wl,-rpath,$C1_ADEPT/lib' LIBS=-ladept"
const C1_TOOLCHAIN = [
    ("gcc", "/usr/bin/gcc", "gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"),
    ("g++", "/usr/bin/g++", "g++ (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"),
    ("make", "/usr/bin/make", "GNU Make 4.3"),
    ("autoreconf", "/usr/bin/autoreconf", "autoreconf (GNU Autoconf) 2.71")]
const C1_AUTOMAKE_VER = "1.16.5"
const C1_LIBTOOLIZE_VER = "2.4.7"

# --- proven Netlib remedy pins -------------------------------------------------------
const C1_SHIM_SO = "$C1_G4WORK/tools/h5open_before_traps.so"
const C1_SHIM_SO_SHA = "28003281a7f1c8470c1bfd94a654999a210581261a5c3e9cd662af2a13dd492f"
const C1_NETLIB_BLAS = "/usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0"
const C1_NETLIB_BLAS_SHA = "e748efcae5753fe4a652877fccdb5895ac6f7605668a2db878b19c914e78e3a8"
const C1_NETLIB_LAPACK = "/usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0"
const C1_NETLIB_LAPACK_SHA = "851bb1fc5833ede9ed704b4417a251a899976d5e0915de40452615187a65278f"

# --- prerequisite: the REVIEWED committed X1 completion ledger -----------------------
const C1_X1_LEDGER = "$C1_PROJECT_ROOT/validation/results/gate4_x1_direct_capture_completion_ledger.json"
const C1_X1_LEDGER_CASE = "gate4_x1_direct_capture_completion_ledger"
const C1_X1_LEDGER_STATUS = "x1_run_completed_verified"
const C1_X1_LEDGER_SHA = "bb1f87c597e673c8a5b5181d325d46eff7b4619c106e28e7ecf121db32c34170"
const C1_X1_LEDGER_COMMIT = "4a3be7a596a3be1e4391c767f23de1f163e227f7"

# --- historical bridge target (informational in-job; ledger matter) ------------------
# computed from the preserved 4561 RUNROOT on 2026-08-14 and
# RE-VERIFIED fail-closed at generation (Agent 42 minor B)
const C1_BRIDGE_RAW2 = "$C1_G4WORK/g4-diag/4561/lw-x1/work-pristine/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
const C1_BRIDGE_RAW2_BYTES = 2415304
const C1_BRIDGE_RAW2_SHA = "49ff3df8c02a1b62f7bfa6cd4b8dc2c6c96e93079c1d042eb8cfb5fc49c61e37"

# --- scientific inputs: identical pins to the 4515/B0/S1/X1 manifest -----------------
const C1_DATA_INPUTS = [
    ("dde735608e57af934a2c1e99932c0ccce530883ab48910c7e17b621de7fa0bee", 450863,
     "$C1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-180.h5"),
    ("b0932f2648f720af74191d2a9d62f6178f73dfb9a620b773e55670f06ce2db85", 450863,
     "$C1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-280.h5"),
    ("01836becbc96e7da2b3b33d586d148948df136457216625b7e60225e093e1792", 450863,
     "$C1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-415.h5"),
    ("c8aa819b9e7ea7ed73a0af74862ab49d4209866b74988529b2dfce0ef99710e2", 450863,
     "$C1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-560.h5"),
    ("cfbda1d66decc14e6e91e8465f32f5a5e4bcf0310a73f620fe45bafbcec9ba7c", 450873,
     "$C1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-1120.h5"),
    ("75239df6dbf578b3be6267c09995ff050f5c846be3c75492fad96dcab25610e8", 450873,
     "$C1_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-2240.h5")]
const C1_WORK_INPUTS = [
    ("e799eae4421afe12481533678963237198338b3979ec938c6e61c2759522d4bc", 451045,
     "$C1_G4WORK/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5",
     "lw_lbl_fluxes"),
    ("ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43", 2413144,
     "$C1_G4WORK/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc",
     "lw_raw-ckd-definition"),
    ("c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e", 58404939,
     "$C1_G4WORK/work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5",
     "lw_gpoints")]
const C1_V12_TEST_PINS = [
    ("f0d77b16b97612687818e85615a103adaa948627846c9819e40e7754ab0743ba",
     11792, "$C1_SRC_ARTIFACT/test/optimize_lut_lw.sh"),
    ("44dcddf099d69becab1c5e6674d013d6c676685e0b8a4ae51e85a1dda33cfc69",
     6357, "$C1_SRC_ARTIFACT/test/config.h"),
    ("34323fd3ecbcd64980b328eec463eedc692497ed3cdd685f2505ca4d1fdc5e2c",
     1369, "$C1_SRC_ARTIFACT/test/check_configuration.h"),
    ("a5fe514dbcb656c99c11ca39d1c88eba953bda592ca35983de9c42da33dab810",
     92, "$C1_SRC_ARTIFACT/test/version.h.in")]

# --- the single factor (source-cited) -------------------------------------------------
const C1_FLAG_TOKEN = "bounded_minimization=0"
const C1_MODEL_ID_ANCHOR = "model_id=lw_\${APPLICATION}_\${BANDSTRUCT}-tol\${TOL} \\"

const C1_RESULTS_JSON = validation_results_path("gate4_c1_bounds_flag_checkpoint.json")
const C1_RESULTS_MD = validation_results_path("gate4_c1_bounds_flag_checkpoint.md")
const C1_SBATCH = validation_results_path("gate4_c1_lw_bounds_flag.sbatch")

const C1_CANONICAL_DIR = joinpath(C1_PROJECT_ROOT, "validation")
const C1_REPRO_NOTE = "reproducibility: the generator's sibling " *
    "package file (frozen design) is hash-pinned; the generated " *
    "sbatch addresses the canonical paths under " *
    "$C1_PROJECT_ROOT/validation regardless of where generation ran, " *
    "and sbatch stage 0a refuses unless the bytes at those paths " *
    "match the pins; final artifacts must be regenerated from the " *
    "promoted byte-identical package before commit."

# --- primitives ------------------------------------------------------------------------

c1_sha(path) = open(io -> bytes2hex(sha256(io)), path)
c1_try_sha(path) = try
    isfile(path) || return nothing
    c1_sha(path)
catch
    nothing
end

function c1_tree_manifest()
    entries = NamedTuple[]
    for (root, _, files) in walkdir(C1_SRC_ARTIFACT)
        for f in files
            p = joinpath(root, f)
            islink(p) && error("unexpected symlink in artifact: $p")
            rel = relpath(p, C1_SRC_ARTIFACT)
            push!(entries, (rel = rel, sha = c1_sha(p),
                            exec = (uperm(p) & 0x01) != 0))
        end
    end
    sort!(entries, by = e -> e.rel)
    entries
end

c1_manifest_hash(entries) = bytes2hex(sha256(join(
    ["F $(e.sha) $(e.exec ? 1 : 0) $(e.rel)" for e in entries], "\n")))

function c1_snapshot(path; readfn = read)
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

function c1_classify_ledger(path; expected_case = C1_X1_LEDGER_CASE,
                            expected_status = C1_X1_LEDGER_STATUS,
                            expected_sha = C1_X1_LEDGER_SHA,
                            readfn = read)
    snap = c1_snapshot(path; readfn = readfn)
    snap.ok || return (ok = false, class = snap.reason,
                       reason = "X1 ledger $(snap.reason)")
    c = get(snap.data, "case", nothing)
    c == expected_case || return (ok = false, class = "case mismatch",
        reason = "X1 ledger case mismatch (got $(repr(c)))")
    s = get(snap.data, "status", nothing)
    s == expected_status || return (ok = false, class = "status mismatch",
        reason = "X1 ledger status $(repr(s)) != $expected_status")
    snap.sha == expected_sha || return (ok = false, class = "sha drift",
        reason = "X1 ledger sha $(snap.sha) != reviewed $(expected_sha)")
    (ok = true, class = "green", reason = "")
end

# SHARED schema+value check code (monitor blocker fix): the EXACT
# per-variable stored-type + dimension signature is pinned from the
# pinned initial raw definition and enforced for EVERY arm BEFORE the
# value policy; nonnumeric/unexpected stored types REFUSE (structural
# fault), never silently skip. This ONE text is embedded verbatim in
# BOTH in-job julia snippets (mode via env) and include_string'd for
# the behavioral fixtures -- no dual implementation. No single-quote
# characters (the sbatch embeds it inside a single-quoted julia -e).
const C1_CHECK_CODE = """
function c1_schema_value_check(path, mode, sig_lines, dims_expect)
    bad = String[]
    nf = Tuple{String, Int}[]
    sig = Dict{String, Tuple{String, Vector{String}}}()
    for l in sig_lines
        parts = split(l, "|")
        if length(parts) != 3
            push!(bad, "malformed signature line: " * l)
            continue
        end
        sig[String(parts[1])] = (String(parts[2]),
            String.(split(parts[3], ","; keepempty = false)))
    end
    NCDataset(path) do ds
        dims_have = sort([String(k) for k in keys(ds.dim)])
        dims_want = sort([String(first(d)) for d in dims_expect])
        dims_have == dims_want ||
            push!(bad, "dimension name set " * string(dims_have) *
                " != pinned " * string(dims_want))
        for (d, v) in dims_expect
            (haskey(ds.dim, d) && ds.dim[d] == v) ||
                push!(bad, "dim " * d * " != " * string(v))
        end
        have = sort([String(k) for k in keys(ds)])
        expected = sort(collect(keys(sig)))
        for v in setdiff(expected, have)
            push!(bad, "var missing: " * v)
        end
        for v in setdiff(have, expected)
            push!(bad, "unexpected extra var: " * v)
        end
        for k in intersect(expected, have)
            et, dn = sig[k]
            tok = true
            if string(eltype(ds[k].var)) != et
                push!(bad, "var " * k * " stored type " *
                    string(eltype(ds[k].var)) * " != pinned " * et)
                tok = false
            end
            if collect(String.(dimnames(ds[k]))) != dn
                push!(bad, "var " * k * " dims " *
                    string(collect(String.(dimnames(ds[k])))) *
                    " != pinned signature")
                tok = false
            end
            tok || continue
            a = try
                Array(ds[k])
            catch
                push!(bad, "unreadable var " * k)
                continue
            end
            length(a) > 0 || push!(bad, "var empty: " * k)
            any(ismissing, a) && push!(bad, "missing values in " * k)
            n = count(!isfinite, skipmissing(a))
            if mode == "strict"
                n == 0 || push!(bad, "nonfinite values in " * k)
            elseif n > 0
                push!(nf, (String(k), n))
            end
        end
    end
    (bad, nf)
end
"""
include_string(@__MODULE__, C1_CHECK_CODE)

# generation-time COMPLETE global dimension name+extent map from a
# sha-bracketed pinned file (monitor blocker fix 2: partial expected-
# member dim checks let unexpected/unchecked dimensions pass)
function c1_dims_map(path, sha)
    pre = c1_try_sha(path)
    pre == sha || return (["pre-open sha $pre != pinned $sha: $path"],
                          nothing)
    dims = try
        NCDataset(path) do ds
            sort([(String(k), Int(ds.dim[k])) for k in keys(ds.dim)];
                 by = first)
        end
    catch err
        return (["dims read failed for $path: " *
                 sprint(showerror, err)], nothing)
    end
    post = c1_try_sha(path)
    post == sha || return (["post-close sha $post != pinned $sha: $path"],
                           nothing)
    (String[], dims)
end

# generation-time signature derivation from a sha-bracketed pinned file
function c1_signature_lines(path, sha)
    pre = c1_try_sha(path)
    pre == sha || return (["pre-open sha $pre != pinned $sha: $path"],
                          nothing)
    lines = try
        NCDataset(path) do ds
            [k * "|" * string(eltype(ds[k].var)) * "|" *
             join(String.(dimnames(ds[k])), ",")
             for k in sort([String(x) for x in keys(ds)])]
        end
    catch err
        return (["signature read failed for $path: " *
                 sprint(showerror, err)], nothing)
    end
    post = c1_try_sha(path)
    post == sha || return (["post-close sha $post != pinned $sha: $path"],
                           nothing)
    (String[], lines)
end

# derive the injected test-script text exactly as the job's sed does
# (fixture authority for the exactly-once/leak gates)
function c1_derive_injected(script_text, runset)
    iss = String[]
    lines = split(script_text, '\n'; keepempty = true)
    anchor_hits = [i for (i, l) in enumerate(lines)
                   if endswith(l, C1_MODEL_ID_ANCHOR)]
    length(anchor_hits) == 1 ||
        (push!(iss, "model_id anchor not exactly once ($(length(anchor_hits)))");
         return (iss, nothing))
    occursin("bounded_minimization", script_text) &&
        (push!(iss, "script already references bounded_minimization");
         return (iss, nothing))
    inject = runset == "probe" ?
        ["\t    bounded_minimization=0 \\", "\t    max_iterations=1 \\"] :
        runset == "c1" ? ["\t    bounded_minimization=0 \\"] : String[]
    i = anchor_hits[1]
    out = vcat(lines[1:i], inject, lines[(i + 1):end])
    (iss, join(out, '\n'))
end

# --- sbatch generation -------------------------------------------------------------------

function c1_make_sbatch(tree, siglines, dims)
    sig_literal = join(["    \"$l\"," for l in siglines], "\n")
    dims_literal = join(["(\"$d\", $v)" for (d, v) in dims], ", ")
    verify_driver = """
SIG = [
$sig_literal
]
DIMS = [$dims_literal]
bad, nf = c1_schema_value_check(ENV["RAW2_PATH"], ENV["MODE"], SIG, DIMS)
for (k, n) in nf
    println("NONFINITE RECORD (", ENV["RUNSET"], "): var=", k,
            " count=", n)
end
isempty(bad) || (foreach(println, bad); exit(1))
if ENV["MODE"] == "strict"
    println("raw2 strict schema/finite verification passed (control)")
else
    total = isempty(nf) ? 0 : sum(last, nf)
    println("raw2 structural verification passed (", ENV["RUNSET"],
            "; nonfinite values recorded: ", total,
            " -- lawful observation under the preregistered two-tier policy)")
end
"""
    verify_snippet = "using NCDatasets\n" * C1_CHECK_CODE * verify_driver
    stage_rows = String[]
    for (sha, sz, path) in C1_DATA_INPUTS
        push!(stage_rows, "$sha $sz $path \$RUNROOT/data/evaluation1/lw_fluxes/$(basename(path))")
    end
    for runset in ("probe", "c0a", "c1", "c0b")
        for (sha, sz, path, rel) in C1_WORK_INPUTS
            push!(stage_rows, "$sha $sz $path \$RUNROOT/work-$runset/$rel/$(basename(path))")
        end
    end
    stage_lines = join(stage_rows, "\n")
    data_post_hash_lines = join(
        ["$sha  \$RUNROOT/data/evaluation1/lw_fluxes/$(basename(path))"
         for (sha, _, path) in C1_DATA_INPUTS], "\n")
    data_post_size_lines = join(
        ["$sz \$RUNROOT/data/evaluation1/lw_fluxes/$(basename(path))"
         for (_, sz, path) in C1_DATA_INPUTS], "\n")
    hash_lines = join(vcat(
        ["$sha  $path" for (sha, _, path) in C1_DATA_INPUTS],
        ["$sha  $path" for (sha, _, path, _) in C1_WORK_INPUTS],
        ["$sha  $path" for (sha, _, path) in C1_V12_TEST_PINS],
        ["$C1_MINIMIZER_H_SHA  $C1_MINIMIZER_H",
         "$C1_LIBADEPT_SHA  $C1_LIBADEPT",
         "$C1_ADEPT_SOURCE_H_SHA  $C1_ADEPT_SOURCE_H"]), "\n")
    size_lines = join(vcat(
        ["$sz $path" for (_, sz, path) in C1_DATA_INPUTS],
        ["$sz $path" for (_, sz, path, _) in C1_WORK_INPUTS],
        ["$sz $path" for (_, sz, path) in C1_V12_TEST_PINS]), "\n")
    gate_pins = join(vcat(
        ["$(c1_sha(joinpath(C1_PROJECT_ROOT, f)))  $(joinpath(C1_PROJECT_ROOT, f))"
         for f in ("validation/gate4_quota_guard.sh",
                   "validation/validation_results.jl")],
        ["$(c1_sha(abspath(@__FILE__)))  $C1_PROJECT_ROOT/validation/gate4_c1_bounds_flag_checkpoint.jl",
         "$C1_DESIGN_SHA  $C1_PROJECT_ROOT/$C1_DESIGN_REPO_PATH",
         "$C1_X1_LEDGER_SHA  $C1_X1_LEDGER"]), "\n")
    artifact_tree_lines = join(["$(e.sha)  $C1_SRC_ARTIFACT/$(e.rel)"
                                for e in tree], "\n")
    copy_tree_lines = join(["$(e.sha)  $(e.rel)" for e in tree], "\n")
    execbit_lines = join(["$(e.exec ? 1 : 0) $(e.rel)" for e in tree], "\n")
    toolchain_checks = join([begin
        V = uppercase(replace(t, "+" => "X"))
        """
$(V)_P=\$(command -v $t) || { echo "REFUSED: $t missing" >&2; exit 65; }
[ "\$$(V)_P" = "$p" ] || { echo "REFUSED: $t path \$$(V)_P != pinned $p" >&2; exit 65; }
$(V)_FULL=\$($t --version); $(V)_L1=\${$(V)_FULL%%\$'\\n'*}
[ "\$$(V)_L1" = "$l1" ] || { echo "REFUSED: $t version line '\$$(V)_L1' != pinned '$l1'" >&2; exit 65; }"""
    end for (t, p, l1) in C1_TOOLCHAIN], "\n")
    banner_3000 = "Optimizing coefficients with Adept LBFGS " *
        "algorithm: max iterations = 3000, convergence criterion = 0.02"
    banner_1 = "Optimizing coefficients with Adept LBFGS " *
        "algorithm: max iterations = 1, convergence criterion = 0.02"
    template_pins = join(["$sha  \$RUNROOT/test-template/$(basename(path))"
                          for (sha, _, path) in C1_V12_TEST_PINS], "\n")
    """
#!/bin/bash
#SBATCH --job-name=g4-c1-lw-bounds-flag
#SBATCH --output=$C1_LOG_DIR/g4-c1-lw-%j.log
#SBATCH --time=06:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=36
#SBATCH --mem=60G
#SBATCH --partition=cpu-large

# Gate-4 C1: BOUNDED-MINIMIZATION FLAG FACTOR (DIAGNOSIS unit; PRIVATE
# output only). Generated by gate4_c1_bounds_flag_checkpoint.jl under
# the frozen C1 design $C1_DESIGN_SHA.
# ONE pinned source tree, ONE build, ONE immutable binary shared by
# ALL arms; run order PROBE (unbounded, 1 iteration; structural
# evidence only) -> C0a (bounded control) -> C1 (the single factor
# bounded_minimization=0) -> C0b (bounded control). TWO-TIER VALUE
# POLICY: structure failures refuse; nonfinite values in probe/C1
# raw2 are recorded observations, never refusals; strict all-finite
# applies to C0a/C0b only. Internal validity (C0a==C0b identity AND
# terminal-status equality) and the historical 4561 bridge are LEDGER
# matters; in-job byte-compares are informational echoes only. ZERO
# canonical writes; RUNROOT preserved on success AND failure.
set -euo pipefail
if [ -z "\${SLURM_JOB_ID:-}" ]; then
    echo "REFUSED: head-node execution is not permitted; submit via sbatch." >&2
    exit 64
fi
case "\$SLURM_JOB_ID" in
    ''|*[!0-9]*) echo "REFUSED: SLURM_JOB_ID is not a positive integer" >&2; exit 64;;
esac

G4WORK=$C1_G4WORK
RUNROOT="\$G4WORK/g4-diag/\${SLURM_JOB_ID}/lw-c1"
SRCDIR="\$RUNROOT/src/ecckd-modern-c1"

echo "=== C1-lw stage 0a: gate-code identity (verify BEFORE sourcing) ==="
sha256sum -c <<'GATEPINS' || { echo "REFUSED: gate code/reviewed prerequisite ledger changed since generation; regenerate the checkpoint" >&2; exit 75; }
$gate_pins
GATEPINS

echo "=== C1-lw stage 0b: quota health (read-only) ==="
source $C1_PROJECT_ROOT/validation/gate4_quota_guard.sh
quota_health \$((5*1024*1024*1024)) || { echo "REFUSED: quota not healthy" >&2; exit 67; }

echo "=== C1-lw stage 0c: pinned inputs + FULL artifact tree manifest + fail-closed toolchain ==="
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
[ "\$(find "$C1_SRC_ARTIFACT" \\( -type f -o -type l \\) | wc -l)" = "$C1_TREE_FILES" ] || { echo "REFUSED: artifact tree file census != $C1_TREE_FILES" >&2; exit 69; }
[ "\$(find "$C1_SRC_ARTIFACT" -type l | wc -l)" = 0 ] || { echo "REFUSED: unexpected symlink in artifact tree" >&2; exit 69; }
while read -r xf rel; do
    if [ "\$xf" = 1 ]; then
        [ -x "$C1_SRC_ARTIFACT/\$rel" ] || { echo "REFUSED: artifact exec bit lost: \$rel" >&2; exit 69; }
    else
        [ ! -x "$C1_SRC_ARTIFACT/\$rel" ] || { echo "REFUSED: artifact exec bit gained: \$rel" >&2; exit 69; }
    fi
done <<'EXECBITS'
$execbit_lines
EXECBITS
$toolchain_checks
AM_FULL=\$(automake --version); AM_LINE1=\${AM_FULL%%\$'\\n'*}; AM_V=\${AM_LINE1##* }
LT_FULL=\$(libtoolize --version); LT_LINE1=\${LT_FULL%%\$'\\n'*}; LT_V=\${LT_LINE1##* }
[ "\$AM_V" = "$C1_AUTOMAKE_VER" ] || { echo "REFUSED: automake \$AM_V != pinned $C1_AUTOMAKE_VER" >&2; exit 65; }
[ "\$LT_V" = "$C1_LIBTOOLIZE_VER" ] || { echo "REFUSED: libtoolize \$LT_V != pinned $C1_LIBTOOLIZE_VER" >&2; exit 65; }

echo "=== C1-lw stage 0d: C1 experiment lock (duplicate-diagnosis guard) ==="
mkdir -p "\$G4WORK/locks"
exec 9>"\$G4WORK/locks/c1-lw.lock"
flock -n 9 || { echo "REFUSED: another C1-lw diagnosis job holds the lock" >&2; exit 73; }

echo "=== C1-lw stage 1: job-private RUNROOT + per-run-set scientific-input snapshot ==="
[ ! -e "\$RUNROOT" ] || { echo "REFUSED: RUNROOT already exists: \$RUNROOT" >&2; exit 72; }
mkdir -p "\$RUNROOT/data/evaluation1/lw_fluxes" "\$RUNROOT/src" "\$RUNROOT/bin" "\$RUNROOT/tools"
for runset in probe c0a c1 c0b; do
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
[ -d "\$RUNROOT/data" ] || { echo "REFUSED: staged data tree missing" >&2; exit 76; }
chmod -R a-w "\$RUNROOT/data"
WLIST=\$(find "\$RUNROOT/data" -writable) || { echo "REFUSED: writable-entry scan failed on the staged data tree" >&2; exit 76; }
[ -z "\$WLIST" ] || { echo "REFUSED: writable entries remain in the staged data tree after chmod" >&2; printf '%s\\n' "\$WLIST" >&2; exit 76; }
echo "staged data tree locked read-only (zero writable entries)"

echo "=== C1-lw stage 2: writable source copy + full-tree content identity + frozen test template ==="
mkdir -p "\$SRCDIR"
cp -rT "$C1_SRC_ARTIFACT" "\$SRCDIR"
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

echo "=== C1-lw stage 3: SINGLE pristine build (corrected fresh-autoreconf recipe; ONE binary for ALL arms) ==="
cd "\$SRCDIR"
autoreconf -i
$C1_CONFIGURE_ARGV
make -j"\$SLURM_CPUS_PER_TASK"
test -x "\$SRCDIR/src/ecckd/optimize_lut" || { echo "REFUSED: optimize_lut not built" >&2; exit 68; }
[ "\$(strings "\$SRCDIR/src/ecckd/optimize_lut" | grep -cF 'Adept LBFGS' || true)" -ge 1 ] || { echo "REFUSED: Adept LBFGS banner string absent from binary" >&2; exit 68; }
cp -- "\$SRCDIR/src/ecckd/optimize_lut" "\$RUNROOT/bin/optimize_lut_c"
chmod a-w "\$RUNROOT/bin/optimize_lut_c"
cp -- "\$SRCDIR/config.log" "\$RUNROOT/config.log.c"
./config.status --config > "\$RUNROOT/config.status.config.txt"
echo "--- config.status --config (single configure/build) ---"
cat "\$RUNROOT/config.status.config.txt"
[ "\$(cat "\$RUNROOT/config.status.config.txt")" = "$C1_CONFIG_STATUS_EXPECT" ] || { echo "REFUSED: config.status --config != corrected reviewed recipe rendering" >&2; exit 68; }
sha256sum "\$RUNROOT/bin/optimize_lut_c" "\$RUNROOT/config.log.c" "\$RUNROOT/config.status.config.txt"
[ "\$(grep -c 'gate4_x1' "\$SRCDIR/src/ecckd/solve_adept.cpp" || true)" = 0 ] || { echo "REFUSED: capture instrument present; C1 is pristine-only" >&2; exit 69; }

echo "=== C1-lw stage 4: per-run-set wrappers (Netlib preload + FP-trap shim; SAME binary) + loader proof ==="
sha256sum -c <<'RUNTIMEPINS' || { echo "REFUSED: runtime BLAS/LAPACK/shim pin mismatch" >&2; exit 79; }
$C1_NETLIB_BLAS_SHA  $C1_NETLIB_BLAS
$C1_NETLIB_LAPACK_SHA  $C1_NETLIB_LAPACK
$C1_SHIM_SO_SHA  $C1_SHIM_SO
RUNTIMEPINS
command -v readelf >/dev/null || { echo "MISSING readelf" >&2; exit 65; }
RE_BLAS=\$(readelf -d "$C1_NETLIB_BLAS")
RE_LAPACK=\$(readelf -d "$C1_NETLIB_LAPACK")
[ "\$(grep -cF 'Library soname: [libblas.so.3]' <<<"\$RE_BLAS" || true)" = 1 ] || { echo "REFUSED: netlib BLAS SONAME != libblas.so.3" >&2; exit 79; }
[ "\$(grep -cF 'Library soname: [liblapack.so.3]' <<<"\$RE_LAPACK" || true)" = 1 ] || { echo "REFUSED: netlib LAPACK SONAME != liblapack.so.3" >&2; exit 79; }
for runset in probe c0a c1 c0b; do
    W="\$RUNROOT/tools/optimize_lut_wrap_\$runset"
    cat > "\$W" <<WRAP
#!/bin/bash
export LD_PRELOAD="$C1_NETLIB_BLAS:$C1_NETLIB_LAPACK:$C1_SHIM_SO"
exec "\$RUNROOT/bin/optimize_lut_c" "\\\$@"
WRAP
    chmod +x "\$W"
    sha256sum "\$W"
    [ "\$(grep -cxF 'export LD_PRELOAD="$C1_NETLIB_BLAS:$C1_NETLIB_LAPACK:$C1_SHIM_SO"' "\$W" || true)" = 1 ] || { echo "REFUSED: wrapper preload line/order drifted (\$runset)" >&2; exit 79; }
done
LDD_OUT=\$(LD_PRELOAD="$C1_NETLIB_BLAS:$C1_NETLIB_LAPACK:$C1_SHIM_SO" ldd "\$RUNROOT/bin/optimize_lut_c")
echo "--- ldd (single binary) ---"
echo "\$LDD_OUT"
[ "\$(grep -cF "$C1_NETLIB_BLAS" <<<"\$LDD_OUT" || true)" = 1 ] || { echo "REFUSED: exact BLAS preload row count != 1" >&2; exit 79; }
[ "\$(grep -cF "$C1_NETLIB_LAPACK" <<<"\$LDD_OUT" || true)" = 1 ] || { echo "REFUSED: exact LAPACK preload row count != 1" >&2; exit 79; }
[ "\$(grep -cF 'liblapack.so.3 =>' <<<"\$LDD_OUT" || true)" = 0 ] || { echo "REFUSED: liblapack.so.3 alias row present" >&2; exit 79; }
[ "\$(grep -cF 'libblas.so.3 =>' <<<"\$LDD_OUT" || true)" = 0 ] || { echo "REFUSED: libblas.so.3 alias row present" >&2; exit 79; }
LN_B=\$(awk -v pat="$C1_NETLIB_BLAS" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
LN_L=\$(awk -v pat="$C1_NETLIB_LAPACK" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
LN_S=\$(awk -v pat="$C1_SHIM_SO" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
{ [ -n "\$LN_B" ] && [ -n "\$LN_L" ] && [ -n "\$LN_S" ] && [ "\$LN_B" -lt "\$LN_L" ] && [ "\$LN_L" -lt "\$LN_S" ]; } || { echo "REFUSED: preload row order is not BLAS<LAPACK<H5shim" >&2; exit 79; }

# SANDWICH RUN ORDER (frozen design): PROBE -> C0a -> C1 -> C0b
for runset in probe c0a c1 c0b; do
    echo "=== C1-lw stage 5-\$runset: \$runset relative-base run (single factor via config-only injection; explicit OpenMP controls) ==="
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
    # SINGLE-FACTOR INJECTION (config-only; anchored; exactly-once and
    # leak gates): probe = flag + 1 iteration; c1 = flag only;
    # c0a/c0b = NO injection (compiled default bounded)
    case "\$runset" in
        probe)
            sed -i 's|model_id=lw_\${APPLICATION}_\${BANDSTRUCT}-tol\${TOL} \\\\\$|&\\n\\t    bounded_minimization=0 \\\\\\n\\t    max_iterations=1 \\\\|' optimize_lut_lw.sh
            [ "\$(grep -cF 'bounded_minimization=0 \\' optimize_lut_lw.sh || true)" = 1 ] || { echo "REFUSED: probe flag injection not exactly once" >&2; exit 68; }
            [ "\$(grep -cF 'max_iterations=1 \\' optimize_lut_lw.sh || true)" = 1 ] || { echo "REFUSED: probe iteration injection not exactly once" >&2; exit 68; }
            ;;
        c1)
            sed -i 's|model_id=lw_\${APPLICATION}_\${BANDSTRUCT}-tol\${TOL} \\\\\$|&\\n\\t    bounded_minimization=0 \\\\|' optimize_lut_lw.sh
            [ "\$(grep -cF 'bounded_minimization=0 \\' optimize_lut_lw.sh || true)" = 1 ] || { echo "REFUSED: c1 flag injection not exactly once" >&2; exit 68; }
            [ "\$(grep -cF 'max_iterations' optimize_lut_lw.sh || true)" = 0 ] || { echo "REFUSED: iteration override leaked into c1" >&2; exit 68; }
            ;;
        c0a|c0b)
            [ "\$(grep -cF 'bounded_minimization' optimize_lut_lw.sh || true)" = 0 ] || { echo "REFUSED: flag leaked into \$runset" >&2; exit 68; }
            [ "\$(grep -cF 'max_iterations' optimize_lut_lw.sh || true)" = 0 ] || { echo "REFUSED: iteration override leaked into \$runset" >&2; exit 68; }
            ;;
    esac
    echo "runset \$runset: OMP_NUM_THREADS=\$SLURM_CPUS_PER_TASK OMP_DYNAMIC=FALSE SLURM_CPUS_PER_TASK=\$SLURM_CPUS_PER_TASK" | tee "\$RUNROOT/\$runset-base-run.log"
    OMP_NUM_THREADS="\$SLURM_CPUS_PER_TASK" OMP_DYNAMIC=FALSE \\
        APPLICATION=climate BAND_STRUCTURE=fsck TOLERANCE=0.0161 \\
        bash optimize_lut_lw.sh relative-base |& tee -a "\$RUNROOT/\$runset-base-run.log"
    RLOG="\$RUNROOT/\$runset-base-run.log"
    case "\$runset" in
        probe)
            [ "\$(grep -cF '$banner_1' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: probe did not show exactly one Adept banner (1/0.02)" >&2; exit 71; }
            [ "\$(grep -cF '$banner_3000' "\$RLOG" || true)" = 0 ] || { echo "REFUSED: probe unexpectedly ran 3000 iterations" >&2; exit 71; }
            [ "\$(grep -cF 'Minimization is unbounded' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: probe did not log unbounded mode (flag literal semantics)" >&2; exit 71; }
            [ "\$(grep -cF 'Minimization is bounded' "\$RLOG" || true)" = 0 ] || { echo "REFUSED: probe logged bounded mode" >&2; exit 71; }
            ;;
        c0a|c0b)
            [ "\$(grep -cF '$banner_3000' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$runset did not show exactly one Adept banner (3000/0.02)" >&2; exit 71; }
            [ "\$(grep -cF 'Minimization is bounded' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$runset did not log bounded mode" >&2; exit 71; }
            [ "\$(grep -cF 'number bounded below:' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$runset bounded-census line not exactly once" >&2; exit 71; }
            [ "\$(grep -cF 'Minimization is unbounded' "\$RLOG" || true)" = 0 ] || { echo "REFUSED: \$runset logged unbounded mode" >&2; exit 71; }
            ;;
        c1)
            [ "\$(grep -cF '$banner_3000' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: c1 did not show exactly one Adept banner (3000/0.02)" >&2; exit 71; }
            [ "\$(grep -cF 'Minimization is unbounded' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: c1 did not log unbounded mode (the single factor)" >&2; exit 71; }
            [ "\$(grep -cF 'Minimization is bounded' "\$RLOG" || true)" = 0 ] || { echo "REFUSED: c1 logged bounded mode" >&2; exit 71; }
            [ "\$(grep -cF 'number bounded below:' "\$RLOG" || true)" = 0 ] || { echo "REFUSED: c1 bounded-census line present" >&2; exit 71; }
            ;;
    esac
    [ "\$(grep -cF 'Optimizing coefficients of: composite h2o o3 co2' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$runset base gas banner not exactly once" >&2; exit 71; }
    [ "\$(grep -cF 'Convergence status: ' "\$RLOG" || true)" = 1 ] || { echo "REFUSED: \$runset convergence-status line not exactly once" >&2; exit 71; }
    ST_LINE=\$(grep -F 'Convergence status: ' "\$RLOG")
    RUN_STATUS="\${ST_LINE#*Convergence status: }"
    if [ "\$runset" != probe ]; then
        { [ "\$RUN_STATUS" = "Converged" ] || [ "\$RUN_STATUS" = "Maximum iterations reached" ]; } || { echo "REFUSED: \$runset terminal status '\$RUN_STATUS' outside the experiment-allowed set (Converged | Maximum iterations reached)" >&2; exit 71; }
    fi
    printf '%s' "\$RUN_STATUS" > "\$RUNROOT/\$runset-status.txt"
    R2="\$RUNROOT/work-\$runset/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
    test -s "\$R2" || { echo "MISSING \$runset raw2 output" >&2; exit 71; }
done

echo "=== C1-lw stage 6: private outputs (two-tier verification; informational echoes; ZERO canonical writes by design) ==="
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
# STRICT verification (controls ONLY): the PINNED per-variable
# stored-type + dimension signature is enforced BEFORE the value
# policy (type/dim/schema drift REFUSES in every arm); all-finite
# additionally required for controls
for runset in c0a c0b; do
    R2="\$RUNROOT/work-\$runset/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
    (cd $C1_PROJECT_ROOT && RAW2_PATH="\$R2" MODE=strict RUNSET="\$runset" julia --project=test -e '
$(verify_snippet)') || { echo "REFUSED: \$runset raw2 failed STRICT schema/finite verification (control arm)" >&2; exit 71; }
done
# STRUCTURE-STRICT verification (probe + C1): SAME pinned signature
# enforcement (structure faults refuse); NONFINITE values are RECORDED
# observations under the preregistered two-tier policy, never refusals
for runset in probe c1; do
    R2="\$RUNROOT/work-\$runset/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
    (cd $C1_PROJECT_ROOT && RAW2_PATH="\$R2" MODE=structural RUNSET="\$runset" julia --project=test -e '
$(verify_snippet)') || { echo "REFUSED: \$runset raw2 failed STRUCTURAL verification (structure faults refuse; nonfinite values never do)" >&2; exit 71; }
done
PROBE_STATUS=\$(cat "\$RUNROOT/probe-status.txt")
C0A_STATUS=\$(cat "\$RUNROOT/c0a-status.txt")
C1_STATUS=\$(cat "\$RUNROOT/c1-status.txt")
C0B_STATUS=\$(cat "\$RUNROOT/c0b-status.txt")
echo "STATUS RECORD (descriptive, for the completion ledger): probe='\$PROBE_STATUS' c0a='\$C0A_STATUS' c1='\$C1_STATUS' c0b='\$C0B_STATUS'"
C0A_R2="\$RUNROOT/work-c0a/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
C0B_R2="\$RUNROOT/work-c0b/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
C1_R2="\$RUNROOT/work-c1/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
# INFORMATIONAL byte-compare echoes ONLY (internal validity = logical
# identity + status equality, decided in the completion ledger)
if cmp -s "\$C0A_R2" "\$C0B_R2"; then
    echo "BASELINE ECHO: C0a and C0b raw2 are BYTE-IDENTICAL (informational; the ledger decides the internal gate)"
else
    echo "BASELINE ECHO: C0a and C0b raw2 DIFFER at byte level (informational; the ledger decides the internal gate)"
fi
if cmp -s "\$C0A_R2" "\$C1_R2"; then
    echo "FLAG ECHO: C1 and C0a raw2 are BYTE-IDENTICAL (informational)"
else
    echo "FLAG ECHO: C1 and C0a raw2 DIFFER at byte level (informational; expected -- the flag is upstream of the solve)"
fi
echo "historical bridge target (4561 pristine raw2; ledger matter; informational echo only): $C1_BRIDGE_RAW2_SHA"
sha256sum "\$RUNROOT/probe-base-run.log" "\$RUNROOT/c0a-base-run.log" "\$RUNROOT/c1-base-run.log" "\$RUNROOT/c0b-base-run.log" \\
    "\$RUNROOT/bin/optimize_lut_c" "\$C0A_R2" "\$C1_R2" "\$C0B_R2" \\
    "\$RUNROOT/work-probe/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
echo "RUNROOT preserved for diagnosis/forensics: \$RUNROOT (no cleanup by design)"
echo "=== C1-lw done \$(date -u +%FT%TZ) ==="
"""
end

# --- text gates ------------------------------------------------------------------------

function c1_bash_syntax_ok(text)
    try
        p = joinpath(mktempdir(), "c1_syntax_check.sbatch")
        write(p, text)
        success(pipeline(`bash -n $p`, stdout = devnull, stderr = devnull))
    catch
        false
    end
end

function c1_text_gate_issues(text, siglines, dims)
    iss = String[]
    req = [
        "REFUSED: head-node execution is not permitted",
        "RUNROOT=\"\$G4WORK/g4-diag/\${SLURM_JOB_ID}/lw-c1\"",
        "cp -rT \"$C1_SRC_ARTIFACT\" \"\$SRCDIR\"",
        C1_DESIGN_SHA,
        "$C1_PROJECT_ROOT/$C1_DESIGN_REPO_PATH",
        C1_X1_LEDGER_SHA,
        C1_X1_LEDGER,
        C1_BRIDGE_RAW2_SHA,
        "autoreconf -i",
        C1_CONFIGURE_ARGV,
        C1_CONFIG_STATUS_EXPECT,
        "'LDFLAGS=-L$C1_ADEPT/lib -Wl,-rpath,$C1_ADEPT/lib'",
        "'LIBS=-ladept'",
        "optimize_lut_c",
        "chmod a-w \"\$RUNROOT/bin/optimize_lut_c\"",
        "REFUSED: capture instrument present; C1 is pristine-only",
        "ARTTREE", "COPYTREE", "EXECBITS", "TEMPLATEPINS",
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
        "bounded_minimization=0",
        "max_iterations=1",
        "REFUSED: probe flag injection not exactly once",
        "REFUSED: c1 flag injection not exactly once",
        "REFUSED: flag leaked into \$runset",
        "REFUSED: iteration override leaked into c1",
        "REFUSED: probe did not log unbounded mode (flag literal semantics)",
        "REFUSED: c1 did not log unbounded mode (the single factor)",
        "REFUSED: c1 bounded-census line present",
        "Minimization is unbounded",
        "Minimization is bounded",
        "number bounded below:",
        "outside the experiment-allowed set (Converged | Maximum iterations reached)",
        "RUN_STATUS=\"\${ST_LINE#*Convergence status: }\"",
        "STATUS RECORD (descriptive, for the completion ledger): probe='\$PROBE_STATUS' c0a='\$C0A_STATUS' c1='\$C1_STATUS' c0b='\$C0B_STATUS'",
        "raw2 strict schema/finite verification passed (control)",
        "NONFINITE RECORD (",
        "MODE=strict",
        "MODE=structural",
        "stored type ",
        "!= pinned signature",
        "c1_schema_value_check",
        "lawful observation under the preregistered two-tier policy",
        "REFUSED: \$runset raw2 failed STRICT schema/finite verification (control arm)",
        "structure faults refuse; nonfinite values never do",
        "BASELINE ECHO:",
        "FLAG ECHO:",
        "the ledger decides the internal gate",
        "RUNROOT preserved for diagnosis/forensics",
        "flock -n 9",
        "cp -r \"\$SRCDIR/test\" \"\$RUNROOT/test-template\"",
        "chmod -R a-w \"\$RUNROOT/test-template\"",
        "cp -r \"\$RUNROOT/test-template\" \"\$TC\"",
        "index(\$0, pat) && !ln { ln = NR }"]
    for r in req
        occursin(r, text) || push!(iss, "required text missing: $r")
    end
    for (pat, n, what) in (
        (r"bash optimize_lut_lw\.sh relative-base", 1,
         "relative-base invocation (single line inside the run loop)"),
        (r"for runset in probe c0a c1 c0b; do", 3,
         "probe/c0a/c1/c0b loops (mkdir, wrappers, run)"),
        (r"for runset in c0a c0b; do", 1, "strict-verification loop (controls only)"),
        (r"for runset in probe c1; do", 1, "structural-verification loop (probe+c1)"),
        (Regex("\\Q" * C1_CONFIGURE_ARGV * "\\E"), 1, "corrected configure invocation"),
        (Regex("\\Q" * C1_CONFIG_STATUS_EXPECT * "\\E"), 1, "config.status expectation"),
        (Regex("\\Q'LIBS=-ladept'\\E"), 1, "quoted LIBS assignment"),
        (Regex("\\Qbounded_minimization=0\\E"), 5,
         "flag token (header comment + 2 sed payloads + 2 count gates)"),
        (Regex("\\Qchmod -R a-w \"\$RUNROOT/data\"\\E"), 1, "data-tree immutability lock"),
        (Regex("\\Qfind \"\$RUNROOT/data\" -writable\\E"), 2,
         "writable-entry scans (post-staging + post-run)"),
        (Regex("\\Qcount(!isfinite\\E"), 2,
         "shared nonfinite counter (one per embedded snippet)"),
        (Regex("\\Qfunction c1_schema_value_check\\E"), 2,
         "shared schema+value check definition (one per embedded snippet)"),
        (Regex("\\QMODE=strict\\E"), 1, "strict-mode invocation (controls)"),
        (Regex("\\QMODE=structural\\E"), 1,
         "structural-mode invocation (probe+c1)"),
        (Regex("\\Q" * siglines[1] * "\\E"), 2,
         "pinned signature first line (embedded in both snippets)"),
        (Regex("\\Q(\"$(dims[1][1])\", $(dims[1][2]))\\E"), 2,
         "pinned dims first entry (embedded in both snippets)"),
        (Regex("\\Q(\"temperature_planck\", 231)\\E"), 2,
         "temperature_planck dim extent (embedded in both snippets)"),
        (Regex("\\Q(\"wavenumber\", 326)\\E"), 2,
         "wavenumber dim extent (embedded in both snippets)"),
        (Regex("\\Qdimension name set \\E"), 2,
         "exact dimension-name-set gate (one per embedded snippet)"))
        m = length(collect(eachmatch(pat, text)))
        m == n || push!(iss, "$what expected exactly $n, got $m")
    end
    for bad in ("relative-ch4", "relative-n2o", "relative-cfc",
                "CANON_FINAL", "mv -n", ".g3.publish.",
                "gate4_x1_capture", "X1HELPER", "GATE4_X1_CAPTURE_PATH",
                "solve_adept.cpp.orig",
                "$C1_G4WORK/work/lw_ckd-definition/ecckd-1.2_lw_ckd-definition")
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
    for m in eachmatch(r"(?m)^[^#\n]*> *\"?\$G4WORK/(?!g4-diag|locks/c1-lw\.lock)", text)
        push!(iss, "redirect toward shared G4WORK area: $(m.match)")
    end
    iss
end

# --- fixtures ------------------------------------------------------------------------------

function c1_fixtures(tree, siglines, dims)
    t = Dict{String, Bool}()
    fx = mktempdir()
    shaof(p) = bytes2hex(sha256(read(p)))

    # SHARED schema+value check behavioral fixtures (the SAME code the
    # job embeds; tiny pinned signature + synthetic files)
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
    sd = mktempdir()
    good = write_tiny(joinpath(sd, "good.nc"))
    t["schema_conforming_strict_accepted"] = begin
        bad, nf = c1_schema_value_check(good, "strict", tinysig, tinydims)
        isempty(bad) && isempty(nf)
    end
    t["schema_type_drift_refuses"] = begin
        p2 = write_tiny(joinpath(sd, "ty.nc"); alpha_ty = Float64)
        bad, _ = c1_schema_value_check(p2, "strict", tinysig, tinydims)
        any(occursin("stored type", b) for b in bad)
    end
    t["schema_dim_drift_refuses"] = begin
        p2 = write_tiny(joinpath(sd, "dm.nc"); alpha_dim = "m")
        bad, _ = c1_schema_value_check(p2, "strict", tinysig, tinydims)
        !isempty(bad)
    end
    t["schema_extra_var_refuses"] = begin
        p2 = write_tiny(joinpath(sd, "ex.nc"); extra = true)
        bad, _ = c1_schema_value_check(p2, "strict", tinysig, tinydims)
        any(occursin("unexpected extra var", b) for b in bad)
    end
    t["schema_missing_var_refuses"] = begin
        p2 = write_tiny(joinpath(sd, "ms.nc"); drop_beta = true)
        bad, _ = c1_schema_value_check(p2, "strict", tinysig, tinydims)
        any(occursin("var missing", b) for b in bad)
    end
    t["nonfinite_strict_refuses"] = begin
        p2 = write_tiny(joinpath(sd, "nfs.nc"); beta = [1.0, Inf, 3.0])
        bad, _ = c1_schema_value_check(p2, "strict", tinysig, tinydims)
        any(occursin("nonfinite values in beta", b) for b in bad)
    end
    t["nonfinite_structural_recorded_not_refused"] = begin
        p2 = write_tiny(joinpath(sd, "nfr.nc"); beta = [1.0, NaN, Inf])
        bad, nf = c1_schema_value_check(p2, "structural", tinysig, tinydims)
        isempty(bad) && nf == [("beta", 2)]
    end
    t["schema_type_drift_refuses_even_in_structural_mode"] = begin
        p2 = write_tiny(joinpath(sd, "tys.nc"); alpha_ty = Float64)
        bad, _ = c1_schema_value_check(p2, "structural", tinysig, tinydims)
        any(occursin("stored type", b) for b in bad)
    end
    t["dims_extent_drift_refuses"] = begin
        # file dim n=4 while the pinned map says n=3
        p2 = write_tiny(joinpath(sd, "de.nc"); n_extent = 4,
                        beta = [1.0, 2.0, 3.0, 4.0])
        bad, _ = c1_schema_value_check(p2, "strict", tinysig, tinydims)
        any(occursin("dim n != 3", b) for b in bad)
    end
    t["dims_unexpected_extra_refuses"] = begin
        # an unexpected UNUSED global dimension must refuse (the gap
        # this fix closes)
        p2 = write_tiny(joinpath(sd, "dx.nc"); extra_dim = true)
        bad, _ = c1_schema_value_check(p2, "strict", tinysig, tinydims)
        any(occursin("dimension name set", b) for b in bad)
    end
    # real signature/dims sanity (47 vars; COMPLETE 8-dim map)
    t["real_signature_47_entries"] = length(siglines) == 47
    t["real_signature_coefficient_float32"] = any(
        startswith(l, "composite_molar_absorption_coeff|Float32|")
        for l in siglines)
    t["real_dims_complete_8"] = length(dims) == 8 &&
        ("temperature_planck", 231) in dims &&
        ("wavenumber", 326) in dims && ("band", 1) in dims &&
        ("composite_gas", 4) in dims && ("g_point", 32) in dims &&
        ("h2o_mole_fraction", 12) in dims && ("pressure", 53) in dims &&
        ("temperature", 6) in dims

    # prerequisite-ledger classifier
    cls(p; kw...) = c1_classify_ledger(p; kw...)
    t["ledger_missing_refuses"] =
        cls(joinpath(fx, "absent.json")).class == "missing"
    p = joinpath(fx, "bad.json"); write(p, "{oops")
    t["ledger_unparseable_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "unparseable (parse failure)"
    p = joinpath(fx, "st.json")
    write(p, JSON.json(Dict("case" => C1_X1_LEDGER_CASE,
                            "status" => "x1_completion_ledger_refused")))
    t["ledger_status_mismatch_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "status mismatch"
    p = joinpath(fx, "green.json")
    write(p, JSON.json(Dict("case" => C1_X1_LEDGER_CASE,
                            "status" => C1_X1_LEDGER_STATUS)))
    t["ledger_sha_drift_refuses"] =
        cls(p; expected_sha = "0" ^ 64).class == "sha drift"
    t["ledger_green_accepted"] = cls(p; expected_sha = shaof(p)).ok

    # artifact tree
    t["tree_census_119"] = length(tree) == C1_TREE_FILES
    t["tree_exec_census_24"] = count(e -> e.exec, tree) == C1_TREE_EXEC

    # single-factor injection derivation (authority: the pinned script)
    script = read("$C1_SRC_ARTIFACT/test/optimize_lut_lw.sh", String)
    for (runset, want_flag, want_iter) in (("probe", 1, 1), ("c1", 1, 0),
                                           ("c0a", 0, 0))
        iss, injected = c1_derive_injected(script, runset)
        t["inject_$(runset)_derives"] = isempty(iss) && injected !== nothing
        injected === nothing && continue
        t["inject_$(runset)_flag_count"] =
            length(collect(eachmatch(
                Regex("\\Q" * "bounded_minimization=0 \\" * "\\E"),
                injected))) == want_flag
        t["inject_$(runset)_iter_count"] =
            length(collect(eachmatch(
                Regex("\\Q" * "max_iterations=1 \\" * "\\E"),
                injected))) == want_iter
    end
    t["inject_missing_anchor_refuses"] =
        !isempty(c1_derive_injected(replace(script,
            "model_id=lw_\${APPLICATION}_\${BANDSTRUCT}-tol\${TOL} \\" =>
            "model_id=other \\"), "c1")[1])
    t["inject_preexisting_flag_refuses"] =
        !isempty(c1_derive_injected(script * "\nbounded_minimization=1\n",
                                    "c1")[1])

    # sbatch text gates
    text = c1_make_sbatch(tree, siglines, dims)
    tg(x) = c1_text_gate_issues(x, siglines, dims)
    t["text_good_accepted"] = isempty(tg(text))
    t["text_missing_type_gate_refuses"] = !isempty(tg(replace(text,
        "stored type " => "type-ish ")))
    t["text_signature_tamper_refuses"] = !isempty(tg(replace(text,
        siglines[1] => "TAMPERED_SIGNATURE_LINE")))
    t["text_dims_tamper_refuses"] = !isempty(tg(replace(text,
        "(\"wavenumber\", 326)" => "(\"wavenumber\", 325)")))
    t["text_missing_dimset_gate_refuses"] = !isempty(tg(replace(text,
        "dimension name set " => "dimension names maybe ")))
    t["text_design_pin_drift_refuses"] =
        !isempty(tg(replace(text, C1_DESIGN_SHA => "0" ^ 64)))
    t["text_x1_ledger_pin_drift_refuses"] =
        !isempty(tg(replace(text, C1_X1_LEDGER_SHA => "0" ^ 64)))
    t["text_missing_probe_unbounded_gate_refuses"] = !isempty(tg(replace(text,
        "REFUSED: probe did not log unbounded mode (flag literal semantics)" =>
        "note")))
    t["text_missing_c1_unbounded_gate_refuses"] = !isempty(tg(replace(text,
        "REFUSED: c1 did not log unbounded mode (the single factor)" => "note")))
    t["text_missing_leak_gate_refuses"] = !isempty(tg(replace(text,
        "REFUSED: flag leaked into \$runset" => "note")))
    t["text_missing_strict_loop_refuses"] = !isempty(tg(replace(text,
        "for runset in c0a c0b; do" => "for runset in c0a; do")))
    t["text_missing_structural_loop_refuses"] = !isempty(tg(replace(text,
        "for runset in probe c1; do" => "for runset in probe; do")))
    t["text_missing_nonfinite_record_refuses"] = !isempty(tg(replace(text,
        "NONFINITE RECORD (" => "IGNORED (")))
    t["text_strict_applied_to_c1_refuses"] = !isempty(tg(replace(text,
        "for runset in c0a c0b; do" => "for runset in c0a c1 c0b; do")))
    t["text_missing_status_allowlist_refuses"] = !isempty(tg(replace(text,
        "outside the experiment-allowed set (Converged | Maximum iterations reached)" =>
        "recorded")))
    t["text_missing_data_lock_refuses"] = !isempty(tg(replace(text,
        "chmod -R a-w \"\$RUNROOT/data\"" => "true")))
    t["text_missing_data_reverify_refuses"] = !isempty(tg(replace(text,
        "REFUSED: staged data input drifted during the runs (sha mismatch)" =>
        "note")))
    t["text_capture_machinery_refuses"] =
        !isempty(tg(text * "\nexport GATE4_X1_CAPTURE_PATH=x\n"))
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
        "'LDFLAGS=-L$C1_ADEPT/lib -Wl,-rpath,$C1_ADEPT/lib'" =>
        "'LDFLAGS=-L$C1_ADEPT/lib -ladept'")))
    t["text_duplicate_configure_refuses"] =
        !isempty(tg(text * "\n" * C1_CONFIGURE_ARGV * "\n"))
    t["text_strings_absence_refuses"] = !isempty(tg(text *
        "\n[ \"\$(strings x | grep -cF 'Adept LBFGS' || true)\" = 0 ] || exit 99\n"))
    t["bash_syntax_good_accepted"] = c1_bash_syntax_ok(text)
    t["bash_syntax_broken_refuses"] =
        !c1_bash_syntax_ok(text * "\nif true; then\n")

    # design-file prose guards (two-tier + no-mechanism + probe scope)
    design = isfile(C1_DESIGN_FILE) ? read(C1_DESIGN_FILE, String) : ""
    t["design_two_tier_present"] =
        occursin("TWO-TIER VALUE POLICY", design) &&
        occursin("never a job refusal", design)
    t["design_no_mechanism_language"] =
        occursin("discriminates NO mechanism", design) &&
        !occursin("unbounded solution", design)
    t["design_probe_structural_only"] =
        occursin("structural evidence only", design)
    t["design_internal_gate_both_conditions"] =
        occursin("terminal-status", design) &&
        occursin("EXACT EQUALITY", design)
    t
end

# --- main -----------------------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()

    tree = c1_tree_manifest()
    groups = Dict{String, Vector{String}}()

    # PINNED per-variable stored-type + dimension signature: derived
    # from the pinned initial raw definition and REQUIRED equal to the
    # 4561 pristine raw2 signature (monitor blocker fix; both reads
    # sha-bracketed)
    sg = String[]
    init_iss, sig_init = c1_signature_lines(C1_WORK_INPUTS[2][3],
                                            C1_WORK_INPUTS[2][1])
    append!(sg, init_iss)
    raw2_iss, sig_raw2 = c1_signature_lines(C1_BRIDGE_RAW2,
                                            C1_BRIDGE_RAW2_SHA)
    append!(sg, raw2_iss)
    if sig_init !== nothing && sig_raw2 !== nothing
        sig_init == sig_raw2 ||
            push!(sg, "pinned initial-raw signature != 4561 pristine raw2 signature (type/dim authority ambiguous; refusing)")
        length(sig_init) == 47 ||
            push!(sg, "signature entry count $(length(sig_init)) != 47")
    end
    # COMPLETE global dimension map (blocker fix 2): derived under the
    # same sha-bracketed reads, exact equality required, count 8
    dinit_iss, dims_init = c1_dims_map(C1_WORK_INPUTS[2][3],
                                       C1_WORK_INPUTS[2][1])
    append!(sg, dinit_iss)
    draw2_iss, dims_raw2 = c1_dims_map(C1_BRIDGE_RAW2, C1_BRIDGE_RAW2_SHA)
    append!(sg, draw2_iss)
    if dims_init !== nothing && dims_raw2 !== nothing
        dims_init == dims_raw2 ||
            push!(sg, "pinned initial-raw dimension map != 4561 pristine raw2 dimension map (refusing)")
        length(dims_init) == 8 ||
            push!(sg, "dimension map count $(length(dims_init)) != 8")
    end
    groups["schema_signature"] = sg
    if !isempty(sg) || sig_init === nothing || dims_init === nothing
        for (k, v) in groups
            gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
            isempty(v) || append!(fails, ["$k: " * i for i in v])
        end
        println("gate4_c1_bounds_flag_checkpoint: c1_checkpoint_refused (schema signature)")
        isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
        return 1
    end
    siglines = sig_init
    dims = dims_init

    tests = c1_fixtures(tree, siglines, dims)
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    led = c1_classify_ledger(C1_X1_LEDGER)
    groups["reviewed_x1_completion_ledger"] = led.ok ? String[] : [led.reason]

    gitc = String[]
    commit = try
        strip(read(`git -C $C1_PROJECT_ROOT log -n1 --format=%H --
                    validation/results/gate4_x1_direct_capture_completion_ledger.json`,
                   String))
    catch
        "unreadable"
    end
    commit == C1_X1_LEDGER_COMMIT ||
        push!(gitc, "X1 ledger last-touching commit $commit != pinned $C1_X1_LEDGER_COMMIT")
    groups["x1_ledger_commit_pin"] = gitc

    dd = String[]
    if isfile(C1_DESIGN_FILE)
        dsha = c1_sha(C1_DESIGN_FILE)
        dsha == C1_DESIGN_SHA ||
            push!(dd, "durable frozen-design file sha $dsha != $C1_DESIGN_SHA")
    else
        push!(dd, "durable frozen-design file missing: $C1_DESIGN_FILE")
    end
    groups["frozen_design_file"] = dd

    # historical bridge target re-verified fail-closed (Agent 42 minor B)
    br = String[]
    isfile(C1_BRIDGE_RAW2) || push!(br, "4561 pristine raw2 missing")
    if isfile(C1_BRIDGE_RAW2)
        filesize(C1_BRIDGE_RAW2) == C1_BRIDGE_RAW2_BYTES ||
            push!(br, "4561 pristine raw2 size drift")
        c1_try_sha(C1_BRIDGE_RAW2) == C1_BRIDGE_RAW2_SHA ||
            push!(br, "4561 pristine raw2 sha drift")
    end
    groups["bridge_target_pin"] = br

    src = String[]
    length(tree) == C1_TREE_FILES ||
        push!(src, "artifact tree census $(length(tree)) != $C1_TREE_FILES")
    count(e -> e.exec, tree) == C1_TREE_EXEC ||
        push!(src, "artifact exec census != $C1_TREE_EXEC")
    for (sha, sz, path) in C1_V12_TEST_PINS
        isfile(path) || (push!(src, "testcopy file missing: $path"); continue)
        filesize(path) == sz || push!(src, "testcopy size drift: $path")
        c1_try_sha(path) == sha || push!(src, "testcopy sha drift: $path")
    end
    groups["modern_source_pins"] = src

    ad = String[]
    c1_try_sha(C1_MINIMIZER_H) == C1_MINIMIZER_H_SHA ||
        push!(ad, "installed Minimizer.h sha drift")
    c1_try_sha(C1_LIBADEPT) == C1_LIBADEPT_SHA ||
        push!(ad, "installed libadept.so.0.0.0 sha drift")
    c1_try_sha(C1_ADEPT_SOURCE_H) == C1_ADEPT_SOURCE_H_SHA ||
        push!(ad, "installed adept_source.h sha drift")
    isdir(joinpath(C1_NETCDF, "lib")) || push!(ad, "netcdf stack missing")
    groups["adept_toolchain_pins"] = ad

    tc = String[]
    for (t_, p_, l1) in C1_TOOLCHAIN
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
    for (sha, sz, path) in C1_DATA_INPUTS
        isfile(path) || (push!(inp, "missing: $path"); continue)
        filesize(path) == sz || push!(inp, "size drift: $path")
        c1_try_sha(path) == sha || push!(inp, "sha drift: $path")
    end
    for (sha, sz, path, _) in C1_WORK_INPUTS
        isfile(path) || (push!(inp, "missing: $path"); continue)
        filesize(path) == sz || push!(inp, "size drift: $path")
        c1_try_sha(path) == sha || push!(inp, "sha drift: $path")
    end
    groups["input_pins"] = inp

    rt = String[]
    for (path, sha, label) in ((C1_NETLIB_BLAS, C1_NETLIB_BLAS_SHA, "netlib blas"),
                               (C1_NETLIB_LAPACK, C1_NETLIB_LAPACK_SHA, "netlib lapack"),
                               (C1_SHIM_SO, C1_SHIM_SO_SHA, "h5 shim"))
        c1_try_sha(path) == sha || push!(rt, "$label pin mismatch: $path")
    end
    groups["runtime_pins"] = rt

    text = c1_make_sbatch(tree, siglines, dims)
    groups["sbatch_text_gates"] = c1_text_gate_issues(text, siglines, dims)
    groups["sbatch_bash_syntax"] = c1_bash_syntax_ok(text) ? String[] :
        ["generated sbatch fails bash -n syntax verification"]

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end
    ready = gates["fixtures"] == "passed" && all(isempty, values(groups))
    status = ready ? "c1_checkpoint_ready" : "c1_checkpoint_refused"
    if ready
        mkpath(dirname(C1_SBATCH))
        write(C1_SBATCH, text)
    end
    sb_sha = ready ? c1_sha(C1_SBATCH) : nothing

    design_text = isfile(C1_DESIGN_FILE) ? read(C1_DESIGN_FILE, String) :
        nothing

    result = Dict(
        "case" => "gate4_c1_bounds_flag_checkpoint",
        "data_mode" => "generator_checkpoint",
        "status" => status,
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "fixture_count" => length(tests),
        "sbatch_path" => C1_SBATCH,
        "sbatch_sha256" => sb_sha,
        "frozen_design" => Dict(
            "sha256" => C1_DESIGN_SHA,
            "durable_file" => C1_DESIGN_REPO_PATH,
            "verbatim_text" => design_text),
        "design" => "CONFIG-ONLY one-factor experiment on the identical " *
            "modern pinned stack as X1: triple-arm SAME-BINARY sandwich " *
            "C0a -> C1 -> C0b preceded by a 1-iteration UNBOUNDED probe " *
            "(flag literal semantics; structural evidence only); the " *
            "single factor is the command-line override " *
            "bounded_minimization=0 (optimize_lut.cpp:148-149; compiled " *
            "default true); pristine binary in ALL arms; no capture " *
            "instrument, no sidecar; the returned solution is UNOBSERVED " *
            "by design. C1 discriminates NO mechanism (the flag removes " *
            "the bounded solver path AND the log-space bound " *
            "construction simultaneously) and repairs nothing. TWO-TIER " *
            "VALUE POLICY: structure failures refuse; nonfinite values " *
            "in probe/C1 raw2 are recorded lawful observations; strict " *
            "all-finite applies to C0a/C0b only. Internal validity " *
            "(C0a==C0b logical identity AND terminal-status exact " *
            "equality) is SEPARATE from the historical 4561 bridge; " *
            "both are completion-ledger matters (in-job byte-compares " *
            "are informational echoes). Zero canonical writes; RUNROOT " *
            "preserved; no submission without explicit monitor GO.",
        "single_factor" => Dict(
            "key" => "bounded_minimization",
            "source" => "optimize_lut.cpp:148-149 (Real is_bounded = " *
                "true; config.read(is_bounded, \"bounded_minimization\"))",
            "injection" => "anchored command-line override " *
                "bounded_minimization=0 after the model_id line " *
                "(exactly-once gates; leak gates prove the token absent " *
                "from both control testcopies and the iteration " *
                "override absent from c1)",
            "runtime_authority" => "probe/c1: 'Minimization is " *
                "unbounded' exactly once + zero bounded/bounded-census " *
                "lines; c0a/c0b: bounded + bounded-census exactly once " *
                "+ zero unbounded lines"),
        "probe" => Dict(
            "purpose" => "flag literal-semantics verification at " *
                "~2-minute cost (Real-typed truthiness routing); " *
                "STRUCTURAL evidence only; no scientific value read; " *
                "status recorded WITHOUT the allowed-set gate",
            "injection" => "bounded_minimization=0 AND max_iterations=1"),
        "schema_signature" => Dict(
            "source" => "derived at generation from the pinned initial " *
                "raw definition ($(C1_WORK_INPUTS[2][1])) and REQUIRED " *
                "equal to the 4561 pristine raw2 signature " *
                "($C1_BRIDGE_RAW2_SHA); both reads sha-bracketed",
            "entries" => length(siglines),
            "sample" => siglines[1],
            "dimension_map" => Dict(d => v for (d, v) in dims),
            "dimension_map_semantics" => "COMPLETE global dimension " *
                "name+extent map (count 8), derived under the same " *
                "sha-bracketed reads and required equal between the " *
                "pinned initial raw and the 4561 pristine raw2; every " *
                "arm requires the exact dimension-name SET plus " *
                "extents (an unexpected unused global dimension " *
                "refuses)",
            "enforcement" => "exact stored type AND exact dimension " *
                "names per variable, enforced for probe/C0a/C1/C0b " *
                "BEFORE the value policy via the shared " *
                "c1_schema_value_check text (embedded verbatim in both " *
                "in-job snippets and behaviorally fixture-tested); " *
                "type/dim/schema drift refuses in EVERY arm; the " *
                "two-tier value policy applies only after structure " *
                "passes"),
        "two_tier_policy" => Dict(
            "structure" => "schema/dims/vars/types failures refuse in " *
                "every arm (instrument faults)",
            "values" => "nonfinite values in probe/C1 raw2 are LAWFUL " *
                "recorded observations (per-variable NONFINITE RECORD " *
                "lines + total), never a job refusal; the strict " *
                "all-finite verification applies to C0a/C0b ONLY; the " *
                "completion ledger applies the same conditionality to " *
                "census/comparator/logical-diff per the frozen design"),
        "internal_validity_and_bridge" => Dict(
            "internal_gate" => "C0a-vs-C0b logical scientific identity " *
                "AND terminal-status exact equality (ledger matter; " *
                "either failing => flag attribution INCONCLUSIVE, all " *
                "C1 comparisons descriptive, no post-hoc noise rule)",
            "historical_bridge" => "C0a and C0b each vs the pinned 4561 " *
                "pristine raw2 $C1_BRIDGE_RAW2_SHA (re-verified " *
                "fail-closed at generation); success does not replace " *
                "the internal gate; failure does not invalidate the " *
                "same-job one-factor comparison",
            "in_job" => "byte-compare BASELINE/FLAG echoes are " *
                "informational only; nothing gates on them"),
        "statuses" => Dict(
            "allowed_set" => ["Converged", "Maximum iterations reached"],
            "scope" => "per-arm execution gate for c0a/c1/c0b; probe " *
                "status recorded without the gate; control-vs-C1 " *
                "equality NOT required; C0a-vs-C0b exact equality is " *
                "part of the internal gate (ledger)"),
        "prerequisites" => [
            Dict("ledger" => "X1 direct-capture completion ledger",
                 "path" => C1_X1_LEDGER,
                 "required_case" => C1_X1_LEDGER_CASE,
                 "required_status" => C1_X1_LEDGER_STATUS,
                 "reviewed_sha256" => C1_X1_LEDGER_SHA,
                 "pinned_commit" => C1_X1_LEDGER_COMMIT)],
        "source_tree" => Dict(
            "artifact" => C1_SRC_ARTIFACT,
            "files" => C1_TREE_FILES,
            "executables" => C1_TREE_EXEC,
            "symlinks" => 0,
            "manifest_sha256" => c1_manifest_hash(tree)),
        "toolchain" => Dict(
            "configure_argv" => C1_CONFIGURE_ARGV,
            "fingerprints" => [Dict("tool" => t_, "path" => p_,
                                    "version_line" => l1)
                               for (t_, p_, l1) in C1_TOOLCHAIN],
            "automake" => C1_AUTOMAKE_VER,
            "libtoolize" => C1_LIBTOOLIZE_VER),
        "provenance" => Dict(
            "generation_dir" => abspath(string(@__DIR__)),
            "generated_in_canonical_location" =>
                abspath(string(@__DIR__)) == abspath(C1_CANONICAL_DIR),
            "note" => C1_REPRO_NOTE),
        "post_terminal_requirements" => [
            "completion ledger with the internal-validity gate " *
                "(identity AND status equality), the separate " *
                "historical bridge, the CONDITIONAL census/comparator/" *
                "nonfinite-aware logical diff per the frozen design, " *
                "and the verbatim ceiling; NOT in-job"],
        "non_authorizing_note" => "this checkpoint generates and " *
            "verifies the C1 sbatch; it never submits; submission " *
            "requires explicit monitor GO.",
        "disclaimer" => "generator checkpoint; writes nothing except " *
            "its own JSON/MD results and the generated sbatch plus " *
            "transient private temp fixtures (mktempdir).")

    mkpath(dirname(C1_RESULTS_JSON))
    open(C1_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(C1_RESULTS_MD, "w") do io
        println(io, "# Gate-4 C1 bounded-minimization flag-factor checkpoint\n")
        println(io, "Status: **$status**\n")
        println(io, result["design"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nFrozen design: `$C1_DESIGN_SHA` (durable file " *
                    "`$C1_DESIGN_REPO_PATH`)")
        println(io, "\nGenerated sbatch: `$C1_SBATCH`" *
                    (sb_sha === nothing ? " (NOT written; refused)" :
                     " sha256 `$sb_sha`"))
        println(io, "\nPrerequisite (fail-closed, sha-chained): X1 " *
                    "completion ledger `$C1_X1_LEDGER_SHA` " *
                    "($C1_X1_LEDGER_STATUS; commit $C1_X1_LEDGER_COMMIT)")
        println(io, "\nBridge target (ledger matter): 4561 pristine " *
                    "raw2 `$C1_BRIDGE_RAW2_SHA` (re-verified at " *
                    "generation)")
        println(io, "\nFixtures: $(length(tests)) " *
                    "($(count(values(tests))) passed)")
        println(io, "\nRun order: PROBE (unbounded, 1 iteration; " *
                    "structural only) -> C0a -> C1 -> C0b; single " *
                    "binary; two-tier value policy in-job; internal " *
                    "gate and bridge decided by the completion ledger.")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_c1_bounds_flag_checkpoint: $status")
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
