include(joinpath(@__DIR__, "validation_results.jl"))

using Dates

include(joinpath(@__DIR__, "reduced_ecckd_optimization_preflight.jl"))

const OFFICIAL_AD_CHECK_JSON = validation_results_path("reduced_ecckd_official_ad_checks.json")
const OFFICIAL_AD_CHECK_MD = validation_results_path("reduced_ecckd_official_ad_checks.md")

function official_reduced_ad_checks(; parameters = initial_parameters())
    reactant_status = optional_dependency_status("Reactant")
    enzyme_status = optional_dependency_status("Enzyme")
    reactant_check = reactant_surrogate_check(parameters)
    enzyme_check = enzyme_surrogate_check(parameters)
    passed = reactant_status == "available" &&
             enzyme_status == "available" &&
             reactant_check.passed &&
             enzyme_check.passed
    return (
        case = "reduced_ecckd_official_ad_checks",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        parameterization = "official reduced ecCKD 32x16 surrogate parameter vector",
        parameter_count = length(parameters),
        reactant_status = reactant_status,
        enzyme_status = enzyme_status,
        reactant_check = reactant_check,
        enzyme_check = enzyme_check,
        status = passed ? "passed" : "failed",
    )
end

function markdown_ad_check_report(result)
    return join([
        "# Reduced ecCKD Official AD Checks",
        "",
        "Status: **$(result.status)**",
        "",
        "| Check | Status | Passed | Detail |",
        "|---|---|---:|---|",
        "| Reactant dependency | $(result.reactant_status) | $(result.reactant_status == "available") | official reduced surrogate compile path |",
        "| Reactant surrogate | $(result.reactant_check.status) | $(result.reactant_check.passed) | $(something(result.reactant_check.error, "")) |",
        "| Enzyme dependency | $(result.enzyme_status) | $(result.enzyme_status == "available") | official reduced surrogate gradient path |",
        "| Enzyme surrogate | $(result.enzyme_check.status) | $(result.enzyme_check.passed) | relative error $(something(result.enzyme_check.relative_error, "n/a")) <= $(result.enzyme_check.threshold) |",
        "",
    ], "\n")
end

function write_official_ad_check_artifacts(result)
    mkpath(dirname(OFFICIAL_AD_CHECK_JSON))
    write(OFFICIAL_AD_CHECK_JSON, json_object(result) * "\n")
    write(OFFICIAL_AD_CHECK_MD, markdown_ad_check_report(result))
    print(markdown_ad_check_report(result))
    println("Wrote $OFFICIAL_AD_CHECK_JSON")
    println("Wrote $OFFICIAL_AD_CHECK_MD")
end

function main()
    write_official_ad_check_artifacts(official_reduced_ad_checks())
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
