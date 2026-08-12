# Gate-4 PENDING-RULINGS REGISTER (derivative, read-only; no election,
# no inferred authority).
#
# Purpose (monitor-directed, 2026-08-12): a single decision surface for
# every genuinely OPEN ruling the campaign is staged on, each proven from
# its machine-readable/pinned source with fail-closed case/status/schema
# verification and path + sha256 recorded. Contents are strictly the
# three source-proven groups:
#   - Gate-2 binding decisions D1-D4 (gate4_g2_binding_decision_scaffold)
#   - thresholds 4-5 four open axes (regression-margin evidence memo)
#   - quota Path A/D authorization (G2c chain + recovery runbook)
# NO Gate-2/acceptance-sequencing ruling is invented: no source declares
# one open. Where a source does not explicitly assign the deciding
# authority the register emits UNASSIGNED -- never a guess. Quota figures
# are an OBSERVED-AT snapshot quoted from the pinned 4440 failure ledger,
# never a live read (the quota watcher runs separately so determinism is
# not broken by changing usage). Deletion, quota change, and job
# submission remain UNAUTHORIZED; this unit changes nothing.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const REG_RESULTS_JSON =
    validation_results_path("gate4_pending_rulings_register.json")
const REG_RESULTS_MD =
    validation_results_path("gate4_pending_rulings_register.md")

struct RegisterRefusal <: Exception
    reason::String
end
Base.showerror(io::IO, e::RegisterRefusal) = print(io, "RegisterRefusal: ",
                                                   e.reason)
rrefuse(reason) = throw(RegisterRefusal(reason))

reg_obj(x) = x isa AbstractDict ? x : Dict{String, Any}()
reg_str(x) = x isa AbstractString ? String(x) : ""
reg_sha(p) = split(strip(read(`sha256sum $p`, String)))[1]

# fail-closed machine-readable JSON source: exact case + status + schema
function verify_json_source(path; expected_case, expected_status,
                            required_keys = String[])
    isfile(path) || rrefuse("source missing: $path")
    raw = try
        JSON.parsefile(path)
    catch err
        rrefuse("source unparseable: $path " *
                "($(first(sprint(showerror, err), 80)))")
    end
    d = reg_obj(raw)
    reg_str(get(d, "case", "")) == expected_case ||
        rrefuse("source case mismatch in $path: " *
                "$(reg_str(get(d, "case", "(missing/non-object)"))) != " *
                "$expected_case")
    reg_str(get(d, "status", "")) == expected_status ||
        rrefuse("source status mismatch in $path: " *
                "$(reg_str(get(d, "status", "(missing)"))) != " *
                "$expected_status")
    for k in required_keys
        haskey(d, k) || rrefuse("source $path missing required key $k")
    end
    return (data = d,
            record = Dict("path" => path, "sha256" => reg_sha(path),
                          "kind" => "json",
                          "verified_case" => expected_case,
                          "verified_status" => expected_status))
end

# fail-closed pinned prose source: required anchors must all be present
function verify_md_source(path; required_anchors)
    isfile(path) || rrefuse("source missing: $path")
    text = read(path, String)
    for a in required_anchors
        occursin(a, text) ||
            rrefuse("source $path missing required anchor: $a")
    end
    return (text = text,
            record = Dict("path" => path, "sha256" => reg_sha(path),
                          "kind" => "md",
                          "verified_anchors" => collect(required_anchors)))
end

# accidental-election / duplicate-ID guards (pure; fixture-testable)
const REG_FORBIDDEN_ENTRY_KEYS = ("resolution", "elected", "verdict",
                                  "chosen", "decision_made")
# the ONLY non-UNASSIGNED authority form the register accepts: the exact
# source-verified Greg assignment (anything else, including a fabricated
# "monitor -- explicitly assigned", fails the guard). The quoted sentence
# is verified VERBATIM (whitespace-normalized) against the runbook.
const REG_AUTHORITY_SENTENCE = "No `rm`, no quota change, and no job " *
    "submission may be run from this document without Greg's explicit " *
    "authorization of the chosen path."
const REG_GREG_AUTHORITY = "Greg -- explicitly assigned by the runbook: " *
    "'" * REG_AUTHORITY_SENTENCE * "'"

normalize_ws(s) = replace(s, r"\s+" => " ")

# exact-sentence verification (whitespace-normalized); loose anchors do
# not prove the quotation/assignment
authority_sentence_present(text) =
    occursin(normalize_ws(REG_AUTHORITY_SENTENCE), normalize_ws(text))
const REG_EXPECTED_IDS = ["R-G2-D1", "R-G2-D2", "R-G2-D3", "R-G2-D4",
                          "R-T45-AX1", "R-T45-AX2", "R-T45-AX3",
                          "R-T45-AX4", "R-QUOTA-PATH-AD"]

# recursive forbidden-key scan: election keys cannot hide inside nested
# containers such as options_from_source
function forbidden_keys_recursive(x, prefix)
    hits = String[]
    if x isa AbstractDict
        for (k, v) in x
            ks = String(k)
            ks in REG_FORBIDDEN_ENTRY_KEYS &&
                push!(hits, prefix * ks)
            append!(hits, forbidden_keys_recursive(v, prefix * ks * "."))
        end
    elseif x isa AbstractVector
        for (i, v) in enumerate(x)
            append!(hits, forbidden_keys_recursive(v, prefix * "[$i]."))
        end
    end
    return hits
end

# exact core entry schema: every entry must carry these keys with the
# right basic types (never assumed to exist)
const REG_CORE_SCHEMA = (
    ("id", AbstractString), ("title", AbstractString),
    ("status", AbstractString), ("deciding_authority", AbstractString),
    ("options_from_source", Union{AbstractDict, AbstractString}),
    ("source_paths", AbstractVector), ("unblocks", AbstractString))

function register_entry_issues(entries)
    issues = String[]
    ids = [reg_str(get(e, "id", "")) for e in entries]
    length(unique(ids)) == length(ids) ||
        push!(issues, "duplicate ruling IDs: $ids")
    for e in entries
        eid = reg_str(get(e, "id", "(missing-id)"))
        isempty(eid) && (eid = "(missing-id)")
        for (k, T) in REG_CORE_SCHEMA
            if !haskey(e, k)
                push!(issues, "entry $eid missing core schema key $k")
            elseif !(e[k] isa T)
                push!(issues, "entry $eid core key $k has wrong type " *
                              "$(typeof(e[k]))")
            end
        end
        reg_str(get(e, "status", "")) == "OPEN" ||
            push!(issues, "entry $eid status " *
                          "$(reg_str(get(e, "status", "(missing)"))) != " *
                          "OPEN (the register never records resolutions)")
        hits = forbidden_keys_recursive(e, "")
        isempty(hits) || push!(issues,
            "entry $eid carries forbidden election key(s): " *
            join(hits, ", "))
        auth = reg_str(get(e, "deciding_authority", ""))
        (auth == "UNASSIGNED" || auth == REG_GREG_AUTHORITY) ||
            push!(issues, "entry $eid authority is neither " *
                          "UNASSIGNED nor the exact source-verified Greg " *
                          "assignment form")
    end
    return issues
end

# stable JSON for MD emission: sorted keys, recursive (Dict iteration
# order is never relied on)
function stable_json(x)
    if x isa AbstractDict
        inner = join(["$(JSON.json(String(k))): $(stable_json(x[k]))"
                      for k in sort(collect(keys(x)); by = String)], ", ")
        return "{" * inner * "}"
    elseif x isa AbstractVector
        return "[" * join([stable_json(v) for v in x], ", ") * "]"
    else
        return JSON.json(x)
    end
end

# Gate-2 decision-map key discipline: exactly D1-D4, no silent omission
# of an unexpected future D-number (cross_reference and other non-D keys
# are allowed)
function gate2_dkey_issues(dmap)
    issues = String[]
    dkeys = sort([String(k) for k in keys(dmap)
                  if occursin(r"^D\d", String(k))])
    expected = ["D1_dataset_binding", "D2_aggregation",
                "D3_nonpositive_pair_policy", "D4_active_gas_lists"]
    dkeys == expected ||
        push!(issues, "decision_map D-key set $dkeys != expected " *
                      "$expected (an unexpected D-number must be " *
                      "surfaced, never silently omitted)")
    return issues
end

# fail-closed quota-snapshot validation: required nested NONNEGATIVE
# integer keys and EXACT arithmetic identities before any copy
function validate_quota_snapshot(ea)
    ea isa AbstractDict || rrefuse("quota accounting is not an object")
    src = reg_obj(get(ea, "source_set_bytes", nothing))
    fin = reg_obj(get(ea, "local_finalized", nothing))
    for (d, ks) in ((src, ("lw_35_files", "sw_35_files", "total_70")),
                    (fin, ("bytes",)),
                    (ea, ("remaining_bytes",
                          "hard_headroom_bytes_post_failure",
                          "shortfall_bytes_post_failure")))
        for k in ks
            v = get(d, k, nothing)
            (v isa Integer && v >= 0) ||
                rrefuse("quota accounting key $k missing/non-integer/" *
                        "negative")
        end
    end
    src["lw_35_files"] + src["sw_35_files"] == src["total_70"] ||
        rrefuse("quota accounting arithmetic: lw + sw != total")
    src["total_70"] - fin["bytes"] == ea["remaining_bytes"] ||
        rrefuse("quota accounting arithmetic: total - finalized != remaining")
    ea["remaining_bytes"] - ea["hard_headroom_bytes_post_failure"] ==
        ea["shortfall_bytes_post_failure"] ||
        rrefuse("quota accounting arithmetic: remaining - headroom != " *
                "shortfall")
    return ea
end

function reg_main()
    fails = String[]
    gates = Dict{String, String}()
    sources = Any[]
    entries = Any[]

    # --- S1: Gate-2 binding decisions D1-D4 -------------------------------
    s1 = try
        verify_json_source(
            validation_results_path("gate4_g2_binding_decision_scaffold.json");
            expected_case = "gate4_g2_binding_decision_scaffold",
            expected_status = "g2_binding_scaffold_ready_awaiting_rulings",
            required_keys = ["decision_map"])
    catch err
        err isa RegisterRefusal || rethrow()
        push!(fails, err.reason); nothing
    end
    if s1 !== nothing
        push!(sources, s1.record)
        dmap = reg_obj(s1.data["decision_map"])
        d_keys = ("D1_dataset_binding", "D2_aggregation",
                  "D3_nonpositive_pair_policy", "D4_active_gas_lists")
        dkey_issues = gate2_dkey_issues(dmap)
        append!(fails, dkey_issues)
        d_ok = isempty(dkey_issues) &&
               all(haskey(dmap, k) &&
                   startswith(reg_str(get(reg_obj(dmap[k]), "state", "")),
                              "UNRESOLVED") for k in d_keys)
        gates["gate2_decision_map_verified_open"] = d_ok ? "passed" : "failed"
        (d_ok || !isempty(dkey_issues)) ||
            push!(fails, "scaffold decision_map D1-D4 not all UNRESOLVED")
        if d_ok
            for k in d_keys
                d = reg_obj(dmap[k])
                push!(entries, Dict(
                    "id" => "R-G2-" * split(k, "_")[1],
                    "title" => "Gate-2 binding decision $k",
                    "status" => "OPEN",
                    "deciding_authority" => "UNASSIGNED",
                    "options_from_source" => Dict(f => d[f] for f in keys(d)
                                                  if f != "state"),
                    "source_paths" => [s1.record["path"]],
                    "unblocks" => "the binding Gate-2 true-OD runner " *
                        "(with the other D rulings)"))
            end
        end
    else
        gates["gate2_decision_map_verified_open"] = "failed"
    end

    # --- S2: thresholds 4-5 four open axes --------------------------------
    s2 = try
        verify_md_source(
            joinpath(@__DIR__, "gate4_regression_margin_semantics_evidence.md");
            required_anchors = ["## OPEN AXES", "1. **Pairing**",
                                "2. **Forcing combination**",
                                "3. **Heating RMSE aggregation**",
                                "4. (Interacts with the above)"])
    catch err
        err isa RegisterRefusal || rethrow()
        push!(fails, err.reason); nothing
    end
    gates["thresholds45_axes_source_verified"] =
        s2 === nothing ? "failed" : "passed"
    if s2 !== nothing
        push!(sources, s2.record)
        axes45 = [
            ("R-T45-AX1", "pairing: max paired per-scenario delta vs " *
             "difference of model-level worsts"),
            ("R-T45-AX2", "forcing combination: TOA/surface conjunction " *
             "vs max of the two deltas (no combined scalar exists in any " *
             "primary source)"),
            ("R-T45-AX3", "heating-RMSE aggregation: per-case deltas vs " *
             "worst-case delta vs pooled (no pooled precedent in the " *
             "canonical published-accuracy path)"),
            ("R-T45-AX4", "signed vs absolute deltas ('may not regress " *
             "beyond' reads signed; recorded phrasing, not an " *
             "implementation)"),
        ]
        for (id, title) in axes45
            push!(entries, Dict(
                "id" => id,
                "title" => "Thresholds 4-5 open axis -- $title",
                "status" => "OPEN",
                "deciding_authority" => "UNASSIGNED",
                "options_from_source" => "see the OPEN AXES section of " *
                    "the pinned evidence memo (quoted options preserved " *
                    "there verbatim)",
                "source_paths" => [s2.record["path"]],
                "unblocks" => "the thresholds 4-5 regression-margin " *
                    "evaluator (with the other axes)"))
        end
    end

    # --- S3: quota Path A/D authorization ----------------------------------
    s3a = try
        verify_json_source(
            validation_results_path("gate4_g2c_eval2_fetch_checkpoint.json");
            expected_case = "gate4_g2c_eval2_fetch_checkpoint",
            expected_status = "g2c_checkpoint_blocked_by_quota")
    catch err
        err isa RegisterRefusal || rethrow()
        push!(fails, err.reason); nothing
    end
    s3b = try
        verify_json_source(
            validation_results_path("gate4_g2c_failure_ledger_4440.json");
            expected_case = "gate4_g2c_failure_ledger_4440",
            expected_status = "g2c_job_4440_failed_disk_quota",
            required_keys = ["exact_accounting_monitor_verified",
                             "timestamp_utc"])
    catch err
        err isa RegisterRefusal || rethrow()
        push!(fails, err.reason); nothing
    end
    s3c = try
        verify_md_source(
            joinpath(@__DIR__, "gate4_g2c_quota_recovery_runbook.md");
            required_anchors = ["## Path A", "## Path D",
                "idealized/{lw_spectra,sw_spectra}",
                "66 files / 217,901,253,443 B",
                "Greg's explicit",
                "authorization of the chosen path"])
    catch err
        err isa RegisterRefusal || rethrow()
        push!(fails, err.reason); nothing
    end
    quota_ok = s3a !== nothing && s3b !== nothing && s3c !== nothing
    gates["quota_path_sources_verified"] = quota_ok ? "passed" : "failed"
    # the exact full authority sentence must be present verbatim
    # (whitespace-normalized); the loose anchors alone do not prove it
    auth_ok = s3c !== nothing && authority_sentence_present(s3c.text)
    gates["exact_authority_sentence_verified"] = auth_ok ? "passed" : "failed"
    auth_ok || push!(fails, "the exact runbook authority sentence quoted " *
                            "by REG_GREG_AUTHORITY was not found " *
                            "(whitespace-normalized)")
    quota_ok = quota_ok && auth_ok
    if quota_ok
        push!(sources, s3a.record); push!(sources, s3b.record)
        push!(sources, s3c.record)
        snapshot = try
            validate_quota_snapshot(
                s3b.data["exact_accounting_monitor_verified"])
        catch err
            err isa RegisterRefusal || rethrow()
            push!(fails, err.reason); nothing
        end
        gates["quota_snapshot_arithmetic_verified"] =
            snapshot === nothing ? "failed" : "passed"
        push!(entries, Dict(
            "id" => "R-QUOTA-PATH-AD",
            "title" => "Quota recovery path authorization: Path A (uid " *
                "quota raise) vs Path D (authorization-required scoped " *
                "cleanup fallback, idealized spectra only)",
            "status" => "OPEN",
            "deciding_authority" => REG_GREG_AUTHORITY,
            "options_from_source" => Dict(
                "path_a" => "uid quota raise (runbook '## Path A', " *
                    "admin action; preserves everything)",
                "path_d_exact_byte_scope" => "authorization-required " *
                    "scoped cleanup fallback: delete " *
                    "/shared/home/greg/data/ckdmip/idealized/" *
                    "{lw_spectra,sw_spectra} ONLY: 66 files / " *
                    "217,901,253,443 B (~202.9 GiB); PRESERVE " *
                    "idealized/conc and ALL of evaluation1/ (eval1 is " *
                    "NOT in the S3 archive); remains UNAUTHORIZED " *
                    "until Greg rules"),
            "quota_snapshot_observed_at" =>
                reg_str(s3b.data["timestamp_utc"]),
            "snapshot_note" => "pinned 4440 failure-ledger accounting, " *
                "arithmetic-verified; NOT a live read -- the quota " *
                "watcher runs separately so this register stays " *
                "deterministic",
            "quota_snapshot" => snapshot,
            "standing_constraint" => "deletion, quota change, and job " *
                "submission remain UNAUTHORIZED pending this ruling",
            "source_paths" => [s3a.record["path"], s3b.record["path"],
                               s3c.record["path"]],
            "unblocks" => "G2c eval2 fetch resume -> G2d rel-415 fluxes " *
                "-> scoped preflight ready -> G3 executor " *
                "ready_awaiting_go"))
    end

    # --- guards -------------------------------------------------------------
    issues = register_entry_issues(entries)
    gates["unique_ids_and_no_election"] = isempty(issues) ? "passed" : "failed"
    append!(fails, issues)
    got_ids = sort([e["id"] for e in entries])
    gates["exact_ruling_id_set"] =
        got_ids == sort(REG_EXPECTED_IDS) ? "passed" : "failed"
    got_ids == sort(REG_EXPECTED_IDS) ||
        push!(fails, "ruling-ID set $got_ids != expected " *
                     "$(sort(REG_EXPECTED_IDS))")

    # --- guard fixtures (pure functions; tmp files) -------------------------
    t = Dict{String, Bool}()
    tdir = mktempdir()
    bad = joinpath(tdir, "bad.json")
    write(bad, "{")
    t["malformed_json_refuses"] = try
        verify_json_source(bad; expected_case = "x", expected_status = "y")
        false
    catch err; err isa RegisterRefusal &&
               occursin("unparseable", err.reason) end
    nonobj = joinpath(tdir, "nonobj.json")
    write(nonobj, "[1]")
    t["non_object_json_refuses"] = try
        verify_json_source(nonobj; expected_case = "x", expected_status = "y")
        false
    catch err; err isa RegisterRefusal &&
               occursin("case mismatch", err.reason) end
    t["missing_source_refuses"] = try
        verify_json_source(joinpath(tdir, "absent.json");
                           expected_case = "x", expected_status = "y")
        false
    catch err; err isa RegisterRefusal end
    wrong = joinpath(tdir, "wrong.json")
    write(wrong, "{\"case\": \"x\", \"status\": \"tampered\"}")
    t["wrong_status_refuses"] = try
        verify_json_source(wrong; expected_case = "x",
                           expected_status = "expected")
        false
    catch err; err isa RegisterRefusal &&
               occursin("status mismatch", err.reason) end
    noanchor = joinpath(tdir, "no_anchor.md")
    write(noanchor, "# something else entirely\n")
    t["missing_anchor_refuses"] = try
        verify_md_source(noanchor; required_anchors = ["## OPEN AXES"])
        false
    catch err; err isa RegisterRefusal end
    dup = [Dict("id" => "A", "status" => "OPEN",
                "deciding_authority" => "UNASSIGNED"),
           Dict("id" => "A", "status" => "OPEN",
                "deciding_authority" => "UNASSIGNED")]
    t["duplicate_ids_detected"] =
        any(occursin("duplicate ruling IDs", i)
            for i in register_entry_issues(dup))
    resolved = [Dict("id" => "B", "status" => "RESOLVED",
                     "deciding_authority" => "UNASSIGNED")]
    t["accidental_election_detected"] =
        any(occursin("!= OPEN", i) for i in register_entry_issues(resolved))
    electkey = [Dict("id" => "C", "status" => "OPEN",
                     "deciding_authority" => "UNASSIGNED",
                     "verdict" => "oops")]
    t["forbidden_election_key_detected"] =
        any(occursin("forbidden election key", i)
            for i in register_entry_issues(electkey))
    nested = [Dict("id" => "C2", "status" => "OPEN",
                   "deciding_authority" => "UNASSIGNED",
                   "options_from_source" => Dict("alt" =>
                       Dict("chosen" => "hidden election")))]
    t["nested_forbidden_key_detected"] =
        any(occursin("forbidden election key", i) &&
            occursin("options_from_source", i)
            for i in register_entry_issues(nested))
    guessauth = [Dict("id" => "D", "status" => "OPEN",
                      "deciding_authority" => "probably the monitor")]
    t["inferred_authority_detected"] =
        any(occursin("neither UNASSIGNED nor the exact", i)
            for i in register_entry_issues(guessauth))
    fabricated = [Dict("id" => "E", "status" => "OPEN",
                       "deciding_authority" =>
                           "monitor -- explicitly assigned")]
    t["fabricated_explicit_authority_detected"] =
        any(occursin("neither UNASSIGNED nor the exact", i)
            for i in register_entry_issues(fabricated))
    badacct = Dict("source_set_bytes" => Dict("lw_35_files" => 10,
        "sw_35_files" => 5, "total_70" => 999),
        "local_finalized" => Dict("bytes" => 1),
        "remaining_bytes" => 14,
        "hard_headroom_bytes_post_failure" => 4,
        "shortfall_bytes_post_failure" => 10)
    t["malformed_accounting_detected"] = try
        validate_quota_snapshot(badacct)
        false
    catch err; err isa RegisterRefusal &&
               occursin("lw + sw != total", err.reason) end
    negacct = Dict("source_set_bytes" => Dict("lw_35_files" => -10,
        "sw_35_files" => 5, "total_70" => -5),
        "local_finalized" => Dict("bytes" => 1),
        "remaining_bytes" => -6,
        "hard_headroom_bytes_post_failure" => 4,
        "shortfall_bytes_post_failure" => -10)
    t["negative_accounting_detected"] = try
        validate_quota_snapshot(negacct)
        false
    catch err; err isa RegisterRefusal &&
               occursin("negative", err.reason) end
    d5map = Dict("D1_dataset_binding" => Dict("state" => "UNRESOLVED"),
                 "D2_aggregation" => Dict("state" => "UNRESOLVED"),
                 "D3_nonpositive_pair_policy" => Dict("state" => "UNRESOLVED"),
                 "D4_active_gas_lists" => Dict("state" => "UNRESOLVED"),
                 "D5_surprise" => Dict("state" => "UNRESOLVED"),
                 "cross_reference" => "allowed non-D key")
    t["unexpected_d5_detected"] =
        any(occursin("!= expected", i) for i in gate2_dkey_issues(d5map))
    t["near_match_authority_sentence_fails"] =
        !authority_sentence_present(replace(REG_AUTHORITY_SENTENCE,
            "Greg's" => "the monitor's"))
    nokey = [Dict("id" => "F", "title" => "t", "status" => "OPEN",
                  "deciding_authority" => "UNASSIGNED",
                  "options_from_source" => "opts",
                  "source_paths" => ["p"])]   # unblocks missing
    t["missing_core_key_detected"] =
        any(occursin("missing core schema key unblocks", i)
            for i in register_entry_issues(nokey))
    wrongtype = [Dict("id" => "G", "title" => "t", "status" => "OPEN",
                      "deciding_authority" => "UNASSIGNED",
                      "options_from_source" => "opts",
                      "source_paths" => "not-a-vector",
                      "unblocks" => "u")]
    t["wrong_type_core_key_detected"] =
        any(occursin("core key source_paths has wrong type", i)
            for i in register_entry_issues(wrongtype))
    rm(tdir, recursive = true, force = true)
    gates["guard_fixtures"] = all(values(t)) ? "passed" : "failed"
    all(values(t)) || push!(fails, "guard fixtures failed: " *
        join([k for (k, v) in t if !v], ", "))

    status = (isempty(fails) && all(v == "passed" for v in values(gates))) ?
             "pending_rulings_register_recorded" :
             "pending_rulings_register_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_pending_rulings_register",
        "data_mode" => "derivative_read_only_register",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "guard_fixture_verdicts" => t,
        "open_rulings" => entries,
        "sources" => sources,
        "provenance" => Dict("branch" => branch,
            "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working " *
                "tree before its own commit"),
        "disclaimer" => "derivative read-only register of source-proven " *
            "OPEN rulings; no election, no inferred authority, no " *
            "resolution recorded; deletion, quota change, and job " *
            "submission remain unauthorized; quota figures are an " *
            "observed-at snapshot from the pinned 4440 failure ledger, " *
            "never a live read.",
    )
    mkpath(dirname(REG_RESULTS_JSON))
    open(REG_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(REG_RESULTS_MD, "w") do io
        println(io, "# Gate-4 pending-rulings register\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Verdict |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\n## Open rulings ($(length(entries)))\n")
        for e in entries
            println(io, "- **$(e["id"])** [$(e["status"])] $(e["title"])")
            println(io, "  - deciding authority: $(e["deciding_authority"])")
            opts = e["options_from_source"]
            println(io, "  - options (from source): ",
                    opts isa AbstractDict ? stable_json(opts) : opts)
            println(io, "  - unblocks: $(e["unblocks"])")
            haskey(e, "standing_constraint") &&
                println(io, "  - constraint: $(e["standing_constraint"])")
            haskey(e, "quota_snapshot_observed_at") &&
                println(io, "  - quota snapshot observed at: " *
                            "$(e["quota_snapshot_observed_at"])")
            haskey(e, "snapshot_note") &&
                println(io, "  - snapshot note: $(e["snapshot_note"])")
            haskey(e, "quota_snapshot") &&
                println(io, "  - quota snapshot (arithmetic-verified): " *
                            stable_json(e["quota_snapshot"]))
        end
        println(io, "\n## Sources (fail-closed verified; path + sha256)\n")
        for s in sources
            println(io, "- `$(s["path"])` sha256 `$(s["sha256"])` " *
                        "($(s["kind"]))")
        end
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_pending_rulings_register: $status " *
            "($(length(entries)) open rulings)")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), first(fails, 8))
    return status == "pending_rulings_register_recorded" ? 0 : 1
end

exit(reg_main())
