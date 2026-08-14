"""
$(TYPEDEF)

Dependency-free summary of an ecCKD CKD-definition file.

This structure stores the schema-level information needed before materializing
lookup tables into runtime gas-optics models. A NetCDF reader extension can
populate it from official ecCKD files without making `NCDatasets.jl` a hard
dependency of the core package.

Fields are

$(TYPEDFIELDS)
"""
struct EcCKDDefinition{D, V, A}
    "Model name from file metadata or user-provided configuration."
    model_name::String
    "Model version from file metadata or user-provided configuration."
    version::String
    "Named dimensions and their lengths."
    dimensions::D
    "Named variables and their dimension tuples."
    variables::V
    "Additional global attributes."
    attributes::A
end

function EcCKDDefinition(; model_name::AbstractString,
                         version::AbstractString = "unknown",
                         dimensions,
                         variables,
                         attributes = (;))
    return EcCKDDefinition(String(model_name), String(version),
                           dimensions, variables, attributes)
end

"""
$(TYPEDEF)

Small validation-oriented summary returned by [`summarize_ecckd_definition`](@ref).

Fields are

$(TYPEDFIELDS)
"""
struct EcCKDSchemaSummary
    model_name::String
    version::String
    lw_bands::Int
    sw_bands::Int
    lw_gpoints::Int
    sw_gpoints::Int
    gases::Vector{String}
    pressure_grid_size::Int
    temperature_grid_size::Int
    source_tables_present::Bool
    rayleigh_tables_present::Bool
end

"""
$(TYPEDEF)

Named pair of official ecCKD longwave and shortwave CKD-definition files.

Fields are

$(TYPEDFIELDS)
"""
struct EcCKDModelSpec
    "Public model-pair selector, for example `:climate_32x32`."
    name::Symbol
    "Official longwave CKD-definition key."
    longwave::Symbol
    "Official shortwave CKD-definition key."
    shortwave::Symbol
    "Human-readable summary for docs and logging."
    description::String
end

const _OFFICIAL_ECCKD_MODELS = (
    "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc",
    "ecckd-1.0_sw_climate_rgb-32b_ckd-definition.nc",
    "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
    "ecckd-1.2_sw_climate_window-64b_ckd-definition.nc",
    "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc",
    "ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc",
)

const _OFFICIAL_ECCKD_DEFAULTS = (
    longwave_32 = "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc",
    shortwave_32 = "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc",
    longwave_64 = "ecckd-1.2_lw_climate_narrow-64b_ckd-definition.nc",
    shortwave_64 = "ecckd-1.2_sw_climate_window-64b_ckd-definition.nc",
    shortwave_96 = "ecckd-1.4_sw_climate_vfine-96b_ckd-definition.nc",
)

const _OFFICIAL_ECCKD_MODEL_SPECS = (
    climate_32x32 = EcCKDModelSpec(:climate_32x32, :longwave_32, :shortwave_32,
                                   "ecCKD climate model with 32 longwave and 32 shortwave g-points"),
    climate_32x64 = EcCKDModelSpec(:climate_32x64, :longwave_32, :shortwave_64,
                                   "ecCKD climate model with 32 longwave and 64 shortwave g-points"),
    climate_32x96 = EcCKDModelSpec(:climate_32x96, :longwave_32, :shortwave_96,
                                   "ecCKD climate model with 32 longwave and 96 shortwave g-points"),
    climate_64x32 = EcCKDModelSpec(:climate_64x32, :longwave_64, :shortwave_32,
                                   "ecCKD climate model with 64 longwave and 32 shortwave g-points"),
    climate_64x64 = EcCKDModelSpec(:climate_64x64, :longwave_64, :shortwave_64,
                                   "ecCKD climate model with 64 longwave and 64 shortwave g-points"),
    climate_64x96 = EcCKDModelSpec(:climate_64x96, :longwave_64, :shortwave_96,
                                   "ecCKD climate model with 64 longwave and 96 shortwave g-points"),
)

const _ECRAD_DATA_DIR_CACHE = Ref(Dict{String, String}())

function _package_root()
    return normpath(joinpath(@__DIR__, "..", ".."))
end

function _artifact_toml_path()
    return joinpath(_package_root(), "Artifacts.toml")
end

function _first_existing_directory(paths)
    for path in paths
        path isa AbstractString && isdir(path) && return normpath(path)
    end
    return nothing
end

function _artifact_root(name::String; require::Bool)
    toml_path = _artifact_toml_path()
    isfile(toml_path) || return nothing
    if !require
        hash = artifact_hash(name, toml_path)
        hash === nothing && return nothing
        path = artifact_path(hash)
        return isdir(path) ? normpath(path) : nothing
    end
    return nothing
end

function _ecrad_artifact_root(; require::Bool = false)
    root = _artifact_root("ecrad_data"; require)
    root === nothing || return root
    require || return nothing
    try
        path = @artifact_str("ecrad_data")
        return isdir(path) ? normpath(path) : nothing
    catch err
        @warn "Unable to resolve lazy ecrad_data artifact; falling back to RH_ECRAD_DATA_PATH or validation checkout" exception = (err, catch_backtrace())
        return nothing
    end
end

function _ecckd_source_artifact_root(; require::Bool = false)
    root = _artifact_root("ecckd_source"; require)
    root === nothing || return root
    require || return nothing
    try
        path = @artifact_str("ecckd_source")
        return isdir(path) ? normpath(path) : nothing
    catch err
        @warn "Unable to resolve lazy ecckd_source artifact; falling back to RH_ECCKD_SOURCE_PATH or validation checkout" exception = (err, catch_backtrace())
        return nothing
    end
end

function _source_root_with_file(root, filename)
    root === nothing && return nothing
    isdir(root) || return nothing
    isfile(joinpath(root, filename)) && return normpath(root)
    for child in readdir(root)
        path = joinpath(root, child)
        if isdir(path) && isfile(joinpath(path, filename))
            return normpath(path)
        end
    end
    return nothing
end

"""
    ecrad_data_path(; require=false)

Return the root directory containing ecRad data files. Resolution order is:
`RH_ECRAD_DATA_PATH`, the lazy `ecrad_data` artifact in `Artifacts.toml`, then
the local validation checkout at `validation/external/ecrad`. GitHub archive
artifacts may contain the data under one top-level child directory; individual
file resolution handles both `<root>/data` and `<root>/<archive>/data`.
"""
function ecrad_data_path(; require::Bool = false)
    root = _first_existing_directory((
        get(ENV, "RH_ECRAD_DATA_PATH", nothing),
        _ecrad_artifact_root(; require),
        joinpath(_package_root(), "validation", "external", "ecrad"),
    ))
    if root === nothing && require
        throw(ArgumentError("ecRad data are not available; set RH_ECRAD_DATA_PATH or instantiate the ecrad_data artifact"))
    end
    return root
end

function _ecrad_data_dir(root::AbstractString)
    normalized_root = normpath(root)
    cache = _ECRAD_DATA_DIR_CACHE[]
    cached = get(cache, normalized_root, nothing)
    cached !== nothing && isdir(cached) && return cached

    direct = joinpath(normalized_root, "data")
    if isdir(direct)
        resolved = normpath(direct)
        cache[normalized_root] = resolved
        return resolved
    end

    for child in readdir(normalized_root)
        path = joinpath(normalized_root, child, "data")
        if isdir(path)
            resolved = normpath(path)
            cache[normalized_root] = resolved
            return resolved
        end
    end

    cache[normalized_root] = normalized_root
    return normalized_root
end

"""
    ecckd_source_path(; require=false)

Return the root directory containing the official ecCKD source tree. Resolution
order is `RH_ECCKD_SOURCE_PATH`, the lazy `ecckd_source` artifact in
`Artifacts.toml`, then the local validation checkout at
`validation/external/ecckd`.
"""
function ecckd_source_path(; require::Bool = false)
    root = _source_root_with_file(get(ENV, "RH_ECCKD_SOURCE_PATH", nothing), "README.md")
    root === nothing && (root = _source_root_with_file(_ecckd_source_artifact_root(; require), "README.md"))
    root === nothing && (root = _source_root_with_file(
        joinpath(_package_root(), "validation", "external", "ecckd"), "README.md"))
    if root === nothing && require
        throw(ArgumentError("ecCKD source is not available; set RH_ECCKD_SOURCE_PATH or instantiate the ecckd_source artifact"))
    end
    return root
end

function _ecrad_data_file(filename::AbstractString; require::Bool = true)
    root = ecrad_data_path(; require)
    root === nothing && return nothing
    data_dir = _ecrad_data_dir(root)
    candidates = String[joinpath(data_dir, filename), joinpath(root, filename)]
    for path in candidates
        isfile(path) && return normpath(path)
    end
    require && throw(ArgumentError("official ecCKD file not found in $(root): $(filename)"))
    return nothing
end

"""
    official_ecckd_model_inventory()

Return the official ecCKD CKD-definition filenames distributed with the pinned
ecRad data artifact.
"""
official_ecckd_model_inventory() = collect(_OFFICIAL_ECCKD_MODELS)

"""
    official_ecckd_model_specs()

Return the named official ecCKD model pairs supported by the high-level
selection interface. Each value is an [`EcCKDModelSpec`](@ref).
"""
official_ecckd_model_specs() = _OFFICIAL_ECCKD_MODEL_SPECS

function _normalize_ecckd_model_name(name)
    key = lowercase(replace(String(name), '-' => '_'))
    if occursin('x', key) && !isempty(key) && isdigit(first(key))
        key = "climate_" * key
    end
    return Symbol(key)
end

"""
    official_ecckd_model_spec(name=:climate_64x32)

Return an [`EcCKDModelSpec`](@ref) for an official ecCKD model pair. `name` may
be a full selector such as `:climate_32x32` or a compact string such as
`"32x32"`.
"""
function official_ecckd_model_spec(name = :climate_64x32)
    name isa EcCKDModelSpec && return name
    key = _normalize_ecckd_model_name(name)
    if !haskey(_OFFICIAL_ECCKD_MODEL_SPECS, key)
        available = join(keys(_OFFICIAL_ECCKD_MODEL_SPECS), ", ")
        throw(ArgumentError("unknown official ecCKD model pair: $(name). Available pairs are $(available)"))
    end
    return getproperty(_OFFICIAL_ECCKD_MODEL_SPECS, key)
end

"""
    official_ecckd_definition_path(name; require=true)

Return the path to an official ecCKD CKD-definition file. `name` may be a full
filename from [`official_ecckd_model_inventory`](@ref) or one of
`:longwave_32`, `:shortwave_32`, `:longwave_64`, `:shortwave_64`, or
`:shortwave_96`.
"""
function official_ecckd_definition_path(name; require::Bool = true)
    filename = if name isa Symbol
        haskey(_OFFICIAL_ECCKD_DEFAULTS, name) ||
            throw(ArgumentError("unknown official ecCKD model key: $(name)"))
        getproperty(_OFFICIAL_ECCKD_DEFAULTS, name)
    else
        String(name)
    end
    return _ecrad_data_file(filename; require)
end

"""
    official_ecckd_definition_paths(; longwave=:longwave_64, shortwave=:shortwave_32)

Return `(longwave=..., shortwave=...)` paths for the default official ecCKD
runtime pair used by validation and examples.
"""
function official_ecckd_definition_paths(; longwave = :longwave_64,
                                         shortwave = :shortwave_32,
                                         require::Bool = true)
    return (
        longwave = official_ecckd_definition_path(longwave; require),
        shortwave = official_ecckd_definition_path(shortwave; require),
    )
end

"""
    official_ecckd_definition_paths(model; require=true)

Return `(longwave=..., shortwave=...)` paths for an official ecCKD model pair.
`model` accepts the same selectors as [`official_ecckd_model_spec`](@ref).
With `require=false`, this function returns `nothing` paths instead of
downloading lazy artifacts or throwing when the data are not already installed.
"""
function official_ecckd_definition_paths(model; require::Bool = true)
    spec = official_ecckd_model_spec(model)
    return official_ecckd_definition_paths(;
        longwave = spec.longwave,
        shortwave = spec.shortwave,
        require,
    )
end

const _ECCKD_DIM_ALIASES = (
    lw_bands = (:lw_band, :lw_bands, :band_lw, :bands_lw, :n_lw_bands),
    sw_bands = (:sw_band, :sw_bands, :band_sw, :bands_sw, :n_sw_bands),
    lw_gpoints = (:lw_gpoint, :lw_gpoints, :gpoint_lw, :gpoints_lw, :n_lw_gpoints),
    sw_gpoints = (:sw_gpoint, :sw_gpoints, :gpoint_sw, :gpoints_sw, :n_sw_gpoints),
    gas = (:gas, :gases, :absorber, :absorbers, :n_gases),
    pressure = (:pressure, :pressures, :p_ref, :pressure_grid, :n_pressure),
    temperature = (:temperature, :temperatures, :t_ref, :temperature_grid, :n_temperature),
)

@inline function _lookup_named(container, key::Symbol)
    if container isa NamedTuple
        return haskey(container, key) ? getproperty(container, key) : nothing
    elseif container isa AbstractDict
        return haskey(container, key) ? container[key] :
               haskey(container, String(key)) ? container[String(key)] : nothing
    else
        return hasproperty(container, key) ? getproperty(container, key) : nothing
    end
end

function _lookup_any(container, keys)
    for key in keys
        value = _lookup_named(container, key)
        value === nothing || return value
    end
    return nothing
end

function _has_named(container, key::Symbol)
    return _lookup_named(container, key) !== nothing
end

function _radiation_kind(definition::EcCKDDefinition)
    has_planck = _has_named(definition.variables, :planck_function)
    has_solar = _has_named(definition.variables, :solar_irradiance) ||
                _has_named(definition.variables, :solar_spectral_irradiance)
    has_lw = _variable_dims(definition, (:lw_absorption, :k_lw, :optical_depth_lw)) !== nothing
    has_sw = _variable_dims(definition, (:sw_absorption, :k_sw, :optical_depth_sw)) !== nothing

    if (has_planck || has_lw) && (has_solar || has_sw)
        return :combined
    elseif has_planck || has_lw
        return :longwave
    elseif has_solar || has_sw
        return :shortwave
    else
        return :unknown
    end
end

function _dimension(definition::EcCKDDefinition, name::Symbol)
    value = _lookup_any(definition.dimensions, getproperty(_ECCKD_DIM_ALIASES, name))
    if value === nothing && name in (:lw_bands, :sw_bands)
        kind = _radiation_kind(definition)
        if kind == :combined ||
           (kind == :longwave && name == :lw_bands) ||
           (kind == :shortwave && name == :sw_bands)
            value = _lookup_named(definition.dimensions, :band)
        end
    end
    if value === nothing && name in (:lw_gpoints, :sw_gpoints)
        kind = _radiation_kind(definition)
        if kind == :combined ||
           (kind == :longwave && name == :lw_gpoints) ||
           (kind == :shortwave && name == :sw_gpoints)
            value = _lookup_named(definition.dimensions, :g_point)
        end
    end
    if value === nothing && name == :gas
        value = _attribute(definition, (:n_gases, :gas_count), nothing)
    end
    value === nothing && return 0
    return Int(value)
end

function _variable_dims(definition::EcCKDDefinition, names)
    for name in names
        dims = _lookup_named(definition.variables, name)
        dims === nothing || return Tuple(Symbol.(dims))
    end
    return nothing
end

function _attribute(definition::EcCKDDefinition, names, default)
    value = _lookup_any(definition.attributes, names)
    value === nothing ? default : value
end

"""
    read_ecckd_definition(path)

Read an ecCKD CKD-definition file. The core package intentionally does not
depend on NetCDF libraries; NetCDF-backed loading should be provided by a
package extension. Until that extension is loaded, this method errors with a
clear message.
"""
function read_ecckd_definition(path::AbstractString)
    throw(ArgumentError("read_ecckd_definition(\"$path\") requires the NetCDF reader extension; load NCDatasets.jl before calling it"))
end

"""
    read_ecckd_tabulated_gas_optics(longwave_path, shortwave_path;
                                    gas_names = (:h2o, :co2),
                                    h2o_mole_fraction = 0.005)

Read official ecCKD CKD-definition files into a lightweight runtime
[`EcCKDTabulatedGasOpticsModel`](@ref). The core package does not depend on
NetCDF libraries, so NetCDF-backed loading is provided by the NCDatasets
extension.

This loader is a runtime-ingestion bridge, not a full ecRad-equivalent
ingestion path: it materializes coefficient tables for the requested
`gas_names` only, together with each gas's reference mole fraction for the
ecCKD relative-linear convention, the shortwave Rayleigh molar scattering
table, and the longwave Planck source table. When `:h2o` is requested, the
official H2O mole-fraction table dimension is kept; at runtime
[`optical_properties!`](@ref) computes the layer H2O mole fraction from the
`h2o` and `composite` gas amounts and interpolates the table per layer. The
`h2o_mole_fraction` keyword is not a gas input on that path — it is accepted
for compatibility/fallback sampling of non-dynamic four-dimensional H2O
tables. Longwave spectral weights are uniform over g-points; shortwave weights
are the file's per-g-point solar irradiance normalized to unit sum.
"""
function read_ecckd_tabulated_gas_optics(longwave_path::AbstractString,
                                         shortwave_path::AbstractString; kwargs...)
    throw(ArgumentError("read_ecckd_tabulated_gas_optics requires the NetCDF reader extension; load NCDatasets.jl before calling it"))
end

"""
    read_official_ecckd_gas_optics(model=:climate_64x32; kwargs...)

Load an official ecCKD model pair into an [`EcCKDTabulatedGasOpticsModel`](@ref).
`model` accepts selectors such as `:climate_32x32`, `:climate_64x32`, or
`"32x96"`. Keyword arguments are forwarded to
[`read_ecckd_tabulated_gas_optics`](@ref), for example `gas_names` and
`h2o_mole_fraction`.

This method resolves the package's lazy ecRad artifact when needed. Load
`NCDatasets.jl` before calling it so the NetCDF reader extension is active.
"""
function read_official_ecckd_gas_optics(model = :climate_64x32; require::Bool = true,
                                        kwargs...)
    paths = official_ecckd_definition_paths(model; require)
    if paths.longwave === nothing || paths.shortwave === nothing
        return nothing
    end
    return read_ecckd_tabulated_gas_optics(paths.longwave, paths.shortwave; kwargs...)
end

"""
    read_ecckd_definition(data)

Build an [`EcCKDDefinition`](@ref) from schema metadata. This method is intended
for tests and for reader extensions that have already extracted dimensions,
variables, and attributes from a backing file.
"""
function read_ecckd_definition(data)
    return EcCKDDefinition(;
        model_name = String(_lookup_named(data, :model_name)),
        version = String(_lookup_named(data, :version)),
        dimensions = _lookup_named(data, :dimensions),
        variables = _lookup_named(data, :variables),
        attributes = something(_lookup_named(data, :attributes), (;)),
    )
end

"""
    summarize_ecckd_definition(definition)

Return schema-level ecCKD metadata used by examples, validation reports, and
benchmark metadata.
"""
function summarize_ecckd_definition(definition::EcCKDDefinition)
    gas_names = _attribute(definition, (:gas_names, :gases), String[])
    gases = String.(collect(gas_names))
    source_dims = _variable_dims(definition, (:lw_source, :planck_source, :source_lw, :planck_function))
    rayleigh_dims = _variable_dims(definition, (:rayleigh, :sw_rayleigh, :rayleigh_optical_depth, :rayleigh_molar_scattering_coeff))

    return EcCKDSchemaSummary(
        definition.model_name,
        definition.version,
        _dimension(definition, :lw_bands),
        _dimension(definition, :sw_bands),
        _dimension(definition, :lw_gpoints),
        _dimension(definition, :sw_gpoints),
        gases,
        _dimension(definition, :pressure),
        _dimension(definition, :temperature),
        source_dims !== nothing,
        rayleigh_dims !== nothing,
    )
end

function Base.show(io::IO, summary::EcCKDSchemaSummary)
    print(io,
        "EcCKDSchemaSummary(",
        "model_name=$(summary.model_name), ",
        "version=$(summary.version), ",
        "LW bands=$(summary.lw_bands), ",
        "SW bands=$(summary.sw_bands), ",
        "LW g-points=$(summary.lw_gpoints), ",
        "SW g-points=$(summary.sw_gpoints), ",
        "gases=$(summary.gases), ",
        "pressure=$(summary.pressure_grid_size), ",
        "temperature=$(summary.temperature_grid_size), ",
        "sources=$(summary.source_tables_present), ",
        "rayleigh=$(summary.rayleigh_tables_present))")
end

function _require_positive!(errors, definition, name::Symbol)
    _dimension(definition, name) > 0 ||
        push!(errors, "missing or nonpositive dimension: $(name)")
    return errors
end

function _require_variable!(errors, definition, names, label)
    _variable_dims(definition, names) !== nothing ||
        push!(errors, "missing required variable group: $(label)")
    return errors
end

function _has_official_molar_absorption(definition::EcCKDDefinition)
    for name in propertynames(definition.variables)
        startswith(String(name), "molar_") && continue
        endswith(String(name), "_molar_absorption_coeff") && return true
    end
    return false
end

"""
    validate_ecckd_definition(definition; throw_on_error=true)

Validate required ecCKD schema metadata. Returns `true` when valid. When
`throw_on_error=false`, returns `(valid, errors)`.
"""
function validate_ecckd_definition(definition::EcCKDDefinition; throw_on_error::Bool = true)
    errors = String[]
    kind = _radiation_kind(definition)
    require_lw = kind in (:longwave, :combined, :unknown)
    require_sw = kind in (:shortwave, :combined, :unknown)

    require_lw && _require_positive!(errors, definition, :lw_bands)
    require_sw && _require_positive!(errors, definition, :sw_bands)
    require_lw && _require_positive!(errors, definition, :lw_gpoints)
    require_sw && _require_positive!(errors, definition, :sw_gpoints)
    _require_positive!(errors, definition, :gas)
    _require_positive!(errors, definition, :pressure)
    _require_positive!(errors, definition, :temperature)
    if !_has_official_molar_absorption(definition)
        require_lw && _require_variable!(errors, definition, (:lw_absorption, :k_lw, :optical_depth_lw), "longwave absorption")
        require_sw && _require_variable!(errors, definition, (:sw_absorption, :k_sw, :optical_depth_sw), "shortwave absorption")
    end

    gas_names = _attribute(definition, (:gas_names, :gases), String[])
    if !isempty(gas_names) && length(gas_names) != _dimension(definition, :gas)
        push!(errors, "gas_names length does not match gas dimension")
    end

    if !isempty(errors)
        if throw_on_error
            throw(ArgumentError("invalid ecCKD definition schema:\n" * join(errors, "\n")))
        else
            return (false, errors)
        end
    end
    return throw_on_error ? true : (true, errors)
end
