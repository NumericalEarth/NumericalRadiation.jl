using JSON

@testset "RRTMGP-target 16-g AD calibration artifact" begin
    script = joinpath(@__DIR__, "..", "validation",
                      "rrtmgp_target_16g_ad_calibration.jl")
    output = read(`$(Base.julia_cmd()) --project=$(Base.active_project()) $script`, String)
    @test occursin("RRTMGP-Target 16-g AD Calibration", output)
    @test occursin("Status: `passed`", output)

    json_path = joinpath(@__DIR__, "..", "validation", "results",
                         "rrtmgp_target_16g_ad_calibration.json")
    @test isfile(json_path)
    result = JSON.parsefile(json_path)

    @test result["case"] == "rrtmgp_target_16g_ad_calibration"
    @test result["status"] == "passed"
    @test result["completion_blocker"] == false
    @test result["ad_training_status"]["reactant_used_for_training"]
    @test result["ad_training_status"]["enzyme_used_for_training"]
    @test result["ad_training_status"]["reactant_check"]["status"] == "passed"
    @test result["ad_training_status"]["enzyme_training"]["status"] == "passed"
    @test result["training"]["method"] == "Enzyme reverse-mode gradient descent"
    @test result["training"]["final_loss"] < result["training"]["initial_loss"]
    @test result["metrics"]["flux_rmse"] >= 0
    @test result["acceptance_rule"] ==
          "This artifact may pass only when Reactant and Enzyme are used to differentiate the RRTMGP-target loss and gradient descent trains the 16-g model parameters."
end
