include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_accuracy.jl"))

const BOUNDARY_TOPOLOGY_REPLACEMENT_JSON =
    validation_results_path("reduced_ecckd_boundary_topology_replacement.json")
const BOUNDARY_TOPOLOGY_REPLACEMENT_MD =
    validation_results_path("reduced_ecckd_boundary_topology_replacement.md")

function topology_replacement_candidates(indices; radius = 2)
    selected = Set(indices)
    rows = NamedTuple[]
    for (local_index, old_gpoint) in pairs(indices)
        for new_gpoint in max(1, old_gpoint - radius):min(32, old_gpoint + radius)
            new_gpoint == old_gpoint && continue
            new_gpoint in selected && continue
            candidate_indices = collect(indices)
            candidate_indices[local_index] = new_gpoint
            push!(rows, (
                local_index = local_index,
                removed_gpoint = old_gpoint,
                added_gpoint = new_gpoint,
                indices = candidate_indices,
            ))
        end
    end
    return rows
end

function boundary_table_model(full_model)
    return reduced_tabulated_model(full_model, (
        ng_lw = 32,
        ng_sw = 16,
        method = "weighted_greedy_subset_boundary_table_continuation",
    ))
end

function topology_normalized_case_objective(case)
    return max(
        case.variables.sw_up.rmse / ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
        case.variables.sw_down.rmse / ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
        case.variables.sw_up.max_abs / ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        case.variables.sw_down.max_abs / ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        case.variables.heating_rate.rmse / ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day,
        case.variables.heating_rate.max_abs / ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
        case.toa_forcing_max_abs / ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
        case.surface_forcing_max_abs /
        ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
    )
end

function topology_objective_breakdown(model)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    objectives = [topology_normalized_case_objective(case) for case in cases]
    worst_index = argmax(objectives)
    worst_case = cases[worst_index]
    return (
        objective = objectives[worst_index],
        worst_case = worst_case.case,
        worst_metric =
            worst_case.toa_forcing_max_abs / ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2 >=
            worst_case.surface_forcing_max_abs /
            ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2 ?
            "toa_or_profile_max" : "surface_or_profile_max",
        worst_value = max(worst_case.toa_forcing_max_abs,
                          worst_case.surface_forcing_max_abs),
        worst_threshold = ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
    )
end

function replace_shortwave_slot!(model, full_model, replacement)
    ig = replacement.local_index
    jg = replacement.added_gpoint
    model.shortwave_absorption[ig, :, :, :] .= full_model.shortwave_absorption[jg, :, :, :]
    if length(model.shortwave_h2o_absorption) != 0 &&
       length(full_model.shortwave_h2o_absorption) != 0
        model.shortwave_h2o_absorption[ig, :, :, :] .=
            full_model.shortwave_h2o_absorption[jg, :, :, :]
    end
    model.shortwave_rayleigh_molar_scattering[ig] =
        full_model.shortwave_rayleigh_molar_scattering[jg]
    return model
end

function topology_replacement_model(base_model, full_model, replacement)
    model = deepcopy(base_model)
    replace_shortwave_slot!(model, full_model, replacement)
    return register_reduced_model(
        model;
        lw_indices = collect(1:size(full_model.longwave_absorption, 1)),
        sw_indices = collect(replacement.indices),
        full_lw_weights = full_model.longwave_weights,
        full_sw_weights = full_model.shortwave_weights,
    )
end

function boundary_topology_replacement_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    base_model = boundary_table_model(full_model)
    base_breakdown = topology_objective_breakdown(base_model)
    radius = parse(Int, get(ENV, "RH_BOUNDARY_TOPOLOGY_REPLACEMENT_RADIUS", "2"))
    limit = parse(Int, get(ENV, "RH_BOUNDARY_TOPOLOGY_REPLACEMENT_CANDIDATES", "64"))
    candidates = topology_replacement_candidates(WEIGHTED_GREEDY_SW_16_INDICES; radius)
    rows = NamedTuple[]
    for candidate in Iterators.take(candidates, limit)
        model = topology_replacement_model(base_model, full_model, candidate)
        breakdown = topology_objective_breakdown(model)
        push!(rows, (
            local_index = candidate.local_index,
            removed_gpoint = candidate.removed_gpoint,
            added_gpoint = candidate.added_gpoint,
            indices = collect(candidate.indices),
            objective = breakdown.objective,
            improvement = base_breakdown.objective - breakdown.objective,
            worst_case = breakdown.worst_case,
            worst_metric = breakdown.worst_metric,
            worst_value = breakdown.worst_value,
            worst_threshold = breakdown.worst_threshold,
        ))
    end
    isempty(rows) && error("no topology replacement candidates evaluated")
    best = argmin(row -> row.objective, rows)
    result = (
        case = "reduced_ecckd_boundary_topology_replacement",
        timestamp_utc = string(Dates.now()),
        status = best.objective < base_breakdown.objective ?
            "topology_replacement_improved" : "topology_replacement_rejected",
        radius = radius,
        evaluated_candidate_count = length(rows),
        total_candidate_count = length(candidates),
        base_indices = collect(WEIGHTED_GREEDY_SW_16_INDICES),
        base_objective = base_breakdown.objective,
        base_worst_case = base_breakdown.worst_case,
        base_worst_metric = base_breakdown.worst_metric,
        base_worst_value = base_breakdown.worst_value,
        best = best,
        rows = rows,
    )
    return result
end

function markdown_boundary_topology_replacement_report(result)
    best = result.best
    lines = String[
        "# Reduced ecCKD Boundary-Table Topology Replacement",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Radius | `$(result.radius)` |",
        "| Evaluated candidates | `$(result.evaluated_candidate_count) / $(result.total_candidate_count)` |",
        "| Base objective | `$(@sprintf("%.12g", result.base_objective))` |",
        "| Best objective | `$(@sprintf("%.12g", best.objective))` |",
        "| Best improvement | `$(@sprintf("%.12g", best.improvement))` |",
        "| Best replacement | `g$(best.removed_gpoint) -> g$(best.added_gpoint)` |",
        "| Worst case | `$(best.worst_case)` |",
        "| Worst metric | `$(best.worst_metric)` |",
        "| Worst value | `$(@sprintf("%.12g", best.worst_value))` |",
        "",
        "This diagnostic replaces one shortwave slot in the current boundary-aware table-continuation model with the raw official ecCKD table for a neighboring g-point. It is intentionally conservative: accepted evidence would still need promotion through `reduced_ecckd_accuracy.jl`.",
    ]
    return join(lines, "\n") * "\n"
end

function main()
    result = boundary_topology_replacement_result()
    mkpath(dirname(BOUNDARY_TOPOLOGY_REPLACEMENT_JSON))
    write(BOUNDARY_TOPOLOGY_REPLACEMENT_JSON, json_object(result) * "\n")
    write(BOUNDARY_TOPOLOGY_REPLACEMENT_MD,
          markdown_boundary_topology_replacement_report(result))
    print(markdown_boundary_topology_replacement_report(result))
    println("Wrote $BOUNDARY_TOPOLOGY_REPLACEMENT_JSON")
    println("Wrote $BOUNDARY_TOPOLOGY_REPLACEMENT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
