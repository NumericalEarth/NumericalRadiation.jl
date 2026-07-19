# Gate-4 g-point EXTRACTION FEASIBILITY finding (negative result, proven).
#
# Question: can the gpoints.h5 required by create_look_up_table be extracted
# from the published CKD definitions via argmax over gpoint_fraction?
# ANSWER: NO. gpoint_fraction in the published targets is a FRACTIONAL
# overlap/projection on the coarse definition wavenumber grid (LW 326 bins,
# SW 995 bins), not a one-hot wavenumber-to-g assignment; create_look_up_table
# requires the real per-wavenumber g_point vector
# (create_look_up_table.cpp: input_file.read(g_point, "g_point"), ~line 89).
# An argmax would INVENT a mapping and is scientifically invalid.
#
# This unit PROVES the fractional structure from the files and records the
# policy amendment. No extraction, generation, optimization, objective,
# floor, or recovery computation.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON
import NCDatasets

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))
using NumericalRadiation

const GF_RESULTS_JSON = validation_results_path("gate4_gpoint_extraction_feasibility.json")
const GF_RESULTS_MD = validation_results_path("gate4_gpoint_extraction_feasibility.md")

function fraction_stats(path)
    local A, varnames
    NCDatasets.NCDataset(path) do ds
        A = Float64.(Array(ds["gpoint_fraction"]))
        varnames = sort(collect(keys(ds)))
    end
    frac = count(x -> 0 < x < 1, A)
    ones_ = count(x -> x == 1, A)
    return Dict{String, Any}(
        "size" => collect(size(A)),
        "max" => maximum(A),
        "positive_fractional_entries" => frac,
        "exact_one_entries" => ones_,
        "min_colsum" => minimum(sum(A; dims = 1)),
        "max_colsum" => maximum(sum(A; dims = 1)),
        "min_rowsum" => minimum(sum(A; dims = 2)),
        "max_rowsum" => maximum(sum(A; dims = 2)),
        "one_hot" => frac == 0,
        "variable_inventory" => varnames,
        "has_g_point_variable" => "g_point" in varnames,
    )
end

function main()
    fails = String[]
    gates = Dict{String, String}()

    lw32 = NumericalRadiation.official_ecckd_definition_path(:longwave_32)
    sw32 = NumericalRadiation.official_ecckd_definition_path(:shortwave_32)
    stats = Dict("lw32" => fraction_stats(lw32), "sw32" => fraction_stats(sw32))

    # Gate: fractional structure proven (NOT one-hot) in both targets
    both_fractional = !stats["lw32"]["one_hot"] && !stats["sw32"]["one_hot"]
    gates["gpoint_fraction_is_fractional"] = both_fractional ? "passed" : "failed"
    both_fractional ||
        push!(fails, "expected fractional gpoint_fraction; found one-hot -- " *
                     "the argmax question must be re-opened, do not proceed " *
                     "on this artifact")

    # Gate: upstream requires the real g_point vector (source anchor)
    src = read("/shared/home/greg/.julia/artifacts/" *
               "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
               "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd/" *
               "src/ecckd/create_look_up_table.cpp", String)
    anchor = occursin("read(g_point, \"g_point\")", src)
    gates["create_lut_requires_g_point_vector"] = anchor ? "passed" : "failed"
    anchor || push!(fails, "g_point read anchor not found in create_look_up_table.cpp")

    # Gate: published definitions carry NO standalone g_point variable --
    # independent second proof that the required high-resolution assignment
    # vector is absent (they hold support/projection arrays only)
    no_gp = !stats["lw32"]["has_g_point_variable"] &&
            !stats["sw32"]["has_g_point_variable"]
    gates["no_g_point_variable_in_published"] = no_gp ? "passed" : "failed"
    no_gp || push!(fails, "unexpected g_point variable found in a published " *
                          "definition -- re-open the extraction question")

    gates["argmax_extraction_ruled_out"] =
        both_fractional && anchor && no_gp ? "passed" : "failed"
    gates["no_computation_beyond_file_stats"] = "passed"

    policy_amendment = Dict(
        "supersedes" => "gate4_gpoint_provenance_policy.json path_a extraction " *
            "METHOD (the path-A goal of structural identity stands; the " *
            "argmax-from-gpoint_fraction mechanism is INVALID)",
        "remaining_options" => [
            Dict("option" => "A1_locate_original_find_g_points_outputs",
                 "detail" => "search upstream releases/ECPDS for the released " *
                     "find_g_points HDF5 files matching the published models; " *
                     "provenance-verified download if found"),
            Dict("option" => "A2_rerun_find_g_points_as_fixed_input_reconstruction",
                 "detail" => "run the pinned find_g_points from idealized " *
                     "spectra as PROBLEM-DEFINITION reconstruction (a " *
                     "non-optimizer stage); acceptance use requires " *
                     "verifying the reconstructed structure reproduces the " *
                     "published gpoint_fraction and band arrays -- if it " *
                     "does not match exactly, it CANNOT feed the acceptance " *
                     "floor without an explicit rule change from Greg"),
            Dict("option" => "A3_alternative_init_source",
                 "detail" => "avoid create_lut regeneration entirely if " *
                     "raw/scaled init definitions are available from the " *
                     "upstream release history"),
        ],
    )

    status = isempty(fails) ? "extraction_infeasibility_proven" :
                              "feasibility_check_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_gpoint_extraction_feasibility",
        "data_mode" => "published_file_statistics_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "gpoint_fraction_stats" => stats,
        "finding" => "published definitions contain NO standalone g_point " *
            "variable (inventory recorded), and " *
            "gpoint_fraction is a fractional overlap/projection on " *
            "the coarse definition grid, not a one-hot assignment; the real " *
            "per-wavenumber g_point vector required by create_look_up_table " *
            "cannot be recovered from it; argmax extraction is invalid",
        "policy_amendment" => policy_amendment,
        "provenance" => Dict("branch" => branch, "generated_from_head" => head,
            "files" => [basename(lw32), basename(sw32)],
            "source_anchor" => "create_look_up_table.cpp: " *
                "input_file.read(g_point, \"g_point\")",
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "feasibility finding only; no extraction, generation, " *
                        "optimization, objective, floor, or recovery " *
                        "computation.",
    )
    mkpath(dirname(GF_RESULTS_JSON))
    open(GF_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(GF_RESULTS_MD, "w") do io
        println(io, "# Gate-4 g-point extraction feasibility (negative result)\n")
        println(io, "Status: **$status**\n")
        println(io, result["finding"], "\n")
        println(io, "| Target | size | max | fractional entries | colsum range |")
        println(io, "|---|---|---|---|---|")
        for k in ("lw32", "sw32")
            st = stats[k]
            println(io, "| $k | $(st["size"]) | $(st["max"]) | " *
                        "$(st["positive_fractional_entries"]) | " *
                        "[$(st["min_colsum"]), $(st["max_colsum"])] |")
        end
        println(io, "\n| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nRemaining options: A1 locate released find_g_points " *
                    "outputs; A2 rerun find_g_points as fixed-input " *
                    "problem-definition reconstruction (acceptance only if " *
                    "the reconstructed structure exactly reproduces the " *
                    "published gpoint_fraction/band arrays, else requires an " *
                    "explicit rule change); A3 alternative init source from " *
                    "upstream release history.")
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_gpoint_extraction_feasibility: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "extraction_infeasibility_proven" ? 0 : 1
end

exit(main())
