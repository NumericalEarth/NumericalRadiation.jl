include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_boundary_table_pair_coordinate_scan.jl"))

const BOUNDARY_TABLE_COORDINATE_DESCENT_JSON =
    validation_results_path("reduced_ecckd_boundary_table_coordinate_descent.json")
const BOUNDARY_TABLE_COORDINATE_DESCENT_MD =
    validation_results_path("reduced_ecckd_boundary_table_coordinate_descent.md")

boundary_table_coordinate_descent_iterations() =
    parse(Int, get(ENV, "RH_BOUNDARY_TABLE_COORDINATE_DESCENT_ITERATIONS", "2"))

function retained_boundary_table_moves()
    return vcat(
        latest_boundary_base_constrained_table_optimizer_moves(),
        latest_boundary_table_coordinate_scan_moves(),
        latest_boundary_table_pair_coordinate_scan_moves(),
    )
end

function boundary_table_descent_model(full_model, accepted_moves = NamedTuple[])
    return current_constrained_table_model(
        full_model,
        vcat(retained_boundary_table_moves(), accepted_moves);
        base_mode = "boundary_weight_refit",
    )
end

function boundary_table_coordinate_descent_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    candidates = boundary_table_coordinate_candidates(full_model)
    accepted_moves = NamedTuple[]
    iterations = NamedTuple[]

    for iteration in 1:boundary_table_coordinate_descent_iterations()
        base_model = boundary_table_descent_model(full_model, accepted_moves)
        base_objective, base_cases = full_hard_objective(base_model)
        rows = NamedTuple[]
        for candidate in candidates
            for step in boundary_table_coordinate_steps()
                for direction in (-1.0, 1.0)
                    move = move_with_log_scale(candidate, direction * step)
                    trial_model = boundary_table_descent_model(
                        full_model,
                        vcat(accepted_moves, [move]),
                    )
                    objective, cases = full_hard_objective(trial_model)
                    push!(rows, (
                        move = move,
                        objective = objective,
                        improvement = base_objective - objective,
                        worst_toa_forcing_error_w_m2 =
                            maximum(case.toa_forcing_max_abs for case in cases),
                        worst_surface_forcing_error_w_m2 =
                            maximum(case.surface_forcing_max_abs for case in cases),
                    ))
                end
            end
        end
        isempty(rows) && error("no boundary-table descent candidates evaluated")
        best = argmin(row -> row.objective, rows)
        accepted = best.objective < base_objective
        push!(iterations, (
            iteration = iteration,
            base_objective = base_objective,
            best_objective = best.objective,
            best_objective_reduction = best.improvement,
            base_worst_toa_forcing_error_w_m2 =
                maximum(case.toa_forcing_max_abs for case in base_cases),
            base_worst_surface_forcing_error_w_m2 =
                maximum(case.surface_forcing_max_abs for case in base_cases),
            best_worst_toa_forcing_error_w_m2 =
                best.worst_toa_forcing_error_w_m2,
            best_worst_surface_forcing_error_w_m2 =
                best.worst_surface_forcing_error_w_m2,
            accepted = accepted,
            accepted_move = accepted ? best.move : nothing,
        ))
        accepted || break
        push!(accepted_moves, best.move)
    end

    final_model = boundary_table_descent_model(full_model, accepted_moves)
    final_objective, final_cases = full_hard_objective(final_model)
    baseline_model = boundary_table_descent_model(full_model)
    baseline_objective, baseline_cases = full_hard_objective(baseline_model)
    accepted = final_objective < baseline_objective
    return (
        case = "reduced_ecckd_boundary_table_coordinate_descent",
        status = accepted ? "coordinate_descent_improved" :
                 "coordinate_descent_rejected",
        base_mode = "boundary_weight_refit_plus_retained_boundary_table_moves",
        include_rayleigh = boundary_table_coordinate_include_rayleigh(),
        candidate_count = length(candidates),
        steps = boundary_table_coordinate_steps(),
        iteration_limit = boundary_table_coordinate_descent_iterations(),
        completed_iterations = length(iterations),
        baseline_objective = baseline_objective,
        baseline_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in baseline_cases),
        baseline_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in baseline_cases),
        final_objective = final_objective,
        final_objective_reduction = baseline_objective - final_objective,
        final_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in final_cases),
        final_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in final_cases),
        accepted = accepted,
        accepted_moves = accepted_moves,
        iterations = iterations,
    )
end

function boundary_table_coordinate_descent_markdown(result)
    lines = String[
        "# Reduced ecCKD Boundary-Table Coordinate Descent",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base mode | $(result.base_mode) |",
        "| Include Rayleigh candidates | $(result.include_rayleigh) |",
        "| Candidates | $(result.candidate_count) |",
        "| Iteration limit | $(result.iteration_limit) |",
        "| Completed iterations | $(result.completed_iterations) |",
        "| Baseline objective | $(@sprintf("%.12g", result.baseline_objective)) |",
        "| Final objective | $(@sprintf("%.12g", result.final_objective)) |",
        "| Final objective reduction | $(@sprintf("%.12g", result.final_objective_reduction)) |",
        "| Baseline TOA forcing error | $(@sprintf("%.12g", result.baseline_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Final TOA forcing error | $(@sprintf("%.12g", result.final_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Baseline surface forcing error | $(@sprintf("%.12g", result.baseline_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Final surface forcing error | $(@sprintf("%.12g", result.final_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Accepted | $(result.accepted) |",
        "",
        "This exact coordinate descent starts from the retained non-recursive",
        "boundary-table state, including accepted single and pair Rayleigh moves,",
        "then accumulates further single active-entry moves only when the full",
        "hard objective improves.",
    ]
    return join(lines, "\n") * "\n"
end

function main()
    result = boundary_table_coordinate_descent_result()
    mkpath(dirname(BOUNDARY_TABLE_COORDINATE_DESCENT_JSON))
    write(BOUNDARY_TABLE_COORDINATE_DESCENT_JSON, json_object(result) * "\n")
    write(BOUNDARY_TABLE_COORDINATE_DESCENT_MD,
          boundary_table_coordinate_descent_markdown(result))
    print(boundary_table_coordinate_descent_markdown(result))
    println("Wrote $BOUNDARY_TABLE_COORDINATE_DESCENT_JSON")
    println("Wrote $BOUNDARY_TABLE_COORDINATE_DESCENT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
