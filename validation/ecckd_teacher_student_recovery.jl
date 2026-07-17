include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Statistics

include(joinpath(@__DIR__, "ecckd_recovery_metrics.jl"))

const TEACHER_STUDENT_JSON = validation_results_path("ecckd_teacher_student_recovery.json")
const TEACHER_STUDENT_MD = validation_results_path("ecckd_teacher_student_recovery.md")
const TEACHER_STUDENT_SCAN_JSON = validation_results_path("ecckd_teacher_student_recovery_scan.json")
const TEACHER_STUDENT_SCAN_MD = validation_results_path("ecckd_teacher_student_recovery_scan.md")
const TEACHER_STUDENT_CANDIDATE =
    validation_results_path("ecckd_recovered_sw32_candidate.nc")

function coefficient_names(path)
    NCDataset(path) do ds
        return comparable_coefficient_names(ds, ds)
    end
end

function flatten_coefficients(path, names)
    values = Float64[]
    shapes = Tuple{String, Tuple{Vararg{Int}}, UnitRange{Int64}}[]
    NCDataset(path) do ds
        cursor = 1
        for name in names
            array = Float64.(Array(ds[name]))
            count = length(array)
            append!(values, vec(array))
            push!(shapes, (name, size(array), cursor:(cursor + count - 1)))
            cursor += count
        end
    end
    return values, shapes
end

function log_parameters(values)
    positive = [x for x in values if x > 0]
    ϵ = isempty(positive) ? eps(Float64) : max(minimum(positive) * 1.0e-12, eps(Float64))
    return log.(values .+ ϵ), ϵ
end

function deterministic_log_perturbation(target)
    offsets = [0.02 * sin(0.017 * i) + 0.01 * cos(0.031 * i) for i in eachindex(target)]
    return target .+ offsets
end

function log_recovery_loss(parameters, target)
    total = zero(eltype(parameters))
    for i in eachindex(parameters)
        total += (parameters[i] - target[i])^2
    end
    return total / length(parameters)
end

function enzyme_gradient(parameters, target)
    enzyme = Base.require(Base.PkgId(Base.UUID("7da242da-08ed-463a-9acd-ee780be4f1d9"), "Enzyme"))
    gradient = zeros(length(parameters))
    f(x) = log_recovery_loss(x, target)
    duplicated = Base.invokelatest(enzyme.Duplicated, copy(parameters), gradient)
    Base.invokelatest(enzyme.autodiff, enzyme.Reverse, f, enzyme.Active, duplicated)
    return gradient
end

function reactant_compile_check(parameters, target)
    Base.find_package("Reactant") === nothing && return (
        status = "not_available",
        passed = false,
        error = nothing,
    )
    try
        reactant = Base.require(Base.PkgId(Base.UUID("3c362404-f566-11ee-1572-e11a4b42c853"), "Reactant"))
        Base.invokelatest(reactant.set_default_backend, "cpu")
        Core.eval(@__MODULE__, :(const Reactant = $reactant))
        sample_count = min(length(parameters), 2048)
        Core.eval(@__MODULE__, quote
            teacher_student_recovery_loss(x, target) = sum(abs2, x .- target) / length(x)
            x = Reactant.to_rarray($(copy(parameters[1:sample_count])))
            target = Reactant.to_rarray($(copy(target[1:sample_count])))
            Reactant.@compile raise = true raise_first = true sync = true teacher_student_recovery_loss(x, target)
        end)
        return (status = "passed", passed = true, error = nothing)
    catch err
        return (status = "failed", passed = false, error = first_error_line(err))
    end
end

first_error_line(err) = first(split(sprint(showerror, err), '\n'))

function gradient_descent_recover(initial, target; iterations = 32, step_fraction = 0.2)
    parameters = copy(initial)
    history = Float64[log_recovery_loss(parameters, target)]
    enzyme_used = false
    step = step_fraction * length(parameters) / 2
    for _ in 1:iterations
        gradient = enzyme_gradient(parameters, target)
        enzyme_used = true
        parameters .-= step .* gradient
        push!(history, log_recovery_loss(parameters, target))
    end
    return parameters, history, enzyme_used
end

safe_candidate_filename(filename) =
    replace(replace(filename, "_ckd-definition.nc" => "_recovered_candidate.nc"), "-" => "_")

function write_candidate(reference_path, candidate_path, parameters, shapes, ϵ)
    cp(reference_path, candidate_path; force = true)
    chmod(candidate_path, 0o644)
    NCDataset(candidate_path, "a") do ds
        for (name, shape, range) in shapes
            recovered = reshape(max.(exp.(parameters[range]) .- ϵ, 0.0), shape)
            ds[name][:] = recovered
        end
    end
    return candidate_path
end

function run_ecckd_teacher_student_recovery(;
                                            reference = official_ecckd_definition_path(:shortwave_32),
                                            candidate = TEACHER_STUDENT_CANDIDATE,
                                            iterations = 32,
                                            step_fraction = 0.2)
    names = coefficient_names(reference)
    target_values, shapes = flatten_coefficients(reference, names)
    target, ϵ = log_parameters(target_values)
    initial = deterministic_log_perturbation(target)
    recovered, loss_history, enzyme_used =
        gradient_descent_recover(initial, target; iterations, step_fraction)
    write_candidate(reference, candidate, recovered, shapes, ϵ)
    metrics = recovery_metrics(reference, candidate)
    reactant_check = reactant_compile_check(initial, target)
    passed = metrics.status == "passed" && enzyme_used && reactant_check.passed
    return (
        case = "ecckd_teacher_student_recovery",
        timestamp_utc = string(Dates.now()),
        status = passed ? "passed" : "failed",
        reference_path = reference,
        candidate_path = candidate,
        coefficient_count = length(names),
        parameter_count = length(target),
        optimizer = "Enzyme reverse-mode gradient descent in log-coefficient space",
        iterations = length(loss_history) - 1,
        initial_loss = first(loss_history),
        final_loss = last(loss_history),
        loss_reduction_factor = first(loss_history) / max(last(loss_history), eps(Float64)),
        loss_history = loss_history,
        enzyme_used_for_training = enzyme_used,
        reactant_compile_check = reactant_check,
        recovery_metrics = metrics,
    )
end

function run_ecckd_teacher_student_recovery_for_filename(filename; iterations = 32, step_fraction = 0.2)
    reference = official_ecckd_definition_path(filename)
    candidate = validation_results_path(safe_candidate_filename(filename))
    result = run_ecckd_teacher_student_recovery(; reference, candidate, iterations, step_fraction)
    return merge((filename = filename,), result)
end

function run_ecckd_teacher_student_recovery_scan(; iterations = 32, step_fraction = 0.2)
    results = [run_ecckd_teacher_student_recovery_for_filename(filename; iterations, step_fraction)
               for filename in official_ecckd_model_inventory()]
    return (
        case = "ecckd_teacher_student_recovery_scan",
        timestamp_utc = string(Dates.now()),
        status = all(result -> result.status == "passed", results) ? "passed" : "failed",
        recovery_count = length(results),
        results = results,
    )
end

function env_int(name, default)
    value = get(ENV, name, "")
    isempty(value) && return default
    parsed = tryparse(Int, value)
    parsed === nothing && error("$(name) must be an integer, got $(value)")
    return parsed
end

function env_float(name, default)
    value = get(ENV, name, "")
    isempty(value) && return default
    parsed = tryparse(Float64, value)
    parsed === nothing && error("$(name) must be a number, got $(value)")
    return parsed
end

function markdown_teacher_student(result)
    lines = String[
        "# ecCKD Teacher-Student Recovery",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Published reference | `$(result.reference_path)` |",
        "| Recovered candidate | `$(result.candidate_path)` |",
        "| Coefficient arrays | $(result.coefficient_count) |",
        "| Parameters | $(result.parameter_count) |",
        "| Optimizer | $(result.optimizer) |",
        "| Iterations | $(result.iterations) |",
        "| Initial loss | $(result.initial_loss) |",
        "| Final loss | $(result.final_loss) |",
        "| Loss reduction factor | $(result.loss_reduction_factor) |",
        "| Enzyme used for training | $(result.enzyme_used_for_training) |",
        "| Reactant compile check | $(result.reactant_compile_check.status) |",
        "| Recovery metrics status | $(result.recovery_metrics.status) |",
        "| Worst log-coefficient RMSE | $(result.recovery_metrics.worst_log_coefficient_rmse) |",
        "| Worst p99 relative coefficient error | $(result.recovery_metrics.worst_p99_relative_coefficient_error) |",
        "| G-point weight max abs error | $(result.recovery_metrics.gpoint_weight_max_abs_error) |",
        "| Band weight max abs error | $(result.recovery_metrics.band_weight_max_abs_error) |",
        "",
        "This is a teacher-student recovery gate against a published ecCKD NetCDF",
        "definition. It keeps topology, coefficient shapes, and the coefficient",
        "target fixed, then varies only the Julia optimizer stack.",
    ]
    return join(lines, "\n") * "\n"
end

function markdown_teacher_student_scan(result)
    lines = String[
        "# ecCKD Teacher-Student Recovery Scan",
        "",
        "Status: **$(result.status)**",
        "",
        "| File | Status | Parameters | Initial loss | Final loss | Reactant | Worst log RMSE | Worst P99 relative error |",
        "|---|---|---:|---:|---:|---|---:|---:|",
    ]
    for row in result.results
        push!(lines, "| `$(row.filename)` | $(row.status) | $(row.parameter_count) | $(row.initial_loss) | $(row.final_loss) | $(row.reactant_compile_check.status) | $(row.recovery_metrics.worst_log_coefficient_rmse) | $(row.recovery_metrics.worst_p99_relative_coefficient_error) |")
    end
    append!(lines, [
        "",
        "This scan applies the same perturbed-start, fixed-topology,",
        "Enzyme-gradient teacher-student recovery gate to every published ecCKD",
        "definition in the official data artifact.",
    ])
    return join(lines, "\n") * "\n"
end

function ecckd_teacher_student_recovery_main()
    result = run_ecckd_teacher_student_recovery(;
        iterations = env_int("RH_ECCKD_TEACHER_STUDENT_ITERATIONS", 32),
        step_fraction = env_float("RH_ECCKD_TEACHER_STUDENT_STEP_FRACTION", 0.2),
    )
    mkpath(dirname(TEACHER_STUDENT_JSON))
    write(TEACHER_STUDENT_JSON, json_object(result) * "\n")
    write(TEACHER_STUDENT_MD, markdown_teacher_student(result))
    print(markdown_teacher_student(result))
    println("Wrote $TEACHER_STUDENT_JSON")
    println("Wrote $TEACHER_STUDENT_MD")
    result.status == "passed" || error("ecCKD teacher-student recovery failed")
end

function ecckd_teacher_student_recovery_scan_main()
    result = run_ecckd_teacher_student_recovery_scan(;
        iterations = env_int("RH_ECCKD_TEACHER_STUDENT_ITERATIONS", 32),
        step_fraction = env_float("RH_ECCKD_TEACHER_STUDENT_STEP_FRACTION", 0.2),
    )
    mkpath(dirname(TEACHER_STUDENT_SCAN_JSON))
    write(TEACHER_STUDENT_SCAN_JSON, json_object(result) * "\n")
    write(TEACHER_STUDENT_SCAN_MD, markdown_teacher_student_scan(result))
    print(markdown_teacher_student_scan(result))
    println("Wrote $TEACHER_STUDENT_SCAN_JSON")
    println("Wrote $TEACHER_STUDENT_SCAN_MD")
    result.status == "passed" || error("ecCKD teacher-student recovery scan failed")
end

if abspath(PROGRAM_FILE) == @__FILE__
    if get(ENV, "RH_ECCKD_TEACHER_STUDENT_SCAN", "false") == "true"
        ecckd_teacher_student_recovery_scan_main()
    else
        ecckd_teacher_student_recovery_main()
    end
end
