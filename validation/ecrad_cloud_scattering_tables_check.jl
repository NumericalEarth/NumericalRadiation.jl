include(joinpath(@__DIR__, "validation_results.jl"))

using Dates

const ABR_ROOT = normpath(joinpath(@__DIR__, ".."))
if Base.find_package("NumericalRadiation") === nothing
    push!(LOAD_PATH, ABR_ROOT)
end

using NumericalRadiation
using NCDatasets

include(joinpath(@__DIR__, "ecrad_reference_manifest.jl"))

const CLOUD_SCATTERING_FILES = (
    (
        kind = "liquid",
        path = "validation/external/ecrad/data/mie_droplet_scattering.nc",
        expected_medium = "liquid-water",
        expected_particle_type = "liquid-droplet",
    ),
    (
        kind = "ice",
        path = "validation/external/ecrad/data/baum-general-habit-mixture_ice_scattering.nc",
        expected_medium = "ice",
        expected_particle_type = "ice-particle",
    ),
)

const CLOUD_SCATTERING_MAPPINGS = (
    (
        kind = "shortwave",
        path = "validation/external/ecrad/data/ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc",
        expected_gpoints = 32,
        liquid_effective_radius = 10.0e-6,
        ice_effective_radius = 30.0e-6,
    ),
    (
        kind = "longwave",
        path = "validation/external/ecrad/data/ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
        expected_gpoints = 64,
        liquid_effective_radius = 10.0e-6,
        ice_effective_radius = 30.0e-6,
    ),
)

function _sample_properties(table)
    iwavenumber = max(1, cld(length(table.wavenumber), 2))
    radius = table.effective_radius[max(1, cld(length(table.effective_radius), 2))]
    props = cloud_scattering_properties(table, iwavenumber, radius)
    return (
        wavenumber_index = iwavenumber,
        effective_radius = radius,
        mass_extinction_coefficient = props.mass_extinction_coefficient,
        single_scattering_albedo = props.single_scattering_albedo,
        asymmetry_factor = props.asymmetry_factor,
        finite = all(isfinite, (
            props.mass_extinction_coefficient,
            props.single_scattering_albedo,
            props.asymmetry_factor,
        )),
    )
end

function cloud_scattering_file_status(spec)
    path = reference_path(spec.path)
    if !isfile(path)
        return (
            kind = spec.kind,
            path = spec.path,
            present = false,
            passed = false,
            status = "missing_file",
        )
    end

    table = read_cloud_scattering_table(path)
    shape_ok = size(table.mass_extinction_coefficient) ==
               (length(table.wavenumber), length(table.effective_radius)) &&
               size(table.single_scattering_albedo) ==
               (length(table.wavenumber), length(table.effective_radius)) &&
               size(table.asymmetry_factor) ==
               (length(table.wavenumber), length(table.effective_radius))
    finite = all(isfinite, table.mass_extinction_coefficient) &&
             all(isfinite, table.single_scattering_albedo) &&
             all(isfinite, table.asymmetry_factor)
    bounded = minimum(table.mass_extinction_coefficient) >= 0 &&
              all(0 .<= table.single_scattering_albedo .<= 1) &&
              all(-1 .<= table.asymmetry_factor .<= 1)
    metadata_ok = table.medium == spec.expected_medium
    sample = _sample_properties(table)
    passed = shape_ok && finite && bounded && metadata_ok && sample.finite

    return (
        kind = spec.kind,
        path = spec.path,
        present = true,
        medium = table.medium,
        expected_medium = spec.expected_medium,
        medium_matches = metadata_ok,
        particle_type = table.particle_type,
        expected_particle_type = spec.expected_particle_type,
        wavenumber_count = length(table.wavenumber),
        effective_radius_count = length(table.effective_radius),
        coefficient_shape = collect(size(table.mass_extinction_coefficient)),
        shape_ok = shape_ok,
        finite = finite,
        bounded = bounded,
        sample = sample,
        passed = passed,
        status = passed ? "passed" : "failed_schema_expectation",
    )
end

function _mapped_status(table, mapping, expected_gpoints, effective_radius)
    props = cloud_scattering_gpoint_properties(table, mapping, effective_radius)
    finite = all(isfinite, props.mass_extinction_coefficient) &&
             all(isfinite, props.single_scattering_albedo) &&
             all(isfinite, props.asymmetry_factor)
    bounded = minimum(props.mass_extinction_coefficient) >= 0 &&
              all(0 .<= props.single_scattering_albedo .<= 1) &&
              all(-1 .<= props.asymmetry_factor .<= 1)
    length_ok = length(props.mass_extinction_coefficient) == expected_gpoints
    positive_extinction = maximum(props.mass_extinction_coefficient) > 0
    return (
        effective_radius = effective_radius,
        gpoints = length(props.mass_extinction_coefficient),
        expected_gpoints = expected_gpoints,
        length_ok = length_ok,
        finite = finite,
        bounded = bounded,
        positive_extinction = positive_extinction,
        mass_extinction_minimum = minimum(props.mass_extinction_coefficient),
        mass_extinction_maximum = maximum(props.mass_extinction_coefficient),
        single_scattering_albedo_minimum = minimum(props.single_scattering_albedo),
        single_scattering_albedo_maximum = maximum(props.single_scattering_albedo),
        asymmetry_factor_minimum = minimum(props.asymmetry_factor),
        asymmetry_factor_maximum = maximum(props.asymmetry_factor),
        passed = length_ok && finite && bounded && positive_extinction,
    )
end

function spectral_mapping_status(spec)
    path = reference_path(spec.path)
    liquid_path = reference_path(CLOUD_SCATTERING_FILES[1].path)
    ice_path = reference_path(CLOUD_SCATTERING_FILES[2].path)
    if !isfile(path) || !isfile(liquid_path) || !isfile(ice_path)
        return (
            kind = spec.kind,
            path = spec.path,
            present = false,
            passed = false,
            status = "missing_file",
        )
    end

    mapping = read_ecckd_spectral_mapping(path)
    liquid = read_cloud_scattering_table(liquid_path)
    ice = read_cloud_scattering_table(ice_path)
    liquid_status = _mapped_status(liquid, mapping, spec.expected_gpoints,
                                   spec.liquid_effective_radius)
    ice_status = _mapped_status(ice, mapping, spec.expected_gpoints,
                                spec.ice_effective_radius)
    shape_ok = size(mapping.gpoint_fraction, 1) == length(mapping.wavenumber1) &&
               size(mapping.gpoint_fraction, 1) == length(mapping.wavenumber2) &&
               size(mapping.gpoint_fraction, 2) == spec.expected_gpoints
    fractions_nonnegative = minimum(mapping.gpoint_fraction) >= 0
    passed = shape_ok && fractions_nonnegative &&
             liquid_status.passed && ice_status.passed
    return (
        kind = spec.kind,
        path = spec.path,
        present = true,
        wavenumber_intervals = length(mapping.wavenumber1),
        gpoints = size(mapping.gpoint_fraction, 2),
        expected_gpoints = spec.expected_gpoints,
        shape_ok = shape_ok,
        fractions_nonnegative = fractions_nonnegative,
        liquid = liquid_status,
        ice = ice_status,
        passed = passed,
        status = passed ? "passed" : "failed_mapping_expectation",
    )
end

function run_ecrad_cloud_scattering_tables_check()
    files = [cloud_scattering_file_status(spec) for spec in CLOUD_SCATTERING_FILES]
    mappings = [spectral_mapping_status(spec) for spec in CLOUD_SCATTERING_MAPPINGS]
    return (
        case = "ecrad_cloud_scattering_tables_check",
        date = string(Dates.now()),
        status = all(file -> file.passed, files) &&
                 all(mapping -> mapping.passed, mappings) ? "passed" : "failed",
        files = files,
        mappings = mappings,
    )
end

function markdown_cloud_scattering_report(result)
    lines = String[
        "# ecRad Cloud Scattering Tables Check",
        "",
        "Status: **$(result.status)**",
        "",
        "This check verifies that the package can ingest the official ecRad cloud scattering NetCDF tables and map them to the official ecCKD g-point grids needed for the all-sky SOCRATES/Fu optical-property path. It does not yet prove that the mapped properties are used by the all-sky solver.",
        "",
        "| Kind | Status | Medium | Wavenumbers | Effective radii | Shape OK | Bounded | Path |",
        "|---|---|---|---:|---:|---:|---:|---|",
    ]
    for file in result.files
        medium = hasproperty(file, :medium) ? file.medium : "missing"
        nwave = hasproperty(file, :wavenumber_count) ? string(file.wavenumber_count) : "missing"
        nradius = hasproperty(file, :effective_radius_count) ? string(file.effective_radius_count) : "missing"
        shape_ok = hasproperty(file, :shape_ok) ? string(file.shape_ok) : "false"
        bounded = hasproperty(file, :bounded) ? string(file.bounded) : "false"
        push!(lines, "| $(file.kind) | $(file.status) | `$medium` | $nwave | $nradius | $shape_ok | $bounded | `$(file.path)` |")
    end
    append!(lines, [
        "",
        "## ecCKD G-Point Mapping",
        "",
        "| Kind | Status | Intervals | G-points | Shape OK | Fractions nonnegative | Liquid max extinction | Ice max extinction |",
        "|---|---|---:|---:|---:|---:|---:|---:|",
    ])
    for mapping in result.mappings
        liquid_max = hasproperty(mapping, :liquid) ? string(mapping.liquid.mass_extinction_maximum) : "missing"
        ice_max = hasproperty(mapping, :ice) ? string(mapping.ice.mass_extinction_maximum) : "missing"
        intervals = hasproperty(mapping, :wavenumber_intervals) ? string(mapping.wavenumber_intervals) : "missing"
        gpoints = hasproperty(mapping, :gpoints) ? string(mapping.gpoints) : "missing"
        shape_ok = hasproperty(mapping, :shape_ok) ? string(mapping.shape_ok) : "false"
        nonnegative = hasproperty(mapping, :fractions_nonnegative) ? string(mapping.fractions_nonnegative) : "false"
        push!(lines, "| $(mapping.kind) | $(mapping.status) | $intervals | $gpoints | $shape_ok | $nonnegative | $liquid_max | $ice_max |")
    end
    append!(lines, [
        "",
        "Next implementation step: use these mapped g-point scattering properties in cloudy-region optical-depth construction and then carry cloud fraction/overlap through the all-sky solver instead of tuning broadband cloud coefficients.",
    ])
    return join(lines, "\n") * "\n"
end

function ecrad_cloud_scattering_tables_check_main()
    result = run_ecrad_cloud_scattering_tables_check()
    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "ecrad_cloud_scattering_tables_check.json")
    md_path = joinpath(results_dir, "ecrad_cloud_scattering_tables_check.md")
    write(json_path, json_object(result))
    write(md_path, markdown_cloud_scattering_report(result))

    print(markdown_cloud_scattering_report(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecrad_cloud_scattering_tables_check_main()
end
