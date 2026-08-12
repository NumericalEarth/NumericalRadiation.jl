# Gate-4 A2 EXECUTION CHECKPOINT + proof scaffold (dry-run; NO submission)
# -- HISTORICAL POST-EXECUTION MODE selected by the COMPLETED submission
# ledger (case + status), never by live-file presence.
#
# EXECUTED (monitor-directed marking, 2026-08-12): the generated sbatch
# ran as job 4082 (attempt 2; attempt 1 was job 4079 running an EARLIER
# script revision with a different sha, recorded in the submission
# ledger's attempt_history and the 4079 failure ledger). Job 4082 ran
# merge_well_mixed + reorder_spectrum + find_g_points ONLY -- it produced
# exactly TWO g-point candidates (LW fsck-tol0.0161 and SW rgb-tol0.047)
# plus the rayleigh input-generation overlay; NO create_lut or raw-init
# output is attributable to 4082 (those belong to the later proof-driver
# chain, job 4091). When both candidates exist on disk, this unit runs
# HISTORICAL VERIFICATION that is read-only with respect to execution
# artifacts (it still writes its own JSON/MD): the executed sbatch is
# PRESERVED (never rewritten) and byte-verified against the submission
# ledger's recorded sbatch sha; candidates, overlay, job id, and outcome
# are verified from the submission ledger with fail-closed normalization;
# the follow-on proof disposition is rendered only after verifying the
# proof finding ledger and Option-B record (case + status). The
# pre-execution generation path is retained for the candidates-absent
# world.
#
# Original contract: generates the exact Slurm batch script for the A2
# merge_well_mixed + reorder + find_g_points run (LW fsck tol 0.0161, SW
# rgb tol 0.047 FIRST, per the pinned do_all stage lists) and records the
# follow-on exact-reproduction proof plan. The batch script is WRITTEN
# but never submitted by this unit; it refuses head-node execution by
# guard. No find_g_points/create_lut/objective/floor execution.
#
# REVISED after job 4079 FAILED at LW reorder: the previous script skipped
# do_all stage 1 (merge_well_mixed_{lw,sw}.sh), so the quarantined WORK_DIR
# had no composite spectra. Additionally the SW composite requires
# ckdmip_mmm_sw_spectra_rayleigh_present.h5 (COMPOSITE_SW_INCLUDES_RAYLEIGH=yes
# in the pinned config), absent from the local MMM tree and 404 on ECPDS;
# it is provisioned in a QUARANTINED INPUT OVERLAY (never mutating
# $CKDMIP_ROOT) using the upstream author's own pinned recipe
# (ckdmip-1.0/work/sw/make_rayleigh_mmm.sh): ckdmip_tool --grid
# <mmm sw h2o_median> --rayleigh.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const WORKCOPY = "/shared/home/greg/ecckd-derived-flux-work/ecckd"
const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"
const CKDMIP_BIN = "/shared/home/greg/build/ckdmip-1.0/bin"
const CKDMIP_TOOL = "$CKDMIP_BIN/ckdmip_tool"
const RAYLEIGH_RECIPE = "/shared/home/greg/build/ckdmip-1.0/work/sw/make_rayleigh_mmm.sh"

# binaries every A2 stage needs (relocation-proof preflight)
const CKDMIP_BINARIES = ["ckdmip_lw", "ckdmip_sw", "ckdmip_tool"]
const ECCKD_BINARIES = ["reorder_spectrum", "find_g_points",
                        "reorder_cloud_spectrum"]

# per-gas MMM spectra consumed by merge_well_mixed_{lw,sw}.sh (present +
# climate --conc-scaled merges), by the reorder GAS_LISTs, and by
# find_g_points climate (h2o/o3 minimum as background_input)
const MERGE_GASES = ["o2_constant", "n2_constant", "co2_present",
                     "ch4_present", "n2o_present",
                     "cfc11_present-equivalent", "cfc12_present"]
const REORDER_FIND_GASES = ["h2o_median", "o3_median",
                            "h2o_minimum", "o3_minimum"]

const AX_RESULTS_JSON = validation_results_path("gate4_a2_execution_checkpoint.json")
const AX_RESULTS_MD = validation_results_path("gate4_a2_execution_checkpoint.md")
const AX_SBATCH = validation_results_path("gate4_a2_dryrun.sbatch")

# the two 4082 g-point candidates (find_g_points outputs; NOTHING else is
# attributable to 4082) and the rayleigh input-generation overlay
const AX_LW_CAND = "$G4WORK/work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5"
const AX_SW_CAND = "$G4WORK/work/sw_gpoints/ecckd-1.2_sw_gpoints_climate_rgb-tol0.047.h5"
const AX_OVERLAY = "$G4WORK/input/mmm/sw_spectra/ckdmip_mmm_sw_spectra_rayleigh_present.h5"

# fail-closed JSON normalizers (same contract as the R2 chain)
ax_obj(x) = x isa AbstractDict ? x : Dict{String, Any}()
ax_str(x) = x isa AbstractString ? String(x) : ""
ax_sha(p) = isfile(p) ? split(strip(read(`sha256sum $p`, String)))[1] : "missing"

# guarded rerun-manifest classifier (fixture-run via the absolute-path
# passthrough; the pre-execution prerequisite's ONLY loader, replacing
# the former single-use ax_parse!): FIVE fixed, distinct refusal
# classes -- missing; unparseable (parse failure); parses to a
# non-object (JSON null/array/scalar); case mismatch (exact
# gate4_a2_find_g_points_rerun_manifest); off-status with the verbatim
# token. Accepted: ONLY exact status a2_manifest_ready -- per the
# monitor's BINDING ruling the current
# a2_manifest_ready_waiting_for_inputs token is REJECTED and blocks
# pre-execution.
function ax_classify_rerun_manifest(name)
    path = isabspath(name) ? name : validation_results_path(name)
    isfile(path) ||
        return (false, "A2 rerun manifest missing")
    raw = try
        JSON.parsefile(path)
    catch
        return (false, "A2 rerun manifest unparseable (parse failure)")
    end
    raw isa AbstractDict ||
        return (false, "A2 rerun manifest parses to a non-object " *
                       "(JSON null/array/scalar)")
    c = get(raw, "case", "")
    (c isa AbstractString &&
     c == "gate4_a2_find_g_points_rerun_manifest") ||
        return (false, "A2 rerun manifest case mismatch: " *
                       (c isa AbstractString && !isempty(c) ? c :
                        "(missing/non-string)"))
    s = get(raw, "status", "")
    st = s isa AbstractString ? String(s) : "(missing/non-string)"
    st == "a2_manifest_ready" ||
        return (false, "A2 manifest not ready: $st")
    return (true, "ok")
end

# the pre-execution sbatch write happens ONLY behind the classified
# manifest prerequisite (mirrors the proven A2 proof-driver pattern);
# blocked/waiting pre-execution, historical, and anomaly all preserve
# the existing file
ax_should_write(mode, manifest_ok) =
    mode == :preexecution && manifest_ok
function ax_write_script(writefn, mode, manifest_ok)
    ax_should_write(mode, manifest_ok) || return false
    writefn()
    return true
end

# fail-closed gate closure (pure; fixture-run; standard discipline):
# whenever ANY gate is not passed the authoritative complete
# failed-gate census is appended, so failure reports can never omit a
# silent failed gate
function ax_close_failed_gates(fails, gates)
    failed = sort([k for (k, v) in gates if v != "passed"])
    out = copy(fails)
    isempty(failed) ||
        push!(out, "failed gates (fail-closed census): " *
                   join(failed, ", "))
    return out, isempty(failed)
end

const SBATCH_TEXT = """
#!/bin/bash
#SBATCH --job-name=g4-a2-find-g-points
#SBATCH --output=/shared/home/greg/data/ckdmip-logs/g4-a2-%j.log
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=60G
#SBATCH --partition=cpu-large

# Gate-4 A2: merge_well_mixed + reorder_spectrum + find_g_points ONLY (no
# LUT-creation, no optimisation, no objective stages). Generated by
# gate4_a2_execution_checkpoint.jl; DO NOT run outside Slurm.
set -euo pipefail
if [ -z "\${SLURM_JOB_ID:-}" ]; then
    echo "REFUSED: head-node execution is not permitted; submit via sbatch." >&2
    exit 64
fi

WORKCOPY=$WORKCOPY
G4WORK=$G4WORK
mkdir -p "\$G4WORK"

# scoped test-dir copy with WORK_DIR redirected to the quarantined g4 tree
# ISOLATED test-copy: never mutate the 4078 working copy; config.h
# hard-codes CKDMIP_DATA_DIR/WORK_DIR/BINDIR, so env-only localization is
# INSUFFICIENT -- all three are sed-patched ABSOLUTE in the copy (BINDIR in
# the pristine file is ../src/ecckd relative to test/, which would break in
# a relocated copy).
TESTCOPY="\$G4WORK/testcopy"
rm -rf "\$TESTCOPY"
cp -r "\$WORKCOPY/test" "\$TESTCOPY"
# MMM_SW_SPECTRA_DIR is redirected to a QUARANTINED INPUT OVERLAY (symlinks
# to the official per-gas files + locally generated rayleigh); the official
# data tree under CKDMIP_DATA_DIR is never written to.
sed -i \
  -e 's|^CKDMIP_DATA_DIR=.*|CKDMIP_DATA_DIR=$CKDMIP_ROOT|' \
  -e 's|^WORK_DIR=.*|WORK_DIR=$G4WORK/work|' \
  -e 's|^BINDIR=.*|BINDIR=$WORKCOPY/src/ecckd|' \
  -e 's|^MMM_SW_SPECTRA_DIR=.*|MMM_SW_SPECTRA_DIR=$G4WORK/input/mmm/sw_spectra|' \
  -e 's|^CLOUD_SPECTRUM=.*|CLOUD_SPECTRUM=$WORKCOPY/data/mie_droplet_scattering.nc|' \
  "\$TESTCOPY/config.h"
grep -E "^(CKDMIP_DATA_DIR|WORK_DIR|BINDIR|MMM_SW_SPECTRA_DIR|CLOUD_SPECTRUM)=" "\$TESTCOPY/config.h"
cd "\$TESTCOPY"

echo "=== A2 stage 0: binary + composite-input preflight + SW rayleigh overlay ==="
for b in $(join(CKDMIP_BINARIES, " ")); do
    test -x "$CKDMIP_BIN/\$b" || { echo "MISSING binary: \$b" >&2; exit 67; }
done
for b in $(join(ECCKD_BINARIES, " ")); do
    test -x "$WORKCOPY/src/ecckd/\$b" || { echo "MISSING binary: \$b" >&2; exit 67; }
done
test -s "$WORKCOPY/data/mie_droplet_scattering.nc" || { echo "MISSING cloud spectrum (mie)" >&2; exit 65; }
test -s "$CKDMIP_ROOT/evaluation1/sw_spectra/ckdmip_ssi.h5" || { echo "MISSING training SSI (cloud reorder wavenumber_input)" >&2; exit 65; }
MMM_LW=$CKDMIP_ROOT/mmm/lw_spectra
MMM_SW=$CKDMIP_ROOT/mmm/sw_spectra
for gas in $(join(vcat(MERGE_GASES, REORDER_FIND_GASES), " ")); do
    test -s "\$MMM_LW/ckdmip_mmm_lw_spectra_\${gas}.h5" || { echo "MISSING LW input: \$gas" >&2; exit 65; }
    test -s "\$MMM_SW/ckdmip_mmm_sw_spectra_\${gas}.h5" || { echo "MISSING SW input: \$gas" >&2; exit 65; }
done
test -s "$CKDMIP_ROOT/mmm/sw_spectra_extras/ckdmip_ssi.h5" || { echo "MISSING MMM SSI" >&2; exit 65; }
OVERLAY=\$G4WORK/input/mmm/sw_spectra
mkdir -p "\$OVERLAY"
ln -sf "\$MMM_SW"/*.h5 "\$OVERLAY/"
RAYLEIGH=\$OVERLAY/ckdmip_mmm_sw_spectra_rayleigh_present.h5
if [ ! -s "\$RAYLEIGH" ]; then
    # upstream author's pinned recipe (ckdmip-1.0/work/sw/make_rayleigh_mmm.sh)
    $CKDMIP_TOOL --grid "\$MMM_SW/ckdmip_mmm_sw_spectra_h2o_median.h5" --rayleigh -o "\$RAYLEIGH"
fi
test -s "\$RAYLEIGH" || { echo "MISSING SW rayleigh after overlay generation" >&2; exit 66; }
echo "rayleigh overlay provenance:"; sha256sum "\$RAYLEIGH"

echo "=== A2 LW stage 1: merge_well_mixed (composite spectra) ==="
APPLICATION=climate bash merge_well_mixed_lw.sh
echo "=== A2 LW: reorder (fsck) ==="
APPLICATION=climate BAND_STRUCTURE=fsck bash reorder_spectrum_lw.sh
echo "=== A2 LW: find_g_points (fsck, TOLERANCE=0.0161) ==="
APPLICATION=climate BAND_STRUCTURE=fsck TOLERANCE=0.0161 bash find_g_points_lw.sh
echo "=== A2 SW stage 1: merge_well_mixed (composite spectra incl rayleigh) ==="
APPLICATION=climate bash merge_well_mixed_sw.sh
echo "=== A2 SW: reorder (rgb) ==="
APPLICATION=climate BAND_STRUCTURE=rgb bash reorder_spectrum_sw.sh
echo "=== A2 SW: find_g_points (rgb, TOLERANCE=0.047) ==="
APPLICATION=climate BAND_STRUCTURE=rgb TOLERANCE=0.047 bash find_g_points_sw.sh

echo "=== A2 outputs ==="
find "$G4WORK/work" -name "*gpoints*" -o -name "*order*" | head -40
echo "=== A2 done rc=\$? \$(date -u +%FT%TZ) ==="
"""

function main()
    fails = String[]
    gates = Dict{String, String}()

    # classifier/writer/census fixtures FIRST, through the SAME
    # production code (counters and temp files ONLY -- AX_SBATCH is
    # never touched by any fixture)
    tdir = mktempdir()
    lt = Dict{String, Bool}()
    lt["missing_fails"] = begin
        r = ax_classify_rerun_manifest(joinpath(tdir, "absent.json"))
        !r[1] && r[2] == "A2 rerun manifest missing"
    end
    fpx = joinpath(tdir, "rm.json")
    write(fpx, "{")
    lt["malformed_fails"] = begin
        r = ax_classify_rerun_manifest(fpx)
        !r[1] && occursin("unparseable (parse failure)", r[2])
    end
    write(fpx, "null")
    lt["null_non_object_fails"] = begin
        r = ax_classify_rerun_manifest(fpx)
        !r[1] && occursin("non-object", r[2])
    end
    write(fpx, "[1]")
    lt["array_non_object_fails"] = begin
        r = ax_classify_rerun_manifest(fpx)
        !r[1] && occursin("non-object", r[2])
    end
    write(fpx, "{\"case\": \"other\", " *
               "\"status\": \"a2_manifest_ready\"}")
    lt["wrong_case_fails"] = begin
        r = ax_classify_rerun_manifest(fpx)
        !r[1] && occursin("case mismatch", r[2])
    end
    # BINDING RULING: the current live waiting token is REJECTED and
    # blocks pre-execution (named fixture, verbatim token)
    write(fpx, "{\"case\": \"gate4_a2_find_g_points_rerun_manifest\", " *
               "\"status\": \"a2_manifest_ready_waiting_for_inputs\"}")
    lt["waiting_for_inputs_token_rejected"] = begin
        r = ax_classify_rerun_manifest(fpx)
        !r[1] && r[2] ==
            "A2 manifest not ready: a2_manifest_ready_waiting_for_inputs"
    end
    write(fpx, "{\"case\": \"gate4_a2_find_g_points_rerun_manifest\", " *
               "\"status\": \"totally_bogus\"}")
    lt["tampered_status_fails"] = begin
        r = ax_classify_rerun_manifest(fpx)
        !r[1] && occursin("not ready: totally_bogus", r[2])
    end
    write(fpx, "{\"case\": \"gate4_a2_find_g_points_rerun_manifest\", " *
               "\"status\": \"a2_manifest_ready\"}")
    lt["exact_green_passes"] =
        ax_classify_rerun_manifest(fpx) == (true, "ok")
    lt["writer_only_green_preexecution"] = begin
        n = Ref(0)
        w = () -> (n[] += 1)
        ax_write_script(w, :preexecution, true) == true && n[] == 1 &&
            ax_write_script(w, :preexecution, false) == false &&
            ax_write_script(w, :historical, true) == false &&
            ax_write_script(w, :anomaly, true) == false && n[] == 1
    end
    lt["failed_gate_closed_without_reason"] = begin
        f1, ok1 = ax_close_failed_gates(String[], Dict("g" => "failed"))
        f2, ok2 = ax_close_failed_gates(String[], Dict("g" => "passed"))
        f3, ok3 = ax_close_failed_gates(["reason for a"],
            Dict("a" => "failed", "b" => "failed"))
        !ok1 && length(f1) == 1 &&
            occursin("fail-closed census", f1[1]) &&
            ok2 && isempty(f2) &&
            !ok3 && length(f3) == 2 && occursin("a, b", f3[2])
    end
    rm(tdir, recursive = true, force = true)
    gates["prerequisite_loader_fixture_tests"] =
        all(values(lt)) ? "passed" : "failed"
    all(values(lt)) || push!(fails, "prerequisite loader fixture " *
        "failures: " * join(sort([k for (k, v) in lt if !v]), ", "))

    # THREE-WAY MODE SELECTION from the SUBMISSION LEDGER (case + status),
    # never from live-file presence alone:
    #   :historical    -- ledger present, valid, completed
    #   :preexecution  -- NO ledger exists AND both candidates absent
    #   :anomaly       -- anything else (present-but-malformed/wrong-status
    #                     ledger, or candidates on disk without a ledger):
    #                     FAIL CLOSED; the sbatch is NEVER regenerated here
    sub_path = validation_results_path("gate4_a2_submission_ledger.json")
    sub_exists = isfile(sub_path)
    sub_raw = try
        sub_exists ? JSON.parsefile(sub_path) : nothing
    catch; nothing end
    sub_obj = ax_obj(sub_raw)
    ledger_completed =
        ax_str(get(sub_obj, "case", "")) == "gate4_a2_submission_ledger" &&
        ax_str(get(sub_obj, "status", "")) ==
            "a2_attempt2_completed_candidates_collected"
    n_cand_present = count(isfile, (AX_LW_CAND, AX_SW_CAND))
    mode = ledger_completed ? :historical :
           (!sub_exists && n_cand_present == 0) ? :preexecution : :anomaly
    historical = mode == :historical
    if historical
        # explicit gate for the ledger facts that selected this mode
        gates["submission_ledger_completed_verified"] = "passed"
    end
    if mode == :anomaly
        gates["mode_selection_fail_closed"] = "failed"
        push!(fails, sub_exists ?
            "submission ledger present but malformed/wrong case/status -- " *
            "FAIL CLOSED: neither historical claims nor sbatch " *
            "regeneration are permitted" :
            "no submission ledger but $(n_cand_present) candidate " *
            "file(s) on disk -- anomalous state; sbatch NOT regenerated")
    end

    # manifest prerequisite is a PRE-EXECUTION gate only (stale in
    # historical/anomaly modes); exact case+status through the guarded
    # classifier -- the waiting token BLOCKS pre-execution (binding
    # ruling; accepted is ONLY a2_manifest_ready)
    manifest_ok = false
    if mode == :preexecution
        manifest_ok, manifest_why = ax_classify_rerun_manifest(
            "gate4_a2_find_g_points_rerun_manifest.json")
        gates["rerun_manifest_prerequisite"] =
            manifest_ok ? "passed" : "failed"
        manifest_ok || push!(fails, manifest_why)
    end

    executed = Dict{String, Any}()
    if historical
        completion = ax_obj(get(sub_obj, "completion", nothing))
        job = ax_obj(get(sub_obj, "job", nothing))
        # job 4082 identity + completion marker, ledger-verified
        jid_ok = get(completion, "job_id", -1) == 4082 &&
                 get(job, "job_id", -1) == 4082
        gates["job_id_4082_verified"] = jid_ok ? "passed" : "failed"
        jid_ok || push!(fails, "submission ledger job_id != 4082")
        outcome = ax_str(get(completion, "outcome", ""))
        outcome_ok = occursin("COMPLETED", outcome) && occursin("rc=0", outcome)
        gates["completion_marker_verified"] = outcome_ok ? "passed" : "failed"
        outcome_ok || push!(fails, "completion outcome lacks COMPLETED/rc=0")
        # exactly TWO g-point candidates (find_g_points outputs; nothing
        # else is attributable to 4082). Missing BOTH or hash mismatch is a
        # historical integrity failure; exactly one present is an explicit
        # partial-output anomaly. NEVER a regeneration fallback.
        cands = ax_obj(get(completion, "candidates", nothing))
        exp_lw = ax_str(get(ax_obj(get(cands, "lw", nothing)), "sha256", ""))
        exp_sw = ax_str(get(ax_obj(get(cands, "sw", nothing)), "sha256", ""))
        shas_wellformed = occursin(r"^[0-9a-f]{64}$", exp_lw) &&
                          occursin(r"^[0-9a-f]{64}$", exp_sw)
        gates["ledger_candidate_shas_wellformed"] =
            shas_wellformed ? "passed" : "failed"
        shas_wellformed || push!(fails,
            "submission-ledger candidate shas missing/malformed")
        n_present = count(isfile, (AX_LW_CAND, AX_SW_CAND))
        if n_present == 1
            gates["partial_candidate_outputs_anomaly"] = "failed"
            push!(fails, "PARTIAL candidate outputs: exactly one of the " *
                "two 4082 g-point candidates is on disk -- anomalous " *
                "state; investigate against the submission ledger")
        else
            cand_ok = shas_wellformed && n_present == 2 &&
                      ax_sha(AX_LW_CAND) == exp_lw &&
                      ax_sha(AX_SW_CAND) == exp_sw
            gates["two_gpoint_candidates_match_submission_ledger"] =
                cand_ok ? "passed" : "failed"
            cand_ok || push!(fails, "4082 candidates missing or != " *
                "submission-ledger shas (historical integrity failure, " *
                "never a regeneration fallback)")
        end
        # rayleigh overlay verified SEPARATELY as an input-generation
        # artifact -- it is NOT a third g-point candidate
        exp_ray = ax_str(get(completion, "rayleigh_overlay_sha256", ""))
        ray_ok = occursin(r"^[0-9a-f]{64}$", exp_ray) &&
                 ax_sha(AX_OVERLAY) == exp_ray
        gates["rayleigh_overlay_input_artifact_verified"] =
            ray_ok ? "passed" : "failed"
        ray_ok || push!(fails, "rayleigh input-generation overlay missing " *
                               "or != submission-ledger sha")
        # executed sbatch PRESERVED: no write in this branch (structural)
        # and live bytes == the submission ledger's recorded sbatch sha
        gates["sbatch_preserved_not_regenerated"] = "passed"
        exp_sb = ax_str(get(ax_obj(get(sub_obj, "sbatch", nothing)),
                            "sha256", ""))
        sb_ok = occursin(r"^[0-9a-f]{64}$", exp_sb) &&
                ax_sha(AX_SBATCH) == exp_sb
        gates["preserved_sbatch_matches_submission_ledger"] =
            sb_ok ? "passed" : "failed"
        sb_ok || push!(fails, "preserved sbatch missing or != " *
                              "submission-ledger sha")
        att1 = ax_obj(get(ax_obj(get(sub_obj, "attempt_history", nothing)),
                          "attempt_1", nothing))
        att1_sha = ax_str(get(att1, "sbatch_sha256", ""))
        att1_ok = get(att1, "job_id", -1) == 4079 &&
                  occursin(r"^[0-9a-f]{64}$", att1_sha) && att1_sha != exp_sb
        gates["attempt1_distinct_script_verified"] =
            att1_ok ? "passed" : "failed"
        att1_ok || push!(fails, "attempt-1 (4079) record missing or its " *
            "sbatch sha is not distinct from the executed attempt-2 script")
        # LATER DISPOSITION (separately verified, case + status): the
        # follow-on proof plan below stays as at-checkpoint text
        pf = ax_obj(try JSON.parsefile(validation_results_path(
            "gate4_a2_proof_finding_ledger.json")) catch; nothing end)
        ob = ax_obj(try JSON.parsefile(validation_results_path(
            "gate4_option_b_decision_record.json")) catch; nothing end)
        # because later_disposition names job 4091, its identity and
        # completion are verified from the proof finding ledger, not
        # assumed from case/status alone
        pf_run = ax_obj(get(pf, "proof_run", nothing))
        pf_outcome = ax_str(get(pf_run, "outcome", ""))
        disp_ok = ax_str(get(pf, "case", "")) == "gate4_a2_proof_finding_ledger" &&
            ax_str(get(pf, "status", "")) ==
                "a2_candidates_sensitivity_only_not_promotable" &&
            get(pf_run, "job_id", -1) == 4091 &&
            occursin("COMPLETED", pf_outcome) &&
            occursin("rc=0", pf_outcome) &&
            ax_str(get(ob, "case", "")) == "gate4_option_b_decision_record" &&
            ax_str(get(ob, "status", "")) ==
                "option_b_adopted_candidates_promoted"
        gates["later_disposition_verified"] = disp_ok ? "passed" : "failed"
        disp_ok || push!(fails, "later-disposition dependencies failed " *
            "case+status verification -- disposition claims withheld")
        executed = Dict(
            "job" => 4082,
            "outcome_ledger_verified" => outcome,
            "candidates" => Dict(
                "lw" => Dict("path" => AX_LW_CAND, "sha256" => exp_lw),
                "sw" => Dict("path" => AX_SW_CAND, "sha256" => exp_sw),
                "note" => "exactly TWO g-point candidates (find_g_points " *
                    "only); NO create_lut/raw-init output is attributable " *
                    "to 4082 -- those belong to the proof-driver chain " *
                    "(job 4091)"),
            "rayleigh_overlay" => Dict("path" => AX_OVERLAY,
                "sha256" => exp_ray,
                "note" => "input-generation artifact, NOT a candidate"),
            "executed_sbatch_sha256" => exp_sb,
            "attempt_1" => Dict("job" => 4079,
                "sbatch_sha256" => att1_sha,
                "note" => "earlier script revision (distinct sha); see " *
                    "gate4_a2_failure_ledger_4079"),
            "later_disposition" => disp_ok ?
                "follow-on exact-reproduction proof EXECUTED via the " *
                "proof-driver chain (job 4091): strict verdict " *
                "a2_candidates_sensitivity_only_not_promotable; " *
                "subsequently Greg-authorized Option B " *
                "(option_b_adopted_candidates_promoted) accepted the two " *
                "candidates as structure sources for ACCEPTANCE-INIT " *
                "SELECTION (it did not alter the strict finding's record)" :
                "WITHHELD: dependency verification failed")
    end   # :anomaly writes nothing and claims nothing

    # genuine pre-execution world writes the dry-run sbatch (never
    # submitted) ONLY behind the classified manifest prerequisite;
    # blocked/waiting pre-execution preserves the existing file
    sbatch_written = ax_write_script(() -> open(AX_SBATCH, "w") do io
        write(io, SBATCH_TEXT)
    end, mode, manifest_ok)

    # gates (structural; mode-appropriate name so anomaly and blocked
    # pre-execution never claim "written")
    sb_gate = historical ? "sbatch_not_regenerated_or_submitted" :
              mode == :anomaly ? "sbatch_untouched_fail_closed" :
              sbatch_written ? "sbatch_written_not_submitted" :
                               "sbatch_blocked_preserved_not_submitted"
    gates[sb_gate] = "passed"   # structural: this
    # script contains no `sbatch` invocation (self-scan with split token)
    self_src = read(@__FILE__, String)
    sb_tok = "sb" * "atch "
    n_direct = length(collect(eachmatch(Regex("run\\(`" * sb_tok), self_src)))
    n_direct == 0 || (gates[sb_gate] = "failed";
                      push!(fails, "sbatch invocation found in checkpoint unit"))
    gates["headnode_refusal_guard"] =
        occursin("REFUSED: head-node execution", SBATCH_TEXT) ? "passed" : "failed"
    # scan EXECUTABLE lines only (comments stripped) so the script may
    # mention forbidden stages in prose without failing itself
    exec_lines = join([l for l in split(SBATCH_TEXT, '\n')
                       if !occursin(r"^\s*#", l)], '\n')
    gates["merge_reorder_find_only"] =
        !occursin("create_lut", exec_lines) &&
        !occursin("create_look_up_table", exec_lines) &&
        !occursin("optimize_lut", exec_lines) ? "passed" : "failed"
    gates["merge_reorder_find_only"] == "passed" ||
        push!(fails, "forbidden stage invocation in executable sbatch lines")
    # 4079 failure fix: stage-1 merge must precede reorder per band
    i_mlw = findfirst("merge_well_mixed_lw.sh", exec_lines)
    i_rlw = findfirst("reorder_spectrum_lw.sh", exec_lines)
    i_msw = findfirst("merge_well_mixed_sw.sh", exec_lines)
    i_rsw = findfirst("reorder_spectrum_sw.sh", exec_lines)
    gates["stage1_merge_before_reorder"] =
        (!isnothing(i_mlw) && !isnothing(i_rlw) && !isnothing(i_msw) &&
         !isnothing(i_rsw) && first(i_mlw) < first(i_rlw) &&
         first(i_msw) < first(i_rsw)) ? "passed" : "failed"
    gates["stage1_merge_before_reorder"] == "passed" ||
        push!(fails, "merge_well_mixed stages missing or misordered")
    # SW rayleigh provisioned in a quarantined overlay, never into the
    # official data tree
    gates["rayleigh_overlay_provisioned"] =
        (occursin("--rayleigh", exec_lines) &&
         occursin("$G4WORK/input/mmm/sw_spectra", SBATCH_TEXT) &&
         occursin("MMM_SW_SPECTRA_DIR=$G4WORK/input/mmm/sw_spectra", SBATCH_TEXT) &&
         !occursin(Regex("--rayleigh[^\n]*-o[^\n]*" * CKDMIP_ROOT), exec_lines)) ?
        "passed" : "failed"
    gates["rayleigh_overlay_provisioned"] == "passed" ||
        push!(fails, "SW rayleigh overlay provisioning missing or mutates data tree")
    # checkpoint-side composite-input preflight (files on disk NOW);
    # rayleigh counts as satisfied if present in overlay OR generatable via
    # the pinned recipe (grid file + pinned tool both present).
    # PRE-EXECUTION ONLY: historical/anomaly modes skip this stale
    # availability gate (the run consumed its inputs in July; present-day
    # availability proves nothing)
    input_manifest = Any[]
    if mode == :preexecution
    inputs_ok = true
    for band in ("lw", "sw"), gas in vcat(MERGE_GASES, REORDER_FIND_GASES)
        p = joinpath(CKDMIP_ROOT, "mmm", "$(band)_spectra",
                     "ckdmip_mmm_$(band)_spectra_$(gas).h5")
        ok = isfile(p) && filesize(p) > 0
        inputs_ok &= ok
        push!(input_manifest, Dict("input" => basename(p), "present" => ok))
    end
    ssi = joinpath(CKDMIP_ROOT, "mmm/sw_spectra_extras/ckdmip_ssi.h5")
    inputs_ok &= isfile(ssi)
    push!(input_manifest, Dict("input" => basename(ssi), "present" => isfile(ssi)))
    for (label, p) in [
        ("mie_droplet_scattering.nc (CLOUD_SPECTRUM, sed-patched absolute)",
         joinpath(WORKCOPY, "data/mie_droplet_scattering.nc")),
        ("evaluation1 ckdmip_ssi.h5 (TRAINING_SW_SSI, cloud-reorder " *
         "wavenumber_input)",
         joinpath(CKDMIP_ROOT, "evaluation1/sw_spectra/ckdmip_ssi.h5"))]
        ok = isfile(p) && filesize(p) > 0
        inputs_ok &= ok
        push!(input_manifest, Dict("input" => label, "present" => ok))
    end
    for b in CKDMIP_BINARIES
        ok = isfile(joinpath(CKDMIP_BIN, b))
        inputs_ok &= ok
        push!(input_manifest, Dict("input" => "binary $b", "present" => ok))
    end
    for b in ECCKD_BINARIES
        ok = isfile(joinpath(WORKCOPY, "src/ecckd", b))
        inputs_ok &= ok
        push!(input_manifest, Dict("input" => "binary $b", "present" => ok))
    end
    overlay_rayleigh = joinpath(G4WORK, "input/mmm/sw_spectra",
                                "ckdmip_mmm_sw_spectra_rayleigh_present.h5")
    grid = joinpath(CKDMIP_ROOT, "mmm/sw_spectra",
                    "ckdmip_mmm_sw_spectra_h2o_median.h5")
    rayleigh_ok = (isfile(overlay_rayleigh) && filesize(overlay_rayleigh) > 0) ||
                  (isfile(grid) && isfile(CKDMIP_TOOL))
    inputs_ok &= rayleigh_ok
    push!(input_manifest, Dict(
        "input" => "ckdmip_mmm_sw_spectra_rayleigh_present.h5 (overlay)",
        "present" => isfile(overlay_rayleigh),
        "generatable_via_pinned_recipe" => isfile(grid) && isfile(CKDMIP_TOOL),
        "recipe" => RAYLEIGH_RECIPE))
    gates["composite_inputs_preflight"] = inputs_ok ? "passed" : "failed"
    inputs_ok || push!(fails, "composite-stage inputs missing (see input_manifest)")
    end
    gates["target_tolerances_narrowed"] =
        occursin("TOLERANCE=0.0161", SBATCH_TEXT) &&
        occursin("TOLERANCE=0.047", SBATCH_TEXT) ? "passed" : "failed"
    gates["workdir_quarantined"] =
        occursin("g4-init-generation/work", SBATCH_TEXT) ? "passed" : "failed"
    # live scheduler queries are PRE-EXECUTION ONLY -- the 4078-era
    # contention policy is a historical record in the other modes
    contention = if mode != :preexecution
        Dict("policy" => "HISTORICAL: the at-checkpoint policy (run " *
             "concurrently with 4078 on a different cpu-large node) " *
             "applied to the July submission window; no live squeue " *
             "queries are made outside pre-execution mode")
    else
        running_4078 = try
            !isempty(strip(read(`squeue -j 4078 -h -o "%T"`, String)))
        catch; false end
        Dict(
            "job_4078_running" => running_4078,
            "policy" => "A2 may run CONCURRENTLY with 4078 on a different " *
                        "cpu-large node (partition has 4 nodes); do not submit " *
                        "if the partition is saturated; never share the node " *
                        "running 4078",
        )
    end
    gates["contention_policy_recorded"] = "passed"
    gates["config_copy_patched_not_env_only"] =
        occursin("sed -i", SBATCH_TEXT) &&
        occursin("CKDMIP_DATA_DIR=", SBATCH_TEXT) &&
        occursin("BINDIR=" * WORKCOPY * "/src/ecckd", SBATCH_TEXT) &&
        occursin("MMM_SW_SPECTRA_DIR=$G4WORK/input/mmm/sw_spectra", SBATCH_TEXT) &&
        occursin("CLOUD_SPECTRUM=$WORKCOPY/data/mie_droplet_scattering.nc",
                 SBATCH_TEXT) &&
        occursin("INSUFFICIENT", SBATCH_TEXT) ? "passed" : "failed"
    gates["config_copy_patched_not_env_only"] == "passed" ||
        push!(fails, "config.h copy-patch of all five path vars not present " *
                     "(CLOUD_SPECTRUM is ../data-relative in the pristine " *
                     "file and breaks in a relocated TESTCOPY)")
    gates["no_mutation_of_4078_workcopy"] =
        !occursin(Regex("sed -i[^\n]*\\\$WORKCOPY/test/config"), SBATCH_TEXT) &&
        occursin("cp -r \"\$WORKCOPY/test\"", SBATCH_TEXT) ? "passed" : "failed"

    proof_plan = Dict(
        "unit" => "gate4_a2_reproduction_proof (follow-on; not implemented here)",
        "inputs" => ["rerun gpoints candidates: " *
                     "$G4WORK/work/**/ecckd-*_{lw,sw}_gpoints_*tol{0.0161,0.047}*.h5",
                     "raw create_lut outputs built FROM those candidates " *
                     "(init-generation manifest commands)",
                     "published LW32/SW32 definitions (verification targets)"],
        "gates" => ["g-counts exactly 32/32",
                    "gpoint_fraction elementwise EXACT vs published",
                    "wavenumber1_band/wavenumber2_band/band_number EXACT",
                    "on any mismatch: candidates are sensitivity-only; " *
                    "report, do not proceed to floor"],
        "refusal" => "proof runner refuses when candidate files are absent",
    )

    # success requires BOTH no fails AND every gate passed: several gates
    # can fail without appending to fails, and a false historical success
    # must be impossible
    # standard fail-closed census before status selection: failure
    # reports can never omit a silent failed gate (all_green already
    # requires every gate passed; the census makes the report complete)
    fails, gates_all_passed = ax_close_failed_gates(fails, gates)
    all_green = isempty(fails) && gates_all_passed
    status = !all_green ? "a2_execution_checkpoint_failed" :
             historical ? "a2_execution_checkpoint_historical_executed" :
                          "a2_execution_checkpoint_ready"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_a2_execution_checkpoint",
        "executed" => executed,
        "data_mode" => historical ?
            "historical_post_execution_verification_only" :
            mode == :anomaly ? "anomalous_state_no_generation" :
            sbatch_written ? "dry_run_script_generation_only" :
            "blocked_no_script_generated",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "prerequisite_loader_fixture_verdicts" => lt,
        "sbatch_path" => AX_SBATCH,
        "sbatch_written_this_run" => sbatch_written,
        # the historical claim is GATE-DEPENDENT (pd_claim discipline):
        # only a green identity gate may say ledger-verified
        "sbatch_scripts_state" => historical ?
            (get(gates, "preserved_sbatch_matches_submission_ledger",
                 "") == "passed" ?
             "EXECUTED script preserved (ledger-verified identity); " *
             "never regenerated" :
             "EXECUTED-script identity verification FAILED; claim " *
             "withheld; the preserved file was NOT regenerated or " *
             "modified by this unit") :
            mode == :anomaly ?
            "untouched (anomalous state; fail closed)" :
            sbatch_written ?
            "generated this run (unsubmitted)" :
            isfile(AX_SBATCH) ?
            "NOT generated this run (prerequisite blocked/waiting); " *
            "the file at sbatch_path is PRESERVED output of an earlier " *
            "run, not current" :
            "NOT generated this run; NO file exists at sbatch_path",
        "env_localization" => Dict(
            "mechanism" => (historical ? "AT-CHECKPOINT description: " : "") *
                "ALL THREE hard-coded config.h path variables " *
                (historical ? "were" : "are") *
                " sed-patched ABSOLUTE inside the isolated TESTCOPY; " *
                "env-only localization is insufficient and gated; the " *
                (historical ?
                 "then-active 4078 working copy was read only as a copy " *
                 "source, never mutated" :
                 "active 4078 working copy is read only as a copy source, " *
                 "never mutated"),
            "CKDMIP_DATA_DIR" => "$CKDMIP_ROOT (sed-patched in TESTCOPY)",
            "WORK_DIR" => "$G4WORK/work (sed-patched in TESTCOPY; " *
                          "quarantined from 4078's workdir)",
            "BINDIR" => "$WORKCOPY/src/ecckd (sed-patched ABSOLUTE in " *
                        "TESTCOPY; pristine relative ../src/ecckd would " *
                        "break in a relocated copy)",
            "MMM_SW_SPECTRA_DIR" => "$G4WORK/input/mmm/sw_spectra " *
                "(sed-patched to the QUARANTINED overlay: symlinks to the " *
                "official per-gas files + rayleigh generated by the pinned " *
                "recipe $RAYLEIGH_RECIPE with $CKDMIP_TOOL; the official " *
                "data tree is never written to)",
            "APPLICATION" => "climate",
            "BAND_STRUCTURE/TOLERANCE" => "fsck/0.0161 (LW), rgb/0.047 (SW) " *
                                          "first; 16-g sanity later"),
        "input_manifest" => input_manifest,
        # historical: verified_outputs carries ONLY genuinely hash-verified
        # artifacts; the un-hashed glob specs stay labeled as at-checkpoint
        # spec, never as verified evidence
        (historical ? "outputs_spec_at_checkpoint" : "expected_outputs") =>
        Dict(
            "gpoints" => "$G4WORK/work/**/ecckd-*_gpoints_climate_" *
                         "{fsck-tol0.0161,rgb-tol0.047}.h5",
            "reorder" => "$G4WORK/work/**/{lw,sw}_order_*_*.h5",
            "log" => "/shared/home/greg/data/ckdmip-logs/g4-a2-<jobid>.log"),
        "verified_outputs" => historical ? Dict(
            "lw_gpoint_candidate" => Dict("path" => AX_LW_CAND,
                "sha256" => get(get(ax_obj(get(executed, "candidates",
                    nothing)), "lw", Dict{String, Any}()), "sha256", "?")),
            "sw_gpoint_candidate" => Dict("path" => AX_SW_CAND,
                "sha256" => get(get(ax_obj(get(executed, "candidates",
                    nothing)), "sw", Dict{String, Any}()), "sha256", "?")),
            "rayleigh_overlay_input_artifact" => Dict("path" => AX_OVERLAY,
                "sha256" => get(ax_obj(get(executed, "rayleigh_overlay",
                    nothing)), "sha256", "?"))) : Dict{String, Any}(),
        "contention" => contention,
        "proof_plan" => proof_plan,
        "provenance" => Dict("branch" => branch, "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => historical ?
            "HISTORICAL post-execution record: the generated sbatch was " *
            "executed as job 4082 (submission-ledger-verified; attempt 1 " *
            "was 4079 on an earlier script revision); the executed script " *
            "is preserved, never regenerated; read-only with respect to " *
            "execution artifacts (this unit writes only its own JSON/MD); " *
            "nothing executed or submitted." :
            mode == :anomaly ?
            "ANOMALOUS state (malformed/wrong-status submission ledger, " *
            "or candidates without a ledger): fail-closed; nothing " *
            "generated, regenerated, or submitted; investigate before " *
            "any action." :
            sbatch_written ?
            "dry-run script generation only; nothing submitted; " *
            "no find_g_points/create_lut/objective/floor " *
            "execution; the generated script runs " *
            "merge_well_mixed + reorder + find_g_points only; " *
            "submission requires explicit authorization per the " *
            "standing protocol." :
            "BLOCKED pre-execution run: the rerun-manifest prerequisite " *
            "failed or is waiting, NO script was generated, nothing " *
            "submitted; any file at the sbatch path is preserved output " *
            "of an earlier run.",
    )
    mkpath(dirname(AX_RESULTS_JSON))
    open(AX_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(AX_RESULTS_MD, "w") do io
        println(io, historical ?
            "# Gate-4 A2 execution checkpoint — HISTORICAL (executed as " *
            "job 4082; attempt 1 = job 4079 on an earlier script)\n" :
            mode == :anomaly ?
            "# Gate-4 A2 execution checkpoint — ANOMALOUS STATE " *
            "(fail-closed)\n" :
            "# Gate-4 A2 execution checkpoint (dry-run)\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        if historical
            if get(gates, "preserved_sbatch_matches_submission_ledger",
                   "") == "passed"
                println(io, "\nExecuted batch script (preserved; " *
                            "byte-verified against the submission " *
                            "ledger's recorded sha): `$(AX_SBATCH)` " *
                            "sha256 " *
                            "`$(get(executed, "executed_sbatch_sha256", "?"))`")
            else
                println(io, "\nExecuted-script identity verification " *
                            "FAILED; claim withheld; the preserved file " *
                            "at `$(AX_SBATCH)` was NOT regenerated or " *
                            "modified by this unit.")
            end
            println(io, "\nLedger-verified outcome: ",
                    get(executed, "outcome_ledger_verified", "?"))
            println(io, "\nExactly TWO g-point candidates (find_g_points " *
                        "only; no create_lut output is attributable to " *
                        "4082):")
            for b in ("lw", "sw")
                c = executed["candidates"][b]
                println(io, "- [$b] `$(basename(c["path"]))` sha256 " *
                            "`$(c["sha256"])`")
            end
            ro = executed["rayleigh_overlay"]
            println(io, "\nRayleigh overlay (input-generation artifact, " *
                        "NOT a candidate): sha256 `$(ro["sha256"])`")
            println(io, "\nLater disposition (separately verified): ",
                    executed["later_disposition"])
        elseif mode == :preexecution
            if sbatch_written
                println(io, "\nGenerated (unsubmitted) batch script: " *
                            "`$(AX_SBATCH)`")
            else
                println(io, "\nNO script generated this run " *
                            "(prerequisite blocked/waiting); any file " *
                            "at `$(AX_SBATCH)` is preserved output of " *
                            "an earlier run, not current.")
            end
            n_present = count(m -> get(m, "present", false), input_manifest)
            println(io, "\nComposite-input preflight: $n_present/" *
                        "$(length(input_manifest)) present " *
                        "(SW rayleigh provisioned in the quarantined overlay " *
                        "via the pinned recipe when absent).")
        end
        haskey(contention, "job_4078_running") &&
            println(io, "\nContention: 4078 running = " *
                        "$(contention["job_4078_running"]); " *
                        contention["policy"])
        println(io, "\nFollow-on proof plan (at-checkpoint text): g-counts " *
                    "32/32; gpoint_fraction and band arrays elementwise " *
                    "EXACT vs published; any mismatch -> sensitivity-only, " *
                    "no floor.")
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_a2_execution_checkpoint: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status in ("a2_execution_checkpoint_ready",
                      "a2_execution_checkpoint_historical_executed") ? 0 : 1
end

exit(main())
