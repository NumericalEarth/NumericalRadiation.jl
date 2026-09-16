#####
##### Scalar per-layer gas optics
#####
#
# Everything in this file is the per-layer, per-g-point core of the ecCKD
# forward models, written so that a host kernel can call it with scalar layer
# state: an interpolation stencil built once per layer, then one optical depth
# per g point from a `NamedTuple` of scalar layer gas amounts (mol m⁻²). The
# array methods of `optical_properties!` in `ecckd_forward.jl` are loops over
# these functions, so the two paths agree bit for bit.
#
# Device-path rules: every function here is `@inline`, allocation-free, never
# throws, branches on model structure (empty tables, `Nothing` brackets) but
# not on data, and threads `FT` from the model type.

"""
$(TYPEDEF)

Per-layer interpolation stencil for the coefficient tables of an
[`EcCKDTabulatedGasOpticsModel`](@ref): the `(i₀, i₁, w)` brackets on the
log-pressure axis, the temperature axis (vector or pressure-dependent matrix
grid) and the optional H2O mole-fraction axis. The stencil depends only on the
layer state, so a host builds it once per layer with
[`gas_optics_stencil`](@ref) and reuses it across every g point and gas.

`FT` is the model's element type; the struct is `isbits`, and the six stored
scalars `(i₀ᵖ, wᵖ, i₀ᵀ, wᵀ, i₀ᴴ, wᴴ)` rebuild it through
`GasOpticsStencil(ip, wp, it, wt, ih, wh)`. Without an H2O table the H2O
bracket is a placeholder that is never indexed.
"""
struct GasOpticsStencil{FT}
    pressure    :: Tuple{Int, Int, FT}
    temperature :: Tuple{Int, Int, FT}
    h2o         :: Tuple{Int, Int, FT}
end

@inline function GasOpticsStencil(pressure::Tuple, temperature::Tuple, h2o::Tuple)
    FT = promote_type(typeof(pressure[3]), typeof(temperature[3]), typeof(h2o[3]))
    return GasOpticsStencil{FT}(pressure, temperature, h2o)
end

"""
$(TYPEDSIGNATURES)

Rebuild a [`GasOpticsStencil`](@ref) from the six scalars a host stores per
layer: the lower index and weight of the pressure, temperature and H2O
brackets. The upper index of each bracket is the lower one plus one, which is
what `gas_optics_stencil` produces whenever the bracket is used; integer
inputs may be any `Integer` type (`Int32` storage is fine).
"""
@inline function GasOpticsStencil(ip::Integer, wp, it::Integer, wt, ih::Integer, wh)
    FT = promote_type(typeof(wp), typeof(wt), typeof(wh))
    pressure = (Int(ip), Int(ip) + 1, FT(wp))
    temperature = (Int(it), Int(it) + 1, FT(wt))
    h2o = (Int(ih), Int(ih) + 1, FT(wh))
    return GasOpticsStencil{FT}(pressure, temperature, h2o)
end

"""
$(TYPEDSIGNATURES)

Interpolation stencil of `model` for one layer at `pressure` (Pa),
`temperature` (K) and H2O mole fraction `h2o_mole_fraction` (mol mol⁻¹,
relative to dry air; ignored by models without an H2O table). Off-table inputs
clamp to the table edges. The stencil is built in the model's element type,
so the coefficient tables are expected to share it.

Returns `nothing` for an [`EcCKDGasOpticsModel`](@ref), whose coefficients
are not interpolated.
"""
@inline function gas_optics_stencil(model::EcCKDTabulatedGasOpticsModel{FT},
                                    pressure,
                                    temperature,
                                    h2o_mole_fraction) where FT
    pressure_bracket, temperature_bracket =
        table_stencil(FT, model.pressure_grid, model.temperature_grid, pressure, temperature)
    h2o_bracket = h2o_axis_bracket(model.h2o_mole_fraction_grid, h2o_mole_fraction)
    return GasOpticsStencil{FT}(pressure_bracket, temperature_bracket, h2o_bracket)
end

@inline gas_optics_stencil(::EcCKDGasOpticsModel, pressure, temperature, h2o_mole_fraction) = nothing

# The absorption tables index `(ig, gas, ip, it)` with the pressure and
# temperature brackets; the H2O tables add the mole-fraction bracket.
@inline table_brackets(s::GasOpticsStencil) = (s.pressure, s.temperature)

# Molar amount of air (mol m⁻²) in a layer of pressure thickness `Δp` (Pa)
# under hydrostatic balance, `Δp / (g mᵈ)`, with `g = 9.80665 m s⁻²` and the
# dry-air molar mass `mᵈ = 0.0289647 kg mol⁻¹`. The Rayleigh scattering table
# and the dry-air fallback of `layer_h2o_mole_fraction` both use it.
@inline hydrostatic_air_moles(::Type{FT}, Δp) where FT =
    FT(Δp) / (FT(9.80665) * FT(0.0289647))

# Scalar H2O amount of a layer for the H2O tables, `0` when the gas container
# carries no `h2o` key (only legal for models without an H2O table, which never
# index it). Resolved at compile time from the `NamedTuple` keys.
@generated function h2o_layer_amount(::Type{FT}, gases::NamedTuple{Names}) where {FT, Names}
    return :h2o in Names ? :(FT(gases.h2o)) : :(zero(FT))
end

"""
$(TYPEDSIGNATURES)

Contribution of the H2O-mole-fraction-dependent `table` (`longwave_h2o_absorption`
or `shortwave_h2o_absorption`) to a layer's optical depth for g point `ig`:
the trilinearly interpolated coefficient times the layer's H2O amount
`h2o_moles` (mol m⁻²). Zero when the model has no H2O grid or the table is
empty.
"""
@inline function h2o_table_optical_depth(model::EcCKDTabulatedGasOpticsModel{FT},
                                         table,
                                         h2o_moles,
                                         ig,
                                         s::GasOpticsStencil) where FT
    length(model.h2o_mole_fraction_grid) == 0 && return zero(FT)
    length(table) == 0 && return zero(FT)
    coefficient = interp_h2o_table(table, ig, table_brackets(s), s.h2o)
    return coefficient * FT(h2o_moles)
end

# Shared body of the longwave and shortwave tabulated optical depths: the
# relative-linear gas sum over the `(ng, ngas, np, nt)` table, plus the H2O
# table, clamped as a total. Relative-linear gases legitimately contribute
# negative optical depth below their reference mole fraction; only the summed
# total is clamped, matching upstream run_ckd.
@inline function tabulated_optical_depth(model::EcCKDTabulatedGasOpticsModel{FT},
                                         table,
                                         h2o_table,
                                         ig,
                                         gases::NamedTuple,
                                         s::GasOpticsStencil) where FT
    τ = accumulate_tabulated_tau(gases, table, model.gas_reference_mole_fractions,
                                 Val(gas_names(model)), ig, 1, table_brackets(s))
    τ += h2o_table_optical_depth(model, h2o_table, h2o_layer_amount(FT, gases), ig, s)
    return max(τ, 0)
end

"""
$(TYPEDSIGNATURES)

Longwave gas optical depth of one layer for g point `ig`. `gases` is a
`NamedTuple` of scalar layer amounts (mol m⁻²) keyed by the model's gas names,
plus `composite` (dry air) when the model applies the ecCKD relative-linear
convention; `s` is the layer's [`gas_optics_stencil`](@ref). The total is
clamped at zero.
"""
@inline longwave_optical_depth(model::EcCKDTabulatedGasOpticsModel{FT},
                               ig,
                               gases::NamedTuple,
                               s::GasOpticsStencil) where FT =
    tabulated_optical_depth(model, model.longwave_absorption,
                            model.longwave_h2o_absorption, ig, gases, s)

"""
$(TYPEDSIGNATURES)

Shortwave gas optical depth of one layer for g point `ig`, with the same
arguments as the longwave method.
"""
@inline shortwave_optical_depth(model::EcCKDTabulatedGasOpticsModel{FT},
                                ig,
                                gases::NamedTuple,
                                s::GasOpticsStencil) where FT =
    tabulated_optical_depth(model, model.shortwave_absorption,
                            model.shortwave_h2o_absorption, ig, gases, s)

@inline longwave_optical_depth(model::EcCKDGasOpticsModel{FT},
                               ig,
                               gases::NamedTuple,
                               ::Nothing) where FT =
    accumulate_tau(gases, model.longwave_absorption, Val(gas_names(model)), ig, 1)

@inline shortwave_optical_depth(model::EcCKDGasOpticsModel{FT},
                                ig,
                                gases::NamedTuple,
                                ::Nothing) where FT =
    accumulate_tau(gases, model.shortwave_absorption, Val(gas_names(model)), ig, 1)

"""
$(TYPEDSIGNATURES)

Rayleigh scattering optical depth of one layer for shortwave g point `ig`:
the model's molar scattering coefficient times the layer's molar amount of
air `air_moles` (mol m⁻²; `Δp / (g mᵈ)` for a hydrostatic layer). Zero when the
model carries no Rayleigh table, and always zero for an
[`EcCKDGasOpticsModel`](@ref).
"""
@inline function rayleigh_optical_depth(model::EcCKDTabulatedGasOpticsModel{FT},
                                        ig,
                                        air_moles) where FT
    length(model.shortwave_rayleigh_molar_scattering) == 0 && return zero(FT)
    return FT(model.shortwave_rayleigh_molar_scattering[ig]) * FT(air_moles)
end

@inline rayleigh_optical_depth(::EcCKDGasOpticsModel{FT}, ig, air_moles) where FT = zero(FT)

"""
$(TYPEDSIGNATURES)

Bracket of `temperature` on the model's Planck source-table temperature grid,
to pass to [`longwave_source`](@ref); `nothing` when the model has no source
table (an [`EcCKDGasOpticsModel`](@ref), or a tabulated model without one),
in which case the source is the scaled gray `σT⁴`.
"""
@inline source_table_bracket(::EcCKDGasOpticsModel, temperature) = nothing

"""
$(TYPEDSIGNATURES)

Longwave Planck source of g point `ig` at `temperature`, in the model's
per-unit-weight flux convention: the tabulated source interpolated with
`source_bracket` from [`source_table_bracket`](@ref), or
`longwave_source_scale[ig] σT⁴` without a table.
"""
@inline function longwave_source(model::EcCKDGasOpticsModel{FT},
                                 ig,
                                 temperature,
                                 ::Nothing) where FT
    return model.longwave_source_scale[ig] * (FT(5.670374419e-8) * temperature^4)
end

"""
$(TYPEDSIGNATURES)

Scalar gas amounts of layer `k` as a `NamedTuple` keyed by `Names` (the
model's gas names), picked from a column gas container whose entries are
per-layer vectors or column-wide scalars. A `composite` (dry air) entry the
container carries outside `Names` is kept, since the relative-linear
convention reads it. This is how the array `optical_properties!` methods feed
[`longwave_optical_depth`](@ref) and [`shortwave_optical_depth`](@ref).
"""
@generated function layer_gases(gases::NamedTuple{Keys}, ::Val{Names}, k) where {Keys, Names}
    picked = collect(Names)
    :composite in Keys && !(:composite in Names) && push!(picked, :composite)
    values = [:(gas_value(gases, $(QuoteNode(name)), k)) for name in picked]
    return :(NamedTuple{$(Tuple(picked))}(($(values...),)))
end

@inline function layer_gases(gases, ::Val{Names}, k) where Names
    picked = NamedTuple{Names}(map(name -> gas_value(gases, name, k), Names))
    if has_gas(gases, :composite) && !(:composite in Names)
        return merge(picked, (; composite = gas_value(gases, :composite, k)))
    else
        return picked
    end
end
