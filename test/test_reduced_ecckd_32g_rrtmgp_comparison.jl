using JSON
using Test

@testset "32-g ecCKD RRTMGP comparison artifact" begin
    script = joinpath(@__DIR__, "..", "validation",
                      "reduced_ecckd_32g_rrtmgp_comparison.jl")
    test_project = Base.active_project()
    output = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)

    @test occursin("32-g ecCKD RRTMGP Comparison", output)
    @test occursin("Status: **passed**", output)
    @test occursin("RRTMGP role", output)

    json_path = joinpath(@__DIR__, "..", "validation", "results",
                         "reduced_ecckd_32g_rrtmgp_comparison.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results",
                       "reduced_ecckd_32g_rrtmgp_comparison.md")
    @test isfile(json_path)
    @test isfile(md_path)

    parsed = JSON.parsefile(json_path)
    @test parsed["case"] == "reduced_ecckd_32g_rrtmgp_comparison"
    @test parsed["status"] == "passed"
    @test occursin("official ecCKD 32-g", parsed["production_target"])
    @test occursin("FROZEN_DIAGNOSTICS.md", parsed["frozen_diagnostic"])
    @test parsed["official_32g_ecckd_hard_gate_passed"]
    @test parsed["rrtmgp_comparison_emitted"]
    @test occursin("not line-by-line truth", parsed["rrtmgp_role"])
    @test length(parsed["cases"]) >= 3

    cases = Dict(case["case"] => case for case in parsed["cases"])
    @test haskey(cases, "ecckd_clear_sky_tropical_column")
    @test haskey(cases, "ecckd_rcemip_style_column_subset")
    @test cases["ecckd_rcemip_style_column_subset"]["columns"] >= 32

    for case in parsed["cases"]
        @test case["candidate_vs_ecckd_reference"]["flux_rmse"] < 0.30
        @test case["candidate_vs_ecckd_reference"]["heating_rate_rmse"] < 0.05
        @test isfinite(case["candidate_vs_rrtmgp"]["flux_rmse"])
        @test isfinite(case["candidate_vs_rrtmgp"]["heating_rate_rmse"])
    end
end
