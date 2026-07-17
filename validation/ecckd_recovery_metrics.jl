include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Statistics

const ABR_ROOT = normpath(joinpath(@__DIR__, ".."))
if Base.find_package("NumericalRadiation") === nothing
    push!(LOAD_PATH, ABR_ROOT)
end

using NumericalRadiation
using NCDatasets

const RECOVERY_JSON = validation_results_path("ecckd_recovery_metrics.json")
const RECOVERY_MD = validation_results_path("ecckd_recovery_metrics.md")

const COEFFICIENT_LOG_RMSE_THRESHOLD = 1.0e-3
const MEDIAN_RELATIVE_ERROR_THRESHOLD = 1.0e-3
const P99_RELATIVE_ERROR_THRESHOLD = 1.0e-2
const GPOINT_WEIGHT_ABS_ERROR_THRESHOLD = 1.0e-6
const BAND_WEIGHT_ABS_ERROR_THRESHOLD = 1.0e-8

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

function pquantile(values, q)
    isempty(values) && return NaN
    sorted = sort!(collect(values))
    index = clamp(ceil(Int, q * length(sorted)), 1, length(sorted))
    return sorted[index]
end

function comparable_coefficient_names(reference, candidate)
    names = String[]
    for name in keys(reference)
        text = String(name)
        endswith(text, "_molar_absorption_coeff") || continue
        haskey(candidate, text) && push!(names, text)
    end
    sort!(names)
    return names
end

function positive_eps(reference_values, candidate_values)
    positive = [x for x in vcat(vec(reference_values), vec(candidate_values)) if x > 0]
    isempty(positive) && return eps(Float64)
    return max(minimum(positive) * 1.0e-12, eps(Float64))
end

function coefficient_metrics(reference_values, candidate_values)
    size(reference_values) == size(candidate_values) ||
        throw(ArgumentError("coefficient shapes differ: $(size(reference_values)) vs $(size(candidate_values))"))
    ref = Float64.(reference_values)
    cand = Float64.(candidate_values)
    ϵ = positive_eps(ref, cand)
    log_diff = log.(cand .+ ϵ) .- log.(ref .+ ϵ)
    denom = max.(abs.(ref), ϵ)
    rel = abs.(cand .- ref) ./ denom
    return (
        log_rmse = sqrt(mean(abs2, log_diff)),
        median_relative_error = median(vec(rel)),
        p99_relative_error = pquantile(vec(rel), 0.99),
        max_relative_error = maximum(rel),
    )
end

function gpoint_weights(ds, kind)
    if kind == "shortwave" && haskey(ds, "solar_irradiance")
        raw = Float64.(Array(ds["solar_irradiance"]))
    elseif kind == "longwave" && haskey(ds, "planck_function")
        raw = vec(sum(Float64.(Array(ds["planck_function"])); dims = 2))
    else
        raw = vec(sum(Float64.(Array(ds["gpoint_fraction"])); dims = 1))
    end
    total = sum(raw)
    total > 0 || throw(ArgumentError("nonpositive g-point weight sum"))
    return raw ./ total
end

function band_weights(ds, gweights)
    haskey(ds, "band_number") || return Float64[]
    bands = Int.(Array(ds["band_number"]))
    offset = minimum(bands) == 0 ? 1 : 0
    output = zeros(Float64, maximum(bands) + offset)
    for (g, band) in enumerate(bands)
        output[band + offset] += gweights[g]
    end
    return output
end

function recovery_metrics(reference_path, candidate_path)
    NCDataset(reference_path) do reference
        NCDataset(candidate_path) do candidate
            reference_definition = read_ecckd_definition(reference_path)
            summary = summarize_ecckd_definition(reference_definition)
            kind = summary.lw_gpoints > 0 ? "longwave" : "shortwave"
            coefficient_names = comparable_coefficient_names(reference, candidate)
            coefficient_results = [
                merge((name = name,), coefficient_metrics(Array(reference[name]), Array(candidate[name])))
                for name in coefficient_names
            ]
            ref_weights = gpoint_weights(reference, kind)
            cand_weights = gpoint_weights(candidate, kind)
            size(ref_weights) == size(cand_weights) ||
                throw(ArgumentError("g-point weight shapes differ: $(size(ref_weights)) vs $(size(cand_weights))"))
            ref_band_weights = band_weights(reference, ref_weights)
            cand_band_weights = band_weights(candidate, cand_weights)
            weight_abs_error = maximum(abs.(cand_weights .- ref_weights))
            band_weight_abs_error = isempty(ref_band_weights) ? 0.0 :
                maximum(abs.(cand_band_weights .- ref_band_weights))
            worst_log_rmse = maximum(result.log_rmse for result in coefficient_results)
            worst_median_relative_error =
                maximum(result.median_relative_error for result in coefficient_results)
            worst_p99_relative_error =
                maximum(result.p99_relative_error for result in coefficient_results)
            passed = worst_log_rmse < COEFFICIENT_LOG_RMSE_THRESHOLD &&
                     worst_median_relative_error < MEDIAN_RELATIVE_ERROR_THRESHOLD &&
                     worst_p99_relative_error < P99_RELATIVE_ERROR_THRESHOLD &&
                     weight_abs_error < GPOINT_WEIGHT_ABS_ERROR_THRESHOLD &&
                     band_weight_abs_error < BAND_WEIGHT_ABS_ERROR_THRESHOLD
            return (
                status = passed ? "passed" : "failed",
                reference_path = reference_path,
                candidate_path = candidate_path,
                kind = kind,
                coefficient_count = length(coefficient_results),
                coefficients = coefficient_results,
                worst_log_coefficient_rmse = worst_log_rmse,
                worst_median_relative_coefficient_error = worst_median_relative_error,
                worst_p99_relative_coefficient_error = worst_p99_relative_error,
                gpoint_weight_max_abs_error = weight_abs_error,
                band_weight_max_abs_error = band_weight_abs_error,
                thresholds = (
                    log_coefficient_rmse = COEFFICIENT_LOG_RMSE_THRESHOLD,
                    median_relative_coefficient_error = MEDIAN_RELATIVE_ERROR_THRESHOLD,
                    p99_relative_coefficient_error = P99_RELATIVE_ERROR_THRESHOLD,
                    gpoint_weight_abs_error = GPOINT_WEIGHT_ABS_ERROR_THRESHOLD,
                    band_weight_abs_error = BAND_WEIGHT_ABS_ERROR_THRESHOLD,
                ),
            )
        end
    end
end

function run_ecckd_recovery_metrics(;
                                    reference = official_ecckd_definition_path(:shortwave_32),
                                    candidate = reference)
    metrics = recovery_metrics(reference, candidate)
    return (
        case = "ecckd_recovery_metrics",
        timestamp_utc = string(Dates.now()),
        status = metrics.status,
        recovery_mode = abspath(reference) == abspath(candidate) ?
                        "published_self_recovery_sanity" :
                        "candidate_against_published",
        metrics = metrics,
    )
end

function markdown_recovery(result)
    metrics = result.metrics
    lines = String[
        "# ecCKD Recovery Metrics",
        "",
        "Status: **$(result.status)**",
        "",
        "Recovery mode: `$(result.recovery_mode)`",
        "",
        "Reference: `$(metrics.reference_path)`",
        "",
        "Candidate: `$(metrics.candidate_path)`",
        "",
        "| Metric | Value | Threshold |",
        "|---|---:|---:|",
        "| Worst log-coefficient RMSE | $(metrics.worst_log_coefficient_rmse) | $(metrics.thresholds.log_coefficient_rmse) |",
        "| Worst median relative coefficient error | $(metrics.worst_median_relative_coefficient_error) | $(metrics.thresholds.median_relative_coefficient_error) |",
        "| Worst 99th-percentile relative coefficient error | $(metrics.worst_p99_relative_coefficient_error) | $(metrics.thresholds.p99_relative_coefficient_error) |",
        "| G-point weight max abs error | $(metrics.gpoint_weight_max_abs_error) | $(metrics.thresholds.gpoint_weight_abs_error) |",
        "| Band weight max abs error | $(metrics.band_weight_max_abs_error) | $(metrics.thresholds.band_weight_abs_error) |",
        "",
        "## Coefficients",
        "",
        "| Name | log RMSE | Median relative error | P99 relative error | Max relative error |",
        "|---|---:|---:|---:|---:|",
    ]
    for coefficient in metrics.coefficients
        push!(lines, "| `$(coefficient.name)` | $(coefficient.log_rmse) | $(coefficient.median_relative_error) | $(coefficient.p99_relative_error) | $(coefficient.max_relative_error) |")
    end
    return join(lines, "\n") * "\n"
end

function ecckd_recovery_metrics_main()
    result = run_ecckd_recovery_metrics()
    mkpath(dirname(RECOVERY_JSON))
    write(RECOVERY_JSON, json_object(result) * "\n")
    write(RECOVERY_MD, markdown_recovery(result))
    print(markdown_recovery(result))
    println("Wrote $RECOVERY_JSON")
    println("Wrote $RECOVERY_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_recovery_metrics_main()
end
