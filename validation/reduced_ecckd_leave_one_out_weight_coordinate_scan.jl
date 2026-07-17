include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_leave_one_out_heating_table_optimizer.jl"))

const LEAVE_ONE_OUT_WEIGHT_COORDINATE_SCAN_JSON =
    validation_results_path("reduced_ecckd_leave_one_out_weight_coordinate_scan.json")
const LEAVE_ONE_OUT_WEIGHT_COORDINATE_SCAN_MD =
    validation_results_path("reduced_ecckd_leave_one_out_weight_coordinate_scan.md")

weight_coordinate_omitted_gpoint(prior) =
    lowercase(strip(get(ENV, "RH_REDUCED_LOO_WEIGHT_COORDINATE_OMIT", "best"))) == "best" ?
    Int(json_get(prior, "best_omitted_gpoint")) :
    parse(Int, get(ENV, "RH_REDUCED_LOO_WEIGHT_COORDINATE_OMIT", "best"))

weight_coordinate_count() =
    parse(Int, get(ENV, "RH_REDUCED_LOO_WEIGHT_COORDINATE_COUNT", "16"))

function weight_coordinate_log_scales()
    raw = get(ENV, "RH_REDUCED_LOO_WEIGHT_COORDINATE_LOG_SCALES",
              "0.001,0.0031622776601683794,0.01,0.03162277660168379")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function scaled_normalized_weight(weights, coordinate, log_scale)
    moved = copy(weights)
    moved[coordinate] *= exp(log_scale)
    total = sum(moved)
    total > 0 || error("nonpositive moved weight total")
    return moved ./ total
end

function exact_weight_coordinate_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    prior = JSON.parsefile(LEAVE_ONE_OUT_WEIGHT_REFIT_JSON)
    omitted = weight_coordinate_omitted_gpoint(prior)
    base_model, indices = leave_one_out_refit_model(full_model, prior, omitted)
    base_weights = collect(base_model.shortwave_weights)
    base_objective, base_cases = full_hard_objective(base_model)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    base_boundary = max_boundary_forcing(base_cases)
    base_heating_rmse = worst_heating_rmse(base_cases)
    boundary_cap = max(ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
                       ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2)
    coordinate_order = sortperm(base_weights; rev = true)
    coordinates = first(coordinate_order, min(weight_coordinate_count(), length(coordinate_order)))
    log_scales = weight_coordinate_log_scales()

    rows = NamedTuple[]
    for coordinate in coordinates, scale in log_scales, direction in (-1.0, 1.0)
        log_scale = direction * scale
        weights = scaled_normalized_weight(base_weights, coordinate, log_scale)
        model = with_shortwave_weights(base_model, weights)
        objective, cases = full_hard_objective(model)
        toa = maximum(case.toa_forcing_max_abs for case in cases)
        surface = maximum(case.surface_forcing_max_abs for case in cases)
        boundary = max_boundary_forcing(cases)
        heating_rmse = worst_heating_rmse(cases)
        accepted = objective < base_objective &&
            boundary <= boundary_cap &&
            heating_rmse <= base_heating_rmse
        push!(rows, (
            local_coordinate = coordinate,
            gpoint = indices[coordinate],
            base_weight = base_weights[coordinate],
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
    sort!(rows; by = row -> (row.exact_objective, row.worst_boundary_forcing_error_w_m2))
    accepted_rows = filter(row -> row.accepted, rows)
    best = isempty(rows) ? nothing : first(rows)
    best_accepted = isempty(accepted_rows) ? nothing :
        accepted_rows[argmin([row.exact_objective for row in accepted_rows])]
    accepted = best_accepted !== nothing
    return (
        case = "reduced_ecckd_leave_one_out_weight_coordinate_scan",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "weight_coordinate_scan_improved" :
            "weight_coordinate_scan_rejected",
        omitted_gpoint = omitted,
        ng_lw = size(base_model.longwave_absorption, 1),
        ng_sw = size(base_model.shortwave_absorption, 1),
        selected_shortwave_gpoints = indices,
        coordinate_count = length(coordinates),
        exact_row_count = length(rows),
        log_scales = log_scales,
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

function weight_coordinate_scan_markdown(result)
    lines = String[
        "# Reduced ecCKD Leave-One-Out Weight Coordinate Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Omitted SW g-point | $(result.omitted_gpoint) |",
        "| Model | $(result.ng_lw)x$(result.ng_sw) |",
        "| Coordinate count | $(result.coordinate_count) |",
        "| Exact rows | $(result.exact_row_count) |",
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
        "This diagnostic exact-evaluates normalized one-coordinate weight moves",
        "around the objective-best 32x31 leave-one-out weight-refit row. It",
        "tests whether the approximate hard-gate weight refit left any simple",
        "exact descent direction before changing support.",
        "",
        "## Best Exact Rows",
        "",
        "| Rank | G-point | Base weight | Log scale | Objective | Reduction | Boundary forcing | Heating RMSE | Accepted |",
        "|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for (rank, row) in enumerate(first(result.rows, min(12, length(result.rows))))
        push!(lines,
              "| $(rank) | $(row.gpoint) | $(@sprintf("%.12g", row.base_weight)) | $(@sprintf("%.12g", row.log_scale)) | $(@sprintf("%.12g", row.exact_objective)) | $(@sprintf("%.12g", row.objective_reduction)) | $(@sprintf("%.12g", row.worst_boundary_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_heating_rate_rmse_k_day)) | $(row.accepted) |")
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = exact_weight_coordinate_scan_result()
    mkpath(dirname(LEAVE_ONE_OUT_WEIGHT_COORDINATE_SCAN_JSON))
    open(LEAVE_ONE_OUT_WEIGHT_COORDINATE_SCAN_JSON, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
    write(LEAVE_ONE_OUT_WEIGHT_COORDINATE_SCAN_MD,
          weight_coordinate_scan_markdown(result))
    print(weight_coordinate_scan_markdown(result))
    println("Wrote $LEAVE_ONE_OUT_WEIGHT_COORDINATE_SCAN_JSON")
    println("Wrote $LEAVE_ONE_OUT_WEIGHT_COORDINATE_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
