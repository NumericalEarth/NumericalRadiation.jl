"""
$(TYPEDEF)

Dependency-light cloud scattering table.

The table stores raw ecRad-style scattering properties as a function of
wavenumber and effective radius. Spectral mapping to radiation bands or
g-points is a separate operation because it depends on the gas-optics spectral
definition and averaging convention.

Fields:
- `medium`: Hydrometeor medium, for example `liquid-water` or `ice`
- `particle_type`: Particle type from file metadata
- `wavenumber`: Wavenumber grid in cm^-1
- `effective_radius`: Effective-radius grid in m
- `mass_extinction_coefficient`: Mass-extinction coefficient with shape
  `(wavenumber, effective_radius)`
- `single_scattering_albedo`: Single-scattering albedo with shape
  `(wavenumber, effective_radius)`
- `asymmetry_factor`: Scattering asymmetry factor with shape
  `(wavenumber, effective_radius)`
"""
struct CloudScatteringTable{FT, V, M}
    medium::String
    particle_type::String
    wavenumber::V
    effective_radius::V
    mass_extinction_coefficient::M
    single_scattering_albedo::M
    asymmetry_factor::M
end

Base.eltype(::CloudScatteringTable{FT}) where FT = FT

"""
$(TYPEDEF)

Spectral mapping from ecCKD resolved wavenumber intervals to g-points.

`wavenumber1` and `wavenumber2` describe the resolved spectral intervals in
cm^-1. `gpoint_fraction` has shape `(wavenumber, g)` and gives the
fractional contribution of each interval to each gas-optics g-point.

Fields:
- `wavenumber1`: Lower wavenumber edge for each resolved spectral interval in cm^-1
- `wavenumber2`: Upper wavenumber edge for each resolved spectral interval in cm^-1
- `gpoint_fraction`: Fractional contribution with shape `(wavenumber, g)`
- `interval_weight`: Spectral interval weights, e.g. solar irradiance or Planck weights
"""
struct EcCKDSpectralMapping{FT, V, M}
    wavenumber1::V
    wavenumber2::V
    gpoint_fraction::M
    interval_weight::V
end

Base.eltype(::EcCKDSpectralMapping{FT}) where FT = FT

function EcCKDSpectralMapping(; wavenumber1::AbstractVector{FT},
                                wavenumber2::AbstractVector{FT},
                                gpoint_fraction::AbstractMatrix{FT},
                                interval_weight::Union{Nothing, AbstractVector{FT}} = nothing) where FT
    length(wavenumber1) == length(wavenumber2) ||
        throw(DimensionMismatch("wavenumber1 and wavenumber2 must have the same length"))
    size(gpoint_fraction, 1) == length(wavenumber1) ||
        throw(DimensionMismatch("gpoint_fraction first dimension must match wavenumber intervals"))
    resolved_interval_weight = interval_weight === nothing ? fill(one(FT), length(wavenumber1)) : interval_weight
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
    # The NCDatasets extension reads a `String`; other string types are converted first.
    path isa String || return read_cloud_scattering_table(String(path))
    throw(ArgumentError("read_cloud_scattering_table requires the NetCDF reader extension; load NCDatasets.jl before calling it"))
end

"""
    read_ecckd_spectral_mapping(path)

Read the ecCKD resolved-spectral to g-point mapping from a CKD-definition
NetCDF file. NetCDF-backed loading is provided by the NCDatasets extension.
"""
function read_ecckd_spectral_mapping(path::AbstractString; kwargs...)
    # The NCDatasets extension reads a `String`; other string types are converted first.
    path isa String || return read_ecckd_spectral_mapping(String(path); kwargs...)
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
    return abs(grid[upper] - wavenumber) < abs(wavenumber - grid[lower]) ? upper : lower
end

"""
    cloud_scattering_properties(table, iwavenumber, effective_radius)

Interpolate raw cloud scattering properties at one wavenumber-grid index and
effective radius. Returns mass extinction, single-scattering albedo, and
asymmetry factor.
"""
function cloud_scattering_properties(table::CloudScatteringTable, iwavenumber::Integer, effective_radius)
    lower, upper, weight = linear_radius_index(table, effective_radius)
    w₀ = one(eltype(table)) - weight
    mass_extinction_coefficient = w₀ * table.mass_extinction_coefficient[iwavenumber, lower] +
                                  weight * table.mass_extinction_coefficient[iwavenumber, upper]
    single_scattering_albedo = w₀ * table.single_scattering_albedo[iwavenumber, lower] +
                               weight * table.single_scattering_albedo[iwavenumber, upper]
    asymmetry_factor = w₀ * table.asymmetry_factor[iwavenumber, lower] +
                       weight * table.asymmetry_factor[iwavenumber, upper]
    return (; mass_extinction_coefficient, single_scattering_albedo, asymmetry_factor)
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
    Ng = size(mapping.gpoint_fraction, 2)
    # Weighted sums over the intervals of each g point: Σw κ, Σw κω (the
    # scattering extinction) and Σw κω 𝒢, plus the weights Σw.
    Σκ = zeros(FT, Ng)
    Σκ_scattering = zeros(FT, Ng)
    Σκ_scattering_𝒢 = zeros(FT, Ng)
    Σw = zeros(FT, Ng)

    for interval in axes(mapping.gpoint_fraction, 1)
        width = abs(FT(mapping.wavenumber2[interval]) - FT(mapping.wavenumber1[interval]))
        midpoint = (FT(mapping.wavenumber1[interval]) + FT(mapping.wavenumber2[interval])) / FT(2)
        table_index = nearest_wavenumber_index(table, midpoint)
        properties = cloud_scattering_properties(table, table_index, effective_radius)
        κ = FT(properties.mass_extinction_coefficient)
        ω = FT(properties.single_scattering_albedo)
        𝒢 = FT(properties.asymmetry_factor)
        if delta_eddington_average
            κ, ω, 𝒢 = delta_eddington(κ, ω, 𝒢)
        end
        for g in 1:Ng
            w = width * FT(mapping.interval_weight[interval]) * FT(mapping.gpoint_fraction[interval, g])
            w == 0 && continue
            κ_scattering = κ * ω
            Σκ[g] += w * κ
            Σκ_scattering[g] += w * κ_scattering
            Σκ_scattering_𝒢[g] += w * κ_scattering * 𝒢
            Σw[g] += w
        end
    end

    ω = zeros(FT, Ng)
    𝒢 = zeros(FT, Ng)
    for g in 1:Ng
        if Σw[g] > 0
            Σκ[g] /= Σw[g]
            Σκ_scattering[g] /= Σw[g]
        end
        if Σκ[g] > 0
            ω[g] = clamp(Σκ_scattering[g] / Σκ[g], zero(FT), one(FT))
        end
        if Σκ_scattering[g] > 0
            𝒢[g] = clamp(Σκ_scattering_𝒢[g] / (Σκ_scattering[g] * Σw[g]), -one(FT), one(FT))
        end
        if delta_eddington_average
            Σκ[g], ω[g], 𝒢[g] = revert_delta_eddington(Σκ[g], ω[g], 𝒢[g])
        end
    end
    return (mass_extinction_coefficient=Σκ, single_scattering_albedo=ω, asymmetry_factor=𝒢)
end

@inline function find_spectral_interval(mapping::EcCKDSpectralMapping, wavenumber)
    for i in eachindex(mapping.wavenumber1)
        if wavenumber >= mapping.wavenumber1[i] && wavenumber <= mapping.wavenumber2[i]
            return i
        end
    end
    return 0
end

function ecrad_cloud_mapping_matrix(table::CloudScatteringTable, mapping::EcCKDSpectralMapping)
    FT = promote_type(eltype(table), eltype(mapping))
    Nwavenumbers = length(table.wavenumber)
    Nintervals = length(mapping.wavenumber1)
    Ng = size(mapping.gpoint_fraction, 2)
    matrix = zeros(FT, Ng, Nwavenumbers)
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
            interval_weight[interval₁] = (ν̃₁ - FT(mapping.wavenumber1[interval₁])) /
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
            interval_weight[interval₁] = (FT(mapping.wavenumber2[interval₁]) - ν̃₁) /
                                         (FT(mapping.wavenumber2[interval₁]) - FT(mapping.wavenumber1[interval₁]))
        end

        interval_weight .*= FT.(mapping.interval_weight)
        for g in 1:Ng
            matrix[g, wavenumber_index] = sum(interval_weight .* view(mapping.gpoint_fraction, :, g))
        end
    end

    for g in 1:Ng
        total = sum(view(matrix, g, :))
        total > 0 && (matrix[g, :] ./= total)
    end
    return matrix
end

# Delta-Eddington scaling `(τ, ω, 𝒢) -> (τ′, ω′, 𝒢′)` with forward peak `f = 𝒢²`,
#     τ′ = (1 - ω f) τ,   ω′ = (1 - f) ω / (1 - ω f),   𝒢′ = 𝒢 / (1 + 𝒢),
# and its inverse, used to average cloud properties in the scaled space.
@inline function delta_eddington(τ, ω, 𝒢)
    f = 𝒢 * 𝒢
    # A pure forward peak leaves a purely absorbing layer; the rescaling is 0/0 there.
    f >= one(f) && return ((one(ω) - ω) * τ, zero(ω), zero(𝒢))
    denominator = one(τ) - ω * f
    return (τ * denominator, ω * (one(ω) - f) / denominator, 𝒢 / (one(𝒢) + 𝒢))
end

@inline function revert_delta_eddington(τ′, ω′, 𝒢′)
    𝒢 = 𝒢′ / (one(𝒢′) - 𝒢′)
    f = 𝒢 * 𝒢
    ω = ω′ / (one(ω′) - f + f * ω′)
    τ = τ′ / (one(τ′) - ω * f)
    return τ, ω, 𝒢
end

function cloud_scattering_gpoint_properties_ecrad(table::CloudScatteringTable,
                                                  mapping::EcCKDSpectralMapping,
                                                  effective_radius;
                                                  delta_eddington_average::Bool,
                                                  thick_averaging::Bool)
    FT = promote_type(eltype(table), eltype(mapping), typeof(float(effective_radius)))
    weights = ecrad_cloud_mapping_matrix(table, mapping)
    Ng = size(weights, 1)
    # Weighted sums over the table wavenumbers of each g point (the weights of
    # each g point sum to one): Σw κ, Σw κω, Σw κω 𝒢 and Σw ℛ∞, the latter the
    # reflectance of a semi-infinite layer used by ecRad's thick averaging.
    Σκ = zeros(FT, Ng)
    Σκ_scattering = zeros(FT, Ng)
    Σκ_scattering_𝒢 = zeros(FT, Ng)
    Σℛ∞ = zeros(FT, Ng)

    for wavenumber_index in axes(weights, 2)
        properties = cloud_scattering_properties(table, wavenumber_index, effective_radius)
        κ = FT(properties.mass_extinction_coefficient)
        ω = FT(properties.single_scattering_albedo)
        𝒢 = FT(properties.asymmetry_factor)
        if delta_eddington_average
            κ, ω, 𝒢 = delta_eddington(κ, ω, 𝒢)
        end
        κ_scattering = κ * ω
        ℛ∞ = zero(FT)
        if thick_averaging
            denominator = max(one(FT) - ω * 𝒢, eps(FT))
            root = sqrt(max((one(FT) - ω) / denominator, zero(FT)))
            ℛ∞ = (one(FT) - root) / (one(FT) + root)
        end
        for g in 1:Ng
            w = FT(weights[g, wavenumber_index])
            w == 0 && continue
            Σκ[g] += w * κ
            Σκ_scattering[g] += w * κ_scattering
            Σκ_scattering_𝒢[g] += w * κ_scattering * 𝒢
            Σℛ∞[g] += w * ℛ∞
        end
    end

    ω = zeros(FT, Ng)
    𝒢 = zeros(FT, Ng)
    for g in 1:Ng
        Σκ[g] > 0 && (ω[g] = clamp(Σκ_scattering[g] / Σκ[g], zero(FT), one(FT)))
        Σκ_scattering[g] > 0 &&
            (𝒢[g] = clamp(Σκ_scattering_𝒢[g] / Σκ_scattering[g],
                          -one(FT), one(FT)))
        if thick_averaging
            ℛ∞ = clamp(Σℛ∞[g], zero(FT), one(FT))
            denominator = (one(FT) + ℛ∞)^2 - 𝒢[g] * (one(FT) - ℛ∞)^2
            ω[g] = denominator > 0 ? clamp(FT(4) * ℛ∞ / denominator, zero(FT), one(FT)) : zero(FT)
        end
        if delta_eddington_average
            Σκ[g], ω[g], 𝒢[g] = revert_delta_eddington(Σκ[g], ω[g], 𝒢[g])
        end
    end

    return (mass_extinction_coefficient=Σκ, single_scattering_albedo=ω, asymmetry_factor=𝒢)
end
