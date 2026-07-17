using JSON

@testset "official ecCKD teacher-student recovery artifact" begin
    root = normpath(joinpath(@__DIR__, ".."))
    script = joinpath(root, "validation", "ecckd_teacher_student_recovery.jl")
    test_project = Base.active_project()
    output = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)

    @test occursin("ecCKD Teacher-Student Recovery", output)
    @test occursin("Status: **passed**", output)
    @test occursin("Enzyme used for training | true", output)
    @test occursin("Reactant compile check | passed", output)
    @test occursin("Recovery metrics status | passed", output)

    json_path = joinpath(root, "validation", "results", "ecckd_teacher_student_recovery.json")
    md_path = joinpath(root, "validation", "results", "ecckd_teacher_student_recovery.md")
    candidate_path = joinpath(root, "validation", "results", "ecckd_recovered_sw32_candidate.nc")
    @test isfile(json_path)
    @test isfile(md_path)
    @test isfile(candidate_path)

    result = JSON.parsefile(json_path)
    @test result["case"] == "ecckd_teacher_student_recovery"
    @test result["status"] == "passed"
    @test result["enzyme_used_for_training"] == true
    @test result["reactant_compile_check"]["status"] == "passed"
    @test result["iterations"] == 32
    @test result["final_loss"] < result["initial_loss"] / 100
    @test result["final_loss"] > 0
    @test result["recovery_metrics"]["status"] == "passed"
    @test result["recovery_metrics"]["worst_log_coefficient_rmse"] < 1.0e-3
    @test result["recovery_metrics"]["gpoint_weight_max_abs_error"] == 0.0
    @test result["recovery_metrics"]["band_weight_max_abs_error"] == 0.0
end
