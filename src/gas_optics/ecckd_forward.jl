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
The pressure and optional H2O grids must be positive and uniformly spaced in
log coordinates, matching the ecCKD file format. A matrix temperature grid is
shaped `(npressure, ntemperature)` and must use one positive temperature
increment throughout.

Fields are

$(TYPEDFIELDS)
"""
struct EcCKDTabulatedGasOpticsModel{FT, GasNames, PG, TG, HG, GREF, LWA, SWA, LHWA, SHWA, SWR, LWS, LST, LSTB, LWW, SWW} <:
       AbstractGasOpticsModel
    "Positive, increasing, log-uniform pressure grid for coefficient tables."
    pressure_grid::PG
    "Increasing temperature grid, or pressure-dependent matrix with one common increment."
    temperature_grid::TG
    "Optional positive, increasing, log-uniform H2O mole-fraction grid."
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

    gas_name_tuple = Tuple(Symbol.(gas_names))
    ngas = length(gas_names)
    length(pressure_grid) >= 2 ||
        throw(DimensionMismatch("pressure_grid must contain at least two points"))
    _temperature_grid_length(temperature_grid) >= 2 ||
        throw(DimensionMismatch("temperature_grid must contain at least two points"))
    _validate_log_uniform_grid(pressure_grid, "pressure_grid")
    _validate_temperature_grid(temperature_grid, length(pressure_grid))
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
        :h2o in gas_name_tuple ||
            throw(ArgumentError("h2o_mole_fraction_grid requires :h2o in gas_names"))
        _validate_log_uniform_grid(h2o_grid, "h2o_mole_fraction_grid")
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
        _validate_increasing_grid(longwave_source_temperature_grid,
                                  "longwave_source_temperature_grid")
    end
    length(lw_weights) == size(longwave_absorption, 1) ||
        throw(DimensionMismatch("longwave_weights must have length ng_lw"))
    length(sw_weights) == size(shortwave_absorption, 1) ||
        throw(DimensionMismatch("shortwave_weights must have length ng_sw"))
    length(sw_rayleigh) == size(shortwave_absorption, 1) ||
        throw(DimensionMismatch("shortwave_rayleigh_molar_scattering must have length ng_sw"))
    length(gas_refs) == ngas ||
        throw(DimensionMismatch("gas_reference_mole_fractions must match gas_names length"))

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

@inline _has_gas(gases::AbstractDict, name::Symbol) = haskey(gases, name)
@inline _has_gas(gases, name::Symbol) = hasproperty(gases, name)

@inline _gas_profile(gases::AbstractDict, name::Symbol) = gases[name]
@inline _gas_profile(gases, name::Symbol) = getproperty(gases, name)

@inline function _check_gas_profile_length(gases, name, nlayers)
    profile = _gas_profile(gases, name)
    profile isa Number && return nothing
    length(profile) >= nlayers ||
        throw(DimensionMismatch("gas profile $name must contain at least nlayers values"))
    return nothing
end

@inline function _check_gas_profile_lengths(gases, names, nlayers)
    for name in names
        _check_gas_profile_length(gases, name, nlayers)
    end
    return nothing
end

@generated function _check_gas_profile_lengths(gases::NamedTuple{Keys},
                                               ::Val{Names},
                                               nlayers) where {Keys, Names}
    checks = [:( _check_gas_profile_length(gases, $(QuoteNode(name)), nlayers) )
              for name in Names]
    return quote
        $(checks...)
        nothing
    end
end

@inline _check_gas_profile_lengths(gases, ::Val{Names}, nlayers) where Names =
    _check_gas_profile_lengths(gases, Names, nlayers)

@inline function _check_tabulated_gas_profile_lengths(gases, names, nlayers)
    _check_gas_profile_lengths(gases, names, nlayers)
    if !(:composite in names) && _has_gas(gases, :composite)
        _check_gas_profile_length(gases, :composite, nlayers)
    end
    return nothing
end

@generated function _check_tabulated_gas_profile_lengths(gases::NamedTuple{Keys},
                                                         ::Val{Names},
                                                         nlayers) where {Keys, Names}
    names_to_check = collect(Names)
    :composite in Keys && !(:composite in Names) && push!(names_to_check, :composite)
    checks = [:( _check_gas_profile_length(gases, $(QuoteNode(name)), nlayers) )
              for name in names_to_check]
    return quote
        $(checks...)
        nothing
    end
end

@inline _check_tabulated_gas_profile_lengths(gases, ::Val{Names}, nlayers) where Names =
    _check_tabulated_gas_profile_lengths(gases, Names, nlayers)

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

function _validate_increasing_grid(grid, name)
    all(isfinite, grid) || throw(ArgumentError("$name must contain only finite values"))
    for i in (firstindex(grid) + 1):lastindex(grid)
        grid[i] > grid[i - 1] ||
            throw(ArgumentError("$name must be strictly increasing"))
    end
    return nothing
end

function _validate_log_uniform_grid(grid, name)
    all(>(zero(eltype(grid))), grid) ||
        throw(ArgumentError("$name must contain only positive values"))
    _validate_increasing_grid(grid, name)
    # The ecCKD reference kernel derives every index from the first log-grid
    # interval. Refuse tables that violate that format instead of interpolating
    # them with a silently wrong coordinate transform.
    expected_step = log(grid[firstindex(grid) + 1]) - log(grid[firstindex(grid)])
    for i in (firstindex(grid) + 2):lastindex(grid)
        step = log(grid[i]) - log(grid[i - 1])
        isapprox(step, expected_step; rtol = 1.0e-5, atol = 0.0) ||
            throw(ArgumentError("$name must be uniformly spaced in log coordinates"))
    end
    return nothing
end

_validate_temperature_grid(grid::AbstractVector, _) =
    _validate_increasing_grid(grid, "temperature_grid")

function _validate_temperature_grid(grid::AbstractMatrix, pressure_count)
    size(grid, 1) == pressure_count ||
        throw(DimensionMismatch("temperature_grid pressure dimension must match pressure_grid"))
    all(isfinite, grid) ||
        throw(ArgumentError("temperature_grid must contain only finite values"))
    expected_step = grid[1, 2] - grid[1, 1]
    expected_step > 0 ||
        throw(ArgumentError("temperature_grid rows must be strictly increasing"))
    # The reference kernel likewise carries one temperature increment for the
    # whole pressure-dependent table.
    for ip in axes(grid, 1), it in 2:size(grid, 2)
        step = grid[ip, it] - grid[ip, it - 1]
        step > 0 ||
            throw(ArgumentError("temperature_grid rows must be strictly increasing"))
        isapprox(step, expected_step; rtol = 1.0e-5, atol = 0.0) ||
            throw(ArgumentError("temperature_grid must use one uniform temperature increment"))
    end
    return nothing
end

@inline function _pressure_bracket(pressure_grid, pressure)
    return _log_bracket(pressure_grid, pressure)
end

# `_log_bracket` needs two grid points. Models without a dynamic H2O table carry
# an empty grid, and `_dynamic_h2o_tau` short-circuits before the bracket is ever
# indexed, so return a same-typed placeholder in that case.
@inline function _h2o_bracket(h2o_grid, h2o_mole_fraction)
    length(h2o_grid) < 2 &&
        return firstindex(h2o_grid), firstindex(h2o_grid), zero(eltype(h2o_grid))
    return _log_bracket(h2o_grid, h2o_mole_fraction)
end

# Pressure/temperature interpolation stencil for a coefficient table: a pair of
# `(i0, i1, weight)` brackets. Brackets depend only on the layer state, so the
# runtime builds one per layer and reuses it across every g point and gas.
#
# `FT` is the *table's* element type, threaded explicitly rather than taken from
# the grids: the matrix-grid temperature index below is evaluated in it, and
# `EcCKDTabulatedGasOpticsModel` stores absorption tables as given, so their
# element type need not match the model's.
@inline _table_stencil(::Type{FT},
                       pressure_grid,
                       temperature_grid::AbstractVector,
                       pressure,
                       temperature) where FT =
    (_pressure_bracket(pressure_grid, pressure), _bracket(temperature_grid, temperature))

@inline function _table_stencil(::Type{FT},
                                pressure_grid,
                                temperature_grid::AbstractMatrix,
                                pressure,
                                temperature) where FT
    pressure_bracket = _pressure_bracket(pressure_grid, pressure)
    ip0, ip1, wp = pressure_bracket
    temperature_origin = (one(FT) - wp) * temperature_grid[ip0, 1] +
                         wp * temperature_grid[ip1, 1]
    temperature_step = temperature_grid[1, 2] - temperature_grid[1, 1]
    temperature_index = one(FT) + clamp((temperature - temperature_origin) / temperature_step,
                                        zero(FT),
                                        FT(size(temperature_grid, 2)) - FT(1.0001))
    it0 = Int(floor(temperature_index))
    return pressure_bracket, (it0, it0 + 1, temperature_index - it0)
end

@inline function _interp_table(table::AbstractArray{<:Any, 4}, ig, j, stencil)
    (ip0, ip1, wp), (it0, it1, wt) = stencil
    c00 = table[ig, j, ip0, it0]
    c10 = table[ig, j, ip1, it0]
    c01 = table[ig, j, ip0, it1]
    c11 = table[ig, j, ip1, it1]
    cp0 = c00 + wp * (c10 - c00)
    cp1 = c01 + wp * (c11 - c01)
    return cp0 + wt * (cp1 - cp0)
end

@inline function _interp_source_table(table::AbstractMatrix, ig, temperature_bracket)
    it0, it1, wt = temperature_bracket
    return table[ig, it0] + wt * (table[ig, it1] - table[ig, it0])
end

@inline function _interp_h2o_table(table::AbstractArray{<:Any, 4}, ig, stencil, h2o_bracket)
    (ip0, ip1, wp), (it0, it1, wt) = stencil
    ih0, ih1, wh = h2o_bracket

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

@inline _source_bracket(model::EcCKDTabulatedGasOpticsModel, temperature) =
    model.longwave_source_table === nothing ?
        nothing : _bracket(model.longwave_source_temperature_grid, temperature)

@inline function _longwave_source(model::EcCKDTabulatedGasOpticsModel{FT},
                                  ig,
                                  temperature,
                                  source_bracket) where FT
    source_bracket === nothing &&
        return model.longwave_source_scale[ig] * FT(5.670374419e-8) * temperature^4
    return _interp_source_table(model.longwave_source_table, ig, source_bracket)
end

"""
$(TYPEDSIGNATURES)

Per-g-point surface longwave emission of `model` at the surface `temperature`,
scaled by `emissivity`, in the same per-unit-weight flux convention as the
model's Planck source tables. Pass the result as `surface_longwave_up` in
`LongwaveBoundaryConditions`.

For multi-g spectral models a scalar ``σT⁴`` boundary is spectrally gray:
every g point then emits the same flux, misallocating surface emission from
transparent window g points into opaque ones (≈ 50 W m⁻² of outgoing
longwave for the official 32-g models on an Earth-like column).
"""
function surface_longwave_emission(model::EcCKDTabulatedGasOpticsModel{FT},
                                   temperature;
                                   emissivity = one(FT)) where FT
    ng = length(model.longwave_weights)
    source_bracket = _source_bracket(model, temperature)
    return FT[emissivity * _longwave_source(model, ig, temperature, source_bracket)
              for ig in 1:ng]
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
                                              stencil) where {FT, GasNames}
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
        push!(terms, :(_interp_table(coefficients, ig, $j, stencil) * $amount))
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
                                           stencil) where FT
    tau = zero(FT)
    for j in eachindex(gas_names)
        amount = FT(_gas_value(gases, gas_names[j], k))
        reference = FT(gas_reference_mole_fractions[j])
        if reference != zero(FT) && _has_gas(gases, :composite)
            amount -= reference * FT(_gas_value(gases, :composite, k))
        end
        tau += _interp_table(coefficients, ig, j, stencil) * amount
    end
    return tau
end

@inline _accumulate_tabulated_tau(gases,
                                  coefficients::AbstractArray{FT, 4},
                                  gas_reference_mole_fractions,
                                  ::Val{GasNames},
                                  ig,
                                  k,
                                  stencil) where {FT, GasNames} =
    _accumulate_tabulated_tau(gases, coefficients, GasNames,
                              gas_reference_mole_fractions, ig, k, stencil)

function _check_ecCKD_optics_shapes(longwave::LongwaveOpticalProperties,
                                    shortwave::ShortwaveOpticalProperties,
                                    model::EcCKDGasOpticsModel,
                                    atmosphere::ColumnAtmosphere)
    nlayers = length(atmosphere.temperature_layers)
    _check_gas_profile_lengths(atmosphere.gases, Val(gas_names(model)), nlayers)
    interface_sources = longwave.source_top !== nothing || longwave.source_bottom !== nothing
    (longwave.source_top === nothing) == (longwave.source_bottom === nothing) ||
        throw(ArgumentError("longwave source_top and source_bottom must both be provided or both be nothing"))
    if interface_sources
        length(atmosphere.temperature_interfaces) == nlayers + 1 ||
            throw(DimensionMismatch("temperature_interfaces must contain nlayers + 1 values"))
    end
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
    length(atmosphere.pressure_layers) == nlayers ||
        throw(DimensionMismatch("pressure_layers must contain nlayers values"))
    length(atmosphere.pressure_interfaces) == nlayers + 1 ||
        throw(DimensionMismatch("pressure_interfaces must contain nlayers + 1 values"))
    _check_tabulated_gas_profile_lengths(atmosphere.gases, Val(gas_names(model)), nlayers)
    interface_sources = longwave.source_top !== nothing || longwave.source_bottom !== nothing
    (longwave.source_top === nothing) == (longwave.source_bottom === nothing) ||
        throw(ArgumentError("longwave source_top and source_bottom must both be provided or both be nothing"))
    if interface_sources
        length(atmosphere.temperature_interfaces) == nlayers + 1 ||
            throw(DimensionMismatch("temperature_interfaces must contain nlayers + 1 values"))
    end
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
    dry_air_moles = _has_gas(atmosphere.gases, :composite) ?
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
                                  stencil,
                                  h2o_bracket) where FT
    length(model.h2o_mole_fraction_grid) == 0 && return zero(FT)
    length(table) == 0 && return zero(FT)
    coefficient = _interp_h2o_table(table, ig, stencil, h2o_bracket)
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

        # Interface sources are optional and `temperature_interfaces` is only
        # required to be populated when they are requested, so fall back to the
        # layer temperature otherwise rather than indexing it. The condition is
        # decided by the optical-property types, so this folds away.
        interface_sources = longwave.source_top !== nothing &&
                            longwave.source_bottom !== nothing
        temperature_top = interface_sources ?
            atmosphere.temperature_interfaces[k] : temperature
        temperature_bottom = interface_sources ?
            atmosphere.temperature_interfaces[k + 1] : temperature

        # Every interpolation bracket below depends only on the layer, so build
        # them once here instead of once per g point and gas. The absorption
        # tables are stored as supplied and may differ in element type, hence one
        # stencil each; the constructor converts both H2O tables to `FT`.
        longwave_stencil = _table_stencil(eltype(model.longwave_absorption),
                                          model.pressure_grid, model.temperature_grid,
                                          pressure, temperature)
        shortwave_stencil = _table_stencil(eltype(model.shortwave_absorption),
                                           model.pressure_grid, model.temperature_grid,
                                           pressure, temperature)
        h2o_stencil = _table_stencil(FT, model.pressure_grid, model.temperature_grid,
                                     pressure, temperature)
        h2o_bracket = _h2o_bracket(model.h2o_mole_fraction_grid, h2o_mole_fraction)
        source_bracket = _source_bracket(model, temperature)
        source_top_bracket = _source_bracket(model, temperature_top)
        source_bottom_bracket = _source_bracket(model, temperature_bottom)

        for ig in axes(model.longwave_absorption, 1)
            longwave.optical_depth[ig, k] =
                _accumulate_tabulated_tau(atmosphere.gases, model.longwave_absorption,
                                          model.gas_reference_mole_fractions,
                                          Val(names),
                                          ig, k, longwave_stencil)
            longwave.optical_depth[ig, k] +=
                _dynamic_h2o_tau(model, model.longwave_h2o_absorption,
                                 atmosphere, ig, k, h2o_stencil, h2o_bracket)
            # Relative-linear gases legitimately contribute negative optical
            # depth below their reference mole fraction; only the summed total
            # is clamped, matching upstream run_ckd.
            longwave.optical_depth[ig, k] =
                max(longwave.optical_depth[ig, k], zero(FT))
            longwave.source[ig, k] = _longwave_source(model, ig, temperature, source_bracket)
            if interface_sources
                longwave.source_top[ig, k] =
                    _longwave_source(model, ig, temperature_top, source_top_bracket)
                longwave.source_bottom[ig, k] =
                    _longwave_source(model, ig, temperature_bottom, source_bottom_bracket)
            end
        end

        for ig in axes(model.shortwave_absorption, 1)
            shortwave.optical_depth[ig, k] =
                _accumulate_tabulated_tau(atmosphere.gases, model.shortwave_absorption,
                                          model.gas_reference_mole_fractions,
                                          Val(names),
                                          ig, k, shortwave_stencil)
            shortwave.optical_depth[ig, k] +=
                _dynamic_h2o_tau(model, model.shortwave_h2o_absorption,
                                 atmosphere, ig, k, h2o_stencil, h2o_bracket)
            shortwave.optical_depth[ig, k] =
                max(shortwave.optical_depth[ig, k], zero(FT))
            shortwave.rayleigh_optical_depth[ig, k] =
                _rayleigh_optical_depth(model, atmosphere, ig, k)
            shortwave.scattering_asymmetry[ig, k] = zero(FT)
        end
    end

    longwave.weights .= model.longwave_weights
    shortwave.weights .= model.shortwave_weights
    return longwave, shortwave
end
