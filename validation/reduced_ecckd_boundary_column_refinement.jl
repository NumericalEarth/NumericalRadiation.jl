include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_joint_weight_block_refit.jl"))

const BOUNDARY_COLUMN_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_boundary_column_refinement.json")
const BOUNDARY_COLUMN_REFINEMENT_MD =
    validation_results_path("reduced_ecckd_boundary_column_refinement.md")

boundary_column_candidate_limit() =
    parse(Int, get(ENV, "RH_REDUCED_BOUNDARY_COLUMN_CANDIDATES", "128"))

function boundary_column_steps()
    raw = get(ENV, "RH_REDUCED_BOUNDARY_COLUMN_STEPS", "0.015625,0.03125,0.0625,0.125")
    return [parse(Float64, strip(token)) for token in split(raw, ",") if !isempty(strip(token))]
end

function boundary_column_worst_column(model, breakdown)
    case = reduced_case_by_name(breakdown.worst_case)
    candidate = candidate_arrays(case.path, model)
    nc = require_ncdatasets()
    result = nc.NCDataset(reference_path(case.path)) do dataset
        reference = (
            lw_up = Array(dataset["lw_up"]),
            lw_down = Array(dataset["lw_down"]),
            sw_up = Array(dataset["sw_up"]),
            sw_down = Array(dataset["sw_down"]),
        )
        if breakdown.worst_metric == "toa_forcing_max_abs"
            residual = boundary_net(candidate, :toa) .- boundary_net(reference, :toa)
            _, column = findmax(abs.(residual))
            return (
                column = column,
                boundary = "toa",
                residual_w_m2 = residual[column],
                normalized_residual =
                    residual[column] / ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
            )
        elseif breakdown.worst_metric == "surface_forcing_max_abs"
            residual = boundary_net(candidate, :surface) .- boundary_net(reference, :surface)
            _, column = findmax(abs.(residual))
            return (
                column = column,
                boundary = "surface",
                residual_w_m2 = residual[column],
                normalized_residual =
                    residual[column] /
                    ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
            )
        end
        return nothing
    end
    result === nothing &&
        error("boundary-column refinement only supports boundary forcing metrics")
    return result
end

function boundary_column_target_breakdown(breakdown)
    boundary_rows = filter(
        row -> row.metric == "toa_forcing_max_abs" ||
               row.metric == "surface_forcing_max_abs",
        breakdown.rows,
    )
    isempty(boundary_rows) && error("no boundary forcing rows found")
    worst = argmax(row -> row.normalized_value, boundary_rows)
    return (
        method = "boundary-column refinement boundary target",
        sw_indices = breakdown.sw_indices,
        objective = worst.normalized_value,
        worst_case = worst.case,
        worst_metric = worst.metric,
        worst_value = worst.value,
        worst_threshold = worst.threshold,
        rows = boundary_rows,
    )
end

function boundary_column_candidates(full_model, model, breakdown, worst_column;
                                    sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    case = reduced_case_by_name(breakdown.worst_case)
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
        nlayers = size(pressure_layers, 1)
        column = worst_column.column

        for ig in eachindex(sw_indices), k in 1:nlayers
            pressure = pressure_layers[k, column]
            temperature = temperature_layers[k, column]
            ip0, ip1, wp = active_entry_pressure_bracket(
                full_model.pressure_grid,
                pressure,
            )
            it0, it1, wt = active_entry_temperature_corners(
                full_model,
                pressure,
                temperature,
                ip0,
                ip1,
                wp,
            )
            for (pressure_index, pressure_weight) in ((ip0, 1.0 - wp), (ip1, wp))
                for (temperature_index, temperature_weight) in
                    ((it0, 1.0 - wt), (it1, wt))
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
                        priority =
                            abs(amount) * interpolation_weight *
                            abs(model.shortwave_weights[ig])
                        priority <= 0 && continue
                        key = ("static_absorption", ig, sw_indices[ig], gas_index,
                               pressure_index, temperature_index, 0)
                        active_entry_candidate_push!(scores, key, priority)
                    end
                    if length(full_model.shortwave_h2o_absorption) != 0 &&
                       haskey(gases, :h2o)
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
                        for (h2o_index, h2o_weight) in ((ih0, 1.0 - wh), (ih1, wh))
                            priority =
                                h2o_moles * interpolation_weight * h2o_weight *
                                abs(model.shortwave_weights[ig])
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

function boundary_column_refinement_result()
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
        method = "boundary-column refinement base breakdown",
    )
    target_breakdown = boundary_column_target_breakdown(base_full_breakdown)
    worst_column = boundary_column_worst_column(base_model, target_breakdown)
    ranked_candidates = boundary_column_candidates(
        full_model,
        base_model,
        target_breakdown,
        worst_column,
    )
    candidates = collect(
        Iterators.take(ranked_candidates, boundary_column_candidate_limit()),
    )
    rows = NamedTuple[]
    for candidate in candidates
        for step in boundary_column_steps()
            for direction in (-1.0, 1.0)
                move = (
                    component = candidate.component,
                    local_gpoint_index = candidate.local_gpoint_index,
                    gpoint = candidate.gpoint,
                    gas_index = candidate.gas_index,
                    pressure_index = candidate.pressure_index,
                    temperature_index = candidate.temperature_index,
                    h2o_index = candidate.h2o_index,
                    log_scale = direction * step,
                    scale = exp(direction * step),
                    priority = candidate.priority,
                )
                candidate_model = table_moved_weighted_model(
                    full_model,
                    parameters,
                    pressure_moves,
                    vcat(active_moves, [move]),
                    base_model.shortwave_weights,
                )
                candidate_breakdown = final_objective_breakdown_from_model(
                    candidate_model;
                    method = "boundary-column refinement candidate breakdown",
                )
                push!(rows, (
                    candidate = candidate,
                    step = step,
                    direction = direction < 0 ? "negative" : "positive",
                    objective = candidate_breakdown.objective,
                    improvement =
                        base_full_breakdown.objective - candidate_breakdown.objective,
                    move = move,
                    candidate_breakdown = candidate_breakdown,
                ))
            end
        end
    end
    isempty(rows) && error("no boundary-column candidates were evaluated")
    best = argmin(row -> row.objective, rows)
    accepted = best.objective < base_full_breakdown.objective
    accepted_moves = accepted ? [best.move] : NamedTuple[]
    return (
        case = "reduced_ecckd_boundary_column_refinement",
        status = "preflight_ready",
        target_case = target_breakdown.worst_case,
        target_metric = target_breakdown.worst_metric,
        target_boundary = worst_column.boundary,
        target_column = worst_column.column,
        target_residual_w_m2 = worst_column.residual_w_m2,
        target_normalized_residual = worst_column.normalized_residual,
        pressure_move_count = length(pressure_moves),
        starting_active_move_count = length(active_moves),
        ranked_candidate_count = length(ranked_candidates),
        evaluated_candidate_count = length(candidates),
        evaluated_trial_count = length(rows),
        steps = boundary_column_steps(),
        base_objective = base_full_breakdown.objective,
        base_boundary_objective = target_breakdown.objective,
        candidate_objective = best.objective,
        final_objective = accepted ? best.objective : base_breakdown.objective,
        objective_reduction = best.improvement,
        accepted = accepted,
        accepted_move_count = length(accepted_moves),
        accepted_moves = accepted_moves,
        all_active_moves = vcat(active_moves, accepted_moves),
        best_direction = best.direction,
        best_step = best.step,
        best_move = best.move,
        base_breakdown = base_full_breakdown,
        target_breakdown = target_breakdown,
        candidate_breakdown = best.candidate_breakdown,
    )
end

function boundary_column_markdown(result)
    lines = String[
        "# Reduced ecCKD Boundary-Column Refinement",
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
        "| Pressure move count | $(result.pressure_move_count) |",
        "| Starting active move count | $(result.starting_active_move_count) |",
        "| Ranked candidate count | $(result.ranked_candidate_count) |",
        "| Evaluated candidate count | $(result.evaluated_candidate_count) |",
        "| Evaluated trial count | $(result.evaluated_trial_count) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Base boundary objective | $(@sprintf("%.12g", result.base_boundary_objective)) |",
        "| Candidate objective | $(@sprintf("%.12g", result.candidate_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Accepted | $(result.accepted) |",
        "| Accepted move count | $(result.accepted_move_count) |",
        "| Best direction | $(result.best_direction) |",
        "| Best step | $(@sprintf("%.12g", result.best_step)) |",
        "",
        "This diagnostic scans active coefficient-table entries that are actually",
        "used by the column producing the current worst boundary forcing error.",
        "It accepts only a move that reduces the full normalized hard-gate",
        "objective across the reduced validation cases.",
    ]
    return join(lines, "\n") * "\n"
end

function write_boundary_column_artifacts(result)
    mkpath(dirname(BOUNDARY_COLUMN_REFINEMENT_JSON))
    write(BOUNDARY_COLUMN_REFINEMENT_JSON, json_object(result) * "\n")
    write(BOUNDARY_COLUMN_REFINEMENT_MD, boundary_column_markdown(result))
    print(boundary_column_markdown(result))
    println("Wrote $BOUNDARY_COLUMN_REFINEMENT_JSON")
    println("Wrote $BOUNDARY_COLUMN_REFINEMENT_MD")
end

function main(; result = nothing)
    write_boundary_column_artifacts(
        result === nothing ? boundary_column_refinement_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
