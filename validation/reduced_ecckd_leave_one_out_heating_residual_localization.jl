include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_leave_one_out_weight_refit.jl"))

const LEAVE_ONE_OUT_HEATING_RESIDUAL_LOCALIZATION_JSON =
    validation_results_path("reduced_ecckd_leave_one_out_heating_residual_localization.json")
const LEAVE_ONE_OUT_HEATING_RESIDUAL_LOCALIZATION_MD =
    validation_results_path("reduced_ecckd_leave_one_out_heating_residual_localization.md")
const LEAVE_ONE_OUT_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_leave_one_out_weight_refit.json")

json_get(object, key) = object[key]
json_get(object, key, default) = haskey(object, key) ? object[key] : default

heating_residual_omitted_gpoint() =
    parse(Int, get(ENV, "RH_REDUCED_LOO_HEATING_RESIDUAL_OMIT", "25"))

function saved_leave_one_out_weights_for_residual(prior, omitted)
    rows = json_get(prior, "rows", Any[])
    matches = filter(row -> Int(json_get(row, "omitted_gpoint")) == omitted, rows)
    isempty(matches) && error("No leave-one-out refit row for omitted g-point $omitted")
    row = only(matches)
    return Float64.(json_get(row, "refit_weights")),
           Float64(json_get(row, "refit_objective"))
end

function leave_one_out_model_for_residual(full_model, prior, omitted)
    indices = setdiff(collect(1:length(full_model.shortwave_weights)), [omitted])
    weights, saved_objective = saved_leave_one_out_weights_for_residual(prior, omitted)
    model = indexed_tabulated_model(full_model,
                                    collect(1:size(full_model.longwave_absorption, 1)),
                                    indices)
    model = with_shortwave_weights(model, weights)
    return model, indices, saved_objective
end

function layer_summary_rows(diff, pressure_interfaces; topn = 8)
    layer_rmse = [sqrt(sum(abs2, diff[k, :]) / size(diff, 2)) for k in axes(diff, 1)]
    layer_bias = [sum(diff[k, :]) / size(diff, 2) for k in axes(diff, 1)]
    order = sortperm(layer_rmse; rev = true)
    rows = NamedTuple[]
    for layer in first(order, min(topn, length(order)))
        column = argmax(abs.(view(diff, layer, :)))
        p_top = pressure_interfaces[layer, column]
        p_bottom = pressure_interfaces[layer + 1, column]
        push!(rows, (
            layer = layer,
            worst_column = column,
            pressure_top_pa = p_top,
            pressure_bottom_pa = p_bottom,
            pressure_mid_pa = 0.5 * (p_top + p_bottom),
            layer_rmse_k_day = layer_rmse[layer],
            layer_mean_bias_k_day = layer_bias[layer],
            layer_max_abs_k_day = maximum(abs, diff[layer, :]),
            residual_at_worst_column_k_day = diff[layer, column],
        ))
    end
    return rows
end

function heating_residual_case_summary(case, model)
    candidate = candidate_arrays(case.path, model)
    nc = require_ncdatasets()
    nc.NCDataset(reference_path(case.path)) do dataset
        reference_heating = Array(dataset["heating_rate"])
        pressure_interfaces = Array(dataset["pressure_interface"])
        diff = candidate.heating_rate .- reference_heating
        max_index = argmax(abs.(diff))
        max_layer = max_index[1]
        max_column = max_index[2]
        rmse = sqrt(sum(abs2, diff) / length(diff))
        max_abs = abs(diff[max_index])
        p_top = pressure_interfaces[max_layer, max_column]
        p_bottom = pressure_interfaces[max_layer + 1, max_column]
        return (
            case = case.case,
            heating_rate_rmse_k_day = rmse,
            heating_rate_rmse_ratio =
                rmse / ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day,
            heating_rate_max_abs_k_day = max_abs,
            heating_rate_max_abs_ratio =
                max_abs / ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
            max_abs_layer = max_layer,
            max_abs_column = max_column,
            max_abs_pressure_top_pa = p_top,
            max_abs_pressure_bottom_pa = p_bottom,
            max_abs_pressure_mid_pa = 0.5 * (p_top + p_bottom),
            residual_at_max_abs_k_day = diff[max_index],
            vertical_mean_bias_k_day = sum(diff) / length(diff),
            layer_summary = layer_summary_rows(diff, pressure_interfaces),
        )
    end
end

function single_heating_residual_localization(full_model, prior, omitted)
    model, indices, saved_objective = leave_one_out_model_for_residual(full_model, prior, omitted)
    cases = [heating_residual_case_summary(case, model) for case in REDUCED_CASES]
    worst = cases[argmax([case.heating_rate_rmse_ratio for case in cases])]
    return (
        omitted_gpoint = omitted,
        ng_lw = size(model.longwave_absorption, 1),
        ng_sw = size(model.shortwave_absorption, 1),
        selected_shortwave_gpoints = indices,
        saved_refit_objective = saved_objective,
        worst_case = worst.case,
        worst_heating_rate_rmse_k_day = worst.heating_rate_rmse_k_day,
        worst_heating_rate_rmse_ratio = worst.heating_rate_rmse_ratio,
        worst_heating_rate_max_abs_k_day = worst.heating_rate_max_abs_k_day,
        worst_heating_rate_max_abs_ratio = worst.heating_rate_max_abs_ratio,
        cases = cases,
    )
end

function heating_residual_localization_result(omitted = heating_residual_omitted_gpoint())
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    prior = JSON.parsefile(LEAVE_ONE_OUT_WEIGHT_REFIT_JSON)
    full_model = candidate_gas_optics(Float64)
    primary = single_heating_residual_localization(full_model, prior, omitted)
    best_objective_omitted = Int(json_get(prior, "best_omitted_gpoint", omitted))
    comparison_omitted = unique([omitted, best_objective_omitted])
    comparisons = [point == omitted ? primary :
                   single_heating_residual_localization(full_model, prior, point)
                   for point in comparison_omitted]
    return merge(primary, (
        case = "reduced_ecckd_leave_one_out_heating_residual_localization",
        timestamp_utc = string(Dates.now()),
        status = "passed",
        objective_best_omitted_gpoint = best_objective_omitted,
        comparison_omitted_gpoints = comparison_omitted,
        comparison_localizations = comparisons,
    ))
end

function localization_markdown(result)
    lines = String[
        "# Reduced ecCKD Leave-One-Out Heating Residual Localization",
        "",
        "Status: **$(result.status)**",
        "",
        "- Omitted SW g-point: $(result.omitted_gpoint)",
        "- Model: $(result.ng_lw)x$(result.ng_sw)",
        "- Saved refit objective: $(@sprintf("%.12g", result.saved_refit_objective))",
        "- Worst case: `$(result.worst_case)`",
        "- Worst heating RMSE: $(@sprintf("%.12g", result.worst_heating_rate_rmse_k_day)) K day^-1 ($(@sprintf("%.12g", result.worst_heating_rate_rmse_ratio))x threshold)",
        "- Worst heating max abs: $(@sprintf("%.12g", result.worst_heating_rate_max_abs_k_day)) K day^-1 ($(@sprintf("%.12g", result.worst_heating_rate_max_abs_ratio))x threshold)",
        "",
        "## Compared Leave-One-Out Rows",
        "",
        "| Omitted SW g-point | Saved objective | Worst case | Heating RMSE | RMSE ratio | Max abs | Max layer | Max pressure mid | Residual at max |",
        "|---:|---:|---|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.comparison_localizations
        worst_case = only(filter(case -> case.case == row.worst_case, row.cases))
        push!(lines,
              "| $(row.omitted_gpoint) | $(@sprintf("%.12g", row.saved_refit_objective)) | `$(row.worst_case)` | $(@sprintf("%.12g", row.worst_heating_rate_rmse_k_day)) | $(@sprintf("%.12g", row.worst_heating_rate_rmse_ratio)) | $(@sprintf("%.12g", row.worst_heating_rate_max_abs_k_day)) | $(worst_case.max_abs_layer) | $(@sprintf("%.12g", worst_case.max_abs_pressure_mid_pa)) | $(@sprintf("%.12g", worst_case.residual_at_max_abs_k_day)) |")
    end
    append!(lines, [
        "",
        "## Case Summary",
        "",
        "| Case | Heating RMSE | RMSE ratio | Max abs | Max layer | Max column | Max pressure mid | Residual at max | Mean bias |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
    ])
    for case in result.cases
        push!(lines,
              "| `$(case.case)` | $(@sprintf("%.12g", case.heating_rate_rmse_k_day)) | $(@sprintf("%.12g", case.heating_rate_rmse_ratio)) | $(@sprintf("%.12g", case.heating_rate_max_abs_k_day)) | $(case.max_abs_layer) | $(case.max_abs_column) | $(@sprintf("%.12g", case.max_abs_pressure_mid_pa)) | $(@sprintf("%.12g", case.residual_at_max_abs_k_day)) | $(@sprintf("%.12g", case.vertical_mean_bias_k_day)) |")
    end
    push!(lines, "", "## Dominant Layers", "")
    for case in result.cases
        push!(lines, "### $(case.case)", "")
        push!(lines, "| Rank | Layer | Column | Pressure mid | Layer RMSE | Layer max abs | Layer bias | Residual at worst column |")
        push!(lines, "|---:|---:|---:|---:|---:|---:|---:|---:|")
        for (rank, row) in enumerate(case.layer_summary)
            push!(lines,
                  "| $(rank) | $(row.layer) | $(row.worst_column) | $(@sprintf("%.12g", row.pressure_mid_pa)) | $(@sprintf("%.12g", row.layer_rmse_k_day)) | $(@sprintf("%.12g", row.layer_max_abs_k_day)) | $(@sprintf("%.12g", row.layer_mean_bias_k_day)) | $(@sprintf("%.12g", row.residual_at_worst_column_k_day)) |")
        end
        push!(lines, "")
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = heating_residual_localization_result()
    mkpath(dirname(LEAVE_ONE_OUT_HEATING_RESIDUAL_LOCALIZATION_JSON))
    open(LEAVE_ONE_OUT_HEATING_RESIDUAL_LOCALIZATION_JSON, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
    write(LEAVE_ONE_OUT_HEATING_RESIDUAL_LOCALIZATION_MD,
          localization_markdown(result))
    print(localization_markdown(result))
    println("Wrote $LEAVE_ONE_OUT_HEATING_RESIDUAL_LOCALIZATION_JSON")
    println("Wrote $LEAVE_ONE_OUT_HEATING_RESIDUAL_LOCALIZATION_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
