include(joinpath(@__DIR__, "validation_results.jl"))

using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_global_block_linearized_refit.jl"))
include(joinpath(@__DIR__, "reduced_ecckd_exact_weight_refit.jl"))

const JOINT_WEIGHT_BLOCK_REFIT_JSON =
    validation_results_path("reduced_ecckd_joint_weight_block_refit.json")
const JOINT_WEIGHT_BLOCK_REFIT_MD =
    validation_results_path("reduced_ecckd_joint_weight_block_refit.md")

joint_weight_block_group_limit() =
    parse(Int, get(ENV, "RH_REDUCED_JOINT_WEIGHT_BLOCK_GROUPS", "24"))

function joint_weight_block_sizes()
    raw = get(ENV, "RH_REDUCED_JOINT_WEIGHT_BLOCK_SIZES", "2,4")
    return [parse(Int, strip(token)) for token in split(raw, ",") if !isempty(strip(token))]
end

joint_weight_block_probe_step() =
    parse(Float64, get(ENV, "RH_REDUCED_JOINT_WEIGHT_BLOCK_PROBE_STEP", "0.03125"))

joint_weight_block_max_table_log_scale() =
    parse(Float64, get(ENV, "RH_REDUCED_JOINT_WEIGHT_BLOCK_MAX_TABLE_LOG_SCALE", "0.0625"))

joint_weight_block_max_weight_logit_delta() =
    parse(Float64, get(ENV, "RH_REDUCED_JOINT_WEIGHT_BLOCK_MAX_WEIGHT_LOGIT_DELTA", "0.25"))

function joint_weight_block_ridge_lambdas()
    raw = get(ENV, "RH_REDUCED_JOINT_WEIGHT_BLOCK_RIDGE_LAMBDAS",
              "1e-6,1e-4,1e-2,1,100")
    return parse.(Float64, split(raw, ","))
end

joint_weight_block_residual_mode() =
    get(ENV, "RH_REDUCED_JOINT_WEIGHT_BLOCK_RESIDUAL_MODE", "worst_metric")

function joint_weight_block_bases(candidates)
    return global_block_bases(
        candidates;
        group_limit = joint_weight_block_group_limit(),
        sizes = joint_weight_block_sizes(),
    )
end

function joint_weight_block_case(case_name)
    for case in REDUCED_CASES
        case.case == case_name && return case
    end
    error("unknown reduced case $case_name")
end

function joint_weight_block_reference(case)
    nc = require_ncdatasets()
    nc.NCDataset(reference_path(case.path)) do dataset
        return (
            sw_up = Array(dataset["sw_up"]),
            sw_down = Array(dataset["sw_down"]),
            heating_rate = Array(dataset["heating_rate"]),
        )
    end
end

function joint_weight_block_worst_metric_residual(model, breakdown)
    case = joint_weight_block_case(breakdown.worst_case)
    candidate = candidate_arrays(case.path, model)
    reference = joint_weight_block_reference(case)
    metric = breakdown.worst_metric
    if metric == "toa_forcing_max_abs"
        return ((candidate.sw_down[1, :] .- candidate.sw_up[1, :]) .-
                (reference.sw_down[1, :] .- reference.sw_up[1, :])) ./
               ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2
    elseif metric == "surface_forcing_max_abs"
        return ((candidate.sw_down[end, :] .- candidate.sw_up[end, :]) .-
                (reference.sw_down[end, :] .- reference.sw_up[end, :])) ./
               ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2
    elseif metric == "sw_up_max_abs" || metric == "sw_up_rmse"
        return vec(candidate.sw_up .- reference.sw_up) ./
               ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2
    elseif metric == "sw_down_max_abs" || metric == "sw_down_rmse"
        return vec(candidate.sw_down .- reference.sw_down) ./
               ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2
    elseif metric == "heating_rate_max_abs" || metric == "heating_rate_rmse"
        return vec(candidate.heating_rate .- reference.heating_rate) ./
               ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day
    end
    return shortwave_residual_vector(model)
end

function joint_weight_block_residual_vector(model, breakdown)
    joint_weight_block_residual_mode() == "all_shortwave" &&
        return shortwave_residual_vector(model)
    return joint_weight_block_worst_metric_residual(model, breakdown)
end

function table_moved_weighted_model(full_model, parameters, pressure_moves, active_moves,
                                    weights)
    model = pressure_band_active_table_moved_model(
        full_model,
        parameters,
        pressure_moves,
        active_moves,
    )
    model.shortwave_weights .= weights
    return model
end

function joint_weight_block_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    parameters = latest_preflight_reduced_parameters()
    parameters === nothing && error("reduced preflight parameters are required")
    pressure_moves = latest_preflight_pressure_band_table_moves()
    isempty(pressure_moves) && error("accepted pressure-band table moves are required")
    active_moves = best_available_active_table_entry_moves()

    base_model = table_moved_weighted_model(
        full_model,
        parameters,
        pressure_moves,
        active_moves,
        current_table_refined_model(full_model).shortwave_weights,
    )
    exact_refit = latest_exact_weight_refit_weights()
    exact_refit === nothing || (base_model.shortwave_weights .= exact_refit.weights)
    base_breakdown = final_objective_breakdown_from_model(
        base_model;
        method = "joint weight/block refit base breakdown",
    )
    ranked_candidates = all_slot_targeted_entry_candidates(
        full_model,
        base_breakdown.worst_case,
    )
    bases = joint_weight_block_bases(ranked_candidates)
    isempty(bases) && error("no joint weight/block bases available")

    base_logits = logits_from_weights(base_model.shortwave_weights)
    base_residual = joint_weight_block_residual_vector(base_model, base_breakdown)
    h = joint_weight_block_probe_step()
    ntable = length(bases)
    nweights = length(base_logits)
    sensitivity = zeros(Float64, length(base_residual), ntable + nweights)

    for (i, basis) in enumerate(bases)
        probe_model = table_moved_weighted_model(
            full_model,
            parameters,
            pressure_moves,
            vcat(active_moves, scaled_basis_moves(basis, h)),
            base_model.shortwave_weights,
        )
        sensitivity[:, i] .=
            (joint_weight_block_residual_vector(probe_model, base_breakdown) .-
             base_residual) ./ h
    end
    for i in eachindex(base_logits)
        probe_logits = copy(base_logits)
        probe_logits[i] += h
        probe_model = with_shortwave_weights(base_model, weights_from_logits(probe_logits))
        sensitivity[:, ntable + i] .=
            (joint_weight_block_residual_vector(probe_model, base_breakdown) .-
             base_residual) ./ h
    end

    gram = sensitivity' * sensitivity
    rhs = -(sensitivity' * base_residual)
    trials = NamedTuple[]
    for lambda in joint_weight_block_ridge_lambdas()
        raw_delta = (gram + lambda * I) \ rhs
        for direction in (1.0, -1.0)
            directed_delta = direction .* raw_delta
            table_delta = clamp.(
                directed_delta[1:ntable],
                -joint_weight_block_max_table_log_scale(),
                joint_weight_block_max_table_log_scale(),
            )
            weight_delta = clamp.(
                directed_delta[(ntable + 1):end],
                -joint_weight_block_max_weight_logit_delta(),
                joint_weight_block_max_weight_logit_delta(),
            )
            moves = reduce(vcat, [
                scaled_basis_moves(basis, delta)
                for (basis, delta) in zip(bases, table_delta)
                if abs(delta) > 1.0e-8
            ]; init = NamedTuple[])
            trial_weights = weights_from_logits(base_logits .+ weight_delta)
            candidate_model = table_moved_weighted_model(
                full_model,
                parameters,
                pressure_moves,
                vcat(active_moves, moves),
                trial_weights,
            )
            candidate_breakdown = final_objective_breakdown_from_model(
                candidate_model;
                method = "joint weight/block refit candidate breakdown",
            )
            push!(trials, (
                ridge_lambda = lambda,
                direction = direction > 0 ? "fitted" : "reversed",
                candidate_objective = candidate_breakdown.objective,
                objective_reduction =
                    base_breakdown.objective - candidate_breakdown.objective,
                table_move_count = length(moves),
                table_delta_norm = norm(table_delta),
                weight_delta_norm = norm(weight_delta),
                raw_delta_norm = norm(raw_delta),
                moves = moves,
                weights = collect(trial_weights),
                candidate_breakdown = candidate_breakdown,
            ))
        end
    end

    best_trial = argmin(trial -> trial.candidate_objective, trials)
    accepted = best_trial.candidate_objective < base_breakdown.objective
    accepted_moves = accepted ? best_trial.moves : NamedTuple[]
    final_weights = accepted ? best_trial.weights : collect(base_model.shortwave_weights)
    final_moves = vcat(active_moves, accepted_moves)

    return (
        case = "reduced_ecckd_joint_weight_block_refit",
        status = "preflight_ready",
        target_case = base_breakdown.worst_case,
        target_metric = base_breakdown.worst_metric,
        pressure_move_count = length(pressure_moves),
        starting_active_move_count = length(active_moves),
        ranked_candidate_count = length(ranked_candidates),
        basis_count = length(bases),
        group_limit = joint_weight_block_group_limit(),
        block_sizes = joint_weight_block_sizes(),
        probe_step = h,
        max_table_log_scale = joint_weight_block_max_table_log_scale(),
        max_weight_logit_delta = joint_weight_block_max_weight_logit_delta(),
        residual_mode = joint_weight_block_residual_mode(),
        ridge_lambdas = joint_weight_block_ridge_lambdas(),
        best_ridge_lambda = best_trial.ridge_lambda,
        best_direction = best_trial.direction,
        base_objective = base_breakdown.objective,
        candidate_objective = best_trial.candidate_objective,
        final_objective = accepted ? best_trial.candidate_objective : base_breakdown.objective,
        objective_reduction = best_trial.objective_reduction,
        accepted = accepted,
        accepted_move_count = length(accepted_moves),
        accepted_moves = accepted_moves,
        all_active_moves = final_moves,
        final_weights = final_weights,
        raw_delta_norm = best_trial.raw_delta_norm,
        table_delta_norm = best_trial.table_delta_norm,
        weight_delta_norm = best_trial.weight_delta_norm,
        trials = trials,
        base_breakdown = base_breakdown,
        candidate_breakdown = best_trial.candidate_breakdown,
    )
end

function joint_weight_block_markdown(result)
    lines = String[
        "# Reduced ecCKD Joint Weight/Block Refit",
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
        "| Basis count | $(result.basis_count) |",
        "| Group limit | $(result.group_limit) |",
        "| Block sizes | $(join(result.block_sizes, ", ")) |",
        "| Probe step | $(@sprintf("%.12g", result.probe_step)) |",
        "| Max table log scale | $(@sprintf("%.12g", result.max_table_log_scale)) |",
        "| Max weight logit delta | $(@sprintf("%.12g", result.max_weight_logit_delta)) |",
        "| Residual mode | $(result.residual_mode) |",
        "| Best ridge lambda | $(@sprintf("%.12g", result.best_ridge_lambda)) |",
        "| Best direction | $(result.best_direction) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Candidate objective | $(@sprintf("%.12g", result.candidate_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Accepted | $(result.accepted) |",
        "| Accepted move count | $(result.accepted_move_count) |",
        "| Raw delta norm | $(@sprintf("%.12g", result.raw_delta_norm)) |",
        "| Table delta norm | $(@sprintf("%.12g", result.table_delta_norm)) |",
        "| Weight delta norm | $(@sprintf("%.12g", result.weight_delta_norm)) |",
        "",
        "This diagnostic fits grouped active-entry table amplitudes and shortwave",
        "weight logits in one linearized least-squares system, then accepts the",
        "candidate only after a full nonlinear hard-gate evaluation.",
    ]
    return join(lines, "\n") * "\n"
end

function write_joint_weight_block_artifacts(result)
    mkpath(dirname(JOINT_WEIGHT_BLOCK_REFIT_JSON))
    write(JOINT_WEIGHT_BLOCK_REFIT_JSON, json_object(result) * "\n")
    write(JOINT_WEIGHT_BLOCK_REFIT_MD, joint_weight_block_markdown(result))
    print(joint_weight_block_markdown(result))
    println("Wrote $JOINT_WEIGHT_BLOCK_REFIT_JSON")
    println("Wrote $JOINT_WEIGHT_BLOCK_REFIT_MD")
end

function main(; result = nothing)
    write_joint_weight_block_artifacts(
        result === nothing ? joint_weight_block_refit_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
