include(joinpath(@__DIR__, "validation_results.jl"))

using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_gas_pressure_band_refinement.jl"))

const GAS_PRESSURE_BAND_LINEARIZED_JSON =
    validation_results_path("reduced_ecckd_gas_pressure_band_linearized_refit.json")
const GAS_PRESSURE_BAND_LINEARIZED_MD =
    validation_results_path("reduced_ecckd_gas_pressure_band_linearized_refit.md")

gas_pressure_band_linearized_candidate_count() =
    parse(Int, get(ENV, "RH_REDUCED_GAS_PRESSURE_BAND_LINEARIZED_CANDIDATES", "32"))

gas_pressure_band_linearized_probe_step() =
    parse(Float64, get(ENV, "RH_REDUCED_GAS_PRESSURE_BAND_LINEARIZED_PROBE_STEP", "0.001953125"))

gas_pressure_band_linearized_max_log_scale() =
    parse(Float64, get(ENV, "RH_REDUCED_GAS_PRESSURE_BAND_LINEARIZED_MAX_LOG_SCALE", "0.0078125"))

function gas_pressure_band_linearized_ridge_lambdas()
    raw = get(ENV, "RH_REDUCED_GAS_PRESSURE_BAND_LINEARIZED_RIDGE_LAMBDAS",
              "1e-6,1e-4,1e-2,1,100,10000")
    return parse.(Float64, split(raw, ","))
end

function gas_pressure_band_move(candidate, log_scale)
    return (
        component = candidate.component,
        local_gpoint_index = candidate.local_gpoint_index,
        gpoint = candidate.gpoint,
        gas_index = candidate.gas_index,
        pressure_index_start = candidate.pressure_index_start,
        pressure_index_end = candidate.pressure_index_end,
        log_scale = log_scale,
        scale = exp(log_scale),
        priority = candidate.priority,
    )
end

function gas_pressure_band_boundary_residual(model, target_breakdown)
    case = reduced_case_by_name(target_breakdown.worst_case)
    candidate = candidate_arrays(case.path, model)
    nc = require_ncdatasets()
    residual = nc.NCDataset(reference_path(case.path)) do dataset
        reference = (
            lw_up = Array(dataset["lw_up"]),
            lw_down = Array(dataset["lw_down"]),
            sw_up = Array(dataset["sw_up"]),
            sw_down = Array(dataset["sw_down"]),
        )
        if target_breakdown.worst_metric == "toa_forcing_max_abs"
            return (boundary_net(candidate, :toa) .- boundary_net(reference, :toa)) ./
                   ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2
        elseif target_breakdown.worst_metric == "surface_forcing_max_abs"
            return (boundary_net(candidate, :surface) .-
                    boundary_net(reference, :surface)) ./
                   ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2
        end
        return nothing
    end
    residual === nothing &&
        error("unsupported boundary metric $(target_breakdown.worst_metric)")
    return residual
end

function gas_pressure_band_linearized_model(full_model, moves)
    model = gas_pressure_band_base_model(full_model)
    apply_gas_pressure_band_moves!(model, moves)
    return model
end

function gas_pressure_band_linearized_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = gas_pressure_band_base_model(full_model)
    base_breakdown = final_objective_breakdown_from_model(
        base_model;
        method = "gas pressure-band linearized base breakdown",
    )
    target_breakdown = boundary_column_target_breakdown(base_breakdown)
    worst_column = boundary_column_worst_column(base_model, target_breakdown)
    candidates = collect(Iterators.take(
        gas_pressure_band_candidates(
            full_model,
            base_model,
            target_breakdown,
            worst_column,
        ),
        gas_pressure_band_linearized_candidate_count(),
    ))
    isempty(candidates) && error("no gas pressure-band candidates available")

    base_residual = gas_pressure_band_boundary_residual(base_model, target_breakdown)
    h = gas_pressure_band_linearized_probe_step()
    sensitivity = zeros(Float64, length(base_residual), length(candidates))
    for (i, candidate) in enumerate(candidates)
        model = gas_pressure_band_linearized_model(
            full_model,
            [gas_pressure_band_move(candidate, h)],
        )
        sensitivity[:, i] .=
            (gas_pressure_band_boundary_residual(model, target_breakdown) .-
             base_residual) ./ h
    end

    gram = sensitivity' * sensitivity
    rhs = -(sensitivity' * base_residual)
    max_log_scale = gas_pressure_band_linearized_max_log_scale()
    trials = NamedTuple[]
    for lambda in gas_pressure_band_linearized_ridge_lambdas()
        raw_delta = (gram + lambda * I) \ rhs
        for direction in (1.0, -1.0)
            delta = clamp.(direction .* raw_delta, -max_log_scale, max_log_scale)
            moves = [
                gas_pressure_band_move(candidate, value)
                for (candidate, value) in zip(candidates, delta)
                if abs(value) > 1.0e-10
            ]
            model = gas_pressure_band_linearized_model(full_model, moves)
            breakdown = final_objective_breakdown_from_model(
                model;
                method = "gas pressure-band linearized candidate breakdown",
            )
            push!(trials, (
                ridge_lambda = lambda,
                direction = direction > 0 ? "fitted" : "reversed",
                candidate_objective = breakdown.objective,
                objective_reduction = base_breakdown.objective - breakdown.objective,
                move_count = length(moves),
                raw_delta_norm = norm(raw_delta),
                clamped_delta_norm = norm(delta),
                moves = moves,
                candidate_breakdown = breakdown,
            ))
        end
    end
    best = argmin(trial -> trial.candidate_objective, trials)
    accepted = best.candidate_objective < base_breakdown.objective
    accepted_moves = accepted ? best.moves : NamedTuple[]
    existing_moves = latest_gas_pressure_band_refinement_moves()
    return (
        case = "reduced_ecckd_gas_pressure_band_linearized_refit",
        status = "preflight_ready",
        target_case = target_breakdown.worst_case,
        target_metric = target_breakdown.worst_metric,
        target_boundary = worst_column.boundary,
        target_column = worst_column.column,
        target_residual_w_m2 = worst_column.residual_w_m2,
        fitted_candidate_count = length(candidates),
        probe_step = h,
        max_log_scale = max_log_scale,
        ridge_lambdas = gas_pressure_band_linearized_ridge_lambdas(),
        best_ridge_lambda = best.ridge_lambda,
        best_direction = best.direction,
        base_objective = base_breakdown.objective,
        candidate_objective = best.candidate_objective,
        final_objective =
            accepted ? best.candidate_objective : base_breakdown.objective,
        objective_reduction = best.objective_reduction,
        accepted = accepted,
        accepted_move_count = length(accepted_moves),
        accepted_moves = accepted_moves,
        all_moves = vcat(existing_moves, accepted_moves),
        raw_delta_norm = best.raw_delta_norm,
        clamped_delta_norm = best.clamped_delta_norm,
        trials = trials,
        base_breakdown = base_breakdown,
        target_breakdown = target_breakdown,
        candidate_breakdown = best.candidate_breakdown,
    )
end

function gas_pressure_band_linearized_markdown(result)
    lines = String[
        "# Reduced ecCKD Gas Pressure-Band Linearized Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Target case | $(result.target_case) |",
        "| Target metric | $(result.target_metric) |",
        "| Target boundary | $(result.target_boundary) |",
        "| Target column | $(result.target_column) |",
        "| Target residual | $(@sprintf("%.12g", result.target_residual_w_m2)) W m^-2 |",
        "| Fitted candidates | $(result.fitted_candidate_count) |",
        "| Probe step | $(@sprintf("%.12g", result.probe_step)) |",
        "| Max log scale | $(@sprintf("%.12g", result.max_log_scale)) |",
        "| Best ridge lambda | $(@sprintf("%.12g", result.best_ridge_lambda)) |",
        "| Best direction | $(result.best_direction) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Candidate objective | $(@sprintf("%.12g", result.candidate_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Accepted | $(result.accepted) |",
        "| Accepted move count | $(result.accepted_move_count) |",
        "| Raw delta norm | $(@sprintf("%.12g", result.raw_delta_norm)) |",
        "| Clamped delta norm | $(@sprintf("%.12g", result.clamped_delta_norm)) |",
        "",
        "This diagnostic solves a ridge-regularized linearized update over",
        "gas-specific pressure-band scales for the current worst boundary",
        "residual, then accepts only after full nonlinear hard-gate evaluation.",
    ]
    return join(lines, "\n") * "\n"
end

function write_gas_pressure_band_linearized_artifacts(result)
    mkpath(dirname(GAS_PRESSURE_BAND_LINEARIZED_JSON))
    write(GAS_PRESSURE_BAND_LINEARIZED_JSON, json_object(result) * "\n")
    write(GAS_PRESSURE_BAND_LINEARIZED_MD, gas_pressure_band_linearized_markdown(result))
    print(gas_pressure_band_linearized_markdown(result))
    println("Wrote $GAS_PRESSURE_BAND_LINEARIZED_JSON")
    println("Wrote $GAS_PRESSURE_BAND_LINEARIZED_MD")
end

function main(; result = nothing)
    write_gas_pressure_band_linearized_artifacts(
        result === nothing ? gas_pressure_band_linearized_refit_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
