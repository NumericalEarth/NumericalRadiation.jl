# Gate-4 S1 STATE-SYNC COMPLETION LEDGER (job 4558, triple-arm sandwich
# A0a -> S1 -> A0b). Evidence unit; writes nothing except
# validation/results/gate4_s1_state_sync_completion_ledger.{json,md}
# plus transient private temp fixtures/snapshots (mktempdir); ZERO
# campaign/canonical writes.
#
# REGISTERED OUTCOME (committed matrix, verbatim application): the
# byte-level branch "A0a != A0b: byte-level treatment inference is
# INCONCLUSIVE because baseline repeatability failed; S1 metrics are
# descriptive only" FIRED (raw2 file hashes differ pairwise). Per the
# monitor's array-level directive, this ledger additionally computes
# and gates ARRAY-LEVEL deltas that distinguish scientific variables
# from NetCDF metadata; nothing is inferred from file hashes or from
# identical printed endpoints.
#
# ARRAY-LEVEL FINDINGS (recomputed and GATED in this unit):
#   - every scientific variable is ELEMENTWISE IDENTICAL across A0a,
#     A0b, and S1 -- and also identical to the historical 4515 raw2;
#     the only OBSERVED NetCDF LOGICAL differences are the run-specific
#     'config' and 'history' global attributes (embedded RUNROOT
#     paths/timestamps). Literal NetCDF encoding/layout differences
#     remain unexamined; the raw file hashes
#     establish byte inequality but not localization of every
#     differing byte.
#   - therefore, at array level: the baseline is exactly repeatable;
#     the one-line sync patch is associated with ZERO change in the
#     serialized scientific state in this run (per the committed
#     contract, no requirement that an extra final callback provably
#     executed: ensure_updated_state may find state already current);
#     and the A0 rebuild bridges to the historical 4515 output exactly
#     at array level.
#   - the active-state effective-bound census is IDENTICAL for all
#     arms and the historical file: below 134/152,631, above
#     19/152,640, worst dlog below 0.41887799902470135 / above
#     0.6268579421960787 -- the serialized-model effective-bound
#     exceedances PERSIST unchanged through the sync line.
#   - the pinned external comparator objective is BIT-EXACT equal for
#     all three arms and equals the historical v1.2 raw2 reference:
#     22.791293464348826.
#
# BINDING INTERPRETATION GUARDS (monitor, 2026-08-13/14, verbatim
# substance): vocabulary is ALWAYS "serialized model effective-bound
# exceedances", never "internal x escaped bounds". The exceedances are
# reported as BELOW and ABOVE counts separately (134 below / 19 above);
# the figure 153 is simply the SUM of exceedance EVENTS (134+19) from
# this same corrected active-state effective census -- it is NOT an
# earlier or distinct counting, and no unique-coordinate collapse is
# performed (no overlap calculation was computed). Because the
# exceedances persist, ALL THREE mechanism classes -- final-state
# SYNCHRONIZATION, mapping/write, and bounded-algorithm behavior --
# remain OPEN and UNRANKED globally: this specific rebuilt trajectory
# did not distinguish refresh-executed from already-current /
# identical-callback-values, so it observes no S1 effect WITHOUT
# globally excluding synchronization for historical 4515. NO ranking,
# NO localization, NO causal attribution. The internal returned x was
# UNOBSERVED/UNKNOWN in 4515 and remains unobserved here. Adept implementation citations are SOURCE-OBSERVED
# context only (installed Minimizer.h dad74793..., libadept
# 1f9016af..., adept_source.h 8f29a64a...; source-to-linked-binary
# provenance unproven): Vector pass-by-value is shallow/shared-storage
# so minimizer updates reach the local x; only callbacks write
# ckd_model.x; no direct write from local x to ckd_model outside
# callbacks; default ensure_updated_state_=-1 suppresses the
# conditional final callback; ecckd's unpatched source has zero
# ensure_updated_state calls. PRIMARY inference comes only from the
# A0a/A0b reproducibility plus the one-line S1 output/census/objective
# differences -- all of which are ZERO at array level in this run.
#
# COMPLETION STATUS IS INDEPENDENT OF SCIENTIFIC OUTCOME:
#   s1_run_completed_verified    -- every evidence group green (exit 0)
#   s1_completion_ledger_refused -- ANY discrepancy (exit 1)

include(joinpath(@__DIR__, "validation_results.jl"))
include(joinpath(@__DIR__, "ecckd_published_model_accuracy.jl"))

import JSON
using SHA: sha256

const SL_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
const SL_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"
const SL_RUNROOT = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/g4-diag/4558/lw-s1"

# fixed evidence timestamp = job 4558 EndTime (never wall-clock)
const SL_EVIDENCE_TIME = "2026-08-14T00:13:49Z"

const SL_REVIEWED_COMMIT = "9d94122d5c48fa881c65355511a17c91e5aab096"
const SL_GEN_SRC = joinpath(SL_PROJECT_ROOT,
    "validation/gate4_s1_state_sync_checkpoint.jl")
const SL_GEN_SRC_SHA = "4cf4d6c6e3b5b4e5888c4f6fc134003a60545e1f474242765f3c42dcc0bce9a6"
const SL_SBATCH = validation_results_path("gate4_s1_lw_state_sync.sbatch")
const SL_SBATCH_SHA = "666a9f4fc3727951d1fe7efdd715591f78e785e2a6d5f4de9b8326965509c44d"

const SL_RECEIPT_S40 = "$SL_LOG_DIR/g4-s1-lw-4558-scontrol-final-session40.txt"
const SL_RECEIPT_A42 = "$SL_LOG_DIR/g4-s1-lw-4558-scontrol-final-agent42.txt"
const SL_RECEIPT_SHA = "0d36f32d19c317c19616381ade089ae620d23161d06d7b4b7991f0f3bf87c75e"
const SL_LOG = "$SL_LOG_DIR/g4-s1-lw-4558.log"
const SL_LOG_SHA = "338256742d049f2cb22525578aa549bed947f548ad75103c0d447210761ed380"

const SL_EXPECT = Dict(
    "JobId" => "4558", "JobName" => "g4-s1-lw-paired-sync",
    "JobState" => "COMPLETED", "Reason" => "None",
    "ExitCode" => "0:0", "DerivedExitCode" => "0:0",
    "Restarts" => "0", "RunTime" => "01:53:10",
    "SubmitTime" => "2026-08-13T22:17:35",
    "StartTime" => "2026-08-13T22:20:39",
    "EndTime" => "2026-08-14T00:13:49",
    "Command" => joinpath(SL_PROJECT_ROOT,
        "validation/results/gate4_s1_lw_state_sync.sbatch"),
    "SubmitLine" => "sbatch --parsable validation/results/gate4_s1_lw_state_sync.sbatch",
    "WorkDir" => SL_PROJECT_ROOT,
    "StdOut" => SL_LOG)

# arm raw2 outputs (coupled size+sha; sizes differ by METADATA length only)
const SL_RAW2 = [
    ("a0a", "$SL_RUNROOT/work-a0a/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
     2415252, "df740e622a28c19e6fa77ce34fb50ec7d52e73857b53b8bbec6c6f4def0090d4"),
    ("a0b", "$SL_RUNROOT/work-a0b/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
     2415252, "9c7796fdea183205fc7587807931a2a182daa6218cf72460e75f8a501dd25ca2"),
    ("s1", "$SL_RUNROOT/work-s1/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
     2415248, "95ac316f62909f5426bb9b9b6dcfb33a326041ae1d9184d6f0bc6c6a1cebb593")]
const SL_HIST_RAW2 = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/g3-runs/4515/lw/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
const SL_HIST_RAW2_BYTES = 2415168
const SL_HIST_RAW2_SHA = "4205489923dbc50c3c148a06f20e5781b3f1dbeb5a13d55d36b460c5f7b4378c"
const SL_INIT = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc"
const SL_INIT_BYTES = 2413144
const SL_INIT_SHA = "ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43"

const SL_ARM_LOGS = [
    ("a0a", "$SL_RUNROOT/a0a-base-run.log",
     "79068590277c0c0ebc01ec8c5dba63f940fb1fb9a0e7284cd2eab1892cb31209"),
    ("a0b", "$SL_RUNROOT/a0b-base-run.log",
     "4af44d04270111c9085ef927b7b195ae00c3a3c71a0b6fd400feccd67b232def"),
    ("s1", "$SL_RUNROOT/s1-base-run.log",
     "f3a1cd3915e369be9fbd8e3c5c31ee5a0967ca6eec390cc8700fde3c81d40c1d")]
const SL_BIN_A0 = ("$SL_RUNROOT/bin/optimize_lut_a0", 22141400,
    "6f2ade09d6094635e5ee865e3d4376739dea0961d941637adfed8b6d25116e68")
const SL_BIN_S1 = ("$SL_RUNROOT/bin/optimize_lut_s1", 22141552,
    "f55eabb8dab518b7382b1cfd89dd9c883a064ddb532300994f4957007510e5a1")
const SL_SRC_ORIG = ("$SL_RUNROOT/solve_adept.cpp.orig",
    "8c9822fac6e6efebadc3fd76c104fe563236221ca6297922e5e8a9467ee32091")
const SL_SRC_PATCHED = ("$SL_RUNROOT/src/ecckd-modern-paired/src/ecckd/solve_adept.cpp",
    "c23246d53a474540443a0e877992dc0d24cfda1ad6cbafa218e3a824cb72070b")

const SL_ADEPT_BANNER = "Optimizing coefficients with Adept LBFGS " *
    "algorithm: max iterations = 3000, convergence criterion = 0.02"
const SL_TERMINAL_ITER = "Iteration 2999: cost function = 16.7768, gradient norm = 0.114057"
const SL_CONV_LINE = "Convergence status: Maximum iterations reached"
const SL_BASELINE_LINE = "BASELINE REPEATABILITY: A0a and A0b raw2 DIFFER " *
    "(baseline repeatability failed; byte-level treatment inference " *
    "INCONCLUSIVE; S1 metrics descriptive only)"
const SL_PRIMARY_LINE = "PRIMARY COMPARISON: S1 and A0a raw2 DIFFER " *
    "(interpretation conditional on baseline repeatability; " *
    "census/objective deltas decide post-terminal)"
const SL_DONE_MARK = "=== S1-lw done 2026-08-14T00:13:49Z ==="
const SL_STAGES = ["0a", "0b", "0c", "0d", "1", "2", "3", "4", "5", "6",
                   "7-a0a", "7-s1", "7-a0b", "8"]
const SL_FAILURE_RE = r"REFUSED|SCHEMA-INVALID|sha mismatch|MISSING/nonexecutable|[Qq]uota exceeded|CANCELLED|slurmstepd: error|Traceback \(most recent call last\)|\bERROR\b|\bFATAL\b|\bFAILED\b|CHILD KILLED|CHILD FAILED|SIGFPE|Floating point exception"

# pinned census expectations (active-state effective bounds; binding
# monitor definitions) -- identical for all arms and the historical file
const SL_CENSUS_EXPECT = (below = 134, above = 19,
    lo_den = 152631, hi_den = 152640, active = 152640,
    worst_lo = 0.41887799902470135, worst_hi = 0.6268579421960787)
const SL_ACTIVE_GASES = ("composite", "h2o", "o3", "co2")

# pinned comparator expectations
const SL_OBJECTIVE_EXPECT = 22.791293464348826
const SL_PUBLISHED_BASELINE = 0.18218645425029933

# comparator code/dependency pins (same manifest as the reviewed B0
# completion ledger; re-verified live)
const SL_CODE_PINS = [
    ("validation/ecckd_published_model_accuracy.jl",
     "e6a10832650e668d88e9e903f222ba130d1e549489a637fbb75c67d1e0520446"),
    ("validation/reduced_ecckd_accuracy.jl",
     "a62520b88f460da681e7fb94eb0d852c863248f98c3cfe1dbaf49b46c8843e02"),
    ("validation/validation_results.jl",
     "60fbaa93cf5f7e34eac2fcf6e054ae4caaf99c2e4e0a63a6c74aa74eeff31d12"),
    ("validation/write_ecrad_candidates.jl",
     "89a2cf69ca036a1762418853f72a09fd352fbe9904adf6c9f10eadbcaeb0c267"),
    ("validation/ecrad_reference_manifest.jl",
     "6bf4787a7fa2f5057217562d423dd6337dbf9702cfe29245276f6205fe1e6b23"),
    ("test/Project.toml",
     "9136a5f68b97123017182b5afaf30c93148188a0ea8681ac3d17a808f6012ef0"),
    ("test/Manifest.toml",
     "cf9f318d43221280a8ca1116fbfea20d66678267f4e9d5dd1bdf519093ceb186"),
    ("Project.toml",
     "e3921c81ac9c8f6f6d2210f59e6195399643b4c8f66625b59b1d950da3493058")]
const SL_SRC_TREE = "7eaf80136e313c073416a815334493fc3b5434e7"
const SL_CASE_INPUTS = [
    ("ecckd_clear_sky_tropical_column",
     joinpath(SL_PROJECT_ROOT,
              "validation/reference/ecrad/ecckd_clear_sky_tropical_column.nc"),
     207210,
     "3a1634b7c7b4e22ae4064ace9826ac76b6810fb4074a5437bfd30b5c911e68e7"),
    ("ecckd_rcemip_style_column_subset",
     joinpath(SL_PROJECT_ROOT,
              "validation/reference/ecrad/ecckd_rcemip_style_column_subset.nc"),
     612490,
     "8c4a6974d74d09ae5f6679f76495538d1b9812edada7d87b1ed6737303710db3")]
const SL_PUB_SW = official_ecckd_definition_path(:shortwave_32)
const SL_PUB_SW_BYTES = 851724
const SL_PUB_SW_SHA = "49abc7bf88b80252e4f9934f8659d108ffee6a101124b2fd080f2eb65d144eb3"
const SL_PUB_LW = official_ecckd_definition_path(:longwave_32)
const SL_PUB_LW_BYTES = 869280
const SL_PUB_LW_SHA = "6087f62f9052653f8e7dbee26cef8bf1977c2516669a169bee8d110b62912ed9"
const SL_H2O = 0.005

# Adept source-observed context pins (GATED in an evidence group;
# source-to-linked-binary provenance caveat retained)
const SL_MINIMIZER_H = "/shared/home/greg/local/adept-2-install/include/adept/Minimizer.h"
const SL_MINIMIZER_H_SHA = "dad747936a66304266d0dd31990afa3a7534c589ac6b7a9230eaafbe671a1f8d"
const SL_LIBADEPT = "/shared/home/greg/local/adept-2-install/lib/libadept.so.0.0.0"
const SL_LIBADEPT_SHA = "1f9016af1b6982493dc8d53dd3a11b2b0c54d4e84c4dbb548b4b06093d43dbcb"
const SL_ADEPT_SOURCE_H = "/shared/home/greg/local/adept-2-install/include/adept_source.h"
const SL_ADEPT_SOURCE_H_SHA = "8f29a64a2d8227e881a7a541e154d80b752f7746c8607f6a9f280b54f0312351"

const SL_RESULTS_JSON = validation_results_path("gate4_s1_state_sync_completion_ledger.json")
const SL_RESULTS_MD = validation_results_path("gate4_s1_state_sync_completion_ledger.md")

# fixture-guarded prose constants (monitor prose blockers, 2026-08-14)
const SL_BOUNDED_INTERP = "Serialized model effective-bound " *
    "exceedances persist in every arm (134 below / 19 above, reported " *
    "separately, never collapsed to unique positions without an " *
    "overlap calculation). ALL THREE mechanism classes -- final-state " *
    "SYNCHRONIZATION, mapping/write, and bounded-algorithm behavior " *
    "-- remain OPEN and UNRANKED globally, with no localization and " *
    "no causal attribution. This specific rebuilt trajectory did not " *
    "distinguish refresh-executed from already-current / " *
    "identical-callback-values: it observes no S1 scientific effect " *
    "in this run without globally excluding synchronization for " *
    "historical 4515. The internal returned x was and remains " *
    "unobserved."
const SL_EVENT_SUM_NOTE = "the figure 153 equals the SUM of exceedance " *
    "EVENTS (134 below + 19 above) from this same corrected " *
    "active-state effective census; it is not an earlier or distinct " *
    "raw-bound counting, and no unique-coordinate collapse or overlap " *
    "calculation is performed or implied"

# --- primitives -----------------------------------------------------------------

sl_try_sha(path) = try
    isfile(path) || return nothing
    open(io -> bytes2hex(sha256(io)), path)
catch
    nothing
end

function sl_read_pinned(path, sha; size = nothing, label = basename(path))
    isfile(path) || return (["$label missing: $path"], nothing)
    bytes = try
        read(path)
    catch
        return (["$label unreadable: $path"], nothing)
    end
    size === nothing || length(bytes) == size ||
        return (["$label size $(length(bytes)) != $size"], nothing)
    got = bytes2hex(sha256(bytes))
    (sha === nothing || got == sha) ||
        return (["$label sha $got != pinned $sha"], nothing)
    (String[], bytes)
end

function sl_pinned_snapshot(path, size, sha; label = basename(path))
    iss, bytes = sl_read_pinned(path, sha; size = size, label = label)
    bytes === nothing && return (iss, nothing)
    snap = joinpath(mktempdir(), "snap_" * basename(path))
    write(snap, bytes)
    (String[], snap)
end

sl_count(text, needle) = length(collect(eachmatch(
    Regex("\\Q" * needle * "\\E"), text)))

const SL_TOKEN_KEYS = ("JobId", "JobName", "JobState", "Reason",
    "ExitCode", "DerivedExitCode", "Restarts", "RunTime",
    "SubmitTime", "StartTime", "EndTime")

function sl_parse_receipt(text)
    f = Dict{String, String}()
    for k in SL_TOKEN_KEYS
        m = match(Regex("\\b" * k * "=(\\S+)"), text)
        m === nothing || (f[k] = String(m.captures[1]))
    end
    for k in ("Command", "SubmitLine", "WorkDir", "StdOut")
        m = match(Regex("^\\s*" * k * "=(.*)\$", "m"), text)
        m === nothing || (f[k] = String(strip(m.captures[1])))
    end
    f
end

function sl_receipt_issues(f, expect)
    iss = String[]
    for (k, v) in expect
        get(f, k, "") == v ||
            push!(iss, "$k mismatch (got $(repr(get(f, k, ""))))")
    end
    sort(iss)
end

# --- job/arm log contracts (pure) --------------------------------------------------

function sl_joblog_issues(text)
    iss = String[]
    lastpos = 0
    for s in SL_STAGES
        marker = "=== S1-lw stage $s:"
        n = sl_count(text, marker)
        n == 1 || push!(iss, "stage $s marker not exactly once ($n)")
        p = findfirst(marker, text)
        if p !== nothing
            first(p) > lastpos || push!(iss, "stage $s marker out of order")
            lastpos = first(p)
        end
    end
    for (label, needle, n_exp) in (
            ("done marker", SL_DONE_MARK, 1),
            ("baseline verdict line", SL_BASELINE_LINE, 1),
            ("primary verdict line", SL_PRIMARY_LINE, 1),
            ("schema-passed line", "raw2 independent schema/finite verification passed", 3),
            ("adept 3000 banner", SL_ADEPT_BANNER, 3),
            ("bounded-mode line", "Minimization is bounded", 3),
            ("terminal iteration record", SL_TERMINAL_ITER, 3))
        n = sl_count(text, needle)
        n == n_exp || push!(iss, "$label count $n != $n_exp")
    end
    m = match(SL_FAILURE_RE, text)
    m === nothing || push!(iss, "failure marker present: $(m.match)")
    iss
end

function sl_armlog_issues(arm, text)
    iss = String[]
    for (label, needle, n_exp) in (
            ("adept banner", SL_ADEPT_BANNER, 1),
            ("bounded-mode line", "Minimization is bounded", 1),
            ("terminal iteration record", SL_TERMINAL_ITER, 1),
            ("convergence line", SL_CONV_LINE, 1),
            ("OMP control line",
             "arm $arm: OMP_NUM_THREADS=36 OMP_DYNAMIC=FALSE SLURM_CPUS_PER_TASK=36", 1))
        n = sl_count(text, needle)
        n == n_exp || push!(iss, "$arm log $label count $n != $n_exp")
    end
    iss
end

# --- array-level identity (pure over datasets) --------------------------------------

# FULL LOGICAL NetCDF comparison (monitor blocker 2 + follow-ups):
# variable census (expected count), per-variable eltype / dimension
# names / shape / every variable attribute (TYPED, never stringified) /
# elementwise values, dimension census with lengths and fail-closed
# unlimited semantics, and ALL global attributes (typed). Results are
# phrased as observed NetCDF LOGICAL differences; literal NetCDF
# encoding/layout differences remain unexamined (raw hashes establish
# byte inequality, not per-byte localization).
# Returns (issues, differing_global_attribs, summary).

# typed attribute snapshot: name => (string(typeof(value)), value); a
# numeric 1 can never equal the string "1"
sl_typed_attrs(a) = Dict(String(k) => (string(typeof(a[k])), a[k])
                         for k in keys(a))
sl_attr_diff_names(aa, ab) = sort([k for k in union(keys(aa), keys(ab))
    if !(haskey(aa, k) && haskey(ab, k) && isequal(aa[k], ab[k]))])

function sl_array_identity(dsa, dsb; allowed_attr_diffs = ["config", "history"],
                           required_attr_diffs = nothing,
                           expected_var_count = 47,
                           unlimited_fn = ds -> sort(String.(unlimited(ds.dim))))
    iss = String[]
    va = sort([String(k) for k in keys(dsa)])
    vb = sort([String(k) for k in keys(dsb)])
    va == vb || push!(iss, "variable census differs")
    length(va) == expected_var_count ||
        push!(iss, "variable count $(length(va)) != $expected_var_count")
    for v in intersect(va, vb)
        A = Array(dsa[v]); B = Array(dsb[v])
        eltype(dsa[v]) == eltype(dsb[v]) ||
            push!(iss, "variable $v eltype differs")
        dimnames(dsa[v]) == dimnames(dsb[v]) ||
            push!(iss, "variable $v dimension names differ")
        isempty(sl_attr_diff_names(sl_typed_attrs(dsa[v].attrib),
                                   sl_typed_attrs(dsb[v].attrib))) ||
            push!(iss, "variable $v attributes differ")
        if size(A) != size(B)
            push!(iss, "variable $v size differs")
        elseif !all(isequal.(A, B))
            push!(iss, "variable $v differs at $(count(.!isequal.(A, B))) elements")
        end
    end
    da = Dict(String(k) => dsa.dim[k] for k in keys(dsa.dim))
    db = Dict(String(k) => dsb.dim[k] for k in keys(dsb.dim))
    da == db || push!(iss, "dimension census/lengths differ")
    # unlimited introspection FAILS CLOSED: a query failure on either
    # file appends an issue (never a shared sentinel that could falsely
    # compare equal); verified API: unlimited(ds.dim) -> String[]
    ua = try
        unlimited_fn(dsa)
    catch err
        push!(iss, "unlimited-dimension query failed (first file): " *
                   sprint(showerror, err))
        nothing
    end
    ub = try
        unlimited_fn(dsb)
    catch err
        push!(iss, "unlimited-dimension query failed (second file): " *
                   sprint(showerror, err))
        nothing
    end
    (ua !== nothing && ub !== nothing && ua != ub) &&
        push!(iss, "unlimited-dimension semantics differ")
    diffs = sl_attr_diff_names(sl_typed_attrs(dsa.attrib),
                               sl_typed_attrs(dsb.attrib))
    for d in diffs
        d in allowed_attr_diffs ||
            push!(iss, "unexpected global-attribute difference: $d")
    end
    # fail-closed EXACT-SET gate: before prose may say "the only
    # observed logical differences are config/history", the observed
    # diff set must EQUAL the required set (a missing expected diff
    # refuses just like an extra one)
    if required_attr_diffs !== nothing
        diffs == sort(required_attr_diffs) ||
            push!(iss, "observed global-attribute difference set " *
                       "$(diffs) != required exact set " *
                       "$(sort(required_attr_diffs))")
    end
    summary = Dict("variable_count" => length(va),
                   "dimension_census" => da,
                   "unlimited_dims" => something(ua, "query-failed"),
                   "differing_global_attributes" => diffs,
                   "comparison_scope" => "observed NetCDF LOGICAL " *
                       "structure/values only (typed attribute " *
                       "comparison, never stringified); literal NetCDF " *
                       "encoding/layout differences unexamined " *
                       "(raw hashes establish " *
                       "byte inequality, not per-byte localization)")
    (iss, diffs, summary)
end

# --- active-state effective-bound census (pure per-gas kernel) ----------------------

# SOURCE-FAITHFUL LOG-SPACE kernel (monitor blocker 1): direct dlog
# predicates exactly matching solve_adept's log-space semantics --
#   raw lower (lo>0):        violation when log(X) <  log(lo)
#   synthetic lower (lo==0 && ini>0 && hi>0):
#                            violation when log(X) < 3log(ini)-2log(hi)
#   X <= 0 under an effective lower bound counts BELOW without log
#   upper (hi>0):            violation when log(X) >  log(hi)
# (avoids under/overflow of the physical ini^3/hi^2 form)
function sl_census_gas(X, lo, hi, ini)
    # fail closed on nonfinite inputs: NaNs are never silently omitted
    # from predicates (the live job's finite gates should make this
    # unreachable; a violation is an instrument error, not a skip)
    for (nm, arr) in (("X", X), ("lo", lo), ("hi", hi), ("init", ini))
        all(isfinite, arr) ||
            throw(ArgumentError("nonfinite values in census input $nm"))
    end
    below = 0; above = 0; lo_den = 0; hi_den = 0
    worst_lo = 0.0; worst_hi = 0.0
    for i in eachindex(X)
        log_lo_eff = NaN
        if lo[i] > 0
            log_lo_eff = log(lo[i])
        elseif lo[i] == 0 && ini[i] > 0 && hi[i] > 0
            log_lo_eff = 3 * log(ini[i]) - 2 * log(hi[i])
        end
        if !isnan(log_lo_eff)
            lo_den += 1
            if X[i] <= 0
                # dlog exceedance of a positive lower bound by a
                # nonpositive value is +Inf, not zero
                below += 1
                worst_lo = Inf
            elseif log(X[i]) < log_lo_eff
                below += 1
                worst_lo = max(worst_lo, log_lo_eff - log(X[i]))
            end
        end
        if hi[i] > 0
            hi_den += 1
            if X[i] > 0 && log(X[i]) > log(hi[i])
                above += 1
                worst_hi = max(worst_hi, log(X[i]) - log(hi[i]))
            end
        end
    end
    (below = below, above = above, lo_den = lo_den, hi_den = hi_den,
     active = length(X), worst_lo = worst_lo, worst_hi = worst_hi)
end

# pinned per-gas expectations (monitor-cross-checked): below/above
const SL_CENSUS_PER_GAS = Dict(
    "composite" => (below = 0, above = 15),
    "h2o" => (below = 134, above = 4),
    "o3" => (below = 0, above = 0),
    "co2" => (below = 0, above = 0))

function sl_census_file(raw2_path, init_path)
    NCDataset(init_path) do di
        NCDataset(raw2_path) do dr
            tot = (below = 0, above = 0, lo_den = 0, hi_den = 0,
                   active = 0, worst_lo = 0.0, worst_hi = 0.0)
            per_gas = Dict{String, Any}()
            for g in SL_ACTIVE_GASES
                r = sl_census_gas(
                    Float64.(Array(dr[g * "_molar_absorption_coeff"])),
                    Float64.(Array(di[g * "_molar_absorption_coeff_min"])),
                    Float64.(Array(di[g * "_molar_absorption_coeff_max"])),
                    Float64.(Array(di[g * "_molar_absorption_coeff"])))
                per_gas[g] = Dict("below" => r.below, "above" => r.above,
                                  "lo_den" => r.lo_den, "hi_den" => r.hi_den)
                tot = (below = tot.below + r.below,
                       above = tot.above + r.above,
                       lo_den = tot.lo_den + r.lo_den,
                       hi_den = tot.hi_den + r.hi_den,
                       active = tot.active + r.active,
                       worst_lo = max(tot.worst_lo, r.worst_lo),
                       worst_hi = max(tot.worst_hi, r.worst_hi))
            end
            (tot, per_gas)
        end
    end
end

sl_per_gas_matches(per_gas) = all(
    per_gas[g]["below"] == SL_CENSUS_PER_GAS[g].below &&
    per_gas[g]["above"] == SL_CENSUS_PER_GAS[g].above
    for g in SL_ACTIVE_GASES)

sl_census_matches(c) = c.below == SL_CENSUS_EXPECT.below &&
    c.above == SL_CENSUS_EXPECT.above &&
    c.lo_den == SL_CENSUS_EXPECT.lo_den &&
    c.hi_den == SL_CENSUS_EXPECT.hi_den &&
    c.active == SL_CENSUS_EXPECT.active &&
    c.worst_lo == SL_CENSUS_EXPECT.worst_lo &&
    c.worst_hi == SL_CENSUS_EXPECT.worst_hi

# --- comparator --------------------------------------------------------------------

function sl_swap_objective(lw_path, sw_path, cases)
    model = read_ecckd_tabulated_gas_optics(lw_path, sw_path;
        gas_names = OFFICIAL_ECCKD_GASES, h2o_mole_fraction = SL_H2O)
    hard_objective([case_metrics(c, model) for c in cases]).value
end

# --- overall ------------------------------------------------------------------------

sl_overall(groups) = all(isempty, values(groups)) ?
    "s1_run_completed_verified" : "s1_completion_ledger_refused"

# --- fixtures -----------------------------------------------------------------------

function sl_fixtures()
    t = Dict{String, Bool}()
    fx = mktempdir()

    mkreceipt(over...) = begin
        e = Dict{String, String}(SL_EXPECT)
        for (k, v) in over
            e[k] = v
        end
        "JobId=$(e["JobId"]) JobName=$(e["JobName"])\n" *
        "   JobState=$(e["JobState"]) Reason=$(e["Reason"]) Dependency=(null)\n" *
        "   Requeue=1 Restarts=$(e["Restarts"]) BatchFlag=1 ExitCode=$(e["ExitCode"])\n" *
        "   DerivedExitCode=$(e["DerivedExitCode"])\n" *
        "   RunTime=$(e["RunTime"]) TimeLimit=06:00:00 TimeMin=N/A\n" *
        "   SubmitTime=$(e["SubmitTime"]) EligibleTime=$(e["SubmitTime"])\n" *
        "   StartTime=$(e["StartTime"]) EndTime=$(e["EndTime"]) Deadline=N/A\n" *
        "   Command=$(e["Command"])\n" *
        "   SubmitLine=$(e["SubmitLine"])\n" *
        "   WorkDir=$(e["WorkDir"])\n" *
        "   StdOut=$(e["StdOut"])\n"
    end
    ri(txt) = sl_receipt_issues(sl_parse_receipt(txt), SL_EXPECT)
    t["receipt_good_binds"] = isempty(ri(mkreceipt()))
    t["receipt_wrong_state_refuses"] =
        !isempty(ri(mkreceipt("JobState" => "FAILED")))
    t["receipt_wrong_runtime_refuses"] =
        !isempty(ri(mkreceipt("RunTime" => "01:53:11")))

    mkjoblog() = begin
        io = IOBuffer()
        for s in SL_STAGES
            println(io, "=== S1-lw stage $s: x ===")
            if startswith(s, "7-")
                println(io, SL_ADEPT_BANNER)
                println(io, "Minimization is bounded")
                println(io, SL_TERMINAL_ITER)
            end
        end
        for _ in 1:3
            println(io, "raw2 independent schema/finite verification passed")
        end
        println(io, SL_BASELINE_LINE)
        println(io, SL_PRIMARY_LINE)
        println(io, SL_DONE_MARK)
        String(take!(io))
    end
    good = mkjoblog()
    t["joblog_good_accepted"] = isempty(sl_joblog_issues(good))
    t["joblog_missing_stage_refuses"] = !isempty(sl_joblog_issues(
        replace(good, "=== S1-lw stage 7-s1: x ===\n" => "")))
    t["joblog_out_of_order_refuses"] = !isempty(sl_joblog_issues(
        "=== S1-lw stage 8: x ===\n" * replace(good,
            "=== S1-lw stage 8: x ===\n" => "")))
    t["joblog_missing_verdict_refuses"] = !isempty(sl_joblog_issues(
        replace(good, SL_BASELINE_LINE * "\n" => "")))
    t["joblog_wrong_schema_count_refuses"] = !isempty(sl_joblog_issues(
        good * "raw2 independent schema/finite verification passed\n"))
    t["joblog_failure_marker_refuses"] = !isempty(sl_joblog_issues(
        good * "OPTIMIZE_LUT CHILD FAILED rc=1\n"))

    mkarmlog(arm) = SL_ADEPT_BANNER * "\nMinimization is bounded\n" *
        "arm $arm: OMP_NUM_THREADS=36 OMP_DYNAMIC=FALSE SLURM_CPUS_PER_TASK=36\n" *
        SL_TERMINAL_ITER * "\n" * SL_CONV_LINE * "\n"
    t["armlog_good_accepted"] = isempty(sl_armlog_issues("a0a", mkarmlog("a0a")))
    t["armlog_wrong_terminal_refuses"] = !isempty(sl_armlog_issues("a0a",
        replace(mkarmlog("a0a"), SL_TERMINAL_ITER =>
            "Iteration 2999: cost function = 16.7769, gradient norm = 0.1")))
    t["armlog_missing_omp_refuses"] = !isempty(sl_armlog_issues("s1",
        mkarmlog("a0b")))

    # array-identity classifier on tiny synthetic pairs
    mknc(path; val = 1.0, attr = "X") = begin
        NCDataset(path, "c") do ds
            defDim(ds, "g_point", 4)
            v = defVar(ds, "coef", Float64, ("g_point",))
            v[:] = [1.0, 2.0, 3.0, val]
            ds.attrib["history"] = attr
            ds.attrib["stable"] = "same"
        end
        path
    end
    pa = mknc(joinpath(fx, "a.nc"))
    pb = mknc(joinpath(fx, "b.nc"); attr = "Y")
    pc = mknc(joinpath(fx, "c.nc"); val = 9.9, attr = "Y")
    cmpids(x, y; kw...) = NCDataset(x) do da
        NCDataset(y) do db
            sl_array_identity(da, db; expected_var_count = 1, kw...)
        end
    end
    t["array_identity_metadata_only_accepted"] = begin
        iss, diffs, summary = cmpids(pa, pb)
        isempty(iss) && diffs == ["history"] &&
            summary["variable_count"] == 1
    end
    t["array_identity_value_diff_refuses"] = begin
        iss, _, _ = cmpids(pa, pc)
        any(i -> occursin("variable coef differs", i), iss)
    end
    t["array_identity_unexpected_attr_refuses"] = begin
        pd = mknc(joinpath(fx, "d.nc"))
        NCDataset(pd, "a") do ds
            ds.attrib["stable"] = "changed"
        end
        iss, _, _ = cmpids(pa, pd)
        any(i -> occursin("unexpected global-attribute difference: stable", i), iss)
    end
    t["array_identity_var_attr_drift_refuses"] = begin
        pe = mknc(joinpath(fx, "e.nc"))
        NCDataset(pe, "a") do ds
            ds["coef"].attrib["units"] = "changed"
        end
        iss, _, _ = cmpids(pa, pe)
        any(i -> occursin("variable coef attributes differ", i), iss)
    end
    t["array_identity_eltype_drift_refuses"] = begin
        pf = joinpath(fx, "f.nc")
        NCDataset(pf, "c") do ds
            defDim(ds, "g_point", 4)
            v = defVar(ds, "coef", Float32, ("g_point",))
            v[:] = Float32[1.0, 2.0, 3.0, 1.0]
            ds.attrib["history"] = "X"
            ds.attrib["stable"] = "same"
        end
        iss, _, _ = cmpids(pa, pf)
        any(i -> occursin("variable coef eltype differs", i), iss)
    end
    t["array_identity_dim_drift_refuses"] = begin
        pg = joinpath(fx, "g.nc")
        NCDataset(pg, "c") do ds
            defDim(ds, "other_dim", 4)
            v = defVar(ds, "coef", Float64, ("other_dim",))
            v[:] = [1.0, 2.0, 3.0, 1.0]
            ds.attrib["history"] = "X"
            ds.attrib["stable"] = "same"
        end
        iss, _, _ = cmpids(pa, pg)
        any(i -> occursin("dimension", i), iss)
    end
    t["array_identity_var_count_gate"] = begin
        iss, _, _ = NCDataset(pa) do da
            NCDataset(pb) do db
                sl_array_identity(da, db; expected_var_count = 47)
            end
        end
        any(i -> occursin("variable count 1 != 47", i), iss)
    end
    # exact-set gate: the live comparisons REQUIRE exactly
    # [config, history]; a MISSING expected diff refuses like an extra
    t["array_identity_required_set_exact_accepted"] = begin
        iss, _, _ = NCDataset(pa) do da
            NCDataset(pb) do db
                sl_array_identity(da, db; expected_var_count = 1,
                    required_attr_diffs = ["history"])
            end
        end
        isempty(iss)
    end
    t["array_identity_required_set_missing_refuses"] = begin
        iss, _, _ = NCDataset(pa) do da
            NCDataset(pa) do da2
                sl_array_identity(da, da2; expected_var_count = 1,
                    required_attr_diffs = ["history"])
            end
        end
        any(i -> occursin("!= required exact set", i), iss)
    end

    # attribute TYPE drift: numeric 1 must never equal string "1"
    t["array_identity_attr_type_drift_refuses"] = begin
        ph = joinpath(fx, "h.nc")
        NCDataset(ph, "c") do ds
            defDim(ds, "g_point", 4)
            v = defVar(ds, "coef", Float64, ("g_point",))
            v[:] = [1.0, 2.0, 3.0, 1.0]
            ds.attrib["history"] = "X"
            ds.attrib["stable"] = Int32(1)
        end
        pi_ = joinpath(fx, "i.nc")
        NCDataset(pi_, "c") do ds
            defDim(ds, "g_point", 4)
            v = defVar(ds, "coef", Float64, ("g_point",))
            v[:] = [1.0, 2.0, 3.0, 1.0]
            ds.attrib["history"] = "X"
            ds.attrib["stable"] = "1"
        end
        iss, _, _ = NCDataset(ph) do da
            NCDataset(pi_) do db
                sl_array_identity(da, db; expected_var_count = 1)
            end
        end
        any(i -> occursin("unexpected global-attribute difference: stable", i), iss)
    end
    # unlimited-query failure FAILS CLOSED (issue appended, never a
    # silently-matching sentinel)
    t["array_identity_unlimited_failure_refuses"] = begin
        iss, _, _ = NCDataset(pa) do da
            NCDataset(pb) do db
                sl_array_identity(da, db; expected_var_count = 1,
                    unlimited_fn = _ -> error("query broken"))
            end
        end
        count(i -> occursin("unlimited-dimension query failed", i), iss) == 2
    end

    # census kernel: every effective-bound rule exercised
    t["census_raw_lower_violation_counted"] = begin
        c = sl_census_gas([0.5], [1.0], [2.0], [1.5])
        c.below == 1 && c.lo_den == 1 && c.hi_den == 1 && c.above == 0
    end
    t["census_synthetic_lower_violation_counted"] = begin
        # min==0, init>0, max>0 -> lo_eff = init^3/max^2 = 1/4; X below it
        c = sl_census_gas([0.2], [0.0], [2.0], [1.0])
        c.below == 1 && c.lo_den == 1
    end
    t["census_synthetic_lower_satisfied_not_counted"] = begin
        c = sl_census_gas([0.3], [0.0], [2.0], [1.0])
        c.below == 0 && c.lo_den == 1
    end
    t["census_upper_violation_counted"] = begin
        c = sl_census_gas([3.0], [1.0], [2.0], [1.5])
        c.above == 1 && c.hi_den == 1
    end
    t["census_nonpositive_bounds_excluded"] = begin
        # min==0 with init==0 -> no lower; max==0 -> no upper
        c = sl_census_gas([0.5], [0.0], [0.0], [0.0])
        c.lo_den == 0 && c.hi_den == 0 && c.below == 0 && c.above == 0
    end
    t["census_worst_dlog_computed"] = begin
        c = sl_census_gas([0.5], [1.0], [2.0], [1.5])
        c.worst_lo == log(1.0) - log(0.5)
    end
    t["census_nonpositive_X_counts_below"] = begin
        c = sl_census_gas([0.0], [1.0], [2.0], [1.5])
        c.below == 1 && c.lo_den == 1 && c.above == 0
    end
    t["census_nonpositive_X_worst_is_inf"] = begin
        c = sl_census_gas([0.0], [1.0], [2.0], [1.5])
        c.worst_lo == Inf
    end
    t["census_nonfinite_input_refuses"] = begin
        try
            sl_census_gas([NaN], [1.0], [2.0], [1.5])
            false
        catch err
            err isa ArgumentError && occursin("nonfinite", err.msg)
        end
    end
    t["census_logspace_synthetic_predicate"] = begin
        # log-space predicate: log(X) < 3log(ini)-2log(hi)
        c = sl_census_gas([0.2], [0.0], [2.0], [1.0])
        c.below == 1 && c.worst_lo == (3*log(1.0) - 2*log(2.0)) - log(0.2)
    end
    t["census_expect_selfconsistency"] = begin
        # the pinned expectation refuses a perturbed census
        c = merge(SL_CENSUS_EXPECT, (below = 135,))
        sl_census_matches(SL_CENSUS_EXPECT) && !sl_census_matches(c)
    end

    # prose guards (monitor blockers): all three mechanism classes stay
    # open in the bounded interpretation, exceedances reported
    # below/above separately, 153 never misattributed to a distinct
    # counting, no global synchronization exclusion
    t["prose_all_three_mechanisms_open"] =
        occursin("SYNCHRONIZATION", SL_BOUNDED_INTERP) &&
        occursin("mapping/write", SL_BOUNDED_INTERP) &&
        occursin("bounded-algorithm behavior", SL_BOUNDED_INTERP)
    t["prose_no_global_sync_exclusion"] =
        occursin("without globally excluding synchronization",
                 SL_BOUNDED_INTERP)
    t["prose_separate_below_above"] =
        occursin("134 below / 19 above", SL_BOUNDED_INTERP) &&
        occursin("never collapsed to unique positions",
                 SL_BOUNDED_INTERP)
    t["prose_153_is_event_sum"] =
        occursin("SUM of exceedance EVENTS (134 below + 19 above)",
                 SL_EVENT_SUM_NOTE) &&
        occursin("not an earlier or distinct raw-bound counting",
                 SL_EVENT_SUM_NOTE)

    # primitive pin fixtures (used by the adept/artifact gates)
    pp = joinpath(fx, "pin.bin"); write(pp, "PINNED-BYTES")
    ppsha = bytes2hex(sha256(read(pp)))
    t["read_pinned_good_accepted"] =
        isempty(sl_read_pinned(pp, ppsha)[1])
    t["read_pinned_sha_drift_refuses"] =
        !isempty(sl_read_pinned(pp, "0" ^ 64)[1])
    t["read_pinned_missing_refuses"] =
        !isempty(sl_read_pinned(joinpath(fx, "no.bin"), ppsha)[1])

    t["overall_all_green"] =
        sl_overall(Dict("a" => String[])) == "s1_run_completed_verified"
    t["overall_any_issue_refuses"] =
        sl_overall(Dict("a" => ["x"])) == "s1_completion_ledger_refused"
    t
end

# --- main -------------------------------------------------------------------------

function main()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    fails = String[]
    gates = Dict{String, String}()

    tests = sl_fixtures()
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    groups = Dict{String, Vector{String}}()

    anc = try
        success(`git -C $SL_PROJECT_ROOT merge-base --is-ancestor $SL_REVIEWED_COMMIT HEAD`)
    catch; false end
    groups["commit_ancestry"] = anc ? String[] :
        ["reviewed commit $SL_REVIEWED_COMMIT is not an ancestor of HEAD"]
    pk = String[]
    sl_try_sha(SL_GEN_SRC) == SL_GEN_SRC_SHA ||
        push!(pk, "checkpoint generator sha != pinned")
    sl_try_sha(SL_SBATCH) == SL_SBATCH_SHA ||
        push!(pk, "sbatch sha != pinned")
    groups["package_pins"] = pk

    rc_iss = String[]
    r40_iss, r40 = sl_read_pinned(SL_RECEIPT_S40, SL_RECEIPT_SHA;
                                  label = "session40 receipt")
    r42_iss, r42 = sl_read_pinned(SL_RECEIPT_A42, SL_RECEIPT_SHA;
                                  label = "agent42 receipt")
    append!(rc_iss, r40_iss); append!(rc_iss, r42_iss)
    if r40 !== nothing && r42 !== nothing
        r40 == r42 || push!(rc_iss, "receipts not byte-identical")
        for (label, bytes) in (("session40", r40), ("agent42", r42))
            for i in sl_receipt_issues(
                    sl_parse_receipt(String(copy(bytes))), SL_EXPECT)
                push!(rc_iss, "$label receipt: $i")
            end
        end
    end
    groups["dual_receipts"] = rc_iss

    jl_iss, jl_bytes = sl_read_pinned(SL_LOG, SL_LOG_SHA; label = "job log")
    jl_bytes === nothing ||
        append!(jl_iss, sl_joblog_issues(String(copy(jl_bytes))))
    groups["job_log_contract"] = jl_iss

    al = String[]
    for (arm, path, sha) in SL_ARM_LOGS
        a_iss, a_bytes = sl_read_pinned(path, sha; label = "$arm log")
        append!(al, a_iss)
        a_bytes === nothing ||
            append!(al, sl_armlog_issues(arm, String(copy(a_bytes))))
    end
    groups["arm_logs"] = al

    rr = String[]
    raw2_snaps = Dict{String, String}()
    for (arm, path, size, sha) in SL_RAW2
        iss, snap = sl_pinned_snapshot(path, size, sha; label = "$arm raw2")
        append!(rr, iss)
        snap === nothing || (raw2_snaps[arm] = snap)
    end
    h_iss, hist_snap = sl_pinned_snapshot(SL_HIST_RAW2, SL_HIST_RAW2_BYTES,
                                          SL_HIST_RAW2_SHA;
                                          label = "historical 4515 raw2")
    append!(rr, h_iss)
    i_iss, init_snap = sl_pinned_snapshot(SL_INIT, SL_INIT_BYTES, SL_INIT_SHA;
                                          label = "ce057079 init")
    append!(rr, i_iss)
    for (path, size, sha) in (SL_BIN_A0, SL_BIN_S1)
        b_iss, _ = sl_read_pinned(path, sha; size = size,
                                  label = basename(path))
        append!(rr, b_iss)
    end
    for (path, sha) in (SL_SRC_ORIG, SL_SRC_PATCHED)
        s_iss, _ = sl_read_pinned(path, sha; label = basename(path))
        append!(rr, s_iss)
    end
    groups["runroot_artifacts"] = rr

    # array-level identity: scientific variables elementwise identical
    # across all arms AND vs the historical 4515 raw2; only the
    # run-specific config/history global attributes may differ
    ai = String[]
    attr_diffs = Dict{String, Any}()
    if length(raw2_snaps) == 3 && hist_snap !== nothing
        for (na, nb) in (("a0a", "a0b"), ("a0a", "s1"))
            iss, diffs, summary = NCDataset(raw2_snaps[na]) do da
                NCDataset(raw2_snaps[nb]) do db
                    sl_array_identity(da, db;
                        required_attr_diffs = ["config", "history"])
                end
            end
            append!(ai, ["$na vs $nb: " * i for i in iss])
            attr_diffs["$na vs $nb"] = Dict("differing_global_attributes" => diffs,
                                            "summary" => summary)
        end
        iss, diffs, summary = NCDataset(raw2_snaps["a0a"]) do da
            NCDataset(hist_snap) do dh
                sl_array_identity(da, dh;
                    required_attr_diffs = ["config", "history"])
            end
        end
        append!(ai, ["a0a vs hist4515: " * i for i in iss])
        attr_diffs["a0a vs hist4515"] = Dict("differing_global_attributes" => diffs,
                                             "summary" => summary)
    else
        push!(ai, "array identity not evaluated (raw2 evidence failed)")
    end
    groups["array_identity"] = ai

    # active-state effective-bound census: recomputed per arm + hist,
    # bit-exact equal to the pinned expectation
    ce = String[]
    census_results = Dict{String, Any}()
    if init_snap !== nothing && length(raw2_snaps) == 3 && hist_snap !== nothing
        for (label, snap) in vcat([(a, raw2_snaps[a]) for a in ("a0a", "a0b", "s1")],
                                  [("hist4515", hist_snap)])
            c, per_gas = try
                sl_census_file(snap, init_snap)
            catch err
                push!(ce, "$label census instrument error: " *
                          sprint(showerror, err))
                continue
            end
            census_results[label] = Dict(
                "below" => c.below, "above" => c.above,
                "lo_den" => c.lo_den, "hi_den" => c.hi_den,
                "active" => c.active,
                "worst_dlog_below" => c.worst_lo,
                "worst_dlog_above" => c.worst_hi,
                "per_gas" => per_gas)
            sl_census_matches(c) ||
                push!(ce, "$label census != pinned expectation: $c")
            sl_per_gas_matches(per_gas) ||
                push!(ce, "$label per-gas census != pinned expectation")
        end
    else
        push!(ce, "census not evaluated (raw2/init evidence failed)")
    end
    groups["census_integrity"] = ce

    # Adept source-observed context pins: gated (drift refuses), with
    # the source-to-linked-binary caveat retained in the prose
    ad = String[]
    for (path, sha, label) in ((SL_MINIMIZER_H, SL_MINIMIZER_H_SHA, "Minimizer.h"),
                               (SL_LIBADEPT, SL_LIBADEPT_SHA, "libadept.so.0.0.0"),
                               (SL_ADEPT_SOURCE_H, SL_ADEPT_SOURCE_H_SHA, "adept_source.h"))
        a_iss, _ = sl_read_pinned(path, sha; label = label)
        append!(ad, a_iss)
    end
    groups["adept_context_pins"] = ad

    # comparator: code pins fail-closed, then snapshot-set evaluation;
    # every arm objective bit-exact equal to the pinned value
    cp = String[]
    for (rel, sha) in SL_CODE_PINS
        sl_try_sha(joinpath(SL_PROJECT_ROOT, rel)) == sha ||
            push!(cp, "comparator code pin drift: $rel")
    end
    src_tree = try
        strip(read(`git -C $SL_PROJECT_ROOT rev-parse HEAD:src`, String))
    catch
        "unreadable"
    end
    src_tree == SL_SRC_TREE || push!(cp, "src tree != reviewed")
    groups["comparator_code_pins"] = cp

    ci = String[]
    objectives = Dict{String, Any}()
    pub_value = nothing
    if isempty(cp) && length(raw2_snaps) == 3
        sw_iss, sw_snap = sl_pinned_snapshot(SL_PUB_SW, SL_PUB_SW_BYTES,
                                             SL_PUB_SW_SHA;
                                             label = "published SW32")
        append!(ci, sw_iss)
        lw_iss, lw_snap = sl_pinned_snapshot(SL_PUB_LW, SL_PUB_LW_BYTES,
                                             SL_PUB_LW_SHA;
                                             label = "published LW32")
        append!(ci, lw_iss)
        snapshot_cases = Any[]
        for (name, path, size, sha) in SL_CASE_INPUTS
            k_iss, k_snap = sl_pinned_snapshot(path, size, sha;
                                               label = "case input $name")
            append!(ci, k_iss)
            k_snap === nothing || push!(snapshot_cases,
                                        (case = name, path = k_snap))
        end
        if sw_snap !== nothing && lw_snap !== nothing &&
           length(snapshot_cases) == length(SL_CASE_INPUTS)
            try
                # every target scored TWICE in-ledger: exact in-run
                # repeatability required, plus bit-exact pinned values;
                # hist4515 is scored independently (never substituted
                # from array identity or a pinned constant alone)
                targets = vcat([(a, raw2_snaps[a], SL_OBJECTIVE_EXPECT)
                                for a in ("a0a", "a0b", "s1")],
                               [("hist4515", hist_snap, SL_OBJECTIVE_EXPECT),
                                ("published_selfcheck", lw_snap,
                                 SL_PUBLISHED_BASELINE)])
                for (label, snap, expected) in targets
                    v1 = sl_swap_objective(snap, sw_snap, snapshot_cases)
                    v2 = sl_swap_objective(snap, sw_snap, snapshot_cases)
                    v1 == v2 ||
                        push!(ci, "$label objective not repeatable " *
                                  "in-run ($v1 vs $v2)")
                    objectives[label] = v1
                    v1 == expected ||
                        push!(ci, "$label objective $v1 != pinned " *
                                  "$expected (bit-exact required)")
                end
                pub_value = get(objectives, "published_selfcheck", nothing)
            catch err
                push!(ci, "comparator evaluation failed: " *
                          sprint(showerror, err))
            end
        end
    else
        push!(ci, "comparator not run (code pins or raw2 evidence failed)")
    end
    groups["comparator_integrity"] = ci

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end
    status = gates["fixtures"] == "passed" ? sl_overall(groups) :
        "s1_completion_ledger_refused"

    scientific = Dict(
        "registered_branch_fired" => "A0a != A0b (raw2 file hashes): " *
            "byte-level treatment inference is INCONCLUSIVE because " *
            "baseline repeatability failed; S1 metrics are descriptive " *
            "only (committed matrix, verbatim)",
        "array_level_findings" => Dict(
            "scientific_variables" => "elementwise identical across " *
                "A0a, A0b, S1, AND the historical 4515 raw2 (gated in " *
                "this unit); nothing inferred from file hashes or " *
                "identical printed endpoints -- the array comparison " *
                "is the instrument",
            "metadata_differences" => attr_diffs,
            "baseline_repeatability_array_level" => "exact (A0a == A0b " *
                "elementwise)",
            "patch_association_array_level" => "the one-line sync patch " *
                "is associated with ZERO change in the serialized " *
                "scientific state in this run; per the committed " *
                "contract no claim is made that an extra final callback " *
                "executed (ensure_updated_state may find state already " *
                "current)",
            "historical_bridge_array_level" => "A0 arms match the " *
                "historical 4515 raw2 elementwise; the byte-level " *
                "bridge remains unlicensed (metadata differs), so " *
                "historical byte differences do not license " *
                "causal inference"),
        "census" => Dict(
            "definitions" => "active state = composite/h2o/o3/co2 " *
                "(n=152,640); lower effective where min>0; upper " *
                "effective where max>0; synthetic lower " *
                "init^3/max^2 where min==0 && init>0 && max>0; " *
                "nonpositive raw bounds excluded from denominators",
            "results" => census_results,
            "finding" => "identical for all arms and the historical " *
                "file: below 134/152,631, above 19/152,640, worst dlog " *
                "below 0.41887799902470135 / above 0.6268579421960787; " *
                "the serialized model effective-bound exceedances " *
                "PERSIST unchanged through the sync line"),
        "objectives" => Dict(
            "per_target" => objectives,
            "published_selfcheck" => pub_value,
            "pinned_value" => SL_OBJECTIVE_EXPECT,
            "finding" => "bit-exact equal across all three arms and " *
                "equal to the historical v1.2 raw2 reference " *
                "(22.791293464348826)"),
        "bounded_interpretation" => SL_BOUNDED_INTERP,
        "exceedance_event_sum_note" => SL_EVENT_SUM_NOTE,
        "interpretation_ceiling" => "BINDING CEILING (monitor, " *
            "2026-08-14): the exact claim set is -- file-byte branch " *
            "inconclusive due to arm-specific root metadata; all 47 " *
            "scientific variables elementwise identical; no observed " *
            "S1 scientific effect in THIS rebuilt paired trajectory. " *
            "ensure_updated_state(1) may execute zero refresh if state " *
            "is already current, and the historical 4515 bridge " *
            "remains conditional due to provenance. NO global " *
            "mechanism exclusion, NO retroactive inference, hashes are " *
            "NOT permanently retired campaign-wide, and synchronization " *
            "is NOT taken off the board.",
        "attribute_difference_explanation" => "the only OBSERVED NetCDF " *
            "LOGICAL differences are the root 'config' and 'history' " *
            "global attributes, which embed run-specific timestamps, " *
            "arm paths, and the optimize_lut_a0 vs optimize_lut_s1 " *
            "wrapper names. Literal NetCDF encoding/layout differences " *
            "remain unexamined; the raw file " *
            "hashes establish byte inequality but not localization of " *
            "every differing byte. The DURABLE instrument for this " *
            "claim is this unit's own gated NCDatasets logical " *
            "comparison over sha-pinned snapshots (monitor-side ncdump " *
            "header inspection was ephemeral cross-check tooling, not " *
            "pinned evidence)",
        "adept_source_observed_caveat" => "Adept implementation " *
            "statements are source-observed context only " *
            "(source-to-linked-binary provenance unproven): installed " *
            "Minimizer.h $SL_MINIMIZER_H_SHA, libadept " *
            "$SL_LIBADEPT_SHA, adept_source.h $SL_ADEPT_SOURCE_H_SHA; " *
            "shallow/shared-storage Vector pass-by-value means " *
            "minimizer updates reach the local x; only callbacks write " *
            "ckd_model.x; no direct write from local x to ckd_model " *
            "outside callbacks; default ensure_updated_state_=-1 " *
            "suppresses the conditional final callback; unpatched " *
            "ecckd has zero ensure_updated_state calls.")

    result = Dict(
        "case" => "gate4_s1_state_sync_completion_ledger",
        "data_mode" => "evidence_ledger_no_campaign_writes",
        "status" => status,
        "timestamp_utc" => SL_EVIDENCE_TIME,
        "evidence_timestamp_utc" => SL_EVIDENCE_TIME,
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "scientific" => scientific,
        "job" => Dict(
            "job_id" => 4558, "job_state" => "COMPLETED",
            "exit_code_raw" => "0:0", "run_time" => "01:53:10",
            "receipt_paths" => [SL_RECEIPT_S40, SL_RECEIPT_A42],
            "receipt_sha256" => SL_RECEIPT_SHA,
            "log_path" => SL_LOG, "log_sha256" => SL_LOG_SHA,
            "runroot_preserved" => SL_RUNROOT),
        "artifact_pins" => Dict(
            "raw2" => [Dict("arm" => a, "path" => p, "bytes" => sz,
                            "sha256" => sh) for (a, p, sz, sh) in SL_RAW2],
            "historical_raw2_sha256" => SL_HIST_RAW2_SHA,
            "init_sha256" => SL_INIT_SHA,
            "arm_logs" => [Dict("arm" => a, "sha256" => sh)
                           for (a, _, sh) in SL_ARM_LOGS],
            "binary_a0_sha256" => SL_BIN_A0[3],
            "binary_s1_sha256" => SL_BIN_S1[3],
            "solve_adept_orig_sha256" => SL_SRC_ORIG[2],
            "solve_adept_patched_sha256" => SL_SRC_PATCHED[2]),
        "reviewed" => Dict(
            "commit_ancestor" => SL_REVIEWED_COMMIT,
            "generator_source_sha256" => SL_GEN_SRC_SHA,
            "sbatch_sha256" => SL_SBATCH_SHA,
            "comparator_code_pins" => [Dict("path" => rel, "sha256" => sha)
                                       for (rel, sha) in SL_CODE_PINS],
            "reviewed_src_tree" => SL_SRC_TREE,
            "case_input_pins" => [Dict("case" => n, "bytes" => sz,
                                       "sha256" => sh)
                                  for (n, _, sz, sh) in SL_CASE_INPUTS],
            "adept_context_pins" => [
            Dict("path" => SL_MINIMIZER_H,
                 "sha256" => SL_MINIMIZER_H_SHA),
            Dict("path" => SL_LIBADEPT,
                 "sha256" => SL_LIBADEPT_SHA),
            Dict("path" => SL_ADEPT_SOURCE_H,
                 "sha256" => SL_ADEPT_SOURCE_H_SHA)],
            "published_lw_pin" => SL_PUB_LW_SHA,
            "published_sw_pin" => SL_PUB_SW_SHA,
            "h2o_mole_fraction" => SL_H2O),
        "non_authorizing_note" => "this ledger records and classifies " *
            "evidence; C1/C2 or any next experiment requires explicit " *
            "monitor rulings; zero canonical writes",
        "disclaimer" => "evidence ledger; writes nothing except its own " *
            "JSON/MD results plus transient private temp " *
            "fixtures/snapshots (mktempdir); zero campaign/canonical " *
            "writes.")

    mkpath(dirname(SL_RESULTS_JSON))
    open(SL_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(SL_RESULTS_MD, "w") do io
        println(io, "# Gate-4 S1 state-sync completion ledger (job 4558)\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "Registered branch fired: ",
                    scientific["registered_branch_fired"], "\n")
        println(io, "## Interpretation ceiling (binding)\n")
        println(io, scientific["interpretation_ceiling"], "\n")
        println(io, "## Decision-grade findings\n")
        println(io, "| Instrument | A0a | A0b | S1 | hist4515 |")
        println(io, "|---|---|---|---|---|")
        println(io, "| raw2 sha (byte channel) | df740e62 | 9c7796fd | " *
                    "95ac316f | 42054899 |")
        println(io, "| scientific arrays | identical | identical | " *
                    "identical | identical |")
        println(io, "| census below/above | 134/19 | 134/19 | 134/19 | " *
                    "134/19 |")
        println(io, "| objective | 22.791293464348826 | " *
                    "22.791293464348826 | 22.791293464348826 | " *
                    "22.791293464348826 |")
        println(io, "\n", scientific["bounded_interpretation"])
        println(io, "\n## Gates\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_s1_state_sync_completion_ledger: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "s1_run_completed_verified" ? 0 : 1
end

exit(main())
