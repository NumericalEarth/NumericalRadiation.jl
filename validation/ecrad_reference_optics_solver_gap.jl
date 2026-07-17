include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf
using Statistics

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))

using NumericalRadiation
using NCDatasets

const ALL_SKY_REFERENCE = "validation/reference/ecrad/ecckd_all_sky_tropical_column.nc"
const ECRAD_ALL_SKY_PROPERTIES =
    "validation/external/ecrad/test/ifs/radiative_properties_ecckd_tc.nc"
const ECRAD_ALL_SKY_OUTPUT =
    "validation/external/ecrad/test/ifs/ecrad_meridian_ecckd_tc_out_REFERENCE.nc"
const REFERENCE_OPTICS_OUTPUT_BASENAME = "ecrad_reference_optics_solver_gap"

function rmse(candidate, reference)
    return sqrt(mean(abs2, vec(candidate .- reference)))
end

function max_abs_error(candidate, reference)
    return maximum(abs, vec(candidate .- reference))
end

function mean_bias(candidate, reference)
    return mean(vec(candidate .- reference))
end

function sw_optics_from_total(total_od, ssa, asymmetry, weights)
    scattering = clamp.(ssa, 0.0, 1.0) .* max.(total_od, 0.0)
    absorption = max.(total_od .- scattering, 0.0)
    return ShortwaveOpticalProperties(absorption;
                                      scattering_optical_depth = scattering,
                                      scattering_asymmetry = asymmetry,
                                      weights = weights)
end

function cloudy_optics_from_reference(clear_total, clear_ssa, clear_asymmetry,
                                      cloud_total, cloud_ssa, cloud_asymmetry,
                                      weights)
    clear_scattering = clamp.(clear_ssa, 0.0, 1.0) .* max.(clear_total, 0.0)
    clear_absorption = max.(clear_total .- clear_scattering, 0.0)
    cloud_scattering = clamp.(cloud_ssa, 0.0, 1.0) .* max.(cloud_total, 0.0)
    cloud_absorption = max.(cloud_total .- cloud_scattering, 0.0)
    total_scattering = clear_scattering .+ cloud_scattering
    asymmetry = similar(total_scattering)
    for index in eachindex(asymmetry)
        asymmetry[index] = total_scattering[index] == 0 ? 0.0 :
            (clear_scattering[index] * clear_asymmetry[index] +
             cloud_scattering[index] * cloud_asymmetry[index]) /
            total_scattering[index]
    end
    return ShortwaveOpticalProperties(clear_absorption .+ cloud_absorption;
                                      scattering_optical_depth = total_scattering,
                                      scattering_asymmetry = asymmetry,
                                      weights = weights)
end

function flux_arrays(ninterfaces, ncolumns)
    return RadiativeFluxes(longwave_up = zeros(ninterfaces, ncolumns),
                           longwave_down = zeros(ninterfaces, ncolumns),
                           shortwave_up = zeros(ninterfaces, ncolumns),
                           shortwave_down = zeros(ninterfaces, ncolumns))
end

function column_fluxes(mode, properties, reference, original_column, local_column;
                       inhomogeneity_overlap_exponent = 2.0)
    nlayers = size(reference["pressure_layer"], 1)
    ng = size(properties["od_sw"], 1)
    incoming_sw = Array(properties["incoming_sw"][:, original_column])
    incoming_total = sum(incoming_sw)
    weights = incoming_total > 0 ? incoming_sw ./ incoming_total :
        fill(inv(Float64(ng)), ng)
    clear_total = Array(properties["od_sw"][:, :, original_column])
    clear_ssa = Array(properties["ssa_sw"][:, :, original_column])
    clear_asymmetry = Array(properties["asymmetry_sw"][:, :, original_column])
    cloud_total = Array(properties["od_sw_cloud"][:, :, original_column])
    cloud_ssa = Array(properties["ssa_sw_cloud"][:, :, original_column])
    cloud_asymmetry = Array(properties["asymmetry_sw_cloud"][:, :, original_column])
    cloud_fraction = Array(reference["cloud_fraction"][:, local_column])
    fractional_std = Array(reference["fractional_std"][:, local_column])
    overlap_param = Array(reference["overlap_param"][:, local_column])
    μ0 = Float64(reference["cos_solar_zenith_angle"][local_column])

    clear = sw_optics_from_total(clear_total, clear_ssa, clear_asymmetry, weights)
    cloudy = cloudy_optics_from_reference(clear_total, clear_ssa, clear_asymmetry,
                                          cloud_total, cloud_ssa, cloud_asymmetry,
                                          weights)
    atmosphere = (; geometry = (; cos_zenith = μ0))
    boundary = ShortwaveBoundaryConditions(
        toa_shortwave_down = Float64(reference["sw_down"][1, local_column]),
        surface_albedo = Array(properties["sw_albedo"][:, original_column]),
        surface_albedo_direct = Array(properties["sw_albedo_direct"][:, original_column]),
    )
    fluxes = RadiativeFluxes(longwave_up = zeros(nlayers + 1),
                             longwave_down = zeros(nlayers + 1),
                             shortwave_up = zeros(nlayers + 1),
                             shortwave_down = zeros(nlayers + 1))

    if mode == :clear
        radiative_fluxes!(fluxes, CloudlessShortwave(), clear, atmosphere, boundary)
    elseif mode == :grid_mean
        grid_total = clear_total .+ cloud_fraction' .* cloud_total
        grid_scattering =
            clear_ssa .* clear_total .+ cloud_fraction' .* cloud_ssa .* cloud_total
        grid_ssa = similar(grid_total)
        grid_asymmetry = similar(grid_total)
        for index in CartesianIndices(grid_total)
            layer = index[2]
            grid_ssa[index] = grid_total[index] == 0 ? 0.0 :
                grid_scattering[index] / grid_total[index]
            grid_asymmetry[index] =
                grid_scattering[index] == 0 ? 0.0 :
                (clear_ssa[index] * clear_total[index] * clear_asymmetry[index] +
                 cloud_fraction[layer] * cloud_ssa[index] * cloud_total[index] *
                 cloud_asymmetry[index]) / grid_scattering[index]
        end
        grid = sw_optics_from_total(grid_total, grid_ssa, grid_asymmetry, weights)
        radiative_fluxes!(fluxes, CloudlessShortwave(), grid, atmosphere, boundary)
    else
        overlap_optics = ShortwaveCloudOverlapOpticalProperties(
            clear,
            cloudy,
            cloud_fraction;
            overlap_parameter = overlap_param,
            fractional_std = fractional_std,
        )
        radiative_fluxes!(
            fluxes,
            CloudOverlapShortwave(
                overlap = mode,
                inhomogeneity_overlap_exponent = inhomogeneity_overlap_exponent,
            ),
            overlap_optics,
            atmosphere,
            boundary,
        )
    end
    return fluxes.shortwave_up, fluxes.shortwave_down
end

function clear_direct_profile(properties, reference, original_column, local_column)
    nlayers = size(reference["pressure_layer"], 1)
    μ0 = Float64(reference["cos_solar_zenith_angle"][local_column])
    incoming_sw = Array(properties["incoming_sw"][:, original_column])
    od = Array(properties["od_sw"][:, :, original_column])
    ssa = Array(properties["ssa_sw"][:, :, original_column])
    asymmetry = Array(properties["asymmetry_sw"][:, :, original_column])
    ng = size(od, 1)
    direct = copy(incoming_sw)
    profile = zeros(Float64, nlayers + 1)
    profile[1] = μ0 * sum(direct)
    for k in 1:nlayers
        for ig in 1:ng
            gamma1, gamma2, gamma3 =
                NumericalRadiation._sw_two_stream_gammas(Float64, μ0,
                                                            ssa[ig, k],
                                                            asymmetry[ig, k])
            _, _, _, _, trans_dir_dir =
                NumericalRadiation._sw_reflectance_transmittance(
                    Float64, μ0, od[ig, k], ssa[ig, k], gamma1, gamma2, gamma3)
            direct[ig] *= trans_dir_dir
        end
        profile[k + 1] = μ0 * sum(direct)
    end
    return profile
end

function ecrad_output_net(output, suffix, original_columns)
    net_name = "flux_net_sw" * suffix
    down_name = "flux_dn_sw" * suffix
    up_name = "flux_up_sw" * suffix
    if haskey(output, net_name)
        return Array(output[net_name][:, original_columns])
    elseif haskey(output, down_name) && haskey(output, up_name)
        return Array(output[down_name][:, original_columns]) .-
               Array(output[up_name][:, original_columns])
    end
    return nothing
end

function run_reference_optics_solver_gap()
    reference_case = get(ENV, "RH_REFERENCE_OPTICS_REFERENCE", ALL_SKY_REFERENCE)
    properties_case = get(ENV, "RH_REFERENCE_OPTICS_PROPERTIES", ECRAD_ALL_SKY_PROPERTIES)
    output_case = get(ENV, "RH_REFERENCE_OPTICS_ECRAD_OUTPUT", ECRAD_ALL_SKY_OUTPUT)
    modes = (
        (name = "clear", overlap = :clear, inhomogeneity_overlap_exponent = 2.0),
        (name = "grid_mean", overlap = :grid_mean, inhomogeneity_overlap_exponent = 2.0),
        (name = "matrix_alpha", overlap = :matrix_alpha, inhomogeneity_overlap_exponent = 2.0),
        (name = "tripleclouds_alpha_p0", overlap = :tripleclouds_alpha, inhomogeneity_overlap_exponent = 0.0),
        (name = "tripleclouds_alpha_p1", overlap = :tripleclouds_alpha, inhomogeneity_overlap_exponent = 1.0),
        (name = "tripleclouds_alpha_p2", overlap = :tripleclouds_alpha, inhomogeneity_overlap_exponent = 2.0),
        (name = "tripleclouds_alpha_p4", overlap = :tripleclouds_alpha, inhomogeneity_overlap_exponent = 4.0),
        (name = "tripleclouds_alpha_p8", overlap = :tripleclouds_alpha, inhomogeneity_overlap_exponent = 8.0),
        (name = "tripleclouds_alpha_p12", overlap = :tripleclouds_alpha, inhomogeneity_overlap_exponent = 12.0),
        (name = "tripleclouds_alpha_p16", overlap = :tripleclouds_alpha, inhomogeneity_overlap_exponent = 16.0),
    )
    reference_path = normpath(joinpath(@__DIR__, "..", reference_case))
    properties_path = normpath(joinpath(@__DIR__, "..", properties_case))
    output_path = normpath(joinpath(@__DIR__, "..", output_case))
    rows = NamedTuple[]
    NCDataset(reference_path) do reference
        NCDataset(properties_path) do properties
            NCDataset(output_path) do ecrad_output
                original_columns = round.(Int, Array(reference["column"]))
                ninterfaces, ncolumns = size(reference["sw_up"])
                total_reference_up = Array(reference["sw_up"])
                total_reference_down = Array(reference["sw_down"])
                clear_reference_up = haskey(reference, "sw_up_clear") ?
                    Array(reference["sw_up_clear"]) : total_reference_up
                clear_reference_down = haskey(reference, "sw_down_clear") ?
                    Array(reference["sw_down_clear"]) : total_reference_down
                total_output_net = ecrad_output_net(ecrad_output, "", original_columns)
                clear_output_net =
                    ecrad_output_net(ecrad_output, "_clear", original_columns)
                clear_output_net === nothing && (clear_output_net = total_output_net)
                clear_direct_reference = haskey(ecrad_output, "flux_dn_direct_sw_clear") ?
                    Array(ecrad_output["flux_dn_direct_sw_clear"][:, original_columns]) :
                    nothing
                for mode in modes
                    up = zeros(Float64, ninterfaces, ncolumns)
                    down = zeros(Float64, ninterfaces, ncolumns)
                    direct = mode.overlap == :clear && clear_direct_reference !== nothing ?
                        zeros(Float64, ninterfaces, ncolumns) : nothing
                    for (local_column, original_column) in enumerate(original_columns)
                        column_up, column_down =
                            column_fluxes(mode.overlap, properties, reference,
                                          original_column, local_column;
                                          inhomogeneity_overlap_exponent =
                                              mode.inhomogeneity_overlap_exponent)
                        up[:, local_column] = column_up
                        down[:, local_column] = column_down
                        if direct !== nothing
                            direct[:, local_column] =
                                clear_direct_profile(properties, reference,
                                                     original_column, local_column)
                        end
                    end
                    reference_up = mode.overlap == :clear ?
                        clear_reference_up : total_reference_up
                    reference_down = mode.overlap == :clear ?
                        clear_reference_down : total_reference_down
                    output_net = mode.overlap == :clear ?
                        clear_output_net : total_output_net
                    net = down .- up
                    reference_net = reference_down .- reference_up
                    push!(rows, (
                        mode = mode.name,
                        sw_up_rmse = rmse(up, reference_up),
                        sw_up_max_abs = max_abs_error(up, reference_up),
                        sw_up_mean_bias = mean_bias(up, reference_up),
                        sw_down_rmse = rmse(down, reference_down),
                        sw_down_max_abs = max_abs_error(down, reference_down),
                        sw_down_mean_bias = mean_bias(down, reference_down),
                        toa_net_abs_error = max_abs_error(net[1, :], reference_net[1, :]),
                        surface_net_abs_error =
                            max_abs_error(net[end, :], reference_net[end, :]),
                        toa_net_mean_bias = mean_bias(net[1, :], reference_net[1, :]),
                        surface_net_mean_bias =
                            mean_bias(net[end, :], reference_net[end, :]),
                        output_toa_net_abs_error = output_net === nothing ? nothing :
                            max_abs_error(net[1, :], output_net[1, :]),
                        output_surface_net_abs_error =
                            output_net === nothing ? nothing :
                            max_abs_error(net[end, :], output_net[end, :]),
                        reference_output_toa_net_abs_error =
                            output_net === nothing ? nothing :
                            max_abs_error(reference_net[1, :], output_net[1, :]),
                        reference_output_surface_net_abs_error =
                            output_net === nothing ? nothing :
                            max_abs_error(reference_net[end, :], output_net[end, :]),
                        clear_direct_max_abs = direct === nothing ? nothing :
                            max_abs_error(direct, clear_direct_reference),
                    ))
                end
            end
        end
    end
    return (
        case = "ecrad_reference_optics_solver_gap",
        date = string(Dates.now()),
        reference = reference_case,
        properties = properties_case,
        ecrad_output = output_case,
        modes = rows,
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
        "# ecRad Reference-Optics Solver Gap",
        "",
        "This diagnostic runs RadiativeHeating shortwave solvers using ecRad's saved all-sky shortwave optical properties. It isolates solver/source treatment from gas, cloud, and aerosol optical-property generation.",
        "",
        "- Reference case: `$(result.reference)`",
        "- ecRad properties: `$(result.properties)`",
        "- ecRad output: `$(result.ecrad_output)`",
        "",
        "| Mode | SW up RMSE | SW down RMSE | Ref TOA net max abs | Ref surface net max abs | Output TOA net max abs | Output surface net max abs | Ref-output TOA max abs | Ref-output surface max abs | Clear direct max abs |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.modes
        direct = row.clear_direct_max_abs === nothing ? "n/a" :
            @sprintf("%.12g", row.clear_direct_max_abs)
        output_toa_value = hasproperty(row, :output_toa_net_abs_error) ?
            row.output_toa_net_abs_error : nothing
        output_surface_value = hasproperty(row, :output_surface_net_abs_error) ?
            row.output_surface_net_abs_error : nothing
        reference_output_toa_value =
            hasproperty(row, :reference_output_toa_net_abs_error) ?
            row.reference_output_toa_net_abs_error : nothing
        reference_output_surface_value =
            hasproperty(row, :reference_output_surface_net_abs_error) ?
            row.reference_output_surface_net_abs_error : nothing
        output_toa = output_toa_value === nothing ? "n/a" :
            @sprintf("%.12g", output_toa_value)
        output_surface = output_surface_value === nothing ? "n/a" :
            @sprintf("%.12g", output_surface_value)
        reference_output_toa =
            reference_output_toa_value === nothing ? "n/a" :
            @sprintf("%.12g", reference_output_toa_value)
        reference_output_surface =
            reference_output_surface_value === nothing ? "n/a" :
            @sprintf("%.12g", reference_output_surface_value)
        push!(lines, "| `$(row.mode)` | $(@sprintf("%.12g", row.sw_up_rmse)) | $(@sprintf("%.12g", row.sw_down_rmse)) | $(@sprintf("%.12g", row.toa_net_abs_error)) | $(@sprintf("%.12g", row.surface_net_abs_error)) | $(output_toa) | $(output_surface) | $(reference_output_toa) | $(reference_output_surface) | $(direct) |")
    end
    return join(lines, "\n") * "\n"
end

function main()
    result = run_reference_optics_solver_gap()
    results_dir = validation_results_dir()
    mkpath(results_dir)
    output_basename = get(ENV, "RH_REFERENCE_OPTICS_OUTPUT_BASENAME",
                          REFERENCE_OPTICS_OUTPUT_BASENAME)
    json_path = joinpath(results_dir, output_basename * ".json")
    md_path = joinpath(results_dir, output_basename * ".md")
    write(json_path, json_object(result))
    write(md_path, markdown_report(result))
    print(markdown_report(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
