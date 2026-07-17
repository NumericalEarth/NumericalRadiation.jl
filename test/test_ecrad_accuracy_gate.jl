module EcRadAccuracyGateTestHelpers
include(joinpath(@__DIR__, "..", "validation", "ecrad_accuracy_gate.jl"))
end

@testset "ecRad accuracy gate artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_accuracy_gate.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    @test occursin("ecRad Accuracy Gate", result)
    @test occursin("radiative_heating_lw_up", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_accuracy_gate.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_accuracy_gate.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_accuracy_gate\"", json)
    @test occursin("\"case_scope\": \"official_ecCKD_hard_gate\"", json)
    @test occursin("\"candidate_prefix\": \"radiative_heating_\"", json)
    @test occursin("\"diagnostic_cases\"", json)
    @test occursin("\"flux_rmse_w_m2\": 1.0", json)
    @test occursin("\"heating_rate_rmse_k_day\": 0.05", json)
    @test occursin("\"status\": \"missing_references\"", json) ||
          occursin("\"status\": \"missing_candidate_outputs\"", json) ||
          occursin("\"status\": \"passed\"", json) ||
          occursin("\"status\": \"failed_threshold\"", json) ||
          occursin("\"status\": \"invalid_reference_schema\"", json)
end

@testset "ecRad accuracy gate threshold comparisons" begin
    using NCDatasets

    function write_gate_fixture(path; flux_offset, heating_offset)
        NCDataset(path, "c") do dataset
            defDim(dataset, "interface", 3)
            defDim(dataset, "layer", 2)

            flux_values = (
                lw_up = [100.0, 90.0, 80.0],
                lw_down = [10.0, 20.0, 30.0],
                sw_up = [40.0, 35.0, 30.0],
                sw_down = [300.0, 250.0, 200.0],
            )

            for name in ("lw_up", "lw_down", "sw_up", "sw_down")
                reference = defVar(dataset, name, Float64, ("interface",))
                candidate = defVar(dataset, "radiative_heating_" * name, Float64, ("interface",))
                reference[:] = getproperty(flux_values, Symbol(name))
                candidate[:] = getproperty(flux_values, Symbol(name)) .+ flux_offset
            end

            heating_reference = defVar(dataset, "heating_rate", Float64, ("layer",))
            heating_candidate = defVar(dataset, "radiative_heating_heating_rate", Float64, ("layer",))
            heating_reference[:] = [0.1, -0.2]
            heating_candidate[:] = [0.1, -0.2] .+ heating_offset
        end
        return path
    end

    mktempdir() do dir
        passing_path = write_gate_fixture(joinpath(dir, "passing.nc");
                                          flux_offset = 0.25,
                                          heating_offset = 0.01)
        failing_path = write_gate_fixture(joinpath(dir, "failing.nc");
                                          flux_offset = 6.0,
                                          heating_offset = 0.6)

        passing = [EcRadAccuracyGateTestHelpers.comparison_status(passing_path, variable)
                   for variable in EcRadAccuracyGateTestHelpers.COMPARISON_VARIABLES]
        failing = [EcRadAccuracyGateTestHelpers.comparison_status(failing_path, variable)
                   for variable in EcRadAccuracyGateTestHelpers.COMPARISON_VARIABLES]
        passing_forcing = (
            EcRadAccuracyGateTestHelpers.forcing_status(passing_path, :toa, EcRadAccuracyGateTestHelpers.ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2),
            EcRadAccuracyGateTestHelpers.forcing_status(passing_path, :surface, EcRadAccuracyGateTestHelpers.ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2),
        )
        failing_forcing = (
            EcRadAccuracyGateTestHelpers.forcing_status(failing_path, :toa, EcRadAccuracyGateTestHelpers.ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2),
            EcRadAccuracyGateTestHelpers.forcing_status(failing_path, :surface, EcRadAccuracyGateTestHelpers.ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2),
        )

        @test all(comparison -> comparison.passed, passing)
        @test all(comparison -> comparison.status == "passed", passing)
        @test any(comparison -> !comparison.passed, failing)
        @test all(comparison -> comparison.status == "failed_threshold", failing)
        @test all(comparison -> comparison.passed, passing_forcing)
        @test all(comparison -> comparison.status == "passed", passing_forcing)
        @test all(comparison -> comparison.passed, failing_forcing)
        @test passing[1].rmse ≈ 0.25
        @test passing[end].rmse ≈ 0.01
    end
end

@testset "ecRad accuracy gate forcing thresholds" begin
    using NCDatasets

    mktempdir() do dir
        path = joinpath(dir, "forcing_failure.nc")
        NCDataset(path, "c") do dataset
            defDim(dataset, "interface", 3)
            defDim(dataset, "layer", 2)
            flux_values = (
                lw_up = [100.0, 90.0, 80.0],
                lw_down = [10.0, 20.0, 30.0],
                sw_up = [40.0, 35.0, 30.0],
                sw_down = [300.0, 250.0, 200.0],
            )

            for name in ("lw_up", "lw_down", "sw_up", "sw_down")
                reference = defVar(dataset, name, Float64, ("interface",))
                candidate = defVar(dataset, "radiative_heating_" * name, Float64, ("interface",))
                reference[:] = getproperty(flux_values, Symbol(name))
                candidate[:] = getproperty(flux_values, Symbol(name))
            end

            dataset["radiative_heating_lw_up"][1] += 0.4
            dataset["radiative_heating_sw_down"][end] += 0.5

            heating_reference = defVar(dataset, "heating_rate", Float64, ("layer",))
            heating_candidate = defVar(dataset, "radiative_heating_heating_rate", Float64, ("layer",))
            heating_reference[:] = [0.1, -0.2]
            heating_candidate[:] = [0.1, -0.2]
        end

        toa = EcRadAccuracyGateTestHelpers.forcing_status(path, :toa, EcRadAccuracyGateTestHelpers.ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2)
        surface = EcRadAccuracyGateTestHelpers.forcing_status(path, :surface, EcRadAccuracyGateTestHelpers.ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2)

        @test !toa.passed
        @test toa.status == "failed_threshold"
        @test toa.max_abs ≈ 0.4
        @test !surface.passed
        @test surface.status == "failed_threshold"
        @test surface.max_abs ≈ 0.5
    end
end
