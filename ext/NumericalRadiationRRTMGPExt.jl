module NumericalRadiationRRTMGPExt

using NumericalRadiation
using ClimaComms
using NCDatasets
using RRTMGP

using RRTMGP: ClearSkyRadiation, RRTMGPGridParams, RRTMGPSolver
using RRTMGP.AtmosphericStates: AtmosphericState
using RRTMGP.BCs: LwBCs, SwBCs
using RRTMGP.Parameters: RRTMGPParameters
using RRTMGP.Vmrs: init_vmr

struct RRTMGPClearSkyModel{FT, C}
    context::C
    parameters::RRTMGPParameters{FT}
end

function RRTMGPClearSkyModel(::Type{FT} = Float64;
                             context = ClimaComms.context(ClimaComms.CPUSingleThreaded()),
                             gravity = 9.80665,
                             molmass_dryair = 0.028964,
                             molmass_water = 0.018016,
                             gas_constant = 8.31446261815324,
                             kappa_d = 287.05 / 1004.0,
                             stefan_boltzmann_constant = 5.670374419e-8,
                             avogadro_number = 6.02214076e23) where FT
    parameters = RRTMGPParameters(
        grav = FT(gravity),
        molmass_dryair = FT(molmass_dryair),
        molmass_water = FT(molmass_water),
        gas_constant = FT(gas_constant),
        kappa_d = FT(kappa_d),
        Stefan = FT(stefan_boltzmann_constant),
        avogad = FT(avogadro_number),
    )
    return RRTMGPClearSkyModel{FT, typeof(context)}(context, parameters)
end

struct RRTMGPBoundaryConditions{FT}
    surface_temperature::FT
    surface_emissivity::FT
    surface_albedo::FT
    toa_shortwave_down::FT
    cos_zenith::FT
end

function RRTMGPBoundaryConditions(; surface_temperature,
                                  surface_emissivity = 1,
                                  surface_albedo = 0,
                                  toa_shortwave_down = 0,
                                  cos_zenith = 1)
    FT = promote_type(typeof(surface_temperature),
                      typeof(surface_emissivity),
                      typeof(surface_albedo),
                      typeof(toa_shortwave_down),
                      typeof(cos_zenith))
    return RRTMGPBoundaryConditions{FT}(FT(surface_temperature),
                                       FT(surface_emissivity),
                                       FT(surface_albedo),
                                       FT(toa_shortwave_down),
                                       FT(cos_zenith))
end

struct RRTMGPWorkspace{S, AS, SOL}
    grid_params::S
    atmospheric_state::AS
    solver::SOL
end

function NumericalRadiation.radiation_workspace(model::RRTMGPClearSkyModel{FT},
                                                   atmosphere::ColumnAtmosphere;
                                                   backend = nothing) where FT
    nlayers = length(atmosphere.temperature_layers)
    ncol = 1
    grid_params = RRTMGPGridParams(FT; context = model.context, nlay = nlayers, ncol)
    array_type = ClimaComms.array_type(ClimaComms.device(model.context))

    radiation_method = ClearSkyRadiation(false)
    lookup_probe = RRTMGP.lookup_tables(grid_params, radiation_method)
    ngas = lookup_probe.lu_kwargs.ngas_sw
    nbnd_lw = lookup_probe.lu_kwargs.nbnd_lw
    nbnd_sw = lookup_probe.lu_kwargs.nbnd_sw

    longitude = array_type{FT}(zeros(ncol))
    latitude = array_type{FT}(zeros(ncol))
    layerdata = array_type{FT}(undef, 4, nlayers, ncol)
    pressure_interfaces = array_type{FT}(undef, nlayers + 1, ncol)
    temperature_interfaces = array_type{FT}(undef, nlayers + 1, ncol)
    surface_temperature = array_type{FT}(undef, ncol)
    vmr = init_vmr(ngas, nlayers, ncol, FT, array_type; gm = true)
    atmospheric_state = AtmosphericState(longitude,
                                         latitude,
                                         layerdata,
                                         pressure_interfaces,
                                         temperature_interfaces,
                                         surface_temperature,
                                         vmr,
                                         nothing,
                                         nothing)

    lw_bcs = LwBCs(array_type{FT}(undef, nbnd_lw, ncol), nothing)
    sw_bcs = SwBCs(array_type{FT}(undef, ncol),
                   array_type{FT}(undef, ncol),
                   array_type{FT}(undef, nbnd_sw, ncol),
                   nothing,
                   array_type{FT}(undef, nbnd_sw, ncol))
    solver = RRTMGPSolver(grid_params,
                          radiation_method,
                          model.parameters,
                          lw_bcs,
                          sw_bcs,
                          atmospheric_state)
    return RRTMGPWorkspace(grid_params, atmospheric_state, solver)
end

gas_value(gases, name::Symbol, default) =
    hasproperty(gases, name) ? getproperty(gases, name) : default

layer_value(x::Number, k) = x
layer_value(x, k) = x[k]

function fill_atmospheric_state!(workspace::RRTMGPWorkspace,
                                 model::RRTMGPClearSkyModel{FT},
                                 atmosphere::ColumnAtmosphere,
                                 boundary::RRTMGPBoundaryConditions) where FT
    nlayers = length(atmosphere.temperature_layers)
    state = workspace.atmospheric_state
    gases = atmosphere.gases
    h2o = gas_value(gases, :h2o, zero(FT))
    o3 = gas_value(gases, :o3, zero(FT))
    co2 = FT(gas_value(gases, :co2, 400e-6))
    ch4 = FT(gas_value(gases, :ch4, 1.8e-6))
    n2o = FT(gas_value(gases, :n2o, 330e-9))
    o2 = FT(gas_value(gases, :o2, 0.20946))
    n2 = FT(gas_value(gases, :n2, 0.78084))
    co = FT(gas_value(gases, :co, 0))

    # RRTMGP's kernels are bottom-at-index-1 (surface source/albedo and the
    # hydrostatic Δp in compute_col_gas_kernel! assume p decreasing with
    # index), while ColumnAtmosphere is top-down by contract, so every
    # per-layer/per-level copy reverses the vertical index.
    for k in 1:nlayers
        kr = nlayers - k + 1
        h2o_k = max(FT(layer_value(h2o, k)), zero(FT))
        state.layerdata[2, kr, 1] = FT(atmosphere.pressure_layers[k])
        state.layerdata[3, kr, 1] = clamp(FT(atmosphere.temperature_layers[k]), FT(160), FT(355))
        state.layerdata[4, kr, 1] = zero(FT)
        state.vmr.vmr_h2o[kr, 1] = h2o_k
        state.vmr.vmr_o3[kr, 1] = max(FT(layer_value(o3, k)), zero(FT))
    end

    for k in 1:(nlayers + 1)
        kr = nlayers + 2 - k
        state.p_lev[kr, 1] = FT(atmosphere.pressure_interfaces[k])
        state.t_lev[kr, 1] = clamp(FT(atmosphere.temperature_interfaces[k]), FT(160), FT(355))
    end

    # Dry column amounts via RRTMGP's own kernel (dry-air VMR convention,
    # moist molar mass; CPU and CUDA methods) on the reversed state.
    RRTMGP.Optics.compute_col_gas!(ClimaComms.device(model.context),
                                   state.p_lev,
                                   view(state.layerdata, 1, :, :),
                                   model.parameters,
                                   state.vmr.vmr_h2o,
                                   nothing)
    state.t_sfc[1] = clamp(FT(boundary.surface_temperature), FT(160), FT(355))

    vmr = state.vmr.vmr
    fill!(vmr, zero(FT))
    gas_indices = workspace.solver.lookups.lookups.idx_gases_sw
    haskey(gas_indices, "co2") && (vmr[gas_indices["co2"]] = co2)
    haskey(gas_indices, "ch4") && (vmr[gas_indices["ch4"]] = ch4)
    haskey(gas_indices, "n2o") && (vmr[gas_indices["n2o"]] = n2o)
    haskey(gas_indices, "o2") && (vmr[gas_indices["o2"]] = o2)
    haskey(gas_indices, "n2") && (vmr[gas_indices["n2"]] = n2)
    haskey(gas_indices, "co") && (vmr[gas_indices["co"]] = co)

    solver = workspace.solver
    solver.lws.bcs.sfc_emis .= FT(boundary.surface_emissivity)
    solver.sws.bcs.cos_zenith .= max(FT(boundary.cos_zenith), zero(FT))
    solver.sws.bcs.toa_flux .= FT(boundary.toa_shortwave_down)
    solver.sws.bcs.sfc_alb_direct .= FT(boundary.surface_albedo)
    solver.sws.bcs.sfc_alb_diffuse .= FT(boundary.surface_albedo)
    return workspace
end

function NumericalRadiation.radiative_fluxes!(fluxes::RadiativeFluxes,
                                                 model::RRTMGPClearSkyModel,
                                                 atmosphere::ColumnAtmosphere,
                                                 boundary::RRTMGPBoundaryConditions,
                                                 workspace::RRTMGPWorkspace =
                                                     radiation_workspace(model, atmosphere))
    nlayers = length(atmosphere.temperature_layers)
    for (name, v) in ((:longwave_up, fluxes.longwave_up),
                      (:longwave_down, fluxes.longwave_down),
                      (:shortwave_up, fluxes.shortwave_up),
                      (:shortwave_down, fluxes.shortwave_down))
        length(v) == nlayers + 1 ||
            throw(DimensionMismatch("$name must have length nlayers + 1"))
    end

    fill_atmospheric_state!(workspace, model, atmosphere, boundary)
    solver = workspace.solver
    Base.invokelatest(RRTMGP.update_lw_fluxes!, solver)
    Base.invokelatest(RRTMGP.update_sw_fluxes!, solver)
    # RRTMGP level fluxes are bottom-at-index-1; reverse back to the
    # package's top-down convention.
    for k in 1:(nlayers + 1)
        kr = nlayers + 2 - k
        fluxes.longwave_up[k] = solver.lws.flux.flux_up[kr, 1]
        fluxes.longwave_down[k] = solver.lws.flux.flux_dn[kr, 1]
        fluxes.shortwave_up[k] = solver.sws.flux.flux_up[kr, 1]
        fluxes.shortwave_down[k] = solver.sws.flux.flux_dn[kr, 1]
    end
    return fluxes
end

end
