include(joinpath(@__DIR__, "validation_results.jl"))

using Dates

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))

include(joinpath(@__DIR__, "write_ecrad_candidates.jl"))

const ECCKD_32B_JSON = validation_results_path("ecckd_32b_baseline_check.json")
const ECCKD_32B_MD = validation_results_path("ecckd_32b_baseline_check.md")
const REDUCED_ACCURACY_JSON = validation_results_path("reduced_ecckd_accuracy.json")

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

function full_32x32_reduced_anchor_passed(path = REDUCED_ACCURACY_JSON)
    isfile(path) || return false
    text = read(path, String)
    occursin("\"ng_lw\": 32", text) &&
        occursin("\"ng_sw\": 32", text) &&
        occursin("official ecCKD 32x32 baseline without shortwave reduction", text) &&
        occursin("\"passed_hard_thresholds\": true", text)
end

function ecckd_32b_baseline_check()
    previous_mode = get(ENV, "RH_CANDIDATE_GAS_OPTICS", nothing)
    try
        ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
        model = candidate_gas_optics(Float64)
        lw_gpoints = size(model.longwave_absorption, 1)
        sw_gpoints = size(model.shortwave_absorption, 1)
        anchor_passed = full_32x32_reduced_anchor_passed()
        passed = lw_gpoints == 32 &&
                 sw_gpoints == 32 &&
                 occursin("32b", get(ENV, "RH_ECCKD_LW_PATH",
                                     "validation/external/ecrad/data/ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc")) &&
                 occursin("32b", get(ENV, "RH_ECCKD_SW_PATH",
                                     "validation/external/ecrad/data/ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc")) &&
                 anchor_passed
        return (
            case = "ecckd_32b_baseline_check",
            timestamp_utc = string(Dates.now()),
            status = passed ? "passed" : "failed",
            longwave_definition = get(ENV, "RH_ECCKD_LW_PATH",
                                      "validation/external/ecrad/data/ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc"),
            shortwave_definition = get(ENV, "RH_ECCKD_SW_PATH",
                                       "validation/external/ecrad/data/ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc"),
            lw_gpoints = lw_gpoints,
            sw_gpoints = sw_gpoints,
            weights_normalized = isapprox(sum(model.longwave_weights), 1.0; atol = 1.0e-12) &&
                                 isapprox(sum(model.shortwave_weights), 1.0; atol = 1.0e-12),
            full_32x32_reduced_accuracy_anchor_passed = anchor_passed,
        )
    finally
        if previous_mode === nothing
            delete!(ENV, "RH_CANDIDATE_GAS_OPTICS")
        else
            ENV["RH_CANDIDATE_GAS_OPTICS"] = previous_mode
        end
    end
end

function markdown_report(result)
    lines = String[
        "# ecCKD 32b Baseline Check",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| LW g-points | $(result.lw_gpoints) |",
        "| SW g-points | $(result.sw_gpoints) |",
        "| Weights normalized | $(result.weights_normalized) |",
        "| Full 32x32 reduced-accuracy anchor passed | $(result.full_32x32_reduced_accuracy_anchor_passed) |",
        "",
        "LW definition: `$(result.longwave_definition)`",
        "",
        "SW definition: `$(result.shortwave_definition)`",
    ]
    return join(lines, "\n") * "\n"
end

function main()
    result = ecckd_32b_baseline_check()
    mkpath(dirname(ECCKD_32B_JSON))
    write(ECCKD_32B_JSON, json_object(result) * "\n")
    write(ECCKD_32B_MD, markdown_report(result))
    print(markdown_report(result))
    println("Wrote $ECCKD_32B_JSON")
    println("Wrote $ECCKD_32B_MD")
    result.status == "passed" || error("ecCKD 32b baseline check failed")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
