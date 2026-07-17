include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using LinearAlgebra

include(joinpath(@__DIR__, "ecckd_candidate_transfer_smoke.jl"))

const CANDIDATE_TABLE_PARAMETER_PROBE_JSON =
    validation_results_path("ecckd_candidate_table_parameter_probe.json")
const CANDIDATE_TABLE_PARAMETER_PROBE_MD =
    validation_results_path("ecckd_candidate_table_parameter_probe.md")

function scaled_shortwave_table_model(model, log_parameters)
    h2o_scale = exp(log_parameters[1])
    co2_scale = exp(log_parameters[2])
    rayleigh_scale = exp(log_parameters[3])
    weight_scale = exp(log_parameters[4])

    shortwave_absorption = copy(model.shortwave_absorption)
    if size(shortwave_absorption, 2) >= 2
        shortwave_absorption[:, 2, :, :] .*= co2_scale
    end
    shortwave_h2o_absorption = copy(model.shortwave_h2o_absorption)
    !isempty(shortwave_h2o_absorption) && (shortwave_h2o_absorption .*= h2o_scale)
    rayleigh = copy(model.shortwave_rayleigh_molar_scattering)
    !isempty(rayleigh) && (rayleigh .*= rayleigh_scale)
    weights = copy(model.shortwave_weights)
    if !isempty(weights)
        weights .*= weight_scale
        total = sum(weights)
        total > 0 && (weights ./= total)
    end

    return EcCKDTabulatedGasOpticsModel(
        gas_names = NumericalRadiation.gas_names(model),
        pressure_grid = model.pressure_grid,
        temperature_grid = model.temperature_grid,
        h2o_mole_fraction_grid = model.h2o_mole_fraction_grid,
        gas_reference_mole_fractions = model.gas_reference_mole_fractions,
        longwave_absorption = model.longwave_absorption,
        shortwave_absorption = shortwave_absorption,
        longwave_h2o_absorption = model.longwave_h2o_absorption,
        shortwave_h2o_absorption = shortwave_h2o_absorption,
        shortwave_rayleigh_molar_scattering = rayleigh,
        longwave_source_scale = model.longwave_source_scale,
        longwave_source_temperature_grid = model.longwave_source_temperature_grid,
        longwave_source_table = model.longwave_source_table,
        longwave_weights = model.longwave_weights,
        shortwave_weights = weights,
    )
end

function shortwave_projected_table_loss(log_parameters, model, atmosphere, sw_sample,
                                        longwave_path, shortwave_path)
    scaled = scaled_shortwave_table_model(model, log_parameters)
    nlayers = length(atmosphere.temperature_layers)
    longwave = LongwaveOpticalProperties(
        zeros(size(scaled.longwave_absorption, 1), nlayers),
        zeros(size(scaled.longwave_absorption, 1), nlayers);
        weights = zeros(size(scaled.longwave_absorption, 1)),
    )
    shortwave = ShortwaveOpticalProperties(
        zeros(size(scaled.shortwave_absorption, 1), nlayers);
        rayleigh_optical_depth = zeros(size(scaled.shortwave_absorption, 1), nlayers),
        weights = zeros(size(scaled.shortwave_absorption, 1)),
    )
    optical_properties!(longwave, shortwave, scaled, atmosphere)
    dummy_lw_sample = merge(sw_sample, (
        kind = "longwave",
        flux_dn_true = zeros(size(sw_sample.flux_dn_true)),
        flux_up_true = zeros(size(sw_sample.flux_up_true)),
        heating_rate_true = zeros(size(sw_sample.heating_rate_true)),
    ))
    projected = projected_flux_arrays(
        longwave,
        shortwave,
        atmosphere,
        dummy_lw_sample,
        sw_sample,
        longwave_path,
        shortwave_path,
    )
    scores = projected_transfer_objective_scores(dummy_lw_sample, sw_sample, projected)
    scores.shortwave.loss === nothing && return Inf
    return scores.shortwave.loss
end

function table_probe_gradient(f, x; step = 1.0e-4)
    gradient = similar(x)
    plus = copy(x)
    minus = copy(x)
    for i in eachindex(x)
        plus .= x
        minus .= x
        plus[i] += step
        minus[i] -= step
        gradient[i] = (f(plus) - f(minus)) / (2step)
        isfinite(gradient[i]) || (gradient[i] = 0.0)
    end
    return gradient
end

function table_probe_descent_step(f, x, gradient; initial_step = 1.0e-3)
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
        candidate = clamp.(x .- step .* gradient, -2.0, 2.0)
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

function run_table_parameter_probe(; root = ckdmip_data_root(),
                                   candidate_path = VECTOR_TRAINING_CANDIDATE,
                                   column = 1,
                                   mu0_index = 1)
    if root === nothing
        return (
            case = "ecckd_candidate_table_parameter_probe",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    sw_path = joinpath(root, expected_flux_path("ckdmip_evaluation1_sw_fluxes_rel-415.h5"))
    missing = [path for path in (sw_path, candidate_path) if !isfile(path)]
    if !isempty(missing)
        return (
            case = "ecckd_candidate_table_parameter_probe",
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
    sw_sample = read_ckdmip_training_sample(sw_path; column, mu0_index)
    f = p -> shortwave_projected_table_loss(p, model, atmosphere, sw_sample,
                                            longwave_path, candidate_path)
    initial_parameters = zeros(Float64, 4)
    initial_loss = f(initial_parameters)
    gradient = table_probe_gradient(f, initial_parameters)
    step = table_probe_descent_step(f, initial_parameters, gradient)
    final_loss = min(step.loss, initial_loss)
    accepted = step.accepted && final_loss < initial_loss
    loss_reduction = initial_loss / max(final_loss, eps(Float64))
    return (
        case = "ecckd_candidate_table_parameter_probe",
        timestamp_utc = string(Dates.now()),
        status = accepted ? "table_parameter_probe_passed" :
                 "table_parameter_probe_failed",
        candidate_path = candidate_path,
        column = column,
        mu0 = mu0,
        parameter_names = [
            "shortwave_h2o_absorption_log_scale",
            "shortwave_co2_absorption_log_scale",
            "shortwave_rayleigh_log_scale",
            "shortwave_weight_common_log_scale",
        ],
        parameter_count = length(initial_parameters),
        initial_loss = initial_loss,
        final_loss = final_loss,
        accepted_step = accepted,
        step_size = step.step,
        loss_reduction_factor = loss_reduction,
        gradient_method = "central_finite_difference_on_in_memory_ckd_table_scales",
        gradient_norm = norm(gradient),
        final_log_parameters = collect(step.parameters),
        blockers = String[],
        interpretation =
            "This optimizes four real in-memory ecCKD shortwave table multipliers against the candidate-driven projected CKDMIP-band loss. It is a table-parameter optimizer probe, not a full CKD-definition writeback or published-model recovery.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_table_parameter_probe(result)
    lines = String[
        "# ecCKD Candidate Table-Parameter Probe",
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
            "| Initial SW projected loss | $(result.initial_loss) |",
            "| Final SW projected loss | $(result.final_loss) |",
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

function ecckd_candidate_table_parameter_probe_main()
    result = run_table_parameter_probe()
    write_json(CANDIDATE_TABLE_PARAMETER_PROBE_JSON, result)
    write(CANDIDATE_TABLE_PARAMETER_PROBE_MD, markdown_table_parameter_probe(result))
    print(markdown_table_parameter_probe(result))
    println("Wrote $CANDIDATE_TABLE_PARAMETER_PROBE_JSON")
    println("Wrote $CANDIDATE_TABLE_PARAMETER_PROBE_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_candidate_table_parameter_probe_main()
end
