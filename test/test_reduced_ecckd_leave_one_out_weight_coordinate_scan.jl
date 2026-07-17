using JSON

@testset "reduced ecCKD leave-one-out weight coordinate scan" begin
    root = normpath(joinpath(@__DIR__, ".."))
    script = joinpath(root, "validation",
                      "reduced_ecckd_leave_one_out_weight_coordinate_scan.jl")
    json_path = joinpath(root, "validation", "results",
                         "reduced_ecckd_leave_one_out_weight_coordinate_scan.json")
    md_path = joinpath(root, "validation", "results",
                       "reduced_ecckd_leave_one_out_weight_coordinate_scan.md")
    if !isfile(json_path) || stat(json_path).mtime < stat(script).mtime
        test_project = Base.active_project()
        read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    end

    @test isfile(json_path)
    @test isfile(md_path)

    result = JSON.parsefile(json_path)
    @test result["status"] == "weight_coordinate_scan_improved"
    @test result["omitted_gpoint"] == 23
    @test result["ng_lw"] == 32
    @test result["ng_sw"] == 31
    @test result["coordinate_count"] == 16
    @test result["exact_row_count"] == 128
    @test result["accepted"]
    @test 1.62 < result["base_objective"] < 1.63
    @test 1.48 < result["accepted_objective"] < 1.49
    @test result["accepted_objective"] < result["base_objective"]
    @test result["accepted_worst_boundary_forcing_error_w_m2"] < 0.3
    @test result["accepted_worst_heating_rate_rmse_k_day"] <
          result["base_worst_heating_rate_rmse_k_day"]
    @test any(row -> row["accepted"], result["rows"])

    markdown = read(md_path, String)
    @test occursin("Weight Coordinate Scan", markdown)
    @test occursin("weight_coordinate_scan_improved", markdown)
end
