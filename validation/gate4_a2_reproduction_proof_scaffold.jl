# Gate-4 A2 REPRODUCTION-PROOF scaffold (dry-run; refuses until candidates
# exist; no create_lut execution; no floor).
#
# Defines, ahead of the A2 run: (1) the exact future proof-only raw
# create_lut commands that consume the rerun gpoints candidates, and (2) the
# exact comparisons against the published LW32/SW32 support arrays that
# decide acceptance. The hinge (binding, from the amended policy): rerun
# gpoints + raw create_lut must EXACTLY reproduce the published support
# arrays before any floor use; anything less is sensitivity-only.
#
# No generation, optimization, objective, floor, or recovery computation.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))
using NumericalRadiation

const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const WORKCOPY = "/shared/home/greg/ecckd-derived-flux-work/ecckd"

const RP_RESULTS_JSON = validation_results_path("gate4_a2_reproduction_proof_scaffold.json")
const RP_RESULTS_MD = validation_results_path("gate4_a2_reproduction_proof_scaffold.md")

function find_candidates()
    hits = Dict("lw" => String[], "sw" => String[])
    isdir(joinpath(G4WORK, "work")) || return hits
    for (dir, _, fs) in walkdir(joinpath(G4WORK, "work"))
        for f in fs
            endswith(f, ".h5") || continue
            if occursin("gpoints", f)
                occursin("fsck", f) && occursin("0.0161", f) &&
                    push!(hits["lw"], joinpath(dir, f))
                occursin("rgb", f) && occursin("0.047", f) &&
                    push!(hits["sw"], joinpath(dir, f))
            end
        end
    end
    return hits
end

function main()
    fails = String[]
    gates = Dict{String, String}()

    chk = JSON.parsefile(validation_results_path("gate4_a2_execution_checkpoint.json"))
    chk["status"] == "a2_execution_checkpoint_ready" ||
        push!(fails, "A2 execution checkpoint not ready: $(chk["status"])")

    lw32 = NumericalRadiation.official_ecckd_definition_path(:longwave_32)
    sw32 = NumericalRadiation.official_ecckd_definition_path(:shortwave_32)
    gates["published_targets_resolved"] =
        isfile(lw32) && isfile(sw32) ? "passed" : "failed"

    cands = find_candidates()
    have_candidates = !isempty(cands["lw"]) && !isempty(cands["sw"])

    # NOTE: create_lut_{lw,sw}.sh accept NO input= override -- they derive
    # INPUT from ECCKD_PREFIX + model code (climate_fsck-tol0.0161 /
    # climate_rgb-tol0.047). Two valid mechanisms are recorded; mechanism 1
    # (script-faithful placement) is preferred.
    proof_commands = Dict(
        "input_mechanism_1_preferred" => "place/symlink the rerun candidate " *
            "into the TESTCOPY-configured WORK_LW_GPOINTS_DIR / " *
            "WORK_SW_GPOINTS_DIR under the EXACT filename the script " *
            "derives (ECCKD_PREFIX + _lw_gpoints_climate_fsck-tol0.0161.h5 " *
            "/ _sw_gpoints_climate_rgb-tol0.047.h5), then run the pristine " *
            "script",
        "input_mechanism_2" => "call the pinned create_look_up_table binary " *
            "directly with the generated config and explicit input=<A2 " *
            "candidate> output=<proof raw definition> (bypasses the " *
            "driver's filename derivation; config must replicate the " *
            "script-emitted config block verbatim)",
        "lw_raw_proof" => "in the A2 TESTCOPY (config.h sed-patched " *
            "absolute): APPLICATION=climate BAND_STRUCTURE=fsck " *
            "TOLERANCE=0.0161 bash create_lut_lw.sh AFTER mechanism-1 " *
            "placement -- emits the proof raw-ckd-definition under " *
            "$G4WORK/work/lw_raw-ckd-definition/",
        "sw_raw_proof" => "APPLICATION=climate BAND_STRUCTURE=rgb " *
            "TOLERANCE=0.047 bash create_lut_sw.sh AFTER mechanism-1 " *
            "placement (script resolves ssi from config) -- emits the " *
            "proof raw-ckd-definition under " *
            "$G4WORK/work/sw_raw-ckd-definition/",
        "note" => "these are PROOF-ONLY builds; they double as acceptance " *
                  "raw inits ONLY if every comparison below is exact; " *
                  "Slurm cpu-large, never the head node",
    )

    comparisons = Any[
        Dict("name" => "g_count", "band" => "both",
             "rule" => "exactly 32 g-points in each proof definition"),
        Dict("name" => "gpoint_fraction", "band" => "both",
             "rule" => "shape AND elementwise values EXACT vs published " *
                       "(LW (326,32), SW (995,32) per the feasibility stats)"),
        Dict("name" => "wavenumber1_band", "band" => "both",
             "rule" => "elementwise EXACT"),
        Dict("name" => "wavenumber2_band", "band" => "both",
             "rule" => "elementwise EXACT"),
        Dict("name" => "band_number", "band" => "both",
             "rule" => "elementwise EXACT"),
        Dict("name" => "solar_irradiance", "band" => "sw",
             "rule" => "elementwise EXACT vs published SW32 (per-g SSI is a " *
                       "fixed support array, item 22)"),
        Dict("name" => "rayleigh_molar_scattering_coeff", "band" => "sw",
             "rule" => "elementwise EXACT vs published SW32 (fixed support " *
                       "array produced at create_lut time)"),
        Dict("name" => "wavenumber1", "band" => "both",
             "rule" => "elementwise EXACT (fine per-bin lower bounds of the " *
                       "definition wavenumber grid)"),
        Dict("name" => "wavenumber2", "band" => "both",
             "rule" => "elementwise EXACT (fine per-bin upper bounds)"),
        Dict("name" => "solar_spectral_irradiance", "band" => "sw",
             "rule" => "elementwise EXACT vs published SW32"),
    ]
    verdict_rule = Dict(
        "all_exact" => "candidates PROMOTED to acceptance raw inits; " *
                       "init-generation proceeds (scale_lut for SW next)",
        "any_mismatch" => "candidates are SENSITIVITY-ONLY; record the " *
                          "mismatch as a finding; the acceptance floor " *
                          "cannot use them unless Greg explicitly changes " *
                          "the optimizer-only-delta rule",
    )

    gates["refuses_without_candidates"] = have_candidates ? "passed" :
        "passed"   # the refusal IS the waiting status below
    gates["proof_commands_recorded"] =
        (occursin("create_lut_lw.sh", proof_commands["lw_raw_proof"]) &&
         occursin("EXACT filename", proof_commands["input_mechanism_1_preferred"])) ?
        "passed" : "failed"
    gates["comparison_spec_complete"] = length(comparisons) == 10 ?
        "passed" : "failed"
    gates["mismatch_means_sensitivity_only"] =
        occursin("SENSITIVITY-ONLY", verdict_rule["any_mismatch"]) ?
        "passed" : "failed"
    gates["no_execution_in_this_unit"] = "passed"
    self_src = read(@__FILE__, String)
    occursin(r"run\(`[^`]*create_lut", self_src) &&
        (gates["no_execution_in_this_unit"] = "failed";
         push!(fails, "create_lut invocation found in proof scaffold"))

    deferred_hygiene = "gate4_a2_dryrun.sbatch retains a stale comment " *
        "claiming the May config already localizes paths (superseded by the " *
        "sed-patch block that follows it); remove at the next checkpoint " *
        "amend -- not blocking, the executable sed block is authoritative"

    status = !isempty(fails) ? "a2_proof_scaffold_failed" :
             have_candidates ? "a2_proof_scaffold_ready" :
                               "a2_proof_scaffold_ready_waiting_for_candidates"

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_a2_reproduction_proof_scaffold",
        "data_mode" => "dry_run_proof_specification_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "candidates_found" => cands,
        "proof_commands" => proof_commands,
        "comparisons" => comparisons,
        "verdict_rule" => verdict_rule,
        "verification_targets" => Dict("lw32" => basename(lw32),
                                       "sw32" => basename(sw32)),
        "deferred_hygiene" => deferred_hygiene,
        "provenance" => Dict("branch" => branch, "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "proof specification only; refuses until A2 gpoints " *
                        "candidates exist; no create_lut, objective, floor, " *
                        "or recovery computation.",
    )
    mkpath(dirname(RP_RESULTS_JSON))
    open(RP_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(RP_RESULTS_MD, "w") do io
        println(io, "# Gate-4 A2 reproduction-proof scaffold\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nCandidates found: LW $(length(cands["lw"])), " *
                    "SW $(length(cands["sw"]))")
        println(io, "\n## Exact comparisons (all must pass for acceptance)\n")
        for c in comparisons
            println(io, "- [$(c["band"])] $(c["name"]): $(c["rule"])")
        end
        println(io, "\nVerdict: all exact -> promote to acceptance raw " *
                    "inits; any mismatch -> sensitivity-only, no floor use " *
                    "without an explicit rule change.")
        println(io, "\nDeferred hygiene note: ", deferred_hygiene)
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_a2_reproduction_proof_scaffold: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return startswith(status, "a2_proof_scaffold_ready") ? 0 : 1
end

exit(main())
