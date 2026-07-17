@testset "host-model access points artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "access_points_check.jl")
    output = read(`$(Base.julia_cmd()) --project=$(Base.active_project()) $script`, String)
    @test occursin("Host-Model Access Points Check", output)
    @test occursin("Status: **passed**", output)
    @test occursin("Host can stop after gas optics", output)
    @test occursin("Host can replace solver or vertical integral", output)

    json_path = joinpath(@__DIR__, "..", "validation", "results", "access_points_check.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results", "access_points_check.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"host_model_access_points_check\"", json)
    @test occursin("\"status\": \"passed\"", json)
    @test occursin("\"host_can_stop_after_gas_optics\": true", json)
    @test occursin("\"host_can_replace_solver_or_vertical_integral\": true", json)
end
