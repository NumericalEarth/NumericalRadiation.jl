# Consolidated from the original per-topic test files (Stage R2).
# Each original file's content is preserved verbatim inside its own module
# so top-level consts/functions from included check scripts cannot clash.

module TestPlanck
using Test
using NumericalRadiation
using Dates

# --- begin content of test_planck.jl ---
@testset "planck: Stefan-Boltzmann recovery" begin
    # π ∫ B(T, ν̃) dν̃ from 10 to 2510 cm⁻¹ must be within ~1% of σ T⁴ at 300 K.
    T = 300.0f0
    lw = AnalyticBandLongwave(Float32)
    nν = lw.nwavenumber
    dν̃ = (lw.wavenumber_max - lw.wavenumber_min) / (nν - 1)
    pi_B = sum(Float32(π) * planck_wavenumber(T, lw.wavenumber_min + (iv-1)*dν̃) * dν̃
               for iv in 1:nν)
    σ_SB = 5.670374419f-8
    @test pi_B ≈ σ_SB * T^4 rtol = 0.01
end

@testset "planck: monotonic in temperature" begin
    ν̃ = 667.0
    @test planck_wavenumber(250.0, ν̃) < planck_wavenumber(290.0, ν̃)
    @test planck_wavenumber(290.0, ν̃) < planck_wavenumber(320.0, ν̃)
end
# --- end content of test_planck.jl ---

end # module TestPlanck

module TestAbsorption
using Test
using NumericalRadiation
using Dates

# --- begin content of test_absorption.jl ---
@testset "h2o_line_kappa_ref: band structure" begin
    lw = AnalyticBandLongwave(Float32)
    @test h2o_line_kappa_ref(100f0, lw) ≈ lw.κ_rot
    @test h2o_line_kappa_ref(200f0, lw) ≈ lw.κ_rot
    @test h2o_line_kappa_ref(600f0, lw) < lw.κ_rot
    @test h2o_line_kappa_ref(600f0, lw) ≈ lw.κ_rot * exp(-(600f0 - 200f0) / lw.l_rot) rtol = 1f-5
    @test h2o_line_kappa_ref(1450f0, lw) ≈ lw.κ_vr
    @test h2o_line_kappa_ref(1600f0, lw) ≈ lw.κ_vr
    @test h2o_line_kappa_ref(2000f0, lw) < lw.κ_vr
    @test h2o_line_kappa_ref(3000f0, lw) == 0f0
end

@testset "co2_kappa_ref: peak + e-folding" begin
    lw = AnalyticBandLongwave(Float32)
    @test co2_kappa_ref(667f0, lw) ≈ lw.κ_CO₂
    @test co2_kappa_ref(667f0 + lw.l_CO₂, lw) ≈ lw.κ_CO₂ / Float32(ℯ) rtol = 1f-4
    @test co2_kappa_ref(400f0, lw) == 0f0
    @test co2_kappa_ref(900f0, lw) == 0f0
end

@testset "h2o_cont_kappa_ref: two-band split" begin
    lw = AnalyticBandLongwave(Float32)
    @test h2o_cont_kappa_ref(1000f0, lw) == lw.κ_cnt1
    @test h2o_cont_kappa_ref(2000f0, lw) == lw.κ_cnt2
    # Paper convention: 1700 cm⁻¹ belongs to the upper (weaker) band.
    @test h2o_cont_kappa_ref(1700f0, lw) == lw.κ_cnt2
    @test h2o_cont_kappa_ref(1699f0, lw) == lw.κ_cnt1
    @test lw.κ_cnt1 > lw.κ_cnt2
end

@testset "williams_delta_tau: positivity + rotation-band dominance" begin
    NF = Float32
    nlayers = 4
    σ_half = collect(NF.(range(0, 1, length = nlayers + 1)))
    geom = ColumnGrid(σ_half)
    T = fill(NF(280), nlayers)
    q = fill(NF(0.005), nlayers)
    pₛ = NF(100_000)
    g  = NF(9.80665)

    lw = AnalyticBandLongwave(NF)

    dν̃ = (lw.wavenumber_max - lw.wavenumber_min) / (lw.nwavenumber - 1)

    for k in 1:nlayers
        Δτ_win      = NumericalRadiation.williams_delta_tau(k, NF(1000), NF(0),   T, q, pₛ, geom, lw, g)
        Δτ_rot      = NumericalRadiation.williams_delta_tau(k, NF(400),  NF(0),   T, q, pₛ, geom, lw, g)
        Δτ_no_co2   = NumericalRadiation.williams_delta_tau(k, NF(667),  NF(0),   T, q, pₛ, geom, lw, g)
        Δτ_with_co2 = NumericalRadiation.williams_delta_tau(k, NF(667),  NF(280), T, q, pₛ, geom, lw, g)

        @test Δτ_win > 0
        @test Δτ_rot > Δτ_win
        @test Δτ_with_co2 > Δτ_no_co2

        for iv in 1:lw.nwavenumber
            ν̃ = lw.wavenumber_min + (iv - 1) * dν̃
            @test NumericalRadiation.williams_delta_tau(k, NF(ν̃), NF(0), T, q, pₛ, geom, lw, g) >= 0
        end
    end
end
# --- end content of test_absorption.jl ---

end # module TestAbsorption

module TestWilliamsLongwave
using Test
using NumericalRadiation
using Dates

# --- begin content of test_williams_longwave.jl ---
"Build a σ-coordinate column of `nlayers` layers with lapse-rate temperature,
constant humidity and a 100 kPa surface pressure."
function _test_column(::Type{NF}, nlayers; T_surface = 295, T_top = 220, q = 0.005) where NF
    σ_half = collect(NF.(range(0, 1, length = nlayers + 1)))
    geom   = ColumnGrid(σ_half)
    T      = NF.(collect(T_top .+ (T_surface - T_top) .* range(0, 1, length = nlayers)))
    q      = fill(NF(q), nlayers)
    Φ      = zeros(NF, nlayers)
    profile = AtmosphereProfile(temperature = T, humidity = q, geopotential = Φ,
                            surface_pressure = NF(100_000))
    return profile, geom
end

@testset "AnalyticBandLongwave: parameterization smoke test" begin
    NF = Float32
    nlayers = 8
    lw = AnalyticBandLongwave(NF)
    profile, geom = _test_column(NF, nlayers)
    surface = SurfaceState{NF}(sea_surface_temperature = NF(295),
                                land_surface_temperature = NF(285),
                                land_fraction = NF(0.3))
    constants = PhysicalConstants{NF}()
    dTdt = zeros(NF, nlayers)
    diag = LongwaveDiagnostics{NF}()
    solve_longwave!(dTdt, diag, lw, profile, geom, surface, constants)
    @test any(!=(0), dTdt)
    @test isfinite(diag.outgoing_longwave)
    @test diag.outgoing_longwave > 0
end

@testset "AnalyticBandLongwave: energy conservation sanity" begin
    NF = Float32
    nlayers = 8
    lw = AnalyticBandLongwave(NF)
    profile, geom = _test_column(NF, nlayers)
    surface = SurfaceState{NF}(sea_surface_temperature = NF(295),
                                land_surface_temperature = NF(285),
                                land_fraction = NF(0.3))
    constants = PhysicalConstants{NF}()
    dTdt = zeros(NF, nlayers)
    diag = LongwaveDiagnostics{NF}()
    solve_longwave!(dTdt, diag, lw, profile, geom, surface, constants)

    @test all(isfinite, dTdt)
    @test diag.outgoing_longwave > 0
    @test diag.surface_longwave_down >= 0
    @test diag.surface_longwave_down <= diag.surface_longwave_up
end

@testset "AnalyticBandLongwave: CO₂ forcing" begin
    NF = Float32
    nlayers = 8
    lw = AnalyticBandLongwave(NF)

    function _olr(CO₂)
        profile, geom = _test_column(NF, nlayers)
        profile = AtmosphereProfile(temperature = profile.temperature,
                                    humidity = profile.humidity,
                                    geopotential = profile.geopotential,
                                    surface_pressure = profile.surface_pressure,
                                    CO₂ = NF(CO₂))
        surface = SurfaceState{NF}(sea_surface_temperature = NF(295),
                                    land_surface_temperature = NF(285),
                                    land_fraction = NF(0.3))
        constants = PhysicalConstants{NF}()
        dTdt = zeros(NF, nlayers)
        diag = LongwaveDiagnostics{NF}()
        solve_longwave!(dTdt, diag, lw, profile, geom, surface, constants)
        return diag.outgoing_longwave
    end
    olr_280 = _olr(280)
    olr_560 = _olr(560)
    @test olr_560 < olr_280
    forcing = olr_280 - olr_560
    @test 1 < forcing < 10
end

@testset "AnalyticBandLongwave: Float32 vs Float64 compatibility" begin
    for NF in (Float32, Float64)
        nlayers = 4
        lw = AnalyticBandLongwave(NF)
        profile, geom = _test_column(NF, nlayers)
        surface = SurfaceState{NF}(sea_surface_temperature = NF(295),
                                    land_surface_temperature = NF(285),
                                    land_fraction = NF(0.3))
        constants = PhysicalConstants{NF}()
        dTdt = zeros(NF, nlayers)
        diag = LongwaveDiagnostics{NF}()
        solve_longwave!(dTdt, diag, lw, profile, geom, surface, constants)
        @test all(isfinite, dTdt)
    end
end
# --- end content of test_williams_longwave.jl ---

end # module TestWilliamsLongwave

module TestShortwave
using Test
using NumericalRadiation
using Dates

# --- begin content of test_shortwave.jl ---
function _test_sw_column(::Type{NF}, nlayers; q = 0.005) where NF
    σ_half = collect(NF.(range(0, 1, length = nlayers + 1)))
    geom   = ColumnGrid(σ_half)
    T      = NF.(collect(220 .+ 9 .* (0:(nlayers - 1))))
    qv     = fill(NF(q), nlayers)
    Φ      = zeros(NF, nlayers)
    profile = AtmosphereProfile(temperature = T, humidity = qv, geopotential = Φ,
                            surface_pressure = NF(100_000))
    return profile, geom
end

@testset "TransparentShortwave: surface energy budget" begin
    NF = Float32
    nlayers = 4
    profile, geom = _test_sw_column(NF, nlayers)
    surface = SurfaceState{NF}(sea_surface_temperature = NF(295),
                                land_surface_temperature = NF(NaN),
                                land_fraction = NF(0),
                                ocean_albedo = NF(0.2),
                                land_albedo = NF(0.15),
                                cos_zenith = NF(0.5))
    constants = PhysicalConstants{NF}()
    thermo = ThermodynamicConstants{NF}()
    dTdt = zeros(NF, nlayers)
    diag = ShortwaveDiagnostics{NF}(nlayers)
    solve_shortwave!(dTdt, diag, NumericalRadiation.TransparentShortwave(), profile, geom, surface, constants, thermo)

    @test diag.surface_shortwave_down ≈ constants.solar_constant * 0.5f0
    @test diag.outgoing_shortwave ≈ 0.2f0 * constants.solar_constant * 0.5f0
    @test all(==(0), dTdt)
end

@testset "OneBandGreyShortwave: absorption in the atmosphere" begin
    NF = Float32
    nlayers = 8
    profile, geom = _test_sw_column(NF, nlayers)
    surface = SurfaceState{NF}(sea_surface_temperature = NF(295),
                                land_surface_temperature = NF(NaN),
                                land_fraction = NF(0),
                                ocean_albedo = NF(0.1),
                                land_albedo = NF(0.1),
                                cos_zenith = NF(0.5))
    constants = PhysicalConstants{NF}()
    thermo = ThermodynamicConstants{NF}()
    dTdt = zeros(NF, nlayers)
    t_scratch = similar(profile.temperature)
    diag = ShortwaveDiagnostics{NF}(nlayers)
    scheme = NumericalRadiation.OneBandGreyShortwave(NF)
    solve_shortwave!(dTdt, diag, scheme, profile, geom, surface, constants, thermo;
                     transmissivity_scratch = t_scratch)

    D_toa = constants.solar_constant * NF(0.5)
    @test 0 < diag.surface_shortwave_down < D_toa
    @test all(dTdt .> 0)              # heating everywhere
    @test diag.outgoing_shortwave > 0
    @test 0 < diag.albedo < 1
end

@testset "OneBandShortwave (full SPEEDY): runs with diagnostic clouds" begin
    NF = Float32
    nlayers = 8
    profile, geom = _test_sw_column(NF, nlayers; q = 0.01)
    profile = AtmosphereProfile(temperature = profile.temperature,
                            humidity = profile.humidity,
                            geopotential = profile.geopotential,
                            surface_pressure = profile.surface_pressure,
                            rain_rate = NF(1e-6))                 # ~0.09 mm/day
    surface = SurfaceState{NF}(sea_surface_temperature = NF(295),
                                land_surface_temperature = NF(285),
                                land_fraction = NF(0.3),
                                ocean_albedo = NF(0.07),
                                land_albedo = NF(0.25),
                                cos_zenith = NF(0.6))
    constants = PhysicalConstants{NF}()
    thermo = ThermodynamicConstants{NF}()
    dTdt = zeros(NF, nlayers)
    t_scratch = similar(profile.temperature)
    diag = ShortwaveDiagnostics{NF}(nlayers)
    scheme = NumericalRadiation.OneBandShortwave(NF)
    solve_shortwave!(dTdt, diag, scheme, profile, geom, surface, constants, thermo;
                     transmissivity_scratch = t_scratch)

    @test all(isfinite, dTdt)
    @test diag.surface_shortwave_down > 0
    @test diag.outgoing_shortwave > 0
    @test 0 <= diag.cloud_cover <= 1
end
# --- end content of test_shortwave.jl ---

end # module TestShortwave

module TestZenith
using Test
using NumericalRadiation
using Dates

# --- begin content of test_zenith.jl ---
@testset "solar_declination: cardinal dates" begin
    # Spencer-series values at solstices and equinoxes, in degrees.
    γ_equinox   = 2π * (79 - 1) / 365.25          # roughly 20 March
    γ_summer    = 2π * (172 - 1) / 365.25         # roughly 21 June
    γ_winter    = 2π * (355 - 1) / 365.25         # roughly 21 December
    @test solar_declination(γ_equinox) * 180 / π ≈ 0 atol = 1
    @test solar_declination(γ_summer) * 180 / π ≈ 23.44 atol = 1
    @test solar_declination(γ_winter) * 180 / π ≈ -23.44 atol = 1
end

@testset "cosine_solar_zenith: nightside = 0" begin
    t = DateTime(2026, 6, 21, 12, 0, 0)
    cosθ_noon_equator = cosine_solar_zenith(0.0, 0.0, t)
    cosθ_midnight = cosine_solar_zenith(π, 0.0, t)
    @test cosθ_noon_equator > 0.8
    @test cosθ_midnight ≈ 0 atol = 1e-6
end
# --- end content of test_zenith.jl ---

end # module TestZenith

module TestRtc
using Test
using NumericalRadiation
using Dates

# --- begin content of test_rtc.jl ---
@testset "RadiativeTransferColumn: umbrella API" begin
    nlayers = 8
    σ_half = collect(range(0.0, 1.0, length = nlayers + 1))
    grid    = ColumnGrid(σ_half)
    profile = AtmosphereProfile(
        temperature      = collect(range(220.0, 295.0, length = nlayers)),
        humidity         = fill(0.005, nlayers),
        geopotential     = zeros(nlayers),
        surface_pressure = 100_000.0,
    )
    surface = SurfaceState(
        sea_surface_temperature  = 295.0,
        land_surface_temperature = 285.0,
        land_fraction            = 0.3,
        ocean_albedo             = 0.07,
        land_albedo              = 0.25,
        cos_zenith               = 0.5,
    )

    rtm = RadiativeTransferColumn(; grid, profile, surface)

    solve_longwave!(rtm)
    @test isfinite(rtm.longwave_diagnostics.outgoing_longwave)
    @test rtm.longwave_diagnostics.outgoing_longwave > 0
    @test rtm.longwave_diagnostics.surface_longwave_down >= 0

    solve_shortwave!(rtm)
    @test rtm.shortwave_diagnostics.surface_shortwave_down > 0
    @test rtm.shortwave_diagnostics.outgoing_shortwave > 0
    @test 0 < rtm.shortwave_diagnostics.albedo < 1

    # reset! zeroes tendency + diagnostics
    reset!(rtm)
    @test all(==(0), rtm.temperature_tendency)
    @test rtm.longwave_diagnostics.outgoing_longwave == 0
end

@testset "RadiativeTransferColumn: Float32 propagation" begin
    NF = Float32
    nlayers = 4
    σ_half = collect(NF.(range(0, 1, length = nlayers + 1)))
    grid   = ColumnGrid(σ_half)
    profile = AtmosphereProfile(
        temperature = collect(NF.(range(220, 295, length = nlayers))),
        humidity    = fill(NF(0.005), nlayers),
        geopotential = zeros(NF, nlayers),
        surface_pressure = NF(100_000),
    )
    surface = SurfaceState{NF}(
        sea_surface_temperature  = NF(295),
        land_surface_temperature = NF(285),
        land_fraction            = NF(0.3),
    )
    rtm = RadiativeTransferColumn(; grid, profile, surface,
        longwave_scheme = AnalyticBandLongwave(NF),
        shortwave_scheme = NumericalRadiation.OneBandShortwave(NF),
        physical_constants = PhysicalConstants{NF}(),
        thermodynamic_constants = ThermodynamicConstants{NF}())
    solve_longwave!(rtm)
    @test eltype(rtm.temperature_tendency) === NF
    @test isa(rtm.longwave_diagnostics.outgoing_longwave, NF)
end

@testset "solve_longwave!: duck-typed constants" begin
    nlayers = 4
    σ_half = collect(range(0.0, 1.0, length = nlayers + 1))
    grid   = ColumnGrid(σ_half)
    profile = AtmosphereProfile(
        temperature = collect(range(220.0, 295.0, length = nlayers)),
        humidity = fill(0.005, nlayers),
        geopotential = zeros(nlayers),
        surface_pressure = 100_000.0,
    )
    surface = SurfaceState(sea_surface_temperature = 295.0,
                           land_surface_temperature = 285.0,
                           land_fraction = 0.3)

    # Plain NamedTuple with the expected field names — should work.
    foreign = (gravity = 9.80665, heat_capacity = 1004.64,
               stefan_boltzmann = 5.670374419e-8, solar_constant = 1361.0)
    dTdt = zeros(nlayers)
    diag = LongwaveDiagnostics()
    solve_longwave!(dTdt, diag, AnalyticBandLongwave(), profile, grid, surface, foreign)
    @test diag.outgoing_longwave > 0
end
# --- end content of test_rtc.jl ---

end # module TestRtc

module TestRuntimeInterfaces
using Test
using NumericalRadiation
using Dates

# --- begin content of test_runtime_interfaces.jl ---
@testset "Runtime interface scaffold" begin
    @test AbstractAtmosphericState isa DataType
    @test AbstractGasOpticsModel isa DataType
    @test AbstractCloudOpticsModel isa DataType
    @test AbstractAerosolOpticsModel isa DataType
    @test AbstractRadiativeTransferSolver isa DataType
    @test AbstractRadiationBackend isa DataType

    nlayers = 4
    pressure_interfaces = collect(range(1_000.0, 100_000.0, length = nlayers + 1))
    pressure_layers = @views (pressure_interfaces[1:end-1] .+ pressure_interfaces[2:end]) ./ 2
    temperature_interfaces = collect(range(210.0, 290.0, length = nlayers + 1))
    temperature_layers = @views (temperature_interfaces[1:end-1] .+ temperature_interfaces[2:end]) ./ 2

    atmosphere = ColumnAtmosphere(
        pressure_layers = pressure_layers,
        pressure_interfaces = pressure_interfaces,
        temperature_layers = temperature_layers,
        temperature_interfaces = temperature_interfaces,
        gases = (; h2o = fill(0.005, nlayers), co2 = 420.0),
        surface = (; temperature = 290.0, emissivity = 1.0),
        geometry = (; cos_zenith = 0.5),
    )

    @test atmosphere isa AbstractAtmosphericState
    @test eltype(atmosphere) === Float64

    fluxes = RadiativeFluxes(
        longwave_up = zeros(nlayers + 1),
        longwave_down = zeros(nlayers + 1),
        shortwave_up = zeros(nlayers + 1),
        shortwave_down = zeros(nlayers + 1),
    )

    @test eltype(fluxes) === Float64
    @test length(fluxes.longwave_up) == nlayers + 1
end

@testset "RadiativeFluxes to heating rates" begin
    nlayers = 2
    pressure_interfaces = [0.0, 50_000.0, 100_000.0]
    pressure_layers = [25_000.0, 75_000.0]
    temperature_interfaces = fill(280.0, nlayers + 1)
    temperature_layers = fill(280.0, nlayers)
    atmosphere = ColumnAtmosphere(
        pressure_layers = pressure_layers,
        pressure_interfaces = pressure_interfaces,
        temperature_layers = temperature_layers,
        temperature_interfaces = temperature_interfaces,
        gases = (;),
        surface = (;),
        geometry = (;),
    )

    fluxes = RadiativeFluxes(
        longwave_up = zeros(nlayers + 1),
        longwave_down = zeros(nlayers + 1),
        shortwave_up = zeros(nlayers + 1),
        shortwave_down = [200.0, 150.0, 150.0],
    )
    heating = zeros(nlayers)

    heating_rates!(heating, fluxes, atmosphere; gravity = 10.0, heat_capacity = 1000.0)

    @test heating[1] ≈ 1.0e-5
    @test heating[2] == 0.0
    column_energy = sum(heating .* diff(pressure_interfaces)) * 1000.0 / 10.0
    @test column_energy ≈ 50.0

    fluxes.longwave_up .= [100.0, 110.0, 110.0]
    fluxes.shortwave_down .= 0.0
    heating_rates!(heating, fluxes, atmosphere; gravity = 10.0, heat_capacity = 1000.0)

    @test heating[1] ≈ 2.0e-6
    @test heating[2] == 0.0

    fluxes.longwave_down .= [10.0, 15.0, 20.0]
    fluxes.longwave_up .= [80.0, 70.0, 65.0]
    fluxes.shortwave_down .= [500.0, 450.0, 410.0]
    fluxes.shortwave_up .= [50.0, 55.0, 60.0]
    heating_rates!(heating, fluxes, atmosphere; gravity = 10.0, heat_capacity = 1000.0)

    net_flux = fluxes.longwave_down .- fluxes.longwave_up .+
        fluxes.shortwave_down .- fluxes.shortwave_up
    layer_energy = heating .* diff(pressure_interfaces) .* 1000.0 ./ 10.0
    @test layer_energy ≈ net_flux[1:end-1] .- net_flux[2:end]
    @test maximum(abs.(layer_energy .- (net_flux[1:end-1] .- net_flux[2:end]))) < 1.0e-12
end

@testset "RadiativeTransferColumn staged wrapper" begin
    nlayers = 6
    grid = ColumnGrid(collect(range(0.0, 1.0, length = nlayers + 1)))
    profile = AtmosphereProfile(
        temperature = collect(range(220.0, 295.0, length = nlayers)),
        humidity = fill(0.005, nlayers),
        geopotential = zeros(nlayers),
        surface_pressure = 100_000.0,
    )
    surface = SurfaceState(
        sea_surface_temperature = 295.0,
        land_surface_temperature = 285.0,
        land_fraction = 0.3,
        ocean_albedo = 0.07,
        land_albedo = 0.25,
        cos_zenith = 0.5,
    )

    rtm = RadiativeTransferColumn(; grid, profile, surface)
    @test radiation_workspace(rtm) === rtm

    returned = radiative_heating!(rtm)
    @test returned === rtm
    @test any(!iszero, rtm.temperature_tendency)
    @test rtm.longwave_diagnostics.outgoing_longwave > 0
    @test rtm.shortwave_diagnostics.surface_shortwave_down > 0

    heating = similar(rtm.temperature_tendency)
    heating_rates!(heating, rtm)
    @test heating == rtm.temperature_tendency

    previous = copy(rtm.temperature_tendency)
    radiative_heating!(rtm; reset = false, shortwave = false)
    @test rtm.temperature_tendency != previous
end
# --- end content of test_runtime_interfaces.jl ---

end # module TestRuntimeInterfaces

module TestCloudlessLongwaveSolver
using Test
using NumericalRadiation
using Dates

# --- begin content of test_cloudless_longwave_solver.jl ---
@testset "CloudlessLongwave precomputed-optics solver" begin
    nlayers = 3
    fluxes = RadiativeFluxes(
        longwave_up = zeros(nlayers + 1),
        longwave_down = zeros(nlayers + 1),
        shortwave_up = zeros(nlayers + 1),
        shortwave_down = zeros(nlayers + 1),
    )
    atmosphere = nothing

    @testset "no-atmosphere limit" begin
        optics = LongwaveOpticalProperties(zeros(nlayers), zeros(nlayers))
        boundary = LongwaveBoundaryConditions(surface_longwave_up = 300.0)

        radiative_fluxes!(fluxes, CloudlessLongwave(), optics, atmosphere, boundary)

        @test fluxes.longwave_up == fill(300.0, nlayers + 1)
        @test fluxes.longwave_down == zeros(nlayers + 1)
    end

    @testset "single-layer absorber" begin
        tau = [log(2.0)]
        source = [100.0]
        one_layer_fluxes = RadiativeFluxes(
            longwave_up = zeros(2),
            longwave_down = zeros(2),
            shortwave_up = zeros(2),
            shortwave_down = zeros(2),
        )
        optics = LongwaveOpticalProperties(tau, source)
        boundary = LongwaveBoundaryConditions(surface_longwave_up = 300.0)

        radiative_fluxes!(one_layer_fluxes, CloudlessLongwave(), optics, atmosphere, boundary)

        @test one_layer_fluxes.longwave_up[2] == 300.0
        @test one_layer_fluxes.longwave_up[1] ≈ 200.0
        @test one_layer_fluxes.longwave_down[1] == 0.0
        @test one_layer_fluxes.longwave_down[2] ≈ 50.0
    end

    @testset "two-layer pure absorber closed-form Schwarzschild solution" begin
        tau = [0.3, 1.1]
        source = [180.0, 260.0]
        surface_up = 340.0
        toa_down = 25.0
        two_layer_fluxes = RadiativeFluxes(
            longwave_up = zeros(3),
            longwave_down = zeros(3),
            shortwave_up = zeros(3),
            shortwave_down = zeros(3),
        )
        optics = LongwaveOpticalProperties(tau, source)
        boundary = LongwaveBoundaryConditions(surface_longwave_up = surface_up,
                                              toa_longwave_down = toa_down)

        radiative_fluxes!(two_layer_fluxes, CloudlessLongwave(), optics,
                          atmosphere, boundary)

        transmittance = exp.(-tau)
        expected_up = zeros(3)
        expected_down = zeros(3)
        expected_up[3] = surface_up
        expected_up[2] = surface_up * transmittance[2] +
            source[2] * (1 - transmittance[2])
        expected_up[1] = expected_up[2] * transmittance[1] +
            source[1] * (1 - transmittance[1])
        expected_down[1] = toa_down
        expected_down[2] = toa_down * transmittance[1] +
            source[1] * (1 - transmittance[1])
        expected_down[3] = expected_down[2] * transmittance[2] +
            source[2] * (1 - transmittance[2])

        @test two_layer_fluxes.longwave_up ≈ expected_up rtol = 1.0e-12 atol = 1.0e-12
        @test two_layer_fluxes.longwave_down ≈ expected_down rtol = 1.0e-12 atol = 1.0e-12
    end

    @testset "weighted spectral accumulation" begin
        tau = [0.0 0.0;
               log(2.0) log(2.0)]
        source = [0.0 0.0;
                  100.0 100.0]
        weights = [0.25, 0.75]
        two_layer_fluxes = RadiativeFluxes(
            longwave_up = zeros(3),
            longwave_down = zeros(3),
            shortwave_up = zeros(3),
            shortwave_down = zeros(3),
        )
        optics = LongwaveOpticalProperties(tau, source; weights)
        boundary = LongwaveBoundaryConditions(surface_longwave_up = 300.0)

        radiative_fluxes!(two_layer_fluxes, CloudlessLongwave(), optics, atmosphere, boundary)

        @test two_layer_fluxes.longwave_up[3] == 300.0
        @test two_layer_fluxes.longwave_up[1] ≈ 187.5
        @test two_layer_fluxes.longwave_down[1] == 0.0
        @test two_layer_fluxes.longwave_down[3] ≈ 56.25
    end

    @testset "spectral surface boundary" begin
        tau = [0.0;
               log(2.0)][:, :]
        source = zeros(2, 1)
        weights = [0.25, 0.75]
        one_layer_fluxes = RadiativeFluxes(
            longwave_up = zeros(2),
            longwave_down = zeros(2),
            shortwave_up = zeros(2),
            shortwave_down = zeros(2),
        )
        optics = LongwaveOpticalProperties(tau, source; weights)
        boundary = LongwaveBoundaryConditions(surface_longwave_up = [100.0, 500.0])

        radiative_fluxes!(one_layer_fluxes, CloudlessLongwave(), optics, atmosphere, boundary)

        @test one_layer_fluxes.longwave_up[2] ≈ 400.0
        @test one_layer_fluxes.longwave_up[1] ≈ 25.0 + 187.5
        @test one_layer_fluxes.longwave_down == zeros(2)
    end

    @testset "ecRad no-scattering interface sources" begin
        tau = [0.5]
        source = [125.0]
        source_top = [100.0]
        source_bottom = [200.0]
        one_layer_fluxes = RadiativeFluxes(
            longwave_up = zeros(2),
            longwave_down = zeros(2),
            shortwave_up = zeros(2),
            shortwave_down = zeros(2),
        )
        optics = LongwaveOpticalProperties(tau, source; source_top, source_bottom)
        boundary = LongwaveBoundaryConditions(surface_longwave_up = 300.0)

        radiative_fluxes!(one_layer_fluxes, CloudlessLongwave(), optics, atmosphere, boundary)

        coeff = 1.66 * tau[1]
        transmittance = exp(-coeff)
        gradient = (source_bottom[1] - source_top[1]) / coeff
        expected_source_up = gradient + source_top[1] -
            transmittance * (gradient + source_bottom[1])
        expected_source_down = -gradient + source_bottom[1] -
            transmittance * (-gradient + source_top[1])

        @test one_layer_fluxes.longwave_up[2] == 300.0
        @test one_layer_fluxes.longwave_up[1] ≈ 300.0 * transmittance + expected_source_up
        @test one_layer_fluxes.longwave_down[1] == 0.0
        @test one_layer_fluxes.longwave_down[2] ≈ expected_source_down
    end

    @testset "longwave scattering reduces to no scattering for zero ssa" begin
        tau = [0.5 0.2]
        source = [125.0 175.0]
        source_top = [100.0 150.0]
        source_bottom = [200.0 250.0]
        no_scattering_fluxes = RadiativeFluxes(
            longwave_up = zeros(3),
            longwave_down = zeros(3),
            shortwave_up = zeros(3),
            shortwave_down = zeros(3),
        )
        scattering_fluxes = RadiativeFluxes(
            longwave_up = zeros(3),
            longwave_down = zeros(3),
            shortwave_up = zeros(3),
            shortwave_down = zeros(3),
        )
        no_scattering = LongwaveOpticalProperties(
            tau, source; source_top, source_bottom)
        scattering = LongwaveOpticalProperties(
            tau, source;
            source_top,
            source_bottom,
            single_scattering_albedo = zeros(1, 2),
            scattering_asymmetry = zeros(1, 2),
        )
        boundary = LongwaveBoundaryConditions(surface_longwave_up = 300.0)

        radiative_fluxes!(no_scattering_fluxes, CloudlessLongwave(),
                          no_scattering, atmosphere, boundary)
        radiative_fluxes!(scattering_fluxes, CloudlessLongwave(),
                          scattering, atmosphere, boundary)

        @test scattering_fluxes.longwave_up ≈ no_scattering_fluxes.longwave_up
        @test scattering_fluxes.longwave_down ≈ no_scattering_fluxes.longwave_down
    end
end

@testset "CloudOverlapLongwave all-sky access point" begin
    atmosphere = nothing
    clear = LongwaveOpticalProperties(
        [0.1 0.1],
        zeros(1, 2);
        source_top = [100.0 120.0],
        source_bottom = [120.0 140.0],
    )
    cloudy = LongwaveOpticalProperties(
        [0.5 0.5],
        zeros(1, 2);
        source_top = [100.0 120.0],
        source_bottom = [120.0 140.0],
    )
    clear_fluxes = RadiativeFluxes(
        longwave_up = zeros(3),
        longwave_down = zeros(3),
        shortwave_up = zeros(3),
        shortwave_down = zeros(3),
    )
    cloudy_fluxes = RadiativeFluxes(
        longwave_up = zeros(3),
        longwave_down = zeros(3),
        shortwave_up = zeros(3),
        shortwave_down = zeros(3),
    )
    overlap_fluxes = RadiativeFluxes(
        longwave_up = zeros(3),
        longwave_down = zeros(3),
        shortwave_up = zeros(3),
        shortwave_down = zeros(3),
    )
    boundary = LongwaveBoundaryConditions(surface_longwave_up = 300.0)

    radiative_fluxes!(clear_fluxes, CloudlessLongwave(), clear, atmosphere, boundary)
    radiative_fluxes!(cloudy_fluxes, CloudlessLongwave(), cloudy, atmosphere, boundary)

    clear_overlap = LongwaveCloudOverlapOpticalProperties(clear, cloudy, [0.0, 0.0])
    radiative_fluxes!(overlap_fluxes, CloudOverlapLongwave(), clear_overlap,
                      atmosphere, boundary)
    @test overlap_fluxes.longwave_up ≈ clear_fluxes.longwave_up
    @test overlap_fluxes.longwave_down ≈ clear_fluxes.longwave_down

    full_cloud_overlap =
        LongwaveCloudOverlapOpticalProperties(clear, cloudy, [1.0, 1.0])
    radiative_fluxes!(overlap_fluxes, CloudOverlapLongwave(), full_cloud_overlap,
                      atmosphere, boundary)
    @test overlap_fluxes.longwave_up ≈ cloudy_fluxes.longwave_up
    @test overlap_fluxes.longwave_down ≈ cloudy_fluxes.longwave_down

    mixed_overlap = LongwaveCloudOverlapOpticalProperties(clear, cloudy, [0.5, 0.5])
    radiative_fluxes!(overlap_fluxes, CloudOverlapLongwave(), mixed_overlap,
                      atmosphere, boundary)
    @test all(isfinite, overlap_fluxes.longwave_up)
    @test all(isfinite, overlap_fluxes.longwave_down)

    tripleclouds_overlap = LongwaveCloudOverlapOpticalProperties(
        clear, cloudy, [0.2, 0.8];
        overlap_parameter = [0.5],
        fractional_std = [1.5, 2.0],
    )
    radiative_fluxes!(
        overlap_fluxes,
        CloudOverlapLongwave(overlap = :tripleclouds_alpha),
        tripleclouds_overlap,
        atmosphere,
        boundary,
    )
    @test all(isfinite, overlap_fluxes.longwave_up)
    @test all(isfinite, overlap_fluxes.longwave_down)

    clear_tripleclouds =
        LongwaveCloudOverlapOpticalProperties(clear, cloudy, [0.0, 0.0])
    radiative_fluxes!(
        overlap_fluxes,
        CloudOverlapLongwave(overlap = :tripleclouds_alpha),
        clear_tripleclouds,
        atmosphere,
        boundary,
    )
    @test overlap_fluxes.longwave_up ≈ clear_fluxes.longwave_up
    @test overlap_fluxes.longwave_down ≈ clear_fluxes.longwave_down

    @test_throws DimensionMismatch LongwaveCloudOverlapOpticalProperties(
        clear, cloudy, [0.5])
    @test_throws ArgumentError CloudOverlapLongwave(overlap = :invalid)
end
# --- end content of test_cloudless_longwave_solver.jl ---

end # module TestCloudlessLongwaveSolver

module TestCloudlessShortwaveSolver
using Test
using NumericalRadiation
using Dates

# --- begin content of test_cloudless_shortwave_solver.jl ---
@testset "CloudlessShortwave precomputed-optics solver" begin
    @testset "transparent atmosphere with black surface" begin
        nlayers = 3
        fluxes = RadiativeFluxes(
            longwave_up = zeros(nlayers + 1),
            longwave_down = zeros(nlayers + 1),
            shortwave_up = zeros(nlayers + 1),
            shortwave_down = zeros(nlayers + 1),
        )
        optics = ShortwaveOpticalProperties(zeros(nlayers))
        boundary = ShortwaveBoundaryConditions(toa_shortwave_down = 500.0,
                                               surface_albedo = 0.0)

        radiative_fluxes!(fluxes, CloudlessShortwave(), optics, nothing, boundary)

        @test fluxes.shortwave_down == fill(500.0, nlayers + 1)
        @test fluxes.shortwave_up == zeros(nlayers + 1)
    end

    @testset "no-atmosphere horizontal-flux limit with solar geometry" begin
        fluxes = RadiativeFluxes(
            longwave_up = zeros(1),
            longwave_down = zeros(1),
            shortwave_up = zeros(1),
            shortwave_down = zeros(1),
        )
        optics = ShortwaveOpticalProperties(Float64[])
        atmosphere = (; geometry = (; cos_zenith = 0.25))
        boundary = ShortwaveBoundaryConditions(toa_shortwave_down = 700.0,
                                               surface_albedo = 0.9,
                                               surface_albedo_direct = 0.3)

        radiative_fluxes!(fluxes, CloudlessShortwave(), optics, atmosphere, boundary)

        @test fluxes.shortwave_down == [700.0]
        @test fluxes.shortwave_up == [210.0]
        @test fluxes.shortwave_down[1] - fluxes.shortwave_up[1] == 490.0
    end

    @testset "single-layer absorber and reflecting surface" begin
        fluxes = RadiativeFluxes(
            longwave_up = zeros(2),
            longwave_down = zeros(2),
            shortwave_up = zeros(2),
            shortwave_down = zeros(2),
        )
        optics = ShortwaveOpticalProperties([log(2.0)])
        boundary = ShortwaveBoundaryConditions(toa_shortwave_down = 400.0,
                                               surface_albedo = 0.25)

        radiative_fluxes!(fluxes, CloudlessShortwave(), optics, nothing, boundary)

        @test fluxes.shortwave_down[1] == 400.0
        @test fluxes.shortwave_down[2] ≈ 200.0
        @test fluxes.shortwave_up[2] ≈ 50.0
        @test fluxes.shortwave_up[1] ≈ 25.0
    end

    @testset "weighted spectral accumulation" begin
        nlayers = 2
        fluxes = RadiativeFluxes(
            longwave_up = zeros(nlayers + 1),
            longwave_down = zeros(nlayers + 1),
            shortwave_up = zeros(nlayers + 1),
            shortwave_down = zeros(nlayers + 1),
        )
        tau = [0.0 0.0;
               log(2.0) log(2.0)]
        optics = ShortwaveOpticalProperties(tau; weights = [0.25, 0.75])
        boundary = ShortwaveBoundaryConditions(toa_shortwave_down = 400.0,
                                               surface_albedo = 0.25)

        radiative_fluxes!(fluxes, CloudlessShortwave(), optics, nothing, boundary)

        @test fluxes.shortwave_down[1] == 400.0
        @test fluxes.shortwave_down[3] ≈ 175.0
        @test fluxes.shortwave_up[3] ≈ 43.75
        @test fluxes.shortwave_up[1] ≈ 29.6875
    end

    @testset "per-g-point surface albedo" begin
        fluxes = RadiativeFluxes(
            longwave_up = zeros(2),
            longwave_down = zeros(2),
            shortwave_up = zeros(2),
            shortwave_down = zeros(2),
        )
        tau = reshape([0.0, 0.0], 2, 1)
        optics = ShortwaveOpticalProperties(tau; weights = [0.25, 0.75])
        boundary = ShortwaveBoundaryConditions(toa_shortwave_down = 400.0,
                                               surface_albedo = [0.2, 0.4])

        radiative_fluxes!(fluxes, CloudlessShortwave(), optics, nothing, boundary)

        @test fluxes.shortwave_down == fill(400.0, 2)
        @test fluxes.shortwave_up == fill(140.0, 2)
    end

    @testset "direct surface albedo can differ from diffuse albedo" begin
        fluxes = RadiativeFluxes(
            longwave_up = zeros(2),
            longwave_down = zeros(2),
            shortwave_up = zeros(2),
            shortwave_down = zeros(2),
        )
        optics = ShortwaveOpticalProperties([0.0])
        boundary = ShortwaveBoundaryConditions(toa_shortwave_down = 400.0,
                                               surface_albedo = 0.25,
                                               surface_albedo_direct = 0.1)

        radiative_fluxes!(fluxes, CloudlessShortwave(), optics, nothing, boundary)

        @test fluxes.shortwave_down == fill(400.0, 2)
        @test fluxes.shortwave_up == fill(40.0, 2)
    end

    @testset "cos-zenith scales the direct optical path" begin
        fluxes = RadiativeFluxes(
            longwave_up = zeros(2),
            longwave_down = zeros(2),
            shortwave_up = zeros(2),
            shortwave_down = zeros(2),
        )
        optics = ShortwaveOpticalProperties([log(2.0)])
        atmosphere = (; geometry = (; cos_zenith = 0.5))
        boundary = ShortwaveBoundaryConditions(toa_shortwave_down = 400.0,
                                               surface_albedo = 0.25)

        radiative_fluxes!(fluxes, CloudlessShortwave(), optics, atmosphere, boundary)

        @test fluxes.shortwave_down[1] == 400.0
        @test fluxes.shortwave_down[2] ≈ 100.0
        @test fluxes.shortwave_up[2] ≈ 25.0
        @test fluxes.shortwave_up[1] ≈ 6.25
    end

    @testset "Rayleigh scattering uses ecRad-style two-stream adding" begin
        fluxes = RadiativeFluxes(
            longwave_up = zeros(2),
            longwave_down = zeros(2),
            shortwave_up = zeros(2),
            shortwave_down = zeros(2),
        )
        optics = ShortwaveOpticalProperties([0.0];
                                            rayleigh_optical_depth = [log(2.0)])
        boundary = ShortwaveBoundaryConditions(toa_shortwave_down = 400.0,
                                               surface_albedo = 0.0)

        radiative_fluxes!(fluxes, CloudlessShortwave(), optics, nothing, boundary)

        @test fluxes.shortwave_down[1] == 400.0
        @test fluxes.shortwave_down[2] ≈ 296.07982702762007
        @test fluxes.shortwave_up[1] ≈ 103.92017297152903
        @test fluxes.shortwave_up[2] == 0.0
        @test fluxes.shortwave_down[2] + fluxes.shortwave_up[1] ≈ 400.0
    end

    @testset "single-layer conservative scattering closes energy at mu0 one" begin
        fluxes = RadiativeFluxes(
            longwave_up = zeros(2),
            longwave_down = zeros(2),
            shortwave_up = zeros(2),
            shortwave_down = zeros(2),
        )
        optics = ShortwaveOpticalProperties([0.0];
                                            scattering_optical_depth = [0.7],
                                            scattering_asymmetry = [0.0])
        atmosphere = (; geometry = (; cos_zenith = 1.0))
        boundary = ShortwaveBoundaryConditions(toa_shortwave_down = 400.0,
                                               surface_albedo = 0.0)

        radiative_fluxes!(fluxes, CloudlessShortwave(), optics, atmosphere, boundary)

        @test fluxes.shortwave_down[1] == 400.0
        @test fluxes.shortwave_up[2] == 0.0
        @test fluxes.shortwave_down[2] + fluxes.shortwave_up[1] ≈
              fluxes.shortwave_down[1] rtol = 1.0e-10
        @test all(>=(0), fluxes.shortwave_down)
        @test all(>=(0), fluxes.shortwave_up)
    end

    @testset "Rayleigh backscatter compatibility option preserves ecRad path" begin
        fluxes = RadiativeFluxes(
            longwave_up = zeros(2),
            longwave_down = zeros(2),
            shortwave_up = zeros(2),
            shortwave_down = zeros(2),
        )
        optics = ShortwaveOpticalProperties([0.0];
                                            rayleigh_optical_depth = [log(2.0)])
        boundary = ShortwaveBoundaryConditions(toa_shortwave_down = 400.0,
                                               surface_albedo = 0.0)

        radiative_fluxes!(fluxes,
                          CloudlessShortwave(rayleigh_backscatter_fraction = 0.5),
                          optics,
                          nothing,
                          boundary)

        @test fluxes.shortwave_down[2] ≈ 296.07982702762007
        @test fluxes.shortwave_up[1] ≈ 103.92017297152903
    end

    @testset "scattering asymmetry reaches two-stream coefficients" begin
        fluxes = RadiativeFluxes(
            longwave_up = zeros(2),
            longwave_down = zeros(2),
            shortwave_up = zeros(2),
            shortwave_down = zeros(2),
        )
        optics = ShortwaveOpticalProperties([0.0];
                                            scattering_optical_depth = [log(2.0)],
                                            scattering_asymmetry = [0.8])
        boundary = ShortwaveBoundaryConditions(toa_shortwave_down = 400.0,
                                               surface_albedo = 0.0)

        radiative_fluxes!(fluxes, CloudlessShortwave(), optics, nothing, boundary)

        @test fluxes.shortwave_down[1] == 400.0
        @test fluxes.shortwave_down[2] ≈ 407.619005357698
        @test fluxes.shortwave_up[1] == 0.0
        @test fluxes.shortwave_up[2] == 0.0
    end
end

@testset "CloudOverlapShortwave all-sky access point" begin
    nlayers = 2
    fluxes = RadiativeFluxes(
        longwave_up = zeros(nlayers + 1),
        longwave_down = zeros(nlayers + 1),
        shortwave_up = zeros(nlayers + 1),
        shortwave_down = zeros(nlayers + 1),
    )
    clear = ShortwaveOpticalProperties(zeros(nlayers))
    cloudy = ShortwaveOpticalProperties([log(2.0), log(2.0)])
    optics = ShortwaveCloudOverlapOpticalProperties(clear, cloudy, [0.0, 1.0])
    boundary = ShortwaveBoundaryConditions(toa_shortwave_down = 400.0,
                                           surface_albedo = 0.0)

    radiative_fluxes!(fluxes, CloudOverlapShortwave(overlap = :average),
                      optics, nothing, boundary)

    @test fluxes.shortwave_down[1] ≈ 400.0
    @test fluxes.shortwave_down[2] ≈ 0.5 * 400.0 + 0.5 * 200.0
    @test fluxes.shortwave_down[3] ≈ 100.0
    @test fluxes.shortwave_up == zeros(nlayers + 1)

    adding_fluxes = RadiativeFluxes(
        longwave_up = zeros(nlayers + 1),
        longwave_down = zeros(nlayers + 1),
        shortwave_up = zeros(nlayers + 1),
        shortwave_down = zeros(nlayers + 1),
    )
    radiative_fluxes!(adding_fluxes, CloudOverlapShortwave(overlap = :adding),
                      optics, nothing, boundary)
    @test adding_fluxes.shortwave_down[1] ≈ 400.0
    @test adding_fluxes.shortwave_down[2] ≈ 400.0
    @test adding_fluxes.shortwave_down[3] ≈ 200.0
    @test adding_fluxes.shortwave_up == zeros(nlayers + 1)

    matrix_fluxes = RadiativeFluxes(
        longwave_up = zeros(nlayers + 1),
        longwave_down = zeros(nlayers + 1),
        shortwave_up = zeros(nlayers + 1),
        shortwave_down = zeros(nlayers + 1),
    )
    radiative_fluxes!(matrix_fluxes, CloudOverlapShortwave(overlap = :matrix_maximum),
                      optics, nothing, boundary)
    @test matrix_fluxes.shortwave_down[1] ≈ 400.0
    @test 0.0 <= matrix_fluxes.shortwave_down[3] <= 400.0
    @test matrix_fluxes.shortwave_up == zeros(nlayers + 1)

    alpha_fluxes = RadiativeFluxes(
        longwave_up = zeros(nlayers + 1),
        longwave_down = zeros(nlayers + 1),
        shortwave_up = zeros(nlayers + 1),
        shortwave_down = zeros(nlayers + 1),
    )
    alpha_optics = ShortwaveCloudOverlapOpticalProperties(
        clear, cloudy, [0.0, 1.0]; overlap_parameter = [0.5])
    radiative_fluxes!(alpha_fluxes, CloudOverlapShortwave(overlap = :matrix_alpha),
                      alpha_optics, nothing, boundary)
    @test alpha_fluxes.shortwave_down[1] ≈ 400.0
    @test 0.0 <= alpha_fluxes.shortwave_down[3] <= 400.0
    @test alpha_fluxes.shortwave_up == zeros(nlayers + 1)

    tripleclouds_fluxes = RadiativeFluxes(
        longwave_up = zeros(nlayers + 1),
        longwave_down = zeros(nlayers + 1),
        shortwave_up = zeros(nlayers + 1),
        shortwave_down = zeros(nlayers + 1),
    )
    tripleclouds_optics = ShortwaveCloudOverlapOpticalProperties(
        clear,
        cloudy,
        [0.0, 1.0];
        overlap_parameter = [0.5],
        fractional_std = [1.0, 1.0],
    )
    radiative_fluxes!(tripleclouds_fluxes,
                      CloudOverlapShortwave(overlap = :tripleclouds_alpha),
                      tripleclouds_optics, nothing, boundary)
    @test tripleclouds_fluxes.shortwave_down[1] ≈ 400.0
    @test 0.0 <= tripleclouds_fluxes.shortwave_down[3] <= 400.0
    @test tripleclouds_fluxes.shortwave_up == zeros(nlayers + 1)

    @test_throws DimensionMismatch ShortwaveCloudOverlapOpticalProperties(
        clear, cloudy, [0.0, 1.0]; overlap_parameter = [0.5, 0.5])
    @test_throws DimensionMismatch ShortwaveCloudOverlapOpticalProperties(
        clear, cloudy, [0.0, 1.0]; fractional_std = [1.0])
    @test_throws ArgumentError CloudOverlapShortwave(overlap = :invalid)
end
# --- end content of test_cloudless_shortwave_solver.jl ---

end # module TestCloudlessShortwaveSolver

module TestCloudOptics
using Test
using NumericalRadiation
using Dates

# --- begin content of test_cloud_optics.jl ---
@testset "Layer cloud optics" begin
    @testset "cloud optical properties" begin
        cloud = CloudOpticalProperties(zeros(3), zeros(3))
        model = LayerCloudOpticsModel(cloud_water_path = [0.0, 0.05, 0.10],
                                      longwave_mass_absorption = 2.0,
                                      shortwave_mass_extinction = 5.0)

        cloud_optical_properties!(cloud, model, (;))

        @test cloud.longwave_optical_depth == [0.0, 0.10, 0.20]
        @test cloud.shortwave_optical_depth == [0.0, 0.25, 0.50]
    end

    @testset "add cloud optical depths to gas optics" begin
        longwave = LongwaveOpticalProperties([0.1, 0.2], [50.0, 60.0])
        shortwave = ShortwaveOpticalProperties([0.01, 0.02])
        cloud = CloudOpticalProperties([0.3, 0.4], [0.5, 0.6])

        add_cloud_optical_depths!(longwave, shortwave, cloud)

        @test longwave.optical_depth ≈ [0.4, 0.6]
        @test shortwave.optical_depth ≈ [0.51, 0.62]
        @test shortwave.rayleigh_optical_depth ≈ [0.0, 0.0]
        @test shortwave.scattering_asymmetry ≈ [0.0, 0.0]
    end

    @testset "cloud shortwave scattering is composed separately" begin
        longwave = LongwaveOpticalProperties([0.1, 0.2], [50.0, 60.0])
        shortwave = ShortwaveOpticalProperties([0.01, 0.02])
        cloud = CloudOpticalProperties([0.3, 0.4], [0.5, 0.6];
                                       shortwave_scattering_optical_depth = [0.05, 0.06],
                                       shortwave_scattering_asymmetry = [0.7, 0.8])

        add_cloud_optical_depths!(longwave, shortwave, cloud)

        @test longwave.optical_depth ≈ [0.4, 0.6]
        @test shortwave.optical_depth ≈ [0.51, 0.62]
        @test shortwave.rayleigh_optical_depth ≈ [0.05, 0.06]
        @test shortwave.scattering_asymmetry ≈ [0.7, 0.8]
    end

    @testset "cloud scattering asymmetry is optical-depth weighted" begin
        longwave = LongwaveOpticalProperties([0.1], [50.0])
        shortwave = ShortwaveOpticalProperties([0.01];
                                               scattering_optical_depth = [0.2],
                                               scattering_asymmetry = [0.1])
        cloud = CloudOpticalProperties([0.0], [0.0];
                                       shortwave_scattering_optical_depth = [0.3],
                                       shortwave_scattering_asymmetry = [0.6])

        add_cloud_optical_depths!(longwave, shortwave, cloud)

        @test shortwave.rayleigh_optical_depth ≈ [0.5]
        @test shortwave.scattering_asymmetry ≈ [(0.2 * 0.1 + 0.3 * 0.6) / 0.5]
    end

    @testset "liquid/ice cloud optical properties with cloud fraction" begin
        cloud = CloudOpticalProperties(zeros(3), zeros(3))
        model = LayerLiquidIceCloudOpticsModel(
            liquid_water_path = [0.10, 0.20, 0.30],
            ice_water_path = [0.30, 0.20, 0.10],
            cloud_fraction = [1.0, 0.5, 0.0],
            liquid_longwave_mass_absorption = 2.0,
            ice_longwave_mass_absorption = 4.0,
            liquid_shortwave_mass_extinction = 5.0,
            ice_shortwave_mass_extinction = 7.0,
        )

        cloud_optical_properties!(cloud, model, (;))

        @test cloud.longwave_optical_depth ≈ [1.4, 0.6, 0.0]
        @test cloud.shortwave_optical_depth ≈ [2.6, 1.2, 0.0]
        @test cloud.shortwave_scattering_optical_depth ≈ [0.0, 0.0, 0.0]
    end

    @testset "liquid/ice cloud scattering partition" begin
        cloud = CloudOpticalProperties(zeros(2), zeros(2))
        model = LayerLiquidIceCloudOpticsModel(
            liquid_water_path = [0.10, 0.20],
            ice_water_path = [0.30, 0.20],
            cloud_fraction = [1.0, 0.5],
            liquid_longwave_mass_absorption = 2.0,
            ice_longwave_mass_absorption = 4.0,
            liquid_shortwave_mass_extinction = 5.0,
            ice_shortwave_mass_extinction = 7.0,
            liquid_shortwave_single_scattering_albedo = 0.8,
            ice_shortwave_single_scattering_albedo = 0.5,
            liquid_shortwave_scattering_asymmetry = 0.85,
            ice_shortwave_scattering_asymmetry = 0.75,
        )

        cloud_optical_properties!(cloud, model, (;))

        @test cloud.longwave_optical_depth ≈ [1.4, 0.6]
        @test cloud.shortwave_optical_depth ≈ [1.15, 0.45]
        @test cloud.shortwave_scattering_optical_depth ≈ [1.45, 0.75]
        @test cloud.shortwave_scattering_asymmetry ≈ [
            (0.85 * 0.4 + 0.75 * 1.05) / 1.45,
            (0.85 * 0.8 + 0.75 * 0.7) / 1.5,
        ]
    end

    @testset "liquid/ice cloud fraction exponent" begin
        cloud = CloudOpticalProperties(zeros(1), zeros(1))
        model = LayerLiquidIceCloudOpticsModel(
            liquid_water_path = [0.10],
            ice_water_path = [0.30],
            cloud_fraction = [0.25],
            liquid_longwave_mass_absorption = 2.0,
            ice_longwave_mass_absorption = 4.0,
            liquid_shortwave_mass_extinction = 5.0,
            ice_shortwave_mass_extinction = 7.0,
            cloud_fraction_exponent = 0.5,
        )

        cloud_optical_properties!(cloud, model, (;))

        @test cloud.longwave_optical_depth ≈ [0.5 * 1.4]
        @test cloud.shortwave_optical_depth ≈ [0.5 * 2.6]
    end

    @testset "cloudy-region liquid/ice optical properties keep cloud fraction separate" begin
        cloud = CloudyRegionCloudOpticalProperties(
            zeros(2),
            zeros(1),
            zeros(2),
            zeros(2),
            shortwave_scattering_optical_depth = zeros(2),
            shortwave_scattering_asymmetry = zeros(2),
        )
        model = LayerLiquidIceCloudOpticsModel(
            liquid_water_path = [0.10, 0.20],
            ice_water_path = [0.30, 0.20],
            cloud_fraction = [0.25, 0.50],
            liquid_longwave_mass_absorption = 2.0,
            ice_longwave_mass_absorption = 4.0,
            liquid_shortwave_mass_extinction = 5.0,
            ice_shortwave_mass_extinction = 7.0,
            liquid_shortwave_single_scattering_albedo = 0.8,
            ice_shortwave_single_scattering_albedo = 0.5,
            liquid_shortwave_scattering_asymmetry = 0.85,
            ice_shortwave_scattering_asymmetry = 0.75,
            cloud_fraction_exponent = 0.5,
        )
        atmosphere = (; overlap_parameter = [0.7])

        cloudy_region_optical_properties!(cloud, model, atmosphere)

        @test cloud.cloud_fraction ≈ [0.25, 0.50]
        @test cloud.overlap_parameter ≈ [0.7]
        @test cloud.longwave_optical_depth ≈ [1.4, 1.2]
        @test cloud.shortwave_optical_depth ≈ [1.15, 0.9]
        @test cloud.shortwave_scattering_optical_depth ≈ [1.45, 1.5]
        @test cloud.shortwave_scattering_asymmetry ≈ [
            (0.85 * 0.4 + 0.75 * 1.05) / 1.45,
            (0.85 * 0.8 + 0.75 * 0.7) / 1.5,
        ]
    end

    @testset "liquid/ice model reads atmosphere properties" begin
        cloud = CloudOpticalProperties(zeros(2), zeros(2))
        model = LayerLiquidIceCloudOpticsModel(
            liquid_water_path = 0.0,
            ice_water_path = 0.0,
            cloud_fraction = 0.0,
            liquid_longwave_mass_absorption = 1.0,
            ice_longwave_mass_absorption = 2.0,
            liquid_shortwave_mass_extinction = 3.0,
            ice_shortwave_mass_extinction = 4.0,
        )
        atmosphere = (;
            liquid_water_path = [0.1, 0.2],
            ice_water_path = [0.3, 0.4],
            cloud_fraction = [0.5, 1.0],
        )

        cloud_optical_properties!(cloud, model, atmosphere)

        @test cloud.longwave_optical_depth ≈ [0.35, 1.0]
        @test cloud.shortwave_optical_depth ≈ [0.75, 2.2]
    end

    @testset "absorptive all-sky shortwave reduces surface flux" begin
        nlayers = 2
        clear_fluxes = RadiativeFluxes(
            longwave_up = zeros(nlayers + 1),
            longwave_down = zeros(nlayers + 1),
            shortwave_up = zeros(nlayers + 1),
            shortwave_down = zeros(nlayers + 1),
        )
        cloudy_fluxes = RadiativeFluxes(
            longwave_up = zeros(nlayers + 1),
            longwave_down = zeros(nlayers + 1),
            shortwave_up = zeros(nlayers + 1),
            shortwave_down = zeros(nlayers + 1),
        )
        clear_shortwave = ShortwaveOpticalProperties(zeros(nlayers))
        cloudy_shortwave = ShortwaveOpticalProperties(zeros(nlayers))
        longwave = LongwaveOpticalProperties(zeros(nlayers), zeros(nlayers))
        cloud = CloudOpticalProperties(zeros(nlayers), [log(2.0), 0.0])
        boundary = ShortwaveBoundaryConditions(toa_shortwave_down = 400.0,
                                               surface_albedo = 0.0)

        add_cloud_optical_depths!(longwave, cloudy_shortwave, cloud)
        radiative_fluxes!(clear_fluxes, CloudlessShortwave(), clear_shortwave, nothing, boundary)
        radiative_fluxes!(cloudy_fluxes, CloudlessShortwave(), cloudy_shortwave, nothing, boundary)

        @test clear_fluxes.shortwave_down[end] == 400.0
        @test cloudy_fluxes.shortwave_down[end] ≈ 200.0
    end

    @testset "mapped cloud scattering composition" begin
        shortwave = ShortwaveOpticalProperties(zeros(2, 2);
                                               scattering_optical_depth = zeros(2, 2),
                                               scattering_asymmetry = zeros(2, 2))
        liquid = (
            mass_extinction_coefficient = [10.0, 20.0],
            single_scattering_albedo = [0.8, 0.5],
            asymmetry_factor = [0.7, 0.6],
        )
        ice = (
            mass_extinction_coefficient = [30.0, 40.0],
            single_scattering_albedo = [0.6, 0.25],
            asymmetry_factor = [0.5, 0.4],
        )

        add_mapped_cloud_scattering!(shortwave, liquid, ice,
                                     [0.1, 0.0], [0.0, 0.2], [1.0, 0.5])

        @test shortwave.optical_depth[:, 1] ≈ [0.2, 1.0]
        @test shortwave.rayleigh_optical_depth[:, 1] ≈ [0.8, 1.0]
        @test shortwave.scattering_asymmetry[:, 1] ≈ [0.7, 0.6]
        @test shortwave.optical_depth[:, 2] ≈ [1.2, 3.0]
        @test shortwave.rayleigh_optical_depth[:, 2] ≈ [1.8, 1.0]
        @test shortwave.scattering_asymmetry[:, 2] ≈ [0.5, 0.4]

        scaled = ShortwaveOpticalProperties(zeros(2, 1);
                                            scattering_optical_depth = zeros(2, 1),
                                            scattering_asymmetry = zeros(2, 1))
        add_mapped_cloud_scattering!(scaled, liquid, ice,
                                     [0.1], [0.0], [1.0];
                                     liquid_extinction_scale = 2.0)
        @test scaled.optical_depth[:, 1] ≈ [0.4, 2.0]
        @test scaled.rayleigh_optical_depth[:, 1] ≈ [1.6, 2.0]

        delta_scaled = ShortwaveOpticalProperties(zeros(1, 1);
                                                  scattering_optical_depth = zeros(1, 1),
                                                  scattering_asymmetry = zeros(1, 1))
        add_mapped_cloud_scattering!(
            delta_scaled,
            (mass_extinction_coefficient = [10.0],
             single_scattering_albedo = [0.8],
             asymmetry_factor = [0.7]),
            (mass_extinction_coefficient = [0.0],
             single_scattering_albedo = [0.0],
             asymmetry_factor = [0.0]),
            [0.1],
            [0.0],
            [1.0];
            delta_eddington_scale = true,
        )
        @test delta_scaled.optical_depth[1, 1] ≈ 0.2
        @test delta_scaled.rayleigh_optical_depth[1, 1] ≈ 0.8 * (1 - 0.7^2)
        @test delta_scaled.scattering_asymmetry[1, 1] ≈ 0.7 / 1.7
    end
end

@testset "Layer aerosol optics" begin
    @testset "aerosol optical properties" begin
        aerosol = AerosolOpticalProperties(zeros(3), zeros(3))
        model = LayerAerosolOpticsModel(aerosol_path = [0.0, 0.02, 0.04],
                                        longwave_mass_absorption = 1.5,
                                        shortwave_mass_extinction = 4.0)

        aerosol_optical_properties!(aerosol, model, (;))

        @test aerosol.longwave_optical_depth == [0.0, 0.03, 0.06]
        @test aerosol.shortwave_optical_depth == [0.0, 0.08, 0.16]
        @test aerosol.shortwave_scattering_optical_depth == [0.0, 0.0, 0.0]
        @test aerosol.shortwave_scattering_asymmetry == [0.0, 0.0, 0.0]
    end

    @testset "aerosol shortwave scattering partition" begin
        aerosol = AerosolOpticalProperties(zeros(2), zeros(2))
        model = LayerAerosolOpticsModel(aerosol_path = [0.02, 0.04],
                                        longwave_mass_absorption = 1.5,
                                        shortwave_mass_extinction = 4.0,
                                        shortwave_single_scattering_albedo = 0.75,
                                        shortwave_scattering_asymmetry = 0.65)

        aerosol_optical_properties!(aerosol, model, (;))

        @test aerosol.longwave_optical_depth ≈ [0.03, 0.06]
        @test aerosol.shortwave_optical_depth ≈ [0.02, 0.04]
        @test aerosol.shortwave_scattering_optical_depth ≈ [0.06, 0.12]
        @test aerosol.shortwave_scattering_asymmetry ≈ [0.65, 0.65]
    end

    @testset "add aerosol optical depths to gas optics" begin
        longwave = LongwaveOpticalProperties([0.1, 0.2], [50.0, 60.0])
        shortwave = ShortwaveOpticalProperties([0.01, 0.02])
        aerosol = AerosolOpticalProperties([0.03, 0.04], [0.05, 0.06];
                                           shortwave_scattering_optical_depth = [0.01, 0.02],
                                           shortwave_scattering_asymmetry = [0.3, 0.4])

        add_aerosol_optical_depths!(longwave, shortwave, aerosol)

        @test longwave.optical_depth ≈ [0.13, 0.24]
        @test shortwave.optical_depth ≈ [0.06, 0.08]
        @test shortwave.rayleigh_optical_depth ≈ [0.01, 0.02]
        @test shortwave.scattering_asymmetry ≈ [0.3, 0.4]
    end

    @testset "absorptive gas cloud aerosol composition" begin
        longwave = LongwaveOpticalProperties([0.1, 0.2], [50.0, 60.0])
        shortwave = ShortwaveOpticalProperties([0.01, 0.02])
        cloud = CloudOpticalProperties([0.3, 0.4], [0.5, 0.6])
        aerosol = AerosolOpticalProperties([0.03, 0.04], [0.05, 0.06])

        add_cloud_optical_depths!(longwave, shortwave, cloud)
        add_aerosol_optical_depths!(longwave, shortwave, aerosol)

        @test longwave.optical_depth ≈ [0.43, 0.64]
        @test shortwave.optical_depth ≈ [0.56, 0.68]
        @test shortwave.rayleigh_optical_depth ≈ [0.0, 0.0]
    end
end
# --- end content of test_cloud_optics.jl ---

end # module TestCloudOptics

module TestCloudScatteringTable
using Test
using NumericalRadiation
using Dates

# --- begin content of test_cloud_scattering_table.jl ---
using NCDatasets

@testset "cloud scattering table" begin
    table = CloudScatteringTable(
        medium = "liquid-water",
        particle_type = "droplet",
        wavenumber = [100.0, 200.0],
        effective_radius = [1.0e-6, 3.0e-6],
        mass_extinction_coefficient = [10.0 30.0; 20.0 40.0],
        single_scattering_albedo = [0.8 1.0; 0.6 0.9],
        asymmetry_factor = [0.7 0.9; 0.5 0.8],
    )

    @test eltype(table) == Float64
    @test table.medium == "liquid-water"
    props = cloud_scattering_properties(table, 1, 2.0e-6)
    @test props.mass_extinction_coefficient ≈ 20.0
    @test props.single_scattering_albedo ≈ 0.9
    @test props.asymmetry_factor ≈ 0.8

    low = cloud_scattering_properties(table, 2, 0.1e-6)
    high = cloud_scattering_properties(table, 2, 10.0e-6)
    @test low.mass_extinction_coefficient ≈ 20.0
    @test high.mass_extinction_coefficient ≈ 40.0
end

@testset "cloud scattering g-point mapping" begin
    table = CloudScatteringTable(
        medium = "liquid-water",
        particle_type = "droplet",
        wavenumber = [100.0, 200.0, 300.0],
        effective_radius = [1.0e-6, 3.0e-6],
        mass_extinction_coefficient = [10.0 20.0; 30.0 40.0; 50.0 60.0],
        single_scattering_albedo = fill(0.8, 3, 2),
        asymmetry_factor = fill(0.5, 3, 2),
    )
    mapping = EcCKDSpectralMapping(
        wavenumber1 = [90.0, 190.0, 290.0],
        wavenumber2 = [110.0, 210.0, 310.0],
        gpoint_fraction = [1.0 0.0; 0.5 0.5; 0.0 1.0],
    )

    props = cloud_scattering_gpoint_properties(table, mapping, 1.0e-6)
    @test length(props.mass_extinction_coefficient) == 2
    @test props.mass_extinction_coefficient[1] ≈ (10.0 + 0.5 * 30.0) / 1.5
    @test props.mass_extinction_coefficient[2] ≈ (0.5 * 30.0 + 50.0) / 1.5
    @test all(props.single_scattering_albedo .≈ 0.8)
    @test all(props.asymmetry_factor .≈ 0.5)

    thick_table = CloudScatteringTable(
        medium = "liquid-water",
        particle_type = "droplet",
        wavenumber = [100.0, 200.0, 300.0],
        effective_radius = [1.0e-6, 3.0e-6],
        mass_extinction_coefficient = [10.0 20.0; 30.0 40.0; 50.0 60.0],
        single_scattering_albedo = [0.95 0.9; 0.7 0.8; 0.4 0.5],
        asymmetry_factor = [0.85 0.8; 0.6 0.65; 0.3 0.4],
    )
    thick = cloud_scattering_gpoint_properties(
        thick_table, mapping, 1.0e-6;
        mapping_method = :ecrad,
        delta_eddington_average = true,
        thick_averaging = true,
    )
    thin = cloud_scattering_gpoint_properties(
        thick_table, mapping, 1.0e-6;
        mapping_method = :ecrad,
        delta_eddington_average = true,
        thick_averaging = false,
    )
    @test length(thick.single_scattering_albedo) == 2
    @test all(0 .<= thick.single_scattering_albedo .<= 1)
    @test thick.single_scattering_albedo != thin.single_scattering_albedo
end

@testset "NCDatasets cloud scattering table reader" begin
    path = tempname() * ".nc"
    NCDataset(path, "c") do ds
        defDim(ds, "wavenumber", 2)
        defDim(ds, "effective_radius", 3)
        ds.attrib["medium"] = "ice"
        ds.attrib["particle_type"] = "cloud-ice"
        wavenumber = defVar(ds, "wavenumber", Float64, ("wavenumber",))
        radius = defVar(ds, "effective_radius", Float64, ("effective_radius",))
        mass_ext = defVar(ds, "mass_extinction_coefficient", Float64,
                          ("wavenumber", "effective_radius"))
        ssa = defVar(ds, "single_scattering_albedo", Float64,
                     ("wavenumber", "effective_radius"))
        asymmetry = defVar(ds, "asymmetry_factor", Float64,
                           ("wavenumber", "effective_radius"))
        wavenumber[:] = [100.0, 200.0]
        radius[:] = [1.0e-6, 2.0e-6, 3.0e-6]
        mass_ext[:, :] = [10.0 20.0 30.0; 40.0 50.0 60.0]
        ssa[:, :] = fill(0.9, 2, 3)
        asymmetry[:, :] = fill(0.7, 2, 3)
    end

    table = read_cloud_scattering_table(path)
    @test table isa CloudScatteringTable
    @test table.medium == "ice"
    @test table.particle_type == "cloud-ice"
    @test table.wavenumber == [100.0, 200.0]
    @test table.effective_radius == [1.0e-6, 2.0e-6, 3.0e-6]
    @test table.mass_extinction_coefficient[2, 3] == 60.0
end

@testset "NCDatasets ecCKD spectral mapping reader" begin
    path = tempname() * ".nc"
    NCDataset(path, "c") do ds
        defDim(ds, "wavenumber", 2)
        defDim(ds, "g_point", 3)
        w1 = defVar(ds, "wavenumber1", Float64, ("wavenumber",))
        w2 = defVar(ds, "wavenumber2", Float64, ("wavenumber",))
        frac = defVar(ds, "gpoint_fraction", Float64, ("wavenumber", "g_point"))
        w1[:] = [100.0, 200.0]
        w2[:] = [150.0, 250.0]
        frac[:, :] = [1.0 0.0 0.0; 0.0 0.25 0.75]
    end

    mapping = read_ecckd_spectral_mapping(path)
    @test mapping isa EcCKDSpectralMapping
    @test mapping.wavenumber1 == [100.0, 200.0]
    @test mapping.wavenumber2 == [150.0, 250.0]
    @test size(mapping.gpoint_fraction) == (2, 3)
    @test mapping.interval_weight == [1.0, 1.0]
end

@testset "official ecRad cloud scattering files" begin
    # Resolve through the package's official-data path (RH_ECRAD_DATA_PATH,
    # the lazy ecrad_data artifact, or a local checkout).
    liquid_path = NumericalRadiation._ecrad_data_file("mie_droplet_scattering.nc";
                                                      require = false)
    ice_path = NumericalRadiation._ecrad_data_file(
        "baum-general-habit-mixture_ice_scattering.nc"; require = false)

    if liquid_path !== nothing && ice_path !== nothing
        liquid = read_cloud_scattering_table(liquid_path)
        ice = read_cloud_scattering_table(ice_path)
        @test liquid.medium == "liquid-water"
        @test ice.medium == "ice"
        @test size(liquid.mass_extinction_coefficient) ==
              (length(liquid.wavenumber), length(liquid.effective_radius))
        @test size(ice.mass_extinction_coefficient) ==
              (length(ice.wavenumber), length(ice.effective_radius))
        @test minimum(liquid.mass_extinction_coefficient) >= 0
        @test minimum(ice.mass_extinction_coefficient) >= 0
        @test all(0 .<= liquid.single_scattering_albedo .<= 1)
        @test all(0 .<= ice.single_scattering_albedo .<= 1)
        @test all(-1 .<= liquid.asymmetry_factor .<= 1)
        @test all(-1 .<= ice.asymmetry_factor .<= 1)

        sw_mapping = read_ecckd_spectral_mapping(
            official_ecckd_definition_path("ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc"))
        liquid_gpoints = cloud_scattering_gpoint_properties(liquid, sw_mapping, 10.0e-6)
        ice_gpoints = cloud_scattering_gpoint_properties(ice, sw_mapping, 30.0e-6)
        liquid_ecrad_gpoints = cloud_scattering_gpoint_properties(
            liquid, sw_mapping, 10.0e-6;
            mapping_method = :ecrad,
            delta_eddington_average = true,
        )
        @test length(liquid_gpoints.mass_extinction_coefficient) == 32
        @test length(ice_gpoints.mass_extinction_coefficient) == 32
        @test length(liquid_ecrad_gpoints.mass_extinction_coefficient) == 32
        @test minimum(liquid_gpoints.mass_extinction_coefficient) >= 0
        @test minimum(ice_gpoints.mass_extinction_coefficient) >= 0
        @test minimum(liquid_ecrad_gpoints.mass_extinction_coefficient) >= 0
        @test all(0 .<= liquid_gpoints.single_scattering_albedo .<= 1)
        @test all(0 .<= ice_gpoints.single_scattering_albedo .<= 1)
        @test all(0 .<= liquid_ecrad_gpoints.single_scattering_albedo .<= 1)
    else
        @info "Skipping official cloud scattering table check; ecRad data files are not present" liquid_path ice_path
        @test_skip "official cloud scattering table files are not present"
    end
end
# --- end content of test_cloud_scattering_table.jl ---

end # module TestCloudScatteringTable
