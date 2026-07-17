include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "ecrad_accuracy_gate.jl"))

const CLOUDLESS_CASE_NAMES = (
    "ecckd_clear_sky_tropical_column",
    "ecckd_rcemip_style_column_subset",
)
const CLOUDLESS_CASES = Tuple(case for case in REQUIRED_CASES if case.case in CLOUDLESS_CASE_NAMES)

function markdown_cloudless_report(result)
    lines = String[
        "# ecRad Cloudless Accuracy Gate",
        "",
        "Status: **$(result.status)**",
        "",
        "This focused hard gate compares only cloudless/no-aerosol reference cases. It is the first required accuracy step before the full all-sky ecRad gate.",
        "",
        "| Case | Status | Passed | Path |",
        "|---|---|---:|---|",
    ]
    for case in result.cases
        push!(lines, "| $(case.case) | $(case.status) | $(case.passed) | `$(case.path)` |")
    end
    append!(lines, [
        "",
        "## Scope",
        "",
        "- Included cases: `$(join(CLOUDLESS_CASE_NAMES, "`, `"))`.",
        "- Excluded here: all-sky cloud liquid/ice optics, aerosol optics, scattering, overlap, and McICA-style solver semantics.",
        "- Thresholds are the same hard flux, heating-rate, TOA forcing, and surface forcing thresholds used by `validation/ecrad_accuracy_gate.jl`.",
        "",
        "This gate must pass before reduced-model accuracy or all-sky convention work can close the `/goal`.",
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
    return join(lines, "\n") * "\n"
end

function run_cloudless_accuracy_gate()
    if NCDATASETS === nothing
        cases = NamedTuple[]
        status = "ncdatasets_unavailable"
    else
        cases = [case_accuracy_status(case) for case in CLOUDLESS_CASES]
        status = all(case -> case.passed, cases) ? "passed" :
                 any(case -> case.status == "missing_reference", cases) ? "missing_references" :
                 any(case -> case.status == "invalid_reference_schema", cases) ? "invalid_reference_schema" :
                 any(case -> case.status == "missing_candidate_outputs", cases) ? "missing_candidate_outputs" :
                 "failed_threshold"
    end
    return (
        case = "ecrad_cloudless_accuracy_gate",
        date = string(Dates.now()),
        status = status,
        candidate_prefix = CANDIDATE_PREFIX,
        reference_scope = "cloudless/no-aerosol first hard gate",
        included_cases = collect(CLOUDLESS_CASE_NAMES),
        excluded_physics = (
            "cloud_liquid_ice_optics",
            "aerosol_optics",
            "scattering",
            "cloud_overlap",
            "mcica_solver_semantics",
        ),
        acceptance_thresholds = ACCEPTANCE_THRESHOLDS,
        cases = cases,
    )
end

function cloudless_accuracy_gate_main()
    result = run_cloudless_accuracy_gate()
    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "ecrad_cloudless_accuracy_gate.json")
    md_path = joinpath(results_dir, "ecrad_cloudless_accuracy_gate.md")
    write(json_path, json_object(result))
    write(md_path, markdown_cloudless_report(result))

    print(markdown_cloudless_report(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    cloudless_accuracy_gate_main()
end
