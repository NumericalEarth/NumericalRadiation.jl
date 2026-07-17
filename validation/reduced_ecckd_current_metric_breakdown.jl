include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_accuracy.jl"))

const CURRENT_METRIC_BREAKDOWN_JSON =
    validation_results_path("reduced_ecckd_current_metric_breakdown.json")
const CURRENT_METRIC_BREAKDOWN_MD =
    validation_results_path("reduced_ecckd_current_metric_breakdown.md")

const CURRENT_REDUCED_SPEC = (
    ng_lw = 32,
    ng_sw = 16,
    method = "weighted_greedy_subset_boundary_table_continuation",
)

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

function current_metric_rows(case)
    rows = NamedTuple[]
    for variable in (:lw_up, :lw_down, :sw_up, :sw_down)
        metrics = getproperty(case.variables, variable)
        push!(rows, (
            case = case.case,
            variable = string(variable),
            metric = "rmse",
            value = metrics.rmse,
            threshold = ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
            normalized_value = metrics.rmse / ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
        ))
        push!(rows, (
            case = case.case,
            variable = string(variable),
            metric = "max_abs",
            value = metrics.max_abs,
            threshold = ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
            normalized_value =
                metrics.max_abs / ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        ))
    end
    heating = case.variables.heating_rate
    push!(rows, (
        case = case.case,
        variable = "heating_rate",
        metric = "rmse",
        value = heating.rmse,
        threshold = ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day,
        normalized_value =
            heating.rmse / ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day,
    ))
    push!(rows, (
        case = case.case,
        variable = "heating_rate",
        metric = "max_abs",
        value = heating.max_abs,
        threshold = ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
        normalized_value =
            heating.max_abs / ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
    ))
    push!(rows, (
        case = case.case,
        variable = "boundary",
        metric = "toa_forcing_max_abs",
        value = case.toa_forcing_max_abs,
        threshold = ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
        normalized_value =
            case.toa_forcing_max_abs / ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
    ))
    push!(rows, (
        case = case.case,
        variable = "boundary",
        metric = "surface_forcing_max_abs",
        value = case.surface_forcing_max_abs,
        threshold = ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
        normalized_value =
            case.surface_forcing_max_abs /
            ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
    ))
    return rows
end

function current_metric_breakdown_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    model = reduced_tabulated_model(full_model, CURRENT_REDUCED_SPEC)
    metrics = model_metrics(full_model, CURRENT_REDUCED_SPEC)
    rows = vcat([current_metric_rows(case) for case in metrics.cases]...)
    sort!(rows; by = row -> row.normalized_value, rev = true)
    worst = first(rows)
    return (
        case = "reduced_ecckd_current_metric_breakdown",
        timestamp_utc = string(Dates.now()),
        status = metrics.passed_hard_thresholds ? "passed" : "failed_threshold",
        model_method = CURRENT_REDUCED_SPEC.method,
        reduction_method = metrics.reduction_method,
        ng_lw = metrics.ng_lw,
        ng_sw = metrics.ng_sw,
        selected_shortwave_gpoints = collect(WEIGHTED_GREEDY_SW_16_INDICES),
        selected_shortwave_weights = collect(model.shortwave_weights),
        passed_hard_thresholds = metrics.passed_hard_thresholds,
        hard_objective = worst.normalized_value,
        worst_case = worst.case,
        worst_variable = worst.variable,
        worst_metric = worst.metric,
        worst_value = worst.value,
        worst_threshold = worst.threshold,
        rows = rows,
    )
end

function current_metric_breakdown_markdown(result)
    lines = String[
        "# Reduced ecCKD Current Metric Breakdown",
        "",
        "Status: **$(result.status)**",
        "",
        "Method: `$(result.reduction_method)`",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Hard objective | `$(@sprintf("%.12g", result.hard_objective))` |",
        "| Worst case | `$(result.worst_case)` |",
        "| Worst variable | `$(result.worst_variable)` |",
        "| Worst metric | `$(result.worst_metric)` |",
        "| Worst value | `$(@sprintf("%.12g", result.worst_value))` |",
        "| Worst threshold | `$(@sprintf("%.12g", result.worst_threshold))` |",
        "",
        "## Ranked Metrics",
        "",
        "| Rank | Case | Variable | Metric | Value | Threshold | Normalized |",
        "|---:|---|---|---|---:|---:|---:|",
    ]
    for (rank, row) in enumerate(result.rows)
        push!(lines,
              "| $(rank) | `$(row.case)` | `$(row.variable)` | `$(row.metric)` | $(@sprintf("%.12g", row.value)) | $(@sprintf("%.12g", row.threshold)) | $(@sprintf("%.12g", row.normalized_value)) |")
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = current_metric_breakdown_result()
    mkpath(dirname(CURRENT_METRIC_BREAKDOWN_JSON))
    write(CURRENT_METRIC_BREAKDOWN_JSON, json_object(result) * "\n")
    write(CURRENT_METRIC_BREAKDOWN_MD, current_metric_breakdown_markdown(result))
    print(current_metric_breakdown_markdown(result))
    println("Wrote $CURRENT_METRIC_BREAKDOWN_JSON")
    println("Wrote $CURRENT_METRIC_BREAKDOWN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
