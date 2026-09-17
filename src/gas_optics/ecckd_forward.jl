"""
$(TYPEDEF)

Small ecCKD-style forward gas-optics model for staged runtime integration.

This type is intentionally limited to fixed, already-interpolated coefficient
tables. It gives host models an allocation-free runtime path from gas columns
to longwave and shortwave optical properties.

`longwave_absorption` and `shortwave_absorption` are shaped `(Ngpoints, Ngases)`.
Gas values in [`ColumnAtmosphere`](@ref) are interpreted as layer absorber
amounts. A gas value may be a scalar, in which case it is applied to every
layer, or a vector with one entry per layer. The gray longwave source is
`longwave_source_scale[gpoint] σT⁴` with the model's `stefan_boltzmann`
(keyword; [`PhysicalConstants`](@ref) default).

"""
struct EcCKDGasOpticsModel{FT, GasNames, LWA, SWA, LWS, LWW, SWW} <: AbstractGasOpticsModel
    longwave_absorption::LWA   # Longwave absorption coefficients with shape `(Nlongwave_gpoints, Ngases)`.
    shortwave_absorption::SWA   # Shortwave absorption coefficients with shape `(Nshortwave_gpoints, Ngases)`.
    longwave_source_scale::LWS   # Longwave source scaling per g-point.
    longwave_weights::LWW   # Longwave spectral weights.
    shortwave_weights::SWW   # Shortwave spectral weights.
    stefan_boltzmann::FT   # Stefan–Boltzmann constant of the gray source, W m⁻² K⁻⁴.
end

# The element type of an adapted model follows its adapted tables, so
# `adapt(Array{Float32}, model)` (or a device adaptor that changes precision)
# yields a `Float32` model whose scalar layer optics compute in `Float32`.
function Adapt.adapt_structure(to, model::EcCKDGasOpticsModel{<:Any, GasNames}) where GasNames
    longwave_absorption = Adapt.adapt(to, model.longwave_absorption)
    shortwave_absorption = Adapt.adapt(to, model.shortwave_absorption)
    longwave_source_scale = Adapt.adapt(to, model.longwave_source_scale)
    longwave_weights = Adapt.adapt(to, model.longwave_weights)
    shortwave_weights = Adapt.adapt(to, model.shortwave_weights)
    fields = (longwave_absorption, shortwave_absorption, longwave_source_scale,
              longwave_weights, shortwave_weights)
    FT = eltype(longwave_absorption)
    return EcCKDGasOpticsModel{FT, GasNames, map(typeof, fields)...}(fields...,
                                                                     FT(model.stefan_boltzmann))
end

function EcCKDGasOpticsModel(; names,
                               longwave_absorption::AbstractMatrix,
                               shortwave_absorption::AbstractMatrix,
                               longwave_source_scale = nothing,
                               longwave_weights = nothing,
                               shortwave_weights = nothing,
                               stefan_boltzmann = PhysicalConstants().stefan_boltzmann)
    FT = promote_type(eltype(longwave_absorption), eltype(shortwave_absorption))
    longwave_source_scale = longwave_source_scale === nothing ?
        ones(FT, size(longwave_absorption, 1)) : longwave_source_scale
    longwave_weights = longwave_weights === nothing ?
        fill(inv(FT(size(longwave_absorption, 1))), size(longwave_absorption, 1)) :
        longwave_weights
    shortwave_weights = shortwave_weights === nothing ?
        fill(inv(FT(size(shortwave_absorption, 1))), size(shortwave_absorption, 1)) :
        shortwave_weights

    Ngases = length(names)
    size(longwave_absorption, 2) == Ngases ||
        throw(DimensionMismatch("longwave_absorption gas dimension must match names"))
    size(shortwave_absorption, 2) == Ngases ||
        throw(DimensionMismatch("shortwave_absorption gas dimension must match names"))
    length(longwave_source_scale) == size(longwave_absorption, 1) ||
        throw(DimensionMismatch("longwave_source_scale must have length Nlongwave_gpoints"))
    length(longwave_weights) == size(longwave_absorption, 1) ||
        throw(DimensionMismatch("longwave_weights must have length Nlongwave_gpoints"))
    length(shortwave_weights) == size(shortwave_absorption, 1) ||
        throw(DimensionMismatch("shortwave_weights must have length Nshortwave_gpoints"))

    gas_name_tuple = Tuple(Symbol.(names))
    fields = (longwave_absorption, shortwave_absorption, longwave_source_scale,
              longwave_weights, shortwave_weights)
    return EcCKDGasOpticsModel{FT, gas_name_tuple, map(typeof, fields)...}(fields...,
                                                                           FT(stefan_boltzmann))
end

Base.eltype(::EcCKDGasOpticsModel{FT}) where FT = FT

"""
$(TYPEDSIGNATURES)

Gas names of an ecCKD gas-optics model as a `Tuple` of `Symbol`s, in the gas
order of its absorption tables. Layer gas containers passed to the layer
optical-depth functions are keyed by these names.
"""
@inline gas_names(::EcCKDGasOpticsModel{<:Any, GasNames}) where GasNames = GasNames

"""
$(TYPEDEF)

ecCKD-style tabulated gas-optics model with bilinear pressure/temperature
interpolation.

`longwave_absorption` and `shortwave_absorption` are shaped
`(Ngpoints, Ngases, Npressures, Ntemperatures)`. The runtime method interpolates
coefficients for each layer, multiplies them by layer absorber amounts from
[`ColumnAtmosphere`](@ref), and writes caller-owned optical-property arrays.
The pressure and optional H₂O grids must be positive and uniformly spaced in
log coordinates, matching the ecCKD file format. A matrix temperature grid is
shaped `(Npressures, Ntemperatures)` and must use one positive temperature
increment throughout. Without a Planck source table the longwave source is
the gray `longwave_source_scale[gpoint] σT⁴` with the model's `stefan_boltzmann`
(keyword; [`PhysicalConstants`](@ref) default).

"""
struct EcCKDTabulatedGasOpticsModel{FT, GasNames, PG, TG, HG, GREF, LWA, SWA, LHWA, SHWA, SWR, LWS, LST, LSTB, LWW, SWW} <:
       AbstractGasOpticsModel
    pressure_grid::PG   # Positive, increasing, log-uniform pressure grid for coefficient tables.
    temperature_grid::TG   # Increasing temperature grid, or pressure-dependent matrix with one common increment.
    water_vapor_mole_fraction_grid::HG   # Optional positive, increasing, log-uniform H₂O mole-fraction grid.
    gas_reference_mole_fractions::GREF   # Reference mole fractions for relative-linear gases, aligned with names.
    longwave_absorption::LWA   # Longwave absorption coefficients with shape `(Nlongwave_gpoints, Ngases, Npressures, Ntemperatures)`.
    shortwave_absorption::SWA   # Shortwave absorption coefficients with shape `(Nshortwave_gpoints, Ngases, Npressures, Ntemperatures)`.
    longwave_water_vapor_absorption::LHWA   # Optional longwave H₂O absorption coefficients with shape `(Nlongwave_gpoints, Npressures, Ntemperatures, Nwater_vapor)`.
    shortwave_water_vapor_absorption::SHWA   # Optional shortwave H₂O absorption coefficients with shape `(Nshortwave_gpoints, Npressures, Ntemperatures, Nwater_vapor)`.
    shortwave_rayleigh_molar_scattering::SWR   # Optional shortwave Rayleigh molar scattering coefficients with length `Nshortwave_gpoints`.
    longwave_source_scale::LWS   # Longwave source scaling per g-point.
    longwave_source_temperature_grid::LST   # Optional longwave source temperature grid.
    longwave_source_table::LSTB   # Optional longwave source table with shape `(Nlongwave_gpoints, Ntemperatures)`.
    longwave_weights::LWW   # Longwave spectral weights.
    shortwave_weights::SWW   # Shortwave spectral weights.
    stefan_boltzmann::FT   # Stefan–Boltzmann constant of the gray source fallback, W m⁻² K⁻⁴.
end

# As for `EcCKDGasOpticsModel`, the adapted model's element type follows its
# adapted tables (the pressure grid stands for all of them: the constructor and
# `EcCKDTabulatedGasOpticsModel{FT}` keep every table in one element type).
function Adapt.adapt_structure(to, model::EcCKDTabulatedGasOpticsModel{<:Any, GasNames}) where GasNames
    pressure_grid = Adapt.adapt(to, model.pressure_grid)
    temperature_grid = Adapt.adapt(to, model.temperature_grid)
    water_vapor_mole_fraction_grid = Adapt.adapt(to, model.water_vapor_mole_fraction_grid)
    longwave_absorption = Adapt.adapt(to, model.longwave_absorption)
    shortwave_absorption = Adapt.adapt(to, model.shortwave_absorption)
    longwave_water_vapor_absorption = Adapt.adapt(to, model.longwave_water_vapor_absorption)
    shortwave_water_vapor_absorption = Adapt.adapt(to, model.shortwave_water_vapor_absorption)
    shortwave_rayleigh_molar_scattering = Adapt.adapt(to, model.shortwave_rayleigh_molar_scattering)
    gas_reference_mole_fractions = Adapt.adapt(to, model.gas_reference_mole_fractions)
    longwave_source_scale = Adapt.adapt(to, model.longwave_source_scale)
    longwave_source_temperature_grid = Adapt.adapt(to, model.longwave_source_temperature_grid)
    longwave_source_table = Adapt.adapt(to, model.longwave_source_table)
    longwave_weights = Adapt.adapt(to, model.longwave_weights)
    shortwave_weights = Adapt.adapt(to, model.shortwave_weights)
    fields = (pressure_grid, temperature_grid, water_vapor_mole_fraction_grid,
              gas_reference_mole_fractions, longwave_absorption,
              shortwave_absorption, longwave_water_vapor_absorption,
              shortwave_water_vapor_absorption, shortwave_rayleigh_molar_scattering,
              longwave_source_scale, longwave_source_temperature_grid,
              longwave_source_table, longwave_weights, shortwave_weights)
    FT = eltype(pressure_grid)
    return EcCKDTabulatedGasOpticsModel{FT, GasNames, map(typeof, fields)...}(fields...,
                                                                              FT(model.stefan_boltzmann))
end

# Adaptor that converts the element type of every array in a model while
# leaving its storage (host or device) where it is. Arrays already in `FT`
# are passed through unchanged, so a same-type conversion shares storage.
struct FloatTypeConverter{FT} end

Adapt.adapt_storage(::FloatTypeConverter{FT}, x::AbstractArray{FT}) where FT = x
Adapt.adapt_storage(::FloatTypeConverter{FT}, x::AbstractArray) where FT = FT.(x)

"""
$(TYPEDSIGNATURES)

Convert every table, grid and weight vector of a tabulated ecCKD gas-optics
model to element type `FT`, returning an `EcCKDTabulatedGasOpticsModel{FT}`.
Optional tables that are absent (`nothing`) stay absent and arrays already in
`FT` are shared rather than copied. The conversion runs where the arrays live,
so a device model is converted on the device.

The reference ecCKD coefficient tables are stored in single precision, so a
`Float32` model reproduces them exactly; only the derived Planck source table
and the spectral weights are rounded.
"""
function (::Type{EcCKDTabulatedGasOpticsModel{FT}})(model::EcCKDTabulatedGasOpticsModel) where FT
    return Adapt.adapt(FloatTypeConverter{FT}(), model)
end

function EcCKDTabulatedGasOpticsModel(; names,
                                        pressure_grid::AbstractVector,
                                        temperature_grid,
                                        water_vapor_mole_fraction_grid = Float64[],
                                        gas_reference_mole_fractions = nothing,
                                        longwave_absorption::AbstractArray{<:Any, 4},
                                        shortwave_absorption::AbstractArray{<:Any, 4},
                                        longwave_water_vapor_absorption = nothing,
                                        shortwave_water_vapor_absorption = nothing,
                                        shortwave_rayleigh_molar_scattering = nothing,
                                        longwave_source_scale = nothing,
                                        longwave_source_temperature_grid = nothing,
                                        longwave_source_table = nothing,
                                        longwave_weights = nothing,
                                        shortwave_weights = nothing,
                                        stefan_boltzmann = PhysicalConstants().stefan_boltzmann)
    source_types = longwave_source_table === nothing ?
        () :
        (eltype(longwave_source_temperature_grid), eltype(longwave_source_table))
    FT = promote_type(eltype(pressure_grid), eltype(temperature_grid),
                      eltype(longwave_absorption), eltype(shortwave_absorption),
                      source_types...)
    water_vapor_grid = collect(FT, water_vapor_mole_fraction_grid)
    longwave_water_vapor = longwave_water_vapor_absorption === nothing ?
        zeros(FT, 0, 0, 0, 0) : FT.(longwave_water_vapor_absorption)
    shortwave_water_vapor = shortwave_water_vapor_absorption === nothing ?
        zeros(FT, 0, 0, 0, 0) : FT.(shortwave_water_vapor_absorption)
    longwave_source_scale = longwave_source_scale === nothing ?
        ones(FT, size(longwave_absorption, 1)) : longwave_source_scale
    longwave_weights = longwave_weights === nothing ?
        fill(inv(FT(size(longwave_absorption, 1))), size(longwave_absorption, 1)) :
        longwave_weights
    shortwave_weights = shortwave_weights === nothing ?
        fill(inv(FT(size(shortwave_absorption, 1))), size(shortwave_absorption, 1)) :
        shortwave_weights
    shortwave_rayleigh_molar_scattering = shortwave_rayleigh_molar_scattering === nothing ?
        zeros(FT, size(shortwave_absorption, 1)) :
        shortwave_rayleigh_molar_scattering
    gas_reference_mole_fractions = gas_reference_mole_fractions === nothing ?
        zeros(FT, length(names)) : FT.(gas_reference_mole_fractions)

    gas_name_tuple = Tuple(Symbol.(names))
    Ngases = length(names)
    length(pressure_grid) >= 2 ||
        throw(DimensionMismatch("pressure_grid must contain at least two points"))
    temperature_grid_length(temperature_grid) >= 2 ||
        throw(DimensionMismatch("temperature_grid must contain at least two points"))
    validate_log_uniform_grid(pressure_grid, "pressure_grid")
    validate_temperature_grid(temperature_grid, length(pressure_grid))
    size(longwave_absorption, 2) == Ngases ||
        throw(DimensionMismatch("longwave_absorption gas dimension must match names"))
    size(shortwave_absorption, 2) == Ngases ||
        throw(DimensionMismatch("shortwave_absorption gas dimension must match names"))
    size(longwave_absorption, 3) == length(pressure_grid) ||
        throw(DimensionMismatch("longwave_absorption pressure dimension must match pressure_grid"))
    size(shortwave_absorption, 3) == length(pressure_grid) ||
        throw(DimensionMismatch("shortwave_absorption pressure dimension must match pressure_grid"))
    size(longwave_absorption, 4) == temperature_grid_length(temperature_grid) ||
        throw(DimensionMismatch("longwave_absorption temperature dimension must match temperature_grid"))
    size(shortwave_absorption, 4) == temperature_grid_length(temperature_grid) ||
        throw(DimensionMismatch("shortwave_absorption temperature dimension must match temperature_grid"))
    if length(water_vapor_grid) > 0
        length(water_vapor_grid) >= 2 ||
            throw(DimensionMismatch("water_vapor_mole_fraction_grid must contain at least two points when supplied"))
        :h2o in gas_name_tuple ||
            throw(ArgumentError("water_vapor_mole_fraction_grid requires :h2o in names"))
        validate_log_uniform_grid(water_vapor_grid, "water_vapor_mole_fraction_grid")
        size(longwave_water_vapor) == (size(longwave_absorption, 1), length(pressure_grid),
                                       temperature_grid_length(temperature_grid), length(water_vapor_grid)) ||
            throw(DimensionMismatch("longwave_water_vapor_absorption must have shape (Nlongwave_gpoints, Npressures, Ntemperatures, Nwater_vapor)"))
        size(shortwave_water_vapor) == (size(shortwave_absorption, 1), length(pressure_grid),
                                        temperature_grid_length(temperature_grid), length(water_vapor_grid)) ||
            throw(DimensionMismatch("shortwave_water_vapor_absorption must have shape (Nshortwave_gpoints, Npressures, Ntemperatures, Nwater_vapor)"))
    end
    length(longwave_source_scale) == size(longwave_absorption, 1) ||
        throw(DimensionMismatch("longwave_source_scale must have length Nlongwave_gpoints"))
    if longwave_source_table !== nothing
        longwave_source_temperature_grid === nothing &&
            throw(DimensionMismatch("longwave_source_temperature_grid is required with longwave_source_table"))
        size(longwave_source_table, 1) == size(longwave_absorption, 1) ||
            throw(DimensionMismatch("longwave_source_table first dimension must match Nlongwave_gpoints"))
        size(longwave_source_table, 2) == length(longwave_source_temperature_grid) ||
            throw(DimensionMismatch("longwave_source_table temperature dimension must match longwave_source_temperature_grid"))
        validate_increasing_grid(longwave_source_temperature_grid,
                                 "longwave_source_temperature_grid")
    end
    length(longwave_weights) == size(longwave_absorption, 1) ||
        throw(DimensionMismatch("longwave_weights must have length Nlongwave_gpoints"))
    length(shortwave_weights) == size(shortwave_absorption, 1) ||
        throw(DimensionMismatch("shortwave_weights must have length Nshortwave_gpoints"))
    length(shortwave_rayleigh_molar_scattering) == size(shortwave_absorption, 1) ||
        throw(DimensionMismatch("shortwave_rayleigh_molar_scattering must have length Nshortwave_gpoints"))
    length(gas_reference_mole_fractions) == Ngases ||
        throw(DimensionMismatch("gas_reference_mole_fractions must match names length"))

    fields = (pressure_grid, temperature_grid, water_vapor_grid, gas_reference_mole_fractions,
              longwave_absorption, shortwave_absorption,
              longwave_water_vapor, shortwave_water_vapor, shortwave_rayleigh_molar_scattering, longwave_source_scale, longwave_source_temperature_grid,
              longwave_source_table, longwave_weights, shortwave_weights)
    return EcCKDTabulatedGasOpticsModel{FT, gas_name_tuple, map(typeof, fields)...}(fields...,
                                                                                    FT(stefan_boltzmann))
end

Base.eltype(::EcCKDTabulatedGasOpticsModel{FT}) where FT = FT
@inline gas_names(::EcCKDTabulatedGasOpticsModel{<:Any, GasNames}) where GasNames = GasNames

@inline function gas_value(gases::NamedTuple, name::Symbol, k)
    value = getproperty(gases, name)
    return value isa Number ? value : value[k]
end

# Gas containers are keyed by `Symbol` throughout. A `String`-keyed container
# must fail here rather than fall back silently: the `haskey(gases, :composite)`
# guards below would miss its keys and quietly change the optical depth.
@inline function gas_value(gases::AbstractDict, name::Symbol, k)
    value = gases[name]
    return value isa Number ? value : value[k]
end

@inline gas_value(gases::AbstractMatrix, gas_index::Integer, k) = gases[gas_index, k]

@inline gas_value(gases, name::Symbol, k) = begin
    value = getproperty(gases, name)
    value isa Number ? value : value[k]
end

@inline has_gas(gases::AbstractDict, name::Symbol) = haskey(gases, name)
@inline has_gas(gases, name::Symbol) = hasproperty(gases, name)

@inline gas_profile(gases::AbstractDict, name::Symbol) = gases[name]
@inline gas_profile(gases, name::Symbol) = getproperty(gases, name)

@inline function check_gas_profile_length(gases, name, Nz)
    profile = gas_profile(gases, name)
    profile isa Number && return nothing
    length(profile) >= Nz ||
        throw(DimensionMismatch("gas profile $name must contain at least Nz values"))
    return nothing
end

@inline function check_gas_profile_lengths(gases, names, Nz)
    for name in names
        check_gas_profile_length(gases, name, Nz)
    end
    return nothing
end

@generated function check_gas_profile_lengths(gases::NamedTuple{Keys},
                                              ::Val{Names},
                                              Nz) where {Keys, Names}
    checks = [:( check_gas_profile_length(gases, $(QuoteNode(name)), Nz) )
              for name in Names]
    return quote
        $(checks...)
        nothing
    end
end

@inline check_gas_profile_lengths(gases, ::Val{Names}, Nz) where Names = check_gas_profile_lengths(gases, Names, Nz)

@inline function check_tabulated_gas_profile_lengths(gases, names, Nz)
    check_gas_profile_lengths(gases, names, Nz)
    if !(:composite in names) && has_gas(gases, :composite)
        check_gas_profile_length(gases, :composite, Nz)
    end
    return nothing
end

@generated function check_tabulated_gas_profile_lengths(gases::NamedTuple{Keys},
                                                        ::Val{Names},
                                                        Nz) where {Keys, Names}
    names_to_check = collect(Names)
    :composite in Keys && !(:composite in Names) && push!(names_to_check, :composite)
    checks = [:( check_gas_profile_length(gases, $(QuoteNode(name)), Nz) )
              for name in names_to_check]
    return quote
        $(checks...)
        nothing
    end
end

@inline check_tabulated_gas_profile_lengths(gases, ::Val{Names}, Nz) where Names =
    check_tabulated_gas_profile_lengths(gases, Names, Nz)

@inline source_temperature(atmosphere::ColumnAtmosphere, k) = atmosphere.temperature_layers[k]

@inline function bracket(grid, x)
    x <= grid[begin] && return firstindex(grid), firstindex(grid) + 1, zero(eltype(grid))
    last = lastindex(grid)
    x >= grid[last] && return last - 1, last, one(eltype(grid))

    lower = firstindex(grid)
    upper = last
    while upper - lower > 1
        mid = (lower + upper) >>> 1
        if x < grid[mid]
            upper = mid
        else
            lower = mid
        end
    end
    weight = (x - grid[lower]) / (grid[upper] - grid[lower])
    return lower, upper, weight
end

@inline function log_bracket(grid, x)
    # Uniform log spacing by file contract; clamp to the axis so off-table
    # inputs interpolate exactly to the edge nodes.
    step = log(grid[begin + 1]) - log(grid[begin])
    offset = (log(max(x, grid[begin])) - log(grid[begin])) / step
    lower = clamped_lower_index(offset, length(grid) - 2)
    weight = clamp(offset - lower, zero(offset), one(offset))
    return firstindex(grid) + lower, firstindex(grid) + lower + 1, weight
end

# Integer part of a nonnegative interpolation coordinate `x`, clamped to
# `[0, top]`, without the `InexactError` that `floor(Int, x)` throws on a
# non-finite `x` (inside a kernel that throw is an unrecoverable trap). The
# clamp is done in floating point first, so `Inf` lands on the top node; a
# `NaN` lands on index 0 and leaves its `NaN` in the caller's weight, so the
# bad input surfaces as `NaN` optics rather than as an aborted launch.
@inline function clamped_lower_index(x, top::Int)
    clamped = clamp(x, zero(x), oftype(x, top))
    return unsafe_trunc(Int, ifelse(isfinite(clamped), clamped, zero(x)))
end

@inline temperature_grid_length(grid::AbstractVector) = length(grid)
@inline temperature_grid_length(grid::AbstractMatrix) = size(grid, 2)

function validate_increasing_grid(grid, name)
    all(isfinite, grid) || throw(ArgumentError("$name must contain only finite values"))
    for i in (firstindex(grid) + 1):lastindex(grid)
        grid[i] > grid[i - 1] ||
            throw(ArgumentError("$name must be strictly increasing"))
    end
    return nothing
end

function validate_log_uniform_grid(grid, name)
    all(>(zero(eltype(grid))), grid) ||
        throw(ArgumentError("$name must contain only positive values"))
    validate_increasing_grid(grid, name)
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

validate_temperature_grid(grid::AbstractVector, _) = validate_increasing_grid(grid, "temperature_grid")

function validate_temperature_grid(grid::AbstractMatrix, pressure_count)
    size(grid, 1) == pressure_count ||
        throw(DimensionMismatch("temperature_grid pressure dimension must match pressure_grid"))
    all(isfinite, grid) ||
        throw(ArgumentError("temperature_grid must contain only finite values"))
    expected_step = grid[1, 2] - grid[1, 1]
    expected_step > 0 ||
        throw(ArgumentError("temperature_grid rows must be strictly increasing"))
    # The reference kernel likewise carries one temperature increment for the
    # whole pressure-dependent table.
    for iᵖ in axes(grid, 1), iᵀ in 2:size(grid, 2)
        step = grid[iᵖ, iᵀ] - grid[iᵖ, iᵀ - 1]
        step > 0 ||
            throw(ArgumentError("temperature_grid rows must be strictly increasing"))
        isapprox(step, expected_step; rtol = 1.0e-5, atol = 0.0) ||
            throw(ArgumentError("temperature_grid must use one uniform temperature increment"))
    end
    return nothing
end

@inline function pressure_axis_bracket(pressure_grid, pressure)
    return log_bracket(pressure_grid, pressure)
end

# `log_bracket` needs two grid points. Models without a dynamic H₂O table carry
# an empty grid, and `water_vapor_table_optical_depth` short-circuits before
# the bracket is ever indexed, so return a same-typed placeholder in that case.
@inline function water_vapor_axis_bracket(water_vapor_grid, water_vapor_mole_fraction)
    length(water_vapor_grid) < 2 &&
        return firstindex(water_vapor_grid), firstindex(water_vapor_grid), zero(eltype(water_vapor_grid))
    return log_bracket(water_vapor_grid, water_vapor_mole_fraction)
end

# Pressure/temperature interpolation stencil for a coefficient table: a pair of
# `(i0, i1, weight)` brackets. Brackets depend only on the layer state, so the
# runtime builds one per layer and reuses it across every g point and gas.
#
# `FT` is the *table's* element type, threaded explicitly rather than taken from
# the grids: the matrix-grid temperature index below is evaluated in it, and
# `EcCKDTabulatedGasOpticsModel` stores absorption tables as given, so their
# element type need not match the model's.
@inline table_stencil(::Type{FT},
                      pressure_grid,
                      temperature_grid::AbstractVector,
                      pressure,
                      temperature) where FT =
    (pressure_axis_bracket(pressure_grid, pressure), bracket(temperature_grid, temperature))

@inline function table_stencil(::Type{FT},
                               pressure_grid,
                               temperature_grid::AbstractMatrix,
                               pressure,
                               temperature) where FT
    pressure_bracket = pressure_axis_bracket(pressure_grid, pressure)
    i₀ᵖ, i₁ᵖ, wᵖ = pressure_bracket
    temperature_origin = (one(FT) - wᵖ) * temperature_grid[i₀ᵖ, 1] +
                         wᵖ * temperature_grid[i₁ᵖ, 1]
    temperature_step = temperature_grid[1, 2] - temperature_grid[1, 1]
    temperature_index = one(FT) + clamp((temperature - temperature_origin) / temperature_step,
                                        zero(FT),
                                        FT(size(temperature_grid, 2)) - FT(1.0001))
    # `temperature_index` is at least 1 unless the state is `NaN`; see
    # `clamped_lower_index` for why the conversion must not throw.
    i₀ᵀ = 1 + clamped_lower_index(temperature_index - one(FT), size(temperature_grid, 2) - 2)
    return pressure_bracket, (i₀ᵀ, i₀ᵀ + 1, temperature_index - i₀ᵀ)
end

@inline function interpolate_table(table::AbstractArray{<:Any, 4}, gpoint, j, stencil)
    (i₀ᵖ, i₁ᵖ, wᵖ), (i₀ᵀ, i₁ᵀ, wᵀ) = stencil
    # Corner values c₍pressure node₎₍temperature node₎, interpolated first in
    # pressure (c₀, c₁ at the two temperature nodes) and then in temperature.
    c₀₀ = table[gpoint, j, i₀ᵖ, i₀ᵀ]
    c₁₀ = table[gpoint, j, i₁ᵖ, i₀ᵀ]
    c₀₁ = table[gpoint, j, i₀ᵖ, i₁ᵀ]
    c₁₁ = table[gpoint, j, i₁ᵖ, i₁ᵀ]
    c₀ = c₀₀ + wᵖ * (c₁₀ - c₀₀)
    c₁ = c₀₁ + wᵖ * (c₁₁ - c₀₁)
    return c₀ + wᵀ * (c₁ - c₀)
end

@inline function interpolate_source_table(table::AbstractMatrix, gpoint, temperature_bracket)
    i₀ᵀ, i₁ᵀ, wᵀ = temperature_bracket
    return table[gpoint, i₀ᵀ] + wᵀ * (table[gpoint, i₁ᵀ] - table[gpoint, i₀ᵀ])
end

@inline function interpolate_water_vapor_table(table::AbstractArray{<:Any, 4}, gpoint, stencil, water_vapor_bracket)
    (i₀ᵖ, i₁ᵖ, wᵖ), (i₀ᵀ, i₁ᵀ, wᵀ) = stencil
    i₀ᴴ, i₁ᴴ, wᴴ = water_vapor_bracket

    # Corner values c₍pressure₎₍temperature₎₍H₂O₎, interpolated in pressure,
    # then temperature (c₀₀ … c₁₁ at the remaining nodes), then H₂O (c₀, c₁).
    c₀₀₀ = table[gpoint, i₀ᵖ, i₀ᵀ, i₀ᴴ]
    c₁₀₀ = table[gpoint, i₁ᵖ, i₀ᵀ, i₀ᴴ]
    c₀₁₀ = table[gpoint, i₀ᵖ, i₁ᵀ, i₀ᴴ]
    c₁₁₀ = table[gpoint, i₁ᵖ, i₁ᵀ, i₀ᴴ]
    c₀₀₁ = table[gpoint, i₀ᵖ, i₀ᵀ, i₁ᴴ]
    c₁₀₁ = table[gpoint, i₁ᵖ, i₀ᵀ, i₁ᴴ]
    c₀₁₁ = table[gpoint, i₀ᵖ, i₁ᵀ, i₁ᴴ]
    c₁₁₁ = table[gpoint, i₁ᵖ, i₁ᵀ, i₁ᴴ]

    c₀₀ = c₀₀₀ + wᵖ * (c₁₀₀ - c₀₀₀)
    c₁₀ = c₀₁₀ + wᵖ * (c₁₁₀ - c₀₁₀)
    c₀₁ = c₀₀₁ + wᵖ * (c₁₀₁ - c₀₀₁)
    c₁₁ = c₀₁₁ + wᵖ * (c₁₁₁ - c₀₁₁)
    c₀ = c₀₀ + wᵀ * (c₁₀ - c₀₀)
    c₁ = c₀₁ + wᵀ * (c₁₁ - c₀₁)
    return c₀ + wᴴ * (c₁ - c₀)
end

# The temperature is converted to the model precision before bracketing, as
# `gas_optics_stencil` does, so the bracket and the sources built on it are
# in `FT` whatever the caller's temperature type.
#
# Off the table the source follows ecRad's `calc_planck_function`: above the
# last node it is extrapolated linearly from the last interval, which the
# bracket expresses as a weight above one (the reference tables end at
# 350 K, which a hot land surface can exceed; holding B(350 K) there would
# under-emit by ≈ 4σT³ ≈ 10 W m⁻² per kelvin). Below the first node
# `longwave_source` scales B(T₁) linearly to zero.
@inline function source_table_bracket(model::EcCKDTabulatedGasOpticsModel{FT}, temperature) where FT
    model.longwave_source_table === nothing && return nothing
    grid = model.longwave_source_temperature_grid
    T = FT(temperature)
    i₀, i₁, w = bracket(grid, T)
    last = lastindex(grid)
    w_above = (T - grid[last - 1]) / (grid[last] - grid[last - 1])
    return i₀, i₁, ifelse(T > grid[last], w_above, w)
end

@inline function longwave_source(model::EcCKDTabulatedGasOpticsModel{FT},
                                 gpoint,
                                 temperature,
                                 source_bracket) where FT
    source_bracket === nothing &&
        return model.longwave_source_scale[gpoint] * model.stefan_boltzmann * FT(temperature)^4
    source = interpolate_source_table(model.longwave_source_table, gpoint, source_bracket)
    # Linear to zero below the first node, as in ecRad; the factor is exactly
    # one on and above the table, so in-range sources are untouched.
    T₁ = model.longwave_source_temperature_grid[begin]
    return source * min(FT(temperature) / T₁, one(FT))
end

@generated function accumulate_optical_depth(gases::NamedTuple,
                                             coefficients::AbstractMatrix{FT},
                                             ::Val{GasNames},
                                             gpoint,
                                             k) where {FT, GasNames}
    terms = [
        :(coefficients[gpoint, $j] * FT(gas_value(gases, $(QuoteNode(name)), k)))
        for (j, name) in enumerate(GasNames)
    ]
    isempty(terms) && return :(zero(FT))
    return foldl((a, b) -> :($a + $b), terms; init = :(zero(FT)))
end

@inline function accumulate_optical_depth(gases,
                                          coefficients::AbstractMatrix{FT},
                                          gas_names::Tuple,
                                          gpoint,
                                          k) where FT
    τ = zero(FT)
    for j in eachindex(gas_names)
        τ += coefficients[gpoint, j] * FT(gas_value(gases, gas_names[j], k))
    end
    return τ
end

@inline accumulate_optical_depth(gases,
                                 coefficients::AbstractMatrix{FT},
                                 ::Val{GasNames},
                                 gpoint,
                                 k) where {FT, GasNames} = accumulate_optical_depth(gases, coefficients, GasNames, gpoint, k)

@generated function accumulate_tabulated_optical_depth(gases::NamedTuple,
                                                       coefficients::AbstractArray{FT, 4},
                                                       gas_reference_mole_fractions,
                                                       ::Val{GasNames},
                                                       gpoint,
                                                       k,
                                                       stencil) where {FT, GasNames}
    gas_fields = fieldnames(gases)
    has_composite = :composite in gas_fields
    terms = Expr[]
    for (j, name) in enumerate(GasNames)
        amount = :(FT(gas_value(gases, $(QuoteNode(name)), k)))
        if has_composite
            amount = :($amount -
                       FT(gas_reference_mole_fractions[$j]) *
                       FT(gas_value(gases, :composite, k)))
        end
        push!(terms, :(interpolate_table(coefficients, gpoint, $j, stencil) * $amount))
    end
    isempty(terms) && return :(zero(FT))
    return foldl((a, b) -> :($a + $b), terms; init = :(zero(FT)))
end

@inline function accumulate_tabulated_optical_depth(gases,
                                                    coefficients::AbstractArray{FT, 4},
                                                    gas_names::Tuple,
                                                    gas_reference_mole_fractions,
                                                    gpoint,
                                                    k,
                                                    stencil) where FT
    τ = zero(FT)
    for j in eachindex(gas_names)
        amount = FT(gas_value(gases, gas_names[j], k))
        reference = FT(gas_reference_mole_fractions[j])
        if reference != zero(FT) && has_gas(gases, :composite)
            amount -= reference * FT(gas_value(gases, :composite, k))
        end
        τ += interpolate_table(coefficients, gpoint, j, stencil) * amount
    end
    return τ
end

@inline accumulate_tabulated_optical_depth(gases,
                                           coefficients::AbstractArray{FT, 4},
                                           gas_reference_mole_fractions,
                                           ::Val{GasNames},
                                           gpoint,
                                           k,
                                           stencil) where {FT, GasNames} =
    accumulate_tabulated_optical_depth(gases, coefficients, GasNames, gas_reference_mole_fractions, gpoint, k, stencil)

function check_ecckd_optics_shapes(longwave::LongwaveOptics,
                                   shortwave::ShortwaveOptics,
                                   model::EcCKDGasOpticsModel,
                                   atmosphere::ColumnAtmosphere)
    Nz = length(atmosphere.temperature_layers)
    check_gas_profile_lengths(atmosphere.gases, Val(gas_names(model)), Nz)
    interface_sources = longwave.source_top !== nothing || longwave.source_bottom !== nothing
    (longwave.source_top === nothing) == (longwave.source_bottom === nothing) ||
        throw(ArgumentError("longwave source_top and source_bottom must both be provided or both be nothing"))
    if interface_sources
        length(atmosphere.temperature_interfaces) == Nz + 1 ||
            throw(DimensionMismatch("temperature_interfaces must contain Nz + 1 values"))
    end
    size(longwave.optical_depth) == (size(model.longwave_absorption, 1), Nz) ||
        throw(DimensionMismatch("longwave optical_depth must have shape (Nlongwave_gpoints, Nz)"))
    size(longwave.source) == size(longwave.optical_depth) ||
        throw(DimensionMismatch("longwave source must have shape (Nlongwave_gpoints, Nz)"))
    longwave.source_top === nothing || size(longwave.source_top) == size(longwave.optical_depth) ||
        throw(DimensionMismatch("longwave source_top must have shape (Nlongwave_gpoints, Nz)"))
    longwave.source_bottom === nothing || size(longwave.source_bottom) == size(longwave.optical_depth) ||
        throw(DimensionMismatch("longwave source_bottom must have shape (Nlongwave_gpoints, Nz)"))
    size(shortwave.optical_depth) == (size(model.shortwave_absorption, 1), Nz) ||
        throw(DimensionMismatch("shortwave optical_depth must have shape (Nshortwave_gpoints, Nz)"))
    size(shortwave.rayleigh_optical_depth) == size(shortwave.optical_depth) ||
        throw(DimensionMismatch("shortwave rayleigh_optical_depth must have shape (Nshortwave_gpoints, Nz)"))
    length(longwave.weights) == size(model.longwave_absorption, 1) ||
        throw(DimensionMismatch("longwave weights must have length Nlongwave_gpoints"))
    length(shortwave.weights) == size(model.shortwave_absorption, 1) ||
        throw(DimensionMismatch("shortwave weights must have length Nshortwave_gpoints"))
    return nothing
end

function check_ecckd_optics_shapes(longwave::LongwaveOptics,
                                   shortwave::ShortwaveOptics,
                                   model::EcCKDTabulatedGasOpticsModel,
                                   atmosphere::ColumnAtmosphere)
    Nz = length(atmosphere.temperature_layers)
    length(atmosphere.pressure_layers) == Nz ||
        throw(DimensionMismatch("pressure_layers must contain Nz values"))
    length(atmosphere.pressure_interfaces) == Nz + 1 ||
        throw(DimensionMismatch("pressure_interfaces must contain Nz + 1 values"))
    check_tabulated_gas_profile_lengths(atmosphere.gases, Val(gas_names(model)), Nz)
    interface_sources = longwave.source_top !== nothing || longwave.source_bottom !== nothing
    (longwave.source_top === nothing) == (longwave.source_bottom === nothing) ||
        throw(ArgumentError("longwave source_top and source_bottom must both be provided or both be nothing"))
    if interface_sources
        length(atmosphere.temperature_interfaces) == Nz + 1 ||
            throw(DimensionMismatch("temperature_interfaces must contain Nz + 1 values"))
    end
    size(longwave.optical_depth) == (size(model.longwave_absorption, 1), Nz) ||
        throw(DimensionMismatch("longwave optical_depth must have shape (Nlongwave_gpoints, Nz)"))
    size(longwave.source) == size(longwave.optical_depth) ||
        throw(DimensionMismatch("longwave source must have shape (Nlongwave_gpoints, Nz)"))
    longwave.source_top === nothing || size(longwave.source_top) == size(longwave.optical_depth) ||
        throw(DimensionMismatch("longwave source_top must have shape (Nlongwave_gpoints, Nz)"))
    longwave.source_bottom === nothing || size(longwave.source_bottom) == size(longwave.optical_depth) ||
        throw(DimensionMismatch("longwave source_bottom must have shape (Nlongwave_gpoints, Nz)"))
    size(shortwave.optical_depth) == (size(model.shortwave_absorption, 1), Nz) ||
        throw(DimensionMismatch("shortwave optical_depth must have shape (Nshortwave_gpoints, Nz)"))
    size(shortwave.rayleigh_optical_depth) == size(shortwave.optical_depth) ||
        throw(DimensionMismatch("shortwave rayleigh_optical_depth must have shape (Nshortwave_gpoints, Nz)"))
    length(longwave.weights) == size(model.longwave_absorption, 1) ||
        throw(DimensionMismatch("longwave weights must have length Nlongwave_gpoints"))
    length(shortwave.weights) == size(model.shortwave_absorption, 1) ||
        throw(DimensionMismatch("shortwave weights must have length Nshortwave_gpoints"))
    return nothing
end

"""
    optical_properties!(longwave, shortwave, model::EcCKDGasOpticsModel, atmosphere)

Fill caller-owned longwave and shortwave optical-property arrays from an
already-interpolated ecCKD-style model. This method performs no NetCDF I/O and
does not allocate output arrays.
"""
function optical_properties!(longwave::LongwaveOptics{FT, <:AbstractMatrix},
                             shortwave::ShortwaveOptics{FT, <:AbstractMatrix},
                             model::EcCKDGasOpticsModel{FT},
                             atmosphere::ColumnAtmosphere) where FT
    check_ecckd_optics_shapes(longwave, shortwave, model, atmosphere)

    Nz = length(atmosphere.temperature_layers)
    names = gas_names(model)

    # Each layer is one call into the scalar layer API of `ecckd_layer.jl`
    # with its gas amounts picked out as scalars, so a host kernel that calls
    # those functions directly reproduces this loop bit for bit.
    for k in 1:Nz
        temperature = source_temperature(atmosphere, k)
        gases = layer_gases(atmosphere.gases, Val(names), k)
        # Fixed coefficients: the stencil and source bracket are `nothing`, and
        # the pressure and H₂O arguments they would have consumed are unused.
        stencil = gas_optics_stencil(model, nothing, temperature, nothing)
        source_bracket = source_table_bracket(model, temperature)

        for gpoint in axes(model.longwave_absorption, 1)
            longwave.optical_depth[gpoint, k] = longwave_optical_depth(model, gpoint, gases, stencil)
            longwave.source[gpoint, k] = longwave_source(model, gpoint, temperature, source_bracket)
            if longwave.source_top !== nothing && longwave.source_bottom !== nothing
                temperature_top = atmosphere.temperature_interfaces[k]
                temperature_bottom = atmosphere.temperature_interfaces[k + 1]
                longwave.source_top[gpoint, k] = longwave_source(model, gpoint, temperature_top, source_bracket)
                longwave.source_bottom[gpoint, k] = longwave_source(model, gpoint, temperature_bottom, source_bracket)
            end
        end

        for gpoint in axes(model.shortwave_absorption, 1)
            shortwave.optical_depth[gpoint, k] = shortwave_optical_depth(model, gpoint, gases, stencil)
            shortwave.rayleigh_optical_depth[gpoint, k] = rayleigh_optical_depth(model, gpoint, nothing)
            shortwave.scattering_asymmetry[gpoint, k] = zero(FT)
        end
    end

    longwave.weights .= model.longwave_weights
    shortwave.weights .= model.shortwave_weights
    return longwave, shortwave
end

@inline has_dynamic_water_vapor(model::EcCKDTabulatedGasOpticsModel) = length(model.water_vapor_mole_fraction_grid) > 0

@inline layer_pressure_thickness(atmosphere::ColumnAtmosphere, k) =
    atmosphere.pressure_interfaces[k + 1] - atmosphere.pressure_interfaces[k]

# Hydrostatic molar amount of layer `k` in the model precision, with gravity
# and the dry-air molar mass of the column's own constants.
@inline function layer_air_moles(::Type{FT}, atmosphere::ColumnAtmosphere, k) where FT
    (; gravity, dry_air_molar_mass) = atmosphere.constants
    Δp = layer_pressure_thickness(atmosphere, k)
    return hydrostatic_air_moles(FT(Δp), FT(gravity), FT(dry_air_molar_mass))
end

# Layer H₂O mole fraction relative to dry air for the H₂O-axis bracket: the
# `composite` amount when the column carries one, else the hydrostatic molar
# amount of the layer, `Δp / (g mᵈ)`.
@inline function layer_water_vapor_mole_fraction(::Type{FT},
                                                 atmosphere::ColumnAtmosphere,
                                                 k) where FT
    water_vapor_moles = max(FT(gas_value(atmosphere.gases, :h2o, k)), zero(FT))
    dry_air_moles = has_gas(atmosphere.gases, :composite) ?
        max(FT(gas_value(atmosphere.gases, :composite, k)), sqrt(eps(FT))) :
        max(layer_air_moles(FT, atmosphere, k), sqrt(eps(FT)))
    return water_vapor_moles / dry_air_moles
end

"""
    optical_properties!(longwave, shortwave, model::EcCKDTabulatedGasOpticsModel, atmosphere)

Fill caller-owned longwave and shortwave optical-property arrays from
pressure/temperature coefficient tables using bilinear interpolation. This is
the lightweight runtime LUT path for ecCKD-style gas optics.
"""
function optical_properties!(longwave::LongwaveOptics{FT, <:AbstractMatrix},
                             shortwave::ShortwaveOptics{FT, <:AbstractMatrix},
                             model::EcCKDTabulatedGasOpticsModel{FT},
                             atmosphere::ColumnAtmosphere) where FT
    check_ecckd_optics_shapes(longwave, shortwave, model, atmosphere)

    Nz = length(atmosphere.temperature_layers)
    names = gas_names(model)

    for k in 1:Nz
        pressure = atmosphere.pressure_layers[k]
        temperature = atmosphere.temperature_layers[k]
        water_vapor_mole_fraction = has_dynamic_water_vapor(model) ?
            layer_water_vapor_mole_fraction(FT, atmosphere, k) : zero(FT)

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

        # Every interpolation bracket depends only on the layer, so build the
        # stencil once here instead of once per g point and gas. From here on
        # the layer is scalar: its gas amounts are picked out of the column
        # container, and each g point is one call into the layer API of
        # `ecckd_layer.jl`, so a host kernel calling those functions directly
        # reproduces this loop bit for bit.
        stencil = gas_optics_stencil(model, pressure, temperature, water_vapor_mole_fraction)
        source_bracket = source_table_bracket(model, temperature)
        source_top_bracket = source_table_bracket(model, temperature_top)
        source_bottom_bracket = source_table_bracket(model, temperature_bottom)
        gases = layer_gases(atmosphere.gases, Val(names), k)
        air_moles = layer_air_moles(FT, atmosphere, k)

        for gpoint in axes(model.longwave_absorption, 1)
            longwave.optical_depth[gpoint, k] = longwave_optical_depth(model, gpoint, gases, stencil)
            longwave.source[gpoint, k] = longwave_source(model, gpoint, temperature, source_bracket)
            if interface_sources
                longwave.source_top[gpoint, k] = longwave_source(model, gpoint, temperature_top, source_top_bracket)
                longwave.source_bottom[gpoint, k] = longwave_source(model, gpoint, temperature_bottom, source_bottom_bracket)
            end
        end

        for gpoint in axes(model.shortwave_absorption, 1)
            shortwave.optical_depth[gpoint, k] = shortwave_optical_depth(model, gpoint, gases, stencil)
            shortwave.rayleigh_optical_depth[gpoint, k] = rayleigh_optical_depth(model, gpoint, air_moles)
            shortwave.scattering_asymmetry[gpoint, k] = zero(FT)
        end
    end

    longwave.weights .= model.longwave_weights
    shortwave.weights .= model.shortwave_weights
    return longwave, shortwave
end
