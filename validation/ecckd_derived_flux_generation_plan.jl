include(joinpath(@__DIR__, "validation_results.jl"))

using Dates

include(joinpath(@__DIR__, "ckdmip_training_data_preflight.jl"))

const DERIVED_FLUX_PLAN_JSON =
    validation_results_path("ecckd_derived_flux_generation_plan.json")
const DERIVED_FLUX_PLAN_MD =
    validation_results_path("ecckd_derived_flux_generation_plan.md")

function derived_flux_descriptor(path)
    m = match(r"^(evaluation[12])/(lw|sw)_fluxes/(ckdmip_[^/]+_fluxes_([A-Za-z0-9-]+)\.h5)$", path)
    m === nothing && throw(ArgumentError("not a derived ecCKD flux path: $(path)"))
    dataset, domain, filename, scenario = m.captures
    return (
        path = path,
        filename = filename,
        dataset = dataset,
        domain = domain,
        scenario = scenario,
        scenario_family = startswith(scenario, "5gas-") ? "5gas" :
                          startswith(scenario, "rel-") ? "rel" :
                          "other",
        evaluation_script = "test/run_$(domain)_lbl_evaluation.sh",
        copy_script = "test/copy_to_ckdmip_$(domain).sh",
    )
end

function raw_chunk_files(root, descriptor)
    root === nothing && return String[]
    directory = joinpath(root, descriptor.dataset, "$(descriptor.domain)_fluxes")
    isdir(directory) || return String[]
    stem = replace(descriptor.filename, ".h5" => "")
    prefix = "RAW_$(stem)_"
    chunks = [
        joinpath(directory, name) for name in readdir(directory)
        if startswith(name, prefix) && endswith(name, ".h5")
    ]
    return sort(chunks)
end

function expected_raw_chunk_count(root, descriptor)
    root === nothing && return 0
    spectra_dir = joinpath(root, descriptor.dataset, "$(descriptor.domain)_spectra")
    isdir(spectra_dir) || return 0
    prefix = "ckdmip_$(descriptor.dataset)_$(descriptor.domain)_spectra_h2o_present_"
    return count(name -> startswith(name, prefix) && endswith(name, ".h5"),
                 readdir(spectra_dir))
end

function derived_flux_progress(root, entry)
    descriptor = derived_flux_descriptor(entry.path)
    chunks = raw_chunk_files(root, descriptor)
    expected_chunks = expected_raw_chunk_count(root, descriptor)
    final_path = root === nothing ? nothing : joinpath(root, descriptor.path)
    final_present = root !== nothing && isfile(final_path)
    raw_bytes = sum(path -> filesize(path), chunks; init = 0)
    final_bytes = final_present ? filesize(final_path) : 0
    progress_state = final_present ? "final_present" :
                     !isempty(chunks) ? "raw_chunks_present" :
                     "missing"
    return merge(descriptor, (
        final_present = final_present,
        final_path = final_path,
        final_bytes = final_bytes,
        expected_raw_chunk_count = expected_chunks,
        raw_chunk_count = length(chunks),
        missing_raw_chunk_count = max(expected_chunks - length(chunks), 0),
        raw_chunk_bytes = raw_bytes,
        first_raw_chunk_unix_time = isempty(chunks) ? nothing :
                                    minimum(path -> stat(path).mtime, chunks),
        latest_raw_chunk_unix_time = isempty(chunks) ? nothing :
                                     maximum(path -> stat(path).mtime, chunks),
        raw_chunks = chunks,
        progress_state = progress_state,
    ))
end

function raw_chunk_rate_summary(progress)
    raw_times = Float64[]
    for entry in progress
        entry.first_raw_chunk_unix_time === nothing || push!(raw_times, entry.first_raw_chunk_unix_time)
        entry.latest_raw_chunk_unix_time === nothing || push!(raw_times, entry.latest_raw_chunk_unix_time)
    end
    present = sum(entry -> entry.raw_chunk_count, progress; init = 0)
    expected = sum(entry -> entry.expected_raw_chunk_count, progress; init = 0)
    remaining = max(expected - present, 0)
    if isempty(raw_times) || present == 0
        return (
            first_raw_chunk_at_utc = nothing,
            latest_raw_chunk_at_utc = nothing,
            observed_raw_chunk_rate_per_hour = nothing,
            estimated_hours_remaining = nothing,
        )
    end
    first_time = minimum(raw_times)
    latest_time = maximum(raw_times)
    elapsed_hours = max((time() - first_time) / 3600, 1.0 / 3600)
    rate = present / elapsed_hours
    return (
        first_raw_chunk_at_utc = string(unix2datetime(first_time)),
        latest_raw_chunk_at_utc = string(unix2datetime(latest_time)),
        observed_raw_chunk_rate_per_hour = rate,
        estimated_hours_remaining = rate > 0 ? remaining / rate : nothing,
    )
end

function scenario_sort_key(scenario)
    m = match(r"^(5gas|rel)-([0-9]+)$", scenario)
    m === nothing && return (3, scenario, 0)
    family, value = m.captures
    return (family == "5gas" ? 1 : 2, "", parse(Int, value))
end

function unique_scenarios(descriptors, domain)
    scenarios = [entry.scenario for entry in descriptors if entry.domain == domain]
    return sort(unique(scenarios); by = scenario_sort_key)
end

function script_rows(ecckd_root)
    scripts = [
        "test/run_lw_lbl_evaluation.sh",
        "test/run_sw_lbl_evaluation.sh",
        "test/copy_to_ckdmip_lw.sh",
        "test/copy_to_ckdmip_sw.sh",
        "test/config.h",
    ]
    return [(path = path, present = isfile(joinpath(ecckd_root, path))) for path in scripts]
end

function executable_path(name)
    for directory in split(get(ENV, "PATH", ""), ':')
        isempty(directory) && continue
        candidate = joinpath(directory, name)
        if isfile(candidate) && (stat(candidate).mode & 0o111) != 0
            return candidate
        end
    end
    return nothing
end

function ncrcat_status()
    path = executable_path("ncrcat")
    present = path !== nothing
    shim = false
    uses_julia_concat = false
    if present
        text = try
            read(path, String)
        catch
            ""
        end
        shim = occursin("concat_ckdmip_flux_chunks.jl", text)
        uses_julia_concat = shim && occursin("julia", text)
    end
    return (
        present = present,
        path = path,
        julia_concat_shim = shim,
        uses_julia_concat = uses_julia_concat,
        note = present ?
               (shim ? "ncrcat resolves to the Julia concat shim used for CKDMIP raw chunk assembly." :
                "ncrcat resolves to a system executable; verify it can concatenate the generated HDF5 chunks.") :
               "ncrcat is not on PATH. The ecCKD evaluation scripts will fail at raw chunk concatenation unless the launcher patches them or a shim is installed.",
    )
end

function suggested_commands(ecckd_root, preflight, descriptors)
    ckdmip_root = preflight.ckdmip_data_root === nothing ? "\$RH_CKDMIP_DATA_PATH" : preflight.ckdmip_data_root
    workdir = get(ENV, "RH_ECCKD_LBL_WORKDIR", joinpath(homedir(), "ecckd-derived-flux-work"))
    commands = String[
        "RH_ECCKD_DERIVED_FLUX_DRY_RUN=true RH_CKDMIP_DATA_PATH=$(ckdmip_root) RH_ECCKD_SOURCE_PATH=$(ecckd_root) RH_ECCKD_LBL_WORKDIR=$(workdir) bash validation/generate_ecckd_derived_fluxes.sh",
        "RH_ECCKD_DERIVED_FLUX_DRY_RUN=false RH_CKDMIP_DATA_PATH=$(ckdmip_root) RH_ECCKD_SOURCE_PATH=$(ecckd_root) RH_ECCKD_LBL_WORKDIR=$(workdir) RH_CKDMIP_TOOL_DIR=/path/to/ckdmip/bin bash validation/generate_ecckd_derived_fluxes.sh",
    ]
    lw = unique_scenarios(descriptors, "lw")
    sw = unique_scenarios(descriptors, "sw")
    if !isempty(lw)
        push!(commands, "# The launcher patches run_lw_lbl_evaluation.sh to SCENARIOS=\"$(join(lw, " "))\".")
    end
    if !isempty(sw)
        push!(commands, "# The launcher patches run_sw_lbl_evaluation.sh to SCENARIOS=\"$(join(sw, " "))\".")
    end
    push!(commands, "RH_CKDMIP_DATA_PATH=\"\$RH_CKDMIP_DATA_PATH\" julia --project=test validation/ckdmip_training_data_preflight.jl")
    return commands
end

function run_ecckd_derived_flux_generation_plan()
    preflight = run_ckdmip_training_data_preflight()
    ecckd_root = run_ecckd_published_training_manifest().ecckd_source_root
    progress = [
        derived_flux_progress(preflight.ckdmip_data_root, entry)
        for entry in preflight.derived_training_flux_products
    ]
    missing_products = [entry for entry in progress if !entry.final_present]
    upstream_ready = isempty(preflight.blockers)
    status = preflight.status == "ready_for_original_ecckd_objective" ? "ready_for_original_ecckd_objective" :
             upstream_ready ? "derived_flux_generation_required" :
             preflight.status
    raw_chunk_products = [entry for entry in progress if entry.raw_chunk_count > 0 && !entry.final_present]
    expected_raw_chunks = sum(entry -> entry.expected_raw_chunk_count, progress; init = 0)
    present_raw_chunks = sum(entry -> entry.raw_chunk_count, progress; init = 0)
    completed_equivalent_raw_chunks = sum(
        entry -> entry.final_present ? entry.expected_raw_chunk_count : entry.raw_chunk_count,
        progress;
        init = 0,
    )
    raw_chunk_rate = raw_chunk_rate_summary(progress)
    return (
        case = "ecckd_derived_flux_generation_plan",
        timestamp_utc = string(Dates.now()),
        status = status,
        ckdmip_data_root = preflight.ckdmip_data_root,
        ecckd_source_root = ecckd_root,
        upstream_preflight_status = preflight.status,
        upstream_blockers = preflight.blockers,
        expected_derived_flux_count = length(progress),
        present_derived_flux_count = count(entry -> entry.final_present, progress),
        raw_chunk_product_count = length(raw_chunk_products),
        expected_raw_chunk_count = expected_raw_chunks,
        present_raw_chunk_count = present_raw_chunks,
        completed_equivalent_raw_chunk_count = completed_equivalent_raw_chunks,
        raw_chunk_rate = raw_chunk_rate,
        missing_derived_flux_count = length(missing_products),
        derived_flux_progress = progress,
        missing_derived_flux_products = missing_products,
        lw_scenarios = unique_scenarios(progress, "lw"),
        sw_scenarios = unique_scenarios(progress, "sw"),
        required_ecckd_scripts = script_rows(ecckd_root),
        ncrcat = ncrcat_status(),
        suggested_working_copy_commands = suggested_commands(ecckd_root, preflight, progress),
        note = "The 5gas-* and rel-* flux products are generated ecCKD training targets, not public CKDMIP archive files. Generate them in a writable ecCKD working copy, then rerun the CKDMIP preflight.",
    )
end

function markdown_derived_flux_plan(result)
    lines = String[
        "# ecCKD Derived Flux Generation Plan",
        "",
        "Status: **$(result.status)**",
        "",
        "CKDMIP data root: `$(result.ckdmip_data_root)`",
        "",
        "ecCKD source root: `$(result.ecckd_source_root)`",
        "",
        result.note,
        "",
        "## Progress",
        "",
        "- Expected derived flux products: $(result.expected_derived_flux_count)",
        "- Final products present: $(result.present_derived_flux_count)",
        "- Products with raw chunks present: $(result.raw_chunk_product_count)",
        "- Raw chunks present: $(result.present_raw_chunk_count)/$(result.expected_raw_chunk_count)",
        "- Completed-equivalent raw chunks: $(result.completed_equivalent_raw_chunk_count)/$(result.expected_raw_chunk_count)",
        "- Observed raw chunk rate: `$(result.raw_chunk_rate.observed_raw_chunk_rate_per_hour)` chunks/hour",
        "- Estimated raw chunk hours remaining: `$(result.raw_chunk_rate.estimated_hours_remaining)`",
        "",
        "## Missing Derived Products",
        "",
        "Missing derived flux products: $(result.missing_derived_flux_count)",
        "",
    ]
    if isempty(result.missing_derived_flux_products)
        push!(lines, "None.")
    else
        push!(lines, "| Path | Domain | Scenario | Script |")
        push!(lines, "|---|---|---|---|")
        for entry in result.missing_derived_flux_products
            push!(lines, "| `$(entry.path)` | `$(entry.domain)` | `$(entry.scenario)` | `$(entry.evaluation_script)` |")
        end
    end
    push!(lines, "", "## Raw Chunk Progress", "")
    chunk_rows = [entry for entry in result.derived_flux_progress if entry.raw_chunk_count > 0]
    if isempty(chunk_rows)
        push!(lines, "No raw chunks are present yet.")
    else
        push!(lines, "| Path | Final present | Raw chunks | Missing chunks | Raw bytes |")
        push!(lines, "|---|---:|---:|---:|---:|")
        for entry in chunk_rows
            push!(lines, "| `$(entry.path)` | $(entry.final_present) | $(entry.raw_chunk_count)/$(entry.expected_raw_chunk_count) | $(entry.missing_raw_chunk_count) | $(entry.raw_chunk_bytes) |")
        end
    end
    push!(lines, "", "## Required ecCKD Scripts", "", "| Path | Present |", "|---|---:|")
    for script in result.required_ecckd_scripts
        push!(lines, "| `$(script.path)` | $(script.present) |")
    end
    push!(lines, "", "## Concatenation Tool", "")
    push!(lines, "- `ncrcat` present: $(result.ncrcat.present)")
    push!(lines, "- `ncrcat` path: `$(result.ncrcat.path)`")
    push!(lines, "- Julia concat shim: $(result.ncrcat.julia_concat_shim)")
    push!(lines, "- Note: $(result.ncrcat.note)")
    push!(lines, "", "## Scenario Batches", "")
    push!(lines, "- LW scenarios: `$(join(result.lw_scenarios, " "))`")
    push!(lines, "- SW scenarios: `$(join(result.sw_scenarios, " "))`")
    push!(lines, "", "## Suggested Working-Copy Commands", "")
    push!(lines, "```sh")
    append!(lines, result.suggested_working_copy_commands)
    push!(lines, "```")
    if !isempty(result.upstream_blockers)
        push!(lines, "", "## Upstream Blockers", "")
        append!(lines, ["- $(blocker)" for blocker in result.upstream_blockers])
    end
    return join(lines, "\n") * "\n"
end

function ecckd_derived_flux_generation_plan_main()
    result = run_ecckd_derived_flux_generation_plan()
    mkpath(dirname(DERIVED_FLUX_PLAN_JSON))
    write(DERIVED_FLUX_PLAN_JSON, json_object(result) * "\n")
    write(DERIVED_FLUX_PLAN_MD, markdown_derived_flux_plan(result))
    print(markdown_derived_flux_plan(result))
    println("Wrote $DERIVED_FLUX_PLAN_JSON")
    println("Wrote $DERIVED_FLUX_PLAN_MD")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_derived_flux_generation_plan_main()
end
