include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_retained_current_heating_profile_optimizer.jl"))

const RETAINED_CURRENT_JOINT_HEATING_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_current_joint_heating_optimizer.json")
const RETAINED_CURRENT_JOINT_HEATING_OPTIMIZER_MD =
    validation_results_path("reduced_ecckd_retained_current_joint_heating_optimizer.md")

current_joint_heating_table_candidates() =
    parse(Int, get(ENV, "RH_REDUCED_CURRENT_JOINT_HEATING_TABLE_CANDIDATES", "8"))

current_joint_heating_logit_probe_step() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_JOINT_HEATING_LOGIT_PROBE_STEP", "0.0009765625"))

current_joint_heating_table_probe_step() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_JOINT_HEATING_TABLE_PROBE_STEP", "0.00048828125"))

current_joint_heating_max_logit_delta() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_JOINT_HEATING_MAX_LOGIT_DELTA", "0.00390625"))

current_joint_heating_max_table_log_scale() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_JOINT_HEATING_MAX_TABLE_LOG_SCALE", "0.001953125"))

current_joint_heating_surface_cap() =
    parse(Float64, get(ENV, "RH_REDUCED_CURRENT_JOINT_HEATING_SURFACE_CAP", "2.03"))

current_joint_heating_toa_tolerance() =
    parse(Float64, get(ENV, "RH_REDUCED_CURRENT_JOINT_HEATING_TOA_TOLERANCE", "0.0"))

current_joint_heating_min_objective_reduction() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_JOINT_HEATING_MIN_OBJECTIVE_REDUCTION",
              "1.0e-3"))

function current_joint_heating_ridge_lambdas()
    raw = get(ENV, "RH_REDUCED_CURRENT_JOINT_HEATING_RIDGE_LAMBDAS",
              "1.0e-8,1.0e-6,1.0e-4,1.0e-2,1.0,100.0,1.0e4,1.0e6")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function with_joint_heating_update(base_model, logit_delta, table_moves)
    model = with_quadrature_logit_delta(base_model, logit_delta)
    apply_active_table_entry_moves!(model, table_moves)
    return model
end

function current_joint_heating_table_candidate_basis(full_model, base_model,
                                                     base_residual, candidate_limit,
                                                     table_probe_step)
    pool = constrained_table_probe_pool(
        all_global_active_table_entry_candidates(
            full_model;
            sw_indices = WEIGHTED_GREEDY_SW_16_INDICES,
        ),
        candidate_limit,
    )
    base_sse = dot(base_residual, base_residual)
    scored = NamedTuple[]
    for candidate in pool
        best_sse = Inf
        for direction in (-1.0, 1.0)
            moved = with_current_table_moves(
                base_model,
                [move_with_log_scale(candidate, direction * table_probe_step)],
            )
            residual = all_heating_profile_boundary_residual_vector(moved)
            best_sse = min(best_sse, dot(residual, residual))
        end
        push!(scored, (
            candidate = candidate,
            residual_sse_reduction = base_sse - best_sse,
            priority = candidate.priority,
        ))
    end
    sort!(scored; by = row -> (-row.residual_sse_reduction, -row.priority))
    return [row.candidate for row in first(scored, min(candidate_limit, length(scored)))]
end

function retained_current_joint_heating_optimizer_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = current_quadrature_linearized_base(full_model)
    base_objective, base_cases = full_hard_objective(base_model)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    base_heating_rmse = worst_heating_rmse(base_cases)
    base_residual = all_heating_profile_boundary_residual_vector(base_model)
    nweights = length(base_model.shortwave_weights)
    logit_basis_count = max(0, nweights - 1)
    table_candidate_limit = current_joint_heating_table_candidates()
    logit_probe_step = current_joint_heating_logit_probe_step()
    table_probe_step = current_joint_heating_table_probe_step()
    max_logit_delta = current_joint_heating_max_logit_delta()
    max_table_log_scale = current_joint_heating_max_table_log_scale()
    surface_cap = current_joint_heating_surface_cap()
    toa_tolerance = current_joint_heating_toa_tolerance()
    min_objective_reduction = current_joint_heating_min_objective_reduction()

    table_candidates = current_joint_heating_table_candidate_basis(
        full_model,
        base_model,
        base_residual,
        table_candidate_limit,
        table_probe_step,
    )
    basis_count = logit_basis_count + length(table_candidates)
    basis = zeros(Float64, length(base_residual), basis_count)
    for j in 1:logit_basis_count
        delta = zeros(Float64, nweights)
        delta[j] = logit_probe_step
        moved = with_quadrature_logit_delta(base_model, delta)
        basis[:, j] .=
            (all_heating_profile_boundary_residual_vector(moved) .- base_residual) ./
            logit_probe_step
    end
    for (j, candidate) in enumerate(table_candidates)
        column = logit_basis_count + j
        moved = with_current_table_moves(
            base_model,
            [move_with_log_scale(candidate, table_probe_step)],
        )
        basis[:, column] .=
            (all_heating_profile_boundary_residual_vector(moved) .- base_residual) ./
            table_probe_step
    end

    rows = NamedTuple[]
    for lambda in current_joint_heating_ridge_lambdas()
        lhs = basis' * basis + lambda * I
        rhs = -(basis' * base_residual)
        raw_delta = basis_count == 0 ? Float64[] : Vector(lhs \ rhs)
        raw_logit_delta = raw_delta[1:logit_basis_count]
        raw_table_delta = raw_delta[(logit_basis_count + 1):end]
        clipped_logit_delta = clamp.(raw_logit_delta, -max_logit_delta,
                                     max_logit_delta)
        clipped_table_delta = clamp.(raw_table_delta, -max_table_log_scale,
                                     max_table_log_scale)
        full_logit_delta = zeros(Float64, nweights)
        full_logit_delta[1:logit_basis_count] .= clipped_logit_delta
        table_moves = [move_with_log_scale(candidate, delta)
                       for (candidate, delta) in
                       zip(table_candidates, clipped_table_delta)
                       if delta != 0]
        model = with_joint_heating_update(base_model, full_logit_delta, table_moves)
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
            clipped_logit_delta_norm = norm(clipped_logit_delta),
            clipped_table_delta_norm = norm(clipped_table_delta),
            exact_objective = objective,
            objective_reduction = base_objective - objective,
            worst_toa_forcing_error_w_m2 = toa,
            worst_surface_forcing_error_w_m2 = surface,
            worst_heating_rate_rmse_k_day = heating_rmse,
            accepted = accepted,
            logit_delta = collect(full_logit_delta),
            table_moves = table_moves,
        ))
    end

    accepted_rows = filter(row -> row.accepted, rows)
    selected = isempty(accepted_rows) ? nothing : argmin(row -> row.exact_objective, accepted_rows)
    best = isempty(rows) ? nothing : argmin(row -> row.exact_objective, rows)
    accepted = selected !== nothing
    return (
        case = "reduced_ecckd_retained_current_joint_heating_optimizer",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "current_joint_heating_optimizer_improved" :
                 "current_joint_heating_optimizer_rejected",
        residual_mode = "heating_profile_boundary",
        basis = "quadrature_logits_plus_active_table_entries",
        logit_basis_count = logit_basis_count,
        table_candidate_count = length(table_candidates),
        basis_count = basis_count,
        logit_probe_step = logit_probe_step,
        table_probe_step = table_probe_step,
        max_logit_delta = max_logit_delta,
        max_table_log_scale = max_table_log_scale,
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
        accepted_logit_delta = accepted ? selected.logit_delta : Float64[],
        accepted_table_move_count = accepted ? length(selected.table_moves) : 0,
        accepted_table_moves = accepted ? selected.table_moves : NamedTuple[],
        rows = rows,
    )
end

joint_heating_metric_or_na(value) =
    value === nothing ? "n/a" : @sprintf("%.12g", value)

function retained_current_joint_heating_optimizer_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Current Joint Heating Optimizer",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Residual mode | $(result.residual_mode) |",
        "| Basis | $(result.basis) |",
        "| Logit basis count | $(result.logit_basis_count) |",
        "| Table candidate count | $(result.table_candidate_count) |",
        "| Basis count | $(result.basis_count) |",
        "| Logit probe step | $(@sprintf("%.12g", result.logit_probe_step)) |",
        "| Table probe step | $(@sprintf("%.12g", result.table_probe_step)) |",
        "| Max logit delta | $(@sprintf("%.12g", result.max_logit_delta)) |",
        "| Max table log scale | $(@sprintf("%.12g", result.max_table_log_scale)) |",
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
        "| Accepted ridge lambda | $(joint_heating_metric_or_na(result.accepted_ridge_lambda)) |",
        "| Accepted objective | $(@sprintf("%.12g", result.accepted_objective)) |",
        "| Accepted TOA forcing | $(@sprintf("%.12g", result.accepted_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Accepted surface forcing | $(@sprintf("%.12g", result.accepted_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Accepted heating RMSE | $(@sprintf("%.12g", result.accepted_worst_heating_rate_rmse_k_day)) K day^-1 |",
        "| Accepted table moves | $(result.accepted_table_move_count) |",
        "",
        "This diagnostic fits one local linear system with both shortwave",
        "quadrature-logit columns and active table-entry columns. It tests",
        "whether weight redistribution can offset the boundary regression seen",
        "in table-only heating-profile residual fits while preserving the same",
        "hard objective, TOA, surface, and heating-RMSE acceptance guards.",
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
    result = result === nothing ? retained_current_joint_heating_optimizer_result() :
        result
    mkpath(dirname(RETAINED_CURRENT_JOINT_HEATING_OPTIMIZER_JSON))
    write(RETAINED_CURRENT_JOINT_HEATING_OPTIMIZER_JSON, json_object(result) * "\n")
    write(RETAINED_CURRENT_JOINT_HEATING_OPTIMIZER_MD,
          retained_current_joint_heating_optimizer_markdown(result))
    print(retained_current_joint_heating_optimizer_markdown(result))
    println("Wrote $RETAINED_CURRENT_JOINT_HEATING_OPTIMIZER_JSON")
    println("Wrote $RETAINED_CURRENT_JOINT_HEATING_OPTIMIZER_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
