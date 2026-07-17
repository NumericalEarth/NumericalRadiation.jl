include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_mixed_pressure_temperature_component_refit.jl"))

const RETAINED_TOPOLOGY_NEIGHBOR_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_topology_neighbor_scan.json")
const RETAINED_TOPOLOGY_NEIGHBOR_SCAN_MD =
    validation_results_path("reduced_ecckd_retained_topology_neighbor_scan.md")

retained_topology_neighbor_radius() =
    parse(Int, get(ENV, "RH_REDUCED_RETAINED_TOPOLOGY_RADIUS", "2"))

retained_topology_neighbor_limit() =
    parse(Int, get(ENV, "RH_REDUCED_RETAINED_TOPOLOGY_LIMIT", "0"))

retained_topology_pair_single_limit() =
    parse(Int, get(ENV, "RH_REDUCED_RETAINED_TOPOLOGY_PAIR_SINGLE_LIMIT", "12"))

retained_topology_pair_trial_limit() =
    parse(Int, get(ENV, "RH_REDUCED_RETAINED_TOPOLOGY_PAIR_TRIAL_LIMIT", "256"))

function latest_mixed_pressure_temperature_component_refit_moves(;
                                                                 path =
                                                                    MIXED_PRESSURE_TEMPERATURE_COMPONENT_REFIT_JSON)
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
        gas_match = Base.match(r"\"gas_index\"\s*:\s*([0-9]+)", object)
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
           gas_match === nothing ||
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
            gas_index = parse(Int, gas_match.captures[1]),
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

function retained_topology_neighbor_indices()
    base = collect(WEIGHTED_GREEDY_SW_16_INDICES)
    radius = retained_topology_neighbor_radius()
    rows = NamedTuple[]
    seen = Set{String}()
    for (slot, gpoint) in pairs(base)
        for replacement in max(1, gpoint - radius):min(32, gpoint + radius)
            replacement == gpoint && continue
            replacement in base && continue
            candidate = copy(base)
            candidate[slot] = replacement
            key = join(candidate, ",")
            key in seen && continue
            push!(seen, key)
            push!(rows, (
                slot = slot,
                old_gpoint = gpoint,
                new_gpoint = replacement,
                sw_indices = candidate,
            ))
        end
    end
    limit = retained_topology_neighbor_limit()
    return limit > 0 && length(rows) > limit ? rows[1:limit] : rows
end

function retained_model_for_sw_indices(full_model, sw_indices)
    reduced = indexed_tabulated_model(
        full_model,
        collect(1:size(full_model.longwave_absorption, 1)),
        sw_indices,
    )
    parameters = latest_preflight_reduced_parameters()
    if parameters === nothing
        reduced.shortwave_weights .= normalized_subset(full_model.shortwave_weights, sw_indices)
    else
        apply_weight_absorption_rayleigh_parameters!(reduced, parameters)
    end
    apply_pressure_band_table_moves!(reduced, latest_preflight_pressure_band_table_moves())
    apply_active_table_entry_moves!(reduced, best_available_active_table_entry_moves())
    apply_best_exact_weight_refit!(reduced)
    apply_gas_pressure_band_refinement_moves!(
        reduced,
        latest_gas_pressure_band_refinement_moves(),
    )
    apply_active_table_entry_moves!(reduced, latest_constrained_table_optimizer_moves())
    apply_post_constrained_weight_refit!(reduced)
    apply_slot_blend_refinement_moves!(reduced, full_model, latest_slot_blend_refinement_moves())
    apply_post_slot_weight_refit!(reduced)
    apply_post_constrained_boundary_weight_refit!(reduced)
    apply_active_table_entry_moves!(
        reduced,
        latest_boundary_base_constrained_table_optimizer_moves(),
    )
    apply_active_table_entry_moves!(reduced, latest_boundary_table_coordinate_scan_moves())
    apply_active_table_entry_moves!(reduced, latest_boundary_table_pair_coordinate_scan_moves())
    apply_active_table_entry_moves!(reduced, latest_boundary_table_coordinate_descent_moves())
    apply_active_table_entry_moves!(
        reduced,
        latest_boundary_table_continuation_optimizer_moves(),
    )
    apply_component_scale_refit_moves!(reduced, latest_component_scale_refit_moves())
    apply_pressure_component_scale_refit_moves!(reduced, latest_pressure_component_scale_refit_moves())
    apply_temperature_component_scale_refit_moves!(
        reduced,
        latest_temperature_component_scale_refit_moves(),
    )
    apply_h2o_component_scale_refit_moves!(reduced, latest_h2o_component_scale_refit_moves())
    apply_gas_component_scale_refit_moves!(reduced, latest_gas_component_scale_refit_moves())
    apply_pressure_temperature_component_scale_refit_moves!(
        reduced,
        latest_pressure_temperature_component_scale_refit_moves(),
    )
    apply_gas_pressure_temperature_component_moves!(
        reduced,
        latest_gas_pressure_temperature_component_scale_refit_moves(),
    )
    apply_h2o_pressure_temperature_component_moves!(
        reduced,
        latest_h2o_pressure_temperature_component_scale_refit_moves(),
    )
    apply_mixed_pressure_temperature_component_moves!(
        reduced,
        latest_mixed_pressure_temperature_component_refit_moves(),
    )
    apply_active_table_entry_moves!(
        reduced,
        latest_retained_structural_optimizer_moves(),
    )
    apply_active_table_entry_moves!(
        reduced,
        latest_retained_structural_continuation_moves(),
    )
    apply_active_table_entry_moves!(
        reduced,
        latest_retained_structural_continuation2_moves(),
    )
    apply_active_table_entry_moves!(
        reduced,
        latest_retained_structural_continuation3_moves(),
    )
    apply_active_table_entry_moves!(
        reduced,
        latest_retained_structural_continuation4_moves(),
    )
    return reduced
end

function retained_topology_score(full_model, candidate)
    model = retained_model_for_sw_indices(full_model, candidate.sw_indices)
    objective, cases = full_hard_objective(model)
    return merge(candidate, (
        objective = objective,
        worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in cases),
        worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in cases),
        passed_hard_thresholds = all(case -> case.passed_hard_thresholds, cases),
        cases = cases,
    ))
end

function retained_topology_pair_candidates(single_rows)
    selected = first(single_rows, min(retained_topology_pair_single_limit(),
                                      length(single_rows)))
    rows = NamedTuple[]
    base_length = isempty(selected) ? 0 : length(first(selected).sw_indices)
    for i in 1:length(selected)
        for j in (i + 1):length(selected)
            length(rows) >= retained_topology_pair_trial_limit() && return rows
            first_move = selected[i]
            second_move = selected[j]
            first_move.slot == second_move.slot && continue
            candidate = copy(WEIGHTED_GREEDY_SW_16_INDICES)
            length(candidate) == base_length || continue
            candidate[first_move.slot] = first_move.new_gpoint
            candidate[second_move.slot] = second_move.new_gpoint
            length(unique(candidate)) == length(candidate) || continue
            push!(rows, (
                slot = 0,
                old_gpoint = 0,
                new_gpoint = 0,
                first_slot = first_move.slot,
                first_old_gpoint = first_move.old_gpoint,
                first_new_gpoint = first_move.new_gpoint,
                second_slot = second_move.slot,
                second_old_gpoint = second_move.old_gpoint,
                second_new_gpoint = second_move.new_gpoint,
                sw_indices = candidate,
            ))
        end
    end
    return rows
end

function retained_topology_neighbor_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    base_model = retained_model_for_sw_indices(full_model, WEIGHTED_GREEDY_SW_16_INDICES)
    base_objective, base_cases = full_hard_objective(base_model)
    candidates = retained_topology_neighbor_indices()
    rows = [retained_topology_score(full_model, candidate) for candidate in candidates]
    pair_candidates = retained_topology_pair_candidates(sort(collect(rows);
                                                            by = row -> row.objective))
    pair_rows = [retained_topology_score(full_model, candidate)
                 for candidate in pair_candidates]
    all_rows = vcat(rows, pair_rows)
    best = if isempty(rows)
        nothing
    else
        objectives = [row.objective for row in all_rows]
        all_rows[argmin(objectives)]
    end
    improved = best !== nothing && best.objective < base_objective
    base_worst_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_worst_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    pareto_safe = best !== nothing &&
        best.worst_toa_forcing_error_w_m2 <= base_worst_toa + 1e-12 &&
        best.worst_surface_forcing_error_w_m2 <= base_worst_surface + 1e-12
    return (
        case = "reduced_ecckd_retained_topology_neighbor_scan",
        status = best === nothing ? "no_topology_neighbors" :
                 improved ? "retained_topology_neighbor_improved" :
                 "retained_topology_neighbor_rejected",
        radius = retained_topology_neighbor_radius(),
        candidate_count = length(rows),
        pair_candidate_count = length(pair_rows),
        base_sw_indices = collect(WEIGHTED_GREEDY_SW_16_INDICES),
        base_objective = base_objective,
        base_worst_toa_forcing_error_w_m2 = base_worst_toa,
        base_worst_surface_forcing_error_w_m2 = base_worst_surface,
        best_slot = best === nothing ? 0 : best.slot,
        best_old_gpoint = best === nothing ? 0 : best.old_gpoint,
        best_new_gpoint = best === nothing ? 0 : best.new_gpoint,
        best_first_slot = best === nothing || !hasproperty(best, :first_slot) ? 0 :
                          best.first_slot,
        best_first_old_gpoint =
            best === nothing || !hasproperty(best, :first_old_gpoint) ? 0 :
            best.first_old_gpoint,
        best_first_new_gpoint =
            best === nothing || !hasproperty(best, :first_new_gpoint) ? 0 :
            best.first_new_gpoint,
        best_second_slot = best === nothing || !hasproperty(best, :second_slot) ? 0 :
                           best.second_slot,
        best_second_old_gpoint =
            best === nothing || !hasproperty(best, :second_old_gpoint) ? 0 :
            best.second_old_gpoint,
        best_second_new_gpoint =
            best === nothing || !hasproperty(best, :second_new_gpoint) ? 0 :
            best.second_new_gpoint,
        best_sw_indices = best === nothing ? Int[] : best.sw_indices,
        best_objective = best === nothing ? NaN : best.objective,
        best_objective_reduction = best === nothing ? NaN : base_objective - best.objective,
        best_worst_toa_forcing_error_w_m2 =
            best === nothing ? NaN : best.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            best === nothing ? NaN : best.worst_surface_forcing_error_w_m2,
        pareto_safe = pareto_safe,
        passed_hard_thresholds = best !== nothing && best.passed_hard_thresholds,
        rows = rows,
        pair_rows = pair_rows,
    )
end

function retained_topology_neighbor_scan_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Topology Neighbor Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Radius | $(result.radius) |",
        "| Candidate count | $(result.candidate_count) |",
        "| Pair candidate count | $(result.pair_candidate_count) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Best objective | $(@sprintf("%.12g", result.best_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Base TOA forcing | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best TOA forcing | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Best replacement | $(result.best_slot == 0 ? "slot $(result.best_first_slot): g$(result.best_first_old_gpoint) -> g$(result.best_first_new_gpoint); slot $(result.best_second_slot): g$(result.best_second_old_gpoint) -> g$(result.best_second_new_gpoint)" : "slot $(result.best_slot): g$(result.best_old_gpoint) -> g$(result.best_new_gpoint)") |",
        "| Pareto safe | $(result.pareto_safe) |",
        "| Passed hard thresholds | $(result.passed_hard_thresholds) |",
        "",
        "This diagnostic evaluates local topology replacements after inheriting the",
        "current retained weights and coefficient/table moves. It is an exact hard",
        "objective scan for nearby quadrature definitions, not a naive topology",
        "comparison.",
        "",
        "## Candidate Summary",
        "",
        "| Slot | Replacement | Objective | TOA forcing | Surface forcing | Passed |",
        "|---:|---|---:|---:|---:|---:|",
    ]
    for row in sort(collect(result.rows); by = row -> row.objective)
        push!(lines, "| $(row.slot) | g$(row.old_gpoint) -> g$(row.new_gpoint) | $(@sprintf("%.12g", row.objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_surface_forcing_error_w_m2)) | $(row.passed_hard_thresholds) |")
    end
    append!(lines, [
        "",
        "## Pair Candidate Summary",
        "",
        "| Replacements | Objective | TOA forcing | Surface forcing | Passed |",
        "|---|---:|---:|---:|---:|",
    ])
    for row in sort(collect(result.pair_rows); by = row -> row.objective)
        replacements = "slot $(row.first_slot): g$(row.first_old_gpoint) -> g$(row.first_new_gpoint); slot $(row.second_slot): g$(row.second_old_gpoint) -> g$(row.second_new_gpoint)"
        push!(lines, "| $replacements | $(@sprintf("%.12g", row.objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_surface_forcing_error_w_m2)) | $(row.passed_hard_thresholds) |")
    end
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? retained_topology_neighbor_scan_result() : result
    mkpath(dirname(RETAINED_TOPOLOGY_NEIGHBOR_SCAN_JSON))
    write(RETAINED_TOPOLOGY_NEIGHBOR_SCAN_JSON, json_object(result) * "\n")
    write(RETAINED_TOPOLOGY_NEIGHBOR_SCAN_MD,
          retained_topology_neighbor_scan_markdown(result))
    print(retained_topology_neighbor_scan_markdown(result))
    println("Wrote $RETAINED_TOPOLOGY_NEIGHBOR_SCAN_JSON")
    println("Wrote $RETAINED_TOPOLOGY_NEIGHBOR_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
