module EcRadCandidateSchemaTestHelpers
include(joinpath(@__DIR__, "..", "validation", "ecrad_candidate_schema.jl"))
end

module EcRadCandidateWriterTestHelpers
include(joinpath(@__DIR__, "..", "validation", "write_ecrad_candidates.jl"))
end

@testset "ecRad candidate schema artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_candidate_schema.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    @test occursin("ecRad Candidate Schema Check", result)
    @test occursin("radiative_heating_lw_up", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_candidate_schema.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_candidate_schema.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_candidate_schema\"", json)
    @test occursin("\"candidate_prefix\": \"radiative_heating_\"", json)
    @test occursin("\"status\": \"missing_references\"", json) ||
          occursin("\"status\": \"missing_or_mismatched_candidate_variables\"", json) ||
          occursin("\"status\": \"passed\"", json) ||
          occursin("\"status\": \"invalid_reference_schema\"", json)
end

@testset "ecRad candidate official gas amount conversions" begin
    pressure_interfaces = reshape([0.0, 9.80665], 2, 1)
    h2o = reshape([EcRadCandidateWriterTestHelpers.MOLAR_MASS_WATER], 1, 1)
    co2_pressure_interfaces = reshape(
        [0.0, 9.80665 * EcRadCandidateWriterTestHelpers.MOLAR_MASS_DRY_AIR],
        2,
        1,
    )
    co2 = reshape([1.0], 1, 1)

    h2o_moles = EcRadCandidateWriterTestHelpers.layer_moles_from_specific_humidity(
        h2o,
        pressure_interfaces,
    )
    air_moles = EcRadCandidateWriterTestHelpers.layer_air_moles(co2_pressure_interfaces)
    co2_moles = EcRadCandidateWriterTestHelpers.layer_moles_from_vmr(co2, air_moles)

    @test h2o_moles[1, 1] ≈ 1.0
    @test air_moles[1, 1] ≈ 1.0
    @test co2_moles[1, 1] ≈ 1.0
end

@testset "ecRad candidate schema shape checks" begin
    using NCDatasets

    mktempdir() do dir
        path = joinpath(dir, "candidate_schema.nc")
        NCDataset(path, "c") do dataset
            defDim(dataset, "interface", 3)
            defDim(dataset, "layer", 2)
            defDim(dataset, "wrong_interface", 4)

            reference = defVar(dataset, "lw_up", Float64, ("interface",))
            matching = defVar(dataset, "radiative_heating_lw_up", Float64, ("interface",))
            mismatched_reference = defVar(dataset, "lw_down", Float64, ("interface",))
            mismatched = defVar(dataset, "radiative_heating_lw_down", Float64, ("wrong_interface",))
            missing_candidate_reference = defVar(dataset, "heating_rate", Float64, ("layer",))

            reference[:] = [1.0, 2.0, 3.0]
            matching[:] = [1.0, 2.0, 3.0]
            mismatched_reference[:] = [1.0, 2.0, 3.0]
            mismatched[:] = [1.0, 2.0, 3.0, 4.0]
            missing_candidate_reference[:] = [0.1, 0.2]
        end

        matching = EcRadCandidateSchemaTestHelpers.candidate_schema_status(
            path,
            (name = "lw_up", candidate = "radiative_heating_lw_up"),
        )
        mismatched = EcRadCandidateSchemaTestHelpers.candidate_schema_status(
            path,
            (name = "lw_down", candidate = "radiative_heating_lw_down"),
        )
        missing = EcRadCandidateSchemaTestHelpers.candidate_schema_status(
            path,
            (name = "heating_rate", candidate = "radiative_heating_heating_rate"),
        )

        @test matching.status == "passed"
        @test matching.shape_matches
        @test matching.reference_shape == [3]
        @test mismatched.status == "shape_mismatch"
        @test !mismatched.shape_matches
        @test mismatched.reference_shape == [3]
        @test mismatched.candidate_shape == [4]
        @test missing.status == "missing_candidate_variable"
        @test !missing.shape_matches
    end
end
