include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_retained_current_pressure_component_scan.jl"))

const BROADER_SUPPORT_REFIT_JSON =
    validation_results_path("reduced_ecckd_broader_support_refit_search.json")
const BROADER_SUPPORT_REFIT_MD =
    validation_results_path("reduced_ecckd_broader_support_refit_search.md")

broader_support_refit_radius() =
    parse(Int, get(ENV, "RH_REDUCED_BROADER_SUPPORT_REFIT_RADIUS", "2"))

broader_support_refit_candidate_limit() =
    parse(Int, get(ENV, "RH_REDUCED_BROADER_SUPPORT_REFIT_CANDIDATES", "2"))

broader_support_refit_prefilter_limit() =
    parse(Int, get(ENV, "RH_REDUCED_BROADER_SUPPORT_REFIT_PREFILTER_CANDIDATES", "12"))

broader_support_refit_band_count() =
    parse(Int, get(ENV, "RH_REDUCED_BROADER_SUPPORT_REFIT_BANDS", "4"))

broader_support_refit_partition() =
    get(ENV, "RH_REDUCED_BROADER_SUPPORT_REFIT_PARTITION", "log_pressure")

broader_support_refit_include_rayleigh() =
    lowercase(get(ENV, "RH_REDUCED_BROADER_SUPPORT_REFIT_INCLUDE_RAYLEIGH", "false")) in
    ("1", "true", "yes")

function broader_support_refit_with_env(f)
    keys = (
        "RH_CANDIDATE_GAS_OPTICS",
        "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_STATIC_GAS_SPLIT",
        "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_INCLUDE_RAYLEIGH",
        "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_HEATING_WEIGHT",
        "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_BOUNDARY_WEIGHT",
        "RH_REDUCED_CURRENT_COMPONENT_PRESSURE_PROBE_STEP",
        "RH_REDUCED_CURRENT_COMPONENT_PRESSURE_MAX_LOG_SCALE",
        "RH_REDUCED_CURRENT_COMPONENT_PRESSURE_SURFACE_CAP",
        "RH_REDUCED_CURRENT_COMPONENT_PRESSURE_TOA_TOLERANCE",
        "RH_REDUCED_CURRENT_COMPONENT_PRESSURE_MIN_OBJECTIVE_REDUCTION",
    )
    old = Dict(key => get(ENV, key, nothing) for key in keys)
    try
        ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
        ENV["RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_STATIC_GAS_SPLIT"] = "true"
        ENV["RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_INCLUDE_RAYLEIGH"] =
            string(broader_support_refit_include_rayleigh())
        ENV["RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_HEATING_WEIGHT"] =
            get(ENV, "RH_REDUCED_BROADER_SUPPORT_REFIT_HEATING_WEIGHT", "8.0")
        ENV["RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_BOUNDARY_WEIGHT"] =
            get(ENV, "RH_REDUCED_BROADER_SUPPORT_REFIT_BOUNDARY_WEIGHT", "1.0")
        ENV["RH_REDUCED_CURRENT_COMPONENT_PRESSURE_PROBE_STEP"] =
            get(ENV, "RH_REDUCED_BROADER_SUPPORT_REFIT_PROBE_STEP", "0.0009765625")
        ENV["RH_REDUCED_CURRENT_COMPONENT_PRESSURE_MAX_LOG_SCALE"] =
            get(ENV, "RH_REDUCED_BROADER_SUPPORT_REFIT_MAX_LOG_SCALE", "0.0001220703125")
        ENV["RH_REDUCED_CURRENT_COMPONENT_PRESSURE_SURFACE_CAP"] =
            get(ENV, "RH_REDUCED_BROADER_SUPPORT_REFIT_SURFACE_CAP", "2.03")
        ENV["RH_REDUCED_CURRENT_COMPONENT_PRESSURE_TOA_TOLERANCE"] =
            get(ENV, "RH_REDUCED_BROADER_SUPPORT_REFIT_TOA_TOLERANCE", "0.0")
        ENV["RH_REDUCED_CURRENT_COMPONENT_PRESSURE_MIN_OBJECTIVE_REDUCTION"] =
            get(ENV, "RH_REDUCED_BROADER_SUPPORT_REFIT_MIN_OBJECTIVE_REDUCTION",
                "6.25e-5")
        return f()
    finally
        for (key, value) in old
            if value === nothing
                delete!(ENV, key)
            else
                ENV[key] = value
            end
        end
    end
end

function composed_support_base_model(full_model, sw_indices)
    model = current_constrained_table_model(
        full_model;
        sw_indices = sw_indices,
        base_mode = "retained_topology",
    )
    for path in (
            RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_SCAN_JSON,
            RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION_SCAN_JSON,
            RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION2_SCAN_JSON,
            RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION3_SCAN_JSON,
        )
        moves = pressure_component_scan_selected_moves(path)
        isempty(moves) || apply_pressure_component_scan_moves!(model, moves)
    end
    return model
end

function support_refit_candidate_row(full_model, candidate)
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
    selected_toa = variant.accepted ?
        variant.accepted_worst_toa_forcing_error_w_m2 :
        maximum(case.toa_forcing_max_abs for case in base_cases)
    selected_surface = variant.accepted ?
        variant.accepted_worst_surface_forcing_error_w_m2 :
        maximum(case.surface_forcing_max_abs for case in base_cases)
    selected_heating = variant.accepted ?
        variant.accepted_worst_heating_rate_rmse_k_day :
        worst_heating_rmse(base_cases)
    return (
        local_index = candidate.local_index,
        removed_gpoint = candidate.removed_gpoint,
        added_gpoint = candidate.added_gpoint,
        indices = collect(candidate.indices),
        base_objective = base_objective,
        refit_best_objective = variant.best_exact_objective,
        refit_best_objective_reduction = variant.best_objective_reduction,
        refit_accepted = variant.accepted,
        selected_objective = selected_objective,
        selected_worst_toa_forcing_error_w_m2 = selected_toa,
        selected_worst_surface_forcing_error_w_m2 = selected_surface,
        selected_worst_heating_rate_rmse_k_day = selected_heating,
        accepted_move_count = variant.accepted_move_count,
    )
end

function support_prefilter_row(full_model, candidate)
    base_model = composed_support_base_model(full_model, candidate.indices)
    objective, cases = full_hard_objective(base_model)
    return (
        candidate...,
        base_objective = objective,
        base_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in cases),
        base_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in cases),
        base_worst_heating_rate_rmse_k_day = worst_heating_rmse(cases),
    )
end

function broader_support_refit_result()
    return broader_support_refit_with_env() do
        full_model = candidate_gas_optics(Float64)
        base_model = composed_support_base_model(full_model, WEIGHTED_GREEDY_SW_16_INDICES)
        current_objective, current_cases = full_hard_objective(base_model)
        candidates = neighbor_topology_candidates(
            WEIGHTED_GREEDY_SW_16_INDICES;
            radius = broader_support_refit_radius(),
        )
        prefilter_rows = NamedTuple[]
        for candidate in Iterators.take(candidates,
                                        broader_support_refit_prefilter_limit())
            push!(prefilter_rows, support_prefilter_row(full_model, candidate))
        end
        sort!(prefilter_rows; by = row -> row.base_objective)
        rows = NamedTuple[]
        for candidate in Iterators.take(prefilter_rows,
                                        broader_support_refit_candidate_limit())
            push!(rows, support_refit_candidate_row(full_model, candidate))
        end
        best = isempty(rows) ? nothing : argmin(row -> row.selected_objective, rows)
        best_objective = best === nothing ? current_objective : best.selected_objective
        return (
            case = "reduced_ecckd_broader_support_refit_search",
            timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
            status = best_objective <= 1.0 ? "passes_hard_objective" :
                     best_objective < current_objective ? "support_refit_improved" :
                     "support_refit_rejected",
            objective_target = 1.0,
            radius = broader_support_refit_radius(),
            requested_candidate_limit = broader_support_refit_candidate_limit(),
            prefilter_candidate_limit = broader_support_refit_prefilter_limit(),
            prefilter_evaluated_count = length(prefilter_rows),
            evaluated_candidate_count = length(rows),
            total_neighbor_candidate_count = length(candidates),
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
            best_removed_gpoint = best === nothing ? nothing : best.removed_gpoint,
            best_added_gpoint = best === nothing ? nothing : best.added_gpoint,
            best_indices = best === nothing ? Int[] : best.indices,
            best_objective = best_objective,
            best_objective_reduction = current_objective - best_objective,
            best_passed_hard_objective = best_objective <= 1.0,
            prefilter_rows = prefilter_rows,
            rows = rows,
        )
    end
end

function broader_support_refit_markdown(result)
    lines = String[
        "# Reduced ecCKD Broader Support-Plus-Refit Search",
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
        "| Radius | $(result.radius) |",
        "| Prefilter candidates | $(result.prefilter_evaluated_count) / $(result.total_neighbor_candidate_count) |",
        "| Candidates evaluated | $(result.evaluated_candidate_count) / $(result.total_neighbor_candidate_count) |",
        "| Pressure bands | $(result.pressure_band_count) |",
        "| Pressure partition | $(result.pressure_partition) |",
        "| Include Rayleigh | $(result.include_rayleigh) |",
        "| Best support move | $(result.best_removed_gpoint === nothing ? "n/a" : "g$(result.best_removed_gpoint) -> g$(result.best_added_gpoint)") |",
        "",
        "This artifact is intentionally stricter than prior support-only scans:",
        "each alternate support is evaluated after replaying the current composed",
        "retained table/component/gas-pressure chain and then running one bounded",
        "static-gas/H2O pressure-component refit against the full reduced hard",
        "objective.",
        "",
        "## Candidate Rows",
        "",
        "| Move | Base objective | Refit best objective | Selected objective | TOA | Surface | Heating RMSE | Accepted moves |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.rows
        push!(lines,
              "| g$(row.removed_gpoint) -> g$(row.added_gpoint) | $(@sprintf("%.12g", row.base_objective)) | $(@sprintf("%.12g", row.refit_best_objective)) | $(@sprintf("%.12g", row.selected_objective)) | $(@sprintf("%.12g", row.selected_worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", row.selected_worst_surface_forcing_error_w_m2)) | $(@sprintf("%.12g", row.selected_worst_heating_rate_rmse_k_day)) | $(row.accepted_move_count) |")
    end
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? broader_support_refit_result() : result
    mkpath(dirname(BROADER_SUPPORT_REFIT_JSON))
    write(BROADER_SUPPORT_REFIT_JSON, json_object(result) * "\n")
    write(BROADER_SUPPORT_REFIT_MD, broader_support_refit_markdown(result))
    print(broader_support_refit_markdown(result))
    println("Wrote $BROADER_SUPPORT_REFIT_JSON")
    println("Wrote $BROADER_SUPPORT_REFIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
