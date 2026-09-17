"""
$(TYPEDEF)

Williams (2026) "Simple Spectral Model" (SSM) for clear-sky longwave
radiative transfer.

The scheme solves Schwarzschild's two-stream equations

    dℐꜛ/dτ = ℐꜛ − πB(T)
    dℐꜜ/dτ = πB(T) − ℐꜜ

for the upwelling (`ℐꜛˡʷ`) and downwelling (`ℐꜜˡʷ`) spectral longwave
fluxes at each of `Nwavenumbers` evenly spaced wavenumbers between
`wavenumber_min` and `wavenumber_max`, with analytic mass absorption
coefficients for H₂O
line (rotation + vibration–rotation + combination bands, [`water_vapor_line_absorption_reference`](@ref)),
a two-band H₂O continuum ([`water_vapor_continuum_absorption_reference`](@ref)) and a Lorentzian CO₂
15 μm bending mode ([`carbon_dioxide_absorption_reference`](@ref)). All reference constants are at
(T_ref, p_ref, RH_ref) = (260 K, 500 hPa, 100 %).

Fields and defaults follow Williams (2026), Table 1.

References:
- Williams (2026), *J. Adv. Model. Earth Syst.*, doi:10.1029/2025MS005405.
- Armstrong (1968), doi:10.1016/0022-4073(68)90052-6 (diffusivity factor D).
- Mlawer et al. (1997), doi:10.1029/97JD00237 (continuum temperature scaling).

Fields:
- `Nwavenumbers`: Number of evenly spaced wavenumber quadrature points
- `wavenumber_min`: Minimum wavenumber of the spectral integration range [cm⁻¹]
- `wavenumber_max`: Maximum wavenumber of the spectral integration range [cm⁻¹]
- `κ_rot`: Peak absorption of the pure-rotation band κ_rot [m² kg⁻¹]
- `l_rot`: e-folding decay length of the rotation band l_rot [cm⁻¹]
- `κ_vr`: Peak absorption of the vibration–rotation band κ_vr [m² kg⁻¹]
- `l_vr1`: e-folding length of vibration–rotation band (low-ν side) l_vr1 [cm⁻¹]
- `l_vr2`: e-folding length of vibration–rotation band (high-ν side) l_vr2 [cm⁻¹]
- `κ_cnt1`: Continuum absorption below 1700 cm⁻¹ κ_cnt1 [m² kg⁻¹]
- `κ_cnt2`: Continuum absorption above 1700 cm⁻¹ κ_cnt2 [m² kg⁻¹]
- `κ_CO₂`: Peak absorption of the CO₂ 15 μm band κ_CO₂ [m² kg⁻¹]
- `l_CO₂`: e-folding half-width of CO₂ band l_CO₂ [cm⁻¹]
- `ν̃_CO₂`: Centre wavenumber of CO₂ bending mode ν̃_CO₂ [cm⁻¹]
- `diffusivity`: Two-stream diffusivity factor D (Armstrong 1968)
- `p_ref`: Reference pressure for pressure broadening [Pa]
- `T_ref`: Reference temperature for absorption coefficient fits [K]
- `pv_ref`: Reference saturation water-vapor pressure at T_ref [Pa]
- `σ_cont`: Temperature-scaling exponent for the continuum (Mlawer et al. 1997) [K⁻¹]
- `water_vapor_molar_mass_ratio`: Water-to-dry-air molar mass ratio mᵛ/mᵈ of the vapor
  partial pressure
- `carbon_dioxide_molar_mass_ratio`: CO₂-to-dry-air molar mass ratio converting ppmv to a
  mass mixing ratio
"""
struct AnalyticBandLongwave{NF} <: AbstractLongwaveScheme
    Nwavenumbers::Int
    wavenumber_min::NF
    wavenumber_max::NF
    κ_rot::NF
    l_rot::NF
    κ_vr::NF
    l_vr1::NF
    l_vr2::NF
    κ_cnt1::NF
    κ_cnt2::NF
    κ_CO₂::NF
    l_CO₂::NF
    ν̃_CO₂::NF
    diffusivity::NF
    p_ref::NF
    T_ref::NF
    pv_ref::NF
    σ_cont::NF
    water_vapor_molar_mass_ratio::NF
    carbon_dioxide_molar_mass_ratio::NF
end

Adapt.@adapt_structure AnalyticBandLongwave

function AnalyticBandLongwave{NF}(;
        Nwavenumbers::Int = 41,
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
        Nwavenumbers, wavenumber_min, wavenumber_max,
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
AnalyticBandLongwave(::Type{NF}; kwargs...) where NF = AnalyticBandLongwave{NF}(; kwargs...)

AnalyticBandLongwave(; kwargs...) = AnalyticBandLongwave{Float64}(; kwargs...)

Base.eltype(::AnalyticBandLongwave{NF}) where NF = NF
Base.eltype(::Type{<:AnalyticBandLongwave{NF}}) where NF = NF

"""$(TYPEDSIGNATURES)
Column longwave radiative transfer for the Williams (2026) Simple Spectral
Model. Tendencies are accumulated into `temperature_tendency` with `+=`/`-=`; diagnostic
fluxes are written into `diagnostics`.

Sign convention: temperature tendency has units [K s⁻¹]; positive OLR, positive
downward surface flux, positive upward surface flux.
"""
function solve_longwave!(temperature_tendency::AbstractVector,
                         diagnostics::LongwaveDiagnostics{NF},
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
    pˢ = profile.surface_pressure
    CO₂ = NF(profile.CO₂)
    Nz = length(T)

    σ  = NF(constants.stefan_boltzmann)
    cᵖ = NF(constants.heat_capacity)
    g  = NF(constants.gravity)

    ε_ocean = NF(surface.ocean_emissivity)
    ε_land  = NF(surface.land_emissivity)
    T_ocean = NF(surface.sea_surface_temperature)
    T_land = NF(surface.land_surface_temperature)
    land_fraction = NF(surface.land_fraction)

    # Broadband Stefan–Boltzmann surface upward flux ℐꜛ = ε σ T⁴ (for diagnostics).
    ℐꜛ_surface_ocean = ifelse(isfinite(T_ocean), ε_ocean * σ * T_ocean^4, zero(NF))
    ℐꜛ_surface_land  = ifelse(isfinite(T_land), ε_land  * σ * T_land^4, zero(NF))
    ℐꜛ_surface_broadband = (1 - land_fraction) * ℐꜛ_surface_ocean + land_fraction * ℐꜛ_surface_land

    # Wavenumber quadrature.
    Δν̃ = (scheme.wavenumber_max - scheme.wavenumber_min) / NF(scheme.Nwavenumbers - 1)

    outgoing_longwave::NF = zero(NF)
    surface_longwave_down::NF = zero(NF)

    for i in 1:scheme.Nwavenumbers
        ν̃ = scheme.wavenumber_min + NF(i - 1) * Δν̃

        B_surface_ocean = ifelse(isfinite(T_ocean), planck_wavenumber(T_ocean, ν̃), zero(NF))
        B_surface_land  = ifelse(isfinite(T_land), planck_wavenumber(T_land, ν̃), zero(NF))

        # Hemispherical surface flux πB(Tˢ), land–sea weighted by emissivity ε.
        # ℐꜛˡʷ (surface, spectral bin) [W m⁻²]:
        ℐꜛ_spectral::NF = Δν̃ * NF(π) * (
            (1 - land_fraction) * ε_ocean * B_surface_ocean +
             land_fraction * ε_land  * B_surface_land
        )

        # ---- Upward sweep: k = Nz → 1 (ℐꜛ) --------------------------
        ℐꜛ::NF = ℐꜛ_spectral
        # Surface upward flux enters the bottom of the lowest layer.
        temperature_tendency[Nz] += surface_flux_to_tendency(ℐꜛ / cᵖ, profile, geometry, constants)

        for k in Nz:-1:1
            Δτ_k = williams_optical_depth_increment(k, ν̃, CO₂, T, q, pˢ, geometry, scheme, g)
            𝒯ₖ  = exp(-Δτ_k)
            B_k  = planck_wavenumber(T[k], ν̃)
            ℐꜛ_new::NF = ℐꜛ * 𝒯ₖ + Δν̃ * NF(π) * B_k * (1 - 𝒯ₖ)

            if k > 1
                # ℐꜛ_new leaves layer k at the top and enters layer k-1 at the bottom.
                temperature_tendency[k]     -= flux_to_tendency(ℐꜛ_new / cᵖ, profile, geometry, constants, k)
                temperature_tendency[k - 1] += flux_to_tendency(ℐꜛ_new / cᵖ, profile, geometry, constants, k - 1)
            else
                # k == 1: ℐꜛ_new is OLR escaping to space.
                temperature_tendency[1] -= flux_to_tendency(ℐꜛ_new / cᵖ, profile, geometry, constants, 1)
                outgoing_longwave += ℐꜛ_new
            end
            ℐꜛ = ℐꜛ_new
        end

        # ---- Downward sweep: k = 1 → Nz (ℐꜜ) ------------------------
        # TOA boundary: ℐꜜˡʷ(TOA) = 0 (no longwave from space).
        ℐꜜ::NF = zero(NF)

        for k in 1:(Nz - 1)
            Δτ_k = williams_optical_depth_increment(k, ν̃, CO₂, T, q, pˢ, geometry, scheme, g)
            𝒯ₖ  = exp(-Δτ_k)
            B_k  = planck_wavenumber(T[k], ν̃)
            ℐꜜ_new::NF = ℐꜜ * 𝒯ₖ + Δν̃ * NF(π) * B_k * (1 - 𝒯ₖ)

            temperature_tendency[k]     -= flux_to_tendency(ℐꜜ_new / cᵖ, profile, geometry, constants, k)
            temperature_tendency[k + 1] += flux_to_tendency(ℐꜜ_new / cᵖ, profile, geometry, constants, k + 1)
            ℐꜜ = ℐꜜ_new
        end

        # Surface-adjacent layer: the downward flux that reaches the surface.
        Δτ_bottom = williams_optical_depth_increment(Nz, ν̃, CO₂, T, q, pˢ, geometry, scheme, g)
        𝒯ˢ = exp(-Δτ_bottom)
        B_bottom = planck_wavenumber(T[Nz], ν̃)
        ℐꜜ_surface::NF = ℐꜜ * 𝒯ˢ + Δν̃ * NF(π) * B_bottom * (1 - 𝒯ˢ)

        temperature_tendency[Nz] -= surface_flux_to_tendency(ℐꜜ_surface / cᵖ, profile, geometry, constants)
        surface_longwave_down += ℐꜜ_surface
    end

    diagnostics.outgoing_longwave         = outgoing_longwave
    diagnostics.surface_longwave_down     = surface_longwave_down
    diagnostics.ocean_surface_longwave_up = ℐꜛ_surface_ocean
    diagnostics.land_surface_longwave_up  = ℐꜛ_surface_land
    diagnostics.surface_longwave_up       = ℐꜛ_surface_broadband

    return nothing
end
