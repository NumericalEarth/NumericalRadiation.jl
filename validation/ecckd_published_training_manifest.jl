include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

const ABR_ROOT = normpath(joinpath(@__DIR__, ".."))
if Base.find_package("NumericalRadiation") === nothing
    push!(LOAD_PATH, ABR_ROOT)
end

using NumericalRadiation

const TRAINING_MANIFEST_JSON =
    validation_results_path("ecckd_published_training_manifest.json")
const TRAINING_MANIFEST_MD =
    validation_results_path("ecckd_published_training_manifest.md")
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

function active_assignment_lines(path, variable)
    lines = String[]
    for line in split(read(path, String), '\n')
        stripped = strip(line)
        isempty(stripped) && continue
        startswith(stripped, "#") && continue
        occursin(variable * "=", stripped) && push!(lines, stripped)
    end
    return lines
end

function config_value(path, variable)
    prefix = variable * "="
    for line in split(read(path, String), '\n')
        stripped = strip(line)
        startswith(stripped, prefix) || continue
        return strip(chop(stripped; head = length(prefix), tail = 0))
    end
    return nothing
end

function parse_mode_blocks(path)
    blocks = NamedTuple[]
    current_names = String[]
    current_lines = String[]
    in_block = false
    for line in split(read(path, String), '\n')
        stripped = strip(line)
        m = match(r"^([A-Za-z0-9_-]+(?:\s*\|\s*[A-Za-z0-9_-]+)*)\)$", stripped)
        if m !== nothing
            current_names = [strip(name) for name in split(m.captures[1], "|")]
            current_lines = String[]
            in_block = true
            continue
        end
        if in_block && stripped == ";;"
            assignments = logical_assignments(current_lines)
            push!(blocks, (
                names = current_names,
                assignments = assignments,
            ))
            current_names = String[]
            current_lines = String[]
            in_block = false
            continue
        end
        in_block && push!(current_lines, line)
    end
    return blocks
end

function quote_count(text)
    return count(==('"'), text)
end

function logical_assignments(lines)
    variables = ("TRAINING", "GASLIST", "SPECIFIC_OPTIONS", "EXTRA_ARGS")
    assignments = String[]
    buffer = nothing
    skipping_training_both_branch = false
    for line in lines
        stripped = strip(line)
        isempty(stripped) && continue
        startswith(stripped, "#") && continue
        if skipping_training_both_branch
            stripped == "fi" && (skipping_training_both_branch = false)
            continue
        end
        if startswith(stripped, "if ") && occursin("TRAINING_BOTH", stripped)
            skipping_training_both_branch = true
            continue
        end
        if buffer !== nothing
            buffer *= " " * stripped
            if iseven(quote_count(buffer))
                push!(assignments, buffer)
                buffer = nothing
            end
            continue
        end
        any(var -> startswith(stripped, var * "="), variables) || continue
        if isodd(quote_count(stripped))
            buffer = stripped
        else
            push!(assignments, stripped)
        end
    end
    buffer === nothing || push!(assignments, buffer)
    return assignments
end

function script_summary(root, relative_path)
    path = joinpath(root, relative_path)
    common_options = active_assignment_lines(path, "COMMON_OPTIONS")
    return (
        path = relative_path,
        exists = isfile(path),
        active_common_options = common_options,
        selected_common_options = isempty(common_options) ? nothing : last(common_options),
        modes = parse_mode_blocks(path),
    )
end

function assignment_value(lines, variable)
    prefix = variable * "="
    for line in reverse(lines)
        stripped = strip(line)
        startswith(stripped, prefix) || continue
        value = strip(chop(stripped; head = length(prefix), tail = 0))
        return strip(value, ['"'])
    end
    return nothing
end

function master_script_summary(root, relative_path)
    path = joinpath(root, relative_path)
    assignment_lines = isfile(path) ? active_assignment_lines(path, "") : String[]
    application = assignment_value(assignment_lines, "APPLICATION")
    band_structure = assignment_value(assignment_lines, "BAND_STRUCTURE")
    tolerance = assignment_value(assignment_lines, "TOLERANCE")
    optimize_modes = assignment_value(assignment_lines, "OPTIMIZE_MODE_LIST")
    return (
        path = relative_path,
        exists = isfile(path),
        application = application,
        band_structure = band_structure,
        tolerance = tolerance,
        optimize_mode_list = optimize_modes,
    )
end

function ckdmip_preflight_status()
    isfile(CKDMIP_PREFLIGHT_JSON) || return (
        status = "missing_preflight",
        derived_flux_final_product_count = 0,
        required_derived_flux_product_count = 18,
        missing_derived_flux_product_count = 18,
        ready = false,
    )
    preflight = JSON.parsefile(CKDMIP_PREFLIGHT_JSON)
    status = String(get(preflight, "status", "unknown"))
    derived_products = get(preflight, "derived_training_flux_products", Any[])
    final_count = Int(get(
        preflight,
        "derived_training_flux_file_count",
        count(product -> get(product, "present", false), derived_products),
    ))
    required_count = Int(get(
        preflight,
        "derived_training_flux_file_count",
        length(derived_products) == 0 ? 18 : length(derived_products),
    ))
    missing_count = count(product -> !get(product, "present", false), derived_products)
    return (
        status = status,
        derived_flux_final_product_count = final_count,
        required_derived_flux_product_count = required_count,
        missing_derived_flux_product_count = missing_count,
        ready = status == "ready_for_original_ecckd_objective" &&
                final_count == required_count &&
                missing_count == 0,
    )
end

function official_recovery_targets()
    return [
        (
            kind = "longwave",
            master_script = "test/do_all_lw.sh",
            application = "climate",
            band_structure = "fsck",
            tolerances = ["0.061", "0.0161"],
            nominal_gpoints = [16, 32],
            optimizer_pass_order = ["relative-base", "relative-ch4", "relative-n2o", "relative-cfc"],
            published_reference = "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc",
        ),
        (
            kind = "shortwave",
            master_script = "test/do_all_sw.sh",
            application = "climate",
            band_structure = "rgb",
            tolerances = ["0.16", "0.047"],
            nominal_gpoints = [16, 32],
            optimizer_pass_order = ["relative-base", "relative-ch4", "relative-n2o"],
            published_reference = "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc",
        ),
    ]
end

function run_ecckd_published_training_manifest()
    root = ecckd_source_path(require = true)
    config_path = joinpath(root, "test", "config.h")
    required_files = [
        "src/ecckd/optimize_lut.cpp",
        "src/ecckd/solve_adept.cpp",
        "src/ecckd/calc_cost_function_lw.cpp",
        "src/ecckd/calc_cost_function_sw.cpp",
        "test/config.h",
        "test/find_g_points_lw.sh",
        "test/find_g_points_sw.sh",
        "test/create_lut_lw.sh",
        "test/create_lut_sw.sh",
        "test/optimize_lut_lw.sh",
        "test/optimize_lut_sw.sh",
        "test/run_ckd_lw.sh",
        "test/run_ckd_sw.sh",
    ]
    source_files = [(path = file, exists = isfile(joinpath(root, file))) for file in required_files]
    scripts = [
        script_summary(root, "test/optimize_lut_lw.sh"),
        script_summary(root, "test/optimize_lut_sw.sh"),
    ]
    master_scripts = [
        master_script_summary(root, "test/do_all_lw.sh"),
        master_script_summary(root, "test/do_all_sw.sh"),
    ]
    config = (
        ckdmip_data_dir = config_value(config_path, "CKDMIP_DATA_DIR"),
        training_code = config_value(config_path, "TRAINING_CODE"),
        evaluation_code = config_value(config_path, "EVALUATION_CODE"),
        training_both = config_value(config_path, "TRAINING_BOTH"),
        mmm_code = config_value(config_path, "MMM_CODE"),
        idealized_code = config_value(config_path, "IDEALIZED_CODE"),
    )
    passed = all(file -> file.exists, source_files) &&
             all(script -> script.exists && script.selected_common_options !== nothing, scripts) &&
             all(script -> script.exists, master_scripts)
    preflight = ckdmip_preflight_status()
    return (
        case = "ecckd_published_training_manifest",
        timestamp_utc = string(Dates.now()),
        status = passed ? "passed" : "failed",
        ecckd_source_root = root,
        objective_contract =
            "Keep these ecCKD source files, script modes, data selections, gases, weights, regularization, and stopping settings fixed; replace only the optimizer implementation/settings in the Julia Reactant/Enzyme recovery pipeline.",
        config = config,
        ckdmip_preflight = preflight,
        source_files = source_files,
        master_scripts = master_scripts,
        optimization_scripts = scripts,
        official_recovery_targets = official_recovery_targets(),
        remaining_external_data_requirement =
            preflight.ready ?
            "None in this workspace: CKDMIP upstream inputs and all 18 derived ecCKD training flux products are present." :
            "Full CKDMIP line-by-line spectral absorption and LBL flux database under RH_CKDMIP_DATA_PATH, plus derived ecCKD 5gas/rel training flux products.",
    )
end

function markdown_manifest(result)
    lines = String[
        "# ecCKD Published Training Manifest",
        "",
        "Status: **$(result.status)**",
        "",
        "ecCKD source root: `$(result.ecckd_source_root)`",
        "",
        result.objective_contract,
        "",
        "## Config",
        "",
        "| Field | Value |",
        "|---|---|",
        "| CKDMIP data dir template | `$(result.config.ckdmip_data_dir)` |",
        "| Training dataset | `$(result.config.training_code)` |",
        "| Evaluation dataset | `$(result.config.evaluation_code)` |",
        "| Train with both evaluation sets | `$(result.config.training_both)` |",
        "| MMM dataset | `$(result.config.mmm_code)` |",
        "| Idealized dataset | `$(result.config.idealized_code)` |",
        "| CKDMIP preflight | `$(result.ckdmip_preflight.status)` |",
        "| Derived flux products | $(result.ckdmip_preflight.derived_flux_final_product_count) / $(result.ckdmip_preflight.required_derived_flux_product_count) |",
        "",
        "## Source Files",
        "",
        "| Path | Present |",
        "|---|---:|",
    ]
    for file in result.source_files
        push!(lines, "| `$(file.path)` | $(file.exists) |")
    end
    push!(lines, "", "## Master Recipes", "")
    push!(lines, "| Script | Application | Band structure | Tolerance list | Optimizer passes |")
    push!(lines, "|---|---|---|---|---|")
    for script in result.master_scripts
        push!(lines, "| `$(script.path)` | `$(script.application)` | `$(script.band_structure)` | `$(script.tolerance)` | `$(script.optimize_mode_list)` |")
    end
    push!(lines, "", "## Recovery Targets", "")
    push!(lines, "| Kind | Band structure | Tolerances | Nominal g-points | Optimizer pass order | Published reference |")
    push!(lines, "|---|---|---|---|---|---|")
    for target in result.official_recovery_targets
        push!(lines, "| $(target.kind) | `$(target.band_structure)` | `$(join(target.tolerances, ", "))` | `$(join(target.nominal_gpoints, ", "))` | `$(join(target.optimizer_pass_order, " -> "))` | `$(target.published_reference)` |")
    end
    push!(lines, "", "## Optimization Scripts", "")
    for script in result.optimization_scripts
        push!(lines, "### `$(script.path)`", "")
        push!(lines, "- Selected common options: `$(script.selected_common_options)`")
        mode_names = [join(mode.names, " | ") for mode in script.modes]
        push!(lines, "- Modes: $(join(mode_names, ", "))", "")
    end
    push!(lines, "Remaining external data requirement: $(result.remaining_external_data_requirement)")
    return join(lines, "\n") * "\n"
end

function ecckd_published_training_manifest_main()
    result = run_ecckd_published_training_manifest()
    mkpath(dirname(TRAINING_MANIFEST_JSON))
    write(TRAINING_MANIFEST_JSON, json_object(result) * "\n")
    write(TRAINING_MANIFEST_MD, markdown_manifest(result))
    print(markdown_manifest(result))
    println("Wrote $TRAINING_MANIFEST_JSON")
    println("Wrote $TRAINING_MANIFEST_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_published_training_manifest_main()
end
