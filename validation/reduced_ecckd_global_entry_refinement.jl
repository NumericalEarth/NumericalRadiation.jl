include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_optimization_preflight.jl"))

const GLOBAL_ENTRY_JSON =
    validation_results_path("reduced_ecckd_global_entry_refinement.json")
const GLOBAL_ENTRY_MD =
    validation_results_path("reduced_ecckd_global_entry_refinement.md")

function global_entry_candidate_limit()
    return parse(Int, get(ENV, "RH_REDUCED_GLOBAL_ENTRY_CANDIDATES", "256"))
end

function global_entry_candidate_offset()
    return parse(Int, get(ENV, "RH_REDUCED_GLOBAL_ENTRY_CANDIDATE_OFFSET", "0"))
end

function global_entry_iterations()
    return parse(Int, get(ENV, "RH_REDUCED_GLOBAL_ENTRY_ITERATIONS", "1"))
end

function global_entry_sweep_windows()
    return parse(Int, get(ENV, "RH_REDUCED_GLOBAL_ENTRY_SWEEP_WINDOWS", "1"))
end

function global_entry_sweep_stride()
    return parse(Int, get(ENV, "RH_REDUCED_GLOBAL_ENTRY_SWEEP_STRIDE",
                          string(global_entry_candidate_limit())))
end

function global_entry_sweep_max_no_improve()
    return parse(Int, get(ENV, "RH_REDUCED_GLOBAL_ENTRY_SWEEP_MAX_NO_IMPROVE", "1"))
end

function all_slot_targeted_entry_candidates(full_model, case_name;
                                           sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    case = reduced_case_by_name(case_name)
    nc = require_ncdatasets()
    scores = Dict{Tuple, Float64}()
    nc.NCDataset(reference_path(case.path)) do dataset
        pressure_layers = Array(dataset["pressure_layer"])
        pressure_interfaces = Array(dataset["pressure_interface"])
        temperature_layers = Array(dataset["temperature_layer"])
        gas_amounts = gas_column_amounts(dataset, pressure_interfaces).amounts
        gases = Dict(Symbol(name) => values for (name, values) in gas_amounts)
        gas_names_tuple = NumericalRadiation.gas_names(full_model)
        references = full_model.gas_reference_mole_fractions
        nlayers, ncolumns = size(pressure_layers)

        for ig in eachindex(sw_indices)
            for column in 1:ncolumns, k in 1:nlayers
                pressure = pressure_layers[k, column]
                temperature = temperature_layers[k, column]
                ip0, ip1, wp =
                    active_entry_pressure_bracket(full_model.pressure_grid, pressure)
                it0, it1, wt =
                    active_entry_temperature_corners(full_model, pressure,
                                                     temperature, ip0, ip1, wp)
                pressure_corners = ((ip0, 1.0 - wp), (ip1, wp))
                temperature_corners = ((it0, 1.0 - wt), (it1, wt))

                for (pressure_index, pressure_weight) in pressure_corners
                    for (temperature_index, temperature_weight) in temperature_corners
                        interpolation_weight = pressure_weight * temperature_weight
                        interpolation_weight <= 0 && continue
                        for gas_index in axes(full_model.shortwave_absorption, 2)
                            amount = active_entry_static_amount(
                                gases,
                                gas_names_tuple,
                                references,
                                gas_index,
                                k,
                                column,
                            )
                            priority = abs(amount) * interpolation_weight
                            priority <= 0 && continue
                            key = ("static_absorption", ig, sw_indices[ig],
                                   gas_index, pressure_index, temperature_index, 0)
                            active_entry_candidate_push!(scores, key, priority)
                        end
                    end

                    length(full_model.shortwave_h2o_absorption) == 0 && continue
                    haskey(gases, :h2o) || continue
                    h2o_moles = max(gases[:h2o][k, column], 0.0)
                    dry_air_moles = haskey(gases, :composite) ?
                        max(gases[:composite][k, column], sqrt(eps(Float64))) :
                        max((pressure_interfaces[k + 1, column] -
                             pressure_interfaces[k, column]) /
                            (9.80665 * 0.0289647), sqrt(eps(Float64)))
                    h2o_mole_fraction = h2o_moles / dry_air_moles
                    ih0, ih1, wh = active_entry_log_bracket(
                        full_model.h2o_mole_fraction_grid,
                        h2o_mole_fraction,
                    )
                    for (temperature_index, temperature_weight) in temperature_corners
                        for (h2o_index, h2o_weight) in ((ih0, 1.0 - wh), (ih1, wh))
                            interpolation_weight =
                                pressure_weight * temperature_weight * h2o_weight
                            interpolation_weight <= 0 && continue
                            priority = h2o_moles * interpolation_weight
                            priority <= 0 && continue
                            key = ("dynamic_h2o", ig, sw_indices[ig], 0,
                                   pressure_index, temperature_index, h2o_index)
                            active_entry_candidate_push!(scores, key, priority)
                        end
                    end
                end
            end
        end
    end

    ranked = collect(scores)
    sort!(ranked; by = pair -> -pair.second)
    return [
        (
            component = key[1],
            local_gpoint_index = key[2],
            gpoint = key[3],
            gas_index = key[4],
            pressure_index = key[5],
            temperature_index = key[6],
            h2o_index = key[7],
            priority = priority,
        )
        for (key, priority) in ranked
    ]
end

function global_entry_window_refinement(full_model, parameters, pressure_moves,
                                        active_moves, target_case, target_metric,
                                        candidates;
                                        sw_indices = WEIGHTED_GREEDY_SW_16_INDICES,
                                        steps = (0.0625, 0.125, 0.25),
                                        max_candidates = global_entry_candidate_limit(),
                                        candidate_offset = global_entry_candidate_offset(),
                                        iterations = global_entry_iterations(),
                                        progress_interval =
                                           active_table_entry_progress_interval(),
                                        max_seconds = active_table_entry_max_seconds())
    current_moves = collect(active_moves)
    initial_objective = pressure_band_active_table_full_objective(
        full_model,
        parameters,
        pressure_moves,
        current_moves;
        sw_indices,
    )
    current_objective = initial_objective
    trajectory = NamedTuple[]
    start_time = time()
    time_limited = false

    for iteration in 1:iterations
        rows = NamedTuple[]
        candidate_count = 0
        stop = false
        start_index = min(candidate_offset + 1, length(candidates) + 1)
        for base_move in @view candidates[start_index:end]
            for step in steps
                for direction in (-1.0, 1.0)
                    move = (
                        component = base_move.component,
                        local_gpoint_index = base_move.local_gpoint_index,
                        gpoint = base_move.gpoint,
                        gas_index = base_move.gas_index,
                        pressure_index = base_move.pressure_index,
                        temperature_index = base_move.temperature_index,
                        h2o_index = base_move.h2o_index,
                        log_scale = direction * step,
                        scale = exp(direction * step),
                        priority = base_move.priority,
                    )
                    candidate_moves = vcat(current_moves, [move])
                    objective = pressure_band_active_table_full_objective(
                        full_model,
                        parameters,
                        pressure_moves,
                        candidate_moves;
                        sw_indices,
                    )
                    push!(rows, (
                        move...,
                        full_objective = objective,
                        full_improvement = current_objective - objective,
                        accepted = objective < current_objective,
                    ))
                    candidate_count += 1
                    if progress_interval > 0 && candidate_count % progress_interval == 0
                        @printf("global active-entry iteration %d evaluated %d candidates; current best %.12g\n",
                                iteration, candidate_count,
                                minimum(row -> row.full_objective, rows))
                        flush(stdout)
                    end
                    if max_seconds > 0 && time() - start_time >= max_seconds
                        time_limited = true
                        stop = true
                        break
                    end
                    if candidate_count >= max_candidates
                        stop = true
                        break
                    end
                end
                stop && break
            end
            stop && break
        end

        if isempty(rows)
            push!(trajectory, (
                iteration = iteration,
                candidate_count = 0,
                initial_full_objective = current_objective,
                best_full_objective = current_objective,
                accepted = false,
                accepted_move = nothing,
            ))
            break
        end

        best = argmin(row -> row.full_objective, rows)
        accepted = best.full_objective < current_objective
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
        ) : nothing
        push!(trajectory, (
            iteration = iteration,
            candidate_count = length(rows),
            initial_full_objective = current_objective,
            best_full_objective = best.full_objective,
            accepted = accepted,
            accepted_move = accepted_move,
        ))
        accepted || break
        push!(current_moves, accepted_move)
        current_objective = best.full_objective
        time_limited && break
    end

    return (
        method = "global all-slot worst-case stencil-ranked active table-entry refinement",
        target_case = target_case,
        target_metric = target_metric,
        iterations_requested = iterations,
        iterations_completed = length(trajectory),
        max_candidates_per_iteration = max_candidates,
        candidate_offset = candidate_offset,
        total_ranked_candidate_count = length(candidates),
        progress_interval = progress_interval,
        max_seconds = max_seconds,
        time_limited = time_limited,
        initial_full_objective = initial_objective,
        final_objective = current_objective,
        objective_reduction = initial_objective - current_objective,
        improved = current_objective < initial_objective,
        accepted_move_count = length(current_moves) - length(active_moves),
        accepted_moves = current_moves[(length(active_moves) + 1):end],
        all_active_moves = current_moves,
        trajectory = trajectory,
    )
end

function global_entry_refinement(full_model, parameters, pressure_moves, active_moves,
                                 target_case, target_metric;
                                 sw_indices = WEIGHTED_GREEDY_SW_16_INDICES,
                                 steps = (0.0625, 0.125, 0.25),
                                 max_candidates = global_entry_candidate_limit(),
                                 candidate_offset = global_entry_candidate_offset(),
                                 iterations = global_entry_iterations(),
                                 progress_interval =
                                    active_table_entry_progress_interval(),
                                 max_seconds = active_table_entry_max_seconds())
    candidates = all_slot_targeted_entry_candidates(
        full_model,
        target_case;
        sw_indices,
    )
    return global_entry_window_refinement(
        full_model,
        parameters,
        pressure_moves,
        active_moves,
        target_case,
        target_metric,
        candidates;
        sw_indices,
        steps,
        max_candidates,
        candidate_offset,
        iterations,
        progress_interval,
        max_seconds,
    )
end

function global_entry_sweep_refinement(full_model, parameters, pressure_moves, active_moves,
                                       base_breakdown;
                                       sw_indices = WEIGHTED_GREEDY_SW_16_INDICES,
                                       max_candidates = global_entry_candidate_limit(),
                                       candidate_offset = global_entry_candidate_offset(),
                                       stride = global_entry_sweep_stride(),
                                       windows = global_entry_sweep_windows(),
                                       max_no_improve =
                                           global_entry_sweep_max_no_improve())
    current_moves = collect(active_moves)
    initial_objective = pressure_band_active_table_full_objective(
        full_model,
        parameters,
        pressure_moves,
        current_moves;
        sw_indices,
    )
    current_objective = initial_objective
    current_breakdown = base_breakdown
    window_rows = NamedTuple[]
    no_improve_count = 0

    for window in 1:windows
        offset = candidate_offset + (window - 1) * stride
        candidates = all_slot_targeted_entry_candidates(
            full_model,
            current_breakdown.worst_case;
            sw_indices,
        )
        refinement = global_entry_window_refinement(
            full_model,
            parameters,
            pressure_moves,
            current_moves,
            current_breakdown.worst_case,
            current_breakdown.worst_metric,
            candidates;
            sw_indices,
            max_candidates,
            candidate_offset = offset,
            iterations = 1,
        )
        improved = refinement.final_objective < current_objective
        push!(window_rows, (
            window = window,
            candidate_offset = offset,
            target_case = current_breakdown.worst_case,
            target_metric = current_breakdown.worst_metric,
            initial_objective = current_objective,
            final_objective = refinement.final_objective,
            objective_reduction = current_objective - refinement.final_objective,
            improved = improved,
            accepted_move_count = refinement.accepted_move_count,
            total_ranked_candidate_count = refinement.total_ranked_candidate_count,
        ))
        if improved
            current_moves = refinement.all_active_moves
            current_objective = refinement.final_objective
            no_improve_count = 0
            model = pressure_band_active_table_moved_model(
                full_model,
                parameters,
                pressure_moves,
                current_moves;
                sw_indices,
            )
            current_breakdown = final_objective_breakdown_from_model(
                model;
                sw_indices,
                method = "global entry sweep current hard-gate breakdown",
            )
        else
            no_improve_count += 1
            no_improve_count >= max_no_improve && break
        end
    end

    return (
        method = "global all-slot active table-entry offset-window sweep",
        target_case = base_breakdown.worst_case,
        target_metric = base_breakdown.worst_metric,
        iterations_requested = windows,
        iterations_completed = length(window_rows),
        max_candidates_per_iteration = max_candidates,
        candidate_offset = candidate_offset,
        sweep_stride = stride,
        sweep_max_no_improve = max_no_improve,
        total_ranked_candidate_count =
            isempty(window_rows) ? 0 : window_rows[end].total_ranked_candidate_count,
        progress_interval = active_table_entry_progress_interval(),
        max_seconds = active_table_entry_max_seconds(),
        time_limited = false,
        initial_full_objective = initial_objective,
        final_objective = current_objective,
        objective_reduction = initial_objective - current_objective,
        improved = current_objective < initial_objective,
        accepted_move_count = length(current_moves) - length(active_moves),
        accepted_moves = current_moves[(length(active_moves) + 1):end],
        all_active_moves = current_moves,
        trajectory = window_rows,
    )
end

function global_entry_refinement_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    parameters = latest_preflight_reduced_parameters()
    parameters === nothing && error("reduced preflight parameters are required")
    pressure_moves = latest_preflight_pressure_band_table_moves()
    isempty(pressure_moves) && error("accepted pressure-band table moves are required")
    active_moves = best_available_active_table_entry_moves()
    pressure_active_model = pressure_band_active_table_moved_model(
        full_model,
        parameters,
        pressure_moves,
        active_moves,
    )
    base_breakdown = final_objective_breakdown_from_model(
        pressure_active_model;
        method = "global entry refinement starting hard-gate breakdown",
    )
    refinement = global_entry_sweep_windows() <= 1 ?
        global_entry_refinement(
            full_model,
            parameters,
            pressure_moves,
            active_moves,
            base_breakdown.worst_case,
            base_breakdown.worst_metric,
        ) :
        global_entry_sweep_refinement(
            full_model,
            parameters,
            pressure_moves,
            active_moves,
            base_breakdown,
        )

    return (
        case = "reduced_ecckd_global_entry_refinement",
        status = "preflight_ready",
        target_case = base_breakdown.worst_case,
        target_metric = base_breakdown.worst_metric,
        target_value = base_breakdown.worst_value,
        target_threshold = base_breakdown.worst_threshold,
        parameter_source = REDUCED_OPTIMIZATION_PREFLIGHT_JSON,
        pressure_move_count = length(pressure_moves),
        starting_active_move_count = length(active_moves),
        candidate_limit = global_entry_candidate_limit(),
        candidate_offset = global_entry_candidate_offset(),
        iterations_requested = global_entry_iterations(),
        sweep_windows = global_entry_sweep_windows(),
        sweep_stride = global_entry_sweep_stride(),
        sweep_max_no_improve = global_entry_sweep_max_no_improve(),
        initial_objective = refinement.initial_full_objective,
        final_objective = refinement.final_objective,
        objective_reduction = refinement.objective_reduction,
        improved = refinement.improved,
        accepted_move_count = refinement.accepted_move_count,
        total_ranked_candidate_count = refinement.total_ranked_candidate_count,
        refinement = refinement,
    )
end

function global_entry_markdown(result)
    lines = String[
        "# Reduced ecCKD Global Entry Refinement",
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
        "| Starting active move count | $(result.starting_active_move_count) |",
        "| Ranked candidate count | $(result.total_ranked_candidate_count) |",
        "| Candidate limit | $(result.candidate_limit) |",
        "| Candidate offset | $(result.candidate_offset) |",
        "| Iterations requested | $(result.iterations_requested) |",
        "| Sweep windows | $(result.sweep_windows) |",
        "| Sweep stride | $(result.sweep_stride) |",
        "| Sweep max no-improve | $(result.sweep_max_no_improve) |",
        "| Accepted move count | $(result.accepted_move_count) |",
        "| Initial objective | $(@sprintf("%.12g", result.initial_objective)) |",
        "| Final objective | $(@sprintf("%.12g", result.final_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Improved | $(result.improved) |",
        "",
        "This artifact broadens the active-entry search beyond entries inside the",
        "accepted pressure-band moves. It ranks all reduced shortwave slots by the",
        "current worst case's interpolation stencil and gas amounts, then applies",
        "the same full hard-objective acceptance rule as the main refinement.",
    ]
    return join(lines, "\n") * "\n"
end

function write_global_entry_artifacts(result)
    mkpath(dirname(GLOBAL_ENTRY_JSON))
    write(GLOBAL_ENTRY_JSON, json_object(result) * "\n")
    write(GLOBAL_ENTRY_MD, global_entry_markdown(result))
    print(global_entry_markdown(result))
    println("Wrote $GLOBAL_ENTRY_JSON")
    println("Wrote $GLOBAL_ENTRY_MD")
end

function main(; result = nothing)
    write_global_entry_artifacts(
        result === nothing ? global_entry_refinement_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
