module EcRadCloudlessAccuracyGateTestHelpers
include(joinpath(@__DIR__, "..", "validation", "ecrad_cloudless_accuracy_gate.jl"))
end

@testset "ecRad cloudless accuracy gate artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_cloudless_accuracy_gate.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    @test occursin("ecRad Cloudless Accuracy Gate", result)
    @test occursin("cloudless/no-aerosol", result)
    @test occursin("radiative_heating_lw_up", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_cloudless_accuracy_gate.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_cloudless_accuracy_gate.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_cloudless_accuracy_gate\"", json)
    @test occursin("\"reference_scope\": \"cloudless/no-aerosol first hard gate\"", json)
    @test occursin("\"ecckd_clear_sky_tropical_column\"", json)
    @test occursin("\"ecckd_rcemip_style_column_subset\"", json)
    @test occursin("\"status\": \"missing_references\"", json) ||
          occursin("\"status\": \"missing_candidate_outputs\"", json) ||
          occursin("\"status\": \"passed\"", json) ||
          occursin("\"status\": \"failed_threshold\"", json) ||
          occursin("\"status\": \"invalid_reference_schema\"", json)
end

@testset "ecRad cloudless gate case selection" begin
    selected = collect(getproperty.(EcRadCloudlessAccuracyGateTestHelpers.CLOUDLESS_CASES, :case))
    @test selected == [
        "ecckd_clear_sky_tropical_column",
        "ecckd_rcemip_style_column_subset",
    ]
    @test !("clear_sky_tropical_column" in selected)
    @test !("rcemip_style_column_subset" in selected)
    @test !("all_sky_tropical_column" in selected)
end
