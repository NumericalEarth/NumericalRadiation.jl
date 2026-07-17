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
