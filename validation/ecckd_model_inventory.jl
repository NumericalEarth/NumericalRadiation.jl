include(joinpath(@__DIR__, "validation_results.jl"))

using Dates

const ABR_ROOT = normpath(joinpath(@__DIR__, ".."))
if Base.find_package("NumericalRadiation") === nothing
    push!(LOAD_PATH, ABR_ROOT)
end

using NumericalRadiation
using NCDatasets

const INVENTORY_JSON = validation_results_path("ecckd_model_inventory.json")
const INVENTORY_MD = validation_results_path("ecckd_model_inventory.md")

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

function model_kind(summary)
    if summary.lw_gpoints > 0
        return "longwave"
    elseif summary.sw_gpoints > 0
        return "shortwave"
    else
        return "unknown"
    end
end

function inventory_entry(filename)
    path = official_ecckd_definition_path(filename)
    definition = read_ecckd_definition(path)
    valid, errors = validate_ecckd_definition(definition; throw_on_error = false)
    summary = summarize_ecckd_definition(definition)
    kind = model_kind(summary)
    gpoints = kind == "longwave" ? summary.lw_gpoints : summary.sw_gpoints
    bands = kind == "longwave" ? summary.lw_bands : summary.sw_bands
    return (
        filename = filename,
        path = path,
        kind = kind,
        model_name = summary.model_name,
        version = summary.version,
        bands = bands,
        gpoints = gpoints,
        gases = summary.gases,
        pressure_grid_size = summary.pressure_grid_size,
        temperature_grid_size = summary.temperature_grid_size,
        source_tables_present = summary.source_tables_present,
        rayleigh_tables_present = summary.rayleigh_tables_present,
        valid_schema = valid,
        schema_errors = errors,
    )
end

function run_ecckd_model_inventory()
    entries = [inventory_entry(filename) for filename in official_ecckd_model_inventory()]
    return (
        case = "ecckd_model_inventory",
        timestamp_utc = string(Dates.now()),
        status = all(entry -> entry.valid_schema, entries) ? "passed" : "failed",
        ecrad_data_path = ecrad_data_path(require = true),
        entries = entries,
    )
end

function markdown_inventory(result)
    lines = String[
        "# ecCKD Model Inventory",
        "",
        "Status: **$(result.status)**",
        "",
        "ecRad data path: `$(result.ecrad_data_path)`",
        "",
        "| File | Kind | Bands | G-points | Gases | Source tables | Rayleigh tables |",
        "|---|---|---:|---:|---|---:|---:|",
    ]
    for entry in result.entries
        gases = join(entry.gases, ", ")
        push!(lines, "| `$(entry.filename)` | $(entry.kind) | $(entry.bands) | $(entry.gpoints) | $(gases) | $(entry.source_tables_present) | $(entry.rayleigh_tables_present) |")
    end
    return join(lines, "\n") * "\n"
end

function ecckd_model_inventory_main()
    result = run_ecckd_model_inventory()
    mkpath(dirname(INVENTORY_JSON))
    write(INVENTORY_JSON, json_object(result) * "\n")
    write(INVENTORY_MD, markdown_inventory(result))
    print(markdown_inventory(result))
    println("Wrote $INVENTORY_JSON")
    println("Wrote $INVENTORY_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_model_inventory_main()
end
