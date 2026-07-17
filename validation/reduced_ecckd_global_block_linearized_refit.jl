include(joinpath(@__DIR__, "validation_results.jl"))

using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_global_block_refinement.jl"))
include(joinpath(@__DIR__, "reduced_ecckd_targeted_entry_linearized_refit.jl"))

const GLOBAL_BLOCK_LINEARIZED_JSON =
    validation_results_path("reduced_ecckd_global_block_linearized_refit.json")
const GLOBAL_BLOCK_LINEARIZED_MD =
    validation_results_path("reduced_ecckd_global_block_linearized_refit.md")

global_block_linearized_group_limit() =
    parse(Int, get(ENV, "RH_REDUCED_GLOBAL_BLOCK_LINEARIZED_GROUPS", "12"))

function global_block_linearized_sizes()
    raw = get(ENV, "RH_REDUCED_GLOBAL_BLOCK_LINEARIZED_SIZES", "2,4")
    return [parse(Int, strip(token)) for token in split(raw, ",") if !isempty(strip(token))]
end

global_block_linearized_probe_step() =
    parse(Float64, get(ENV, "RH_REDUCED_GLOBAL_BLOCK_LINEARIZED_PROBE_STEP", "0.0625"))

global_block_linearized_max_log_scale() =
    parse(Float64, get(ENV, "RH_REDUCED_GLOBAL_BLOCK_LINEARIZED_MAX_LOG_SCALE", "0.25"))

function global_block_linearized_ridge_lambdas()
    text = get(ENV, "RH_REDUCED_GLOBAL_BLOCK_LINEARIZED_RIDGE_LAMBDAS",
               "1e-6,1e-4,1e-2,1,100")
    return parse.(Float64, split(text, ","))
end

function global_block_bases(candidates;
                            group_limit = global_block_linearized_group_limit(),
                            sizes = global_block_linearized_sizes())
    bases = NamedTuple[]
    for block in grouped_global_entry_blocks(candidates; group_limit)
        for block_size in sizes
            selected_count = min(block_size, length(block.entries))
            selected_count == 0 && continue
            push!(bases, (
                component = block.component,
                local_gpoint_index = block.local_gpoint_index,
                gpoint = block.gpoint,
                gas_index = block.gas_index,
                group_priority = block.priority,
                block_size = selected_count,
                basis_moves = block_moves(block, selected_count, 1.0),
            ))
        end
    end
    return bases
end

function scaled_basis_moves(basis, log_scale)
    return [
        (
            component = move.component,
            local_gpoint_index = move.local_gpoint_index,
            gpoint = move.gpoint,
            gas_index = move.gas_index,
            pressure_index = move.pressure_index,
            temperature_index = move.temperature_index,
            h2o_index = move.h2o_index,
            log_scale = log_scale,
            scale = exp(log_scale),
            priority = move.priority,
        )
        for move in basis.basis_moves
    ]
end

function global_block_linearized_refit_result()
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
        method = "global block linearized refit base breakdown",
    )
    ranked_candidates = all_slot_targeted_entry_candidates(
        full_model,
        base_breakdown.worst_case,
    )
    bases = global_block_bases(ranked_candidates)
    isempty(bases) && error("no global block bases available")

    base_residual = shortwave_residual_vector(base_model)
    h = global_block_linearized_probe_step()
    sensitivity = zeros(Float64, length(base_residual), length(bases))
    for (i, basis) in enumerate(bases)
        probe_model = pressure_band_active_table_moved_model(
            full_model,
            parameters,
            pressure_moves,
            vcat(active_moves, scaled_basis_moves(basis, h)),
        )
        sensitivity[:, i] .= (shortwave_residual_vector(probe_model) .- base_residual) ./ h
    end

    gram = sensitivity' * sensitivity
    rhs = -(sensitivity' * base_residual)
    max_log_scale = global_block_linearized_max_log_scale()
    trials = NamedTuple[]
    for lambda in global_block_linearized_ridge_lambdas()
        raw_delta = (gram + lambda * I) \ rhs
        clamped_delta = clamp.(raw_delta, -max_log_scale, max_log_scale)
        moves = reduce(vcat, [
            scaled_basis_moves(basis, delta)
            for (basis, delta) in zip(bases, clamped_delta)
            if abs(delta) > 1.0e-8
        ]; init = NamedTuple[])
        candidate_model = pressure_band_active_table_moved_model(
            full_model,
            parameters,
            pressure_moves,
            vcat(active_moves, moves),
        )
        candidate_breakdown = final_objective_breakdown_from_model(
            candidate_model;
            method = "global block linearized refit candidate breakdown",
        )
        push!(trials, (
            ridge_lambda = lambda,
            candidate_objective = candidate_breakdown.objective,
            objective_reduction = base_breakdown.objective - candidate_breakdown.objective,
            basis_count = length(bases),
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
        case = "reduced_ecckd_global_block_linearized_refit",
        status = "preflight_ready",
        target_case = base_breakdown.worst_case,
        target_metric = base_breakdown.worst_metric,
        pressure_move_count = length(pressure_moves),
        starting_active_move_count = length(active_moves),
        ranked_candidate_count = length(ranked_candidates),
        basis_count = length(bases),
        group_limit = global_block_linearized_group_limit(),
        block_sizes = global_block_linearized_sizes(),
        probe_step = h,
        max_log_scale = max_log_scale,
        ridge_lambdas = global_block_linearized_ridge_lambdas(),
        best_ridge_lambda = best_trial.ridge_lambda,
        base_objective = base_breakdown.objective,
        candidate_objective = best_trial.candidate_objective,
        final_objective = accepted ? best_trial.candidate_objective : base_breakdown.objective,
        objective_reduction = best_trial.objective_reduction,
        accepted = accepted,
        accepted_move_count = length(accepted_moves),
        accepted_moves = accepted_moves,
        all_active_moves = vcat(active_moves, accepted_moves),
        raw_delta_norm = best_trial.raw_delta_norm,
        clamped_delta_norm = best_trial.clamped_delta_norm,
        trials = trials,
        base_breakdown = base_breakdown,
        candidate_breakdown = best_trial.candidate_breakdown,
    )
end

function global_block_linearized_markdown(result)
    lines = String[
        "# Reduced ecCKD Global Block Linearized Refit",
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
        "This diagnostic fits a joint linearized update over grouped active-entry",
        "table bases. It differs from scalar block refinement by solving for all",
        "basis amplitudes at once, then accepting the candidate only after a full",
        "nonlinear hard-gate evaluation.",
    ]
    return join(lines, "\n") * "\n"
end

function write_global_block_linearized_artifacts(result)
    mkpath(dirname(GLOBAL_BLOCK_LINEARIZED_JSON))
    write(GLOBAL_BLOCK_LINEARIZED_JSON, json_object(result) * "\n")
    write(GLOBAL_BLOCK_LINEARIZED_MD, global_block_linearized_markdown(result))
    print(global_block_linearized_markdown(result))
    println("Wrote $GLOBAL_BLOCK_LINEARIZED_JSON")
    println("Wrote $GLOBAL_BLOCK_LINEARIZED_MD")
end

function main(; result = nothing)
    write_global_block_linearized_artifacts(
        result === nothing ? global_block_linearized_refit_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
