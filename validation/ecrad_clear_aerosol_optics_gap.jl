include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "ecrad_all_sky_optics_gap.jl"))

const CLEAR_AEROSOL_OPTICS_ENV = Dict(
    "RH_CANDIDATE_GAS_OPTICS" => "official_ecckd",
    "RH_AEROSOL_OPTICS" => "true",
    "RH_IFS_AEROSOL_TABLE_OPTICS" => "true",
    "RH_AEROSOL_DELTA_EDDINGTON_SCALE" => "true",
    "RH_IFS_AEROSOL_LAYER_RELATIVE_HUMIDITY" => "true",
    "RH_CLOUD_SCATTERING_TABLE_OPTICS" => "false",
    "RH_CLOUD_EFFECTIVE_RADIUS_OPTICS" => "false",
)

function with_clear_aerosol_optics_env(f)
    previous = Dict(key => get(ENV, key, nothing) for key in keys(CLEAR_AEROSOL_OPTICS_ENV))
    try
        for (key, value) in CLEAR_AEROSOL_OPTICS_ENV
            ENV[key] = value
        end
        return f()
    finally
        for (key, value) in previous
            if value === nothing
                delete!(ENV, key)
            else
                ENV[key] = value
            end
        end
    end
end

function clear_aerosol_optics_gap_rows(reference, properties, candidate)
    original_columns = round.(Int, Array(reference["column"]))
    mapping = (
        (reference = "od_lw", candidate = "od_lw", units = "1"),
        (reference = "od_sw", candidate = "od_sw", units = "1"),
        (reference = "ssa_sw", candidate = "ssa_sw", units = "1"),
        (reference = "asymmetry_sw", candidate = "asymmetry_sw", units = "1"),
    )
    rows = NamedTuple[]
    push_optics_gap_rows!(rows, properties, candidate, original_columns,
                          "clear_gas_aerosol", mapping)
    return rows
end

function run_clear_aerosol_optics_gap()
    return with_clear_aerosol_optics_env() do
        NCDATASETS.NCDataset(reference_path(ALL_SKY_REFERENCE)) do reference
            NCDATASETS.NCDataset(reference_path(ECRAD_ALL_SKY_PROPERTIES)) do properties
                candidate = candidate_all_sky_optics(reference)
                return (
                    case = "ecrad_clear_aerosol_optics_gap",
                    date = string(Dates.now()),
                    reference_case = ALL_SKY_REFERENCE,
                    ecrad_properties = ECRAD_ALL_SKY_PROPERTIES,
                    candidate_configuration = [
                        (variable = key, value = CLEAR_AEROSOL_OPTICS_ENV[key])
                        for key in sort(collect(keys(CLEAR_AEROSOL_OPTICS_ENV)))
                    ],
                    rows = clear_aerosol_optics_gap_rows(reference, properties, candidate),
                )
            end
        end
    end
end

function markdown_clear_aerosol_optics_gap(result)
    lines = String[
        "# ecRad Clear Aerosol Optics Gap",
        "",
        "This diagnostic compares generated clear gas+aerosol optical properties against ecRad's saved all-sky clear optical properties.",
        "",
        "| Candidate kind | Variable | RMSE | Max abs | Mean bias | Mean abs | Reference mean | Candidate mean |",
        "|---|---|---:|---:|---:|---:|---:|---:|",
    ]
    for row in result.rows
        push!(lines, "| `$(row.candidate_kind)` | `$(row.variable)` | $(@sprintf("%.12g", row.rmse)) | $(@sprintf("%.12g", row.max_abs)) | $(@sprintf("%.12g", row.mean_bias)) | $(@sprintf("%.12g", row.mean_abs)) | $(@sprintf("%.12g", row.reference_mean)) | $(@sprintf("%.12g", row.candidate_mean)) |")
    end
    append!(lines, [
        "",
        "## Candidate Configuration",
        "",
        "| Environment variable | Value |",
        "|---|---|",
    ])
    for row in result.candidate_configuration
        push!(lines, "| `$(row.variable)` | `$(row.value)` |")
    end
    return join(lines, "\n") * "\n"
end

function clear_aerosol_optics_gap_main()
    result = run_clear_aerosol_optics_gap()
    results_dir = validation_results_dir()
    mkpath(results_dir)
    json_path = joinpath(results_dir, "ecrad_clear_aerosol_optics_gap.json")
    md_path = joinpath(results_dir, "ecrad_clear_aerosol_optics_gap.md")
    write(json_path, json_object(result))
    write(md_path, markdown_clear_aerosol_optics_gap(result))
    print(markdown_clear_aerosol_optics_gap(result))
    println("Wrote $json_path")
    println("Wrote $md_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    clear_aerosol_optics_gap_main()
end
