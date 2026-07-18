using Dates
using Printf
using Statistics

include(joinpath(@__DIR__, "ecrad_reference_manifest.jl"))

const ECRAD_ROOT = joinpath(@__DIR__, "external", "ecrad")
const ECRAD_IFS = joinpath(ECRAD_ROOT, "test", "ifs")
const ECRAD_TC_PROPERTIES = joinpath(ECRAD_IFS, "radiative_properties_ecckd_tc.nc")

function require_ncdatasets()
    NCDATASETS === nothing &&
        error("NCDatasets is required. Run with `julia --project=test validation/materialize_ecrad_references.jl`.")
    return NCDATASETS
end

function pressure_layer_from_interfaces(p_interface)
    return 0.5 .* (p_interface[1:(end - 1), :] .+ p_interface[2:end, :])
end

function temperature_layer_from_interfaces(p_interface, t_interface)
    p_top = p_interface[1:(end - 1), :]
    p_bottom = p_interface[2:end, :]
    t_top = t_interface[1:(end - 1), :]
    t_bottom = t_interface[2:end, :]
    return (t_top .* p_top .+ t_bottom .* p_bottom) ./ (p_top .+ p_bottom)
end

function heating_rate_k_day(p_interface, lw_up, lw_down, sw_up, sw_down)
    gravity = 9.80665
    heat_capacity = 1004.0
    seconds_per_day = 86400.0
    nlayers = size(p_interface, 1) - 1
    ncolumns = size(p_interface, 2)
    heating = zeros(Float64, nlayers, ncolumns)
    net = lw_down .- lw_up .+ sw_down .- sw_up
    for j in 1:ncolumns, k in 1:nlayers
        Δp = p_interface[k + 1, j] - p_interface[k, j]
        heating[k, j] = seconds_per_day * gravity / heat_capacity *
            (net[k, j] - net[k + 1, j]) / Δp
    end
    return heating
end

function mean_surface_albedo(sw_albedo)
    ndims(sw_albedo) == 1 && return sw_albedo
    return vec(dropdims(mean(sw_albedo; dims = 1); dims = 1))
end

function copy_gpoint_matrix!(dataset, variable_name, values, dim_name = "shortwave_gpoint")
    if !haskey(dataset.dim, dim_name)
        NCDATASETS.defDim(dataset, dim_name, size(values, 1))
    elseif dataset.dim[dim_name] != size(values, 1)
        return false
    end
    if haskey(dataset, variable_name)
        size(dataset[variable_name], 1) == size(values, 1) || return false
        dataset[variable_name][:] = values
    else
        var = NCDATASETS.defVar(dataset, variable_name, Float64,
                                (dim_name, "column"))
        var[:] = values
    end
    return true
end

function copy_saved_shortwave_boundaries!(dataset, properties, columns)
    property_variables = String.(collect(keys(properties)))
    copied = String[]
    if "sw_albedo" in property_variables
        diffuse_albedo = Array(properties["sw_albedo"][:, columns])
        copy_gpoint_matrix!(dataset, "surface_albedo_spectral", diffuse_albedo) &&
            push!(copied, "surface_albedo_spectral")
    end
    if "sw_albedo_direct" in property_variables
        direct_albedo = Array(properties["sw_albedo_direct"][:, columns])
        copy_gpoint_matrix!(dataset, "surface_albedo_direct_gpoint", direct_albedo) &&
            push!(copied, "surface_albedo_direct_gpoint")
    end
    if "incoming_sw" in property_variables
        incoming_sw = Array(properties["incoming_sw"][:, columns])
        copy_gpoint_matrix!(dataset, "toa_shortwave_down_spectral", incoming_sw) &&
            push!(copied, "toa_shortwave_down_spectral")
    end
    return copied
end

function column_or_scalar(input, name, columns)
    values = Array(input[name])
    ndims(values) == 0 && return fill(Float64(values[]), length(columns))
    return values[columns]
end

function liquid_water_path(q_liquid, p_interface)
    gravity = 9.80665
    nlayers = size(q_liquid, 1)
    ncolumns = size(q_liquid, 2)
    path = zeros(Float64, nlayers, ncolumns)
    for j in 1:ncolumns, k in 1:nlayers
        path[k, j] = q_liquid[k, j] * (p_interface[k + 1, j] - p_interface[k, j]) / gravity
    end
    return path
end

function write_reference_case(output_path; input_path, output_reference_path,
                              columns, all_sky, clear_fluxes = false,
                              properties_path = ECRAD_TC_PROPERTIES)
    nc = require_ncdatasets()
    mkpath(dirname(output_path))
    nc.NCDataset(input_path) do input
        nc.NCDataset(output_reference_path) do reference
            p_interface = Array(input["pressure_hl"][:, columns])
            t_interface = Array(input["temperature_hl"][:, columns])
            suffix = clear_fluxes ? "_clear" : ""
            lw_up = Array(reference["flux_up_lw" * suffix][:, columns])
            lw_down = Array(reference["flux_dn_lw" * suffix][:, columns])
            sw_up = Array(reference["flux_up_sw" * suffix][:, columns])
            sw_down = Array(reference["flux_dn_sw" * suffix][:, columns])
            heating = heating_rate_k_day(p_interface, lw_up, lw_down, sw_up, sw_down)
            ref_variables = String.(collect(keys(reference)))
            spectral_suffix = clear_fluxes ? "_clear" : ""
            has_lw_surface_spectral =
                "spectral_flux_up_lw" * spectral_suffix in ref_variables
            has_sw_surface_spectral =
                all(name in ref_variables for name in
                    ("spectral_flux_up_sw" * spectral_suffix,
                     "spectral_flux_dn_sw" * spectral_suffix))

            nc.NCDataset(output_path, "c") do dataset
                nc.defDim(dataset, "interface", size(p_interface, 1))
                nc.defDim(dataset, "layer", size(p_interface, 1) - 1)
                nc.defDim(dataset, "column", length(columns))

                dataset.attrib["source"] = "ECMWF ecRad test/ifs reference data"
                dataset.attrib["source_input"] = input_path
                dataset.attrib["source_output"] = output_reference_path
                dataset.attrib["source_flux_scope"] = clear_fluxes ? "clear" : "total"
                dataset.attrib["materialized_at"] = string(Dates.now())
                dataset.attrib["all_sky"] = string(all_sky)

                column = nc.defVar(dataset, "column", Int, ("column",))
                column[:] = collect(columns)

                variables = (
                    pressure_layer = pressure_layer_from_interfaces(p_interface),
                    pressure_interface = p_interface,
                    temperature_layer = temperature_layer_from_interfaces(p_interface, t_interface),
                    temperature_interface = t_interface,
                    h2o = Array(input["q"][:, columns]),
                    o3 = Array(input["o3_mmr"][:, columns]),
                    co2 = Array(input["co2_vmr"][:, columns]),
                    ch4 = Array(input["ch4_vmr"][:, columns]),
                    n2o = Array(input["n2o_vmr"][:, columns]),
                    cfc11 = Array(input["cfc11_vmr"][:, columns]),
                    cfc12 = Array(input["cfc12_vmr"][:, columns]),
                    cos_solar_zenith_angle = column_or_scalar(input, "cos_solar_zenith_angle", columns),
                    solar_irradiance = column_or_scalar(input, "solar_irradiance", columns),
                    surface_temperature = Array(input["skin_temperature"][columns]),
                    surface_albedo = mean_surface_albedo(Array(input["sw_albedo"][:, columns])),
                    lw_up = lw_up,
                    lw_down = lw_down,
                    sw_up = sw_up,
                    sw_down = sw_down,
                    heating_rate = heating,
                )

                for (name, values) in pairs(variables)
                    dims = ndims(values) == 1 ? ("column",) :
                           size(values, 1) == size(p_interface, 1) ? ("interface", "column") :
                           ("layer", "column")
                    var = nc.defVar(dataset, String(name), Float64, dims)
                    var[:] = values
                end

                if has_lw_surface_spectral
                    spectral_lw = Array(reference["spectral_flux_up_lw" * spectral_suffix][:, end, columns])
                    nc.defDim(dataset, "longwave_gpoint", size(spectral_lw, 1))
                    var = nc.defVar(dataset, "surface_longwave_up_spectral", Float64,
                                    ("longwave_gpoint", "column"))
                    var[:] = spectral_lw
                end

                if has_sw_surface_spectral
                    spectral_up = Array(reference["spectral_flux_up_sw" * spectral_suffix][:, end, columns])
                    spectral_down = Array(reference["spectral_flux_dn_sw" * spectral_suffix][:, end, columns])
                    spectral_albedo = similar(spectral_up)
                    for index in eachindex(spectral_up, spectral_down)
                        spectral_albedo[index] = spectral_down[index] <= 0 ?
                            0.0 : clamp(spectral_up[index] / spectral_down[index], 0.0, 1.0)
                    end
                    nc.defDim(dataset, "shortwave_gpoint", size(spectral_albedo, 1))
                    var = nc.defVar(dataset, "surface_albedo_spectral", Float64,
                                    ("shortwave_gpoint", "column"))
                    var[:] = spectral_albedo
                    toa_down = Array(reference["spectral_flux_dn_sw" * spectral_suffix][:, 1, columns])
                    var = nc.defVar(dataset, "toa_shortwave_down_spectral", Float64,
                                    ("shortwave_gpoint", "column"))
                    var[:] = toa_down
                end

                if "sw_albedo_direct" in String.(collect(keys(input)))
                    direct_albedo = Array(input["sw_albedo_direct"][:, columns])
                    if !haskey(dataset.dim, "shortwave_surface_band")
                        nc.defDim(dataset, "shortwave_surface_band", size(direct_albedo, 1))
                    end
                    var = nc.defVar(dataset, "surface_albedo_direct_spectral", Float64,
                                    ("shortwave_surface_band", "column"))
                    var[:] = direct_albedo
                end

                if all_sky && isfile(properties_path)
                    nc.NCDataset(properties_path) do properties
                        property_variables = String.(collect(keys(properties)))
                        copied_boundaries =
                            copy_saved_shortwave_boundaries!(dataset, properties, columns)
                        dataset.attrib["saved_shortwave_boundary_source"] = properties_path
                        dataset.attrib["saved_shortwave_boundaries"] =
                            join(copied_boundaries, ",")
                        if "q_sat_liquid" in property_variables && !haskey(dataset, "h2o_sat_liq")
                            saturation = Array(properties["q_sat_liquid"][:, columns])
                            var = nc.defVar(dataset, "h2o_sat_liq", Float64,
                                            ("layer", "column"))
                            var[:] = saturation
                        end
                    end
                end

                if all_sky
                    lw_up_clear = nc.defVar(dataset, "lw_up_clear", Float64, ("interface", "column"))
                    lw_down_clear = nc.defVar(dataset, "lw_down_clear", Float64, ("interface", "column"))
                    sw_up_clear = nc.defVar(dataset, "sw_up_clear", Float64, ("interface", "column"))
                    sw_down_clear = nc.defVar(dataset, "sw_down_clear", Float64, ("interface", "column"))
                    heating_clear = nc.defVar(dataset, "heating_rate_clear", Float64,
                                               ("layer", "column"))
                    ref_variables = String.(collect(keys(reference)))
                    if all(name in ref_variables for name in
                           ("flux_up_lw_clear", "flux_dn_lw_clear",
                            "flux_up_sw_clear", "flux_dn_sw_clear"))
                        clear_lw_up = Array(reference["flux_up_lw_clear"][:, columns])
                        clear_lw_down = Array(reference["flux_dn_lw_clear"][:, columns])
                        clear_sw_up = Array(reference["flux_up_sw_clear"][:, columns])
                        clear_sw_down = Array(reference["flux_dn_sw_clear"][:, columns])
                        lw_up_clear[:] = clear_lw_up
                        lw_down_clear[:] = clear_lw_down
                        sw_up_clear[:] = clear_sw_up
                        sw_down_clear[:] = clear_sw_down
                        heating_clear[:] = heating_rate_k_day(p_interface, clear_lw_up,
                                                              clear_lw_down, clear_sw_up,
                                                              clear_sw_down)
                    end

                    cloud_fraction = nc.defVar(dataset, "cloud_fraction", Float64, ("layer", "column"))
                    liquid = nc.defVar(dataset, "liquid_water_path", Float64, ("layer", "column"))
                    ice = nc.defVar(dataset, "ice_water_path", Float64, ("layer", "column"))
                    re_liquid = nc.defVar(dataset, "re_liquid", Float64, ("layer", "column"))
                    re_ice = nc.defVar(dataset, "re_ice", Float64, ("layer", "column"))
                    inv_cloud_effective_size = nc.defVar(dataset, "inv_cloud_effective_size",
                                                          Float64, ("layer", "column"))
                    cloud_fraction[:] = Array(input["cloud_fraction"][:, columns])
                    liquid[:] = liquid_water_path(Array(input["q_liquid"][:, columns]), p_interface)
                    ice[:] = liquid_water_path(Array(input["q_ice"][:, columns]), p_interface)
                    re_liquid[:] = Array(input["re_liquid"][:, columns])
                    re_ice[:] = Array(input["re_ice"][:, columns])
                    inv_cloud_effective_size[:] =
                        Array(input["inv_cloud_effective_size"][:, columns])
                    if "fractional_std" in String.(collect(keys(input)))
                        fractional_std = nc.defVar(dataset, "fractional_std", Float64,
                                                   ("layer", "column"))
                        fractional_std[:] = Array(input["fractional_std"][:, columns])
                    end
                    if "overlap_param" in String.(collect(keys(input)))
                        nc.defDim(dataset, "overlap_interface", size(p_interface, 1) - 2)
                        overlap = nc.defVar(dataset, "overlap_param", Float64,
                                            ("overlap_interface", "column"))
                        overlap[:] = Array(input["overlap_param"][:, columns])
                    end
                    if "aerosol_mmr" in String.(collect(keys(input)))
                        aerosol_mmr = Array(input["aerosol_mmr"][:, :, columns])
                        nc.defDim(dataset, "aerosol_type", size(aerosol_mmr, 2))
                        aerosol = nc.defVar(dataset, "aerosol_mmr", Float64,
                                            ("layer", "aerosol_type", "column"))
                        aerosol[:] = aerosol_mmr
                    end
                end
            end
        end
    end
    return output_path
end

function materialize_references()
    input_path = joinpath(ECRAD_IFS, "ecrad_meridian.nc")
    clear_output = joinpath(ECRAD_IFS, "ecrad_meridian_cloudless_out_REFERENCE.nc")
    all_sky_output = joinpath(ECRAD_IFS, "ecrad_meridian_default_out_REFERENCE.nc")
    ecckd_all_sky_tc_output = joinpath(ECRAD_IFS, "ecrad_meridian_ecckd_tc_out_REFERENCE.nc")
    ecckd_cloudless_noaer_output = joinpath(ECRAD_IFS, "ecrad_meridian_ecckd_cloudless_noaer_out.nc")
    ecckd_32x64_cloudless_noaer_output =
        joinpath(ECRAD_IFS, "ecrad_meridian_ecckd_32x64_cloudless_noaer_out.nc")
    ecckd_32x96_cloudless_noaer_output =
        joinpath(ECRAD_IFS, "ecrad_meridian_ecckd_32x96_cloudless_noaer_out.nc")
    ecckd_64x32_cloudless_noaer_output =
        joinpath(ECRAD_IFS, "ecrad_meridian_ecckd_64x32_cloudless_noaer_out.nc")
    ecckd_64x64_cloudless_noaer_output =
        joinpath(ECRAD_IFS, "ecrad_meridian_ecckd_64x64_cloudless_noaer_out.nc")
    ecckd_64x96_cloudless_noaer_output =
        joinpath(ECRAD_IFS, "ecrad_meridian_ecckd_64x96_cloudless_noaer_out.nc")
    matched_all_sky_outputs = (
        (
            output_reference_path =
                joinpath(ECRAD_IFS, "ecrad_meridian_ecckd_32x64_all_sky_out.nc"),
            output_path = joinpath(validation_reference_dir(), "ecrad",
                                   "ecckd_32x64_all_sky_tropical_column.nc"),
            properties_path = joinpath(ECRAD_IFS, "radiative_properties_ecckd_32x64.nc"),
        ),
        (
            output_reference_path =
                joinpath(ECRAD_IFS, "ecrad_meridian_ecckd_32x96_all_sky_out.nc"),
            output_path = joinpath(validation_reference_dir(), "ecrad",
                                   "ecckd_32x96_all_sky_tropical_column.nc"),
            properties_path = joinpath(ECRAD_IFS, "radiative_properties_ecckd_32x96.nc"),
        ),
        (
            output_reference_path =
                joinpath(ECRAD_IFS, "ecrad_meridian_ecckd_64x32_all_sky_out.nc"),
            output_path = joinpath(validation_reference_dir(), "ecrad",
                                   "ecckd_64x32_all_sky_tropical_column.nc"),
            properties_path = joinpath(ECRAD_IFS, "radiative_properties_ecckd_64x32.nc"),
        ),
        (
            output_reference_path =
                joinpath(ECRAD_IFS, "ecrad_meridian_ecckd_64x64_all_sky_out.nc"),
            output_path = joinpath(validation_reference_dir(), "ecrad",
                                   "ecckd_64x64_all_sky_tropical_column.nc"),
            properties_path = joinpath(ECRAD_IFS, "radiative_properties_ecckd_64x64.nc"),
        ),
        (
            output_reference_path =
                joinpath(ECRAD_IFS, "ecrad_meridian_ecckd_64x96_all_sky_out.nc"),
            output_path = joinpath(validation_reference_dir(), "ecrad",
                                   "ecckd_64x96_all_sky_tropical_column.nc"),
            properties_path = joinpath(ECRAD_IFS, "radiative_properties_ecckd_64x96.nc"),
        ),
    )
    tropical_columns = 12:21
    rcemip_style_columns = 1:32

    outputs = String[]
    push!(outputs, write_reference_case(
        joinpath(validation_reference_dir(), "ecrad", "clear_sky_tropical_column.nc");
        input_path,
        output_reference_path = clear_output,
        columns = tropical_columns,
        all_sky = false,
    ))
    push!(outputs, write_reference_case(
        joinpath(validation_reference_dir(), "ecrad", "ecckd_clear_sky_tropical_column.nc");
        input_path,
        output_reference_path = ecckd_cloudless_noaer_output,
        columns = tropical_columns,
        all_sky = false,
    ))
    push!(outputs, write_reference_case(
        joinpath(validation_reference_dir(), "ecrad", "all_sky_tropical_column.nc");
        input_path,
        output_reference_path = all_sky_output,
        columns = tropical_columns,
        all_sky = true,
    ))
    push!(outputs, write_reference_case(
        joinpath(validation_reference_dir(), "ecrad", "ecckd_all_sky_tropical_column.nc");
        input_path,
        output_reference_path = ecckd_all_sky_tc_output,
        columns = tropical_columns,
        all_sky = true,
    ))
    for case in matched_all_sky_outputs
        if isfile(case.output_reference_path)
            push!(outputs, write_reference_case(
                case.output_path;
                input_path,
                output_reference_path = case.output_reference_path,
                columns = tropical_columns,
                all_sky = true,
                properties_path = case.properties_path,
            ))
        end
    end
    push!(outputs, write_reference_case(
        joinpath(validation_reference_dir(), "ecrad", "rcemip_style_column_subset.nc");
        input_path,
        output_reference_path = clear_output,
        columns = rcemip_style_columns,
        all_sky = false,
    ))
    push!(outputs, write_reference_case(
        joinpath(validation_reference_dir(), "ecrad", "ecckd_rcemip_style_column_subset.nc");
        input_path,
        output_reference_path = ecckd_cloudless_noaer_output,
        columns = rcemip_style_columns,
        all_sky = false,
    ))
    if isfile(ecckd_32x64_cloudless_noaer_output)
        push!(outputs, write_reference_case(
            joinpath(validation_reference_dir(), "ecrad",
                     "ecckd_32x64_clear_sky_tropical_column.nc");
            input_path,
            output_reference_path = ecckd_32x64_cloudless_noaer_output,
            columns = tropical_columns,
            all_sky = false,
        ))
        push!(outputs, write_reference_case(
            joinpath(validation_reference_dir(), "ecrad",
                     "ecckd_32x64_rcemip_style_column_subset.nc");
            input_path,
            output_reference_path = ecckd_32x64_cloudless_noaer_output,
            columns = rcemip_style_columns,
            all_sky = false,
        ))
    end
    if isfile(ecckd_32x96_cloudless_noaer_output)
        push!(outputs, write_reference_case(
            joinpath(validation_reference_dir(), "ecrad",
                     "ecckd_32x96_clear_sky_tropical_column.nc");
            input_path,
            output_reference_path = ecckd_32x96_cloudless_noaer_output,
            columns = tropical_columns,
            all_sky = false,
        ))
        push!(outputs, write_reference_case(
            joinpath(validation_reference_dir(), "ecrad",
                     "ecckd_32x96_rcemip_style_column_subset.nc");
            input_path,
            output_reference_path = ecckd_32x96_cloudless_noaer_output,
            columns = rcemip_style_columns,
            all_sky = false,
        ))
    end
    if isfile(ecckd_64x32_cloudless_noaer_output)
        push!(outputs, write_reference_case(
            joinpath(validation_reference_dir(), "ecrad",
                     "ecckd_64x32_clear_sky_tropical_column.nc");
            input_path,
            output_reference_path = ecckd_64x32_cloudless_noaer_output,
            columns = tropical_columns,
            all_sky = false,
        ))
        push!(outputs, write_reference_case(
            joinpath(validation_reference_dir(), "ecrad",
                     "ecckd_64x32_rcemip_style_column_subset.nc");
            input_path,
            output_reference_path = ecckd_64x32_cloudless_noaer_output,
            columns = rcemip_style_columns,
            all_sky = false,
        ))
    end
    if isfile(ecckd_64x64_cloudless_noaer_output)
        push!(outputs, write_reference_case(
            joinpath(validation_reference_dir(), "ecrad",
                     "ecckd_64x64_clear_sky_tropical_column.nc");
            input_path,
            output_reference_path = ecckd_64x64_cloudless_noaer_output,
            columns = tropical_columns,
            all_sky = false,
        ))
        push!(outputs, write_reference_case(
            joinpath(validation_reference_dir(), "ecrad",
                     "ecckd_64x64_rcemip_style_column_subset.nc");
            input_path,
            output_reference_path = ecckd_64x64_cloudless_noaer_output,
            columns = rcemip_style_columns,
            all_sky = false,
        ))
    end
    if isfile(ecckd_64x96_cloudless_noaer_output)
        push!(outputs, write_reference_case(
            joinpath(validation_reference_dir(), "ecrad",
                     "ecckd_64x96_clear_sky_tropical_column.nc");
            input_path,
            output_reference_path = ecckd_64x96_cloudless_noaer_output,
            columns = tropical_columns,
            all_sky = false,
        ))
        push!(outputs, write_reference_case(
            joinpath(validation_reference_dir(), "ecrad",
                     "ecckd_64x96_rcemip_style_column_subset.nc");
            input_path,
            output_reference_path = ecckd_64x96_cloudless_noaer_output,
            columns = rcemip_style_columns,
            all_sky = false,
        ))
    end
    return outputs
end

function materialize_ecrad_references_main()
    outputs = materialize_references()
    println("# Materialized ecRad References")
    for output in outputs
        println("- ", output)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    materialize_ecrad_references_main()
end
