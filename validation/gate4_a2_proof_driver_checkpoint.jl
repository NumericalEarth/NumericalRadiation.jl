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

# nonthrowing hash for the OUTPUT boundary: missing/unreadable files
# classify as failed gates with reasons, never a crash (early
# missing-file return avoids sha256sum stderr in deliberate fixtures)
pd_try_sha(p) = try
    isfile(p) || return nothing
    split(strip(read(`sha256sum $p`, String)))[1]
catch
    nothing
end

pd_obj(x) = x isa AbstractDict ? x : Dict{String, Any}()
pd_str(x) = x isa AbstractString ? String(x) : ""
pd_hex64(x) = x isa AbstractString && occursin(r"^[0-9a-f]{64}$", x)

# shared guarded pinned-artifact loader (fixture-run via the
# absolute-path passthrough; the unit's SINGLE parsefile site, serving
# all four artifact edges): FIVE fixed, distinct refusal classes with
# FIXED reasons -- missing; unparseable (parse failure); parses to a
# non-object (JSON null/array/scalar); case mismatch; not green. The
# EXACT case is bound before the EXACT status for every producer,
# including the finding and submission ledgers.
function pd_parse_pinned(name, expected_case, expected_status)
    path = isabspath(name) ? name : validation_results_path(name)
    isfile(path) ||
        return (false, "$expected_case missing", nothing)
    raw = try
        JSON.parsefile(path)
    catch
        return (false, "$expected_case unparseable (parse failure)",
                nothing)
    end
    raw isa AbstractDict ||
        return (false, "$expected_case parses to a non-object " *
                       "(JSON null/array/scalar)", nothing)
    c = pd_str(get(raw, "case", ""))
    c == expected_case ||
        return (false, "$expected_case case mismatch: " *
                       (isempty(c) ? "(missing/non-string)" : c), raw)
    s = pd_str(get(raw, "status", ""))
    s == expected_status ||
        return (false, "$expected_case not green: " *
                       (isempty(s) ? "(missing/non-string)" : s), raw)
    return (true, "ok", raw)
end

# PURE safe navigators used identically by production and fixtures:
# finding-ledger proof_run fields (shape deficiencies yield ""/-1)
pd_fin_job_id(fin) = get(pd_obj(get(pd_obj(fin), "proof_run", nothing)),
                         "job_id", -1)
pd_fin_outcome(fin) = pd_str(get(pd_obj(get(pd_obj(fin), "proof_run",
                                             nothing)), "outcome", ""))
pd_fin_raw_sha(fin, band) = pd_str(get(pd_obj(get(pd_obj(get(pd_obj(fin),
    "proof_run", nothing)), band, nothing)), "sha256", ""))
# submission-ledger fields
pd_sub_job_id(sub) = get(pd_obj(get(pd_obj(sub), "job", nothing)),
                         "job_id", -1)
pd_sub_sbatch_sha(sub) = pd_str(get(pd_obj(get(pd_obj(sub), "sbatch",
                                               nothing)), "sha256", ""))
# Option-B supersedes scan: non-vector never matches; non-string
# entries normalize (never throw or falsely match)
function pd_ob_supersedes_scaffold(ob)
    sup = get(pd_obj(ob), "supersedes", nothing)
    return sup isa AbstractVector &&
           any(occursin("gate4_a2_reproduction_proof_scaffold",
                        pd_str(s)) for s in sup)
end

# payload-facing status extraction: safe on nothing/non-object/non-
# string (the failure report must always be emittable)
function pd_status_or_q(x)
    s = pd_str(get(pd_obj(x), "status", ""))
    return isempty(s) ? "?" : s
end

# truthful pre-execution data_mode: a blocked run generated nothing
pd_preexec_data_mode(sbatch_written) = sbatch_written ?
    "dry_run_script_generation_only" : "blocked_no_script_generated"

# pure claim formatter shared with fixtures: a fact is ASSERTED only
# when its gate is green; otherwise the claim is WITHHELD -- a
# malformed-ledger report can never assert the facts it failed to verify
pd_claim(ok, verified_text, withheld_text) =
    ok ? verified_text : withheld_text

# fail-closed gate closure (pure; fixture-run): whenever ANY gate is
# not passed, the AUTHORITATIVE complete failed-gate census is appended
# (duplication with specific reasons is acceptable -- one gate's reason
# can never hide another gate's silent failure), and success ALWAYS
# additionally requires every gate passed
function pd_close_failed_gates(fails, gates)
    failed = sort([k for (k, v) in gates if v != "passed"])
    out = copy(fails)
    isempty(failed) ||
        push!(out, "failed gates (fail-closed census): " *
                   join(failed, ", "))
    return out, isempty(failed)
end

# the pre-execution sbatch write happens ONLY behind the classified
# scaffold prerequisite (historical/partial paths are structurally
# write-free; a blocked pre-execution run never clobbers PD_SBATCH)
pd_should_write(preexecution, scaffold_ok) = preexecution && scaffold_ok
function pd_write_script(writefn, preexecution, scaffold_ok)
    pd_should_write(preexecution, scaffold_ok) || return false
    writefn()
    return true
end

# read-only historical mode: outputs exist; verify against the reviewed
# ledgers, preserve (never regenerate) the executed sbatch
function historical_executed_mode(gates, fails, lw_sha, sw_sha)
    # fail-closed evidence gates: execution facts are VERIFIED from the
    # ledgers, never hardcoded (monitor requirement); EXACT case+status
    # are bound for both ledgers through the shared guarded loader
    fin_ok, fin_why, fin = pd_parse_pinned(PD_FINDING_LEDGER,
        "gate4_a2_proof_finding_ledger",
        "a2_candidates_sensitivity_only_not_promotable")
    sub_ok, sub_why, sub = pd_parse_pinned(PD_SUBMISSION_LEDGER,
        "gate4_a2_proof_submission_ledger",
        "proof_run_submitted_awaiting_completion")
    gates["ledger_case_ids_verified"] =
        (fin_ok && sub_ok) ? "passed" : "failed"
    fin_ok || push!(fails, fin_why)
    sub_ok || push!(fails, sub_why)
    jid_ok = pd_sub_job_id(sub) == 4091 && pd_fin_job_id(fin) == 4091
    gates["job_id_4091_verified"] = jid_ok ? "passed" : "failed"
    jid_ok || push!(fails, "job_id != 4091 in a ledger (or ledger " *
                           "shape deficient)")
    outcome = pd_fin_outcome(fin)
    outcome_ok = occursin("COMPLETED", outcome) && occursin("rc=0", outcome)
    gates["finding_outcome_completed_rc0"] = outcome_ok ? "passed" : "failed"
    outcome_ok || push!(fails, "finding-ledger outcome lacks COMPLETED " *
                               "rc=0: $(first(outcome, 80))")
    ob_ok0, ob_why, ob = pd_parse_pinned(
        "gate4_option_b_decision_record.json",
        "gate4_option_b_decision_record",
        "option_b_adopted_candidates_promoted")
    ob_ok0 || push!(fails, ob_why)
    ob_ok = ob_ok0 && pd_ob_supersedes_scaffold(ob)
    gates["option_b_adoption_verified"] = ob_ok ? "passed" : "failed"
    (ob_ok || !ob_ok0) ||
        push!(fails, "Option-B record does not supersede the strict " *
                     "scaffold verdict; promotion cannot be claimed")

    # ledger shas 64-HEX VALIDATED before any file hashing/comparison
    exp_lw = pd_fin_raw_sha(fin, "lw_raw")
    exp_sw = pd_fin_raw_sha(fin, "sw_raw")
    shas_wellformed = pd_hex64(exp_lw) && pd_hex64(exp_sw)
    gates["finding_ledger_shas_wellformed"] =
        shas_wellformed ? "passed" : "failed"
    shas_wellformed || push!(fails, "finding-ledger lw/sw raw shas " *
                                    "missing or not 64-hex")
    lw_ok = shas_wellformed && pd_try_sha(LW_RAW) == exp_lw
    sw_ok = shas_wellformed && pd_try_sha(SW_RAW) == exp_sw
    gates["outputs_match_4091_finding_ledger"] =
        lw_ok && sw_ok ? "passed" : "failed"
    (lw_ok && sw_ok) || !shas_wellformed ||
        push!(fails, "on-disk proof outputs do not match the reviewed 4091 " *
                     "finding ledger (lw_ok=$lw_ok sw_ok=$sw_ok) -- this IS " *
                     "a real integrity problem, not a stale-output refusal")
    # the committed sbatch is the executed artifact; verify identity vs the
    # submission ledger (sha 64-HEX validated first) and re-check its
    # structural guards without rewriting; nonthrowing reads
    sbatch_text = try
        isfile(PD_SBATCH) ? read(PD_SBATCH, String) : ""
    catch
        ""
    end
    sb_expected = pd_sub_sbatch_sha(sub)
    sb_wellformed = pd_hex64(sb_expected)
    gates["submission_ledger_sbatch_sha_wellformed"] =
        sb_wellformed ? "passed" : "failed"
    sb_wellformed || push!(fails, "submission-ledger sbatch sha " *
                                  "missing or not 64-hex")
    sb_ok = sb_wellformed && pd_try_sha(PD_SBATCH) == sb_expected
    gates["preserved_sbatch_matches_submission_ledger"] =
        sb_ok ? "passed" : "failed"
    # the identity reason is emitted ONLY when the expected sha is
    # well-formed; the malformed-sha reason above stands alone
    (sb_ok || !sb_wellformed) ||
        push!(fails, "preserved sbatch missing or != submission-ledger " *
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
    # CLAIM DISCIPLINE: every asserted fact goes through pd_claim keyed
    # on its own verification gate -- a failed verification WITHHOLDS
    # the claim while still stating that nothing was regenerated
    payload = Dict(
        "mode" => "historical_executed",
        "candidates" => Dict(
            "lw" => Dict("path" => LW_CAND, "sha256" => lw_sha),
            "sw" => Dict("path" => SW_CAND, "sha256" => sw_sha)),
        "executed_outputs" => Dict(
            "lw" => Dict("path" => LW_RAW, "sha256" => exp_lw,
                "note" => pd_claim(ob_ok && lw_ok,
                    "PROMOTED to the LW acceptance init under Option B",
                    "promotion claim WITHHELD (verification failed); " *
                    "file not modified by this unit")),
            "sw" => Dict("path" => SW_RAW, "sha256" => exp_sw,
                "note" => pd_claim(sw_ok,
                    "v1.2 proof output; sensitivity evidence only -- " *
                    "the promoted SW raw is the v1.4 R2 output (job 4096)",
                    "output identity UNVERIFIED; claim withheld; file " *
                    "not modified by this unit"))),
        "execution" => Dict(
            "job_id_verified" => pd_claim(jid_ok, 4091,
                "UNVERIFIED (claim withheld)"),
            "outcome_verified" => pd_claim(outcome_ok, outcome,
                "UNVERIFIED (claim withheld)"),
            "strict_finding_status" => pd_status_or_q(fin),
            "promotion_verification" => pd_claim(ob_ok,
                "Option-B record adoption + explicit supersession of " *
                "the scaffold verdict verified against " *
                "gate4_option_b_decision_record",
                "promotion verification FAILED; claim withheld")),
        "ledgers" => Dict("finding" => basename(PD_FINDING_LEDGER),
                          "submission" => basename(PD_SUBMISSION_LEDGER)))
    return payload
end

function main()
    fails = String[]
    gates = Dict{String, String}()

    # loader/navigator/writer fixtures FIRST, through the SAME code
    tdir = mktempdir()
    lt = Dict{String, Bool}()
    lt["missing_fails"] = begin
        r = pd_parse_pinned(joinpath(tdir, "absent.json"), "c", "s")
        !r[1] && r[2] == "c missing"
    end
    fpx = joinpath(tdir, "pa.json")
    write(fpx, "{")
    lt["malformed_fails"] = begin
        r = pd_parse_pinned(fpx, "c", "s")
        !r[1] && r[2] == "c unparseable (parse failure)"
    end
    write(fpx, "null")
    lt["null_non_object_fails"] = begin
        r = pd_parse_pinned(fpx, "c", "s")
        !r[1] && occursin("non-object", r[2])
    end
    write(fpx, "[1]")
    lt["array_non_object_fails"] = begin
        r = pd_parse_pinned(fpx, "c", "s")
        !r[1] && occursin("non-object", r[2])
    end
    write(fpx, "{\"case\": \"other\", \"status\": \"s\"}")
    lt["wrong_case_fails"] = begin
        r = pd_parse_pinned(fpx, "c", "s")
        !r[1] && occursin("case mismatch", r[2])
    end
    write(fpx, "{\"case\": \"c\", \"status\": \"totally_bogus\"}")
    lt["tampered_status_fails"] = begin
        r = pd_parse_pinned(fpx, "c", "s")
        !r[1] && occursin("not green", r[2])
    end
    write(fpx, "{\"case\": \"c\", \"status\": \"s\"}")
    lt["exact_green_captures"] = begin
        r = pd_parse_pinned(fpx, "c", "s")
        r[1] && r[2] == "ok" && r[3] isa AbstractDict
    end
    lt["fin_navigators_shape_safe"] = begin
        good = Dict("proof_run" => Dict("job_id" => 4091,
            "outcome" => "COMPLETED rc=0",
            "lw_raw" => Dict("sha256" => "a" ^ 64),
            "sw_raw" => Dict("sha256" => "b" ^ 64)))
        pd_fin_job_id(good) == 4091 &&
            pd_fin_outcome(good) == "COMPLETED rc=0" &&
            pd_fin_raw_sha(good, "lw_raw") == "a" ^ 64 &&
            pd_fin_raw_sha(good, "sw_raw") == "b" ^ 64 &&
            pd_fin_job_id(Dict{String, Any}()) == -1 &&
            pd_fin_outcome(Dict("proof_run" => "x")) == "" &&
            pd_fin_raw_sha(Dict("proof_run" =>
                Dict("lw_raw" => Dict("sha256" => 5))), "lw_raw") == "" &&
            pd_fin_raw_sha(nothing, "lw_raw") == ""
    end
    lt["sub_navigators_shape_safe"] = begin
        good = Dict("job" => Dict("job_id" => 4091),
                    "sbatch" => Dict("sha256" => "c" ^ 64))
        pd_sub_job_id(good) == 4091 &&
            pd_sub_sbatch_sha(good) == "c" ^ 64 &&
            pd_sub_job_id(Dict{String, Any}()) == -1 &&
            pd_sub_sbatch_sha(Dict("sbatch" => "x")) == "" &&
            !pd_hex64(pd_sub_sbatch_sha(Dict("sbatch" =>
                Dict("sha256" => "zz"))))
    end
    lt["supersedes_scan_normalized"] = begin
        hit = Dict("supersedes" =>
            ["gate4_a2_reproduction_proof_scaffold strict verdict"])
        pd_ob_supersedes_scaffold(hit) &&
            !pd_ob_supersedes_scaffold(Dict("supersedes" => "x")) &&
            !pd_ob_supersedes_scaffold(Dict{String, Any}()) &&
            pd_ob_supersedes_scaffold(Dict("supersedes" =>
                [5, "gate4_a2_reproduction_proof_scaffold"])) &&
            !pd_ob_supersedes_scaffold(Dict("supersedes" => [5, "other"]))
    end
    lt["writer_only_preexecution_green"] = begin
        n = Ref(0)
        w = () -> (n[] += 1)
        pd_write_script(w, true, true) == true && n[] == 1 &&
            pd_write_script(w, true, false) == false &&
            pd_write_script(w, false, true) == false &&
            pd_write_script(w, false, false) == false && n[] == 1
    end
    lt["try_sha_nonthrowing"] =
        pd_try_sha(joinpath(tdir, "gone.bin")) === nothing &&
        pd_try_sha(fpx) isa AbstractString
    # payload-facing status extraction must be emittable on ANY loader
    # result, including nothing/non-object/non-string
    lt["payload_status_safe_on_refusals"] =
        pd_status_or_q(nothing) == "?" &&
        pd_status_or_q(Dict{String, Any}()) == "?" &&
        pd_status_or_q(Dict("status" => 5)) == "?" &&
        pd_status_or_q("not-an-object") == "?" &&
        pd_status_or_q(Dict("status" => "x")) == "x"
    # blocked pre-execution runs report a truthful data_mode
    lt["blocked_data_mode_truthful"] =
        pd_preexec_data_mode(true) == "dry_run_script_generation_only" &&
        pd_preexec_data_mode(false) == "blocked_no_script_generated"
    # claim discipline: withheld on failure, verbatim on green
    lt["claims_withheld_on_failure"] =
        pd_claim(true, "verified", "withheld") == "verified" &&
        pd_claim(false, "verified", "withheld") == "withheld"
    # a failed gate can never yield success, and the complete failed-gate
    # census is ALWAYS appended -- one gate's reason cannot hide another
    # gate's silent failure
    lt["failed_gate_closed_without_reason"] = begin
        f1, ok1 = pd_close_failed_gates(String[], Dict("g" => "failed"))
        f2, ok2 = pd_close_failed_gates(String[], Dict("g" => "passed"))
        f3, ok3 = pd_close_failed_gates(["reason for a"],
            Dict("a" => "failed", "b" => "failed"))
        !ok1 && length(f1) == 1 && occursin("fail-closed census", f1[1]) &&
            ok2 && isempty(f2) &&
            !ok3 && length(f3) == 2 && f3[1] == "reason for a" &&
            occursin("a, b", f3[2])
    end
    rm(tdir, recursive = true, force = true)
    gates["prerequisite_loader_fixture_tests"] =
        all(values(lt)) ? "passed" : "failed"
    all(values(lt)) || push!(fails, "prerequisite loader fixture " *
        "failures: " * join(sort([k for (k, v) in lt if !v]), ", "))

    # exact case+status scaffold prerequisite through the shared loader
    scaffold_ok, scaffold_why, _ = pd_parse_pinned(
        "gate4_a2_reproduction_proof_scaffold.json",
        "gate4_a2_reproduction_proof_scaffold",
        "a2_proof_scaffold_ready")
    gates["scaffold_ready_required"] = scaffold_ok ? "passed" : "failed"
    scaffold_ok || push!(fails, scaffold_why)

    isfile(LW_CAND) && isfile(SW_CAND) ||
        (push!(fails, "candidate files missing"); return finish(gates, fails,
            Dict(), ""; lt = lt))
    lw_sha = pd_try_sha(LW_CAND)
    sw_sha = pd_try_sha(SW_CAND)
    if lw_sha === nothing || sw_sha === nothing
        push!(fails, "candidate files unreadable at hash time")
        return finish(gates, fails, Dict(), ""; lt = lt)
    end
    gates["candidates_hashed"] = "passed"

    # POST-EXECUTION: both 4091 outputs on disk -> read-only historical mode
    if isfile(LW_RAW) && isfile(SW_RAW)
        payload = historical_executed_mode(gates, fails, lw_sha, sw_sha)
        return finish(gates, fails, payload, ""; lt = lt)
    elseif isfile(LW_RAW) || isfile(SW_RAW)
        push!(fails, "PARTIAL proof outputs on disk (exactly one of LW/SW " *
                     "raw exists) -- anomalous state; investigate against " *
                     "the 4091 finding ledger before any action")
        return finish(gates, fails, Dict("mode" => "partial_outputs"), "";
                      lt = lt)
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
    # the WRITE is allowlist-gated on the classified scaffold
    # prerequisite: a blocked pre-execution run never clobbers PD_SBATCH
    sbatch_written = pd_write_script(() -> open(PD_SBATCH, "w") do io
        write(io, sbatch_text)
    end, true, scaffold_ok)

    sb_gate = sbatch_written ? "sbatch_written_not_submitted" :
              "sbatch_blocked_preserved_not_submitted"
    gates[sb_gate] = "passed"
    self_src = read(@__FILE__, String)
    sb_tok = "sb" * "atch "
    isempty(collect(eachmatch(Regex("run\\(`" * sb_tok), self_src))) ||
        (gates[sb_gate] = "failed";
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
    return finish(gates, fails, payload, sbatch_text;
                  lt = lt, sbatch_written = sbatch_written)
end

function finish(gates, fails, payload, sbatch_text;
                lt = Dict{String, Bool}(), sbatch_written = false)
    mode = get(payload, "mode", "")
    historical = mode == "historical_executed"
    partial = mode == "partial_outputs"
    # fail-closed status selection: every failed gate is closed into a
    # controlled reason, and success requires EVERY gate passed
    fails, gates_all_passed = pd_close_failed_gates(fails, gates)
    status = !(isempty(fails) && gates_all_passed) ?
             "a2_proof_driver_failed" :
             historical ? "a2_proof_driver_historical_executed" :
                          "a2_proof_driver_ready_awaiting_go"
    sb_identity_ok =
        get(gates, "preserved_sbatch_matches_submission_ledger", "") ==
        "passed"
    data_mode = historical ? "historical_post_execution_verification_only" :
                partial ? "anomalous_partial_outputs_no_generation" :
                          pd_preexec_data_mode(sbatch_written)
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_a2_proof_driver_checkpoint",
        "data_mode" => data_mode,
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "prerequisite_loader_fixture_verdicts" => lt,
        "sbatch_path" => PD_SBATCH,
        "sbatch_written_this_run" => sbatch_written,
        "sbatch_scripts_state" => historical ?
            pd_claim(sb_identity_ok,
                "EXECUTED script preserved (ledger-verified identity); " *
                "never regenerated",
                "EXECUTED-script identity verification FAILED; claim " *
                "withheld; the preserved file was NOT regenerated or " *
                "modified by this unit") :
            sbatch_written ?
            "generated this run (unsubmitted)" :
            isfile(PD_SBATCH) ?
            "NOT generated this run (prerequisite blocked or anomalous " *
            "state); the file at sbatch_path is PRESERVED output of an " *
            "earlier run, not current" :
            "NOT generated this run; NO file exists at sbatch_path",
        "payload" => payload,
        "provenance" => Dict("branch" => branch, "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => historical ?
            pd_claim(status == "a2_proof_driver_historical_executed",
                "HISTORICAL post-execution record: the generated sbatch " *
                "was executed as authorized proof job 4091 " *
                "(ledger-verified, not assumed); outputs verified " *
                "against the reviewed finding ledger; the executed " *
                "script is preserved, never regenerated; nothing " *
                "submitted or executed by this unit.",
                "HISTORICAL post-execution record with FAILED " *
                "verification: executed/promoted claims WITHHELD " *
                "pending review; the preserved script and outputs were " *
                "NOT regenerated or modified by this unit; nothing " *
                "submitted or executed.") :
            partial ?
            "ANOMALOUS partial-output state: exactly one 4091 raw output " *
            "is on disk; nothing generated, regenerated, or submitted; " *
            "investigate against the finding ledger before any action." :
            sbatch_written ?
            "dry-run script generation only; nothing submitted; " *
            "no create_lut, comparison, objective, floor, or " *
            "acceptance execution; submission requires explicit " *
            "review/go per the standing protocol." :
            "BLOCKED pre-execution run: a prerequisite failed, NO " *
            "script was generated, nothing submitted; any file at the " *
            "sbatch path is preserved output of an earlier run.",
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
        elseif sbatch_written
            println(io, "\nGenerated (unsubmitted) proof batch script: " *
                        "`$(PD_SBATCH)`")
        else
            println(io, "\nNO script generated this run (prerequisite " *
                        "blocked or anomalous state); any file at " *
                        "`$(PD_SBATCH)` is preserved output of an " *
                        "earlier run, not current.")
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
