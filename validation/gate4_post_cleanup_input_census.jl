# Gate-4 POST-CLEANUP INPUT CENSUS (derivative, read-only, observed-at;
# no election, no authorization judgment, no quota/lfs reads).
#
# Purpose (monitor-directed, 2026-08-12): after the observed large
# usage drop, produce an evidence-grade deterministic record of which
# campaign inputs exist NOW. Machine facts stay NEUTRAL:
#   - every path in the scoped preflight's input inventory is re-stat'ed
#     and classified by the four-way transition recorded_present/
#     recorded_absent x now_present/now_absent -- no "expected",
#     "regression", or "deletion" vocabulary in machine data (the pinned
#     preflight schema does not mark paths required, so this census
#     cannot either);
#   - the register's RECORDED Path-D wording is represented strictly as
#     registered_scope_claim_vs_observation -- a claim recorded at
#     register time, NEVER a statement of current authorization;
#   - LIVE SCIENTIFIC INPUT rows are EXISTENCE and SIZE only (their
#     content is never read or hashed here; the preflight's recorded
#     observed hashes/verdicts are consumed as-is). Pinned SOURCE JSON
#     artifacts ARE byte-read and sha256-hashed (coupled snapshots),
#     and the scoped preflight artifact is verified against an exact
#     pinned sha.
# Traversal is bounded to the exact named roots, symlinks are never
# followed (walkdir follow_symlinks=false; symlinked entries counted,
# not traversed), and permission/read failures are RECORDED per
# directory, never silently skipped. Deterministic: sorted walks, no
# quota/lfs reads, coupled byte snapshots for every pinned-source load,
# atomic unique-temp+rename emission. Exit 0 is confined to completed
# censuses BECAUSE this artifact confers no readiness and authorizes
# nothing -- downstream must inspect the status token and payload;
# blocked sources and selftest failure remain nonzero.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON
import SHA

const PCC_RESULTS_JSON =
    validation_results_path("gate4_post_cleanup_input_census.json")
const PCC_RESULTS_MD =
    validation_results_path("gate4_post_cleanup_input_census.md")

# exact committed preflight artifact this census consumes (fail-closed
# readiness contract: case + status + byte sha, all inspectable below)
const PCC_PREFLIGHT_SHA =
    "f5b7e1714b107a7307842389ea3bdfbbd1bb0111f9509cafcdee464327955f0b"
const PCC_PREFLIGHT_JSON =
    validation_results_path("gate4_g3_scoped_input_preflight.json")
const PCC_G2C_JSON =
    validation_results_path("gate4_g2c_eval2_fetch_checkpoint.json")
const PCC_REGISTER_JSON =
    validation_results_path("gate4_pending_rulings_register.json")

const PCC_CKDMIP = "/shared/home/greg/data/ckdmip"
const PCC_PATH_D_DIRS = [joinpath(PCC_CKDMIP, "idealized", "lw_spectra"),
                         joinpath(PCC_CKDMIP, "idealized", "sw_spectra")]
const PCC_PRESERVE_DIRS = [joinpath(PCC_CKDMIP, "idealized", "conc"),
                           joinpath(PCC_CKDMIP, "evaluation1")]

# verbatim needles that must appear in the register's recorded Path-D
# byte scope before this census quotes it
const PCC_PATHD_NEEDLES = ["idealized/{lw_spectra,sw_spectra}",
                           "66 files / 217,901,253,443 B",
                           "PRESERVE", "evaluation1/"]

pcc_obj(x) = x isa AbstractDict ? x : Dict{String, Any}()
pcc_str(x) = x isa AbstractString ? String(x) : ""

# coupled BYTE snapshot (same construction as the rulings intake's
# ric_snapshot): one read supplies both the SHA-256 digest and the
# parsed content, so digest and facts can never describe different bytes
function pcc_snapshot(path)
    bytes = try
        read(path)
    catch
        return (readable = false, sha = nothing, parse_success = false,
                object_ok = false, data = nothing)
    end
    sha = bytes2hex(SHA.sha256(bytes))
    raw = try
        JSON.parse(String(bytes))
    catch
        return (readable = true, sha = sha, parse_success = false,
                object_ok = false, data = nothing)
    end
    return (readable = true, sha = sha, parse_success = true,
            object_ok = raw isa AbstractDict, data = raw)
end

# ---------------------------------------------------------------------------
# PURE validators/classifiers (used identically in production + fixtures)
# ---------------------------------------------------------------------------

# NEUTRAL four-way transition classes (recorded x now); no "expected"/
# "regression"/"deletion" vocabulary -- the pinned schema marks nothing
# required, so this census records transitions only. Production maps an
# unobservable path to the SEPARATE observation_error class, never here.
pcc_transition(recorded, now) =
    recorded && now ? "recorded_present_now_present" :
    recorded && !now ? "recorded_present_now_absent" :
    !recorded && !now ? "recorded_absent_now_absent" :
    "recorded_absent_now_present"

# single-lstat, NO-FOLLOW path observation: presence is the NODE ITSELF
# (a symlink node is present even when its target is not; the pinned
# inventory contains a live symlink row). size_bytes comes from the SAME
# lstat. Julia's lstat does not reliably throw on stat failures: it can
# return a StatStruct with ioerrno set, and ispath(st)==false for EVERY
# failure -- so the errno is classified EXPLICITLY: 0 = observed node;
# ENOENT/ENOTDIR = known absent; any other nonzero errno (e.g. EACCES)
# = observation_error with the code emitted, NEVER "absent". The
# try/catch remains for Julia versions/paths where lstat throws.
# For symlinks the link target text is recorded and target_resolves is
# a separate, EXPLICITLY-FOLLOWING diagnostic. statfn is injectable so
# fixtures can classify synthetic stat results deterministically.
function pcc_path_observation(path; statfn = lstat)
    st = try
        statfn(path)
    catch err
        return (observation_ok = false, node_present = false,
                node_type = "stat_error",
                stat_error_detail = first(sprint(showerror, err), 120),
                size_bytes = nothing, link_target = nothing,
                target_resolves = nothing)
    end
    errno = try Int(st.ioerrno) catch; 0 end
    if errno == Int(Base.UV_ENOENT) || errno == Int(Base.UV_ENOTDIR)
        return (observation_ok = true, node_present = false,
                node_type = "absent", stat_error_detail = nothing,
                size_bytes = nothing, link_target = nothing,
                target_resolves = nothing)
    elseif errno != 0
        return (observation_ok = false, node_present = false,
                node_type = "stat_error",
                stat_error_detail = "lstat ioerrno=$errno",
                size_bytes = nothing, link_target = nothing,
                target_resolves = nothing)
    end
    if islink(st)
        tgt = try readlink(path) catch; nothing end
        resolves = try isfile(path) || isdir(path) catch; false end
        return (observation_ok = true, node_present = true,
                node_type = "symlink", stat_error_detail = nothing,
                size_bytes = filesize(st),
                link_target = tgt, target_resolves = resolves)
    end
    return (observation_ok = true, node_present = true,
            node_type = isfile(st) ? "file" :
                        isdir(st) ? "directory" : "other",
            stat_error_detail = nothing,
            size_bytes = filesize(st),
            link_target = nothing, target_resolves = nothing)
end

# fail-closed pinned-source verification over an already-taken snapshot
function pcc_source_issues(snap, expected_case, expected_status,
                           expected_sha = nothing)
    issues = String[]
    snap.readable || (push!(issues, "source unreadable"); return issues)
    snap.parse_success || (push!(issues, "source unparseable");
                           return issues)
    snap.object_ok || (push!(issues, "source parses to a non-object");
                       return issues)
    pcc_str(get(snap.data, "case", "")) == expected_case ||
        push!(issues, "source case != $expected_case")
    pcc_str(get(snap.data, "status", "")) == expected_status ||
        push!(issues, "source status != $expected_status")
    # optional byte-sha pin: refuse drift when a source is pinned to an
    # exact committed artifact (same coupled snapshot supplies the sha)
    (expected_sha === nothing || snap.sha == expected_sha) ||
        push!(issues, "source sha drift (!= pinned $(expected_sha))")
    return issues
end

# fail-closed preflight inventory row schema: presence must be an
# explicit Bool and the path a nonempty string (never defaulted)
function pcc_inventory_row_issues(rows)
    issues = String[]
    rows isa AbstractVector ||
        return ["preflight inventory missing/non-vector"]
    isempty(rows) && push!(issues, "preflight inventory is empty")
    for (i, r0) in enumerate(rows)
        r = pcc_obj(r0)
        get(r, "present", nothing) isa Bool ||
            push!(issues, "inventory[$i] present missing/non-Bool")
        isempty(pcc_str(get(r, "path", ""))) &&
            push!(issues, "inventory[$i] path missing/empty")
    end
    return issues
end

# register Path-D scope extraction: the quota row's recorded byte scope
# must carry every verbatim needle before this census quotes it
function pcc_pathd_scope(regdata)
    for r0 in (get(regdata, "open_rulings", nothing) isa AbstractVector ?
               regdata["open_rulings"] : Any[])
        r = pcc_obj(r0)
        pcc_str(get(r, "id", "")) == "R-QUOTA-PATH-AD" || continue
        opts = pcc_obj(get(r, "options_from_source", nothing))
        scope = pcc_str(get(opts, "path_d_exact_byte_scope", ""))
        missing_needles = [n for n in PCC_PATHD_NEEDLES
                           if !occursin(n, scope)]
        return (scope = scope, missing_needles = missing_needles)
    end
    return (scope = "", missing_needles = copy(PCC_PATHD_NEEDLES))
end

# deterministic directory inventory bounded to the named root. The ROOT
# itself goes through the single-lstat observation first: a stat/
# permission failure is root_observation_ok=false (an error state), an
# absent root is present=false, and a NON-DIRECTORY root (file/symlink/
# other) is recorded by node type and never traversed -- none of these
# collapse into each other. Traversal: sorted recursive walk, symlinks
# NEVER followed (symlinked files AND directories counted, not
# traversed/dropped), traversal + size-read failures RECORDED. Existence
# and size only -- no content read, no integrity conclusion.
function pcc_dir_inventory(dir; statfn = lstat)
    obs = pcc_path_observation(dir; statfn = statfn)
    base = Dict{String, Any}("path" => dir,
        "root_observation_ok" => obs.observation_ok,
        "root_node_type" => obs.node_type,
        "present" => obs.observation_ok ? obs.node_present : nothing,
        "file_count" => 0, "total_bytes" => 0, "symlink_count" => 0,
        "traversal_errors" => String[],
        "size_read_failures" => String[])
    obs.stat_error_detail === nothing ||
        (base["root_error_detail"] = obs.stat_error_detail)
    (obs.observation_ok && obs.node_type == "directory") || return base
    n = 0
    bytes = 0
    nlink = 0
    errs = String[]
    szfail = String[]
    for (root, dirs, files) in walkdir(dir;
            follow_symlinks = false,
            onerror = e -> push!(errs, first(sprint(showerror, e), 120)))
        sort!(dirs)
        # symlinked DIRECTORIES are not descended (no-follow) but are
        # COUNTED, never silently dropped
        for d in dirs
            islink(joinpath(root, d)) && (nlink += 1)
        end
        for f in sort(files)
            p = joinpath(root, f)
            o = pcc_path_observation(p)
            if !o.observation_ok
                push!(szfail, p)
            elseif o.node_type == "symlink"
                nlink += 1
            else
                n += 1
                o.size_bytes === nothing ? push!(szfail, p) :
                    (bytes += o.size_bytes)
            end
        end
    end
    base["file_count"] = n
    base["total_bytes"] = bytes
    base["symlink_count"] = nlink
    base["traversal_errors"] = sort(errs)
    base["size_read_failures"] = sort(szfail)
    return base
end

# every error an inventory can carry, aggregated into the census
# findings count (root stat error + traversal errors + size failures +
# a reified readdir error if attached)
pcc_inventory_error_count(inv) =
    (get(inv, "root_observation_ok", true) == false ? 1 : 0) +
    length(get(inv, "traversal_errors", String[])) +
    length(get(inv, "size_read_failures", String[])) +
    (haskey(inv, "readdir_error") ? 1 : 0)

# findings = absence transitions OR observation errors; the neutral
# token covers both, and exit 0 stays confined to completed censuses
# (readiness explicitly absent/non-authorizing)
pcc_status(sources_ok, selftests_ok, n_findings) =
    !selftests_ok ? "post_cleanup_census_selftest_failed" :
    !sources_ok ? "post_cleanup_census_blocked_sources" :
    n_findings > 0 ?
        "post_cleanup_census_recorded_with_observation_findings" :
    "post_cleanup_census_recorded"

pcc_exit_code(status) =
    status in ("post_cleanup_census_recorded",
               "post_cleanup_census_recorded_with_observation_findings") ?
        0 : 1

# ---------------------------------------------------------------------------
# fixtures
# ---------------------------------------------------------------------------

function pcc_fixtures()
    t = Dict{String, Bool}()
    tdir = mktempdir()

    # coupled snapshot semantics (same proof shape as the intake's)
    cpf = joinpath(tdir, "coupled.json")
    write(cpf, "{\"v\": 1}")
    s1 = pcc_snapshot(cpf)
    write(cpf, "{\"v\": 22}")
    s2 = pcc_snapshot(cpf)
    t["byte_snapshot_couples_digest_and_content"] =
        s1.object_ok && s1.data["v"] == 1 && s2.data["v"] == 22 &&
        s1.sha != s2.sha
    t["missing_snapshot_unreadable"] =
        !pcc_snapshot(joinpath(tdir, "absent.json")).readable

    # transition matrix, exhaustively (neutral vocabulary only)
    t["transition_matrix_exact"] =
        pcc_transition(true, true) == "recorded_present_now_present" &&
        pcc_transition(true, false) == "recorded_present_now_absent" &&
        pcc_transition(false, false) == "recorded_absent_now_absent" &&
        pcc_transition(false, true) == "recorded_absent_now_present"

    # single-lstat path observation matrix: regular / absent / live
    # symlink / broken symlink via real lstat, plus DETERMINISTIC
    # synthetic-errno classification (EACCES-like and ENOENT) and a
    # throwing statfn -- the SAME helper production uses; a permission/
    # unknown stat failure is observation_error, NEVER absent
    t["path_observation_matrix"] = begin
        reg = joinpath(tdir, "obs_reg.bin"); write(reg, zeros(UInt8, 7))
        o1 = pcc_path_observation(reg)
        o2 = pcc_path_observation(joinpath(tdir, "obs_absent"))
        ln = joinpath(tdir, "obs_link"); symlink(reg, ln)
        o3 = pcc_path_observation(ln)
        bln = joinpath(tdir, "obs_broken")
        symlink(joinpath(tdir, "obs_gone"), bln)
        o4 = pcc_path_observation(bln)
        o1.observation_ok && o1.node_present &&
            o1.node_type == "file" && o1.size_bytes == 7 &&
            o2.observation_ok && !o2.node_present &&
            o2.node_type == "absent" &&
            o3.observation_ok && o3.node_present &&
            o3.node_type == "symlink" && o3.link_target == reg &&
            o3.target_resolves == true &&
            o4.observation_ok && o4.node_present &&
            o4.node_type == "symlink" && o4.target_resolves == false
    end
    t["stat_errno_classification_exact"] = begin
        # synthetic stat results exercise the errno classifier without
        # environment-sensitive permission manipulation
        oacc = pcc_path_observation("/synthetic";
            statfn = _ -> (ioerrno = Int(Base.UV_EACCES),))
        onoent = pcc_path_observation("/synthetic";
            statfn = _ -> (ioerrno = Int(Base.UV_ENOENT),))
        onotdir = pcc_path_observation("/synthetic";
            statfn = _ -> (ioerrno = Int(Base.UV_ENOTDIR),))
        othrow = pcc_path_observation("/synthetic";
            statfn = _ -> error("boom"))
        !oacc.observation_ok && oacc.node_type == "stat_error" &&
            !oacc.node_present &&
            occursin("ioerrno=$(Int(Base.UV_EACCES))",
                     oacc.stat_error_detail) &&
            onoent.observation_ok && !onoent.node_present &&
            onoent.node_type == "absent" &&
            onotdir.observation_ok && !onotdir.node_present &&
            !othrow.observation_ok && othrow.node_type == "stat_error" &&
            occursin("boom", othrow.stat_error_detail)
    end

    # source verification refusals over synthetic snapshots
    ok_snap = (readable = true, sha = "x", parse_success = true,
               object_ok = true,
               data = Dict("case" => "c1", "status" => "s1"))
    t["source_verification_accepts_exact"] =
        isempty(pcc_source_issues(ok_snap, "c1", "s1"))
    t["source_sha_pin_match_accepted"] =
        isempty(pcc_source_issues(ok_snap, "c1", "s1", ok_snap.sha))
    t["source_sha_drift_refused"] =
        any(occursin("sha drift", i)
            for i in pcc_source_issues(ok_snap, "c1", "s1", "0" ^ 64))
    t["source_wrong_case_refuses"] =
        any(occursin("case !=", i)
            for i in pcc_source_issues(ok_snap, "other", "s1"))
    t["source_wrong_status_refuses"] =
        any(occursin("status !=", i)
            for i in pcc_source_issues(ok_snap, "c1", "other"))
    bad_snap = (readable = true, sha = "x", parse_success = false,
                object_ok = false, data = nothing)
    t["source_unparseable_refuses"] =
        any(occursin("unparseable", i)
            for i in pcc_source_issues(bad_snap, "c1", "s1"))

    # inventory row schema guard
    t["inventory_schema_guard"] =
        any(occursin("present missing/non-Bool", i)
            for i in pcc_inventory_row_issues([Dict("path" => "/p")])) &&
        any(occursin("path missing/empty", i)
            for i in pcc_inventory_row_issues([Dict("present" => true)])) &&
        isempty(pcc_inventory_row_issues([Dict("present" => true,
                                               "path" => "/p")])) &&
        !isempty(pcc_inventory_row_issues("not-a-vector"))

    # Path-D scope needle guard
    t["pathd_needle_guard"] = begin
        goodreg = Dict("open_rulings" => [Dict("id" => "R-QUOTA-PATH-AD",
            "options_from_source" => Dict("path_d_exact_byte_scope" =>
                "delete idealized/{lw_spectra,sw_spectra} ONLY: 66 " *
                "files / 217,901,253,443 B; PRESERVE idealized/conc " *
                "and ALL of evaluation1/"))])
        badreg = Dict("open_rulings" => [Dict("id" => "R-QUOTA-PATH-AD",
            "options_from_source" => Dict("path_d_exact_byte_scope" =>
                "some other scope"))])
        isempty(pcc_pathd_scope(goodreg).missing_needles) &&
            !isempty(pcc_pathd_scope(badreg).missing_needles) &&
            length(pcc_pathd_scope(Dict()).missing_needles) ==
                length(PCC_PATHD_NEEDLES)
    end

    # deterministic directory inventory on a tmp tree: counts, bytes,
    # no-follow symlink counting, and recorded (not skipped) failures
    t["dir_inventory_counts_files_and_bytes"] = begin
        base = joinpath(tdir, "tree")
        mkpath(joinpath(base, "sub"))
        write(joinpath(base, "a.bin"), zeros(UInt8, 10))
        write(joinpath(base, "sub", "b.bin"), zeros(UInt8, 32))
        symlink(joinpath(base, "a.bin"), joinpath(base, "lnk.bin"))
        # symlinked DIRECTORY: counted, never descended or dropped
        symlink(joinpath(base, "sub"), joinpath(base, "lnkdir"))
        inv = pcc_dir_inventory(base)
        gone = pcc_dir_inventory(joinpath(tdir, "no-such-dir"))
        inv["present"] == true && inv["root_node_type"] == "directory" &&
            inv["root_observation_ok"] == true &&
            inv["file_count"] == 2 &&
            inv["total_bytes"] == 42 && inv["symlink_count"] == 2 &&
            inv["traversal_errors"] == String[] &&
            inv["size_read_failures"] == String[] &&
            gone["present"] == false &&
            gone["root_node_type"] == "absent" &&
            gone["file_count"] == 0 && haskey(gone, "traversal_errors")
    end
    # roots that are not traversable directories stay DISTINCT: wrong
    # node type (a file) is present-but-untraversed; an injected stat
    # failure is root_observation_ok=false; and the error-count helper
    # aggregates root/traversal/size/readdir failures
    t["dir_inventory_root_distinctions"] = begin
        froot = joinpath(tdir, "not_a_dir.bin"); write(froot, [0x01])
        wrong = pcc_dir_inventory(froot)
        errinv = pcc_dir_inventory(joinpath(tdir, "whatever");
                                   statfn = _ -> error("boom"))
        wrong["present"] == true && wrong["root_node_type"] == "file" &&
            wrong["file_count"] == 0 &&
            errinv["root_observation_ok"] == false &&
            errinv["root_node_type"] == "stat_error" &&
            errinv["present"] === nothing &&
            pcc_inventory_error_count(errinv) == 1 &&
            pcc_inventory_error_count(wrong) == 0 &&
            pcc_inventory_error_count(Dict("root_observation_ok" => true,
                "traversal_errors" => ["x"],
                "size_read_failures" => ["y", "z"],
                "readdir_error" => "e")) == 4
    end

    # status/exit selection: exit 0 is confined to completed censuses
    # (readiness explicitly absent/non-authorizing); blocked/selftest
    # remain nonzero
    t["status_and_exit_selection"] =
        pcc_status(true, true, 0) == "post_cleanup_census_recorded" &&
        pcc_status(true, true, 2) ==
            "post_cleanup_census_recorded_with_observation_findings" &&
        pcc_status(false, true, 0) ==
            "post_cleanup_census_blocked_sources" &&
        pcc_status(true, false, 0) ==
            "post_cleanup_census_selftest_failed" &&
        pcc_status(false, false, 1) ==
            "post_cleanup_census_selftest_failed" &&
        pcc_exit_code("post_cleanup_census_recorded") == 0 &&
        pcc_exit_code(
            "post_cleanup_census_recorded_with_observation_findings") == 0 &&
        pcc_exit_code("post_cleanup_census_blocked_sources") == 1 &&
        pcc_exit_code("post_cleanup_census_selftest_failed") == 1

    rm(tdir, recursive = true, force = true)
    return t
end

# ---------------------------------------------------------------------------
# emission
# ---------------------------------------------------------------------------

function pcc_stable_json(x)
    if x isa AbstractDict
        inner = join(["$(JSON.json(String(k))): $(pcc_stable_json(x[k]))"
                      for k in sort(collect(keys(x)); by = String)], ", ")
        return "{" * inner * "}"
    elseif x isa AbstractVector
        return "[" * join([pcc_stable_json(v) for v in x], ", ") * "]"
    else
        return JSON.json(x)
    end
end

# atomic replacement: unique same-directory temp + rename (prevents
# truncation/partial replacement; a crash before rename preserves the
# previous complete artifact; successful completion publishes this run)
function pcc_atomic_write(path, content)
    tmp = path * ".tmp-$(getpid())"
    open(tmp, "w") do io
        write(io, content)
    end
    Base.Filesystem.rename(tmp, path)
end

function pcc_main()
    fails = String[]
    gates = Dict{String, String}()

    t = pcc_fixtures()
    selftests_ok = all(values(t))
    gates["fixtures"] = selftests_ok ? "passed" : "failed"
    selftests_ok || push!(fails, "fixtures failed: " *
        join(sort([k for (k, v) in t if !v]), ", "))

    # pinned sources, each via ONE coupled byte snapshot
    src = Dict{String, Any}()
    sources_ok = true
    snaps = Dict{String, Any}()
    for (label, path, ecase, estatus, esha) in (
        ("scoped_preflight", PCC_PREFLIGHT_JSON,
         "gate4_g3_scoped_input_preflight",
         "g3_scoped_preflight_ready", PCC_PREFLIGHT_SHA),
        ("g2c_fetch_checkpoint", PCC_G2C_JSON,
         "gate4_g2c_eval2_fetch_checkpoint",
         "g2c_checkpoint_ready", nothing),
        ("pending_rulings_register", PCC_REGISTER_JSON,
         "gate4_pending_rulings_register",
         "pending_rulings_register_recorded", nothing))
        snap = pcc_snapshot(path)
        issues = pcc_source_issues(snap, ecase, estatus, esha)
        isempty(issues) || (sources_ok = false;
                            append!(fails, ["$label: " * i
                                            for i in issues]))
        snaps[label] = snap
        src[label] = Dict("path" => path,
            "snapshot_sha256" => snap.sha,
            "expected_sha256" => esha,   # nothing for unpinned sources
            "verified_case" => ecase, "verified_status" => estatus,
            "verified" => isempty(issues))
    end
    gates["pinned_sources_verified"] = sources_ok ? "passed" : "failed"

    # preflight inventory re-stat (existence + size only)
    census_rows = Any[]
    n_rpna = 0
    n_obserr = 0
    counts = Dict("recorded_present_now_present" => 0,
                  "recorded_present_now_absent" => 0,
                  "recorded_absent_now_absent" => 0,
                  "recorded_absent_now_present" => 0,
                  "observation_error" => 0)
    pathd_scope = (scope = "", missing_needles = PCC_PATHD_NEEDLES)
    if sources_ok
        inv = get(snaps["scoped_preflight"].data, "inventory", nothing)
        inv_issues = pcc_inventory_row_issues(inv)
        if !isempty(inv_issues)
            sources_ok = false
            append!(fails, inv_issues)
            gates["pinned_sources_verified"] = "failed"
        else
            for r0 in inv
                r = pcc_obj(r0)
                p = pcc_str(r["path"])
                rec = r["present"]
                # single lstat, no-follow: presence is the NODE itself;
                # a stat/permission failure is observation_error, NEVER
                # now_absent
                o = pcc_path_observation(p)
                cls = o.observation_ok ?
                    pcc_transition(rec, o.node_present) :
                    "observation_error"
                counts[cls] += 1
                cls == "recorded_present_now_absent" && (n_rpna += 1)
                cls == "observation_error" && (n_obserr += 1)
                row = Dict{String, Any}(
                    "input" => pcc_str(get(r, "input", "")),
                    "path" => p,
                    "recorded_present" => rec,
                    "observation_ok" => o.observation_ok,
                    "now_present" => o.observation_ok ?
                        o.node_present : nothing,
                    "node_type" => o.node_type,
                    "class" => cls)
                o.size_bytes === nothing ||
                    (row["observed_size_bytes"] = o.size_bytes)
                o.stat_error_detail === nothing ||
                    (row["stat_error_detail"] = o.stat_error_detail)
                if o.node_type == "symlink"
                    row["link_target"] = o.link_target
                    row["target_resolves_following_diagnostic"] =
                        o.target_resolves
                end
                push!(census_rows, row)
            end
        end
        scope = pcc_pathd_scope(snaps["pending_rulings_register"].data)
        pathd_scope = scope
        isempty(scope.missing_needles) ||
            (sources_ok = false;
             gates["pinned_sources_verified"] = "failed";
             push!(fails, "register Path-D scope missing verbatim " *
                          "needles: $(scope.missing_needles)"))
    end
    # directory-level facts bounded to the exact named roots; every root
    # goes through the single-lstat observation (absent, wrong node
    # type, and stat error stay distinct), readdir failures are reified,
    # and NO immediate entry is silently skipped
    pathd_dirs = [merge(pcc_dir_inventory(d),
                        Dict("registered_scope_claim" =>
                             "listed in the register's RECORDED Path-D " *
                             "deletion wording (a claim recorded at " *
                             "register time, not a statement of " *
                             "current authorization)"))
                  for d in PCC_PATH_D_DIRS]
    conc_inv = merge(pcc_dir_inventory(PCC_PRESERVE_DIRS[1]),
                     Dict("registered_scope_claim" =>
                          "named in the register's RECORDED PRESERVE " *
                          "wording"))
    eval1_root = PCC_PRESERVE_DIRS[2]
    eval1_root_obs = pcc_path_observation(eval1_root)
    eval1_root_fact = Dict{String, Any}(
        "path" => eval1_root,
        "root_observation_ok" => eval1_root_obs.observation_ok,
        "root_node_type" => eval1_root_obs.node_type,
        "present" => eval1_root_obs.observation_ok ?
            eval1_root_obs.node_present : nothing)
    eval1_root_obs.stat_error_detail === nothing ||
        (eval1_root_fact["root_error_detail"] =
             eval1_root_obs.stat_error_detail)
    eval1_entries = Any[]
    if eval1_root_obs.observation_ok &&
       eval1_root_obs.node_type == "directory"
        names = try
            sort(readdir(eval1_root))
        catch err
            eval1_root_fact["readdir_error"] =
                first(sprint(showerror, err), 120)
            nothing
        end
        if names !== nothing
            for name in names
                p = joinpath(eval1_root, name)
                o = pcc_path_observation(p)
                entry = Dict{String, Any}("name" => name,
                    "observation_ok" => o.observation_ok,
                    "node_type" => o.node_type)
                o.stat_error_detail === nothing ||
                    (entry["stat_error_detail"] = o.stat_error_detail)
                if o.observation_ok && o.node_type == "directory"
                    entry["inventory"] = pcc_dir_inventory(p)
                elseif o.node_type == "symlink"
                    entry["link_target"] = o.link_target
                    entry["target_resolves_following_diagnostic"] =
                        o.target_resolves
                elseif o.size_bytes !== nothing
                    entry["observed_size_bytes"] = o.size_bytes
                end
                push!(eval1_entries, entry)
            end
        end
    end
    # aggregate EVERY observation-error class into the findings count:
    # pinned rows + root observations + traversal/readdir/size failures
    for inv in vcat(pathd_dirs, [conc_inv, eval1_root_fact])
        n_obserr += pcc_inventory_error_count(inv)
    end
    for e in eval1_entries
        e["observation_ok"] || (n_obserr += 1)
        haskey(e, "inventory") &&
            (n_obserr += pcc_inventory_error_count(e["inventory"]))
    end

    gates["no_recorded_present_now_absent"] =
        sources_ok && n_rpna == 0 ? "passed" : "failed"
    n_rpna > 0 && push!(fails,
        "$n_rpna paths recorded present in the pinned preflight are " *
        "now absent: " *
        join([r["path"] for r in census_rows
              if r["class"] == "recorded_present_now_absent"], ", "))
    gates["no_observation_errors"] =
        sources_ok && n_obserr == 0 ? "passed" : "failed"
    n_obserr > 0 && push!(fails,
        "$n_obserr observation errors across pinned rows, named roots, " *
        "and traversals (stat/permission/readdir/size failures -- " *
        "unknown states, never reported as absence)")
    eval1_note = "registered_scope_claim_vs_observation: the register's " *
        "RECORDED wording names idealized/conc and ALL of evaluation1/ " *
        "in its PRESERVE clause; the live subdir set above is the " *
        "observation. Both sides are facts about recorded text and " *
        "current existence -- neither is a statement of current " *
        "authorization, and this unit makes no claim about who removed " *
        "anything or under what approval"

    status = pcc_status(sources_ok, selftests_ok, n_rpna + n_obserr)
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    # fully anchored UTC evidence: terminal Z appended (Dates.now(UTC)
    # stringifies without a timezone designator)
    nowstamp = string(Dates.now(Dates.UTC)) * "Z"
    result = Dict(
        "case" => "gate4_post_cleanup_input_census",
        "data_mode" => "read_only_observed_at_census",
        "status" => status,
        "timestamp_utc" => nowstamp,
        "observed_at_utc" => nowstamp,
        "observation_semantics" => "for LIVE SCIENTIFIC INPUT census " *
            "rows: existence and size at observed_at only -- their " *
            "content is never read or hashed by this unit and no " *
            "content-integrity conclusion is drawn about them. Pinned " *
            "SOURCE JSON artifacts are different: their bytes ARE read " *
            "and sha256-hashed (coupled snapshots), and the scoped " *
            "preflight artifact is additionally verified against an " *
            "exact pinned sha",
        "readiness" => Dict(
            "conferred" => false,
            "note" => "this census confers NO readiness and authorizes " *
                "NOTHING; downstream must inspect the status token and " *
                "payload, never the exit code alone"),
        "gates" => gates, "failures" => fails,
        "fixture_verdicts" => t,
        "sources" => src,
        "source_verification_semantics" => "ALL pinned source " *
            "artifacts get exact case/status verification; the " *
            "scoped_preflight source ADDITIONALLY gets exact " *
            "coupled-byte sha256 verification against " *
            "PCC_PREFLIGHT_SHA. This authenticates the captured " *
            "artifacts' role and recorded baseline (e.g. the G2c " *
            "checkpoint recorded g2c_checkpoint_ready at its own write " *
            "time); it is NOT an assertion of current source " *
            "availability or quota state -- this unit intentionally " *
            "performs no live probe or quota read",
        "preflight_census" => Dict(
            "rows" => census_rows,
            "counts" => counts,
            "hash_reverification" => "scientific files are NOT rehashed " *
                "by this census (stated bound): the preflight " *
                "inventory's recorded observed hashes and " *
                "sha256_matches verdicts are consumed as-is. Source " *
                "JSON artifacts are byte-read and sha256-HASHED via " *
                "coupled snapshots; scoped_preflight is ADDITIONALLY " *
                "checked against its exact pin (G2c/register snapshots " *
                "are hashed but carry no digest pin)"),
        "registered_scope_claim_vs_observation" => Dict(
            "register_quote_recorded_wording" => pathd_scope.scope,
            "scope_dirs_observed" => pathd_dirs,
            "idealized_conc" => conc_inv,
            "evaluation1_root" => eval1_root_fact,
            "evaluation1_immediate_entries" => eval1_entries,
            "note" => eval1_note),
        "determinism_note" => "no quota/lfs reads (nondeterministic); " *
            "sorted walks bounded to named roots; symlinks never " *
            "followed; coupled byte snapshots for pinned sources; " *
            "double-run compared with timestamp_utc/observed_at_utc " *
            "stripped",
        "provenance" => Dict("branch" => branch,
            "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working " *
                "tree before its own commit"),
        "disclaimer" => "read-only observed-at census; neutral facts " *
            "only -- no election, no ruling/intake change, no " *
            "authorization or attribution claim, no content-integrity " *
            "conclusion about live scientific inputs (pinned source " *
            "JSON artifacts are byte-hashed as disclosed above), no " *
            "deletion/creation outside its own artifacts, no " *
            "job/quota/fetch action.")

    mkpath(dirname(PCC_RESULTS_JSON))
    jbuf = IOBuffer(); JSON.print(jbuf, result, 2)
    pcc_atomic_write(PCC_RESULTS_JSON, String(take!(jbuf)))
    mbuf = IOBuffer()
    println(mbuf, "# Gate-4 post-cleanup input census\n")
    println(mbuf, "Status: **$status**\n")
    println(mbuf, result["disclaimer"], "\n")
    println(mbuf, "| Gate | Verdict |")
    println(mbuf, "|---|---|")
    for k in sort(collect(keys(gates)))
        println(mbuf, "| $k | $(gates[k]) |")
    end
    println(mbuf, "\n## Preflight inventory re-stat " *
                  "($(length(census_rows)) rows)\n")
    println(mbuf, "Counts: " * pcc_stable_json(counts) * "\n")
    for r in census_rows
        r["class"] == "recorded_present_now_present" && continue
        println(mbuf, "- [$(r["class"])] $(r["input"]): `$(r["path"])`")
    end
    println(mbuf, "\n(recorded_present_now_present rows omitted above " *
                  "for brevity; all rows are in the JSON.)")
    println(mbuf, "\n## Registered scope claim vs observation\n")
    println(mbuf, "Register RECORDED wording (a claim recorded at " *
                  "register time, not a statement of current " *
                  "authorization): " * JSON.json(pathd_scope.scope) * "\n")
    for d in pathd_dirs
        println(mbuf, "- `$(d["path"])`: present=$(d["present"]) " *
                      "files=$(d["file_count"]) bytes=$(d["total_bytes"])")
    end
    println(mbuf, "- `$(conc_inv["path"])`: present=$(conc_inv["present"]) " *
                  "files=$(conc_inv["file_count"]) " *
                  "bytes=$(conc_inv["total_bytes"])")
    println(mbuf, "- `$(eval1_root_fact["path"])` (root): " *
                  "present=$(eval1_root_fact["present"]) " *
                  "node_type=$(eval1_root_fact["root_node_type"])")
    for e in eval1_entries
        if haskey(e, "inventory")
            inv = e["inventory"]
            println(mbuf, "  - `$(e["name"])` [$(e["node_type"])]: " *
                          "files=$(inv["file_count"]) " *
                          "bytes=$(inv["total_bytes"])")
        else
            println(mbuf, "  - `$(e["name"])` [$(e["node_type"])]" *
                          (haskey(e, "observed_size_bytes") ?
                           ": bytes=$(e["observed_size_bytes"])" : ""))
        end
    end
    println(mbuf, "\n", eval1_note)
    isempty(fails) || (println(mbuf, "\n## Failures\n");
                       foreach(f -> println(mbuf, "- ", f), fails))
    println(mbuf, "\nProvenance: branch `$branch`, generated_from_head " *
                  "`$head` (pre-own-commit).")
    pcc_atomic_write(PCC_RESULTS_MD, String(take!(mbuf)))

    println("gate4_post_cleanup_input_census: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    println("  counts: " * pcc_stable_json(counts))
    isempty(fails) || foreach(f -> println("  FAIL: $f"), first(fails, 8))
    return pcc_exit_code(status)
end

exit(pcc_main())
