include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_support_swap_scan.jl"))

const SUPPORT_EXPANSION_SCAN_JSON =
    validation_results_path("reduced_ecckd_support_expansion_scan.json")
const SUPPORT_EXPANSION_SCAN_MD =
    validation_results_path("reduced_ecckd_support_expansion_scan.md")

support_expansion_exact_top_n() =
    parse(Int, get(ENV, "RH_REDUCED_SUPPORT_EXPANSION_EXACT_TOP_N", "16"))

function support_expansion_candidates(seed_indices, nfull)
    selected = Set(seed_indices)
    missing = [ig for ig in 1:nfull if !(ig in selected)]
    rows = NamedTuple[]
    for added in missing
        indices = sort(vcat(seed_indices, added))
        push!(rows, (
            added_gpoints = [added],
            indices = indices,
        ))
    end
    for i in 1:length(missing)
        for j in i + 1:length(missing)
            added = [missing[i], missing[j]]
            indices = sort(vcat(seed_indices, added))
            push!(rows, (
                added_gpoints = added,
                indices = indices,
            ))
        end
    end
    return rows
end

function approximate_support_expansion(context, full_weights, candidate)
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

function exact_support_expansion(full_model, approximate)
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

function support_expansion_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    context = search_context(full_model)
    nfull = size(full_model.shortwave_absorption, 1)
    exact_top_n = support_expansion_exact_top_n()
    seeds = NamedTuple[]
    for seed in support_swap_seed_specs()
        candidates = [
            approximate_support_expansion(context, full_model.shortwave_weights, candidate)
            for candidate in support_expansion_candidates(seed.indices, nfull)
        ]
        sort!(candidates; by = row -> row.approximate_hardgate_objective)
        exact_candidates = [
            exact_support_expansion(full_model, candidate)
            for candidate in candidates[1:min(exact_top_n, length(candidates))]
        ]
        sort!(exact_candidates; by = row -> row.exact_objective)
        best_exact = isempty(exact_candidates) ? nothing : first(exact_candidates)
        push!(seeds, (
            label = seed.label,
            seed_indices = seed.indices,
            candidate_count = length(candidates),
            exact_candidate_count = length(exact_candidates),
            best_exact_objective = best_exact === nothing ? NaN : best_exact.exact_objective,
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
        case = "reduced_ecckd_support_expansion_scan",
        timestamp_utc = string(Dates.now()),
        status = best_overall !== nothing && best_overall.passed_hard_thresholds ?
                 "passed" : "failed_threshold",
        search_objective = "support_expansion_hardgate_weight_refit",
        support_swap_iterations = support_swap_iterations(),
        support_swap_pnorm = support_swap_pnorm(),
        exact_top_n = exact_top_n,
        seed_count = length(seeds),
        best_overall_objective =
            best_overall === nothing ? NaN : best_overall.exact_objective,
        best_overall_ng =
            best_overall === nothing ? 0 : length(best_overall.indices),
        best_overall_added_gpoints =
            best_overall === nothing ? Int[] : collect(best_overall.added_gpoints),
        best_overall_indices =
            best_overall === nothing ? Int[] : collect(best_overall.indices),
        best_overall_passed_hard_thresholds =
            best_overall !== nothing && best_overall.passed_hard_thresholds,
        seeds = seeds,
    )
end

function support_expansion_markdown(result)
    lines = String[
        "# Reduced ecCKD Support Expansion Scan",
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
        "| Best overall g-points | $(result.best_overall_ng) |",
        "| Best overall passed | $(result.best_overall_passed_hard_thresholds) |",
        "| Best added g-points | `$(join(result.best_overall_added_gpoints, ", "))` |",
        "| Best indices | `$(join(result.best_overall_indices, ", "))` |",
        "",
        "This diagnostic keeps the seed support and adds one or two shortwave",
        "g-points, then refits nonnegative weights against the hard-gate residual",
        "basis. It tests whether a 17- or 18-g reduced target is a plausible",
        "escape from the current 16-g acceptance blocker.",
        "",
    ]
    for seed in result.seeds
        push!(lines, "## $(seed.label)")
        push!(lines, "")
        push!(lines, "- candidates: $(seed.candidate_count)")
        push!(lines, "- exact candidates: $(seed.exact_candidate_count)")
        push!(lines, "- best exact objective: $(@sprintf("%.12g", seed.best_exact_objective))")
        push!(lines, "- best passed hard thresholds: $(seed.best_passed_hard_thresholds)")
        push!(lines, "")
        push!(lines, "| Added | ng | Exact objective | TOA forcing | Surface forcing | Heating RMSE | Passed | Indices |")
        push!(lines, "|---|---:|---:|---:|---:|---:|---:|---|")
        for row in seed.exact_candidates
            push!(lines,
                  "| `$(join(row.added_gpoints, ", "))` | $(length(row.indices)) | $(@sprintf("%.12g", row.exact_objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_surface_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_heating_rate_rmse_k_day)) | $(row.passed_hard_thresholds) | `$(join(row.indices, ", "))` |")
        end
        push!(lines, "")
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = support_expansion_scan_result()
    mkpath(dirname(SUPPORT_EXPANSION_SCAN_JSON))
    markdown = support_expansion_markdown(result)
    write(SUPPORT_EXPANSION_SCAN_JSON, json_object(result))
    write(SUPPORT_EXPANSION_SCAN_MD, markdown)
    print(markdown)
    println("Wrote $SUPPORT_EXPANSION_SCAN_JSON")
    println("Wrote $SUPPORT_EXPANSION_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
