include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using LinearAlgebra

include(joinpath(@__DIR__, "ecckd_candidate_transfer_smoke.jl"))

const CANDIDATE_TRANSFER_OPTIMIZER_PROBE_JSON =
    validation_results_path("ecckd_candidate_transfer_optimizer_probe.json")
const CANDIDATE_TRANSFER_OPTIMIZER_PROBE_MD =
    validation_results_path("ecckd_candidate_transfer_optimizer_probe.md")

function scaled_longwave_optics(optics, log_parameters)
    tau_scale = exp(log_parameters[1])
    source_scale = exp(log_parameters[2])
    source_top = optics.source_top === nothing ? nothing :
                 source_scale .* optics.source_top
    source_bottom = optics.source_bottom === nothing ? nothing :
                    source_scale .* optics.source_bottom
    return LongwaveOpticalProperties(
        tau_scale .* optics.optical_depth,
        source_scale .* optics.source;
        source_top,
        source_bottom,
        weights = optics.weights,
    )
end

function scaled_shortwave_optics(optics, log_parameters)
    tau_scale = exp(log_parameters[3])
    rayleigh_scale = exp(log_parameters[4])
    return ShortwaveOpticalProperties(
        tau_scale .* optics.optical_depth;
        rayleigh_optical_depth = rayleigh_scale .* optics.rayleigh_optical_depth,
        scattering_asymmetry = optics.scattering_asymmetry,
        weights = optics.weights,
    )
end

function transfer_probe_loss(log_parameters, longwave, shortwave, atmosphere,
                             lw_sample, sw_sample, longwave_path, shortwave_path)
    scaled_lw = scaled_longwave_optics(longwave, log_parameters)
    scaled_sw = scaled_shortwave_optics(shortwave, log_parameters)
    projected = projected_flux_arrays(
        scaled_lw,
        scaled_sw,
        atmosphere,
        lw_sample,
        sw_sample,
        longwave_path,
        shortwave_path,
    )
    scores = projected_transfer_objective_scores(lw_sample, sw_sample, projected)
    scores.longwave.loss === nothing && return Inf
    scores.shortwave.loss === nothing && return Inf
    return scores.longwave.loss + scores.shortwave.loss
end

function finite_difference_gradient(f, x; step = 1.0e-4)
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

function accepted_descent_step(f, x, gradient; initial_step = 1.0e-3)
    initial_loss = f(x)
    gradient_norm2 = sum(abs2, gradient)
    isfinite(initial_loss) && gradient_norm2 > 0 || return (
        accepted = false,
        step = 0.0,
        loss = initial_loss,
        parameters = copy(x),
    )
    step = initial_step
    for _ in 1:24
        candidate = x .- step .* gradient
        loss = f(candidate)
        if isfinite(loss) && loss < initial_loss
            return (
                accepted = true,
                step = step,
                loss = loss,
                parameters = candidate,
            )
        end
        step *= 0.5
    end
    return (
        accepted = false,
        step = step,
        loss = initial_loss,
        parameters = copy(x),
    )
end

function run_transfer_optimizer_probe(; root = ckdmip_data_root(),
                                      candidate_path = VECTOR_TRAINING_CANDIDATE,
                                      column = 1,
                                      mu0_index = 1)
    if root === nothing
        return (
            case = "ecckd_candidate_transfer_optimizer_probe",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    lw_path = joinpath(root, expected_flux_path("ckdmip_evaluation1_lw_fluxes_rel-415.h5"))
    sw_path = joinpath(root, expected_flux_path("ckdmip_evaluation1_sw_fluxes_rel-415.h5"))
    missing = [path for path in (lw_path, sw_path, candidate_path) if !isfile(path)]
    if !isempty(missing)
        return (
            case = "ecckd_candidate_transfer_optimizer_probe",
            timestamp_utc = string(Dates.now()),
            status = "missing_input",
            blockers = ["Missing input: $(path)" for path in missing],
        )
    end
    sw_dataset = NCDataset(sw_path)
    mu0 = try
        Float64(sw_dataset["mu0"][mu0_index])
    finally
        close(sw_dataset)
    end
    atmosphere = ckdmip_column_atmosphere(sw_path; column, mu0)
    longwave_path = official_ecckd_definition_path(:longwave_32)
    model = read_ecckd_tabulated_gas_optics(
        longwave_path,
        candidate_path;
        gas_names = (:h2o, :co2),
    )
    lw_sample = read_ckdmip_training_sample(lw_path; column, mu0_index)
    sw_sample = read_ckdmip_training_sample(sw_path; column, mu0_index)
    longwave, shortwave, _ = transfer_flux_arrays(model, atmosphere, lw_sample, sw_sample)
    f = p -> transfer_probe_loss(p, longwave, shortwave, atmosphere,
                                 lw_sample, sw_sample, longwave_path, candidate_path)
    initial_parameters = zeros(Float64, 4)
    initial_loss = f(initial_parameters)
    gradient = finite_difference_gradient(f, initial_parameters)
    step = accepted_descent_step(f, initial_parameters, gradient)
    final_loss = min(step.loss, initial_loss)
    accepted = step.accepted && final_loss < initial_loss
    loss_reduction = initial_loss / max(final_loss, eps(Float64))
    status = accepted && loss_reduction > 1 ? "optimizer_probe_passed" :
             "optimizer_probe_failed"
    return (
        case = "ecckd_candidate_transfer_optimizer_probe",
        timestamp_utc = string(Dates.now()),
        status = status,
        candidate_path = candidate_path,
        column = column,
        mu0 = mu0,
        parameter_names = [
            "longwave_optical_depth_log_scale",
            "longwave_source_log_scale",
            "shortwave_optical_depth_log_scale",
            "shortwave_rayleigh_log_scale",
        ],
        parameter_count = length(initial_parameters),
        initial_loss = initial_loss,
        final_loss = final_loss,
        accepted_step = accepted,
        step_size = step.step,
        loss_reduction_factor = loss_reduction,
        gradient_method = "central_finite_difference_on_band_projected_transfer_loss",
        gradient_norm = norm(gradient),
        final_log_parameters = collect(step.parameters),
        blockers = String[],
        interpretation =
            "This optimizes four global log-scale transfer parameters against the candidate-driven, g-point-to-CKDMIP-band projected original-objective loss. It is an optimizer probe for the transfer path, not a published CKD-definition recovery.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_transfer_optimizer_probe(result)
    lines = String[
        "# ecCKD Candidate Transfer Optimizer Probe",
        "",
        "Status: **$(result.status)**",
        "",
        "## Blockers",
        "",
    ]
    if isempty(result.blockers)
        push!(lines, "None.")
    else
        append!(lines, ["- $(blocker)" for blocker in result.blockers])
    end
    if hasproperty(result, :parameter_count)
        append!(lines, [
            "",
            "## Optimizer Probe",
            "",
            "| Metric | Value |",
            "|---|---:|",
            "| Parameters | $(result.parameter_count) |",
            "| Initial projected loss | $(result.initial_loss) |",
            "| Final projected loss | $(result.final_loss) |",
            "| Loss reduction factor | $(result.loss_reduction_factor) |",
            "| Accepted step | $(result.accepted_step) |",
            "| Step size | $(result.step_size) |",
            "| Gradient method | $(result.gradient_method) |",
            "| Gradient norm | $(result.gradient_norm) |",
            "",
            result.interpretation,
        ])
    end
    return join(lines, "\n") * "\n"
end

function ecckd_candidate_transfer_optimizer_probe_main()
    result = run_transfer_optimizer_probe()
    write_json(CANDIDATE_TRANSFER_OPTIMIZER_PROBE_JSON, result)
    write(CANDIDATE_TRANSFER_OPTIMIZER_PROBE_MD,
          markdown_transfer_optimizer_probe(result))
    print(markdown_transfer_optimizer_probe(result))
    println("Wrote $CANDIDATE_TRANSFER_OPTIMIZER_PROBE_JSON")
    println("Wrote $CANDIDATE_TRANSFER_OPTIMIZER_PROBE_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_candidate_transfer_optimizer_probe_main()
end
