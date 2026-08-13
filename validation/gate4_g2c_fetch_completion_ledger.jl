# Gate-4 G2c FETCH COMPLETION LEDGER (read-only evidence unit; NO
# submission, NO fetch, NO writes outside its own results artifacts).
# Success-form mirror of gate4_g2c_failure_ledger_4440: verifies the
# G2c eval2 fetch (registered reviewed attempts only) against the
# pinned manifest and the job logs, and classifies fail-closed.
#
# Classifier states (monitor-approved 2026-08-13, revised per review):
#   g2c_fetch_ledger_waiting_for_job    -- a REGISTERED attempt is
#     queued/running (including a newly PENDING retry with no log yet),
#     or the latest registered log is incomplete while its job is live
#   g2c_fetch_ledger_resumable_timeout  -- latest registered attempt
#     hit the wall (TIME LIMIT marker), NO semantic failure markers,
#     scheduler probe OK with nothing queued, and the disk is clean for
#     resume (stable snapshot; existing finals exact-size; at most one
#     .g2c.part.* across BOTH band dirs, manifested and <= its manifest
#     size): eligible for the TIMEOUT-only continuity resubmission of
#     the SAME reviewed sbatch
#   g2c_fetch_ledger_failed             -- semantic failure marker in
#     the latest registered log, or a terminal-complete/timeout log
#     contradicted by a STABLE disk snapshot: NO auto-resubmission
#   g2c_fetch_completed_verified        -- latest registered log is
#     TERMINAL (stage-2 exact-70 header AND done marker, no failure
#     markers), scheduler probe OK with nothing queued, and a STABLE
#     disk snapshot shows 70/70 exact manifest sizes, h5-open success
#     on EVERY final, and zero .g2c.part.* files in either band dir
#   g2c_fetch_ledger_indeterminate_refused -- evidence unclassifiable:
#     scheduler probe failure, unregistered NEWER attempt log,
#     unregistered ACTIVE queue entry, unreadable latest log, unstable
#     disk snapshot under a terminal/timeout claim, or an incomplete
#     log with nothing queued. Fail-closed refusal, never a guess.
#
# FINALIZED log lines are recorded as PROVENANCE ONLY -- never sole
# proof; the terminal log must carry its own exact-70 stage and done
# marker, and a stable disk snapshot must agree.
#
# ATTEMPT REGISTRY: only registered attempts (job ID + reviewed sbatch
# sha + reviewed commit + submission receipt) participate in
# classification. Legacy logs (e.g. job 4440, which ran the PRE-review
# sync-based script) are recorded as unregistered history and are
# never implied to have run the reviewed sbatch. An unregistered log
# NEWER than the newest registered attempt refuses classification.
# Continuity resubmissions append a registry row at resubmission time.
#
# Continuity history lives HERE, not in the runbook (register pin
# stability). This ledger authorizes nothing.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON
using SHA: sha256

const GL_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"
const GL_LOG_RE = r"^g4-g2c-(\d+)\.log$"
const GL_JOB_NAME = "g4-g2c-eval2-fetch"
const GL_DEST = "/shared/home/greg/data/ckdmip/evaluation2"
const GL_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
const GL_MANIFEST = joinpath(GL_PROJECT_ROOT, "validation/gate4_eval2_selected_manifest.tsv")
const GL_SBATCH = validation_results_path("gate4_g2c_eval2_fetch.sbatch")
const GL_REVIEWED_SBATCH_SHA = "b7d7c5a10eee40ab23d78fb116ca0ce8de562adf9b034cf1311649e256c908d7"
const GL_REVIEWED_COMMIT = "9216204c449304a9a73503598400c45bc0a941ae"
const GL_MANIFEST_TOTAL = 329989234896
const GL_MANIFEST_COUNT = 70
const GL_PART_PREFIX = ".g2c.part."

# registered reviewed attempts; continuity resubmissions append here
const GL_ATTEMPT_REGISTRY = [
    Dict("job_id" => 4500,
         "sbatch_sha256" => GL_REVIEWED_SBATCH_SHA,
         "reviewed_commit" => GL_REVIEWED_COMMIT,
         "submitted_utc" => "2026-08-13T09:38:59Z",
         "submitted_by" => "Codex monitor via Codex exec after " *
             "independent preflight recheck (parity, no duplicate, " *
             "sbatch SHA, live quota guard)",
         "termination_record" => "/shared/home/greg/data/ckdmip-logs/" *
             "g4-g2c-4500-scontrol-final.txt",
         "expected_submit_line" => "sbatch --parsable " *
             "validation/results/gate4_g2c_eval2_fetch.sbatch",
         "terminal_log_sha256" => "c9b8564921905137764e127053" *
             "81b6d667072ab3b96c90af68ab865a1929eb7e"),
]
gl_hex64(s) = s isa AbstractString && occursin(r"^[0-9a-f]{64}$", s)

# nonthrowing ID extraction: a malformed appended receipt (missing /
# string / nonconvertible job_id) must NOT crash the ledger at module
# load -- the row is simply excluded here, and attempt_registry_integrity
# fails it, so the run emits the intended refused artifact instead.
function gl_registry_ids(registry)
    ids = Set{Int}()
    for r in registry
        jid = get(r, "job_id", nothing)
        (jid isa Int && jid > 0) && push!(ids, jid)
    end
    ids
end
const GL_REGISTERED_IDS = gl_registry_ids(GL_ATTEMPT_REGISTRY)

# registry receipt binding: every row must carry the reviewed sbatch
# sha + reviewed commit and a nonempty submission receipt; job IDs are
# unique positive ints. An appended row that fails any of these
# invalidates the registry (fail-closed) rather than being trusted.
function gl_registry_issues(registry, reviewed_sha, reviewed_commit)
    issues = String[]
    ids = Int[]
    for (i, r) in enumerate(registry)
        jid = get(r, "job_id", nothing)
        if !(jid isa Int) || jid <= 0
            push!(issues, "row $i: job_id not a positive Int")
        else
            push!(ids, jid)
        end
        get(r, "sbatch_sha256", "") == reviewed_sha ||
            push!(issues, "row $i: sbatch_sha256 != reviewed sha")
        get(r, "reviewed_commit", "") == reviewed_commit ||
            push!(issues, "row $i: reviewed_commit != reviewed commit")
        for k in ("submitted_utc", "submitted_by")
            v = get(r, k, "")
            (v isa AbstractString && !isempty(strip(v))) ||
                push!(issues, "row $i: $k empty/missing")
        end
        # termination_record / expected_submit_line / terminal_log_sha256
        # are optional while an attempt is live, but if present must be
        # well-formed (nonempty; digest exactly 64 lowercase hex)
        for k in ("termination_record", "expected_submit_line")
            if haskey(r, k)
                v = r[k]
                (v isa AbstractString && !isempty(strip(v))) ||
                    push!(issues, "row $i: $k present but empty")
            end
        end
        if haskey(r, "terminal_log_sha256")
            gl_hex64(r["terminal_log_sha256"]) ||
                push!(issues, "row $i: terminal_log_sha256 not 64-hex")
        end
    end
    length(unique(ids)) == length(ids) ||
        push!(issues, "duplicate job_id in registry")
    isempty(registry) && push!(issues, "registry empty")
    issues
end

const GL_RESULTS_JSON = validation_results_path("gate4_g2c_fetch_completion_ledger.json")
const GL_RESULTS_MD = validation_results_path("gate4_g2c_fetch_completion_ledger.md")

# fixed semantic failure markers: the reviewed sbatch's own refusal
# vocabulary PLUS the observed legacy 4440 markers ('download failed',
# 'Disk quota exceeded') and the explicit no-source refusal. None of
# these match generic Slurm timeout text.
const GL_FAILURE_RE = r"REFUSED|FETCH FAILED|H5 SANITY FAILED|SIZE MISMATCH|^MISSING |download failed|Disk quota exceeded|no source available"m
const GL_TIMEOUT_RE = r"DUE TO TIME LIMIT|TIME LIMIT"
const GL_STAGE2_MARK = "=== G2c stage 2: final exact-70 verification"
const GL_DONE_MARK = "=== G2c done"

# --- nonthrowing primitives ------------------------------------------------

gl_try_read(path) = try
    (true, read(path, String))
catch
    (false, "")
end

gl_try_sha(path) = try
    isfile(path) || return nothing
    bytes2hex(sha256(read(path)))
catch
    nothing
end

# nonthrowing size probe: Int bytes, nothing (absent), or :err
gl_default_fsize(p) = try
    isfile(p) ? Int(filesize(p)) : nothing
catch
    :err
end

gl_default_list(d) = try
    isdir(d) ? readdir(d) : String[]
catch
    nothing
end

# --- manifest --------------------------------------------------------------

function gl_manifest_rows(path)
    rows = Tuple{String, Int}[]
    for l in eachline(path)
        (startswith(l, '#') || isempty(strip(l))) && continue
        p = split(l, '\t')
        length(p) >= 2 || continue
        push!(rows, (String(p[1]), parse(Int, p[2])))
    end
    rows
end

gl_band_sub(name) =
    occursin("_lw_spectra_", name) ? "lw_spectra" :
    occursin("_sw_spectra_", name) ? "sw_spectra" : nothing

# --- scontrol termination receipt (pure parse + binding) --------------------

const GL_RECEIPT_TOKEN_KEYS = ("JobId", "JobName", "JobState", "Reason",
    "ExitCode", "DerivedExitCode", "Restarts", "RunTime", "StartTime",
    "EndTime")

# scontrol show job text -> Dict of the fields this ledger binds;
# token keys are single-token KEY=VALUE, path/line keys are line-anchored
function gl_parse_receipt(text)
    f = Dict{String, String}()
    for k in GL_RECEIPT_TOKEN_KEYS
        m = match(Regex("\\b" * k * "=(\\S+)"), text)
        m === nothing || (f[k] = String(m.captures[1]))
    end
    for k in ("Command", "SubmitLine", "StdOut")
        m = match(Regex("^\\s*" * k * "=(.*)\$", "m"), text)
        m === nothing || (f[k] = String(strip(m.captures[1])))
    end
    f
end

# binding: the receipt must identify EXACTLY this attempt running the
# reviewed script -- job id, job name, absolute reviewed Command,
# SubmitLine referencing the reviewed sbatch, the attempt's own StdOut
# log, and Start/End/RunTime present
function gl_receipt_binding_issues(f, jobid;
        sbatch_abs = GL_SBATCH, log_dir = GL_LOG_DIR,
        job_name = GL_JOB_NAME, expected_submit_line = "")
    iss = String[]
    get(f, "JobId", "") == string(jobid) ||
        push!(iss, "JobId != $jobid")
    get(f, "JobName", "") == job_name || push!(iss, "JobName mismatch")
    normpath(get(f, "Command", "?")) == normpath(sbatch_abs) ||
        push!(iss, "Command is not the reviewed absolute sbatch path")
    # EXACT equality against the registered captured invocation: prefix
    # injection or option drift with the same basename must refuse
    if isempty(strip(expected_submit_line))
        push!(iss, "expected_submit_line not registered for this attempt")
    elseif get(f, "SubmitLine", "") != expected_submit_line
        push!(iss, "SubmitLine != registered expected_submit_line")
    end
    get(f, "StdOut", "") == joinpath(log_dir, "g4-g2c-$jobid.log") ||
        push!(iss, "StdOut mismatch")
    for k in ("StartTime", "EndTime", "RunTime")
        isempty(get(f, k, "")) && push!(iss, "$k missing")
    end
    iss
end

# clean-COMPLETED field set required to accept a terminal-complete log
gl_receipt_completed_ok(f) =
    get(f, "JobState", "") == "COMPLETED" &&
    get(f, "Reason", "") == "None" &&
    get(f, "ExitCode", "") == "0:0" &&
    get(f, "DerivedExitCode", "") == "0:0" &&
    get(f, "Restarts", "") == "0"

# receipt summary consumed by the state machine
gl_receipt_summary(present, f, binding_issues) = (
    present = present, binding_issues = binding_issues,
    completed_ok = present && gl_receipt_completed_ok(f),
    state = present ? get(f, "JobState", "") : "")
const GL_NO_RECEIPT = (present = false, binding_issues = String[],
                       completed_ok = false, state = "")

# terminal-log digest binding: the completion/timeout claim must be
# anchored to an IMMUTABLE registered digest of the classified log --
# a log mutated after registration can never re-prove completion
function gl_log_binding(registered, live)
    (registered isa AbstractString && !isempty(strip(registered))) ||
        return (ok = false,
                reason = "terminal_log_sha256 not registered for this attempt")
    gl_hex64(registered) ||
        return (ok = false, reason = "registered terminal_log_sha256 malformed")
    (live isa AbstractString && gl_hex64(live)) ||
        return (ok = false, reason = "live log digest unavailable")
    registered == live ||
        return (ok = false, reason = "log digest mismatch (log content " *
                                     "differs from registered digest)")
    (ok = true, reason = "")
end
const GL_NO_LOGBIND = (ok = false, reason = "no terminal log digest bound")

# --- per-log classification (pure; complete evidence schema always) ---------

gl_evidence(; finalized = 0, skip = 0, fetcher = "unrecorded", note = "",
              marker = "") = Dict{String, Any}(
    "finalized_lines" => finalized, "skip_lines" => skip,
    "fetcher" => fetcher, "first_failure_marker" => marker,
    "note" => note)

# one readable log's text -> (state, evidence); states:
# :semantic_failure, :terminal_complete, :timeout, :incomplete
function gl_classify_log(text)
    lines = split(text, '\n')
    finalized = count(l -> startswith(l, "FINALIZED "), lines)
    skipped = count(l -> startswith(l, "SKIP "), lines)
    fm = match(r"^fetcher: (\S+)"m, text)
    fetcher = fm === nothing ? "unrecorded" : String(fm.captures[1])
    note = "FINALIZED/SKIP counts are provenance only, never sole proof"
    m = match(GL_FAILURE_RE, text)
    m !== nothing && return (:semantic_failure,
        gl_evidence(; finalized, skip = skipped, fetcher, note,
                      marker = String(m.match)))
    occursin(GL_STAGE2_MARK, text) && occursin(GL_DONE_MARK, text) &&
        return (:terminal_complete,
                gl_evidence(; finalized, skip = skipped, fetcher, note))
    occursin(GL_TIMEOUT_RE, text) &&
        return (:timeout,
                gl_evidence(; finalized, skip = skipped, fetcher, note))
    (:incomplete, gl_evidence(; finalized, skip = skipped, fetcher, note))
end

# readable-or-not -> (state, complete-schema evidence)
gl_attempt_state(ok, text) = ok ? gl_classify_log(text) :
    (:unreadable, gl_evidence(note = "log unreadable"))

# --- disk census (race-aware, nonthrowing, injectable) ----------------------

# finals per manifest row + ALL .g2c.part.* files enumerated from BOTH
# band dirs (rogue/unmanifested partials included, manifest_bytes = -1).
# fsizefn returns Int/nothing/:err; a :err or a part vanishing between
# list and stat marks the snapshot unstable.
function gl_disk_verdict(dest, rows; h5fn = nothing,
                         fsizefn = gl_default_fsize,
                         listfn = gl_default_list)
    sizes = Dict(rows)
    present = 0; exact = 0; wrong = String[]; missing_names = String[]
    unstable = String[]; h5_failed = String[]
    for (name, size) in rows
        sub = gl_band_sub(name)
        sub === nothing && (push!(wrong, "no band dir: $name"); continue)
        sz = fsizefn(joinpath(dest, sub, name))
        if sz === :err
            push!(unstable, "final stat error: $name")
        elseif sz === nothing
            push!(missing_names, name)
        else
            present += 1
            if sz == size
                exact += 1
                (h5fn !== nothing && !h5fn(joinpath(dest, sub, name))) &&
                    push!(h5_failed, name)
            else
                push!(wrong, "$name local=$sz manifest=$size")
            end
        end
    end
    parts = Tuple{String, Int, Int}[]   # (name, part_bytes, manifest_bytes|-1)
    for sub in ("lw_spectra", "sw_spectra")
        entries = listfn(joinpath(dest, sub))
        if entries === nothing
            push!(unstable, "band dir unlistable: $sub")
            continue
        end
        for e in entries
            startswith(e, GL_PART_PREFIX) || continue
            name = e[length(GL_PART_PREFIX)+1:end]
            psz = fsizefn(joinpath(dest, sub, e))
            if psz === :err || psz === nothing
                push!(unstable, "part unstable (stat error or vanished " *
                                "mid-scan): $e")
            else
                # band-bound: a manifested name found in the WRONG band
                # dir is rogue (manifest_bytes = -1), never resumable
                msz = gl_band_sub(name) == sub ? get(sizes, name, -1) : -1
                push!(parts, (name, psz, msz))
            end
        end
    end
    (present = present, exact = exact, wrong = wrong,
     missing = missing_names, parts = parts, h5_failed = h5_failed,
     total = length(rows), stable = isempty(unstable),
     unstable_reads = unstable)
end

gl_parts_resumable(d) =
    length(d.parts) <= 1 &&
    all(t -> t[3] > 0 && t[2] <= t[3], d.parts) &&
    isempty(d.wrong)

gl_disk_complete(d) =
    d.exact == d.total && isempty(d.wrong) && isempty(d.missing) &&
    isempty(d.parts) && isempty(d.h5_failed)

# --- overall state machine (pure) ------------------------------------------

# reg: registered attempts (jobid, state, evidence) ordered by job id
# newer_unreg: an unregistered log newer than every registered attempt
# probe: (ok, active::Vector{(id, state)}, unregistered_active::Bool)
# disk: gl_disk_verdict result
function gl_overall(reg, newer_unreg, probe, disk; missing_latest = false,
                    receipt = GL_NO_RECEIPT, logbind = GL_NO_LOGBIND)
    newer_unreg &&
        return ("g2c_fetch_ledger_indeterminate_refused",
                "unregistered attempt log newer than every registered " *
                "attempt; refusing to classify (registry required)")
    # the NEWEST registered attempt must be evidenced by a log or a
    # queue entry; never fall back to classifying an older attempt
    missing_latest &&
        return ("g2c_fetch_ledger_indeterminate_refused",
                "newest registered attempt has neither a log nor a " *
                "scheduler entry (vanished or submission failed before " *
                "log creation); refusing to classify an older attempt")
    # a semantic marker in the latest registered log is queue-independent
    if !isempty(reg) && reg[end][2] == :semantic_failure
        return ("g2c_fetch_ledger_failed",
                "latest registered attempt $(reg[end][1]): semantic " *
                "failure marker: $(reg[end][3]["first_failure_marker"])")
    end
    probe.ok ||
        return ("g2c_fetch_ledger_indeterminate_refused",
                "scheduler probe failed; fail-closed (cannot rule out a " *
                "queued/running attempt)")
    probe.unregistered_active &&
        return ("g2c_fetch_ledger_indeterminate_refused",
                "active queue entry under the G2c job name is NOT in the " *
                "attempt registry; refusing")
    active = !isempty(probe.active)
    isempty(reg) &&
        return (active ?
            ("g2c_fetch_ledger_waiting_for_job",
             "registered attempt queued with no log yet: " *
             join(["$(i):$(s)" for (i, s) in probe.active], ", ")) :
            ("g2c_fetch_ledger_indeterminate_refused",
             "no registered attempt logs and nothing queued"))
    active &&
        return ("g2c_fetch_ledger_waiting_for_job",
                "registered attempt in queue (" *
                join(["$(i):$(s)" for (i, s) in probe.active], ", ") *
                "); latest log state $(reg[end][2])")
    latest = reg[end]
    st = latest[2]
    st == :unreadable &&
        return ("g2c_fetch_ledger_indeterminate_refused",
                "latest registered attempt $(latest[1]) log unreadable")
    if st == :terminal_complete
        # completion additionally requires the durable scheduler
        # termination receipt, bound to THIS attempt, showing a clean
        # COMPLETED (the log alone is never sufficient)
        receipt.present ||
            return ("g2c_fetch_ledger_indeterminate_refused",
                    "terminal claim without a readable termination " *
                    "receipt (registry termination_record missing or " *
                    "unreadable)")
        isempty(receipt.binding_issues) ||
            return ("g2c_fetch_ledger_indeterminate_refused",
                    "termination receipt does not bind to attempt " *
                    "$(latest[1]): " * join(receipt.binding_issues, "; "))
        logbind.ok ||
            return ("g2c_fetch_ledger_indeterminate_refused",
                    "terminal log digest not bound: " * logbind.reason)
        receipt.completed_ok ||
            return ("g2c_fetch_ledger_failed",
                    "termination receipt contradicts the terminal log " *
                    "(JobState=$(receipt.state) or nonzero/dirty exit " *
                    "fields)")
        disk.stable ||
            return ("g2c_fetch_ledger_indeterminate_refused",
                    "terminal claim but disk snapshot unstable: " *
                    join(disk.unstable_reads, "; "))
        gl_disk_complete(disk) &&
            return ("g2c_fetch_completed_verified",
                    "terminal log $(latest[1]) + stable disk " *
                    "$(disk.exact)/$(disk.total) exact + h5-open all + " *
                    "no .part in either band dir")
        return ("g2c_fetch_ledger_failed",
                "terminal-complete log $(latest[1]) contradicted by " *
                "stable disk: exact=$(disk.exact)/$(disk.total) " *
                "wrong=$(length(disk.wrong)) missing=$(length(disk.missing)) " *
                "parts=$(length(disk.parts)) h5_failed=$(length(disk.h5_failed))")
    end
    if st == :timeout
        # resumable_timeout requires the receipt to PROVE the TIMEOUT:
        # log text alone never authorizes the continuity path
        receipt.present ||
            return ("g2c_fetch_ledger_indeterminate_refused",
                    "timeout resumability requires a readable " *
                    "termination receipt proving TIMEOUT")
        isempty(receipt.binding_issues) ||
            return ("g2c_fetch_ledger_indeterminate_refused",
                    "termination receipt does not bind to attempt " *
                    "$(latest[1]): " * join(receipt.binding_issues, "; "))
        logbind.ok ||
            return ("g2c_fetch_ledger_indeterminate_refused",
                    "terminal log digest not bound: " * logbind.reason)
        receipt.state == "TIMEOUT" ||
            return ("g2c_fetch_ledger_failed",
                    "termination receipt JobState=$(receipt.state) " *
                    "contradicts the timeout log claim")
        disk.stable ||
            return ("g2c_fetch_ledger_indeterminate_refused",
                    "timeout claim but disk snapshot unstable: " *
                    join(disk.unstable_reads, "; "))
        gl_parts_resumable(disk) &&
            return ("g2c_fetch_ledger_resumable_timeout",
                    "registered attempt $(latest[1]) hit TIME LIMIT with " *
                    "clean resume state (finals exact; " *
                    "parts=$(length(disk.parts)), all manifested and <= " *
                    "manifest size): TIMEOUT-only continuity applies")
        return ("g2c_fetch_ledger_failed",
                "timeout attempt $(latest[1]) but disk NOT clean for " *
                "resume: wrong=$(length(disk.wrong)) parts=" *
                join(["$(n):$(p)B/manifest=$(m)B" for (n, p, m) in disk.parts], ",") *
                " (rogue part has manifest=-1)")
    end
    ("g2c_fetch_ledger_indeterminate_refused",
     "latest registered attempt $(latest[1]) incomplete with nothing " *
     "queued and no timeout marker; refusing to guess")
end

# --- live probes ------------------------------------------------------------

function gl_scan_logs(dir)
    isdir(dir) || return nothing
    found = Tuple{Int, String}[]
    entries = try readdir(dir) catch; return nothing end
    for f in entries
        m = match(GL_LOG_RE, f)
        m === nothing && continue
        push!(found, (parse(Int, m.captures[1]), joinpath(dir, f)))
    end
    sort!(found; by = first)
    found
end

# by user + job name (catches a newly PENDING retry with no log);
# fail-closed: any probe error -> ok=false
function gl_queue_probe(registered_ids)
    try
        user = strip(read(`id -un`, String))
        out = read(pipeline(`squeue -h -u $user -n $GL_JOB_NAME -o "%i %T"`,
                            stderr=devnull), String)
        entries = Tuple{Int, String}[]
        for l in split(out, '\n')
            isempty(strip(l)) && continue
            p = split(strip(l))
            length(p) >= 2 || return (ok = false,
                active = Tuple{Int, String}[], unregistered_active = false)
            push!(entries, (parse(Int, p[1]), String(p[2])))
        end
        (ok = true, active = entries,
         unregistered_active = any(e -> !(e[1] in registered_ids), entries))
    catch
        (ok = false, active = Tuple{Int, String}[],
         unregistered_active = false)
    end
end

function gl_h5_open(path)
    try
        success(pipeline(`python3 -c "import sys, h5py; h5py.File(sys.argv[1], 'r').close()" $path`,
                         stdout=devnull, stderr=devnull)) && return true
    catch
    end
    try
        return success(pipeline(`h5ls $path`, stdout=devnull, stderr=devnull))
    catch
        return false
    end
end

function gl_quota_row_observed()
    try
        uid = strip(read(`id -u`, String))
        row = strip(split(read(pipeline(`lfs quota -q -u $uid /shared`,
                                        stderr=devnull), String), "\n")[1])
        isempty(row) ? "unavailable" : row
    catch
        "unavailable"
    end
end

# --- fail-closed gate census -----------------------------------------------

function gl_close_failed_gates!(fails, gates)
    bad = sort([k for (k, v) in gates if v != "passed"])
    isempty(bad) ||
        push!(fails, "failed gates (fail-closed census): " * join(bad, ", "))
end

# --- synthetic fixtures ----------------------------------------------------

function gl_fixtures()
    t = Dict{String, Bool}()
    rows = [("ckdmip_evaluation2_lw_spectra_fx1_1-10.h5", 101),
            ("ckdmip_evaluation2_lw_spectra_fx2_1-10.h5", 102),
            ("ckdmip_evaluation2_lw_spectra_fx3_1-10.h5", 103),
            ("ckdmip_evaluation2_sw_spectra_fx4_1-10.h5", 104)]
    rowdir(i) = gl_band_sub(rows[i][1])
    mkdest(; finals = Dict{Int, Int}(), parts = Dict{Int, Int}(),
             rogue = false, wrongband = Dict{Int, Int}()) = begin
        d = mktempdir()
        mkpath(joinpath(d, "lw_spectra")); mkpath(joinpath(d, "sw_spectra"))
        mk(dir, fname, sz) = open(joinpath(d, dir, fname), "w") do io
            sz > 0 && (seek(io, sz - 1); write(io, UInt8(0)))
        end
        for (i, sz) in finals
            mk(rowdir(i), rows[i][1], sz)
        end
        for (i, sz) in parts
            mk(rowdir(i), GL_PART_PREFIX * rows[i][1], sz)
        end
        # a manifested name planted as a .part in the OTHER band dir
        for (i, sz) in wrongband
            mk(rowdir(i) == "lw_spectra" ? "sw_spectra" : "lw_spectra",
               GL_PART_PREFIX * rows[i][1], sz)
        end
        rogue && write(joinpath(d, "sw_spectra",
                                GL_PART_PREFIX * "unmanifested.h5"), "x")
        d
    end
    exact4 = Dict(1 => 101, 2 => 102, 3 => 103, 4 => 104)
    h5ok = _ -> true

    term_log = "=== G2c stage 0: preflight ===\nfetcher: ecpds\n" *
        "FINALIZED a (1 B)\nFINALIZED b (1 B)\n" *
        GL_STAGE2_MARK * " (size + h5 sanity vs manifest) ===\n" *
        GL_DONE_MARK * " 2026-08-13T12:00:00Z ===\n"
    timeout_log = "fetcher: ecpds\nFINALIZED a (1 B)\n" *
        "slurmstepd: error: *** JOB 4500 ON node CANCELLED AT " *
        "2026-08-13T21:00:00 DUE TO TIME LIMIT ***\n"
    sem_log = "fetcher: ecpds\nREFUSED: part size mismatch x part=5 manifest=9\n"
    legacy4440_log = "download: s3://x -> y\ndownload failed: " *
        "[Errno 122] Disk quota exceeded\n"
    inc_log = "=== G2c stage 0: preflight ===\nfetcher: ecpds\n" *
        "FINALIZED a (1 B)\n"

    # per-log classifier classes
    t["log_terminal_complete"] = gl_classify_log(term_log)[1] == :terminal_complete
    t["log_semantic_failure"] = gl_classify_log(sem_log)[1] == :semantic_failure
    t["log_timeout"] = gl_classify_log(timeout_log)[1] == :timeout
    t["log_incomplete"] = gl_classify_log(inc_log)[1] == :incomplete
    t["legacy_4440_markers_semantic"] =
        gl_classify_log(legacy4440_log)[1] == :semantic_failure
    t["timeout_text_not_semantic"] =
        gl_classify_log(timeout_log)[1] != :semantic_failure
    t["finalized_never_sole_proof"] =
        gl_classify_log("FINALIZED a (1 B)\nFINALIZED b (1 B)\n")[1] == :incomplete
    t["failure_marker_beats_done"] =
        gl_classify_log(sem_log * term_log)[1] == :semantic_failure
    # complete evidence schema on unreadable logs (MD-render safety)
    let (st, ev) = gl_attempt_state(false, "")
        t["unreadable_evidence_schema_complete"] = st == :unreadable &&
            all(haskey(ev, k) for k in ("finalized_lines", "skip_lines",
                                        "fetcher", "first_failure_marker",
                                        "note"))
    end

    A(s) = [(4500, s, gl_evidence(marker = s == :semantic_failure ?
                                  "REFUSED: fixture" : ""))]
    P(; ok = true, active = Tuple{Int, String}[], unreg = false) =
        (ok = ok, active = active, unregistered_active = unreg)
    dv(d; h5fn = h5ok, kw...) = gl_disk_verdict(d, rows; h5fn, kw...)
    idle = P()
    RC = (present = true, binding_issues = String[], completed_ok = true,
          state = "COMPLETED")
    RT = (present = true, binding_issues = String[], completed_ok = false,
          state = "TIMEOUT")
    LOK = (ok = true, reason = "")
    esl = "sbatch --parsable validation/results/gate4_g2c_eval2_fetch.sbatch"

    # overall machine
    t["active_incomplete_is_waiting"] =
        gl_overall(A(:incomplete), false,
                   P(active = [(4500, "RUNNING")]), dv(mkdest()))[1] ==
        "g2c_fetch_ledger_waiting_for_job"
    t["incomplete_no_queue_refuses"] =
        gl_overall(A(:incomplete), false, idle, dv(mkdest()))[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["no_attempts_nothing_queued_refuses"] =
        gl_overall(Tuple{Int, Symbol, Dict{String, Any}}[], false, idle,
                   dv(mkdest()))[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["pending_retry_no_log_is_waiting"] =
        gl_overall(Tuple{Int, Symbol, Dict{String, Any}}[], false,
                   P(active = [(4600, "PENDING")]), dv(mkdest()))[1] ==
        "g2c_fetch_ledger_waiting_for_job"
    t["probe_failure_refuses_timeout"] =
        gl_overall(A(:timeout), false, P(ok = false),
                   dv(mkdest(finals = Dict(1 => 101))))[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["probe_failure_refuses_incomplete"] =
        gl_overall(A(:incomplete), false, P(ok = false), dv(mkdest()))[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["probe_failure_still_fails_semantic"] =
        gl_overall(A(:semantic_failure), false, P(ok = false),
                   dv(mkdest()))[1] == "g2c_fetch_ledger_failed"
    t["unregistered_active_refuses"] =
        gl_overall(A(:timeout), false,
                   P(active = [(9999, "PENDING")], unreg = true),
                   dv(mkdest(finals = Dict(1 => 101))))[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["unregistered_newer_log_refuses"] =
        gl_overall(A(:terminal_complete), true, idle,
                   dv(mkdest(finals = exact4)))[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["timeout_clean_part_resumable"] =
        gl_overall(A(:timeout), false, idle,
                   dv(mkdest(finals = Dict(1 => 101), parts = Dict(2 => 50)));
                   receipt = RT, logbind = LOK)[1] ==
        "g2c_fetch_ledger_resumable_timeout"
    t["timeout_oversized_part_fails"] =
        gl_overall(A(:timeout), false, idle,
                   dv(mkdest(parts = Dict(2 => 9999))); receipt = RT, logbind = LOK)[1] ==
        "g2c_fetch_ledger_failed"
    t["timeout_rogue_part_fails"] =
        gl_overall(A(:timeout), false, idle,
                   dv(mkdest(finals = Dict(1 => 101), rogue = true));
                   receipt = RT, logbind = LOK)[1] ==
        "g2c_fetch_ledger_failed"
    t["timeout_two_parts_fails"] =
        gl_overall(A(:timeout), false, idle,
                   dv(mkdest(parts = Dict(1 => 10, 2 => 10))); receipt = RT, logbind = LOK)[1] ==
        "g2c_fetch_ledger_failed"
    t["timeout_wrong_size_final_fails"] =
        gl_overall(A(:timeout), false, idle, dv(mkdest(finals = Dict(1 => 55)));
                   receipt = RT, logbind = LOK)[1] ==
        "g2c_fetch_ledger_failed"
    t["semantic_failure_fails"] =
        gl_overall(A(:semantic_failure), false, idle, dv(mkdest()))[1] ==
        "g2c_fetch_ledger_failed"
    t["terminal_plus_disk_verified"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4)); receipt = RC, logbind = LOK)[1] ==
        "g2c_fetch_completed_verified"
    t["terminal_disk_contradiction_fails"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = Dict(1 => 101, 2 => 102)));
                   receipt = RC, logbind = LOK)[1] ==
        "g2c_fetch_ledger_failed"
    t["terminal_leftover_part_fails"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4, parts = Dict(1 => 10)));
                   receipt = RC, logbind = LOK)[1] ==
        "g2c_fetch_ledger_failed"
    t["terminal_rogue_part_fails"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4, rogue = true)); receipt = RC, logbind = LOK)[1] ==
        "g2c_fetch_ledger_failed"
    t["terminal_h5_failure_fails"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4);
                      h5fn = p -> !occursin("fx2", p)); receipt = RC, logbind = LOK)[1] ==
        "g2c_fetch_ledger_failed"
    t["terminal_while_active_is_waiting"] =
        gl_overall(A(:terminal_complete), false,
                   P(active = [(4600, "RUNNING")]),
                   dv(mkdest(finals = exact4)))[1] ==
        "g2c_fetch_ledger_waiting_for_job"
    t["unreadable_latest_refuses"] =
        gl_overall([(4500, :unreadable, gl_evidence(note = "log unreadable"))],
                   false, idle, dv(mkdest(finals = exact4)))[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    # race-aware snapshot: stat error under a terminal/timeout claim refuses
    err_fsize(bad) = p -> occursin(bad, p) ? :err : gl_default_fsize(p)
    t["terminal_unstable_snapshot_refuses"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4); fsizefn = err_fsize("fx1"));
                   receipt = RC, logbind = LOK)[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["timeout_unstable_snapshot_refuses"] =
        gl_overall(A(:timeout), false, idle,
                   dv(mkdest(finals = exact4); fsizefn = err_fsize("fx1"));
                   receipt = RT, logbind = LOK)[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["unlistable_band_dir_is_unstable"] =
        !gl_disk_verdict(mkdest(), rows; listfn = _ -> nothing).stable
    # multi-attempt
    t["multi_attempt_latest_wins"] =
        gl_overall([(4500, :timeout, gl_evidence()),
                    (4600, :terminal_complete, gl_evidence())],
                   false, idle, dv(mkdest(finals = exact4)); receipt = RC, logbind = LOK)[1] ==
        "g2c_fetch_completed_verified"
    t["multi_attempt_latest_semantic_fails"] =
        gl_overall([(4500, :timeout, gl_evidence()),
                    (4600, :semantic_failure,
                     gl_evidence(marker = "REFUSED: fixture"))],
                   false, idle, dv(mkdest(finals = exact4)))[1] ==
        "g2c_fetch_ledger_failed"
    # registry receipt binding
    goodrow(id) = Dict("job_id" => id,
        "sbatch_sha256" => GL_REVIEWED_SBATCH_SHA,
        "reviewed_commit" => GL_REVIEWED_COMMIT,
        "submitted_utc" => "2026-08-13T09:38:59Z", "submitted_by" => "x")
    ri(reg) = gl_registry_issues(reg, GL_REVIEWED_SBATCH_SHA,
                                 GL_REVIEWED_COMMIT)
    t["registry_valid_passes"] = isempty(ri([goodrow(4500), goodrow(4600)]))
    t["registry_wrong_hash_refused"] = begin
        bad = goodrow(4600); bad["sbatch_sha256"] = "deadbeef"
        !isempty(ri([goodrow(4500), bad]))
    end
    t["registry_wrong_commit_refused"] = begin
        bad = goodrow(4600); bad["reviewed_commit"] = "0000000"
        !isempty(ri([goodrow(4500), bad]))
    end
    t["registry_duplicate_id_refused"] =
        !isempty(ri([goodrow(4500), goodrow(4500)]))
    t["registry_empty_receipt_refused"] = begin
        bad = goodrow(4600); bad["submitted_by"] = "  "
        !isempty(ri([goodrow(4500), bad]))
    end
    # malformed job_id through the ACTUAL ID-extraction helper: no throw,
    # bad row excluded (integrity gate separately fails it)
    t["registry_ids_nonthrowing_on_malformed"] = begin
        bad = goodrow(4600); bad["job_id"] = "not-an-int"
        bad2 = goodrow(4700); delete!(bad2, "job_id")
        gl_registry_ids([goodrow(4500), bad, bad2]) == Set([4500])
    end
    # newest registered attempt evidenced by neither log nor queue
    t["latest_registered_missing_refuses"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4));
                   missing_latest = true)[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    # band-bound partial: SW-named manifested part planted in lw_spectra
    # must be rogue (manifest -1), never resumable
    t["wrong_band_part_fails"] =
        gl_overall(A(:timeout), false, idle,
                   dv(mkdest(finals = Dict(1 => 101),
                             wrongband = Dict(4 => 50))); receipt = RT, logbind = LOK)[1] ==
        "g2c_fetch_ledger_failed"
    t["wrong_band_part_marked_rogue"] = begin
        d = gl_disk_verdict(mkdest(wrongband = Dict(4 => 50)), rows)
        length(d.parts) == 1 && d.parts[1][3] == -1
    end
    # scontrol termination receipt: parse + binding + machine integration
    rc_text(; id = 4500, state = "COMPLETED", reason = "None",
              exit = "0:0", dexit = "0:0", restarts = "0",
              cmd = GL_SBATCH,
              submitline = "sbatch --parsable validation/results/" *
                  "gate4_g2c_eval2_fetch.sbatch",
              stdout = joinpath(GL_LOG_DIR, "g4-g2c-4500.log")) =
        "JobId=$id JobName=$GL_JOB_NAME\n" *
        "   JobState=$state Reason=$reason Dependency=(null)\n" *
        "   Requeue=1 Restarts=$restarts BatchFlag=1 ExitCode=$exit\n" *
        "   DerivedExitCode=$dexit\n" *
        "   RunTime=02:00:12 TimeLimit=12:00:00\n" *
        "   StartTime=2026-08-13T09:43:03 EndTime=2026-08-13T11:43:15\n" *
        "   Command=$cmd\n" *
        "   SubmitLine=$submitline\n" *
        "   StdOut=$stdout\n"
    rsum(txt, id) = begin
        f = gl_parse_receipt(txt)
        gl_receipt_summary(true, f, gl_receipt_binding_issues(f, id;
            expected_submit_line = esl))
    end
    t["receipt_good_completed_parses_and_binds"] = begin
        r = rsum(rc_text(), 4500)
        isempty(r.binding_issues) && r.completed_ok && r.state == "COMPLETED"
    end
    t["receipt_good_completed_verifies"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4));
                   receipt = rsum(rc_text(), 4500), logbind = LOK)[1] ==
        "g2c_fetch_completed_verified"
    t["receipt_wrong_state_fails"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4));
                   receipt = rsum(rc_text(state = "FAILED"), 4500), logbind = LOK)[1] ==
        "g2c_fetch_ledger_failed"
    t["receipt_nonzero_exit_fails"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4));
                   receipt = rsum(rc_text(exit = "1:0"), 4500), logbind = LOK)[1] ==
        "g2c_fetch_ledger_failed"
    t["receipt_jobid_mismatch_refuses"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4));
                   receipt = rsum(rc_text(id = 4999,
                       stdout = joinpath(GL_LOG_DIR, "g4-g2c-4999.log")),
                       4500))[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["receipt_command_mismatch_refuses"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4));
                   receipt = rsum(rc_text(cmd = "/tmp/other.sbatch"), 4500))[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["receipt_missing_terminal_refuses"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4)))[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["receipt_timeout_proof_grants_resumable"] =
        gl_overall(A(:timeout), false, idle,
                   dv(mkdest(finals = Dict(1 => 101), parts = Dict(2 => 50)));
                   receipt = rsum(rc_text(state = "TIMEOUT",
                       reason = "TimeLimit", exit = "0:15"), 4500), logbind = LOK)[1] ==
        "g2c_fetch_ledger_resumable_timeout"
    t["receipt_completed_under_timeout_log_fails"] =
        gl_overall(A(:timeout), false, idle,
                   dv(mkdest(finals = Dict(1 => 101)));
                   receipt = rsum(rc_text(), 4500), logbind = LOK)[1] ==
        "g2c_fetch_ledger_failed"
    t["receipt_missing_timeout_refuses"] =
        gl_overall(A(:timeout), false, idle,
                   dv(mkdest(finals = Dict(1 => 101))))[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["waiting_valid_before_receipt_exists"] =
        gl_overall(A(:incomplete), false,
                   P(active = [(4500, "RUNNING")]), dv(mkdest()))[1] ==
        "g2c_fetch_ledger_waiting_for_job"
    # EXACT SubmitLine: injected option with the same basename refuses
    t["submitline_injected_prefix_refuses"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4));
                   receipt = rsum(rc_text(submitline = "sbatch --parsable " *
                       "--export=X=1 validation/results/" *
                       "gate4_g2c_eval2_fetch.sbatch"), 4500),
                   logbind = LOK)[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["submitline_unregistered_expectation_refuses"] = begin
        f = gl_parse_receipt(rc_text())
        !isempty(gl_receipt_binding_issues(f, 4500;
                                           expected_submit_line = ""))
    end
    # immutable terminal-log digest binding
    h = "ab" ^ 32
    t["digest_good_binds"] = gl_log_binding(h, h).ok
    t["digest_missing_refuses_terminal"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4));
                   receipt = RC)[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["digest_missing_refuses_timeout"] =
        gl_overall(A(:timeout), false, idle,
                   dv(mkdest(finals = Dict(1 => 101)));
                   receipt = RT)[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["digest_malformed_refuses"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4));
                   receipt = RC,
                   logbind = gl_log_binding("not-hex", h))[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    t["digest_mismatch_refuses"] =
        gl_overall(A(:terminal_complete), false, idle,
                   dv(mkdest(finals = exact4));
                   receipt = RC,
                   logbind = gl_log_binding(h, "cd" ^ 32))[1] ==
        "g2c_fetch_ledger_indeterminate_refused"
    # registry digest well-formedness
    t["registry_bad_log_digest_refused"] = begin
        bad = goodrow(4600); bad["terminal_log_sha256"] = "xyz"
        !isempty(ri([goodrow(4500), bad]))
    end
    t
end

# --- main -------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()

    tests = gl_fixtures()
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    rows = try gl_manifest_rows(GL_MANIFEST) catch; nothing end
    man_ok = rows !== nothing && length(rows) == GL_MANIFEST_COUNT &&
             length(unique(first.(rows))) == GL_MANIFEST_COUNT &&
             sum(last.(rows)) == GL_MANIFEST_TOTAL
    gates["manifest_integrity"] = man_ok ? "passed" : "failed"
    man_ok || push!(fails, "manifest count/uniqueness/sum drift")

    live_sbatch_sha = gl_try_sha(GL_SBATCH)
    gates["reviewed_sbatch_sha_pinned"] =
        live_sbatch_sha == GL_REVIEWED_SBATCH_SHA ? "passed" : "failed"
    gates["reviewed_sbatch_sha_pinned"] == "passed" ||
        push!(fails, "live sbatch sha $(something(live_sbatch_sha, "unreadable")) " *
                     "!= reviewed $(GL_REVIEWED_SBATCH_SHA)")

    logs = gl_scan_logs(GL_LOG_DIR)
    gates["log_scan_readable"] = logs === nothing ? "failed" : "passed"
    logs === nothing && push!(fails, "log dir unreadable: $GL_LOG_DIR")

    reg = Tuple{Int, Symbol, Dict{String, Any}}[]
    attempt_records = Any[]
    log_shas = Dict{Int, String}()
    max_unreg = -1
    if logs !== nothing
        for (jid, path) in logs
            ok, text = gl_try_read(path)
            st, ev = gl_attempt_state(ok, text)
            # coupled digest: hash the SAME bytes that were classified
            lsha = ok ? bytes2hex(sha256(codeunits(text))) : nothing
            ok && (log_shas[jid] = lsha)
            registered = jid in GL_REGISTERED_IDS
            registered ? push!(reg, (jid, st, ev)) :
                         (max_unreg = max(max_unreg, jid))
            push!(attempt_records, Dict("job_id" => jid, "log" => path,
                "readable" => ok, "state" => String(st),
                "log_sha256" => lsha,
                "registered" => registered,
                "registry_note" => registered ?
                    "registered reviewed attempt" :
                    "UNREGISTERED legacy/history log; NOT implied to " *
                    "have run the reviewed sbatch",
                "evidence" => ev))
        end
    end
    newer_unreg = max_unreg > (isempty(reg) ? -1 : reg[end][1]) &&
                  !isempty(GL_REGISTERED_IDS) &&
                  max_unreg > maximum(GL_REGISTERED_IDS)
    gates["no_unregistered_newer_attempt"] = newer_unreg ? "failed" : "passed"

    reg_issues = gl_registry_issues(GL_ATTEMPT_REGISTRY,
                                    GL_REVIEWED_SBATCH_SHA,
                                    GL_REVIEWED_COMMIT)
    gates["attempt_registry_integrity"] =
        isempty(reg_issues) ? "passed" : "failed"
    isempty(reg_issues) ||
        push!(fails, "attempt registry invalid: " * join(reg_issues, "; "))

    probe = gl_queue_probe(GL_REGISTERED_IDS)
    gates["scheduler_probe_ok"] = probe.ok ? "passed" : "failed"
    probe.ok || push!(fails, "squeue probe failed; classification refused")

    # the NEWEST registered attempt must be evidenced by a log or a
    # live scheduler entry; a vanished/failed submission refuses
    latest_reg_id = isempty(GL_REGISTERED_IDS) ? -1 : maximum(GL_REGISTERED_IDS)
    latest_has_log = any(a[1] == latest_reg_id for a in reg)
    latest_in_queue = probe.ok && any(i == latest_reg_id
                                      for (i, _) in probe.active)
    missing_latest = !latest_has_log && !latest_in_queue
    gates["latest_registered_attempt_evidenced"] =
        missing_latest ? "failed" : "passed"

    # durable scheduler termination receipt for the latest registered
    # attempt: REQUIRED completion evidence for terminal/timeout claims;
    # waiting-while-live is valid before a receipt exists
    latest_row = findlast(r -> get(r, "job_id", -1) == latest_reg_id,
                          GL_ATTEMPT_REGISTRY)
    term_path = latest_row === nothing ? "" :
        get(GL_ATTEMPT_REGISTRY[latest_row], "termination_record", "")
    receipt = GL_NO_RECEIPT
    receipt_sha = nothing
    receipt_fields = Dict{String, String}()
    expected_sl = latest_row === nothing ? "" :
        get(GL_ATTEMPT_REGISTRY[latest_row], "expected_submit_line", "")
    if !isempty(term_path)
        rok, rtext = gl_try_read(term_path)
        if rok
            receipt_sha = bytes2hex(sha256(codeunits(rtext)))
            receipt_fields = gl_parse_receipt(rtext)
            receipt = gl_receipt_summary(true, receipt_fields,
                gl_receipt_binding_issues(receipt_fields, latest_reg_id;
                    expected_submit_line = expected_sl))
        end
    end
    latest_state = isempty(reg) ? :none : reg[end][2]
    needs_receipt = latest_state in (:terminal_complete, :timeout)
    gates["termination_receipt_bound"] = !needs_receipt ? "passed" :
        (receipt.present && isempty(receipt.binding_issues) &&
         (latest_state == :terminal_complete ? receipt.completed_ok :
          receipt.state == "TIMEOUT")) ? "passed" : "failed"
    gates["termination_receipt_bound"] == "passed" ||
        push!(fails, "termination receipt missing/unbound/contradictory " *
                     "for the latest registered attempt")

    # immutable terminal-log digest binding (registered pin == live bytes)
    reg_digest = latest_row === nothing ? "" :
        get(GL_ATTEMPT_REGISTRY[latest_row], "terminal_log_sha256", "")
    logbind = gl_log_binding(reg_digest, get(log_shas, latest_reg_id, nothing))
    gates["terminal_log_digest_bound"] = !needs_receipt ? "passed" :
        (logbind.ok ? "passed" : "failed")
    gates["terminal_log_digest_bound"] == "passed" ||
        push!(fails, "terminal log digest not bound: " * logbind.reason)

    latest_terminal = !isempty(reg) && reg[end][2] == :terminal_complete
    disk = man_ok ? gl_disk_verdict(GL_DEST, rows;
                        h5fn = latest_terminal ? gl_h5_open : nothing) :
           gl_disk_verdict(GL_DEST, Tuple{String, Int}[])

    status, reason = man_ok && gates["fixtures"] == "passed" &&
                     gates["reviewed_sbatch_sha_pinned"] == "passed" &&
                     gates["attempt_registry_integrity"] == "passed" &&
                     logs !== nothing ?
        gl_overall(reg, newer_unreg, probe, disk;
                   missing_latest, receipt, logbind) :
        ("g2c_fetch_ledger_indeterminate_refused",
         "prerequisite gates failed; refusing to classify")

    gl_close_failed_gates!(fails, gates)

    result = Dict(
        "case" => "gate4_g2c_fetch_completion_ledger",
        "data_mode" => "read_only_evidence_ledger",
        "status" => status,
        "status_reason" => reason,
        "timestamp_utc" => string(Dates.now(Dates.UTC)) * "Z",
        "gates" => gates, "failures" => fails,
        "fixture_verdicts" => tests,
        "attempt_registry" => GL_ATTEMPT_REGISTRY,
        "attempts" => attempt_records,
        "queue_probe" => Dict("ok" => probe.ok,
            "active" => [Dict("job_id" => i, "state" => s)
                         for (i, s) in probe.active],
            "unregistered_active" => probe.unregistered_active),
        "disk" => Dict(
            "present" => disk.present, "exact" => disk.exact,
            "total" => disk.total, "stable" => disk.stable,
            "unstable_reads" => disk.unstable_reads,
            "wrong_size" => disk.wrong,
            "missing_count" => length(disk.missing),
            "parts" => [Dict("name" => n, "part_bytes" => p,
                             "manifest_bytes" => m) for (n, p, m) in disk.parts],
            "h5_failed" => disk.h5_failed,
            "h5_opened_every_final" => latest_terminal),
        "quota_observed_at" => Dict(
            "row_verbatim" => gl_quota_row_observed(),
            "observed_at_utc" => string(Dates.now(Dates.UTC)) * "Z",
            "note" => "observation record only; never a gate input in " *
                      "this deterministic-classification unit"),
        "reviewed" => Dict(
            "commit" => GL_REVIEWED_COMMIT,
            "sbatch_sha256" => GL_REVIEWED_SBATCH_SHA,
            "sbatch_sha256_live" => live_sbatch_sha),
        "termination_receipt" => Dict(
            "path" => term_path,
            "readable" => receipt.present,
            "sha256" => receipt_sha,
            "parsed_fields" => receipt_fields,
            "binding_issues" => receipt.binding_issues,
            "completed_ok" => receipt.completed_ok,
            "job_state" => receipt.state,
            "note" => "REQUIRED completion evidence for terminal/timeout " *
                "claims; the log alone never proves completion or " *
                "authorizes the continuity path"),
        "terminal_log_digest" => Dict(
            "registered" => reg_digest,
            "live" => get(log_shas, latest_reg_id, nothing),
            "bound" => logbind.ok,
            "reason" => logbind.reason,
            "note" => "the completion/timeout claim is anchored to the " *
                "registered immutable digest; mutated log content can " *
                "never re-prove completion"),
        "continuity_policy" => "TIMEOUT-only resumption of the SAME " *
            "reviewed sbatch is covered by the recorded durable G2c " *
            "authorization; requires state " *
            "g2c_fetch_ledger_resumable_timeout (stable clean-part disk), " *
            "live quota guard pass, scheduler probe OK with no duplicate, " *
            "unchanged reviewed sbatch sha, and a registry row appended " *
            "for the new job ID at resubmission. Semantic failures are " *
            "NEVER auto-resubmitted.",
        "non_authorizing_note" => "this ledger records and classifies " *
            "evidence; it authorizes no fetch, submission, deletion, or " *
            "quota action",
        "disclaimer" => "read-only evidence ledger; nothing submitted, " *
            "fetched, or modified by this unit outside its own results " *
            "artifacts.",
    )
    mkpath(dirname(GL_RESULTS_JSON))
    open(GL_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(GL_RESULTS_MD, "w") do io
        println(io, "# Gate-4 G2c fetch completion ledger\n")
        println(io, "Status: **$status** -- $reason\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nAttempts (job id: log state):")
        for r in attempt_records
            tag = r["registered"] ? "registered" : "UNREGISTERED legacy"
            println(io, "- $(r["job_id"]) [$tag]: $(r["state"]) " *
                        "(FINALIZED lines: " *
                        "$(get(r["evidence"], "finalized_lines", "?")); " *
                        "provenance only)")
        end
        isempty(attempt_records) && println(io, "- none found")
        println(io, "\nQueue probe: ok=$(probe.ok), active=" *
                    "$(length(probe.active)), unregistered_active=" *
                    "$(probe.unregistered_active)")
        println(io, "\nTermination receipt: readable=$(receipt.present), " *
                    "JobState=$(isempty(receipt.state) ? "n/a" : receipt.state), " *
                    "bound=$(receipt.present && isempty(receipt.binding_issues)), " *
                    "sha256=$(something(receipt_sha, "n/a"))")
        println(io, "\nDisk: $(disk.exact)/$(disk.total) exact-size finals; " *
                    "$(length(disk.parts)) .part (both band dirs " *
                    "enumerated); stable=$(disk.stable); h5-opened every " *
                    "final: $latest_terminal")
        println(io, "\nContinuity policy: ", result["continuity_policy"])
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_g2c_fetch_completion_ledger: $status")
    println("  reason: $reason")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status in ("g2c_fetch_ledger_waiting_for_job",
                      "g2c_fetch_ledger_resumable_timeout",
                      "g2c_fetch_completed_verified") ? 0 : 1
end

exit(main())
