include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_slot_blend_refinement.jl"))

const PAIR_SLOT_BLEND_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_pair_slot_blend_refinement.json")
const PAIR_SLOT_BLEND_REFINEMENT_MD =
    validation_results_path("reduced_ecckd_pair_slot_blend_refinement.md")

pair_slot_blend_single_count() =
    parse(Int, get(ENV, "RH_REDUCED_PAIR_SLOT_BLEND_SINGLE_COUNT", "16"))

pair_slot_blend_pair_count() =
    parse(Int, get(ENV, "RH_REDUCED_PAIR_SLOT_BLEND_PAIR_COUNT", "128"))

function pair_slot_blend_refinement_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_blends = latest_slot_blend_refinement_moves()
    base_model = slot_blend_model(full_model, base_blends; include_existing = false)
    base_breakdown = final_objective_breakdown_from_model(
        base_model;
        method = "pair slot blend refinement base breakdown",
    )
    candidates = slot_blend_candidates(WEIGHTED_GREEDY_SW_16_INDICES)
    single_best, single_rows = best_slot_blend_step(
        full_model,
        base_model,
        base_breakdown,
        candidates,
    )
    ranked_singles =
        first(sort(single_rows, by = row -> row.objective),
              min(pair_slot_blend_single_count(), length(single_rows)))

    pair_candidates = NamedTuple[]
    for i in eachindex(ranked_singles)
        for j in (i + 1):length(ranked_singles)
            ranked_singles[i].local_index == ranked_singles[j].local_index &&
                continue
            push!(pair_candidates, (
                first = ranked_singles[i].blend,
                second = ranked_singles[j].blend,
                single_objective_sum =
                    ranked_singles[i].objective + ranked_singles[j].objective,
            ))
        end
    end
    pair_candidates = first(pair_candidates,
                            min(pair_slot_blend_pair_count(),
                                length(pair_candidates)))

    rows = NamedTuple[]
    for candidate in pair_candidates
        model = deepcopy(base_model)
        apply_slot_blend!(model, full_model, candidate.first)
        apply_slot_blend!(model, full_model, candidate.second)
        breakdown = final_objective_breakdown_from_model(
            model;
            method = "pair slot blend refinement candidate breakdown",
        )
        push!(rows, (
            objective = breakdown.objective,
            improvement = base_breakdown.objective - breakdown.objective,
            first = candidate.first,
            second = candidate.second,
            worst_case = breakdown.worst_case,
            worst_metric = breakdown.worst_metric,
            worst_value = breakdown.worst_value,
            worst_threshold = breakdown.worst_threshold,
            breakdown = breakdown,
        ))
    end

    best = isempty(rows) ? nothing : argmin(row -> row.objective, rows)
    accepted = best !== nothing && best.objective < base_breakdown.objective
    accepted_blends = accepted ? [best.first, best.second] : NamedTuple[]
    final_blends = vcat(base_blends, accepted_blends)
    final_breakdown = accepted ? best.breakdown : base_breakdown
    return (
        case = "reduced_ecckd_pair_slot_blend_refinement",
        status = "preflight_ready",
        radius = slot_blend_radius(),
        alphas = slot_blend_alphas(),
        base_blend_count = length(base_blends),
        single_candidate_count = length(single_rows),
        ranked_single_count = length(ranked_singles),
        pair_candidate_count = length(pair_candidates),
        evaluated_pair_count = length(rows),
        base_objective = base_breakdown.objective,
        best_single_objective = single_best.objective,
        best_pair_objective = best === nothing ? base_breakdown.objective : best.objective,
        final_objective = final_breakdown.objective,
        objective_reduction = base_breakdown.objective - final_breakdown.objective,
        accepted = accepted,
        accepted_blend_count = length(accepted_blends),
        accepted_blends = accepted_blends,
        all_blends = final_blends,
        total_blend_count = length(final_blends),
        best_first_blend = best === nothing ? nothing : best.first,
        best_second_blend = best === nothing ? nothing : best.second,
        best_worst_case = best === nothing ? base_breakdown.worst_case : best.worst_case,
        best_worst_metric = best === nothing ? base_breakdown.worst_metric : best.worst_metric,
        rows = rows,
        base_breakdown = base_breakdown,
        candidate_breakdown = final_breakdown,
    )
end

function pair_slot_blend_markdown(result)
    first_move = result.best_first_blend === nothing ? "n/a" :
        "g$(result.best_first_blend.source_gpoint) -> g$(result.best_first_blend.blend_gpoint) alpha $(@sprintf("%.12g", result.best_first_blend.alpha))"
    second_move = result.best_second_blend === nothing ? "n/a" :
        "g$(result.best_second_blend.source_gpoint) -> g$(result.best_second_blend.blend_gpoint) alpha $(@sprintf("%.12g", result.best_second_blend.alpha))"
    lines = String[
        "# Reduced ecCKD Pair Slot-Blend Refinement",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Radius | $(result.radius) |",
        "| Base blend count | $(result.base_blend_count) |",
        "| Ranked single count | $(result.ranked_single_count) |",
        "| Evaluated pair count | $(result.evaluated_pair_count) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Best single objective | $(@sprintf("%.12g", result.best_single_objective)) |",
        "| Best pair objective | $(@sprintf("%.12g", result.best_pair_objective)) |",
        "| Final objective | $(@sprintf("%.12g", result.final_objective)) |",
        "| Objective reduction | $(@sprintf("%.12g", result.objective_reduction)) |",
        "| Accepted | $(result.accepted) |",
        "| Accepted blend count | $(result.accepted_blend_count) |",
        "| Total blend count | $(result.total_blend_count) |",
        "| Best first move | $first_move |",
        "| Best second move | $second_move |",
        "| Best worst case | $(result.best_worst_case) |",
        "| Best worst metric | $(result.best_worst_metric) |",
        "",
        "This diagnostic evaluates bounded pairs from the best single slot-blend",
        "candidates and accepts the pair only if the nonlinear hard-gate objective",
        "improves.",
    ]
    return join(lines, "\n") * "\n"
end

function write_pair_slot_blend_artifacts(result)
    mkpath(dirname(PAIR_SLOT_BLEND_REFINEMENT_JSON))
    write(PAIR_SLOT_BLEND_REFINEMENT_JSON, json_object(result) * "\n")
    write(PAIR_SLOT_BLEND_REFINEMENT_MD, pair_slot_blend_markdown(result))
    print(pair_slot_blend_markdown(result))
    println("Wrote $PAIR_SLOT_BLEND_REFINEMENT_JSON")
    println("Wrote $PAIR_SLOT_BLEND_REFINEMENT_MD")
end

function main(; result = nothing)
    write_pair_slot_blend_artifacts(
        result === nothing ? pair_slot_blend_refinement_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
