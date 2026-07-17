include(joinpath(@__DIR__, "validation_results.jl"))

using NumericalRadiation
using Dates
using LinearAlgebra: norm
using Printf
using Statistics

const TARGET_PARAMETERS = [0.14, 0.006, 0.020, 0.0009]
const INITIAL_PARAMETERS = [0.07, 0.003, 0.010, 0.0004]
const PURE_LOSS_H2O = (0.0015, 0.006, 0.018)
const PURE_LOSS_CO2 = 420.0e-6
const PURE_LOSS_TEMPERATURE = (230.0, 262.0, 290.0)
const PURE_LOSS_SURFACE_TEMPERATURE = 300.0
const STEFAN_BOLTZMANN = 5.670374419e-8
const TRAINING_ITERATIONS = 12
const GRADIENT_STEP = 1.0e-5
const GRADIENT_CHECK_STEP = 5.0e-6
const INITIAL_LINE_SEARCH_STEP = 0.5
const MINIMUM_LINE_SEARCH_STEP = 1.0e-8
const DETERMINISTIC_SEED = "none_deterministic_fixture"

function optional_package_status(name)
    path = Base.find_package(name)
    return path === nothing ? "not_available_in_active_project" : "available_but_not_exercised"
end

function first_error_line(err)
    line = first(split(sprint(showerror, err), '\n'))
    return length(line) > 240 ? line[1:240] : line
end

function toy_atmosphere()
    pressure_interfaces = [1_000.0, 25_000.0, 60_000.0, 100_000.0]
    pressure_layers = [13_000.0, 42_500.0, 80_000.0]
    temperature_interfaces = [215.0, 245.0, 278.0, 300.0]
    temperature_layers = [230.0, 262.0, 290.0]
    return ColumnAtmosphere(
        pressure_layers = pressure_layers,
        pressure_interfaces = pressure_interfaces,
        temperature_layers = temperature_layers,
        temperature_interfaces = temperature_interfaces,
        gases = (
            h2o = [0.0015, 0.006, 0.018],
            co2 = 420.0e-6,
        ),
        surface = (; temperature = 300.0, albedo = 0.08),
        geometry = (; cos_zenith = 0.5),
    )
end

function gas_model(parameters)
    lw_h2o, lw_co2, sw_h2o, sw_co2 = parameters
    return EcCKDGasOpticsModel(
        gas_names = (:h2o, :co2),
        longwave_absorption = [
            lw_h2o       lw_co2
            0.55lw_h2o   1.70lw_co2
            0.25lw_h2o   0.60lw_co2
        ],
        shortwave_absorption = [
            sw_h2o       sw_co2
            0.45sw_h2o   2.00sw_co2
        ],
        longwave_source_scale = [0.95, 1.0, 1.08],
        longwave_weights = [0.25, 0.45, 0.30],
        shortwave_weights = [0.65, 0.35],
    )
end

function forward(parameters)
    atmosphere = toy_atmosphere()
    model = gas_model(parameters)
    nlayers = length(atmosphere.temperature_layers)

    longwave = LongwaveOpticalProperties(zeros(3, nlayers), zeros(3, nlayers);
                                         weights = zeros(3))
    shortwave = ShortwaveOpticalProperties(zeros(2, nlayers); weights = zeros(2))
    fluxes = RadiativeFluxes(
        longwave_up = zeros(nlayers + 1),
        longwave_down = zeros(nlayers + 1),
        shortwave_up = zeros(nlayers + 1),
        shortwave_down = zeros(nlayers + 1),
    )
    heating = zeros(nlayers)

    optical_properties!(longwave, shortwave, model, atmosphere)
    radiative_fluxes!(
        fluxes,
        CloudlessLongwave(),
        longwave,
        atmosphere,
        LongwaveBoundaryConditions(
            surface_longwave_up = 5.670374419e-8 * atmosphere.surface.temperature^4,
        ),
    )
    radiative_fluxes!(
        fluxes,
        CloudlessShortwave(),
        shortwave,
        atmosphere,
        ShortwaveBoundaryConditions(
            toa_shortwave_down = 1361.0 * atmosphere.geometry.cos_zenith,
            surface_albedo = atmosphere.surface.albedo,
        ),
    )
    heating_rates!(heating, fluxes, atmosphere; gravity = 9.80665, heat_capacity = 1004.0)

    flux_vector = vcat(fluxes.longwave_up,
                       fluxes.longwave_down,
                       fluxes.shortwave_up,
                       fluxes.shortwave_down)
    return (; flux = flux_vector, heating_day = heating .* 86_400)
end

function loss(parameters, reference)
    prediction = forward(parameters)
    flux_error = prediction.flux .- reference.flux
    heating_error = prediction.heating_day .- reference.heating_day
    return mean(abs2, flux_error) + 0.01 * mean(abs2, heating_error)
end

function prediction_metrics(parameters, reference)
    prediction = forward(parameters)
    flux_error = prediction.flux .- reference.flux
    heating_error = prediction.heating_day .- reference.heating_day
    return (
        flux_rmse = sqrt(mean(abs2, flux_error)),
        flux_max_error = maximum(abs, flux_error),
        heating_rate_rmse_k_day = sqrt(mean(abs2, heating_error)),
        heating_rate_max_error_k_day = maximum(abs, heating_error),
    )
end

function finite_difference_gradient(f, parameters; step = 1.0e-5)
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

function train(reference; iterations = TRAINING_ITERATIONS)
    parameters = copy(INITIAL_PARAMETERS)
    losses = Float64[]
    f(x) = loss(x, reference)

    for _ in 1:iterations
        push!(losses, f(parameters))
        gradient = finite_difference_gradient(f, parameters; step = GRADIENT_STEP)
        step = INITIAL_LINE_SEARCH_STEP
        accepted = false
        while step > MINIMUM_LINE_SEARCH_STEP
            candidate = max.(parameters .- step .* gradient, 1.0e-9)
            if f(candidate) < losses[end]
                parameters .= candidate
                accepted = true
                break
            end
            step *= 0.5
        end
        accepted || break
    end

    push!(losses, f(parameters))
    return (; parameters, losses)
end

function relative_gradient_difference(g1, g2)
    return norm(g1 .- g2) / max(norm(g2), eps(eltype(g2)))
end

function pure_twostream_flux(parameters)
    lw_h2o, lw_co2, sw_h2o, sw_co2 = parameters
    h2o1, h2o2, h2o3 = PURE_LOSS_H2O
    T1, T2, T3 = PURE_LOSS_TEMPERATURE

    τ1 = lw_h2o * h2o1 + lw_co2 * PURE_LOSS_CO2
    τ2 = lw_h2o * h2o2 + lw_co2 * PURE_LOSS_CO2
    τ3 = lw_h2o * h2o3 + lw_co2 * PURE_LOSS_CO2
    S1 = STEFAN_BOLTZMANN * T1^4
    S2 = STEFAN_BOLTZMANN * T2^4
    S3 = STEFAN_BOLTZMANN * T3^4

    up3 = STEFAN_BOLTZMANN * PURE_LOSS_SURFACE_TEMPERATURE^4
    up2 = up3 * exp(-τ3) + S3 * (1 - exp(-τ3))
    up1 = up2 * exp(-τ2) + S2 * (1 - exp(-τ2))
    up0 = up1 * exp(-τ1) + S1 * (1 - exp(-τ1))

    down0 = 0.0
    down1 = down0 * exp(-τ1) + S1 * (1 - exp(-τ1))
    down2 = down1 * exp(-τ2) + S2 * (1 - exp(-τ2))
    down3 = down2 * exp(-τ3) + S3 * (1 - exp(-τ3))

    τsw1 = sw_h2o * h2o1 + sw_co2 * PURE_LOSS_CO2
    τsw2 = sw_h2o * h2o2 + sw_co2 * PURE_LOSS_CO2
    τsw3 = sw_h2o * h2o3 + sw_co2 * PURE_LOSS_CO2
    sw0 = 680.5
    sw1 = sw0 * exp(-τsw1)
    sw2 = sw1 * exp(-τsw2)
    sw3 = sw2 * exp(-τsw3)

    return (up0, up1, up2, up3, down0, down1, down2, down3, sw0, sw1, sw2, sw3)
end

const PURE_LOSS_TARGET_FLUX = pure_twostream_flux(TARGET_PARAMETERS)

function pure_twostream_loss(parameters)
    flux = pure_twostream_flux(parameters)
    total = zero(eltype(parameters))
    for i in eachindex(flux)
        total += (flux[i] - PURE_LOSS_TARGET_FLUX[i])^2
    end
    return total / length(flux)
end

function enzyme_gradient_check(reference)
    Base.find_package("Enzyme") === nothing && return (
        status = "not_available_in_active_project",
        check = "pure_two_stream_radiative_loss",
        relative_error = nothing,
        threshold = 1.0e-4,
        passed = false,
        error = nothing,
    )

    try
        enzyme = Base.require(Base.PkgId(Base.UUID("7da242da-08ed-463a-9acd-ee780be4f1d9"), "Enzyme"))
        parameters = copy(INITIAL_PARAMETERS)
        enzyme_gradient = zeros(length(parameters))
        f(x) = pure_twostream_loss(x)
        duplicated = Base.invokelatest(enzyme.Duplicated, parameters, enzyme_gradient)
        Base.invokelatest(enzyme.autodiff,
                          enzyme.Reverse,
                          f,
                          enzyme.Active,
                          duplicated)
        finite_difference = finite_difference_gradient(f, INITIAL_PARAMETERS)
        relative_error = relative_gradient_difference(enzyme_gradient, finite_difference)
        threshold = 1.0e-4
        return (
            status = relative_error <= threshold ? "passed" : "failed",
            check = "pure_two_stream_radiative_loss",
            relative_error = relative_error,
            threshold = threshold,
            passed = relative_error <= threshold,
            error = nothing,
        )
    catch err
        return (
            status = "failed",
            check = "pure_two_stream_radiative_loss",
            relative_error = nothing,
            threshold = 1.0e-4,
            passed = false,
            error = first_error_line(err),
        )
    end
end

function reactant_compile_check()
    Base.find_package("Reactant") === nothing && return (
        status = "not_available_in_active_project",
        passed = false,
        error = nothing,
    )

    try
        reactant = Base.require(Base.PkgId(Base.UUID("3c362404-f566-11ee-1572-e11a4b42c853"), "Reactant"))
        initial = copy(INITIAL_PARAMETERS)
        target_parameters = copy(TARGET_PARAMETERS)
        Base.invokelatest(reactant.set_default_backend, "cpu")
        Core.eval(@__MODULE__, :(const Reactant = $reactant))
        Core.eval(@__MODULE__, quote
            quadratic_loss(x, target) = sum(abs2, x .- target)
            x = Reactant.to_rarray($initial)
            target = Reactant.to_rarray($target_parameters)
            Reactant.@compile raise = true raise_first = true sync = true quadratic_loss(x, target)
        end)
        return (
            status = "passed",
            passed = true,
            error = nothing,
        )
    catch err
        return (
            status = "failed",
            passed = false,
            error = first_error_line(err),
        )
    end
end

function json_value(value)
    if value === nothing
        return "null"
    elseif value isa AbstractString
        return "\"" * replace(value, "\"" => "\\\"") * "\""
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value isa NamedTuple
        return json_object(value)
    elseif value isa AbstractVector
        return "[" * join(json_value.(value), ", ") * "]"
    else
        return string(value)
    end
end

function json_object(result)
    names = propertynames(result)
    lines = ["{"]
    for (i, name) in enumerate(names)
        comma = i == length(names) ? "" : ","
        push!(lines, "  \"$(name)\": $(json_value(getproperty(result, name)))$(comma)")
    end
    push!(lines, "}")
    return join(lines, "\n")
end

function markdown_report(result)
    return """
    # Toy ecCKD Training

    Status: **$(result.passed ? "pass" : "fail")**

    This is a deterministic reduced gas-optics training fixture. It exercises
    loss construction, finite-difference gradient consistency, and loss
    reduction for fixed-topology ecCKD-style parameters. It is not a CKDMIP
    production training run. When Enzyme and Reactant are available in the
    active environment, it also checks an Enzyme gradient through a pure
    two-stream radiative loss and Reactant compilation of a toy loss. The full
    mutating radiative-transfer training path is still open.

    | Metric | Value |
    |---|---:|
    | Initial loss | $(@sprintf("%.12g", result.initial_loss)) |
    | Final loss | $(@sprintf("%.12g", result.final_loss)) |
    | Loss ratio | $(@sprintf("%.12g", result.loss_ratio)) |
    | Initial flux RMSE | $(@sprintf("%.12g", result.initial_metrics.flux_rmse)) W m^-2 |
    | Final flux RMSE | $(@sprintf("%.12g", result.final_metrics.flux_rmse)) W m^-2 |
    | Flux RMSE ratio | $(@sprintf("%.12g", result.flux_rmse_ratio)) |
    | Initial heating RMSE | $(@sprintf("%.12g", result.initial_metrics.heating_rate_rmse_k_day)) K day^-1 |
    | Final heating RMSE | $(@sprintf("%.12g", result.final_metrics.heating_rate_rmse_k_day)) K day^-1 |
    | Heating RMSE ratio | $(@sprintf("%.12g", result.heating_rate_rmse_ratio)) |
    | Gradient relative difference | $(@sprintf("%.12g", result.gradient_relative_difference)) |
    | Gradient threshold | $(@sprintf("%.12g", result.gradient_relative_difference_threshold)) |
    | Enzyme status | $(result.enzyme_check.status) |
    | Enzyme check | $(result.enzyme_check.check) |
    | Enzyme relative error | $(result.enzyme_check.relative_error === nothing ? "not measured" : @sprintf("%.12g", result.enzyme_check.relative_error)) |
    | Reactant status | $(result.reactant_check.status) |

    Initial parameters: `$(result.initial_parameters)`

    Final parameters: `$(result.final_parameters)`

    Target parameters: `$(result.target_parameters)`

    Configuration: `$(result.configuration)`
    """
end

function main()
    reference = forward(TARGET_PARAMETERS)
    f(x) = loss(x, reference)
    gradient_a = finite_difference_gradient(f, INITIAL_PARAMETERS; step = GRADIENT_STEP)
    gradient_b = finite_difference_gradient(f, INITIAL_PARAMETERS; step = GRADIENT_CHECK_STEP)
    gradient_error = relative_gradient_difference(gradient_a, gradient_b)
    training = train(reference)
    enzyme_check = enzyme_gradient_check(reference)
    reactant_check = reactant_compile_check()

    initial_loss = first(training.losses)
    final_loss = last(training.losses)
    initial_metrics = prediction_metrics(INITIAL_PARAMETERS, reference)
    final_metrics = prediction_metrics(training.parameters, reference)
    flux_rmse_ratio = final_metrics.flux_rmse / initial_metrics.flux_rmse
    heating_rate_rmse_ratio =
        final_metrics.heating_rate_rmse_k_day / initial_metrics.heating_rate_rmse_k_day
    gradient_threshold = 1.0e-4
    passed = final_loss < initial_loss &&
             flux_rmse_ratio < 1 &&
             heating_rate_rmse_ratio < 1 &&
             gradient_error <= gradient_threshold
    configuration = (
        deterministic_seed = DETERMINISTIC_SEED,
        iterations = TRAINING_ITERATIONS,
        gradient_step = GRADIENT_STEP,
        gradient_check_step = GRADIENT_CHECK_STEP,
        initial_line_search_step = INITIAL_LINE_SEARCH_STEP,
        minimum_line_search_step = MINIMUM_LINE_SEARCH_STEP,
        loss_flux_weight = 1.0,
        loss_heating_rate_weight = 0.01,
        atmosphere = (
            pressure_layers_pa = toy_atmosphere().pressure_layers,
            pressure_interfaces_pa = toy_atmosphere().pressure_interfaces,
            temperature_layers_k = toy_atmosphere().temperature_layers,
            h2o = toy_atmosphere().gases.h2o,
            co2 = toy_atmosphere().gases.co2,
            surface_temperature_k = toy_atmosphere().surface.temperature,
            surface_albedo = toy_atmosphere().surface.albedo,
            cos_zenith = toy_atmosphere().geometry.cos_zenith,
        ),
    )

    result = (
        case = "toy_ecckd_fixed_topology_training",
        date = string(Dates.now()),
        passed = passed,
        initial_parameters = INITIAL_PARAMETERS,
        final_parameters = training.parameters,
        target_parameters = TARGET_PARAMETERS,
        initial_loss = initial_loss,
        final_loss = final_loss,
        loss_ratio = final_loss / initial_loss,
        initial_metrics = initial_metrics,
        final_metrics = final_metrics,
        flux_rmse_ratio = flux_rmse_ratio,
        heating_rate_rmse_ratio = heating_rate_rmse_ratio,
        loss_history = training.losses,
        gradient_relative_difference = gradient_error,
        gradient_relative_difference_threshold = gradient_threshold,
        enzyme_check = enzyme_check,
        reactant_check = reactant_check,
        configuration = configuration,
        notes = "Finite-difference training fixture is always run; Enzyme/Reactant checks run only when those packages are available. Full radiative-transfer Enzyme differentiation remains open.",
    )

    results_dir = validation_results_dir()
    mkpath(results_dir)
    write(joinpath(results_dir, "toy_ecckd_training.json"), json_object(result))
    write(joinpath(results_dir, "toy_ecckd_training.md"), markdown_report(result))

    println("Toy ecCKD training: $(passed ? "pass" : "fail")")
    println("initial loss: $(@sprintf("%.12g", initial_loss))")
    println("final loss: $(@sprintf("%.12g", final_loss))")
    println("flux RMSE ratio: $(@sprintf("%.12g", flux_rmse_ratio))")
    println("heating-rate RMSE ratio: $(@sprintf("%.12g", heating_rate_rmse_ratio))")
    println("gradient relative difference: $(@sprintf("%.12g", gradient_error))")
    passed || error("toy ecCKD training failed")
end

main()
