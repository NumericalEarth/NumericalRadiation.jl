include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_optimization_preflight.jl"))

const PRESSURE_BAND_JSON =
    validation_results_path("reduced_ecckd_pressure_band_refinement_preflight.json")
const PRESSURE_BAND_MD =
    validation_results_path("reduced_ecckd_pressure_band_refinement_preflight.md")

function final_parameters_from_section(section_key; path = PREFLIGHT_JSON)
    isfile(path) || return nothing
    section = json_object_section(read(path, String), section_key)
    section == "" && return nothing
    match = Base.match(r"\"final_parameters\"\s*:\s*\[([^\]]+)\]", section)
    match === nothing && return nothing
    values = parse.(Float64, split(match.captures[1], ","))
    length(values) == 3length(WEIGHTED_GREEDY_SW_16_INDICES) || return nothing
    return values
end

function current_reduced_parameters()
    for section in (
            "post_joint_coordinate_refinement",
            "coefficient_joint_direction_scan",
            "greedy_coordinate_descent",
        )
        parameters = final_parameters_from_section(section)
        parameters === nothing || return parameters
    end
    return initial_parameters()
end

function pressure_bands(npressure, nband)
    edges = round.(Int, range(1, npressure + 1; length = nband + 1))
    return [edges[i]:(edges[i + 1] - 1) for i in 1:nband]
end

function pressure_band_scaled_model(full_model, parameters, band, log_scale)
    model = reduced_model_from_parameters(full_model, parameters)
    scale = exp(clamp(log_scale, -5.0, 5.0))
    model.shortwave_absorption[:, :, band, :] .*= scale
    if length(model.shortwave_h2o_absorption) != 0
        model.shortwave_h2o_absorption[:, band, :, :] .*= scale
    end
    return model
end

function gpoint_pressure_band_scaled_model(full_model, parameters, ig, band, log_scale)
    model = reduced_model_from_parameters(full_model, parameters)
    scale = exp(clamp(log_scale, -5.0, 5.0))
    model.shortwave_absorption[ig, :, band, :] .*= scale
    if length(model.shortwave_h2o_absorption) != 0
        model.shortwave_h2o_absorption[ig, band, :, :] .*= scale
    end
    return model
end

function apply_gpoint_pressure_band_move!(model, move)
    scale = exp(clamp(move.log_scale, -5.0, 5.0))
    band = move.pressure_index_start:move.pressure_index_end
    ig = move.local_gpoint_index
    model.shortwave_absorption[ig, :, band, :] .*= scale
    if length(model.shortwave_h2o_absorption) != 0
        model.shortwave_h2o_absorption[ig, band, :, :] .*= scale
    end
    return model
end

function apply_component_gpoint_pressure_band_move!(model, move)
    scale = exp(clamp(move.log_scale, -5.0, 5.0))
    band = move.pressure_index_start:move.pressure_index_end
    ig = move.local_gpoint_index
    if move.component == "static_absorption"
        model.shortwave_absorption[ig, :, band, :] .*= scale
    elseif move.component == "dynamic_h2o"
        if length(model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[ig, band, :, :] .*= scale
        end
    else
        throw(ArgumentError("unsupported pressure-band component $(move.component)"))
    end
    return model
end

function gpoint_pressure_band_moved_model(full_model, parameters, moves)
    model = reduced_model_from_parameters(full_model, parameters)
    for move in moves
        apply_gpoint_pressure_band_move!(model, move)
    end
    return model
end

function component_gpoint_pressure_band_moved_model(full_model, parameters, moves)
    model = reduced_model_from_parameters(full_model, parameters)
    for move in moves
        apply_component_gpoint_pressure_band_move!(model, move)
    end
    return model
end

function pressure_band_full_objective(full_model, parameters, band, log_scale)
    model = pressure_band_scaled_model(full_model, parameters, band, log_scale)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return maximum(normalized_case_objective, cases)
end

function pressure_band_metric_objective(full_model, parameters, band, log_scale,
                                        case_name, metric)
    model = pressure_band_scaled_model(full_model, parameters, band, log_scale)
    case = case_metrics(reduced_case_by_name(case_name), model)
    return normalized_metric_value(case, metric)
end

function gpoint_pressure_band_full_objective(full_model, parameters, ig, band, log_scale)
    model = gpoint_pressure_band_scaled_model(full_model, parameters, ig, band, log_scale)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return maximum(normalized_case_objective, cases)
end

function gpoint_pressure_band_metric_objective(full_model, parameters, ig, band,
                                              log_scale, case_name, metric)
    model = gpoint_pressure_band_scaled_model(full_model, parameters, ig, band, log_scale)
    case = case_metrics(reduced_case_by_name(case_name), model)
    return normalized_metric_value(case, metric)
end

function moved_model_full_objective(full_model, parameters, moves)
    model = gpoint_pressure_band_moved_model(full_model, parameters, moves)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return maximum(normalized_case_objective, cases)
end

function moved_model_metric_objective(full_model, parameters, moves, case_name, metric)
    model = gpoint_pressure_band_moved_model(full_model, parameters, moves)
    case = case_metrics(reduced_case_by_name(case_name), model)
    return normalized_metric_value(case, metric)
end

function component_moved_model_full_objective(full_model, parameters, moves)
    model = component_gpoint_pressure_band_moved_model(full_model, parameters, moves)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return maximum(normalized_case_objective, cases)
end

function component_moved_model_metric_objective(full_model, parameters, moves,
                                                case_name, metric)
    model = component_gpoint_pressure_band_moved_model(full_model, parameters, moves)
    case = case_metrics(reduced_case_by_name(case_name), model)
    return normalized_metric_value(case, metric)
end

function pressure_band_refinement_scan(full_model, parameters, breakdown;
                                       nband = 4,
                                       steps = (0.125, 0.25))
    bands = pressure_bands(length(full_model.pressure_grid), nband)
    base_full_objective = reduced_objective(full_model, parameters)
    base_metric_objective = targeted_metric_objective(
        full_model,
        parameters,
        breakdown.worst_case,
        breakdown.worst_metric,
    )
    rows = NamedTuple[]
    for (iband, band) in enumerate(bands)
        for step in steps
            for direction in (-1.0, 1.0)
                candidate_log_scale = direction * step
                metric_objective = pressure_band_metric_objective(
                    full_model,
                    parameters,
                    band,
                    candidate_log_scale,
                    breakdown.worst_case,
                    breakdown.worst_metric,
                )
                full_objective = pressure_band_full_objective(
                    full_model,
                    parameters,
                    band,
                    candidate_log_scale,
                )
                push!(rows, (
                    band = iband,
                    pressure_index_start = first(band),
                    pressure_index_end = last(band),
                    log_scale = candidate_log_scale,
                    scale = exp(candidate_log_scale),
                    metric_objective = metric_objective,
                    metric_improvement = base_metric_objective - metric_objective,
                    full_objective = full_objective,
                    full_improvement = base_full_objective - full_objective,
                    accepted = full_objective < base_full_objective,
                ))
            end
        end
    end
    best_metric = argmin(row -> row.metric_objective, rows)
    best_full = argmin(row -> row.full_objective, rows)
    return (
        method = "single pressure-band nonnegative shortwave coefficient-table scale scan",
        base_full_objective = base_full_objective,
        base_metric_objective = base_metric_objective,
        target_case = breakdown.worst_case,
        target_metric = breakdown.worst_metric,
        band_count = length(bands),
        candidate_count = length(rows),
        best_metric_candidate = best_metric,
        best_full_candidate = best_full,
        accepted = best_full.full_objective < base_full_objective,
        rows = rows,
    )
end

function iterative_gpoint_pressure_band_iterations()
    return parse(Int, get(ENV, "RH_REDUCED_GPOINT_PRESSURE_BAND_ITERATIONS", "2"))
end

function iterative_gpoint_pressure_band_refinement(full_model, parameters, breakdown;
                                                   nband = 4,
                                                   steps = (0.125, 0.25),
                                                   max_candidates =
                                                    gpoint_pressure_band_candidate_limit(),
                                                   iterations =
                                                    iterative_gpoint_pressure_band_iterations())
    bands = pressure_bands(length(full_model.pressure_grid), nband)
    moves = NamedTuple[]
    initial_full_objective = moved_model_full_objective(full_model, parameters, moves)
    current_full_objective = initial_full_objective
    trajectory = NamedTuple[]

    for iteration in 1:iterations
        current_metric_objective = moved_model_metric_objective(
            full_model,
            parameters,
            moves,
            breakdown.worst_case,
            breakdown.worst_metric,
        )
        rows = NamedTuple[]
        candidate_count = 0
        stop = false
        for ig in eachindex(WEIGHTED_GREEDY_SW_16_INDICES)
            for (iband, band) in enumerate(bands)
                for step in steps
                    for direction in (-1.0, 1.0)
                        move = (
                            local_gpoint_index = ig,
                            gpoint = WEIGHTED_GREEDY_SW_16_INDICES[ig],
                            band = iband,
                            pressure_index_start = first(band),
                            pressure_index_end = last(band),
                            log_scale = direction * step,
                            scale = exp(direction * step),
                        )
                        candidate_moves = vcat(moves, [move])
                        metric_objective = moved_model_metric_objective(
                            full_model,
                            parameters,
                            candidate_moves,
                            breakdown.worst_case,
                            breakdown.worst_metric,
                        )
                        full_objective = moved_model_full_objective(
                            full_model,
                            parameters,
                            candidate_moves,
                        )
                        push!(rows, (
                            move...,
                            metric_objective = metric_objective,
                            metric_improvement =
                                current_metric_objective - metric_objective,
                            full_objective = full_objective,
                            full_improvement =
                                current_full_objective - full_objective,
                            accepted = full_objective < current_full_objective,
                        ))
                        candidate_count += 1
                        if candidate_count >= max_candidates
                            stop = true
                            break
                        end
                    end
                    stop && break
                end
                stop && break
            end
            stop && break
        end
        best_full = argmin(row -> row.full_objective, rows)
        accepted = best_full.full_objective < current_full_objective
        push!(trajectory, (
            iteration = iteration,
            candidate_count = length(rows),
            initial_full_objective = current_full_objective,
            best_full_objective = best_full.full_objective,
            best_metric_objective = minimum(row -> row.metric_objective, rows),
            accepted = accepted,
            accepted_move = accepted ? (
                local_gpoint_index = best_full.local_gpoint_index,
                gpoint = best_full.gpoint,
                band = best_full.band,
                pressure_index_start = best_full.pressure_index_start,
                pressure_index_end = best_full.pressure_index_end,
                log_scale = best_full.log_scale,
                scale = best_full.scale,
            ) : nothing,
        ))
        accepted || break
        push!(moves, trajectory[end].accepted_move)
        current_full_objective = best_full.full_objective
    end

    return (
        method = "iterative per-g-point pressure-band nonnegative table scaling",
        iterations_requested = iterations,
        iterations_completed = length(trajectory),
        initial_full_objective = initial_full_objective,
        final_full_objective = current_full_objective,
        objective_reduction = initial_full_objective - current_full_objective,
        improved = current_full_objective < initial_full_objective,
        accepted_move_count = length(moves),
        accepted_moves = moves,
        trajectory = trajectory,
    )
end

function gpoint_pressure_band_candidate_limit()
    return parse(Int, get(ENV, "RH_REDUCED_GPOINT_PRESSURE_BAND_CANDIDATES", "64"))
end

function component_pressure_band_candidate_limit()
    return parse(Int, get(ENV, "RH_REDUCED_COMPONENT_PRESSURE_BAND_CANDIDATES", "64"))
end

function active_table_entry_candidate_limit()
    return parse(Int, get(ENV, "RH_REDUCED_ACTIVE_TABLE_ENTRY_CANDIDATES", "64"))
end

function apply_active_table_entry_move!(model, move)
    scale = exp(clamp(move.log_scale, -5.0, 5.0))
    ig = move.local_gpoint_index
    if move.component == "static_absorption"
        model.shortwave_absorption[
            ig,
            move.gas_index,
            move.pressure_index,
            move.temperature_index,
        ] *= scale
    elseif move.component == "dynamic_h2o"
        if length(model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[
                ig,
                move.pressure_index,
                move.temperature_index,
                move.h2o_index,
            ] *= scale
        end
    else
        throw(ArgumentError("unsupported active table-entry component $(move.component)"))
    end
    return model
end

function active_table_entry_moved_model(full_model, parameters, moves)
    model = reduced_model_from_parameters(full_model, parameters)
    for move in moves
        apply_active_table_entry_move!(model, move)
    end
    return model
end

function active_table_entry_full_objective(full_model, parameters, moves)
    model = active_table_entry_moved_model(full_model, parameters, moves)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return maximum(normalized_case_objective, cases)
end

function active_table_entry_metric_objective(full_model, parameters, moves,
                                             case_name, metric)
    model = active_table_entry_moved_model(full_model, parameters, moves)
    case = case_metrics(reduced_case_by_name(case_name), model)
    return normalized_metric_value(case, metric)
end

function gpoint_pressure_band_refinement_scan(full_model, parameters, breakdown;
                                              nband = 4,
                                              steps = (0.125, 0.25),
                                              max_candidates =
                                                gpoint_pressure_band_candidate_limit())
    bands = pressure_bands(length(full_model.pressure_grid), nband)
    base_full_objective = reduced_objective(full_model, parameters)
    base_metric_objective = targeted_metric_objective(
        full_model,
        parameters,
        breakdown.worst_case,
        breakdown.worst_metric,
    )
    rows = NamedTuple[]
    candidate_count = 0
    stop = false
    for ig in eachindex(WEIGHTED_GREEDY_SW_16_INDICES)
        for (iband, band) in enumerate(bands)
            for step in steps
                for direction in (-1.0, 1.0)
                    candidate_log_scale = direction * step
                    metric_objective = gpoint_pressure_band_metric_objective(
                        full_model,
                        parameters,
                        ig,
                        band,
                        candidate_log_scale,
                        breakdown.worst_case,
                        breakdown.worst_metric,
                    )
                    full_objective = gpoint_pressure_band_full_objective(
                        full_model,
                        parameters,
                        ig,
                        band,
                        candidate_log_scale,
                    )
                    push!(rows, (
                        local_gpoint_index = ig,
                        gpoint = WEIGHTED_GREEDY_SW_16_INDICES[ig],
                        band = iband,
                        pressure_index_start = first(band),
                        pressure_index_end = last(band),
                        log_scale = candidate_log_scale,
                        scale = exp(candidate_log_scale),
                        metric_objective = metric_objective,
                        metric_improvement = base_metric_objective - metric_objective,
                        full_objective = full_objective,
                        full_improvement = base_full_objective - full_objective,
                        accepted = full_objective < base_full_objective,
                    ))
                    candidate_count += 1
                    if candidate_count >= max_candidates
                        stop = true
                        break
                    end
                end
                stop && break
            end
            stop && break
        end
        stop && break
    end
    best_metric = argmin(row -> row.metric_objective, rows)
    best_full = argmin(row -> row.full_objective, rows)
    return (
        method = "per-g-point pressure-band nonnegative shortwave coefficient-table scale scan",
        base_full_objective = base_full_objective,
        base_metric_objective = base_metric_objective,
        target_case = breakdown.worst_case,
        target_metric = breakdown.worst_metric,
        band_count = length(bands),
        candidate_count = length(rows),
        max_candidates = max_candidates,
        best_metric_candidate = best_metric,
        best_full_candidate = best_full,
        accepted = best_full.full_objective < base_full_objective,
        rows = rows,
    )
end

function component_gpoint_pressure_band_refinement_scan(full_model, parameters, breakdown;
                                                        nband = 4,
                                                        steps = (0.125, 0.25),
                                                        max_candidates =
                                                            component_pressure_band_candidate_limit())
    bands = pressure_bands(length(full_model.pressure_grid), nband)
    base_full_objective = reduced_objective(full_model, parameters)
    base_metric_objective = targeted_metric_objective(
        full_model,
        parameters,
        breakdown.worst_case,
        breakdown.worst_metric,
    )
    rows = NamedTuple[]
    candidate_count = 0
    stop = false
    for component in ("static_absorption", "dynamic_h2o")
        for ig in eachindex(WEIGHTED_GREEDY_SW_16_INDICES)
            for (iband, band) in enumerate(bands)
                for step in steps
                    for direction in (-1.0, 1.0)
                        move = (
                            component = component,
                            local_gpoint_index = ig,
                            gpoint = WEIGHTED_GREEDY_SW_16_INDICES[ig],
                            band = iband,
                            pressure_index_start = first(band),
                            pressure_index_end = last(band),
                            log_scale = direction * step,
                            scale = exp(direction * step),
                        )
                        moves = (move,)
                        metric_objective = component_moved_model_metric_objective(
                            full_model,
                            parameters,
                            moves,
                            breakdown.worst_case,
                            breakdown.worst_metric,
                        )
                        full_objective = component_moved_model_full_objective(
                            full_model,
                            parameters,
                            moves,
                        )
                        push!(rows, (
                            move...,
                            metric_objective = metric_objective,
                            metric_improvement =
                                base_metric_objective - metric_objective,
                            full_objective = full_objective,
                            full_improvement =
                                base_full_objective - full_objective,
                            accepted = full_objective < base_full_objective,
                        ))
                        candidate_count += 1
                        if candidate_count >= max_candidates
                            stop = true
                            break
                        end
                    end
                    stop && break
                end
                stop && break
            end
            stop && break
        end
        stop && break
    end
    best_metric = argmin(row -> row.metric_objective, rows)
    best_full = argmin(row -> row.full_objective, rows)
    return (
        method = "component-separated per-g-point pressure-band table scaling",
        base_full_objective = base_full_objective,
        base_metric_objective = base_metric_objective,
        target_case = breakdown.worst_case,
        target_metric = breakdown.worst_metric,
        band_count = length(bands),
        candidate_count = length(rows),
        max_candidates = max_candidates,
        best_metric_candidate = best_metric,
        best_full_candidate = best_full,
        accepted = best_full.full_objective < base_full_objective,
        rows = rows,
    )
end

function iterative_component_gpoint_pressure_band_iterations()
    return parse(Int, get(ENV, "RH_REDUCED_COMPONENT_PRESSURE_BAND_ITERATIONS", "2"))
end

function iterative_component_gpoint_pressure_band_refinement(full_model, parameters,
                                                             breakdown;
                                                             nband = 4,
                                                             steps = (0.125, 0.25),
                                                             max_candidates =
                                                                component_pressure_band_candidate_limit(),
                                                             iterations =
                                                                iterative_component_gpoint_pressure_band_iterations())
    bands = pressure_bands(length(full_model.pressure_grid), nband)
    moves = NamedTuple[]
    initial_full_objective =
        component_moved_model_full_objective(full_model, parameters, moves)
    current_full_objective = initial_full_objective
    trajectory = NamedTuple[]

    for iteration in 1:iterations
        current_metric_objective = component_moved_model_metric_objective(
            full_model,
            parameters,
            moves,
            breakdown.worst_case,
            breakdown.worst_metric,
        )
        rows = NamedTuple[]
        candidate_count = 0
        stop = false
        for component in ("static_absorption", "dynamic_h2o")
            for ig in eachindex(WEIGHTED_GREEDY_SW_16_INDICES)
                for (iband, band) in enumerate(bands)
                    for step in steps
                        for direction in (-1.0, 1.0)
                            move = (
                                component = component,
                                local_gpoint_index = ig,
                                gpoint = WEIGHTED_GREEDY_SW_16_INDICES[ig],
                                band = iband,
                                pressure_index_start = first(band),
                                pressure_index_end = last(band),
                                log_scale = direction * step,
                                scale = exp(direction * step),
                            )
                            candidate_moves = vcat(moves, [move])
                            metric_objective =
                                component_moved_model_metric_objective(
                                    full_model,
                                    parameters,
                                    candidate_moves,
                                    breakdown.worst_case,
                                    breakdown.worst_metric,
                                )
                            full_objective = component_moved_model_full_objective(
                                full_model,
                                parameters,
                                candidate_moves,
                            )
                            push!(rows, (
                                move...,
                                metric_objective = metric_objective,
                                metric_improvement =
                                    current_metric_objective - metric_objective,
                                full_objective = full_objective,
                                full_improvement =
                                    current_full_objective - full_objective,
                                accepted = full_objective < current_full_objective,
                            ))
                            candidate_count += 1
                            if candidate_count >= max_candidates
                                stop = true
                                break
                            end
                        end
                        stop && break
                    end
                    stop && break
                end
                stop && break
            end
            stop && break
        end
        best_full = argmin(row -> row.full_objective, rows)
        accepted = best_full.full_objective < current_full_objective
        accepted_move = accepted ? (
            component = best_full.component,
            local_gpoint_index = best_full.local_gpoint_index,
            gpoint = best_full.gpoint,
            band = best_full.band,
            pressure_index_start = best_full.pressure_index_start,
            pressure_index_end = best_full.pressure_index_end,
            log_scale = best_full.log_scale,
            scale = best_full.scale,
        ) : nothing
        push!(trajectory, (
            iteration = iteration,
            candidate_count = length(rows),
            initial_full_objective = current_full_objective,
            best_full_objective = best_full.full_objective,
            best_metric_objective = minimum(row -> row.metric_objective, rows),
            accepted = accepted,
            accepted_move = accepted_move,
        ))
        accepted || break
        push!(moves, accepted_move)
        current_full_objective = best_full.full_objective
    end

    return (
        method = "iterative component-separated per-g-point pressure-band table scaling",
        iterations_requested = iterations,
        iterations_completed = length(trajectory),
        initial_full_objective = initial_full_objective,
        final_full_objective = current_full_objective,
        objective_reduction = initial_full_objective - current_full_objective,
        improved = current_full_objective < initial_full_objective,
        accepted_move_count = length(moves),
        accepted_moves = moves,
        trajectory = trajectory,
    )
end

function active_table_entry_refinement_scan(full_model, parameters, breakdown,
                                            component_scan;
                                            steps = (0.125, 0.25),
                                            max_candidates =
                                                active_table_entry_candidate_limit(),
                                            base_moves = NamedTuple[])
    base_full_objective = active_table_entry_full_objective(full_model, parameters,
                                                           base_moves)
    base_metric_objective = active_table_entry_metric_objective(
        full_model,
        parameters,
        base_moves,
        breakdown.worst_case,
        breakdown.worst_metric,
    )
    active = component_scan.best_full_candidate
    pressure_indices = active.pressure_index_start:active.pressure_index_end
    rows = NamedTuple[]
    candidate_count = 0
    stop = false
    component = active.component
    ig = active.local_gpoint_index

    if component == "static_absorption"
        for gas_index in axes(full_model.shortwave_absorption, 2)
            for pressure_index in pressure_indices
                for temperature_index in axes(full_model.shortwave_absorption, 4)
                    for step in steps
                        for direction in (-1.0, 1.0)
                            move = (
                                component = component,
                                local_gpoint_index = ig,
                                gpoint = active.gpoint,
                                gas_index = gas_index,
                                pressure_index = pressure_index,
                                temperature_index = temperature_index,
                                h2o_index = 0,
                                log_scale = direction * step,
                                scale = exp(direction * step),
                            )
                            moves = vcat(collect(base_moves), [move])
                            metric_objective = active_table_entry_metric_objective(
                                full_model,
                                parameters,
                                moves,
                                breakdown.worst_case,
                                breakdown.worst_metric,
                            )
                            full_objective = active_table_entry_full_objective(
                                full_model,
                                parameters,
                                moves,
                            )
                            push!(rows, (
                                move...,
                                metric_objective = metric_objective,
                                metric_improvement =
                                    base_metric_objective - metric_objective,
                                full_objective = full_objective,
                                full_improvement =
                                    base_full_objective - full_objective,
                                accepted = full_objective < base_full_objective,
                            ))
                            candidate_count += 1
                            if candidate_count >= max_candidates
                                stop = true
                                break
                            end
                        end
                        stop && break
                    end
                    stop && break
                end
                stop && break
            end
            stop && break
        end
    elseif component == "dynamic_h2o" && length(full_model.shortwave_h2o_absorption) != 0
        for pressure_index in pressure_indices
            for temperature_index in axes(full_model.shortwave_h2o_absorption, 3)
                for h2o_index in axes(full_model.shortwave_h2o_absorption, 4)
                    for step in steps
                        for direction in (-1.0, 1.0)
                            move = (
                                component = component,
                                local_gpoint_index = ig,
                                gpoint = active.gpoint,
                                gas_index = 0,
                                pressure_index = pressure_index,
                                temperature_index = temperature_index,
                                h2o_index = h2o_index,
                                log_scale = direction * step,
                                scale = exp(direction * step),
                            )
                            moves = vcat(collect(base_moves), [move])
                            metric_objective = active_table_entry_metric_objective(
                                full_model,
                                parameters,
                                moves,
                                breakdown.worst_case,
                                breakdown.worst_metric,
                            )
                            full_objective = active_table_entry_full_objective(
                                full_model,
                                parameters,
                                moves,
                            )
                            push!(rows, (
                                move...,
                                metric_objective = metric_objective,
                                metric_improvement =
                                    base_metric_objective - metric_objective,
                                full_objective = full_objective,
                                full_improvement =
                                    base_full_objective - full_objective,
                                accepted = full_objective < base_full_objective,
                            ))
                            candidate_count += 1
                            if candidate_count >= max_candidates
                                stop = true
                                break
                            end
                        end
                        stop && break
                    end
                    stop && break
                end
                stop && break
            end
            stop && break
        end
    end

    best_metric = isempty(rows) ? nothing : argmin(row -> row.metric_objective, rows)
    best_full = isempty(rows) ? nothing : argmin(row -> row.full_objective, rows)
    return (
        method = "active coefficient-table entry scaling inside best component pressure band",
        base_full_objective = base_full_objective,
        base_metric_objective = base_metric_objective,
        target_case = breakdown.worst_case,
        target_metric = breakdown.worst_metric,
        active_component = component,
        active_gpoint = active.gpoint,
        active_band = active.band,
        candidate_count = length(rows),
        max_candidates = max_candidates,
        best_metric_candidate = best_metric,
        best_full_candidate = best_full,
        accepted = best_full !== nothing && best_full.full_objective < base_full_objective,
        rows = rows,
    )
end

function active_table_entry_iterations()
    return parse(Int, get(ENV, "RH_REDUCED_ACTIVE_TABLE_ENTRY_ITERATIONS", "2"))
end

function iterative_active_table_entry_refinement(full_model, parameters, breakdown,
                                                 component_scan;
                                                 iterations =
                                                    active_table_entry_iterations(),
                                                 max_candidates =
                                                    active_table_entry_candidate_limit())
    moves = NamedTuple[]
    initial_full_objective =
        active_table_entry_full_objective(full_model, parameters, moves)
    current_full_objective = initial_full_objective
    trajectory = NamedTuple[]

    for iteration in 1:iterations
        scan = active_table_entry_refinement_scan(
            full_model,
            parameters,
            breakdown,
            component_scan;
            max_candidates = max_candidates,
            base_moves = moves,
        )
        best = scan.best_full_candidate
        accepted = best !== nothing && best.full_objective < current_full_objective
        push!(trajectory, (
            iteration = iteration,
            candidate_count = scan.candidate_count,
            initial_full_objective = current_full_objective,
            best_full_objective = best === nothing ? current_full_objective :
                best.full_objective,
            accepted = accepted,
            accepted_move = accepted ? (
                component = best.component,
                local_gpoint_index = best.local_gpoint_index,
                gpoint = best.gpoint,
                gas_index = best.gas_index,
                pressure_index = best.pressure_index,
                temperature_index = best.temperature_index,
                h2o_index = best.h2o_index,
                log_scale = best.log_scale,
                scale = best.scale,
            ) : nothing,
        ))
        accepted || break
        push!(moves, trajectory[end].accepted_move)
        current_full_objective = best.full_objective
    end

    return (
        method = "iterative active coefficient-table entry scaling",
        iterations_requested = iterations,
        iterations_completed = length(trajectory),
        initial_full_objective = initial_full_objective,
        final_full_objective = current_full_objective,
        objective_reduction = initial_full_objective - current_full_objective,
        improved = current_full_objective < initial_full_objective,
        accepted_move_count = length(moves),
        accepted_moves = moves,
        trajectory = trajectory,
    )
end

function pairwise_pressure_band_top_candidates()
    return parse(Int, get(ENV, "RH_REDUCED_PAIRWISE_PRESSURE_BAND_TOP_CANDIDATES", "6"))
end

function pressure_band_move_from_row(row)
    return (
        local_gpoint_index = row.local_gpoint_index,
        gpoint = row.gpoint,
        band = row.band,
        pressure_index_start = row.pressure_index_start,
        pressure_index_end = row.pressure_index_end,
        log_scale = row.log_scale,
        scale = row.scale,
    )
end

function pairwise_gpoint_pressure_band_refinement_scan(full_model, parameters,
                                                       gpoint_scan, breakdown;
                                                       top_candidates =
                                                        pairwise_pressure_band_top_candidates())
    base_full_objective = gpoint_scan.base_full_objective
    base_metric_objective = gpoint_scan.base_metric_objective
    improving_rows = [
        row for row in gpoint_scan.rows
        if row.metric_objective < base_metric_objective ||
           row.full_objective < base_full_objective
    ]
    sort!(improving_rows; by = row -> min(row.metric_objective, row.full_objective))
    selected_rows = improving_rows[1:min(top_candidates, length(improving_rows))]

    rows = NamedTuple[]
    for i in 1:length(selected_rows)
        first_move = pressure_band_move_from_row(selected_rows[i])
        for j in (i + 1):length(selected_rows)
            second_move = pressure_band_move_from_row(selected_rows[j])
            first_move.local_gpoint_index == second_move.local_gpoint_index &&
                first_move.band == second_move.band && continue
            moves = (first_move, second_move)
            metric_objective = moved_model_metric_objective(
                full_model,
                parameters,
                moves,
                breakdown.worst_case,
                breakdown.worst_metric,
            )
            full_objective = moved_model_full_objective(full_model, parameters, moves)
            push!(rows, (
                first_gpoint = first_move.gpoint,
                first_band = first_move.band,
                first_log_scale = first_move.log_scale,
                second_gpoint = second_move.gpoint,
                second_band = second_move.band,
                second_log_scale = second_move.log_scale,
                metric_objective = metric_objective,
                metric_improvement = base_metric_objective - metric_objective,
                full_objective = full_objective,
                full_improvement = base_full_objective - full_objective,
                accepted = full_objective < base_full_objective,
                moves = moves,
            ))
        end
    end

    best_full = isempty(rows) ? nothing : argmin(row -> row.full_objective, rows)
    best_metric = isempty(rows) ? nothing : argmin(row -> row.metric_objective, rows)
    return (
        method = "pairwise per-g-point pressure-band table scaling over best single-move candidates",
        base_full_objective = base_full_objective,
        base_metric_objective = base_metric_objective,
        target_case = breakdown.worst_case,
        target_metric = breakdown.worst_metric,
        selected_single_candidate_count = length(selected_rows),
        candidate_count = length(rows),
        best_metric_candidate = best_metric,
        best_full_candidate = best_full,
        accepted = best_full !== nothing && best_full.full_objective < base_full_objective,
        rows = rows,
    )
end

function pressure_band_refinement_preflight()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    parameters = current_reduced_parameters()
    breakdown = final_objective_breakdown(full_model, parameters)
    scan = pressure_band_refinement_scan(full_model, parameters, breakdown)
    gpoint_scan = gpoint_pressure_band_refinement_scan(full_model, parameters, breakdown)
    component_gpoint_scan =
        component_gpoint_pressure_band_refinement_scan(full_model, parameters,
                                                      breakdown)
    iterative_component_gpoint_scan =
        iterative_component_gpoint_pressure_band_refinement(full_model,
                                                            parameters,
                                                            breakdown)
    active_entry_scan =
        active_table_entry_refinement_scan(full_model, parameters, breakdown,
                                           component_gpoint_scan)
    iterative_active_entry_scan =
        iterative_active_table_entry_refinement(full_model, parameters, breakdown,
                                                component_gpoint_scan)
    pairwise_scan =
        pairwise_gpoint_pressure_band_refinement_scan(full_model, parameters,
                                                     gpoint_scan, breakdown)
    iterative_scan =
        iterative_gpoint_pressure_band_refinement(full_model, parameters, breakdown)
    accepted = scan.accepted || gpoint_scan.accepted ||
        component_gpoint_scan.accepted || iterative_component_gpoint_scan.improved ||
        active_entry_scan.accepted || iterative_active_entry_scan.improved ||
        pairwise_scan.accepted || iterative_scan.improved
    return (
        case = "reduced_ecckd_pressure_band_refinement_preflight",
        timestamp_utc = string(Dates.now()),
        status = accepted ? "pressure_band_move_improved" :
            "pressure_band_no_accepted_move",
        reference_scope = collect(REDUCED_CASE_NAMES),
        parameterization =
            "nonnegative pressure-band scaling of reduced shortwave absorption and dynamic H2O coefficient tables",
        current_objective = scan.base_full_objective,
        target_case = scan.target_case,
        target_metric = scan.target_metric,
        target_metric_objective = scan.base_metric_objective,
        band_count = scan.band_count,
        candidate_count = scan.candidate_count,
        scan = scan,
        gpoint_scan = gpoint_scan,
        component_gpoint_scan = component_gpoint_scan,
        iterative_component_gpoint_scan = iterative_component_gpoint_scan,
        active_table_entry_scan = active_entry_scan,
        iterative_active_table_entry_scan = iterative_active_entry_scan,
        pairwise_gpoint_scan = pairwise_scan,
        iterative_gpoint_scan = iterative_scan,
        next_required_work =
            iterative_component_gpoint_scan.final_full_objective <= 8.6143936 ?
            "The accepted iterative component pressure-band moves are already promoted into the main reduced optimizer and reduced-accuracy artifact; move beyond bounded pressure-band table scales to a constrained multi-parameter coefficient-table or quadrature-bin optimizer against flux and heating residuals." :
            accepted ?
            "Promote the accepted pressure-band table moves into the reduced optimizer and regenerate the hard-gate accuracy artifact." :
            "Single global and bounded per-g-point pressure-band table scales do not close the RCEMIP TOA forcing blocker; move to a multi-parameter constrained table/quadrature optimizer against flux and heating residuals.",
    )
end

function markdown_report(result)
    best_metric = result.scan.best_metric_candidate
    best_full = result.scan.best_full_candidate
    best_g_metric = result.gpoint_scan.best_metric_candidate
    best_g_full = result.gpoint_scan.best_full_candidate
    best_component = result.component_gpoint_scan.best_full_candidate
    best_entry = result.active_table_entry_scan.best_full_candidate
    entry_objective = best_entry === nothing ?
        result.active_table_entry_scan.base_full_objective :
        best_entry.full_objective
    best_pair = result.pairwise_gpoint_scan.best_full_candidate
    pair_objective = best_pair === nothing ? result.pairwise_gpoint_scan.base_full_objective :
        best_pair.full_objective
    lines = String[
        "# Reduced ecCKD Pressure-Band Refinement Preflight",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Current full objective | $(@sprintf("%.12g", result.current_objective)) |",
        "| Target case | $(result.target_case) |",
        "| Target metric | $(result.target_metric) |",
        "| Target metric objective | $(@sprintf("%.12g", result.target_metric_objective)) |",
        "| Pressure bands | $(result.band_count) |",
        "| Candidates | $(result.candidate_count) |",
        "| Best target-metric band | $(best_metric.band) |",
        "| Best target-metric scale | $(@sprintf("%.6g", best_metric.scale)) |",
        "| Best target-metric objective | $(@sprintf("%.12g", best_metric.metric_objective)) |",
        "| Best full-objective band | $(best_full.band) |",
        "| Best full-objective scale | $(@sprintf("%.6g", best_full.scale)) |",
        "| Best full objective | $(@sprintf("%.12g", best_full.full_objective)) |",
        "| Global pressure-band accepted | $(result.scan.accepted) |",
        "| Per-g pressure-band candidates | $(result.gpoint_scan.candidate_count) |",
        "| Best per-g target g-point | $(best_g_metric.gpoint) |",
        "| Best per-g target band | $(best_g_metric.band) |",
        "| Best per-g target objective | $(@sprintf("%.12g", best_g_metric.metric_objective)) |",
        "| Best per-g full g-point | $(best_g_full.gpoint) |",
        "| Best per-g full band | $(best_g_full.band) |",
        "| Best per-g full objective | $(@sprintf("%.12g", best_g_full.full_objective)) |",
        "| Per-g pressure-band accepted | $(result.gpoint_scan.accepted) |",
        "| Component per-g candidates | $(result.component_gpoint_scan.candidate_count) |",
        "| Best component per-g full component | $(best_component.component) |",
        "| Best component per-g full g-point | $(best_component.gpoint) |",
        "| Best component per-g full band | $(best_component.band) |",
        "| Best component per-g full objective | $(@sprintf("%.12g", best_component.full_objective)) |",
        "| Component per-g pressure-band accepted | $(result.component_gpoint_scan.accepted) |",
        "| Iterative component per-g iterations completed | $(result.iterative_component_gpoint_scan.iterations_completed) |",
        "| Iterative component per-g accepted moves | $(result.iterative_component_gpoint_scan.accepted_move_count) |",
        "| Iterative component per-g final objective | $(@sprintf("%.12g", result.iterative_component_gpoint_scan.final_full_objective)) |",
        "| Active table-entry candidates | $(result.active_table_entry_scan.candidate_count) |",
        "| Active table-entry component | $(result.active_table_entry_scan.active_component) |",
        "| Active table-entry g-point | $(result.active_table_entry_scan.active_gpoint) |",
        "| Best active table-entry full objective | $(@sprintf("%.12g", entry_objective)) |",
        "| Active table-entry accepted | $(result.active_table_entry_scan.accepted) |",
        "| Iterative active table-entry iterations completed | $(result.iterative_active_table_entry_scan.iterations_completed) |",
        "| Iterative active table-entry accepted moves | $(result.iterative_active_table_entry_scan.accepted_move_count) |",
        "| Iterative active table-entry final objective | $(@sprintf("%.12g", result.iterative_active_table_entry_scan.final_full_objective)) |",
        "| Pairwise per-g candidates | $(result.pairwise_gpoint_scan.candidate_count) |",
        "| Pairwise selected single candidates | $(result.pairwise_gpoint_scan.selected_single_candidate_count) |",
        "| Best pairwise full objective | $(@sprintf("%.12g", pair_objective)) |",
        "| Pairwise pressure-band accepted | $(result.pairwise_gpoint_scan.accepted) |",
        "| Iterative per-g iterations requested | $(result.iterative_gpoint_scan.iterations_requested) |",
        "| Iterative per-g iterations completed | $(result.iterative_gpoint_scan.iterations_completed) |",
        "| Iterative per-g accepted moves | $(result.iterative_gpoint_scan.accepted_move_count) |",
        "| Iterative per-g final objective | $(@sprintf("%.12g", result.iterative_gpoint_scan.final_full_objective)) |",
        "| Iterative per-g objective reduction | $(@sprintf("%.12g", result.iterative_gpoint_scan.objective_reduction)) |",
        "",
        "Next required work: $(result.next_required_work)",
    ]
    return join(lines, "\n") * "\n"
end

function main()
    result = pressure_band_refinement_preflight()
    mkpath(dirname(PRESSURE_BAND_JSON))
    write(PRESSURE_BAND_JSON, json_object(result) * "\n")
    write(PRESSURE_BAND_MD, markdown_report(result))
    print(markdown_report(result))
    println("Wrote $PRESSURE_BAND_JSON")
    println("Wrote $PRESSURE_BAND_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
