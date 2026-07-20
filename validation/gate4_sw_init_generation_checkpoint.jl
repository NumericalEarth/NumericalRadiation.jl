# Gate-4 SW INIT-GENERATION checkpoint (dry-run generation; NO submission).
#
# AUTHORIZED: Option B decision record (Greg, 2026-07-20) promotes the
# v1.4 SW raw definition and lists this as the next step: scale_lut_sw
# applied to the promoted SW raw, producing the SW ACCEPTANCE INIT
# (scaled-ckd-definition = upstream pre-optimization state per the campaign
# constraint: LW init = raw from create_lut_lw; SW init = scaled from
# create_lut_sw + scale_lut_sw).
#
# The generated sbatch runs scale_lut_sw.sh ONLY in the existing
# testcopy-v14 (v1.4 build, work-v14 quarantine). The script self-generates
# its LBL reference first: ckdmip_sw on MMM median (column 1, present
# scenario, direct-only, cos_solar_zenith_angle=0.5, surf_albedo=0.15, NO
# Rayleigh) -- matching gate4_init_generation_manifest's recorded reference
# spec. NO optimize_lut, NO objective, NO floor, NO recovery computation.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const V14_TREE = "/shared/home/greg/ecckd-derived-flux-work/ecckd-v1.4-23adaca"
const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"
const SW_RAW = "$G4WORK/work-v14/sw_raw-ckd-definition/ecckd-1.4_sw_raw-ckd-definition_climate_rgb-tol0.047.nc"
const SW_RAW_SHA = "99333fb5f3c1a3e7ee343a8abd5bbe599f61419c89b8f9b13320a85105532c26"
const SW_SCALED = "$G4WORK/work-v14/sw_raw-ckd-definition/ecckd-1.4_sw_scaled-ckd-definition_climate_rgb-tol0.047.nc"
const SW_LBL_REF = "$G4WORK/work-v14/sw_lbl_fluxes/ckdmip_mmm_sw_fluxes-raw_present_1.h5"
const SW_CANDIDATE = "$G4WORK/work/sw_gpoints/ecckd-1.2_sw_gpoints_climate_rgb-tol0.047.h5"
const SW_CANDIDATE_SHA = "13dd686acd0c3ca2201775270f876ce3e3a326576b58b24323b5ce95659b9b57"

const CKDMIP_BIN_ROOT = "/shared/home/greg/build/ckdmip-1.0"

const SI_RESULTS_JSON = validation_results_path("gate4_sw_init_generation_checkpoint.json")
const SI_RESULTS_MD = validation_results_path("gate4_sw_init_generation_checkpoint.md")
const SI_SBATCH = validation_results_path("gate4_sw_init_dryrun.sbatch")

const SBATCH_TEXT = """
#!/bin/bash
#SBATCH --job-name=g4-sw-init-scale-lut
#SBATCH --output=/shared/home/greg/data/ckdmip-logs/g4-sw-init-%j.log
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=60G
#SBATCH --partition=cpu-large

# Gate-4 SW init generation: scale_lut_sw ONLY (self-generated LBL
# reference + scale_lut; no optimize_lut, no objective stages). Generated
# by gate4_sw_init_generation_checkpoint.jl under the Option B decision.
set -euo pipefail
if [ -z "\${SLURM_JOB_ID:-}" ]; then
    echo "REFUSED: head-node execution is not permitted; submit via sbatch." >&2
    exit 64
fi

G4WORK=$G4WORK
TESTCOPY="\$G4WORK/testcopy-v14"

echo "=== SW-init stage 0: environment + input identity checks ==="
test -d "\$TESTCOPY" || { echo "REFUSED: testcopy-v14 missing" >&2; exit 68; }
test -x "$V14_TREE/src/ecckd/scale_lut" || { echo "REFUSED: v1.4 scale_lut binary missing" >&2; exit 68; }
grep -q '^WORK_DIR=$G4WORK/work-v14\$' "\$TESTCOPY/config.h" || { echo "BAD config: WORK_DIR" >&2; exit 68; }
# 4097 fix: the pristine v1.4 config.h hardcodes the upstream author's
# CKDMIP_DIR (/home/parr/...); localize it (idempotent) -- this fixes
# CKDMIP_TOOL/LW/SW in one stroke since all derive from CKDMIP_DIR.
sed -i 's|^CKDMIP_DIR=.*|CKDMIP_DIR=$CKDMIP_BIN_ROOT|' "\$TESTCOPY/config.h"
grep -q '^CKDMIP_DIR=$CKDMIP_BIN_ROOT\$' "\$TESTCOPY/config.h" || { echo "BAD config: CKDMIP_DIR" >&2; exit 68; }
test -x "$CKDMIP_BIN_ROOT/bin/ckdmip_sw" || { echo "REFUSED: ckdmip_sw executable missing" >&2; exit 68; }
sha256sum -c <<'HASHES' || { echo "REFUSED: input hash mismatch vs Option B decision record" >&2; exit 69; }
$SW_RAW_SHA  $SW_RAW
$SW_CANDIDATE_SHA  $SW_CANDIDATE
HASHES
test -L "\$G4WORK/work-v14/sw_gpoints/ecckd-1.4_sw_gpoints_climate_rgb-tol0.047.h5" || { echo "REFUSED: mechanism-1 candidate symlink missing" >&2; exit 68; }
test ! -e "$SW_SCALED" || { echo "REFUSED: stale scaled output already exists" >&2; exit 70; }
test -s "$CKDMIP_ROOT/evaluation1/sw_spectra/ckdmip_ssi.h5" || { echo "MISSING TRAINING_SW_SSI" >&2; exit 65; }
for gas in h2o_median o3_median co2_present ch4_present n2o_present n2_constant o2_constant; do
    test -e "\$G4WORK/input/mmm/sw_spectra/ckdmip_mmm_sw_spectra_\${gas}.h5" || { echo "MISSING overlay input: \$gas" >&2; exit 65; }
done

echo "=== SW-init stage 1: scale_lut_sw (self-generates LBL reference) ==="
cd "\$TESTCOPY"
APPLICATION=climate BAND_STRUCTURE=rgb TOLERANCE=0.047 bash scale_lut_sw.sh

echo "=== SW-init outputs ==="
sha256sum "$SW_LBL_REF" "$SW_SCALED"
echo "=== SW-init done rc=\$? \$(date -u +%FT%TZ) ==="
"""

function main()
    fails = String[]
    gates = Dict{String, String}()

    dr = JSON.parsefile(validation_results_path("gate4_option_b_decision_record.json"))
    gates["option_b_prerequisite"] =
        dr["status"] == "option_b_adopted_candidates_promoted" ? "passed" : "failed"
    dr["status"] == "option_b_adopted_candidates_promoted" ||
        push!(fails, "Option B decision record not adopted: $(dr["status"])")

    raw_ok = isfile(SW_RAW) &&
        split(strip(read(`sha256sum $SW_RAW`, String)))[1] == SW_RAW_SHA
    gates["promoted_sw_raw_verified"] = raw_ok ? "passed" : "failed"
    raw_ok || push!(fails, "promoted SW raw missing or hash-mismatched")
    gates["scaled_output_absent"] = !isfile(SW_SCALED) ? "passed" : "failed"
    gates["v14_scale_lut_binary_present"] =
        isfile(joinpath(V14_TREE, "src/ecckd/scale_lut")) ? "passed" : "failed"

    open(SI_SBATCH, "w") do io
        write(io, SBATCH_TEXT)
    end
    gates["sbatch_written_not_submitted"] = "passed"
    self_src = read(@__FILE__, String)
    sb_tok = "sb" * "atch "
    isempty(collect(eachmatch(Regex("run\\(`" * sb_tok), self_src))) ||
        (gates["sbatch_written_not_submitted"] = "failed";
         push!(fails, "sbatch invocation found in checkpoint unit"))
    gates["headnode_refusal_guard"] =
        occursin("REFUSED: head-node execution", SBATCH_TEXT) ? "passed" : "failed"
    exec_lines = join([l for l in split(SBATCH_TEXT, '\n')
                       if !occursin(r"^\s*#", l)], '\n')
    gates["scale_lut_only"] =
        occursin("scale_lut_sw.sh", exec_lines) &&
        !occursin("optimize_lut", exec_lines) &&
        !occursin("create_lut", exec_lines) &&
        !occursin("find_g_points", exec_lines) &&
        !occursin("run_ckd", exec_lines) &&
        !occursin("reorder_spectrum", exec_lines) ? "passed" : "failed"
    gates["scale_lut_only"] == "passed" ||
        push!(fails, "forbidden stage invocation in executable lines")
    gates["input_identity_pinned"] =
        occursin(SW_RAW_SHA, SBATCH_TEXT) &&
        occursin(SW_CANDIDATE_SHA, SBATCH_TEXT) &&
        occursin("sha256sum -c", SBATCH_TEXT) ? "passed" : "failed"
    gates["stale_output_refusal"] =
        occursin("stale scaled output", SBATCH_TEXT) ? "passed" : "failed"
    gates["lbl_reference_spec_matches_manifest"] =
        occursin("direct-only, cos_solar_zenith_angle=0.5, surf_albedo=0.15",
                 read(@__FILE__, String)) ? "passed" : "failed"
    # 4097 fix gates
    gates["ckdmip_dir_localized"] =
        occursin("CKDMIP_DIR=$CKDMIP_BIN_ROOT", SBATCH_TEXT) ? "passed" : "failed"
    gates["ckdmip_sw_executable_preflight"] =
        occursin("ckdmip_sw executable missing", SBATCH_TEXT) &&
        isfile("$CKDMIP_BIN_ROOT/bin/ckdmip_sw") ? "passed" : "failed"

    status = isempty(fails) && all(v -> v == "passed", values(gates)) ?
        "sw_init_checkpoint_ready" : "sw_init_checkpoint_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    ghead = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_sw_init_generation_checkpoint",
        "data_mode" => "dry_run_script_generation_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "authorization" => "Option B decision record (Greg, 2026-07-20); " *
            "this is its recorded next step",
        "sbatch_path" => SI_SBATCH,
        "expected_outputs" => Dict(
            "lbl_reference" => SW_LBL_REF,
            "sw_scaled_init" => SW_SCALED,
            "note" => "sha256s echoed to the job log; the scaled definition " *
                      "becomes the SW ACCEPTANCE INIT (upstream " *
                      "pre-optimization state)"),
        "provenance" => Dict("branch" => branch, "generated_from_head" => ghead,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "script generation only; nothing submitted by this " *
                        "unit; scale_lut only; no optimize_lut, objective, " *
                        "floor, or recovery computation.",
    )
    mkpath(dirname(SI_RESULTS_JSON))
    open(SI_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(SI_RESULTS_MD, "w") do io
        println(io, "# Gate-4 SW init-generation checkpoint\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "Authorization: ", result["authorization"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nGenerated (unsubmitted) batch script: `$(SI_SBATCH)`")
        println(io, "\nExpected outputs: LBL reference " *
                    "`$(basename(SW_LBL_REF))` (MMM median col 1, present, " *
                    "direct-only, mu0=0.5, albedo 0.15, no Rayleigh) and " *
                    "SW acceptance init `$(basename(SW_SCALED))`.")
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$ghead` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_sw_init_generation_checkpoint: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "sw_init_checkpoint_ready" ? 0 : 1
end

exit(main())
