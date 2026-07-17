include(joinpath(@__DIR__, "validation_results.jl"))

using Printf

include(joinpath(@__DIR__, "reduced_ecckd_flux_pair_bins.jl"))

const GROUPED_QUADRATURE_SEARCH_JSON =
    validation_results_path("reduced_ecckd_grouped_quadrature_search.json")
const GROUPED_QUADRATURE_SEARCH_MD =
    validation_results_path("reduced_ecckd_grouped_quadrature_search.md")

function grouped_quadrature_feature(full_model, gpoint;
                                    flux_weight,
                                    heating_weight,
                                    boundary_weight)
    model = single_shortwave_gpoint_model(full_model, gpoint)
    blocks = Float64[]
    for case in REDUCED_CASES
        arrays = candidate_arrays(case.path, model)
        push!(blocks, (flux_weight / ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2) .*
                      vec(arrays.sw_up)...)
        push!(blocks, (flux_weight / ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2) .*
                      vec(arrays.sw_down)...)
        push!(blocks, (heating_weight / ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day) .*
                      vec(arrays.heating_rate)...)
        push!(blocks, (boundary_weight / ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2) .*
                      vec(boundary_net(arrays, :toa))...)
        push!(blocks, (boundary_weight / ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2) .*
                      vec(boundary_net(arrays, :surface))...)
    end
    return blocks
end

function grouped_quadrature_features(full_model; flux_weight, heating_weight,
                                     boundary_weight)
    return [
        grouped_quadrature_feature(
            full_model,
            gpoint;
            flux_weight,
            heating_weight,
            boundary_weight,
        )
        for gpoint in 1:32
    ]
end

function greedy_grouped_pairs(features, weights; anchor_order)
    remaining = Set(1:32)
    groups = Vector{Vector{Int}}()
    for anchor in anchor_order
        anchor in remaining || continue
        delete!(remaining, anchor)
        if isempty(remaining)
            push!(groups, [anchor])
            break
        end
        candidates = collect(remaining)
        _, partner_index = findmin(g -> norm(features[anchor] .- features[g]),
                                   candidates)
        partner = candidates[partner_index]
        delete!(remaining, partner)
        push!(groups, sort([anchor, partner]))
    end
    return sort(groups; by = pair -> first(pair))
end

function grouped_quadrature_anchor_orders(weights)
    return (
        spectral = collect(1:32),
        reverse_spectral = collect(32:-1:1),
        weight_descending = sortperm(collect(weights), rev = true),
        weight_ascending = sortperm(collect(weights), rev = false),
        weighted_greedy_first = vcat(
            WEIGHTED_GREEDY_SW_16_INDICES,
            [g for g in 1:32 if !(g in WEIGHTED_GREEDY_SW_16_INDICES)],
        ),
    )
end

function grouped_quadrature_candidate_groups(full_model)
    candidates = NamedTuple[]
    seen = Set{String}()
    for weights in (
            (flux = 1.0, heating = 1.0, boundary = 1.0),
            (flux = 0.25, heating = 1.0, boundary = 4.0),
            (flux = 0.1, heating = 1.0, boundary = 10.0),
            (flux = 1.0, heating = 4.0, boundary = 4.0),
            (flux = 0.1, heating = 4.0, boundary = 12.0),
        )
        features = grouped_quadrature_features(
            full_model;
            flux_weight = weights.flux,
            heating_weight = weights.heating,
            boundary_weight = weights.boundary,
        )
        for (anchor_name, anchor_order) in pairs(grouped_quadrature_anchor_orders(
                full_model.shortwave_weights))
            groups = greedy_grouped_pairs(
                features,
                full_model.shortwave_weights;
                anchor_order,
            )
            key = join([join(group, "+") for group in groups], ",")
            key in seen && continue
            push!(seen, key)
            push!(candidates, (
                label = "$(anchor_name)_flux$(weights.flux)_heat$(weights.heating)_boundary$(weights.boundary)",
                groups = groups,
                flux_weight = weights.flux,
                heating_weight = weights.heating,
                boundary_weight = weights.boundary,
            ))
        end
    end
    adjacent_groups = [collect(group) for group in gpoint_groups(32, 16)]
    key = join([join(group, "+") for group in adjacent_groups], ",")
    if !(key in seen)
        push!(candidates, (
            label = "adjacent_spectral_pairs",
            groups = adjacent_groups,
            flux_weight = 0.0,
            heating_weight = 0.0,
            boundary_weight = 0.0,
        ))
    end
    return candidates
end

function grouped_quadrature_case_objective(case)
    return flux_pair_case_objective(case)
end

function grouped_quadrature_score(full_model, candidate)
    model = flux_pair_tabulated_model(full_model, candidate.groups)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return (
        label = candidate.label,
        groups = candidate.groups,
        flux_weight = candidate.flux_weight,
        heating_weight = candidate.heating_weight,
        boundary_weight = candidate.boundary_weight,
        objective = maximum(grouped_quadrature_case_objective, cases),
        worst_toa_forcing_error =
            maximum(case.toa_forcing_max_abs for case in cases),
        worst_surface_forcing_error =
            maximum(case.surface_forcing_max_abs for case in cases),
        passed_hard_thresholds = all(case -> case.passed_hard_thresholds, cases),
        cases = cases,
    )
end

function grouped_quadrature_search_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    require_ncdatasets()
    Base.retry_load_extensions()
    full_model = candidate_gas_optics(Float64)
    candidates = grouped_quadrature_candidate_groups(full_model)
    rows = [grouped_quadrature_score(full_model, candidate) for candidate in candidates]
    best = argmin(row -> row.objective, rows)
    return (
        case = "reduced_ecckd_grouped_quadrature_search",
        status = best.passed_hard_thresholds ? "passed_threshold" :
                 "failed_threshold",
        candidate_count = length(rows),
        ng_lw = 32,
        ng_sw = 16,
        best_label = best.label,
        best_groups = best.groups,
        best_objective = best.objective,
        best_worst_toa_forcing_error = best.worst_toa_forcing_error,
        best_worst_surface_forcing_error = best.worst_surface_forcing_error,
        passed_hard_thresholds = best.passed_hard_thresholds,
        best_cases = best.cases,
        rows = rows,
    )
end

function grouped_quadrature_search_markdown(result)
    group_text = join([join(group, "+") for group in result.best_groups], ", ")
    lines = String[
        "# Reduced ecCKD Grouped Quadrature Search",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Candidates | $(result.candidate_count) |",
        "| ng_lw | $(result.ng_lw) |",
        "| ng_sw | $(result.ng_sw) |",
        "| Best label | $(result.best_label) |",
        "| Best objective | $(@sprintf("%.12g", result.best_objective)) |",
        "| Worst TOA forcing | $(@sprintf("%.12g", result.best_worst_toa_forcing_error)) W m^-2 |",
        "| Worst surface forcing | $(@sprintf("%.12g", result.best_worst_surface_forcing_error)) W m^-2 |",
        "| Passed hard thresholds | $(result.passed_hard_thresholds) |",
        "",
        "Best groups: `$(group_text)`",
        "",
        "This diagnostic searches deterministic 16-bin pairings generated from",
        "different flux, heating-rate, and boundary-flux feature scalings and",
        "anchor orderings. Each candidate is exact-evaluated as a grouped",
        "spectral-weighted coefficient table against the hard clean ecCKD cases.",
        "",
        "## Candidate Summary",
        "",
        "| Label | Objective | TOA forcing | Surface forcing | Passed |",
        "|---|---:|---:|---:|---:|",
    ]
    for row in sort(collect(result.rows); by = row -> row.objective)
        push!(lines, "| $(row.label) | $(@sprintf("%.12g", row.objective)) | $(@sprintf("%.12g", row.worst_toa_forcing_error)) | $(@sprintf("%.12g", row.worst_surface_forcing_error)) | $(row.passed_hard_thresholds) |")
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = grouped_quadrature_search_result()
    mkpath(dirname(GROUPED_QUADRATURE_SEARCH_JSON))
    write(GROUPED_QUADRATURE_SEARCH_JSON, json_object(result) * "\n")
    write(GROUPED_QUADRATURE_SEARCH_MD, grouped_quadrature_search_markdown(result))
    print(grouped_quadrature_search_markdown(result))
    println("Wrote $GROUPED_QUADRATURE_SEARCH_JSON")
    println("Wrote $GROUPED_QUADRATURE_SEARCH_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
