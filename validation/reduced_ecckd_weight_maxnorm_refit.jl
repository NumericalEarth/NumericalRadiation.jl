include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_subset_search.jl"))

const WEIGHT_MAXNORM_REFIT_JSON =
    validation_results_path("reduced_ecckd_weight_maxnorm_refit.json")
const WEIGHT_MAXNORM_REFIT_MD =
    validation_results_path("reduced_ecckd_weight_maxnorm_refit.md")

weight_maxnorm_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_WEIGHT_MAXNORM_ITERATIONS", "50000"))

function projected_maxnorm_weight_refit(design, target, initial_weights;
                                        iterations = weight_maxnorm_iterations())
    weights = simplex_projection(collect(initial_weights))
    best_weights = copy(weights)
    residual = design * weights - target
    best_objective = maximum(abs, residual)
    row_norms2 = vec(sum(abs2, design; dims = 2))

    for iteration in 1:iterations
        residual = design * weights - target
        active_index = argmax(abs.(residual))
        objective = abs(residual[active_index])
        if objective < best_objective
            best_objective = objective
            best_weights .= weights
        end
        gradient = sign(residual[active_index]) .* view(design, active_index, :)
        denominator = max(row_norms2[active_index], eps(Float64))
        step = min(0.25 / sqrt(iteration), objective / denominator)
        weights = simplex_projection(weights .- step .* collect(gradient))
    end

    return best_weights, best_objective
end

function exact_weight_cases(model, weights)
    weighted = with_shortwave_weights(model, weights)
    return [case_metrics(case, weighted) for case in REDUCED_CASES]
end

function exact_weight_objective_from_cases(cases)
    return maximum(exact_case_objective, cases)
end

function weight_candidate_result(label, model, context, indices, weights;
                                 approximate_objective)
    cases = exact_weight_cases(model, weights)
    objective = exact_weight_objective_from_cases(cases)
    return (
        label = label,
        approximate_objective = approximate_objective,
        exact_objective = objective,
        worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in cases),
        worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in cases),
        max_abs_weight_delta =
            maximum(abs.(weights .- model.shortwave_weights)),
        weights = collect(weights),
    )
end

function reduced_weight_maxnorm_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    model = reduced_tabulated_model(full_model, (
        ng_lw = 32,
        ng_sw = 16,
        method = "weighted_greedy_subset_preflight_table_refined",
    ))
    context = search_context(model)
    indices = collect(1:size(model.shortwave_absorption, 1))
    base_weights = collect(model.shortwave_weights)
    design, target = subset_hard_gate_weight_design(context, indices)

    base_cases = exact_weight_cases(model, base_weights)
    base_objective = exact_weight_objective_from_cases(base_cases)
    base_linear_objective = maximum(abs, design * base_weights - target)

    candidates = NamedTuple[]
    for p in (16, 32, 64)
        weights, approximate_objective =
            optimized_subset_weights_hardgate(context, indices;
                                              initial_weights = base_weights,
                                              max_iterations = 3000,
                                              p = p)
        push!(candidates,
              weight_candidate_result("projected p=$p hard-gate weights",
                                      model, context, indices, weights;
                                      approximate_objective))
    end

    maxnorm_weights, maxnorm_objective =
        projected_maxnorm_weight_refit(design, target, base_weights)
    push!(candidates,
          weight_candidate_result("projected max-norm hard-gate weights",
                                  model, context, indices, maxnorm_weights;
                                  approximate_objective = maxnorm_objective))

    _, best_index = findmin(candidate -> candidate.exact_objective, candidates)
    best = candidates[best_index]
    accepted = best.exact_objective < base_objective
    return (
        case = "reduced_ecckd_weight_maxnorm_refit",
        status = accepted ? "weight_refit_improved" : "weight_refit_rejected",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        method = "projected-simplex p-norm and max-norm shortwave weight refits on current table-refined 32x16 model",
        iterations = weight_maxnorm_iterations(),
        base_exact_objective = base_objective,
        base_linear_objective = base_linear_objective,
        base_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in base_cases),
        base_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in base_cases),
        best_label = best.label,
        best_exact_objective = best.exact_objective,
        best_approximate_objective = best.approximate_objective,
        best_worst_toa_forcing_error_w_m2 = best.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            best.worst_surface_forcing_error_w_m2,
        best_max_abs_weight_delta = best.max_abs_weight_delta,
        accepted = accepted,
        candidates = candidates,
    )
end

function json_value(value)
    if value === nothing
        return "null"
    elseif value isa AbstractString
        escaped = replace(value,
            "\\" => "\\\\",
            "\"" => "\\\"",
            "\n" => "\\n",
            "\r" => "\\r",
            "\t" => "\\t",
        )
        return "\"" * escaped * "\""
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value isa NamedTuple
        return json_object(value)
    elseif value isa AbstractVector || value isa Tuple
        return "[" * join(json_value.(value), ", ") * "]"
    else
        return string(value)
    end
end

function json_object(object)
    pairs = ["  \"$(name)\": $(json_value(getfield(object, name)))"
             for name in propertynames(object)]
    return "{\n" * join(pairs, ",\n") * "\n}"
end

function weight_maxnorm_markdown(result)
    lines = String[
        "# Reduced ecCKD Weight Max-Norm Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base exact objective | $(@sprintf("%.12g", result.base_exact_objective)) |",
        "| Base linear objective | $(@sprintf("%.12g", result.base_linear_objective)) |",
        "| Best candidate | $(result.best_label) |",
        "| Best exact objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best approximate objective | $(@sprintf("%.12g", result.best_approximate_objective)) |",
        "| Best TOA forcing error | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing error | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Max absolute weight delta | $(@sprintf("%.12g", result.best_max_abs_weight_delta)) |",
        "| Accepted | $(result.accepted) |",
        "",
        "This diagnostic keeps the current table-refined 16-g shortwave optical",
        "properties fixed and refits only nonnegative simplex weights against",
        "hard-gate-scaled shortwave flux, heating-rate, and boundary residuals.",
    ]
    return join(lines, "\n") * "\n"
end

function write_weight_maxnorm_artifacts(result)
    mkpath(dirname(WEIGHT_MAXNORM_REFIT_JSON))
    write(WEIGHT_MAXNORM_REFIT_JSON, json_object(result) * "\n")
    write(WEIGHT_MAXNORM_REFIT_MD, weight_maxnorm_markdown(result))
    print(weight_maxnorm_markdown(result))
    println("Wrote $WEIGHT_MAXNORM_REFIT_JSON")
    println("Wrote $WEIGHT_MAXNORM_REFIT_MD")
end

function main(; result = nothing)
    write_weight_maxnorm_artifacts(
        result === nothing ? reduced_weight_maxnorm_refit_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
