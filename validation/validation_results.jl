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

# The ecRad reference NetCDF products under `validation/reference` are
# distributed as the lazy `ecrad_reference_data` Pkg artifact instead of being
# tracked in git (only README files stay tracked). Validation runs write
# candidate variables into these NetCDF files in place, so the artifact is
# always materialized as a writable copy inside the repository working tree;
# it is never consumed read-only from the artifact store. Resolution order:
#   1. `NUMERICAL_RADIATION_VALIDATION_REFERENCE_DIR` environment override,
#   2. an existing local `validation/reference` data copy (developer checkouts),
#   3. a writable copy materialized from the `ecrad_reference_data` artifact.
# NOTE: branch 3 becomes live once the `validation-data-v1` release asset in
# Artifacts.toml is published; fresh clones then download and materialize the
# reference data on first use.
# Copy ONLY reference `.nc` payloads from the artifact into the working
# tree, creating directories as needed and making the copies writable.
# Tracked repository files at this path (README.md and any other non-.nc
# files) are NEVER touched: an earlier top-level `cp(...; force = true)`
# clobbered the tracked validation/reference/ecrad/README.md with the
# artifact's stale copy (monitor-caught side effect).
function materialize_reference_payloads(artifact_dir, reference_dir)
    for (root, _, files) in walkdir(artifact_dir)
        rel = relpath(root, artifact_dir)
        for file in files
            endswith(file, ".nc") || continue
            dest_dir = rel == "." ? reference_dir :
                       joinpath(reference_dir, rel)
            mkpath(dest_dir)
            dest = joinpath(dest_dir, file)
            cp(joinpath(root, file), dest; force = true)
            # Artifact-store files are read-only; the copy must be writable.
            chmod(dest, 0o644)
        end
    end
    return reference_dir
end

function validation_reference_dir()
    override = get(ENV, "NUMERICAL_RADIATION_VALIDATION_REFERENCE_DIR", nothing)
    override !== nothing && return normpath(override)
    reference_dir = normpath(joinpath(@__DIR__, "reference"))
    if isdir(reference_dir)
        for (_, _, files) in walkdir(reference_dir)
            any(endswith(".nc"), files) && return reference_dir
        end
    end
    lazy_artifacts = Base.require(
        Base.PkgId(Base.UUID("4af54fe1-eca0-43a8-85a7-787d91b784e3"), "LazyArtifacts"))
    artifacts_toml = normpath(joinpath(@__DIR__, "..", "Artifacts.toml"))
    tree_hash = lazy_artifacts.artifact_hash("ecrad_reference_data", artifacts_toml)
    lazy_artifacts.artifact_exists(tree_hash) ||
        lazy_artifacts.ensure_artifact_installed("ecrad_reference_data", artifacts_toml)
    artifact_dir = lazy_artifacts.artifact_path(tree_hash)
    mkpath(reference_dir)
    materialize_reference_payloads(artifact_dir, reference_dir)
    return reference_dir
end
