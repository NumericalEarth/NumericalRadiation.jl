include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_h2o_pressure_temperature_component_scale_refit.jl"))

const MIXED_PRESSURE_TEMPERATURE_COMPONENT_REFIT_JSON =
    validation_results_path("reduced_ecckd_mixed_pressure_temperature_component_refit.json")
const MIXED_PRESSURE_TEMPERATURE_COMPONENT_REFIT_MD =
    validation_results_path("reduced_ecckd_mixed_pressure_temperature_component_refit.md")

mixed_pressure_temperature_component_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_MIXED_PT_COMPONENT_ITERATIONS", "1"))

mixed_pressure_temperature_component_pressure_bands() =
    parse(Int, get(ENV, "RH_REDUCED_MIXED_PT_COMPONENT_PRESSURE_BANDS", "2"))

mixed_pressure_temperature_component_temperature_bands() =
    parse(Int, get(ENV, "RH_REDUCED_MIXED_PT_COMPONENT_TEMPERATURE_BANDS", "2"))

mixed_pressure_temperature_component_h2o_bands() =
    parse(Int, get(ENV, "RH_REDUCED_MIXED_PT_COMPONENT_H2O_BANDS", "2"))

function mixed_pressure_temperature_component_steps()
    raw = get(ENV, "RH_REDUCED_MIXED_PT_COMPONENT_STEPS",
              "0.00390625,0.0078125,0.015625,0.03125,0.0625,0.125")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function parse_int_list_env(key, fallback)
    raw = strip(get(ENV, key, ""))
    isempty(raw) && return fallback
    return sort(unique(parse(Int, strip(token)) for token in split(raw, ",")
                       if !isempty(strip(token))))
end

mixed_static_gpoints() =
    parse_int_list_env("RH_REDUCED_MIXED_PT_STATIC_GPOINTS", [14])

mixed_static_gas_indices() =
    parse_int_list_env("RH_REDUCED_MIXED_PT_STATIC_GAS_INDICES", [3])

mixed_h2o_gpoints() =
    parse_int_list_env("RH_REDUCED_MIXED_PT_H2O_GPOINTS", [2])

function latest_h2o_pressure_temperature_component_scale_refit_moves(;
                                                                     path =
                                                                        H2O_PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    moves_match = Base.match(
        r"\"accepted_moves\"\s*:\s*\[([\s\S]*?)\]\s*,\s*\"iterations\"",
        text,
    )
    moves_match === nothing && return NamedTuple[]
    moves_text = moves_match.captures[1]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_text)
        object = match.captures[1]
        component_match = Base.match(r"\"component\"\s*:\s*\"([^\"]+)\"", object)
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        pressure_start_match =
            Base.match(r"\"pressure_index_start\"\s*:\s*([0-9]+)", object)
        pressure_end_match =
            Base.match(r"\"pressure_index_end\"\s*:\s*([0-9]+)", object)
        temperature_start_match =
            Base.match(r"\"temperature_index_start\"\s*:\s*([0-9]+)", object)
        temperature_end_match =
            Base.match(r"\"temperature_index_end\"\s*:\s*([0-9]+)", object)
        h2o_start_match =
            Base.match(r"\"h2o_index_start\"\s*:\s*([0-9]+)", object)
        h2o_end_match =
            Base.match(r"\"h2o_index_end\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if component_match === nothing ||
           local_match === nothing ||
           pressure_start_match === nothing ||
           pressure_end_match === nothing ||
           temperature_start_match === nothing ||
           temperature_end_match === nothing ||
           h2o_start_match === nothing ||
           h2o_end_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = component_match.captures[1],
            local_gpoint_index = parse(Int, local_match.captures[1]),
            pressure_index_start = parse(Int, pressure_start_match.captures[1]),
            pressure_index_end = parse(Int, pressure_end_match.captures[1]),
            temperature_index_start = parse(Int, temperature_start_match.captures[1]),
            temperature_index_end = parse(Int, temperature_end_match.captures[1]),
            h2o_index_start = parse(Int, h2o_start_match.captures[1]),
            h2o_index_end = parse(Int, h2o_end_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function mixed_pressure_temperature_component_base_model(full_model)
    model = h2o_pressure_temperature_component_base_model(full_model)
    apply_h2o_pressure_temperature_component_moves!(
        model,
        latest_h2o_pressure_temperature_component_scale_refit_moves(),
    )
    return model
end

function mixed_static_move(local_gpoint_index, gas_index, pressure_range,
                           temperature_range, log_scale)
    return (
        component = "static_absorption",
        local_gpoint_index = local_gpoint_index,
        gas_index = gas_index,
        pressure_index_start = first(pressure_range),
        pressure_index_end = last(pressure_range),
        temperature_index_start = first(temperature_range),
        temperature_index_end = last(temperature_range),
        h2o_index_start = 0,
        h2o_index_end = 0,
        log_scale = log_scale,
        scale = exp(log_scale),
    )
end

function mixed_h2o_move(local_gpoint_index, pressure_range, temperature_range,
                        h2o_range, log_scale)
    return (
        component = "h2o_absorption",
        local_gpoint_index = local_gpoint_index,
        gas_index = 0,
        pressure_index_start = first(pressure_range),
        pressure_index_end = last(pressure_range),
        temperature_index_start = first(temperature_range),
        temperature_index_end = last(temperature_range),
        h2o_index_start = first(h2o_range),
        h2o_index_end = last(h2o_range),
        log_scale = log_scale,
        scale = exp(log_scale),
    )
end

function apply_mixed_pressure_temperature_component_move!(model, move)
    scale = exp(clamp(move.log_scale, -5.0, 5.0))
    pressure_range = move.pressure_index_start:move.pressure_index_end
    temperature_range = move.temperature_index_start:move.temperature_index_end
    if move.component == "static_absorption"
        model.shortwave_absorption[
            move.local_gpoint_index,
            move.gas_index,
            pressure_range,
            temperature_range,
        ] .*= scale
    elseif move.component == "h2o_absorption"
        length(model.shortwave_h2o_absorption) == 0 && return model
        model.shortwave_h2o_absorption[
            move.local_gpoint_index,
            pressure_range,
            temperature_range,
            move.h2o_index_start:move.h2o_index_end,
        ] .*= scale
    else
        throw(ArgumentError("unsupported mixed component $(move.component)"))
    end
    return model
end

function apply_mixed_pressure_temperature_component_moves!(model, moves)
    for move in moves
        apply_mixed_pressure_temperature_component_move!(model, move)
    end
    return model
end

function mixed_pressure_temperature_component_trial(full_model, moves)
    model = mixed_pressure_temperature_component_base_model(full_model)
    apply_mixed_pressure_temperature_component_moves!(model, moves)
    _, cases = full_hard_objective(model)
    objective = maximum(normalized_case_objective, cases)
    return objective, cases
end

function mixed_pressure_temperature_component_candidates(full_model)
    pressure_ranges = pressure_bands(
        length(full_model.pressure_grid),
        mixed_pressure_temperature_component_pressure_bands(),
    )
    temperature_ranges = temperature_bands(
        size(full_model.shortwave_absorption, 4),
        mixed_pressure_temperature_component_temperature_bands(),
    )
    h2o_ranges = length(full_model.shortwave_h2o_absorption) == 0 ?
        UnitRange{Int}[] :
        pressure_bands(
            size(full_model.shortwave_h2o_absorption, 4),
            mixed_pressure_temperature_component_h2o_bands(),
        )
    rows = NamedTuple[]
    for ig in mixed_static_gpoints(), gas_index in mixed_static_gas_indices()
        for pressure_range in pressure_ranges, temperature_range in temperature_ranges
            push!(rows, (
                component = "static_absorption",
                local_gpoint_index = ig,
                gas_index = gas_index,
                pressure_range = pressure_range,
                temperature_range = temperature_range,
                h2o_range = 0:0,
            ))
        end
    end
    for ig in mixed_h2o_gpoints()
        for pressure_range in pressure_ranges,
            temperature_range in temperature_ranges,
            h2o_range in h2o_ranges

            push!(rows, (
                component = "h2o_absorption",
                local_gpoint_index = ig,
                gas_index = 0,
                pressure_range = pressure_range,
                temperature_range = temperature_range,
                h2o_range = h2o_range,
            ))
        end
    end
    return rows
end

function mixed_pressure_temperature_component_scan(full_model, accepted_moves,
                                                   base_objective)
    rows = NamedTuple[]
    for candidate in mixed_pressure_temperature_component_candidates(full_model)
        for step in mixed_pressure_temperature_component_steps(), direction in (-1.0, 1.0)
            move = candidate.component == "static_absorption" ?
                mixed_static_move(
                    candidate.local_gpoint_index,
                    candidate.gas_index,
                    candidate.pressure_range,
                    candidate.temperature_range,
                    direction * step,
                ) :
                mixed_h2o_move(
                    candidate.local_gpoint_index,
                    candidate.pressure_range,
                    candidate.temperature_range,
                    candidate.h2o_range,
                    direction * step,
                )
            objective, cases = mixed_pressure_temperature_component_trial(
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
    isempty(rows) && return rows, nothing
    best = argmin(row -> row.objective, rows)
    return rows, best
end

function mixed_pressure_temperature_component_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    base_model = mixed_pressure_temperature_component_base_model(full_model)
    base_objective, base_cases = full_hard_objective(base_model)
    accepted_moves = NamedTuple[]
    iterations = NamedTuple[]
    current_objective = base_objective
    current_cases = base_cases

    for iteration in 1:mixed_pressure_temperature_component_iterations()
        rows, best = mixed_pressure_temperature_component_scan(
            full_model,
            accepted_moves,
            current_objective,
        )
        best === nothing && break
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
        current_cases = mixed_pressure_temperature_component_trial(
            full_model,
            accepted_moves,
        )[2]
    end

    return (
        case = "reduced_ecckd_mixed_pressure_temperature_component_refit",
        status = isempty(accepted_moves) ?
            "mixed_pressure_temperature_component_refit_rejected" :
            "mixed_pressure_temperature_component_refit_improved",
        base_mode = "h2o_pressure_temperature_component_scale_refit",
        candidate_count = length(mixed_pressure_temperature_component_candidates(full_model)),
        iteration_limit = mixed_pressure_temperature_component_iterations(),
        completed_iterations = length(iterations),
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

function mixed_pressure_temperature_component_refit_markdown(result)
    lines = String[
        "# Reduced ecCKD Mixed Pressure-Temperature Component Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base mode | $(result.base_mode) |",
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
        "This diagnostic alternates between the static-gas and H2O block families",
        "that improved the current retained reduced model.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ?
        mixed_pressure_temperature_component_refit_result() : result
    mkpath(dirname(MIXED_PRESSURE_TEMPERATURE_COMPONENT_REFIT_JSON))
    write(MIXED_PRESSURE_TEMPERATURE_COMPONENT_REFIT_JSON, json_object(result) * "\n")
    write(MIXED_PRESSURE_TEMPERATURE_COMPONENT_REFIT_MD,
          mixed_pressure_temperature_component_refit_markdown(result))
    print(mixed_pressure_temperature_component_refit_markdown(result))
    println("Wrote $MIXED_PRESSURE_TEMPERATURE_COMPONENT_REFIT_JSON")
    println("Wrote $MIXED_PRESSURE_TEMPERATURE_COMPONENT_REFIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
