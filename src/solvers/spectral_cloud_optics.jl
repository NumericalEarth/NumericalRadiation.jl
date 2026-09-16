#####
##### Per-g-point cloud optics for host kernels
#####
#
# A `SpectralCloudOptics` holds one hydrometeor phase (liquid droplets or ice
# crystals) already mapped onto the g points of one ecCKD spectral mapping, on
# a grid of effective-radius nodes. A host kernel brackets the layer's
# effective radius once, reads the per-g-point `(κ, ω, g)` with
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
of one [`EcCKDSpectralMapping`](@ref), tabulated on `nr` effective-radius
nodes. The mass-extinction coefficient `κ` (m² kg⁻¹), single-scattering albedo
`ω`, and asymmetry factor `g` have shape `(ng, nr)`; a layer's values are
read by bracketing its effective radius with [`effective_radius_bracket`](@ref)
and interpolating with [`cloud_layer_optics`](@ref). The element type `FT`
follows the stored arrays, so `Adapt.adapt(Array{Float32}, cloud)` yields a
`Float32` model.

Fields are

$(TYPEDFIELDS)
"""
struct SpectralCloudOptics{FT, V, M}
    "Effective-radius nodes in m, strictly increasing, shape `(nr,)`."
    effective_radius :: V
    "Mass-extinction coefficient in m² kg⁻¹, shape `(ng, nr)`."
    mass_extinction_coefficient :: M
    "Single-scattering albedo, shape `(ng, nr)`."
    single_scattering_albedo :: M
    "Scattering asymmetry factor, shape `(ng, nr)`."
    asymmetry_factor :: M
end

Base.eltype(::SpectralCloudOptics{FT}) where FT = FT

"""
$(TYPEDSIGNATURES)

Build a [`SpectralCloudOptics`](@ref) from per-node arrays: `effective_radius`
of shape `(nr,)` and the three property matrices of shape `(ng, nr)`. The
element type is `promote_type` of the array element types unless `float_type`
is given; the arrays are converted to `Vector{FT}` and `Matrix{FT}`.
"""
function SpectralCloudOptics(effective_radius::AbstractVector,
                             mass_extinction_coefficient::AbstractMatrix,
                             single_scattering_albedo::AbstractMatrix,
                             asymmetry_factor::AbstractMatrix;
                             float_type = promote_type(eltype(effective_radius),
                                                       eltype(mass_extinction_coefficient),
                                                       eltype(single_scattering_albedo),
                                                       eltype(asymmetry_factor)))
    FT = float_type
    nr = length(effective_radius)
    nr >= 1 || throw(ArgumentError("SpectralCloudOptics needs at least one effective-radius node"))
    validate_increasing_grid(effective_radius, "effective_radius")
    ng = size(mass_extinction_coefficient, 1)
    for (name, array) in (("mass_extinction_coefficient", mass_extinction_coefficient),
                          ("single_scattering_albedo", single_scattering_albedo),
                          ("asymmetry_factor", asymmetry_factor))
        size(array) == (ng, nr) ||
            throw(DimensionMismatch("$name must have shape (ng, nr) = ($ng, $nr)"))
    end
    radius = Vector{FT}(effective_radius)
    κ = Matrix{FT}(mass_extinction_coefficient)
    ω = Matrix{FT}(single_scattering_albedo)
    g = Matrix{FT}(asymmetry_factor)
    return SpectralCloudOptics{FT, typeof(radius), typeof(κ)}(radius, κ, ω, g)
end

"""
$(TYPEDSIGNATURES)

Map a [`CloudScatteringTable`](@ref) onto the g points of `mapping` at a single
`effective_radius` (m), producing a one-node [`SpectralCloudOptics`](@ref).
The node values are exactly those of [`cloud_scattering_gpoint_properties`](@ref)
with the same `mapping_method`, `delta_eddington_average`, and
`thick_averaging` keywords; the defaults follow ecRad (`:ecrad` interval
weighting with delta-Eddington averaging). Longwave mappings read by
[`read_ecckd_spectral_mapping`](@ref) already carry Planck interval weights,
so the same constructor serves both spectral regions. `float_type` sets the
element type of the stored arrays.
"""
function SpectralCloudOptics(table::CloudScatteringTable,
                             mapping::EcCKDSpectralMapping;
                             effective_radius::Number,
                             mapping_method = :ecrad,
                             delta_eddington_average = true,
                             thick_averaging = false,
                             float_type = eltype(table))
    properties = cloud_scattering_gpoint_properties(table, mapping, effective_radius;
                                                    mapping_method,
                                                    delta_eddington_average,
                                                    thick_averaging)
    ng = length(properties.mass_extinction_coefficient)
    radius = [effective_radius]
    κ = reshape(properties.mass_extinction_coefficient, ng, 1)
    ω = reshape(properties.single_scattering_albedo, ng, 1)
    g = reshape(properties.asymmetry_factor, ng, 1)
    return SpectralCloudOptics(radius, κ, ω, g; float_type)
end

# The element type of an adapted model follows its adapted arrays, so a device
# adaptor that changes precision yields a model whose layer optics compute in
# that precision.
function Adapt.adapt_structure(to, cloud::SpectralCloudOptics)
    effective_radius = Adapt.adapt(to, cloud.effective_radius)
    κ = Adapt.adapt(to, cloud.mass_extinction_coefficient)
    ω = Adapt.adapt(to, cloud.single_scattering_albedo)
    g = Adapt.adapt(to, cloud.asymmetry_factor)
    FT = eltype(κ)
    return SpectralCloudOptics{FT, typeof(effective_radius), typeof(κ)}(effective_radius, κ, ω, g)
end

function Base.show(io::IO, cloud::SpectralCloudOptics{FT}) where FT
    ng, nr = size(cloud.mass_extinction_coefficient)
    print(io, "SpectralCloudOptics{", FT, "} with ", ng, " g points on ", nr,
          " effective-radius node", nr == 1 ? "" : "s")
    nr == 1 && print(io, " at ", cloud.effective_radius[1] * 1e6, " μm")
    return nothing
end

"""
$(TYPEDSIGNATURES)

Bracket `radius` (m) on the effective-radius nodes of `cloud`: the tuple
`(i₀, i₁, w)` such that a property `p` interpolates as
`(1 - w) p[ig, i₀] + w p[ig, i₁]`, clamped to the edge nodes off the grid. A
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
asymmetry factor `g` of `cloud` at g point `ig`, interpolated on the
effective-radius bracket `(i₀, i₁, w)` from [`effective_radius_bracket`](@ref).
On a one-node model (`w = 0`) the node values are returned exactly.
"""
@inline function cloud_layer_optics(cloud::SpectralCloudOptics{FT}, ig, radius_bracket) where FT
    i₀, i₁, w = radius_bracket
    w₀ = one(FT) - w
    κ = w₀ * cloud.mass_extinction_coefficient[ig, i₀] + w * cloud.mass_extinction_coefficient[ig, i₁]
    ω = w₀ * cloud.single_scattering_albedo[ig, i₀] + w * cloud.single_scattering_albedo[ig, i₁]
    g = w₀ * cloud.asymmetry_factor[ig, i₀] + w * cloud.asymmetry_factor[ig, i₁]
    return κ, ω, g
end

"""
$(TYPEDSIGNATURES)

Fold one scattering constituent with mass-extinction coefficient `κ`,
single-scattering albedo `ω`, asymmetry factor `g_cloud`, and mass path
`water_path` (kg m⁻²) into a layer's absorption optical depth `τ_absorption`,
scattering optical depth `τ_scattering`, and scattering-weighted asymmetry
factor `asymmetry`, returning the updated triple:

```text
τₐ′ = τₐ + κ (1 - ω) wp
τₛ′ = τₛ + κ ω wp
g′  = (g τₛ + g_cloud κ ω wp) / τₛ′,    or 0 when τₛ′ = 0
```

The asymmetry update is evaluated as `g + (g_cloud - g) κ ω wp / τₛ′`, which
is the same number and leaves the layer bit-for-bit unchanged when
`water_path = 0`. [`add_mapped_cloud_scattering!`](@ref) applies this per phase
and per g point.
"""
@inline function add_scattering_layer(τ_absorption, τ_scattering, asymmetry, κ, ω, g_cloud, water_path)
    τ_cloud_scattering = κ * ω * water_path
    τ_absorption′ = τ_absorption + κ * (1 - ω) * water_path
    τ_scattering′ = τ_scattering + τ_cloud_scattering
    asymmetry′ = ifelse(τ_scattering′ == 0,
                        zero(τ_scattering′),
                        asymmetry + (g_cloud - asymmetry) * (τ_cloud_scattering / τ_scattering′))
    return τ_absorption′, τ_scattering′, asymmetry′
end

"""
$(TYPEDSIGNATURES)

Longwave cloud absorption optical depth `κ (1 - ω) wp` of `cloud` at g point
`ig` for mass path `water_path` (kg m⁻²) on the effective-radius bracket from
[`effective_radius_bracket`](@ref); longwave cloud scattering is neglected.
Zero for a `Nothing` phase.
"""
@inline function cloud_absorption_optical_depth(cloud::SpectralCloudOptics, ig, radius_bracket, water_path)
    κ, ω, _ = cloud_layer_optics(cloud, ig, radius_bracket)
    return κ * (1 - ω) * water_path
end

@inline cloud_absorption_optical_depth(::Nothing, ig, radius_bracket, water_path) = zero(water_path)
