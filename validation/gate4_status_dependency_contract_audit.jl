# Gate-4 STATUS/CASE-PROJECTION DEPENDENCY CONTRACT AUDIT (derivative,
# read-only; no election, no state mutation, no unit execution).
#
# SCOPE (explicit, monitor-directed): this audit verifies the STATUS/CASE
# PROJECTION of every literal JSON.parsefile-MEDIATED cross-artifact
# contract in validation/gate4*.jl (other parsing forms are outside the
# censused surface), plus four declared per-kind extensions -- the
# register snapshot-hash contract, the E9 prerequisite truth table with
# reviewed-complete ledger schema, the fingerprint-join post-hoc row
# contract, and the authority-input truth table (rulings intake:
# register health x source presence x parse shape).
# STRUCTURAL requirements beyond that projection (attempt strings, output
# hashes, arithmetic identities, boundary flags, D-key sets) are enforced
# in-unit by the consumers themselves and are OUT OF SCOPE here; they are
# listed per edge family in structural_out_of_scope.
#
# Design (second-pass, after monitor review of the first pass):
#   - a UNIFIED parse-site ledger classifies every live JSON.parsefile
#     site as `edge` (carrying the exact served edge_id(s)) or an
#     excluded class; reconciliation requires every live site matched
#     exactly once, every parsefile ledger record matched by a live
#     site, AND union(served edge IDs) == the manifest ID set -- an
#     omitted known edge can no longer pass. Consumers whose coupled
#     byte-snapshot helpers are deliberately NOT JSON.parsefile (they
#     close the hash-vs-parse TOCTOU; currently the rulings intake and
#     the post-cleanup input census) are carried as
#     declared-snapshot-extension records, source-bound directly by
#     reconciliation and forbidden from matching any live parsefile
#     site;
#   - unknown contract kinds REFUSE (never fall through);
#   - snapshot-staleness and E9 branch validation are PURE functions used
#     identically in production and fixtures; the E9 present-ledger
#     branch validates the reviewed-complete run-ledger schema (copied
#     verbatim from gate4_g3_acceptance_comparison.jl, which is not
#     include-safe);
#   - mode-dependent token sets are encoded per mode (accepted_by_mode);
#     e.g. the r2 executor's pre-execution branch REJECTS the historical
#     token;
#   - consumer contracts are modeled faithfully; status-only contracts
#     are hardening findings, never silent upgrades.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON
import SHA

const DCA_RESULTS_JSON =
    validation_results_path("gate4_status_dependency_contract_audit.json")
const DCA_RESULTS_MD =
    validation_results_path("gate4_status_dependency_contract_audit.md")

const DCA_VALIDATION_DIR = @__DIR__
const DCA_G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const DCA_R2_V14_RAW = "$DCA_G4WORK/work-v14/sw_raw-ckd-definition/" *
    "ecckd-1.4_sw_raw-ckd-definition_climate_rgb-tol0.047.nc"

struct DcaRefusal <: Exception
    reason::String
end
Base.showerror(io::IO, e::DcaRefusal) = print(io, "DcaRefusal: ", e.reason)
drefuse(reason) = throw(DcaRefusal(reason))

dca_obj(x) = x isa AbstractDict ? x : Dict{String, Any}()
dca_str(x) = x isa AbstractString ? String(x) : ""
dca_sha(p) = split(strip(read(`sha256sum $p`, String)))[1]
# nonthrowing current-state hash for live checks: a file vanishing
# between an existence check and the hash (TOCTOU) is classified
# stale/violated by the caller, never an uncaught crash
dca_try_sha(p) = try
    split(strip(read(`sha256sum $p`, String)))[1]
catch
    nothing
end

# nonthrowing BYTE snapshot for live checks where digest and parsed
# content must correspond: one read(path) supplies both, so a mid-run
# file replacement can never pair bytes B's content with bytes A's
# digest (mirrors the rulings intake's ric_snapshot)
function dca_snapshot(path)
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

const DCA_KNOWN_KINDS = (:exact, :set, :prefix, :mode_dependent,
                         :register_snapshot, :fingerprint_join,
                         :absence_tolerant, :authority_input)

# --- copied VERBATIM from gate4_g3_acceptance_comparison.jl:91-113 (that
# unit ends in exit(main()) and must never be include()d) ------------------
hex64(x) = x isa AbstractString && occursin(r"^[0-9a-f]{64}$", x)

function validate_run_ledger(ld)
    get(ld, "case", "") == "gate4_g3_run_ledger" ||
        return (false, "case != gate4_g3_run_ledger")
    get(ld, "status", "") == "reviewed-complete" ||
        return (false, "status != reviewed-complete")
    jobs = get(ld, "jobs", nothing)
    jobs isa AbstractDict || return (false, "missing jobs section")
    for band in ("lw", "sw")
        j = get(jobs, band, nothing)
        j isa AbstractDict || return (false, "missing jobs.$band")
        jid = get(j, "job_id", nothing)
        jid_ok = (jid isa Integer && jid > 0) ||
            (jid isa AbstractString && occursin(r"^[0-9]+$", jid) &&
             tryparse(Int, jid) !== nothing && tryparse(Int, jid) > 0)
        jid_ok || return (false, "jobs.$band.job_id not a positive numeric id")
        get(j, "exit_code", -1) == 0 || return (false, "jobs.$band.exit_code != 0")
        for f in ("sbatch_sha256", "log_sha256", "output_sha256")
            hex64(get(j, f, "")) || return (false, "jobs.$band.$f not 64-hex")
        end
    end
    return (true, "ok")
end
# ---------------------------------------------------------------------------

# --- PURE validators (used identically in production and fixtures) ---------
# register snapshot-hash contract: recorded source sha/case/status vs the
# CURRENT producer facts
dca_snapshot_stale(recorded, cur_sha, cur_case, cur_status) =
    dca_str(get(recorded, "sha256", "")) != cur_sha ||
    dca_str(get(recorded, "verified_case", "")) != cur_case ||
    dca_str(get(recorded, "verified_status", "")) != cur_status

# PURE hardening-findings constructor (fixture-run with synthetic
# verdicts): status-only contracts and explicitly classified self-test
# states are surfaced as FINDINGS, never failures; production and the
# fixture share this exact code
function dca_hardening_findings(verdicts)
    h = [Dict("id" => v["id"],
              "finding" => "status-only contract (no case check); " *
                  "weakness, not a violation")
         for v in verdicts if get(v, "status_only_contract", false)]
    for v in verdicts
        get(v, "verdict", "") == "consumer_selftest_state" &&
            push!(h, Dict("id" => v["id"],
                "finding" => "consumer is in its self-test-failure " *
                    "status; classified explicitly, not a dependency " *
                    "inconsistency"))
    end
    return h
end

# authority-input truth table (pure; fixture-tested): the faithful
# rulings-intake statuses given register health, source presence, and
# parse shape. The intake's deeper semantics (assignment schema, pin,
# authority, vocabulary) are its own fail-closed enforcement -- for a
# present parseable object BOTH recorded and refused are faithful states.
function dca_authority_input_allowed(reg_stale, present, parse_success,
                                     object_ok)
    reg_stale && return ["rulings_intake_blocked_register_stale"]
    present || return ["rulings_intake_awaiting_assignments"]
    (parse_success === true && object_ok === true) ||
        return ["rulings_intake_refused"]
    return ["rulings_intake_assignments_recorded",
            "rulings_intake_refused"]
end

# E9 prerequisite truth table (FAITHFUL to both consumers: G1 and G3
# check recovered OUTPUTS before RUN_LEDGER):
#   outputs absent                       -> waiting (whether the ledger is
#                                           absent OR present)
#   outputs present + ledger absent      -> blocked_missing_run_ledger
#   outputs present + ledger UNPARSEABLE -> catches_parse_errors
#     consumers classify blocked_invalid; a consumer WITHOUT the guard
#     would be an execution/refusal GAP with NO faithful emitted status
#     (empty allowed set). BOTH campaign consumers now guard (G1's
#     try/catch; G3's classify_run_ledger loader, which closed the
#     former standing gap) -- the gap branch stays representable and
#     fixture-tested so any future unguarded consumer is still modeled
#     faithfully
#   outputs present + parseable schema-invalid -> blocked_invalid
#   outputs present + ledger valid      -> only the consumer-specific
#                                           downstream status set
# tokens = (waiting, missing, invalid, downstream::Vector)
# parse_success = JSON.parsefile completed without throwing (a ledger
# containing JSON null PARSES successfully to nothing -- it is NOT a
# parse failure); object_ok = the parsed value is an object. G1 and G3
# both map unparseable AND parsed-non-object to blocked_invalid (G3 via
# its classify_run_ledger guarded loader); the no-guard style remains a
# valid input to this pure function and is exercised by fixtures.
function dca_e9_allowed_statuses(outputs_present, ledger_present,
                                 parse_success, object_ok, schema_ok,
                                 tokens;
                                 catches_parse_errors,
                                 maps_nonobject_to_invalid)
    outputs_present || return [tokens.waiting]
    ledger_present || return [tokens.missing]
    parse_success === true ||
        return catches_parse_errors ? [tokens.invalid] : String[]
    object_ok === true ||
        return maps_nonobject_to_invalid ? [tokens.invalid] : String[]
    schema_ok === true || return [tokens.invalid]
    return tokens.downstream
end

# self-test claims must be corroborated by artifact evidence, never by
# the status string alone
dca_selftest_evidence_ok(d) =
    dca_str(get(d, "data_mode", "")) == "selftest_failure" ||
    !isempty(get(d, "failures", Any[])) ||
    any(v === false for v in values(dca_obj(get(d, "selftests", nothing))))

# manifest-inventory hygiene, checked BEFORE any Dict collapse (mirrors
# the consumers' first-match/only(filter) semantics): blank or duplicate
# labels make label-joins ambiguous
function dca_inventory_issues(entries)
    issues = String[]
    labels = String[]
    for x in entries
        lbl = dca_str(get(dca_obj(x), "label", ""))
        isempty(lbl) && push!(issues, "blank label in manifest inventory")
        push!(labels, lbl)
    end
    length(unique(labels)) == length(labels) ||
        push!(issues, "duplicate labels in manifest inventory")
    return issues
end

# self-test precedence classification: both consumers can emit a
# self-test-failure status regardless of the prerequisite state (G3
# before output checks; G1 as a final override). That state is
# classified explicitly -- it is NOT a dependency inconsistency.
dca_e9_verdict_class(cstat, allowed, selftest_status) =
    cstat == selftest_status ? :consumer_selftest_state :
    cstat in allowed ? :satisfied : :violated

# recovered-output paths (identical constants in BOTH consumers)
const DCA_LW_RECOVERED = "$DCA_G4WORK/work/lw_ckd-definition/" *
    "ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc"
const DCA_SW_RECOVERED = "$DCA_G4WORK/work-v14/sw_ckd-definition/" *
    "ecckd-1.4_sw_ckd-definition_climate_rgb-tol0.047.nc"

# ============================================================================
# DECLARATIVE DATA
# ============================================================================

const DCA_SW_SCALED = "$DCA_G4WORK/work-v14/sw_raw-ckd-definition/" *
    "ecckd-1.4_sw_scaled-ckd-definition_climate_rgb-tol0.047.nc"

function dca_modes()
    a2_sub = try
        JSON.parsefile(validation_results_path("gate4_a2_submission_ledger.json"))
    catch; nothing end
    a2_hist = dca_str(get(dca_obj(a2_sub), "status", "")) ==
              "a2_attempt2_completed_candidates_collected"
    return (a2 = a2_hist ? :historical : :preexecution,
            r2 = isfile(DCA_R2_V14_RAW) ? :historical : :preexecution,
            # PRESENCE semantics, not verification semantics: the audit
            # only observes that a scaled output EXISTS -- whether it is
            # historical (path+sha verified) or anomaly is the
            # CONSUMER's classification; the ledger edge is active for
            # the whole output-present branch either way
            sw_init = isfile(DCA_SW_SCALED) ? :output_present :
                                              :preexecution,
            g3_ledger_present =
                isfile(validation_results_path("gate4_g3_run_ledger.json")))
end

# Edge fields: id, consumer, anchors, producer, kind, accepted (or
# accepted_by_mode + mode_axis), expected_case, consumer_checks_case
# (ACTUAL contract), status_only (hardening flag), active_when
const DCA_EDGES = [
 # HARDENED consumer: classify_pinned_artifact binds exact case+status
 # for BOTH pinned inputs; the sbatch write is allowlist-gated to
 # pre-execution mode; the init-provenance ledger is consulted ONLY in
 # historical mode (post-execution evidence, its own edge below)
 (id = "dep:sw_init_checkpoint<-option_b", consumer = "gate4_sw_init_generation_checkpoint.jl",
  anchors = ["ob_ok, ob_why, _ = classify_pinned_artifact(",
             "\"gate4_option_b_decision_record\",",
             "\"option_b_adopted_candidates_promoted\")",
             "sbatch_written = si_write_script("],
  producer = "gate4_option_b_decision_record.json", kind = :exact,
  accepted = ["option_b_adopted_candidates_promoted"],
  expected_case = "gate4_option_b_decision_record",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:sw_init_checkpoint<-init_provenance_ledger:output_present",
  consumer = "gate4_sw_init_generation_checkpoint.jl",
  # OUTPUT-PRESENT evidence edge: loaded whenever a scaled output
  # exists; whether that output is historical (path+sha verified) or
  # anomaly is the CONSUMER's classification -- the audit gates only on
  # presence, never calling unverified evidence historical. The
  # ledger-recorded sha must verify the live output through a
  # path-bound (root-resolved, normalized-equality) record.
  anchors = ["il_ok, il_why, il = classify_pinned_artifact(",
             "\"gate4_init_provenance_ledger\",",
             "\"acceptance_inits_complete\")",
             "si_ledger_sw_matches(rec, SW_SCALED)"],
  producer = "gate4_init_provenance_ledger.json", kind = :exact,
  accepted = ["acceptance_inits_complete"],
  expected_case = "gate4_init_provenance_ledger",
  consumer_checks_case = true, status_only = false,
  active_when = :sw_init_output_present),
 # HARDENED consumer: rp_parse_pinned binds exact case+status for ALL
 # FOUR pinned inputs (five fixed refusal classes); deep ledger fields
 # and the promotion scan go through pure navigators shared with the
 # unit's fixtures (former status-only findings on the r1 and option-B
 # edges CLOSED). R1 stays active in BOTH modes; the three ledger edges
 # stay historical-only. No write boundary: the unit writes nothing but
 # its own results.
 (id = "dep:r2_proof_scaffold<-r1_probe", consumer = "gate4_r2_sw_matching_version_proof_scaffold.jl",
  anchors = ["r1_ok, r1_why, _ = rp_parse_pinned(",
             "\"gate4_r1_release_provenance_probe\",",
             "\"r1_sw_mapping_found_lw_ambiguous\")"],
  producer = "gate4_r1_release_provenance_probe.json", kind = :exact,
  accepted = ["r1_sw_mapping_found_lw_ambiguous"],
  expected_case = "gate4_r1_release_provenance_probe",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:r2_proof_scaffold<-r2_finding_ledger:historical",
  consumer = "gate4_r2_sw_matching_version_proof_scaffold.jl",
  anchors = ["fin_ok, fin_why, fin = rp_parse_pinned(",
             "\"gate4_r2_finding_ledger\",",
             "\"r2_ssi_resolved_drift_version_independent\")",
             "exp_bin, exp_out = rp_finding_shas(fin)"],
  producer = "gate4_r2_finding_ledger.json", kind = :mode_dependent,
  accepted = ["r2_ssi_resolved_drift_version_independent"],
  expected_case = "gate4_r2_finding_ledger",
  consumer_checks_case = true, status_only = false,
  active_when = :r2_historical),
 (id = "dep:r2_proof_scaffold<-option_b:historical",
  consumer = "gate4_r2_sw_matching_version_proof_scaffold.jl",
  anchors = ["ob_ok0, ob_why, ob = rp_parse_pinned(",
             "\"gate4_option_b_decision_record\",",
             "\"option_b_adopted_candidates_promoted\")",
             "rp_has_promoted_sha(ob, exp_out)"],
  producer = "gate4_option_b_decision_record.json", kind = :mode_dependent,
  accepted = ["option_b_adopted_candidates_promoted"],
  expected_case = "gate4_option_b_decision_record",
  consumer_checks_case = true, status_only = false,
  active_when = :r2_historical),
 (id = "dep:r2_proof_scaffold<-init_provenance_ledger:historical",
  consumer = "gate4_r2_sw_matching_version_proof_scaffold.jl",
  anchors = ["ip_ok, ip_why, ip = rp_parse_pinned(",
             "\"gate4_init_provenance_ledger\",",
             "\"acceptance_inits_complete\")"],
  producer = "gate4_init_provenance_ledger.json", kind = :mode_dependent,
  accepted = ["acceptance_inits_complete"],
  expected_case = "gate4_init_provenance_ledger",
  consumer_checks_case = true, status_only = false,
  active_when = :r2_historical),
 # HARDENED consumer: rx_classify_scaffold binds the exact case before
 # the FAITHFUL mode-dependent status sets; parse/missing/non-object
 # are three fixed distinct refusal classes; the pre-execution sbatch
 # write is allowlist-gated (former status-only finding CLOSED)
 (id = "dep:r2_exec_checkpoint<-r2_proof_scaffold",
  consumer = "gate4_r2_execution_checkpoint.jl",
  anchors = ["scaffold_ok, scaffold_why = rx_classify_scaffold(scaffold_obj,",
             "c == \"gate4_r2_sw_matching_version_proof_scaffold\"",
             "s in (\"r2_scaffold_ready_awaiting_authorization\",",
             "sbatch_written = rx_write_script("],
  producer = "gate4_r2_sw_matching_version_proof_scaffold.json",
  kind = :mode_dependent,
  # FAITHFUL mode-specific sets: the pre-execution branch REJECTS the
  # historical token
  accepted_by_mode = Dict(
      :historical => ["r2_scaffold_ready_awaiting_authorization",
                      "r2_scaffold_historical_executed"],
      :preexecution => ["r2_scaffold_ready_awaiting_authorization"]),
  mode_axis = :r2,
  expected_case = "gate4_r2_sw_matching_version_proof_scaffold",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:r2_exec_checkpoint<-r2_finding_ledger:historical",
  consumer = "gate4_r2_execution_checkpoint.jl",
  anchors = ["fin_ok = as_str(get(fin_obj, \"case\", \"\")) ==",
             "\"r2_ssi_resolved_drift_version_independent\""],
  producer = "gate4_r2_finding_ledger.json", kind = :mode_dependent,
  accepted = ["r2_ssi_resolved_drift_version_independent"],
  expected_case = "gate4_r2_finding_ledger",
  consumer_checks_case = true, status_only = false,
  active_when = :r2_historical),
 # HARDENED consumer: ps_classify_exec_checkpoint binds the exact case
 # before the FAITHFUL accepted set (both the pre-execution and
 # historical-executed tokens; pure membership helper shared with
 # fixtures); fail-closed gate census before status selection; the unit
 # executes nothing and writes only its own results (former status-only
 # finding CLOSED)
 (id = "dep:a2_proof_scaffold<-a2_exec_checkpoint",
  consumer = "gate4_a2_reproduction_proof_scaffold.jl",
  anchors = ["chk_ok, chk_why = ps_classify_exec_checkpoint(",
             "c == \"gate4_a2_execution_checkpoint\"",
             "status in (\"a2_execution_checkpoint_ready\",",
             "\"a2_execution_checkpoint_historical_executed\")",
             "ps_exec_status_accepted(st)"],
  producer = "gate4_a2_execution_checkpoint.json", kind = :set,
  accepted = ["a2_execution_checkpoint_ready",
              "a2_execution_checkpoint_historical_executed"],
  expected_case = "gate4_a2_execution_checkpoint",
  consumer_checks_case = true, status_only = false, active_when = :always),
 # HARDENED consumer: pd_parse_pinned binds exact case+status for ALL
 # FOUR pinned inputs (the finding/submission ledgers gain the exact
 # status binding matching this manifest's pinned accepted sets -- the
 # submission token is historically pre-completion; completion evidence
 # lives separately in finding proof_run.outcome); deep fields and the
 # supersedes scan go through pure navigators shared with the unit's
 # fixtures; ledger shas are 64-hex validated before hashing; the
 # pre-execution write is allowlist-gated (former status-only findings
 # on the scaffold and option-B edges CLOSED). Historical/partial paths
 # are structurally write-free.
 (id = "dep:a2_proof_driver<-a2_proof_scaffold",
  consumer = "gate4_a2_proof_driver_checkpoint.jl",
  anchors = ["scaffold_ok, scaffold_why, _ = pd_parse_pinned(",
             "\"gate4_a2_reproduction_proof_scaffold\",",
             "\"a2_proof_scaffold_ready\")",
             "sbatch_written = pd_write_script("],
  producer = "gate4_a2_reproduction_proof_scaffold.json", kind = :exact,
  accepted = ["a2_proof_scaffold_ready"],
  expected_case = "gate4_a2_reproduction_proof_scaffold",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:a2_proof_driver<-a2_proof_finding_ledger:historical",
  consumer = "gate4_a2_proof_driver_checkpoint.jl",
  anchors = ["fin_ok, fin_why, fin = pd_parse_pinned(PD_FINDING_LEDGER,",
             "\"gate4_a2_proof_finding_ledger\",",
             "\"a2_candidates_sensitivity_only_not_promotable\")"],
  producer = "gate4_a2_proof_finding_ledger.json", kind = :mode_dependent,
  accepted = ["a2_candidates_sensitivity_only_not_promotable"],
  expected_case = "gate4_a2_proof_finding_ledger",
  consumer_checks_case = true, status_only = false,
  active_when = :a2_historical),
 (id = "dep:a2_proof_driver<-a2_proof_submission_ledger:historical",
  consumer = "gate4_a2_proof_driver_checkpoint.jl",
  anchors = ["sub_ok, sub_why, sub = pd_parse_pinned(PD_SUBMISSION_LEDGER,",
             "\"gate4_a2_proof_submission_ledger\",",
             "\"proof_run_submitted_awaiting_completion\")"],
  producer = "gate4_a2_proof_submission_ledger.json", kind = :mode_dependent,
  accepted = ["proof_run_submitted_awaiting_completion"],
  expected_case = "gate4_a2_proof_submission_ledger",
  consumer_checks_case = true, status_only = false,
  active_when = :a2_historical),
 (id = "dep:a2_proof_driver<-option_b:historical",
  consumer = "gate4_a2_proof_driver_checkpoint.jl",
  anchors = ["ob_ok0, ob_why, ob = pd_parse_pinned(",
             "\"gate4_option_b_decision_record\",",
             "\"option_b_adopted_candidates_promoted\")",
             "pd_ob_supersedes_scaffold(ob)"],
  producer = "gate4_option_b_decision_record.json", kind = :mode_dependent,
  accepted = ["option_b_adopted_candidates_promoted"],
  expected_case = "gate4_option_b_decision_record",
  consumer_checks_case = true, status_only = false,
  active_when = :a2_historical),
 (id = "dep:a2_exec_checkpoint<-a2_submission_ledger:mode_selection",
  consumer = "gate4_a2_execution_checkpoint.jl",
  anchors = ["\"a2_attempt2_completed_candidates_collected\""],
  producer = "gate4_a2_submission_ledger.json", kind = :mode_dependent,
  accepted = ["a2_attempt2_completed_candidates_collected"],
  expected_case = "gate4_a2_submission_ledger",
  consumer_checks_case = true, status_only = false, active_when = :always),
 # HARDENED consumer: ax_classify_rerun_manifest binds the exact case
 # before the exact status; BINDING ruling -- accepted is ONLY
 # a2_manifest_ready, so the current live waiting token
 # (a2_manifest_ready_waiting_for_inputs) is rejected and blocks
 # pre-execution (named fixture); the pre-execution write is
 # allowlist-gated; historical/anomaly never write. The branch is
 # INACTIVE live (a2 mode historical); its contract is fixture-verified
 # offline through the same production classifier.
 (id = "dep:a2_exec_checkpoint<-a2_rerun_manifest:preexecution",
  consumer = "gate4_a2_execution_checkpoint.jl",
  anchors = ["manifest_ok, manifest_why = ax_classify_rerun_manifest(",
             "c == \"gate4_a2_find_g_points_rerun_manifest\"",
             "st == \"a2_manifest_ready\"",
             "sbatch_written = ax_write_script("],
  producer = "gate4_a2_find_g_points_rerun_manifest.json",
  kind = :mode_dependent,
  accepted = ["a2_manifest_ready"],
  expected_case = "gate4_a2_find_g_points_rerun_manifest",
  consumer_checks_case = true, status_only = false,
  active_when = :a2_preexecution),
 (id = "dep:a2_exec_checkpoint<-a2_proof_finding_ledger:later_disposition",
  consumer = "gate4_a2_execution_checkpoint.jl",
  anchors = ["ax_str(get(pf, \"case\", \"\")) == \"gate4_a2_proof_finding_ledger\""],
  producer = "gate4_a2_proof_finding_ledger.json", kind = :mode_dependent,
  accepted = ["a2_candidates_sensitivity_only_not_promotable"],
  expected_case = "gate4_a2_proof_finding_ledger",
  consumer_checks_case = true, status_only = false,
  active_when = :a2_historical),
 (id = "dep:a2_exec_checkpoint<-option_b:later_disposition",
  consumer = "gate4_a2_execution_checkpoint.jl",
  anchors = ["ax_str(get(ob, \"case\", \"\")) == \"gate4_option_b_decision_record\""],
  producer = "gate4_option_b_decision_record.json", kind = :mode_dependent,
  accepted = ["option_b_adopted_candidates_promoted"],
  expected_case = "gate4_option_b_decision_record",
  consumer_checks_case = true, status_only = false,
  active_when = :a2_historical),
 # HARDENED consumer: am_classify_a1 binds the exact case before the
 # exact status (the A1 network producer is never rerun; only its
 # committed artifact is parsed); five fixed refusal classes with the
 # operative-path caveat kept ONLY on the parsed wrong-status class;
 # fail-closed gate census before status selection; the unit executes
 # nothing and writes only its own results (former status-only finding
 # CLOSED)
 (id = "dep:a2_rerun_manifest<-a1_upstream_recon",
  consumer = "gate4_a2_find_g_points_rerun_manifest.jl",
  anchors = ["a1_ok, a1_why = am_classify_a1(",
             "c == \"gate4_a1_upstream_recon\"",
             "st == \"a1_recon_no_exact_upstream_source_found\""],
  producer = "gate4_a1_upstream_recon.json", kind = :exact,
  accepted = ["a1_recon_no_exact_upstream_source_found"],
  expected_case = "gate4_a1_upstream_recon",
  consumer_checks_case = true, status_only = false, active_when = :always),
 # HARDENED consumer: classify_scaffold_artifact binds the exact case
 # before the FAITHFUL prefix status check; classification runs before
 # any pinned-script read/walk and short-circuits all downstream gates
 # to blocked_prerequisite; consumed manifest fields go through a safe
 # navigator (former status-only finding CLOSED)
 (id = "dep:init_generation_manifest<-g2_g3_runner_scaffold",
  consumer = "gate4_init_generation_manifest.jl",
  anchors = ["scaffold_ok, scaffold_why, scaffold = classify_scaffold_artifact(",
             "c == \"gate4_g2_g3_runner_scaffold\"",
             "startswith(s, \"runner_scaffold_ready\")",
             "ig_first_incode(scaffold, "],
  producer = "gate4_g2_g3_runner_scaffold.json", kind = :prefix,
  accepted = "runner_scaffold_ready",
  expected_case = "gate4_g2_g3_runner_scaffold",
  consumer_checks_case = true, status_only = false, active_when = :always),
 # HARDENED consumer: classify_green_audit binds the exact case before
 # the status comparison and classifies missing/unparseable/non-object
 # fail-closed; downstream building sits behind an exception-catching
 # allowlist boundary (former status-only findings CLOSED)
 (id = "dep:g2_g3_runner_scaffold<-stage_config_audit",
  consumer = "gate4_g2_g3_runner_scaffold.jl",
  anchors = ["\"gate4_stage_config_audit\", \"stage_config_audit_passed\"",
             "okp, why, data = classify_green_audit(path, ecase, estatus)",
             "rs_should_build(prereq_state) = prereq_state == \"green\""],
  producer = "gate4_stage_config_audit.json", kind = :exact,
  accepted = ["stage_config_audit_passed"],
  expected_case = "gate4_stage_config_audit",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:g2_g3_runner_scaffold<-covariance_stride_audit",
  consumer = "gate4_g2_g3_runner_scaffold.jl",
  anchors = ["\"covariance_stride_audit_passed\"",
             "\"gate4_covariance_stride_audit\"",
             "okp, why, data = classify_green_audit(path, ecase, estatus)"],
  producer = "gate4_covariance_stride_audit.json", kind = :exact,
  accepted = ["covariance_stride_audit_passed"],
  expected_case = "gate4_covariance_stride_audit",
  consumer_checks_case = true, status_only = false, active_when = :always),
 # HARDENED consumer: classify_init_ledger binds the exact case before
 # the faithful exact-status comparison, and the sbatch write is gated
 # on the classified prerequisite (former status-only finding CLOSED)
 (id = "dep:g2a_checkpoint<-init_provenance_ledger",
  consumer = "gate4_g2a_sw_rgb_flux_checkpoint.jl",
  anchors = ["init_ok, init_why, _ = classify_init_ledger(",
             "c == \"gate4_init_provenance_ledger\"",
             "s == \"acceptance_inits_complete\"",
             "sbatch_written = ga_write_script("],
  producer = "gate4_init_provenance_ledger.json", kind = :exact,
  accepted = ["acceptance_inits_complete"],
  expected_case = "gate4_init_provenance_ledger",
  consumer_checks_case = true, status_only = false, active_when = :always),
 # HARDENED consumer: classify_g2a_ledger binds the exact case before
 # the faithful exact-status comparison, and the sbatch write is gated
 # on the classified prerequisite (former status-only finding CLOSED)
 (id = "dep:g2b_checkpoint<-g2a_data_ledger",
  consumer = "gate4_g2b_sw_rgb_variants_checkpoint.jl",
  anchors = ["g2a_ok, g2a_why, _ = classify_g2a_ledger(",
             "c == \"gate4_g2a_data_ledger\"",
             "s == \"sw_rgb_rel_training_fluxes_installed_and_verified\"",
             "sbatch_written = gb_write_script("],
  producer = "gate4_g2a_data_ledger.json", kind = :exact,
  accepted = ["sw_rgb_rel_training_fluxes_installed_and_verified"],
  expected_case = "gate4_g2a_data_ledger",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:g3_executor<-scoped_preflight",
  consumer = "gate4_g3_executor_checkpoint.jl",
  # HARDENED consumer: classify_scoped_preflight binds the exact case
  # before the status ladder and classifies missing/unparseable/
  # non-object/unknown-status fail-closed; generation is allowlist-gated
  # behind the classified state (former status-only finding CLOSED)
  anchors = ["pf_state, pf_reason = classify_scoped_preflight(",
             "c == \"gate4_g3_scoped_input_preflight\"",
             "s == \"g3_scoped_preflight_ready\"",
             "gx_should_generate(pf_state) = pf_state in (\"waiting\", \"ready\")"],
  producer = "gate4_g3_scoped_input_preflight.json", kind = :set,
  # FAITHFUL: the executor tolerates waiting-for-eval2 (its own status
  # becomes g3_executor_waiting_for_eval2, accepted exit-0); only the
  # ready->go path needs g3_scoped_preflight_ready
  accepted = ["g3_scoped_preflight_ready",
              "g3_scoped_preflight_waiting_for_eval2"],
  expected_case = "gate4_g3_scoped_input_preflight",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:g2_binding_scaffold<-gate2_od_dataset_manifest:fingerprint_join",
  consumer = "gate4_g2_binding_decision_scaffold.jl",
  anchors = ["function manifest_fingerprint(scenario_path)"],
  producer = "gate4_gate2_od_dataset_manifest.json",
  kind = :fingerprint_join,
  accepted = String[],
  expected_case = "gate4_gate2_od_dataset_manifest",
  consumer_checks_case = false, status_only = false, active_when = :always),
 (id = "dep:rulings_register<-g2_binding_scaffold",
  consumer = "gate4_pending_rulings_register.jl",
  anchors = ["expected_status = \"g2_binding_scaffold_ready_awaiting_rulings\""],
  producer = "gate4_g2_binding_decision_scaffold.json",
  kind = :register_snapshot,
  accepted = ["g2_binding_scaffold_ready_awaiting_rulings"],
  expected_case = "gate4_g2_binding_decision_scaffold",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:rulings_register<-g2c_fetch_checkpoint",
  consumer = "gate4_pending_rulings_register.jl",
  anchors = ["expected_status = \"g2c_checkpoint_ready\""],
  producer = "gate4_g2c_eval2_fetch_checkpoint.json",
  kind = :register_snapshot,
  accepted = ["g2c_checkpoint_ready"],
  expected_case = "gate4_g2c_eval2_fetch_checkpoint",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:rulings_register<-g2c_failure_ledger_4440",
  consumer = "gate4_pending_rulings_register.jl",
  anchors = ["expected_status = \"g2c_job_4440_failed_disk_quota\""],
  producer = "gate4_g2c_failure_ledger_4440.json",
  kind = :register_snapshot,
  accepted = ["g2c_job_4440_failed_disk_quota"],
  expected_case = "gate4_g2c_failure_ledger_4440",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:rulings_intake<-pending_rulings_register",
  consumer = "gate4_rulings_intake_contract.jl",
  anchors = ["const RIC_EXPECTED_CASE = \"gate4_pending_rulings_register\"",
             "const RIC_EXPECTED_STATUS = \"pending_rulings_register_recorded\"",
             "ric_source_set_issues", "ric_source_staleness"],
  producer = "gate4_pending_rulings_register.json", kind = :exact,
  accepted = ["pending_rulings_register_recorded"],
  expected_case = "gate4_pending_rulings_register",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:rulings_intake<-rulings_assignment:authority_input",
  consumer = "gate4_rulings_intake_contract.jl",
  # the producer is a HUMAN-AUTHORED input in validation/ (absent =
  # legitimate awaiting state; never written by any unit); the intake's
  # canonical artifact must faithfully track register health + source
  # presence + parse shape
  anchors = ["const RIC_ASSIGNMENT_PATH = joinpath(@__DIR__, \"gate4_rulings_assignment.json\")",
             "present = isfile(RIC_ASSIGNMENT_PATH)",
             "ric_current_status(reg_healthy, present, parse_success,",
             "never_written_by_this_unit"],
  producer = "gate4_rulings_assignment.json", kind = :authority_input,
  accepted = ["rulings_intake_awaiting_assignments",
              "rulings_intake_assignments_recorded",
              "rulings_intake_blocked_register_stale",
              "rulings_intake_refused"],
  selftest_status = "rulings_intake_selftest_failed",
  expected_case = "gate4_rulings_intake_contract",
  consumer_checks_case = true, status_only = false, active_when = :always),
 # post-cleanup census source edges: these bind the census to the exact
 # case+status it verified at authoring; when the g2c/preflight statuses
 # legitimately change (post-resume), these edges flag the census stale
 # for deliberate revision (same pattern as the register edges)
 (id = "dep:post_cleanup_census<-g3_scoped_preflight",
  consumer = "gate4_post_cleanup_input_census.jl",
  anchors = ["const PCC_PREFLIGHT_JSON =",
             "const PCC_PREFLIGHT_SHA =",
             "\"gate4_g3_scoped_input_preflight\"",
             "\"g3_scoped_preflight_ready\", PCC_PREFLIGHT_SHA"],
  producer = "gate4_g3_scoped_input_preflight.json", kind = :exact,
  accepted = ["g3_scoped_preflight_ready"],
  expected_case = "gate4_g3_scoped_input_preflight",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:g3_scoped_preflight<-g2d_completion_ledger",
  consumer = "gate4_g3_scoped_input_preflight.jl",
  anchors = ["pf_classify_g2d_ledger(PF_LEDGER_JSON)",
             "const PF_LEDGER_SHA =",
             "\"g2d_flux_completed_verified\"",
             "\"gate4_g2d_flux_completion_ledger\""],
  producer = "gate4_g2d_flux_completion_ledger.json", kind = :exact,
  accepted = ["g2d_flux_completed_verified"],
  expected_case = "gate4_g2d_flux_completion_ledger",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:post_cleanup_census<-g2c_fetch_checkpoint",
  consumer = "gate4_post_cleanup_input_census.jl",
  anchors = ["const PCC_G2C_JSON =",
             "\"gate4_g2c_eval2_fetch_checkpoint\"",
             "\"g2c_checkpoint_ready\""],
  producer = "gate4_g2c_eval2_fetch_checkpoint.json", kind = :exact,
  accepted = ["g2c_checkpoint_ready"],
  expected_case = "gate4_g2c_eval2_fetch_checkpoint",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:g2d_checkpoint<-g2c_completion_ledger",
  consumer = "gate4_g2d_eval2_rel415_flux_checkpoint.jl",
  anchors = ["classify_g2c_ledger(GD_LEDGER_JSON)",
             "\"g2c_fetch_completed_verified\"",
             "\"gate4_g2c_fetch_completion_ledger\""],
  producer = "gate4_g2c_fetch_completion_ledger.json", kind = :exact,
  accepted = ["g2c_fetch_completed_verified"],
  expected_case = "gate4_g2c_fetch_completion_ledger",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:g2d_completion_ledger<-g2d_checkpoint",
  consumer = "gate4_g2d_flux_completion_ledger.jl",
  anchors = ["fl_classify_checkpoint(FL_CKPT_JSON)",
             "\"g2d_checkpoint_ready\"",
             "\"gate4_g2d_eval2_rel415_flux_checkpoint\""],
  producer = "gate4_g2d_eval2_rel415_flux_checkpoint.json", kind = :exact,
  accepted = ["g2d_checkpoint_ready"],
  expected_case = "gate4_g2d_eval2_rel415_flux_checkpoint",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:post_cleanup_census<-pending_rulings_register",
  consumer = "gate4_post_cleanup_input_census.jl",
  anchors = ["const PCC_REGISTER_JSON =",
             "\"gate4_pending_rulings_register\"",
             "\"pending_rulings_register_recorded\""],
  producer = "gate4_pending_rulings_register.json", kind = :exact,
  accepted = ["pending_rulings_register_recorded"],
  expected_case = "gate4_pending_rulings_register",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:r1_probe<-r2_finding_ledger:followup",
  consumer = "gate4_r1_release_provenance_probe.jl",
  anchors = ["r2_case, r2_status = dep_case_status(\"gate4_r2_finding_ledger.json\")"],
  producer = "gate4_r2_finding_ledger.json", kind = :exact,
  accepted = ["r2_ssi_resolved_drift_version_independent"],
  expected_case = "gate4_r2_finding_ledger",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:r1_probe<-option_b:followup",
  consumer = "gate4_r1_release_provenance_probe.jl",
  anchors = ["ob_case, ob_status = dep_case_status(\"gate4_option_b_decision_record.json\")"],
  producer = "gate4_option_b_decision_record.json", kind = :exact,
  accepted = ["option_b_adopted_candidates_promoted"],
  expected_case = "gate4_option_b_decision_record",
  consumer_checks_case = true, status_only = false, active_when = :always),
 # HARDENED consumer (offline contract-selftest verified; the unit's
 # normal path performs network reconnaissance and stays deliberately
 # unexecuted under the no-fetch boundary): v1_followup_status binds
 # the exact case before the status read with five fixed refusal
 # tokens; refusal tokens can never equal an accepted status, so the
 # fail-closed withholding of executed/closed claims is unchanged
 # (former status-only findings CLOSED)
 (id = "dep:v1_recon<-r1_probe:followup",
  consumer = "gate4_v1_version_skew_recon.jl",
  anchors = ["r1_status = v1_followup_status(",
             "\"gate4_r1_release_provenance_probe\")",
             "r1_status == \"r1_sw_mapping_found_lw_ambiguous\"",
             "followups_ok = v1_followups_ok(r1_status, r2_status, ob_status)"],
  producer = "gate4_r1_release_provenance_probe.json", kind = :exact,
  accepted = ["r1_sw_mapping_found_lw_ambiguous"],
  expected_case = "gate4_r1_release_provenance_probe",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:v1_recon<-r2_finding_ledger:followup",
  consumer = "gate4_v1_version_skew_recon.jl",
  anchors = ["r2_status = v1_followup_status(\"gate4_r2_finding_ledger.json\",",
             "\"gate4_r2_finding_ledger\")",
             "r2_status == \"r2_ssi_resolved_drift_version_independent\"",
             "followups_ok = v1_followups_ok(r1_status, r2_status, ob_status)"],
  producer = "gate4_r2_finding_ledger.json", kind = :exact,
  accepted = ["r2_ssi_resolved_drift_version_independent"],
  expected_case = "gate4_r2_finding_ledger",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:v1_recon<-option_b:followup",
  consumer = "gate4_v1_version_skew_recon.jl",
  anchors = ["ob_status = v1_followup_status(",
             "\"gate4_option_b_decision_record\")",
             "ob_status == \"option_b_adopted_candidates_promoted\"",
             "followups_ok = v1_followups_ok(r1_status, r2_status, ob_status)"],
  producer = "gate4_option_b_decision_record.json", kind = :exact,
  accepted = ["option_b_adopted_candidates_promoted"],
  expected_case = "gate4_option_b_decision_record",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:g1_objective_ratio<-g3_run_ledger",
  consumer = "gate4_g1_objective_ratio.jl",
  # anchors cover the consumer's ACTUAL prerequisite chain: the ledger
  # const, the waiting/missing/invalid tokens, the parse call, and the
  # schema-validator call -- not just the const path
  anchors = ["const G1OR_RUN_LEDGER = validation_results_path(\"gate4_g3_run_ledger.json\")",
             "\"g1_waiting_for_optimizer_outputs\"",
             "\"g1_blocked_missing_run_ledger\"",
             "\"g1_blocked_invalid_run_ledger\"",
             "JSON.parsefile(ledger_path)",
             "validate_run_ledger(ledger)"],
  producer = :g3_run_ledger, kind = :absence_tolerant,
  accepted = String[],
  e9_tokens = (waiting = "g1_waiting_for_optimizer_outputs",
               missing = "g1_blocked_missing_run_ledger",
               invalid = "g1_blocked_invalid_run_ledger",
               downstream = ["g1_blocked_ledger_hash_mismatch",
                             "g1_blocked_structural_mismatch",
                             "g1_blocked_boundary_compatibility_drift",
                             "g1_objective_ratio_passed",
                             "g1_objective_ratio_failed"]),
  catches_ledger_parse_errors = true,   # g1or_gate try/catches parsefile
  maps_nonobject_to_invalid = true,     # "ledger is not an object" branch
  selftest_status = "g1_selftests_failed",  # final live-status override
  # full source binding: root constant, BOTH recovered constants with
  # filename fragments, the output-first check, and G1's actual parse/
  # non-object semantics (try/catch + isa AbstractDict)
  output_anchors = ["const G1OR_G4 = \"/shared/home/greg/ecckd-derived-flux-work/g4-init-generation\"",
                    "const G1OR_LW_RECOVERED = \"\$G1OR_G4/work/lw_ckd-definition/\" *",
                    "\"ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc\"",
                    "const G1OR_SW_RECOVERED = \"\$G1OR_G4/work-v14/sw_ckd-definition/\" *",
                    "\"ecckd-1.4_sw_ckd-definition_climate_rgb-tol0.047.nc\"",
                    "(isfile(lw_path) && isfile(sw_path)) ||",
                    "ledger = try",
                    "ledger isa AbstractDict ||"],
  expected_case = "gate4_g1_objective_ratio",
  consumer_checks_case = false, status_only = false, active_when = :always),
 (id = "dep:g3_acceptance<-g3_run_ledger",
  consumer = "gate4_g3_acceptance_comparison.jl",
  anchors = ["const RUN_LEDGER = validation_results_path(\"gate4_g3_run_ledger.json\")",
             "g3_acceptance_waiting_for_optimizer_outputs",
             "g3_acceptance_blocked_missing_run_ledger",
             "g3_acceptance_blocked_invalid_run_ledger",
             "ledger, lok, lreason = classify_run_ledger(RUN_LEDGER)",
             "validate_run_ledger(ledger)"],
  producer = :g3_run_ledger, kind = :absence_tolerant,
  accepted = String[],
  e9_tokens = (waiting = "g3_acceptance_waiting_for_optimizer_outputs",
               missing = "g3_acceptance_blocked_missing_run_ledger",
               invalid = "g3_acceptance_blocked_invalid_run_ledger",
               downstream = ["g3_acceptance_blocked_ledger_hash_mismatch",
                             "g3_acceptance_structural_mismatch",
                             "g3_acceptance_incomplete_pending_objective_and_od",
                             "g3_acceptance_failed_weight_l1"]),
  # G3's classify_run_ledger guarded loader (added to close the former
  # standing gap) try/catches the parse AND rejects a parsed non-object
  # BEFORE validate_run_ledger: both shapes now classify as
  # blocked_invalid with stable reasons, matching G1
  catches_ledger_parse_errors = true,
  maps_nonobject_to_invalid = true,
  selftest_status = "g3_acceptance_selftest_failed",  # emitted BEFORE
  # the output checks
  # full source binding: root constant, BOTH recovered constants (with
  # filenames inline), the output-first check, and the exact GUARDED
  # loader/shape-check parse shapes as evidence the gap is closed
  output_anchors = ["const G4 = \"/shared/home/greg/ecckd-derived-flux-work/g4-init-generation\"",
                    "const LW_RECOVERED = \"\$G4/work/lw_ckd-definition/ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc\"",
                    "const SW_RECOVERED = \"\$G4/work-v14/sw_ckd-definition/ecckd-1.4_sw_ckd-definition_climate_rgb-tol0.047.nc\"",
                    "missing_out = [p for p in (LW_RECOVERED, SW_RECOVERED) if !isfile(p)]",
                    "ledger = try",
                    "parse_failed = true",
                    "ledger isa AbstractDict ||"],
  expected_case = "gate4_g3_acceptance_comparison",
  consumer_checks_case = false, status_only = false, active_when = :always),
]

# declarative-manifest schema/invariant validation (pure; fixture-tested)
const DCA_ALLOWED_ACTIVE_WHEN = (:always, :a2_historical,
                                 :a2_preexecution, :r2_historical,
                                 :sw_init_output_present)
function dca_manifest_issues(edges)
    issues = String[]
    for e in edges
        p = pairs(e)
        for k in (:id, :consumer, :anchors, :producer, :kind,
                  :expected_case, :consumer_checks_case, :status_only,
                  :active_when)
            haskey(p, k) ||
                push!(issues, "edge $(get(p, :id, "?")) missing field $k")
        end
        haskey(p, :kind) && !(e.kind in DCA_KNOWN_KINDS) &&
            push!(issues, "edge $(e.id) unknown kind $(e.kind)")
        haskey(p, :active_when) &&
            !(e.active_when in DCA_ALLOWED_ACTIVE_WHEN) &&
            push!(issues, "edge $(e.id) invalid active_when " *
                          "$(e.active_when)")
        if haskey(p, :accepted_by_mode)
            haskey(p, :mode_axis) && e.mode_axis in (:a2, :r2) ||
                push!(issues, "edge $(e.id) accepted_by_mode requires " *
                              "mode_axis in (:a2, :r2)")
            for m in (:historical, :preexecution)
                haskey(e.accepted_by_mode, m) ||
                    push!(issues, "edge $(e.id) accepted_by_mode missing " *
                                  "mode key $m")
            end
        elseif !haskey(p, :accepted)
            push!(issues, "edge $(get(p, :id, "?")) has neither accepted " *
                          "nor accepted_by_mode")
        end
        # status_only consistency for regular kinds: it must mirror the
        # absence of a case check
        if haskey(p, :kind) && e.kind in (:exact, :set, :prefix,
                                          :mode_dependent)
            e.status_only == !e.consumer_checks_case ||
                push!(issues, "edge $(e.id) status_only inconsistent with " *
                              "consumer_checks_case")
        end
        if haskey(p, :kind) && e.kind == :authority_input
            haskey(p, :selftest_status) || push!(issues,
                "edge $(get(p, :id, "?")) authority_input requires " *
                "selftest_status")
            if haskey(p, :accepted)
                need = ["rulings_intake_assignments_recorded",
                        "rulings_intake_awaiting_assignments",
                        "rulings_intake_blocked_register_stale",
                        "rulings_intake_refused"]
                sort(collect(e.accepted)) == sort(need) || push!(issues,
                    "edge $(get(p, :id, "?")) authority_input declared " *
                    "status universe != the exact four intake tokens")
            end
        end
        if haskey(p, :kind) && e.kind == :absence_tolerant
            for k in (:e9_tokens, :catches_ledger_parse_errors,
                      :maps_nonobject_to_invalid, :selftest_status,
                      :output_anchors)
                haskey(p, k) || push!(issues,
                    "edge $(get(p, :id, "?")) absence_tolerant requires $k")
            end
            # anchor-coverage invariant: root constant, BOTH recovered
            # constants (LW and SW), the output-first check, and a
            # parse-shape anchor must all be bound
            if haskey(p, :output_anchors)
                oa = join(e.output_anchors, "\n")
                for (label, needle) in (
                        ("root constant", "g4-init-generation"),
                        ("LW recovered", "lw_ckd-definition"),
                        ("SW recovered", "sw_ckd-definition"),
                        ("output-first check", "isfile"),
                        ("parse shape", "ledger"))
                    occursin(needle, oa) || push!(issues,
                        "edge $(get(p, :id, "?")) output_anchors missing " *
                        "$label binding ($needle)")
                end
            end
        end
    end
    return issues
end

# fingerprint post-hoc row validation (pure; fixture-tested): blank or
# duplicate labels/shas are rejected so unrelated shaped JSON cannot pass
function dca_fingerprint_row_issues(rows)
    issues = String[]
    isempty(rows) && push!(issues, "no manifest-joined rows found")
    labels = String[]
    for r in rows
        lbl = dca_str(get(r, "manifest_label", ""))
        rsha = dca_str(get(r, "manifest_sha256", ""))
        isempty(lbl) && push!(issues, "blank manifest_label in row")
        occursin(r"^[0-9a-f]{64}$", rsha) ||
            push!(issues, "row $lbl: malformed/blank manifest_sha256")
        push!(labels, lbl)
    end
    length(unique(labels)) == length(labels) ||
        push!(issues, "duplicate manifest labels among rows: $labels")
    return issues
end

# UNIFIED parse-site ledger: every live JSON.parsefile site classified as
# `edge` (with the exact served edge_ids) or an excluded class
const DCA_SITE_LEDGER = [
 (file = "gate4_a2_execution_checkpoint.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge", edge_ids = ["dep:a2_exec_checkpoint<-a2_rerun_manifest:preexecution"],
  reason = "ax_classify_rerun_manifest guarded-loader body (five fixed " *
           "refusal classes; exact-case + exact-status binding; the " *
           "waiting token is rejected per the binding ruling; live " *
           "edge inactive in historical mode + tmp loader fixtures)"),
 (file = "gate4_a2_execution_checkpoint.jl",
  anchor = "sub_exists ? JSON.parsefile(sub_path) : nothing",
  class = "edge", edge_ids = ["dep:a2_exec_checkpoint<-a2_submission_ledger:mode_selection"],
  reason = "mode-selection parse"),
 (file = "gate4_a2_execution_checkpoint.jl",
  anchor = "pf = ax_obj(try JSON.parsefile(validation_results_path(",
  class = "edge", edge_ids = ["dep:a2_exec_checkpoint<-a2_proof_finding_ledger:later_disposition"],
  reason = "later-disposition parse"),
 (file = "gate4_a2_execution_checkpoint.jl",
  anchor = "ob = ax_obj(try JSON.parsefile(validation_results_path(",
  class = "edge", edge_ids = ["dep:a2_exec_checkpoint<-option_b:later_disposition"],
  reason = "later-disposition parse"),
 (file = "gate4_a2_find_g_points_rerun_manifest.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge", edge_ids = ["dep:a2_rerun_manifest<-a1_upstream_recon"],
  reason = "am_classify_a1 guarded-loader body (five fixed refusal " *
           "classes; exact-case + exact-status binding; artifact-only " *
           "-- the A1 network producer is never rerun; live edge + tmp " *
           "loader fixtures)"),
 (file = "gate4_a2_proof_driver_checkpoint.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge",
  edge_ids = ["dep:a2_proof_driver<-a2_proof_scaffold",
              "dep:a2_proof_driver<-a2_proof_finding_ledger:historical",
              "dep:a2_proof_driver<-a2_proof_submission_ledger:historical",
              "dep:a2_proof_driver<-option_b:historical"],
  reason = "pd_parse_pinned guarded-loader body (five fixed refusal " *
           "classes; exact case+status binding; serves all four " *
           "artifact edges + tmp loader fixtures)"),
 (file = "gate4_a2_reproduction_proof_scaffold.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge", edge_ids = ["dep:a2_proof_scaffold<-a2_exec_checkpoint"],
  reason = "ps_classify_exec_checkpoint guarded-loader body (five fixed " *
           "refusal classes; exact-case + faithful accepted-set " *
           "binding; live edge + tmp loader fixtures)"),
 (file = "gate4_g1_objective_ratio.jl",
  anchor = "JSON.parsefile(ledger_path)",
  class = "edge", edge_ids = ["dep:g1_objective_ratio<-g3_run_ledger"],
  reason = "g1or_gate ledger parse (live edge + tmp ladder fixtures)"),
 (file = "gate4_g2_binding_decision_scaffold.jl",
  anchor = "m = JSON.parsefile(BDS_MANIFEST_JSON)",
  class = "edge", edge_ids = ["dep:g2_binding_scaffold<-gate2_od_dataset_manifest:fingerprint_join"],
  reason = "manifest_fingerprint helper body"),
 (file = "gate4_g2_binding_decision_scaffold.jl",
  anchor = "eval2_path = JSON.parsefile(BDS_MANIFEST_JSON)[\"inventory\"][end][\"path\"]",
  class = "fixture-support", edge_ids = String[],
  reason = "supplies the pending-eval2 refusal fixture input"),
 (file = "gate4_g2_binding_decision_scaffold.jl",
  anchor = "manifest = JSON.parsefile(BDS_MANIFEST_JSON)",
  class = "informational-read", edge_ids = String[],
  reason = "decision-map emission; gating lives in manifest_fingerprint"),
 (file = "gate4_g2_g3_runner_scaffold.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge",
  edge_ids = ["dep:g2_g3_runner_scaffold<-stage_config_audit",
              "dep:g2_g3_runner_scaffold<-covariance_stride_audit"],
  reason = "classify_green_audit guarded-loader body (exact-case " *
           "prerequisite binding; serves both prerequisite edges + tmp " *
           "loader fixtures)"),
 (file = "gate4_g2a_sw_rgb_flux_checkpoint.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge", edge_ids = ["dep:g2a_checkpoint<-init_provenance_ledger"],
  reason = "classify_init_ledger guarded-loader body (exact-case + " *
           "exact-status binding; live edge + tmp loader fixtures)"),
 (file = "gate4_g2b_sw_rgb_variants_checkpoint.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge", edge_ids = ["dep:g2b_checkpoint<-g2a_data_ledger"],
  reason = "classify_g2a_ledger guarded-loader body (exact-case + " *
           "exact-status binding; live edge + tmp loader fixtures)"),
 (file = "gate4_g2d_eval2_rel415_flux_checkpoint.jl",
  anchor = "JSON.parse(String(copy(bytes)))",
  class = "declared-snapshot-extension",
  edge_ids = ["dep:g2d_checkpoint<-g2c_completion_ledger"],
  reason = "gd_snapshot helper body: coupled byte snapshot (one read " *
           "supplies digest AND parsed content; the Unit L ledger pin " *
           "is a sha-over-the-same-bytes check), deliberately NOT " *
           "JSON.parsefile -- source-bound directly by reconcile; the " *
           "same helper also parses fixture tmp files"),
 (file = "gate4_g2d_flux_completion_ledger.jl",
  anchor = "JSON.parse(String(copy(bytes)))",
  class = "declared-snapshot-extension",
  edge_ids = ["dep:g2d_completion_ledger<-g2d_checkpoint"],
  reason = "fl_snapshot helper body: coupled byte snapshot (one read " *
           "supplies digest AND parsed content; the checkpoint pin is " *
           "a sha-over-the-same-bytes check), deliberately NOT " *
           "JSON.parsefile -- source-bound directly by reconcile; the " *
           "same helper also parses fixture tmp files"),
 (file = "gate4_g3_acceptance_comparison.jl",
  anchor = "JSON.parsefile(AC_RESULTS_JSON)",
  class = "own-artifact", edge_ids = String[],
  reason = "waiting-path parse-back self-test of own results"),
 (file = "gate4_g3_acceptance_comparison.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge", edge_ids = ["dep:g3_acceptance<-g3_run_ledger"],
  reason = "classify_run_ledger guarded-loader body (absence-tolerant " *
           "edge; live run-ledger load + tmp loader fixtures)"),
 (file = "gate4_g3_executor_checkpoint.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge", edge_ids = ["dep:g3_executor<-scoped_preflight"],
  reason = "classify_scoped_preflight guarded-loader body (exact-case " *
           "prerequisite binding; live edge + tmp loader fixtures)"),
 (file = "gate4_g3_scoped_input_preflight.jl",
  anchor = "JSON.parse(String(copy(bytes)))",
  class = "declared-snapshot-extension",
  edge_ids = ["dep:g3_scoped_preflight<-g2d_completion_ledger"],
  reason = "pf_snapshot helper body: coupled byte snapshot (one read " *
           "supplies digest AND parsed content; the G2d completion " *
           "ledger pin is a sha-over-the-same-bytes check), " *
           "deliberately NOT JSON.parsefile -- source-bound directly " *
           "by reconcile; the same helper also parses fixture tmp files"),
 (file = "gate4_init_generation_manifest.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge", edge_ids = ["dep:init_generation_manifest<-g2_g3_runner_scaffold"],
  reason = "classify_scaffold_artifact guarded-loader body (exact-case " *
           "+ faithful prefix binding; live edge + tmp loader fixtures)"),
 (file = "gate4_pending_rulings_register.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge",
  edge_ids = ["dep:rulings_register<-g2_binding_scaffold",
              "dep:rulings_register<-g2c_fetch_checkpoint",
              "dep:rulings_register<-g2c_failure_ledger_4440"],
  reason = "verify_json_source helper body (register edges + fixtures)"),
 (file = "gate4_post_cleanup_input_census.jl",
  anchor = "JSON.parse(String(bytes))",
  class = "declared-snapshot-extension",
  edge_ids = ["dep:post_cleanup_census<-g3_scoped_preflight",
              "dep:post_cleanup_census<-g2c_fetch_checkpoint",
              "dep:post_cleanup_census<-pending_rulings_register"],
  reason = "pcc_snapshot helper body: coupled byte snapshot (one read " *
           "supplies digest AND parsed content), deliberately NOT " *
           "JSON.parsefile -- source-bound directly by reconcile; the " *
           "same helper also parses fixture tmp files"),
 (file = "gate4_r1_release_provenance_probe.jl",
  anchor = "d = JSON.parsefile(validation_results_path(name))",
  class = "edge",
  edge_ids = ["dep:r1_probe<-r2_finding_ledger:followup",
              "dep:r1_probe<-option_b:followup"],
  reason = "dep_case_status helper body"),
 (file = "gate4_r2_execution_checkpoint.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge",
  edge_ids = ["dep:r2_exec_checkpoint<-r2_proof_scaffold",
              "dep:r2_exec_checkpoint<-r2_finding_ledger:historical"],
  reason = "parse_artifact! guarded-loader body (three fixed refusal " *
           "classes: missing / unparseable / non-object; serves both " *
           "edges + tmp loader fixtures)"),
 (file = "gate4_r2_sw_matching_version_proof_scaffold.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge",
  edge_ids = ["dep:r2_proof_scaffold<-r1_probe",
              "dep:r2_proof_scaffold<-r2_finding_ledger:historical",
              "dep:r2_proof_scaffold<-option_b:historical",
              "dep:r2_proof_scaffold<-init_provenance_ledger:historical"],
  reason = "rp_parse_pinned guarded-loader body (five fixed refusal " *
           "classes; exact case+status binding; serves all four " *
           "artifact edges + tmp loader fixtures)"),
 (file = "gate4_rulings_intake_contract.jl",
  anchor = "JSON.parse(String(bytes))",
  class = "declared-snapshot-extension",
  edge_ids = ["dep:rulings_intake<-pending_rulings_register",
              "dep:rulings_intake<-rulings_assignment:authority_input"],
  reason = "ric_snapshot helper body: a coupled BYTE snapshot (one read " *
           "supplies digest AND parsed content, closing the " *
           "hash-vs-parse TOCTOU), deliberately NOT JSON.parsefile -- " *
           "declared here as a non-parsefile extension, source-bound " *
           "directly by reconcile instead of via the parsefile census; " *
           "the same helper also re-reads the unit's own previous " *
           "artifact and fixture tmp files"),
 (file = "gate4_sw_init_generation_checkpoint.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge",
  edge_ids = ["dep:sw_init_checkpoint<-option_b",
              "dep:sw_init_checkpoint<-init_provenance_ledger:output_present"],
  reason = "classify_pinned_artifact guarded-loader body (exact-case + " *
           "exact-status binding; serves the always-on Option-B edge " *
           "and the output-present ledger-evidence edge + tmp loader " *
           "fixtures)"),
 (file = "gate4_v1_version_skew_recon.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge",
  edge_ids = ["dep:v1_recon<-r1_probe:followup",
              "dep:v1_recon<-r2_finding_ledger:followup",
              "dep:v1_recon<-option_b:followup"],
  reason = "v1_followup_status guarded-loader body (five fixed refusal " *
           "tokens; exact-case binding; offline contract-selftest " *
           "verified -- the unit's normal network path is never run " *
           "under the no-fetch boundary)"),
]

const DCA_STRUCTURAL_OUT_OF_SCOPE = Dict(
    "a2/r2 historical edges" => "attempt strings, output/binary/sbatch " *
        "hashes, job ids, outcome markers -- enforced in-unit",
    "register edges" => "D-key set, quota arithmetic, MD anchors -- " *
        "enforced by the register itself; this audit adds the " *
        "snapshot-hash staleness projection",
    "fingerprint_join" => "per-scenario schema/dims -- enforced by the " *
        "manifest; this audit verifies the post-hoc row label/sha/live " *
        "size+hash contract",
    "absence_tolerant" => "full acceptance/objective logic -- this audit " *
        "verifies the branch statuses and the reviewed-complete ledger " *
        "schema only",
    "authority_input" => "assignment schema, register pin, authority, " *
        "and vocabulary enforcement -- lives in the rulings intake " *
        "itself; this audit projects register health, source presence, " *
        "and parse shape into the faithful allowed status set only")

# ============================================================================
# ENGINE
# ============================================================================

function dca_census()
    sites = Any[]
    for f in sort(readdir(DCA_VALIDATION_DIR))
        (startswith(f, "gate4") && endswith(f, ".jl")) || continue
        f == "gate4_status_dependency_contract_audit.jl" && continue
        text = read(joinpath(DCA_VALIDATION_DIR, f), String)
        for (i, line) in enumerate(split(text, '\n'))
            occursin("JSON.parsefile", line) &&
                push!(sites, (file = f, line = i, text = strip(line)))
        end
    end
    return sites
end

# reconciliation: every live JSON.parsefile site matched exactly once;
# every parsefile ledger record matched by exactly one live site; a
# declared-snapshot-extension record (a deliberately non-parsefile
# coupled byte-snapshot site) is instead SOURCE-BOUND directly -- its
# anchor must exist in the consumer source and must never match a live
# parsefile site; union of served edge_ids == the manifest ID set (both
# directions)
function dca_reconcile(sites, ledger, manifest_ids)
    issues = String[]
    ledger_hits = zeros(Int, length(ledger))
    for s in sites
        matches = [li for (li, x) in enumerate(ledger)
                   if x.file == s.file && occursin(x.anchor, s.text)]
        if isempty(matches)
            push!(issues, "UNACCOUNTED parse site $(s.file):$(s.line): " *
                          "$(first(s.text, 90))")
        elseif length(matches) > 1
            push!(issues, "AMBIGUOUS parse site $(s.file):$(s.line) " *
                          "matches $(length(matches)) ledger records")
        else
            ledger_hits[matches[1]] += 1
        end
    end
    # each parsefile ledger record must be matched by EXACTLY one live
    # site; declared snapshot extensions are verified against the source
    for (li, x) in enumerate(ledger)
        if x.class == "declared-snapshot-extension"
            ledger_hits[li] == 0 ||
                push!(issues, "declared-snapshot-extension record " *
                              "unexpectedly matched a live parsefile " *
                              "site: $(x.file)")
            cpath = joinpath(DCA_VALIDATION_DIR, x.file)
            (isfile(cpath) && occursin(x.anchor, read(cpath, String))) ||
                push!(issues, "DECLARED EXTENSION ANCHOR MISSING: " *
                              "$(x.file) anchor $(first(x.anchor, 60))")
            continue
        end
        ledger_hits[li] == 0 &&
            push!(issues, "DANGLING ledger record (no live site): " *
                          "$(x.file) anchor $(first(x.anchor, 60))")
        ledger_hits[li] > 1 &&
            push!(issues, "MULTI-MATCHED ledger record ($(ledger_hits[li]) " *
                          "live sites): $(x.file) anchor " *
                          "$(first(x.anchor, 60))")
    end
    served = sort(unique(vcat([collect(x.edge_ids) for x in ledger]...)))
    expected = sort(manifest_ids)
    if served != expected
        missing_e = setdiff(expected, served)
        extra_e = setdiff(served, expected)
        push!(issues, "EDGE-UNION MISMATCH: sites serve $(length(served)) " *
              "edges vs manifest $(length(expected)); missing=$(missing_e) " *
              "extra=$(extra_e)")
    end
    return issues
end

function dca_active(e, modes)
    e.active_when == :always && return true
    e.active_when == :a2_historical && return modes.a2 == :historical
    e.active_when == :a2_preexecution && return modes.a2 == :preexecution
    e.active_when == :r2_historical && return modes.r2 == :historical
    e.active_when == :sw_init_output_present &&
        return modes.sw_init == :output_present
    drefuse("unknown active_when $(e.active_when) for $(e.id)")
end

function dca_accepted_tokens(e, modes)
    if haskey(pairs(e), :accepted_by_mode)
        axis_mode = e.mode_axis == :r2 ? modes.r2 :
                    e.mode_axis == :a2 ? modes.a2 :
                    drefuse("unknown mode_axis $(e.mode_axis) for $(e.id)")
        return e.accepted_by_mode[axis_mode]
    end
    return e.accepted
end

# live register health AS THE INTAKE CHECKS IT: identity + the EXACT
# five normalized full source paths (a substituted same-count list is
# stale, mirroring the intake's ric_source_set_issues) + live re-hash;
# any drift -> the intake blocks, so the authority-input allowed set
# narrows to blocked_register_stale
const DCA_REG_EXPECTED_SOURCE_PATHS = sort(normpath.([
    validation_results_path("gate4_g2_binding_decision_scaffold.json"),
    joinpath(DCA_VALIDATION_DIR,
             "gate4_regression_margin_semantics_evidence.md"),
    validation_results_path("gate4_g2c_eval2_fetch_checkpoint.json"),
    validation_results_path("gate4_g2c_failure_ledger_4440.json"),
    joinpath(DCA_VALIDATION_DIR, "gate4_g2c_quota_recovery_runbook.md")]))

function dca_register_sources_stale(srcs)
    srcs isa AbstractVector || return true
    sort([normpath(dca_str(get(dca_obj(s), "path", ""))) for s in srcs]) ==
        DCA_REG_EXPECTED_SOURCE_PATHS || return true
    for s in srcs
        d = dca_obj(s)
        h = dca_try_sha(dca_str(get(d, "path", "")))
        (h !== nothing && h == dca_str(get(d, "sha256", ""))) ||
            return true
    end
    return false
end

function dca_edge_verdict(e, modes)
    e.kind in DCA_KNOWN_KINDS ||
        drefuse("unknown contract kind $(e.kind) for $(e.id)")
    rec = Dict{String, Any}("id" => e.id, "kind" => String(e.kind),
        "consumer" => e.consumer,
        "status_only_contract" => e.status_only)
    cpath = joinpath(DCA_VALIDATION_DIR, e.consumer)
    isfile(cpath) || return merge(rec, Dict("verdict" => "violated",
        "detail" => "consumer source missing"))
    ctext = read(cpath, String)
    rec["consumer_sha256"] = dca_sha(cpath)
    for a in e.anchors
        occursin(a, ctext) || return merge(rec,
            Dict("verdict" => "violated",
                 "detail" => "consumer anchor missing: $(first(a, 70))"))
    end
    active = dca_active(e, modes)
    rec["active"] = active
    active || return merge(rec, Dict("verdict" => "inactive_branch",
        "detail" => "contract branch not exercised in the current mode; " *
                    "anchors verified"))

    if e.kind == :absence_tolerant
        # SOURCE-BOUND E9 invariants: every token the truth table relies
        # on (waiting/missing/invalid/downstream/selftest) plus the
        # recovered-output constants and output-first conditions must
        # exist in the consumer source -- consumer drift cannot leave the
        # audit green
        e9_toks = vcat([e.e9_tokens.waiting, e.e9_tokens.missing,
                        e.e9_tokens.invalid, e.selftest_status],
                       e.e9_tokens.downstream)
        for tok in vcat(e9_toks, collect(e.output_anchors))
            occursin(tok, ctext) || return merge(rec,
                Dict("verdict" => "violated",
                     "detail" => "consumer source missing E9-bound " *
                                 "token/anchor: $(first(tok, 70))"))
        end
        # FAITHFUL prerequisite chain: outputs first, then ledger, with
        # parse SUCCESS distinguished from object-ness and schema (a JSON
        # null parses successfully; arrays parse but are not objects)
        outputs_present = isfile(DCA_LW_RECOVERED) &&
                          isfile(DCA_SW_RECOVERED)
        present = modes.g3_ledger_present
        parse_success = nothing
        object_ok = nothing
        schema_ok = nothing
        if present
            lp = validation_results_path("gate4_g3_run_ledger.json")
            parse_success = true
            ld_raw = try JSON.parsefile(lp) catch
                parse_success = false; nothing end
            object_ok = parse_success ? (ld_raw isa AbstractDict) : nothing
            schema_ok = object_ok === true ?
                validate_run_ledger(ld_raw)[1] : nothing
        end
        allowed = dca_e9_allowed_statuses(outputs_present, present,
            parse_success, object_ok, schema_ok, e.e9_tokens;
            catches_parse_errors = e.catches_ledger_parse_errors,
            maps_nonobject_to_invalid = e.maps_nonobject_to_invalid)
        art = validation_results_path(e.expected_case * ".json")
        isfile(art) || return merge(rec, Dict("verdict" => "violated",
            "detail" => "consumer artifact missing: $art"))
        d = dca_obj(try JSON.parsefile(art) catch; nothing end)
        ccase = dca_str(get(d, "case", ""))
        cstat = dca_str(get(d, "status", ""))
        rec["consumer_artifact_sha256"] = dca_sha(art)
        ccase == e.expected_case || return merge(rec,
            Dict("verdict" => "violated",
                 "detail" => "consumer artifact case $ccase != " *
                             "$(e.expected_case)"))
        cls = dca_e9_verdict_class(cstat, allowed, e.selftest_status)
        if cls == :consumer_selftest_state && !dca_selftest_evidence_ok(d)
            return merge(rec, Dict("verdict" => "violated",
                "detail" => "consumer claims self-test-failure status " *
                    "WITHOUT corroborating artifact evidence " *
                    "(failures/gates/selftests/data_mode)"))
        end
        verdict = cls == :satisfied ? "satisfied" :
                  cls == :consumer_selftest_state ?
                      "consumer_selftest_state" : "violated"
        gap = present === true &&
              ((parse_success !== true &&
                !e.catches_ledger_parse_errors) ||
               (parse_success === true && object_ok !== true &&
                !e.maps_nonobject_to_invalid))
        return merge(rec, Dict("verdict" => verdict,
            "detail" => "outputs " *
                (outputs_present ? "present" : "absent") * "; ledger " *
                (present ? "present (parse_success=$(parse_success), " *
                    "object_ok=$(object_ok), schema_ok=$(schema_ok))" :
                 "absent") *
                "; allowed=$(allowed); consumer status=$cstat" *
                (gap ? " -- unparseable/non-object ledger is an " *
                       "uncaught-exception gap in this consumer (no " *
                       "faithful status exists)" : "") *
                (verdict == "violated" ?
                 " -- INCONSISTENT with the prerequisite state" :
                 verdict == "consumer_selftest_state" ?
                 " -- self-test failure state (evidence-corroborated), " *
                 "classified explicitly, not a dependency inconsistency" :
                 "")))
    end

    if e.kind == :authority_input
        # the producer is a human-authored input in validation/ whose
        # ABSENCE is a legitimate (awaiting) state, so the generic
        # results-dir producer load below does not apply. The audit
        # projects register health + source presence + parse shape into
        # the faithful allowed set and verifies the intake's canonical
        # artifact against it; the intake's deeper semantics are declared
        # structurally out of scope.
        # SOURCE-BOUND status tokens (as E9 does): every accepted token
        # plus the selftest status must exist in the consumer source --
        # consumer drift cannot leave the audit green
        for tok in vcat(collect(e.accepted), [e.selftest_status])
            occursin(tok, ctext) || return merge(rec,
                Dict("verdict" => "violated",
                     "detail" => "consumer source missing bound status " *
                                 "token: $(first(tok, 70))"))
        end
        # ONE register byte snapshot per evaluation: identity, source
        # staleness, and the fact-check digest all share it (digest and
        # parsed content from the same read)
        reg_snap = dca_snapshot(validation_results_path(
            "gate4_pending_rulings_register.json"))
        regd = dca_obj(reg_snap.data)
        reg_identity_ok = reg_snap.object_ok &&
            dca_str(get(regd, "case", "")) ==
                "gate4_pending_rulings_register" &&
            dca_str(get(regd, "status", "")) ==
                "pending_rulings_register_recorded"
        reg_stale = !reg_identity_ok ||
            dca_register_sources_stale(get(regd, "sources", nothing))
        # ONE input byte snapshot per evaluation, mirroring the intake
        apath = joinpath(DCA_VALIDATION_DIR, String(e.producer))
        present = isfile(apath)
        in_snap = present ? dca_snapshot(apath) : nothing
        parse_success = present ? in_snap.parse_success : nothing
        object_ok = present ? in_snap.object_ok : nothing
        allowed = dca_authority_input_allowed(reg_stale, present,
                                              parse_success, object_ok)
        # ONE consumer-artifact byte snapshot: the verified case/status
        # and the recorded sha are guaranteed to describe the same bytes
        art = validation_results_path(e.expected_case * ".json")
        art_snap = dca_snapshot(art)
        art_snap.readable || return merge(rec,
            Dict("verdict" => "violated",
                 "detail" => "consumer artifact missing/unreadable: $art"))
        art_snap.object_ok || return merge(rec,
            Dict("verdict" => "violated",
                 "detail" => "consumer artifact unparseable/non-object"))
        d = dca_obj(art_snap.data)
        ccase = dca_str(get(d, "case", ""))
        cstat = dca_str(get(d, "status", ""))
        rec["consumer_artifact_sha256"] = art_snap.sha
        ccase == e.expected_case || return merge(rec,
            Dict("verdict" => "violated",
                 "detail" => "consumer artifact case $ccase != " *
                             "$(e.expected_case)"))
        # RECORDED FACTS must equal CURRENT facts, not status alone: a
        # changed human input or register cannot leave an old artifact
        # looking current. Every comparison uses this evaluation's byte
        # snapshots; an unreadable file is a fact drift, never a crash.
        art_reg = dca_obj(get(d, "register", nothing))
        as = dca_obj(get(d, "assignment_source", nothing))
        fact_bad = String[]
        get(art_reg, "healthy", nothing) == !reg_stale ||
            push!(fact_bad, "register.healthy != current register health")
        if !reg_stale
            dca_str(get(art_reg, "live_sha256", "")) == reg_snap.sha ||
                push!(fact_bad, "register.live_sha256 != current " *
                                "register snapshot digest")
        end
        normpath(dca_str(get(as, "path", ""))) == normpath(apath) ||
            push!(fact_bad, "assignment_source.path mismatch")
        get(as, "present", nothing) == present ||
            push!(fact_bad, "assignment_source.present != current")
        isequal(get(as, "parse_success", missing), parse_success) ||
            push!(fact_bad, "assignment_source.parse_success != current")
        isequal(get(as, "object_ok", missing), object_ok) ||
            push!(fact_bad, "assignment_source.object_ok != current")
        if present
            isequal(get(as, "live_sha256", missing),
                    in_snap.readable ? in_snap.sha : nothing) ||
                push!(fact_bad, "assignment_source.live_sha256 != " *
                                "current input snapshot digest")
        else
            get(as, "live_sha256", missing) === nothing ||
                push!(fact_bad,
                      "assignment_source.live_sha256 recorded for an " *
                      "absent input")
        end
        isempty(fact_bad) || return merge(rec,
            Dict("verdict" => "violated",
                 "detail" => "consumer artifact facts drifted from " *
                             "current state: " * join(fact_bad, "; ")))
        cls = dca_e9_verdict_class(cstat, allowed, e.selftest_status)
        if cls == :consumer_selftest_state && !dca_selftest_evidence_ok(d)
            return merge(rec, Dict("verdict" => "violated",
                "detail" => "consumer claims self-test-failure status " *
                    "WITHOUT corroborating artifact evidence " *
                    "(failures/gates/selftests/data_mode)"))
        end
        verdict = cls == :satisfied ? "satisfied" :
                  cls == :consumer_selftest_state ?
                      "consumer_selftest_state" : "violated"
        return merge(rec, Dict("verdict" => verdict,
            "detail" => "register " *
                (reg_stale ? "STALE" : "healthy") * "; authority input " *
                (present ? "present (parse_success=$(parse_success), " *
                           "object_ok=$(object_ok))" : "absent") *
                "; allowed=$(allowed); consumer status=$cstat" *
                (verdict == "violated" ?
                 " -- INCONSISTENT with the prerequisite state" :
                 verdict == "consumer_selftest_state" ?
                 " -- self-test failure state (evidence-corroborated), " *
                 "classified explicitly, not a dependency inconsistency" :
                 "")))
    end

    prod = validation_results_path(String(e.producer))
    isfile(prod) || return merge(rec, Dict("verdict" => "violated",
        "detail" => "producer artifact missing: $prod"))
    d = dca_obj(try JSON.parsefile(prod) catch; nothing end)
    isempty(d) && return merge(rec, Dict("verdict" => "violated",
        "detail" => "producer artifact unparseable/non-object"))
    rec["producer_sha256"] = dca_sha(prod)
    pcase = dca_str(get(d, "case", ""))
    pstat = dca_str(get(d, "status", ""))
    rec["producer_case"] = pcase
    rec["producer_status"] = pstat

    if e.kind == :fingerprint_join
        # POST-HOC ROW CONTRACT: every manifest-joined row in the binding
        # scaffold's committed artifact must still verify against the
        # current manifest entry AND the live file (size + hash)
        sart = validation_results_path(
            "gate4_g2_binding_decision_scaffold.json")
        isfile(sart) || return merge(rec, Dict("verdict" => "violated",
            "detail" => "binding-scaffold artifact missing"))
        sd = dca_obj(try JSON.parsefile(sart) catch; nothing end)
        # scaffold artifact IDENTITY: unrelated shaped JSON must not pass
        (dca_str(get(sd, "case", "")) ==
             "gate4_g2_binding_decision_scaffold" &&
         dca_str(get(sd, "status", "")) ==
             "g2_binding_scaffold_ready_awaiting_rulings") ||
            return merge(rec, Dict("verdict" => "violated",
                "detail" => "binding-scaffold artifact identity failed " *
                    "(case/status)"))
        rows = Any[]
        for r in get(sd, "demo_metric_rows_manifest_joined", Any[])
            push!(rows, dca_obj(r))
        end
        nd = dca_obj(get(sd, "negative_total_diagnostic", nothing))
        haskey(nd, "scenario") && push!(rows,
            merge(dca_obj(nd["scenario"]),
                  Dict("scenario_path" => "(diagnostic)")))
        row_issues = dca_fingerprint_row_issues(rows)
        isempty(row_issues) || return merge(rec,
            Dict("verdict" => "violated",
                 "detail" => join(row_issues, "; ")))
        # inventory hygiene BEFORE the Dict collapse: blank/duplicate
        # labels would make first-match/only-style label joins ambiguous
        inv_entries = get(d, "inventory", Any[])
        inv_issues = dca_inventory_issues(inv_entries)
        isempty(inv_issues) || return merge(rec,
            Dict("verdict" => "violated",
                 "detail" => join(inv_issues, "; ")))
        inv = Dict(dca_str(get(dca_obj(x), "label", "")) => dca_obj(x)
                   for x in inv_entries)
        bad = String[]
        for r in rows
            lbl = dca_str(get(r, "manifest_label", ""))
            rsha = dca_str(get(r, "manifest_sha256", ""))
            ent = get(inv, lbl, nothing)
            if ent === nothing
                push!(bad, "$lbl: not in current manifest")
            elseif dca_str(get(ent, "sha256", "")) != rsha
                push!(bad, "$lbl: row sha != current manifest sha")
            elseif get(ent, "present", false) != true ||
                   get(ent, "schema_ok", false) != true
                push!(bad, "$lbl: manifest entry not present/schema_ok")
            else
                p = dca_str(get(ent, "path", ""))
                if !isfile(p) || filesize(p) != get(ent, "size_bytes", -1) ||
                   dca_sha(p) != rsha
                    push!(bad, "$lbl: live file size/hash drifted")
                end
            end
        end
        ok = isempty(bad)
        return merge(rec, Dict("verdict" => ok ? "satisfied" : "violated",
            "rows_checked" => length(rows),
            "detail" => ok ? "all $(length(rows)) manifest-joined rows " *
                "re-verified (label, sha, live size+hash); manifest " *
                "status $pstat recorded as info only" :
                join(bad, "; ")))
    end

    accepted = dca_accepted_tokens(e, modes)
    status_ok = e.kind == :prefix ? startswith(pstat, accepted) :
                pstat in accepted
    case_ok = !e.consumer_checks_case || pcase == e.expected_case

    if e.kind == :register_snapshot
        regp = validation_results_path("gate4_pending_rulings_register.json")
        isfile(regp) || return merge(rec, Dict("verdict" => "violated",
            "detail" => "register artifact missing"))
        reg = dca_obj(try JSON.parsefile(regp) catch; nothing end)
        recsrc = nothing
        for s in get(reg, "sources", Any[])
            endswith(dca_str(get(dca_obj(s), "path", "")),
                     String(e.producer)) && (recsrc = dca_obj(s))
        end
        recsrc === nothing && return merge(rec,
            Dict("verdict" => "violated",
                 "detail" => "register records no source for $(e.producer)"))
        stale = dca_snapshot_stale(recsrc, rec["producer_sha256"],
                                   pcase, pstat)
        ok = status_ok && case_ok && !stale
        return merge(rec, Dict("verdict" => ok ? "satisfied" : "violated",
            "register_recorded_sha256" => dca_str(get(recsrc, "sha256", "")),
            "detail" => stale ?
                "REGISTER STALE: recorded source sha/case/status no " *
                "longer match the current producer -- register " *
                "regeneration required" :
                (ok ? "snapshot and live contract both satisfied" :
                 "producer status/case outside accepted contract")))
    end

    ok = status_ok && case_ok
    return merge(rec, Dict("verdict" => ok ? "satisfied" : "violated",
        "detail" => ok ? "contract satisfied" :
            "status=$pstat case=$pcase vs accepted=$(accepted) " *
            "case-checked=$(e.consumer_checks_case)"))
end

function dca_main()
    fails = String[]
    gates = Dict{String, String}()

    ids = [e.id for e in DCA_EDGES]
    gates["manifest_ids_unique"] =
        length(unique(ids)) == length(ids) ? "passed" : "failed"
    length(unique(ids)) == length(ids) ||
        push!(fails, "duplicate edge IDs in the declarative manifest")
    gates["manifest_edge_count_43"] =
        length(DCA_EDGES) == 43 ? "passed" : "failed"
    length(DCA_EDGES) == 43 ||
        push!(fails, "manifest has $(length(DCA_EDGES)) edges, expected 43")
    n_snapext = count(x -> x.class == "declared-snapshot-extension",
                      DCA_SITE_LEDGER)
    gates["snapshot_extension_count_5"] =
        n_snapext == 5 ? "passed" : "failed"
    n_snapext == 5 ||
        push!(fails, "site ledger has $n_snapext declared-snapshot-" *
                     "extension records, expected 5")
    m_issues = dca_manifest_issues(DCA_EDGES)
    gates["manifest_schema_valid"] = isempty(m_issues) ? "passed" : "failed"
    append!(fails, m_issues)

    sites = dca_census()
    issues = dca_reconcile(sites, DCA_SITE_LEDGER, ids)
    gates["census_reconciles_with_edge_linkage"] =
        isempty(issues) ? "passed" : "failed"
    append!(fails, issues)

    modes = dca_modes()
    verdicts = [dca_edge_verdict(e, modes) for e in DCA_EDGES]
    n_sat = count(v -> v["verdict"] == "satisfied", verdicts)
    n_inact = count(v -> v["verdict"] == "inactive_branch", verdicts)
    n_viol = count(v -> v["verdict"] == "violated", verdicts)
    n_self = count(v -> v["verdict"] == "consumer_selftest_state", verdicts)
    # gate named precisely: it asserts NO VIOLATIONS -- selftest states
    # are counted and surfaced separately, never called "satisfied"
    gates["no_contract_violations"] = n_viol == 0 ? "passed" : "failed"
    n_viol == 0 || push!(fails,
        "$(n_viol) contract violations: " *
        join([v["id"] for v in verdicts if v["verdict"] == "violated"], ", "))

    # hardening findings via the pure, fixture-shared constructor; with
    # every consumer hardened, live hardening == [] is the EXPECTED
    # generated result (informational -- deliberately NOT a gate: a
    # future legitimate status-only or selftest finding must surface as
    # a finding, never as an audit failure). The former standing G3
    # asymmetry finding remains CLOSED (classify_run_ledger).
    hardening = dca_hardening_findings(verdicts)

    # --- fixtures (pure validators reused; unknown kinds refuse) ----------
    t = Dict{String, Bool}()
    tdir = mktempdir()
    badp = joinpath(tdir, "bad.json"); write(badp, "{")
    t["malformed_artifact_detected"] =
        isempty(dca_obj(try JSON.parsefile(badp) catch; nothing end))
    fake_sites = [(file = "gate4_zzz.jl", line = 1,
                   text = "x = JSON.parsefile(\"novel.json\")")]
    t["unaccounted_site_detected"] =
        any(occursin("UNACCOUNTED", i)
            for i in dca_reconcile(fake_sites, DCA_SITE_LEDGER, ids))
    t["dangling_ledger_record_detected"] =
        any(occursin("DANGLING", i)
            for i in dca_reconcile(Any[], DCA_SITE_LEDGER, ids))
    t["omitted_edge_union_detected"] =
        any(occursin("EDGE-UNION MISMATCH", i)
            for i in dca_reconcile(dca_census(), DCA_SITE_LEDGER,
                                   vcat(ids, ["dep:phantom<-nothing"])))
    t["duplicate_id_guard"] = begin
        dup = vcat(ids, [ids[1]])
        length(unique(dup)) != length(dup)
    end
    t["unknown_kind_refuses"] = try
        e0 = DCA_EDGES[1]
        dca_edge_verdict(merge(NamedTuple(pairs(e0)), (kind = :bogus,)),
                         modes)
        false
    catch err; err isa DcaRefusal &&
               occursin("unknown contract kind", err.reason) end
    t["malformed_consumer_anchor_detected"] = begin
        csrc = joinpath(tdir, "gate4_fake_consumer.jl")
        write(csrc, "# no anchors here\n")
        e0 = DCA_EDGES[1]
        # consumer path is resolved relative to the validation dir, so
        # point the synthetic edge at a relative temp path
        rel = relpath(csrc, DCA_VALIDATION_DIR)
        v = dca_edge_verdict(merge(NamedTuple(pairs(e0)),
                                   (consumer = rel,)), modes)
        v["verdict"] == "violated" &&
            occursin("anchor missing", v["detail"])
    end
    # pure snapshot validator: doctored record stale, faithful record not
    t["snapshot_staleness_detected"] =
        dca_snapshot_stale(Dict("sha256" => "0"^64,
            "verified_case" => "c", "verified_status" => "s"),
            "1"^64, "c", "s") &&
        !dca_snapshot_stale(Dict("sha256" => "1"^64,
            "verified_case" => "c", "verified_status" => "s"),
            "1"^64, "c", "s")
    # pure E9 TRUTH TABLE: every prerequisite branch (outputs first),
    # with parse SUCCESS / object-ness / schema distinguished, in BOTH
    # consumer styles (guarded catches+maps -- now BOTH campaign
    # consumers -- and the hypothetical unguarded style, kept
    # fixture-tested so a future guardless consumer stays representable)
    tk = (waiting = "W", missing = "M", invalid = "I",
          downstream = ["D1", "D2"])
    g1s = (catches_parse_errors = true, maps_nonobject_to_invalid = true)
    g3s = (catches_parse_errors = false, maps_nonobject_to_invalid = false)
    t["e9_truth_table_validated"] =
        dca_e9_allowed_statuses(false, false, nothing, nothing, nothing,
                                tk; g1s...) == ["W"] &&
        dca_e9_allowed_statuses(false, true, true, true, true,
                                tk; g1s...) == ["W"] &&
        dca_e9_allowed_statuses(true, false, nothing, nothing, nothing,
                                tk; g1s...) == ["M"] &&
        dca_e9_allowed_statuses(true, true, true, true, false,
                                tk; g1s...) == ["I"] &&
        dca_e9_allowed_statuses(true, true, true, true, true,
                                tk; g1s...) == ["D1", "D2"]
    # ledger-state matrix: malformed / null / array (parse ok, non-
    # object) / valid object, per consumer style. JSON null PARSES
    # successfully to a non-object -- it must never be conflated with a
    # parse failure.
    t["e9_ledger_state_matrix_validated"] =
        # malformed: guarded -> invalid; unguarded -> gap (no faithful
        # status)
        dca_e9_allowed_statuses(true, true, false, nothing, nothing,
                                tk; g1s...) == ["I"] &&
        dca_e9_allowed_statuses(true, true, false, nothing, nothing,
                                tk; g3s...) == String[] &&
        # null / array: parse succeeds, object_ok=false:
        # guarded -> invalid ("not an object"); unguarded -> gap
        dca_e9_allowed_statuses(true, true, true, false, nothing,
                                tk; g1s...) == ["I"] &&
        dca_e9_allowed_statuses(true, true, true, false, nothing,
                                tk; g3s...) == String[] &&
        # valid object, schema-invalid -> invalid in BOTH styles
        dca_e9_allowed_statuses(true, true, true, true, false,
                                tk; g3s...) == ["I"] &&
        # valid object + schema -> downstream in BOTH styles
        dca_e9_allowed_statuses(true, true, true, true, true,
                                tk; g3s...) == ["D1", "D2"]
    # self-test precedence classification: explicit class, not violation
    t["e9_selftest_classified"] =
        dca_e9_verdict_class("SELF", ["W"], "SELF") ==
            :consumer_selftest_state &&
        dca_e9_verdict_class("W", ["W"], "SELF") == :satisfied &&
        dca_e9_verdict_class("X", ["W"], "SELF") == :violated
    # self-test claims require corroborating artifact evidence
    t["selftest_evidence_required"] =
        dca_selftest_evidence_ok(Dict("data_mode" => "selftest_failure")) &&
        dca_selftest_evidence_ok(Dict("failures" => ["x"])) &&
        dca_selftest_evidence_ok(Dict("selftests" =>
            Dict("a" => true, "b" => false))) &&
        !dca_selftest_evidence_ok(Dict("data_mode" => "other",
            "failures" => Any[], "selftests" => Dict("a" => true)))
    # E9 anchor-coverage invariant: an AT edge missing the SW recovered
    # binding (or any other of root/LW/SW/output-first/parse-shape) is a
    # manifest schema failure
    e9edge = [e for e in DCA_EDGES
              if e.id == "dep:g1_objective_ratio<-g3_run_ledger"][1]
    stripped_anchors = [a for a in e9edge.output_anchors
                        if !occursin("sw_ckd-definition", a)]
    t["e9_anchor_coverage_invariant"] =
        any(occursin("missing SW recovered binding", i)
            for i in dca_manifest_issues([merge(NamedTuple(pairs(e9edge)),
                (output_anchors = stripped_anchors,))])) &&
        isempty([i for i in dca_manifest_issues([e9edge])
                 if occursin("output_anchors missing", i)])
    # authority-input truth table: register staleness dominates, absence
    # is awaiting, parse/object failures narrow to refused, and only a
    # present parseable object admits recorded (alongside refused)
    t["authority_input_truth_table_validated"] =
        dca_authority_input_allowed(true, true, true, true) ==
            ["rulings_intake_blocked_register_stale"] &&
        dca_authority_input_allowed(false, false, nothing, nothing) ==
            ["rulings_intake_awaiting_assignments"] &&
        dca_authority_input_allowed(false, true, false, false) ==
            ["rulings_intake_refused"] &&
        dca_authority_input_allowed(false, true, true, false) ==
            ["rulings_intake_refused"] &&
        dca_authority_input_allowed(false, true, true, true) ==
            ["rulings_intake_assignments_recorded",
             "rulings_intake_refused"]
    # authority-input manifest invariants: the declared status universe
    # must be exactly the four intake tokens, and selftest_status is
    # required
    ai_edge = [e for e in DCA_EDGES
               if e.id ==
                  "dep:rulings_intake<-rulings_assignment:authority_input"][1]
    t["authority_input_manifest_invariants"] =
        any(occursin("!= the exact four intake tokens", i)
            for i in dca_manifest_issues([merge(NamedTuple(pairs(ai_edge)),
                (accepted = ["rulings_intake_awaiting_assignments"],))])) &&
        isempty([i for i in dca_manifest_issues([ai_edge])
                 if occursin("authority_input", i)])
    # register source-set fidelity: a substituted SAME-COUNT source list
    # (same-basename file elsewhere, or a different pinned file) is stale
    # even if every hash matches its own file
    subst_srcs = [Dict("path" => i == 1 ? DCA_RESULTS_JSON :
                           DCA_REG_EXPECTED_SOURCE_PATHS[i],
                       "sha256" => "0"^64)
                  for i in eachindex(DCA_REG_EXPECTED_SOURCE_PATHS)]
    t["register_source_substitution_detected"] =
        dca_register_sources_stale(subst_srcs) &&
        dca_register_sources_stale("not-a-vector") &&
        dca_register_sources_stale(
            [Dict("path" => p, "sha256" => "0"^64)
             for p in DCA_REG_EXPECTED_SOURCE_PATHS[1:4]])
    # TOCTOU hardening: current-state hashing never throws -- a vanished
    # file classifies (stale/violated) instead of crashing the audit
    t["try_sha_nonthrowing"] =
        dca_try_sha(joinpath(tdir, "vanished.bin")) === nothing &&
        dca_try_sha(badp) isa AbstractString
    # coupled byte snapshot: digest and parsed content come from the
    # SAME captured bytes; an already-taken snapshot is immune to a
    # subsequent overwrite, and a fresh snapshot sees the new pair
    t["snapshot_couples_digest_and_content"] = begin
        cpf = joinpath(tdir, "coupled.json")
        write(cpf, "{\"v\": 1}")
        s1 = dca_snapshot(cpf)
        h1 = dca_try_sha(cpf)
        write(cpf, "{\"v\": 22}")
        s2 = dca_snapshot(cpf)
        s1.object_ok && s1.data["v"] == 1 && s1.sha == h1 &&
            s2.data["v"] == 22 && s2.sha == dca_try_sha(cpf) &&
            s1.sha != s2.sha &&
            !dca_snapshot(joinpath(tdir, "gone.json")).readable
    end
    # a declared-snapshot-extension record is source-bound directly: a
    # missing anchor in the consumer source must be flagged
    t["declared_extension_anchor_missing_detected"] = begin
        tampered = Any[x.class == "declared-snapshot-extension" ?
                       merge(NamedTuple(pairs(x)),
                             (anchor = "NO_SUCH_SNAPSHOT_ANCHOR",)) : x
                       for x in DCA_SITE_LEDGER]
        any(occursin("DECLARED EXTENSION ANCHOR MISSING", i)
            for i in dca_reconcile(dca_census(), tampered, ids))
    end
    # authority-input token binding: a consumer source missing ANY
    # accepted/selftest status token is violated before any live check
    t["authority_input_missing_token_detected"] = begin
        csrc = joinpath(tdir, "gate4_fake_intake.jl")
        write(csrc, join(ai_edge.anchors, "\n") * "\n" *
                    join(ai_edge.accepted[1:3], "\n") * "\n")
        rel = relpath(csrc, DCA_VALIDATION_DIR)
        v = dca_edge_verdict(merge(NamedTuple(pairs(ai_edge)),
                                   (consumer = rel,)), modes)
        v["verdict"] == "violated" &&
            occursin("missing bound status token", v["detail"])
    end
    # inventory hygiene rejected BEFORE Dict collapse
    t["inventory_hygiene_detected"] =
        any(occursin("blank label", i)
            for i in dca_inventory_issues([Dict("label" => "")])) &&
        any(occursin("duplicate labels", i)
            for i in dca_inventory_issues(
                [Dict("label" => "a"), Dict("label" => "a")])) &&
        isempty(dca_inventory_issues(
            [Dict("label" => "a"), Dict("label" => "b")]))
    # multi-matched ledger record must be rejected (exactly-once contract)
    dupsites = [(file = DCA_SITE_LEDGER[1].file, line = 1,
                 text = DCA_SITE_LEDGER[1].anchor),
                (file = DCA_SITE_LEDGER[1].file, line = 2,
                 text = DCA_SITE_LEDGER[1].anchor)]
    t["multi_matched_ledger_record_detected"] =
        any(occursin("MULTI-MATCHED", i)
            for i in dca_reconcile(dupsites, DCA_SITE_LEDGER, ids))
    # the sw_init mode axis must gate its output-present edge: active
    # for :output_present (presence semantics -- the consumer, not the
    # audit, decides historical vs anomaly), inactive for :preexecution
    t["sw_init_mode_axis_active_when"] = begin
        e_h = (id = "fixture", active_when = :sw_init_output_present)
        m_h = (a2 = :historical, r2 = :historical,
               sw_init = :output_present, g3_ledger_present = false)
        m_p = (a2 = :historical, r2 = :historical,
               sw_init = :preexecution, g3_ledger_present = false)
        dca_active(e_h, m_h) && !dca_active(e_h, m_p)
    end
    # unknown mode_axis must refuse (never silently mapped)
    t["unknown_mode_axis_refuses"] = try
        e6 = [e for e in DCA_EDGES
              if e.id == "dep:r2_exec_checkpoint<-r2_proof_scaffold"][1]
        dca_accepted_tokens(merge(NamedTuple(pairs(e6)),
                                  (mode_axis = :bogus,)), modes)
        false
    catch err; err isa DcaRefusal &&
               occursin("unknown mode_axis", err.reason) end
    # malformed manifest schema fixtures
    bad_edges = [
        (id = "x1", consumer = "c", anchors = String[], producer = "p",
         kind = :exact, expected_case = "e", consumer_checks_case = false,
         status_only = false, active_when = :always,
         accepted = ["t"]),                     # status_only inconsistent
        (id = "x2", consumer = "c", anchors = String[], producer = "p",
         kind = :exact, expected_case = "e", consumer_checks_case = false,
         status_only = true, active_when = :sometimes,
         accepted = ["t"]),                     # invalid active_when
        (id = "x3", consumer = "c", anchors = String[], producer = "p",
         kind = :exact, expected_case = "e", consumer_checks_case = false,
         status_only = true, active_when = :always),  # no accepted
    ]
    mi = dca_manifest_issues(bad_edges)
    t["malformed_manifest_schema_detected"] =
        any(occursin("status_only inconsistent", i) for i in mi) &&
        any(occursin("invalid active_when", i) for i in mi) &&
        any(occursin("neither accepted nor accepted_by_mode", i) for i in mi)
    # fingerprint row-issue validator: blank + duplicate labels rejected
    t["fingerprint_row_issues_detected"] =
        any(occursin("blank manifest_label", i)
            for i in dca_fingerprint_row_issues([Dict()])) &&
        any(occursin("duplicate manifest labels", i)
            for i in dca_fingerprint_row_issues(
                [Dict("manifest_label" => "a", "manifest_sha256" => "0"^64),
                 Dict("manifest_label" => "a",
                      "manifest_sha256" => "0"^64)])) &&
        isempty(dca_fingerprint_row_issues(
            [Dict("manifest_label" => "a", "manifest_sha256" => "0"^64),
             Dict("manifest_label" => "b", "manifest_sha256" => "1"^64)]))
    t["run_ledger_schema_validator"] = begin
        good = Dict("case" => "gate4_g3_run_ledger",
            "status" => "reviewed-complete",
            "jobs" => Dict(b => Dict("job_id" => 4999, "exit_code" => 0,
                "sbatch_sha256" => "0"^64, "log_sha256" => "0"^64,
                "output_sha256" => "0"^64) for b in ("lw", "sw")))
        validate_run_ledger(good)[1] &&
            !validate_run_ledger(merge(good, Dict("status" => "draft")))[1]
    end
    # SYNTHETIC exemplar (every live consumer is now hardened, so live
    # hardening == [] is the expected generated result): a synthetic
    # status-only verdict and a synthetic selftest-state verdict must
    # classify as FINDINGS through the exact production constructor,
    # and never surface as failures
    t["status_only_is_finding_not_failure"] = begin
        syn = dca_hardening_findings(Any[
            Dict("id" => "synthetic-status-only-edge",
                 "status_only_contract" => true,
                 "verdict" => "satisfied"),
            Dict("id" => "synthetic-selftest-edge",
                 "status_only_contract" => false,
                 "verdict" => "consumer_selftest_state"),
            Dict("id" => "synthetic-clean-edge",
                 "status_only_contract" => false,
                 "verdict" => "satisfied")])
        any(h -> h["id"] == "synthetic-status-only-edge", syn) &&
            any(h -> h["id"] == "synthetic-selftest-edge", syn) &&
            !any(h -> h["id"] == "synthetic-clean-edge", syn) &&
            !any(occursin("synthetic-status-only-edge", f) for f in fails)
    end
    rm(tdir, recursive = true, force = true)
    gates["fixtures"] = all(values(t)) ? "passed" : "failed"
    all(values(t)) || push!(fails, "fixtures failed: " *
        join([k for (k, v) in t if !v], ", "))

    status = (isempty(fails) && all(v == "passed" for v in values(gates))) ?
             "dependency_contract_audit_consistent" :
             "dependency_contract_audit_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_status_dependency_contract_audit",
        "data_mode" => "derivative_read_only_contract_audit",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "scope" => "status/case projection of every literal " *
            "JSON.parsefile-MEDIATED cross-artifact contract in " *
            "validation/gate4*.jl (other parsing forms, e.g. JSON.parse " *
            "over network responses in the V1/R1 recon units, are not " *
            "artifact contracts and are not censused), plus declared " *
            "extensions (register snapshot-hash, E9 prerequisite truth " *
            "table + reviewed-complete ledger schema, fingerprint-join " *
            "post-hoc rows with artifact identity, authority-input " *
            "truth table for the rulings intake); structural " *
            "requirements beyond that projection are enforced in-unit " *
            "by consumers and listed in structural_out_of_scope",
        "structural_out_of_scope" => DCA_STRUCTURAL_OUT_OF_SCOPE,
        "gates" => gates, "failures" => fails,
        "census" => Dict(
            "inclusion_rule" => "every literal JSON.parsefile occurrence " *
                "in validation/gate4*.jl (this audit excluded by name; " *
                "other parsing forms are out of the censused contract " *
                "surface); each live site AND each parsefile ledger " *
                "record matched EXACTLY once; union(served IDs) must " *
                "equal the manifest. Consumers that deliberately use a " *
                "coupled BYTE-snapshot parse (one read supplies digest " *
                "AND content, closing the hash-vs-parse TOCTOU) -- " *
                "each declared as its own extension record (currently " *
                "ric_snapshot, pcc_snapshot, gd_snapshot, fl_snapshot, " *
                "and pf_snapshot) -- are NOT " *
                "parsefile sites: each such helper is carried as a " *
                "declared-snapshot-extension ledger record whose anchor " *
                "reconciliation binds directly against the consumer " *
                "source (and which must never match a live parsefile " *
                "site). n_sites therefore counts live JSON.parsefile " *
                "sites only; the extensions are counted separately in " *
                "n_declared_snapshot_extensions.",
            "source_glob" => "validation/gate4*.jl",
            "n_sites" => length(sites),
            "n_declared_snapshot_extensions" =>
                count(x -> x.class == "declared-snapshot-extension",
                      DCA_SITE_LEDGER),
            "sites" => [Dict("file" => s.file, "line" => s.line,
                             "text" => first(s.text, 100)) for s in sites],
            "site_ledger" => [Dict("file" => x.file, "anchor" => x.anchor,
                "class" => x.class, "edge_ids" => collect(x.edge_ids),
                "reason" => x.reason) for x in DCA_SITE_LEDGER]),
        "modes_observed" => Dict("a2" => String(modes.a2),
            "r2" => String(modes.r2),
            "sw_init" => String(modes.sw_init),
            "g3_run_ledger_present" => modes.g3_ledger_present),
        "contract_satisfaction" => Dict(
            "n_edges" => length(DCA_EDGES),
            "satisfied" => n_sat, "inactive_branch" => n_inact,
            "consumer_selftest_state" => n_self,
            "violated" => n_viol, "verdicts" => verdicts),
        "hardening_findings" => hardening,
        "fixture_verdicts" => t,
        "provenance" => Dict("branch" => branch,
            "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working " *
                "tree before its own commit"),
        "disclaimer" => "derivative read-only STATUS/CASE-PROJECTION " *
            "contract audit; consumer contracts modeled faithfully " *
            "(status-only contracts are hardening findings, not " *
            "upgraded); no election, no state mutation, no unit " *
            "execution, no submission/fetch/deletion/quota action.",
    )
    mkpath(dirname(DCA_RESULTS_JSON))
    open(DCA_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(DCA_RESULTS_MD, "w") do io
        println(io, "# Gate-4 status/case-projection dependency contract " *
                    "audit\n")
        println(io, "Status: **$status**\n")
        println(io, result["scope"], "\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Verdict |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nCensus: $(length(sites)) parse sites reconciled " *
                    "with edge linkage; modes a2=$(modes.a2) " *
                    "r2=$(modes.r2) sw_init=$(modes.sw_init) " *
                    "g3_ledger_present=$(modes.g3_ledger_present).")
        println(io, "\n## Contract verdicts ($(n_sat) satisfied / " *
                    "$(n_inact) inactive / $(n_self) selftest-state / " *
                    "$(n_viol) violated)\n")
        for v in verdicts
            println(io, "- $(v["id"]) [$(v["kind"])]: **$(v["verdict"])** " *
                        "-- $(get(v, "detail", ""))")
        end
        println(io, "\n## Hardening findings ($(length(hardening)))\n")
        for h in hardening
            println(io, "- $(h["id"]): $(h["finding"])")
        end
        println(io, "\n## Structural checks out of scope\n")
        for (k, v) in sort(collect(DCA_STRUCTURAL_OUT_OF_SCOPE); by = first)
            println(io, "- **$k**: $v")
        end
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_status_dependency_contract_audit: $status " *
            "($(n_sat)/$(length(DCA_EDGES)) satisfied, $(n_inact) inactive)")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), first(fails, 12))
    return status == "dependency_contract_audit_consistent" ? 0 : 1
end

exit(dca_main())
