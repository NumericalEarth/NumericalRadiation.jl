include(joinpath(@__DIR__, "validation_results.jl"))

using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_global_entry_refinement.jl"))
include(joinpath(@__DIR__, "reduced_ecckd_targeted_entry_linearized_refit.jl"))

const GLOBAL_LINEARIZED_JSON =
    validation_results_path("reduced_ecckd_global_entry_linearized_refit.json")
const GLOBAL_LINEARIZED_MD =
    validation_results_path("reduced_ecckd_global_entry_linearized_refit.md")

global_linearized_candidate_count() =
    parse(Int, get(ENV, "RH_REDUCED_GLOBAL_LINEARIZED_ENTRY_CANDIDATES", "24"))

function global_linearized_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    parameters = latest_preflight_reduced_parameters()
    parameters === nothing && error("reduced preflight parameters are required")
    pressure_moves = latest_preflight_pressure_band_table_moves()
    isempty(pressure_moves) && error("accepted pressure-band table moves are required")
    active_moves = best_available_active_table_entry_moves()

    base_model = pressure_band_active_table_moved_model(
        full_model,
        parameters,
        pressure_moves,
        active_moves,
    )
    base_breakdown = final_objective_breakdown_from_model(
        base_model;
        method = "global linearized entry refit base breakdown",
    )
    ranked_candidates = all_slot_targeted_entry_candidates(
        full_model,
        base_breakdown.worst_case,
    )
    candidates = collect(Iterators.take(ranked_candidates,
                                        global_linearized_candidate_count()))
    isempty(candidates) && error("no global entry candidates available")

    base_residual = shortwave_residual_vector(base_model)
    h = linearized_probe_step()
    sensitivity = zeros(Float64, length(base_residual), length(candidates))
    for (i, candidate) in enumerate(candidates)
        probe_move = active_entry_move_from_candidate(candidate, h)
        probe_model = pressure_band_active_table_moved_model(
            full_model,
            parameters,
            pressure_moves,
            vcat(active_moves, [probe_move]),
        )
        sensitivity[:, i] .= (shortwave_residual_vector(probe_model) .- base_residual) ./ h
    end

    max_log_scale = linearized_max_log_scale()
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
            vcat(active_moves, moves),
        )
        candidate_breakdown = final_objective_breakdown_from_model(
            candidate_model;
            method = "global linearized entry refit candidate breakdown",
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
        case = "reduced_ecckd_global_entry_linearized_refit",
        status = "preflight_ready",
        target_case = base_breakdown.worst_case,
        target_metric = base_breakdown.worst_metric,
        pressure_move_count = length(pressure_moves),
        starting_active_move_count = length(active_moves),
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

function global_linearized_markdown(result)
    lines = String[
        "# Reduced ecCKD Global Entry Linearized Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Target case | $(result.target_case) |",
        "| Target metric | $(result.target_metric) |",
        "| Pressure move count | $(result.pressure_move_count) |",
        "| Starting active move count | $(result.starting_active_move_count) |",
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
        "This diagnostic starts from the best available pressure/table-active",
        "state and fits a joint linearized update over the highest-priority",
        "all-slot active table entries. The update is accepted only if the full",
        "hard-gate objective improves after evaluating the nonlinear model.",
    ]
    return join(lines, "\n") * "\n"
end

function write_global_linearized_artifacts(result)
    mkpath(dirname(GLOBAL_LINEARIZED_JSON))
    write(GLOBAL_LINEARIZED_JSON, json_object(result) * "\n")
    write(GLOBAL_LINEARIZED_MD, global_linearized_markdown(result))
    print(global_linearized_markdown(result))
    println("Wrote $GLOBAL_LINEARIZED_JSON")
    println("Wrote $GLOBAL_LINEARIZED_MD")
end

function main(; result = nothing)
    write_global_linearized_artifacts(
        result === nothing ? global_linearized_refit_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
