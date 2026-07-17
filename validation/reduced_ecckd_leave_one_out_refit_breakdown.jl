include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_leave_one_out_weight_refit.jl"))

const LEAVE_ONE_OUT_REFIT_BREAKDOWN_JSON =
    validation_results_path("reduced_ecckd_leave_one_out_refit_breakdown.json")
const LEAVE_ONE_OUT_REFIT_BREAKDOWN_MD =
    validation_results_path("reduced_ecckd_leave_one_out_refit_breakdown.md")

target_omitted_gpoint() =
    parse(Int, get(ENV, "RH_REDUCED_LEAVE_ONE_OUT_BREAKDOWN_OMIT", "25"))

json_get(object, key) = object[key]
json_get(object, key, default) = haskey(object, key) ? object[key] : default

function metric_breakdown(case)
    entries = (
        (metric = "sw_up_rmse", ratio = case.variables.sw_up.rmse /
                                      ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
         value = case.variables.sw_up.rmse,
         threshold = ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2),
        (metric = "sw_down_rmse", ratio = case.variables.sw_down.rmse /
                                        ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
         value = case.variables.sw_down.rmse,
         threshold = ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2),
        (metric = "sw_up_max_abs", ratio = case.variables.sw_up.max_abs /
                                         ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
         value = case.variables.sw_up.max_abs,
         threshold = ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2),
        (metric = "sw_down_max_abs", ratio = case.variables.sw_down.max_abs /
                                           ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
         value = case.variables.sw_down.max_abs,
         threshold = ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2),
        (metric = "heating_rate_rmse", ratio = case.variables.heating_rate.rmse /
                                             ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day,
         value = case.variables.heating_rate.rmse,
         threshold = ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day),
        (metric = "heating_rate_max_abs", ratio = case.variables.heating_rate.max_abs /
                                               ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
         value = case.variables.heating_rate.max_abs,
         threshold = ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day),
        (metric = "toa_forcing", ratio = case.toa_forcing_max_abs /
                                      ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
         value = case.toa_forcing_max_abs,
         threshold = ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2),
        (metric = "surface_forcing", ratio = case.surface_forcing_max_abs /
                                          ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
         value = case.surface_forcing_max_abs,
         threshold = ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2),
    )
    return sort(collect(entries); by = entry -> entry.ratio, rev = true)
end

function single_leave_one_out_refit_breakdown(prior, omitted)
    rows = json_get(prior, "rows", Any[])
    matches = filter(row -> Int(json_get(row, "omitted_gpoint")) == omitted, rows)
    isempty(matches) && error("No leave-one-out refit row for omitted g-point $omitted")
    saved = only(matches)

    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    indices = setdiff(collect(1:length(full_model.shortwave_weights)), [omitted])
    weights = Float64.(json_get(saved, "refit_weights"))
    exact = exact_subset_result(full_model, indices, weights)
    case_breakdowns = [
        (
            case = case.case,
            passed_hard_thresholds = case.passed_hard_thresholds,
            objective = exact_case_objective(case),
            metrics = metric_breakdown(case),
        )
        for case in exact.exact.cases
    ]
    worst = case_breakdowns[argmax([case.objective for case in case_breakdowns])]
    return (
        case = "reduced_ecckd_leave_one_out_refit_breakdown",
        timestamp_utc = string(Dates.now()),
        status = exact.exact.passed_hard_thresholds ? "passed" : "failed_threshold",
        omitted_gpoint = omitted,
        ng_lw = exact.exact.ng_lw,
        ng_sw = exact.exact.ng_sw,
        selected_shortwave_gpoints = exact.exact.selected_shortwave_gpoints,
        saved_refit_objective = Float64(json_get(saved, "refit_objective")),
        recomputed_objective = exact.objective,
        objective_difference = abs(exact.objective - Float64(json_get(saved, "refit_objective"))),
        worst_case = worst.case,
        limiting_metric = first(worst.metrics).metric,
        limiting_metric_ratio = first(worst.metrics).ratio,
        limiting_metric_value = first(worst.metrics).value,
        limiting_metric_threshold = first(worst.metrics).threshold,
        case_breakdowns = case_breakdowns,
    )
end

function leave_one_out_refit_breakdown_result(omitted = target_omitted_gpoint())
    isfile(LEAVE_ONE_OUT_WEIGHT_REFIT_JSON) ||
        error("Missing $LEAVE_ONE_OUT_WEIGHT_REFIT_JSON")
    prior = JSON.parsefile(LEAVE_ONE_OUT_WEIGHT_REFIT_JSON)
    primary = single_leave_one_out_refit_breakdown(prior, omitted)
    best_objective_omitted = Int(json_get(prior, "best_omitted_gpoint", omitted))
    comparison_omitted = unique([omitted, best_objective_omitted])
    comparisons = [single_leave_one_out_refit_breakdown(prior, point)
                   for point in comparison_omitted]
    return merge(primary, (
        objective_best_omitted_gpoint = best_objective_omitted,
        comparison_omitted_gpoints = comparison_omitted,
        comparison_breakdowns = comparisons,
    ))
end

function breakdown_json_value(value)
    if value isa AbstractString
        return JSON.json(value)
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value isa NamedTuple
        return breakdown_json_object(value)
    elseif value isa AbstractVector || value isa Tuple
        return "[" * join(breakdown_json_value.(value), ", ") * "]"
    elseif value === nothing
        return "null"
    else
        return string(value)
    end
end

function breakdown_json_object(object)
    names = propertynames(object)
    lines = ["{"]
    for (i, name) in enumerate(names)
        comma = i == length(names) ? "" : ","
        push!(lines,
              "  \"$(name)\": $(breakdown_json_value(getproperty(object, name)))$(comma)")
    end
    push!(lines, "}")
    return join(lines, "\n")
end

function breakdown_markdown(result)
    lines = String[
        "# Reduced ecCKD Leave-One-Out Refit Breakdown",
        "",
        "Status: **$(result.status)**",
        "",
        "- Omitted SW g-point: $(result.omitted_gpoint)",
        "- Saved refit objective: $(@sprintf("%.12g", result.saved_refit_objective))",
        "- Recomputed objective: $(@sprintf("%.12g", result.recomputed_objective))",
        "- Worst case: `$(result.worst_case)`",
        "- Limiting metric: `$(result.limiting_metric)` = $(@sprintf("%.12g", result.limiting_metric_value)) / $(@sprintf("%.12g", result.limiting_metric_threshold)) = $(@sprintf("%.12g", result.limiting_metric_ratio))×",
        "",
        "## Compared Leave-One-Out Rows",
        "",
        "| Omitted SW g-point | Objective | Worst case | Limiting metric | Value | Threshold | Ratio |",
        "|---:|---:|---|---|---:|---:|---:|",
    ]
    for row in result.comparison_breakdowns
        push!(lines,
              "| $(row.omitted_gpoint) | $(@sprintf("%.12g", row.recomputed_objective)) | `$(row.worst_case)` | `$(row.limiting_metric)` | $(@sprintf("%.12g", row.limiting_metric_value)) | $(@sprintf("%.12g", row.limiting_metric_threshold)) | $(@sprintf("%.12g", row.limiting_metric_ratio)) |")
    end
    append!(lines, [
        "",
        "## Metric Ratios",
        "",
        "| Case | Rank | Metric | Value | Threshold | Ratio |",
        "|---|---:|---|---:|---:|---:|",
    ])
    for case in result.case_breakdowns
        for (rank, metric) in enumerate(case.metrics)
            push!(lines,
                  "| `$(case.case)` | $(rank) | `$(metric.metric)` | $(@sprintf("%.12g", metric.value)) | $(@sprintf("%.12g", metric.threshold)) | $(@sprintf("%.12g", metric.ratio)) |")
        end
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = leave_one_out_refit_breakdown_result()
    mkpath(dirname(LEAVE_ONE_OUT_REFIT_BREAKDOWN_JSON))
    write(LEAVE_ONE_OUT_REFIT_BREAKDOWN_JSON, breakdown_json_object(result) * "\n")
    write(LEAVE_ONE_OUT_REFIT_BREAKDOWN_MD, breakdown_markdown(result))
    print(breakdown_markdown(result))
    println("Wrote $LEAVE_ONE_OUT_REFIT_BREAKDOWN_JSON")
    println("Wrote $LEAVE_ONE_OUT_REFIT_BREAKDOWN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
