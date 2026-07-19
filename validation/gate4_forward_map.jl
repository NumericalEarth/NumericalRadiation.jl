# Gate-4 P2 deliverable 1 (Stage 1): differentiable ecCKD forward-map pieces.
#
# Implements the upstream training-RT semantics per the anchored checklist in
# validation/results/gate4_p2_forward_map_design.md, Appendix B (checklist item
# numbers cited inline) and Appendix A (SW heating convention). Pure functions,
# no src/ or ext/ modification. Stage 1 scope: coefficient-state loader,
# optical-depth interpolation, LW/SW RT recurrences, heating rates.
# Enzyme wiring (Stage 2) and prior/negative-OD penalty terms (Stage 3) follow.
#
# Data mode: synthetic profiles and published CKD definition tables only.
# No CKDMIP flux data is read here; no objective-value/floor/recovery claims.

include(joinpath(@__DIR__, "validation_results.jl"))

import NCDatasets

# --- Physical constants (Appendix B item numbers in comments) -----------------
const G4_LW_DIFFUSIVITY = 1.66            # item 1 (constants.h:24)
const G4_LW_EMISS_THRESHOLD = 1e-5        # item 2 (radiative_transfer_lw.cpp:42-43)
const G4_SW_UP_SECANT = 2.0               # item 7 (radiative_transfer_sw.cpp:66)
const G4_ACCEL_GRAVITY = 9.80665          # item 12 (constants.h:22)
const G4_SPECIFIC_HEAT_AIR = 1004.0       # item 12 (constants.h:23)
const G4_HR_WEIGHT = 86400.0              # item 13 (K/s -> K/day, squared in cost)
const G4_M_DRY_AIR = 28.970               # item 17 (g/mol; simple_weight uses 0.001*M)
const G4_INDEX_CLAMP_EPS = 1.0001         # item 17: fractional index in [0, n-1.0001]

# --- Optical-depth interpolation (item 17) -------------------------------------
# Fractional 0-based index of query q on ascending axis x, clamped to
# [0, n-1.0001] exactly as upstream (ckd_model.cpp:895-1074).
function g4_fractional_index(x::AbstractVector, q::Real)
    n = length(x)
    n >= 2 || throw(ArgumentError("axis needs >= 2 nodes"))
    # locate bracket by linear scan (axes are short); even spacing not assumed
    if q <= x[1]
        idx = (q - x[1]) / (x[2] - x[1])
    elseif q >= x[n]
        idx = (n - 2) + (q - x[n-1]) / (x[n] - x[n-1])
    else
        j = 1
        while x[j+1] < q
            j += 1
        end
        idx = (j - 1) + (q - x[j]) / (x[j+1] - x[j])
    end
    return clamp(idx, 0.0, (n - 1) - (G4_INDEX_CLAMP_EPS - 1.0))
end

# Bilinear interpolation of table[ip, it] over (log-p, T) axes, LINEAR in the
# coefficient (logarithmic_interpolation=false upstream). Index/weight split so
# Stage-2 AD can keep indices out of the tape (design section 4).
struct G4BilinearStencil
    i0p::Int; wp::Float64
    i0t::Int; wt::Float64
end

function g4_bilinear_stencil(logp_axis, t_axis, logp::Real, t::Real)
    fp = g4_fractional_index(logp_axis, logp)
    ft = g4_fractional_index(t_axis, t)
    i0p = floor(Int, fp); i0t = floor(Int, ft)
    return G4BilinearStencil(i0p, fp - i0p, i0t, ft - i0t)
end

function g4_bilinear_apply(table::AbstractMatrix, s::G4BilinearStencil)
    ip = s.i0p + 1; it = s.i0t + 1     # to 1-based
    return (1 - s.wp) * ((1 - s.wt) * table[ip, it] + s.wt * table[ip, it+1]) +
           s.wp       * ((1 - s.wt) * table[ip+1, it] + s.wt * table[ip+1, it+1])
end

# Layer molar weighting (items 8, 17): moles of dry air per unit area,
# simple_weight = dp / (g * 0.001 * M_air)  [mol m^-2]
g4_simple_weight(dp::Real) = dp / (G4_ACCEL_GRAVITY * 0.001 * G4_M_DRY_AIR)

# --- Longwave RT (items 1-5; radiative_transfer_lw.cpp:25-60) ------------------
# Per-g single column. tau: nlay optical depths; planck_hl: nlay+1 half-level
# Planck band irradiances (W m^-2); surf_planck, surf_emissivity (=1 in
# training, item 4). Index 1 = TOA interface; pressure increases with index.
function g4_lw_fluxes(tau::AbstractVector, planck_hl::AbstractVector,
                      surf_planck::Real, surf_emissivity::Real)
    nlay = length(tau)
    length(planck_hl) == nlay + 1 ||
        throw(DimensionMismatch("planck_hl must have nlay+1 entries"))
    T = promote_type(eltype(tau), eltype(planck_hl))
    flux_dn = zeros(T, nlay + 1)
    flux_up = zeros(T, nlay + 1)
    emiss = similar(flux_dn, nlay)
    factor = similar(flux_dn, nlay)
    for l in 1:nlay
        e = 1 - exp(-G4_LW_DIFFUSIVITY * tau[l])                     # item 1
        f = e > G4_LW_EMISS_THRESHOLD ?
            1 - e / (G4_LW_DIFFUSIVITY * tau[l]) : 0.5 * e           # item 2
        emiss[l] = e; factor[l] = f
    end
    flux_dn[1] = 0                                                    # item 3 TOA
    for l in 1:nlay
        flux_dn[l+1] = flux_dn[l] * (1 - emiss[l]) +
                       planck_hl[l] * (emiss[l] - factor[l]) +
                       planck_hl[l+1] * factor[l]
    end
    flux_up[nlay+1] = surf_planck * surf_emissivity +
                      (1 - surf_emissivity) * flux_dn[nlay+1]         # item 3
    for l in nlay:-1:1
        flux_up[l] = flux_up[l+1] * (1 - emiss[l]) +
                     planck_hl[l+1] * (emiss[l] - factor[l]) +
                     planck_hl[l] * factor[l]                         # weights swap
    end
    return (flux_dn = flux_dn, flux_up = flux_up)
end

# --- Shortwave RT (items 6-11; radiative_transfer_sw.cpp:24-77) ----------------
# Direct beam only (albedo <= 0 path): flux_up is EMPTY upstream; represented
# here as `nothing` so heating cannot silently consume it.
function g4_sw_direct(tau::AbstractVector, cos_sza::Real, ssi::Real)
    nlay = length(tau)
    T = promote_type(eltype(tau), typeof(float(cos_sza)))
    flux_dn = zeros(T, nlay + 1)
    flux_dn[1] = cos_sza * ssi                                        # item 6
    for l in 1:nlay
        flux_dn[l+1] = flux_dn[l] * exp(-tau[l] / cos_sza)
    end
    return flux_dn
end

# Norayleigh upwelling return beam at fixed secant 2.0 (item 7). mu0 and albedo
# are explicit arguments so a G1 runner can drive this directly.
function g4_sw_fluxes(tau::AbstractVector, cos_sza::Real, ssi::Real, albedo::Real)
    flux_dn = g4_sw_direct(tau, cos_sza, ssi)
    if albedo <= 0
        return (flux_dn = flux_dn, flux_up = nothing)                 # direct-only
    end
    nlay = length(tau)
    flux_up = zeros(eltype(flux_dn), nlay + 1)
    flux_up[nlay+1] = flux_dn[nlay+1] * albedo                        # item 7
    for l in nlay:-1:1
        flux_up[l] = flux_up[l+1] * exp(-G4_SW_UP_SECANT * tau[l])
    end
    return (flux_dn = flux_dn, flux_up = flux_up)
end

# --- Heating rates (item 12; heating_rate.h:38-47) -----------------------------
# HR = -(g/cp)/dp * (dFdn - dFup); SW uses DOWNWELLING ONLY (Appendix A,
# HIGH-RISK PARITY REQUIREMENT: never generic net-flux divergence for SW).
function g4_heating_rate(pressure_hl::AbstractVector, flux_dn::AbstractVector,
                         flux_up::Union{AbstractVector, Nothing})
    nlay = length(pressure_hl) - 1
    T = eltype(flux_dn)
    hr = zeros(T, nlay)
    for l in 1:nlay
        conv = -(G4_ACCEL_GRAVITY / G4_SPECIFIC_HEAT_AIR) /
               (pressure_hl[l+1] - pressure_hl[l])
        dnet = (flux_dn[l+1] - flux_dn[l])
        if flux_up !== nothing
            dnet -= (flux_up[l+1] - flux_up[l])
        end
        hr[l] = conv * dnet
    end
    return hr                                                          # K s^-1
end

g4_sw_heating_rate(pressure_hl, flux_dn) =
    g4_heating_rate(pressure_hl, flux_dn, nothing)   # Appendix A convention

# --- Coefficient-state loader (item 22 support arrays; Stage-1 scope) ----------
# Generic NCDatasets read of a published ckd-definition file. Returns
# coefficient arrays keyed by variable name plus support/coordinate arrays that
# are present. Axis-semantics alignment against upstream is validated at G1
# (Stage 2+); Stage 1 records what was found.
function g4_load_ckd_definition(path::AbstractString)
    coeffs = Dict{String, Array{Float64}}()
    support = Dict{String, Array{Float64}}()
    dims = Dict{String, Int}()
    NCDatasets.NCDataset(path) do ds
        for (name, var) in ds
            if endswith(name, "molar_absorption_coeff")
                coeffs[name] = Float64.(Array(var))
            elseif name in ("gpoint_fraction", "solar_irradiance",
                            "rayleigh_molar_scattering_coeff",
                            "planck_function", "temperature_planck",
                            "pressure", "temperature", "wavenumber1_band",
                            "wavenumber2_band")
                support[name] = Float64.(Array(var))
            end
        end
        for (dname, d) in ds.dim
            dims[String(dname)] = Int(d)
        end
    end
    return (path = path, coefficients = coeffs, support = support, dims = dims)
end
