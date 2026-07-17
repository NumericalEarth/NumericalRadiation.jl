include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const BOUNDARY_TABLE_CONTINUATION_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_boundary_table_continuation_optimizer.json")
const BOUNDARY_TABLE_CONTINUATION_OPTIMIZER_MD =
    validation_results_path("reduced_ecckd_boundary_table_continuation_optimizer.md")

function set_boundary_table_continuation_default!(key, value)
    haskey(ENV, key) || (ENV[key] = value)
    return ENV[key]
end

function boundary_table_continuation_optimizer_result()
    set_boundary_table_continuation_default!(
        "RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE",
        "boundary_table_post_descent",
    )
    set_boundary_table_continuation_default!(
        "RH_REDUCED_CONSTRAINED_TABLE_SCOPE",
        "all_global_residual_probe",
    )
    set_boundary_table_continuation_default!(
        "RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE",
        "toa",
    )
    set_boundary_table_continuation_default!("RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES", "16")
    set_boundary_table_continuation_default!("RH_REDUCED_CONSTRAINED_TABLE_PROBE_POOL_MULTIPLIER", "4")
    set_boundary_table_continuation_default!("RH_REDUCED_CONSTRAINED_TABLE_PROBE_STEP", "0.0009765625")
    set_boundary_table_continuation_default!("RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE", "0.00390625")
    set_boundary_table_continuation_default!("RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH", "false")
    return constrained_table_optimizer_result()
end

function boundary_table_continuation_markdown(result)
    lines = String[
        "# Reduced ecCKD Boundary-Table Continuation Optimizer",
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
        "This artifact starts from the retained boundary-table post-descent",
        "state and records only additional continuation moves. It is consumed",
        "after the boundary-base, coordinate-scan, pair-scan, and coordinate",
        "descent artifacts.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? boundary_table_continuation_optimizer_result() : result
    mkpath(dirname(BOUNDARY_TABLE_CONTINUATION_OPTIMIZER_JSON))
    write(BOUNDARY_TABLE_CONTINUATION_OPTIMIZER_JSON, json_object(result) * "\n")
    write(BOUNDARY_TABLE_CONTINUATION_OPTIMIZER_MD,
          boundary_table_continuation_markdown(result))
    print(boundary_table_continuation_markdown(result))
    println("Wrote $BOUNDARY_TABLE_CONTINUATION_OPTIMIZER_JSON")
    println("Wrote $BOUNDARY_TABLE_CONTINUATION_OPTIMIZER_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
