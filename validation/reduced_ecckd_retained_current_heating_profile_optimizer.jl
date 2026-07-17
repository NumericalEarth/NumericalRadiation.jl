include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_retained_current_bounded_table_optimizer.jl"))

const RETAINED_CURRENT_HEATING_PROFILE_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_current_heating_profile_optimizer.json")
const RETAINED_CURRENT_HEATING_PROFILE_OPTIMIZER_MD =
    validation_results_path("reduced_ecckd_retained_current_heating_profile_optimizer.md")

current_heating_profile_candidates() =
    parse(Int, get(ENV, "RH_REDUCED_CURRENT_HEATING_PROFILE_CANDIDATES", "12"))

current_heating_profile_probe_step() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_HEATING_PROFILE_PROBE_STEP", "0.00048828125"))

current_heating_profile_max_log_scale() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_HEATING_PROFILE_MAX_LOG_SCALE", "0.001953125"))

current_heating_profile_surface_cap() =
    parse(Float64, get(ENV, "RH_REDUCED_CURRENT_HEATING_PROFILE_SURFACE_CAP", "2.03"))

current_heating_profile_toa_tolerance() =
    parse(Float64, get(ENV, "RH_REDUCED_CURRENT_HEATING_PROFILE_TOA_TOLERANCE", "0.0"))

current_heating_profile_min_objective_reduction() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_HEATING_PROFILE_MIN_OBJECTIVE_REDUCTION",
              "1.0e-3"))

function current_heating_profile_ridge_lambdas()
    raw = get(ENV, "RH_REDUCED_CURRENT_HEATING_PROFILE_RIDGE_LAMBDAS",
              "1.0e-8,1.0e-6,1.0e-4,1.0e-2,1.0,100.0,1.0e4,1.0e6")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function heating_profile_boundary_residual_vector(case, model)
    nc = require_ncdatasets()
    candidate = candidate_arrays(case.path, model)
    nc.NCDataset(reference_path(case.path)) do dataset
        reference = (
            lw_up = Array(dataset["lw_up"]),
            lw_down = Array(dataset["lw_down"]),
            sw_up = Array(dataset["sw_up"]),
            sw_down = Array(dataset["sw_down"]),
            heating_rate = Array(dataset["heating_rate"]),
        )
        candidate_toa = boundary_net(candidate, :toa)
        reference_toa = boundary_net(reference, :toa)
        candidate_surface = boundary_net(candidate, :surface)
        reference_surface = boundary_net(reference, :surface)
        heating = candidate.heating_rate .- reference.heating_rate
        heating_rmse_scale =
            ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day * sqrt(length(heating))
        return vcat(
            vec(heating) ./ ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
            vec(heating) ./ heating_rmse_scale,
            vec(candidate_toa .- reference_toa) ./
                ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
            vec(candidate_surface .- reference_surface) ./
                ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
        )
    end
end

function all_heating_profile_boundary_residual_vector(model)
    return vcat([heating_profile_boundary_residual_vector(case, model)
                 for case in REDUCED_CASES]...)
end

function worst_heating_rmse(cases)
    return maximum(case.variables.heating_rate.rmse for case in cases)
end

function retained_current_heating_profile_optimizer_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = current_quadrature_linearized_base(full_model)
    base_objective, base_cases = full_hard_objective(base_model)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    base_heating_rmse = worst_heating_rmse(base_cases)
    base_residual = all_heating_profile_boundary_residual_vector(base_model)
    candidate_limit = current_heating_profile_candidates()
    probe_step = current_heating_profile_probe_step()
    max_log_scale = current_heating_profile_max_log_scale()
    surface_cap = current_heating_profile_surface_cap()
    toa_tolerance = current_heating_profile_toa_tolerance()
    min_objective_reduction = current_heating_profile_min_objective_reduction()

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
                [move_with_log_scale(candidate, direction * probe_step)],
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
    candidates = [row.candidate for row in first(scored, min(candidate_limit, length(scored)))]

    basis = zeros(Float64, length(base_residual), length(candidates))
    for (j, candidate) in enumerate(candidates)
        moved = with_current_table_moves(
            base_model,
            [move_with_log_scale(candidate, probe_step)],
        )
        basis[:, j] .=
            (all_heating_profile_boundary_residual_vector(moved) .- base_residual) ./
            probe_step
    end

    rows = NamedTuple[]
    for lambda in current_heating_profile_ridge_lambdas()
        lhs = basis' * basis + lambda * I
        rhs = -(basis' * base_residual)
        raw_delta = isempty(candidates) ? Float64[] : Vector(lhs \ rhs)
        clipped_delta = clamp.(raw_delta, -max_log_scale, max_log_scale)
        moves = [move_with_log_scale(candidate, delta)
                 for (candidate, delta) in zip(candidates, clipped_delta)
                 if delta != 0]
        model = with_current_table_moves(base_model, moves)
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
            exact_objective = objective,
            objective_reduction = base_objective - objective,
            worst_toa_forcing_error_w_m2 = toa,
            worst_surface_forcing_error_w_m2 = surface,
            worst_heating_rate_rmse_k_day = heating_rmse,
            accepted = accepted,
            moves = moves,
        ))
    end

    accepted_rows = filter(row -> row.accepted, rows)
    selected = isempty(accepted_rows) ? nothing : argmin(row -> row.exact_objective, accepted_rows)
    best = isempty(rows) ? nothing : argmin(row -> row.exact_objective, rows)
    accepted = selected !== nothing
    return (
        case = "reduced_ecckd_retained_current_heating_profile_optimizer",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "current_heating_profile_optimizer_improved" :
                 "current_heating_profile_optimizer_rejected",
        residual_mode = "heating_profile_boundary",
        candidate_count = length(candidates),
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
        accepted_move_count = accepted ? length(selected.moves) : 0,
        accepted_moves = accepted ? selected.moves : NamedTuple[],
        rows = rows,
    )
end

heating_profile_metric_or_na(value) =
    value === nothing ? "n/a" : @sprintf("%.12g", value)

function retained_current_heating_profile_optimizer_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Current Heating-Profile Optimizer",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Residual mode | $(result.residual_mode) |",
        "| Candidate count | $(result.candidate_count) |",
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
        "| Accepted ridge lambda | $(heating_profile_metric_or_na(result.accepted_ridge_lambda)) |",
        "| Accepted objective | $(@sprintf("%.12g", result.accepted_objective)) |",
        "| Accepted TOA forcing | $(@sprintf("%.12g", result.accepted_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Accepted surface forcing | $(@sprintf("%.12g", result.accepted_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Accepted heating RMSE | $(@sprintf("%.12g", result.accepted_worst_heating_rate_rmse_k_day)) K day^-1 |",
        "| Accepted moves | $(result.accepted_move_count) |",
        "",
        "This diagnostic fits local active table-entry moves against a residual",
        "that combines full heating-rate profile errors with TOA and surface",
        "net-boundary errors. It exact-evaluates every ridge row and accepts",
        "only a hard-objective improvement with non-regressing TOA, capped",
        "surface forcing, and non-regressing heating-rate RMSE.",
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
    result = result === nothing ? retained_current_heating_profile_optimizer_result() :
        result
    mkpath(dirname(RETAINED_CURRENT_HEATING_PROFILE_OPTIMIZER_JSON))
    write(RETAINED_CURRENT_HEATING_PROFILE_OPTIMIZER_JSON, json_object(result) * "\n")
    write(RETAINED_CURRENT_HEATING_PROFILE_OPTIMIZER_MD,
          retained_current_heating_profile_optimizer_markdown(result))
    print(retained_current_heating_profile_optimizer_markdown(result))
    println("Wrote $RETAINED_CURRENT_HEATING_PROFILE_OPTIMIZER_JSON")
    println("Wrote $RETAINED_CURRENT_HEATING_PROFILE_OPTIMIZER_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
