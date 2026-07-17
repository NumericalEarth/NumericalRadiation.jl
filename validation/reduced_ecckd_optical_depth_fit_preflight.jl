include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_accuracy.jl"))

const OPTICAL_DEPTH_FIT_JSON =
    validation_results_path("reduced_ecckd_optical_depth_fit_preflight.json")
const OPTICAL_DEPTH_FIT_MD =
    validation_results_path("reduced_ecckd_optical_depth_fit_preflight.md")

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

function shortwave_workspace(model, nlayers)
    longwave = LongwaveOpticalProperties(
        zeros(Float64, size(model.longwave_absorption, 1), nlayers),
        zeros(Float64, size(model.longwave_absorption, 1), nlayers),
        source_top = zeros(Float64, size(model.longwave_absorption, 1), nlayers),
        source_bottom = zeros(Float64, size(model.longwave_absorption, 1), nlayers),
    )
    shortwave = ShortwaveOpticalProperties(
        zeros(Float64, size(model.shortwave_absorption, 1), nlayers),
    )
    return longwave, shortwave
end

function optical_depth_fit_stats(target, candidate)
    residual = candidate .- target
    return (
        rmse = sqrt(sum(abs2, residual) / length(residual)),
        max_abs = maximum(abs, residual),
        target_rms = sqrt(sum(abs2, target) / length(target)),
        relative_rmse = sqrt(sum(abs2, residual) / max(sum(abs2, target), eps(Float64))),
    )
end

function fitted_scales(target, candidate)
    ng = size(target, 1)
    scales = ones(Float64, ng)
    for ig in 1:ng
        numerator = sum(candidate[ig, :, :] .* target[ig, :, :])
        denominator = sum(abs2, candidate[ig, :, :])
        scales[ig] = denominator <= eps(Float64) ? 1.0 :
            clamp(numerator / denominator, 0.01, 100.0)
    end
    return scales
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

function flux_objective(model)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return (
        cases = cases,
        objective = maximum(normalized_case_objective, cases),
        passed_hard_thresholds = all(case -> case.passed_hard_thresholds, cases),
    )
end

function apply_shortwave_scales!(model, scales)
    for ig in axes(model.shortwave_absorption, 1)
        model.shortwave_absorption[ig, :, :, :] .*= scales[ig]
        if length(model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[ig, :, :, :] .*= scales[ig]
        end
        model.shortwave_rayleigh_molar_scattering[ig] *= scales[ig]
    end
    return model
end

function weighted_greedy_candidate_model(full_model)
    model = indexed_tabulated_model(
        full_model,
        collect(1:size(full_model.longwave_absorption, 1)),
        WEIGHTED_GREEDY_SW_16_INDICES,
    )
    model.shortwave_weights .= WEIGHTED_GREEDY_SW_16_WEIGHTS
    return model
end

function component_masked_model(full_model; absorption, dynamic_h2o, rayleigh)
    model = weighted_greedy_candidate_model(full_model)
    absorption || fill!(model.shortwave_absorption, 0)
    dynamic_h2o || fill!(model.shortwave_h2o_absorption, 0)
    rayleigh || fill!(model.shortwave_rayleigh_molar_scattering, 0)
    return model
end

function apply_component_scales!(model, scales)
    for ig in axes(model.shortwave_absorption, 1)
        model.shortwave_absorption[ig, :, :, :] .*= scales[ig, 1]
        if length(model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[ig, :, :, :] .*= scales[ig, 2]
        end
        model.shortwave_rayleigh_molar_scattering[ig] *= scales[ig, 3]
    end
    return model
end

function optical_depth_training_arrays(case, target_model, candidate_model)
    nc = require_ncdatasets()
    nc.NCDataset(reference_path(case.path)) do dataset
        pressure_layers = Array(dataset["pressure_layer"])
        pressure_interfaces = Array(dataset["pressure_interface"])
        temperature_layers = Array(dataset["temperature_layer"])
        temperature_interfaces = Array(dataset["temperature_interface"])
        gas_amounts = gas_column_amounts(dataset, pressure_interfaces)

        nlayers, ncolumns = size(pressure_layers)
        target = zeros(Float64, size(target_model.shortwave_absorption, 1), nlayers, ncolumns)
        candidate = similar(target)
        target_lw, target_sw = shortwave_workspace(target_model, nlayers)
        candidate_lw, candidate_sw = shortwave_workspace(candidate_model, nlayers)

        for j in 1:ncolumns
            atmosphere = ColumnAtmosphere(
                pressure_layers = pressure_layers[:, j],
                pressure_interfaces = pressure_interfaces[:, j],
                temperature_layers = temperature_layers[:, j],
                temperature_interfaces = temperature_interfaces[:, j],
                gases = Dict(name => values[:, j] for (name, values) in gas_amounts.amounts),
                surface = (;),
                geometry = (;),
            )
            optical_properties!(target_lw, target_sw, target_model, atmosphere)
            optical_properties!(candidate_lw, candidate_sw, candidate_model, atmosphere)
            target[:, :, j] .= target_sw.optical_depth .+ target_sw.rayleigh_optical_depth
            candidate[:, :, j] .= candidate_sw.optical_depth .+
                                  candidate_sw.rayleigh_optical_depth
        end
        return target, candidate
    end
end

function combined_training_arrays(target_model, candidate_model)
    targets = Array{Float64, 3}[]
    candidates = Array{Float64, 3}[]
    for case in REDUCED_CASES
        target, candidate = optical_depth_training_arrays(case, target_model, candidate_model)
        push!(targets, target)
        push!(candidates, candidate)
    end
    return cat(targets...; dims = 3), cat(candidates...; dims = 3)
end

function component_fit_scales(target, absorption, dynamic_h2o, rayleigh)
    ng = size(target, 1)
    scales = ones(Float64, ng, 3)
    fitted = similar(target)
    for ig in 1:ng
        x1 = vec(absorption[ig, :, :])
        x2 = vec(dynamic_h2o[ig, :, :])
        x3 = vec(rayleigh[ig, :, :])
        y = vec(target[ig, :, :])
        normal = [
            dot(x1, x1) dot(x1, x2) dot(x1, x3)
            dot(x2, x1) dot(x2, x2) dot(x2, x3)
            dot(x3, x1) dot(x3, x2) dot(x3, x3)
        ]
        rhs = [dot(x1, y), dot(x2, y), dot(x3, y)]
        λ = 1.0e-12 * max(tr(normal), 1.0)
        component_scales = (normal + λ * I) \ rhs
        scales[ig, :] .= clamp.(component_scales, 0.0, 100.0)
        fitted[ig, :, :] .= scales[ig, 1] .* absorption[ig, :, :] .+
                            scales[ig, 2] .* dynamic_h2o[ig, :, :] .+
                            scales[ig, 3] .* rayleigh[ig, :, :]
    end
    return scales, fitted
end

function interpolation_pairs(model, pressure, temperature)
    if model.temperature_grid isa AbstractMatrix
        ip0, ip1, wp = NumericalRadiation._pressure_bracket(model.pressure_grid, pressure)
        temperature_origin = (1 - wp) * model.temperature_grid[ip0, 1] +
                             wp * model.temperature_grid[ip1, 1]
        temperature_step = model.temperature_grid[1, 2] - model.temperature_grid[1, 1]
        temperature_index = 1 + clamp(
            (temperature - temperature_origin) / temperature_step,
            0.0,
            Float64(size(model.temperature_grid, 2)) - 1.0001,
        )
        it0 = Int(floor(temperature_index))
        it1 = it0 + 1
        wt = temperature_index - it0
    else
        ip0, ip1, wp = NumericalRadiation._bracket(model.pressure_grid, pressure)
        it0, it1, wt = NumericalRadiation._bracket(model.temperature_grid, temperature)
    end
    return (
        (ip0, it0, (1 - wp) * (1 - wt)),
        (ip1, it0, wp * (1 - wt)),
        (ip0, it1, (1 - wp) * wt),
        (ip1, it1, wp * wt),
    )
end

function h2o_interpolation_pairs(model, pressure, temperature, h2o_mole_fraction)
    isempty(model.h2o_mole_fraction_grid) && return Tuple{}()
    pressure_temperature_pairs = interpolation_pairs(model, pressure, temperature)
    ih0, ih1, wh = NumericalRadiation._log_bracket(
        model.h2o_mole_fraction_grid,
        h2o_mole_fraction,
    )
    pairs = Tuple{Int, Int, Int, Float64}[]
    for (ip, it, weight) in pressure_temperature_pairs
        push!(pairs, (ip, it, ih0, weight * (1 - wh)))
        push!(pairs, (ip, it, ih1, weight * wh))
    end
    return pairs
end

function coefficient_fit_parameter_count(model)
    np = length(model.pressure_grid)
    nt = NumericalRadiation._temperature_grid_length(model.temperature_grid)
    nh2o = length(model.h2o_mole_fraction_grid)
    return length(NumericalRadiation.gas_names(model)) * np * nt +
           (nh2o == 0 ? 0 : np * nt * nh2o) + 1
end

function absorption_parameter_index(model, gas_index, ip, it)
    np = length(model.pressure_grid)
    nt = NumericalRadiation._temperature_grid_length(model.temperature_grid)
    return ((gas_index - 1) * np + (ip - 1)) * nt + it
end

function h2o_parameter_index(model, ip, it, ih)
    np = length(model.pressure_grid)
    nt = NumericalRadiation._temperature_grid_length(model.temperature_grid)
    ngas = length(NumericalRadiation.gas_names(model))
    return ngas * np * nt + ((ip - 1) * nt + (it - 1)) *
           length(model.h2o_mole_fraction_grid) + ih
end

function rayleigh_parameter_index(model)
    return coefficient_fit_parameter_count(model)
end

function coefficient_fit_design(case, model, target_model)
    nc = require_ncdatasets()
    nc.NCDataset(reference_path(case.path)) do dataset
        pressure_layers = Array(dataset["pressure_layer"])
        pressure_interfaces = Array(dataset["pressure_interface"])
        temperature_layers = Array(dataset["temperature_layer"])
        temperature_interfaces = Array(dataset["temperature_interface"])
        gas_amounts = gas_column_amounts(dataset, pressure_interfaces)
        nlayers, ncolumns = size(pressure_layers)
        nparameters = coefficient_fit_parameter_count(model)
        nsamples = nlayers * ncolumns
        design = zeros(Float64, nsamples, nparameters)
        gas_names = NumericalRadiation.gas_names(model)
        references = model.gas_reference_mole_fractions
        target, _ = optical_depth_training_arrays(case, target_model, model)

        row = 0
        for j in 1:ncolumns, k in 1:nlayers
            row += 1
            pressure = pressure_layers[k, j]
            temperature = temperature_layers[k, j]
            gases = Dict(name => values[:, j] for (name, values) in gas_amounts.amounts)
            for (ip, it, weight) in interpolation_pairs(model, pressure, temperature)
                for (igas, name) in enumerate(gas_names)
                    amount = NumericalRadiation._gas_value(gases, name, k)
                    reference = references[igas]
                    if reference != 0 && haskey(gases, :composite)
                        amount -= reference * NumericalRadiation._gas_value(gases, :composite, k)
                    end
                    design[row, absorption_parameter_index(model, igas, ip, it)] +=
                        weight * amount
                end
            end

            if !isempty(model.h2o_mole_fraction_grid)
                h2o_mole_fraction =
                    NumericalRadiation._h2o_mole_fraction(Float64,
                        ColumnAtmosphere(
                            pressure_layers = pressure_layers[:, j],
                            pressure_interfaces = pressure_interfaces[:, j],
                            temperature_layers = temperature_layers[:, j],
                            temperature_interfaces = temperature_interfaces[:, j],
                            gases = gases,
                            surface = (;),
                            geometry = (;),
                        ),
                        k,
                    )
                h2o_amount = NumericalRadiation._gas_value(gases, :h2o, k)
                for (ip, it, ih, weight) in h2o_interpolation_pairs(
                        model, pressure, temperature, h2o_mole_fraction)
                    design[row, h2o_parameter_index(model, ip, it, ih)] +=
                        weight * h2o_amount
                end
            end

            Δp = pressure_interfaces[k + 1, j] - pressure_interfaces[k, j]
            design[row, rayleigh_parameter_index(model)] =
                Δp / (GRAVITY * 0.001 * 28.9647)
        end
        return design, [vec(target[ig, :, :]) for ig in axes(target, 1)]
    end
end

function combined_coefficient_fit_design(cases, model, target_model)
    designs = Matrix{Float64}[]
    targets_by_case = Vector{Vector{Float64}}[]
    for case in cases
        design, targets = coefficient_fit_design(case, model, target_model)
        push!(designs, design)
        push!(targets_by_case, targets)
    end
    ng = size(model.shortwave_absorption, 1)
    targets = [
        vcat([case_targets[ig] for case_targets in targets_by_case]...)
        for ig in 1:ng
    ]
    return vcat(designs...), targets
end

function coefficient_table_from_fit(full_model, base_model, fitted_parameters)
    np = length(base_model.pressure_grid)
    nt = NumericalRadiation._temperature_grid_length(base_model.temperature_grid)
    ngas = length(NumericalRadiation.gas_names(base_model))
    ng = size(base_model.shortwave_absorption, 1)
    shortwave_absorption = similar(base_model.shortwave_absorption)
    shortwave_h2o_absorption = similar(base_model.shortwave_h2o_absorption)
    rayleigh = similar(base_model.shortwave_rayleigh_molar_scattering)

    for ig in 1:ng
        parameters = max.(fitted_parameters[ig], 0.0)
        for gas_index in 1:ngas, ip in 1:np, it in 1:nt
            shortwave_absorption[ig, gas_index, ip, it] =
                parameters[absorption_parameter_index(base_model, gas_index, ip, it)]
        end
        if !isempty(shortwave_h2o_absorption)
            for ip in 1:np, it in 1:nt, ih in 1:length(base_model.h2o_mole_fraction_grid)
                shortwave_h2o_absorption[ig, ip, it, ih] =
                    parameters[h2o_parameter_index(base_model, ip, it, ih)]
            end
        end
        rayleigh[ig] = parameters[rayleigh_parameter_index(base_model)]
    end

    fitted = EcCKDTabulatedGasOpticsModel(
        gas_names = NumericalRadiation.gas_names(full_model),
        pressure_grid = full_model.pressure_grid,
        temperature_grid = full_model.temperature_grid,
        h2o_mole_fraction_grid = full_model.h2o_mole_fraction_grid,
        gas_reference_mole_fractions = full_model.gas_reference_mole_fractions,
        longwave_absorption = full_model.longwave_absorption,
        shortwave_absorption = shortwave_absorption,
        longwave_h2o_absorption = full_model.longwave_h2o_absorption,
        shortwave_h2o_absorption = shortwave_h2o_absorption,
        shortwave_rayleigh_molar_scattering = rayleigh,
        longwave_source_scale = full_model.longwave_source_scale,
        longwave_source_temperature_grid = full_model.longwave_source_temperature_grid,
        longwave_source_table = full_model.longwave_source_table,
        longwave_weights = full_model.longwave_weights,
        shortwave_weights = base_model.shortwave_weights,
    )
    metadata = get(REDUCED_MODEL_METADATA, base_model, nothing)
    if metadata === nothing
        return fitted
    end
    return register_reduced_model(fitted;
        sw_indices = metadata.sw_indices,
        sw_groups = metadata.sw_groups,
        full_sw_weights = metadata.full_sw_weights,
    )
end

function coefficient_parameters_from_model(model)
    np = length(model.pressure_grid)
    nt = NumericalRadiation._temperature_grid_length(model.temperature_grid)
    ngas = length(NumericalRadiation.gas_names(model))
    ng = size(model.shortwave_absorption, 1)
    parameters = [zeros(Float64, coefficient_fit_parameter_count(model)) for _ in 1:ng]
    for ig in 1:ng
        for gas_index in 1:ngas, ip in 1:np, it in 1:nt
            parameters[ig][absorption_parameter_index(model, gas_index, ip, it)] =
                model.shortwave_absorption[ig, gas_index, ip, it]
        end
        if !isempty(model.shortwave_h2o_absorption)
            for ip in 1:np, it in 1:nt, ih in 1:length(model.h2o_mole_fraction_grid)
                parameters[ig][h2o_parameter_index(model, ip, it, ih)] =
                    model.shortwave_h2o_absorption[ig, ip, it, ih]
            end
        end
        parameters[ig][rayleigh_parameter_index(model)] =
            model.shortwave_rayleigh_molar_scattering[ig]
    end
    return parameters
end

function coefficient_table_fit(full_model, target_model, base_model; ridge = 1.0e-16)
    design, targets = combined_coefficient_fit_design(REDUCED_CASES, base_model, target_model)
    regularization = ridge * max(opnorm(design)^2, 1.0)
    lhs = design' * design + regularization * I
    fitted_parameters = [lhs \ (design' * target) for target in targets]
    predictions = [design * parameters for parameters in fitted_parameters]
    physical_target_parameters = coefficient_parameters_from_model(target_model)
    physical_target_predictions = [
        design * parameters for parameters in physical_target_parameters
    ]
    fitted_model = coefficient_table_from_fit(full_model, base_model, fitted_parameters)
    target_matrix = zeros(Float64, length(targets), length(first(targets)))
    prediction_matrix = similar(target_matrix)
    physical_target_prediction_matrix = similar(target_matrix)
    for ig in eachindex(targets)
        target_matrix[ig, :] .= targets[ig]
        prediction_matrix[ig, :] .= predictions[ig]
        physical_target_prediction_matrix[ig, :] .= physical_target_predictions[ig]
    end
    clipped_target, clipped_candidate = combined_training_arrays(target_model, fitted_model)
    return (
        model = fitted_model,
        parameter_count_per_g = size(design, 2),
        sample_count = size(design, 1) * length(targets),
        clipped_parameter_count = sum(count(<(0), parameters) for parameters in fitted_parameters),
        physical_target_optical_depth_stats =
            optical_depth_fit_stats(target_matrix, physical_target_prediction_matrix),
        raw_least_squares_optical_depth_stats =
            optical_depth_fit_stats(target_matrix, prediction_matrix),
        clipped_model_optical_depth_stats =
            optical_depth_fit_stats(clipped_target, clipped_candidate),
    )
end

function optical_depth_fit_preflight()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    target_model = weighted_tabulated_model(full_model, 32, 16)
    candidate_model = weighted_greedy_candidate_model(full_model)

    case_rows = NamedTuple[]
    all_target = Array{Float64, 3}[]
    all_candidate = Array{Float64, 3}[]
    for case in REDUCED_CASES
        target, candidate = optical_depth_training_arrays(case, target_model, candidate_model)
        push!(all_target, target)
        push!(all_candidate, candidate)
        push!(case_rows, (
            case = case.case,
            sample_count = length(target),
            baseline = optical_depth_fit_stats(target, candidate),
        ))
    end

    target = cat(all_target...; dims = 3)
    candidate = cat(all_candidate...; dims = 3)
    baseline = optical_depth_fit_stats(target, candidate)
    scales = fitted_scales(target, candidate)
    fitted = similar(candidate)
    for ig in axes(candidate, 1)
        fitted[ig, :, :] .= scales[ig] .* candidate[ig, :, :]
    end
    refit = optical_depth_fit_stats(target, fitted)
    absorption_model = component_masked_model(full_model;
        absorption = true, dynamic_h2o = false, rayleigh = false)
    h2o_model = component_masked_model(full_model;
        absorption = false, dynamic_h2o = true, rayleigh = false)
    rayleigh_model = component_masked_model(full_model;
        absorption = false, dynamic_h2o = false, rayleigh = true)
    _, absorption_component = combined_training_arrays(target_model, absorption_model)
    _, h2o_component = combined_training_arrays(target_model, h2o_model)
    _, rayleigh_component = combined_training_arrays(target_model, rayleigh_model)
    component_scales, component_fitted =
        component_fit_scales(target, absorption_component, h2o_component, rayleigh_component)
    component_refit = optical_depth_fit_stats(target, component_fitted)
    improvement = baseline.rmse - refit.rmse
    flux_baseline = flux_objective(candidate_model)
    scaled_candidate_model = weighted_greedy_candidate_model(full_model)
    apply_shortwave_scales!(scaled_candidate_model, scales)
    flux_scaled = flux_objective(scaled_candidate_model)
    component_scaled_model = weighted_greedy_candidate_model(full_model)
    apply_component_scales!(component_scaled_model, component_scales)
    flux_component_scaled = flux_objective(component_scaled_model)
    coefficient_fit = coefficient_table_fit(full_model, target_model, target_model)
    flux_physical_target_model = flux_objective(target_model)
    flux_coefficient_fit = flux_objective(coefficient_fit.model)

    return (
        case = "reduced_ecckd_optical_depth_fit_preflight",
        timestamp_utc = string(Dates.now()),
        status = improvement > 0 ? "optical_depth_refit_target_ready" :
            "optical_depth_refit_not_improved",
        target = "weighted 32-to-16 cumulative-k projection of official shortwave optical depths",
        candidate = "weighted-greedy 16-g subset official shortwave optical depths",
        reference_cases = collect(REDUCED_CASE_NAMES),
        ng_sw = 16,
        sample_count = length(target),
        baseline = baseline,
        fitted = refit,
        component_fitted = component_refit,
        rmse_reduction = improvement,
        relative_rmse_reduction = improvement / max(baseline.rmse, eps(Float64)),
        component_rmse_reduction = baseline.rmse - component_refit.rmse,
        component_relative_rmse_reduction =
            (baseline.rmse - component_refit.rmse) / max(baseline.rmse, eps(Float64)),
        fitted_scales = scales,
        component_scales = component_scales,
        scale_min = minimum(scales),
        scale_max = maximum(scales),
        component_scale_min = minimum(component_scales),
        component_scale_max = maximum(component_scales),
        flux_baseline_objective = flux_baseline.objective,
        flux_scaled_objective = flux_scaled.objective,
        flux_scaled_improved = flux_scaled.objective < flux_baseline.objective,
        flux_scaled_passed_hard_thresholds = flux_scaled.passed_hard_thresholds,
        flux_component_scaled_objective = flux_component_scaled.objective,
        flux_component_scaled_improved =
            flux_component_scaled.objective < flux_baseline.objective,
        flux_component_scaled_passed_hard_thresholds =
            flux_component_scaled.passed_hard_thresholds,
        coefficient_table_fit = (
            parameter_count_per_g = coefficient_fit.parameter_count_per_g,
            sample_count = coefficient_fit.sample_count,
            clipped_parameter_count = coefficient_fit.clipped_parameter_count,
            physical_target_optical_depth =
                coefficient_fit.physical_target_optical_depth_stats,
            physical_target_flux_objective = flux_physical_target_model.objective,
            physical_target_flux_passed_hard_thresholds =
                flux_physical_target_model.passed_hard_thresholds,
            raw_least_squares_optical_depth =
                coefficient_fit.raw_least_squares_optical_depth_stats,
            clipped_model_optical_depth =
                coefficient_fit.clipped_model_optical_depth_stats,
            flux_objective = flux_coefficient_fit.objective,
            flux_improved = flux_coefficient_fit.objective < flux_baseline.objective,
            flux_passed_hard_thresholds = flux_coefficient_fit.passed_hard_thresholds,
        ),
        case_rows = case_rows,
        next_required_work = flux_coefficient_fit.passed_hard_thresholds ?
            "Regenerate reduced_ecckd_accuracy and Breeze reduced Pareto artifacts from the coefficient-table fit." :
            "The first real coefficient-table least-squares refit is wired, but unconstrained coefficients require heavy nonnegative clipping and these optical-depth targets are still not enough for the flux hard gate; next use a constrained table optimizer against flux/heating residuals or optimize the reduced quadrature definition jointly with the table entries.",
    )
end

function markdown_report(result)
    lines = String[
        "# Reduced ecCKD Optical-Depth Fit Preflight",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Shortwave g-points | $(result.ng_sw) |",
        "| Optical-depth samples | $(result.sample_count) |",
        "| Baseline optical-depth RMSE | $(@sprintf("%.12g", result.baseline.rmse)) |",
        "| Fitted optical-depth RMSE | $(@sprintf("%.12g", result.fitted.rmse)) |",
        "| Component-fitted optical-depth RMSE | $(@sprintf("%.12g", result.component_fitted.rmse)) |",
        "| Relative RMSE reduction | $(@sprintf("%.6f", result.relative_rmse_reduction)) |",
        "| Component relative RMSE reduction | $(@sprintf("%.6f", result.component_relative_rmse_reduction)) |",
        "| Baseline relative RMSE | $(@sprintf("%.12g", result.baseline.relative_rmse)) |",
        "| Fitted relative RMSE | $(@sprintf("%.12g", result.fitted.relative_rmse)) |",
        "| Component fitted relative RMSE | $(@sprintf("%.12g", result.component_fitted.relative_rmse)) |",
        "| Scale range | $(@sprintf("%.6g", result.scale_min)) to $(@sprintf("%.6g", result.scale_max)) |",
        "| Component scale range | $(@sprintf("%.6g", result.component_scale_min)) to $(@sprintf("%.6g", result.component_scale_max)) |",
        "| Baseline flux objective | $(@sprintf("%.12g", result.flux_baseline_objective)) |",
        "| Scaled flux objective | $(@sprintf("%.12g", result.flux_scaled_objective)) |",
        "| Scaled flux objective improved | $(result.flux_scaled_improved) |",
        "| Component-scaled flux objective | $(@sprintf("%.12g", result.flux_component_scaled_objective)) |",
        "| Component-scaled flux objective improved | $(result.flux_component_scaled_improved) |",
        "| Coefficient-table fit parameters per g | $(result.coefficient_table_fit.parameter_count_per_g) |",
        "| Physical projected table optical-depth RMSE | $(@sprintf("%.12g", result.coefficient_table_fit.physical_target_optical_depth.rmse)) |",
        "| Physical projected table flux objective | $(@sprintf("%.12g", result.coefficient_table_fit.physical_target_flux_objective)) |",
        "| Coefficient-table raw LS optical-depth RMSE | $(@sprintf("%.12g", result.coefficient_table_fit.raw_least_squares_optical_depth.rmse)) |",
        "| Coefficient-table clipped-model optical-depth RMSE | $(@sprintf("%.12g", result.coefficient_table_fit.clipped_model_optical_depth.rmse)) |",
        "| Coefficient-table fit clipped parameters | $(result.coefficient_table_fit.clipped_parameter_count) |",
        "| Coefficient-table fit flux objective | $(@sprintf("%.12g", result.coefficient_table_fit.flux_objective)) |",
        "| Coefficient-table fit flux objective improved | $(result.coefficient_table_fit.flux_improved) |",
        "",
        "This artifact is an optical-depth training preflight, not a flux acceptance result. It compares the current weighted-greedy 16-g subset to a weighted 32-to-16 cumulative-k projection of the official shortwave ecCKD optical depths.",
        "",
        "The fitted per-g optical-depth scales are diagnostic targets only. The coefficient-table fit is the first table-level refit path: it solves for shortwave absorption, dynamic H2O, and Rayleigh table entries against the same optical-depth target, records the raw unconstrained fit separately from the clipped physical table, and then evaluates the resulting fluxes.",
        "",
        "Next required work: $(result.next_required_work)",
    ]
    return join(lines, "\n") * "\n"
end

function main()
    result = optical_depth_fit_preflight()
    mkpath(dirname(OPTICAL_DEPTH_FIT_JSON))
    write(OPTICAL_DEPTH_FIT_JSON, json_object(result) * "\n")
    write(OPTICAL_DEPTH_FIT_MD, markdown_report(result))
    print(markdown_report(result))
    println("Wrote $OPTICAL_DEPTH_FIT_JSON")
    println("Wrote $OPTICAL_DEPTH_FIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
