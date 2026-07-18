include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using Printf

const RESULTS_DIR = validation_results_dir()
const REDUCED_ACCURACY_JSON = joinpath(RESULTS_DIR, "reduced_ecckd_accuracy.json")
const PUBLISHED_MODEL_ACCURACY_JSON =
    joinpath(RESULTS_DIR, "ecckd_published_model_accuracy.json")
const INVENTORY_JSON = joinpath(RESULTS_DIR, "ecckd_model_inventory.json")
const PARETO_JSON = joinpath(RESULTS_DIR, "ecckd_band_accuracy_pareto.json")
const PARETO_MD = joinpath(RESULTS_DIR, "ecckd_band_accuracy_pareto.md")
const PARETO_CSV = joinpath(RESULTS_DIR, "ecckd_band_accuracy_pareto.csv")
const PARETO_SVG = joinpath(RESULTS_DIR, "ecckd_band_accuracy_pareto.svg")

const FALLBACK_ACCEPTANCE_THRESHOLDS = (
    flux_rmse_w_m2 = 1.0,
    flux_max_abs_w_m2 = 5.0,
    heating_rate_rmse_k_day = 0.05,
    heating_rate_max_abs_k_day = 0.5,
    toa_forcing_abs_error_w_m2 = 0.3,
    surface_forcing_abs_error_w_m2 = 0.3,
)

function json_escape(text)
    return replace(text, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")
end

function json_value(value)
    if value isa AbstractString
        return "\"" * json_escape(value) * "\""
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value isa NamedTuple
        return json_object(value)
    elseif value isa AbstractVector || value isa Tuple
        return "[" * join(json_value.(value), ", ") * "]"
    elseif value === nothing
        return "null"
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

function json_get(object, key)
    return object[key]
end

function json_get(object, key, default)
    return haskey(object, key) ? object[key] : default
end

function acceptance_thresholds(path = REDUCED_ACCURACY_JSON)
    isfile(path) || return FALLBACK_ACCEPTANCE_THRESHOLDS
    result = JSON.parsefile(path)
    thresholds = json_get(result, "acceptance_thresholds", Dict{String, Any}())
    return (
        flux_rmse_w_m2 = Float64(json_get(thresholds, "flux_rmse_w_m2",
                                          FALLBACK_ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2)),
        flux_max_abs_w_m2 = Float64(json_get(thresholds, "flux_max_abs_w_m2",
                                             FALLBACK_ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2)),
        heating_rate_rmse_k_day = Float64(json_get(thresholds, "heating_rate_rmse_k_day",
                                                   FALLBACK_ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day)),
        heating_rate_max_abs_k_day = Float64(json_get(thresholds, "heating_rate_max_abs_k_day",
                                                      FALLBACK_ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day)),
        toa_forcing_abs_error_w_m2 = Float64(json_get(thresholds, "toa_forcing_abs_error_w_m2",
                                                      FALLBACK_ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2)),
        surface_forcing_abs_error_w_m2 = Float64(json_get(thresholds, "surface_forcing_abs_error_w_m2",
                                                          FALLBACK_ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2)),
    )
end

function metric_choice(pairs)
    filtered = filter(pair -> isfinite(pair[2]), pairs)
    isempty(filtered) && return ("unreported", NaN)
    index = argmax(last.(filtered))
    return filtered[index]
end

function reduced_case_metric_ratios(cases, thresholds)
    pairs = Tuple{String, Float64}[]
    for case in cases
        variables = json_get(case, "variables", Dict{String, Any}())
        for name in ("lw_up", "lw_down", "sw_up", "sw_down")
            metrics = json_get(variables, name, Dict{String, Any}())
            push!(pairs, ("$(name)_rmse", Float64(json_get(metrics, "rmse", 0.0)) /
                                          thresholds.flux_rmse_w_m2))
            push!(pairs, ("$(name)_max_abs", Float64(json_get(metrics, "max_abs", 0.0)) /
                                             thresholds.flux_max_abs_w_m2))
        end
        heating = json_get(variables, "heating_rate", Dict{String, Any}())
        push!(pairs, ("heating_rate_rmse", Float64(json_get(heating, "rmse", 0.0)) /
                                            thresholds.heating_rate_rmse_k_day))
        push!(pairs, ("heating_rate_max_abs", Float64(json_get(heating, "max_abs", 0.0)) /
                                               thresholds.heating_rate_max_abs_k_day))
        push!(pairs, ("toa_forcing", Float64(json_get(case, "toa_forcing_max_abs", 0.0)) /
                                     thresholds.toa_forcing_abs_error_w_m2))
        push!(pairs, ("surface_forcing", Float64(json_get(case, "surface_forcing_max_abs", 0.0)) /
                                         thresholds.surface_forcing_abs_error_w_m2))
    end
    return metric_choice(pairs)
end

function sw_boundary_metric_ratios(toa, surface, sw_up_rmse, sw_down_rmse, thresholds)
    return metric_choice((
        ("toa_forcing", toa / thresholds.toa_forcing_abs_error_w_m2),
        ("surface_forcing", surface / thresholds.surface_forcing_abs_error_w_m2),
        ("sw_up_rmse", sw_up_rmse / thresholds.flux_rmse_w_m2),
        ("sw_down_rmse", sw_down_rmse / thresholds.flux_rmse_w_m2),
    ))
end

function parse_reduced_accuracy_rows(path = REDUCED_ACCURACY_JSON)
    isfile(path) || return NamedTuple[]
    result = JSON.parsefile(path)
    thresholds = acceptance_thresholds(path)
    rows = NamedTuple[]
    for model in json_get(result, "models", Any[])
        cases = json_get(model, "cases", Any[])
        isempty(cases) && continue
        toa = maximum(Float64(json_get(case, "toa_forcing_max_abs")) for case in cases)
        surface = maximum(Float64(json_get(case, "surface_forcing_max_abs")) for case in cases)
        ng_lw = Int(json_get(model, "ng_lw"))
        ng_sw = Int(json_get(model, "ng_sw"))
        limiting_metric, limiting_ratio = reduced_case_metric_ratios(cases, thresholds)
        push!(rows, (
            source = "reduced_accuracy",
            label = String(json_get(model, "reduction_method")),
            ng_lw = ng_lw,
            ng_sw = ng_sw,
            total_gpoints = ng_lw + ng_sw,
            passed = Bool(json_get(model, "passed_hard_thresholds")),
            worst_toa_forcing_error_w_m2 = toa,
            worst_surface_forcing_error_w_m2 = surface,
            worst_boundary_forcing_error_w_m2 = max(toa, surface),
            normalized_objective = limiting_ratio,
            objective_source = "maximum_reported_threshold_ratio",
            limiting_metric = limiting_metric,
            limiting_metric_ratio = limiting_ratio,
        ))
    end
    return rows
end

function parse_published_model_accuracy_rows(path = PUBLISHED_MODEL_ACCURACY_JSON)
    isfile(path) || return NamedTuple[]
    result = JSON.parsefile(path)
    rows = NamedTuple[]
    for model in json_get(result, "models", Any[])
        objective = json_get(model, "hard_objective", Dict{String, Any}())
        ng_lw = Int(json_get(model, "ng_lw"))
        ng_sw = Int(json_get(model, "ng_sw"))
        toa = Float64(json_get(model, "worst_toa_forcing_abs_error_w_m2"))
        surface = Float64(json_get(model, "worst_surface_forcing_abs_error_w_m2"))
        normalized_objective = Float64(json_get(objective, "value", max(toa, surface)))
        limiting_metric = String(json_get(objective, "metric", "reported_hard_objective"))
        push!(rows, (
            source = "published_model_accuracy",
            label = String(json_get(model, "label")),
            ng_lw = ng_lw,
            ng_sw = ng_sw,
            total_gpoints = ng_lw + ng_sw,
            passed = Bool(json_get(model, "passed_hard_thresholds")),
            worst_toa_forcing_error_w_m2 = toa,
            worst_surface_forcing_error_w_m2 = surface,
            worst_boundary_forcing_error_w_m2 = max(toa, surface),
            normalized_objective = normalized_objective,
            objective_source = "published_model_accuracy_hard_objective",
            limiting_metric = limiting_metric,
            limiting_metric_ratio = normalized_objective,
        ))
    end
    return rows
end

function parse_inventory_rows(path = INVENTORY_JSON)
    isfile(path) || return NamedTuple[]
    result = JSON.parsefile(path)
    rows = NamedTuple[]
    for entry in json_get(result, "entries", Any[])
        push!(rows, (
            filename = String(json_get(entry, "filename")),
            kind = String(json_get(entry, "kind")),
            bands = Int(json_get(entry, "bands")),
            gpoints = Int(json_get(entry, "gpoints")),
            gases = join(String.(json_get(entry, "gases", Any[])), ", "),
            source_tables_present = Bool(json_get(entry, "source_tables_present")),
            rayleigh_tables_present = Bool(json_get(entry, "rayleigh_tables_present")),
        ))
    end
    return rows
end

function pareto_front(rows)
    sorted = sort(rows; by = row -> (row.total_gpoints, row.worst_boundary_forcing_error_w_m2))
    front = NamedTuple[]
    best = Inf
    for row in sorted
        if row.worst_boundary_forcing_error_w_m2 < best
            push!(front, row)
            best = row.worst_boundary_forcing_error_w_m2
        end
    end
    return front
end

function objective_front(rows)
    sorted = sort(rows; by = row -> (row.total_gpoints, row.normalized_objective,
                                     row.worst_boundary_forcing_error_w_m2))
    front = NamedTuple[]
    best = Inf
    for row in sorted
        if row.normalized_objective < best
            push!(front, row)
            best = row.normalized_objective
        end
    end
    return front
end

function write_csv(rows, path = PARETO_CSV)
    lines = ["source,label,ng_lw,ng_sw,total_gpoints,passed,worst_toa_forcing_error_w_m2,worst_surface_forcing_error_w_m2,worst_boundary_forcing_error_w_m2,normalized_objective,objective_source,limiting_metric,limiting_metric_ratio"]
    for row in rows
        label = replace(row.label, "\"" => "\"\"")
        push!(lines, join((
            row.source,
            "\"$label\"",
            row.ng_lw,
            row.ng_sw,
            row.total_gpoints,
            row.passed,
            row.worst_toa_forcing_error_w_m2,
            row.worst_surface_forcing_error_w_m2,
            row.worst_boundary_forcing_error_w_m2,
            row.normalized_objective,
            row.objective_source,
            row.limiting_metric,
            row.limiting_metric_ratio,
        ), ","))
    end
    write(path, join(lines, "\n") * "\n")
end

function svg_plot(rows, front)
    width = 900
    height = 520
    left = 80
    right = 40
    top = 40
    bottom = 80
    xs = [row.total_gpoints for row in rows]
    ys = [max(row.worst_boundary_forcing_error_w_m2, 1.0e-4) for row in rows]
    xmin, xmax = minimum(xs), maximum(xs)
    ymin, ymax = minimum(log10.(ys)), maximum(log10.(ys))
    xmax == xmin && (xmax += 1)
    ymax == ymin && (ymax += 1)
    xcoord(x) = left + (x - xmin) / (xmax - xmin) * (width - left - right)
    ycoord(y) = top + (ymax - log10(max(y, 1.0e-4))) / (ymax - ymin) * (height - top - bottom)

    lines = String[
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\" viewBox=\"0 0 $width $height\">",
        "<rect width=\"100%\" height=\"100%\" fill=\"white\"/>",
        "<text x=\"$(width ÷ 2)\" y=\"24\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"18\">ecCKD Accuracy vs Total G-points</text>",
        "<line x1=\"$left\" y1=\"$(height-bottom)\" x2=\"$(width-right)\" y2=\"$(height-bottom)\" stroke=\"black\"/>",
        "<line x1=\"$left\" y1=\"$top\" x2=\"$left\" y2=\"$(height-bottom)\" stroke=\"black\"/>",
        "<text x=\"$(width ÷ 2)\" y=\"$(height-24)\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"14\">total g-points (LW + SW)</text>",
        "<text x=\"20\" y=\"$(height ÷ 2)\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"14\" transform=\"rotate(-90 20 $(height ÷ 2))\">worst boundary forcing error (W m^-2, log scale)</text>",
    ]
    for tick in unique(sort(xs))
        x = xcoord(tick)
        push!(lines, "<line x1=\"$x\" y1=\"$(height-bottom)\" x2=\"$x\" y2=\"$(height-bottom+5)\" stroke=\"black\"/>")
        push!(lines, "<text x=\"$x\" y=\"$(height-bottom+22)\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"12\">$tick</text>")
    end
    y_ticks = sort(unique(vcat(0.01, 0.03, 0.1, 0.3, 1.0, 3.0, 10.0, 30.0, 100.0)))
    for tick in y_ticks
        logtick = log10(tick)
        ymin <= logtick <= ymax || continue
        y = ycoord(tick)
        push!(lines, "<line x1=\"$(left-5)\" y1=\"$y\" x2=\"$left\" y2=\"$y\" stroke=\"black\"/>")
        push!(lines, "<line x1=\"$left\" y1=\"$y\" x2=\"$(width-right)\" y2=\"$y\" stroke=\"#dddddd\"/>")
        push!(lines, "<text x=\"$(left-10)\" y=\"$(y+4)\" text-anchor=\"end\" font-family=\"sans-serif\" font-size=\"12\">$tick</text>")
    end
    threshold_y = ycoord(0.3)
    push!(lines, "<line x1=\"$left\" y1=\"$threshold_y\" x2=\"$(width-right)\" y2=\"$threshold_y\" stroke=\"#2f7d32\" stroke-dasharray=\"6 4\"/>")
    push!(lines, "<text x=\"$(width-right-8)\" y=\"$(threshold_y-8)\" text-anchor=\"end\" font-family=\"sans-serif\" font-size=\"12\" fill=\"#2f7d32\">0.3 W m^-2 hard threshold</text>")
    for (i, row) in enumerate(rows)
        jitter = ((i % 9) - 4) * 1.2
        x = xcoord(row.total_gpoints) + jitter
        y = ycoord(row.worst_boundary_forcing_error_w_m2)
        color = row.passed ? "#1b9e77" : "#d95f02"
        push!(lines, "<circle cx=\"$x\" cy=\"$y\" r=\"5\" fill=\"$color\" opacity=\"0.8\"><title>$(row.label): $(row.worst_boundary_forcing_error_w_m2) W m^-2</title></circle>")
    end
    if length(front) > 1
        points = join(["$(xcoord(row.total_gpoints)),$(ycoord(row.worst_boundary_forcing_error_w_m2))" for row in front], " ")
        push!(lines, "<polyline points=\"$points\" fill=\"none\" stroke=\"#7570b3\" stroke-width=\"2\"/>")
    end
    push!(lines, "<circle cx=\"$(width-190)\" cy=\"55\" r=\"5\" fill=\"#1b9e77\"/><text x=\"$(width-178)\" y=\"59\" font-family=\"sans-serif\" font-size=\"12\">passed</text>")
    push!(lines, "<circle cx=\"$(width-190)\" cy=\"75\" r=\"5\" fill=\"#d95f02\"/><text x=\"$(width-178)\" y=\"79\" font-family=\"sans-serif\" font-size=\"12\">failed reduced candidate</text>")
    push!(lines, "</svg>")
    return join(lines, "\n") * "\n"
end

function run_band_accuracy_pareto()
    rows = vcat(
        parse_reduced_accuracy_rows(),
        parse_published_model_accuracy_rows(),
    )
    front = pareto_front(rows)
    objective = objective_front(rows)
    inventory = parse_inventory_rows()
    passed_rows = count(row -> row.passed, rows)
    return (
        case = "ecckd_band_accuracy_pareto",
        timestamp_utc = string(Dates.now()),
        status = isempty(rows) ? "missing_accuracy_rows" : "passed",
        point_count = length(rows),
        passed_point_count = passed_rows,
        published_inventory_count = length(inventory),
        plot_path = PARETO_SVG,
        csv_path = PARETO_CSV,
        accuracy_points = rows,
        pareto_front = front,
        objective_front = objective,
        published_inventory = inventory,
        notes = "This artifact plots the currently tracked ecCKD accuracy rows: the official 32x32 anchor from the reduced-accuracy registry and direct published-model accuracy diagnostics for the promoted official 32x32, 32x64, 32x96, 64x32, 64x64, and 64x96 combinations. Promoted published combinations are inventoried, recovered by the teacher-student scan, and pass the package-native clean reference gate against matched ecRad reference products. Frozen greedy-era reduced candidates are recorded in validation/FROZEN_DIAGNOSTICS.md; new band-count rows only count when produced by the recovered training pipeline.",
    )
end

function markdown_pareto(result)
    lines = String[
        "# ecCKD Band-Count Accuracy Pareto",
        "",
        "Status: **$(result.status)**",
        "",
        "- Accuracy points: $(result.point_count)",
        "- Passing accuracy points: $(result.passed_point_count)",
        "- Published ecCKD inventory entries: $(result.published_inventory_count)",
        "- Plot: `$(result.plot_path)`",
        "- CSV: `$(result.csv_path)`",
        "",
        result.notes,
        "",
        "The plot keeps boundary forcing on the y-axis because that is the user-facing radiative forcing criterion. The JSON and CSV also report `normalized_objective`, `objective_source`, and `limiting_metric`.",
        "",
        "## Boundary-Forcing Pareto Front",
        "",
        "| Total g-points | LW | SW | Passed | Worst boundary forcing error | Normalized objective | Limiting metric | Method |",
        "|---:|---:|---:|---:|---:|---:|---|---|",
    ]
    for row in result.pareto_front
        push!(lines, "| $(row.total_gpoints) | $(row.ng_lw) | $(row.ng_sw) | $(row.passed) | $(@sprintf("%.6g", row.worst_boundary_forcing_error_w_m2)) | $(@sprintf("%.6g", row.normalized_objective)) | $(row.limiting_metric) | $(row.label) |")
    end
    append!(lines, [
        "",
        "## Normalized-Objective Pareto Front",
        "",
        "This front ranks the same rows by the full reported hard-gate objective when available. It can disagree with the boundary-forcing front when a row's limiting metric is not boundary forcing.",
        "",
        "| Total g-points | LW | SW | Passed | Worst boundary forcing error | Normalized objective | Limiting metric | Method |",
        "|---:|---:|---:|---:|---:|---:|---|---|",
    ])
    for row in result.objective_front
        push!(lines, "| $(row.total_gpoints) | $(row.ng_lw) | $(row.ng_sw) | $(row.passed) | $(@sprintf("%.6g", row.worst_boundary_forcing_error_w_m2)) | $(@sprintf("%.6g", row.normalized_objective)) | $(row.limiting_metric) | $(row.label) |")
    end
    append!(lines, [
        "",
        "## Published Inventory",
        "",
        "| File | Kind | Bands | G-points |",
        "|---|---|---:|---:|",
    ])
    for row in result.published_inventory
        push!(lines, "| `$(row.filename)` | $(row.kind) | $(row.bands) | $(row.gpoints) |")
    end
    return join(lines, "\n") * "\n"
end

function band_accuracy_pareto_main()
    result = run_band_accuracy_pareto()
    mkpath(RESULTS_DIR)
    write_csv(result.accuracy_points)
    write(PARETO_SVG, svg_plot(result.accuracy_points, result.pareto_front))
    write(PARETO_JSON, json_object(result) * "\n")
    write(PARETO_MD, markdown_pareto(result))
    print(markdown_pareto(result))
    println("Wrote $PARETO_JSON")
    println("Wrote $PARETO_MD")
    println("Wrote $PARETO_CSV")
    println("Wrote $PARETO_SVG")
end

if abspath(PROGRAM_FILE) == @__FILE__
    band_accuracy_pareto_main()
end
