using JSON

@testset "reduced ecCKD leave-one-out weight coordinate boundary polish" begin
    root = normpath(joinpath(@__DIR__, ".."))
    script = joinpath(root, "validation",
                      "reduced_ecckd_leave_one_out_weight_coordinate_boundary_polish.jl")
    json_path = joinpath(root, "validation", "results",
                         "reduced_ecckd_leave_one_out_weight_coordinate_boundary_polish.json")
    md_path = joinpath(root, "validation", "results",
                       "reduced_ecckd_leave_one_out_weight_coordinate_boundary_polish.md")
    if !isfile(json_path) || stat(json_path).mtime < stat(script).mtime
        test_project = Base.active_project()
        read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    end

    @test isfile(json_path)
    @test isfile(md_path)

    result = JSON.parsefile(json_path)
    @test result["status"] == "weight_coordinate_boundary_polish_passed"
    @test result["omitted_gpoint"] == 23
    @test result["ng_lw"] == 32
    @test result["ng_sw"] == 31
    @test result["coordinate_count"] == 31
    @test result["max_iterations"] == 20
    @test result["completed_iterations"] == 17
    @test result["accepted_move_count"] == 17
    @test 1.08 < result["initial_objective"] < 1.09
    @test result["final_objective"] <= 1.0
    @test 0.99 < result["final_objective"] < 1.0
    @test result["final_worst_boundary_forcing_error_w_m2"] < 0.3
    @test result["final_worst_heating_rate_rmse_k_day"] < 0.05

    markdown = read(md_path, String)
    @test occursin("Weight Coordinate Boundary Polish", markdown)
    @test occursin("weight_coordinate_boundary_polish_passed", markdown)
end
