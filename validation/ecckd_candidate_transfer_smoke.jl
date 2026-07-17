include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using JSON
using NCDatasets

const ABR_ROOT = normpath(joinpath(@__DIR__, ".."))
if Base.find_package("NumericalRadiation") === nothing
    push!(LOAD_PATH, ABR_ROOT)
end

using NumericalRadiation

include(joinpath(@__DIR__, "ecckd_candidate_original_objective_score.jl"))

const CANDIDATE_TRANSFER_SMOKE_JSON =
    validation_results_path("ecckd_candidate_transfer_smoke.json")
const CANDIDATE_TRANSFER_SMOKE_MD =
    validation_results_path("ecckd_candidate_transfer_smoke.md")

function layer_midpoints(values)
    return 0.5 .* (values[1:(end - 1)] .+ values[2:end])
end

function ckdmip_column_atmosphere(path; column = 1, mu0 = 0.5)
    NCDataset(path) do ds
        pressure_hl = Float64.(ds["pressure_hl"][:, column])
        temperature_hl = Float64.(ds["temperature_hl"][:, column])
        raw_mole_fraction = Array(ds["mole_fraction_fl"][:, :, column])
        mole_fraction = Float64.(coalesce.(raw_mole_fraction, 0.0))
        nlayers = length(pressure_hl) - 1
        gas(index) = index <= size(mole_fraction, 2) ?
                     mole_fraction[:, index] :
                     zeros(Float64, nlayers)
        return ColumnAtmosphere(
            pressure_layers = layer_midpoints(pressure_hl),
            pressure_interfaces = pressure_hl,
            temperature_layers = layer_midpoints(temperature_hl),
            temperature_interfaces = temperature_hl,
            gases = (;
                h2o = gas(1),
                co2 = gas(2),
            ),
            surface = (; temperature = temperature_hl[end], emissivity = 1.0),
            geometry = (; cos_zenith = mu0),
        )
    end
end

function broadband_sample(sample)
    flux_dn = reshape(vec(sum(sample.flux_dn_true; dims = 2)), :, 1)
    flux_up = reshape(vec(sum(sample.flux_up_true; dims = 2)), :, 1)
    heating = sample.kind == "longwave" ?
              ecckd_flux_heating_rate(sample.pressure_hl, flux_dn, flux_up) :
              ecckd_flux_heating_rate(sample.pressure_hl, flux_dn)
    return merge(sample, (
        flux_dn_true = flux_dn,
        flux_up_true = flux_up,
        heating_rate_true = heating,
        band_wavenumber1 = [minimum(sample.band_wavenumber1)],
        band_wavenumber2 = [maximum(sample.band_wavenumber2)],
    ))
end

function transfer_flux_arrays(model, atmosphere, lw_sample, sw_sample)
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

    fluxes = RadiativeFluxes(
        longwave_up = zeros(nlayers + 1),
        longwave_down = zeros(nlayers + 1),
        shortwave_up = zeros(nlayers + 1),
        shortwave_down = zeros(nlayers + 1),
    )
    surface_lw_up = sum(lw_sample.flux_up_true[end, :])
    radiative_fluxes!(
        fluxes,
        CloudlessLongwave(),
        longwave,
        atmosphere,
        LongwaveBoundaryConditions(surface_longwave_up = surface_lw_up),
    )
    sw_down_surface = max(sum(sw_sample.flux_dn_true[end, :]), eps(Float64))
    sw_albedo = clamp(sum(sw_sample.flux_up_true[end, :]) / sw_down_surface, 0.0, 1.0)
    radiative_fluxes!(
        fluxes,
        CloudlessShortwave(),
        shortwave,
        atmosphere,
        ShortwaveBoundaryConditions(
            toa_shortwave_down = sum(sw_sample.flux_dn_true[1, :]),
            surface_albedo = sw_albedo,
        ),
    )
    return longwave, shortwave, fluxes
end

function one_gpoint_longwave_fluxes(optics, ig, atmosphere, boundary)
    nlayers = size(optics.optical_depth, 2)
    source_top = optics.source_top === nothing ? nothing :
                 reshape(optics.source_top[ig, :], 1, nlayers)
    source_bottom = optics.source_bottom === nothing ? nothing :
                    reshape(optics.source_bottom[ig, :], 1, nlayers)
    single = LongwaveOpticalProperties(
        reshape(optics.optical_depth[ig, :], 1, nlayers),
        reshape(optics.source[ig, :], 1, nlayers);
        source_top,
        source_bottom,
        weights = [optics.weights[ig]],
    )
    fluxes = RadiativeFluxes(
        longwave_up = zeros(nlayers + 1),
        longwave_down = zeros(nlayers + 1),
        shortwave_up = zeros(nlayers + 1),
        shortwave_down = zeros(nlayers + 1),
    )
    radiative_fluxes!(fluxes, CloudlessLongwave(), single, atmosphere, boundary)
    return fluxes.longwave_down, fluxes.longwave_up
end

function one_gpoint_shortwave_fluxes(optics, ig, atmosphere, boundary)
    nlayers = size(optics.optical_depth, 2)
    single = ShortwaveOpticalProperties(
        reshape(optics.optical_depth[ig, :], 1, nlayers);
        rayleigh_optical_depth = reshape(optics.rayleigh_optical_depth[ig, :], 1, nlayers),
        scattering_asymmetry = reshape(optics.scattering_asymmetry[ig, :], 1, nlayers),
        weights = [optics.weights[ig]],
    )
    fluxes = RadiativeFluxes(
        longwave_up = zeros(nlayers + 1),
        longwave_down = zeros(nlayers + 1),
        shortwave_up = zeros(nlayers + 1),
        shortwave_down = zeros(nlayers + 1),
    )
    radiative_fluxes!(fluxes, CloudlessShortwave(), single, atmosphere, boundary)
    return fluxes.shortwave_down, fluxes.shortwave_up
end

function spectral_projection_matrix(mapping, band_wavenumber1, band_wavenumber2)
    ng = size(mapping.gpoint_fraction, 2)
    nbands = length(band_wavenumber1)
    projection = zeros(Float64, ng, nbands)
    for i in eachindex(mapping.wavenumber1)
        interval1 = mapping.wavenumber1[i]
        interval2 = mapping.wavenumber2[i]
        width = max(interval2 - interval1, eps(Float64))
        interval_weight = mapping.interval_weight[i]
        for iband in 1:nbands
            overlap = max(0.0,
                          min(interval2, band_wavenumber2[iband]) -
                          max(interval1, band_wavenumber1[iband]))
            overlap == 0 && continue
            factor = interval_weight * overlap / width
            for ig in 1:ng
                projection[ig, iband] += factor * mapping.gpoint_fraction[i, ig]
            end
        end
    end
    for ig in 1:ng
        total = sum(projection[ig, :])
        if total > 0
            projection[ig, :] ./= total
        else
            projection[ig, :] .= inv(Float64(nbands))
        end
    end
    return projection
end

function projected_flux_arrays(longwave, shortwave, atmosphere, lw_sample, sw_sample,
                               longwave_path, shortwave_path)
    nlayers = size(longwave.optical_depth, 2)
    lw_projection = spectral_projection_matrix(
        read_ecckd_spectral_mapping(longwave_path),
        lw_sample.band_wavenumber1,
        lw_sample.band_wavenumber2,
    )
    sw_projection = spectral_projection_matrix(
        read_ecckd_spectral_mapping(shortwave_path),
        sw_sample.band_wavenumber1,
        sw_sample.band_wavenumber2,
    )

    lw_dn = zeros(Float64, nlayers + 1, length(lw_sample.band_wavenumber1))
    lw_up = zeros(Float64, nlayers + 1, length(lw_sample.band_wavenumber1))
    lw_boundary = LongwaveBoundaryConditions(
        surface_longwave_up = sum(lw_sample.flux_up_true[end, :]),
    )
    for ig in 1:size(longwave.optical_depth, 1)
        g_dn, g_up = one_gpoint_longwave_fluxes(longwave, ig, atmosphere, lw_boundary)
        for iband in axes(lw_dn, 2)
            lw_dn[:, iband] .+= lw_projection[ig, iband] .* g_dn
            lw_up[:, iband] .+= lw_projection[ig, iband] .* g_up
        end
    end

    sw_dn = zeros(Float64, nlayers + 1, length(sw_sample.band_wavenumber1))
    sw_up = zeros(Float64, nlayers + 1, length(sw_sample.band_wavenumber1))
    sw_down_surface = max(sum(sw_sample.flux_dn_true[end, :]), eps(Float64))
    sw_albedo = clamp(sum(sw_sample.flux_up_true[end, :]) / sw_down_surface, 0.0, 1.0)
    sw_boundary = ShortwaveBoundaryConditions(
        toa_shortwave_down = sum(sw_sample.flux_dn_true[1, :]),
        surface_albedo = sw_albedo,
    )
    for ig in 1:size(shortwave.optical_depth, 1)
        g_dn, g_up = one_gpoint_shortwave_fluxes(shortwave, ig, atmosphere, sw_boundary)
        for iband in axes(sw_dn, 2)
            sw_dn[:, iband] .+= sw_projection[ig, iband] .* g_dn
            sw_up[:, iband] .+= sw_projection[ig, iband] .* g_up
        end
    end

    return (
        longwave = (flux_dn = lw_dn, flux_up = lw_up),
        shortwave = (flux_dn = sw_dn, flux_up = sw_up),
    )
end

function transfer_objective_scores(lw_sample, sw_sample, fluxes)
    lw_broadband = broadband_sample(lw_sample)
    sw_broadband = broadband_sample(sw_sample)
    lw_dn = reshape(fluxes.longwave_down, :, 1)
    lw_up = reshape(fluxes.longwave_up, :, 1)
    sw_dn = reshape(fluxes.shortwave_down, :, 1)
    sw_up = reshape(fluxes.shortwave_up, :, 1)
    return (
        longwave = (
            loss = candidate_forward_loss(lw_broadband;
                                          flux_dn_fwd = lw_dn,
                                          flux_up_fwd = lw_up),
            finite = isfinite(candidate_forward_loss(lw_broadband;
                                                     flux_dn_fwd = lw_dn,
                                                     flux_up_fwd = lw_up)),
        ),
        shortwave = (
            loss = candidate_forward_loss(sw_broadband;
                                          flux_dn_fwd = sw_dn,
                                          flux_up_fwd = sw_up),
            finite = isfinite(candidate_forward_loss(sw_broadband;
                                                     flux_dn_fwd = sw_dn,
                                                     flux_up_fwd = sw_up)),
        ),
    )
end

function finite_flux_copy(values)
    output = copy(values)
    output .= ifelse.(isfinite.(output) .& (abs.(output) .<= 1.0e6), output, 0.0)
    return output
end

function projected_transfer_objective_scores(lw_sample, sw_sample, projected)
    lw_nonfinite =
        count(!isfinite, projected.longwave.flux_dn) +
        count(!isfinite, projected.longwave.flux_up)
    sw_nonfinite =
        count(!isfinite, projected.shortwave.flux_dn) +
        count(!isfinite, projected.shortwave.flux_up)
    lw_dn = finite_flux_copy(projected.longwave.flux_dn)
    lw_up = finite_flux_copy(projected.longwave.flux_up)
    sw_dn = finite_flux_copy(projected.shortwave.flux_dn)
    sw_up = finite_flux_copy(projected.shortwave.flux_up)
    lw_loss = candidate_forward_loss(lw_sample;
                                     flux_dn_fwd = lw_dn,
                                     flux_up_fwd = lw_up)
    sw_loss = candidate_forward_loss(sw_sample;
                                     flux_dn_fwd = sw_dn,
                                     flux_up_fwd = sw_up)
    return (
        longwave = (
            loss = isfinite(lw_loss) ? lw_loss : nothing,
            finite = isfinite(lw_loss),
            nonfinite_flux_count = lw_nonfinite,
        ),
        shortwave = (
            loss = isfinite(sw_loss) ? sw_loss : nothing,
            finite = isfinite(sw_loss),
            nonfinite_flux_count = sw_nonfinite,
        ),
    )
end

function run_ecckd_candidate_transfer_smoke(; root = ckdmip_data_root(),
                                            candidate_path = VECTOR_TRAINING_CANDIDATE,
                                            column = 1,
                                            mu0_index = 1)
    if root === nothing
        return (
            case = "ecckd_candidate_transfer_smoke",
            timestamp_utc = string(Dates.now()),
            status = "missing_ckdmip_data_root",
            blockers = ["RH_CKDMIP_DATA_PATH is unset or does not point to a directory."],
        )
    end
    lw_path = joinpath(root, expected_flux_path("ckdmip_evaluation1_lw_fluxes_rel-415.h5"))
    sw_path = joinpath(root, expected_flux_path("ckdmip_evaluation1_sw_fluxes_rel-415.h5"))
    missing = [path for path in (lw_path, sw_path, candidate_path) if !isfile(path)]
    if !isempty(missing)
        return (
            case = "ecckd_candidate_transfer_smoke",
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
    model = read_ecckd_tabulated_gas_optics(
        official_ecckd_definition_path(:longwave_32),
        candidate_path;
        gas_names = (:h2o, :co2),
    )
    lw_sample = read_ckdmip_training_sample(lw_path; column, mu0_index)
    sw_sample = read_ckdmip_training_sample(sw_path; column, mu0_index)
    longwave, shortwave, fluxes =
        transfer_flux_arrays(model, atmosphere, lw_sample, sw_sample)
    scores = transfer_objective_scores(lw_sample, sw_sample, fluxes)
    projected = projected_flux_arrays(
        longwave,
        shortwave,
        atmosphere,
        lw_sample,
        sw_sample,
        official_ecckd_definition_path(:longwave_32),
        candidate_path,
    )
    projected_scores = projected_transfer_objective_scores(lw_sample, sw_sample, projected)
    finite = scores.longwave.finite && scores.shortwave.finite &&
        all(isfinite, longwave.optical_depth) &&
        all(isfinite, shortwave.optical_depth) &&
        all(isfinite, fluxes.longwave_up) &&
        all(isfinite, fluxes.shortwave_down)
    return (
        case = "ecckd_candidate_transfer_smoke",
        timestamp_utc = string(Dates.now()),
        status = finite ? "candidate_transfer_smoke_ready" :
                 "candidate_transfer_smoke_failed",
        candidate_path = candidate_path,
        column = column,
        mu0 = mu0,
        layer_count = length(atmosphere.temperature_layers),
        longwave_gpoints = size(longwave.optical_depth, 1),
        shortwave_gpoints = size(shortwave.optical_depth, 1),
        longwave_optical_depth_max = maximum(longwave.optical_depth),
        shortwave_optical_depth_max = maximum(shortwave.optical_depth),
        shortwave_rayleigh_optical_depth_max = maximum(shortwave.rayleigh_optical_depth),
        longwave_surface_up = fluxes.longwave_up[end],
        longwave_toa_up = fluxes.longwave_up[1],
        shortwave_toa_down = fluxes.shortwave_down[1],
        shortwave_surface_down = fluxes.shortwave_down[end],
        shortwave_toa_up = fluxes.shortwave_up[1],
        objective_scores = scores,
        spectral_projection_objective_scores = projected_scores,
        longwave_projection_band_count = size(projected.longwave.flux_dn, 2),
        shortwave_projection_band_count = size(projected.shortwave.flux_dn, 2),
        blockers = String[],
        remaining_gap =
            "This is a cloudless transfer smoke test through package gas optics and solvers. It now includes a g-point-to-CKDMIP-band spectral projection score, but full recovery still requires the differentiable ecCKD/equivalent spectral transfer used by the original objective.",
    )
end

function write_json(path, result)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON.print(io, result, 2)
        println(io)
    end
end

function markdown_transfer_smoke(result)
    lines = String[
        "# ecCKD Candidate Transfer Smoke",
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
    if hasproperty(result, :objective_scores)
        append!(lines, [
            "",
            "## Transfer Metrics",
            "",
            "| Metric | Value |",
            "|---|---:|",
            "| Layers | $(result.layer_count) |",
            "| LW g-points | $(result.longwave_gpoints) |",
            "| SW g-points | $(result.shortwave_gpoints) |",
            "| LW optical-depth max | $(result.longwave_optical_depth_max) |",
            "| SW optical-depth max | $(result.shortwave_optical_depth_max) |",
            "| SW Rayleigh optical-depth max | $(result.shortwave_rayleigh_optical_depth_max) |",
            "| LW original-objective broadband loss | $(result.objective_scores.longwave.loss) |",
            "| SW original-objective broadband loss | $(result.objective_scores.shortwave.loss) |",
            "| LW spectral-projection bands | $(result.longwave_projection_band_count) |",
            "| SW spectral-projection bands | $(result.shortwave_projection_band_count) |",
            "| LW spectral-projection original-objective loss | $(result.spectral_projection_objective_scores.longwave.loss) |",
            "| SW spectral-projection original-objective loss | $(result.spectral_projection_objective_scores.shortwave.loss) |",
            "| LW spectral-projection non-finite flux count | $(result.spectral_projection_objective_scores.longwave.nonfinite_flux_count) |",
            "| SW spectral-projection non-finite flux count | $(result.spectral_projection_objective_scores.shortwave.nonfinite_flux_count) |",
        ])
        push!(lines, "", result.remaining_gap)
    end
    return join(lines, "\n") * "\n"
end

function ecckd_candidate_transfer_smoke_main()
    result = run_ecckd_candidate_transfer_smoke()
    write_json(CANDIDATE_TRANSFER_SMOKE_JSON, result)
    write(CANDIDATE_TRANSFER_SMOKE_MD, markdown_transfer_smoke(result))
    print(markdown_transfer_smoke(result))
    println("Wrote $CANDIDATE_TRANSFER_SMOKE_JSON")
    println("Wrote $CANDIDATE_TRANSFER_SMOKE_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    ecckd_candidate_transfer_smoke_main()
end
