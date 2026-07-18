# Consolidated from the original per-topic test files (Stage R2).
# Each original file's content is preserved verbatim inside its own module
# so top-level consts/functions from included validation scripts cannot clash.

module TestMetrics
using Test
using NumericalRadiation
using Dates

# --- begin content of test_metrics.jl ---
@testset "Radiation validation metrics" begin
    candidate_flux = [1.0, 3.0, 6.0]
    reference_flux = [1.0, 1.0, 2.0]
    candidate_heating = [0.10, 0.20, 0.40]
    reference_heating = [0.05, 0.25, 0.20]

    metrics = radiation_error_metrics(
        candidate_flux = candidate_flux,
        reference_flux = reference_flux,
        candidate_heating_rate = candidate_heating,
        reference_heating_rate = reference_heating,
        candidate_toa_flux = 240.5,
        reference_toa_flux = 240.0,
        candidate_surface_flux = 110.0,
        reference_surface_flux = 112.0,
    )

    @test metrics isa RadiationErrorMetrics
    @test metrics.flux_rmse ≈ sqrt((0.0^2 + 2.0^2 + 4.0^2) / 3)
    @test metrics.flux_max_abs == 4.0
    @test metrics.flux_bias == 2.0
    @test metrics.heating_rate_rmse ≈ sqrt((0.05^2 + (-0.05)^2 + 0.20^2) / 3)
    @test metrics.heating_rate_max_abs ≈ 0.20
    @test metrics.heating_rate_bias ≈ (0.05 - 0.05 + 0.20) / 3
    @test metrics.toa_forcing_error == 0.5
    @test metrics.surface_forcing_error == -2.0

    loose = RadiationThresholds(
        flux_rmse = 3.0,
        flux_max_abs = 4.0,
        flux_abs_bias = 2.0,
        heating_rate_rmse = 0.2,
        heating_rate_max_abs = 0.2,
        heating_rate_abs_bias = 0.1,
        toa_forcing_abs_error = 0.5,
        surface_forcing_abs_error = 2.0,
    )
    valid, errors = passes_thresholds(metrics, loose)
    @test valid
    @test isempty(errors)
    @test passes_thresholds(metrics, loose; throw_on_error = true)

    strict = RadiationThresholds(flux_rmse = 1.0, surface_forcing_abs_error = 1.0)
    valid_strict, strict_errors = passes_thresholds(metrics, strict)
    @test !valid_strict
    @test any(contains("flux_rmse"), strict_errors)
    @test any(contains("surface_forcing_abs_error"), strict_errors)
    @test_throws ArgumentError passes_thresholds(metrics, strict; throw_on_error = true)

    @test_throws DimensionMismatch radiation_error_metrics(
        candidate_flux = [1.0],
        reference_flux = [1.0, 2.0],
        candidate_heating_rate = candidate_heating,
        reference_heating_rate = reference_heating,
        candidate_toa_flux = 0.0,
        reference_toa_flux = 0.0,
        candidate_surface_flux = 0.0,
        reference_surface_flux = 0.0,
    )
end

@testset "RadiativeFluxes comparison metrics" begin
    atmosphere = ColumnAtmosphere(
        pressure_layers = [25_000.0, 75_000.0],
        pressure_interfaces = [0.0, 50_000.0, 100_000.0],
        temperature_layers = [250.0, 280.0],
        temperature_interfaces = [240.0, 265.0, 290.0],
        gases = (;),
        surface = (;),
        geometry = (;),
    )
    candidate = RadiativeFluxes(
        longwave_up = [10.0, 12.0, 14.0],
        longwave_down = [0.0, 2.0, 4.0],
        shortwave_up = [1.0, 2.0, 3.0],
        shortwave_down = [100.0, 80.0, 60.0],
    )
    reference = RadiativeFluxes(
        longwave_up = [9.0, 11.0, 13.0],
        longwave_down = [0.0, 1.0, 3.0],
        shortwave_up = [1.0, 1.0, 2.0],
        shortwave_down = [99.0, 79.0, 59.0],
    )

    metrics = radiative_flux_error_metrics(candidate, reference, atmosphere;
                                           gravity = 10.0,
                                           heat_capacity = 1000.0)
    @test metrics isa RadiationErrorMetrics
    @test metrics.flux_rmse ≈ sqrt(10 / 12)
    @test metrics.flux_max_abs == 1.0
    @test metrics.toa_forcing_error == 0.0
    @test metrics.surface_forcing_error == 0.0
    @test isfinite(metrics.heating_rate_rmse)
end
# --- end content of test_metrics.jl ---

end # module TestMetrics

module TestRrtmgpExt
using Test
using NumericalRadiation
using Dates

# --- begin content of test_rrtmgp_ext.jl ---
using NumericalRadiation
using ClimaComms
using NCDatasets
using RRTMGP

@testset "RRTMGP extension direct ColumnAtmosphere comparison" begin
    ext = Base.get_extension(NumericalRadiation, :NumericalRadiationRRTMGPExt)
    @test ext !== nothing

    pressure_interfaces = [1.0e3, 2.0e4, 5.0e4, 8.0e4, 1.0e5]
    pressure_layers = (pressure_interfaces[1:end-1] .+ pressure_interfaces[2:end]) ./ 2
    temperature_interfaces = [210.0, 235.0, 260.0, 285.0, 300.0]
    temperature_layers = (temperature_interfaces[1:end-1] .+ temperature_interfaces[2:end]) ./ 2
    atmosphere = ColumnAtmosphere(
        pressure_layers = pressure_layers,
        pressure_interfaces = pressure_interfaces,
        temperature_layers = temperature_layers,
        temperature_interfaces = temperature_interfaces,
        gases = (h2o = [1e-4, 8e-4, 3e-3, 1e-2],
                 o3 = fill(1e-8, 4),
                 co2 = 400e-6),
        surface = (;),
        geometry = (;),
    )
    rrtmgp = ext.RRTMGPClearSkyModel(Float64)
    boundary = ext.RRTMGPBoundaryConditions(surface_temperature = 300.0,
                                            surface_emissivity = 0.98,
                                            surface_albedo = 0.1,
                                            toa_shortwave_down = 500.0,
                                            cos_zenith = 1.0)
    rrtmgp_fluxes = RadiativeFluxes(
        longwave_up = zeros(5),
        longwave_down = zeros(5),
        shortwave_up = zeros(5),
        shortwave_down = zeros(5),
    )
    workspace = radiation_workspace(rrtmgp, atmosphere)
    radiative_fluxes!(rrtmgp_fluxes, rrtmgp, atmosphere, boundary, workspace)

    @test all(isfinite, rrtmgp_fluxes.longwave_up)
    @test all(isfinite, rrtmgp_fluxes.longwave_down)
    @test all(isfinite, rrtmgp_fluxes.shortwave_up)
    @test all(isfinite, rrtmgp_fluxes.shortwave_down)

    gas = EcCKDGasOpticsModel(
        gas_names = (:h2o, :co2),
        longwave_absorption = fill(0.01, 2, 2),
        shortwave_absorption = fill(0.005, 2, 2),
        longwave_weights = fill(0.5, 2),
        shortwave_weights = fill(0.5, 2),
        longwave_source_scale = fill(1.0, 2),
    )
    longwave = LongwaveOpticalProperties(zeros(2, 4), zeros(2, 4); weights = fill(0.5, 2))
    shortwave = ShortwaveOpticalProperties(zeros(2, 4); weights = fill(0.5, 2))
    optical_properties!(longwave, shortwave, gas, atmosphere)
    rh_fluxes = RadiativeFluxes(
        longwave_up = zeros(5),
        longwave_down = zeros(5),
        shortwave_up = zeros(5),
        shortwave_down = zeros(5),
    )
    radiative_fluxes!(rh_fluxes,
                      CloudlessLongwave(),
                      longwave,
                      atmosphere,
                      LongwaveBoundaryConditions(surface_longwave_up = 0.98 * 5.670374419e-8 * 300.0^4))
    radiative_fluxes!(rh_fluxes,
                      CloudlessShortwave(),
                      shortwave,
                      atmosphere,
                      ShortwaveBoundaryConditions(toa_shortwave_down = 500.0,
                                                  surface_albedo = 0.1))
    metrics = radiative_flux_error_metrics(rh_fluxes, rrtmgp_fluxes, atmosphere;
                                           gravity = 9.80665,
                                           heat_capacity = 1004.0)
    @test isfinite(metrics.flux_rmse)
    @test isfinite(metrics.heating_rate_rmse)
end
# --- end content of test_rrtmgp_ext.jl ---

end # module TestRrtmgpExt

module TestAccessPointsCheck
using Test
using NumericalRadiation
using Dates

# --- begin content of test_access_points_check.jl ---
@testset "host-model access points artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "access_points_check.jl")
    output = read(`$(Base.julia_cmd()) --project=$(Base.active_project()) $script`, String)
    @test occursin("Host-Model Access Points Check", output)
    @test occursin("Status: **passed**", output)
    @test occursin("Host can stop after gas optics", output)
    @test occursin("Host can replace solver or vertical integral", output)

    json_path = joinpath(@__DIR__, "..", "validation", "results", "access_points_check.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results", "access_points_check.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"host_model_access_points_check\"", json)
    @test occursin("\"status\": \"passed\"", json)
    @test occursin("\"host_can_stop_after_gas_optics\": true", json)
    @test occursin("\"host_can_replace_solver_or_vertical_integral\": true", json)
end
# --- end content of test_access_points_check.jl ---

end # module TestAccessPointsCheck
