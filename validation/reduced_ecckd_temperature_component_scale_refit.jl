include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_pressure_component_scale_refit.jl"))

const TEMPERATURE_COMPONENT_SCALE_REFIT_JSON =
    validation_results_path("reduced_ecckd_temperature_component_scale_refit.json")
const TEMPERATURE_COMPONENT_SCALE_REFIT_MD =
    validation_results_path("reduced_ecckd_temperature_component_scale_refit.md")

temperature_component_band_count() =
    parse(Int, get(ENV, "RH_REDUCED_TEMPERATURE_COMPONENT_BANDS", "8"))

temperature_component_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_TEMPERATURE_COMPONENT_ITERATIONS", "2"))

function temperature_component_steps()
    raw = get(ENV, "RH_REDUCED_TEMPERATURE_COMPONENT_STEPS",
              "0.00390625,0.0078125,0.015625,0.03125,0.0625,0.125")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function temperature_component_gpoints()
    raw = strip(get(ENV, "RH_REDUCED_TEMPERATURE_COMPONENT_GPOINTS", ""))
    if !isempty(raw)
        return sort(unique(parse(Int, strip(token)) for token in split(raw, ",")
                           if !isempty(strip(token))))
    end
    pressure_moves = latest_pressure_component_scale_refit_moves()
    pressure_selected = sort(unique(move.local_gpoint_index for move in pressure_moves))
    !isempty(pressure_selected) && return pressure_selected
    component_moves = latest_component_scale_refit_moves()
    selected = sort(unique(move.local_gpoint_index for move in component_moves
                           if move.component in ("static_absorption", "h2o_absorption")))
    return isempty(selected) ? collect(1:length(WEIGHTED_GREEDY_SW_16_INDICES)) : selected
end

function temperature_component_base_model(full_model)
    model = pressure_component_base_model(full_model)
    apply_pressure_component_moves!(model, latest_pressure_component_scale_refit_moves())
    return model
end

function temperature_bands(ntemperature, nband)
    return pressure_bands(ntemperature, nband)
end

function temperature_component_move(component, local_gpoint_index, temperature_range, log_scale)
    return (
        component = component,
        local_gpoint_index = local_gpoint_index,
        temperature_index_start = first(temperature_range),
        temperature_index_end = last(temperature_range),
        log_scale = log_scale,
        scale = exp(log_scale),
    )
end

function apply_temperature_component_move!(model, move)
    scale = exp(clamp(move.log_scale, -5.0, 5.0))
    band = move.temperature_index_start:move.temperature_index_end
    ig = move.local_gpoint_index
    if move.component == "static_absorption"
        model.shortwave_absorption[ig, :, :, band] .*= scale
    elseif move.component == "h2o_absorption"
        if length(model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[ig, :, band, :] .*= scale
        end
    else
        throw(ArgumentError("unsupported temperature component $(move.component)"))
    end
    return model
end

function apply_temperature_component_moves!(model, moves)
    for move in moves
        apply_temperature_component_move!(model, move)
    end
    return model
end

function temperature_component_trial(full_model, moves)
    model = temperature_component_base_model(full_model)
    apply_temperature_component_moves!(model, moves)
    objective, cases = full_hard_objective(model)
    return objective, cases
end

function temperature_component_candidates(full_model)
    ntemperature = size(full_model.shortwave_absorption, 4)
    bands = temperature_bands(ntemperature, temperature_component_band_count())
    rows = NamedTuple[]
    for ig in temperature_component_gpoints()
        for component in ("static_absorption", "h2o_absorption")
            for band in bands
                push!(rows, (
                    component = component,
                    local_gpoint_index = ig,
                    temperature_range = band,
                ))
            end
        end
    end
    return rows
end

function temperature_component_scan(full_model, accepted_moves, base_objective)
    rows = NamedTuple[]
    for candidate in temperature_component_candidates(full_model)
        for step in temperature_component_steps()
            for direction in (-1.0, 1.0)
                move = temperature_component_move(
                    candidate.component,
                    candidate.local_gpoint_index,
                    candidate.temperature_range,
                    direction * step,
                )
                objective, cases = temperature_component_trial(
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

function temperature_component_scale_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    base_model = temperature_component_base_model(full_model)
    base_objective, base_cases = full_hard_objective(base_model)
    accepted_moves = NamedTuple[]
    iterations = NamedTuple[]
    current_objective = base_objective
    current_cases = base_cases

    for iteration in 1:temperature_component_iterations()
        rows, best =
            temperature_component_scan(full_model, accepted_moves, current_objective)
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
        current_cases = temperature_component_trial(full_model, accepted_moves)[2]
    end

    return (
        case = "reduced_ecckd_temperature_component_scale_refit",
        status = isempty(accepted_moves) ? "temperature_component_scale_refit_rejected" :
                 "temperature_component_scale_refit_improved",
        base_mode = "pressure_component_scale_refit",
        temperature_band_count = temperature_component_band_count(),
        selected_gpoints = temperature_component_gpoints(),
        steps = temperature_component_steps(),
        iteration_limit = temperature_component_iterations(),
        completed_iterations = length(iterations),
        candidate_count = length(temperature_component_candidates(full_model)),
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

function temperature_component_scale_refit_markdown(result)
    lines = String[
        "# Reduced ecCKD Temperature-Component Scale Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base mode | $(result.base_mode) |",
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
        "This diagnostic starts from the retained pressure-component model and",
        "exact-coordinate scans temperature-band scales for static and H2O",
        "shortwave absorption on the g-points selected by previous component",
        "scale refits.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? temperature_component_scale_refit_result() : result
    mkpath(dirname(TEMPERATURE_COMPONENT_SCALE_REFIT_JSON))
    write(TEMPERATURE_COMPONENT_SCALE_REFIT_JSON, json_object(result) * "\n")
    write(TEMPERATURE_COMPONENT_SCALE_REFIT_MD,
          temperature_component_scale_refit_markdown(result))
    print(temperature_component_scale_refit_markdown(result))
    println("Wrote $TEMPERATURE_COMPONENT_SCALE_REFIT_JSON")
    println("Wrote $TEMPERATURE_COMPONENT_SCALE_REFIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
