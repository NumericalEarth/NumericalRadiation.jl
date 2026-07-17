include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using LinearAlgebra
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_optimization_preflight.jl"))

const CONSTRAINED_TABLE_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_constrained_table_optimizer.json")
const CONSTRAINED_TABLE_OPTIMIZER_MD =
    validation_results_path("reduced_ecckd_constrained_table_optimizer.md")

constrained_table_candidate_count() =
    parse(Int, get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_CANDIDATES", "8"))

constrained_table_probe_step() =
    parse(Float64, get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_PROBE_STEP", "0.015625"))

constrained_table_max_log_scale() =
    parse(Float64, get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_MAX_LOG_SCALE", "0.125"))

constrained_table_candidate_scope() =
    get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_SCOPE", "pressure_band_active")

constrained_table_probe_pool_multiplier() =
    parse(Int, get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_PROBE_POOL_MULTIPLIER", "4"))

constrained_table_include_rayleigh() =
    lowercase(get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH", "false")) in
    ("1", "true", "yes")

constrained_table_progress() =
    lowercase(get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_PROGRESS", "false")) in
    ("1", "true", "yes")

constrained_table_max_probe_seconds() =
    parse(Float64, get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_MAX_PROBE_SECONDS", "Inf"))

constrained_table_residual_mode() =
    get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE", "all_shortwave")

function constrained_table_sw_indices()
    raw = strip(get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_SW_INDICES", ""))
    isempty(raw) && return WEIGHTED_GREEDY_SW_16_INDICES
    return [parse(Int, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function constrained_table_shortwave_weights(full_model, sw_indices)
    raw = strip(get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_SW_WEIGHTS", ""))
    if isempty(raw)
        return normalized_subset(full_model.shortwave_weights, sw_indices)
    end
    weights = [parse(Float64, strip(token)) for token in split(raw, ",")
               if !isempty(strip(token))]
    length(weights) == length(sw_indices) ||
        throw(ArgumentError("RH_REDUCED_CONSTRAINED_TABLE_SW_WEIGHTS length must match SW indices"))
    total = sum(weights)
    total > 0 || throw(ArgumentError("custom shortwave weights must sum positive"))
    return weights ./ total
end

constrained_table_base_mode() =
    get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_BASE_MODE", "canonical")

function constrained_table_ridge_lambdas()
    raw = get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_RIDGE_LAMBDAS",
              "1.0e-6,1.0e-4,1.0e-2,1.0,100.0")
    return [parse(Float64, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function current_constrained_table_model(full_model, moves = NamedTuple[];
                                         sw_indices = constrained_table_sw_indices(),
                                         base_mode = constrained_table_base_mode())
    if base_mode == "canonical" && sw_indices == WEIGHTED_GREEDY_SW_16_INDICES
        model = reduced_tabulated_model(full_model, (
            ng_lw = 32,
            ng_sw = 16,
            method = "weighted_greedy_subset_preflight_table_refined",
        ))
    elseif base_mode == "boundary_weight_refit" &&
           sw_indices == WEIGHTED_GREEDY_SW_16_INDICES
        model = reduced_tabulated_model(full_model, (
            ng_lw = 32,
            ng_sw = 16,
            method = "weighted_greedy_subset_boundary_weight_refit",
        ))
    elseif base_mode == "boundary_table_continuation" &&
           sw_indices == WEIGHTED_GREEDY_SW_16_INDICES
        model = reduced_tabulated_model(full_model, (
            ng_lw = 32,
            ng_sw = 16,
            method = "weighted_greedy_subset_boundary_table_continuation",
        ))
    elseif base_mode == "boundary_table_post_descent" &&
           sw_indices == WEIGHTED_GREEDY_SW_16_INDICES
        model = reduced_tabulated_model(full_model, (
            ng_lw = 32,
            ng_sw = 16,
            method = "weighted_greedy_subset_boundary_weight_refit",
        ))
        apply_active_table_entry_moves!(
            model,
            latest_boundary_base_constrained_table_optimizer_moves(),
        )
        apply_active_table_entry_moves!(
            model,
            latest_boundary_table_coordinate_scan_moves(),
        )
        apply_active_table_entry_moves!(
            model,
            latest_boundary_table_pair_coordinate_scan_moves(),
        )
        apply_active_table_entry_moves!(
            model,
            latest_boundary_table_coordinate_descent_moves(),
        )
    elseif base_mode == "boundary_base_table" &&
           sw_indices == WEIGHTED_GREEDY_SW_16_INDICES
        model = reduced_tabulated_model(full_model, (
            ng_lw = 32,
            ng_sw = 16,
            method = "weighted_greedy_subset_boundary_weight_refit",
        ))
        apply_active_table_entry_moves!(
            model,
            latest_boundary_base_constrained_table_optimizer_moves(),
        )
    elseif base_mode == "plain_topology"
        model = indexed_tabulated_model(
            full_model,
            collect(1:size(full_model.longwave_absorption, 1)),
            sw_indices,
        )
        model.shortwave_weights .= constrained_table_shortwave_weights(
            full_model,
            sw_indices,
        )
    elseif base_mode == "retained_topology"
        model = retained_topology_constrained_base_model(full_model, sw_indices)
    else
        throw(ArgumentError("unsupported constrained table base mode $base_mode"))
    end
    for move in moves
        apply_active_table_entry_move!(model, move)
    end
    return model
end

function retained_topology_constrained_base_model(full_model, sw_indices)
    model = indexed_tabulated_model(
        full_model,
        collect(1:size(full_model.longwave_absorption, 1)),
        sw_indices,
    )
    parameters = latest_preflight_reduced_parameters()
    if parameters === nothing
        model.shortwave_weights .= constrained_table_shortwave_weights(
            full_model,
            sw_indices,
        )
    else
        apply_weight_absorption_rayleigh_parameters!(model, parameters)
    end
    apply_pressure_band_table_moves!(model, latest_preflight_pressure_band_table_moves())
    apply_active_table_entry_moves!(model, best_available_active_table_entry_moves())
    apply_best_exact_weight_refit!(model)
    apply_gas_pressure_band_refinement_moves!(
        model,
        latest_gas_pressure_band_refinement_moves(),
    )
    apply_active_table_entry_moves!(model, latest_constrained_table_optimizer_moves())
    apply_post_constrained_weight_refit!(model)
    apply_slot_blend_refinement_moves!(model, full_model, latest_slot_blend_refinement_moves())
    apply_post_slot_weight_refit!(model)
    apply_post_constrained_boundary_weight_refit!(model)
    apply_active_table_entry_moves!(
        model,
        latest_boundary_base_constrained_table_optimizer_moves(),
    )
    apply_active_table_entry_moves!(model, latest_boundary_table_coordinate_scan_moves())
    apply_active_table_entry_moves!(model, latest_boundary_table_pair_coordinate_scan_moves())
    apply_active_table_entry_moves!(model, latest_boundary_table_coordinate_descent_moves())
    apply_active_table_entry_moves!(
        model,
        latest_boundary_table_continuation_optimizer_moves(),
    )
    apply_component_scale_refit_moves!(model, latest_component_scale_refit_moves())
    apply_pressure_component_scale_refit_moves!(model, latest_pressure_component_scale_refit_moves())
    apply_temperature_component_scale_refit_moves!(
        model,
        latest_temperature_component_scale_refit_moves(),
    )
    apply_h2o_component_scale_refit_moves!(model, latest_h2o_component_scale_refit_moves())
    apply_gas_component_scale_refit_moves!(model, latest_gas_component_scale_refit_moves())
    apply_pressure_temperature_component_scale_refit_moves!(
        model,
        latest_pressure_temperature_component_scale_refit_moves(),
    )
    apply_gas_pressure_temperature_component_scale_refit_moves!(
        model,
        latest_gas_pressure_temperature_component_scale_refit_moves(),
    )
    apply_h2o_pressure_temperature_component_scale_refit_moves!(
        model,
        latest_h2o_pressure_temperature_component_scale_refit_moves(),
    )
    apply_mixed_pressure_temperature_component_refit_moves!(
        model,
        latest_mixed_pressure_temperature_component_refit_moves(),
    )
    apply_active_table_entry_moves!(model, latest_retained_structural_optimizer_moves())
    apply_active_table_entry_moves!(model, latest_retained_structural_continuation_moves())
    apply_active_table_entry_moves!(model, latest_retained_structural_continuation2_moves())
    apply_active_table_entry_moves!(model, latest_retained_structural_continuation3_moves())
    apply_active_table_entry_moves!(model, latest_retained_structural_continuation4_moves())
    apply_mixed_pressure_temperature_component_refit_moves!(
        model,
        latest_retained_mixed_component_pareto_scan_moves(),
    )
    apply_active_table_entry_moves!(model, latest_retained_objective_probe_expansion_moves())
    apply_active_table_entry_moves!(model, latest_retained_objective_probe_expansion2_moves())
    apply_active_table_entry_moves!(model, latest_retained_objective_probe_expansion3_moves())
    apply_active_table_entry_moves!(model, latest_retained_objective_probe_expansion4_moves())
    apply_active_table_entry_moves!(model, latest_retained_surface_probe_expansion_moves())
    apply_active_table_entry_moves!(model, latest_retained_surface_probe_expansion2_moves())
    apply_active_table_entry_moves!(model, latest_retained_surface_probe_expansion3_moves())
    return model
end

function full_hard_objective(model)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return maximum(normalized_case_objective, cases), cases
end

function shortwave_heating_rate(sw_up, sw_down, pressure_interfaces)
    nlayers = size(sw_up, 1) - 1
    ncolumns = size(sw_up, 2)
    heating = zeros(Float64, nlayers, ncolumns)
    factor = 86400.0 * GRAVITY / 1004.0
    for j in 1:ncolumns, k in 1:nlayers
        Δp = pressure_interfaces[k + 1, j] - pressure_interfaces[k, j]
        net_top = sw_down[k, j] - sw_up[k, j]
        net_bottom = sw_down[k + 1, j] - sw_up[k + 1, j]
        heating[k, j] = factor * (net_top - net_bottom) / Δp
    end
    return heating
end

function shortwave_residual_vector(case, model)
    nc = require_ncdatasets()
    candidate = candidate_arrays(case.path, model)
    nc.NCDataset(reference_path(case.path)) do dataset
        reference_sw_up = Array(dataset["sw_up"])
        reference_sw_down = Array(dataset["sw_down"])
        pressure_interfaces = Array(dataset["pressure_interface"])
        reference_heating =
            shortwave_heating_rate(reference_sw_up, reference_sw_down,
                                   pressure_interfaces)
        candidate_heating =
            shortwave_heating_rate(candidate.sw_up, candidate.sw_down,
                                   pressure_interfaces)
        candidate_toa = candidate.sw_down[1, :] .- candidate.sw_up[1, :]
        reference_toa = reference_sw_down[1, :] .- reference_sw_up[1, :]
        candidate_surface = candidate.sw_down[end, :] .- candidate.sw_up[end, :]
        reference_surface = reference_sw_down[end, :] .- reference_sw_up[end, :]
        sw_up_rmse_scale =
            ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2 * sqrt(length(candidate.sw_up))
        sw_down_rmse_scale =
            ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2 * sqrt(length(candidate.sw_down))
        heating_rmse_scale =
            ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day *
            sqrt(length(candidate_heating))
        return vcat(
            vec(candidate.sw_up .- reference_sw_up) ./
                ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
            vec(candidate.sw_down .- reference_sw_down) ./
                ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
            vec(candidate.sw_up .- reference_sw_up) ./ sw_up_rmse_scale,
            vec(candidate.sw_down .- reference_sw_down) ./ sw_down_rmse_scale,
            vec(candidate_toa .- reference_toa) ./
                ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
            vec(candidate_surface .- reference_surface) ./
                ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
            vec(candidate_heating .- reference_heating) ./
                ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
            vec(candidate_heating .- reference_heating) ./ heating_rmse_scale,
        )
    end
end

function all_shortwave_residual_vector(model)
    return vcat([shortwave_residual_vector(case, model) for case in REDUCED_CASES]...)
end

function boundary_shortwave_residual_vector(case, model; boundary = :both)
    nc = require_ncdatasets()
    candidate = candidate_arrays(case.path, model)
    nc.NCDataset(reference_path(case.path)) do dataset
        reference_sw_up = Array(dataset["sw_up"])
        reference_sw_down = Array(dataset["sw_down"])
        candidate_toa = candidate.sw_down[1, :] .- candidate.sw_up[1, :]
        reference_toa = reference_sw_down[1, :] .- reference_sw_up[1, :]
        candidate_surface = candidate.sw_down[end, :] .- candidate.sw_up[end, :]
        reference_surface = reference_sw_down[end, :] .- reference_sw_up[end, :]
        toa_residual = vec(candidate_toa .- reference_toa) ./
            ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2
        surface_residual = vec(candidate_surface .- reference_surface) ./
            ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2
        boundary == :toa && return toa_residual
        boundary == :surface && return surface_residual
        return vcat(toa_residual, surface_residual)
    end
end

function all_boundary_shortwave_residual_vector(model; boundary = :both)
    return vcat([boundary_shortwave_residual_vector(case, model; boundary)
                 for case in REDUCED_CASES]...)
end

function constrained_table_residual_vector(model)
    mode = constrained_table_residual_mode()
    if mode == "all_shortwave"
        return all_shortwave_residual_vector(model)
    elseif mode == "boundary"
        return all_boundary_shortwave_residual_vector(model)
    elseif mode == "toa"
        return all_boundary_shortwave_residual_vector(model; boundary = :toa)
    elseif mode == "surface"
        return all_boundary_shortwave_residual_vector(model; boundary = :surface)
    end
    throw(ArgumentError("unsupported constrained table residual mode $mode"))
end

function global_active_table_entry_candidates(full_model, case_name;
                                              sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    case = reduced_case_by_name(case_name)
    nc = require_ncdatasets()
    scores = Dict{Tuple, Float64}()
    nc.NCDataset(reference_path(case.path)) do dataset
        pressure_layers = Array(dataset["pressure_layer"])
        pressure_interfaces = Array(dataset["pressure_interface"])
        temperature_layers = Array(dataset["temperature_layer"])
        gas_amounts = gas_column_amounts(dataset, pressure_interfaces).amounts
        gases = Dict(Symbol(name) => values for (name, values) in gas_amounts)
        gas_names_tuple = NumericalRadiation.gas_names(full_model)
        references = full_model.gas_reference_mole_fractions
        nlayers, ncolumns = size(pressure_layers)

        for ig in eachindex(sw_indices), column in 1:ncolumns, k in 1:nlayers
            pressure = pressure_layers[k, column]
            temperature = temperature_layers[k, column]
            ip0, ip1, wp =
                active_entry_pressure_bracket(full_model.pressure_grid, pressure)
            it0, it1, wt =
                active_entry_temperature_corners(full_model, pressure,
                                                 temperature, ip0, ip1, wp)
            pressure_corners = ((ip0, 1.0 - wp), (ip1, wp))
            temperature_corners = ((it0, 1.0 - wt), (it1, wt))
            dry_air_moles = haskey(gases, :composite) ?
                max(gases[:composite][k, column], sqrt(eps(Float64))) :
                max((pressure_interfaces[k + 1, column] -
                     pressure_interfaces[k, column]) /
                    (9.80665 * 0.0289647), sqrt(eps(Float64)))

            for (pressure_index, pressure_weight) in pressure_corners
                for (temperature_index, temperature_weight) in temperature_corners
                    interpolation_weight = pressure_weight * temperature_weight
                    interpolation_weight <= 0 && continue
                    for gas_index in axes(full_model.shortwave_absorption, 2)
                        amount = active_entry_static_amount(
                            gases,
                            gas_names_tuple,
                            references,
                            gas_index,
                            k,
                            column,
                        )
                        priority = abs(amount) * interpolation_weight
                        priority <= 0 && continue
                        key = ("static_absorption", ig, sw_indices[ig],
                               gas_index, pressure_index, temperature_index, 0)
                        active_entry_candidate_push!(scores, key, priority)
                    end
                end

                if length(full_model.shortwave_h2o_absorption) != 0 &&
                   haskey(gases, :h2o)
                    h2o_moles = max(gases[:h2o][k, column], 0.0)
                    h2o_mole_fraction = h2o_moles / dry_air_moles
                    ih0, ih1, wh = active_entry_log_bracket(
                        full_model.h2o_mole_fraction_grid,
                        h2o_mole_fraction,
                    )
                    for (temperature_index, temperature_weight) in temperature_corners
                        for (h2o_index, h2o_weight) in ((ih0, 1.0 - wh), (ih1, wh))
                            interpolation_weight =
                                pressure_weight * temperature_weight * h2o_weight
                            interpolation_weight <= 0 && continue
                            priority = h2o_moles * interpolation_weight
                            priority <= 0 && continue
                            key = ("dynamic_h2o", ig, sw_indices[ig], 0,
                                   pressure_index, temperature_index, h2o_index)
                            active_entry_candidate_push!(scores, key, priority)
                        end
                    end
                end
            end

            rayleigh_priority =
                dry_air_moles * abs(full_model.shortwave_rayleigh_molar_scattering[sw_indices[ig]])
            if rayleigh_priority > 0
                key = ("rayleigh", ig, sw_indices[ig], 0, 0, 0, 0)
                active_entry_candidate_push!(scores, key, rayleigh_priority)
            end
        end
    end

    ranked = collect(scores)
    sort!(ranked; by = pair -> -pair.second)
    return [
        (
            component = key[1],
            local_gpoint_index = key[2],
            gpoint = key[3],
            gas_index = key[4],
            pressure_index = key[5],
            temperature_index = key[6],
            h2o_index = key[7],
            priority = priority,
        )
        for (key, priority) in ranked
    ]
end

function all_global_active_table_entry_candidates(full_model;
                                                  sw_indices = WEIGHTED_GREEDY_SW_16_INDICES)
    scores = Dict{Tuple, Float64}()
    for case in REDUCED_CASES
        for candidate in global_active_table_entry_candidates(
            full_model,
            case.case;
            sw_indices,
        )
            key = (
                candidate.component,
                candidate.local_gpoint_index,
                candidate.gpoint,
                candidate.gas_index,
                candidate.pressure_index,
                candidate.temperature_index,
                candidate.h2o_index,
            )
            active_entry_candidate_push!(scores, key, candidate.priority)
        end
    end
    ranked = collect(scores)
    sort!(ranked; by = pair -> -pair.second)
    return [
        (
            component = key[1],
            local_gpoint_index = key[2],
            gpoint = key[3],
            gas_index = key[4],
            pressure_index = key[5],
            temperature_index = key[6],
            h2o_index = key[7],
            priority = priority,
        )
        for (key, priority) in ranked
    ]
end

function constrained_table_limit_candidates(candidates, limit)
    constrained_table_include_rayleigh() ||
        return first(candidates, min(limit, length(candidates)))
    rayleigh_candidates = [candidate for candidate in candidates
                           if candidate.component == "rayleigh"]
    table_candidates = [candidate for candidate in candidates
                        if candidate.component != "rayleigh"]
    rayleigh_count = min(length(rayleigh_candidates), limit)
    table_count = max(0, limit - rayleigh_count)
    return vcat(
        first(table_candidates, min(table_count, length(table_candidates))),
        first(rayleigh_candidates, rayleigh_count),
    )
end

function constrained_table_probe_pool_limit(limit)
    multiplier = max(1, constrained_table_probe_pool_multiplier())
    return max(limit, limit * multiplier)
end

function constrained_table_probe_pool(candidates, limit)
    pool_limit = constrained_table_probe_pool_limit(limit)
    if !constrained_table_include_rayleigh()
        return first(candidates, min(pool_limit, length(candidates)))
    end

    table_candidates = [candidate for candidate in candidates
                        if candidate.component != "rayleigh"]
    rayleigh_candidates = [candidate for candidate in candidates
                           if candidate.component == "rayleigh"]
    # Probe all Rayleigh slots when enabled so the signed residual/objective
    # response, not sign-blind scattering magnitude, decides whether any
    # Rayleigh move should consume a final optimizer basis slot.
    return vcat(
        first(table_candidates, min(pool_limit, length(table_candidates))),
        rayleigh_candidates,
    )
end

function residual_probe_table_entry_candidates(full_model, base_residual; limit,
                                               sw_indices = constrained_table_sw_indices(),
                                               base_mode = constrained_table_base_mode(),
                                               base_moves = NamedTuple[])
    pool = constrained_table_probe_pool(
        all_global_active_table_entry_candidates(full_model; sw_indices),
        limit,
    )
    isempty(pool) && return NamedTuple[]

    h = constrained_table_probe_step()
    base_sse = dot(base_residual, base_residual)
    scored = NamedTuple[]
    progress = constrained_table_progress()
    max_seconds = constrained_table_max_probe_seconds()
    start_time = time()
    for (candidate_index, candidate) in enumerate(pool)
        if isfinite(max_seconds) && time() - start_time > max_seconds &&
           !isempty(scored)
            progress &&
                println("constrained table residual probe hit $(max_seconds)s cap after $(length(scored)) / $(length(pool)) candidates")
            break
        end
        progress && candidate_index % 16 == 1 &&
            println("constrained table residual probe candidate $candidate_index / $(length(pool))")
        best_sse = Inf
        best_direction = 0.0
        for direction in (-1.0, 1.0)
            moved_model = current_constrained_table_model(
                full_model,
                vcat(base_moves,
                     [move_with_log_scale(candidate, direction * h)]);
                sw_indices,
                base_mode,
            )
            residual = constrained_table_residual_vector(moved_model)
            sse = dot(residual, residual)
            if sse < best_sse
                best_sse = sse
                best_direction = direction
            end
        end
        push!(scored, (
            candidate = candidate,
            probe_objective_reduction = base_sse - best_sse,
            best_probe_direction = best_direction,
            best_probe_sse = best_sse,
            priority = candidate.priority,
        ))
    end
    sort!(scored; by = row -> (-row.probe_objective_reduction, -row.priority))
    return [row.candidate for row in first(scored, min(limit, length(scored)))]
end

function objective_probe_table_entry_candidates(full_model, base_objective; limit,
                                                sw_indices = constrained_table_sw_indices(),
                                                base_mode = constrained_table_base_mode(),
                                                base_moves = NamedTuple[])
    pool = constrained_table_probe_pool(
        all_global_active_table_entry_candidates(full_model; sw_indices),
        limit,
    )
    isempty(pool) && return NamedTuple[]

    h = constrained_table_probe_step()
    scored = NamedTuple[]
    progress = constrained_table_progress()
    max_seconds = constrained_table_max_probe_seconds()
    start_time = time()
    for (candidate_index, candidate) in enumerate(pool)
        if isfinite(max_seconds) && time() - start_time > max_seconds &&
           !isempty(scored)
            progress &&
                println("constrained table objective probe hit $(max_seconds)s cap after $(length(scored)) / $(length(pool)) candidates")
            break
        end
        progress && candidate_index % 16 == 1 &&
            println("constrained table objective probe candidate $candidate_index / $(length(pool))")
        best_objective = Inf
        best_direction = 0.0
        for direction in (-1.0, 1.0)
            moved_model = current_constrained_table_model(
                full_model,
                vcat(base_moves,
                     [move_with_log_scale(candidate, direction * h)]);
                sw_indices,
                base_mode,
            )
            objective, _ = full_hard_objective(moved_model)
            if objective < best_objective
                best_objective = objective
                best_direction = direction
            end
        end
        push!(scored, (
            candidate = candidate,
            probe_objective_reduction = base_objective - best_objective,
            best_probe_direction = best_direction,
            best_probe_objective = best_objective,
            priority = candidate.priority,
        ))
    end
    sort!(scored; by = row -> (-row.probe_objective_reduction, -row.priority))
    return [row.candidate for row in first(scored, min(limit, length(scored)))]
end

function constrained_table_move_candidates(full_model, target_case; limit,
                                           sw_indices = constrained_table_sw_indices(),
                                           base_mode = constrained_table_base_mode(),
                                           base_residual = nothing,
                                           base_objective = nothing,
                                           base_moves = NamedTuple[])
    if constrained_table_candidate_scope() == "all_global_active"
        candidates = all_global_active_table_entry_candidates(full_model; sw_indices)
        return constrained_table_limit_candidates(candidates, limit)
    elseif constrained_table_candidate_scope() == "all_global_residual_probe"
        base_residual === nothing &&
            throw(ArgumentError("all_global_residual_probe requires base_residual"))
        return residual_probe_table_entry_candidates(
            full_model,
            base_residual;
            limit,
            sw_indices,
            base_mode,
            base_moves,
        )
    elseif constrained_table_candidate_scope() == "all_global_objective_probe"
        base_objective === nothing &&
            throw(ArgumentError("all_global_objective_probe requires base_objective"))
        return objective_probe_table_entry_candidates(
            full_model,
            base_objective;
            limit,
            sw_indices,
            base_mode,
            base_moves,
        )
    elseif constrained_table_candidate_scope() == "global_active"
        candidates = global_active_table_entry_candidates(full_model, target_case;
                                                          sw_indices)
        return constrained_table_limit_candidates(candidates, limit)
    end
    pressure_moves = latest_gas_pressure_band_refinement_moves()
    if isempty(pressure_moves)
        pressure_moves = latest_preflight_pressure_band_table_moves()
    end
    candidates = targeted_active_table_entry_candidates(
        full_model,
        pressure_moves,
        target_case,
        sw_indices = sw_indices,
    )
    return first(candidates, min(limit, length(candidates)))
end

function move_with_log_scale(candidate, log_scale)
    return (
        component = candidate.component,
        local_gpoint_index = candidate.local_gpoint_index,
        gpoint = candidate.gpoint,
        gas_index = candidate.gas_index,
        pressure_index = candidate.pressure_index,
        temperature_index = candidate.temperature_index,
        h2o_index = candidate.h2o_index,
        log_scale = log_scale,
        scale = exp(log_scale),
    )
end

function constrained_table_trial(full_model, candidates, deltas;
                                 sw_indices = constrained_table_sw_indices(),
                                 base_mode = constrained_table_base_mode(),
                                 base_moves = NamedTuple[])
    moves = [move_with_log_scale(candidate, delta)
             for (candidate, delta) in zip(candidates, deltas)
             if delta != 0]
    model = current_constrained_table_model(
        full_model,
        vcat(base_moves, moves);
        sw_indices,
        base_mode,
    )
    objective, cases = full_hard_objective(model)
    return objective, cases, moves
end

function constrained_table_optimizer_result(; extra_base_moves = NamedTuple[])
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    sw_indices = constrained_table_sw_indices()
    base_mode = constrained_table_base_mode()
    artifact_base_moves = base_mode == "canonical" &&
        sw_indices == WEIGHTED_GREEDY_SW_16_INDICES ?
        latest_constrained_table_optimizer_moves() : NamedTuple[]
    base_model = current_constrained_table_model(
        full_model,
        extra_base_moves;
        sw_indices,
        base_mode,
    )
    base_objective, base_cases = full_hard_objective(base_model)
    base_breakdown = final_objective_breakdown_from_model(
        base_model;
        method = "current table-refined hard-gate breakdown",
    )
    target = constrained_table_optimizer_target(base_breakdown)
    h = constrained_table_probe_step()
    base_residual = constrained_table_residual_vector(base_model)
    candidates = constrained_table_move_candidates(
        full_model,
        base_breakdown.worst_case;
        limit = constrained_table_candidate_count(),
        sw_indices,
        base_mode,
        base_residual,
        base_objective,
        base_moves = extra_base_moves,
    )

    basis = zeros(Float64, length(base_residual), length(candidates))
    for (j, candidate) in enumerate(candidates)
        moved_model = current_constrained_table_model(
            full_model,
            vcat(extra_base_moves, [move_with_log_scale(candidate, h)]),
            sw_indices = sw_indices,
            base_mode = base_mode,
        )
        basis[:, j] .=
            (constrained_table_residual_vector(moved_model) .- base_residual) ./ h
    end

    max_delta = constrained_table_max_log_scale()
    rows = NamedTuple[]
    for lambda in constrained_table_ridge_lambdas()
        lhs = basis' * basis + lambda * I
        rhs = -(basis' * base_residual)
        raw_delta = isempty(candidates) ? Float64[] : Vector(lhs \ rhs)
        clipped_delta = clamp.(raw_delta, -max_delta, max_delta)
        objective, cases, moves =
            constrained_table_trial(
                full_model,
                candidates,
                clipped_delta;
                sw_indices,
                base_mode,
                base_moves = extra_base_moves,
            )
        push!(rows, (
            ridge_lambda = lambda,
            raw_delta_norm = norm(raw_delta),
            clipped_delta_norm = norm(clipped_delta),
            max_abs_delta = isempty(clipped_delta) ? 0.0 : maximum(abs, clipped_delta),
            exact_objective = objective,
            objective_reduction = base_objective - objective,
            worst_toa_forcing_error_w_m2 =
                maximum(case.toa_forcing_max_abs for case in cases),
            worst_surface_forcing_error_w_m2 =
                maximum(case.surface_forcing_max_abs for case in cases),
            accepted = objective < base_objective,
            moves = moves,
        ))
    end

    best = isempty(rows) ? nothing : argmin(row -> row.exact_objective, rows)
    accepted = best !== nothing && best.exact_objective < base_objective
    return (
        case = "reduced_ecckd_constrained_table_optimizer",
        status = accepted ? "constrained_table_optimizer_improved" :
                 "constrained_table_optimizer_rejected",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        method = "ridge linearized multi-parameter nonnegative shortwave table-entry optimizer with exact hard-objective acceptance",
        candidate_scope = constrained_table_candidate_scope(),
        residual_mode = constrained_table_residual_mode(),
        include_rayleigh = constrained_table_include_rayleigh(),
        base_mode = base_mode,
        sw_indices = collect(sw_indices),
        target = target,
        candidate_count = length(candidates),
        probe_step = h,
        max_log_scale = max_delta,
        base_objective = base_objective,
        base_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in base_cases),
        base_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in base_cases),
        best_ridge_lambda = best === nothing ? NaN : best.ridge_lambda,
        best_exact_objective = best === nothing ? base_objective : best.exact_objective,
        best_objective_reduction = best === nothing ? 0.0 : best.objective_reduction,
        best_worst_toa_forcing_error_w_m2 =
            best === nothing ? NaN : best.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            best === nothing ? NaN : best.worst_surface_forcing_error_w_m2,
        accepted = accepted,
        base_moves = vcat(artifact_base_moves, extra_base_moves),
        proposed_moves = best === nothing ? NamedTuple[] : best.moves,
        accepted_moves = accepted ? best.moves : NamedTuple[],
        all_active_proposed_moves =
            best === nothing ? vcat(artifact_base_moves, extra_base_moves) :
            vcat(artifact_base_moves, extra_base_moves, best.moves),
        all_active_moves = accepted ?
            vcat(artifact_base_moves, extra_base_moves, best.moves) :
            vcat(artifact_base_moves, extra_base_moves),
        rows = rows,
    )
end

function pareto_safe_forcing_update(result; tolerance = 1e-12)
    return result.best_worst_toa_forcing_error_w_m2 <=
           result.base_worst_toa_forcing_error_w_m2 + tolerance &&
           result.best_worst_surface_forcing_error_w_m2 <=
           result.base_worst_surface_forcing_error_w_m2 + tolerance
end

function pareto_guarded_forcing_result(result;
                                       rejected_status =
                                           "constrained_table_optimizer_pareto_rejected")
    pareto_safe = pareto_safe_forcing_update(result)
    if result.accepted && !pareto_safe
        return merge(
            result,
            (
                status = rejected_status,
                pareto_safe = false,
                accepted = false,
                accepted_moves = NamedTuple[],
                all_active_moves = result.base_moves,
            ),
        )
    end
    return merge(result, (pareto_safe = pareto_safe,))
end

function pareto_guarded_structural_result(result)
    return merge(result, (pareto_safe = pareto_safe_forcing_update(result),))
end

function constrained_table_markdown(result)
    lines = String[
        "# Reduced ecCKD Constrained Table Optimizer",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Target case | $(result.target.target_case) |",
        "| Target metric | $(result.target.target_metric) |",
        "| Candidate scope | $(result.candidate_scope) |",
        "| Residual mode | $(result.residual_mode) |",
        "| Include Rayleigh candidates | $(result.include_rayleigh) |",
        "| Candidate count | $(result.candidate_count) |",
        "| Probe step | $(@sprintf("%.12g", result.probe_step)) |",
        "| Max log scale | $(@sprintf("%.12g", result.max_log_scale)) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Best ridge lambda | $(@sprintf("%.12g", result.best_ridge_lambda)) |",
        "| Best exact objective | $(@sprintf("%.12g", result.best_exact_objective)) |",
        "| Best objective reduction | $(@sprintf("%.12g", result.best_objective_reduction)) |",
        "| Best TOA forcing error | $(@sprintf("%.12g", result.best_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Best surface forcing error | $(@sprintf("%.12g", result.best_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Pareto safe | $(hasproperty(result, :pareto_safe) ? result.pareto_safe : pareto_safe_forcing_update(result)) |",
        "| Accepted | $(result.accepted) |",
        "",
        "This is the first constrained multi-parameter table optimizer preflight.",
        "It linearizes hard-gate-scaled shortwave flux, heating-rate, and boundary",
        "residuals with respect to multiple active table entries, solves bounded",
        "ridge updates, then evaluates the nonlinear full hard objective before",
        "accepting any move.",
    ]
    return join(lines, "\n") * "\n"
end

function write_constrained_table_artifacts(result)
    mkpath(dirname(CONSTRAINED_TABLE_OPTIMIZER_JSON))
    write(CONSTRAINED_TABLE_OPTIMIZER_JSON, json_object(result) * "\n")
    write(CONSTRAINED_TABLE_OPTIMIZER_MD, constrained_table_markdown(result))
    print(constrained_table_markdown(result))
    println("Wrote $CONSTRAINED_TABLE_OPTIMIZER_JSON")
    println("Wrote $CONSTRAINED_TABLE_OPTIMIZER_MD")
end

function main(; result = nothing)
    write_constrained_table_artifacts(
        result === nothing ? constrained_table_optimizer_result() : result,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
