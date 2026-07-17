using JSON

@testset "reduced ecCKD leave-one-out refit breakdown" begin
    root = normpath(joinpath(@__DIR__, ".."))
    script = joinpath(root, "validation", "reduced_ecckd_leave_one_out_refit_breakdown.jl")
    test_project = Base.active_project()
    output = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)

    @test occursin("Reduced ecCKD Leave-One-Out Refit Breakdown", output)
    @test occursin("Limiting metric: `heating_rate_rmse`", output)

    json_path = joinpath(root, "validation", "results",
                         "reduced_ecckd_leave_one_out_refit_breakdown.json")
    md_path = joinpath(root, "validation", "results",
                       "reduced_ecckd_leave_one_out_refit_breakdown.md")
    @test isfile(json_path)
    @test isfile(md_path)

    result = JSON.parsefile(json_path)
    @test result["status"] == "failed_threshold"
    @test result["omitted_gpoint"] == 25
    @test result["ng_lw"] == 32
    @test result["ng_sw"] == 31
    @test result["worst_case"] == "ecckd_clear_sky_tropical_column"
    @test result["limiting_metric"] == "heating_rate_rmse"
    @test 12.33 < result["limiting_metric_ratio"] < 12.34
    @test result["objective_difference"] < 1.0e-10
    @test result["objective_best_omitted_gpoint"] == 23
    @test result["comparison_omitted_gpoints"] == Any[25, 23]
    @test length(result["comparison_breakdowns"]) == 2
    objective_best = only(filter(row -> row["omitted_gpoint"] == 23,
                                 result["comparison_breakdowns"]))
    @test objective_best["limiting_metric_ratio"] < 1.7
    @test objective_best["recomputed_objective"] < 1.7
    @test objective_best["worst_case"] == "ecckd_clear_sky_tropical_column"
end
