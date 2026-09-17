"""
$(TYPEDEF)

Williams (2026) "Simple Spectral Model" (SSM) for clear-sky longwave
radiative transfer.

The scheme solves Schwarzschild's two-stream equations

    dℐꜛ/dτ = ℐꜛ − πB(T)
    dℐꜜ/dτ = πB(T) − ℐꜜ

for the upwelling (`ℐꜛˡʷ`) and downwelling (`ℐꜜˡʷ`) spectral longwave
fluxes at each of `nwavenumber` evenly spaced wavenumbers between
`wavenumber_min` and `wavenumber_max`, with analytic mass absorption
coefficients for H₂O
line (rotation + vibration–rotation + combination bands, [`water_vapor_line_kappa_ref`](@ref)),
a two-band H₂O continuum ([`water_vapor_continuum_kappa_ref`](@ref)) and a Lorentzian CO₂
15 μm bending mode ([`carbon_dioxide_kappa_ref`](@ref)). All reference constants are at
(T_ref, p_ref, RH_ref) = (260 K, 500 hPa, 100 %).

Fields and defaults follow Williams (2026), Table 1.

References:
- Williams (2026), *J. Adv. Model. Earth Syst.*, doi:10.1029/2025MS005405.
- Armstrong (1968), doi:10.1016/0022-4073(68)90052-6 (diffusivity factor D).
- Mlawer et al. (1997), doi:10.1029/97JD00237 (continuum temperature scaling).

Fields are

$(TYPEDFIELDS)
"""
struct AnalyticBandLongwave{NF} <: AbstractLongwaveScheme
    "Number of evenly spaced wavenumber quadrature points"
    nwavenumber::Int
    "Minimum wavenumber of the spectral integration range [cm⁻¹]"
    wavenumber_min::NF
    "Maximum wavenumber of the spectral integration range [cm⁻¹]"
    wavenumber_max::NF
    "Peak absorption of the pure-rotation band κ_rot [m² kg⁻¹]"
    κ_rot::NF
    "e-folding decay length of the rotation band l_rot [cm⁻¹]"
    l_rot::NF
    "Peak absorption of the vibration–rotation band κ_vr [m² kg⁻¹]"
    κ_vr::NF
    "e-folding length of vibration–rotation band (low-ν side) l_vr1 [cm⁻¹]"
    l_vr1::NF
    "e-folding length of vibration–rotation band (high-ν side) l_vr2 [cm⁻¹]"
    l_vr2::NF
    "Continuum absorption below 1700 cm⁻¹ κ_cnt1 [m² kg⁻¹]"
    κ_cnt1::NF
    "Continuum absorption above 1700 cm⁻¹ κ_cnt2 [m² kg⁻¹]"
    κ_cnt2::NF
    "Peak absorption of the CO₂ 15 μm band κ_CO₂ [m² kg⁻¹]"
    κ_CO₂::NF
    "e-folding half-width of CO₂ band l_CO₂ [cm⁻¹]"
    l_CO₂::NF
    "Centre wavenumber of CO₂ bending mode ν̃_CO₂ [cm⁻¹]"
    ν̃_CO₂::NF
    "Two-stream diffusivity factor D (Armstrong 1968)"
    diffusivity::NF
    "Reference pressure for pressure broadening [Pa]"
    p_ref::NF
    "Reference temperature for absorption coefficient fits [K]"
    T_ref::NF
    "Reference saturation water-vapor pressure at T_ref [Pa]"
    pv_ref::NF
    "Temperature-scaling exponent for the continuum (Mlawer et al. 1997) [K⁻¹]"
    σ_cont::NF
    "Water-to-dry-air molar mass ratio ε = mᵛ / mᵈ of the vapor partial pressure"
    water_vapor_molar_mass_ratio::NF
    "CO₂-to-dry-air molar mass ratio converting ppmv to a mass mixing ratio"
    carbon_dioxide_molar_mass_ratio::NF
end

Adapt.@adapt_structure AnalyticBandLongwave

function AnalyticBandLongwave{NF}(;
        nwavenumber::Int = 41,
        wavenumber_min = NF(10),
        wavenumber_max = NF(2500),
        κ_rot  = NF(37),    l_rot  = NF(56),
        κ_vr   = NF(5),     l_vr1  = NF(37),    l_vr2 = NF(52),
        κ_cnt1 = NF(0.004), κ_cnt2 = NF(0.0002),
        κ_CO₂    = NF(110), l_CO₂  = NF(12),    ν̃_CO₂ = NF(667),
        diffusivity = NF(1.5),
        p_ref  = NF(50000), T_ref  = NF(260),   pv_ref = NF(224.92),
        σ_cont = NF(0.02),
        water_vapor_molar_mass_ratio = NF(0.622),
        carbon_dioxide_molar_mass_ratio = NF(44 / 29),
    ) where NF
    return AnalyticBandLongwave{NF}(
        nwavenumber, wavenumber_min, wavenumber_max,
        κ_rot, l_rot, κ_vr, l_vr1, l_vr2, κ_cnt1, κ_cnt2,
        κ_CO₂, l_CO₂, ν̃_CO₂,
        diffusivity, p_ref, T_ref, pv_ref, σ_cont,
        water_vapor_molar_mass_ratio, carbon_dioxide_molar_mass_ratio,
    )
end

"""$(TYPEDSIGNATURES)
Construct an [`AnalyticBandLongwave`](@ref). Floating-point type defaults to
`Float64`; pass as a positional argument (e.g. `AnalyticBandLongwave(Float32)`)
for a different precision.
"""
AnalyticBandLongwave(::Type{NF}; kwargs...) where NF =
    AnalyticBandLongwave{NF}(; kwargs...)

AnalyticBandLongwave(; kwargs...) = AnalyticBandLongwave{Float64}(; kwargs...)

Base.eltype(::AnalyticBandLongwave{NF}) where NF = NF
Base.eltype(::Type{<:AnalyticBandLongwave{NF}}) where NF = NF

"""$(TYPEDSIGNATURES)
Column longwave radiative transfer for the Williams (2026) Simple Spectral
Model. Tendencies are accumulated into `dTdt` with `+=`/`-=`; diagnostic
fluxes are written into `diag`.

Sign convention: temperature tendency has units [K s⁻¹]; positive OLR, positive
downward surface flux, positive upward surface flux.
"""
function solve_longwave!(dTdt::AbstractVector,
                         diag::LongwaveDiagnostics{NF},
                         scheme::AnalyticBandLongwave{NF},
                         profile::AtmosphereProfile{NF},
                         geometry::ColumnGrid,
                         surface::SurfaceState,
                         constants) where NF
    # `constants` is duck-typed: any object with `.gravity`, `.heat_capacity`,
    # `.stefan_boltzmann`, `.solar_constant` works (PhysicalConstants is the
    # built-in; Breeze's ThermodynamicConstants can be adapted via a thin
    # wrapper in the Breeze extension).

    T  = profile.temperature
    q  = profile.humidity
    pₛ = profile.surface_pressure
    CO₂ = NF(profile.CO₂)
    nlayers = length(T)

    σ_SB = NF(constants.stefan_boltzmann)
    cₚ   = NF(constants.heat_capacity)
    g    = NF(constants.gravity)

    ϵ_ocean = NF(surface.ocean_emissivity)
    ϵ_land  = NF(surface.land_emissivity)
    sst     = NF(surface.sea_surface_temperature)
    lst     = NF(surface.land_surface_temperature)
    land_fraction = NF(surface.land_fraction)

    # Broadband Stefan–Boltzmann surface upward flux (for diagnostics).
    U_sfc_ocean = ifelse(isfinite(sst), ϵ_ocean * σ_SB * sst^4, zero(NF))
    U_sfc_land  = ifelse(isfinite(lst), ϵ_land  * σ_SB * lst^4, zero(NF))
    U_sfc_bb    = (1 - land_fraction) * U_sfc_ocean + land_fraction * U_sfc_land

    # Wavenumber quadrature.
    nν = scheme.nwavenumber
    dν̃ = (scheme.wavenumber_max - scheme.wavenumber_min) / NF(nν - 1)

    olr_sum::NF    = zero(NF)
    D_surf_sum::NF = zero(NF)

    for iv in 1:nν
        ν̃ = scheme.wavenumber_min + NF(iv - 1) * dν̃

        B_sfc_ocean = ifelse(isfinite(sst), planck_wavenumber(sst, ν̃), zero(NF))
        B_sfc_land  = ifelse(isfinite(lst), planck_wavenumber(lst, ν̃), zero(NF))

        # Hemispherical surface flux πB(T_sfc), land–sea weighted by emissivity ϵ.
        # ℐꜛˡʷ (surface, spectral bin) [W m⁻²]:
        U_spec::NF = dν̃ * NF(π) * (
            (1 - land_fraction) * ϵ_ocean * B_sfc_ocean +
             land_fraction      * ϵ_land  * B_sfc_land
        )

        # ---- Upward sweep: k = nlayers → 1 (ℐꜛ) --------------------------
        U::NF = U_spec
        # Surface upward flux enters the bottom of the lowest layer.
        dTdt[nlayers] += surface_flux_to_tendency(U / cₚ, profile, geometry, constants)

        for k in nlayers:-1:1
            Δτ_k  = williams_delta_tau(k, ν̃, CO₂, T, q, pₛ, geometry, scheme, g)
            tr_k  = exp(-Δτ_k)
            B_k   = planck_wavenumber(T[k], ν̃)
            U_new::NF = U * tr_k + dν̃ * NF(π) * B_k * (1 - tr_k)

            if k > 1
                # U_new leaves layer k at the top and enters layer k-1 at the bottom.
                dTdt[k]     -= flux_to_tendency(U_new / cₚ, profile, geometry, constants, k)
                dTdt[k - 1] += flux_to_tendency(U_new / cₚ, profile, geometry, constants, k - 1)
            else
                # k == 1: U_new is OLR escaping to space.
                dTdt[1] -= flux_to_tendency(U_new / cₚ, profile, geometry, constants, 1)
                olr_sum += U_new
            end
            U = U_new
        end

        # ---- Downward sweep: k = 1 → nlayers (ℐꜜ) ------------------------
        # TOA boundary: ℐꜜˡʷ(TOA) = 0 (no longwave from space).
        D::NF = zero(NF)

        for k in 1:(nlayers - 1)
            Δτ_k  = williams_delta_tau(k, ν̃, CO₂, T, q, pₛ, geometry, scheme, g)
            tr_k  = exp(-Δτ_k)
            B_k   = planck_wavenumber(T[k], ν̃)
            D_new::NF = D * tr_k + dν̃ * NF(π) * B_k * (1 - tr_k)

            dTdt[k]     -= flux_to_tendency(D_new / cₚ, profile, geometry, constants, k)
            dTdt[k + 1] += flux_to_tendency(D_new / cₚ, profile, geometry, constants, k + 1)
            D = D_new
        end

        # Surface-adjacent layer: the downward flux that reaches the surface.
        Δτ_nl = williams_delta_tau(nlayers, ν̃, CO₂, T, q, pₛ, geometry, scheme, g)
        tr_nl = exp(-Δτ_nl)
        B_nl  = planck_wavenumber(T[nlayers], ν̃)
        D_surf::NF = D * tr_nl + dν̃ * NF(π) * B_nl * (1 - tr_nl)

        dTdt[nlayers] -= surface_flux_to_tendency(D_surf / cₚ, profile, geometry, constants)
        D_surf_sum    += D_surf
    end

    diag.outgoing_longwave        = olr_sum
    diag.surface_longwave_down    = D_surf_sum
    diag.ocean_surface_longwave_up = U_sfc_ocean
    diag.land_surface_longwave_up  = U_sfc_land
    diag.surface_longwave_up       = U_sfc_bb

    return nothing
end
