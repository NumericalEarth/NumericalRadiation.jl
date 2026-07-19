module NumericalRadiationNCDatasetsExt

using NumericalRadiation
using NCDatasets

import NumericalRadiation: EcCKDDefinition, EcCKDTabulatedGasOpticsModel
import NumericalRadiation: CloudScatteringTable, EcCKDSpectralMapping
import NumericalRadiation: read_ecckd_definition, read_ecckd_tabulated_gas_optics
import NumericalRadiation: read_cloud_scattering_table, read_ecckd_spectral_mapping

_sym(name) = Symbol(String(name))

function _dimensions(ds)
    pairs = (_sym(name) => Int(length) for (name, length) in ds.dim)
    return (; pairs...)
end

function _variables(ds)
    pairs = (_sym(name) => Tuple(Symbol.(NCDatasets.dimnames(ds[String(name)])))
             for name in keys(ds))
    return (; pairs...)
end

function _attributes(ds)
    attributes = Dict{Symbol, Any}(_sym(name) => ds.attrib[String(name)] for name in keys(ds.attrib))
    if haskey(ds, "n_gases")
        attributes[:n_gases] = Int(Array(ds["n_gases"])[1])
    end
    gas_names = String[]
    for name in keys(ds)
        text = String(name)
        if endswith(text, "_molar_absorption_coeff")
            push!(gas_names, replace(text, "_molar_absorption_coeff" => ""))
        end
    end
    if !isempty(gas_names)
        attributes[:gas_names] = gas_names
    end
    return attributes
end

function _attribute(attributes, names, default)
    for name in names
        haskey(attributes, name) && return attributes[name]
    end
    return default
end

"""
    read_ecckd_definition(path::String)

Read ecCKD schema metadata from a NetCDF file using `NCDatasets.jl`.
"""
function read_ecckd_definition(path::String)
    NCDataset(path, "r") do ds
        attributes = _attributes(ds)
        model_name = _attribute(attributes, (:model_name, :title, :name), basename(path))
        version = _attribute(attributes, (:version, :model_version), "unknown")
        return EcCKDDefinition(;
            model_name,
            version,
            dimensions = _dimensions(ds),
            variables = _variables(ds),
            attributes,
        )
    end
end

function _string_attribute(ds, name, default = "")
    haskey(ds.attrib, name) || return default
    return String(ds.attrib[name])
end

"""
    read_cloud_scattering_table(path::String)

Read an ecRad-style cloud scattering NetCDF file using `NCDatasets.jl`.
"""
function read_cloud_scattering_table(path::String)
    NCDataset(path, "r") do ds
        return CloudScatteringTable(
            medium = _string_attribute(ds, "medium"),
            particle_type = _string_attribute(ds, "particle_type"),
            wavenumber = Float64.(Array(ds["wavenumber"])),
            effective_radius = Float64.(Array(ds["effective_radius"])),
            mass_extinction_coefficient =
                Float64.(Array(ds["mass_extinction_coefficient"])),
            single_scattering_albedo =
                Float64.(Array(ds["single_scattering_albedo"])),
            asymmetry_factor = Float64.(Array(ds["asymmetry_factor"])),
        )
    end
end

"""
    read_ecckd_spectral_mapping(path::String)

Read resolved wavenumber intervals and `gpoint_fraction` from an ecCKD
CKD-definition file using `NCDatasets.jl`.
"""
function read_ecckd_spectral_mapping(path::String)
    NCDataset(path, "r") do ds
        interval_weight = if haskey(ds, "solar_spectral_irradiance")
            Float64.(Array(ds["solar_spectral_irradiance"]))
        elseif haskey(ds, "temperature_planck")
            wavenumber_midpoint =
                0.5 .* (Float64.(Array(ds["wavenumber1"])) .+
                        Float64.(Array(ds["wavenumber2"])))
            _planck_wavenumber_weight.(wavenumber_midpoint, 273.15)
        else
            ones(Float64, length(ds["wavenumber1"]))
        end
        return EcCKDSpectralMapping(
            wavenumber1 = Float64.(Array(ds["wavenumber1"])),
            wavenumber2 = Float64.(Array(ds["wavenumber2"])),
            gpoint_fraction = Float64.(Array(ds["gpoint_fraction"])),
            interval_weight = interval_weight,
        )
    end
end

function _planck_wavenumber_weight(wavenumber_cm, temperature)
    w = max(Float64(wavenumber_cm), 0.0)
    t = max(Float64(temperature), eps(Float64))
    exponent = 1.438776877 * w / t
    return exponent > 700 ? 0.0 : w^3 / expm1(exponent)
end

function _nearest_index(values, target)
    _, index = findmin(abs.(values .- target))
    return index
end

function _temperature_grid(ds)
    temperature = Array(ds["temperature"])
    ndims(temperature) == 1 && return Float64.(temperature)
    return Float64.(temperature)
end

function _coefficient_table(ds, gas::Symbol; h2o_mole_fraction, dynamic_h2o = false,
                            allow_missing = false)
    name = String(gas) * "_molar_absorption_coeff"
    if !haskey(ds, name)
        allow_missing && return nothing
        throw(ArgumentError("missing ecCKD coefficient variable: $name"))
    end
    table = Array(ds[name])
    if ndims(table) == 4
        gas == :h2o ||
            throw(ArgumentError("unsupported four-dimensional coefficient table for gas $gas"))
        dynamic_h2o && return zeros(Float64, size(table, 1), size(table, 2), size(table, 3))
        h2o_grid = Float64.(Array(ds["h2o_mole_fraction"]))
        ih2o = _nearest_index(h2o_grid, h2o_mole_fraction)
        return Float64.(table[:, :, :, ih2o])
    elseif ndims(table) == 3
        return Float64.(table)
    else
        throw(ArgumentError("expected $name to have 3 or 4 dimensions, got $(ndims(table))"))
    end
end

function _stack_coefficients(ds, gas_names; h2o_mole_fraction, dynamic_h2o = false,
                             allow_missing = false)
    first_table = nothing
    for gas in gas_names
        first_table = _coefficient_table(ds, gas;
                                         h2o_mole_fraction = h2o_mole_fraction,
                                         dynamic_h2o = dynamic_h2o,
                                         allow_missing = allow_missing)
        first_table === nothing || break
    end
    first_table === nothing &&
        throw(ArgumentError("no requested gases have ecCKD coefficient variables"))
    output = zeros(Float64, size(first_table, 1), length(gas_names),
                   size(first_table, 2), size(first_table, 3))
    for (igas, gas) in enumerate(gas_names)
        table = _coefficient_table(ds, gas;
                                   h2o_mole_fraction = h2o_mole_fraction,
                                   dynamic_h2o = dynamic_h2o,
                                   allow_missing = allow_missing)
        table === nothing && continue
        output[:, igas, :, :] .= table
    end
    return output
end

function _h2o_absorption_table(ds, gas_names)
    :h2o in gas_names || return nothing
    haskey(ds, "h2o_molar_absorption_coeff") || return nothing
    table = Array(ds["h2o_molar_absorption_coeff"])
    ndims(table) == 4 || return nothing
    return Float64.(table)
end

function _shortwave_weights(ds)
    if haskey(ds, "solar_irradiance")
        weights = Float64.(Array(ds["solar_irradiance"]))
        total = sum(weights)
        total > 0 && return weights ./ total
    end
    ng = size(ds["band_number"], 1)
    return fill(inv(Float64(ng)), ng)
end

function _longwave_source_table(ds, longwave_weights)
    temperature_grid = Float64.(Array(ds["temperature_planck"]))
    planck = Float64.(Array(ds["planck_function"]))
    size(planck, 1) == length(longwave_weights) ||
        throw(DimensionMismatch("planck_function g-point dimension must match longwave weights"))
    source = similar(planck)
    for ig in axes(planck, 1)
        source[ig, :] .= planck[ig, :] ./ longwave_weights[ig]
    end
    return temperature_grid, source
end

function _reference_mole_fractions(ds, gas_names)
    refs = zeros(Float64, length(gas_names))
    for (igas, gas) in enumerate(gas_names)
        name = String(gas) * "_reference_mole_fraction"
        haskey(ds, name) && (refs[igas] = Float64(Array(ds[name])[]))
    end
    return refs
end

"""
    read_ecckd_tabulated_gas_optics(longwave_path, shortwave_path; gas_names=(:h2o, :co2))

Materialize selected official ecCKD gas coefficient tables into
`EcCKDTabulatedGasOpticsModel`.

This helper is intentionally a runtime-ingestion bridge, not a claim of full
ecRad equivalence. It stacks the `<gas>_molar_absorption_coeff` tables for the
requested `gas_names` only (gases absent from the shortwave file contribute
zero), passes the pressure-dependent official temperature grid through as a
matrix for the runtime interpolation kernel, and reads each gas's
`<gas>_reference_mole_fraction` so the runtime can apply the ecCKD
relative-linear convention. When `:h2o` is requested, the official
four-dimensional H2O table is carried with its mole-fraction dimension intact;
the runtime computes the layer H2O mole fraction from the `h2o` and
`composite` gas amounts and interpolates the table per layer. The
`h2o_mole_fraction` keyword is not a gas input on that path — it is accepted
for compatibility/fallback nearest-index sampling of non-dynamic
four-dimensional H2O tables. Longwave weights
are uniform over g-points and the Planck source table is normalized by them;
shortwave weights are the file's `solar_irradiance` normalized to unit sum
(uniform when absent).
"""
function read_ecckd_tabulated_gas_optics(longwave_path::String,
                                         shortwave_path::String;
                                         gas_names = (:h2o, :co2),
                                         h2o_mole_fraction = 0.005)
    gas_name_tuple = Tuple(Symbol.(gas_names))
    lw = NCDataset(longwave_path, "r") do ds
        (
            pressure_grid = Float64.(Array(ds["pressure"])),
            temperature_grid = _temperature_grid(ds),
            h2o_grid = haskey(ds, "h2o_mole_fraction") ?
                Float64.(Array(ds["h2o_mole_fraction"])) : Float64[],
            absorption = _stack_coefficients(ds, gas_name_tuple;
                                             h2o_mole_fraction = h2o_mole_fraction,
                                             dynamic_h2o = :h2o in gas_name_tuple,
                                             allow_missing = false),
            h2o_absorption = _h2o_absorption_table(ds, gas_name_tuple),
            gas_reference_mole_fractions = _reference_mole_fractions(ds, gas_name_tuple),
            weights = fill(inv(Float64(size(ds["band_number"], 1))),
                           size(ds["band_number"], 1)),
            source = nothing,
        )
    end
    lw_source_temperature_grid, lw_source_table =
        NCDataset(longwave_path, "r") do ds
            _longwave_source_table(ds, lw.weights)
        end
    sw = NCDataset(shortwave_path, "r") do ds
        pressure_grid = Float64.(Array(ds["pressure"]))
        isapprox(pressure_grid, lw.pressure_grid; rtol = 0.0, atol = 1.0e-3) ||
            throw(ArgumentError("longwave and shortwave ecCKD pressure grids differ"))
        (
            temperature_grid = _temperature_grid(ds),
            absorption = _stack_coefficients(ds, gas_name_tuple;
                                             h2o_mole_fraction = h2o_mole_fraction,
                                             dynamic_h2o = :h2o in gas_name_tuple,
                                             allow_missing = true),
            h2o_absorption = _h2o_absorption_table(ds, gas_name_tuple),
            rayleigh = haskey(ds, "rayleigh_molar_scattering_coeff") ?
                       Float64.(Array(ds["rayleigh_molar_scattering_coeff"])) :
                       Float64[],
            weights = _shortwave_weights(ds),
        )
    end
    length(sw.temperature_grid) == length(lw.temperature_grid) ||
        throw(ArgumentError("longwave and shortwave ecCKD temperature grid sizes differ"))

    return EcCKDTabulatedGasOpticsModel(
        gas_names = gas_name_tuple,
        pressure_grid = lw.pressure_grid,
        temperature_grid = lw.temperature_grid,
        h2o_mole_fraction_grid = lw.h2o_grid,
        gas_reference_mole_fractions = lw.gas_reference_mole_fractions,
        longwave_absorption = lw.absorption,
        shortwave_absorption = sw.absorption,
        longwave_h2o_absorption = lw.h2o_absorption,
        shortwave_h2o_absorption = sw.h2o_absorption,
        shortwave_rayleigh_molar_scattering = sw.rayleigh,
        longwave_source_scale = ones(Float64, size(lw.absorption, 1)),
        longwave_source_temperature_grid = lw_source_temperature_grid,
        longwave_source_table = lw_source_table,
        longwave_weights = lw.weights,
        shortwave_weights = sw.weights,
    )
end

end
