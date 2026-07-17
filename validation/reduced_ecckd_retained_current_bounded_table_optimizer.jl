include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_retained_current_quadrature_linearized_optimizer.jl"))

const RETAINED_CURRENT_BOUNDED_TABLE_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_current_bounded_table_optimizer.json")
const RETAINED_CURRENT_BOUNDED_TABLE_OPTIMIZER_MD =
    validation_results_path("reduced_ecckd_retained_current_bounded_table_optimizer.md")

current_bounded_table_candidates() =
    parse(Int, get(ENV, "RH_REDUCED_CURRENT_BOUNDED_TABLE_CANDIDATES", "16"))

current_bounded_table_probe_step() =
    parse(Float64, get(ENV, "RH_REDUCED_CURRENT_BOUNDED_TABLE_PROBE_STEP", "0.00048828125"))

current_bounded_table_max_log_scale() =
    parse(Float64, get(ENV, "RH_REDUCED_CURRENT_BOUNDED_TABLE_MAX_LOG_SCALE", "0.001953125"))

current_bounded_table_surface_cap() =
    parse(Float64, get(ENV, "RH_REDUCED_CURRENT_BOUNDED_TABLE_SURFACE_CAP", "2.03"))

current_bounded_table_toa_tolerance() =
    parse(Float64, get(ENV, "RH_REDUCED_CURRENT_BOUNDED_TABLE_TOA_TOLERANCE", "0.0"))

current_bounded_table_min_objective_reduction() =
    parse(Float64, get(ENV, "RH_REDUCED_CURRENT_BOUNDED_TABLE_MIN_OBJECTIVE_REDUCTION", "1.0e-3"))

function current_bounded_table_ridge_lambdas()
    raw = get(ENV, "RH_REDUCED_CURRENT_BOUNDED_TABLE_RIDGE_LAMBDAS",
              "1.0e-8,1.0e-6,1.0e-4,1.0e-2,1.0,100.0,1.0e4,1.0e6")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function with_current_table_moves(model, moves)
    candidate = deepcopy(model)
    apply_active_table_entry_moves!(candidate, moves)
    return candidate
end

function retained_current_bounded_table_optimizer_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = current_quadrature_linearized_base(full_model)
    base_objective, base_cases = full_hard_objective(base_model)
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    base_residual = constrained_table_residual_vector(base_model)
    candidate_limit = current_bounded_table_candidates()
    probe_step = current_bounded_table_probe_step()
    max_log_scale = current_bounded_table_max_log_scale()
    surface_cap = current_bounded_table_surface_cap()
    toa_tolerance = current_bounded_table_toa_tolerance()
    min_objective_reduction = current_bounded_table_min_objective_reduction()

    pool = constrained_table_probe_pool(
        all_global_active_table_entry_candidates(
            full_model;
            sw_indices = WEIGHTED_GREEDY_SW_16_INDICES,
        ),
        candidate_limit,
    )
    base_sse = dot(base_residual, base_residual)
    scored = NamedTuple[]
    for candidate in pool
        best_sse = Inf
        for direction in (-1.0, 1.0)
            moved = with_current_table_moves(
                base_model,
                [move_with_log_scale(candidate, direction * probe_step)],
            )
            residual = constrained_table_residual_vector(moved)
            best_sse = min(best_sse, dot(residual, residual))
        end
        push!(scored, (
            candidate = candidate,
            probe_objective_reduction = base_sse - best_sse,
            priority = candidate.priority,
        ))
    end
    sort!(scored; by = row -> (-row.probe_objective_reduction, -row.priority))
    candidates = [row.candidate for row in first(scored, min(candidate_limit, length(scored)))]

    basis = zeros(Float64, length(base_residual), length(candidates))
    for (j, candidate) in enumerate(candidates)
        moved = with_current_table_moves(
            base_model,
            [move_with_log_scale(candidate, probe_step)],
        )
        basis[:, j] .= (constrained_table_residual_vector(moved) .- base_residual) ./
            probe_step
    end

    rows = NamedTuple[]
    for lambda in current_bounded_table_ridge_lambdas()
        lhs = basis' * basis + lambda * I
        rhs = -(basis' * base_residual)
        raw_delta = isempty(candidates) ? Float64[] : Vector(lhs \ rhs)
        clipped_delta = clamp.(raw_delta, -max_log_scale, max_log_scale)
        moves = [move_with_log_scale(candidate, delta)
                 for (candidate, delta) in zip(candidates, clipped_delta)
                 if delta != 0]
        model = with_current_table_moves(base_model, moves)
        objective, cases = full_hard_objective(model)
        toa = maximum(case.toa_forcing_max_abs for case in cases)
        surface = maximum(case.surface_forcing_max_abs for case in cases)
        accepted = base_objective - objective >= min_objective_reduction &&
            objective < base_objective &&
            toa <= base_toa + toa_tolerance &&
            surface <= surface_cap
        push!(rows, (
            ridge_lambda = lambda,
            raw_delta_norm = norm(raw_delta),
            clipped_delta_norm = norm(clipped_delta),
            exact_objective = objective,
            objective_reduction = base_objective - objective,
            worst_toa_forcing_error_w_m2 = toa,
            worst_surface_forcing_error_w_m2 = surface,
            accepted = accepted,
            moves = moves,
        ))
    end

    accepted_rows = filter(row -> row.accepted, rows)
    selected = isempty(accepted_rows) ? nothing : argmin(row -> row.exact_objective, accepted_rows)
    best = isempty(rows) ? nothing : argmin(row -> row.exact_objective, rows)
    accepted = selected !== nothing
    return (
        case = "reduced_ecckd_retained_current_bounded_table_optimizer",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = accepted ? "current_bounded_table_optimizer_improved" :
                 "current_bounded_table_optimizer_rejected",
        residual_mode = constrained_table_residual_mode(),
        candidate_count = length(candidates),
        probe_step = probe_step,
        max_log_scale = max_log_scale,
        surface_cap_w_m2 = surface_cap,
        toa_tolerance_w_m2 = toa_tolerance,
        min_objective_reduction = min_objective_reduction,
        base_objective = base_objective,
        base_worst_toa_forcing_error_w_m2 = base_toa,
        base_worst_surface_forcing_error_w_m2 = base_surface,
        best_exact_objective = best === nothing ? base_objective : best.exact_objective,
        best_objective_reduction = best === nothing ? 0.0 : best.objective_reduction,
        best_worst_toa_forcing_error_w_m2 =
            best === nothing ? base_toa : best.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            best === nothing ? base_surface : best.worst_surface_forcing_error_w_m2,
        accepted = accepted,
        accepted_ridge_lambda = accepted ? selected.ridge_lambda : nothing,
        accepted_objective = accepted ? selected.exact_objective : base_objective,
        accepted_objective_reduction = accepted ? selected.objective_reduction : 0.0,
        accepted_worst_toa_forcing_error_w_m2 =
            accepted ? selected.worst_toa_forcing_error_w_m2 : base_toa,
        accepted_worst_surface_forcing_error_w_m2 =
            accepted ? selected.worst_surface_forcing_error_w_m2 : base_surface,
        accepted_move_count = accepted ? length(selected.moves) : 0,
        accepted_moves = accepted ? selected.moves : NamedTuple[],
        rows = rows,
    )
end

current_bounded_table_metric_or_na(value) =
    value === nothing ? "n/a" : @sprintf("%.12g", value)

function retained_current_bounded_table_optimizer_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Current Bounded Table Optimizer",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Residual mode | $(result.residual_mode) |",
        "| Candidate count | $(result.candidate_count) |",
        "| Probe step | $(@sprintf("%.12g", result.probe_step)) |",
        "| Max log scale | $(@sprintf("%.12g", result.max_log_scale)) |",
        "| Surface cap | $(@sprintf("%.12g", result.surface_cap_w_m2)) W m^-2 |",
        "| TOA tolerance | $(@sprintf("%.12g", result.toa_tolerance_w_m2)) W m^-2 |",
        "| Minimum objective reduction | $(@sprintf("%.12g", result.min_objective_reduction)) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Base TOA forcing | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Best objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best TOA forcing | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Accepted | $(result.accepted) |",
        "| Accepted ridge lambda | $(current_bounded_table_metric_or_na(result.accepted_ridge_lambda)) |",
        "| Accepted objective | $(@sprintf("%.12g", result.accepted_objective)) |",
        "| Accepted TOA forcing | $(@sprintf("%.12g", result.accepted_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Accepted surface forcing | $(@sprintf("%.12g", result.accepted_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Accepted moves | $(result.accepted_move_count) |",
        "",
        "This diagnostic fits local active table-entry moves on the current",
        "capped/post-weight base. It accepts only material exact objective and",
        "TOA improvements that remain inside the configured surface cap.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? retained_current_bounded_table_optimizer_result() :
        result
    mkpath(dirname(RETAINED_CURRENT_BOUNDED_TABLE_OPTIMIZER_JSON))
    write(RETAINED_CURRENT_BOUNDED_TABLE_OPTIMIZER_JSON, json_object(result) * "\n")
    write(RETAINED_CURRENT_BOUNDED_TABLE_OPTIMIZER_MD,
          retained_current_bounded_table_optimizer_markdown(result))
    print(retained_current_bounded_table_optimizer_markdown(result))
    println("Wrote $RETAINED_CURRENT_BOUNDED_TABLE_OPTIMIZER_JSON")
    println("Wrote $RETAINED_CURRENT_BOUNDED_TABLE_OPTIMIZER_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
