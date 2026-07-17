using JSON

@testset "reduced ecCKD leave-one-out heating residual localization" begin
    root = normpath(joinpath(@__DIR__, ".."))
    script = joinpath(root, "validation",
                      "reduced_ecckd_leave_one_out_heating_residual_localization.jl")
    json_path = joinpath(root, "validation", "results",
                         "reduced_ecckd_leave_one_out_heating_residual_localization.json")
    md_path = joinpath(root, "validation", "results",
                       "reduced_ecckd_leave_one_out_heating_residual_localization.md")
    if !isfile(json_path) || stat(json_path).mtime < stat(script).mtime
        test_project = Base.active_project()
        read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    end

    @test isfile(json_path)
    @test isfile(md_path)

    result = JSON.parsefile(json_path)
    @test result["status"] == "passed"
    @test result["omitted_gpoint"] == 25
    @test result["ng_lw"] == 32
    @test result["ng_sw"] == 31
    @test result["worst_case"] == "ecckd_clear_sky_tropical_column"
    @test 12.33 < result["worst_heating_rate_rmse_ratio"] < 12.34
    @test result["objective_best_omitted_gpoint"] == 23
    @test result["comparison_omitted_gpoints"] == Any[25, 23]
    @test length(result["comparison_localizations"]) == 2
    tropical = only(filter(case -> case["case"] == "ecckd_clear_sky_tropical_column",
                           result["cases"]))
    @test tropical["max_abs_layer"] == 1
    @test tropical["max_abs_pressure_mid_pa"] < 2
    @test tropical["residual_at_max_abs_k_day"] < -6
    @test tropical["layer_summary"][1]["layer"] == 1
    @test tropical["layer_summary"][1]["layer_rmse_k_day"] > 5
    objective_best = only(filter(row -> row["omitted_gpoint"] == 23,
                                 result["comparison_localizations"]))
    @test 1.62 < objective_best["worst_heating_rate_rmse_ratio"] < 1.63
    objective_best_tropical =
        only(filter(case -> case["case"] == "ecckd_clear_sky_tropical_column",
                    objective_best["cases"]))
    @test objective_best_tropical["max_abs_layer"] == 4
    @test 5 < objective_best_tropical["max_abs_pressure_mid_pa"] < 6
    @test objective_best_tropical["residual_at_max_abs_k_day"] < -0.3

    markdown = read(md_path, String)
    @test occursin("Heating Residual Localization", markdown)
    @test occursin("Compared Leave-One-Out Rows", markdown)
    @test occursin("Dominant Layers", markdown)
end
