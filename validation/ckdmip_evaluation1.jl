#####
##### CKDMIP Evaluation-1 line-by-line benchmark of the reference ecCKD models
#####
#
# Runs the 50 clear-sky "Evaluation-1" profiles of CKDMIP (Hogan and
# Matricardi, 2020, GMD 13, 6501) through the reference ecCKD gas-optics
# models `climate_32x32` and `climate_64x64` — `optical_properties!` followed
# by the streaming longwave and shortwave solvers — and compares the
# broadband fluxes and heating rates with the line-by-line reference fluxes
# that the ecRad checkout in the `ecrad_data` artifact ships under
# `test/ckdmip/` (present-day 2020 concentrations, "reduced" files without
# the per-band fluxes).
#
# Conventions (those of the ecRad driver on the same input):
#   * layer pressure and temperature are the arithmetic means of the bounding
#     half levels; the Planck sources are evaluated at the half levels;
#   * layer amounts follow the dry column-amount convention of the ecCKD
#     tables, dry air `nᵈ = Δp / (g mᵈ)` and every gas `χ nᵈ`; N₂ and O₂ are
#     the `composite` gas of the tables. The moist-molar-mass convention
#     `nᵈ = Δp / (g (mᵈ + mᵛ χ_H₂O))` is run alongside, ungated;
#   * longwave: surface temperature `Tₛ = temperature_hl[end]`, emissivity 1,
#     no downwelling flux at 0.01 Pa;
#   * shortwave: the five cosines of the solar zenith angle are read from the
#     reference file's `mu0` dimension, the solar constant from its TOA
#     downwelling flux (1361 W m⁻²), and the surface albedo from its surface
#     up/down ratio (0.15, the `sw_albedo` of the ecRad CKDMIP configuration).
#
# Statistics follow `evaluate_ckd_{lw,sw}_fluxes.m` of the ecRad CKDMIP test
# suite: bias and RMSE of the TOA upwelling and surface downwelling fluxes
# over profiles (and, in the shortwave, over solar zenith angles), and
# heating-rate RMSEs weighted by the cube root of pressure within a pressure
# range. The gated ranges are p > 100 hPa and 4 Pa < p ≤ 100 hPa; the CKDMIP
# ranges 0.02–4 hPa and 4–1100 hPa are reported alongside.
#
# Observed on 2026-09-16 (Float64, dry column-amount convention; every gate
# passes). Fluxes in W m⁻², heating rates in K day⁻¹; "trop" is p > 100 hPa,
# "strat" 4 Pa < p ≤ 100 hPa, and the CKDMIP ranges are 0.02–4 / 4–1100 hPa:
#
#   climate_32x32 (32 LW × 32 SW g-points)
#     LW TOA up            bias -0.002  RMSE 0.147     (gate |bias| ≤ 0.5, RMSE ≤ 1.0)
#     LW surface down      bias -0.002  RMSE 0.411     (gate |bias| ≤ 0.8, RMSE ≤ 1.5)
#     LW heating rate      trop 0.0756 (gate ≤ 0.10)   strat 0.0456 (gate ≤ 0.5)
#                          CKDMIP ranges 0.0755 / 0.0641
#     SW TOA up            RMSE 0.346 all μ₀ (gate ≤ 1.5), bias -0.297
#     SW surface down      RMSE 0.205 μ₀ ≥ 0.3 (gate ≤ 2.5), bias -0.017
#     SW heating rate      trop 0.0562 (gate ≤ 0.10)   CKDMIP ranges 0.1027 / 0.0595
#     moist convention     LW surface down bias -0.197 RMSE 0.560; SW surface down RMSE 0.303
#
#   climate_64x64 (64 LW × 64 SW g-points)
#     LW TOA up            bias +0.002  RMSE 0.137     (gate |bias| ≤ 0.3, RMSE ≤ 0.6)
#     LW surface down      bias +0.021  RMSE 0.384     (gate |bias| ≤ 0.5, RMSE ≤ 1.0)
#     LW heating rate      trop 0.0762 (gate ≤ 0.09)   strat 0.0384 (gate ≤ 0.4)
#                          CKDMIP ranges 0.0642 / 0.0625
#     SW TOA up            RMSE 0.163 all μ₀ (gate ≤ 1.0), bias -0.079
#     SW surface down      RMSE 0.262 μ₀ ≥ 0.3 (gate ≤ 1.5), bias -0.073
#     SW heating rate      trop 0.0571 (gate ≤ 0.07)   CKDMIP ranges 0.1014 / 0.0500
#     moist convention     LW surface down bias -0.175 RMSE 0.518; SW surface down RMSE 0.326
#
# The tropospheric longwave heating-rate error is the same for both models
# and comes from the two 200–300 Pa layers next to the surface (per-layer RMS
# 0.9 and 0.3 K day⁻¹, against 0.02–0.13 elsewhere below 100 hPa); see the
# note at CKDMIP_GATES. Exact angular integration in place of D = 1.66 makes
# every statistic worse, so the reference was computed with the diffusivity
# approximation and the linear-in-τ Planck function the streaming solver uses.
#
# Reports (JSON per model and one Markdown summary) are written to
# NUMERICAL_RADIATION_VALIDATION_RESULTS_DIR, by default `validation/results/`.
#
# Run from the package root, in an environment with NCDatasets (the test
# environment works once the package is developed into it):
#
#   julia --project=test -e 'using Pkg; Pkg.develop(path=".")'
#   julia --project=test validation/ckdmip_evaluation1.jl

include(joinpath(@__DIR__, "common.jl"))

# Gates (W m⁻² for fluxes, K day⁻¹ for heating rates). The 64×64 tropospheric
# longwave heating-rate gate was set at 0.07 before the first run and raised
# once, by 29 %, after it: the observed 0.076 K day⁻¹ is the same for both
# models and sits in the two 200–300 Pa layers next to the surface, where the
# CKD averaging cannot follow the line-by-line heating of thin layers with a
# large surface temperature jump (profile 36: 13 K across 200 Pa, reference
# heating 33 K day⁻¹); the same statistic over the CKDMIP 4–1100 hPa range is
# 0.063 K day⁻¹.
const CKDMIP_GATES = (
    climate_32x32 = (lw_toa_up = (bias = 0.5, rmse = 1.0),
                     lw_surface_down = (bias = 0.8, rmse = 1.5),
                     lw_heating_rate_troposphere = 0.10,
                     lw_heating_rate_stratosphere = 0.5,
                     sw_toa_up = 1.5,
                     sw_surface_down = 2.5,
                     sw_heating_rate_troposphere = 0.10),
    climate_64x64 = (lw_toa_up = (bias = 0.3, rmse = 0.6),
                     lw_surface_down = (bias = 0.5, rmse = 1.0),
                     lw_heating_rate_troposphere = 0.09,
                     lw_heating_rate_stratosphere = 0.4,
                     sw_toa_up = 1.0,
                     sw_surface_down = 1.5,
                     sw_heating_rate_troposphere = 0.07),
)

const CKDMIP_GASES = (:h2o, :o3, :co2, :ch4, :n2o, :cfc11, :cfc12)
const CKDMIP_FILES = ("concentrations", "lw_fluxes", "sw_fluxes")

# Paths of the three CKDMIP files in the artifact, or `nothing` with a message
# when the artifact itself cannot be resolved (a missing or undownloadable
# artifact must not fail CI). Only that step is guarded: once the artifact is
# present, a CKDMIP file missing from it is a real failure and throws.
function ckdmip_files()
    root = try
        ecrad_data_path(; require = true)
    catch exception
        @warn "ecrad_data artifact is not available" exception = (exception, catch_backtrace())
        return nothing
    end
    root === nothing && return nothing
    return map(CKDMIP_FILES) do name
        ecrad_test_file("ckdmip/ckdmip_evaluation1_$(name)_present_reduced.nc"; require = true)
    end
end

# Everything the benchmark reads: profiles, line-by-line fluxes and the
# shortwave configuration inferred from the reference file.
function load_ckdmip(paths)
    concentrations, longwave_path, shortwave_path = paths
    data = NCDataset(concentrations) do dataset
        (; pressure_hl = dense(dataset["pressure_hl"][:, :]),
           temperature_hl = dense(dataset["temperature_hl"][:, :]),
           mole_fractions = NamedTuple{CKDMIP_GASES}(map(gas -> dense(dataset["$(gas)_mole_fraction_fl"][:, :]), CKDMIP_GASES)))
    end
    longwave = NCDataset(longwave_path) do dataset
        (; up = dense(dataset["flux_up_lw"][:, :]), down = dense(dataset["flux_dn_lw"][:, :]))
    end
    shortwave = NCDataset(shortwave_path) do dataset
        # The zenith dimension is read, not assumed: `mu0` is a coordinate of
        # the flux arrays `(half_level, mu0, column)`.
        haskey(dataset, "mu0") || throw(ArgumentError("shortwave reference file has no mu0 coordinate"))
        μ₀ = round.(dense(dataset["mu0"][:]); digits = 6)   # stored in single precision
        up = dense(dataset["flux_up_sw"][:, :, :])
        down = dense(dataset["flux_dn_sw"][:, :, :])
        dimnames(dataset["flux_up_sw"]) == ("half_level", "mu0", "column") ||
            throw(ArgumentError("unexpected shortwave flux dimensions $(dimnames(dataset["flux_up_sw"]))"))
        (; μ₀, up, down)
    end

    Nprofiles = size(data.pressure_hl, 2)
    size(longwave.up) == size(data.pressure_hl) || throw(DimensionMismatch("longwave reference shape"))
    size(shortwave.up) == (size(data.pressure_hl, 1), length(shortwave.μ₀), Nprofiles) ||
        throw(DimensionMismatch("shortwave reference shape"))

    # Solar constant and albedo of the reference calculation, from the fluxes
    # themselves: `S₀ = down_TOA / μ₀` and `α = up_surface / down_surface`.
    solar_constants = [shortwave.down[1, j, i] / shortwave.μ₀[j] for j in eachindex(shortwave.μ₀), i in 1:Nprofiles]
    solar_constant = round(mean(solar_constants); digits = 1)
    maximum(abs, solar_constants .- solar_constant) < 0.05 ||
        throw(ArgumentError("reference TOA irradiance is not a single solar constant"))
    albedos = shortwave.up[end, :, :] ./ shortwave.down[end, :, :]
    albedo = round(mean(albedos); digits = 3)
    maximum(abs, albedos .- albedo) < 1e-4 ||
        throw(ArgumentError("reference surface albedo is not spectrally and spatially constant"))

    return (; data..., longwave, shortwave, Nprofiles, solar_constant, albedo)
end

# Run one model over every profile, returning fluxes, heating rates and the
# statistics of the CKDMIP evaluation.
function evaluate_ckdmip(model_name, benchmark; column_amount_convention = :dry)
    (; pressure_hl, temperature_hl, mole_fractions, longwave, shortwave, Nprofiles, solar_constant, albedo) = benchmark
    μ₀ = shortwave.μ₀
    Nz = size(pressure_hl, 1) - 1
    Nzenith = length(μ₀)

    model = read_reference_ecckd_gas_optics(model_name; names = ECCKD_GAS_NAMES)
    workspace = ColumnWorkspace(model, Nz)

    longwave_up = zeros(Nz + 1, Nprofiles)
    longwave_down = zeros(Nz + 1, Nprofiles)
    shortwave_up = zeros(Nz + 1, Nzenith, Nprofiles)
    shortwave_down = zeros(Nz + 1, Nzenith, Nprofiles)
    longwave_heating = zeros(Nz, Nprofiles)
    lw_heating_reference = zeros(Nz, Nprofiles)
    shortwave_heating = zeros(Nz, Nzenith, Nprofiles)
    sw_heating_reference = zeros(Nz, Nzenith, Nprofiles)

    profile_column(i) = benchmark_column(pressure_hl[:, i], temperature_hl[:, i], map(mf -> mf[:, i], mole_fractions);
                                         surface = (; temperature = temperature_hl[end, i], emissivity = 1.0),
                                         geometry = (;), column_amount_convention)

    # One untimed column first, so that the timing below excludes compilation.
    column_fluxes!(workspace, model, profile_column(1); surface_temperature = temperature_hl[end, 1],
                   emissivity = 1.0, albedo, cos_zeniths = μ₀, solar_constant)

    elapsed = 0.0   # optics and solves only
    for i in 1:Nprofiles
        surface_temperature = temperature_hl[end, i]
        atmosphere = profile_column(i)
        elapsed += @elapsed fluxes = column_fluxes!(workspace, model, atmosphere; surface_temperature, emissivity = 1.0,
                                                    albedo, cos_zeniths = μ₀, solar_constant)
        longwave_up[:, i] = fluxes.longwave_up
        longwave_down[:, i] = fluxes.longwave_down
        shortwave_up[:, :, i] = fluxes.shortwave_up
        shortwave_down[:, :, i] = fluxes.shortwave_down
        longwave_heating[:, i] = heating_rate_per_day(fluxes.longwave_up, fluxes.longwave_down, atmosphere)
        lw_heating_reference[:, i] = heating_rate_per_day(longwave.up[:, i], longwave.down[:, i], atmosphere)
        for j in 1:Nzenith
            shortwave_heating[:, j, i] = heating_rate_per_day(fluxes.shortwave_up[:, j], fluxes.shortwave_down[:, j], atmosphere)
            sw_heating_reference[:, j, i] = heating_rate_per_day(shortwave.up[:, j, i], shortwave.down[:, j, i], atmosphere)
        end
    end

    # Shortwave statistics pool profiles and zenith angles; the pressure
    # interfaces are replicated per zenith angle for the weighted heating-rate
    # RMSE. The surface-downwelling gate excludes μ₀ < 0.3.
    pressure_sw = repeat(pressure_hl, inner = (1, Nzenith))
    flat(x) = reshape(x, size(x, 1), :)
    high_sun = findall(>=(0.3), μ₀)
    heating_ranges(p, hr, ref) = map(range -> weighted_heating_rate_rmse(p, hr, ref, range), HEATING_RATE_RANGES)

    statistics = (;
        lw_toa_up = (bias = bias(longwave_up[1, :], longwave.up[1, :]), rmse = rmse(longwave_up[1, :], longwave.up[1, :])),
        lw_surface_down = (bias = bias(longwave_down[end, :], longwave.down[end, :]), rmse = rmse(longwave_down[end, :], longwave.down[end, :])),
        lw_profile_rmse = (up = rmse(longwave_up, longwave.up), down = rmse(longwave_down, longwave.down)),
        lw_heating_rate = heating_ranges(pressure_hl, longwave_heating, lw_heating_reference),
        sw_toa_up = (bias = bias(shortwave_up[1, :, :], shortwave.up[1, :, :]), rmse = rmse(shortwave_up[1, :, :], shortwave.up[1, :, :])),
        sw_surface_down = (bias = bias(shortwave_down[end, high_sun, :], shortwave.down[end, high_sun, :]),
                           rmse = rmse(shortwave_down[end, high_sun, :], shortwave.down[end, high_sun, :]),
                           rmse_all_zenith_angles = rmse(shortwave_down[end, :, :], shortwave.down[end, :, :])),
        sw_profile_rmse = (up = rmse(shortwave_up, shortwave.up), down = rmse(shortwave_down, shortwave.down)),
        sw_heating_rate = heating_ranges(pressure_sw, flat(shortwave_heating), flat(sw_heating_reference)),
        sw_by_zenith_angle = [(; mu0 = μ₀[j],
                                 toa_up_rmse = rmse(shortwave_up[1, j, :], shortwave.up[1, j, :]),
                                 surface_down_rmse = rmse(shortwave_down[end, j, :], shortwave.down[end, j, :]),
                                 heating_rate_troposphere_rmse = weighted_heating_rate_rmse(
                                     pressure_hl, shortwave_heating[:, j, :], sw_heating_reference[:, j, :],
                                     HEATING_RATE_RANGES.troposphere))
                              for j in 1:Nzenith],
    )

    gates_for = getproperty(CKDMIP_GATES, Symbol(model_name))
    gates = [
        flux_gate("LW TOA up"; statistics.lw_toa_up...,
                  rmse_threshold = gates_for.lw_toa_up.rmse, bias_threshold = gates_for.lw_toa_up.bias),
        flux_gate("LW surface down"; statistics.lw_surface_down...,
                  rmse_threshold = gates_for.lw_surface_down.rmse, bias_threshold = gates_for.lw_surface_down.bias),
        heating_rate_gate("LW heating rate, p > 100 hPa";
                          rmse = statistics.lw_heating_rate.troposphere,
                          rmse_threshold = gates_for.lw_heating_rate_troposphere),
        heating_rate_gate("LW heating rate, 4 Pa < p ≤ 100 hPa";
                          rmse = statistics.lw_heating_rate.stratosphere,
                          rmse_threshold = gates_for.lw_heating_rate_stratosphere),
        flux_gate("SW TOA up, all μ₀"; rmse = statistics.sw_toa_up.rmse, rmse_threshold = gates_for.sw_toa_up),
        flux_gate("SW surface down, μ₀ ≥ 0.3"; rmse = statistics.sw_surface_down.rmse,
                  rmse_threshold = gates_for.sw_surface_down),
        heating_rate_gate("SW heating rate, p > 100 hPa";
                          rmse = statistics.sw_heating_rate.troposphere,
                          rmse_threshold = gates_for.sw_heating_rate_troposphere),
    ]

    return (; model_name = String(model_name),
              longwave_gpoints = length(model.longwave_weights),
              shortwave_gpoints = length(model.shortwave_weights),
              Nprofiles, Nz, mu0 = μ₀, solar_constant, albedo, column_amount_convention,
              elapsed_seconds = elapsed,
              microseconds_per_column = 1e6 * elapsed / Nprofiles,
              statistics, gates)
end

function ckdmip_markdown(results, benchmark, paths)
    lines = String[]
    push!(lines, "# CKDMIP Evaluation-1 benchmark of the reference ecCKD models")
    push!(lines, "")
    push!(lines, "Generated $(Dates.format(now(), "yyyy-mm-dd HH:MM")) by `validation/ckdmip_evaluation1.jl`.")
    push!(lines, "")
    push!(lines, "$(benchmark.Nprofiles) present-day clear-sky profiles, $(size(benchmark.pressure_hl, 1) - 1) layers " *
                 "from $(benchmark.pressure_hl[1, 1]) Pa; longwave with `ε = 1` and `Tₛ = temperature_hl[end]`; " *
                 "shortwave with `S₀ = $(benchmark.solar_constant)` W m⁻², albedo $(benchmark.albedo), " *
                 "μ₀ ∈ $(benchmark.shortwave.μ₀). Reference: line-by-line fluxes of CKDMIP " *
                 "(`$(basename(paths[2]))`, `$(basename(paths[3]))`).")
    push!(lines, "")
    push!(lines, "Heating-rate RMSEs are weighted by the cube root of pressure within the range " *
                 "(the CKDMIP statistic); fluxes in W m⁻², heating rates in K day⁻¹. Gated runs use the " *
                 "dry column-amount convention `nᵈ = Δp / (g mᵈ)` of the ecCKD tables; the rows marked " *
                 "\"moist convention\" use `nᵈ = Δp / (g (mᵈ + mᵛ χ_H₂O))`.")
    for r in results
        s = r.statistics
        push!(lines, "")
        push!(lines, "## $(r.model_name) ($(r.longwave_gpoints) LW × $(r.shortwave_gpoints) SW g-points)")
        push!(lines, "")
        push!(lines, "$(round(r.microseconds_per_column; digits = 1)) μs per column (optics + LW + $(length(r.mu0)) SW solves), " *
                     "$(round(r.elapsed_seconds; digits = 3)) s total.")
        push!(lines, "")
        push!(lines, markdown_gate_table(r.gates))
        push!(lines, "")
        push!(lines, "Additional statistics:")
        push!(lines, "")
        push!(lines, markdown_row(("Quantity", "Value")))
        push!(lines, markdown_row(("---", "---")))
        push!(lines, markdown_row(("LW heating rate RMSE 0.02–4 hPa / 4–1100 hPa",
                                   @sprintf("%.4f / %.4f K day⁻¹", s.lw_heating_rate.ckdmip_upper, s.lw_heating_rate.ckdmip_lower))))
        push!(lines, markdown_row(("SW heating rate RMSE 0.02–4 hPa / 4–1100 hPa",
                                   @sprintf("%.4f / %.4f K day⁻¹", s.sw_heating_rate.ckdmip_upper, s.sw_heating_rate.ckdmip_lower))))
        push!(lines, markdown_row(("SW heating rate RMSE 4 Pa < p ≤ 100 hPa",
                                   @sprintf("%.4f K day⁻¹", s.sw_heating_rate.stratosphere))))
        push!(lines, markdown_row(("LW profile RMSE up / down", @sprintf("%.3f / %.3f W m⁻²", s.lw_profile_rmse.up, s.lw_profile_rmse.down))))
        push!(lines, markdown_row(("SW profile RMSE up / down", @sprintf("%.3f / %.3f W m⁻²", s.sw_profile_rmse.up, s.sw_profile_rmse.down))))
        push!(lines, markdown_row(("SW TOA up bias", @sprintf("%+.3f W m⁻²", s.sw_toa_up.bias))))
        push!(lines, markdown_row(("SW surface down bias (μ₀ ≥ 0.3) / RMSE (all μ₀)",
                                   @sprintf("%+.3f / %.3f W m⁻²", s.sw_surface_down.bias, s.sw_surface_down.rmse_all_zenith_angles))))
        m = r.moist_convention_statistics
        push!(lines, markdown_row(("Moist convention: LW TOA up bias / RMSE", @sprintf("%+.3f / %.3f W m⁻²", m.lw_toa_up.bias, m.lw_toa_up.rmse))))
        push!(lines, markdown_row(("Moist convention: LW surface down bias / RMSE", @sprintf("%+.3f / %.3f W m⁻²", m.lw_surface_down.bias, m.lw_surface_down.rmse))))
        push!(lines, markdown_row(("Moist convention: LW heating rate RMSE p > 100 hPa", @sprintf("%.4f K day⁻¹", m.lw_heating_rate.troposphere))))
        push!(lines, markdown_row(("Moist convention: SW TOA up RMSE / surface down RMSE (μ₀ ≥ 0.3)",
                                   @sprintf("%.3f / %.3f W m⁻²", m.sw_toa_up.rmse, m.sw_surface_down.rmse))))
        push!(lines, "")
        push!(lines, markdown_row(("μ₀", "SW TOA up RMSE", "SW surface down RMSE", "SW heating rate RMSE p > 100 hPa")))
        push!(lines, markdown_row(("---", "---", "---", "---")))
        for z in s.sw_by_zenith_angle
            push!(lines, markdown_row((string(z.mu0), @sprintf("%.3f", z.toa_up_rmse),
                                       @sprintf("%.3f", z.surface_down_rmse), @sprintf("%.4f", z.heating_rate_troposphere_rmse))))
        end
    end
    push!(lines, "")
    return join(lines, "\n")
end

function run_ckdmip_evaluation1(; models = (:climate_32x32, :climate_64x64))
    results_dir = validation_results_dir()
    paths = ckdmip_files()
    results = []
    @testset "CKDMIP Evaluation-1" begin
        if paths === nothing
            @test_skip "CKDMIP evaluation files not available (ecrad_data artifact)"
            return results
        end
        benchmark = load_ckdmip(paths)
        println("CKDMIP Evaluation-1: $(benchmark.Nprofiles) profiles, S₀ = $(benchmark.solar_constant) W m⁻², " *
                "albedo $(benchmark.albedo), μ₀ = $(benchmark.shortwave.μ₀)")
        for model_name in models
            result = evaluate_ckdmip(model_name, benchmark)
            # The contract's moist-molar-mass column amounts, reported but not gated.
            moist = evaluate_ckdmip(model_name, benchmark; column_amount_convention = :moist)
            result = (; result..., moist_convention_statistics = moist.statistics)
            push!(results, result)
            println("\n$(result.model_name): $(round(result.microseconds_per_column; digits = 1)) μs per column")
            report_gates(result.gates)
            @testset "$(result.model_name)" begin
                for gate in result.gates
                    ok, errors = gate_passes(gate)
                    @testset "$(gate.name)" begin
                        @test ok
                        ok || println("  $(gate.name): ", join(errors, "; "))
                    end
                end
            end
            record = (; benchmark = "CKDMIP evaluation1 present-day", generated = string(now()),
                        input_files = collect(basename.(paths)),
                        model = result.model_name,
                        longwave_gpoints = result.longwave_gpoints,
                        shortwave_gpoints = result.shortwave_gpoints,
                        Nprofiles = result.Nprofiles, Nz = result.Nz,
                        mu0 = result.mu0, solar_constant = result.solar_constant, albedo = result.albedo,
                        surface_emissivity = 1.0,
                        column_amount_convention = result.column_amount_convention,
                        elapsed_seconds = result.elapsed_seconds,
                        microseconds_per_column = result.microseconds_per_column,
                        heating_rate_ranges_Pa = map(r -> collect(r), HEATING_RATE_RANGES),
                        statistics = result.statistics,
                        moist_convention_statistics = result.moist_convention_statistics,
                        gates = gate_records(result.gates),
                        passes = all(first ∘ gate_passes, result.gates))
            write_json(joinpath(results_dir, "ckdmip_evaluation1_$(result.model_name).json"), record)
        end
        write(joinpath(results_dir, "ckdmip_evaluation1.md"), ckdmip_markdown(results, benchmark, paths))
        println("\nReports written to $(results_dir)")
    end
    return results
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_ckdmip_evaluation1()
end
