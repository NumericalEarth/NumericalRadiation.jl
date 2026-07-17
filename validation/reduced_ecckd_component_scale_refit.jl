include(joinpath(@__DIR__, "validation_results.jl"))

using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_boundary_table_continuation_optimizer.jl"))

const COMPONENT_SCALE_REFIT_JSON =
    validation_results_path("reduced_ecckd_component_scale_refit.json")
const COMPONENT_SCALE_REFIT_MD =
    validation_results_path("reduced_ecckd_component_scale_refit.md")

component_scale_probe_step() =
    parse(Float64, get(ENV, "RH_REDUCED_COMPONENT_SCALE_PROBE_STEP", "0.00390625"))

component_scale_max_log_scale() =
    parse(Float64, get(ENV, "RH_REDUCED_COMPONENT_SCALE_MAX_LOG_SCALE", "0.125"))

component_scale_coordinate_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_COMPONENT_SCALE_COORDINATE_ITERATIONS", "3"))

function component_scale_coordinate_steps()
    raw = get(ENV, "RH_REDUCED_COMPONENT_SCALE_COORDINATE_STEPS",
              "0.00390625,0.0078125,0.015625,0.03125,0.0625,0.125")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function component_scale_ridge_lambdas()
    raw = get(ENV, "RH_REDUCED_COMPONENT_SCALE_RIDGE_LAMBDAS",
              "1.0e-6,1.0e-4,1.0e-2,1.0,100.0,10000.0")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function component_scale_move(index, ng, log_scale)
    if index <= ng
        component = "static_absorption"
        local_gpoint_index = index
    elseif index <= 2ng
        component = "h2o_absorption"
        local_gpoint_index = index - ng
    else
        component = "rayleigh"
        local_gpoint_index = index - 2ng
    end
    return (
        component = component,
        local_gpoint_index = local_gpoint_index,
        parameter_index = index,
        log_scale = log_scale,
        scale = exp(log_scale),
    )
end

function component_scaled_model(base_model, deltas)
    ng = size(base_model.shortwave_absorption, 1)
    length(deltas) == 3ng ||
        throw(DimensionMismatch("component scale vector must have 3 * ng entries"))
    shortwave_absorption = copy(base_model.shortwave_absorption)
    shortwave_h2o_absorption = copy(base_model.shortwave_h2o_absorption)
    shortwave_rayleigh = copy(base_model.shortwave_rayleigh_molar_scattering)

    static_scales = exp.(clamp.(deltas[1:ng], -5.0, 5.0))
    h2o_scales = exp.(clamp.(deltas[(ng + 1):(2ng)], -5.0, 5.0))
    rayleigh_scales = exp.(clamp.(deltas[(2ng + 1):(3ng)], -5.0, 5.0))
    for ig in 1:ng
        shortwave_absorption[ig, :, :, :] .*= static_scales[ig]
        if length(shortwave_h2o_absorption) != 0
            shortwave_h2o_absorption[ig, :, :, :] .*= h2o_scales[ig]
        end
        shortwave_rayleigh[ig] *= rayleigh_scales[ig]
    end

    model = EcCKDTabulatedGasOpticsModel(
        gas_names = NumericalRadiation.gas_names(base_model),
        pressure_grid = base_model.pressure_grid,
        temperature_grid = base_model.temperature_grid,
        h2o_mole_fraction_grid = base_model.h2o_mole_fraction_grid,
        gas_reference_mole_fractions = base_model.gas_reference_mole_fractions,
        longwave_absorption = base_model.longwave_absorption,
        shortwave_absorption = shortwave_absorption,
        longwave_h2o_absorption = base_model.longwave_h2o_absorption,
        shortwave_h2o_absorption = shortwave_h2o_absorption,
        shortwave_rayleigh_molar_scattering = shortwave_rayleigh,
        longwave_source_scale = base_model.longwave_source_scale,
        longwave_source_temperature_grid = base_model.longwave_source_temperature_grid,
        longwave_source_table = base_model.longwave_source_table,
        longwave_weights = base_model.longwave_weights,
        shortwave_weights = base_model.shortwave_weights,
    )
    return copy_reduced_metadata!(model, base_model)
end

function component_scale_coordinate_scan(base_model, current_deltas, current_objective)
    ng = size(base_model.shortwave_absorption, 1)
    rows = NamedTuple[]
    for index in 1:(3ng), step in component_scale_coordinate_steps(), direction in (-1.0, 1.0)
        trial_deltas = copy(current_deltas)
        trial_deltas[index] = clamp(
            trial_deltas[index] + direction * step,
            -component_scale_max_log_scale(),
            component_scale_max_log_scale(),
        )
        objective, cases, _ = component_scale_trial(base_model, trial_deltas)
        push!(rows, (
            move = component_scale_move(index, ng, trial_deltas[index] - current_deltas[index]),
            parameter_index = index,
            absolute_log_scale = trial_deltas[index],
            objective = objective,
            improvement = current_objective - objective,
            worst_toa_forcing_error_w_m2 =
                maximum(case.toa_forcing_max_abs for case in cases),
            worst_surface_forcing_error_w_m2 =
                maximum(case.surface_forcing_max_abs for case in cases),
            accepted = objective < current_objective,
            deltas = trial_deltas,
        ))
    end
    best = argmin(row -> row.objective, rows)
    return rows, best
end

function component_scale_coordinate_descent(base_model, initial_objective)
    ng = size(base_model.shortwave_absorption, 1)
    current_deltas = zeros(Float64, 3ng)
    current_objective = initial_objective
    accepted_moves = NamedTuple[]
    iterations = NamedTuple[]

    for iteration in 1:component_scale_coordinate_iterations()
        rows, best = component_scale_coordinate_scan(
            base_model,
            current_deltas,
            current_objective,
        )
        accepted = best.objective < current_objective
        push!(iterations, (
            iteration = iteration,
            trial_count = length(rows),
            base_objective = current_objective,
            best_objective = best.objective,
            best_objective_reduction = current_objective - best.objective,
            best_worst_toa_forcing_error_w_m2 =
                best.worst_toa_forcing_error_w_m2,
            best_worst_surface_forcing_error_w_m2 =
                best.worst_surface_forcing_error_w_m2,
            accepted = accepted,
            accepted_move = accepted ? best.move : nothing,
        ))
        accepted || break
        current_deltas .= best.deltas
        current_objective = best.objective
        push!(accepted_moves, best.move)
    end
    final_objective, final_cases, _ = component_scale_trial(base_model, current_deltas)
    return (
        final_deltas = current_deltas,
        final_objective = final_objective,
        final_cases = final_cases,
        accepted_moves = accepted_moves,
        iterations = iterations,
    )
end

function component_scale_trial(base_model, deltas)
    model = component_scaled_model(base_model, deltas)
    objective, cases = full_hard_objective(model)
    return objective, cases, model
end

function component_scale_base_model(full_model)
    model = current_constrained_table_model(
        full_model;
        base_mode = "boundary_table_post_descent",
    )
    apply_active_table_entry_moves!(
        model,
        latest_boundary_table_continuation_optimizer_moves(),
    )
    return model
end

function component_scale_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    base_model = component_scale_base_model(full_model)
    base_objective, base_cases = full_hard_objective(base_model)
    base_residual = constrained_table_residual_vector(base_model)
    ng = size(base_model.shortwave_absorption, 1)
    parameter_count = 3ng
    h = component_scale_probe_step()
    sensitivity = zeros(Float64, length(base_residual), parameter_count)

    for index in 1:parameter_count
        deltas = zeros(Float64, parameter_count)
        deltas[index] = h
        moved = component_scaled_model(base_model, deltas)
        sensitivity[:, index] .=
            (constrained_table_residual_vector(moved) .- base_residual) ./ h
    end

    max_delta = component_scale_max_log_scale()
    rows = NamedTuple[]
    for lambda in component_scale_ridge_lambdas()
        lhs = sensitivity' * sensitivity + lambda * I
        rhs = -(sensitivity' * base_residual)
        raw_delta = Vector(lhs \ rhs)
        clipped_delta = clamp.(raw_delta, -max_delta, max_delta)
        objective, cases, _ = component_scale_trial(base_model, clipped_delta)
        push!(rows, (
            ridge_lambda = lambda,
            raw_delta_norm = norm(raw_delta),
            clipped_delta_norm = norm(clipped_delta),
            max_abs_delta = maximum(abs, clipped_delta),
            exact_objective = objective,
            objective_reduction = base_objective - objective,
            worst_toa_forcing_error_w_m2 =
                maximum(case.toa_forcing_max_abs for case in cases),
            worst_surface_forcing_error_w_m2 =
                maximum(case.surface_forcing_max_abs for case in cases),
            accepted = objective < base_objective,
            component_log_scales = clipped_delta,
        ))
    end

    best = argmin(row -> row.exact_objective, rows)
    coordinate = component_scale_coordinate_descent(base_model, base_objective)
    linear_accepted = best.exact_objective < base_objective
    coordinate_accepted = coordinate.final_objective < base_objective
    accepted = linear_accepted || coordinate_accepted
    use_coordinate =
        coordinate.final_objective <= best.exact_objective || !linear_accepted
    final_objective = accepted ?
        (use_coordinate ? coordinate.final_objective : best.exact_objective) :
        base_objective
    final_cases = accepted ?
        (use_coordinate ? coordinate.final_cases :
         component_scale_trial(base_model, best.component_log_scales)[2]) :
        base_cases
    final_deltas = accepted ?
        (use_coordinate ? coordinate.final_deltas : best.component_log_scales) :
        Float64[]
    return (
        case = "reduced_ecckd_component_scale_refit",
        status = accepted ? "component_scale_refit_improved" :
                 "component_scale_refit_rejected",
        base_mode = "boundary_table_post_descent_plus_continuation",
        parameterization = "per-g-point static-absorption, H2O-absorption, and Rayleigh log scales",
        parameter_count = parameter_count,
        probe_step = h,
        max_log_scale = max_delta,
        ridge_lambdas = component_scale_ridge_lambdas(),
        best_ridge_lambda = best.ridge_lambda,
        coordinate_iterations_requested = component_scale_coordinate_iterations(),
        coordinate_steps = component_scale_coordinate_steps(),
        coordinate_iterations = coordinate.iterations,
        base_objective = base_objective,
        best_exact_objective = best.exact_objective,
        coordinate_final_objective = coordinate.final_objective,
        final_objective = final_objective,
        objective_reduction = base_objective - final_objective,
        base_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in base_cases),
        base_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in base_cases),
        final_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in final_cases),
        final_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in final_cases),
        accepted = accepted,
        selected_refit = accepted ? (use_coordinate ? "coordinate" : "linearized") : "none",
        accepted_moves = use_coordinate && accepted ? coordinate.accepted_moves : NamedTuple[],
        component_log_scales = final_deltas,
        rows = rows,
    )
end

function component_scale_refit_markdown(result)
    lines = String[
        "# Reduced ecCKD Component-Scale Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base mode | $(result.base_mode) |",
        "| Parameter count | $(result.parameter_count) |",
        "| Probe step | $(@sprintf("%.12g", result.probe_step)) |",
        "| Max log scale | $(@sprintf("%.12g", result.max_log_scale)) |",
        "| Best ridge lambda | $(@sprintf("%.12g", result.best_ridge_lambda)) |",
        "| Coordinate iterations | $(length(result.coordinate_iterations)) / $(result.coordinate_iterations_requested) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Best linearized exact objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Coordinate final objective | $(@sprintf("%.12g", result.coordinate_final_objective)) |",
        "| Final objective | $(@sprintf("%.12g", result.final_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Base TOA forcing error | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Final TOA forcing error | $(@sprintf("%.12g", result.final_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing error | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Final surface forcing error | $(@sprintf("%.12g", result.final_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Selected refit | $(result.selected_refit) |",
        "| Accepted moves | $(length(result.accepted_moves)) |",
        "| Accepted | $(result.accepted) |",
        "",
        "This diagnostic applies whole-component log-scale factors to the retained",
        "boundary-table 32x16 model. Static absorption, H2O absorption, and",
        "Rayleigh scattering are scaled independently per retained shortwave",
        "g-point, preserving nonnegative tabulated optics.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? component_scale_refit_result() : result
    mkpath(dirname(COMPONENT_SCALE_REFIT_JSON))
    write(COMPONENT_SCALE_REFIT_JSON, json_object(result) * "\n")
    write(COMPONENT_SCALE_REFIT_MD, component_scale_refit_markdown(result))
    print(component_scale_refit_markdown(result))
    println("Wrote $COMPONENT_SCALE_REFIT_JSON")
    println("Wrote $COMPONENT_SCALE_REFIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
