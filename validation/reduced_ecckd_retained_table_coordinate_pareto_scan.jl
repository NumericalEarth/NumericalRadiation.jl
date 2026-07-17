include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const RETAINED_TABLE_COORDINATE_PARETO_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_table_coordinate_pareto_scan.json")
const RETAINED_TABLE_COORDINATE_PARETO_SCAN_MD =
    validation_results_path("reduced_ecckd_retained_table_coordinate_pareto_scan.md")

function retained_table_coordinate_candidate_count()
    return parse(Int, get(ENV, "RH_REDUCED_TABLE_COORDINATE_PARETO_CANDIDATES", "64"))
end

function retained_table_coordinate_steps()
    raw = get(ENV, "RH_REDUCED_TABLE_COORDINATE_PARETO_STEPS",
              "0.0001220703125,0.000244140625,0.00048828125,0.0009765625,0.001953125")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function retained_table_coordinate_pool(full_model; sw_indices)
    candidates = all_global_active_table_entry_candidates(full_model; sw_indices)
    return first(candidates, min(retained_table_coordinate_candidate_count(),
                                 length(candidates)))
end

function retained_table_coordinate_pareto_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    sw_indices = WEIGHTED_GREEDY_SW_16_INDICES
    base_mode = "boundary_table_continuation"
    base_model = current_constrained_table_model(
        full_model;
        sw_indices,
        base_mode,
    )
    base_objective, base_cases = full_hard_objective(base_model)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    candidates = retained_table_coordinate_pool(full_model; sw_indices)

    rows = NamedTuple[]
    for candidate in candidates
        for step in retained_table_coordinate_steps(), direction in (-1.0, 1.0)
            move = move_with_log_scale(candidate, direction * step)
            model = current_constrained_table_model(
                full_model,
                [move];
                sw_indices,
                base_mode,
            )
            objective, cases = full_hard_objective(model)
            toa = maximum(case.toa_forcing_max_abs for case in cases)
            surface = maximum(case.surface_forcing_max_abs for case in cases)
            push!(rows, (
                component = candidate.component,
                local_gpoint_index = candidate.local_gpoint_index,
                gpoint = candidate.gpoint,
                gas_index = candidate.gas_index,
                pressure_index = candidate.pressure_index,
                temperature_index = candidate.temperature_index,
                h2o_index = candidate.h2o_index,
                step = step,
                direction = direction < 0 ? "negative" : "positive",
                log_scale = direction * step,
                objective = objective,
                objective_reduction = base_objective - objective,
                toa_forcing_error_w_m2 = toa,
                surface_forcing_error_w_m2 = surface,
                toa_regressed = toa > base_toa,
                surface_regressed = surface > base_surface,
                pareto_safe = objective < base_objective &&
                              toa <= base_toa &&
                              surface <= base_surface,
                move = move,
            ))
        end
    end

    best = argmin(row -> row.objective, rows)
    safe_rows = filter(row -> row.pareto_safe, rows)
    best_safe = isempty(safe_rows) ? nothing : argmin(row -> row.objective, safe_rows)
    accepted = best_safe !== nothing
    return (
        case = "reduced_ecckd_retained_table_coordinate_pareto_scan",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "table_coordinate_pareto_scan_improved" :
                 "table_coordinate_pareto_scan_rejected",
        base_mode = base_mode,
        candidate_count = length(candidates),
        trial_count = length(rows),
        base_objective = base_objective,
        base_worst_toa_forcing_error_w_m2 = base_toa,
        base_worst_surface_forcing_error_w_m2 = base_surface,
        best_objective = best.objective,
        best_objective_reduction = best.objective_reduction,
        best_worst_toa_forcing_error_w_m2 = best.toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 = best.surface_forcing_error_w_m2,
        best_component = best.component,
        best_gpoint = best.gpoint,
        best_local_gpoint_index = best.local_gpoint_index,
        best_gas_index = best.gas_index,
        best_pressure_index = best.pressure_index,
        best_temperature_index = best.temperature_index,
        best_h2o_index = best.h2o_index,
        best_step = best.step,
        best_direction = best.direction,
        best_toa_regressed = best.toa_regressed,
        best_surface_regressed = best.surface_regressed,
        any_pareto_safe = accepted,
        best_safe_objective = accepted ? best_safe.objective : base_objective,
        best_safe_objective_reduction =
            accepted ? best_safe.objective_reduction : 0.0,
        best_safe_worst_toa_forcing_error_w_m2 =
            accepted ? best_safe.toa_forcing_error_w_m2 : base_toa,
        best_safe_worst_surface_forcing_error_w_m2 =
            accepted ? best_safe.surface_forcing_error_w_m2 : base_surface,
        best_safe_move = accepted ? best_safe.move : nothing,
        rows = rows,
    )
end

function retained_table_coordinate_pareto_scan_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Table Coordinate Pareto Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Base TOA forcing | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Candidates | $(result.candidate_count) |",
        "| Trials | $(result.trial_count) |",
        "| Best objective | $(@sprintf("%.12g", result.best_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best TOA forcing | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Best component | $(result.best_component) |",
        "| Best g-point | $(result.best_gpoint) |",
        "| Best move | $(result.best_direction) $(result.best_step) |",
        "| Best TOA regressed | $(result.best_toa_regressed) |",
        "| Best surface regressed | $(result.best_surface_regressed) |",
        "| Any Pareto-safe | $(result.any_pareto_safe) |",
        "| Best Pareto-safe objective | $(@sprintf("%.12g", result.best_safe_objective)) |",
        "| Best Pareto-safe TOA forcing | $(@sprintf("%.12g", result.best_safe_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best Pareto-safe surface forcing | $(@sprintf("%.12g", result.best_safe_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "",
        "This diagnostic evaluates exact one-coordinate nonlinear table moves on",
        "the retained boundary-table-continuation base. A candidate is",
        "Pareto-safe only if it lowers the full hard objective and does not worsen",
        "either worst TOA or worst surface forcing error.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? retained_table_coordinate_pareto_scan_result() :
        result
    mkpath(dirname(RETAINED_TABLE_COORDINATE_PARETO_SCAN_JSON))
    write(RETAINED_TABLE_COORDINATE_PARETO_SCAN_JSON, json_object(result) * "\n")
    write(RETAINED_TABLE_COORDINATE_PARETO_SCAN_MD,
          retained_table_coordinate_pareto_scan_markdown(result))
    print(retained_table_coordinate_pareto_scan_markdown(result))
    println("Wrote $RETAINED_TABLE_COORDINATE_PARETO_SCAN_JSON")
    println("Wrote $RETAINED_TABLE_COORDINATE_PARETO_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
