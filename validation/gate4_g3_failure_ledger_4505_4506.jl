# Gate-4 G3 FAILURE LEDGER for optimizer attempts 4505 (LW) / 4506 (SW)
# (read-only evidence unit; writes NOTHING except its own JSON/MD).
# Records the semantic failure of the first G3 recovery attempts and the
# monitor's bounded diagnostics, fail-closed:
#   g3_attempts_4505_4506_failed_semantic_diagnosed -- every evidence
#     group verified (exit 0: the LEDGER succeeded at recording; the
#     recorded content is the failure)
#   g3_failure_ledger_refused -- ANY discrepancy (exit 1)
#
# WHAT HAPPENED (all digest-bound below): both jobs, submitted by the
# Codex monitor under g3_recovery_go at reviewed commit 4a3667bd, passed
# every gate (GATEPINS, quota, runtime preflight, input pins, staging,
# config asserts) and died identically 13-14 s in: optimize_lut was
# killed at the FIRST LAPACK call of the run -- inv(background) at
# ckd_model.cpp:681, the 318x318 a-priori covariance inverse -- while
# stdout ended silently at "Creating 318x318 error covariance matrix
# for COMPOSITE". The upstream pipeline `$OPTIMIZE_LUT ... |& tee $LOG`
# + `test "${PIPESTATUS[0]}" -eq 0` flattened the child's signal status
# to shell rc 1 (Slurm ExitCode=1:0, Reason=NonZeroExitCode).
#
# DIAGNOSIS (monitor's bounded read-only diagnostics, recorded here as
# attributed observations): gdb showed SIGFPE in ATLAS
# ATL_dcopy_xp1yp1aXbX -> dlasyf_ -> dsytrf_ -> adept::inv
# (ckd_model.cpp:681, nx=318, corr=0.8, prior_error=8|2), under the
# unconditional feenableexcept(FE_INVALID|FE_DIVBYZERO|FE_OVERFLOW)
# (optimize_lut.cpp:51 -> src/include/floating_point_exceptions.h:20).
# A dcopy_-only interposer merely moved the SIGFPE to ATLAS
# ATL_diamax_xp1yp0aXbX. Netlib positive evidence, two bounded probes:
# (i) Netlib BLAS preload + Netlib LAPACK via LD_LIBRARY_PATH completed
# all four LW covariance matrices and reached optimizer iteration 8;
# (ii) the FINAL exact-version preload-only order (BLAS:LAPACK:H5-shim,
# NO LD_LIBRARY_PATH) completed all four inversions with identical
# inverse fractions, loaded all scenes, and reached iteration 3 (rc124
# from the deliberate 60 s timeout only; no SIGFPE), with the loader
# binding dcopy_ -> /usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0.
# REMEDY DECISION (for the separate executor-amendment commit): exact-
# version preload-only -- LD_PRELOAD=<netlib blas>:<netlib lapack>:
# <h5open shim>, NO LD_LIBRARY_PATH (both libraries carry SONAMEs
# libblas.so.3/liblapack.so.3 and satisfy Adept directly).
#
# The H5open-preinit shim WORKED (all HDF5 reads succeeded); this was
# not an input, staging, or HDF5 failure. Canonical finals were never
# published (13 s crash); both RUNROOTs are preserved forensics.
# REPRODUCIBILITY: every recorded fact is a FIXED evidence-time
# constant or an immutable git-blob/digest pin -- no live canonical or
# system-library reads, no wall-clock timestamps -- so this historical
# ledger stays byte-identical and green regardless of later remediated
# publications or system updates.

include(joinpath(@__DIR__, "validation_results.jl"))

import JSON
import SHA

# fixed evidence timestamp (max job EndTime): this HISTORICAL ledger
# carries no wall-clock generation time, so double runs are
# byte-identical by construction
const FLX_EVIDENCE_TIME = "2026-08-13T16:24:52Z"

const FLX_PROJECT_ROOT = dirname(@__DIR__)
const FLX_G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const FLX_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"
const FLX_REVIEWED_COMMIT = "4a3667bd1b15b58ff340e62ab00c28ae78916736"

# the EXECUTED script bytes, verified from the IMMUTABLE git blobs at
# the reviewed commit (never from mutable working-tree paths: a later
# executor amendment must not fail this historical ledger)
const FLX_SCRIPTS = Dict(
    "lw" => Dict("repo_path" => "validation/results/gate4_g3_lw_optimizer.sbatch",
                 "bytes" => 24009,
                 "sha256" => "a225d75728c245b9bdf1e508cc82f34464120baeb926b2bb4526940282773bdc"),
    "sw" => Dict("repo_path" => "validation/results/gate4_g3_sw_optimizer.sbatch",
                 "bytes" => 21980,
                 "sha256" => "024e2d3c91709ecc7fb4458cb9aa6344ace2393177e1ce3f4218fbd9a3df5d1e"))

# immutable-blob pin: hash the bytes of <commit>:<path> from git object
# storage, never the working tree
function flx_blob_pin_issues(commit, relpath, sha, bytes)
    iss = String[]
    blob = try
        read(`git -C $FLX_PROJECT_ROOT cat-file blob $commit:$relpath`)
    catch
        push!(iss, "git blob unreadable: $commit:$relpath")
        return iss
    end
    bytes2hex(SHA.sha256(blob)) == sha ||
        push!(iss, "blob sha drift: $commit:$relpath")
    length(blob) == bytes || push!(iss, "blob size drift: $commit:$relpath")
    iss
end

# attempt registry: receipts/logs custody-hashed by Agent 42 within 15 s
# of termination and live-verified before embedding here
const FLX_ATTEMPTS = Dict(
    "lw" => Dict(
        "job_id" => 4505,
        "job_name" => "g4-g3-lw-optimizer",
        "submitted_by" => "Codex monitor mechanical submit under " *
            "g3_recovery_go at reviewed commit 4a3667bd",
        "expected_submit_line" => "sbatch --parsable " *
            "validation/results/gate4_g3_lw_optimizer.sbatch",
        "receipt" => "$FLX_LOG_DIR/g4-g3-lw-4505-scontrol-final-agent42.txt",
        "receipt_sha256" => "3881ce1a286ee3825febfee0aa1ffe91fd6fc9cedbe24c5b3a1b627c4ad529eb",
        "joblog" => "$FLX_LOG_DIR/g4-g3-lw-4505.log",
        "joblog_sha256" => "10e7e6b511d202f1b70701200cf737c762fb8681472cf22a7f9622f12e4c5d3a",
        "childlog" => "$FLX_G4WORK/g3-runs/4505/lw/work/lw_raw-ckd-definition/" *
            "ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.log",
        "childlog_sha256" => "725fae078febe65334a50767d84eecbdb4ba8f6f85435710bad6e72736f7c631",
        "runroot" => "$FLX_G4WORK/g3-runs/4505/lw",
        "expected_fields" => Dict(
            "JobId" => "4505", "JobName" => "g4-g3-lw-optimizer",
            "JobState" => "FAILED", "Reason" => "NonZeroExitCode",
            "ExitCode" => "1:0", "DerivedExitCode" => "0:0",
            "Restarts" => "0", "RunTime" => "00:00:13",
            "TimeLimit" => "1-00:00:00",
            "StartTime" => "2026-08-13T16:24:38",
            "EndTime" => "2026-08-13T16:24:51",
            "Command" => "/shared/home/greg/Projects/" *
                "AnalyticBandRadiation-platform/validation/results/" *
                "gate4_g3_lw_optimizer.sbatch",
            "SubmitLine" => "sbatch --parsable " *
                "validation/results/gate4_g3_lw_optimizer.sbatch",
            "StdOut" => "/shared/home/greg/data/ckdmip-logs/g4-g3-lw-4505.log"),
        "covariance_line" => "Creating 318x318 error covariance matrix for COMPOSITE",
        "fixed_error" => "8"),
    "sw" => Dict(
        "job_id" => 4506,
        "job_name" => "g4-g3-sw-optimizer",
        "submitted_by" => "Codex monitor mechanical submit under " *
            "g3_recovery_go at reviewed commit 4a3667bd",
        "expected_submit_line" => "sbatch --parsable " *
            "validation/results/gate4_g3_sw_optimizer.sbatch",
        "receipt" => "$FLX_LOG_DIR/g4-g3-sw-4506-scontrol-final-agent42.txt",
        "receipt_sha256" => "87422acd3eea564122791c6351a8b5cfa62ed8a2e10113fb90c2be25cbe19816",
        "joblog" => "$FLX_LOG_DIR/g4-g3-sw-4506.log",
        "joblog_sha256" => "981a4af093823e28eead7485b1a516fdb5b1964ba1b4bea3332dae1213dbad75",
        "childlog" => "$FLX_G4WORK/g3-runs/4506/sw/work/sw_raw-ckd-definition/" *
            "ecckd-1.4_sw_raw2-ckd-definition_climate_rgb-tol0.047.log",
        "childlog_sha256" => "219b2388a200ae717f4ac06d7a955a630a0e4e116e49a317944e21cb563a12e4",
        "runroot" => "$FLX_G4WORK/g3-runs/4506/sw",
        "expected_fields" => Dict(
            "JobId" => "4506", "JobName" => "g4-g3-sw-optimizer",
            "JobState" => "FAILED", "Reason" => "NonZeroExitCode",
            "ExitCode" => "1:0", "DerivedExitCode" => "0:0",
            "Restarts" => "0", "RunTime" => "00:00:14",
            "TimeLimit" => "1-00:00:00",
            "StartTime" => "2026-08-13T16:24:38",
            "EndTime" => "2026-08-13T16:24:52",
            "Command" => "/shared/home/greg/Projects/" *
                "AnalyticBandRadiation-platform/validation/results/" *
                "gate4_g3_sw_optimizer.sbatch",
            "SubmitLine" => "sbatch --parsable " *
                "validation/results/gate4_g3_sw_optimizer.sbatch",
            "StdOut" => "/shared/home/greg/data/ckdmip-logs/g4-g3-sw-4506.log"),
        "covariance_line" => "Creating 318x318 error covariance matrix for COMPOSITE",
        "fixed_error" => "2"))

# canonical finals that must NOT have been published by these attempts
const FLX_CANON = Dict(
    "lw" => "$FLX_G4WORK/work/lw_ckd-definition/ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc",
    "sw" => "$FLX_G4WORK/work-v14/sw_ckd-definition/ecckd-1.4_sw_ckd-definition_climate_rgb-tol0.047.nc")

# validated remedy pins (exact-version Netlib, monitor-proven; consumed
# by the SEPARATE executor-amendment commit)
const FLX_NETLIB_BLAS = "/usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0"
const FLX_NETLIB_BLAS_SHA = "e748efcae5753fe4a652877fccdb5895ac6f7605668a2db878b19c914e78e3a8"
const FLX_NETLIB_BLAS_BYTES = 677880
const FLX_NETLIB_LAPACK = "/usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0"
const FLX_NETLIB_LAPACK_SHA = "851bb1fc5833ede9ed704b4417a251a899976d5e0915de40452615187a65278f"
const FLX_NETLIB_LAPACK_BYTES = 7268368
const FLX_SHIM_SO = "$FLX_G4WORK/tools/h5open_before_traps.so"
const FLX_SHIM_SO_SHA = "28003281a7f1c8470c1bfd94a654999a210581261a5c3e9cd662af2a13dd492f"

const FLX_STAGE_MARKS = ["stage 0a: gate-code identity",
                         "stage 0b: quota health",
                         "stage 0c: fresh scoped preflight",
                         "stage 0d: band lock",
                         "stage 0e: exact size+sha pin",
                         "stage 1: job-private RUNROOT",
                         "stage 2: optimizer wrapper inside RUNROOT",
                         "stage 3: isolated testcopy inside RUNROOT",
                         "stage 4: staged optimizer"]
const FLX_ABSENT_MARKS = ["stage 5: staged outputs",
                          "stage 6: FINAL-ONLY atomic publish",
                          "=== G3-lw done", "=== G3-sw done"]
const FLX_READY_LINE = "gate4_g3_scoped_input_preflight: g3_scoped_preflight_ready"

const FLX_RESULTS_JSON = validation_results_path("gate4_g3_failure_ledger_4505_4506.json")
const FLX_RESULTS_MD = validation_results_path("gate4_g3_failure_ledger_4505_4506.md")

# --- primitives ---------------------------------------------------------------

flx_try_sha(path) = try
    isfile(path) || return nothing
    open(io -> bytes2hex(SHA.sha256(io)), path)
catch
    nothing
end

const FLX_TOKEN_KEYS = ("JobId", "JobName", "JobState", "Reason",
    "ExitCode", "DerivedExitCode", "Restarts", "RunTime", "TimeLimit",
    "StartTime", "EndTime")

function flx_parse_receipt(text)
    f = Dict{String, String}()
    for k in FLX_TOKEN_KEYS
        m = match(Regex("\\b" * k * "=(\\S+)"), text)
        m === nothing || (f[k] = String(m.captures[1]))
    end
    for k in ("Command", "SubmitLine", "StdOut")
        m = match(Regex("^\\s*" * k * "=(.*)\$", "m"), text)
        m === nothing || (f[k] = String(strip(m.captures[1])))
    end
    f
end

# exact-equality binding of every expected field
function flx_field_issues(f, expect)
    iss = String[]
    for (k, v) in expect
        get(f, k, "") == v ||
            push!(iss, "$k mismatch (got $(repr(get(f, k, ""))))")
    end
    sort(iss)
end

# digest-then-parse evidence group for one custody file
function flx_receipt_group(path, pinned, expect)
    iss = String[]
    sha = flx_try_sha(path)
    sha === nothing &&
        (push!(iss, "receipt missing/unreadable: $path"); return iss)
    sha == pinned ||
        (push!(iss, "receipt sha $sha != pinned"); return iss)
    append!(iss, flx_field_issues(flx_parse_receipt(read(path, String)),
                                  expect))
    iss
end

# failure-shape log verification: the recorded stages present, the
# post-failure stages ABSENT, the final line the covariance line, the
# preflight ready line present, and NO refusal markers (the silent-
# masking evidence)
function flx_log_issues(text; stages = FLX_STAGE_MARKS,
                        absent = FLX_ABSENT_MARKS,
                        ready = FLX_READY_LINE,
                        lastline = "")
    iss = String[]
    for s in stages
        occursin(s, text) || push!(iss, "missing stage marker: $s")
    end
    for a in absent
        occursin(a, text) &&
            push!(iss, "post-failure marker unexpectedly present: $a")
    end
    # EXACTLY one exact ready line (never mere presence)
    n_ready = length(collect(eachmatch(Regex("^\\Q" * ready * "\\E\$", "m"),
                                       text)))
    n_ready == 1 ||
        push!(iss, "runtime preflight ready line count $n_ready != 1")
    occursin("REFUSED", text) &&
        push!(iss, "REFUSED marker present (contradicts silent-kill evidence)")
    # EXACT final line (whitespace-stripped equality, never substring)
    lines = [l for l in split(text, '\n') if !isempty(strip(l))]
    (isempty(lines) || strip(lines[end]) != lastline) &&
        push!(iss, "final log line != exact covariance line")
    sort(iss)
end

# pinned-file expectation
function flx_pin_issues(path, sha; bytes = nothing)
    iss = String[]
    got = flx_try_sha(path)
    got === nothing && (push!(iss, "missing/unreadable: $path"); return iss)
    got == sha || push!(iss, "sha drift: $path")
    bytes === nothing || filesize(path) == bytes ||
        push!(iss, "size drift: $path")
    iss
end

flx_overall(groups) = all(isempty, values(groups)) ?
    "g3_attempts_4505_4506_failed_semantic_diagnosed" :
    "g3_failure_ledger_refused"

function flx_close_failed_gates!(fails, gates)
    bad = sort([k for (k, v) in gates if v != "passed"])
    isempty(bad) ||
        push!(fails, "failed gates (fail-closed census): " * join(bad, ", "))
end

# --- fixtures ------------------------------------------------------------------

function flx_fixtures()
    t = Dict{String, Bool}()
    fx = mktempdir()
    shaof(p) = bytes2hex(SHA.sha256(read(p)))
    ex = FLX_ATTEMPTS["lw"]["expected_fields"]
    mkreceipt(over...) = begin
        e = Dict{String, String}(ex)
        for (k, v) in over
            e[k] = v
        end
        "JobId=$(e["JobId"]) JobName=$(e["JobName"])\n" *
        "   JobState=$(e["JobState"]) Reason=$(e["Reason"]) Dependency=(null)\n" *
        "   Requeue=1 Restarts=$(e["Restarts"]) ExitCode=$(e["ExitCode"])\n" *
        "   DerivedExitCode=$(e["DerivedExitCode"])\n" *
        "   RunTime=$(e["RunTime"]) TimeLimit=$(e["TimeLimit"])\n" *
        "   StartTime=$(e["StartTime"]) EndTime=$(e["EndTime"])\n" *
        "   Command=$(e["Command"])\n" *
        "   SubmitLine=$(e["SubmitLine"])\n" *
        "   StdOut=$(e["StdOut"])\n"
    end
    fi(txt) = flx_field_issues(flx_parse_receipt(txt), ex)
    t["receipt_good_binds"] = isempty(fi(mkreceipt()))
    t["receipt_state_drift_refuses"] =
        !isempty(fi(mkreceipt("JobState" => "COMPLETED")))
    t["receipt_exit_drift_refuses"] =
        !isempty(fi(mkreceipt("ExitCode" => "0:0")))
    t["receipt_runtime_drift_refuses"] =
        !isempty(fi(mkreceipt("RunTime" => "01:00:00")))
    t["receipt_jobid_drift_refuses"] =
        !isempty(fi(mkreceipt("JobId" => "9999")))
    t["receipt_submitline_drift_refuses"] =
        !isempty(fi(mkreceipt("SubmitLine" => "sbatch --parsable " *
            "--export=X=1 validation/results/gate4_g3_lw_optimizer.sbatch")))
    t["receipt_command_drift_refuses"] =
        !isempty(fi(mkreceipt("Command" => "/tmp/other.sbatch")))
    t["receipt_stdout_drift_refuses"] =
        !isempty(fi(mkreceipt("StdOut" => "/tmp/other.log")))
    # receipt group: missing / digest drift / good
    rp = joinpath(fx, "r.txt"); write(rp, mkreceipt())
    t["receipt_group_good"] = isempty(flx_receipt_group(rp, shaof(rp), ex))
    t["receipt_group_missing_refuses"] =
        !isempty(flx_receipt_group(joinpath(fx, "no.txt"), "0" ^ 64, ex))
    t["receipt_group_digest_drift_refuses"] =
        !isempty(flx_receipt_group(rp, "0" ^ 64, ex))
    # failure-shape log
    cov = "Creating 318x318 error covariance matrix for COMPOSITE"
    goodlog = join(FLX_STAGE_MARKS, "\n...\n") * "\n" * FLX_READY_LINE *
              "\nwork...\n  " * cov * "\n"
    li(txt) = flx_log_issues(txt; lastline = cov)
    t["log_failure_shape_accepted"] = isempty(li(goodlog))
    t["log_missing_stage_refuses"] =
        !isempty(li(replace(goodlog, FLX_STAGE_MARKS[5] => "")))
    t["log_done_marker_present_refuses"] =
        !isempty(li(goodlog * "=== G3-lw done 2026-08-13T17:00:00Z ===\n"))
    t["log_publish_stage_present_refuses"] =
        !isempty(li(replace(goodlog, "work..." =>
            "stage 6: FINAL-ONLY atomic publish")))
    t["log_refused_marker_refuses"] =
        !isempty(li(replace(goodlog, "work..." => "REFUSED: x")))
    t["log_wrong_last_line_refuses"] =
        !isempty(li(goodlog * "some trailing line\n"))
    t["log_missing_ready_line_refuses"] =
        !isempty(li(replace(goodlog, FLX_READY_LINE => "")))
    t["log_duplicated_ready_line_refuses"] =
        !isempty(li(FLX_READY_LINE * "\n" * goodlog))
    t["log_final_line_suffix_refuses"] =
        !isempty(li(replace(goodlog, cov => cov * " extra")))
    # pin expectations
    p = joinpath(fx, "f.bin"); write(p, "DATA")
    t["pin_good"] = isempty(flx_pin_issues(p, shaof(p); bytes = 4))
    t["pin_sha_drift_refuses"] = !isempty(flx_pin_issues(p, "0" ^ 64))
    t["pin_size_drift_refuses"] =
        !isempty(flx_pin_issues(p, shaof(p); bytes = 5))
    t["pin_missing_refuses"] =
        !isempty(flx_pin_issues(joinpath(fx, "no.bin"), "0" ^ 64))
    # overall composition
    t["overall_all_green"] =
        flx_overall(Dict("a" => String[])) ==
        "g3_attempts_4505_4506_failed_semantic_diagnosed"
    t["overall_any_issue_refuses"] =
        flx_overall(Dict("a" => ["x"])) == "g3_failure_ledger_refused"
    t
end

# --- main -----------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()

    tests = flx_fixtures()
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    groups = Dict{String, Vector{String}}()
    anc = try
        success(`git -C $FLX_PROJECT_ROOT merge-base --is-ancestor $FLX_REVIEWED_COMMIT HEAD`)
    catch; false end
    groups["commit_ancestry"] = anc ? String[] :
        ["reviewed commit not an ancestor of HEAD"]

    for (band, s) in FLX_SCRIPTS
        groups["script_blob_pin_$band"] = flx_blob_pin_issues(
            FLX_REVIEWED_COMMIT, s["repo_path"], s["sha256"], s["bytes"])
    end

    for (band, a) in FLX_ATTEMPTS
        groups["receipt_$band"] = flx_receipt_group(a["receipt"],
            a["receipt_sha256"], a["expected_fields"])
        # job stdout log: digest then failure-shape verification
        jl_iss = String[]
        jsha = flx_try_sha(a["joblog"])
        if jsha != a["joblog_sha256"]
            push!(jl_iss, "joblog sha $(something(jsha, "unreadable")) != pinned")
        else
            append!(jl_iss, flx_log_issues(read(a["joblog"], String);
                                           lastline = a["covariance_line"]))
        end
        groups["joblog_$band"] = jl_iss
        # child per-pass log: digest + last-line covariance
        cl_iss = String[]
        csha = flx_try_sha(a["childlog"])
        if csha != a["childlog_sha256"]
            push!(cl_iss, "childlog sha $(something(csha, "unreadable")) != pinned")
        else
            ctext = read(a["childlog"], String)
            clines = [l for l in split(ctext, '\n') if !isempty(strip(l))]
            (isempty(clines) || strip(clines[end]) != a["covariance_line"]) &&
                push!(cl_iss, "childlog final line != exact covariance line")
            occursin("fixed error of $(a["fixed_error"])", ctext) ||
                push!(cl_iss, "childlog fixed-error line missing")
        end
        groups["childlog_$band"] = cl_iss
        # RUNROOT forensics preserved
        rr = a["runroot"]
        groups["runroot_preserved_$band"] =
            all(isdir(joinpath(rr, d))
                for d in ("data", "testcopy", "tools", "work")) ?
            String[] : ["RUNROOT tree incomplete/missing: $rr"]
    end

    # NOTE deliberately NO live netlib/shim gate here: this historical
    # ledger records the remedy pins as FIXED evidence-time facts in
    # remedy_decision; LIVE gating of those libraries belongs to the
    # executor amendment (Commit 2), so system-library updates can
    # never perturb this record.

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end

    status = gates["fixtures"] == "passed" ? flx_overall(groups) :
             "g3_failure_ledger_refused"
    flx_close_failed_gates!(fails, gates)

    # NON-GATING observation: canonical-final absence at authoring.
    # Non-publication is PROVEN by the gated evidence (FAILED receipts +
    # digest-bound logs with stage 5/6 and done markers absent); this
    # observation is expected to flip after a successful remediated
    # publication WITHOUT affecting this historical ledger's verdict.
    # FIXED recorded facts at evidence time (NO live reads: a later
    # successful publication or system-library update must not rewrite
    # this historical record or perturb byte stability). Non-publication
    # is PROVEN by the gated evidence (FAILED receipts + digest-bound
    # logs with stage 5/6 and done markers absent). The executor
    # amendment owns all LIVE remedy gating.
    canonical_obs = Dict(band => Dict("path" => FLX_CANON[band],
        "absent_at_evidence_time" => true) for band in keys(FLX_CANON))
    atlas_obs = Dict(
        "f77blas" => Dict(
            "symlink" => "/lib/x86_64-linux-gnu/libf77blas.so.3",
            "resolved_at_evidence_time" =>
                "/usr/lib/x86_64-linux-gnu/libf77blas.so.3.10.3",
            "sha256" => "0962621e102076187bc6f01890eb6f8482b15dd1a994aaab24b2250eab74cbfb"),
        "lapack" => Dict(
            "symlink" => "/lib/x86_64-linux-gnu/liblapack.so.3",
            "resolved_at_evidence_time" =>
                "/usr/lib/x86_64-linux-gnu/atlas/liblapack.so.3.10.3",
            "sha256" => "f541fba68cbebded2fca2621dc3317df5b6a7363eaaf060dc653cea5027806ad"))

    result = Dict(
        "case" => "gate4_g3_failure_ledger_4505_4506",
        "data_mode" => "read_only_evidence_ledger",
        "status" => status,
        "evidence_time_utc" => FLX_EVIDENCE_TIME,
        "timestamp_semantics" => "fixed evidence timestamp (max job " *
            "EndTime); no wall-clock generation time -- double runs " *
            "are byte-identical",
        "gates" => gates, "failures" => fails,
        "fixture_verdicts" => tests,
        "reviewed_commit" => FLX_REVIEWED_COMMIT,
        "scripts" => FLX_SCRIPTS,
        "attempts" => FLX_ATTEMPTS,
        "canonical_finals" => Dict(
            "observation" => canonical_obs,
            "semantics" => "FIXED recorded fact at evidence time " *
                "(2026-08-13T16:24:52Z), never re-read live: it " *
                "remains absent_at_evidence_time=true permanently, " *
                "regardless of any later remediated publication. " *
                "Non-publication by the failed attempts is PROVEN by " *
                "the gated evidence (FAILED receipts + digest-bound " *
                "logs with stage 5/6 and done markers absent)."),
        "failure_mechanism" => Dict(
            "kill_site" => "adept::inv at ckd_model.cpp:681 " *
                "(inv(background), nx=318 a-priori covariance)",
            "signal_path" => "SIGFPE in ATLAS ATL_dcopy_xp1yp1aXbX -> " *
                "dlasyf_ -> dsytrf_ -> adept::inv",
            "trap_source" => "unconditional feenableexcept(FE_INVALID|" *
                "FE_DIVBYZERO|FE_OVERFLOW) at optimize_lut.cpp:51 via " *
                "src/include/floating_point_exceptions.h:20",
            "status_masking" => "upstream `\$OPTIMIZE_LUT ... |& tee " *
                "\$LOG` + `test \"\${PIPESTATUS[0]}\" -eq 0` flattens " *
                "child rc 128+sig to shell rc 1 (Slurm ExitCode=1:0) " *
                "with no printed signal message",
            "h5_shim_verdict" => "WORKED: all HDF5 gas-property reads " *
                "succeeded before the kill; not an HDF5/input failure"),
        "diagnostic_observations" => Dict(
            "attribution" => "Codex monitor bounded read-only " *
                "diagnostics (gdb on retained LW first pass; temp " *
                "diagnostic sources removed; repo clean); recorded " *
                "here as attributed observations with hashes",
            "gdb_backtrace" => "SIGFPE: ATL_dcopy_xp1yp1aXbX -> " *
                "dlasyf_ -> dsytrf_ -> adept::inv (ckd_model.cpp:681); " *
                "nx=318, corr=0.8, prior_error=8",
            "partial_interposer_negative" => "dcopy_-only interposer " *
                "rebound LAPACK dcopy_ but ATLAS then SIGFPEd in " *
                "ATL_diamax_xp1yp0aXbX in the same factorization -- " *
                "partial interposition is insufficient",
            "full_netlib_positive" => "Netlib BLAS preload + Netlib " *
                "LAPACK (that probe supplied LAPACK via " *
                "LD_LIBRARY_PATH) completed ALL four LW covariance " *
                "matrices (318 COMPOSITE, 3816 H2O, 318 O3, 318 CO2), " *
                "loaded all training scenes, and reached optimizer " *
                "iteration 8 in a 60 s bounded /tmp-only run with no " *
                "SIGFPE; loader binding: liblapack dcopy_ -> " *
                FLX_NETLIB_BLAS,
            "preload_only_final_order_positive" => "the FINAL exact-" *
                "version preload-only order (BLAS:LAPACK:H5-shim, NO " *
                "LD_LIBRARY_PATH) has full-path bounded positive " *
                "evidence: the monitor's 60 s /tmp-only probe " *
                "completed ALL FOUR LW covariance inversions with " *
                "identical inverse fractions (0.975159/0.994135/" *
                "0.975159/0.975159), loaded all training scenes, and " *
                "reached optimizer iteration 3; rc124 came only from " *
                "the deliberate timeout, with no output written and no " *
                "SIGFPE",
            "atlas_libraries_observed" => atlas_obs),
        "remedy_decision" => Dict(
            "route" => "exact-version preload-only (monitor-proven): " *
                "LD_PRELOAD=$FLX_NETLIB_BLAS:$FLX_NETLIB_LAPACK:" *
                "$FLX_SHIM_SO (BLAS, LAPACK, H5 shim order); NO " *
                "LD_LIBRARY_PATH -- both libraries carry SONAMEs " *
                "libblas.so.3/liblapack.so.3 and satisfy Adept's " *
                "DT_NEEDED directly, removing symlink ambiguity",
            "netlib_blas" => Dict("path" => FLX_NETLIB_BLAS,
                "sha256" => FLX_NETLIB_BLAS_SHA,
                "bytes" => FLX_NETLIB_BLAS_BYTES),
            "netlib_lapack" => Dict("path" => FLX_NETLIB_LAPACK,
                "sha256" => FLX_NETLIB_LAPACK_SHA,
                "bytes" => FLX_NETLIB_LAPACK_BYTES),
            "fidelity_note" => "FP traps stay ENABLED for the science " *
                "code; only the flag-raising ATLAS implementation is " *
                "displaced by reference Netlib",
            "implemented_by" => "the SEPARATE executor-amendment commit " *
                "(raw child rc/signal surfacing included); this ledger " *
                "records evidence and decides nothing"),
        "non_authorizing_note" => "this ledger records and classifies " *
            "evidence; it does not itself resubmit, edit the executor, " *
            "or authorize anything -- downstream consumers must bind " *
            "this artifact (exact case/status/sha)",
        "disclaimer" => "read-only evidence ledger; writes nothing " *
            "except its own JSON/MD results.",
    )
    mkpath(dirname(FLX_RESULTS_JSON))
    open(FLX_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(FLX_RESULTS_MD, "w") do io
        println(io, "# Gate-4 G3 failure ledger: attempts 4505 (LW) / 4506 (SW)\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nMechanism: SIGFPE in ATLAS at the FIRST LAPACK " *
                    "call (inv(background), ckd_model.cpp:681) under " *
                    "unconditional FP traps; child status flattened to " *
                    "rc 1 by the upstream tee/PIPESTATUS pipeline. The " *
                    "H5open shim worked; inputs/staging were not at fault.")
        println(io, "\nRemedy decision (executor amendment, separate " *
                    "commit): exact-version Netlib preload-only, " *
                    "BLAS:LAPACK:H5-shim order, no LD_LIBRARY_PATH; " *
                    "plus raw child rc/signal surfacing.")
        println(io, "\nForensics: both RUNROOTs preserved; four custody " *
                    "files digest-bound (Agent 42 capture-suffix " *
                    "protocol); canonical finals absent at authoring.")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_g3_failure_ledger_4505_4506: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "g3_attempts_4505_4506_failed_semantic_diagnosed" ? 0 : 1
end

exit(main())
