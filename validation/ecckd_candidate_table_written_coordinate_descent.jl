include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

include(joinpath(@__DIR__, "ecckd_candidate_table_written_coordinate_scan.jl"))

const CANDIDATE_TABLE_WRITTEN_COORDINATE_DESCENT_JSON =
    validation_results_path("ecckd_candidate_table_written_coordinate_descent.json")
const CANDIDATE_TABLE_WRITTEN_COORDINATE_DESCENT_MD =
    validation_results_path("ecckd_candidate_table_written_coordinate_descent.md")
const CANDIDATE_TABLE_WRITTEN_COORDINATE_DESCENT_FILE =
    validation_results_path("ecckd_table_written_coordinate_descent_sw32_candidate.nc")

function written_coordinate_scan_seed_parameters()
    if isfile(CANDIDATE_TABLE_WRITTEN_COORDINATE_SCAN_JSON)
        data = JSON.parsefile(CANDIDATE_TABLE_WRITTEN_COORDINATE_SCAN_JSON)
        params = local_json_get(data, "best_log_parameters", nothing)
        params isa AbstractVector && length(params) == 4 && return Float64.(params)
    end
    return selected_multisample_parameters()
end

function run_table_written_coordinate_descent(; root = ckdmip_data_root(),
                                              reference_path = VECTOR_TRAINING_CANDIDATE,
                                              candidate_path =
                                                  CANDIDATE_TABLE_WRITTEN_COORDINATE_DESCENT_FILE,
                                              scenarios = ("rel-180", "rel-415", "rel-1120"),
                                              initial_parameters =
                                                  written_coordinate_scan_seed_parameters(),
                                              deltas = (-0.1, -0.03162277660168379,
                                                        -0.01, 0.01,
                                                        0.03162277660168379, 0.1),
                                              iterations = 6,
                                              column = 1,
                                              mu0_index = 1)
    if root === nothing
        return (
            case = "ecckd_candidate_table_written_coordinate_descent",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    if !isfile(reference_path)
        return (
            case = "ecckd_candidate_table_written_coordinate_descent",
            timestamp_utc = string(Dates.now()),
            status = "missing_input",
            blockers = ["Missing input: $(reference_path)"],
        )
    end

    parameters = collect(initial_parameters)
    seed = written_multisample_score(root, reference_path, candidate_path, parameters,
                                     scenarios; column, mu0_index)
    history = Any[(
        iteration = 0,
        accepted = true,
        aggregate_loss = seed.aggregate_loss,
        worst_loss_ratio = seed.worst_loss_ratio,
        improved_count = seed.improved_count,
        parameters = collect(parameters),
    )]
    accepted_moves = 0
    best_score = seed
    for iteration in 1:iterations
        scan = run_table_written_coordinate_scan(;
            root,
            reference_path,
            candidate_path,
            scenarios,
            initial_parameters = parameters,
            deltas,
            column,
            mu0_index,
        )
        accepted = scan.best_aggregate_loss < best_score.aggregate_loss
        if accepted
            parameters = collect(scan.best_log_parameters)
            accepted_moves += 1
            best_score = written_multisample_score(root, reference_path, candidate_path,
                                                   parameters, scenarios; column, mu0_index)
        end
        push!(history, (
            iteration = iteration,
            accepted = accepted,
            aggregate_loss = accepted ? best_score.aggregate_loss : scan.best_aggregate_loss,
            worst_loss_ratio = accepted ? best_score.worst_loss_ratio :
                               scan.best_worst_loss_ratio,
            improved_count = accepted ? best_score.improved_count :
                             scan.best_improved_count,
            parameters = accepted ? collect(parameters) : collect(scan.best_log_parameters),
        ))
        accepted || break
    end
    write_scaled_shortwave_candidate(reference_path, candidate_path, parameters)
    all_improved = best_score.improved_count == best_score.present_count
    improved = best_score.aggregate_loss < seed.aggregate_loss
    status = improved && all_improved ? "written_coordinate_descent_improved" :
             all_improved ? "written_coordinate_descent_no_descent" :
             "written_coordinate_descent_failed"
    return (
        case = "ecckd_candidate_table_written_coordinate_descent",
        timestamp_utc = string(Dates.now()),
        status = status,
        reference_path = reference_path,
        candidate_path = candidate_path,
        scenario_count = length(scenarios),
        present_count = seed.present_count,
        iterations = iterations,
        accepted_move_count = accepted_moves,
        initial_aggregate_loss = seed.aggregate_loss,
        final_aggregate_loss = best_score.aggregate_loss,
        aggregate_loss_reduction_factor =
            seed.aggregate_loss / max(best_score.aggregate_loss, eps(Float64)),
        initial_worst_loss_ratio = seed.worst_loss_ratio,
        final_worst_loss_ratio = best_score.worst_loss_ratio,
        final_improved_count = best_score.improved_count,
        initial_log_parameters = collect(initial_parameters),
        final_log_parameters = collect(parameters),
        final_rows = best_score.rows,
        history = history,
        blockers = String[],
        interpretation =
            "This repeats exact written-file coordinate scans, accepting a move only when the reread multi-sample aggregate loss improves. It is a written-file optimizer diagnostic, not published-model recovery.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_table_written_coordinate_descent(result)
    lines = String[
        "# ecCKD Candidate Table Written Coordinate Descent",
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
            "## Written Coordinate Descent",
            "",
            "| Metric | Value |",
            "|---|---:|",
            "| Present scenarios | $(result.present_count)/$(result.scenario_count) |",
            "| Iterations | $(result.iterations) |",
            "| Accepted moves | $(result.accepted_move_count) |",
            "| Initial aggregate loss | $(result.initial_aggregate_loss) |",
            "| Final aggregate loss | $(result.final_aggregate_loss) |",
            "| Aggregate loss reduction factor | $(result.aggregate_loss_reduction_factor) |",
            "| Initial worst loss ratio | $(result.initial_worst_loss_ratio) |",
            "| Final worst loss ratio | $(result.final_worst_loss_ratio) |",
            "| Final improved scenarios | $(result.final_improved_count) |",
            "",
            "## Final Written Candidate Scenario Scores",
            "",
            "| Scenario | Baseline loss | Candidate loss | Loss ratio | Improved |",
            "|---|---:|---:|---:|---:|",
        ])
        for row in result.final_rows
            push!(lines,
                  "| $(row.scenario) | $(row.baseline_loss) | $(row.candidate_loss) | $(row.loss_ratio) | $(row.improved) |")
        end
        push!(lines, "", result.interpretation)
    end
    return join(lines, "\n") * "\n"
end

function ecckd_candidate_table_written_coordinate_descent_main()
    result = run_table_written_coordinate_descent()
    write_json(CANDIDATE_TABLE_WRITTEN_COORDINATE_DESCENT_JSON, result)
    write(CANDIDATE_TABLE_WRITTEN_COORDINATE_DESCENT_MD,
          markdown_table_written_coordinate_descent(result))
    print(markdown_table_written_coordinate_descent(result))
    println("Wrote $CANDIDATE_TABLE_WRITTEN_COORDINATE_DESCENT_JSON")
    println("Wrote $CANDIDATE_TABLE_WRITTEN_COORDINATE_DESCENT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_candidate_table_written_coordinate_descent_main()
end
