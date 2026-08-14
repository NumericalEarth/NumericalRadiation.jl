# Gate-4 C3-IB job-4580 TERMINAL FAILURE LEDGER writer (fail-closed).
# Durable forensics for the FAILED 71:0 terminal state of job 4580:
# an INSTRUMENT-GATE FALSE-REFUSAL -- the committed downstream banner
# gate hand-assumed the base-pass convergence criterion (0.02) while
# the pinned template's downstream modes use 0.0005; the relative-ch4
# science completed (raw3 written and closed) before the gate refused.
# Separates DURABLE EVIDENCE (receipt/log/template/gate pins and
# verbatim extracts, three-leg root-cause chain) from MONITOR
# OBSERVATIONS (classification and rulings). Writes NOTHING unless
# every pin, raw-field, line, and census gate passes. ZERO scientific
# inference; partial outputs are forensics only and MUST NOT be
# reused; the 4580 RUNROOT/log/receipt are preserved, reviewer
# accesses are read-only, and NO filesystem immutability seal is
# claimed (none was applied).

const P2_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
include(joinpath(P2_PROJECT_ROOT, "validation", "validation_results.jl"))
using SHA
using JSON

const F4580_RECEIPT = "/shared/home/greg/data/ckdmip-logs/" *
    "g4-c3ib-lw-4580-scontrol-final-agent42.txt"
const F4580_RECEIPT_SHA =
    "28e71c26bc69834b145ce78fb3c8c5ac8e5eef1a2be9506a2832660de7276c19"
const F4580_EPOCH = F4580_RECEIPT * ".epoch"
const F4580_EPOCH_VALUE = "1786728580"
const F4580_LOG = "/shared/home/greg/data/ckdmip-logs/g4-c3ib-lw-4580.log"
const F4580_LOG_SHA =
    "292c9ce6fabba8a23ba27206718d33d22dfbec466e24c9874a40c582be897873"
const F4580_LOG_BYTES = 1247306
const F4580_LOG_LINES = 16554
const F4580_BANNER_LINE = 3663
const F4580_BANNER_TEXT = "Optimizing coefficients with Adept LBFGS " *
    "algorithm: max iterations = 3000, convergence criterion = 0.0005"
const F4580_RAW3_CLOSE_LINE = 16553
const F4580_REFUSAL_LINE = 16554
const F4580_REFUSAL_TEXT =
    "REFUSED: c0a relative-ch4 default-3000 banner not exactly once"
const F4580_RUNROOT = "/shared/home/greg/ecckd-derived-flux-work/" *
    "g4-init-generation/g4-diag/4580/lw-c3ib"
const F4580_COMMIT = "01a6fa78d001c4f4e59cc02e0e9a245997361d8d"
const F4580_SBATCH_REPO =
    "validation/results/gate4_c3_ib_lw_iteration_budget.sbatch"
const F4580_SBATCH_SHA =
    "834cd0d32863ba299edb13075b2077d6f92b46ddc884282bdf1d87bac1397a9b"
const F4580_GATE_LINE = 1261
const F4580_TEMPLATE = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd/" *
    "test/optimize_lut_lw.sh"
const F4580_TEMPLATE_SHA =
    "f0d77b16b97612687818e85615a103adaa948627846c9819e40e7754ab0743ba"
const F4580_MODES = ["relative-base", "relative-ch4", "relative-n2o",
                     "relative-cfc"]
const F4580_OPTIMIZE_LUT_CPP = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd/" *
    "src/ecckd/optimize_lut.cpp"
const F4580_OPTIMIZE_LUT_CPP_SHA =
    "3ebaef95bdb334f20016be8b7cb6a8f0b86a5608f682839a4f80641f843740e1"
const F4580_EXPECTED_CRITERIA = Dict(
    "relative-base" => "0.02", "relative-ch4" => "0.0005",
    "relative-n2o" => "0.0005", "relative-cfc" => "0.0005")
const F4580_RAW2 = joinpath(F4580_RUNROOT, "work-c0a",
    "lw_raw-ckd-definition",
    "ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc")
const F4580_RAW2_SHA =
    "51e830c01e9202e8d3a5d69a0e40e7c2838398b43a3528c7f6ad5279d2e79503"
const F4580_RAW2_BYTES = 2415316
const F4580_RAW3 = joinpath(F4580_RUNROOT, "work-c0a",
    "lw_raw-ckd-definition",
    "ecckd-1.2_lw_raw3-ckd-definition_climate_fsck-tol0.0161.nc")
const F4580_RAW3_SHA =
    "162750414be8b949335172629ec460e9eb5cb922e1cf4056bf22a635cc54389b"
const F4580_RAW3_BYTES = 2417524
const F4580_RAW_REQUIRED = [
    "JobId=4580", "JobName=g4-c3ib-lw-iteration-budget",
    "JobState=FAILED", "Reason=NonZeroExitCode", "ExitCode=71:0",
    "DerivedExitCode=0:0", "Restarts=0", "RunTime=00:52:49",
    "TimeLimit=06:00:00", "StartTime=2026-08-14T16:36:41",
    "EndTime=2026-08-14T17:29:30",
    "Command=/shared/home/greg/Projects/AnalyticBandRadiation-platform/" *
        "validation/results/gate4_c3_ib_lw_iteration_budget.sbatch",
    "SubmitLine=sbatch --parsable " *
        "validation/results/gate4_c3_ib_lw_iteration_budget.sbatch",
    "StdOut=/shared/home/greg/data/ckdmip-logs/g4-c3ib-lw-4580.log"]
const F4580_STAGED_EVAL1 = sort([
    "ckdmip_evaluation1_lw_fluxes_rel-180.h5",
    "ckdmip_evaluation1_lw_fluxes_rel-280.h5",
    "ckdmip_evaluation1_lw_fluxes_rel-415.h5",
    "ckdmip_evaluation1_lw_fluxes_rel-560.h5",
    "ckdmip_evaluation1_lw_fluxes_rel-1120.h5",
    "ckdmip_evaluation1_lw_fluxes_rel-2240.h5",
    "ckdmip_evaluation1_lw_fluxes_present.h5",
    "ckdmip_evaluation1_lw_fluxes_ch4-350.h5",
    "ckdmip_evaluation1_lw_fluxes_ch4-700.h5",
    "ckdmip_evaluation1_lw_fluxes_ch4-1200.h5",
    "ckdmip_evaluation1_lw_fluxes_ch4-2600.h5",
    "ckdmip_evaluation1_lw_fluxes_ch4-3500.h5",
    "ckdmip_evaluation1_lw_fluxes_n2o-190.h5",
    "ckdmip_evaluation1_lw_fluxes_n2o-270.h5",
    "ckdmip_evaluation1_lw_fluxes_n2o-405.h5",
    "ckdmip_evaluation1_lw_fluxes_n2o-540.h5",
    "ckdmip_evaluation1_lw_fluxes_cfc11-0.h5",
    "ckdmip_evaluation1_lw_fluxes_cfc11-2000.h5",
    "ckdmip_evaluation1_lw_fluxes_cfc12-0.h5",
    "ckdmip_evaluation1_lw_fluxes_cfc12-550.h5"])
const F4580_RESULTS_JSON =
    validation_results_path("gate4_c3_ib_4580_failure_ledger.json")
const F4580_RESULTS_MD =
    validation_results_path("gate4_c3_ib_4580_failure_ledger.md")

f4580_sha(p) = bytes2hex(open(sha256, p))

# forensic extraction of the active per-mode SPECIFIC_OPTIONS line and
# its convergence_criterion token from the pinned template
function f4580_downstream_setting(text, mode)
    m = match(Regex("(?ms)^\\s*" * mode * "\\)\\s*(.*?);;"), text)
    m === nothing && return nothing
    for ln in split(m.captures[1], '\n')
        startswith(strip(ln), "#") && continue
        om = match(r"^\s*SPECIFIC_OPTIONS=\"([^\"]*)\"\s*$", ln)
        om === nothing && continue
        cm = match(r"convergence_criterion=([0-9.eE+-]+)",
                   om.captures[1])
        cm === nothing && return nothing
        return (line = String(strip(ln)),
                criterion = String(cm.captures[1]))
    end
    nothing
end

# compiled-default C++ base authority: EXACTLY ONE active declaration
# site and EXACTLY ONE active config-read site (comment lines cannot
# satisfy either)
function f4580_base_source_setting(cpp_text)
    dm = collect(eachmatch(
        r"(?m)^\s*Real convergence_criterion = ([0-9.eE+-]+);",
        cpp_text))
    length(dm) == 1 || return nothing
    rm_ = collect(eachmatch(
        r"(?m)^\s*config\.read\(convergence_criterion, \"convergence_criterion\"\);",
        cpp_text))
    length(rm_) == 1 || return nothing
    (line = String(strip(dm[1].match)),
     criterion = String(dm[1].captures[1]))
end

function main()
    iss = String[]
    for (what, pth, pin) in (("receipt", F4580_RECEIPT, F4580_RECEIPT_SHA),
                             ("log", F4580_LOG, F4580_LOG_SHA),
                             ("template", F4580_TEMPLATE, F4580_TEMPLATE_SHA),
                             ("base-source optimize_lut.cpp",
                              F4580_OPTIMIZE_LUT_CPP,
                              F4580_OPTIMIZE_LUT_CPP_SHA))
        isfile(pth) || (push!(iss, "$what missing: $pth"); continue)
        f4580_sha(pth) == pin || push!(iss, "$what sha drift: $pth")
    end
    epoch = isfile(F4580_EPOCH) ? strip(read(F4580_EPOCH, String)) : nothing
    epoch == F4580_EPOCH_VALUE ||
        push!(iss, "epoch sidecar missing or value != $F4580_EPOCH_VALUE")
    receipt_text = isfile(F4580_RECEIPT) ? read(F4580_RECEIPT, String) : ""
    for r in F4580_RAW_REQUIRED
        occursin(r, receipt_text) ||
            push!(iss, "receipt missing raw field: $r")
    end
    isfile(F4580_LOG) && filesize(F4580_LOG) == F4580_LOG_BYTES ||
        push!(iss, "log byte count != $F4580_LOG_BYTES")
    loglines = isfile(F4580_LOG) ?
        split(read(F4580_LOG, String), '\n'; keepempty = true) : String[]
    if !isempty(loglines) && isempty(last(loglines))
        pop!(loglines)
    else
        push!(iss, "log does not end with a newline")
    end
    length(loglines) == F4580_LOG_LINES ||
        push!(iss, "log line count $(length(loglines)) != $F4580_LOG_LINES")
    banner = length(loglines) >= F4580_BANNER_LINE ?
        String(loglines[F4580_BANNER_LINE]) : ""
    banner == F4580_BANNER_TEXT ||
        push!(iss, "log line $F4580_BANNER_LINE != expected " *
                   "downstream banner")
    raw3close = length(loglines) >= F4580_RAW3_CLOSE_LINE ?
        String(loglines[F4580_RAW3_CLOSE_LINE]) : ""
    (startswith(raw3close, "Closed ") && occursin("raw3", raw3close) &&
     occursin(F4580_RUNROOT, raw3close)) ||
        push!(iss, "log line $F4580_RAW3_CLOSE_LINE is not the raw3 " *
                   "close record")
    refusal = length(loglines) >= F4580_REFUSAL_LINE ?
        String(loglines[F4580_REFUSAL_LINE]) : ""
    refusal == F4580_REFUSAL_TEXT ||
        push!(iss, "log line $F4580_REFUSAL_LINE != expected refusal")
    count(l -> occursin("REFUSED:", l), loglines) == 1 ||
        push!(iss, "log REFUSED marker count != 1 (single false-refusal " *
                   "classification requires exactly one)")
    # defective gate line from the COMMITTED blob (idempotent: does not
    # depend on the working tree, which the recovery candidate rewrites)
    gate_text = ""
    sb = try
        read(`git -C $P2_PROJECT_ROOT show $F4580_COMMIT:$F4580_SBATCH_REPO`,
             String)
    catch
        push!(iss, "committed defective sbatch blob unreadable")
        ""
    end
    if !isempty(sb)
        bytes2hex(sha256(sb)) == F4580_SBATCH_SHA ||
            push!(iss, "committed sbatch blob sha != $F4580_SBATCH_SHA")
        sblines = split(sb, '\n')
        if length(sblines) >= F4580_GATE_LINE
            gate_text = String(sblines[F4580_GATE_LINE])
            (occursin("convergence criterion = 0.02", gate_text) &&
             occursin("default-3000 banner not exactly once", gate_text)) ||
                push!(iss, "committed sbatch line $F4580_GATE_LINE is " *
                           "not the defective banner gate")
        else
            push!(iss, "committed sbatch shorter than gate line")
        end
    end
    # leg 1 of the root-cause chain, SPLIT AUTHORITY: template
    # downstream overrides (ch4/n2o/cfc) vs the compiled-default C++
    # base authority (relative-base has ZERO SPECIFIC_OPTIONS in its
    # block); exact-one declaration and exact-one config-read gated
    tpl = isfile(F4580_TEMPLATE) ? read(F4580_TEMPLATE, String) : ""
    cpp = isfile(F4580_OPTIMIZE_LUT_CPP) ?
        read(F4580_OPTIMIZE_LUT_CPP, String) : ""
    isempty(cpp) && push!(iss, "pinned optimize_lut.cpp unreadable")
    dsettings = Dict{String, Any}()
    for mode in ["relative-ch4", "relative-n2o", "relative-cfc"]
        st = f4580_downstream_setting(tpl, mode)
        if st === nothing
            push!(iss, "template downstream override unreadable: $mode")
        else
            st.criterion == F4580_EXPECTED_CRITERIA[mode] ||
                push!(iss, "template $mode criterion " *
                           "$(st.criterion) != expected")
            dsettings[mode] = Dict("setting_line" => st.line,
                                   "criterion_token" => st.criterion)
        end
    end
    bset = f4580_base_source_setting(cpp)
    if bset === nothing
        push!(iss, "compiled base-source criterion not derivable " *
                   "(declaration/config-read sites != 1)")
    else
        bset.criterion == F4580_EXPECTED_CRITERIA["relative-base"] ||
            push!(iss, "compiled base criterion $(bset.criterion) " *
                       "!= expected")
    end
    # preserved-RUNROOT forensics: staged closure + partial outputs
    staged_dir = joinpath(F4580_RUNROOT, "data", "evaluation1", "lw_fluxes")
    staged = isdir(staged_dir) ? sort(readdir(staged_dir)) : String[]
    staged == F4580_STAGED_EVAL1 ||
        push!(iss, "preserved RUNROOT staged eval1 census != the " *
                   "20-name selected-mode closure")
    for (what, pth, sha, sz) in (
        ("raw2", F4580_RAW2, F4580_RAW2_SHA, F4580_RAW2_BYTES),
        ("raw3", F4580_RAW3, F4580_RAW3_SHA, F4580_RAW3_BYTES))
        isfile(pth) || (push!(iss, "$what product missing"); continue)
        filesize(pth) == sz || push!(iss, "$what byte count drift")
        f4580_sha(pth) == sha || push!(iss, "$what sha drift")
    end
    if !isempty(iss)
        foreach(i -> println("F4580 LEDGER REFUSE: ", i), iss)
        println("gate4_c3_ib_4580_failure_ledger: refused (nothing written)")
        return 1
    end
    result = Dict(
        "case" => "gate4_c3_ib_4580_failure_ledger",
        "data_mode" => "terminal_forensics_ledger",
        "status" => "c3ib_4580_failed_downstream_banner_gate_false_refusal",
        "job" => Dict(
            "job_id" => "4580",
            "job_name" => "g4-c3ib-lw-iteration-budget",
            "state" => "FAILED", "reason" => "NonZeroExitCode",
            "exit_code" => "71:0", "derived_exit_code" => "0:0",
            "restarts" => "0", "run_time" => "00:52:49",
            "time_limit" => "06:00:00",
            "start_time" => "2026-08-14T16:36:41",
            "end_time" => "2026-08-14T17:29:30",
            "command" => "/shared/home/greg/Projects/" *
                "AnalyticBandRadiation-platform/validation/results/" *
                "gate4_c3_ib_lw_iteration_budget.sbatch",
            "submit_line" => "sbatch --parsable " *
                "validation/results/gate4_c3_ib_lw_iteration_budget.sbatch",
            "stdout" => F4580_LOG),
        "durable_evidence" => Dict(
            "receipt" => Dict("path" => F4580_RECEIPT,
                "sha256" => F4580_RECEIPT_SHA,
                "bytes" => filesize(F4580_RECEIPT),
                "epoch_sidecar" => F4580_EPOCH,
                "epoch" => F4580_EPOCH_VALUE,
                "custody" => "create-once noclobber scontrol -dd " *
                    "capture, -agent42 suffix"),
            "log" => Dict("path" => F4580_LOG,
                "sha256" => F4580_LOG_SHA, "bytes" => F4580_LOG_BYTES,
                "lines" => F4580_LOG_LINES),
            "root_cause_chain" => Dict(
                "leg1_pinned_authorities" => Dict(
                    "template_downstream_overrides" => Dict(
                        "path" => F4580_TEMPLATE,
                        "sha256" => F4580_TEMPLATE_SHA,
                        "modes" => dsettings),
                    "compiled_base_source" => Dict(
                        "path" => F4580_OPTIMIZE_LUT_CPP,
                        "sha256" => F4580_OPTIMIZE_LUT_CPP_SHA,
                        "declaration_line" =>
                            bset === nothing ? nothing : bset.line,
                        "criterion_token" =>
                            bset === nothing ? nothing : bset.criterion,
                        "declaration_sites" => 1,
                        "config_read_sites" => 1,
                        "note" => "relative-base has exactly ZERO " *
                            "active SPECIFIC_OPTIONS in its template " *
                            "block; the compiled default governs")),
                "leg2_observed_banner" => Dict(
                    "log_line" => F4580_BANNER_LINE,
                    "text" => F4580_BANNER_TEXT),
                "leg3_defective_gate" => Dict(
                    "commit" => F4580_COMMIT,
                    "sbatch_repo_path" => F4580_SBATCH_REPO,
                    "sbatch_sha256" => F4580_SBATCH_SHA,
                    "gate_line" => F4580_GATE_LINE,
                    "gate_text" => gate_text,
                    "raw3_closed_log_line" => F4580_RAW3_CLOSE_LINE,
                    "refusal_log_line" => F4580_REFUSAL_LINE,
                    "refusal_text" => F4580_REFUSAL_TEXT)),
            "recovery_evidence_narrow" => Dict(
                "staging" => "all 20 selected-mode eval1 inputs staged " *
                    "and byte-verified; the stage-1b census passed; " *
                    "present.h5 and all five CH4 perturbation files " *
                    "were read (the 4578 staging failure class did " *
                    "not recur)",
                "base_pass" => "c0a base completed at its 3000-iteration " *
                    "cap (recorded observation only)",
                "downstream" => "relative-ch4 pass ran to its own " *
                    "terminal state and the raw3 product was written " *
                    "and closed BEFORE the defective gate refused"),
            "partial_outputs_forensics_only" => [
                Dict("path" => F4580_RAW2, "sha256" => F4580_RAW2_SHA,
                     "bytes" => F4580_RAW2_BYTES),
                Dict("path" => F4580_RAW3, "sha256" => F4580_RAW3_SHA,
                     "bytes" => F4580_RAW3_BYTES)],
            "partial_output_reuse" => "PROHIBITED; a fresh job must " *
                "rerun the full sandwich in its own RUNROOT",
            "runroot" => Dict("path" => F4580_RUNROOT,
                "preserved" => true,
                "access_policy" => "reviewer accesses read-only; no " *
                    "filesystem immutability seal applied",
                "staged_eval1_count" => length(staged))),
        "monitor_observations" => Dict(
            "nonwrite_review" => "REVIEWED, NON-EXHAUSTIVE: no " *
                "canonical scientific output publish/install step was " *
                "identified in the sha-verified committed sbatch blob " *
                "or observed in the pinned log; the directly " *
                "established experimental products (the raw2/raw3 " *
                "pins in durable evidence) reside under the 4580 " *
                "RUNROOT. This is a reviewed statement, not an " *
                "exhaustive filesystem non-write proof; the Slurm " *
                "log, receipt, and lock/state surfaces are expected " *
                "writes outside its scope",
            "classification" => "instrument_gate_false_refusal",
            "classified_by" => "Codex monitor terminal audit; " *
                "predicted live by Agent42 and independently " *
                "confirmed by session40 and the monitor before the " *
                "terminal event",
            "defect" => "the committed downstream banner gate " *
                "hand-assumed the base-pass convergence criterion " *
                "(0.02); the pinned template's downstream modes " *
                "(relative-ch4/n2o/cfc) set convergence_criterion=" *
                "0.0005, so the value-exact gate matched zero lines",
            "review_miss_class" => "unexercised-gate: job 4578 " *
                "terminated before this gate ever ran, and the " *
                "criterion constant was never derived from the " *
                "pinned template per-mode settings",
            "scientific_inference" => "ZERO scientific inference is " *
                "drawn from this run; no acceptance, budget, or " *
                "mechanism claim; partial outputs are forensics only",
            "terminal_contract_applied" => "FAILED is a HOLD state; " *
                "no automatic resubmission; the next action required " *
                "a new explicit Codex-monitor review and GO with " *
                "hash verification",
            "fix_direction" => "fail-closed SPLIT-AUTHORITY criterion " *
                "derivation: relative-base requires exactly ZERO " *
                "active SPECIFIC_OPTIONS in both authorities and " *
                "derives its criterion solely from the SHA-pinned " *
                "src/ecckd/optimize_lut.cpp (exactly one declaration " *
                "site, exactly one config-read site); " *
                "relative-ch4/n2o/cfc each require exactly ONE active " *
                "SPECIFIC_OPTIONS and exactly ONE criterion token " *
                "with cross-authority exact-match and no C++ " *
                "fallback; per-mode rendered banner gates; derivation " *
                "fixtures so no banner constant is hand-written"),
        "non_authorizing_note" => "this ledger records a terminal " *
            "failure; it authorizes NOTHING (no resubmission, no " *
            "recovered acceptance, no mechanism inference)",
        "disclaimer" => "writer reads the receipt, epoch sidecar, " *
            "log, pinned template, committed sbatch blob, and " *
            "preserved RUNROOT read-only; writes only its own " *
            "JSON/MD results")
    mkpath(dirname(F4580_RESULTS_JSON))
    open(F4580_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(F4580_RESULTS_MD, "w") do io
        println(io, "# Gate-4 C3-IB job 4580 terminal failure ledger\n")
        println(io, "Status: " *
            "**c3ib_4580_failed_downstream_banner_gate_false_refusal**\n")
        println(io, "| Field | Value |")
        println(io, "|---|---|")
        println(io, "| JobState | FAILED (NonZeroExitCode, 71:0) |")
        println(io, "| RunTime | 00:52:49 (limit 06:00:00) |")
        println(io, "| EndTime | 2026-08-14T17:29:30 |")
        println(io, "| Receipt | `$F4580_RECEIPT_SHA` (epoch $F4580_EPOCH_VALUE) |")
        println(io, "| Log | `$F4580_LOG_SHA` ($F4580_LOG_BYTES B) |")
        println(io, "| Base criterion authority | " *
            "`$(first(F4580_OPTIMIZE_LUT_CPP_SHA, 8))...` " *
            "optimize_lut.cpp compiled default (template has ZERO " *
            "base override) |")
        println(io, "| Root cause | instrument-gate false-refusal: " *
            "committed gate (sbatch `$(first(F4580_SBATCH_SHA, 8))...` " *
            "line $F4580_GATE_LINE) expected downstream criterion " *
            "0.02; template (`$(first(F4580_TEMPLATE_SHA, 8))...`) " *
            "sets 0.0005; observed banner log:$F4580_BANNER_LINE |")
        println(io, "| Science before refusal | 20-file staging + " *
            "census passed; c0a base capped; relative-ch4 completed, " *
            "raw3 closed (log:$F4580_RAW3_CLOSE_LINE) |")
        println(io, "| RUNROOT | `$F4580_RUNROOT` (preserved; " *
            "partial outputs prohibited from reuse; reviewer " *
            "accesses read-only) |")
        println(io, "\nClassification (monitor): instrument-gate " *
                    "false-refusal -- not scientific, not staging. " *
                    "ZERO scientific inference; no resubmission " *
                    "without explicit Codex-monitor GO; a fresh job " *
                    "must rerun the full sandwich.")
    end
    println("gate4_c3_ib_4580_failure_ledger: written")
    return 0
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end
