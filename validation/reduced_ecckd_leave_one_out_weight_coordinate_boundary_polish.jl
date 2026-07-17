include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using Printf

include(joinpath(@__DIR__,
                 "reduced_ecckd_leave_one_out_weight_coordinate_descent_continuation.jl"))

const LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_JSON =
    validation_results_path("reduced_ecckd_leave_one_out_weight_coordinate_boundary_polish.json")
const LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_MD =
    validation_results_path("reduced_ecckd_leave_one_out_weight_coordinate_boundary_polish.md")

function configure_weight_coordinate_boundary_polish_defaults!()
    if !haskey(ENV, "RH_REDUCED_LOO_WEIGHT_COORDINATE_COUNT")
        ENV["RH_REDUCED_LOO_WEIGHT_COORDINATE_COUNT"] = "31"
    end
    if !haskey(ENV, "RH_REDUCED_LOO_WEIGHT_COORDINATE_LOG_SCALES")
        ENV["RH_REDUCED_LOO_WEIGHT_COORDINATE_LOG_SCALES"] =
            "0.0001,0.00031622776601683794,0.001"
    end
    if !haskey(ENV, "RH_REDUCED_LOO_WEIGHT_COORDINATE_DESCENT_ITERATIONS")
        ENV["RH_REDUCED_LOO_WEIGHT_COORDINATE_DESCENT_ITERATIONS"] = "20"
    end
    return nothing
end

function exact_weight_coordinate_boundary_polish_result()
    configure_weight_coordinate_boundary_polish_defaults!()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    prior = JSON.parsefile(LEAVE_ONE_OUT_WEIGHT_REFIT_JSON)
    seed = JSON.parsefile(LEAVE_ONE_OUT_WEIGHT_COORDINATE_DESCENT_CONTINUATION_JSON)
    omitted = Int(json_get(seed, "omitted_gpoint"))
    base_model, indices = leave_one_out_refit_model(full_model, prior, omitted)
    initial_weights = Float64[seed["final_weights"]...]
    current_weights = copy(initial_weights)
    current_metrics = weight_coordinate_metrics(with_shortwave_weights(base_model, current_weights))
    initial_metrics = current_metrics
    iterations = NamedTuple[]
    accepted_moves = NamedTuple[]
    max_iterations = weight_coordinate_descent_iterations()
    for iteration in 1:max_iterations
        step = weight_coordinate_descent_iteration(base_model, indices, current_weights,
                                                  current_metrics; iteration)
        push!(iterations, step)
        step.accepted || break
        move = step.accepted_move
        push!(accepted_moves, move)
        current_weights = scaled_normalized_weight(current_weights,
                                                   move.local_coordinate,
                                                   move.log_scale)
        current_metrics = (
            objective = move.exact_objective,
            toa = move.worst_toa_forcing_error_w_m2,
            surface = move.worst_surface_forcing_error_w_m2,
            boundary = move.worst_boundary_forcing_error_w_m2,
            heating_rmse = move.worst_heating_rate_rmse_k_day,
        )
        current_metrics.objective <= 1.0 && break
    end
    status = isempty(accepted_moves) ?
        "weight_coordinate_boundary_polish_rejected" :
        current_metrics.objective <= 1.0 ?
        "weight_coordinate_boundary_polish_passed" :
        "weight_coordinate_boundary_polish_improved"
    return (
        case = "reduced_ecckd_leave_one_out_weight_coordinate_boundary_polish",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = status,
        seed_artifact = LEAVE_ONE_OUT_WEIGHT_COORDINATE_DESCENT_CONTINUATION_JSON,
        omitted_gpoint = omitted,
        ng_lw = size(base_model.longwave_absorption, 1),
        ng_sw = size(base_model.shortwave_absorption, 1),
        selected_shortwave_gpoints = indices,
        coordinate_count = weight_coordinate_count(),
        log_scales = weight_coordinate_log_scales(),
        max_iterations = max_iterations,
        completed_iterations = length(iterations),
        accepted_move_count = length(accepted_moves),
        initial_objective = initial_metrics.objective,
        initial_worst_toa_forcing_error_w_m2 = initial_metrics.toa,
        initial_worst_surface_forcing_error_w_m2 = initial_metrics.surface,
        initial_worst_boundary_forcing_error_w_m2 = initial_metrics.boundary,
        initial_worst_heating_rate_rmse_k_day = initial_metrics.heating_rmse,
        final_objective = current_metrics.objective,
        objective_reduction = initial_metrics.objective - current_metrics.objective,
        final_worst_toa_forcing_error_w_m2 = current_metrics.toa,
        final_worst_surface_forcing_error_w_m2 = current_metrics.surface,
        final_worst_boundary_forcing_error_w_m2 = current_metrics.boundary,
        final_worst_heating_rate_rmse_k_day = current_metrics.heating_rmse,
        final_weights = collect(current_weights),
        accepted_moves = accepted_moves,
        iterations = iterations,
    )
end

function weight_coordinate_boundary_polish_markdown(result)
    lines = String[
        "# Reduced ecCKD Leave-One-Out Weight Coordinate Boundary Polish",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Omitted SW g-point | $(result.omitted_gpoint) |",
        "| Model | $(result.ng_lw)x$(result.ng_sw) |",
        "| Coordinate count | $(result.coordinate_count) |",
        "| Max iterations | $(result.max_iterations) |",
        "| Completed iterations | $(result.completed_iterations) |",
        "| Accepted moves | $(result.accepted_move_count) |",
        "| Initial objective | $(@sprintf("%.12g", result.initial_objective)) |",
        "| Final objective | $(@sprintf("%.12g", result.final_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Final TOA forcing | $(@sprintf("%.12g", result.final_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Final surface forcing | $(@sprintf("%.12g", result.final_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Final boundary forcing | $(@sprintf("%.12g", result.final_worst_boundary_forcing_error_w_m2)) W m^-2 |",
        "| Final heating RMSE | $(@sprintf("%.12g", result.final_worst_heating_rate_rmse_k_day)) K day^-1 |",
        "",
        "This diagnostic starts from the boundary-tight continuation row and",
        "uses very small normalized quadrature-weight moves. It stops once",
        "the exact hard objective reaches the pass threshold or no accepted",
        "boundary-safe descent move remains.",
        "",
        "## Iterations",
        "",
        "| Iteration | Accepted | G-point | Log scale | Objective | Reduction | Boundary forcing | Heating RMSE |",
        "|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for step in result.iterations
        if step.accepted
            move = step.accepted_move
            push!(lines,
                  "| $(step.iteration) | true | $(move.gpoint) | $(@sprintf("%.12g", move.log_scale)) | $(@sprintf("%.12g", move.exact_objective)) | $(@sprintf("%.12g", move.objective_reduction)) | $(@sprintf("%.12g", move.worst_boundary_forcing_error_w_m2)) | $(@sprintf("%.12g", move.worst_heating_rate_rmse_k_day)) |")
        else
            best = step.best_move
            push!(lines,
                  "| $(step.iteration) | false | $(best.gpoint) | $(@sprintf("%.12g", best.log_scale)) | $(@sprintf("%.12g", best.exact_objective)) | $(@sprintf("%.12g", best.objective_reduction)) | $(@sprintf("%.12g", best.worst_boundary_forcing_error_w_m2)) | $(@sprintf("%.12g", best.worst_heating_rate_rmse_k_day)) |")
        end
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = exact_weight_coordinate_boundary_polish_result()
    mkpath(dirname(LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_JSON))
    open(LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_JSON, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
    write(LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_MD,
          weight_coordinate_boundary_polish_markdown(result))
    print(weight_coordinate_boundary_polish_markdown(result))
    println("Wrote $LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_JSON")
    println("Wrote $LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
