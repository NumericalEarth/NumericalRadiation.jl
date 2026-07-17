include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

const ALL_SKY_IFS_GATE_JSON = validation_results_path("ecrad_all_sky_ifs_gate.json")
const ALL_SKY_IFS_GATE_MD = validation_results_path("ecrad_all_sky_ifs_gate.md")
const ACCURACY_GATE_JSON = validation_results_path("ecrad_accuracy_gate.json")
const CLOUD_SWEEP_JSON = validation_results_path("ecrad_all_sky_cloud_sweep.json")
const REFERENCE_OPTICS_JSON = validation_results_path("ecrad_reference_optics_solver_gap.json")
const CLOUD_TABLES_JSON = validation_results_path("ecrad_cloud_scattering_tables_check.json")

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
    elseif value isa AbstractVector || value isa Tuple
        return "[" * join(json_value.(value), ", ") * "]"
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

function json_string(text, key)
    match = Base.match(Regex("\"$key\"\\s*:\\s*\"([^\"]*)\""), text)
    return match === nothing ? "" : match.captures[1]
end

function json_number(text, key)
    match = Base.match(Regex("\"$key\"\\s*:\\s*([-+0-9.eE]+)"), text)
    return match === nothing ? NaN : parse(Float64, match.captures[1])
end

function json_numbers(text, key)
    return [
        parse(Float64, match.captures[1])
        for match in eachmatch(Regex("\"$key\"\\s*:\\s*([-+0-9.eE]+)"), text)
    ]
end

function ecrad_all_sky_case_passed(path = ACCURACY_GATE_JSON)
    isfile(path) || return false
    text = read(path, String)
    occursin("\"status\": \"passed\"", text) &&
        occursin("\"case\": \"ecckd_all_sky_tropical_column\"", text) &&
        occursin("\"passed\": true", text)
end

function cloud_sweep_summary(path = CLOUD_SWEEP_JSON)
    isfile(path) || return (
        present = false,
        best_trial = "",
        best_worst_threshold_ratio = NaN,
        passed = false,
    )
    text = read(path, String)
    ratios = json_numbers(text, "all_sky_worst_threshold_ratio")
    ratio = isempty(ratios) ? NaN : minimum(ratios)
    return (
        present = true,
        best_trial = json_string(text, "best_trial"),
        best_worst_threshold_ratio = ratio,
        passed = isfinite(ratio) && ratio <= 1.0,
    )
end

function mode_object(text, mode)
    marker = "\"mode\": \"$mode\""
    start = findfirst(marker, text)
    start === nothing && return ""
    object_start = something(findprev('{', text, first(start)), first(start))
    depth = 0
    for i in object_start:lastindex(text)
        if text[i] == '{'
            depth += 1
        elseif text[i] == '}'
            depth -= 1
            depth == 0 && return text[object_start:i]
        end
    end
    return ""
end

function reference_optics_summary(path = REFERENCE_OPTICS_JSON)
    isfile(path) || return (
        present = false,
        mode = "tripleclouds_alpha_p2",
        toa_net_abs_error = NaN,
        surface_net_abs_error = NaN,
        passed = false,
    )
    object = mode_object(read(path, String), "tripleclouds_alpha_p2")
    toa = json_number(object, "toa_net_abs_error")
    surface = json_number(object, "surface_net_abs_error")
    threshold = 1.0e-3
    return (
        present = object != "",
        mode = "tripleclouds_alpha_p2",
        toa_net_abs_error = toa,
        surface_net_abs_error = surface,
        threshold = threshold,
        passed = isfinite(toa) && isfinite(surface) &&
                 toa <= threshold && surface <= threshold,
    )
end

function cloud_tables_passed(path = CLOUD_TABLES_JSON)
    isfile(path) && occursin("\"status\": \"passed\"", read(path, String))
end

function all_sky_ifs_gate()
    sweep = cloud_sweep_summary()
    reference_optics = reference_optics_summary()
    accuracy_passed = ecrad_all_sky_case_passed()
    cloud_tables = cloud_tables_passed()
    passed = accuracy_passed && sweep.passed && reference_optics.passed && cloud_tables
    return (
        case = "ecrad_all_sky_ifs_gate",
        timestamp_utc = string(Dates.now()),
        status = passed ? "passed" : "blocked",
        accuracy_gate_ecckd_all_sky_passed = accuracy_passed,
        cloud_scattering_tables_passed = cloud_tables,
        cloud_sweep = sweep,
        reference_optics_solver = reference_optics,
        completion_note = passed ?
            "The current IFS all-sky evidence gate is satisfied by the official ecCKD all-sky hard gate, the best all-sky cloud/aerosol/overlap sweep, the reference-optics Tripleclouds solver match, and cloud scattering table ingestion." :
            "All-sky evidence remains incomplete; inspect the failed fields in this artifact.",
    )
end

function markdown_report(result)
    lines = String[
        "# ecRad All-Sky IFS Gate",
        "",
        "Status: **$(result.status)**",
        "",
        "| Check | Passed | Value |",
        "|---|---:|---:|",
        "| official ecCKD all-sky hard gate | $(result.accuracy_gate_ecckd_all_sky_passed) | n/a |",
        "| cloud scattering tables | $(result.cloud_scattering_tables_passed) | n/a |",
        "| best cloud/aerosol/overlap sweep | $(result.cloud_sweep.passed) | $(@sprintf("%.12g", result.cloud_sweep.best_worst_threshold_ratio)) |",
        "| reference-optics Tripleclouds solver | $(result.reference_optics_solver.passed) | TOA $(@sprintf("%.12g", result.reference_optics_solver.toa_net_abs_error)), surface $(@sprintf("%.12g", result.reference_optics_solver.surface_net_abs_error)) |",
        "",
        "Best all-sky trial: `$(result.cloud_sweep.best_trial)`",
        "",
        result.completion_note,
    ]
    return join(lines, "\n") * "\n"
end

function main()
    result = all_sky_ifs_gate()
    mkpath(dirname(ALL_SKY_IFS_GATE_JSON))
    write(ALL_SKY_IFS_GATE_JSON, json_object(result) * "\n")
    write(ALL_SKY_IFS_GATE_MD, markdown_report(result))
    print(markdown_report(result))
    println("Wrote $ALL_SKY_IFS_GATE_JSON")
    println("Wrote $ALL_SKY_IFS_GATE_MD")
    result.status == "passed" || error("ecRad all-sky IFS gate is blocked")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
