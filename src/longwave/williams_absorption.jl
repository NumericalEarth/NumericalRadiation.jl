# Analytic reference absorption coefficients for the Williams (2026) Simple
# Spectral Model. All three functions return the reference value at
# (T_ref, p_ref, RH_ref) = (260 K, 500 hPa, 100 %); pressure/temperature
# broadening is applied in `williams_delta_tau`.

"""
    h2o_line_kappa_ref(ν̃, scheme::AnalyticBandLongwave) -> κ  [m² kg⁻¹]

Reference H₂O line mass absorption coefficient. Piecewise-exponential fit to
the pure-rotation (200–1000 cm⁻¹), vibration–rotation (1000–1700 cm⁻¹) and
combination bands (1700–2500 cm⁻¹).

Reference: Williams (2026), Eq. 4 and Table 1.
"""
@inline function h2o_line_kappa_ref(ν̃, scheme)
    NF = typeof(ν̃)
    (; κ_rot, l_rot, κ_vr, l_vr1, l_vr2) = scheme
    if ν̃ <= 200
        return NF(κ_rot)
    elseif ν̃ <= 1000
        return NF(κ_rot * exp(-(ν̃ - 200) / l_rot))
    elseif ν̃ <= 1450
        return NF(κ_vr * exp(-(1450 - ν̃) / l_vr1))
    elseif ν̃ <= 1700
        return NF(κ_vr)
    elseif ν̃ <= 2500
        return NF(κ_vr * exp(-(ν̃ - 1700) / l_vr2))
    else
        return zero(NF)
    end
end

"""
    co2_kappa_ref(ν̃, scheme::AnalyticBandLongwave) -> κ  [m² kg⁻¹]

Reference CO₂ absorption coefficient. A two-sided exponential (Laplace-shaped)
wing centred on the 15 μm bending mode at ν̃_CO₂ ≈ 667 cm⁻¹, active only in
[500, 850] cm⁻¹.

Reference: Williams (2026), Eq. 5.
"""
@inline function co2_kappa_ref(ν̃, scheme)
    NF = typeof(ν̃)
    (; κ_CO₂, l_CO₂, ν̃_CO₂) = scheme
    return ifelse(ν̃ > 500 && ν̃ < 850,
                  NF(κ_CO₂ * exp(-abs(ν̃ - ν̃_CO₂) / l_CO₂)),
                  zero(NF))
end

"""
    h2o_cont_kappa_ref(ν̃, scheme::AnalyticBandLongwave) -> κ  [m² kg⁻¹]

Reference H₂O continuum absorption. Two gray values split at 1700 cm⁻¹
(stronger in the main atmospheric window below).

Reference: Williams (2026), Eq. 6.
"""
@inline function h2o_cont_kappa_ref(ν̃, scheme)
    NF = typeof(ν̃)
    # Paper convention: [10, 1700) → κ_cnt1, [1700, 2500] → κ_cnt2.
    return ν̃ < 1700 ? NF(scheme.κ_cnt1) : NF(scheme.κ_cnt2)
end

"""
$(TYPEDSIGNATURES)

Optical depth increment through layer `k` at wavenumber `ν̃`. Combines H₂O
line absorption (Williams 2026, Eq. 7), H₂O continuum (Eq. 8) and CO₂ (Eq. 9).
The result already includes the two-stream diffusivity factor `D ≈ 1.5`
(Armstrong 1968).

`temperature` and `humidity` are length-`nlayers` column vectors; `geometry`
is a [`ColumnGrid`](@ref).
"""
@inline function williams_delta_tau(k::Integer, ν̃::NF, CO₂::NF,
                                     temperature::AbstractVector, humidity::AbstractVector,
                                     surface_pressure::Real,
                                     geometry::ColumnGrid,
                                     scheme, gravity::Real) where NF
    σ_full  = geometry.σ_full
    σ_half  = geometry.σ_half
    σ_thick = geometry.σ_thick

    pₛ = NF(surface_pressure)
    p_full_k = NF(σ_full[k]) * pₛ
    Δp_k     = NF(σ_thick[k]) * pₛ
    T_k      = NF(temperature[k])
    q_k      = NF(humidity[k])
    g        = NF(gravity)

    # H₂O line: κ ∝ p / p_ref
    κ_line = h2o_line_kappa_ref(ν̃, scheme)
    Δτ_h2o_line = κ_line * (p_full_k / NF(scheme.p_ref)) * q_k * Δp_k / g

    # H₂O continuum: self-broadening + temperature scaling
    # Vapor partial pressure: pᵥ = q p / (ε + (1 − ε) q), ε ≈ 0.622
    p_v_k   = q_k * p_full_k / (NF(0.622) + NF(0.378) * q_k)
    κ_cont  = h2o_cont_kappa_ref(ν̃, scheme)
    Δτ_h2o_cont = κ_cont * (p_v_k / NF(scheme.pv_ref)) *
                  exp(NF(scheme.σ_cont) * (NF(scheme.T_ref) - T_k)) *
                  q_k * Δp_k / g

    # CO₂ (well-mixed): analytic integral across the layer.
    # For a well-mixed gas with κ ∝ p / p_ref the column integral from the TOA
    # to pressure p gives τ = D κ q_CO₂ p² / (2 g p_ref). The layer increment
    # is the difference of τ at the two bounding half levels.
    q_co2 = NF(CO₂ * NF(1e-6) * 44 / 29)
    κ_CO₂_v = co2_kappa_ref(ν̃, scheme)
    p_half_k   = NF(σ_half[k])   * pₛ
    p_half_kp1 = NF(σ_half[k+1]) * pₛ
    Δτ_co2 = κ_CO₂_v * q_co2 * (p_half_kp1^2 - p_half_k^2) / (2 * g * NF(scheme.p_ref))

    return NF(scheme.diffusivity) * (Δτ_h2o_line + Δτ_h2o_cont + Δτ_co2)
end
