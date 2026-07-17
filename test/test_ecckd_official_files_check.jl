using JSON

@testset "official ecCKD files validation artifact" begin
    root = normpath(joinpath(@__DIR__, ".."))
    script = joinpath(root, "validation", "ecckd_official_files_check.jl")
    test_project = Base.active_project()
    output = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)

    @test occursin("Official ecCKD Definition Files Check", output)
    @test occursin("Status: **passed**", output)
    @test occursin("longwave", output)
    @test occursin("shortwave", output)
    @test occursin("Runtime LUT Ingestion", output)

    json_path = joinpath(root, "validation", "results", "official_ecckd_definition_files_check.json")
    md_path = joinpath(root, "validation", "results", "official_ecckd_definition_files_check.md")
    @test isfile(json_path)
    @test isfile(md_path)

    result = JSON.parsefile(json_path)
    @test result["case"] == "official_ecckd_definition_files_check"
    @test result["status"] == "passed"
    @test Set(file["expected_gpoints"] for file in result["files"]) == Set([64, 32])
    @test all(file -> file["required_gases_present"], result["files"])

    runtime = result["runtime_model"]
    @test runtime["gas_names"] == ["composite", "h2o", "o3", "co2", "ch4", "n2o", "cfc11", "cfc12"]
    @test runtime["temperature_grid_shape"] == [53, 6]
    @test runtime["longwave_absorption_shape"] == [64, 8, 53, 6]
    @test runtime["shortwave_absorption_shape"] == [32, 8, 53, 6]
    @test runtime["shortwave_rayleigh_coefficients"] == 32
    @test runtime["shortwave_rayleigh_coefficients_positive"]
    @test runtime["longwave_source_table_present"]
    @test runtime["longwave_source_table_finite"]
    @test runtime["finite_optical_depths"]
    @test runtime["nonnegative_optical_depths"]
end
