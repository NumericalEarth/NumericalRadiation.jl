include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_boundary_column_refinement.jl"))

const BOUNDARY_COLUMN_BLOCK_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_boundary_column_block_refinement.json")
const BOUNDARY_COLUMN_BLOCK_REFINEMENT_MD =
    validation_results_path("reduced_ecckd_boundary_column_block_refinement.md")

boundary_column_block_candidate_limit() =
    parse(Int, get(ENV, "RH_REDUCED_BOUNDARY_COLUMN_BLOCK_CANDIDATES", "24"))

function boundary_column_block_sizes()
    raw = get(ENV, "RH_REDUCED_BOUNDARY_COLUMN_BLOCK_SIZES", "4,8,16")
    return [parse(Int, strip(token)) for token in split(raw, ",") if !isempty(strip(token))]
end

function boundary_column_block_steps()
    raw = get(ENV, "RH_REDUCED_BOUNDARY_COLUMN_BLOCK_STEPS", "0.00390625,0.0078125,0.015625,0.03125")
    return [parse(Float64, strip(token)) for token in split(raw, ",") if !isempty(strip(token))]
end

function boundary_column_candidate_blocks(candidates;
                                          limit = boundary_column_block_candidate_limit(),
                                          sizes = boundary_column_block_sizes())
    groups = Dict{Tuple{Int, String}, Vector{NamedTuple}}()
    for candidate in candidates
        key = (candidate.local_gpoint_index, candidate.component)
        push!(get!(groups, key, NamedTuple[]), candidate)
    end
    ordered = collect(groups)
    sort!(ordered; by = pair -> -sum(candidate.priority for candidate in pair.second))
    blocks = NamedTuple[]
    for (key, entries) in Iterators.take(ordered, limit)
        sort!(entries; by = candidate -> -candidate.priority)
        for block_size in sizes
            selected_count = min(block_size, length(entries))
            selected_count == 0 && continue
            selected = entries[1:selected_count]
            push!(blocks, (
                local_gpoint_index = key[1],
                component = key[2],
                block_size = selected_count,
                priority = sum(candidate.priority for candidate in selected),
                entries = selected,
            ))
        end
    end
    return blocks
end

function boundary_column_block_moves(block, log_scale)
    return [
        (
            component = entry.component,
            local_gpoint_index = entry.local_gpoint_index,
            gpoint = entry.gpoint,
            gas_index = entry.gas_index,
            pressure_index = entry.pressure_index,
            temperature_index = entry.temperature_index,
            h2o_index = entry.h2o_index,
            log_scale = log_scale,
            scale = exp(log_scale),
            priority = entry.priority,
        )
        for entry in block.entries
    ]
end

function boundary_column_block_refinement_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    parameters = latest_preflight_reduced_parameters()
    parameters === nothing && error("reduced preflight parameters are required")
    pressure_moves = latest_preflight_pressure_band_table_moves()
    isempty(pressure_moves) && error("accepted pressure-band table moves are required")
    active_moves = best_available_active_table_entry_moves()
    base_model = current_table_refined_model(full_model)
    exact_refit = latest_exact_weight_refit_weights()
    exact_refit === nothing || (base_model.shortwave_weights .= exact_refit.weights)
    base_full_breakdown = final_objective_breakdown_from_model(
        base_model;
        method = "boundary-column block refinement base breakdown",
    )
    target_breakdown = boundary_column_target_breakdown(base_full_breakdown)
    worst_column = boundary_column_worst_column(base_model, target_breakdown)
    candidates = boundary_column_candidates(
        full_model,
        base_model,
        target_breakdown,
        worst_column,
    )
    blocks = boundary_column_candidate_blocks(candidates)
    rows = NamedTuple[]
    for block in blocks
        for step in boundary_column_block_steps()
            for direction in (-1.0, 1.0)
                moves = boundary_column_block_moves(block, direction * step)
                candidate_model = table_moved_weighted_model(
                    full_model,
                    parameters,
                    pressure_moves,
                    vcat(active_moves, moves),
                    base_model.shortwave_weights,
                )
                candidate_breakdown = final_objective_breakdown_from_model(
                    candidate_model;
                    method = "boundary-column block refinement candidate breakdown",
                )
                push!(rows, (
                    local_gpoint_index = block.local_gpoint_index,
                    component = block.component,
                    block_size = block.block_size,
                    priority = block.priority,
                    step = step,
                    direction = direction < 0 ? "negative" : "positive",
                    objective = candidate_breakdown.objective,
                    improvement =
                        base_full_breakdown.objective - candidate_breakdown.objective,
                    moves = moves,
                    candidate_breakdown = candidate_breakdown,
                ))
            end
        end
    end
    isempty(rows) && error("no boundary-column blocks were evaluated")
    best = argmin(row -> row.objective, rows)
    accepted = best.objective < base_full_breakdown.objective
    accepted_moves = accepted ? best.moves : NamedTuple[]
    return (
        case = "reduced_ecckd_boundary_column_block_refinement",
        status = "preflight_ready",
        target_case = target_breakdown.worst_case,
        target_metric = target_breakdown.worst_metric,
        target_boundary = worst_column.boundary,
        target_column = worst_column.column,
        target_residual_w_m2 = worst_column.residual_w_m2,
        pressure_move_count = length(pressure_moves),
        starting_active_move_count = length(active_moves),
        ranked_candidate_count = length(candidates),
        block_count = length(blocks),
        evaluated_trial_count = length(rows),
        block_sizes = boundary_column_block_sizes(),
        steps = boundary_column_block_steps(),
        base_objective = base_full_breakdown.objective,
        base_boundary_objective = target_breakdown.objective,
        candidate_objective = best.objective,
        final_objective = accepted ? best.objective : base_full_breakdown.objective,
        objective_reduction = best.improvement,
        accepted = accepted,
        accepted_move_count = length(accepted_moves),
        accepted_moves = accepted_moves,
        all_active_moves = vcat(active_moves, accepted_moves),
        best_local_gpoint_index = best.local_gpoint_index,
        best_component = best.component,
        best_block_size = best.block_size,
        best_step = best.step,
        best_direction = best.direction,
        base_breakdown = base_full_breakdown,
        target_breakdown = target_breakdown,
        candidate_breakdown = best.candidate_breakdown,
    )
end

function boundary_column_block_markdown(result)
    lines = String[
        "# Reduced ecCKD Boundary-Column Block Refinement",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Target case | $(result.target_case) |",
        "| Target metric | $(result.target_metric) |",
        "| Target boundary | $(result.target_boundary) |",
        "| Target column | $(result.target_column) |",
        "| Target residual | $(@sprintf("%.12g", result.target_residual_w_m2)) W m^-2 |",
        "| Starting active move count | $(result.starting_active_move_count) |",
        "| Ranked candidate count | $(result.ranked_candidate_count) |",
        "| Block count | $(result.block_count) |",
        "| Evaluated trial count | $(result.evaluated_trial_count) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Base boundary objective | $(@sprintf("%.12g", result.base_boundary_objective)) |",
        "| Candidate objective | $(@sprintf("%.12g", result.candidate_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Accepted | $(result.accepted) |",
        "| Accepted move count | $(result.accepted_move_count) |",
        "| Best local g-point index | $(result.best_local_gpoint_index) |",
        "| Best component | $(result.best_component) |",
        "| Best block size | $(result.best_block_size) |",
        "| Best direction | $(result.best_direction) |",
        "| Best step | $(@sprintf("%.12g", result.best_step)) |",
        "",
        "This diagnostic groups entries used by the current worst boundary column",
        "and applies one coherent nonnegative scaling to each block. It accepts",
        "only candidates that reduce the full normalized hard-gate objective.",
    ]
    return join(lines, "\n") * "\n"
end

function write_boundary_column_block_artifacts(result)
    mkpath(dirname(BOUNDARY_COLUMN_BLOCK_REFINEMENT_JSON))
    write(BOUNDARY_COLUMN_BLOCK_REFINEMENT_JSON, json_object(result) * "\n")
    write(BOUNDARY_COLUMN_BLOCK_REFINEMENT_MD, boundary_column_block_markdown(result))
    print(boundary_column_block_markdown(result))
    println("Wrote $BOUNDARY_COLUMN_BLOCK_REFINEMENT_JSON")
    println("Wrote $BOUNDARY_COLUMN_BLOCK_REFINEMENT_MD")
end

function main(; result = nothing)
    write_boundary_column_block_artifacts(
        result === nothing ? boundary_column_block_refinement_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
