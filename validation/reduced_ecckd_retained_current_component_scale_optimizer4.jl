include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_retained_current_component_scale_optimizer3.jl"))

const RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER4_JSON =
    validation_results_path("reduced_ecckd_retained_current_component_scale_optimizer4.json")
const RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER4_MD =
    validation_results_path("reduced_ecckd_retained_current_component_scale_optimizer4.md")

component_scale4_max_log_scale() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_COMPONENT_SCALE4_MAX_LOG_SCALE",
              "0.000244140625"))

component_scale4_min_objective_reduction() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_COMPONENT_SCALE4_MIN_OBJECTIVE_REDUCTION",
              "1.25e-4"))

function retained_current_component_scale_optimizer4_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = current_quadrature_linearized_base(full_model)
    predecessor_delta_counts = Int[]
    for path in (
        RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER_JSON,
        RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER2_JSON,
        RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER3_JSON,
    )
        deltas = current_component_scale_accepted_deltas(path)
        push!(predecessor_delta_counts, length(deltas))
        isempty(deltas) || (base_model = component_scaled_model(base_model, deltas))
    end

    base_objective, base_cases = full_hard_objective(base_model)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    base_heating_rmse = worst_heating_rmse(base_cases)
    base_residual = all_heating_profile_boundary_residual_vector(base_model)
    ng = size(base_model.shortwave_absorption, 1)
    parameter_count = 3ng
    probe_step = current_component_scale_probe_step()
    max_log_scale = component_scale4_max_log_scale()
    surface_cap = current_component_scale_surface_cap()
    toa_tolerance = current_component_scale_toa_tolerance()
    min_objective_reduction = component_scale4_min_objective_reduction()

    basis = zeros(Float64, length(base_residual), parameter_count)
    for index in 1:parameter_count
        deltas = zeros(Float64, parameter_count)
        deltas[index] = probe_step
        moved = component_scaled_model(base_model, deltas)
        basis[:, index] .=
            (all_heating_profile_boundary_residual_vector(moved) .- base_residual) ./
            probe_step
    end

    rows = NamedTuple[]
    for lambda in current_component_scale_ridge_lambdas()
        lhs = basis' * basis + lambda * I
        rhs = -(basis' * base_residual)
        raw_delta = Vector(lhs \ rhs)
        clipped_delta = clamp.(raw_delta, -max_log_scale, max_log_scale)
        model = component_scaled_model(base_model, clipped_delta)
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
    return (
        case = "reduced_ecckd_retained_current_component_scale_optimizer4",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "current_component_scale_optimizer4_improved" :
                 "current_component_scale_optimizer4_rejected",
        residual_mode = "heating_profile_boundary",
        base_mode = "current_component_scale_optimizer3_composed",
        basis = "fourth_pass_per_gpoint_static_h2o_rayleigh_component_scales",
        basis_count = parameter_count,
        predecessor_delta_counts = predecessor_delta_counts,
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
        accepted_deltas = accepted ? selected.deltas : Float64[],
        rows = rows,
    )
end

function retained_current_component_scale_optimizer4_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Current Component-Scale Optimizer 4",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Residual mode | $(result.residual_mode) |",
        "| Base mode | $(result.base_mode) |",
        "| Basis | $(result.basis) |",
        "| Basis count | $(result.basis_count) |",
        "| Predecessor delta counts | $(join(result.predecessor_delta_counts, ", ")) |",
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
        "",
        "This diagnostic composes the first three accepted component-scale moves,",
        "then tests whether the same low-rank parameter family still has a",
        "smaller cap-safe improving direction on the updated current base.",
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
        retained_current_component_scale_optimizer4_result() : result
    mkpath(dirname(RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER4_JSON))
    write(RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER4_JSON, json_object(result) * "\n")
    write(RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER4_MD,
          retained_current_component_scale_optimizer4_markdown(result))
    print(retained_current_component_scale_optimizer4_markdown(result))
    println("Wrote $RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER4_JSON")
    println("Wrote $RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER4_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
