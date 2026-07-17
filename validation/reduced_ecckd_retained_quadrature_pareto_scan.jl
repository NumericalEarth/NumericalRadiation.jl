include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const RETAINED_QUADRATURE_PARETO_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_quadrature_pareto_scan.json")
const RETAINED_QUADRATURE_PARETO_SCAN_MD =
    validation_results_path("reduced_ecckd_retained_quadrature_pareto_scan.md")

function quadrature_scan_steps()
    raw = get(ENV, "RH_REDUCED_QUADRATURE_SCAN_STEPS", "0.03125,0.0625,0.125,0.25")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function with_reweighted_shortwave(model, logits)
    candidate = deepcopy(model)
    candidate.shortwave_weights .= softmax(logits)
    return candidate
end

function retained_quadrature_pareto_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = current_constrained_table_model(
        full_model;
        base_mode = "boundary_table_continuation",
    )
    base_objective, base_cases = full_hard_objective(base_model)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    base_weights = copy(base_model.shortwave_weights)
    base_logits = log.(max.(base_weights, eps(Float64)))

    rows = NamedTuple[]
    for ig in eachindex(base_logits)
        for step in quadrature_scan_steps(), direction in (-1.0, 1.0)
            logits = copy(base_logits)
            logits[ig] += direction * step
            objective, cases = full_hard_objective(
                with_reweighted_shortwave(base_model, logits),
            )
            toa = maximum(case.toa_forcing_max_abs for case in cases)
            surface = maximum(case.surface_forcing_max_abs for case in cases)
            push!(rows, (
                local_index = ig,
                gpoint = WEIGHTED_GREEDY_SW_16_INDICES[ig],
                step = step,
                direction = direction < 0 ? "negative" : "positive",
                objective = objective,
                objective_reduction = base_objective - objective,
                toa_forcing_error_w_m2 = toa,
                surface_forcing_error_w_m2 = surface,
                toa_regressed = toa > base_toa,
                surface_regressed = surface > base_surface,
                pareto_safe = objective < base_objective &&
                              toa <= base_toa &&
                              surface <= base_surface,
            ))
        end
    end
    best = argmin(row -> row.objective, rows)
    safe_rows = filter(row -> row.pareto_safe, rows)
    best_safe = isempty(safe_rows) ? nothing : argmin(row -> row.objective, safe_rows)
    accepted = best_safe !== nothing
    return (
        case = "reduced_ecckd_retained_quadrature_pareto_scan",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "quadrature_pareto_scan_improved" :
                 "quadrature_pareto_scan_rejected",
        base_mode = "boundary_table_continuation",
        candidate_count = length(rows),
        step_count = length(quadrature_scan_steps()),
        base_objective = base_objective,
        base_worst_toa_forcing_error_w_m2 = base_toa,
        base_worst_surface_forcing_error_w_m2 = base_surface,
        best_objective = best.objective,
        best_objective_reduction = best.objective_reduction,
        best_worst_toa_forcing_error_w_m2 = best.toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 = best.surface_forcing_error_w_m2,
        best_local_index = best.local_index,
        best_gpoint = best.gpoint,
        best_step = best.step,
        best_direction = best.direction,
        best_toa_regressed = best.toa_regressed,
        best_surface_regressed = best.surface_regressed,
        any_pareto_safe = accepted,
        best_safe_objective = accepted ? best_safe.objective : base_objective,
        best_safe_objective_reduction =
            accepted ? best_safe.objective_reduction : 0.0,
        best_safe_worst_toa_forcing_error_w_m2 =
            accepted ? best_safe.toa_forcing_error_w_m2 : base_toa,
        best_safe_worst_surface_forcing_error_w_m2 =
            accepted ? best_safe.surface_forcing_error_w_m2 : base_surface,
        best_safe_local_index = accepted ? best_safe.local_index : 0,
        best_safe_gpoint = accepted ? best_safe.gpoint : 0,
        best_safe_step = accepted ? best_safe.step : 0.0,
        best_safe_direction = accepted ? best_safe.direction : "",
        rows = rows,
    )
end

function retained_quadrature_pareto_scan_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Quadrature Pareto Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Base TOA forcing | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Candidates | $(result.candidate_count) |",
        "| Best objective | $(@sprintf("%.12g", result.best_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best TOA forcing | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Best move | g$(result.best_gpoint) $(result.best_direction) $(result.best_step) |",
        "| Best TOA regressed | $(result.best_toa_regressed) |",
        "| Best surface regressed | $(result.best_surface_regressed) |",
        "| Any Pareto-safe | $(result.any_pareto_safe) |",
        "| Best Pareto-safe objective | $(@sprintf("%.12g", result.best_safe_objective)) |",
        "| Best Pareto-safe TOA forcing | $(@sprintf("%.12g", result.best_safe_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best Pareto-safe surface forcing | $(@sprintf("%.12g", result.best_safe_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "",
        "This diagnostic perturbs one reduced shortwave quadrature logit at a time",
        "on the fully retained boundary-table-continuation base. A candidate is",
        "Pareto-safe only if it lowers the full hard objective and does not worsen",
        "either worst TOA or worst surface forcing error.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? retained_quadrature_pareto_scan_result() : result
    mkpath(dirname(RETAINED_QUADRATURE_PARETO_SCAN_JSON))
    write(RETAINED_QUADRATURE_PARETO_SCAN_JSON, json_object(result) * "\n")
    write(RETAINED_QUADRATURE_PARETO_SCAN_MD,
          retained_quadrature_pareto_scan_markdown(result))
    print(retained_quadrature_pareto_scan_markdown(result))
    println("Wrote $RETAINED_QUADRATURE_PARETO_SCAN_JSON")
    println("Wrote $RETAINED_QUADRATURE_PARETO_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
