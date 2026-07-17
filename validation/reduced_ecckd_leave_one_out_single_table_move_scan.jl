include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_leave_one_out_heating_table_optimizer.jl"))

const LEAVE_ONE_OUT_SINGLE_TABLE_MOVE_SCAN_JSON =
    validation_results_path("reduced_ecckd_leave_one_out_single_table_move_scan.json")
const LEAVE_ONE_OUT_SINGLE_TABLE_MOVE_SCAN_MD =
    validation_results_path("reduced_ecckd_leave_one_out_single_table_move_scan.md")

single_move_candidate_count() =
    parse(Int, get(ENV, "RH_REDUCED_LOO_SINGLE_MOVE_CANDIDATES", "8"))

function single_move_log_scales()
    raw = get(ENV, "RH_REDUCED_LOO_SINGLE_MOVE_LOG_SCALES",
              "0.0001220703125,0.00048828125,0.001953125")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function single_move_pressure_index_min()
    raw = strip(get(ENV, "RH_REDUCED_LOO_SINGLE_MOVE_PRESSURE_INDEX_MIN", "1"))
    isempty(raw) && return nothing
    return parse(Int, raw)
end

function single_move_pressure_index_max()
    raw = strip(get(ENV, "RH_REDUCED_LOO_SINGLE_MOVE_PRESSURE_INDEX_MAX", "8"))
    isempty(raw) && return nothing
    return parse(Int, raw)
end

function single_move_omitted_gpoint(prior)
    raw = get(ENV, "RH_REDUCED_LOO_SINGLE_MOVE_OMIT", "best")
    lowercase(strip(raw)) == "best" && return Int(json_get(prior, "best_omitted_gpoint"))
    return parse(Int, raw)
end

function pressure_window_candidates(candidates, pressure_min, pressure_max)
    return [
        candidate for candidate in candidates
        if candidate.pressure_index != 0 &&
           (pressure_min === nothing || candidate.pressure_index >= pressure_min) &&
           (pressure_max === nothing || candidate.pressure_index <= pressure_max)
    ]
end

function candidate_label(candidate)
    parts = String[]
    for name in propertynames(candidate)
        name in (:priority, :score) && continue
        value = getproperty(candidate, name)
        value isa Number || value isa AbstractString || value isa Symbol || continue
        push!(parts, "$(name)=$(value)")
    end
    return isempty(parts) ? string(candidate) : join(parts, ", ")
end

function exact_single_move_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    prior = JSON.parsefile(LEAVE_ONE_OUT_WEIGHT_REFIT_JSON)
    omitted = single_move_omitted_gpoint(prior)
    base_model, indices = leave_one_out_refit_model(full_model, prior, omitted)
    base_objective, base_cases = full_hard_objective(base_model)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    base_boundary = max_boundary_forcing(base_cases)
    base_heating_rmse = worst_heating_rmse(base_cases)
    boundary_cap = max(ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
                       ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2)
    probe_step = loo_heating_probe_step()
    candidate_limit = single_move_candidate_count()
    scales = single_move_log_scales()
    pressure_min = single_move_pressure_index_min()
    pressure_max = single_move_pressure_index_max()

    base_residual = all_heating_profile_boundary_residual_vector(base_model)
    base_sse = dot(base_residual, base_residual)
    all_candidates = all_global_active_table_entry_candidates(full_model; sw_indices = indices)
    filtered_candidates = pressure_window_candidates(all_candidates, pressure_min, pressure_max)
    isempty(filtered_candidates) && error("No candidates inside pressure-index window")
    pool = constrained_table_probe_pool(
        filtered_candidates,
        candidate_limit,
    )

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

    rows = NamedTuple[]
    for (candidate_index, candidate) in enumerate(candidates)
        for scale in scales, direction in (-1.0, 1.0)
            log_scale = direction * scale
            moved = with_current_table_moves(
                base_model,
                [move_with_log_scale(candidate, log_scale)],
            )
            objective, cases = full_hard_objective(moved)
            toa = maximum(case.toa_forcing_max_abs for case in cases)
            surface = maximum(case.surface_forcing_max_abs for case in cases)
            boundary = max_boundary_forcing(cases)
            heating_rmse = worst_heating_rmse(cases)
            accepted = objective < base_objective &&
                boundary <= boundary_cap &&
                heating_rmse <= base_heating_rmse
            push!(rows, (
                candidate_index = candidate_index,
                candidate = candidate_label(candidate),
                log_scale = log_scale,
                exact_objective = objective,
                objective_reduction = base_objective - objective,
                worst_toa_forcing_error_w_m2 = toa,
                worst_surface_forcing_error_w_m2 = surface,
                worst_boundary_forcing_error_w_m2 = boundary,
                worst_heating_rate_rmse_k_day = heating_rmse,
                accepted = accepted,
            ))
        end
    end
    sort!(rows; by = row -> (row.exact_objective, row.worst_boundary_forcing_error_w_m2))
    accepted_rows = filter(row -> row.accepted, rows)
    best = isempty(rows) ? nothing : first(rows)
    best_accepted = isempty(accepted_rows) ? nothing :
        accepted_rows[argmin([row.exact_objective for row in accepted_rows])]
    accepted = best_accepted !== nothing
    return (
        case = "reduced_ecckd_leave_one_out_single_table_move_scan",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "single_table_move_improved" : "single_table_move_rejected",
        omitted_gpoint = omitted,
        ng_lw = size(base_model.longwave_absorption, 1),
        ng_sw = size(base_model.shortwave_absorption, 1),
        selected_shortwave_gpoints = indices,
        candidate_count = length(candidates),
        exact_row_count = length(rows),
        log_scales = scales,
        pressure_index_min = pressure_min,
        pressure_index_max = pressure_max,
        boundary_cap_w_m2 = boundary_cap,
        base_objective = base_objective,
        base_worst_toa_forcing_error_w_m2 = base_toa,
        base_worst_surface_forcing_error_w_m2 = base_surface,
        base_worst_boundary_forcing_error_w_m2 = base_boundary,
        base_worst_heating_rate_rmse_k_day = base_heating_rmse,
        best_exact_objective = best === nothing ? base_objective : best.exact_objective,
        best_objective_reduction = best === nothing ? 0.0 : best.objective_reduction,
        best_worst_boundary_forcing_error_w_m2 =
            best === nothing ? base_boundary : best.worst_boundary_forcing_error_w_m2,
        best_worst_heating_rate_rmse_k_day =
            best === nothing ? base_heating_rmse : best.worst_heating_rate_rmse_k_day,
        accepted = accepted,
        accepted_objective = accepted ? best_accepted.exact_objective : base_objective,
        accepted_objective_reduction = accepted ? best_accepted.objective_reduction : 0.0,
        accepted_worst_boundary_forcing_error_w_m2 =
            accepted ? best_accepted.worst_boundary_forcing_error_w_m2 : base_boundary,
        accepted_worst_heating_rate_rmse_k_day =
            accepted ? best_accepted.worst_heating_rate_rmse_k_day : base_heating_rmse,
        accepted_move = accepted ? best_accepted : nothing,
        rows = rows,
    )
end

function single_move_scan_markdown(result)
    lines = String[
        "# Reduced ecCKD Leave-One-Out Single Table-Move Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Omitted SW g-point | $(result.omitted_gpoint) |",
        "| Model | $(result.ng_lw)x$(result.ng_sw) |",
        "| Candidate count | $(result.candidate_count) |",
        "| Exact rows | $(result.exact_row_count) |",
        "| Pressure-index min | $(result.pressure_index_min) |",
        "| Pressure-index max | $(result.pressure_index_max) |",
        "| Boundary cap | $(@sprintf("%.12g", result.boundary_cap_w_m2)) W m^-2 |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Base boundary forcing | $(@sprintf("%.12g", result.base_worst_boundary_forcing_error_w_m2)) W m^-2 |",
        "| Base heating RMSE | $(@sprintf("%.12g", result.base_worst_heating_rate_rmse_k_day)) K day^-1 |",
        "| Best objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best boundary forcing | $(@sprintf("%.12g", result.best_worst_boundary_forcing_error_w_m2)) W m^-2 |",
        "| Best heating RMSE | $(@sprintf("%.12g", result.best_worst_heating_rate_rmse_k_day)) K day^-1 |",
        "| Accepted | $(result.accepted) |",
        "| Accepted objective | $(@sprintf("%.12g", result.accepted_objective)) |",
        "| Accepted boundary forcing | $(@sprintf("%.12g", result.accepted_worst_boundary_forcing_error_w_m2)) W m^-2 |",
        "| Accepted heating RMSE | $(@sprintf("%.12g", result.accepted_worst_heating_rate_rmse_k_day)) K day^-1 |",
        "",
        "This diagnostic exact-evaluates individual local active table-entry moves",
        "on the objective-best 32x31 leave-one-out row by default. The default",
        "pressure-index window targets the upper atmosphere where the g23",
        "heating residual is localized. It is a cheap check for whether the",
        "local table basis has any one-step descent direction before trying",
        "another combined ridge step.",
        "",
        "## Best Exact Rows",
        "",
        "| Rank | Candidate | Log scale | Objective | Reduction | Boundary forcing | Heating RMSE | Accepted |",
        "|---:|---|---:|---:|---:|---:|---:|---:|",
    ]
    for (rank, row) in enumerate(first(result.rows, min(12, length(result.rows))))
        push!(lines,
              "| $(rank) | `$(row.candidate)` | $(@sprintf("%.12g", row.log_scale)) | $(@sprintf("%.12g", row.exact_objective)) | $(@sprintf("%.12g", row.objective_reduction)) | $(@sprintf("%.12g", row.worst_boundary_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_heating_rate_rmse_k_day)) | $(row.accepted) |")
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = exact_single_move_scan_result()
    mkpath(dirname(LEAVE_ONE_OUT_SINGLE_TABLE_MOVE_SCAN_JSON))
    open(LEAVE_ONE_OUT_SINGLE_TABLE_MOVE_SCAN_JSON, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
    write(LEAVE_ONE_OUT_SINGLE_TABLE_MOVE_SCAN_MD, single_move_scan_markdown(result))
    print(single_move_scan_markdown(result))
    println("Wrote $LEAVE_ONE_OUT_SINGLE_TABLE_MOVE_SCAN_JSON")
    println("Wrote $LEAVE_ONE_OUT_SINGLE_TABLE_MOVE_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
