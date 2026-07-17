include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const RETAINED_TOPOLOGY_CONSTRAINED_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_topology_constrained_optimizer.json")
const RETAINED_TOPOLOGY_CONSTRAINED_OPTIMIZER_MD =
    validation_results_path("reduced_ecckd_retained_topology_constrained_optimizer.md")

const RETAINED_TOPOLOGY_PAIR_SW_INDICES =
    [1, 4, 9, 10, 12, 13, 14, 16, 19, 22, 26, 27, 28, 30, 31, 32]

function retained_topology_constrained_indices()
    raw = strip(get(ENV, "RH_RETAINED_TOPOLOGY_CONSTRAINED_SW_INDICES", ""))
    isempty(raw) && return RETAINED_TOPOLOGY_PAIR_SW_INDICES
    return [parse(Int, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function with_retained_topology_constrained_environment(f)
    keys = (
        "RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE",
        "RH_REDUCED_CONSTRAINED_TABLE_SW_INDICES",
        "RH_REDUCED_CONSTRAINED_TABLE_SCOPE",
        "RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE",
        "RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES",
        "RH_REDUCED_CONSTRAINED_TABLE_PROBE_POOL_MULTIPLIER",
        "RH_REDUCED_CONSTRAINED_TABLE_PROBE_STEP",
        "RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE",
        "RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH",
    )
    old = Dict(key => get(ENV, key, nothing) for key in keys)
    try
        ENV["RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE"] = "retained_topology"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_SW_INDICES"] =
            join(retained_topology_constrained_indices(), ",")
        ENV["RH_REDUCED_CONSTRAINED_TABLE_SCOPE"] =
            get(ENV, "RH_RETAINED_TOPOLOGY_CONSTRAINED_SCOPE", "all_global_residual_probe")
        ENV["RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE"] =
            get(ENV, "RH_RETAINED_TOPOLOGY_CONSTRAINED_RESIDUAL_MODE", "boundary")
        ENV["RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES"] =
            get(ENV, "RH_RETAINED_TOPOLOGY_CONSTRAINED_CANDIDATES", "16")
        ENV["RH_REDUCED_CONSTRAINED_TABLE_PROBE_POOL_MULTIPLIER"] =
            get(ENV, "RH_RETAINED_TOPOLOGY_CONSTRAINED_PROBE_POOL_MULTIPLIER", "4")
        ENV["RH_REDUCED_CONSTRAINED_TABLE_PROBE_STEP"] =
            get(ENV, "RH_RETAINED_TOPOLOGY_CONSTRAINED_PROBE_STEP", "0.00390625")
        ENV["RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE"] =
            get(ENV, "RH_RETAINED_TOPOLOGY_CONSTRAINED_MAX_LOG_SCALE", "0.03125")
        ENV["RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH"] =
            get(ENV, "RH_RETAINED_TOPOLOGY_CONSTRAINED_INCLUDE_RAYLEIGH", "true")
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

function retained_topology_constrained_optimizer_result()
    result = with_retained_topology_constrained_environment() do
        pareto_guarded_forcing_result(constrained_table_optimizer_result())
    end
    return merge(
        result,
        (
            case = "reduced_ecckd_retained_topology_constrained_optimizer",
            method = "Pareto-guarded constrained table-entry rescue of the best rejected retained topology pair",
        ),
    )
end

function retained_topology_constrained_optimizer_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Topology Constrained Optimizer",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base mode | $(result.base_mode) |",
        "| Candidate scope | $(result.candidate_scope) |",
        "| Residual mode | $(result.residual_mode) |",
        "| SW indices | $(join(result.sw_indices, ", ")) |",
        "| Candidate count | $(result.candidate_count) |",
        "| Probe step | $(@sprintf("%.12g", result.probe_step)) |",
        "| Max log scale | $(@sprintf("%.12g", result.max_log_scale)) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Best exact objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best TOA forcing error | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing error | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Pareto safe | $(result.pareto_safe) |",
        "| Accepted | $(result.accepted) |",
        "| Proposed moves | $(length(result.proposed_moves)) |",
        "",
        "This diagnostic checks whether the best rejected retained-topology pair can",
        "be rescued by a small local constrained table-entry optimization before",
        "considering broader topology or coefficient-table parameterizations.",
    ]
    return join(lines, "\n") * "\n"
end

function main()
    result = retained_topology_constrained_optimizer_result()
    mkpath(dirname(RETAINED_TOPOLOGY_CONSTRAINED_OPTIMIZER_JSON))
    write(RETAINED_TOPOLOGY_CONSTRAINED_OPTIMIZER_JSON, json_object(result) * "\n")
    write(RETAINED_TOPOLOGY_CONSTRAINED_OPTIMIZER_MD,
          retained_topology_constrained_optimizer_markdown(result))
    print(retained_topology_constrained_optimizer_markdown(result))
    println("Wrote $RETAINED_TOPOLOGY_CONSTRAINED_OPTIMIZER_JSON")
    println("Wrote $RETAINED_TOPOLOGY_CONSTRAINED_OPTIMIZER_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
