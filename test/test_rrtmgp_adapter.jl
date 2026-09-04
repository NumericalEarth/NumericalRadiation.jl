using Test
using NumericalRadiation
using NCDatasets   # extension trigger, with ClimaComms + RRTMGP
using RRTMGP
using ClimaComms

# Canonical RRTMGP-adapter reference tests. These pin the two contract
# properties a finiteness check cannot see:
#
# 1. COLUMN AMOUNTS: RRTMGP's compute_col_gas_kernel! (optics/gas_optics.jl)
#    defines vmr_h2o relative to DRY air and divides the hydrostatic Δp by
#    the moist molar mass m_air = molmass_dryair + molmass_water * vmr_h2o.
#    The adapter must fill `layerdata[1, :, :]` (col_dry) with exactly that
#    convention, not a (1 - h2o) mass-fraction approximation.
#
# 2. ORIENTATION: RRTMGP's two-stream kernels are bottom-at-index-1 (surface
#    source/albedo at level 1; longwave2stream.jl), while ColumnAtmosphere is
#    top-down by contract. The adapter must reverse the vertical index on
#    ingest and reverse fluxes back on egress.

const EXT = Base.get_extension(NumericalRadiation, :NumericalRadiationRRTMGPExt)

@testset "RRTMGP adapter reference" begin
    FT = Float64
    nlayers = 4
    pressure_interfaces = [10_000.0, 30_000.0, 55_000.0, 80_000.0, 100_000.0]
    pressure_layers = (pressure_interfaces[1:end-1] .+ pressure_interfaces[2:end]) ./ 2
    temperature_interfaces = [210.0, 235.0, 260.0, 285.0, 300.0]
    temperature_layers = (temperature_interfaces[1:end-1] .+ temperature_interfaces[2:end]) ./ 2
    # Distinct, humid per-layer h2o VMR values so both the index reversal and
    # the moist-molar-mass difference are individually detectable.
    h2o = [1e-4, 8e-4, 3e-3, 2e-2]
    atmosphere = ColumnAtmosphere(
        pressure_layers = pressure_layers,
        pressure_interfaces = pressure_interfaces,
        temperature_layers = temperature_layers,
        temperature_interfaces = temperature_interfaces,
        gases = (h2o = h2o, o3 = [1e-8, 2e-8, 3e-8, 4e-8], co2 = 400e-6),
        surface = (;),
        geometry = (;),
    )
    model = EXT.RRTMGPClearSkyModel(FT)
    boundary = EXT.RRTMGPBoundaryConditions(surface_temperature = 300.0,
                                            surface_emissivity = 0.98,
                                            surface_albedo = 0.1,
                                            toa_shortwave_down = 1361.0,
                                            cos_zenith = 0.5)
    workspace = radiation_workspace(model, atmosphere)
    EXT.fill_atmospheric_state!(workspace, model, atmosphere, boundary)
    state = workspace.atmospheric_state

    @testset "orientation: ingest is bottom-at-index-1" begin
        # Level arrays: RRTMGP index 1 must hold the SURFACE values.
        @test state.p_lev[1, 1] == 100_000.0
        @test state.p_lev[end, 1] == 10_000.0
        @test state.t_lev[1, 1] == 300.0
        @test state.t_lev[end, 1] == 210.0
        # Layer arrays: our layer k lands at RRTMGP layer nlayers - k + 1.
        for k in 1:nlayers
            kr = nlayers - k + 1
            @test state.layerdata[2, kr, 1] == pressure_layers[k]
            @test state.layerdata[3, kr, 1] == temperature_layers[k]
            @test state.vmr.vmr_h2o[kr, 1] == h2o[k]
            @test state.vmr.vmr_o3[kr, 1] == atmosphere.gases.o3[k]
        end
    end

    @testset "column amounts: RRTMGP dry-air-VMR convention" begin
        params = model.parameters
        for k in 1:nlayers
            kr = nlayers - k + 1
            Δp = pressure_interfaces[k + 1] - pressure_interfaces[k]
            m_air = params.molmass_dryair + params.molmass_water * h2o[k]
            expected = Δp * params.avogad / (1e4 * m_air * params.grav)
            @test state.layerdata[1, kr, 1] ≈ expected rtol = 1e-12
            # Guard against regressing to the (1 - h2o) mass-fraction form:
            # for the humid bottom layer the two formulas differ materially.
            wrong = (Δp / params.grav) * (1 - h2o[k]) /
                    params.molmass_dryair * params.avogad / 1e4
            if h2o[k] >= 1e-2
                @test abs(state.layerdata[1, kr, 1] - wrong) / expected > 5e-3
            end
        end
    end

    # One adapter solve, reused by the canonical comparison and the endpoint
    # diagnostics below (no redundant workspace construction or solves).
    adapter_fluxes = RadiativeFluxes(longwave_up = zeros(nlayers + 1),
                                     longwave_down = zeros(nlayers + 1),
                                     shortwave_up = zeros(nlayers + 1),
                                     shortwave_down = zeros(nlayers + 1))
    radiative_fluxes!(adapter_fluxes, model, atmosphere, boundary, workspace)

    @testset "canonical bottom-up solve matches the public adapter" begin
        # Independently populate a second workspace CANONICALLY (bottom-up,
        # by hand, without fill_atmospheric_state!), solve with RRTMGP
        # directly, and require the public adapter to reproduce it after
        # reversal. This is the like-for-like acceptance the finiteness
        # test cannot provide.
        canonical = radiation_workspace(model, atmosphere)
        cstate = canonical.atmospheric_state
        params = model.parameters
        for kr in 1:nlayers                       # kr: 1 = bottom (canonical)
            k = nlayers - kr + 1                  # our top-down index
            cstate.layerdata[2, kr, 1] = pressure_layers[k]
            cstate.layerdata[3, kr, 1] = temperature_layers[k]
            cstate.layerdata[4, kr, 1] = 0.0
            cstate.vmr.vmr_h2o[kr, 1] = h2o[k]
            cstate.vmr.vmr_o3[kr, 1] = atmosphere.gases.o3[k]
            Δp = pressure_interfaces[k + 1] - pressure_interfaces[k]
            m_air = params.molmass_dryair + params.molmass_water * h2o[k]
            cstate.layerdata[1, kr, 1] = Δp * params.avogad /
                                         (1e4 * m_air * params.grav)
        end
        for kr in 1:(nlayers + 1)
            k = nlayers + 2 - kr
            cstate.p_lev[kr, 1] = pressure_interfaces[k]
            cstate.t_lev[kr, 1] = temperature_interfaces[k]
        end
        cstate.t_sfc[1] = 300.0
        cvmr = cstate.vmr.vmr
        fill!(cvmr, 0.0)
        gas_indices = canonical.solver.lookups.lookups.idx_gases_sw
        haskey(gas_indices, "co2") && (cvmr[gas_indices["co2"]] = 400e-6)
        haskey(gas_indices, "ch4") && (cvmr[gas_indices["ch4"]] = 1.8e-6)
        haskey(gas_indices, "n2o") && (cvmr[gas_indices["n2o"]] = 330e-9)
        haskey(gas_indices, "o2") && (cvmr[gas_indices["o2"]] = 0.20946)
        haskey(gas_indices, "n2") && (cvmr[gas_indices["n2"]] = 0.78084)
        haskey(gas_indices, "co") && (cvmr[gas_indices["co"]] = 0.0)
        canonical.solver.lws.bcs.sfc_emis .= 0.98
        canonical.solver.sws.bcs.cos_zenith .= 0.5
        canonical.solver.sws.bcs.toa_flux .= 1361.0
        canonical.solver.sws.bcs.sfc_alb_direct .= 0.1
        canonical.solver.sws.bcs.sfc_alb_diffuse .= 0.1
        Base.invokelatest(RRTMGP.update_lw_fluxes!, canonical.solver)
        Base.invokelatest(RRTMGP.update_sw_fluxes!, canonical.solver)

        for k in 1:(nlayers + 1)
            kr = nlayers + 2 - k
            @test adapter_fluxes.longwave_up[k] ≈
                  canonical.solver.lws.flux.flux_up[kr, 1] rtol = 1e-10
            @test adapter_fluxes.longwave_down[k] ≈
                  canonical.solver.lws.flux.flux_dn[kr, 1] rtol = 1e-10
            @test adapter_fluxes.shortwave_up[k] ≈
                  canonical.solver.sws.flux.flux_up[kr, 1] rtol = 1e-10
            @test adapter_fluxes.shortwave_down[k] ≈
                  canonical.solver.sws.flux.flux_dn[kr, 1] rtol = 1e-10
        end
    end

    @testset "orientation: endpoint diagnostics are top-down" begin
        σ = 5.670374419e-8
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
        @test isapprox(adapter_fluxes.shortwave_down[1], 1361.0 * 0.5; rtol = 1e-6)
        @test adapter_fluxes.shortwave_down[end] <= adapter_fluxes.shortwave_down[1]
        @test all(isfinite, adapter_fluxes.longwave_up)
        @test all(isfinite, adapter_fluxes.longwave_down)
        @test all(isfinite, adapter_fluxes.shortwave_up)
        @test all(isfinite, adapter_fluxes.shortwave_down)
    end

    @testset "malformed non-first output buffer throws before solving" begin
        bad = RadiativeFluxes(longwave_up = zeros(nlayers + 1),
                              longwave_down = zeros(nlayers + 1),
                              shortwave_up = zeros(nlayers + 1),
                              shortwave_down = zeros(nlayers))    # wrong length
        # Sentinel: fill_atmospheric_state! would overwrite t_sfc, so it
        # surviving as NaN proves the guard fired before any state fill.
        workspace.atmospheric_state.t_sfc[1] = NaN
        @test_throws DimensionMismatch radiative_fluxes!(
            bad, model, atmosphere, boundary, workspace)
        @test isnan(workspace.atmospheric_state.t_sfc[1])
    end
end
