include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_retained_quadrature_pareto_scan.jl"))

const RETAINED_QUADRATURE_PAIR_PARETO_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_quadrature_pair_pareto_scan.json")
const RETAINED_QUADRATURE_PAIR_PARETO_SCAN_MD =
    validation_results_path("reduced_ecckd_retained_quadrature_pair_pareto_scan.md")

function quadrature_pair_scan_max_pairs()
    return parse(Int, get(ENV, "RH_REDUCED_QUADRATURE_PAIR_SCAN_MAX_PAIRS", "120"))
end

function retained_quadrature_pair_pareto_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = current_constrained_table_model(
        full_model;
        base_mode = "boundary_table_continuation",
    )
    base_objective, base_cases = full_hard_objective(base_model)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    base_logits = log.(max.(base_model.shortwave_weights, eps(Float64)))
    max_pairs = quadrature_pair_scan_max_pairs()

    rows = NamedTuple[]
    pair_count = 0
    done = false
    for i in eachindex(base_logits)
        for j in eachindex(base_logits)
            i == j && continue
            pair_count += 1
            pair_count > max_pairs && (done = true; break)
            for step in quadrature_scan_steps()
                logits = copy(base_logits)
                logits[i] += step
                logits[j] -= step
                objective, cases = full_hard_objective(
                    with_reweighted_shortwave(base_model, logits),
                )
                toa = maximum(case.toa_forcing_max_abs for case in cases)
                surface = maximum(case.surface_forcing_max_abs for case in cases)
                push!(rows, (
                    up_local_index = i,
                    up_gpoint = WEIGHTED_GREEDY_SW_16_INDICES[i],
                    down_local_index = j,
                    down_gpoint = WEIGHTED_GREEDY_SW_16_INDICES[j],
                    step = step,
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
        done && break
    end

    best = argmin(row -> row.objective, rows)
    safe_rows = filter(row -> row.pareto_safe, rows)
    best_safe = isempty(safe_rows) ? nothing : argmin(row -> row.objective, safe_rows)
    accepted = best_safe !== nothing
    return (
        case = "reduced_ecckd_retained_quadrature_pair_pareto_scan",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "quadrature_pair_pareto_scan_improved" :
                 "quadrature_pair_pareto_scan_rejected",
        base_mode = "boundary_table_continuation",
        pair_count = min(pair_count, max_pairs),
        candidate_count = length(rows),
        base_objective = base_objective,
        base_worst_toa_forcing_error_w_m2 = base_toa,
        base_worst_surface_forcing_error_w_m2 = base_surface,
        best_objective = best.objective,
        best_objective_reduction = best.objective_reduction,
        best_worst_toa_forcing_error_w_m2 = best.toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 = best.surface_forcing_error_w_m2,
        best_up_gpoint = best.up_gpoint,
        best_down_gpoint = best.down_gpoint,
        best_step = best.step,
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
        best_safe_up_gpoint = accepted ? best_safe.up_gpoint : 0,
        best_safe_down_gpoint = accepted ? best_safe.down_gpoint : 0,
        best_safe_step = accepted ? best_safe.step : 0.0,
        rows = rows,
    )
end

function retained_quadrature_pair_pareto_scan_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Quadrature Pair Pareto Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Base TOA forcing | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Pairs | $(result.pair_count) |",
        "| Candidates | $(result.candidate_count) |",
        "| Best objective | $(@sprintf("%.12g", result.best_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best TOA forcing | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Best move | g$(result.best_up_gpoint) up, g$(result.best_down_gpoint) down, $(result.best_step) |",
        "| Best TOA regressed | $(result.best_toa_regressed) |",
        "| Best surface regressed | $(result.best_surface_regressed) |",
        "| Any Pareto-safe | $(result.any_pareto_safe) |",
        "| Best Pareto-safe objective | $(@sprintf("%.12g", result.best_safe_objective)) |",
        "| Best Pareto-safe TOA forcing | $(@sprintf("%.12g", result.best_safe_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best Pareto-safe surface forcing | $(@sprintf("%.12g", result.best_safe_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "",
        "This diagnostic redistributes reduced shortwave quadrature weight between",
        "two retained g-points at a time. A candidate is Pareto-safe only if it",
        "lowers the full hard objective and does not worsen either worst TOA or",
        "worst surface forcing error.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? retained_quadrature_pair_pareto_scan_result() : result
    mkpath(dirname(RETAINED_QUADRATURE_PAIR_PARETO_SCAN_JSON))
    write(RETAINED_QUADRATURE_PAIR_PARETO_SCAN_JSON, json_object(result) * "\n")
    write(RETAINED_QUADRATURE_PAIR_PARETO_SCAN_MD,
          retained_quadrature_pair_pareto_scan_markdown(result))
    print(retained_quadrature_pair_pareto_scan_markdown(result))
    println("Wrote $RETAINED_QUADRATURE_PAIR_PARETO_SCAN_JSON")
    println("Wrote $RETAINED_QUADRATURE_PAIR_PARETO_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
