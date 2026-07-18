# Consolidated from the original per-topic test files (Stage R2).
# Each original file's content is preserved verbatim inside its own module
# so top-level consts/functions from included validation scripts cannot clash.

module TestReducedEcckd32gRrtmgpComparison
using Test
using NumericalRadiation
using Dates

# --- begin content of test_reduced_ecckd_32g_rrtmgp_comparison.jl ---
using JSON
using Test

@testset "32-g ecCKD RRTMGP comparison artifact" begin
    script = joinpath(@__DIR__, "..", "validation",
                      "reduced_ecckd_32g_rrtmgp_comparison.jl")
    test_project = Base.active_project()
    output = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)

    @test occursin("32-g ecCKD RRTMGP Comparison", output)
    @test occursin("Status: **passed**", output)
    @test occursin("RRTMGP role", output)

    json_path = joinpath(@__DIR__, "..", "validation", "results",
                         "reduced_ecckd_32g_rrtmgp_comparison.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results",
                       "reduced_ecckd_32g_rrtmgp_comparison.md")
    @test isfile(json_path)
    @test isfile(md_path)

    parsed = JSON.parsefile(json_path)
    @test parsed["case"] == "reduced_ecckd_32g_rrtmgp_comparison"
    @test parsed["status"] == "passed"
    @test occursin("official ecCKD 32-g", parsed["production_target"])
    @test occursin("FROZEN_DIAGNOSTICS.md", parsed["frozen_diagnostic"])
    @test parsed["official_32g_ecckd_hard_gate_passed"]
    @test parsed["rrtmgp_comparison_emitted"]
    @test occursin("not line-by-line truth", parsed["rrtmgp_role"])
    @test length(parsed["cases"]) >= 3

    cases = Dict(case["case"] => case for case in parsed["cases"])
    @test haskey(cases, "ecckd_clear_sky_tropical_column")
    @test haskey(cases, "ecckd_rcemip_style_column_subset")
    @test cases["ecckd_rcemip_style_column_subset"]["columns"] >= 32

    for case in parsed["cases"]
        @test case["candidate_vs_ecckd_reference"]["flux_rmse"] < 0.30
        @test case["candidate_vs_ecckd_reference"]["heating_rate_rmse"] < 0.05
        @test isfinite(case["candidate_vs_rrtmgp"]["flux_rmse"])
        @test isfinite(case["candidate_vs_rrtmgp"]["heating_rate_rmse"])
    end
end
# --- end content of test_reduced_ecckd_32g_rrtmgp_comparison.jl ---

end # module TestReducedEcckd32gRrtmgpComparison

module TestReducedEcckdOpticalDepthFitPreflight
using Test
using NumericalRadiation
using Dates

# --- begin content of test_reduced_ecckd_optical_depth_fit_preflight.jl ---
using Test

include(joinpath(@__DIR__, "..", "validation", "reduced_ecckd_optical_depth_fit_preflight.jl"))

@testset "reduced ecCKD optical-depth fit preflight artifact" begin
    result = optical_depth_fit_preflight()
    @test result.case == "reduced_ecckd_optical_depth_fit_preflight"
    @test result.status == "optical_depth_refit_target_ready"
    @test result.ng_sw == 16
    @test result.sample_count > 0
    @test result.baseline.rmse > 0
    @test result.fitted.rmse < result.baseline.rmse
    @test result.component_fitted.rmse < result.fitted.rmse
    @test result.relative_rmse_reduction > 0
    @test result.component_relative_rmse_reduction > result.relative_rmse_reduction
    @test length(result.fitted_scales) == 16
    @test size(result.component_scales) == (16, 3)
    @test result.scale_min > 0
    @test result.scale_max >= result.scale_min
    @test result.component_scale_max >= result.component_scale_min
    @test result.flux_baseline_objective > 1
    @test result.flux_scaled_objective > result.flux_baseline_objective
    @test !result.flux_scaled_improved
    @test !result.flux_scaled_passed_hard_thresholds
    @test result.flux_component_scaled_objective > result.flux_baseline_objective
    @test !result.flux_component_scaled_improved
    @test !result.flux_component_scaled_passed_hard_thresholds
    @test result.coefficient_table_fit.parameter_count_per_g > 0
    @test result.coefficient_table_fit.sample_count == result.sample_count
    @test result.coefficient_table_fit.physical_target_optical_depth.rmse < 1.0e-10
    @test result.coefficient_table_fit.physical_target_flux_objective > 1
    @test !result.coefficient_table_fit.physical_target_flux_passed_hard_thresholds
    @test result.coefficient_table_fit.raw_least_squares_optical_depth.rmse <
          result.component_fitted.rmse
    @test result.coefficient_table_fit.clipped_model_optical_depth.rmse >
          result.baseline.rmse
    @test result.coefficient_table_fit.clipped_parameter_count > 0
    @test result.coefficient_table_fit.flux_objective > result.flux_baseline_objective
    @test !result.coefficient_table_fit.flux_improved
    @test !result.coefficient_table_fit.flux_passed_hard_thresholds
    @test length(result.case_rows) == length(REDUCED_CASES)
    @test occursin("optical-depth targets", result.next_required_work)

    main()
    @test isfile(OPTICAL_DEPTH_FIT_JSON)
    @test isfile(OPTICAL_DEPTH_FIT_MD)
    json = read(OPTICAL_DEPTH_FIT_JSON, String)
    @test occursin("\"case\": \"reduced_ecckd_optical_depth_fit_preflight\"", json)
    @test occursin("\"status\": \"optical_depth_refit_target_ready\"", json)
    @test occursin("\"fitted_scales\"", json)
    @test occursin("\"component_scales\"", json)
    @test occursin("\"relative_rmse_reduction\"", json)
    @test occursin("\"flux_scaled_improved\": false", json)
    @test occursin("\"flux_component_scaled_improved\": false", json)
    @test occursin("\"coefficient_table_fit\"", json)
    markdown = read(OPTICAL_DEPTH_FIT_MD, String)
    @test occursin("Reduced ecCKD Optical-Depth Fit Preflight", markdown)
    @test occursin("Baseline optical-depth RMSE", markdown)
    @test occursin("Component-fitted optical-depth RMSE", markdown)
    @test occursin("Scaled flux objective", markdown)
    @test occursin("Physical projected table optical-depth RMSE", markdown)
    @test occursin("Coefficient-table raw LS optical-depth RMSE", markdown)
    @test occursin("Coefficient-table clipped-model optical-depth RMSE", markdown)
end
# --- end content of test_reduced_ecckd_optical_depth_fit_preflight.jl ---

end # module TestReducedEcckdOpticalDepthFitPreflight

include_slow_validation_test("test_rrtmgp_target_16g_ad_calibration.jl")
