include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const RETAINED_STRUCTURAL_CONTINUATION4_JSON =
    validation_results_path("reduced_ecckd_retained_structural_continuation4.json")
const RETAINED_STRUCTURAL_CONTINUATION4_MD =
    validation_results_path("reduced_ecckd_retained_structural_continuation4.md")

function set_retained_structural_continuation4_default!(key, value)
    haskey(ENV, key) || (ENV[key] = value)
    return ENV[key]
end

function retained_structural_continuation4_result()
    set_retained_structural_continuation4_default!(
        "RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE",
        "boundary_table_continuation",
    )
    set_retained_structural_continuation4_default!(
        "RH_REDUCED_IGNORE_RETAINED_STRUCTURAL_CONTINUATION4",
        "true",
    )
    set_retained_structural_continuation4_default!(
        "RH_REDUCED_CONSTRAINED_TABLE_SCOPE",
        "all_global_residual_probe",
    )
    set_retained_structural_continuation4_default!(
        "RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE",
        "all_shortwave",
    )
    set_retained_structural_continuation4_default!(
        "RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES",
        "12",
    )
    set_retained_structural_continuation4_default!(
        "RH_REDUCED_CONSTRAINED_TABLE_PROBE_STEP",
        "0.0001220703125",
    )
    set_retained_structural_continuation4_default!(
        "RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE",
        "0.0009765625",
    )
    set_retained_structural_continuation4_default!(
        "RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH",
        "true",
    )
    set_retained_structural_continuation4_default!(
        "RH_REDUCED_CONSTRAINED_TABLE_RIDGE_LAMBDAS",
        "1.0e-4,1.0e-2,1.0,100.0,1.0e4,1.0e6,1.0e8",
    )
    return pareto_guarded_structural_result(constrained_table_optimizer_result())
end

function retained_structural_continuation4_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Structural Continuation 4",
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
        "| Best ridge lambda | $(@sprintf("%.12g", result.best_ridge_lambda)) |",
        "| Best exact objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best TOA forcing error | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing error | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Pareto safe | $(result.pareto_safe) |",
        "| Accepted moves | $(length(result.accepted_moves)) |",
        "| Accepted | $(result.accepted) |",
        "",
        "This retained continuation starts from the current reduced model after",
        "the third retained structural continuation and records another",
        "smaller-trust-region all-shortwave residual constrained table step.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? retained_structural_continuation4_result() :
        result
    mkpath(dirname(RETAINED_STRUCTURAL_CONTINUATION4_JSON))
    write(RETAINED_STRUCTURAL_CONTINUATION4_JSON, json_object(result) * "\n")
    write(RETAINED_STRUCTURAL_CONTINUATION4_MD,
          retained_structural_continuation4_markdown(result))
    print(retained_structural_continuation4_markdown(result))
    println("Wrote $RETAINED_STRUCTURAL_CONTINUATION4_JSON")
    println("Wrote $RETAINED_STRUCTURAL_CONTINUATION4_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
