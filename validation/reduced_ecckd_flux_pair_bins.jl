include(joinpath(@__DIR__, "validation_results.jl"))

using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_accuracy.jl"))

const FLUX_PAIR_BINS_JSON =
    validation_results_path("reduced_ecckd_flux_pair_bins.json")
const FLUX_PAIR_BINS_MD =
    validation_results_path("reduced_ecckd_flux_pair_bins.md")

function flux_pair_case_objective(case)
    return max(
        case.variables.sw_up.rmse / ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
        case.variables.sw_down.rmse / ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
        case.variables.sw_up.max_abs / ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        case.variables.sw_down.max_abs / ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        case.variables.heating_rate.rmse /
            ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day,
        case.variables.heating_rate.max_abs /
            ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
        case.toa_forcing_max_abs /
            ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
        case.surface_forcing_max_abs /
            ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
    )
end

function single_shortwave_gpoint_model(full_model, gpoint)
    model = indexed_tabulated_model(
        full_model,
        collect(1:size(full_model.longwave_absorption, 1)),
        [gpoint],
    )
    model.shortwave_weights .= [1.0]
    return model
end

function flux_pair_feature(full_model, gpoint)
    model = single_shortwave_gpoint_model(full_model, gpoint)
    blocks = Float64[]
    for case in REDUCED_CASES
        arrays = candidate_arrays(case.path, model)
        push!(blocks, vec(arrays.sw_up)...)
        push!(blocks, vec(arrays.sw_down)...)
        push!(blocks, vec(arrays.heating_rate)...)
        push!(blocks, vec(boundary_net(arrays, :toa))...)
        push!(blocks, vec(boundary_net(arrays, :surface))...)
    end
    return blocks
end

function normalized_flux_pair_features(full_model)
    features = [flux_pair_feature(full_model, gpoint) for gpoint in 1:32]
    matrix = reduce(hcat, features)
    for row in axes(matrix, 1)
        scale = maximum(abs, matrix[row, :])
        scale > 0 || continue
        matrix[row, :] ./= scale
    end
    return [matrix[:, gpoint] for gpoint in 1:32]
end

function greedy_flux_pair_groups(full_model)
    features = normalized_flux_pair_features(full_model)
    weights = full_model.shortwave_weights
    remaining = Set(1:32)
    pairs = Vector{Vector{Int}}()
    while !isempty(remaining)
        anchor = first(sort(collect(remaining); by = g -> -weights[g]))
        delete!(remaining, anchor)
        if isempty(remaining)
            push!(pairs, [anchor])
            break
        end
        _, partner_index = findmin(g -> norm(features[anchor] .- features[g]),
                                   collect(remaining))
        partner = collect(remaining)[partner_index]
        delete!(remaining, partner)
        push!(pairs, sort([anchor, partner]))
    end
    return sort(pairs; by = pair -> first(pair))
end

function flux_pair_tabulated_model(full_model, groups)
    reduced = EcCKDTabulatedGasOpticsModel(
        gas_names = NumericalRadiation.gas_names(full_model),
        pressure_grid = full_model.pressure_grid,
        temperature_grid = full_model.temperature_grid,
        h2o_mole_fraction_grid = full_model.h2o_mole_fraction_grid,
        gas_reference_mole_fractions = full_model.gas_reference_mole_fractions,
        longwave_absorption = full_model.longwave_absorption,
        shortwave_absorption = weighted_group_reduce(full_model.shortwave_absorption,
                                                     full_model.shortwave_weights,
                                                     groups),
        longwave_h2o_absorption = full_model.longwave_h2o_absorption,
        shortwave_h2o_absorption = weighted_group_reduce(full_model.shortwave_h2o_absorption,
                                                         full_model.shortwave_weights,
                                                         groups),
        shortwave_rayleigh_molar_scattering =
            weighted_group_reduce(full_model.shortwave_rayleigh_molar_scattering,
                                  full_model.shortwave_weights,
                                  groups),
        longwave_source_scale = full_model.longwave_source_scale,
        longwave_source_temperature_grid = full_model.longwave_source_temperature_grid,
        longwave_source_table = full_model.longwave_source_table,
        longwave_weights = full_model.longwave_weights,
        shortwave_weights = normalized_group_weights(full_model.shortwave_weights, groups),
    )
    return register_reduced_model(reduced;
        sw_groups = groups,
        full_sw_weights = full_model.shortwave_weights,
    )
end

function flux_pair_bins_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    groups = greedy_flux_pair_groups(full_model)
    model = flux_pair_tabulated_model(full_model, groups)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    objective = maximum(flux_pair_case_objective, cases)
    return (
        case = "reduced_ecckd_flux_pair_bins",
        status = all(case -> case.passed_hard_thresholds, cases) ?
                 "passed_threshold" : "failed_threshold",
        ng_lw = 32,
        ng_sw = length(groups),
        reduction_method =
            "flux-profile paired official ecCKD shortwave bins with spectral-weighted coefficient averages",
        groups = groups,
        objective = objective,
        worst_toa_forcing_error =
            maximum(case.toa_forcing_max_abs for case in cases),
        worst_surface_forcing_error =
            maximum(case.surface_forcing_max_abs for case in cases),
        passed_hard_thresholds = all(case -> case.passed_hard_thresholds, cases),
        cases = cases,
    )
end

function flux_pair_bins_markdown(result)
    group_text = join([join(group, "+") for group in result.groups], ", ")
    lines = String[
        "# Reduced ecCKD Flux-Pair Bins",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| ng_lw | $(result.ng_lw) |",
        "| ng_sw | $(result.ng_sw) |",
        "| Objective | $(@sprintf("%.12g", result.objective)) |",
        "| Worst TOA forcing | $(@sprintf("%.12g", result.worst_toa_forcing_error)) W m^-2 |",
        "| Worst surface forcing | $(@sprintf("%.12g", result.worst_surface_forcing_error)) W m^-2 |",
        "| Passed hard thresholds | $(result.passed_hard_thresholds) |",
        "",
        "Groups: `$(group_text)`",
        "",
        "This diagnostic pairs official shortwave g-points by similarity of their",
        "single-gpoint flux, heating-rate, and boundary-flux profiles on the",
        "reduced validation cases, then evaluates a 16-bin spectral-weighted",
        "coefficient average.",
    ]
    return join(lines, "\n") * "\n"
end

function write_flux_pair_bins_artifacts(result)
    mkpath(dirname(FLUX_PAIR_BINS_JSON))
    write(FLUX_PAIR_BINS_JSON, json_object(result) * "\n")
    write(FLUX_PAIR_BINS_MD, flux_pair_bins_markdown(result))
    print(flux_pair_bins_markdown(result))
    println("Wrote $FLUX_PAIR_BINS_JSON")
    println("Wrote $FLUX_PAIR_BINS_MD")
end

function main(; result = nothing)
    write_flux_pair_bins_artifacts(result === nothing ? flux_pair_bins_result() : result)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
