include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using Printf

const TRAINING_TARGETS_JSON = validation_results_path("ecckd_training_recovery_targets.json")
const TRAINING_TARGETS_MD = validation_results_path("ecckd_training_recovery_targets.md")
const OFFICIAL_TRAINING_JSON = validation_results_path("official_ecckd_training.json")

function artifact_or_empty(path)
    isfile(path) ? JSON.parsefile(path) : Dict{String,Any}()
end

function training_recovery_targets()
    official = artifact_or_empty(OFFICIAL_TRAINING_JSON)

    official_ratio = get(official, "final_objective_target_ratio", Inf)

    targets = (
        fixed_inputs = [
            "same CKDMIP/ecCKD source files",
            "same representative atmosphere states",
            "same objective terms and hard thresholds",
            "same trainable parameterization unless the row is explicitly labelled as a new band-count scheme",
        ],
        optimizer_only_delta_rule =
            "published-model recovery experiments may vary optimizer settings, schedules, and initialization seeds, but not source data, objective terms, or evaluation cases",
        new_band_scheme_rule =
            "new band-count rows only count when produced by the recovered training pipeline with source data, objective terms, and evaluation cases fixed; greedy/forward-evaluation candidates are frozen as evidence (validation/FROZEN_DIAGNOSTICS.md) and do not satisfy these targets",
        published_model_recovery_metrics = (
            final_objective_target_ratio_max = 1.05,
            weight_l1_relative_error_max = 0.02,
            optical_depth_log_rmse_max = 0.02,
            forcing_error_regression_margin_w_m2 = 0.03,
            heating_rmse_regression_margin_k_day = 0.005,
        ),
        new_band_scheme_metrics = (
            hard_gate_objective_max = 1.0,
            toa_forcing_abs_error_w_m2_max = 0.30,
            surface_forcing_abs_error_w_m2_max = 0.30,
            heating_rate_rmse_k_day_max = 0.05,
            required_band_counts = [48, 96],
        ),
    )

    status = official_ratio <=
             targets.published_model_recovery_metrics.final_objective_target_ratio_max ?
             "passed" : "partial"

    return (
        case = "ecckd_training_recovery_targets",
        timestamp_utc = string(Dates.now()),
        status = status,
        targets = targets,
        current_official_recovery = (
            status = get(official, "status", "missing"),
            ng_sw = get(official, "ng_sw", nothing),
            parameter_count = get(official, "parameter_count", nothing),
            final_objective_target_ratio = official_ratio,
            hard_accuracy_target_met = get(official, "hard_accuracy_target_met", false),
        ),
        interpretation =
            "Published-model recovery remains partial until the Reactant/Enzyme training pipeline recovers a published ecCKD definition under the optimizer-only-delta rule; new band-count schemes only count when produced by that recovered pipeline.",
        next_required_work = [
            "Run the original-objective Reactant/Enzyme recovery with source data/objective/evaluation fixed and only optimizer settings varied.",
            "Compare recovered weights and optical-depth tables against the published ecCKD model using the quantitative recovery metrics above.",
            "Use the recovered pipeline to generate missing band-count rows, starting with 48-g and 96-g, then refresh the accuracy-vs-band plot.",
        ],
    )
end

function write_json_value(io, value)
    if value === nothing
        print(io, "null")
    elseif value isa AbstractString
        JSON.print(io, value)
    elseif value isa Bool
        print(io, value ? "true" : "false")
    elseif value isa Number
        print(io, isfinite(value) ? string(value) : "null")
    elseif value isa NamedTuple
        write_json_object(io, value)
    elseif value isa AbstractVector || value isa Tuple
        print(io, "[")
        for (i, item) in enumerate(value)
            i > 1 && print(io, ", ")
            write_json_value(io, item)
        end
        print(io, "]")
    else
        JSON.print(io, value)
    end
end

function write_json_object(io, object)
    names = propertynames(object)
    println(io, "{")
    for (i, name) in enumerate(names)
        print(io, "  ")
        JSON.print(io, String(name))
        print(io, ": ")
        write_json_value(io, getproperty(object, name))
        println(io, i == length(names) ? "" : ",")
    end
    print(io, "}")
end

function json_object(object)
    io = IOBuffer()
    write_json_object(io, object)
    return String(take!(io))
end

function markdown_report(result)
    official = result.current_official_recovery
    recovery = result.targets.published_model_recovery_metrics
    scheme = result.targets.new_band_scheme_metrics
    lines = String[
        "# ecCKD Training Recovery Targets",
        "",
        "Status: **$(result.status)**",
        "",
        "## Current Evidence",
        "",
        "| Evidence | Value |",
        "|---|---:|",
        "| Official recovery final objective / target | $(@sprintf("%.12g", official.final_objective_target_ratio)) |",
        "| Official recovery hard target met | $(official.hard_accuracy_target_met) |",
        "",
        "## Recovery Criteria",
        "",
        "| Metric | Acceptance |",
        "|---|---:|",
        "| Final objective / target | <= $(recovery.final_objective_target_ratio_max) |",
        "| Relative L1 weight error | <= $(recovery.weight_l1_relative_error_max) |",
        "| Optical-depth log RMSE | <= $(recovery.optical_depth_log_rmse_max) |",
        "| Forcing regression margin | <= $(recovery.forcing_error_regression_margin_w_m2) W m^-2 |",
        "| Heating RMSE regression margin | <= $(recovery.heating_rmse_regression_margin_k_day) K day^-1 |",
        "",
        "## New Band-Scheme Criteria",
        "",
        "| Metric | Acceptance |",
        "|---|---:|",
        "| Hard-gate objective | <= $(scheme.hard_gate_objective_max) |",
        "| TOA forcing absolute error | <= $(scheme.toa_forcing_abs_error_w_m2_max) W m^-2 |",
        "| Surface forcing absolute error | <= $(scheme.surface_forcing_abs_error_w_m2_max) W m^-2 |",
        "| Heating-rate RMSE | <= $(scheme.heating_rate_rmse_k_day_max) K day^-1 |",
        "| Required band-count points | $(join(string.(scheme.required_band_counts), ", ")) |",
        "",
        result.targets.new_band_scheme_rule,
        "",
        result.interpretation,
        "",
        "Next required work:",
    ]
    append!(lines, ["- $item" for item in result.next_required_work])
    return join(lines, "\n") * "\n"
end

function main()
    result = training_recovery_targets()
    mkpath(dirname(TRAINING_TARGETS_JSON))
    write(TRAINING_TARGETS_JSON, json_object(result) * "\n")
    write(TRAINING_TARGETS_MD, markdown_report(result))
    print(markdown_report(result))
    println("Wrote $TRAINING_TARGETS_JSON")
    println("Wrote $TRAINING_TARGETS_MD")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
