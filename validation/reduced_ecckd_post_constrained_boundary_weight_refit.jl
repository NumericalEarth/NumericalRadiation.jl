include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_post_constrained_weight_refit.jl"))

const POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_post_constrained_boundary_weight_refit.json")
const POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_MD =
    validation_results_path("reduced_ecckd_post_constrained_boundary_weight_refit.md")

boundary_weight_refit_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_ITERATIONS", "8"))

function boundary_weight_refit_steps()
    raw = get(ENV, "RH_REDUCED_POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_STEPS",
              "0.03125,0.0625,0.125,0.25,0.5")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

boundary_weight_refit_start_mode() =
    get(ENV, "RH_REDUCED_POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_START", "base")

function latest_boundary_weight_refit_weights(;
                                              path =
                                                POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_JSON)
    isfile(path) || return nothing
    text = read(path, String)
    occursin("\"accepted\": true", text) || return nothing
    match = Base.match(r"\"final_weights\"\s*:\s*\[([^\]]+)\]", text)
    match === nothing && return nothing
    return parse.(Float64, split(match.captures[1], ","))
end

function boundary_weight_objective_from_cases(cases)
    return max(
        maximum(case.toa_forcing_max_abs for case in cases) /
        ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
        maximum(case.surface_forcing_max_abs for case in cases) /
        ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
    )
end

function post_constrained_boundary_weight_objective(model, logits)
    weighted_model = with_shortwave_weights(
        model,
        weight_refit_weights_from_logits(logits),
    )
    cases = [case_metrics(case, weighted_model) for case in REDUCED_CASES]
    return boundary_weight_objective_from_cases(cases), cases
end

function boundary_weight_scan(model, logits, current_objective;
                              steps = boundary_weight_refit_steps())
    rows = NamedTuple[]
    for index in eachindex(logits), step in steps, direction in (-1.0, 1.0)
        trial = copy(logits)
        trial[index] += direction * step
        objective, _ = post_constrained_boundary_weight_objective(model, trial)
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
    return best
end

function post_constrained_boundary_weight_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = current_constrained_table_model(full_model)
    start_mode = boundary_weight_refit_start_mode()
    start_weights = start_mode == "latest" ?
        latest_boundary_weight_refit_weights() : nothing
    if start_weights !== nothing && length(start_weights) != length(base_model.shortwave_weights)
        start_weights = nothing
    end
    current_logits = weight_refit_logits_from_weights(
        start_weights === nothing ? base_model.shortwave_weights : start_weights,
    )
    initial_boundary_objective, initial_cases =
        post_constrained_boundary_weight_objective(base_model, current_logits)
    current_objective = initial_boundary_objective
    best_logits = copy(current_logits)
    trajectory = NamedTuple[]

    for iteration in 1:boundary_weight_refit_iterations()
        best = boundary_weight_scan(base_model, best_logits, current_objective)
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
    final_boundary_objective = boundary_weight_objective_from_cases(final_cases)
    final_full_objective = maximum(normalized_case_objective, final_cases)
    initial_full_objective = maximum(normalized_case_objective, initial_cases)
    return (
        case = "reduced_ecckd_post_constrained_boundary_weight_refit",
        status = final_boundary_objective < initial_boundary_objective ?
                 "boundary_weight_refit_improved" :
                 "boundary_weight_refit_rejected",
        iterations_requested = boundary_weight_refit_iterations(),
        iterations_completed = length(trajectory),
        start_mode = start_mode,
        used_latest_start = start_weights !== nothing,
        steps = boundary_weight_refit_steps(),
        initial_boundary_objective = initial_boundary_objective,
        final_boundary_objective = final_boundary_objective,
        boundary_objective_reduction =
            initial_boundary_objective - final_boundary_objective,
        initial_full_objective = initial_full_objective,
        final_full_objective = final_full_objective,
        accepted = final_boundary_objective < initial_boundary_objective,
        initial_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in initial_cases),
        initial_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in initial_cases),
        final_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in final_cases),
        final_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in final_cases),
        final_weights = collect(final_weights),
        trajectory = trajectory,
    )
end

function post_constrained_boundary_weight_refit_markdown(result)
    lines = String[
        "# Reduced ecCKD Post-Constrained Boundary Weight Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Iterations requested | $(result.iterations_requested) |",
        "| Iterations completed | $(result.iterations_completed) |",
        "| Initial boundary objective | $(@sprintf("%.12g", result.initial_boundary_objective)) |",
        "| Final boundary objective | $(@sprintf("%.12g", result.final_boundary_objective)) |",
        "| Boundary objective reduction | $(@sprintf("%.12g", result.boundary_objective_reduction)) |",
        "| Initial full objective | $(@sprintf("%.12g", result.initial_full_objective)) |",
        "| Final full objective | $(@sprintf("%.12g", result.final_full_objective)) |",
        "| Accepted | $(result.accepted) |",
        "| Initial worst TOA forcing | $(@sprintf("%.12g", result.initial_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Initial worst surface forcing | $(@sprintf("%.12g", result.initial_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Final worst TOA forcing | $(@sprintf("%.12g", result.final_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Final worst surface forcing | $(@sprintf("%.12g", result.final_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "",
        "This diagnostic refits only shortwave quadrature weights against the",
        "boundary-forcing max objective after cumulative constrained table moves.",
        "It is diagnostic and is not the canonical reduced model unless all hard",
        "thresholds pass.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? post_constrained_boundary_weight_refit_result() : result
    mkpath(dirname(POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_JSON))
    write(POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_JSON, json_object(result) * "\n")
    write(POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_MD,
          post_constrained_boundary_weight_refit_markdown(result))
    print(post_constrained_boundary_weight_refit_markdown(result))
    println("Wrote $POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_JSON")
    println("Wrote $POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
