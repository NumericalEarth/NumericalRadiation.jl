using JSON

@testset "reduced ecCKD leave-one-out single table-move scan" begin
    root = normpath(joinpath(@__DIR__, ".."))
    script = joinpath(root, "validation",
                      "reduced_ecckd_leave_one_out_single_table_move_scan.jl")
    json_path = joinpath(root, "validation", "results",
                         "reduced_ecckd_leave_one_out_single_table_move_scan.json")
    md_path = joinpath(root, "validation", "results",
                       "reduced_ecckd_leave_one_out_single_table_move_scan.md")
    if !isfile(json_path) || stat(json_path).mtime < stat(script).mtime
        test_project = Base.active_project()
        read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    end

    @test isfile(json_path)
    @test isfile(md_path)

    result = JSON.parsefile(json_path)
    @test result["status"] == "single_table_move_rejected"
    @test result["omitted_gpoint"] == 23
    @test result["ng_lw"] == 32
    @test result["ng_sw"] == 31
    @test result["candidate_count"] == 8
    @test result["exact_row_count"] == 48
    @test result["pressure_index_min"] == 1
    @test result["pressure_index_max"] == 8
    @test !result["accepted"]
    @test 1.62 < result["base_objective"] < 1.63
    @test result["best_exact_objective"] > result["base_objective"]
    @test result["best_worst_boundary_forcing_error_w_m2"] > 0.3
    @test result["best_worst_heating_rate_rmse_k_day"] >
          result["base_worst_heating_rate_rmse_k_day"]
    @test all(!row["accepted"] for row in result["rows"])

    markdown = read(md_path, String)
    @test occursin("Single Table-Move Scan", markdown)
    @test occursin("single_table_move_rejected", markdown)
end
