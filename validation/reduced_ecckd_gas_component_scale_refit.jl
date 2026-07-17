include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_h2o_component_scale_refit.jl"))

const GAS_COMPONENT_SCALE_REFIT_JSON =
    validation_results_path("reduced_ecckd_gas_component_scale_refit.json")
const GAS_COMPONENT_SCALE_REFIT_MD =
    validation_results_path("reduced_ecckd_gas_component_scale_refit.md")

gas_component_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_GAS_COMPONENT_ITERATIONS", "1"))

function gas_component_steps()
    raw = get(ENV, "RH_REDUCED_GAS_COMPONENT_STEPS",
              "0.00390625,0.0078125,0.015625,0.03125,0.0625,0.125")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function gas_component_gpoints()
    raw = strip(get(ENV, "RH_REDUCED_GAS_COMPONENT_GPOINTS", ""))
    if !isempty(raw)
        return sort(unique(parse(Int, strip(token)) for token in split(raw, ",")
                           if !isempty(strip(token))))
    end
    moves = latest_component_scale_refit_moves()
    selected = sort(unique(move.local_gpoint_index for move in moves
                           if move.component == "static_absorption"))
    return isempty(selected) ? h2o_component_gpoints() : selected
end

function gas_component_base_model(full_model)
    model = h2o_component_base_model(full_model)
    apply_h2o_component_moves!(model, latest_h2o_component_scale_refit_moves())
    return model
end

function gas_component_move(local_gpoint_index, gas_index, gas_name, log_scale)
    return (
        component = "static_absorption",
        local_gpoint_index = local_gpoint_index,
        gas_index = gas_index,
        gas_name = String(gas_name),
        log_scale = log_scale,
        scale = exp(log_scale),
    )
end

function apply_gas_component_move!(model, move)
    scale = exp(clamp(move.log_scale, -5.0, 5.0))
    model.shortwave_absorption[move.local_gpoint_index, move.gas_index, :, :] .*= scale
    return model
end

function apply_gas_component_moves!(model, moves)
    for move in moves
        apply_gas_component_move!(model, move)
    end
    return model
end

function gas_component_trial(full_model, moves)
    model = gas_component_base_model(full_model)
    apply_gas_component_moves!(model, moves)
    objective, cases = full_hard_objective(model)
    return objective, cases
end

function gas_component_candidates(full_model)
    names = NumericalRadiation.gas_names(full_model)
    rows = NamedTuple[]
    for ig in gas_component_gpoints()
        for gas_index in eachindex(names)
            push!(rows, (
                local_gpoint_index = ig,
                gas_index = gas_index,
                gas_name = String(names[gas_index]),
            ))
        end
    end
    return rows
end

function gas_component_scan(full_model, accepted_moves, base_objective)
    rows = NamedTuple[]
    for candidate in gas_component_candidates(full_model)
        for step in gas_component_steps()
            for direction in (-1.0, 1.0)
                move = gas_component_move(
                    candidate.local_gpoint_index,
                    candidate.gas_index,
                    candidate.gas_name,
                    direction * step,
                )
                objective, cases = gas_component_trial(
                    full_model,
                    vcat(accepted_moves, [move]),
                )
                push!(rows, (
                    move = move,
                    objective = objective,
                    improvement = base_objective - objective,
                    worst_toa_forcing_error_w_m2 =
                        maximum(case.toa_forcing_max_abs for case in cases),
                    worst_surface_forcing_error_w_m2 =
                        maximum(case.surface_forcing_max_abs for case in cases),
                    accepted = objective < base_objective,
                ))
            end
        end
    end
    best = argmin(row -> row.objective, rows)
    return rows, best
end

function gas_component_scale_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    base_model = gas_component_base_model(full_model)
    base_objective, base_cases = full_hard_objective(base_model)
    accepted_moves = NamedTuple[]
    iterations = NamedTuple[]
    current_objective = base_objective
    current_cases = base_cases

    for iteration in 1:gas_component_iterations()
        rows, best = gas_component_scan(full_model, accepted_moves, current_objective)
        accepted = best.objective < current_objective
        push!(iterations, (
            iteration = iteration,
            trial_count = length(rows),
            base_objective = current_objective,
            best_objective = best.objective,
            best_objective_reduction = current_objective - best.objective,
            best_worst_toa_forcing_error_w_m2 =
                best.worst_toa_forcing_error_w_m2,
            best_worst_surface_forcing_error_w_m2 =
                best.worst_surface_forcing_error_w_m2,
            accepted = accepted,
            accepted_move = accepted ? best.move : nothing,
        ))
        accepted || break
        push!(accepted_moves, best.move)
        current_objective = best.objective
        current_cases = gas_component_trial(full_model, accepted_moves)[2]
    end

    return (
        case = "reduced_ecckd_gas_component_scale_refit",
        status = isempty(accepted_moves) ? "gas_component_scale_refit_rejected" :
                 "gas_component_scale_refit_improved",
        base_mode = "h2o_component_scale_refit",
        selected_gpoints = gas_component_gpoints(),
        steps = gas_component_steps(),
        iteration_limit = gas_component_iterations(),
        completed_iterations = length(iterations),
        candidate_count = length(gas_component_candidates(full_model)),
        base_objective = base_objective,
        final_objective = current_objective,
        objective_reduction = base_objective - current_objective,
        base_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in base_cases),
        base_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in base_cases),
        final_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in current_cases),
        final_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in current_cases),
        accepted = !isempty(accepted_moves),
        accepted_moves = accepted_moves,
        iterations = iterations,
    )
end

function gas_component_scale_refit_markdown(result)
    lines = String[
        "# Reduced ecCKD Gas-Component Scale Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base mode | $(result.base_mode) |",
        "| Selected g-points | $(join(result.selected_gpoints, ", ")) |",
        "| Candidate count | $(result.candidate_count) |",
        "| Iterations | $(result.completed_iterations) / $(result.iteration_limit) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Final objective | $(@sprintf("%.12g", result.final_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Base TOA forcing error | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Final TOA forcing error | $(@sprintf("%.12g", result.final_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing error | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Final surface forcing error | $(@sprintf("%.12g", result.final_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Accepted moves | $(length(result.accepted_moves)) |",
        "| Accepted | $(result.accepted) |",
        "",
        "This diagnostic starts from the retained H2O-component model and",
        "exact-coordinate scans nonnegative gas-specific static shortwave",
        "absorption scales on the g-points selected by whole-component refits.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? gas_component_scale_refit_result() : result
    mkpath(dirname(GAS_COMPONENT_SCALE_REFIT_JSON))
    write(GAS_COMPONENT_SCALE_REFIT_JSON, json_object(result) * "\n")
    write(GAS_COMPONENT_SCALE_REFIT_MD, gas_component_scale_refit_markdown(result))
    print(gas_component_scale_refit_markdown(result))
    println("Wrote $GAS_COMPONENT_SCALE_REFIT_JSON")
    println("Wrote $GAS_COMPONENT_SCALE_REFIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
