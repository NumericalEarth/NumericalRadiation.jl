include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

include(joinpath(@__DIR__, "ecckd_candidate_table_humidity_tribin_descent.jl"))

const CANDIDATE_TABLE_HUMIDITY_TRIBIN_WEIGHTED_DESCENT_JSON =
    validation_results_path("ecckd_candidate_table_humidity_tribin_weighted_descent.json")
const CANDIDATE_TABLE_HUMIDITY_TRIBIN_WEIGHTED_DESCENT_MD =
    validation_results_path("ecckd_candidate_table_humidity_tribin_weighted_descent.md")
const CANDIDATE_TABLE_HUMIDITY_TRIBIN_WEIGHTED_DESCENT_FILE =
    validation_results_path("ecckd_table_humidity_tribin_weighted_descent_sw32_candidate.nc")

function weighted_loss_ratio(score, scenario_weights)
    present_rows = filter(row -> row.present, score.rows)
    isempty(present_rows) && return Inf
    numerator = 0.0
    denominator = 0.0
    for row in present_rows
        weight = Float64(get(scenario_weights, String(row.scenario), 1.0))
        numerator += weight * row.loss_ratio
        denominator += weight
    end
    return numerator / max(denominator, eps(Float64))
end

function weighted_score_tuple(score, scenario_weights)
    return merge(score, (
        weighted_loss_ratio = weighted_loss_ratio(score, scenario_weights),
    ))
end

function humidity_tribin_weighted_descent_step(root, reference_path, candidate_path,
                                               parameters, scenarios, deltas,
                                               scenario_weights;
                                               column = 1, mu0_index = 1)
    incumbent = weighted_score_tuple(
        humidity_tribin_score(root, reference_path, candidate_path,
                              parameters, scenarios; column, mu0_index),
        scenario_weights,
    )
    best = incumbent
    best_parameters = collect(parameters)
    tested = 0
    for index in 1:3
        for delta in deltas
            proposal = copy(parameters)
            proposal[index] = clamp(proposal[index] + delta, -2.0, 2.0)
            proposal == parameters && continue
            score = weighted_score_tuple(
                humidity_tribin_score(root, reference_path, candidate_path,
                                      proposal, scenarios; column, mu0_index),
                scenario_weights,
            )
            tested += 1
            score.weighted_loss_ratio < best.weighted_loss_ratio || continue
            best = score
            best_parameters = collect(proposal)
        end
    end
    return (
        accepted = best.weighted_loss_ratio < incumbent.weighted_loss_ratio,
        tested = tested,
        incumbent = incumbent,
        best = best,
        best_parameters = best_parameters,
    )
end

function run_single_humidity_tribin_weighted_descent(root, reference_path,
                                                    candidate_path, scenarios,
                                                    initial_parameters,
                                                    scenario_weights, deltas,
                                                    iterations; column = 1,
                                                    mu0_index = 1)
    parameters = collect(initial_parameters)
    seed = weighted_score_tuple(
        humidity_tribin_score(root, reference_path, candidate_path,
                              parameters, scenarios; column, mu0_index),
        scenario_weights,
    )
    best = seed
    accepted_moves = 0
    tested_moves = 0
    history = Any[(
        iteration = 0,
        accepted = true,
        aggregate_loss = seed.aggregate_loss,
        worst_loss_ratio = seed.worst_loss_ratio,
        weighted_loss_ratio = seed.weighted_loss_ratio,
        improved_count = seed.improved_count,
        parameters = collect(parameters),
    )]
    for iteration in 1:iterations
        step = humidity_tribin_weighted_descent_step(
            root, reference_path, candidate_path, parameters, scenarios, deltas,
            scenario_weights; column, mu0_index,
        )
        tested_moves += step.tested
        if step.accepted
            parameters = step.best_parameters
            best = weighted_score_tuple(
                humidity_tribin_score(root, reference_path, candidate_path,
                                      parameters, scenarios; column, mu0_index),
                scenario_weights,
            )
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
            weighted_loss_ratio = step.accepted ? best.weighted_loss_ratio :
                                  step.best.weighted_loss_ratio,
            improved_count = step.accepted ? best.improved_count :
                             step.best.improved_count,
            parameters = step.accepted ? collect(parameters) :
                         collect(step.best_parameters),
        ))
        step.accepted || break
    end
    return (
        scenario_weights = Dict(k => Float64(v) for (k, v) in scenario_weights),
        initial_weighted_loss_ratio = seed.weighted_loss_ratio,
        final_weighted_loss_ratio = best.weighted_loss_ratio,
        weighted_loss_ratio_reduction_factor =
            seed.weighted_loss_ratio / max(best.weighted_loss_ratio, eps(Float64)),
        initial_aggregate_loss = seed.aggregate_loss,
        final_aggregate_loss = best.aggregate_loss,
        aggregate_loss_reduction_factor =
            seed.aggregate_loss / max(best.aggregate_loss, eps(Float64)),
        initial_worst_loss_ratio = seed.worst_loss_ratio,
        final_worst_loss_ratio = best.worst_loss_ratio,
        worst_loss_ratio_reduction_factor =
            seed.worst_loss_ratio / max(best.worst_loss_ratio, eps(Float64)),
        final_improved_count = best.improved_count,
        present_count = seed.present_count,
        tested_move_count = tested_moves,
        accepted_move_count = accepted_moves,
        final_parameters = collect(parameters),
        final_rows = best.rows,
        history = history,
    )
end

function weighted_descent_better(candidate, incumbent)
    candidate.final_improved_count == candidate.present_count &&
        incumbent.final_improved_count != incumbent.present_count && return true
    candidate.final_worst_loss_ratio < incumbent.final_worst_loss_ratio && return true
    candidate.final_worst_loss_ratio == incumbent.final_worst_loss_ratio &&
        candidate.final_weighted_loss_ratio < incumbent.final_weighted_loss_ratio &&
        return true
    return false
end

function run_table_humidity_tribin_weighted_descent(; root = ckdmip_data_root(),
                                                    reference_path =
                                                        VECTOR_TRAINING_CANDIDATE,
                                                    candidate_path =
                                                        CANDIDATE_TABLE_HUMIDITY_TRIBIN_WEIGHTED_DESCENT_FILE,
                                                    scenarios = ("rel-180",
                                                                 "rel-415",
                                                                 "rel-1120"),
                                                    initial_parameters =
                                                        humidity_tribin_probe_parameters(:aggregate),
                                                    scenario_weight_sets = (
                                                        Dict("rel-1120" => 2.0),
                                                        Dict("rel-1120" => 4.0),
                                                        Dict("rel-1120" => 8.0),
                                                        Dict("rel-1120" => 16.0),
                                                    ),
                                                    deltas = (-0.1,
                                                              -0.03162277660168379,
                                                              -0.01, 0.01,
                                                              0.03162277660168379,
                                                              0.1),
                                                    iterations = 4,
                                                    column = 1,
                                                    mu0_index = 1)
    if root === nothing
        return (
            case = "ecckd_candidate_table_humidity_tribin_weighted_descent",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    if !isfile(reference_path)
        return (
            case = "ecckd_candidate_table_humidity_tribin_weighted_descent",
            timestamp_utc = string(Dates.now()),
            status = "missing_input",
            blockers = ["Missing input: $(reference_path)"],
        )
    end

    rows = Any[]
    best = nothing
    for weights in scenario_weight_sets
        score = run_single_humidity_tribin_weighted_descent(
            root, reference_path, candidate_path, scenarios, initial_parameters,
            weights, deltas, iterations; column, mu0_index,
        )
        push!(rows, score)
        if best === nothing || weighted_descent_better(score, best)
            best = score
        end
    end
    write_humidity_tribin_shortwave_candidate(reference_path, candidate_path,
                                              best.final_parameters)
    improved = best.final_weighted_loss_ratio < best.initial_weighted_loss_ratio ||
               best.final_worst_loss_ratio < best.initial_worst_loss_ratio
    return (
        case = "ecckd_candidate_table_humidity_tribin_weighted_descent",
        timestamp_utc = string(Dates.now()),
        status = improved ? "humidity_tribin_weighted_descent_improved" :
                 "humidity_tribin_weighted_descent_no_descent",
        reference_path = reference_path,
        candidate_path = candidate_path,
        scenario_count = length(scenarios),
        present_count = best.present_count,
        iterations = iterations,
        tested_weight_set_count = length(rows),
        best_scenario_weights = best.scenario_weights,
        best_weighted_loss_ratio = best.final_weighted_loss_ratio,
        best_weighted_loss_ratio_reduction_factor =
            best.weighted_loss_ratio_reduction_factor,
        best_aggregate_loss = best.final_aggregate_loss,
        best_aggregate_loss_reduction_factor =
            best.aggregate_loss_reduction_factor,
        best_worst_loss_ratio = best.final_worst_loss_ratio,
        best_worst_loss_ratio_reduction_factor =
            best.worst_loss_ratio_reduction_factor,
        best_accepted_move_count = best.accepted_move_count,
        best_tested_move_count = best.tested_move_count,
        best_final_improved_count = best.final_improved_count,
        best_final_rows = best.final_rows,
        rows = rows,
        blockers = String[],
        interpretation =
            "This exact written/reread scan optimizes a weighted mean of per-scenario loss ratios, emphasizing high-humidity rel-1120 without using raw-loss scale as the only objective. It is a diagnostic for objective weighting, not published-model recovery.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_table_humidity_tribin_weighted_descent(result)
    lines = String[
        "# ecCKD Candidate Table Humidity-Tribin Weighted Descent",
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
            "## Best Weighted Descent Summary",
            "",
            "| Metric | Value |",
            "|---|---:|",
            "| Present scenarios | $(result.present_count)/$(result.scenario_count) |",
            "| Tested weight sets | $(result.tested_weight_set_count) |",
            "| Best scenario weights | $(result.best_scenario_weights) |",
            "| Best tested moves | $(result.best_tested_move_count) |",
            "| Best accepted moves | $(result.best_accepted_move_count) |",
            "| Best weighted loss ratio | $(result.best_weighted_loss_ratio) |",
            "| Weighted loss ratio reduction factor | $(result.best_weighted_loss_ratio_reduction_factor) |",
            "| Best aggregate loss | $(result.best_aggregate_loss) |",
            "| Aggregate loss reduction factor | $(result.best_aggregate_loss_reduction_factor) |",
            "| Best worst loss ratio | $(result.best_worst_loss_ratio) |",
            "| Worst loss ratio reduction factor | $(result.best_worst_loss_ratio_reduction_factor) |",
            "| Final improved scenarios | $(result.best_final_improved_count) |",
            "",
            "## Best Final Scenario Scores",
            "",
            "| Scenario | Baseline loss | Candidate loss | Loss ratio | Improved |",
            "|---|---:|---:|---:|---:|",
        ])
        for row in result.best_final_rows
            push!(lines,
                  "| $(row.scenario) | $(row.baseline_loss) | $(row.candidate_loss) | $(row.loss_ratio) | $(row.improved) |")
        end
        append!(lines, [
            "",
            "## Weight-Set Sweep",
            "",
            "| Scenario weights | Accepted moves | Weighted ratio | Worst ratio | Aggregate loss |",
            "|---|---:|---:|---:|---:|",
        ])
        for row in result.rows
            push!(lines,
                  "| $(row.scenario_weights) | $(row.accepted_move_count) | $(row.final_weighted_loss_ratio) | $(row.final_worst_loss_ratio) | $(row.final_aggregate_loss) |")
        end
        push!(lines, "", result.interpretation)
    end
    return join(lines, "\n") * "\n"
end

function ecckd_candidate_table_humidity_tribin_weighted_descent_main()
    result = run_table_humidity_tribin_weighted_descent()
    write_json(CANDIDATE_TABLE_HUMIDITY_TRIBIN_WEIGHTED_DESCENT_JSON, result)
    write(CANDIDATE_TABLE_HUMIDITY_TRIBIN_WEIGHTED_DESCENT_MD,
          markdown_table_humidity_tribin_weighted_descent(result))
    print(markdown_table_humidity_tribin_weighted_descent(result))
    println("Wrote $CANDIDATE_TABLE_HUMIDITY_TRIBIN_WEIGHTED_DESCENT_JSON")
    println("Wrote $CANDIDATE_TABLE_HUMIDITY_TRIBIN_WEIGHTED_DESCENT_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_candidate_table_humidity_tribin_weighted_descent_main()
end
