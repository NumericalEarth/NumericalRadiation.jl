# Consolidated from the original per-topic test files (Stage R2).
# Each original file's content is preserved verbatim inside its own module
# so top-level consts/functions from included validation scripts cannot clash.

module TestEcckdPublishedModelAccuracy
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_published_model_accuracy.jl ---
using Test
using JSON

include(joinpath(@__DIR__, "..", "validation", "ecckd_published_model_accuracy.jl"))

@testset "published ecCKD model accuracy" begin
    result = main()
    @test isfile(PUBLISHED_MODEL_ACCURACY_JSON)
    @test isfile(PUBLISHED_MODEL_ACCURACY_MD)
    artifact = JSON.parsefile(PUBLISHED_MODEL_ACCURACY_JSON)
    @test artifact["case"] == "ecckd_published_model_accuracy"
    @test artifact["status"] == "passed"
    @test length(artifact["models"]) == 6
    @test length(artifact["isolation_diagnostics"]) == 3
    @test length(artifact["boundary_projection_diagnostics"]) == 5
    models = Dict(model["label"] => model for model in artifact["models"])
    model_32 = models["official ecCKD 1.0 32-LW x 32-SW climate model"]
    model_32x64 = models["official ecCKD 1.0/1.2 32-LW x 64-SW climate/window model"]
    model_32x96 = models["official ecCKD 1.0/1.4 32-LW x 96-SW climate/vfine model"]
    model_64x32 = models["official ecCKD 1.2/1.4 64-LW x 32-SW narrow/rgb model"]
    model_64 = models["official ecCKD 1.2 64-LW x 64-SW climate model"]
    model_96 = models["official ecCKD 1.2/1.4 64-LW x 96-SW climate/vfine model"]
    @test model_32["ng_lw"] == 32
    @test model_32["ng_sw"] == 32
    @test model_32x64["ng_lw"] == 32
    @test model_32x64["ng_sw"] == 64
    @test model_32x96["ng_lw"] == 32
    @test model_32x96["ng_sw"] == 96
    @test model_64x32["ng_lw"] == 64
    @test model_64x32["ng_sw"] == 32
    @test model_64["ng_lw"] == 64
    @test model_64["ng_sw"] == 64
    @test model_96["ng_lw"] == 64
    @test model_96["ng_sw"] == 96
    @test model_32["passed_hard_thresholds"]
    @test model_32["hard_objective"]["value"] <= 1.0
    @test model_32["boundary_compatibility"]["all_longwave_spectral_boundaries_match"]
    @test model_32["boundary_compatibility"]["all_shortwave_surface_albedo_boundaries_match"]
    @test !model_32["boundary_compatibility"]["all_shortwave_direct_albedo_boundaries_match"]
    @test model_32["boundary_compatibility"]["all_shortwave_incoming_spectral_boundaries_match"]
    @test model_32x64["passed_hard_thresholds"]
    @test model_32x96["passed_hard_thresholds"]
    @test model_64x32["passed_hard_thresholds"]
    @test model_32x64["hard_objective"]["value"] <= 1.0
    @test model_32x96["hard_objective"]["value"] <= 1.0
    @test model_64x32["hard_objective"]["value"] <= 1.0
    @test model_32x64["boundary_compatibility"]["all_longwave_spectral_boundaries_match"]
    @test model_32x64["boundary_compatibility"]["all_shortwave_surface_albedo_boundaries_match"]
    @test model_32x96["boundary_compatibility"]["all_longwave_spectral_boundaries_match"]
    @test model_32x96["boundary_compatibility"]["all_shortwave_surface_albedo_boundaries_match"]
    @test model_64x32["boundary_compatibility"]["all_longwave_spectral_boundaries_match"]
    @test model_64x32["boundary_compatibility"]["all_shortwave_surface_albedo_boundaries_match"]
    @test model_64["passed_hard_thresholds"]
    @test model_96["passed_hard_thresholds"]
    @test model_64["hard_objective"]["value"] <= 1.0
    @test model_96["hard_objective"]["value"] <= 1.0
    @test model_64["boundary_compatibility"]["all_longwave_spectral_boundaries_match"]
    @test model_64["boundary_compatibility"]["all_shortwave_surface_albedo_boundaries_match"]
    @test model_96["boundary_compatibility"]["all_longwave_spectral_boundaries_match"]
    @test model_96["boundary_compatibility"]["all_shortwave_surface_albedo_boundaries_match"]
    diagnostics = Dict(model["label"] => model for model in artifact["isolation_diagnostics"])
    sw64 = diagnostics["component isolation: published 32-LW x 64-SW"]
    sw96 = diagnostics["component isolation: published 32-LW x 96-SW"]
    lw64 = diagnostics["component isolation: published 64-LW x 32-SW"]
    @test sw64["ng_lw"] == 32
    @test sw64["ng_sw"] == 64
    @test sw96["ng_lw"] == 32
    @test sw96["ng_sw"] == 96
    @test lw64["ng_lw"] == 64
    @test lw64["ng_sw"] == 32
    @test !sw64["passed_hard_thresholds"]
    @test !sw96["passed_hard_thresholds"]
    @test !lw64["passed_hard_thresholds"]
    @test sw64["hard_objective"]["metric"] == "surface_forcing"
    @test sw96["hard_objective"]["metric"] == "surface_forcing"
    @test lw64["hard_objective"]["metric"] == "heating_rate_max_abs"
    @test sw64["boundary_compatibility"]["all_longwave_spectral_boundaries_match"]
    @test !sw64["boundary_compatibility"]["all_shortwave_surface_albedo_boundaries_match"]
    @test sw96["boundary_compatibility"]["all_longwave_spectral_boundaries_match"]
    @test !sw96["boundary_compatibility"]["all_shortwave_surface_albedo_boundaries_match"]
    @test !lw64["boundary_compatibility"]["all_longwave_spectral_boundaries_match"]
    @test lw64["boundary_compatibility"]["all_shortwave_surface_albedo_boundaries_match"]
    projection = Dict(model["label"] => model
                      for model in artifact["boundary_projection_diagnostics"])
    projected_sw64 =
        projection["boundary-projected diagnostic: published 32-LW x 64-SW"]
    projected_sw96 =
        projection["boundary-projected diagnostic: published 32-LW x 96-SW"]
    projected_lw64 =
        projection["boundary-projected diagnostic: published 64-LW x 32-SW"]
    @test !projected_sw64["passed_hard_thresholds"]
    @test !projected_sw96["passed_hard_thresholds"]
    @test !projected_lw64["passed_hard_thresholds"]
    @test projected_sw64["hard_objective"]["metric"] == "toa_forcing"
    @test projected_sw96["hard_objective"]["metric"] == "toa_forcing"
    @test projected_sw64["worst_surface_forcing_abs_error_w_m2"] <
          sw64["worst_surface_forcing_abs_error_w_m2"]
    @test projected_sw96["worst_surface_forcing_abs_error_w_m2"] <
          sw96["worst_surface_forcing_abs_error_w_m2"]
    @test projected_lw64["hard_objective"]["value"] > lw64["hard_objective"]["value"]
    md = read(PUBLISHED_MODEL_ACCURACY_MD, String)
    @test occursin("64-LW x 96-SW", md)
    @test occursin("Boundary compatibility", md)
    @test occursin("Mixed-component isolation diagnostics", md)
    @test occursin("Boundary-projection experiment", md)
    @test occursin("Status: **passed**", md)
end
# --- end content of test_ecckd_published_model_accuracy.jl ---

end # module TestEcckdPublishedModelAccuracy

module TestEcckdPublishedAllSkyAccuracy
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_published_all_sky_accuracy.jl ---
using JSON

include(joinpath(@__DIR__, "..", "validation", "ecckd_published_all_sky_accuracy.jl"))

@testset "published ecCKD all-sky accuracy" begin
    result = main()
    @test isfile(PUBLISHED_ALL_SKY_ACCURACY_JSON)
    @test isfile(PUBLISHED_ALL_SKY_ACCURACY_MD)
    artifact = JSON.parsefile(PUBLISHED_ALL_SKY_ACCURACY_JSON)
    @test artifact["case"] == "ecckd_published_all_sky_accuracy"
    @test artifact["status"] == "passed"
    @test artifact["model_count"] == 6
    @test length(artifact["models"]) == 6
    @test artifact["passed_count"] == artifact["model_count"]
    @test Set(model["ng_lw"] for model in artifact["models"]) == Set([32, 64])
    @test Set(model["ng_sw"] for model in artifact["models"]) == Set([32, 64, 96])
    @test all(model["hard_objective"] > 0 for model in artifact["models"])
    @test all(haskey(model, "toa_forcing_max_abs") for model in artifact["models"])
    @test all(haskey(model, "surface_forcing_max_abs") for model in artifact["models"])
    @test all(haskey(model, "component_boundary_errors") for model in artifact["models"])
    @test all(length(model["component_boundary_errors"]) == 4 for model in artifact["models"])
    @test all(Set(error["component"] for error in model["component_boundary_errors"]) ==
              Set(["lw", "sw"]) for model in artifact["models"])
    @test all(model["passed"] for model in artifact["models"])

    baseline = first(model for model in artifact["models"]
                     if model["case"] == "ecckd_32x32_all_sky_tropical_column")
    @test baseline["passed"]
    @test baseline["toa_forcing_max_abs"] < 0.3
    @test baseline["surface_forcing_max_abs"] < 0.3

    wide_rows = filter(model -> model["ng_lw"] == 64 || model["ng_sw"] > 32,
                       artifact["models"])
    @test !isempty(wide_rows)
    @test any(model -> model["limiting_metric"] in
              ("toa_forcing_abs_error", "surface_forcing_abs_error"),
              wide_rows)

    md = read(PUBLISHED_ALL_SKY_ACCURACY_MD, String)
    @test occursin("Published ecCKD All-Sky Accuracy", md)
    @test occursin("Tripleclouds/aerosol", md)
    @test occursin("Hard objective", md)
    @test occursin("LW TOA", md)
    @test occursin("SW surface", md)
end
# --- end content of test_ecckd_published_all_sky_accuracy.jl ---

end # module TestEcckdPublishedAllSkyAccuracy

module TestEcckdMatchedReferencePlan
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_matched_reference_plan.jl ---
using Test
using JSON

include(joinpath(@__DIR__, "..", "validation", "ecckd_matched_reference_plan.jl"))

@testset "ecCKD matched reference plan" begin
    result = main()
    @test isfile(MATCHED_REFERENCE_PLAN_JSON)
    @test isfile(MATCHED_REFERENCE_PLAN_MD)
    artifact = JSON.parsefile(MATCHED_REFERENCE_PLAN_JSON)
    @test artifact["case"] == "ecckd_matched_reference_plan"
    @test artifact["status"] == "ready_for_published_parity_validation"
    @test length(artifact["required_cases"]) == 16
    @test artifact["missing_case_count"] == 0
    @test all(case["present"] && case["boundary_gpoints_match"]
              for case in artifact["required_cases"])
    @test all(isempty(case["missing_variables"]) for case in artifact["required_cases"])
    @test count(case -> case["all_sky"], artifact["required_cases"]) == 6
    @test Set(case["required_shortwave_gpoints"] for case in artifact["required_cases"]) ==
          Set([32, 64, 96])
    @test Set(case["required_longwave_gpoints"] for case in artifact["required_cases"]) ==
          Set([32, 64])
    for case in artifact["required_cases"]
        overrides = join(case["namelist_overrides"], "\n")
        @test occursin("gas_model_name=\"ECCKD\"", overrides)
        @test occursin("do_save_spectral_flux=true", overrides)
        @test occursin("gas_optics_lw_override_file_name=", overrides)
        @test occursin("gas_optics_sw_override_file_name=", overrides)
        if case["all_sky"]
            @test occursin("sw_solver_name=\"Tripleclouds\"", overrides)
            @test occursin("use_aerosols=true", overrides)
        end
    end
    @test occursin("ecrad_meridian_ecckd_cloudless_noaer_out.nc",
                   join(artifact["existing_ecrad_outputs"], "\n"))
    @test occursin("projection diagnostic", artifact["rationale"])
    md = read(MATCHED_REFERENCE_PLAN_MD, String)
    @test occursin("Status: **ready_for_published_parity_validation**", md)
    @test occursin("published-model accuracy", md)
    @test occursin("Required ecRad Namelist Overrides", md)
end
# --- end content of test_ecckd_matched_reference_plan.jl ---

end # module TestEcckdMatchedReferencePlan

module TestEcckdRecoveryMetrics
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_recovery_metrics.jl ---
using JSON

module EcckdRecoveryMetricsValidation
include(joinpath(@__DIR__, "..", "validation", "ecckd_recovery_metrics.jl"))
end

@testset "official ecCKD recovery metrics artifact" begin
    root = normpath(joinpath(@__DIR__, ".."))
    json_path = joinpath(root, "validation", "results", "ecckd_recovery_metrics.json")
    md_path = joinpath(root, "validation", "results", "ecckd_recovery_metrics.md")
    redirect_stdout(devnull) do
        EcckdRecoveryMetricsValidation.ecckd_recovery_metrics_main()
    end

    @test isfile(json_path)
    @test isfile(md_path)
    output = read(md_path, String)
    @test occursin("ecCKD Recovery Metrics", output)
    @test occursin("Status: **passed**", output)
    @test occursin("published_self_recovery_sanity", output)
    @test occursin("Worst log-coefficient RMSE", output)

    result = JSON.parsefile(json_path)
    @test result["case"] == "ecckd_recovery_metrics"
    @test result["status"] == "passed"
    @test result["recovery_mode"] == "published_self_recovery_sanity"

    metrics = result["metrics"]
    @test metrics["status"] == "passed"
    @test metrics["kind"] == "shortwave"
    @test metrics["coefficient_count"] == 6
    @test sort([coefficient["name"] for coefficient in metrics["coefficients"]]) == [
        "ch4_molar_absorption_coeff",
        "co2_molar_absorption_coeff",
        "composite_molar_absorption_coeff",
        "h2o_molar_absorption_coeff",
        "n2o_molar_absorption_coeff",
        "o3_molar_absorption_coeff",
    ]
    @test metrics["worst_log_coefficient_rmse"] == 0.0
    @test metrics["gpoint_weight_max_abs_error"] == 0.0
    @test metrics["band_weight_max_abs_error"] == 0.0
    @test metrics["thresholds"]["log_coefficient_rmse"] == 1.0e-3
end
# --- end content of test_ecckd_recovery_metrics.jl ---

end # module TestEcckdRecoveryMetrics

module TestEcckdTeacherStudentRecovery
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_teacher_student_recovery.jl ---
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
# --- end content of test_ecckd_teacher_student_recovery.jl ---

end # module TestEcckdTeacherStudentRecovery

module TestEcckdTeacherStudentRecoveryScan
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_teacher_student_recovery_scan.jl ---
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
# --- end content of test_ecckd_teacher_student_recovery_scan.jl ---

end # module TestEcckdTeacherStudentRecoveryScan

module TestEcckd32bBaselineCheck
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_32b_baseline_check.jl ---
using Test

include(joinpath(@__DIR__, "..", "validation", "ecckd_32b_baseline_check.jl"))

@testset "ecCKD 32b baseline check artifact" begin
    result = ecckd_32b_baseline_check()
    @test result.case == "ecckd_32b_baseline_check"
    @test result.status == "passed"
    @test occursin("32b", result.longwave_definition)
    @test occursin("32b", result.shortwave_definition)
    @test result.lw_gpoints == 32
    @test result.sw_gpoints == 32
    @test result.weights_normalized
    @test result.full_32x32_reduced_accuracy_anchor_passed

    main()
    @test isfile(ECCKD_32B_JSON)
    @test isfile(ECCKD_32B_MD)
    json = read(ECCKD_32B_JSON, String)
    @test occursin("\"case\": \"ecckd_32b_baseline_check\"", json)
    @test occursin("\"status\": \"passed\"", json)
    @test occursin("\"lw_gpoints\": 32", json)
    @test occursin("\"sw_gpoints\": 32", json)
    @test occursin("\"full_32x32_reduced_accuracy_anchor_passed\": true", json)
end
# --- end content of test_ecckd_32b_baseline_check.jl ---

end # module TestEcckd32bBaselineCheck

module TestEcckdBandAccuracyPareto
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_band_accuracy_pareto.jl ---
using JSON

@testset "ecCKD band-count accuracy Pareto artifact" begin
    root = normpath(joinpath(@__DIR__, ".."))
    script = joinpath(root, "validation", "ecckd_band_accuracy_pareto.jl")
    test_project = Base.active_project()
    output = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)

    @test occursin("ecCKD Band-Count Accuracy Pareto", output)
    @test occursin("Status: **passed**", output)
    @test occursin("Published ecCKD inventory entries: 6", output)

    md_path = joinpath(root, "validation", "results", "ecckd_band_accuracy_pareto.md")
    json_path = joinpath(root, "validation", "results", "ecckd_band_accuracy_pareto.json")
    csv_path = joinpath(root, "validation", "results", "ecckd_band_accuracy_pareto.csv")
    svg_path = joinpath(root, "validation", "results", "ecckd_band_accuracy_pareto.svg")
    @test isfile(md_path)
    @test isfile(json_path)
    @test isfile(csv_path)
    @test isfile(svg_path)

    result = JSON.parsefile(json_path)
    @test result["status"] == "passed"
    @test result["point_count"] >= 5
    @test result["published_inventory_count"] == 6
    @test result["passed_point_count"] >= 1
    @test haskey(result, "objective_front")
    @test length(result["objective_front"]) >= 2
    @test any(row -> row["ng_lw"] == 32 && row["ng_sw"] == 32 && row["passed"],
              result["accuracy_points"])
    @test any(row -> row["source"] == "reduced_accuracy" &&
                     row["ng_lw"] == 32 &&
                     row["ng_sw"] == 32 &&
                     row["passed"],
              result["accuracy_points"])
    @test any(row -> row["source"] == "published_model_accuracy" &&
                     row["ng_lw"] == 64 &&
                     row["ng_sw"] == 64 &&
                     row["passed"],
              result["accuracy_points"])
    @test any(row -> row["source"] == "published_model_accuracy" &&
                     row["ng_lw"] == 64 &&
                     row["ng_sw"] == 96 &&
                     row["passed"],
              result["accuracy_points"])

    md = read(md_path, String)
    @test occursin("Boundary-Forcing Pareto Front", md)
    @test occursin("Normalized-Objective Pareto Front", md)

    csv = read(csv_path, String)
    @test occursin("source,label,ng_lw,ng_sw,total_gpoints,passed", csv)
    @test occursin("normalized_objective,objective_source,limiting_metric", csv)
    @test length(split(chomp(csv), "\n")) == result["point_count"] + 1

    svg = read(svg_path, String)
    @test occursin("<svg", svg)
    @test occursin("ecCKD Accuracy vs Total G-points", svg)
    @test occursin("0.3 W m^-2 hard threshold", svg)
end
# --- end content of test_ecckd_band_accuracy_pareto.jl ---

end # module TestEcckdBandAccuracyPareto
