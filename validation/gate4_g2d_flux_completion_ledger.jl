# Gate-4 G2d FLUX COMPLETION LEDGER (read-only evidence unit; writes
# NOTHING except its own JSON/MD results). Verifies job 4503 -- the
# single registered reviewed G2d attempt -- against the pinned
# checkpoint provenance chain, the scheduler termination receipt, the
# digest-bound job log, and the live outputs/installs, and classifies
# fail-closed:
#   g2d_flux_completed_verified  -- every evidence group green (exit 0)
#   g2d_flux_ledger_refused      -- ANY discrepancy (exit 1); reasons
#     enumerate every failed group; never a guess
#
# Provenance chain (monitor-specified bounded contract, 2026-08-13):
#   reviewed commit dec274d8 must be an ancestor of HEAD; the committed
#   checkpoint source, checkpoint JSON (case/status/sha), and generated
#   sbatch are byte-pinned; the attempt registry binds job 4503 to the
#   exact SubmitLine, termination receipt, and log digest; the log must
#   show stages 0-6 exactly once in order with the exact done timestamp,
#   the 70/70 preflight marker, zero failure markers, and the exact
#   path+hash echo for every artifact; live LW/SW outputs must be
#   byte-identical exact-size/sha copies passing the FULL schema
#   validator extracted from the sha-pinned committed sbatch (never
#   open/size-only); the five rayleigh finals must match exact
#   names/sizes/log-echoed hashes and full schema/grid equality against
#   their H2O sources; work-eval2 must hold exactly the two finals with
#   zero RAW/.g2dtmp/.g2d.install/.g2d.ray residue. The quota row is an
#   informational observation, never completion truth.
#
# RECEIPT EVIDENCE (final dual-evidence ruling, monitor 2026-08-13):
# the termination record was first captured at 2026-08-13T14:57:48
# (full receipt sha 59d79073..., disclosed) and overwritten at 14:59:22
# by session 40's re-capture of the same completed job. BOTH surviving
# evidence files are digest-bound below: the current full receipt
# (7328195a..., evidence A) and the preserved original watcher output
# (aaeed4d4..., evidence B); common fields are cross-checked exactly,
# and the two FULL receipts are never claimed byte/field-identical.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON
using SHA: sha256

const FL_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
const FL_G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const FL_E2SW = "/shared/home/greg/data/ckdmip/evaluation2/sw_spectra"
const FL_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"
const FL_JOB_NAME = "g4-g2d-eval2-rel415"

const FL_REVIEWED_COMMIT = "dec274d87efde77586903a705b288e1cb2b0aea7"
const FL_CKPT_SRC = joinpath(FL_PROJECT_ROOT,
    "validation/gate4_g2d_eval2_rel415_flux_checkpoint.jl")
const FL_CKPT_SRC_SHA = "38f666f23b10693752bdae83bca08ee765dc69fd8ecde3c1f11b7edae66f1b18"
const FL_CKPT_JSON = validation_results_path("gate4_g2d_eval2_rel415_flux_checkpoint.json")
const FL_CKPT_CASE = "gate4_g2d_eval2_rel415_flux_checkpoint"
const FL_CKPT_STATUS = "g2d_checkpoint_ready"
const FL_CKPT_JSON_SHA = "826e08828e863389f0ae10fd2e69a731032608f47cd8e67fc7965236ddd5ad60"
const FL_SBATCH = validation_results_path("gate4_g2d_eval2_rel415_flux.sbatch")
const FL_SBATCH_SHA = "06c1a97d49e289cb29a462bb1f1fb750d650c170f6aab8d5ab333568f7e2329d"

# single registered reviewed attempt; TWO terminal evidence files bound
# (monitor ruling 2026-08-13, no weakening):
#   (A) the current full scheduler receipt (7328195a..., session 40's
#       14:59:22 re-capture) binds JobId/Name, SubmitTime, exact
#       paths/SubmitLine and every contract-required field it carries
#   (B) the preserved ORIGINAL 14:57:48 watcher output (aaeed4d4...,
#       mode 0444) binds the exact terminal-capture timestamp plus
#       JobState/Reason/ExitCode/DerivedExitCode/Restarts/runtime/limit/
#       start/end/Command/SubmitLine/StdOut and the done/hash tail
# Common fields are cross-checked exactly. The original full receipt
# (59d79073...) and the 14:59:22 overwrite remain disclosed; the two
# full receipts are NOT claimed byte- or field-identical.
const FL_RECEIPT = "$FL_LOG_DIR/g4-g2d-4503-scontrol-final.txt"
const FL_RECEIPT_SHA = "7328195aa860961ab04df7b77b4a6aa7c29ff87fb0ad8047beeeb9de22d3560f"
const FL_ORIGINAL_RECEIPT_SHA = "59d7907353f0a3470b03038ede9f28048d7b7a8f2dcdb161a2219368f240e346"
const FL_MON = "$FL_LOG_DIR/g4-g2d-4503-terminal-monitor-output.txt"
const FL_MON_SHA = "aaeed4d49efdbe5987bfb4803b542969de9986801951e458e8e183f4abf12e31"
const FL_MON_CAPLINE = "JOB-4503-TERMINATED at 2026-08-13T14:57:48Z, capturing scontrol"
const FL_JOBLOG = "$FL_LOG_DIR/g4-g2d-4503.log"
const FL_JOBLOG_SHA = "bdad1889bfc38b9d042700e67f52eb60e051a889cb62f1642bd329ebb8ecf0c0"
const FL_REGISTRY = Dict(
    "job_id" => 4503,
    "submitted_utc" => "2026-08-13T12:40:50Z",
    "submitted_by" => "Codex monitor via Codex exec after IMMUTABLE " *
        "commit review of dec274d8; exactly ONE authorized sbatch was " *
        "executed (session 40's local submit was blocked by its " *
        "permission classifier BEFORE execution)",
    "expected_submit_line" => "sbatch --parsable " *
        "validation/results/gate4_g2d_eval2_rel415_flux.sbatch",
    "termination_record" => FL_RECEIPT,
    "termination_record_sha256" => FL_RECEIPT_SHA,
    "original_receipt_sha256_disclosed" => FL_ORIGINAL_RECEIPT_SHA,
    "terminal_monitor_output" => FL_MON,
    "terminal_monitor_output_sha256" => FL_MON_SHA,
    "terminal_log" => FL_JOBLOG,
    "terminal_log_sha256" => FL_JOBLOG_SHA)

# expected field bindings, exact strings (never normpath-relaxed)
# (A) current full receipt: everything it carries (no DerivedExitCode
#     line survives in the 14:59:22 re-capture; that field binds via B)
const FL_RECEIPT_EXPECT = Dict(
    "JobId" => "4503", "JobName" => FL_JOB_NAME,
    "JobState" => "COMPLETED", "Reason" => "None",
    "ExitCode" => "0:0", "Restarts" => "0",
    "RunTime" => "02:12:42", "TimeLimit" => "08:00:00",
    "SubmitTime" => "2026-08-13T12:40:50",
    "StartTime" => "2026-08-13T12:45:05",
    "EndTime" => "2026-08-13T14:57:47",
    "Command" => FL_SBATCH,
    "SubmitLine" => FL_REGISTRY["expected_submit_line"],
    "WorkDir" => FL_PROJECT_ROOT,
    "StdOut" => FL_JOBLOG)
# (B) preserved original watcher output: terminal fields incl. the
#     DerivedExitCode the re-capture lost
const FL_MON_EXPECT = Dict(
    "JobState" => "COMPLETED", "Reason" => "None",
    "ExitCode" => "0:0", "DerivedExitCode" => "0:0", "Restarts" => "0",
    "RunTime" => "02:12:42", "TimeLimit" => "08:00:00",
    "StartTime" => "2026-08-13T12:45:05",
    "EndTime" => "2026-08-13T14:57:47",
    "Command" => FL_SBATCH,
    "SubmitLine" => FL_REGISTRY["expected_submit_line"],
    "StdOut" => FL_JOBLOG)
const FL_CROSS_KEYS = ("JobState", "Reason", "ExitCode", "Restarts",
    "RunTime", "TimeLimit", "StartTime", "EndTime", "Command",
    "SubmitLine", "StdOut")

# outputs: exact size + sha + full schema, byte-identical copy sets
const FL_LW_SHA = "e799eae4421afe12481533678963237198338b3979ec938c6e61c2759522d4bc"
const FL_SW_SHA = "4ec6e8eb810dd4ad02f710dcbac4115f6d4d2002b28057ec68d20220a5b92291"
const FL_LW_BYTES = 451045
const FL_SW_BYTES = 1817493
const FL_LW_FILES = [
    "$FL_G4WORK/work-eval2/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5",
    "$FL_G4WORK/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5"]
const FL_SW_FILES = [
    "$FL_G4WORK/work-eval2/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5",
    "$FL_G4WORK/work/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5",
    "$FL_G4WORK/work-v14/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5"]

# rayleigh finals: exact names/sizes and the log-echoed hashes
const FL_RAY = [
    ("1-10", 902119952, "164ead75fdd2d08c86b7cb6729875bdb7802718a6bc0d0200ce9290a7c2ba15e"),
    ("11-20", 902145705, "d8c29fbfc562d9d8cabbe34eb8cfdaada2e3aecafcb17364e0336b07c1dc0c85"),
    ("21-30", 902140646, "5babdf39143d5ec564abbcb77cbce5ceffaf08685d033e7982c8cc80e63f97ce"),
    ("31-40", 902107831, "266fafd0b2516d8093e495f26bbadd3d493f11e3674699ac1d8c896478823e50"),
    ("41-50", 902161409, "000bc657951f095763401d262da878fcbdbfdb8c7f5ee54088c0f53c50c399db")]
fl_ray_path(chunk) = "$FL_E2SW/ckdmip_evaluation2_sw_spectra_rayleigh_present_$chunk.h5"
fl_h2o_path(chunk) = "$FL_E2SW/ckdmip_evaluation2_sw_spectra_h2o_present_$chunk.h5"

const FL_STAGES = [
    "=== G2d stage 0: preflight ===",
    "=== G2d stage 1: eval2 SW rayleigh (5 exact names; validated reuse) ===",
    "=== G2d stage 2: isolated testcopy-eval2 from the PINNED artifact ===",
    "=== G2d stage 3: LW rel-415 LBL evaluation ===",
    "=== G2d stage 4: SW rel-415 RGB LBL evaluation ===",
    "=== G2d stage 5: quarantine schema gate (exact-2, full validation) ===",
    "=== G2d stage 6: atomic installs into the exact G3 targets ==="]
const FL_DONE_MARK = "=== G2d done 2026-08-13T14:57:47Z ==="
const FL_PREFLIGHT_MARK = "preflight: 70/70 eval2 spectra exact-size + h5-open verified"
# broadened per review: traceback, generic ERROR/FATAL/FAILED, pin
# mismatch, quota failure/exceeded -- verified zero matches against the
# clean 4503 log before adoption (case-insensitive)
const FL_FAILURE_RE = r"REFUSED|SCHEMA-INVALID|sha mismatch|MISSING/nonexecutable|quota exceeded|Disk quota exceeded|CANCELLED|slurmstepd: error|Traceback \(most recent call last\)|\bERROR\b|\bFATAL\b|\bFAILED\b|QUOTA-\w+ REFUSED"i

const FL_RESULTS_JSON = validation_results_path("gate4_g2d_flux_completion_ledger.json")
const FL_RESULTS_MD = validation_results_path("gate4_g2d_flux_completion_ledger.md")

# --- primitives ---------------------------------------------------------------

# streaming digest: Rayleigh finals are ~902 MB each; never read
# wholesale into memory
fl_try_sha(path) = try
    isfile(path) || return nothing
    open(io -> bytes2hex(sha256(io)), path)
catch
    nothing
end

# coupled byte snapshot: one read supplies digest AND parsed content
function fl_snapshot(path)
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

# guarded checkpoint classifier: exact case, exact status, exact byte sha
function fl_classify_checkpoint(path; expected_case = FL_CKPT_CASE,
                                expected_status = FL_CKPT_STATUS,
                                expected_sha = FL_CKPT_JSON_SHA)
    snap = fl_snapshot(path)
    snap.ok || return (ok = false, class = snap.reason,
                       reason = "checkpoint artifact $(snap.reason)")
    c = get(snap.data, "case", nothing)
    c == expected_case || return (ok = false, class = "case mismatch",
        reason = "checkpoint case mismatch (got $(repr(c)))")
    s = get(snap.data, "status", nothing)
    s == expected_status || return (ok = false, class = "not ready",
        reason = "checkpoint status $(repr(s)) != $expected_status")
    snap.sha == expected_sha || return (ok = false, class = "sha drift",
        reason = "checkpoint sha $(snap.sha) != pinned $(expected_sha)")
    (ok = true, class = "green", reason = "")
end

# --- receipt (scontrol) parse + exact binding ---------------------------------

const FL_TOKEN_KEYS = ("JobId", "JobName", "JobState", "Reason",
    "ExitCode", "DerivedExitCode", "Restarts", "RunTime", "TimeLimit",
    "SubmitTime", "StartTime", "EndTime")

function fl_parse_receipt(text)
    f = Dict{String, String}()
    for k in FL_TOKEN_KEYS
        m = match(Regex("\\b" * k * "=(\\S+)"), text)
        m === nothing || (f[k] = String(m.captures[1]))
    end
    for k in ("Command", "SubmitLine", "WorkDir", "StdOut")
        m = match(Regex("^\\s*" * k * "=(.*)\$", "m"), text)
        m === nothing || (f[k] = String(strip(m.captures[1])))
    end
    f
end

# EVERY expected field must match by EXACT string (no normpath
# relaxation anywhere, monitor ruling); any deviation is an issue
function fl_receipt_issues(f, expect)
    iss = String[]
    for (k, v) in expect
        get(f, k, "") == v ||
            push!(iss, "$k mismatch (got $(repr(get(f, k, ""))))")
    end
    sort(iss)
end

# cross-check: common fields of the two terminal evidence parses must
# agree exactly
function fl_cross_issues(fa, fb, keys = FL_CROSS_KEYS)
    iss = String[]
    for k in keys
        get(fa, k, nothing) == get(fb, k, nothing) ||
            push!(iss, "cross-check $k: receipt $(repr(get(fa, k, nothing))) " *
                       "!= monitor-output $(repr(get(fb, k, nothing)))")
    end
    sort(iss)
end

# preserved-original watcher output group: digest, exact capture line,
# terminal fields, and the done/hash tail
function fl_monitor_output_group(path, pinned, expect;
                                 capline = FL_MON_CAPLINE,
                                 done = FL_DONE_MARK,
                                 echoes = Tuple{String, String}[])
    iss = String[]
    sha = fl_try_sha(path)
    sha === nothing &&
        (push!(iss, "monitor output missing/unreadable: $path"); return (iss, nothing))
    sha == pinned ||
        (push!(iss, "monitor output sha $sha != pinned $pinned"); return (iss, nothing))
    text = read(path, String)
    occursin(capline, text) ||
        push!(iss, "exact terminal-capture line missing")
    occursin(done, text) || push!(iss, "done marker missing from tail")
    for (h, p) in echoes
        occursin("$h  $p", text) ||
            push!(iss, "missing tail hash echo for $p")
    end
    f = fl_parse_receipt(text)
    append!(iss, fl_receipt_issues(f, expect))
    (sort(iss), f)
end

# --- log verification (pure) ---------------------------------------------------

# stages exactly once and in order; exact done marker; preflight marker;
# zero failure markers; exact "sha  path" echo for every artifact
function fl_log_issues(text; stages = FL_STAGES, done = FL_DONE_MARK,
                       preflight = FL_PREFLIGHT_MARK,
                       failure_re = FL_FAILURE_RE,
                       echoes = Tuple{String, String}[])
    iss = String[]
    lastpos = 0
    for s in stages
        n = length(collect(eachmatch(Regex("\\Q" * s * "\\E"), text)))
        n == 1 || push!(iss, "stage marker not exactly once ($n): $s")
        p = findfirst(s, text)
        if p !== nothing
            first(p) > lastpos ||
                push!(iss, "stage marker out of order: $s")
            lastpos = first(p)
        end
    end
    n = length(collect(eachmatch(Regex("\\Q" * done * "\\E"), text)))
    n == 1 || push!(iss, "done marker not exactly once ($n)")
    occursin(preflight, text) ||
        push!(iss, "70/70 preflight marker missing")
    m = match(failure_re, text)
    m === nothing || push!(iss, "failure marker present: $(m.match)")
    for (sha, path) in echoes
        occursin("$sha  $path", text) ||
            push!(iss, "missing hash echo for $path")
    end
    iss
end

# --- live file expectation (exists + exact size + exact sha) -------------------

function fl_file_issues(path, size, sha)
    iss = String[]
    if !isfile(path)
        push!(iss, "missing: $path")
        return iss
    end
    filesize(path) == size ||
        push!(iss, "size $(filesize(path)) != $size: $path")
    got = fl_try_sha(path)
    got == sha || push!(iss, "sha $(something(got, "unreadable")) != " *
                             "expected: $path")
    iss
end

# receipt evidence group: digest pin first, then exact field binding
function fl_receipt_group(path, pinned, expect)
    iss = String[]
    sha = fl_try_sha(path)
    sha === nothing &&
        (push!(iss, "receipt missing/unreadable: $path"); return iss)
    sha == pinned ||
        (push!(iss, "receipt sha $sha != pinned $pinned"); return iss)
    append!(iss, fl_receipt_issues(fl_parse_receipt(read(path, String)),
                                   expect))
    iss
end

# rayleigh exact-name census: the rayleigh_present_* population in the
# spectra dir must be EXACTLY the five expected basenames -- an extra or
# wrong-name rayleigh file refuses even if the five pinned ones are good
const FL_RAY_PREFIX = "ckdmip_evaluation2_sw_spectra_rayleigh_present_"
function fl_ray_census_issues(entries, expected)
    entries === nothing && return ["rayleigh dir unlistable"]
    ray = sort([String(e) for e in entries if startswith(e, FL_RAY_PREFIX)])
    exp = sort(collect(expected))
    ray == exp ? String[] :
        ["rayleigh name census mismatch: got $(ray) expected $(exp)"]
end

# --- residue census (pure over injected listings) ------------------------------

const FL_FORBIDDEN_RES = (r"^RAW", r"\.g2dtmp$", r"^\.g2d\.install\.",
                          r"^\.g2d\.ray\.")

# listings: Dict(label => (entries, allowed_exact)) -- entries must be
# exactly allowed_exact (order-insensitive) AND free of forbidden forms
function fl_residue_issues(listings)
    iss = String[]
    for (label, (entries, allowed)) in listings
        entries === nothing && (push!(iss, "$label unlistable"); continue)
        for e in entries
            any(re -> occursin(re, e), FL_FORBIDDEN_RES) &&
                push!(iss, "$label residue: $e")
        end
        if allowed !== nothing
            Set(entries) == Set(allowed) ||
                push!(iss, "$label entries $(sort(entries)) != " *
                           "expected $(sort(collect(allowed)))")
        end
    end
    sort(iss)
end

fl_try_list(d) = try
    isdir(d) ? readdir(d) : nothing
catch
    nothing
end

# --- validator extraction from the sha-pinned committed sbatch -----------------

function fl_extract_validator()
    sha = fl_try_sha(FL_SBATCH)
    sha == FL_SBATCH_SHA || return nothing
    text = read(FL_SBATCH, String)
    m1 = findfirst("cat > \"\$VAL\" <<'PYEOF'\n", text)
    m2 = findfirst("\nPYEOF\n", text)
    (m1 === nothing || m2 === nothing) && return nothing
    src = text[last(m1)+1:first(m2)]
    p = joinpath(mktempdir(), "g2d_validator.py")
    write(p, src)
    p
end

fl_schema_ok(val, mode, path, extra...) =
    val !== nothing && success(pipeline(
        `python3 $val $mode $path $(collect(extra))`,
        stdout=devnull, stderr=devnull))

# --- overall -------------------------------------------------------------------

fl_overall(groups) = all(isempty, values(groups)) ?
    "g2d_flux_completed_verified" : "g2d_flux_ledger_refused"

function fl_close_failed_gates!(fails, gates)
    bad = sort([k for (k, v) in gates if v != "passed"])
    isempty(bad) ||
        push!(fails, "failed gates (fail-closed census): " * join(bad, ", "))
end

# --- fixtures -------------------------------------------------------------------

function fl_fixtures(val)
    t = Dict{String, Bool}()
    fx = mktempdir()
    shaof(p) = bytes2hex(sha256(read(p)))

    # checkpoint classifier classes
    cls(p; kw...) = fl_classify_checkpoint(p; kw...)
    t["ckpt_missing_refuses"] =
        cls(joinpath(fx, "absent.json")).class == "missing"
    p = joinpath(fx, "bad.json"); write(p, "{oops")
    t["ckpt_unparseable_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "unparseable (parse failure)"
    p = joinpath(fx, "arr.json"); write(p, "[]")
    t["ckpt_non_object_refuses"] =
        cls(p; expected_sha = shaof(p)).class ==
        "parses to a non-object (JSON null/array/scalar)"
    p = joinpath(fx, "case.json")
    write(p, JSON.json(Dict("case" => "x", "status" => FL_CKPT_STATUS)))
    t["ckpt_case_mismatch_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "case mismatch"
    p = joinpath(fx, "st.json")
    write(p, JSON.json(Dict("case" => FL_CKPT_CASE,
                            "status" => "g2d_checkpoint_waiting_for_g2c")))
    t["ckpt_not_ready_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "not ready"
    p = joinpath(fx, "green.json")
    write(p, JSON.json(Dict("case" => FL_CKPT_CASE,
                            "status" => FL_CKPT_STATUS)))
    t["ckpt_hash_drift_refuses"] =
        cls(p; expected_sha = "0" ^ 64).class == "sha drift"
    t["ckpt_green_accepted"] = cls(p; expected_sha = shaof(p)).ok

    # receipt binding: synthetic receipt from the expectation table
    mkreceipt(over...) = begin
        e = Dict{String, String}(FL_RECEIPT_EXPECT)
        for (k, v) in over
            e[k] = v
        end
        "JobId=$(e["JobId"]) JobName=$(e["JobName"])\n" *
        "   JobState=$(e["JobState"]) Reason=$(e["Reason"]) Dependency=(null)\n" *
        "   Requeue=1 Restarts=$(e["Restarts"]) ExitCode=$(e["ExitCode"])\n" *
        "   RunTime=$(e["RunTime"]) TimeLimit=$(e["TimeLimit"])\n" *
        "   SubmitTime=$(e["SubmitTime"]) EligibleTime=$(e["SubmitTime"])\n" *
        "   StartTime=$(e["StartTime"]) EndTime=$(e["EndTime"])\n" *
        "   Command=$(e["Command"])\n" *
        "   SubmitLine=$(e["SubmitLine"])\n" *
        "   WorkDir=$(e["WorkDir"])\n" *
        "   StdOut=$(e["StdOut"])\n"
    end
    ri(txt) = fl_receipt_issues(fl_parse_receipt(txt), FL_RECEIPT_EXPECT)
    t["receipt_good_binds"] = isempty(ri(mkreceipt()))
    t["receipt_wrong_state_refuses"] =
        !isempty(ri(mkreceipt("JobState" => "FAILED")))
    t["receipt_nonzero_exit_refuses"] =
        !isempty(ri(mkreceipt("ExitCode" => "1:0")))
    t["receipt_restarts_refuses"] =
        !isempty(ri(mkreceipt("Restarts" => "1")))
    t["receipt_jobid_refuses"] = !isempty(ri(mkreceipt("JobId" => "9999")))
    t["receipt_submitline_injection_refuses"] =
        !isempty(ri(mkreceipt("SubmitLine" => "sbatch --parsable " *
            "--export=X=1 validation/results/gate4_g2d_eval2_rel415_flux.sbatch")))
    t["receipt_workdir_refuses"] =
        !isempty(ri(mkreceipt("WorkDir" => "/tmp")))
    t["receipt_stdout_refuses"] =
        !isempty(ri(mkreceipt("StdOut" => "/tmp/x.log")))
    t["receipt_runtime_refuses"] =
        !isempty(ri(mkreceipt("RunTime" => "07:59:59")))
    t["receipt_submittime_refuses"] =
        !isempty(ri(mkreceipt("SubmitTime" => "2026-08-13T00:00:00")))

    # preserved monitor-output group (B) + cross-check
    fx_echo = [("a" ^ 64, "/x/a.h5")]
    mkmon(over...) = begin
        e = Dict{String, String}(FL_MON_EXPECT)
        for (k, v) in over
            e[k] = v
        end
        FL_MON_CAPLINE * "\n" *
        "   JobState=$(e["JobState"]) Reason=$(e["Reason"]) Dependency=(null)\n" *
        "   Requeue=1 Restarts=$(e["Restarts"]) BatchFlag=1 ExitCode=$(e["ExitCode"])\n" *
        "   DerivedExitCode=$(e["DerivedExitCode"])\n" *
        "   RunTime=$(e["RunTime"]) TimeLimit=$(e["TimeLimit"])\n" *
        "   StartTime=$(e["StartTime"]) EndTime=$(e["EndTime"])\n" *
        "   Command=$(e["Command"])\n" *
        "   SubmitLine=$(e["SubmitLine"])\n" *
        "   StdOut=$(e["StdOut"])\n---LOG-TAIL---\n" *
        ("a" ^ 64) * "  /x/a.h5\n" * FL_DONE_MARK * "\n"
    end
    mg(txt; kw...) = begin
        p2 = joinpath(fx, "mon_$(hash(txt)).txt"); write(p2, txt)
        fl_monitor_output_group(p2, shaof(p2), FL_MON_EXPECT;
                                echoes = fx_echo, kw...)
    end
    t["monitor_output_good"] = isempty(mg(mkmon())[1])
    t["monitor_output_missing_refuses"] =
        !isempty(fl_monitor_output_group(joinpath(fx, "nomon.txt"),
            "0" ^ 64, FL_MON_EXPECT)[1])
    t["monitor_output_digest_drift_refuses"] = begin
        p2 = joinpath(fx, "mon_drift.txt"); write(p2, mkmon())
        !isempty(fl_monitor_output_group(p2, "0" ^ 64, FL_MON_EXPECT)[1])
    end
    t["monitor_output_field_drift_refuses"] =
        !isempty(mg(mkmon("DerivedExitCode" => "1:0"))[1])
    t["monitor_output_capline_missing_refuses"] =
        !isempty(mg(replace(mkmon(), FL_MON_CAPLINE => "captured"))[1])
    t["monitor_output_tail_echo_missing_refuses"] =
        !isempty(mg(replace(mkmon(), ("a" ^ 64) * "  /x/a.h5" => ""))[1])
    # cross-check agreement/disagreement
    fa = fl_parse_receipt(mkreceipt())
    fb = mg(mkmon())[2]
    t["cross_check_agreement_passes"] =
        fb !== nothing && isempty(fl_cross_issues(fa, fb))
    t["cross_check_disagreement_refuses"] = begin
        fb2 = mg(mkmon("EndTime" => "2026-08-13T14:57:48"))[2]
        fb2 !== nothing && !isempty(fl_cross_issues(fa, fb2))
    end

    # log verification
    goodlog(echoes) = join(FL_STAGES, "\nwork...\n") * "\n" *
        FL_PREFLIGHT_MARK * "\n" *
        join(["$sha  $path" for (sha, path) in echoes], "\n") * "\n" *
        FL_DONE_MARK * "\n"
    ec = [("a" ^ 64, "/x/one.h5"), ("b" ^ 64, "/x/two.h5")]
    t["log_good_accepted"] = isempty(fl_log_issues(goodlog(ec); echoes = ec))
    t["log_missing_stage_refuses"] =
        !isempty(fl_log_issues(replace(goodlog(ec), FL_STAGES[5] => "");
                               echoes = ec))
    t["log_out_of_order_refuses"] =
        !isempty(fl_log_issues(FL_STAGES[2] * "\n" *
            replace(goodlog(ec), FL_STAGES[2] => ""); echoes = ec))
    t["log_failure_marker_refuses"] =
        !isempty(fl_log_issues(goodlog(ec) * "REFUSED: x\n"; echoes = ec))
    t["log_missing_echo_refuses"] =
        !isempty(fl_log_issues(goodlog(ec[1:1]); echoes = ec))
    t["log_wrong_done_timestamp_refuses"] =
        !isempty(fl_log_issues(replace(goodlog(ec),
            FL_DONE_MARK => "=== G2d done 2026-08-13T00:00:00Z ===");
            echoes = ec))

    # live-file expectations on tmp files
    p = joinpath(fx, "out.h5"); write(p, "DATA")
    t["file_good_accepted"] = isempty(fl_file_issues(p, 4, shaof(p)))
    t["file_missing_refuses"] =
        !isempty(fl_file_issues(joinpath(fx, "no.h5"), 4, "0" ^ 64))
    t["file_wrong_size_refuses"] = !isempty(fl_file_issues(p, 5, shaof(p)))
    t["file_wrong_sha_refuses"] = !isempty(fl_file_issues(p, 4, "0" ^ 64))
    # schema mismatch refusal, evidence-based via the extracted validator
    t["schema_cross_mode_refuses"] =
        val !== nothing && !fl_schema_ok(val, "lw", FL_SW_FILES[1])
    # rayleigh grid mismatch: live rayleigh vs the WRONG h2o chunk
    t["rayleigh_wrong_source_refuses"] =
        val !== nothing && !fl_schema_ok(val, "rayleigh",
            fl_ray_path("1-10"), fl_h2o_path("11-20"))

    # residue census
    rl(entries; allowed = nothing) =
        fl_residue_issues(Dict("d" => (entries, allowed)))
    t["residue_clean_accepted"] =
        isempty(rl(["final.h5"]; allowed = ["final.h5"]))
    t["residue_raw_refuses"] = !isempty(rl(["RAW_x_1-10.h5", "final.h5"]))
    t["residue_g2dtmp_refuses"] = !isempty(rl(["final.h5.g2dtmp"]))
    t["residue_install_tmp_refuses"] = !isempty(rl([".g2d.install.f.h5"]))
    t["residue_ray_tmp_refuses"] = !isempty(rl([".g2d.ray.1-10.tmp"]))
    t["residue_unexpected_entry_refuses"] =
        !isempty(rl(["final.h5", "other.h5"]; allowed = ["final.h5"]))
    t["residue_unlistable_refuses"] =
        !isempty(fl_residue_issues(Dict("d" => (nothing, nothing))))

    # receipt group: missing / digest drift / good (through the guarded
    # group helper, not only the field binder)
    rp2 = joinpath(fx, "receipt.txt"); write(rp2, mkreceipt())
    t["receipt_group_good"] =
        isempty(fl_receipt_group(rp2, shaof(rp2), FL_RECEIPT_EXPECT))
    t["receipt_group_missing_refuses"] =
        !isempty(fl_receipt_group(joinpath(fx, "norcpt.txt"), "0" ^ 64,
                                  FL_RECEIPT_EXPECT))
    t["receipt_group_digest_drift_refuses"] =
        !isempty(fl_receipt_group(rp2, "0" ^ 64, FL_RECEIPT_EXPECT))
    # copy-identity drift: two copies expected at the SAME pinned sha,
    # one drifts -> refused
    c1 = joinpath(fx, "c1.h5"); write(c1, "IDENTICAL")
    c2 = joinpath(fx, "c2.h5"); write(c2, "DIVERGENT")
    t["copy_identity_drift_refuses"] =
        isempty(fl_file_issues(c1, 9, shaof(c1))) &&
        !isempty(fl_file_issues(c2, 9, shaof(c1)))
    # rayleigh exact-name census
    exp5 = [FL_RAY_PREFIX * c * ".h5" for (c, _, _) in FL_RAY]
    t["ray_census_exact_accepted"] =
        isempty(fl_ray_census_issues(vcat(exp5, ["other_file.h5"]), exp5))
    t["ray_census_extra_refuses"] =
        !isempty(fl_ray_census_issues(vcat(exp5,
            [FL_RAY_PREFIX * "51-60.h5"]), exp5))
    t["ray_census_wrong_name_refuses"] =
        !isempty(fl_ray_census_issues(
            vcat(exp5[1:4], [FL_RAY_PREFIX * "1-10.h5.bak"]), exp5))
    t["ray_census_missing_refuses"] =
        !isempty(fl_ray_census_issues(exp5[1:4], exp5))
    t["ray_census_unlistable_refuses"] =
        !isempty(fl_ray_census_issues(nothing, exp5))
    # broadened failure markers still reject; clean log still accepted
    for (name, marker) in (("traceback", "Traceback (most recent call last):"),
                           ("generic_error", "ERROR: boom"),
                           ("generic_fatal", "FATAL: boom"),
                           ("generic_failed", "job FAILED"),
                           ("quota_exceeded", "Disk quota exceeded"),
                           ("pin_mismatch", "post-sed LW script sha mismatch"))
        t["log_marker_$(name)_refuses"] =
            !isempty(fl_log_issues(goodlog(ec) * marker * "\n"; echoes = ec))
    end
    # overall composition
    t["overall_all_green"] =
        fl_overall(Dict("a" => String[], "b" => String[])) ==
        "g2d_flux_completed_verified"
    t["overall_any_issue_refuses"] =
        fl_overall(Dict("a" => String[], "b" => ["x"])) ==
        "g2d_flux_ledger_refused"
    t
end

# --- main -----------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()

    val = fl_extract_validator()
    gates["validator_extracted_from_pinned_sbatch"] =
        val === nothing ? "failed" : "passed"
    val === nothing &&
        push!(fails, "sbatch sha drift or validator heredoc not found")

    tests = fl_fixtures(val)
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    groups = Dict{String, Vector{String}}()

    # provenance chain
    anc = try
        success(`git -C $FL_PROJECT_ROOT merge-base --is-ancestor $FL_REVIEWED_COMMIT HEAD`)
    catch; false end
    groups["commit_ancestry"] = anc ? String[] :
        ["reviewed commit $FL_REVIEWED_COMMIT is not an ancestor of HEAD"]
    src_sha = fl_try_sha(FL_CKPT_SRC)
    groups["checkpoint_source_pin"] = src_sha == FL_CKPT_SRC_SHA ?
        String[] : ["checkpoint source sha $(something(src_sha, "unreadable")) != pinned"]
    led = fl_classify_checkpoint(FL_CKPT_JSON)
    groups["checkpoint_json_pin"] = led.ok ? String[] : [led.reason]
    sb_sha = fl_try_sha(FL_SBATCH)
    groups["sbatch_pin"] = sb_sha == FL_SBATCH_SHA ?
        String[] : ["sbatch sha $(something(sb_sha, "unreadable")) != pinned"]

    # receipt (A): digest then exact binding (single guarded group helper)
    groups["termination_receipt"] =
        fl_receipt_group(FL_RECEIPT, FL_RECEIPT_SHA, FL_RECEIPT_EXPECT)

    # preserved original watcher output (B): digest, capture line,
    # terminal fields incl. DerivedExitCode, done/hash tail
    out_echoes = [(FL_LW_SHA, FL_LW_FILES[1]), (FL_SW_SHA, FL_SW_FILES[1]),
                  (FL_LW_SHA, FL_LW_FILES[2]), (FL_SW_SHA, FL_SW_FILES[2]),
                  (FL_SW_SHA, FL_SW_FILES[3])]
    mon_iss, mon_fields = fl_monitor_output_group(FL_MON, FL_MON_SHA,
        FL_MON_EXPECT; echoes = out_echoes)
    groups["terminal_monitor_output"] = mon_iss

    # cross-check: common fields of both evidence parses must agree
    groups["receipt_cross_check"] =
        (fl_try_sha(FL_RECEIPT) == FL_RECEIPT_SHA && mon_fields !== nothing) ?
        fl_cross_issues(fl_parse_receipt(read(FL_RECEIPT, String)),
                        mon_fields) :
        ["cross-check unavailable (evidence digest/read failure)"]

    # log: digest then structure + hash echoes for every artifact
    log_issues = String[]
    log_sha = fl_try_sha(FL_JOBLOG)
    if log_sha != FL_JOBLOG_SHA
        push!(log_issues, "log sha $(something(log_sha, "unreadable")) " *
                          "!= pinned $(FL_JOBLOG_SHA)")
    else
        echoes = Tuple{String, String}[]
        for (chunk, _, sha) in FL_RAY
            push!(echoes, (sha, fl_ray_path(chunk)))
        end
        push!(echoes, (FL_LW_SHA, FL_LW_FILES[1]))
        push!(echoes, (FL_SW_SHA, FL_SW_FILES[1]))
        push!(echoes, (FL_LW_SHA, FL_LW_FILES[2]))
        push!(echoes, (FL_SW_SHA, FL_SW_FILES[2]))
        push!(echoes, (FL_SW_SHA, FL_SW_FILES[3]))
        append!(log_issues,
                fl_log_issues(read(FL_JOBLOG, String); echoes = echoes))
    end
    groups["terminal_log"] = log_issues

    # live outputs: exact size/sha (byte-identity via equal pinned sha)
    # AND full schema on EVERY copy
    out_issues = String[]
    for f in FL_LW_FILES
        append!(out_issues, fl_file_issues(f, FL_LW_BYTES, FL_LW_SHA))
        fl_schema_ok(val, "lw", f) || push!(out_issues, "lw schema failed: $f")
    end
    for f in FL_SW_FILES
        append!(out_issues, fl_file_issues(f, FL_SW_BYTES, FL_SW_SHA))
        fl_schema_ok(val, "sw", f) || push!(out_issues, "sw schema failed: $f")
    end
    groups["flux_outputs_and_installs"] = out_issues

    # rayleigh finals: exact-name census, then sizes/hashes + schema/grid
    ray_issues = fl_ray_census_issues(fl_try_list(FL_E2SW),
        [basename(fl_ray_path(c)) for (c, _, _) in FL_RAY])
    for (chunk, size, sha) in FL_RAY
        rp = fl_ray_path(chunk)
        append!(ray_issues, fl_file_issues(rp, size, sha))
        fl_schema_ok(val, "rayleigh", rp, fl_h2o_path(chunk)) ||
            push!(ray_issues, "rayleigh schema/grid failed: $chunk")
    end
    groups["rayleigh_finals"] = ray_issues

    # residue: work-eval2 exactly the two finals; no temp forms anywhere
    groups["residue"] = fl_residue_issues(Dict(
        "work-eval2/lw_lbl_fluxes" =>
            (fl_try_list("$FL_G4WORK/work-eval2/lw_lbl_fluxes"),
             [basename(FL_LW_FILES[1])]),
        "work-eval2/sw_lbl_fluxes" =>
            (fl_try_list("$FL_G4WORK/work-eval2/sw_lbl_fluxes"),
             [basename(FL_SW_FILES[1])]),
        "eval2 sw_spectra" => (fl_try_list(FL_E2SW), nothing),
        "work/lw_lbl_fluxes" =>
            (fl_try_list("$FL_G4WORK/work/lw_lbl_fluxes"), nothing),
        "work/sw_lbl_fluxes" =>
            (fl_try_list("$FL_G4WORK/work/sw_lbl_fluxes"), nothing),
        "work-v14/sw_lbl_fluxes" =>
            (fl_try_list("$FL_G4WORK/work-v14/sw_lbl_fluxes"), nothing)))

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end

    status = (gates["fixtures"] == "passed" &&
              gates["validator_extracted_from_pinned_sbatch"] == "passed") ?
        fl_overall(groups) : "g2d_flux_ledger_refused"
    fl_close_failed_gates!(fails, gates)

    quota_row = try
        uid = strip(read(`id -u`, String))
        strip(split(read(pipeline(`lfs quota -q -u $uid /shared`,
                                  stderr=devnull), String), "\n")[1])
    catch
        "unavailable"
    end

    result = Dict(
        "case" => "gate4_g2d_flux_completion_ledger",
        "data_mode" => "read_only_evidence_ledger",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)) * "Z",
        "gates" => gates, "failures" => fails,
        "fixture_verdicts" => tests,
        "attempt_registry" => [FL_REGISTRY],
        "reviewed" => Dict(
            "commit_ancestor" => FL_REVIEWED_COMMIT,
            "checkpoint_source_sha256" => FL_CKPT_SRC_SHA,
            "checkpoint_json_sha256" => FL_CKPT_JSON_SHA,
            "sbatch_sha256" => FL_SBATCH_SHA),
        "receipt_pin_note" => "the termination-record file was first " *
            "captured 2026-08-13T14:57:48 (full receipt sha 59d79073..., " *
            "disclosed) and overwritten at 14:59:22 by session 40's " *
            "re-capture of the same completed job (7328195a..., bound " *
            "as evidence A; the re-capture lacks the DerivedExitCode " *
            "line). Per the monitor's receipt ruling the ORIGINAL " *
            "14:57:48 watcher output is preserved at $(FL_MON) (stored " *
            "read-only at preservation; content digest-bound to " *
            "aaeed4d4... by this ledger) and bound as evidence B for " *
            "the terminal-capture timestamp, DerivedExitCode, and the " *
            "done/hash tail; common fields are cross-checked exactly. " *
            "The two FULL receipts are NOT claimed byte- or " *
            "field-identical.",
        "outputs" => Dict(
            "lw" => Dict("bytes" => FL_LW_BYTES, "sha256" => FL_LW_SHA,
                         "copies" => FL_LW_FILES),
            "sw" => Dict("bytes" => FL_SW_BYTES, "sha256" => FL_SW_SHA,
                         "copies" => FL_SW_FILES)),
        "rayleigh" => [Dict("chunk" => c, "bytes" => s, "sha256" => h,
                            "path" => fl_ray_path(c))
                       for (c, s, h) in FL_RAY],
        "quota_observed_at" => Dict(
            "row_verbatim" => quota_row,
            "observed_at_utc" => string(Dates.now(Dates.UTC)) * "Z",
            "note" => "informational observation ONLY; never an input " *
                      "to the completion classification"),
        "non_authorizing_note" => "this ledger records and classifies " *
            "evidence; it does not itself submit, fetch, delete, change " *
            "quota, or execute G3 -- downstream consumers must bind this " *
            "artifact (exact case/status/sha) rather than assume " *
            "progression from its existence",
        "disclaimer" => "read-only evidence ledger; writes nothing " *
            "except its own JSON/MD results.",
    )
    mkpath(dirname(FL_RESULTS_JSON))
    open(FL_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(FL_RESULTS_MD, "w") do io
        println(io, "# Gate-4 G2d flux completion ledger\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        if status == "g2d_flux_completed_verified"
            println(io, "\nAttempt: job 4503 (COMPLETED 0:0, 02:12:42 " *
                        "of 08:00:00), dual receipt + log digest-bound; " *
                        "see JSON.")
            println(io, "\nOutputs: LW $(FL_LW_BYTES) B x " *
                        "$(length(FL_LW_FILES)) copies; SW " *
                        "$(FL_SW_BYTES) B x $(length(FL_SW_FILES)) " *
                        "copies; rayleigh 5 finals (~4.2 GiB); every " *
                        "copy full-schema validated.")
        else
            println(io, "\nAttempt: job 4503 -- expected COMPLETED 0:0 " *
                        "(claim WITHHELD: not verified by this run; see " *
                        "Failures).")
            println(io, "\nOutputs: expected LW/SW copies + 5 rayleigh " *
                        "finals (claims WITHHELD: not verified by this " *
                        "run; nothing was regenerated).")
        end
        println(io, "\nReceipt pin note: ", result["receipt_pin_note"])
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_g2d_flux_completion_ledger: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "g2d_flux_completed_verified" ? 0 : 1
end

exit(main())
