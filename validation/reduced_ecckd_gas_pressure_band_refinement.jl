include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_slot_blend_refinement.jl"))

const GAS_PRESSURE_BAND_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_gas_pressure_band_refinement.json")
const GAS_PRESSURE_BAND_REFINEMENT_MD =
    validation_results_path("reduced_ecckd_gas_pressure_band_refinement.md")

gas_pressure_band_count() =
    parse(Int, get(ENV, "RH_REDUCED_GAS_PRESSURE_BANDS", "4"))

gas_pressure_band_candidate_limit() =
    parse(Int, get(ENV, "RH_REDUCED_GAS_PRESSURE_BAND_CANDIDATES", "64"))

function gas_pressure_band_steps()
    raw = get(ENV, "RH_REDUCED_GAS_PRESSURE_BAND_STEPS", "0.00390625,0.0078125,0.015625,0.03125")
    return [parse(Float64, strip(token)) for token in split(raw, ",") if !isempty(strip(token))]
end

function apply_gas_pressure_band_move!(model, move)
    scale = exp(clamp(move.log_scale, -5.0, 5.0))
    band = move.pressure_index_start:move.pressure_index_end
    ig = move.local_gpoint_index
    if move.component == "static_absorption"
        model.shortwave_absorption[ig, move.gas_index, band, :] .*= scale
    elseif move.component == "dynamic_h2o"
        if length(model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[ig, band, :, :] .*= scale
        end
    else
        throw(ArgumentError("unsupported gas pressure-band component $(move.component)"))
    end
    return model
end

function apply_gas_pressure_band_moves!(model, moves)
    for move in moves
        apply_gas_pressure_band_move!(model, move)
    end
    return model
end

function gas_pressure_band_base_model(full_model)
    model = slot_blend_model(full_model, NamedTuple[]; include_existing = true)
    apply_gas_pressure_band_refinement_moves!(
        model,
        latest_gas_pressure_band_refinement_moves(),
    )
    return model
end

function gas_pressure_band_candidates(full_model, base_model, target_breakdown,
                                      worst_column)
    case = reduced_case_by_name(target_breakdown.worst_case)
    bands = pressure_bands(length(full_model.pressure_grid), gas_pressure_band_count())
    nc = require_ncdatasets()
    scores = Dict{Tuple, Float64}()
    nc.NCDataset(reference_path(case.path)) do dataset
        pressure_layers = Array(dataset["pressure_layer"])
        pressure_interfaces = Array(dataset["pressure_interface"])
        gas_amounts = gas_column_amounts(dataset, pressure_interfaces).amounts
        gases = Dict(Symbol(name) => values for (name, values) in gas_amounts)
        gas_names_tuple = NumericalRadiation.gas_names(full_model)
        references = full_model.gas_reference_mole_fractions
        column = worst_column.column
        nlayers = size(pressure_layers, 1)
        for ig in axes(base_model.shortwave_absorption, 1), k in 1:nlayers
            pressure = pressure_layers[k, column]
            ip0, ip1, wp = active_entry_pressure_bracket(
                full_model.pressure_grid,
                pressure,
            )
            for (pressure_index, pressure_weight) in ((ip0, 1.0 - wp), (ip1, wp))
                band_index = findfirst(band -> pressure_index in band, bands)
                band_index === nothing && continue
                band = bands[band_index]
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
                        abs(amount) * pressure_weight * abs(base_model.shortwave_weights[ig])
                    priority <= 0 && continue
                    key = (
                        "static_absorption",
                        ig,
                        WEIGHTED_GREEDY_SW_16_INDICES[ig],
                        gas_index,
                        first(band),
                        last(band),
                    )
                    scores[key] = get(scores, key, 0.0) + priority
                end
                if length(full_model.shortwave_h2o_absorption) != 0 &&
                   haskey(gases, :h2o)
                    h2o_moles = max(gases[:h2o][k, column], 0.0)
                    priority =
                        h2o_moles * pressure_weight * abs(base_model.shortwave_weights[ig])
                    priority <= 0 && continue
                    key = (
                        "dynamic_h2o",
                        ig,
                        WEIGHTED_GREEDY_SW_16_INDICES[ig],
                        0,
                        first(band),
                        last(band),
                    )
                    scores[key] = get(scores, key, 0.0) + priority
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
            pressure_index_start = key[5],
            pressure_index_end = key[6],
            priority = priority,
        )
        for (key, priority) in ranked
    ]
end

function gas_pressure_band_refinement_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = gas_pressure_band_base_model(full_model)
    base_full_breakdown = final_objective_breakdown_from_model(
        base_model;
        method = "gas pressure-band refinement base breakdown",
    )
    target_breakdown = boundary_column_target_breakdown(base_full_breakdown)
    worst_column = boundary_column_worst_column(base_model, target_breakdown)
    candidates = gas_pressure_band_candidates(
        full_model,
        base_model,
        target_breakdown,
        worst_column,
    )
    selected = collect(
        Iterators.take(candidates, gas_pressure_band_candidate_limit()),
    )
    rows = NamedTuple[]
    for candidate in selected
        for step in gas_pressure_band_steps()
            for direction in (-1.0, 1.0)
                move = (
                    component = candidate.component,
                    local_gpoint_index = candidate.local_gpoint_index,
                    gpoint = candidate.gpoint,
                    gas_index = candidate.gas_index,
                    pressure_index_start = candidate.pressure_index_start,
                    pressure_index_end = candidate.pressure_index_end,
                    log_scale = direction * step,
                    scale = exp(direction * step),
                    priority = candidate.priority,
                )
                model = gas_pressure_band_base_model(full_model)
                apply_gas_pressure_band_move!(model, move)
                breakdown = final_objective_breakdown_from_model(
                    model;
                    method = "gas pressure-band refinement candidate breakdown",
                )
                push!(rows, (
                    candidate = candidate,
                    step = step,
                    direction = direction < 0 ? "negative" : "positive",
                    objective = breakdown.objective,
                    improvement = base_full_breakdown.objective - breakdown.objective,
                    move = move,
                    candidate_breakdown = breakdown,
                ))
            end
        end
    end
    isempty(rows) && error("no gas pressure-band candidates were evaluated")
    best = argmin(row -> row.objective, rows)
    accepted = best.objective < base_full_breakdown.objective
    accepted_moves = accepted ? [best.move] : NamedTuple[]
    all_moves = vcat(latest_gas_pressure_band_refinement_moves(), accepted_moves)
    return (
        case = "reduced_ecckd_gas_pressure_band_refinement",
        status = "preflight_ready",
        target_case = target_breakdown.worst_case,
        target_metric = target_breakdown.worst_metric,
        target_boundary = worst_column.boundary,
        target_column = worst_column.column,
        target_residual_w_m2 = worst_column.residual_w_m2,
        pressure_band_count = gas_pressure_band_count(),
        ranked_candidate_count = length(candidates),
        evaluated_candidate_count = length(selected),
        evaluated_trial_count = length(rows),
        steps = gas_pressure_band_steps(),
        base_objective = base_full_breakdown.objective,
        base_boundary_objective = target_breakdown.objective,
        candidate_objective = best.objective,
        final_objective = accepted ? best.objective : base_full_breakdown.objective,
        objective_reduction = best.improvement,
        accepted = accepted,
        accepted_move_count = length(accepted_moves),
        accepted_moves = accepted_moves,
        all_moves = all_moves,
        best_component = best.move.component,
        best_local_gpoint_index = best.move.local_gpoint_index,
        best_gpoint = best.move.gpoint,
        best_gas_index = best.move.gas_index,
        best_pressure_index_start = best.move.pressure_index_start,
        best_pressure_index_end = best.move.pressure_index_end,
        best_step = best.step,
        best_direction = best.direction,
        base_breakdown = base_full_breakdown,
        target_breakdown = target_breakdown,
        candidate_breakdown = best.candidate_breakdown,
    )
end

function gas_pressure_band_markdown(result)
    lines = String[
        "# Reduced ecCKD Gas Pressure-Band Refinement",
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
        "| Pressure-band count | $(result.pressure_band_count) |",
        "| Ranked candidate count | $(result.ranked_candidate_count) |",
        "| Evaluated candidate count | $(result.evaluated_candidate_count) |",
        "| Evaluated trial count | $(result.evaluated_trial_count) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Base boundary objective | $(@sprintf("%.12g", result.base_boundary_objective)) |",
        "| Candidate objective | $(@sprintf("%.12g", result.candidate_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Accepted | $(result.accepted) |",
        "| Accepted move count | $(result.accepted_move_count) |",
        "| Best component | $(result.best_component) |",
        "| Best local g-point index | $(result.best_local_gpoint_index) |",
        "| Best official g-point | $(result.best_gpoint) |",
        "| Best gas index | $(result.best_gas_index) |",
        "| Best pressure range | $(result.best_pressure_index_start):$(result.best_pressure_index_end) |",
        "| Best direction | $(result.best_direction) |",
        "| Best step | $(@sprintf("%.12g", result.best_step)) |",
        "",
        "This diagnostic applies one nonnegative gas-specific pressure-band scale",
        "to the current reduced shortwave table and accepts only if the nonlinear",
        "hard-gate objective improves.",
    ]
    return join(lines, "\n") * "\n"
end

function write_gas_pressure_band_artifacts(result)
    mkpath(dirname(GAS_PRESSURE_BAND_REFINEMENT_JSON))
    write(GAS_PRESSURE_BAND_REFINEMENT_JSON, json_object(result) * "\n")
    write(GAS_PRESSURE_BAND_REFINEMENT_MD, gas_pressure_band_markdown(result))
    print(gas_pressure_band_markdown(result))
    println("Wrote $GAS_PRESSURE_BAND_REFINEMENT_JSON")
    println("Wrote $GAS_PRESSURE_BAND_REFINEMENT_MD")
end

function main(; result = nothing)
    write_gas_pressure_band_artifacts(
        result === nothing ? gas_pressure_band_refinement_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
