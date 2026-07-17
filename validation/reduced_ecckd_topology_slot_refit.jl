include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_optimization_preflight.jl"))

const TOPOLOGY_SLOT_REFIT_JSON =
    validation_results_path("reduced_ecckd_topology_slot_refit.json")
const TOPOLOGY_SLOT_REFIT_MD =
    validation_results_path("reduced_ecckd_topology_slot_refit.md")

topology_slot_radius() =
    parse(Int, get(ENV, "RH_REDUCED_TOPOLOGY_SLOT_RADIUS", "2"))

topology_slot_candidate_limit() =
    parse(Int, get(ENV, "RH_REDUCED_TOPOLOGY_SLOT_CANDIDATES", "0"))

function topology_slot_active_moves()
    moves = latest_targeted_active_table_entry_moves()
    isempty(moves) || return moves
    return latest_preflight_active_table_entry_moves()
end

function topology_slot_model(full_model, parameters, indices, pressure_moves, active_moves)
    return pressure_band_active_table_moved_model(
        full_model,
        parameters,
        pressure_moves,
        active_moves;
        sw_indices = indices,
    )
end

function topology_slot_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    parameters = latest_preflight_reduced_parameters()
    parameters === nothing && error("reduced preflight parameters are required")
    pressure_moves = latest_preflight_pressure_band_table_moves()
    active_moves = topology_slot_active_moves()

    base_indices = WEIGHTED_GREEDY_SW_16_INDICES
    base_model = topology_slot_model(
        full_model,
        parameters,
        base_indices,
        pressure_moves,
        active_moves,
    )
    base_breakdown = final_objective_breakdown_from_model(
        base_model;
        sw_indices = base_indices,
        method = "topology slot-inheritance base breakdown",
    )
    candidates = neighbor_topology_candidates(base_indices; radius = topology_slot_radius())
    limit = topology_slot_candidate_limit()
    evaluated_candidates = limit <= 0 ? candidates : collect(Iterators.take(candidates, limit))
    rows = NamedTuple[]
    for candidate in evaluated_candidates
        model = topology_slot_model(
            full_model,
            parameters,
            candidate.indices,
            pressure_moves,
            active_moves,
        )
        breakdown = final_objective_breakdown_from_model(
            model;
            sw_indices = candidate.indices,
            method = "topology slot-inheritance candidate breakdown",
        )
        push!(rows, (
            local_index = candidate.local_index,
            removed_gpoint = candidate.removed_gpoint,
            added_gpoint = candidate.added_gpoint,
            indices = candidate.indices,
            objective = breakdown.objective,
            improvement = base_breakdown.objective - breakdown.objective,
            worst_case = breakdown.worst_case,
            worst_metric = breakdown.worst_metric,
            worst_value = breakdown.worst_value,
            worst_threshold = breakdown.worst_threshold,
        ))
    end
    best = isempty(rows) ? nothing : argmin(row -> row.objective, rows)
    return (
        case = "reduced_ecckd_topology_slot_refit",
        status = "preflight_ready",
        radius = topology_slot_radius(),
        candidate_limit = limit,
        total_candidate_count = length(candidates),
        candidate_count = length(rows),
        pressure_move_count = length(pressure_moves),
        active_move_count = length(active_moves),
        base_indices = collect(base_indices),
        base_objective = base_breakdown.objective,
        best_objective = best === nothing ? base_breakdown.objective : best.objective,
        best_improvement = best === nothing ? 0.0 : best.improvement,
        improved = best !== nothing && best.objective < base_breakdown.objective,
        best_removed_gpoint = best === nothing ? nothing : best.removed_gpoint,
        best_added_gpoint = best === nothing ? nothing : best.added_gpoint,
        best_indices = best === nothing ? Int[] : best.indices,
        rows = rows,
        base_breakdown = base_breakdown,
    )
end

function topology_slot_markdown(result)
    lines = String[
        "# Reduced ecCKD Topology Slot Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Radius | $(result.radius) |",
        "| Candidates | $(result.candidate_count) / $(result.total_candidate_count) |",
        "| Pressure moves | $(result.pressure_move_count) |",
        "| Active moves | $(result.active_move_count) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Best objective | $(@sprintf("%.12g", result.best_objective)) |",
        "| Best improvement | $(@sprintf("%.12g", result.best_improvement)) |",
        "| Improved | $(result.improved) |",
        "| Best move | $(result.best_removed_gpoint === nothing ? "n/a" : "g$(result.best_removed_gpoint) -> g$(result.best_added_gpoint)") |",
        "",
        "| Removed | Added | Objective | Improvement | Worst case | Worst metric |",
        "|---:|---:|---:|---:|---|---|",
    ]
    for row in result.rows
        push!(lines, "| $(row.removed_gpoint) | $(row.added_gpoint) | $(@sprintf("%.12g", row.objective)) | $(@sprintf("%.12g", row.improvement)) | $(row.worst_case) | $(row.worst_metric) |")
    end
    push!(lines, "")
    push!(lines, "This diagnostic keeps optimized local parameter slots fixed while swapping nearby official g-points. It tests whether a neighbor topology can inherit the current slot weights/scales/table moves and improve the nonlinear hard objective before any expensive topology reoptimization.")
    return join(lines, "\n") * "\n"
end

function write_topology_slot_artifacts(result)
    mkpath(dirname(TOPOLOGY_SLOT_REFIT_JSON))
    write(TOPOLOGY_SLOT_REFIT_JSON, json_object(result) * "\n")
    write(TOPOLOGY_SLOT_REFIT_MD, topology_slot_markdown(result))
    print(topology_slot_markdown(result))
    println("Wrote $TOPOLOGY_SLOT_REFIT_JSON")
    println("Wrote $TOPOLOGY_SLOT_REFIT_MD")
end

function main(; result = nothing)
    write_topology_slot_artifacts(
        result === nothing ? topology_slot_refit_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
