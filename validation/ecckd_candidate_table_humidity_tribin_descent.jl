include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

include(joinpath(@__DIR__, "ecckd_candidate_table_humidity_tribin_probe.jl"))

const CANDIDATE_TABLE_HUMIDITY_TRIBIN_DESCENT_JSON =
    validation_results_path("ecckd_candidate_table_humidity_tribin_descent.json")
const CANDIDATE_TABLE_HUMIDITY_TRIBIN_DESCENT_MD =
    validation_results_path("ecckd_candidate_table_humidity_tribin_descent.md")
const CANDIDATE_TABLE_HUMIDITY_TRIBIN_DESCENT_FILE =
    validation_results_path("ecckd_table_humidity_tribin_descent_sw32_candidate.nc")

function humidity_tribin_probe_parameters(kind)
    if isfile(CANDIDATE_TABLE_HUMIDITY_TRIBIN_PROBE_JSON)
        data = JSON.parsefile(CANDIDATE_TABLE_HUMIDITY_TRIBIN_PROBE_JSON)
        key = kind == :minimax ? "best_minimax_parameters" : "best_aggregate_parameters"
        params = local_json_get(data, key, nothing)
        params isa AbstractVector && length(params) == 6 && return Float64.(params)
    end
    return humidity_tribin_initial_parameters()
end

function humidity_tribin_descent_step(root, reference_path, candidate_path,
                                      parameters, scenarios, deltas, mode;
                                      column = 1, mu0_index = 1)
    incumbent = humidity_tribin_score(root, reference_path, candidate_path,
                                      parameters, scenarios; column, mu0_index)
    best = incumbent
    best_parameters = collect(parameters)
    tested = 0
    for index in 1:3
        for delta in deltas
            proposal = copy(parameters)
            proposal[index] = clamp(proposal[index] + delta, -2.0, 2.0)
            proposal == parameters && continue
            score = humidity_tribin_score(root, reference_path, candidate_path,
                                          proposal, scenarios; column, mu0_index)
            tested += 1
            if mode == :minimax
                if minimax_better(score, best)
                    best = score
                    best_parameters = collect(proposal)
                end
            else
                if aggregate_better(score, best)
                    best = score
                    best_parameters = collect(proposal)
                end
            end
        end
    end
    accepted = mode == :minimax ?
               best.worst_loss_ratio < incumbent.worst_loss_ratio :
               best.aggregate_loss < incumbent.aggregate_loss
    return (
        accepted = accepted,
        tested = tested,
        incumbent = incumbent,
        best = best,
        best_parameters = best_parameters,
    )
end

function run_table_humidity_tribin_descent(; root = ckdmip_data_root(),
                                           reference_path = VECTOR_TRAINING_CANDIDATE,
                                           candidate_path =
                                               CANDIDATE_TABLE_HUMIDITY_TRIBIN_DESCENT_FILE,
                                           scenarios = ("rel-180", "rel-415", "rel-1120"),
                                           initial_parameters =
                                               humidity_tribin_probe_parameters(:aggregate),
                                           mode = :aggregate,
                                           deltas = (-0.1, -0.03162277660168379,
                                                     -0.01, 0.01,
                                                     0.03162277660168379, 0.1),
                                           iterations = 4,
                                           column = 1,
                                           mu0_index = 1)
    if root === nothing
        return (
            case = "ecckd_candidate_table_humidity_tribin_descent",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    if !isfile(reference_path)
        return (
            case = "ecckd_candidate_table_humidity_tribin_descent",
            timestamp_utc = string(Dates.now()),
            status = "missing_input",
            blockers = ["Missing input: $(reference_path)"],
        )
    end

    parameters = collect(initial_parameters)
    seed = humidity_tribin_score(root, reference_path, candidate_path,
                                 parameters, scenarios; column, mu0_index)
    best = seed
    accepted_moves = 0
    tested_moves = 0
    history = Any[(
        iteration = 0,
        accepted = true,
        aggregate_loss = seed.aggregate_loss,
        worst_loss_ratio = seed.worst_loss_ratio,
        improved_count = seed.improved_count,
        parameters = collect(parameters),
    )]
    for iteration in 1:iterations
        step = humidity_tribin_descent_step(root, reference_path, candidate_path,
                                            parameters, scenarios, deltas, mode;
                                            column, mu0_index)
        tested_moves += step.tested
        if step.accepted
            parameters = step.best_parameters
            best = humidity_tribin_score(root, reference_path, candidate_path,
                                         parameters, scenarios; column, mu0_index)
            accepted_moves += 1
        else
            best = step.incumbent
        end
        push!(history, (
            iteration = iteration,
            accepted = step.accepted,
            aggregate_loss = step.accepted ? best.aggregate_loss :
                             step.best.aggregate_loss,
            worst_loss_ratio = step.accepted ? best.worst_loss_ratio :
                               step.best.worst_loss_ratio,
            improved_count = step.accepted ? best.improved_count :
                             step.best.improved_count,
            parameters = step.accepted ? collect(parameters) :
                         collect(step.best_parameters),
        ))
        step.accepted || break
    end
    write_humidity_tribin_shortwave_candidate(reference_path, candidate_path,
                                              parameters)
    all_improved = best.improved_count == best.present_count
    aggregate_improved = best.aggregate_loss < seed.aggregate_loss
    minimax_improved = best.worst_loss_ratio < seed.worst_loss_ratio
    status = aggregate_improved || minimax_improved ?
             "humidity_tribin_descent_improved" :
             all_improved ? "humidity_tribin_descent_no_descent" :
             "humidity_tribin_descent_failed"
    return (
        case = "ecckd_candidate_table_humidity_tribin_descent",
        timestamp_utc = string(Dates.now()),
        status = status,
        mode = String(mode),
        reference_path = reference_path,
        candidate_path = candidate_path,
        scenario_count = length(scenarios),
        present_count = seed.present_count,
        iterations = iterations,
        tested_move_count = tested_moves,
        accepted_move_count = accepted_moves,
        initial_aggregate_loss = seed.aggregate_loss,
        final_aggregate_loss = best.aggregate_loss,
        aggregate_loss_reduction_factor =
            seed.aggregate_loss / max(best.aggregate_loss, eps(Float64)),
        initial_worst_loss_ratio = seed.worst_loss_ratio,
        final_worst_loss_ratio = best.worst_loss_ratio,
        worst_loss_ratio_reduction_factor =
            seed.worst_loss_ratio / max(best.worst_loss_ratio, eps(Float64)),
        final_improved_count = best.improved_count,
        initial_parameters = collect(initial_parameters),
        final_parameters = collect(parameters),
        final_rows = best.rows,
        history = history,
        blockers = String[],
        interpretation =
            "This repeats exact written/reread low/mid/high H2O split moves. It is a structured humidity-axis table optimizer diagnostic, not published-model recovery.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_table_humidity_tribin_descent(result)
    lines = String[
        "# ecCKD Candidate Table Humidity-Tribin Descent",
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
            "## Descent Summary",
            "",
            "| Metric | Value |",
            "|---|---:|",
            "| Mode | $(result.mode) |",
            "| Present scenarios | $(result.present_count)/$(result.scenario_count) |",
            "| Tested moves | $(result.tested_move_count) |",
            "| Accepted moves | $(result.accepted_move_count) |",
            "| Initial aggregate loss | $(result.initial_aggregate_loss) |",
            "| Final aggregate loss | $(result.final_aggregate_loss) |",
            "| Aggregate loss reduction factor | $(result.aggregate_loss_reduction_factor) |",
            "| Initial worst loss ratio | $(result.initial_worst_loss_ratio) |",
            "| Final worst loss ratio | $(result.final_worst_loss_ratio) |",
            "| Worst loss ratio reduction factor | $(result.worst_loss_ratio_reduction_factor) |",
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

function ecckd_candidate_table_humidity_tribin_descent_main()
    result = run_table_humidity_tribin_descent()
    write_json(CANDIDATE_TABLE_HUMIDITY_TRIBIN_DESCENT_JSON, result)
    write(CANDIDATE_TABLE_HUMIDITY_TRIBIN_DESCENT_MD,
          markdown_table_humidity_tribin_descent(result))
    print(markdown_table_humidity_tribin_descent(result))
    println("Wrote $CANDIDATE_TABLE_HUMIDITY_TRIBIN_DESCENT_JSON")
    println("Wrote $CANDIDATE_TABLE_HUMIDITY_TRIBIN_DESCENT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_candidate_table_humidity_tribin_descent_main()
end
