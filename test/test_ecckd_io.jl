# Consolidated from the original per-topic test files (Stage R2).
# Each original file's content is preserved verbatim inside its own module
# so top-level consts/functions from included check scripts cannot clash.

module TestEcckdDefinition
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_definition.jl ---
@testset "ecCKD definition schema core" begin
    metadata = (
        model_name = "toy-ecCKD",
        version = "0.1",
        dimensions = (
            lw_bands = 16,
            sw_bands = 14,
            lw_gpoints = 32,
            sw_gpoints = 16,
            gases = 3,
            pressure = 10,
            temperature = 8,
        ),
        variables = (
            lw_absorption = (:gases, :lw_gpoints, :pressure, :temperature),
            sw_absorption = (:gases, :sw_gpoints, :pressure, :temperature),
            lw_source = (:lw_gpoints, :temperature),
            sw_rayleigh = (:sw_gpoints, :pressure),
        ),
        attributes = (
            gas_names = ["h2o", "co2", "o3"],
        ),
    )

    definition = read_ecckd_definition(metadata)
    @test definition isa EcCKDDefinition
    @test validate_ecckd_definition(definition)

    summary = summarize_ecckd_definition(definition)
    @test summary isa EcCKDSchemaSummary
    @test summary.model_name == "toy-ecCKD"
    @test summary.version == "0.1"
    @test summary.lw_bands == 16
    @test summary.sw_bands == 14
    @test summary.lw_gpoints == 32
    @test summary.sw_gpoints == 16
    @test summary.gases == ["h2o", "co2", "o3"]
    @test summary.pressure_grid_size == 10
    @test summary.temperature_grid_size == 8
    @test summary.source_tables_present
    @test summary.rayleigh_tables_present

    invalid = EcCKDDefinition(
        model_name = "invalid",
        dimensions = (lw_bands = 16, gases = 1),
        variables = (;),
    )
    valid, errors = validate_ecckd_definition(invalid; throw_on_error = false)
    @test !valid
    @test any(contains("sw_bands"), errors)
    @test any(contains("longwave absorption"), errors)
    @test_throws ArgumentError validate_ecckd_definition(invalid)

    bad_gases = EcCKDDefinition(
        model_name = "bad-gases",
        dimensions = (
            lw_bands = 1,
            sw_bands = 1,
            lw_gpoints = 1,
            sw_gpoints = 1,
            gases = 2,
            pressure = 1,
            temperature = 1,
        ),
        variables = (
            lw_absorption = (:gases, :lw_gpoints, :pressure, :temperature),
            sw_absorption = (:gases, :sw_gpoints, :pressure, :temperature),
        ),
        attributes = (gas_names = ["h2o"],),
    )
    valid_gases, gas_errors = validate_ecckd_definition(bad_gases; throw_on_error = false)
    @test !valid_gases
    @test any(contains("gas_names length"), gas_errors)

    try
        read_ecckd_definition("missing-ecckd.nc")
        @test false
    catch err
        message = sprint(showerror, err)
        if isnothing(Base.get_extension(NumericalRadiation, :NumericalRadiationNCDatasetsExt))
            @test err isa ArgumentError
            @test occursin("load NCDatasets.jl", message)
        else
            @test occursin("missing-ecckd.nc", message)
        end
    end
end
# --- end content of test_ecckd_definition.jl ---

end # module TestEcckdDefinition

module TestEcckdArtifacts
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_artifacts.jl ---
const ABR_ROOT_FOR_ARTIFACT_TEST = normpath(joinpath(@__DIR__, ".."))
if Base.find_package("NumericalRadiation") === nothing
    push!(LOAD_PATH, ABR_ROOT_FOR_ARTIFACT_TEST)
end

using NumericalRadiation

@testset "official ecCKD artifact resolver" begin
    inventory = official_ecckd_model_inventory()
    @test "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc" in inventory
    @test "ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc" in inventory

    root = ecrad_data_path(require = true)
    @test isdir(root)

    mktempdir() do temp_root
        withenv("RH_ECRAD_DATA_PATH" => temp_root) do
            @test ecrad_data_path(require = true) == normpath(temp_root)
        end
    end

    mktempdir() do temp_root
        filename = "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc"
        nested_data = joinpath(temp_root, "ecrad-archive", "data")
        mkpath(nested_data)
        write(joinpath(nested_data, filename), "")
        withenv("RH_ECRAD_DATA_PATH" => temp_root) do
            @test official_ecckd_definition_path(filename; require = true) ==
                  normpath(joinpath(nested_data, filename))
        end
    end

    mktempdir() do temp_root
        missing_root = joinpath(temp_root, "missing-ecckd")
        @test NumericalRadiation._source_root_with_file(missing_root, "README.md") === nothing
    end

    source_root = ecckd_source_path(require = true)
    @test isfile(joinpath(source_root, "src", "ecckd", "optimize_lut.cpp"))

    paths = official_ecckd_definition_paths(require = true)
    @test isfile(paths.longwave)
    @test isfile(paths.shortwave)
    @test basename(paths.longwave) == "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc"
    @test basename(paths.shortwave) == "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc"

    @test_throws ArgumentError official_ecckd_definition_path(:not_a_model; require = false)
end
# --- end content of test_ecckd_artifacts.jl ---

end # module TestEcckdArtifacts

module TestEcckdNcdatasetsExt
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_ncdatasets_ext.jl ---
using NCDatasets

@testset "NetCDF readers accept any AbstractString path" begin
    # The extension specializes `::String`. Without a funnel in the package stub,
    # a `SubString` misses it and is told to load NCDatasets — which is loaded
    # here — so assert the two reach the same reader.
    paths = official_ecckd_definition_paths(require = false)
    if paths.longwave !== nothing && isfile(paths.longwave)
        as_substring = strip(" " * paths.longwave * " ")
        @test as_substring isa SubString{String}
        @test as_substring == paths.longwave

        from_string = read_ecckd_definition(String(paths.longwave))
        from_substring = read_ecckd_definition(as_substring)
        @test from_substring isa EcCKDDefinition
        @test from_substring.model_name == from_string.model_name
        @test from_substring.dimensions == from_string.dimensions

        mapping_string = read_ecckd_spectral_mapping(String(paths.longwave))
        mapping_substring = read_ecckd_spectral_mapping(as_substring)
        @test mapping_substring isa EcCKDSpectralMapping
        @test mapping_substring.wavenumber1 == mapping_string.wavenumber1

        if paths.shortwave !== nothing && isfile(paths.shortwave)
            sw_substring = strip(" " * paths.shortwave * " ")
            model = read_ecckd_tabulated_gas_optics(as_substring, sw_substring)
            @test model isa EcCKDTabulatedGasOpticsModel
        end
    end

    # A path that is not a `String` must still reach the reader, so a missing
    # file has to report the missing file rather than a missing extension.
    missing_substring = strip(" " * tempname() * "-absent.nc ")
    for reader in (read_ecckd_definition, read_ecckd_spectral_mapping,
                   read_cloud_scattering_table)
        err = try
            reader(missing_substring)
            nothing
        catch caught
            caught
        end
        @test err !== nothing
        @test !occursin("load NCDatasets.jl", sprint(showerror, err))
    end
end

@testset "NCDatasets ecCKD reader extension" begin
    path = tempname() * ".nc"

    NCDataset(path, "c") do ds
        defDim(ds, "lw_bands", 2)
        defDim(ds, "sw_bands", 3)
        defDim(ds, "lw_gpoints", 4)
        defDim(ds, "sw_gpoints", 5)
        defDim(ds, "gases", 2)
        defDim(ds, "pressure", 6)
        defDim(ds, "temperature", 7)

        defVar(ds, "lw_absorption", Float64,
               ("gases", "lw_gpoints", "pressure", "temperature"))
        defVar(ds, "sw_absorption", Float64,
               ("gases", "sw_gpoints", "pressure", "temperature"))
        defVar(ds, "lw_source", Float64, ("lw_gpoints", "temperature"))
        defVar(ds, "sw_rayleigh", Float64, ("sw_gpoints", "pressure"))

        ds.attrib["model_name"] = "toy-netcdf-ecCKD"
        ds.attrib["version"] = "0.2"
        ds.attrib["gas_names"] = ["h2o", "co2"]
    end

    definition = read_ecckd_definition(path)
    @test definition isa EcCKDDefinition
    @test validate_ecckd_definition(definition)

    summary = summarize_ecckd_definition(definition)
    @test summary.model_name == "toy-netcdf-ecCKD"
    @test summary.version == "0.2"
    @test summary.lw_bands == 2
    @test summary.sw_bands == 3
    @test summary.lw_gpoints == 4
    @test summary.sw_gpoints == 5
    @test summary.gases == ["h2o", "co2"]
    @test summary.pressure_grid_size == 6
    @test summary.temperature_grid_size == 7
    @test summary.source_tables_present
    @test summary.rayleigh_tables_present
end

@testset "official ecCKD runtime LUT ingestion" begin
    paths = official_ecckd_definition_paths(require = false)
    lw_path = paths.longwave
    sw_path = paths.shortwave

    if lw_path !== nothing && sw_path !== nothing && isfile(lw_path) && isfile(sw_path)
        model = read_ecckd_tabulated_gas_optics(lw_path, sw_path;
                                                gas_names = (:h2o, :co2),
                                                h2o_mole_fraction = 0.005)
        @test model isa EcCKDTabulatedGasOpticsModel
        @test size(model.longwave_absorption) == (64, 2, 53, 6)
        @test size(model.shortwave_absorption) == (32, 2, 53, 6)
        @test length(model.h2o_mole_fraction_grid) == 12
        @test size(model.longwave_h2o_absorption) == (64, 53, 6, 12)
        @test size(model.shortwave_h2o_absorption) == (32, 53, 6, 12)
        @test all(iszero, model.longwave_absorption[:, 1, :, :])
        @test all(iszero, model.shortwave_absorption[:, 1, :, :])
        @test size(model.temperature_grid) == (53, 6)
        @test model.pressure_grid[begin] < model.pressure_grid[end]
        @test all(isfinite, model.longwave_absorption)
        @test all(isfinite, model.shortwave_absorption)
        @test length(model.shortwave_rayleigh_molar_scattering) == 32
        @test maximum(model.shortwave_rayleigh_molar_scattering) > 0
        @test sum(model.longwave_weights) ≈ 1.0
        @test sum(model.shortwave_weights) ≈ 1.0

        atmosphere = ColumnAtmosphere(
            pressure_layers = [20_000.0, 80_000.0],
            pressure_interfaces = [10_000.0, 50_000.0, 100_000.0],
            temperature_layers = [240.0, 290.0],
            temperature_interfaces = [230.0, 265.0, 300.0],
            gases = (
                h2o = [1.0e-3, 5.0e-3],
                co2 = [4.0e-4, 4.0e-4],
            ),
            surface = (;),
            geometry = (;),
        )
        longwave = LongwaveOpticalProperties(zeros(64, 2), zeros(64, 2);
                                             weights = zeros(64))
        shortwave = ShortwaveOpticalProperties(zeros(32, 2);
                                               weights = zeros(32))
        optical_properties!(longwave, shortwave, model, atmosphere)

        @test all(isfinite, longwave.optical_depth)
        @test all(isfinite, shortwave.optical_depth)
        @test all(longwave.optical_depth .>= 0)
        @test all(shortwave.optical_depth .>= 0)
        @test all(isfinite, shortwave.rayleigh_optical_depth)
        @test all(shortwave.rayleigh_optical_depth .>= 0)
        @test maximum(shortwave.rayleigh_optical_depth) > 0
    else
        @info "Skipping official ecCKD runtime LUT ingestion check; ecRad data files are not present" lw_path sw_path
        @test_skip "official ecCKD runtime LUT files are not present"
    end
end

@testset "official ecCKD definition files" begin
    paths = official_ecckd_definition_paths(require = false)
    lw_path = paths.longwave
    sw_path = paths.shortwave

    if lw_path !== nothing && sw_path !== nothing && isfile(lw_path) && isfile(sw_path)
        lw = read_ecckd_definition(lw_path)
        sw = read_ecckd_definition(sw_path)

        @test validate_ecckd_definition(lw)
        @test validate_ecckd_definition(sw)

        lw_summary = summarize_ecckd_definition(lw)
        sw_summary = summarize_ecckd_definition(sw)

        @test lw_summary.lw_gpoints == 64
        @test lw_summary.lw_bands == 13
        @test lw_summary.sw_gpoints == 0
        @test lw_summary.source_tables_present
        @test "h2o" in lw_summary.gases
        @test "co2" in lw_summary.gases

        @test sw_summary.sw_gpoints == 32
        @test sw_summary.sw_bands == 5
        @test sw_summary.lw_gpoints == 0
        @test sw_summary.rayleigh_tables_present
        @test "h2o" in sw_summary.gases
        @test "co2" in sw_summary.gases
    else
        @info "Skipping official ecCKD definition file checks; ecRad data files are not present" lw_path sw_path
        @test_skip "official ecCKD definition files are not present"
    end
end
# --- end content of test_ecckd_ncdatasets_ext.jl ---

end # module TestEcckdNcdatasetsExt

module TestEcckdModelInventory
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_model_inventory.jl ---
using JSON

module EcckdModelInventoryValidation
include(joinpath(@__DIR__, "ecckd_model_inventory.jl"))
end

@testset "official ecCKD model inventory artifact" begin
    results_dir = mktempdir()
    json_path = joinpath(results_dir, "ecckd_model_inventory.json")
    md_path = joinpath(results_dir, "ecckd_model_inventory.md")
    previous = get(ENV, "NUMERICAL_RADIATION_VALIDATION_RESULTS_DIR", nothing)
    ENV["NUMERICAL_RADIATION_VALIDATION_RESULTS_DIR"] = results_dir
    try
        redirect_stdout(devnull) do
            EcckdModelInventoryValidation.ecckd_model_inventory_main()
        end
    finally
        if previous === nothing
            delete!(ENV, "NUMERICAL_RADIATION_VALIDATION_RESULTS_DIR")
        else
            ENV["NUMERICAL_RADIATION_VALIDATION_RESULTS_DIR"] = previous
        end
    end

    @test isfile(json_path)
    @test isfile(md_path)
    output = read(md_path, String)
    @test occursin("ecCKD Model Inventory", output)
    @test occursin("Status: **passed**", output)
    @test occursin("ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc", output)
    @test occursin("ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc", output)

    result = JSON.parsefile(json_path)
    @test result["case"] == "ecckd_model_inventory"
    @test result["status"] == "passed"
    @test length(result["entries"]) == 6

    entries = Dict(entry["filename"] => entry for entry in result["entries"])
    @test sort([entry["gpoints"] for entry in result["entries"]]) == [32, 32, 32, 64, 64, 96]
    @test entries["ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc"]["source_tables_present"]
    @test !entries["ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc"]["rayleigh_tables_present"]
    @test entries["ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc"]["source_tables_present"]
    @test !entries["ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc"]["rayleigh_tables_present"]
    for filename in (
        "ecckd-1.0_sw_climate_rgb-32b_ckd-definition.nc",
        "ecckd-1.2_sw_climate_window-64b_ckd-definition.nc",
        "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc",
        "ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc",
    )
        @test !entries[filename]["source_tables_present"]
        @test entries[filename]["rayleigh_tables_present"]
    end
end
# --- end content of test_ecckd_model_inventory.jl ---

end # module TestEcckdModelInventory

module TestEcckdModelSelectionInterface
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_model_selection_interface.jl ---
@testset "ecCKD model selection interface" begin
    specs = official_ecckd_model_specs()
    @test haskey(specs, :climate_32x32)
    @test haskey(specs, :climate_64x64)
    @test haskey(specs, :climate_64x96)

    spec = official_ecckd_model_spec("32x96")
    @test spec.name == :climate_32x96
    @test spec.longwave == :longwave_32
    @test spec.shortwave == :shortwave_96

    @test official_ecckd_model_spec(:climate_64x32).longwave == :longwave_64
    @test official_ecckd_model_spec("64x96").shortwave == :shortwave_96
    @test_throws ArgumentError official_ecckd_model_spec("16x16")

    paths = official_ecckd_definition_paths("32x32"; require = false)
    @test hasproperty(paths, :longwave)
    @test hasproperty(paths, :shortwave)

    if isnothing(paths.longwave) || isnothing(paths.shortwave)
        @test read_official_ecckd_gas_optics("32x32"; require = false) === nothing
    elseif isnothing(Base.get_extension(NumericalRadiation, :NumericalRadiationNCDatasetsExt))
        @test_throws ArgumentError read_official_ecckd_gas_optics("32x32")
    else
        model = read_official_ecckd_gas_optics("32x32")
        @test model isa EcCKDTabulatedGasOpticsModel
        @test length(model.longwave_weights) == 32
        @test length(model.shortwave_weights) == 32
    end
end
# --- end content of test_ecckd_model_selection_interface.jl ---

end # module TestEcckdModelSelectionInterface

module TestEcckdForward
using Test
using NumericalRadiation
using Dates

Base.@noinline function run_optical_properties!(longwave, shortwave, model, atmosphere)
    optical_properties!(longwave, shortwave, model, atmosphere)
    return nothing
end

Base.@noinline function optical_properties_allocations(longwave, shortwave, model, atmosphere)
    return @allocated run_optical_properties!(longwave, shortwave, model, atmosphere)
end

# --- begin content of test_ecckd_forward.jl ---
@testset "ecCKD-style forward gas optics" begin
    nlayers = 3
    atmosphere = ColumnAtmosphere(
        pressure_layers = [20_000.0, 50_000.0, 80_000.0],
        pressure_interfaces = [10_000.0, 35_000.0, 65_000.0, 95_000.0],
        temperature_layers = [220.0, 260.0, 300.0],
        temperature_interfaces = [210.0, 240.0, 280.0, 305.0],
        gases = (
            h2o = [1.0, 2.0, 3.0],
            co2 = 4.0,
        ),
        surface = (;),
        geometry = (;),
    )

    model = EcCKDGasOpticsModel(
        gas_names = (:h2o, :co2),
        longwave_absorption = [0.1 0.01;
                               0.2 0.02],
        shortwave_absorption = [0.03 0.003],
        longwave_source_scale = [0.5, 1.0],
        longwave_weights = [0.25, 0.75],
        shortwave_weights = [1.0],
    )

    longwave = LongwaveOpticalProperties(zeros(2, nlayers), zeros(2, nlayers);
                                         weights = zeros(2))
    shortwave = ShortwaveOpticalProperties(zeros(1, nlayers); weights = zeros(1))

    returned = optical_properties!(longwave, shortwave, model, atmosphere)
    @test returned == (longwave, shortwave)

    @test longwave.optical_depth ≈ [0.14 0.24 0.34;
                                    0.28 0.48 0.68]
    @test shortwave.optical_depth ≈ [0.042 0.072 0.102]
    @test longwave.weights == [0.25, 0.75]
    @test shortwave.weights == [1.0]

    stefan_boltzmann = 5.670374419e-8
    @test longwave.source[1, :] ≈ 0.5 .* stefan_boltzmann .* atmosphere.temperature_layers .^ 4
    @test longwave.source[2, :] ≈ stefan_boltzmann .* atmosphere.temperature_layers .^ 4

    # Julia 1.10 specializes the allocation measurement separately.
    optical_properties_allocations(longwave, shortwave, model, atmosphere)
    @test optical_properties_allocations(longwave, shortwave, model, atmosphere) == 0

    bad_longwave = LongwaveOpticalProperties(zeros(1, nlayers), zeros(1, nlayers);
                                             weights = zeros(1))
    @test_throws DimensionMismatch optical_properties!(bad_longwave, shortwave, model, atmosphere)

    @test_throws DimensionMismatch EcCKDGasOpticsModel(
        gas_names = (:h2o,),
        longwave_absorption = [0.1 0.01],
        shortwave_absorption = reshape([0.03], 1, 1),
    )
end

@testset "ecCKD-style tabulated longwave source table" begin
    atmosphere = ColumnAtmosphere(
        pressure_layers = [15_000.0],
        pressure_interfaces = [10_000.0, 20_000.0],
        temperature_layers = [275.0],
        temperature_interfaces = [250.0, 300.0],
        gases = (h2o = [1.0], co2 = [1.0]),
        surface = (;),
        geometry = (;),
    )
    model = EcCKDTabulatedGasOpticsModel(
        gas_names = (:h2o, :co2),
        pressure_grid = [10_000.0, 20_000.0],
        temperature_grid = [250.0, 300.0],
        longwave_absorption = fill(0.1, 2, 2, 2, 2),
        shortwave_absorption = fill(0.01, 1, 2, 2, 2),
        longwave_source_temperature_grid = [250.0, 300.0],
        longwave_source_table = [10.0 20.0;
                                 100.0 200.0],
        longwave_weights = [0.5, 0.5],
        shortwave_weights = [1.0],
    )
    longwave = LongwaveOpticalProperties(zeros(2, 1), zeros(2, 1);
                                         weights = zeros(2))
    shortwave = ShortwaveOpticalProperties(zeros(1, 1); weights = zeros(1))

    optical_properties!(longwave, shortwave, model, atmosphere)

    @test longwave.source[:, 1] ≈ [15.0, 150.0]
end

@testset "ecCKD-style tabulated shortwave Rayleigh channel" begin
    atmosphere = ColumnAtmosphere(
        pressure_layers = [15_000.0],
        pressure_interfaces = [10_000.0, 20_000.0],
        temperature_layers = [275.0],
        temperature_interfaces = [250.0, 300.0],
        gases = (h2o = [1.0], co2 = [1.0]),
        surface = (;),
        geometry = (;),
    )
    model = EcCKDTabulatedGasOpticsModel(
        gas_names = (:h2o, :co2),
        pressure_grid = [10_000.0, 20_000.0],
        temperature_grid = [250.0, 300.0],
        longwave_absorption = fill(0.1, 1, 2, 2, 2),
        shortwave_absorption = fill(0.01, 2, 2, 2, 2),
        shortwave_rayleigh_molar_scattering = [1.0e-8, 2.0e-8],
        longwave_weights = [1.0],
        shortwave_weights = [0.5, 0.5],
    )
    longwave = LongwaveOpticalProperties(zeros(1, 1), zeros(1, 1);
                                         weights = zeros(1))
    shortwave = ShortwaveOpticalProperties(zeros(2, 1); weights = zeros(2))

    optical_properties!(longwave, shortwave, model, atmosphere)

    @test shortwave.rayleigh_optical_depth[1, 1] > 0
    @test shortwave.rayleigh_optical_depth[2, 1] ≈ 2shortwave.rayleigh_optical_depth[1, 1]
end

@testset "ecCKD-style tabulated gas optics" begin
    nlayers = 2
    pressure_grid = [10_000.0, 20_000.0]
    temperature_grid = [250.0, 300.0]

    longwave_table = zeros(2, 2, 2, 2)
    shortwave_table = zeros(1, 2, 2, 2)
    for ig in axes(longwave_table, 1), j in axes(longwave_table, 2),
        ip in axes(longwave_table, 3), it in axes(longwave_table, 4)
        longwave_table[ig, j, ip, it] =
            100ig + 10j + 0.001pressure_grid[ip] + 0.01temperature_grid[it]
    end
    for ig in axes(shortwave_table, 1), j in axes(shortwave_table, 2),
        ip in axes(shortwave_table, 3), it in axes(shortwave_table, 4)
        shortwave_table[ig, j, ip, it] =
            10ig + j + 0.0001pressure_grid[ip] + 0.001temperature_grid[it]
    end

    atmosphere = ColumnAtmosphere(
        pressure_layers = [15_000.0, 20_000.0],
        pressure_interfaces = [10_000.0, 17_500.0, 25_000.0],
        temperature_layers = [275.0, 250.0],
        temperature_interfaces = [260.0, 280.0, 245.0],
        gases = (
            h2o = [2.0, 3.0],
            co2 = 4.0,
        ),
        surface = (;),
        geometry = (;),
    )

    model = EcCKDTabulatedGasOpticsModel(
        gas_names = (:h2o, :co2),
        pressure_grid = pressure_grid,
        temperature_grid = temperature_grid,
        longwave_absorption = longwave_table,
        shortwave_absorption = shortwave_table,
        longwave_source_scale = [1.0, 2.0],
        longwave_weights = [0.4, 0.6],
        shortwave_weights = [1.0],
    )

    longwave = LongwaveOpticalProperties(zeros(2, nlayers), zeros(2, nlayers);
                                         weights = zeros(2))
    shortwave = ShortwaveOpticalProperties(zeros(1, nlayers); weights = zeros(1))

    optical_properties!(longwave, shortwave, model, atmosphere)

    lw_coeff(ig, j, p, t) = 100ig + 10j + 0.001p + 0.01t
    sw_coeff(ig, j, p, t) = 10ig + j + 0.0001p + 0.001t
    @test longwave.optical_depth[1, 1] ≈
          lw_coeff(1, 1, 15_000.0, 275.0) * 2.0 +
          lw_coeff(1, 2, 15_000.0, 275.0) * 4.0
    @test longwave.optical_depth[2, 2] ≈
          lw_coeff(2, 1, 20_000.0, 250.0) * 3.0 +
          lw_coeff(2, 2, 20_000.0, 250.0) * 4.0
    @test shortwave.optical_depth[1, 1] ≈
          sw_coeff(1, 1, 15_000.0, 275.0) * 2.0 +
          sw_coeff(1, 2, 15_000.0, 275.0) * 4.0
    @test longwave.weights == [0.4, 0.6]
    @test shortwave.weights == [1.0]

    stefan_boltzmann = 5.670374419e-8
    @test longwave.source[1, :] ≈ stefan_boltzmann .* atmosphere.temperature_layers .^ 4
    @test longwave.source[2, :] ≈ 2 .* stefan_boltzmann .* atmosphere.temperature_layers .^ 4

    # Julia 1.10 specializes the allocation measurement separately.
    optical_properties_allocations(longwave, shortwave, model, atmosphere)
    @test optical_properties_allocations(longwave, shortwave, model, atmosphere) == 0

    @test_throws DimensionMismatch EcCKDTabulatedGasOpticsModel(
        gas_names = (:h2o, :co2),
        pressure_grid = pressure_grid,
        temperature_grid = temperature_grid,
        longwave_absorption = zeros(2, 2, 1, 2),
        shortwave_absorption = shortwave_table,
    )
end

# Bit-exact pin on the tabulated interpolation path. `optical_properties!` hoists
# every interpolation bracket out of its g-point and gas loops, which is only
# valid if it reproduces per-point bracketing to the last bit — approximate
# comparison would hide exactly the rounding drift that invalidates the hoist.
# Reference values were produced by the pre-hoist implementation; regenerate them
# deliberately (and say so) if the interpolation itself is ever meant to change.
@testset "ecCKD tabulated interpolation is bit-exact" begin
    pressure_grid = [5_000.0, 20_000.0, 60_000.0, 100_000.0]
    np, nt, nh2o = 4, 3, 3
    ng_lw, ng_sw = 3, 2

    make_atmosphere(gases) = ColumnAtmosphere(
        pressure_layers = [7_500.0, 33_000.0, 88_000.0],
        pressure_interfaces = [1_000.0, 14_000.0, 52_000.0, 101_000.0],
        temperature_layers = [217.3, 263.9, 291.4],
        temperature_interfaces = [205.1, 231.7, 279.2, 297.8],
        gases = gases,
        surface = (;),
        geometry = (;),
    )

    lw_entry(ig, j, p, t) = 1e-4 * (7ig + 3j) * (1 + 1e-5 * p) * (1 + 1e-3 * t)
    sw_entry(ig, j, p, t) = 1e-5 * (5ig + 2j) * (1 + 2e-5 * p) * (1 + 2e-3 * t)

    @testset "vector temperature grid" begin
        temperature_grid = [200.0, 250.0, 300.0]
        ngas = 2
        model = EcCKDTabulatedGasOpticsModel(
            gas_names = (:h2o, :co2),
            pressure_grid = pressure_grid,
            temperature_grid = temperature_grid,
            longwave_absorption = [lw_entry(ig, j, pressure_grid[ip], temperature_grid[it])
                                   for ig in 1:ng_lw, j in 1:ngas, ip in 1:np, it in 1:nt],
            shortwave_absorption = [sw_entry(ig, j, pressure_grid[ip], temperature_grid[it])
                                    for ig in 1:ng_sw, j in 1:ngas, ip in 1:np, it in 1:nt],
            longwave_source_scale = [0.7, 1.0, 1.3],
            longwave_weights = [0.2, 0.3, 0.5],
            shortwave_weights = [0.45, 0.55],
        )
        atmosphere = make_atmosphere((h2o = [3.1, 12.7, 41.9], co2 = 8.3))
        longwave = LongwaveOpticalProperties(zeros(ng_lw, 3), zeros(ng_lw, 3);
                                             weights = zeros(ng_lw))
        shortwave = ShortwaveOpticalProperties(zeros(ng_sw, 3); weights = zeros(ng_sw))
        optical_properties!(longwave, shortwave, model, atmosphere)

        @test longwave.optical_depth == [
            0.018176419275000005  0.03948638463  0.12792246808000002;
            0.028619027325000004  0.06419689353  0.21323648456000002;
            0.03906163537500001  0.08890740243  0.29855050104
        ]
        @test longwave.source == [
            88.50110269925781  192.51622517560816  286.19890405283525;
            126.43014671322547  275.0231788222974  408.85557721833607;
            164.35919072719312  357.5301324689866  531.5122503838369
        ]
        @test shortwave.optical_depth == [
            0.0015903975600000003  0.0041491381280000005  0.016076183040000004;
            0.0025307778600000006  0.006812093528000001  0.027041188320000006
        ]

        optical_properties_allocations(longwave, shortwave, model, atmosphere)
        @test optical_properties_allocations(longwave, shortwave, model, atmosphere) == 0
    end

    @testset "matrix temperature grid with dynamic H2O" begin
        # Pressure-dependent temperature grid: origin shifts with pressure,
        # uniform step, which is the layout the official ecCKD LUTs use.
        temperature_grid = [180.0 + 30.0 * (ip - 1) + 40.0 * (it - 1)
                            for ip in 1:np, it in 1:nt]
        h2o_grid = [1e-6, 1e-4, 1e-2]
        source_temperature_grid = [180.0, 240.0, 300.0]
        ngas = 3
        model = EcCKDTabulatedGasOpticsModel(
            gas_names = (:h2o, :co2, :composite),
            pressure_grid = pressure_grid,
            temperature_grid = temperature_grid,
            h2o_mole_fraction_grid = h2o_grid,
            gas_reference_mole_fractions = [0.0, 4.0e-4, 0.0],
            longwave_absorption = [lw_entry(ig, j, pressure_grid[ip], temperature_grid[ip, it])
                                   for ig in 1:ng_lw, j in 1:ngas, ip in 1:np, it in 1:nt],
            shortwave_absorption = [sw_entry(ig, j, pressure_grid[ip], temperature_grid[ip, it])
                                    for ig in 1:ng_sw, j in 1:ngas, ip in 1:np, it in 1:nt],
            longwave_h2o_absorption = [1e-3 * ig * (1 + 1e-5 * pressure_grid[ip]) *
                                       (1 + 1e-3 * temperature_grid[ip, it]) * (1 + 10ih)
                                       for ig in 1:ng_lw, ip in 1:np, it in 1:nt, ih in 1:nh2o],
            shortwave_h2o_absorption = [1e-4 * ig * (1 + 2e-5 * pressure_grid[ip]) *
                                        (1 + 2e-3 * temperature_grid[ip, it]) * (1 + 5ih)
                                        for ig in 1:ng_sw, ip in 1:np, it in 1:nt, ih in 1:nh2o],
            shortwave_rayleigh_molar_scattering = [1.1e-6, 3.7e-6],
            longwave_source_temperature_grid = source_temperature_grid,
            longwave_source_table = [1.0 * (ig + 2) * st^2
                                     for ig in 1:ng_lw, st in source_temperature_grid],
            longwave_weights = [0.2, 0.3, 0.5],
            shortwave_weights = [0.45, 0.55],
        )
        atmosphere = make_atmosphere((h2o = [3.1, 12.7, 41.9], co2 = 8.3,
                                      composite = [4.2e2, 1.1e3, 2.6e3]))
        longwave = LongwaveOpticalProperties(zeros(ng_lw, 3), zeros(ng_lw, 3);
                                             source_top = zeros(ng_lw, 3),
                                             source_bottom = zeros(ng_lw, 3),
                                             weights = zeros(ng_lw))
        shortwave = ShortwaveOpticalProperties(zeros(ng_sw, 3); weights = zeros(ng_sw))
        optical_properties!(longwave, shortwave, model, atmosphere)

        @test longwave.optical_depth == [
            1.038988107153748  3.7047430420059544  11.585312434596617;
            1.5665497545609188  5.709921054577294  18.215134429347714;
            2.0941114019680898  7.715099067148635  24.84495642409881
        ]
        @test longwave.source == [
            144198.0  211517.99999999997  256067.99999999994;
            192264.0  282023.99999999994  341423.99999999994;
            240330.0  352529.99999999994  426779.99999999994
        ]
        @test longwave.source_top == [
            128826.0  162342.0  236303.99999999997;
            171768.0  216456.0  315072.0;
            214710.0  270570.0  393839.99999999994
        ]
        @test longwave.source_bottom == [
            162342.0  236303.99999999997  266436.0;
            216456.0  315072.0  355248.0;
            270570.0  393839.99999999994  444060.0
        ]
        @test shortwave.optical_depth == [
            0.08880985743526217  0.3703675106164617  1.2739652348396093;
            0.1339252653870883  0.5682224044917201  1.9866223473795563
        ]

        optical_properties_allocations(longwave, shortwave, model, atmosphere)
        @test optical_properties_allocations(longwave, shortwave, model, atmosphere) == 0
    end
end
# --- end content of test_ecckd_forward.jl ---

end # module TestEcckdForward
