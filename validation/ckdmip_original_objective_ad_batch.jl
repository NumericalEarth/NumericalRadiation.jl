include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using LinearAlgebra

include(joinpath(@__DIR__, "ckdmip_original_objective_dataset.jl"))

const CKDMIP_OBJECTIVE_AD_BATCH_JSON =
    validation_results_path("ckdmip_original_objective_ad_batch.json")
const CKDMIP_OBJECTIVE_AD_BATCH_MD =
    validation_results_path("ckdmip_original_objective_ad_batch.md")

function deterministic_flux_perturbation(n)
    return [0.01 * sin(0.37 * i) + 0.005 * cos(0.11 * i) for i in 1:n]
end

function compact_training_sample(sample; nlevel = 4, nband = 2)
    nlevel = min(nlevel, size(sample.flux_dn_true, 1))
    nband = min(nband, size(sample.flux_dn_true, 2))
    nlevel >= 2 || throw(ArgumentError("compact sample needs at least two flux levels"))
    nband >= 1 || throw(ArgumentError("compact sample needs at least one band"))
    nlevel <= size(sample.flux_dn_true, 1) ||
        throw(ArgumentError("nlevel exceeds available flux levels"))
    nband <= size(sample.flux_dn_true, 2) ||
        throw(ArgumentError("nband exceeds available bands"))
    pressure_hl = sample.pressure_hl[1:nlevel]
    flux_dn = sample.flux_dn_true[1:nlevel, 1:nband]
    flux_up = sample.flux_up_true[1:nlevel, 1:nband]
    heating = sample.kind == "longwave" ?
              ecckd_flux_heating_rate(pressure_hl, flux_dn, flux_up) :
              ecckd_flux_heating_rate(pressure_hl, flux_dn)
    return merge(sample, (
        pressure_hl = pressure_hl,
        layer_weight = ckdmip_layer_weight(pressure_hl),
        flux_dn_true = flux_dn,
        flux_up_true = flux_up,
        heating_rate_true = heating,
        band_wavenumber1 = sample.band_wavenumber1[1:nband],
        band_wavenumber2 = sample.band_wavenumber2[1:nband],
    ))
end

function split_corrections(parameters, dims)
    n = prod(dims)
    length(parameters) == 4n ||
        throw(DimensionMismatch("expected $(4n) parameters for two LW and two SW flux correction arrays"))
    index = 1
    lw_dn = reshape(parameters[index:(index + n - 1)], dims)
    index += n
    lw_up = reshape(parameters[index:(index + n - 1)], dims)
    index += n
    sw_dn = reshape(parameters[index:(index + n - 1)], dims)
    index += n
    sw_up = reshape(parameters[index:(index + n - 1)], dims)
    return lw_dn, lw_up, sw_dn, sw_up
end

function ckdmip_flux_correction_batch_loss(parameters, lw_sample, sw_sample;
                                          flux_profile_weight = 0.0,
                                          broadband_weight = 0.0)
    dims = size(lw_sample.flux_dn_true)
    size(sw_sample.flux_dn_true) == dims ||
        throw(DimensionMismatch("LW and SW samples must use matching compact flux shapes"))
    lw_dn_correction, lw_up_correction, sw_dn_correction, sw_up_correction =
        split_corrections(parameters, dims)
    lw_dn_fwd = lw_sample.flux_dn_true .+ lw_dn_correction
    lw_up_fwd = lw_sample.flux_up_true .+ lw_up_correction
    sw_dn_fwd = sw_sample.flux_dn_true .+ sw_dn_correction
    sw_up_fwd = sw_sample.flux_up_true .+ sw_up_correction

    lw_heating_fwd =
        ecckd_flux_heating_rate(lw_sample.pressure_hl, lw_dn_fwd, lw_up_fwd)
    sw_heating_fwd =
        ecckd_flux_heating_rate(sw_sample.pressure_hl, sw_dn_fwd)
    lw_loss = ecckd_lw_ckd_loss(;
        heating_rate_fwd = lw_heating_fwd,
        heating_rate_true = lw_sample.heating_rate_true,
        flux_dn_fwd = lw_dn_fwd,
        flux_up_fwd = lw_up_fwd,
        flux_dn_true = lw_sample.flux_dn_true,
        flux_up_true = lw_sample.flux_up_true,
        layer_weight = lw_sample.layer_weight,
        flux_weight = 0.2,
        flux_profile_weight,
        broadband_weight,
    )
    sw_loss = ecckd_sw_ckd_loss(;
        heating_rate_fwd = sw_heating_fwd,
        heating_rate_true = sw_sample.heating_rate_true,
        flux_dn_fwd = sw_dn_fwd,
        flux_up_fwd = sw_up_fwd,
        flux_dn_true = sw_sample.flux_dn_true,
        flux_up_true = sw_sample.flux_up_true,
        layer_weight = sw_sample.layer_weight,
        flux_weight = 0.4,
        flux_profile_weight,
        broadband_weight,
    )
    return lw_loss + sw_loss
end

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

function finite_difference_component(f, x, index; step = 1.0e-6)
    plus = copy(x)
    minus = copy(x)
    plus[index] += step
    minus[index] -= step
    return (f(plus) - f(minus)) / (2step)
end

function loss_reducing_step(f, x, gradient)
    initial_loss = f(x)
    gradient_norm2 = sum(abs2, gradient)
    gradient_norm2 > 0 || return (
        step = 0.0,
        final_loss = initial_loss,
        accepted = false,
    )
    step = 0.5 * initial_loss / gradient_norm2
    for _ in 1:24
        candidate = x .- step .* gradient
        final_loss = f(candidate)
        if isfinite(final_loss) && final_loss < initial_loss
            return (
                step = step,
                final_loss = final_loss,
                accepted = true,
            )
        end
        step *= 0.5
    end
    return (
        step = step,
        final_loss = initial_loss,
        accepted = false,
    )
end

function run_ckdmip_original_objective_ad_batch(; root = ckdmip_data_root(),
                                                column = 1,
                                                mu0_index = 1)
    if root === nothing
        return (
            case = "ckdmip_original_objective_ad_batch",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            ckdmip_data_root = nothing,
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    lw_path = joinpath(root, expected_flux_path("ckdmip_evaluation1_lw_fluxes_rel-415.h5"))
    sw_path = joinpath(root, expected_flux_path("ckdmip_evaluation1_sw_fluxes_rel-415.h5"))
    missing = [path for path in (lw_path, sw_path) if !isfile(path)]
    if !isempty(missing)
        return (
            case = "ckdmip_original_objective_ad_batch",
            timestamp_utc = string(Dates.now()),
            status = "missing_training_flux_sample",
            ckdmip_data_root = root,
            blockers = ["Missing training flux sample: $(path)" for path in missing],
        )
    end
    lw_sample = compact_training_sample(
        read_ckdmip_training_sample(lw_path; column, mu0_index),
    )
    sw_sample = compact_training_sample(
        read_ckdmip_training_sample(sw_path; column, mu0_index),
    )
    dims = size(lw_sample.flux_dn_true)
    parameters = deterministic_flux_perturbation(4prod(dims))
    f = p -> ckdmip_flux_correction_batch_loss(p, lw_sample, sw_sample)
    initial_loss = f(parameters)
    gradient = finite_difference_gradient(f, parameters)
    probe_index = max(1, length(parameters) ÷ 3)
    finite_difference = finite_difference_component(f, parameters, probe_index)
    gradient_error = abs(gradient[probe_index] - finite_difference) /
                     max(abs(finite_difference), eps(Float64))
    step = loss_reducing_step(f, parameters, gradient)
    status = step.accepted && gradient_error < 1.0e-5 ?
             "optimizer_batch_ready" : "optimizer_batch_failed"
    return (
        case = "ckdmip_original_objective_ad_batch",
        timestamp_utc = string(Dates.now()),
        status = status,
        ckdmip_data_root = root,
        lw_sample = lw_path,
        sw_sample = sw_path,
        column = column,
        mu0_index = mu0_index,
        flux_shape = collect(dims),
        parameter_count = length(parameters),
        initial_loss = initial_loss,
        final_loss = step.final_loss,
        accepted_step = step.accepted,
        step_size = step.step,
        loss_reduction_factor = initial_loss / max(step.final_loss, eps(Float64)),
        gradient_norm = norm(gradient),
        gradient_method = "central_finite_difference",
        finite_difference_probe_index = probe_index,
        finite_difference_gradient = finite_difference,
        batch_gradient = gradient[probe_index],
        finite_difference_relative_error = gradient_error,
        blockers = String[],
    )
end

function json_string(result)
    io = IOBuffer()
    JSON.print(io, result, 2)
    return String(take!(io))
end

function markdown_ad_batch(result)
    lines = String[
        "# CKDMIP Original Objective Optimizer Batch",
        "",
        "Status: **$(result.status)**",
        "",
        "CKDMIP data root: `$(result.ckdmip_data_root)`",
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
            "| Parameter count | $(result.parameter_count) |",
            "| Initial loss | $(result.initial_loss) |",
            "| Final loss after one accepted step | $(result.final_loss) |",
            "| Loss reduction factor | $(result.loss_reduction_factor) |",
            "| Gradient norm | $(result.gradient_norm) |",
            "| Finite-difference relative error | $(result.finite_difference_relative_error) |",
        ])
    end
    push!(lines, "", "This artifact uses real CKDMIP LW/SW rel-415 training samples and a compact original-objective flux-correction batch. It is an optimizer-readiness probe, not a published-model recovery; Enzyme coverage remains in `test/test_ecckd_original_objective_loss.jl`.")
    return join(lines, "\n") * "\n"
end

function main()
    result = run_ckdmip_original_objective_ad_batch()
    mkpath(dirname(CKDMIP_OBJECTIVE_AD_BATCH_JSON))
    write(CKDMIP_OBJECTIVE_AD_BATCH_JSON, json_string(result) * "\n")
    write(CKDMIP_OBJECTIVE_AD_BATCH_MD, markdown_ad_batch(result))
    print(markdown_ad_batch(result))
    println("Wrote $CKDMIP_OBJECTIVE_AD_BATCH_JSON")
    println("Wrote $CKDMIP_OBJECTIVE_AD_BATCH_MD")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
