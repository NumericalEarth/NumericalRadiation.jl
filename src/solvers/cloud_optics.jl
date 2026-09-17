"""
$(TYPEDEF)

Layer cloud optical properties for the staged runtime interface.

This first cloud-optics container stores longwave absorption, shortwave
absorption, and shortwave scattering optical depth at model layers so host
models can test all-sky plumbing independently from gas optics and
radiative-transfer solvers. More complete phase functions and overlap
properties can extend this interface without changing the gas-optics API.

Fields are

$(TYPEDFIELDS)
"""
struct CloudOptics{FT, A}
    "Layer longwave cloud optical depth."
    longwave_optical_depth::A
    "Layer shortwave absorptive cloud optical depth."
    shortwave_optical_depth::A
    "Layer shortwave scattering cloud optical depth."
    shortwave_scattering_optical_depth::A
    "Layer shortwave cloud scattering asymmetry factor."
    shortwave_scattering_asymmetry::A
end

function CloudOptics(longwave_optical_depth::AbstractVector{FT},
                                shortwave_optical_depth::AbstractVector{FT};
                                shortwave_scattering_optical_depth = zero.(shortwave_optical_depth),
                                shortwave_scattering_asymmetry = zero.(shortwave_optical_depth)) where FT
    length(longwave_optical_depth) == length(shortwave_optical_depth) ||
        throw(DimensionMismatch("longwave and shortwave cloud optical depth must have the same length"))
    length(shortwave_scattering_optical_depth) == length(shortwave_optical_depth) ||
        throw(DimensionMismatch("shortwave scattering cloud optical depth must have the same length"))
    length(shortwave_scattering_asymmetry) == length(shortwave_optical_depth) ||
        throw(DimensionMismatch("shortwave scattering asymmetry must have the same length"))
    return CloudOptics{FT, typeof(longwave_optical_depth)}(
        longwave_optical_depth,
        shortwave_optical_depth,
        shortwave_scattering_optical_depth,
        shortwave_scattering_asymmetry,
    )
end

Base.eltype(::CloudOptics{FT}) where FT = FT

"""
$(TYPEDEF)

Cloudy-region cloud optical properties for all-sky solvers.

Unlike [`CloudOptics`](@ref), these optical depths are not scaled by
cloud fraction. They describe the cloudy region of each layer, while
`cloud_fraction` and `overlap_parameter` are carried separately for
Tripleclouds/McICA-style solvers. This avoids the grid-mean shortcut that is
useful for simple smoke tests but inconsistent with ecRad's all-sky
cloud-region optical-property convention.

Fields are

$(TYPEDFIELDS)
"""
struct CloudyRegionCloudOptics{FT, A}
    "Layer cloud fraction."
    cloud_fraction::A
    "Interface cloud-overlap parameter between adjacent layers."
    overlap_parameter::A
    "Cloudy-region longwave cloud optical depth."
    longwave_optical_depth::A
    "Cloudy-region shortwave absorptive cloud optical depth."
    shortwave_optical_depth::A
    "Cloudy-region shortwave scattering cloud optical depth."
    shortwave_scattering_optical_depth::A
    "Cloudy-region shortwave cloud scattering asymmetry factor."
    shortwave_scattering_asymmetry::A
end

function CloudyRegionCloudOptics(cloud_fraction::AbstractVector{FT},
                                            overlap_parameter::AbstractVector{FT},
                                            longwave_optical_depth::AbstractVector{FT},
                                            shortwave_optical_depth::AbstractVector{FT};
                                            shortwave_scattering_optical_depth =
                                                zero.(shortwave_optical_depth),
                                            shortwave_scattering_asymmetry =
                                                zero.(shortwave_optical_depth)) where FT
    nlayers = length(cloud_fraction)
    length(longwave_optical_depth) == nlayers ||
        throw(DimensionMismatch("longwave cloudy-region optical depth must have length nlayers"))
    length(shortwave_optical_depth) == nlayers ||
        throw(DimensionMismatch("shortwave cloudy-region optical depth must have length nlayers"))
    length(shortwave_scattering_optical_depth) == nlayers ||
        throw(DimensionMismatch("shortwave cloudy-region scattering optical depth must have length nlayers"))
    length(shortwave_scattering_asymmetry) == nlayers ||
        throw(DimensionMismatch("shortwave cloudy-region scattering asymmetry must have length nlayers"))
    if !(length(overlap_parameter) == max(nlayers - 1, 0) ||
         length(overlap_parameter) == nlayers)
        throw(DimensionMismatch("overlap_parameter must have length nlayers - 1 or nlayers"))
    end
    return CloudyRegionCloudOptics{FT, typeof(cloud_fraction)}(
        cloud_fraction,
        overlap_parameter,
        longwave_optical_depth,
        shortwave_optical_depth,
        shortwave_scattering_optical_depth,
        shortwave_scattering_asymmetry,
    )
end

Base.eltype(::CloudyRegionCloudOptics{FT}) where FT = FT

"""
$(TYPEDEF)

Layer aerosol optical properties for the staged runtime interface.

This first aerosol-optics container mirrors [`CloudOptics`](@ref):
it stores absorptive longwave and shortwave optical depth at model layers so
host models can compose gas, cloud, and aerosol optics without accepting a
single end-to-end radiation path.

Fields are

$(TYPEDFIELDS)
"""
struct AerosolOptics{FT, A}
    "Layer longwave aerosol optical depth."
    longwave_optical_depth::A
    "Layer shortwave absorptive aerosol optical depth."
    shortwave_optical_depth::A
    "Layer shortwave scattering aerosol optical depth."
    shortwave_scattering_optical_depth::A
    "Layer shortwave aerosol scattering asymmetry factor."
    shortwave_scattering_asymmetry::A
end

function AerosolOptics(longwave_optical_depth::AbstractVector{FT},
                                  shortwave_optical_depth::AbstractVector{FT};
                                  shortwave_scattering_optical_depth = zero.(shortwave_optical_depth),
                                  shortwave_scattering_asymmetry = zero.(shortwave_optical_depth)) where FT
    length(longwave_optical_depth) == length(shortwave_optical_depth) ||
        throw(DimensionMismatch("longwave and shortwave aerosol optical depth must have the same length"))
    length(shortwave_scattering_optical_depth) == length(shortwave_optical_depth) ||
        throw(DimensionMismatch("shortwave scattering aerosol optical depth must have the same length"))
    length(shortwave_scattering_asymmetry) == length(shortwave_optical_depth) ||
        throw(DimensionMismatch("shortwave aerosol scattering asymmetry must have the same length"))
    return AerosolOptics{FT, typeof(longwave_optical_depth)}(
        longwave_optical_depth,
        shortwave_optical_depth,
        shortwave_scattering_optical_depth,
        shortwave_scattering_asymmetry,
    )
end

Base.eltype(::AerosolOptics{FT}) where FT = FT

"""
$(TYPEDEF)

Simple layer-cloud optical model.

`cloud_water_path` may be a scalar, a vector with one entry per layer, or an
object supporting `getproperty(..., :cloud_water_path)`. Optical depths are

```text
τ_lw = longwave_mass_absorption * cloud_water_path
τ_sw_abs = (1 - ω0) * shortwave_mass_extinction * cloud_water_path
τ_sw_scat = ω0 * shortwave_mass_extinction * cloud_water_path
```

Fields are

$(TYPEDFIELDS)
"""
struct LayerCloudOpticsModel{FT, CWP} <: AbstractCloudOpticsModel
    "Layer cloud water path, or fallback value when the atmosphere does not provide one."
    cloud_water_path::CWP
    "Longwave mass absorption coefficient."
    longwave_mass_absorption::FT
    "Shortwave mass extinction coefficient."
    shortwave_mass_extinction::FT
    "Shortwave single-scattering albedo."
    shortwave_single_scattering_albedo::FT
    "Shortwave scattering asymmetry factor."
    shortwave_scattering_asymmetry::FT
end

"""
$(TYPEDEF)

Layer liquid/ice cloud optical model for all-sky host integrations.

This keeps liquid water path, ice water path, and cloud fraction as separate
inputs instead of collapsing them before the cloud-optics API. The current
model is still absorptive/extinctive-only, but it gives later IFS-compatible
cloud optics a stable place to add phase-dependent scattering, asymmetry,
effective-radius, and overlap conventions.

Optical depths are

```text
τ_lw = f_cloud * (κ_lw_liq * LWP + κ_lw_ice * IWP)
τ_sw_abs = f_cloud * ((1 - ω0_liq) * κ_sw_liq * LWP
                    + (1 - ω0_ice) * κ_sw_ice * IWP)
τ_sw_scat = f_cloud * (ω0_liq * κ_sw_liq * LWP
                     + ω0_ice * κ_sw_ice * IWP)
```

Fields are

$(TYPEDFIELDS)
"""
struct LayerLiquidIceCloudOpticsModel{FT, LWP, IWP, CF} <: AbstractCloudOpticsModel
    "Layer liquid water path, or fallback value when the atmosphere does not provide one."
    liquid_water_path::LWP
    "Layer ice water path, or fallback value when the atmosphere does not provide one."
    ice_water_path::IWP
    "Layer cloud fraction, or fallback value when the atmosphere does not provide one."
    cloud_fraction::CF
    "Liquid longwave mass absorption coefficient."
    liquid_longwave_mass_absorption::FT
    "Ice longwave mass absorption coefficient."
    ice_longwave_mass_absorption::FT
    "Liquid shortwave mass extinction coefficient."
    liquid_shortwave_mass_extinction::FT
    "Ice shortwave mass extinction coefficient."
    ice_shortwave_mass_extinction::FT
    "Liquid shortwave single-scattering albedo."
    liquid_shortwave_single_scattering_albedo::FT
    "Ice shortwave single-scattering albedo."
    ice_shortwave_single_scattering_albedo::FT
    "Liquid shortwave scattering asymmetry factor."
    liquid_shortwave_scattering_asymmetry::FT
    "Ice shortwave scattering asymmetry factor."
    ice_shortwave_scattering_asymmetry::FT
    "Exponent applied to cloud fraction before scaling optical depth."
    cloud_fraction_exponent::FT
end

function LayerLiquidIceCloudOpticsModel(; liquid_water_path,
                                        ice_water_path,
                                        cloud_fraction = 1,
                                        liquid_longwave_mass_absorption,
                                        ice_longwave_mass_absorption,
                                        liquid_shortwave_mass_extinction,
                                        ice_shortwave_mass_extinction,
                                        liquid_shortwave_single_scattering_albedo = 0,
                                        ice_shortwave_single_scattering_albedo = 0,
                                        liquid_shortwave_scattering_asymmetry = 0,
                                        ice_shortwave_scattering_asymmetry = 0,
                                        cloud_fraction_exponent = 1)
    FT = promote_type(typeof(liquid_longwave_mass_absorption),
                      typeof(ice_longwave_mass_absorption),
                      typeof(liquid_shortwave_mass_extinction),
                      typeof(ice_shortwave_mass_extinction),
                      typeof(liquid_shortwave_single_scattering_albedo),
                      typeof(ice_shortwave_single_scattering_albedo),
                      typeof(liquid_shortwave_scattering_asymmetry),
                      typeof(ice_shortwave_scattering_asymmetry),
                      typeof(cloud_fraction_exponent))
    return LayerLiquidIceCloudOpticsModel{FT, typeof(liquid_water_path),
                                          typeof(ice_water_path),
                                          typeof(cloud_fraction)}(
        liquid_water_path,
        ice_water_path,
        cloud_fraction,
        FT(liquid_longwave_mass_absorption),
        FT(ice_longwave_mass_absorption),
        FT(liquid_shortwave_mass_extinction),
        FT(ice_shortwave_mass_extinction),
        FT(liquid_shortwave_single_scattering_albedo),
        FT(ice_shortwave_single_scattering_albedo),
        FT(liquid_shortwave_scattering_asymmetry),
        FT(ice_shortwave_scattering_asymmetry),
        FT(cloud_fraction_exponent),
    )
end

function LayerCloudOpticsModel(; cloud_water_path,
                               longwave_mass_absorption,
                               shortwave_mass_extinction,
                               shortwave_single_scattering_albedo = 0,
                               shortwave_scattering_asymmetry = 0)
    FT = promote_type(typeof(longwave_mass_absorption),
                      typeof(shortwave_mass_extinction),
                      typeof(shortwave_single_scattering_albedo),
                      typeof(shortwave_scattering_asymmetry))
    return LayerCloudOpticsModel{FT, typeof(cloud_water_path)}(
        cloud_water_path,
        FT(longwave_mass_absorption),
        FT(shortwave_mass_extinction),
        FT(shortwave_single_scattering_albedo),
        FT(shortwave_scattering_asymmetry),
    )
end

@inline function cloud_water_path_at(model::LayerCloudOpticsModel, atmosphere, k)
    source = hasproperty(atmosphere, :cloud_water_path) ?
        getproperty(atmosphere, :cloud_water_path) :
        model.cloud_water_path
    return source isa Number ? source : source[k]
end

@inline function layer_property(atmosphere, fallback, name::Symbol, k)
    source = hasproperty(atmosphere, name) ? getproperty(atmosphere, name) : fallback
    return source isa Number ? source : source[k]
end

"""
    cloud_optical_properties!(cloud, model::LayerCloudOpticsModel, atmosphere)

Fill caller-owned cloud optical depth arrays from a simple layer cloud-water
path model.
"""
function cloud_optical_properties!(cloud::CloudOptics{FT},
                                   model::LayerCloudOpticsModel,
                                   atmosphere) where FT
    nlayers = length(cloud.longwave_optical_depth)
    length(cloud.shortwave_optical_depth) == nlayers ||
        throw(DimensionMismatch("shortwave cloud optical depth must have length nlayers"))

    for k in 1:nlayers
        cloud_water_path = FT(cloud_water_path_at(model, atmosphere, k))
        shortwave_extinction = FT(model.shortwave_mass_extinction) * cloud_water_path
        ω_shortwave = clamp(FT(model.shortwave_single_scattering_albedo), zero(FT), one(FT))
        cloud.longwave_optical_depth[k] = FT(model.longwave_mass_absorption) * cloud_water_path
        cloud.shortwave_optical_depth[k] = (one(FT) - ω_shortwave) * shortwave_extinction
        cloud.shortwave_scattering_optical_depth[k] = ω_shortwave * shortwave_extinction
        cloud.shortwave_scattering_asymmetry[k] =
            clamp(FT(model.shortwave_scattering_asymmetry), -one(FT), one(FT))
    end

    return cloud
end

function fill_liquid_ice_cloud_optics!(cloud::CloudOptics{FT},
                                        model::LayerLiquidIceCloudOpticsModel,
                                        atmosphere;
                                        scale_by_cloud_fraction::Bool) where FT
    nlayers = length(cloud.longwave_optical_depth)
    length(cloud.shortwave_optical_depth) == nlayers ||
        throw(DimensionMismatch("shortwave cloud optical depth must have length nlayers"))

    for k in 1:nlayers
        liquid = max(FT(layer_property(atmosphere, model.liquid_water_path,
                                        :liquid_water_path, k)), zero(FT))
        ice = max(FT(layer_property(atmosphere, model.ice_water_path,
                                     :ice_water_path, k)), zero(FT))
        fraction = clamp(FT(layer_property(atmosphere, model.cloud_fraction,
                                            :cloud_fraction, k)), zero(FT), one(FT))
        fraction_scale = scale_by_cloud_fraction ?
            fraction ^ max(FT(model.cloud_fraction_exponent), zero(FT)) :
            one(FT)
        τˡ_extinction = FT(model.liquid_shortwave_mass_extinction) * liquid
        τⁱ_extinction = FT(model.ice_shortwave_mass_extinction) * ice
        ωˡ = clamp(FT(model.liquid_shortwave_single_scattering_albedo), zero(FT), one(FT))
        ωⁱ = clamp(FT(model.ice_shortwave_single_scattering_albedo), zero(FT), one(FT))
        gˡ =
            clamp(FT(model.liquid_shortwave_scattering_asymmetry), -one(FT), one(FT))
        gⁱ =
            clamp(FT(model.ice_shortwave_scattering_asymmetry), -one(FT), one(FT))
        τˡ_scattering = ωˡ * τˡ_extinction
        τⁱ_scattering = ωⁱ * τⁱ_extinction
        τ_scattering = τˡ_scattering + τⁱ_scattering
        cloud.longwave_optical_depth[k] = fraction_scale *
            (FT(model.liquid_longwave_mass_absorption) * liquid +
             FT(model.ice_longwave_mass_absorption) * ice)
        cloud.shortwave_optical_depth[k] = fraction_scale *
            ((one(FT) - ωˡ) * τˡ_extinction +
             (one(FT) - ωⁱ) * τⁱ_extinction)
        cloud.shortwave_scattering_optical_depth[k] = fraction_scale * τ_scattering
        cloud.shortwave_scattering_asymmetry[k] = τ_scattering == zero(FT) ?
            zero(FT) :
            (gˡ * τˡ_scattering + gⁱ * τⁱ_scattering) / τ_scattering
    end

    return cloud
end

"""
    cloud_optical_properties!(cloud, model::LayerLiquidIceCloudOpticsModel, atmosphere)

Fill caller-owned cloud optical depth arrays from phase-separated liquid/ice
water paths and cloud fraction. This existing method returns grid-mean cloud
optical depth for simple homogeneous-column composition. Use
[`cloudy_region_optical_properties!`](@ref) for all-sky solvers that carry
cloud fraction and overlap separately.
"""
function cloud_optical_properties!(cloud::CloudOptics{FT},
                                   model::LayerLiquidIceCloudOpticsModel,
                                   atmosphere) where FT
    return fill_liquid_ice_cloud_optics!(cloud, model, atmosphere;
                                          scale_by_cloud_fraction = true)
end

@inline function overlap_parameter_at(atmosphere, k, FT)
    if atmosphere !== nothing && hasproperty(atmosphere, :overlap_parameter)
        source = getproperty(atmosphere, :overlap_parameter)
        return FT(source isa Number ? source : source[k])
    end
    return one(FT)
end

"""
    cloudy_region_optical_properties!(cloud, model::LayerLiquidIceCloudOpticsModel, atmosphere)

Fill caller-owned cloudy-region cloud optical properties from phase-separated
liquid/ice water paths. Cloud fraction and overlap are stored separately and
optical depths are not multiplied by cloud fraction.
"""
function cloudy_region_optical_properties!(cloud::CloudyRegionCloudOptics{FT},
                                           model::LayerLiquidIceCloudOpticsModel,
                                           atmosphere) where FT
    nlayers = length(cloud.cloud_fraction)
    scratch = CloudOptics(cloud.longwave_optical_depth,
                                     cloud.shortwave_optical_depth;
                                     shortwave_scattering_optical_depth =
                                         cloud.shortwave_scattering_optical_depth,
                                     shortwave_scattering_asymmetry =
                                         cloud.shortwave_scattering_asymmetry)
    fill_liquid_ice_cloud_optics!(scratch, model, atmosphere;
                                   scale_by_cloud_fraction = false)
    for k in 1:nlayers
        cloud.cloud_fraction[k] =
            clamp(FT(layer_property(atmosphere, model.cloud_fraction,
                                     :cloud_fraction, k)), zero(FT), one(FT))
    end
    for k in eachindex(cloud.overlap_parameter)
        cloud.overlap_parameter[k] = overlap_parameter_at(atmosphere, k, FT)
    end
    return cloud
end

"""
$(TYPEDEF)

Simple layer-aerosol optical model.

`aerosol_path` may be a scalar, a vector with one entry per layer, or a value
provided by `getproperty(atmosphere, :aerosol_path)`. Optical depths are

```text
τ_lw = longwave_mass_absorption * aerosol_path
τ_sw = shortwave_mass_extinction * aerosol_path
```

Fields are

$(TYPEDFIELDS)
"""
struct LayerAerosolOpticsModel{FT, AP} <: AbstractAerosolOpticsModel
    "Layer aerosol path, or fallback value when the atmosphere does not provide one."
    aerosol_path::AP
    "Longwave mass absorption coefficient."
    longwave_mass_absorption::FT
    "Shortwave mass extinction coefficient."
    shortwave_mass_extinction::FT
    "Shortwave single-scattering albedo."
    shortwave_single_scattering_albedo::FT
    "Shortwave scattering asymmetry factor."
    shortwave_scattering_asymmetry::FT
end

function LayerAerosolOpticsModel(; aerosol_path,
                                 longwave_mass_absorption,
                                 shortwave_mass_extinction,
                                 shortwave_single_scattering_albedo = 0,
                                 shortwave_scattering_asymmetry = 0)
    FT = promote_type(typeof(longwave_mass_absorption),
                      typeof(shortwave_mass_extinction),
                      typeof(shortwave_single_scattering_albedo),
                      typeof(shortwave_scattering_asymmetry))
    return LayerAerosolOpticsModel{FT, typeof(aerosol_path)}(
        aerosol_path,
        FT(longwave_mass_absorption),
        FT(shortwave_mass_extinction),
        FT(shortwave_single_scattering_albedo),
        FT(shortwave_scattering_asymmetry),
    )
end

@inline function aerosol_path_at(model::LayerAerosolOpticsModel, atmosphere, k)
    source = hasproperty(atmosphere, :aerosol_path) ?
        getproperty(atmosphere, :aerosol_path) :
        model.aerosol_path
    return source isa Number ? source : source[k]
end

"""
    aerosol_optical_properties!(aerosol, model::LayerAerosolOpticsModel, atmosphere)

Fill caller-owned aerosol optical depth arrays from a simple layer aerosol-path
model.
"""
function aerosol_optical_properties!(aerosol::AerosolOptics{FT},
                                     model::LayerAerosolOpticsModel,
                                     atmosphere) where FT
    nlayers = length(aerosol.longwave_optical_depth)
    length(aerosol.shortwave_optical_depth) == nlayers ||
        throw(DimensionMismatch("shortwave aerosol optical depth must have length nlayers"))

    for k in 1:nlayers
        path = FT(aerosol_path_at(model, atmosphere, k))
        shortwave_extinction = FT(model.shortwave_mass_extinction) * path
        ω_shortwave = clamp(FT(model.shortwave_single_scattering_albedo), zero(FT), one(FT))
        aerosol.longwave_optical_depth[k] = FT(model.longwave_mass_absorption) * path
        aerosol.shortwave_optical_depth[k] = (one(FT) - ω_shortwave) * shortwave_extinction
        aerosol.shortwave_scattering_optical_depth[k] = ω_shortwave * shortwave_extinction
        aerosol.shortwave_scattering_asymmetry[k] =
            clamp(FT(model.shortwave_scattering_asymmetry), -one(FT), one(FT))
    end

    return aerosol
end

@inline add_cloud_optical_depth!(optical_depth::AbstractVector, τ_cloud, k) =
    optical_depth[k] += τ_cloud[k]

function add_cloud_optical_depth!(optical_depth::AbstractMatrix, τ_cloud, k)
    for gpoint in axes(optical_depth, 1)
        optical_depth[gpoint, k] += τ_cloud[k]
    end
    return nothing
end

@inline function add_cloud_scattering!(optical_depth::AbstractVector,
                                        asymmetry::AbstractVector,
                                        τ_cloud,
                                        cloud_asymmetry,
                                        k)
    τ_existing = optical_depth[k]
    τ_incoming = τ_cloud[k]
    τ_total = τ_existing + τ_incoming
    asymmetry[k] = τ_total == zero(τ_total) ? zero(τ_total) :
        (asymmetry[k] * τ_existing + cloud_asymmetry[k] * τ_incoming) / τ_total
    optical_depth[k] = τ_total
    return nothing
end

function add_cloud_scattering!(optical_depth::AbstractMatrix,
                                asymmetry::AbstractMatrix,
                                τ_cloud,
                                cloud_asymmetry,
                                k)
    for gpoint in axes(optical_depth, 1)
        τ_existing = optical_depth[gpoint, k]
        τ_incoming = τ_cloud[k]
        τ_total = τ_existing + τ_incoming
        asymmetry[gpoint, k] = τ_total == zero(τ_total) ? zero(τ_total) :
            (asymmetry[gpoint, k] * τ_existing + cloud_asymmetry[k] * τ_incoming) / τ_total
        optical_depth[gpoint, k] = τ_total
    end
    return nothing
end

"""
    add_cloud_optical_depths!(longwave, shortwave, cloud)

Add layer cloud optical depths to precomputed gas optical properties. Longwave
and shortwave absorption are added to the absorption optical-depth arrays;
shortwave cloud scattering is added to the solver's scattering optical-depth
array. This keeps gas optics, cloud optics, and solvers independently testable
while providing an initial all-sky composition path.
"""
function add_cloud_optical_depths!(longwave::LongwaveOptics,
                                   shortwave::ShortwaveOptics,
                                   cloud::CloudOptics)
    nlayers = length(cloud.longwave_optical_depth)
    length(cloud.shortwave_optical_depth) == nlayers ||
        throw(DimensionMismatch("shortwave cloud optical depth must have length nlayers"))

    for k in 1:nlayers
        add_cloud_optical_depth!(longwave.optical_depth, cloud.longwave_optical_depth, k)
        add_cloud_optical_depth!(shortwave.optical_depth, cloud.shortwave_optical_depth, k)
        add_cloud_scattering!(shortwave.rayleigh_optical_depth,
                               shortwave.scattering_asymmetry,
                               cloud.shortwave_scattering_optical_depth,
                               cloud.shortwave_scattering_asymmetry,
                               k)
    end

    return longwave, shortwave
end

"""
    add_mapped_cloud_scattering!(shortwave, liquid_properties, ice_properties,
                                 liquid_water_path, ice_water_path, cloud_fraction; kwargs...)

Add g-point mapped liquid and ice cloud scattering to shortwave optical
properties. The input `liquid_properties` and `ice_properties` are per-g-point
scattering tables (anything with `mass_extinction_coefficient`,
`single_scattering_albedo`, and `asymmetry_factor` indexable by g point, such
as the output of [`cloud_scattering_gpoint_properties`](@ref)), while the
water paths and cloud fraction are layer fields. The function adds absorptive
optical depth to `shortwave.optical_depth` and mixes scattering optical
depth/asymmetry into `shortwave.rayleigh_optical_depth` and
`shortwave.scattering_asymmetry`.

Each layer and g point is two calls of [`add_scattering_layer`](@ref), one per
phase, so a host kernel looping over that function reproduces this array
method. The keyword scale factors enter that loop as follows: the extinction
scales multiply each phase's mass-extinction coefficient; the cloud-fraction
weight `cloud_fraction^cloud_fraction_exponent` multiplies both water paths;
`shortwave_scattering_scale` multiplies each phase's single-scattering albedo
(clamped to `[0, 1]`); and `delta_eddington_scale` removes the
forward-scattering peak of the combined liquid+ice mixture once with
`delta_eddington`, after the phases are mixed and before the mixture is
folded into the layer, as ecRad does (`f = g²` is nonlinear, so scaling the
phases separately would differ whenever their asymmetries differ).
"""
function add_mapped_cloud_scattering!(shortwave::ShortwaveOptics{<:Any, <:AbstractMatrix},
                                      liquid_properties,
                                      ice_properties,
                                      liquid_water_path,
                                      ice_water_path,
                                      cloud_fraction;
                                      cloud_fraction_exponent = 1,
                                      liquid_extinction_scale = 1,
                                      ice_extinction_scale = 1,
                                      shortwave_scattering_scale = 1,
                                      delta_eddington_scale = false)
    ng, nlayers = size(shortwave.optical_depth)
    length(liquid_properties.mass_extinction_coefficient) == ng ||
        throw(DimensionMismatch("liquid cloud g-point properties must match shortwave g-points"))
    length(ice_properties.mass_extinction_coefficient) == ng ||
        throw(DimensionMismatch("ice cloud g-point properties must match shortwave g-points"))
    length(liquid_water_path) == nlayers ||
        throw(DimensionMismatch("liquid_water_path must match shortwave layers"))
    length(ice_water_path) == nlayers ||
        throw(DimensionMismatch("ice_water_path must match shortwave layers"))
    length(cloud_fraction) == nlayers ||
        throw(DimensionMismatch("cloud_fraction must match shortwave layers"))

    FT = eltype(shortwave)
    exponent = max(FT(cloud_fraction_exponent), zero(FT))
    liquid_scale = FT(liquid_extinction_scale)
    ice_scale = FT(ice_extinction_scale)
    scattering_scale = max(FT(shortwave_scattering_scale), zero(FT))
    for k in 1:nlayers
        fraction_scale = clamp(FT(cloud_fraction[k]), zero(FT), one(FT))^exponent
        liquid_path = fraction_scale * max(FT(liquid_water_path[k]), zero(FT))
        ice_path = fraction_scale * max(FT(ice_water_path[k]), zero(FT))
        for gpoint in 1:ng
            τ_absorption = shortwave.optical_depth[gpoint, k]
            τ_scattering = shortwave.rayleigh_optical_depth[gpoint, k]
            asymmetry = shortwave.scattering_asymmetry[gpoint, k]

            κˡ, ωˡ, gˡ = scaled_phase_optics(liquid_properties, gpoint, liquid_scale, scattering_scale, FT)
            κⁱ, ωⁱ, gⁱ = scaled_phase_optics(ice_properties, gpoint, ice_scale, scattering_scale, FT)

            if delta_eddington_scale
                # ecRad removes the forward peak of the whole cloud after every
                # constituent has been added, so compose the liquid+ice mixture
                # on its own, scale it once, and fold it into the layer as one
                # constituent of unit mass path.
                τᶜ_absorption, τᶜ_scattering, gᶜ =
                    add_scattering_layer(zero(FT), zero(FT), zero(FT), κˡ, ωˡ, gˡ, liquid_path)
                τᶜ_absorption, τᶜ_scattering, gᶜ =
                    add_scattering_layer(τᶜ_absorption, τᶜ_scattering, gᶜ, κⁱ, ωⁱ, gⁱ, ice_path)
                τᶜ = τᶜ_absorption + τᶜ_scattering
                ωᶜ = ifelse(τᶜ == 0, zero(FT), τᶜ_scattering / τᶜ)
                τᶜ, ωᶜ, gᶜ = delta_eddington(τᶜ, ωᶜ, gᶜ)
                τ_absorption, τ_scattering, asymmetry =
                    add_scattering_layer(τ_absorption, τ_scattering, asymmetry, τᶜ, ωᶜ, gᶜ, one(FT))
            else
                τ_absorption, τ_scattering, asymmetry =
                    add_scattering_layer(τ_absorption, τ_scattering, asymmetry, κˡ, ωˡ, gˡ, liquid_path)
                τ_absorption, τ_scattering, asymmetry =
                    add_scattering_layer(τ_absorption, τ_scattering, asymmetry, κⁱ, ωⁱ, gⁱ, ice_path)
            end

            shortwave.optical_depth[gpoint, k] = τ_absorption
            shortwave.rayleigh_optical_depth[gpoint, k] = τ_scattering
            shortwave.scattering_asymmetry[gpoint, k] = asymmetry
        end
    end
    return shortwave
end

# Clamped and scaled (κ, ω, g) of one phase at g point `gpoint` for the mapped
# scattering loop: κ scaled by the phase's extinction scale, ω and g clamped to
# their physical ranges, and then the scattering scale on ω (clamped so
# scattering never exceeds extinction).
@inline function scaled_phase_optics(properties, gpoint, extinction_scale, scattering_scale, ::Type{FT}) where FT
    κ = extinction_scale * FT(properties.mass_extinction_coefficient[gpoint])
    ω = clamp(FT(properties.single_scattering_albedo[gpoint]), zero(FT), one(FT))
    g = clamp(FT(properties.asymmetry_factor[gpoint]), -one(FT), one(FT))
    ω = clamp(ω * scattering_scale, zero(FT), one(FT))
    return κ, ω, g
end

function add_mapped_cloud_scattering!(shortwave::ShortwaveOptics{<:Any, <:AbstractVector},
                                      args...; kwargs...)
    throw(ArgumentError("mapped cloud scattering requires matrix-shaped shortwave optical properties with explicit g-points"))
end

"""
    add_aerosol_optical_depths!(longwave, shortwave, aerosol)

Add layer aerosol optical depths to precomputed gas optical properties. This
keeps aerosol optics independently testable while providing an initial
absorptive gas+cloud+aerosol composition path.
"""
function add_aerosol_optical_depths!(longwave::LongwaveOptics,
                                     shortwave::ShortwaveOptics,
                                     aerosol::AerosolOptics)
    nlayers = length(aerosol.longwave_optical_depth)
    length(aerosol.shortwave_optical_depth) == nlayers ||
        throw(DimensionMismatch("shortwave aerosol optical depth must have length nlayers"))

    for k in 1:nlayers
        add_cloud_optical_depth!(longwave.optical_depth, aerosol.longwave_optical_depth, k)
        add_cloud_optical_depth!(shortwave.optical_depth, aerosol.shortwave_optical_depth, k)
        add_cloud_scattering!(shortwave.rayleigh_optical_depth,
                               shortwave.scattering_asymmetry,
                               aerosol.shortwave_scattering_optical_depth,
                               aerosol.shortwave_scattering_asymmetry,
                               k)
    end

    return longwave, shortwave
end
