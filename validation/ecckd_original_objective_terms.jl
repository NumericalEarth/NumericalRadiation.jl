include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using Printf

const ORIGINAL_OBJECTIVE_TERMS_JSON =
    validation_results_path("ecckd_original_objective_terms.json")
const ORIGINAL_OBJECTIVE_TERMS_MD =
    validation_results_path("ecckd_original_objective_terms.md")
const TRAINING_MANIFEST_JSON =
    validation_results_path("ecckd_published_training_manifest.json")

function manifest_or_error()
    isfile(TRAINING_MANIFEST_JSON) ||
        error("missing $TRAINING_MANIFEST_JSON; run validation/ecckd_published_training_manifest.jl first")
    return JSON.parsefile(TRAINING_MANIFEST_JSON)
end

function source_lines(root, relative_path)
    path = joinpath(root, relative_path)
    isfile(path) || error("missing official ecCKD source file $path")
    return split(read(path, String), '\n')
end

function first_matching_line(lines, pattern)
    for (index, line) in enumerate(lines)
        occursin(pattern, line) && return index
    end
    return nothing
end

function source_term(name, description, lines, pattern)
    line = first_matching_line(lines, pattern)
    return (
        name = name,
        description = description,
        source_pattern = pattern,
        source_line = line,
        present = line !== nothing,
    )
end

function options_for_script(manifest, script_path)
    scripts = get(manifest, "optimization_scripts", Any[])
    for script in scripts
        get(script, "path", "") == script_path && return script
    end
    return Dict{String,Any}()
end

function modes_for_master(manifest, script_path)
    scripts = get(manifest, "master_scripts", Any[])
    for script in scripts
        get(script, "path", "") == script_path && return script
    end
    return Dict{String,Any}()
end

function objective_terms_for_kind(root, kind)
    if kind == "longwave"
        lines = source_lines(root, "src/ecckd/calc_cost_function_lw.cpp")
        return (
            source_file = "src/ecckd/calc_cost_function_lw.cpp",
            ckd_function = "calc_cost_function_ckd_lw",
            heating_rate_seconds_to_days = 86400.0,
            transfer = "radiative_transfer_lw with full upwelling and downwelling heating-rate calculation",
            terms = [
                source_term(
                    "spectral_band_heating_rate",
                    "Per-band squared heating-rate residual weighted by layer_weight and 86400^2.",
                    lines,
                    "hr_weight*hr_weight*sum(layer_weight*((heating_rate_fwd",
                ),
                source_term(
                    "spectral_surface_down_flux",
                    "Per-band surface downwelling flux residual weighted by flux_weight.",
                    lines,
                    "flux_dn_fwd(end,iband)-flux_dn(end,iband)",
                ),
                source_term(
                    "spectral_toa_up_flux",
                    "Per-band TOA upwelling flux residual weighted by flux_weight.",
                    lines,
                    "flux_up_fwd(0,iband)-flux_up(0,iband)",
                ),
                source_term(
                    "interior_flux_profile",
                    "Interior upwelling and downwelling profile residuals weighted by flux_profile_weight and interface weights.",
                    lines,
                    "flux_dn_fwd(range(1,end-1),iband)-flux_dn(range(1,end-1),iband)",
                ),
                source_term(
                    "broadband_heating_rate",
                    "Broadband heating-rate residual formed after summing over bands and blended by broadband_weight.",
                    lines,
                    "broadband_weight*hr_weight*hr_weight*sum(layer_weight*(sum(heating_rate_fwd-hr,1)",
                ),
                source_term(
                    "broadband_boundary_flux",
                    "Broadband surface-down and TOA-up residuals formed after summing over bands.",
                    lines,
                    "broadband_weight*flux_weight*(sum(flux_dn_fwd(end,__)-flux_dn(end,__))",
                ),
                source_term(
                    "spectral_boundary_flux",
                    "Optional g-point surface-down and TOA-up boundary residuals weighted by spectral_boundary_weight.",
                    lines,
                    "spectral_boundary_weight",
                ),
                source_term(
                    "relative_reference_flux_subtraction",
                    "Optional subtraction of relative-to CKD fluxes before evaluating residuals.",
                    lines,
                    "flux_dn_fwd_orig -= *relative_ckd_flux_dn",
                ),
            ],
        )
    elseif kind == "shortwave"
        lines = source_lines(root, "src/ecckd/calc_cost_function_sw.cpp")
        return (
            source_file = "src/ecckd/calc_cost_function_sw.cpp",
            ckd_function = "calc_cost_function_ckd_sw",
            heating_rate_seconds_to_days = 86400.0,
            transfer = "radiative_transfer_direct_sw or radiative_transfer_norayleigh_sw; heating-rate objective uses downwelling flux only",
            terms = [
                source_term(
                    "shortwave_transfer_branch",
                    "Direct shortwave transfer for zero albedo; no-Rayleigh two-stream branch for reflective surfaces.",
                    lines,
                    "radiative_transfer_norayleigh_sw(cos_sza, ssi,",
                ),
                source_term(
                    "downwelling_only_heating_rate",
                    "Heating-rate residual is computed from downwelling fluxes only in the CKD objective.",
                    lines,
                    "heating_rate(pressure_hl, flux_dn_fwd, aMatrix(), heating_rate_fwd)",
                ),
                source_term(
                    "spectral_band_heating_rate",
                    "Per-band squared heating-rate residual weighted by layer_weight and 86400^2.",
                    lines,
                    "hr_weight*hr_weight*sum(layer_weight*(heating_rate_fwd(__,iband)-hr(__,iband))",
                ),
                source_term(
                    "spectral_surface_down_flux",
                    "Per-band surface downwelling flux residual weighted by flux_weight.",
                    lines,
                    "flux_dn_fwd(end,iband)-flux_dn(end,iband)",
                ),
                source_term(
                    "spectral_toa_up_flux_20x",
                    "Per-band TOA upwelling residual weighted by flux_weight with the official 20x multiplier.",
                    lines,
                    "+20.0*(flux_up_fwd(0,iband)-flux_up(0,iband))",
                ),
                source_term(
                    "interior_flux_profile",
                    "Interior upwelling and downwelling profile residuals weighted by flux_profile_weight and interface weights.",
                    lines,
                    "flux_dn_fwd(range(1,end-1),iband)-flux_dn(range(1,end-1),iband)",
                ),
                source_term(
                    "broadband_heating_rate",
                    "Broadband heating-rate residual formed after summing over bands and blended by broadband_weight.",
                    lines,
                    "broadband_weight*hr_weight*hr_weight*sum(layer_weight*(sum(heating_rate_fwd-hr,1)",
                ),
                source_term(
                    "broadband_surface_down_flux",
                    "Broadband surface-down residual formed after summing over bands.",
                    lines,
                    "broadband_weight*flux_weight*(sum(flux_dn_fwd(end,__)-flux_dn(end,__))",
                ),
                source_term(
                    "spectral_boundary_surface_down_flux",
                    "Optional g-point surface-down residual weighted by spectral_boundary_weight.",
                    lines,
                    "flux_dn_fwd_orig(end,__)-spectral_flux_dn_surf",
                ),
                source_term(
                    "relative_reference_flux_subtraction",
                    "Optional subtraction of relative-to CKD fluxes before evaluating residuals.",
                    lines,
                    "flux_dn_fwd_orig -= *relative_ckd_flux_dn",
                ),
            ],
        )
    else
        throw(ArgumentError("unsupported kind $kind"))
    end
end

function pass_sequence(manifest, kind)
    if kind == "longwave"
        master = modes_for_master(manifest, "test/do_all_lw.sh")
        script = options_for_script(manifest, "test/optimize_lut_lw.sh")
    else
        master = modes_for_master(manifest, "test/do_all_sw.sh")
        script = options_for_script(manifest, "test/optimize_lut_sw.sh")
    end
    modes = split(String(get(master, "optimize_mode_list", "")))
    mode_blocks = get(script, "modes", Any[])
    rows = NamedTuple[]
    for mode in modes
        block = nothing
        for candidate in mode_blocks
            names = String.(get(candidate, "names", Any[]))
            mode in names && (block = candidate; break)
        end
        assignments = block === nothing ? String[] : String.(get(block, "assignments", Any[]))
        push!(rows, (
            mode = mode,
            present = block !== nothing,
            training = assignment_value(assignments, "TRAINING"),
            gaslist = assignment_value(assignments, "GASLIST"),
            specific_options = assignment_value(assignments, "SPECIFIC_OPTIONS"),
            extra_args = assignment_value(assignments, "EXTRA_ARGS"),
        ))
    end
    return (
        master_script = get(master, "path", kind == "longwave" ? "test/do_all_lw.sh" : "test/do_all_sw.sh"),
        application = get(master, "application", nothing),
        band_structure = get(master, "band_structure", nothing),
        tolerances = split(String(get(master, "tolerance", ""))),
        optimize_modes = modes,
        selected_common_options = get(script, "selected_common_options", nothing),
        passes = rows,
    )
end

function assignment_value(assignments, variable)
    prefix = variable * "="
    for assignment in reverse(assignments)
        startswith(assignment, prefix) || continue
        value = strip(chop(assignment; head = length(prefix), tail = 0))
        return strip(value, ['"'])
    end
    return nothing
end

function all_terms_present(section)
    all(term -> term.present, section.terms)
end

function original_objective_terms()
    manifest = manifest_or_error()
    root = String(manifest["ecckd_source_root"])
    longwave = objective_terms_for_kind(root, "longwave")
    shortwave = objective_terms_for_kind(root, "shortwave")
    pass_sequences = (
        longwave = pass_sequence(manifest, "longwave"),
        shortwave = pass_sequence(manifest, "shortwave"),
    )
    status = get(manifest, "status", "") == "passed" &&
             all_terms_present(longwave) &&
             all_terms_present(shortwave) &&
             all(row -> row.present, pass_sequences.longwave.passes) &&
             all(row -> row.present, pass_sequences.shortwave.passes) ?
             "objective_terms_captured" : "incomplete"
    return (
        case = "ecckd_original_objective_terms",
        timestamp_utc = string(Dates.now()),
        status = status,
        ecckd_source_root = root,
        objective_contract =
            "These terms and pass settings are fixed inputs for the Reactant/Enzyme original-objective recovery; optimizer settings may vary, but source data, loss terms, gases, weights, band mappings, and pass order may not.",
        implementation_status =
            "terms_captured_not_yet_recovered",
        longwave = longwave,
        shortwave = shortwave,
        pass_sequences = pass_sequences,
        next_required_work = [
            "Implement Julia/Reactant evaluation of calc_cost_function_ckd_lw and calc_cost_function_ckd_sw using these captured terms.",
            "Run optimizer-only recovery for one published target and compare recovered weights/tables against the published CKD definition.",
            "Promote the result into official_ecckd_training only after the quantitative recovery target is met.",
        ],
    )
end

function write_json_value(io, value)
    if value === nothing
        print(io, "null")
    elseif value isa AbstractString
        JSON.print(io, value)
    elseif value isa Bool
        print(io, value ? "true" : "false")
    elseif value isa Number
        print(io, isfinite(value) ? string(value) : "null")
    elseif value isa NamedTuple
        write_json_object(io, value)
    elseif value isa AbstractVector || value isa Tuple
        print(io, "[")
        for (i, item) in enumerate(value)
            i > 1 && print(io, ", ")
            write_json_value(io, item)
        end
        print(io, "]")
    else
        JSON.print(io, value)
    end
end

function write_json_object(io, object)
    names = propertynames(object)
    println(io, "{")
    for (i, name) in enumerate(names)
        print(io, "  ")
        JSON.print(io, String(name))
        print(io, ": ")
        write_json_value(io, getproperty(object, name))
        println(io, i == length(names) ? "" : ",")
    end
    print(io, "}")
end

function json_object(object)
    io = IOBuffer()
    write_json_object(io, object)
    return String(take!(io))
end

function markdown_report(result)
    lines = String[
        "# ecCKD Original Objective Terms",
        "",
        "Status: **$(result.status)**",
        "",
        result.objective_contract,
        "",
        "Implementation status: `$(result.implementation_status)`",
        "",
        "## Fixed Pass Sequences",
        "",
        "| Kind | Application | Band structure | Tolerances | Common options | Modes |",
        "|---|---|---|---|---|---|",
        "| longwave | $(result.pass_sequences.longwave.application) | $(result.pass_sequences.longwave.band_structure) | $(join(result.pass_sequences.longwave.tolerances, ", ")) | `$(result.pass_sequences.longwave.selected_common_options)` | $(join(result.pass_sequences.longwave.optimize_modes, " -> ")) |",
        "| shortwave | $(result.pass_sequences.shortwave.application) | $(result.pass_sequences.shortwave.band_structure) | $(join(result.pass_sequences.shortwave.tolerances, ", ")) | `$(result.pass_sequences.shortwave.selected_common_options)` | $(join(result.pass_sequences.shortwave.optimize_modes, " -> ")) |",
        "",
        "## Objective Terms",
        "",
        "| Kind | Term | Present | Source line | Description |",
        "|---|---|---:|---:|---|",
    ]
    for (kind, section) in (("longwave", result.longwave), ("shortwave", result.shortwave))
        for term in section.terms
            push!(lines, "| $kind | `$(term.name)` | $(term.present) | $(term.source_line) | $(term.description) |")
        end
    end
    push!(lines, "", "## Pass Details", "")
    for (kind, sequence) in (("longwave", result.pass_sequences.longwave),
                             ("shortwave", result.pass_sequences.shortwave))
        push!(lines, "### $(kind)")
        push!(lines, "")
        push!(lines, "| Mode | Present | Gases | Training files | Specific options | Extra args |")
        push!(lines, "|---|---:|---|---|---|---|")
        for row in sequence.passes
            push!(lines, "| `$(row.mode)` | $(row.present) | `$(row.gaslist)` | `$(row.training)` | `$(row.specific_options)` | `$(row.extra_args)` |")
        end
        push!(lines, "")
    end
    push!(lines, "Next required work:")
    append!(lines, ["- $item" for item in result.next_required_work])
    return join(lines, "\n") * "\n"
end

function main()
    result = original_objective_terms()
    mkpath(dirname(ORIGINAL_OBJECTIVE_TERMS_JSON))
    write(ORIGINAL_OBJECTIVE_TERMS_JSON, json_object(result) * "\n")
    write(ORIGINAL_OBJECTIVE_TERMS_MD, markdown_report(result))
    print(markdown_report(result))
    println("Wrote $ORIGINAL_OBJECTIVE_TERMS_JSON")
    println("Wrote $ORIGINAL_OBJECTIVE_TERMS_MD")
    result.status == "objective_terms_captured" ||
        error("ecCKD original objective term capture incomplete")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
