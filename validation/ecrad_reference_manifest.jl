include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

const ABR_ROOT = normpath(joinpath(@__DIR__, ".."))

const NCDATASETS = try
    Base.require(Base.PkgId(Base.UUID("85f8d34a-cbdd-5861-8df4-14fed0d494ab"), "NCDatasets"))
catch
    nothing
end

const REQUIRED_CASES = (
    (
        case = "clear_sky_tropical_column",
        path = "validation/reference/ecrad/clear_sky_tropical_column.nc",
        description = "Single-column clear-sky tropical profile for solver and gas-optics smoke validation.",
        required_variables = (
            "pressure_layer",
            "pressure_interface",
            "temperature_layer",
            "temperature_interface",
            "h2o",
            "co2",
            "surface_temperature",
            "surface_albedo",
            "lw_up",
            "lw_down",
            "sw_up",
            "sw_down",
            "heating_rate",
        ),
    ),
    (
        case = "all_sky_tropical_column",
        path = "validation/reference/ecrad/all_sky_tropical_column.nc",
        description = "Single-column all-sky tropical profile with cloud optical properties for the first cloudy ecRad comparison.",
        required_variables = (
            "pressure_layer",
            "pressure_interface",
            "temperature_layer",
            "temperature_interface",
            "h2o",
            "co2",
            "cloud_fraction",
            "liquid_water_path",
            "ice_water_path",
            "re_liquid",
            "re_ice",
            "inv_cloud_effective_size",
            "fractional_std",
            "overlap_param",
            "aerosol_mmr",
            "lw_up",
            "lw_down",
            "sw_up",
            "sw_down",
            "heating_rate",
            "lw_up_clear",
            "lw_down_clear",
            "sw_up_clear",
            "sw_down_clear",
            "heating_rate_clear",
        ),
    ),
    (
        case = "ecckd_clear_sky_tropical_column",
        path = "validation/reference/ecrad/ecckd_clear_sky_tropical_column.nc",
        description = "ecRad ecCKD cloudless/no-aerosol tropical profile for the first hard gas-optics and solver agreement gate.",
        required_variables = (
            "pressure_layer",
            "pressure_interface",
            "temperature_layer",
            "temperature_interface",
            "h2o",
            "o3",
            "co2",
            "ch4",
            "n2o",
            "cfc11",
            "cfc12",
            "surface_temperature",
            "surface_albedo",
            "lw_up",
            "lw_down",
            "sw_up",
            "sw_down",
            "heating_rate",
        ),
    ),
    (
        case = "ecckd_all_sky_tropical_column",
        path = "validation/reference/ecrad/ecckd_all_sky_tropical_column.nc",
        description = "ecRad ecCKD Tripleclouds all-sky tropical profile for the current IFS cloud/aerosol/scattering/overlap solver gate.",
        required_variables = (
            "pressure_layer",
            "pressure_interface",
            "temperature_layer",
            "temperature_interface",
            "h2o",
            "o3",
            "co2",
            "ch4",
            "n2o",
            "cfc11",
            "cfc12",
            "cloud_fraction",
            "liquid_water_path",
            "ice_water_path",
            "re_liquid",
            "re_ice",
            "inv_cloud_effective_size",
            "fractional_std",
            "overlap_param",
            "aerosol_mmr",
            "lw_up",
            "lw_down",
            "sw_up",
            "sw_down",
            "heating_rate",
            "lw_up_clear",
            "lw_down_clear",
            "sw_up_clear",
            "sw_down_clear",
            "heating_rate_clear",
        ),
    ),
    (
        case = "rcemip_style_column_subset",
        path = "validation/reference/ecrad/rcemip_style_column_subset.nc",
        description = "Non-spinup RCEMIP-style selected-column reference subset for Breeze/RRTMGP comparison accuracy checks.",
        required_variables = (
            "column",
            "pressure_layer",
            "pressure_interface",
            "temperature_layer",
            "temperature_interface",
            "h2o",
            "co2",
            "surface_temperature",
            "surface_albedo",
            "lw_up",
            "lw_down",
            "sw_up",
            "sw_down",
            "heating_rate",
        ),
    ),
    (
        case = "ecckd_rcemip_style_column_subset",
        path = "validation/reference/ecrad/ecckd_rcemip_style_column_subset.nc",
        description = "ecRad ecCKD cloudless/no-aerosol RCEMIP-style selected-column subset for the first hard realistic-problem gate.",
        required_variables = (
            "column",
            "pressure_layer",
            "pressure_interface",
            "temperature_layer",
            "temperature_interface",
            "h2o",
            "o3",
            "co2",
            "ch4",
            "n2o",
            "cfc11",
            "cfc12",
            "surface_temperature",
            "surface_albedo",
            "lw_up",
            "lw_down",
            "sw_up",
            "sw_down",
            "heating_rate",
        ),
    ),
)

const ACCEPTANCE_THRESHOLDS = (
    flux_rmse_w_m2 = 1.0,
    flux_max_abs_w_m2 = 5.0,
    heating_rate_rmse_k_day = 0.05,
    heating_rate_max_abs_k_day = 0.5,
    toa_forcing_abs_error_w_m2 = 0.3,
    surface_forcing_abs_error_w_m2 = 0.3,
)

reference_path(path) = isabspath(path) ? path : joinpath(ABR_ROOT, path)

function netcdf_variables(path)
    NCDATASETS === nothing && return (nothing, "NCDatasets not available")
    dataset = nothing
    try
        dataset = NCDATASETS.NCDataset(reference_path(path))
        return (String.(collect(keys(dataset))), nothing)
    catch err
        return (nothing, sprint(showerror, err))
    finally
        dataset !== nothing && close(dataset)
    end
end

function case_status(case)
    exists = isfile(reference_path(case.path))
    variables, schema_error = exists ? netcdf_variables(case.path) : (nothing, nothing)
    missing_variables = variables === nothing ? collect(case.required_variables) :
        [name for name in case.required_variables if !(name in variables)]
    schema_valid = exists && variables !== nothing && isempty(missing_variables)
    status = !exists ? "missing" :
        schema_valid ? "present_schema_valid" :
        "present_schema_invalid"

    return (
        case = case.case,
        path = case.path,
        description = case.description,
        present = exists,
        schema_checked = exists && variables !== nothing,
        schema_valid = schema_valid,
        required_variables = collect(case.required_variables),
        present_variables = variables === nothing ? String[] : variables,
        missing_variables = missing_variables,
        schema_error = schema_error,
        status = status,
    )
end

function json_value(value)
    if value === nothing
        return "null"
    elseif value isa AbstractString
        return "\"" * replace(value, "\"" => "\\\"") * "\""
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value isa NamedTuple
        return json_object(value)
    elseif value isa AbstractVector || value isa Tuple
        return "[" * join(json_value.(value), ", ") * "]"
    else
        return string(value)
    end
end

function json_object(result)
    names = propertynames(result)
    lines = ["{"]
    for (i, name) in enumerate(names)
        comma = i == length(names) ? "" : ","
        push!(lines, "  \"$(name)\": $(json_value(getproperty(result, name)))$(comma)")
    end
    push!(lines, "}")
    return join(lines, "\n")
end

function markdown_report(result)
    lines = String[
        "# ecRad Reference Manifest",
        "",
        "Status: **$(result.status)**",
        "",
        "This report defines the first required external ecRad/ecCKD reference artifacts. It does not run ecRad and does not validate accuracy by itself.",
        "",
        "| Case | Status | Missing variables | Path |",
        "|---|---|---:|---|",
    ]
    for case in result.cases
        push!(lines, "| $(case.case) | $(case.status) | $(length(case.missing_variables)) | `$(case.path)` |")
    end
    append!(lines, [
        "",
        "## Initial Hard Thresholds",
        "",
        "| Metric | Threshold |",
        "|---|---:|",
        "| Flux RMSE | $(@sprintf("%.12g", result.acceptance_thresholds.flux_rmse_w_m2)) W m^-2 |",
        "| Flux max abs | $(@sprintf("%.12g", result.acceptance_thresholds.flux_max_abs_w_m2)) W m^-2 |",
        "| Heating-rate RMSE | $(@sprintf("%.12g", result.acceptance_thresholds.heating_rate_rmse_k_day)) K day^-1 |",
        "| Heating-rate max abs | $(@sprintf("%.12g", result.acceptance_thresholds.heating_rate_max_abs_k_day)) K day^-1 |",
        "| TOA forcing abs error | $(@sprintf("%.12g", result.acceptance_thresholds.toa_forcing_abs_error_w_m2)) W m^-2 |",
        "| Surface forcing abs error | $(@sprintf("%.12g", result.acceptance_thresholds.surface_forcing_abs_error_w_m2)) W m^-2 |",
        "",
        "Reference file instructions: `$(result.reference_readme)`",
        "",
        "Missing reference files or invalid schemas block final ecRad/ecCKD validation and reduced-model acceptance.",
    ])
    return join(lines, "\n") * "\n"
end

function main()
    cases = [case_status(case) for case in REQUIRED_CASES]
    missing = count(case -> !case.present, cases)
    invalid = count(case -> case.present && !case.schema_valid, cases)
    result = (
        case = "ecrad_reference_manifest",
        date = string(Dates.now()),
        status = missing > 0 ? "missing_references" :
                 invalid > 0 ? "invalid_reference_schema" :
                 "references_present_schema_valid",
        reference_readme = "validation/reference/ecrad/README.md",
        missing_reference_count = missing,
        invalid_schema_count = invalid,
        schema_checker = NCDATASETS === nothing ? "unavailable" : "NCDatasets",
        acceptance_thresholds = ACCEPTANCE_THRESHOLDS,
        cases = cases,
    )

    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "ecrad_reference_manifest.json")
    md_path = joinpath(results_dir, "ecrad_reference_manifest.md")
    write(json_path, json_object(result))
    write(md_path, markdown_report(result))

    print(markdown_report(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
