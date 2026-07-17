include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_gas_component_scale_refit.jl"))

const PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON =
    validation_results_path("reduced_ecckd_pressure_temperature_component_scale_refit.json")
const PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_MD =
    validation_results_path("reduced_ecckd_pressure_temperature_component_scale_refit.md")

pressure_temperature_component_pressure_bands() =
    parse(Int, get(ENV, "RH_REDUCED_PT_COMPONENT_PRESSURE_BANDS", "4"))

pressure_temperature_component_temperature_bands() =
    parse(Int, get(ENV, "RH_REDUCED_PT_COMPONENT_TEMPERATURE_BANDS", "4"))

pressure_temperature_component_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_PT_COMPONENT_ITERATIONS", "1"))

pressure_temperature_component_objective_mode() =
    get(ENV, "RH_REDUCED_PT_COMPONENT_OBJECTIVE", "full")

function pressure_temperature_component_steps()
    raw = get(ENV, "RH_REDUCED_PT_COMPONENT_STEPS",
              "0.00390625,0.0078125,0.015625,0.03125,0.0625")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function pressure_temperature_component_gpoints()
    raw = strip(get(ENV, "RH_REDUCED_PT_COMPONENT_GPOINTS", ""))
    if !isempty(raw)
        return sort(unique(parse(Int, strip(token)) for token in split(raw, ",")
                           if !isempty(strip(token))))
    end
    selected = Int[]
    append!(selected, [move.local_gpoint_index for move in latest_pressure_component_scale_refit_moves()])
    append!(selected, [move.local_gpoint_index for move in latest_temperature_component_scale_refit_moves()])
    append!(selected, [move.local_gpoint_index for move in latest_h2o_component_scale_refit_moves()])
    append!(selected, [move.local_gpoint_index for move in latest_gas_component_scale_refit_moves()])
    isempty(selected) && return sort(union(pressure_component_gpoints(), temperature_component_gpoints()))
    return sort(unique(selected))
end

function pressure_temperature_component_base_model(full_model)
    model = gas_component_base_model(full_model)
    apply_gas_component_moves!(model, latest_gas_component_scale_refit_moves())
    return model
end

function pressure_temperature_component_move(component, local_gpoint_index,
                                             pressure_range, temperature_range,
                                             log_scale)
    return (
        component = component,
        local_gpoint_index = local_gpoint_index,
        pressure_index_start = first(pressure_range),
        pressure_index_end = last(pressure_range),
        temperature_index_start = first(temperature_range),
        temperature_index_end = last(temperature_range),
        log_scale = log_scale,
        scale = exp(log_scale),
    )
end

function apply_pressure_temperature_component_move!(model, move)
    scale = exp(clamp(move.log_scale, -5.0, 5.0))
    ig = move.local_gpoint_index
    pressure_range = move.pressure_index_start:move.pressure_index_end
    temperature_range = move.temperature_index_start:move.temperature_index_end
    if move.component == "static_absorption"
        model.shortwave_absorption[ig, :, pressure_range, temperature_range] .*= scale
    elseif move.component == "h2o_absorption"
        if length(model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[ig, pressure_range, temperature_range, :] .*= scale
        end
    else
        throw(ArgumentError("unsupported pressure-temperature component $(move.component)"))
    end
    return model
end

function apply_pressure_temperature_component_moves!(model, moves)
    for move in moves
        apply_pressure_temperature_component_move!(model, move)
    end
    return model
end

function pressure_temperature_component_trial(full_model, moves)
    model = pressure_temperature_component_base_model(full_model)
    apply_pressure_temperature_component_moves!(model, moves)
    _, cases = full_hard_objective(model)
    objective = pressure_temperature_component_objective(cases)
    return objective, cases
end

function pressure_temperature_component_objective(cases)
    mode = pressure_temperature_component_objective_mode()
    if mode == "full"
        return maximum(normalized_case_objective, cases)
    elseif mode == "toa"
        return maximum(case.toa_forcing_max_abs for case in cases) /
               ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2
    elseif mode == "surface"
        return maximum(case.surface_forcing_max_abs for case in cases) /
               ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2
    elseif mode == "boundary"
        return max(
            maximum(case.toa_forcing_max_abs for case in cases) /
            ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
            maximum(case.surface_forcing_max_abs for case in cases) /
            ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
        )
    end
    throw(ArgumentError("unsupported pressure-temperature objective mode $mode"))
end

function pressure_temperature_component_candidates(full_model)
    pressure_ranges = pressure_bands(
        length(full_model.pressure_grid),
        pressure_temperature_component_pressure_bands(),
    )
    temperature_ranges = temperature_bands(
        size(full_model.shortwave_absorption, 4),
        pressure_temperature_component_temperature_bands(),
    )
    rows = NamedTuple[]
    for ig in pressure_temperature_component_gpoints()
        for component in ("static_absorption", "h2o_absorption")
            for pressure_range in pressure_ranges, temperature_range in temperature_ranges
                push!(rows, (
                    component = component,
                    local_gpoint_index = ig,
                    pressure_range = pressure_range,
                    temperature_range = temperature_range,
                ))
            end
        end
    end
    return rows
end

function pressure_temperature_component_scan(full_model, accepted_moves, base_objective)
    rows = NamedTuple[]
    for candidate in pressure_temperature_component_candidates(full_model)
        for step in pressure_temperature_component_steps(), direction in (-1.0, 1.0)
            move = pressure_temperature_component_move(
                candidate.component,
                candidate.local_gpoint_index,
                candidate.pressure_range,
                candidate.temperature_range,
                direction * step,
            )
            objective, cases = pressure_temperature_component_trial(
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
    best = argmin(row -> row.objective, rows)
    return rows, best
end

function pressure_temperature_component_scale_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    base_model = pressure_temperature_component_base_model(full_model)
    base_objective, base_cases = full_hard_objective(base_model)
    accepted_moves = NamedTuple[]
    iterations = NamedTuple[]
    current_objective = base_objective
    current_cases = base_cases

    for iteration in 1:pressure_temperature_component_iterations()
        rows, best = pressure_temperature_component_scan(
            full_model,
            accepted_moves,
            current_objective,
        )
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
        current_cases = pressure_temperature_component_trial(
            full_model,
            accepted_moves,
        )[2]
    end

    return (
        case = "reduced_ecckd_pressure_temperature_component_scale_refit",
        status = isempty(accepted_moves) ?
            "pressure_temperature_component_scale_refit_rejected" :
            "pressure_temperature_component_scale_refit_improved",
        base_mode = "gas_component_scale_refit",
        objective_mode = pressure_temperature_component_objective_mode(),
        pressure_band_count = pressure_temperature_component_pressure_bands(),
        temperature_band_count = pressure_temperature_component_temperature_bands(),
        selected_gpoints = pressure_temperature_component_gpoints(),
        steps = pressure_temperature_component_steps(),
        iteration_limit = pressure_temperature_component_iterations(),
        completed_iterations = length(iterations),
        candidate_count = length(pressure_temperature_component_candidates(full_model)),
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

function pressure_temperature_component_scale_refit_markdown(result)
    lines = String[
        "# Reduced ecCKD Pressure-Temperature Component Scale Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base mode | $(result.base_mode) |",
        "| Objective mode | $(result.objective_mode) |",
        "| Pressure bands | $(result.pressure_band_count) |",
        "| Temperature bands | $(result.temperature_band_count) |",
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
        "This diagnostic starts from the retained gas-component model and exact-coordinate",
        "scans coupled pressure-temperature block scales for static and H2O shortwave",
        "absorption on the g-points selected by the previous local refits.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ?
        pressure_temperature_component_scale_refit_result() : result
    mkpath(dirname(PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON))
    write(PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON,
          json_object(result) * "\n")
    write(PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_MD,
          pressure_temperature_component_scale_refit_markdown(result))
    print(pressure_temperature_component_scale_refit_markdown(result))
    println("Wrote $PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON")
    println("Wrote $PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
