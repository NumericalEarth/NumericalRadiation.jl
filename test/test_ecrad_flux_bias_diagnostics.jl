@testset "ecRad flux bias diagnostics artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_flux_bias_diagnostics.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    @test occursin("ecRad Flux Bias Diagnostics", result)
    @test occursin("Boundary Net-Flux Bias", result)
    @test occursin("Variable Bias", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results",
                         "ecrad_flux_bias_diagnostics.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results",
                       "ecrad_flux_bias_diagnostics.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_flux_bias_diagnostics\"", json)
    @test occursin("\"boundary_biases\":", json)
    @test occursin("\"variable_biases\":", json)
end
