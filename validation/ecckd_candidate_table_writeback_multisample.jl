include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

include(joinpath(@__DIR__, "ecckd_candidate_table_writeback_continuation.jl"))

const CANDIDATE_TABLE_WRITEBACK_MULTISAMPLE_JSON =
    validation_results_path("ecckd_candidate_table_writeback_multisample.json")
const CANDIDATE_TABLE_WRITEBACK_MULTISAMPLE_MD =
    validation_results_path("ecckd_candidate_table_writeback_multisample.md")

function shortwave_projected_loss_for_file(candidate_path, sw_path; column = 1, mu0_index = 1)
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
        candidate_path;
        gas_names = (:h2o, :co2),
    )
    sw_sample = read_ckdmip_training_sample(sw_path; column, mu0_index)
    nlayers = length(atmosphere.temperature_layers)
    longwave = LongwaveOpticalProperties(
        zeros(size(model.longwave_absorption, 1), nlayers),
        zeros(size(model.longwave_absorption, 1), nlayers);
        weights = zeros(size(model.longwave_absorption, 1)),
    )
    shortwave = ShortwaveOpticalProperties(
        zeros(size(model.shortwave_absorption, 1), nlayers);
        rayleigh_optical_depth = zeros(size(model.shortwave_absorption, 1), nlayers),
        weights = zeros(size(model.shortwave_absorption, 1)),
    )
    optical_properties!(longwave, shortwave, model, atmosphere)
    dummy_lw_sample = merge(sw_sample, (
        kind = "longwave",
        flux_dn_true = zeros(size(sw_sample.flux_dn_true)),
        flux_up_true = zeros(size(sw_sample.flux_up_true)),
        heating_rate_true = zeros(size(sw_sample.heating_rate_true)),
    ))
    projected = projected_flux_arrays(
        longwave,
        shortwave,
        atmosphere,
        dummy_lw_sample,
        sw_sample,
        longwave_path,
        candidate_path,
    )
    scores = projected_transfer_objective_scores(dummy_lw_sample, sw_sample, projected)
    return scores.shortwave.loss, scores.shortwave.nonfinite_flux_count
end

function multisample_row(root, scenario, reference_path, candidate_path; column = 1,
                         mu0_index = 1)
    sw_path = joinpath(root,
                       expected_flux_path("ckdmip_evaluation1_sw_fluxes_$(scenario).h5"))
    if !isfile(sw_path)
        return (
            scenario = scenario,
            present = false,
            baseline_loss = nothing,
            candidate_loss = nothing,
            improved = false,
            loss_ratio = nothing,
            baseline_nonfinite_flux_count = nothing,
            candidate_nonfinite_flux_count = nothing,
        )
    end
    baseline_loss, baseline_nonfinite =
        shortwave_projected_loss_for_file(reference_path, sw_path; column, mu0_index)
    candidate_loss, candidate_nonfinite =
        shortwave_projected_loss_for_file(candidate_path, sw_path; column, mu0_index)
    improved = candidate_loss !== nothing && baseline_loss !== nothing &&
               candidate_loss < baseline_loss
    return (
        scenario = scenario,
        present = true,
        baseline_loss = baseline_loss,
        candidate_loss = candidate_loss,
        improved = improved,
        loss_ratio = candidate_loss / max(baseline_loss, eps(Float64)),
        baseline_nonfinite_flux_count = baseline_nonfinite,
        candidate_nonfinite_flux_count = candidate_nonfinite,
    )
end

function run_table_writeback_multisample(; root = ckdmip_data_root(),
                                         reference_path = VECTOR_TRAINING_CANDIDATE,
                                         candidate_path =
                                             CANDIDATE_TABLE_WRITEBACK_CONTINUATION_FILE,
                                         scenarios = ("rel-180", "rel-415", "rel-1120"),
                                         column = 1,
                                         mu0_index = 1)
    if root === nothing
        return (
            case = "ecckd_candidate_table_writeback_multisample",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    missing = [path for path in (reference_path, candidate_path) if !isfile(path)]
    if !isempty(missing)
        return (
            case = "ecckd_candidate_table_writeback_multisample",
            timestamp_utc = string(Dates.now()),
            status = "missing_input",
            blockers = ["Missing input: $(path)" for path in missing],
        )
    end
    rows = [
        multisample_row(root, scenario, reference_path, candidate_path;
                        column, mu0_index)
        for scenario in scenarios
    ]
    present_rows = filter(row -> row.present, rows)
    improved_count = count(row -> row.improved, present_rows)
    status = isempty(present_rows) ? "missing_samples" :
             improved_count == length(present_rows) ?
             "table_writeback_multisample_passed" :
             "table_writeback_multisample_partial"
    return (
        case = "ecckd_candidate_table_writeback_multisample",
        timestamp_utc = string(Dates.now()),
        status = status,
        reference_path = reference_path,
        candidate_path = candidate_path,
        scenario_count = length(rows),
        present_count = length(present_rows),
        improved_count = improved_count,
        worst_loss_ratio = isempty(present_rows) ? nothing :
                           maximum(row.loss_ratio for row in present_rows),
        rows = rows,
        blockers = String[],
        interpretation =
            "This rescans the written table-continuation candidate across multiple representative CKDMIP SW scenarios. It checks generalization of the writeback update; it is not full published-model recovery.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_table_writeback_multisample(result)
    lines = String[
        "# ecCKD Candidate Table-Writeback Multisample",
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
    if hasproperty(result, :rows)
        append!(lines, [
            "",
            "## Scenario Scores",
            "",
            "| Scenario | Present | Baseline loss | Candidate loss | Loss ratio | Improved |",
            "|---|---:|---:|---:|---:|---:|",
        ])
        for row in result.rows
            push!(lines,
                  "| $(row.scenario) | $(row.present) | $(row.baseline_loss) | $(row.candidate_loss) | $(row.loss_ratio) | $(row.improved) |")
        end
        push!(lines, "", result.interpretation)
    end
    return join(lines, "\n") * "\n"
end

function ecckd_candidate_table_writeback_multisample_main()
    result = run_table_writeback_multisample()
    write_json(CANDIDATE_TABLE_WRITEBACK_MULTISAMPLE_JSON, result)
    write(CANDIDATE_TABLE_WRITEBACK_MULTISAMPLE_MD,
          markdown_table_writeback_multisample(result))
    print(markdown_table_writeback_multisample(result))
    println("Wrote $CANDIDATE_TABLE_WRITEBACK_MULTISAMPLE_JSON")
    println("Wrote $CANDIDATE_TABLE_WRITEBACK_MULTISAMPLE_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_candidate_table_writeback_multisample_main()
end
