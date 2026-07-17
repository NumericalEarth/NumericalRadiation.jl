using JSON

@testset "official ecCKD teacher-student recovery scan artifact" begin
    root = normpath(joinpath(@__DIR__, ".."))
    json_path = joinpath(root, "validation", "results", "ecckd_teacher_student_recovery_scan.json")
    md_path = joinpath(root, "validation", "results", "ecckd_teacher_student_recovery_scan.md")
    script = joinpath(root, "validation", "ecckd_teacher_student_recovery.jl")

    if !isfile(json_path) || !isfile(md_path) || stat(json_path).mtime < stat(script).mtime
        test_project = Base.active_project()
        output = read(setenv(
            `$(Base.julia_cmd()) --project=$test_project $script`,
            "RH_ECCKD_TEACHER_STUDENT_SCAN" => "true",
            "RH_ECCKD_TEACHER_STUDENT_ITERATIONS" => "32",
        ), String)
        @test occursin("ecCKD Teacher-Student Recovery Scan", output)
    end

    @test isfile(json_path)
    @test isfile(md_path)

    result = JSON.parsefile(json_path)
    md = read(md_path, String)
    @test result["case"] == "ecckd_teacher_student_recovery_scan"
    @test result["status"] == "passed"
    @test result["recovery_count"] == 6
    @test length(result["results"]) == 6
    @test occursin("| File | Status | Parameters | Initial loss | Final loss | Reactant | Worst log RMSE | Worst P99 relative error |", md)

    rows = Dict(row["filename"] => row for row in result["results"])
    @test haskey(rows, "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc")
    @test haskey(rows, "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc")
    @test haskey(rows, "ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc")
    @test all(row -> row["status"] == "passed", result["results"])
    @test all(row -> row["iterations"] == 32, result["results"])
    @test all(row -> row["parameter_count"] > 0, result["results"])
    @test all(row -> row["final_loss"] > 0, result["results"])
    @test all(row -> row["recovery_metrics"]["worst_log_coefficient_rmse"] < 1.0e-3,
              result["results"])
    @test rows["ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc"]["parameter_count"] ==
          maximum(row["parameter_count"] for row in result["results"])
end
