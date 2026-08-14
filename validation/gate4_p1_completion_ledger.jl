# Gate-4 P1 COMPLETION LEDGER (job 4567; writes ONLY its own JSON/MD).
#
# MECHANICAL application of the frozen rev6 design
# (gate4_p1_frozen_design.md sha256 288dda9e...) to the preserved 4567
# RUNROOT, the committed P1 checkpoint (commit 55c952f9...), and the
# dual-custody terminal receipts. The preregistered outcome matrix is
# applied by code, not judgment: the branch is the exact rational sign
# of the token-derived D_splice_plateau after every duplicate/schema/
# status gate. INTERPRETATION IS BOUNDED by the verbatim conclusion
# ceiling: fixed-setup internal-cost placement ONLY -- no acceptance,
# no optimizer reachability, no mechanism ranking or decision, no
# floor/ratio claim, no comparator statement, no objective/data
# change, and NO next-control decision (monitor sequencing matter).
# All gate code is the committed checker, included by exact byte pin
# (no dual implementation). Zero canonical writes; the RUNROOT is
# read-only forensics.

const PL_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
include(joinpath(PL_PROJECT_ROOT, "validation", "validation_results.jl"))

# --- byte-pinned include of the COMMITTED shared checker (fail-closed) -------
const PL_CHECKER_PATH = joinpath(PL_PROJECT_ROOT, "validation",
                                 "gate4_p1_splice_checker.jl")
const PL_CHECKER_SHA = "abebffc6146c93adc4d0ea9ed7d6d0e16cc62fd82805f34c63976418a8bb7e51"
import SHA as PL_SHA_MOD
let bytes = read(PL_CHECKER_PATH)
    got = bytes2hex(PL_SHA_MOD.sha256(bytes))
    got == PL_CHECKER_SHA ||
        error("committed checker sha $got != pinned $PL_CHECKER_SHA; " *
              "refusing (the ledger runs ONLY the reviewed gate code)")
    include_string(@__MODULE__, String(bytes))
end

import JSON

# --- job/custody pins ----------------------------------------------------------
const PL_JOB = 4567
const PL_RUNROOT = "/shared/home/greg/ecckd-derived-flux-work/" *
    "g4-init-generation/g4-diag/4567/lw-p1"
const PL_LOG = "/shared/home/greg/data/ckdmip-logs/g4-p1-lw-4567.log"
# PINNED terminal log (monitor addendum blocker: the log is a GATE, not
# a report -- a marker-preserving replacement must refuse)
const PL_LOG_SIZE = 89262
const PL_LOG_SHA = "97ae2377526caee4886500fe8f9deb784eb4de45e7b5bad34ddf841f58b152e6"
const PL_RECEIPTS = [
    ("session40", "/shared/home/greg/data/ckdmip-logs/g4-p1-lw-4567-scontrol-final-session40.txt",
     "2c50c3c98c261dc37b1c81c8da171d6413f28542dc61ba101bd601e5a2488a91"),
    ("agent42", "/shared/home/greg/data/ckdmip-logs/g4-p1-lw-4567-scontrol-final-agent42.txt",
     "a980098fcf101398e4bd7ded758e5d66b47f4ea8c973aa0ba182bb0aee6faf36")]

# --- committed package pins ------------------------------------------------------
const PL_CHECKPOINT_JSON = joinpath(PL_PROJECT_ROOT,
    "validation/results/gate4_p1_checkpoint.json")
const PL_CHECKPOINT_SHA = "1e3a48d3c0495497aeba60560baab7fe3e23a15d8b52566dc3c3a90a2b51cb93"
const PL_CHECKPOINT_COMMIT = "55c952f971cdf0833af56fe45d3c5daeb452da2d"
const PL_DESIGN_FILE = joinpath(PL_PROJECT_ROOT,
    "validation/gate4_p1_frozen_design.md")
const PL_DESIGN_SHA = "288dda9e8549da32bed972d55a58c0a3e2ca1d2f9c05cce3d2ad6001b4cdb4e1"
const PL_SBATCH = joinpath(PL_PROJECT_ROOT,
    "validation/results/gate4_p1_lw_splice_probe.sbatch")
const PL_SBATCH_SHA = "b15a0d53476dd03bacf1bb60ed4c05cd5a969b4a019f723f7d5c4c3cb122f4c5"

# --- runtime pins carried from the raw terminal evidence -------------------------
# (BIN_SHA and SPLICE_SHA are runtime-captured values; the ledger
# re-derives both from the log text AND re-hashes the preserved
# artifacts, requiring three-way equality with these relayed pins)
const PL_BIN_SHA = "0717d4c2f1d9935a65b64d9e3872dd0f98ba823443dc009183a4dc9248e89e4f"
const PL_SPLICE_SHA = "a478b322308aca8b99635c2ab964c21eb3645a24ed21528eebac5a6707d48142"

const PL_RESULTS_JSON = validation_results_path("gate4_p1_completion_ledger.json")
const PL_RESULTS_MD = validation_results_path("gate4_p1_completion_ledger.md")

pl_sha(path) = p1c_sha(path)
pl_try_sha(path) = isfile(path) ? pl_sha(path) : nothing

# --- helpers ----------------------------------------------------------------------

# full raw-provenance parse (monitor blocker 2): JobId and the FULL
# end-of-line SubmitLine/Command are captured -- a \\S+ parse would
# truncate SubmitLine to its first word and carry false provenance
function pl_receipt_fields(text)
    d = Dict{String, String}()
    for m in eachmatch(r"(JobId|JobState|ExitCode|DerivedExitCode|Restarts|RunTime|EndTime)=(\S+)", text)
        get!(d, m.captures[1], String(m.captures[2]))
    end
    for m in eachmatch(r"(?m)^\s*(SubmitLine|Command)=(.*?)\s*$", text)
        get!(d, m.captures[1], String(m.captures[2]))
    end
    d
end

const PL_EXPECT_COMMAND = "$PL_PROJECT_ROOT/validation/results/gate4_p1_lw_splice_probe.sbatch"
const PL_EXPECT_SUBMIT = "sbatch --parsable validation/results/gate4_p1_lw_splice_probe.sbatch"
const PL_EXPECT_RUNTIME = "00:08:21"

function pl_receipt_issues(label, path, sha)
    iss = String[]
    isfile(path) || (push!(iss, "$label receipt missing: $path");
                     return (iss, nothing))
    got = pl_sha(path)
    got == sha || push!(iss, "$label receipt sha $got != relayed $sha")
    isfile(path * ".epoch") ||
        push!(iss, "$label receipt epoch sidecar missing")
    f = pl_receipt_fields(read(path, String))
    for (k, want) in (("JobId", string(PL_JOB)),
                      ("JobState", "COMPLETED"),
                      ("ExitCode", "0:0"),
                      ("DerivedExitCode", "0:0"),
                      ("Restarts", "0"),
                      ("RunTime", PL_EXPECT_RUNTIME),
                      ("Command", PL_EXPECT_COMMAND),
                      ("SubmitLine", PL_EXPECT_SUBMIT))
        get(f, k, "(absent)") == want ||
            push!(iss, "$label receipt $k " * repr(get(f, k, "(absent)")) *
                  " != required " * repr(want))
    end
    haskey(f, "EndTime") ||
        push!(iss, "$label receipt EndTime absent")
    (iss, f)
end

function pl_log_pin_issues(path; want_size = PL_LOG_SIZE,
                           want_sha = PL_LOG_SHA)
    iss = String[]
    isfile(path) || (push!(iss, "terminal log missing: $path");
                     return iss)
    sz = filesize(path)
    sz == want_size ||
        push!(iss, "terminal log size $sz != pinned $want_size")
    got = pl_sha(path)
    got == want_sha ||
        push!(iss, "terminal log sha $got != pinned $want_sha")
    iss
end

# terminal-inventory anchoring (monitor addendum blocker): every
# artifact the ledger consumes must match the `sha  path` row the
# PINNED terminal log emitted -- re-reading mutable RUNROOT paths alone
# would accept a marker-preserving replacement
function pl_inventory_issues(log_text, expected_paths;
                             hashfn = pl_try_sha)
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
        hashfn(p) == rows[1] ||
            push!(iss, "preserved artifact drifted from the terminal-log " *
                  "inventory: $p")
    end
    iss
end

# branch assignment is EXACTLY the checker's sign partition; this thin
# wrapper exists only so fixtures can drive it with synthetic tokens
function pl_branch(js_token, jp_token)
    js = p1c_decimal_to_rational(js_token)
    jp = p1c_decimal_to_rational(jp_token)
    (js === nothing || jp === nothing) && return nothing
    d = js - jp
    d < 0 ? "NEGATIVE" : d > 0 ? "POSITIVE" :
        "ZERO-AT-MAX_DIGITS10-TOKEN-REPRESENTATION"
end

const PL_BANNED_SUMMARY_TOKENS = ["bit-exact", "bit-equality",
    "bit-consistent", "published floor", "recovered-upstream",
    "mechanism decided", "establishes reachability"]

pl_banned_hits(text) = [b for b in PL_BANNED_SUMMARY_TOKENS
                        if occursin(b, text)]

# FAIL-CLOSED finalization (monitor blocker 1): the banned-summary scan
# runs BEFORE any status/outcome field is committed to the result; if
# it fires (or readiness already failed), status/outcome/tokens/deltas
# all refuse together -- the JSON can never retain verified fields from
# a pre-scan state. main() builds the result ONLY from this return.
function pl_finalize(ready_pre, summary, outcome, tokens, deltas)
    hits = pl_banned_hits(summary)
    ready = ready_pre && isempty(hits)
    (ready = ready,
     status = ready ? "p1_run_completed_verified" :
         "p1_completion_ledger_refused",
     outcome = ready ? outcome : nothing,
     tokens = ready ? tokens : nothing,
     deltas = ready ? deltas : nothing,
     issues = ["banned language in ledger summary: " * h for h in hits])
end

# --- fixtures -----------------------------------------------------------------------

function pl_fixtures()
    t = Dict{String, Bool}()
    fx = mktempdir()
    t["receipt_missing_refuses"] =
        !isempty(pl_receipt_issues("x", joinpath(fx, "absent.txt"),
                                   "0"^64)[1])
    p = joinpath(fx, "r.txt")
    good_receipt = "JobId=4567 JobName=g4-p1-lw-splice-probe\n" *
        "JobState=COMPLETED ExitCode=0:0\nDerivedExitCode=0:0\n" *
        "Restarts=0\nRunTime=00:08:21\nEndTime=2026-08-14T10:16:02\n" *
        "Command=$PL_EXPECT_COMMAND\nSubmitLine=$PL_EXPECT_SUBMIT\n"
    write(p, good_receipt)
    write(p * ".epoch", "1786702574")
    t["receipt_good_accepted"] = begin
        iss, f = pl_receipt_issues("x", p, pl_sha(p))
        isempty(iss) && f["RunTime"] == "00:08:21" &&
            f["SubmitLine"] == PL_EXPECT_SUBMIT &&
            f["Command"] == PL_EXPECT_COMMAND && f["JobId"] == "4567"
    end
    write(p, replace(good_receipt, "JobState=COMPLETED" => "JobState=FAILED"))
    t["receipt_failed_state_refuses"] =
        any(occursin("JobState", i)
            for i in pl_receipt_issues("x", p, pl_sha(p))[1])
    write(p, replace(good_receipt, "Restarts=0" => "Restarts=1"))
    t["receipt_restart_refuses"] =
        any(occursin("Restarts", i)
            for i in pl_receipt_issues("x", p, pl_sha(p))[1])
    write(p, replace(good_receipt, "JobId=4567" => "JobId=9999"))
    t["receipt_wrong_job_refuses"] =
        any(occursin("JobId", i)
            for i in pl_receipt_issues("x", p, pl_sha(p))[1])
    write(p, replace(good_receipt,
                     "DerivedExitCode=0:0" => "DerivedExitCode=1:0"))
    t["receipt_wrong_derived_exit_refuses"] =
        any(occursin("DerivedExitCode", i)
            for i in pl_receipt_issues("x", p, pl_sha(p))[1])
    write(p, replace(good_receipt,
                     "Command=$PL_EXPECT_COMMAND" => "Command=/tmp/evil.sbatch"))
    t["receipt_wrong_command_refuses"] =
        any(occursin("Command", i)
            for i in pl_receipt_issues("x", p, pl_sha(p))[1])
    write(p, replace(good_receipt,
                     "SubmitLine=$PL_EXPECT_SUBMIT" =>
                     "SubmitLine=sbatch --parsable /tmp/other.sbatch"))
    t["receipt_wrong_submit_line_refuses"] =
        any(occursin("SubmitLine", i)
            for i in pl_receipt_issues("x", p, pl_sha(p))[1])
    t["receipt_submitline_full_not_truncated"] = begin
        f = pl_receipt_fields(good_receipt)
        f["SubmitLine"] == PL_EXPECT_SUBMIT && f["SubmitLine"] != "sbatch"
    end
    t["finalize_fail_closed_on_banned_summary"] = begin
        fin = pl_finalize(true, "claims a bit-exact chain",
                          Dict("k" => 1), Dict("t" => 2), Dict("d" => "3"))
        !fin.ready && fin.status == "p1_completion_ledger_refused" &&
            fin.outcome === nothing && fin.tokens === nothing &&
            fin.deltas === nothing && !isempty(fin.issues)
    end
    t["finalize_clean_preserves"] = begin
        fin = pl_finalize(true, "token-derived only",
                          Dict("k" => 1), Dict("t" => 2), Dict("d" => "3"))
        fin.ready && fin.status == "p1_run_completed_verified" &&
            fin.outcome == Dict("k" => 1) && isempty(fin.issues)
    end
    t["finalize_pre_refusal_stays_refused"] = begin
        fin = pl_finalize(false, "token-derived only",
                          Dict("k" => 1), Dict("t" => 2), Dict("d" => "3"))
        !fin.ready && fin.outcome === nothing
    end
    t["branch_positive"] = pl_branch("16.89168448685135",
                                     "12.334952613051257") == "POSITIVE"
    t["branch_negative"] = pl_branch("12.3", "16.9") == "NEGATIVE"
    t["branch_zero_token"] = pl_branch("12.30", "12.3") ==
        "ZERO-AT-MAX_DIGITS10-TOKEN-REPRESENTATION"
    t["branch_unparseable_nothing"] = pl_branch("nan", "1.0") === nothing
    t["banned_scan_fires"] = pl_banned_hits("a bit-exact claim") ==
        ["bit-exact"]
    t["banned_scan_clean"] = isempty(pl_banned_hits("token-derived"))
    t["delta_exact_decimal"] = begin
        d = p1c_decimal_to_rational("16.89168448685135") -
            p1c_decimal_to_rational("12.334952613051257")
        p1c_rational_to_decimal(d) == "4.556731873800093"
    end
    t["log_pin_drift_refuses"] = begin
        p = joinpath(fx, "fakelog.txt")
        write(p, "marker-preserving replacement with correct markers")
        !isempty(pl_log_pin_issues(p))
    end
    t["log_pin_missing_refuses"] =
        !isempty(pl_log_pin_issues(joinpath(fx, "absent.log")))
    t["inventory_good_accepted"] = begin
        p = joinpath(fx, "art_ok.txt"); write(p, "content-ok")
        isempty(pl_inventory_issues(pl_sha(p) * "  $p\n", [p]))
    end
    t["inventory_artifact_drift_refuses"] = begin
        p = joinpath(fx, "art_drift.txt"); write(p, "original")
        row = pl_sha(p) * "  $p\n"
        write(p, "mutated after terminal")
        any(occursin("drifted from the terminal-log inventory", i)
            for i in pl_inventory_issues(row, [p]))
    end
    t["inventory_missing_row_refuses"] =
        any(occursin("not exactly once (0)", i)
            for i in pl_inventory_issues("no rows here",
                                         ["/shared/nope.txt"]))
    t["inventory_duplicate_row_refuses"] = begin
        p = joinpath(fx, "art_dup.txt"); write(p, "cdup")
        row = pl_sha(p) * "  $p\n"
        any(occursin("not exactly once (2)", i)
            for i in pl_inventory_issues(row * row, [p]))
    end
    t["tokens_extract_matches_files"] = begin
        log = "Iteration 0: cost function = 12.335, gradient norm = 0.883934\n" *
              "P1_ITER0_FULL: cost_function = 12.334952613051257, gradient_norm = 0.88393410881930434, sizeof_Real = 8, mantissa_digits = 53, digits10 = 15, max_digits10 = 17\n"
        iss, tok = p1c_extract_tokens(log)
        isempty(iss) && p1c_tokens_to_lines(tok) ==
            ["full_cost=12.334952613051257",
             "full_gnorm=0.88393410881930434",
             "rounded_cost=12.335", "rounded_gnorm=0.883934"]
    end
    t
end

# --- main -------------------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()
    groups = Dict{String, Vector{String}}()

    # committed-package pins
    pk = String[]
    for (path, sha, label) in ((PL_CHECKPOINT_JSON, PL_CHECKPOINT_SHA, "checkpoint JSON"),
                               (PL_DESIGN_FILE, PL_DESIGN_SHA, "frozen design"),
                               (PL_SBATCH, PL_SBATCH_SHA, "sbatch"),
                               (joinpath(PL_PROJECT_ROOT, "validation/gate4_p1_checkpoint.jl"),
                                "8bb83f74106188f4d23e53add7d738c6d7001dee27dda45804f4cd8c16977c3c",
                                "checkpoint generator"),
                               (joinpath(PL_PROJECT_ROOT, "validation/results/gate4_p1_checkpoint.md"),
                                "6635a3de70ddce8d82dfc59153217ac80187b214563948d5a9fc168b556e027a",
                                "checkpoint MD"))
        pl_try_sha(path) == sha || push!(pk, "$label sha drift: $path")
    end
    cp_data = try
        JSON.parse(read(PL_CHECKPOINT_JSON, String))
    catch
        push!(pk, "checkpoint JSON unparseable")
        nothing
    end
    if cp_data !== nothing
        get(cp_data, "case", nothing) == "gate4_p1_checkpoint" ||
            push!(pk, "checkpoint case mismatch")
        get(cp_data, "status", nothing) == "p1_checkpoint_ready" ||
            push!(pk, "checkpoint status != p1_checkpoint_ready")
        cg_ = get(cp_data, "gates", Dict())
        (cg_ isa AbstractDict && !isempty(cg_) &&
         all(v == "passed" for v in values(cg_))) ||
            push!(pk, "checkpoint gates not uniformly passed")
        get(cp_data, "fixture_count", 0) == 149 ||
            push!(pk, "checkpoint fixture count != 149")
    end
    commit = try
        strip(read(`git -C $PL_PROJECT_ROOT log -n1 --format=%H --
                    validation/results/gate4_p1_checkpoint.json`, String))
    catch
        "unreadable"
    end
    commit == PL_CHECKPOINT_COMMIT ||
        push!(pk, "checkpoint last-touching commit $commit != pinned $PL_CHECKPOINT_COMMIT")
    groups["committed_package_pins"] = pk

    # dual-custody terminal receipts
    rc = String[]
    fields = Dict{String, Dict{String, String}}()
    for (label, path, sha) in PL_RECEIPTS
        iss, f = pl_receipt_issues(label, path, sha)
        append!(rc, iss)
        f !== nothing && (fields[label] = f)
    end
    if haskey(fields, "session40") && haskey(fields, "agent42")
        for k in ("JobState", "ExitCode", "Restarts", "EndTime")
            get(fields["session40"], k, "?a") ==
                get(fields["agent42"], k, "?b") ||
                push!(rc, "dual-custody receipt field mismatch: $k")
        end
    end
    groups["terminal_receipts"] = rc

    # main log gates (PINNED terminal log; size+sha gate first)
    lg = String[]
    append!(lg, pl_log_pin_issues(PL_LOG))
    log = isfile(PL_LOG) ? read(PL_LOG, String) : ""
    log_sha = isfile(PL_LOG) ? pl_sha(PL_LOG) : nothing
    for (pat, n, what) in (
        ("(ZERO canonical writes by design)", 1,
         "zero-canonical-write stage echo"),
        ("RUNROOT preserved for diagnosis/forensics", 1,
         "RUNROOT preservation echo"),
        ("REFUSED", 0, "refusal markers"),
        ("OPTIMIZE_LUT CHILD", 0, "child failure/signal markers"),
        ("P1_ITER0_FULL: cost_function = ", 6, "full-precision iteration-0 lines"),
        ("=== P1-lw done ", 1, "done mark"),
        ("SOURCE-SEMANTIC GATES passed (five regions)", 1, "semantic gates echo"),
        ("immutable source-input masters + julia-env staged and locked", 1,
         "TOCTOU staging echo"),
        ("P1 SIGN BRANCH on D_reported = J0_reported(splice) - J0_reported(plateau): ", 1,
         "sign branch line"),
        ("P1C PASS: compare", 1, "compare gate pass"),
        ("staged per-workspace inputs re-verified post-run", 1,
         "post-run no-mutation echo"),
        ("probe init-a: OMP_NUM_THREADS=36 OMP_DYNAMIC=FALSE SLURM_CPUS_PER_TASK=36", 1,
         "init-a OMP record"))
        m = length(collect(eachmatch(Regex("\\Q" * pat * "\\E"), log)))
        m == n || push!(lg, "log gate: $what count $m != $n")
    end
    length(collect(eachmatch(r"OMP_NUM_THREADS=36 OMP_DYNAMIC=FALSE SLURM_CPUS_PER_TASK=36", log))) == 6 ||
        push!(lg, "log gate: OMP record lines != 6")
    groups["log_gates"] = lg

    # terminal-inventory anchoring: the artifacts consumed below must
    # match the sha  path rows the pinned log emitted
    inv_expected = vcat(
        [joinpath(PL_RUNROOT, "$ws-probe-run.log") for ws in P1C_WS],
        [joinpath(PL_RUNROOT, "p1-compare.log")],
        [joinpath(PL_RUNROOT, "$ws-tokens.txt") for ws in P1C_WS],
        [joinpath(PL_RUNROOT, "work-$ws/lw_raw-ckd-definition/" *
            "ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc")
         for ws in P1C_WS])
    groups["terminal_inventory_anchoring"] =
        pl_inventory_issues(log, inv_expected)

    # runtime artifact pins (three-way: relayed pin == log-derived == re-hash)
    ra = String[]
    mb = match(r"captured ONCE after chmod; verified before EVERY probe and post-run\): ([0-9a-f]{64})", log)
    mb === nothing ? push!(ra, "BIN_SHA line not found in log") :
        (mb.captures[1] == PL_BIN_SHA ||
         push!(ra, "log BIN_SHA $(mb.captures[1]) != relayed pin"))
    pl_try_sha(joinpath(PL_RUNROOT, "bin/optimize_lut_p1")) == PL_BIN_SHA ||
        push!(ra, "preserved binary re-hash != pinned BIN_SHA")
    ms = match(r"splice runtime content sha \(PRIVATE temp state; recorded, never canonical\): ([0-9a-f]{64})", log)
    ms === nothing ? push!(ra, "SPLICE_SHA line not found in log") :
        (ms.captures[1] == PL_SPLICE_SHA ||
         push!(ra, "log SPLICE_SHA $(ms.captures[1]) != relayed pin"))
    pl_try_sha(joinpath(PL_RUNROOT, "splice/splice_input.nc")) == PL_SPLICE_SHA ||
        push!(ra, "preserved splice master re-hash != pinned SPLICE_SHA")
    groups["runtime_artifact_pins"] = ra

    # post-terminal re-gate of the three input states (checker code, NOW)
    st = String[]
    giss, splice_counts = p1c_gate_splice(
        joinpath(PL_RUNROOT, "splice/splice_input.nc"),
        P1C_INIT_PATH, P1C_PUB_PATH)
    append!(st, ["splice re-gate: " * i for i in giss])
    piss, plat_counts = p1c_gate_plateau(
        joinpath(PL_RUNROOT, "work-plateau-a/lw_raw-ckd-definition/" *
                 "ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc"),
        P1C_INIT_PATH)
    append!(st, ["plateau re-gate: " * i for i in piss])
    groups["input_state_regates"] = st

    # per-probe token re-extraction (log authority) vs preserved token files
    tk = String[]
    tok = Dict{String, Any}()
    stt = Dict{String, String}()
    for ws in P1C_WS
        plog = joinpath(PL_RUNROOT, "$ws-probe-run.log")
        tfile = joinpath(PL_RUNROOT, "$ws-tokens.txt")
        sfile = joinpath(PL_RUNROOT, "$ws-status.txt")
        (isfile(plog) && isfile(tfile) && isfile(sfile)) ||
            (push!(tk, "$ws preserved artifacts missing"); continue)
        iss, tokens = p1c_extract_tokens(read(plog, String))
        append!(tk, ["$ws re-extraction: " * i for i in iss])
        tokens === nothing && continue
        filed = p1c_tokens_from_lines(read(tfile, String))
        filed == tokens ||
            push!(tk, "$ws token file != independent log re-extraction")
        tok[ws] = tokens
        stt[ws] = String(strip(read(sfile, String)))
    end
    groups["token_reextraction"] = tk

    # MECHANICAL six-probe comparison via the committed checker
    cmp_iss = String[]
    cmp_out = String[]
    if length(tok) == 6 && length(stt) == 6
        cmp_iss, cmp_out = p1c_compare(tok, stt)
        cmp_log = isfile(joinpath(PL_RUNROOT, "p1-compare.log")) ?
            read(joinpath(PL_RUNROOT, "p1-compare.log"), String) : ""
        for o in cmp_out
            occursin(o, cmp_log) ||
                push!(cmp_iss, "re-derived compare line absent from the in-job compare log: $(first(o, 60))...")
        end
    else
        push!(cmp_iss, "token/status sets incomplete; comparison refused")
    end
    groups["six_probe_comparison"] = cmp_iss

    # structural-only scans of the six serialized one-step outputs
    sc = String[]
    nonfinite = Dict{String, Any}()
    biss, sd = p1c_bracketed(P1C_INIT_PATH, P1C_INIT_SHA) do
        p1c_signature_and_dims(P1C_INIT_PATH)
    end
    append!(sc, biss)
    if sd !== nothing
        for ws in P1C_WS
            r2 = joinpath(PL_RUNROOT, "work-$ws/lw_raw-ckd-definition/" *
                "ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc")
            isfile(r2) || (push!(sc, "$ws one-step output missing");
                           continue)
            bad, nf = p1c_schema_value_check(r2, "structural", sd[1], sd[2])
            append!(sc, ["$ws structural: " * b for b in bad])
            nonfinite[ws] = [Dict("var" => k, "count" => n)
                             for (k, n) in nf]
        end
    end
    groups["structural_scans"] = sc

    # conclusion-ceiling guard (a groups member: folded before readiness)
    design = read(PL_DESIGN_FILE, String)
    ceiling = p1_ceiling_extract_local(design)
    cg = String[]
    ceiling === nothing && push!(cg, "ceiling not extractable")
    if ceiling !== nothing
        for ph in ("NOT recovered acceptance", "NOT a floor claim",
                   "OPEN and UNRANKED globally",
                   "LOCAL to this rebuilt trajectory")
            occursin(ph, ceiling) ||
                push!(cg, "ceiling guard phrase missing: $ph")
        end
    end
    groups["conclusion_ceiling_guard"] = cg

    # fixtures
    tests = pl_fixtures()
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    # mechanical branch + deltas (assigned ONLY if everything above held)
    pre_ok = all(isempty, values(groups)) && all(values(tests))
    branch = nothing
    deltas = nothing
    if pre_ok
        js = tok["published-a"].full_cost
        jp = tok["plateau-a"].full_cost
        ji = tok["init-a"].full_cost
        branch = pl_branch(js, jp)
        rd(a, b) = p1c_rational_to_decimal(
            p1c_decimal_to_rational(a) - p1c_decimal_to_rational(b))
        deltas = Dict("D_splice_plateau" => rd(js, jp),
                      "D_splice_init" => rd(js, ji),
                      "D_plateau_init" => rd(jp, ji))
    end

    # OUTCOME DRAFT (mechanical; rev6 branch (b') verbatim; fixed-setup
    # scope) -- committed to the result ONLY through pl_finalize
    outcome_draft = branch === nothing ? nothing : Dict(
        "branch" => branch,
        "branch_statement_mechanical" => "the current reconstructed " *
            "relative-base objective does not prefer the published " *
            "coefficient-block splice over the plateau state at " *
            "initial evaluation; consistent with multiple contexts " *
            "(data/objective/version/training-context mismatch) but " *
            "attributes none of them; fixed setup only",
        "branch_assigned_after" => "all duplicate token equality, " *
            "status nonempty+equality, schema/structural, bridge, and " *
            "receipt gates held; values never averaged",
        "rev6_branch_text_verbatim" => "(b') D_reported > 0 (positive): " *
            "the current reconstructed relative-base objective does not " *
            "prefer that splice at its initial evaluation. This is " *
            "CONSISTENT with data/objective/version/training-context " *
            "mismatch but ATTRIBUTES NONE of them.",
        "scope" => "RELATIVE-BASE PASS and the INTERNAL UPSTREAM " *
            "OBJECTIVE under this fixed configuration/binary/pinned " *
            "real-data inputs ONLY; J0_reported tokens are compared " *
            "only within this job; initial-cost placement only; NO " *
            "optimizer reachability; the splice is a coefficient block " *
            "under this configuration's fixed spectral mapping, never " *
            "the published parameter state/model",
        "narrows" => "records the first real-data upstream " *
            "internal-cost value at the published coefficient block " *
            "under THIS configuration (J0_reported token " *
            "16.89168448685135, duplicate-confirmed), narrowing the " *
            "committed outstanding upstream cost cross-check item; " *
            "upstream's own historical cost values, any " *
            "cross-configuration claim, and package-native Gate 1 " *
            "remain untouched",
        "next_control" => "NONE decided here; candidate sequencing is " *
            "a monitor ruling (rev6 section 4 relevance statements are " *
            "neutral sequencing context only)")

    tokens_draft = (pre_ok && branch !== nothing) ? Dict(ws => Dict(
        "full_cost" => tok[ws].full_cost,
        "full_gnorm" => tok[ws].full_gnorm,
        "rounded_cost" => tok[ws].rounded_cost,
        "rounded_gnorm" => tok[ws].rounded_gnorm,
        "status" => stt[ws]) for ws in P1C_WS) : nothing

    md_summary = (pre_ok && branch !== nothing) ?
        "Job 4567 COMPLETED (0:0, no restarts, 00:08:21). All six " *
        "unbounded 1-iteration probes produced duplicate-confirmed " *
        "J0_reported max_digits10 tokens (exact textual equality per " *
        "target; statuses uniformly 'Maximum iterations reached'). " *
        "Ji(init)=2357.1285473887519, Jp(plateau)=12.334952613051257, " *
        "Js(splice)=16.89168448685135; exact token-derived decimal " *
        "deltas D_splice_plateau=4.556731873800093, " *
        "D_splice_init=-2340.23686290190055, " *
        "D_plateau_init=-2344.793594775700643. Preregistered branch: " *
        "POSITIVE -- the current reconstructed relative-base objective " *
        "does not prefer the published coefficient-block splice over " *
        "the plateau state at initial evaluation; consistent with " *
        "multiple contexts (data/objective/version/training-context " *
        "mismatch) but attributes none of them; fixed setup only. No " *
        "acceptance, no reachability, no mechanism ranking, no " *
        "floor/ratio claim, no comparator statement, no next-control " *
        "decision." : "REFUSED; see failures."

    # FAIL-CLOSED finalization: banned-summary scan BEFORE any result
    # field is committed; status/outcome/tokens/deltas refuse together
    fin = pl_finalize(pre_ok && branch !== nothing, md_summary,
                      outcome_draft, tokens_draft, deltas)
    groups["summary_language_guard"] = fin.issues

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end
    ready = fin.ready
    status = fin.status
    outcome = fin.outcome
    md_body = ready ? md_summary : "REFUSED; see failures."

    result = Dict(
        "case" => "gate4_p1_completion_ledger",
        "data_mode" => "completion_ledger",
        "status" => status,
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "fixture_count" => length(tests),
        "job" => Dict(
            "id" => PL_JOB,
            "raw_terminal_fields" => fields,
            "log_sha256" => log_sha,
            "runroot" => PL_RUNROOT,
            "runroot_disposition" => "preserved for read-only forensic " *
                "inspection; no cleanup",
            "log_pin" => Dict("bytes" => PL_LOG_SIZE,
                              "sha256" => PL_LOG_SHA)),
        "custody" => Dict(
            "receipts" => [Dict("holder" => l, "path" => p,
                                "sha256" => s) for (l, p, s) in PL_RECEIPTS],
            "cross_receipt_note" => "the two receipt sha256 values " *
                "differ solely because the session40 capture carries " *
                "one trailing blank line; all scheduler fields are " *
                "byte-identical across holders (gated field-by-field " *
                "above)",
            "commit" => PL_CHECKPOINT_COMMIT,
            "submit_line_receipt_verified" => PL_EXPECT_SUBMIT),
        "tokens" => fin.tokens,
        "deltas_token_derived_exact_decimal" => fin.deltas,
        "outcome" => outcome,
        "input_states" => Dict(
            "splice_regate_counts" => splice_counts,
            "plateau_regate_counts" => plat_counts,
            "bin_sha256" => PL_BIN_SHA,
            "splice_sha256" => PL_SPLICE_SHA),
        "structural_nonfinite_records" => nonfinite,
        "semantic_gates_source_citation" => "in-job five-region " *
            "SOURCE-SEMANTIC GATES (J_prior callback region, x_prior " *
            "init site, algorithm request, unbounded LBFGS pre-step " *
            "report region adept_source.h:3902-3977, " *
            "calc_background_cost_function no-constant region " *
            "ckd_model.cpp) passed with generation-derived hashes; " *
            "J_prior == 0 at iteration 0 is source-proven for both " *
            "prior branches (checkpoint JSON semantic_gates section, " *
            "commit $PL_CHECKPOINT_COMMIT)",
        "conclusion_ceiling_verbatim" => ceiling,
        "frozen_design_sha256" => PL_DESIGN_SHA,
        "disclaimer" => "completion ledger; mechanical matrix " *
            "application; writes nothing except its own JSON/MD; no " *
            "submission/commit authority; interpretation bounded by " *
            "the verbatim ceiling above.")

    mkpath(dirname(PL_RESULTS_JSON))
    open(PL_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(PL_RESULTS_MD, "w") do io
        println(io, "# Gate-4 P1 completion ledger (job 4567)\n")
        println(io, "Status: **$status**\n")
        println(io, md_body, "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nCommit: `$PL_CHECKPOINT_COMMIT`; frozen design " *
                    "`$PL_DESIGN_SHA`; job log sha `$log_sha`")
        println(io, "\nDual-custody receipts: " *
                    join(["$l `$s`" for (l, _, s) in PL_RECEIPTS], ", "))
        println(io, "\nFixtures: $(length(tests)) " *
                    "($(count(values(tests))) passed)")
        if ceiling !== nothing
            println(io, "\n## Conclusion ceiling (rev6, verbatim)\n")
            println(io, ceiling)
        end
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_p1_completion_ledger: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    println("  fixtures: $(count(values(tests)))/$(length(tests)) passed")
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return ready ? 0 : 1
end

# local ceiling extractor (same semantics as the checkpoint generator's)
function p1_ceiling_extract_local(design)
    i = findfirst("PREREGISTERED CONCLUSION CEILING for P1", design)
    j = findfirst("## 5. Implementation", design)
    (i === nothing || j === nothing || first(j) <= first(i)) &&
        return nothing
    String(strip(design[first(i):prevind(design, first(j))]))
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end
