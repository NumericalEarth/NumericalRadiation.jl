@testset "reduced ecCKD gap report artifact" begin
    using JSON

    script = joinpath(@__DIR__, "..", "validation", "reduced_ecckd_gap_report.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)

    @test occursin("Reduced ecCKD Gap Report", result)
    @test occursin(r"reduced_shortwave_(blocked|passed)", result)
    @test occursin("Conclusion", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results", "reduced_ecckd_gap_report.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results", "reduced_ecckd_gap_report.md")
    accuracy_md_path =
        joinpath(@__DIR__, "..", "validation", "results", "reduced_ecckd_accuracy.md")
    @test isfile(json_path)
    @test isfile(md_path)
    @test isfile(accuracy_md_path)

    json = read(json_path, String)
    parsed = JSON.parse(json)
    json_int(key) = parse(Int, only(match(Regex("\"$(key)\"\\s*:\\s*(\\d+)"), json).captures))
    json_bool(key) = only(match(Regex("\"$(key)\"\\s*:\\s*(true|false)"), json).captures) == "true"

    @test occursin("\"case\": \"reduced_ecckd_gap_report\"", json)
    @test parsed["status"] in ("reduced_shortwave_blocked", "reduced_shortwave_passed")
    @test json_bool("full_shortwave_passed")
    @test json_bool("reduced_shortwave_passed") ==
          (parsed["status"] == "reduced_shortwave_passed")
    @test occursin("\"optimization\": {", json)
    @test parsed["coefficient_continuation"]["present"]
    @test occursin("\"acceptance_gap_status\": \"far_above_objective_target\"", json)
    @test occursin("\"best_block\": \"weights\"", json)
    @test occursin("\"topology_scan_status\": \"all_32x16_topologies_fail_forcing_gate\"", json)
    @test json_int("topology_candidate_count") >= 1
    @test occursin("\"best_topology_forcing_objective_lower_bound\":", json)
    @test parsed["optimization"]["final_worst_case"] in
          ("ecckd_clear_sky_tropical_column", "ecckd_rcemip_style_column_subset")
    @test occursin("\"final_worst_metric\": \"toa_forcing_max_abs\"", json)
    @test parsed["best_reduced_toa_forcing_error_w_m2"] <= 2.16
    @test parsed["best_reduced_surface_forcing_error_w_m2"] <=
          parsed["retained_mixed_component_pareto_scan"]["final_worst_surface_forcing_error_w_m2"] +
          1e-10
    @test parsed["best_reduced_surface_forcing_error_w_m2"] < 2.03
    @test parsed["leave_one_out_scan"]["present"]
    @test parsed["leave_one_out_scan"]["status"] in
          ("all_leave_one_out_failed", "some_leave_one_out_passed")
    @test parsed["leave_one_out_scan"]["candidate_count"] == 32
    @test parsed["leave_one_out_scan"]["best_omitted_gpoint"] >= 1
    @test parsed["leave_one_out_scan"]["best_omitted_gpoint"] <= 32
    @test parsed["leave_one_out_scan"]["worst_omitted_gpoint"] >= 1
    @test parsed["leave_one_out_scan"]["worst_omitted_gpoint"] <= 32
    @test parsed["leave_one_out_scan"]["best_objective"] <=
          parsed["leave_one_out_scan"]["worst_objective"]
    if parsed["leave_one_out_scan"]["status"] == "all_leave_one_out_failed"
        @test parsed["leave_one_out_scan"]["pass_count"] == 0
        @test parsed["leave_one_out_scan"]["best_objective"] > 1
    else
        @test parsed["leave_one_out_scan"]["pass_count"] > 0
    end
    @test parsed["leave_one_out_weight_refit"]["present"]
    @test parsed["leave_one_out_weight_refit"]["status"] in
          ("all_leave_one_out_refits_failed", "some_leave_one_out_refits_passed")
    @test parsed["leave_one_out_weight_refit"]["candidate_count"] == 32
    @test parsed["leave_one_out_weight_refit"]["best_omitted_gpoint"] >= 1
    @test parsed["leave_one_out_weight_refit"]["best_omitted_gpoint"] <= 32
    @test parsed["leave_one_out_weight_refit"]["worst_omitted_gpoint"] >= 1
    @test parsed["leave_one_out_weight_refit"]["worst_omitted_gpoint"] <= 32
    @test parsed["leave_one_out_weight_refit"]["best_refit_objective"] <=
          parsed["leave_one_out_weight_refit"]["worst_refit_objective"]
    @test parsed["leave_one_out_weight_refit"]["best_refit_objective"] <=
          parsed["leave_one_out_weight_refit"]["best_initial_objective"]
    if parsed["leave_one_out_weight_refit"]["status"] ==
       "all_leave_one_out_refits_failed"
        @test parsed["leave_one_out_weight_refit"]["pass_count"] == 0
        @test parsed["leave_one_out_weight_refit"]["best_refit_objective"] > 1
    else
        @test parsed["leave_one_out_weight_refit"]["pass_count"] > 0
    end
    @test parsed["importance_group_scan"]["present"]
    @test parsed["importance_group_scan"]["status"] in
          ("all_importance_groups_failed", "some_importance_groups_passed")
    @test parsed["importance_group_scan"]["importance_source"] != ""
    @test parsed["importance_group_scan"]["grouping_rule"] != ""
    @test parsed["importance_group_scan"]["candidate_count"] >= 1
    @test parsed["importance_group_scan"]["best_label"] != ""
    @test parsed["importance_group_scan"]["best_refit_objective"] > 0
    if parsed["importance_group_scan"]["status"] == "all_importance_groups_failed"
        @test parsed["importance_group_scan"]["pass_count"] == 0
        @test parsed["importance_group_scan"]["best_refit_objective"] > 1
    else
        @test parsed["importance_group_scan"]["pass_count"] > 0
    end
    @test parsed["support_swap_scan"]["present"]
    @test parsed["support_swap_scan"]["status"] in ("failed_threshold", "passed")
    @test parsed["support_swap_scan"]["seed_count"] >= 1
    @test parsed["support_swap_scan"]["exact_top_n"] >= 1
    @test parsed["support_swap_scan"]["best_overall_objective"] > 0
    @test length(parsed["support_swap_scan"]["best_overall_indices"]) == 16
    @test 1 <= parsed["support_swap_scan"]["best_overall_removed_gpoint"] <= 32
    @test 1 <= parsed["support_swap_scan"]["best_overall_added_gpoint"] <= 32
    if parsed["support_swap_scan"]["status"] == "failed_threshold"
        @test !parsed["support_swap_scan"]["best_overall_passed_hard_thresholds"]
        @test parsed["support_swap_scan"]["best_overall_objective"] > 1
    else
        @test parsed["support_swap_scan"]["best_overall_passed_hard_thresholds"]
    end
    @test parsed["support_swap_continuation_scan"]["present"]
    @test parsed["support_swap_continuation_scan"]["status"] in
          ("failed_threshold", "passed")
    @test parsed["support_swap_continuation_scan"]["exact_top_n"] >= 1
    @test parsed["support_swap_continuation_scan"]["seed_exact_objective"] > 0
    @test parsed["support_swap_continuation_scan"]["best_objective"] > 0
    @test parsed["support_swap_continuation_scan"]["best_objective_reduction"] >= 0
    @test length(parsed["support_swap_continuation_scan"]["best_indices"]) == 16
    @test 1 <= parsed["support_swap_continuation_scan"]["best_removed_gpoint"] <= 32
    @test 1 <= parsed["support_swap_continuation_scan"]["best_added_gpoint"] <= 32
    if parsed["support_swap_continuation_scan"]["status"] == "failed_threshold"
        @test !parsed["support_swap_continuation_scan"]["best_passed_hard_thresholds"]
        @test parsed["support_swap_continuation_scan"]["best_objective"] > 1
    else
        @test parsed["support_swap_continuation_scan"]["best_passed_hard_thresholds"]
    end
    @test parsed["support_expansion_scan"]["present"]
    @test parsed["support_expansion_scan"]["status"] in ("failed_threshold", "passed")
    @test parsed["support_expansion_scan"]["seed_count"] >= 1
    @test parsed["support_expansion_scan"]["exact_top_n"] >= 1
    @test parsed["support_expansion_scan"]["best_overall_objective"] > 0
    @test parsed["support_expansion_scan"]["best_overall_ng"] in (17, 18)
    @test length(parsed["support_expansion_scan"]["best_overall_added_gpoints"]) in (1, 2)
    @test length(parsed["support_expansion_scan"]["best_overall_indices"]) ==
          parsed["support_expansion_scan"]["best_overall_ng"]
    if parsed["support_expansion_scan"]["status"] == "failed_threshold"
        @test !parsed["support_expansion_scan"]["best_overall_passed_hard_thresholds"]
        @test parsed["support_expansion_scan"]["best_overall_objective"] > 1
    else
        @test parsed["support_expansion_scan"]["best_overall_passed_hard_thresholds"]
    end
    @test parsed["support_expansion_refit_scan"]["present"]
    @test parsed["support_expansion_refit_scan"]["status"] in
          ("failed_threshold", "passed")
    @test parsed["support_expansion_refit_scan"]["iterations"] >= 800
    @test parsed["support_expansion_refit_scan"]["candidate_count"] >= 1
    @test parsed["support_expansion_refit_scan"]["start_count"] >= 2
    @test parsed["support_expansion_refit_scan"]["best_label"] != ""
    @test parsed["support_expansion_refit_scan"]["best_start_label"] != ""
    @test parsed["support_expansion_refit_scan"]["best_objective"] > 0
    @test parsed["support_expansion_refit_scan"]["best_ng"] in (17, 18)
    @test length(parsed["support_expansion_refit_scan"]["best_added_gpoints"]) in (1, 2)
    @test length(parsed["support_expansion_refit_scan"]["best_indices"]) ==
          parsed["support_expansion_refit_scan"]["best_ng"]
    if parsed["support_expansion_refit_scan"]["status"] == "failed_threshold"
        @test !parsed["support_expansion_refit_scan"]["best_passed_hard_thresholds"]
        @test parsed["support_expansion_refit_scan"]["best_objective"] > 1
    else
        @test parsed["support_expansion_refit_scan"]["best_passed_hard_thresholds"]
    end
    @test parsed["random_support_search"]["present"]
    @test parsed["random_support_search"]["status"] in ("failed_threshold", "passed")
    @test parsed["random_support_search"]["random_seed_count"] >= 1
    @test parsed["random_support_search"]["candidate_count"] >=
          parsed["random_support_search"]["random_seed_count"]
    @test parsed["random_support_search"]["exact_top_n"] >= 1
    @test parsed["random_support_search"]["iterations"] >= 1
    @test parsed["random_support_search"]["pnorm"] >= 1
    @test parsed["random_support_search"]["best_label"] != ""
    @test parsed["random_support_search"]["best_objective"] > 0
    @test length(parsed["random_support_search"]["best_indices"]) == 16
    @test parsed["random_support_search"]["canonical_seed_objective"] > 0
    @test parsed["random_support_search"]["subset_hardgate_seed_objective"] > 0
    if parsed["random_support_search"]["status"] == "failed_threshold"
        @test !parsed["random_support_search"]["best_passed_hard_thresholds"]
        @test parsed["random_support_search"]["best_objective"] > 1
    else
        @test parsed["random_support_search"]["best_passed_hard_thresholds"]
    end
    @test parsed["broader_support_refit_search"]["present"]
    @test parsed["broader_support_refit_search"]["status"] in
          ("support_refit_rejected", "support_refit_improved", "passes_hard_objective")
    @test parsed["broader_support_refit_search"]["objective_target"] == 1.0
    @test parsed["broader_support_refit_search"]["radius"] >= 1
    @test parsed["broader_support_refit_search"]["prefilter_evaluated_count"] >=
          parsed["broader_support_refit_search"]["evaluated_candidate_count"]
    @test parsed["broader_support_refit_search"]["evaluated_candidate_count"] >= 1
    @test parsed["broader_support_refit_search"]["total_neighbor_candidate_count"] >=
          parsed["broader_support_refit_search"]["prefilter_evaluated_count"]
    @test parsed["broader_support_refit_search"]["current_objective"] > 1
    @test parsed["broader_support_refit_search"]["best_objective"] > 1
    if parsed["broader_support_refit_search"]["status"] == "passes_hard_objective"
        @test parsed["broader_support_refit_search"]["best_passed_hard_objective"]
        @test parsed["broader_support_refit_search"]["best_objective"] <= 1
    else
        @test !parsed["broader_support_refit_search"]["best_passed_hard_objective"]
        @test parsed["broader_support_refit_search"]["best_objective"] > 1
    end
    @test parsed["nonlocal_support_refit_search"]["present"]
    @test parsed["nonlocal_support_refit_search"]["status"] in
          ("nonlocal_support_refit_rejected", "nonlocal_support_refit_improved",
           "passes_hard_objective")
    @test parsed["nonlocal_support_refit_search"]["objective_target"] == 1.0
    @test parsed["nonlocal_support_refit_search"]["evaluated_candidate_count"] >= 1
    @test parsed["nonlocal_support_refit_search"]["total_candidate_count"] >=
          parsed["nonlocal_support_refit_search"]["evaluated_candidate_count"]
    @test parsed["nonlocal_support_refit_search"]["current_objective"] > 1
    @test parsed["nonlocal_support_refit_search"]["best_objective"] > 1
    if parsed["nonlocal_support_refit_search"]["status"] == "passes_hard_objective"
        @test parsed["nonlocal_support_refit_search"]["best_passed_hard_objective"]
        @test parsed["nonlocal_support_refit_search"]["best_objective"] <= 1
    else
        @test !parsed["nonlocal_support_refit_search"]["best_passed_hard_objective"]
        @test parsed["nonlocal_support_refit_search"]["best_objective"] > 1
    end
    @test parsed["current_metric_breakdown"]["present"]
    @test parsed["current_metric_breakdown"]["status"] in
          ("failed_threshold", "passed")
    @test parsed["current_metric_breakdown"]["selected_shortwave_gpoint_count"] == 16
    @test parsed["current_metric_breakdown"]["worst_case"] != ""
    @test parsed["current_metric_breakdown"]["worst_metric"] != ""
    @test parsed["current_metric_breakdown"]["second_case"] != ""
    @test parsed["current_metric_breakdown"]["second_metric"] != ""
    @test parsed["current_metric_breakdown"]["second_normalized_value"] > 0
    if parsed["current_metric_breakdown"]["status"] == "failed_threshold"
        @test parsed["current_metric_breakdown"]["hard_objective"] > 1
        @test parsed["current_metric_breakdown"]["worst_value"] >
              parsed["current_metric_breakdown"]["worst_threshold"]
    else
        @test parsed["current_metric_breakdown"]["hard_objective"] <= 1
        @test parsed["current_metric_breakdown"]["worst_value"] <=
              parsed["current_metric_breakdown"]["worst_threshold"]
    end
    @test parsed["reduced_acceptance_decision"]["present"]
    @test parsed["reduced_acceptance_decision"]["blocker"] ==
          "reduced_16g_hard_threshold"
    @test parsed["reduced_acceptance_decision"]["objective_target"] == 1.0
    @test parsed["reduced_acceptance_decision"]["current_hard_objective"] ==
          parsed["current_metric_breakdown"]["hard_objective"]
    @test parsed["reduced_acceptance_decision"]["worst_metric"] ==
          parsed["current_metric_breakdown"]["worst_metric"]
    if parsed["current_metric_breakdown"]["status"] == "failed_threshold"
        @test parsed["reduced_acceptance_decision"]["status"] ==
              "decision_required"
        @test parsed["reduced_acceptance_decision"]["local_support_searches_rejected"]
        @test parsed["reduced_acceptance_decision"]["current_chain_required_for_best_row"]
        @test parsed["reduced_acceptance_decision"]["bare_canonical_support_objective"] >
              parsed["reduced_acceptance_decision"]["current_hard_objective"]
        @test parsed["reduced_acceptance_decision"]["random_support_best_objective"] >
              parsed["reduced_acceptance_decision"]["current_hard_objective"]
        if parsed["reduced_acceptance_decision"]["nonlocal_support_refit_rejected"]
            @test occursin(
                "revising the reduced-model acceptance target",
                parsed["reduced_acceptance_decision"]["recommended_next_decision"],
            )
            @test occursin(
                "different reduced basis",
                parsed["reduced_acceptance_decision"]["recommended_next_decision"],
            )
            @test length(parsed["reduced_acceptance_decision"]["remaining_options"]) == 2
            @test parsed["reduced_acceptance_decision"]["nonlocal_support_refit_best_objective"] >
                  parsed["reduced_acceptance_decision"]["current_hard_objective"]
            @test parsed["reduced_acceptance_decision"]["nonlocal_support_refit_evaluated_candidate_count"] >=
                  1
            if parsed["status"] == "reduced_shortwave_passed"
                @test occursin(
                    "Promote the passing reduced model",
                    parsed["next_required_work"],
                )
            else
                @test occursin(
                    "nonlocal support-plus-refit pass then evaluates all",
                    parsed["next_required_work"],
                )
                @test occursin(
                    "revisiting the hard reduced acceptance plan or allowing a different reduced basis",
                    parsed["next_required_work"],
                )
            end
            @test !occursin(
                "truly global support-plus-refit search",
                parsed["next_required_work"],
            )
        elseif parsed["reduced_acceptance_decision"]["bounded_broader_support_refit_rejected"]
            @test length(parsed["reduced_acceptance_decision"]["remaining_options"]) == 3
            @test occursin(
                "full global/nonlocal support-plus-refit search",
                parsed["reduced_acceptance_decision"]["recommended_next_decision"],
            )
            @test parsed["reduced_acceptance_decision"]["bounded_broader_support_refit_best_objective"] >
                  parsed["reduced_acceptance_decision"]["current_hard_objective"]
            @test parsed["reduced_acceptance_decision"]["bounded_broader_support_refit_evaluated_candidate_count"] >=
                  1
        else
            @test length(parsed["reduced_acceptance_decision"]["remaining_options"]) == 3
            @test occursin(
                "broader joint support-plus-refit search",
                parsed["reduced_acceptance_decision"]["recommended_next_decision"],
            )
        end
    else
        @test parsed["reduced_acceptance_decision"]["status"] == "passed"
    end
    accuracy_md = read(accuracy_md_path, String)
    canonical_accuracy_row = match(
        r"\| 32 \| 16 \| weighted greedy 16 shortwave g-point subset with boundary-aware table, component, structural, objective-probe, surface-probe, capped table, continuation, post-capped weight, post-weight surface-table, bounded weight, four current component-scale refits, selected current gas-pressure component scan refit, gas-pressure continuation refit, weighted gas-pressure continuation refit, and high-weight gas-pressure continuation refit \| false \| ([0-9.eE+-]+) W m\^-2 \| ([0-9.eE+-]+) W m\^-2 \|",
        accuracy_md,
    )
    @test canonical_accuracy_row !== nothing
    canonical_accuracy_toa = parse(Float64, canonical_accuracy_row.captures[1])
    canonical_accuracy_surface = parse(Float64, canonical_accuracy_row.captures[2])
    @test canonical_accuracy_toa <= 2.16
    @test canonical_accuracy_surface < 2.03
    @test json_int("targeted_candidate_count") >= 1
    @test !json_bool("targeted_accepted")
    @test occursin("\"global_entry\": {", json)
    @test json_int("total_ranked_candidate_count") >= 1
    @test json_int("candidate_limit") >= 1
    @test json_int("cumulative_active_move_count") >= 1
    @test json_int("separated_candidate_count") >= 1
    @test !json_bool("separated_accepted")
    @test occursin("\"next_optimizer_required_absolute_reduction\":", json)
    @test occursin("nonnegative shortwave coefficient-table", json)
    @test json_int("warm_topology_candidate_count") >= 1
    @test !json_bool("warm_topology_improved")
    @test json_int("finite_difference_candidate_count") >= 1
    @test !json_bool("finite_difference_improved")
    @test occursin("\"global_linearized_entry\": {", json)
    @test occursin("\"subset_search\": {", json)
    @test occursin("\"weighted_selected_shortwave_gpoints\": [", json)
    @test occursin("\"pruned_full_fit_selected_shortwave_gpoints\": [", json)
    @test occursin("\"hardgate_selected_shortwave_gpoints\": [", json)
    @test occursin("\"selected_shortwave_weights_present\": true", json)
    @test occursin("\"support_swap_scan\": {", json)
    @test occursin("\"support_swap_continuation_scan\": {", json)
    @test occursin("\"support_expansion_scan\": {", json)
    @test occursin("\"support_expansion_refit_scan\": {", json)
    @test occursin("\"random_support_search\": {", json)
    @test occursin("\"optical_depth_fit\": {", json)
    @test occursin("\"status\": \"optical_depth_refit_target_ready\"", json)
    @test occursin("\"component_relative_rmse_reduction\":", json)
    @test occursin("\"flux_component_scaled_improved\": false", json)
    @test occursin("\"pressure_band_refinement\": {", json)
    @test occursin("\"status\": \"pressure_band_move_improved\"", json)
    @test occursin("\"iterative_accepted_move_count\":", json)
    @test occursin("\"iterative_final_objective\":", json)
    @test occursin("\"iterative_improved\": true", json)
    @test parsed["boundary_column_refinement"]["present"]
    @test parsed["boundary_column_block_refinement"]["present"]
    @test parsed["slot_blend_refinement"]["present"]
    @test parsed["pair_slot_blend_refinement"]["present"]
    @test parsed["slot_blend_linearized"]["present"]
    @test parsed["post_slot_weight_refit"]["present"]
    @test parsed["gas_pressure_band_refinement"]["present"]
    @test parsed["gas_pressure_band_linearized"]["present"]
    @test parsed["flux_pair_bins"]["present"]
    @test parsed["grouped_quadrature_search"]["present"]
    @test parsed["grouped_quadrature_weight_refit"]["present"]
    @test parsed["weight_maxnorm_refit"]["present"]
    @test parsed["constrained_table_optimizer"]["present"]
    @test parsed["constrained_table_optimizer"]["candidate_scope"] == "all_global_residual_probe"
    @test parsed["constrained_table_optimizer"]["include_rayleigh"]
    @test parsed["topology_constrained_optimizer"]["present"]
    @test parsed["post_constrained_weight_refit"]["present"]
    @test parsed["post_constrained_boundary_weight_refit"]["present"]
    @test parsed["hardgate_subset_search"]["present"]
    @test parsed["boundary_topology_replacement"]["present"]
    @test parsed["boundary_topology_weight_refit"]["present"]
    @test parsed["boundary_table_coordinate_scan"]["present"]
    @test parsed["boundary_table_pair_coordinate_scan"]["present"]
    @test parsed["boundary_table_coordinate_descent"]["present"]
    @test parsed["boundary_table_continuation_optimizer"]["present"]
    @test parsed["component_scale_refit"]["present"]
    @test parsed["pressure_component_scale_refit"]["present"]
    @test parsed["temperature_component_scale_refit"]["present"]
    @test parsed["h2o_component_scale_refit"]["present"]
    @test parsed["gas_component_scale_refit"]["present"]
    @test parsed["pressure_temperature_component_scale_refit"]["present"]
    @test parsed["gas_pressure_temperature_component_scale_refit"]["present"]
    @test parsed["h2o_pressure_temperature_component_scale_refit"]["present"]
    @test parsed["mixed_pressure_temperature_component_refit"]["present"]
    @test parsed["retained_mixed_component_pareto_scan"]["present"]
    @test parsed["retained_topology_neighbor_scan"]["present"]
    @test parsed["retained_topology_constrained_optimizer"]["present"]
    @test parsed["structural_optimizer_sweep"]["present"]
    @test parsed["retained_structural_optimizer"]["present"]
    @test parsed["retained_structural_continuation"]["present"]
    @test parsed["retained_structural_continuation2"]["present"]
    @test parsed["retained_structural_continuation3"]["present"]
    @test parsed["retained_structural_continuation4"]["present"]
    @test parsed["retained_structural_pareto_probe"]["present"]
    @test parsed["retained_quadrature_pareto_scan"]["present"]
    @test parsed["retained_quadrature_pair_pareto_scan"]["present"]
    @test parsed["retained_quadrature_linearized_optimizer"]["present"]
    @test parsed["retained_current_quadrature_linearized_optimizer"]["present"]
    @test parsed["retained_current_bounded_table_optimizer"]["present"]
    @test parsed["retained_current_heating_profile_optimizer"]["present"]
    @test parsed["retained_current_joint_heating_optimizer"]["present"]
    @test parsed["retained_current_component_scale_optimizer"]["present"]
    @test parsed["retained_capped_table_optimizer"]["present"]
    @test parsed["retained_capped_table_continuation"]["present"]
    @test parsed["retained_post_capped_weight_refit"]["present"]
    @test parsed["retained_post_weight_surface_table_refit"]["present"]
    @test parsed["retained_post_weight_bounded_weight_refit"]["present"]
    @test parsed["retained_table_coordinate_pareto_scan"]["present"]
    @test parsed["retained_objective_probe_expansion"]["present"]
    @test parsed["retained_objective_probe_expansion2"]["present"]
    @test parsed["retained_objective_probe_expansion3"]["present"]
    @test parsed["retained_objective_probe_expansion4"]["present"]
    @test parsed["retained_surface_probe_expansion"]["present"]
    @test parsed["retained_surface_probe_expansion2"]["present"]
    @test parsed["retained_surface_probe_expansion3"]["present"]
    @test parsed["retained_boundary_probe_expansion"]["present"]
    @test parsed["retained_toa_probe_expansion"]["present"]
    @test parsed["boundary_table_triple_coordinate_scan"]["present"]
    @test !parsed["gas_pressure_band_linearized"]["accepted"]
    @test !parsed["flux_pair_bins"]["passed_hard_thresholds"]
    @test !parsed["grouped_quadrature_search"]["passed_hard_thresholds"]
    @test !parsed["grouped_quadrature_weight_refit"]["passed_hard_thresholds"]
    @test !parsed["weight_maxnorm_refit"]["accepted"]
    @test !parsed["hardgate_subset_search"]["passed_hard_thresholds"]
    @test parsed["boundary_topology_replacement"]["status"] ==
          "topology_replacement_rejected"
    @test parsed["boundary_topology_weight_refit"]["status"] ==
          "topology_weight_refit_rejected"
    @test parsed["boundary_table_coordinate_scan"]["accepted"]
    @test parsed["boundary_table_pair_coordinate_scan"]["accepted"]
    @test parsed["boundary_table_coordinate_descent"]["accepted"]
    @test parsed["boundary_table_continuation_optimizer"]["accepted"]
    @test parsed["boundary_table_continuation_optimizer"]["base_mode"] ==
          "boundary_table_post_descent"
    @test parsed["component_scale_refit"]["accepted"]
    @test parsed["component_scale_refit"]["base_mode"] ==
          "boundary_table_post_descent_plus_continuation"
    @test parsed["pressure_component_scale_refit"]["accepted"]
    @test parsed["pressure_component_scale_refit"]["base_mode"] ==
          "component_scale_refit"
    @test parsed["temperature_component_scale_refit"]["base_mode"] ==
          "pressure_component_scale_refit"
    @test parsed["h2o_component_scale_refit"]["base_mode"] ==
          "temperature_component_scale_refit"
    @test parsed["gas_component_scale_refit"]["base_mode"] ==
          "h2o_component_scale_refit"
    @test parsed["pressure_temperature_component_scale_refit"]["base_mode"] ==
          "gas_component_scale_refit"
    @test parsed["pressure_temperature_component_scale_refit"]["objective_mode"] ==
          "full"
    @test parsed["gas_pressure_temperature_component_scale_refit"]["base_mode"] ==
          "pressure_temperature_component_scale_refit"
    @test parsed["h2o_pressure_temperature_component_scale_refit"]["base_mode"] ==
          "gas_pressure_temperature_component_scale_refit"
    @test parsed["mixed_pressure_temperature_component_refit"]["base_mode"] ==
          "h2o_pressure_temperature_component_scale_refit"
    @test parsed["boundary_table_triple_coordinate_scan"]["accepted"]
    @test !parsed["pair_slot_blend_refinement"]["accepted"]
    @test !parsed["slot_blend_linearized"]["accepted"]
    @test parsed["post_slot_weight_refit"]["accepted"]
    @test parsed["constrained_table_optimizer"]["best_exact_objective"] > 1
    @test parsed["topology_constrained_optimizer"]["best_exact_objective"] > 1
    @test parsed["topology_constrained_optimizer"]["topology_count"] >= 1
    @test parsed["post_constrained_weight_refit"]["final_objective"] > 1
    @test parsed["post_constrained_boundary_weight_refit"]["final_boundary_objective"] > 1
    @test parsed["flux_pair_bins"]["objective"] > 1
    @test parsed["grouped_quadrature_search"]["best_objective"] > 1
    @test parsed["grouped_quadrature_weight_refit"]["best_refit_objective"] > 1
    @test parsed["grouped_quadrature_weight_refit"]["best_refit_objective"] <=
          parsed["grouped_quadrature_weight_refit"]["best_base_objective"]
    @test parsed["weight_maxnorm_refit"]["best_exact_objective"] > 1
    @test parsed["hardgate_subset_search"]["exact_objective"] > 1
    @test length(parsed["hardgate_subset_search"]["selected_shortwave_gpoints"]) == 16
    @test parsed["boundary_topology_replacement"]["best_objective"] >
          parsed["boundary_topology_replacement"]["base_objective"]
    @test parsed["boundary_topology_weight_refit"]["best_objective"] >
          parsed["boundary_topology_weight_refit"]["base_objective"]
    @test parsed["boundary_table_coordinate_scan"]["best_objective"] <=
          parsed["boundary_table_coordinate_scan"]["base_objective"]
    @test parsed["boundary_table_pair_coordinate_scan"]["best_objective"] <=
          parsed["boundary_table_pair_coordinate_scan"]["base_objective"]
    @test parsed["boundary_table_coordinate_descent"]["final_objective"] <=
          parsed["boundary_table_coordinate_descent"]["baseline_objective"]
    @test parsed["boundary_table_continuation_optimizer"]["best_exact_objective"] <=
          parsed["boundary_table_continuation_optimizer"]["base_objective"]
    @test parsed["component_scale_refit"]["final_objective"] <=
          parsed["component_scale_refit"]["base_objective"]
    @test parsed["pressure_component_scale_refit"]["final_objective"] <=
          parsed["pressure_component_scale_refit"]["base_objective"]
    @test parsed["temperature_component_scale_refit"]["final_objective"] <=
          parsed["temperature_component_scale_refit"]["base_objective"]
    @test parsed["h2o_component_scale_refit"]["final_objective"] <=
          parsed["h2o_component_scale_refit"]["base_objective"]
    @test parsed["gas_component_scale_refit"]["final_objective"] <=
          parsed["gas_component_scale_refit"]["base_objective"]
    @test parsed["pressure_temperature_component_scale_refit"]["final_objective"] <=
          parsed["pressure_temperature_component_scale_refit"]["base_objective"]
    @test parsed["gas_pressure_temperature_component_scale_refit"]["final_objective"] <=
          parsed["gas_pressure_temperature_component_scale_refit"]["base_objective"]
    @test parsed["h2o_pressure_temperature_component_scale_refit"]["final_objective"] <=
          parsed["h2o_pressure_temperature_component_scale_refit"]["base_objective"]
    @test parsed["mixed_pressure_temperature_component_refit"]["final_objective"] <=
          parsed["mixed_pressure_temperature_component_refit"]["base_objective"]
    @test parsed["retained_mixed_component_pareto_scan"]["status"] ==
          "retained_mixed_component_scan_improved"
    @test startswith(
        parsed["retained_mixed_component_pareto_scan"]["acceptance_rule"],
        "bounded_frontier",
    )
    @test parsed["retained_mixed_component_pareto_scan"]["pareto_tolerance"] <=
          0.01
    @test haskey(parsed["retained_mixed_component_pareto_scan"],
                 "surface_cap_w_m2")
    @test parsed["retained_mixed_component_pareto_scan"]["best_exact_objective"] <
          parsed["retained_mixed_component_pareto_scan"]["base_objective"]
    @test parsed["retained_mixed_component_pareto_scan"]["any_pareto_safe"]
    @test parsed["retained_mixed_component_pareto_scan"]["accepted"]
    @test parsed["retained_mixed_component_pareto_scan"]["final_worst_surface_forcing_error_w_m2"] <
          2.03
    @test parsed["retained_topology_neighbor_scan"]["status"] ==
          "retained_topology_neighbor_rejected"
    @test parsed["retained_topology_neighbor_scan"]["candidate_count"] >= 1
    @test parsed["retained_topology_neighbor_scan"]["pair_candidate_count"] >= 1
    @test parsed["retained_topology_neighbor_scan"]["best_objective"] >
          parsed["retained_topology_neighbor_scan"]["base_objective"]
    @test !parsed["retained_topology_neighbor_scan"]["pareto_safe"]
    @test !parsed["retained_topology_neighbor_scan"]["passed_hard_thresholds"]
    @test parsed["retained_topology_constrained_optimizer"]["status"] ==
          "constrained_table_optimizer_rejected"
    @test parsed["retained_topology_constrained_optimizer"]["best_exact_objective"] >
          parsed["retained_topology_constrained_optimizer"]["base_objective"]
    @test !parsed["retained_topology_constrained_optimizer"]["pareto_safe"]
    @test !parsed["retained_topology_constrained_optimizer"]["accepted"]
    @test parsed["retained_quadrature_linearized_optimizer"]["status"] ==
          "quadrature_linearized_optimizer_rejected"
    @test parsed["retained_quadrature_linearized_optimizer"]["best_exact_objective"] >
          parsed["retained_quadrature_linearized_optimizer"]["base_objective"]
    @test !parsed["retained_quadrature_linearized_optimizer"]["any_pareto_safe"]
    @test !parsed["retained_quadrature_linearized_optimizer"]["accepted"]
    @test parsed["retained_current_quadrature_linearized_optimizer"]["status"] in
          ("current_quadrature_linearized_optimizer_improved",
           "current_quadrature_linearized_optimizer_rejected")
    if parsed["retained_current_quadrature_linearized_optimizer"]["accepted"]
        @test parsed["retained_current_quadrature_linearized_optimizer"]["status"] ==
              "current_quadrature_linearized_optimizer_improved"
        @test parsed["retained_current_quadrature_linearized_optimizer"]["accepted_objective"] <
              parsed["retained_current_quadrature_linearized_optimizer"]["base_objective"]
        @test parsed["retained_current_quadrature_linearized_optimizer"]["accepted_worst_toa_forcing_error_w_m2"] <=
              parsed["retained_current_quadrature_linearized_optimizer"]["base_worst_toa_forcing_error_w_m2"] +
              parsed["retained_current_quadrature_linearized_optimizer"]["toa_tolerance_w_m2"]
        @test parsed["retained_current_quadrature_linearized_optimizer"]["accepted_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_current_quadrature_linearized_optimizer"]["surface_cap_w_m2"]
    else
        @test parsed["retained_current_quadrature_linearized_optimizer"]["status"] ==
              "current_quadrature_linearized_optimizer_rejected"
        @test parsed["retained_current_quadrature_linearized_optimizer"]["best_exact_objective"] >
              parsed["retained_current_quadrature_linearized_optimizer"]["base_objective"]
    end
    @test parsed["retained_current_bounded_table_optimizer"]["status"] in
          ("current_bounded_table_optimizer_improved",
           "current_bounded_table_optimizer_rejected")
    if parsed["retained_current_bounded_table_optimizer"]["accepted"]
        @test parsed["retained_current_bounded_table_optimizer"]["status"] ==
              "current_bounded_table_optimizer_improved"
        @test parsed["retained_current_bounded_table_optimizer"]["accepted_objective"] <
              parsed["retained_current_bounded_table_optimizer"]["base_objective"]
        @test parsed["retained_current_bounded_table_optimizer"]["accepted_worst_toa_forcing_error_w_m2"] <=
              parsed["retained_current_bounded_table_optimizer"]["base_worst_toa_forcing_error_w_m2"] +
              parsed["retained_current_bounded_table_optimizer"]["toa_tolerance_w_m2"]
        @test parsed["retained_current_bounded_table_optimizer"]["accepted_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_current_bounded_table_optimizer"]["surface_cap_w_m2"]
        @test parsed["retained_current_bounded_table_optimizer"]["accepted_objective_reduction"] >=
              parsed["retained_current_bounded_table_optimizer"]["min_objective_reduction"]
        @test parsed["retained_current_bounded_table_optimizer"]["accepted_move_count"] > 0
    else
        @test parsed["retained_current_bounded_table_optimizer"]["status"] ==
              "current_bounded_table_optimizer_rejected"
        @test parsed["retained_current_bounded_table_optimizer"]["best_exact_objective"] >=
              parsed["retained_current_bounded_table_optimizer"]["base_objective"]
    end
    @test parsed["retained_current_heating_profile_optimizer"]["status"] in
          ("current_heating_profile_optimizer_improved",
           "current_heating_profile_optimizer_rejected")
    @test parsed["retained_current_heating_profile_optimizer"]["residual_mode"] ==
          "heating_profile_boundary"
    @test parsed["retained_current_heating_profile_optimizer"]["candidate_count"] >= 1
    if parsed["retained_current_heating_profile_optimizer"]["accepted"]
        @test parsed["retained_current_heating_profile_optimizer"]["accepted_objective"] <
              parsed["retained_current_heating_profile_optimizer"]["base_objective"]
        @test parsed["retained_current_heating_profile_optimizer"]["accepted_worst_toa_forcing_error_w_m2"] <=
              parsed["retained_current_heating_profile_optimizer"]["base_worst_toa_forcing_error_w_m2"] +
              parsed["retained_current_heating_profile_optimizer"]["toa_tolerance_w_m2"]
        @test parsed["retained_current_heating_profile_optimizer"]["accepted_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_current_heating_profile_optimizer"]["surface_cap_w_m2"]
        @test parsed["retained_current_heating_profile_optimizer"]["accepted_worst_heating_rate_rmse_k_day"] <=
              parsed["retained_current_heating_profile_optimizer"]["base_worst_heating_rate_rmse_k_day"]
        @test parsed["retained_current_heating_profile_optimizer"]["accepted_move_count"] > 0
    else
        @test parsed["retained_current_heating_profile_optimizer"]["status"] ==
              "current_heating_profile_optimizer_rejected"
        @test parsed["retained_current_heating_profile_optimizer"]["best_exact_objective"] >=
              parsed["retained_current_heating_profile_optimizer"]["base_objective"]
    end
    @test parsed["retained_current_joint_heating_optimizer"]["status"] in
          ("current_joint_heating_optimizer_improved",
           "current_joint_heating_optimizer_rejected")
    @test parsed["retained_current_joint_heating_optimizer"]["residual_mode"] ==
          "heating_profile_boundary"
    @test parsed["retained_current_joint_heating_optimizer"]["basis"] ==
          "quadrature_logits_plus_active_table_entries"
    @test parsed["retained_current_joint_heating_optimizer"]["basis_count"] ==
          parsed["retained_current_joint_heating_optimizer"]["logit_basis_count"] +
          parsed["retained_current_joint_heating_optimizer"]["table_candidate_count"]
    if parsed["retained_current_joint_heating_optimizer"]["accepted"]
        @test parsed["retained_current_joint_heating_optimizer"]["accepted_objective"] <
              parsed["retained_current_joint_heating_optimizer"]["base_objective"]
        @test parsed["retained_current_joint_heating_optimizer"]["accepted_worst_toa_forcing_error_w_m2"] <=
              parsed["retained_current_joint_heating_optimizer"]["base_worst_toa_forcing_error_w_m2"] +
              parsed["retained_current_joint_heating_optimizer"]["toa_tolerance_w_m2"]
        @test parsed["retained_current_joint_heating_optimizer"]["accepted_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_current_joint_heating_optimizer"]["surface_cap_w_m2"]
        @test parsed["retained_current_joint_heating_optimizer"]["accepted_worst_heating_rate_rmse_k_day"] <=
              parsed["retained_current_joint_heating_optimizer"]["base_worst_heating_rate_rmse_k_day"]
    else
        @test parsed["retained_current_joint_heating_optimizer"]["status"] ==
              "current_joint_heating_optimizer_rejected"
        @test parsed["retained_current_joint_heating_optimizer"]["best_exact_objective"] >=
              parsed["retained_current_joint_heating_optimizer"]["base_objective"]
    end
    @test parsed["retained_current_component_scale_optimizer"]["status"] in
          ("current_component_scale_optimizer_improved",
           "current_component_scale_optimizer_rejected")
    @test parsed["retained_current_component_scale_optimizer"]["residual_mode"] ==
          "heating_profile_boundary"
    @test parsed["retained_current_component_scale_optimizer"]["basis"] ==
          "per_gpoint_static_h2o_rayleigh_component_scales"
    @test parsed["retained_current_component_scale_optimizer"]["basis_count"] == 48
    if parsed["retained_current_component_scale_optimizer"]["accepted"]
        @test parsed["retained_current_component_scale_optimizer"]["accepted_objective"] <
              parsed["retained_current_component_scale_optimizer"]["base_objective"]
        @test parsed["retained_current_component_scale_optimizer"]["accepted_worst_toa_forcing_error_w_m2"] <=
              parsed["retained_current_component_scale_optimizer"]["base_worst_toa_forcing_error_w_m2"] +
              parsed["retained_current_component_scale_optimizer"]["toa_tolerance_w_m2"]
        @test parsed["retained_current_component_scale_optimizer"]["accepted_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_current_component_scale_optimizer"]["surface_cap_w_m2"]
        @test parsed["retained_current_component_scale_optimizer"]["accepted_worst_heating_rate_rmse_k_day"] <=
              parsed["retained_current_component_scale_optimizer"]["base_worst_heating_rate_rmse_k_day"]
    else
        @test parsed["retained_current_component_scale_optimizer"]["status"] ==
              "current_component_scale_optimizer_rejected"
    end
    @test parsed["retained_current_component_scale_optimizer2"]["status"] in
          ("current_component_scale_optimizer2_improved",
           "current_component_scale_optimizer2_rejected")
    @test parsed["retained_current_component_scale_optimizer2"]["residual_mode"] ==
          "heating_profile_boundary"
    @test parsed["retained_current_component_scale_optimizer2"]["basis"] ==
          "second_pass_per_gpoint_static_h2o_rayleigh_component_scales"
    @test parsed["retained_current_component_scale_optimizer2"]["basis_count"] == 48
    if parsed["retained_current_component_scale_optimizer2"]["accepted"]
        @test parsed["retained_current_component_scale_optimizer2"]["accepted_objective"] <
              parsed["retained_current_component_scale_optimizer2"]["base_objective"]
        @test parsed["retained_current_component_scale_optimizer2"]["accepted_worst_toa_forcing_error_w_m2"] <=
              parsed["retained_current_component_scale_optimizer2"]["base_worst_toa_forcing_error_w_m2"] +
              parsed["retained_current_component_scale_optimizer2"]["toa_tolerance_w_m2"]
        @test parsed["retained_current_component_scale_optimizer2"]["accepted_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_current_component_scale_optimizer2"]["surface_cap_w_m2"]
        @test parsed["retained_current_component_scale_optimizer2"]["accepted_worst_heating_rate_rmse_k_day"] <=
              parsed["retained_current_component_scale_optimizer2"]["base_worst_heating_rate_rmse_k_day"]
    else
        @test parsed["retained_current_component_scale_optimizer2"]["status"] ==
              "current_component_scale_optimizer2_rejected"
    end
    @test parsed["retained_current_component_scale_optimizer3"]["status"] in
          ("current_component_scale_optimizer3_improved",
           "current_component_scale_optimizer3_rejected")
    @test parsed["retained_current_component_scale_optimizer3"]["residual_mode"] ==
          "heating_profile_boundary"
    @test parsed["retained_current_component_scale_optimizer3"]["basis"] ==
          "third_pass_per_gpoint_static_h2o_rayleigh_component_scales"
    @test parsed["retained_current_component_scale_optimizer3"]["basis_count"] == 48
    if parsed["retained_current_component_scale_optimizer3"]["accepted"]
        @test parsed["retained_current_component_scale_optimizer3"]["accepted_objective"] <
              parsed["retained_current_component_scale_optimizer3"]["base_objective"]
        @test parsed["retained_current_component_scale_optimizer3"]["accepted_worst_toa_forcing_error_w_m2"] <=
              parsed["retained_current_component_scale_optimizer3"]["base_worst_toa_forcing_error_w_m2"] +
              parsed["retained_current_component_scale_optimizer3"]["toa_tolerance_w_m2"]
        @test parsed["retained_current_component_scale_optimizer3"]["accepted_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_current_component_scale_optimizer3"]["surface_cap_w_m2"]
        @test parsed["retained_current_component_scale_optimizer3"]["accepted_worst_heating_rate_rmse_k_day"] <=
              parsed["retained_current_component_scale_optimizer3"]["base_worst_heating_rate_rmse_k_day"]
    else
        @test parsed["retained_current_component_scale_optimizer3"]["status"] ==
              "current_component_scale_optimizer3_rejected"
    end
    @test parsed["retained_current_component_scale_optimizer4"]["status"] in
          ("current_component_scale_optimizer4_improved",
           "current_component_scale_optimizer4_rejected")
    @test parsed["retained_current_component_scale_optimizer4"]["residual_mode"] ==
          "heating_profile_boundary"
    @test parsed["retained_current_component_scale_optimizer4"]["basis"] ==
          "fourth_pass_per_gpoint_static_h2o_rayleigh_component_scales"
    @test parsed["retained_current_component_scale_optimizer4"]["basis_count"] == 48
    if parsed["retained_current_component_scale_optimizer4"]["accepted"]
        @test parsed["retained_current_component_scale_optimizer4"]["accepted_objective"] <
              parsed["retained_current_component_scale_optimizer4"]["base_objective"]
        @test parsed["retained_current_component_scale_optimizer4"]["accepted_worst_toa_forcing_error_w_m2"] <=
              parsed["retained_current_component_scale_optimizer4"]["base_worst_toa_forcing_error_w_m2"] +
              parsed["retained_current_component_scale_optimizer4"]["toa_tolerance_w_m2"]
        @test parsed["retained_current_component_scale_optimizer4"]["accepted_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_current_component_scale_optimizer4"]["surface_cap_w_m2"]
        @test parsed["retained_current_component_scale_optimizer4"]["accepted_worst_heating_rate_rmse_k_day"] <=
              parsed["retained_current_component_scale_optimizer4"]["base_worst_heating_rate_rmse_k_day"]
    else
        @test parsed["retained_current_component_scale_optimizer4"]["status"] ==
              "current_component_scale_optimizer4_rejected"
    end
    @test parsed["retained_current_pressure_component_optimizer"]["status"] in
          ("current_pressure_component_optimizer_improved",
           "current_pressure_component_optimizer_rejected")
    @test parsed["retained_current_pressure_component_optimizer"]["residual_mode"] ==
          "heating_profile_boundary"
    @test parsed["retained_current_pressure_component_optimizer"]["basis"] ==
          "per_gpoint_pressure_band_static_h2o_component_scales"
    @test parsed["retained_current_pressure_component_optimizer"]["basis_count"] == 128
    @test parsed["retained_current_pressure_component_optimizer"]["pressure_band_count"] == 4
    if parsed["retained_current_pressure_component_optimizer"]["accepted"]
        @test parsed["retained_current_pressure_component_optimizer"]["accepted_objective"] <
              parsed["retained_current_pressure_component_optimizer"]["base_objective"]
        @test parsed["retained_current_pressure_component_optimizer"]["accepted_worst_toa_forcing_error_w_m2"] <=
              parsed["retained_current_pressure_component_optimizer"]["base_worst_toa_forcing_error_w_m2"] +
              parsed["retained_current_pressure_component_optimizer"]["toa_tolerance_w_m2"]
        @test parsed["retained_current_pressure_component_optimizer"]["accepted_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_current_pressure_component_optimizer"]["surface_cap_w_m2"]
        @test parsed["retained_current_pressure_component_optimizer"]["accepted_worst_heating_rate_rmse_k_day"] <=
              parsed["retained_current_pressure_component_optimizer"]["base_worst_heating_rate_rmse_k_day"]
    else
        @test parsed["retained_current_pressure_component_optimizer"]["status"] ==
              "current_pressure_component_optimizer_rejected"
    end
    @test parsed["retained_current_pressure_component_scan"]["status"] in
          ("current_pressure_component_scan_improved",
           "current_pressure_component_scan_rejected")
    @test parsed["retained_current_pressure_component_scan"]["residual_mode"] ==
          "heating_profile_boundary"
    @test parsed["retained_current_pressure_component_scan"]["basis"] ==
          "per_gpoint_pressure_band_static_h2o_component_scales"
    if parsed["retained_current_pressure_component_scan"]["accepted"]
        @test parsed["retained_current_pressure_component_scan"]["selected_partition"] ==
              "log_pressure"
        @test parsed["retained_current_pressure_component_scan"]["selected_pressure_band_count"] == 8
        @test parsed["retained_current_pressure_component_scan"]["selected_basis_count"] == 256
        @test parsed["retained_current_pressure_component_scan"]["selected_accepted_move_count"] > 0
        @test parsed["retained_current_pressure_component_scan"]["selected_objective"] <
              parsed["retained_current_pressure_component_scan"]["base_objective"]
        @test parsed["retained_current_pressure_component_scan"]["selected_worst_toa_forcing_error_w_m2"] <=
              parsed["retained_current_pressure_component_scan"]["base_worst_toa_forcing_error_w_m2"] +
              parsed["retained_current_pressure_component_scan"]["toa_tolerance_w_m2"]
        @test parsed["retained_current_pressure_component_scan"]["selected_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_current_pressure_component_scan"]["surface_cap_w_m2"]
    else
        @test parsed["retained_current_pressure_component_scan"]["status"] ==
              "current_pressure_component_scan_rejected"
    end
    @test parsed["retained_current_pressure_component_rayleigh_scan"]["present"]
    @test parsed["retained_current_pressure_component_rayleigh_scan"]["include_rayleigh"]
    @test parsed["retained_current_pressure_component_rayleigh_scan"]["selected_objective"] >=
          parsed["retained_current_pressure_component_scan"]["selected_objective"]
    @test parsed["retained_current_pressure_component_surface_guard_scan"]["present"]
    @test parsed["retained_current_pressure_component_surface_guard_scan"]["surface_cap_w_m2"] <=
          2.02
    @test parsed["retained_current_pressure_component_surface_guard_scan"]["selected_worst_surface_forcing_error_w_m2"] <=
          parsed["retained_current_pressure_component_surface_guard_scan"]["surface_cap_w_m2"]
    @test parsed["retained_current_pressure_component_surface_guard_scan"]["selected_objective"] >=
          parsed["retained_current_pressure_component_scan"]["selected_objective"]
    @test parsed["retained_current_gas_pressure_component_scan"]["present"]
    @test parsed["retained_current_gas_pressure_component_scan"]["status"] in
          ("current_pressure_component_scan_improved",
           "current_pressure_component_scan_rejected")
    @test parsed["retained_current_gas_pressure_component_scan"]["residual_mode"] ==
          "heating_profile_boundary"
    @test parsed["retained_current_gas_pressure_component_scan"]["basis"] ==
          "per_gpoint_pressure_band_static_gas_h2o_component_scales"
    @test !parsed["retained_current_gas_pressure_component_scan"]["include_rayleigh"]
    @test parsed["retained_current_gas_pressure_component_scan"]["static_gas_split"]
    if parsed["retained_current_gas_pressure_component_scan"]["accepted"]
        @test parsed["retained_current_gas_pressure_component_scan"]["selected_partition"] ==
              "log_pressure"
        @test parsed["retained_current_gas_pressure_component_scan"]["selected_pressure_band_count"] == 4
        @test parsed["retained_current_gas_pressure_component_scan"]["selected_basis_count"] == 576
        @test parsed["retained_current_gas_pressure_component_scan"]["selected_accepted_move_count"] > 0
        @test parsed["retained_current_gas_pressure_component_scan"]["selected_objective"] <
              parsed["retained_current_pressure_component_scan"]["selected_objective"]
        @test parsed["retained_current_gas_pressure_component_scan"]["selected_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_current_gas_pressure_component_scan"]["surface_cap_w_m2"]
    else
        @test parsed["retained_current_gas_pressure_component_scan"]["status"] ==
              "current_pressure_component_scan_rejected"
    end
    @test parsed["retained_current_gas_pressure_component_continuation_scan"]["present"]
    @test parsed["retained_current_gas_pressure_component_continuation_scan"]["status"] in
          ("current_pressure_component_scan_improved",
           "current_pressure_component_scan_rejected")
    @test parsed["retained_current_gas_pressure_component_continuation_scan"]["basis"] ==
          "per_gpoint_pressure_band_static_gas_h2o_component_scales"
    @test parsed["retained_current_gas_pressure_component_continuation_scan"]["static_gas_split"]
    if parsed["retained_current_gas_pressure_component_continuation_scan"]["accepted"]
        @test parsed["retained_current_gas_pressure_component_continuation_scan"]["selected_partition"] ==
              "log_pressure"
        @test parsed["retained_current_gas_pressure_component_continuation_scan"]["selected_pressure_band_count"] == 4
        @test parsed["retained_current_gas_pressure_component_continuation_scan"]["selected_basis_count"] == 576
        @test parsed["retained_current_gas_pressure_component_continuation_scan"]["selected_objective"] <
              parsed["retained_current_gas_pressure_component_scan"]["selected_objective"]
        @test parsed["retained_current_gas_pressure_component_continuation_scan"]["selected_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_current_gas_pressure_component_continuation_scan"]["surface_cap_w_m2"]
    else
        @test parsed["retained_current_gas_pressure_component_continuation_scan"]["status"] ==
              "current_pressure_component_scan_rejected"
    end
    @test parsed["retained_current_gas_pressure_component_continuation2_scan"]["present"]
    @test parsed["retained_current_gas_pressure_component_continuation2_scan"]["status"] in
          ("current_pressure_component_scan_improved",
           "current_pressure_component_scan_rejected")
    @test parsed["retained_current_gas_pressure_component_continuation2_scan"]["basis"] ==
          "per_gpoint_pressure_band_static_gas_h2o_component_scales"
    @test parsed["retained_current_gas_pressure_component_continuation2_scan"]["static_gas_split"]
    @test parsed["retained_current_gas_pressure_component_continuation2_scan"]["heating_weight"] >= 1
    if parsed["retained_current_gas_pressure_component_continuation2_scan"]["accepted"]
        @test parsed["retained_current_gas_pressure_component_continuation2_scan"]["selected_partition"] ==
              "log_pressure"
        @test parsed["retained_current_gas_pressure_component_continuation2_scan"]["selected_pressure_band_count"] == 4
        @test parsed["retained_current_gas_pressure_component_continuation2_scan"]["selected_basis_count"] == 576
        @test parsed["retained_current_gas_pressure_component_continuation2_scan"]["selected_objective"] <
              parsed["retained_current_gas_pressure_component_continuation_scan"]["selected_objective"]
        @test parsed["retained_current_gas_pressure_component_continuation2_scan"]["selected_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_current_gas_pressure_component_continuation2_scan"]["surface_cap_w_m2"]
        @test parsed["retained_current_gas_pressure_component_continuation2_scan"]["selected_worst_heating_rate_rmse_k_day"] <=
              parsed["retained_current_gas_pressure_component_continuation_scan"]["selected_worst_heating_rate_rmse_k_day"]
    else
        @test parsed["retained_current_gas_pressure_component_continuation2_scan"]["status"] ==
              "current_pressure_component_scan_rejected"
    end
    @test parsed["retained_current_gas_pressure_component_continuation3_scan"]["present"]
    @test parsed["retained_current_gas_pressure_component_continuation3_scan"]["status"] in
          ("current_pressure_component_scan_improved",
           "current_pressure_component_scan_rejected")
    @test parsed["retained_current_gas_pressure_component_continuation3_scan"]["basis"] ==
          "per_gpoint_pressure_band_static_gas_h2o_component_scales"
    @test parsed["retained_current_gas_pressure_component_continuation3_scan"]["static_gas_split"]
    @test parsed["retained_current_gas_pressure_component_continuation3_scan"]["heating_weight"] >=
          parsed["retained_current_gas_pressure_component_continuation2_scan"]["heating_weight"]
    if parsed["retained_current_gas_pressure_component_continuation3_scan"]["accepted"]
        @test parsed["retained_current_gas_pressure_component_continuation3_scan"]["selected_partition"] ==
              "log_pressure"
        @test parsed["retained_current_gas_pressure_component_continuation3_scan"]["selected_pressure_band_count"] == 4
        @test parsed["retained_current_gas_pressure_component_continuation3_scan"]["selected_basis_count"] == 576
        @test parsed["retained_current_gas_pressure_component_continuation3_scan"]["selected_objective"] <
              parsed["retained_current_gas_pressure_component_continuation2_scan"]["selected_objective"]
        @test parsed["retained_current_gas_pressure_component_continuation3_scan"]["selected_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_current_gas_pressure_component_continuation3_scan"]["surface_cap_w_m2"]
        @test parsed["retained_current_gas_pressure_component_continuation3_scan"]["selected_worst_heating_rate_rmse_k_day"] <=
              parsed["retained_current_gas_pressure_component_continuation2_scan"]["selected_worst_heating_rate_rmse_k_day"]
    else
        @test parsed["retained_current_gas_pressure_component_continuation3_scan"]["status"] ==
              "current_pressure_component_scan_rejected"
    end
    @test parsed["retained_capped_table_optimizer"]["status"] ==
          "retained_capped_table_optimizer_improved"
    @test parsed["retained_capped_table_optimizer"]["residual_mode"] == "surface"
    @test parsed["retained_capped_table_optimizer"]["surface_cap_w_m2"] <= 2.03
    @test parsed["retained_capped_table_optimizer"]["cap_safe_present"]
    @test parsed["retained_capped_table_optimizer"]["best_cap_safe_exact_objective"] <
          parsed["retained_capped_table_optimizer"]["base_objective"]
    @test parsed["retained_capped_table_optimizer"]["best_cap_safe_toa_forcing_error_w_m2"] <
          parsed["retained_capped_table_optimizer"]["base_worst_toa_forcing_error_w_m2"]
    @test parsed["retained_capped_table_optimizer"]["best_cap_safe_surface_forcing_error_w_m2"] <
          parsed["retained_capped_table_optimizer"]["surface_cap_w_m2"]
    if parsed["retained_capped_table_optimizer"]["best_unsafe_surface_forcing_error_w_m2"] !== nothing
        @test parsed["retained_capped_table_optimizer"]["best_unsafe_surface_forcing_error_w_m2"] >
              parsed["retained_capped_table_optimizer"]["surface_cap_w_m2"]
    end
    @test parsed["retained_capped_table_optimizer"]["accepted"]
    @test parsed["retained_capped_table_optimizer"]["accepted_move_count"] > 0
    @test parsed["retained_capped_table_optimizer"]["accepted_move_count"] <=
          parsed["retained_capped_table_optimizer"]["candidate_count"]
    @test parsed["retained_capped_table_continuation"]["status"] ==
          "retained_capped_table_continuation_improved"
    @test parsed["retained_capped_table_continuation"]["residual_mode"] == "surface"
    @test parsed["retained_capped_table_continuation"]["base_capped_move_count"] ==
          parsed["retained_capped_table_optimizer"]["accepted_move_count"]
    @test parsed["retained_capped_table_continuation"]["best_cap_safe_exact_objective"] <
          parsed["retained_capped_table_continuation"]["base_objective"]
    @test parsed["retained_capped_table_continuation"]["best_cap_safe_toa_forcing_error_w_m2"] <
          parsed["retained_capped_table_continuation"]["base_worst_toa_forcing_error_w_m2"]
    @test parsed["retained_capped_table_continuation"]["best_cap_safe_surface_forcing_error_w_m2"] <
          parsed["retained_capped_table_continuation"]["surface_cap_w_m2"]
    @test parsed["retained_capped_table_continuation"]["accepted"]
    @test parsed["retained_capped_table_continuation"]["accepted_move_count"] > 0
    @test parsed["retained_capped_table_continuation"]["accepted_move_count"] <=
          parsed["retained_capped_table_continuation"]["candidate_count"]
    @test parsed["retained_post_capped_weight_refit"]["status"] in
          ("retained_post_capped_weight_refit_improved",
           "retained_post_capped_weight_refit_rejected")
    if parsed["retained_post_capped_weight_refit"]["accepted"]
        @test parsed["retained_post_capped_weight_refit"]["status"] ==
              "retained_post_capped_weight_refit_improved"
        @test parsed["retained_post_capped_weight_refit"]["refit_objective"] <
              parsed["retained_post_capped_weight_refit"]["base_objective"]
        @test parsed["retained_post_capped_weight_refit"]["refit_worst_toa_forcing_error_w_m2"] <=
              parsed["retained_post_capped_weight_refit"]["base_worst_toa_forcing_error_w_m2"]
        @test parsed["retained_post_capped_weight_refit"]["refit_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_post_capped_weight_refit"]["base_worst_surface_forcing_error_w_m2"]
        @test parsed["retained_post_capped_weight_refit"]["max_abs_weight_delta"] > 0
    else
        @test parsed["retained_post_capped_weight_refit"]["status"] ==
              "retained_post_capped_weight_refit_rejected"
    end
    @test parsed["retained_post_weight_surface_table_refit"]["status"] in
          ("retained_post_weight_surface_table_refit_improved",
           "retained_post_weight_surface_table_refit_rejected")
    if parsed["retained_post_weight_surface_table_refit"]["accepted"]
        @test parsed["retained_post_weight_surface_table_refit"]["best_exact_objective"] <
              parsed["retained_post_weight_surface_table_refit"]["base_objective"]
        @test parsed["retained_post_weight_surface_table_refit"]["accepted_objective_reduction"] >=
              parsed["retained_post_weight_surface_table_refit"]["min_objective_reduction"]
        @test parsed["retained_post_weight_surface_table_refit"]["best_worst_toa_forcing_error_w_m2"] <=
              parsed["retained_post_weight_surface_table_refit"]["base_worst_toa_forcing_error_w_m2"]
        @test parsed["retained_post_weight_surface_table_refit"]["best_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_post_weight_surface_table_refit"]["base_worst_surface_forcing_error_w_m2"]
        @test parsed["retained_post_weight_surface_table_refit"]["accepted_move_count"] > 0
    end
    @test parsed["retained_post_weight_bounded_weight_refit"]["status"] in
          ("retained_post_weight_bounded_weight_refit_improved",
           "retained_post_weight_bounded_weight_refit_rejected")
    if parsed["retained_post_weight_bounded_weight_refit"]["accepted"]
        @test parsed["retained_post_weight_bounded_weight_refit"]["refit_objective"] <
              parsed["retained_post_weight_bounded_weight_refit"]["base_objective"]
        @test parsed["retained_post_weight_bounded_weight_refit"]["refit_worst_toa_forcing_error_w_m2"] <=
              parsed["retained_post_weight_bounded_weight_refit"]["base_worst_toa_forcing_error_w_m2"] +
              parsed["retained_post_weight_bounded_weight_refit"]["toa_tolerance_w_m2"]
        @test parsed["retained_post_weight_bounded_weight_refit"]["refit_worst_surface_forcing_error_w_m2"] <=
              parsed["retained_post_weight_bounded_weight_refit"]["surface_cap_w_m2"]
        @test parsed["retained_post_weight_bounded_weight_refit"]["max_abs_weight_delta"] > 0
    end
    @test parsed["structural_optimizer_sweep"]["status"] ==
          "structural_optimizer_sweep_improved"
    @test parsed["structural_optimizer_sweep"]["config_count"] >= 1
    @test parsed["structural_optimizer_sweep"]["best_exact_objective"] <
          parsed["structural_optimizer_sweep"]["best_base_objective"]
    @test parsed["structural_optimizer_sweep"]["best_worst_toa_forcing_error_w_m2"] >
          0.3
    @test parsed["retained_structural_optimizer"]["accepted"]
    @test parsed["retained_structural_optimizer"]["accepted_move_count"] >= 1
    @test parsed["retained_structural_optimizer"]["best_exact_objective"] <
          parsed["retained_structural_optimizer"]["base_objective"]
    @test parsed["retained_structural_optimizer"]["best_worst_toa_forcing_error_w_m2"] >
          0.3
    @test parsed["retained_structural_continuation"]["accepted"]
    @test parsed["retained_structural_continuation"]["accepted_move_count"] >= 1
    @test parsed["retained_structural_continuation"]["best_exact_objective"] <
          parsed["retained_structural_continuation"]["base_objective"]
    @test parsed["retained_structural_continuation"]["best_worst_toa_forcing_error_w_m2"] >
          0.3
    @test parsed["retained_structural_continuation2"]["accepted"]
    @test parsed["retained_structural_continuation2"]["accepted_move_count"] >= 1
    @test parsed["retained_structural_continuation2"]["best_exact_objective"] <
          parsed["retained_structural_continuation2"]["base_objective"]
    @test parsed["retained_structural_continuation2"]["best_worst_toa_forcing_error_w_m2"] >
          0.3
    @test parsed["retained_structural_continuation3"]["accepted"]
    @test parsed["retained_structural_continuation3"]["accepted_move_count"] >= 1
    @test parsed["retained_structural_continuation3"]["best_exact_objective"] <
          parsed["retained_structural_continuation3"]["base_objective"]
    @test parsed["retained_structural_continuation3"]["best_worst_toa_forcing_error_w_m2"] >
          0.3
    @test parsed["retained_structural_continuation4"]["accepted"]
    @test parsed["retained_structural_continuation4"]["accepted_move_count"] >= 1
    @test parsed["retained_structural_continuation4"]["best_exact_objective"] <
          parsed["retained_structural_continuation4"]["base_objective"]
    @test parsed["retained_structural_continuation4"]["best_worst_toa_forcing_error_w_m2"] >
          0.3
    @test parsed["retained_structural_pareto_probe"]["status"] ==
          "pareto_probe_rejected"
    @test parsed["retained_structural_pareto_probe"]["config_count"] >= 1
    @test parsed["retained_structural_pareto_probe"]["best_exact_objective"] >=
          parsed["retained_structural_continuation4"]["best_exact_objective"]
    @test !parsed["retained_structural_pareto_probe"]["any_accepted"]
    @test !parsed["retained_structural_pareto_probe"]["any_pareto_safe"]
    @test parsed["retained_quadrature_pareto_scan"]["status"] ==
          "quadrature_pareto_scan_rejected"
    @test parsed["retained_quadrature_pareto_scan"]["candidate_count"] >= 1
    @test parsed["retained_quadrature_pareto_scan"]["best_objective"] >=
          parsed["retained_quadrature_pareto_scan"]["base_objective"]
    @test !parsed["retained_quadrature_pareto_scan"]["any_pareto_safe"]
    @test parsed["retained_quadrature_pair_pareto_scan"]["status"] ==
          "quadrature_pair_pareto_scan_rejected"
    @test parsed["retained_quadrature_pair_pareto_scan"]["candidate_count"] >= 1
    @test parsed["retained_quadrature_pair_pareto_scan"]["best_objective"] >=
          parsed["retained_quadrature_pair_pareto_scan"]["base_objective"]
    @test !parsed["retained_quadrature_pair_pareto_scan"]["any_pareto_safe"]
    @test parsed["retained_table_coordinate_pareto_scan"]["status"] ==
          "table_coordinate_pareto_scan_rejected"
    @test parsed["retained_table_coordinate_pareto_scan"]["trial_count"] >= 1
    @test parsed["retained_table_coordinate_pareto_scan"]["best_objective"] >=
          parsed["retained_table_coordinate_pareto_scan"]["base_objective"]
    @test !parsed["retained_table_coordinate_pareto_scan"]["any_pareto_safe"]
    @test parsed["retained_objective_probe_expansion"]["status"] ==
          "objective_probe_expansion_rejected"
    @test !parsed["retained_objective_probe_expansion"]["any_accepted"]
    @test parsed["retained_objective_probe_expansion"]["best_exact_objective"] <
          parsed["retained_table_coordinate_pareto_scan"]["base_objective"]
    @test parsed["retained_objective_probe_expansion"]["best_worst_surface_forcing_error_w_m2"] >
          parsed["retained_table_coordinate_pareto_scan"]["best_worst_surface_forcing_error_w_m2"]
    @test parsed["retained_objective_probe_expansion2"]["status"] ==
          "objective_probe_expansion2_rejected"
    @test !parsed["retained_objective_probe_expansion2"]["any_accepted"]
    @test parsed["retained_objective_probe_expansion3"]["status"] ==
          "objective_probe_expansion3_rejected"
    @test !parsed["retained_objective_probe_expansion3"]["any_accepted"]
    @test parsed["retained_objective_probe_expansion4"]["status"] ==
          "objective_probe_expansion4_rejected"
    @test !parsed["retained_objective_probe_expansion4"]["any_accepted"]
    @test parsed["retained_objective_probe_expansion4"]["best_worst_surface_forcing_error_w_m2"] <
          2.0
    @test parsed["retained_surface_probe_expansion"]["status"] ==
          "surface_probe_expansion_rejected"
    @test !parsed["retained_surface_probe_expansion"]["any_accepted"]
    @test parsed["retained_surface_probe_expansion"]["best_objective_reduction"] < 0
    @test parsed["retained_surface_probe_expansion2"]["status"] ==
          "surface_probe_expansion2_rejected"
    @test !parsed["retained_surface_probe_expansion2"]["any_accepted"]
    @test parsed["retained_surface_probe_expansion2"]["best_objective_reduction"] < 0
    @test parsed["retained_surface_probe_expansion3"]["status"] ==
          "surface_probe_expansion3_rejected"
    @test !parsed["retained_surface_probe_expansion3"]["any_accepted"]
    @test parsed["retained_surface_probe_expansion3"]["best_objective_reduction"] < 0
    @test parsed["retained_surface_probe_expansion3"]["best_worst_surface_forcing_error_w_m2"] <
          2.05
    @test parsed["retained_boundary_probe_expansion"]["status"] ==
          "boundary_probe_expansion_rejected"
    @test !parsed["retained_boundary_probe_expansion"]["any_accepted"]
    @test parsed["retained_boundary_probe_expansion"]["best_worst_surface_forcing_error_w_m2"] >
          parsed["best_reduced_surface_forcing_error_w_m2"]
    @test parsed["retained_toa_probe_expansion"]["status"] in
          ("toa_probe_expansion_improved", "toa_probe_expansion_rejected")
    @test !parsed["retained_toa_probe_expansion"]["any_pareto_safe"]
    @test !parsed["retained_toa_probe_expansion"]["any_accepted"]
    @test parsed["coefficient_continuation"]["status"] ==
          "coefficient_continuation_above_target"
    @test parsed["coefficient_continuation"]["final_objective"] > 1
    @test parsed["coefficient_continuation"]["best_start_objective"] <=
          parsed["coefficient_continuation"]["initial_objective"]
    @test parsed["boundary_table_triple_coordinate_scan"]["best_objective"] <=
          parsed["boundary_table_triple_coordinate_scan"]["base_objective"]
    @test occursin("coefficient/table optimizer", json) ||
          occursin("constrained table optimizer", json)
end
