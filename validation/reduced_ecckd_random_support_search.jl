include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf
using Random

include(joinpath(@__DIR__, "reduced_ecckd_support_swap_scan.jl"))

const RANDOM_SUPPORT_SEARCH_JSON =
    validation_results_path("reduced_ecckd_random_support_search.json")
const RANDOM_SUPPORT_SEARCH_MD =
    validation_results_path("reduced_ecckd_random_support_search.md")

random_support_seed_count() =
    parse(Int, get(ENV, "RH_REDUCED_RANDOM_SUPPORT_SEEDS", "64"))

random_support_exact_top_n() =
    parse(Int, get(ENV, "RH_REDUCED_RANDOM_SUPPORT_EXACT_TOP_N", "16"))

random_support_rng_seed() =
    parse(Int, get(ENV, "RH_REDUCED_RANDOM_SUPPORT_RNG_SEED", "1729"))

function random_support_specs(nfull, nselected)
    rng = MersenneTwister(random_support_rng_seed())
    specs = NamedTuple[
        (
            label = "canonical_weighted_greedy_support",
            indices = collect(WEIGHTED_GREEDY_SW_16_INDICES),
        ),
        (
            label = "subset_search_hardgate_support",
            indices = collect(SUBSET_HARDGATE_SW_16_INDICES),
        ),
    ]
    seen = Set{Tuple{Vararg{Int}}}()
    for spec in specs
        push!(seen, Tuple(spec.indices))
    end
    attempt = 0
    while length(specs) < random_support_seed_count() + 2 &&
          attempt < 20random_support_seed_count()
        attempt += 1
        indices = sort(randperm(rng, nfull)[1:nselected])
        key = Tuple(indices)
        key in seen && continue
        push!(seen, key)
        push!(specs, (
            label = "random_support_$(length(specs) - 1)",
            indices = indices,
        ))
    end
    return specs
end

function approximate_random_support(context, full_weights, spec)
    weights, approximate_objective =
        optimized_subset_weights_hardgate(
            context,
            spec.indices;
            initial_weights = normalized_subset(full_weights, spec.indices),
            max_iterations = support_swap_iterations(),
            p = support_swap_pnorm(),
        )
    return (
        label = spec.label,
        indices = collect(spec.indices),
        selected_weights = collect(weights),
        approximate_objective = approximate_objective,
    )
end

function exact_random_support(full_model, approximate)
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

function random_support_search_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    context = search_context(full_model)
    nfull = size(full_model.shortwave_absorption, 1)
    specs = random_support_specs(nfull, 16)
    approximate = [
        approximate_random_support(context, full_model.shortwave_weights, spec)
        for spec in specs
    ]
    deterministic_exact = [
        exact_random_support(full_model, row)
        for row in approximate
        if row.label in ("canonical_weighted_greedy_support",
                         "subset_search_hardgate_support")
    ]
    sort!(deterministic_exact; by = row -> row.exact_objective)
    sort!(approximate; by = row -> row.approximate_objective)
    exact_top_n = random_support_exact_top_n()
    exact = [
        exact_random_support(full_model, row)
        for row in approximate[1:min(exact_top_n, length(approximate))]
    ]
    sort!(exact; by = row -> row.exact_objective)
    best = first(exact)
    return (
        case = "reduced_ecckd_random_support_search",
        timestamp_utc = string(Dates.now()),
        status = best.passed_hard_thresholds ? "passed" : "failed_threshold",
        search_objective = "random_16g_support_hardgate_weight_refit",
        rng_seed = random_support_rng_seed(),
        random_seed_count = random_support_seed_count(),
        candidate_count = length(approximate),
        exact_top_n = exact_top_n,
        iterations = support_swap_iterations(),
        pnorm = support_swap_pnorm(),
        best_label = best.label,
        best_objective = best.exact_objective,
        best_passed_hard_thresholds = best.passed_hard_thresholds,
        best_indices = collect(best.indices),
        best_worst_toa_forcing_error_w_m2 = best.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 = best.worst_surface_forcing_error_w_m2,
        best_worst_heating_rate_rmse_k_day = best.worst_heating_rate_rmse_k_day,
        deterministic_seed_candidates = deterministic_exact,
        exact_candidates = exact,
    )
end

function random_support_search_markdown(result)
    lines = String[
        "# Reduced ecCKD Random Support Search",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Search objective | $(result.search_objective) |",
        "| RNG seed | $(result.rng_seed) |",
        "| Random seed count | $(result.random_seed_count) |",
        "| Candidates | $(result.candidate_count) |",
        "| Exact candidates | $(length(result.exact_candidates)) |",
        "| Iterations | $(result.iterations) |",
        "| p-norm | $(result.pnorm) |",
        "| Best label | `$(result.best_label)` |",
        "| Best objective | $(@sprintf("%.12g", result.best_objective)) |",
        "| Best passed | $(result.best_passed_hard_thresholds) |",
        "| Best indices | `$(join(result.best_indices, ", "))` |",
        "",
        "This diagnostic samples random 16-g shortwave supports, refits",
        "nonnegative hard-gate weights for each support, and exactly evaluates",
        "the best approximate candidates. It tests whether the deterministic",
        "subset-search seeds missed an easy alternate support basin.",
        "",
        "## Deterministic Seed Supports",
        "",
        "| Label | Exact objective | TOA forcing | Surface forcing | Heating RMSE | Passed | Indices |",
        "|---|---:|---:|---:|---:|---:|---|",
    ]
    for row in result.deterministic_seed_candidates
        push!(lines,
              "| `$(row.label)` | $(@sprintf("%.12g", row.exact_objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_surface_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_heating_rate_rmse_k_day)) | $(row.passed_hard_thresholds) | `$(join(row.indices, ", "))` |")
    end
    append!(lines, [
        "",
        "## Top Approximate Candidates",
        "",
        "| Label | Exact objective | TOA forcing | Surface forcing | Heating RMSE | Passed | Indices |",
        "|---|---:|---:|---:|---:|---:|---|",
    ])
    for row in result.exact_candidates
        push!(lines,
              "| `$(row.label)` | $(@sprintf("%.12g", row.exact_objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_surface_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_heating_rate_rmse_k_day)) | $(row.passed_hard_thresholds) | `$(join(row.indices, ", "))` |")
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = random_support_search_result()
    mkpath(dirname(RANDOM_SUPPORT_SEARCH_JSON))
    markdown = random_support_search_markdown(result)
    write(RANDOM_SUPPORT_SEARCH_JSON, json_object(result))
    write(RANDOM_SUPPORT_SEARCH_MD, markdown)
    print(markdown)
    println("Wrote $RANDOM_SUPPORT_SEARCH_JSON")
    println("Wrote $RANDOM_SUPPORT_SEARCH_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
