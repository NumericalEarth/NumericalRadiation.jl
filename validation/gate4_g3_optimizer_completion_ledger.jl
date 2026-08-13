# Gate-4 G3 OPTIMIZER COMPLETION LEDGER (read-only evidence unit; writes
# NOTHING except validation/results/gate4_g3_run_ledger.{json,md}).
# Verifies jobs 4515 (LW) and 4516 (SW) -- the two authorized attempt-2
# submissions under the monitor's g3_recovery_go #2 -- against the pinned
# commit chain, the dual-custody scheduler receipts, the digest-bound job
# logs (full approved parser contract), and the canonical published
# outputs, and classifies fail-closed:
#   reviewed-complete      -- every evidence group green (exit 0); this is
#                             the exact status token both consumers
#                             (gate4_g1_objective_ratio.jl and
#                             gate4_g3_acceptance_comparison.jl) require
#   g3_run_ledger_refused  -- ANY discrepancy (exit 1); reasons enumerate
#                             every failed group; never a guess
#
# Provenance chain (monitor-approved parser contract + GO, 2026-08-13):
#   reviewed commit 559892b0 (Netlib remedy amendment) must be an ancestor
#   of HEAD; the committed executor source and both generated sbatch
#   scripts are byte-pinned; each band binds BOTH custody receipts
#   (session40 + agent42, independently captured create-once, byte-
#   identical this attempt), every contract receipt field by exact string,
#   the log by digest and then by the full parser contract (stage markers
#   0a-6 exactly once in order, READY exactly once, banner cardinality/
#   order, exact ordered covariance-group sequence with pinned sizes,
#   a-priori group counts, fraction-record counts, loader-resolution rows
#   with zero alias rows, publication + staged hash echoes exactly once,
#   exact done marker, zero failure markers, exact per-pass terminal
#   records), the canonical output by exact size + sha + the invariant
#   netCDF schema gate (fail-closed on any nonfinite value), and the
#   preserved RUNROOT staging by CONTENT (staged final exact size + live
#   sha == the canonical pin; every staged raw's live sha == its pinned
#   log echo), never by directory existence alone.
#
# PASS-STATUS FACTS (binding monitor correction, 2026-08-13; recorded
# exactly, NEVER summarized as "all passes converged"):
#   LW 4515: relative-base   Iteration 2999 cost 16.7768   Maximum iterations reached
#            relative-ch4    Iteration 2999 cost 1.83547   Maximum iterations reached
#            relative-n2o    Iteration 840  cost 0.417307  Converged
#            relative-cfc    Iteration 71   cost 0.023528  Converged
#   SW 4516: relative-base   Iteration 1999 cost 66.3659   Maximum iterations reached
#            relative-ch4    Iteration 203  cost 4.56198   Converged
#            relative-n2o    Iteration 132  cost 0.253514  Converged
# Iteration caps are the upstream optimizer's own terminal state (child
# exit 0, outputs written and published); binding scientific acceptance
# belongs to the downstream consumers (objective ratio, weight rel-L1),
# never to this ledger.
#
# Failure-marker regex note: the G2d ledger's case-insensitive \bERROR\b
# would falsely match the optimizer's benign "error covariance matrix"
# lines (12 in the LW log, 9 in the SW log). ERROR/FATAL/FAILED are
# matched CASE-SENSITIVELY here; the corrected regex was verified to have
# ZERO matches against both clean terminal logs before adoption.

include(joinpath(@__DIR__, "validation_results.jl"))

import JSON
using SHA: sha256
using NCDatasets

const GL_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
const GL_G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const GL_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"

const GL_REVIEWED_COMMIT = "559892b013efb13f7bf1f9280f8c383d0d682ba7"
const GL_EXEC_SRC = joinpath(GL_PROJECT_ROOT,
    "validation/gate4_g3_executor_checkpoint.jl")
const GL_EXEC_SRC_SHA = "18da8d72cf77a9eed8d8f58d433192ecb8a85e90a80e87e72b7176e05468bdf0"

# fixed evidence timestamp = max job EndTime (monitor rule: never wall-clock)
const GL_EVIDENCE_TIME = "2026-08-13T18:04:12Z"

const GL_SUBMIT_NOTE = "both jobs submitted EXACTLY ONCE by session 40 " *
    "directly under the monitor's g3_recovery_go #2 (2026-08-13; \"This " *
    "GO is for these two submissions only\"); no retries, Restarts=0 " *
    "bound from both receipts"

const GL_RECEIPT_NOTE = "dual-custody receipts: session 40's watcher and " *
    "Agent 42's watcher each captured scontrol show job -dd at first " *
    "terminal observation with atomic O_CREAT|O_EXCL (noclobber) " *
    "create-once semantics onto DISTINCT suffixed paths " *
    "(-session40 / -agent42); for this attempt the two captures are " *
    "byte-identical per band (equal pinned sha), unlike the 4503 " *
    "single-path overwrite incident this protocol was adopted to prevent"

# --- per-band evidence pins (exact, from both-terminal closure) ----------------

const GL_LDD_PRELOADS = [
    "/usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0",
    "/usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0",
    "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/tools/h5open_before_traps.so"]

const GL_READY_LINE = "gate4_g3_scoped_input_preflight: g3_scoped_preflight_ready"

# ERROR/FATAL/FAILED case-SENSITIVE (see header note); everything else as
# in the G2d ledger plus the G3 executor's own refusal/child markers and
# the attempt-1 SIGFPE signatures
const GL_FAILURE_RE = r"REFUSED|SCHEMA-INVALID|sha mismatch|MISSING/nonexecutable|[Qq]uota exceeded|CANCELLED|slurmstepd: error|Traceback \(most recent call last\)|\bERROR\b|\bFATAL\b|\bFAILED\b|CHILD KILLED|CHILD FAILED|SIGFPE|Floating point exception"

gl_stage_markers(band, gases) = [
    "=== G3-$band stage 0a: gate-code identity (verify BEFORE sourcing) ===",
    "=== G3-$band stage 0b: quota health (read-only; before controlled optimizer workspace/output allocation) ===",
    "=== G3-$band stage 0c: fresh scoped preflight must be READY (no-write mode; full diagnostics preserved) ===",
    "=== G3-$band stage 0d: band lock (acquired before campaign RUNROOT/input-snapshot/output mutation) ===",
    "=== G3-$band stage 0e: exact size+sha pin of EVERY optimizer input (originals) ===",
    "=== G3-$band stage 1: job-private RUNROOT + scientific-input snapshot ===",
    "=== G3-$band stage 2: optimizer wrapper inside RUNROOT (Netlib preload + FP-trap shim; env-only) ===",
    "=== G3-$band stage 2b: loader-resolution proof (SONAME + exact preload rows + zero alias rows) ===",
    "=== G3-$band stage 3: isolated testcopy inside RUNROOT (config overrides) ===",
    "=== G3-$band stage 4: staged optimizer ($gases; all writes under RUNROOT) ===",
    "=== G3-$band stage 5: staged outputs (hash echoes; nothing canonical yet) ===",
    "=== G3-$band stage 6: FINAL-ONLY atomic publish to the canonical path ==="]

gl_cov(size, gas) = "  Creating $(size)x$(size) error covariance matrix for $gas"

const GL_BANDS = Dict(
    "lw" => (
        job_id = 4515,
        job_name = "g4-g3-lw-optimizer",
        sbatch = joinpath(GL_PROJECT_ROOT,
            "validation/results/gate4_g3_lw_optimizer.sbatch"),
        sbatch_rel = "validation/results/gate4_g3_lw_optimizer.sbatch",
        sbatch_sha = "ccfa0d7c79b45aa203bf7c21582e13ea8eb4ebddc2da20defb4347bdb38c713e",
        receipt_session40 = "$GL_LOG_DIR/g4-g3-lw-4515-scontrol-final-session40.txt",
        receipt_agent42 = "$GL_LOG_DIR/g4-g3-lw-4515-scontrol-final-agent42.txt",
        receipt_sha = "34bcd96548993d48674dd91c7a69595e10ccdd567c10120038d8366cd59fcec1",
        log = "$GL_LOG_DIR/g4-g3-lw-4515.log",
        log_sha = "c0b840d6e1ab351538fd23908e6f7ea329d47cefb69d4b752b4da664cc856362",
        canonical = "$GL_G4WORK/work/lw_ckd-definition/ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc",
        output_bytes = 872004,
        output_sha = "a3d93d3eb4e69894862fad682563d25a5636e7dbbcc59c197ecaa1cceb6f24b4",
        runroot = "$GL_G4WORK/g3-runs/4515/lw",
        staged_final = "$GL_G4WORK/g3-runs/4515/lw/work/lw_ckd-definition/ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc",
        staged_raws = [
            ("4205489923dbc50c3c148a06f20e5781b3f1dbeb5a13d55d36b460c5f7b4378c",
             "$GL_G4WORK/g3-runs/4515/lw/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"),
            ("f95d613037f51ac13da964e28f449fde91cd1ec3e765fbdc75ee9868e92a1de7",
             "$GL_G4WORK/g3-runs/4515/lw/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw3-ckd-definition_climate_fsck-tol0.0161.nc"),
            ("6766fd8bc7d2bc56518ba41e2009e507b762ae499b9b188e3eae91a8b55f3c83",
             "$GL_G4WORK/g3-runs/4515/lw/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw4-ckd-definition_climate_fsck-tol0.0161.nc")],
        receipt_expect = Dict(
            "JobId" => "4515", "JobName" => "g4-g3-lw-optimizer",
            "JobState" => "COMPLETED", "Reason" => "None",
            "ExitCode" => "0:0", "DerivedExitCode" => "0:0",
            "Restarts" => "0", "RunTime" => "00:52:34",
            "TimeLimit" => "1-00:00:00",
            "SubmitTime" => "2026-08-13T17:09:05",
            "StartTime" => "2026-08-13T17:11:38",
            "EndTime" => "2026-08-13T18:04:12",
            "Command" => joinpath(GL_PROJECT_ROOT,
                "validation/results/gate4_g3_lw_optimizer.sbatch"),
            "SubmitLine" => "sbatch --parsable validation/results/gate4_g3_lw_optimizer.sbatch",
            "WorkDir" => GL_PROJECT_ROOT,
            "StdOut" => "$GL_LOG_DIR/g4-g3-lw-4515.log"),
        stages = gl_stage_markers("lw",
            "relative-base relative-ch4 relative-n2o relative-cfc"),
        done = "=== G3-lw done 2026-08-13T18:04:12Z ===",
        banners = [
            "Optimizing coefficients of: composite h2o o3 co2",
            "Optimizing coefficients of: ch4",
            "Optimizing coefficients of: n2o",
            "Optimizing coefficients of: cfc11 cfc12"],
        cov_sequence = [
            gl_cov(318, "COMPOSITE"), gl_cov(3816, "H2O"),
            gl_cov(318, "O3"), gl_cov(318, "CO2"), gl_cov(318, "CH4"),
            gl_cov(318, "N2O"), gl_cov(318, "CFC11"), gl_cov(318, "CFC12")],
        apriori_line = "Creating a-priori error covariance matrices with fixed error of 8",
        apriori_count = 4,
        fraction_base_count = 4,
        fraction_total = 8,
        pass_records = [
            ("Iteration 2999: cost function = 16.7768, gradient norm = 0.114057",
             "Convergence status: Maximum iterations reached"),
            ("Iteration 2999: cost function = 1.83547, gradient norm = 0.093339",
             "Convergence status: Maximum iterations reached"),
            ("Iteration 840: cost function = 0.417307, gradient norm = 0.000438281",
             "Convergence status: Converged"),
            ("Iteration 71: cost function = 0.023528, gradient norm = 0.000460102",
             "Convergence status: Converged")],
        pass_names = ["relative-base", "relative-ch4", "relative-n2o",
                      "relative-cfc"],
        band_dim = 1,
        extra_vars = ["planck_function", "gpoint_fraction"],
        abs_gases = ["cfc11", "cfc12", "ch4", "co2", "composite", "h2o",
                     "n2o", "o3"]),
    "sw" => (
        job_id = 4516,
        job_name = "g4-g3-sw-optimizer",
        sbatch = joinpath(GL_PROJECT_ROOT,
            "validation/results/gate4_g3_sw_optimizer.sbatch"),
        sbatch_rel = "validation/results/gate4_g3_sw_optimizer.sbatch",
        sbatch_sha = "464fe754e60f7581585bc096ac745932175c9abd4607e1b1364ae9fdc635228a",
        receipt_session40 = "$GL_LOG_DIR/g4-g3-sw-4516-scontrol-final-session40.txt",
        receipt_agent42 = "$GL_LOG_DIR/g4-g3-sw-4516-scontrol-final-agent42.txt",
        receipt_sha = "1aa2762a601e0822e277f996f8d461ac3b2d4201430829f447b8eb0160be09ce",
        log = "$GL_LOG_DIR/g4-g3-sw-4516.log",
        log_sha = "1d9e36f38bff047df2d1f409586071dd5003fa7d017fc7ed29b3b03b2f1a18de",
        canonical = "$GL_G4WORK/work-v14/sw_ckd-definition/ecckd-1.4_sw_ckd-definition_climate_rgb-tol0.047.nc",
        output_bytes = 854508,
        output_sha = "8b54392eeddd303299881d6405dcf3de4d738667a3dfe605964a64863e2fbee4",
        runroot = "$GL_G4WORK/g3-runs/4516/sw",
        staged_final = "$GL_G4WORK/g3-runs/4516/sw/work/sw_ckd-definition/ecckd-1.4_sw_ckd-definition_climate_rgb-tol0.047.nc",
        staged_raws = [
            ("b500fa55b2da11abaf61a74437f39f1eb4ff6dbd9574bd69ab57e544a855a086",
             "$GL_G4WORK/g3-runs/4516/sw/work/sw_raw-ckd-definition/ecckd-1.4_sw_raw2-ckd-definition_climate_rgb-tol0.047.nc"),
            ("3afef930690e1b4aef61b22e6e84103f62c37ce63579dcd1e46442e6188e7cb0",
             "$GL_G4WORK/g3-runs/4516/sw/work/sw_raw-ckd-definition/ecckd-1.4_sw_raw3-ckd-definition_climate_rgb-tol0.047.nc")],
        receipt_expect = Dict(
            "JobId" => "4516", "JobName" => "g4-g3-sw-optimizer",
            "JobState" => "COMPLETED", "Reason" => "None",
            "ExitCode" => "0:0", "DerivedExitCode" => "0:0",
            "Restarts" => "0", "RunTime" => "00:43:55",
            "TimeLimit" => "1-00:00:00",
            "SubmitTime" => "2026-08-13T17:09:16",
            "StartTime" => "2026-08-13T17:12:08",
            "EndTime" => "2026-08-13T17:56:03",
            "Command" => joinpath(GL_PROJECT_ROOT,
                "validation/results/gate4_g3_sw_optimizer.sbatch"),
            "SubmitLine" => "sbatch --parsable validation/results/gate4_g3_sw_optimizer.sbatch",
            "WorkDir" => GL_PROJECT_ROOT,
            "StdOut" => "$GL_LOG_DIR/g4-g3-sw-4516.log"),
        stages = gl_stage_markers("sw",
            "relative-base relative-ch4 relative-n2o"),
        done = "=== G3-sw done 2026-08-13T17:56:03Z ===",
        banners = [
            "Optimizing coefficients of: composite h2o o3 co2",
            "Optimizing coefficients of: ch4",
            "Optimizing coefficients of: n2o"],
        cov_sequence = [
            gl_cov(318, "COMPOSITE"), gl_cov(3816, "H2O"),
            gl_cov(318, "O3"), gl_cov(318, "CO2"), gl_cov(318, "CH4"),
            gl_cov(318, "N2O")],
        apriori_line = "Creating a-priori error covariance matrices with fixed error of 2",
        apriori_count = 3,
        fraction_base_count = 4,
        fraction_total = 6,
        pass_records = [
            ("Iteration 1999: cost function = 66.3659, gradient norm = 0.384829",
             "Convergence status: Maximum iterations reached"),
            ("Iteration 203: cost function = 4.56198, gradient norm = 0.000410846",
             "Convergence status: Converged"),
            ("Iteration 132: cost function = 0.253514, gradient norm = 0.000465887",
             "Convergence status: Converged")],
        pass_names = ["relative-base", "relative-ch4", "relative-n2o"],
        band_dim = 5,
        extra_vars = ["rayleigh_molar_scattering_coeff",
                      "solar_spectral_irradiance"],
        abs_gases = ["ch4", "co2", "composite", "h2o", "n2o", "o3"]))

const GL_RESULTS_JSON = validation_results_path("gate4_g3_run_ledger.json")
const GL_RESULTS_MD = validation_results_path("gate4_g3_run_ledger.md")

# --- primitives -----------------------------------------------------------------

gl_try_sha(path) = try
    isfile(path) || return nothing
    open(io -> bytes2hex(sha256(io)), path)
catch
    nothing
end

# --- receipt (scontrol) parse + exact binding -----------------------------------

const GL_TOKEN_KEYS = ("JobId", "JobName", "JobState", "Reason",
    "ExitCode", "DerivedExitCode", "Restarts", "RunTime", "TimeLimit",
    "SubmitTime", "StartTime", "EndTime")

function gl_parse_receipt(text)
    f = Dict{String, String}()
    for k in GL_TOKEN_KEYS
        m = match(Regex("\\b" * k * "=(\\S+)"), text)
        m === nothing || (f[k] = String(m.captures[1]))
    end
    for k in ("Command", "SubmitLine", "WorkDir", "StdOut")
        m = match(Regex("^\\s*" * k * "=(.*)\$", "m"), text)
        m === nothing || (f[k] = String(strip(m.captures[1])))
    end
    f
end

# EVERY expected field must match by EXACT string (no normpath relaxation)
function gl_receipt_issues(f, expect)
    iss = String[]
    for (k, v) in expect
        get(f, k, "") == v ||
            push!(iss, "$k mismatch (got $(repr(get(f, k, ""))))")
    end
    sort(iss)
end

# dual-custody group: BOTH receipts must exist at the SAME pinned sha
# (byte-identity via equal digest), and the parsed session40 fields must
# bind exactly; never touches (or distinguishes in favor of) either path
function gl_dual_receipt_group(p40, p42, pinned, expect)
    iss = String[]
    s40 = gl_try_sha(p40)
    s42 = gl_try_sha(p42)
    s40 === nothing && push!(iss, "session40 receipt missing/unreadable: $p40")
    s42 === nothing && push!(iss, "agent42 receipt missing/unreadable: $p42")
    isempty(iss) || return iss
    s40 == pinned || push!(iss, "session40 receipt sha $s40 != pinned $pinned")
    s42 == pinned || push!(iss, "agent42 receipt sha $s42 != pinned $pinned")
    isempty(iss) || return iss
    append!(iss, gl_receipt_issues(gl_parse_receipt(read(p40, String)), expect))
    iss
end

# --- pure log-contract checks (each fixture-testable) ---------------------------

gl_count(text, needle) = length(collect(eachmatch(
    Regex("\\Q" * needle * "\\E"), text)))

# ordered exactly-once markers (stages then done)
function gl_marker_issues(text, stages, done)
    iss = String[]
    lastpos = 0
    for s in stages
        n = gl_count(text, s)
        n == 1 || push!(iss, "stage marker not exactly once ($n): $s")
        p = findfirst(s, text)
        if p !== nothing
            first(p) > lastpos || push!(iss, "stage marker out of order: $s")
            lastpos = first(p)
        end
    end
    n = gl_count(text, done)
    n == 1 || push!(iss, "done marker not exactly once ($n)")
    p = findfirst(done, text)
    (p === nothing || first(p) > lastpos) ||
        push!(iss, "done marker out of order")
    iss
end

# ordered exactly-once line set (banners; covariance sequence)
function gl_sequence_issues(text, lines, label)
    iss = String[]
    lastpos = 0
    for l in lines
        n = gl_count(text, l)
        n == 1 || push!(iss, "$label not exactly once ($n): $l")
        p = findfirst(l, text)
        if p !== nothing
            first(p) > lastpos || push!(iss, "$label out of order: $l")
            lastpos = first(p)
        end
    end
    iss
end

# exact per-pass terminal records: the last "Iteration N:" line preceding
# each "Convergence status:" line, in order, must equal the pinned pairs
function gl_pass_records_observed(text)
    recs = Tuple{String, String}[]
    lastiter = ""
    for line in split(text, '\n')
        if occursin(r"^Iteration [0-9]+:", line)
            lastiter = String(line)
        elseif occursin(r"^Convergence status:", line)
            push!(recs, (lastiter, String(line)))
        end
    end
    recs
end

gl_pass_issues(text, expected) =
    gl_pass_records_observed(text) == collect(expected) ? String[] :
        ["per-pass terminal records != pinned expectation: observed " *
         repr(gl_pass_records_observed(text))]

# fraction-of-elements records: exact count inside the relative-base
# region (banner 1 .. banner 2) and exact total count
function gl_fraction_issues(text, banner1, banner2, base_n, total_n)
    iss = String[]
    total = length(collect(eachmatch(r"fraction of elements less than", text)))
    total == total_n ||
        push!(iss, "fraction records total $total != $total_n")
    p1 = findfirst(banner1, text)
    p2 = findfirst(banner2, text)
    if p1 === nothing || p2 === nothing || first(p2) <= last(p1)
        push!(iss, "relative-base region unresolvable for fraction census")
    else
        region = text[last(p1)+1:first(p2)-1]
        n = length(collect(eachmatch(r"fraction of elements less than", region)))
        n == base_n ||
            push!(iss, "fraction records in relative-base region $n != $base_n")
    end
    iss
end

# loader-resolution proof: exactly one absolute row per preload path
# token, in LD_PRELOAD order, and ZERO SONAME alias rows (SONAME-
# satisfying preloads leave no "libblas.so.3 =>"/"liblapack.so.3 =>" rows)
function gl_ldd_issues(text, preloads)
    iss = String[]
    lastpos = 0
    for p in preloads
        re = Regex("(?m)^\\s*\\Q" * p * "\\E \\(0x")
        ms = collect(eachmatch(re, text))
        length(ms) == 1 ||
            push!(iss, "preload row not exactly once ($(length(ms))): $p")
        if length(ms) == 1
            ms[1].offset > lastpos ||
                push!(iss, "preload row out of order: $p")
            lastpos = ms[1].offset
        end
    end
    n = length(collect(eachmatch(r"(?m)^\s*lib(blas|lapack)\.so\.3 =>", text)))
    n == 0 || push!(iss, "SONAME alias rows present ($n); preload did not " *
                         "satisfy DT_NEEDED directly")
    iss
end

# full per-band log contract over a digest-verified text
function gl_log_issues(text, b)
    iss = String[]
    append!(iss, gl_marker_issues(text, b.stages, b.done))
    n = gl_count(text, GL_READY_LINE)
    n == 1 || push!(iss, "READY line not exactly once ($n)")
    append!(iss, gl_sequence_issues(text, b.banners, "optimizer banner"))
    append!(iss, gl_sequence_issues(text, b.cov_sequence, "covariance group"))
    n = gl_count(text, b.apriori_line)
    n == b.apriori_count ||
        push!(iss, "a-priori group lines $n != $(b.apriori_count)")
    append!(iss, gl_fraction_issues(text, b.banners[1], b.banners[2],
                                    b.fraction_base_count, b.fraction_total))
    append!(iss, gl_pass_issues(text, b.pass_records))
    append!(iss, gl_ldd_issues(text, GL_LDD_PRELOADS))
    # publication line: unique canonical-path selector, exact sha
    n = gl_count(text, "$(b.output_sha)  $(b.canonical)")
    n == 1 || push!(iss, "canonical publication line not exactly once ($n)")
    npub = length(collect(eachmatch(
        Regex("(?m)^[0-9a-f]{64}  \\Q" * b.canonical * "\\E\$"), text)))
    npub == 1 ||
        push!(iss, "publication-line pattern not exactly once ($npub)")
    # staged final + raw echoes (stage 5), exact sha+path each
    n = gl_count(text, "$(b.output_sha)  $(b.staged_final)")
    n == 1 || push!(iss, "staged final hash echo not exactly once ($n)")
    for (sha, path) in b.staged_raws
        n = gl_count(text, "$sha  $path")
        n == 1 || push!(iss, "staged raw hash echo not exactly once ($n): $path")
    end
    m = match(GL_FAILURE_RE, text)
    m === nothing || push!(iss, "failure marker present: $(m.match)")
    iss
end

# --- invariant netCDF schema gate (coupled evidence read) ------------------------

const GL_STRUCTURAL_VARS = ["band_number", "wavenumber1_band",
    "wavenumber2_band", "wavenumber1", "wavenumber2"]

gl_all_finite(a) = !any(ismissing, a) && all(isfinite, skipmissing(a))

# invariant expectations (wavenumber / temperature_planck intentionally
# NOT hard-bound; structural_compatible in the acceptance unit stays
# authoritative for published-pair structural equality)
function gl_schema_issues_ds(ds, b)
    iss = String[]
    expdims = Dict("g_point" => 32, "pressure" => 53, "temperature" => 6,
                   "composite_gas" => 4, "h2o_mole_fraction" => 12,
                   "band" => b.band_dim)
    for (d, v) in expdims
        haskey(ds.dim, d) || (push!(iss, "dim missing: $d"); continue)
        ds.dim[d] == v || push!(iss, "dim $d = $(ds.dim[d]) != $v")
    end
    absvars = sort([String(k) for k in keys(ds)
                    if endswith(String(k), "_molar_absorption_coeff")])
    expabs = sort([g * "_molar_absorption_coeff" for g in b.abs_gases])
    absvars == expabs ||
        push!(iss, "absorption-coefficient variable census $(absvars) != " *
                   "$(expabs)")
    for v in vcat(expabs, b.extra_vars, GL_STRUCTURAL_VARS)
        haskey(ds, v) || (push!(iss, "var missing: $v"); continue)
        a = try
            Array(ds[v])
        catch
            push!(iss, "var unreadable: $v")
            continue
        end
        length(a) > 0 || push!(iss, "var empty: $v")
        et = eltype(a)
        numeric = (et <: Union{Missing, Real})
        numeric || (push!(iss, "var non-numeric: $v"); continue)
        gl_all_finite(a) || push!(iss, "var has nonfinite/missing values: $v")
    end
    iss
end

# coupled read: ONE byte read supplies the digest AND the parsed netCDF
# (a private snapshot written from the hashed bytes is what gets opened,
# so parsed content is exactly the hashed content)
function gl_schema_group(b)
    isfile(b.canonical) || return ["canonical output missing: $(b.canonical)"]
    bytes = try
        read(b.canonical)
    catch
        return ["canonical output unreadable: $(b.canonical)"]
    end
    length(bytes) == b.output_bytes ||
        return ["canonical output size $(length(bytes)) != $(b.output_bytes)"]
    sha = bytes2hex(sha256(bytes))
    sha == b.output_sha ||
        return ["canonical output sha $sha != pinned $(b.output_sha)"]
    snap = joinpath(mktempdir(), "snap_$(b.job_id).nc")
    write(snap, bytes)
    iss = try
        NCDataset(ds -> gl_schema_issues_ds(ds, b), snap)
    catch err
        ["canonical output not openable as netCDF: $(sprint(showerror, err))"]
    end
    rm(snap; force = true)
    iss
end

# --- RUNROOT staged-content group (monitor correction 2026-08-13) ----------------
# the preserved forensic staging must still hold the exact published
# bytes: staged final by exact size + live sha == the CANONICAL pin
# (publish proved byte-identity), every staged raw by live sha == its
# pinned stage-5 log echo; directory existence alone is never enough
function gl_runroot_group(b)
    isdir(b.runroot) ||
        return ["RUNROOT missing (forensics contract): $(b.runroot)"]
    iss = String[]
    if !isfile(b.staged_final)
        push!(iss, "staged final missing: $(b.staged_final)")
    else
        filesize(b.staged_final) == b.output_bytes ||
            push!(iss, "staged final size $(filesize(b.staged_final)) != " *
                       "$(b.output_bytes)")
        s = gl_try_sha(b.staged_final)
        s == b.output_sha ||
            push!(iss, "staged final sha $(something(s, "unreadable")) != " *
                       "canonical pin")
    end
    for (sha, path) in b.staged_raws
        if !isfile(path)
            push!(iss, "staged raw missing: $path")
        else
            s = gl_try_sha(path)
            s == sha ||
                push!(iss, "staged raw sha $(something(s, "unreadable")) " *
                           "!= pinned echo: $path")
        end
    end
    iss
end

# --- run-ledger consumer self-check ---------------------------------------------
# copied VERBATIM from gate4_g3_acceptance_comparison.jl:91-113 (that file
# ends in exit(main()) and must never be include()d); the ledger this unit
# writes must satisfy the consumers' own validator BEFORE it is written
hex64(x) = x isa AbstractString && occursin(r"^[0-9a-f]{64}$", x)

function validate_run_ledger(ld)
    get(ld, "case", "") == "gate4_g3_run_ledger" ||
        return (false, "case != gate4_g3_run_ledger")
    get(ld, "status", "") == "reviewed-complete" ||
        return (false, "status != reviewed-complete")
    jobs = get(ld, "jobs", nothing)
    jobs isa AbstractDict || return (false, "missing jobs section")
    for band in ("lw", "sw")
        j = get(jobs, band, nothing)
        j isa AbstractDict || return (false, "missing jobs.$band")
        jid = get(j, "job_id", nothing)
        jid_ok = (jid isa Integer && jid > 0) ||
            (jid isa AbstractString && occursin(r"^[0-9]+$", jid) &&
             tryparse(Int, jid) !== nothing && tryparse(Int, jid) > 0)
        jid_ok || return (false, "jobs.$band.job_id not a positive numeric id")
        get(j, "exit_code", -1) == 0 || return (false, "jobs.$band.exit_code != 0")
        for f in ("sbatch_sha256", "log_sha256", "output_sha256")
            hex64(get(j, f, "")) || return (false, "jobs.$band.$f not 64-hex")
        end
    end
    return (true, "ok")
end

# --- overall ---------------------------------------------------------------------

gl_overall(groups) = all(isempty, values(groups)) ?
    "reviewed-complete" : "g3_run_ledger_refused"

function gl_close_failed_gates!(fails, gates)
    bad = sort([k for (k, v) in gates if v != "passed"])
    isempty(bad) ||
        push!(fails, "failed gates (fail-closed census): " * join(bad, ", "))
end

# --- fixtures ---------------------------------------------------------------------

# synthetic minimal log satisfying the FULL per-band contract; mutations
# must each refuse through gl_log_issues
function gl_mklog(b)
    io = IOBuffer()
    println(io, b.stages[1])
    println(io, b.stages[2])
    println(io, b.stages[3])
    println(io, GL_READY_LINE)
    println(io, b.stages[4])
    println(io, b.stages[5])
    println(io, b.stages[6])
    println(io, b.stages[7])
    println(io, b.stages[8])
    for p in GL_LDD_PRELOADS
        println(io, "\t$p (0x00007f0000000000)")
    end
    println(io, b.stages[9])
    println(io, b.stages[10])
    for (i, banner) in enumerate(b.banners)
        println(io, banner)
        println(io, b.apriori_line)
        if i == 1
            for c in b.cov_sequence[1:4]
                println(io, c)
                println(io, "    fraction of elements less than 1e-06 is 0.9")
            end
        else
            println(io, b.cov_sequence[3 + i])
            println(io, "    fraction of elements less than 1e-06 is 0.9")
        end
        # LW cfc pass creates two covariance groups (CFC11+CFC12) but has
        # a single a-priori header; mirror by emitting the trailing group
        if i == length(b.banners) && length(b.cov_sequence) == 8
            println(io, b.cov_sequence[8])
            println(io, "    fraction of elements less than 1e-06 is 0.9")
        end
        println(io, b.pass_records[i][1])
        println(io, b.pass_records[i][2])
    end
    println(io, b.stages[11])
    for (sha, path) in b.staged_raws
        println(io, "$sha  $path")
    end
    println(io, "$(b.output_sha)  $(b.staged_final)")
    println(io, b.stages[12])
    println(io, "$(b.output_sha)  $(b.canonical)")
    println(io, b.done)
    String(take!(io))
end

# tiny netCDF fixture matching a reduced band-like spec (schema logic is
# parameterized by the spec, so fixtures never need full-size arrays)
function gl_mknc(path, spec; drop_var = nothing, poison_var = nothing,
                 wrong_dim = nothing)
    NCDataset(path, "c") do ds
        dims = Dict("g_point" => 32, "pressure" => 53, "temperature" => 6,
                    "composite_gas" => 4, "h2o_mole_fraction" => 12,
                    "band" => spec.band_dim)
        wrong_dim === nothing || (dims[wrong_dim] += 1)
        for (d, v) in dims
            defDim(ds, d, v)
        end
        allvars = vcat([g * "_molar_absorption_coeff" for g in spec.abs_gases],
                       spec.extra_vars, GL_STRUCTURAL_VARS)
        for v in allvars
            v == drop_var && continue
            var = defVar(ds, v, Float64, ("g_point",))
            var[:] = fill(v == poison_var ? NaN : 1.0, 32)
        end
    end
    path
end

function gl_fixtures()
    t = Dict{String, Bool}()
    fx = mktempdir()
    shaof(p) = bytes2hex(sha256(read(p)))
    lw = GL_BANDS["lw"]
    sw = GL_BANDS["sw"]

    # receipt binding: synthetic receipt from the expectation table
    mkreceipt(b, over...) = begin
        e = Dict{String, String}(b.receipt_expect)
        for (k, v) in over
            e[k] = v
        end
        "JobId=$(e["JobId"]) JobName=$(e["JobName"])\n" *
        "   JobState=$(e["JobState"]) Reason=$(e["Reason"]) Dependency=(null)\n" *
        "   Requeue=1 Restarts=$(e["Restarts"]) BatchFlag=1 ExitCode=$(e["ExitCode"])\n" *
        "   DerivedExitCode=$(e["DerivedExitCode"])\n" *
        "   RunTime=$(e["RunTime"]) TimeLimit=$(e["TimeLimit"]) TimeMin=N/A\n" *
        "   SubmitTime=$(e["SubmitTime"]) EligibleTime=$(e["SubmitTime"])\n" *
        "   StartTime=$(e["StartTime"]) EndTime=$(e["EndTime"]) Deadline=N/A\n" *
        "   Command=$(e["Command"])\n" *
        "   SubmitLine=$(e["SubmitLine"])\n" *
        "   WorkDir=$(e["WorkDir"])\n" *
        "   StdOut=$(e["StdOut"])\n"
    end
    ri(b, txt) = gl_receipt_issues(gl_parse_receipt(txt), b.receipt_expect)
    for (band, b) in (("lw", lw), ("sw", sw))
        t["receipt_$(band)_good_binds"] = isempty(ri(b, mkreceipt(b)))
    end
    t["receipt_wrong_state_refuses"] =
        !isempty(ri(lw, mkreceipt(lw, "JobState" => "FAILED")))
    t["receipt_nonzero_exit_refuses"] =
        !isempty(ri(lw, mkreceipt(lw, "ExitCode" => "1:0")))
    t["receipt_nonzero_derived_refuses"] =
        !isempty(ri(lw, mkreceipt(lw, "DerivedExitCode" => "1:0")))
    t["receipt_restarts_refuses"] =
        !isempty(ri(lw, mkreceipt(lw, "Restarts" => "1")))
    t["receipt_jobid_refuses"] =
        !isempty(ri(lw, mkreceipt(lw, "JobId" => "9999")))
    t["receipt_jobname_refuses"] =
        !isempty(ri(lw, mkreceipt(lw, "JobName" => "g4-g3-lw")))
    t["receipt_submitline_injection_refuses"] =
        !isempty(ri(lw, mkreceipt(lw, "SubmitLine" =>
            "sbatch --parsable --export=X=1 " * lw.sbatch_rel)))
    t["receipt_workdir_refuses"] =
        !isempty(ri(lw, mkreceipt(lw, "WorkDir" => "/tmp")))
    t["receipt_stdout_refuses"] =
        !isempty(ri(lw, mkreceipt(lw, "StdOut" => "/tmp/x.log")))
    t["receipt_runtime_refuses"] =
        !isempty(ri(lw, mkreceipt(lw, "RunTime" => "23:59:59")))
    t["receipt_endtime_refuses"] =
        !isempty(ri(lw, mkreceipt(lw, "EndTime" => "2026-08-13T00:00:00")))

    # dual-custody group on tmp files: identical good pair accepted;
    # missing / divergent / drifted refuse
    r40 = joinpath(fx, "r40.txt"); write(r40, mkreceipt(lw))
    r42 = joinpath(fx, "r42.txt"); write(r42, mkreceipt(lw))
    rbad = joinpath(fx, "rbad.txt")
    write(rbad, mkreceipt(lw, "EndTime" => "2026-08-13T00:00:00"))
    t["dual_receipt_identical_good"] =
        isempty(gl_dual_receipt_group(r40, r42, shaof(r40), lw.receipt_expect))
    t["dual_receipt_missing_refuses"] =
        !isempty(gl_dual_receipt_group(joinpath(fx, "no.txt"), r42,
                                       shaof(r42), lw.receipt_expect))
    t["dual_receipt_divergent_refuses"] =
        !isempty(gl_dual_receipt_group(r40, rbad, shaof(r40),
                                       lw.receipt_expect))
    t["dual_receipt_pin_drift_refuses"] =
        !isempty(gl_dual_receipt_group(r40, r42, "0" ^ 64, lw.receipt_expect))

    # full log contract: both synthetic band logs accepted, mutations refuse
    for (band, b) in (("lw", lw), ("sw", sw))
        good = gl_mklog(b)
        t["log_$(band)_good_accepted"] = isempty(gl_log_issues(good, b))
        t["log_$(band)_missing_stage_refuses"] =
            !isempty(gl_log_issues(replace(good, b.stages[10] * "\n" => ""), b))
        t["log_$(band)_missing_ready_refuses"] =
            !isempty(gl_log_issues(replace(good, GL_READY_LINE => "not ready"), b))
        t["log_$(band)_missing_banner_refuses"] =
            !isempty(gl_log_issues(replace(good,
                b.banners[end] * "\n" => ""), b))
        t["log_$(band)_missing_cov_refuses"] =
            !isempty(gl_log_issues(replace(good,
                b.cov_sequence[end] * "\n" => ""), b))
        t["log_$(band)_missing_publication_refuses"] =
            !isempty(gl_log_issues(replace(good,
                "$(b.output_sha)  $(b.canonical)" => ""), b))
        t["log_$(band)_pass_status_drift_refuses"] =
            !isempty(gl_log_issues(replace(good,
                "Convergence status: Converged" =>
                "Convergence status: Maximum iterations reached"), b))
    end
    good = gl_mklog(lw)
    t["log_stage_out_of_order_refuses"] =
        !isempty(gl_marker_issues(lw.stages[2] * "\n" *
            replace(good, lw.stages[2] * "\n" => ""), lw.stages, lw.done))
    t["log_duplicate_done_refuses"] =
        !isempty(gl_log_issues(good * lw.done * "\n", lw))
    t["log_duplicate_publication_refuses"] =
        !isempty(gl_log_issues(good *
            "$(lw.output_sha)  $(lw.canonical)\n", lw))
    t["log_wrong_publication_sha_refuses"] =
        !isempty(gl_log_issues(replace(good,
            "$(lw.output_sha)  $(lw.canonical)" =>
            ("f" ^ 64) * "  $(lw.canonical)"), lw))
    t["log_missing_staged_echo_refuses"] =
        !isempty(gl_log_issues(replace(good,
            "$(lw.staged_raws[1][1])  $(lw.staged_raws[1][2])\n" => ""), lw))
    t["log_apriori_count_refuses"] =
        !isempty(gl_log_issues(good * lw.apriori_line * "\n", lw))
    t["log_fraction_total_refuses"] =
        !isempty(gl_log_issues(good *
            "    fraction of elements less than 1e-06 is 0.9\n", lw))
    t["log_banner_out_of_order_refuses"] =
        !isempty(gl_sequence_issues(lw.banners[2] * "\n" * good,
                                    lw.banners, "banner"))
    t["log_cov_out_of_order_refuses"] =
        !isempty(gl_sequence_issues(lw.cov_sequence[2] * "\n" * good,
                                    lw.cov_sequence, "cov"))
    # failure markers: executor/child/signal forms refuse; UPPERCASE
    # ERROR refuses while the optimizer's benign lowercase "error
    # covariance" lines (present in every good fixture log) are accepted
    for (name, marker) in (("refused", "REFUSED: gate 12"),
                           ("child_killed", "CHILD KILLED by signal 8"),
                           ("child_failed", "CHILD FAILED rc=1"),
                           ("sigfpe", "SIGFPE"),
                           ("fpe", "Floating point exception"),
                           ("uppercase_error", "ERROR: boom"),
                           ("uppercase_failed", "job FAILED"),
                           ("traceback", "Traceback (most recent call last):"),
                           ("quota", "Disk quota exceeded"),
                           ("slurmstepd", "slurmstepd: error: x"))
        t["log_marker_$(name)_refuses"] =
            !isempty(gl_log_issues(good * marker * "\n", lw))
    end
    t["log_lowercase_error_covariance_accepted"] =
        match(GL_FAILURE_RE,
              "Creating a-priori error covariance matrices\n") === nothing

    # ldd contract
    lddgood = join(["\t$p (0x0)" for p in GL_LDD_PRELOADS], "\n") * "\n"
    t["ldd_good_accepted"] = isempty(gl_ldd_issues(lddgood, GL_LDD_PRELOADS))
    t["ldd_missing_row_refuses"] =
        !isempty(gl_ldd_issues(replace(lddgood,
            "\t$(GL_LDD_PRELOADS[1]) (0x0)\n" => ""), GL_LDD_PRELOADS))
    t["ldd_out_of_order_refuses"] =
        !isempty(gl_ldd_issues("\t$(GL_LDD_PRELOADS[2]) (0x0)\n" *
            "\t$(GL_LDD_PRELOADS[1]) (0x0)\n" *
            "\t$(GL_LDD_PRELOADS[3]) (0x0)\n", GL_LDD_PRELOADS))
    t["ldd_alias_row_refuses"] =
        !isempty(gl_ldd_issues(lddgood *
            "\tlibblas.so.3 => /usr/lib/x86_64-linux-gnu/libblas.so.3 (0x0)\n",
            GL_LDD_PRELOADS))

    # pass-record extraction is positional and exact
    t["pass_records_extracted_in_order"] =
        gl_pass_records_observed("Iteration 1: cost function = 2, x\n" *
            "junk\nConvergence status: Converged\n" *
            "Iteration 9: cost function = 1, x\n" *
            "Convergence status: Maximum iterations reached\n") ==
        [("Iteration 1: cost function = 2, x", "Convergence status: Converged"),
         ("Iteration 9: cost function = 1, x",
          "Convergence status: Maximum iterations reached")]

    # schema gate on tiny fixture files (checker logic is parameterized;
    # full-size dims stay bound through the same code path in main)
    spec = (band_dim = 2,
            extra_vars = ["planck_function"],
            abs_gases = ["h2o", "o3"])
    ncgood = gl_mknc(joinpath(fx, "good.nc"), spec)
    run_schema(p) = NCDataset(ds -> gl_schema_issues_ds(ds, spec), p)
    t["schema_good_accepted"] = begin
        iss = run_schema(ncgood)
        # only the full-size dims differ on the fixture; band matches
        all(i -> startswith(i, "dim "), iss) &&
            !any(i -> occursin("band", i), iss)
    end
    t["schema_missing_var_refuses"] =
        any(i -> i == "var missing: planck_function",
            run_schema(gl_mknc(joinpath(fx, "drop.nc"), spec;
                               drop_var = "planck_function")))
    t["schema_nonfinite_refuses"] =
        any(i -> i == "var has nonfinite/missing values: h2o_molar_absorption_coeff",
            run_schema(gl_mknc(joinpath(fx, "nan.nc"), spec;
                               poison_var = "h2o_molar_absorption_coeff")))
    t["schema_wrong_band_dim_refuses"] =
        any(i -> occursin("dim band", i),
            run_schema(gl_mknc(joinpath(fx, "dim.nc"), spec;
                               wrong_dim = "band")))
    t["schema_extra_absvar_census_refuses"] =
        any(i -> occursin("variable census", i),
            run_schema(gl_mknc(joinpath(fx, "extra.nc"),
                (band_dim = 2, extra_vars = ["planck_function"],
                 abs_gases = ["h2o", "o3", "co2"]))))

    # coupled schema group refusals (size/sha/missing) via a band-like
    # spec pointing at tmp paths
    fake = (job_id = 0, canonical = ncgood,
            output_bytes = filesize(ncgood), output_sha = shaof(ncgood),
            band_dim = 2, extra_vars = ["planck_function"],
            abs_gases = ["h2o", "o3"])
    t["schema_group_size_drift_refuses"] =
        gl_schema_group(merge_nt(fake, (output_bytes = 1,))) ==
        ["canonical output size $(filesize(ncgood)) != 1"]
    t["schema_group_sha_drift_refuses"] =
        !isempty(gl_schema_group(merge_nt(fake, (output_sha = "0" ^ 64,))))
    t["schema_group_missing_refuses"] =
        !isempty(gl_schema_group(merge_nt(fake,
            (canonical = joinpath(fx, "absent.nc"),))))

    # RUNROOT staged-content group on tmp trees (monitor correction):
    # content is verified, never directory existence alone
    rr = joinpath(fx, "runroot"); mkpath(rr)
    sf = joinpath(rr, "final.nc"); write(sf, "FINALBYTES")
    rw = joinpath(rr, "raw2.nc"); write(rw, "RAWBYTES")
    rspec(; kw...) = merge_nt((runroot = rr, staged_final = sf,
        output_bytes = filesize(sf), output_sha = shaof(sf),
        staged_raws = [(shaof(rw), rw)]), NamedTuple(kw))
    t["runroot_contents_good_accepted"] = isempty(gl_runroot_group(rspec()))
    t["runroot_missing_dir_refuses"] =
        !isempty(gl_runroot_group(rspec(runroot = joinpath(fx, "norr"))))
    t["runroot_staged_final_missing_refuses"] =
        !isempty(gl_runroot_group(rspec(
            staged_final = joinpath(rr, "absent.nc"))))
    t["runroot_staged_final_size_drift_refuses"] =
        !isempty(gl_runroot_group(rspec(output_bytes = 1)))
    t["runroot_staged_final_sha_drift_refuses"] =
        !isempty(gl_runroot_group(rspec(output_sha = "0" ^ 64)))
    t["runroot_raw_missing_refuses"] =
        !isempty(gl_runroot_group(rspec(
            staged_raws = [(shaof(rw), joinpath(rr, "noraw.nc"))])))
    t["runroot_raw_sha_drift_refuses"] =
        !isempty(gl_runroot_group(rspec(staged_raws = [("0" ^ 64, rw)])))

    # run-ledger consumer self-check fixtures (verbatim validator)
    goodjobs = Dict(
        "case" => "gate4_g3_run_ledger", "status" => "reviewed-complete",
        "jobs" => Dict(
            "lw" => Dict("job_id" => 4515, "exit_code" => 0,
                         "sbatch_sha256" => "a" ^ 64,
                         "log_sha256" => "b" ^ 64,
                         "output_sha256" => "c" ^ 64),
            "sw" => Dict("job_id" => 4516, "exit_code" => 0,
                         "sbatch_sha256" => "d" ^ 64,
                         "log_sha256" => "e" ^ 64,
                         "output_sha256" => "f" ^ 64)))
    deep(d) = JSON.parse(JSON.json(d))
    t["ledger_selfcheck_good"] = validate_run_ledger(deep(goodjobs))[1]
    bad = deep(goodjobs); bad["status"] = "g3_run_ledger_refused"
    t["ledger_selfcheck_bad_status_refuses"] = !validate_run_ledger(bad)[1]
    bad = deep(goodjobs); bad["jobs"]["lw"]["exit_code"] = "0:0"
    t["ledger_selfcheck_raw_exit_refuses"] = !validate_run_ledger(bad)[1]
    bad = deep(goodjobs); bad["jobs"]["sw"]["output_sha256"] = "xyz"
    t["ledger_selfcheck_bad_hex_refuses"] = !validate_run_ledger(bad)[1]
    bad = deep(goodjobs); delete!(bad["jobs"], "sw")
    t["ledger_selfcheck_missing_band_refuses"] = !validate_run_ledger(bad)[1]

    # overall composition
    t["overall_all_green"] =
        gl_overall(Dict("a" => String[], "b" => String[])) ==
        "reviewed-complete"
    t["overall_any_issue_refuses"] =
        gl_overall(Dict("a" => String[], "b" => ["x"])) ==
        "g3_run_ledger_refused"
    t
end

# NamedTuple merge helper for fixtures (Base.merge on NamedTuples)
merge_nt(nt, over) = merge(nt, over)

# --- main -------------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()

    tests = gl_fixtures()
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    groups = Dict{String, Vector{String}}()

    anc = try
        success(`git -C $GL_PROJECT_ROOT merge-base --is-ancestor $GL_REVIEWED_COMMIT HEAD`)
    catch; false end
    groups["commit_ancestry"] = anc ? String[] :
        ["reviewed commit $GL_REVIEWED_COMMIT is not an ancestor of HEAD"]
    src_sha = gl_try_sha(GL_EXEC_SRC)
    groups["executor_source_pin"] = src_sha == GL_EXEC_SRC_SHA ?
        String[] : ["executor source sha $(something(src_sha, "unreadable")) != pinned"]

    for band in ("lw", "sw")
        b = GL_BANDS[band]
        sb_sha = gl_try_sha(b.sbatch)
        groups["$(band)_sbatch_pin"] = sb_sha == b.sbatch_sha ? String[] :
            ["sbatch sha $(something(sb_sha, "unreadable")) != pinned"]
        groups["$(band)_dual_receipts"] = gl_dual_receipt_group(
            b.receipt_session40, b.receipt_agent42, b.receipt_sha,
            b.receipt_expect)
        log_issues = String[]
        log_sha = gl_try_sha(b.log)
        if log_sha != b.log_sha
            push!(log_issues, "log sha $(something(log_sha, "unreadable")) " *
                              "!= pinned $(b.log_sha)")
        else
            append!(log_issues, gl_log_issues(read(b.log, String), b))
        end
        groups["$(band)_terminal_log"] = log_issues
        groups["$(band)_canonical_output"] = gl_schema_group(b)
        groups["$(band)_runroot_contents"] = gl_runroot_group(b)
    end

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end

    status = gates["fixtures"] == "passed" ? gl_overall(groups) :
        "g3_run_ledger_refused"

    # jobs section: raw fields exactly as bound (integer exit_code for the
    # consumer contract; raw Slurm strings kept separately)
    jobs = Dict{String, Any}()
    for band in ("lw", "sw")
        b = GL_BANDS[band]
        jobs[band] = Dict{String, Any}(
            "job_id" => b.job_id,
            "job_name" => b.job_name,
            "exit_code" => 0,
            "exit_code_raw" => "0:0",
            "derived_exit_code_raw" => "0:0",
            "job_state" => "COMPLETED",
            "restarts" => 0,
            "sbatch_path" => b.sbatch_rel,
            "sbatch_sha256" => b.sbatch_sha,
            "log_path" => b.log,
            "log_sha256" => b.log_sha,
            "output_path" => b.canonical,
            "output_bytes" => b.output_bytes,
            "output_sha256" => b.output_sha,
            "receipt_paths" => [b.receipt_session40, b.receipt_agent42],
            "receipt_sha256" => b.receipt_sha,
            "submit_line" => b.receipt_expect["SubmitLine"],
            "submit_time" => b.receipt_expect["SubmitTime"],
            "start_time" => b.receipt_expect["StartTime"],
            "end_time" => b.receipt_expect["EndTime"],
            "run_time" => b.receipt_expect["RunTime"],
            "done_marker" => b.done,
            "runroot_preserved" => b.runroot,
            "staged_final_sha256" => b.output_sha,
            "staged_raw_echoes" => [Dict("sha256" => s, "path" => p)
                                    for (s, p) in b.staged_raws],
            "pass_status" => [Dict(
                    "pass" => b.pass_names[i],
                    "final_iteration_line" => b.pass_records[i][1],
                    "convergence_status_line" => b.pass_records[i][2])
                for i in 1:length(b.pass_records)])
    end

    # the written ledger must satisfy the consumers' VERBATIM validator
    # before it is written (self-check through a JSON round trip)
    candidate = Dict("case" => "gate4_g3_run_ledger", "status" => status,
                     "jobs" => jobs)
    if status == "reviewed-complete"
        vok, vreason = validate_run_ledger(JSON.parse(JSON.json(candidate)))
        gates["consumer_validator_selfcheck"] = vok ? "passed" : "failed"
        if !vok
            push!(fails, "written ledger fails consumer validator: $vreason")
            status = "g3_run_ledger_refused"
        end
    else
        gates["consumer_validator_selfcheck"] = "not-run (refused ledger)"
    end
    gl_close_failed_gates!(fails, gates)

    result = Dict(
        "case" => "gate4_g3_run_ledger",
        "data_mode" => "read_only_evidence_ledger",
        "status" => status,
        # conventional top-level timestamp is the SAME fixed evidence time
        # (deterministic; downstream semantic reruns exclude only
        # timestamp_utc as contracted)
        "timestamp_utc" => GL_EVIDENCE_TIME,
        "evidence_timestamp_utc" => GL_EVIDENCE_TIME,
        "evidence_timestamp_rule" => "fixed at max job EndTime " *
            "(2026-08-13T18:04:12Z, job 4515); never wall-clock, so " *
            "double runs are byte-identical",
        "jobs" => jobs,
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "reviewed" => Dict(
            "commit_ancestor" => GL_REVIEWED_COMMIT,
            "executor_source_sha256" => GL_EXEC_SRC_SHA,
            "submission_note" => GL_SUBMIT_NOTE,
            "receipt_custody_note" => GL_RECEIPT_NOTE),
        "pass_status_note" => "PASS-STATUS FACTS (binding monitor " *
            "correction 2026-08-13): LW relative-base and relative-ch4 " *
            "terminated at the optimizer's iteration cap (Iteration 2999, " *
            "\"Maximum iterations reached\"), as did SW relative-base " *
            "(Iteration 1999); only LW relative-n2o (840) / relative-cfc " *
            "(71) and SW relative-ch4 (203) / relative-n2o (132) report " *
            "\"Converged\". It is NEVER claimed that all passes " *
            "explicitly converged. Iteration caps are the upstream " *
            "optimizer's own terminal state (child exit 0, outputs " *
            "written); binding scientific acceptance belongs to the " *
            "downstream consumers (G1 objective ratio, weight rel-L1).",
        "non_authorizing_note" => "this ledger records and classifies " *
            "evidence; it does not itself submit, publish, or accept the " *
            "recovered models -- downstream consumers must bind this " *
            "artifact (exact case/status/schema) rather than assume " *
            "progression from its existence",
        "disclaimer" => "read-only evidence ledger; writes nothing " *
            "except its own JSON/MD results.")

    mkpath(dirname(GL_RESULTS_JSON))
    open(GL_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(GL_RESULTS_MD, "w") do io
        println(io, "# Gate-4 G3 optimizer run ledger\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "Evidence timestamp (fixed, = max EndTime): " *
                    "$GL_EVIDENCE_TIME\n")
        println(io, "| Band | Job | State | Exit | RunTime | Output sha256 |")
        println(io, "|---|---|---|---|---|---|")
        for band in ("lw", "sw")
            j = jobs[band]
            println(io, "| $band | $(j["job_id"]) | $(j["job_state"]) | " *
                        "$(j["exit_code_raw"]) | $(j["run_time"]) | " *
                        "`$(j["output_sha256"])` |")
        end
        println(io, "\n## Pass status (exact facts; never \"all converged\")\n")
        println(io, "| Band | Pass | Terminal record |")
        println(io, "|---|---|---|")
        for band in ("lw", "sw")
            for p in jobs[band]["pass_status"]
                println(io, "| $band | $(p["pass"]) | " *
                            "$(p["final_iteration_line"]) -> " *
                            "$(p["convergence_status_line"]) |")
            end
        end
        println(io, "\n", result["pass_status_note"])
        println(io, "\n## Gates\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nReceipt custody: ", GL_RECEIPT_NOTE)
        println(io, "\nSubmission: ", GL_SUBMIT_NOTE)
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_g3_optimizer_completion_ledger: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "reviewed-complete" ? 0 : 1
end

exit(main())
