include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const BOUNDARY_BASE_CONSTRAINED_TABLE_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_boundary_base_constrained_table_optimizer.json")
const BOUNDARY_BASE_CONSTRAINED_TABLE_OPTIMIZER_MD =
    validation_results_path("reduced_ecckd_boundary_base_constrained_table_optimizer.md")

function set_boundary_base_default!(key, value)
    haskey(ENV, key) || (ENV[key] = value)
    return ENV[key]
end

function boundary_base_constrained_table_optimizer_result()
    set_boundary_base_default!(
        "RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE",
        "boundary_weight_refit",
    )
    set_boundary_base_default!(
        "RH_REDUCED_CONSTRAINED_TABLE_SCOPE",
        "all_global_residual_probe",
    )
    set_boundary_base_default!("RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES", "16")
    set_boundary_base_default!("RH_REDUCED_CONSTRAINED_TABLE_PROBE_POOL_MULTIPLIER", "4")
    set_boundary_base_default!("RH_REDUCED_CONSTRAINED_TABLE_PROBE_STEP", "0.0009765625")
    set_boundary_base_default!("RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE", "0.001953125")
    set_boundary_base_default!("RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH", "false")
    return constrained_table_optimizer_result()
end

function boundary_base_constrained_table_markdown(result)
    lines = String[
        "# Reduced ecCKD Boundary-Base Constrained Table Optimizer",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base mode | $(result.base_mode) |",
        "| Candidate scope | $(result.candidate_scope) |",
        "| Residual mode | $(result.residual_mode) |",
        "| Include Rayleigh candidates | $(result.include_rayleigh) |",
        "| Candidate count | $(result.candidate_count) |",
        "| Probe step | $(@sprintf("%.12g", result.probe_step)) |",
        "| Max log scale | $(@sprintf("%.12g", result.max_log_scale)) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Best exact objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best TOA forcing error | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing error | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Accepted | $(result.accepted) |",
        "",
        "This artifact is separate from the canonical constrained-table optimizer.",
        "It starts from the boundary-aware post-constrained weight-refit model",
        "and records only boundary-base table continuations.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? boundary_base_constrained_table_optimizer_result() : result
    mkpath(dirname(BOUNDARY_BASE_CONSTRAINED_TABLE_OPTIMIZER_JSON))
    write(BOUNDARY_BASE_CONSTRAINED_TABLE_OPTIMIZER_JSON, json_object(result) * "\n")
    write(BOUNDARY_BASE_CONSTRAINED_TABLE_OPTIMIZER_MD,
          boundary_base_constrained_table_markdown(result))
    print(boundary_base_constrained_table_markdown(result))
    println("Wrote $BOUNDARY_BASE_CONSTRAINED_TABLE_OPTIMIZER_JSON")
    println("Wrote $BOUNDARY_BASE_CONSTRAINED_TABLE_OPTIMIZER_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
