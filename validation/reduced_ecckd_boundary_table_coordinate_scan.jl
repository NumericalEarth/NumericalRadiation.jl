include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const BOUNDARY_TABLE_COORDINATE_SCAN_JSON =
    validation_results_path("reduced_ecckd_boundary_table_coordinate_scan.json")
const BOUNDARY_TABLE_COORDINATE_SCAN_MD =
    validation_results_path("reduced_ecckd_boundary_table_coordinate_scan.md")

boundary_table_coordinate_candidate_limit() =
    parse(Int, get(ENV, "RH_BOUNDARY_TABLE_COORDINATE_CANDIDATES", "64"))

boundary_table_coordinate_include_rayleigh() =
    lowercase(get(ENV, "RH_BOUNDARY_TABLE_COORDINATE_INCLUDE_RAYLEIGH", "false")) in
    ("1", "true", "yes")

function boundary_table_coordinate_steps()
    raw = get(ENV, "RH_BOUNDARY_TABLE_COORDINATE_STEPS",
              "0.0009765625,0.001953125,0.00390625,0.0078125")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function boundary_table_coordinate_candidates(full_model)
    candidates = all_global_active_table_entry_candidates(full_model)
    limit = min(boundary_table_coordinate_candidate_limit(), length(candidates))
    if !boundary_table_coordinate_include_rayleigh()
        return first(candidates, limit)
    end
    table_candidates = [candidate for candidate in candidates
                        if candidate.component != "rayleigh"]
    rayleigh_candidates = [candidate for candidate in candidates
                           if candidate.component == "rayleigh"]
    return vcat(first(table_candidates, min(limit, length(table_candidates))),
                rayleigh_candidates)
end

function boundary_table_coordinate_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    base_mode = "boundary_base_table"
    base_model = current_constrained_table_model(full_model; base_mode)
    base_objective, base_cases = full_hard_objective(base_model)
    base_breakdown = final_objective_breakdown_from_model(
        base_model;
        method = "boundary-table coordinate scan base",
    )
    candidates = boundary_table_coordinate_candidates(full_model)
    rows = NamedTuple[]
    for candidate in candidates
        for step in boundary_table_coordinate_steps()
            for direction in (-1.0, 1.0)
                move = move_with_log_scale(candidate, direction * step)
                model = current_constrained_table_model(
                    full_model,
                    [move];
                    base_mode,
                )
                objective, cases = full_hard_objective(model)
                push!(rows, (
                    component = move.component,
                    local_gpoint_index = move.local_gpoint_index,
                    gpoint = move.gpoint,
                    gas_index = move.gas_index,
                    pressure_index = move.pressure_index,
                    temperature_index = move.temperature_index,
                    h2o_index = move.h2o_index,
                    log_scale = move.log_scale,
                    step = step,
                    direction = direction < 0 ? "negative" : "positive",
                    objective = objective,
                    improvement = base_objective - objective,
                    worst_toa_forcing_error_w_m2 =
                        maximum(case.toa_forcing_max_abs for case in cases),
                    worst_surface_forcing_error_w_m2 =
                        maximum(case.surface_forcing_max_abs for case in cases),
                    move = move,
                ))
            end
        end
    end
    isempty(rows) && error("no boundary-table coordinate candidates evaluated")
    best = argmin(row -> row.objective, rows)
    accepted = best.objective < base_objective
    return (
        case = "reduced_ecckd_boundary_table_coordinate_scan",
        status = accepted ? "coordinate_scan_improved" : "coordinate_scan_rejected",
        base_mode = base_mode,
        include_rayleigh = boundary_table_coordinate_include_rayleigh(),
        candidate_count = length(candidates),
        trial_count = length(rows),
        steps = boundary_table_coordinate_steps(),
        base_objective = base_objective,
        base_worst_case = base_breakdown.worst_case,
        base_worst_metric = base_breakdown.worst_metric,
        base_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in base_cases),
        base_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in base_cases),
        best_objective = best.objective,
        best_objective_reduction = best.improvement,
        best_worst_toa_forcing_error_w_m2 = best.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 = best.worst_surface_forcing_error_w_m2,
        accepted = accepted,
        accepted_move = accepted ? best.move : nothing,
        accepted_moves = accepted ? [best.move] : NamedTuple[],
        best = best,
    )
end

function boundary_table_coordinate_scan_markdown(result)
    lines = String[
        "# Reduced ecCKD Boundary-Table Coordinate Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base mode | $(result.base_mode) |",
        "| Include Rayleigh candidates | $(result.include_rayleigh) |",
        "| Candidates | $(result.candidate_count) |",
        "| Trials | $(result.trial_count) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Best objective | $(@sprintf("%.12g", result.best_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Base TOA forcing error | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best TOA forcing error | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing error | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing error | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Accepted | $(result.accepted) |",
        "",
        "This exact coordinate scan starts from the retained boundary-table",
        "base table model and evaluates one active table-entry scale at a time",
        "against the full hard objective.",
    ]
    return join(lines, "\n") * "\n"
end

function main()
    result = boundary_table_coordinate_scan_result()
    mkpath(dirname(BOUNDARY_TABLE_COORDINATE_SCAN_JSON))
    write(BOUNDARY_TABLE_COORDINATE_SCAN_JSON, json_object(result) * "\n")
    write(BOUNDARY_TABLE_COORDINATE_SCAN_MD,
          boundary_table_coordinate_scan_markdown(result))
    print(boundary_table_coordinate_scan_markdown(result))
    println("Wrote $BOUNDARY_TABLE_COORDINATE_SCAN_JSON")
    println("Wrote $BOUNDARY_TABLE_COORDINATE_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
