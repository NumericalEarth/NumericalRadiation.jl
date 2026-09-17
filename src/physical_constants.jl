#####
##### Physical constants
#####
#
# Every physical constant the package uses is defined here, once. Planet- and
# host-dependent values are fields of `PhysicalConstants` and
# `ThermodynamicConstants`, so a host model that supplies its own values sees
# them propagate through the staged runtime, the column schemes and the
# adapters; no solver, kernel or adapter carries a numeric literal of its own.
# The Earth defaults below are the only place those literals appear.

# Universal constants (CODATA 2018, exact by definition in the 2019 SI). They
# are not planet-dependent, so they are module constants rather than
# `PhysicalConstants` fields: `planck_wavenumber` reads them at any precision,
# and the ecCKD spectral-mapping reader weights intervals with c₂.
const PLANCK_CONSTANT = 6.62607015e-34          # h, J s
const SPEED_OF_LIGHT = 2.99792458e8             # c, m s⁻¹
const BOLTZMANN_CONSTANT = 1.380649e-23         # kᴮ, J K⁻¹
const SECOND_RADIATION_CONSTANT = 1.438776877   # c₂ = 100 h c / kᴮ, cm K

"""
$(TYPEDEF)

Physical constants consumed by the column radiation solvers, the staged
runtime (a [`ColumnAtmosphere`](@ref) carries one) and the RRTMGP adapter.
Hosts pass their own values through the keyword constructor; the fields and
their Earth defaults are

* `gravity` — `g`, 9.80665 m s⁻²
* `heat_capacity` — `cᵖ`, isobaric specific heat of dry air, 1004.64 J kg⁻¹ K⁻¹
* `stefan_boltzmann` — `σ`, 5.670374419e-8 W m⁻² K⁻⁴
* `solar_constant` — `S₀`, 1361 W m⁻²
* `dry_air_molar_mass` — `mᵈ`, 0.0289647 kg mol⁻¹ (the ecCKD/CKDMIP value)
* `water_molar_mass` — `mᵛ`, 0.01801528 kg mol⁻¹
* `dry_air_gas_constant` — `Rᵈ`, 287.05 J kg⁻¹ K⁻¹
* `universal_gas_constant` — `ℛ`, 8.31446261815324 J mol⁻¹ K⁻¹
* `avogadro_number` — `Nᴬ`, 6.02214076e23 mol⁻¹

The column schemes read `constants` duck-typed, so any object with the
properties they use works in their place.
"""
struct PhysicalConstants{NF}
    gravity::NF
    heat_capacity::NF
    stefan_boltzmann::NF
    solar_constant::NF
    dry_air_molar_mass::NF
    water_molar_mass::NF
    dry_air_gas_constant::NF
    universal_gas_constant::NF
    avogadro_number::NF
end

function PhysicalConstants{NF}(;
        gravity                = NF(9.80665),
        heat_capacity          = NF(1004.64),
        stefan_boltzmann       = NF(5.670374419e-8),
        solar_constant         = NF(1361),
        dry_air_molar_mass     = NF(0.0289647),
        water_molar_mass       = NF(0.01801528),
        dry_air_gas_constant   = NF(287.05),
        universal_gas_constant = NF(8.31446261815324),
        avogadro_number        = NF(6.02214076e23),
    ) where NF
    return PhysicalConstants{NF}(gravity, heat_capacity, stefan_boltzmann, solar_constant,
                                 dry_air_molar_mass, water_molar_mass, dry_air_gas_constant,
                                 universal_gas_constant, avogadro_number)
end

PhysicalConstants(::Type{NF}; kwargs...) where NF = PhysicalConstants{NF}(; kwargs...)

PhysicalConstants(; kwargs...) = PhysicalConstants{Float64}(; kwargs...)

"""
$(TYPEDEF)

Thermodynamic constants needed for saturation-humidity calculations used by
the diagnostic cloud scheme.
"""
struct ThermodynamicConstants{NF}
    saturation_vapor_pressure_reference::NF
    latent_heat_condensation::NF
    gas_constant_vapor::NF
    freezing_temperature::NF
    molar_mass_ratio::NF
end

function ThermodynamicConstants{NF}(;
        saturation_vapor_pressure_reference = NF(610.78),
        latent_heat_condensation            = NF(2.501e6),
        gas_constant_vapor                  = NF(461.50),
        freezing_temperature                = NF(273.15),
        molar_mass_ratio                    = NF(0.622),
    ) where NF
    return ThermodynamicConstants{NF}(
        saturation_vapor_pressure_reference,
        latent_heat_condensation,
        gas_constant_vapor,
        freezing_temperature,
        molar_mass_ratio,
    )
end

ThermodynamicConstants(::Type{NF}; kwargs...) where NF = ThermodynamicConstants{NF}(; kwargs...)

ThermodynamicConstants(; kwargs...) = ThermodynamicConstants{Float64}(; kwargs...)

"""$(TYPEDSIGNATURES)
Sensible Earth defaults for the full set of physical constants needed by the
shortwave solver (constants + thermodynamic constants).
"""
default_earth_constants(::Type{NF}) where NF = (physical=PhysicalConstants{NF}(), thermodynamic=ThermodynamicConstants{NF}())

default_earth_constants() = default_earth_constants(Float64)
