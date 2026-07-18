include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using Printf
using Statistics

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))

using NumericalRadiation
using NCDatasets
using RRTMGP

const RESULT_JSON =
    validation_results_path("reduced_ecckd_32g_rrtmgp_comparison.json")
const RESULT_MD =
    validation_results_path("reduced_ecckd_32g_rrtmgp_comparison.md")
const REDUCED_ACCURACY_JSON =
    validation_results_path("reduced_ecckd_accuracy.json")

const CASES = (
    (
        case = "ecckd_clear_sky_tropical_column",
        path = joinpath(@__DIR__, "reference", "ecrad",
                        "ecckd_clear_sky_tropical_column.nc"),
        reference_suffix = "",
        candidate_suffix = "",
    ),
    (
        case = "ecckd_rcemip_style_column_subset",
        path = joinpath(@__DIR__, "reference", "ecrad",
                        "ecckd_rcemip_style_column_subset.nc"),
        reference_suffix = "",
        candidate_suffix = "",
    ),
    (
        case = "ecckd_all_sky_tropical_column_clear_projection",
        path = joinpath(@__DIR__, "reference", "ecrad",
                        "ecckd_all_sky_tropical_column.nc"),
        reference_suffix = "_clear",
        candidate_suffix = "_clear",
    ),
)

json_escape(text) = replace(string(text), "\\" => "\\\\", "\"" => "\\\"",
                            "\n" => "\\n")

function json_value(value)
    value === nothing && return "null"
    value isa Bool && return value ? "true" : "false"
    value isa Number && return string(value)
    value isa AbstractString && return "\"$(json_escape(value))\""
    value isa Symbol && return "\"$(json_escape(String(value)))\""
    if value isa AbstractVector || value isa Tuple
        return "[" * join(json_value.(collect(value)), ", ") * "]"
    end
    if value isa NamedTuple
        return json_object(value)
    end
    return "\"$(json_escape(value))\""
end

function json_object(object)
    pairs = ["\"$(json_escape(key))\": $(json_value(getproperty(object, key)))"
             for key in propertynames(object)]
    return "{\n  " * join(pairs, ",\n  ") * "\n}"
end

function fluxes_from_dataset(ds, prefix, suffix, column)
    variable(name) = haskey(ds, "$(prefix)$(name)$(suffix)") ?
                     "$(prefix)$(name)$(suffix)" :
                     "$(name)$(suffix)"
    return RadiativeFluxes(
        longwave_up = Array(ds[variable("lw_up")])[:, column],
        longwave_down = Array(ds[variable("lw_down")])[:, column],
        shortwave_up = Array(ds[variable("sw_up")])[:, column],
        shortwave_down = Array(ds[variable("sw_down")])[:, column],
    )
end

function atmosphere_from_dataset(ds, column)
    co2 = Array(ds["co2"])[:, column]
    ch4 = Array(ds["ch4"])[:, column]
    n2o = Array(ds["n2o"])[:, column]
    gases = (
        h2o = Array(ds["h2o"])[:, column],
        o3 = Array(ds["o3"])[:, column],
        co2 = co2[1],
        ch4 = ch4[1],
        n2o = n2o[1],
        o2 = 0.20946,
        n2 = 0.78084,
    )
    return ColumnAtmosphere(
        pressure_layers = Array(ds["pressure_layer"])[:, column],
        pressure_interfaces = Array(ds["pressure_interface"])[:, column],
        temperature_layers = Array(ds["temperature_layer"])[:, column],
        temperature_interfaces = Array(ds["temperature_interface"])[:, column],
        gases = gases,
        surface = (;),
        geometry = (; cos_zenith = Array(ds["cos_solar_zenith_angle"])[column]),
    )
end

function rrtmgp_fluxes!(fluxes, model, atmosphere, ds, column, workspace)
    ext = Base.get_extension(NumericalRadiation, :NumericalRadiationRRTMGPExt)
    ext === nothing && error("NumericalRadiationRRTMGPExt did not load")
    boundary = ext.RRTMGPBoundaryConditions(
        surface_temperature = Array(ds["surface_temperature"])[column],
        surface_emissivity = 0.98,
        surface_albedo = Array(ds["surface_albedo"])[column],
        toa_shortwave_down = Array(ds["solar_irradiance"])[column],
        cos_zenith = Array(ds["cos_solar_zenith_angle"])[column],
    )
    radiative_fluxes!(fluxes, model, atmosphere, boundary, workspace)
    return fluxes
end

function empty_fluxes(ninterfaces)
    return RadiativeFluxes(
        longwave_up = zeros(Float64, ninterfaces),
        longwave_down = zeros(Float64, ninterfaces),
        shortwave_up = zeros(Float64, ninterfaces),
        shortwave_down = zeros(Float64, ninterfaces),
    )
end

function aggregate_metrics(metrics)
    isempty(metrics) && return (
        flux_rmse = NaN,
        flux_max_abs = NaN,
        heating_rate_rmse = NaN,
        heating_rate_max_abs = NaN,
        toa_forcing_abs_error = NaN,
        surface_forcing_abs_error = NaN,
    )
    return (
        flux_rmse = sqrt(mean(m.flux_rmse^2 for m in metrics)),
        flux_max_abs = maximum(m.flux_max_abs for m in metrics),
        heating_rate_rmse = sqrt(mean(m.heating_rate_rmse^2 for m in metrics)),
        heating_rate_max_abs = maximum(m.heating_rate_max_abs for m in metrics),
        toa_forcing_abs_error = maximum(abs(m.toa_forcing_error) for m in metrics),
        surface_forcing_abs_error = maximum(abs(m.surface_forcing_error) for m in metrics),
    )
end

function case_result(spec, model)
    candidate_vs_ecckd = RadiationErrorMetrics[]
    candidate_vs_rrtmgp = RadiationErrorMetrics[]
    ncolumns = 0
    NCDataset(spec.path) do ds
        ncolumns = length(ds["column"])
        rrtmgp = empty_fluxes(size(ds["pressure_interface"], 1))
        workspace = nothing
        for column in 1:ncolumns
            atmosphere = atmosphere_from_dataset(ds, column)
            workspace === nothing && (workspace = radiation_workspace(model, atmosphere))
            candidate = fluxes_from_dataset(ds, "radiative_heating_", spec.candidate_suffix, column)
            reference = fluxes_from_dataset(ds, "", spec.reference_suffix, column)
            rrtmgp_fluxes!(rrtmgp, model, atmosphere, ds, column, workspace)
            push!(candidate_vs_ecckd,
                  radiative_flux_error_metrics(candidate, reference, atmosphere;
                                               gravity = 9.80665,
                                               heat_capacity = 1004.0))
            push!(candidate_vs_rrtmgp,
                  radiative_flux_error_metrics(candidate, rrtmgp, atmosphere;
                                               gravity = 9.80665,
                                               heat_capacity = 1004.0))
        end
    end
    return (
        case = spec.case,
        path = relpath(spec.path, normpath(joinpath(@__DIR__, ".."))),
        columns = ncolumns,
        reference_suffix = spec.reference_suffix,
        candidate_suffix = spec.candidate_suffix,
        candidate_vs_ecckd_reference = aggregate_metrics(candidate_vs_ecckd),
        candidate_vs_rrtmgp = aggregate_metrics(candidate_vs_rrtmgp),
    )
end

function model_passed_in_reduced_accuracy(ng_lw, ng_sw, label_fragment)
    isfile(REDUCED_ACCURACY_JSON) || return false
    data = JSON.parsefile(REDUCED_ACCURACY_JSON)
    return any(get(data, "models", Any[])) do model
        Int(model["ng_lw"]) == ng_lw &&
            Int(model["ng_sw"]) == ng_sw &&
            Bool(model["passed_hard_thresholds"]) &&
            occursin(label_fragment, String(model["reduction_method"]))
    end
end

function run_comparison()
    ext = Base.get_extension(NumericalRadiation, :NumericalRadiationRRTMGPExt)
    ext === nothing && error("NumericalRadiationRRTMGPExt did not load")
    model = ext.RRTMGPClearSkyModel(Float64)
    cases = [case_result(spec, model) for spec in CASES]
    all_finite = all(cases) do case
        values = (
            case.candidate_vs_ecckd_reference.flux_rmse,
            case.candidate_vs_ecckd_reference.heating_rate_rmse,
            case.candidate_vs_rrtmgp.flux_rmse,
            case.candidate_vs_rrtmgp.heating_rate_rmse,
        )
        all(isfinite, values)
    end
    ecckd_passed = model_passed_in_reduced_accuracy(32, 32, "official ecCKD 32x32")
    status = ecckd_passed && all_finite ? "passed" : "failed"
    return (
        case = "reduced_ecckd_32g_rrtmgp_comparison",
        timestamp_utc = string(Dates.now()),
        status = status,
        production_target = "official ecCKD 32-g gas optics",
        frozen_diagnostic = "greedy-era reduced candidates (16-g canonical chain, 32x31 boundary polish) are frozen as evidence in validation/FROZEN_DIAGNOSTICS.md; no reduced row is tracked here",
        rrtmgp_role = "direct CKD compatibility baseline, not line-by-line truth",
        candidate_source = "radiative_heating_* NetCDF variables for official ecCKD 32/32",
        official_32g_ecckd_hard_gate_passed = ecckd_passed,
        rrtmgp_comparison_emitted = all_finite,
        cases = cases,
    )
end

function write_markdown(result)
    lines = String[
        "# 32-g ecCKD RRTMGP Comparison",
        "",
        "Status: **$(result.status)**",
        "",
        "- production target: $(result.production_target)",
        "- frozen diagnostic: $(result.frozen_diagnostic)",
        "- RRTMGP role: $(result.rrtmgp_role)",
        "- candidate source: $(result.candidate_source)",
        "- official 32-g ecCKD hard gate passed: $(result.official_32g_ecckd_hard_gate_passed)",
        "- RRTMGP comparison emitted: $(result.rrtmgp_comparison_emitted)",
        "",
        "| Case | Columns | Official ecCKD flux RMSE | Official ecCKD heating RMSE | Official RRTMGP flux RMSE | Official RRTMGP heating RMSE |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for case in result.cases
        push!(lines,
              "| $(case.case) | $(case.columns) | $(@sprintf("%.12g", case.candidate_vs_ecckd_reference.flux_rmse)) | $(@sprintf("%.12g", case.candidate_vs_ecckd_reference.heating_rate_rmse)) | $(@sprintf("%.12g", case.candidate_vs_rrtmgp.flux_rmse)) | $(@sprintf("%.12g", case.candidate_vs_rrtmgp.heating_rate_rmse)) |")
    end
    push!(lines, "")
    push!(lines,
          "The official 32-g ecCKD production target is accepted against the ecRad/ecCKD hard gate. RRTMGP is reported as a compatibility comparison between CKD models, not as the absolute-accuracy reference.")
    return join(lines, "\n") * "\n"
end

function main()
    result = run_comparison()
    mkpath(dirname(RESULT_JSON))
    write(RESULT_JSON, json_object(result))
    write(RESULT_MD, write_markdown(result))
    println(read(RESULT_MD, String))
    println("Wrote $RESULT_JSON")
    println("Wrote $RESULT_MD")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
