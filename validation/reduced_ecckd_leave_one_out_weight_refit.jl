include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_hardgate_subset_search.jl"))

const LEAVE_ONE_OUT_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_leave_one_out_weight_refit.json")
const LEAVE_ONE_OUT_WEIGHT_REFIT_MD =
    validation_results_path("reduced_ecckd_leave_one_out_weight_refit.md")

leave_one_out_weight_refit_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_LEAVE_ONE_OUT_WEIGHT_REFIT_ITERATIONS", "5000"))

leave_one_out_weight_refit_pnorm() =
    parse(Int, get(ENV, "RH_REDUCED_LEAVE_ONE_OUT_WEIGHT_REFIT_P", "16"))

function leave_one_out_weight_refit_row(full_model, design, target, omitted_gpoint)
    indices = setdiff(collect(1:length(full_model.shortwave_weights)), [omitted_gpoint])
    initial_weights = normalized_subset(full_model.shortwave_weights, indices)
    initial_exact = exact_subset_result(full_model, indices, initial_weights)
    refit_weights, approximate_objective =
        optimize_sparse_hardgate_weights(
            design,
            target,
            indices;
            initial_weights,
            max_iterations = leave_one_out_weight_refit_iterations(),
            p = leave_one_out_weight_refit_pnorm(),
        )
    refit_exact = exact_subset_result(full_model, indices, refit_weights)
    return (
        omitted_gpoint = omitted_gpoint,
        ng_lw = 32,
        ng_sw = length(indices),
        initial_objective = initial_exact.objective,
        refit_objective = refit_exact.objective,
        objective_reduction = initial_exact.objective - refit_exact.objective,
        approximate_hardgate_objective = approximate_objective,
        passed_hard_thresholds = refit_exact.exact.passed_hard_thresholds,
        initial_toa_forcing_error_w_m2 = initial_exact.worst_toa_forcing_error_w_m2,
        initial_surface_forcing_error_w_m2 = initial_exact.worst_surface_forcing_error_w_m2,
        refit_toa_forcing_error_w_m2 = refit_exact.worst_toa_forcing_error_w_m2,
        refit_surface_forcing_error_w_m2 =
            refit_exact.worst_surface_forcing_error_w_m2,
        refit_weights = collect(refit_weights),
    )
end

function leave_one_out_weight_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    context = search_context(full_model)
    design, target = hardgate_full_design(context)
    rows = [
        leave_one_out_weight_refit_row(full_model, design, target, omitted_gpoint)
        for omitted_gpoint in 1:length(full_model.shortwave_weights)
    ]
    best = argmin(row -> row.refit_objective, rows)
    worst = argmax(row -> row.refit_objective, rows)
    pass_count = count(row -> row.passed_hard_thresholds, rows)
    return (
        case = "reduced_ecckd_leave_one_out_weight_refit",
        timestamp_utc = string(Dates.now()),
        status = pass_count == 0 ? "all_leave_one_out_refits_failed" :
            "some_leave_one_out_refits_passed",
        reference_scope = collect(REDUCED_CASE_NAMES),
        iterations = leave_one_out_weight_refit_iterations(),
        p_norm = leave_one_out_weight_refit_pnorm(),
        candidate_count = length(rows),
        pass_count = pass_count,
        best_omitted_gpoint = best.omitted_gpoint,
        best_initial_objective = best.initial_objective,
        best_refit_objective = best.refit_objective,
        best_objective_reduction = best.objective_reduction,
        best_refit_toa_forcing_error_w_m2 = best.refit_toa_forcing_error_w_m2,
        best_refit_surface_forcing_error_w_m2 =
            best.refit_surface_forcing_error_w_m2,
        worst_omitted_gpoint = worst.omitted_gpoint,
        worst_refit_objective = worst.refit_objective,
        worst_refit_toa_forcing_error_w_m2 = worst.refit_toa_forcing_error_w_m2,
        worst_refit_surface_forcing_error_w_m2 =
            worst.refit_surface_forcing_error_w_m2,
        rows = rows,
    )
end

function leave_one_out_weight_refit_markdown(result)
    lines = String[
        "# Reduced ecCKD Leave-One-Out Weight Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "This diagnostic drops one official shortwave g-point at a time and",
        "then refits the remaining 31 nonnegative shortwave weights against",
        "the normalized hard-gate flux/heating objective.",
        "",
        "| Omitted SW g-point | Passed | Initial objective | Refit objective | Objective reduction | Refit TOA forcing | Refit surface forcing |",
        "|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.rows
        push!(lines,
              "| $(row.omitted_gpoint) | $(row.passed_hard_thresholds) | $(@sprintf("%.12g", row.initial_objective)) | $(@sprintf("%.12g", row.refit_objective)) | $(@sprintf("%.12g", row.objective_reduction)) | $(@sprintf("%.12g", row.refit_toa_forcing_error_w_m2)) W m^-2 | $(@sprintf("%.12g", row.refit_surface_forcing_error_w_m2)) W m^-2 |")
    end
    append!(lines, [
        "",
        "Best omitted g-point after refit: `$(result.best_omitted_gpoint)` with objective `$(@sprintf("%.12g", result.best_refit_objective))`.",
        "Worst omitted g-point after refit: `$(result.worst_omitted_gpoint)` with objective `$(@sprintf("%.12g", result.worst_refit_objective))`.",
    ])
    return join(lines, "\n") * "\n"
end

function main()
    result = leave_one_out_weight_refit_result()
    mkpath(dirname(LEAVE_ONE_OUT_WEIGHT_REFIT_JSON))
    write(LEAVE_ONE_OUT_WEIGHT_REFIT_JSON, json_object(result) * "\n")
    write(LEAVE_ONE_OUT_WEIGHT_REFIT_MD, leave_one_out_weight_refit_markdown(result))
    print(leave_one_out_weight_refit_markdown(result))
    println("Wrote $LEAVE_ONE_OUT_WEIGHT_REFIT_JSON")
    println("Wrote $LEAVE_ONE_OUT_WEIGHT_REFIT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
