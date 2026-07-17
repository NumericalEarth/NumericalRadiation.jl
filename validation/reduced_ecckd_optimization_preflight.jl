include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_accuracy.jl"))

const PREFLIGHT_JSON = validation_results_path("reduced_ecckd_optimization_preflight.json")
const PREFLIGHT_MD = validation_results_path("reduced_ecckd_optimization_preflight.md")
const REDUCED_ACCURACY_JSON = validation_results_path("reduced_ecckd_accuracy.json")
const REDUCED_SUBSET_SEARCH_JSON = validation_results_path("reduced_ecckd_subset_search.json")
const PREFLIGHT_DIRECTION = [
    sin(0.37i) + 0.5cos(0.19i) for i in 1:(3length(WEIGHTED_GREEDY_SW_16_INDICES))
]

softmax(values) = begin
    shifted = values .- maximum(values)
    exps = exp.(shifted)
    exps ./ sum(exps)
end

function optional_dependency_status(name)
    if get(ENV, "RH_SKIP_OPTIONAL_AD_CHECKS", "false") == "true"
        return "skipped_by_RH_SKIP_OPTIONAL_AD_CHECKS"
    end
    Base.find_package(name) === nothing ? "not_available_in_active_project" : "available"
end

function first_error_line(err)
    line = first(split(sprint(showerror, err), '\n'))
    return length(line) > 240 ? line[1:240] : line
end

function initial_parameters()
    weights = max.(WEIGHTED_GREEDY_SW_16_WEIGHTS, eps(Float64))
    logits = log.(weights)
    absorption_log_scales = zeros(Float64, length(weights))
    rayleigh_log_scales = zeros(Float64, length(weights))
    return vcat(logits, absorption_log_scales, rayleigh_log_scales)
end

function reduced_model_from_parameters(full_model, parameters;
                                       sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    ng = length(sw_indices)
    length(parameters) == 3ng ||
        throw(DimensionMismatch("reduced optimization parameter vector must have 3 * ng_sw entries"))

    model = indexed_tabulated_model(full_model,
                                    collect(1:size(full_model.longwave_absorption, 1)),
                                    sw_indices)
    model.shortwave_weights .= softmax(parameters[1:ng])
    absorption_scales = exp.(clamp.(parameters[(ng + 1):(2ng)], -5.0, 5.0))
    rayleigh_scales = exp.(clamp.(parameters[(2ng + 1):(3ng)], -5.0, 5.0))
    for ig in 1:ng
        model.shortwave_absorption[ig, :, :, :] .*= absorption_scales[ig]
        if length(model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[ig, :, :, :] .*= absorption_scales[ig]
        end
        model.shortwave_rayleigh_molar_scattering[ig] *= rayleigh_scales[ig]
    end
    return model
end

function separated_component_parameters(parameters)
    ng = length(WEIGHTED_GREEDY_SW_16_INDICES)
    length(parameters) == 3ng ||
        throw(DimensionMismatch("base reduced parameter vector must have 3 * ng_sw entries"))
    logits = parameters[1:ng]
    absorption_log_scales = parameters[(ng + 1):(2ng)]
    rayleigh_log_scales = parameters[(2ng + 1):(3ng)]
    return vcat(logits,
                absorption_log_scales,
                absorption_log_scales,
                rayleigh_log_scales)
end

function separated_component_model_from_parameters(full_model, parameters;
                                                   sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    ng = length(sw_indices)
    length(parameters) == 4ng ||
        throw(DimensionMismatch("separated-component reduced parameter vector must have 4 * ng_sw entries"))

    model = indexed_tabulated_model(full_model,
                                    collect(1:size(full_model.longwave_absorption, 1)),
                                    sw_indices)
    model.shortwave_weights .= softmax(parameters[1:ng])
    absorption_scales = exp.(clamp.(parameters[(ng + 1):(2ng)], -5.0, 5.0))
    h2o_scales = exp.(clamp.(parameters[(2ng + 1):(3ng)], -5.0, 5.0))
    rayleigh_scales = exp.(clamp.(parameters[(3ng + 1):(4ng)], -5.0, 5.0))
    for ig in 1:ng
        model.shortwave_absorption[ig, :, :, :] .*= absorption_scales[ig]
        if length(model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[ig, :, :, :] .*= h2o_scales[ig]
        end
        model.shortwave_rayleigh_molar_scattering[ig] *= rayleigh_scales[ig]
    end
    return model
end

function normalized_case_objective(case)
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

function reduced_objective(full_model, parameters;
                           sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    model = reduced_model_from_parameters(full_model, parameters; sw_indices)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return maximum(normalized_case_objective, cases)
end

function separated_component_objective(full_model, parameters;
                                       sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    model = separated_component_model_from_parameters(full_model, parameters; sw_indices)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return maximum(normalized_case_objective, cases)
end

function normalized_objective_rows(case)
    rows = NamedTuple[]
    for variable in (:sw_up, :sw_down, :heating_rate)
        metrics = getproperty(case.variables, variable)
        if variable == :heating_rate
            rmse_threshold = ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day
            max_threshold = ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day
        else
            rmse_threshold = ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2
            max_threshold = ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2
        end
        push!(rows, (
            case = case.case,
            metric = "$(variable)_rmse",
            value = metrics.rmse,
            threshold = rmse_threshold,
            normalized_value = metrics.rmse / rmse_threshold,
        ))
        push!(rows, (
            case = case.case,
            metric = "$(variable)_max_abs",
            value = metrics.max_abs,
            threshold = max_threshold,
            normalized_value = metrics.max_abs / max_threshold,
        ))
    end
    push!(rows, (
        case = case.case,
        metric = "toa_forcing_max_abs",
        value = case.toa_forcing_max_abs,
        threshold = ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
        normalized_value =
            case.toa_forcing_max_abs / ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
    ))
    push!(rows, (
        case = case.case,
        metric = "surface_forcing_max_abs",
        value = case.surface_forcing_max_abs,
        threshold = ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
        normalized_value =
            case.surface_forcing_max_abs /
            ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
    ))
    return rows
end

function final_objective_breakdown(full_model, parameters;
                                   sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    model = reduced_model_from_parameters(full_model, parameters; sw_indices)
    return final_objective_breakdown_from_model(
        model;
        sw_indices,
        method = "final reduced hard-gate normalized metric breakdown",
    )
end

function final_objective_breakdown_from_model(model;
                                              sw_indices = WEIGHTED_GREEDY_SW_16_INDICES,
                                              method =
                                                "final reduced hard-gate normalized metric breakdown")
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    rows = vcat([normalized_objective_rows(case) for case in cases]...)
    worst = argmax(row -> row.normalized_value, rows)
    return (
        method = method,
        sw_indices = collect(sw_indices),
        objective = worst.normalized_value,
        worst_case = worst.case,
        worst_metric = worst.metric,
        worst_value = worst.value,
        worst_threshold = worst.threshold,
        rows = rows,
    )
end

function smooth_normalized_objective_from_rows(rows; beta = 8.0)
    values = [row.normalized_value for row in rows]
    isempty(values) && return 0.0
    m = maximum(values)
    return m + log(sum(exp.(beta .* (values .- m)))) / beta
end

function smooth_reduced_objective(full_model, parameters;
                                  sw_indices = WEIGHTED_GREEDY_SW_16_INDICES,
                                  beta = 8.0)
    model = reduced_model_from_parameters(full_model, parameters; sw_indices)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    rows = vcat([normalized_objective_rows(case) for case in cases]...)
    return smooth_normalized_objective_from_rows(rows; beta)
end

function constrained_table_optimizer_target(breakdown)
    return (
        method = "constrained table/quadrature optimizer target from dominant hard-gate residual",
        target_case = breakdown.worst_case,
        target_metric = breakdown.worst_metric,
        target_value = breakdown.worst_value,
        target_threshold = breakdown.worst_threshold,
        target_normalized_value = breakdown.objective,
        required_absolute_reduction = max(breakdown.worst_value - breakdown.worst_threshold, 0.0),
        required_relative_reduction =
            breakdown.worst_value <= 0 ? 0.0 :
            max(breakdown.worst_value - breakdown.worst_threshold, 0.0) /
            breakdown.worst_value,
        rejected_local_parameterizations = [
            "48-parameter weights/static-plus-H2O absorption/Rayleigh scalar scan",
            "targeted worst-metric scalar coordinate scan",
            "64-parameter separated static-absorption/H2O/Rayleigh scalar scan",
            "weighted 32-to-16 optical-depth projection target",
        ],
        recommended_next_parameterization =
            "nonnegative shortwave coefficient-table or quadrature-bin optimizer with objective terms for TOA forcing, surface forcing, flux profiles, and heating rates",
        acceptance_rule =
            "accept only candidates that reduce the full normalized hard-gate objective and keep all clean ecCKD cases within the final hard thresholds",
    )
end

function reduced_case_by_name(case_name)
    for case in REDUCED_CASES
        case.case == case_name && return case
    end
    throw(ArgumentError("unknown reduced case $case_name"))
end

function normalized_metric_value(case, metric)
    if metric == "toa_forcing_max_abs"
        return case.toa_forcing_max_abs /
               ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2
    elseif metric == "surface_forcing_max_abs"
        return case.surface_forcing_max_abs /
               ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2
    end
    metric_match = Base.match(r"^(sw_up|sw_down|heating_rate)_(rmse|max_abs)$", metric)
    metric_match === nothing &&
        throw(ArgumentError("unsupported normalized metric $metric"))
    variable = Symbol(metric_match.captures[1])
    statistic = Symbol(metric_match.captures[2])
    metrics = getproperty(case.variables, variable)
    value = getproperty(metrics, statistic)
    if variable == :heating_rate
        threshold = statistic == :rmse ?
            ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day :
            ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day
    else
        threshold = statistic == :rmse ?
            ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2 :
            ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2
    end
    return value / threshold
end

function targeted_metric_objective(full_model, parameters, case_name, metric;
                                   sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    model = reduced_model_from_parameters(full_model, parameters; sw_indices)
    case = case_metrics(reduced_case_by_name(case_name), model)
    return normalized_metric_value(case, metric)
end

function separated_component_metric_objective(full_model, parameters, case_name, metric;
                                              sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    model = separated_component_model_from_parameters(full_model, parameters; sw_indices)
    case = case_metrics(reduced_case_by_name(case_name), model)
    return normalized_metric_value(case, metric)
end

function central_directional_derivative(f, parameters, direction; step = 1.0e-4)
    normalized_direction = direction ./ norm(direction)
    plus = parameters .+ step .* normalized_direction
    minus = parameters .- step .* normalized_direction
    return (f(plus) - f(minus)) / (2step)
end

function finite_difference_gradient(f, parameters; step = 1.0e-5)
    gradient = similar(parameters)
    plus = copy(parameters)
    minus = copy(parameters)
    for i in eachindex(parameters)
        plus .= parameters
        minus .= parameters
        plus[i] += step
        minus[i] -= step
        gradient[i] = (f(plus) - f(minus)) / (2step)
    end
    return gradient
end

function surrogate_target_parameters()
    ng = length(WEIGHTED_GREEDY_SW_16_INDICES)
    weights = max.(WEIGHTED_GREEDY_SW_16_WEIGHTS, eps(Float64))
    logits = log.(weights)
    absorption_log_scales = log.(WEIGHTED_GREEDY_SW_16_COEFFICIENT_SCALES)
    rayleigh_log_scales = zeros(Float64, ng)
    return vcat(logits, absorption_log_scales, rayleigh_log_scales)
end

function reduced_parameter_surrogate_loss(parameters)
    target = surrogate_target_parameters()
    total = zero(eltype(parameters))
    for i in eachindex(parameters)
        total += (parameters[i] - target[i])^2
    end
    return total / length(parameters)
end

function relative_gradient_difference(g1, g2)
    return norm(g1 .- g2) / max(norm(g2), eps(eltype(g2)))
end

function enzyme_surrogate_check(parameters)
    get(ENV, "RH_SKIP_OPTIONAL_AD_CHECKS", "false") == "true" && return (
        status = "skipped_by_RH_SKIP_OPTIONAL_AD_CHECKS",
        check = "official_reduced_parameter_surrogate",
        relative_error = nothing,
        threshold = 1.0e-4,
        passed = false,
        error = nothing,
    )

    Base.find_package("Enzyme") === nothing && return (
        status = "not_available_in_active_project",
        check = "official_reduced_parameter_surrogate",
        relative_error = nothing,
        threshold = 1.0e-4,
        passed = false,
        error = nothing,
    )

    try
        enzyme = Base.require(Base.PkgId(Base.UUID("7da242da-08ed-463a-9acd-ee780be4f1d9"), "Enzyme"))
        enzyme_gradient = zeros(length(parameters))
        f(x) = reduced_parameter_surrogate_loss(x)
        duplicated = Base.invokelatest(enzyme.Duplicated, copy(parameters), enzyme_gradient)
        Base.invokelatest(enzyme.autodiff,
                          enzyme.Reverse,
                          f,
                          enzyme.Active,
                          duplicated)
        finite_difference = finite_difference_gradient(f, parameters)
        relative_error = relative_gradient_difference(enzyme_gradient, finite_difference)
        threshold = 1.0e-4
        return (
            status = relative_error <= threshold ? "passed" : "failed",
            check = "official_reduced_parameter_surrogate",
            relative_error = relative_error,
            threshold = threshold,
            passed = relative_error <= threshold,
            error = nothing,
        )
    catch err
        return (
            status = "failed",
            check = "official_reduced_parameter_surrogate",
            relative_error = nothing,
            threshold = 1.0e-4,
            passed = false,
            error = first_error_line(err),
        )
    end
end

function reactant_surrogate_check(parameters)
    get(ENV, "RH_SKIP_OPTIONAL_AD_CHECKS", "false") == "true" && return (
        status = "skipped_by_RH_SKIP_OPTIONAL_AD_CHECKS",
        check = "official_reduced_parameter_surrogate",
        passed = false,
        error = nothing,
    )

    Base.find_package("Reactant") === nothing && return (
        status = "not_available_in_active_project",
        check = "official_reduced_parameter_surrogate",
        passed = false,
        error = nothing,
    )

    try
        reactant = Base.require(Base.PkgId(Base.UUID("3c362404-f566-11ee-1572-e11a4b42c853"), "Reactant"))
        target = surrogate_target_parameters()
        Base.invokelatest(reactant.set_default_backend, "cpu")
        Core.eval(@__MODULE__, :(const Reactant = $reactant))
        Core.eval(@__MODULE__, quote
            official_reduced_surrogate_loss(x, target) = sum(abs2, x .- target) / length(x)
            x = Reactant.to_rarray($(copy(parameters)))
            target = Reactant.to_rarray($target)
            Reactant.@compile raise = true raise_first = true sync = true official_reduced_surrogate_loss(x, target)
        end)
        return (
            status = "passed",
            check = "official_reduced_parameter_surrogate",
            passed = true,
            error = nothing,
        )
    catch err
        return (
            status = "failed",
            check = "official_reduced_parameter_surrogate",
            passed = false,
            error = first_error_line(err),
        )
    end
end

function trial_line_search(f, parameters, direction)
    normalized_direction = direction ./ norm(direction)
    initial = f(parameters)
    trials = NamedTuple[]
    for step in (1.0e-4, 3.0e-4, 1.0e-3, 3.0e-3, 1.0e-2)
        objective = f(parameters .+ step .* normalized_direction)
        push!(trials, (
            step = step,
            objective = objective,
            improved = objective < initial,
        ))
    end
    best = argmin(trial -> trial.objective, trials)
    return (
        trials = trials,
        best_step = best.step,
        best_objective = best.objective,
        improved = best.objective < initial,
    )
end

function optimization_smoke_result(initial_objective, line_search)
    return (
        method = "deterministic finite-difference directional line search",
        iterations = 1,
        initial_objective = initial_objective,
        final_objective = line_search.best_objective,
        objective_reduction = initial_objective - line_search.best_objective,
        improved = line_search.improved,
    )
end

function deterministic_directional_search(f, parameters, direction; iterations = 2)
    current_parameters = copy(parameters)
    initial_objective = f(current_parameters)
    current_objective = initial_objective
    steps = NamedTuple[]
    for iteration in 1:iterations
        line_search = trial_line_search(f, current_parameters, direction)
        if line_search.improved
            normalized_direction = direction ./ norm(direction)
            current_parameters .+= line_search.best_step .* normalized_direction
            current_objective = line_search.best_objective
        end
        push!(steps, (
            iteration = iteration,
            best_step = line_search.best_step,
            objective = line_search.best_objective,
            improved = line_search.improved,
        ))
    end
    return (
        method = "deterministic repeated directional search",
        iterations = iterations,
        initial_objective = initial_objective,
        final_objective = current_objective,
        objective_reduction = initial_objective - current_objective,
        improved = current_objective < initial_objective,
        steps = steps,
    )
end

function block_direction(ng, block)
    direction = zeros(Float64, 3ng)
    offset = block == :weights ? 0 : block == :absorption ? ng : 2ng
    for i in 1:ng
        direction[offset + i] = sin(0.41i) + 0.25cos(0.23i)
    end
    return direction ./ norm(direction)
end

function block_trial_scan(f, parameters; step = 1.0e-2)
    ng = length(WEIGHTED_GREEDY_SW_16_INDICES)
    initial = f(parameters)
    rows = NamedTuple[]
    for block in (:weights, :absorption, :rayleigh)
        direction = block_direction(ng, block)
        forward = f(parameters .+ step .* direction)
        backward = f(parameters .- step .* direction)
        best = min(forward, backward)
        push!(rows, (
            block = String(block),
            forward_objective = forward,
            backward_objective = backward,
            best_objective = best,
            best_improvement = initial - best,
            improved = best < initial,
        ))
    end
    best_row = argmin(row -> row.best_objective, rows)
    return (
        step = step,
        initial_objective = initial,
        rows = rows,
        best_block = best_row.block,
        best_objective = best_row.best_objective,
        best_improvement = best_row.best_improvement,
    )
end

function coordinate_coefficient_scan(f, parameters; steps = (0.25, 1.0))
    ng = length(WEIGHTED_GREEDY_SW_16_INDICES)
    initial = f(parameters)
    rows = NamedTuple[]
    for block in (:absorption, :rayleigh)
        offset = block == :absorption ? ng : 2ng
        for ig in 1:ng
            for step in steps
                forward_parameters = copy(parameters)
                backward_parameters = copy(parameters)
                forward_parameters[offset + ig] += step
                backward_parameters[offset + ig] -= step
                forward = f(forward_parameters)
                backward = f(backward_parameters)
                best_direction = forward <= backward ? "positive" : "negative"
                best_objective = min(forward, backward)
                push!(rows, (
                    block = String(block),
                    gpoint = WEIGHTED_GREEDY_SW_16_INDICES[ig],
                    local_index = ig,
                    step = step,
                    forward_objective = forward,
                    backward_objective = backward,
                    best_direction = best_direction,
                    best_objective = best_objective,
                    best_improvement = initial - best_objective,
                    improved = best_objective < initial,
                ))
            end
        end
    end
    best = argmin(row -> row.best_objective, rows)
    return (
        method = "bounded one-coordinate absorption/Rayleigh log-scale scan",
        initial_objective = initial,
        candidate_count = length(rows),
        rows = rows,
        best_block = best.block,
        best_gpoint = best.gpoint,
        best_local_index = best.local_index,
        best_step = best.step,
        best_direction = best.best_direction,
        best_objective = best.best_objective,
        best_improvement = best.best_improvement,
    )
end

function apply_coordinate_move(parameters, scan)
    updated = copy(parameters)
    ng = length(WEIGHTED_GREEDY_SW_16_INDICES)
    offset = scan.best_block == "absorption" ? ng : 2ng
    direction = scan.best_direction == "positive" ? 1.0 : -1.0
    updated[offset + scan.best_local_index] += direction * scan.best_step
    return updated
end

function greedy_coordinate_descent(f, parameters; iterations = 6,
                                   steps = (0.25, 1.0),
                                   initial_objective = nothing,
                                   initial_iterations = 0)
    current_parameters = copy(parameters)
    current_objective = f(current_parameters)
    origin_objective = initial_objective === nothing ? current_objective : initial_objective
    best_parameters = copy(current_parameters)
    best_objective = current_objective
    trajectory = NamedTuple[]

    for iteration in 1:iterations
        scan = coordinate_coefficient_scan(f, current_parameters; steps = steps)
        improved = scan.best_objective < current_objective
        push!(trajectory, (
            iteration = initial_iterations + iteration,
            initial_objective = current_objective,
            best_block = scan.best_block,
            best_gpoint = scan.best_gpoint,
            best_local_index = scan.best_local_index,
            best_step = scan.best_step,
            best_direction = scan.best_direction,
            best_objective = scan.best_objective,
            best_improvement = current_objective - scan.best_objective,
            improved = improved,
        ))
        improved || break
        current_parameters = apply_coordinate_move(current_parameters, scan)
        current_objective = scan.best_objective
        if current_objective < best_objective
            best_objective = current_objective
            best_parameters .= current_parameters
        end
    end

    return (
        method = "greedy bounded coordinate descent over absorption/Rayleigh log-scales",
        iterations_requested = initial_iterations + iterations,
        iterations_completed = initial_iterations + length(trajectory),
        initial_objective = origin_objective,
        final_objective = best_objective,
        objective_reduction = origin_objective - best_objective,
        improved = best_objective < origin_objective,
        trajectory = trajectory,
        final_parameters = collect(best_parameters),
    )
end

function cached_greedy_descent_checkpoint(initial_objective, parameters;
                                          path = PREFLIGHT_JSON)
    isfile(path) || return nothing
    text = read(path, String)
    parameter_match = Base.match(r"\"final_parameters\"\s*:\s*\[([^\]]+)\]", text)
    objective_match = Base.match(r"\"greedy_coordinate_descent\"\s*:\s*\{[\s\S]*?\"final_objective\"\s*:\s*([-+0-9.eE]+)", text)
    iterations_match = Base.match(r"\"greedy_coordinate_descent\"\s*:\s*\{[\s\S]*?\"iterations_completed\"\s*:\s*([0-9]+)", text)
    parameter_match === nothing && return nothing
    objective_match === nothing && return nothing
    values = parse.(Float64, split(parameter_match.captures[1], ","))
    length(values) == length(parameters) || return nothing
    final_objective = parse(Float64, objective_match.captures[1])
    isfinite(final_objective) && final_objective < initial_objective || return nothing
    iterations_completed = iterations_match === nothing ? 0 : parse(Int, iterations_match.captures[1])
    return (
        method = "cached greedy bounded coordinate descent checkpoint over absorption/Rayleigh log-scales",
        iterations_requested = iterations_completed,
        iterations_completed = iterations_completed,
        initial_objective = initial_objective,
        final_objective = final_objective,
        objective_reduction = initial_objective - final_objective,
        improved = true,
        trajectory = NamedTuple[],
        final_parameters = values,
        checkpoint_source = path,
    )
end

function greedy_total_iterations()
    return parse(Int, get(ENV, "RH_REDUCED_GREEDY_TOTAL_ITERATIONS", "14"))
end

function greedy_coordinate_descent_with_checkpoint(f, parameters, initial_objective;
                                                   total_iterations = greedy_total_iterations(),
                                                   checkpoint_path = PREFLIGHT_JSON)
    cached = cached_greedy_descent_checkpoint(
        initial_objective,
        parameters;
        path = checkpoint_path,
    )
    if cached === nothing
        return greedy_coordinate_descent(f, parameters; iterations = total_iterations),
            false
    end
    cached.iterations_completed > total_iterations && return cached, true
    cached.iterations_completed >= total_iterations && return cached, true

    remaining_iterations = total_iterations - cached.iterations_completed
    resumed = greedy_coordinate_descent(
        f,
        cached.final_parameters;
        iterations = remaining_iterations,
        initial_objective = initial_objective,
        initial_iterations = cached.iterations_completed,
    )
    return (
        method = "resumed greedy bounded coordinate descent over absorption/Rayleigh log-scales",
        iterations_requested = total_iterations,
        iterations_completed = resumed.iterations_completed,
        initial_objective = initial_objective,
        final_objective = resumed.final_objective,
        objective_reduction = initial_objective - resumed.final_objective,
        improved = resumed.final_objective < initial_objective,
        trajectory = resumed.trajectory,
        final_parameters = resumed.final_parameters,
        checkpoint_source = cached.checkpoint_source,
        checkpoint_iterations = cached.iterations_completed,
        checkpoint_objective = cached.final_objective,
    ), true
end

function _normalized_direction(entries, nparameters)
    direction = zeros(Float64, nparameters)
    for (index, sign_value) in entries
        direction[index] = sign_value
    end
    magnitude = norm(direction)
    magnitude == 0 && return nothing
    return direction ./ magnitude
end

function coefficient_joint_directions(parameters)
    ng = length(WEIGHTED_GREEDY_SW_16_INDICES)
    absorption_entries = [
        (ng + i, sign(parameters[ng + i]))
        for i in 1:ng if parameters[ng + i] != 0.0
    ]
    rayleigh_entries = [
        (2ng + i, sign(parameters[2ng + i]))
        for i in 1:ng if parameters[2ng + i] != 0.0
    ]
    directions = NamedTuple[]
    for (name, entries) in (
            ("nonzero_absorption_scales", absorption_entries),
            ("nonzero_rayleigh_scales", rayleigh_entries),
            ("all_nonzero_coefficient_scales", vcat(absorption_entries, rayleigh_entries)),
        )
        direction = _normalized_direction(entries, length(parameters))
        direction === nothing && continue
        push!(directions, (
            name = name,
            active_parameter_count = length(entries),
            direction = direction,
        ))
    end
    return directions
end

function coefficient_joint_direction_scan(f, parameters; steps = (0.125, 0.25, 0.5, 1.0))
    initial = f(parameters)
    rows = NamedTuple[]
    for direction in coefficient_joint_directions(parameters)
        for step in steps
            plus_parameters = parameters .+ step .* direction.direction
            minus_parameters = parameters .- step .* direction.direction
            plus = f(plus_parameters)
            minus = f(minus_parameters)
            best_direction = plus <= minus ? "positive" : "negative"
            best_objective = min(plus, minus)
            push!(rows, (
                direction = direction.name,
                active_parameter_count = direction.active_parameter_count,
                step = step,
                plus_objective = plus,
                minus_objective = minus,
                best_direction = best_direction,
                best_objective = best_objective,
                best_improvement = initial - best_objective,
                improved = best_objective < initial,
            ))
        end
    end

    if isempty(rows)
        return (
            method = "joint coefficient direction scan over nonzero optimized scales",
            initial_objective = initial,
            candidate_count = 0,
            rows = rows,
            best_direction_name = nothing,
            best_step = nothing,
            best_step_direction = nothing,
            best_objective = initial,
            best_improvement = 0.0,
            final_parameters = collect(parameters),
        )
    end

    best = argmin(row -> row.best_objective, rows)
    best_direction = only(filter(direction -> direction.name == best.direction,
                                 coefficient_joint_directions(parameters))).direction
    signed_step = best.best_direction == "positive" ? best.step : -best.step
    return (
        method = "joint coefficient direction scan over nonzero optimized scales",
        initial_objective = initial,
        candidate_count = length(rows),
        rows = rows,
        best_direction_name = best.direction,
        best_step = best.step,
        best_step_direction = best.best_direction,
        best_objective = best.best_objective,
        best_improvement = best.best_improvement,
        final_parameters = collect(parameters .+ signed_step .* best_direction),
    )
end

function post_joint_refinement_iterations()
    return parse(Int, get(ENV, "RH_REDUCED_POST_JOINT_REFINEMENT_ITERATIONS", "2"))
end

function post_joint_coordinate_refinement(f, parameters;
                                          iterations = post_joint_refinement_iterations(),
                                          steps = (0.125, 0.25))
    current_parameters = copy(parameters)
    initial_objective = f(current_parameters)
    current_objective = initial_objective
    best_parameters = copy(current_parameters)
    trajectory = NamedTuple[]

    for iteration in 1:iterations
        scan = coordinate_coefficient_scan(f, current_parameters; steps = steps)
        improved = scan.best_objective < current_objective
        push!(trajectory, (
            iteration = iteration,
            initial_objective = current_objective,
            best_block = scan.best_block,
            best_gpoint = scan.best_gpoint,
            best_local_index = scan.best_local_index,
            best_step = scan.best_step,
            best_direction = scan.best_direction,
            best_objective = scan.best_objective,
            best_improvement = current_objective - scan.best_objective,
            improved = improved,
        ))
        improved || break
        current_parameters = apply_coordinate_move(current_parameters, scan)
        current_objective = scan.best_objective
        best_parameters .= current_parameters
    end

    return (
        method = "small-step coordinate refinement after joint coefficient direction scan",
        iterations_requested = iterations,
        iterations_completed = length(trajectory),
        initial_objective = initial_objective,
        final_objective = current_objective,
        objective_reduction = initial_objective - current_objective,
        improved = current_objective < initial_objective,
        trajectory = trajectory,
        final_parameters = collect(best_parameters),
    )
end

function weight_coordinate_refinement_iterations()
    return parse(Int, get(ENV, "RH_REDUCED_WEIGHT_REFINEMENT_ITERATIONS", "2"))
end

function coordinate_weight_scan(f, parameters; steps = (0.125, 0.25, 0.5))
    ng = length(WEIGHTED_GREEDY_SW_16_INDICES)
    initial = f(parameters)
    rows = NamedTuple[]
    for ig in 1:ng
        for step in steps
            forward_parameters = copy(parameters)
            backward_parameters = copy(parameters)
            forward_parameters[ig] += step
            backward_parameters[ig] -= step
            forward = f(forward_parameters)
            backward = f(backward_parameters)
            best_direction = forward <= backward ? "positive" : "negative"
            best_objective = min(forward, backward)
            push!(rows, (
                block = "weights",
                gpoint = WEIGHTED_GREEDY_SW_16_INDICES[ig],
                local_index = ig,
                step = step,
                forward_objective = forward,
                backward_objective = backward,
                best_direction = best_direction,
                best_objective = best_objective,
                best_improvement = initial - best_objective,
                improved = best_objective < initial,
            ))
        end
    end
    best = argmin(row -> row.best_objective, rows)
    return (
        method = "bounded one-coordinate shortwave softmax-logit scan",
        initial_objective = initial,
        candidate_count = length(rows),
        rows = rows,
        best_block = best.block,
        best_gpoint = best.gpoint,
        best_local_index = best.local_index,
        best_step = best.step,
        best_direction = best.best_direction,
        best_objective = best.best_objective,
        best_improvement = best.best_improvement,
    )
end

function apply_weight_coordinate_move(parameters, scan)
    updated = copy(parameters)
    direction = scan.best_direction == "positive" ? 1.0 : -1.0
    updated[scan.best_local_index] += direction * scan.best_step
    return updated
end

function post_coefficient_weight_refinement(f, parameters;
                                            iterations = weight_coordinate_refinement_iterations(),
                                            steps = (0.125, 0.25, 0.5))
    current_parameters = copy(parameters)
    initial_objective = f(current_parameters)
    current_objective = initial_objective
    best_parameters = copy(current_parameters)
    trajectory = NamedTuple[]

    for iteration in 1:iterations
        scan = coordinate_weight_scan(f, current_parameters; steps = steps)
        improved = scan.best_objective < current_objective
        push!(trajectory, (
            iteration = iteration,
            initial_objective = current_objective,
            best_gpoint = scan.best_gpoint,
            best_local_index = scan.best_local_index,
            best_step = scan.best_step,
            best_direction = scan.best_direction,
            best_objective = scan.best_objective,
            best_improvement = current_objective - scan.best_objective,
            improved = improved,
        ))
        improved || break
        current_parameters = apply_weight_coordinate_move(current_parameters, scan)
        current_objective = scan.best_objective
        best_parameters .= current_parameters
    end

    return (
        method = "softmax-weight coordinate refinement after coefficient optimization",
        iterations_requested = iterations,
        iterations_completed = length(trajectory),
        initial_objective = initial_objective,
        final_objective = current_objective,
        objective_reduction = initial_objective - current_objective,
        improved = current_objective < initial_objective,
        trajectory = trajectory,
        final_parameters = collect(best_parameters),
    )
end

function coefficient_parameter_indices(parameters)
    ng = length(WEIGHTED_GREEDY_SW_16_INDICES)
    length(parameters) == 3ng ||
        throw(DimensionMismatch("coefficient gradient refinement expects 3 * ng_sw parameters"))
    return (ng + 1):(3ng)
end

function finite_difference_coefficient_direction_refinement(f, parameters;
                                                           h = 0.03125,
                                                           steps = (0.125, 0.25, 0.5, 1.0))
    initial = f(parameters)
    gradient = zeros(Float64, length(parameters))
    rows = NamedTuple[]
    for index in coefficient_parameter_indices(parameters)
        forward_parameters = copy(parameters)
        backward_parameters = copy(parameters)
        forward_parameters[index] += h
        backward_parameters[index] -= h
        forward = f(forward_parameters)
        backward = f(backward_parameters)
        gradient[index] = (forward - backward) / (2h)
        push!(rows, (
            parameter_index = index,
            local_index = ((index - 1) % length(WEIGHTED_GREEDY_SW_16_INDICES)) + 1,
            block = index <= 2 * length(WEIGHTED_GREEDY_SW_16_INDICES) ?
                "absorption" : "rayleigh",
            forward_objective = forward,
            backward_objective = backward,
            central_gradient = gradient[index],
        ))
    end

    magnitude = norm(gradient)
    if !isfinite(magnitude) || magnitude == 0
        return (
            method = "central finite-difference normalized coefficient-gradient line search",
            initial_objective = initial,
            active_parameter_count = length(rows),
            gradient_norm = magnitude,
            candidate_count = 0,
            rows = rows,
            trials = NamedTuple[],
            best_step = nothing,
            best_objective = initial,
            best_improvement = 0.0,
            improved = false,
            final_parameters = collect(parameters),
        )
    end

    direction = -gradient ./ magnitude
    trials = NamedTuple[]
    for step in steps
        candidate_parameters = parameters .+ step .* direction
        objective = f(candidate_parameters)
        push!(trials, (
            step = step,
            objective = objective,
            improvement = initial - objective,
            improved = objective < initial,
        ))
    end
    best = argmin(trial -> trial.objective, trials)
    improved = best.objective < initial
    return (
        method = "central finite-difference normalized coefficient-gradient line search",
        initial_objective = initial,
        active_parameter_count = length(rows),
        gradient_norm = magnitude,
        candidate_count = 2length(rows) + length(trials),
        rows = rows,
        trials = trials,
        best_step = best.step,
        best_objective = best.objective,
        best_improvement = best.improvement,
        improved = improved,
        final_parameters = collect(improved ? parameters .+ best.step .* direction : parameters),
    )
end

function smooth_objective_beta()
    return parse(Float64, get(ENV, "RH_REDUCED_SMOOTH_OBJECTIVE_BETA", "8.0"))
end

function smooth_objective_coefficient_refinement(full_model, parameters;
                                                 beta = smooth_objective_beta(),
                                                 h = 0.03125,
                                                 steps = (0.125, 0.25, 0.5, 1.0),
                                                 sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    smooth_f(x) = smooth_reduced_objective(
        full_model,
        x;
        sw_indices,
        beta,
    )
    hard_f(x) = reduced_objective(full_model, x; sw_indices)
    smooth_refinement = finite_difference_coefficient_direction_refinement(
        smooth_f,
        parameters;
        h,
        steps,
    )
    initial_hard_objective = hard_f(parameters)
    candidate_hard_objective = hard_f(smooth_refinement.final_parameters)
    accepted = smooth_refinement.improved &&
               candidate_hard_objective < initial_hard_objective
    return (
        method = "log-sum-exp smoothed normalized residual coefficient-gradient line search",
        beta = beta,
        initial_smooth_objective = smooth_refinement.initial_objective,
        best_smooth_objective = smooth_refinement.best_objective,
        smooth_improved = smooth_refinement.improved,
        initial_hard_objective = initial_hard_objective,
        candidate_hard_objective = candidate_hard_objective,
        accepted = accepted,
        active_parameter_count = smooth_refinement.active_parameter_count,
        gradient_norm = smooth_refinement.gradient_norm,
        candidate_count = smooth_refinement.candidate_count,
        best_step = smooth_refinement.best_step,
        best_smooth_improvement = smooth_refinement.best_improvement,
        final_objective = accepted ? candidate_hard_objective : initial_hard_objective,
        final_parameters = collect(accepted ? smooth_refinement.final_parameters : parameters),
        smooth_refinement = smooth_refinement,
    )
end

function targeted_refinement_candidate_limit()
    return parse(Int, get(ENV, "RH_REDUCED_TARGETED_REFINEMENT_CANDIDATES", "96"))
end

function targeted_metric_coordinate_scan(metric_f, parameters;
                                         steps = (0.0625, 0.125, 0.25),
                                         max_candidates = targeted_refinement_candidate_limit())
    initial = metric_f(parameters)
    rows = NamedTuple[]
    candidate_count = 0
    stop = false
    for index in eachindex(parameters)
        for step in steps
            forward_parameters = copy(parameters)
            backward_parameters = copy(parameters)
            forward_parameters[index] += step
            backward_parameters[index] -= step
            forward = metric_f(forward_parameters)
            backward = metric_f(backward_parameters)
            best_direction = forward <= backward ? "positive" : "negative"
            best_objective = min(forward, backward)
            push!(rows, (
                parameter_index = index,
                block = index <= length(WEIGHTED_GREEDY_SW_16_INDICES) ? "weights" :
                    index <= 2 * length(WEIGHTED_GREEDY_SW_16_INDICES) ? "absorption" :
                    index <= 3 * length(WEIGHTED_GREEDY_SW_16_INDICES) ? "dynamic_h2o" :
                    "rayleigh",
                local_index = ((index - 1) % length(WEIGHTED_GREEDY_SW_16_INDICES)) + 1,
                step = step,
                forward_objective = forward,
                backward_objective = backward,
                best_direction = best_direction,
                best_objective = best_objective,
                best_improvement = initial - best_objective,
                improved = best_objective < initial,
            ))
            candidate_count += 2
            if candidate_count >= max_candidates
                stop = true
                break
            end
        end
        stop && break
    end
    best = argmin(row -> row.best_objective, rows)
    return (
        method = "bounded coordinate scan against current worst normalized metric",
        initial_objective = initial,
        candidate_count = candidate_count,
        rows = rows,
        best_parameter_index = best.parameter_index,
        best_block = best.block,
        best_local_index = best.local_index,
        best_step = best.step,
        best_direction = best.best_direction,
        best_objective = best.best_objective,
        best_improvement = best.best_improvement,
        improved = best.best_objective < initial,
    )
end

function apply_targeted_metric_move(parameters, scan)
    updated = copy(parameters)
    direction = scan.best_direction == "positive" ? 1.0 : -1.0
    updated[scan.best_parameter_index] += direction * scan.best_step
    return updated
end

function targeted_worst_metric_refinement(full_model, parameters, breakdown, full_f)
    metric_f(x) = targeted_metric_objective(
        full_model,
        x,
        breakdown.worst_case,
        breakdown.worst_metric,
    )
    scan = targeted_metric_coordinate_scan(metric_f, parameters)
    candidate_parameters = scan.improved ?
        apply_targeted_metric_move(parameters, scan) : copy(parameters)
    initial_full_objective = full_f(parameters)
    candidate_full_objective = scan.improved ?
        full_f(candidate_parameters) : initial_full_objective
    accepted = scan.improved && candidate_full_objective < initial_full_objective
    return (
        method = "targeted current-worst-metric coordinate refinement with full-objective acceptance",
        target_case = breakdown.worst_case,
        target_metric = breakdown.worst_metric,
        target_initial_objective = scan.initial_objective,
        target_best_objective = scan.best_objective,
        target_improvement = scan.best_improvement,
        target_improved = scan.improved,
        scan = scan,
        initial_full_objective = initial_full_objective,
        candidate_full_objective = candidate_full_objective,
        accepted = accepted,
        final_objective = accepted ? candidate_full_objective : initial_full_objective,
        final_parameters = collect(accepted ? candidate_parameters : parameters),
    )
end

function separated_component_refinement_candidate_limit()
    return parse(Int, get(ENV, "RH_REDUCED_SEPARATED_COMPONENT_CANDIDATES", "64"))
end

function separated_component_refinement(full_model, base_parameters, breakdown)
    parameters = separated_component_parameters(base_parameters)
    full_f(x) = separated_component_objective(full_model, x)
    metric_f(x) = separated_component_metric_objective(
        full_model,
        x,
        breakdown.worst_case,
        breakdown.worst_metric,
    )
    scan = targeted_metric_coordinate_scan(
        metric_f,
        parameters;
        max_candidates = separated_component_refinement_candidate_limit(),
    )
    candidate_parameters = scan.improved ?
        apply_targeted_metric_move(parameters, scan) : copy(parameters)
    initial_full_objective = full_f(parameters)
    candidate_full_objective = scan.improved ?
        full_f(candidate_parameters) : initial_full_objective
    accepted = scan.improved && candidate_full_objective < initial_full_objective
    return (
        method = "separated static/H2O/Rayleigh component refinement with full-objective acceptance",
        parameter_count = length(parameters),
        target_case = breakdown.worst_case,
        target_metric = breakdown.worst_metric,
        target_initial_objective = scan.initial_objective,
        target_best_objective = scan.best_objective,
        target_improvement = scan.best_improvement,
        target_improved = scan.improved,
        scan = scan,
        initial_full_objective = initial_full_objective,
        candidate_full_objective = candidate_full_objective,
        accepted = accepted,
        final_objective = accepted ? candidate_full_objective : initial_full_objective,
        final_parameters = collect(accepted ? candidate_parameters : parameters),
    )
end

function pressure_bands(npressure, nband)
    edges = round.(Int, range(1, npressure + 1; length = nband + 1))
    return [edges[i]:(edges[i + 1] - 1) for i in 1:nband]
end

function apply_pressure_band_table_move!(model, move)
    scale = exp(clamp(move.log_scale, -5.0, 5.0))
    band = move.pressure_index_start:move.pressure_index_end
    ig = move.local_gpoint_index
    if move.component == "static_absorption"
        model.shortwave_absorption[ig, :, band, :] .*= scale
    elseif move.component == "dynamic_h2o"
        if length(model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[ig, band, :, :] .*= scale
        end
    else
        throw(ArgumentError("unsupported table move component $(move.component)"))
    end
    return model
end

function pressure_band_table_moved_model(full_model, parameters, moves;
                                         sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    model = reduced_model_from_parameters(full_model, parameters; sw_indices)
    for move in moves
        apply_pressure_band_table_move!(model, move)
    end
    return model
end

function pressure_band_table_full_objective(full_model, parameters, moves;
                                            sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    model = pressure_band_table_moved_model(full_model, parameters, moves; sw_indices)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return maximum(normalized_case_objective, cases)
end

function pressure_band_table_metric_objective(full_model, parameters, moves,
                                              case_name, metric;
                                              sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    model = pressure_band_table_moved_model(full_model, parameters, moves; sw_indices)
    case = case_metrics(reduced_case_by_name(case_name), model)
    return normalized_metric_value(case, metric)
end

function apply_active_table_entry_move!(model, move)
    scale = exp(clamp(move.log_scale, -5.0, 5.0))
    ig = move.local_gpoint_index
    if move.component == "static_absorption"
        model.shortwave_absorption[
            ig,
            move.gas_index,
            move.pressure_index,
            move.temperature_index,
        ] *= scale
    elseif move.component == "dynamic_h2o"
        if length(model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[
                ig,
                move.pressure_index,
                move.temperature_index,
                move.h2o_index,
            ] *= scale
        end
    elseif move.component == "rayleigh"
        model.shortwave_rayleigh_molar_scattering[ig] *= scale
    else
        throw(ArgumentError("unsupported active table-entry component $(move.component)"))
    end
    return model
end

function pressure_band_active_table_moved_model(full_model, parameters,
                                                pressure_moves, active_moves;
                                                sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    model = pressure_band_table_moved_model(full_model, parameters, pressure_moves; sw_indices)
    for move in active_moves
        apply_active_table_entry_move!(model, move)
    end
    return model
end

function pressure_band_active_table_full_objective(full_model, parameters,
                                                   pressure_moves, active_moves;
                                                   sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    model = pressure_band_active_table_moved_model(
        full_model,
        parameters,
        pressure_moves,
        active_moves;
        sw_indices,
    )
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return maximum(normalized_case_objective, cases)
end

function pressure_band_active_table_metric_objective(full_model, parameters,
                                                     pressure_moves, active_moves,
                                                     case_name, metric;
                                                     sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    model = pressure_band_active_table_moved_model(
        full_model,
        parameters,
        pressure_moves,
        active_moves;
        sw_indices,
    )
    case = case_metrics(reduced_case_by_name(case_name), model)
    return normalized_metric_value(case, metric)
end

function pressure_band_table_refinement_candidate_limit()
    return parse(Int, get(ENV, "RH_REDUCED_TABLE_REFINEMENT_CANDIDATES", "64"))
end

function pressure_band_table_refinement_iterations()
    return parse(Int, get(ENV, "RH_REDUCED_TABLE_REFINEMENT_ITERATIONS", "2"))
end

function pressure_band_table_refinement(full_model, parameters, breakdown;
                                        sw_indices = WEIGHTED_GREEDY_SW_16_INDICES,
                                        nband = 4,
                                        steps = (0.125, 0.25),
                                        max_candidates =
                                            pressure_band_table_refinement_candidate_limit(),
                                        iterations =
                                            pressure_band_table_refinement_iterations())
    bands = pressure_bands(length(full_model.pressure_grid), nband)
    moves = NamedTuple[]
    initial_full_objective =
        pressure_band_table_full_objective(full_model, parameters, moves; sw_indices)
    current_full_objective = initial_full_objective
    trajectory = NamedTuple[]

    for iteration in 1:iterations
        current_metric_objective = pressure_band_table_metric_objective(
            full_model,
            parameters,
            moves,
            breakdown.worst_case,
            breakdown.worst_metric;
            sw_indices,
        )
        rows = NamedTuple[]
        candidate_count = 0
        stop = false
        for component in ("static_absorption", "dynamic_h2o")
            for ig in eachindex(sw_indices)
                for (iband, band) in enumerate(bands)
                    for step in steps
                        for direction in (-1.0, 1.0)
                            move = (
                                component = component,
                                local_gpoint_index = ig,
                                gpoint = sw_indices[ig],
                                band = iband,
                                pressure_index_start = first(band),
                                pressure_index_end = last(band),
                                log_scale = direction * step,
                                scale = exp(direction * step),
                            )
                            candidate_moves = vcat(moves, [move])
                            metric_objective = pressure_band_table_metric_objective(
                                full_model,
                                parameters,
                                candidate_moves,
                                breakdown.worst_case,
                                breakdown.worst_metric;
                                sw_indices,
                            )
                            full_objective = pressure_band_table_full_objective(
                                full_model,
                                parameters,
                                candidate_moves;
                                sw_indices,
                            )
                            push!(rows, (
                                move...,
                                metric_objective = metric_objective,
                                metric_improvement =
                                    current_metric_objective - metric_objective,
                                full_objective = full_objective,
                                full_improvement =
                                    current_full_objective - full_objective,
                                accepted = full_objective < current_full_objective,
                            ))
                            candidate_count += 1
                            if candidate_count >= max_candidates
                                stop = true
                                break
                            end
                        end
                        stop && break
                    end
                    stop && break
                end
                stop && break
            end
            stop && break
        end

        best_full = argmin(row -> row.full_objective, rows)
        accepted = best_full.full_objective < current_full_objective
        accepted_move = accepted ? (
            component = best_full.component,
            local_gpoint_index = best_full.local_gpoint_index,
            gpoint = best_full.gpoint,
            band = best_full.band,
            pressure_index_start = best_full.pressure_index_start,
            pressure_index_end = best_full.pressure_index_end,
            log_scale = best_full.log_scale,
            scale = best_full.scale,
        ) : nothing
        push!(trajectory, (
            iteration = iteration,
            candidate_count = length(rows),
            initial_full_objective = current_full_objective,
            best_full_objective = best_full.full_objective,
            best_metric_objective = minimum(row -> row.metric_objective, rows),
            accepted = accepted,
            accepted_move = accepted_move,
        ))
        accepted || break
        push!(moves, accepted_move)
        current_full_objective = best_full.full_objective
    end

    final_model =
        pressure_band_table_moved_model(full_model, parameters, moves; sw_indices)
    refined_breakdown = final_objective_breakdown_from_model(
        final_model;
        sw_indices,
        method = "component pressure-band table refinement hard-gate breakdown",
    )
    return (
        method = "iterative component pressure-band nonnegative shortwave table refinement",
        iterations_requested = iterations,
        iterations_completed = length(trajectory),
        max_candidates_per_iteration = max_candidates,
        initial_full_objective = initial_full_objective,
        final_objective = current_full_objective,
        objective_reduction = initial_full_objective - current_full_objective,
        improved = current_full_objective < initial_full_objective,
        accepted_move_count = length(moves),
        accepted_moves = moves,
        trajectory = trajectory,
        refined_breakdown = refined_breakdown,
    )
end

function active_table_entry_refinement_candidate_limit()
    return parse(Int, get(ENV, "RH_REDUCED_ACTIVE_TABLE_ENTRY_CANDIDATES", "96"))
end

function active_table_entry_refinement_iterations()
    return parse(Int, get(ENV, "RH_REDUCED_ACTIVE_TABLE_ENTRY_ITERATIONS", "2"))
end

function active_table_entry_progress_interval()
    return parse(Int, get(ENV, "RH_REDUCED_ACTIVE_TABLE_ENTRY_PROGRESS", "0"))
end

function active_table_entry_max_seconds()
    return parse(Float64, get(ENV, "RH_REDUCED_ACTIVE_TABLE_ENTRY_MAX_SECONDS", "0"))
end

function active_table_entry_targeted_candidates_enabled()
    return get(ENV, "RH_REDUCED_ACTIVE_TABLE_ENTRY_TARGETED", "true") == "true"
end

function active_entry_bracket(grid, x)
    x <= grid[begin] && return firstindex(grid), firstindex(grid) + 1, 0.0
    last = lastindex(grid)
    x >= grid[last] && return last - 1, last, 1.0

    lo = firstindex(grid)
    hi = last
    while hi - lo > 1
        mid = (lo + hi) >>> 1
        if x < grid[mid]
            hi = mid
        else
            lo = mid
        end
    end
    weight = (x - grid[lo]) / (grid[hi] - grid[lo])
    return lo, hi, Float64(weight)
end

function active_entry_log_bracket(grid, x)
    x_positive = max(x, grid[begin])
    index = 1.0 + clamp((log(x_positive) - log(grid[begin])) /
                        (log(grid[begin + 1]) - log(grid[begin])),
                        0.0,
                        Float64(length(grid)) - 1.0001)
    lo = Int(floor(index))
    return lo, lo + 1, index - lo
end

function active_entry_pressure_bracket(pressure_grid, pressure)
    return active_entry_log_bracket(pressure_grid, pressure)
end

function active_entry_temperature_corners(model, pressure, temperature, ip0, ip1, wp)
    temperature_grid = model.temperature_grid
    if temperature_grid isa AbstractMatrix
        temperature_origin = (1.0 - wp) * temperature_grid[ip0, 1] +
                             wp * temperature_grid[ip1, 1]
        temperature_step = temperature_grid[1, 2] - temperature_grid[1, 1]
        temperature_index = 1.0 + clamp((temperature - temperature_origin) /
                                        temperature_step,
                                        0.0,
                                        Float64(size(temperature_grid, 2)) - 1.0001)
        it0 = Int(floor(temperature_index))
        return it0, it0 + 1, temperature_index - it0
    end
    return active_entry_bracket(temperature_grid, temperature)
end

function active_entry_candidate_push!(scores, key, priority)
    scores[key] = get(scores, key, 0.0) + priority
    return scores
end

function active_entry_static_amount(gases, gas_names, references, gas_index, k, column)
    name = gas_names[gas_index]
    amount = haskey(gases, name) ? gases[name][k, column] : 0.0
    if haskey(gases, :composite)
        amount -= references[gas_index] * gases[:composite][k, column]
    end
    return Float64(amount)
end

function targeted_active_table_entry_candidates(full_model, pressure_moves,
                                                case_name;
                                                sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    isempty(pressure_moves) && return NamedTuple[]
    case = reduced_case_by_name(case_name)
    nc = require_ncdatasets()
    scores = Dict{Tuple, Float64}()
    nc.NCDataset(reference_path(case.path)) do dataset
        pressure_layers = Array(dataset["pressure_layer"])
        pressure_interfaces = Array(dataset["pressure_interface"])
        temperature_layers = Array(dataset["temperature_layer"])
        gas_amounts = gas_column_amounts(dataset, pressure_interfaces).amounts
        gases = Dict(Symbol(name) => values for (name, values) in gas_amounts)
        gas_names_tuple = NumericalRadiation.gas_names(full_model)
        references = full_model.gas_reference_mole_fractions
        nlayers, ncolumns = size(pressure_layers)

        for pressure_move in pressure_moves
            ig = pressure_move.local_gpoint_index
            pressure_range =
                pressure_move.pressure_index_start:pressure_move.pressure_index_end
            for column in 1:ncolumns, k in 1:nlayers
                pressure = pressure_layers[k, column]
                temperature = temperature_layers[k, column]
                ip0, ip1, wp =
                    active_entry_pressure_bracket(full_model.pressure_grid, pressure)
                it0, it1, wt =
                    active_entry_temperature_corners(full_model, pressure,
                                                     temperature, ip0, ip1, wp)
                pressure_corners = ((ip0, 1.0 - wp), (ip1, wp))
                temperature_corners = ((it0, 1.0 - wt), (it1, wt))

                if pressure_move.component == "static_absorption"
                    for (pressure_index, pressure_weight) in pressure_corners
                        pressure_index in pressure_range || continue
                        for (temperature_index, temperature_weight) in temperature_corners
                            interpolation_weight = pressure_weight * temperature_weight
                            interpolation_weight <= 0 && continue
                            for gas_index in axes(full_model.shortwave_absorption, 2)
                                amount = active_entry_static_amount(
                                    gases,
                                    gas_names_tuple,
                                    references,
                                    gas_index,
                                    k,
                                    column,
                                )
                                priority = abs(amount) * interpolation_weight
                                priority <= 0 && continue
                                key = ("static_absorption", ig, pressure_move.gpoint,
                                       gas_index, pressure_index, temperature_index, 0)
                                active_entry_candidate_push!(scores, key, priority)
                            end
                        end
                    end
                elseif pressure_move.component == "dynamic_h2o" &&
                       length(full_model.shortwave_h2o_absorption) != 0 &&
                       haskey(gases, :h2o)
                    for (pressure_index, pressure_weight) in pressure_corners
                        pressure_index in pressure_range || continue
                        h2o_moles = max(gases[:h2o][k, column], 0.0)
                        dry_air_moles = haskey(gases, :composite) ?
                            max(gases[:composite][k, column], sqrt(eps(Float64))) :
                            max((pressure_interfaces[k + 1, column] -
                                 pressure_interfaces[k, column]) /
                                (9.80665 * 0.0289647), sqrt(eps(Float64)))
                        h2o_mole_fraction = h2o_moles / dry_air_moles
                        ih0, ih1, wh = active_entry_log_bracket(
                            full_model.h2o_mole_fraction_grid,
                            h2o_mole_fraction,
                        )
                        for (temperature_index, temperature_weight) in temperature_corners
                            for (h2o_index, h2o_weight) in ((ih0, 1.0 - wh), (ih1, wh))
                                interpolation_weight =
                                    pressure_weight * temperature_weight * h2o_weight
                                interpolation_weight <= 0 && continue
                                priority = h2o_moles * interpolation_weight
                                priority <= 0 && continue
                                key = ("dynamic_h2o", ig, pressure_move.gpoint, 0,
                                       pressure_index, temperature_index, h2o_index)
                                active_entry_candidate_push!(scores, key, priority)
                            end
                        end
                    end
                end
            end
        end
    end

    ranked = collect(scores)
    sort!(ranked; by = pair -> -pair.second)
    return [
        (
            component = key[1],
            local_gpoint_index = key[2],
            gpoint = key[3],
            gas_index = key[4],
            pressure_index = key[5],
            temperature_index = key[6],
            h2o_index = key[7],
            priority = priority,
        )
        for (key, priority) in ranked
    ]
end

function active_table_entry_refinement(full_model, parameters, breakdown,
                                       pressure_refinement;
                                       sw_indices = WEIGHTED_GREEDY_SW_16_INDICES,
                                       steps = (0.0625, 0.125),
                                       max_candidates =
                                           active_table_entry_refinement_candidate_limit(),
                                       iterations =
                                           active_table_entry_refinement_iterations(),
                                       progress_interval =
                                           active_table_entry_progress_interval(),
                                       max_seconds =
                                           active_table_entry_max_seconds())
    pressure_moves = pressure_refinement.accepted_moves
    if isempty(pressure_moves)
        initial_objective = reduced_objective(full_model, parameters; sw_indices)
        return (
            method = "active coefficient-table entry refinement after accepted pressure-band moves",
            iterations_requested = iterations,
            iterations_completed = 0,
            max_candidates_per_iteration = max_candidates,
            initial_full_objective = initial_objective,
            final_objective = initial_objective,
            objective_reduction = 0.0,
            improved = false,
            accepted_move_count = 0,
            accepted_moves = NamedTuple[],
            trajectory = NamedTuple[],
        )
    end

    active_moves = NamedTuple[]
    initial_full_objective = pressure_band_active_table_full_objective(
        full_model,
        parameters,
        pressure_moves,
        active_moves;
        sw_indices,
    )
    current_full_objective = initial_full_objective
    trajectory = NamedTuple[]
    start_time = time()
    time_limited = false
    targeted_candidates = active_table_entry_targeted_candidates_enabled() ?
        targeted_active_table_entry_candidates(
            full_model,
            pressure_moves,
            breakdown.worst_case;
            sw_indices,
        ) : NamedTuple[]

    for iteration in 1:iterations
        current_metric_objective = pressure_band_active_table_metric_objective(
            full_model,
            parameters,
            pressure_moves,
            active_moves,
            breakdown.worst_case,
            breakdown.worst_metric;
            sw_indices,
        )
        rows = NamedTuple[]
        candidate_count = 0
        stop = false
        if !isempty(targeted_candidates)
            for base_move in targeted_candidates
                for step in steps
                    for direction in (-1.0, 1.0)
                        move = (
                            component = base_move.component,
                            local_gpoint_index = base_move.local_gpoint_index,
                            gpoint = base_move.gpoint,
                            gas_index = base_move.gas_index,
                            pressure_index = base_move.pressure_index,
                            temperature_index = base_move.temperature_index,
                            h2o_index = base_move.h2o_index,
                            log_scale = direction * step,
                            scale = exp(direction * step),
                            priority = base_move.priority,
                        )
                        candidate_moves = vcat(active_moves, [move])
                        metric_objective =
                            pressure_band_active_table_metric_objective(
                                full_model,
                                parameters,
                                pressure_moves,
                                candidate_moves,
                                breakdown.worst_case,
                                breakdown.worst_metric;
                                sw_indices,
                            )
                        full_objective =
                            pressure_band_active_table_full_objective(
                                full_model,
                                parameters,
                                pressure_moves,
                                candidate_moves;
                                sw_indices,
                            )
                        push!(rows, (
                            move...,
                            metric_objective = metric_objective,
                            metric_improvement =
                                current_metric_objective - metric_objective,
                            full_objective = full_objective,
                            full_improvement =
                                current_full_objective - full_objective,
                            accepted = full_objective < current_full_objective,
                        ))
                        candidate_count += 1
                        if progress_interval > 0 && candidate_count % progress_interval == 0
                            @printf("active table-entry iteration %d evaluated %d candidates; current best %.12g\n",
                                    iteration, candidate_count,
                                    minimum(row -> row.full_objective, rows))
                            flush(stdout)
                        end
                        if max_seconds > 0 && time() - start_time >= max_seconds
                            time_limited = true
                            stop = true
                            break
                        end
                        if candidate_count >= max_candidates
                            stop = true
                            break
                        end
                    end
                    stop && break
                end
                stop && break
            end
        else
            for pressure_move in pressure_moves
            component = pressure_move.component
            ig = pressure_move.local_gpoint_index
            pressure_indices =
                pressure_move.pressure_index_start:pressure_move.pressure_index_end
            if component == "static_absorption"
                for gas_index in axes(full_model.shortwave_absorption, 2)
                    for pressure_index in pressure_indices
                        for temperature_index in axes(full_model.shortwave_absorption, 4)
                            for step in steps
                                for direction in (-1.0, 1.0)
                                    move = (
                                        component = component,
                                        local_gpoint_index = ig,
                                        gpoint = pressure_move.gpoint,
                                        gas_index = gas_index,
                                        pressure_index = pressure_index,
                                        temperature_index = temperature_index,
                                        h2o_index = 0,
                                        log_scale = direction * step,
                                        scale = exp(direction * step),
                                    )
                                    candidate_moves = vcat(active_moves, [move])
                                    metric_objective =
                                        pressure_band_active_table_metric_objective(
                                            full_model,
                                            parameters,
                                            pressure_moves,
                                            candidate_moves,
                                            breakdown.worst_case,
                                            breakdown.worst_metric;
                                            sw_indices,
                                        )
                                    full_objective =
                                        pressure_band_active_table_full_objective(
                                            full_model,
                                            parameters,
                                            pressure_moves,
                                            candidate_moves;
                                            sw_indices,
                                        )
                                    push!(rows, (
                                        move...,
                                        metric_objective = metric_objective,
                                        metric_improvement =
                                            current_metric_objective - metric_objective,
                                        full_objective = full_objective,
                                        full_improvement =
                                            current_full_objective - full_objective,
                                        accepted = full_objective < current_full_objective,
                                    ))
                                    candidate_count += 1
                                    if progress_interval > 0 && candidate_count % progress_interval == 0
                                        @printf("active table-entry iteration %d evaluated %d candidates; current best %.12g\n",
                                                iteration, candidate_count,
                                                minimum(row -> row.full_objective, rows))
                                        flush(stdout)
                                    end
                                    if max_seconds > 0 && time() - start_time >= max_seconds
                                        time_limited = true
                                        stop = true
                                        break
                                    end
                                    if candidate_count >= max_candidates
                                        stop = true
                                        break
                                    end
                                end
                                stop && break
                            end
                            stop && break
                        end
                        stop && break
                    end
                    stop && break
                end
            elseif component == "dynamic_h2o" &&
                   length(full_model.shortwave_h2o_absorption) != 0
                for pressure_index in pressure_indices
                    for temperature_index in axes(full_model.shortwave_h2o_absorption, 3)
                        for h2o_index in axes(full_model.shortwave_h2o_absorption, 4)
                            for step in steps
                                for direction in (-1.0, 1.0)
                                    move = (
                                        component = component,
                                        local_gpoint_index = ig,
                                        gpoint = pressure_move.gpoint,
                                        gas_index = 0,
                                        pressure_index = pressure_index,
                                        temperature_index = temperature_index,
                                        h2o_index = h2o_index,
                                        log_scale = direction * step,
                                        scale = exp(direction * step),
                                    )
                                    candidate_moves = vcat(active_moves, [move])
                                    metric_objective =
                                        pressure_band_active_table_metric_objective(
                                            full_model,
                                            parameters,
                                            pressure_moves,
                                            candidate_moves,
                                            breakdown.worst_case,
                                            breakdown.worst_metric;
                                            sw_indices,
                                        )
                                    full_objective =
                                        pressure_band_active_table_full_objective(
                                            full_model,
                                            parameters,
                                            pressure_moves,
                                            candidate_moves;
                                            sw_indices,
                                        )
                                    push!(rows, (
                                        move...,
                                        metric_objective = metric_objective,
                                        metric_improvement =
                                            current_metric_objective - metric_objective,
                                        full_objective = full_objective,
                                        full_improvement =
                                            current_full_objective - full_objective,
                                        accepted = full_objective < current_full_objective,
                                    ))
                                    candidate_count += 1
                                    if progress_interval > 0 && candidate_count % progress_interval == 0
                                        @printf("active table-entry iteration %d evaluated %d candidates; current best %.12g\n",
                                                iteration, candidate_count,
                                                minimum(row -> row.full_objective, rows))
                                        flush(stdout)
                                    end
                                    if max_seconds > 0 && time() - start_time >= max_seconds
                                        time_limited = true
                                        stop = true
                                        break
                                    end
                                    if candidate_count >= max_candidates
                                        stop = true
                                        break
                                    end
                                end
                                stop && break
                            end
                            stop && break
                        end
                        stop && break
                    end
                end
            end
            stop && break
            end
        end

        if isempty(rows)
            push!(trajectory, (
                iteration = iteration,
                candidate_count = 0,
                initial_full_objective = current_full_objective,
                best_full_objective = current_full_objective,
                best_metric_objective = current_metric_objective,
                accepted = false,
                accepted_move = nothing,
            ))
            break
        end

        best_full = argmin(row -> row.full_objective, rows)
        accepted = best_full.full_objective < current_full_objective
        accepted_move = accepted ? (
            component = best_full.component,
            local_gpoint_index = best_full.local_gpoint_index,
            gpoint = best_full.gpoint,
            gas_index = best_full.gas_index,
            pressure_index = best_full.pressure_index,
            temperature_index = best_full.temperature_index,
            h2o_index = best_full.h2o_index,
            log_scale = best_full.log_scale,
            scale = best_full.scale,
        ) : nothing
        push!(trajectory, (
            iteration = iteration,
            candidate_count = length(rows),
            initial_full_objective = current_full_objective,
            best_full_objective = best_full.full_objective,
            best_metric_objective = minimum(row -> row.metric_objective, rows),
            accepted = accepted,
            accepted_move = accepted_move,
        ))
        accepted || break
        push!(active_moves, accepted_move)
        current_full_objective = best_full.full_objective
        time_limited && break
    end

    return (
        method = "active coefficient-table entry refinement after accepted pressure-band moves",
        iterations_requested = iterations,
        iterations_completed = length(trajectory),
        max_candidates_per_iteration = max_candidates,
        progress_interval = progress_interval,
        max_seconds = max_seconds,
        time_limited = time_limited,
        targeted_candidates_enabled = !isempty(targeted_candidates),
        targeted_candidate_count = length(targeted_candidates),
        initial_full_objective = initial_full_objective,
        final_objective = current_full_objective,
        objective_reduction = initial_full_objective - current_full_objective,
        improved = current_full_objective < initial_full_objective,
        accepted_move_count = length(active_moves),
        accepted_moves = active_moves,
        trajectory = trajectory,
    )
end

function unique_topology_key(indices)
    return join(indices, ",")
end

function neighbor_topology_candidates(base_indices = WEIGHTED_GREEDY_SW_16_INDICES;
                                      radius = 1)
    candidates = NamedTuple[]
    seen = Set{String}()
    for local_index in eachindex(base_indices)
        old_gpoint = base_indices[local_index]
        for delta in -radius:radius
            delta == 0 && continue
            new_gpoint = old_gpoint + delta
            1 <= new_gpoint <= 32 || continue
            new_gpoint in base_indices && continue
            candidate = collect(base_indices)
            candidate[local_index] = new_gpoint
            length(unique(candidate)) == length(candidate) || continue
            key = unique_topology_key(candidate)
            key in seen && continue
            push!(seen, key)
            push!(candidates, (
                local_index = local_index,
                removed_gpoint = old_gpoint,
                added_gpoint = new_gpoint,
                indices = candidate,
            ))
        end
    end
    return candidates
end

function topology_neighbor_scan(full_model, parameters;
                                base_indices = WEIGHTED_GREEDY_SW_16_INDICES,
                                radius = 1,
                                max_candidates = 8)
    base_objective = reduced_objective(full_model, parameters; sw_indices = base_indices)
    all_candidates = neighbor_topology_candidates(base_indices; radius = radius)
    rows = NamedTuple[]
    for candidate in Iterators.take(all_candidates, max_candidates)
        objective = reduced_objective(full_model, parameters; sw_indices = candidate.indices)
        push!(rows, (
            local_index = candidate.local_index,
            removed_gpoint = candidate.removed_gpoint,
            added_gpoint = candidate.added_gpoint,
            indices = candidate.indices,
            objective = objective,
            improvement = base_objective - objective,
            improved = objective < base_objective,
        ))
    end

    best = isempty(rows) ? nothing : argmin(row -> row.objective, rows)
    return (
        method = "single-neighbor topology replacement around optimized 48-parameter state",
        base_indices = collect(base_indices),
        radius = radius,
        max_candidates = max_candidates,
        candidate_count = length(rows),
        total_candidate_count = length(all_candidates),
        base_objective = base_objective,
        best_local_index = best === nothing ? nothing : best.local_index,
        best_removed_gpoint = best === nothing ? nothing : best.removed_gpoint,
        best_added_gpoint = best === nothing ? nothing : best.added_gpoint,
        best_indices = best === nothing ? Int[] : best.indices,
        best_objective = best === nothing ? base_objective : best.objective,
        best_improvement = best === nothing ? 0.0 : best.improvement,
        improved = best !== nothing && best.objective < base_objective,
        rows = rows,
    )
end

function topology_refinement_candidate_limit()
    return parse(Int, get(ENV, "RH_REDUCED_TOPOLOGY_REFINEMENT_CANDIDATES", "2"))
end

function topology_refinement_radius()
    return parse(Int, get(ENV, "RH_REDUCED_TOPOLOGY_REFINEMENT_RADIUS", "1"))
end

function topology_refinement_iterations()
    return parse(Int, get(ENV, "RH_REDUCED_TOPOLOGY_REFINEMENT_ITERATIONS", "1"))
end

function warm_started_topology_neighbor_refinement(full_model, parameters;
                                                   base_indices = WEIGHTED_GREEDY_SW_16_INDICES,
                                                   radius = topology_refinement_radius(),
                                                   max_candidates = topology_refinement_candidate_limit(),
                                                   iterations = topology_refinement_iterations())
    base_objective = reduced_objective(full_model, parameters; sw_indices = base_indices)
    all_candidates = neighbor_topology_candidates(base_indices; radius = radius)
    rows = NamedTuple[]
    best_parameters = copy(parameters)
    best_indices = collect(base_indices)
    best_objective = base_objective

    for candidate in Iterators.take(all_candidates, max_candidates)
        f_candidate(x) = reduced_objective(full_model, x; sw_indices = candidate.indices)
        initial_objective = f_candidate(parameters)
        refinement = post_joint_coordinate_refinement(
            f_candidate,
            parameters;
            iterations = iterations,
            steps = (0.125, 0.25),
        )
        improved = refinement.final_objective < base_objective
        push!(rows, (
            local_index = candidate.local_index,
            removed_gpoint = candidate.removed_gpoint,
            added_gpoint = candidate.added_gpoint,
            indices = candidate.indices,
            initial_objective = initial_objective,
            refined_objective = refinement.final_objective,
            refinement_iterations = refinement.iterations_completed,
            improvement = base_objective - refinement.final_objective,
            improved = improved,
        ))
        if refinement.final_objective < best_objective
            best_objective = refinement.final_objective
            best_parameters .= refinement.final_parameters
            best_indices = collect(candidate.indices)
        end
    end

    best = isempty(rows) ? nothing : argmin(row -> row.refined_objective, rows)
    return (
        method = "warm-started single-neighbor topology replacement with bounded coefficient refit",
        base_indices = collect(base_indices),
        radius = radius,
        max_candidates = max_candidates,
        candidate_count = length(rows),
        total_candidate_count = length(all_candidates),
        refinement_iterations = iterations,
        base_objective = base_objective,
        best_local_index = best === nothing ? nothing : best.local_index,
        best_removed_gpoint = best === nothing ? nothing : best.removed_gpoint,
        best_added_gpoint = best === nothing ? nothing : best.added_gpoint,
        best_indices = best_indices,
        best_objective = best_objective,
        best_improvement = base_objective - best_objective,
        improved = best_objective < base_objective,
        final_parameters = collect(best_parameters),
        rows = rows,
    )
end

function ranked_topology_refinement_candidate_limit()
    return parse(Int, get(ENV, "RH_REDUCED_RANKED_TOPOLOGY_REFINEMENT_CANDIDATES", "4"))
end

function ranked_topology_neighbor_refinement(full_model, parameters;
                                             base_indices = WEIGHTED_GREEDY_SW_16_INDICES,
                                             radius = topology_refinement_radius(),
                                             max_candidates =
                                                ranked_topology_refinement_candidate_limit(),
                                             iterations = topology_refinement_iterations())
    base_objective = reduced_objective(full_model, parameters; sw_indices = base_indices)
    all_candidates = neighbor_topology_candidates(base_indices; radius = radius)
    ranked_candidates = NamedTuple[]
    for candidate in all_candidates
        objective = reduced_objective(full_model, parameters; sw_indices = candidate.indices)
        push!(ranked_candidates, (
            candidate...,
            initial_objective = objective,
            initial_improvement = base_objective - objective,
        ))
    end
    sort!(ranked_candidates; by = candidate -> candidate.initial_objective)

    rows = NamedTuple[]
    best_parameters = copy(parameters)
    best_indices = collect(base_indices)
    best_objective = base_objective
    for candidate in Iterators.take(ranked_candidates, max_candidates)
        f_candidate(x) = reduced_objective(full_model, x; sw_indices = candidate.indices)
        refinement = post_joint_coordinate_refinement(
            f_candidate,
            parameters;
            iterations = iterations,
            steps = (0.125, 0.25),
        )
        improved = refinement.final_objective < base_objective
        push!(rows, (
            local_index = candidate.local_index,
            removed_gpoint = candidate.removed_gpoint,
            added_gpoint = candidate.added_gpoint,
            indices = candidate.indices,
            initial_objective = candidate.initial_objective,
            refined_objective = refinement.final_objective,
            refinement_iterations = refinement.iterations_completed,
            improvement = base_objective - refinement.final_objective,
            improved = improved,
        ))
        if refinement.final_objective < best_objective
            best_objective = refinement.final_objective
            best_parameters .= refinement.final_parameters
            best_indices = collect(candidate.indices)
        end
    end

    best = isempty(rows) ? nothing : argmin(row -> row.refined_objective, rows)
    return (
        method = "ranked warm-started topology replacement with bounded coefficient refit",
        base_indices = collect(base_indices),
        radius = radius,
        max_candidates = max_candidates,
        candidate_count = length(rows),
        total_candidate_count = length(all_candidates),
        ranked_candidate_count = length(ranked_candidates),
        refinement_iterations = iterations,
        base_objective = base_objective,
        best_local_index = best === nothing ? nothing : best.local_index,
        best_removed_gpoint = best === nothing ? nothing : best.removed_gpoint,
        best_added_gpoint = best === nothing ? nothing : best.added_gpoint,
        best_indices = best_indices,
        best_initial_objective = best === nothing ? base_objective : best.initial_objective,
        best_objective = best_objective,
        best_improvement = base_objective - best_objective,
        improved = best_objective < base_objective,
        final_parameters = collect(best_parameters),
        rows = rows,
    )
end

function first_regex_capture(text, pattern)
    match = Base.match(pattern, text)
    return match === nothing ? nothing : match.captures[1]
end

function parse_json_bool(text, key)
    value = first_regex_capture(text, Regex("\"$key\"\\s*:\\s*(true|false)"))
    value === nothing && return nothing
    return value == "true"
end

function parse_json_int(text, key)
    value = first_regex_capture(text, Regex("\"$key\"\\s*:\\s*([0-9]+)"))
    value === nothing && return nothing
    return parse(Int, value)
end

function parse_json_string(text, key)
    return first_regex_capture(text, Regex("\"$key\"\\s*:\\s*\"([^\"]+)\""))
end

function json_object_section(text, key)
    marker = "\"$key\": {"
    start = findfirst(marker, text)
    start === nothing && return ""
    section_start = last(start) + 1
    depth = 1
    for i in section_start:lastindex(text)
        char = text[i]
        if char == '{'
            depth += 1
        elseif char == '}'
            depth -= 1
            depth == 0 && return text[section_start:i - 1]
        end
    end
    return ""
end

function json_numbers(text, key)
    return [
        parse(Float64, match.captures[1])
        for match in eachmatch(Regex("\"$key\"\\s*:\\s*([-+0-9.eE]+)"), text)
    ]
end

function reduced_accuracy_model_chunks(text)
    marker = "\n}, {\n  \"ng_lw\""
    raw_chunks = split(text, marker)
    chunks = String[]
    for (i, chunk) in enumerate(raw_chunks)
        model_text = i == 1 ? chunk : "\"ng_lw\"" * chunk
        occursin("\"reduction_method\"", model_text) && push!(chunks, model_text)
    end
    return chunks
end

function reduced_accuracy_topology_scan(path = REDUCED_ACCURACY_JSON)
    isfile(path) || return (
        status = "artifact_missing",
        source = path,
        candidate_count = 0,
        rows = NamedTuple[],
        best_method = nothing,
        best_forcing_objective_lower_bound = nothing,
        best_passed_hard_thresholds = false,
    )

    rows = NamedTuple[]
    for chunk in reduced_accuracy_model_chunks(read(path, String))
        ng_lw = parse_json_int(chunk, "ng_lw")
        ng_sw = parse_json_int(chunk, "ng_sw")
        method = parse_json_string(chunk, "reduction_method")
        passed = parse_json_bool(chunk, "passed_hard_thresholds")
        toa = json_numbers(chunk, "toa_forcing_max_abs")
        surface = json_numbers(chunk, "surface_forcing_max_abs")
        if ng_lw == 32 && ng_sw == 16 && method !== nothing && !isempty(toa) && !isempty(surface)
            forcing_objective = max(maximum(toa) / ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
                                    maximum(surface) / ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2)
            push!(rows, (
                ng_lw = ng_lw,
                ng_sw = ng_sw,
                reduction_method = method,
                passed_hard_thresholds = something(passed, false),
                max_toa_forcing_abs = maximum(toa),
                max_surface_forcing_abs = maximum(surface),
                forcing_objective_lower_bound = forcing_objective,
            ))
        end
    end

    isempty(rows) && return (
        status = "no_32x16_candidates_found",
        source = path,
        candidate_count = 0,
        rows = rows,
        best_method = nothing,
        best_forcing_objective_lower_bound = nothing,
        best_passed_hard_thresholds = false,
    )

    best = argmin(row -> row.forcing_objective_lower_bound, rows)
    return (
        status = any(row -> row.passed_hard_thresholds, rows) ?
            "contains_passing_topology" : "all_32x16_topologies_fail_forcing_gate",
        source = path,
        candidate_count = length(rows),
        rows = rows,
        best_method = best.reduction_method,
        best_forcing_objective_lower_bound = best.forcing_objective_lower_bound,
        best_passed_hard_thresholds = best.passed_hard_thresholds,
    )
end

function subset_search_topology_scan(path = REDUCED_SUBSET_SEARCH_JSON)
    isfile(path) || return (
        status = "artifact_missing",
        source = path,
        candidate_count = 0,
        rows = NamedTuple[],
        best_method = nothing,
        best_forcing_objective_lower_bound = nothing,
        best_passed_hard_thresholds = false,
    )

    text = read(path, String)
    rows = NamedTuple[]
    for (key, method) in (
            ("best_subset", "heating-aware greedy subset with official weights"),
            ("best_weighted_subset", "heating-aware weighted subset with fitted weights"),
            ("best_pruned_full_fit_subset", "heating-aware full-fit-pruned subset with fitted weights"),
            ("best_hardgate_weighted_subset", "heating-aware hard-gate max-norm weighted subset"),
        )
        section = json_object_section(text, key)
        section == "" && continue
        passed = parse_json_bool(section, "passed_hard_thresholds")
        toa = json_numbers(section, "toa_forcing_max_abs")
        surface = json_numbers(section, "surface_forcing_max_abs")
        if !isempty(toa) && !isempty(surface)
            forcing_objective = max(maximum(toa) / ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
                                    maximum(surface) / ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2)
            push!(rows, (
                ng_lw = 32,
                ng_sw = 16,
                reduction_method = method,
                passed_hard_thresholds = something(passed, false),
                max_toa_forcing_abs = maximum(toa),
                max_surface_forcing_abs = maximum(surface),
                forcing_objective_lower_bound = forcing_objective,
            ))
        end
    end

    isempty(rows) && return (
        status = "no_subset_candidates_found",
        source = path,
        candidate_count = 0,
        rows = rows,
        best_method = nothing,
        best_forcing_objective_lower_bound = nothing,
        best_passed_hard_thresholds = false,
    )

    best = argmin(row -> row.forcing_objective_lower_bound, rows)
    return (
        status = any(row -> row.passed_hard_thresholds, rows) ?
            "contains_passing_topology" : "all_subset_topologies_fail_forcing_gate",
        source = path,
        candidate_count = length(rows),
        rows = rows,
        best_method = best.reduction_method,
        best_forcing_objective_lower_bound = best.forcing_objective_lower_bound,
        best_passed_hard_thresholds = best.passed_hard_thresholds,
    )
end

function json_escape(text)
    return replace(text, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")
end

function json_value(value)
    if value === nothing
        return "null"
    elseif value isa AbstractString
        return "\"" * json_escape(value) * "\""
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value isa NamedTuple
        return json_object(value)
    elseif value isa AbstractVector || value isa Tuple
        return "[" * join(json_value.(value), ", ") * "]"
    else
        return string(value)
    end
end

function json_object(object)
    names = propertynames(object)
    lines = ["{"]
    for (i, name) in enumerate(names)
        comma = i == length(names) ? "" : ","
        push!(lines, "  \"$(name)\": $(json_value(getproperty(object, name)))$(comma)")
    end
    push!(lines, "}")
    return join(lines, "\n")
end

function markdown_report(result)
    lines = String[
        "# Reduced ecCKD Optimization Preflight",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Trainable shortwave g-points | $(result.ng_sw) |",
        "| Parameter count | $(result.parameter_count) |",
        "| Initial normalized objective | $(@sprintf("%.12g", result.initial_objective)) |",
        "| Directional derivative | $(@sprintf("%.12g", result.directional_derivative)) |",
        "| Best trial objective | $(@sprintf("%.12g", result.best_trial_objective)) |",
        "| Best trial step | $(@sprintf("%.4g", result.best_trial_step)) |",
        "| Optimization smoke final objective | $(@sprintf("%.12g", result.optimization_smoke.final_objective)) |",
        "| Optimization smoke reduction | $(@sprintf("%.12g", result.optimization_smoke.objective_reduction)) |",
        "| Directional search final objective | $(@sprintf("%.12g", result.directional_search.final_objective)) |",
        "| Directional search reduction | $(@sprintf("%.12g", result.directional_search.objective_reduction)) |",
        "| Best parameter block | $(result.block_trial_scan.best_block) |",
        "| Best block trial objective | $(@sprintf("%.12g", result.block_trial_scan.best_objective)) |",
        "| Coefficient coordinate candidates | $(result.coordinate_coefficient_scan.candidate_count) |",
        "| Best coefficient coordinate | $(result.coordinate_coefficient_scan.best_block) g$(result.coordinate_coefficient_scan.best_gpoint) $(result.coordinate_coefficient_scan.best_direction) step $(result.coordinate_coefficient_scan.best_step) |",
        "| Best coefficient coordinate objective | $(@sprintf("%.12g", result.coordinate_coefficient_scan.best_objective)) |",
        "| Greedy coefficient descent iterations | $(result.greedy_coordinate_descent.iterations_completed) |",
        "| Greedy coefficient descent final objective | $(@sprintf("%.12g", result.greedy_coordinate_descent.final_objective)) |",
        "| Greedy coefficient descent source | $(result.greedy_coordinate_descent_checkpoint_used ? "cached checkpoint" : "fresh run") |",
        "| Joint coefficient direction candidates | $(result.coefficient_joint_direction_scan.candidate_count) |",
        "| Best joint coefficient direction | $(result.coefficient_joint_direction_scan.best_direction_name === nothing ? "n/a" : result.coefficient_joint_direction_scan.best_direction_name) |",
        "| Best joint coefficient objective | $(@sprintf("%.12g", result.coefficient_joint_direction_scan.best_objective)) |",
        "| Post-joint refinement iterations | $(result.post_joint_coordinate_refinement.iterations_completed) |",
        "| Post-joint refinement final objective | $(@sprintf("%.12g", result.post_joint_coordinate_refinement.final_objective)) |",
        "| Post-coefficient weight refinement iterations | $(result.post_coefficient_weight_refinement.iterations_completed) |",
        "| Post-coefficient weight refinement final objective | $(@sprintf("%.12g", result.post_coefficient_weight_refinement.final_objective)) |",
        "| Finite-difference coefficient-gradient candidates | $(result.finite_difference_coefficient_direction_refinement.candidate_count) |",
        "| Finite-difference coefficient-gradient norm | $(@sprintf("%.12g", result.finite_difference_coefficient_direction_refinement.gradient_norm)) |",
        "| Finite-difference coefficient-gradient best objective | $(@sprintf("%.12g", result.finite_difference_coefficient_direction_refinement.best_objective)) |",
        "| Finite-difference coefficient-gradient improved | $(result.finite_difference_coefficient_direction_refinement.improved) |",
        "| Smooth objective beta | $(@sprintf("%.6g", result.smooth_objective_coefficient_refinement.beta)) |",
        "| Smooth objective best smooth value | $(@sprintf("%.12g", result.smooth_objective_coefficient_refinement.best_smooth_objective)) |",
        "| Smooth objective hard candidate | $(@sprintf("%.12g", result.smooth_objective_coefficient_refinement.candidate_hard_objective)) |",
        "| Smooth objective accepted | $(result.smooth_objective_coefficient_refinement.accepted) |",
        "| Topology-neighbor candidates | $(result.topology_neighbor_scan.candidate_count) / $(result.topology_neighbor_scan.total_candidate_count) |",
        "| Best topology-neighbor move | $(result.topology_neighbor_scan.best_removed_gpoint === nothing ? "n/a" : "g$(result.topology_neighbor_scan.best_removed_gpoint) -> g$(result.topology_neighbor_scan.best_added_gpoint)") |",
        "| Best topology-neighbor objective | $(@sprintf("%.12g", result.topology_neighbor_scan.best_objective)) |",
        "| Topology scan status | $(result.topology_candidate_scan.status) |",
        "| Topology candidates | $(result.topology_candidate_scan.candidate_count) |",
        "| Best topology forcing lower bound | $(result.topology_candidate_scan.best_forcing_objective_lower_bound === nothing ? "n/a" : @sprintf("%.12g", result.topology_candidate_scan.best_forcing_objective_lower_bound)) |",
        "| Subset-search scan status | $(result.subset_search_topology_scan.status) |",
        "| Subset-search candidates | $(result.subset_search_topology_scan.candidate_count) |",
        "| Best subset-search forcing lower bound | $(result.subset_search_topology_scan.best_forcing_objective_lower_bound === nothing ? "n/a" : @sprintf("%.12g", result.subset_search_topology_scan.best_forcing_objective_lower_bound)) |",
        "| Hard threshold objective target | $(result.objective_target) |",
        "| Final objective / target | $(@sprintf("%.12g", result.final_objective_target_ratio)) |",
        "| Final worst case | $(result.final_objective_breakdown.worst_case) |",
        "| Final worst metric | $(result.final_objective_breakdown.worst_metric) |",
        "| Final worst metric value | $(@sprintf("%.12g", result.final_objective_breakdown.worst_value)) |",
        "| Final worst metric threshold | $(@sprintf("%.12g", result.final_objective_breakdown.worst_threshold)) |",
        "| Targeted worst-metric candidates | $(result.targeted_worst_metric_refinement.scan.candidate_count) |",
        "| Targeted worst-metric objective | $(@sprintf("%.12g", result.targeted_worst_metric_refinement.target_best_objective)) |",
        "| Targeted full-objective candidate | $(@sprintf("%.12g", result.targeted_worst_metric_refinement.candidate_full_objective)) |",
        "| Targeted move accepted | $(result.targeted_worst_metric_refinement.accepted) |",
        "| Separated-component parameter count | $(result.separated_component_refinement.parameter_count) |",
        "| Separated-component candidates | $(result.separated_component_refinement.scan.candidate_count) |",
        "| Separated-component target objective | $(@sprintf("%.12g", result.separated_component_refinement.target_best_objective)) |",
        "| Separated-component full-objective candidate | $(@sprintf("%.12g", result.separated_component_refinement.candidate_full_objective)) |",
        "| Separated-component move accepted | $(result.separated_component_refinement.accepted) |",
        "| Table-refinement iterations | $(result.pressure_band_table_refinement.iterations_completed) |",
        "| Table-refinement accepted moves | $(result.pressure_band_table_refinement.accepted_move_count) |",
        "| Table-refinement final objective | $(@sprintf("%.12g", result.pressure_band_table_refinement.final_objective)) |",
        "| Table-refinement improved | $(result.pressure_band_table_refinement.improved) |",
        "| Active table-entry iterations | $(result.active_table_entry_refinement.iterations_completed) |",
        "| Active table-entry accepted moves | $(result.active_table_entry_refinement.accepted_move_count) |",
        "| Active table-entry targeted candidates | $(result.active_table_entry_refinement.targeted_candidates_enabled ? result.active_table_entry_refinement.targeted_candidate_count : 0) |",
        "| Active table-entry final objective | $(@sprintf("%.12g", result.active_table_entry_refinement.final_objective)) |",
        "| Active table-entry improved | $(result.active_table_entry_refinement.improved) |",
        "| Next optimizer target case | $(result.constrained_table_optimizer_target.target_case) |",
        "| Next optimizer target metric | $(result.constrained_table_optimizer_target.target_metric) |",
        "| Required absolute reduction | $(@sprintf("%.12g", result.constrained_table_optimizer_target.required_absolute_reduction)) |",
        "| Required relative reduction | $(@sprintf("%.6f", result.constrained_table_optimizer_target.required_relative_reduction)) |",
        "| Warm-start topology radius | $(result.warm_started_topology_neighbor_refinement.radius) |",
        "| Warm-start topology candidates | $(result.warm_started_topology_neighbor_refinement.candidate_count) / $(result.warm_started_topology_neighbor_refinement.total_candidate_count) |",
        "| Warm-start topology best move | $(result.warm_started_topology_neighbor_refinement.best_removed_gpoint === nothing ? "n/a" : "g$(result.warm_started_topology_neighbor_refinement.best_removed_gpoint) -> g$(result.warm_started_topology_neighbor_refinement.best_added_gpoint)") |",
        "| Warm-start topology best objective | $(@sprintf("%.12g", result.warm_started_topology_neighbor_refinement.best_objective)) |",
        "| Warm-start topology improved | $(result.warm_started_topology_neighbor_refinement.improved) |",
        "| Ranked topology radius | $(result.ranked_topology_neighbor_refinement.radius) |",
        "| Ranked topology candidates | $(result.ranked_topology_neighbor_refinement.candidate_count) / $(result.ranked_topology_neighbor_refinement.total_candidate_count) |",
        "| Ranked topology best move | $(result.ranked_topology_neighbor_refinement.best_removed_gpoint === nothing ? "n/a" : "g$(result.ranked_topology_neighbor_refinement.best_removed_gpoint) -> g$(result.ranked_topology_neighbor_refinement.best_added_gpoint)") |",
        "| Ranked topology best initial objective | $(@sprintf("%.12g", result.ranked_topology_neighbor_refinement.best_initial_objective)) |",
        "| Ranked topology best refined objective | $(@sprintf("%.12g", result.ranked_topology_neighbor_refinement.best_objective)) |",
        "| Ranked topology improved | $(result.ranked_topology_neighbor_refinement.improved) |",
        "",
        "The parameterization optimizes 16 shortwave spectral weights, 16 absorption coefficient scales, and 16 Rayleigh coefficient scales on the official ecCKD reduced hard-gate cases.",
        "",
        "The topology scan ranks the existing official 32x16 reduced-accuracy candidates by the forcing-error lower bound implied by their TOA and surface forcing errors. This keeps the next optimizer tied to measured official-case evidence instead of only the current weighted-greedy topology.",
        "",
        "Next required work: $(result.next_required_work)",
        "",
        "Reactant status: `$(result.reactant_status)`",
        "",
        "Reactant surrogate check: `$(result.reactant_check.status)`",
        "",
        "Enzyme status: `$(result.enzyme_status)`",
        "",
        "Enzyme surrogate check: `$(result.enzyme_check.status)`",
    ]
    return join(lines, "\n") * "\n"
end

function reduced_optimization_preflight()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    parameters = initial_parameters()
    direction = PREFLIGHT_DIRECTION
    f(x) = reduced_objective(full_model, x)
    initial_objective = f(parameters)
    derivative = central_directional_derivative(f, parameters, direction)
    line_search = trial_line_search(f, parameters, direction)
    optimization_smoke = optimization_smoke_result(initial_objective, line_search)
    directional_search = deterministic_directional_search(f, parameters, direction)
    block_scan = block_trial_scan(f, parameters)
    coordinate_scan = coordinate_coefficient_scan(f, parameters)
    greedy_descent, greedy_checkpoint_used =
        greedy_coordinate_descent_with_checkpoint(f, parameters, initial_objective)
    joint_scan = coefficient_joint_direction_scan(f, greedy_descent.final_parameters)
    joint_parameters = joint_scan.best_objective < greedy_descent.final_objective ?
        joint_scan.final_parameters : greedy_descent.final_parameters
    post_joint_refinement = post_joint_coordinate_refinement(f, joint_parameters)
    best_parameters = post_joint_refinement.final_objective <
        min(greedy_descent.final_objective, joint_scan.best_objective) ?
        post_joint_refinement.final_parameters : joint_parameters
    weight_refinement = post_coefficient_weight_refinement(f, best_parameters)
    best_parameters = weight_refinement.final_objective <
        min(greedy_descent.final_objective,
            joint_scan.best_objective,
            post_joint_refinement.final_objective) ?
        weight_refinement.final_parameters : best_parameters
    finite_difference_refinement =
        finite_difference_coefficient_direction_refinement(f, best_parameters)
    best_parameters = finite_difference_refinement.improved ?
        finite_difference_refinement.final_parameters : best_parameters
    smooth_refinement =
        smooth_objective_coefficient_refinement(full_model, best_parameters)
    best_parameters = smooth_refinement.accepted ?
        smooth_refinement.final_parameters : best_parameters
    final_breakdown = final_objective_breakdown(full_model, best_parameters)
    targeted_refinement =
        targeted_worst_metric_refinement(full_model, best_parameters, final_breakdown, f)
    best_parameters = targeted_refinement.accepted ?
        targeted_refinement.final_parameters : best_parameters
    final_breakdown = targeted_refinement.accepted ?
        final_objective_breakdown(full_model, best_parameters) : final_breakdown
    separated_refinement = separated_component_refinement(
        full_model,
        best_parameters,
        final_breakdown,
    )
    warm_topology_refinement =
        warm_started_topology_neighbor_refinement(full_model, best_parameters)
    current_sw_indices = WEIGHTED_GREEDY_SW_16_INDICES
    best_parameters = warm_topology_refinement.improved ?
        warm_topology_refinement.final_parameters : best_parameters
    current_sw_indices = warm_topology_refinement.improved ?
        warm_topology_refinement.best_indices : current_sw_indices
    final_breakdown = warm_topology_refinement.improved ?
        final_objective_breakdown(
            full_model,
            best_parameters;
            sw_indices = current_sw_indices,
        ) : final_breakdown
    ranked_topology_refinement =
        ranked_topology_neighbor_refinement(
            full_model,
            best_parameters;
            base_indices = current_sw_indices,
        )
    best_parameters = ranked_topology_refinement.improved ?
        ranked_topology_refinement.final_parameters : best_parameters
    current_sw_indices = ranked_topology_refinement.improved ?
        ranked_topology_refinement.best_indices : current_sw_indices
    final_breakdown = ranked_topology_refinement.improved ?
        final_objective_breakdown(
            full_model,
            best_parameters;
            sw_indices = current_sw_indices,
        ) : final_breakdown
    topology_neighbor = topology_neighbor_scan(
        full_model,
        best_parameters;
        base_indices = current_sw_indices,
    )
    pressure_table_refinement = pressure_band_table_refinement(
        full_model,
        best_parameters,
        final_breakdown;
        sw_indices = current_sw_indices,
    )
    final_breakdown = pressure_table_refinement.improved ?
        pressure_table_refinement.refined_breakdown : final_breakdown
    active_entry_refinement = active_table_entry_refinement(
        full_model,
        best_parameters,
        final_breakdown,
        pressure_table_refinement;
        sw_indices = current_sw_indices,
    )
    if active_entry_refinement.improved
        active_model = pressure_band_active_table_moved_model(
            full_model,
            best_parameters,
            pressure_table_refinement.accepted_moves,
            active_entry_refinement.accepted_moves;
            sw_indices = current_sw_indices,
        )
        final_breakdown = final_objective_breakdown_from_model(
            active_model;
            sw_indices = current_sw_indices,
            method = "active coefficient-table entry refinement hard-gate breakdown",
        )
    end
    next_optimizer_target = constrained_table_optimizer_target(final_breakdown)
    topology_scan = reduced_accuracy_topology_scan()
    subset_topology_scan = subset_search_topology_scan()
    final_objective = min(directional_search.final_objective,
                          coordinate_scan.best_objective,
                          greedy_descent.final_objective,
                          joint_scan.best_objective,
                          post_joint_refinement.final_objective,
                          weight_refinement.final_objective,
                          finite_difference_refinement.best_objective,
                          smooth_refinement.final_objective,
                          targeted_refinement.final_objective,
                          separated_refinement.final_objective,
                          warm_topology_refinement.best_objective,
                          ranked_topology_refinement.best_objective,
                          topology_neighbor.best_objective,
                          pressure_table_refinement.final_objective,
                          active_entry_refinement.final_objective)
    objective_target = 1.0
    enzyme_check = enzyme_surrogate_check(parameters)
    reactant_check = reactant_surrogate_check(parameters)
    finite_preflight = isfinite(initial_objective) &&
                       isfinite(derivative) &&
                       isfinite(line_search.best_objective)
    return (
        case = "reduced_ecckd_optimization_preflight",
        timestamp_utc = string(Dates.now()),
        status = finite_preflight ? "preflight_ready" : "failed",
        reference_scope = collect(REDUCED_CASE_NAMES),
        parameterization = "softmax weights plus per-g-point absorption and Rayleigh log-scales",
        ng_sw = length(WEIGHTED_GREEDY_SW_16_INDICES),
        parameter_count = length(parameters),
        objective = "maximum normalized clean ecCKD shortwave/heating/forcing hard-gate residual",
        objective_target = objective_target,
        initial_objective = initial_objective,
        directional_derivative = derivative,
        best_trial_step = line_search.best_step,
        best_trial_objective = line_search.best_objective,
        trial_improved_objective = line_search.improved,
        trial_line_search = line_search.trials,
        optimization_smoke = optimization_smoke,
        directional_search = directional_search,
        block_trial_scan = block_scan,
        coordinate_coefficient_scan = coordinate_scan,
        greedy_coordinate_descent = greedy_descent,
        greedy_coordinate_descent_checkpoint_used = greedy_checkpoint_used,
        coefficient_joint_direction_scan = joint_scan,
        post_joint_coordinate_refinement = post_joint_refinement,
        post_coefficient_weight_refinement = weight_refinement,
        finite_difference_coefficient_direction_refinement =
            finite_difference_refinement,
        smooth_objective_coefficient_refinement = smooth_refinement,
        final_objective_breakdown = final_breakdown,
        targeted_worst_metric_refinement = targeted_refinement,
        separated_component_refinement = separated_refinement,
        pressure_band_table_refinement = pressure_table_refinement,
        active_table_entry_refinement = active_entry_refinement,
        constrained_table_optimizer_target = next_optimizer_target,
        warm_started_topology_neighbor_refinement = warm_topology_refinement,
        ranked_topology_neighbor_refinement = ranked_topology_refinement,
        topology_neighbor_scan = topology_neighbor,
        topology_candidate_scan = topology_scan,
        subset_search_topology_scan = subset_topology_scan,
        final_objective_target_ratio = final_objective / objective_target,
        acceptance_gap_status = final_objective <= objective_target ?
            "passes_objective_target" : "far_above_objective_target",
        next_required_work = final_objective <= objective_target ?
            "Regenerate reduced_ecckd_accuracy and Breeze reduced Pareto artifacts from the optimized model." :
            "Move beyond bounded pressure-band table scales: run a stronger joint coefficient/table optimizer against flux and heating residuals or jointly optimize the reduced quadrature definition; the current table-refined 48-parameter path remains far above the hard-gate target.",
        finite_directional_derivative = isfinite(derivative),
        reactant_status = optional_dependency_status("Reactant"),
        enzyme_status = optional_dependency_status("Enzyme"),
        reactant_check = reactant_check,
        enzyme_check = enzyme_check,
    )
end

function write_preflight_artifacts(result)
    mkpath(dirname(PREFLIGHT_JSON))
    write(PREFLIGHT_JSON, json_object(result) * "\n")
    write(PREFLIGHT_MD, markdown_report(result))
    print(markdown_report(result))
    println("Wrote $PREFLIGHT_JSON")
    println("Wrote $PREFLIGHT_MD")
end

function main(; result = nothing)
    write_preflight_artifacts(result === nothing ? reduced_optimization_preflight() : result)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
