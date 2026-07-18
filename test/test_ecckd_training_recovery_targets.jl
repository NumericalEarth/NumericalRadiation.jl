using Test
using JSON

include(joinpath(@__DIR__, "..", "validation", "ecckd_training_recovery_targets.jl"))

@testset "ecCKD training recovery quantitative targets" begin
    result = main()
    @test isfile(TRAINING_TARGETS_JSON)
    @test isfile(TRAINING_TARGETS_MD)
    artifact = JSON.parsefile(TRAINING_TARGETS_JSON)
    @test artifact["case"] == "ecckd_training_recovery_targets"
    @test artifact["status"] == "partial"
    @test artifact["targets"]["optimizer_only_delta_rule"] != ""
    @test occursin("recovered training pipeline",
                   artifact["targets"]["new_band_scheme_rule"])
    @test artifact["targets"]["published_model_recovery_metrics"]["final_objective_target_ratio_max"] == 1.05
    @test artifact["targets"]["published_model_recovery_metrics"]["weight_l1_relative_error_max"] == 0.02
    @test artifact["targets"]["new_band_scheme_metrics"]["hard_gate_objective_max"] == 1.0
    @test artifact["targets"]["new_band_scheme_metrics"]["required_band_counts"] == [48, 96]
    @test artifact["current_official_recovery"]["final_objective_target_ratio"] > 1
    @test !artifact["current_official_recovery"]["hard_accuracy_target_met"]
    md = read(TRAINING_TARGETS_MD, String)
    @test occursin("optimizer settings varied", md)
    @test occursin("recovered training pipeline", md)
    @test occursin("48-g and 96-g", md)
end
