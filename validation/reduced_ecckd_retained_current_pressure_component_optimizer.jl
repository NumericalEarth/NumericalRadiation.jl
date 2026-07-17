include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_retained_current_component_scale_optimizer4.jl"))

const RETAINED_CURRENT_PRESSURE_COMPONENT_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_current_pressure_component_optimizer.json")
const RETAINED_CURRENT_PRESSURE_COMPONENT_OPTIMIZER_MD =
    validation_results_path("reduced_ecckd_retained_current_pressure_component_optimizer.md")

current_pressure_component_band_count() =
    parse(Int, get(ENV, "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_BANDS", "4"))

current_pressure_component_probe_step() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_PROBE_STEP",
              "0.0009765625"))

current_pressure_component_max_log_scale() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_MAX_LOG_SCALE",
              "0.001953125"))

current_pressure_component_surface_cap() =
    parse(Float64, get(ENV, "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SURFACE_CAP", "2.03"))

current_pressure_component_toa_tolerance() =
    parse(Float64, get(ENV, "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_TOA_TOLERANCE", "0.0"))

current_pressure_component_min_objective_reduction() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_MIN_OBJECTIVE_REDUCTION",
              "1.0e-3"))

function current_pressure_component_ridge_lambdas()
    raw = get(ENV, "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_RIDGE_LAMBDAS",
              "1.0e-8,1.0e-6,1.0e-4,1.0e-2,1.0,100.0,1.0e4,1.0e6")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function current_pressure_component_bands(npressure, nband)
    edges = round.(Int, range(1, npressure + 1; length = nband + 1))
    return [edges[i]:(edges[i + 1] - 1) for i in 1:nband]
end

function current_four_component_scale_base(full_model)
    model = current_quadrature_linearized_base(full_model)
    for path in (
        RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER_JSON,
        RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER2_JSON,
        RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER3_JSON,
        RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER4_JSON,
    )
        deltas = current_component_scale_accepted_deltas(path)
        isempty(deltas) || (model = component_scaled_model(model, deltas))
    end
    return model
end

function pressure_component_scaled_model(base_model, deltas, bands)
    ng = size(base_model.shortwave_absorption, 1)
    nbands = length(bands)
    length(deltas) == 2 * ng * nbands ||
        throw(DimensionMismatch("pressure component vector must have 2 * ng * nbands entries"))
    model = component_scaled_model(base_model, zeros(Float64, 3ng))
    for index in eachindex(deltas)
        band_index = ((index - 1) % nbands) + 1
        local_index = fld(index - 1, nbands) + 1
        component_index = local_index <= ng ? 1 : 2
        ig = component_index == 1 ? local_index : local_index - ng
        scale = exp(clamp(deltas[index], -5.0, 5.0))
        band = bands[band_index]
        if component_index == 1
            model.shortwave_absorption[ig, :, band, :] .*= scale
        elseif length(model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[ig, band, :, :] .*= scale
        end
    end
    return model
end

function pressure_component_move(index, ng, bands, log_scale)
    nbands = length(bands)
    band_index = ((index - 1) % nbands) + 1
    local_index = fld(index - 1, nbands) + 1
    component = local_index <= ng ? "static_absorption" : "h2o_absorption"
    local_gpoint_index = local_index <= ng ? local_index : local_index - ng
    return (
        component = component,
        local_gpoint_index = local_gpoint_index,
        pressure_index_start = first(bands[band_index]),
        pressure_index_end = last(bands[band_index]),
        band_index = band_index,
        parameter_index = index,
        log_scale = log_scale,
        scale = exp(log_scale),
    )
end

function retained_current_pressure_component_optimizer_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = current_four_component_scale_base(full_model)
    base_objective, base_cases = full_hard_objective(base_model)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    base_heating_rmse = worst_heating_rmse(base_cases)
    base_residual = all_heating_profile_boundary_residual_vector(base_model)
    ng = size(base_model.shortwave_absorption, 1)
    bands = current_pressure_component_bands(
        length(base_model.pressure_grid),
        current_pressure_component_band_count(),
    )
    parameter_count = 2 * ng * length(bands)
    probe_step = current_pressure_component_probe_step()
    max_log_scale = current_pressure_component_max_log_scale()
    surface_cap = current_pressure_component_surface_cap()
    toa_tolerance = current_pressure_component_toa_tolerance()
    min_objective_reduction = current_pressure_component_min_objective_reduction()

    basis = zeros(Float64, length(base_residual), parameter_count)
    for index in 1:parameter_count
        deltas = zeros(Float64, parameter_count)
        deltas[index] = probe_step
        moved = pressure_component_scaled_model(base_model, deltas, bands)
        basis[:, index] .=
            (all_heating_profile_boundary_residual_vector(moved) .- base_residual) ./
            probe_step
    end

    rows = NamedTuple[]
    for lambda in current_pressure_component_ridge_lambdas()
        lhs = basis' * basis + lambda * I
        rhs = -(basis' * base_residual)
        raw_delta = Vector(lhs \ rhs)
        clipped_delta = clamp.(raw_delta, -max_log_scale, max_log_scale)
        model = pressure_component_scaled_model(base_model, clipped_delta, bands)
        objective, cases = full_hard_objective(model)
        toa = maximum(case.toa_forcing_max_abs for case in cases)
        surface = maximum(case.surface_forcing_max_abs for case in cases)
        heating_rmse = worst_heating_rmse(cases)
        accepted = base_objective - objective >= min_objective_reduction &&
            objective < base_objective &&
            toa <= base_toa + toa_tolerance &&
            surface <= surface_cap &&
            heating_rmse <= base_heating_rmse
        push!(rows, (
            ridge_lambda = lambda,
            raw_delta_norm = norm(raw_delta),
            clipped_delta_norm = norm(clipped_delta),
            max_abs_delta = maximum(abs, clipped_delta),
            exact_objective = objective,
            objective_reduction = base_objective - objective,
            worst_toa_forcing_error_w_m2 = toa,
            worst_surface_forcing_error_w_m2 = surface,
            worst_heating_rate_rmse_k_day = heating_rmse,
            accepted = accepted,
            deltas = collect(clipped_delta),
        ))
    end

    accepted_rows = filter(row -> row.accepted, rows)
    selected = isempty(accepted_rows) ? nothing :
        argmin(row -> row.exact_objective, accepted_rows)
    best = isempty(rows) ? nothing : argmin(row -> row.exact_objective, rows)
    accepted = selected !== nothing
    accepted_deltas = accepted ? selected.deltas : Float64[]
    accepted_moves = accepted ?
        [pressure_component_move(index, ng, bands, delta)
         for (index, delta) in enumerate(accepted_deltas) if delta != 0] :
        NamedTuple[]
    return (
        case = "reduced_ecckd_retained_current_pressure_component_optimizer",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "current_pressure_component_optimizer_improved" :
                 "current_pressure_component_optimizer_rejected",
        residual_mode = "heating_profile_boundary",
        base_mode = "current_component_scale_optimizer4_composed",
        basis = "per_gpoint_pressure_band_static_h2o_component_scales",
        basis_count = parameter_count,
        pressure_band_count = length(bands),
        probe_step = probe_step,
        max_log_scale = max_log_scale,
        surface_cap_w_m2 = surface_cap,
        toa_tolerance_w_m2 = toa_tolerance,
        min_objective_reduction = min_objective_reduction,
        base_objective = base_objective,
        base_worst_toa_forcing_error_w_m2 = base_toa,
        base_worst_surface_forcing_error_w_m2 = base_surface,
        base_worst_heating_rate_rmse_k_day = base_heating_rmse,
        best_exact_objective = best === nothing ? base_objective : best.exact_objective,
        best_objective_reduction = best === nothing ? 0.0 : best.objective_reduction,
        best_worst_toa_forcing_error_w_m2 =
            best === nothing ? base_toa : best.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            best === nothing ? base_surface : best.worst_surface_forcing_error_w_m2,
        best_worst_heating_rate_rmse_k_day =
            best === nothing ? base_heating_rmse : best.worst_heating_rate_rmse_k_day,
        accepted = accepted,
        accepted_ridge_lambda = accepted ? selected.ridge_lambda : nothing,
        accepted_objective = accepted ? selected.exact_objective : base_objective,
        accepted_objective_reduction = accepted ? selected.objective_reduction : 0.0,
        accepted_worst_toa_forcing_error_w_m2 =
            accepted ? selected.worst_toa_forcing_error_w_m2 : base_toa,
        accepted_worst_surface_forcing_error_w_m2 =
            accepted ? selected.worst_surface_forcing_error_w_m2 : base_surface,
        accepted_worst_heating_rate_rmse_k_day =
            accepted ? selected.worst_heating_rate_rmse_k_day : base_heating_rmse,
        accepted_moves = accepted_moves,
        rows = rows,
    )
end

function retained_current_pressure_component_optimizer_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Current Pressure-Component Optimizer",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Residual mode | $(result.residual_mode) |",
        "| Base mode | $(result.base_mode) |",
        "| Basis | $(result.basis) |",
        "| Basis count | $(result.basis_count) |",
        "| Pressure bands | $(result.pressure_band_count) |",
        "| Probe step | $(@sprintf("%.12g", result.probe_step)) |",
        "| Max log scale | $(@sprintf("%.12g", result.max_log_scale)) |",
        "| Surface cap | $(@sprintf("%.12g", result.surface_cap_w_m2)) W m^-2 |",
        "| TOA tolerance | $(@sprintf("%.12g", result.toa_tolerance_w_m2)) W m^-2 |",
        "| Minimum objective reduction | $(@sprintf("%.12g", result.min_objective_reduction)) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Base TOA forcing | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Base heating RMSE | $(@sprintf("%.12g", result.base_worst_heating_rate_rmse_k_day)) K day^-1 |",
        "| Best objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best TOA forcing | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Best heating RMSE | $(@sprintf("%.12g", result.best_worst_heating_rate_rmse_k_day)) K day^-1 |",
        "| Accepted | $(result.accepted) |",
        "| Accepted ridge lambda | $(component_current_metric_or_na(result.accepted_ridge_lambda)) |",
        "| Accepted objective | $(@sprintf("%.12g", result.accepted_objective)) |",
        "| Accepted TOA forcing | $(@sprintf("%.12g", result.accepted_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Accepted surface forcing | $(@sprintf("%.12g", result.accepted_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Accepted heating RMSE | $(@sprintf("%.12g", result.accepted_worst_heating_rate_rmse_k_day)) K day^-1 |",
        "| Accepted moves | $(length(result.accepted_moves)) |",
        "",
        "This diagnostic composes the current four accepted component-scale",
        "moves, then solves a pressure-band static/H2O component-scale basis",
        "against the coupled heating-profile and boundary residual.",
        "",
        "## Ridge Summary",
        "",
        "| Ridge lambda | Objective | TOA forcing | Surface forcing | Heating RMSE | Accepted |",
        "|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.rows
        push!(lines,
              "| $(@sprintf("%.12g", row.ridge_lambda)) | $(@sprintf("%.12g", row.exact_objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_surface_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_heating_rate_rmse_k_day)) | $(row.accepted) |")
    end
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ?
        retained_current_pressure_component_optimizer_result() : result
    mkpath(dirname(RETAINED_CURRENT_PRESSURE_COMPONENT_OPTIMIZER_JSON))
    write(RETAINED_CURRENT_PRESSURE_COMPONENT_OPTIMIZER_JSON,
          json_object(result) * "\n")
    write(RETAINED_CURRENT_PRESSURE_COMPONENT_OPTIMIZER_MD,
          retained_current_pressure_component_optimizer_markdown(result))
    print(retained_current_pressure_component_optimizer_markdown(result))
    println("Wrote $RETAINED_CURRENT_PRESSURE_COMPONENT_OPTIMIZER_JSON")
    println("Wrote $RETAINED_CURRENT_PRESSURE_COMPONENT_OPTIMIZER_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
