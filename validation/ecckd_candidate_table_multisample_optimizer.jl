include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using LinearAlgebra

include(joinpath(@__DIR__, "ecckd_candidate_table_writeback_multisample.jl"))

const CANDIDATE_TABLE_MULTISAMPLE_OPTIMIZER_JSON =
    validation_results_path("ecckd_candidate_table_multisample_optimizer.json")
const CANDIDATE_TABLE_MULTISAMPLE_OPTIMIZER_MD =
    validation_results_path("ecckd_candidate_table_multisample_optimizer.md")
const CANDIDATE_TABLE_MULTISAMPLE_FILE =
    validation_results_path("ecckd_table_multisample_sw32_candidate.nc")

function table_multisample_seed_parameters()
    if isfile(CANDIDATE_TABLE_WRITEBACK_CONTINUATION_JSON)
        data = JSON.parsefile(CANDIDATE_TABLE_WRITEBACK_CONTINUATION_JSON)
        params = local_json_get(data, "final_log_parameters", nothing)
        params isa AbstractVector && length(params) == 4 && return Float64.(params)
    end
    return zeros(Float64, 4)
end

function table_multisample_entries(root, scenarios; column = 1, mu0_index = 1)
    entries = NamedTuple[]
    for scenario in scenarios
        sw_path = joinpath(root,
                           expected_flux_path("ckdmip_evaluation1_sw_fluxes_$(scenario).h5"))
        isfile(sw_path) || continue
        sw_dataset = NCDataset(sw_path)
        mu0 = try
            Float64(sw_dataset["mu0"][mu0_index])
        finally
            close(sw_dataset)
        end
        push!(entries, (
            scenario = scenario,
            sw_path = sw_path,
            atmosphere = ckdmip_column_atmosphere(sw_path; column, mu0),
            sample = read_ckdmip_training_sample(sw_path; column, mu0_index),
        ))
    end
    return entries
end

function aggregate_projected_table_loss(log_parameters, model, entries,
                                        longwave_path, shortwave_path)
    isempty(entries) && return Inf
    total = 0.0
    for entry in entries
        loss = shortwave_projected_table_loss(
            log_parameters,
            model,
            entry.atmosphere,
            entry.sample,
            longwave_path,
            shortwave_path,
        )
        isfinite(loss) || return Inf
        total += loss
    end
    return total / length(entries)
end

function run_table_multisample_optimizer(; root = ckdmip_data_root(),
                                         reference_path = VECTOR_TRAINING_CANDIDATE,
                                         candidate_path =
                                             CANDIDATE_TABLE_MULTISAMPLE_FILE,
                                         scenarios = ("rel-180", "rel-415", "rel-1120"),
                                         iterations = 2,
                                         initial_parameters =
                                             table_multisample_seed_parameters(),
                                         column = 1,
                                         mu0_index = 1)
    if root === nothing
        return (
            case = "ecckd_candidate_table_multisample_optimizer",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    if !isfile(reference_path)
        return (
            case = "ecckd_candidate_table_multisample_optimizer",
            timestamp_utc = string(Dates.now()),
            status = "missing_input",
            blockers = ["Missing input: $(reference_path)"],
        )
    end
    entries = table_multisample_entries(root, scenarios; column, mu0_index)
    if isempty(entries)
        return (
            case = "ecckd_candidate_table_multisample_optimizer",
            timestamp_utc = string(Dates.now()),
            status = "missing_samples",
            blockers = ["No requested CKDMIP SW scenarios were present."],
        )
    end

    longwave_path = official_ecckd_definition_path(:longwave_32)
    model = read_ecckd_tabulated_gas_optics(
        longwave_path,
        reference_path;
        gas_names = (:h2o, :co2),
    )
    f = p -> aggregate_projected_table_loss(p, model, entries,
                                            longwave_path, reference_path)
    continuation = table_parameter_continuation(f, initial_parameters; iterations)
    initial_loss = first(continuation.history)
    final_loss = last(continuation.history)
    accepted = isfinite(final_loss) && final_loss < initial_loss

    best_writeback = nothing
    best_written_loss = Inf
    best_checkpoint_index = 0
    best_parameters = copy(first(continuation.parameter_history))
    for (index, parameters) in enumerate(continuation.parameter_history)
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
        written_loss = isempty(present_rows) ? Inf :
                       sum(row.candidate_loss for row in present_rows) /
                       length(present_rows)
        all_improved = writeback.improved_count == writeback.present_count
        best_all_improved = best_writeback !== nothing &&
                            best_writeback.improved_count == best_writeback.present_count
        if (all_improved && !best_all_improved) ||
           (all_improved == best_all_improved && written_loss < best_written_loss)
            best_writeback = writeback
            best_written_loss = written_loss
            best_checkpoint_index = index - 1
            best_parameters = copy(parameters)
        end
    end
    write_scaled_shortwave_candidate(reference_path, candidate_path, best_parameters)
    writeback = best_writeback
    writeback_passed = writeback.status == "table_writeback_multisample_passed"
    status = writeback_passed && accepted ? "table_multisample_optimizer_passed" :
             writeback_passed ? "table_multisample_optimizer_seed_passed" :
             accepted ? "table_multisample_optimizer_partial" :
             "table_multisample_optimizer_failed"
    return (
        case = "ecckd_candidate_table_multisample_optimizer",
        timestamp_utc = string(Dates.now()),
        status = status,
        reference_path = reference_path,
        candidate_path = candidate_path,
        scenario_count = length(scenarios),
        present_count = length(entries),
        iterations = iterations,
        accepted_steps = continuation.accepted_steps,
        initial_aggregate_loss = initial_loss,
        final_aggregate_loss = final_loss,
        aggregate_loss_reduction_factor =
            initial_loss / max(final_loss, eps(Float64)),
        final_log_parameters = collect(continuation.parameters),
        selected_log_parameters = collect(best_parameters),
        best_written_checkpoint_index = best_checkpoint_index,
        selected_written_aggregate_loss = best_written_loss,
        gradient_method = "central_finite_difference_on_multisample_projected_table_loss",
        writeback_status = writeback.status,
        writeback_improved_count = writeback.improved_count,
        writeback_worst_loss_ratio = writeback.worst_loss_ratio,
        writeback_rows = writeback.rows,
        blockers = String[],
        interpretation =
            "This optimizes four real ecCKD shortwave table multipliers against an aggregate projected original-objective loss over multiple CKDMIP SW scenarios, writes a CKD-definition candidate, and rescans the written file. It is still a small-parameter optimizer probe, not published-model recovery.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_table_multisample_optimizer(result)
    lines = String[
        "# ecCKD Candidate Table Multisample Optimizer",
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
            "## Aggregate Optimizer",
            "",
            "| Metric | Value |",
            "|---|---:|",
            "| Present scenarios | $(result.present_count)/$(result.scenario_count) |",
            "| Iterations | $(result.iterations) |",
            "| Accepted steps | $(result.accepted_steps) |",
            "| Initial aggregate loss | $(result.initial_aggregate_loss) |",
            "| Final aggregate loss | $(result.final_aggregate_loss) |",
            "| Aggregate loss reduction factor | $(result.aggregate_loss_reduction_factor) |",
            "| Best written checkpoint | $(result.best_written_checkpoint_index) |",
            "| Selected written aggregate loss | $(result.selected_written_aggregate_loss) |",
            "| Writeback status | $(result.writeback_status) |",
            "| Writeback improved scenarios | $(result.writeback_improved_count) |",
            "| Writeback worst loss ratio | $(result.writeback_worst_loss_ratio) |",
            "",
            "## Written Candidate Scenario Scores",
            "",
            "| Scenario | Baseline loss | Candidate loss | Loss ratio | Improved |",
            "|---|---:|---:|---:|---:|",
        ])
        for row in result.writeback_rows
            push!(lines,
                  "| $(row.scenario) | $(row.baseline_loss) | $(row.candidate_loss) | $(row.loss_ratio) | $(row.improved) |")
        end
        push!(lines, "", result.interpretation)
    end
    return join(lines, "\n") * "\n"
end

function ecckd_candidate_table_multisample_optimizer_main()
    result = run_table_multisample_optimizer()
    write_json(CANDIDATE_TABLE_MULTISAMPLE_OPTIMIZER_JSON, result)
    write(CANDIDATE_TABLE_MULTISAMPLE_OPTIMIZER_MD,
          markdown_table_multisample_optimizer(result))
    print(markdown_table_multisample_optimizer(result))
    println("Wrote $CANDIDATE_TABLE_MULTISAMPLE_OPTIMIZER_JSON")
    println("Wrote $CANDIDATE_TABLE_MULTISAMPLE_OPTIMIZER_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_candidate_table_multisample_optimizer_main()
end
