@testset "ecRad reference manifest artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_reference_manifest.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    @test occursin("ecRad Reference Manifest", result)
    @test occursin("clear_sky_tropical_column", result)
    @test occursin("rcemip_style_column_subset", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_reference_manifest.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_reference_manifest.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_reference_manifest\"", json)
    @test occursin("\"flux_rmse_w_m2\": 1.0", json)
    @test occursin("\"heating_rate_rmse_k_day\": 0.05", json)
    @test occursin("\"missing_reference_count\":", json)
    @test occursin("\"invalid_schema_count\":", json)
    @test occursin("\"schema_checker\": \"NCDatasets\"", json)
    @test occursin("\"schema_valid\":", json)
    @test occursin("\"missing_variables\":", json)
end
