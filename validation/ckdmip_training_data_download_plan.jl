include(joinpath(@__DIR__, "validation_results.jl"))

using Dates

const DOWNLOAD_PLAN_JSON =
    validation_results_path("ckdmip_training_data_download_plan.json")
const DOWNLOAD_PLAN_MD =
    validation_results_path("ckdmip_training_data_download_plan.md")

const CKDMIP_BASE_URL = "https://aux.ecmwf.int/ecpds/home/ckdmip"

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

function download_task(source_path, destination_path; recursive = true)
    url = recursive ? "$(CKDMIP_BASE_URL)/$(source_path)/" : "$(CKDMIP_BASE_URL)/$(source_path)"
    command = recursive ?
        "mkdir -p \"\$RH_CKDMIP_DATA_PATH/$(destination_path)\" && wget -r -np -nd -R 'index.html*' -P \"\$RH_CKDMIP_DATA_PATH/$(destination_path)\" \"$(url)\"" :
        "mkdir -p \"\$RH_CKDMIP_DATA_PATH/$(dirname(destination_path))\" && wget -c -O \"\$RH_CKDMIP_DATA_PATH/$(destination_path)\" \"$(url)\""
    return (
        source = url,
        destination = destination_path,
        recursive = recursive,
        command = command,
    )
end

function local_task(description, destination_path, command)
    return (
        source = description,
        destination = destination_path,
        recursive = false,
        command = command,
    )
end

function run_ckdmip_training_data_download_plan()
    concentration_files = [
        ("concentrations/ckdmip_mmm_concentrations.nc", "mmm/conc/ckdmip_mmm_concentrations.nc"),
        ("concentrations/ckdmip_idealized_concentrations.nc", "idealized/conc/ckdmip_idealized_concentrations.nc"),
    ]
    for dataset in ("evaluation1", "evaluation2")
        for scenario in (
            "present", "preindustrial", "future", "glacialmax",
            "co2-180", "co2-280", "co2-560", "co2-1120", "co2-2240",
            "ch4-350", "ch4-700", "ch4-1200", "ch4-2600", "ch4-3500",
            "n2o-190", "n2o-270", "n2o-405", "n2o-540",
            "cfc11-0", "cfc11-2000", "cfc12-0", "cfc12-550",
            "co2-180-ch4-350", "co2-180-ch4-3500",
            "co2-2240-ch4-350", "co2-2240-ch4-3500",
            "co2-180-n2o-190", "co2-180-n2o-540",
            "co2-2240-n2o-190", "co2-2240-n2o-540",
            "ch4-350-n2o-190", "ch4-350-n2o-540",
            "ch4-3500-n2o-190", "ch4-3500-n2o-540",
        )
            name = "ckdmip_$(dataset)_concentrations_$(scenario).nc"
            push!(concentration_files, ("concentrations/$(name)", "$(dataset)/conc/$(name)"))
        end
    end

    tasks = NamedTuple[]
    append!(tasks, [download_task(source, destination; recursive = false)
                    for (source, destination) in concentration_files])
    for dataset in ("mmm", "idealized", "evaluation1", "evaluation2")
        push!(tasks, download_task("lw_spectra/$(dataset)", "$(dataset)/lw_spectra"))
        push!(tasks, download_task("sw_spectra/$(dataset)", "$(dataset)/sw_spectra"))
    end
    push!(tasks, local_task(
        "local symlink to CKDMIP solar spectral irradiance file",
        "mmm/sw_spectra_extras/ckdmip_ssi.h5",
        "mkdir -p \"\$RH_CKDMIP_DATA_PATH/mmm/sw_spectra_extras\" && ln -sf \"../../evaluation1/sw_spectra/ckdmip_ssi.h5\" \"\$RH_CKDMIP_DATA_PATH/mmm/sw_spectra_extras/ckdmip_ssi.h5\"",
    ))
    for dataset in ("evaluation1", "evaluation2")
        push!(tasks, download_task("lw_fluxes/$(dataset)", "$(dataset)/lw_fluxes"))
        push!(tasks, download_task("sw_fluxes/$(dataset)", "$(dataset)/sw_fluxes"))
    end

    return (
        case = "ckdmip_training_data_download_plan",
        timestamp_utc = string(Dates.now()),
        status = "manual_or_batch_download_required",
        base_url = CKDMIP_BASE_URL,
        target_env = "RH_CKDMIP_DATA_PATH",
        warning =
            "This plan intentionally does not run downloads. The full CKDMIP LBL database is hundreds of GB to about 1 TB and should be materialized by an explicit user or batch job.",
        expected_layout_roots = (
            "mmm/conc", "mmm/lw_spectra", "mmm/sw_spectra", "mmm/sw_spectra_extras",
            "idealized/conc", "idealized/lw_spectra", "idealized/sw_spectra",
            "evaluation1/conc", "evaluation1/lw_spectra", "evaluation1/sw_spectra",
            "evaluation1/lw_fluxes", "evaluation1/sw_fluxes",
            "evaluation2/conc", "evaluation2/lw_spectra", "evaluation2/sw_spectra",
            "evaluation2/lw_fluxes", "evaluation2/sw_fluxes",
        ),
        task_count = length(tasks),
        tasks = tasks,
    )
end

function markdown_plan(result)
    lines = String[
        "# CKDMIP Training Data Download Plan",
        "",
        "Status: **$(result.status)**",
        "",
        result.warning,
        "",
        "Set `$(result.target_env)` to a large scratch/data directory before running any command.",
        "",
        "Base URL: `$(result.base_url)`",
        "",
        "Tasks: $(result.task_count)",
        "",
        "## Expected Layout",
        "",
    ]
    append!(lines, ["- `$(root)`" for root in result.expected_layout_roots])
    push!(lines, "", "## Commands", "")
    push!(lines, "```bash")
    push!(lines, "test -n \"\$RH_CKDMIP_DATA_PATH\"")
    for task in result.tasks
        push!(lines, task.command)
    end
    push!(lines, "```")
    return join(lines, "\n") * "\n"
end

function ckdmip_training_data_download_plan_main()
    result = run_ckdmip_training_data_download_plan()
    mkpath(dirname(DOWNLOAD_PLAN_JSON))
    write(DOWNLOAD_PLAN_JSON, json_object(result) * "\n")
    write(DOWNLOAD_PLAN_MD, markdown_plan(result))
    print(markdown_plan(result))
    println("Wrote $DOWNLOAD_PLAN_JSON")
    println("Wrote $DOWNLOAD_PLAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ckdmip_training_data_download_plan_main()
end
