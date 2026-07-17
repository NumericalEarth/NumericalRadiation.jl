include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

include(joinpath(@__DIR__, "ecckd_candidate_table_multisample_optimizer.jl"))

const CANDIDATE_TABLE_WRITTEN_COORDINATE_SCAN_JSON =
    validation_results_path("ecckd_candidate_table_written_coordinate_scan.json")
const CANDIDATE_TABLE_WRITTEN_COORDINATE_SCAN_MD =
    validation_results_path("ecckd_candidate_table_written_coordinate_scan.md")
const CANDIDATE_TABLE_WRITTEN_COORDINATE_SCAN_FILE =
    validation_results_path("ecckd_table_written_coordinate_sw32_candidate.nc")

function selected_multisample_parameters()
    if isfile(CANDIDATE_TABLE_MULTISAMPLE_OPTIMIZER_JSON)
        data = JSON.parsefile(CANDIDATE_TABLE_MULTISAMPLE_OPTIMIZER_JSON)
        params = local_json_get(data, "selected_log_parameters", nothing)
        params isa AbstractVector && length(params) == 4 && return Float64.(params)
    end
    return table_multisample_seed_parameters()
end

function written_multisample_score(root, reference_path, candidate_path, parameters,
                                   scenarios; column = 1, mu0_index = 1)
    write_scaled_shortwave_candidate(reference_path, candidate_path, parameters)
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

function run_table_written_coordinate_scan(; root = ckdmip_data_root(),
                                           reference_path = VECTOR_TRAINING_CANDIDATE,
                                           candidate_path =
                                               CANDIDATE_TABLE_WRITTEN_COORDINATE_SCAN_FILE,
                                           scenarios = ("rel-180", "rel-415", "rel-1120"),
                                           initial_parameters =
                                               selected_multisample_parameters(),
                                           deltas = (-0.1, -0.03162277660168379,
                                                     -0.01, 0.01,
                                                     0.03162277660168379, 0.1),
                                           column = 1,
                                           mu0_index = 1)
    if root === nothing
        return (
            case = "ecckd_candidate_table_written_coordinate_scan",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    if !isfile(reference_path)
        return (
            case = "ecckd_candidate_table_written_coordinate_scan",
            timestamp_utc = string(Dates.now()),
            status = "missing_input",
            blockers = ["Missing input: $(reference_path)"],
        )
    end

    seed = written_multisample_score(root, reference_path, candidate_path,
                                     initial_parameters, scenarios; column, mu0_index)
    best = seed
    rows = NamedTuple[]
    seen = Set{Tuple{Vararg{Float64, 4}}}()
    for index in eachindex(initial_parameters)
        for delta in deltas
            parameters = clamp.(copy(initial_parameters), -2.0, 2.0)
            parameters[index] = clamp(parameters[index] + delta, -2.0, 2.0)
            key = Tuple(round.(parameters; digits = 12))
            key in seen && continue
            push!(seen, key)
            score = written_multisample_score(root, reference_path, candidate_path,
                                              parameters, scenarios; column, mu0_index)
            push!(rows, merge(score, (coordinate = index, delta = delta)))
            score_all_improved = score.improved_count == score.present_count
            best_all_improved = best.improved_count == best.present_count
            if (score_all_improved && !best_all_improved) ||
               (score_all_improved == best_all_improved &&
                score.aggregate_loss < best.aggregate_loss)
                best = score
            end
        end
    end
    write_scaled_shortwave_candidate(reference_path, candidate_path, best.parameters)
    improved = best.aggregate_loss < seed.aggregate_loss
    all_improved = best.improved_count == best.present_count
    status = improved && all_improved ? "written_coordinate_scan_improved" :
             all_improved ? "written_coordinate_scan_no_descent" :
             "written_coordinate_scan_failed"
    return (
        case = "ecckd_candidate_table_written_coordinate_scan",
        timestamp_utc = string(Dates.now()),
        status = status,
        reference_path = reference_path,
        candidate_path = candidate_path,
        scenario_count = length(scenarios),
        present_count = seed.present_count,
        tested_move_count = length(rows),
        seed_aggregate_loss = seed.aggregate_loss,
        best_aggregate_loss = best.aggregate_loss,
        aggregate_loss_reduction_factor =
            seed.aggregate_loss / max(best.aggregate_loss, eps(Float64)),
        seed_worst_loss_ratio = seed.worst_loss_ratio,
        best_worst_loss_ratio = best.worst_loss_ratio,
        best_improved_count = best.improved_count,
        initial_log_parameters = collect(initial_parameters),
        best_log_parameters = collect(best.parameters),
        best_rows = best.rows,
        scan_rows = rows,
        blockers = String[],
        interpretation =
            "This exact scan writes and rereads one-coordinate table-parameter moves around the selected multi-sample candidate. A move is useful only if the written file improves the multi-sample score; in-memory optimizer loss is not used for acceptance.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_table_written_coordinate_scan(result)
    lines = String[
        "# ecCKD Candidate Table Written Coordinate Scan",
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
            "## Written Coordinate Scan",
            "",
            "| Metric | Value |",
            "|---|---:|",
            "| Present scenarios | $(result.present_count)/$(result.scenario_count) |",
            "| Tested moves | $(result.tested_move_count) |",
            "| Seed aggregate loss | $(result.seed_aggregate_loss) |",
            "| Best aggregate loss | $(result.best_aggregate_loss) |",
            "| Aggregate loss reduction factor | $(result.aggregate_loss_reduction_factor) |",
            "| Seed worst loss ratio | $(result.seed_worst_loss_ratio) |",
            "| Best worst loss ratio | $(result.best_worst_loss_ratio) |",
            "| Best improved scenarios | $(result.best_improved_count) |",
            "",
            "## Best Written Candidate Scenario Scores",
            "",
            "| Scenario | Baseline loss | Candidate loss | Loss ratio | Improved |",
            "|---|---:|---:|---:|---:|",
        ])
        for row in result.best_rows
            push!(lines,
                  "| $(row.scenario) | $(row.baseline_loss) | $(row.candidate_loss) | $(row.loss_ratio) | $(row.improved) |")
        end
        push!(lines, "", result.interpretation)
    end
    return join(lines, "\n") * "\n"
end

function ecckd_candidate_table_written_coordinate_scan_main()
    result = run_table_written_coordinate_scan()
    write_json(CANDIDATE_TABLE_WRITTEN_COORDINATE_SCAN_JSON, result)
    write(CANDIDATE_TABLE_WRITTEN_COORDINATE_SCAN_MD,
          markdown_table_written_coordinate_scan(result))
    print(markdown_table_written_coordinate_scan(result))
    println("Wrote $CANDIDATE_TABLE_WRITTEN_COORDINATE_SCAN_JSON")
    println("Wrote $CANDIDATE_TABLE_WRITTEN_COORDINATE_SCAN_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_candidate_table_written_coordinate_scan_main()
end
