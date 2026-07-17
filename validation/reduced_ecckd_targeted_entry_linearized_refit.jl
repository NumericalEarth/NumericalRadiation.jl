include(joinpath(@__DIR__, "validation_results.jl"))

using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_optimization_preflight.jl"))

const TARGETED_LINEARIZED_JSON =
    validation_results_path("reduced_ecckd_targeted_entry_linearized_refit.json")
const TARGETED_LINEARIZED_MD =
    validation_results_path("reduced_ecckd_targeted_entry_linearized_refit.md")

linearized_candidate_count() =
    parse(Int, get(ENV, "RH_REDUCED_LINEARIZED_ENTRY_CANDIDATES", "16"))

linearized_probe_step() =
    parse(Float64, get(ENV, "RH_REDUCED_LINEARIZED_ENTRY_PROBE_STEP", "0.0625"))

linearized_max_log_scale() =
    parse(Float64, get(ENV, "RH_REDUCED_LINEARIZED_ENTRY_MAX_LOG_SCALE", "0.25"))

function linearized_ridge_lambdas()
    text = get(ENV, "RH_REDUCED_LINEARIZED_ENTRY_RIDGE_LAMBDAS",
               "1e-6,1e-4,1e-2,1,100")
    return parse.(Float64, split(text, ","))
end

function shortwave_reference_arrays(case)
    nc = require_ncdatasets()
    nc.NCDataset(reference_path(case.path)) do dataset
        return (
            sw_up = Array(dataset["sw_up"]),
            sw_down = Array(dataset["sw_down"]),
            heating_rate = Array(dataset["heating_rate"]),
        )
    end
end

function shortwave_residual_vector(model)
    blocks = Vector{Float64}[]
    for case in REDUCED_CASES
        candidate = candidate_arrays(case.path, model)
        reference = shortwave_reference_arrays(case)
        candidate_toa = candidate.sw_down[1, :] .- candidate.sw_up[1, :]
        reference_toa = reference.sw_down[1, :] .- reference.sw_up[1, :]
        candidate_surface = candidate.sw_down[end, :] .- candidate.sw_up[end, :]
        reference_surface = reference.sw_down[end, :] .- reference.sw_up[end, :]
        push!(blocks, vcat(
            vec(candidate.sw_up .- reference.sw_up) ./
                ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
            vec(candidate.sw_down .- reference.sw_down) ./
                ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
            vec(candidate.heating_rate .- reference.heating_rate) ./
                ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
            vec(candidate_toa .- reference_toa) ./
                ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
            vec(candidate_surface .- reference_surface) ./
                ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
        ))
    end
    return vcat(blocks...)
end

function active_entry_move_from_candidate(candidate, log_scale)
    return (
        component = candidate.component,
        local_gpoint_index = candidate.local_gpoint_index,
        gpoint = candidate.gpoint,
        gas_index = candidate.gas_index,
        pressure_index = candidate.pressure_index,
        temperature_index = candidate.temperature_index,
        h2o_index = candidate.h2o_index,
        log_scale = log_scale,
        scale = exp(log_scale),
    )
end

function targeted_linearized_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    parameters = latest_preflight_reduced_parameters()
    parameters === nothing && error("reduced preflight parameters are required")
    pressure_moves = latest_preflight_pressure_band_table_moves()
    isempty(pressure_moves) && error("accepted pressure-band table moves are required")

    breakdown = final_objective_breakdown(full_model, parameters)
    ranked_candidates = targeted_active_table_entry_candidates(
        full_model,
        pressure_moves,
        breakdown.worst_case,
    )
    candidates = collect(Iterators.take(ranked_candidates, linearized_candidate_count()))
    isempty(candidates) && error("no targeted entry candidates available")

    base_model = pressure_band_active_table_moved_model(
        full_model,
        parameters,
        pressure_moves,
        NamedTuple[],
    )
    base_residual = shortwave_residual_vector(base_model)
    h = linearized_probe_step()
    sensitivity = zeros(Float64, length(base_residual), length(candidates))
    for (i, candidate) in enumerate(candidates)
        probe_move = active_entry_move_from_candidate(candidate, h)
        probe_model = pressure_band_active_table_moved_model(
            full_model,
            parameters,
            pressure_moves,
            [probe_move],
        )
        sensitivity[:, i] .= (shortwave_residual_vector(probe_model) .- base_residual) ./ h
    end

    max_log_scale = linearized_max_log_scale()
    base_breakdown = final_objective_breakdown_from_model(
        base_model;
        method = "linearized targeted entry refit base breakdown",
    )
    gram = sensitivity' * sensitivity
    rhs = -(sensitivity' * base_residual)
    trials = NamedTuple[]
    for lambda in linearized_ridge_lambdas()
        raw_delta = (gram + lambda * I) \ rhs
        clamped_delta = clamp.(raw_delta, -max_log_scale, max_log_scale)
        moves = [
            active_entry_move_from_candidate(candidate, delta)
            for (candidate, delta) in zip(candidates, clamped_delta)
            if abs(delta) > 1.0e-8
        ]
        candidate_model = pressure_band_active_table_moved_model(
            full_model,
            parameters,
            pressure_moves,
            moves,
        )
        candidate_breakdown = final_objective_breakdown_from_model(
            candidate_model;
            method = "linearized targeted entry refit candidate breakdown",
        )
        push!(trials, (
            ridge_lambda = lambda,
            candidate_objective = candidate_breakdown.objective,
            objective_reduction = base_breakdown.objective - candidate_breakdown.objective,
            move_count = length(moves),
            raw_delta_norm = norm(raw_delta),
            clamped_delta_norm = norm(clamped_delta),
            moves = moves,
            candidate_breakdown = candidate_breakdown,
        ))
    end
    best_trial = argmin(trial -> trial.candidate_objective, trials)
    accepted = best_trial.candidate_objective < base_breakdown.objective
    accepted_moves = accepted ? best_trial.moves : NamedTuple[]

    return (
        case = "reduced_ecckd_targeted_entry_linearized_refit",
        status = "preflight_ready",
        target_case = breakdown.worst_case,
        target_metric = breakdown.worst_metric,
        pressure_move_count = length(pressure_moves),
        ranked_candidate_count = length(ranked_candidates),
        fitted_candidate_count = length(candidates),
        probe_step = h,
        max_log_scale = max_log_scale,
        ridge_lambdas = linearized_ridge_lambdas(),
        best_ridge_lambda = best_trial.ridge_lambda,
        base_objective = base_breakdown.objective,
        candidate_objective = best_trial.candidate_objective,
        objective_reduction = best_trial.objective_reduction,
        accepted = accepted,
        accepted_move_count = length(accepted_moves),
        accepted_moves = accepted_moves,
        raw_delta_norm = best_trial.raw_delta_norm,
        clamped_delta_norm = best_trial.clamped_delta_norm,
        trials = trials,
        base_breakdown = base_breakdown,
        candidate_breakdown = best_trial.candidate_breakdown,
    )
end

function targeted_linearized_markdown(result)
    lines = String[
        "# Reduced ecCKD Targeted Entry Linearized Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Target case | $(result.target_case) |",
        "| Target metric | $(result.target_metric) |",
        "| Pressure move count | $(result.pressure_move_count) |",
        "| Ranked candidate count | $(result.ranked_candidate_count) |",
        "| Fitted candidate count | $(result.fitted_candidate_count) |",
        "| Probe step | $(@sprintf("%.12g", result.probe_step)) |",
        "| Max log scale | $(@sprintf("%.12g", result.max_log_scale)) |",
        "| Best ridge lambda | $(@sprintf("%.12g", result.best_ridge_lambda)) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Candidate objective | $(@sprintf("%.12g", result.candidate_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Accepted | $(result.accepted) |",
        "| Accepted move count | $(result.accepted_move_count) |",
        "| Raw delta norm | $(@sprintf("%.12g", result.raw_delta_norm)) |",
        "| Clamped delta norm | $(@sprintf("%.12g", result.clamped_delta_norm)) |",
        "",
        "This diagnostic fits a joint linearized update over the highest-priority",
        "active table entries. The update is accepted only if the full hard-gate",
        "objective improves after evaluating the nonlinear model.",
    ]
    return join(lines, "\n") * "\n"
end

function write_targeted_linearized_artifacts(result)
    mkpath(dirname(TARGETED_LINEARIZED_JSON))
    write(TARGETED_LINEARIZED_JSON, json_object(result) * "\n")
    write(TARGETED_LINEARIZED_MD, targeted_linearized_markdown(result))
    print(targeted_linearized_markdown(result))
    println("Wrote $TARGETED_LINEARIZED_JSON")
    println("Wrote $TARGETED_LINEARIZED_MD")
end

function main(; result = nothing)
    write_targeted_linearized_artifacts(
        result === nothing ? targeted_linearized_refit_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
