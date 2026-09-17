"""
$(TYPEDEF)

Dependency-light cloud scattering table.

The table stores raw ecRad-style scattering properties as a function of
wavenumber and effective radius. Spectral mapping to radiation bands or
g-points is a separate operation because it depends on the gas-optics spectral
definition and averaging convention.

Fields are

$(TYPEDFIELDS)
"""
struct CloudScatteringTable{FT, V, M}
    "Hydrometeor medium, for example `liquid-water` or `ice`."
    medium::String
    "Particle type from file metadata."
    particle_type::String
    "Wavenumber grid in cm^-1."
    wavenumber::V
    "Effective-radius grid in m."
    effective_radius::V
    "Mass-extinction coefficient with shape `(wavenumber, effective_radius)`."
    mass_extinction_coefficient::M
    "Single-scattering albedo with shape `(wavenumber, effective_radius)`."
    single_scattering_albedo::M
    "Scattering asymmetry factor with shape `(wavenumber, effective_radius)`."
    asymmetry_factor::M
end

Base.eltype(::CloudScatteringTable{FT}) where FT = FT

"""
$(TYPEDEF)

Spectral mapping from ecCKD resolved wavenumber intervals to g-points.

`wavenumber1` and `wavenumber2` describe the resolved spectral intervals in
cm^-1. `gpoint_fraction` has shape `(wavenumber, gpoint)` and gives the
fractional contribution of each interval to each gas-optics g-point.

Fields are

$(TYPEDFIELDS)
"""
struct EcCKDSpectralMapping{FT, V, M}
    "Lower wavenumber edge for each resolved spectral interval in cm^-1."
    wavenumber1::V
    "Upper wavenumber edge for each resolved spectral interval in cm^-1."
    wavenumber2::V
    "Fractional contribution with shape `(wavenumber, gpoint)`."
    gpoint_fraction::M
    "Spectral interval weights, e.g. solar irradiance or Planck weights."
    interval_weight::V
end

Base.eltype(::EcCKDSpectralMapping{FT}) where FT = FT

function EcCKDSpectralMapping(; wavenumber1::AbstractVector{FT},
                              wavenumber2::AbstractVector{FT},
                              gpoint_fraction::AbstractMatrix{FT},
                              interval_weight::Union{Nothing, AbstractVector{FT}} =
                                  nothing) where FT
    length(wavenumber1) == length(wavenumber2) ||
        throw(DimensionMismatch("wavenumber1 and wavenumber2 must have the same length"))
    size(gpoint_fraction, 1) == length(wavenumber1) ||
        throw(DimensionMismatch("gpoint_fraction first dimension must match wavenumber intervals"))
    resolved_interval_weight = interval_weight === nothing ?
        fill(one(FT), length(wavenumber1)) :
        interval_weight
    length(resolved_interval_weight) == length(wavenumber1) ||
        throw(DimensionMismatch("interval_weight must match wavenumber intervals"))
    return EcCKDSpectralMapping{FT, typeof(wavenumber1), typeof(gpoint_fraction)}(
        wavenumber1,
        wavenumber2,
        gpoint_fraction,
        resolved_interval_weight,
    )
end

function CloudScatteringTable(; medium::AbstractString = "",
                              particle_type::AbstractString = "",
                              wavenumber::AbstractVector{FT},
                              effective_radius::AbstractVector{FT},
                              mass_extinction_coefficient::AbstractMatrix{FT},
                              single_scattering_albedo::AbstractMatrix{FT},
                              asymmetry_factor::AbstractMatrix{FT}) where FT
    expected_size = (length(wavenumber), length(effective_radius))
    size(mass_extinction_coefficient) == expected_size ||
        throw(DimensionMismatch("mass_extinction_coefficient must have shape (wavenumber, effective_radius)"))
    size(single_scattering_albedo) == expected_size ||
        throw(DimensionMismatch("single_scattering_albedo must have shape (wavenumber, effective_radius)"))
    size(asymmetry_factor) == expected_size ||
        throw(DimensionMismatch("asymmetry_factor must have shape (wavenumber, effective_radius)"))
    return CloudScatteringTable{FT, typeof(wavenumber),
                                typeof(mass_extinction_coefficient)}(
        String(medium),
        String(particle_type),
        wavenumber,
        effective_radius,
        mass_extinction_coefficient,
        single_scattering_albedo,
        asymmetry_factor,
    )
end

"""
    read_cloud_scattering_table(path)

Read an ecRad-style cloud scattering NetCDF file. The core package does not
depend on NetCDF libraries; NetCDF-backed loading is provided by the
NCDatasets extension.
"""
function read_cloud_scattering_table(path::AbstractString)
    # The NCDatasets extension specializes `::String`, so convert other string
    # types (a `SubString` from `strip`/`split`) instead of reporting them here as
    # a missing extension.
    path isa String || return read_cloud_scattering_table(String(path))
    throw(ArgumentError("read_cloud_scattering_table requires the NetCDF reader extension; load NCDatasets.jl before calling it"))
end

"""
    read_ecckd_spectral_mapping(path)

Read the ecCKD resolved-spectral to g-point mapping from a CKD-definition
NetCDF file. NetCDF-backed loading is provided by the NCDatasets extension.
"""
function read_ecckd_spectral_mapping(path::AbstractString)
    # The NCDatasets extension specializes `::String`, so convert other string
    # types (a `SubString` from `strip`/`split`) instead of reporting them here as
    # a missing extension.
    path isa String || return read_ecckd_spectral_mapping(String(path))
    throw(ArgumentError("read_ecckd_spectral_mapping requires the NetCDF reader extension; load NCDatasets.jl before calling it"))
end

@inline function linear_radius_index(table::CloudScatteringTable, effective_radius)
    radius = table.effective_radius
    target = clamp(effective_radius, first(radius), last(radius))
    upper = searchsortedfirst(radius, target)
    if upper <= firstindex(radius)
        return firstindex(radius), firstindex(radius), zero(eltype(table))
    elseif upper > lastindex(radius)
        return lastindex(radius), lastindex(radius), zero(eltype(table))
    end
    lower = upper - 1
    weight = (target - radius[lower]) / (radius[upper] - radius[lower])
    return lower, upper, weight
end

@inline function nearest_wavenumber_index(table::CloudScatteringTable, wavenumber)
    grid = table.wavenumber
    upper = searchsortedfirst(grid, wavenumber)
    if upper <= firstindex(grid)
        return firstindex(grid)
    elseif upper > lastindex(grid)
        return lastindex(grid)
    end
    lower = upper - 1
    return abs(grid[upper] - wavenumber) < abs(wavenumber - grid[lower]) ?
        upper : lower
end

"""
    cloud_scattering_properties(table, iwavenumber, effective_radius)

Interpolate raw cloud scattering properties at one wavenumber-grid index and
effective radius. Returns mass extinction, single-scattering albedo, and
asymmetry factor.
"""
function cloud_scattering_properties(table::CloudScatteringTable, iwavenumber::Integer,
                                     effective_radius)
    lower, upper, weight = linear_radius_index(table, effective_radius)
    w₀ = one(eltype(table)) - weight
    mass_extinction = w₀ * table.mass_extinction_coefficient[iwavenumber, lower] +
               weight * table.mass_extinction_coefficient[iwavenumber, upper]
    ω = w₀ * table.single_scattering_albedo[iwavenumber, lower] +
          weight * table.single_scattering_albedo[iwavenumber, upper]
    asymmetry = w₀ * table.asymmetry_factor[iwavenumber, lower] +
                weight * table.asymmetry_factor[iwavenumber, upper]
    return (
        mass_extinction_coefficient = mass_extinction,
        single_scattering_albedo = ω,
        asymmetry_factor = asymmetry,
    )
end

"""
    cloud_scattering_gpoint_properties(table, mapping, effective_radius)

Map raw cloud-scattering table properties onto an ecCKD g-point grid using
the resolved spectral intervals and `gpoint_fraction` weights from an
[`EcCKDSpectralMapping`](@ref). Returns vectors of mass extinction,
single-scattering albedo, and asymmetry factor with one entry per g-point.

The current mapper samples the nearest cloud-scattering table wavenumber at
each ecCKD interval midpoint and uses interval width times g-point fraction as
the quadrature weight. Single-scattering albedo is extinction-weighted, and
asymmetry is scattering-extinction-weighted.
"""
function cloud_scattering_gpoint_properties(table::CloudScatteringTable,
                                            mapping::EcCKDSpectralMapping,
                                            effective_radius;
                                            mapping_method::Symbol = :midpoint,
                                            delta_eddington_average::Bool = false,
                                            thick_averaging::Bool = false)
    if mapping_method == :ecrad
        return cloud_scattering_gpoint_properties_ecrad(
            table, mapping, effective_radius;
            delta_eddington_average = delta_eddington_average,
            thick_averaging = thick_averaging,
        )
    elseif mapping_method != :midpoint
        throw(ArgumentError("unsupported cloud scattering mapping_method=$mapping_method"))
    end

    FT = promote_type(eltype(table), eltype(mapping), typeof(float(effective_radius)))
    Ngpoints = size(mapping.gpoint_fraction, 2)
    mass_extinction = zeros(FT, Ngpoints)
    scattering_extinction = zeros(FT, Ngpoints)
    asymmetry_numerator = zeros(FT, Ngpoints)
    weight_sum = zeros(FT, Ngpoints)

    for interval in axes(mapping.gpoint_fraction, 1)
        width = abs(FT(mapping.wavenumber2[interval]) - FT(mapping.wavenumber1[interval]))
        midpoint = (FT(mapping.wavenumber1[interval]) + FT(mapping.wavenumber2[interval])) / FT(2)
        table_index = nearest_wavenumber_index(table, midpoint)
        properties = cloud_scattering_properties(table, table_index, effective_radius)
        κ = FT(properties.mass_extinction_coefficient)
        ω = FT(properties.single_scattering_albedo)
        g = FT(properties.asymmetry_factor)
        if delta_eddington_average
            κ, ω, g = delta_eddington(κ, ω, g)
        end
        for gpoint in 1:Ngpoints
            weight = width * FT(mapping.interval_weight[interval]) *
                FT(mapping.gpoint_fraction[interval, gpoint])
            weight == 0 && continue
            κ_scattering = κ * ω
            mass_extinction[gpoint] += weight * κ
            scattering_extinction[gpoint] += weight * κ_scattering
            asymmetry_numerator[gpoint] += weight * κ_scattering * g
            weight_sum[gpoint] += weight
        end
    end

    single_scattering_albedo = zeros(FT, Ngpoints)
    asymmetry = zeros(FT, Ngpoints)
    for gpoint in 1:Ngpoints
        if weight_sum[gpoint] > 0
            mass_extinction[gpoint] /= weight_sum[gpoint]
            scattering_extinction[gpoint] /= weight_sum[gpoint]
        end
        if mass_extinction[gpoint] > 0
            single_scattering_albedo[gpoint] = clamp(scattering_extinction[gpoint] / mass_extinction[gpoint], zero(FT), one(FT))
        end
        if scattering_extinction[gpoint] > 0
            asymmetry[gpoint] = clamp(asymmetry_numerator[gpoint] / (scattering_extinction[gpoint] * weight_sum[gpoint]),
                                  -one(FT), one(FT))
        end
        if delta_eddington_average
            mass_extinction[gpoint], single_scattering_albedo[gpoint], asymmetry[gpoint] =
                revert_delta_eddington(mass_extinction[gpoint], single_scattering_albedo[gpoint], asymmetry[gpoint])
        end
    end
    return (
        mass_extinction_coefficient = mass_extinction,
        single_scattering_albedo,
        asymmetry_factor = asymmetry,
    )
end

@inline function find_spectral_interval(mapping::EcCKDSpectralMapping, wavenumber)
    for i in eachindex(mapping.wavenumber1)
        if wavenumber >= mapping.wavenumber1[i] && wavenumber <= mapping.wavenumber2[i]
            return i
        end
    end
    return 0
end

function ecrad_cloud_mapping_matrix(table::CloudScatteringTable,
                                     mapping::EcCKDSpectralMapping)
    FT = promote_type(eltype(table), eltype(mapping))
    Nwavenumbers = length(table.wavenumber)
    Nintervals = length(mapping.wavenumber1)
    Ngpoints = size(mapping.gpoint_fraction, 2)
    matrix = zeros(FT, Ngpoints, Nwavenumbers)
    interval_weight = zeros(FT, Nintervals)

    for wavenumber_index in 1:Nwavenumbers
        fill!(interval_weight, zero(FT))
        ν̃₁ = FT(table.wavenumber[wavenumber_index])
        interval₁ = find_spectral_interval(mapping, ν̃₁)
        interval₁ < 1 && continue

        if wavenumber_index > 1
            ν̃₀ = FT(table.wavenumber[wavenumber_index - 1])
            interval₀ = find_spectral_interval(mapping, ν̃₀)
            if interval₀ == interval₁
                interval_weight[interval₀] = FT(0.5) * (ν̃₁ - ν̃₀) /
                    (FT(mapping.wavenumber2[interval₀]) - FT(mapping.wavenumber1[interval₀]))
            else
                if interval₀ >= 1
                    interval_weight[interval₀] = FT(0.5) *
                        (FT(mapping.wavenumber2[interval₀]) - ν̃₀)^2 /
                        ((FT(mapping.wavenumber2[interval₀]) - FT(mapping.wavenumber1[interval₀])) *
                         (ν̃₁ - ν̃₀))
                end
                interval_weight[interval₁] = FT(0.5) *
                    (one(FT) + (FT(mapping.wavenumber1[interval₁]) - ν̃₁) /
                     (ν̃₁ - ν̃₀)) *
                    (ν̃₁ - FT(mapping.wavenumber1[interval₁])) /
                    (FT(mapping.wavenumber2[interval₁]) - FT(mapping.wavenumber1[interval₁]))
                if interval₀ >= 1 && interval₁ - interval₀ > 1
                    for interval in (interval₀ + 1):(interval₁ - 1)
                        interval_weight[interval] = FT(0.5) *
                            (FT(mapping.wavenumber1[interval]) + FT(mapping.wavenumber2[interval]) -
                             FT(2) * ν̃₀) / (ν̃₁ - ν̃₀)
                    end
                end
            end
        else
            interval₁ > 1 && (interval_weight[1:(interval₁ - 1)] .= one(FT))
            interval_weight[interval₁] =
                (ν̃₁ - FT(mapping.wavenumber1[interval₁])) /
                (FT(mapping.wavenumber2[interval₁]) - FT(mapping.wavenumber1[interval₁]))
        end

        if wavenumber_index < Nwavenumbers
            ν̃₂ = FT(table.wavenumber[wavenumber_index + 1])
            interval₂ = find_spectral_interval(mapping, ν̃₂)
            if interval₁ == interval₂
                interval_weight[interval₁] += FT(0.5) * (ν̃₂ - ν̃₁) /
                    (FT(mapping.wavenumber2[interval₁]) - FT(mapping.wavenumber1[interval₁]))
            else
                if 1 <= interval₂ <= Nintervals
                    interval_weight[interval₂] += FT(0.5) *
                        (ν̃₂ - FT(mapping.wavenumber1[interval₂]))^2 /
                        ((FT(mapping.wavenumber2[interval₂]) - FT(mapping.wavenumber1[interval₂])) *
                         (ν̃₂ - ν̃₁))
                end
                interval_weight[interval₁] += FT(0.5) *
                    (one(FT) + (ν̃₂ - FT(mapping.wavenumber2[interval₁])) /
                     (ν̃₂ - ν̃₁)) *
                    (FT(mapping.wavenumber2[interval₁]) - ν̃₁) /
                    (FT(mapping.wavenumber2[interval₁]) - FT(mapping.wavenumber1[interval₁]))
                if interval₂ >= 1 && interval₂ - interval₁ > 1
                    for interval in (interval₁ + 1):(interval₂ - 1)
                        interval_weight[interval] += FT(0.5) *
                            (FT(2) * ν̃₂ - FT(mapping.wavenumber1[interval]) -
                             FT(mapping.wavenumber2[interval])) / (ν̃₂ - ν̃₁)
                    end
                end
            end
        else
            interval₁ < Nintervals && (interval_weight[(interval₁ + 1):Nintervals] .= one(FT))
            interval_weight[interval₁] =
                (FT(mapping.wavenumber2[interval₁]) - ν̃₁) /
                (FT(mapping.wavenumber2[interval₁]) - FT(mapping.wavenumber1[interval₁]))
        end

        interval_weight .*= FT.(mapping.interval_weight)
        for gpoint in 1:Ngpoints
            matrix[gpoint, wavenumber_index] = sum(interval_weight .* view(mapping.gpoint_fraction, :, gpoint))
        end
    end

    for gpoint in 1:Ngpoints
        total = sum(view(matrix, gpoint, :))
        total > 0 && (matrix[gpoint, :] ./= total)
    end
    return matrix
end

@inline function delta_eddington(τ, ω, asymmetry)
    f = asymmetry * asymmetry
    denominator = one(τ) - ω * f
    return (
        τ * denominator,
        ω * (one(ω) - f) / denominator,
        asymmetry / (one(asymmetry) + asymmetry),
    )
end

@inline function revert_delta_eddington(τ, ω, asymmetry)
    g = asymmetry / (one(asymmetry) - asymmetry)
    f = g * g
    ω_reverted = ω / (one(ω) - f + f * ω)
    τ_reverted = τ / (one(τ) - ω_reverted * f)
    return τ_reverted, ω_reverted, g
end

function cloud_scattering_gpoint_properties_ecrad(table::CloudScatteringTable,
                                                   mapping::EcCKDSpectralMapping,
                                                   effective_radius;
                                                   delta_eddington_average::Bool,
                                                   thick_averaging::Bool)
    FT = promote_type(eltype(table), eltype(mapping), typeof(float(effective_radius)))
    weights = ecrad_cloud_mapping_matrix(table, mapping)
    Ngpoints = size(weights, 1)
    mass_extinction = zeros(FT, Ngpoints)
    scattering_extinction = zeros(FT, Ngpoints)
    asymmetry_numerator = zeros(FT, Ngpoints)
    thick_reflectance = zeros(FT, Ngpoints)

    for wavenumber_index in axes(weights, 2)
        properties = cloud_scattering_properties(table, wavenumber_index, effective_radius)
        κ = FT(properties.mass_extinction_coefficient)
        ω = FT(properties.single_scattering_albedo)
        g = FT(properties.asymmetry_factor)
        if delta_eddington_average
            κ, ω, g = delta_eddington(κ, ω, g)
        end
        κ_scattering = κ * ω
        reflectance_semi_infinite = zero(FT)
        if thick_averaging
            denominator = max(one(FT) - ω * g, eps(FT))
            root = sqrt(max((one(FT) - ω) / denominator, zero(FT)))
            reflectance_semi_infinite = (one(FT) - root) / (one(FT) + root)
        end
        for gpoint in 1:Ngpoints
            weight = FT(weights[gpoint, wavenumber_index])
            weight == 0 && continue
            mass_extinction[gpoint] += weight * κ
            scattering_extinction[gpoint] += weight * κ_scattering
            asymmetry_numerator[gpoint] += weight * κ_scattering * g
            thick_reflectance[gpoint] += weight * reflectance_semi_infinite
        end
    end

    single_scattering_albedo = zeros(FT, Ngpoints)
    asymmetry = zeros(FT, Ngpoints)
    for gpoint in 1:Ngpoints
        mass_extinction[gpoint] > 0 &&
            (single_scattering_albedo[gpoint] = clamp(scattering_extinction[gpoint] / mass_extinction[gpoint], zero(FT), one(FT)))
        scattering_extinction[gpoint] > 0 &&
            (asymmetry[gpoint] = clamp(asymmetry_numerator[gpoint] / scattering_extinction[gpoint],
                                   -one(FT), one(FT)))
        if thick_averaging
            reflectance = clamp(thick_reflectance[gpoint], zero(FT), one(FT))
            denominator = (one(FT) + reflectance)^2 -
                asymmetry[gpoint] * (one(FT) - reflectance)^2
            single_scattering_albedo[gpoint] = denominator > 0 ?
                clamp(FT(4) * reflectance / denominator, zero(FT), one(FT)) :
                zero(FT)
        end
        if delta_eddington_average
            mass_extinction[gpoint], single_scattering_albedo[gpoint], asymmetry[gpoint] =
                revert_delta_eddington(mass_extinction[gpoint], single_scattering_albedo[gpoint], asymmetry[gpoint])
        end
    end

    return (
        mass_extinction_coefficient = mass_extinction,
        single_scattering_albedo,
        asymmetry_factor = asymmetry,
    )
end
