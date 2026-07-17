include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_support_expansion_scan.jl"))

const SUPPORT_EXPANSION_REFIT_SCAN_JSON =
    validation_results_path("reduced_ecckd_support_expansion_refit_scan.json")
const SUPPORT_EXPANSION_REFIT_SCAN_MD =
    validation_results_path("reduced_ecckd_support_expansion_refit_scan.md")

support_expansion_refit_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_SUPPORT_EXPANSION_REFIT_ITERATIONS", "4000"))

const SUPPORT_EXPANSION_REFIT_CANDIDATES = (
    (
        label = "subset_hardgate_plus_3_6",
        seed_indices = SUBSET_HARDGATE_SW_16_INDICES,
        indices = [2, 3, 4, 6, 7, 10, 11, 12, 14, 16, 18, 21, 22, 27, 28, 30, 31, 32],
    ),
    (
        label = "subset_hardgate_plus_5_6",
        seed_indices = SUBSET_HARDGATE_SW_16_INDICES,
        indices = [2, 4, 5, 6, 7, 10, 11, 12, 14, 16, 18, 21, 22, 27, 28, 30, 31, 32],
    ),
    (
        label = "subset_hardgate_plus_1",
        seed_indices = SUBSET_HARDGATE_SW_16_INDICES,
        indices = [1, 2, 4, 7, 10, 11, 12, 14, 16, 18, 21, 22, 27, 28, 30, 31, 32],
    ),
    (
        label = "canonical_plus_7_11",
        seed_indices = WEIGHTED_GREEDY_SW_16_INDICES,
        indices = [1, 4, 7, 9, 10, 11, 12, 13, 14, 16, 21, 22, 25, 27, 28, 30, 31, 32],
    ),
    (
        label = "canonical_plus_7",
        seed_indices = WEIGHTED_GREEDY_SW_16_INDICES,
        indices = [1, 4, 7, 9, 10, 12, 13, 14, 16, 21, 22, 25, 27, 28, 30, 31, 32],
    ),
)

function padded_seed_weights(indices, seed_indices, seed_weights; epsilon = 0.0)
    values = fill(epsilon, length(indices))
    for (seed_position, ig) in enumerate(seed_indices)
        target_position = findfirst(==(ig), indices)
        target_position === nothing && continue
        values[target_position] = seed_weights[seed_position]
    end
    return simplex_projection(values)
end

function support_expansion_refit_starts(context, full_weights, candidate; iterations)
    seed_weights, seed_objective =
        optimized_subset_weights_hardgate(
            context,
            candidate.seed_indices;
            initial_weights = normalized_subset(full_weights, candidate.seed_indices),
            max_iterations = iterations,
            p = support_swap_pnorm(),
        )
    return (
        seed_objective = seed_objective,
        starts = (
            (
                label = "official_normalized",
                weights = normalized_subset(full_weights, candidate.indices),
            ),
            (
                label = "uniform",
                weights = fill(inv(length(candidate.indices)), length(candidate.indices)),
            ),
            (
                label = "seed_zero_padded",
                weights = padded_seed_weights(candidate.indices, candidate.seed_indices,
                                              seed_weights),
            ),
            (
                label = "seed_epsilon_padded",
                weights = padded_seed_weights(candidate.indices, candidate.seed_indices,
                                              seed_weights; epsilon = 1e-4),
            ),
        ),
    )
end

function support_expansion_refit_candidate(context, full_model, candidate; iterations)
    start_bundle = support_expansion_refit_starts(context, full_model.shortwave_weights,
                                                 candidate; iterations)
    trials = NamedTuple[]
    for start in start_bundle.starts
        weights, approximate_objective =
            optimized_subset_weights_hardgate(
                context,
                candidate.indices;
                initial_weights = start.weights,
                max_iterations = iterations,
                p = support_swap_pnorm(),
            )
        exact = subset_exact_metrics(full_model, candidate.indices, weights)
        push!(trials, (
            start_label = start.label,
            approximate_objective = approximate_objective,
            exact_objective = exact_result_objective(exact),
            passed_hard_thresholds = exact.passed_hard_thresholds,
            worst_toa_forcing_error_w_m2 =
                maximum(case.toa_forcing_max_abs for case in exact.cases),
            worst_surface_forcing_error_w_m2 =
                maximum(case.surface_forcing_max_abs for case in exact.cases),
            worst_heating_rate_rmse_k_day =
                maximum(case.variables.heating_rate.rmse for case in exact.cases),
            selected_weights = collect(weights),
        ))
    end
    best = argmin(row -> row.exact_objective, trials)
    return (
        label = candidate.label,
        seed_indices = collect(candidate.seed_indices),
        indices = collect(candidate.indices),
        added_gpoints = setdiff(candidate.indices, candidate.seed_indices),
        seed_objective = start_bundle.seed_objective,
        best_start_label = best.start_label,
        best_objective = best.exact_objective,
        best_approximate_objective = best.approximate_objective,
        best_passed_hard_thresholds = best.passed_hard_thresholds,
        best_worst_toa_forcing_error_w_m2 = best.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 = best.worst_surface_forcing_error_w_m2,
        best_worst_heating_rate_rmse_k_day = best.worst_heating_rate_rmse_k_day,
        trials = trials,
    )
end

function support_expansion_refit_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    context = search_context(full_model)
    iterations = support_expansion_refit_iterations()
    candidates = [
        support_expansion_refit_candidate(context, full_model, candidate; iterations)
        for candidate in SUPPORT_EXPANSION_REFIT_CANDIDATES
    ]
    sort!(candidates; by = row -> row.best_objective)
    best = first(candidates)
    return (
        case = "reduced_ecckd_support_expansion_refit_scan",
        timestamp_utc = string(Dates.now()),
        status = best.best_passed_hard_thresholds ? "passed" : "failed_threshold",
        search_objective = "support_expansion_multistart_hardgate_weight_refit",
        iterations = iterations,
        pnorm = support_swap_pnorm(),
        candidate_count = length(candidates),
        start_count = length(first(candidates).trials),
        best_label = best.label,
        best_objective = best.best_objective,
        best_start_label = best.best_start_label,
        best_ng = length(best.indices),
        best_added_gpoints = collect(best.added_gpoints),
        best_indices = collect(best.indices),
        best_passed_hard_thresholds = best.best_passed_hard_thresholds,
        candidates = candidates,
    )
end

function support_expansion_refit_markdown(result)
    lines = String[
        "# Reduced ecCKD Support Expansion Refit Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Search objective | $(result.search_objective) |",
        "| Iterations | $(result.iterations) |",
        "| p-norm | $(result.pnorm) |",
        "| Candidates | $(result.candidate_count) |",
        "| Starts per candidate | $(result.start_count) |",
        "| Best label | `$(result.best_label)` |",
        "| Best objective | $(@sprintf("%.12g", result.best_objective)) |",
        "| Best start | `$(result.best_start_label)` |",
        "| Best g-points | $(result.best_ng) |",
        "| Best passed | $(result.best_passed_hard_thresholds) |",
        "| Best added g-points | `$(join(result.best_added_gpoints, ", "))` |",
        "| Best indices | `$(join(result.best_indices, ", "))` |",
        "",
        "This diagnostic reruns the best 17/18-g expansion candidates with",
        "longer hard-gate weight optimization and multiple warm starts, including",
        "zero-padded and epsilon-padded seed weights. It tests whether the",
        "bounded support-expansion rejection was caused by the initial weight",
        "refit rather than by the support itself.",
        "",
        "| Candidate | Added | ng | Seed objective | Best start | Best objective | TOA forcing | Surface forcing | Heating RMSE | Passed |",
        "|---|---|---:|---:|---|---:|---:|---:|---:|---:|",
    ]
    for candidate in result.candidates
        push!(lines,
              "| `$(candidate.label)` | `$(join(candidate.added_gpoints, ", "))` | $(length(candidate.indices)) | $(@sprintf("%.12g", candidate.seed_objective)) | `$(candidate.best_start_label)` | $(@sprintf("%.12g", candidate.best_objective)) | $(@sprintf("%.12g", candidate.best_worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", candidate.best_worst_surface_forcing_error_w_m2)) | $(@sprintf("%.12g", candidate.best_worst_heating_rate_rmse_k_day)) | $(candidate.best_passed_hard_thresholds) |")
    end
    push!(lines, "")
    for candidate in result.candidates
        push!(lines, "## $(candidate.label)")
        push!(lines, "")
        push!(lines, "| Start | Approximate objective | Exact objective | TOA forcing | Surface forcing | Heating RMSE | Passed |")
        push!(lines, "|---|---:|---:|---:|---:|---:|---:|")
        for trial in candidate.trials
            push!(lines,
                  "| `$(trial.start_label)` | $(@sprintf("%.12g", trial.approximate_objective)) | $(@sprintf("%.12g", trial.exact_objective)) | $(@sprintf("%.12g", trial.worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", trial.worst_surface_forcing_error_w_m2)) | $(@sprintf("%.12g", trial.worst_heating_rate_rmse_k_day)) | $(trial.passed_hard_thresholds) |")
        end
        push!(lines, "")
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = support_expansion_refit_scan_result()
    mkpath(dirname(SUPPORT_EXPANSION_REFIT_SCAN_JSON))
    markdown = support_expansion_refit_markdown(result)
    write(SUPPORT_EXPANSION_REFIT_SCAN_JSON, json_object(result))
    write(SUPPORT_EXPANSION_REFIT_SCAN_MD, markdown)
    print(markdown)
    println("Wrote $SUPPORT_EXPANSION_REFIT_SCAN_JSON")
    println("Wrote $SUPPORT_EXPANSION_REFIT_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
