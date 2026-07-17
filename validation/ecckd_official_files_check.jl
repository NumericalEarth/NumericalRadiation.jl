include(joinpath(@__DIR__, "validation_results.jl"))

using Dates

const ABR_ROOT = normpath(joinpath(@__DIR__, ".."))
if Base.find_package("NumericalRadiation") === nothing
    push!(LOAD_PATH, ABR_ROOT)
end

using NumericalRadiation
using NCDatasets

include(joinpath(@__DIR__, "ecrad_reference_manifest.jl"))

const OFFICIAL_ECCKD_FILES = (
    (
        kind = "longwave",
        key = :longwave_64,
        path = "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
        expected_gpoints = 64,
        expected_bands = 13,
        required_gases = ("composite", "h2o", "o3", "co2", "ch4", "n2o", "cfc11", "cfc12"),
        required_source = true,
        required_rayleigh = false,
    ),
    (
        kind = "shortwave",
        key = :shortwave_32,
        path = "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc",
        expected_gpoints = 32,
        expected_bands = 5,
        required_gases = ("composite", "h2o", "o3", "co2", "ch4", "n2o"),
        required_source = false,
        required_rayleigh = true,
    ),
)

const OFFICIAL_ECCKD_RUNTIME_GASES = (:composite, :h2o, :o3, :co2, :ch4, :n2o, :cfc11, :cfc12)

function official_definition_path(spec; require = true)
    override_name = spec.kind == "longwave" ? "RH_ECCKD_LW_PATH" : "RH_ECCKD_SW_PATH"
    override = get(ENV, override_name, "")
    isempty(override) || return reference_path(override)
    return official_ecckd_definition_path(spec.key; require)
end

function file_status(spec)
    path = official_definition_path(spec; require = false)
    if path === nothing || !isfile(path)
        return (
            kind = spec.kind,
            path = spec.path,
            present = false,
            valid_schema = false,
            passed = false,
            status = "missing_file",
        )
    end

    definition = read_ecckd_definition(path)
    valid, errors = validate_ecckd_definition(definition; throw_on_error = false)
    summary = summarize_ecckd_definition(definition)
    gpoints = spec.kind == "longwave" ? summary.lw_gpoints : summary.sw_gpoints
    bands = spec.kind == "longwave" ? summary.lw_bands : summary.sw_bands
    required_gases_present = all(gas -> gas in summary.gases, spec.required_gases)
    source_ok = summary.source_tables_present == spec.required_source
    rayleigh_ok = summary.rayleigh_tables_present == spec.required_rayleigh
    passed = valid &&
             gpoints == spec.expected_gpoints &&
             bands == spec.expected_bands &&
             required_gases_present &&
             source_ok &&
             rayleigh_ok

    return (
        kind = spec.kind,
        path = spec.path,
        present = true,
        valid_schema = valid,
        schema_errors = errors,
        model_name = summary.model_name,
        version = summary.version,
        gpoints = gpoints,
        expected_gpoints = spec.expected_gpoints,
        bands = bands,
        expected_bands = spec.expected_bands,
        gases = summary.gases,
        required_gases = collect(spec.required_gases),
        required_gases_present = required_gases_present,
        source_tables_present = summary.source_tables_present,
        required_source_tables_present = spec.required_source,
        rayleigh_tables_present = summary.rayleigh_tables_present,
        required_rayleigh_tables_present = spec.required_rayleigh,
        passed = passed,
        status = passed ? "passed" : "failed_schema_expectation",
    )
end

function run_official_ecckd_files_check()
    files = [file_status(spec) for spec in OFFICIAL_ECCKD_FILES]
    runtime = runtime_model_status()
    return (
        case = "official_ecckd_definition_files_check",
        date = string(Dates.now()),
        status = all(file -> file.passed, files) && runtime.passed ? "passed" : "failed",
        files = files,
        runtime_model = runtime,
    )
end

function runtime_model_status()
    lw_path = official_definition_path(OFFICIAL_ECCKD_FILES[1]; require = false)
    sw_path = official_definition_path(OFFICIAL_ECCKD_FILES[2]; require = false)
    if lw_path === nothing || sw_path === nothing || !isfile(lw_path) || !isfile(sw_path)
        return (
            status = "missing_file",
            passed = false,
        )
    end

    model = read_ecckd_tabulated_gas_optics(lw_path, sw_path;
                                            gas_names = OFFICIAL_ECCKD_RUNTIME_GASES,
                                            h2o_mole_fraction = 0.005)
    pressure_interfaces = [10_000.0, 50_000.0, 100_000.0]
    composite = [(pressure_interfaces[k + 1] - pressure_interfaces[k]) /
                 (9.80665 * 0.001 * 28.9647) for k in 1:2]
    atmosphere = ColumnAtmosphere(
        pressure_layers = [20_000.0, 80_000.0],
        pressure_interfaces = pressure_interfaces,
        temperature_layers = [240.0, 290.0],
        temperature_interfaces = [230.0, 265.0, 300.0],
        gases = (
            composite = composite,
            h2o = 0.005 .* composite,
            o3 = [8.0e-6, 2.0e-8] .* composite,
            co2 = 4.2e-4 .* composite,
            ch4 = 1.9e-6 .* composite,
            n2o = 3.3e-7 .* composite,
            cfc11 = 2.3e-10 .* composite,
            cfc12 = 5.2e-10 .* composite,
        ),
        surface = (;),
        geometry = (;),
    )
    longwave = LongwaveOpticalProperties(zeros(64, 2), zeros(64, 2);
                                         weights = zeros(64))
    shortwave = ShortwaveOpticalProperties(zeros(32, 2);
                                           weights = zeros(32))
    optical_properties!(longwave, shortwave, model, atmosphere)

    finite = all(isfinite, longwave.optical_depth) &&
             all(isfinite, shortwave.optical_depth) &&
             all(isfinite, shortwave.rayleigh_optical_depth)
    nonnegative = all(longwave.optical_depth .>= 0) &&
                  all(shortwave.optical_depth .>= 0) &&
                  all(shortwave.rayleigh_optical_depth .>= 0)
    weights_normalized = isapprox(sum(longwave.weights), 1.0; atol = 1.0e-12) &&
                         isapprox(sum(shortwave.weights), 1.0; atol = 1.0e-12)
    passed = finite && nonnegative && weights_normalized
    source_table_present = model.longwave_source_table !== nothing
    source_table_finite = source_table_present && all(isfinite, model.longwave_source_table)
    return (
        status = passed ? "passed" : "failed",
        passed = passed,
        gas_names = String.(OFFICIAL_ECCKD_RUNTIME_GASES),
        h2o_mole_fraction = 0.005,
        pressure_grid_size = length(model.pressure_grid),
        temperature_grid_shape = collect(size(model.temperature_grid)),
        longwave_absorption_shape = collect(size(model.longwave_absorption)),
        shortwave_absorption_shape = collect(size(model.shortwave_absorption)),
        shortwave_rayleigh_coefficients = length(model.shortwave_rayleigh_molar_scattering),
        shortwave_rayleigh_coefficients_positive =
            maximum(model.shortwave_rayleigh_molar_scattering) > 0,
        shortwave_rayleigh_optical_depth_maximum =
            maximum(shortwave.rayleigh_optical_depth),
        longwave_source_table_present = source_table_present,
        longwave_source_table_shape = source_table_present ?
                                      collect(size(model.longwave_source_table)) :
                                      Int[],
        longwave_source_table_finite = source_table_finite,
        finite_optical_depths = finite,
        nonnegative_optical_depths = nonnegative,
        weights_normalized = weights_normalized,
    )
end

function markdown_official_ecckd_report(result)
    lines = String[
        "# Official ecCKD Definition Files Check",
        "",
        "Status: **$(result.status)**",
        "",
        "This check verifies that the package reader recognizes the official ecCKD definition files shipped in the ecRad checkout. It does not yet convert those definitions into production optical-depth kernels.",
        "",
        "| Kind | Status | G-points | Bands | Required gases present | Source tables | Rayleigh tables | Path |",
        "|---|---|---:|---:|---:|---:|---:|---|",
    ]
    for file in result.files
        gpoints = hasproperty(file, :gpoints) ? string(file.gpoints) : "missing"
        bands = hasproperty(file, :bands) ? string(file.bands) : "missing"
        gases = hasproperty(file, :required_gases_present) ? string(file.required_gases_present) : "false"
        source = hasproperty(file, :source_tables_present) ? string(file.source_tables_present) : "false"
        rayleigh = hasproperty(file, :rayleigh_tables_present) ? string(file.rayleigh_tables_present) : "false"
        push!(lines, "| $(file.kind) | $(file.status) | $gpoints | $bands | $gases | $source | $rayleigh | `$(file.path)` |")
    end
    append!(lines, [
        "",
        "## Runtime LUT Ingestion",
        "",
        "Status: **$(result.runtime_model.status)**",
        "",
        "| Field | Value |",
        "|---|---|",
        "| Gas names | `$(join(result.runtime_model.gas_names, ", "))` |",
        "| H2O mole fraction sample | $(result.runtime_model.h2o_mole_fraction) |",
        "| Pressure grid size | $(result.runtime_model.pressure_grid_size) |",
        "| Temperature grid shape | `$(result.runtime_model.temperature_grid_shape)` |",
        "| Longwave absorption shape | `$(result.runtime_model.longwave_absorption_shape)` |",
        "| Shortwave absorption shape | `$(result.runtime_model.shortwave_absorption_shape)` |",
        "| Shortwave Rayleigh coefficients | $(result.runtime_model.shortwave_rayleigh_coefficients) |",
        "| Shortwave Rayleigh coefficients positive | $(result.runtime_model.shortwave_rayleigh_coefficients_positive) |",
        "| Shortwave Rayleigh optical-depth max | $(result.runtime_model.shortwave_rayleigh_optical_depth_maximum) |",
        "| Longwave source table present | $(result.runtime_model.longwave_source_table_present) |",
        "| Longwave source table shape | `$(result.runtime_model.longwave_source_table_shape)` |",
        "| Longwave source table finite | $(result.runtime_model.longwave_source_table_finite) |",
        "| Finite optical depths | $(result.runtime_model.finite_optical_depths) |",
        "| Nonnegative optical depths | $(result.runtime_model.nonnegative_optical_depths) |",
        "| Weights normalized | $(result.runtime_model.weights_normalized) |",
    ])
    return join(lines, "\n") * "\n"
end

function official_ecckd_files_check_main()
    result = run_official_ecckd_files_check()
    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "official_ecckd_definition_files_check.json")
    md_path = joinpath(results_dir, "official_ecckd_definition_files_check.md")
    write(json_path, json_object(result))
    write(md_path, markdown_official_ecckd_report(result))

    print(markdown_official_ecckd_report(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    official_ecckd_files_check_main()
end
