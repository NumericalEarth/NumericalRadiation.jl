using Test
using JSON

include(joinpath(@__DIR__, "..", "validation", "official_ecckd_training.jl"))

@testset "official reduced ecCKD gas-optics training artifact" begin
    # The committed artifact is frozen evidence from the demoted greedy
    # optimizer chain (see validation/FROZEN_DIAGNOSTICS.md); main() only
    # verifies its presence and never recomputes it.
    main()
    @test isfile(OFFICIAL_TRAINING_JSON)
    @test isfile(OFFICIAL_TRAINING_MD)
    json = read(OFFICIAL_TRAINING_JSON, String)
    artifact = JSON.parsefile(OFFICIAL_TRAINING_JSON)
    @test artifact["case"] == "official_reduced_ecckd_gas_optics_training"
    @test artifact["status"] == "partial"
    @test artifact["training_source"] == "official ecCKD tabulated gas-optics reduced hard-gate objective"
    @test artifact["parameter_count"] == 48
    @test artifact["ng_sw"] == 16
    @test artifact["final_objective"] < artifact["initial_objective"]
    @test artifact["objective_reduction"] > 0
    @test artifact["objective_ratio"] < 1
    @test !artifact["hard_accuracy_target_met"]
    @test artifact["recovery_status"] == "optimizer_improved_but_target_not_met"
    @test artifact["final_objective_target_ratio"] > 1
    @test artifact["final_objective_target_ratio"] < 10
    @test artifact["optimizer"] == "deterministic multi-stage reduced ecCKD optimizer chain"
    @test "pressure_band_table_refinement" in artifact["optimization_chain"]
    @test artifact["reactant_check"]["status"] == "passed"
    @test artifact["enzyme_check"]["status"] == "passed"
    @test artifact["topology_candidate_scan"]["status"] == "all_32x16_topologies_fail_forcing_gate"
    @test occursin("Status is partial", artifact["notes"])
    @test occursin("\"case\": \"official_reduced_ecckd_gas_optics_training\"", json)
    @test occursin("\"status\": \"partial\"", json)
    @test occursin("\"hard_accuracy_target_met\": false", json)
    @test occursin("\"recovery_status\": \"optimizer_improved_but_target_not_met\"", json)
    @test occursin("\"training_source\": \"official ecCKD tabulated gas-optics reduced hard-gate objective\"", json)
    @test 8.60 < artifact["final_objective_target_ratio"] < 8.61
    @test occursin("\"topology_candidate_scan\"", json)
end
