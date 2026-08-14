# Gate-4 P2 COMPLETION LEDGER (job 4575; writes ONLY its own JSON/MD).
#
# MECHANICAL application of the frozen P2 design
# (gate4_p2_frozen_design.md sha256 c6c76385...) to the preserved 4575
# RUNROOT, the committed P2 checkpoint (commit 3f872216...), and the
# dual-custody terminal receipts. Branches are the exact decimal signs
# of the token-derived deltas after every duplicate/control/schema
# gate; the residual label is used ONLY under the GRANTED license; the
# instrument-ordering reversal is stated ONLY because both exact
# orderings hold on their own committed records, as a recorded
# placement fact, never an explanation. INTERPRETATION IS BOUNDED by
# the verbatim conclusion ceiling: private diagnostic placement only;
# no recovered acceptance; no objective-change authorization; no
# optimizer reachability; no mechanism localization/ranking; the
# <=1.05 gate untouched; no automatic next-control decision.
# Gate code = the COMMITTED P2 checker included by exact byte pin
# (chain include intentionally disabled: compare-side gates only).
# Custody classification (monitor ruling): job 4576 = PRE-FREEZE
# DESIGNED LOCK REFUSAL (duplicate-submission race; evidence, not a
# scientific failure); the session40 `-final-` 4575 receipt = RUNNING
# SNAPSHOT (disclosed premature capture, preserved immutable);
# `-terminal-session40` = the true session40 terminal custody leg.

const QL_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
include(joinpath(QL_PROJECT_ROOT, "validation", "validation_results.jl"))

import SHA as QL_SHA_MOD
const QL_P1_CHECKER = joinpath(QL_PROJECT_ROOT, "validation",
                               "gate4_p1_splice_checker.jl")
const QL_P1_CHECKER_SHA = "abebffc6146c93adc4d0ea9ed7d6d0e16cc62fd82805f34c63976418a8bb7e51"
const QL_P2_CHECKER = joinpath(QL_PROJECT_ROOT, "validation",
                               "gate4_p2_hard_objective_checker.jl")
const QL_P2_CHECKER_SHA = "2ba2fac1947fa727bd35d5931923a62edd77f8a82646024781fd2f74960ac575"
for (path, sha) in ((QL_P1_CHECKER, QL_P1_CHECKER_SHA),
                    (QL_P2_CHECKER, QL_P2_CHECKER_SHA))
    got = bytes2hex(QL_SHA_MOD.sha256(read(path)))
    got == sha || error("committed checker sha $got != pinned $sha: $path")
end
ENV["P2C_P1_CHECKER"] = QL_P1_CHECKER
delete!(ENV, "P2C_CHAIN_DIR")   # compare-side gates only; no evaluator
include_string(@__MODULE__, read(QL_P2_CHECKER, String))

import JSON

# --- job/custody pins -----------------------------------------------------------
const QL_JOB = 4575
const QL_RUNROOT = "/shared/home/greg/ecckd-derived-flux-work/" *
    "g4-init-generation/g4-diag/4575/lw-p2"
const QL_LOG = "/shared/home/greg/data/ckdmip-logs/g4-p2-lw-4575.log"
const QL_LOG_SIZE = 13338
const QL_LOG_SHA = "ede18984920a2d8cd3b2c8511a499fbb97804ac6441e51c51e3d9130c129a7a7"
const QL_RECEIPTS = [
    ("session40_terminal",
     "/shared/home/greg/data/ckdmip-logs/g4-p2-lw-4575-scontrol-terminal-session40.txt",
     "501d407945891879193a14e747347d61534d3f1e0c8896448a0888ae741af16a",
     "terminal custody leg"),
    ("agent42_terminal",
     "/shared/home/greg/data/ckdmip-logs/g4-p2-lw-4575-scontrol-final-agent42.txt",
     "b98b0796312f3a8499fc46f77900b5e44eed02d6549a12ea36c6e451f2bb7aa2",
     "terminal custody leg"),
    ("session40_running_snapshot",
     "/shared/home/greg/data/ckdmip-logs/g4-p2-lw-4575-scontrol-final-session40.txt",
     "9b981624d880f0da19fced779647193bdb7cbe4d0ffd4bf300d2de4651dea926",
     "RUNNING snapshot (disclosed premature capture; NOT terminal evidence)")]
const QL_4576 = Dict(
    "classification" => "pre-freeze DESIGNED LOCK REFUSAL " *
        "(duplicate-submission race; stage 0d flock; exit 73:0 in ~1s; " *
        "no stage-1 freeze, no evaluation; harness success, not a P2 " *
        "scientific/package failure)",
    "log" => "/shared/home/greg/data/ckdmip-logs/g4-p2-lw-4576.log",
    "log_sha256" => "0857d6d2b6172b6d35f42e887c245d83825de273bdd4c14e6f1e79b228425ed8",
    "log_bytes" => 2772,
    "receipt_session40" => "/shared/home/greg/data/ckdmip-logs/g4-p2-lw-4576-scontrol-final-session40.txt",
    "receipt_sha256" => "9d89b3cc576c7f4d30d1cd0b5dabb2b74b4bdd5e6e124e8854e4fb25b048d715")

# --- committed package pins (commit 3f872216; six files) --------------------------
const QL_COMMIT = "3f872216a0001d093d5de06f5ad27141958f74a1"
const QL_SIX = [
    ("validation/gate4_p2_frozen_design.md",
     "c6c7638542f371ae1e44c91214d028e8f7ce9a9a61ca2be4fb0b2923f3b9f420"),
    ("validation/gate4_p2_hard_objective_checker.jl", QL_P2_CHECKER_SHA),
    ("validation/gate4_p2_checkpoint.jl",
     "cd336dece998dfb6beae0a4e9cabbfe690ea648b059ee7dc203bf89d061455a3"),
    ("validation/results/gate4_p2_lw_hard_objective.sbatch",
     "59f697d277d7228123f822f94c3b028f9954f0b57e6fd68bc85ecb9e2b977f39"),
    ("validation/results/gate4_p2_checkpoint.json",
     "f8f0606098f87dc3661ea9fde26147d9a93a47f59633d77b0beaaa289b383be7"),
    ("validation/results/gate4_p2_checkpoint.md",
     "340c35462f00fe102482457376c533a794f5125780ad67d7f184b14ef541a79c")]
const QL_EXPECT_SUBMIT = "sbatch --parsable validation/results/gate4_p2_lw_hard_objective.sbatch"
const QL_EXPECT_COMMAND = "$QL_PROJECT_ROOT/validation/results/gate4_p2_lw_hard_objective.sbatch"
const QL_EXPECT_RUNTIME = "00:03:26"

# --- frozen expected observations (monitor terminal audit) -------------------------
const QL_EXPECT_OBJ = Dict(
    "init" => "102.67056437657112",
    "plateau" => "22.791293464348826",
    "splice" => "0.18218653435647347",
    "published" => "0.18218645425029933")
const QL_EXPECT_DELTAS = Dict(
    "D_splice_plateau" => ("-22.60910692999235253", "NEGATIVE"),
    "D_splice_published" => ("0.00000008010617414", "POSITIVE"))
# P1 committed record (commit 4501220e): upstream J0_reported ordering
const QL_P1_LEDGER = joinpath(QL_PROJECT_ROOT,
    "validation/results/gate4_p1_completion_ledger.json")
const QL_P1_LEDGER_SHA = "9605cf64deb5cb14f2f3403d73c976b00ddfa2c7fc50adba9cb24e1dd51f2403"

ql_sha(path) = p2c_sha(path)

# SHARED parameterized semantic receipt checker (monitor delta): the
# ONE derivation used by the 4575 terminal legs, the RUNNING snapshot,
# AND the 4576 duplicate-refusal receipt; hash gates remain separate
const QL_TERMINAL_EXPECT = (("JobId", "4575"), ("JobState", "COMPLETED"),
    ("ExitCode", "0:0"), ("DerivedExitCode", "0:0"), ("Restarts", "0"),
    ("RunTime", "00:03:26"),
    ("Command", "$QL_PROJECT_ROOT/validation/results/gate4_p2_lw_hard_objective.sbatch"),
    ("SubmitLine", "sbatch --parsable validation/results/gate4_p2_lw_hard_objective.sbatch"))
const QL_SNAPSHOT_EXPECT = (("JobId", "4575"), ("JobState", "RUNNING"),
    ("Command", "$QL_PROJECT_ROOT/validation/results/gate4_p2_lw_hard_objective.sbatch"),
    ("SubmitLine", "sbatch --parsable validation/results/gate4_p2_lw_hard_objective.sbatch"))
const QL_4576_EXPECT = (("JobId", "4576"), ("JobState", "FAILED"),
    ("ExitCode", "73:0"), ("DerivedExitCode", "0:0"), ("Restarts", "0"),
    ("Command", "$QL_PROJECT_ROOT/validation/results/gate4_p2_lw_hard_objective.sbatch"),
    ("SubmitLine", "sbatch --parsable validation/results/gate4_p2_lw_hard_objective.sbatch"))
function ql_receipt_semantic_issues(text, label, expected)
    iss = String[]
    f = ql_receipt_fields(text)
    for (k, want) in expected
        get(f, k, "(absent)") == want ||
            push!(iss, "$label receipt $k " *
                  repr(get(f, k, "(absent)")) * " != " * repr(want))
    end
    (iss, f)
end
ql_try_sha(path) = isfile(path) ? ql_sha(path) : nothing

function ql_receipt_fields(text)
    d = Dict{String, String}()
    for m in eachmatch(r"(JobId|JobState|ExitCode|DerivedExitCode|Restarts|RunTime|EndTime)=(\S+)", text)
        get!(d, m.captures[1], String(m.captures[2]))
    end
    for m in eachmatch(r"(?m)^\s*(SubmitLine|Command)=(.*?)\s*$", text)
        get!(d, m.captures[1], String(m.captures[2]))
    end
    d
end

function ql_inventory_issues(log_text, expected_paths)
    iss = String[]
    emitted = Dict{String, Vector{String}}()
    for m in eachmatch(r"(?m)^([0-9a-f]{64})  (/\S+)$", log_text)
        push!(get!(emitted, String(m.captures[2]), String[]),
              String(m.captures[1]))
    end
    for p in expected_paths
        rows = get(emitted, p, String[])
        length(rows) == 1 ||
            (push!(iss, "terminal-log inventory row for $p not exactly " *
                   "once ($(length(rows)))"); continue)
        ql_try_sha(p) == rows[1] ||
            push!(iss, "preserved artifact drifted from the terminal-log " *
                  "inventory: $p")
    end
    iss
end

# fail-closed 4576 duplicate-refusal custody derivation (monitor
# ledger hold): receipt existence+sha+epoch, exact terminal fields,
# pinned log size+sha, refusal exactly once, and MECHANICAL
# pre-freeze/no-evaluation proof (zero freeze/arm/done markers)
function ql_4576_issues(; log = QL_4576["log"],
                        log_sha = QL_4576["log_sha256"],
                        log_bytes = QL_4576["log_bytes"],
                        receipt = QL_4576["receipt_session40"],
                        receipt_sha = QL_4576["receipt_sha256"])
    iss = String[]
    isfile(receipt) || push!(iss, "4576 receipt missing")
    if isfile(receipt)
        ql_sha(receipt) == receipt_sha ||
            push!(iss, "4576 receipt sha drift")
        isfile(receipt * ".epoch") ||
            push!(iss, "4576 receipt epoch sidecar missing")
        si, _ = ql_receipt_semantic_issues(read(receipt, String),
                                           "4576", QL_4576_EXPECT)
        append!(iss, si)
    end
    isfile(log) || push!(iss, "4576 evidence log missing")
    if isfile(log)
        filesize(log) == log_bytes ||
            push!(iss, "4576 log size != pinned $log_bytes")
        ql_sha(log) == log_sha || push!(iss, "4576 log sha drift")
        lt = read(log, String)
        n = length(collect(eachmatch(
            r"REFUSED: another P2-lw diagnosis job holds the lock", lt)))
        n == 1 || push!(iss, "4576 lock-refusal line count $n != 1")
        for (pat, what) in (("STAGE-1 FREEZE COMPLETE", "stage-1 freeze"),
                            ("P2C PASS: arm", "arm evaluation"),
                            ("=== P2-lw done ", "done mark"))
            m = length(collect(eachmatch(Regex("\\Q" * pat * "\\E"), lt)))
            m == 0 || push!(iss, "4576 log shows $what ($m) -- " *
                            "pre-freeze/no-evaluation classification " *
                            "would be false")
        end
    end
    iss
end

const QL_BANNED = ["recovered acceptance was", "mechanism identified",
    "bit-exact J0", "published floor", "objective change authorized",
    "next control selected",
    # monitor retraction 2026-08-14: operator phrases exceeding the
    # frozen outcome structure, banned from every emitted string
    "acceptance-equivalent", "negligible", "acceptance metric",
    "acceptance instrument", "recovered acceptance",
    "better by a factor", "faithfully descending",
    "times the published", "-fold"]
# licensed negation/ceiling phrases are STRIPPED before the scan
# (Agent 42 C1-prose pattern): licensed negative uses never
# false-positive, forbidden positive uses always hit; matching is
# CASE-INSENSITIVE with whitespace normalized (line wraps in the
# verbatim ceiling must not evade stripping)
const QL_LICENSED_STRIP = ["no recovered acceptance",
    "no recovered-acceptance", "not recovered acceptance",
    "acceptance semantics are untouched"]
function ql_banned_hits(text)
    t = replace(lowercase(text), r"\s+" => " ")
    for st in QL_LICENSED_STRIP
        t = replace(t, st => " ")
    end
    [b for b in QL_BANNED if occursin(lowercase(b), t)]
end

# fail-closed over summary AND every emitted outcome string (monitor
# hold: the strongest interpretive strings live under outcome; a clean
# summary must not launder a banned outcome)
# class-closing whole-result scan (Agent 42): EVERY string leaf of
# the result object is scanned before write, so no future prose field
# (observations/custody/disclaimer/...) can reopen the laundering gap
function ql_whole_result_scan(x)
    hits = String[]
    walk(y) = y isa AbstractString ? append!(hits, ql_banned_hits(y)) :
        y isa AbstractDict ? foreach(walk, values(y)) :
        y isa AbstractVector ? foreach(walk, y) : nothing
    walk(x)
    unique(hits)
end

# THE ONE CALLABLE FINALIZER (monitor architecture ruling): main
# builds ONE complete unconditional candidate and calls this ONCE. It
# alone combines evidence readiness + whole-result language hits, sets
# verified/refused status, and suppresses ALL interpretive fields via
# the minimal refusal template on EITHER failure class. No
# readiness-conditional prose construction exists anywhere in main.
function ql_two_phase(result, gates, fails, ready_pre, md_body)
    result["summary_md_body"] = md_body
    result["status"] = "p2_run_completed_verified"
    gates["evidence_whole_result_language_guard"] = "passed"
    result["gates"] = gates
    wr = ql_whole_result_scan(result)
    for h in wr
        push!(fails, "banned language in emitted result: " * h)
    end
    isempty(wr) ||
        (gates["evidence_whole_result_language_guard"] = "failed")
    ready = ready_pre && isempty(wr)
    status = ready ? "p2_run_completed_verified" :
        "p2_completion_ledger_refused"
    if !ready
        md_body = "REFUSED; see failures."
        result = Dict{String, Any}(
            "case" => "gate4_p2_completion_ledger",
            "data_mode" => "completion_ledger",
            "status" => status, "gates" => gates, "failures" => fails,
            "fixture_verdicts" => get(result, "fixture_verdicts", nothing),
            "fixture_count" => get(result, "fixture_count", 0),
            "note" => "interpretive fields suppressed (evidence " *
                "refusal and/or whole-result language guard); refused " *
                "template emitted")
    else
        result["status"] = status
    end
    (result, gates, fails, status, ready, md_body)
end

function ql_fixtures()
    t = Dict{String, Bool}()
    fx = mktempdir()
    good = "JobId=4575 JobName=g4-p2-lw-hard-objective\n" *
        "JobState=COMPLETED ExitCode=0:0\nDerivedExitCode=0:0\n" *
        "Restarts=0\nRunTime=00:03:26\nEndTime=2026-08-14T12:07:20\n" *
        "Command=$QL_PROJECT_ROOT/validation/results/gate4_p2_lw_hard_objective.sbatch\n" *
        "SubmitLine=$QL_EXPECT_SUBMIT\n"
    f = ql_receipt_fields(good)
    t["receipt_full_submitline"] = f["SubmitLine"] == QL_EXPECT_SUBMIT
    t["receipt_fields_parse"] = f["JobId"] == "4575" &&
        f["RunTime"] == QL_EXPECT_RUNTIME
    t["inventory_good_accepted"] = begin
        p = joinpath(fx, "a.txt"); write(p, "content")
        isempty(ql_inventory_issues(ql_sha(p) * "  $p\n", [p]))
    end
    t["inventory_drift_refuses"] = begin
        p = joinpath(fx, "b.txt"); write(p, "orig")
        row = ql_sha(p) * "  $p\n"
        write(p, "mutated")
        !isempty(ql_inventory_issues(row, [p]))
    end
    t["inventory_missing_refuses"] =
        !isempty(ql_inventory_issues("none", ["/nope"]))
    t["branch_signs_exact_decimal"] = begin
        d1 = p1c_decimal_to_rational(QL_EXPECT_OBJ["splice"]) -
             p1c_decimal_to_rational(QL_EXPECT_OBJ["plateau"])
        d2 = p1c_decimal_to_rational(QL_EXPECT_OBJ["splice"]) -
             p1c_decimal_to_rational(QL_EXPECT_OBJ["published"])
        p1c_rational_to_decimal(d1) == QL_EXPECT_DELTAS["D_splice_plateau"][1] &&
            d1 < 0 &&
            p1c_rational_to_decimal(d2) == QL_EXPECT_DELTAS["D_splice_published"][1] &&
            d2 > 0
    end
    t["custody_4576_positive"] = isempty(ql_4576_issues())
    t["custody_4576_receipt_tamper_refuses"] = begin
        q = joinpath(fx, "r4576.txt")
        write(q, read(QL_4576["receipt_session40"], String) * "# tampered\n")
        write(q * ".epoch", "1")
        any(occursin("receipt sha drift", i)
            for i in ql_4576_issues(receipt = q))
    end
    t["custody_4576_wrong_command_refuses"] = begin
        q = joinpath(fx, "r4576c.txt")
        write(q, replace(read(QL_4576["receipt_session40"], String),
                         "Command=" * QL_EXPECT_COMMAND =>
                         "Command=/tmp/evil.sbatch"))
        write(q * ".epoch", "1")
        iss2 = ql_4576_issues(receipt = q, receipt_sha = ql_sha(q))
        any(occursin("Command", i) for i in iss2)
    end
    t["custody_4576_wrong_state_refuses"] = begin
        q = joinpath(fx, "r4576b.txt")
        write(q, replace(read(QL_4576["receipt_session40"], String),
                         "JobState=FAILED" => "JobState=COMPLETED"))
        write(q * ".epoch", "1")
        iss2 = ql_4576_issues(receipt = q, receipt_sha = ql_sha(q))
        any(occursin("JobState", i) for i in iss2)
    end
    t["custody_4576_postfreeze_log_refuses"] = begin
        q = joinpath(fx, "l4576.log")
        write(q, read(QL_4576["log"], String) *
              "STAGE-1 FREEZE COMPLETE: impostor\n")
        iss2 = ql_4576_issues(log = q, log_sha = ql_sha(q),
                              log_bytes = filesize(q))
        any(occursin("stage-1 freeze", i) for i in iss2)
    end
    t["two_phase_banned_summary_refuses"] = begin
        cand = Dict{String, Any}("outcome" => Dict("k" => "clean"))
        r2, _, f2, st2, rd2, _ = ql_two_phase(cand,
            Dict{String, String}(), String[], true,
            "claims mechanism identified")
        st2 == "p2_completion_ledger_refused" && !rd2 &&
            !haskey(r2, "outcome") && !isempty(f2)
    end
    t["two_phase_evidence_refusal_clean_prose_suppresses"] = begin
        cand = Dict{String, Any}(
            "outcome" => Dict("k" => "recorded placement fact"),
            "observations" => Dict("note" => "token-derived only"))
        full_summary = "full interpretive summary: recorded placement " *
            "fact; token-derived deltas; reversal reportable"
        r2, g2, _, st2, rd2, md2 = ql_two_phase(cand,
            Dict{String, String}(), String[], false, full_summary)
        st2 == "p2_completion_ledger_refused" && !rd2 &&
            !haskey(r2, "outcome") && !haskey(r2, "observations") &&
            !haskey(r2, "summary_md_body") &&
            md2 == "REFUSED; see failures." &&
            g2["evidence_whole_result_language_guard"] == "passed"
    end
    t["whole_scan_observations_only_detects"] = begin
        r = Dict("status" => "x", "observations" =>
                 Dict("note" => "a negligible placement"),
                 "outcome" => Dict("k" => "clean"))
        "negligible" in ql_whole_result_scan(r)
    end
    t["whole_scan_custody_only_detects"] = begin
        r = Dict("custody" => Dict("receipts" =>
                 [Dict("classification" => "acceptance-equivalent leg")]))
        "acceptance-equivalent" in ql_whole_result_scan(r)
    end
    t["two_phase_observations_only_refuses"] = begin
        cand = Dict{String, Any}("status" => "p2_run_completed_verified",
            "outcome" => Dict("k" => "clean placement"),
            "observations" => Dict("note" => "a negligible shift"))
        r2, g2, f2, st2, rd2, _ = ql_two_phase(cand,
            Dict{String, String}(), String[], true, "clean body")
        st2 == "p2_completion_ledger_refused" && !rd2 &&
            !haskey(r2, "outcome") && !haskey(r2, "observations") &&
            g2["evidence_whole_result_language_guard"] == "failed" &&
            !isempty(f2)
    end
    t["two_phase_custody_only_refuses"] = begin
        cand = Dict{String, Any}("status" => "p2_run_completed_verified",
            "outcome" => Dict("k" => "clean placement"),
            "observations" => Dict("note" => "token-derived only"),
            "custody" => Dict("receipts" =>
                [Dict("classification" => "acceptance-equivalent leg")]))
        r2, g2, f2, st2, rd2, _ = ql_two_phase(cand,
            Dict{String, String}(), String[], true, "clean body")
        st2 == "p2_completion_ledger_refused" && !rd2 &&
            !haskey(r2, "outcome") && !haskey(r2, "observations") &&
            g2["evidence_whole_result_language_guard"] == "failed" &&
            !isempty(f2)
    end
    t["terminal_wrong_command_refuses_via_shared_helper"] = begin
        txt = replace(read(QL_RECEIPTS[1][2], String),
            "Command=" * QL_EXPECT_COMMAND => "Command=/tmp/evil.sbatch")
        si, _ = ql_receipt_semantic_issues(txt, "t", QL_TERMINAL_EXPECT)
        any(occursin("Command", i) for i in si)
    end
    t["snapshot_wrong_jobid_refuses_via_shared_helper"] = begin
        txt = replace(read(QL_RECEIPTS[3][2], String),
                      "JobId=4575" => "JobId=9999")
        si, _ = ql_receipt_semantic_issues(txt, "s", QL_SNAPSHOT_EXPECT)
        any(occursin("JobId", i) for i in si)
    end
    t["two_phase_clean_candidate_preserves"] = begin
        cand = Dict{String, Any}("status" => "p2_run_completed_verified",
            "outcome" => Dict("k" => "recorded placement fact"),
            "observations" => Dict("note" => "token-derived only"))
        r2, g2, _, st2, rd2, _ = ql_two_phase(cand,
            Dict{String, String}(), String[], true, "clean body")
        st2 == "p2_run_completed_verified" && rd2 &&
            haskey(r2, "outcome") && haskey(r2, "observations") &&
            g2["evidence_whole_result_language_guard"] == "passed"
    end
    t["banned_case_variation_detects"] =
        "negligible" in ql_banned_hits("a NEGLIGIBLE shift")
    t["retracted_phrase_through_finalizer_refuses"] = begin
        cand = Dict{String, Any}(
            "outcome" => Dict("x" => "better by a FACTOR of ~125"))
        r2, _, _, st2, rd2, _ = ql_two_phase(cand,
            Dict{String, String}(), String[], true, "clean summary")
        st2 == "p2_completion_ledger_refused" && !rd2 &&
            !haskey(r2, "outcome")
    end
    t["ceiling_text_scans_green"] = begin
        d = read(joinpath(QL_PROJECT_ROOT, QL_SIX[1][1]), String)
        c = ql_ceiling(d)
        c !== nothing && isempty(ql_banned_hits(c))
    end
    t["whole_scan_md_body_detects"] = begin
        r = Dict("summary_md_body" => "described as faithfully descending")
        "faithfully descending" in ql_whole_result_scan(r)
    end
    t["whole_scan_clean_passes"] = isempty(ql_whole_result_scan(
        Dict("a" => "recorded placement fact",
             "b" => [Dict("c" => "token-derived only")],
             "n" => 42)))
    t["finalize_banned_outcome_only_refuses"] = begin
        cand = Dict{String, Any}(
            "outcome" => Dict("instrument_ordering_statement" =>
                              "mechanism identified"))
        r2, _, f2, st2, rd2, _ = ql_two_phase(cand,
            Dict{String, String}(), String[], true,
            "clean placement summary")
        st2 == "p2_completion_ledger_refused" && !rd2 &&
            !haskey(r2, "outcome") && !isempty(f2)
    end
    t["finalize_clean_outcome_preserves"] = begin
        cand = Dict{String, Any}(
            "outcome" => Dict("a" => "recorded placement fact",
                              "b" => Dict("c" => "token-derived only")))
        r2, _, _, st2, rd2, _ = ql_two_phase(cand,
            Dict{String, String}(), String[], true,
            "clean placement summary")
        st2 == "p2_run_completed_verified" && rd2 && haskey(r2, "outcome")
    end
    t["banned_scan_clean_on_licensed_text"] =
        isempty(ql_banned_hits("no recovered acceptance; reversal is a " *
                               "recorded placement fact"))
    t
end

function ql_ceiling(design)
    i = findfirst("## Conclusion ceiling", design)
    j = findfirst("## Evidence machinery", design)
    (i === nothing || j === nothing) && return nothing
    String(strip(design[first(i):prevind(design, first(j))]))
end

function main()
    fails = String[]
    gates = Dict{String, String}()
    groups = Dict{String, Vector{String}}()

    pk = String[]
    for (rel, sha) in QL_SIX
        ql_try_sha(joinpath(QL_PROJECT_ROOT, rel)) == sha ||
            push!(pk, "committed pin drift: $rel")
    end
    commit = try
        strip(read(`git -C $QL_PROJECT_ROOT log -n1 --format=%H --
                    validation/results/gate4_p2_checkpoint.json`, String))
    catch
        "unreadable"
    end
    commit == QL_COMMIT ||
        push!(pk, "checkpoint last-touching commit $commit != $QL_COMMIT")
    ql_try_sha(QL_P1_LEDGER) == QL_P1_LEDGER_SHA ||
        push!(pk, "committed P1 ledger sha drift")
    groups["committed_package_pins"] = pk

    lg = String[]
    isfile(QL_LOG) || push!(lg, "terminal log missing")
    if isfile(QL_LOG)
        filesize(QL_LOG) == QL_LOG_SIZE ||
            push!(lg, "terminal log size != pinned $QL_LOG_SIZE")
        ql_sha(QL_LOG) == QL_LOG_SHA ||
            push!(lg, "terminal log sha != pinned")
    end
    log = isfile(QL_LOG) ? read(QL_LOG, String) : ""
    for (pat, n, what) in (("REFUSED", 0, "refusal markers"),
        ("P2C PASS: arm", 8, "arm pass lines"),
        ("P2C PASS: license", 1, "license pass line"),
        ("P2C PASS: compare", 1, "compare pass line"),
        ("STAGE-1 FREEZE COMPLETE", 1, "freeze marker"),
        ("P2 RESIDUAL-LABEL LICENSE: GRANTED", 1, "license grant"),
        ("staged inputs re-verified post-run", 1, "post-run reverify"),
        ("=== P2-lw done ", 1, "done mark"))
        m = length(collect(eachmatch(Regex("\\Q" * pat * "\\E"), log)))
        m == n || push!(lg, "log gate: $what count $m != $n")
    end
    groups["log_gates"] = lg

    rc = String[]
    fields = Dict{String, Dict{String, String}}()
    for (label, path, sha, class) in QL_RECEIPTS
        isfile(path) || (push!(rc, "$label receipt missing"); continue)
        ql_sha(path) == sha || push!(rc, "$label receipt sha drift")
        isfile(path * ".epoch") ||
            push!(rc, "$label epoch sidecar missing")
        si, f = ql_receipt_semantic_issues(read(path, String), label,
            class == "terminal custody leg" ? QL_TERMINAL_EXPECT :
                QL_SNAPSHOT_EXPECT)
        append!(rc, si)
        fields[label] = f
    end
    for k in ("JobState", "ExitCode", "Restarts", "EndTime")
        get(get(fields, "session40_terminal", Dict()), k, "?a") ==
            get(get(fields, "agent42_terminal", Dict()), k, "?b") ||
            push!(rc, "dual-custody terminal field mismatch: $k")
    end
    append!(rc, ql_4576_issues())
    groups["custody_receipts"] = rc

    inv_expected = vcat(
        [joinpath(QL_RUNROOT, "$arm-record.txt") for arm in P2C_ARMS],
        [joinpath(QL_RUNROOT, "$arm-arm.log") for arm in P2C_ARMS],
        [joinpath(QL_RUNROOT, "splice/splice_input.nc"),
         joinpath(QL_RUNROOT, "p2-license.log"),
         joinpath(QL_RUNROOT, "p2-compare.log")])
    groups["terminal_inventory_anchoring"] =
        ql_inventory_issues(log, inv_expected)

    # re-run the committed compare-side gates on the preserved records
    cg = String[]
    records = Dict{String, String}()
    for arm in P2C_ARMS
        p = joinpath(QL_RUNROOT, "$arm-record.txt")
        isfile(p) ? (records[arm] = read(p, String)) :
            push!(cg, "missing arm record: $arm")
    end
    obs = Dict{String, String}()
    if length(records) == 8
        append!(cg, p2c_duplicate_issues(records))
        append!(cg, p2c_control_issues(records))
        for st in P2C_STATES
            m = collect(eachmatch(r"(?m)^objective_token=(\S+)$",
                                  records["$st-a"]))
            length(m) == 1 ? (obs[st] = String(m[1].captures[1])) :
                push!(cg, "objective token not exactly once for $st")
        end
        for (st, want) in QL_EXPECT_OBJ
            get(obs, st, "(absent)") == want ||
                push!(cg, "observed $st objective " *
                      get(obs, st, "(absent)") * " != audited $want")
        end
        for arm in P2C_ARMS
            occursin("rows=24", records[arm]) ||
                push!(cg, "$arm record rows != 24")
        end
    else
        push!(cg, "record set incomplete; comparison refused")
    end
    groups["record_regates"] = cg

    dd = String[]
    design = read(joinpath(QL_PROJECT_ROOT, QL_SIX[1][1]), String)
    ceiling = ql_ceiling(design)
    ceiling === nothing && push!(dd, "ceiling not extractable")
    if ceiling !== nothing
        for ph in ("PRIVATE DIAGNOSTIC PLACEMENT ONLY",
                   "NO recovered", "NO objective-change",
                   "NO optimizer", "NO mechanism localization",
                   "NO automatic next-control")
            occursin(ph, ceiling) ||
                push!(dd, "ceiling guard phrase missing: $ph")
        end
    end
    groups["conclusion_ceiling_guard"] = dd

    tests = ql_fixtures()
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    pre_ok = all(isempty, values(groups)) && all(values(tests))
    deltas = nothing
    branches = nothing
    reversal = nothing
    # COMPUTATION GUARD (licensed per Agent 42 sweep classification +
    # monitor architecture ruling): this conditional fail-closes DATA
    # DERIVATION only (exact-decimal values from observed tokens cannot
    # execute on gate-failed inputs); outputs are data (null on
    # refusal); ALL prose/status suppression lives in ql_two_phase.
    if pre_ok
        rd(a, b) = p1c_rational_to_decimal(
            p1c_decimal_to_rational(a) - p1c_decimal_to_rational(b))
        sgn(a, b) = begin
            d = p1c_decimal_to_rational(a) - p1c_decimal_to_rational(b)
            d < 0 ? "NEGATIVE" : d > 0 ? "POSITIVE" :
                "ZERO-AT-TOKEN-REPRESENTATION"
        end
        deltas = Dict(
            "D_splice_plateau" => rd(obs["splice"], obs["plateau"]),
            "D_splice_published" => rd(obs["splice"], obs["published"]))
        branches = Dict(
            "D_splice_plateau" => sgn(obs["splice"], obs["plateau"]),
            "D_splice_published" => sgn(obs["splice"], obs["published"]))
        for (k, (dv, bv)) in QL_EXPECT_DELTAS
            (deltas[k] == dv && branches[k] == bv) ||
                push!(fails, "delta/branch $k mismatch vs audited record")
        end
        p1d = JSON.parse(read(QL_P1_LEDGER, String))
        p1_branch = get(get(p1d, "outcome", Dict()), "branch", "(absent)")
        reversal = (p1_branch == "POSITIVE" &&
                    branches["D_splice_plateau"] == "NEGATIVE")
        reversal ||
            push!(fails, "reversal precondition not met (P1 branch " *
                  "$p1_branch, P2 splice-plateau " *
                  "$(branches["D_splice_plateau"]))")
    end
    pre_ok = pre_ok && isempty(fails)

    outcome_draft = Dict(
        "branches" => branches,
        "deltas_token_derived_exact_decimal" => deltas,
        "residual_label" => "LICENSED AND USED: the eight materialized " *
            "longwave_absorption gas slices AND the complete " *
            "longwave_h2o_absorption table are exact-equal between the " *
            "loaded splice and loaded published-final, so the " *
            "+0.00000008010617414 splice-vs-published delta is the " *
            "recorded non-coefficient/materialized-model residual AS A " *
            "BLOCK at identical coefficient tables under this fixed " *
            "setup (no attribution within the block)",
        "instrument_ordering_statement" => "REPORTABLE (both exact " *
            "orderings hold on their own committed records): the P1 " *
            "upstream internal J0_reported ordered splice ABOVE plateau " *
            "(committed +4.556731873800093); the P2 package-native hard " *
            "objective orders splice BELOW plateau " *
            "(-22.60910692999235253). A recorded placement fact under " *
            "two fixed instruments/setups; never an explanation, never " *
            "a mechanism statement",
        "controls" => "all three same-job controls reproduced their " *
            "pinned literals exactly in BOTH arms (init " *
            "102.67056437657112, plateau 22.791293464348826, published " *
            "0.18218645425029933); duplicates exact-payload equal",
        "next_control" => "NONE decided here; sequencing is a monitor " *
            "ruling")

    # built UNCONDITIONALLY (monitor architecture hold): suppression on
    # refusal is ql_two_phase's alone
    summary =
        "Job 4575 COMPLETED (0:0, no restarts, 00:03:26). Eight " *
        "palindromic arms; duplicate payloads exact; all three same-job " *
        "controls reproduced their pinned literals exactly. Splice " *
        "hard-objective 0.18218653435647347 (both arms). Exact " *
        "token-derived deltas: D_splice_plateau=-22.60910692999235253 " *
        "(NEGATIVE), D_splice_published=+0.00000008010617414 " *
        "(POSITIVE). Residual label LICENSED (materialized tables " *
        "exact-equal): the +8.0e-8 block is the recorded " *
        "non-coefficient/materialized-model residual at identical " *
        "coefficients. Instrument-ordering reversal REPORTABLE as a " *
        "recorded placement fact (P1 upstream splice>plateau; P2 " *
        "hard-objective splice<plateau). Private diagnostic placement " *
        "only; no recovered acceptance; no objective-change " *
        "authorization; no optimizer reachability; no mechanism " *
        "localization or ranking; the <=1.05 gate untouched; no " *
        "automatic next-control decision."
    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end
    md_body = summary

    result = Dict{String, Any}(
        "case" => "gate4_p2_completion_ledger",
        "data_mode" => "completion_ledger",
        "status" => "pending_finalizer",
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "fixture_count" => length(tests),
        "job" => Dict("id" => QL_JOB,
            "raw_terminal_fields" => fields,
            "log_pin" => Dict("bytes" => QL_LOG_SIZE,
                              "sha256" => QL_LOG_SHA),
            "runroot" => QL_RUNROOT,
            "runroot_disposition" => "preserved for read-only forensic " *
                "inspection; no cleanup"),
        "custody" => Dict(
            "commit" => QL_COMMIT,
            "submit_line_receipt_verified" => QL_EXPECT_SUBMIT,
            "receipts" => [Dict("holder" => l, "path" => p,
                                "sha256" => s, "classification" => c)
                           for (l, p, s, c) in QL_RECEIPTS],
            "duplicate_submission_job_4576" => QL_4576,
            "checkpoint_fixtures_executed" => "68/68 at generation; " *
                "dual-reviewed; Agent 42 third-party byte-identical " *
                "regeneration"),
        "observations" => Dict(
            "objective_tokens" => obs,
            "limiting_metric" => "ecckd_clear_sky_tropical_column/" *
                "heating_rate_max_abs (all eight arms)"),
        "outcome" => outcome_draft,
        "conclusion_ceiling_verbatim" => ceiling,
        "frozen_design_sha256" => QL_SIX[1][2],
        "disclaimer" => "completion ledger; mechanical application; " *
            "writes nothing except its own JSON/MD; no " *
            "submission/commit authority; interpretation bounded by the " *
            "verbatim ceiling above.")

    # THE ONE FINALIZER CALL (readiness + language + suppression)
    result, gates, fails, status, ready, md_body =
        ql_two_phase(result, gates, fails, pre_ok, md_body)

    out_json = validation_results_path("gate4_p2_completion_ledger.json")
    out_md = validation_results_path("gate4_p2_completion_ledger.md")
    mkpath(dirname(out_json))
    open(out_json, "w") do io
        JSON.print(io, result, 2)
    end
    open(out_md, "w") do io
        println(io, "# Gate-4 P2 completion ledger (job 4575)\n")
        println(io, "Status: **$status**\n")
        println(io, md_body, "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nCommit: `$QL_COMMIT`; frozen design " *
                    "`$(QL_SIX[1][2])`; log `$QL_LOG_SHA`")
        println(io, "\nCustody: session40 terminal `501d4079...`, " *
                    "agent42 terminal `b98b0796...`; session40 " *
                    "`-final-` file = RUNNING snapshot (disclosed, " *
                    "immutable, NOT terminal evidence); job 4576 = " *
                    "pre-freeze designed lock refusal (evidence " *
                    "preserved).")
        println(io, "\nFixtures: $(length(tests)) " *
                    "($(count(values(tests))) passed)")
        if ceiling !== nothing
            println(io, "\n## Conclusion ceiling (frozen design, verbatim)\n")
            println(io, ceiling)
        end
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_p2_completion_ledger: $status")
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
