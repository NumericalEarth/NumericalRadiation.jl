@testset "ecRad all-sky cloud-effect diagnostics artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_all_sky_cloud_effect_diagnostics.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    @test occursin("ecRad All-Sky Cloud-Effect Diagnostics", result)
    @test occursin("Boundary Cloud Effect Error", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results",
                         "ecrad_all_sky_cloud_effect_diagnostics.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results",
                       "ecrad_all_sky_cloud_effect_diagnostics.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_all_sky_cloud_effect_diagnostics\"", json)
    @test occursin("\"boundary_cloud_effects\":", json)
    @test occursin("\"profile_cloud_effects\":", json)
end
