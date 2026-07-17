include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

include(joinpath(@__DIR__, "ecckd_recovery_metrics.jl"))

const PUBLISHED_RECOVERY_TARGET_JSON =
    validation_results_path("ecckd_published_recovery_target.json")
const PUBLISHED_RECOVERY_TARGET_MD =
    validation_results_path("ecckd_published_recovery_target.md")
const TRAINING_TARGETS_JSON =
    validation_results_path("ecckd_training_recovery_targets.json")

const SUPPORT_ARRAY_NAMES = (
    "gpoint_fraction",
    "band_number",
    "solar_irradiance",
    "planck_function",
    "rayleigh_molar_scattering_coeff",
)

function finite_or_nothing(value)
    value isa Number && isfinite(value) ? value : nothing
end

function array_summary(ds, name)
    values = Float64.(Array(ds[name]))
    positive = count(>(0), values)
    return (
        name = String(name),
        shape = collect(size(values)),
        element_count = length(values),
        positive_count = positive,
        min = finite_or_nothing(minimum(values)),
        max = finite_or_nothing(maximum(values)),
        sum = finite_or_nothing(sum(values)),
    )
end

function coefficient_array_summaries(ds)
    return [array_summary(ds, name) for name in comparable_coefficient_names(ds, ds)]
end

function support_array_summaries(ds)
    summaries = NamedTuple[]
    for name in SUPPORT_ARRAY_NAMES
        haskey(ds, name) && push!(summaries, array_summary(ds, name))
    end
    return summaries
end

function published_model_target(filename)
    path = official_ecckd_definition_path(filename)
    definition = read_ecckd_definition(path)
    summary = summarize_ecckd_definition(definition)
    kind = summary.lw_gpoints > 0 ? "longwave" : "shortwave"
    gpoints = kind == "longwave" ? summary.lw_gpoints : summary.sw_gpoints
    bands = kind == "longwave" ? summary.lw_bands : summary.sw_bands
    NCDataset(path) do ds
        coefficients = coefficient_array_summaries(ds)
        support_arrays = support_array_summaries(ds)
        return (
            filename = filename,
            path = path,
            kind = kind,
            version = summary.version,
            model_name = summary.model_name,
            bands = bands,
            gpoints = gpoints,
            gases = summary.gases,
            coefficient_array_count = length(coefficients),
            coefficient_parameter_count =
                sum(row -> row.element_count, coefficients; init = 0),
            support_array_count = length(support_arrays),
            support_parameter_count =
                sum(row -> row.element_count, support_arrays; init = 0),
            coefficients = coefficients,
            support_arrays = support_arrays,
        )
    end
end

function recovery_acceptance_targets()
    if isfile(TRAINING_TARGETS_JSON)
        data = JSON.parsefile(TRAINING_TARGETS_JSON)
        targets = get(get(data, "targets", Dict{String, Any}()),
                      "published_model_recovery_metrics", Dict{String, Any}())
        !isempty(targets) && return targets
    end
    return Dict{String, Any}(
        "final_objective_target_ratio_max" => 1.05,
        "weight_l1_relative_error_max" => 0.02,
        "optical_depth_log_rmse_max" => 0.02,
        "forcing_error_regression_margin_w_m2" => 0.03,
        "heating_rmse_regression_margin_k_day" => 0.005,
    )
end

function run_ecckd_published_recovery_target()
    models = [published_model_target(filename) for filename in official_ecckd_model_inventory()]
    target_32_sw = only(filter(row -> row.filename ==
        "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc", models))
    target_32_lw = only(filter(row -> row.filename ==
        "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc", models))
    acceptance = recovery_acceptance_targets()
    return (
        case = "ecckd_published_recovery_target",
        timestamp_utc = string(Dates.now()),
        status = "published_recovery_target_ready",
        model_count = length(models),
        target_models = models,
        primary_recovery_targets = (
            shortwave_32 = target_32_sw,
            longwave_32 = target_32_lw,
        ),
        acceptance_metrics = acceptance,
        optimizer_only_delta_rule =
            "A recovery run may vary optimizer settings, schedules, and initialization seeds, but must keep the published CKDMIP/ecCKD inputs, objective terms, trainable arrays, and evaluation cases fixed.",
        next_required_work = [
            "Choose one primary target, preferably the 32-g shortwave RGB model, and initialize the trainable arrays from the same parameterization used by ecCKD.",
            "Run the original-objective optimizer with only optimizer settings varied.",
            "Write the recovered CKD-definition and evaluate it with ecckd_recovery_metrics plus the original-objective flux/heating criteria.",
        ],
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_published_recovery_target(result)
    lines = String[
        "# ecCKD Published Recovery Target",
        "",
        "Status: **$(result.status)**",
        "",
        "Optimizer-only delta rule: $(result.optimizer_only_delta_rule)",
        "",
        "## Acceptance Metrics",
        "",
        "| Metric | Threshold |",
        "|---|---:|",
    ]
    for key in sort(collect(keys(result.acceptance_metrics)))
        push!(lines, "| `$(key)` | $(result.acceptance_metrics[key]) |")
    end
    append!(lines, [
        "",
        "## Published Targets",
        "",
        "| File | Kind | Bands | G-points | Coefficient arrays | Coefficient parameters | Support arrays | Support parameters |",
        "|---|---|---:|---:|---:|---:|---:|---:|",
    ])
    for row in result.target_models
        push!(lines, "| `$(row.filename)` | $(row.kind) | $(row.bands) | $(row.gpoints) | $(row.coefficient_array_count) | $(row.coefficient_parameter_count) | $(row.support_array_count) | $(row.support_parameter_count) |")
    end
    push!(lines, "", "## Primary 32-G Targets", "")
    for row in (result.primary_recovery_targets.longwave_32,
                result.primary_recovery_targets.shortwave_32)
        push!(lines,
              "- `$(row.filename)`: $(row.kind), $(row.bands) bands, $(row.gpoints) g-points, $(row.coefficient_parameter_count) coefficient parameters.")
    end
    push!(lines, "", "## Next Required Work", "")
    append!(lines, ["- $(item)" for item in result.next_required_work])
    return join(lines, "\n") * "\n"
end

function ecckd_published_recovery_target_main()
    result = run_ecckd_published_recovery_target()
    write_json(PUBLISHED_RECOVERY_TARGET_JSON, result)
    write(PUBLISHED_RECOVERY_TARGET_MD, markdown_published_recovery_target(result))
    print(markdown_published_recovery_target(result))
    println("Wrote $PUBLISHED_RECOVERY_TARGET_JSON")
    println("Wrote $PUBLISHED_RECOVERY_TARGET_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_published_recovery_target_main()
end
