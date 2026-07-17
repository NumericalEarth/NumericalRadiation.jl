using JSON

@testset "reduced ecCKD leave-one-out weight coordinate descent" begin
    root = normpath(joinpath(@__DIR__, ".."))
    script = joinpath(root, "validation",
                      "reduced_ecckd_leave_one_out_weight_coordinate_descent.jl")
    json_path = joinpath(root, "validation", "results",
                         "reduced_ecckd_leave_one_out_weight_coordinate_descent.json")
    md_path = joinpath(root, "validation", "results",
                       "reduced_ecckd_leave_one_out_weight_coordinate_descent.md")
    if !isfile(json_path) || stat(json_path).mtime < stat(script).mtime
        test_project = Base.active_project()
        read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    end

    @test isfile(json_path)
    @test isfile(md_path)

    result = JSON.parsefile(json_path)
    @test result["status"] == "weight_coordinate_descent_improved"
    @test result["omitted_gpoint"] == 23
    @test result["ng_lw"] == 32
    @test result["ng_sw"] == 31
    @test result["max_iterations"] == 6
    @test result["completed_iterations"] == 6
    @test result["accepted_move_count"] == 6
    @test 1.62 < result["initial_objective"] < 1.63
    @test 1.26 < result["final_objective"] < 1.27
    @test result["final_objective"] < result["initial_objective"]
    @test result["final_worst_boundary_forcing_error_w_m2"] < 0.3
    @test result["final_worst_heating_rate_rmse_k_day"] <
          result["initial_worst_heating_rate_rmse_k_day"]

    markdown = read(md_path, String)
    @test occursin("Weight Coordinate Descent", markdown)
    @test occursin("weight_coordinate_descent_improved", markdown)
end
