include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

const ABR_ROOT = normpath(joinpath(@__DIR__, ".."))
if Base.find_package("NumericalRadiation") === nothing
    push!(LOAD_PATH, ABR_ROOT)
end

using NumericalRadiation

const OBJECTIVE_RECONSTRUCTION_JSON =
    validation_results_path("ecckd_objective_reconstruction_check.json")
const OBJECTIVE_RECONSTRUCTION_MD =
    validation_results_path("ecckd_objective_reconstruction_check.md")
const TRAINING_MANIFEST_JSON =
    validation_results_path("ecckd_published_training_manifest.json")
const CKDMIP_PREFLIGHT_JSON =
    validation_results_path("ckdmip_training_data_preflight.json")

function json_escape(text)
    return replace(text, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")
end

function json_value(value)
    if value isa AbstractString
        return "\"" * json_escape(value) * "\""
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value isa NamedTuple
        return json_object(value)
    elseif value isa AbstractVector || value isa Tuple
        return "[" * join(json_value.(value), ", ") * "]"
    elseif value === nothing
        return "null"
    else
        return string(value)
    end
end

function json_object(object)
    names = propertynames(object)
    lines = ["{"]
    for (i, name) in enumerate(names)
        comma = i == length(names) ? "" : ","
        push!(lines, "  \"$(name)\": $(json_value(getproperty(object, name)))$(comma)")
    end
    push!(lines, "}")
    return join(lines, "\n")
end

function ecrad_source_root()
    root = ecrad_data_path(require = true)
    isfile(joinpath(root, "README.md")) && return normpath(root)
    for child in readdir(root)
        path = joinpath(root, child)
        if isdir(path) && isfile(joinpath(path, "README.md")) && isdir(joinpath(path, "data"))
            return normpath(path)
        end
    end
    return normpath(root)
end

function relative_existing_paths(root, paths)
    return [path for path in paths if isfile(joinpath(root, path))]
end

function all_files(root)
    root === nothing && return String[]
    files = String[]
    for (dir, _, names) in walkdir(root)
        for name in names
            push!(files, relpath(joinpath(dir, name), root))
        end
    end
    return files
end

function any_file_matches(files, predicates...)
    for file in files
        lower = lowercase(file)
        all(predicate -> predicate(lower), predicates) && return true
    end
    return false
end

contains_text(text) = lower -> occursin(text, lower)
contains_any(texts) = lower -> any(text -> occursin(text, lower), texts)

function ckdmip_training_root()
    path = get(ENV, "RH_CKDMIP_DATA_PATH", nothing)
    path isa AbstractString && isdir(path) && return normpath(path)
    return nothing
end

function ckdmip_preflight_result()
    isfile(CKDMIP_PREFLIGHT_JSON) || return nothing
    return JSON.parsefile(CKDMIP_PREFLIGHT_JSON)
end

function check_entry(; name, present, role, evidence = String[], blocker = nothing)
    return (
        name = name,
        present = present,
        role = role,
        evidence = evidence,
        blocker = blocker,
    )
end

function run_ecckd_objective_reconstruction_check()
    root = ecrad_source_root()
    files = all_files(root)
    source_root = ecckd_source_path(require = false)
    ckdmip_root = ckdmip_training_root()
    ckdmip_preflight = ckdmip_preflight_result()
    ckdmip_preflight_status =
        ckdmip_preflight === nothing ? "missing_preflight" :
        String(get(ckdmip_preflight, "status", "unknown"))
    derived_flux_blockers =
        ckdmip_preflight === nothing ? String[] :
        String.(get(ckdmip_preflight, "derived_flux_generation_blockers", Any[]))

    published_definitions =
        [relpath(path, root) for path in official_ecckd_definition_path.(official_ecckd_model_inventory())]
    ckdmip_evaluation_paths = [
        "test/ckdmip/ckdmip_evaluation1_concentrations_present_reduced.nc",
        "test/ckdmip/ckdmip_evaluation1_lw_fluxes_present_reduced.nc",
        "test/ckdmip/ckdmip_evaluation1_sw_fluxes_present_reduced.nc",
    ]
    ckdmip_scripts = [
        "test/ckdmip/do_evaluate_ecrad.m",
        "test/ckdmip/evaluate_ckd_lw_fluxes.m",
        "test/ckdmip/evaluate_ckd_sw_fluxes.m",
        "test/ckdmip/evaluate_forcing_ecrad.m",
    ]
    runtime_sources = [
        "radiation/radiation_ecckd.F90",
        "radiation/radiation_ecckd_gas.F90",
        "radiation/radiation_ecckd_interface.F90",
    ]

    has_lbl_training_database =
        any_file_matches(files, contains_any(("lbl", "line-by-line", "line_by_line")), endswith_nc) ||
        any_file_matches(files, contains_text("training"), endswith_nc)
    required_ckdmip_dirs = [
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
    ckdmip_dir_evidence = ckdmip_root === nothing ? String[] :
                          [dir for dir in required_ckdmip_dirs if isdir(joinpath(ckdmip_root, dir))]
    required_ckdmip_key_files = [
        "mmm/conc/ckdmip_mmm_concentrations.nc",
        "idealized/conc/ckdmip_idealized_concentrations.nc",
        "evaluation1/conc/ckdmip_evaluation1_concentrations_present.nc",
        "evaluation2/conc/ckdmip_evaluation2_concentrations_present.nc",
        "mmm/sw_spectra_extras/ckdmip_ssi.h5",
        "evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_present.h5",
        "evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_present.h5",
    ]
    ckdmip_file_evidence = ckdmip_root === nothing ? String[] :
                           [file for file in required_ckdmip_key_files if isfile(joinpath(ckdmip_root, file))]
    required_ckdmip_spectra_dirs = [
        "mmm/lw_spectra",
        "mmm/sw_spectra",
        "idealized/lw_spectra",
        "idealized/sw_spectra",
        "evaluation1/lw_spectra",
        "evaluation1/sw_spectra",
        "evaluation2/lw_spectra",
        "evaluation2/sw_spectra",
    ]
    ckdmip_spectra_evidence = ckdmip_root === nothing ? String[] :
                              [dir for dir in required_ckdmip_spectra_dirs
                               if isdir(joinpath(ckdmip_root, dir)) &&
                                  !isempty(readdir(joinpath(ckdmip_root, dir)))]
    has_ckdmip_training_tree = length(ckdmip_dir_evidence) == length(required_ckdmip_dirs) &&
                               length(ckdmip_file_evidence) == length(required_ckdmip_key_files) &&
                               length(ckdmip_spectra_evidence) == length(required_ckdmip_spectra_dirs)
    has_required_derived_flux_products =
        ckdmip_root !== nothing &&
        (ckdmip_preflight_status == "ready_for_original_ecckd_objective" ||
         (ckdmip_preflight !== nothing &&
         isempty(derived_flux_blockers) &&
         ckdmip_preflight_status != "missing_ckdmip_data_root" &&
         ckdmip_preflight_status != "incomplete_ckdmip_upstream_data"))
    optimizer_source_paths = [
        "src/ecckd/optimize_lut.cpp",
        "src/ecckd/solve_adept.cpp",
        "src/ecckd/calc_cost_function_lw.cpp",
        "src/ecckd/calc_cost_function_sw.cpp",
    ]
    objective_manifest_paths = [
        "test/config.h",
        "test/optimize_lut_lw.sh",
        "test/optimize_lut_sw.sh",
        "test/do_all_lw.sh",
        "test/do_all_sw.sh",
    ]
    optimizer_evidence =
        source_root === nothing ? String[] : relative_existing_paths(source_root, optimizer_source_paths)
    objective_manifest_evidence =
        source_root === nothing ? String[] : relative_existing_paths(source_root, objective_manifest_paths)
    has_generator_or_optimizer = length(optimizer_evidence) == length(optimizer_source_paths)
    has_objective_manifest = length(objective_manifest_evidence) == length(objective_manifest_paths)

    checks = [
        check_entry(
            name = "published ecCKD CKD-definition files",
            present = all(isfile, official_ecckd_definition_path.(official_ecckd_model_inventory())),
            role = "Published model targets for schema validation, teacher-student recovery, and coefficient comparisons.",
            evidence = published_definitions,
        ),
        check_entry(
            name = "CKDMIP evaluation profiles and reference fluxes",
            present = length(relative_existing_paths(root, ckdmip_evaluation_paths)) == length(ckdmip_evaluation_paths),
            role = "Evaluation data for radiation-model comparison after a model has been generated.",
            evidence = relative_existing_paths(root, ckdmip_evaluation_paths),
        ),
        check_entry(
            name = "ecRad CKDMIP evaluation scripts",
            present = !isempty(relative_existing_paths(root, ckdmip_scripts)),
            role = "Reference examples for evaluating CKD files in ecRad.",
            evidence = relative_existing_paths(root, ckdmip_scripts),
        ),
        check_entry(
            name = "ecRad runtime ecCKD source",
            present = !isempty(relative_existing_paths(root, runtime_sources)),
            role = "Runtime implementation needed to understand how published CKD-definition files are consumed.",
            evidence = relative_existing_paths(root, runtime_sources),
        ),
        check_entry(
            name = "original LBL training database",
            present = has_lbl_training_database || has_ckdmip_training_tree,
            role = "Upstream CKDMIP spectra, concentrations, and public flux inputs required before derived ecCKD training fluxes can be generated.",
            evidence = vcat(
                [file for file in files
                 if occursin(r"(?i)(lbl|line-by-line|line_by_line|training).*\.nc$", file)],
                ckdmip_dir_evidence,
                ckdmip_file_evidence,
                ckdmip_spectra_evidence,
            ),
            blocker = (has_lbl_training_database || has_ckdmip_training_tree) ? nothing :
                      "No complete CKDMIP line-by-line training tree was found; set RH_CKDMIP_DATA_PATH to a mounted/downloaded CKDMIP data root and run ckdmip_training_data_preflight.",
        ),
        check_entry(
            name = "derived ecCKD training flux products",
            present = has_required_derived_flux_products,
            role = "Derived 5-gas and relative-humidity perturbation flux products consumed by the published ecCKD optimizer scripts.",
            evidence = ckdmip_preflight === nothing ? String[] :
                       String.(get(ckdmip_preflight, "derived_training_flux_files", Any[])),
            blocker = has_required_derived_flux_products ? nothing :
                      (ckdmip_root !== nothing &&
                       ckdmip_preflight_status == "ready_for_derived_flux_generation") ?
                      "CKDMIP upstream data is present, but derived ecCKD 5gas/rel training flux products are missing; generate them locally from the spectra before exact objective recovery." :
                      nothing,
        ),
        check_entry(
            name = "official ecCKD generator and optimizer source",
            present = has_generator_or_optimizer,
            role = "Required to keep all non-optimizer choices identical while swapping in the Reactant/Enzyme optimizer.",
            evidence = optimizer_evidence,
            blocker = has_generator_or_optimizer ? nothing :
                      "No official ecCKD optimizer source was found through RH_ECCKD_SOURCE_PATH, the ecckd_source artifact, or validation/external/ecckd.",
        ),
        check_entry(
            name = "official ecCKD objective weights and training scripts",
            present = has_objective_manifest,
            role = "Required to define the exact gases, profiles, spectral weights, loss terms, and stopping criteria used by the published models.",
            evidence = objective_manifest_evidence,
            blocker = has_objective_manifest ? nothing :
                      "No official ecCKD objective/training scripts were found through RH_ECCKD_SOURCE_PATH, the ecckd_source artifact, or validation/external/ecckd.",
        ),
    ]

    blockers = [check.blocker for check in checks if check.blocker !== nothing]
    status = isempty(blockers) ? "ready_to_reconstruct_original_objective" :
             "blocked_missing_original_training_assets"
    return (
        case = "ecckd_objective_reconstruction_check",
        timestamp_utc = string(Dates.now()),
        status = status,
        ecrad_source_root = root,
        ecckd_source_root = source_root,
        ckdmip_training_root = ckdmip_root,
        checks = checks,
        blockers = blockers,
        current_supported_recovery =
            "Teacher-student coefficient recovery against published ecCKD CKD-definition files using Reactant compilation checks and Enzyme gradients.",
        fixed_objective_manifest =
            isfile(TRAINING_MANIFEST_JSON) ? TRAINING_MANIFEST_JSON : nothing,
        ckdmip_training_data_preflight =
            isfile(CKDMIP_PREFLIGHT_JSON) ? CKDMIP_PREFLIGHT_JSON : nothing,
        ckdmip_training_data_preflight_status = ckdmip_preflight_status,
        missing_for_exact_original_recovery =
            [check.name for check in checks if check.blocker !== nothing],
        next_required_inputs = (
            "Set RH_CKDMIP_DATA_PATH to a complete CKDMIP tree with public upstream spectra, concentration, and flux inputs.",
            "Generate the derived ecCKD 5gas/rel training flux products locally from the upstream spectra if they are not already present.",
            "Encode the original profile set, spectral weights, gases, loss terms, and stopping criteria before varying optimizer settings.",
        ),
    )
end

endswith_nc(lower) = endswith(lower, ".nc")

function markdown_objective_reconstruction(result)
    lines = String[
        "# ecCKD Objective Reconstruction Check",
        "",
        "Status: **$(result.status)**",
        "",
        "ecRad source root: `$(result.ecrad_source_root)`",
        "",
        "ecCKD source root: `$(result.ecckd_source_root)`",
        "",
        "Current supported recovery: $(result.current_supported_recovery)",
        "",
        "## Checks",
        "",
        "| Asset | Present | Role | Evidence count |",
        "|---|---:|---|---:|",
    ]
    for check in result.checks
        push!(lines, "| $(check.name) | $(check.present) | $(check.role) | $(length(check.evidence)) |")
    end
    push!(lines, "", "## Blockers", "")
    if isempty(result.blockers)
        push!(lines, "None.")
    else
        append!(lines, ["- $(blocker)" for blocker in result.blockers])
    end
    push!(lines, "", "## Next Required Inputs", "")
    append!(lines, ["- $(input)" for input in result.next_required_inputs])
    return join(lines, "\n") * "\n"
end

function ecckd_objective_reconstruction_check_main()
    result = run_ecckd_objective_reconstruction_check()
    mkpath(dirname(OBJECTIVE_RECONSTRUCTION_JSON))
    write(OBJECTIVE_RECONSTRUCTION_JSON, json_object(result) * "\n")
    write(OBJECTIVE_RECONSTRUCTION_MD, markdown_objective_reconstruction(result))
    print(markdown_objective_reconstruction(result))
    println("Wrote $OBJECTIVE_RECONSTRUCTION_JSON")
    println("Wrote $OBJECTIVE_RECONSTRUCTION_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_objective_reconstruction_check_main()
end
