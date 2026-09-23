# ClearSkyEcCKDRadiation: a configured clear-sky ecCKD column scheme, the tabulated gas
# optics together with the prescribed mole fractions of the gases a host does not carry and
# the surface emissivity. Host couplings (SpeedyWeather's NumericalRadiation extension, Breeze) build the
# `ColumnAtmosphere` from their state, take the gases the host carries from there, every other
# gas from `mole_fractions`, and run the staged API with `scheme.gas_optics`.

export ClearSkyEcCKDRadiation, default_ozone_profile

"""
    default_ozone_profile(p)

Ozone mole fraction as a function of pressure `p` [Pa]: a Chapman-layer shape peaking at
8 ppmv near 30 hPa and vanishing towards the surface. The default `o3` prescription of
[`ClearSkyEcCKDRadiation`](@ref) for hosts without an ozone field; a crude stand-in for a climatology.
"""
@inline function default_ozone_profile(p)
    p₀ = oftype(p, 3000)
    return oftype(p, 8e-6) * (p / p₀) * exp(one(p) - p / p₀)
end

"""
    ClearSkyEcCKDRadiation{FT} <: AbstractRadiationScheme

Clear-sky ecCKD radiation as one configured column scheme: tabulated correlated-k
`gas_optics` ([`EcCKDTabulatedGasOpticsModel`](@ref)) for both streams, the prescribed
`mole_fractions` of the gases the host does not carry, and the longwave `surface_emissivity`.
Longwave and shortwave are solved clear-sky ([`CloudlessLongwave`](@ref),
[`CloudlessShortwave`](@ref)) from one evaluation of the gas optics.

Gas composition: `composite` (dry air) and `h2o` always come from the host's state. Every
other gas of the ecCKD model needs an entry in `mole_fractions`, a number (mole fraction) or a
function of pressure [Pa]; `o3` defaults to [`default_ozone_profile`](@ref) and `co2` to
280 ppm, and a host that carries CO₂ (SpeedyWeather's greenhouse gases) overrides `co2`.
Gases the ecCKD model knows but that were not requested when loading it stay at their
reference concentration.

```julia
using NumericalRadiation, NCDatasets
scheme = ClearSkyEcCKDRadiation(Float32, "32x32")                                  # reference tables
scheme = ClearSkyEcCKDRadiation(Float32, "64x96"; mole_fractions = (; co2 = 400e-6), surface_emissivity = 0.97)
gas_optics = read_reference_ecckd_gas_optics("32x32"; names = (:composite, :h2o, :o3, :co2, :ch4))
scheme = ClearSkyEcCKDRadiation(gas_optics; mole_fractions = (; ch4 = 1.8e-6))     # every extra gas must be prescribed
```
"""
struct ClearSkyEcCKDRadiation{FT, GO <: EcCKDTabulatedGasOpticsModel{FT}, MF <: NamedTuple} <: AbstractRadiationScheme
    "Tabulated ecCKD gas optics for both streams"
    gas_optics::GO
    "Prescribed mole fractions of the gases the host does not carry: numbers or functions of pressure [Pa]"
    mole_fractions::MF
    "Longwave emissivity of the surface [1]"
    surface_emissivity::FT
end

Adapt.@adapt_structure ClearSkyEcCKDRadiation

# gases every host takes from its own state
const HOST_GASES = (:composite, :h2o)

"""
    ClearSkyEcCKDRadiation(gas_optics::EcCKDTabulatedGasOpticsModel{FT}; ozone = default_ozone_profile,
                           mole_fractions = (;), surface_emissivity = 0.98)

Configure `gas_optics` into a [`ClearSkyEcCKDRadiation`](@ref). `ozone` is a shortcut for
`mole_fractions.o3`; `mole_fractions` overrides the defaults (`o3 = ozone`, `co2 = 280e-6`)
and prescribes every further gas of the model, an `ArgumentError` names a missing one.
Numbers are converted to `FT`."""
function ClearSkyEcCKDRadiation(gas_optics::EcCKDTabulatedGasOpticsModel{FT};
                        ozone = default_ozone_profile,
                        mole_fractions = (;),
                        surface_emissivity = 0.98) where FT
    fractions = merge((; o3 = ozone, co2 = FT(280e-6)), mole_fractions)
    fractions = map(x -> x isa Number ? FT(x) : x, fractions)
    for name in gas_names(gas_optics)
        name in HOST_GASES && continue
        haskey(fractions, name) || throw(ArgumentError(
            "the ecCKD model carries gas :$name; prescribe it with mole_fractions = (; $name = ...)"))
    end
    return ClearSkyEcCKDRadiation{FT, typeof(gas_optics), typeof(fractions)}(gas_optics, fractions, FT(surface_emissivity))
end

"""
    ClearSkyEcCKDRadiation{FT}(gas_optics::EcCKDTabulatedGasOpticsModel; kwargs...)

Convert `gas_optics` to the number format `FT` first."""
ClearSkyEcCKDRadiation{FT}(gas_optics::EcCKDTabulatedGasOpticsModel; kwargs...) where FT =
    ClearSkyEcCKDRadiation(EcCKDTabulatedGasOpticsModel{FT}(gas_optics); kwargs...)

"""
    ClearSkyEcCKDRadiation(FT::Type, model_pair; names = (:composite, :h2o, :o3, :co2), kwargs...)

Load the reference ecCKD `model_pair` (e.g. `"32x32"`, `"64x96"`) with the gases `names` through
[`read_reference_ecckd_gas_optics`](@ref) (NCDatasets must be loaded) in number format `FT`."""
ClearSkyEcCKDRadiation(FT::Type, model_pair::Union{Symbol, AbstractString, EcCKDModelSpec};
                       names = (:composite, :h2o, :o3, :co2), kwargs...) =
    ClearSkyEcCKDRadiation{FT}(read_reference_ecckd_gas_optics(model_pair; names); kwargs...)

Base.eltype(::ClearSkyEcCKDRadiation{FT}) where FT = FT

function Base.show(io::IO, scheme::ClearSkyEcCKDRadiation{FT}) where FT
    (; gas_optics) = scheme
    print(io, "ClearSkyEcCKDRadiation{", FT, "}(gases = ", gas_names(gas_optics),
          ", ", length(gas_optics.longwave_weights), " longwave × ", length(gas_optics.shortwave_weights),
          " shortwave g points, prescribed = ", keys(scheme.mole_fractions),
          ", surface_emissivity = ", scheme.surface_emissivity, ")")
end
