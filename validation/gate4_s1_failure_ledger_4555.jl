# Gate-4 S1 FAILURE LEDGER: job 4555 (attempt 1 of the triple-arm
# state-sync hypothesis test). Evidence unit; writes nothing except
# validation/results/gate4_s1_failure_ledger_4555.{json,md} (plus
# transient private temp fixtures under mktempdir).
#
# CLASSIFICATION (monitor, 2026-08-13): SEMANTIC/BUILD FAILURE at the
# stage-3 A0 configure. Gates that passed in production: the TWO
# pre-patch tree-identity gates (ARTTREE artifact manifest at stage 0c
# and COPYTREE copied-tree manifest at stage 2), the exec-bit census
# and zero-symlink checks, the frozen test-template snapshot+pins, and
# the fail-closed toolchain fingerprints. The job died in stage 3
# BEFORE the patch, so the third (post-patch POSTPATCHTREE) gate was
# NOT reached; no patch/rebuild/arm executed. RUNROOT preserved; cost
# 22 seconds.
#
# ROOT CAUSE (proven, not guessed; monitor diagnostic + Agent 42
# independent audit):
#   - the fresh autoreconf-generated configure (sha 9a2a6908...) checks
#     Adept >= 2.1 with a conftest that calls the out-of-line symbol
#     adept::compiler_version(); the m4 macro embeds its own -ladept
#     AHEAD of conftest.cpp in the test link line, which is
#     order-broken under left-to-right linker scanning (Ubuntu
#     --as-needed): the library is scanned before the object that
#     needs it -> undefined reference -> "Unable to find Adept library
#     version >= 2.1". An ARGUMENT-POSITION defect, not missing paths
#     (the -L and rpath flags were present in the failing command).
#   - the historical generated configure in the extant built tree
#     (sha 9ed1baac...) checks Adept >= 1.1, DESPITE m4/adept.m4 being
#     BYTE-IDENTICAL (sha 79d60785...) between the artifact and the
#     extant tree: the extant generated configure is STALE GENERATED
#     STATE relative to its own m4 source. Generated-configure vintage
#     differs despite identical current m4 source; therefore
#     config.status --config (user options only) was INSUFFICIENT
#     build-equivalence evidence.
#   - corrected recipe (monitor-tested in fresh isolated artifact
#     copies after autoreconf): LIBS=-ladept ALONE fails at the initial
#     "C++ compiler cannot create executables" (rc=77; the nonstandard
#     Adept lib path is unknown before the m4 check); path-only LDFLAGS
#     (-L + rpath, never -ladept) plus LIBS=-ladept passes (Adept >=
#     2.1 yes, nc_create -lnetcdf, final LIBS = -lnetcdf -ladept):
#     autoconf places user LIBS AFTER conftest.cpp, supplying the
#     resolving late -ladept. This is a BUILD-ENABLEMENT correction,
#     not a scientific change and not historical build equivalence;
#     the same corrected build is common to A0/S1, preserving the
#     internal one-factor triple-arm test. Historical 4515 remains an
#     output bridge only if the A0 raw2 matches it.

include(joinpath(@__DIR__, "validation_results.jl"))

import JSON
using SHA: sha256

const FL5_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
const FL5_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"
const FL5_RUNROOT = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/g4-diag/4555/lw-s1"

# fixed evidence timestamp = job 4555 EndTime (never wall-clock)
const FL5_EVIDENCE_TIME = "2026-08-13T21:54:01Z"

const FL5_RECEIPT_S40 = "$FL5_LOG_DIR/g4-s1-lw-4555-scontrol-final-session40.txt"
const FL5_RECEIPT_A42 = "$FL5_LOG_DIR/g4-s1-lw-4555-scontrol-final-agent42.txt"
const FL5_RECEIPT_SHA = "f496e977287029170eaa9b324c6b113ba8ce2f389f010a9610687230a8e0abd8"
const FL5_LOG = "$FL5_LOG_DIR/g4-s1-lw-4555.log"
const FL5_LOG_SHA = "32271da81abe3d369bb8573c50a3174d5f9e1ef954ece888f6c9a8f2da46c2ee"
const FL5_CONFIG_LOG = "$FL5_RUNROOT/src/ecckd-modern-paired/config.log"
const FL5_CONFIG_LOG_SHA = "b70582b756dfc6d9379cccd073e77a354581135a469ae0f25cef89cc3b2d55e8"
const FL5_FRESH_CONFIGURE = "$FL5_RUNROOT/src/ecckd-modern-paired/configure"
const FL5_FRESH_CONFIGURE_SHA = "9a2a690860ae3be9d6fe6f4eaead875ffb4394d27b2b5c10896736e5dc6a4219"
const FL5_HIST_CONFIGURE = "/shared/home/greg/ecckd-derived-flux-work/ecckd/configure"
const FL5_HIST_CONFIGURE_SHA = "9ed1baac13a17c5f537e0bad75afa38a43ece2c116ed38fee4a3446f54772dfc"
const FL5_M4_ARTIFACT = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd/m4/adept.m4"
const FL5_M4_HIST = "/shared/home/greg/ecckd-derived-flux-work/ecckd/m4/adept.m4"
const FL5_M4_SHA = "79d6078590dd7a44b912c6011f3aaf4caed909437880b3d4bd585d7ef1fbf520"

const FL5_ERROR_LINE = "configure: error: Unable to find Adept library version >= 2.1"
const FL5_UNDEF_LINE = "undefined reference to `adept::compiler_version[abi:cxx11]()'"
const FL5_CHECK_21 = "checking for Adept >= 2.1: including adept_arrays.h and linking via -ladept"
const FL5_CHECK_11 = "checking for Adept >= 1.1: including adept_arrays.h and linking via -ladept"

const FL5_EXPECT = Dict(
    "JobId" => "4555", "JobName" => "g4-s1-lw-paired-sync",
    "JobState" => "FAILED", "Reason" => "NonZeroExitCode",
    "ExitCode" => "1:0", "DerivedExitCode" => "0:0",
    "Restarts" => "0", "RunTime" => "00:00:22",
    "SubmitTime" => "2026-08-13T21:51:06",
    "StartTime" => "2026-08-13T21:53:39",
    "EndTime" => "2026-08-13T21:54:01",
    "Command" => joinpath(FL5_PROJECT_ROOT,
        "validation/results/gate4_s1_lw_state_sync.sbatch"),
    "SubmitLine" => "sbatch --parsable validation/results/gate4_s1_lw_state_sync.sbatch",
    "WorkDir" => FL5_PROJECT_ROOT,
    "StdOut" => FL5_LOG)

const FL5_RESULTS_JSON = validation_results_path("gate4_s1_failure_ledger_4555.json")
const FL5_RESULTS_MD = validation_results_path("gate4_s1_failure_ledger_4555.md")

# --- primitives -----------------------------------------------------------------

function fl5_read_pinned(path, sha; label = basename(path))
    isfile(path) || return (["$label missing: $path"], nothing)
    bytes = try
        read(path)
    catch
        return (["$label unreadable: $path"], nothing)
    end
    got = bytes2hex(sha256(bytes))
    got == sha || return (["$label sha $got != pinned $sha"], nothing)
    (String[], bytes)
end

const FL5_TOKEN_KEYS = ("JobId", "JobName", "JobState", "Reason",
    "ExitCode", "DerivedExitCode", "Restarts", "RunTime",
    "SubmitTime", "StartTime", "EndTime")

function fl5_parse_receipt(text)
    f = Dict{String, String}()
    for k in FL5_TOKEN_KEYS
        m = match(Regex("\\b" * k * "=(\\S+)"), text)
        m === nothing || (f[k] = String(m.captures[1]))
    end
    for k in ("Command", "SubmitLine", "WorkDir", "StdOut")
        m = match(Regex("^\\s*" * k * "=(.*)\$", "m"), text)
        m === nothing || (f[k] = String(strip(m.captures[1])))
    end
    f
end

function fl5_receipt_issues(f, expect)
    iss = String[]
    for (k, v) in expect
        get(f, k, "") == v ||
            push!(iss, "$k mismatch (got $(repr(get(f, k, ""))))")
    end
    sort(iss)
end

fl5_count(text, needle) = length(collect(eachmatch(
    Regex("\\Q" * needle * "\\E"), text)))

# failed-log shape: stages 0a-2 AND the stage-3 banner present (the
# banner prints before autoreconf); the configure error line exactly
# once; never a patch, arm, comparison, or done marker
function fl5_log_issues(text)
    iss = String[]
    for s in ("0a", "0b", "0c", "0d", "1", "2", "3")
        occursin("=== S1-lw stage $s", text) ||
            push!(iss, "log missing stage $s marker")
    end
    n = fl5_count(text, FL5_ERROR_LINE)
    n == 1 || push!(iss, "configure error line not exactly once ($n)")
    for bad in ("=== S1-lw stage 4", "=== S1-lw stage 5",
                "=== S1-lw stage 7", "=== S1-lw stage 8",
                "BASELINE REPEATABILITY", "PRIMARY COMPARISON",
                "=== S1-lw done ")
        occursin(bad, text) && push!(iss, "log falsely contains: $bad")
    end
    iss
end

# failed config.log: the exact link-order evidence (the m4-embedded
# -ladept BEFORE conftest.cpp, the undefined out-of-line symbol, the
# 2.1 check, the terminal error)
function fl5_configlog_issues(text)
    iss = String[]
    # config.log renders the terminal error as "configure:NNNNN: error:
    # ..." (line-numbered), unlike the job log's "configure: error: ..."
    for (label, needle) in (("2.1 check line", FL5_CHECK_21),
                            ("undefined-reference line", FL5_UNDEF_LINE),
                            ("configure error text",
                             "error: Unable to find Adept library version >= 2.1"))
        occursin(needle, text) || push!(iss, "config.log missing $label")
    end
    occursin(r"-ladept\s+conftest\.cpp", text) ||
        push!(iss, "config.log missing the order-broken '-ladept " *
                   "conftest.cpp' link evidence")
    iss
end

fl5_overall(groups) = all(isempty, values(groups)) ?
    "s1_4555_failure_recorded" : "s1_4555_ledger_refused"

# --- fixtures ---------------------------------------------------------------------

function fl5_fixtures()
    t = Dict{String, Bool}()

    mkreceipt(over...) = begin
        e = Dict{String, String}(FL5_EXPECT)
        for (k, v) in over
            e[k] = v
        end
        Vector{UInt8}(codeunits(
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
            "   StdOut=$(e["StdOut"])\n"))
    end
    ri(bytes) = fl5_receipt_issues(fl5_parse_receipt(String(copy(bytes))),
                                   FL5_EXPECT)
    t["receipt_good_binds"] = isempty(ri(mkreceipt()))
    t["receipt_wrong_state_refuses"] =
        !isempty(ri(mkreceipt("JobState" => "COMPLETED")))
    t["receipt_wrong_exit_refuses"] =
        !isempty(ri(mkreceipt("ExitCode" => "0:0")))
    t["receipt_wrong_runtime_refuses"] =
        !isempty(ri(mkreceipt("RunTime" => "00:37:54")))

    goodlog = join(["=== S1-lw stage $s: x ===" for s in
                    ("0a", "0b", "0c", "0d", "1", "2", "3")],
                   "\nok\n") * "\n" * FL5_ERROR_LINE * "\n"
    t["log_good_accepted"] = isempty(fl5_log_issues(goodlog))
    t["log_missing_error_refuses"] = !isempty(fl5_log_issues(
        replace(goodlog, FL5_ERROR_LINE * "\n" => "")))
    t["log_duplicate_error_refuses"] = !isempty(fl5_log_issues(
        goodlog * FL5_ERROR_LINE * "\n"))
    t["log_reaches_arm_refuses"] = !isempty(fl5_log_issues(
        goodlog * "=== S1-lw stage 7-a0a: x ===\n"))
    t["log_missing_stage_refuses"] = !isempty(fl5_log_issues(
        replace(goodlog, "=== S1-lw stage 2: x ===" => "")))

    goodcl = FL5_CHECK_21 * "\ng++ -o conftest -g -O2 -I/x -L/x " *
        "-Wl,-rpath,/x -ladept  conftest.cpp  >&5\n" *
        FL5_UNDEF_LINE * "\n" * FL5_ERROR_LINE * "\n"
    t["configlog_good_accepted"] = isempty(fl5_configlog_issues(goodcl))
    t["configlog_missing_undef_refuses"] = !isempty(fl5_configlog_issues(
        replace(goodcl, FL5_UNDEF_LINE * "\n" => "")))
    t["configlog_missing_order_evidence_refuses"] =
        !isempty(fl5_configlog_issues(
            replace(goodcl, "-ladept  conftest.cpp" => "conftest.cpp -ladept")))

    t["overall_all_green"] =
        fl5_overall(Dict("a" => String[])) == "s1_4555_failure_recorded"
    t["overall_any_issue_refuses"] =
        fl5_overall(Dict("a" => ["x"])) == "s1_4555_ledger_refused"
    t
end

# --- main -------------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()

    tests = fl5_fixtures()
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    groups = Dict{String, Vector{String}}()

    # dual receipts: coupled reads, byte-identity, full field binding
    rc_iss = String[]
    r40_iss, r40 = fl5_read_pinned(FL5_RECEIPT_S40, FL5_RECEIPT_SHA;
                                   label = "session40 receipt")
    r42_iss, r42 = fl5_read_pinned(FL5_RECEIPT_A42, FL5_RECEIPT_SHA;
                                   label = "agent42 receipt")
    append!(rc_iss, r40_iss); append!(rc_iss, r42_iss)
    if r40 !== nothing && r42 !== nothing
        r40 == r42 || push!(rc_iss, "receipts not byte-identical")
        for (label, bytes) in (("session40", r40), ("agent42", r42))
            for i in fl5_receipt_issues(
                    fl5_parse_receipt(String(copy(bytes))), FL5_EXPECT)
                push!(rc_iss, "$label receipt: $i")
            end
        end
    end
    groups["dual_receipts"] = rc_iss

    l_iss, l_bytes = fl5_read_pinned(FL5_LOG, FL5_LOG_SHA; label = "job log")
    l_bytes === nothing ||
        append!(l_iss, fl5_log_issues(String(copy(l_bytes))))
    groups["job_log"] = l_iss

    c_iss, c_bytes = fl5_read_pinned(FL5_CONFIG_LOG, FL5_CONFIG_LOG_SHA;
                                     label = "failed config.log")
    c_bytes === nothing ||
        append!(c_iss, fl5_configlog_issues(String(copy(c_bytes))))
    groups["failed_config_log"] = c_iss

    pv = String[]
    fc_iss, _ = fl5_read_pinned(FL5_FRESH_CONFIGURE,
                                FL5_FRESH_CONFIGURE_SHA;
                                label = "fresh generated configure")
    append!(pv, fc_iss)
    hc_iss, hc = fl5_read_pinned(FL5_HIST_CONFIGURE,
                                 FL5_HIST_CONFIGURE_SHA;
                                 label = "historical generated configure")
    append!(pv, hc_iss)
    hc === nothing || (occursin(FL5_CHECK_11, String(copy(hc))) ||
        push!(pv, "historical configure lacks the >= 1.1 check " *
                  "(stale-vintage evidence)"))
    m4a_iss, m4a = fl5_read_pinned(FL5_M4_ARTIFACT, FL5_M4_SHA;
                                   label = "artifact m4/adept.m4")
    append!(pv, m4a_iss)
    m4h_iss, m4h = fl5_read_pinned(FL5_M4_HIST, FL5_M4_SHA;
                                   label = "historical m4/adept.m4")
    append!(pv, m4h_iss)
    (m4a !== nothing && m4h !== nothing && m4a == m4h) ||
        push!(pv, "m4/adept.m4 not byte-identical across trees")
    groups["configure_vintage_evidence"] = pv

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end
    status = gates["fixtures"] == "passed" ? fl5_overall(groups) :
        "s1_4555_ledger_refused"

    result = Dict(
        "case" => "gate4_s1_failure_ledger_4555",
        "data_mode" => "evidence_ledger_no_campaign_writes",
        "status" => status,
        "timestamp_utc" => FL5_EVIDENCE_TIME,
        "evidence_timestamp_utc" => FL5_EVIDENCE_TIME,
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "job" => Dict(
            "job_id" => 4555,
            "job_state" => "FAILED",
            "exit_code_raw" => "1:0",
            "derived_exit_code_raw" => "0:0",
            "run_time" => "00:00:22",
            "receipt_paths" => [FL5_RECEIPT_S40, FL5_RECEIPT_A42],
            "receipt_sha256" => FL5_RECEIPT_SHA,
            "log_path" => FL5_LOG,
            "log_sha256" => FL5_LOG_SHA,
            "runroot_preserved" => FL5_RUNROOT),
        "gates_passed_in_4555" => "ONLY the two pre-patch tree-identity " *
            "gates (stage-0c ARTTREE artifact manifest, stage-2 " *
            "COPYTREE copied-tree manifest), the exec-bit census and " *
            "zero-symlink checks, the frozen test-template " *
            "snapshot+pins, and the fail-closed toolchain fingerprints " *
            "passed; the job died in stage 3 BEFORE the patch, so the " *
            "post-patch POSTPATCHTREE gate was NOT reached and no " *
            "patch/rebuild/arm executed",
        # DURABLE evidence: content-pinned artifacts that prove the 4555
        # root cause and the stale-configure finding
        "durable_evidence" => Dict(
            "scope" => "content-pinned campaign evidence: these pins " *
                "prove the 4555 root cause and the stale-configure " *
                "finding",
            "failed_config_log_sha256" => FL5_CONFIG_LOG_SHA,
            "fresh_generated_configure_sha256" => FL5_FRESH_CONFIGURE_SHA,
            "historical_generated_configure_sha256" => FL5_HIST_CONFIGURE_SHA,
            "m4_adept_m4_sha256_both_trees" => FL5_M4_SHA),
        "root_cause" => "ARGUMENT-POSITION link defect in the fresh " *
            "(9a2a6908) configure's Adept >= 2.1 test: the m4 macro " *
            "embeds its own -ladept AHEAD of conftest.cpp, so " *
            "left-to-right linker scanning drops the library before " *
            "the object that needs adept::compiler_version() " *
            "(out-of-line, [abi:cxx11]) -> undefined reference -> " *
            "'Unable to find Adept library version >= 2.1'. Paths were " *
            "present (-L + rpath in the failing command); no runtime " *
            "environment involved.",
        "stale_configure_finding" => "generated configure vintage " *
            "differs despite identical current m4 source: the extant " *
            "built tree's configure (9ed1baac) checks Adept >= 1.1 " *
            "while m4/adept.m4 is byte-identical (79d60785) between " *
            "that tree and the artifact; the extant generated configure " *
            "is stale generated state, so config.status --config (user " *
            "options only) was insufficient build-equivalence evidence.",
        # EPHEMERAL design evidence: monitor-session diagnostics in /tmp,
        # deliberately NOT content-pinned; authoritative execution proof
        # is attempt 2's fail-closed configure + config.status assert
        "preflight_design_evidence" => Dict(
            "scope" => "monitor-observed diagnostics in EPHEMERAL /tmp " *
                "copies; NOT content-pinned campaign evidence; the " *
                "corrected recipe is preflight design evidence only, " *
                "and the authoritative execution proof is attempt 2's " *
                "fail-closed configure + byte-exact config.status " *
                "assertion in the amended checkpoint",
            "corrected_recipe" => Dict(
            "configure_argv" => "./configure " *
                "--with-adept=/shared/home/greg/local/adept-2-install " *
                "--with-netcdf=/shared/home/greg/local/ckdmip-stack " *
                "'LDFLAGS=-L/shared/home/greg/local/adept-2-install/lib " *
                "-Wl,-rpath,/shared/home/greg/local/adept-2-install/lib' " *
                "'LIBS=-ladept'",
            "ldflags_semantics" => "path + rpath ONLY, never -ladept " *
                "(the m4 adds its own early -ladept; user LIBS supplies " *
                "the resolving late -ladept because autoconf places " *
                "LIBS after conftest.cpp)",
            "libs_only_counterexample" => "LIBS=-ladept alone fails at " *
                "rc=77 'C++ compiler cannot create executables' (the " *
                "nonstandard Adept lib path is unknown before the m4 " *
                "check)",
            "diagnostic_result" => "monitor-tested in fresh isolated " *
                "artifact copies after autoreconf: Adept >= 2.1 yes, " *
                "nc_create -lnetcdf, final LIBS = -lnetcdf -ladept",
            "classification" => "build-enablement correction, not a " *
                "scientific change and not historical build " *
                "equivalence; the same corrected build is common to " *
                "A0/S1, preserving the internal one-factor triple-arm " *
                "test; historical 4515 remains an output bridge only " *
                "if the A0 raw2 matches")),
        "evidence_scope_note" => "the corrected-recipe diagnostics were " *
            "monitor-observed in EPHEMERAL /tmp copies and are NOT " *
            "content-pinned campaign evidence. Durable pins in this " *
            "ledger prove the 4555 root cause and the stale-configure " *
            "finding (receipts/log/config.log/configure/m4 hashes); the " *
            "corrected recipe is PREFLIGHT DESIGN EVIDENCE only, and " *
            "the authoritative execution proof is attempt 2's " *
            "fail-closed configure + byte-exact config.status " *
            "assertion in the amended checkpoint.",
        "non_authorizing_note" => "this ledger records and classifies " *
            "evidence; the amended attempt-2 checkpoint must pin this " *
            "ledger and monitor GO is required before any commit or " *
            "resubmission",
        "disclaimer" => "evidence ledger; writes nothing except its own " *
            "JSON/MD results plus transient private temp fixtures " *
            "(mktempdir); zero campaign/canonical writes.")

    mkpath(dirname(FL5_RESULTS_JSON))
    open(FL5_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(FL5_RESULTS_MD, "w") do io
        println(io, "# Gate-4 S1 failure ledger: job 4555\n")
        println(io, "Status: **$status**\n")
        println(io, result["root_cause"], "\n")
        println(io, result["stale_configure_finding"], "\n")
        println(io, "Corrected recipe: `" *
                    result["preflight_design_evidence"]["corrected_recipe"]["configure_argv"] *
                    "` (preflight design evidence; ephemeral diagnostics " *
                    "NOT content-pinned; attempt-2 fail-closed " *
                    "configure/config.status is the execution proof)\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_s1_failure_ledger_4555: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "s1_4555_failure_recorded" ? 0 : 1
end

exit(main())
