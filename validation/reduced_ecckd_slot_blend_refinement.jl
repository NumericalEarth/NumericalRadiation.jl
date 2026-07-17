include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_boundary_column_refinement.jl"))

const SLOT_BLEND_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_slot_blend_refinement.json")
const SLOT_BLEND_REFINEMENT_MD =
    validation_results_path("reduced_ecckd_slot_blend_refinement.md")

slot_blend_radius() =
    parse(Int, get(ENV, "RH_REDUCED_SLOT_BLEND_RADIUS", "2"))

function slot_blend_alphas()
    raw = get(ENV, "RH_REDUCED_SLOT_BLEND_ALPHAS", "0.015625,0.03125,0.0625,0.125")
    return [parse(Float64, strip(token)) for token in split(raw, ",") if !isempty(strip(token))]
end

slot_blend_include_existing() =
    lowercase(get(ENV, "RH_REDUCED_SLOT_BLEND_INCLUDE_EXISTING", "false")) in
    ("1", "true", "yes")

slot_blend_iterations() =
    parse(Int, get(ENV, "RH_REDUCED_SLOT_BLEND_ITERATIONS", "1"))

function slot_blend_candidates(indices; radius = slot_blend_radius())
    selected = Set(indices)
    rows = NamedTuple[]
    for (local_index, gpoint) in pairs(indices)
        for candidate_gpoint in max(1, gpoint - radius):min(32, gpoint + radius)
            candidate_gpoint == gpoint && continue
            candidate_gpoint in selected && continue
            push!(rows, (
                local_index = local_index,
                source_gpoint = gpoint,
                blend_gpoint = candidate_gpoint,
            ))
        end
    end
    return rows
end

function apply_slot_blend!(model, full_model, blend)
    alpha = blend.alpha
    ig = blend.local_index
    jg = blend.blend_gpoint
    model.shortwave_absorption[ig, :, :, :] .=
        (1 - alpha) .* model.shortwave_absorption[ig, :, :, :] .+
        alpha .* full_model.shortwave_absorption[jg, :, :, :]
    if length(model.shortwave_h2o_absorption) != 0 &&
       length(full_model.shortwave_h2o_absorption) != 0
        model.shortwave_h2o_absorption[ig, :, :, :] .=
            (1 - alpha) .* model.shortwave_h2o_absorption[ig, :, :, :] .+
            alpha .* full_model.shortwave_h2o_absorption[jg, :, :, :]
    end
    model.shortwave_rayleigh_molar_scattering[ig] =
        (1 - alpha) * model.shortwave_rayleigh_molar_scattering[ig] +
        alpha * full_model.shortwave_rayleigh_molar_scattering[jg]
    return model
end

function apply_slot_blends!(model, full_model, blends)
    for blend in blends
        apply_slot_blend!(model, full_model, blend)
    end
    return model
end

function slot_blend_model(full_model, blends; include_existing = true)
    model = current_table_refined_model(full_model)
    if include_existing
        apply_slot_blends!(model, full_model, latest_slot_blend_refinement_moves())
    end
    apply_slot_blends!(model, full_model, blends)
    return model
end

function best_slot_blend_step(full_model, base_model, base_breakdown, candidates)
    rows = NamedTuple[]
    for candidate in candidates
        for alpha in slot_blend_alphas()
            blend = (
                local_index = candidate.local_index,
                source_gpoint = candidate.source_gpoint,
                blend_gpoint = candidate.blend_gpoint,
                alpha = alpha,
            )
            model = deepcopy(base_model)
            apply_slot_blend!(model, full_model, blend)
            breakdown = final_objective_breakdown_from_model(
                model;
                method = "slot blend refinement candidate breakdown",
            )
            push!(rows, (
                local_index = blend.local_index,
                source_gpoint = blend.source_gpoint,
                blend_gpoint = blend.blend_gpoint,
                alpha = alpha,
                objective = breakdown.objective,
                improvement = base_breakdown.objective - breakdown.objective,
                worst_case = breakdown.worst_case,
                worst_metric = breakdown.worst_metric,
                worst_value = breakdown.worst_value,
                worst_threshold = breakdown.worst_threshold,
                blend = blend,
                breakdown = breakdown,
            ))
        end
    end
    isempty(rows) && error("no slot-blend candidates were evaluated")
    return argmin(row -> row.objective, rows), rows
end

function slot_blend_refinement_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    active_moves = best_available_active_table_entry_moves()
    include_existing = slot_blend_include_existing()
    existing_blends = include_existing ? latest_slot_blend_refinement_moves() : NamedTuple[]
    current_blends = collect(existing_blends)
    current_model = slot_blend_model(full_model, current_blends; include_existing = false)
    initial_breakdown = final_objective_breakdown_from_model(
        current_model;
        method = "slot blend refinement base breakdown",
    )
    candidates = slot_blend_candidates(WEIGHTED_GREEDY_SW_16_INDICES)
    accepted_blends = NamedTuple[]
    iteration_history = NamedTuple[]
    rows = NamedTuple[]
    current_breakdown = initial_breakdown
    best = nothing
    for iteration in 1:slot_blend_iterations()
        best, rows = best_slot_blend_step(
            full_model,
            current_model,
            current_breakdown,
            candidates,
        )
        accepted_iteration = best.objective < current_breakdown.objective
        push!(iteration_history, (
            iteration = iteration,
            base_objective = current_breakdown.objective,
            candidate_objective = best.objective,
            objective_reduction = current_breakdown.objective - best.objective,
            accepted = accepted_iteration,
            local_index = best.local_index,
            source_gpoint = best.source_gpoint,
            blend_gpoint = best.blend_gpoint,
            alpha = best.alpha,
            worst_case = best.worst_case,
            worst_metric = best.worst_metric,
        ))
        accepted_iteration || break
        push!(accepted_blends, best.blend)
        push!(current_blends, best.blend)
        apply_slot_blend!(current_model, full_model, best.blend)
        current_breakdown = best.breakdown
        if current_breakdown.objective <= 1.0
            break
        end
    end
    best === nothing && error("no slot-blend iteration was evaluated")
    accepted = !isempty(accepted_blends)
    all_blends = current_blends
    return (
        case = "reduced_ecckd_slot_blend_refinement",
        status = "preflight_ready",
        radius = slot_blend_radius(),
        alphas = slot_blend_alphas(),
        iterations_requested = slot_blend_iterations(),
        iterations_completed = length(iteration_history),
        active_move_count = length(active_moves),
        include_existing_blends = include_existing,
        candidate_count = length(candidates),
        evaluated_trial_count = length(rows) * length(iteration_history),
        base_objective = initial_breakdown.objective,
        candidate_objective = best.objective,
        final_objective = current_breakdown.objective,
        objective_reduction = initial_breakdown.objective - current_breakdown.objective,
        accepted = accepted,
        accepted_blend_count = length(accepted_blends),
        accepted_blends = accepted_blends,
        all_blends = all_blends,
        total_blend_count = length(all_blends),
        best_local_index = best.local_index,
        best_source_gpoint = best.source_gpoint,
        best_blend_gpoint = best.blend_gpoint,
        best_alpha = best.alpha,
        best_worst_case = best.worst_case,
        best_worst_metric = best.worst_metric,
        iteration_history = iteration_history,
        rows = rows,
        base_breakdown = initial_breakdown,
        candidate_breakdown = current_breakdown,
    )
end

function slot_blend_markdown(result)
    lines = String[
        "# Reduced ecCKD Slot-Blend Refinement",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Radius | $(result.radius) |",
        "| Iterations requested | $(result.iterations_requested) |",
        "| Iterations completed | $(result.iterations_completed) |",
        "| Candidate count | $(result.candidate_count) |",
        "| Evaluated trial count | $(result.evaluated_trial_count) |",
        "| Active move count | $(result.active_move_count) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Candidate objective | $(@sprintf("%.12g", result.candidate_objective)) |",
        "| Final objective | $(@sprintf("%.12g", result.final_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Accepted | $(result.accepted) |",
        "| Accepted blend count | $(result.accepted_blend_count) |",
        "| Total blend count | $(result.total_blend_count) |",
        "| Best local index | $(result.best_local_index) |",
        "| Best move | g$(result.best_source_gpoint) -> g$(result.best_blend_gpoint) |",
        "| Best alpha | $(@sprintf("%.12g", result.best_alpha)) |",
        "| Best worst case | $(result.best_worst_case) |",
        "| Best worst metric | $(result.best_worst_metric) |",
        "",
        "This diagnostic convexly blends one optimized reduced shortwave slot",
        "toward a nearby full official ecCKD g-point table. It is a bounded",
        "quadrature/table deformation and is accepted only if the nonlinear",
        "hard-gate objective improves.",
    ]
    return join(lines, "\n") * "\n"
end

function write_slot_blend_artifacts(result)
    mkpath(dirname(SLOT_BLEND_REFINEMENT_JSON))
    write(SLOT_BLEND_REFINEMENT_JSON, json_object(result) * "\n")
    write(SLOT_BLEND_REFINEMENT_MD, slot_blend_markdown(result))
    print(slot_blend_markdown(result))
    println("Wrote $SLOT_BLEND_REFINEMENT_JSON")
    println("Wrote $SLOT_BLEND_REFINEMENT_MD")
end

function main(; result = nothing)
    write_slot_blend_artifacts(
        result === nothing ? slot_blend_refinement_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
