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
include(joinpath(@__DIR__, "ecckd_original_objective_loss.jl"))

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

# --- Stage 2: differentiable chain loss ∘ RT ∘ interpolation --------------------
# Single-gas, single-band LW chain: log-coefficient LUT theta (ng, np, nt) ->
# linear-in-coefficient interpolation of exp(theta) (item 17) -> per-g optical
# depth -> LW RT (items 1-5) -> band aggregation by summation (item 16; LW
# climate FSCK is one band) -> net-flux heating (item 12, LW) -> the ported
# ecckd_lw_ckd_loss kernel. Interpolation stencils live in the context,
# precomputed OUTSIDE the differentiated path (design section 4).
struct G4LwChainContext
    stencils::Vector{G4BilinearStencil}
    layer_moles::Vector{Float64}     # gas moles per area per layer [mol m^-2]
    planck_hl::Vector{Float64}
    surf_planck::Float64
    pressure_hl::Vector{Float64}
    layer_weight::Vector{Float64}
    heating_true::Matrix{Float64}    # (nlay, 1)
    flux_dn_true::Matrix{Float64}    # (nlay+1, 1)
    flux_up_true::Matrix{Float64}    # (nlay+1, 1)
    flux_weight::Float64
    flux_profile_weight::Float64
    broadband_weight::Float64
end

function g4_lw_chain_fluxes(theta_log::AbstractArray{<:Real,3}, ctx::G4LwChainContext)
    ng = size(theta_log, 1)
    nlay = length(ctx.stencils)
    T = eltype(theta_log)
    flux_dn_band = zeros(T, nlay + 1)
    flux_up_band = zeros(T, nlay + 1)
    tau = zeros(T, nlay)
    for g in 1:ng
        for l in 1:nlay
            s = ctx.stencils[l]
            ip = s.i0p + 1; it = s.i0t + 1
            c = (1 - s.wp) * ((1 - s.wt) * exp(theta_log[g, ip,   it]) +
                              s.wt       * exp(theta_log[g, ip,   it+1])) +
                s.wp       * ((1 - s.wt) * exp(theta_log[g, ip+1, it]) +
                              s.wt       * exp(theta_log[g, ip+1, it+1]))
            tau[l] = c * ctx.layer_moles[l]
        end
        r = g4_lw_fluxes(tau, ctx.planck_hl, ctx.surf_planck, 1.0)
        flux_dn_band .+= r.flux_dn
        flux_up_band .+= r.flux_up
    end
    return flux_dn_band, flux_up_band
end

function g4_lw_chain_loss(theta_log::AbstractArray{<:Real,3}, ctx::G4LwChainContext)
    flux_dn_band, flux_up_band = g4_lw_chain_fluxes(theta_log, ctx)
    hr = g4_heating_rate(ctx.pressure_hl, flux_dn_band, flux_up_band)
    return ecckd_lw_ckd_loss(
        heating_rate_fwd = reshape(hr, :, 1),
        heating_rate_true = ctx.heating_true,
        flux_dn_fwd = reshape(flux_dn_band, :, 1),
        flux_up_fwd = reshape(flux_up_band, :, 1),
        flux_dn_true = ctx.flux_dn_true,
        flux_up_true = ctx.flux_up_true,
        layer_weight = ctx.layer_weight,
        flux_weight = ctx.flux_weight,
        flux_profile_weight = ctx.flux_profile_weight,
        broadband_weight = ctx.broadband_weight,
    )
end

# --- Stage 3: objective-completion terms (Appendix B items 18-19) ---------------
# These complete the training objective beyond the ported flux/heating kernels:
# REQUIRED before any G3/floor or recovery claim. This is objective-completion
# plumbing, NOT real-data acceptance.

# Correlation-shape matrix S over a (t, p) log-coefficient LUT slice for one
# g-point: S[a,b] = tcorr^|Δt| * pcorr^|Δp| (item 19; ckd_model.cpp:678-679).
# Flatten order: t fastest within p (documented assumption; the quadratic form
# is invariant to a consistent permutation — exact upstream stride order is
# re-verified at G1).
function g4_prior_shape_matrix(nt::Int, np::Int, tcorr::Real, pcorr::Real)
    n = nt * np
    S = Matrix{Float64}(undef, n, n)
    for b in 1:n, a in 1:n
        ta, pa = mod(a - 1, nt), div(a - 1, nt)
        tb, pb = mod(b - 1, nt), div(b - 1, nt)
        S[a, b] = tcorr^abs(ta - tb) * pcorr^abs(pa - pb)
    end
    return S
end

# Prior term for theta (ng, np, nt) against prior mean theta_prior:
# J = sum_g 0.5 * (1/bg_err^2) * v' * Sinv * v with v the (t fastest) flatten
# of theta[g,:,:] - theta_prior[g,:,:]. Sinv precomputed (constant, outside
# any AD tape).
function g4_prior_term(theta::AbstractArray{<:Real,3},
                       theta_prior::AbstractArray{<:Real,3},
                       Sinv::AbstractMatrix, bg_err::Real)
    ng, np, nt = size(theta)
    T = eltype(theta)
    J = zero(T)
    v = zeros(T, np * nt)
    for g in 1:ng
        k = 0
        for ip in 1:np, it in 1:nt
            k += 1
            v[k] = theta[g, ip, it] - theta_prior[g, ip, it]
        end
        J += (v' * (Sinv * v))
    end
    return T(0.5) / (bg_err^2) * J
end

# Negative optical-depth penalty (item 18; solve_adept.cpp:105-114): computed
# on the UNCLAMPED optical depths, which are then clamped to zero for RT.
function g4_negative_od_penalty(od::AbstractArray, weight::Real)
    T = eltype(od)
    acc = zero(T)
    for x in od
        acc += x < 0 ? x * x : zero(T)
    end
    return weight * acc
end

g4_clamp_od(od::AbstractArray) = max.(od, zero(eltype(od)))

# 3-D variant for LUT gases with a concentration axis (item 19: optional
# ccorr^|Δc| factor). Flatten order: t fastest, then p, then c (documented;
# quadratic form is permutation-invariant given consistent construction).
function g4_prior_shape_matrix_3d(nt::Int, np::Int, nc::Int,
                                  tcorr::Real, pcorr::Real, ccorr::Real)
    n = nt * np * nc
    S = Matrix{Float64}(undef, n, n)
    unpack(a) = (mod(a - 1, nt), mod(div(a - 1, nt), np), div(a - 1, nt * np))
    for b in 1:n, a in 1:n
        ta, pa, ca = unpack(a)
        tb, pb, cb = unpack(b)
        S[a, b] = tcorr^abs(ta - tb) * pcorr^abs(pa - pb) * ccorr^abs(ca - cb)
    end
    return S
end

# Prior term for a concentration-axis LUT gas: theta (ng, nc, np, nt).
function g4_prior_term_conc(theta::AbstractArray{<:Real,4},
                            theta_prior::AbstractArray{<:Real,4},
                            Sinv::AbstractMatrix, bg_err::Real)
    ng, nc, np, nt = size(theta)
    T = eltype(theta)
    J = zero(T)
    v = zeros(T, nc * np * nt)
    for g in 1:ng
        k = 0
        for ic in 1:nc, ip in 1:np, it in 1:nt
            k += 1
            v[k] = theta[g, ic, ip, it] - theta_prior[g, ic, ip, it]
        end
        J += (v' * (Sinv * v))
    end
    return T(0.5) / (bg_err^2) * J
end
