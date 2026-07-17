include(joinpath(@__DIR__, "validation_results.jl"))

using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_constrained_table_optimizer.jl"))
include(joinpath(@__DIR__, "reduced_ecckd_slot_blend_refinement.jl"))

const SLOT_BLEND_LINEARIZED_REFIT_JSON =
    validation_results_path("reduced_ecckd_slot_blend_linearized_refit.json")
const SLOT_BLEND_LINEARIZED_REFIT_MD =
    validation_results_path("reduced_ecckd_slot_blend_linearized_refit.md")

slot_blend_linearized_candidate_count() =
    parse(Int, get(ENV, "RH_REDUCED_SLOT_BLEND_LINEARIZED_CANDIDATES", "48"))

slot_blend_linearized_probe_alpha() =
    parse(Float64, get(ENV, "RH_REDUCED_SLOT_BLEND_LINEARIZED_PROBE_ALPHA", "0.0009765625"))

slot_blend_linearized_max_alpha() =
    parse(Float64, get(ENV, "RH_REDUCED_SLOT_BLEND_LINEARIZED_MAX_ALPHA", "0.03125"))

function slot_blend_linearized_ridge_lambdas()
    raw = get(ENV, "RH_REDUCED_SLOT_BLEND_LINEARIZED_RIDGE_LAMBDAS",
              "1.0e-4,1.0e-2,1.0,100.0,1.0e4,1.0e6")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function ranked_unique_slot_blend_directions(full_model, base_model, base_breakdown)
    candidates = slot_blend_candidates(WEIGHTED_GREEDY_SW_16_INDICES)
    _, rows = best_slot_blend_step(full_model, base_model, base_breakdown, candidates)
    sorted = sort(rows, by = row -> row.objective)
    seen = Set{Tuple{Int, Int}}()
    directions = NamedTuple[]
    for row in sorted
        key = (row.local_index, row.blend_gpoint)
        key in seen && continue
        push!(seen, key)
        push!(directions, (
            local_index = row.local_index,
            source_gpoint = row.source_gpoint,
            blend_gpoint = row.blend_gpoint,
        ))
        length(directions) >= slot_blend_linearized_candidate_count() && break
    end
    return directions, rows
end

function slot_blend_linearized_trial(full_model, base_model, directions, deltas)
    blends = NamedTuple[]
    model = deepcopy(base_model)
    for (direction, delta) in zip(directions, deltas)
        delta > 0 || continue
        blend = (
            local_index = direction.local_index,
            source_gpoint = direction.source_gpoint,
            blend_gpoint = direction.blend_gpoint,
            alpha = delta,
        )
        apply_slot_blend!(model, full_model, blend)
        push!(blends, blend)
    end
    breakdown = final_objective_breakdown_from_model(
        model;
        method = "slot blend linearized candidate breakdown",
    )
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return breakdown, cases, blends
end

function slot_blend_linearized_refit_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_blends = latest_slot_blend_refinement_moves()
    base_model = slot_blend_model(full_model, base_blends; include_existing = false)
    base_breakdown = final_objective_breakdown_from_model(
        base_model;
        method = "slot blend linearized base breakdown",
    )
    base_residual = all_shortwave_residual_vector(base_model)
    directions, single_rows =
        ranked_unique_slot_blend_directions(full_model, base_model, base_breakdown)
    h = slot_blend_linearized_probe_alpha()
    basis = zeros(Float64, length(base_residual), length(directions))
    for (j, direction) in enumerate(directions)
        moved = deepcopy(base_model)
        apply_slot_blend!(
            moved,
            full_model,
            (
                local_index = direction.local_index,
                source_gpoint = direction.source_gpoint,
                blend_gpoint = direction.blend_gpoint,
                alpha = h,
            ),
        )
        basis[:, j] .= (all_shortwave_residual_vector(moved) .- base_residual) ./ h
    end

    rows = NamedTuple[]
    max_alpha = slot_blend_linearized_max_alpha()
    for lambda in slot_blend_linearized_ridge_lambdas()
        lhs = basis' * basis + lambda * I
        rhs = -(basis' * base_residual)
        raw_delta = isempty(directions) ? Float64[] : Vector(lhs \ rhs)
        clipped_delta = clamp.(raw_delta, 0.0, max_alpha)
        breakdown, cases, blends =
            slot_blend_linearized_trial(full_model, base_model, directions, clipped_delta)
        push!(rows, (
            ridge_lambda = lambda,
            raw_delta_norm = norm(raw_delta),
            clipped_delta_norm = norm(clipped_delta),
            max_alpha = isempty(clipped_delta) ? 0.0 : maximum(clipped_delta),
            positive_delta_count = count(>(0), clipped_delta),
            exact_objective = breakdown.objective,
            objective_reduction = base_breakdown.objective - breakdown.objective,
            worst_toa_forcing_error_w_m2 =
                maximum(case.toa_forcing_max_abs for case in cases),
            worst_surface_forcing_error_w_m2 =
                maximum(case.surface_forcing_max_abs for case in cases),
            accepted = breakdown.objective < base_breakdown.objective,
            blends = blends,
            breakdown = breakdown,
        ))
    end

    best = isempty(rows) ? nothing : argmin(row -> row.exact_objective, rows)
    accepted = best !== nothing && best.exact_objective < base_breakdown.objective
    accepted_blends = accepted ? best.blends : NamedTuple[]
    all_blends = accepted ? vcat(base_blends, accepted_blends) : base_blends
    final_breakdown = accepted ? best.breakdown : base_breakdown
    return (
        case = "reduced_ecckd_slot_blend_linearized_refit",
        status = accepted ? "slot_blend_linearized_improved" :
                 "slot_blend_linearized_rejected",
        base_blend_count = length(base_blends),
        candidate_count = length(directions),
        single_trial_count = length(single_rows),
        probe_alpha = h,
        max_alpha = max_alpha,
        base_objective = base_breakdown.objective,
        best_ridge_lambda = best === nothing ? NaN : best.ridge_lambda,
        best_exact_objective = best === nothing ? base_breakdown.objective :
                               best.exact_objective,
        best_objective_reduction = best === nothing ? 0.0 :
                                   best.objective_reduction,
        best_positive_delta_count = best === nothing ? 0 : best.positive_delta_count,
        best_worst_toa_forcing_error_w_m2 =
            best === nothing ? NaN : best.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            best === nothing ? NaN : best.worst_surface_forcing_error_w_m2,
        accepted = accepted,
        accepted_blend_count = length(accepted_blends),
        accepted_blends = accepted_blends,
        all_blends = all_blends,
        total_blend_count = length(all_blends),
        final_objective = final_breakdown.objective,
        rows = rows,
        base_breakdown = base_breakdown,
        candidate_breakdown = final_breakdown,
    )
end

function slot_blend_linearized_markdown(result)
    lines = String[
        "# Reduced ecCKD Slot-Blend Linearized Refit",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Base blend count | $(result.base_blend_count) |",
        "| Candidate count | $(result.candidate_count) |",
        "| Single trial count | $(result.single_trial_count) |",
        "| Probe alpha | $(@sprintf("%.12g", result.probe_alpha)) |",
        "| Max alpha | $(@sprintf("%.12g", result.max_alpha)) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Best ridge lambda | $(@sprintf("%.12g", result.best_ridge_lambda)) |",
        "| Best exact objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best positive delta count | $(result.best_positive_delta_count) |",
        "| Best TOA forcing error | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing error | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Accepted | $(result.accepted) |",
        "| Accepted blend count | $(result.accepted_blend_count) |",
        "| Total blend count | $(result.total_blend_count) |",
        "",
        "This diagnostic finite-differences ranked slot-blend directions, solves a",
        "bounded nonnegative ridge update over them, then accepts only if the exact",
        "nonlinear hard-gate objective improves.",
    ]
    return join(lines, "\n") * "\n"
end

function write_slot_blend_linearized_artifacts(result)
    mkpath(dirname(SLOT_BLEND_LINEARIZED_REFIT_JSON))
    write(SLOT_BLEND_LINEARIZED_REFIT_JSON, json_object(result) * "\n")
    write(SLOT_BLEND_LINEARIZED_REFIT_MD, slot_blend_linearized_markdown(result))
    print(slot_blend_linearized_markdown(result))
    println("Wrote $SLOT_BLEND_LINEARIZED_REFIT_JSON")
    println("Wrote $SLOT_BLEND_LINEARIZED_REFIT_MD")
end

function main(; result = nothing)
    write_slot_blend_linearized_artifacts(
        result === nothing ? slot_blend_linearized_refit_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
