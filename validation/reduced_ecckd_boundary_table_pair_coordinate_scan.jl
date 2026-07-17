include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_boundary_table_coordinate_scan.jl"))

const BOUNDARY_TABLE_PAIR_COORDINATE_SCAN_JSON =
    validation_results_path("reduced_ecckd_boundary_table_pair_coordinate_scan.json")
const BOUNDARY_TABLE_PAIR_COORDINATE_SCAN_MD =
    validation_results_path("reduced_ecckd_boundary_table_pair_coordinate_scan.md")

boundary_table_pair_single_limit() =
    parse(Int, get(ENV, "RH_BOUNDARY_TABLE_PAIR_SINGLE_LIMIT", "16"))

boundary_table_pair_trial_limit() =
    parse(Int, get(ENV, "RH_BOUNDARY_TABLE_PAIR_TRIAL_LIMIT", "512"))

function boundary_table_single_trial_rows(full_model, base_mode, base_objective)
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
                    move = move,
                    objective = objective,
                    improvement = base_objective - objective,
                    worst_toa_forcing_error_w_m2 =
                        maximum(case.toa_forcing_max_abs for case in cases),
                    worst_surface_forcing_error_w_m2 =
                        maximum(case.surface_forcing_max_abs for case in cases),
                ))
            end
        end
    end
    sort!(rows; by = row -> (row.objective, row.worst_toa_forcing_error_w_m2))
    return rows
end

function boundary_table_pair_coordinate_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    base_mode = "boundary_table_continuation"
    base_model = current_constrained_table_model(full_model; base_mode)
    base_objective, base_cases = full_hard_objective(base_model)
    singles = boundary_table_single_trial_rows(full_model, base_mode, base_objective)
    selected_singles = first(singles, min(boundary_table_pair_single_limit(),
                                          length(singles)))
    pair_rows = NamedTuple[]
    for i in 1:length(selected_singles)
        for j in (i + 1):length(selected_singles)
            length(pair_rows) >= boundary_table_pair_trial_limit() && break
            moves = [selected_singles[i].move, selected_singles[j].move]
            model = current_constrained_table_model(
                full_model,
                moves;
                base_mode,
            )
            objective, cases = full_hard_objective(model)
            push!(pair_rows, (
                first_move = moves[1],
                second_move = moves[2],
                objective = objective,
                improvement = base_objective - objective,
                worst_toa_forcing_error_w_m2 =
                    maximum(case.toa_forcing_max_abs for case in cases),
                worst_surface_forcing_error_w_m2 =
                    maximum(case.surface_forcing_max_abs for case in cases),
            ))
        end
    end
    isempty(pair_rows) && error("no boundary-table pair candidates evaluated")
    best = argmin(row -> row.objective, pair_rows)
    accepted = best.objective < base_objective
    return (
        case = "reduced_ecckd_boundary_table_pair_coordinate_scan",
        status = accepted ? "pair_coordinate_scan_improved" :
                 "pair_coordinate_scan_rejected",
        base_mode = base_mode,
        include_rayleigh = boundary_table_coordinate_include_rayleigh(),
        single_trial_count = length(singles),
        selected_single_count = length(selected_singles),
        pair_trial_count = length(pair_rows),
        base_objective = base_objective,
        base_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in base_cases),
        base_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in base_cases),
        best_objective = best.objective,
        best_objective_reduction = best.improvement,
        best_worst_toa_forcing_error_w_m2 = best.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 = best.worst_surface_forcing_error_w_m2,
        accepted = accepted,
        accepted_moves = accepted ? [best.first_move, best.second_move] : NamedTuple[],
        best = best,
    )
end

function boundary_table_pair_coordinate_scan_markdown(result)
    lines = String[
        "# Reduced ecCKD Boundary-Table Pair Coordinate Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base mode | $(result.base_mode) |",
        "| Include Rayleigh candidates | $(result.include_rayleigh) |",
        "| Single trials | $(result.single_trial_count) |",
        "| Selected singles | $(result.selected_single_count) |",
        "| Pair trials | $(result.pair_trial_count) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Best objective | $(@sprintf("%.12g", result.best_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Base TOA forcing error | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best TOA forcing error | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing error | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing error | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Accepted | $(result.accepted) |",
        "",
        "This exact pair scan starts from the retained boundary-table continuation",
        "model, ranks exact single-coordinate moves, and evaluates all pairs from",
        "the retained single-move set against the full hard objective.",
    ]
    return join(lines, "\n") * "\n"
end

function main()
    result = boundary_table_pair_coordinate_scan_result()
    mkpath(dirname(BOUNDARY_TABLE_PAIR_COORDINATE_SCAN_JSON))
    write(BOUNDARY_TABLE_PAIR_COORDINATE_SCAN_JSON, json_object(result) * "\n")
    write(BOUNDARY_TABLE_PAIR_COORDINATE_SCAN_MD,
          boundary_table_pair_coordinate_scan_markdown(result))
    print(boundary_table_pair_coordinate_scan_markdown(result))
    println("Wrote $BOUNDARY_TABLE_PAIR_COORDINATE_SCAN_JSON")
    println("Wrote $BOUNDARY_TABLE_PAIR_COORDINATE_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
