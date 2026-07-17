include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_boundary_topology_replacement.jl"))

const BOUNDARY_TOPOLOGY_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_boundary_topology_weight_refit.json")
const BOUNDARY_TOPOLOGY_WEIGHT_REFIT_MD =
    validation_results_path("reduced_ecckd_boundary_topology_weight_refit.md")

boundary_topology_weight_radius() =
    parse(Int, get(ENV, "RH_BOUNDARY_TOPOLOGY_WEIGHT_RADIUS", "2"))

boundary_topology_weight_candidates() =
    parse(Int, get(ENV, "RH_BOUNDARY_TOPOLOGY_WEIGHT_CANDIDATES", "64"))

boundary_topology_weight_iterations() =
    parse(Int, get(ENV, "RH_BOUNDARY_TOPOLOGY_WEIGHT_ITERATIONS", "2000"))

function topology_weight_refit_model(base_model, full_model, replacement)
    model = topology_replacement_model(base_model, full_model, replacement)
    weights = optimized_shortwave_weights_maxnorm(
        model;
        initial_weights = model.shortwave_weights,
        max_iterations = boundary_topology_weight_iterations(),
        p = 16,
    )
    return with_shortwave_weights(model, weights), weights
end

function boundary_topology_weight_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    base_model = boundary_table_model(full_model)
    base_breakdown = topology_objective_breakdown(base_model)
    radius = boundary_topology_weight_radius()
    limit = boundary_topology_weight_candidates()
    candidates = topology_replacement_candidates(WEIGHTED_GREEDY_SW_16_INDICES; radius)
    rows = NamedTuple[]
    for candidate in Iterators.take(candidates, limit)
        model, weights = topology_weight_refit_model(base_model, full_model, candidate)
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
            weights = collect(weights),
        ))
    end
    isempty(rows) && error("no topology weight-refit candidates evaluated")
    best = argmin(row -> row.objective, rows)
    return (
        case = "reduced_ecckd_boundary_topology_weight_refit",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = best.objective < base_breakdown.objective ?
            "topology_weight_refit_improved" : "topology_weight_refit_rejected",
        radius = radius,
        weight_iterations = boundary_topology_weight_iterations(),
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
end

function markdown_boundary_topology_weight_refit_report(result)
    best = result.best
    lines = String[
        "# Reduced ecCKD Boundary-Table Topology Weight Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Radius | `$(result.radius)` |",
        "| Weight iterations | `$(result.weight_iterations)` |",
        "| Evaluated candidates | `$(result.evaluated_candidate_count) / $(result.total_candidate_count)` |",
        "| Base objective | `$(@sprintf("%.12g", result.base_objective))` |",
        "| Best objective | `$(@sprintf("%.12g", best.objective))` |",
        "| Best improvement | `$(@sprintf("%.12g", best.improvement))` |",
        "| Best replacement | `g$(best.removed_gpoint) -> g$(best.added_gpoint)` |",
        "| Worst case | `$(best.worst_case)` |",
        "| Worst metric | `$(best.worst_metric)` |",
        "| Worst value | `$(@sprintf("%.12g", best.worst_value))` |",
        "",
        "This diagnostic replaces one shortwave slot in the retained boundary-aware",
        "table-continuation model, then refits the reduced shortwave weights with",
        "the hard-gate max-norm weight optimizer before exact objective evaluation.",
    ]
    return join(lines, "\n") * "\n"
end

function main()
    result = boundary_topology_weight_refit_result()
    mkpath(dirname(BOUNDARY_TOPOLOGY_WEIGHT_REFIT_JSON))
    write(BOUNDARY_TOPOLOGY_WEIGHT_REFIT_JSON, json_object(result) * "\n")
    write(BOUNDARY_TOPOLOGY_WEIGHT_REFIT_MD,
          markdown_boundary_topology_weight_refit_report(result))
    print(markdown_boundary_topology_weight_refit_report(result))
    println("Wrote $BOUNDARY_TOPOLOGY_WEIGHT_REFIT_JSON")
    println("Wrote $BOUNDARY_TOPOLOGY_WEIGHT_REFIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
