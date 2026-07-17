include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_hardgate_subset_search.jl"))

const IMPORTANCE_GROUP_SCAN_JSON =
    validation_results_path("reduced_ecckd_importance_group_scan.json")
const IMPORTANCE_GROUP_SCAN_MD =
    validation_results_path("reduced_ecckd_importance_group_scan.md")
const LEAVE_ONE_OUT_SCAN_JSON =
    validation_results_path("reduced_ecckd_leave_one_out_scan.json")

const FALLBACK_LEAVE_ONE_OUT_IMPORTANCE_OBJECTIVES = [
    16.822848913694394,
    47.412088861519806,
    39.62312928630089,
    58.24903991644533,
    36.17851599477376,
    36.26648013060352,
    58.962490097848864,
    24.076020765144982,
    44.33047071752185,
    141.6540772252957,
    23.7342337368,
    48.3330699416,
    54.7757602593,
    48.0909893011,
    8.71846678269,
    57.2057590383,
    2.27825890568,
    39.3251008859,
    7.860637352,
    6.1724999348,
    8.14981989363,
    2.77056885502,
    1.64509212825,
    4.8255956954,
    12.3434561459,
    109.659052713,
    130.75599397,
    122.19389007,
    51.963484808,
    20.3280041491,
    37.2933974373,
    81.0776393006,
]

importance_group_scan_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_IMPORTANCE_GROUP_SCAN_ITERATIONS", "3000"))

importance_group_scan_pnorm() =
    parse(Int, get(ENV, "RH_REDUCED_IMPORTANCE_GROUP_SCAN_P", "16"))

function live_leave_one_out_importance_objectives()
    isfile(LEAVE_ONE_OUT_SCAN_JSON) ||
        return (
            objectives = collect(FALLBACK_LEAVE_ONE_OUT_IMPORTANCE_OBJECTIVES),
            source = "fallback_embedded_leave_one_out_objectives",
        )
    text = read(LEAVE_ONE_OUT_SCAN_JSON, String)
    rows_match = match(r"\"rows\"\s*:\s*\[([\s\S]*)\]\s*\}\s*$", text)
    rows_match === nothing &&
        return (
            objectives = collect(FALLBACK_LEAVE_ONE_OUT_IMPORTANCE_OBJECTIVES),
            source = "fallback_embedded_leave_one_out_objectives",
        )
    rows_text = rows_match.captures[1]
    objectives = fill(NaN, length(FALLBACK_LEAVE_ONE_OUT_IMPORTANCE_OBJECTIVES))
    for row_match in eachmatch(r"\{[\s\S]*?\"omitted_gpoint\"\s*:\s*([0-9]+)[\s\S]*?\"objective\"\s*:\s*([-+0-9.eE]+)[\s\S]*?\}", rows_text)
        omitted_gpoint = parse(Int, row_match.captures[1])
        1 <= omitted_gpoint <= length(objectives) || continue
        objectives[omitted_gpoint] = parse(Float64, row_match.captures[2])
    end
    any(isnan, objectives) &&
        return (
            objectives = collect(FALLBACK_LEAVE_ONE_OUT_IMPORTANCE_OBJECTIVES),
            source = "fallback_embedded_leave_one_out_objectives",
        )
    return (
        objectives = objectives,
        source = "validation/results/reduced_ecckd_leave_one_out_scan.json",
    )
end

function json_escape(text)
    return replace(text, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")
end

function json_value(value)
    if value === nothing
        return "null"
    elseif value isa AbstractString
        return "\"" * json_escape(value) * "\""
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value isa NamedTuple
        return json_object(value)
    elseif value isa AbstractVector || value isa Tuple || value isa AbstractRange
        return "[" * join(json_value.(collect(value)), ", ") * "]"
    else
        return string(value)
    end
end

function json_object(object)
    names = propertynames(object)
    lines = ["{"]
    for (i, name) in enumerate(names)
        comma = i == length(names) ? "" : ","
        push!(lines, "  \"$(name)\": $(json_value(getproperty(object, name)))$(comma)")
    end
    push!(lines, "}")
    return join(lines, "\n")
end

function split_indices_evenly(indices, ngroups)
    ngroups == 0 && return Vector{Int}[]
    length(indices) >= ngroups ||
        throw(ArgumentError("cannot split $(length(indices)) indices into $ngroups groups"))
    edges = round.(Int, range(1, length(indices) + 1; length = ngroups + 1))
    groups = [collect(indices[edges[i]:(edges[i + 1] - 1)]) for i in 1:ngroups]
    all(!isempty, groups) || error("empty importance group generated")
    return groups
end

function importance_singleton_groups(singletons, nfull = 32, ngroups = 16)
    singleton_set = Set(singletons)
    remaining = [ig for ig in 1:nfull if !(ig in singleton_set)]
    merge_groups = split_indices_evenly(remaining, ngroups - length(singletons))
    groups = [[ig] for ig in sort(collect(singletons))]
    append!(groups, merge_groups)
    sort!(groups; by = group -> first(group))
    return groups
end

function grouped_shortwave_model(full_model, sw_groups)
    reduced = EcCKDTabulatedGasOpticsModel(
        gas_names = NumericalRadiation.gas_names(full_model),
        pressure_grid = full_model.pressure_grid,
        temperature_grid = full_model.temperature_grid,
        h2o_mole_fraction_grid = full_model.h2o_mole_fraction_grid,
        gas_reference_mole_fractions = full_model.gas_reference_mole_fractions,
        longwave_absorption = full_model.longwave_absorption,
        shortwave_absorption = weighted_group_reduce(full_model.shortwave_absorption,
                                                     full_model.shortwave_weights,
                                                     sw_groups),
        longwave_h2o_absorption = full_model.longwave_h2o_absorption,
        shortwave_h2o_absorption = weighted_group_reduce(full_model.shortwave_h2o_absorption,
                                                         full_model.shortwave_weights,
                                                         sw_groups),
        shortwave_rayleigh_molar_scattering =
            weighted_group_reduce(full_model.shortwave_rayleigh_molar_scattering,
                                  full_model.shortwave_weights,
                                  sw_groups),
        longwave_source_scale = full_model.longwave_source_scale,
        longwave_source_temperature_grid = full_model.longwave_source_temperature_grid,
        longwave_source_table = full_model.longwave_source_table,
        longwave_weights = full_model.longwave_weights,
        shortwave_weights = normalized_group_weights(full_model.shortwave_weights,
                                                     sw_groups),
    )
    return register_reduced_model(reduced;
        sw_groups,
        full_sw_weights = full_model.shortwave_weights,
    )
end

function hardgate_objective_from_cases(cases)
    return maximum(exact_case_objective, cases)
end

function grouped_model_result(label, full_model, sw_groups)
    model = grouped_shortwave_model(full_model, sw_groups)
    initial_cases = [case_metrics(case, model) for case in REDUCED_CASES]
    initial_objective = hardgate_objective_from_cases(initial_cases)
    context = search_context(model)
    weights, approximate_objective =
        optimized_subset_weights_hardgate(
            context,
            collect(1:length(sw_groups));
            initial_weights = model.shortwave_weights,
            max_iterations = importance_group_scan_iterations(),
            p = importance_group_scan_pnorm(),
        )
    refit_model = with_shortwave_weights(model, weights)
    refit_cases = [case_metrics(case, refit_model) for case in REDUCED_CASES]
    refit_objective = hardgate_objective_from_cases(refit_cases)
    return (
        label = label,
        ng_lw = 32,
        ng_sw = length(sw_groups),
        sw_groups = [collect(group) for group in sw_groups],
        initial_objective = initial_objective,
        refit_objective = refit_objective,
        objective_reduction = initial_objective - refit_objective,
        approximate_hardgate_objective = approximate_objective,
        passed_hard_thresholds = all(case -> case.passed_hard_thresholds, refit_cases),
        worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in refit_cases),
        worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in refit_cases),
        worst_sw_up_rmse_w_m2 =
            maximum(case.variables.sw_up.rmse for case in refit_cases),
        worst_sw_down_rmse_w_m2 =
            maximum(case.variables.sw_down.rmse for case in refit_cases),
        refit_weights = collect(weights),
    )
end

function importance_group_specs()
    importance = live_leave_one_out_importance_objectives()
    importance_objectives = importance.objectives
    critical_order = sortperm(importance_objectives; rev = true)
    redundant_order = sortperm(importance_objectives)
    specs = NamedTuple[]
    for k in (4, 6, 8, 10, 12)
        singletons = sort(critical_order[1:k])
        push!(specs, (
            label = "critical_singleton_k$(k)",
            groups = importance_singleton_groups(singletons),
        ))
    end
    for (critical_k, redundant_k) in ((8, 2), (8, 4), (10, 2), (10, 4))
        singletons = sort(unique(vcat(critical_order[1:critical_k],
                                      redundant_order[1:redundant_k])))
        length(singletons) < 16 || continue
        push!(specs, (
            label = "critical$(critical_k)_redundant$(redundant_k)_singletons",
            groups = importance_singleton_groups(singletons),
        ))
    end
    return (
        specs = specs,
        importance_source = importance.source,
    )
end

function importance_group_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    spec_result = importance_group_specs()
    rows = [
        grouped_model_result(spec.label, full_model, spec.groups)
        for spec in spec_result.specs
    ]
    best = argmin(row -> row.refit_objective, rows)
    pass_count = count(row -> row.passed_hard_thresholds, rows)
    return (
        case = "reduced_ecckd_importance_group_scan",
        timestamp_utc = string(Dates.now()),
        status = pass_count == 0 ? "all_importance_groups_failed" :
            "some_importance_groups_passed",
        reference_scope = collect(REDUCED_CASE_NAMES),
        importance_source = spec_result.importance_source,
        grouping_rule =
            "critical_singleton_kN keeps the N largest leave-one-out objective g-points as singleton bins, then splits all remaining g-points into 16 - N spectral-order groups; criticalN_redundantM also keeps the M smallest leave-one-out objective g-points as singleton bins before splitting the rest.",
        iterations = importance_group_scan_iterations(),
        p_norm = importance_group_scan_pnorm(),
        candidate_count = length(rows),
        pass_count = pass_count,
        best_label = best.label,
        best_refit_objective = best.refit_objective,
        best_toa_forcing_error_w_m2 = best.worst_toa_forcing_error_w_m2,
        best_surface_forcing_error_w_m2 = best.worst_surface_forcing_error_w_m2,
        rows = rows,
    )
end

function importance_group_scan_markdown(result)
    lines = String[
        "# Reduced ecCKD Importance-Guided Group Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "This diagnostic keeps high-impact leave-one-out shortwave g-points as",
        "singleton bins, merges the remaining g-points into 16 total groups,",
        "then refits nonnegative shortwave group weights against the normalized",
        "hard-gate objective.",
        "",
        "Importance source: `$(result.importance_source)`",
        "",
        "Grouping rule: $(result.grouping_rule)",
        "",
        "| Label | Passed | Initial objective | Refit objective | Worst TOA forcing | Worst surface forcing | Groups |",
        "|---|---:|---:|---:|---:|---:|---|",
    ]
    for row in result.rows
        group_text = join(["[" * join(group, ",") * "]" for group in row.sw_groups], " ")
        push!(lines,
              "| $(row.label) | $(row.passed_hard_thresholds) | $(@sprintf("%.12g", row.initial_objective)) | $(@sprintf("%.12g", row.refit_objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error_w_m2)) W m^-2 | $(@sprintf("%.12g", row.worst_surface_forcing_error_w_m2)) W m^-2 | `$(group_text)` |")
    end
    append!(lines, [
        "",
        "Best grouped candidate: `$(result.best_label)` with objective `$(@sprintf("%.12g", result.best_refit_objective))`.",
    ])
    return join(lines, "\n") * "\n"
end

function main()
    result = importance_group_scan_result()
    mkpath(dirname(IMPORTANCE_GROUP_SCAN_JSON))
    write(IMPORTANCE_GROUP_SCAN_JSON, json_object(result) * "\n")
    write(IMPORTANCE_GROUP_SCAN_MD, importance_group_scan_markdown(result))
    print(importance_group_scan_markdown(result))
    println("Wrote $IMPORTANCE_GROUP_SCAN_JSON")
    println("Wrote $IMPORTANCE_GROUP_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
