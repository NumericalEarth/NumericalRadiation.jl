include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_subset_search.jl"))

const LEAVE_ONE_OUT_SCAN_JSON =
    validation_results_path("reduced_ecckd_leave_one_out_scan.json")
const LEAVE_ONE_OUT_SCAN_MD =
    validation_results_path("reduced_ecckd_leave_one_out_scan.md")

function leave_one_out_row(full_model, omitted_gpoint)
    sw_indices = [ig for ig in 1:size(full_model.shortwave_absorption, 1)
                  if ig != omitted_gpoint]
    model = indexed_tabulated_model(
        full_model,
        collect(1:size(full_model.longwave_absorption, 1)),
        sw_indices,
    )
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return (
        omitted_gpoint = omitted_gpoint,
        ng_lw = 32,
        ng_sw = length(sw_indices),
        passed_hard_thresholds = all(case -> case.passed_hard_thresholds, cases),
        objective = maximum(exact_case_objective, cases),
        worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in cases),
        worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in cases),
        worst_sw_up_rmse_w_m2 = maximum(case.variables.sw_up.rmse for case in cases),
        worst_sw_down_rmse_w_m2 =
            maximum(case.variables.sw_down.rmse for case in cases),
    )
end

function leave_one_out_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    rows = [leave_one_out_row(full_model, ig)
            for ig in 1:size(full_model.shortwave_absorption, 1)]
    passed_rows = filter(row -> row.passed_hard_thresholds, rows)
    best = argmin(row -> row.objective, rows)
    worst = argmax(row -> row.objective, rows)
    return (
        case = "reduced_ecckd_leave_one_out_scan",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = isempty(passed_rows) ? "all_leave_one_out_failed" :
                 "some_leave_one_out_passed",
        reference_scope = collect(REDUCED_CASE_NAMES),
        candidate_count = length(rows),
        pass_count = length(passed_rows),
        best_omitted_gpoint = best.omitted_gpoint,
        best_objective = best.objective,
        best_toa_forcing_error_w_m2 = best.worst_toa_forcing_error_w_m2,
        best_surface_forcing_error_w_m2 =
            best.worst_surface_forcing_error_w_m2,
        worst_omitted_gpoint = worst.omitted_gpoint,
        worst_objective = worst.objective,
        worst_toa_forcing_error_w_m2 = worst.worst_toa_forcing_error_w_m2,
        worst_surface_forcing_error_w_m2 =
            worst.worst_surface_forcing_error_w_m2,
        rows = rows,
    )
end

function leave_one_out_scan_markdown(result)
    lines = String[
        "# Reduced ecCKD Leave-One-Out Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "This diagnostic drops one official shortwave g-point at a time from the",
        "otherwise full 32x32 official ecCKD path. It tests whether the clean",
        "hard gate is robust to a single omitted shortwave quadrature point.",
        "",
        "| Omitted SW g-point | Passed | Objective | Worst TOA forcing | Worst surface forcing | Worst SW up RMSE | Worst SW down RMSE |",
        "|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.rows
        push!(lines,
              "| $(row.omitted_gpoint) | $(row.passed_hard_thresholds) | $(@sprintf("%.12g", row.objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error_w_m2)) W m^-2 | $(@sprintf("%.12g", row.worst_surface_forcing_error_w_m2)) W m^-2 | $(@sprintf("%.12g", row.worst_sw_up_rmse_w_m2)) W m^-2 | $(@sprintf("%.12g", row.worst_sw_down_rmse_w_m2)) W m^-2 |")
    end
    push!(lines, "")
    push!(lines,
          "Best omitted g-point: `$(result.best_omitted_gpoint)` with objective `$(@sprintf("%.12g", result.best_objective))`.")
    push!(lines,
          "Worst omitted g-point: `$(result.worst_omitted_gpoint)` with objective `$(@sprintf("%.12g", result.worst_objective))`.")
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? leave_one_out_scan_result() : result
    mkpath(dirname(LEAVE_ONE_OUT_SCAN_JSON))
    write(LEAVE_ONE_OUT_SCAN_JSON, json_object(result) * "\n")
    write(LEAVE_ONE_OUT_SCAN_MD, leave_one_out_scan_markdown(result))
    print(leave_one_out_scan_markdown(result))
    println("Wrote $LEAVE_ONE_OUT_SCAN_JSON")
    println("Wrote $LEAVE_ONE_OUT_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
