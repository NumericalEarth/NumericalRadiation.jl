#####
##### Per-g-point cloud optics for host kernels
#####
#
# A `SpectralCloudOptics` holds one hydrometeor phase (liquid droplets or ice
# crystals) already mapped onto the g points of one ecCKD spectral mapping, on
# a grid of effective-radius nodes. A host kernel brackets the layer's
# effective radius once, reads the per-g-point `(κ, ω, 𝒢)` with
# `cloud_layer_optics`, and folds them into the layer's absorption and
# scattering optical depth with `add_scattering_layer` (shortwave) or
# `cloud_absorption_optical_depth` (longwave, where cloud scattering is
# neglected). `add_mapped_cloud_scattering!` in `cloud_optics.jl` is a loop
# over `add_scattering_layer`, so the array and kernel paths agree.
#
# Device-path rules: every function below the constructors is `@inline`,
# allocation-free, never throws, branches on structure (the node count, a
# `Nothing` phase) but not on data, and threads `FT` from the type parameter.

"""
$(TYPEDEF)

Cloud scattering properties of one hydrometeor phase mapped onto the g points
of one [`EcCKDSpectralMapping`](@ref), tabulated on `Nr` effective-radius
nodes. The mass-extinction coefficient `κ` (m² kg⁻¹), single-scattering albedo
`ω`, and asymmetry factor `𝒢` have shape `(Ng, Nr)`; a layer's values are
read by bracketing its effective radius with [`effective_radius_bracket`](@ref)
and interpolating with [`cloud_layer_optics`](@ref). The element type `FT`
follows the stored arrays, so `Adapt.adapt(Array{Float32}, cloud)` yields a
`Float32` model.

Fields:
- `effective_radius`: Effective-radius nodes in m, strictly increasing, shape `(Nr,)`
- `mass_extinction_coefficient`: Mass-extinction coefficient in m² kg⁻¹, shape
  `(Ng, Nr)`
- `single_scattering_albedo`: Single-scattering albedo, shape `(Ng, Nr)`
- `asymmetry_factor`: Scattering asymmetry factor, shape `(Ng, Nr)`
"""
struct SpectralCloudOptics{FT, V, M}
    effective_radius :: V
    mass_extinction_coefficient :: M
    single_scattering_albedo :: M
    asymmetry_factor :: M
end

Base.eltype(::SpectralCloudOptics{FT}) where FT = FT

"""
$(TYPEDSIGNATURES)

Build a [`SpectralCloudOptics`](@ref) from per-node arrays: `effective_radius`
of shape `(Nr,)` and the three property matrices of shape `(Ng, Nr)`. The
element type `FT` is passed as the first positional argument; the arrays are
converted to `Vector{FT}` and `Matrix{FT}`.
"""
function SpectralCloudOptics(FT::DataType,
                             effective_radius::AbstractVector,
                             mass_extinction_coefficient::AbstractMatrix,
                             single_scattering_albedo::AbstractMatrix,
                             asymmetry_factor::AbstractMatrix)
    Nr = length(effective_radius)
    Nr >= 1 || throw(ArgumentError("SpectralCloudOptics needs at least one effective-radius node"))
    validate_increasing_grid(effective_radius, "effective_radius")
    Ng = size(mass_extinction_coefficient, 1)
    for (name, array) in (("mass_extinction_coefficient", mass_extinction_coefficient),
                          ("single_scattering_albedo", single_scattering_albedo),
                          ("asymmetry_factor", asymmetry_factor))
        size(array) == (Ng, Nr) ||
            throw(DimensionMismatch("$name must have shape (Ng, Nr) = ($Ng, $Nr)"))
    end
    radius = Vector{FT}(effective_radius)
    κ = Matrix{FT}(mass_extinction_coefficient)
    ω = Matrix{FT}(single_scattering_albedo)
    𝒢 = Matrix{FT}(asymmetry_factor)
    return SpectralCloudOptics{FT, typeof(radius), typeof(κ)}(radius, κ, ω, 𝒢)
end

"""
$(TYPEDSIGNATURES)

Build a [`SpectralCloudOptics`](@ref) from per-node arrays whose element type
is `promote_type` of the array element types.
"""
SpectralCloudOptics(effective_radius::AbstractVector,
                    mass_extinction_coefficient::AbstractMatrix,
                    single_scattering_albedo::AbstractMatrix,
                    asymmetry_factor::AbstractMatrix) =
    SpectralCloudOptics(promote_type(eltype(effective_radius),
                                     eltype(mass_extinction_coefficient),
                                     eltype(single_scattering_albedo),
                                     eltype(asymmetry_factor)),
                        effective_radius, mass_extinction_coefficient,
                        single_scattering_albedo, asymmetry_factor)

"""
$(TYPEDSIGNATURES)

Map a [`CloudScatteringTable`](@ref) onto the g points of `mapping` at a single
`effective_radius` (m), producing a one-node [`SpectralCloudOptics`](@ref).
The node values are exactly those of [`cloud_scattering_gpoint_properties`](@ref)
with the same `mapping_method`, `delta_eddington_average`, and
`thick_averaging` keywords; the defaults follow ecRad (`:ecrad` interval
weighting with delta-Eddington averaging). Longwave mappings read by
[`read_ecckd_spectral_mapping`](@ref) already carry Planck interval weights,
so the same constructor serves both spectral regions. The element type `FT` of
the stored arrays is passed as the first positional argument.
"""
function SpectralCloudOptics(FT::DataType,
                             table::CloudScatteringTable,
                             mapping::EcCKDSpectralMapping;
                             effective_radius::Number,
                             mapping_method = :ecrad,
                             delta_eddington_average = true,
                             thick_averaging = false)
    properties = cloud_scattering_gpoint_properties(table, mapping, effective_radius;
                                                    mapping_method,
                                                    delta_eddington_average,
                                                    thick_averaging)
    Ng = length(properties.mass_extinction_coefficient)
    radius = [effective_radius]
    κ = reshape(properties.mass_extinction_coefficient, Ng, 1)
    ω = reshape(properties.single_scattering_albedo, Ng, 1)
    𝒢 = reshape(properties.asymmetry_factor, Ng, 1)
    return SpectralCloudOptics(FT, radius, κ, ω, 𝒢)
end

"""
$(TYPEDSIGNATURES)

Map a [`CloudScatteringTable`](@ref) onto the g points of `mapping` with the
element type of `table`.
"""
SpectralCloudOptics(table::CloudScatteringTable, mapping::EcCKDSpectralMapping; kwargs...) =
    SpectralCloudOptics(eltype(table), table, mapping; kwargs...)

# The element type of an adapted model follows its adapted arrays, so a device
# adaptor that changes precision yields a model whose layer optics compute in
# that precision.
function Adapt.adapt_structure(to, cloud::SpectralCloudOptics)
    effective_radius = Adapt.adapt(to, cloud.effective_radius)
    κ = Adapt.adapt(to, cloud.mass_extinction_coefficient)
    ω = Adapt.adapt(to, cloud.single_scattering_albedo)
    𝒢 = Adapt.adapt(to, cloud.asymmetry_factor)
    FT = eltype(κ)
    return SpectralCloudOptics{FT, typeof(effective_radius), typeof(κ)}(effective_radius, κ, ω, 𝒢)
end

function Base.show(io::IO, cloud::SpectralCloudOptics{FT}) where FT
    Ng, Nr = size(cloud.mass_extinction_coefficient)
    print(io, "SpectralCloudOptics{", FT, "} with ", Ng, " g points on ", Nr,
          " effective-radius node", Nr == 1 ? "" : "s")
    Nr == 1 && print(io, " at ", cloud.effective_radius[1] * 1e6, " μm")
    return nothing
end

"""
$(TYPEDSIGNATURES)

Bracket `radius` (m) on the effective-radius nodes of `cloud`: the tuple
`(i₀, i₁, w)` such that a property `p` interpolates as
`(1 - w) p[g, i₀] + w p[g, i₁]`, clamped to the edge nodes off the grid. A
one-node model brackets to `(1, 1, 0)` for every radius, and so does a
`Nothing` phase, whose bracket is never indexed.
"""
@inline function effective_radius_bracket(cloud::SpectralCloudOptics{FT}, radius) where FT
    grid = cloud.effective_radius
    if length(grid) == 1
        return (firstindex(grid), firstindex(grid), zero(FT))
    else
        return bracket(grid, FT(radius))
    end
end

@inline effective_radius_bracket(::Nothing, radius) = (1, 1, 0)

"""
$(TYPEDSIGNATURES)

Mass-extinction coefficient `κ` (m² kg⁻¹), single-scattering albedo `ω`, and
asymmetry factor `𝒢` of `cloud` at g point `g`, interpolated on the
effective-radius bracket `(i₀, i₁, w)` from [`effective_radius_bracket`](@ref).
On a one-node model (`w = 0`) the node values are returned exactly.
"""
@inline function cloud_layer_optics(cloud::SpectralCloudOptics{FT}, g, radius_bracket) where FT
    i₀, i₁, w = radius_bracket
    w₀ = one(FT) - w
    κ = w₀ * cloud.mass_extinction_coefficient[g, i₀] + w * cloud.mass_extinction_coefficient[g, i₁]
    ω = w₀ * cloud.single_scattering_albedo[g, i₀] + w * cloud.single_scattering_albedo[g, i₁]
    𝒢 = w₀ * cloud.asymmetry_factor[g, i₀] + w * cloud.asymmetry_factor[g, i₁]
    return κ, ω, 𝒢
end

# A `Nothing` phase has no optics: zero extinction, so that
# `add_scattering_layer` leaves the layer unchanged whatever the water path.
@inline cloud_layer_optics(::Nothing, g, radius_bracket) = (0, 0, 0)

"""
$(TYPEDSIGNATURES)

Fold one scattering constituent with mass-extinction coefficient `κ`,
single-scattering albedo `ω`, asymmetry factor `𝒢_cloud`, and mass path
`water_path` (kg m⁻²) into a layer's absorption optical depth `τ_absorption`,
scattering optical depth `τ_scattering`, and scattering-weighted asymmetry
factor `𝒢`, returning the updated triple:

```text
τ_absorption′ = τ_absorption + κ (1 - ω) water_path
τ_scattering′ = τ_scattering + κ ω water_path
𝒢′ = (𝒢 τ_scattering + 𝒢_cloud κ ω water_path) / τ_scattering′,    or 0 when τ_scattering′ = 0
```

The asymmetry update is evaluated as `𝒢 + (𝒢_cloud - 𝒢) κ ω water_path / τ_scattering′`,
which is the same number and leaves the layer bit-for-bit unchanged when
`water_path = 0`. [`add_mapped_cloud_scattering!`](@ref) applies this per phase
and per g point.
"""
@inline function add_scattering_layer(τ_absorption, τ_scattering, 𝒢, κ, ω, 𝒢_cloud, water_path)
    τ_cloud_scattering = κ * ω * water_path
    τ_absorption′ = τ_absorption + κ * (1 - ω) * water_path
    τ_scattering′ = τ_scattering + τ_cloud_scattering
    𝒢′ = ifelse(τ_scattering′ == 0, zero(τ_scattering′), 𝒢 + (𝒢_cloud - 𝒢) * (τ_cloud_scattering / τ_scattering′))
    return τ_absorption′, τ_scattering′, 𝒢′
end

"""
$(TYPEDSIGNATURES)

Fold `cloud` at g point `g` on the effective-radius bracket from
[`effective_radius_bracket`](@ref) with mass path `water_path` (kg m⁻²) into
a layer's `(τ_absorption, τ_scattering, 𝒢)`, returning the updated
triple: [`cloud_layer_optics`](@ref) followed by
[`add_scattering_layer`](@ref). A `Nothing` phase returns the layer
unchanged, so one shortwave layer functor serves clear and cloudy skies.
"""
@inline function add_cloud_scattering_layer(τ_absorption, τ_scattering, 𝒢,
                                            cloud::SpectralCloudOptics, g, radius_bracket, water_path)
    κ, ω, 𝒢_cloud = cloud_layer_optics(cloud, g, radius_bracket)
    return add_scattering_layer(τ_absorption, τ_scattering, 𝒢, κ, ω, 𝒢_cloud, water_path)
end

@inline add_cloud_scattering_layer(τ_absorption, τ_scattering, 𝒢,
                                   ::Nothing, g, radius_bracket, water_path) = (τ_absorption, τ_scattering, 𝒢)

"""
$(TYPEDSIGNATURES)

Longwave cloud absorption optical depth `κ (1 - ω) water_path` of `cloud` at g point
`g` for mass path `water_path` (kg m⁻²) on the effective-radius bracket from
[`effective_radius_bracket`](@ref); longwave cloud scattering is neglected.
Zero for a `Nothing` phase.
"""
@inline function cloud_absorption_optical_depth(cloud::SpectralCloudOptics, g, radius_bracket, water_path)
    κ, ω, _ = cloud_layer_optics(cloud, g, radius_bracket)
    return κ * (1 - ω) * water_path
end

@inline cloud_absorption_optical_depth(::Nothing, g, radius_bracket, water_path) = zero(water_path)
