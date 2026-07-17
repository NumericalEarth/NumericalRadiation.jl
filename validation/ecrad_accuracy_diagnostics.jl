include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "ecrad_accuracy_gate.jl"))

function ratio(value, threshold)
    value === nothing && return nothing
    threshold == 0 && return Inf
    return value / threshold
end

function metric_rows(gate_result)
    rows = NamedTuple[]
    for case in gate_result.cases
        for metric in case.comparisons
            push!(rows, (
                case = case.case,
                metric = metric.variable * "_rmse",
                value = metric.rmse,
                threshold = metric.rmse_threshold,
                ratio = ratio(metric.rmse, metric.rmse_threshold),
                units = metric.units,
                passed = metric.passed,
            ))
            push!(rows, (
                case = case.case,
                metric = metric.variable * "_max_abs",
                value = metric.max_abs,
                threshold = metric.max_abs_threshold,
                ratio = ratio(metric.max_abs, metric.max_abs_threshold),
                units = metric.units,
                passed = metric.passed,
            ))
        end
        for metric in case.forcing_comparisons
            push!(rows, (
                case = case.case,
                metric = metric.metric,
                value = metric.max_abs,
                threshold = metric.threshold,
                ratio = ratio(metric.max_abs, metric.threshold),
                units = metric.units,
                passed = metric.passed,
            ))
        end
    end
    return rows
end

function worst_rows(rows; n = 12)
    sortable = filter(row -> row.ratio !== nothing, rows)
    sort!(sortable; by = row -> row.ratio, rev = true)
    return sortable[1:min(n, length(sortable))]
end

function summarize_by_case(rows)
    cases = unique(row.case for row in rows)
    summaries = NamedTuple[]
    for case in cases
        ratios = [row.ratio for row in rows if row.case == case && row.ratio !== nothing]
        push!(summaries, (
            case = case,
            failed_metric_count = count(row -> row.case == case && !row.passed, rows),
            worst_ratio = isempty(ratios) ? nothing : maximum(ratios),
        ))
    end
    return summaries
end

function run_accuracy_diagnostics()
    gate = run_accuracy_gate()
    rows = metric_rows(gate)
    return (
        case = "ecrad_accuracy_diagnostics",
        date = string(Dates.now()),
        gate_status = gate.status,
        candidate_prefix = CANDIDATE_PREFIX,
        failed_metric_count = count(row -> !row.passed, rows),
        case_summary = summarize_by_case(rows),
        worst_metrics = worst_rows(rows),
    )
end

function markdown_diagnostics_report(result)
    lines = String[
        "# ecRad Accuracy Diagnostics",
        "",
        "Gate status: **$(result.gate_status)**",
        "",
        "This report ranks current `$(result.candidate_prefix)*` errors by threshold exceedance. It is diagnostic only; the hard pass/fail source of truth remains `validation/ecrad_accuracy_gate.jl`.",
        "",
        "Failed metric count: $(result.failed_metric_count)",
        "",
        "## Case Summary",
        "",
        "| Case | Failed metrics | Worst threshold ratio |",
        "|---|---:|---:|",
    ]
    for row in result.case_summary
        worst_ratio = row.worst_ratio === nothing ? "missing" : @sprintf("%.6g", row.worst_ratio)
        push!(lines, "| $(row.case) | $(row.failed_metric_count) | $worst_ratio |")
    end
    append!(lines, [
        "",
        "## Worst Metrics",
        "",
        "| Case | Metric | Value | Threshold | Ratio |",
        "|---|---|---:|---:|---:|",
    ])
    for row in result.worst_metrics
        value = row.value === nothing ? "missing" : @sprintf("%.12g", row.value)
        threshold = @sprintf("%.12g", row.threshold)
        ratio_text = row.ratio === nothing ? "missing" : @sprintf("%.6g", row.ratio)
        push!(lines, "| $(row.case) | `$(row.metric)` | $value $(row.units) | $threshold $(row.units) | $ratio_text |")
    end
    return join(lines, "\n") * "\n"
end

function diagnostics_main()
    result = run_accuracy_diagnostics()
    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "ecrad_accuracy_diagnostics.json")
    md_path = joinpath(results_dir, "ecrad_accuracy_diagnostics.md")
    write(json_path, json_object(result))
    write(md_path, markdown_diagnostics_report(result))

    print(markdown_diagnostics_report(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    diagnostics_main()
end
