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
    w1 = one(eltype(table)) - weight
    mass_ext = w1 * table.mass_extinction_coefficient[iwavenumber, lower] +
               weight * table.mass_extinction_coefficient[iwavenumber, upper]
    ssa = w1 * table.single_scattering_albedo[iwavenumber, lower] +
          weight * table.single_scattering_albedo[iwavenumber, upper]
    asymmetry = w1 * table.asymmetry_factor[iwavenumber, lower] +
                weight * table.asymmetry_factor[iwavenumber, upper]
    return (
        mass_extinction_coefficient = mass_ext,
        single_scattering_albedo = ssa,
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
    ng = size(mapping.gpoint_fraction, 2)
    mass_ext = zeros(FT, ng)
    scattering_ext = zeros(FT, ng)
    asymmetry_numer = zeros(FT, ng)
    weight_sum = zeros(FT, ng)

    for iw in axes(mapping.gpoint_fraction, 1)
        width = abs(FT(mapping.wavenumber2[iw]) - FT(mapping.wavenumber1[iw]))
        midpoint = (FT(mapping.wavenumber1[iw]) + FT(mapping.wavenumber2[iw])) / FT(2)
        itable = nearest_wavenumber_index(table, midpoint)
        props = cloud_scattering_properties(table, itable, effective_radius)
        ext = FT(props.mass_extinction_coefficient)
        ssa = FT(props.single_scattering_albedo)
        asym = FT(props.asymmetry_factor)
        if delta_eddington_average
            ext, ssa, asym = delta_eddington(ext, ssa, asym)
        end
        for ig in 1:ng
            weight = width * FT(mapping.interval_weight[iw]) *
                FT(mapping.gpoint_fraction[iw, ig])
            weight == 0 && continue
            scat = ext * ssa
            mass_ext[ig] += weight * ext
            scattering_ext[ig] += weight * scat
            asymmetry_numer[ig] += weight * scat * asym
            weight_sum[ig] += weight
        end
    end

    ssa = zeros(FT, ng)
    asymmetry = zeros(FT, ng)
    for ig in 1:ng
        if weight_sum[ig] > 0
            mass_ext[ig] /= weight_sum[ig]
            scattering_ext[ig] /= weight_sum[ig]
        end
        if mass_ext[ig] > 0
            ssa[ig] = clamp(scattering_ext[ig] / mass_ext[ig], zero(FT), one(FT))
        end
        if scattering_ext[ig] > 0
            asymmetry[ig] = clamp(asymmetry_numer[ig] / (scattering_ext[ig] * weight_sum[ig]),
                                  -one(FT), one(FT))
        end
        if delta_eddington_average
            mass_ext[ig], ssa[ig], asymmetry[ig] =
                revert_delta_eddington(mass_ext[ig], ssa[ig], asymmetry[ig])
        end
    end
    return (
        mass_extinction_coefficient = mass_ext,
        single_scattering_albedo = ssa,
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
    nwav = length(table.wavenumber)
    nspectral = length(mapping.wavenumber1)
    ng = size(mapping.gpoint_fraction, 2)
    matrix = zeros(FT, ng, nwav)
    interval_weight = zeros(FT, nspectral)

    for jwav in 1:nwav
        fill!(interval_weight, zero(FT))
        wavenum1 = FT(table.wavenumber[jwav])
        isd1 = find_spectral_interval(mapping, wavenum1)
        isd1 < 1 && continue

        if jwav > 1
            wavenum0 = FT(table.wavenumber[jwav - 1])
            isd0 = find_spectral_interval(mapping, wavenum0)
            if isd0 == isd1
                interval_weight[isd0] = FT(0.5) * (wavenum1 - wavenum0) /
                    (FT(mapping.wavenumber2[isd0]) - FT(mapping.wavenumber1[isd0]))
            else
                if isd0 >= 1
                    interval_weight[isd0] = FT(0.5) *
                        (FT(mapping.wavenumber2[isd0]) - wavenum0)^2 /
                        ((FT(mapping.wavenumber2[isd0]) - FT(mapping.wavenumber1[isd0])) *
                         (wavenum1 - wavenum0))
                end
                interval_weight[isd1] = FT(0.5) *
                    (one(FT) + (FT(mapping.wavenumber1[isd1]) - wavenum1) /
                     (wavenum1 - wavenum0)) *
                    (wavenum1 - FT(mapping.wavenumber1[isd1])) /
                    (FT(mapping.wavenumber2[isd1]) - FT(mapping.wavenumber1[isd1]))
                if isd0 >= 1 && isd1 - isd0 > 1
                    for isd in (isd0 + 1):(isd1 - 1)
                        interval_weight[isd] = FT(0.5) *
                            (FT(mapping.wavenumber1[isd]) + FT(mapping.wavenumber2[isd]) -
                             FT(2) * wavenum0) / (wavenum1 - wavenum0)
                    end
                end
            end
        else
            isd1 > 1 && (interval_weight[1:(isd1 - 1)] .= one(FT))
            interval_weight[isd1] =
                (wavenum1 - FT(mapping.wavenumber1[isd1])) /
                (FT(mapping.wavenumber2[isd1]) - FT(mapping.wavenumber1[isd1]))
        end

        if jwav < nwav
            wavenum2 = FT(table.wavenumber[jwav + 1])
            isd2 = find_spectral_interval(mapping, wavenum2)
            if isd1 == isd2
                interval_weight[isd1] += FT(0.5) * (wavenum2 - wavenum1) /
                    (FT(mapping.wavenumber2[isd1]) - FT(mapping.wavenumber1[isd1]))
            else
                if 1 <= isd2 <= nspectral
                    interval_weight[isd2] += FT(0.5) *
                        (wavenum2 - FT(mapping.wavenumber1[isd2]))^2 /
                        ((FT(mapping.wavenumber2[isd2]) - FT(mapping.wavenumber1[isd2])) *
                         (wavenum2 - wavenum1))
                end
                interval_weight[isd1] += FT(0.5) *
                    (one(FT) + (wavenum2 - FT(mapping.wavenumber2[isd1])) /
                     (wavenum2 - wavenum1)) *
                    (FT(mapping.wavenumber2[isd1]) - wavenum1) /
                    (FT(mapping.wavenumber2[isd1]) - FT(mapping.wavenumber1[isd1]))
                if isd2 >= 1 && isd2 - isd1 > 1
                    for isd in (isd1 + 1):(isd2 - 1)
                        interval_weight[isd] += FT(0.5) *
                            (FT(2) * wavenum2 - FT(mapping.wavenumber1[isd]) -
                             FT(mapping.wavenumber2[isd])) / (wavenum2 - wavenum1)
                    end
                end
            end
        else
            isd1 < nspectral && (interval_weight[(isd1 + 1):nspectral] .= one(FT))
            interval_weight[isd1] =
                (FT(mapping.wavenumber2[isd1]) - wavenum1) /
                (FT(mapping.wavenumber2[isd1]) - FT(mapping.wavenumber1[isd1]))
        end

        interval_weight .*= FT.(mapping.interval_weight)
        for ig in 1:ng
            matrix[ig, jwav] = sum(interval_weight .* view(mapping.gpoint_fraction, :, ig))
        end
    end

    for ig in 1:ng
        total = sum(view(matrix, ig, :))
        total > 0 && (matrix[ig, :] ./= total)
    end
    return matrix
end

@inline function delta_eddington(od, ssa, asymmetry)
    f = asymmetry * asymmetry
    denom = one(od) - ssa * f
    return (
        od * denom,
        ssa * (one(ssa) - f) / denom,
        asymmetry / (one(asymmetry) + asymmetry),
    )
end

@inline function revert_delta_eddington(od, ssa, asymmetry)
    g = asymmetry / (one(asymmetry) - asymmetry)
    f = g * g
    reverted_ssa = ssa / (one(ssa) - f + f * ssa)
    reverted_od = od / (one(od) - reverted_ssa * f)
    return reverted_od, reverted_ssa, g
end

function cloud_scattering_gpoint_properties_ecrad(table::CloudScatteringTable,
                                                   mapping::EcCKDSpectralMapping,
                                                   effective_radius;
                                                   delta_eddington_average::Bool,
                                                   thick_averaging::Bool)
    FT = promote_type(eltype(table), eltype(mapping), typeof(float(effective_radius)))
    weights = ecrad_cloud_mapping_matrix(table, mapping)
    ng = size(weights, 1)
    mass_ext = zeros(FT, ng)
    scattering_ext = zeros(FT, ng)
    asymmetry_numer = zeros(FT, ng)
    thick_reflectance = zeros(FT, ng)

    for iw in axes(weights, 2)
        props = cloud_scattering_properties(table, iw, effective_radius)
        ext = FT(props.mass_extinction_coefficient)
        ssa = FT(props.single_scattering_albedo)
        asym = FT(props.asymmetry_factor)
        if delta_eddington_average
            ext, ssa, asym = delta_eddington(ext, ssa, asym)
        end
        scat = ext * ssa
        ref_inf = zero(FT)
        if thick_averaging
            denom = max(one(FT) - ssa * asym, eps(FT))
            root = sqrt(max((one(FT) - ssa) / denom, zero(FT)))
            ref_inf = (one(FT) - root) / (one(FT) + root)
        end
        for ig in 1:ng
            weight = FT(weights[ig, iw])
            weight == 0 && continue
            mass_ext[ig] += weight * ext
            scattering_ext[ig] += weight * scat
            asymmetry_numer[ig] += weight * scat * asym
            thick_reflectance[ig] += weight * ref_inf
        end
    end

    ssa = zeros(FT, ng)
    asymmetry = zeros(FT, ng)
    for ig in 1:ng
        mass_ext[ig] > 0 &&
            (ssa[ig] = clamp(scattering_ext[ig] / mass_ext[ig], zero(FT), one(FT)))
        scattering_ext[ig] > 0 &&
            (asymmetry[ig] = clamp(asymmetry_numer[ig] / scattering_ext[ig],
                                   -one(FT), one(FT)))
        if thick_averaging
            reflectance = clamp(thick_reflectance[ig], zero(FT), one(FT))
            denom = (one(FT) + reflectance)^2 -
                asymmetry[ig] * (one(FT) - reflectance)^2
            ssa[ig] = denom > 0 ?
                clamp(FT(4) * reflectance / denom, zero(FT), one(FT)) :
                zero(FT)
        end
        if delta_eddington_average
            mass_ext[ig], ssa[ig], asymmetry[ig] =
                revert_delta_eddington(mass_ext[ig], ssa[ig], asymmetry[ig])
        end
    end

    return (
        mass_extinction_coefficient = mass_ext,
        single_scattering_albedo = ssa,
        asymmetry_factor = asymmetry,
    )
end
