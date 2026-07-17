@testset "ecRad accuracy diagnostics artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_accuracy_diagnostics.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    @test occursin("ecRad Accuracy Diagnostics", result)
    @test occursin("Worst Metrics", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_accuracy_diagnostics.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_accuracy_diagnostics.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_accuracy_diagnostics\"", json)
    @test occursin("\"gate_status\":", json)
    @test occursin("\"failed_metric_count\":", json)
    @test occursin("\"worst_metrics\":", json)
end
