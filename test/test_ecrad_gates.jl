# Consolidated from the original per-topic test files (Stage R2).
# Each original file's content is preserved verbatim inside its own module
# so top-level consts/functions from included validation scripts cannot clash.

module TestEcradReferenceManifest
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecrad_reference_manifest.jl ---
@testset "ecRad reference manifest artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_reference_manifest.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    @test occursin("ecRad Reference Manifest", result)
    @test occursin("clear_sky_tropical_column", result)
    @test occursin("rcemip_style_column_subset", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_reference_manifest.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_reference_manifest.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_reference_manifest\"", json)
    @test occursin("\"flux_rmse_w_m2\": 1.0", json)
    @test occursin("\"heating_rate_rmse_k_day\": 0.05", json)
    @test occursin("\"missing_reference_count\":", json)
    @test occursin("\"invalid_schema_count\":", json)
    @test occursin("\"schema_checker\": \"NCDatasets\"", json)
    @test occursin("\"schema_valid\":", json)
    @test occursin("\"missing_variables\":", json)
end
# --- end content of test_ecrad_reference_manifest.jl ---

end # module TestEcradReferenceManifest

module TestEcradMaterializeReferences
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecrad_materialize_references.jl ---
using NCDatasets

include(joinpath(@__DIR__, "..", "validation", "materialize_ecrad_references.jl"))

@testset "ecRad reference materializer conventions" begin
    p_interface = [100.0 200.0;
                   300.0 600.0;
                   900.0 1000.0]
    t_interface = [200.0 220.0;
                   260.0 280.0;
                   300.0 320.0]

    expected = [
        (200.0 * 100.0 + 260.0 * 300.0) / (100.0 + 300.0)  (220.0 * 200.0 + 280.0 * 600.0) / (200.0 + 600.0);
        (260.0 * 300.0 + 300.0 * 900.0) / (300.0 + 900.0)  (280.0 * 600.0 + 320.0 * 1000.0) / (600.0 + 1000.0)
    ]

    @test temperature_layer_from_interfaces(p_interface, t_interface) ≈ expected

    reference_path = joinpath(@__DIR__, "..", "validation", "reference", "ecrad",
                              "clear_sky_tropical_column.nc")
    if isfile(reference_path)
        NCDatasets.NCDataset(reference_path) do dataset
            @test haskey(dataset, "cos_solar_zenith_angle")
            @test haskey(dataset, "solar_irradiance")
            @test haskey(dataset, "o3")
            @test haskey(dataset, "ch4")
            @test haskey(dataset, "n2o")
            @test all(Array(dataset["cos_solar_zenith_angle"]) .>= 0)
            @test all(Array(dataset["solar_irradiance"]) .> 0)
        end
    end

    ecckd_reference_path = joinpath(@__DIR__, "..", "validation", "reference", "ecrad",
                                    "ecckd_clear_sky_tropical_column.nc")
    if isfile(ecckd_reference_path)
        NCDatasets.NCDataset(ecckd_reference_path) do dataset
            @test dataset.attrib["source_flux_scope"] == "total"
            @test haskey(dataset, "o3")
            @test haskey(dataset, "ch4")
            @test haskey(dataset, "n2o")
            @test haskey(dataset, "surface_longwave_up_spectral")
            @test haskey(dataset, "surface_albedo_spectral")
            @test haskey(dataset, "surface_albedo_direct_spectral")
        end
    end

    matched_64x64_reference_path =
        joinpath(@__DIR__, "..", "validation", "reference", "ecrad",
                 "ecckd_64x64_clear_sky_tropical_column.nc")
    if isfile(matched_64x64_reference_path)
        NCDatasets.NCDataset(matched_64x64_reference_path) do dataset
            @test haskey(dataset, "surface_longwave_up_spectral")
            @test haskey(dataset, "surface_albedo_spectral")
            @test size(dataset["surface_longwave_up_spectral"], 1) == 64
            @test size(dataset["surface_albedo_spectral"], 1) == 64
        end
    end

    matched_64x96_reference_path =
        joinpath(@__DIR__, "..", "validation", "reference", "ecrad",
                 "ecckd_64x96_clear_sky_tropical_column.nc")
    if isfile(matched_64x96_reference_path)
        NCDatasets.NCDataset(matched_64x96_reference_path) do dataset
            @test haskey(dataset, "surface_longwave_up_spectral")
            @test haskey(dataset, "surface_albedo_spectral")
            @test size(dataset["surface_longwave_up_spectral"], 1) == 64
            @test size(dataset["surface_albedo_spectral"], 1) == 96
        end
    end

    for (case_name, ng_lw, ng_sw) in (
        ("ecckd_32x64_clear_sky_tropical_column.nc", 32, 64),
        ("ecckd_32x96_clear_sky_tropical_column.nc", 32, 96),
        ("ecckd_64x32_clear_sky_tropical_column.nc", 64, 32),
    )
        matched_reference_path =
            joinpath(@__DIR__, "..", "validation", "reference", "ecrad", case_name)
        if isfile(matched_reference_path)
            NCDatasets.NCDataset(matched_reference_path) do dataset
                @test haskey(dataset, "surface_longwave_up_spectral")
                @test haskey(dataset, "surface_albedo_spectral")
                @test size(dataset["surface_longwave_up_spectral"], 1) == ng_lw
                @test size(dataset["surface_albedo_spectral"], 1) == ng_sw
            end
        end
    end

    all_sky_reference_path = joinpath(@__DIR__, "..", "validation", "reference", "ecrad",
                                      "all_sky_tropical_column.nc")
    if isfile(all_sky_reference_path)
        NCDatasets.NCDataset(all_sky_reference_path) do dataset
            @test haskey(dataset, "re_liquid")
            @test haskey(dataset, "re_ice")
            @test haskey(dataset, "inv_cloud_effective_size")
            @test haskey(dataset, "fractional_std")
            @test haskey(dataset, "overlap_param")
            @test haskey(dataset, "aerosol_mmr")
            @test haskey(dataset, "surface_albedo_direct_spectral")
            @test haskey(dataset, "surface_albedo_spectral")
            @test haskey(dataset, "surface_albedo_direct_gpoint")
            @test dimnames(dataset["overlap_param"]) == ("overlap_interface", "column")
            @test dimnames(dataset["aerosol_mmr"]) == ("layer", "aerosol_type", "column")
            @test dimnames(dataset["surface_albedo_direct_gpoint"]) ==
                  ("shortwave_gpoint", "column")
        end
    end

    ecckd_all_sky_reference_path = joinpath(@__DIR__, "..", "validation", "reference", "ecrad",
                                            "ecckd_all_sky_tropical_column.nc")
    if isfile(ecckd_all_sky_reference_path)
        NCDatasets.NCDataset(ecckd_all_sky_reference_path) do dataset
            @test dataset.attrib["source_flux_scope"] == "total"
            @test occursin("ecrad_meridian_ecckd_tc_out_REFERENCE.nc",
                           dataset.attrib["source_output"])
            @test haskey(dataset, "o3")
            @test haskey(dataset, "ch4")
            @test haskey(dataset, "n2o")
            @test haskey(dataset, "surface_longwave_up_spectral")
            @test haskey(dataset, "surface_albedo_direct_gpoint")
            @test haskey(dataset, "lw_up_clear")
            @test haskey(dataset, "sw_down_clear")
        end
    end

    for (case_name, ng_lw, ng_sw) in (
        ("ecckd_32x64_all_sky_tropical_column.nc", 32, 64),
        ("ecckd_32x96_all_sky_tropical_column.nc", 32, 96),
        ("ecckd_64x32_all_sky_tropical_column.nc", 64, 32),
        ("ecckd_64x64_all_sky_tropical_column.nc", 64, 64),
        ("ecckd_64x96_all_sky_tropical_column.nc", 64, 96),
    )
        matched_all_sky_path =
            joinpath(@__DIR__, "..", "validation", "reference", "ecrad", case_name)
        if isfile(matched_all_sky_path)
            NCDatasets.NCDataset(matched_all_sky_path) do dataset
                @test dataset.attrib["source_flux_scope"] == "total"
                @test haskey(dataset, "cloud_fraction")
                @test haskey(dataset, "aerosol_mmr")
                @test haskey(dataset, "lw_up_clear")
                @test haskey(dataset, "sw_down_clear")
                @test haskey(dataset, "surface_longwave_up_spectral")
                @test haskey(dataset, "surface_albedo_spectral")
                @test size(dataset["surface_longwave_up_spectral"], 1) == ng_lw
                @test size(dataset["surface_albedo_spectral"], 1) == ng_sw
                if case_name == "ecckd_32x64_all_sky_tropical_column.nc"
                    @test haskey(dataset, "surface_albedo_direct_gpoint")
                    @test haskey(dataset, "toa_shortwave_down_spectral")
                    @test size(dataset["surface_albedo_direct_gpoint"], 1) == ng_sw
                    @test occursin("radiative_properties_ecckd_32x64.nc",
                                   dataset.attrib["saved_shortwave_boundary_source"])
                    @test occursin("surface_albedo_direct_gpoint",
                                   dataset.attrib["saved_shortwave_boundaries"])
                end
            end
        end
    end
end
# --- end content of test_ecrad_materialize_references.jl ---

end # module TestEcradMaterializeReferences

module TestEcradCandidateSchema
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecrad_candidate_schema.jl ---
module EcRadCandidateSchemaTestHelpers
include(joinpath(@__DIR__, "..", "validation", "ecrad_candidate_schema.jl"))
end

module EcRadCandidateWriterTestHelpers
include(joinpath(@__DIR__, "..", "validation", "write_ecrad_candidates.jl"))
end

@testset "ecRad candidate schema artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_candidate_schema.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    @test occursin("ecRad Candidate Schema Check", result)
    @test occursin("radiative_heating_lw_up", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_candidate_schema.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_candidate_schema.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_candidate_schema\"", json)
    @test occursin("\"candidate_prefix\": \"radiative_heating_\"", json)
    @test occursin("\"status\": \"missing_references\"", json) ||
          occursin("\"status\": \"missing_or_mismatched_candidate_variables\"", json) ||
          occursin("\"status\": \"passed\"", json) ||
          occursin("\"status\": \"invalid_reference_schema\"", json)
end

@testset "ecRad candidate official gas amount conversions" begin
    pressure_interfaces = reshape([0.0, 9.80665], 2, 1)
    h2o = reshape([EcRadCandidateWriterTestHelpers.MOLAR_MASS_WATER], 1, 1)
    co2_pressure_interfaces = reshape(
        [0.0, 9.80665 * EcRadCandidateWriterTestHelpers.MOLAR_MASS_DRY_AIR],
        2,
        1,
    )
    co2 = reshape([1.0], 1, 1)

    h2o_moles = EcRadCandidateWriterTestHelpers.layer_moles_from_specific_humidity(
        h2o,
        pressure_interfaces,
    )
    air_moles = EcRadCandidateWriterTestHelpers.layer_air_moles(co2_pressure_interfaces)
    co2_moles = EcRadCandidateWriterTestHelpers.layer_moles_from_vmr(co2, air_moles)

    @test h2o_moles[1, 1] ≈ 1.0
    @test air_moles[1, 1] ≈ 1.0
    @test co2_moles[1, 1] ≈ 1.0
end

@testset "ecRad candidate schema shape checks" begin
    using NCDatasets

    mktempdir() do dir
        path = joinpath(dir, "candidate_schema.nc")
        NCDataset(path, "c") do dataset
            defDim(dataset, "interface", 3)
            defDim(dataset, "layer", 2)
            defDim(dataset, "wrong_interface", 4)

            reference = defVar(dataset, "lw_up", Float64, ("interface",))
            matching = defVar(dataset, "radiative_heating_lw_up", Float64, ("interface",))
            mismatched_reference = defVar(dataset, "lw_down", Float64, ("interface",))
            mismatched = defVar(dataset, "radiative_heating_lw_down", Float64, ("wrong_interface",))
            missing_candidate_reference = defVar(dataset, "heating_rate", Float64, ("layer",))

            reference[:] = [1.0, 2.0, 3.0]
            matching[:] = [1.0, 2.0, 3.0]
            mismatched_reference[:] = [1.0, 2.0, 3.0]
            mismatched[:] = [1.0, 2.0, 3.0, 4.0]
            missing_candidate_reference[:] = [0.1, 0.2]
        end

        matching = EcRadCandidateSchemaTestHelpers.candidate_schema_status(
            path,
            (name = "lw_up", candidate = "radiative_heating_lw_up"),
        )
        mismatched = EcRadCandidateSchemaTestHelpers.candidate_schema_status(
            path,
            (name = "lw_down", candidate = "radiative_heating_lw_down"),
        )
        missing = EcRadCandidateSchemaTestHelpers.candidate_schema_status(
            path,
            (name = "heating_rate", candidate = "radiative_heating_heating_rate"),
        )

        @test matching.status == "passed"
        @test matching.shape_matches
        @test matching.reference_shape == [3]
        @test mismatched.status == "shape_mismatch"
        @test !mismatched.shape_matches
        @test mismatched.reference_shape == [3]
        @test mismatched.candidate_shape == [4]
        @test missing.status == "missing_candidate_variable"
        @test !missing.shape_matches
    end
end
# --- end content of test_ecrad_candidate_schema.jl ---

end # module TestEcradCandidateSchema

module TestEcradAccuracyGate
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecrad_accuracy_gate.jl ---
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
# --- end content of test_ecrad_accuracy_gate.jl ---

end # module TestEcradAccuracyGate

module TestEcradCloudlessAccuracyGate
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecrad_cloudless_accuracy_gate.jl ---
module EcRadCloudlessAccuracyGateTestHelpers
include(joinpath(@__DIR__, "..", "validation", "ecrad_cloudless_accuracy_gate.jl"))
end

@testset "ecRad cloudless accuracy gate artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_cloudless_accuracy_gate.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    @test occursin("ecRad Cloudless Accuracy Gate", result)
    @test occursin("cloudless/no-aerosol", result)
    @test occursin("radiative_heating_lw_up", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_cloudless_accuracy_gate.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_cloudless_accuracy_gate.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_cloudless_accuracy_gate\"", json)
    @test occursin("\"reference_scope\": \"cloudless/no-aerosol first hard gate\"", json)
    @test occursin("\"ecckd_clear_sky_tropical_column\"", json)
    @test occursin("\"ecckd_rcemip_style_column_subset\"", json)
    @test occursin("\"status\": \"missing_references\"", json) ||
          occursin("\"status\": \"missing_candidate_outputs\"", json) ||
          occursin("\"status\": \"passed\"", json) ||
          occursin("\"status\": \"failed_threshold\"", json) ||
          occursin("\"status\": \"invalid_reference_schema\"", json)
end

@testset "ecRad cloudless gate case selection" begin
    selected = collect(getproperty.(EcRadCloudlessAccuracyGateTestHelpers.CLOUDLESS_CASES, :case))
    @test selected == [
        "ecckd_clear_sky_tropical_column",
        "ecckd_rcemip_style_column_subset",
    ]
    @test !("clear_sky_tropical_column" in selected)
    @test !("rcemip_style_column_subset" in selected)
    @test !("all_sky_tropical_column" in selected)
end
# --- end content of test_ecrad_cloudless_accuracy_gate.jl ---

end # module TestEcradCloudlessAccuracyGate

module TestEcradAccuracyDiagnostics
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecrad_accuracy_diagnostics.jl ---
@testset "ecRad accuracy diagnostics artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_accuracy_diagnostics.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    @test occursin("ecRad Accuracy Diagnostics", result)
    @test occursin("Worst Metrics", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_accuracy_diagnostics.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results", "ecrad_accuracy_diagnostics.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_accuracy_diagnostics\"", json)
    @test occursin("\"gate_status\":", json)
    @test occursin("\"failed_metric_count\":", json)
    @test occursin("\"worst_metrics\":", json)
end
# --- end content of test_ecrad_accuracy_diagnostics.jl ---

end # module TestEcradAccuracyDiagnostics

module TestEcradFluxBiasDiagnostics
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecrad_flux_bias_diagnostics.jl ---
@testset "ecRad flux bias diagnostics artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_flux_bias_diagnostics.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    @test occursin("ecRad Flux Bias Diagnostics", result)
    @test occursin("Boundary Net-Flux Bias", result)
    @test occursin("Variable Bias", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results",
                         "ecrad_flux_bias_diagnostics.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results",
                       "ecrad_flux_bias_diagnostics.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_flux_bias_diagnostics\"", json)
    @test occursin("\"boundary_biases\":", json)
    @test occursin("\"variable_biases\":", json)
end
# --- end content of test_ecrad_flux_bias_diagnostics.jl ---

end # module TestEcradFluxBiasDiagnostics

module TestEcradAllSkyCloudEffectDiagnostics
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecrad_all_sky_cloud_effect_diagnostics.jl ---
@testset "ecRad all-sky cloud-effect diagnostics artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_all_sky_cloud_effect_diagnostics.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)
    @test occursin("ecRad All-Sky Cloud-Effect Diagnostics", result)
    @test occursin("Boundary Cloud Effect Error", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results",
                         "ecrad_all_sky_cloud_effect_diagnostics.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results",
                       "ecrad_all_sky_cloud_effect_diagnostics.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_all_sky_cloud_effect_diagnostics\"", json)
    @test occursin("\"boundary_cloud_effects\":", json)
    @test occursin("\"profile_cloud_effects\":", json)
end
# --- end content of test_ecrad_all_sky_cloud_effect_diagnostics.jl ---

end # module TestEcradAllSkyCloudEffectDiagnostics

module TestEcradAllSkyCloudSweep
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecrad_all_sky_cloud_sweep.jl ---
@testset "ecRad all-sky cloud sweep artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_all_sky_cloud_sweep.jl")
    include(script)
    result = markdown_cloud_sweep_report((
        best_trial = "smoke",
        best_configuration = [(variable = "RH_AEROSOL_OPTICS", value = "false")],
        trials = [(
            name = "smoke",
            all_sky_worst_threshold_ratio = 1.0,
            toa_forcing_abs_error_w_m2 = 1.0,
            surface_forcing_abs_error_w_m2 = 1.0,
            toa_sw_cloud_effect_max_abs_w_m2 = 1.0,
            surface_sw_cloud_effect_max_abs_w_m2 = 1.0,
            profile_sw_cloud_effect_max_abs_w_m2 = 1.0,
            heating_cloud_effect_max_abs_k_day = 1.0,
        )],
    ))
    @test occursin("ecRad All-Sky Cloud Sweep", result)
    @test occursin("Best Configuration", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results",
                         "ecrad_all_sky_cloud_sweep.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results",
                       "ecrad_all_sky_cloud_sweep.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_all_sky_cloud_sweep\"", json)
    @test occursin("\"best_trial\":", json)
    @test occursin("\"trials\":", json)
end
# --- end content of test_ecrad_all_sky_cloud_sweep.jl ---

end # module TestEcradAllSkyCloudSweep

module TestEcradAllSkyOpticsGap
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecrad_all_sky_optics_gap.jl ---
@testset "ecRad all-sky optics gap artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "ecrad_all_sky_optics_gap.jl")
    include(script)
    result = markdown_all_sky_optics_gap((
        rows = [(
            candidate_kind = "smoke",
            variable = "od_sw_cloud",
            candidate_variable = "od_sw_cloud",
            units = "1",
            rmse = 1.0,
            max_abs = 1.0,
            mean_bias = 1.0,
            mean_abs = 1.0,
            reference_mean = 1.0,
            candidate_mean = 1.0,
        )],
        candidate_configuration = [(variable = "RH_AEROSOL_OPTICS", value = "false")],
    ))
    @test occursin("ecRad All-Sky Optics Gap", result)
    @test occursin("Reference case", result)
    @test occursin("ecRad properties", result)
    @test occursin("Candidate Configuration", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results",
                         "ecrad_all_sky_optics_gap.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results",
                       "ecrad_all_sky_optics_gap.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_all_sky_optics_gap\"", json)
    @test occursin("\"od_sw_cloud\"", json)
    @test occursin("\"od_lw_cloud\"", json)

    json_32x64_path = joinpath(@__DIR__, "..", "validation", "results",
                               "ecrad_all_sky_optics_gap_32x64.json")
    md_32x64_path = joinpath(@__DIR__, "..", "validation", "results",
                             "ecrad_all_sky_optics_gap_32x64.md")
    @test isfile(json_32x64_path)
    @test isfile(md_32x64_path)

    json_32x64 = read(json_32x64_path, String)
    @test occursin("ecckd_32x64_all_sky_tropical_column.nc", json_32x64)
    @test occursin("ecckd-1.2_sw_climate_window-64b_ckd-definition.nc", json_32x64)

    gate_json_path = joinpath(@__DIR__, "..", "validation", "results",
                              "ecrad_all_sky_optics_gap_32x64_gate.json")
    gate_md_path = joinpath(@__DIR__, "..", "validation", "results",
                            "ecrad_all_sky_optics_gap_32x64_gate.md")
    @test isfile(gate_json_path)
    @test isfile(gate_md_path)

    gate_json = read(gate_json_path, String)
    @test occursin("\"RH_AEROSOL_OPTICS\"", gate_json)
    @test occursin("\"RH_IFS_AEROSOL_TABLE_OPTICS\"", gate_json)
    @test occursin("\"value\": \"true\"", gate_json)
    @test occursin("clear_region_current", gate_json)
    @test occursin("cloudy_region_delta_scaled", gate_json)
    @test occursin("od_sw+od_sw_cloud", gate_json)
    @test occursin("combined_ssa_sw", gate_json)
    @test occursin("boundary_materialized", gate_json)
    @test occursin("incoming_sw", gate_json)
    @test occursin("sw_albedo_direct", gate_json)
end
# --- end content of test_ecrad_all_sky_optics_gap.jl ---

end # module TestEcradAllSkyOpticsGap

module TestEcradReferenceOpticsSolverGap
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecrad_reference_optics_solver_gap.jl ---
@testset "ecRad reference-optics solver gap artifact" begin
    script = joinpath(@__DIR__, "..", "validation",
                      "ecrad_reference_optics_solver_gap.jl")
    include(script)

    default_json = joinpath(@__DIR__, "..", "validation", "results",
                            "ecrad_reference_optics_solver_gap.json")
    default_md = joinpath(@__DIR__, "..", "validation", "results",
                          "ecrad_reference_optics_solver_gap.md")
    diagnostic_json = joinpath(@__DIR__, "..", "validation", "results",
                               "ecrad_reference_optics_solver_gap_32x64.json")
    diagnostic_md = joinpath(@__DIR__, "..", "validation", "results",
                             "ecrad_reference_optics_solver_gap_32x64.md")

    @test isfile(default_json)
    @test isfile(default_md)
    @test isfile(diagnostic_json)
    @test isfile(diagnostic_md)

    default = read(default_json, String)
    diagnostic = read(diagnostic_json, String)
    @test occursin("\"case\": \"ecrad_reference_optics_solver_gap\"", default)
    @test occursin("ecrad_meridian_ecckd_tc_out_REFERENCE.nc", default)
    @test occursin("ecckd_32x64_all_sky_tropical_column.nc", diagnostic)
    @test occursin("ecrad_meridian_ecckd_32x64_all_sky_props_out.nc",
                   diagnostic)
    @test occursin("tripleclouds_alpha_p2", diagnostic)

    report = markdown_report((
        reference = "reference.nc",
        properties = "properties.nc",
        ecrad_output = "output.nc",
        modes = [(
            mode = "smoke",
            sw_up_rmse = 1.0,
            sw_down_rmse = 1.0,
            toa_net_abs_error = 1.0,
            surface_net_abs_error = 1.0,
            toa_net_mean_bias = 1.0,
            surface_net_mean_bias = 1.0,
            output_toa_net_abs_error = nothing,
            output_surface_net_abs_error = nothing,
            reference_output_toa_net_abs_error = nothing,
            reference_output_surface_net_abs_error = nothing,
            clear_direct_max_abs = nothing,
        )],
    ))
    @test occursin("Reference case", report)
    @test occursin("ecRad output", report)
    @test occursin("Output TOA net max abs", report)
    @test occursin("reference_output_toa_net_abs_error", diagnostic)
    @test occursin("5.097602388559608e-5", diagnostic)
    @test occursin("4.57763671875e-5", diagnostic)
end
# --- end content of test_ecrad_reference_optics_solver_gap.jl ---

end # module TestEcradReferenceOpticsSolverGap

module TestEcradCloudScatteringTablesCheck
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecrad_cloud_scattering_tables_check.jl ---
@testset "ecRad cloud scattering tables validation artifact" begin
    root = normpath(joinpath(@__DIR__, ".."))
    script = joinpath(root, "validation", "ecrad_cloud_scattering_tables_check.jl")
    test_project = Base.active_project()
    output = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)

    @test occursin("ecRad Cloud Scattering Tables Check", output)
    @test occursin("Status: **passed**", output)
    @test occursin("liquid", output)
    @test occursin("ice", output)
    @test occursin("ecCKD G-Point Mapping", output)

    json_path = joinpath(root, "validation", "results", "ecrad_cloud_scattering_tables_check.json")
    md_path = joinpath(root, "validation", "results", "ecrad_cloud_scattering_tables_check.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"ecrad_cloud_scattering_tables_check\"", json)
    @test occursin("\"status\": \"passed\"", json)
    @test occursin("\"medium\": \"liquid-water\"", json)
    @test occursin("\"medium\": \"ice\"", json)
    @test occursin("\"shape_ok\": true", json)
    @test occursin("\"bounded\": true", json)
    @test occursin("\"finite\": true", json)
    @test occursin("\"mappings\": [", json)
    @test occursin("\"kind\": \"shortwave\"", json)
    @test occursin("\"kind\": \"longwave\"", json)
    @test occursin("\"expected_gpoints\": 32", json)
    @test occursin("\"expected_gpoints\": 64", json)
    @test occursin("\"positive_extinction\": true", json)
end
# --- end content of test_ecrad_cloud_scattering_tables_check.jl ---

end # module TestEcradCloudScatteringTablesCheck

module TestEcradAllSkyIfsGate
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecrad_all_sky_ifs_gate.jl ---
using Test

include(joinpath(@__DIR__, "..", "validation", "ecrad_all_sky_ifs_gate.jl"))

@testset "ecRad all-sky IFS gate artifact" begin
    result = all_sky_ifs_gate()
    @test result.case == "ecrad_all_sky_ifs_gate"
    @test result.status == "passed"
    @test result.accuracy_gate_ecckd_all_sky_passed
    @test result.cloud_scattering_tables_passed
    @test result.cloud_sweep.passed
    @test result.cloud_sweep.best_worst_threshold_ratio <= 1
    @test occursin("tripleclouds", result.cloud_sweep.best_trial)
    @test result.reference_optics_solver.passed
    @test result.reference_optics_solver.toa_net_abs_error <=
          result.reference_optics_solver.threshold
    @test result.reference_optics_solver.surface_net_abs_error <=
          result.reference_optics_solver.threshold

    main()
    @test isfile(ALL_SKY_IFS_GATE_JSON)
    @test isfile(ALL_SKY_IFS_GATE_MD)
    json = read(ALL_SKY_IFS_GATE_JSON, String)
    @test occursin("\"case\": \"ecrad_all_sky_ifs_gate\"", json)
    @test occursin("\"status\": \"passed\"", json)
    @test occursin("\"accuracy_gate_ecckd_all_sky_passed\": true", json)
    @test occursin("\"cloud_scattering_tables_passed\": true", json)
end
# --- end content of test_ecrad_all_sky_ifs_gate.jl ---

end # module TestEcradAllSkyIfsGate
