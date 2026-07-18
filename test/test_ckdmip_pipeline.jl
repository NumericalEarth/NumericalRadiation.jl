# Consolidated from the original per-topic test files (Stage R2).
# Each original file's content is preserved verbatim inside its own module
# so top-level consts/functions from included validation scripts cannot clash.

module TestCkdmipTrainingDataDownloadPlan
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ckdmip_training_data_download_plan.jl ---
using JSON

module CKDMIPTrainingDataDownloadPlanValidation
include(joinpath(@__DIR__, "..", "validation", "ckdmip_training_data_download_plan.jl"))
end

@testset "CKDMIP training data download plan" begin
    root = normpath(joinpath(@__DIR__, ".."))
    json_path = joinpath(root, "validation", "results", "ckdmip_training_data_download_plan.json")
    md_path = joinpath(root, "validation", "results", "ckdmip_training_data_download_plan.md")

    redirect_stdout(devnull) do
        CKDMIPTrainingDataDownloadPlanValidation.ckdmip_training_data_download_plan_main()
    end

    @test isfile(json_path)
    @test isfile(md_path)
    @test occursin("CKDMIP Training Data Download Plan", read(md_path, String))

    result = JSON.parsefile(json_path)
    @test result["case"] == "ckdmip_training_data_download_plan"
    @test result["status"] == "manual_or_batch_download_required"
    @test result["target_env"] == "RH_CKDMIP_DATA_PATH"
    @test result["task_count"] == length(result["tasks"])
    @test result["task_count"] > 20
    @test "evaluation1/lw_spectra" in result["expected_layout_roots"]
    @test "evaluation2/sw_fluxes" in result["expected_layout_roots"]

    commands = [task["command"] for task in result["tasks"]]
    @test any(command -> occursin("ckdmip_evaluation1_concentrations_present.nc", command), commands)
    @test any(command -> occursin("lw_spectra/evaluation1", command), commands)
    @test any(command -> occursin("sw_spectra/evaluation2", command), commands)
    @test any(command -> occursin("ln -sf", command) &&
                         occursin("mmm/sw_spectra_extras/ckdmip_ssi.h5", command), commands)
    @test all(command -> occursin("\$RH_CKDMIP_DATA_PATH", command), commands)
end
# --- end content of test_ckdmip_training_data_download_plan.jl ---

end # module TestCkdmipTrainingDataDownloadPlan

module TestCkdmipTrainingDataPreflight
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ckdmip_training_data_preflight.jl ---
using JSON

module CKDMIPTrainingDataPreflightValidation
include(joinpath(@__DIR__, "..", "validation", "ckdmip_training_data_preflight.jl"))
end

@testset "CKDMIP training data preflight" begin
    root = normpath(joinpath(@__DIR__, ".."))
    json_path = joinpath(root, "validation", "results", "ckdmip_training_data_preflight.json")
    md_path = joinpath(root, "validation", "results", "ckdmip_training_data_preflight.md")

    result = withenv("RH_CKDMIP_DATA_PATH" => "") do
        CKDMIPTrainingDataPreflightValidation.run_ckdmip_training_data_preflight()
    end
    @test result.case == "ckdmip_training_data_preflight"
    @test result.status == "missing_ckdmip_data_root"
    @test result.ckdmip_data_root === nothing
    @test result.expected_training_flux_file_count == 52
    @test result.upstream_training_flux_file_count == 34
    @test result.derived_training_flux_file_count == 18
    @test "ckdmip_evaluation1_lw_fluxes_present.h5" in result.expected_training_flux_files
    @test "ckdmip_evaluation1_lw_fluxes_present.h5" in result.upstream_training_flux_files
    @test "ckdmip_evaluation1_sw_fluxes_rel-415.h5" in result.expected_training_flux_files
    @test "ckdmip_evaluation1_sw_fluxes_rel-415.h5" in result.derived_training_flux_files
    @test !("ckdmip_evaluation2_lw_fluxes_rel-415.h5" in result.expected_training_flux_files)
    @test !("ckdmip_evaluation2_sw_fluxes_rel-415.h5" in result.expected_training_flux_files)
    @test any(blocker -> occursin("RH_CKDMIP_DATA_PATH", blocker), result.blockers)

    markdown = CKDMIPTrainingDataPreflightValidation.markdown_preflight(result)
    @test occursin("CKDMIP Training Data Preflight", markdown)

    mktempdir() do ckdmip_root
        for entry in CKDMIPTrainingDataPreflightValidation.expected_layout_roots()
            mkpath(joinpath(ckdmip_root, entry))
        end
        for entry in (
            "mmm/lw_spectra",
            "mmm/sw_spectra",
            "idealized/lw_spectra",
            "idealized/sw_spectra",
            "evaluation1/lw_spectra",
            "evaluation1/sw_spectra",
            "evaluation2/lw_spectra",
            "evaluation2/sw_spectra",
        )
            write(joinpath(ckdmip_root, entry, "marker.dat"), "fixture\n")
        end

        manifest = CKDMIPTrainingDataPreflightValidation.run_ecckd_published_training_manifest()
        upstream = [
            file for file in CKDMIPTrainingDataPreflightValidation.expected_training_flux_files(manifest)
            if !CKDMIPTrainingDataPreflightValidation.derived_training_flux_file(file)
        ]
        upstream_paths = vcat(
            CKDMIPTrainingDataPreflightValidation.key_files(),
            CKDMIPTrainingDataPreflightValidation.expected_flux_path.(upstream),
        )
        for path in upstream_paths
            full_path = joinpath(ckdmip_root, path)
            mkpath(dirname(full_path))
            write(full_path, "fixture\n")
        end

        derived_result = withenv("RH_CKDMIP_DATA_PATH" => ckdmip_root) do
            CKDMIPTrainingDataPreflightValidation.run_ckdmip_training_data_preflight()
        end
        @test derived_result.status == "ready_for_derived_flux_generation"
        @test isempty(derived_result.blockers)
        @test length(derived_result.derived_flux_generation_blockers) == 18
        @test all(blocker -> occursin("derived ecCKD training flux product", blocker),
                  derived_result.derived_flux_generation_blockers)

        derived = [
            file for file in CKDMIPTrainingDataPreflightValidation.expected_training_flux_files(manifest)
            if CKDMIPTrainingDataPreflightValidation.derived_training_flux_file(file)
        ]
        for path in CKDMIPTrainingDataPreflightValidation.expected_flux_path.(derived)
            full_path = joinpath(ckdmip_root, path)
            mkpath(dirname(full_path))
            write(full_path, "fixture\n")
        end

        ready_result = withenv("RH_CKDMIP_DATA_PATH" => ckdmip_root) do
            CKDMIPTrainingDataPreflightValidation.run_ckdmip_training_data_preflight()
        end
        @test ready_result.status == "ready_for_original_ecckd_objective"
        @test isempty(ready_result.blockers)
        @test isempty(ready_result.derived_flux_generation_blockers)
    end
end
# --- end content of test_ckdmip_training_data_preflight.jl ---

end # module TestCkdmipTrainingDataPreflight

module TestEcckdDerivedFluxGenerationPlan
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_derived_flux_generation_plan.jl ---
using JSON

module ECCKDDerivedFluxGenerationPlanValidation
include(joinpath(@__DIR__, "..", "validation", "ecckd_derived_flux_generation_plan.jl"))
end

@testset "ecCKD derived flux generation plan" begin
    root = normpath(joinpath(@__DIR__, ".."))
    json_path = joinpath(root, "validation", "results", "ecckd_derived_flux_generation_plan.json")
    md_path = joinpath(root, "validation", "results", "ecckd_derived_flux_generation_plan.md")

    redirect_stdout(devnull) do
        ECCKDDerivedFluxGenerationPlanValidation.ecckd_derived_flux_generation_plan_main()
    end

    @test isfile(json_path)
    @test isfile(md_path)

    result = JSON.parsefile(json_path)
    @test result["case"] == "ecckd_derived_flux_generation_plan"
    @test result["expected_derived_flux_count"] == 18
    @test 0 <= result["present_derived_flux_count"] <= 18
    @test 0 <= result["missing_derived_flux_count"] <= 18
    @test result["present_derived_flux_count"] + result["missing_derived_flux_count"] == 18
    @test result["expected_raw_chunk_count"] >= result["present_raw_chunk_count"]
    @test result["expected_raw_chunk_count"] >= 0
    @test haskey(result, "completed_equivalent_raw_chunk_count")
    @test result["expected_raw_chunk_count"] >= result["completed_equivalent_raw_chunk_count"]
    @test result["completed_equivalent_raw_chunk_count"] >= result["present_raw_chunk_count"]
    @test haskey(result, "raw_chunk_rate")
    @test haskey(result["raw_chunk_rate"], "observed_raw_chunk_rate_per_hour")
    @test haskey(result["raw_chunk_rate"], "estimated_hours_remaining")
    @test haskey(result, "ncrcat")
    @test haskey(result["ncrcat"], "present")
    @test haskey(result["ncrcat"], "path")
    @test haskey(result["ncrcat"], "julia_concat_shim")
    @test haskey(result["ncrcat"], "uses_julia_concat")
    @test haskey(result, "derived_flux_progress")
    @test length(result["derived_flux_progress"]) == 18
    @test result["upstream_preflight_status"] in (
        "missing_ckdmip_data_root",
        "incomplete_ckdmip_upstream_data",
        "ready_for_derived_flux_generation",
        "ready_for_original_ecckd_objective",
    )
    @test "5gas-415" in result["lw_scenarios"]
    @test "rel-415" in result["lw_scenarios"]
    @test "rel-415" in result["sw_scenarios"]
    @test !("5gas-415" in result["sw_scenarios"])
    @test any(row -> row["path"] == "test/run_lw_lbl_evaluation.sh" && row["present"],
              result["required_ecckd_scripts"])
    @test any(row -> row["path"] == "test/run_sw_lbl_evaluation.sh" && row["present"],
              result["required_ecckd_scripts"])
    @test all(row -> haskey(row, "raw_chunk_count") &&
                     haskey(row, "expected_raw_chunk_count") &&
                     haskey(row, "missing_raw_chunk_count") &&
                     haskey(row, "raw_chunk_bytes") &&
                     haskey(row, "first_raw_chunk_unix_time") &&
                     haskey(row, "latest_raw_chunk_unix_time") &&
                     haskey(row, "progress_state"),
              result["derived_flux_progress"])

    md = read(md_path, String)
    @test occursin("ecCKD Derived Flux Generation Plan", md)
    @test occursin("Raw Chunk Progress", md)
    @test occursin("Concatenation Tool", md)
    @test occursin("Completed-equivalent raw chunks", md)
    @test occursin("Observed raw chunk rate", md)
    @test occursin("not public CKDMIP archive files", md)
    @test occursin("run_lw_lbl_evaluation.sh", md)
    @test occursin("run_sw_lbl_evaluation.sh", md)
    @test occursin("generate_ecckd_derived_fluxes.sh", md)
end
# --- end content of test_ecckd_derived_flux_generation_plan.jl ---

end # module TestEcckdDerivedFluxGenerationPlan

module TestConcatCkdmipFluxChunks
using Test
using NumericalRadiation
using Dates

# --- begin content of test_concat_ckdmip_flux_chunks.jl ---
using NCDatasets

module CKDMIPFluxChunkConcatenationValidation
include(joinpath(@__DIR__, "..", "validation", "concat_ckdmip_flux_chunks.jl"))
end

@testset "ecCKD derived flux launcher dry run" begin
    root = normpath(joinpath(@__DIR__, ".."))
    script = joinpath(root, "validation", "generate_ecckd_derived_fluxes.sh")
    install_script = joinpath(root, "validation", "install_ecckd_derived_fluxes.sh")

    @test success(`bash -n $script`)
    @test success(`bash -n $install_script`)

    mktempdir() do workdir
        output = read(setenv(`bash $script`,
                             "RH_CKDMIP_DATA_PATH" => "/tmp/ckdmip-dryrun",
                             "RH_ECCKD_LBL_WORKDIR" => workdir,
                             "RH_ECCKD_DERIVED_FLUX_DRY_RUN" => "true"), String)
        @test occursin("Dry run only", output)
        @test occursin("run_lw_lbl_evaluation.sh", output)
        @test occursin("run_sw_lbl_evaluation.sh", output)
        @test occursin("install generated ckdmip_evaluation1_*_fluxes_{5gas,rel}-*.h5 files", output)

        lw_script = joinpath(workdir, "ecckd", "test", "run_lw_lbl_evaluation.sh")
        sw_script = joinpath(workdir, "ecckd", "test", "run_sw_lbl_evaluation.sh")
        config = joinpath(workdir, "ecckd", "test", "config.h")
        @test isfile(lw_script)
        @test isfile(sw_script)
        @test isfile(config)
        @test occursin("SCENARIOS=\"5gas-180 5gas-280 5gas-415 5gas-560 5gas-1120 5gas-2240 rel-180 rel-280 rel-415 rel-560 rel-1120 rel-2240\"",
                       read(lw_script, String))
        @test occursin("SCENARIOS=\"rel-180 rel-280 rel-415 rel-560 rel-1120 rel-2240\"",
                       read(sw_script, String))
        @test occursin("concat_ckdmip_flux_chunks.jl", read(lw_script, String))
        @test occursin("concat_ckdmip_flux_chunks.jl", read(sw_script, String))
        @test occursin("*** REUSING \$OUTFILE ***", read(lw_script, String))
        @test occursin("*** REUSING \$OUTFILE ***", read(sw_script, String))
        @test occursin("CKDMIP_DATA_DIR=/tmp/ckdmip-dryrun", read(config, String))
        @test occursin("WORK_DIR=$(workdir)/work", read(config, String))

        launcher = read(script, String)
        @test occursin("install_ecckd_derived_fluxes.sh", launcher)

        installer = read(install_script, String)
        @test occursin("evaluation1/lw_fluxes", installer)
        @test occursin("evaluation1/sw_fluxes", installer)
        @test occursin("ckdmip_evaluation1_lw_fluxes_5gas-*.h5", installer)
        @test occursin("ckdmip_evaluation1_lw_fluxes_rel-*.h5", installer)
        @test occursin("ckdmip_evaluation1_sw_fluxes_rel-*.h5", installer)
    end

    err = Pipe()
    proc = run(pipeline(setenv(`bash $script`,
                               "RH_ECCKD_DERIVED_FLUX_DRY_RUN" => "true");
                        stderr = err);
               wait = false)
    wait(proc)
    close(err.in)
    @test proc.exitcode == 2
    @test occursin("Set RH_CKDMIP_DATA_PATH", read(err, String))

    mktempdir() do workdir
        ckdmip_root = joinpath(workdir, "ckdmip")
        lbl_root = joinpath(workdir, "lbl")
        lw_source = joinpath(lbl_root, "work", "lw_lbl_fluxes")
        sw_source = joinpath(lbl_root, "work", "sw_lbl_fluxes")
        mkpath(lw_source)
        mkpath(sw_source)
        write(joinpath(lw_source, "ckdmip_evaluation1_lw_fluxes_5gas-180.h5"), "lw 5gas\n")
        write(joinpath(lw_source, "ckdmip_evaluation1_lw_fluxes_rel-180.h5"), "lw rel\n")
        write(joinpath(sw_source, "ckdmip_evaluation1_sw_fluxes_rel-180.h5"), "sw rel\n")

        output = read(setenv(`bash $install_script`,
                             "RH_CKDMIP_DATA_PATH" => ckdmip_root,
                             "RH_ECCKD_LBL_WORKDIR" => lbl_root), String)
        @test occursin("Installed 3 derived ecCKD flux product", output)
        @test read(joinpath(ckdmip_root, "evaluation1", "lw_fluxes",
                            "ckdmip_evaluation1_lw_fluxes_5gas-180.h5"), String) == "lw 5gas\n"
        @test read(joinpath(ckdmip_root, "evaluation1", "lw_fluxes",
                            "ckdmip_evaluation1_lw_fluxes_rel-180.h5"), String) == "lw rel\n"
        @test read(joinpath(ckdmip_root, "evaluation1", "sw_fluxes",
                            "ckdmip_evaluation1_sw_fluxes_rel-180.h5"), String) == "sw rel\n"
    end
end

@testset "CKDMIP flux chunk concatenation" begin
    mktempdir() do dir
        inputs = String[]
        for i in 1:3
            path = joinpath(dir, "chunk$(i).h5")
            ds = NCDataset(path, "c")
            defDim(ds, "column", Inf)
            defDim(ds, "half_level", 2)
            defDim(ds, "gas", 1)
            ds.attrib["scenario"] = "fixture"
            v = defVar(ds, "flux_up_lw", Float32, ("half_level", "column"))
            v.attrib["units"] = "W m-2"
            v[:, 1:2] = fill(Float32(i), 2, 2)
            g = defVar(ds, "reference_surface_mole_fraction", Float32, ("gas",);
                       attrib = Dict("units" => "1"))
            g[:] = Float32[415e-6]
            close(ds)
            push!(inputs, path)
        end

        output = joinpath(dir, "joined.h5")
        CKDMIPFluxChunkConcatenationValidation.concat_ckdmip_flux_chunks(inputs, output)

        ds = NCDataset(output)
        try
            @test ds.dim["column"] == 6
            @test ds.dim["half_level"] == 2
            @test ds.attrib["scenario"] == "fixture"
            @test occursin("concat_ckdmip_flux_chunks", ds.attrib["history"])
            @test ds["flux_up_lw"].attrib["units"] == "W m-2"
            @test ds["flux_up_lw"][:, :] == Float32[
                1 1 2 2 3 3
                1 1 2 2 3 3
            ]
            @test ds["reference_surface_mole_fraction"][:] == Float32[415e-6]
        finally
            close(ds)
        end
    end
end
# --- end content of test_concat_ckdmip_flux_chunks.jl ---

end # module TestConcatCkdmipFluxChunks

module TestCkdmipDownloadScript
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ckdmip_download_script.jl ---
@testset "CKDMIP download helper dry run" begin
    root = normpath(joinpath(@__DIR__, ".."))
    script = joinpath(root, "validation", "download_ckdmip_training_data.sh")

    @test success(`bash -n $script`)

    output = read(setenv(`bash $script`,
                         "RH_CKDMIP_DATA_PATH" => "/tmp/ckdmip-dryrun",
                         "CKDMIP_DRY_RUN" => "true"), String)
    @test occursin("DRY-RUN:", output)
    @test occursin("ckdmip_mmm_concentrations.nc", output)
    @test occursin("lw_spectra/evaluation1", output)
    @test occursin("sw_fluxes/evaluation2", output)
    @test occursin("ckdmip_training_data_preflight.jl", output)

    preflight_output = read(setenv(`bash $script`,
                                   "RH_CKDMIP_DATA_PATH" => "/tmp/ckdmip-dryrun",
                                   "CKDMIP_DRY_RUN" => "true",
                                   "CKDMIP_RUN_PREFLIGHT" => "true"), String)
    @test occursin("DRY-RUN:", preflight_output)
    @test occursin("--project=$(joinpath(root, "test"))", preflight_output)
    @test occursin(joinpath(root, "validation", "ckdmip_training_data_preflight.jl"),
                   preflight_output)

    err = Pipe()
    proc = run(pipeline(setenv(`bash $script`, "CKDMIP_DRY_RUN" => "true"); stderr = err);
               wait = false)
    wait(proc)
    close(err.in)
    @test proc.exitcode == 2
    @test occursin("Set RH_CKDMIP_DATA_PATH", read(err, String))
end
# --- end content of test_ckdmip_download_script.jl ---

end # module TestCkdmipDownloadScript

module TestEcckdPublishedTrainingManifest
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_published_training_manifest.jl ---
using JSON

module EcckdPublishedTrainingManifestValidation
include(joinpath(@__DIR__, "..", "validation", "ecckd_published_training_manifest.jl"))
end

@testset "ecCKD published training manifest" begin
    root = normpath(joinpath(@__DIR__, ".."))
    json_path = joinpath(root, "validation", "results", "ecckd_published_training_manifest.json")
    md_path = joinpath(root, "validation", "results", "ecckd_published_training_manifest.md")
    redirect_stdout(devnull) do
        EcckdPublishedTrainingManifestValidation.ecckd_published_training_manifest_main()
    end

    @test isfile(json_path)
    @test isfile(md_path)
    @test occursin("ecCKD Published Training Manifest", read(md_path, String))

    result = JSON.parsefile(json_path)
    @test result["case"] == "ecckd_published_training_manifest"
    @test result["status"] == "passed"
    @test result["config"]["training_code"] == "evaluation1"
    @test result["config"]["evaluation_code"] == "evaluation2"
    @test result["config"]["training_both"] == "no"
    @test result["ckdmip_preflight"]["status"] == "ready_for_original_ecckd_objective"
    @test result["ckdmip_preflight"]["derived_flux_final_product_count"] == 18
    @test result["ckdmip_preflight"]["ready"]
    @test all(file -> file["exists"], result["source_files"])

    master_scripts = Dict(script["path"] => script for script in result["master_scripts"])
    @test master_scripts["test/do_all_lw.sh"]["band_structure"] == "fsck"
    @test master_scripts["test/do_all_sw.sh"]["band_structure"] == "rgb"
    @test occursin("relative-base", master_scripts["test/do_all_lw.sh"]["optimize_mode_list"])
    @test occursin("relative-base", master_scripts["test/do_all_sw.sh"]["optimize_mode_list"])

    targets = Dict(target["kind"] => target for target in result["official_recovery_targets"])
    @test targets["longwave"]["nominal_gpoints"] == Any[16, 32]
    @test targets["shortwave"]["nominal_gpoints"] == Any[16, 32]
    @test targets["shortwave"]["optimizer_pass_order"] == Any["relative-base", "relative-ch4", "relative-n2o"]

    scripts = Dict(script["path"] => script for script in result["optimization_scripts"])
    @test haskey(scripts, "test/optimize_lut_lw.sh")
    @test haskey(scripts, "test/optimize_lut_sw.sh")
    @test occursin("prior_error=8.0", scripts["test/optimize_lut_lw.sh"]["selected_common_options"])
    @test occursin("bounded_optimization=0", scripts["test/optimize_lut_sw.sh"]["selected_common_options"])

    lw_modes = Set(vcat((mode["names"] for mode in scripts["test/optimize_lut_lw.sh"]["modes"])...))
    sw_modes = Set(vcat((mode["names"] for mode in scripts["test/optimize_lut_sw.sh"]["modes"])...))
    @test "climate" in lw_modes
    @test "all-in-one" in lw_modes
    @test "relative-base" in sw_modes
end
# --- end content of test_ecckd_published_training_manifest.jl ---

end # module TestEcckdPublishedTrainingManifest

module TestEcckdObjectiveReconstructionCheck
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_objective_reconstruction_check.jl ---
using JSON

module EcckdObjectiveReconstructionValidation
include(joinpath(@__DIR__, "..", "validation", "ecckd_objective_reconstruction_check.jl"))
end

@testset "ecCKD original-objective reconstruction check" begin
    root = normpath(joinpath(@__DIR__, ".."))
    json_path = joinpath(root, "validation", "results", "ecckd_objective_reconstruction_check.json")
    md_path = joinpath(root, "validation", "results", "ecckd_objective_reconstruction_check.md")
    redirect_stdout(devnull) do
        EcckdObjectiveReconstructionValidation.ecckd_objective_reconstruction_check_main()
    end

    @test isfile(json_path)
    @test isfile(md_path)
    @test occursin("ecCKD Objective Reconstruction Check", read(md_path, String))

    result = JSON.parsefile(json_path)
    @test result["case"] == "ecckd_objective_reconstruction_check"
    @test result["status"] in (
        "blocked_missing_original_training_assets",
        "ready_to_reconstruct_original_objective",
        "passed",
    )
    @test endswith(result["ckdmip_training_data_preflight"],
                   joinpath("validation", "results", "ckdmip_training_data_preflight.json"))
    @test all(item -> item in (
              "original LBL training database",
              "derived ecCKD training flux products",
          ), result["missing_for_exact_original_recovery"])
    @test result["ecckd_source_root"] !== nothing

    checks = Dict(check["name"] => check for check in result["checks"])
    @test checks["published ecCKD CKD-definition files"]["present"] == true
    @test checks["CKDMIP evaluation profiles and reference fluxes"]["present"] == true
    @test haskey(checks, "original LBL training database")
    @test haskey(checks, "derived ecCKD training flux products")
    @test checks["official ecCKD generator and optimizer source"]["present"] == true
    @test checks["official ecCKD objective weights and training scripts"]["present"] == true

    if !isempty(result["blockers"])
        blocker_text = join(result["blockers"], "\n")
        @test occursin("RH_CKDMIP_DATA_PATH", blocker_text) ||
              occursin("derived ecCKD", blocker_text)
    end
end
# --- end content of test_ecckd_objective_reconstruction_check.jl ---

end # module TestEcckdObjectiveReconstructionCheck

module TestEcckdOriginalObjectiveTerms
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_original_objective_terms.jl ---
using JSON

include(joinpath(@__DIR__, "..", "validation", "ecckd_original_objective_terms.jl"))

@testset "ecCKD original objective term capture" begin
    result = main()
    @test result.status == "objective_terms_captured"
    @test isfile(ORIGINAL_OBJECTIVE_TERMS_JSON)
    @test isfile(ORIGINAL_OBJECTIVE_TERMS_MD)

    artifact = JSON.parsefile(ORIGINAL_OBJECTIVE_TERMS_JSON)
    @test artifact["case"] == "ecckd_original_objective_terms"
    @test artifact["status"] == "objective_terms_captured"
    @test artifact["implementation_status"] == "terms_captured_not_yet_recovered"
    @test artifact["longwave"]["ckd_function"] == "calc_cost_function_ckd_lw"
    @test artifact["shortwave"]["ckd_function"] == "calc_cost_function_ckd_sw"

    longwave_terms = Set(term["name"] for term in artifact["longwave"]["terms"])
    shortwave_terms = Set(term["name"] for term in artifact["shortwave"]["terms"])
    @test "spectral_boundary_flux" in longwave_terms
    @test "spectral_toa_up_flux_20x" in shortwave_terms
    @test "downwelling_only_heating_rate" in shortwave_terms
    @test all(term["present"] for term in artifact["longwave"]["terms"])
    @test all(term["present"] for term in artifact["shortwave"]["terms"])

    lw_sequence = artifact["pass_sequences"]["longwave"]
    sw_sequence = artifact["pass_sequences"]["shortwave"]
    @test lw_sequence["optimize_modes"] == ["relative-base", "relative-ch4", "relative-n2o", "relative-cfc"]
    @test sw_sequence["optimize_modes"] == ["relative-base", "relative-ch4", "relative-n2o"]
    @test occursin("broadband_weight=0.8", lw_sequence["selected_common_options"])
    @test occursin("broadband_weight=0.4", sw_sequence["selected_common_options"])
    @test all(pass["present"] for pass in lw_sequence["passes"])
    @test all(pass["present"] for pass in sw_sequence["passes"])

    md = read(ORIGINAL_OBJECTIVE_TERMS_MD, String)
    @test occursin("ecCKD Original Objective Terms", md)
    @test occursin("spectral_toa_up_flux_20x", md)
    @test occursin("terms_captured_not_yet_recovered", md)
end
# --- end content of test_ecckd_original_objective_terms.jl ---

end # module TestEcckdOriginalObjectiveTerms

module TestEcckdOriginalObjectiveLoss
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_original_objective_loss.jl ---
include(joinpath(@__DIR__, "..", "validation", "ecckd_original_objective_loss.jl"))

function finite_difference_gradient(f, x; step = 1.0e-6)
    gradient = similar(x)
    plus = copy(x)
    minus = copy(x)
    for i in eachindex(x)
        plus .= x
        minus .= x
        plus[i] += step
        minus[i] -= step
        gradient[i] = (f(plus) - f(minus)) / (2step)
    end
    return gradient
end

function relative_gradient_error(a, b)
    norm(a .- b) / max(norm(b), eps(eltype(b)))
end

function enzyme_gradient_for_loss(f, x)
    enzyme = Base.require(Base.PkgId(Base.UUID("7da242da-08ed-463a-9acd-ee780be4f1d9"), "Enzyme"))
    gradient = zeros(length(x))
    duplicated = Base.invokelatest(enzyme.Duplicated, copy(x), gradient)
    const_f = Base.invokelatest(enzyme.Const, f)
    Base.invokelatest(enzyme.autodiff, enzyme.Reverse, const_f,
                      enzyme.Active, duplicated)
    return gradient
end

function reactant_compile_loss_probe(x, flux_up_true, flux_dn_true, layer_weight)
    reactant = Base.require(Base.PkgId(Base.UUID("3c362404-f566-11ee-1572-e11a4b42c853"), "Reactant"))
    Base.invokelatest(reactant.set_default_backend, "cpu")
    Core.eval(@__MODULE__, :(const Reactant = $reactant))
    Core.eval(@__MODULE__, quote
        function sw_objective_loss_probe(x, flux_up_true, flux_dn_true, layer_weight)
            flux_up_fwd = reshape(x, 4, 2)
            heating = zeros(eltype(x), 3, 2)
            ecckd_sw_ckd_loss(;
                heating_rate_fwd = heating,
                heating_rate_true = heating,
                flux_dn_fwd = flux_dn_true,
                flux_up_fwd = flux_up_fwd,
                flux_dn_true = flux_dn_true,
                flux_up_true = flux_up_true,
                layer_weight = layer_weight,
                flux_weight = 0.4,
                flux_profile_weight = 0.0,
                broadband_weight = 0.0,
            )
        end
        x_ra = Reactant.to_rarray($x)
        up_ra = Reactant.to_rarray($flux_up_true)
        dn_ra = Reactant.to_rarray($flux_dn_true)
        layer_ra = Reactant.to_rarray($layer_weight)
        Reactant.@compile raise = true raise_first = true sync = true sw_objective_loss_probe(x_ra, up_ra, dn_ra, layer_ra)
    end)
    return true
end

@testset "ecCKD original objective loss assembly" begin
    layer_weight = [0.2, 0.3, 0.5]
    heating_true = zeros(3, 2)
    heating_fwd = [1.0e-6 2.0e-6;
                   -1.0e-6 0.5e-6;
                   0.0 -0.5e-6]
    flux_dn_true = [10.0 20.0;
                    9.0 18.0;
                    8.0 16.0;
                    7.0 14.0]
    flux_up_true = [1.0 2.0;
                    1.2 2.2;
                    1.4 2.4;
                    1.6 2.6]
    flux_dn_fwd = flux_dn_true .+ [0.1 -0.2;
                                   0.05 -0.1;
                                   0.02 -0.03;
                                   0.3 -0.4]
    flux_up_fwd = flux_up_true .+ [0.2 -0.1;
                                   0.04 -0.02;
                                   -0.03 0.01;
                                   0.0 0.0]

    no_profile_lw = ecckd_lw_ckd_loss(;
        heating_rate_fwd = heating_fwd,
        heating_rate_true = heating_true,
        flux_dn_fwd,
        flux_up_fwd,
        flux_dn_true,
        flux_up_true,
        layer_weight,
        flux_weight = 0.2,
        flux_profile_weight = 0.0,
        broadband_weight = 0.0,
    )
    manual_lw = 0.0
    for iband in 1:2
        manual_lw += ECCKD_HR_SECONDS_PER_DAY^2 *
            sum(layer_weight .* abs2.(heating_fwd[:, iband] .- heating_true[:, iband]))
        manual_lw += 0.2 *
            ((flux_dn_fwd[end, iband] - flux_dn_true[end, iband])^2 +
             (flux_up_fwd[1, iband] - flux_up_true[1, iband])^2)
    end
    manual_lw /= 2
    @test no_profile_lw ≈ manual_lw

    spectral_boundary_lw = ecckd_lw_ckd_loss(;
        heating_rate_fwd = heating_true,
        heating_rate_true = heating_true,
        flux_dn_fwd = flux_dn_true,
        flux_up_fwd = flux_up_true,
        flux_dn_true,
        flux_up_true,
        layer_weight,
        flux_weight = 0.0,
        flux_profile_weight = 0.0,
        broadband_weight = 0.0,
        spectral_boundary_weight = 0.1,
        flux_dn_fwd_orig = flux_dn_fwd,
        flux_up_fwd_orig = flux_up_fwd,
        spectral_flux_dn_surf = flux_dn_true[end, :],
        spectral_flux_up_toa = flux_up_true[1, :],
    )
    @test spectral_boundary_lw ≈
          0.1 * (sum(abs2, flux_dn_fwd[end, :] .- flux_dn_true[end, :]) +
                 sum(abs2, flux_up_fwd[1, :] .- flux_up_true[1, :]))

    sw_toa = ecckd_sw_ckd_loss(;
        heating_rate_fwd = heating_true,
        heating_rate_true = heating_true,
        flux_dn_fwd = flux_dn_true,
        flux_up_fwd,
        flux_dn_true,
        flux_up_true,
        layer_weight,
        flux_weight = 0.4,
        flux_profile_weight = 0.0,
        broadband_weight = 0.0,
    )
    @test sw_toa ≈ 0.4 * 20.0 *
                    sum(abs2, flux_up_fwd[1, :] .- flux_up_true[1, :])

    sw_broadband_no_up = ecckd_sw_ckd_loss(;
        heating_rate_fwd = heating_true,
        heating_rate_true = heating_true,
        flux_dn_fwd,
        flux_up_fwd,
        flux_dn_true,
        flux_up_true,
        layer_weight,
        flux_weight = 0.4,
        flux_profile_weight = 0.0,
        broadband_weight = 0.5,
        all_albedo_positive = false,
    )
    sw_broadband_up = ecckd_sw_ckd_loss(;
        heating_rate_fwd = heating_true,
        heating_rate_true = heating_true,
        flux_dn_fwd,
        flux_up_fwd,
        flux_dn_true,
        flux_up_true,
        layer_weight,
        flux_weight = 0.4,
        flux_profile_weight = 0.0,
        broadband_weight = 0.5,
        all_albedo_positive = true,
    )
    @test sw_broadband_up > sw_broadband_no_up

    sw_boundary = ecckd_sw_ckd_loss(;
        heating_rate_fwd = heating_true,
        heating_rate_true = heating_true,
        flux_dn_fwd = flux_dn_true,
        flux_up_fwd = flux_up_true,
        flux_dn_true,
        flux_up_true,
        layer_weight,
        flux_weight = 0.0,
        flux_profile_weight = 0.0,
        broadband_weight = 0.0,
        spectral_boundary_weight = 0.3,
        flux_dn_fwd_orig = flux_dn_fwd,
        spectral_flux_dn_surf = flux_dn_true[end, :],
    )
    @test sw_boundary ≈
          0.3 * sum(abs2, flux_dn_fwd[end, :] .- flux_dn_true[end, :])

    f(x) = ecckd_sw_ckd_loss(;
        heating_rate_fwd = heating_true,
        heating_rate_true = heating_true,
        flux_dn_fwd = flux_dn_true,
        flux_up_fwd = reshape(x, 4, 2),
        flux_dn_true,
        flux_up_true,
        layer_weight,
        flux_weight = 0.4,
        flux_profile_weight = 0.0,
        broadband_weight = 0.0,
    )
    parameters = vec(copy(flux_up_fwd))
    enzyme_gradient = enzyme_gradient_for_loss(f, parameters)
    finite_difference = finite_difference_gradient(f, parameters)
    @test relative_gradient_error(enzyme_gradient, finite_difference) < 1.0e-6
    @test reactant_compile_loss_probe(parameters, flux_up_true, flux_dn_true, layer_weight)
end
# --- end content of test_ecckd_original_objective_loss.jl ---

end # module TestEcckdOriginalObjectiveLoss

module TestCkdmipOriginalObjectiveDataset
using Test
using NumericalRadiation
using Dates

# Kept as a physical file: the slow AD-batch test includes it directly
# when NUMERICAL_RADIATION_RUN_SLOW_VALIDATION_TESTS=true.
include(joinpath(@__DIR__, "test_ckdmip_original_objective_dataset.jl"))

end # module TestCkdmipOriginalObjectiveDataset

include_slow_validation_test("test_ckdmip_original_objective_ad_batch.jl")

module TestOfficialEcckdTraining
using Test
using NumericalRadiation
using Dates

# --- begin content of test_official_ecckd_training.jl ---
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
# --- end content of test_official_ecckd_training.jl ---

end # module TestOfficialEcckdTraining

module TestEcckdTrainingRecoveryTargets
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_training_recovery_targets.jl ---
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
# --- end content of test_ecckd_training_recovery_targets.jl ---

end # module TestEcckdTrainingRecoveryTargets

module TestEcckdPublishedRecoveryTarget
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_published_recovery_target.jl ---
using JSON

module EcckdPublishedRecoveryTargetValidation
include(joinpath(@__DIR__, "..", "validation", "ecckd_published_recovery_target.jl"))
end

@testset "ecCKD published recovery target artifact" begin
    root = normpath(joinpath(@__DIR__, ".."))
    json_path = joinpath(root, "validation", "results", "ecckd_published_recovery_target.json")
    md_path = joinpath(root, "validation", "results", "ecckd_published_recovery_target.md")

    redirect_stdout(devnull) do
        EcckdPublishedRecoveryTargetValidation.ecckd_published_recovery_target_main()
    end

    @test isfile(json_path)
    @test isfile(md_path)

    result = JSON.parsefile(json_path)
    @test result["case"] == "ecckd_published_recovery_target"
    @test result["status"] == "published_recovery_target_ready"
    @test result["model_count"] == 6
    @test length(result["target_models"]) == 6
    @test haskey(result["primary_recovery_targets"], "shortwave_32")
    @test haskey(result["primary_recovery_targets"], "longwave_32")
    @test result["primary_recovery_targets"]["shortwave_32"]["filename"] ==
          "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc"
    @test result["primary_recovery_targets"]["longwave_32"]["filename"] ==
          "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc"
    @test result["primary_recovery_targets"]["shortwave_32"]["coefficient_array_count"] == 6
    @test result["primary_recovery_targets"]["longwave_32"]["coefficient_array_count"] == 8
    @test result["primary_recovery_targets"]["shortwave_32"]["coefficient_parameter_count"] > 0
    @test result["primary_recovery_targets"]["longwave_32"]["coefficient_parameter_count"] > 0
    @test result["primary_recovery_targets"]["shortwave_32"]["support_array_count"] >= 4
    @test result["primary_recovery_targets"]["longwave_32"]["support_array_count"] >= 3
    @test result["acceptance_metrics"]["final_objective_target_ratio_max"] <= 1.05
    @test result["acceptance_metrics"]["optical_depth_log_rmse_max"] <= 0.02
    @test occursin("optimizer settings", result["optimizer_only_delta_rule"])

    markdown = read(md_path, String)
    @test occursin("ecCKD Published Recovery Target", markdown)
    @test occursin("Published Targets", markdown)
    @test occursin("ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc", markdown)
    @test occursin("Primary 32-G Targets", markdown)
end
# --- end content of test_ecckd_published_recovery_target.jl ---

end # module TestEcckdPublishedRecoveryTarget

module TestEcckdPublishedRecoveryVector
using Test
using NumericalRadiation
using Dates

# --- begin content of test_ecckd_published_recovery_vector.jl ---
using JSON

module EcckdPublishedRecoveryVectorValidation
include(joinpath(@__DIR__, "..", "validation", "ecckd_published_recovery_vector.jl"))
end

@testset "ecCKD published recovery vector artifact" begin
    root = normpath(joinpath(@__DIR__, ".."))
    json_path = joinpath(root, "validation", "results", "ecckd_published_recovery_vector.json")
    md_path = joinpath(root, "validation", "results", "ecckd_published_recovery_vector.md")

    redirect_stdout(devnull) do
        EcckdPublishedRecoveryVectorValidation.ecckd_published_recovery_vector_main()
    end

    @test isfile(json_path)
    @test isfile(md_path)

    result = JSON.parsefile(json_path)
    @test result["case"] == "ecckd_published_recovery_vector"
    @test result["status"] == "passed"
    @test result["array_count"] == 9
    @test result["parameter_count"] == 204896
    @test result["roundtrip_error"]["max_abs_error"] == 0.0
    @test result["roundtrip_error"]["l1_relative_error"] == 0.0
    @test result["recovery_metrics"]["status"] == "passed"
    @test result["recovery_metrics"]["worst_log_coefficient_rmse"] == 0.0
    @test result["recovery_metrics"]["gpoint_weight_max_abs_error"] == 0.0
    @test any(row -> row["name"] == "gpoint_fraction", result["arrays"])
    @test any(row -> row["name"] == "solar_irradiance", result["arrays"])
    @test any(row -> row["name"] == "rayleigh_molar_scattering_coeff", result["arrays"])

    markdown = read(md_path, String)
    @test occursin("ecCKD Published Recovery Vector", markdown)
    @test occursin("Round-trip max abs error", markdown)
    @test occursin("optimizer handoff vector", markdown)
end
# --- end content of test_ecckd_published_recovery_vector.jl ---

end # module TestEcckdPublishedRecoveryVector

include_slow_validation_test("test_ecckd_published_recovery_vector_training.jl")
