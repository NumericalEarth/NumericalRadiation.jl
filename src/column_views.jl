"""
$(TYPEDEF)

Vertical geometry for a single column expressed in sigma-pressure coordinates.

`σ_full` has length `nlayers` and gives the midpoint of each layer.
`σ_half` has length `nlayers + 1` and gives the layer interfaces.
`σ_thick = diff(σ_half)` has length `nlayers`.
"""
struct ColumnGrid{NF, V<:AbstractVector{NF}}
    σ_full::V
    σ_half::V
    σ_thick::V
end

function ColumnGrid(σ_half::AbstractVector{NF}) where NF
    nlayers = length(σ_half) - 1
    σ_full  = @views (σ_half[1:nlayers] .+ σ_half[2:end]) ./ 2
    σ_thick = diff(σ_half)
    return ColumnGrid{NF, typeof(σ_half)}(σ_full, σ_half, σ_thick)
end

"""
$(TYPEDEF)

Column thermodynamic profile and lower boundary quantities read by the
radiation solvers.

The arrays are indexed top-down: `k = 1` is the top of the atmosphere,
`k = nlayers` is the bottom (surface-adjacent) layer.
"""
struct AtmosphereProfile{NF, V<:AbstractVector{NF}}
    temperature::V
    humidity::V
    geopotential::V
    surface_pressure::NF
    rain_rate::NF
    CO₂::NF
end

AtmosphereProfile(; temperature, humidity, geopotential = similar(temperature, 0),
              surface_pressure, rain_rate = zero(eltype(temperature)), CO₂ = eltype(temperature)(280)) =
    AtmosphereProfile{eltype(temperature), typeof(temperature)}(
        temperature, humidity, geopotential, surface_pressure, rain_rate, CO₂)

"""
$(TYPEDEF)

Lower-boundary properties needed by the column radiation solvers.
`NaN` in `sea_surface_temperature` or `land_surface_temperature` means the
column has no ocean / no land respectively (the corresponding contribution
is skipped).
"""
struct SurfaceState{NF}
    sea_surface_temperature::NF
    land_surface_temperature::NF
    land_fraction::NF
    ocean_albedo::NF
    land_albedo::NF
    cos_zenith::NF
    ocean_emissivity::NF
    land_emissivity::NF
end

function SurfaceState{NF}(;
        sea_surface_temperature,
        land_surface_temperature,
        land_fraction,
        ocean_albedo     = zero(NF),
        land_albedo      = zero(NF),
        cos_zenith       = zero(NF),
        ocean_emissivity = one(NF),
        land_emissivity  = one(NF),
    ) where NF
    return SurfaceState{NF}(
        sea_surface_temperature, land_surface_temperature, land_fraction,
        ocean_albedo, land_albedo, cos_zenith,
        ocean_emissivity, land_emissivity,
    )
end

"""$(TYPEDSIGNATURES)
Construct a [`SurfaceState`](@ref). Floating-point type defaults to `Float64`.
"""
SurfaceState(::Type{NF}; kwargs...) where NF = SurfaceState{NF}(; kwargs...)

function SurfaceState(; sea_surface_temperature, land_surface_temperature,
                       land_fraction, kwargs...)
    NF = Float64
    return SurfaceState{NF}(;
        sea_surface_temperature  = convert(NF, sea_surface_temperature),
        land_surface_temperature = convert(NF, land_surface_temperature),
        land_fraction            = convert(NF, land_fraction),
        kwargs...)
end

"""
$(TYPEDEF)

Physical constants consumed by the column radiation solvers.
"""
struct PhysicalConstants{NF}
    gravity::NF
    heat_capacity::NF
    stefan_boltzmann::NF
    solar_constant::NF
end

function PhysicalConstants{NF}(;
        gravity          = NF(9.80665),
        heat_capacity    = NF(1004.64),
        stefan_boltzmann = NF(5.670374419e-8),
        solar_constant   = NF(1361),
    ) where NF
    return PhysicalConstants{NF}(gravity, heat_capacity, stefan_boltzmann, solar_constant)
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
default_earth_constants(::Type{NF}) where NF =
    (physical = PhysicalConstants{NF}(), thermodynamic = ThermodynamicConstants{NF}())

default_earth_constants() = default_earth_constants(Float64)

"""
$(TYPEDEF)

Clausius–Clapeyron saturation specific humidity at `(T, p)` given
`ThermodynamicConstants`. Returns `NaN` if the partial pressure is
unresolvable (e.g. zero total pressure).
"""
@inline function saturation_humidity(T, p, tc::ThermodynamicConstants)
    (; saturation_vapor_pressure_reference, latent_heat_condensation,
       gas_constant_vapor, freezing_temperature, molar_mass_ratio) = tc
    e_sat = saturation_vapor_pressure_reference *
            exp(latent_heat_condensation / gas_constant_vapor *
                (inv(freezing_temperature) - inv(T)))
    return molar_mass_ratio * e_sat / p
end

"""
$(TYPEDEF)

Column longwave diagnostic outputs written by [`solve_longwave!`](@ref).
"""
mutable struct LongwaveDiagnostics{NF}
    outgoing_longwave::NF
    surface_longwave_down::NF
    surface_longwave_up::NF
    ocean_surface_longwave_up::NF
    land_surface_longwave_up::NF
end

LongwaveDiagnostics(::Type{NF}) where NF = LongwaveDiagnostics{NF}()

LongwaveDiagnostics{NF}() where NF = LongwaveDiagnostics{NF}(
    zero(NF), zero(NF), zero(NF), zero(NF), zero(NF))

LongwaveDiagnostics() = LongwaveDiagnostics{Float64}()

"""
$(TYPEDEF)

Column shortwave diagnostic outputs written by [`solve_shortwave!`](@ref).
"""
mutable struct ShortwaveDiagnostics{NF}
    outgoing_shortwave::NF
    surface_shortwave_down::NF
    surface_shortwave_up::NF
    ocean_surface_shortwave_down::NF
    land_surface_shortwave_down::NF
    ocean_surface_shortwave_up::NF
    land_surface_shortwave_up::NF
    albedo::NF
    cloud_cover::NF
    cloud_top::Int
    stratocumulus_cover::NF
end

ShortwaveDiagnostics(::Type{NF}, nlayers::Integer = 1) where NF =
    ShortwaveDiagnostics{NF}(nlayers)

ShortwaveDiagnostics{NF}(nlayers::Integer = 1) where NF = ShortwaveDiagnostics{NF}(
    zero(NF), zero(NF), zero(NF), zero(NF), zero(NF), zero(NF), zero(NF),
    zero(NF), zero(NF), nlayers + 1, zero(NF))

ShortwaveDiagnostics(nlayers::Integer = 1) = ShortwaveDiagnostics{Float64}(nlayers)
