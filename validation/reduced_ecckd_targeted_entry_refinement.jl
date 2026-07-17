include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_optimization_preflight.jl"))

const TARGETED_ENTRY_JSON =
    validation_results_path("reduced_ecckd_targeted_entry_refinement.json")
const TARGETED_ENTRY_MD =
    validation_results_path("reduced_ecckd_targeted_entry_refinement.md")

function targeted_entry_candidate_limit()
    return parse(Int, get(ENV, "RH_REDUCED_TARGETED_ENTRY_CANDIDATES", "256"))
end

function targeted_entry_iterations()
    return parse(Int, get(ENV, "RH_REDUCED_TARGETED_ENTRY_ITERATIONS", "1"))
end

function targeted_entry_refinement_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    parameters = latest_preflight_reduced_parameters()
    parameters === nothing && error("reduced preflight parameters are required")
    pressure_moves = latest_preflight_pressure_band_table_moves()
    isempty(pressure_moves) && error("accepted pressure-band table moves are required")

    base_breakdown = final_objective_breakdown(full_model, parameters)
    pressure_refinement = (accepted_moves = pressure_moves,)
    pressure_objective = pressure_band_table_full_objective(
        full_model,
        parameters,
        pressure_moves,
    )
    refinement = active_table_entry_refinement(
        full_model,
        parameters,
        base_breakdown,
        pressure_refinement;
        max_candidates = targeted_entry_candidate_limit(),
        iterations = targeted_entry_iterations(),
    )

    return (
        case = "reduced_ecckd_targeted_entry_refinement",
        status = "preflight_ready",
        target_case = base_breakdown.worst_case,
        target_metric = base_breakdown.worst_metric,
        target_value = base_breakdown.worst_value,
        target_threshold = base_breakdown.worst_threshold,
        parameter_source = REDUCED_OPTIMIZATION_PREFLIGHT_JSON,
        pressure_move_count = length(pressure_moves),
        candidate_limit = targeted_entry_candidate_limit(),
        iterations_requested = targeted_entry_iterations(),
        pressure_refined_objective = pressure_objective,
        final_objective = refinement.final_objective,
        objective_reduction = refinement.objective_reduction,
        improved = refinement.improved,
        accepted_move_count = refinement.accepted_move_count,
        targeted_candidate_count = refinement.targeted_candidate_count,
        refinement = refinement,
    )
end

function targeted_entry_markdown(result)
    lines = String[
        "# Reduced ecCKD Targeted Entry Refinement",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Target case | $(result.target_case) |",
        "| Target metric | $(result.target_metric) |",
        "| Target value | $(@sprintf("%.12g", result.target_value)) |",
        "| Target threshold | $(@sprintf("%.12g", result.target_threshold)) |",
        "| Pressure move count | $(result.pressure_move_count) |",
        "| Targeted candidate count | $(result.targeted_candidate_count) |",
        "| Candidate limit | $(result.candidate_limit) |",
        "| Iterations requested | $(result.iterations_requested) |",
        "| Accepted move count | $(result.accepted_move_count) |",
        "| Pressure-refined objective | $(@sprintf("%.12g", result.pressure_refined_objective)) |",
        "| Final objective | $(@sprintf("%.12g", result.final_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Improved | $(result.improved) |",
        "",
        "This artifact is intentionally narrower than the main optimization preflight. It",
        "only evaluates table entries ranked by the current worst case's interpolation",
        "stencil and gas amounts, then applies the same full hard-objective acceptance",
        "rule as the main active table-entry refinement.",
    ]
    return join(lines, "\n") * "\n"
end

function write_targeted_entry_artifacts(result)
    mkpath(dirname(TARGETED_ENTRY_JSON))
    write(TARGETED_ENTRY_JSON, json_object(result) * "\n")
    write(TARGETED_ENTRY_MD, targeted_entry_markdown(result))
    print(targeted_entry_markdown(result))
    println("Wrote $TARGETED_ENTRY_JSON")
    println("Wrote $TARGETED_ENTRY_MD")
end

function main(; result = nothing)
    write_targeted_entry_artifacts(
        result === nothing ? targeted_entry_refinement_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
