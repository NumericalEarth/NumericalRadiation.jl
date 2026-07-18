include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))

using NumericalRadiation

include(joinpath(@__DIR__, "write_ecrad_candidates.jl"))

const REDUCED_CASE_NAMES = (
    "ecckd_clear_sky_tropical_column",
    "ecckd_rcemip_style_column_subset",
)
const REDUCED_CASES = Tuple(case for case in REQUIRED_CASES if case.case in REDUCED_CASE_NAMES)

# The greedy reduced-model program was demoted on 2026-07-18: only the
# published official ecCKD path is tracked here. The frozen greedy-era
# diagnostics (16-g canonical chain, 32x31 leave-one-out boundary polish) are
# recorded in validation/FROZEN_DIAGNOSTICS.md and preserved on the archived
# ref `audit-trail-2026-07-17` (branch `audit-trail-pre-cleanup`). New
# band-count schemes only count when produced by the recovered training
# pipeline.
const REDUCED_MODELS = (
    (ng_lw = 32, ng_sw = 32, method = "full_official"),
)
const REDUCED_BREEZE_DIR = joinpath(ABR_ROOT, "..", "BreezeRadiativeHeatingDev",
                                    "Breeze.jl", "benchmarking", "results",
                                    "reduced_accuracy")

# Frozen greedy-era 16-g shortwave subset, retained solely for the archived
# optical-depth fit preflight diagnostic
# (validation/reduced_ecckd_optical_depth_fit_preflight.jl).
const WEIGHTED_GREEDY_SW_16_INDICES = [1, 4, 9, 10, 12, 13, 14, 16, 21, 22, 25, 27, 28, 30, 31, 32]
const WEIGHTED_GREEDY_SW_16_WEIGHTS = [
    0.17702426479749597,
    0.03815408244118855,
    0.015579301860285315,
    0.20367879528292673,
    0.04200925659973763,
    0.016455490940877802,
    0.01974518735155143,
    0.026502831286670296,
    0.016856231416409018,
    0.0026632936984052353,
    0.0006871228074808986,
    0.20656413811365726,
    0.22368702192850093,
    0.0044141291625588875,
    0.0030199527744255643,
    0.0029588995378284455,
]
const REDUCED_MODEL_METADATA = IdDict{Any, NamedTuple}()

function register_reduced_model(model; lw_indices = nothing, sw_indices = nothing,
                                lw_groups = nothing, sw_groups = nothing,
                                full_lw_weights = nothing, full_sw_weights = nothing,
                                use_reduced_incoming_weights = false,
                                lw_boundary_projection = nothing,
                                sw_boundary_projection = nothing)
    REDUCED_MODEL_METADATA[model] = (
        lw_indices = lw_indices,
        sw_indices = sw_indices,
        lw_groups = lw_groups,
        sw_groups = sw_groups,
        full_lw_weights = full_lw_weights,
        full_sw_weights = full_sw_weights,
        use_reduced_incoming_weights = use_reduced_incoming_weights,
        lw_boundary_projection = lw_boundary_projection,
        sw_boundary_projection = sw_boundary_projection,
    )
    return model
end

function uses_full_official_shortwave_weights(gas_optics)
    metadata = get(REDUCED_MODEL_METADATA, gas_optics, nothing)
    return metadata === nothing
end

function uses_reduced_incoming_shortwave_weights(gas_optics)
    metadata = get(REDUCED_MODEL_METADATA, gas_optics, nothing)
    metadata === nothing && return false
    return hasproperty(metadata, :use_reduced_incoming_weights) &&
           metadata.use_reduced_incoming_weights
end

function normalized_subset(weights, indices)
    subset = collect(weights[indices])
    total = sum(subset)
    total > 0 || error("selected spectral weights must have positive sum")
    return subset ./ total
end

function subset_or_empty(array, indices)
    length(array) == 0 && return array
    return array[indices, :, :, :]
end

function subset_or_empty(array::AbstractMatrix, indices)
    length(array) == 0 && return array
    return array[indices, :]
end

function gpoint_groups(nfull, nreduced)
    nreduced <= nfull ||
        throw(ArgumentError("cannot reduce $nfull g-points to $nreduced"))
    edges = round.(Int, range(1, nfull + 1; length = nreduced + 1))
    groups = [edges[i]:(edges[i + 1] - 1) for i in 1:nreduced]
    all(!isempty, groups) || error("empty g-point group generated")
    return groups
end

function normalized_group_weights(weights, groups)
    subset = [sum(weights[group]) for group in groups]
    total = sum(subset)
    total > 0 || error("selected spectral weights must have positive sum")
    return subset ./ total
end

function weighted_group_reduce(array::AbstractArray{FT, 4}, weights, groups) where FT
    length(array) == 0 && return array
    reduced = zeros(FT, length(groups), size(array, 2), size(array, 3), size(array, 4))
    for (i, group) in enumerate(groups)
        group_weight = sum(weights[group])
        group_weight > 0 || error("g-point group weight must be positive")
        for local_index in group
            reduced[i, :, :, :] .+= (weights[local_index] / group_weight) .* array[local_index, :, :, :]
        end
    end
    return reduced
end

function weighted_group_reduce(array::AbstractMatrix{FT}, weights, groups) where FT
    length(array) == 0 && return array
    reduced = zeros(FT, length(groups), size(array, 2))
    for (i, group) in enumerate(groups)
        group_weight = sum(weights[group])
        group_weight > 0 || error("g-point group weight must be positive")
        for local_index in group
            reduced[i, :] .+= (weights[local_index] / group_weight) .* array[local_index, :]
        end
    end
    return reduced
end

function weighted_group_reduce(vector::AbstractVector{FT}, weights, groups) where FT
    length(vector) == 0 && return vector
    reduced = zeros(FT, length(groups))
    for (i, group) in enumerate(groups)
        group_weight = sum(weights[group])
        group_weight > 0 || error("g-point group weight must be positive")
        for local_index in group
            reduced[i] += (weights[local_index] / group_weight) * vector[local_index]
        end
    end
    return reduced
end

function indexed_tabulated_model(model, lw_indices, sw_indices)
    source_table = model.longwave_source_table === nothing ||
        length(model.longwave_source_table) == 0 ?
        model.longwave_source_table :
        model.longwave_source_table[lw_indices, :]

    reduced = EcCKDTabulatedGasOpticsModel(
        gas_names = NumericalRadiation.gas_names(model),
        pressure_grid = model.pressure_grid,
        temperature_grid = model.temperature_grid,
        h2o_mole_fraction_grid = model.h2o_mole_fraction_grid,
        gas_reference_mole_fractions = model.gas_reference_mole_fractions,
        longwave_absorption = model.longwave_absorption[lw_indices, :, :, :],
        shortwave_absorption = model.shortwave_absorption[sw_indices, :, :, :],
        longwave_h2o_absorption = subset_or_empty(model.longwave_h2o_absorption, lw_indices),
        shortwave_h2o_absorption = subset_or_empty(model.shortwave_h2o_absorption, sw_indices),
        shortwave_rayleigh_molar_scattering = model.shortwave_rayleigh_molar_scattering[sw_indices],
        longwave_source_scale = model.longwave_source_scale[lw_indices],
        longwave_source_temperature_grid = model.longwave_source_temperature_grid,
        longwave_source_table = source_table,
        longwave_weights = normalized_subset(model.longwave_weights, lw_indices),
        shortwave_weights = normalized_subset(model.shortwave_weights, sw_indices),
    )
    return register_reduced_model(reduced;
        lw_indices = collect(lw_indices),
        sw_indices = collect(sw_indices),
        full_lw_weights = model.longwave_weights,
        full_sw_weights = model.shortwave_weights,
    )
end

function weighted_tabulated_model(model, ng_lw, ng_sw)
    lw_groups = gpoint_groups(size(model.longwave_absorption, 1), ng_lw)
    sw_groups = gpoint_groups(size(model.shortwave_absorption, 1), ng_sw)

    reduced = EcCKDTabulatedGasOpticsModel(
        gas_names = NumericalRadiation.gas_names(model),
        pressure_grid = model.pressure_grid,
        temperature_grid = model.temperature_grid,
        h2o_mole_fraction_grid = model.h2o_mole_fraction_grid,
        gas_reference_mole_fractions = model.gas_reference_mole_fractions,
        longwave_absorption = weighted_group_reduce(model.longwave_absorption,
                                                    model.longwave_weights,
                                                    lw_groups),
        shortwave_absorption = weighted_group_reduce(model.shortwave_absorption,
                                                     model.shortwave_weights,
                                                     sw_groups),
        longwave_h2o_absorption = weighted_group_reduce(model.longwave_h2o_absorption,
                                                        model.longwave_weights,
                                                        lw_groups),
        shortwave_h2o_absorption = weighted_group_reduce(model.shortwave_h2o_absorption,
                                                         model.shortwave_weights,
                                                         sw_groups),
        shortwave_rayleigh_molar_scattering =
            weighted_group_reduce(model.shortwave_rayleigh_molar_scattering,
                                  model.shortwave_weights,
                                  sw_groups),
        longwave_source_scale = weighted_group_reduce(model.longwave_source_scale,
                                                      model.longwave_weights,
                                                      lw_groups),
        longwave_source_temperature_grid = model.longwave_source_temperature_grid,
        longwave_source_table = weighted_group_reduce(model.longwave_source_table,
                                                      model.longwave_weights,
                                                      lw_groups),
        longwave_weights = normalized_group_weights(model.longwave_weights, lw_groups),
        shortwave_weights = normalized_group_weights(model.shortwave_weights, sw_groups),
    )
    return register_reduced_model(reduced;
        lw_groups = lw_groups,
        sw_groups = sw_groups,
        full_lw_weights = model.longwave_weights,
        full_sw_weights = model.shortwave_weights,
    )
end

function reduced_tabulated_model(model, spec)
    if spec.method == "full_official"
        return model
    end
    error("unknown reduced model method $(spec.method)")
end

function reduce_gpoint_matrix(values, weights; indices = nothing, groups = nothing)
    values === nothing && return nothing
    size(values, 1) == length(weights) || return values
    if indices !== nothing
        return values[indices, :]
    elseif groups !== nothing
        reduced = zeros(eltype(values), length(groups), size(values, 2))
        for (i, group) in enumerate(groups)
            group_weight = sum(weights[group])
            group_weight > 0 || error("g-point group weight must be positive")
            for local_index in group
                reduced[i, :] .+= (weights[local_index] / group_weight) .* values[local_index, :]
            end
        end
        return reduced
    end
    return values
end

function gpoint_fraction_projection(source_definition_path, target_definition_path)
    nc = require_ncdatasets()
    nc.NCDataset(source_definition_path) do source_dataset
        nc.NCDataset(target_definition_path) do target_dataset
            source_fraction = Array(source_dataset["gpoint_fraction"])
            target_fraction = Array(target_dataset["gpoint_fraction"])
            size(source_fraction, 1) == size(target_fraction, 1) ||
                throw(DimensionMismatch("source and target gpoint_fraction grids differ"))
            wavenumber1 = Array(target_dataset["wavenumber1"])
            wavenumber2 = Array(target_dataset["wavenumber2"])
            widths = abs.(wavenumber2 .- wavenumber1)
            overlap = target_fraction' * (source_fraction .* widths)
            projection = similar(overlap)
            for target_index in axes(overlap, 1)
                total = sum(overlap[target_index, :])
                projection[target_index, :] .=
                    total > 0 ? overlap[target_index, :] ./ total :
                    fill(inv(size(overlap, 2)), size(overlap, 2))
            end
            return projection
        end
    end
end

function project_gpoint_matrix(values, projection)
    values === nothing && return nothing
    size(values, 1) == size(projection, 2) || return values
    return projection * values
end

function reduced_shortwave_boundary_arrays(surface_albedo_spectral,
                                           surface_albedo_direct_spectral,
                                           toa_shortwave_down_spectral,
                                           gas_optics)
    metadata = get(REDUCED_MODEL_METADATA, gas_optics, nothing)
    metadata === nothing &&
        return surface_albedo_spectral, surface_albedo_direct_spectral,
            toa_shortwave_down_spectral
    full_sw_weights = metadata.full_sw_weights === nothing ?
        gas_optics.shortwave_weights : metadata.full_sw_weights
    if hasproperty(metadata, :sw_boundary_projection) &&
       metadata.sw_boundary_projection !== nothing
        projection = gpoint_fraction_projection(
            metadata.sw_boundary_projection.source_definition_path,
            metadata.sw_boundary_projection.target_definition_path,
        )
        return (
            project_gpoint_matrix(surface_albedo_spectral, projection),
            project_gpoint_matrix(surface_albedo_direct_spectral, projection),
            project_gpoint_matrix(toa_shortwave_down_spectral, projection),
        )
    end
    return (
        reduce_gpoint_matrix(surface_albedo_spectral, full_sw_weights;
            indices = metadata.sw_indices,
            groups = metadata.sw_groups),
        reduce_gpoint_matrix(surface_albedo_direct_spectral, full_sw_weights;
            indices = metadata.sw_indices,
            groups = metadata.sw_groups),
        reduce_gpoint_matrix(toa_shortwave_down_spectral, full_sw_weights;
            indices = metadata.sw_indices,
            groups = metadata.sw_groups),
    )
end

function projected_longwave_boundary_array(surface_longwave_up_spectral, gas_optics)
    surface_longwave_up_spectral === nothing && return nothing
    metadata = get(REDUCED_MODEL_METADATA, gas_optics, nothing)
    metadata === nothing && return surface_longwave_up_spectral
    if hasproperty(metadata, :lw_boundary_projection) &&
       metadata.lw_boundary_projection !== nothing
        projection = gpoint_fraction_projection(
            metadata.lw_boundary_projection.source_definition_path,
            metadata.lw_boundary_projection.target_definition_path,
        )
        return project_gpoint_matrix(surface_longwave_up_spectral, projection)
    end
    return surface_longwave_up_spectral
end

function flux_workspace(gas_optics, nlayers)
    longwave = LongwaveOpticalProperties(
        zeros(Float64, size(gas_optics.longwave_absorption, 1), nlayers),
        zeros(Float64, size(gas_optics.longwave_absorption, 1), nlayers),
        source_top = zeros(Float64, size(gas_optics.longwave_absorption, 1), nlayers),
        source_bottom = zeros(Float64, size(gas_optics.longwave_absorption, 1), nlayers),
    )
    shortwave = ShortwaveOpticalProperties(
        zeros(Float64, size(gas_optics.shortwave_absorption, 1), nlayers),
    )
    fluxes = RadiativeFluxes(
        longwave_up = zeros(Float64, nlayers + 1),
        longwave_down = zeros(Float64, nlayers + 1),
        shortwave_up = zeros(Float64, nlayers + 1),
        shortwave_down = zeros(Float64, nlayers + 1),
    )
    heating = zeros(Float64, nlayers)
    return longwave, shortwave, fluxes, heating
end

function candidate_arrays(path, gas_optics)
    nc = require_ncdatasets()
    nc.NCDataset(reference_path(path)) do dataset
        pressure_layers = Array(dataset["pressure_layer"])
        pressure_interfaces = Array(dataset["pressure_interface"])
        temperature_layers = Array(dataset["temperature_layer"])
        temperature_interfaces = Array(dataset["temperature_interface"])
        gas_amounts = gas_column_amounts(dataset, pressure_interfaces)
        surface_temperature = Array(dataset["surface_temperature"])
        surface_albedo = Array(dataset["surface_albedo"])
        variables = String.(collect(keys(dataset)))
        surface_albedo_spectral = "surface_albedo_spectral" in variables ?
            Array(dataset["surface_albedo_spectral"]) : nothing
        surface_albedo_direct_spectral =
            "surface_albedo_direct_gpoint" in variables ?
            Array(dataset["surface_albedo_direct_gpoint"]) :
            "surface_albedo_direct_spectral" in variables ?
            Array(dataset["surface_albedo_direct_spectral"]) : nothing
        surface_longwave_up_spectral = "surface_longwave_up_spectral" in variables ?
            Array(dataset["surface_longwave_up_spectral"]) : nothing
        surface_longwave_up_spectral =
            projected_longwave_boundary_array(surface_longwave_up_spectral, gas_optics)
        toa_shortwave_down_spectral = "toa_shortwave_down_spectral" in variables ?
            Array(dataset["toa_shortwave_down_spectral"]) : nothing
        surface_albedo_spectral, surface_albedo_direct_spectral,
            toa_shortwave_down_spectral =
            reduced_shortwave_boundary_arrays(surface_albedo_spectral,
                                              surface_albedo_direct_spectral,
                                              toa_shortwave_down_spectral,
                                              gas_optics)
        if surface_albedo_spectral !== nothing &&
           size(surface_albedo_spectral, 1) != size(gas_optics.shortwave_absorption, 1)
            surface_albedo_spectral = nothing
        end
        if surface_albedo_direct_spectral !== nothing &&
           size(surface_albedo_direct_spectral, 1) != size(gas_optics.shortwave_absorption, 1)
            surface_albedo_direct_spectral = nothing
        end
        if toa_shortwave_down_spectral !== nothing &&
           size(toa_shortwave_down_spectral, 1) != size(gas_optics.shortwave_absorption, 1)
            toa_shortwave_down_spectral = nothing
        end
        if surface_longwave_up_spectral !== nothing &&
           size(surface_longwave_up_spectral, 1) != size(gas_optics.longwave_absorption, 1)
            surface_longwave_up_spectral = nothing
        end
        reference_lw_up = Array(dataset["lw_up"])
        reference_sw_up = Array(dataset["sw_up"])
        reference_sw_down = Array(dataset["sw_down"])
        toa_shortwave_down = reference_sw_down[1, :]
        solar_irradiance = "solar_irradiance" in variables ?
            Array(dataset["solar_irradiance"]) :
            fill(DEFAULT_SOLAR_IRRADIANCE, length(toa_shortwave_down))
        cos_zenith = "cos_solar_zenith_angle" in variables ?
            Array(dataset["cos_solar_zenith_angle"]) :
            clamp.(toa_shortwave_down ./ solar_irradiance, 0.0, 1.0)

        nlayers, ncolumns = size(pressure_layers)
        lw_up = zeros(Float64, nlayers + 1, ncolumns)
        lw_down = zeros(Float64, nlayers + 1, ncolumns)
        sw_up = zeros(Float64, nlayers + 1, ncolumns)
        sw_down = zeros(Float64, nlayers + 1, ncolumns)
        heating = zeros(Float64, nlayers, ncolumns)
        longwave, shortwave, fluxes, column_heating = flux_workspace(gas_optics, nlayers)

        for j in 1:ncolumns
            atmosphere = ColumnAtmosphere(
                pressure_layers = pressure_layers[:, j],
                pressure_interfaces = pressure_interfaces[:, j],
                temperature_layers = temperature_layers[:, j],
                temperature_interfaces = temperature_interfaces[:, j],
                gases = Dict(name => values[:, j] for (name, values) in gas_amounts.amounts),
                surface = (;),
                geometry = (; cos_zenith = cos_zenith[j]),
            )
            optical_properties!(longwave, shortwave, gas_optics, atmosphere)
            if toa_shortwave_down_spectral !== nothing &&
               (uses_full_official_shortwave_weights(gas_optics) ||
                uses_reduced_incoming_shortwave_weights(gas_optics))
                column_toa = max.(toa_shortwave_down_spectral[:, j], 0.0)
                column_total = sum(column_toa)
                if column_total > 0
                    shortwave.weights .= column_toa ./ column_total
                end
            end
            radiative_fluxes!(
                fluxes,
                CloudlessLongwave(),
                longwave,
                atmosphere,
                LongwaveBoundaryConditions(
                    surface_longwave_up = surface_longwave_up_spectral === nothing ?
                        longwave_surface_boundary(gas_optics, surface_temperature[j],
                                                  reference_lw_up[end, j]) :
                        surface_longwave_up_spectral[:, j] ./ gas_optics.longwave_weights,
                ),
            )
            effective_surface_albedo = reference_sw_down[end, j] <= 0 ?
                surface_albedo[j] :
                clamp(reference_sw_up[end, j] / reference_sw_down[end, j], 0.0, 1.0)
            radiative_fluxes!(
                fluxes,
                CloudlessShortwave(rayleigh_backscatter_fraction =
                    env_float("RH_SW_RAYLEIGH_BACKSCATTER_FRACTION", 0.5)),
                shortwave,
                atmosphere,
                ShortwaveBoundaryConditions(
                    toa_shortwave_down = max(toa_shortwave_down[j], 0.0),
                    surface_albedo = surface_albedo_spectral === nothing ?
                        effective_surface_albedo :
                        surface_albedo_spectral[:, j],
                    surface_albedo_direct = surface_albedo_direct_spectral === nothing ?
                        surface_albedo_spectral === nothing ?
                            effective_surface_albedo :
                            surface_albedo_spectral[:, j] :
                        surface_albedo_direct_spectral[:, j],
                ),
            )
            heating_rates!(column_heating, fluxes, atmosphere;
                           gravity = GRAVITY, heat_capacity = 1004.0)
            lw_up[:, j] = fluxes.longwave_up
            lw_down[:, j] = fluxes.longwave_down
            sw_up[:, j] = fluxes.shortwave_up
            sw_down[:, j] = fluxes.shortwave_down
            heating[:, j] = 86400.0 .* column_heating
        end
        return (
            lw_up = lw_up,
            lw_down = lw_down,
            sw_up = sw_up,
            sw_down = sw_down,
            heating_rate = heating,
        )
    end
end

function metric_pair(candidate, reference)
    difference = candidate .- reference
    return (
        rmse = sqrt(sum(abs2, difference) / length(difference)),
        max_abs = maximum(abs, difference),
    )
end

function boundary_net(arrays, boundary)
    i = boundary == :toa ? 1 : size(arrays.lw_up, 1)
    return arrays.lw_down[i, :] .- arrays.lw_up[i, :] .+
           arrays.sw_down[i, :] .- arrays.sw_up[i, :]
end

function case_metrics(case, gas_optics)
    nc = require_ncdatasets()
    candidate = candidate_arrays(case.path, gas_optics)
    nc.NCDataset(reference_path(case.path)) do dataset
        reference = (
            lw_up = Array(dataset["lw_up"]),
            lw_down = Array(dataset["lw_down"]),
            sw_up = Array(dataset["sw_up"]),
            sw_down = Array(dataset["sw_down"]),
            heating_rate = Array(dataset["heating_rate"]),
        )
        variable_metrics = (
            lw_up = metric_pair(candidate.lw_up, reference.lw_up),
            lw_down = metric_pair(candidate.lw_down, reference.lw_down),
            sw_up = metric_pair(candidate.sw_up, reference.sw_up),
            sw_down = metric_pair(candidate.sw_down, reference.sw_down),
            heating_rate = metric_pair(candidate.heating_rate, reference.heating_rate),
        )
        toa = maximum(abs, boundary_net(candidate, :toa) .- boundary_net(reference, :toa))
        surface = maximum(abs, boundary_net(candidate, :surface) .-
                               boundary_net(reference, :surface))
        passed = variable_metrics.lw_up.rmse <= ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2 &&
                 variable_metrics.lw_down.rmse <= ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2 &&
                 variable_metrics.sw_up.rmse <= ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2 &&
                 variable_metrics.sw_down.rmse <= ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2 &&
                 variable_metrics.heating_rate.rmse <= ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day &&
                 variable_metrics.lw_up.max_abs <= ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2 &&
                 variable_metrics.lw_down.max_abs <= ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2 &&
                 variable_metrics.sw_up.max_abs <= ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2 &&
                 variable_metrics.sw_down.max_abs <= ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2 &&
                 variable_metrics.heating_rate.max_abs <= ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day &&
                 toa <= ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2 &&
                 surface <= ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2
        return (
            case = case.case,
            path = case.path,
            passed_hard_thresholds = passed,
            variables = variable_metrics,
            toa_forcing_max_abs = toa,
            surface_forcing_max_abs = surface,
        )
    end
end

function model_metrics(full_model, model_spec)
    model = reduced_tabulated_model(full_model, model_spec)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return (
        ng_lw = model_spec.ng_lw,
        ng_sw = model_spec.ng_sw,
        reduction_method = model_spec.method == "full_official" ?
            "official ecCKD 32x32 baseline without shortwave reduction" :
            error("unknown reduced model method $(model_spec.method)"),
        passed_hard_thresholds = all(case -> case.passed_hard_thresholds, cases),
        cases = cases,
    )
end

function markdown_report(result)
    lines = String[
        "# Reduced ecCKD Accuracy",
        "",
        "Status: **$(result.status)**",
        "",
        "Reference scope: clean ecCKD cloudless/no-aerosol tropical and RCEMIP-style cases.",
        "",
        "| ng_lw | ng_sw | Method | Passed | Worst TOA forcing error | Worst surface forcing error |",
        "|---:|---:|---|---:|---:|---:|",
    ]
    for model in result.models
        worst_toa = maximum(case.toa_forcing_max_abs for case in model.cases)
        worst_surface = maximum(case.surface_forcing_max_abs for case in model.cases)
        push!(lines, "| $(model.ng_lw) | $(model.ng_sw) | $(model.reduction_method) | $(model.passed_hard_thresholds) | $(@sprintf("%.12g", worst_toa)) W m^-2 | $(@sprintf("%.12g", worst_surface)) W m^-2 |")
    end
    append!(lines, [
        "",
        "Only the published official ecCKD path is tracked here. The frozen greedy-era reduced diagnostics are recorded in `validation/FROZEN_DIAGNOSTICS.md`; new band-count schemes only count when produced by the recovered training pipeline.",
    ])
    return join(lines, "\n") * "\n"
end

function reduced_accuracy_main()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    models = [model_metrics(full_model, spec) for spec in REDUCED_MODELS]
    status = all(model -> model.passed_hard_thresholds, models) ? "passed" : "failed_threshold"
    result = (
        case = "radiative_heating_reduced_accuracy",
        timestamp_utc = string(Dates.now()),
        status = status,
        reference_scope = collect(REDUCED_CASE_NAMES),
        acceptance_thresholds = ACCEPTANCE_THRESHOLDS,
        models = models,
    )
    results_dir = validation_results_dir()
    mkpath(results_dir)
    abr_json = joinpath(results_dir, "reduced_ecckd_accuracy.json")
    abr_md = joinpath(results_dir, "reduced_ecckd_accuracy.md")
    write(abr_json, json_object(result))
    write(abr_md, markdown_report(result))

    mkpath(REDUCED_BREEZE_DIR)
    breeze_json = joinpath(REDUCED_BREEZE_DIR, "radiative_heating_reduced_accuracy_latest.json")
    breeze_md = joinpath(REDUCED_BREEZE_DIR, "radiative_heating_reduced_accuracy_latest.md")
    write(breeze_json, json_object(result))
    write(breeze_md, markdown_report(result))

    print(markdown_report(result))
    println("Wrote $abr_json")
    println("Wrote $abr_md")
    println("Wrote $breeze_json")
    println("Wrote $breeze_md")
end

if abspath(PROGRAM_FILE) == @__FILE__
    reduced_accuracy_main()
end
