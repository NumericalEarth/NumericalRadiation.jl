using JSON

module RecoveryGoalAuditValidation
include(joinpath(@__DIR__, "..", "validation", "recovery_goal_audit.jl"))
end

@testset "recovery goal audit" begin
    root = normpath(joinpath(@__DIR__, ".."))
    json_path = joinpath(root, "validation", "results", "recovery_goal_audit.json")
    md_path = joinpath(root, "validation", "results", "recovery_goal_audit.md")

    redirect_stdout(devnull) do
        RecoveryGoalAuditValidation.recovery_goal_audit_main()
    end

    @test isfile(json_path)
    @test isfile(md_path)

    result = JSON.parsefile(json_path)
    @test result["case"] == "recovery_goal_audit"
    @test result["status"] in ("not_complete", "complete")
    @test result["blocked_count"] >= 0
    @test result["partial_count"] >= 0
    @test haskey(result, "prompt_to_artifact_checklist")
    @test length(result["prompt_to_artifact_checklist"]) == 4
    @test result["unmet_requirement_count"] ==
          count(item -> !item["covered"], result["prompt_to_artifact_checklist"])
    @test Set(result["unmet_requirement_ids"]) ==
          Set(item["requirement_id"] for item in result["prompt_to_artifact_checklist"]
              if !item["covered"])
    @test haskey(result, "original_objective_assets_ready")
    @test haskey(result, "official_training_summary")
    @test result["official_training_summary"]["present"]
    @test result["official_training_summary"]["reactant_status"] == "passed"
    @test result["official_training_summary"]["enzyme_status"] == "passed"
    @test result["official_training_summary"]["final_objective_target_ratio"] > 1
    @test !result["official_training_summary"]["hard_accuracy_target_met"]
    @test result["teacher_student_recovery_status"] == "passed"
    @test haskey(result, "derived_flux_progress")
    @test haskey(result, "derived_flux_plan_status")
    @test haskey(result, "derived_flux_plan_summary")
    @test haskey(result["derived_flux_plan_summary"], "ncrcat")
    @test result["derived_flux_progress"]["expected"] >= 0
    @test result["derived_flux_progress"]["final_present"] >= 0
    @test result["derived_flux_progress"]["products_with_raw_chunks"] >= 0
    @test result["derived_flux_progress"]["expected_raw_chunks"] >=
          result["derived_flux_progress"]["present_raw_chunks"]
    @test haskey(result["derived_flux_progress"], "completed_equivalent_raw_chunks")
    @test result["derived_flux_progress"]["expected_raw_chunks"] >=
          result["derived_flux_progress"]["completed_equivalent_raw_chunks"]
    @test result["derived_flux_progress"]["completed_equivalent_raw_chunks"] >=
          result["derived_flux_progress"]["present_raw_chunks"]
    @test haskey(result["derived_flux_progress"], "observed_raw_chunk_rate_per_hour")
    @test haskey(result["derived_flux_progress"], "estimated_raw_chunk_hours_remaining")
    @test result["objective_reconstruction_status"] in (
        "blocked_missing_original_training_assets",
        "ready_to_reconstruct_original_objective",
        "passed",
    )
    @test haskey(result, "original_objective_terms_summary")
    @test result["original_objective_terms_summary"]["present"]
    @test result["original_objective_terms_summary"]["status"] ==
          "objective_terms_captured"
    @test result["original_objective_terms_summary"]["implementation_status"] ==
          "terms_captured_not_yet_recovered"
    @test result["original_objective_terms_summary"]["longwave_term_count"] >= 8
    @test result["original_objective_terms_summary"]["shortwave_term_count"] >= 10
    @test result["original_objective_terms_summary"]["longwave_terms_present"]
    @test result["original_objective_terms_summary"]["shortwave_terms_present"]
    @test haskey(result, "ckdmip_objective_dataset_summary")
    @test result["ckdmip_objective_dataset_summary"]["present"]
    @test result["ckdmip_objective_dataset_summary"]["status"] ==
          "dataset_samples_ready"
    @test result["ckdmip_objective_dataset_summary"]["sample_count"] == 2
    @test result["ckdmip_objective_dataset_summary"]["training_flux_file_count"] >= 52
    @test result["ckdmip_objective_dataset_summary"]["training_flux_schema_ok_count"] ==
          result["ckdmip_objective_dataset_summary"]["training_flux_file_count"]
    @test result["ckdmip_objective_dataset_summary"]["longwave_sample_ready"]
    @test result["ckdmip_objective_dataset_summary"]["shortwave_sample_ready"]
    @test result["ckdmip_objective_dataset_summary"]["self_loss_zero"]
    @test haskey(result, "ckdmip_objective_ad_batch_summary")
    @test result["ckdmip_objective_ad_batch_summary"]["present"]
    @test result["ckdmip_objective_ad_batch_summary"]["status"] ==
          "optimizer_batch_ready"
    @test result["ckdmip_objective_ad_batch_summary"]["parameter_count"] > 0
    @test result["ckdmip_objective_ad_batch_summary"]["accepted_step"]
    @test result["ckdmip_objective_ad_batch_summary"]["loss_reduction_factor"] > 1
    @test result["ckdmip_objective_ad_batch_summary"]["gradient_method"] ==
          "central_finite_difference"
    @test haskey(result, "published_recovery_target_summary")
    @test result["published_recovery_target_summary"]["present"]
    @test result["published_recovery_target_summary"]["status"] ==
          "published_recovery_target_ready"
    @test result["published_recovery_target_summary"]["model_count"] == 6
    @test result["published_recovery_target_summary"]["shortwave_32_parameter_count"] > 0
    @test result["published_recovery_target_summary"]["longwave_32_parameter_count"] > 0
    @test result["published_recovery_target_summary"]["final_objective_target_ratio_max"] <= 1.05
    @test result["published_recovery_target_summary"]["optical_depth_log_rmse_max"] <= 0.02
    @test result["published_recovery_target_summary"]["optimizer_only_delta_rule_present"]
    @test haskey(result, "published_recovery_vector_summary")
    @test result["published_recovery_vector_summary"]["present"]
    @test result["published_recovery_vector_summary"]["status"] == "passed"
    @test result["published_recovery_vector_summary"]["array_count"] == 9
    @test result["published_recovery_vector_summary"]["parameter_count"] == 204896
    @test result["published_recovery_vector_summary"]["roundtrip_max_abs_error"] == 0.0
    @test result["published_recovery_vector_summary"]["roundtrip_l1_relative_error"] == 0.0
    @test result["published_recovery_vector_summary"]["recovery_metrics_status"] == "passed"
    @test haskey(result, "published_recovery_vector_training_summary")
    @test result["published_recovery_vector_training_summary"]["present"]
    @test result["published_recovery_vector_training_summary"]["status"] == "passed"
    @test result["published_recovery_vector_training_summary"]["parameter_count"] == 204896
    @test result["published_recovery_vector_training_summary"]["trained_parameter_count"] == 64
    @test result["published_recovery_vector_training_summary"]["loss_reduction_factor"] > 1.0e10
    @test !result["published_recovery_vector_training_summary"]["enzyme_requested"]
    @test !result["published_recovery_vector_training_summary"]["reactant_check_requested"]
    @test result["published_recovery_vector_training_summary"]["recovery_metrics_status"] == "passed"
    @test result["ckdmip_preflight_status"] in (
        "missing_ckdmip_data_root",
        "incomplete_ckdmip_upstream_data",
        "ready_for_derived_flux_generation",
        "ready_for_original_ecckd_objective",
    )
    @test result["reduced_model_summary"]["full_32x32_passed"]
    @test result["reduced_model_summary"]["hard_boundary_forcing_threshold_w_m2"] == 0.3
    @test result["reduced_model_summary"]["official_32x32_worst_boundary_forcing_error_w_m2"] < 0.3
    @test haskey(result["reduced_model_summary"], "best_reduced_candidate")
    @test haskey(result, "published_model_accuracy_summary")
    @test result["published_model_accuracy_summary"]["present"]
    @test result["published_model_accuracy_summary"]["status"] == "passed"
    @test result["published_model_accuracy_summary"]["model_count"] == 6
    @test result["published_model_accuracy_summary"]["passed_count"] == 6
    @test result["published_model_accuracy_summary"]["boundary_compatible_count"] == 6
    @test result["published_model_accuracy_summary"]["isolation_diagnostic_count"] == 3
    @test result["published_model_accuracy_summary"]["boundary_projection_diagnostic_count"] == 5
    @test haskey(result, "matched_reference_summary")
    @test result["matched_reference_summary"]["present"]
    @test result["matched_reference_summary"]["status"] ==
          "ready_for_published_parity_validation"
    @test result["matched_reference_summary"]["required_case_count"] == 16
    @test result["matched_reference_summary"]["missing_case_count"] == 0
    @test result["matched_reference_summary"]["all_sky_case_count"] == 6
    @test result["matched_reference_summary"]["all_sky_ready_count"] == 6
    @test haskey(result, "published_all_sky_accuracy_summary")
    @test result["published_all_sky_accuracy_summary"]["present"]
    @test result["published_all_sky_accuracy_summary"]["status"] in
          ("passed", "failed_threshold")
    @test result["published_all_sky_accuracy_summary"]["model_count"] == 6
    @test result["published_all_sky_accuracy_summary"]["passed_count"] >= 1
    @test result["published_all_sky_accuracy_summary"]["passed_count"] <= 6
    @test result["published_all_sky_accuracy_summary"]["worst_hard_objective"] > 0
    @test haskey(result, "reduced_weight_coordinate_boundary_polish_summary")
    @test result["reduced_weight_coordinate_boundary_polish_summary"]["present"]
    @test result["reduced_weight_coordinate_boundary_polish_summary"]["accepted"]
    @test result["reduced_weight_coordinate_boundary_polish_summary"]["passed"]
    @test result["reduced_weight_coordinate_boundary_polish_summary"]["omitted_gpoint"] == 23
    @test result["reduced_weight_coordinate_boundary_polish_summary"]["accepted_move_count"] == 17
    @test 0.99 < result["reduced_weight_coordinate_boundary_polish_summary"]["final_objective"] < 1.0
    @test result["reduced_weight_coordinate_boundary_polish_summary"]["final_worst_boundary_forcing_error_w_m2"] < 0.3
    @test result["breeze_summary"]["runtime_supported"]
    @test result["breeze_summary"]["final_4x_claim_supported"]

    mktempdir() do dir
        missing_breeze = joinpath(dir, "missing_breeze.json")
        env_result = withenv("RH_BREEZE_RCEMIP_JSON" => missing_breeze) do
            RecoveryGoalAuditValidation.run_recovery_goal_audit()
        end
        @test env_result.breeze_summary.artifact == missing_breeze
        @test !env_result.breeze_summary.present
        @test any(row -> row.id == "breeze_dynamic_integration" && row.status == "blocked",
                  env_result.requirements)
    end

    statuses = Dict(row["id"] => row["status"] for row in result["requirements"])
    @test statuses["ecrad_full_and_reduced_parity"] in ("blocked", "partial", "passed")
    @test statuses["reduced_vs_rrtmgp_representative_states"] in ("blocked", "partial", "passed")
    @test statuses["breeze_dynamic_integration"] == "passed"
    @test statuses["reactant_enzyme_ecckd_training_recovery"] in ("blocked", "partial", "passed")

    markdown = read(md_path, String)
    @test occursin("Recovery Goal Audit", markdown)
    @test occursin("Prompt-to-Artifact Checklist", markdown)
    @test occursin("Derived flux products:", markdown)
    @test occursin("Derived flux generation plan status", markdown)
    @test occursin("Derived raw chunks:", markdown)
    @test occursin("Completed-equivalent derived raw chunks", markdown)
    @test occursin("ncrcat", markdown)
    @test occursin("Observed derived raw chunk rate", markdown)
    @test occursin("Quantitative Reduced-Model Status", markdown)
    @test occursin("64x96", markdown) || occursin("64x64", markdown)
    @test occursin("boundary-projection diagnostics", markdown)
    @test occursin("omitted SW g-point 23", markdown)
    @test occursin("Quantitative Training-Recovery Status", markdown)
    @test occursin("Original objective terms:", markdown)
    @test occursin("CKDMIP objective dataset:", markdown)
    @test occursin("CKDMIP objective optimizer batch:", markdown)
    @test occursin("Published recovery target:", markdown)
    @test occursin("Published recovery vector:", markdown)
    @test occursin("Published recovery vector training:", markdown)
    @test occursin("final/target", markdown)
    @test occursin("RH_CKDMIP_DATA_PATH", markdown) ||
          occursin("derived ecCKD", markdown)
end
