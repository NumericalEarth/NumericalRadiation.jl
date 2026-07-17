using JSON

@testset "reduced ecCKD leave-one-out heating table optimizer" begin
    root = normpath(joinpath(@__DIR__, ".."))
    script = joinpath(root, "validation",
                      "reduced_ecckd_leave_one_out_heating_table_optimizer.jl")
    json_path = joinpath(root, "validation", "results",
                         "reduced_ecckd_leave_one_out_heating_table_optimizer.json")
    md_path = joinpath(root, "validation", "results",
                       "reduced_ecckd_leave_one_out_heating_table_optimizer.md")
    if !isfile(json_path) || stat(json_path).mtime < stat(script).mtime
        test_project = Base.active_project()
        read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    end

    @test isfile(json_path)
    @test isfile(md_path)

    result = JSON.parsefile(json_path)
    @test result["status"] == "leave_one_out_heating_table_optimizer_rejected"
    @test result["omitted_gpoint"] == 25
    @test result["ng_lw"] == 32
    @test result["ng_sw"] == 31
    @test result["candidate_count"] == 16
    @test !result["accepted"]
    @test result["accepted_move_count"] == 0
    @test 12.33 < result["base_objective"] < 12.34
    @test result["best_exact_objective"] > result["base_objective"]
    @test result["best_worst_boundary_forcing_error_w_m2"] > 0.3
    @test result["best_worst_heating_rate_rmse_k_day"] >
          result["base_worst_heating_rate_rmse_k_day"]
    @test result["objective_best_omitted_gpoint"] == 23
    @test result["comparison_omitted_gpoints"] == Any[25, 23]
    @test length(result["comparison_results"]) == 2
    objective_best = only(filter(row -> row["omitted_gpoint"] == 23,
                                 result["comparison_results"]))
    @test objective_best["status"] == "leave_one_out_heating_table_optimizer_rejected"
    @test !objective_best["accepted"]
    @test 1.62 < objective_best["base_objective"] < 1.63
    @test objective_best["best_exact_objective"] > objective_best["base_objective"]
    @test objective_best["best_worst_boundary_forcing_error_w_m2"] > 0.3

    markdown = read(md_path, String)
    @test occursin("Leave-One-Out Heating Table Optimizer", markdown)
    @test occursin("Compared Leave-One-Out Rows", markdown)
    @test occursin("rejected", markdown)
end
