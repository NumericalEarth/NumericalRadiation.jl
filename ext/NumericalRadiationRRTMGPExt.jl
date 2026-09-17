module NumericalRadiationRRTMGPExt

using NumericalRadiation
using ClimaComms
using NCDatasets
using RRTMGP

using RRTMGP: ClearSkyRadiation, RRTMGPGridParams, RRTMGPSolver, lookup_tables
using RRTMGP.AtmosphericStates: AtmosphericState
using RRTMGP.BCs: LwBCs, SwBCs
using RRTMGP.Parameters: RRTMGPParameters
using RRTMGP.VolumeMixingRatios: VmrGM

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

# Zero-initialized global-mean gas mole fractions: H₂O and O₃ vary per
# layer, every other gas is a well-mixed scalar (the layout of RRTMGP's
# `VmrGM`, which calls them volume mixing ratios).
function initialize_global_mean_mole_fractions(ngas, nlayers, ncol, FT, array_type)
    water_vapor_mole_fraction = array_type{FT}(undef, nlayers, ncol)
    ozone_mole_fraction = array_type{FT}(undef, nlayers, ncol)
    mole_fractions = array_type{FT}(undef, ngas)
    fill!(water_vapor_mole_fraction, zero(FT))
    fill!(ozone_mole_fraction, zero(FT))
    fill!(mole_fractions, zero(FT))
    return VmrGM(water_vapor_mole_fraction, ozone_mole_fraction, mole_fractions)
end

function NumericalRadiation.radiation_workspace(model::RRTMGPClearSkyModel{FT},
                                                   atmosphere::ColumnAtmosphere;
                                                   backend = nothing) where FT
    nlayers = length(atmosphere.temperature_layers)
    ncol = 1
    grid_params = RRTMGPGridParams(FT; context = model.context, domain_nlay = nlayers, ncol)
    array_type = ClimaComms.array_type(ClimaComms.device(model.context))

    # Read the NetCDF lookup tables once and hand the bundle to the solver.
    radiation_method = ClearSkyRadiation(false)
    lookups = lookup_tables(grid_params, radiation_method)
    ngas = lookups.ngas_sw
    nbnd_lw = lookups.nbnd_lw
    nbnd_sw = lookups.nbnd_sw

    longitude = array_type{FT}(zeros(ncol))
    latitude = array_type{FT}(zeros(ncol))
    layerdata = array_type{FT}(undef, 4, nlayers, ncol)
    pressure_interfaces = array_type{FT}(undef, nlayers + 1, ncol)
    temperature_interfaces = array_type{FT}(undef, nlayers + 1, ncol)
    surface_temperature = array_type{FT}(undef, ncol)
    mole_fractions = initialize_global_mean_mole_fractions(ngas, nlayers, ncol, FT, array_type)
    atmospheric_state = AtmosphericState(longitude,
                                         latitude,
                                         layerdata,
                                         pressure_interfaces,
                                         temperature_interfaces,
                                         surface_temperature,
                                         mole_fractions,
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
                          atmospheric_state;
                          lookups)
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
    water_vapor = gas_value(gases, :h2o, zero(FT))
    ozone = gas_value(gases, :o3, zero(FT))
    carbon_dioxide = FT(gas_value(gases, :co2, 400e-6))
    methane = FT(gas_value(gases, :ch4, 1.8e-6))
    nitrous_oxide = FT(gas_value(gases, :n2o, 330e-9))
    oxygen = FT(gas_value(gases, :o2, 0.20946))
    nitrogen = FT(gas_value(gases, :n2, 0.78084))
    carbon_monoxide = FT(gas_value(gases, :co, 0))

    # RRTMGP's kernels are bottom-at-index-1 (surface source/albedo and the
    # hydrostatic Δp in compute_col_gas_kernel! assume p decreasing with
    # index), while ColumnAtmosphere is top-down by contract, so every
    # per-layer/per-level copy reverses the vertical index.
    for k in 1:nlayers
        kr = nlayers - k + 1
        water_vapor_k = max(FT(layer_value(water_vapor, k)), zero(FT))
        state.layerdata[2, kr, 1] = FT(atmosphere.pressure_layers[k])
        state.layerdata[3, kr, 1] = clamp(FT(atmosphere.temperature_layers[k]), FT(160), FT(355))
        state.layerdata[4, kr, 1] = zero(FT)
        state.vmr.vmr_h2o[kr, 1] = water_vapor_k
        state.vmr.vmr_o3[kr, 1] = max(FT(layer_value(ozone, k)), zero(FT))
    end

    for k in 1:(nlayers + 1)
        kr = nlayers + 2 - k
        state.p_lev[kr, 1] = FT(atmosphere.pressure_interfaces[k])
        state.t_lev[kr, 1] = clamp(FT(atmosphere.temperature_interfaces[k]), FT(160), FT(355))
    end

    # Dry column amounts via RRTMGP's own kernel (dry-air mole-fraction
    # convention, "VMR" in RRTMGP, with the moist molar mass) on the reversed
    # state. The staging above and the flux read-back below index the state
    # arrays element by element, so this adapter is CPU-only: `context` must
    # be a CPU ClimaComms context.
    RRTMGP.Optics.compute_col_gas!(ClimaComms.device(model.context),
                                   state.p_lev,
                                   view(state.layerdata, 1, :, :),
                                   model.parameters,
                                   state.vmr.vmr_h2o,
                                   nothing)
    state.t_sfc[1] = clamp(FT(boundary.surface_temperature), FT(160), FT(355))

    mole_fractions = state.vmr.vmr
    fill!(mole_fractions, zero(FT))
    gas_indices = workspace.solver.lookups.idx_gases_sw
    haskey(gas_indices, "co2") && (mole_fractions[gas_indices["co2"]] = carbon_dioxide)
    haskey(gas_indices, "ch4") && (mole_fractions[gas_indices["ch4"]] = methane)
    haskey(gas_indices, "n2o") && (mole_fractions[gas_indices["n2o"]] = nitrous_oxide)
    haskey(gas_indices, "o2") && (mole_fractions[gas_indices["o2"]] = oxygen)
    haskey(gas_indices, "n2") && (mole_fractions[gas_indices["n2"]] = nitrogen)
    haskey(gas_indices, "co") && (mole_fractions[gas_indices["co"]] = carbon_monoxide)

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
    RRTMGP.update_lw_fluxes!(solver)
    RRTMGP.update_sw_fluxes!(solver)
    # RRTMGP level fluxes are bottom-at-index-1; reverse back to the
    # package's top-down convention. The `(nlayers + 1, ncol)` views are
    # RRTMGP's public flux accessors, refreshed by the update calls above.
    lw_up = RRTMGP.lw_flux_up(solver)
    lw_dn = RRTMGP.lw_flux_dn(solver)
    sw_up = RRTMGP.sw_flux_up(solver)
    sw_dn = RRTMGP.sw_flux_dn(solver)
    for k in 1:(nlayers + 1)
        kr = nlayers + 2 - k
        fluxes.longwave_up[k] = lw_up[kr, 1]
        fluxes.longwave_down[k] = lw_dn[kr, 1]
        fluxes.shortwave_up[k] = sw_up[kr, 1]
        fluxes.shortwave_down[k] = sw_dn[kr, 1]
    end
    return fluxes
end

end
