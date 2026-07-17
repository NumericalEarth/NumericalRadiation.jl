include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

include(joinpath(@__DIR__, "ckdmip_original_objective_dataset.jl"))
include(joinpath(@__DIR__, "ecckd_recovery_metrics.jl"))

const CANDIDATE_OBJECTIVE_SCORE_JSON =
    validation_results_path("ecckd_candidate_original_objective_score.json")
const CANDIDATE_OBJECTIVE_SCORE_MD =
    validation_results_path("ecckd_candidate_original_objective_score.md")
const VECTOR_TRAINING_CANDIDATE =
    validation_results_path("ecckd_vector_trained_sw32_candidate.nc")

function candidate_forward_loss(sample; flux_dn_fwd, flux_up_fwd,
                                flux_profile_weight = 0.0,
                                broadband_weight = 0.0)
    if sample.kind == "longwave"
        heating_fwd = ecckd_flux_heating_rate(sample.pressure_hl, flux_dn_fwd, flux_up_fwd)
        return ecckd_lw_ckd_loss(;
            heating_rate_fwd = heating_fwd,
            heating_rate_true = sample.heating_rate_true,
            flux_dn_fwd = flux_dn_fwd,
            flux_up_fwd = flux_up_fwd,
            flux_dn_true = sample.flux_dn_true,
            flux_up_true = sample.flux_up_true,
            layer_weight = sample.layer_weight,
            flux_weight = 0.2,
            flux_profile_weight,
            broadband_weight,
        )
    elseif sample.kind == "shortwave"
        heating_fwd = ecckd_flux_heating_rate(sample.pressure_hl, flux_dn_fwd)
        return ecckd_sw_ckd_loss(;
            heating_rate_fwd = heating_fwd,
            heating_rate_true = sample.heating_rate_true,
            flux_dn_fwd = flux_dn_fwd,
            flux_up_fwd = flux_up_fwd,
            flux_dn_true = sample.flux_dn_true,
            flux_up_true = sample.flux_up_true,
            layer_weight = sample.layer_weight,
            flux_weight = 0.4,
            flux_profile_weight,
            broadband_weight,
        )
    end
    throw(ArgumentError("unknown sample kind $(sample.kind)"))
end

function deterministic_forward_perturbation(dims)
    return reshape([0.001 * sin(0.23 * i) + 0.0005 * cos(0.17 * i)
                    for i in 1:prod(dims)], dims)
end

function sample_objective_score(sample)
    zero_loss = candidate_forward_loss(
        sample,
        flux_dn_fwd = sample.flux_dn_true,
        flux_up_fwd = sample.flux_up_true,
    )
    perturbation = deterministic_forward_perturbation(size(sample.flux_dn_true))
    perturbed_loss = candidate_forward_loss(
        sample,
        flux_dn_fwd = sample.flux_dn_true .+ perturbation,
        flux_up_fwd = sample.flux_up_true .- perturbation,
    )
    return (
        kind = sample.kind,
        nlayer = size(sample.heating_rate_true, 1),
        nband = size(sample.heating_rate_true, 2),
        zero_forward_loss = zero_loss,
        perturbed_forward_loss = perturbed_loss,
        loss_increases_under_perturbation = perturbed_loss > zero_loss,
    )
end

function candidate_recovery_metrics(candidate_path)
    if !isfile(candidate_path)
        return (
            present = false,
            status = "missing",
            worst_log_coefficient_rmse = nothing,
            gpoint_weight_max_abs_error = nothing,
        )
    end
    metrics = recovery_metrics(official_ecckd_definition_path(:shortwave_32), candidate_path)
    return (
        present = true,
        status = metrics.status,
        worst_log_coefficient_rmse = metrics.worst_log_coefficient_rmse,
        gpoint_weight_max_abs_error = metrics.gpoint_weight_max_abs_error,
    )
end

function run_ecckd_candidate_original_objective_score(; root = ckdmip_data_root(),
                                                       candidate_path =
                                                           VECTOR_TRAINING_CANDIDATE,
                                                       column = 1,
                                                       mu0_index = 1)
    if root === nothing
        return (
            case = "ecckd_candidate_original_objective_score",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            candidate_path = candidate_path,
            candidate_metrics = candidate_recovery_metrics(candidate_path),
            sample_scores = NamedTuple[],
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    lw_path = joinpath(root, expected_flux_path("ckdmip_evaluation1_lw_fluxes_rel-415.h5"))
    sw_path = joinpath(root, expected_flux_path("ckdmip_evaluation1_sw_fluxes_rel-415.h5"))
    missing = [path for path in (lw_path, sw_path) if !isfile(path)]
    if !isempty(missing)
        return (
            case = "ecckd_candidate_original_objective_score",
            timestamp_utc = string(Dates.now()),
            status = "missing_training_flux_sample",
            candidate_path = candidate_path,
            candidate_metrics = candidate_recovery_metrics(candidate_path),
            sample_scores = NamedTuple[],
            blockers = ["Missing training flux sample: $(path)" for path in missing],
        )
    end
    lw_sample = read_ckdmip_training_sample(lw_path; column, mu0_index)
    sw_sample = read_ckdmip_training_sample(sw_path; column, mu0_index)
    scores = sample_objective_score.((lw_sample, sw_sample))
    candidate_metrics = candidate_recovery_metrics(candidate_path)
    passed = candidate_metrics.status == "passed" &&
             all(score -> score.zero_forward_loss == 0.0, scores) &&
             all(score -> score.loss_increases_under_perturbation, scores)
    return (
        case = "ecckd_candidate_original_objective_score",
        timestamp_utc = string(Dates.now()),
        status = passed ? "candidate_objective_score_ready" :
                 "candidate_objective_score_failed",
        candidate_path = candidate_path,
        candidate_metrics = candidate_metrics,
        sample_scores = scores,
        blockers = String[],
        remaining_gap =
            "This scores supplied forward flux/heating arrays against CKDMIP samples. The remaining heavy step is replacing the identity/perturbed forward arrays with differentiable transfer computed from the CKD-definition candidate.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function json_string(result)
    io = IOBuffer()
    JSON.print(io, result, 2)
    return String(take!(io))
end

function markdown_candidate_objective_score(result)
    lines = String[
        "# ecCKD Candidate Original-Objective Score",
        "",
        "Status: **$(result.status)**",
        "",
        "Candidate: `$(result.candidate_path)`",
        "",
        "Candidate recovery metrics status: `$(result.candidate_metrics.status)`",
        "",
        "## Blockers",
        "",
    ]
    if isempty(result.blockers)
        push!(lines, "None.")
    else
        append!(lines, ["- $(blocker)" for blocker in result.blockers])
    end
    if !isempty(result.sample_scores)
        append!(lines, [
            "",
            "## Sample Objective Scores",
            "",
            "| Kind | Layers | Bands | Zero-forward loss | Perturbed-forward loss | Perturbation increases loss |",
            "|---|---:|---:|---:|---:|---:|",
        ])
        for row in result.sample_scores
            push!(lines, "| $(row.kind) | $(row.nlayer) | $(row.nband) | $(row.zero_forward_loss) | $(row.perturbed_forward_loss) | $(row.loss_increases_under_perturbation) |")
        end
    end
    hasproperty(result, :remaining_gap) && push!(lines, "", result.remaining_gap)
    return join(lines, "\n") * "\n"
end

function ecckd_candidate_original_objective_score_main()
    result = run_ecckd_candidate_original_objective_score()
    write_json(CANDIDATE_OBJECTIVE_SCORE_JSON, result)
    write(CANDIDATE_OBJECTIVE_SCORE_MD, markdown_candidate_objective_score(result))
    print(markdown_candidate_objective_score(result))
    println("Wrote $CANDIDATE_OBJECTIVE_SCORE_JSON")
    println("Wrote $CANDIDATE_OBJECTIVE_SCORE_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_candidate_original_objective_score_main()
end
