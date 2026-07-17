include(joinpath(@__DIR__, "validation_results.jl"))

using Dates

include(joinpath(@__DIR__, "ecrad_accuracy_gate.jl"))

function variable_shape(dataset, name)
    return collect(size(dataset[name]))
end

function candidate_schema_status(path, variable)
    dataset = nothing
    try
        dataset = NCDATASETS.NCDataset(reference_path(path))
        variables = String.(collect(keys(dataset)))
        reference_present = variable.name in variables
        candidate_present = variable.candidate in variables
        reference_shape = reference_present ? variable_shape(dataset, variable.name) : Int[]
        candidate_shape = candidate_present ? variable_shape(dataset, variable.candidate) : Int[]
        shape_matches = reference_present && candidate_present &&
            reference_shape == candidate_shape
        return (
            variable = variable.name,
            candidate_variable = variable.candidate,
            reference_present = reference_present,
            candidate_present = candidate_present,
            reference_shape = reference_shape,
            candidate_shape = candidate_shape,
            shape_matches = shape_matches,
            status = shape_matches ? "passed" :
                     !reference_present ? "missing_reference_variable" :
                     !candidate_present ? "missing_candidate_variable" :
                     "shape_mismatch",
        )
    catch err
        return (
            variable = variable.name,
            candidate_variable = variable.candidate,
            reference_present = false,
            candidate_present = false,
            reference_shape = Int[],
            candidate_shape = Int[],
            shape_matches = false,
            status = "error: " * sprint(showerror, err),
        )
    finally
        dataset !== nothing && close(dataset)
    end
end

function case_candidate_schema_status(case)
    manifest = case_status(case)
    if !manifest.schema_valid
        return (
            case = case.case,
            path = case.path,
            schema_status = manifest.status,
            variables = NamedTuple[],
            passed = false,
            status = manifest.present ? "invalid_reference_schema" : "missing_reference",
        )
    end

    variables = [candidate_schema_status(case.path, variable)
                 for variable in COMPARISON_VARIABLES]
    passed = all(variable -> variable.shape_matches, variables)
    return (
        case = case.case,
        path = case.path,
        schema_status = manifest.status,
        variables = variables,
        passed = passed,
        status = passed ? "passed" : "missing_or_mismatched_candidate_variables",
    )
end

function run_candidate_schema_check()
    if NCDATASETS === nothing
        cases = NamedTuple[]
        status = "ncdatasets_unavailable"
    else
        cases = [case_candidate_schema_status(case) for case in REQUIRED_CASES]
        status = all(case -> case.passed, cases) ? "passed" :
                 any(case -> case.status == "missing_reference", cases) ? "missing_references" :
                 any(case -> case.status == "invalid_reference_schema", cases) ? "invalid_reference_schema" :
                 "missing_or_mismatched_candidate_variables"
    end
    return (
        case = "ecrad_candidate_schema",
        date = string(Dates.now()),
        status = status,
        candidate_prefix = CANDIDATE_PREFIX,
        cases = cases,
    )
end

function markdown_candidate_schema_report(result)
    lines = String[
        "# ecRad Candidate Schema Check",
        "",
        "Status: **$(result.status)**",
        "",
        "This report checks that each ecRad reference variable used by the hard accuracy gate has a matching `$(CANDIDATE_PREFIX)*` candidate variable with the same array shape. It does not validate numerical accuracy.",
        "",
        "| Case | Status | Passed | Path |",
        "|---|---|---:|---|",
    ]
    for case in result.cases
        push!(lines, "| $(case.case) | $(case.status) | $(case.passed) | `$(case.path)` |")
    end
    append!(lines, [
        "",
        "## Candidate Variables",
        "",
        "| Reference variable | Candidate variable | Shape rule |",
        "|---|---|---|",
    ])
    for variable in COMPARISON_VARIABLES
        push!(lines, "| `$(variable.name)` | `$(variable.candidate)` | exact shape match |")
    end
    return join(lines, "\n") * "\n"
end

function candidate_schema_main()
    result = run_candidate_schema_check()
    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "ecrad_candidate_schema.json")
    md_path = joinpath(results_dir, "ecrad_candidate_schema.md")
    write(json_path, json_object(result))
    write(md_path, markdown_candidate_schema_report(result))

    print(markdown_candidate_schema_report(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    candidate_schema_main()
end
