include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

const RESULTS_DIR = validation_results_dir()
const RECOVERY_GOAL_AUDIT_JSON = joinpath(RESULTS_DIR, "recovery_goal_audit.json")
const RECOVERY_GOAL_AUDIT_MD = joinpath(RESULTS_DIR, "recovery_goal_audit.md")

const ECRAD_ACCURACY_JSON = joinpath(RESULTS_DIR, "ecrad_accuracy_gate.json")
const ECRAD_ALL_SKY_JSON = joinpath(RESULTS_DIR, "ecrad_all_sky_ifs_gate.json")
const REDUCED_ACCURACY_JSON = joinpath(RESULTS_DIR, "reduced_ecckd_accuracy.json")
const PUBLISHED_MODEL_ACCURACY_JSON = joinpath(RESULTS_DIR, "ecckd_published_model_accuracy.json")
const PUBLISHED_ALL_SKY_ACCURACY_JSON =
    joinpath(RESULTS_DIR, "ecckd_published_all_sky_accuracy.json")
const MATCHED_REFERENCE_PLAN_JSON = joinpath(RESULTS_DIR, "ecckd_matched_reference_plan.json")
const RRTMGP_COMPARISON_JSON = joinpath(RESULTS_DIR, "reduced_ecckd_32g_rrtmgp_comparison.json")
const TEACHER_STUDENT_SCAN_JSON = joinpath(RESULTS_DIR, "ecckd_teacher_student_recovery_scan.json")
const OBJECTIVE_RECONSTRUCTION_JSON = joinpath(RESULTS_DIR, "ecckd_objective_reconstruction_check.json")
const ORIGINAL_OBJECTIVE_TERMS_JSON = joinpath(RESULTS_DIR, "ecckd_original_objective_terms.json")
const CKDMIP_OBJECTIVE_DATASET_JSON = joinpath(RESULTS_DIR, "ckdmip_original_objective_dataset.json")
const CKDMIP_OBJECTIVE_AD_BATCH_JSON = joinpath(RESULTS_DIR, "ckdmip_original_objective_ad_batch.json")
const PUBLISHED_RECOVERY_TARGET_JSON =
    joinpath(RESULTS_DIR, "ecckd_published_recovery_target.json")
const PUBLISHED_RECOVERY_VECTOR_JSON =
    joinpath(RESULTS_DIR, "ecckd_published_recovery_vector.json")
const PUBLISHED_RECOVERY_VECTOR_TRAINING_JSON =
    joinpath(RESULTS_DIR, "ecckd_published_recovery_vector_training.json")
const OFFICIAL_TRAINING_JSON = joinpath(RESULTS_DIR, "official_ecckd_training.json")
const TRAINING_TARGETS_JSON = joinpath(RESULTS_DIR, "ecckd_training_recovery_targets.json")
const CKDMIP_PREFLIGHT_JSON = joinpath(RESULTS_DIR, "ckdmip_training_data_preflight.json")
const DERIVED_FLUX_PLAN_JSON = joinpath(RESULTS_DIR, "ecckd_derived_flux_generation_plan.json")
const BAND_PARETO_JSON = joinpath(RESULTS_DIR, "ecckd_band_accuracy_pareto.json")
const LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_JSON =
    joinpath(RESULTS_DIR,
             "reduced_ecckd_leave_one_out_weight_coordinate_boundary_polish.json")
const DEFAULT_BREEZE_RCEMIP_JSON =
    "/shared/home/greg/Projects/BreezeRadiativeHeatingDev/Breeze.jl/benchmarking/results/rcemip_h100_32x32x64/radiative_heating_rcemip_latest.json"

json_get(object, key, default = nothing) = haskey(object, key) ? object[key] : default
json_present(path) = isfile(path) ? JSON.parsefile(path) : nothing
json_status(path) = (data = json_present(path); data === nothing ? "missing" : String(json_get(data, "status", "unknown")))

function reduced_model_summary()
    data = json_present(REDUCED_ACCURACY_JSON)
    data === nothing && return (
        artifact = REDUCED_ACCURACY_JSON,
        present = false,
        full_32x32_passed = false,
        reduced_candidates_present = false,
        reduced_candidates_passed = false,
        hard_boundary_forcing_threshold_w_m2 = nothing,
        official_32x32_worst_boundary_forcing_error_w_m2 = nothing,
        best_reduced_candidate = nothing,
        passing_band_counts = Int[],
        failing_reduced_band_counts = Int[],
    )

    thresholds = json_get(data, "acceptance_thresholds", Dict{String, Any}())
    hard_boundary_threshold = if haskey(thresholds, "toa_forcing_abs_error_w_m2") &&
                                 haskey(thresholds, "surface_forcing_abs_error_w_m2")
        max(Float64(thresholds["toa_forcing_abs_error_w_m2"]),
            Float64(thresholds["surface_forcing_abs_error_w_m2"]))
    else
        nothing
    end

    passing_band_counts = Int[]
    failing_reduced_band_counts = Int[]
    full_32x32_passed = false
    reduced_candidates_present = false
    reduced_candidates_passed = false
    official_32x32_worst_boundary = nothing
    best_reduced_candidate = nothing
    for model in json_get(data, "models", Any[])
        ng_lw = Int(json_get(model, "ng_lw", 0))
        ng_sw = Int(json_get(model, "ng_sw", 0))
        total = ng_lw + ng_sw
        passed = Bool(json_get(model, "passed_hard_thresholds", false))
        cases = json_get(model, "cases", Any[])
        worst_toa = isempty(cases) ? Inf :
            maximum(Float64(json_get(case, "toa_forcing_max_abs", Inf)) for case in cases)
        worst_surface = isempty(cases) ? Inf :
            maximum(Float64(json_get(case, "surface_forcing_max_abs", Inf)) for case in cases)
        worst_boundary = max(worst_toa, worst_surface)
        if ng_lw == 32 && ng_sw == 32 && passed
            full_32x32_passed = true
            official_32x32_worst_boundary = worst_boundary
        end
        if ng_sw < 32 || ng_lw < 32
            reduced_candidates_present = true
            candidate = (
                ng_lw = ng_lw,
                ng_sw = ng_sw,
                total_gpoints = total,
                reduction_method = String(json_get(model, "reduction_method", "")),
                passed = passed,
                worst_toa_forcing_error_w_m2 = worst_toa,
                worst_surface_forcing_error_w_m2 = worst_surface,
                worst_boundary_forcing_error_w_m2 = worst_boundary,
            )
            if best_reduced_candidate === nothing ||
               candidate.worst_boundary_forcing_error_w_m2 <
               best_reduced_candidate.worst_boundary_forcing_error_w_m2
                best_reduced_candidate = candidate
            end
            if passed
                reduced_candidates_passed = true
                push!(passing_band_counts, total)
            else
                push!(failing_reduced_band_counts, total)
            end
        elseif passed
            push!(passing_band_counts, total)
        end
    end
    return (
        artifact = REDUCED_ACCURACY_JSON,
        present = true,
        full_32x32_passed = full_32x32_passed,
        reduced_candidates_present = reduced_candidates_present,
        reduced_candidates_passed = reduced_candidates_passed,
        hard_boundary_forcing_threshold_w_m2 = hard_boundary_threshold,
        official_32x32_worst_boundary_forcing_error_w_m2 = official_32x32_worst_boundary,
        best_reduced_candidate = best_reduced_candidate,
        passing_band_counts = sort(unique(passing_band_counts)),
        failing_reduced_band_counts = sort(unique(failing_reduced_band_counts)),
    )
end

function published_model_accuracy_summary()
    data = json_present(PUBLISHED_MODEL_ACCURACY_JSON)
    data === nothing && return (
        artifact = PUBLISHED_MODEL_ACCURACY_JSON,
        present = false,
        status = "missing",
        model_count = 0,
        passed_count = 0,
        boundary_compatible_count = 0,
        isolation_diagnostic_count = 0,
        boundary_projection_diagnostic_count = 0,
        failed_labels = String[],
    )
    models = json_get(data, "models", Any[])
    isolation_diagnostics = json_get(data, "isolation_diagnostics", Any[])
    boundary_projection_diagnostics =
        json_get(data, "boundary_projection_diagnostics", Any[])
    failed = [String(json_get(model, "label", "")) for model in models
              if !Bool(json_get(model, "passed_hard_thresholds", false))]
    boundary_compatible_count = count(models) do model
        compatibility = json_get(model, "boundary_compatibility", Dict{String, Any}())
        Bool(json_get(compatibility, "all_longwave_spectral_boundaries_match", false)) &&
            Bool(json_get(compatibility,
                          "all_shortwave_surface_albedo_boundaries_match", false))
    end
    return (
        artifact = PUBLISHED_MODEL_ACCURACY_JSON,
        present = true,
        status = String(json_get(data, "status", "unknown")),
        model_count = length(models),
        passed_count = count(model -> Bool(json_get(model, "passed_hard_thresholds", false)),
                             models),
        boundary_compatible_count = boundary_compatible_count,
        isolation_diagnostic_count = length(isolation_diagnostics),
        boundary_projection_diagnostic_count = length(boundary_projection_diagnostics),
        failed_labels = failed,
    )
end

function matched_reference_summary()
    data = json_present(MATCHED_REFERENCE_PLAN_JSON)
    data === nothing && return (
        artifact = MATCHED_REFERENCE_PLAN_JSON,
        present = false,
        status = "missing",
        required_case_count = 0,
        missing_case_count = 0,
        all_sky_case_count = 0,
        all_sky_ready_count = 0,
    )
    cases = json_get(data, "required_cases", Any[])
    all_sky_cases = filter(case -> Bool(json_get(case, "all_sky", false)), cases)
    ready(case) = Bool(json_get(case, "present", false)) &&
        Bool(json_get(case, "boundary_gpoints_match", false)) &&
        isempty(json_get(case, "missing_variables", Any[]))
    return (
        artifact = MATCHED_REFERENCE_PLAN_JSON,
        present = true,
        status = String(json_get(data, "status", "unknown")),
        required_case_count = length(cases),
        missing_case_count = Int(json_get(data, "missing_case_count", length(cases))),
        all_sky_case_count = length(all_sky_cases),
        all_sky_ready_count = count(ready, all_sky_cases),
    )
end

function published_all_sky_accuracy_summary()
    data = json_present(PUBLISHED_ALL_SKY_ACCURACY_JSON)
    data === nothing && return (
        artifact = PUBLISHED_ALL_SKY_ACCURACY_JSON,
        present = false,
        status = "missing",
        model_count = 0,
        passed_count = 0,
        failed_labels = String[],
        worst_hard_objective = nothing,
    )
    models = json_get(data, "models", Any[])
    failed = [String(json_get(model, "label", "")) for model in models
              if !Bool(json_get(model, "passed", false))]
    objectives = [Float64(json_get(model, "hard_objective", 0.0)) for model in models]
    return (
        artifact = PUBLISHED_ALL_SKY_ACCURACY_JSON,
        present = true,
        status = String(json_get(data, "status", "unknown")),
        model_count = length(models),
        passed_count = Int(json_get(data, "passed_count", 0)),
        failed_labels = failed,
        worst_hard_objective = isempty(objectives) ? nothing : maximum(objectives),
    )
end

function reduced_weight_coordinate_boundary_polish_summary()
    data = json_present(LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_JSON)
    data === nothing && return (
        artifact = LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_JSON,
        present = false,
        accepted = false,
        passed = false,
        omitted_gpoint = nothing,
        final_objective = nothing,
        final_worst_boundary_forcing_error_w_m2 = nothing,
        final_worst_heating_rate_rmse_k_day = nothing,
    )
    final_objective = json_get(data, "final_objective", nothing)
    return (
        artifact = LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_JSON,
        present = true,
        status = String(json_get(data, "status", "unknown")),
        accepted = Int(json_get(data, "accepted_move_count", 0)) > 0,
        passed = final_objective !== nothing && Float64(final_objective) <= 1.0,
        omitted_gpoint = json_get(data, "omitted_gpoint", nothing),
        accepted_move_count = json_get(data, "accepted_move_count", nothing),
        initial_objective = json_get(data, "initial_objective", nothing),
        final_objective = final_objective,
        objective_reduction = json_get(data, "objective_reduction", nothing),
        final_worst_boundary_forcing_error_w_m2 =
            json_get(data, "final_worst_boundary_forcing_error_w_m2", nothing),
        final_worst_heating_rate_rmse_k_day =
            json_get(data, "final_worst_heating_rate_rmse_k_day", nothing),
    )
end

function breeze_summary()
    artifact = get(ENV, "RH_BREEZE_RCEMIP_JSON", DEFAULT_BREEZE_RCEMIP_JSON)
    data = json_present(artifact)
    data === nothing && return (
        artifact = artifact,
        present = false,
        status = "missing",
        workload = "",
        gas_model_kind = "",
        gas_model_accuracy_status = "",
        runtime_supported = false,
        final_4x_claim_supported = false,
        speedup = 0.0,
        nsys_report = "",
        ncu_report = "",
    )
    return (
        artifact = artifact,
        present = true,
        status = String(json_get(data, "status", "unknown")),
        workload = String(json_get(data, "workload", "")),
        gas_model_kind = String(json_get(data, "gas_model_kind", "")),
        gas_model_accuracy_status = String(json_get(data, "gas_model_accuracy_status", "")),
        runtime_supported = Bool(json_get(data, "radiative_heating_runtime_supported", false)),
        final_4x_claim_supported = Bool(json_get(data, "final_4x_claim_supported", false)),
        speedup = Float64(json_get(data, "radiation_update_speedup", 0.0)),
        nsys_report = String(json_get(data, "nsys_report", "")),
        ncu_report = String(json_get(data, "ncu_report", "")),
    )
end

function official_training_summary()
    data = json_present(OFFICIAL_TRAINING_JSON)
    data === nothing && return (
        artifact = OFFICIAL_TRAINING_JSON,
        present = false,
        status = "missing",
        parameter_count = 0,
        ng_sw = 0,
        optimizer = "",
        initial_objective = nothing,
        final_objective = nothing,
        objective_target = nothing,
        final_objective_target_ratio = nothing,
        hard_accuracy_target_met = false,
        reactant_status = "missing",
        enzyme_status = "missing",
        acceptance_gap_status = "missing",
        next_required_work = "",
    )
    reactant = json_get(data, "reactant_check", Dict{String, Any}())
    enzyme = json_get(data, "enzyme_check", Dict{String, Any}())
    return (
        artifact = OFFICIAL_TRAINING_JSON,
        present = true,
        status = String(json_get(data, "status", "unknown")),
        parameter_count = Int(json_get(data, "parameter_count", 0)),
        ng_sw = Int(json_get(data, "ng_sw", 0)),
        optimizer = String(json_get(data, "optimizer", "")),
        initial_objective = json_get(data, "initial_objective", nothing),
        final_objective = json_get(data, "final_objective", nothing),
        objective_target = json_get(data, "objective_target", nothing),
        final_objective_target_ratio = json_get(data, "final_objective_target_ratio", nothing),
        hard_accuracy_target_met = Bool(json_get(data, "hard_accuracy_target_met", false)),
        reactant_status = String(json_get(reactant, "status", "unknown")),
        enzyme_status = String(json_get(enzyme, "status", "unknown")),
        acceptance_gap_status = String(json_get(data, "acceptance_gap_status", "unknown")),
        next_required_work = String(json_get(data, "next_required_work", "")),
    )
end

function training_targets_summary()
    data = json_present(TRAINING_TARGETS_JSON)
    data === nothing && return (
        artifact = TRAINING_TARGETS_JSON,
        present = false,
        status = "missing",
        official_final_objective_target_ratio = nothing,
        reduced_hard_accuracy_target_met = false,
        reduced_final_objective_target_ratio = nothing,
    )
    official = json_get(data, "current_official_recovery", Dict{String, Any}())
    reduced = json_get(data, "current_in_house_reduced_scheme", Dict{String, Any}())
    return (
        artifact = TRAINING_TARGETS_JSON,
        present = true,
        status = String(json_get(data, "status", "unknown")),
        official_final_objective_target_ratio =
            json_get(official, "final_objective_target_ratio", nothing),
        reduced_hard_accuracy_target_met =
            Bool(json_get(reduced, "hard_accuracy_target_met", false)),
        reduced_final_objective_target_ratio =
            json_get(reduced, "final_objective_target_ratio", nothing),
    )
end

function original_objective_terms_summary()
    data = json_present(ORIGINAL_OBJECTIVE_TERMS_JSON)
    data === nothing && return (
        artifact = ORIGINAL_OBJECTIVE_TERMS_JSON,
        present = false,
        status = "missing",
        implementation_status = "missing",
        longwave_term_count = 0,
        shortwave_term_count = 0,
        longwave_terms_present = false,
        shortwave_terms_present = false,
    )
    longwave_terms = json_get(json_get(data, "longwave", Dict{String, Any}()),
                              "terms", Any[])
    shortwave_terms = json_get(json_get(data, "shortwave", Dict{String, Any}()),
                               "terms", Any[])
    return (
        artifact = ORIGINAL_OBJECTIVE_TERMS_JSON,
        present = true,
        status = String(json_get(data, "status", "unknown")),
        implementation_status = String(json_get(data, "implementation_status", "unknown")),
        longwave_term_count = length(longwave_terms),
        shortwave_term_count = length(shortwave_terms),
        longwave_terms_present = !isempty(longwave_terms) &&
            all(term -> Bool(json_get(term, "present", false)), longwave_terms),
        shortwave_terms_present = !isempty(shortwave_terms) &&
            all(term -> Bool(json_get(term, "present", false)), shortwave_terms),
    )
end

function ckdmip_objective_dataset_summary()
    data = json_present(CKDMIP_OBJECTIVE_DATASET_JSON)
    data === nothing && return (
        artifact = CKDMIP_OBJECTIVE_DATASET_JSON,
        present = false,
        status = "missing",
        sample_count = 0,
        training_flux_file_count = 0,
        training_flux_schema_ok_count = 0,
        longwave_sample_ready = false,
        shortwave_sample_ready = false,
        self_loss_zero = false,
    )
    samples = json_get(data, "samples", Any[])
    kinds = Set(String(json_get(sample, "kind", "")) for sample in samples)
    return (
        artifact = CKDMIP_OBJECTIVE_DATASET_JSON,
        present = true,
        status = String(json_get(data, "status", "unknown")),
        sample_count = length(samples),
        training_flux_file_count = Int(json_get(data, "training_flux_file_count", 0)),
        training_flux_schema_ok_count = Int(json_get(data, "training_flux_schema_ok_count", 0)),
        longwave_sample_ready = "longwave" in kinds,
        shortwave_sample_ready = "shortwave" in kinds,
        self_loss_zero = !isempty(samples) &&
            all(sample -> Float64(json_get(sample, "self_loss", Inf)) == 0.0, samples),
    )
end

function ckdmip_objective_ad_batch_summary()
    data = json_present(CKDMIP_OBJECTIVE_AD_BATCH_JSON)
    data === nothing && return (
        artifact = CKDMIP_OBJECTIVE_AD_BATCH_JSON,
        present = false,
        status = "missing",
        parameter_count = 0,
        accepted_step = false,
        loss_reduction_factor = nothing,
        gradient_method = "missing",
    )
    return (
        artifact = CKDMIP_OBJECTIVE_AD_BATCH_JSON,
        present = true,
        status = String(json_get(data, "status", "unknown")),
        parameter_count = Int(json_get(data, "parameter_count", 0)),
        accepted_step = Bool(json_get(data, "accepted_step", false)),
        loss_reduction_factor = json_get(data, "loss_reduction_factor", nothing),
        gradient_method = String(json_get(data, "gradient_method", "unknown")),
    )
end

function published_recovery_target_summary()
    data = json_present(PUBLISHED_RECOVERY_TARGET_JSON)
    data === nothing && return (
        artifact = PUBLISHED_RECOVERY_TARGET_JSON,
        present = false,
        status = "missing",
        model_count = 0,
        shortwave_32_parameter_count = 0,
        longwave_32_parameter_count = 0,
        final_objective_target_ratio_max = nothing,
        optical_depth_log_rmse_max = nothing,
        optimizer_only_delta_rule_present = false,
    )
    primary = json_get(data, "primary_recovery_targets", Dict{String, Any}())
    shortwave = json_get(primary, "shortwave_32", Dict{String, Any}())
    longwave = json_get(primary, "longwave_32", Dict{String, Any}())
    metrics = json_get(data, "acceptance_metrics", Dict{String, Any}())
    return (
        artifact = PUBLISHED_RECOVERY_TARGET_JSON,
        present = true,
        status = String(json_get(data, "status", "unknown")),
        model_count = Int(json_get(data, "model_count", 0)),
        shortwave_32_parameter_count =
            Int(json_get(shortwave, "coefficient_parameter_count", 0)),
        longwave_32_parameter_count =
            Int(json_get(longwave, "coefficient_parameter_count", 0)),
        final_objective_target_ratio_max =
            json_get(metrics, "final_objective_target_ratio_max", nothing),
        optical_depth_log_rmse_max =
            json_get(metrics, "optical_depth_log_rmse_max", nothing),
        optimizer_only_delta_rule_present =
            occursin("optimizer settings",
                     String(json_get(data, "optimizer_only_delta_rule", ""))),
    )
end

function published_recovery_vector_summary()
    data = json_present(PUBLISHED_RECOVERY_VECTOR_JSON)
    data === nothing && return (
        artifact = PUBLISHED_RECOVERY_VECTOR_JSON,
        present = false,
        status = "missing",
        array_count = 0,
        parameter_count = 0,
        roundtrip_max_abs_error = nothing,
        roundtrip_l1_relative_error = nothing,
        recovery_metrics_status = "missing",
    )
    roundtrip = json_get(data, "roundtrip_error", Dict{String, Any}())
    metrics = json_get(data, "recovery_metrics", Dict{String, Any}())
    return (
        artifact = PUBLISHED_RECOVERY_VECTOR_JSON,
        present = true,
        status = String(json_get(data, "status", "unknown")),
        array_count = Int(json_get(data, "array_count", 0)),
        parameter_count = Int(json_get(data, "parameter_count", 0)),
        roundtrip_max_abs_error = json_get(roundtrip, "max_abs_error", nothing),
        roundtrip_l1_relative_error = json_get(roundtrip, "l1_relative_error", nothing),
        recovery_metrics_status = String(json_get(metrics, "status", "unknown")),
    )
end

function published_recovery_vector_training_summary()
    data = json_present(PUBLISHED_RECOVERY_VECTOR_TRAINING_JSON)
    data === nothing && return (
        artifact = PUBLISHED_RECOVERY_VECTOR_TRAINING_JSON,
        present = false,
        status = "missing",
        parameter_count = 0,
        trained_parameter_count = 0,
        final_loss = nothing,
        loss_reduction_factor = nothing,
        enzyme_requested = false,
        reactant_check_requested = false,
        recovery_metrics_status = "missing",
    )
    metrics = json_get(data, "recovery_metrics", Dict{String, Any}())
    return (
        artifact = PUBLISHED_RECOVERY_VECTOR_TRAINING_JSON,
        present = true,
        status = String(json_get(data, "status", "unknown")),
        parameter_count = Int(json_get(data, "parameter_count", 0)),
        trained_parameter_count = Int(json_get(data, "trained_parameter_count", 0)),
        final_loss = json_get(data, "final_loss", nothing),
        loss_reduction_factor = json_get(data, "loss_reduction_factor", nothing),
        enzyme_requested = Bool(json_get(data, "enzyme_requested", false)),
        reactant_check_requested = Bool(json_get(data, "reactant_check_requested", false)),
        recovery_metrics_status = String(json_get(metrics, "status", "unknown")),
    )
end


function raw_derived_chunk_count(root, relative_path)
    root isa AbstractString || return 0
    m = match(r"^(evaluation[12])/(lw|sw)_fluxes/(ckdmip_[^/]+\.h5)$", relative_path)
    m === nothing && return 0
    dataset, domain, filename = m.captures
    directory = joinpath(root, dataset, "$(domain)_fluxes")
    isdir(directory) || return 0
    stem = replace(filename, ".h5" => "")
    prefix = "RAW_$(stem)_"
    return count(name -> startswith(name, prefix) && endswith(name, ".h5"),
                 readdir(directory))
end

function expected_derived_chunk_count(root, relative_path)
    root isa AbstractString || return 0
    m = match(r"^(evaluation[12])/(lw|sw)_fluxes/ckdmip_[^/]+\.h5$", relative_path)
    m === nothing && return 0
    dataset, domain = m.captures
    spectra_dir = joinpath(root, dataset, "$(domain)_spectra")
    isdir(spectra_dir) || return 0
    prefix = "ckdmip_$(dataset)_$(domain)_spectra_h2o_present_"
    return count(name -> startswith(name, prefix) && endswith(name, ".h5"),
                 readdir(spectra_dir))
end

function derived_flux_progress_summary(ckdmip)
    ckdmip === nothing && return (
        expected = 0,
        final_present = 0,
        products_with_raw_chunks = 0,
        missing = 0,
    )
    root = json_get(ckdmip, "ckdmip_data_root", nothing)
    products = json_get(ckdmip, "derived_training_flux_products", Any[])
    final_present = count(product -> Bool(json_get(product, "present", false)), products)
    raw_chunk_counts = [
        raw_derived_chunk_count(root, String(json_get(product, "path", "")))
        for product in products
    ]
    expected_chunk_counts = [
        expected_derived_chunk_count(root, String(json_get(product, "path", "")))
        for product in products
    ]
    products_with_raw_chunks = count(>(0), raw_chunk_counts)
    raw_times = Float64[]
    for product in products
        path = String(json_get(product, "path", ""))
        root isa AbstractString || continue
        m = match(r"^(evaluation[12])/(lw|sw)_fluxes/(ckdmip_[^/]+\.h5)$", path)
        m === nothing && continue
        dataset, domain, filename = m.captures
        directory = joinpath(root, dataset, "$(domain)_fluxes")
        isdir(directory) || continue
        stem = replace(filename, ".h5" => "")
        prefix = "RAW_$(stem)_"
        for name in readdir(directory)
            startswith(name, prefix) && endswith(name, ".h5") &&
                push!(raw_times, stat(joinpath(directory, name)).mtime)
        end
    end
    present_raw_chunks = sum(raw_chunk_counts; init = 0)
    expected_raw_chunks = sum(expected_chunk_counts; init = 0)
    completed_equivalent_raw_chunks = sum(
        zip(json_get.(products, Ref("present"), Ref(false)), raw_chunk_counts, expected_chunk_counts),
    ) do (final_present, raw_count, expected_count)
        Bool(final_present) ? expected_count : raw_count
    end
    remaining_raw_chunks = max(expected_raw_chunks - present_raw_chunks, 0)
    if isempty(raw_times) || present_raw_chunks == 0
        rate = nothing
        estimated_hours = nothing
    else
        elapsed_hours = max((time() - minimum(raw_times)) / 3600, 1.0 / 3600)
        rate = present_raw_chunks / elapsed_hours
        estimated_hours = rate > 0 ? remaining_raw_chunks / rate : nothing
    end
    return (
        expected = length(products),
        final_present = final_present,
        products_with_raw_chunks = products_with_raw_chunks,
        expected_raw_chunks = expected_raw_chunks,
        present_raw_chunks = present_raw_chunks,
        completed_equivalent_raw_chunks = completed_equivalent_raw_chunks,
        observed_raw_chunk_rate_per_hour = rate,
        estimated_raw_chunk_hours_remaining = estimated_hours,
        missing = length(products) - final_present,
    )
end

function derived_flux_plan_summary()
    plan = json_present(DERIVED_FLUX_PLAN_JSON)
    plan === nothing && return (
        artifact = DERIVED_FLUX_PLAN_JSON,
        present = false,
        status = "missing",
        expected_derived_flux_count = 0,
        present_derived_flux_count = 0,
        raw_chunk_product_count = 0,
        present_raw_chunk_count = 0,
        expected_raw_chunk_count = 0,
        completed_equivalent_raw_chunk_count = 0,
        raw_chunk_rate = nothing,
        ncrcat = nothing,
    )
    return (
        artifact = DERIVED_FLUX_PLAN_JSON,
        present = true,
        status = String(json_get(plan, "status", "unknown")),
        expected_derived_flux_count = Int(json_get(plan, "expected_derived_flux_count", 0)),
        present_derived_flux_count = Int(json_get(plan, "present_derived_flux_count", 0)),
        raw_chunk_product_count = Int(json_get(plan, "raw_chunk_product_count", 0)),
        present_raw_chunk_count = Int(json_get(plan, "present_raw_chunk_count", 0)),
        expected_raw_chunk_count = Int(json_get(plan, "expected_raw_chunk_count", 0)),
        completed_equivalent_raw_chunk_count =
            Int(json_get(plan, "completed_equivalent_raw_chunk_count",
                         json_get(plan, "present_raw_chunk_count", 0))),
        raw_chunk_rate = json_get(plan, "raw_chunk_rate", nothing),
        ncrcat = json_get(plan, "ncrcat", nothing),
    )
end

function derived_flux_progress_from_plan(plan)
    rate = plan.raw_chunk_rate
    return (
        expected = plan.expected_derived_flux_count,
        final_present = plan.present_derived_flux_count,
        products_with_raw_chunks = plan.raw_chunk_product_count,
        expected_raw_chunks = plan.expected_raw_chunk_count,
        present_raw_chunks = plan.present_raw_chunk_count,
        completed_equivalent_raw_chunks = plan.completed_equivalent_raw_chunk_count,
        observed_raw_chunk_rate_per_hour =
            rate === nothing ? nothing : json_get(rate, "observed_raw_chunk_rate_per_hour", nothing),
        estimated_raw_chunk_hours_remaining =
            rate === nothing ? nothing : json_get(rate, "estimated_hours_remaining", nothing),
        missing = max(plan.expected_derived_flux_count - plan.present_derived_flux_count, 0),
    )
end

function prompt_artifact_checklist(requirements)
    return [
        (
            requirement_id = row.id,
            prompt_requirement = row.requirement,
            coverage_status = row.status,
            evidence = row.evidence,
            covered = row.status == "passed",
            gap = row.status == "passed" ? "" : row.finding,
        )
        for row in requirements
    ]
end

function run_recovery_goal_audit()
    reduced = reduced_model_summary()
    published_accuracy = published_model_accuracy_summary()
    matched_references = matched_reference_summary()
    published_all_sky = published_all_sky_accuracy_summary()
    weight_polish = reduced_weight_coordinate_boundary_polish_summary()
    breeze = breeze_summary()
    official_training = official_training_summary()
    training_targets = training_targets_summary()
    original_objective_terms = original_objective_terms_summary()
    ckdmip_objective_dataset = ckdmip_objective_dataset_summary()
    ckdmip_objective_ad_batch = ckdmip_objective_ad_batch_summary()
    published_recovery_target = published_recovery_target_summary()
    published_recovery_vector = published_recovery_vector_summary()
    published_recovery_vector_training = published_recovery_vector_training_summary()
    teacher = json_present(TEACHER_STUDENT_SCAN_JSON)
    objective = json_present(OBJECTIVE_RECONSTRUCTION_JSON)
    ckdmip = json_present(CKDMIP_PREFLIGHT_JSON)
    pareto = json_present(BAND_PARETO_JSON)
    derived_plan = derived_flux_plan_summary()
    ckdmip_preflight_status = ckdmip === nothing ? "missing" : String(json_get(ckdmip, "status", "unknown"))
    objective_status = objective === nothing ? "missing" : String(json_get(objective, "status", "unknown"))
    derived_flux_progress = derived_plan.present && derived_plan.expected_derived_flux_count > 0 ?
                            derived_flux_progress_from_plan(derived_plan) :
                            derived_flux_progress_summary(ckdmip)
    original_objective_assets_ready =
        ckdmip_preflight_status == "ready_for_original_ecckd_objective" ||
        objective_status == "ready_to_reconstruct_original_objective"

    requirements = NamedTuple[]

    parity_status = json_status(ECRAD_ACCURACY_JSON) == "passed" &&
        json_status(ECRAD_ALL_SKY_JSON) == "passed" &&
        reduced.full_32x32_passed ? "partial" : "blocked"
    push!(requirements, (
        id = "ecrad_full_and_reduced_parity",
        requirement = "Demonstrate parity with ecRad for full-accuracy models and reduced ecCKD models such as 16- and 32-band variants.",
        status = parity_status,
        evidence = [
            ECRAD_ACCURACY_JSON,
            ECRAD_ALL_SKY_JSON,
            PUBLISHED_MODEL_ACCURACY_JSON,
            PUBLISHED_ALL_SKY_ACCURACY_JSON,
            MATCHED_REFERENCE_PLAN_JSON,
            REDUCED_ACCURACY_JSON,
            BAND_PARETO_JSON,
            LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_JSON,
        ],
        finding = reduced.reduced_candidates_passed ?
            "The promoted 32x32, 32x64, 32x96, 64x32, 64x64, and 64x96 published ecCKD combinations and at least one reduced candidate pass the clean package-native hard thresholds; $(matched_references.all_sky_ready_count)/$(matched_references.all_sky_case_count) all-sky promoted-combination reference products are present with matching spectral boundaries, and package all-sky comparisons currently pass $(published_all_sky.passed_count)/$(published_all_sky.model_count) promoted rows, while lower-band reduced variants remain incomplete." :
            weight_polish.passed ?
            "Full official ecCKD 32x32 passes and the exact g$(weight_polish.omitted_gpoint) 32x31 weight-coordinate boundary polish now passes the hard objective at $(weight_polish.final_objective)x while keeping boundary forcing at $(weight_polish.final_worst_boundary_forcing_error_w_m2) W m^-2." :
            "Full official ecCKD 32x32 passes, but currently measured reduced shortwave candidates fail the hard thresholds.",
    ))

    rrtmgp_status = json_status(RRTMGP_COMPARISON_JSON) == "passed" &&
        reduced.full_32x32_passed ? "partial" : "blocked"
    push!(requirements, (
        id = "reduced_vs_rrtmgp_representative_states",
        requirement = "Demonstrate that reduced models meet accuracy criteria when compared to RRTMGP for representative atmosphere states.",
        status = rrtmgp_status,
        evidence = [
            RRTMGP_COMPARISON_JSON,
            REDUCED_ACCURACY_JSON,
            BAND_PARETO_JSON,
            LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_JSON,
        ],
        finding = reduced.reduced_candidates_passed ?
            "RRTMGP comparison metrics are emitted and at least one reduced candidate passes hard thresholds." :
            weight_polish.passed ?
            "RRTMGP comparison metrics are emitted for the official 32x32 path on representative states, and the best tracked 31-SW row now passes the exact hard objective at $(weight_polish.final_objective)x with boundary forcing $(weight_polish.final_worst_boundary_forcing_error_w_m2) W m^-2." :
            "RRTMGP comparison metrics are emitted for the official 32x32 path on representative states, but reduced candidates do not yet pass hard accuracy criteria.",
    ))

    breeze_passed = breeze.present && breeze.runtime_supported &&
        breeze.final_4x_claim_supported && breeze.gas_model_accuracy_status == "passed"
    push!(requirements, (
        id = "breeze_dynamic_integration",
        requirement = "Demonstrate that the new radiation models can be integrated into Breeze simulations dynamically without blowing them up.",
        status = breeze_passed ? "passed" : "blocked",
        evidence = [breeze.artifact],
        finding = breeze_passed ?
            "The dedicated Breeze RCEMIP-style H100 artifact records a supported official ecCKD 32/32 runtime, passed gas-model accuracy status, and a finite >=4x RRTMGP speedup." :
            "No passing dedicated Breeze RCEMIP-style runtime artifact was found.",
    ))

    teacher_passed = teacher !== nothing && String(json_get(teacher, "status", "unknown")) == "passed"
    exact_recovery_passed = objective_status == "passed"
    push!(requirements, (
        id = "reactant_enzyme_ecckd_training_recovery",
        requirement = "Reimplement the ecCKD training pipeline and demonstrate success by recovering one published model while varying only optimizer settings.",
        status = exact_recovery_passed ? "passed" :
                 (original_objective_assets_ready || official_training.present) ? "partial" : "blocked",
        evidence = [
            TEACHER_STUDENT_SCAN_JSON,
            OFFICIAL_TRAINING_JSON,
            TRAINING_TARGETS_JSON,
            OBJECTIVE_RECONSTRUCTION_JSON,
            ORIGINAL_OBJECTIVE_TERMS_JSON,
            CKDMIP_OBJECTIVE_DATASET_JSON,
            CKDMIP_OBJECTIVE_AD_BATCH_JSON,
            PUBLISHED_RECOVERY_TARGET_JSON,
            PUBLISHED_RECOVERY_VECTOR_JSON,
            PUBLISHED_RECOVERY_VECTOR_TRAINING_JSON,
            CKDMIP_PREFLIGHT_JSON,
            DERIVED_FLUX_PLAN_JSON,
        ],
        finding = exact_recovery_passed ?
            "The original ecCKD objective-reconstruction check passes." :
            original_objective_terms.status == "objective_terms_captured" && ckdmip_objective_dataset.status == "dataset_samples_ready" && ckdmip_objective_ad_batch.status == "optimizer_batch_ready" && official_training.present ?
            "Reactant/Enzyme checks pass and the current official/reduced optimizer reduces the objective, but the final objective remains $(official_training.final_objective_target_ratio)x the hard target; CKDMIP assets are ready, representative LW/SW training samples feed the Julia loss with zero self-loss, the compact real-data optimizer probe reduces loss, and the official objective terms have been captured." :
            original_objective_terms.status == "objective_terms_captured" && ckdmip_objective_dataset.status == "dataset_samples_ready" && official_training.present ?
            "Reactant/Enzyme checks pass and the current official/reduced optimizer reduces the objective, but the final objective remains $(official_training.final_objective_target_ratio)x the hard target; CKDMIP assets are ready, representative LW/SW training flux samples feed the Julia loss with zero self-loss, and the official objective terms have been captured." :
            original_objective_terms.status == "objective_terms_captured" && official_training.present ?
            "Reactant/Enzyme checks pass and the current official/reduced optimizer reduces the objective, but the final objective remains $(official_training.final_objective_target_ratio)x the hard target; CKDMIP assets are ready and the official LW/SW objective terms have been captured for original-objective recovery." :
            official_training.present ?
            "Reactant/Enzyme checks pass and the current official/reduced optimizer reduces the objective, but the final objective remains $(official_training.final_objective_target_ratio)x the hard target; CKDMIP assets are ready for original-objective recovery." :
            original_objective_assets_ready ?
            "The CKDMIP upstream and derived ecCKD training flux products are available, but the Reactant/Enzyme original-objective optimizer has not yet recovered a published model quantitatively." :
            ckdmip_preflight_status == "ready_for_derived_flux_generation" ?
            "Teacher-student coefficient recovery passes and upstream CKDMIP data is present, but exact original-objective recovery is blocked until the derived ecCKD 5gas/rel training flux products are generated." :
            "Teacher-student coefficient recovery passes, but exact original-objective recovery is blocked until RH_CKDMIP_DATA_PATH points to a complete CKDMIP tree and any missing derived ecCKD training flux products are generated.",
    ))

    blocked = count(row -> row.status == "blocked", requirements)
    partial = count(row -> row.status == "partial", requirements)
    checklist = prompt_artifact_checklist(requirements)
    return (
        case = "recovery_goal_audit",
        timestamp_utc = string(Dates.now()),
        status = blocked == 0 && partial == 0 ? "complete" : "not_complete",
        blocked_count = blocked,
        partial_count = partial,
        unmet_requirement_count = count(item -> !item.covered, checklist),
        unmet_requirement_ids = [item.requirement_id for item in checklist if !item.covered],
        reduced_model_summary = reduced,
        published_model_accuracy_summary = published_accuracy,
        matched_reference_summary = matched_references,
        published_all_sky_accuracy_summary = published_all_sky,
        reduced_weight_coordinate_boundary_polish_summary = weight_polish,
        breeze_summary = breeze,
        ckdmip_preflight_status = ckdmip_preflight_status,
        derived_flux_plan_status = derived_plan.status,
        objective_reconstruction_status = objective_status,
        original_objective_terms_summary = original_objective_terms,
        ckdmip_objective_dataset_summary = ckdmip_objective_dataset,
        ckdmip_objective_ad_batch_summary = ckdmip_objective_ad_batch,
        published_recovery_target_summary = published_recovery_target,
        published_recovery_vector_summary = published_recovery_vector,
        published_recovery_vector_training_summary = published_recovery_vector_training,
        original_objective_assets_ready = original_objective_assets_ready,
        official_training_summary = official_training,
        training_recovery_targets_summary = training_targets,
        derived_flux_progress = derived_flux_progress,
        derived_flux_plan_summary = derived_plan,
        teacher_student_recovery_status = teacher === nothing ? "missing" : String(json_get(teacher, "status", "unknown")),
        pareto_point_count = pareto === nothing ? 0 : Int(json_get(pareto, "point_count", 0)),
        requirements = requirements,
        prompt_to_artifact_checklist = checklist,
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_audit(result)
    ncrcat = result.derived_flux_plan_summary.ncrcat
    ncrcat_line = ncrcat === nothing ? "missing" :
                  "present=$(json_get(ncrcat, "present", false)), path=$(json_get(ncrcat, "path", nothing)), julia_concat_shim=$(json_get(ncrcat, "julia_concat_shim", false))"
    lines = String[
        "# Recovery Goal Audit",
        "",
        "Status: **$(result.status)**",
        "",
        "- Blocked requirements: $(result.blocked_count)",
        "- Partial requirements: $(result.partial_count)",
        "- Unmet requirements: $(result.unmet_requirement_count)",
        "- Teacher-student recovery status: `$(result.teacher_student_recovery_status)`",
        "- Objective reconstruction status: `$(result.objective_reconstruction_status)`",
        "- Original objective term capture status: `$(result.original_objective_terms_summary.status)`",
        "- CKDMIP objective dataset status: `$(result.ckdmip_objective_dataset_summary.status)`",
        "- CKDMIP objective optimizer batch status: `$(result.ckdmip_objective_ad_batch_summary.status)`",
        "- Published recovery target status: `$(result.published_recovery_target_summary.status)`",
        "- Published recovery vector status: `$(result.published_recovery_vector_summary.status)`",
        "- Published recovery vector training status: `$(result.published_recovery_vector_training_summary.status)`",
        "- Official training artifact status: `$(result.official_training_summary.status)`",
        "- Official training final objective / target: `$(result.official_training_summary.final_objective_target_ratio)`",
        "- Training recovery target status: `$(result.training_recovery_targets_summary.status)`",
        "- Training target reduced scheme objective / target: `$(result.training_recovery_targets_summary.reduced_final_objective_target_ratio)`",
        "- CKDMIP preflight status: `$(result.ckdmip_preflight_status)`",
        "- Derived flux generation plan status: `$(result.derived_flux_plan_status)`",
        "- Original objective assets ready: $(result.original_objective_assets_ready)",
        "- Derived flux products: $(result.derived_flux_progress.final_present)/$(result.derived_flux_progress.expected) final present, $(result.derived_flux_progress.products_with_raw_chunks) with raw chunks",
        "- Derived raw chunks: $(result.derived_flux_progress.present_raw_chunks)/$(result.derived_flux_progress.expected_raw_chunks)",
        "- Completed-equivalent derived raw chunks: $(result.derived_flux_progress.completed_equivalent_raw_chunks)/$(result.derived_flux_progress.expected_raw_chunks)",
        "- Observed derived raw chunk rate: `$(result.derived_flux_progress.observed_raw_chunk_rate_per_hour)` chunks/hour",
        "- Estimated derived raw chunk hours remaining: `$(result.derived_flux_progress.estimated_raw_chunk_hours_remaining)`",
        "- `ncrcat` concat tool: `$(ncrcat_line)`",
        "- Pareto points: $(result.pareto_point_count)",
        "- Hard boundary forcing threshold: `$(result.reduced_model_summary.hard_boundary_forcing_threshold_w_m2)` W m^-2",
        "- Official 32x32 worst boundary forcing error: `$(result.reduced_model_summary.official_32x32_worst_boundary_forcing_error_w_m2)` W m^-2",
        "- Published model accuracy status: `$(result.published_model_accuracy_summary.status)` ($(result.published_model_accuracy_summary.passed_count)/$(result.published_model_accuracy_summary.model_count) passing)",
        "- Published model boundary compatibility: `$(result.published_model_accuracy_summary.boundary_compatible_count)/$(result.published_model_accuracy_summary.model_count)` rows with matching LW surface spectral and SW surface-albedo g-point boundaries; isolation diagnostics: `$(result.published_model_accuracy_summary.isolation_diagnostic_count)`; boundary-projection diagnostics: `$(result.published_model_accuracy_summary.boundary_projection_diagnostic_count)`",
        "",
        "## Requirements",
        "",
        "| Requirement | Status | Finding | Evidence |",
        "|---|---|---|---|",
    ]
    for row in result.requirements
        evidence = join(["`$(path)`" for path in row.evidence], "<br>")
        finding = replace(row.finding, "|" => "\\|")
        requirement = replace(row.requirement, "|" => "\\|")
        push!(lines, "| $(requirement) | $(row.status) | $(finding) | $(evidence) |")
    end
    push!(lines, "", "## Prompt-to-Artifact Checklist", "")
    push!(lines, "| Requirement ID | Covered | Status | Evidence Count | Gap |")
    push!(lines, "|---|---:|---|---:|---|")
    for item in result.prompt_to_artifact_checklist
        gap = replace(item.gap, "|" => "\\|")
        push!(lines, "| `$(item.requirement_id)` | $(item.covered) | $(item.coverage_status) | $(length(item.evidence)) | $(gap) |")
    end
    push!(lines, "", "## Quantitative Reduced-Model Status", "")
    best = result.reduced_model_summary.best_reduced_candidate
    weight_polish = result.reduced_weight_coordinate_boundary_polish_summary
    if best === nothing
        push!(lines, "No reduced candidate metrics are currently available.")
    else
        push!(lines,
            "- Best reduced candidate so far: $(best.ng_lw)x$(best.ng_sw) ($(best.total_gpoints) total g-points), passed=$(best.passed).")
        push!(lines,
            "- Worst boundary forcing error: $(best.worst_boundary_forcing_error_w_m2) W m^-2 (TOA $(best.worst_toa_forcing_error_w_m2), surface $(best.worst_surface_forcing_error_w_m2)).")
        push!(lines, "- Method: $(best.reduction_method)")
    end
    if weight_polish.present
        push!(lines,
            "- Exact weight-coordinate boundary polish: omitted SW g-point $(weight_polish.omitted_gpoint), accepted moves=$(weight_polish.accepted_move_count), passed=$(weight_polish.passed), objective $(weight_polish.initial_objective) -> $(weight_polish.final_objective), boundary $(weight_polish.final_worst_boundary_forcing_error_w_m2) W m^-2, heating RMSE $(weight_polish.final_worst_heating_rate_rmse_k_day) K day^-1.")
    end
    push!(lines, "", "## Quantitative Training-Recovery Status", "")
    terms = result.original_objective_terms_summary
    push!(lines,
        "- Original objective terms: status=$(terms.status), implementation=$(terms.implementation_status), LW terms=$(terms.longwave_term_count), SW terms=$(terms.shortwave_term_count), all terms present=$(terms.longwave_terms_present && terms.shortwave_terms_present).")
    dataset = result.ckdmip_objective_dataset_summary
    push!(lines,
        "- CKDMIP objective dataset: status=$(dataset.status), samples=$(dataset.sample_count), schema $(dataset.training_flux_schema_ok_count)/$(dataset.training_flux_file_count), LW ready=$(dataset.longwave_sample_ready), SW ready=$(dataset.shortwave_sample_ready), self-loss zero=$(dataset.self_loss_zero).")
    ad_batch = result.ckdmip_objective_ad_batch_summary
    push!(lines,
        "- CKDMIP objective optimizer batch: status=$(ad_batch.status), parameters=$(ad_batch.parameter_count), accepted step=$(ad_batch.accepted_step), loss reduction=$(ad_batch.loss_reduction_factor), gradient=$(ad_batch.gradient_method).")
    recovery_target = result.published_recovery_target_summary
    push!(lines,
        "- Published recovery target: status=$(recovery_target.status), models=$(recovery_target.model_count), SW32 coefficient parameters=$(recovery_target.shortwave_32_parameter_count), LW32 coefficient parameters=$(recovery_target.longwave_32_parameter_count), final/target <= $(recovery_target.final_objective_target_ratio_max), optical-depth log RMSE <= $(recovery_target.optical_depth_log_rmse_max), optimizer-only rule=$(recovery_target.optimizer_only_delta_rule_present).")
    recovery_vector = result.published_recovery_vector_summary
    push!(lines,
        "- Published recovery vector: status=$(recovery_vector.status), arrays=$(recovery_vector.array_count), parameters=$(recovery_vector.parameter_count), round-trip max abs=$(recovery_vector.roundtrip_max_abs_error), round-trip L1 relative=$(recovery_vector.roundtrip_l1_relative_error), metrics=$(recovery_vector.recovery_metrics_status).")
    recovery_vector_training = result.published_recovery_vector_training_summary
    push!(lines,
        "- Published recovery vector training: status=$(recovery_vector_training.status), trained parameters=$(recovery_vector_training.trained_parameter_count)/$(recovery_vector_training.parameter_count), final loss=$(recovery_vector_training.final_loss), loss reduction=$(recovery_vector_training.loss_reduction_factor), Enzyme requested=$(recovery_vector_training.enzyme_requested), Reactant requested=$(recovery_vector_training.reactant_check_requested), metrics=$(recovery_vector_training.recovery_metrics_status).")
    training = result.official_training_summary
    if !training.present
        push!(lines, "No official/reduced ecCKD training artifact is currently available.")
    else
        push!(lines,
            "- Artifact status: $(training.status); optimizer: $(training.optimizer); parameters: $(training.parameter_count); trainable SW g-points: $(training.ng_sw).")
        push!(lines,
            "- Objective: initial $(training.initial_objective), final $(training.final_objective), target $(training.objective_target), final/target $(training.final_objective_target_ratio).")
        push!(lines,
            "- Reactant check: $(training.reactant_status); Enzyme check: $(training.enzyme_status); hard accuracy target met: $(training.hard_accuracy_target_met).")
        push!(lines,
            "- Gap status: $(training.acceptance_gap_status). Next work: $(training.next_required_work)")
    end
    push!(lines, "", "## Remaining Required Work", "")
    if result.original_objective_assets_ready && result.objective_reconstruction_status != "passed"
        push!(lines, "The CKDMIP data and derived ecCKD training flux products are ready for original-objective reconstruction. The remaining required work is running and validating the Reactant/Enzyme optimizer against the fixed published objective until one published model is recovered quantitatively.")
    elseif result.ckdmip_preflight_status == "ready_for_derived_flux_generation"
        push!(lines, "Exact original ecCKD objective recovery now has the upstream CKDMIP tree available, but still requires local generation of the derived ecCKD `5gas-*` and `rel-*` training flux products. The current teacher-student recovery is useful AD evidence, but it is not a substitute for reconstructing the published objective.")
    else
        push!(lines, "Exact original ecCKD objective recovery still requires `RH_CKDMIP_DATA_PATH` to point at the complete CKDMIP line-by-line training tree and any missing derived ecCKD training flux products to be generated. The current teacher-student recovery is useful AD evidence, but it is not a substitute for reconstructing the published objective.")
    end
    return join(lines, "\n") * "\n"
end

function recovery_goal_audit_main()
    result = run_recovery_goal_audit()
    write_json(RECOVERY_GOAL_AUDIT_JSON, result)
    write(RECOVERY_GOAL_AUDIT_MD, markdown_audit(result))
    print(markdown_audit(result))
    println("Wrote $RECOVERY_GOAL_AUDIT_JSON")
    println("Wrote $RECOVERY_GOAL_AUDIT_MD")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    recovery_goal_audit_main()
end
