@testset "reduced ecCKD size scan artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "reduced_ecckd_size_scan.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)

    @test occursin("Reduced ecCKD Size Scan", result)
    @test occursin("only_full_32_sw_passes", result) ||
          occursin("reduced_pass_found", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results", "reduced_ecckd_size_scan.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results", "reduced_ecckd_size_scan.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"radiative_heating_reduced_size_scan\"", json)
    @test occursin("\"ng_sw\": 16", json)
    @test occursin("\"ng_sw\": 32", json)
    @test occursin("\"passed_hard_thresholds\": true", json)
end
