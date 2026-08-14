# Gate-4 C3-IB job-4578 TERMINAL FAILURE LEDGER writer (fail-closed).
# Durable forensics for the FAILED 134:0 terminal state of job 4578
# (staging-manifest-completeness gap: first downstream pass could not
# find ckdmip_evaluation1_lw_fluxes_present.h5 in the staged search
# paths). Separates DURABLE EVIDENCE (receipt/log/RUNROOT pins and
# verbatim extracts) from MONITOR OBSERVATIONS (classification and
# rulings). Writes NOTHING unless every pin, raw-field, and census
# gate passes. ZERO scientific inference; the 4578 RUNROOT, log, and
# receipt are immutable forensics and are only READ here.

const P2_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
include(joinpath(P2_PROJECT_ROOT, "validation", "validation_results.jl"))
using SHA
using JSON

const F4578_RECEIPT = "/shared/home/greg/data/ckdmip-logs/" *
    "g4-c3ib-lw-4578-scontrol-final-agent42.txt"
const F4578_RECEIPT_SHA =
    "f6f3a3618b5207c5e9a6645586cbe65a69038636fcfb2c406bd7dd953797c5c7"
const F4578_EPOCH = F4578_RECEIPT * ".epoch"
const F4578_EPOCH_VALUE = "1786721517"
const F4578_LOG = "/shared/home/greg/data/ckdmip-logs/g4-c3ib-lw-4578.log"
const F4578_LOG_SHA =
    "698cab0bdf65d42ebcd29796e15ece5848d679a9cbf04b4f31d7f5e535f1fbba"
const F4578_RUNROOT = "/shared/home/greg/ecckd-derived-flux-work/" *
    "g4-init-generation/g4-diag/4578/lw-c3ib"
const F4578_MISSING_INPUT = "ckdmip_evaluation1_lw_fluxes_present.h5"
const F4578_STAGED_EVAL1 = [
    "ckdmip_evaluation1_lw_fluxes_rel-1120.h5",
    "ckdmip_evaluation1_lw_fluxes_rel-180.h5",
    "ckdmip_evaluation1_lw_fluxes_rel-2240.h5",
    "ckdmip_evaluation1_lw_fluxes_rel-280.h5",
    "ckdmip_evaluation1_lw_fluxes_rel-415.h5",
    "ckdmip_evaluation1_lw_fluxes_rel-560.h5"]
const F4578_RAW_REQUIRED = [
    "JobId=4578", "JobName=g4-c3ib-lw-iteration-budget",
    "JobState=FAILED", "Reason=NonZeroExitCode", "ExitCode=134:0",
    "DerivedExitCode=0:0", "RunTime=00:38:32", "TimeLimit=06:00:00",
    "EndTime=2026-08-14T15:31:43"]
const F4578_RESULTS_JSON =
    validation_results_path("gate4_c3_ib_4578_failure_ledger.json")
const F4578_RESULTS_MD =
    validation_results_path("gate4_c3_ib_4578_failure_ledger.md")

f4578_sha(p) = bytes2hex(open(sha256, p))

function main()
    iss = String[]
    for (what, pth, pin) in (("receipt", F4578_RECEIPT, F4578_RECEIPT_SHA),
                             ("log", F4578_LOG, F4578_LOG_SHA))
        isfile(pth) || (push!(iss, "$what missing: $pth"); continue)
        f4578_sha(pth) == pin || push!(iss, "$what sha drift: $pth")
    end
    epoch = isfile(F4578_EPOCH) ? strip(read(F4578_EPOCH, String)) : nothing
    epoch == F4578_EPOCH_VALUE ||
        push!(iss, "epoch sidecar missing or value != $F4578_EPOCH_VALUE")
    receipt_text = isfile(F4578_RECEIPT) ? read(F4578_RECEIPT, String) : ""
    for r in F4578_RAW_REQUIRED
        occursin(r, receipt_text) ||
            push!(iss, "receipt missing raw field: $r")
    end
    log_text = isfile(F4578_LOG) ? read(F4578_LOG, String) : ""
    errline = nothing
    for ln in split(log_text, '\n')
        if occursin("Failed to find $F4578_MISSING_INPUT", ln)
            errline === nothing ||
                push!(iss, "missing-input error line is not unique")
            errline = String(ln)
        end
    end
    errline === nothing &&
        push!(iss, "log lacks the DataFile.cpp missing-input line")
    for req in ("terminate called after throwing an instance of 'int'",
                "OPTIMIZE_LUT CHILD FAILED rc=134")
        occursin(req, log_text) || push!(iss, "log lacks: $req")
    end
    occursin("REFUSED:", log_text) &&
        push!(iss, "log carries REFUSED markers (classification " *
                   "requires zero gate refusals before the child abort)")
    staged_dir = joinpath(F4578_RUNROOT, "data", "evaluation1", "lw_fluxes")
    staged = isdir(staged_dir) ? sort(readdir(staged_dir)) : String[]
    staged == sort(F4578_STAGED_EVAL1) ||
        push!(iss, "preserved RUNROOT staged eval1 census != the " *
                   "six-name set that defines this failure class")
    if !isempty(iss)
        foreach(i -> println("F4578 LEDGER REFUSE: ", i), iss)
        println("gate4_c3_ib_4578_failure_ledger: refused (nothing written)")
        return 1
    end
    result = Dict(
        "case" => "gate4_c3_ib_4578_failure_ledger",
        "data_mode" => "terminal_forensics_ledger",
        "status" => "c3ib_4578_failed_staging_manifest_gap",
        "job" => Dict(
            "job_id" => "4578",
            "job_name" => "g4-c3ib-lw-iteration-budget",
            "state" => "FAILED", "reason" => "NonZeroExitCode",
            "exit_code" => "134:0", "derived_exit_code" => "0:0",
            "run_time" => "00:38:32", "time_limit" => "06:00:00",
            "end_time" => "2026-08-14T15:31:43"),
        "durable_evidence" => Dict(
            "receipt" => Dict("path" => F4578_RECEIPT,
                "sha256" => F4578_RECEIPT_SHA,
                "bytes" => filesize(F4578_RECEIPT),
                "epoch_sidecar" => F4578_EPOCH,
                "epoch" => F4578_EPOCH_VALUE,
                "custody" => "create-once noclobber scontrol -dd " *
                    "capture, -agent42 suffix"),
            "log" => Dict("path" => F4578_LOG,
                "sha256" => F4578_LOG_SHA,
                "bytes" => filesize(F4578_LOG)),
            "missing_input_error_line" => errline,
            "child_failure_lines" => [
                "terminate called after throwing an instance of 'int'",
                "OPTIMIZE_LUT CHILD FAILED rc=134"],
            "failure_point" => "arm c0a, first downstream pass " *
                "(relative-ch4), TRAINING read of the first listed " *
                "input; base passes (probe, c0a relative-base) had " *
                "completed with zero REFUSED markers",
            "first_missing_input" => F4578_MISSING_INPUT,
            "runroot" => Dict("path" => F4578_RUNROOT,
                "preserved" => true,
                "staged_eval1_count" => length(staged),
                "staged_eval1_names" => staged),
            "zero_refused_markers_in_log" => true),
        "monitor_observations" => Dict(
            "classification" => "staging_manifest_completeness_gap",
            "classified_by" => "Codex monitor terminal audit, with " *
                "Agent42 independent mechanical confirmation",
            "selected_mode_eval1_closure" => 20,
            "staged_eval1_manifest" => 6,
            "omitted_inputs" => 14,
            "root_cause" => "the eval1 staging manifest was " *
                "hand-inherited from base-pass-only prior units and " *
                "never re-derived from the selected-mode pass " *
                "scripts (relative-base/ch4/n2o/cfc)",
            "scientific_inference" => "ZERO scientific inference is " *
                "drawn from this run; the partial C0a outputs are " *
                "forensics only and MUST NOT be reused; a fresh job " *
                "must rerun the full sandwich",
            "terminal_contract_applied" => "FAILED is a HOLD state; " *
                "no automatic resubmission; the next action required " *
                "a new explicit Codex-monitor review and GO with " *
                "hash verification"),
        "non_authorizing_note" => "this ledger records a terminal " *
            "failure; it authorizes NOTHING (no resubmission, no " *
            "recovered acceptance, no mechanism inference)",
        "disclaimer" => "writer reads the receipt, epoch sidecar, " *
            "log, and preserved RUNROOT read-only; writes only its " *
            "own JSON/MD results")
    mkpath(dirname(F4578_RESULTS_JSON))
    open(F4578_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(F4578_RESULTS_MD, "w") do io
        println(io, "# Gate-4 C3-IB job 4578 terminal failure ledger\n")
        println(io, "Status: **c3ib_4578_failed_staging_manifest_gap**\n")
        println(io, "| Field | Value |")
        println(io, "|---|---|")
        println(io, "| JobState | FAILED (NonZeroExitCode, 134:0) |")
        println(io, "| RunTime | 00:38:32 (limit 06:00:00) |")
        println(io, "| EndTime | 2026-08-14T15:31:43 |")
        println(io, "| Receipt | `$F4578_RECEIPT_SHA` (epoch $F4578_EPOCH_VALUE) |")
        println(io, "| Log | `$F4578_LOG_SHA` |")
        println(io, "| First missing input | `$F4578_MISSING_INPUT` |")
        println(io, "| Staged eval1 | 6 of the 20-name selected-mode closure |")
        println(io, "| RUNROOT | `$F4578_RUNROOT` (preserved, immutable) |")
        println(io, "\nClassification (monitor): staging-manifest " *
                    "completeness gap. ZERO scientific inference; no " *
                    "resubmission without explicit Codex-monitor GO; " *
                    "a fresh job must rerun the full sandwich.")
    end
    println("gate4_c3_ib_4578_failure_ledger: written")
    return 0
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end
