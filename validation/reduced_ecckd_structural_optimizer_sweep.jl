include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const STRUCTURAL_OPTIMIZER_SWEEP_JSON =
    validation_results_path("reduced_ecckd_structural_optimizer_sweep.json")
const STRUCTURAL_OPTIMIZER_SWEEP_MD =
    validation_results_path("reduced_ecckd_structural_optimizer_sweep.md")

function structural_optimizer_sweep_configs()
    return (
        (
            label = "retained_all_shortwave_residual_probe",
            base_mode = "boundary_table_continuation",
            scope = "all_global_residual_probe",
            residual_mode = "all_shortwave",
            candidates = "12",
            probe_step = "0.001953125",
            max_log_scale = "0.03125",
            include_rayleigh = "true",
            ridge_lambdas = "1.0e-4,1.0e-2,1.0,100.0,1.0e4",
        ),
        (
            label = "retained_boundary_residual_probe",
            base_mode = "boundary_table_continuation",
            scope = "all_global_residual_probe",
            residual_mode = "boundary",
            candidates = "12",
            probe_step = "0.001953125",
            max_log_scale = "0.03125",
            include_rayleigh = "true",
            ridge_lambdas = "1.0e-4,1.0e-2,1.0,100.0,1.0e4",
        ),
    )
end

function with_sweep_env(f, config)
    keys = (
        "RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE",
        "RH_REDUCED_CONSTRAINED_TABLE_SCOPE",
        "RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE",
        "RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES",
        "RH_REDUCED_CONSTRAINED_TABLE_PROBE_STEP",
        "RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE",
        "RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH",
        "RH_REDUCED_CONSTRAINED_TABLE_RIDGE_LAMBDAS",
        "RH_CANDIDATE_GAS_OPTICS",
    )
    old = Dict(key => get(ENV, key, nothing) for key in keys)
    try
        ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE"] = config.base_mode
        ENV["RH_REDUCED_CONSTRAINED_TABLE_SCOPE"] = config.scope
        ENV["RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE"] = config.residual_mode
        ENV["RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES"] = config.candidates
        ENV["RH_REDUCED_CONSTRAINED_TABLE_PROBE_STEP"] = config.probe_step
        ENV["RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE"] = config.max_log_scale
        ENV["RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH"] =
            config.include_rayleigh
        ENV["RH_REDUCED_CONSTRAINED_TABLE_RIDGE_LAMBDAS"] =
            config.ridge_lambdas
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

function compact_sweep_row(config, result)
    return (
        label = config.label,
        status = result.status,
        base_mode = result.base_mode,
        candidate_scope = result.candidate_scope,
        residual_mode = result.residual_mode,
        include_rayleigh = result.include_rayleigh,
        candidate_count = result.candidate_count,
        probe_step = result.probe_step,
        max_log_scale = result.max_log_scale,
        base_objective = result.base_objective,
        best_ridge_lambda = result.best_ridge_lambda,
        best_exact_objective = result.best_exact_objective,
        best_objective_reduction = result.best_objective_reduction,
        best_worst_toa_forcing_error_w_m2 =
            result.best_worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            result.best_worst_surface_forcing_error_w_m2,
        accepted = result.accepted,
        accepted_move_count = length(result.accepted_moves),
    )
end

function structural_optimizer_sweep_result()
    rows = NamedTuple[]
    for config in structural_optimizer_sweep_configs()
        result = with_sweep_env(config) do
            constrained_table_optimizer_result()
        end
        push!(rows, compact_sweep_row(config, result))
    end
    best = isempty(rows) ? nothing :
        rows[argmin([row.best_exact_objective for row in rows])]
    return (
        case = "reduced_ecckd_structural_optimizer_sweep",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = best !== nothing && best.accepted ?
            "structural_optimizer_sweep_improved" :
            "structural_optimizer_sweep_rejected",
        config_count = length(rows),
        best_label = best === nothing ? "" : best.label,
        best_base_objective = best === nothing ? NaN : best.base_objective,
        best_exact_objective = best === nothing ? NaN : best.best_exact_objective,
        best_objective_reduction =
            best === nothing ? NaN : best.best_objective_reduction,
        best_worst_toa_forcing_error_w_m2 =
            best === nothing ? NaN : best.best_worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            best === nothing ? NaN : best.best_worst_surface_forcing_error_w_m2,
        rows = rows,
    )
end

function structural_optimizer_sweep_markdown(result)
    lines = String[
        "# Reduced ecCKD Structural Optimizer Sweep",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Configurations | $(result.config_count) |",
        "| Best label | $(result.best_label) |",
        "| Best base objective | $(@sprintf("%.12g", result.best_base_objective)) |",
        "| Best exact objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best TOA forcing | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "",
        "This diagnostic runs the existing constrained table optimizer against",
        "the retained boundary-table-continuation model with multiple structural",
        "candidate and residual definitions. It does not overwrite the retained",
        "optimizer artifact.",
        "",
        "## Configurations",
        "",
        "| Label | Scope | Residual | Base objective | Best objective | Reduction | TOA | Surface | Accepted |",
        "|---|---|---|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.rows
        push!(lines, "| $(row.label) | $(row.candidate_scope) | $(row.residual_mode) | $(@sprintf("%.12g", row.base_objective)) | $(@sprintf("%.12g", row.best_exact_objective)) | $(@sprintf("%.12g", row.best_objective_reduction)) | $(@sprintf("%.12g", row.best_worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.best_worst_surface_forcing_error_w_m2)) | $(row.accepted) |")
    end
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? structural_optimizer_sweep_result() : result
    mkpath(dirname(STRUCTURAL_OPTIMIZER_SWEEP_JSON))
    write(STRUCTURAL_OPTIMIZER_SWEEP_JSON, json_object(result) * "\n")
    write(STRUCTURAL_OPTIMIZER_SWEEP_MD, structural_optimizer_sweep_markdown(result))
    print(structural_optimizer_sweep_markdown(result))
    println("Wrote $STRUCTURAL_OPTIMIZER_SWEEP_JSON")
    println("Wrote $STRUCTURAL_OPTIMIZER_SWEEP_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
