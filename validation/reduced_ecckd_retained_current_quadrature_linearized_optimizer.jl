include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_retained_post_weight_bounded_weight_refit.jl"))
include(joinpath(@__DIR__, "reduced_ecckd_retained_quadrature_linearized_optimizer.jl"))

const RETAINED_CURRENT_QUADRATURE_LINEARIZED_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_current_quadrature_linearized_optimizer.json")
const RETAINED_CURRENT_QUADRATURE_LINEARIZED_OPTIMIZER_MD =
    validation_results_path("reduced_ecckd_retained_current_quadrature_linearized_optimizer.md")

current_quadrature_linearized_surface_cap() =
    parse(Float64, get(ENV, "RH_REDUCED_CURRENT_QUADRATURE_SURFACE_CAP", "2.03"))

current_quadrature_linearized_toa_tolerance() =
    parse(Float64, get(ENV, "RH_REDUCED_CURRENT_QUADRATURE_TOA_TOLERANCE", "0.0"))

function current_quadrature_linearized_base(full_model)
    model = post_weight_bounded_weight_refit_base(full_model)
    weights = latest_retained_post_weight_bounded_weight_refit_weights()
    weights === nothing || (model.shortwave_weights .= weights.weights)
    return model
end

function retained_current_quadrature_linearized_optimizer_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = current_quadrature_linearized_base(full_model)
    base_objective, base_cases = full_hard_objective(base_model)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    base_residual = constrained_table_residual_vector(base_model)
    h = quadrature_linearized_probe_step()
    nweights = length(base_model.shortwave_weights)
    basis_count = max(0, nweights - 1)
    basis = zeros(Float64, length(base_residual), basis_count)
    for j in 1:basis_count
        delta = zeros(Float64, nweights)
        delta[j] = h
        moved = with_quadrature_logit_delta(base_model, delta)
        basis[:, j] .= (constrained_table_residual_vector(moved) .- base_residual) ./ h
    end

    max_delta = quadrature_linearized_max_logit_delta()
    surface_cap = current_quadrature_linearized_surface_cap()
    toa_tolerance = current_quadrature_linearized_toa_tolerance()
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
        accepted = objective < base_objective &&
            toa <= base_toa + toa_tolerance &&
            surface <= surface_cap
        push!(rows, (
            ridge_lambda = lambda,
            raw_delta_norm = norm(raw_delta),
            clipped_delta_norm = norm(clipped_delta),
            max_abs_delta = isempty(clipped_delta) ? 0.0 : maximum(abs, clipped_delta),
            objective = objective,
            objective_reduction = base_objective - objective,
            worst_toa_forcing_error_w_m2 = toa,
            worst_surface_forcing_error_w_m2 = surface,
            accepted = accepted,
            weights = collect(candidate_model.shortwave_weights),
        ))
    end

    accepted_rows = filter(row -> row.accepted, rows)
    best = isempty(rows) ? nothing : argmin(row -> row.objective, rows)
    selected = isempty(accepted_rows) ? nothing : argmin(row -> row.objective, accepted_rows)
    accepted = selected !== nothing
    return (
        case = "reduced_ecckd_retained_current_quadrature_linearized_optimizer",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "current_quadrature_linearized_optimizer_improved" :
                 "current_quadrature_linearized_optimizer_rejected",
        base_mode = "current_capped_post_weight",
        residual_mode = constrained_table_residual_mode(),
        basis_count = basis_count,
        probe_step = h,
        max_logit_delta = max_delta,
        surface_cap_w_m2 = surface_cap,
        toa_tolerance_w_m2 = toa_tolerance,
        base_objective = base_objective,
        base_worst_toa_forcing_error_w_m2 = base_toa,
        base_worst_surface_forcing_error_w_m2 = base_surface,
        best_ridge_lambda = best === nothing ? NaN : best.ridge_lambda,
        best_exact_objective = best === nothing ? base_objective : best.objective,
        best_objective_reduction = best === nothing ? 0.0 : best.objective_reduction,
        best_worst_toa_forcing_error_w_m2 =
            best === nothing ? base_toa : best.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            best === nothing ? base_surface : best.worst_surface_forcing_error_w_m2,
        accepted = accepted,
        accepted_ridge_lambda = accepted ? selected.ridge_lambda : nothing,
        accepted_objective = accepted ? selected.objective : base_objective,
        accepted_objective_reduction = accepted ? selected.objective_reduction : 0.0,
        accepted_worst_toa_forcing_error_w_m2 =
            accepted ? selected.worst_toa_forcing_error_w_m2 : base_toa,
        accepted_worst_surface_forcing_error_w_m2 =
            accepted ? selected.worst_surface_forcing_error_w_m2 : base_surface,
        accepted_weights = accepted ? collect(selected.weights) : Float64[],
        rows = rows,
    )
end

current_quadrature_metric_or_na(value) =
    value === nothing ? "n/a" : @sprintf("%.12g", value)

function retained_current_quadrature_linearized_optimizer_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Current Quadrature Linearized Optimizer",
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
        "| Surface cap | $(@sprintf("%.12g", result.surface_cap_w_m2)) W m^-2 |",
        "| TOA tolerance | $(@sprintf("%.12g", result.toa_tolerance_w_m2)) W m^-2 |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Base TOA forcing | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Best ridge lambda | $(@sprintf("%.12g", result.best_ridge_lambda)) |",
        "| Best exact objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best TOA forcing | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Accepted | $(result.accepted) |",
        "| Accepted ridge lambda | $(current_quadrature_metric_or_na(result.accepted_ridge_lambda)) |",
        "| Accepted objective | $(@sprintf("%.12g", result.accepted_objective)) |",
        "| Accepted TOA forcing | $(@sprintf("%.12g", result.accepted_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Accepted surface forcing | $(@sprintf("%.12g", result.accepted_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "",
        "This diagnostic fits a linearized all-logit shortwave quadrature-weight",
        "update on the current capped/post-weight base. It exact-evaluates every",
        "ridge candidate and accepts only objective/TOA improvements that remain",
        "inside the configured absolute surface-forcing cap.",
        "",
        "## Ridge Summary",
        "",
        "| Ridge lambda | Objective | TOA forcing | Surface forcing | Accepted |",
        "|---:|---:|---:|---:|---:|",
    ]
    for row in result.rows
        push!(lines,
              "| $(@sprintf("%.12g", row.ridge_lambda)) | $(@sprintf("%.12g", row.objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.worst_surface_forcing_error_w_m2)) | $(row.accepted) |")
    end
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ?
        retained_current_quadrature_linearized_optimizer_result() : result
    mkpath(dirname(RETAINED_CURRENT_QUADRATURE_LINEARIZED_OPTIMIZER_JSON))
    write(RETAINED_CURRENT_QUADRATURE_LINEARIZED_OPTIMIZER_JSON,
          json_object(result) * "\n")
    write(RETAINED_CURRENT_QUADRATURE_LINEARIZED_OPTIMIZER_MD,
          retained_current_quadrature_linearized_optimizer_markdown(result))
    print(retained_current_quadrature_linearized_optimizer_markdown(result))
    println("Wrote $RETAINED_CURRENT_QUADRATURE_LINEARIZED_OPTIMIZER_JSON")
    println("Wrote $RETAINED_CURRENT_QUADRATURE_LINEARIZED_OPTIMIZER_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
