include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

include(joinpath(@__DIR__, "ecckd_recovery_metrics.jl"))

const PUBLISHED_RECOVERY_VECTOR_JSON =
    validation_results_path("ecckd_published_recovery_vector.json")
const PUBLISHED_RECOVERY_VECTOR_MD =
    validation_results_path("ecckd_published_recovery_vector.md")
const PUBLISHED_RECOVERY_VECTOR_CANDIDATE =
    validation_results_path("ecckd_vector_roundtrip_sw32_candidate.nc")

const FLOAT_SUPPORT_ARRAY_NAMES = (
    "gpoint_fraction",
    "solar_irradiance",
    "planck_function",
    "rayleigh_molar_scattering_coeff",
)

function vectorized_array_names(path)
    NCDataset(path) do ds
        names = comparable_coefficient_names(ds, ds)
        for name in FLOAT_SUPPORT_ARRAY_NAMES
            haskey(ds, name) && push!(names, name)
        end
        return sort(names)
    end
end

function flatten_recovery_arrays(path, names)
    values = Float64[]
    shapes = NamedTuple[]
    NCDataset(path) do ds
        cursor = 1
        for name in names
            array = Float64.(Array(ds[name]))
            count = length(array)
            append!(values, vec(array))
            push!(shapes, (
                name = name,
                shape = collect(size(array)),
                first_index = cursor,
                last_index = cursor + count - 1,
                element_count = count,
            ))
            cursor += count
        end
    end
    return values, shapes
end

function write_vector_candidate(reference_path, candidate_path, parameters, shapes)
    cp(reference_path, candidate_path; force = true)
    chmod(candidate_path, 0o644)
    NCDataset(candidate_path, "a") do ds
        for shape in shapes
            values = reshape(parameters[shape.first_index:shape.last_index],
                             Tuple(shape.shape))
            ds[shape.name][:] = values
        end
    end
    return candidate_path
end

function vector_roundtrip_error(reference_parameters, candidate_parameters)
    diff = abs.(candidate_parameters .- reference_parameters)
    denom = max(sum(abs, reference_parameters), eps(Float64))
    return (
        max_abs_error = isempty(diff) ? 0.0 : maximum(diff),
        l1_relative_error = sum(diff) / denom,
    )
end

function run_ecckd_published_recovery_vector(;
                                             reference =
                                                 official_ecckd_definition_path(:shortwave_32),
                                             candidate =
                                                 PUBLISHED_RECOVERY_VECTOR_CANDIDATE)
    names = vectorized_array_names(reference)
    target, shapes = flatten_recovery_arrays(reference, names)
    write_vector_candidate(reference, candidate, target, shapes)
    roundtrip, _ = flatten_recovery_arrays(candidate, names)
    roundtrip_error = vector_roundtrip_error(target, roundtrip)
    metrics = recovery_metrics(reference, candidate)
    passed = metrics.status == "passed" &&
             roundtrip_error.max_abs_error == 0.0 &&
             roundtrip_error.l1_relative_error == 0.0
    return (
        case = "ecckd_published_recovery_vector",
        timestamp_utc = string(Dates.now()),
        status = passed ? "passed" : "failed",
        reference_path = reference,
        candidate_path = candidate,
        array_count = length(names),
        parameter_count = length(target),
        arrays = shapes,
        roundtrip_error = roundtrip_error,
        recovery_metrics = metrics,
        interpretation =
            "This is the optimizer handoff vector for published-model recovery: the optimizer can update this parameter vector, write a CKD-definition candidate, and score it with the published recovery metrics.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_published_recovery_vector(result)
    lines = String[
        "# ecCKD Published Recovery Vector",
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
        "| Round-trip max abs error | $(result.roundtrip_error.max_abs_error) |",
        "| Round-trip L1 relative error | $(result.roundtrip_error.l1_relative_error) |",
        "| Recovery metrics status | $(result.recovery_metrics.status) |",
        "| Worst log-coefficient RMSE | $(result.recovery_metrics.worst_log_coefficient_rmse) |",
        "| G-point weight max abs error | $(result.recovery_metrics.gpoint_weight_max_abs_error) |",
        "",
        "## Arrays",
        "",
        "| Name | Elements | Shape |",
        "|---|---:|---|",
    ]
    for row in result.arrays
        push!(lines, "| `$(row.name)` | $(row.element_count) | $(join(row.shape, "x")) |")
    end
    push!(lines, "", result.interpretation)
    return join(lines, "\n") * "\n"
end

function ecckd_published_recovery_vector_main()
    result = run_ecckd_published_recovery_vector()
    write_json(PUBLISHED_RECOVERY_VECTOR_JSON, result)
    write(PUBLISHED_RECOVERY_VECTOR_MD, markdown_published_recovery_vector(result))
    print(markdown_published_recovery_vector(result))
    println("Wrote $PUBLISHED_RECOVERY_VECTOR_JSON")
    println("Wrote $PUBLISHED_RECOVERY_VECTOR_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_published_recovery_vector_main()
end
