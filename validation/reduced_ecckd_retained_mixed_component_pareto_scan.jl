include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_mixed_pressure_temperature_component_refit.jl"))
include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const RETAINED_MIXED_COMPONENT_PARETO_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_mixed_component_pareto_scan.json")
const RETAINED_MIXED_COMPONENT_PARETO_SCAN_MD =
    validation_results_path("reduced_ecckd_retained_mixed_component_pareto_scan.md")

retained_mixed_component_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_RETAINED_MIXED_COMPONENT_ITERATIONS", "1"))

function retained_mixed_component_steps()
    raw = get(ENV, "RH_REDUCED_RETAINED_MIXED_COMPONENT_STEPS",
              "0.000244140625,0.00048828125,0.0009765625,0.001953125,0.00390625,0.0078125")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

retained_mixed_component_pareto_tolerance() =
    parse(Float64, get(ENV, "RH_REDUCED_RETAINED_MIXED_COMPONENT_PARETO_TOLERANCE", "1.0e-12"))

retained_mixed_component_surface_cap() =
    parse(Float64, get(ENV, "RH_REDUCED_RETAINED_MIXED_COMPONENT_SURFACE_CAP", "-1.0"))

retained_mixed_component_acceptance_rule(tolerance, surface_cap) =
    tolerance <= 1.0e-12 ?
    (surface_cap > 0 ? "strict_pareto_surface_cap" : "strict_pareto") :
    (surface_cap > 0 ? "bounded_frontier_surface_cap" : "bounded_frontier")

retained_mixed_static_gpoints() =
    parse_int_list_env("RH_REDUCED_RETAINED_MIXED_STATIC_GPOINTS", [14])

retained_mixed_static_gas_indices() =
    parse_int_list_env("RH_REDUCED_RETAINED_MIXED_STATIC_GAS_INDICES", [3])

retained_mixed_h2o_gpoints() =
    parse_int_list_env("RH_REDUCED_RETAINED_MIXED_H2O_GPOINTS", [2])

function retained_mixed_component_base_model(full_model)
    old_ignore = get(ENV, "RH_REDUCED_IGNORE_RETAINED_MIXED_COMPONENT_PARETO_SCAN", nothing)
    try
        ENV["RH_REDUCED_IGNORE_RETAINED_MIXED_COMPONENT_PARETO_SCAN"] = "true"
        return current_constrained_table_model(
            full_model;
            base_mode = "retained_topology",
            sw_indices = WEIGHTED_GREEDY_SW_16_INDICES,
        )
    finally
        if old_ignore === nothing
            delete!(ENV, "RH_REDUCED_IGNORE_RETAINED_MIXED_COMPONENT_PARETO_SCAN")
        else
            ENV["RH_REDUCED_IGNORE_RETAINED_MIXED_COMPONENT_PARETO_SCAN"] =
                old_ignore
        end
    end
end

function retained_mixed_component_candidates(full_model)
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
    for ig in retained_mixed_static_gpoints(),
        gas_index in retained_mixed_static_gas_indices(),
        pressure_range in pressure_ranges,
        temperature_range in temperature_ranges

        push!(rows, (
            component = "static_absorption",
            local_gpoint_index = ig,
            gas_index = gas_index,
            pressure_range = pressure_range,
            temperature_range = temperature_range,
            h2o_range = 0:0,
        ))
    end
    for ig in retained_mixed_h2o_gpoints(),
        pressure_range in pressure_ranges,
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
    return rows
end

function retained_mixed_component_trial(full_model, moves)
    model = retained_mixed_component_base_model(full_model)
    apply_mixed_pressure_temperature_component_moves!(model, moves)
    return full_hard_objective(model)
end

function retained_mixed_component_scan(full_model, accepted_moves, base_objective,
                                       base_toa, base_surface)
    rows = NamedTuple[]
    for candidate in retained_mixed_component_candidates(full_model)
        for step in retained_mixed_component_steps(), direction in (-1.0, 1.0)
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
            objective, cases = retained_mixed_component_trial(
                full_model,
                vcat(accepted_moves, [move]),
            )
            toa = maximum(case.toa_forcing_max_abs for case in cases)
            surface = maximum(case.surface_forcing_max_abs for case in cases)
            tolerance = retained_mixed_component_pareto_tolerance()
            surface_cap = retained_mixed_component_surface_cap()
            surface_limit = surface_cap > 0 ?
                min(base_surface + tolerance, surface_cap) :
                base_surface + tolerance
            strict_pareto_safe = objective < base_objective &&
                toa <= base_toa + 1.0e-12 &&
                surface <= base_surface + 1.0e-12
            pareto_safe = objective < base_objective &&
                toa <= base_toa + tolerance &&
                surface <= surface_limit
            push!(rows, (
                move = move,
                objective = objective,
                objective_reduction = base_objective - objective,
                worst_toa_forcing_error_w_m2 = toa,
                worst_surface_forcing_error_w_m2 = surface,
                strict_pareto_safe = strict_pareto_safe,
                surface_cap_safe = surface_cap <= 0 || surface <= surface_cap,
                pareto_safe = pareto_safe,
            ))
        end
    end
    isempty(rows) && return rows, nothing
    safe_rows = filter(row -> row.pareto_safe, rows)
    best = isempty(safe_rows) ? argmin(row -> row.objective, rows) :
        argmin(row -> row.objective, safe_rows)
    return rows, best
end

function retained_mixed_component_pareto_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = retained_mixed_component_base_model(full_model)
    base_objective, base_cases = full_hard_objective(base_model)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    accepted_moves = NamedTuple[]
    current_objective = base_objective
    current_cases = base_cases
    iterations = NamedTuple[]
    last_rows = NamedTuple[]

    for iteration in 1:retained_mixed_component_iterations()
        current_toa = maximum(case.toa_forcing_max_abs for case in current_cases)
        current_surface = maximum(case.surface_forcing_max_abs for case in current_cases)
        rows, best = retained_mixed_component_scan(
            full_model,
            accepted_moves,
            current_objective,
            current_toa,
            current_surface,
        )
        last_rows = rows
        best === nothing && break
        accepted = best.pareto_safe
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
            pareto_safe = best.pareto_safe,
            accepted = accepted,
            accepted_move = accepted ? best.move : nothing,
        ))
        accepted || break
        push!(accepted_moves, best.move)
        current_objective, current_cases =
            retained_mixed_component_trial(full_model, accepted_moves)
    end

    final_toa = maximum(case.toa_forcing_max_abs for case in current_cases)
    final_surface = maximum(case.surface_forcing_max_abs for case in current_cases)
    best_any = isempty(last_rows) ? nothing : argmin(row -> row.objective, last_rows)
    return (
        case = "reduced_ecckd_retained_mixed_component_pareto_scan",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = isempty(accepted_moves) ? "retained_mixed_component_scan_rejected" :
                 "retained_mixed_component_scan_improved",
        base_mode = "retained_topology",
        acceptance_rule =
            retained_mixed_component_acceptance_rule(
                retained_mixed_component_pareto_tolerance(),
                retained_mixed_component_surface_cap(),
            ),
        pareto_tolerance = retained_mixed_component_pareto_tolerance(),
        surface_cap_w_m2 = retained_mixed_component_surface_cap(),
        candidate_count = length(retained_mixed_component_candidates(full_model)),
        trial_count = length(last_rows),
        iteration_limit = retained_mixed_component_iterations(),
        completed_iterations = length(iterations),
        base_objective = base_objective,
        final_objective = current_objective,
        objective_reduction = base_objective - current_objective,
        base_worst_toa_forcing_error_w_m2 = base_toa,
        base_worst_surface_forcing_error_w_m2 = base_surface,
        final_worst_toa_forcing_error_w_m2 = final_toa,
        final_worst_surface_forcing_error_w_m2 = final_surface,
        best_exact_objective = best_any === nothing ? base_objective : best_any.objective,
        best_objective_reduction =
            best_any === nothing ? 0.0 : base_objective - best_any.objective,
        best_worst_toa_forcing_error_w_m2 =
            best_any === nothing ? base_toa : best_any.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            best_any === nothing ? base_surface :
            best_any.worst_surface_forcing_error_w_m2,
        any_pareto_safe = !isempty(accepted_moves),
        any_strict_pareto_safe =
            !isempty(last_rows) && any(row -> row.strict_pareto_safe, last_rows),
        any_surface_cap_safe =
            !isempty(last_rows) && any(row -> row.surface_cap_safe, last_rows),
        accepted = !isempty(accepted_moves),
        accepted_moves = accepted_moves,
        iterations = iterations,
    )
end

function retained_mixed_component_pareto_scan_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Mixed Component Pareto Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base mode | $(result.base_mode) |",
        "| Acceptance rule | $(result.acceptance_rule) |",
        "| Forcing-error tolerance | $(@sprintf("%.12g", result.pareto_tolerance)) W m^-2 |",
        "| Surface cap | $(result.surface_cap_w_m2 > 0 ? @sprintf("%.12g W m^-2", result.surface_cap_w_m2) : "disabled") |",
        "| Candidates | $(result.candidate_count) |",
        "| Trials | $(result.trial_count) |",
        "| Iterations | $(result.completed_iterations) / $(result.iteration_limit) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Final objective | $(@sprintf("%.12g", result.final_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Base TOA forcing | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Final TOA forcing | $(@sprintf("%.12g", result.final_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Final surface forcing | $(@sprintf("%.12g", result.final_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Best exact objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best TOA forcing | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Any strict Pareto-safe | $(result.any_strict_pareto_safe) |",
        "| Any surface-cap-safe | $(result.any_surface_cap_safe) |",
        "| Any tolerance Pareto-safe | $(result.any_pareto_safe) |",
        "| Accepted | $(result.accepted) |",
        "| Accepted moves | $(length(result.accepted_moves)) |",
        "",
        "This diagnostic reuses the mixed static/H2O pressure-temperature component",
        "blocks on the fully retained current base. With `strict_pareto`, every",
        "accepted move must reduce the hard objective without increasing TOA or",
        "surface forcing beyond roundoff. With `bounded_frontier`, accepted moves",
        "must still reduce the hard objective while keeping each forcing error",
        "within the configured W m^-2 tolerance of the current iteration base.",
        "If a positive surface cap is configured, accepted moves must also keep",
        "the absolute worst-case surface forcing error at or below that cap.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? retained_mixed_component_pareto_scan_result() :
        result
    mkpath(dirname(RETAINED_MIXED_COMPONENT_PARETO_SCAN_JSON))
    write(RETAINED_MIXED_COMPONENT_PARETO_SCAN_JSON, json_object(result) * "\n")
    write(RETAINED_MIXED_COMPONENT_PARETO_SCAN_MD,
          retained_mixed_component_pareto_scan_markdown(result))
    print(retained_mixed_component_pareto_scan_markdown(result))
    println("Wrote $RETAINED_MIXED_COMPONENT_PARETO_SCAN_JSON")
    println("Wrote $RETAINED_MIXED_COMPONENT_PARETO_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
