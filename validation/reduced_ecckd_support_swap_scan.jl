include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_subset_search.jl"))

const SUPPORT_SWAP_SCAN_JSON =
    validation_results_path("reduced_ecckd_support_swap_scan.json")
const SUPPORT_SWAP_SCAN_MD =
    validation_results_path("reduced_ecckd_support_swap_scan.md")

const SUBSET_HARDGATE_SW_16_INDICES =
    [2, 4, 7, 10, 11, 12, 14, 16, 18, 21, 22, 27, 28, 30, 31, 32]

support_swap_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_SUPPORT_SWAP_ITERATIONS", "800"))

support_swap_pnorm() =
    parse(Int, get(ENV, "RH_REDUCED_SUPPORT_SWAP_P", "16"))

support_swap_exact_top_n() =
    parse(Int, get(ENV, "RH_REDUCED_SUPPORT_SWAP_EXACT_TOP_N", "12"))

function support_swap_seed_specs()
    (
        (
            label = "canonical_weighted_greedy_support",
            indices = collect(WEIGHTED_GREEDY_SW_16_INDICES),
        ),
        (
            label = "subset_search_hardgate_support",
            indices = collect(SUBSET_HARDGATE_SW_16_INDICES),
        ),
    )
end

function support_swap_candidates(seed_indices, nfull)
    selected = Set(seed_indices)
    rows = NamedTuple[]
    for removed in seed_indices
        for added in 1:nfull
            added in selected && continue
            candidate = sort([ig for ig in seed_indices if ig != removed])
            push!(candidate, added)
            sort!(candidate)
            length(unique(candidate)) == length(seed_indices) || continue
            push!(rows, (
                removed_gpoint = removed,
                added_gpoint = added,
                indices = candidate,
            ))
        end
    end
    return rows
end

function approximate_support_swap(context, full_weights, candidate)
    initial_weights = normalized_subset(full_weights, candidate.indices)
    weights, approximate_objective =
        optimized_subset_weights_hardgate(
            context,
            candidate.indices;
            initial_weights = initial_weights,
            max_iterations = support_swap_iterations(),
            p = support_swap_pnorm(),
        )
    return merge(candidate, (
        selected_weights = collect(weights),
        approximate_hardgate_objective = approximate_objective,
    ))
end

function exact_support_swap(full_model, approximate)
    exact = subset_exact_metrics(full_model, approximate.indices,
                                 approximate.selected_weights)
    return merge(approximate, (
        exact_objective = exact_result_objective(exact),
        passed_hard_thresholds = exact.passed_hard_thresholds,
        worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in exact.cases),
        worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in exact.cases),
        worst_heating_rate_rmse_k_day =
            maximum(case.variables.heating_rate.rmse for case in exact.cases),
    ))
end

function support_swap_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    context = search_context(full_model)
    nfull = size(full_model.shortwave_absorption, 1)
    exact_top_n = support_swap_exact_top_n()
    seeds = NamedTuple[]
    for seed in support_swap_seed_specs()
        baseline_weights = normalized_subset(full_model.shortwave_weights, seed.indices)
        baseline_exact = subset_exact_metrics(full_model, seed.indices,
                                              baseline_weights)
        candidates = [
            approximate_support_swap(context, full_model.shortwave_weights, candidate)
            for candidate in support_swap_candidates(seed.indices, nfull)
        ]
        sort!(candidates; by = row -> row.approximate_hardgate_objective)
        exact_candidates = [
            exact_support_swap(full_model, candidate)
            for candidate in candidates[1:min(exact_top_n, length(candidates))]
        ]
        sort!(exact_candidates; by = row -> row.exact_objective)
        best_exact = isempty(exact_candidates) ? nothing : first(exact_candidates)
        push!(seeds, (
            label = seed.label,
            baseline_indices = seed.indices,
            baseline_exact_objective = exact_result_objective(baseline_exact),
            candidate_count = length(candidates),
            exact_candidate_count = length(exact_candidates),
            best_exact_objective =
                best_exact === nothing ? exact_result_objective(baseline_exact) :
                best_exact.exact_objective,
            best_improved =
                best_exact !== nothing &&
                best_exact.exact_objective < exact_result_objective(baseline_exact),
            best_passed_hard_thresholds =
                best_exact !== nothing && best_exact.passed_hard_thresholds,
            best_candidate = best_exact,
            exact_candidates = exact_candidates,
        ))
    end
    all_exact_candidates = vcat([collect(seed.exact_candidates) for seed in seeds]...)
    sort!(all_exact_candidates; by = row -> row.exact_objective)
    best_overall = isempty(all_exact_candidates) ? nothing : first(all_exact_candidates)
    return (
        case = "reduced_ecckd_support_swap_scan",
        timestamp_utc = string(Dates.now()),
        status = best_overall !== nothing && best_overall.passed_hard_thresholds ?
                 "passed" : "failed_threshold",
        search_objective = "single_swap_hardgate_weight_refit",
        support_swap_iterations = support_swap_iterations(),
        support_swap_pnorm = support_swap_pnorm(),
        exact_top_n = exact_top_n,
        seed_count = length(seeds),
        best_overall_objective =
            best_overall === nothing ? NaN : best_overall.exact_objective,
        best_overall_indices =
            best_overall === nothing ? Int[] : collect(best_overall.indices),
        best_overall_removed_gpoint =
            best_overall === nothing ? 0 : best_overall.removed_gpoint,
        best_overall_added_gpoint =
            best_overall === nothing ? 0 : best_overall.added_gpoint,
        best_overall_passed_hard_thresholds =
            best_overall !== nothing && best_overall.passed_hard_thresholds,
        seeds = seeds,
    )
end

function support_swap_markdown(result)
    lines = String[
        "# Reduced ecCKD Support-Swap Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Search objective | $(result.search_objective) |",
        "| Weight iterations | $(result.support_swap_iterations) |",
        "| p-norm | $(result.support_swap_pnorm) |",
        "| Exact candidates per seed | $(result.exact_top_n) |",
        "| Best overall objective | $(@sprintf("%.12g", result.best_overall_objective)) |",
        "| Best overall passed | $(result.best_overall_passed_hard_thresholds) |",
        "| Best removed g-point | $(result.best_overall_removed_gpoint) |",
        "| Best added g-point | $(result.best_overall_added_gpoint) |",
        "| Best indices | `$(join(result.best_overall_indices, ", "))` |",
        "",
        "This diagnostic changes the 16-g support by one shortwave g-point,",
        "refits nonnegative weights against the hard-gate residual basis, and",
        "exactly evaluates the best approximate candidates. It does not promote",
        "a new canonical support by itself.",
        "",
    ]
    for seed in result.seeds
        push!(lines, "## $(seed.label)")
        push!(lines, "")
        push!(lines, "- baseline objective: $(@sprintf("%.12g", seed.baseline_exact_objective))")
        push!(lines, "- candidates: $(seed.candidate_count)")
        push!(lines, "- exact candidates: $(seed.exact_candidate_count)")
        push!(lines, "- best exact objective: $(@sprintf("%.12g", seed.best_exact_objective))")
        push!(lines, "- best improved over baseline: $(seed.best_improved)")
        push!(lines, "- best passed hard thresholds: $(seed.best_passed_hard_thresholds)")
        push!(lines, "")
        push!(lines, "| Removed | Added | Exact objective | TOA forcing | Surface forcing | Heating RMSE | Passed | Indices |")
        push!(lines, "|---:|---:|---:|---:|---:|---:|---:|---|")
        for row in seed.exact_candidates
            push!(lines,
                  "| $(row.removed_gpoint) | $(row.added_gpoint) | $(@sprintf("%.12g", row.exact_objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_surface_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_heating_rate_rmse_k_day)) | $(row.passed_hard_thresholds) | `$(join(row.indices, ", "))` |")
        end
        push!(lines, "")
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = support_swap_scan_result()
    mkpath(dirname(SUPPORT_SWAP_SCAN_JSON))
    markdown = support_swap_markdown(result)
    write(SUPPORT_SWAP_SCAN_JSON, json_object(result))
    write(SUPPORT_SWAP_SCAN_MD, markdown)
    print(markdown)
    println("Wrote $SUPPORT_SWAP_SCAN_JSON")
    println("Wrote $SUPPORT_SWAP_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
