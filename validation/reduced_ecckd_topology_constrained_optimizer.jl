include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const TOPOLOGY_CONSTRAINED_JSON =
    validation_results_path("reduced_ecckd_topology_constrained_optimizer.json")
const TOPOLOGY_CONSTRAINED_MD =
    validation_results_path("reduced_ecckd_topology_constrained_optimizer.md")

const TOPOLOGY_TRIALS = (
    (
        label = "subset_search_official_weight_greedy",
        indices = [2, 4, 7, 8, 10, 11, 12, 14, 16, 18, 21, 25, 27, 28, 30, 32],
        weights = Float64[],
    ),
    (
        label = "subset_search_boundary_weight_30",
        indices = [2, 4, 7, 10, 11, 12, 14, 16, 18, 21, 22, 27, 28, 30, 31, 32],
        weights = [
            0.021151761745205975,
            0.029324765136930567,
            0.15826074775561377,
            0.16097041867293482,
            0.10621948180267397,
            0.023654011357233835,
            0.026674809079345736,
            0.024618362369092355,
            0.02003879700572604,
            0.01455242425469479,
            0.0020338155204009728,
            0.19029237672395616,
            0.2088136254241496,
            0.0072478273818982475,
            0.0011284702115749439,
            0.005018305558568347,
        ],
    ),
    (
        label = "subset_search_boundary_weight_10",
        indices = [2, 4, 7, 8, 9, 10, 12, 14, 16, 18, 21, 27, 28, 30, 31, 32],
        weights = [
            0.014619802955263822,
            0.024754080603269137,
            0.16590572125845582,
            0.09385970442441578,
            0.019457837732868456,
            0.1687389805684648,
            0.022957421958459314,
            0.023356729351870168,
            0.021973580365878504,
            0.016230151341577168,
            0.011475502085638203,
            0.19043928376470942,
            0.21044366237142587,
            0.007379072948915833,
            0.0037858539604346065,
            0.004622614308353097,
        ],
    ),
)

function with_trial_environment(f, trial; candidates, max_log_scale)
    old = Dict{String, Union{Nothing, String}}()
    keys = (
        "RH_REDUCED_CONSTRAINED_TABLE_SCOPE",
        "RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE",
        "RH_REDUCED_CONSTRAINED_TABLE_SW_INDICES",
        "RH_REDUCED_CONSTRAINED_TABLE_SW_WEIGHTS",
        "RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES",
        "RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE",
        "RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH",
    )
    for key in keys
        old[key] = get(ENV, key, nothing)
    end
    try
        ENV["RH_REDUCED_CONSTRAINED_TABLE_SCOPE"] = "global_active"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE"] = "plain_topology"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_SW_INDICES"] = join(trial.indices, ",")
        if isempty(trial.weights)
            delete!(ENV, "RH_REDUCED_CONSTRAINED_TABLE_SW_WEIGHTS")
        else
            ENV["RH_REDUCED_CONSTRAINED_TABLE_SW_WEIGHTS"] = join(trial.weights, ",")
        end
        ENV["RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES"] = string(candidates)
        ENV["RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE"] = string(max_log_scale)
        ENV["RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH"] = "false"
        return f()
    finally
        for key in keys
            if old[key] === nothing
                delete!(ENV, key)
            else
                ENV[key] = old[key]::String
            end
        end
    end
end

function slim_topology_result(trial, result)
    return (
        label = trial.label,
        sw_indices = collect(trial.indices),
        weight_source = isempty(trial.weights) ? "official_renormalized" : "subset_search_fitted",
        status = result.status,
        base_objective = result.base_objective,
        best_exact_objective = result.best_exact_objective,
        best_objective_reduction = result.best_objective_reduction,
        best_worst_toa_forcing_error_w_m2 = result.best_worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 = result.best_worst_surface_forcing_error_w_m2,
        target_case = result.target.target_case,
        target_metric = result.target.target_metric,
        candidate_count = result.candidate_count,
        max_log_scale = result.max_log_scale,
        accepted = result.accepted,
        accepted_move_count = length(result.accepted_moves),
    )
end

function topology_constrained_result(; candidates = 64, max_log_scale = 0.25)
    rows = NamedTuple[]
    for trial in TOPOLOGY_TRIALS
        result = with_trial_environment(trial; candidates, max_log_scale) do
            constrained_table_optimizer_result()
        end
        push!(rows, slim_topology_result(trial, result))
    end
    _, best_index = findmin(row -> row.best_exact_objective, rows)
    best = rows[best_index]
    return (
        case = "reduced_ecckd_topology_constrained_optimizer",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = best.best_worst_toa_forcing_error_w_m2 <=
                 ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2 &&
                 best.best_worst_surface_forcing_error_w_m2 <=
                 ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2 ?
                 "passed" : "failed_threshold",
        candidates_per_topology = candidates,
        max_log_scale = max_log_scale,
        best_label = best.label,
        best_exact_objective = best.best_exact_objective,
        best_worst_toa_forcing_error_w_m2 = best.best_worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            best.best_worst_surface_forcing_error_w_m2,
        rows = rows,
    )
end

function topology_constrained_markdown(result)
    lines = String[
        "# Reduced ecCKD Topology Constrained Optimizer",
        "",
        "Status: **$(result.status)**",
        "",
        "This diagnostic applies the constrained active-entry table optimizer to",
        "alternate 16-g shortwave topologies from the subset-search artifact.",
        "It is separate from the canonical reduced model artifact and does not",
        "overwrite the accepted canonical constrained moves.",
        "",
        "| Topology | Accepted | Objective | TOA forcing error | Surface forcing error |",
        "|---|---:|---:|---:|---:|",
    ]
    for row in result.rows
        push!(lines,
              "| $(row.label) | $(row.accepted) | $(@sprintf("%.12g", row.best_exact_objective)) | $(@sprintf("%.12g", row.best_worst_toa_forcing_error_w_m2)) W m^-2 | $(@sprintf("%.12g", row.best_worst_surface_forcing_error_w_m2)) W m^-2 |")
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = topology_constrained_result()
    mkpath(dirname(TOPOLOGY_CONSTRAINED_JSON))
    write(TOPOLOGY_CONSTRAINED_JSON, json_object(result) * "\n")
    write(TOPOLOGY_CONSTRAINED_MD, topology_constrained_markdown(result))
    print(topology_constrained_markdown(result))
    println("Wrote $TOPOLOGY_CONSTRAINED_JSON")
    println("Wrote $TOPOLOGY_CONSTRAINED_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
