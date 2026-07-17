# By default validation scripts write under `validation/results`, preserving
# their direct command-line behavior. Tests set
# `NUMERICAL_RADIATION_VALIDATION_RESULTS_DIR` to redirect generated artifacts
# to a temporary copy of the result tree.
function validation_results_dir()
    default_results_dir = joinpath(@__DIR__, "results")
    return normpath(
        get(
            ENV,
            "NUMERICAL_RADIATION_VALIDATION_RESULTS_DIR",
            default_results_dir,
        ),
    )
end

validation_results_path(parts...) = joinpath(validation_results_dir(), parts...)

function ensure_validation_results_dir()
    results_dir = validation_results_dir()
    mkpath(results_dir)
    return results_dir
end
