include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using LinearAlgebra
using Printf

include(joinpath(@__DIR__,
                 "reduced_ecckd_retained_current_pressure_component_optimizer.jl"))

const RETAINED_CURRENT_PRESSURE_COMPONENT_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_pressure_component_scan.json")
const RETAINED_CURRENT_PRESSURE_COMPONENT_SCAN_MD =
    validation_results_path("reduced_ecckd_retained_current_pressure_component_scan.md")
const RETAINED_CURRENT_PRESSURE_COMPONENT_RAYLEIGH_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_pressure_component_rayleigh_scan.json")
const RETAINED_CURRENT_PRESSURE_COMPONENT_RAYLEIGH_SCAN_MD =
    validation_results_path("reduced_ecckd_retained_current_pressure_component_rayleigh_scan.md")
const RETAINED_CURRENT_PRESSURE_COMPONENT_SURFACE_GUARD_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_pressure_component_surface_guard_scan.json")
const RETAINED_CURRENT_PRESSURE_COMPONENT_SURFACE_GUARD_SCAN_MD =
    validation_results_path("reduced_ecckd_retained_current_pressure_component_surface_guard_scan.md")
const RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_scan.json")
const RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_SCAN_MD =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_scan.md")
const RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_continuation_scan.json")
const RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION_SCAN_MD =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_continuation_scan.md")
const RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION2_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_continuation2_scan.json")
const RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION2_SCAN_MD =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_continuation2_scan.md")
const RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION3_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_continuation3_scan.json")
const RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION3_SCAN_MD =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_continuation3_scan.md")

function pressure_component_scan_band_counts()
    raw = get(ENV, "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_BANDS", "2,4,8,16")
    return [parse(Int, strip(token)) for token in split(raw, ",")
            if !isempty(strip(token))]
end

function pressure_component_scan_partitions()
    raw = get(ENV, "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_PARTITIONS",
              "index,log_pressure")
    return [strip(token) for token in split(raw, ",") if !isempty(strip(token))]
end

pressure_component_scan_include_rayleigh() =
    lowercase(get(ENV, "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_INCLUDE_RAYLEIGH",
                  "false")) in ("1", "true", "yes")

pressure_component_scan_surface_guard_diagnostic() =
    lowercase(get(ENV,
                  "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_SURFACE_GUARD_DIAGNOSTIC",
                  "false")) in ("1", "true", "yes")

pressure_component_scan_static_gas_split() =
    lowercase(get(ENV,
                  "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_STATIC_GAS_SPLIT",
                  "false")) in ("1", "true", "yes")

pressure_component_scan_archive_only() =
    lowercase(get(ENV,
                  "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_ARCHIVE_ONLY",
                  "false")) in ("1", "true", "yes")

pressure_component_scan_heating_weight() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_HEATING_WEIGHT",
              "1.0"))

pressure_component_scan_boundary_weight() =
    parse(Float64,
          get(ENV, "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_BOUNDARY_WEIGHT",
              "1.0"))

pressure_component_scan_base_mode() =
    get(ENV, "RH_REDUCED_CURRENT_PRESSURE_COMPONENT_SCAN_BASE_MODE",
        "current_component_scale_optimizer4_composed")

function pressure_component_scan_archive_token(raw)
    token = lowercase(strip(raw))
    token = replace(token, r"[^a-z0-9]+" => "_")
    token = replace(token, r"^_+|_+$" => "")
    return isempty(token) ? "default" : token
end

function pressure_component_scan_archive_suffix()
    mode = pressure_component_scan_static_gas_split() ? "gas_pressure" :
           pressure_component_scan_surface_guard_diagnostic() ? "surface_guard" :
           pressure_component_scan_include_rayleigh() ? "rayleigh" : "standard"
    bands = join(pressure_component_scan_band_counts(), "-")
    partitions = join(pressure_component_scan_partitions(), "-")
    surface_cap = @sprintf("%.6g", current_pressure_component_surface_cap())
    max_log_scale = @sprintf("%.6g", current_pressure_component_max_log_scale())
    min_reduction =
        @sprintf("%.6g", current_pressure_component_min_objective_reduction())
    heating_weight = @sprintf("%.6g", pressure_component_scan_heating_weight())
    boundary_weight = @sprintf("%.6g", pressure_component_scan_boundary_weight())
    base_mode = pressure_component_scan_base_mode()
    return join((
                    mode,
                    "base",
                    pressure_component_scan_archive_token(base_mode),
                    "bands",
                    pressure_component_scan_archive_token(bands),
                    "partitions",
                    pressure_component_scan_archive_token(partitions),
                    "surfacecap",
                    pressure_component_scan_archive_token(surface_cap),
                    "maxlog",
                    pressure_component_scan_archive_token(max_log_scale),
                    "minred",
                    pressure_component_scan_archive_token(min_reduction),
                    "heatw",
                    pressure_component_scan_archive_token(heating_weight),
                    "bdryw",
                    pressure_component_scan_archive_token(boundary_weight),
                ),
                "_")
end

function pressure_component_scan_archive_path(path)
    root, ext = splitext(path)
    return "$(root)_$(pressure_component_scan_archive_suffix())$(ext)"
end

pressure_component_scan_json_path() =
    pressure_component_scan_static_gas_split() &&
    pressure_component_scan_base_mode() ==
    "current_gas_pressure_component_continuation2_scan_composed" ?
    RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION3_SCAN_JSON :
    pressure_component_scan_static_gas_split() &&
    pressure_component_scan_base_mode() ==
    "current_gas_pressure_component_continuation_scan_composed" ?
    RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION2_SCAN_JSON :
    pressure_component_scan_static_gas_split() &&
    pressure_component_scan_base_mode() == "current_gas_pressure_component_scan_composed" ?
    RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION_SCAN_JSON :
    pressure_component_scan_static_gas_split() ?
    RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_SCAN_JSON :
    pressure_component_scan_surface_guard_diagnostic() ?
    RETAINED_CURRENT_PRESSURE_COMPONENT_SURFACE_GUARD_SCAN_JSON :
    pressure_component_scan_include_rayleigh() ?
    RETAINED_CURRENT_PRESSURE_COMPONENT_RAYLEIGH_SCAN_JSON :
    RETAINED_CURRENT_PRESSURE_COMPONENT_SCAN_JSON

pressure_component_scan_md_path() =
    pressure_component_scan_static_gas_split() &&
    pressure_component_scan_base_mode() ==
    "current_gas_pressure_component_continuation2_scan_composed" ?
    RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION3_SCAN_MD :
    pressure_component_scan_static_gas_split() &&
    pressure_component_scan_base_mode() ==
    "current_gas_pressure_component_continuation_scan_composed" ?
    RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION2_SCAN_MD :
    pressure_component_scan_static_gas_split() &&
    pressure_component_scan_base_mode() == "current_gas_pressure_component_scan_composed" ?
    RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION_SCAN_MD :
    pressure_component_scan_static_gas_split() ?
    RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_SCAN_MD :
    pressure_component_scan_surface_guard_diagnostic() ?
    RETAINED_CURRENT_PRESSURE_COMPONENT_SURFACE_GUARD_SCAN_MD :
    pressure_component_scan_include_rayleigh() ?
    RETAINED_CURRENT_PRESSURE_COMPONENT_RAYLEIGH_SCAN_MD :
    RETAINED_CURRENT_PRESSURE_COMPONENT_SCAN_MD

function log_pressure_component_bands(pressure_grid, nband)
    npressure = length(pressure_grid)
    logs = log.(abs.(Float64.(pressure_grid)))
    denominator = logs[end] - logs[1]
    if denominator == 0
        return current_pressure_component_bands(npressure, nband)
    end
    coordinate = (logs .- logs[1]) ./ denominator
    bands = UnitRange{Int}[]
    last_stop = 0
    for band_index in 1:nband
        lo = (band_index - 1) / nband
        hi = band_index / nband
        indices = findall(x -> x >= lo && (band_index == nband ? x <= hi : x < hi),
                          coordinate)
        if isempty(indices)
            return current_pressure_component_bands(npressure, nband)
        end
        start = first(indices)
        stop = last(indices)
        if start != last_stop + 1
            return current_pressure_component_bands(npressure, nband)
        end
        push!(bands, start:stop)
        last_stop = stop
    end
    last_stop == npressure || return current_pressure_component_bands(npressure, nband)
    return bands
end

function pressure_component_scan_bands(pressure_grid, nband, partition)
    if partition == "index"
        return current_pressure_component_bands(length(pressure_grid), nband)
    elseif partition == "log_pressure"
        return log_pressure_component_bands(pressure_grid, nband)
    else
        throw(ArgumentError("unknown pressure partition: $partition"))
    end
end

function pressure_component_scan_selected_moves(path)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"status\": \"current_pressure_component_scan_improved\"", text) ||
        return NamedTuple[]
    moves_match = Base.match(
        r"\"selected_accepted_moves\"\s*:\s*\[([\s\S]*?)\]\s*,\s*\"variants\"",
        text,
    )
    moves_match === nothing && return NamedTuple[]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_match.captures[1])
        object = match.captures[1]
        component_match = Base.match(r"\"component\"\s*:\s*\"([^\"]+)\"", object)
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        start_match = Base.match(r"\"pressure_index_start\"\s*:\s*([0-9]+)", object)
        end_match = Base.match(r"\"pressure_index_end\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if component_match === nothing ||
           local_match === nothing ||
           start_match === nothing ||
           end_match === nothing ||
           scale_match === nothing
            continue
        end
        gas_match = Base.match(r"\"gas_index\"\s*:\s*([0-9]+)", object)
        push!(moves, (
            component = component_match.captures[1],
            local_gpoint_index = parse(Int, local_match.captures[1]),
            gas_index = gas_match === nothing ? 0 : parse(Int, gas_match.captures[1]),
            pressure_index_start = parse(Int, start_match.captures[1]),
            pressure_index_end = parse(Int, end_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function apply_pressure_component_scan_moves!(model, moves)
    for move in moves
        scale = exp(clamp(move.log_scale, -5.0, 5.0))
        ig = move.local_gpoint_index
        band = move.pressure_index_start:move.pressure_index_end
        if move.component == "static_absorption"
            if move.gas_index == 0
                model.shortwave_absorption[ig, :, band, :] .*= scale
            else
                model.shortwave_absorption[ig, move.gas_index, band, :] .*= scale
            end
        elseif move.component == "h2o_absorption"
            if length(model.shortwave_h2o_absorption) != 0
                model.shortwave_h2o_absorption[ig, band, :, :] .*= scale
            end
        else
            throw(ArgumentError("unsupported pressure component scan move $(move.component)"))
        end
    end
    return model
end

function pressure_component_scan_base_model(full_model)
    base = current_four_component_scale_base(full_model)
    mode = pressure_component_scan_base_mode()
    if mode == "current_component_scale_optimizer4_composed"
        return base
    elseif mode == "current_gas_pressure_component_scan_composed"
        moves = pressure_component_scan_selected_moves(
            RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_SCAN_JSON,
        )
        isempty(moves) && return base
        return apply_pressure_component_scan_moves!(base, moves)
    elseif mode == "current_gas_pressure_component_continuation_scan_composed"
        first_moves = pressure_component_scan_selected_moves(
            RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_SCAN_JSON,
        )
        continuation_moves = pressure_component_scan_selected_moves(
            RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION_SCAN_JSON,
        )
        isempty(first_moves) || apply_pressure_component_scan_moves!(base, first_moves)
        isempty(continuation_moves) ||
            apply_pressure_component_scan_moves!(base, continuation_moves)
        return base
    elseif mode == "current_gas_pressure_component_continuation2_scan_composed"
        for path in (
            RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_SCAN_JSON,
            RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION_SCAN_JSON,
            RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION2_SCAN_JSON,
        )
            moves = pressure_component_scan_selected_moves(path)
            isempty(moves) || apply_pressure_component_scan_moves!(base, moves)
        end
        return base
    end
    throw(ArgumentError("unsupported pressure component scan base mode $mode"))
end

function pressure_component_scan_deltas_to_model(base_model, deltas, bands;
                                                 include_rayleigh = false,
                                                 static_gas_split = false)
    ng = size(base_model.shortwave_absorption, 1)
    nbands = length(bands)
    ngas = size(base_model.shortwave_absorption, 2)
    if static_gas_split
        static_parameter_count = ng * ngas * nbands
        h2o_parameter_count = ng * nbands
        pressure_parameter_count = static_parameter_count + h2o_parameter_count
        model = component_scaled_model(base_model, zeros(Float64, 3ng))
        for index in 1:static_parameter_count
            band_index = ((index - 1) % nbands) + 1
            gas_local = fld(index - 1, nbands) + 1
            gas_index = ((gas_local - 1) % ngas) + 1
            ig = fld(gas_local - 1, ngas) + 1
            scale = exp(clamp(deltas[index], -5.0, 5.0))
            model.shortwave_absorption[ig, gas_index, bands[band_index], :] .*= scale
        end
        if length(model.shortwave_h2o_absorption) != 0
            for h2o_index in 1:h2o_parameter_count
                index = static_parameter_count + h2o_index
                band_index = ((h2o_index - 1) % nbands) + 1
                ig = fld(h2o_index - 1, nbands) + 1
                scale = exp(clamp(deltas[index], -5.0, 5.0))
                model.shortwave_h2o_absorption[ig, bands[band_index], :, :] .*= scale
            end
        end
    else
        pressure_parameter_count = 2 * ng * nbands
        model = pressure_component_scaled_model(
            base_model,
            deltas[1:pressure_parameter_count],
            bands,
        )
    end
    include_rayleigh || return model
    length(deltas) == pressure_parameter_count + ng ||
        throw(DimensionMismatch("rayleigh scan vector must include ng Rayleigh entries"))
    for ig in 1:ng
        scale = exp(clamp(deltas[pressure_parameter_count + ig], -5.0, 5.0))
        model.shortwave_rayleigh_molar_scattering[ig] *= scale
    end
    return model
end

function pressure_component_scan_move(index, ng, bands, log_scale;
                                      include_rayleigh = false,
                                      static_gas_split = false,
                                      ngas = 0)
    nbands = length(bands)
    if static_gas_split
        pressure_parameter_count = ng * (ngas + 1) * nbands
        static_parameter_count = ng * ngas * nbands
        if index <= static_parameter_count
            band_index = ((index - 1) % nbands) + 1
            gas_local = fld(index - 1, nbands) + 1
            gas_index = ((gas_local - 1) % ngas) + 1
            ig = fld(gas_local - 1, ngas) + 1
            return (
                component = "static_absorption",
                local_gpoint_index = ig,
                gas_index = gas_index,
                pressure_index_start = first(bands[band_index]),
                pressure_index_end = last(bands[band_index]),
                band_index = band_index,
                parameter_index = index,
                log_scale = log_scale,
                scale = exp(log_scale),
            )
        elseif index <= pressure_parameter_count
            h2o_index = index - static_parameter_count
            band_index = ((h2o_index - 1) % nbands) + 1
            ig = fld(h2o_index - 1, nbands) + 1
            return (
                component = "h2o_absorption",
                local_gpoint_index = ig,
                gas_index = 0,
                pressure_index_start = first(bands[band_index]),
                pressure_index_end = last(bands[band_index]),
                band_index = band_index,
                parameter_index = index,
                log_scale = log_scale,
                scale = exp(log_scale),
            )
        end
    else
        pressure_parameter_count = 2 * ng * nbands
    end
    if include_rayleigh && index > pressure_parameter_count
        return (
            component = "rayleigh",
            local_gpoint_index = index - pressure_parameter_count,
            pressure_index_start = 1,
            pressure_index_end = length(bands),
            band_index = 0,
            parameter_index = index,
            log_scale = log_scale,
            scale = exp(log_scale),
        )
    end
    return pressure_component_move(index, ng, bands, log_scale)
end

function pressure_component_scan_case_residual_vector(case, model)
    heating_weight = pressure_component_scan_heating_weight()
    boundary_weight = pressure_component_scan_boundary_weight()
    nc = require_ncdatasets()
    candidate = candidate_arrays(case.path, model)
    nc.NCDataset(reference_path(case.path)) do dataset
        reference = (
            lw_up = Array(dataset["lw_up"]),
            lw_down = Array(dataset["lw_down"]),
            sw_up = Array(dataset["sw_up"]),
            sw_down = Array(dataset["sw_down"]),
            heating_rate = Array(dataset["heating_rate"]),
        )
        candidate_toa = boundary_net(candidate, :toa)
        reference_toa = boundary_net(reference, :toa)
        candidate_surface = boundary_net(candidate, :surface)
        reference_surface = boundary_net(reference, :surface)
        heating = candidate.heating_rate .- reference.heating_rate
        heating_rmse_scale =
            ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day * sqrt(length(heating))
        return vcat(
            heating_weight .* vec(heating) ./
                ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
            heating_weight .* vec(heating) ./ heating_rmse_scale,
            boundary_weight .* vec(candidate_toa .- reference_toa) ./
                ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
            boundary_weight .* vec(candidate_surface .- reference_surface) ./
                ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
        )
    end
end

function pressure_component_scan_residual_vector(model)
    return vcat([pressure_component_scan_case_residual_vector(case, model)
                 for case in REDUCED_CASES]...)
end

function pressure_component_scan_variant(base_model, base_objective, base_cases,
                                         base_residual, nband, partition,
                                         include_rayleigh, static_gas_split)
    bands = pressure_component_scan_bands(base_model.pressure_grid, nband, partition)
    ng = size(base_model.shortwave_absorption, 1)
    ngas = size(base_model.shortwave_absorption, 2)
    pressure_parameter_count = static_gas_split ?
                               ng * (ngas + 1) * length(bands) :
                               2 * ng * length(bands)
    parameter_count = pressure_parameter_count + (include_rayleigh ? ng : 0)
    probe_step = current_pressure_component_probe_step()
    max_log_scale = current_pressure_component_max_log_scale()
    surface_cap = current_pressure_component_surface_cap()
    toa_tolerance = current_pressure_component_toa_tolerance()
    min_objective_reduction = current_pressure_component_min_objective_reduction()
    base_toa = maximum(case.toa_forcing_max_abs for case in base_cases)
    base_surface = maximum(case.surface_forcing_max_abs for case in base_cases)
    base_heating_rmse = worst_heating_rmse(base_cases)

    basis = zeros(Float64, length(base_residual), parameter_count)
    for index in 1:parameter_count
        deltas = zeros(Float64, parameter_count)
        deltas[index] = probe_step
        moved = pressure_component_scan_deltas_to_model(
            base_model,
            deltas,
            bands;
            include_rayleigh = include_rayleigh,
            static_gas_split = static_gas_split,
        )
        basis[:, index] .=
            (pressure_component_scan_residual_vector(moved) .- base_residual) ./
            probe_step
    end

    rows = NamedTuple[]
    for lambda in current_pressure_component_ridge_lambdas()
        lhs = basis' * basis + lambda * I
        rhs = -(basis' * base_residual)
        raw_delta = Vector(lhs \ rhs)
        clipped_delta = clamp.(raw_delta, -max_log_scale, max_log_scale)
        model = pressure_component_scan_deltas_to_model(
            base_model,
            clipped_delta,
            bands;
            include_rayleigh = include_rayleigh,
            static_gas_split = static_gas_split,
        )
        objective, cases = full_hard_objective(model)
        toa = maximum(case.toa_forcing_max_abs for case in cases)
        surface = maximum(case.surface_forcing_max_abs for case in cases)
        heating_rmse = worst_heating_rmse(cases)
        accepted = base_objective - objective >= min_objective_reduction &&
            objective < base_objective &&
            toa <= base_toa + toa_tolerance &&
            surface <= surface_cap &&
            heating_rmse <= base_heating_rmse
        push!(rows, (
            ridge_lambda = lambda,
            exact_objective = objective,
            objective_reduction = base_objective - objective,
            worst_toa_forcing_error_w_m2 = toa,
            worst_surface_forcing_error_w_m2 = surface,
            worst_heating_rate_rmse_k_day = heating_rmse,
            accepted = accepted,
            deltas = collect(clipped_delta),
        ))
    end

    accepted_rows = filter(row -> row.accepted, rows)
    selected = isempty(accepted_rows) ? nothing :
        argmin(row -> row.exact_objective, accepted_rows)
    best = isempty(rows) ? nothing : argmin(row -> row.exact_objective, rows)
    accepted = selected !== nothing
    accepted_deltas = accepted ? selected.deltas : Float64[]
    accepted_moves = accepted ?
        [pressure_component_scan_move(
             index,
             ng,
             bands,
             delta;
             include_rayleigh = include_rayleigh,
             static_gas_split = static_gas_split,
             ngas = ngas,
         )
         for (index, delta) in enumerate(accepted_deltas) if delta != 0] :
        NamedTuple[]

    return (
        partition = partition,
        include_rayleigh = include_rayleigh,
        static_gas_split = static_gas_split,
        pressure_band_count = length(bands),
        basis_count = parameter_count,
        pressure_index_ranges = ["$(first(band)):$(last(band))" for band in bands],
        best_exact_objective = best === nothing ? base_objective : best.exact_objective,
        best_objective_reduction = best === nothing ? 0.0 : best.objective_reduction,
        best_worst_toa_forcing_error_w_m2 =
            best === nothing ? base_toa : best.worst_toa_forcing_error_w_m2,
        best_worst_surface_forcing_error_w_m2 =
            best === nothing ? base_surface : best.worst_surface_forcing_error_w_m2,
        best_worst_heating_rate_rmse_k_day =
            best === nothing ? base_heating_rmse : best.worst_heating_rate_rmse_k_day,
        accepted = accepted,
        accepted_ridge_lambda = accepted ? selected.ridge_lambda : nothing,
        accepted_objective = accepted ? selected.exact_objective : base_objective,
        accepted_objective_reduction = accepted ? selected.objective_reduction : 0.0,
        accepted_worst_toa_forcing_error_w_m2 =
            accepted ? selected.worst_toa_forcing_error_w_m2 : base_toa,
        accepted_worst_surface_forcing_error_w_m2 =
            accepted ? selected.worst_surface_forcing_error_w_m2 : base_surface,
        accepted_worst_heating_rate_rmse_k_day =
            accepted ? selected.worst_heating_rate_rmse_k_day : base_heating_rmse,
        accepted_move_count = length(accepted_moves),
        accepted_moves = accepted_moves,
    )
end

function retained_current_pressure_component_scan_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    base_model = pressure_component_scan_base_model(full_model)
    base_objective, base_cases = full_hard_objective(base_model)
    base_residual = pressure_component_scan_residual_vector(base_model)
    include_rayleigh = pressure_component_scan_include_rayleigh()
    static_gas_split = pressure_component_scan_static_gas_split()
    variants = NamedTuple[]
    for partition in pressure_component_scan_partitions()
        for nband in pressure_component_scan_band_counts()
            push!(variants,
                  pressure_component_scan_variant(base_model, base_objective,
                                                  base_cases, base_residual,
                                                  nband, partition,
                                                  include_rayleigh,
                                                  static_gas_split))
        end
    end
    accepted_variants = filter(variant -> variant.accepted, variants)
    selected = isempty(accepted_variants) ? nothing :
        argmin(variant -> variant.accepted_objective, accepted_variants)
    return (
        case = "reduced_ecckd_retained_current_pressure_component_scan",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = selected === nothing ? "current_pressure_component_scan_rejected" :
                 "current_pressure_component_scan_improved",
        residual_mode = "heating_profile_boundary",
        base_mode = pressure_component_scan_base_mode(),
        basis = include_rayleigh ?
                "per_gpoint_pressure_band_static_h2o_component_scales_plus_rayleigh" :
                static_gas_split ?
                "per_gpoint_pressure_band_static_gas_h2o_component_scales" :
                "per_gpoint_pressure_band_static_h2o_component_scales",
        include_rayleigh = include_rayleigh,
        static_gas_split = static_gas_split,
        heating_weight = pressure_component_scan_heating_weight(),
        boundary_weight = pressure_component_scan_boundary_weight(),
        probe_step = current_pressure_component_probe_step(),
        max_log_scale = current_pressure_component_max_log_scale(),
        surface_cap_w_m2 = current_pressure_component_surface_cap(),
        toa_tolerance_w_m2 = current_pressure_component_toa_tolerance(),
        min_objective_reduction = current_pressure_component_min_objective_reduction(),
        base_objective = base_objective,
        base_worst_toa_forcing_error_w_m2 =
            maximum(case.toa_forcing_max_abs for case in base_cases),
        base_worst_surface_forcing_error_w_m2 =
            maximum(case.surface_forcing_max_abs for case in base_cases),
        base_worst_heating_rate_rmse_k_day = worst_heating_rmse(base_cases),
        selected_partition = selected === nothing ? "" : selected.partition,
        selected_pressure_band_count =
            selected === nothing ? 0 : selected.pressure_band_count,
        selected_objective = selected === nothing ? base_objective :
                             selected.accepted_objective,
        selected_worst_toa_forcing_error_w_m2 =
            selected === nothing ?
            maximum(case.toa_forcing_max_abs for case in base_cases) :
            selected.accepted_worst_toa_forcing_error_w_m2,
        selected_worst_surface_forcing_error_w_m2 =
            selected === nothing ?
            maximum(case.surface_forcing_max_abs for case in base_cases) :
            selected.accepted_worst_surface_forcing_error_w_m2,
        selected_worst_heating_rate_rmse_k_day =
            selected === nothing ? worst_heating_rmse(base_cases) :
            selected.accepted_worst_heating_rate_rmse_k_day,
        selected_basis_count = selected === nothing ? 0 : selected.basis_count,
        selected_accepted_move_count =
            selected === nothing ? 0 : selected.accepted_move_count,
        selected_accepted_moves =
            selected === nothing ? NamedTuple[] : selected.accepted_moves,
        variants = variants,
    )
end

function retained_current_pressure_component_scan_markdown(result)
    lines = String[
        "# Reduced ecCKD Retained Current Pressure-Component Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Residual mode | $(result.residual_mode) |",
        "| Base mode | $(result.base_mode) |",
        "| Basis | $(result.basis) |",
        "| Include Rayleigh | $(result.include_rayleigh) |",
        "| Static gas split | $(result.static_gas_split) |",
        "| Heating residual weight | $(@sprintf("%.12g", result.heating_weight)) |",
        "| Boundary residual weight | $(@sprintf("%.12g", result.boundary_weight)) |",
        "| Probe step | $(@sprintf("%.12g", result.probe_step)) |",
        "| Max log scale | $(@sprintf("%.12g", result.max_log_scale)) |",
        "| Surface cap | $(@sprintf("%.12g", result.surface_cap_w_m2)) W m^-2 |",
        "| TOA tolerance | $(@sprintf("%.12g", result.toa_tolerance_w_m2)) W m^-2 |",
        "| Minimum objective reduction | $(@sprintf("%.12g", result.min_objective_reduction)) |",
        "| Base objective | $(@sprintf("%.12g", result.base_objective)) |",
        "| Base TOA forcing | $(@sprintf("%.12g", result.base_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Base surface forcing | $(@sprintf("%.12g", result.base_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Base heating RMSE | $(@sprintf("%.12g", result.base_worst_heating_rate_rmse_k_day)) K day^-1 |",
        "| Selected partition | $(result.selected_partition) |",
        "| Selected pressure bands | $(result.selected_pressure_band_count) |",
        "| Selected objective | $(@sprintf("%.12g", result.selected_objective)) |",
        "| Selected TOA forcing | $(@sprintf("%.12g", result.selected_worst_toa_forcing_error_w_m2)) W m^-2 |",
        "| Selected surface forcing | $(@sprintf("%.12g", result.selected_worst_surface_forcing_error_w_m2)) W m^-2 |",
        "| Selected heating RMSE | $(@sprintf("%.12g", result.selected_worst_heating_rate_rmse_k_day)) K day^-1 |",
        "",
        "This diagnostic compares pressure-component bases before promoting any",
        "new pressure-band partition into the canonical reduced row.",
        "",
        "## Variants",
        "",
        "| Partition | Rayleigh | Static gas split | Pressure bands | Basis count | Objective | TOA forcing | Surface forcing | Heating RMSE | Accepted | Moves |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for variant in result.variants
        push!(lines,
              "| $(variant.partition) | $(variant.include_rayleigh) | $(variant.static_gas_split) | $(variant.pressure_band_count) | $(variant.basis_count) | $(@sprintf("%.12g", variant.accepted_objective)) | $(@sprintf("%.12g", variant.accepted_worst_toa_forcing_error_w_m2)) | $(@sprintf("%.12g", variant.accepted_worst_surface_forcing_error_w_m2)) | $(@sprintf("%.12g", variant.accepted_worst_heating_rate_rmse_k_day)) | $(variant.accepted) | $(variant.accepted_move_count) |")
    end
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ?
        retained_current_pressure_component_scan_result() : result
    json_path = pressure_component_scan_json_path()
    md_path = pressure_component_scan_md_path()
    archive_json_path = pressure_component_scan_archive_path(json_path)
    archive_md_path = pressure_component_scan_archive_path(md_path)
    mkpath(dirname(json_path))
    markdown = retained_current_pressure_component_scan_markdown(result)
    json = json_object(result) * "\n"
    if !pressure_component_scan_archive_only()
        write(json_path, json)
        write(md_path, markdown)
    end
    write(archive_json_path, json)
    write(archive_md_path, markdown)
    print(markdown)
    if pressure_component_scan_archive_only()
        println("Skipped canonical write for $json_path")
        println("Skipped canonical write for $md_path")
    else
        println("Wrote $json_path")
        println("Wrote $md_path")
    end
    println("Wrote $archive_json_path")
    println("Wrote $archive_md_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
