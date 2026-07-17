include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_global_entry_refinement.jl"))

const GLOBAL_BLOCK_JSON =
    validation_results_path("reduced_ecckd_global_block_refinement.json")
const GLOBAL_BLOCK_MD =
    validation_results_path("reduced_ecckd_global_block_refinement.md")

global_block_group_limit() =
    parse(Int, get(ENV, "RH_REDUCED_GLOBAL_BLOCK_GROUPS", "16"))

global_block_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_GLOBAL_BLOCK_ITERATIONS", "1"))

function global_block_sizes()
    raw = get(ENV, "RH_REDUCED_GLOBAL_BLOCK_SIZES", "2,4")
    return [parse(Int, strip(token)) for token in split(raw, ",") if !isempty(strip(token))]
end

function global_block_key(candidate)
    if candidate.component == "static_absorption"
        return (
            component = candidate.component,
            local_gpoint_index = candidate.local_gpoint_index,
            gpoint = candidate.gpoint,
            gas_index = candidate.gas_index,
        )
    elseif candidate.component == "dynamic_h2o"
        return (
            component = candidate.component,
            local_gpoint_index = candidate.local_gpoint_index,
            gpoint = candidate.gpoint,
            gas_index = candidate.gas_index,
        )
    end
    return (
        component = candidate.component,
        local_gpoint_index = candidate.local_gpoint_index,
        gpoint = candidate.gpoint,
        gas_index = candidate.gas_index,
    )
end

function grouped_global_entry_blocks(candidates; group_limit = global_block_group_limit())
    groups = Dict{NamedTuple, Vector{NamedTuple}}()
    priorities = Dict{NamedTuple, Float64}()
    for candidate in candidates
        key = global_block_key(candidate)
        group = get!(groups, key, NamedTuple[])
        push!(group, candidate)
        priorities[key] = get(priorities, key, 0.0) + candidate.priority
    end
    ranked_keys = collect(keys(groups))
    sort!(ranked_keys; by = key -> -priorities[key])
    limited_keys = Iterators.take(ranked_keys, group_limit)
    return [
        (
            key...,
            priority = priorities[key],
            entries = groups[key],
        )
        for key in limited_keys
    ]
end

function block_moves(block, block_size, log_scale)
    return [
        (
            component = candidate.component,
            local_gpoint_index = candidate.local_gpoint_index,
            gpoint = candidate.gpoint,
            gas_index = candidate.gas_index,
            pressure_index = candidate.pressure_index,
            temperature_index = candidate.temperature_index,
            h2o_index = candidate.h2o_index,
            log_scale = log_scale,
            scale = exp(log_scale),
            priority = candidate.priority,
        )
        for candidate in Iterators.take(block.entries, block_size)
    ]
end

function global_block_refinement(full_model, parameters, pressure_moves, active_moves,
                                 base_breakdown;
                                 sw_indices = WEIGHTED_GREEDY_SW_16_INDICES,
                                 iterations = global_block_iterations(),
                                 group_limit = global_block_group_limit(),
                                 sizes = global_block_sizes(),
                                 steps = (0.0625, 0.125, 0.25))
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
    trajectory = NamedTuple[]

    for iteration in 1:iterations
        candidates = all_slot_targeted_entry_candidates(
            full_model,
            current_breakdown.worst_case;
            sw_indices,
        )
        blocks = grouped_global_entry_blocks(candidates; group_limit)
        rows = NamedTuple[]
        for block in blocks
            for block_size in sizes
                selected_count = min(block_size, length(block.entries))
                selected_count == 0 && continue
                for step in steps
                    for direction in (-1.0, 1.0)
                        trial_moves = block_moves(block, selected_count, direction * step)
                        objective = pressure_band_active_table_full_objective(
                            full_model,
                            parameters,
                            pressure_moves,
                            vcat(current_moves, trial_moves);
                            sw_indices,
                        )
                        push!(rows, (
                            component = block.component,
                            local_gpoint_index = block.local_gpoint_index,
                            gpoint = block.gpoint,
                            gas_index = block.gas_index,
                            group_priority = block.priority,
                            block_size = selected_count,
                            step = step,
                            direction = direction < 0 ? "negative" : "positive",
                            move_count = length(trial_moves),
                            full_objective = objective,
                            full_improvement = current_objective - objective,
                            accepted = objective < current_objective,
                        ))
                    end
                end
            end
        end

        if isempty(rows)
            push!(trajectory, (
                iteration = iteration,
                candidate_group_count = 0,
                evaluated_block_count = 0,
                initial_objective = current_objective,
                best_objective = current_objective,
                accepted = false,
                accepted_moves = NamedTuple[],
            ))
            break
        end

        best = argmin(row -> row.full_objective, rows)
        accepted = best.full_objective < current_objective
        accepted_moves = accepted ? block_moves(
            only(filter(block -> block.component == best.component &&
                                 block.local_gpoint_index == best.local_gpoint_index &&
                                 block.gpoint == best.gpoint &&
                                 block.gas_index == best.gas_index,
                        blocks)),
            best.block_size,
            (best.direction == "negative" ? -1.0 : 1.0) * best.step,
        ) : NamedTuple[]

        push!(trajectory, (
            iteration = iteration,
            candidate_group_count = length(blocks),
            evaluated_block_count = length(rows),
            initial_objective = current_objective,
            best_objective = best.full_objective,
            objective_reduction = current_objective - best.full_objective,
            accepted = accepted,
            best_component = best.component,
            best_gpoint = best.gpoint,
            best_gas_index = best.gas_index,
            best_block_size = best.block_size,
            best_step = best.step,
            best_direction = best.direction,
            accepted_moves = accepted_moves,
        ))

        accepted || break
        append!(current_moves, accepted_moves)
        current_objective = best.full_objective
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
            method = "global block refinement current hard-gate breakdown",
        )
    end

    return (
        method = "global grouped active table-entry block refinement",
        target_case = base_breakdown.worst_case,
        target_metric = base_breakdown.worst_metric,
        iterations_requested = iterations,
        iterations_completed = length(trajectory),
        group_limit = group_limit,
        block_sizes = sizes,
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

function global_block_refinement_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    parameters = latest_preflight_reduced_parameters()
    parameters === nothing && error("reduced preflight parameters are required")
    pressure_moves = latest_preflight_pressure_band_table_moves()
    isempty(pressure_moves) && error("accepted pressure-band table moves are required")
    active_moves = best_available_active_table_entry_moves()
    base_model = pressure_band_active_table_moved_model(
        full_model,
        parameters,
        pressure_moves,
        active_moves,
    )
    base_breakdown = final_objective_breakdown_from_model(
        base_model;
        method = "global block refinement starting hard-gate breakdown",
    )
    refinement = global_block_refinement(
        full_model,
        parameters,
        pressure_moves,
        active_moves,
        base_breakdown,
    )
    return (
        case = "reduced_ecckd_global_block_refinement",
        status = "preflight_ready",
        target_case = base_breakdown.worst_case,
        target_metric = base_breakdown.worst_metric,
        target_value = base_breakdown.worst_value,
        target_threshold = base_breakdown.worst_threshold,
        parameter_source = REDUCED_OPTIMIZATION_PREFLIGHT_JSON,
        pressure_move_count = length(pressure_moves),
        starting_active_move_count = length(active_moves),
        group_limit = global_block_group_limit(),
        block_sizes = global_block_sizes(),
        iterations_requested = global_block_iterations(),
        initial_objective = refinement.initial_full_objective,
        final_objective = refinement.final_objective,
        objective_reduction = refinement.objective_reduction,
        improved = refinement.improved,
        accepted_move_count = refinement.accepted_move_count,
        refinement = refinement,
    )
end

function global_block_markdown(result)
    lines = String[
        "# Reduced ecCKD Global Block Refinement",
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
        "| Group limit | $(result.group_limit) |",
        "| Block sizes | $(join(result.block_sizes, ", ")) |",
        "| Iterations requested | $(result.iterations_requested) |",
        "| Accepted move count | $(result.accepted_move_count) |",
        "| Initial objective | $(@sprintf("%.12g", result.initial_objective)) |",
        "| Final objective | $(@sprintf("%.12g", result.final_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Improved | $(result.improved) |",
        "",
        "This artifact tests coherent multi-entry table moves rather than one",
        "scalar entry at a time. Candidate entries are grouped by component,",
        "local shortwave slot, official g-point, and gas identity, then accepted",
        "only when the nonlinear full hard-gate objective improves.",
    ]
    return join(lines, "\n") * "\n"
end

function write_global_block_artifacts(result)
    mkpath(dirname(GLOBAL_BLOCK_JSON))
    write(GLOBAL_BLOCK_JSON, json_object(result) * "\n")
    write(GLOBAL_BLOCK_MD, global_block_markdown(result))
    print(global_block_markdown(result))
    println("Wrote $GLOBAL_BLOCK_JSON")
    println("Wrote $GLOBAL_BLOCK_MD")
end

function main(; result = nothing)
    write_global_block_artifacts(
        result === nothing ? global_block_refinement_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
