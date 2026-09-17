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
    climate_32x32 = (longwave_toa_up = (bias = 0.6, rmse = 1.0),
                     longwave_surface_down = (bias = 0.6, rmse = 2.0),
                     longwave_heating_rate_troposphere = 0.30,
                     shortwave_toa_up = 0.6,
                     shortwave_surface_down = 1.5,
                     shortwave_heating_rate_troposphere = 0.06),
    climate_64x64 = (longwave_toa_up = (bias = 0.6, rmse = 1.0),
                     longwave_surface_down = (bias = 0.6, rmse = 2.0),
                     longwave_heating_rate_troposphere = 0.30,
                     shortwave_toa_up = 0.6,
                     shortwave_surface_down = 1.5,
                     shortwave_heating_rate_troposphere = 0.06),
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
            catch exception
                @warn "Download failed" url exception = (exception, catch_backtrace())
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
function scaled_global_mean(dataset, name, experiment)
    variable = dataset[name]
    scale = parse(Float64, replace(get(variable.attrib, "units", "1"), " " => ""))
    return Float64(variable[experiment]) * scale
end

function load_rfmip(paths; experiment = RFMIP_EXPERIMENT)
    sites = NCDataset(paths.input) do dataset
        (; pressure_layers = dense(dataset["pres_layer"][:, :]),
           pressure_interfaces = dense(dataset["pres_level"][:, :]),
           temperature_layers = dense(dataset["temp_layer"][:, :, experiment]),
           temperature_interfaces = dense(dataset["temp_level"][:, :, experiment]),
           surface_temperature = dense(dataset["surface_temperature"][:, experiment]),
           surface_emissivity = dense(dataset["surface_emissivity"][:]),
           surface_albedo = dense(dataset["surface_albedo"][:]),
           solar_zenith_angle = dense(dataset["solar_zenith_angle"][:]),
           total_solar_irradiance = dense(dataset["total_solar_irradiance"][:]),
           h2o = dense(dataset["water_vapor"][:, :, experiment]),
           o3 = dense(dataset["ozone"][:, :, experiment]),
           co2 = scaled_global_mean(dataset, "carbon_dioxide_GM", experiment),
           ch4 = scaled_global_mean(dataset, "methane_GM", experiment),
           n2o = scaled_global_mean(dataset, "nitrous_oxide_GM", experiment),
           cfc11 = scaled_global_mean(dataset, "cfc11eq_GM", experiment),
           cfc12 = scaled_global_mean(dataset, "cfc12_GM", experiment),
           experiment_label = String(dataset["expt_label"][experiment]))
    end
    reference = map(paths.fluxes) do path
        NCDataset(path) do dataset
            variable = first(v for v in RFMIP_FLUX_VARIABLES if haskey(dataset, v))
            dense(dataset[variable][:, :, experiment])
        end
    end
    Nsites = size(sites.pressure_interfaces, 2)
    all(size(flux) == size(sites.pressure_interfaces) for flux in reference) ||
        throw(DimensionMismatch("LBLRTM flux shapes do not match the input levels"))
    # Levels run top-down from 0.01 Pa, as the solvers expect.
    all(sites.pressure_interfaces[1, :] .< sites.pressure_interfaces[end, :]) ||
        throw(ArgumentError("RFMIP levels are expected top-down"))
    μ₀ = cosd.(sites.solar_zenith_angle)
    # Daytime is where the reference has sunlight: LBLRTM treated one site
    # with the sun 2.4° above the horizon (site 46, μ₀ = 0.042) as night.
    daytime = findall(i -> μ₀[i] > 0 && reference.rsd[1, i] > 0, 1:Nsites)
    excluded_sites = findall(i -> μ₀[i] > 0 && reference.rsd[1, i] == 0, 1:Nsites)
    return (; sites..., reference, Nsites, μ₀, daytime, excluded_sites)
end

function evaluate_rfmip(model_name, benchmark; column_amount_convention = :dry)
    (; Nsites, μ₀, daytime, reference) = benchmark
    Nz = size(benchmark.pressure_layers, 1)
    model = read_reference_ecckd_gas_optics(model_name; names = ECCKD_GAS_NAMES)
    workspace = ColumnWorkspace(model, Nz)

    longwave_up = zeros(Nz + 1, Nsites)
    longwave_down = zeros(Nz + 1, Nsites)
    shortwave_up = zeros(Nz + 1, Nsites)
    shortwave_down = zeros(Nz + 1, Nsites)
    heating = (longwave = zeros(Nz, Nsites), longwave_reference = zeros(Nz, Nsites),
               shortwave = zeros(Nz, Nsites), shortwave_reference = zeros(Nz, Nsites),
               longwave_quadrature = zeros(Nz, Nsites))
    # Informational: the same longwave optics with exact angular integration
    # (3-node Gauss–Legendre, as LBLRTM's RADSUM) instead of D = 1.66.
    quadrature = gauss_legendre_flux_nodes(3)
    longwave_up_quadrature = zeros(Nz + 1, Nsites)
    longwave_down_quadrature = zeros(Nz + 1, Nsites)

    site_mole_fractions(i) = (h2o = benchmark.h2o[:, i], o3 = benchmark.o3[:, i],
                              co2 = benchmark.co2, ch4 = benchmark.ch4, n2o = benchmark.n2o,
                              cfc11 = benchmark.cfc11, cfc12 = benchmark.cfc12)

    site_column(i) = benchmark_column(benchmark.pressure_interfaces[:, i], benchmark.temperature_interfaces[:, i],
                                      site_mole_fractions(i);
                                      pressure_layers = benchmark.pressure_layers[:, i],
                                      temperature_layers = benchmark.temperature_layers[:, i],
                                      surface = (; temperature = benchmark.surface_temperature[i],
                                                   emissivity = benchmark.surface_emissivity[i]),
                                      geometry = (; cos_zenith = μ₀[i]),
                                      column_amount_convention)

    # One untimed column first, so that the timing below excludes compilation.
    column_fluxes!(workspace, model, site_column(1); surface_temperature = benchmark.surface_temperature[1],
                   emissivity = benchmark.surface_emissivity[1], albedo = benchmark.surface_albedo[1],
                   cos_zeniths = (μ₀[1],), solar_constant = benchmark.total_solar_irradiance[1])

    elapsed = 0.0   # optics and solves only
    for i in 1:Nsites
        surface_temperature = benchmark.surface_temperature[i]
        emissivity = benchmark.surface_emissivity[i]
        atmosphere = site_column(i)
        elapsed += @elapsed fluxes = column_fluxes!(workspace, model, atmosphere; surface_temperature, emissivity,
                                                    albedo = benchmark.surface_albedo[i], cos_zeniths = (μ₀[i],),
                                                    solar_constant = benchmark.total_solar_irradiance[i])
        longwave_up[:, i] = fluxes.longwave_up
        longwave_down[:, i] = fluxes.longwave_down
        shortwave_up[:, i] = fluxes.shortwave_up[:, 1]
        shortwave_down[:, i] = fluxes.shortwave_down[:, 1]
        heating.longwave[:, i] = heating_rate_per_day(fluxes.longwave_up, fluxes.longwave_down, atmosphere)
        heating.longwave_reference[:, i] = heating_rate_per_day(reference.rlu[:, i], reference.rld[:, i], atmosphere)
        heating.shortwave[:, i] = heating_rate_per_day(shortwave_up[:, i], shortwave_down[:, i], atmosphere)
        heating.shortwave_reference[:, i] = heating_rate_per_day(reference.rsu[:, i], reference.rsd[:, i], atmosphere)
        longwave_quadrature_fluxes!(view(longwave_up_quadrature, :, i), view(longwave_down_quadrature, :, i), workspace.longwave,
                                    model.longwave_weights, length(model.longwave_weights), Nz,
                                    TabulatedSurfaceEmission(model, surface_temperature; emissivity), 1 - emissivity, quadrature)
        heating.longwave_quadrature[:, i] = heating_rate_per_day(longwave_up_quadrature[:, i], longwave_down_quadrature[:, i], atmosphere)
    end

    p_hl = benchmark.pressure_interfaces
    day = daytime
    night = findall(<=(0), μ₀)
    heating_ranges(p, hr, ref) = map(range -> weighted_heating_rate_rmse(p, hr, ref, range), HEATING_RATE_RANGES)
    statistics = (;
        longwave_toa_up = (bias = bias(longwave_up[1, :], reference.rlu[1, :]), rmse = rmse(longwave_up[1, :], reference.rlu[1, :])),
        longwave_surface_down = (bias = bias(longwave_down[end, :], reference.rld[end, :]), rmse = rmse(longwave_down[end, :], reference.rld[end, :])),
        longwave_surface_up = (bias = bias(longwave_up[end, :], reference.rlu[end, :]), rmse = rmse(longwave_up[end, :], reference.rlu[end, :])),
        longwave_profile_rmse = (up = rmse(longwave_up, reference.rlu), down = rmse(longwave_down, reference.rld)),
        longwave_heating_rate = heating_ranges(p_hl, heating.longwave, heating.longwave_reference),
        shortwave_toa_up = (bias = bias(shortwave_up[1, day], reference.rsu[1, day]), rmse = rmse(shortwave_up[1, day], reference.rsu[1, day])),
        shortwave_surface_down = (bias = bias(shortwave_down[end, day], reference.rsd[end, day]), rmse = rmse(shortwave_down[end, day], reference.rsd[end, day])),
        shortwave_toa_down_max_relative_error = maximum(abs, shortwave_down[1, day] ./ reference.rsd[1, day] .- 1),
        shortwave_profile_rmse = (up = rmse(shortwave_up[:, day], reference.rsu[:, day]), down = rmse(shortwave_down[:, day], reference.rsd[:, day])),
        shortwave_heating_rate = heating_ranges(p_hl[:, day], heating.shortwave[:, day], heating.shortwave_reference[:, day]),
        night_sites_max_flux = maximum(abs, [shortwave_up[:, night]; shortwave_down[:, night]]),
        longwave_heating_rate_troposphere_above_lowest_two_layers =
            weighted_heating_rate_rmse(p_hl, heating.longwave, heating.longwave_reference, HEATING_RATE_RANGES.troposphere;
                                       exclude_lowest = 2),
        longwave_quadrature = (toa_up = (bias = bias(longwave_up_quadrature[1, :], reference.rlu[1, :]),
                                         rmse = rmse(longwave_up_quadrature[1, :], reference.rlu[1, :])),
                               surface_down = (bias = bias(longwave_down_quadrature[end, :], reference.rld[end, :]),
                                               rmse = rmse(longwave_down_quadrature[end, :], reference.rld[end, :])),
                               heating_rate = heating_ranges(p_hl, heating.longwave_quadrature, heating.longwave_reference)),
    )

    gates_for = getproperty(RFMIP_GATES, Symbol(model_name))
    gates = [
        flux_gate("LW TOA up"; statistics.longwave_toa_up...,
                  rmse_threshold = gates_for.longwave_toa_up.rmse, bias_threshold = gates_for.longwave_toa_up.bias),
        flux_gate("LW surface down"; statistics.longwave_surface_down...,
                  rmse_threshold = gates_for.longwave_surface_down.rmse, bias_threshold = gates_for.longwave_surface_down.bias),
        heating_rate_gate("LW heating rate, p > 100 hPa";
                          rmse = statistics.longwave_heating_rate.troposphere,
                          rmse_threshold = gates_for.longwave_heating_rate_troposphere),
        flux_gate("SW TOA up, μ₀ > 0"; rmse = statistics.shortwave_toa_up.rmse, rmse_threshold = gates_for.shortwave_toa_up),
        flux_gate("SW surface down, μ₀ > 0"; rmse = statistics.shortwave_surface_down.rmse, rmse_threshold = gates_for.shortwave_surface_down),
        heating_rate_gate("SW heating rate, p > 100 hPa, μ₀ > 0";
                          rmse = statistics.shortwave_heating_rate.troposphere,
                          rmse_threshold = gates_for.shortwave_heating_rate_troposphere),
    ]

    return (; model_name = String(model_name),
              Nlongwave_gpoints = length(model.longwave_weights),
              Nshortwave_gpoints = length(model.shortwave_weights),
              Nsites, Nz, Ndaytime = length(day), excluded_sites = benchmark.excluded_sites,
              column_amount_convention,
              elapsed_seconds = elapsed,
              microseconds_per_column = 1e6 * elapsed / Nsites,
              statistics, gates)
end

function rfmip_markdown(results, benchmark)
    lines = String[]
    push!(lines, "# RFMIP-IRF clear-sky benchmark of the reference ecCKD models against LBLRTM")
    push!(lines, "")
    push!(lines, "Generated $(Dates.format(now(), "yyyy-mm-dd HH:MM")) by `validation/rfmip_irf.jl`.")
    push!(lines, "")
    push!(lines, "$(benchmark.Nsites) sites of experiment $(RFMIP_EXPERIMENT) (\"$(benchmark.experiment_label)\"), " *
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
                 "\"moist convention\" use `nᵈ = Δp / (g (mᵈ + mᵛ χH₂O))`.")
    for r in results
        s = r.statistics
        m = r.moist_convention_statistics
        push!(lines, "")
        push!(lines, "## $(r.model_name) ($(r.Nlongwave_gpoints) LW × $(r.Nshortwave_gpoints) SW g-points)")
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
        push!(lines, markdown_row(("LW surface up bias / RMSE", @sprintf("%+.3f / %.3f W m⁻²", s.longwave_surface_up.bias, s.longwave_surface_up.rmse))))
        push!(lines, markdown_row(("LW profile RMSE up / down", @sprintf("%.3f / %.3f W m⁻²", s.longwave_profile_rmse.up, s.longwave_profile_rmse.down))))
        push!(lines, markdown_row(("LW heating rate RMSE p > 100 hPa without the two lowest layers",
                                   @sprintf("%.4f K day⁻¹", s.longwave_heating_rate_troposphere_above_lowest_two_layers))))
        push!(lines, markdown_row(("LW heating rate RMSE 4 Pa < p ≤ 100 hPa", @sprintf("%.4f K day⁻¹", s.longwave_heating_rate.stratosphere))))
        push!(lines, markdown_row(("LW heating rate RMSE 0.02–4 hPa / 4–1100 hPa",
                                   @sprintf("%.4f / %.4f K day⁻¹", s.longwave_heating_rate.ckdmip_upper, s.longwave_heating_rate.ckdmip_lower))))
        push!(lines, markdown_row(("SW TOA up bias / SW surface down bias (μ₀ > 0)", @sprintf("%+.3f / %+.3f W m⁻²", s.shortwave_toa_up.bias, s.shortwave_surface_down.bias))))
        push!(lines, markdown_row(("SW profile RMSE up / down (μ₀ > 0)", @sprintf("%.3f / %.3f W m⁻²", s.shortwave_profile_rmse.up, s.shortwave_profile_rmse.down))))
        push!(lines, markdown_row(("SW heating rate RMSE 4 Pa < p ≤ 100 hPa (μ₀ > 0)", @sprintf("%.4f K day⁻¹", s.shortwave_heating_rate.stratosphere))))
        push!(lines, markdown_row(("SW TOA down max relative error (S₀ μ₀ check)", @sprintf("%.1e", s.shortwave_toa_down_max_relative_error))))
        push!(lines, markdown_row(("Night sites max |SW flux|", @sprintf("%.2e W m⁻²", s.night_sites_max_flux))))
        q = s.longwave_quadrature
        push!(lines, markdown_row(("Exact angular integration: LW TOA up bias / RMSE", @sprintf("%+.3f / %.3f W m⁻²", q.toa_up.bias, q.toa_up.rmse))))
        push!(lines, markdown_row(("Exact angular integration: LW surface down bias / RMSE", @sprintf("%+.3f / %.3f W m⁻²", q.surface_down.bias, q.surface_down.rmse))))
        push!(lines, markdown_row(("Exact angular integration: LW heating rate RMSE p > 100 hPa / 4 Pa < p ≤ 100 hPa",
                                   @sprintf("%.4f / %.4f K day⁻¹", q.heating_rate.troposphere, q.heating_rate.stratosphere))))
        push!(lines, markdown_row(("Moist convention: LW TOA up bias / RMSE", @sprintf("%+.3f / %.3f W m⁻²", m.longwave_toa_up.bias, m.longwave_toa_up.rmse))))
        push!(lines, markdown_row(("Moist convention: LW surface down bias / RMSE", @sprintf("%+.3f / %.3f W m⁻²", m.longwave_surface_down.bias, m.longwave_surface_down.rmse))))
        push!(lines, markdown_row(("Moist convention: LW heating rate RMSE p > 100 hPa", @sprintf("%.4f K day⁻¹", m.longwave_heating_rate.troposphere))))
        push!(lines, markdown_row(("Moist convention: SW TOA up RMSE / surface down RMSE (μ₀ > 0)",
                                   @sprintf("%.3f / %.3f W m⁻²", m.shortwave_toa_up.rmse, m.shortwave_surface_down.rmse))))
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
        println("RFMIP-IRF: $(benchmark.Nsites) sites, experiment $(RFMIP_EXPERIMENT) ($(benchmark.experiment_label)), " *
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
                @test result.statistics.shortwave_toa_down_max_relative_error < 1e-5
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
                        Nlongwave_gpoints = result.Nlongwave_gpoints,
                        Nshortwave_gpoints = result.Nshortwave_gpoints,
                        Nsites = result.Nsites, Ndaytime = result.Ndaytime, excluded_sites = result.excluded_sites,
                        Nz = result.Nz,
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
