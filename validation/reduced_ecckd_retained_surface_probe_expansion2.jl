include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const RETAINED_SURFACE_PROBE_EXPANSION2_JSON =
    validation_results_path("reduced_ecckd_retained_surface_probe_expansion2.json")
const RETAINED_SURFACE_PROBE_EXPANSION2_MD =
    validation_results_path("reduced_ecckd_retained_surface_probe_expansion2.md")

function with_surface_probe2_env(f; candidates, probe_step, max_log_scale)
    keys = (
        "RH_CANDIDATE_GAS_OPTICS",
        "RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE",
        "RH_REDUCED_CONSTRAINED_TABLE_SCOPE",
        "RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE",
        "RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES",
        "RH_REDUCED_CONSTRAINED_TABLE_PROBE_POOL_MULTIPLIER",
        "RH_REDUCED_CONSTRAINED_TABLE_PROBE_STEP",
        "RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE",
        "RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH",
        "RH_REDUCED_CONSTRAINED_TABLE_RIDGE_LAMBDAS",
        "RH_REDUCED_IGNORE_RETAINED_SURFACE_PROBE_EXPANSION2",
    )
    old = Dict(key => get(ENV, key, nothing) for key in keys)
    try
        ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE"] =
            "boundary_table_continuation"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_SCOPE"] =
            "all_global_objective_probe"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE"] = "surface"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES"] = string(candidates)
        ENV["RH_REDUCED_CONSTRAINED_TABLE_PROBE_POOL_MULTIPLIER"] = "4"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_PROBE_STEP"] = string(probe_step)
        ENV["RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE"] = string(max_log_scale)
        ENV["RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH"] = "true"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_RIDGE_LAMBDAS"] =
            "1.0e-4,1.0e-2,1.0,100.0,1.0e4,1.0e6,1.0e8"
        ENV["RH_REDUCED_IGNORE_RETAINED_SURFACE_PROBE_EXPANSION2"] = "true"
        return f()
    finally
        for (key, value) in old
            if value === nothing
                delete!(ENV, key)
            else
                ENV[key] = value
            end
        end
    end
end

function retained_surface_probe_expansion2_result()
    configs = (
        (
            label = "surface_probe2_32_medium_tiny",
            candidates = 32,
            probe_step = 0.000244140625,
            max_log_scale = 0.001953125,
        ),
        (
            label = "surface_probe2_32_small_tiny",
            candidates = 32,
            probe_step = 0.0001220703125,
            max_log_scale = 0.0009765625,
        ),
    )
    rows = NamedTuple[]
    for config in configs
        result = with_surface_probe2_env(
            candidates = config.candidates,
            probe_step = config.probe_step,
            max_log_scale = config.max_log_scale,
        ) do
            constrained_table_optimizer_result()
        end
        pareto_safe = pareto_safe_forcing_update(result)
        accepted = result.accepted && pareto_safe
        push!(rows, (
            label = config.label,
            status = result.status,
            candidate_count = result.candidate_count,
            probe_step = result.probe_step,
            max_log_scale = result.max_log_scale,
            base_objective = result.base_objective,
            base_worst_toa_forcing_error_w_m2 =
                result.base_worst_toa_forcing_error_w_m2,
            base_worst_surface_forcing_error_w_m2 =
                result.base_worst_surface_forcing_error_w_m2,
            best_exact_objective = result.best_exact_objective,
            best_objective_reduction = result.best_objective_reduction,
            best_worst_toa_forcing_error_w_m2 =
                result.best_worst_toa_forcing_error_w_m2,
            best_worst_surface_forcing_error_w_m2 =
                result.best_worst_surface_forcing_error_w_m2,
            pareto_safe = pareto_safe,
            accepted = accepted,
            accepted_moves = accepted ? result.accepted_moves : NamedTuple[],
        ))
    end
    best = argmin(row -> row.best_exact_objective, rows)
    accepted = any(row -> row.accepted, rows)
    return (
        case = "reduced_ecckd_retained_surface_probe_expansion2",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "surface_probe_expansion2_improved" :
                 "surface_probe_expansion2_rejected",
        config_count = length(rows),
        best_label = best.label,
        best_exact_objective = best.best_exact_objective,
        best_objective_reduction = best.best_objective_reduction,
        best_worst_toa_forcing_error_w_m2 =
            best.best_worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            best.best_worst_surface_forcing_error_w_m2,
        any_accepted = accepted,
        rows = rows,
    )
end

function retained_surface_probe_expansion2_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Surface-Probe Expansion 2",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Configurations | $(result.config_count) |",
        "| Best label | $(result.best_label) |",
        "| Best exact objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best TOA forcing | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Any accepted | $(result.any_accepted) |",
        "",
        "This diagnostic repeats the surface-only linearized residual update after",
        "the first surface-probe expansion has been promoted, accepting only",
        "strict Pareto-safe full-objective updates.",
        "",
        "## Configurations",
        "",
        "| Label | Candidates | Probe step | Max log scale | Base objective | Base TOA | Base surface | Best objective | Reduction | TOA | Surface | Pareto safe | Accepted |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.rows
        push!(lines, "| $(row.label) | $(row.candidate_count) | $(@sprintf("%.12g", row.probe_step)) | $(@sprintf("%.12g", row.max_log_scale)) | $(@sprintf("%.12g", row.base_objective)) | $(@sprintf("%.12g", row.base_worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.base_worst_surface_forcing_error_w_m2)) | $(@sprintf("%.12g", row.best_exact_objective)) | $(@sprintf("%.12g", row.best_objective_reduction)) | $(@sprintf("%.12g", row.best_worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.best_worst_surface_forcing_error_w_m2)) | $(row.pareto_safe) | $(row.accepted) |")
    end
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? retained_surface_probe_expansion2_result() :
        result
    mkpath(dirname(RETAINED_SURFACE_PROBE_EXPANSION2_JSON))
    write(RETAINED_SURFACE_PROBE_EXPANSION2_JSON, json_object(result) * "\n")
    write(RETAINED_SURFACE_PROBE_EXPANSION2_MD,
          retained_surface_probe_expansion2_markdown(result))
    print(retained_surface_probe_expansion2_markdown(result))
    println("Wrote $RETAINED_SURFACE_PROBE_EXPANSION2_JSON")
    println("Wrote $RETAINED_SURFACE_PROBE_EXPANSION2_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
