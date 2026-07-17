using Test
using JSON

include(joinpath(@__DIR__, "..", "validation",
                 "reduced_ecckd_pressure_band_refinement_preflight.jl"))

@testset "reduced ecCKD pressure-band refinement preflight" begin
    if get(ENV, "RH_REGENERATE_VALIDATION_ARTIFACTS", "false") == "true" ||
       !isfile(PRESSURE_BAND_JSON) || !isfile(PRESSURE_BAND_MD)
        result = pressure_band_refinement_preflight()
        @test result.case == "reduced_ecckd_pressure_band_refinement_preflight"
        @test result.status == "pressure_band_move_improved"
        @test result.current_objective > 1
        @test result.target_case == "ecckd_rcemip_style_column_subset"
        @test result.target_metric == "toa_forcing_max_abs"
        @test result.band_count == 4
        @test result.candidate_count == 16
        @test isfinite(result.scan.best_metric_candidate.metric_objective)
        @test result.scan.best_metric_candidate.metric_objective > 1
        @test result.scan.best_full_candidate.full_objective >
              result.current_objective
        @test !result.scan.accepted
        @test result.gpoint_scan.candidate_count > result.candidate_count
        @test result.gpoint_scan.best_metric_candidate.metric_objective <
              result.target_metric_objective
        @test result.gpoint_scan.best_full_candidate.full_objective <
              result.current_objective
        @test result.gpoint_scan.accepted
        @test result.component_gpoint_scan.candidate_count >= 1
        @test result.component_gpoint_scan.candidate_count <=
              result.component_gpoint_scan.max_candidates
        @test result.component_gpoint_scan.best_full_candidate.full_objective <=
              result.gpoint_scan.best_full_candidate.full_objective
        @test result.component_gpoint_scan.best_full_candidate.component in
              ("static_absorption", "dynamic_h2o")
        @test result.component_gpoint_scan.accepted
        @test result.iterative_component_gpoint_scan.iterations_completed >= 1
        @test result.iterative_component_gpoint_scan.accepted_move_count >= 1
        @test result.iterative_component_gpoint_scan.final_full_objective <=
              result.component_gpoint_scan.best_full_candidate.full_objective
        @test result.iterative_component_gpoint_scan.improved
        @test result.active_table_entry_scan.candidate_count >= 1
        @test result.active_table_entry_scan.active_component in
              ("static_absorption", "dynamic_h2o")
        @test isfinite(result.active_table_entry_scan.best_full_candidate.full_objective)
        @test result.active_table_entry_scan.best_full_candidate.full_objective <
              result.current_objective
        @test result.active_table_entry_scan.accepted
        @test result.iterative_active_table_entry_scan.iterations_completed >= 1
        @test result.iterative_active_table_entry_scan.accepted_move_count >= 1
        @test result.iterative_active_table_entry_scan.final_full_objective <=
              result.active_table_entry_scan.best_full_candidate.full_objective
        @test result.iterative_active_table_entry_scan.improved
        @test result.pairwise_gpoint_scan.candidate_count >= 1
        @test result.pairwise_gpoint_scan.selected_single_candidate_count >= 1
        @test isfinite(result.pairwise_gpoint_scan.best_full_candidate.full_objective)
        @test result.iterative_gpoint_scan.accepted_move_count >= 1
        @test result.iterative_gpoint_scan.final_full_objective <
              result.current_objective
        @test result.iterative_gpoint_scan.final_full_objective <=
              result.gpoint_scan.best_full_candidate.full_objective

        main()
    end

    @test isfile(PRESSURE_BAND_JSON)
    @test isfile(PRESSURE_BAND_MD)
    artifact = JSON.parsefile(PRESSURE_BAND_JSON)
    @test artifact["case"] == "reduced_ecckd_pressure_band_refinement_preflight"
    @test artifact["status"] == "pressure_band_move_improved"
    @test artifact["candidate_count"] == 16
    @test artifact["gpoint_scan"]["accepted"]
    @test artifact["component_gpoint_scan"]["accepted"]
    @test artifact["iterative_component_gpoint_scan"]["accepted_move_count"] >= 1
    @test artifact["active_table_entry_scan"]["accepted"]
    @test artifact["iterative_active_table_entry_scan"]["accepted_move_count"] >= 1
    @test artifact["iterative_gpoint_scan"]["accepted_move_count"] >= 1
    json = read(PRESSURE_BAND_JSON, String)
    @test occursin("\"case\": \"reduced_ecckd_pressure_band_refinement_preflight\"", json)
    @test occursin("\"status\": \"pressure_band_move_improved\"", json)
    @test occursin("\"candidate_count\": 16", json)
    @test occursin("\"gpoint_scan\"", json)
    @test occursin("\"component_gpoint_scan\"", json)
    @test occursin("\"iterative_component_gpoint_scan\"", json)
    @test occursin("\"active_table_entry_scan\"", json)
    @test occursin("\"iterative_active_table_entry_scan\"", json)
    @test occursin("\"pairwise_gpoint_scan\"", json)
    @test occursin("\"iterative_gpoint_scan\"", json)
    markdown = read(PRESSURE_BAND_MD, String)
    @test occursin("Reduced ecCKD Pressure-Band Refinement Preflight", markdown)
    @test occursin("Best full objective", markdown)
    @test occursin("Per-g pressure-band candidates", markdown)
    @test occursin("Component per-g candidates", markdown)
    @test occursin("Iterative component per-g final objective", markdown)
    @test occursin("Active table-entry candidates", markdown)
    @test occursin("Iterative active table-entry final objective", markdown)
    @test occursin("Pairwise per-g candidates", markdown)
    @test occursin("Iterative per-g final objective", markdown)
end
