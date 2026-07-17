include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "ecrad_reference_manifest.jl"))

const MATCHED_REFERENCE_PLAN_JSON =
    validation_results_path("ecckd_matched_reference_plan.json")
const MATCHED_REFERENCE_PLAN_MD =
    validation_results_path("ecckd_matched_reference_plan.md")

const MATCHED_REFERENCE_CASES = (
    (
        case = "ecckd_32x64_clear_sky_tropical_column",
        existing_reference_case = "ecckd_clear_sky_tropical_column",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_32x64_clear_sky_tropical_column.nc"),
        longwave_key = "longwave_32",
        shortwave_key = "shortwave_64",
        longwave_gpoints = 32,
        shortwave_gpoints = 64,
        longwave_file = "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc",
        shortwave_file = "ecckd-1.2_sw_climate_window-64b_ckd-definition.nc",
        columns = "12:21",
        all_sky = false,
    ),
    (
        case = "ecckd_32x96_clear_sky_tropical_column",
        existing_reference_case = "ecckd_clear_sky_tropical_column",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_32x96_clear_sky_tropical_column.nc"),
        longwave_key = "longwave_32",
        shortwave_key = "shortwave_96",
        longwave_gpoints = 32,
        shortwave_gpoints = 96,
        longwave_file = "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc",
        shortwave_file = "ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc",
        columns = "12:21",
        all_sky = false,
    ),
    (
        case = "ecckd_64x32_clear_sky_tropical_column",
        existing_reference_case = "ecckd_clear_sky_tropical_column",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_64x32_clear_sky_tropical_column.nc"),
        longwave_key = "longwave_64",
        shortwave_key = "shortwave_32",
        longwave_gpoints = 64,
        shortwave_gpoints = 32,
        longwave_file = "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
        shortwave_file = "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc",
        columns = "12:21",
        all_sky = false,
    ),
    (
        case = "ecckd_64x64_clear_sky_tropical_column",
        existing_reference_case = "ecckd_clear_sky_tropical_column",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_64x64_clear_sky_tropical_column.nc"),
        longwave_key = "longwave_64",
        shortwave_key = "shortwave_64",
        longwave_gpoints = 64,
        shortwave_gpoints = 64,
        longwave_file = "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
        shortwave_file = "ecckd-1.2_sw_climate_window-64b_ckd-definition.nc",
        columns = "12:21",
        all_sky = false,
    ),
    (
        case = "ecckd_64x96_clear_sky_tropical_column",
        existing_reference_case = "ecckd_clear_sky_tropical_column",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_64x96_clear_sky_tropical_column.nc"),
        longwave_key = "longwave_64",
        shortwave_key = "shortwave_96",
        longwave_gpoints = 64,
        shortwave_gpoints = 96,
        longwave_file = "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
        shortwave_file = "ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc",
        columns = "12:21",
        all_sky = false,
    ),
    (
        case = "ecckd_32x64_rcemip_style_column_subset",
        existing_reference_case = "ecckd_rcemip_style_column_subset",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_32x64_rcemip_style_column_subset.nc"),
        longwave_key = "longwave_32",
        shortwave_key = "shortwave_64",
        longwave_gpoints = 32,
        shortwave_gpoints = 64,
        longwave_file = "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc",
        shortwave_file = "ecckd-1.2_sw_climate_window-64b_ckd-definition.nc",
        columns = "1:32",
        all_sky = false,
    ),
    (
        case = "ecckd_32x96_rcemip_style_column_subset",
        existing_reference_case = "ecckd_rcemip_style_column_subset",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_32x96_rcemip_style_column_subset.nc"),
        longwave_key = "longwave_32",
        shortwave_key = "shortwave_96",
        longwave_gpoints = 32,
        shortwave_gpoints = 96,
        longwave_file = "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc",
        shortwave_file = "ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc",
        columns = "1:32",
        all_sky = false,
    ),
    (
        case = "ecckd_64x32_rcemip_style_column_subset",
        existing_reference_case = "ecckd_rcemip_style_column_subset",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_64x32_rcemip_style_column_subset.nc"),
        longwave_key = "longwave_64",
        shortwave_key = "shortwave_32",
        longwave_gpoints = 64,
        shortwave_gpoints = 32,
        longwave_file = "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
        shortwave_file = "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc",
        columns = "1:32",
        all_sky = false,
    ),
    (
        case = "ecckd_64x64_rcemip_style_column_subset",
        existing_reference_case = "ecckd_rcemip_style_column_subset",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_64x64_rcemip_style_column_subset.nc"),
        longwave_key = "longwave_64",
        shortwave_key = "shortwave_64",
        longwave_gpoints = 64,
        shortwave_gpoints = 64,
        longwave_file = "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
        shortwave_file = "ecckd-1.2_sw_climate_window-64b_ckd-definition.nc",
        columns = "1:32",
        all_sky = false,
    ),
    (
        case = "ecckd_64x96_rcemip_style_column_subset",
        existing_reference_case = "ecckd_rcemip_style_column_subset",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_64x96_rcemip_style_column_subset.nc"),
        longwave_key = "longwave_64",
        shortwave_key = "shortwave_96",
        longwave_gpoints = 64,
        shortwave_gpoints = 96,
        longwave_file = "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
        shortwave_file = "ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc",
        columns = "1:32",
        all_sky = false,
    ),
    (
        case = "ecckd_32x32_all_sky_tropical_column",
        existing_reference_case = "ecckd_all_sky_tropical_column",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_all_sky_tropical_column.nc"),
        longwave_key = "longwave_32",
        shortwave_key = "shortwave_32",
        longwave_gpoints = 32,
        shortwave_gpoints = 32,
        longwave_file = "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc",
        shortwave_file = "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc",
        columns = "12:21",
        all_sky = true,
    ),
    (
        case = "ecckd_32x64_all_sky_tropical_column",
        existing_reference_case = "ecckd_all_sky_tropical_column",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_32x64_all_sky_tropical_column.nc"),
        longwave_key = "longwave_32",
        shortwave_key = "shortwave_64",
        longwave_gpoints = 32,
        shortwave_gpoints = 64,
        longwave_file = "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc",
        shortwave_file = "ecckd-1.2_sw_climate_window-64b_ckd-definition.nc",
        columns = "12:21",
        all_sky = true,
    ),
    (
        case = "ecckd_32x96_all_sky_tropical_column",
        existing_reference_case = "ecckd_all_sky_tropical_column",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_32x96_all_sky_tropical_column.nc"),
        longwave_key = "longwave_32",
        shortwave_key = "shortwave_96",
        longwave_gpoints = 32,
        shortwave_gpoints = 96,
        longwave_file = "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc",
        shortwave_file = "ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc",
        columns = "12:21",
        all_sky = true,
    ),
    (
        case = "ecckd_64x32_all_sky_tropical_column",
        existing_reference_case = "ecckd_all_sky_tropical_column",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_64x32_all_sky_tropical_column.nc"),
        longwave_key = "longwave_64",
        shortwave_key = "shortwave_32",
        longwave_gpoints = 64,
        shortwave_gpoints = 32,
        longwave_file = "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
        shortwave_file = "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc",
        columns = "12:21",
        all_sky = true,
    ),
    (
        case = "ecckd_64x64_all_sky_tropical_column",
        existing_reference_case = "ecckd_all_sky_tropical_column",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_64x64_all_sky_tropical_column.nc"),
        longwave_key = "longwave_64",
        shortwave_key = "shortwave_64",
        longwave_gpoints = 64,
        shortwave_gpoints = 64,
        longwave_file = "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
        shortwave_file = "ecckd-1.2_sw_climate_window-64b_ckd-definition.nc",
        columns = "12:21",
        all_sky = true,
    ),
    (
        case = "ecckd_64x96_all_sky_tropical_column",
        existing_reference_case = "ecckd_all_sky_tropical_column",
        output_path =
            joinpath(@__DIR__, "reference", "ecrad",
                     "ecckd_64x96_all_sky_tropical_column.nc"),
        longwave_key = "longwave_64",
        shortwave_key = "shortwave_96",
        longwave_gpoints = 64,
        shortwave_gpoints = 96,
        longwave_file = "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
        shortwave_file = "ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc",
        columns = "12:21",
        all_sky = true,
    ),
)

const REQUIRED_MATCHED_VARIABLES = (
    "surface_longwave_up_spectral",
    "surface_albedo_spectral",
    "lw_up",
    "lw_down",
    "sw_up",
    "sw_down",
    "heating_rate",
)

const REQUIRED_ALL_SKY_MATCHED_VARIABLES = (
    "cloud_fraction",
    "liquid_water_path",
    "ice_water_path",
    "re_liquid",
    "re_ice",
    "aerosol_mmr",
    "lw_up_clear",
    "sw_down_clear",
)

function require_ncdatasets()
    NCDATASETS === nothing &&
        error("NCDatasets is required. Run with `julia --project=test validation/ecckd_matched_reference_plan.jl`.")
    return NCDATASETS
end

function existing_output_files()
    ifs_dir = joinpath(@__DIR__, "external", "ecrad", "test", "ifs")
    isdir(ifs_dir) || return String[]
    return sort(filter(name -> startswith(name, "ecrad_meridian") &&
                              endswith(name, ".nc"),
                       readdir(ifs_dir)))
end

function case_status(spec)
    present = isfile(spec.output_path)
    missing_variables = String[]
    boundary_matches = false
    if present
        nc = require_ncdatasets()
        nc.NCDataset(spec.output_path) do dataset
            variables = String.(collect(keys(dataset)))
            required_variables = spec.all_sky ?
                (REQUIRED_MATCHED_VARIABLES..., REQUIRED_ALL_SKY_MATCHED_VARIABLES...) :
                REQUIRED_MATCHED_VARIABLES
            missing_variables = [name for name in required_variables if !(name in variables)]
            boundary_matches =
                "surface_longwave_up_spectral" in variables &&
                "surface_albedo_spectral" in variables &&
                size(dataset["surface_longwave_up_spectral"], 1) ==
                    spec.longwave_gpoints &&
                size(dataset["surface_albedo_spectral"], 1) ==
                    spec.shortwave_gpoints
        end
    end
    all_sky_overrides = (
        "gas_model_name=\"ECCKD\"",
        "sw_solver_name=\"Tripleclouds\"",
        "lw_solver_name=\"Tripleclouds\"",
        "use_aerosols=true",
        "do_save_spectral_flux=true",
        "do_save_gpoint_flux=false",
        "gas_optics_lw_override_file_name=\"$(spec.longwave_file)\"",
        "gas_optics_sw_override_file_name=\"$(spec.shortwave_file)\"",
    )
    cloudless_overrides = (
        "gas_model_name=\"ECCKD\"",
        "sw_solver_name=\"Cloudless\"",
        "lw_solver_name=\"Cloudless\"",
        "use_aerosols=false",
        "do_save_spectral_flux=true",
        "do_save_gpoint_flux=false",
        "gas_optics_lw_override_file_name=\"$(spec.longwave_file)\"",
        "gas_optics_sw_override_file_name=\"$(spec.shortwave_file)\"",
    )
    return (
        case = spec.case,
        existing_reference_case = spec.existing_reference_case,
        output_path = spec.output_path,
        present = present,
        required_longwave_gpoints = spec.longwave_gpoints,
        required_shortwave_gpoints = spec.shortwave_gpoints,
        boundary_gpoints_match = boundary_matches,
        missing_variables = missing_variables,
        longwave_key = spec.longwave_key,
        shortwave_key = spec.shortwave_key,
        namelist_overrides = spec.all_sky ? all_sky_overrides : cloudless_overrides,
        columns = spec.columns,
        all_sky = spec.all_sky,
    )
end

function matched_reference_plan()
    cases = [case_status(spec) for spec in MATCHED_REFERENCE_CASES]
    missing_cases = count(case -> !(case.present && case.boundary_gpoints_match &&
                                    isempty(case.missing_variables)), cases)
    status = missing_cases == 0 ? "ready_for_published_parity_validation" :
             "matched_published_references_missing"
    next_step = missing_cases == 0 ?
        "Run the published-model accuracy, Pareto, and recovery-audit validations against the matched reference products; all required matched reference files are present with compatible spectral boundary arrays." :
        "Run ecRad with the listed ecCKD definition-file combinations for the tropical, RCEMIP-style, and all-sky column selections, then materialize those outputs into the listed validation/reference/ecrad NetCDF files with matching spectral boundary arrays."
    return (
        case = "ecckd_matched_reference_plan",
        timestamp_utc = string(Dates.now()),
        status = status,
        rationale = "Published 64/96 ecCKD parity cannot be established against the current 32-g package-native references because spectral boundary arrays do not match the target g-point grids; the projection diagnostic reduces SW surface forcing but still fails TOA forcing and invalidates LW boundaries.",
        existing_ecrad_outputs = existing_output_files(),
        required_cases = cases,
        missing_case_count = missing_cases,
        next_step = next_step,
    )
end

function markdown_report(result)
    lines = String[
        "# ecCKD Matched Reference Plan",
        "",
        "Status: **$(result.status)**",
        "",
        result.rationale,
        "",
        "- Missing matched reference cases: $(result.missing_case_count)",
        "- Existing ecRad output files inspected: $(length(result.existing_ecrad_outputs))",
        "",
        "## Required Matched References",
        "",
        "| Case | LW | SW | Present | Boundary matches | Output |",
        "|---|---:|---:|---:|---:|---|",
    ]
    for row in result.required_cases
        push!(lines,
              "| $(row.case) | $(row.required_longwave_gpoints) | $(row.required_shortwave_gpoints) | $(row.present) | $(row.boundary_gpoints_match) | `$(row.output_path)` |")
    end
    append!(lines, [
        "",
        "## Required ecRad Namelist Overrides",
        "",
        "Each listed case requires the appropriate ecRad ecCKD template plus these case-specific gas-optics override files:",
        "",
        "| Case | LW override | SW override |",
        "|---|---|---|",
    ])
    for row in result.required_cases
        lw_override = filter(value -> startswith(value, "gas_optics_lw_override"),
                             row.namelist_overrides)[1]
        sw_override = filter(value -> startswith(value, "gas_optics_sw_override"),
                             row.namelist_overrides)[1]
        push!(lines, "| $(row.case) | `$(lw_override)` | `$(sw_override)` |")
    end
    append!(lines, [
        "",
        "## Next Step",
        "",
        result.next_step,
    ])
    return join(lines, "\n") * "\n"
end

function main()
    result = matched_reference_plan()
    mkpath(dirname(MATCHED_REFERENCE_PLAN_JSON))
    write(MATCHED_REFERENCE_PLAN_JSON, json_object(result) * "\n")
    write(MATCHED_REFERENCE_PLAN_MD, markdown_report(result))
    print(markdown_report(result))
    println("Wrote $MATCHED_REFERENCE_PLAN_JSON")
    println("Wrote $MATCHED_REFERENCE_PLAN_MD")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
