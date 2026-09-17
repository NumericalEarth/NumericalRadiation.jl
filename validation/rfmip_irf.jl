#####
##### RFMIP-IRF clear-sky benchmark against LBLRTM
#####
#
# Runs the 100 RFMIP-IRF sites (Pincus et al., 2016, GMD 9, 3447) of
# experiment 1, present day, through the reference ecCKD models
# `climate_32x32` and `climate_64x64` — `optical_properties!` followed by the
# streaming longwave and shortwave solvers — and compares the broadband
# fluxes with the LBLRTM 12.8 reference fluxes published for CMIP6
# (AER, `rad-irf`, r1i1p1f1, version v20190514).
#
# Input: `multiple_input4MIPs_radiation_RFMIP_UColorado-RFMIP-1-2_none.nc`
# (site = 100, layer = 60, level = 61, expt = 18; levels top-down from
# 0.01 Pa) and `r{l,s}{u,d}_Efx_LBLRTM-12-8_rad-irf_r1i1p1f1_gn.nc`. The five
# files are downloaded to `validation/data/rfmip/` (or the directory named
# by NUMERICAL_RADIATION_RFMIP_PATH) when they are not already there; if a
# download fails the URLs are printed and the benchmark is skipped with
# `@test_skip`, so a network problem never fails CI.
#
# Conventions:
#   * layer and level pressures and temperatures, the surface (skin)
#     temperature, emissivity (0.98), albedo, solar zenith angle and total
#     solar irradiance are the file's per-site values; H₂O and O₃ are the
#     per-layer mole fractions relative to dry air, the well-mixed gases the
#     `*_GM` values of experiment 1 (units attribute applied);
#   * the ecCKD tables carry CFC-11 and CFC-12: CFC-11 is fed the CMIP6
#     "CFC-11-equivalent" (all halocarbons other than CFC-12 mapped onto
#     CFC-11), CFC-12 its own value; CO, N₂O₅, etc. are not represented;
#   * gated runs use the dry column-amount convention of the ecCKD tables,
#     `nᵈ = Δp / (g mᵈ)`; the moist-molar-mass convention is reported alongside;
#   * shortwave statistics use the sites where the reference has sunlight
#     (50 of 100: site 46 has the sun 2.4° above the horizon but no sunlight
#     in the LBLRTM files, so it is left out). At the night sites the model
#     gives exactly zero.
#
# LBLRTM is an independent line-by-line model from the one the ecCKD tables
# were trained on (CKDMIP's LBLRTM runs with a different halocarbon set and a
# different treatment of the surface), so the gates are looser than CKDMIP's
# and were set from the first run with about 50 % headroom; they are
# regression gates, not accuracy claims.
#
# Observed on 2026-09-16 (Float64, dry column-amount convention; every gate
# passes). Fluxes in W m⁻², heating rates in K day⁻¹; "trop" is p > 100 hPa,
# "strat" 4 Pa < p ≤ 100 hPa, and the CKDMIP ranges are 0.02–4 / 4–1100 hPa:
#
#   climate_32x32 (32 LW × 32 SW g-points)
#     LW TOA up            bias +0.408  RMSE 0.629     (gate |bias| ≤ 0.6, RMSE ≤ 1.0)
#     LW surface down      bias +0.387  RMSE 1.356     (gate |bias| ≤ 0.6, RMSE ≤ 2.0)
#     LW heating rate      trop 0.2041 (gate ≤ 0.30); 0.1266 without the two lowest layers
#                          strat 0.5499; CKDMIP ranges 0.9513 / 0.1776
#     SW TOA up            RMSE 0.350 (gate ≤ 0.6), bias +0.012
#     SW surface down      RMSE 0.956 (gate ≤ 1.5), bias +0.576
#     SW heating rate      trop 0.0398 (gate ≤ 0.06)
#     exact angular integration (3-node Gauss–Legendre instead of D = 1.66):
#                          LW TOA up +0.228 / 0.402, surface down -0.446 / 0.883, trop 0.2019, strat 0.5892
#     moist convention     LW surface down bias +0.087 RMSE 1.182; SW surface down RMSE 1.168
#
#   climate_64x64 (64 LW × 64 SW g-points)
#     LW TOA up            bias +0.358  RMSE 0.540
#     LW surface down      bias +0.363  RMSE 1.408
#     LW heating rate      trop 0.2022; 0.1283 without the two lowest layers
#                          strat 0.5850; CKDMIP ranges 1.0147 / 0.1755
#     SW TOA up            RMSE 0.322, bias +0.176
#     SW surface down      RMSE 1.039, bias +0.667
#     SW heating rate      trop 0.0401
#     exact angular integration:
#                          LW TOA up +0.279 / 0.412, surface down -0.475 / 0.929, trop 0.1991, strat 0.6170
#     moist convention     LW surface down bias +0.061 RMSE 1.239; SW surface down RMSE 1.242
#
# The tropospheric longwave heating-rate error sits in the two 200–300 Pa
# layers next to the surface, whose skin temperature differs from the air by
# up to 9 K: the reference heats them by 20–50 K day⁻¹ and the CKD models by
# about 11 % less (median), for 32 and 64 g-points alike; the angular
# integration is not the cause (it changes that statistic by 1 %).
#
# Reports (JSON per model and one Markdown summary) are written to
# NUMERICAL_RADIATION_VALIDATION_RESULTS_DIR, by default `validation/results/`.
#
# Run from the package root, in an environment with NCDatasets (the test
# environment works once the package is developed into it):
#
#   julia --project=test -e 'using Pkg; Pkg.develop(path=".")'
#   julia --project=test validation/rfmip_irf.jl

include(joinpath(@__DIR__, "common.jl"))

using Downloads

const RFMIP_INPUT_FILE = "multiple_input4MIPs_radiation_RFMIP_UColorado-RFMIP-1-2_none.nc"
const RFMIP_INPUT_URL = "https://raw.githubusercontent.com/earth-system-radiation/rrtmgp-data/main/examples/rfmip-clear-sky/inputs/" *
                        RFMIP_INPUT_FILE
const RFMIP_FLUX_VARIABLES = ("rlu", "rld", "rsu", "rsd")
rfmip_flux_file(variable) = "$(variable)_Efx_LBLRTM-12-8_rad-irf_r1i1p1f1_gn.nc"
rfmip_flux_url(variable) = "https://g-52ba3.fd635.8443.data.globus.org/css03_data/CMIP6/RFMIP/AER/LBLRTM-12-8/rad-irf/" *
                           "r1i1p1f1/Efx/$(variable)/gn/v20190514/" * rfmip_flux_file(variable)
const RFMIP_EXPERIMENT = 1   # present day

# Regression gates (W m⁻² for fluxes, K day⁻¹ for heating rates), set from the
# first run with about 50 % headroom; see the header.
const RFMIP_GATES = (
    climate_32x32 = (lw_toa_up = (bias = 0.6, rmse = 1.0),
                     lw_surface_down = (bias = 0.6, rmse = 2.0),
                     lw_heating_rate_troposphere = 0.30,
                     sw_toa_up = 0.6,
                     sw_surface_down = 1.5,
                     sw_heating_rate_troposphere = 0.06),
    climate_64x64 = (lw_toa_up = (bias = 0.6, rmse = 1.0),
                     lw_surface_down = (bias = 0.6, rmse = 2.0),
                     lw_heating_rate_troposphere = 0.30,
                     sw_toa_up = 0.6,
                     sw_surface_down = 1.5,
                     sw_heating_rate_troposphere = 0.06),
)

rfmip_data_dir() = normpath(get(ENV, "NUMERICAL_RADIATION_RFMIP_PATH", joinpath(@__DIR__, "data", "rfmip")))

# Local paths of the input and the four LBLRTM flux files, downloading those
# that are missing; `nothing` when any of them is unavailable.
function rfmip_files()
    dir = rfmip_data_dir()
    mkpath(dir)
    wanted = [(RFMIP_INPUT_FILE, RFMIP_INPUT_URL);
              [(rfmip_flux_file(v), rfmip_flux_url(v)) for v in RFMIP_FLUX_VARIABLES]]
    paths = String[]
    missing_urls = String[]
    for (filename, url) in wanted
        path = joinpath(dir, filename)
        if !isfile(path)
            partial = path * ".part"
            try
                println("Downloading $(url)")
                Downloads.download(url, partial; timeout = 300)
                mv(partial, path; force = true)
            catch err
                @warn "Download failed" url exception = (err, catch_backtrace())
                isfile(partial) && rm(partial; force = true)
                push!(missing_urls, url)
                continue
            end
        end
        push!(paths, path)
    end
    if !isempty(missing_urls)
        println("RFMIP-IRF files could not be downloaded. Fetch them by hand into $(dir) " *
                "(or set NUMERICAL_RADIATION_RFMIP_PATH to a directory holding them):")
        foreach(url -> println("  ", url), missing_urls)
        return nothing
    end
    return (input = paths[1], fluxes = NamedTuple{Symbol.(RFMIP_FLUX_VARIABLES)}(Tuple(paths[2:end])))
end

# Scale a `*_GM` well-mixed-gas value by its units attribute ("1.e-6" etc.).
function scaled_global_mean(ds, name, experiment)
    variable = ds[name]
    scale = parse(Float64, replace(get(variable.attrib, "units", "1"), " " => ""))
    return Float64(variable[experiment]) * scale
end

function load_rfmip(paths; experiment = RFMIP_EXPERIMENT)
    sites = NCDataset(paths.input) do ds
        (; pressure_layers = dense(ds["pres_layer"][:, :]),
           pressure_interfaces = dense(ds["pres_level"][:, :]),
           temperature_layers = dense(ds["temp_layer"][:, :, experiment]),
           temperature_interfaces = dense(ds["temp_level"][:, :, experiment]),
           surface_temperature = dense(ds["surface_temperature"][:, experiment]),
           surface_emissivity = dense(ds["surface_emissivity"][:]),
           surface_albedo = dense(ds["surface_albedo"][:]),
           solar_zenith_angle = dense(ds["solar_zenith_angle"][:]),
           total_solar_irradiance = dense(ds["total_solar_irradiance"][:]),
           h2o = dense(ds["water_vapor"][:, :, experiment]),
           o3 = dense(ds["ozone"][:, :, experiment]),
           co2 = scaled_global_mean(ds, "carbon_dioxide_GM", experiment),
           ch4 = scaled_global_mean(ds, "methane_GM", experiment),
           n2o = scaled_global_mean(ds, "nitrous_oxide_GM", experiment),
           cfc11 = scaled_global_mean(ds, "cfc11eq_GM", experiment),
           cfc12 = scaled_global_mean(ds, "cfc12_GM", experiment),
           experiment_label = String(ds["expt_label"][experiment]))
    end
    reference = map(paths.fluxes) do path
        NCDataset(path) do ds
            variable = first(v for v in RFMIP_FLUX_VARIABLES if haskey(ds, v))
            dense(ds[variable][:, :, experiment])
        end
    end
    nsites = size(sites.pressure_interfaces, 2)
    all(size(flux) == size(sites.pressure_interfaces) for flux in reference) ||
        throw(DimensionMismatch("LBLRTM flux shapes do not match the input levels"))
    # Levels run top-down from 0.01 Pa, as the solvers expect.
    all(sites.pressure_interfaces[1, :] .< sites.pressure_interfaces[end, :]) ||
        throw(ArgumentError("RFMIP levels are expected top-down"))
    cos_zenith = cosd.(sites.solar_zenith_angle)
    # Daytime is where the reference has sunlight: LBLRTM treated one site
    # with the sun 2.4° above the horizon (site 46, μ₀ = 0.042) as night.
    daytime = findall(i -> cos_zenith[i] > 0 && reference.rsd[1, i] > 0, 1:nsites)
    excluded_sites = findall(i -> cos_zenith[i] > 0 && reference.rsd[1, i] == 0, 1:nsites)
    return (; sites..., reference, nsites, cos_zenith, daytime, excluded_sites)
end

function evaluate_rfmip(model_name, benchmark; column_amount_convention = :dry)
    (; nsites, cos_zenith, daytime, reference) = benchmark
    nlayers = size(benchmark.pressure_layers, 1)
    model = read_reference_ecckd_gas_optics(model_name; names = ECCKD_GAS_NAMES)
    workspace = ColumnWorkspace(model, nlayers)

    lw_up = zeros(nlayers + 1, nsites)
    lw_down = zeros(nlayers + 1, nsites)
    sw_up = zeros(nlayers + 1, nsites)
    sw_down = zeros(nlayers + 1, nsites)
    heating = (lw = zeros(nlayers, nsites), lw_reference = zeros(nlayers, nsites),
               sw = zeros(nlayers, nsites), sw_reference = zeros(nlayers, nsites),
               lw_quadrature = zeros(nlayers, nsites))
    # Informational: the same longwave optics with exact angular integration
    # (3-node Gauss–Legendre, as LBLRTM's RADSUM) instead of D = 1.66.
    quadrature = gauss_legendre_flux_nodes(3)
    lw_up_quadrature = zeros(nlayers + 1, nsites)
    lw_down_quadrature = zeros(nlayers + 1, nsites)

    site_mole_fractions(i) = (h2o = benchmark.h2o[:, i], o3 = benchmark.o3[:, i],
                              co2 = benchmark.co2, ch4 = benchmark.ch4, n2o = benchmark.n2o,
                              cfc11 = benchmark.cfc11, cfc12 = benchmark.cfc12)

    site_column(i) = benchmark_column(benchmark.pressure_interfaces[:, i], benchmark.temperature_interfaces[:, i],
                                      site_mole_fractions(i);
                                      pressure_layers = benchmark.pressure_layers[:, i],
                                      temperature_layers = benchmark.temperature_layers[:, i],
                                      surface = (; temperature = benchmark.surface_temperature[i],
                                                   emissivity = benchmark.surface_emissivity[i]),
                                      geometry = (; cos_zenith = cos_zenith[i]),
                                      column_amount_convention)

    # One untimed column first, so that the timing below excludes compilation.
    column_fluxes!(workspace, model, site_column(1); surface_temperature = benchmark.surface_temperature[1],
                   emissivity = benchmark.surface_emissivity[1], albedo = benchmark.surface_albedo[1],
                   cos_zeniths = (cos_zenith[1],), solar_constant = benchmark.total_solar_irradiance[1])

    elapsed = 0.0   # optics and solves only
    for i in 1:nsites
        surface_temperature = benchmark.surface_temperature[i]
        emissivity = benchmark.surface_emissivity[i]
        atmosphere = site_column(i)
        elapsed += @elapsed fluxes = column_fluxes!(workspace, model, atmosphere; surface_temperature, emissivity,
                                                   albedo = benchmark.surface_albedo[i], cos_zeniths = (cos_zenith[i],),
                                                   solar_constant = benchmark.total_solar_irradiance[i])
        lw_up[:, i] = fluxes.longwave_up
        lw_down[:, i] = fluxes.longwave_down
        sw_up[:, i] = fluxes.shortwave_up[:, 1]
        sw_down[:, i] = fluxes.shortwave_down[:, 1]
        heating.lw[:, i] = heating_rate_per_day(fluxes.longwave_up, fluxes.longwave_down, atmosphere)
        heating.lw_reference[:, i] = heating_rate_per_day(reference.rlu[:, i], reference.rld[:, i], atmosphere)
        heating.sw[:, i] = heating_rate_per_day(sw_up[:, i], sw_down[:, i], atmosphere)
        heating.sw_reference[:, i] = heating_rate_per_day(reference.rsu[:, i], reference.rsd[:, i], atmosphere)
        longwave_quadrature_fluxes!(view(lw_up_quadrature, :, i), view(lw_down_quadrature, :, i), workspace.longwave,
                                    model.longwave_weights, length(model.longwave_weights), nlayers,
                                    TabulatedSurfaceEmission(model, surface_temperature; emissivity), 1 - emissivity, quadrature)
        heating.lw_quadrature[:, i] = heating_rate_per_day(lw_up_quadrature[:, i], lw_down_quadrature[:, i], atmosphere)
    end

    p_hl = benchmark.pressure_interfaces
    day = daytime
    night = findall(<=(0), cos_zenith)
    heating_ranges(p, hr, ref) = map(range -> weighted_heating_rate_rmse(p, hr, ref, range), HEATING_RATE_RANGES)
    statistics = (;
        lw_toa_up = (bias = bias(lw_up[1, :], reference.rlu[1, :]), rmse = rmse(lw_up[1, :], reference.rlu[1, :])),
        lw_surface_down = (bias = bias(lw_down[end, :], reference.rld[end, :]), rmse = rmse(lw_down[end, :], reference.rld[end, :])),
        lw_surface_up = (bias = bias(lw_up[end, :], reference.rlu[end, :]), rmse = rmse(lw_up[end, :], reference.rlu[end, :])),
        lw_profile_rmse = (up = rmse(lw_up, reference.rlu), down = rmse(lw_down, reference.rld)),
        lw_heating_rate = heating_ranges(p_hl, heating.lw, heating.lw_reference),
        sw_toa_up = (bias = bias(sw_up[1, day], reference.rsu[1, day]), rmse = rmse(sw_up[1, day], reference.rsu[1, day])),
        sw_surface_down = (bias = bias(sw_down[end, day], reference.rsd[end, day]), rmse = rmse(sw_down[end, day], reference.rsd[end, day])),
        sw_toa_down_max_relative_error = maximum(abs, sw_down[1, day] ./ reference.rsd[1, day] .- 1),
        sw_profile_rmse = (up = rmse(sw_up[:, day], reference.rsu[:, day]), down = rmse(sw_down[:, day], reference.rsd[:, day])),
        sw_heating_rate = heating_ranges(p_hl[:, day], heating.sw[:, day], heating.sw_reference[:, day]),
        night_sites_max_flux = maximum(abs, [sw_up[:, night]; sw_down[:, night]]),
        lw_heating_rate_troposphere_above_lowest_two_layers =
            weighted_heating_rate_rmse(p_hl, heating.lw, heating.lw_reference, HEATING_RATE_RANGES.troposphere;
                                       exclude_lowest = 2),
        lw_quadrature = (toa_up = (bias = bias(lw_up_quadrature[1, :], reference.rlu[1, :]),
                                   rmse = rmse(lw_up_quadrature[1, :], reference.rlu[1, :])),
                         surface_down = (bias = bias(lw_down_quadrature[end, :], reference.rld[end, :]),
                                         rmse = rmse(lw_down_quadrature[end, :], reference.rld[end, :])),
                         heating_rate = heating_ranges(p_hl, heating.lw_quadrature, heating.lw_reference)),
    )

    gates_for = getproperty(RFMIP_GATES, Symbol(model_name))
    gates = [
        flux_gate("LW TOA up"; statistics.lw_toa_up...,
                  rmse_threshold = gates_for.lw_toa_up.rmse, bias_threshold = gates_for.lw_toa_up.bias),
        flux_gate("LW surface down"; statistics.lw_surface_down...,
                  rmse_threshold = gates_for.lw_surface_down.rmse, bias_threshold = gates_for.lw_surface_down.bias),
        heating_rate_gate("LW heating rate, p > 100 hPa";
                          rmse = statistics.lw_heating_rate.troposphere,
                          rmse_threshold = gates_for.lw_heating_rate_troposphere),
        flux_gate("SW TOA up, μ₀ > 0"; rmse = statistics.sw_toa_up.rmse, rmse_threshold = gates_for.sw_toa_up),
        flux_gate("SW surface down, μ₀ > 0"; rmse = statistics.sw_surface_down.rmse, rmse_threshold = gates_for.sw_surface_down),
        heating_rate_gate("SW heating rate, p > 100 hPa, μ₀ > 0";
                          rmse = statistics.sw_heating_rate.troposphere,
                          rmse_threshold = gates_for.sw_heating_rate_troposphere),
    ]

    return (; model_name = String(model_name),
              longwave_gpoints = length(model.longwave_weights),
              shortwave_gpoints = length(model.shortwave_weights),
              nsites, nlayers, ndaytime = length(day), excluded_sites = benchmark.excluded_sites,
              column_amount_convention,
              elapsed_seconds = elapsed,
              microseconds_per_column = 1e6 * elapsed / nsites,
              statistics, gates)
end

function rfmip_markdown(results, benchmark)
    lines = String[]
    push!(lines, "# RFMIP-IRF clear-sky benchmark of the reference ecCKD models against LBLRTM")
    push!(lines, "")
    push!(lines, "Generated $(Dates.format(now(), "yyyy-mm-dd HH:MM")) by `validation/rfmip_irf.jl`.")
    push!(lines, "")
    push!(lines, "$(benchmark.nsites) sites of experiment $(RFMIP_EXPERIMENT) (\"$(benchmark.experiment_label)\"), " *
                 "$(size(benchmark.pressure_layers, 1)) layers from $(benchmark.pressure_interfaces[1, 1]) Pa; " *
                 "per-site skin temperature, emissivity, albedo, solar zenith angle and total solar irradiance; " *
                 "$(length(benchmark.daytime)) daytime sites enter the shortwave statistics" *
                 (isempty(benchmark.excluded_sites) ? "" :
                  " (sites $(benchmark.excluded_sites) have the sun above the horizon but no sunlight in the reference and are left out)") * ". " *
                 "Reference: LBLRTM 12.8 (AER, `rad-irf`, r1i1p1f1, v20190514). Well-mixed gases: " *
                 @sprintf("CO₂ %.1f ppm, CH₄ %.1f ppb, N₂O %.1f ppb, CFC-11-eq %.1f ppt, CFC-12 %.1f ppt.",
                          1e6 * benchmark.co2, 1e9 * benchmark.ch4, 1e9 * benchmark.n2o, 1e12 * benchmark.cfc11, 1e12 * benchmark.cfc12))
    push!(lines, "")
    push!(lines, "Heating-rate RMSEs are weighted by the cube root of pressure within the range " *
                 "(the CKDMIP statistic); fluxes in W m⁻², heating rates in K day⁻¹. Gated runs use the " *
                 "dry column-amount convention `nᵈ = Δp / (g mᵈ)` of the ecCKD tables; the rows marked " *
                 "\"moist convention\" use `nᵈ = Δp / (g (mᵈ + mᵛ χ_H₂O))`.")
    for r in results
        s = r.statistics
        m = r.moist_convention_statistics
        push!(lines, "")
        push!(lines, "## $(r.model_name) ($(r.longwave_gpoints) LW × $(r.shortwave_gpoints) SW g-points)")
        push!(lines, "")
        push!(lines, "$(round(r.microseconds_per_column; digits = 1)) μs per column (optics + LW + SW), " *
                     "$(round(r.elapsed_seconds; digits = 3)) s total.")
        push!(lines, "")
        push!(lines, markdown_gate_table(r.gates))
        push!(lines, "")
        push!(lines, "Additional statistics:")
        push!(lines, "")
        push!(lines, markdown_row(("Quantity", "Value")))
        push!(lines, markdown_row(("---", "---")))
        push!(lines, markdown_row(("LW surface up bias / RMSE", @sprintf("%+.3f / %.3f W m⁻²", s.lw_surface_up.bias, s.lw_surface_up.rmse))))
        push!(lines, markdown_row(("LW profile RMSE up / down", @sprintf("%.3f / %.3f W m⁻²", s.lw_profile_rmse.up, s.lw_profile_rmse.down))))
        push!(lines, markdown_row(("LW heating rate RMSE p > 100 hPa without the two lowest layers",
                                   @sprintf("%.4f K day⁻¹", s.lw_heating_rate_troposphere_above_lowest_two_layers))))
        push!(lines, markdown_row(("LW heating rate RMSE 4 Pa < p ≤ 100 hPa", @sprintf("%.4f K day⁻¹", s.lw_heating_rate.stratosphere))))
        push!(lines, markdown_row(("LW heating rate RMSE 0.02–4 hPa / 4–1100 hPa",
                                   @sprintf("%.4f / %.4f K day⁻¹", s.lw_heating_rate.ckdmip_upper, s.lw_heating_rate.ckdmip_lower))))
        push!(lines, markdown_row(("SW TOA up bias / SW surface down bias (μ₀ > 0)", @sprintf("%+.3f / %+.3f W m⁻²", s.sw_toa_up.bias, s.sw_surface_down.bias))))
        push!(lines, markdown_row(("SW profile RMSE up / down (μ₀ > 0)", @sprintf("%.3f / %.3f W m⁻²", s.sw_profile_rmse.up, s.sw_profile_rmse.down))))
        push!(lines, markdown_row(("SW heating rate RMSE 4 Pa < p ≤ 100 hPa (μ₀ > 0)", @sprintf("%.4f K day⁻¹", s.sw_heating_rate.stratosphere))))
        push!(lines, markdown_row(("SW TOA down max relative error (S₀ μ₀ check)", @sprintf("%.1e", s.sw_toa_down_max_relative_error))))
        push!(lines, markdown_row(("Night sites max |SW flux|", @sprintf("%.2e W m⁻²", s.night_sites_max_flux))))
        q = s.lw_quadrature
        push!(lines, markdown_row(("Exact angular integration: LW TOA up bias / RMSE", @sprintf("%+.3f / %.3f W m⁻²", q.toa_up.bias, q.toa_up.rmse))))
        push!(lines, markdown_row(("Exact angular integration: LW surface down bias / RMSE", @sprintf("%+.3f / %.3f W m⁻²", q.surface_down.bias, q.surface_down.rmse))))
        push!(lines, markdown_row(("Exact angular integration: LW heating rate RMSE p > 100 hPa / 4 Pa < p ≤ 100 hPa",
                                   @sprintf("%.4f / %.4f K day⁻¹", q.heating_rate.troposphere, q.heating_rate.stratosphere))))
        push!(lines, markdown_row(("Moist convention: LW TOA up bias / RMSE", @sprintf("%+.3f / %.3f W m⁻²", m.lw_toa_up.bias, m.lw_toa_up.rmse))))
        push!(lines, markdown_row(("Moist convention: LW surface down bias / RMSE", @sprintf("%+.3f / %.3f W m⁻²", m.lw_surface_down.bias, m.lw_surface_down.rmse))))
        push!(lines, markdown_row(("Moist convention: LW heating rate RMSE p > 100 hPa", @sprintf("%.4f K day⁻¹", m.lw_heating_rate.troposphere))))
        push!(lines, markdown_row(("Moist convention: SW TOA up RMSE / surface down RMSE (μ₀ > 0)",
                                   @sprintf("%.3f / %.3f W m⁻²", m.sw_toa_up.rmse, m.sw_surface_down.rmse))))
    end
    push!(lines, "")
    return join(lines, "\n")
end

function run_rfmip_irf(; models = (:climate_32x32, :climate_64x64))
    results_dir = validation_results_dir()
    results = []
    @testset "RFMIP-IRF clear sky" begin
        paths = rfmip_files()
        if paths === nothing
            @test_skip "RFMIP-IRF input or LBLRTM reference files not available"
            return results
        end
        model_paths = reference_ecckd_definition_paths(:climate_32x32; require = false)
        if model_paths.longwave === nothing
            @test_skip "ecrad_data artifact not available"
            return results
        end
        benchmark = load_rfmip(paths)
        println("RFMIP-IRF: $(benchmark.nsites) sites, experiment $(RFMIP_EXPERIMENT) ($(benchmark.experiment_label)), " *
                "$(length(benchmark.daytime)) daytime sites")
        for model_name in models
            result = evaluate_rfmip(model_name, benchmark)
            moist = evaluate_rfmip(model_name, benchmark; column_amount_convention = :moist)
            result = (; result..., moist_convention_statistics = moist.statistics)
            push!(results, result)
            println("\n$(result.model_name): $(round(result.microseconds_per_column; digits = 1)) μs per column")
            report_gates(result.gates)
            @testset "$(result.model_name)" begin
                # The reference TOA downwelling flux is `S₀ μ₀` (stored in single
                # precision), which the solver reproduces.
                @test result.statistics.sw_toa_down_max_relative_error < 1e-5
                @test result.statistics.night_sites_max_flux == 0
                for gate in result.gates
                    ok, errors = gate_passes(gate)
                    @testset "$(gate.name)" begin
                        @test ok
                        ok || println("  $(gate.name): ", join(errors, "; "))
                    end
                end
            end
            record = (; benchmark = "RFMIP-IRF experiment $(RFMIP_EXPERIMENT) ($(benchmark.experiment_label)) vs LBLRTM 12.8",
                        generated = string(now()),
                        input_files = [basename(paths.input); collect(basename.(values(paths.fluxes)))],
                        model = result.model_name,
                        longwave_gpoints = result.longwave_gpoints,
                        shortwave_gpoints = result.shortwave_gpoints,
                        nsites = result.nsites, ndaytime = result.ndaytime, excluded_sites = result.excluded_sites,
                        nlayers = result.nlayers,
                        well_mixed_mole_fractions = (; co2 = benchmark.co2, ch4 = benchmark.ch4, n2o = benchmark.n2o,
                                                       cfc11 = benchmark.cfc11, cfc12 = benchmark.cfc12),
                        column_amount_convention = result.column_amount_convention,
                        elapsed_seconds = result.elapsed_seconds,
                        microseconds_per_column = result.microseconds_per_column,
                        heating_rate_ranges_Pa = map(r -> collect(r), HEATING_RATE_RANGES),
                        statistics = result.statistics,
                        moist_convention_statistics = result.moist_convention_statistics,
                        gates = gate_records(result.gates),
                        passes = all(first ∘ gate_passes, result.gates))
            write_json(joinpath(results_dir, "rfmip_irf_$(result.model_name).json"), record)
        end
        write(joinpath(results_dir, "rfmip_irf.md"), rfmip_markdown(results, benchmark))
        println("\nReports written to $(results_dir)")
    end
    return results
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_rfmip_irf()
end
