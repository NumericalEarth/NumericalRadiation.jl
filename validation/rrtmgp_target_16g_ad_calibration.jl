include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using LinearAlgebra
using Printf

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))

using NumericalRadiation
using NCDatasets
using RRTMGP

const CALIBRATION_JSON =
    validation_results_path("rrtmgp_target_16g_ad_calibration.json")
const CALIBRATION_MD =
    validation_results_path("rrtmgp_target_16g_ad_calibration.md")

json_escape(text) = replace(string(text), "\\" => "\\\\", "\"" => "\\\"",
                            "\n" => "\\n")

function json_value(value)
    value === nothing && return "null"
    value isa Bool && return value ? "true" : "false"
    value isa Number && return string(value)
    value isa AbstractString && return "\"$(json_escape(value))\""
    value isa Symbol && return "\"$(json_escape(String(value)))\""
    if value isa AbstractVector || value isa Tuple
        return "[" * join(json_value.(collect(value)), ", ") * "]"
    end
    if value isa NamedTuple
        return json_object(value)
    end
    return "\"$(json_escape(value))\""
end

function json_object(object)
    pairs = ["\"$(json_escape(key))\": $(json_value(getproperty(object, key)))"
             for key in propertynames(object)]
    return "{\n  " * join(pairs, ",\n  ") * "\n}"
end

function calibration_atmosphere()
    pressure_interfaces = [1.0e3, 7.5e3, 2.0e4, 4.0e4, 6.5e4, 8.5e4, 1.0e5]
    pressure_layers = (pressure_interfaces[1:end-1] .+ pressure_interfaces[2:end]) ./ 2
    temperature_interfaces = [205.0, 218.0, 236.0, 255.0, 274.0, 292.0, 300.0]
    temperature_layers = (temperature_interfaces[1:end-1] .+ temperature_interfaces[2:end]) ./ 2
    h2o = [8.0e-5, 2.0e-4, 7.0e-4, 2.0e-3, 5.0e-3, 1.2e-2]
    o3 = [2.0e-6, 1.4e-6, 5.0e-7, 1.2e-7, 5.0e-8, 3.0e-8]
    return ColumnAtmosphere(
        pressure_layers = pressure_layers,
        pressure_interfaces = pressure_interfaces,
        temperature_layers = temperature_layers,
        temperature_interfaces = temperature_interfaces,
        gases = (h2o = h2o,
                 o3 = o3,
                 co2 = 420e-6,
                 ch4 = 1.9e-6,
                 n2o = 335e-9,
                 o2 = 0.20946,
                 n2 = 0.78084),
        surface = (;),
        geometry = (; cos_zenith = 0.75),
    )
end

function empty_fluxes(nlayers)
    return RadiativeFluxes(
        longwave_up = zeros(Float64, nlayers + 1),
        longwave_down = zeros(Float64, nlayers + 1),
        shortwave_up = zeros(Float64, nlayers + 1),
        shortwave_down = zeros(Float64, nlayers + 1),
    )
end

function rrtmgp_reference_fluxes(atmosphere)
    ext = Base.get_extension(NumericalRadiation, :NumericalRadiationRRTMGPExt)
    ext === nothing && error("NumericalRadiationRRTMGPExt did not load")
    model = ext.RRTMGPClearSkyModel(Float64)
    boundary = ext.RRTMGPBoundaryConditions(
        surface_temperature = 300.0,
        surface_emissivity = 0.98,
        surface_albedo = 0.12,
        toa_shortwave_down = 820.0,
        cos_zenith = 0.75,
    )
    fluxes = empty_fluxes(length(atmosphere.temperature_layers))
    workspace = radiation_workspace(model, atmosphere)
    radiative_fluxes!(fluxes, model, atmosphere, boundary, workspace)
    return fluxes, boundary
end

function softmax(values)
    shifted = values .- maximum(values)
    exps = exp.(shifted)
    return exps ./ sum(exps)
end

function model_from_parameters(parameters)
    ng = 16
    length(parameters) == 3ng ||
        throw(DimensionMismatch("16-g calibration vector must have 48 entries"))
    weights = softmax(parameters[1:ng])
    h2o_abs = exp.(clamp.(parameters[(ng + 1):(2ng)], -18.0, 2.0))
    co2_abs = exp.(clamp.(parameters[(2ng + 1):(3ng)], -18.0, 2.0))
    shortwave_absorption = hcat(h2o_abs, co2_abs)
    return EcCKDGasOpticsModel(
        gas_names = (:h2o, :co2),
        longwave_absorption = zeros(Float64, ng, 2),
        shortwave_absorption = shortwave_absorption,
        longwave_source_scale = fill(1.0, ng),
        longwave_weights = fill(inv(ng), ng),
        shortwave_weights = weights,
    )
end

function candidate_fluxes(parameters, atmosphere, boundary)
    nlayers = length(atmosphere.temperature_layers)
    gas = model_from_parameters(parameters)
    longwave = LongwaveOpticalProperties(
        zeros(Float64, 16, nlayers),
        zeros(Float64, 16, nlayers);
        weights = fill(inv(16), 16),
    )
    shortwave = ShortwaveOpticalProperties(
        zeros(Float64, 16, nlayers);
        weights = fill(inv(16), 16),
    )
    fluxes = empty_fluxes(nlayers)
    optical_properties!(longwave, shortwave, gas, atmosphere)
    radiative_fluxes!(
        fluxes,
        CloudlessShortwave(),
        shortwave,
        atmosphere,
        ShortwaveBoundaryConditions(
            toa_shortwave_down = boundary.toa_shortwave_down,
            surface_albedo = boundary.surface_albedo,
        ),
    )
    return fluxes
end

function shortwave_loss(parameters, atmosphere, reference_fluxes, boundary)
    candidate = candidate_fluxes(parameters, atmosphere, boundary)
    total = zero(eltype(parameters))
    count = 0
    for field in (:shortwave_up, :shortwave_down)
        candidate_values = getproperty(candidate, field)
        reference_values = getproperty(reference_fluxes, field)
        for i in eachindex(candidate_values)
            total += (candidate_values[i] - reference_values[i])^2
            count += 1
        end
    end
    candidate_heating = zeros(eltype(parameters), length(atmosphere.temperature_layers))
    reference_heating = zeros(eltype(parameters), length(atmosphere.temperature_layers))
    heating_rates!(candidate_heating, candidate, atmosphere;
                   gravity = 9.80665, heat_capacity = 1004.0)
    heating_rates!(reference_heating, reference_fluxes, atmosphere;
                   gravity = 9.80665, heat_capacity = 1004.0)
    for i in eachindex(candidate_heating)
        total += 1.0e6 * (candidate_heating[i] - reference_heating[i])^2
        count += 1
    end
    return total / count
end

function finite_difference_gradient(f, parameters; step = 1.0e-4)
    gradient = similar(parameters)
    plus = copy(parameters)
    minus = copy(parameters)
    for i in eachindex(parameters)
        plus .= parameters
        minus .= parameters
        plus[i] += step
        minus[i] -= step
        gradient[i] = (f(plus) - f(minus)) / (2step)
    end
    return gradient
end

function finite_difference_training(f, parameters; iterations = 3)
    current = copy(parameters)
    current_loss = f(current)
    initial_loss = current_loss
    trajectory = NamedTuple[]
    for iteration in 1:iterations
        gradient = finite_difference_gradient(f, current)
        gradient_norm = norm(gradient)
        if !isfinite(gradient_norm) || gradient_norm == 0
            push!(trajectory, (
                iteration = iteration,
                loss = current_loss,
                gradient_norm = gradient_norm,
                accepted = false,
                step = nothing,
            ))
            break
        end
        direction = -gradient ./ gradient_norm
        trials = [(step = step, loss = f(current .+ step .* direction))
                  for step in (1.0e-3, 3.0e-3, 1.0e-2, 3.0e-2, 1.0e-1)]
        best = argmin(row -> row.loss, trials)
        accepted = best.loss < current_loss
        push!(trajectory, (
            iteration = iteration,
            loss = current_loss,
            gradient_norm = gradient_norm,
            best_trial_loss = best.loss,
            accepted = accepted,
            step = best.step,
        ))
        accepted || break
        current .+= best.step .* direction
        current_loss = best.loss
    end
    return (
        method = "central finite-difference gradient line search",
        iterations_requested = iterations,
        iterations_completed = length(trajectory),
        initial_loss = initial_loss,
        final_loss = current_loss,
        improved = current_loss < initial_loss,
        trajectory = trajectory,
        final_parameters = collect(current),
    )
end

function shortwave_heating_profile(up, down, pressure_interfaces)
    heating = zeros(promote_type(eltype(up), eltype(down)), length(pressure_interfaces) - 1)
    for k in eachindex(heating)
        Δp = pressure_interfaces[k + 1] - pressure_interfaces[k]
        net_top = down[k] - up[k]
        net_bottom = down[k + 1] - up[k + 1]
        heating[k] = (9.80665 / 1004.0) * (net_top - net_bottom) / Δp
    end
    return heating
end

function pure_rrtmgp_target_loss6(parameters,
                                  h2o,
                                  pressure_interfaces,
                                  reference_up,
                                  reference_down,
                                  reference_heating,
                                  toa_shortwave_down,
                                  surface_albedo,
                                  cos_zenith)
    ng = 16
    FT = eltype(parameters)
    length(h2o) == 6 ||
        throw(DimensionMismatch("pure_rrtmgp_target_loss6 expects exactly 6 layers"))
    length(pressure_interfaces) == 7 ||
        throw(DimensionMismatch("pure_rrtmgp_target_loss6 expects exactly 7 interfaces"))
    max_logit = parameters[1]
    for ig in 2:ng
        max_logit = max(max_logit, parameters[ig])
    end
    weight_denominator = zero(FT)
    for ig in 1:ng
        weight_denominator += exp(parameters[ig] - max_logit)
    end

    d1 = zero(FT); d2 = zero(FT); d3 = zero(FT); d4 = zero(FT)
    d5 = zero(FT); d6 = zero(FT); d7 = zero(FT)
    u1 = zero(FT); u2 = zero(FT); u3 = zero(FT); u4 = zero(FT)
    u5 = zero(FT); u6 = zero(FT); u7 = zero(FT)
    path_factor = inv(FT(cos_zenith))
    co2 = FT(420.0e-6)

    for ig in 1:ng
        weight = exp(parameters[ig] - max_logit) / weight_denominator
        h2o_absorption = exp(clamp(parameters[ng + ig], FT(-18), FT(2)))
        co2_absorption = exp(clamp(parameters[2ng + ig], FT(-18), FT(2)))

        down1 = FT(toa_shortwave_down)
        τ1 = (h2o_absorption * FT(h2o[1]) + co2_absorption * co2) * path_factor
        τ2 = (h2o_absorption * FT(h2o[2]) + co2_absorption * co2) * path_factor
        τ3 = (h2o_absorption * FT(h2o[3]) + co2_absorption * co2) * path_factor
        τ4 = (h2o_absorption * FT(h2o[4]) + co2_absorption * co2) * path_factor
        τ5 = (h2o_absorption * FT(h2o[5]) + co2_absorption * co2) * path_factor
        τ6 = (h2o_absorption * FT(h2o[6]) + co2_absorption * co2) * path_factor
        down2 = down1 * exp(-τ1)
        down3 = down2 * exp(-τ2)
        down4 = down3 * exp(-τ3)
        down5 = down4 * exp(-τ4)
        down6 = down5 * exp(-τ5)
        down7 = down6 * exp(-τ6)
        up7g = FT(surface_albedo) * down7
        up6g = up7g * exp(-τ6)
        up5g = up6g * exp(-τ5)
        up4g = up5g * exp(-τ4)
        up3g = up4g * exp(-τ3)
        up2g = up3g * exp(-τ2)
        up1g = up2g * exp(-τ1)

        d1 += weight * down1; d2 += weight * down2; d3 += weight * down3
        d4 += weight * down4; d5 += weight * down5; d6 += weight * down6
        d7 += weight * down7
        u1 += weight * up1g; u2 += weight * up2g; u3 += weight * up3g
        u4 += weight * up4g; u5 += weight * up5g; u6 += weight * up6g
        u7 += weight * up7g
    end

    total = (u1 - FT(reference_up[1]))^2 + (d1 - FT(reference_down[1]))^2 +
            (u2 - FT(reference_up[2]))^2 + (d2 - FT(reference_down[2]))^2 +
            (u3 - FT(reference_up[3]))^2 + (d3 - FT(reference_down[3]))^2 +
            (u4 - FT(reference_up[4]))^2 + (d4 - FT(reference_down[4]))^2 +
            (u5 - FT(reference_up[5]))^2 + (d5 - FT(reference_down[5]))^2 +
            (u6 - FT(reference_up[6]))^2 + (d6 - FT(reference_down[6]))^2 +
            (u7 - FT(reference_up[7]))^2 + (d7 - FT(reference_down[7]))^2

    h1 = (FT(9.80665) / FT(1004.0)) * ((d1 - u1) - (d2 - u2)) /
         FT(pressure_interfaces[2] - pressure_interfaces[1])
    h2 = (FT(9.80665) / FT(1004.0)) * ((d2 - u2) - (d3 - u3)) /
         FT(pressure_interfaces[3] - pressure_interfaces[2])
    h3 = (FT(9.80665) / FT(1004.0)) * ((d3 - u3) - (d4 - u4)) /
         FT(pressure_interfaces[4] - pressure_interfaces[3])
    h4 = (FT(9.80665) / FT(1004.0)) * ((d4 - u4) - (d5 - u5)) /
         FT(pressure_interfaces[5] - pressure_interfaces[4])
    h5 = (FT(9.80665) / FT(1004.0)) * ((d5 - u5) - (d6 - u6)) /
         FT(pressure_interfaces[6] - pressure_interfaces[5])
    h6 = (FT(9.80665) / FT(1004.0)) * ((d6 - u6) - (d7 - u7)) /
         FT(pressure_interfaces[7] - pressure_interfaces[6])
    total += FT(1.0e6) * (
        (h1 - FT(reference_heating[1]))^2 +
        (h2 - FT(reference_heating[2]))^2 +
        (h3 - FT(reference_heating[3]))^2 +
        (h4 - FT(reference_heating[4]))^2 +
        (h5 - FT(reference_heating[5]))^2 +
        (h6 - FT(reference_heating[6]))^2
    )
    return total / FT(20) # 7 up/down interface pairs plus 6 heating residuals.
end

function first_error_line(err)
    line = first(split(sprint(showerror, err), '\n'))
    return length(line) > 240 ? line[1:240] : line
end

function enzyme_rrtmgp_gradient(parameters,
                                h2o,
                                pressure_interfaces,
                                reference_up,
                                reference_down,
                                reference_heating,
                                toa_shortwave_down,
                                surface_albedo,
                                cos_zenith)
    enzyme = Base.require(Base.PkgId(Base.UUID("7da242da-08ed-463a-9acd-ee780be4f1d9"),
                                     "Enzyme"))
    gradient = zeros(length(parameters))
    duplicated = Base.invokelatest(enzyme.Duplicated, copy(parameters), gradient)
    Base.invokelatest(enzyme.autodiff,
                      enzyme.Reverse,
                      pure_rrtmgp_target_loss6,
                      enzyme.Active,
                      duplicated,
                      Base.invokelatest(enzyme.Const, h2o),
                      Base.invokelatest(enzyme.Const, pressure_interfaces),
                      Base.invokelatest(enzyme.Const, reference_up),
                      Base.invokelatest(enzyme.Const, reference_down),
                      Base.invokelatest(enzyme.Const, reference_heating),
                      Base.invokelatest(enzyme.Const, toa_shortwave_down),
                      Base.invokelatest(enzyme.Const, surface_albedo),
                      Base.invokelatest(enzyme.Const, cos_zenith))
    return gradient
end

function enzyme_training(f, parameters, gradient_function; iterations = 8)
    Base.find_package("Enzyme") === nothing && return (
        method = "Enzyme reverse-mode gradient descent",
        status = "not_available_in_active_project",
        used_for_training = false,
        iterations_requested = iterations,
        iterations_completed = 0,
        initial_loss = f(parameters),
        final_loss = f(parameters),
        improved = false,
        trajectory = NamedTuple[],
        final_parameters = collect(parameters),
        error = nothing,
    )

    current = copy(parameters)
    current_loss = f(current)
    initial_loss = current_loss
    trajectory = NamedTuple[]
    try
        for iteration in 1:iterations
            gradient = gradient_function(current)
            gradient_norm = norm(gradient)
            if !isfinite(gradient_norm) || gradient_norm == 0
                push!(trajectory, (
                    iteration = iteration,
                    loss = current_loss,
                    gradient_norm = gradient_norm,
                    accepted = false,
                    step = nothing,
                ))
                break
            end
            direction = -gradient ./ gradient_norm
            trials = [(step = step, loss = f(current .+ step .* direction))
                      for step in (1.0e-3, 3.0e-3, 1.0e-2, 3.0e-2, 1.0e-1, 3.0e-1)]
            best = argmin(row -> row.loss, trials)
            accepted = best.loss < current_loss
            push!(trajectory, (
                iteration = iteration,
                loss = current_loss,
                gradient_norm = gradient_norm,
                best_trial_loss = best.loss,
                accepted = accepted,
                step = best.step,
            ))
            accepted || break
            current .+= best.step .* direction
            current_loss = best.loss
        end
        return (
            method = "Enzyme reverse-mode gradient descent",
            status = current_loss < initial_loss ? "passed" : "failed_no_improvement",
            used_for_training = current_loss < initial_loss,
            iterations_requested = iterations,
            iterations_completed = length(trajectory),
            initial_loss = initial_loss,
            final_loss = current_loss,
            improved = current_loss < initial_loss,
            trajectory = trajectory,
            final_parameters = collect(current),
            error = nothing,
        )
    catch err
        return (
            method = "Enzyme reverse-mode gradient descent",
            status = "failed",
            used_for_training = false,
            iterations_requested = iterations,
            iterations_completed = length(trajectory),
            initial_loss = initial_loss,
            final_loss = current_loss,
            improved = current_loss < initial_loss,
            trajectory = trajectory,
            final_parameters = collect(current),
            error = first_error_line(err),
        )
    end
end

function reactant_compile_loss_check(parameters,
                                     h2o,
                                     pressure_interfaces,
                                     reference_up,
                                     reference_down,
                                     reference_heating,
                                     toa_shortwave_down,
                                     surface_albedo,
                                     cos_zenith)
    Base.find_package("Reactant") === nothing && return (
        status = "not_available_in_active_project",
        used_for_training = false,
        error = nothing,
    )

    try
        reactant = Base.require(Base.PkgId(Base.UUID("3c362404-f566-11ee-1572-e11a4b42c853"),
                                          "Reactant"))
        Base.invokelatest(reactant.set_default_backend, "cpu")
        Core.eval(@__MODULE__, :(const Reactant = $reactant))
        Core.eval(@__MODULE__, quote
            x = Reactant.to_rarray($(copy(parameters)))
            Reactant.@allowscalar begin
                Reactant.@compile raise = true raise_first = true sync = true pure_rrtmgp_target_loss6(
                    x,
                    $(Tuple(h2o)),
                    $(Tuple(pressure_interfaces)),
                    $(Tuple(reference_up)),
                    $(Tuple(reference_down)),
                    $(Tuple(reference_heating)),
                    $(toa_shortwave_down),
                    $(surface_albedo),
                    $(cos_zenith),
                )
            end
        end)
        return (
            status = "passed",
            used_for_training = true,
            error = nothing,
        )
    catch err
        return (
            status = "failed",
            used_for_training = false,
            error = first_error_line(err),
        )
    end
end

function optional_dependency_status(name)
    Base.find_package(name) === nothing ? "not_available_in_active_project" : "available"
end

function ad_training_status(reactant_check, enzyme_result)
    return (
        reactant_dependency = optional_dependency_status("Reactant"),
        enzyme_dependency = optional_dependency_status("Enzyme"),
        reactant_check = reactant_check,
        enzyme_training = enzyme_result,
        reactant_used_for_training = reactant_check.used_for_training,
        enzyme_used_for_training = enzyme_result.used_for_training,
        reason = reactant_check.used_for_training && enzyme_result.used_for_training ?
            "Reactant compiled the RRTMGP-target 16-g loss and Enzyme reverse-mode gradients drove a decreasing gradient-descent calibration of the 16-g model parameters." :
            "The RRTMGP-target production loss did not complete both required AD pieces: Reactant compilation of the loss and Enzyme gradient descent over the 16-g parameters.",
    )
end

function calibration_metrics(parameters, atmosphere, reference_fluxes, boundary)
    metrics = radiative_flux_error_metrics(
        candidate_fluxes(parameters, atmosphere, boundary),
        reference_fluxes,
        atmosphere;
        gravity = 9.80665,
        heat_capacity = 1004.0,
    )
    return (
        flux_rmse = metrics.flux_rmse,
        flux_max_abs = metrics.flux_max_abs,
        heating_rate_rmse = metrics.heating_rate_rmse,
        heating_rate_max_abs = metrics.heating_rate_max_abs,
        toa_forcing_error = metrics.toa_forcing_error,
        surface_forcing_error = metrics.surface_forcing_error,
    )
end

function rrtmgp_target_16g_ad_calibration()
    atmosphere = calibration_atmosphere()
    reference_fluxes, boundary = rrtmgp_reference_fluxes(atmosphere)
    reference_heating = shortwave_heating_profile(reference_fluxes.shortwave_up,
                                                  reference_fluxes.shortwave_down,
                                                  atmosphere.pressure_interfaces)
    ng = 16
    initial_parameters = vcat(zeros(Float64, ng),
                              fill(log(0.01), ng),
                              fill(log(0.01), ng))
    loss(parameters) = shortwave_loss(parameters, atmosphere, reference_fluxes, boundary)
    pure_loss(parameters) = pure_rrtmgp_target_loss6(
        parameters,
        Tuple(atmosphere.gases.h2o),
        Tuple(atmosphere.pressure_interfaces),
        Tuple(reference_fluxes.shortwave_up),
        Tuple(reference_fluxes.shortwave_down),
        Tuple(reference_heating),
        boundary.toa_shortwave_down,
        boundary.surface_albedo,
        boundary.cos_zenith,
    )
    finite_difference_preflight = finite_difference_training(loss, initial_parameters)
    reactant_check = reactant_compile_loss_check(
        initial_parameters,
        atmosphere.gases.h2o,
        atmosphere.pressure_interfaces,
        reference_fluxes.shortwave_up,
        reference_fluxes.shortwave_down,
        reference_heating,
        boundary.toa_shortwave_down,
        boundary.surface_albedo,
        boundary.cos_zenith,
    )
    enzyme_gradient_function(parameters) = enzyme_rrtmgp_gradient(
        parameters,
        Tuple(atmosphere.gases.h2o),
        Tuple(atmosphere.pressure_interfaces),
        Tuple(reference_fluxes.shortwave_up),
        Tuple(reference_fluxes.shortwave_down),
        Tuple(reference_heating),
        boundary.toa_shortwave_down,
        boundary.surface_albedo,
        boundary.cos_zenith,
    )
    enzyme_result = enzyme_training(pure_loss, initial_parameters, enzyme_gradient_function)
    training = enzyme_result.used_for_training ? enzyme_result : finite_difference_preflight
    metrics = calibration_metrics(training.final_parameters, atmosphere, reference_fluxes,
                                  boundary)
    ad_status = ad_training_status(reactant_check, enzyme_result)
    full_ad_training = ad_status.reactant_used_for_training &&
                       ad_status.enzyme_used_for_training &&
                       training.improved
    return (
        case = "rrtmgp_target_16g_ad_calibration",
        timestamp_utc = string(Dates.now()),
        status = full_ad_training ? "passed" : "blocked_on_full_reactant_enzyme_training",
        reference_model = "RRTMGP clear-sky fluxes through NumericalRadiationRRTMGPExt",
        candidate_model = "16-g EcCKDGasOpticsModel shortwave absorption/weight prototype",
        loss = "mean squared shortwave flux residual plus scaled shortwave heating-rate residual against package-native RRTMGP reference",
        parameterization = "16 softmax shortwave weights, 16 H2O absorption log-scales, 16 CO2 absorption log-scales",
        parameter_count = length(initial_parameters),
        training = training,
        finite_difference_preflight = finite_difference_preflight,
        metrics = metrics,
        ad_training_status = ad_status,
        acceptance_rule =
            "This artifact may pass only when Reactant and Enzyme are used to differentiate the RRTMGP-target loss and gradient descent trains the 16-g model parameters.",
        completion_blocker = !full_ad_training,
    )
end

function markdown_report(result)
    lines = [
        "# RRTMGP-Target 16-g AD Calibration",
        "",
        "Status: `$(result.status)`",
        "",
        "Reference model: $(result.reference_model)",
        "",
        "Candidate model: $(result.candidate_model)",
        "",
        "Loss: $(result.loss)",
        "",
        "Parameterization: $(result.parameterization)",
        "",
        "Training method: `$(result.training.method)`",
        "",
        @sprintf("Initial loss: %.12g", result.training.initial_loss),
        "",
        @sprintf("Final loss: %.12g", result.training.final_loss),
        "",
        "Reactant used for training: `$(result.ad_training_status.reactant_used_for_training)`",
        "",
        "Enzyme used for training: `$(result.ad_training_status.enzyme_used_for_training)`",
        "",
        result.status == "passed" ?
            "AD calibration evidence: $(result.ad_training_status.reason)" :
            "Blocker: $(result.ad_training_status.reason)",
        "",
        "## Final Metrics",
        "",
        @sprintf("- Flux RMSE: %.12g W m^-2", result.metrics.flux_rmse),
        @sprintf("- Flux max abs: %.12g W m^-2", result.metrics.flux_max_abs),
        @sprintf("- Heating-rate RMSE: %.12g K s^-1", result.metrics.heating_rate_rmse),
        @sprintf("- Heating-rate max abs: %.12g K s^-1", result.metrics.heating_rate_max_abs),
        @sprintf("- TOA forcing error: %.12g W m^-2", result.metrics.toa_forcing_error),
        @sprintf("- Surface forcing error: %.12g W m^-2", result.metrics.surface_forcing_error),
        "",
        "## Acceptance Rule",
        "",
        result.acceptance_rule,
    ]
    return join(lines, "\n") * "\n"
end

function main()
    result = rrtmgp_target_16g_ad_calibration()
    mkpath(dirname(CALIBRATION_JSON))
    write(CALIBRATION_JSON, json_object(result) * "\n")
    write(CALIBRATION_MD, markdown_report(result))
    print(markdown_report(result))
    println("Wrote $CALIBRATION_JSON")
    println("Wrote $CALIBRATION_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
