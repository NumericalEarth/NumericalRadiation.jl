include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_grouped_quadrature_search.jl"))

const GROUPED_QUADRATURE_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_grouped_quadrature_weight_refit.json")
const GROUPED_QUADRATURE_WEIGHT_REFIT_MD =
    validation_results_path("reduced_ecckd_grouped_quadrature_weight_refit.md")

function grouped_weight_refit_iterations()
    parse(Int, get(ENV, "RH_REDUCED_GROUPED_WEIGHT_REFIT_ITERATIONS", "3000"))
end

function grouped_weight_candidate(full_model, candidate)
    model = flux_pair_tabulated_model(full_model, candidate.groups)
    initial_weights = collect(model.shortwave_weights)
    refit_weights = optimized_shortwave_weights_maxnorm(
        model;
        initial_weights,
        max_iterations = grouped_weight_refit_iterations(),
        p = 32,
    )
    design, target = hard_gate_shortwave_design(model)
    approximate_objective = maximum(abs, design * refit_weights - target)
    base_cases = [case_metrics(case, model) for case in REDUCED_CASES]
    refit_model = with_shortwave_weights(model, refit_weights)
    refit_cases = [case_metrics(case, refit_model) for case in REDUCED_CASES]
    base_objective = maximum(flux_pair_case_objective, base_cases)
    refit_objective = maximum(flux_pair_case_objective, refit_cases)
    return (
        label = candidate.label,
        groups = candidate.groups,
        base_objective = base_objective,
        refit_objective = refit_objective,
        objective_reduction = base_objective - refit_objective,
        approximate_objective = approximate_objective,
        base_worst_toa_forcing_error =
            maximum(case.toa_forcing_max_abs for case in base_cases),
        base_worst_surface_forcing_error =
            maximum(case.surface_forcing_max_abs for case in base_cases),
        refit_worst_toa_forcing_error =
            maximum(case.toa_forcing_max_abs for case in refit_cases),
        refit_worst_surface_forcing_error =
            maximum(case.surface_forcing_max_abs for case in refit_cases),
        max_abs_weight_delta = maximum(abs.(refit_weights .- initial_weights)),
        passed_hard_thresholds = all(case -> case.passed_hard_thresholds, refit_cases),
        refit_weights = collect(refit_weights),
    )
end

function grouped_quadrature_weight_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    candidates = grouped_quadrature_candidate_groups(full_model)
    rows = [grouped_weight_candidate(full_model, candidate) for candidate in candidates]
    best = argmin(row -> row.refit_objective, rows)
    return (
        case = "reduced_ecckd_grouped_quadrature_weight_refit",
        status = best.passed_hard_thresholds ? "passed_threshold" :
                 best.refit_objective < best.base_objective ?
                 "weight_refit_improved" : "weight_refit_rejected",
        candidate_count = length(rows),
        iterations = grouped_weight_refit_iterations(),
        best_label = best.label,
        best_groups = best.groups,
        best_base_objective = best.base_objective,
        best_refit_objective = best.refit_objective,
        best_objective_reduction = best.objective_reduction,
        best_approximate_objective = best.approximate_objective,
        best_worst_toa_forcing_error = best.refit_worst_toa_forcing_error,
        best_worst_surface_forcing_error = best.refit_worst_surface_forcing_error,
        best_max_abs_weight_delta = best.max_abs_weight_delta,
        passed_hard_thresholds = best.passed_hard_thresholds,
        rows = rows,
    )
end

function grouped_quadrature_weight_refit_markdown(result)
    group_text = join([join(group, "+") for group in result.best_groups], ", ")
    lines = String[
        "# Reduced ecCKD Grouped Quadrature Weight Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Candidates | $(result.candidate_count) |",
        "| Iterations | $(result.iterations) |",
        "| Best label | $(result.best_label) |",
        "| Best base objective | $(@sprintf("%.12g", result.best_base_objective)) |",
        "| Best refit objective | $(@sprintf("%.12g", result.best_refit_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best approximate objective | $(@sprintf("%.12g", result.best_approximate_objective)) |",
        "| Worst TOA forcing | $(@sprintf("%.12g", result.best_worst_toa_forcing_error)) W m^-2 |",
        "| Worst surface forcing | $(@sprintf("%.12g", result.best_worst_surface_forcing_error)) W m^-2 |",
        "| Max absolute weight delta | $(@sprintf("%.12g", result.best_max_abs_weight_delta)) |",
        "| Passed hard thresholds | $(result.passed_hard_thresholds) |",
        "",
        "Best groups: `$(group_text)`",
        "",
        "This diagnostic keeps each grouped quadrature coefficient table fixed but",
        "refits its 16 nonnegative shortwave weights on the hard-gate-scaled",
        "flux, heating-rate, and boundary residual basis before exact evaluation.",
        "",
        "## Candidate Summary",
        "",
        "| Label | Base objective | Refit objective | TOA forcing | Surface forcing | Passed |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for row in sort(collect(result.rows); by = row -> row.refit_objective)
        push!(lines, "| $(row.label) | $(@sprintf("%.12g", row.base_objective)) | $(@sprintf("%.12g", row.refit_objective)) | $(@sprintf("%.12g", row.refit_worst_toa_forcing_error)) | $(@sprintf("%.12g", row.refit_worst_surface_forcing_error)) | $(row.passed_hard_thresholds) |")
    end
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? grouped_quadrature_weight_refit_result() : result
    mkpath(dirname(GROUPED_QUADRATURE_WEIGHT_REFIT_JSON))
    write(GROUPED_QUADRATURE_WEIGHT_REFIT_JSON, json_object(result) * "\n")
    write(GROUPED_QUADRATURE_WEIGHT_REFIT_MD,
          grouped_quadrature_weight_refit_markdown(result))
    print(grouped_quadrature_weight_refit_markdown(result))
    println("Wrote $GROUPED_QUADRATURE_WEIGHT_REFIT_JSON")
    println("Wrote $GROUPED_QUADRATURE_WEIGHT_REFIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
