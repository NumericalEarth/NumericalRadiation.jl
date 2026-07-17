include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_subset_search.jl"))

const HARDGATE_SUBSET_JSON =
    validation_results_path("reduced_ecckd_hardgate_subset_search.json")
const HARDGATE_SUBSET_MD =
    validation_results_path("reduced_ecckd_hardgate_subset_search.md")

function hardgate_full_design(context)
    nfull = length(context[1].basis)
    columns = Vector{Vector{Float64}}(undef, nfull)
    targets = Vector{Float64}[]
    for case in context
        push!(targets, subset_hard_gate_metric_vector(case.reference))
    end
    for ig in 1:nfull
        blocks = Vector{Float64}[]
        for case in context
            push!(blocks, subset_hard_gate_metric_vector(case.basis[ig]))
        end
        columns[ig] = vcat(blocks...)
    end
    return reduce(hcat, columns), vcat(targets...)
end

function optimize_sparse_hardgate_weights(design, target, indices;
                                          initial_weights = nothing,
                                          max_iterations = 700,
                                          p = 32)
    subdesign = design[:, indices]
    n = length(indices)
    weights = initial_weights === nothing ? fill(inv(n), n) :
        simplex_projection(collect(initial_weights))
    column_norm2 = [sum(abs2, view(subdesign, :, j)) for j in 1:n]
    lipschitz = n * maximum(column_norm2)
    step0 = lipschitz > 0 ? inv(lipschitz) : 1.0
    best_weights = copy(weights)
    best_objective = Inf
    for iter in 1:max_iterations
        residual = subdesign * weights - target
        abs_residual = abs.(residual) .+ eps(Float64)
        objective = sum(abs_residual .^ p)^(1 / p)
        if objective < best_objective
            best_objective = objective
            best_weights .= weights
        end
        scale = objective > 0 ? objective^(p - 1) : one(objective)
        gradient_residual = sign.(residual) .* (abs_residual .^ (p - 1)) ./ scale
        gradient = subdesign' * gradient_residual
        weights = simplex_projection(weights - (step0 / sqrt(iter)) * gradient)
    end
    return best_weights, best_objective
end

function exact_subset_result(full_model, indices, selected_weights)
    exact = subset_exact_metrics(full_model, indices, selected_weights)
    objective = exact_result_objective(exact)
    worst_case = argmax(exact.cases) do case
        exact_case_objective(case)
    end
    return (
        exact = exact,
        objective = objective,
        worst_case = worst_case.case,
        worst_toa_forcing_error_w_m2 = maximum(case.toa_forcing_max_abs for case in exact.cases),
        worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in exact.cases),
    )
end

function hardgate_initial_subsets(weights, nselected)
    starts = Vector{Vector{Int}}()
    push!(starts, WEIGHTED_GREEDY_SW_16_INDICES)
    push!(starts, GREEDY_SW_16_INDICES)
    append!(starts, initial_subsets(weights, nselected))
    return unique(sort.(collect.(starts)))
end

function initial_sparse_subset_weights(full_model, selected)
    if collect(selected) == WEIGHTED_GREEDY_SW_16_INDICES
        return collect(WEIGHTED_GREEDY_SW_16_WEIGHTS)
    end
    return normalized_subset(full_model.shortwave_weights, selected)
end

function hardgate_sparse_swap_search(context, full_model, design, target, initial_indices;
                                     max_passes = 3,
                                     candidate_limit = 48,
                                     max_weight_iterations = 450,
                                     final_weight_iterations = 1_200,
                                     p = 16,
                                     progress = false)
    selected = sort(collect(initial_indices))
    initial_selected_weights = initial_sparse_subset_weights(full_model, selected)
    initial_exact = exact_subset_result(full_model, selected, initial_selected_weights)
    selected_weights, approximate_objective =
        optimize_sparse_hardgate_weights(design, target, selected;
                                         initial_weights = initial_selected_weights,
                                         max_iterations = final_weight_iterations,
                                         p)
    exact = exact_subset_result(full_model, selected, selected_weights)
    if initial_exact.objective < exact.objective
        selected_weights = collect(initial_selected_weights)
        exact = initial_exact
        approximate_objective = norm(design[:, selected] * selected_weights - target, Inf)
    end
    history = [(
        pass = 0,
        approximate_objective = approximate_objective,
        exact_objective = exact.objective,
        indices = collect(selected),
    )]
    all_indices = collect(1:length(full_model.shortwave_weights))

    for pass in 1:max_passes
        progress && println("hardgate sparse pass $pass start objective $(exact.objective)")
        trial_rows = NamedTuple[]
        for remove_index in selected
            for add_index in setdiff(all_indices, selected)
                candidate = sort([idx for idx in selected if idx != remove_index])
                push!(candidate, add_index)
                sort!(candidate)
                length(unique(candidate)) == length(selected) || continue
                local_weights = fill(inv(length(candidate)), length(candidate))
                shared = intersect(selected, candidate)
                for old in shared
                    old_pos = findfirst(==(old), selected)
                    new_pos = findfirst(==(old), candidate)
                    local_weights[new_pos] = selected_weights[old_pos]
                end
                local_weights = simplex_projection(local_weights)
                weights, objective =
                    optimize_sparse_hardgate_weights(design, target, candidate;
                                                     initial_weights = local_weights,
                                                     max_iterations = max_weight_iterations,
                                                     p)
                push!(trial_rows, (
                    remove = remove_index,
                    add = add_index,
                    indices = candidate,
                    weights = collect(weights),
                    approximate_objective = objective,
                ))
            end
        end
        sort!(trial_rows; by = row -> row.approximate_objective)
        trial_rows = trial_rows[1:min(candidate_limit, length(trial_rows))]
        progress && println("hardgate sparse pass $pass exact-checking $(length(trial_rows)) ranked candidates")

        best_trial = nothing
        best_exact = exact
        for (trial_index, trial) in enumerate(trial_rows)
            refined_weights, refined_approximate =
                optimize_sparse_hardgate_weights(design, target, trial.indices;
                                                 initial_weights = trial.weights,
                                                 max_iterations = final_weight_iterations,
                                                 p)
            refined_exact = exact_subset_result(full_model, trial.indices, refined_weights)
            initial_trial_exact =
                exact_subset_result(full_model, trial.indices, trial.weights)
            if initial_trial_exact.objective < refined_exact.objective
                refined_weights = trial.weights
                refined_exact = initial_trial_exact
                refined_approximate = trial.approximate_objective
            end
            row = (
                trial...,
                weights = collect(refined_weights),
                approximate_objective = refined_approximate,
                exact_objective = refined_exact.objective,
            )
            if refined_exact.objective < best_exact.objective
                best_trial = row
                best_exact = refined_exact
                progress &&
                    println("hardgate sparse pass $pass candidate $trial_index improved exact objective to $(best_exact.objective)")
            end
        end

        best_trial === nothing && break
        selected = collect(best_trial.indices)
        selected_weights = collect(best_trial.weights)
        approximate_objective = best_trial.approximate_objective
        exact = best_exact
        push!(history, (
            pass = pass,
            approximate_objective = approximate_objective,
            exact_objective = exact.objective,
            indices = collect(selected),
        ))
    end

    return (
        indices = collect(selected),
        selected_weights = collect(selected_weights),
        approximate_objective = approximate_objective,
        exact_objective = exact.objective,
        passed_hard_thresholds = exact.exact.passed_hard_thresholds,
        worst_case = exact.worst_case,
        worst_toa_forcing_error_w_m2 = exact.worst_toa_forcing_error_w_m2,
        worst_surface_forcing_error_w_m2 = exact.worst_surface_forcing_error_w_m2,
        history = history,
        exact = exact.exact,
    )
end

function hardgate_sparse_subset_main()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    context = search_context(full_model)
    design, target = hardgate_full_design(context)
    nselected = parse(Int, get(ENV, "RH_HARDGATE_SUBSET_NSELECTED", "16"))
    max_starts = parse(Int, get(ENV, "RH_HARDGATE_SUBSET_MAX_STARTS", "4"))
    max_passes = parse(Int, get(ENV, "RH_HARDGATE_SUBSET_MAX_PASSES", "3"))
    candidate_limit = parse(Int, get(ENV, "RH_HARDGATE_SUBSET_CANDIDATE_LIMIT", "48"))
    max_weight_iterations =
        parse(Int, get(ENV, "RH_HARDGATE_SUBSET_WEIGHT_ITERATIONS", "450"))
    final_weight_iterations =
        parse(Int, get(ENV, "RH_HARDGATE_SUBSET_FINAL_WEIGHT_ITERATIONS", "1200"))
    p = parse(Int, get(ENV, "RH_HARDGATE_SUBSET_P", "16"))
    progress = get(ENV, "RH_HARDGATE_SUBSET_PROGRESS", "false") == "true"
    starts = hardgate_initial_subsets(full_model.shortwave_weights, nselected)
    starts = starts[1:min(max_starts, length(starts))]
    searches = [
        hardgate_sparse_swap_search(
            context,
            full_model,
            design,
            target,
            start;
            max_passes,
            candidate_limit,
            max_weight_iterations,
            final_weight_iterations,
            p,
            progress,
        )
        for start in starts
    ]
    best = argmin(search -> search.exact_objective, searches)
    status = best.passed_hard_thresholds ? "passed" : "failed_threshold"
    result = (
        case = "reduced_ecckd_hardgate_subset_search",
        timestamp_utc = string(Dates.now()),
        status = status,
        method =
            "overlapping sparse nonnegative 16-term shortwave flux-basis hard-gate subset search",
        nselected = nselected,
        starts_evaluated = length(starts),
        best = best,
        all_searches = searches,
    )
    mkpath(dirname(HARDGATE_SUBSET_JSON))
    write(HARDGATE_SUBSET_JSON, json_object(result))
    write(HARDGATE_SUBSET_MD, markdown_hardgate_sparse_subset_report(result))
    print(markdown_hardgate_sparse_subset_report(result))
    println("Wrote $HARDGATE_SUBSET_JSON")
    println("Wrote $HARDGATE_SUBSET_MD")
end

function markdown_hardgate_sparse_subset_report(result)
    best = result.best
    lines = String[
        "# Reduced ecCKD Hard-Gate Sparse Subset Search",
        "",
        "Status: **$(result.status)**",
        "",
        "Method: `$(result.method)`",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Selected shortwave g-points | `$(join(best.indices, ", "))` |",
        "| Exact objective | `$(@sprintf("%.12g", best.exact_objective))` |",
        "| Approximate objective | `$(@sprintf("%.12g", best.approximate_objective))` |",
        "| Worst case | `$(best.worst_case)` |",
        "| Worst TOA forcing error | `$(@sprintf("%.12g", best.worst_toa_forcing_error_w_m2))` W m^-2 |",
        "| Worst surface forcing error | `$(@sprintf("%.12g", best.worst_surface_forcing_error_w_m2))` W m^-2 |",
        "| Passed hard thresholds | `$(best.passed_hard_thresholds)` |",
        "",
        "This is a flux-basis feasibility diagnostic. It uses nonnegative sparse weights over official shortwave g-point responses, then exact-checks the selected support through the normal tabulated model path. It does not replace the physical reduced coefficient-table artifact unless it passes and is promoted into `reduced_ecckd_accuracy.jl`.",
        "",
        "## Search History",
        "",
        "| Pass | Approximate objective | Exact objective | Indices |",
        "|---:|---:|---:|---|",
    ]
    for row in best.history
        push!(lines,
              "| $(row.pass) | $(@sprintf("%.12g", row.approximate_objective)) | $(@sprintf("%.12g", row.exact_objective)) | `$(join(row.indices, ", "))` |")
    end
    return join(lines, "\n") * "\n"
end

if abspath(PROGRAM_FILE) == @__FILE__
    hardgate_sparse_subset_main()
end
