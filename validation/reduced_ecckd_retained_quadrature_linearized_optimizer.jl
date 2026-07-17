include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const RETAINED_QUADRATURE_LINEARIZED_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_quadrature_linearized_optimizer.json")
const RETAINED_QUADRATURE_LINEARIZED_OPTIMIZER_MD =
    validation_results_path("reduced_ecckd_retained_quadrature_linearized_optimizer.md")

function quadrature_linearized_probe_step()
    parse(Float64, get(ENV, "RH_REDUCED_QUADRATURE_LINEARIZED_PROBE_STEP", "0.00390625"))
end

function quadrature_linearized_max_logit_delta()
    parse(Float64, get(ENV, "RH_REDUCED_QUADRATURE_LINEARIZED_MAX_LOGIT_DELTA", "0.03125"))
end

function quadrature_linearized_ridge_lambdas()
    raw = get(ENV, "RH_REDUCED_QUADRATURE_LINEARIZED_RIDGE_LAMBDAS",
              "1.0e-6,1.0e-4,1.0e-2,1.0,100.0,1.0e4")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function with_quadrature_logit_delta(model, delta)
    candidate = deepcopy(model)
    logits = log.(max.(candidate.shortwave_weights, eps(Float64)))
    logits .+= delta
    candidate.shortwave_weights .= softmax(logits)
    return candidate
end

function retained_quadrature_linearized_optimizer_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    sw_indices = WEIGHTED_GREEDY_SW_16_INDICES
    base_model = current_constrained_table_model(
        full_model;
        base_mode = "retained_topology",
        sw_indices,
    )
    base_objective, base_cases = full_hard_objective(base_model)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    base_residual = constrained_table_residual_vector(base_model)
    h = quadrature_linearized_probe_step()
    nweights = length(base_model.shortwave_weights)

    # One logit is fixed as the reference because a uniform logit shift is a no-op
    # under softmax normalization.
    basis_count = max(0, nweights - 1)
    basis = zeros(Float64, length(base_residual), basis_count)
    for j in 1:basis_count
        delta = zeros(Float64, nweights)
        delta[j] = h
        moved = with_quadrature_logit_delta(base_model, delta)
        basis[:, j] .= (constrained_table_residual_vector(moved) .- base_residual) ./ h
    end

    max_delta = quadrature_linearized_max_logit_delta()
    rows = NamedTuple[]
    for lambda in quadrature_linearized_ridge_lambdas()
        lhs = basis' * basis + lambda * I
        rhs = -(basis' * base_residual)
        raw_delta = basis_count == 0 ? Float64[] : Vector(lhs \ rhs)
        clipped_delta = clamp.(raw_delta, -max_delta, max_delta)
        full_delta = zeros(Float64, nweights)
        full_delta[1:basis_count] .= clipped_delta
        candidate_model = with_quadrature_logit_delta(base_model, full_delta)
        objective, cases = full_hard_objective(candidate_model)
        toa = maximum(case.toa_forcing_max_abs for case in cases)
        surface = maximum(case.surface_forcing_max_abs for case in cases)
        pareto_safe = objective < base_objective &&
            toa <= base_toa + 1e-12 &&
            surface <= base_surface + 1e-12
        push!(rows, (
            ridge_lambda = lambda,
            raw_delta_norm = norm(raw_delta),
            clipped_delta_norm = norm(clipped_delta),
            max_abs_delta = isempty(clipped_delta) ? 0.0 : maximum(abs, clipped_delta),
            objective = objective,
            objective_reduction = base_objective - objective,
            worst_toa_forcing_error_w_m2 = toa,
            worst_surface_forcing_error_w_m2 = surface,
            pareto_safe = pareto_safe,
            weights = collect(candidate_model.shortwave_weights),
        ))
    end

    best = isempty(rows) ? nothing : argmin(row -> row.objective, rows)
    safe_rows = filter(row -> row.pareto_safe, rows)
    best_safe = isempty(safe_rows) ? nothing : argmin(row -> row.objective, safe_rows)
    accepted = best_safe !== nothing
    selected = accepted ? best_safe : best
    return (
        case = "reduced_ecckd_retained_quadrature_linearized_optimizer",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "quadrature_linearized_optimizer_improved" :
                 "quadrature_linearized_optimizer_rejected",
        base_mode = "retained_topology",
        residual_mode = constrained_table_residual_mode(),
        sw_indices = collect(sw_indices),
        basis_count = basis_count,
        probe_step = h,
        max_logit_delta = max_delta,
        base_objective = base_objective,
        base_worst_toa_forcing_error_w_m2 = base_toa,
        base_worst_surface_forcing_error_w_m2 = base_surface,
        best_ridge_lambda = selected === nothing ? NaN : selected.ridge_lambda,
        best_exact_objective = selected === nothing ? base_objective : selected.objective,
        best_objective_reduction =
            selected === nothing ? 0.0 : selected.objective_reduction,
        best_worst_toa_forcing_error_w_m2 =
            selected === nothing ? base_toa : selected.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            selected === nothing ? base_surface : selected.worst_surface_forcing_error_w_m2,
        any_pareto_safe = accepted,
        accepted = accepted,
        accepted_weights = accepted ? collect(best_safe.weights) : Float64[],
        rows = rows,
    )
end

function retained_quadrature_linearized_optimizer_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Quadrature Linearized Optimizer",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base mode | $(result.base_mode) |",
        "| Residual mode | $(result.residual_mode) |",
        "| Basis count | $(result.basis_count) |",
        "| Probe step | $(@sprintf("%.12g", result.probe_step)) |",
        "| Max logit delta | $(@sprintf("%.12g", result.max_logit_delta)) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Base TOA forcing | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Best ridge lambda | $(@sprintf("%.12g", result.best_ridge_lambda)) |",
        "| Best exact objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best TOA forcing | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Any Pareto-safe | $(result.any_pareto_safe) |",
        "| Accepted | $(result.accepted) |",
        "",
        "This diagnostic fits a linearized all-logit shortwave quadrature-weight",
        "update on the retained current base, then exact-evaluates each ridge",
        "candidate and accepts only strict Pareto-safe TOA/surface improvements.",
        "",
        "## Ridge Summary",
        "",
        "| Ridge lambda | Objective | TOA forcing | Surface forcing | Pareto-safe |",
        "|---:|---:|---:|---:|---:|",
    ]
    for row in result.rows
        push!(lines,
              "| $(@sprintf("%.12g", row.ridge_lambda)) | $(@sprintf("%.12g", row.objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_surface_forcing_error_w_m2)) | $(row.pareto_safe) |")
    end
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? retained_quadrature_linearized_optimizer_result() : result
    mkpath(dirname(RETAINED_QUADRATURE_LINEARIZED_OPTIMIZER_JSON))
    write(RETAINED_QUADRATURE_LINEARIZED_OPTIMIZER_JSON, json_object(result) * "\n")
    write(RETAINED_QUADRATURE_LINEARIZED_OPTIMIZER_MD,
          retained_quadrature_linearized_optimizer_markdown(result))
    print(retained_quadrature_linearized_optimizer_markdown(result))
    println("Wrote $RETAINED_QUADRATURE_LINEARIZED_OPTIMIZER_JSON")
    println("Wrote $RETAINED_QUADRATURE_LINEARIZED_OPTIMIZER_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
