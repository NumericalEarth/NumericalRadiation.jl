include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

include(joinpath(@__DIR__, "ecckd_published_recovery_vector.jl"))

const PUBLISHED_RECOVERY_VECTOR_TRAINING_JSON =
    validation_results_path("ecckd_published_recovery_vector_training.json")
const PUBLISHED_RECOVERY_VECTOR_TRAINING_MD =
    validation_results_path("ecckd_published_recovery_vector_training.md")
const PUBLISHED_RECOVERY_VECTOR_TRAINING_CANDIDATE =
    validation_results_path("ecckd_vector_trained_sw32_candidate.nc")

function log_parameterization(values)
    positive = [value for value in values if value > 0]
    ϵ = isempty(positive) ? eps(Float64) : max(minimum(positive) * 1.0e-12, eps(Float64))
    return log.(values .+ ϵ), ϵ
end

function deterministic_recovery_perturbation(target)
    return target .+ [0.03 * sin(0.011 * i) + 0.015 * cos(0.019 * i)
                      for i in eachindex(target)]
end

function vector_recovery_loss(parameters, target)
    total = zero(eltype(parameters))
    for i in eachindex(parameters)
        total += (parameters[i] - target[i])^2
    end
    return total / length(parameters)
end

function enzyme_vector_gradient(parameters, target)
    enzyme = Base.require(Base.PkgId(Base.UUID("7da242da-08ed-463a-9acd-ee780be4f1d9"),
                                     "Enzyme"))
    gradient = zeros(length(parameters))
    f(x) = vector_recovery_loss(x, target)
    duplicated = Base.invokelatest(enzyme.Duplicated, copy(parameters), gradient)
    Base.invokelatest(enzyme.autodiff, enzyme.Reverse, f, enzyme.Active, duplicated)
    return gradient
end

function analytic_vector_gradient(parameters, target)
    scale = 2 / length(parameters)
    return scale .* (parameters .- target)
end

first_error_line(err) = first(split(sprint(showerror, err), '\n'))

function reactant_vector_compile_check(parameters, target)
    Base.find_package("Reactant") === nothing && return (
        status = "not_available",
        passed = false,
        error = nothing,
    )
    try
        reactant = Base.require(Base.PkgId(Base.UUID("3c362404-f566-11ee-1572-e11a4b42c853"),
                                           "Reactant"))
        Base.invokelatest(reactant.set_default_backend, "cpu")
        Core.eval(@__MODULE__, :(const Reactant = $reactant))
        sample_count = min(length(parameters), 64)
        Core.eval(@__MODULE__, quote
            recovery_vector_loss(x, target) = sum(abs2, x .- target) / length(x)
            x = Reactant.to_rarray($(copy(parameters[1:sample_count])))
            target = Reactant.to_rarray($(copy(target[1:sample_count])))
            Reactant.@compile raise = true raise_first = true sync = true recovery_vector_loss(x, target)
        end)
        return (status = "passed", passed = true, error = nothing)
    catch err
        return (status = "failed", passed = false, error = first_error_line(err))
    end
end

function skipped_check(reason)
    return (
        status = "skipped",
        passed = false,
        error = reason,
    )
end

function gradient_descent_recover_vector(initial, target; iterations = 36, step_fraction = 0.35,
                                         use_enzyme = false)
    parameters = copy(initial)
    history = Float64[vector_recovery_loss(parameters, target)]
    enzyme_used = false
    step = step_fraction * length(parameters) / 2
    for _ in 1:iterations
        gradient = if use_enzyme
            enzyme_used = true
            enzyme_vector_gradient(parameters, target)
        else
            analytic_vector_gradient(parameters, target)
        end
        parameters .-= step .* gradient
        push!(history, vector_recovery_loss(parameters, target))
    end
    return parameters, history, enzyme_used
end

function write_log_vector_candidate(reference_path, candidate_path, log_parameters, shapes, ϵ)
    values = max.(exp.(log_parameters) .- ϵ, 0.0)
    return write_vector_candidate(reference_path, candidate_path, values, shapes)
end

function run_ecckd_published_recovery_vector_training(;
                                                       reference =
                                                           official_ecckd_definition_path(:shortwave_32),
                                                       candidate =
                                                           PUBLISHED_RECOVERY_VECTOR_TRAINING_CANDIDATE,
                                                       iterations = 36,
                                                       step_fraction = 0.35,
                                                       trained_parameter_count = 64,
                                                       use_enzyme = false,
                                                       run_reactant_check = false)
    names = vectorized_array_names(reference)
    target_values, shapes = flatten_recovery_arrays(reference, names)
    target, ϵ = log_parameterization(target_values)
    train_count = min(trained_parameter_count, length(target))
    train_slice = 1:train_count
    initial = deterministic_recovery_perturbation(target[train_slice])
    train_target = target[train_slice]
    reactant_check = run_reactant_check ?
        reactant_vector_compile_check(initial, train_target) :
        skipped_check("disabled for the default fast vector-training artifact")
    recovered, loss_history, enzyme_used =
        gradient_descent_recover_vector(initial, train_target; iterations, step_fraction,
                                        use_enzyme)
    recovered_full = copy(target)
    recovered_full[train_slice] .= recovered
    write_log_vector_candidate(reference, candidate, recovered_full, shapes, ϵ)
    recovered_values, _ = flatten_recovery_arrays(candidate, names)
    roundtrip_error = vector_roundtrip_error(target_values, recovered_values)
    metrics = recovery_metrics(reference, candidate)
    passed = metrics.status == "passed" &&
             roundtrip_error.l1_relative_error < 1.0e-6 &&
             (!use_enzyme || enzyme_used) &&
             (!run_reactant_check || reactant_check.passed)
    return (
        case = "ecckd_published_recovery_vector_training",
        timestamp_utc = string(Dates.now()),
        status = passed ? "passed" : "failed",
        reference_path = reference,
        candidate_path = candidate,
        array_count = length(names),
        parameter_count = length(target),
        trained_parameter_count = train_count,
        optimizer = use_enzyme ?
                    "Enzyme reverse-mode gradient descent in log vector space" :
                    "analytic quadratic gradient descent in log vector space",
        iterations = length(loss_history) - 1,
        initial_loss = first(loss_history),
        final_loss = last(loss_history),
        loss_reduction_factor = first(loss_history) / max(last(loss_history), eps(Float64)),
        enzyme_used_for_training = enzyme_used,
        enzyme_requested = use_enzyme,
        reactant_compile_check = reactant_check,
        reactant_check_requested = run_reactant_check,
        roundtrip_error = roundtrip_error,
        recovery_metrics = metrics,
        interpretation =
            "This trains a deterministic slice of the executable published-model handoff vector back to the SW32 published target while keeping the target arrays and metric definitions fixed, then writes a complete CKD-definition candidate. The default fast path uses an analytic gradient; Enzyme and Reactant checks are optional kwargs because the full AD compiler path is already covered elsewhere and is too slow for this vector handoff test. It is still a vector-recovery gate, not the full original CKDMIP flux objective.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_published_recovery_vector_training(result)
    lines = String[
        "# ecCKD Published Recovery Vector Training",
        "",
        "Status: **$(result.status)**",
        "",
        "Reference: `$(result.reference_path)`",
        "",
        "Candidate: `$(result.candidate_path)`",
        "",
        "| Metric | Value |",
        "|---|---:|",
        "| Arrays | $(result.array_count) |",
        "| Parameters | $(result.parameter_count) |",
        "| Trained parameters | $(result.trained_parameter_count) |",
        "| Optimizer | $(result.optimizer) |",
        "| Iterations | $(result.iterations) |",
        "| Initial loss | $(result.initial_loss) |",
        "| Final loss | $(result.final_loss) |",
        "| Loss reduction factor | $(result.loss_reduction_factor) |",
        "| Enzyme requested | $(result.enzyme_requested) |",
        "| Enzyme used for training | $(result.enzyme_used_for_training) |",
        "| Reactant check requested | $(result.reactant_check_requested) |",
        "| Reactant compile check | $(result.reactant_compile_check.status) |",
        "| Round-trip max abs error | $(result.roundtrip_error.max_abs_error) |",
        "| Round-trip L1 relative error | $(result.roundtrip_error.l1_relative_error) |",
        "| Recovery metrics status | $(result.recovery_metrics.status) |",
        "| Worst log-coefficient RMSE | $(result.recovery_metrics.worst_log_coefficient_rmse) |",
        "| Worst p99 relative coefficient error | $(result.recovery_metrics.worst_p99_relative_coefficient_error) |",
        "| G-point weight max abs error | $(result.recovery_metrics.gpoint_weight_max_abs_error) |",
        "",
        result.interpretation,
    ]
    return join(lines, "\n") * "\n"
end

function ecckd_published_recovery_vector_training_main()
    result = run_ecckd_published_recovery_vector_training()
    write_json(PUBLISHED_RECOVERY_VECTOR_TRAINING_JSON, result)
    write(PUBLISHED_RECOVERY_VECTOR_TRAINING_MD,
          markdown_published_recovery_vector_training(result))
    print(markdown_published_recovery_vector_training(result))
    println("Wrote $PUBLISHED_RECOVERY_VECTOR_TRAINING_JSON")
    println("Wrote $PUBLISHED_RECOVERY_VECTOR_TRAINING_MD")
    result.status == "passed" || error("ecCKD published recovery vector training failed")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_published_recovery_vector_training_main()
end
