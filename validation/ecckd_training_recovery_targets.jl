include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using Printf

const TRAINING_TARGETS_JSON = validation_results_path("ecckd_training_recovery_targets.json")
const TRAINING_TARGETS_MD = validation_results_path("ecckd_training_recovery_targets.md")
const OFFICIAL_TRAINING_JSON = validation_results_path("official_ecckd_training.json")
const BOUNDARY_POLISH_JSON = joinpath(
    @__DIR__,
    "results",
    "reduced_ecckd_leave_one_out_weight_coordinate_boundary_polish.json",
)
const REDUCED_ACCURACY_JSON = validation_results_path("reduced_ecckd_accuracy.json")

function artifact_or_empty(path)
    isfile(path) ? JSON.parsefile(path) : Dict{String,Any}()
end

function find_canonical_boundary_polish_row(rows)
    for row in rows
        method = string(get(row, "reduction_method", ""))
        if get(row, "ng_lw", 0) == 32 &&
           get(row, "ng_sw", 0) == 31 &&
           occursin("boundary-polished", method)
            return row
        end
    end
    return Dict{String,Any}()
end

function max_case_value(row, key)
    cases = get(row, "cases", Any[])
    isempty(cases) && return nothing
    return maximum(case -> get(case, key, 0.0), cases)
end

function training_recovery_targets()
    official = artifact_or_empty(OFFICIAL_TRAINING_JSON)
    boundary_polish = artifact_or_empty(BOUNDARY_POLISH_JSON)
    reduced_accuracy = artifact_or_empty(REDUCED_ACCURACY_JSON)
    reduced_rows = get(reduced_accuracy, "models", Any[])
    canonical_row = find_canonical_boundary_polish_row(reduced_rows)

    official_ratio = get(official, "final_objective_target_ratio", Inf)
    boundary_objective = get(boundary_polish, "final_objective", Inf)
    canonical_passed = get(canonical_row, "passed_hard_thresholds", false)

    targets = (
        fixed_inputs = [
            "same CKDMIP/ecCKD source files",
            "same representative atmosphere states",
            "same objective terms and hard thresholds",
            "same trainable parameterization unless the row is explicitly labelled as a new band-count scheme",
        ],
        optimizer_only_delta_rule =
            "published-model recovery experiments may vary optimizer settings, schedules, and initialization seeds, but not source data, objective terms, or evaluation cases",
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
            required_band_counts = [48, 63, 96],
        ),
    )

    status = official_ratio <= targets.published_model_recovery_metrics.final_objective_target_ratio_max &&
             canonical_passed ? "passed" : "partial"

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
        current_in_house_reduced_scheme = (
            model = "canonical 32x31 boundary-polished reduced ecCKD",
            total_gpoints = get(canonical_row, "ng_lw", 0) + get(canonical_row, "ng_sw", 0),
            hard_accuracy_target_met = canonical_passed,
            final_objective_target_ratio = boundary_objective,
            toa_forcing_abs_error_w_m2 = max_case_value(canonical_row, "toa_forcing_max_abs"),
            surface_forcing_abs_error_w_m2 =
                max_case_value(canonical_row, "surface_forcing_max_abs"),
        ),
        interpretation =
            "The 32x31 reduced scheme now passes the hard radiation gate, but published-model recovery remains partial until the Reactant/Enzyme training pipeline recovers a published ecCKD definition under the optimizer-only-delta rule.",
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
    reduced = result.current_in_house_reduced_scheme
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
        "| Canonical reduced model | $(reduced.model) |",
        "| Canonical reduced total g-points | $(reduced.total_gpoints) |",
        "| Canonical reduced hard target met | $(reduced.hard_accuracy_target_met) |",
        "| Canonical reduced objective / target | $(@sprintf("%.12g", reduced.final_objective_target_ratio)) |",
        "| Canonical reduced TOA forcing error | $(reduced.toa_forcing_abs_error_w_m2) W m^-2 |",
        "| Canonical reduced surface forcing error | $(reduced.surface_forcing_abs_error_w_m2) W m^-2 |",
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
