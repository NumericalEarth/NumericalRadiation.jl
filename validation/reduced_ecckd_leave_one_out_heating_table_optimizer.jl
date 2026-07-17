include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_retained_current_heating_profile_optimizer.jl"))

const LEAVE_ONE_OUT_HEATING_TABLE_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_leave_one_out_heating_table_optimizer.json")
const LEAVE_ONE_OUT_HEATING_TABLE_OPTIMIZER_MD =
    validation_results_path("reduced_ecckd_leave_one_out_heating_table_optimizer.md")
const LEAVE_ONE_OUT_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_leave_one_out_weight_refit.json")

json_get(object, key) = object[key]
json_get(object, key, default) = haskey(object, key) ? object[key] : default

loo_heating_omitted_gpoint() =
    parse(Int, get(ENV, "RH_REDUCED_LOO_HEATING_OMIT", "25"))

loo_heating_candidate_count() =
    parse(Int, get(ENV, "RH_REDUCED_LOO_HEATING_CANDIDATES", "16"))

loo_heating_probe_step() =
    parse(Float64, get(ENV, "RH_REDUCED_LOO_HEATING_PROBE_STEP", "0.00048828125"))

loo_heating_max_log_scale() =
    parse(Float64, get(ENV, "RH_REDUCED_LOO_HEATING_MAX_LOG_SCALE", "0.001953125"))

function loo_heating_ridge_lambdas()
    raw = get(ENV, "RH_REDUCED_LOO_HEATING_RIDGE_LAMBDAS",
              "1.0e-10,1.0e-8,1.0e-6,1.0e-4,1.0e-2,1.0,100.0,1.0e4")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function saved_leave_one_out_weights(prior, omitted)
    rows = json_get(prior, "rows", Any[])
    matches = filter(row -> Int(json_get(row, "omitted_gpoint")) == omitted, rows)
    isempty(matches) && error("No leave-one-out refit row for omitted g-point $omitted")
    row = only(matches)
    return Float64.(json_get(row, "refit_weights"))
end

function leave_one_out_refit_model(full_model, prior, omitted)
    indices = setdiff(collect(1:length(full_model.shortwave_weights)), [omitted])
    model = indexed_tabulated_model(full_model,
                                    collect(1:size(full_model.longwave_absorption, 1)),
                                    indices)
    model = with_shortwave_weights(model, saved_leave_one_out_weights(prior, omitted))
    return model, indices
end

function max_boundary_forcing(cases)
    return maximum(max(case.toa_forcing_max_abs, case.surface_forcing_max_abs)
                   for case in cases)
end

function single_leave_one_out_heating_table_optimizer(full_model, prior, omitted)
    base_model, indices = leave_one_out_refit_model(full_model, prior, omitted)
    base_objective, base_cases = full_hard_objective(base_model)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    base_heating_rmse = worst_heating_rmse(base_cases)
    base_boundary = max_boundary_forcing(base_cases)
    base_residual = all_heating_profile_boundary_residual_vector(base_model)

    candidate_limit = loo_heating_candidate_count()
    probe_step = loo_heating_probe_step()
    max_log_scale = loo_heating_max_log_scale()
    boundary_cap = max(ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
                       ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2)
    pool = constrained_table_probe_pool(
        all_global_active_table_entry_candidates(full_model; sw_indices = indices),
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
    for lambda in loo_heating_ridge_lambdas()
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
        boundary = max_boundary_forcing(cases)
        accepted = objective < base_objective &&
            heating_rmse <= base_heating_rmse &&
            boundary <= boundary_cap
        push!(rows, (
            ridge_lambda = lambda,
            raw_delta_norm = norm(raw_delta),
            clipped_delta_norm = norm(clipped_delta),
            exact_objective = objective,
            objective_reduction = base_objective - objective,
            worst_toa_forcing_error_w_m2 = toa,
            worst_surface_forcing_error_w_m2 = surface,
            worst_boundary_forcing_error_w_m2 = boundary,
            worst_heating_rate_rmse_k_day = heating_rmse,
            accepted = accepted,
            move_count = length(moves),
            moves = moves,
        ))
    end

    accepted_rows = filter(row -> row.accepted, rows)
    selected = isempty(accepted_rows) ? nothing : argmin(row -> row.exact_objective, accepted_rows)
    best = isempty(rows) ? nothing : argmin(row -> row.exact_objective, rows)
    accepted = selected !== nothing
    return (
        status = accepted ? "leave_one_out_heating_table_optimizer_improved" :
            "leave_one_out_heating_table_optimizer_rejected",
        omitted_gpoint = omitted,
        ng_lw = size(base_model.longwave_absorption, 1),
        ng_sw = size(base_model.shortwave_absorption, 1),
        selected_shortwave_gpoints = indices,
        candidate_count = length(candidates),
        probe_step = probe_step,
        max_log_scale = max_log_scale,
        boundary_cap_w_m2 = boundary_cap,
        base_objective = base_objective,
        base_worst_toa_forcing_error_w_m2 = base_toa,
        base_worst_surface_forcing_error_w_m2 = base_surface,
        base_worst_boundary_forcing_error_w_m2 = base_boundary,
        base_worst_heating_rate_rmse_k_day = base_heating_rmse,
        best_exact_objective = best === nothing ? base_objective : best.exact_objective,
        best_objective_reduction = best === nothing ? 0.0 : best.objective_reduction,
        best_worst_toa_forcing_error_w_m2 =
            best === nothing ? base_toa : best.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            best === nothing ? base_surface : best.worst_surface_forcing_error_w_m2,
        best_worst_boundary_forcing_error_w_m2 =
            best === nothing ? base_boundary : best.worst_boundary_forcing_error_w_m2,
        best_worst_heating_rate_rmse_k_day =
            best === nothing ? base_heating_rmse : best.worst_heating_rate_rmse_k_day,
        accepted = accepted,
        accepted_ridge_lambda = accepted ? selected.ridge_lambda : nothing,
        accepted_objective = accepted ? selected.exact_objective : base_objective,
        accepted_objective_reduction = accepted ? selected.objective_reduction : 0.0,
        accepted_worst_boundary_forcing_error_w_m2 =
            accepted ? selected.worst_boundary_forcing_error_w_m2 : base_boundary,
        accepted_worst_heating_rate_rmse_k_day =
            accepted ? selected.worst_heating_rate_rmse_k_day : base_heating_rmse,
        accepted_move_count = accepted ? selected.move_count : 0,
        accepted_moves = accepted ? selected.moves : NamedTuple[],
        rows = rows,
    )
end

function leave_one_out_heating_table_optimizer_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    prior = JSON.parsefile(LEAVE_ONE_OUT_WEIGHT_REFIT_JSON)
    omitted = loo_heating_omitted_gpoint()
    primary = single_leave_one_out_heating_table_optimizer(full_model, prior, omitted)
    best_objective_omitted = Int(json_get(prior, "best_omitted_gpoint", omitted))
    comparison_omitted = unique([omitted, best_objective_omitted])
    comparisons = [point == omitted ? primary :
                   single_leave_one_out_heating_table_optimizer(full_model, prior, point)
                   for point in comparison_omitted]
    return merge(primary, (
        case = "reduced_ecckd_leave_one_out_heating_table_optimizer",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        objective_best_omitted_gpoint = best_objective_omitted,
        comparison_omitted_gpoints = comparison_omitted,
        comparison_results = comparisons,
    ))
end

function metric_or_na(value)
    value === nothing ? "n/a" : @sprintf("%.12g", value)
end

function leave_one_out_heating_table_optimizer_markdown(result)
    lines = String[
        "# Reduced ecCKD Leave-One-Out Heating Table Optimizer",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Omitted SW g-point | $(result.omitted_gpoint) |",
        "| Candidate count | $(result.candidate_count) |",
        "| Probe step | $(@sprintf("%.12g", result.probe_step)) |",
        "| Max log scale | $(@sprintf("%.12g", result.max_log_scale)) |",
        "| Boundary cap | $(@sprintf("%.12g", result.boundary_cap_w_m2)) W m^-2 |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Base boundary forcing | $(@sprintf("%.12g", result.base_worst_boundary_forcing_error_w_m2)) W m^-2 |",
        "| Base heating RMSE | $(@sprintf("%.12g", result.base_worst_heating_rate_rmse_k_day)) K day^-1 |",
        "| Best objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best boundary forcing | $(@sprintf("%.12g", result.best_worst_boundary_forcing_error_w_m2)) W m^-2 |",
        "| Best heating RMSE | $(@sprintf("%.12g", result.best_worst_heating_rate_rmse_k_day)) K day^-1 |",
        "| Accepted | $(result.accepted) |",
        "| Accepted ridge lambda | $(metric_or_na(result.accepted_ridge_lambda)) |",
        "| Accepted objective | $(@sprintf("%.12g", result.accepted_objective)) |",
        "| Accepted boundary forcing | $(@sprintf("%.12g", result.accepted_worst_boundary_forcing_error_w_m2)) W m^-2 |",
        "| Accepted heating RMSE | $(@sprintf("%.12g", result.accepted_worst_heating_rate_rmse_k_day)) K day^-1 |",
        "| Accepted moves | $(result.accepted_move_count) |",
        "",
        "This diagnostic starts from saved 32x31 leave-one-out weight-refit",
        "models and fits local table-entry moves against the same heating-profile",
        "plus boundary residual used by the retained 16-SW heating optimizer.",
        "It accepts only an exact hard-objective improvement that keeps the",
        "TOA/surface boundary forcing below the hard 0.3 W m^-2 cap.",
        "",
        "## Compared Leave-One-Out Rows",
        "",
        "| Omitted SW g-point | Status | Base objective | Best objective | Best reduction | Base boundary | Best boundary | Base heating RMSE | Best heating RMSE | Accepted |",
        "|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.comparison_results
        push!(lines,
              "| $(row.omitted_gpoint) | $(row.status) | $(@sprintf("%.12g", row.base_objective)) | $(@sprintf("%.12g", row.best_exact_objective)) | $(@sprintf("%.12g", row.best_objective_reduction)) | $(@sprintf("%.12g", row.base_worst_boundary_forcing_error_w_m2)) | $(@sprintf("%.12g", row.best_worst_boundary_forcing_error_w_m2)) | $(@sprintf("%.12g", row.base_worst_heating_rate_rmse_k_day)) | $(@sprintf("%.12g", row.best_worst_heating_rate_rmse_k_day)) | $(row.accepted) |")
    end
    append!(lines, [
        "",
        "## Ridge Summary",
        "",
        "| Ridge lambda | Objective | TOA forcing | Surface forcing | Boundary forcing | Heating RMSE | Accepted |",
        "|---:|---:|---:|---:|---:|---:|---:|",
    ])
    for row in result.rows
        push!(lines,
              "| $(@sprintf("%.12g", row.ridge_lambda)) | $(@sprintf("%.12g", row.exact_objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_surface_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_boundary_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_heating_rate_rmse_k_day)) | $(row.accepted) |")
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = leave_one_out_heating_table_optimizer_result()
    mkpath(dirname(LEAVE_ONE_OUT_HEATING_TABLE_OPTIMIZER_JSON))
    open(LEAVE_ONE_OUT_HEATING_TABLE_OPTIMIZER_JSON, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
    write(LEAVE_ONE_OUT_HEATING_TABLE_OPTIMIZER_MD,
          leave_one_out_heating_table_optimizer_markdown(result))
    print(leave_one_out_heating_table_optimizer_markdown(result))
    println("Wrote $LEAVE_ONE_OUT_HEATING_TABLE_OPTIMIZER_JSON")
    println("Wrote $LEAVE_ONE_OUT_HEATING_TABLE_OPTIMIZER_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
