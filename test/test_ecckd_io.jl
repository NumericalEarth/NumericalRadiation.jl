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
# --- end content of test_ecckd_forward.jl ---

end # module TestEcckdForward
