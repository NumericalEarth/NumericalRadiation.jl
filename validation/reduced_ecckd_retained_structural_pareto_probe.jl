include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const RETAINED_STRUCTURAL_PARETO_PROBE_JSON =
    validation_results_path("reduced_ecckd_retained_structural_pareto_probe.json")
const RETAINED_STRUCTURAL_PARETO_PROBE_MD =
    validation_results_path("reduced_ecckd_retained_structural_pareto_probe.md")

function retained_structural_pareto_probe_configs()
    return (
        (
            label = "current_exact_objective_tiny_rayleigh",
            scope = "all_global_objective_probe",
            residual_mode = "all_shortwave",
            include_rayleigh = "true",
        ),
        (
            label = "current_residual_tiny_no_rayleigh",
            scope = "all_global_residual_probe",
            residual_mode = "all_shortwave",
            include_rayleigh = "false",
        ),
    )
end

function with_pareto_probe_env(f, config)
    keys = (
        "RH_CANDIDATE_GAS_OPTICS",
        "RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE",
        "RH_REDUCED_CONSTRAINED_TABLE_SCOPE",
        "RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE",
        "RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES",
        "RH_REDUCED_CONSTRAINED_TABLE_PROBE_STEP",
        "RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE",
        "RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH",
        "RH_REDUCED_CONSTRAINED_TABLE_RIDGE_LAMBDAS",
    )
    old = Dict(key => get(ENV, key, nothing) for key in keys)
    try
        ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE"] =
            "boundary_table_continuation"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_SCOPE"] = config.scope
        ENV["RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE"] = config.residual_mode
        ENV["RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES"] = "12"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_PROBE_STEP"] = "0.0001220703125"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE"] = "0.0009765625"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH"] =
            config.include_rayleigh
        ENV["RH_REDUCED_CONSTRAINED_TABLE_RIDGE_LAMBDAS"] =
            "1.0e-4,1.0e-2,1.0,100.0,1.0e4,1.0e6,1.0e8"
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

function compact_pareto_probe_row(config, result)
    surface_regressed =
        result.best_worst_surface_forcing_error_w_m2 >
        result.base_worst_surface_forcing_error_w_m2
    toa_regressed =
        result.best_worst_toa_forcing_error_w_m2 >
        result.base_worst_toa_forcing_error_w_m2
    return (
        label = config.label,
        status = result.status,
        candidate_scope = result.candidate_scope,
        residual_mode = result.residual_mode,
        include_rayleigh = result.include_rayleigh,
        candidate_count = result.candidate_count,
        probe_step = result.probe_step,
        max_log_scale = result.max_log_scale,
        base_objective = result.base_objective,
        best_exact_objective = result.best_exact_objective,
        best_objective_reduction = result.best_objective_reduction,
        base_worst_toa_forcing_error_w_m2 =
            result.base_worst_toa_forcing_error_w_m2,
        base_worst_surface_forcing_error_w_m2 =
            result.base_worst_surface_forcing_error_w_m2,
        best_worst_toa_forcing_error_w_m2 =
            result.best_worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            result.best_worst_surface_forcing_error_w_m2,
        toa_regressed = toa_regressed,
        surface_regressed = surface_regressed,
        accepted = result.accepted,
    )
end

function retained_structural_pareto_probe_result()
    rows = NamedTuple[]
    for config in retained_structural_pareto_probe_configs()
        result = with_pareto_probe_env(config) do
            constrained_table_optimizer_result()
        end
        push!(rows, compact_pareto_probe_row(config, result))
    end
    accepted = any(row -> row.accepted, rows)
    pareto_safe = any(row -> row.accepted && !row.toa_regressed &&
                            !row.surface_regressed, rows)
    best = rows[argmin([row.best_exact_objective for row in rows])]
    return (
        case = "reduced_ecckd_retained_structural_pareto_probe",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = pareto_safe ? "pareto_probe_improved" :
                 accepted ? "pareto_probe_scalar_only" :
                 "pareto_probe_rejected",
        config_count = length(rows),
        best_label = best.label,
        best_exact_objective = best.best_exact_objective,
        best_objective_reduction = best.best_objective_reduction,
        best_worst_toa_forcing_error_w_m2 =
            best.best_worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            best.best_worst_surface_forcing_error_w_m2,
        any_accepted = accepted,
        any_pareto_safe = pareto_safe,
        rows = rows,
    )
end

function retained_structural_pareto_probe_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Structural Pareto Probe",
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
        "| Any Pareto-safe accepted | $(result.any_pareto_safe) |",
        "",
        "This diagnostic probes the current retained structural base after the",
        "four retained structural continuations. It records whether another tiny",
        "constrained table step is available without repeating the retained",
        "one-off continuation chain.",
        "",
        "## Configurations",
        "",
        "| Label | Scope | Rayleigh | Base objective | Best objective | Reduction | TOA | Surface | TOA regressed | Surface regressed | Accepted |",
        "|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.rows
        push!(lines, "| $(row.label) | $(row.candidate_scope) | $(row.include_rayleigh) | $(@sprintf("%.12g", row.base_objective)) | $(@sprintf("%.12g", row.best_exact_objective)) | $(@sprintf("%.12g", row.best_objective_reduction)) | $(@sprintf("%.12g", row.best_worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.best_worst_surface_forcing_error_w_m2)) | $(row.toa_regressed) | $(row.surface_regressed) | $(row.accepted) |")
    end
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? retained_structural_pareto_probe_result() :
        result
    mkpath(dirname(RETAINED_STRUCTURAL_PARETO_PROBE_JSON))
    write(RETAINED_STRUCTURAL_PARETO_PROBE_JSON, json_object(result) * "\n")
    write(RETAINED_STRUCTURAL_PARETO_PROBE_MD,
          retained_structural_pareto_probe_markdown(result))
    print(retained_structural_pareto_probe_markdown(result))
    println("Wrote $RETAINED_STRUCTURAL_PARETO_PROBE_JSON")
    println("Wrote $RETAINED_STRUCTURAL_PARETO_PROBE_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
