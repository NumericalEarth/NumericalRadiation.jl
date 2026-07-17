include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const POST_CONSTRAINED_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_post_constrained_weight_refit.json")
const POST_CONSTRAINED_WEIGHT_REFIT_MD =
    validation_results_path("reduced_ecckd_post_constrained_weight_refit.md")

post_constrained_weight_refit_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_POST_CONSTRAINED_WEIGHT_REFIT_ITERATIONS", "6"))

function post_constrained_weight_refit_steps()
    raw = get(ENV, "RH_REDUCED_POST_CONSTRAINED_WEIGHT_REFIT_STEPS",
              "0.03125,0.0625,0.125,0.25")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function weight_refit_logits_from_weights(weights)
    return log.(max.(collect(weights), eps(Float64)))
end

function weight_refit_weights_from_logits(logits)
    shifted = logits .- maximum(logits)
    weights = exp.(shifted)
    return weights ./ sum(weights)
end

function post_constrained_weight_objective(model, logits)
    weighted_model = with_shortwave_weights(
        model,
        weight_refit_weights_from_logits(logits),
    )
    cases = [case_metrics(case, weighted_model) for case in REDUCED_CASES]
    return maximum(normalized_case_objective, cases), cases
end

function post_constrained_weight_scan(model, logits, current_objective;
                                      steps = post_constrained_weight_refit_steps())
    rows = NamedTuple[]
    for index in eachindex(logits), step in steps, direction in (-1.0, 1.0)
        trial = copy(logits)
        trial[index] += direction * step
        objective, _ = post_constrained_weight_objective(model, trial)
        push!(rows, (
            local_index = index,
            step = step,
            direction = direction < 0 ? "negative" : "positive",
            objective = objective,
            improvement = current_objective - objective,
            accepted = objective < current_objective,
        ))
    end
    best = argmin(row -> row.objective, rows)
    return rows, best
end

function post_constrained_weight_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = current_constrained_table_model(full_model)
    current_logits = weight_refit_logits_from_weights(base_model.shortwave_weights)
    initial_objective, initial_cases =
        post_constrained_weight_objective(base_model, current_logits)
    current_objective = initial_objective
    best_logits = copy(current_logits)
    trajectory = NamedTuple[]

    for iteration in 1:post_constrained_weight_refit_iterations()
        _, best = post_constrained_weight_scan(
            base_model,
            best_logits,
            current_objective,
        )
        accepted = best.objective < current_objective
        push!(trajectory, (
            iteration = iteration,
            initial_objective = current_objective,
            best_local_index = best.local_index,
            best_step = best.step,
            best_direction = best.direction,
            best_objective = best.objective,
            best_improvement = current_objective - best.objective,
            accepted = accepted,
        ))
        accepted || break
        best_logits[best.local_index] +=
            (best.direction == "negative" ? -best.step : best.step)
        current_objective = best.objective
    end

    final_weights = weight_refit_weights_from_logits(best_logits)
    final_model = with_shortwave_weights(base_model, final_weights)
    final_cases = [case_metrics(case, final_model) for case in REDUCED_CASES]
    final_objective = maximum(normalized_case_objective, final_cases)
    initial_toa = maximum(case.toa_forcing_max_abs for case in initial_cases)
    initial_surface = maximum(case.surface_forcing_max_abs for case in initial_cases)
    final_toa = maximum(case.toa_forcing_max_abs for case in final_cases)
    final_surface = maximum(case.surface_forcing_max_abs for case in final_cases)
    return (
        case = "reduced_ecckd_post_constrained_weight_refit",
        status = final_objective < initial_objective ? "weight_refit_improved" :
                 "weight_refit_rejected",
        iterations_requested = post_constrained_weight_refit_iterations(),
        iterations_completed = length(trajectory),
        steps = post_constrained_weight_refit_steps(),
        initial_objective = initial_objective,
        final_objective = final_objective,
        objective_reduction = initial_objective - final_objective,
        accepted = final_objective < initial_objective,
        initial_worst_toa_forcing_error_w_m2 = initial_toa,
        initial_worst_surface_forcing_error_w_m2 = initial_surface,
        final_worst_toa_forcing_error_w_m2 = final_toa,
        final_worst_surface_forcing_error_w_m2 = final_surface,
        initial_weights = collect(base_model.shortwave_weights),
        final_weights = collect(final_weights),
        initial_cases = initial_cases,
        final_cases = final_cases,
        trajectory = trajectory,
    )
end

function post_constrained_weight_refit_markdown(result)
    initial_toa = maximum(case.toa_forcing_max_abs for case in result.initial_cases)
    initial_surface = maximum(case.surface_forcing_max_abs for case in result.initial_cases)
    final_toa = maximum(case.toa_forcing_max_abs for case in result.final_cases)
    final_surface = maximum(case.surface_forcing_max_abs for case in result.final_cases)
    lines = String[
        "# Reduced ecCKD Post-Constrained Weight Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Iterations requested | $(result.iterations_requested) |",
        "| Iterations completed | $(result.iterations_completed) |",
        "| Initial objective | $(@sprintf("%.12g", result.initial_objective)) |",
        "| Final objective | $(@sprintf("%.12g", result.final_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Accepted | $(result.accepted) |",
        "| Initial worst TOA forcing | $(@sprintf("%.12g", initial_toa)) W m^-2 |",
        "| Initial worst surface forcing | $(@sprintf("%.12g", initial_surface)) W m^-2 |",
        "| Final worst TOA forcing | $(@sprintf("%.12g", final_toa)) W m^-2 |",
        "| Final worst surface forcing | $(@sprintf("%.12g", final_surface)) W m^-2 |",
        "",
        "This diagnostic refits only the 16 shortwave quadrature weights after",
        "the cumulative constrained table moves have been applied. It accepts",
        "only exact nonlinear hard-objective improvements.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? post_constrained_weight_refit_result() : result
    mkpath(dirname(POST_CONSTRAINED_WEIGHT_REFIT_JSON))
    write(POST_CONSTRAINED_WEIGHT_REFIT_JSON, json_object(result) * "\n")
    write(POST_CONSTRAINED_WEIGHT_REFIT_MD,
          post_constrained_weight_refit_markdown(result))
    print(post_constrained_weight_refit_markdown(result))
    println("Wrote $POST_CONSTRAINED_WEIGHT_REFIT_JSON")
    println("Wrote $POST_CONSTRAINED_WEIGHT_REFIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
