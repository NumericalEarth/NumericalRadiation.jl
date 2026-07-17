include(joinpath(@__DIR__, "validation_results.jl"))

using Dates

include(joinpath(@__DIR__, "ecckd_published_training_manifest.jl"))

const CKDMIP_PREFLIGHT_JSON =
    validation_results_path("ckdmip_training_data_preflight.json")
const CKDMIP_PREFLIGHT_MD =
    validation_results_path("ckdmip_training_data_preflight.md")

function ckdmip_data_root()
    root = get(ENV, "RH_CKDMIP_DATA_PATH", "")
    return !isempty(root) && isdir(root) ? normpath(root) : nothing
end

function expected_layout_roots()
    return [
        "mmm/conc",
        "mmm/lw_spectra",
        "mmm/sw_spectra",
        "mmm/sw_spectra_extras",
        "idealized/conc",
        "idealized/lw_spectra",
        "idealized/sw_spectra",
        "evaluation1/conc",
        "evaluation1/lw_spectra",
        "evaluation1/sw_spectra",
        "evaluation1/lw_fluxes",
        "evaluation1/sw_fluxes",
        "evaluation2/conc",
        "evaluation2/lw_spectra",
        "evaluation2/sw_spectra",
        "evaluation2/lw_fluxes",
        "evaluation2/sw_fluxes",
    ]
end

function quoted_filenames(text, pattern)
    matches = eachmatch(pattern, text)
    return unique([match.match for match in matches])
end

function expected_training_flux_files(manifest)
    files = String[]
    pattern = r"ckdmip_(evaluation[12])_(lw|sw)_fluxes_[A-Za-z0-9-]+\.h5"
    for script in manifest.optimization_scripts
        for mode in script.modes
            for assignment in mode.assignments
                append!(files, quoted_filenames(assignment, pattern))
            end
        end
    end
    unique!(files)
    sort!(files)
    return files
end

function derived_training_flux_file(filename)
    return occursin(r"_fluxes_(5gas|rel)-", filename)
end

function expected_flux_path(filename)
    m = match(r"ckdmip_(evaluation[12])_(lw|sw)_fluxes_", filename)
    m === nothing && throw(ArgumentError("not a CKDMIP flux filename: $(filename)"))
    dataset, domain = m.captures
    return joinpath(dataset, "$(domain)_fluxes", filename)
end

function key_files()
    return [
        "mmm/conc/ckdmip_mmm_concentrations.nc",
        "idealized/conc/ckdmip_idealized_concentrations.nc",
        "evaluation1/conc/ckdmip_evaluation1_concentrations_present.nc",
        "evaluation2/conc/ckdmip_evaluation2_concentrations_present.nc",
        "mmm/sw_spectra_extras/ckdmip_ssi.h5",
    ]
end

function nonempty_dir(path)
    isdir(path) && !isempty(readdir(path))
end

function run_ckdmip_training_data_preflight()
    root = ckdmip_data_root()
    manifest = run_ecckd_published_training_manifest()
    training_flux_files = expected_training_flux_files(manifest)
    upstream_training_flux_files = [file for file in training_flux_files if !derived_training_flux_file(file)]
    derived_training_flux_files = [file for file in training_flux_files if derived_training_flux_file(file)]
    upstream_expected_files = vcat(key_files(), expected_flux_path.(upstream_training_flux_files))
    derived_expected_files = expected_flux_path.(derived_training_flux_files)

    layout = [
        (path = path, present = root !== nothing && isdir(joinpath(root, path)))
        for path in expected_layout_roots()
    ]
    upstream_files = [
        (path = path, present = root !== nothing && isfile(joinpath(root, path)))
        for path in upstream_expected_files
    ]
    derived_files = [
        (path = path, present = root !== nothing && isfile(joinpath(root, path)))
        for path in derived_expected_files
    ]
    spectra_dirs = [
        (path = path, present = root !== nothing && nonempty_dir(joinpath(root, path)))
        for path in (
            "mmm/lw_spectra",
            "mmm/sw_spectra",
            "idealized/lw_spectra",
            "idealized/sw_spectra",
            "evaluation1/lw_spectra",
            "evaluation1/sw_spectra",
            "evaluation2/lw_spectra",
            "evaluation2/sw_spectra",
        )
    ]
    missing_layout = [entry.path for entry in layout if !entry.present]
    missing_upstream_files = [entry.path for entry in upstream_files if !entry.present]
    missing_derived_files = [entry.path for entry in derived_files if !entry.present]
    missing_spectra_dirs = [entry.path for entry in spectra_dirs if !entry.present]
    blockers = String[]
    root === nothing && push!(blockers, "RH_CKDMIP_DATA_PATH is unset or does not point to a directory.")
    append!(blockers, ["Missing required CKDMIP layout directory: $(path)" for path in missing_layout])
    append!(blockers, ["Missing required upstream CKDMIP file: $(path)" for path in missing_upstream_files])
    append!(blockers, ["Missing or empty CKDMIP spectra directory: $(path)" for path in missing_spectra_dirs])
    derived_blockers = ["Missing derived ecCKD training flux product: $(path)" for path in missing_derived_files]
    status = !isempty(blockers) ?
             (root === nothing ? "missing_ckdmip_data_root" : "incomplete_ckdmip_upstream_data") :
             !isempty(derived_blockers) ? "ready_for_derived_flux_generation" :
             "ready_for_original_ecckd_objective"
    return (
        case = "ckdmip_training_data_preflight",
        timestamp_utc = string(Dates.now()),
        status = status,
        ckdmip_data_root = root,
        fixed_objective_manifest = TRAINING_MANIFEST_JSON,
        expected_training_flux_file_count = length(training_flux_files),
        expected_training_flux_files = training_flux_files,
        upstream_training_flux_file_count = length(upstream_training_flux_files),
        upstream_training_flux_files = upstream_training_flux_files,
        derived_training_flux_file_count = length(derived_training_flux_files),
        derived_training_flux_files = derived_training_flux_files,
        layout = layout,
        key_and_upstream_training_files = upstream_files,
        derived_training_flux_products = derived_files,
        spectra_directories = spectra_dirs,
        blockers = blockers,
        derived_flux_generation_blockers = derived_blockers,
    )
end

function markdown_preflight(result)
    lines = String[
        "# CKDMIP Training Data Preflight",
        "",
        "Status: **$(result.status)**",
        "",
        "CKDMIP data root: `$(result.ckdmip_data_root)`",
        "",
        "Fixed objective manifest: `$(result.fixed_objective_manifest)`",
        "",
        "Expected training flux files: $(result.expected_training_flux_file_count)",
        "",
        "- Upstream CKDMIP flux inputs: $(result.upstream_training_flux_file_count)",
        "- Derived ecCKD flux products: $(result.derived_training_flux_file_count)",
        "",
        "## Blockers",
        "",
    ]
    if isempty(result.blockers)
        push!(lines, "None.")
    else
        append!(lines, ["- $(blocker)" for blocker in result.blockers])
    end
    push!(lines, "", "## Derived Flux Products", "")
    if isempty(result.derived_flux_generation_blockers)
        push!(lines, "None missing.")
    else
        append!(lines, ["- $(blocker)" for blocker in result.derived_flux_generation_blockers])
    end
    push!(lines, "", "## Required Upstream Files", "", "| Path | Present |", "|---|---:|")
    for file in result.key_and_upstream_training_files
        push!(lines, "| `$(file.path)` | $(file.present) |")
    end
    push!(lines, "", "## Derived Training Flux Products", "", "| Path | Present |", "|---|---:|")
    for file in result.derived_training_flux_products
        push!(lines, "| `$(file.path)` | $(file.present) |")
    end
    return join(lines, "\n") * "\n"
end

function ckdmip_training_data_preflight_main()
    result = run_ckdmip_training_data_preflight()
    mkpath(dirname(CKDMIP_PREFLIGHT_JSON))
    write(CKDMIP_PREFLIGHT_JSON, json_object(result) * "\n")
    write(CKDMIP_PREFLIGHT_MD, markdown_preflight(result))
    print(markdown_preflight(result))
    println("Wrote $CKDMIP_PREFLIGHT_JSON")
    println("Wrote $CKDMIP_PREFLIGHT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ckdmip_training_data_preflight_main()
end
