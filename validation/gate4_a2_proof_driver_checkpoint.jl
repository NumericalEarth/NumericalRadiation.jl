# Gate-4 A2 PROOF-DRIVER checkpoint (dry-run; NO submission, NO execution)
# -- HISTORICAL POST-EXECUTION MODE when the 4091 outputs exist.
#
# EXECUTED (monitor-directed marking, 2026-08-12): the sbatch this unit
# generated was submitted as authorized proof job 4091 (rc=0); its raw
# outputs exist and are pinned by the reviewed finding ledger
# (gate4_a2_proof_finding_ledger.json: lw_raw ce057079..., sw_raw
# 3308cb7a...), and the LW raw was later PROMOTED to the acceptance init
# under Option B. Therefore, when BOTH raw outputs exist, this unit runs
# in READ-ONLY HISTORICAL MODE: it does NOT regenerate the sbatch (the
# committed script is preserved as the executed artifact and verified
# against the submission ledger's sbatch sha), verifies the on-disk
# outputs against the finding ledger, re-checks the preserved script's
# structural guards, and reports a2_proof_driver_historical_executed.
# The pre-execution generation path (with its stale-output refusal gates)
# is retained VERBATIM for the outputs-absent world; partial outputs are
# an explicit failure. Nothing is submitted in any mode.
#
# Original contract (pre-execution): generates the exact Slurm batch
# script for the reproduction-proof raw create_lut builds that consume
# the 4082 candidates, per mechanism 1 of the proof scaffold. Key
# simplification proven by the readiness audit: the candidates ALREADY
# sit in WORK_{LW,SW}_GPOINTS_DIR under the exact filenames
# create_lut_{lw,sw}.sh derives (INPUT is a bare filename resolved via
# the generated config's append_path), so "placement" reduces to a
# sha256 identity check pinned at generation time. The generated script
# runs create_look_up_table ONLY (via the pristine create_lut_{lw,sw}.sh
# drivers in the EXISTING 4082 TESTCOPY -- reused, not recreated). NO
# optimize_lut, scale_lut, find_g_points, run_ckd, objective, floor, or
# acceptance use. Submission requires explicit review/go.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const WORKCOPY = "/shared/home/greg/ecckd-derived-flux-work/ecckd"
const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"
const TESTCOPY = "$G4WORK/testcopy"

const LW_CAND = "$G4WORK/work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5"
const SW_CAND = "$G4WORK/work/sw_gpoints/ecckd-1.2_sw_gpoints_climate_rgb-tol0.047.h5"
const LW_RAW = "$G4WORK/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc"
const SW_RAW = "$G4WORK/work/sw_raw-ckd-definition/ecckd-1.2_sw_raw-ckd-definition_climate_rgb-tol0.047.nc"

const PD_RESULTS_JSON = validation_results_path("gate4_a2_proof_driver_checkpoint.json")
const PD_RESULTS_MD = validation_results_path("gate4_a2_proof_driver_checkpoint.md")
const PD_SBATCH = validation_results_path("gate4_a2_proof_dryrun.sbatch")
const PD_FINDING_LEDGER = validation_results_path("gate4_a2_proof_finding_ledger.json")
const PD_SUBMISSION_LEDGER = validation_results_path("gate4_a2_proof_submission_ledger.json")

sha256(p) = split(strip(read(`sha256sum $p`, String)))[1]

# read-only historical mode: outputs exist; verify against the reviewed
# ledgers, preserve (never regenerate) the executed sbatch
function historical_executed_mode(gates, fails, lw_sha, sw_sha)
    fin = JSON.parsefile(PD_FINDING_LEDGER)
    sub = JSON.parsefile(PD_SUBMISSION_LEDGER)

    # fail-closed evidence gates: execution facts are VERIFIED from the
    # ledgers, never hardcoded (monitor requirement)
    case_ok = get(fin, "case", "") == "gate4_a2_proof_finding_ledger" &&
              get(sub, "case", "") == "gate4_a2_proof_submission_ledger"
    gates["ledger_case_ids_verified"] = case_ok ? "passed" : "failed"
    case_ok || push!(fails, "ledger case IDs wrong: fin=" *
        "$(get(fin, "case", "?")) sub=$(get(sub, "case", "?"))")
    jid_ok = get(get(sub, "job", Dict{String, Any}()), "job_id", -1) == 4091 &&
             get(fin["proof_run"], "job_id", -1) == 4091
    gates["job_id_4091_verified"] = jid_ok ? "passed" : "failed"
    jid_ok || push!(fails, "job_id != 4091 in a ledger")
    outcome = String(get(fin["proof_run"], "outcome", ""))
    outcome_ok = occursin("COMPLETED", outcome) && occursin("rc=0", outcome)
    gates["finding_outcome_completed_rc0"] = outcome_ok ? "passed" : "failed"
    outcome_ok || push!(fails, "finding-ledger outcome lacks COMPLETED " *
                               "rc=0: $(first(outcome, 80))")
    ob = JSON.parsefile(
        validation_results_path("gate4_option_b_decision_record.json"))
    ob_ok = get(ob, "status", "") == "option_b_adopted_candidates_promoted" &&
            any(occursin("gate4_a2_reproduction_proof_scaffold", String(s))
                for s in get(ob, "supersedes", Any[]))
    gates["option_b_adoption_verified"] = ob_ok ? "passed" : "failed"
    ob_ok || push!(fails, "Option-B record not adopted or does not " *
        "supersede the strict scaffold verdict; promotion cannot be claimed")

    exp_lw = fin["proof_run"]["lw_raw"]["sha256"]
    exp_sw = fin["proof_run"]["sw_raw"]["sha256"]
    lw_ok = sha256(LW_RAW) == exp_lw
    sw_ok = sha256(SW_RAW) == exp_sw
    gates["outputs_match_4091_finding_ledger"] =
        lw_ok && sw_ok ? "passed" : "failed"
    (lw_ok && sw_ok) ||
        push!(fails, "on-disk proof outputs do not match the reviewed 4091 " *
                     "finding ledger (lw_ok=$lw_ok sw_ok=$sw_ok) -- this IS " *
                     "a real integrity problem, not a stale-output refusal")
    # the committed sbatch is the executed artifact; verify identity vs the
    # submission ledger and re-check its structural guards without rewriting
    sbatch_text = isfile(PD_SBATCH) ? read(PD_SBATCH, String) : ""
    sb_expected = get(get(sub, "sbatch", Dict{String, Any}()), "sha256", "")
    sb_ok = isfile(PD_SBATCH) && sha256(PD_SBATCH) == sb_expected
    gates["preserved_sbatch_matches_submission_ledger"] =
        sb_ok ? "passed" : "failed"
    sb_ok || push!(fails, "preserved sbatch missing or != submission-ledger " *
                          "sha $sb_expected")
    gates["sbatch_preserved_not_regenerated"] = "passed"  # structural: this
    # branch contains no write to PD_SBATCH
    gates["headnode_refusal_guard"] =
        occursin("REFUSED: head-node execution", sbatch_text) ? "passed" : "failed"
    gates["candidate_identity_pinned"] =
        occursin(lw_sha, sbatch_text) && occursin(sw_sha, sbatch_text) &&
        occursin("sha256sum -c", sbatch_text) ? "passed" : "failed"
    gates["sbatch_refuses_stale_raw_outputs"] =
        occursin("stale LW raw output", sbatch_text) &&
        occursin("stale SW raw output", sbatch_text) ? "passed" : "failed"
    payload = Dict(
        "mode" => "historical_executed",
        "candidates" => Dict(
            "lw" => Dict("path" => LW_CAND, "sha256" => lw_sha),
            "sw" => Dict("path" => SW_CAND, "sha256" => sw_sha)),
        "executed_outputs" => Dict(
            "lw" => Dict("path" => LW_RAW, "sha256" => exp_lw,
                "note" => "PROMOTED to the LW acceptance init under Option B"),
            "sw" => Dict("path" => SW_RAW, "sha256" => exp_sw,
                "note" => "v1.2 proof output; sensitivity evidence only -- " *
                    "the promoted SW raw is the v1.4 R2 output (job 4096)")),
        "execution" => Dict(
            "job_id_verified" => 4091,
            "outcome_verified" => outcome,     # full ledger text, untruncated
            "strict_finding_status" => get(fin, "status", "?"),
            "promotion_verification" => "Option-B record adoption + " *
                "explicit supersession of the scaffold verdict verified " *
                "against gate4_option_b_decision_record"),
        "ledgers" => Dict("finding" => basename(PD_FINDING_LEDGER),
                          "submission" => basename(PD_SUBMISSION_LEDGER)))
    return payload
end

function main()
    fails = String[]
    gates = Dict{String, String}()

    scaffold = JSON.parsefile(
        validation_results_path("gate4_a2_reproduction_proof_scaffold.json"))
    gates["scaffold_ready_required"] =
        scaffold["status"] == "a2_proof_scaffold_ready" ? "passed" : "failed"
    scaffold["status"] == "a2_proof_scaffold_ready" ||
        push!(fails, "proof scaffold not ready: $(scaffold["status"])")

    isfile(LW_CAND) && isfile(SW_CAND) ||
        (push!(fails, "candidate files missing"); return finish(gates, fails,
            Dict(), ""))
    lw_sha = sha256(LW_CAND)
    sw_sha = sha256(SW_CAND)
    gates["candidates_hashed"] = "passed"

    # POST-EXECUTION: both 4091 outputs on disk -> read-only historical mode
    if isfile(LW_RAW) && isfile(SW_RAW)
        payload = historical_executed_mode(gates, fails, lw_sha, sw_sha)
        return finish(gates, fails, payload, "")
    elseif isfile(LW_RAW) || isfile(SW_RAW)
        push!(fails, "PARTIAL proof outputs on disk (exactly one of LW/SW " *
                     "raw exists) -- anomalous state; investigate against " *
                     "the 4091 finding ledger before any action")
        return finish(gates, fails, Dict("mode" => "partial_outputs"), "")
    end

    sbatch_text = """
#!/bin/bash
#SBATCH --job-name=g4-a2-proof-create-lut
#SBATCH --output=/shared/home/greg/data/ckdmip-logs/g4-a2-proof-%j.log
#SBATCH --time=08:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=60G
#SBATCH --partition=cpu-large

# Gate-4 A2 reproduction proof: raw create_lut builds ONLY (no optimisation,
# no scaling, no objective stages). Generated by
# gate4_a2_proof_driver_checkpoint.jl; DO NOT run outside Slurm.
set -euo pipefail
if [ -z "\${SLURM_JOB_ID:-}" ]; then
    echo "REFUSED: head-node execution is not permitted; submit via sbatch." >&2
    exit 64
fi

TESTCOPY=$TESTCOPY

echo "=== proof stage 0: environment + candidate identity checks ==="
test -d "\$TESTCOPY" || { echo "REFUSED: 4082 TESTCOPY missing" >&2; exit 68; }
grep -q '^CKDMIP_DATA_DIR=$CKDMIP_ROOT\$' "\$TESTCOPY/config.h" || { echo "BAD config: CKDMIP_DATA_DIR" >&2; exit 68; }
grep -q '^WORK_DIR=$G4WORK/work\$' "\$TESTCOPY/config.h" || { echo "BAD config: WORK_DIR" >&2; exit 68; }
grep -q '^BINDIR=$WORKCOPY/src/ecckd\$' "\$TESTCOPY/config.h" || { echo "BAD config: BINDIR" >&2; exit 68; }
grep -q '^MMM_SW_SPECTRA_DIR=$G4WORK/input/mmm/sw_spectra\$' "\$TESTCOPY/config.h" || { echo "BAD config: MMM_SW_SPECTRA_DIR" >&2; exit 68; }
grep -q '^CLOUD_SPECTRUM=$WORKCOPY/data/mie_droplet_scattering.nc\$' "\$TESTCOPY/config.h" || { echo "BAD config: CLOUD_SPECTRUM" >&2; exit 68; }
sha256sum -c <<'HASHES' || { echo "REFUSED: candidate hash mismatch vs 4082 ledger" >&2; exit 69; }
$lw_sha  $LW_CAND
$sw_sha  $SW_CAND
HASHES
test ! -e "$LW_RAW" || { echo "REFUSED: stale LW raw output already exists; the authorized proof run must CREATE it, not inherit it" >&2; exit 70; }
test ! -e "$SW_RAW" || { echo "REFUSED: stale SW raw output already exists; the authorized proof run must CREATE it, not inherit it" >&2; exit 70; }
test -d "$CKDMIP_ROOT/idealized/lw_spectra" || { echo "MISSING idealized LW spectra" >&2; exit 65; }
test -d "$CKDMIP_ROOT/idealized/sw_spectra" || { echo "MISSING idealized SW spectra" >&2; exit 65; }
test -s "$CKDMIP_ROOT/mmm/conc/ckdmip_mmm-const_concentrations.nc" || { echo "MISSING mmm-const conc" >&2; exit 65; }
test -s "$CKDMIP_ROOT/mmm/sw_spectra_extras/ckdmip_ssi.h5" || { echo "MISSING MMM SSI" >&2; exit 65; }
cd "\$TESTCOPY"

echo "=== proof LW: raw create_lut (fsck, TOLERANCE=0.0161) ==="
APPLICATION=climate BAND_STRUCTURE=fsck TOLERANCE=0.0161 bash create_lut_lw.sh
echo "=== proof SW: raw create_lut (rgb, TOLERANCE=0.047) ==="
APPLICATION=climate BAND_STRUCTURE=rgb TOLERANCE=0.047 bash create_lut_sw.sh

echo "=== proof raw outputs ==="
sha256sum "$LW_RAW" "$SW_RAW"
echo "=== proof create_lut done rc=\$? \$(date -u +%FT%TZ) ==="
"""
    open(PD_SBATCH, "w") do io
        write(io, sbatch_text)
    end

    gates["sbatch_written_not_submitted"] = "passed"
    self_src = read(@__FILE__, String)
    sb_tok = "sb" * "atch "
    isempty(collect(eachmatch(Regex("run\\(`" * sb_tok), self_src))) ||
        (gates["sbatch_written_not_submitted"] = "failed";
         push!(fails, "sbatch invocation found in proof-driver unit"))
    gates["headnode_refusal_guard"] =
        occursin("REFUSED: head-node execution", sbatch_text) ? "passed" : "failed"
    exec_lines = join([l for l in split(sbatch_text, '\n')
                       if !occursin(r"^\s*#", l)], '\n')
    gates["create_lut_only"] =
        occursin("create_lut_lw.sh", exec_lines) &&
        occursin("create_lut_sw.sh", exec_lines) &&
        !occursin("optimize_lut", exec_lines) &&
        !occursin("scale_lut", exec_lines) &&
        !occursin("find_g_points", exec_lines) &&
        !occursin("run_ckd", exec_lines) &&
        !occursin("reorder_spectrum", exec_lines) ? "passed" : "failed"
    gates["create_lut_only"] == "passed" ||
        push!(fails, "forbidden stage invocation in executable proof lines")
    gates["testcopy_reused_not_recreated"] =
        !occursin("rm -rf", exec_lines) && !occursin("sed -i", exec_lines) &&
        occursin("4082 TESTCOPY missing", sbatch_text) ? "passed" : "failed"
    gates["testcopy_reused_not_recreated"] == "passed" ||
        push!(fails, "proof sbatch must reuse the 4082 TESTCOPY unchanged")
    gates["candidate_identity_pinned"] =
        occursin(lw_sha, sbatch_text) && occursin(sw_sha, sbatch_text) &&
        occursin("sha256sum -c", sbatch_text) ? "passed" : "failed"
    gates["raw_outputs_declared"] =
        occursin(LW_RAW, sbatch_text) && occursin(SW_RAW, sbatch_text) ?
        "passed" : "failed"
    gates["raw_outputs_absent_preproof"] =
        !isfile(LW_RAW) && !isfile(SW_RAW) ? "passed" : "failed"
    gates["raw_outputs_absent_preproof"] == "passed" ||
        push!(fails, "raw output(s) already exist before any authorized " *
                     "proof run -- stale files must be investigated, not " *
                     "inherited")
    gates["sbatch_refuses_stale_raw_outputs"] =
        occursin("stale LW raw output", sbatch_text) &&
        occursin("stale SW raw output", sbatch_text) ? "passed" : "failed"
    gates["no_execution_in_this_unit"] = "passed"   # generation only; the
    # comparison runner is a separate refusing script

    payload = Dict(
        "candidates" => Dict(
            "lw" => Dict("path" => LW_CAND, "sha256" => lw_sha),
            "sw" => Dict("path" => SW_CAND, "sha256" => sw_sha)),
        "expected_raw_outputs" => Dict("lw" => LW_RAW, "sw" => SW_RAW),
        "mechanism" => "mechanism 1 (script-faithful): candidates already at " *
            "the exact script-derived INPUT paths (find_g_points wrote them " *
            "there under the same config); placement = pinned sha256 " *
            "identity check; then pristine create_lut_{lw,sw}.sh in the " *
            "REUSED 4082 TESTCOPY",
        "version_skew_note" => "pre-registered mismatch risk: published LW32 " *
            "is ecckd-1.0, published SW32 is ecckd-1.4, pinned rerun " *
            "toolchain is ecckd-1.2; content comparisons are name-agnostic " *
            "but algorithmic drift across versions is a plausible mismatch " *
            "cause; any mismatch -> sensitivity-only per the scaffold " *
            "verdict rule")
    return finish(gates, fails, payload, sbatch_text)
end

function finish(gates, fails, payload, sbatch_text)
    mode = get(payload, "mode", "")
    historical = mode == "historical_executed"
    partial = mode == "partial_outputs"
    status = !isempty(fails) ? "a2_proof_driver_failed" :
             historical ? "a2_proof_driver_historical_executed" :
                          "a2_proof_driver_ready_awaiting_go"
    data_mode = historical ? "historical_post_execution_verification_only" :
                partial ? "anomalous_partial_outputs_no_generation" :
                          "dry_run_script_generation_only"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_a2_proof_driver_checkpoint",
        "data_mode" => data_mode,
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "sbatch_path" => PD_SBATCH,
        "payload" => payload,
        "provenance" => Dict("branch" => branch, "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => historical ?
            "HISTORICAL post-execution record: the generated sbatch was " *
            "executed as authorized proof job 4091 (ledger-verified, not " *
            "assumed); outputs verified against the reviewed finding " *
            "ledger; the executed script is preserved, never regenerated; " *
            "nothing submitted or executed by this unit." :
            partial ?
            "ANOMALOUS partial-output state: exactly one 4091 raw output " *
            "is on disk; nothing generated, regenerated, or submitted; " *
            "investigate against the finding ledger before any action." :
            "dry-run script generation only; nothing submitted; " *
            "no create_lut, comparison, objective, floor, or " *
            "acceptance execution; submission requires explicit " *
            "review/go per the standing protocol.",
    )
    mkpath(dirname(PD_RESULTS_JSON))
    open(PD_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(PD_RESULTS_MD, "w") do io
        println(io, historical ?
            "# Gate-4 A2 proof-driver checkpoint — HISTORICAL (executed " *
            "as job 4091)\n" :
            "# Gate-4 A2 proof-driver checkpoint (dry-run)\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        if historical
            println(io, "\nExecuted proof batch script (preserved, " *
                        "ledger-verified): `$(PD_SBATCH)`")
            ex = payload["execution"]
            println(io, "\nExecution (ledger-verified): job " *
                        "$(ex["job_id_verified"]); outcome: " *
                        "$(ex["outcome_verified"]); strict finding status: " *
                        "$(ex["strict_finding_status"]); " *
                        "$(ex["promotion_verification"]).")
            for b in ("lw", "sw")
                o = payload["executed_outputs"][b]
                println(io, "- [$b] `$(basename(o["path"]))` sha256 " *
                            "`$(o["sha256"])` -- $(o["note"])")
            end
        else
            println(io, "\nGenerated (unsubmitted) proof batch script: " *
                        "`$(PD_SBATCH)`")
        end
        if haskey(payload, "candidates")
            println(io, "\nPinned candidate identities:")
            for b in ("lw", "sw")
                c = payload["candidates"][b]
                println(io, "- [$b] `$(basename(c["path"]))` sha256 `$(c["sha256"])`")
            end
            haskey(payload, "expected_raw_outputs") &&
                println(io, "\nExpected raw outputs: " *
                    "`$(basename(payload["expected_raw_outputs"]["lw"]))`, " *
                    "`$(basename(payload["expected_raw_outputs"]["sw"]))`")
            haskey(payload, "version_skew_note") &&
                println(io, "\nVersion-skew note: ",
                        payload["version_skew_note"])
        end
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_a2_proof_driver_checkpoint: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status in ("a2_proof_driver_ready_awaiting_go",
                      "a2_proof_driver_historical_executed") ? 0 : 1
end

exit(main())
