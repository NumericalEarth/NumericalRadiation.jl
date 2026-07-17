include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_optimization_preflight.jl"))

const OFFICIAL_TRAINING_JSON = validation_results_path("official_ecckd_training.json")
const OFFICIAL_TRAINING_MD = validation_results_path("official_ecckd_training.md")

function official_training_status(preflight)
    improved = preflight.final_objective_target_ratio <
               preflight.initial_objective / preflight.objective_target
    checks_passed = preflight.enzyme_check.status == "passed" &&
                    preflight.reactant_check.status == "passed"
    recovered = preflight.final_objective_target_ratio <= 1.0
    return recovered && checks_passed ? "passed" :
           improved && checks_passed ? "partial" : "failed"
end

function official_training_report(preflight)
    status = official_training_status(preflight)
    initial_objective = preflight.initial_objective
    objective_target = preflight.objective_target
    final_objective = preflight.final_objective_target_ratio * objective_target
    objective_ratio = final_objective / objective_target
    optimization_chain = [
        "directional_search",
        "coordinate_coefficient_scan",
        "greedy_coordinate_descent",
        "coefficient_joint_direction_scan",
        "post_joint_coordinate_refinement",
        "post_coefficient_weight_refinement",
        "finite_difference_coefficient_direction_refinement",
        "smooth_objective_coefficient_refinement",
        "targeted_worst_metric_refinement",
        "separated_component_refinement",
        "warm_started_topology_neighbor_refinement",
        "ranked_topology_neighbor_refinement",
        "pressure_band_table_refinement",
        "active_table_entry_refinement",
    ]
    return (
        case = "official_reduced_ecckd_gas_optics_training",
        timestamp_utc = string(Dates.now()),
        status = status,
        reference_scope = preflight.reference_scope,
        training_source = "official ecCKD tabulated gas-optics reduced hard-gate objective",
        parameterization = preflight.parameterization,
        parameter_count = preflight.parameter_count,
        ng_sw = preflight.ng_sw,
        optimizer = "deterministic multi-stage reduced ecCKD optimizer chain",
        optimization_chain = optimization_chain,
        iterations =
            preflight.directional_search.iterations +
            preflight.greedy_coordinate_descent.iterations_completed +
            preflight.post_joint_coordinate_refinement.iterations_completed +
            preflight.post_coefficient_weight_refinement.iterations_completed +
            preflight.pressure_band_table_refinement.iterations_completed +
            preflight.active_table_entry_refinement.iterations_completed,
        initial_objective = initial_objective,
        final_objective = final_objective,
        objective_reduction = initial_objective - final_objective,
        objective_ratio = final_objective / initial_objective,
        objective_target = objective_target,
        final_objective_target_ratio = objective_ratio,
        hard_accuracy_target_met = final_objective <= objective_target,
        recovery_status =
            final_objective <= objective_target ? "published_model_recovered" :
            "optimizer_improved_but_target_not_met",
        acceptance_gap_status = preflight.acceptance_gap_status,
        loss_history = [
            initial_objective,
            preflight.directional_search.final_objective,
            preflight.coordinate_coefficient_scan.best_objective,
            preflight.greedy_coordinate_descent.final_objective,
            preflight.coefficient_joint_direction_scan.best_objective,
            preflight.post_joint_coordinate_refinement.final_objective,
            preflight.post_coefficient_weight_refinement.final_objective,
            preflight.pressure_band_table_refinement.final_objective,
            preflight.active_table_entry_refinement.final_objective,
            final_objective,
        ],
        reactant_check = preflight.reactant_check,
        enzyme_check = preflight.enzyme_check,
        topology_candidate_scan = preflight.topology_candidate_scan,
        next_required_work = preflight.next_required_work,
        notes = "This is the official/reduced ecCKD training-path artifact: it demonstrates objective construction, trainable parameters, Reactant/Enzyme checks, and deterministic objective reduction on official ecCKD references. Status is partial until final_objective_target_ratio <= 1 and a published model is recovered quantitatively.",
    )
end

function markdown_report(result)
    lines = String[
        "# Official/Reduced ecCKD Gas-Optics Training",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Trainable shortwave g-points | $(result.ng_sw) |",
        "| Parameter count | $(result.parameter_count) |",
        "| Iterations | $(result.iterations) |",
        "| Initial objective | $(@sprintf("%.12g", result.initial_objective)) |",
        "| Final objective | $(@sprintf("%.12g", result.final_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Final objective / initial objective | $(@sprintf("%.12g", result.objective_ratio)) |",
        "| Final objective / hard target | $(@sprintf("%.12g", result.final_objective_target_ratio)) |",
        "| Hard accuracy target met | $(result.hard_accuracy_target_met) |",
        "| Recovery status | $(result.recovery_status) |",
        "| Reactant check | $(result.reactant_check.status) |",
        "| Enzyme check | $(result.enzyme_check.status) |",
        "",
        result.notes,
        "",
        "Next required work: $(result.next_required_work)",
    ]
    return join(lines, "\n") * "\n"
end

function main()
    preflight = reduced_optimization_preflight()
    result = official_training_report(preflight)
    mkpath(dirname(OFFICIAL_TRAINING_JSON))
    write(OFFICIAL_TRAINING_JSON, json_object(result) * "\n")
    write(OFFICIAL_TRAINING_MD, markdown_report(result))
    print(markdown_report(result))
    println("Wrote $OFFICIAL_TRAINING_JSON")
    println("Wrote $OFFICIAL_TRAINING_MD")
    result.status != "failed" || error("official/reduced ecCKD training failed")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
