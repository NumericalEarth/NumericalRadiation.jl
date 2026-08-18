"""
$(TYPEDEF)

Small ecCKD-style forward gas-optics model for staged runtime integration.

This type is intentionally limited to fixed, already-interpolated coefficient
tables. It gives host models an allocation-free runtime path from gas columns
to longwave and shortwave optical properties.

`longwave_absorption` and `shortwave_absorption` are shaped `(ng, ngas)`.
Gas values in [`ColumnAtmosphere`](@ref) are interpreted as layer absorber
amounts. A gas value may be a scalar, in which case it is applied to every
layer, or a vector with one entry per layer.

Fields are

$(TYPEDFIELDS)
"""
struct EcCKDGasOpticsModel{FT, GasNames, LWA, SWA, LWS, LWW, SWW} <: AbstractGasOpticsModel
    "Longwave absorption coefficients with shape `(ng_lw, ngas)`."
    longwave_absorption::LWA
    "Shortwave absorption coefficients with shape `(ng_sw, ngas)`."
    shortwave_absorption::SWA
    "Longwave source scaling per g-point."
    longwave_source_scale::LWS
    "Longwave spectral weights."
    longwave_weights::LWW
    "Shortwave spectral weights."
    shortwave_weights::SWW
end

function Adapt.adapt_structure(to, model::EcCKDGasOpticsModel{FT, GasNames}) where {FT, GasNames}
    longwave_absorption = Adapt.adapt(to, model.longwave_absorption)
    shortwave_absorption = Adapt.adapt(to, model.shortwave_absorption)
    longwave_source_scale = Adapt.adapt(to, model.longwave_source_scale)
    longwave_weights = Adapt.adapt(to, model.longwave_weights)
    shortwave_weights = Adapt.adapt(to, model.shortwave_weights)
    return EcCKDGasOpticsModel{FT, GasNames,
                               typeof(longwave_absorption),
                               typeof(shortwave_absorption),
                               typeof(longwave_source_scale),
                               typeof(longwave_weights),
                               typeof(shortwave_weights)}(
        longwave_absorption,
        shortwave_absorption,
        longwave_source_scale,
        longwave_weights,
        shortwave_weights,
    )
end

function EcCKDGasOpticsModel(; gas_names,
                             longwave_absorption::AbstractMatrix,
                             shortwave_absorption::AbstractMatrix,
                             longwave_source_scale = nothing,
                             longwave_weights = nothing,
                             shortwave_weights = nothing)
    FT = promote_type(eltype(longwave_absorption), eltype(shortwave_absorption))
    lw_source = longwave_source_scale === nothing ?
        ones(FT, size(longwave_absorption, 1)) : longwave_source_scale
    lw_weights = longwave_weights === nothing ?
        fill(inv(FT(size(longwave_absorption, 1))), size(longwave_absorption, 1)) :
        longwave_weights
    sw_weights = shortwave_weights === nothing ?
        fill(inv(FT(size(shortwave_absorption, 1))), size(shortwave_absorption, 1)) :
        shortwave_weights

    ngas = length(gas_names)
    size(longwave_absorption, 2) == ngas ||
        throw(DimensionMismatch("longwave_absorption gas dimension must match gas_names"))
    size(shortwave_absorption, 2) == ngas ||
        throw(DimensionMismatch("shortwave_absorption gas dimension must match gas_names"))
    length(lw_source) == size(longwave_absorption, 1) ||
        throw(DimensionMismatch("longwave_source_scale must have length ng_lw"))
    length(lw_weights) == size(longwave_absorption, 1) ||
        throw(DimensionMismatch("longwave_weights must have length ng_lw"))
    length(sw_weights) == size(shortwave_absorption, 1) ||
        throw(DimensionMismatch("shortwave_weights must have length ng_sw"))

    gas_name_tuple = Tuple(Symbol.(gas_names))
    return EcCKDGasOpticsModel{FT, gas_name_tuple,
                               typeof(longwave_absorption),
                               typeof(shortwave_absorption),
                               typeof(lw_source),
                               typeof(lw_weights),
                               typeof(sw_weights)}(
        longwave_absorption,
        shortwave_absorption,
        lw_source,
        lw_weights,
        sw_weights,
    )
end

Base.eltype(::EcCKDGasOpticsModel{FT}) where FT = FT
gas_names(::EcCKDGasOpticsModel{<:Any, GasNames}) where GasNames = GasNames

"""
$(TYPEDEF)

ecCKD-style tabulated gas-optics model with bilinear pressure/temperature
interpolation.

`longwave_absorption` and `shortwave_absorption` are shaped
`(ng, ngas, npressure, ntemperature)`. The runtime method interpolates
coefficients for each layer, multiplies them by layer absorber amounts from
[`ColumnAtmosphere`](@ref), and writes caller-owned optical-property arrays.

Fields are

$(TYPEDFIELDS)
"""
struct EcCKDTabulatedGasOpticsModel{FT, GasNames, PG, TG, HG, GREF, LWA, SWA, LHWA, SHWA, SWR, LWS, LST, LSTB, LWW, SWW} <:
       AbstractGasOpticsModel
    "Pressure grid for coefficient tables."
    pressure_grid::PG
    "Temperature grid for coefficient tables."
    temperature_grid::TG
    "Optional H2O mole-fraction grid for official H2O coefficient tables."
    h2o_mole_fraction_grid::HG
    "Reference mole fractions for relative-linear gases, aligned with gas_names."
    gas_reference_mole_fractions::GREF
    "Longwave absorption coefficients with shape `(ng_lw, ngas, np, nt)`."
    longwave_absorption::LWA
    "Shortwave absorption coefficients with shape `(ng_sw, ngas, np, nt)`."
    shortwave_absorption::SWA
    "Optional longwave H2O absorption coefficients with shape `(ng_lw, np, nt, nh2o)`."
    longwave_h2o_absorption::LHWA
    "Optional shortwave H2O absorption coefficients with shape `(ng_sw, np, nt, nh2o)`."
    shortwave_h2o_absorption::SHWA
    "Optional shortwave Rayleigh molar scattering coefficients with length `ng_sw`."
    shortwave_rayleigh_molar_scattering::SWR
    "Longwave source scaling per g-point."
    longwave_source_scale::LWS
    "Optional longwave source temperature grid."
    longwave_source_temperature_grid::LST
    "Optional longwave source table with shape `(ng_lw, ntemperature)`."
    longwave_source_table::LSTB
    "Longwave spectral weights."
    longwave_weights::LWW
    "Shortwave spectral weights."
    shortwave_weights::SWW
end

function Adapt.adapt_structure(to, model::EcCKDTabulatedGasOpticsModel{FT, GasNames}) where {FT, GasNames}
    pressure_grid = Adapt.adapt(to, model.pressure_grid)
    temperature_grid = Adapt.adapt(to, model.temperature_grid)
    h2o_mole_fraction_grid = Adapt.adapt(to, model.h2o_mole_fraction_grid)
    longwave_absorption = Adapt.adapt(to, model.longwave_absorption)
    shortwave_absorption = Adapt.adapt(to, model.shortwave_absorption)
    longwave_h2o_absorption = Adapt.adapt(to, model.longwave_h2o_absorption)
    shortwave_h2o_absorption = Adapt.adapt(to, model.shortwave_h2o_absorption)
    shortwave_rayleigh_molar_scattering = Adapt.adapt(to, model.shortwave_rayleigh_molar_scattering)
    gas_reference_mole_fractions = Adapt.adapt(to, model.gas_reference_mole_fractions)
    longwave_source_scale = Adapt.adapt(to, model.longwave_source_scale)
    longwave_source_temperature_grid = Adapt.adapt(to, model.longwave_source_temperature_grid)
    longwave_source_table = Adapt.adapt(to, model.longwave_source_table)
    longwave_weights = Adapt.adapt(to, model.longwave_weights)
    shortwave_weights = Adapt.adapt(to, model.shortwave_weights)
    return EcCKDTabulatedGasOpticsModel{FT, GasNames,
                                        typeof(pressure_grid),
                                        typeof(temperature_grid),
                                        typeof(h2o_mole_fraction_grid),
                                        typeof(gas_reference_mole_fractions),
                                        typeof(longwave_absorption),
                                        typeof(shortwave_absorption),
                                        typeof(longwave_h2o_absorption),
                                        typeof(shortwave_h2o_absorption),
                                        typeof(shortwave_rayleigh_molar_scattering),
                                        typeof(longwave_source_scale),
                                        typeof(longwave_source_temperature_grid),
                                        typeof(longwave_source_table),
                                        typeof(longwave_weights),
                                        typeof(shortwave_weights)}(
        pressure_grid,
        temperature_grid,
        h2o_mole_fraction_grid,
        gas_reference_mole_fractions,
        longwave_absorption,
        shortwave_absorption,
        longwave_h2o_absorption,
        shortwave_h2o_absorption,
        shortwave_rayleigh_molar_scattering,
        longwave_source_scale,
        longwave_source_temperature_grid,
        longwave_source_table,
        longwave_weights,
        shortwave_weights,
    )
end

function EcCKDTabulatedGasOpticsModel(; gas_names,
                                      pressure_grid::AbstractVector,
                                      temperature_grid,
                                      h2o_mole_fraction_grid = Float64[],
                                      gas_reference_mole_fractions = nothing,
                                      longwave_absorption::AbstractArray{<:Any, 4},
                                      shortwave_absorption::AbstractArray{<:Any, 4},
                                      longwave_h2o_absorption = nothing,
                                      shortwave_h2o_absorption = nothing,
                                      shortwave_rayleigh_molar_scattering = nothing,
                                      longwave_source_scale = nothing,
                                      longwave_source_temperature_grid = nothing,
                                      longwave_source_table = nothing,
                                      longwave_weights = nothing,
                                      shortwave_weights = nothing)
    source_types = longwave_source_table === nothing ?
        () :
        (eltype(longwave_source_temperature_grid), eltype(longwave_source_table))
    FT = promote_type(eltype(pressure_grid), eltype(temperature_grid),
                      eltype(longwave_absorption), eltype(shortwave_absorption),
                      source_types...)
    h2o_grid = collect(FT, h2o_mole_fraction_grid)
    lw_h2o = longwave_h2o_absorption === nothing ?
        zeros(FT, 0, 0, 0, 0) : FT.(longwave_h2o_absorption)
    sw_h2o = shortwave_h2o_absorption === nothing ?
        zeros(FT, 0, 0, 0, 0) : FT.(shortwave_h2o_absorption)
    lw_source = longwave_source_scale === nothing ?
        ones(FT, size(longwave_absorption, 1)) : longwave_source_scale
    lw_weights = longwave_weights === nothing ?
        fill(inv(FT(size(longwave_absorption, 1))), size(longwave_absorption, 1)) :
        longwave_weights
    sw_weights = shortwave_weights === nothing ?
        fill(inv(FT(size(shortwave_absorption, 1))), size(shortwave_absorption, 1)) :
        shortwave_weights
    sw_rayleigh = shortwave_rayleigh_molar_scattering === nothing ?
        zeros(FT, size(shortwave_absorption, 1)) :
        shortwave_rayleigh_molar_scattering
    gas_refs = gas_reference_mole_fractions === nothing ?
        zeros(FT, length(gas_names)) : FT.(gas_reference_mole_fractions)

    ngas = length(gas_names)
    length(pressure_grid) >= 2 ||
        throw(DimensionMismatch("pressure_grid must contain at least two points"))
    _temperature_grid_length(temperature_grid) >= 2 ||
        throw(DimensionMismatch("temperature_grid must contain at least two points"))
    size(longwave_absorption, 2) == ngas ||
        throw(DimensionMismatch("longwave_absorption gas dimension must match gas_names"))
    size(shortwave_absorption, 2) == ngas ||
        throw(DimensionMismatch("shortwave_absorption gas dimension must match gas_names"))
    size(longwave_absorption, 3) == length(pressure_grid) ||
        throw(DimensionMismatch("longwave_absorption pressure dimension must match pressure_grid"))
    size(shortwave_absorption, 3) == length(pressure_grid) ||
        throw(DimensionMismatch("shortwave_absorption pressure dimension must match pressure_grid"))
    size(longwave_absorption, 4) == _temperature_grid_length(temperature_grid) ||
        throw(DimensionMismatch("longwave_absorption temperature dimension must match temperature_grid"))
    size(shortwave_absorption, 4) == _temperature_grid_length(temperature_grid) ||
        throw(DimensionMismatch("shortwave_absorption temperature dimension must match temperature_grid"))
    if length(h2o_grid) > 0
        length(h2o_grid) >= 2 ||
            throw(DimensionMismatch("h2o_mole_fraction_grid must contain at least two points when supplied"))
        size(lw_h2o) == (size(longwave_absorption, 1), length(pressure_grid),
                         _temperature_grid_length(temperature_grid), length(h2o_grid)) ||
            throw(DimensionMismatch("longwave_h2o_absorption must have shape (ng_lw, np, nt, nh2o)"))
        size(sw_h2o) == (size(shortwave_absorption, 1), length(pressure_grid),
                         _temperature_grid_length(temperature_grid), length(h2o_grid)) ||
            throw(DimensionMismatch("shortwave_h2o_absorption must have shape (ng_sw, np, nt, nh2o)"))
    end
    length(lw_source) == size(longwave_absorption, 1) ||
        throw(DimensionMismatch("longwave_source_scale must have length ng_lw"))
    if longwave_source_table !== nothing
        longwave_source_temperature_grid === nothing &&
            throw(DimensionMismatch("longwave_source_temperature_grid is required with longwave_source_table"))
        size(longwave_source_table, 1) == size(longwave_absorption, 1) ||
            throw(DimensionMismatch("longwave_source_table first dimension must match ng_lw"))
        size(longwave_source_table, 2) == length(longwave_source_temperature_grid) ||
            throw(DimensionMismatch("longwave_source_table temperature dimension must match longwave_source_temperature_grid"))
    end
    length(lw_weights) == size(longwave_absorption, 1) ||
        throw(DimensionMismatch("longwave_weights must have length ng_lw"))
    length(sw_weights) == size(shortwave_absorption, 1) ||
        throw(DimensionMismatch("shortwave_weights must have length ng_sw"))
    length(sw_rayleigh) == size(shortwave_absorption, 1) ||
        throw(DimensionMismatch("shortwave_rayleigh_molar_scattering must have length ng_sw"))
    length(gas_refs) == ngas ||
        throw(DimensionMismatch("gas_reference_mole_fractions must match gas_names length"))

    gas_name_tuple = Tuple(Symbol.(gas_names))
    return EcCKDTabulatedGasOpticsModel{FT, gas_name_tuple,
                                        typeof(pressure_grid),
                                        typeof(temperature_grid),
                                        typeof(h2o_grid),
                                        typeof(gas_refs),
                                        typeof(longwave_absorption),
                                        typeof(shortwave_absorption),
                                        typeof(lw_h2o),
                                        typeof(sw_h2o),
                                        typeof(sw_rayleigh),
                                        typeof(lw_source),
                                        typeof(longwave_source_temperature_grid),
                                        typeof(longwave_source_table),
                                        typeof(lw_weights),
                                        typeof(sw_weights)}(
        pressure_grid,
        temperature_grid,
        h2o_grid,
        gas_refs,
        longwave_absorption,
        shortwave_absorption,
        lw_h2o,
        sw_h2o,
        sw_rayleigh,
        lw_source,
        longwave_source_temperature_grid,
        longwave_source_table,
        lw_weights,
        sw_weights,
    )
end

Base.eltype(::EcCKDTabulatedGasOpticsModel{FT}) where FT = FT
gas_names(::EcCKDTabulatedGasOpticsModel{<:Any, GasNames}) where GasNames = GasNames

@inline function _gas_value(gases::NamedTuple, name::Symbol, k)
    value = getproperty(gases, name)
    return value isa Number ? value : value[k]
end

# Gas containers are keyed by `Symbol` throughout. A `String`-keyed container
# must fail here rather than fall back silently: the `haskey(gases, :composite)`
# guards below would miss its keys and quietly change the optical depth.
@inline function _gas_value(gases::AbstractDict, name::Symbol, k)
    value = gases[name]
    return value isa Number ? value : value[k]
end

@inline _gas_value(gases::AbstractMatrix, igas::Integer, k) = gases[igas, k]

@inline _gas_value(gases, name::Symbol, k) = begin
    value = getproperty(gases, name)
    value isa Number ? value : value[k]
end

@inline _source_temperature(atmosphere::ColumnAtmosphere, k) =
    atmosphere.temperature_layers[k]

@inline function _bracket(grid, x)
    x <= grid[begin] && return firstindex(grid), firstindex(grid) + 1, zero(eltype(grid))
    last = lastindex(grid)
    x >= grid[last] && return last - 1, last, one(eltype(grid))

    lo = firstindex(grid)
    hi = last
    while hi - lo > 1
        mid = (lo + hi) >>> 1
        if x < grid[mid]
            hi = mid
        else
            lo = mid
        end
    end
    weight = (x - grid[lo]) / (grid[hi] - grid[lo])
    return lo, hi, weight
end

@inline function _log_bracket(grid, x)
    x_positive = max(x, grid[begin])
    index = one(eltype(grid)) +
        clamp((log(x_positive) - log(grid[begin])) / (log(grid[begin + 1]) - log(grid[begin])),
              zero(eltype(grid)),
              eltype(grid)(length(grid)) - eltype(grid)(1.0001))
    lo = Int(floor(index))
    return lo, lo + 1, index - lo
end

@inline _temperature_grid_length(grid::AbstractVector) = length(grid)
@inline _temperature_grid_length(grid::AbstractMatrix) = size(grid, 2)

@inline function _pressure_bracket(pressure_grid, pressure)
    return _log_bracket(pressure_grid, pressure)
end

@inline function _interp_table(table::AbstractArray{FT, 4},
                               ig,
                               j,
                               pressure,
                               temperature,
                               pressure_grid,
                               temperature_grid) where FT
    ip0, ip1, wp = _bracket(pressure_grid, pressure)
    it0, it1, wt = _bracket(temperature_grid, temperature)
    c00 = table[ig, j, ip0, it0]
    c10 = table[ig, j, ip1, it0]
    c01 = table[ig, j, ip0, it1]
    c11 = table[ig, j, ip1, it1]
    cp0 = c00 + wp * (c10 - c00)
    cp1 = c01 + wp * (c11 - c01)
    return cp0 + wt * (cp1 - cp0)
end

@inline function _interp_table(table::AbstractArray{FT, 4},
                               ig,
                               j,
                               pressure,
                               temperature,
                               pressure_grid,
                               temperature_grid::AbstractMatrix) where FT
    ip0, ip1, wp = _pressure_bracket(pressure_grid, pressure)
    temperature_origin = (one(FT) - wp) * temperature_grid[ip0, 1] +
                         wp * temperature_grid[ip1, 1]
    temperature_step = temperature_grid[1, 2] - temperature_grid[1, 1]
    temperature_index = one(FT) + clamp((temperature - temperature_origin) / temperature_step,
                                        zero(FT),
                                        FT(size(temperature_grid, 2)) - FT(1.0001))
    it0 = Int(floor(temperature_index))
    it1 = it0 + 1
    wt = temperature_index - it0

    c00 = table[ig, j, ip0, it0]
    c10 = table[ig, j, ip1, it0]
    c01 = table[ig, j, ip0, it1]
    c11 = table[ig, j, ip1, it1]
    cp0 = c00 + wp * (c10 - c00)
    cp1 = c01 + wp * (c11 - c01)
    return cp0 + wt * (cp1 - cp0)
end

@inline function _interp_source_table(table::AbstractMatrix{FT},
                                      temperature_grid,
                                      ig,
                                      temperature) where FT
    it0, it1, wt = _bracket(temperature_grid, temperature)
    return table[ig, it0] + wt * (table[ig, it1] - table[ig, it0])
end

@inline function _interp_h2o_table(table::AbstractArray{FT, 4},
                                   ig,
                                   pressure,
                                   temperature,
                                   h2o_mole_fraction,
                                   pressure_grid,
                                   temperature_grid::AbstractMatrix,
                                   h2o_grid) where FT
    ip0, ip1, wp = _pressure_bracket(pressure_grid, pressure)
    temperature_origin = (one(FT) - wp) * temperature_grid[ip0, 1] +
                         wp * temperature_grid[ip1, 1]
    temperature_step = temperature_grid[1, 2] - temperature_grid[1, 1]
    temperature_index = one(FT) + clamp((temperature - temperature_origin) / temperature_step,
                                        zero(FT),
                                        FT(size(temperature_grid, 2)) - FT(1.0001))
    it0 = Int(floor(temperature_index))
    it1 = it0 + 1
    wt = temperature_index - it0
    ih0, ih1, wh = _log_bracket(h2o_grid, h2o_mole_fraction)

    c000 = table[ig, ip0, it0, ih0]
    c100 = table[ig, ip1, it0, ih0]
    c010 = table[ig, ip0, it1, ih0]
    c110 = table[ig, ip1, it1, ih0]
    c001 = table[ig, ip0, it0, ih1]
    c101 = table[ig, ip1, it0, ih1]
    c011 = table[ig, ip0, it1, ih1]
    c111 = table[ig, ip1, it1, ih1]

    c00 = c000 + wp * (c100 - c000)
    c10 = c010 + wp * (c110 - c010)
    c01 = c001 + wp * (c101 - c001)
    c11 = c011 + wp * (c111 - c011)
    ct0 = c00 + wt * (c10 - c00)
    ct1 = c01 + wt * (c11 - c01)
    return ct0 + wh * (ct1 - ct0)
end

@inline function _interp_h2o_table(table::AbstractArray{FT, 4},
                                   ig,
                                   pressure,
                                   temperature,
                                   h2o_mole_fraction,
                                   pressure_grid,
                                   temperature_grid::AbstractVector,
                                   h2o_grid) where FT
    ip0, ip1, wp = _bracket(pressure_grid, pressure)
    it0, it1, wt = _bracket(temperature_grid, temperature)
    ih0, ih1, wh = _log_bracket(h2o_grid, h2o_mole_fraction)

    c000 = table[ig, ip0, it0, ih0]
    c100 = table[ig, ip1, it0, ih0]
    c010 = table[ig, ip0, it1, ih0]
    c110 = table[ig, ip1, it1, ih0]
    c001 = table[ig, ip0, it0, ih1]
    c101 = table[ig, ip1, it0, ih1]
    c011 = table[ig, ip0, it1, ih1]
    c111 = table[ig, ip1, it1, ih1]

    c00 = c000 + wp * (c100 - c000)
    c10 = c010 + wp * (c110 - c010)
    c01 = c001 + wp * (c101 - c001)
    c11 = c011 + wp * (c111 - c011)
    ct0 = c00 + wt * (c10 - c00)
    ct1 = c01 + wt * (c11 - c01)
    return ct0 + wh * (ct1 - ct0)
end

@inline function _longwave_source(model::EcCKDTabulatedGasOpticsModel{FT},
                                  ig,
                                  temperature) where FT
    if model.longwave_source_table === nothing
        return model.longwave_source_scale[ig] * FT(5.670374419e-8) * temperature^4
    end
    return _interp_source_table(model.longwave_source_table,
                                model.longwave_source_temperature_grid,
                                ig,
                                temperature)
end

@generated function _accumulate_tau(gases::NamedTuple,
                                    coefficients::AbstractMatrix{FT},
                                    ::Val{GasNames},
                                    ig,
                                    k) where {FT, GasNames}
    terms = [
        :(coefficients[ig, $j] * FT(_gas_value(gases, $(QuoteNode(name)), k)))
        for (j, name) in enumerate(GasNames)
    ]
    isempty(terms) && return :(zero(FT))
    return foldl((a, b) -> :($a + $b), terms; init = :(zero(FT)))
end

@inline function _accumulate_tau(gases,
                                 coefficients::AbstractMatrix{FT},
                                 gas_names::Tuple,
                                 ig,
                                 k) where FT
    tau = zero(FT)
    for j in eachindex(gas_names)
        tau += coefficients[ig, j] * FT(_gas_value(gases, gas_names[j], k))
    end
    return tau
end

@inline _accumulate_tau(gases,
                        coefficients::AbstractMatrix{FT},
                        ::Val{GasNames},
                        ig,
                        k) where {FT, GasNames} =
    _accumulate_tau(gases, coefficients, GasNames, ig, k)

@generated function _accumulate_tabulated_tau(gases::NamedTuple,
                                              coefficients::AbstractArray{FT, 4},
                                              gas_reference_mole_fractions,
                                              ::Val{GasNames},
                                              ig,
                                              k,
                                              pressure,
                                              temperature,
                                              pressure_grid,
                                              temperature_grid) where {FT, GasNames}
    gas_fields = fieldnames(gases)
    has_composite = :composite in gas_fields
    terms = Expr[]
    for (j, name) in enumerate(GasNames)
        amount = :(FT(_gas_value(gases, $(QuoteNode(name)), k)))
        if has_composite
            amount = :($amount -
                       FT(gas_reference_mole_fractions[$j]) *
                       FT(_gas_value(gases, :composite, k)))
        end
        push!(terms,
              :(_interp_table(coefficients, ig, $j, pressure, temperature,
                              pressure_grid, temperature_grid) * $amount))
    end
    isempty(terms) && return :(zero(FT))
    return foldl((a, b) -> :($a + $b), terms; init = :(zero(FT)))
end

@inline function _accumulate_tabulated_tau(gases,
                                           coefficients::AbstractArray{FT, 4},
                                           gas_names::Tuple,
                                           gas_reference_mole_fractions,
                                           ig,
                                           k,
                                           pressure,
                                           temperature,
                                           pressure_grid,
                                           temperature_grid) where FT
    tau = zero(FT)
    for j in eachindex(gas_names)
        amount = FT(_gas_value(gases, gas_names[j], k))
        reference = FT(gas_reference_mole_fractions[j])
        if reference != zero(FT) && haskey(gases, :composite)
            amount -= reference * FT(_gas_value(gases, :composite, k))
        end
        tau += _interp_table(coefficients, ig, j, pressure, temperature,
                             pressure_grid, temperature_grid) *
               amount
    end
    return tau
end

@inline _accumulate_tabulated_tau(gases,
                                  coefficients::AbstractArray{FT, 4},
                                  gas_reference_mole_fractions,
                                  ::Val{GasNames},
                                  ig,
                                  k,
                                  pressure,
                                  temperature,
                                  pressure_grid,
                                  temperature_grid) where {FT, GasNames} =
    _accumulate_tabulated_tau(gases, coefficients, GasNames,
                              gas_reference_mole_fractions, ig, k, pressure,
                              temperature, pressure_grid, temperature_grid)

function _check_ecCKD_optics_shapes(longwave::LongwaveOpticalProperties,
                                    shortwave::ShortwaveOpticalProperties,
                                    model::EcCKDGasOpticsModel,
                                    atmosphere::ColumnAtmosphere)
    nlayers = length(atmosphere.temperature_layers)
    size(longwave.optical_depth) == (size(model.longwave_absorption, 1), nlayers) ||
        throw(DimensionMismatch("longwave optical_depth must have shape (ng_lw, nlayers)"))
    size(longwave.source) == size(longwave.optical_depth) ||
        throw(DimensionMismatch("longwave source must have shape (ng_lw, nlayers)"))
    longwave.source_top === nothing || size(longwave.source_top) == size(longwave.optical_depth) ||
        throw(DimensionMismatch("longwave source_top must have shape (ng_lw, nlayers)"))
    longwave.source_bottom === nothing || size(longwave.source_bottom) == size(longwave.optical_depth) ||
        throw(DimensionMismatch("longwave source_bottom must have shape (ng_lw, nlayers)"))
    size(shortwave.optical_depth) == (size(model.shortwave_absorption, 1), nlayers) ||
        throw(DimensionMismatch("shortwave optical_depth must have shape (ng_sw, nlayers)"))
    size(shortwave.rayleigh_optical_depth) == size(shortwave.optical_depth) ||
        throw(DimensionMismatch("shortwave rayleigh_optical_depth must have shape (ng_sw, nlayers)"))
    length(longwave.weights) == size(model.longwave_absorption, 1) ||
        throw(DimensionMismatch("longwave weights must have length ng_lw"))
    length(shortwave.weights) == size(model.shortwave_absorption, 1) ||
        throw(DimensionMismatch("shortwave weights must have length ng_sw"))
    return nothing
end

function _check_ecCKD_optics_shapes(longwave::LongwaveOpticalProperties,
                                    shortwave::ShortwaveOpticalProperties,
                                    model::EcCKDTabulatedGasOpticsModel,
                                    atmosphere::ColumnAtmosphere)
    nlayers = length(atmosphere.temperature_layers)
    size(longwave.optical_depth) == (size(model.longwave_absorption, 1), nlayers) ||
        throw(DimensionMismatch("longwave optical_depth must have shape (ng_lw, nlayers)"))
    size(longwave.source) == size(longwave.optical_depth) ||
        throw(DimensionMismatch("longwave source must have shape (ng_lw, nlayers)"))
    longwave.source_top === nothing || size(longwave.source_top) == size(longwave.optical_depth) ||
        throw(DimensionMismatch("longwave source_top must have shape (ng_lw, nlayers)"))
    longwave.source_bottom === nothing || size(longwave.source_bottom) == size(longwave.optical_depth) ||
        throw(DimensionMismatch("longwave source_bottom must have shape (ng_lw, nlayers)"))
    size(shortwave.optical_depth) == (size(model.shortwave_absorption, 1), nlayers) ||
        throw(DimensionMismatch("shortwave optical_depth must have shape (ng_sw, nlayers)"))
    size(shortwave.rayleigh_optical_depth) == size(shortwave.optical_depth) ||
        throw(DimensionMismatch("shortwave rayleigh_optical_depth must have shape (ng_sw, nlayers)"))
    length(longwave.weights) == size(model.longwave_absorption, 1) ||
        throw(DimensionMismatch("longwave weights must have length ng_lw"))
    length(shortwave.weights) == size(model.shortwave_absorption, 1) ||
        throw(DimensionMismatch("shortwave weights must have length ng_sw"))
    return nothing
end

"""
    optical_properties!(longwave, shortwave, model::EcCKDGasOpticsModel, atmosphere)

Fill caller-owned longwave and shortwave optical-property arrays from an
already-interpolated ecCKD-style model. This method performs no NetCDF I/O and
does not allocate output arrays.
"""
function optical_properties!(longwave::LongwaveOpticalProperties{FT, <:AbstractMatrix},
                             shortwave::ShortwaveOpticalProperties{FT, <:AbstractMatrix},
                             model::EcCKDGasOpticsModel{FT},
                             atmosphere::ColumnAtmosphere) where FT
    _check_ecCKD_optics_shapes(longwave, shortwave, model, atmosphere)

    nlayers = length(atmosphere.temperature_layers)
    names = gas_names(model)

    for k in 1:nlayers
        source = FT(5.670374419e-8) * _source_temperature(atmosphere, k)^4

        for ig in axes(model.longwave_absorption, 1)
            longwave.optical_depth[ig, k] =
                _accumulate_tau(atmosphere.gases, model.longwave_absorption, Val(names), ig, k)
            longwave.source[ig, k] = model.longwave_source_scale[ig] * source
            if longwave.source_top !== nothing && longwave.source_bottom !== nothing
                source_top = FT(5.670374419e-8) * atmosphere.temperature_interfaces[k]^4
                source_bottom = FT(5.670374419e-8) * atmosphere.temperature_interfaces[k + 1]^4
                longwave.source_top[ig, k] = model.longwave_source_scale[ig] * source_top
                longwave.source_bottom[ig, k] = model.longwave_source_scale[ig] * source_bottom
            end
        end

        for ig in axes(model.shortwave_absorption, 1)
            shortwave.optical_depth[ig, k] =
                _accumulate_tau(atmosphere.gases, model.shortwave_absorption, Val(names), ig, k)
            shortwave.rayleigh_optical_depth[ig, k] = zero(FT)
            shortwave.scattering_asymmetry[ig, k] = zero(FT)
        end
    end

    longwave.weights .= model.longwave_weights
    shortwave.weights .= model.shortwave_weights
    return longwave, shortwave
end

@inline function _rayleigh_optical_depth(model::EcCKDTabulatedGasOpticsModel{FT},
                                         atmosphere::ColumnAtmosphere,
                                         ig,
                                         k) where FT
    length(model.shortwave_rayleigh_molar_scattering) == 0 && return zero(FT)
    Δp = atmosphere.pressure_interfaces[k + 1] - atmosphere.pressure_interfaces[k]
    air_molar_mass = FT(28.9647)
    gravity = FT(9.80665)
    return FT(model.shortwave_rayleigh_molar_scattering[ig]) * FT(Δp) /
           (gravity * FT(0.001) * air_molar_mass)
end

@inline _has_dynamic_h2o(model::EcCKDTabulatedGasOpticsModel) =
    length(model.h2o_mole_fraction_grid) > 0

@inline function _h2o_mole_fraction(::Type{FT},
                                    atmosphere::ColumnAtmosphere,
                                    k) where FT
    h2o_moles = max(FT(_gas_value(atmosphere.gases, :h2o, k)), zero(FT))
    dry_air_moles = haskey(atmosphere.gases, :composite) ?
        max(FT(_gas_value(atmosphere.gases, :composite, k)), sqrt(eps(FT))) :
        max(FT(atmosphere.pressure_interfaces[k + 1] - atmosphere.pressure_interfaces[k]) /
            (FT(9.80665) * FT(0.0289647)), sqrt(eps(FT)))
    return h2o_moles / dry_air_moles
end

@inline function _dynamic_h2o_tau(model::EcCKDTabulatedGasOpticsModel{FT},
                                  table,
                                  atmosphere::ColumnAtmosphere,
                                  ig,
                                  k,
                                  pressure,
                                  temperature,
                                  h2o_mole_fraction) where FT
    length(model.h2o_mole_fraction_grid) == 0 && return zero(FT)
    length(table) == 0 && return zero(FT)
    coefficient = _interp_h2o_table(table, ig, pressure, temperature,
                                    h2o_mole_fraction,
                                    model.pressure_grid,
                                    model.temperature_grid,
                                    model.h2o_mole_fraction_grid)
    return coefficient * FT(_gas_value(atmosphere.gases, :h2o, k))
end

"""
    optical_properties!(longwave, shortwave, model::EcCKDTabulatedGasOpticsModel, atmosphere)

Fill caller-owned longwave and shortwave optical-property arrays from
pressure/temperature coefficient tables using bilinear interpolation. This is
the lightweight runtime LUT path for ecCKD-style gas optics.
"""
function optical_properties!(longwave::LongwaveOpticalProperties{FT, <:AbstractMatrix},
                             shortwave::ShortwaveOpticalProperties{FT, <:AbstractMatrix},
                             model::EcCKDTabulatedGasOpticsModel{FT},
                             atmosphere::ColumnAtmosphere) where FT
    _check_ecCKD_optics_shapes(longwave, shortwave, model, atmosphere)

    nlayers = length(atmosphere.temperature_layers)
    names = gas_names(model)

    for k in 1:nlayers
        pressure = atmosphere.pressure_layers[k]
        temperature = atmosphere.temperature_layers[k]
        h2o_mole_fraction = _has_dynamic_h2o(model) ?
            _h2o_mole_fraction(FT, atmosphere, k) : zero(FT)

        for ig in axes(model.longwave_absorption, 1)
            longwave.optical_depth[ig, k] =
                _accumulate_tabulated_tau(atmosphere.gases, model.longwave_absorption,
                                          model.gas_reference_mole_fractions,
                                          Val(names),
                                          ig, k, pressure, temperature,
                                          model.pressure_grid, model.temperature_grid)
            longwave.optical_depth[ig, k] +=
                _dynamic_h2o_tau(model, model.longwave_h2o_absorption,
                                 atmosphere, ig, k, pressure, temperature,
                                 h2o_mole_fraction)
            longwave.source[ig, k] = _longwave_source(model, ig, temperature)
            if longwave.source_top !== nothing && longwave.source_bottom !== nothing
                longwave.source_top[ig, k] =
                    _longwave_source(model, ig, atmosphere.temperature_interfaces[k])
                longwave.source_bottom[ig, k] =
                    _longwave_source(model, ig, atmosphere.temperature_interfaces[k + 1])
            end
        end

        for ig in axes(model.shortwave_absorption, 1)
            shortwave.optical_depth[ig, k] =
                _accumulate_tabulated_tau(atmosphere.gases, model.shortwave_absorption,
                                          model.gas_reference_mole_fractions,
                                          Val(names),
                                          ig, k, pressure, temperature,
                                          model.pressure_grid, model.temperature_grid)
            shortwave.optical_depth[ig, k] +=
                _dynamic_h2o_tau(model, model.shortwave_h2o_absorption,
                                 atmosphere, ig, k, pressure, temperature,
                                 h2o_mole_fraction)
            shortwave.rayleigh_optical_depth[ig, k] =
                _rayleigh_optical_depth(model, atmosphere, ig, k)
            shortwave.scattering_asymmetry[ig, k] = zero(FT)
        end
    end

    longwave.weights .= model.longwave_weights
    shortwave.weights .= model.shortwave_weights
    return longwave, shortwave
end
