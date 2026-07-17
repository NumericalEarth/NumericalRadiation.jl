include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

include(joinpath(@__DIR__, "ecckd_candidate_table_writeback_probe.jl"))

const CANDIDATE_TABLE_WRITEBACK_CONTINUATION_JSON =
    validation_results_path("ecckd_candidate_table_writeback_continuation.json")
const CANDIDATE_TABLE_WRITEBACK_CONTINUATION_MD =
    validation_results_path("ecckd_candidate_table_writeback_continuation.md")
const CANDIDATE_TABLE_WRITEBACK_CONTINUATION_FILE =
    validation_results_path("ecckd_table_scaled_sw32_continuation_candidate.nc")

function table_parameter_continuation(f, initial_parameters; iterations = 4)
    parameters = copy(initial_parameters)
    history = Float64[f(parameters)]
    parameter_history = Vector{Float64}[copy(parameters)]
    accepted_steps = 0
    step_sizes = Float64[]
    for _ in 1:iterations
        gradient = table_probe_gradient(f, parameters)
        step = table_probe_descent_step(f, parameters, gradient)
        if step.accepted && step.loss < last(history)
            parameters .= step.parameters
            accepted_steps += 1
            push!(step_sizes, step.step)
            push!(history, step.loss)
            push!(parameter_history, copy(parameters))
        else
            push!(history, last(history))
            push!(step_sizes, 0.0)
            push!(parameter_history, copy(parameters))
        end
    end
    return (
        parameters = parameters,
        history = history,
        parameter_history = parameter_history,
        accepted_steps = accepted_steps,
        step_sizes = step_sizes,
    )
end

function run_table_writeback_continuation(; root = ckdmip_data_root(),
                                          reference_path = VECTOR_TRAINING_CANDIDATE,
                                          candidate_path =
                                              CANDIDATE_TABLE_WRITEBACK_CONTINUATION_FILE,
                                          iterations = 4,
                                          column = 1,
                                          mu0_index = 1)
    if root === nothing
        return (
            case = "ecckd_candidate_table_writeback_continuation",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    sw_path = joinpath(root, expected_flux_path("ckdmip_evaluation1_sw_fluxes_rel-415.h5"))
    missing = [path for path in (reference_path, sw_path) if !isfile(path)]
    if !isempty(missing)
        return (
            case = "ecckd_candidate_table_writeback_continuation",
            timestamp_utc = string(Dates.now()),
            status = "missing_input",
            blockers = ["Missing input: $(path)" for path in missing],
        )
    end

    sw_dataset = NCDataset(sw_path)
    mu0 = try
        Float64(sw_dataset["mu0"][mu0_index])
    finally
        close(sw_dataset)
    end
    atmosphere = ckdmip_column_atmosphere(sw_path; column, mu0)
    longwave_path = official_ecckd_definition_path(:longwave_32)
    model = read_ecckd_tabulated_gas_optics(
        longwave_path,
        reference_path;
        gas_names = (:h2o, :co2),
    )
    sw_sample = read_ckdmip_training_sample(sw_path; column, mu0_index)
    f = p -> shortwave_projected_table_loss(p, model, atmosphere, sw_sample,
                                            longwave_path, reference_path)
    continuation = table_parameter_continuation(f, zeros(Float64, 4); iterations)
    baseline_loss, baseline_nonfinite =
        written_shortwave_projected_loss(reference_path, root; column, mu0_index)
    best_loss = baseline_loss
    best_nonfinite = baseline_nonfinite
    best_parameters = copy(first(continuation.parameter_history))
    best_checkpoint_index = 0
    for (index, parameters) in enumerate(continuation.parameter_history)
        index == 1 && continue
        write_scaled_shortwave_candidate(reference_path, candidate_path, parameters)
        candidate_loss, candidate_nonfinite =
            written_shortwave_projected_loss(candidate_path, root; column, mu0_index)
        if candidate_loss !== nothing && candidate_loss < best_loss
            best_loss = candidate_loss
            best_nonfinite = candidate_nonfinite
            best_parameters = copy(parameters)
            best_checkpoint_index = index - 1
        end
    end
    write_scaled_shortwave_candidate(reference_path, candidate_path, best_parameters)
    metrics = recovery_metrics(official_ecckd_definition_path(:shortwave_32), candidate_path)
    improved = best_loss !== nothing && best_loss < baseline_loss
    return (
        case = "ecckd_candidate_table_writeback_continuation",
        timestamp_utc = string(Dates.now()),
        status = improved ? "table_writeback_continuation_passed" :
                 "table_writeback_continuation_failed",
        reference_path = reference_path,
        candidate_path = candidate_path,
        iterations = iterations,
        accepted_steps = continuation.accepted_steps,
        initial_in_memory_loss = first(continuation.history),
        final_in_memory_loss = last(continuation.history),
        in_memory_loss_reduction_factor =
            first(continuation.history) / max(last(continuation.history), eps(Float64)),
        baseline_projected_loss = baseline_loss,
        written_projected_loss = best_loss,
        writeback_loss_reduction_factor = baseline_loss / max(best_loss, eps(Float64)),
        baseline_nonfinite_flux_count = baseline_nonfinite,
        written_nonfinite_flux_count = best_nonfinite,
        best_checkpoint_index = best_checkpoint_index,
        final_log_parameters = collect(best_parameters),
        step_sizes = continuation.step_sizes,
        candidate_metrics_status = metrics.status,
        candidate_worst_log_coefficient_rmse = metrics.worst_log_coefficient_rmse,
        accepted_writeback = improved,
        blockers = String[],
        interpretation =
            "This runs a short continuation on real in-memory ecCKD table multipliers, writes the final multipliers into a CKD-definition NetCDF candidate, and verifies that the written file still reduces the projected original-objective loss. It is not full published-model recovery.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_table_writeback_continuation(result)
    lines = String[
        "# ecCKD Candidate Table-Writeback Continuation",
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
            "## Continuation",
            "",
            "| Metric | Value |",
            "|---|---:|",
            "| Iterations | $(result.iterations) |",
            "| Accepted steps | $(result.accepted_steps) |",
            "| Initial in-memory loss | $(result.initial_in_memory_loss) |",
            "| Final in-memory loss | $(result.final_in_memory_loss) |",
            "| In-memory loss reduction factor | $(result.in_memory_loss_reduction_factor) |",
            "| Baseline written SW projected loss | $(result.baseline_projected_loss) |",
            "| Continuation written SW projected loss | $(result.written_projected_loss) |",
            "| Writeback loss reduction factor | $(result.writeback_loss_reduction_factor) |",
            "| Best written checkpoint | $(result.best_checkpoint_index) |",
            "| Accepted writeback | $(result.accepted_writeback) |",
            "| Candidate metrics status | $(result.candidate_metrics_status) |",
            "| Candidate worst log-coefficient RMSE | $(result.candidate_worst_log_coefficient_rmse) |",
            "",
            result.interpretation,
        ])
    end
    return join(lines, "\n") * "\n"
end

function ecckd_candidate_table_writeback_continuation_main()
    result = run_table_writeback_continuation()
    write_json(CANDIDATE_TABLE_WRITEBACK_CONTINUATION_JSON, result)
    write(CANDIDATE_TABLE_WRITEBACK_CONTINUATION_MD,
          markdown_table_writeback_continuation(result))
    print(markdown_table_writeback_continuation(result))
    println("Wrote $CANDIDATE_TABLE_WRITEBACK_CONTINUATION_JSON")
    println("Wrote $CANDIDATE_TABLE_WRITEBACK_CONTINUATION_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_candidate_table_writeback_continuation_main()
end
