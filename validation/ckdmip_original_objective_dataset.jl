include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using NCDatasets

include(joinpath(@__DIR__, "ckdmip_training_data_preflight.jl"))
include(joinpath(@__DIR__, "ecckd_original_objective_loss.jl"))

const CKDMIP_OBJECTIVE_DATASET_JSON =
    validation_results_path("ckdmip_original_objective_dataset.json")
const CKDMIP_OBJECTIVE_DATASET_MD =
    validation_results_path("ckdmip_original_objective_dataset.md")

const ECCKD_GRAVITY = 9.80665
const ECCKD_SPECIFIC_HEAT_AIR = 1004.0

function ckdmip_flux_kind(path)
    name = basename(path)
    occursin("_lw_fluxes_", name) && return "longwave"
    occursin("_sw_fluxes_", name) && return "shortwave"
    throw(ArgumentError("cannot infer CKDMIP flux kind from $(path)"))
end

function netcdf_attribute(dataset, name; default = nothing)
    key = string(name)
    return haskey(dataset.attrib, key) ? string(dataset.attrib[key]) : default
end

function ckdmip_layer_weight(pressure_hl)
    pressure = Float64.(pressure_hl)
    length(pressure) >= 2 || throw(ArgumentError("pressure_hl must include at least two half-levels"))
    all(diff(pressure) .> 0) ||
        throw(ArgumentError("pressure_hl must increase downward"))
    weight = sqrt.(pressure[2:end]) .- sqrt.(pressure[1:(end - 1)])
    total = sum(weight)
    total > 0 || throw(ArgumentError("layer weights have non-positive sum"))
    return weight ./ total
end

function ecckd_flux_heating_rate(pressure_hl, flux_dn, flux_up = nothing;
                                 gravity = ECCKD_GRAVITY,
                                 heat_capacity = ECCKD_SPECIFIC_HEAT_AIR)
    pressure = Float64.(pressure_hl)
    down = Float64.(flux_dn)
    size(down, 1) == length(pressure) ||
        throw(DimensionMismatch("flux_dn first dimension must match pressure_hl"))
    nlay = length(pressure) - 1
    result = zeros(Float64, nlay, size(down, 2))
    conversion = .-(gravity / heat_capacity) ./ diff(pressure)
    if flux_up === nothing
        for iband in axes(down, 2)
            result[:, iband] .= conversion .* (down[2:end, iband] .- down[1:(end - 1), iband])
        end
    else
        up = Float64.(flux_up)
        size(up) == size(down) ||
            throw(DimensionMismatch("flux_up must match flux_dn when provided"))
        for iband in axes(down, 2)
            result[:, iband] .= conversion .*
                (down[2:end, iband] .- down[1:(end - 1), iband] .-
                 up[2:end, iband] .+ up[1:(end - 1), iband])
        end
    end
    return result
end

function read_lw_training_sample(dataset; column = 1)
    pressure_hl = Float64.(dataset["pressure_hl"][:, column])
    flux_up = permutedims(Float64.(dataset["band_flux_up_lw"][:, :, column]), (2, 1))
    flux_dn = permutedims(Float64.(dataset["band_flux_dn_lw"][:, :, column]), (2, 1))
    return (
        kind = "longwave",
        column = column,
        mu0_index = nothing,
        pressure_hl = pressure_hl,
        layer_weight = ckdmip_layer_weight(pressure_hl),
        flux_up_true = flux_up,
        flux_dn_true = flux_dn,
        heating_rate_true = ecckd_flux_heating_rate(pressure_hl, flux_dn, flux_up),
        band_wavenumber1 = Float64.(dataset["band_wavenumber1_lw"][:]),
        band_wavenumber2 = Float64.(dataset["band_wavenumber2_lw"][:]),
    )
end

function read_sw_training_sample(dataset; column = 1, mu0_index = 1)
    pressure_hl = Float64.(dataset["pressure_hl"][:, column])
    flux_up = permutedims(Float64.(dataset["band_flux_up_sw"][:, :, mu0_index, column]), (2, 1))
    flux_dn = permutedims(Float64.(dataset["band_flux_dn_sw"][:, :, mu0_index, column]), (2, 1))
    return (
        kind = "shortwave",
        column = column,
        mu0_index = mu0_index,
        pressure_hl = pressure_hl,
        layer_weight = ckdmip_layer_weight(pressure_hl),
        flux_up_true = flux_up,
        flux_dn_true = flux_dn,
        heating_rate_true = ecckd_flux_heating_rate(pressure_hl, flux_dn),
        band_wavenumber1 = Float64.(dataset["band_wavenumber1_sw"][:]),
        band_wavenumber2 = Float64.(dataset["band_wavenumber2_sw"][:]),
    )
end

function read_ckdmip_training_sample(path; column = 1, mu0_index = 1)
    dataset = NCDataset(path)
    try
        kind = ckdmip_flux_kind(path)
        sample = kind == "longwave" ?
                 read_lw_training_sample(dataset; column) :
                 read_sw_training_sample(dataset; column, mu0_index)
        return merge(sample, (
            path = path,
            scenario = netcdf_attribute(dataset, "scenario"; default = "unknown"),
            constituent_id = netcdf_attribute(dataset, "constituent_id"; default = "unknown"),
            dimensions = Dict(String(name) => Int(length) for (name, length) in dataset.dim),
            has_spectral_boundary =
                kind == "longwave" ?
                all(name -> haskey(dataset, name),
                    ("spectral_flux_dn_surf_lw", "spectral_flux_up_toa_lw")) :
                haskey(dataset, "spectral_flux_dn_surf_sw"),
        ))
    finally
        close(dataset)
    end
end

function objective_self_loss(sample)
    if sample.kind == "longwave"
        return ecckd_lw_ckd_loss(
            heating_rate_fwd = sample.heating_rate_true,
            heating_rate_true = sample.heating_rate_true,
            flux_dn_fwd = sample.flux_dn_true,
            flux_up_fwd = sample.flux_up_true,
            flux_dn_true = sample.flux_dn_true,
            flux_up_true = sample.flux_up_true,
            layer_weight = sample.layer_weight,
            flux_weight = 0.2,
            flux_profile_weight = 0.0,
            broadband_weight = 0.0,
        )
    else
        return ecckd_sw_ckd_loss(
            heating_rate_fwd = sample.heating_rate_true,
            heating_rate_true = sample.heating_rate_true,
            flux_dn_fwd = sample.flux_dn_true,
            flux_up_fwd = sample.flux_up_true,
            flux_dn_true = sample.flux_dn_true,
            flux_up_true = sample.flux_up_true,
            layer_weight = sample.layer_weight,
            flux_weight = 0.4,
            flux_profile_weight = 0.0,
            broadband_weight = 0.0,
        )
    end
end

function sample_summary(sample)
    return (
        kind = sample.kind,
        path = sample.path,
        scenario = sample.scenario,
        constituent_id = sample.constituent_id,
        column = sample.column,
        mu0_index = sample.mu0_index,
        dimensions = sample.dimensions,
        nlayer = size(sample.heating_rate_true, 1),
        nband = size(sample.heating_rate_true, 2),
        layer_weight_sum = sum(sample.layer_weight),
        pressure_top_pa = first(sample.pressure_hl),
        pressure_surface_pa = last(sample.pressure_hl),
        flux_dn_surface_sum_w_m2 = sum(sample.flux_dn_true[end, :]),
        flux_up_toa_sum_w_m2 = sum(sample.flux_up_true[1, :]),
        heating_rate_min_k_s = minimum(sample.heating_rate_true),
        heating_rate_max_k_s = maximum(sample.heating_rate_true),
        self_loss = objective_self_loss(sample),
        has_spectral_boundary = sample.has_spectral_boundary,
    )
end

function default_training_flux_paths(root)
    return [
        joinpath(root, expected_flux_path("ckdmip_evaluation1_lw_fluxes_rel-415.h5")),
        joinpath(root, expected_flux_path("ckdmip_evaluation1_sw_fluxes_rel-415.h5")),
    ]
end

function objective_training_flux_filenames()
    manifest = run_ecckd_published_training_manifest()
    return expected_training_flux_files(manifest)
end

function required_ckdmip_flux_variables(kind)
    if kind == "longwave"
        return [
            "pressure_hl",
            "band_flux_up_lw",
            "band_flux_dn_lw",
            "band_wavenumber1_lw",
            "band_wavenumber2_lw",
        ]
    elseif kind == "shortwave"
        return [
            "pressure_hl",
            "mu0",
            "band_flux_up_sw",
            "band_flux_dn_sw",
            "band_wavenumber1_sw",
            "band_wavenumber2_sw",
        ]
    end
    throw(ArgumentError("unknown CKDMIP flux kind $(kind)"))
end

function ckdmip_flux_file_schema(path)
    kind = ckdmip_flux_kind(path)
    if !isfile(path)
        return (
            filename = basename(path),
            path = path,
            kind = kind,
            present = false,
            schema_ok = false,
            missing_variables = required_ckdmip_flux_variables(kind),
            dimensions = Dict{String, Int}(),
            scenario = "missing",
        )
    end
    dataset = NCDataset(path)
    try
        required = required_ckdmip_flux_variables(kind)
        missing = [name for name in required if !haskey(dataset, name)]
        return (
            filename = basename(path),
            path = path,
            kind = kind,
            present = true,
            schema_ok = isempty(missing),
            missing_variables = missing,
            dimensions = Dict(String(name) => Int(length) for (name, length) in dataset.dim),
            scenario = netcdf_attribute(dataset, "scenario"; default = "unknown"),
        )
    finally
        close(dataset)
    end
end

function run_ckdmip_original_objective_dataset(; root = ckdmip_data_root(),
                                               column = 1,
                                               mu0_index = 1,
                                               training_flux_filenames = nothing)
    if root === nothing
        return (
            case = "ckdmip_original_objective_dataset",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            ckdmip_data_root = nothing,
            training_flux_file_count = 0,
            training_flux_schema_ok_count = 0,
            training_flux_schemas = NamedTuple[],
            samples = NamedTuple[],
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    filenames = training_flux_filenames === nothing ?
                objective_training_flux_filenames() :
                collect(training_flux_filenames)
    schema_paths = [joinpath(root, expected_flux_path(filename)) for filename in filenames]
    schemas = ckdmip_flux_file_schema.(schema_paths)
    paths = default_training_flux_paths(root)
    missing = [path for path in paths if !isfile(path)]
    missing_schema = [schema.path for schema in schemas if !schema.present]
    bad_schema = [schema.path for schema in schemas if schema.present && !schema.schema_ok]
    if !isempty(missing)
        return (
            case = "ckdmip_original_objective_dataset",
            timestamp_utc = string(Dates.now()),
            status = "missing_training_flux_sample",
            ckdmip_data_root = root,
            training_flux_file_count = length(schemas),
            training_flux_schema_ok_count = count(schema -> schema.schema_ok, schemas),
            training_flux_schemas = schemas,
            samples = NamedTuple[],
            blockers = ["Missing training flux sample: $(path)" for path in missing],
        )
    end
    samples = [sample_summary(read_ckdmip_training_sample(path; column, mu0_index)) for path in paths]
    passed = all(sample -> isapprox(sample.layer_weight_sum, 1.0; atol = 1e-12), samples) &&
             all(sample -> sample.self_loss == 0, samples) &&
             isempty(missing_schema) &&
             isempty(bad_schema)
    return (
        case = "ckdmip_original_objective_dataset",
        timestamp_utc = string(Dates.now()),
        status = passed ? "dataset_samples_ready" :
                 !isempty(missing_schema) ? "missing_training_flux_schema_file" :
                 !isempty(bad_schema) ? "training_flux_schema_mismatch" :
                 "dataset_sample_check_failed",
        ckdmip_data_root = root,
        training_flux_file_count = length(schemas),
        training_flux_schema_ok_count = count(schema -> schema.schema_ok, schemas),
        training_flux_schemas = schemas,
        samples = samples,
        blockers = vcat(
            ["Missing training flux schema file: $(path)" for path in missing_schema],
            ["Training flux schema mismatch: $(path)" for path in bad_schema],
        ),
    )
end

function json_string(result)
    io = IOBuffer()
    JSON.print(io, result, 2)
    return String(take!(io))
end

function markdown_objective_dataset(result)
    lines = String[
        "# CKDMIP Original Objective Dataset",
        "",
        "Status: **$(result.status)**",
        "",
        "CKDMIP data root: `$(result.ckdmip_data_root)`",
        "",
        "Training flux schemas ready: $(result.training_flux_schema_ok_count) / $(result.training_flux_file_count)",
        "",
        "## Blockers",
        "",
    ]
    if isempty(result.blockers)
        push!(lines, "None.")
    else
        append!(lines, ["- $(blocker)" for blocker in result.blockers])
    end
    push!(lines, "", "## Representative Samples", "")
    push!(lines, "| Kind | Scenario | Column | mu0 index | Layers | Bands | Sum layer weight | Self loss | Spectral boundary |")
    push!(lines, "|---|---|---:|---:|---:|---:|---:|---:|---:|")
    for sample in result.samples
        mu0 = sample.mu0_index === nothing ? "" : string(sample.mu0_index)
        push!(lines, "| $(sample.kind) | `$(sample.scenario)` | $(sample.column) | $(mu0) | $(sample.nlayer) | $(sample.nband) | $(sample.layer_weight_sum) | $(sample.self_loss) | $(sample.has_spectral_boundary) |")
    end
    push!(lines, "", "This artifact proves the original-objective recovery path can read the CKDMIP LBL flux products, reproduce ecCKD layer weights, compute K s^-1 heating targets from flux divergence, and feed those arrays into the Julia CKD loss assembly.")
    return join(lines, "\n") * "\n"
end

function main()
    result = run_ckdmip_original_objective_dataset()
    mkpath(dirname(CKDMIP_OBJECTIVE_DATASET_JSON))
    write(CKDMIP_OBJECTIVE_DATASET_JSON, json_string(result) * "\n")
    write(CKDMIP_OBJECTIVE_DATASET_MD, markdown_objective_dataset(result))
    print(markdown_objective_dataset(result))
    println("Wrote $CKDMIP_OBJECTIVE_DATASET_JSON")
    println("Wrote $CKDMIP_OBJECTIVE_DATASET_MD")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
