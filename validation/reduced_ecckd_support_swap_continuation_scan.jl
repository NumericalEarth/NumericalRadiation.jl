include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_support_swap_scan.jl"))

const SUPPORT_SWAP_CONTINUATION_SCAN_JSON =
    validation_results_path("reduced_ecckd_support_swap_continuation_scan.json")
const SUPPORT_SWAP_CONTINUATION_SCAN_MD =
    validation_results_path("reduced_ecckd_support_swap_continuation_scan.md")

function json_int_array_field(text, key)
    match = Base.match(Regex("\"$key\"\\s*:\\s*\\[([^\\]]*)\\]"), text)
    match === nothing && return Int[]
    raw = strip(match.captures[1])
    isempty(raw) && return Int[]
    return [parse(Int, strip(capture)) for capture in split(raw, ',')
            if !isempty(strip(capture))]
end

function support_swap_continuation_seed_indices()
    if isfile(SUPPORT_SWAP_SCAN_JSON)
        text = read(SUPPORT_SWAP_SCAN_JSON, String)
        indices = json_int_array_field(text, "best_overall_indices")
        length(indices) == 16 && return indices
    end
    return [2, 4, 7, 8, 10, 11, 12, 14, 16, 18, 21, 22, 27, 28, 30, 32]
end

support_swap_continuation_exact_top_n() =
    parse(Int, get(ENV, "RH_REDUCED_SUPPORT_SWAP_CONTINUATION_EXACT_TOP_N", "16"))

function support_swap_continuation_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    context = search_context(full_model)
    nfull = size(full_model.shortwave_absorption, 1)
    seed_indices = support_swap_continuation_seed_indices()
    seed_weights, seed_approximate_objective =
        optimized_subset_weights_hardgate(
            context,
            seed_indices;
            initial_weights = normalized_subset(full_model.shortwave_weights, seed_indices),
            max_iterations = support_swap_iterations(),
            p = support_swap_pnorm(),
        )
    seed_exact = subset_exact_metrics(full_model, seed_indices, seed_weights)
    candidates = [
        approximate_support_swap(context, full_model.shortwave_weights, candidate)
        for candidate in support_swap_candidates(seed_indices, nfull)
    ]
    sort!(candidates; by = row -> row.approximate_hardgate_objective)
    exact_top_n = support_swap_continuation_exact_top_n()
    exact_candidates = [
        exact_support_swap(full_model, candidate)
        for candidate in candidates[1:min(exact_top_n, length(candidates))]
    ]
    sort!(exact_candidates; by = row -> row.exact_objective)
    best = isempty(exact_candidates) ? nothing : first(exact_candidates)
    seed_objective = exact_result_objective(seed_exact)
    return (
        case = "reduced_ecckd_support_swap_continuation_scan",
        timestamp_utc = string(Dates.now()),
        status = best !== nothing && best.passed_hard_thresholds ?
                 "passed" : "failed_threshold",
        search_objective = "second_swap_hardgate_weight_refit",
        support_swap_iterations = support_swap_iterations(),
        support_swap_pnorm = support_swap_pnorm(),
        exact_top_n = exact_top_n,
        seed_indices = seed_indices,
        seed_approximate_objective = seed_approximate_objective,
        seed_exact_objective = seed_objective,
        candidate_count = length(candidates),
        exact_candidate_count = length(exact_candidates),
        best_objective = best === nothing ? seed_objective : best.exact_objective,
        best_objective_reduction =
            best === nothing ? 0.0 : seed_objective - best.exact_objective,
        best_passed_hard_thresholds =
            best !== nothing && best.passed_hard_thresholds,
        best_removed_gpoint = best === nothing ? 0 : best.removed_gpoint,
        best_added_gpoint = best === nothing ? 0 : best.added_gpoint,
        best_indices = best === nothing ? seed_indices : collect(best.indices),
        exact_candidates = exact_candidates,
    )
end

function support_swap_continuation_markdown(result)
    lines = String[
        "# Reduced ecCKD Support-Swap Continuation Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Search objective | $(result.search_objective) |",
        "| Weight iterations | $(result.support_swap_iterations) |",
        "| p-norm | $(result.support_swap_pnorm) |",
        "| Exact candidates | $(result.exact_candidate_count) |",
        "| Seed objective | $(@sprintf("%.12g", result.seed_exact_objective)) |",
        "| Best objective | $(@sprintf("%.12g", result.best_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best passed | $(result.best_passed_hard_thresholds) |",
        "| Best removed g-point | $(result.best_removed_gpoint) |",
        "| Best added g-point | $(result.best_added_gpoint) |",
        "| Seed indices | `$(join(result.seed_indices, ", "))` |",
        "| Best indices | `$(join(result.best_indices, ", "))` |",
        "",
        "This diagnostic starts from the best one-g-point support-swap result,",
        "then scans one additional shortwave g-point replacement with a fresh",
        "nonnegative hard-gate weight refit. It tests whether the failed one-swap",
        "neighborhood opens a nearby two-swap escape direction.",
        "",
        "| Removed | Added | Exact objective | TOA forcing | Surface forcing | Heating RMSE | Passed | Indices |",
        "|---:|---:|---:|---:|---:|---:|---:|---|",
    ]
    for row in result.exact_candidates
        push!(lines,
              "| $(row.removed_gpoint) | $(row.added_gpoint) | $(@sprintf("%.12g", row.exact_objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_surface_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_heating_rate_rmse_k_day)) | $(row.passed_hard_thresholds) | `$(join(row.indices, ", "))` |")
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = support_swap_continuation_scan_result()
    mkpath(dirname(SUPPORT_SWAP_CONTINUATION_SCAN_JSON))
    markdown = support_swap_continuation_markdown(result)
    write(SUPPORT_SWAP_CONTINUATION_SCAN_JSON, json_object(result))
    write(SUPPORT_SWAP_CONTINUATION_SCAN_MD, markdown)
    print(markdown)
    println("Wrote $SUPPORT_SWAP_CONTINUATION_SCAN_JSON")
    println("Wrote $SUPPORT_SWAP_CONTINUATION_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
