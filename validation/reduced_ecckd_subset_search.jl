include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_accuracy.jl"))

const SEARCH_BREEZE_DIR = joinpath(ABR_ROOT, "..", "BreezeRadiativeHeatingDev",
                                   "Breeze.jl", "benchmarking", "results",
                                   "reduced_accuracy")

function sw_reference_arrays(case)
    nc = require_ncdatasets()
    nc.NCDataset(reference_path(case.path)) do dataset
        sw_up = Array(dataset["sw_up"])
        sw_down = Array(dataset["sw_down"])
        pressure_interfaces = Array(dataset["pressure_interface"])
        return (
            sw_up = sw_up,
            sw_down = sw_down,
            pressure_interfaces = pressure_interfaces,
            sw_heating_rate = shortwave_heating_rate(sw_up, sw_down, pressure_interfaces),
        )
    end
end

function shortwave_heating_rate(sw_up, sw_down, pressure_interfaces)
    nlayers = size(sw_up, 1) - 1
    ncolumns = size(sw_up, 2)
    heating = zeros(Float64, nlayers, ncolumns)
    factor = 86400.0 * GRAVITY / 1004.0
    for j in 1:ncolumns, k in 1:nlayers
        Δp = pressure_interfaces[k + 1, j] - pressure_interfaces[k, j]
        net_top = sw_down[k, j] - sw_up[k, j]
        net_bottom = sw_down[k + 1, j] - sw_up[k + 1, j]
        heating[k, j] = factor * (net_top - net_bottom) / Δp
    end
    return heating
end

function sw_basis_arrays(case, model)
    ng = size(model.shortwave_absorption, 1)
    reference = sw_reference_arrays(case)
    basis = Vector{NamedTuple}(undef, ng)
    for ig in 1:ng
        weights = zeros(Float64, ng)
        weights[ig] = 1
        arrays = candidate_arrays(case.path, with_shortwave_weights(model, weights))
        basis[ig] = (
            sw_up = arrays.sw_up,
            sw_down = arrays.sw_down,
            sw_heating_rate = shortwave_heating_rate(arrays.sw_up, arrays.sw_down,
                                                     reference.pressure_interfaces),
        )
    end
    return reference, basis
end

function search_context(model)
    cases = NamedTuple[]
    for case in REDUCED_CASES
        reference, basis = sw_basis_arrays(case, model)
        push!(cases, (
            case = case.case,
            reference = reference,
            basis = basis,
        ))
    end
    return cases
end

function combine_sw(basis, indices, weights)
    sw_up = zeros(Float64, size(basis[1].sw_up))
    sw_down = zeros(Float64, size(basis[1].sw_down))
    sw_heating_rate = zeros(Float64, size(basis[1].sw_heating_rate))
    selected_weights = normalized_subset(weights, indices)
    for (local_index, ig) in enumerate(indices)
        sw_up .+= selected_weights[local_index] .* basis[ig].sw_up
        sw_down .+= selected_weights[local_index] .* basis[ig].sw_down
        sw_heating_rate .+= selected_weights[local_index] .* basis[ig].sw_heating_rate
    end
    return sw_up, sw_down, sw_heating_rate
end

function combine_sw_with_selected_weights(basis, indices, selected_weights)
    sw_up = zeros(Float64, size(basis[1].sw_up))
    sw_down = zeros(Float64, size(basis[1].sw_down))
    sw_heating_rate = zeros(Float64, size(basis[1].sw_heating_rate))
    for (local_index, ig) in enumerate(indices)
        sw_up .+= selected_weights[local_index] .* basis[ig].sw_up
        sw_down .+= selected_weights[local_index] .* basis[ig].sw_down
        sw_heating_rate .+= selected_weights[local_index] .* basis[ig].sw_heating_rate
    end
    return sw_up, sw_down, sw_heating_rate
end

function rmse_array(candidate, reference)
    difference = candidate .- reference
    return sqrt(sum(abs2, difference) / length(difference))
end

function subset_score(context, indices, weights)
    worst = 0.0
    for case in context
        sw_up, sw_down, sw_heating_rate = combine_sw(case.basis, indices, weights)
        reference = case.reference
        toa_error = maximum(abs, (sw_down[1, :] .- sw_up[1, :]) .-
                                 (reference.sw_down[1, :] .- reference.sw_up[1, :]))
        surface_error = maximum(abs, (sw_down[end, :] .- sw_up[end, :]) .-
                                     (reference.sw_down[end, :] .- reference.sw_up[end, :]))
        worst = max(worst,
                    rmse_array(sw_up, reference.sw_up) / ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
                    rmse_array(sw_down, reference.sw_down) / ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
                    maximum(abs, sw_up .- reference.sw_up) / ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
                    maximum(abs, sw_down .- reference.sw_down) / ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
                    rmse_array(sw_heating_rate, reference.sw_heating_rate) / ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day,
                    maximum(abs, sw_heating_rate .- reference.sw_heating_rate) / ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
                    toa_error / ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
                    surface_error / ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2)
    end
    return worst
end

function subset_score_with_selected_weights(context, indices, selected_weights)
    worst = 0.0
    for case in context
        sw_up, sw_down, sw_heating_rate =
            combine_sw_with_selected_weights(case.basis, indices, selected_weights)
        reference = case.reference
        toa_error = maximum(abs, (sw_down[1, :] .- sw_up[1, :]) .-
                                 (reference.sw_down[1, :] .- reference.sw_up[1, :]))
        surface_error = maximum(abs, (sw_down[end, :] .- sw_up[end, :]) .-
                                     (reference.sw_down[end, :] .- reference.sw_up[end, :]))
        worst = max(worst,
                    rmse_array(sw_up, reference.sw_up) / ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
                    rmse_array(sw_down, reference.sw_down) / ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
                    maximum(abs, sw_up .- reference.sw_up) / ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
                    maximum(abs, sw_down .- reference.sw_down) / ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
                    rmse_array(sw_heating_rate, reference.sw_heating_rate) / ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day,
                    maximum(abs, sw_heating_rate .- reference.sw_heating_rate) / ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
                    toa_error / ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
                    surface_error / ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2)
    end
    return worst
end

function subset_metric_vector(arrays; boundary_weight, heating_weight)
    toa = arrays.sw_down[1, :] .- arrays.sw_up[1, :]
    surface = arrays.sw_down[end, :] .- arrays.sw_up[end, :]
    return vcat(vec(arrays.sw_up), vec(arrays.sw_down),
                boundary_weight .* vec(toa),
                boundary_weight .* vec(surface),
                heating_weight .* vec(arrays.sw_heating_rate))
end

function subset_hard_gate_metric_vector(arrays)
    toa = arrays.sw_down[1, :] .- arrays.sw_up[1, :]
    surface = arrays.sw_down[end, :] .- arrays.sw_up[end, :]
    sw_up_rmse_scale = ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2 * sqrt(length(arrays.sw_up))
    sw_down_rmse_scale = ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2 * sqrt(length(arrays.sw_down))
    heating_rmse_scale = ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day *
                         sqrt(length(arrays.sw_heating_rate))
    return vcat(
        vec(arrays.sw_up) ./ ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        vec(arrays.sw_down) ./ ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        vec(arrays.sw_up) ./ sw_up_rmse_scale,
        vec(arrays.sw_down) ./ sw_down_rmse_scale,
        vec(toa) ./ ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
        vec(surface) ./ ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
        vec(arrays.sw_heating_rate) ./ ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
        vec(arrays.sw_heating_rate) ./ heating_rmse_scale,
    )
end

function subset_weight_design(context, indices; boundary_weight,
                              heating_weight = inv(ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day))
    columns = Vector{Vector{Float64}}(undef, length(indices))
    targets = Vector{Float64}[]
    for case in context
        reference = case.reference
        push!(targets, subset_metric_vector(reference;
            boundary_weight = boundary_weight,
            heating_weight = heating_weight))
    end
    for (local_index, ig) in enumerate(indices)
        blocks = Vector{Float64}[]
        for case in context
            basis = case.basis[ig]
            push!(blocks, subset_metric_vector(basis;
                boundary_weight = boundary_weight,
                heating_weight = heating_weight))
        end
        columns[local_index] = vcat(blocks...)
    end
    return reduce(hcat, columns), vcat(targets...)
end

function optimized_subset_weights(context, indices; boundary_weight = 10.0,
                                  max_iterations = 800)
    design, target = subset_weight_design(context, indices;
                                          boundary_weight = boundary_weight)
    n = length(indices)
    weights = fill(inv(n), n)
    lipschitz = opnorm(design)^2
    step = lipschitz > 0 ? inv(lipschitz) : 1.0
    for _ in 1:max_iterations
        weights = simplex_projection(weights - step * (design' * (design * weights - target)))
    end
    return weights
end

function subset_hard_gate_weight_design(context, indices)
    columns = Vector{Vector{Float64}}(undef, length(indices))
    targets = Vector{Float64}[]
    for case in context
        push!(targets, subset_hard_gate_metric_vector(case.reference))
    end
    for (local_index, ig) in enumerate(indices)
        blocks = Vector{Float64}[]
        for case in context
            push!(blocks, subset_hard_gate_metric_vector(case.basis[ig]))
        end
        columns[local_index] = vcat(blocks...)
    end
    return reduce(hcat, columns), vcat(targets...)
end

function optimized_subset_weights_hardgate(context, indices;
                                           initial_weights = nothing,
                                           max_iterations = 500,
                                           p = 16)
    design, target = subset_hard_gate_weight_design(context, indices)
    n = length(indices)
    weights = initial_weights === nothing ? fill(inv(n), n) :
        simplex_projection(collect(initial_weights))
    lipschitz = opnorm(design)^2
    step0 = lipschitz > 0 ? inv(lipschitz) : 1.0
    best_weights = copy(weights)
    best_objective = Inf
    for iter in 1:max_iterations
        residual = design * weights - target
        abs_residual = abs.(residual) .+ eps(Float64)
        objective = sum(abs_residual .^ p)^(1 / p)
        if objective < best_objective
            best_objective = objective
            best_weights .= weights
        end
        scale = objective > 0 ? objective^(p - 1) : one(objective)
        gradient_residual = sign.(residual) .* (abs_residual .^ (p - 1)) ./ scale
        gradient = design' * gradient_residual
        weights = simplex_projection(weights - (step0 / sqrt(iter)) * gradient)
    end
    return best_weights, best_objective
end

function hardgate_weight_candidate(context, indices, initial_weights, label)
    selected_weights, approximate_objective =
        optimized_subset_weights_hardgate(context, indices;
                                          initial_weights = initial_weights)
    return (
        label = label,
        indices = collect(indices),
        selected_weights = collect(selected_weights),
        approximate_hardgate_objective = approximate_objective,
    )
end

function greedy_swap_search(context, weights, initial_indices; max_passes = 6)
    selected = sort(collect(initial_indices))
    best_score = subset_score(context, selected, weights)
    history = [(pass = 0, score = best_score, indices = collect(selected))]
    all_indices = collect(eachindex(weights))

    for pass in 1:max_passes
        best_candidate = selected
        improved = false
        for remove_index in selected
            for add_index in setdiff(all_indices, selected)
                candidate = sort([idx for idx in selected if idx != remove_index])
                push!(candidate, add_index)
                sort!(candidate)
                length(unique(candidate)) == length(selected) || continue
                score = subset_score(context, candidate, weights)
                if score < best_score
                    best_score = score
                    best_candidate = candidate
                    improved = true
                end
            end
        end
        selected = best_candidate
        push!(history, (pass = pass, score = best_score, indices = collect(selected)))
        improved || break
    end
    return (
        indices = selected,
        approximate_score = best_score,
        history = history,
    )
end

function greedy_weighted_swap_search(context, initial_indices; max_passes = 4,
                                     boundary_weight = 10.0)
    selected = sort(collect(initial_indices))
    selected_weights = optimized_subset_weights(context, selected;
                                                boundary_weight = boundary_weight)
    best_score = subset_score_with_selected_weights(context, selected, selected_weights)
    history = [(pass = 0, score = best_score, indices = collect(selected),
                selected_weights = collect(selected_weights))]
    all_indices = collect(1:length(context[1].basis))

    for pass in 1:max_passes
        best_candidate = selected
        best_weights = selected_weights
        improved = false
        for remove_index in selected
            for add_index in setdiff(all_indices, selected)
                candidate = sort([idx for idx in selected if idx != remove_index])
                push!(candidate, add_index)
                sort!(candidate)
                length(unique(candidate)) == length(selected) || continue
                candidate_weights = optimized_subset_weights(context, candidate;
                                                             boundary_weight = boundary_weight)
                score = subset_score_with_selected_weights(context, candidate,
                                                           candidate_weights)
                if score < best_score
                    best_score = score
                    best_candidate = candidate
                    best_weights = candidate_weights
                    improved = true
                end
            end
        end
        selected = best_candidate
        selected_weights = best_weights
        push!(history, (pass = pass, score = best_score, indices = collect(selected),
                        selected_weights = collect(selected_weights)))
        improved || break
    end
    return (
        indices = selected,
        selected_weights = selected_weights,
        approximate_score = best_score,
        boundary_weight = boundary_weight,
        history = history,
    )
end

function multi_boundary_weighted_swap_search(context, initial_indices;
                                             boundary_weights = (1.0, 3.0, 10.0, 30.0),
                                             max_passes = 2)
    searches = [
        greedy_weighted_swap_search(context, initial_indices;
                                    boundary_weight,
                                    max_passes)
        for boundary_weight in boundary_weights
    ]
    _, best_index = findmin(search -> search.approximate_score, searches)
    return (
        selected_search = searches[best_index],
        all_searches = searches,
    )
end

function prune_full_weight_fit(context; nselected = 16,
                               boundary_weights = (1.0, 3.0, 10.0, 30.0))
    all_indices = collect(1:length(context[1].basis))
    trials = NamedTuple[]
    for boundary_weight in boundary_weights
        full_weights = optimized_subset_weights(context, all_indices;
                                                boundary_weight = boundary_weight)
        selected = sort(sortperm(full_weights, rev = true)[1:nselected])
        selected_weights = optimized_subset_weights(context, selected;
                                                    boundary_weight = boundary_weight)
        score = subset_score_with_selected_weights(context, selected, selected_weights)
        push!(trials, (
            boundary_weight = boundary_weight,
            indices = selected,
            selected_weights = collect(selected_weights),
            full_weight_support = collect(full_weights),
            approximate_score = score,
        ))
    end
    _, best_index = findmin(trial -> trial.approximate_score, trials)
    return (
        selected_search = trials[best_index],
        all_trials = trials,
    )
end

function initial_subsets(weights, nselected)
    n = length(weights)
    starts = Vector{Vector{Int}}()
    push!(starts, selected_gpoints(n, nselected))
    push!(starts, sort(sortperm(collect(weights), rev = true)[1:nselected]))
    push!(starts, collect(1:nselected))
    push!(starts, collect((n - nselected + 1):n))
    push!(starts, collect(1:2:n))
    push!(starts, collect(2:2:n))
    unique_starts = Vector{Vector{Int}}()
    for start in starts
        candidate = sort(collect(start))
        length(candidate) == nselected || continue
        candidate in unique_starts || push!(unique_starts, candidate)
    end
    return unique_starts
end

function multi_start_search(context, weights, nselected)
    searches = [greedy_swap_search(context, weights, initial)
                for initial in initial_subsets(weights, nselected)]
    _, best_index = findmin(search -> search.approximate_score, searches)
    return (
        selected_search = searches[best_index],
        all_searches = searches,
    )
end

function subset_exact_metrics(full_model, indices)
    model = indexed_tabulated_model(full_model, collect(1:size(full_model.longwave_absorption, 1)), indices)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return (
        ng_lw = size(full_model.longwave_absorption, 1),
        ng_sw = length(indices),
        selected_shortwave_gpoints = collect(indices),
        reduction_method = "greedy shortwave g-point subset search with official weights renormalized",
        passed_hard_thresholds = all(case -> case.passed_hard_thresholds, cases),
        cases = cases,
    )
end

function subset_exact_metrics(full_model, indices, selected_weights)
    model = indexed_tabulated_model(full_model, collect(1:size(full_model.longwave_absorption, 1)), indices)
    model.shortwave_weights .= selected_weights
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return (
        ng_lw = size(full_model.longwave_absorption, 1),
        ng_sw = length(indices),
        selected_shortwave_gpoints = collect(indices),
        selected_shortwave_weights = collect(selected_weights),
        reduction_method = "weighted greedy shortwave g-point subset search with projected simplex weights",
        passed_hard_thresholds = all(case -> case.passed_hard_thresholds, cases),
        cases = cases,
    )
end

function exact_case_objective(case)
    return max(
        case.variables.sw_up.rmse / ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
        case.variables.sw_down.rmse / ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
        case.variables.sw_up.max_abs / ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        case.variables.sw_down.max_abs / ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        case.variables.heating_rate.rmse / ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day,
        case.variables.heating_rate.max_abs / ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
        case.toa_forcing_max_abs / ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
        case.surface_forcing_max_abs / ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
    )
end

exact_result_objective(result) = maximum(exact_case_objective, result.cases)

function exact_search_candidate(full_model, search)
    return (
        search = search,
        exact = subset_exact_metrics(full_model, search.indices, search.selected_weights),
    )
end

function select_best_exact_candidate(candidates)
    _, best_index = findmin(candidate -> exact_result_objective(candidate.exact), candidates)
    return candidates[best_index]
end

function markdown_subset_report(result)
    lines = String[
        "# Reduced ecCKD Shortwave Subset Search",
        "",
        "Status: **$(result.status)**",
        "",
        "Search objective: `$(result.search_objective)`",
        "",
        "Selected shortwave g-points: `$(join(result.best_subset.selected_shortwave_gpoints, ", "))`",
        "",
        "| Case | Passed | TOA forcing error | Surface forcing error | SW up RMSE | SW down RMSE | Heating RMSE | Heating max |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for case in result.best_subset.cases
        push!(lines, "| $(case.case) | $(case.passed_hard_thresholds) | $(@sprintf("%.12g", case.toa_forcing_max_abs)) W m^-2 | $(@sprintf("%.12g", case.surface_forcing_max_abs)) W m^-2 | $(@sprintf("%.12g", case.variables.sw_up.rmse)) W m^-2 | $(@sprintf("%.12g", case.variables.sw_down.rmse)) W m^-2 | $(@sprintf("%.12g", case.variables.heating_rate.rmse)) K day^-1 | $(@sprintf("%.12g", case.variables.heating_rate.max_abs)) K day^-1 |")
    end
    append!(lines, [
        "",
        "## Weighted Subset Search",
        "",
        "Selected shortwave g-points: `$(join(result.best_weighted_subset.selected_shortwave_gpoints, ", "))`",
        "",
        "Boundary weight: `$(@sprintf("%.12g", result.weighted_search.boundary_weight))`",
        "",
        "| Case | Passed | TOA forcing error | Surface forcing error | SW up RMSE | SW down RMSE | Heating RMSE | Heating max |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ])
    for case in result.best_weighted_subset.cases
        push!(lines, "| $(case.case) | $(case.passed_hard_thresholds) | $(@sprintf("%.12g", case.toa_forcing_max_abs)) W m^-2 | $(@sprintf("%.12g", case.surface_forcing_max_abs)) W m^-2 | $(@sprintf("%.12g", case.variables.sw_up.rmse)) W m^-2 | $(@sprintf("%.12g", case.variables.sw_down.rmse)) W m^-2 | $(@sprintf("%.12g", case.variables.heating_rate.rmse)) K day^-1 | $(@sprintf("%.12g", case.variables.heating_rate.max_abs)) K day^-1 |")
    end
    append!(lines, [
        "",
        "A failed status means this deterministic subset search improved the current 16-g shortwave reduction but still does not satisfy the hard clean ecCKD thresholds. The current failure is useful evidence that simple subset selection is not enough; a real ecCKD reduction/optimization method is still required.",
        "",
        "## Search History",
        "",
        "| Pass | Approximate normalized score | Indices |",
        "|---:|---:|---|",
    ])
    for row in result.search.history
        push!(lines, "| $(row.pass) | $(@sprintf("%.12g", row.score)) | `$(join(row.indices, ", "))` |")
    end
    append!(lines, [
        "",
        "## Boundary-Weight Trials",
        "",
        "| Boundary weight | Approximate normalized score | Indices |",
        "|---:|---:|---|",
    ])
    for search in result.boundary_weighted_searches
        push!(lines, "| $(@sprintf("%.12g", search.boundary_weight)) | $(@sprintf("%.12g", search.approximate_score)) | `$(join(search.indices, ", "))` |")
    end
    append!(lines, [
        "",
        "## Full-Fit Pruning Trial",
        "",
        "Selected shortwave g-points: `$(join(result.best_pruned_full_fit_subset.selected_shortwave_gpoints, ", "))`",
        "",
        "Boundary weight: `$(@sprintf("%.12g", result.pruned_full_fit_search.boundary_weight))`",
        "",
        "| Case | Passed | TOA forcing error | Surface forcing error | SW up RMSE | SW down RMSE | Heating RMSE | Heating max |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ])
    for case in result.best_pruned_full_fit_subset.cases
        push!(lines, "| $(case.case) | $(case.passed_hard_thresholds) | $(@sprintf("%.12g", case.toa_forcing_max_abs)) W m^-2 | $(@sprintf("%.12g", case.surface_forcing_max_abs)) W m^-2 | $(@sprintf("%.12g", case.variables.sw_up.rmse)) W m^-2 | $(@sprintf("%.12g", case.variables.sw_down.rmse)) W m^-2 | $(@sprintf("%.12g", case.variables.heating_rate.rmse)) K day^-1 | $(@sprintf("%.12g", case.variables.heating_rate.max_abs)) K day^-1 |")
    end
    append!(lines, [
        "",
        "## Hard-Gate Max-Norm Weight Trial",
        "",
        "Selected shortwave g-points: `$(join(result.best_hardgate_weighted_subset.selected_shortwave_gpoints, ", "))`",
        "",
        "Source topology: `$(result.hardgate_weighted_search.label)`",
        "",
        "Approximate normalized hard-gate objective: `$(@sprintf("%.12g", result.hardgate_weighted_search.approximate_hardgate_objective))`",
        "",
        "| Case | Passed | TOA forcing error | Surface forcing error | SW up RMSE | SW down RMSE | Heating RMSE | Heating max |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ])
    for case in result.best_hardgate_weighted_subset.cases
        push!(lines, "| $(case.case) | $(case.passed_hard_thresholds) | $(@sprintf("%.12g", case.toa_forcing_max_abs)) W m^-2 | $(@sprintf("%.12g", case.surface_forcing_max_abs)) W m^-2 | $(@sprintf("%.12g", case.variables.sw_up.rmse)) W m^-2 | $(@sprintf("%.12g", case.variables.sw_down.rmse)) W m^-2 | $(@sprintf("%.12g", case.variables.heating_rate.rmse)) K day^-1 | $(@sprintf("%.12g", case.variables.heating_rate.max_abs)) K day^-1 |")
    end
    return join(lines, "\n") * "\n"
end

function subset_search_main()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    context = search_context(full_model)
    search_result = multi_start_search(context, full_model.shortwave_weights, 16)
    search = search_result.selected_search
    weighted_search_result = multi_boundary_weighted_swap_search(context, search.indices)
    pruned_full_fit = prune_full_weight_fit(context)
    exact = subset_exact_metrics(full_model, search.indices)
    weighted_candidates = [
        exact_search_candidate(full_model, candidate)
        for candidate in weighted_search_result.all_searches
    ]
    pruned_candidates = [
        exact_search_candidate(full_model, candidate)
        for candidate in pruned_full_fit.all_trials
    ]
    weighted_candidate = select_best_exact_candidate(weighted_candidates)
    pruned_candidate = select_best_exact_candidate(pruned_candidates)
    weighted_search = weighted_candidate.search
    weighted_exact = weighted_candidate.exact
    pruned_exact = pruned_candidate.exact
    hardgate_searches = [
        hardgate_weight_candidate(context, search.indices,
                                  normalized_subset(full_model.shortwave_weights, search.indices),
                                  "official-weight greedy subset"),
        hardgate_weight_candidate(context, weighted_search.indices,
                                  weighted_search.selected_weights,
                                  "boundary-weighted greedy subset"),
        hardgate_weight_candidate(context, pruned_candidate.search.indices,
                                  pruned_candidate.search.selected_weights,
                                  "full-fit-pruned subset"),
    ]
    hardgate_candidates = [
        exact_search_candidate(full_model, candidate)
        for candidate in hardgate_searches
    ]
    hardgate_candidate = select_best_exact_candidate(hardgate_candidates)
    hardgate_search = hardgate_candidate.search
    hardgate_exact = hardgate_candidate.exact
    status = any(result -> result.passed_hard_thresholds,
                 (exact, weighted_exact, pruned_exact, hardgate_exact)) ? "passed" : "failed_threshold"
    result = (
        case = "radiative_heating_reduced_subset_search",
        timestamp_utc = string(Dates.now()),
        status = status,
        search_objective = "flux_boundary_and_shortwave_heating_rate",
        reference_scope = collect(REDUCED_CASE_NAMES),
        search = search,
        weighted_search = weighted_search,
        boundary_weighted_searches = weighted_search_result.all_searches,
        pruned_full_fit_search = pruned_candidate.search,
        pruned_full_fit_trials = pruned_full_fit.all_trials,
        hardgate_weighted_search = hardgate_search,
        hardgate_weighted_searches = hardgate_searches,
        all_searches = search_result.all_searches,
        best_subset = exact,
        best_weighted_subset = weighted_exact,
        best_pruned_full_fit_subset = pruned_exact,
        best_hardgate_weighted_subset = hardgate_exact,
    )
    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "reduced_ecckd_subset_search.json")
    md_path = joinpath(results_dir, "reduced_ecckd_subset_search.md")
    write(json_path, json_object(result))
    write(md_path, markdown_subset_report(result))

    mkpath(SEARCH_BREEZE_DIR)
    breeze_json = joinpath(SEARCH_BREEZE_DIR, "radiative_heating_reduced_subset_search_latest.json")
    breeze_md = joinpath(SEARCH_BREEZE_DIR, "radiative_heating_reduced_subset_search_latest.md")
    write(breeze_json, json_object(result))
    write(breeze_md, markdown_subset_report(result))

    print(markdown_subset_report(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
    println("Wrote $breeze_json")
    println("Wrote $breeze_md")
end

if abspath(PROGRAM_FILE) == @__FILE__
    subset_search_main()
end
