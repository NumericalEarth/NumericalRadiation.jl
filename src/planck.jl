"""
    planck_wavenumber(T, ν̃)

Spectral Planck radiance at temperature `T` [K] and wavenumber `ν̃` [cm⁻¹],
in units of W m⁻² sr⁻¹ (cm⁻¹)⁻¹.

The two-stream hemispherical flux source term is `π × planck_wavenumber(T, ν̃)`.
Integrating `π × planck_wavenumber(T, ν̃)` over all wavenumbers recovers the
Stefan–Boltzmann law σ T⁴.

The constants are the module's `PLANCK_CONSTANT`, `SPEED_OF_LIGHT` and
`BOLTZMANN_CONSTANT` (CODATA 2018).
"""
@inline function planck_wavenumber(T::NF, ν̃::NF) where NF
    h  = NF(PLANCK_CONSTANT)     # [J s]
    c  = NF(SPEED_OF_LIGHT)      # [m s⁻¹]
    kᴮ = NF(BOLTZMANN_CONSTANT)  # [J K⁻¹]
    ν̃ₘ = ν̃ * 100                 # cm⁻¹ → m⁻¹
    # Radiance per-m⁻¹, multiply by 100 to convert to per-cm⁻¹.
    return NF(100) * 2 * h * ν̃ₘ^3 * c^2 / (exp(h * c * ν̃ₘ / (kᴮ * T)) - 1)
end

@inline planck_wavenumber(T, ν̃) = planck_wavenumber(promote(T, ν̃)...)
