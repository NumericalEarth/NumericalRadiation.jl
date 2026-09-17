using Test
using NumericalRadiation
using NCDatasets   # extension trigger, with ClimaComms + RRTMGP
using RRTMGP
using ClimaComms

# Canonical RRTMGP-adapter reference tests. These pin the two contract
# properties a finiteness check cannot see:
#
# 1. COLUMN AMOUNTS: RRTMGP's compute_col_gas_kernel! (optics/gas_optics.jl)
#    defines `vmr_h2o` (the water-vapor mole fraction) relative to DRY air and
#    divides the hydrostatic Δp by the moist molar mass
#    `m_air = molmass_dryair + molmass_water * vmr_h2o`.
#    The adapter must fill `layerdata[1, :, :]` (col_dry) with exactly that
#    convention, not a (1 - χ_H₂O) mass-fraction approximation.
#
# 2. ORIENTATION: RRTMGP's two-stream kernels are bottom-at-index-1 (surface
#    source/albedo at level 1; longwave2stream.jl), while ColumnAtmosphere is
#    top-down by contract. The adapter must reverse the vertical index on
#    ingest and reverse fluxes back on egress.

const EXT = Base.get_extension(NumericalRadiation, :NumericalRadiationRRTMGPExt)
const SOLAR_CONSTANT = PhysicalConstants().solar_constant

@testset "RRTMGP adapter reference" begin
    FT = Float64
    Nz = 4
    pressure_interfaces = [10_000.0, 30_000.0, 55_000.0, 80_000.0, 100_000.0]
    pressure_layers = (pressure_interfaces[1:end-1] .+ pressure_interfaces[2:end]) ./ 2
    temperature_interfaces = [210.0, 235.0, 260.0, 285.0, 300.0]
    temperature_layers = (temperature_interfaces[1:end-1] .+ temperature_interfaces[2:end]) ./ 2
    # Distinct, humid per-layer water-vapor mole fractions so both the index
    # reversal and the moist-molar-mass difference are individually detectable.
    water_vapor = [1e-4, 8e-4, 3e-3, 2e-2]
    atmosphere = ColumnAtmosphere(
        pressure_layers = pressure_layers,
        pressure_interfaces = pressure_interfaces,
        temperature_layers = temperature_layers,
        temperature_interfaces = temperature_interfaces,
        gases = (h2o = water_vapor, o3 = [1e-8, 2e-8, 3e-8, 4e-8], co2 = 400e-6),
        surface = (;),
        geometry = (;),
    )
    model = EXT.RRTMGPClearSkyModel(FT)
    boundary = EXT.RRTMGPBoundaryConditions(surface_temperature = 300.0,
                                            surface_emissivity = 0.98,
                                            surface_albedo = 0.1,
                                            toa_shortwave_down = SOLAR_CONSTANT,
                                            cos_zenith = 0.5)
    workspace = radiation_workspace(model, atmosphere)
    EXT.fill_atmospheric_state!(workspace, model, atmosphere, boundary)
    state = workspace.atmospheric_state

    @testset "RRTMGP parameters come from PhysicalConstants" begin
        constants = PhysicalConstants(FT)
        params = model.parameters
        @test params.grav == constants.gravity
        @test params.molmass_dryair == constants.dry_air_molar_mass
        @test params.molmass_water == constants.water_molar_mass
        @test params.gas_constant == constants.universal_gas_constant
        @test params.kappa_d == constants.dry_air_gas_constant / constants.heat_capacity
        @test params.Stefan == constants.stefan_boltzmann
        @test params.avogad == constants.avogadro_number
        # A host's own constants propagate into the adapter.
        heavy = PhysicalConstants(FT; gravity = 2 * constants.gravity)
        @test EXT.RRTMGPClearSkyModel(FT; constants = heavy).parameters.grav == heavy.gravity
        # Without a leading element type the adapter defaults to Float64.
        default_model = EXT.RRTMGPClearSkyModel()
        @test default_model isa EXT.RRTMGPClearSkyModel{Float64}
        @test default_model.parameters == params
        @test EXT.RRTMGPClearSkyModel(; constants = heavy).parameters.grav == heavy.gravity
    end

    @testset "orientation: ingest is bottom-at-index-1" begin
        # Level arrays: RRTMGP index 1 must hold the SURFACE values.
        @test state.p_lev[1, 1] == 100_000.0
        @test state.p_lev[end, 1] == 10_000.0
        @test state.t_lev[1, 1] == 300.0
        @test state.t_lev[end, 1] == 210.0
        # Layer arrays: our layer k lands at RRTMGP layer Nz - k + 1.
        for k in 1:Nz
            k_reversed = Nz - k + 1
            @test state.layerdata[2, k_reversed, 1] == pressure_layers[k]
            @test state.layerdata[3, k_reversed, 1] == temperature_layers[k]
            @test state.vmr.vmr_h2o[k_reversed, 1] == water_vapor[k]
            @test state.vmr.vmr_o3[k_reversed, 1] == atmosphere.gases.o3[k]
        end
    end

    @testset "column amounts: RRTMGP dry-air mole-fraction convention" begin
        params = model.parameters
        for k in 1:Nz
            k_reversed = Nz - k + 1
            Δp = pressure_interfaces[k + 1] - pressure_interfaces[k]
            m_air = params.molmass_dryair + params.molmass_water * water_vapor[k]
            expected = Δp * params.avogad / (1e4 * m_air * params.grav)
            @test state.layerdata[1, k_reversed, 1] ≈ expected rtol = 1e-12
            # Guard against regressing to the (1 - χ_H₂O) mass-fraction form:
            # for the humid bottom layer the two formulas differ materially.
            wrong = (Δp / params.grav) * (1 - water_vapor[k]) /
                    params.molmass_dryair * params.avogad / 1e4
            if water_vapor[k] >= 1e-2
                @test abs(state.layerdata[1, k_reversed, 1] - wrong) / expected > 5e-3
            end
        end
    end

    # One adapter solve, reused by the canonical comparison and the endpoint
    # diagnostics below (no redundant workspace construction or solves).
    adapter_fluxes = RadiativeFluxes(longwave_up = zeros(Nz + 1),
                                     longwave_down = zeros(Nz + 1),
                                     shortwave_up = zeros(Nz + 1),
                                     shortwave_down = zeros(Nz + 1))
    radiative_fluxes!(adapter_fluxes, model, atmosphere, boundary, workspace)

    @testset "canonical bottom-up solve matches the public adapter" begin
        # Independently populate a second workspace CANONICALLY (bottom-up,
        # by hand, without fill_atmospheric_state!), solve with RRTMGP
        # directly, and require the public adapter to reproduce it after
        # reversal. This is the like-for-like acceptance the finiteness
        # test cannot provide.
        canonical = radiation_workspace(model, atmosphere)
        canonical_state = canonical.atmospheric_state
        params = model.parameters
        for k_reversed in 1:Nz                       # k_reversed: 1 = bottom (canonical)
            k = Nz - k_reversed + 1                  # our top-down index
            canonical_state.layerdata[2, k_reversed, 1] = pressure_layers[k]
            canonical_state.layerdata[3, k_reversed, 1] = temperature_layers[k]
            canonical_state.layerdata[4, k_reversed, 1] = 0.0
            canonical_state.vmr.vmr_h2o[k_reversed, 1] = water_vapor[k]
            canonical_state.vmr.vmr_o3[k_reversed, 1] = atmosphere.gases.o3[k]
            Δp = pressure_interfaces[k + 1] - pressure_interfaces[k]
            m_air = params.molmass_dryair + params.molmass_water * water_vapor[k]
            canonical_state.layerdata[1, k_reversed, 1] = Δp * params.avogad /
                                         (1e4 * m_air * params.grav)
        end
        for k_reversed in 1:(Nz + 1)
            k = Nz + 2 - k_reversed
            canonical_state.p_lev[k_reversed, 1] = pressure_interfaces[k]
            canonical_state.t_lev[k_reversed, 1] = temperature_interfaces[k]
        end
        canonical_state.t_sfc[1] = 300.0
        mole_fractions = canonical_state.vmr.vmr
        fill!(mole_fractions, 0.0)
        gas_indices = canonical.solver.lookups.idx_gases_sw
        haskey(gas_indices, "co2") && (mole_fractions[gas_indices["co2"]] = 400e-6)
        haskey(gas_indices, "ch4") && (mole_fractions[gas_indices["ch4"]] = 1.8e-6)
        haskey(gas_indices, "n2o") && (mole_fractions[gas_indices["n2o"]] = 330e-9)
        haskey(gas_indices, "o2") && (mole_fractions[gas_indices["o2"]] = 0.20946)
        haskey(gas_indices, "n2") && (mole_fractions[gas_indices["n2"]] = 0.78084)
        haskey(gas_indices, "co") && (mole_fractions[gas_indices["co"]] = 0.0)
        canonical.solver.lws.bcs.sfc_emis .= 0.98
        canonical.solver.sws.bcs.cos_zenith .= 0.5
        canonical.solver.sws.bcs.toa_flux .= SOLAR_CONSTANT
        canonical.solver.sws.bcs.sfc_alb_direct .= 0.1
        canonical.solver.sws.bcs.sfc_alb_diffuse .= 0.1
        RRTMGP.update_lw_fluxes!(canonical.solver)
        RRTMGP.update_sw_fluxes!(canonical.solver)
        canonical_lw_up = RRTMGP.lw_flux_up(canonical.solver)
        canonical_lw_dn = RRTMGP.lw_flux_dn(canonical.solver)
        canonical_sw_up = RRTMGP.sw_flux_up(canonical.solver)
        canonical_sw_dn = RRTMGP.sw_flux_dn(canonical.solver)

        for k in 1:(Nz + 1)
            k_reversed = Nz + 2 - k
            @test adapter_fluxes.longwave_up[k] ≈ canonical_lw_up[k_reversed, 1] rtol = 1e-10
            @test adapter_fluxes.longwave_down[k] ≈ canonical_lw_dn[k_reversed, 1] rtol = 1e-10
            @test adapter_fluxes.shortwave_up[k] ≈ canonical_sw_up[k_reversed, 1] rtol = 1e-10
            @test adapter_fluxes.shortwave_down[k] ≈ canonical_sw_dn[k_reversed, 1] rtol = 1e-10
        end
    end

    @testset "orientation: endpoint diagnostics are top-down" begin
        σ = model.parameters.Stefan
        # Downwelling longwave must vanish at TOA (index 1, top-down) and be
        # substantial at the surface; a flipped adapter reverses this.
        @test adapter_fluxes.longwave_down[1] < 5.0
        @test adapter_fluxes.longwave_down[end] > 100.0
        # Upwelling at the surface is boundary emission plus reflection.
        surface_up = 0.98 * σ * 300.0^4 + (1 - 0.98) * adapter_fluxes.longwave_down[end]
        @test isapprox(adapter_fluxes.longwave_up[end], surface_up; rtol = 2e-2)
        # OLR is positive and below the surface blackbody value.
        @test 0 < adapter_fluxes.longwave_up[1] < σ * 300.0^4
        # Shortwave: TOA downwelling equals the prescribed incident beam and
        # is attenuated (never amplified) toward the surface.
        @test isapprox(adapter_fluxes.shortwave_down[1], SOLAR_CONSTANT * 0.5; rtol = 1e-6)
        @test adapter_fluxes.shortwave_down[end] <= adapter_fluxes.shortwave_down[1]
        @test all(isfinite, adapter_fluxes.longwave_up)
        @test all(isfinite, adapter_fluxes.longwave_down)
        @test all(isfinite, adapter_fluxes.shortwave_up)
        @test all(isfinite, adapter_fluxes.shortwave_down)
    end

    @testset "malformed non-first output buffer throws before solving" begin
        bad = RadiativeFluxes(longwave_up = zeros(Nz + 1),
                              longwave_down = zeros(Nz + 1),
                              shortwave_up = zeros(Nz + 1),
                              shortwave_down = zeros(Nz))    # wrong length
        # Sentinel: fill_atmospheric_state! would overwrite t_sfc, so it
        # surviving as NaN proves the guard fired before any state fill.
        workspace.atmospheric_state.t_sfc[1] = NaN
        @test_throws DimensionMismatch radiative_fluxes!(
            bad, model, atmosphere, boundary, workspace)
        @test isnan(workspace.atmospheric_state.t_sfc[1])
    end
end
