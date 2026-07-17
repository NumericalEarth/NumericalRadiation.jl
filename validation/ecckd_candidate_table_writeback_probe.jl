include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON

include(joinpath(@__DIR__, "ecckd_candidate_table_parameter_probe.jl"))

const CANDIDATE_TABLE_WRITEBACK_PROBE_JSON =
    validation_results_path("ecckd_candidate_table_writeback_probe.json")
const CANDIDATE_TABLE_WRITEBACK_PROBE_MD =
    validation_results_path("ecckd_candidate_table_writeback_probe.md")
const CANDIDATE_TABLE_WRITEBACK_FILE =
    validation_results_path("ecckd_table_scaled_sw32_candidate.nc")

local_json_get(object, key, default = nothing) =
    haskey(object, key) ? object[key] : default

function optimized_table_parameters()
    if isfile(CANDIDATE_TABLE_PARAMETER_PROBE_JSON)
        data = JSON.parsefile(CANDIDATE_TABLE_PARAMETER_PROBE_JSON)
        params = local_json_get(data, "final_log_parameters", nothing)
        params isa AbstractVector && length(params) == 4 && return Float64.(params)
    end
    return zeros(Float64, 4)
end

function write_scaled_shortwave_candidate(reference_path, candidate_path, log_parameters)
    cp(reference_path, candidate_path; force = true)
    chmod(candidate_path, 0o644)
    h2o_scale = exp(log_parameters[1])
    co2_scale = exp(log_parameters[2])
    rayleigh_scale = exp(log_parameters[3])
    weight_scale = exp(log_parameters[4])
    NCDataset(candidate_path, "a") do ds
        if haskey(ds, "h2o_molar_absorption_coeff")
            ds["h2o_molar_absorption_coeff"][:] =
                Array(ds["h2o_molar_absorption_coeff"]) .* h2o_scale
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

function written_shortwave_projected_loss(candidate_path, root; column = 1, mu0_index = 1)
    sw_path = joinpath(root, expected_flux_path("ckdmip_evaluation1_sw_fluxes_rel-415.h5"))
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

function run_table_writeback_probe(; root = ckdmip_data_root(),
                                   reference_path = VECTOR_TRAINING_CANDIDATE,
                                   candidate_path = CANDIDATE_TABLE_WRITEBACK_FILE,
                                   log_parameters = optimized_table_parameters(),
                                   column = 1,
                                   mu0_index = 1)
    if root === nothing
        return (
            case = "ecckd_candidate_table_writeback_probe",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    missing = [path for path in (reference_path,
                                 joinpath(root, expected_flux_path("ckdmip_evaluation1_sw_fluxes_rel-415.h5")))
               if !isfile(path)]
    if !isempty(missing)
        return (
            case = "ecckd_candidate_table_writeback_probe",
            timestamp_utc = string(Dates.now()),
            status = "missing_input",
            blockers = ["Missing input: $(path)" for path in missing],
        )
    end
    write_scaled_shortwave_candidate(reference_path, candidate_path, log_parameters)
    baseline_loss, baseline_nonfinite =
        written_shortwave_projected_loss(reference_path, root; column, mu0_index)
    written_loss, written_nonfinite =
        written_shortwave_projected_loss(candidate_path, root; column, mu0_index)
    metrics = recovery_metrics(official_ecckd_definition_path(:shortwave_32), candidate_path)
    improved = written_loss !== nothing && written_loss < baseline_loss
    return (
        case = "ecckd_candidate_table_writeback_probe",
        timestamp_utc = string(Dates.now()),
        status = improved ? "table_writeback_probe_passed" :
                 "table_writeback_probe_failed",
        reference_path = reference_path,
        candidate_path = candidate_path,
        log_parameters = collect(log_parameters),
        baseline_projected_loss = baseline_loss,
        written_projected_loss = written_loss,
        loss_reduction_factor = baseline_loss / max(written_loss, eps(Float64)),
        baseline_nonfinite_flux_count = baseline_nonfinite,
        written_nonfinite_flux_count = written_nonfinite,
        candidate_metrics_status = metrics.status,
        candidate_worst_log_coefficient_rmse = metrics.worst_log_coefficient_rmse,
        accepted_writeback = improved,
        blockers = String[],
        interpretation =
            "This writes the optimized table multipliers into a CKD-definition NetCDF candidate and rescans that file through the normal reader and projected original-objective score. It is a writeback probe, not full published-model recovery.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_table_writeback_probe(result)
    lines = String[
        "# ecCKD Candidate Table-Writeback Probe",
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
            "## Writeback Probe",
            "",
            "| Metric | Value |",
            "|---|---:|",
            "| Baseline SW projected loss | $(result.baseline_projected_loss) |",
            "| Written SW projected loss | $(result.written_projected_loss) |",
            "| Loss reduction factor | $(result.loss_reduction_factor) |",
            "| Accepted writeback | $(result.accepted_writeback) |",
            "| Baseline non-finite flux count | $(result.baseline_nonfinite_flux_count) |",
            "| Written non-finite flux count | $(result.written_nonfinite_flux_count) |",
            "| Candidate metrics status | $(result.candidate_metrics_status) |",
            "| Candidate worst log-coefficient RMSE | $(result.candidate_worst_log_coefficient_rmse) |",
            "",
            result.interpretation,
        ])
    end
    return join(lines, "\n") * "\n"
end

function ecckd_candidate_table_writeback_probe_main()
    result = run_table_writeback_probe()
    write_json(CANDIDATE_TABLE_WRITEBACK_PROBE_JSON, result)
    write(CANDIDATE_TABLE_WRITEBACK_PROBE_MD, markdown_table_writeback_probe(result))
    print(markdown_table_writeback_probe(result))
    println("Wrote $CANDIDATE_TABLE_WRITEBACK_PROBE_JSON")
    println("Wrote $CANDIDATE_TABLE_WRITEBACK_PROBE_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_candidate_table_writeback_probe_main()
end
