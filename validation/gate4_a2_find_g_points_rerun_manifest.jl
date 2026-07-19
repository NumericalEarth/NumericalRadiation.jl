# Gate-4 A2 rerun-with-proof MANIFEST (dry-run; nothing heavy executes).
#
# Operative path after the A1 negative result: rerun the upstream g-point
# construction with the pinned tool as fixed-input PROBLEM-DEFINITION
# reconstruction. Full chain per the pinned scripts:
#   reorder_spectrum_{lw,sw}.sh  (MMM median present-day spectra ->
#                                 {lw,sw}_order_<bandstruct>_<gas>.h5)
#   find_g_points_{lw,sw}.sh     (MMM spectra + reordering outputs,
#                                 per-TOLERANCE loop -> gpoints h5 outputs;
#                                 idealized spectra enter LATER, at the
#                                 create_lut proof stage)
# ACCEPTANCE HINGE (binding): a rerun output feeds the recovery floor ONLY if
# rerun gpoints + raw create_lut EXACTLY reproduce the published
# gpoint_fraction and band support arrays (and g-counts 32/32). Anything
# short of exact reproduction is SENSITIVITY-ONLY per the amended policy
# (gate4_gpoint_provenance_policy @ 270044e amendment).
#
# No find_g_points/create_lut/objective/floor execution in this unit.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const ECCKD_SRC = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"
const CKDMIP_ROOT = get(ENV, "RH_CKDMIP_DATA_PATH",
                        "/shared/home/greg/data/ckdmip")
const WORKROOT = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const TOOLDIR = "/shared/home/greg/ecckd-derived-flux-work/ecckd/src/ecckd"

const A2_RESULTS_JSON = validation_results_path("gate4_a2_find_g_points_rerun_manifest.json")
const A2_RESULTS_MD = validation_results_path("gate4_a2_find_g_points_rerun_manifest.md")

grepn(text, pat) = [(i, strip(l)) for (i, l) in enumerate(split(text, '\n'))
                    if occursin(pat, l) && !occursin(r"^\s*#", l)]

function main()
    fails = String[]
    gates = Dict{String, String}()

    src = Dict(
        "find_lw" => read(joinpath(ECCKD_SRC, "test/find_g_points_lw.sh"), String),
        "find_sw" => read(joinpath(ECCKD_SRC, "test/find_g_points_sw.sh"), String),
        "reorder_lw" => read(joinpath(ECCKD_SRC, "test/reorder_spectrum_lw.sh"), String),
        "reorder_sw" => read(joinpath(ECCKD_SRC, "test/reorder_spectrum_sw.sh"), String),
        "do_lw" => read(joinpath(ECCKD_SRC, "test/do_all_lw.sh"), String),
        "do_sw" => read(joinpath(ECCKD_SRC, "test/do_all_sw.sh"), String),
    )
    a1 = JSON.parsefile(validation_results_path("gate4_a1_upstream_recon.json"))
    a1["status"] == "a1_recon_no_exact_upstream_source_found" ||
        push!(fails, "A1 recon status unexpected: $(a1["status"]) -- A2 may " *
                     "not be the operative path")

    evidence = Dict{String, Any}(
        "tolerance_lists" => grepn(src["do_lw"], "TOLERANCE") ∪
                             grepn(src["do_sw"], "TOLERANCE") ∪
                             grepn(src["find_lw"], "TOLERANCE")[1:min(4, end)],
        "reorder_inputs_lw" => grepn(src["find_lw"], "median") ∪
                               grepn(src["find_lw"], "reordering_input"),
        "reorder_inputs_sw" => grepn(src["find_sw"], "median") ∪
                               grepn(src["find_sw"], "reordering_input"),
        "gpoint_outputs" => grepn(src["find_lw"], "gpoints") ∪
                            grepn(src["find_sw"], "gpoints"),
        "bandstructs" => grepn(src["do_lw"], "BANDSTRUCT") ∪
                         grepn(src["do_sw"], "BANDSTRUCT"),
    )

    # required inputs with presence
    req = Any[]
    function need(label, path; dir = false, glob = nothing)
        present = if glob !== nothing
            isdir(path) && any(occursin(glob, f) for f in readdir(path))
        else
            dir ? isdir(path) : isfile(path)
        end
        push!(req, Dict("label" => label, "path" => string(path),
                        "glob" => glob, "present" => present))
        return present
    end
    need("pinned find_g_points binary", joinpath(TOOLDIR, "find_g_points"))
    need("pinned reorder_spectrum binary",
         joinpath(TOOLDIR, "reorder_spectrum"))
    need("MMM LW median spectra", joinpath(CKDMIP_ROOT, "mmm/lw_spectra");
         glob = "median")
    need("MMM SW median spectra", joinpath(CKDMIP_ROOT, "mmm/sw_spectra");
         glob = "median")
    need("idealized LW spectra (create_lut PROOF stage, not find_g_points)",
         joinpath(CKDMIP_ROOT, "idealized/lw_spectra"); dir = true)
    need("idealized SW spectra (create_lut PROOF stage, not find_g_points)",
         joinpath(CKDMIP_ROOT, "idealized/sw_spectra"); dir = true)
    need("MMM SSI", joinpath(CKDMIP_ROOT, "mmm/sw_spectra_extras/ckdmip_ssi.h5"))
    n_present = count(r -> r["present"], req)
    inputs_ready = n_present == length(req)

    commands = Dict(
        "step1_reorder" => Dict(
            "lw" => "test/reorder_spectrum_lw.sh (pinned) with " *
                    "CKDMIP_DATA_DIR=$CKDMIP_ROOT, WORK_DIR=$WORKROOT/lw " *
                    "-- consumes MMM median present-day spectra, emits " *
                    "lw_order_<bandstruct>_<gas>.h5",
            "sw" => "test/reorder_spectrum_sw.sh analog for SW"),
        "step2_find_g_points" => Dict(
            "lw" => "test/find_g_points_lw.sh, BANDSTRUCT=fsck; 32-g TARGET " *
                    "TOLERANCE = 0.0161 (pinned do_all_lw.sh); optional " *
                    "0.061 only as 16-g sanity product",
            "sw" => "test/find_g_points_sw.sh, BANDSTRUCT=rgb; 32-g TARGET " *
                    "TOLERANCE = 0.047 (pinned do_all_sw.sh:43, " *
                    "TOLERANCE=\"0.16 0.047\"); optional 0.16 only as 16-g " *
                    "sanity product"),
        "future_outputs" => Dict(
            "lw" => "$WORKROOT/lw/lw_gpoints/ecckd-<VER>_lw_gpoints_" *
                    "climate_fsck-tol0.0161.h5 (A2 candidate; 32-g check " *
                    "gates it); optional ...tol0.061.h5 16-g sanity",
            "sw" => "$WORKROOT/sw/sw_gpoints/ecckd-<VER>_sw_gpoints_" *
                    "climate_rgb-tol0.047.h5 (A2 candidate); optional " *
                    "...tol0.16.h5 16-g sanity"),
        "runtime_estimate" => Dict(
            "basis" => "reorder + find_g_points stream the MMM spectra " *
                       "(median present-day) per band; idealized spectra " *
                       "are consumed later at the create_lut proof stage; " *
                       "LBL-scale IO-bound",
            "estimate" => "1-4 h per band per tolerance on cpu-large " *
                          "(60 GB, 16 cpu); tolerance loop multiplies -- " *
                          "run the published-matching tolerances first",
            "placement" => "Slurm cpu-large, never the head node"),
        "refusal" => "no execution from this manifest; the A2 runner unit " *
                     "must re-check inputs and carry the acceptance hinge " *
                     "gates before any invocation",
    )

    acceptance_hinge = Dict(
        "rule" => "rerun gpoints.h5 + raw create_lut output must EXACTLY " *
                  "reproduce the published gpoint_fraction and band support " *
                  "arrays (wavenumber1/2_band, band_number) AND the g-counts " *
                  "(32 LW fsck / 32 SW rgb) BEFORE any floor use",
        "if_not_exact" => "outputs are SENSITIVITY-ONLY; they cannot feed " *
                          "the acceptance floor unless Greg explicitly " *
                          "changes the optimizer-only-delta rule",
        "verification_targets" => "published LW32/SW32 definitions " *
                                  "(gate4_covariance_stride_audit rows; " *
                                  "gate4_gpoint_extraction_feasibility stats)",
    )

    gates["pinned_scripts_discovered"] = length(src) == 6 ? "passed" : "failed"
    gates["required_inputs_enumerated"] = length(req) >= 7 ? "passed" : "failed"
    gates["future_outputs_named"] = "passed"
    gates["acceptance_hinge_exact_reproduction"] =
        occursin("EXACTLY reproduce", acceptance_hinge["rule"]) ? "passed" : "failed"
    gates["unproven_reruns_sensitivity_only"] =
        occursin("SENSITIVITY-ONLY", acceptance_hinge["if_not_exact"]) ?
        "passed" : "failed"
    gates["runtime_estimate_recorded"] = "passed"
    gates["no_heavy_execution"] = "passed"
    self_src = read(@__FILE__, String)
    for tool in ("find_g_points ", "create_look_up_table ")
        occursin(Regex("run\\(`[^`]*" * strip(tool)), self_src) &&
            (gates["no_heavy_execution"] = "failed";
             push!(fails, "tool invocation found in manifest"))
    end

    status = !isempty(fails) ? "a2_manifest_failed" :
             inputs_ready ? "a2_manifest_ready" :
                            "a2_manifest_ready_waiting_for_inputs"

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_a2_find_g_points_rerun_manifest",
        "data_mode" => "dry_run_manifest_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "required_inputs" => req,
        "inputs_present" => n_present, "inputs_expected" => length(req),
        "commands" => commands,
        "acceptance_hinge" => acceptance_hinge,
        "evidence" => evidence,
        "provenance" => Dict("branch" => branch, "generated_from_head" => head,
            "pinned_source" => ECCKD_SRC,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "dry-run A2 manifest only; no find_g_points, " *
                        "create_lut, objective, floor, or recovery " *
                        "computation.",
    )
    mkpath(dirname(A2_RESULTS_JSON))
    open(A2_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(A2_RESULTS_MD, "w") do io
        println(io, "# Gate-4 A2 find_g_points rerun-with-proof manifest\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\n## Required inputs ($n_present/$(length(req)))\n")
        for r in req
            println(io, "- [$(r["present"] ? "present" : "MISSING")] " *
                        "$(r["label"]): `$(r["path"])`" *
                        (r["glob"] === nothing ? "" : " (glob: $(r["glob"]))"))
        end
        println(io, "\n## Acceptance hinge\n")
        println(io, acceptance_hinge["rule"])
        println(io, "\nIf not exact: ", acceptance_hinge["if_not_exact"])
        println(io, "\nRuntime estimate: ",
                commands["runtime_estimate"]["estimate"], " (",
                commands["runtime_estimate"]["placement"], ")")
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_a2_find_g_points_rerun_manifest: $status " *
            "($n_present/$(length(req)) inputs)")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return startswith(status, "a2_manifest_ready") ? 0 : 1
end

exit(main())
