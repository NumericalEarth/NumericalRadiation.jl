include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_broader_support_refit_search.jl"))

const NONLOCAL_SUPPORT_REFIT_JSON =
    validation_results_path("reduced_ecckd_nonlocal_support_refit_search.json")
const NONLOCAL_SUPPORT_REFIT_MD =
    validation_results_path("reduced_ecckd_nonlocal_support_refit_search.md")

const NONLOCAL_SUPPORT_SOURCES = (
    (
        label = "random_support_best",
        path = validation_results_path("reduced_ecckd_random_support_search.json"),
        key = "best_indices",
    ),
    (
        label = "support_swap_best",
        path = validation_results_path("reduced_ecckd_support_swap_scan.json"),
        key = "best_overall_indices",
    ),
    (
        label = "support_swap_continuation_best",
        path = validation_results_path("reduced_ecckd_support_swap_continuation_scan.json"),
        key = "best_indices",
    ),
    (
        label = "hardgate_subset_best",
        path = validation_results_path("reduced_ecckd_hardgate_subset_search.json"),
        key = "selected_shortwave_gpoints",
    ),
)

nonlocal_support_refit_candidate_limit() =
    parse(Int, get(ENV, "RH_REDUCED_NONLOCAL_SUPPORT_REFIT_CANDIDATES", "2"))

function integer_array_field(text, key)
    match = Base.match(Regex("\"$key\"\\s*:\\s*\\[([^\\]]*)\\]"), text)
    match === nothing && return Int[]
    return [parse(Int, strip(token)) for token in split(match.captures[1], ",")
            if !isempty(strip(token))]
end

function nonlocal_support_candidates()
    candidates = NamedTuple[]
    seen = Set{String}()
    for source in NONLOCAL_SUPPORT_SOURCES
        isfile(source.path) || continue
        indices = integer_array_field(read(source.path, String), source.key)
        length(indices) == 16 || continue
        length(unique(indices)) == 16 || continue
        all(index -> 1 <= index <= 32, indices) || continue
        key = join(indices, ",")
        key in seen && continue
        push!(seen, key)
        push!(candidates, (
            label = source.label,
            indices = indices,
        ))
    end
    return candidates
end

function nonlocal_support_prefilter_row(full_model, candidate)
    base_model = composed_support_base_model(full_model, candidate.indices)
    objective, cases = full_hard_objective(base_model)
    return (
        label = candidate.label,
        indices = collect(candidate.indices),
        base_objective = objective,
        base_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in cases),
        base_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in cases),
        base_worst_heating_rate_rmse_k_day = worst_heating_rmse(cases),
    )
end

function nonlocal_support_refit_row(full_model, candidate)
    base_model = composed_support_base_model(full_model, candidate.indices)
    base_objective, base_cases = full_hard_objective(base_model)
    base_residual = pressure_component_scan_residual_vector(base_model)
    variant = pressure_component_scan_variant(
        base_model,
        base_objective,
        base_cases,
        base_residual,
        broader_support_refit_band_count(),
        broader_support_refit_partition(),
        broader_support_refit_include_rayleigh(),
        true,
    )
    selected_objective = variant.accepted ? variant.accepted_objective : base_objective
    return (
        label = candidate.label,
        indices = collect(candidate.indices),
        base_objective = base_objective,
        refit_best_objective = variant.best_exact_objective,
        refit_best_objective_reduction = variant.best_objective_reduction,
        refit_accepted = variant.accepted,
        selected_objective = selected_objective,
        selected_worst_toa_forcing_error_w_m2 = variant.accepted ?
            variant.accepted_worst_toa_forcing_error_w_m2 :
            maximum(case.toa_forcing_max_abs for case in base_cases),
        selected_worst_surface_forcing_error_w_m2 = variant.accepted ?
            variant.accepted_worst_surface_forcing_error_w_m2 :
            maximum(case.surface_forcing_max_abs for case in base_cases),
        selected_worst_heating_rate_rmse_k_day = variant.accepted ?
            variant.accepted_worst_heating_rate_rmse_k_day :
            worst_heating_rmse(base_cases),
        accepted_move_count = variant.accepted_move_count,
    )
end

function nonlocal_support_refit_result()
    return broader_support_refit_with_env() do
        full_model = candidate_gas_optics(Float64)
        base_model = composed_support_base_model(full_model, WEIGHTED_GREEDY_SW_16_INDICES)
        current_objective, current_cases = full_hard_objective(base_model)
        candidates = nonlocal_support_candidates()
        prefilter_rows = [nonlocal_support_prefilter_row(full_model, candidate)
                          for candidate in candidates]
        sort!(prefilter_rows; by = row -> row.base_objective)
        rows = NamedTuple[]
        for candidate in Iterators.take(prefilter_rows,
                                        nonlocal_support_refit_candidate_limit())
            push!(rows, nonlocal_support_refit_row(full_model, candidate))
        end
        best = isempty(rows) ? nothing : argmin(row -> row.selected_objective, rows)
        best_objective = best === nothing ? current_objective : best.selected_objective
        return (
            case = "reduced_ecckd_nonlocal_support_refit_search",
            timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
            status = best_objective <= 1.0 ? "passes_hard_objective" :
                     best_objective < current_objective ? "nonlocal_support_refit_improved" :
                     "nonlocal_support_refit_rejected",
            objective_target = 1.0,
            candidate_source = "best saved nonlocal supports from random/swap/continuation/hardgate searches",
            requested_candidate_limit = nonlocal_support_refit_candidate_limit(),
            prefilter_evaluated_count = length(prefilter_rows),
            evaluated_candidate_count = length(rows),
            total_candidate_count = length(candidates),
            pressure_band_count = broader_support_refit_band_count(),
            pressure_partition = broader_support_refit_partition(),
            include_rayleigh = broader_support_refit_include_rayleigh(),
            current_indices = collect(WEIGHTED_GREEDY_SW_16_INDICES),
            current_objective = current_objective,
            current_worst_toa_forcing_error_w_m2 =
                maximum(case.toa_forcing_max_abs for case in current_cases),
            current_worst_surface_forcing_error_w_m2 =
                maximum(case.surface_forcing_max_abs for case in current_cases),
            current_worst_heating_rate_rmse_k_day = worst_heating_rmse(current_cases),
            best_label = best === nothing ? "" : best.label,
            best_indices = best === nothing ? Int[] : best.indices,
            best_objective = best_objective,
            best_objective_reduction = current_objective - best_objective,
            best_passed_hard_objective = best_objective <= 1.0,
            prefilter_rows = prefilter_rows,
            rows = rows,
        )
    end
end

function nonlocal_support_refit_markdown(result)
    lines = String[
        "# Reduced ecCKD Nonlocal Support-Plus-Refit Search",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Objective target | $(@sprintf("%.12g", result.objective_target)) |",
        "| Current objective | $(@sprintf("%.12g", result.current_objective)) |",
        "| Best objective | $(@sprintf("%.12g", result.best_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best passed hard objective | $(result.best_passed_hard_objective) |",
        "| Candidate sources | $(result.total_candidate_count) |",
        "| Prefilter candidates | $(result.prefilter_evaluated_count) / $(result.total_candidate_count) |",
        "| Candidates evaluated | $(result.evaluated_candidate_count) / $(result.total_candidate_count) |",
        "| Pressure bands | $(result.pressure_band_count) |",
        "| Pressure partition | $(result.pressure_partition) |",
        "| Include Rayleigh | $(result.include_rayleigh) |",
        "| Best label | $(isempty(result.best_label) ? "n/a" : result.best_label) |",
        "",
        "This artifact tests nonlocal 16-g supports already identified by the",
        "random, swap, continuation, and hardgate subset searches. Each support",
        "is evaluated after replaying the current composed table/component/",
        "gas-pressure chain and then running one bounded static-gas/H2O",
        "pressure-component refit against the full reduced hard objective.",
        "",
        "## Candidate Rows",
        "",
        "| Label | Base objective | Refit best objective | Selected objective | TOA | Surface | Heating RMSE | Accepted moves |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.rows
        push!(lines,
              "| $(row.label) | $(@sprintf("%.12g", row.base_objective)) | $(@sprintf("%.12g", row.refit_best_objective)) | $(@sprintf("%.12g", row.selected_objective)) | $(@sprintf("%.12g", row.selected_worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.selected_worst_surface_forcing_error_w_m2)) | $(@sprintf("%.12g", row.selected_worst_heating_rate_rmse_k_day)) | $(row.accepted_move_count) |")
    end
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? nonlocal_support_refit_result() : result
    mkpath(dirname(NONLOCAL_SUPPORT_REFIT_JSON))
    write(NONLOCAL_SUPPORT_REFIT_JSON, json_object(result) * "\n")
    write(NONLOCAL_SUPPORT_REFIT_MD, nonlocal_support_refit_markdown(result))
    print(nonlocal_support_refit_markdown(result))
    println("Wrote $NONLOCAL_SUPPORT_REFIT_JSON")
    println("Wrote $NONLOCAL_SUPPORT_REFIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
