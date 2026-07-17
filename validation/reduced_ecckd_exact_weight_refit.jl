include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_post_table_weight_refit.jl"))

const EXACT_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_exact_weight_refit.json")
const EXACT_WEIGHT_REFIT_MD =
    validation_results_path("reduced_ecckd_exact_weight_refit.md")

exact_weight_refit_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_EXACT_WEIGHT_REFIT_ITERATIONS", "8"))

function exact_weight_refit_steps()
    raw = get(ENV, "RH_REDUCED_EXACT_WEIGHT_REFIT_STEPS", "0.03125,0.0625,0.125")
    return [parse(Float64, strip(token)) for token in split(raw, ",") if !isempty(strip(token))]
end

function logits_from_weights(weights)
    return log.(max.(collect(weights), eps(Float64)))
end

function weights_from_logits(logits)
    shifted = logits .- maximum(logits)
    weights = exp.(shifted)
    return weights ./ sum(weights)
end

function exact_weight_objective(model, logits)
    weighted_model = with_shortwave_weights(model, weights_from_logits(logits))
    cases = [case_metrics(case, weighted_model) for case in REDUCED_CASES]
    return maximum(exact_case_objective, cases), cases
end

function exact_weight_coordinate_scan(model, logits, current_objective;
                                      steps = exact_weight_refit_steps())
    rows = NamedTuple[]
    for index in eachindex(logits)
        for step in steps
            for direction in (-1.0, 1.0)
                trial_logits = copy(logits)
                trial_logits[index] += direction * step
                objective, _ = exact_weight_objective(model, trial_logits)
                push!(rows, (
                    local_index = index,
                    step = step,
                    direction = direction < 0 ? "negative" : "positive",
                    objective = objective,
                    improvement = current_objective - objective,
                    accepted = objective < current_objective,
                ))
            end
        end
    end
    best = argmin(row -> row.objective, rows)
    return (
        rows = rows,
        best = best,
    )
end

function exact_weight_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = current_table_refined_model(full_model)
    previous_refit = latest_exact_weight_refit_weights()
    if previous_refit !== nothing
        base_model.shortwave_weights .= previous_refit.weights
    end
    current_logits = logits_from_weights(base_model.shortwave_weights)
    initial_objective, initial_cases = exact_weight_objective(base_model, current_logits)
    current_objective = initial_objective
    best_logits = copy(current_logits)
    trajectory = NamedTuple[]

    for iteration in 1:exact_weight_refit_iterations()
        scan = exact_weight_coordinate_scan(base_model, best_logits, current_objective)
        accepted = scan.best.objective < current_objective
        push!(trajectory, (
            iteration = iteration,
            initial_objective = current_objective,
            best_local_index = scan.best.local_index,
            best_step = scan.best.step,
            best_direction = scan.best.direction,
            best_objective = scan.best.objective,
            best_improvement = current_objective - scan.best.objective,
            accepted = accepted,
        ))
        accepted || break
        direction = scan.best.direction == "negative" ? -1.0 : 1.0
        best_logits[scan.best.local_index] += direction * scan.best.step
        current_objective = scan.best.objective
    end

    final_weights = weights_from_logits(best_logits)
    final_model = with_shortwave_weights(base_model, final_weights)
    final_cases = [case_metrics(case, final_model) for case in REDUCED_CASES]
    final_objective = maximum(exact_case_objective, final_cases)
    return (
        case = "reduced_ecckd_exact_weight_refit",
        status = "preflight_ready",
        iterations_requested = exact_weight_refit_iterations(),
        iterations_completed = length(trajectory),
        steps = exact_weight_refit_steps(),
        initial_objective = initial_objective,
        final_objective = final_objective,
        objective_reduction = initial_objective - final_objective,
        accepted = final_objective < initial_objective,
        initial_weights = collect(base_model.shortwave_weights),
        final_weights = collect(final_weights),
        initial_cases = initial_cases,
        final_cases = final_cases,
        trajectory = trajectory,
    )
end

function exact_weight_refit_markdown(result)
    initial_toa = maximum(case.toa_forcing_max_abs for case in result.initial_cases)
    initial_surface = maximum(case.surface_forcing_max_abs for case in result.initial_cases)
    final_toa = maximum(case.toa_forcing_max_abs for case in result.final_cases)
    final_surface = maximum(case.surface_forcing_max_abs for case in result.final_cases)
    lines = String[
        "# Reduced ecCKD Exact Weight Refit",
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
        "This diagnostic refits only the 16 shortwave weights by coordinate",
        "searching softmax logits against the exact clean ecCKD hard objective.",
        "It is accepted only if the exact nonlinear model improves.",
    ]
    return join(lines, "\n") * "\n"
end

function write_exact_weight_refit_artifacts(result)
    mkpath(dirname(EXACT_WEIGHT_REFIT_JSON))
    write(EXACT_WEIGHT_REFIT_JSON, json_object(result) * "\n")
    write(EXACT_WEIGHT_REFIT_MD, exact_weight_refit_markdown(result))
    print(exact_weight_refit_markdown(result))
    println("Wrote $EXACT_WEIGHT_REFIT_JSON")
    println("Wrote $EXACT_WEIGHT_REFIT_MD")
end

function main(; result = nothing)
    write_exact_weight_refit_artifacts(
        result === nothing ? exact_weight_refit_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
