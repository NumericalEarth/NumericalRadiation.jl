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
grid) and the optional H₂O mole-fraction axis. The stencil depends only on the
layer state, so a host builds it once per layer with
[`gas_optics_stencil`](@ref) and reuses it across every g point and gas.

`FT` is the model's element type; the struct is `isbits`, and the six stored
scalars `(i₀ᵖ, wᵖ, i₀ᵀ, wᵀ, i₀ᴴ, wᴴ)` rebuild it through
`GasOpticsStencil(i₀ᵖ, wᵖ, i₀ᵀ, wᵀ, i₀ᴴ, wᴴ)`. Without an H₂O table the H₂O
bracket is a placeholder that is never indexed.
"""
struct GasOpticsStencil{FT}
    pressure    :: Tuple{Int, Int, FT}
    temperature :: Tuple{Int, Int, FT}
    water_vapor :: Tuple{Int, Int, FT}
end

@inline function GasOpticsStencil(pressure::Tuple, temperature::Tuple, water_vapor::Tuple)
    FT = promote_type(typeof(pressure[3]), typeof(temperature[3]), typeof(water_vapor[3]))
    return GasOpticsStencil{FT}(pressure, temperature, water_vapor)
end

"""
$(TYPEDSIGNATURES)

Rebuild a [`GasOpticsStencil`](@ref) from the six scalars a host stores per
layer: the lower index and weight of the pressure, temperature and H₂O
brackets. The upper index of each bracket is the lower one plus one, which is
what `gas_optics_stencil` produces whenever the bracket is used; integer
inputs may be any `Integer` type (`Int32` storage is fine).
"""
@inline function GasOpticsStencil(i₀ᵖ::Integer, wᵖ, i₀ᵀ::Integer, wᵀ, i₀ᴴ::Integer, wᴴ)
    FT = promote_type(typeof(wᵖ), typeof(wᵀ), typeof(wᴴ))
    pressure = (Int(i₀ᵖ), Int(i₀ᵖ) + 1, FT(wᵖ))
    temperature = (Int(i₀ᵀ), Int(i₀ᵀ) + 1, FT(wᵀ))
    water_vapor = (Int(i₀ᴴ), Int(i₀ᴴ) + 1, FT(wᴴ))
    return GasOpticsStencil{FT}(pressure, temperature, water_vapor)
end

"""
$(TYPEDSIGNATURES)

Interpolation stencil of `model` for one layer at `pressure` (Pa),
`temperature` (K) and H₂O mole fraction `water_vapor_mole_fraction` (mol mol⁻¹,
relative to dry air; ignored by models without an H₂O table). Off-table inputs
clamp to the table edges. The stencil is built in the model's element type,
so the coefficient tables are expected to share it.

Returns `nothing` for an [`EcCKDGasOpticsModel`](@ref), whose coefficients
are not interpolated.
"""
@inline function gas_optics_stencil(model::EcCKDTabulatedGasOpticsModel{FT},
                                    pressure,
                                    temperature,
                                    water_vapor_mole_fraction) where FT
    pressure_bracket, temperature_bracket = table_stencil(FT, model.pressure_grid, model.temperature_grid, pressure, temperature)
    water_vapor_bracket = water_vapor_axis_bracket(model.water_vapor_mole_fraction_grid, water_vapor_mole_fraction)
    return GasOpticsStencil{FT}(pressure_bracket, temperature_bracket, water_vapor_bracket)
end

@inline gas_optics_stencil(::EcCKDGasOpticsModel, pressure, temperature, water_vapor_mole_fraction) = nothing

# The absorption tables index `(g, gas, pressure, temperature)` with the pressure and
# temperature brackets; the H₂O tables add the mole-fraction bracket.
@inline table_brackets(s::GasOpticsStencil) = (s.pressure, s.temperature)

"""
$(TYPEDSIGNATURES)

Molar amount of air (mol m⁻²) in a layer of pressure thickness `Δp` (Pa) under
hydrostatic balance, `Δp / (g mᵈ)`, with the gravitational acceleration `g`
and dry-air molar mass `mᵈ` supplied by the caller rather than fixed here, so
a host's own constants propagate (a [`PhysicalConstants`](@ref) carries both
as `gravity` and `dry_air_molar_mass`). The array
`optical_properties!` methods read them from `atmosphere.constants`; a host
kernel passes the values of its own constants object. Feeds the Rayleigh
scattering optical depth and the dry-air fallback of the layer H₂O mole
fraction. The result takes the promoted type of the arguments, so pass them
in the model's element type.
"""
@inline hydrostatic_air_moles(Δp, g, mᵈ) = Δp / (g * mᵈ)

# Scalar H₂O amount of a layer for the H₂O tables, `0` when the gas container
# carries no `h2o` key (only legal for models without an H₂O table, which never
# index i₀ᵀ). Resolved at compile time from the `NamedTuple` keys.
@generated function water_vapor_layer_amount(::Type{FT}, gases::NamedTuple{Names}) where {FT, Names}
    return :h2o in Names ? :(FT(gases.h2o)) : :(zero(FT))
end

"""
$(TYPEDSIGNATURES)

Contribution of the H₂O-mole-fraction-dependent `table`
(`longwave_water_vapor_absorption` or `shortwave_water_vapor_absorption`) to a
layer's optical depth for g point `g`: the trilinearly interpolated
coefficient times the layer's H₂O amount `water_vapor_moles` (mol m⁻²). Zero
when the model has no H₂O grid or the table is empty.
"""
@inline function water_vapor_table_optical_depth(model::EcCKDTabulatedGasOpticsModel{FT},
                                                 table,
                                                 water_vapor_moles,
                                                 g,
                                                 s::GasOpticsStencil) where FT
    length(model.water_vapor_mole_fraction_grid) == 0 && return zero(FT)
    length(table) == 0 && return zero(FT)
    coefficient = interpolate_water_vapor_table(table, g, table_brackets(s), s.water_vapor)
    return coefficient * FT(water_vapor_moles)
end

# Shared body of the longwave and shortwave tabulated optical depths: the
# relative-linear gas sum over the `(Ng, Ngases, Npressures, Ntemperatures)` table, plus the H₂O
# table, clamped as a total. Relative-linear gases legitimately contribute
# negative optical depth below their reference mole fraction; only the summed
# total is clamped, matching upstream run_ckd.
@inline function tabulated_optical_depth(model::EcCKDTabulatedGasOpticsModel{FT},
                                         table,
                                         water_vapor_table,
                                         g,
                                         gases::NamedTuple,
                                         s::GasOpticsStencil) where FT
    τ = accumulate_tabulated_optical_depth(gases, table, model.gas_reference_mole_fractions,
                                           Val(gas_names(model)), g, 1, table_brackets(s))
    water_vapor_moles = water_vapor_layer_amount(FT, gases)
    τ += water_vapor_table_optical_depth(model, water_vapor_table, water_vapor_moles, g, s)
    return max(τ, 0)
end

"""
$(TYPEDSIGNATURES)

Longwave gas optical depth of one layer for g point `g`. `gases` is a
`NamedTuple` of scalar layer amounts (mol m⁻²) keyed by the model's gas names,
plus `composite` (dry air) when the model applies the ecCKD relative-linear
convention; `s` is the layer's [`gas_optics_stencil`](@ref). The total is
clamped at zero.
"""
@inline longwave_optical_depth(model::EcCKDTabulatedGasOpticsModel{FT},
                               g,
                               gases::NamedTuple,
                               s::GasOpticsStencil) where FT =
    tabulated_optical_depth(model, model.longwave_absorption, model.longwave_water_vapor_absorption, g, gases, s)

"""
$(TYPEDSIGNATURES)

Shortwave gas optical depth of one layer for g point `g`, with the same
arguments as the longwave method.
"""
@inline shortwave_optical_depth(model::EcCKDTabulatedGasOpticsModel{FT},
                                g,
                                gases::NamedTuple,
                                s::GasOpticsStencil) where FT =
    tabulated_optical_depth(model, model.shortwave_absorption, model.shortwave_water_vapor_absorption, g, gases, s)

@inline longwave_optical_depth(model::EcCKDGasOpticsModel{FT}, g, gases::NamedTuple, ::Nothing) where FT =
    accumulate_optical_depth(gases, model.longwave_absorption, Val(gas_names(model)), g, 1)

@inline shortwave_optical_depth(model::EcCKDGasOpticsModel{FT}, g, gases::NamedTuple, ::Nothing) where FT =
    accumulate_optical_depth(gases, model.shortwave_absorption, Val(gas_names(model)), g, 1)

"""
$(TYPEDSIGNATURES)

Rayleigh scattering optical depth of one layer for shortwave g point `g`:
the model's molar scattering coefficient times the layer's molar amount of
air `air_moles` (mol m⁻²; `Δp / (g mᵈ)` for a hydrostatic layer). Zero when the
model carries no Rayleigh table, and always zero for an
[`EcCKDGasOpticsModel`](@ref).
"""
@inline function rayleigh_optical_depth(model::EcCKDTabulatedGasOpticsModel{FT}, g, air_moles) where FT
    length(model.shortwave_rayleigh_molar_scattering) == 0 && return zero(FT)
    return FT(model.shortwave_rayleigh_molar_scattering[g]) * FT(air_moles)
end

@inline rayleigh_optical_depth(::EcCKDGasOpticsModel{FT}, g, air_moles) where FT = zero(FT)

"""
$(TYPEDSIGNATURES)

Bracket of `temperature` on the model's Planck source-table temperature grid,
to pass to [`longwave_source`](@ref); `nothing` when the model has no source
table (an [`EcCKDGasOpticsModel`](@ref), or a tabulated model without one),
in which case the source is the scaled gray `σT⁴`. Off the table the source
follows ecRad: above the last node (350 K in the reference tables) it is
extrapolated linearly from the last interval, below the first node (120 K)
it is scaled linearly to zero.
"""
@inline source_table_bracket(::EcCKDGasOpticsModel, temperature) = nothing

"""
$(TYPEDSIGNATURES)

Longwave Planck source of g point `g` at `temperature`, in the model's
per-unit-weight flux convention: the tabulated source interpolated with
`source_bracket` from [`source_table_bracket`](@ref), or
`longwave_source_scale[g] σT⁴` without a table, with `σ` the model's
`stefan_boltzmann` field (set at construction, [`PhysicalConstants`](@ref)
default).
"""
@inline function longwave_source(model::EcCKDGasOpticsModel{FT}, g, temperature, ::Nothing) where FT
    return model.longwave_source_scale[g] * (model.stefan_boltzmann * FT(temperature)^4)
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
        return merge(picked, (; composite=gas_value(gases, :composite, k)))
    else
        return picked
    end
end
