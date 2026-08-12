# Gate-4 STATUS/CASE-PROJECTION DEPENDENCY CONTRACT AUDIT (derivative,
# read-only; no election, no state mutation, no unit execution).
#
# SCOPE (explicit, monitor-directed): this audit verifies the STATUS/CASE
# PROJECTION of every literal JSON.parsefile-MEDIATED cross-artifact
# contract in validation/gate4*.jl (other parsing forms are outside the
# censused surface), plus three declared per-kind extensions -- the
# register snapshot-hash contract, the E9 prerequisite truth table with
# reviewed-complete ledger schema, and the fingerprint-join post-hoc row
# contract.
# STRUCTURAL requirements beyond that projection (attempt strings, output
# hashes, arithmetic identities, boundary flags, D-key sets) are enforced
# in-unit by the consumers themselves and are OUT OF SCOPE here; they are
# listed per edge family in structural_out_of_scope.
#
# Design (second-pass, after monitor review of the first pass):
#   - a UNIFIED parse-site ledger classifies every live JSON.parsefile
#     site as `edge` (carrying the exact served edge_id(s)) or an
#     excluded class; reconciliation requires every live site matched
#     exactly once, every ledger record matched by a live site, AND
#     union(served edge IDs) == the manifest ID set -- an omitted known
#     edge can no longer pass;
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

const DCA_KNOWN_KINDS = (:exact, :set, :prefix, :mode_dependent,
                         :register_snapshot, :fingerprint_join,
                         :absence_tolerant)

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

# E9 prerequisite truth table (FAITHFUL to both consumers: G1 and G3
# check recovered OUTPUTS before RUN_LEDGER):
#   outputs absent                       -> waiting (whether the ledger is
#                                           absent OR present)
#   outputs present + ledger absent      -> blocked_missing_run_ledger
#   outputs present + ledger UNPARSEABLE -> ASYMMETRIC: G1 catches parse
#     errors (blocked_invalid); G3 does NOT catch JSON.parsefile -- an
#     execution/refusal GAP with NO faithful emitted status (empty
#     allowed set; any artifact status in that state is a violation, and
#     the gap itself is a standing hardening finding)
#   outputs present + parseable schema-invalid -> blocked_invalid
#   outputs present + ledger valid      -> only the consumer-specific
#                                           downstream status set
# tokens = (waiting, missing, invalid, downstream::Vector)
# parse_success = JSON.parsefile completed without throwing (a ledger
# containing JSON null PARSES successfully to nothing -- it is NOT a
# parse failure); object_ok = the parsed value is an object. G1 maps
# unparseable AND parsed-non-object to blocked_invalid; G3 throws on
# unparseable AND on non-object (validate_run_ledger indexes it), so both
# are no-faithful-status gaps there.
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

function dca_modes()
    a2_sub = try
        JSON.parsefile(validation_results_path("gate4_a2_submission_ledger.json"))
    catch; nothing end
    a2_hist = dca_str(get(dca_obj(a2_sub), "status", "")) ==
              "a2_attempt2_completed_candidates_collected"
    return (a2 = a2_hist ? :historical : :preexecution,
            r2 = isfile(DCA_R2_V14_RAW) ? :historical : :preexecution,
            g3_ledger_present =
                isfile(validation_results_path("gate4_g3_run_ledger.json")))
end

# Edge fields: id, consumer, anchors, producer, kind, accepted (or
# accepted_by_mode + mode_axis), expected_case, consumer_checks_case
# (ACTUAL contract), status_only (hardening flag), active_when
const DCA_EDGES = [
 (id = "dep:sw_init_checkpoint<-option_b", consumer = "gate4_sw_init_generation_checkpoint.jl",
  anchors = ["dr[\"status\"] == \"option_b_adopted_candidates_promoted\""],
  producer = "gate4_option_b_decision_record.json", kind = :exact,
  accepted = ["option_b_adopted_candidates_promoted"],
  expected_case = "gate4_option_b_decision_record",
  consumer_checks_case = false, status_only = true, active_when = :always),
 (id = "dep:r2_proof_scaffold<-r1_probe", consumer = "gate4_r2_sw_matching_version_proof_scaffold.jl",
  anchors = ["r1[\"status\"] == \"r1_sw_mapping_found_lw_ambiguous\""],
  producer = "gate4_r1_release_provenance_probe.json", kind = :exact,
  accepted = ["r1_sw_mapping_found_lw_ambiguous"],
  expected_case = "gate4_r1_release_provenance_probe",
  consumer_checks_case = false, status_only = true, active_when = :always),
 (id = "dep:r2_proof_scaffold<-r2_finding_ledger:historical",
  consumer = "gate4_r2_sw_matching_version_proof_scaffold.jl",
  anchors = ["fin[\"status\"] == \"r2_ssi_resolved_drift_version_independent\""],
  producer = "gate4_r2_finding_ledger.json", kind = :mode_dependent,
  accepted = ["r2_ssi_resolved_drift_version_independent"],
  expected_case = "gate4_r2_finding_ledger",
  consumer_checks_case = true, status_only = false,
  active_when = :r2_historical),
 (id = "dep:r2_proof_scaffold<-option_b:historical",
  consumer = "gate4_r2_sw_matching_version_proof_scaffold.jl",
  anchors = ["get(ob, \"status\", \"\") == \"option_b_adopted_candidates_promoted\""],
  producer = "gate4_option_b_decision_record.json", kind = :mode_dependent,
  accepted = ["option_b_adopted_candidates_promoted"],
  expected_case = "gate4_option_b_decision_record",
  consumer_checks_case = false, status_only = true,
  active_when = :r2_historical),
 (id = "dep:r2_proof_scaffold<-init_provenance_ledger:historical",
  consumer = "gate4_r2_sw_matching_version_proof_scaffold.jl",
  anchors = ["get(ip, \"case\", \"\") == \"gate4_init_provenance_ledger\""],
  producer = "gate4_init_provenance_ledger.json", kind = :mode_dependent,
  accepted = ["acceptance_inits_complete"],
  expected_case = "gate4_init_provenance_ledger",
  consumer_checks_case = true, status_only = false,
  active_when = :r2_historical),
 (id = "dep:r2_exec_checkpoint<-r2_proof_scaffold",
  consumer = "gate4_r2_execution_checkpoint.jl",
  anchors = ["scaffold_status in (\"r2_scaffold_ready_awaiting_authorization\","],
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
  consumer_checks_case = false, status_only = true, active_when = :always),
 (id = "dep:r2_exec_checkpoint<-r2_finding_ledger:historical",
  consumer = "gate4_r2_execution_checkpoint.jl",
  anchors = ["fin_ok = as_str(get(fin_obj, \"case\", \"\")) ==",
             "\"r2_ssi_resolved_drift_version_independent\""],
  producer = "gate4_r2_finding_ledger.json", kind = :mode_dependent,
  accepted = ["r2_ssi_resolved_drift_version_independent"],
  expected_case = "gate4_r2_finding_ledger",
  consumer_checks_case = true, status_only = false,
  active_when = :r2_historical),
 (id = "dep:a2_proof_scaffold<-a2_exec_checkpoint",
  consumer = "gate4_a2_reproduction_proof_scaffold.jl",
  anchors = ["chk[\"status\"] in (\"a2_execution_checkpoint_ready\","],
  producer = "gate4_a2_execution_checkpoint.json", kind = :set,
  accepted = ["a2_execution_checkpoint_ready",
              "a2_execution_checkpoint_historical_executed"],
  expected_case = "gate4_a2_execution_checkpoint",
  consumer_checks_case = false, status_only = true, active_when = :always),
 (id = "dep:a2_proof_driver<-a2_proof_scaffold",
  consumer = "gate4_a2_proof_driver_checkpoint.jl",
  anchors = ["scaffold[\"status\"] == \"a2_proof_scaffold_ready\""],
  producer = "gate4_a2_reproduction_proof_scaffold.json", kind = :exact,
  accepted = ["a2_proof_scaffold_ready"],
  expected_case = "gate4_a2_reproduction_proof_scaffold",
  consumer_checks_case = false, status_only = true, active_when = :always),
 (id = "dep:a2_proof_driver<-a2_proof_finding_ledger:historical",
  consumer = "gate4_a2_proof_driver_checkpoint.jl",
  anchors = ["get(fin, \"case\", \"\") == \"gate4_a2_proof_finding_ledger\""],
  producer = "gate4_a2_proof_finding_ledger.json", kind = :mode_dependent,
  accepted = ["a2_candidates_sensitivity_only_not_promotable"],
  expected_case = "gate4_a2_proof_finding_ledger",
  consumer_checks_case = true, status_only = false,
  active_when = :a2_historical),
 (id = "dep:a2_proof_driver<-a2_proof_submission_ledger:historical",
  consumer = "gate4_a2_proof_driver_checkpoint.jl",
  anchors = ["get(sub, \"case\", \"\") == \"gate4_a2_proof_submission_ledger\""],
  producer = "gate4_a2_proof_submission_ledger.json", kind = :mode_dependent,
  accepted = ["proof_run_submitted_awaiting_completion"],
  expected_case = "gate4_a2_proof_submission_ledger",
  consumer_checks_case = true, status_only = false,
  active_when = :a2_historical),
 (id = "dep:a2_proof_driver<-option_b:historical",
  consumer = "gate4_a2_proof_driver_checkpoint.jl",
  anchors = ["ob_ok = get(ob, \"status\", \"\") == \"option_b_adopted_candidates_promoted\""],
  producer = "gate4_option_b_decision_record.json", kind = :mode_dependent,
  accepted = ["option_b_adopted_candidates_promoted"],
  expected_case = "gate4_option_b_decision_record",
  consumer_checks_case = false, status_only = true,
  active_when = :a2_historical),
 (id = "dep:a2_exec_checkpoint<-a2_submission_ledger:mode_selection",
  consumer = "gate4_a2_execution_checkpoint.jl",
  anchors = ["\"a2_attempt2_completed_candidates_collected\""],
  producer = "gate4_a2_submission_ledger.json", kind = :mode_dependent,
  accepted = ["a2_attempt2_completed_candidates_collected"],
  expected_case = "gate4_a2_submission_ledger",
  consumer_checks_case = true, status_only = false, active_when = :always),
 (id = "dep:a2_exec_checkpoint<-a2_rerun_manifest:preexecution",
  consumer = "gate4_a2_execution_checkpoint.jl",
  anchors = ["== \"a2_manifest_ready\""],
  producer = "gate4_a2_find_g_points_rerun_manifest.json",
  kind = :mode_dependent,
  accepted = ["a2_manifest_ready"],
  expected_case = "gate4_a2_find_g_points_rerun_manifest",
  consumer_checks_case = false, status_only = true,
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
 (id = "dep:a2_rerun_manifest<-a1_upstream_recon",
  consumer = "gate4_a2_find_g_points_rerun_manifest.jl",
  anchors = ["a1[\"status\"] == \"a1_recon_no_exact_upstream_source_found\""],
  producer = "gate4_a1_upstream_recon.json", kind = :exact,
  accepted = ["a1_recon_no_exact_upstream_source_found"],
  expected_case = "gate4_a1_upstream_recon",
  consumer_checks_case = false, status_only = true, active_when = :always),
 (id = "dep:init_generation_manifest<-g2_g3_runner_scaffold",
  consumer = "gate4_init_generation_manifest.jl",
  anchors = ["startswith(scaffold[\"status\"], \"runner_scaffold_ready\")"],
  producer = "gate4_g2_g3_runner_scaffold.json", kind = :prefix,
  accepted = "runner_scaffold_ready",
  expected_case = "gate4_g2_g3_runner_scaffold",
  consumer_checks_case = false, status_only = true, active_when = :always),
 (id = "dep:g2_g3_runner_scaffold<-stage_config_audit",
  consumer = "gate4_g2_g3_runner_scaffold.jl",
  anchors = ["cfg[\"status\"] == \"stage_config_audit_passed\""],
  producer = "gate4_stage_config_audit.json", kind = :exact,
  accepted = ["stage_config_audit_passed"],
  expected_case = "gate4_stage_config_audit",
  consumer_checks_case = false, status_only = true, active_when = :always),
 (id = "dep:g2_g3_runner_scaffold<-covariance_stride_audit",
  consumer = "gate4_g2_g3_runner_scaffold.jl",
  anchors = ["stride[\"status\"] == \"covariance_stride_audit_passed\""],
  producer = "gate4_covariance_stride_audit.json", kind = :exact,
  accepted = ["covariance_stride_audit_passed"],
  expected_case = "gate4_covariance_stride_audit",
  consumer_checks_case = false, status_only = true, active_when = :always),
 (id = "dep:g2a_checkpoint<-init_provenance_ledger",
  consumer = "gate4_g2a_sw_rgb_flux_checkpoint.jl",
  anchors = ["init[\"status\"] == \"acceptance_inits_complete\""],
  producer = "gate4_init_provenance_ledger.json", kind = :exact,
  accepted = ["acceptance_inits_complete"],
  expected_case = "gate4_init_provenance_ledger",
  consumer_checks_case = false, status_only = true, active_when = :always),
 (id = "dep:g2b_checkpoint<-g2a_data_ledger",
  consumer = "gate4_g2b_sw_rgb_variants_checkpoint.jl",
  anchors = ["g2a[\"status\"] == \"sw_rgb_rel_training_fluxes_installed_and_verified\""],
  producer = "gate4_g2a_data_ledger.json", kind = :exact,
  accepted = ["sw_rgb_rel_training_fluxes_installed_and_verified"],
  expected_case = "gate4_g2a_data_ledger",
  consumer_checks_case = false, status_only = true, active_when = :always),
 (id = "dep:g3_executor<-scoped_preflight",
  consumer = "gate4_g3_executor_checkpoint.jl",
  anchors = ["pf[\"status\"] == \"g3_scoped_preflight_ready\""],
  producer = "gate4_g3_scoped_input_preflight.json", kind = :set,
  # FAITHFUL: the executor tolerates waiting-for-eval2 (its own status
  # becomes g3_executor_waiting_for_eval2, accepted exit-0); only the
  # ready->go path needs g3_scoped_preflight_ready
  accepted = ["g3_scoped_preflight_ready",
              "g3_scoped_preflight_waiting_for_eval2"],
  expected_case = "gate4_g3_scoped_input_preflight",
  consumer_checks_case = false, status_only = true, active_when = :always),
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
  anchors = ["expected_status = \"g2c_checkpoint_blocked_by_quota\""],
  producer = "gate4_g2c_eval2_fetch_checkpoint.json",
  kind = :register_snapshot,
  accepted = ["g2c_checkpoint_blocked_by_quota"],
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
 (id = "dep:v1_recon<-r1_probe:followup",
  consumer = "gate4_v1_version_skew_recon.jl",
  anchors = ["r1_status = ledger_status(\"gate4_r1_release_provenance_probe.json\")"],
  producer = "gate4_r1_release_provenance_probe.json", kind = :exact,
  accepted = ["r1_sw_mapping_found_lw_ambiguous"],
  expected_case = "gate4_r1_release_provenance_probe",
  consumer_checks_case = false, status_only = true, active_when = :always),
 (id = "dep:v1_recon<-r2_finding_ledger:followup",
  consumer = "gate4_v1_version_skew_recon.jl",
  anchors = ["r2_status = ledger_status(\"gate4_r2_finding_ledger.json\")"],
  producer = "gate4_r2_finding_ledger.json", kind = :exact,
  accepted = ["r2_ssi_resolved_drift_version_independent"],
  expected_case = "gate4_r2_finding_ledger",
  consumer_checks_case = false, status_only = true, active_when = :always),
 (id = "dep:v1_recon<-option_b:followup",
  consumer = "gate4_v1_version_skew_recon.jl",
  anchors = ["ob_status = ledger_status(\"gate4_option_b_decision_record.json\")"],
  producer = "gate4_option_b_decision_record.json", kind = :exact,
  accepted = ["option_b_adopted_candidates_promoted"],
  expected_case = "gate4_option_b_decision_record",
  consumer_checks_case = false, status_only = true, active_when = :always),
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
             "ledger = JSON.parsefile(RUN_LEDGER)",
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
  # G3 does NOT try/catch JSON.parsefile(RUN_LEDGER) and
  # validate_run_ledger indexes the parsed value: unparseable AND
  # non-object are both uncaught-exception gaps, standing hardening
  # finding
  catches_ledger_parse_errors = false,
  maps_nonobject_to_invalid = false,
  selftest_status = "g3_acceptance_selftest_failed",  # emitted BEFORE
  # the output checks
  # full source binding: root constant, BOTH recovered constants (with
  # filenames inline), the output-first check, and the exact DIRECT
  # no-catch parse shape as evidence of the gap
  output_anchors = ["const G4 = \"/shared/home/greg/ecckd-derived-flux-work/g4-init-generation\"",
                    "const LW_RECOVERED = \"\$G4/work/lw_ckd-definition/ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc\"",
                    "const SW_RECOVERED = \"\$G4/work-v14/sw_ckd-definition/ecckd-1.4_sw_ckd-definition_climate_rgb-tol0.047.nc\"",
                    "missing_out = [p for p in (LW_RECOVERED, SW_RECOVERED) if !isfile(p)]",
                    "ledger = JSON.parsefile(RUN_LEDGER)"],
  expected_case = "gate4_g3_acceptance_comparison",
  consumer_checks_case = false, status_only = false, active_when = :always),
]

# declarative-manifest schema/invariant validation (pure; fixture-tested)
const DCA_ALLOWED_ACTIVE_WHEN = (:always, :a2_historical,
                                 :a2_preexecution, :r2_historical)
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
  anchor = "JSON.parsefile(validation_results_path(name))",
  class = "edge", edge_ids = ["dep:a2_exec_checkpoint<-a2_rerun_manifest:preexecution"],
  reason = "ax_parse! helper body"),
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
  anchor = "a1 = JSON.parsefile(validation_results_path(\"gate4_a1_upstream_recon.json\"))",
  class = "edge", edge_ids = ["dep:a2_rerun_manifest<-a1_upstream_recon"],
  reason = "a1 prerequisite parse"),
 (file = "gate4_a2_proof_driver_checkpoint.jl",
  anchor = "fin = JSON.parsefile(PD_FINDING_LEDGER)",
  class = "edge", edge_ids = ["dep:a2_proof_driver<-a2_proof_finding_ledger:historical"],
  reason = "historical finding-ledger parse"),
 (file = "gate4_a2_proof_driver_checkpoint.jl",
  anchor = "sub = JSON.parsefile(PD_SUBMISSION_LEDGER)",
  class = "edge", edge_ids = ["dep:a2_proof_driver<-a2_proof_submission_ledger:historical"],
  reason = "historical submission-ledger parse"),
 (file = "gate4_a2_proof_driver_checkpoint.jl",
  anchor = "ob = JSON.parsefile(",
  class = "edge", edge_ids = ["dep:a2_proof_driver<-option_b:historical"],
  reason = "historical option-B parse"),
 (file = "gate4_a2_proof_driver_checkpoint.jl",
  anchor = "scaffold = JSON.parsefile(",
  class = "edge", edge_ids = ["dep:a2_proof_driver<-a2_proof_scaffold"],
  reason = "proof-scaffold prerequisite parse"),
 (file = "gate4_a2_reproduction_proof_scaffold.jl",
  anchor = "chk = JSON.parsefile(validation_results_path(\"gate4_a2_execution_checkpoint.json\"))",
  class = "edge", edge_ids = ["dep:a2_proof_scaffold<-a2_exec_checkpoint"],
  reason = "execution-checkpoint prerequisite parse"),
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
  anchor = "cfg = JSON.parsefile(validation_results_path(\"gate4_stage_config_audit.json\"))",
  class = "edge", edge_ids = ["dep:g2_g3_runner_scaffold<-stage_config_audit"],
  reason = "stage-config prerequisite parse"),
 (file = "gate4_g2_g3_runner_scaffold.jl",
  anchor = "stride = JSON.parsefile(validation_results_path(\"gate4_covariance_stride_audit.json\"))",
  class = "edge", edge_ids = ["dep:g2_g3_runner_scaffold<-covariance_stride_audit"],
  reason = "covariance-stride prerequisite parse"),
 (file = "gate4_g2a_sw_rgb_flux_checkpoint.jl",
  anchor = "init = JSON.parsefile(validation_results_path(\"gate4_init_provenance_ledger.json\"))",
  class = "edge", edge_ids = ["dep:g2a_checkpoint<-init_provenance_ledger"],
  reason = "init-ledger prerequisite parse"),
 (file = "gate4_g2b_sw_rgb_variants_checkpoint.jl",
  anchor = "g2a = JSON.parsefile(validation_results_path(\"gate4_g2a_data_ledger.json\"))",
  class = "edge", edge_ids = ["dep:g2b_checkpoint<-g2a_data_ledger"],
  reason = "g2a-ledger prerequisite parse"),
 (file = "gate4_g3_acceptance_comparison.jl",
  anchor = "JSON.parsefile(AC_RESULTS_JSON)",
  class = "own-artifact", edge_ids = String[],
  reason = "waiting-path parse-back self-test of own results"),
 (file = "gate4_g3_acceptance_comparison.jl",
  anchor = "ledger = JSON.parsefile(RUN_LEDGER)",
  class = "edge", edge_ids = ["dep:g3_acceptance<-g3_run_ledger"],
  reason = "run-ledger parse (absence-tolerant edge)"),
 (file = "gate4_g3_executor_checkpoint.jl",
  anchor = "pf = JSON.parsefile(validation_results_path(\"gate4_g3_scoped_input_preflight.json\"))",
  class = "edge", edge_ids = ["dep:g3_executor<-scoped_preflight"],
  reason = "scoped-preflight prerequisite parse"),
 (file = "gate4_init_generation_manifest.jl",
  anchor = "scaffold = JSON.parsefile(",
  class = "edge", edge_ids = ["dep:init_generation_manifest<-g2_g3_runner_scaffold"],
  reason = "runner-scaffold prerequisite parse"),
 (file = "gate4_pending_rulings_register.jl",
  anchor = "JSON.parsefile(path)",
  class = "edge",
  edge_ids = ["dep:rulings_register<-g2_binding_scaffold",
              "dep:rulings_register<-g2c_fetch_checkpoint",
              "dep:rulings_register<-g2c_failure_ledger_4440"],
  reason = "verify_json_source helper body (register edges + fixtures)"),
 (file = "gate4_r1_release_provenance_probe.jl",
  anchor = "d = JSON.parsefile(validation_results_path(name))",
  class = "edge",
  edge_ids = ["dep:r1_probe<-r2_finding_ledger:followup",
              "dep:r1_probe<-option_b:followup"],
  reason = "dep_case_status helper body"),
 (file = "gate4_r2_execution_checkpoint.jl",
  anchor = "JSON.parsefile(validation_results_path(name))",
  class = "edge",
  edge_ids = ["dep:r2_exec_checkpoint<-r2_proof_scaffold",
              "dep:r2_exec_checkpoint<-r2_finding_ledger:historical"],
  reason = "parse_artifact! helper body"),
 (file = "gate4_r2_sw_matching_version_proof_scaffold.jl",
  anchor = "r1 = JSON.parsefile(validation_results_path(\"gate4_r1_release_provenance_probe.json\"))",
  class = "edge", edge_ids = ["dep:r2_proof_scaffold<-r1_probe"],
  reason = "r1 prerequisite parse"),
 (file = "gate4_r2_sw_matching_version_proof_scaffold.jl",
  anchor = "fin = JSON.parsefile(validation_results_path(\"gate4_r2_finding_ledger.json\"))",
  class = "edge", edge_ids = ["dep:r2_proof_scaffold<-r2_finding_ledger:historical"],
  reason = "finding-ledger historical parse"),
 (file = "gate4_r2_sw_matching_version_proof_scaffold.jl",
  anchor = "ob = JSON.parsefile(",
  class = "edge", edge_ids = ["dep:r2_proof_scaffold<-option_b:historical"],
  reason = "option-B historical parse"),
 (file = "gate4_r2_sw_matching_version_proof_scaffold.jl",
  anchor = "ip = JSON.parsefile(",
  class = "edge", edge_ids = ["dep:r2_proof_scaffold<-init_provenance_ledger:historical"],
  reason = "init-provenance historical parse"),
 (file = "gate4_sw_init_generation_checkpoint.jl",
  anchor = "dr = JSON.parsefile(validation_results_path(\"gate4_option_b_decision_record.json\"))",
  class = "edge", edge_ids = ["dep:sw_init_checkpoint<-option_b"],
  reason = "option-B prerequisite parse"),
 (file = "gate4_v1_version_skew_recon.jl",
  anchor = "String(JSON.parsefile(validation_results_path(name))[\"status\"])",
  class = "edge",
  edge_ids = ["dep:v1_recon<-r1_probe:followup",
              "dep:v1_recon<-r2_finding_ledger:followup",
              "dep:v1_recon<-option_b:followup"],
  reason = "ledger_status helper body (status-only)"),
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
        "schema only")

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

# reconciliation: every live site matched exactly once; every ledger
# record matched by exactly one live site; union of served edge_ids ==
# the manifest ID set (both directions)
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
    # each ledger record must be matched by EXACTLY one live site
    for (li, x) in enumerate(ledger)
        ledger_hits[li] == 0 &&
            push!(issues, "DANGLING ledger record (no live site): " *
                          "$(x.file) anchor $(first(x.anchor, 60))")
        ledger_hits[li] > 1 &&
            push!(issues, "MULTI-MATCHED ledger record ($(ledger_hits[li]) " *
                          "live sites): $(x.file) anchor " *
                          "$(first(x.anchor, 60))")
    end
    served = sort(unique(vcat([collect(x.edge_ids) for x in ledger
                               if x.class == "edge"]...)))
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
    gates["manifest_edge_count_34"] =
        length(DCA_EDGES) == 34 ? "passed" : "failed"
    length(DCA_EDGES) == 34 ||
        push!(fails, "manifest has $(length(DCA_EDGES)) edges, expected 34")
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

    hardening = [Dict("id" => v["id"],
                      "finding" => "status-only contract (no case check); " *
                          "weakness, not a violation")
                 for v in verdicts if get(v, "status_only_contract", false)]
    # standing asymmetry finding: G3 catches neither unparseable ledger
    # JSON nor a parsed non-object
    push!(hardening, Dict("id" => "dep:g3_acceptance<-g3_run_ledger",
        "finding" => "consumer does not try/catch " *
            "JSON.parsefile(RUN_LEDGER) and validate_run_ledger indexes " *
            "the parsed value: an UNPARSEABLE OR PARSED-NON-OBJECT " *
            "present ledger is an uncaught-exception gap with no " *
            "faithful emitted status (G1 handles both cases as " *
            "blocked_invalid); weakness, not a current violation " *
            "(ledger absent)"))
    # explicitly classified self-test states are surfaced, never called
    # dependency inconsistencies
    for v in verdicts
        v["verdict"] == "consumer_selftest_state" && push!(hardening,
            Dict("id" => v["id"],
                 "finding" => "consumer is in its self-test-failure " *
                     "status; classified explicitly, not a dependency " *
                     "inconsistency"))
    end

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
    # consumer styles (G1: catches+maps; G3: neither)
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
        # malformed: G1 -> invalid; G3 -> gap (no faithful status)
        dca_e9_allowed_statuses(true, true, false, nothing, nothing,
                                tk; g1s...) == ["I"] &&
        dca_e9_allowed_statuses(true, true, false, nothing, nothing,
                                tk; g3s...) == String[] &&
        # null / array: parse succeeds, object_ok=false:
        # G1 -> invalid ("not an object"); G3 -> gap
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
    t["status_only_is_finding_not_failure"] =
        any(h -> h["id"] == "dep:sw_init_checkpoint<-option_b", hardening) &&
        !any(occursin("dep:sw_init_checkpoint<-option_b", f) for f in fails)
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
            "post-hoc rows with artifact identity); structural " *
            "requirements beyond that projection are enforced in-unit " *
            "by consumers and listed in structural_out_of_scope",
        "structural_out_of_scope" => DCA_STRUCTURAL_OUT_OF_SCOPE,
        "gates" => gates, "failures" => fails,
        "census" => Dict(
            "inclusion_rule" => "every literal JSON.parsefile occurrence " *
                "in validation/gate4*.jl (this audit excluded by name; " *
                "other parsing forms are out of the censused contract " *
                "surface); each live site AND each ledger record matched " *
                "EXACTLY once; union(served IDs) must equal the manifest",
            "source_glob" => "validation/gate4*.jl",
            "n_sites" => length(sites),
            "sites" => [Dict("file" => s.file, "line" => s.line,
                             "text" => first(s.text, 100)) for s in sites],
            "site_ledger" => [Dict("file" => x.file, "anchor" => x.anchor,
                "class" => x.class, "edge_ids" => collect(x.edge_ids),
                "reason" => x.reason) for x in DCA_SITE_LEDGER]),
        "modes_observed" => Dict("a2" => String(modes.a2),
            "r2" => String(modes.r2),
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
                    "r2=$(modes.r2) " *
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
