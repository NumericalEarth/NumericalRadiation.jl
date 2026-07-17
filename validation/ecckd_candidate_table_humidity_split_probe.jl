include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

include(joinpath(@__DIR__, "ecckd_candidate_table_written_minimax_descent.jl"))

const CANDIDATE_TABLE_HUMIDITY_SPLIT_PROBE_JSON =
    validation_results_path("ecckd_candidate_table_humidity_split_probe.json")
const CANDIDATE_TABLE_HUMIDITY_SPLIT_PROBE_MD =
    validation_results_path("ecckd_candidate_table_humidity_split_probe.md")
const CANDIDATE_TABLE_HUMIDITY_SPLIT_FILE =
    validation_results_path("ecckd_table_humidity_split_sw32_candidate.nc")

function coordinate_descent_parameters()
    if isfile(CANDIDATE_TABLE_WRITTEN_COORDINATE_DESCENT_JSON)
        data = JSON.parsefile(CANDIDATE_TABLE_WRITTEN_COORDINATE_DESCENT_JSON)
        params = local_json_get(data, "final_log_parameters", nothing)
        params isa AbstractVector && length(params) == 4 && return Float64.(params)
    end
    return written_coordinate_scan_seed_parameters()
end

function humidity_split_initial_parameters()
    base = coordinate_descent_parameters()
    return [base[1], base[1], base[2], base[3], base[4]]
end

function write_humidity_split_shortwave_candidate(reference_path, candidate_path,
                                                  log_parameters)
    cp(reference_path, candidate_path; force = true)
    chmod(candidate_path, 0o644)
    dry_h2o_scale = exp(log_parameters[1])
    moist_h2o_scale = exp(log_parameters[2])
    co2_scale = exp(log_parameters[3])
    rayleigh_scale = exp(log_parameters[4])
    weight_scale = exp(log_parameters[5])
    NCDataset(candidate_path, "a") do ds
        if haskey(ds, "h2o_molar_absorption_coeff")
            values = Array(ds["h2o_molar_absorption_coeff"])
            split = max(1, size(values, 4) ÷ 2)
            values[:, :, :, 1:split] .*= dry_h2o_scale
            values[:, :, :, (split + 1):end] .*= moist_h2o_scale
            ds["h2o_molar_absorption_coeff"][:] = values
        end
        if haskey(ds, "co2_molar_absorption_coeff")
            ds["co2_molar_absorption_coeff"][:] =
                Array(ds["co2_molar_absorption_coeff"]) .* co2_scale
        end
        if haskey(ds, "rayleigh_molar_scattering_coeff")
            ds["rayleigh_molar_scattering_coeff"][:] =
                Array(ds["rayleigh_molar_scattering_coeff"]) .* rayleigh_scale
        end
        if haskey(ds, "solar_irradiance")
            ds["solar_irradiance"][:] = Array(ds["solar_irradiance"]) .* weight_scale
        end
    end
    return candidate_path
end

function humidity_split_score(root, reference_path, candidate_path, parameters,
                              scenarios; column = 1, mu0_index = 1)
    write_humidity_split_shortwave_candidate(reference_path, candidate_path, parameters)
    writeback = run_table_writeback_multisample(;
        root,
        reference_path,
        candidate_path,
        scenarios,
        column,
        mu0_index,
    )
    present_rows = filter(row -> row.present, writeback.rows)
    aggregate_loss = isempty(present_rows) ? Inf :
                     sum(row.candidate_loss for row in present_rows) / length(present_rows)
    return (
        parameters = collect(parameters),
        aggregate_loss = aggregate_loss,
        status = writeback.status,
        improved_count = writeback.improved_count,
        present_count = writeback.present_count,
        worst_loss_ratio = writeback.worst_loss_ratio,
        rows = writeback.rows,
    )
end

function aggregate_better(candidate, incumbent)
    candidate_all = candidate.improved_count == candidate.present_count
    incumbent_all = incumbent.improved_count == incumbent.present_count
    candidate_all && !incumbent_all && return true
    candidate_all == incumbent_all || return false
    candidate.aggregate_loss < incumbent.aggregate_loss && return true
    candidate.aggregate_loss == incumbent.aggregate_loss &&
        candidate.worst_loss_ratio < incumbent.worst_loss_ratio && return true
    return false
end

function run_table_humidity_split_probe(; root = ckdmip_data_root(),
                                        reference_path = VECTOR_TRAINING_CANDIDATE,
                                        candidate_path =
                                            CANDIDATE_TABLE_HUMIDITY_SPLIT_FILE,
                                        scenarios = ("rel-180", "rel-415", "rel-1120"),
                                        initial_parameters =
                                            humidity_split_initial_parameters(),
                                        deltas = (-0.1, -0.03162277660168379,
                                                  -0.01, 0.01,
                                                  0.03162277660168379, 0.1),
                                        column = 1,
                                        mu0_index = 1)
    if root === nothing
        return (
            case = "ecckd_candidate_table_humidity_split_probe",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    if !isfile(reference_path)
        return (
            case = "ecckd_candidate_table_humidity_split_probe",
            timestamp_utc = string(Dates.now()),
            status = "missing_input",
            blockers = ["Missing input: $(reference_path)"],
        )
    end

    seed = humidity_split_score(root, reference_path, candidate_path,
                                initial_parameters, scenarios; column, mu0_index)
    best_aggregate = seed
    best_minimax = seed
    rows = NamedTuple[]
    for index in 1:2
        for delta in deltas
            parameters = copy(initial_parameters)
            parameters[index] = clamp(parameters[index] + delta, -2.0, 2.0)
            score = humidity_split_score(root, reference_path, candidate_path,
                                         parameters, scenarios; column, mu0_index)
            push!(rows, merge(score, (coordinate = index, delta = delta)))
            aggregate_better(score, best_aggregate) && (best_aggregate = score)
            minimax_better(score, best_minimax) && (best_minimax = score)
        end
    end
    write_humidity_split_shortwave_candidate(reference_path, candidate_path,
                                             best_aggregate.parameters)
    aggregate_improved = best_aggregate.aggregate_loss < seed.aggregate_loss
    minimax_improved = best_minimax.worst_loss_ratio < seed.worst_loss_ratio
    status = aggregate_improved || minimax_improved ?
             "humidity_split_probe_improved" :
             "humidity_split_probe_no_descent"
    return (
        case = "ecckd_candidate_table_humidity_split_probe",
        timestamp_utc = string(Dates.now()),
        status = status,
        reference_path = reference_path,
        candidate_path = candidate_path,
        scenario_count = length(scenarios),
        present_count = seed.present_count,
        tested_move_count = length(rows),
        seed_aggregate_loss = seed.aggregate_loss,
        seed_worst_loss_ratio = seed.worst_loss_ratio,
        best_aggregate_loss = best_aggregate.aggregate_loss,
        best_aggregate_worst_loss_ratio = best_aggregate.worst_loss_ratio,
        best_minimax_aggregate_loss = best_minimax.aggregate_loss,
        best_minimax_worst_loss_ratio = best_minimax.worst_loss_ratio,
        aggregate_loss_reduction_factor =
            seed.aggregate_loss / max(best_aggregate.aggregate_loss, eps(Float64)),
        worst_loss_ratio_reduction_factor =
            seed.worst_loss_ratio / max(best_minimax.worst_loss_ratio, eps(Float64)),
        seed_parameters = collect(initial_parameters),
        best_aggregate_parameters = collect(best_aggregate.parameters),
        best_minimax_parameters = collect(best_minimax.parameters),
        best_aggregate_rows = best_aggregate.rows,
        best_minimax_rows = best_minimax.rows,
        scan_rows = rows,
        blockers = String[],
        interpretation =
            "This writes and rereads one-step dry/moist H2O split-table moves. It tests whether humidity-aware table parameters can decouple low-/mid-humidity and high-humidity representative states; it is not published-model recovery.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_table_humidity_split_probe(result)
    lines = String[
        "# ecCKD Candidate Table Humidity-Split Probe",
        "",
        "Status: **$(result.status)**",
        "",
        "## Blockers",
        "",
    ]
    if isempty(result.blockers)
        push!(lines, "None.")
    else
        append!(lines, ["- $(blocker)" for blocker in result.blockers])
    end
    if hasproperty(result, :candidate_path)
        append!(lines, [
            "",
            "Candidate: `$(result.candidate_path)`",
            "",
            "## Probe Summary",
            "",
            "| Metric | Value |",
            "|---|---:|",
            "| Present scenarios | $(result.present_count)/$(result.scenario_count) |",
            "| Tested moves | $(result.tested_move_count) |",
            "| Seed aggregate loss | $(result.seed_aggregate_loss) |",
            "| Best aggregate loss | $(result.best_aggregate_loss) |",
            "| Aggregate loss reduction factor | $(result.aggregate_loss_reduction_factor) |",
            "| Seed worst loss ratio | $(result.seed_worst_loss_ratio) |",
            "| Best minimax worst loss ratio | $(result.best_minimax_worst_loss_ratio) |",
            "| Worst loss ratio reduction factor | $(result.worst_loss_ratio_reduction_factor) |",
            "",
            result.interpretation,
        ])
    end
    return join(lines, "\n") * "\n"
end

function ecckd_candidate_table_humidity_split_probe_main()
    result = run_table_humidity_split_probe()
    write_json(CANDIDATE_TABLE_HUMIDITY_SPLIT_PROBE_JSON, result)
    write(CANDIDATE_TABLE_HUMIDITY_SPLIT_PROBE_MD,
          markdown_table_humidity_split_probe(result))
    print(markdown_table_humidity_split_probe(result))
    println("Wrote $CANDIDATE_TABLE_HUMIDITY_SPLIT_PROBE_JSON")
    println("Wrote $CANDIDATE_TABLE_HUMIDITY_SPLIT_PROBE_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_candidate_table_humidity_split_probe_main()
end
