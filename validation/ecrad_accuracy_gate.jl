include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "ecrad_reference_manifest.jl"))

const CANDIDATE_PREFIX = "radiative_heating_"
const COMPARISON_VARIABLES = (
    (
        name = "lw_up",
        candidate = CANDIDATE_PREFIX * "lw_up",
        rmse_threshold = ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
        max_abs_threshold = ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        units = "W m^-2",
    ),
    (
        name = "lw_down",
        candidate = CANDIDATE_PREFIX * "lw_down",
        rmse_threshold = ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
        max_abs_threshold = ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        units = "W m^-2",
    ),
    (
        name = "sw_up",
        candidate = CANDIDATE_PREFIX * "sw_up",
        rmse_threshold = ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
        max_abs_threshold = ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        units = "W m^-2",
    ),
    (
        name = "sw_down",
        candidate = CANDIDATE_PREFIX * "sw_down",
        rmse_threshold = ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
        max_abs_threshold = ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        units = "W m^-2",
    ),
    (
        name = "heating_rate",
        candidate = CANDIDATE_PREFIX * "heating_rate",
        rmse_threshold = ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day,
        max_abs_threshold = ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
        units = "K day^-1",
    ),
)

const HARD_GATE_CASE_NAMES = (
    "ecckd_clear_sky_tropical_column",
    "ecckd_all_sky_tropical_column",
    "ecckd_rcemip_style_column_subset",
)

const HARD_GATE_CASES = filter(case -> case.case in HARD_GATE_CASE_NAMES, REQUIRED_CASES)
const DIAGNOSTIC_CASES = filter(case -> !(case.case in HARD_GATE_CASE_NAMES), REQUIRED_CASES)

function array_from_var(dataset, name)
    return vec(Array(dataset[name]))
end

function array_from_flux_var(dataset, name)
    return Array(dataset[name])
end

function rmse(candidate, reference)
    length(candidate) == length(reference) ||
        throw(DimensionMismatch("candidate and reference arrays must have the same length"))
    return sqrt(sum(abs2, candidate .- reference) / length(reference))
end

function max_abs_error(candidate, reference)
    length(candidate) == length(reference) ||
        throw(DimensionMismatch("candidate and reference arrays must have the same length"))
    return maximum(abs, candidate .- reference)
end

function boundary_values(values, boundary)
    ndims(values) >= 1 ||
        throw(DimensionMismatch("flux arrays must have at least one interface dimension"))
    index = boundary == :toa ? firstindex(values, 1) : lastindex(values, 1)
    slice = selectdim(values, 1, index)
    return vec(Array(slice))
end

function net_flux(lw_up, lw_down, sw_up, sw_down, boundary)
    return boundary_values(lw_down, boundary) .-
           boundary_values(lw_up, boundary) .+
           boundary_values(sw_down, boundary) .-
           boundary_values(sw_up, boundary)
end

function forcing_status(path, boundary, threshold)
    dataset = nothing
    try
        dataset = NCDATASETS.NCDataset(reference_path(path))
        variables = String.(collect(keys(dataset)))
        reference_names = ("lw_up", "lw_down", "sw_up", "sw_down")
        candidate_names = CANDIDATE_PREFIX .* reference_names
        missing_reference = [name for name in reference_names if !(name in variables)]
        missing_candidate = [name for name in candidate_names if !(name in variables)]
        if !isempty(missing_reference) || !isempty(missing_candidate)
            return (
                metric = boundary == :toa ? "toa_forcing_abs_error" : "surface_forcing_abs_error",
                boundary = string(boundary),
                missing_reference_variables = missing_reference,
                missing_candidate_variables = missing_candidate,
                max_abs = nothing,
                threshold = threshold,
                units = "W m^-2",
                passed = false,
                status = "missing_comparison_variable",
            )
        end

        reference_net = net_flux(
            array_from_flux_var(dataset, "lw_up"),
            array_from_flux_var(dataset, "lw_down"),
            array_from_flux_var(dataset, "sw_up"),
            array_from_flux_var(dataset, "sw_down"),
            boundary,
        )
        candidate_net = net_flux(
            array_from_flux_var(dataset, CANDIDATE_PREFIX * "lw_up"),
            array_from_flux_var(dataset, CANDIDATE_PREFIX * "lw_down"),
            array_from_flux_var(dataset, CANDIDATE_PREFIX * "sw_up"),
            array_from_flux_var(dataset, CANDIDATE_PREFIX * "sw_down"),
            boundary,
        )
        error_max_abs = max_abs_error(candidate_net, reference_net)
        passed = error_max_abs <= threshold
        return (
            metric = boundary == :toa ? "toa_forcing_abs_error" : "surface_forcing_abs_error",
            boundary = string(boundary),
            missing_reference_variables = String[],
            missing_candidate_variables = String[],
            max_abs = error_max_abs,
            threshold = threshold,
            units = "W m^-2",
            passed = passed,
            status = passed ? "passed" : "failed_threshold",
        )
    catch err
        return (
            metric = boundary == :toa ? "toa_forcing_abs_error" : "surface_forcing_abs_error",
            boundary = string(boundary),
            missing_reference_variables = String[],
            missing_candidate_variables = String[],
            max_abs = nothing,
            threshold = threshold,
            units = "W m^-2",
            passed = false,
            status = "error: " * sprint(showerror, err),
        )
    finally
        dataset !== nothing && close(dataset)
    end
end

function comparison_status(path, variable)
    dataset = nothing
    try
        dataset = NCDATASETS.NCDataset(reference_path(path))
        variables = String.(collect(keys(dataset)))
        reference_present = variable.name in variables
        candidate_present = variable.candidate in variables
        if !reference_present || !candidate_present
            return (
                variable = variable.name,
                candidate_variable = variable.candidate,
                reference_present = reference_present,
                candidate_present = candidate_present,
                rmse = nothing,
                max_abs = nothing,
                rmse_threshold = variable.rmse_threshold,
                max_abs_threshold = variable.max_abs_threshold,
                units = variable.units,
                passed = false,
                status = "missing_comparison_variable",
            )
        end

        reference = array_from_var(dataset, variable.name)
        candidate = array_from_var(dataset, variable.candidate)
        error_rmse = rmse(candidate, reference)
        error_max_abs = max_abs_error(candidate, reference)
        passed = error_rmse <= variable.rmse_threshold &&
                 error_max_abs <= variable.max_abs_threshold
        return (
            variable = variable.name,
            candidate_variable = variable.candidate,
            reference_present = true,
            candidate_present = true,
            rmse = error_rmse,
            max_abs = error_max_abs,
            rmse_threshold = variable.rmse_threshold,
            max_abs_threshold = variable.max_abs_threshold,
            units = variable.units,
            passed = passed,
            status = passed ? "passed" : "failed_threshold",
        )
    catch err
        return (
            variable = variable.name,
            candidate_variable = variable.candidate,
            reference_present = false,
            candidate_present = false,
            rmse = nothing,
            max_abs = nothing,
            rmse_threshold = variable.rmse_threshold,
            max_abs_threshold = variable.max_abs_threshold,
            units = variable.units,
            passed = false,
            status = "error: " * sprint(showerror, err),
        )
    finally
        dataset !== nothing && close(dataset)
    end
end

function case_accuracy_status(case)
    manifest = case_status(case)
    if !manifest.schema_valid
        return (
            case = case.case,
            path = case.path,
            schema_status = manifest.status,
        comparisons = NamedTuple[],
        forcing_comparisons = NamedTuple[],
        passed = false,
        status = manifest.present ? "invalid_reference_schema" : "missing_reference",
        )
    end

    comparisons = [comparison_status(case.path, variable) for variable in COMPARISON_VARIABLES]
    forcing_comparisons = (
        forcing_status(case.path, :toa, ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2),
        forcing_status(case.path, :surface, ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2),
    )
    passed = all(comparison -> comparison.passed, comparisons) &&
             all(comparison -> comparison.passed, forcing_comparisons)
    missing_candidate = any(comparison -> comparison.status == "missing_comparison_variable", comparisons) ||
        any(comparison -> comparison.status == "missing_comparison_variable", forcing_comparisons)
    return (
        case = case.case,
        path = case.path,
        schema_status = manifest.status,
        comparisons = comparisons,
        forcing_comparisons = forcing_comparisons,
        passed = passed,
        status = passed ? "passed" :
                 missing_candidate ? "missing_candidate_outputs" :
                 "failed_threshold",
    )
end

function markdown_accuracy_report(result)
    lines = String[
        "# ecRad Accuracy Gate",
        "",
        "Status: **$(result.status)**",
        "",
        "This report applies hard acceptance thresholds to official ecCKD ecRad reference variables and `$(CANDIDATE_PREFIX)*` candidate variables in the same NetCDF files. It does not run ecRad.",
        "",
        "Hard gate scope: `$(result.case_scope)`. Legacy non-ecCKD references remain diagnostics and do not control this pass/fail status.",
        "",
        "| Case | Status | Passed | Path |",
        "|---|---|---:|---|",
    ]
    for case in result.cases
        push!(lines, "| $(case.case) | $(case.status) | $(case.passed) | `$(case.path)` |")
    end
    append!(lines, [
        "",
        "## Variable Thresholds",
        "",
        "| Variable | Candidate variable | RMSE threshold | Max abs threshold |",
        "|---|---|---:|---:|",
    ])
    for variable in COMPARISON_VARIABLES
        push!(lines, "| `$(variable.name)` | `$(variable.candidate)` | $(@sprintf("%.12g", variable.rmse_threshold)) $(variable.units) | $(@sprintf("%.12g", variable.max_abs_threshold)) $(variable.units) |")
    end
    append!(lines, [
        "",
        "## Boundary Net-Flux Thresholds",
        "",
        "| Metric | Boundary | Max abs threshold |",
        "|---|---|---:|",
        "| TOA forcing abs error | first interface | $(@sprintf("%.12g", ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2)) W m^-2 |",
        "| Surface forcing abs error | last interface | $(@sprintf("%.12g", ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2)) W m^-2 |",
    ])
    append!(lines, [
        "",
        "A file must include the ecRad variables from `validation/ecrad_reference_manifest.jl` and matching candidate variables named `radiative_heating_lw_up`, `radiative_heating_lw_down`, `radiative_heating_sw_up`, `radiative_heating_sw_down`, and `radiative_heating_heating_rate`.",
    ])
    if !isempty(result.diagnostic_cases)
        append!(lines, [
            "",
            "## Diagnostic Cases Outside This Hard Gate",
            "",
            "| Case | Path |",
            "|---|---|",
        ])
        for case in result.diagnostic_cases
            push!(lines, "| $(case.case) | `$(case.path)` |")
        end
    end
    return join(lines, "\n") * "\n"
end

function run_accuracy_gate()
    if NCDATASETS === nothing
        cases = NamedTuple[]
        diagnostic_cases = NamedTuple[]
        status = "ncdatasets_unavailable"
    else
        cases = [case_accuracy_status(case) for case in HARD_GATE_CASES]
        diagnostic_cases = [case_status(case) for case in DIAGNOSTIC_CASES]
        status = all(case -> case.passed, cases) ? "passed" :
                 any(case -> case.status == "missing_reference", cases) ? "missing_references" :
                 any(case -> case.status == "invalid_reference_schema", cases) ? "invalid_reference_schema" :
                 any(case -> case.status == "missing_candidate_outputs", cases) ? "missing_candidate_outputs" :
                 "failed_threshold"
    end
    return (
        case = "ecrad_accuracy_gate",
        date = string(Dates.now()),
        status = status,
        case_scope = "official_ecCKD_hard_gate",
        candidate_prefix = CANDIDATE_PREFIX,
        acceptance_thresholds = ACCEPTANCE_THRESHOLDS,
        cases = cases,
        diagnostic_cases = diagnostic_cases,
    )
end

function accuracy_gate_main()
    result = run_accuracy_gate()
    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "ecrad_accuracy_gate.json")
    md_path = joinpath(results_dir, "ecrad_accuracy_gate.md")
    write(json_path, json_object(result))
    write(md_path, markdown_accuracy_report(result))

    print(markdown_accuracy_report(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    accuracy_gate_main()
end
