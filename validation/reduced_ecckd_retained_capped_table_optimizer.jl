include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))

const RETAINED_CAPPED_TABLE_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_capped_table_optimizer.json")
const RETAINED_CAPPED_TABLE_OPTIMIZER_MD =
    validation_results_path("reduced_ecckd_retained_capped_table_optimizer.md")

retained_capped_table_surface_cap() =
    parse(Float64, get(ENV, "RH_REDUCED_RETAINED_CAPPED_TABLE_SURFACE_CAP", "2.03"))

retained_capped_table_toa_tolerance() =
    parse(Float64, get(ENV, "RH_REDUCED_RETAINED_CAPPED_TABLE_TOA_TOLERANCE", "0.0"))

function with_retained_capped_table_environment(f)
    keys = (
        "RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE",
        "RH_REDUCED_CONSTRAINED_TABLE_SCOPE",
        "RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE",
        "RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES",
        "RH_REDUCED_CONSTRAINED_TABLE_PROBE_POOL_MULTIPLIER",
        "RH_REDUCED_CONSTRAINED_TABLE_PROBE_STEP",
        "RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE",
        "RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH",
        "RH_REDUCED_CONSTRAINED_TABLE_RIDGE_LAMBDAS",
    )
    old = Dict(key => get(ENV, key, nothing) for key in keys)
    try
        ENV["RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE"] = "retained_topology"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_SCOPE"] =
            get(ENV, "RH_REDUCED_RETAINED_CAPPED_TABLE_SCOPE", "all_global_residual_probe")
        ENV["RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE"] =
            get(ENV, "RH_REDUCED_RETAINED_CAPPED_TABLE_RESIDUAL_MODE", "surface")
        ENV["RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES"] =
            get(ENV, "RH_REDUCED_RETAINED_CAPPED_TABLE_CANDIDATES", "48")
        ENV["RH_REDUCED_CONSTRAINED_TABLE_PROBE_POOL_MULTIPLIER"] =
            get(ENV, "RH_REDUCED_RETAINED_CAPPED_TABLE_PROBE_POOL_MULTIPLIER", "2")
        ENV["RH_REDUCED_CONSTRAINED_TABLE_PROBE_STEP"] =
            get(ENV, "RH_REDUCED_RETAINED_CAPPED_TABLE_PROBE_STEP", "0.001953125")
        ENV["RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE"] =
            get(ENV, "RH_REDUCED_RETAINED_CAPPED_TABLE_MAX_LOG_SCALE", "0.0078125")
        ENV["RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH"] =
            get(ENV, "RH_REDUCED_RETAINED_CAPPED_TABLE_INCLUDE_RAYLEIGH", "true")
        ENV["RH_REDUCED_CONSTRAINED_TABLE_RIDGE_LAMBDAS"] =
            get(
                ENV,
                "RH_REDUCED_RETAINED_CAPPED_TABLE_RIDGE_LAMBDAS",
                "1.0e-8,1.0e-6,1.0e-4,1.0e-2,1.0,100.0,1.0e4,1.0e6",
            )
        return f()
    finally
        for key in keys
            if old[key] === nothing
                delete!(ENV, key)
            else
                ENV[key] = old[key]::String
            end
        end
    end
end

function retained_capped_table_optimizer_result()
    surface_cap = retained_capped_table_surface_cap()
    toa_tolerance = retained_capped_table_toa_tolerance()
    raw = with_retained_capped_table_environment() do
        constrained_table_optimizer_result()
    end
    safe_rows = filter(raw.rows) do row
        row.exact_objective < raw.base_objective &&
            row.worst_toa_forcing_error_w_m2 <=
                raw.base_worst_toa_forcing_error_w_m2 + toa_tolerance &&
            row.worst_surface_forcing_error_w_m2 <= surface_cap
    end
    unsafe_rows = filter(raw.rows) do row
        row.worst_toa_forcing_error_w_m2 >
            raw.base_worst_toa_forcing_error_w_m2 + toa_tolerance ||
            row.worst_surface_forcing_error_w_m2 > surface_cap
    end
    selected = isempty(safe_rows) ? nothing : argmin(row -> row.exact_objective, safe_rows)
    best_overall = isempty(raw.rows) ? nothing : argmin(row -> row.exact_objective, raw.rows)
    best_unsafe = isempty(unsafe_rows) ? nothing : argmin(row -> row.exact_objective, unsafe_rows)
    accepted = selected !== nothing
    return merge(
        raw,
        (
            case = "reduced_ecckd_retained_capped_table_optimizer",
            status = accepted ? "retained_capped_table_optimizer_improved" :
                     "retained_capped_table_optimizer_rejected",
            timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
            method = "bounded-frontier retained constrained table optimizer with absolute surface cap",
            surface_cap_w_m2 = surface_cap,
            toa_tolerance_w_m2 = toa_tolerance,
            cap_safe_present = accepted,
            best_cap_safe_ridge_lambda =
                selected === nothing ? nothing : selected.ridge_lambda,
            best_cap_safe_exact_objective =
                selected === nothing ? nothing : selected.exact_objective,
            best_cap_safe_objective_reduction =
                selected === nothing ? nothing : selected.objective_reduction,
            best_cap_safe_toa_forcing_error_w_m2 =
                selected === nothing ? nothing : selected.worst_toa_forcing_error_w_m2,
            best_cap_safe_surface_forcing_error_w_m2 =
                selected === nothing ? nothing : selected.worst_surface_forcing_error_w_m2,
            best_overall_exact_objective =
                best_overall === nothing ? nothing : best_overall.exact_objective,
            best_overall_toa_forcing_error_w_m2 =
                best_overall === nothing ? nothing : best_overall.worst_toa_forcing_error_w_m2,
            best_overall_surface_forcing_error_w_m2 =
                best_overall === nothing ? nothing : best_overall.worst_surface_forcing_error_w_m2,
            best_unsafe_exact_objective =
                best_unsafe === nothing ? nothing : best_unsafe.exact_objective,
            best_unsafe_toa_forcing_error_w_m2 =
                best_unsafe === nothing ? nothing : best_unsafe.worst_toa_forcing_error_w_m2,
            best_unsafe_surface_forcing_error_w_m2 =
                best_unsafe === nothing ? nothing : best_unsafe.worst_surface_forcing_error_w_m2,
            accepted = accepted,
            accepted_move_count = accepted ? length(selected.moves) : 0,
            accepted_moves = accepted ? selected.moves : NamedTuple[],
            all_active_moves = accepted ?
                vcat(raw.base_moves, selected.moves) : raw.base_moves,
        ),
    )
end

retained_capped_metric_or_na(value) =
    value === nothing ? "n/a" : @sprintf("%.12g", value)

function retained_capped_table_optimizer_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Capped Table Optimizer",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base mode | $(result.base_mode) |",
        "| Candidate scope | $(result.candidate_scope) |",
        "| Residual mode | $(result.residual_mode) |",
        "| Surface cap | $(@sprintf("%.12g", result.surface_cap_w_m2)) W m^-2 |",
        "| TOA tolerance | $(@sprintf("%.12g", result.toa_tolerance_w_m2)) W m^-2 |",
        "| Candidate count | $(result.candidate_count) |",
        "| Probe step | $(@sprintf("%.12g", result.probe_step)) |",
        "| Max log scale | $(@sprintf("%.12g", result.max_log_scale)) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Base TOA forcing | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Cap-safe row present | $(result.cap_safe_present) |",
        "| Best cap-safe objective | $(retained_capped_metric_or_na(result.best_cap_safe_exact_objective)) |",
        "| Best cap-safe TOA forcing | $(retained_capped_metric_or_na(result.best_cap_safe_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best cap-safe surface forcing | $(retained_capped_metric_or_na(result.best_cap_safe_surface_forcing_error_w_m2)) W m^-2 |",
        "| Best overall objective | $(retained_capped_metric_or_na(result.best_overall_exact_objective)) |",
        "| Best overall TOA forcing | $(retained_capped_metric_or_na(result.best_overall_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best overall surface forcing | $(retained_capped_metric_or_na(result.best_overall_surface_forcing_error_w_m2)) W m^-2 |",
        "| Best unsafe objective | $(retained_capped_metric_or_na(result.best_unsafe_exact_objective)) |",
        "| Best unsafe TOA forcing | $(retained_capped_metric_or_na(result.best_unsafe_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best unsafe surface forcing | $(retained_capped_metric_or_na(result.best_unsafe_surface_forcing_error_w_m2)) W m^-2 |",
        "| Accepted | $(result.accepted) |",
        "| Accepted moves | $(length(result.accepted_moves)) |",
        "",
        "This diagnostic reruns the constrained table-entry optimizer on the",
        "current retained base, but composes only rows that improve the exact",
        "objective, stay within the configured TOA tolerance, and remain below",
        "the absolute surface forcing cap.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? retained_capped_table_optimizer_result() : result
    mkpath(dirname(RETAINED_CAPPED_TABLE_OPTIMIZER_JSON))
    write(RETAINED_CAPPED_TABLE_OPTIMIZER_JSON, json_object(result) * "\n")
    write(RETAINED_CAPPED_TABLE_OPTIMIZER_MD,
          retained_capped_table_optimizer_markdown(result))
    print(retained_capped_table_optimizer_markdown(result))
    println("Wrote $RETAINED_CAPPED_TABLE_OPTIMIZER_JSON")
    println("Wrote $RETAINED_CAPPED_TABLE_OPTIMIZER_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
