# Gate-4 G3 EXECUTOR checkpoint (dry-run generation; NO submission, NO
# execution). Generates the two staged-optimizer sbatch scripts (LW, SW)
# for the recovery run, wired per the verbatim optimizer spec and the
# scoped actual-input preflight. Submission requires BOTH the scoped
# preflight reporting ready (eval2 pair installed by G2d) AND explicit
# review/go -- this unit only writes artifacts.
#
# Wiring (all monitor-reviewed evidence):
#   LW: pinned v1.2 test scripts + v1.2 binary; WORK_DIR=work (accepted
#       raw init ce057079..., gpoints c96e6492..., eval2 LW flux installed
#       there by G2d); ECCKD_PREFIX=ecckd-1.2 via version.h; passes
#       relative-base relative-ch4 relative-n2o relative-cfc (CLI args);
#       chain raw->raw2->raw3->raw4->ckd.
#   SW: v1.4 tree test scripts (byte-identical to pinned v1.2 for
#       optimize_lut_sw.sh -- verified by diff) + v1.4 binary; WORK_DIR=
#       work-v14 (accepted scaled init 74d8be65..., gpoints symlink ->
#       1.2 candidate 13dd686a..., eval2 SW rgb flux dual-installed there
#       by G2d); ECCKD_PREFIX=ecckd-1.4; passes relative-base relative-ch4
#       relative-n2o; chain scaled->raw2->raw3->ckd; rgb rewrite maps
#       training paths to evaluation1/sw_fluxes-rgb.
#   TRAINING_BOTH=yes sed (config.h:71 default no) appends the eval2
#       rel-415 file to the relative-base pass, both bands = the faithful
#       '-32b' training set.
#   optimize_lut enables FP traps (optimize_lut.cpp:51) -> each sbatch
#       generates an OPTIMIZER-SPECIFIC wrapper (LD_PRELOAD the hash-pinned
#       4099 H5open-preinit .so, exec the band's pinned binary) and seds
#       OPTIMIZE_LUT= in the testcopy config to that wrapper.
#
# ACCEPTANCE METRICS (evaluated by a SEPARATE post-run comparison unit,
# never inside the executor): final/target <= 1.05, weight L1 <= 0.02,
# OD log-RMSE <= 0.02 vs the published models.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const ECCKD_SRC = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"
const V14_TREE = "/shared/home/greg/ecckd-derived-flux-work/ecckd-v1.4-23adaca"
const V12_SRCDIR = "/shared/home/greg/ecckd-derived-flux-work/ecckd/src/ecckd"
const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"
const CKDMIP_BIN_ROOT = "/shared/home/greg/build/ckdmip-1.0"
const SHIM_SO = "$G4WORK/tools/h5open_before_traps.so"
const SHIM_SO_SHA = "28003281a7f1c8470c1bfd94a654999a210581261a5c3e9cd662af2a13dd492f"
const LW_INIT_SHA = "ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43"
const SW_INIT_SHA = "74d8be65226f081f3d2882520ab374ed102d73cc3dd43bb2fa7c5a5c27602d74"
const V12_BIN_SHA = "6c3600fe6001d92e0d067cde1d57f19c82bae0c208a32dd2c48cd77031c05692"
const V14_BIN_SHA = "101e41ed77c83c81c138494a2b950bbffd12caad27b0c64028666550d7c30d65"

const GX_RESULTS_JSON = validation_results_path("gate4_g3_executor_checkpoint.json")
const GX_RESULTS_MD = validation_results_path("gate4_g3_executor_checkpoint.md")
const GX_SBATCH_LW = validation_results_path("gate4_g3_lw_optimizer.sbatch")
const GX_SBATCH_SW = validation_results_path("gate4_g3_sw_optimizer.sbatch")

# The future submit entrypoint. This checkpoint NEVER calls it.
function submit_g3(; authorize::Symbol = :refused)
    authorize === :g3_recovery_go ||
        error("submit_g3 refused: requires authorize=:g3_recovery_go " *
              "(explicit go after scoped preflight is ready and this " *
              "checkpoint is reviewed)")
    error("not implemented in the checkpoint: submission is a human sbatch " *
          "command per the runbook sequence")
end

function make_sbatch(band)
    lw = band == "lw"
    srcdir   = lw ? ECCKD_SRC : V14_TREE
    ver      = lw ? "1.2" : "1.4"
    bindir   = lw ? V12_SRCDIR : "$V14_TREE/src/ecckd"
    binsha   = lw ? V12_BIN_SHA : V14_BIN_SHA
    initsha  = lw ? LW_INIT_SHA : SW_INIT_SHA
    workdir  = lw ? "$G4WORK/work" : "$G4WORK/work-v14"
    initfile = lw ?
        "$G4WORK/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc" :
        "$G4WORK/work-v14/sw_raw-ckd-definition/ecckd-1.4_sw_scaled-ckd-definition_climate_rgb-tol0.047.nc"
    eval2    = lw ?
        "$G4WORK/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5" :
        "$G4WORK/work-v14/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5"
    bandstruct = lw ? "fsck" : "rgb"
    tol      = lw ? "0.0161" : "0.047"
    modes    = lw ? "relative-base relative-ch4 relative-n2o relative-cfc" :
                    "relative-base relative-ch4 relative-n2o"
    script   = lw ? "optimize_lut_lw.sh" : "optimize_lut_sw.sh"
    outdir_raw = "$workdir/$(band)_raw-ckd-definition"
    outdir_ckd = "$workdir/$(band)_ckd-definition"
    stale = lw ?
        ["$outdir_raw/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
         "$outdir_raw/ecckd-1.2_lw_raw3-ckd-definition_climate_fsck-tol0.0161.nc",
         "$outdir_raw/ecckd-1.2_lw_raw4-ckd-definition_climate_fsck-tol0.0161.nc",
         "$outdir_ckd/ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc"] :
        ["$outdir_raw/ecckd-1.4_sw_raw2-ckd-definition_climate_rgb-tol0.047.nc",
         "$outdir_raw/ecckd-1.4_sw_raw3-ckd-definition_climate_rgb-tol0.047.nc",
         "$outdir_ckd/ecckd-1.4_sw_ckd-definition_climate_rgb-tol0.047.nc"]
    stale_block = join(["test ! -e \"$f\" || { echo \"REFUSED: stale optimizer output exists: $f\" >&2; exit 70; }"
                        for f in stale], "\n")
    final_ckd = stale[end]
    """
#!/bin/bash
#SBATCH --job-name=g4-g3-$(band)-optimizer
#SBATCH --output=/shared/home/greg/data/ckdmip-logs/g4-g3-$(band)-%j.log
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=36
#SBATCH --mem=60G
#SBATCH --partition=cpu-large

# Gate-4 G3 $(uppercase(band)) staged optimizer: optimize_lut ONLY (no
# create/scale/find/LBL stages). Generated by gate4_g3_executor_checkpoint.jl.
# Faithful TRAINING_BOTH=yes recovery run from the accepted init.
set -euo pipefail
if [ -z "\${SLURM_JOB_ID:-}" ]; then
    echo "REFUSED: head-node execution is not permitted; submit via sbatch." >&2
    exit 64
fi

G4WORK=$G4WORK
TESTCOPY="\$G4WORK/testcopy-g3-$(band)"

echo "=== G3-$(band) stage 0: input identity checks ==="
sha256sum -c <<'HASHES' || { echo "REFUSED: pinned input hash mismatch" >&2; exit 69; }
$initsha  $initfile
$binsha  $bindir/optimize_lut
$SHIM_SO_SHA  $SHIM_SO
HASHES
test -x "$bindir/optimize_lut" || { echo "REFUSED: optimize_lut not executable" >&2; exit 68; }
test -s "$eval2" || { echo "REFUSED: eval2 TRAINING_BOTH file missing (G2d incomplete)" >&2; exit 65; }
$stale_block

echo "=== G3-$(band) stage 1: optimizer wrapper (FP-trap shim; env-only) ==="
mkdir -p "\$G4WORK/tools"
cat > "\$G4WORK/tools/optimize_lut_h5preinit_v$(replace(ver, "." => ""))" <<WRAP
#!/bin/bash
export LD_PRELOAD="$SHIM_SO"
exec "$bindir/optimize_lut" "\\\$@"
WRAP
chmod +x "\$G4WORK/tools/optimize_lut_h5preinit_v$(replace(ver, "." => ""))"
sha256sum "\$G4WORK/tools/optimize_lut_h5preinit_v$(replace(ver, "." => ""))"

echo "=== G3-$(band) stage 2: isolated testcopy (config overrides) ==="
rm -rf "\$TESTCOPY"
cp -r "$srcdir/test" "\$TESTCOPY"
cd "\$TESTCOPY"
sed 's/@PACKAGE_VERSION@/$ver/g' version.h.in > version.h
sed -i \\
  -e 's|^CKDMIP_DIR=.*|CKDMIP_DIR=$CKDMIP_BIN_ROOT|' \\
  -e 's|^CKDMIP_DATA_DIR=.*|CKDMIP_DATA_DIR=$CKDMIP_ROOT|' \\
  -e 's|^WORK_DIR=.*|WORK_DIR=$workdir|' \\
  -e 's|^BINDIR=.*|BINDIR=$bindir|' \\
  -e 's|^TRAINING_BOTH=no\$|TRAINING_BOTH=yes|' \\
  -e 's|^OPTIMIZE_LUT=.*|OPTIMIZE_LUT=$G4WORK/tools/optimize_lut_h5preinit_v$(replace(ver, "." => ""))|' \\
  config.h
grep -E "^(CKDMIP_DIR|CKDMIP_DATA_DIR|WORK_DIR|BINDIR|TRAINING_BOTH|OPTIMIZE_LUT)=" config.h
grep -qE "^TRAINING_BOTH=yes\$" config.h || { echo "BAD config: TRAINING_BOTH" >&2; exit 68; }

echo "=== G3-$(band) stage 3: staged optimizer ($modes) ==="
APPLICATION=climate BAND_STRUCTURE=$bandstruct TOLERANCE=$tol \\
    bash $script $modes

echo "=== G3-$(band) outputs ==="
sha256sum $(join(map(f -> "\"$f\"", stale), " \\\n    "))
test -s "$final_ckd" || { echo "MISSING final ckd-definition" >&2; exit 71; }
echo "=== G3-$(band) done rc=\$? \$(date -u +%FT%TZ) ==="
"""
end

function main()
    fails = String[]
    gates = Dict{String, String}()

    pf = JSON.parsefile(validation_results_path("gate4_g3_scoped_input_preflight.json"))
    pf_ready = pf["status"] == "g3_scoped_preflight_ready"
    gates["scoped_preflight_prerequisite"] =
        pf_ready ? "passed" :
        (pf["status"] == "g3_scoped_preflight_waiting_for_eval2" ? "waiting" : "failed")
    pf["status"] in ("g3_scoped_preflight_ready",
                     "g3_scoped_preflight_waiting_for_eval2") ||
        push!(fails, "scoped preflight in failed state: $(pf["status"])")

    lw_text = make_sbatch("lw")
    sw_text = make_sbatch("sw")
    open(GX_SBATCH_LW, "w") do io; write(io, lw_text); end
    open(GX_SBATCH_SW, "w") do io; write(io, sw_text); end

    gates["sbatch_written_not_submitted"] = "passed"
    self_src = read(@__FILE__, String)
    sb_tok = "sb" * "atch "
    isempty(collect(eachmatch(Regex("run\\(`" * sb_tok), self_src))) ||
        (gates["sbatch_written_not_submitted"] = "failed";
         push!(fails, "sbatch invocation found in checkpoint unit"))
    for (nm, txt) in (("lw", lw_text), ("sw", sw_text))
        exec_lines = join([l for l in split(txt, '\n')
                           if !occursin(r"^\s*#", l)], '\n')
        gates["$(nm)_headnode_refusal"] =
            occursin("REFUSED: head-node execution", txt) ? "passed" : "failed"
        gates["$(nm)_optimize_only"] =
            occursin("optimize_lut", exec_lines) &&
            !occursin("create_lut", exec_lines) &&
            !occursin("create_look_up_table", exec_lines) &&
            !occursin("scale_lut_", exec_lines) &&
            !occursin("find_g_points", exec_lines) &&
            !occursin("run_ckd", exec_lines) &&
            !occursin("lbl_evaluation", exec_lines) ? "passed" : "failed"
        gates["$(nm)_optimize_only"] == "passed" ||
            push!(fails, "$nm: forbidden stage in executable lines")
        gates["$(nm)_training_both_sed"] =
            occursin("TRAINING_BOTH=no\$|TRAINING_BOTH=yes", txt) ? "passed" : "failed"
        gates["$(nm)_shim_wrapper"] =
            occursin("LD_PRELOAD", txt) && occursin(SHIM_SO_SHA, txt) &&
            occursin("OPTIMIZE_LUT=$G4WORK/tools/optimize_lut_h5preinit", txt) ?
            "passed" : "failed"
        gates["$(nm)_stale_output_refusal"] =
            occursin("stale optimizer output exists", txt) ? "passed" : "failed"
        gates["$(nm)_input_hash_gate"] =
            occursin("sha256sum -c", txt) &&
            occursin("eval2 TRAINING_BOTH file missing", txt) ? "passed" : "failed"
    end
    gates["lw_mode_list"] =
        occursin("optimize_lut_lw.sh relative-base relative-ch4 relative-n2o relative-cfc",
                 lw_text) ? "passed" : "failed"
    gates["sw_mode_list"] =
        occursin("optimize_lut_sw.sh relative-base relative-ch4 relative-n2o",
                 sw_text) && !occursin("relative-cfc", sw_text) ? "passed" : "failed"
    gates["token_gated_submit"] = try
        submit_g3(); "failed"
    catch err
        occursin("refused", sprint(showerror, err)) ? "passed" : "failed"
    end
    gates["sw_script_version_identity"] =
        read(`diff -q $V14_TREE/test/optimize_lut_sw.sh $ECCKD_SRC/test/optimize_lut_sw.sh`,
             String) == "" ? "passed" : "failed"

    others = [k for k in keys(gates) if k != "scoped_preflight_prerequisite"]
    others_pass = all(k -> gates[k] == "passed", others)
    status = if others_pass && pf_ready && isempty(fails)
        "g3_executor_ready_awaiting_go"
    elseif others_pass && isempty(fails)
        "g3_executor_waiting_for_eval2"
    else
        "g3_executor_checkpoint_failed"
    end

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    ghead = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_g3_executor_checkpoint",
        "data_mode" => "dry_run_script_generation_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "sbatch_paths" => Dict("lw" => GX_SBATCH_LW, "sw" => GX_SBATCH_SW),
        "authorization_token_required" => "g3_recovery_go (plus scoped " *
            "preflight ready; submission is a reviewed human step)",
        "acceptance_metrics_note" => "final/target <= 1.05, weight L1 <= " *
            "0.02, OD log-RMSE <= 0.02 vs published models -- evaluated by " *
            "a separate post-run comparison unit, never inside the executor",
        "provenance" => Dict("branch" => branch, "generated_from_head" => ghead,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "script generation only; nothing submitted or " *
                        "executed; no objective, floor, or recovery " *
                        "computation in this unit.",
    )
    mkpath(dirname(GX_RESULTS_JSON))
    open(GX_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(GX_RESULTS_MD, "w") do io
        println(io, "# Gate-4 G3 executor checkpoint (dry-run)\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nGenerated (unsubmitted): `$(GX_SBATCH_LW)`, `$(GX_SBATCH_SW)`")
        println(io, "\nAuthorization: token `g3_recovery_go` + scoped " *
                    "preflight ready + review.")
        println(io, "\n", result["acceptance_metrics_note"])
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$ghead` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_g3_executor_checkpoint: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status in ("g3_executor_ready_awaiting_go",
                      "g3_executor_waiting_for_eval2") ? 0 : 1
end

exit(main())
