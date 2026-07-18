using Test
using NumericalRadiation
using Dates

const VALIDATION_DIR = abspath(joinpath(@__DIR__, "..", "validation"))
const VALIDATION_RESULTS_DIR_ENV = "NUMERICAL_RADIATION_VALIDATION_RESULTS_DIR"
const RUN_SLOW_VALIDATION_TESTS =
    lowercase(get(ENV, "NUMERICAL_RADIATION_RUN_SLOW_VALIDATION_TESTS", "false")) in
    ("1", "true", "yes", "on")

function with_temporary_validation_results(f::Function)
    source_results_dir = joinpath(VALIDATION_DIR, "results")
    previous_results_dir = get(ENV, VALIDATION_RESULTS_DIR_ENV, nothing)

    return mktempdir() do temp_root
        temp_results_dir = joinpath(temp_root, "results")
        if isdir(source_results_dir)
            cp(source_results_dir, temp_results_dir; force = true)
        else
            mkpath(temp_results_dir)
        end

        ENV[VALIDATION_RESULTS_DIR_ENV] = temp_results_dir
        try
            return f()
        finally
            if previous_results_dir === nothing
                delete!(ENV, VALIDATION_RESULTS_DIR_ENV)
            else
                ENV[VALIDATION_RESULTS_DIR_ENV] = previous_results_dir
            end
        end
    end
end

function print_stderr_without_method_overwrite_warnings(stderr_path)
    text = read(stderr_path, String)
    isempty(text) && return nothing

    for line in split(text, '\n'; keepempty=false)
        if !occursin(r"^WARNING: Method definition .* overwritten", line)
            println(stderr, line)
        end
    end

    return nothing
end

function rewrite_includes(expr)
    if expr isa Expr
        if expr.head == :call && length(expr.args) == 2 && expr.args[1] == :include
            return :(Main.include_dependency_quietly(@__MODULE__, $(rewrite_includes(expr.args[2]))))
        end
        return Expr(expr.head, map(rewrite_includes, expr.args)...)
    end

    return expr
end

function include_dependency_quietly(target_module::Module, path::AbstractString)
    resolved = abspath(path)
    is_validation = startswith(resolved, VALIDATION_DIR * Base.Filesystem.path_separator)
    if !is_validation
        return Base.include(rewrite_includes, target_module, resolved)
    end

    return mktemp() do stderr_path, stderr_io
        close(stderr_io)

        try
            result = open(stderr_path, "w") do redirected_stderr
                redirect_stderr(redirected_stderr) do
                    Base.include(rewrite_includes, target_module, resolved)
                end
            end
            print_stderr_without_method_overwrite_warnings(stderr_path)
            return result
        catch
            print(stderr, read(stderr_path, String))
            rethrow()
        end
    end
end

function include_test(filename::AbstractString)
    path = joinpath(@__DIR__, filename)
    return Base.include(rewrite_includes, @__MODULE__, path)
end

function include_slow_validation_test(filename::AbstractString)
    if RUN_SLOW_VALIDATION_TESTS
        return include_test(filename)
    end

    @testset "$(filename) (slow validation)" begin
        @test_skip(
            "set NUMERICAL_RADIATION_RUN_SLOW_VALIDATION_TESTS=true to run long optimizer/recovery validation"
        )
    end

    return nothing
end

with_temporary_validation_results() do
@testset "NumericalRadiation" begin
    include_test("test_planck.jl")
    include_test("test_absorption.jl")
    include_test("test_williams_longwave.jl")
    include_test("test_shortwave.jl")
    include_test("test_zenith.jl")
    include_test("test_rtc.jl")
    include_test("test_runtime_interfaces.jl")
    include_test("test_cloudless_longwave_solver.jl")
    include_test("test_cloudless_shortwave_solver.jl")
    include_test("test_cloud_optics.jl")
    include_test("test_cloud_scattering_table.jl")
    include_test("test_ecckd_definition.jl")
    include_test("test_ecckd_artifacts.jl")
    include_test("test_ecckd_ncdatasets_ext.jl")
    include_test("test_ecckd_model_inventory.jl")
    include_test("test_ecckd_model_selection_interface.jl")
    include_test("test_ecckd_published_model_accuracy.jl")
    include_test("test_ecckd_published_all_sky_accuracy.jl")
    include_test("test_ecckd_matched_reference_plan.jl")
    include_test("test_ecckd_recovery_metrics.jl")
    include_test("test_ecckd_teacher_student_recovery.jl")
    include_test("test_ecckd_teacher_student_recovery_scan.jl")
    include_test("test_ecckd_band_accuracy_pareto.jl")
    include_test("test_ecckd_objective_reconstruction_check.jl")
    include_test("test_ecckd_published_training_manifest.jl")
    include_test("test_ecckd_original_objective_terms.jl")
    include_test("test_ecckd_original_objective_loss.jl")
    include_test("test_ckdmip_original_objective_dataset.jl")
    include_slow_validation_test("test_ckdmip_original_objective_ad_batch.jl")
    include_test("test_ecckd_published_recovery_target.jl")
    include_test("test_ecckd_published_recovery_vector.jl")
    include_slow_validation_test("test_ecckd_published_recovery_vector_training.jl")
    include_test("test_ckdmip_training_data_download_plan.jl")
    include_test("test_ckdmip_training_data_preflight.jl")
    include_test("test_ecckd_derived_flux_generation_plan.jl")
    include_test("test_concat_ckdmip_flux_chunks.jl")
    include_test("test_ckdmip_download_script.jl")
    include_test("test_ecckd_official_files_check.jl")
    include_test("test_ecckd_forward.jl")
    include_test("test_rrtmgp_ext.jl")
    include_test("test_metrics.jl")
    include_test("test_access_points_check.jl")
    include_test("test_ecrad_reference_manifest.jl")
    include_test("test_ecrad_materialize_references.jl")
    include_test("test_ecrad_candidate_schema.jl")
    include_test("test_ecrad_accuracy_gate.jl")
    include_test("test_ecrad_cloudless_accuracy_gate.jl")
    include_test("test_ecrad_accuracy_diagnostics.jl")
    include_test("test_ecrad_flux_bias_diagnostics.jl")
    include_test("test_ecrad_all_sky_cloud_effect_diagnostics.jl")
    include_test("test_ecrad_all_sky_cloud_sweep.jl")
    include_test("test_ecrad_all_sky_optics_gap.jl")
    include_test("test_ecrad_reference_optics_solver_gap.jl")
    include_test("test_ecrad_cloud_scattering_tables_check.jl")
    include_test("test_ecrad_all_sky_ifs_gate.jl")
    include_test("test_ecckd_32b_baseline_check.jl")
    include_test("test_reduced_ecckd_metadata.jl")
    include_test("test_reduced_ecckd_32g_rrtmgp_comparison.jl")
    include_test("test_reduced_ecckd_optical_depth_fit_preflight.jl")
    include_slow_validation_test("test_reduced_ecckd_optimization_preflight.jl")
    include_test("test_reduced_ecckd_pressure_band_refinement_preflight.jl")
    include_test("test_official_ecckd_training.jl")
    include_test("test_ecckd_training_recovery_targets.jl")
    include_test("test_goal_audit_check.jl")
    include_test("test_recovery_goal_audit.jl")
end

@testset "SpeedyWeather Extension" begin
    include_test("test_with_speedyweather.jl")
end
end
