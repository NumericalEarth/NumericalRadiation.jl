# Gate-4 RULINGS INTAKE CONTRACT (derivative, fail-closed; no election,
# no inferred authority, no authorization).
#
# Purpose (monitor-directed, 2026-08-12): the deterministic intake
# mechanism for the 9 open campaign rulings recorded in the pending-
# rulings register. A human authority resolves rulings by authoring
# validation/gate4_rulings_assignment.json OUT OF BAND (this unit NEVER
# writes that file); this unit validates it fail-closed against the
# register and emits ONE canonical current-state artifact that always
# reflects THIS run:
#   - assignment absent + register healthy -> awaiting (exit 0)
#   - assignment valid                     -> recorded (exit 0)
#   - assignment present but invalid       -> refused (exit 1)
#   - register identity/sources stale      -> blocked_register_stale (exit 1)
# The canonical artifact is replaced ATOMICALLY (unique same-directory
# temp + rename) by every run that completes emission -- a crash or
# write failure leaves the previous artifact intact, never truncated --
# so downstream can never consume a torn artifact, and a completed run
# after source removal/corruption always demotes yesterday's valid
# output. Current-state hashes are nonthrowing single snapshots: a
# source vanishing mid-run (TOCTOU) is CLASSIFIED stale/refused rather
# than crashing before replacement. Prior valid decisions are preserved
# ONLY as an embedded last_valid_intake block explicitly marked
# historical_non_authorizing -- never as the active status.
#
# Authority (never inferred): the 8 UNASSIGNED rows in the register
# REFUSE any assignment -- they remain OPEN until a source-proven
# authority assignment updates the register (which this unit's register-
# consistency check then flags, forcing a deliberate intake revision).
# Only R-QUOTA-PATH-AD has a source-proven authority (Greg, per the
# runbook sentence quoted verbatim below); its assignment requires
# decided_by == "Greg" plus independently reviewable evidence provenance
# {kind, locator, quote[, sha256]}. That is STRUCTURAL ATTRIBUTION, NOT
# AUTHENTICATION: this unit cannot prove Greg authored the evidence
# absent a trusted signature/channel, never calls a recorded ruling
# execution-authorized, and never emits an authorization token (the
# quota domain state on resolution is
# ruling_recorded_execution_unauthorized).
#
# Options (never canonicalized from prose): a decision vocabulary is
# machine-enumerated ONLY where the option IDs are literal keys of the
# register's options_from_source object, exact-set-asserted against the
# live register: R-QUOTA-PATH-AD {path_a, path_d_exact_byte_scope} and
# R-G2-D3 {variant_pair_selection, variant_eps_clamping}. Every other
# row (D1, D2, D4, AX1-4) is unenumerated and REFUSES resolution until a
# source provides exact option IDs.
#
# Recording a ruling never authorizes execution: deletion, quota change,
# and job submission remain UNAUTHORIZED regardless of intake state; the
# quota path executes only under the runbook's own protocol.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON
import SHA

const RIC_RESULTS_JSON =
    validation_results_path("gate4_rulings_intake_contract.json")
const RIC_RESULTS_MD =
    validation_results_path("gate4_rulings_intake_contract.md")
const RIC_REGISTER_JSON =
    validation_results_path("gate4_pending_rulings_register.json")
# authoritative human-authored input; lives in validation/, NOT results;
# never written by any unit
const RIC_ASSIGNMENT_PATH = joinpath(@__DIR__, "gate4_rulings_assignment.json")

ric_obj(x) = x isa AbstractDict ? x : Dict{String, Any}()
ric_str(x) = x isa AbstractString ? String(x) : ""
ric_sha(p) = split(strip(read(`sha256sum $p`, String)))[1]
# nonthrowing current-state hash: a file vanishing/changing between the
# existence check and the hash (TOCTOU) must be CLASSIFIED fail-closed
# (stale/refused), never crash the run before canonical replacement
ric_try_sha(p) = try
    split(strip(read(`sha256sum $p`, String)))[1]
catch
    nothing
end

const RIC_EXPECTED_CASE = "gate4_pending_rulings_register"
const RIC_EXPECTED_STATUS = "pending_rulings_register_recorded"
const RIC_EXPECTED_IDS = ["R-G2-D1", "R-G2-D2", "R-G2-D3", "R-G2-D4",
                          "R-T45-AX1", "R-T45-AX2", "R-T45-AX3",
                          "R-T45-AX4", "R-QUOTA-PATH-AD"]

# copied VERBATIM from gate4_pending_rulings_register.jl (that unit ends
# in exit(reg_main()) and must never be include()d): the ONLY
# non-UNASSIGNED authority form the register can carry
const RIC_AUTHORITY_SENTENCE = "No `rm`, no quota change, and no job " *
    "submission may be run from this document without Greg's explicit " *
    "authorization of the chosen path."
const RIC_GREG_AUTHORITY = "Greg -- explicitly assigned by the runbook: " *
    "'" * RIC_AUTHORITY_SENTENCE * "'"

# machine-enumerated decision vocabularies: option IDs are LITERAL keys
# of the register row's options_from_source object; the exact full key
# set is asserted against the live register so drift refuses. All other
# rows are unenumerated and refuse resolution.
const RIC_ENUMERATIONS = Dict(
    "R-QUOTA-PATH-AD" => (option_ids = ["path_a", "path_d_exact_byte_scope"],
                          exact_source_keys = ["path_a",
                                               "path_d_exact_byte_scope"]),
    "R-G2-D3" => (option_ids = ["variant_eps_clamping",
                                "variant_pair_selection"],
                  exact_source_keys = ["invariant", "variant_eps_clamping",
                                       "variant_pair_selection"]))

# monitor-directed derived equivalence (2026-08-12), NOT an election: the
# two source-described AX2 reporting forms are verdict-equivalent
const RIC_AX2_EQUIVALENCE_NOTE = "derived equivalence (not an election): " *
    "the conjunction (d_toa <= m && d_surface <= m) is mathematically " *
    "equivalent to max(d_toa, d_surface) <= m when the same margin and " *
    "the same signed/absolute transform apply; both source-described " *
    "reporting forms are preserved and marked verdict-equivalent -- they " *
    "cannot change pass/fail absent a different threshold/transform"

const RIC_NON_AUTHORIZING = "recording a ruling does NOT itself " *
    "authorize any action: deletion, quota change, and job submission " *
    "remain UNAUTHORIZED; the quota path executes only under the " *
    "runbook's own protocol"

# fully anchored UTC shape: prefix-only matching would accept trailing
# garbage, and *_at_utc field names require the terminal Z (an offset or
# zoneless timestamp is not UTC)
const RIC_ISO_RE = r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$"
const RIC_HEX64_RE = r"^[0-9a-f]{64}$"

# the register must pin EXACTLY these five sources at these EXACT
# normalized full paths (basename-only matching would permit a
# substituted file elsewhere); a tampered same-shaped register supplying
# a different list refuses before any re-hash, and the sha re-hash then
# subsumes per-source case/status drift
const RIC_EXPECTED_SOURCE_PATHS = sort(normpath.([
    validation_results_path("gate4_g2_binding_decision_scaffold.json"),
    joinpath(@__DIR__, "gate4_regression_margin_semantics_evidence.md"),
    validation_results_path("gate4_g2c_eval2_fetch_checkpoint.json"),
    validation_results_path("gate4_g2c_failure_ledger_4440.json"),
    joinpath(@__DIR__, "gate4_g2c_quota_recovery_runbook.md")]))

# the unit's SINGLE literal JSON parse site (dependency-audit censused;
# serves the register edge and the authority-input edge; the same helper
# also re-reads the unit's own previous artifact and fixture tmp files).
# NONTHROWING BYTE SNAPSHOT: one read(path) supplies BOTH the SHA-256
# digest and the parsed content, so a mid-run file replacement can never
# pair bytes B's decisions with bytes A's digest. JSON null/arrays PARSE
# successfully but are not objects; the distinction is never collapsed.
function ric_snapshot(path)
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
# PURE validators (used identically in production and fixtures)
# ---------------------------------------------------------------------------

# register model consistency: exact identity, exact 9-ID set, all rows
# OPEN, exact authority forms, exact enumeration key sets
function ric_register_issues(reg)
    issues = String[]
    ric_str(get(reg, "case", "")) == RIC_EXPECTED_CASE ||
        push!(issues, "register case != $RIC_EXPECTED_CASE")
    ric_str(get(reg, "status", "")) == RIC_EXPECTED_STATUS ||
        push!(issues, "register status != $RIC_EXPECTED_STATUS")
    rows = get(reg, "open_rulings", nothing)
    rows isa AbstractVector ||
        (push!(issues, "register open_rulings missing/non-vector");
         return issues)
    byid = Dict{String, Any}()
    for r in rows
        d = ric_obj(r)
        byid[ric_str(get(d, "id", ""))] = d
    end
    ids = sort(collect(keys(byid)))
    if ids != sort(RIC_EXPECTED_IDS) || length(rows) != length(RIC_EXPECTED_IDS)
        push!(issues, "register ruling-ID set $ids != the exact expected " *
                      "9-ID set (a source-proven register change requires " *
                      "a deliberate intake revision)")
        return issues
    end
    for id in RIC_EXPECTED_IDS
        d = byid[id]
        ric_str(get(d, "status", "")) == "OPEN" ||
            push!(issues, "register row $id status != OPEN")
        auth = ric_str(get(d, "deciding_authority", ""))
        if id == "R-QUOTA-PATH-AD"
            auth == RIC_GREG_AUTHORITY ||
                push!(issues, "register row $id authority is not the " *
                              "exact source-verified Greg form")
        else
            auth == "UNASSIGNED" ||
                push!(issues, "register row $id authority != UNASSIGNED " *
                              "(a source-proven authority assignment " *
                              "requires a deliberate intake revision)")
        end
        if haskey(RIC_ENUMERATIONS, id)
            en = RIC_ENUMERATIONS[id]
            opts = get(d, "options_from_source", nothing)
            got = opts isa AbstractDict ?
                sort([String(k) for k in keys(opts)]) : String[]
            got == sort(en.exact_source_keys) ||
                push!(issues, "register row $id options_from_source key " *
                              "set $got != exact expected " *
                              "$(sort(en.exact_source_keys)) -- " *
                              "enumeration no longer source-anchored")
        end
    end
    return issues
end

# exact pinned-source SET: the register must record exactly the five
# known sources at their exact normalized full paths -- a same-shaped
# register carrying a different list (including a same-basename file in
# another directory) never reaches the re-hash
function ric_source_set_issues(sources)
    sources isa AbstractVector ||
        return ["register sources missing/non-vector"]
    got = sort([normpath(ric_str(get(ric_obj(s), "path", "")))
                for s in sources])
    got == RIC_EXPECTED_SOURCE_PATHS && return String[]
    return ["register pinned-source path set $got != the exact expected " *
            "five normalized full paths $(RIC_EXPECTED_SOURCE_PATHS)"]
end

# live re-hash of every source the register pinned: any missing file or
# sha drift makes the whole decision surface stale (the hash subsumes
# per-source case/status drift)
function ric_source_staleness(sources)
    stale = String[]
    sources isa AbstractVector ||
        return ["register sources missing/non-vector"]
    for s in sources
        d = ric_obj(s)
        p = ric_str(get(d, "path", ""))
        rec = ric_str(get(d, "sha256", ""))
        h = ric_try_sha(p)
        if h === nothing
            push!(stale, "pinned source missing or unreadable at hash " *
                         "time: $p")
        elseif h != rec
            push!(stale, "pinned source sha drifted: $p")
        end
    end
    return stale
end

# pure classification of the present-but-unhashable snapshot race: the
# input existed at the presence check but could not be hashed -- refused
ric_snapshot_issue(present, sha) =
    present && sha === nothing ?
        ["assignment file unreadable at hash time (snapshot " *
         "inconsistency) -- refused"] : String[]

const RIC_TOP_REQUIRED = ["schema", "authored_by", "authored_at_utc",
                          "register_pin", "rulings"]
const RIC_TOP_ALLOWED = vcat(RIC_TOP_REQUIRED, ["note"])
const RIC_PIN_KEYS = sort(["case", "status", "sha256"])
# exact 9-ID input coverage: every register ID appears exactly once with
# an explicit state, so an accidental omission can never silently read
# as OPEN. OPEN rows FORBID resolution fields; RESOLVED rows require them.
const RIC_ROW_OPEN_ALLOWED = ["ruling_id", "state"]
const RIC_ROW_RESOLVED_REQUIRED = ["ruling_id", "state", "decision",
                                   "decided_by", "decided_at_utc",
                                   "evidence"]
const RIC_ROW_RESOLVED_ALLOWED = vcat(RIC_ROW_RESOLVED_REQUIRED, ["notes"])
const RIC_EVIDENCE_REQUIRED = ["kind", "locator", "quote"]
const RIC_EVIDENCE_ALLOWED = vcat(RIC_EVIDENCE_REQUIRED, ["sha256"])

# fail-closed rulings-file validation against the verified register
# model; returns the full refusal list (empty == valid). regmodel maps
# id => register row; live_register_sha is the recomputed hash of the
# register artifact this run.
function ric_assignment_issues(data, regmodel, live_register_sha)
    issues = String[]
    data isa AbstractDict ||
        return ["rulings file parses to a non-object (JSON null/array/" *
                "scalar) -- refused"]
    for k in keys(data)
        String(k) in RIC_TOP_ALLOWED ||
            push!(issues, "unknown top-level key $(String(k)) -- exact-key " *
                          "discipline refuses smuggled fields")
    end
    for k in RIC_TOP_REQUIRED
        haskey(data, k) || push!(issues, "missing top-level key $k")
    end
    ric_str(get(data, "schema", "")) == "gate4_rulings_assignment_v1" ||
        push!(issues, "schema != gate4_rulings_assignment_v1")
    isempty(ric_str(get(data, "authored_by", ""))) &&
        push!(issues, "authored_by missing/empty (authorship is out of " *
                      "band; the field is still structurally required)")
    occursin(RIC_ISO_RE, ric_str(get(data, "authored_at_utc", ""))) ||
        push!(issues, "authored_at_utc not fully anchored UTC ISO-8601 " *
                      "(terminal Z required)")
    pin0 = get(data, "register_pin", nothing)
    if !(pin0 isa AbstractDict)
        push!(issues, "register_pin missing/non-object")
    else
        sort([String(k) for k in keys(pin0)]) == RIC_PIN_KEYS ||
            push!(issues, "register_pin key set != exact " *
                          "{case, status, sha256}")
        ric_str(get(pin0, "case", "")) == RIC_EXPECTED_CASE ||
            push!(issues, "register_pin.case mismatch")
        ric_str(get(pin0, "status", "")) == RIC_EXPECTED_STATUS ||
            push!(issues, "register_pin.status mismatch")
        ric_str(get(pin0, "sha256", "")) == live_register_sha ||
            push!(issues, "register_pin.sha256 does not match the live " *
                          "register artifact -- STALE PIN; re-author " *
                          "against the current register")
    end
    rows = get(data, "rulings", nothing)
    if !(rows isa AbstractVector)
        push!(issues, "rulings missing/non-vector")
        return issues
    end
    seen = String[]
    for (i, r0) in enumerate(rows)
        r = r0 isa AbstractDict ? r0 : nothing
        if r === nothing
            push!(issues, "rulings[$i] is not an object")
            continue
        end
        id = ric_str(get(r, "ruling_id", ""))
        if !(id in RIC_EXPECTED_IDS)
            push!(issues, "rulings[$i] unknown ruling_id $id")
            continue
        end
        id in seen && push!(issues, "duplicate row for $id")
        push!(seen, id)
        st = ric_str(get(r, "state", ""))
        if st == "OPEN"
            for k in keys(r)
                String(k) in RIC_ROW_OPEN_ALLOWED ||
                    push!(issues, "OPEN row $id forbids key $(String(k)) " *
                                  "-- an OPEN row carries ONLY " *
                                  "ruling_id+state")
            end
            continue
        elseif st != "RESOLVED"
            push!(issues, "row $id state $st not in {OPEN, RESOLVED}")
            continue
        end
        for k in keys(r)
            String(k) in RIC_ROW_RESOLVED_ALLOWED ||
                push!(issues, "RESOLVED row $id unknown key $(String(k)) " *
                              "-- exact-key discipline refuses smuggled " *
                              "fields")
        end
        for k in RIC_ROW_RESOLVED_REQUIRED
            haskey(r, k) || push!(issues, "RESOLVED row $id missing key $k")
        end
        isempty(ric_str(get(r, "decision", ""))) &&
            push!(issues, "RESOLVED row $id decision missing/empty")
        occursin(RIC_ISO_RE, ric_str(get(r, "decided_at_utc", ""))) ||
            push!(issues, "RESOLVED row $id decided_at_utc not fully " *
                          "anchored UTC ISO-8601 (terminal Z required)")
        # evidence must be independently reviewable/pinnable provenance
        # (structural attribution, not authentication): source kind,
        # locator/conversation record, exact quote; optional 64-hex digest
        ev = get(r, "evidence", nothing)
        if !(ev isa AbstractDict)
            push!(issues, "RESOLVED row $id evidence must be an object " *
                          "{kind, locator, quote[, sha256]} -- a ruling " *
                          "needs independently reviewable provenance, " *
                          "never an agent-authored choice")
        else
            for k in keys(ev)
                String(k) in RIC_EVIDENCE_ALLOWED ||
                    push!(issues, "RESOLVED row $id evidence unknown key " *
                                  "$(String(k))")
            end
            for k in RIC_EVIDENCE_REQUIRED
                isempty(ric_str(get(ev, k, ""))) &&
                    push!(issues, "RESOLVED row $id evidence.$k " *
                                  "missing/empty")
            end
            haskey(ev, "sha256") &&
                !occursin(RIC_HEX64_RE, ric_str(ev["sha256"])) &&
                push!(issues, "RESOLVED row $id evidence.sha256 not 64-hex")
        end
        # authority gate FIRST (never inferred)
        auth = ric_str(get(ric_obj(get(regmodel, id, nothing)),
                           "deciding_authority", ""))
        if auth == "UNASSIGNED"
            push!(issues, "RESOLVED row $id refused: register authority " *
                          "is UNASSIGNED -- the row remains OPEN until a " *
                          "source-proven authority assignment updates " *
                          "the register")
            continue
        elseif auth == RIC_GREG_AUTHORITY
            ric_str(get(r, "decided_by", "")) == "Greg" ||
                push!(issues, "RESOLVED row $id refused: decided_by must " *
                              "be exactly Greg (source-proven authority)")
        else
            push!(issues, "RESOLVED row $id refused: unrecognized " *
                          "register authority form")
            continue
        end
        # vocabulary gate SECOND
        if haskey(RIC_ENUMERATIONS, id)
            dec = ric_str(get(r, "decision", ""))
            dec in RIC_ENUMERATIONS[id].option_ids ||
                push!(issues, "RESOLVED row $id decision $dec not in the " *
                              "machine-enumerated option IDs " *
                              "$(RIC_ENUMERATIONS[id].option_ids)")
        else
            push!(issues, "RESOLVED row $id refused: options are not " *
                          "machine-enumerated from a pinned source -- " *
                          "resolution refused until exact option IDs are " *
                          "source-provided")
        end
    end
    # exact coverage LAST: every register ID exactly once (duplicates and
    # unknowns already reported above)
    sort(seen) == sort(RIC_EXPECTED_IDS) ||
        push!(issues, "rulings coverage $(sort(seen)) != the exact 9-ID " *
                      "register set -- every ruling must appear exactly " *
                      "once with an explicit OPEN/RESOLVED state")
    return issues
end

# per-row projection: all 9 rows, explicit OPEN/RESOLVED, enumeration
# provenance, AX2 derived-equivalence annotation; resolutions echo the
# assignment verbatim
function ric_resolution_rows(regmodel, valid_assignments)
    # defensive: only explicit state==RESOLVED rows can ever project as
    # resolutions, whatever a caller passes
    byid = Dict(ric_str(get(ric_obj(a), "ruling_id", "")) => ric_obj(a)
                for a in valid_assignments
                if ric_str(get(ric_obj(a), "state", "")) == "RESOLVED")
    rows = Any[]
    for id in RIC_EXPECTED_IDS
        reg = ric_obj(get(regmodel, id, nothing))
        row = Dict{String, Any}(
            "ruling_id" => id,
            "state" => haskey(byid, id) ? "RESOLVED" : "OPEN",
            "deciding_authority" => ric_str(get(reg, "deciding_authority",
                                                "")),
            "options_enumeration" => haskey(RIC_ENUMERATIONS, id) ?
                Dict("mode" => "machine_enumerated",
                     "option_ids" => RIC_ENUMERATIONS[id].option_ids) :
                Dict("mode" => "unenumerated_refuses_resolution",
                     "note" => "no pinned source machine-enumerates " *
                               "exact option IDs; resolution refused " *
                               "until one does"))
        id == "R-T45-AX2" &&
            (row["derived_equivalence_note"] = RIC_AX2_EQUIVALENCE_NOTE)
        if haskey(byid, id)
            a = byid[id]
            row["resolution"] = Dict(
                "decision" => ric_str(get(a, "decision", "")),
                "decided_by" => ric_str(get(a, "decided_by", "")),
                "decided_at_utc" => ric_str(get(a, "decided_at_utc", "")),
                "evidence" => deepcopy(ric_obj(get(a, "evidence",
                                                   nothing))),
                "attribution" => "structural_not_authenticated")
            haskey(a, "notes") &&
                (row["resolution"]["notes"] = ric_str(a["notes"]))
            row["non_authorizing_note"] = RIC_NON_AUTHORIZING
        end
        push!(rows, row)
    end
    return rows
end

# domain readiness: emitted separately, never requires all 9. The quota
# domain deliberately has NO "ready" key and never emits an authorization
# token: a recorded quota ruling is structural attribution, not
# authentication, and execution stays runbook-gated.
function ric_domain_readiness(rows)
    state = Dict(ric_str(r["ruling_id"]) => ric_str(r["state"])
                 for r in rows)
    mk = ids -> begin
        missing_ids = [i for i in ids if get(state, i, "OPEN") != "RESOLVED"]
        Dict("ready" => isempty(missing_ids),
             "requires" => ids, "missing" => missing_ids)
    end
    qmissing = get(state, "R-QUOTA-PATH-AD", "OPEN") == "RESOLVED" ?
        String[] : ["R-QUOTA-PATH-AD"]
    return Dict(
        "g2_binding_runner" => mk(["R-G2-D1", "R-G2-D2", "R-G2-D3",
                                   "R-G2-D4"]),
        "t45_evaluator" => mk(["R-T45-AX1", "R-T45-AX2", "R-T45-AX3",
                               "R-T45-AX4"]),
        "quota_path" => Dict(
            "state" => isempty(qmissing) ?
                "ruling_recorded_execution_unauthorized" :
                "awaiting_ruling",
            "requires" => ["R-QUOTA-PATH-AD"], "missing" => qmissing,
            "non_authorizing_note" => RIC_NON_AUTHORIZING))
end

# canonical current-state status from this run's facts (pure)
function ric_current_status(reg_healthy, present, parse_success, object_ok,
                            issues_empty)
    reg_healthy || return "rulings_intake_blocked_register_stale"
    present || return "rulings_intake_awaiting_assignments"
    (parse_success && object_ok && issues_empty) ||
        return "rulings_intake_refused"
    return "rulings_intake_assignments_recorded"
end

ric_exit_code(status) =
    status in ("rulings_intake_awaiting_assignments",
               "rulings_intake_assignments_recorded") ? 0 : 1

# last-valid preservation rule: embed ONLY a previously RECORDED state,
# ONLY when this run is not itself recorded, ONLY as historical data
ric_embed_last_valid(prev_status, current_status) =
    prev_status == "rulings_intake_assignments_recorded" &&
    current_status != "rulings_intake_assignments_recorded"

# ---------------------------------------------------------------------------
# fixtures (pure validators + tmp parse-shape files)
# ---------------------------------------------------------------------------

function ric_fixture_regmodel()
    m = Dict{String, Any}()
    for id in RIC_EXPECTED_IDS
        m[id] = Dict{String, Any}("id" => id, "status" => "OPEN",
            "deciding_authority" => id == "R-QUOTA-PATH-AD" ?
                RIC_GREG_AUTHORITY : "UNASSIGNED")
    end
    m["R-QUOTA-PATH-AD"]["options_from_source"] =
        Dict("path_a" => "a", "path_d_exact_byte_scope" => "d")
    m["R-G2-D3"]["options_from_source"] =
        Dict("invariant" => "i", "variant_eps_clamping" => "e",
             "variant_pair_selection" => "p")
    return m
end

ric_fixture_register(m) = Dict{String, Any}(
    "case" => RIC_EXPECTED_CASE, "status" => RIC_EXPECTED_STATUS,
    "open_rulings" => [m[id] for id in RIC_EXPECTED_IDS])

ric_fixture_evidence() = Dict{String, Any}(
    "kind" => "conversation_record", "locator" => "TEST-locator",
    "quote" => "TEST evidence quote")

# full-coverage rulings rows: all 9 IDs, quota RESOLVED by default,
# everything else explicit OPEN
function ric_fixture_rows(; quota_resolved = true)
    rows = Any[]
    for id in RIC_EXPECTED_IDS
        if id == "R-QUOTA-PATH-AD" && quota_resolved
            push!(rows, Dict{String, Any}(
                "ruling_id" => id, "state" => "RESOLVED",
                "decision" => "path_a", "decided_by" => "Greg",
                "decided_at_utc" => "2026-08-12T00:00:00Z",
                "evidence" => ric_fixture_evidence()))
        else
            push!(rows, Dict{String, Any}("ruling_id" => id,
                                          "state" => "OPEN"))
        end
    end
    return rows
end

function ric_fixture_assignment(sha; rows = nothing)
    Dict{String, Any}(
        "schema" => "gate4_rulings_assignment_v1",
        "authored_by" => "TEST-AUTHOR", "authored_at_utc" =>
            "2026-08-12T00:00:00Z",
        "register_pin" => Dict("case" => RIC_EXPECTED_CASE,
            "status" => RIC_EXPECTED_STATUS, "sha256" => sha),
        "rulings" => rows === nothing ? ric_fixture_rows() : rows)
end

function ric_fixtures()
    t = Dict{String, Bool}()
    m = ric_fixture_regmodel()
    reg = ric_fixture_register(m)
    sha = "0" ^ 64

    # register model consistency
    t["register_healthy_accepts"] = isempty(ric_register_issues(reg))
    bad = deepcopy(reg); bad["case"] = "other"
    t["register_wrong_case_refuses"] =
        any(occursin("case !=", i) for i in ric_register_issues(bad))
    bad = deepcopy(reg); bad["status"] = "tampered"
    t["register_wrong_status_refuses"] =
        any(occursin("status !=", i) for i in ric_register_issues(bad))
    bad = deepcopy(reg); pop!(bad["open_rulings"])
    t["register_id_set_drift_refuses"] =
        any(occursin("exact expected", i) for i in ric_register_issues(bad))
    bad = deepcopy(reg); bad["open_rulings"][1]["status"] = "RESOLVED"
    t["register_non_open_row_refuses"] =
        any(occursin("!= OPEN", i) for i in ric_register_issues(bad))
    bad = deepcopy(reg)
    bad["open_rulings"][2]["deciding_authority"] =
        "monitor -- explicitly assigned"
    t["register_authority_drift_refuses"] =
        any(occursin("!= UNASSIGNED", i) for i in ric_register_issues(bad))
    bad = deepcopy(reg)
    bad["open_rulings"][end]["deciding_authority"] = "Greg"
    t["register_quota_authority_form_refuses"] =
        any(occursin("exact source-verified Greg form", i)
            for i in ric_register_issues(bad))
    bad = deepcopy(reg)
    bad["open_rulings"][end]["options_from_source"] =
        Dict("path_a" => "a", "path_b" => "b")
    t["register_quota_enum_drift_refuses"] =
        any(occursin("enumeration no longer source-anchored", i)
            for i in ric_register_issues(bad))
    bad = deepcopy(reg)
    bad["open_rulings"][3]["options_from_source"] =
        Dict("variant_eps_clamping" => "e", "variant_pair_selection" => "p")
    t["register_d3_key_set_drift_refuses"] =
        any(occursin("enumeration no longer source-anchored", i)
            for i in ric_register_issues(bad))

    # source staleness (tmp files)
    tdir = mktempdir()
    sp = joinpath(tdir, "src.json"); write(sp, "{}")
    fresh = [Dict("path" => sp, "sha256" => ric_sha(sp))]
    t["fresh_sources_accepted"] = isempty(ric_source_staleness(fresh))
    write(sp, "{ }")
    t["source_hash_drift_detected"] =
        any(occursin("sha drifted", i) for i in ric_source_staleness(fresh))
    gone = [Dict("path" => joinpath(tdir, "absent.json"),
                 "sha256" => "0"^64)]
    t["missing_source_detected"] =
        any(occursin("missing", i) for i in ric_source_staleness(gone))
    t["empty_sources_refused"] =
        !isempty(ric_source_set_issues(Any[]))
    t["exact_source_set_accepted"] =
        isempty(ric_source_set_issues(
            [Dict("path" => p) for p in RIC_EXPECTED_SOURCE_PATHS]))
    # TOCTOU hardening: hash failures return nothing (never throw) and a
    # present-but-unhashable input classifies as a refusal issue
    t["hash_failure_returns_nothing"] =
        ric_try_sha(joinpath(tdir, "vanished.json")) === nothing &&
        ric_try_sha(sp) isa AbstractString
    t["snapshot_inconsistency_refuses"] =
        any(occursin("snapshot inconsistency", i)
            for i in ric_snapshot_issue(true, nothing)) &&
        isempty(ric_snapshot_issue(true, "0"^64)) &&
        isempty(ric_snapshot_issue(false, nothing))
    # same basename in another directory must NOT satisfy the set check
    subst = [Dict("path" => i == 1 ?
                  joinpath(tdir, basename(RIC_EXPECTED_SOURCE_PATHS[1])) :
                  RIC_EXPECTED_SOURCE_PATHS[i])
             for i in eachindex(RIC_EXPECTED_SOURCE_PATHS)]
    t["same_basename_wrong_directory_refuses"] =
        any(occursin("exact expected", i)
            for i in ric_source_set_issues(subst))

    # rulings-file validation (exact 9-row coverage schema)
    qrow(x) = only(r for r in x["rulings"]
                   if r["ruling_id"] == "R-QUOTA-PATH-AD")
    ok = ric_fixture_assignment(sha)
    t["valid_quota_assignment_accepted"] =
        isempty(ric_assignment_issues(ok, m, sha))
    allopen = ric_fixture_assignment(sha;
                                     rows = ric_fixture_rows(
                                         quota_resolved = false))
    t["all_open_explicit_accepted"] =
        isempty(ric_assignment_issues(allopen, m, sha))
    t["non_object_file_refuses"] =
        any(occursin("non-object", i)
            for i in ric_assignment_issues(nothing, m, sha))
    bad = deepcopy(ok); bad["authorize_execution"] = true
    t["unknown_top_key_refuses"] =
        any(occursin("unknown top-level key authorize_execution", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); bad["schema"] = "v0"
    t["wrong_schema_token_refuses"] =
        any(occursin("schema !=", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); delete!(bad, "register_pin")
    t["missing_pin_refuses"] =
        any(occursin("missing top-level key register_pin", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); bad["register_pin"]["sha256"] = "1"^64
    t["stale_pin_refuses"] =
        any(occursin("STALE PIN", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); bad["register_pin"]["status"] = "tampered"
    t["pin_status_mismatch_refuses"] =
        any(occursin("register_pin.status mismatch", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); bad["register_pin"]["extra"] = "x"
    t["pin_unknown_key_refuses"] =
        any(occursin("register_pin key set != exact", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); bad["rulings"] = "not-a-vector"
    t["non_vector_rulings_refuses"] =
        any(occursin("rulings missing/non-vector", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); bad["rulings"] = bad["rulings"][1:8]
    t["missing_row_coverage_refuses"] =
        any(occursin("exact 9-ID", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); bad["rulings"][1]["ruling_id"] = "R-XX-99"
    t["unknown_ruling_id_refuses"] =
        any(occursin("unknown ruling_id", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok)
    bad["rulings"][1]["ruling_id"] = bad["rulings"][2]["ruling_id"]
    t["duplicate_ruling_id_refuses"] =
        any(occursin("duplicate row", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); bad["rulings"][1]["state"] = "PENDING"
    t["invalid_state_token_refuses"] =
        any(occursin("not in {OPEN, RESOLVED}", i)
            for i in ric_assignment_issues(bad, m, sha))
    # an OPEN row FORBIDS resolution fields: an accidental omission of
    # state=RESOLVED can never smuggle a decision through
    bad = deepcopy(ok); bad["rulings"][1]["decision"] = "sneaky"
    t["open_row_forbids_resolution_fields"] =
        any(occursin("OPEN row R-G2-D1 forbids key decision", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); delete!(qrow(bad), "evidence")
    t["resolved_row_missing_evidence_refuses"] =
        any(occursin("missing key evidence", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); qrow(bad)["applies_also_to"] = "all"
    t["unknown_row_key_refuses"] =
        any(occursin("unknown key applies_also_to", i)
            for i in ric_assignment_issues(bad, m, sha))
    resolved_row(id, dec) = Dict{String, Any}(
        "ruling_id" => id, "state" => "RESOLVED", "decision" => dec,
        "decided_by" => "Greg",
        "decided_at_utc" => "2026-08-12T00:00:00Z",
        "evidence" => ric_fixture_evidence())
    rows0 = ric_fixture_rows(quota_resolved = false)
    bad = ric_fixture_assignment(sha; rows =
        [r["ruling_id"] == "R-G2-D2" ? resolved_row("R-G2-D2", "pooled") : r
         for r in rows0])
    t["unassigned_authority_row_refuses"] =
        any(occursin("authority is UNASSIGNED", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); qrow(bad)["decided_by"] = "monitor"
    t["quota_wrong_decider_refuses"] =
        any(occursin("decided_by must be exactly Greg", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); qrow(bad)["decision"] = "path_b"
    t["quota_bad_vocabulary_refuses"] =
        any(occursin("not in the machine-enumerated option IDs", i)
            for i in ric_assignment_issues(bad, m, sha))
    # constraint-1 branch proven independent of authority: a SYNTHETIC
    # Greg-assigned row with no enumeration still refuses resolution
    m2 = deepcopy(m)
    m2["R-T45-AX1"]["deciding_authority"] = RIC_GREG_AUTHORITY
    bad = ric_fixture_assignment(sha; rows =
        [r["ruling_id"] == "R-T45-AX1" ?
             resolved_row("R-T45-AX1", "paired_delta") : r
         for r in rows0])
    t["unenumerated_options_refuse_resolution"] =
        any(occursin("not machine-enumerated", i)
            for i in ric_assignment_issues(bad, m2, sha))
    bad = deepcopy(ok); qrow(bad)["evidence"] = "just a string"
    t["non_object_evidence_refuses"] =
        any(occursin("evidence must be an object", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); qrow(bad)["evidence"]["quote"] = ""
    t["empty_evidence_quote_refuses"] =
        any(occursin("evidence.quote missing/empty", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok)
    qrow(bad)["evidence"]["authorizes_execution"] = true
    t["evidence_unknown_key_refuses"] =
        any(occursin("evidence unknown key", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); qrow(bad)["evidence"]["sha256"] = "zz"
    t["evidence_bad_digest_refuses"] =
        any(occursin("evidence.sha256 not 64-hex", i)
            for i in ric_assignment_issues(bad, m, sha))
    bad = deepcopy(ok); qrow(bad)["decided_at_utc"] = "yesterday"
    t["malformed_decided_at_refuses"] =
        any(occursin("decided_at_utc not fully anchored", i)
            for i in ric_assignment_issues(bad, m, sha))
    # ANCHORED timestamp validation: trailing garbage refuses
    bad = deepcopy(ok)
    qrow(bad)["decided_at_utc"] = "2026-08-12T00:00:00Z; rm -rf"
    t["trailing_garbage_timestamp_refuses"] =
        any(occursin("decided_at_utc not fully anchored", i)
            for i in ric_assignment_issues(bad, m, sha))
    # a *_at_utc field must carry the terminal Z: offsets/zoneless refuse
    bad = deepcopy(ok)
    qrow(bad)["decided_at_utc"] = "2026-08-12T00:00:00+00:00"
    t["non_utc_offset_timestamp_refuses"] =
        any(occursin("terminal Z required", i)
            for i in ric_assignment_issues(bad, m, sha))

    # projection + readiness on the valid quota assignment
    rows = ric_resolution_rows(m, [r for r in ok["rulings"]
                                   if r["state"] == "RESOLVED"])
    t["nine_rows_always_emitted"] = length(rows) == 9 &&
        sort([ric_str(r["ruling_id"]) for r in rows]) ==
        sort(RIC_EXPECTED_IDS)
    t["quota_row_resolved_others_open"] =
        count(r -> ric_str(r["state"]) == "RESOLVED", rows) == 1 &&
        only(r for r in rows
             if ric_str(r["state"]) == "RESOLVED")["ruling_id"] ==
            "R-QUOTA-PATH-AD"
    t["resolved_row_marked_non_authorizing"] =
        all(!haskey(r, "resolution") ||
            get(r, "non_authorizing_note", "") == RIC_NON_AUTHORIZING
            for r in rows)
    t["ax2_equivalence_note_present"] =
        only(r for r in rows if r["ruling_id"] == "R-T45-AX2")[
            "derived_equivalence_note"] == RIC_AX2_EQUIVALENCE_NOTE
    dr = ric_domain_readiness(rows)
    # the quota domain must NEVER emit a "ready"/authorization token:
    # resolution yields ruling_recorded_execution_unauthorized only
    t["quota_domain_recorded_never_authorized"] =
        !haskey(dr["quota_path"], "ready") &&
        dr["quota_path"]["state"] ==
            "ruling_recorded_execution_unauthorized" &&
        dr["quota_path"]["non_authorizing_note"] == RIC_NON_AUTHORIZING &&
        dr["g2_binding_runner"]["ready"] == false &&
        dr["t45_evaluator"]["ready"] == false &&
        sort(dr["g2_binding_runner"]["missing"]) ==
            ["R-G2-D1", "R-G2-D2", "R-G2-D3", "R-G2-D4"]
    open_rows = ric_resolution_rows(m, Any[])
    dr0 = ric_domain_readiness(open_rows)
    t["all_open_no_domain_ready"] =
        dr0["g2_binding_runner"]["ready"] == false &&
        dr0["t45_evaluator"]["ready"] == false &&
        dr0["quota_path"]["state"] == "awaiting_ruling"

    # parse-shape separation (tmp files through the ONE snapshot helper)
    up = joinpath(tdir, "unparseable.json"); write(up, "{")
    r = ric_snapshot(up)
    t["unparseable_is_parse_failure"] =
        r.readable && !r.parse_success && !r.object_ok &&
        r.sha isa AbstractString
    np = joinpath(tdir, "null.json"); write(np, "null")
    r = ric_snapshot(np)
    t["json_null_parses_but_non_object"] = r.parse_success && !r.object_ok
    ap = joinpath(tdir, "array.json"); write(ap, "[1]")
    r = ric_snapshot(ap)
    t["json_array_parses_but_non_object"] = r.parse_success && !r.object_ok
    t["missing_file_snapshot_unreadable"] = begin
        r = ric_snapshot(joinpath(tdir, "not-there.json"))
        !r.readable && r.sha === nothing && !r.parse_success
    end
    # coupled byte snapshot: digest and parsed content come from the SAME
    # captured bytes -- overwriting the file changes neither in an
    # already-taken snapshot, and a fresh snapshot sees the new pair
    t["byte_snapshot_couples_digest_and_content"] = begin
        cpf = joinpath(tdir, "coupled.json")
        write(cpf, "{\"v\": 1}")
        s1 = ric_snapshot(cpf)
        sha1_external = ric_sha(cpf)
        write(cpf, "{\"v\": 22}")
        s2 = ric_snapshot(cpf)
        s1.parse_success && s1.object_ok && s1.data["v"] == 1 &&
            s1.sha == sha1_external && s2.data["v"] == 22 &&
            s2.sha == ric_sha(cpf) && s1.sha != s2.sha
    end

    # current-state transitions (the stale-ready matrix)
    t["absent_source_is_awaiting"] =
        ric_current_status(true, false, false, false, false) ==
        "rulings_intake_awaiting_assignments"
    t["valid_source_is_recorded"] =
        ric_current_status(true, true, true, true, true) ==
        "rulings_intake_assignments_recorded"
    t["stale_register_blocks_even_when_source_valid"] =
        ric_current_status(false, true, true, true, true) ==
        "rulings_intake_blocked_register_stale"
    # valid -> source REMOVED: prior recorded state must NOT survive as
    # the active status; the run transitions to awaiting and the prior
    # decisions are embedded as historical only
    prev_removed = ric_current_status(true, false, false, false, false)
    t["valid_then_source_removed_goes_awaiting"] =
        prev_removed == "rulings_intake_awaiting_assignments" &&
        ric_embed_last_valid("rulings_intake_assignments_recorded",
                             prev_removed)
    # valid -> source CORRUPTED: refused nonzero, historical embed only
    prev_corrupt = ric_current_status(true, true, false, false, false)
    t["valid_then_source_corrupted_refuses"] =
        prev_corrupt == "rulings_intake_refused" &&
        ric_exit_code(prev_corrupt) == 1 &&
        ric_embed_last_valid("rulings_intake_assignments_recorded",
                             prev_corrupt)
    t["recorded_state_never_embeds_itself"] =
        !ric_embed_last_valid("rulings_intake_assignments_recorded",
                              "rulings_intake_assignments_recorded")
    t["awaiting_prev_never_embeds"] =
        !ric_embed_last_valid("rulings_intake_awaiting_assignments",
                              "rulings_intake_refused")
    t["exit_codes_exact"] =
        ric_exit_code("rulings_intake_awaiting_assignments") == 0 &&
        ric_exit_code("rulings_intake_assignments_recorded") == 0 &&
        ric_exit_code("rulings_intake_refused") == 1 &&
        ric_exit_code("rulings_intake_blocked_register_stale") == 1 &&
        ric_exit_code("rulings_intake_selftest_failed") == 1

    rm(tdir, recursive = true, force = true)
    return t
end

# ---------------------------------------------------------------------------
# emission
# ---------------------------------------------------------------------------

# stable JSON for MD emission (sorted keys, recursive)
function ric_stable_json(x)
    if x isa AbstractDict
        inner = join(["$(JSON.json(String(k))): $(ric_stable_json(x[k]))"
                      for k in sort(collect(keys(x)); by = String)], ", ")
        return "{" * inner * "}"
    elseif x isa AbstractVector
        return "[" * join([ric_stable_json(v) for v in x], ", ") * "]"
    else
        return JSON.json(x)
    end
end

# atomic replacement: unique same-directory temp + rename. This prevents
# TRUNCATION/PARTIAL replacement (readers never see a torn artifact) and
# temp-name collisions across concurrent/stale runs; a crash BEFORE the
# rename preserves the previous complete artifact, and successful
# completion publishes this run's state.
function ric_atomic_write(path, content)
    tmp = path * ".tmp-$(getpid())"
    open(tmp, "w") do io
        write(io, content)
    end
    Base.Filesystem.rename(tmp, path)
end

const RIC_EXPECTED_ASSIGNMENT_SCHEMA = Dict(
    "schema" => "gate4_rulings_assignment_v1",
    "authored_by" => "<nonempty; authorship is out of band>",
    "authored_at_utc" => "<ISO-8601>",
    "register_pin" => Dict("case" => RIC_EXPECTED_CASE,
        "status" => RIC_EXPECTED_STATUS,
        "sha256" => "<sha256 of the live register artifact>"),
    "rulings" => [Dict(
        "ruling_id" => "<ALL 9 register IDs, each exactly once>",
        "state" => "<OPEN | RESOLVED -- explicit; OPEN rows carry ONLY " *
                   "ruling_id+state; RESOLVED rows require every field " *
                   "below>",
        "decision" => "<verbatim machine-enumerated option id>",
        "decided_by" => "<authority; quota requires exactly Greg>",
        "decided_at_utc" => "<fully anchored ISO-8601>",
        "evidence" => Dict(
            "kind" => "<source kind, e.g. conversation_record/file>",
            "locator" => "<independently reviewable locator/record>",
            "quote" => "<exact verbatim quote>",
            "sha256" => "<optional 64-hex digest of the evidence source>"),
        "notes" => "<optional>")],
    "note" => "<optional>")

function ric_main()
    fails = String[]
    gates = Dict{String, String}()

    # fixtures first: a broken validator must never bless an intake state
    t = ric_fixtures()
    gates["fixtures"] = all(values(t)) ? "passed" : "failed"
    all(values(t)) || push!(fails, "fixtures failed: " *
        join(sort([k for (k, v) in t if !v]), ", "))

    # register verification (identity + model + pinned-source freshness)
    reg_healthy = false
    regmodel = Dict{String, Any}()
    live_register_sha = ""
    reg_detail = String[]
    if isfile(RIC_REGISTER_JSON)
        # ONE byte snapshot: digest and parsed content from the same
        # read; the digest serves pin validation AND the emitted
        # register.live_sha256 fact
        rs = ric_snapshot(RIC_REGISTER_JSON)
        if !rs.readable
            push!(reg_detail, "register artifact unreadable at snapshot " *
                              "time (TOCTOU)")
        elseif !rs.parse_success
            push!(reg_detail, "register artifact unparseable")
        elseif !rs.object_ok
            push!(reg_detail, "register artifact parses to a non-object")
        else
            live_register_sha = rs.sha
            append!(reg_detail, ric_register_issues(rs.data))
            srcs = get(rs.data, "sources", nothing)
            append!(reg_detail, ric_source_set_issues(srcs))
            append!(reg_detail, ric_source_staleness(srcs))
            if isempty(reg_detail)
                reg_healthy = true
                for r in get(rs.data, "open_rulings", Any[])
                    regmodel[ric_str(get(ric_obj(r), "id", ""))] = ric_obj(r)
                end
            end
        end
    else
        push!(reg_detail, "register artifact missing: $RIC_REGISTER_JSON")
    end
    gates["register_verified_and_sources_fresh"] =
        reg_healthy ? "passed" : "failed"
    append!(fails, reg_detail)

    # assignment source state (never written here): ONE nonthrowing byte
    # snapshot supplies digest AND parsed decisions (a mid-run file
    # replacement can never pair one's bytes with the other's), reused
    # for validation and emission -- never re-hashed. Snapshot taken
    # whenever present (even register-blocked) so the emitted facts are
    # always current.
    present = isfile(RIC_ASSIGNMENT_PATH)
    asnap = present ? ric_snapshot(RIC_ASSIGNMENT_PATH) : nothing
    assignment_sha = asnap === nothing ? nothing : asnap.sha
    parse_success = asnap === nothing ? false : asnap.parse_success
    object_ok = asnap === nothing ? false : asnap.object_ok
    adata = asnap === nothing ? nothing : asnap.data
    issues = String[]
    if reg_healthy && present
        if !asnap.readable
            append!(issues, ric_snapshot_issue(present, asnap.sha))
        elseif !parse_success
            push!(issues, "assignment file unparseable -- refused")
        elseif !object_ok
            push!(issues, "assignment parses to a non-object (JSON null/" *
                          "array/scalar) -- refused")
        else
            append!(issues, ric_assignment_issues(adata, regmodel,
                                                  live_register_sha))
        end
    end

    status = ric_current_status(reg_healthy, present, parse_success,
                                object_ok, isempty(issues))
    # self-test override FIRST: a broken validator can never bless a
    # state, and (below) it also never skips preserving a previously
    # recorded state as historical evidence
    all(values(t)) || (status = "rulings_intake_selftest_failed")
    valid_assignments = status == "rulings_intake_assignments_recorded" ?
        [r for r in get(ric_obj(adata), "rulings", Any[])
         if ric_str(get(ric_obj(r), "state", "")) == "RESOLVED"] : Any[]
    rows = ric_resolution_rows(reg_healthy ? regmodel :
        Dict{String, Any}(id => Dict{String, Any}("id" => id,
            "deciding_authority" => "(register unavailable)")
            for id in RIC_EXPECTED_IDS), valid_assignments)
    readiness = ric_domain_readiness(rows)
    gates["assignment_state"] = status in
        ("rulings_intake_awaiting_assignments",
         "rulings_intake_assignments_recorded") ? "passed" : "failed"
    status == "rulings_intake_refused" &&
        append!(fails, issues)

    # last-valid preservation: historical, non-authorizing, never active
    last_valid = nothing
    if isfile(RIC_RESULTS_JSON)
        prev = ric_snapshot(RIC_RESULTS_JSON)
        if prev.parse_success && prev.object_ok
            pstat = ric_str(get(prev.data, "status", ""))
            if ric_embed_last_valid(pstat, status)
                last_valid = Dict(
                    "historical_non_authorizing" => true,
                    "note" => "previous RECORDED intake preserved as " *
                        "historical evidence only; the canonical status " *
                        "of THIS run is authoritative and downstream " *
                        "must never consume these decisions",
                    "previous_status" => pstat,
                    "previous_timestamp_utc" =>
                        ric_str(get(prev.data, "timestamp_utc", "")),
                    "previous_resolved_rows" =>
                        [r for r in get(prev.data, "resolutions", Any[])
                         if ric_str(get(ric_obj(r), "state", "")) ==
                            "RESOLVED"])
            end
        end
    end

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_rulings_intake_contract",
        "data_mode" => "derivative_fail_closed_intake",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "fixture_verdicts" => t,
        "register" => Dict(
            "path" => RIC_REGISTER_JSON,
            "healthy" => reg_healthy,
            "live_sha256" => live_register_sha,
            "expected_case" => RIC_EXPECTED_CASE,
            "expected_status" => RIC_EXPECTED_STATUS),
        "assignment_source" => Dict(
            "path" => RIC_ASSIGNMENT_PATH,
            "present" => present,
            # the SAME single snapshot used in validation (never
            # re-hashed at emission): a changed same-status human input
            # can never leave an old artifact looking current, and an
            # unhashable present input was already classified refused
            "live_sha256" => assignment_sha,
            "parse_success" => present ? parse_success : nothing,
            "object_ok" => present ? object_ok : nothing,
            "never_written_by_this_unit" => true),
        "resolutions" => rows,
        "domain_readiness" => readiness,
        "expected_assignment_schema" => RIC_EXPECTED_ASSIGNMENT_SCHEMA,
        "refusal_reasons" => issues,
        "authorship_caveat" => "structural attribution, NOT " *
            "authentication: validation can say structurally recorded; " *
            "it cannot prove Greg authored the evidence absent a " *
            "trusted signature/channel; assignment authorship is out " *
            "of band and this unit never emits an authorization token",
        "standing_constraint" => RIC_NON_AUTHORIZING,
        "provenance" => Dict("branch" => branch,
            "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working " *
                "tree before its own commit"),
        "disclaimer" => "derivative fail-closed rulings intake; no " *
            "election, no inferred authority, no default decision; the " *
            "8 UNASSIGNED rows refuse assignment until a source-proven " *
            "authority updates the register; unenumerated option sets " *
            "refuse resolution; the canonical status reflects the " *
            "latest successfully emitted run (atomic same-directory " *
            "temp + rename -- a failed write can never truncate or " *
            "silently preserve a stale-ready artifact as this run's " *
            "output) and prior decisions survive only as historical " *
            "non-authorizing evidence.")
    last_valid !== nothing && (result["last_valid_intake"] = last_valid)

    mkpath(dirname(RIC_RESULTS_JSON))
    jbuf = IOBuffer(); JSON.print(jbuf, result, 2)
    ric_atomic_write(RIC_RESULTS_JSON, String(take!(jbuf)))
    mbuf = IOBuffer()
    println(mbuf, "# Gate-4 rulings intake contract\n")
    println(mbuf, "Status: **$status**\n")
    println(mbuf, result["disclaimer"], "\n")
    println(mbuf, "| Gate | Verdict |")
    println(mbuf, "|---|---|")
    for k in sort(collect(keys(gates)))
        println(mbuf, "| $k | $(gates[k]) |")
    end
    println(mbuf, "\n## Rulings ($(length(rows)) rows, always all 9)\n")
    for r in rows
        println(mbuf, "- **$(r["ruling_id"])** [$(r["state"])] authority: " *
                      "$(first(ric_str(r["deciding_authority"]), 60))" *
                      (ric_str(r["deciding_authority"]) == "UNASSIGNED" ?
                       "" : "..."))
        println(mbuf, "  - options: " *
                      ric_stable_json(r["options_enumeration"]))
        haskey(r, "derived_equivalence_note") &&
            println(mbuf, "  - $(r["derived_equivalence_note"])")
        haskey(r, "resolution") &&
            println(mbuf, "  - resolution: " *
                          ric_stable_json(r["resolution"]) *
                          " ($(RIC_NON_AUTHORIZING))")
    end
    println(mbuf, "\n## Domain readiness\n")
    for k in sort(collect(keys(readiness)))
        println(mbuf, "- `$k`: " * ric_stable_json(readiness[k]))
    end
    println(mbuf, "\n## Assignment source\n")
    println(mbuf, "- path: `$(RIC_ASSIGNMENT_PATH)` (authored out of " *
                  "band; never written by any unit)")
    println(mbuf, "- present: $present")
    println(mbuf, "\n## Expected assignment schema\n")
    println(mbuf, "```json")
    println(mbuf, ric_stable_json(RIC_EXPECTED_ASSIGNMENT_SCHEMA))
    println(mbuf, "```")
    if last_valid !== nothing
        println(mbuf, "\n## Last valid intake (HISTORICAL, " *
                      "non-authorizing)\n")
        println(mbuf, ric_stable_json(last_valid))
    end
    isempty(issues) || (println(mbuf, "\n## Refusal reasons\n");
                        foreach(i -> println(mbuf, "- ", i), issues))
    isempty(fails) || (println(mbuf, "\n## Failures\n");
                       foreach(f -> println(mbuf, "- ", f), fails))
    println(mbuf, "\nProvenance: branch `$branch`, generated_from_head " *
                  "`$head` (pre-own-commit).")
    ric_atomic_write(RIC_RESULTS_MD, String(take!(mbuf)))

    println("gate4_rulings_intake_contract: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    n_res = count(r -> ric_str(r["state"]) == "RESOLVED", rows)
    println("  rows: $(length(rows)) (RESOLVED: $n_res); readiness: " *
            "g2_binding_runner=$(readiness["g2_binding_runner"]["ready"]) " *
            "t45_evaluator=$(readiness["t45_evaluator"]["ready"]) " *
            "quota_path=$(readiness["quota_path"]["state"])")
    isempty(fails) || foreach(f -> println("  FAIL: $f"), first(fails, 8))
    return ric_exit_code(status)
end

exit(ric_main())
