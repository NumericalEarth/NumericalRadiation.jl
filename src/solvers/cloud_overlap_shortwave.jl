"""
$(TYPEDEF)

Shortwave optical properties for a two-region all-sky column.

`clear` contains gas/aerosol optical properties for the clear region.
`cloudy` contains the cloudy-region optical properties, including gas plus
cloud scattering/absorption. `cloud_fraction` is kept separate so host models
and all-sky solvers do not have to encode cloud fraction by weakening the
cloudy-region optical depth.

Fields are

$(TYPEDFIELDS)
"""
struct ShortwaveCloudOverlapOpticalProperties{FT, S, F, O, D}
    "Clear-region shortwave optical properties."
    clear::S
    "Cloudy-region shortwave optical properties."
    cloudy::S
    "Layer cloud fraction."
    cloud_fraction::F
    "Interface overlap parameter between adjacent cloudy layers."
    overlap_parameter::O
    "Layer fractional standard deviation of in-cloud condensate."
    fractional_std::D
end

function ShortwaveCloudOverlapOpticalProperties(clear::ShortwaveOpticalProperties{FT},
                                                cloudy::ShortwaveOpticalProperties{FT},
                                                cloud_fraction::AbstractVector{FT};
                                                overlap_parameter = nothing,
                                                fractional_std = nothing) where FT
    _sw_nlayers(clear) == _sw_nlayers(cloudy) ||
        throw(DimensionMismatch("clear and cloudy shortwave optics must have the same number of layers"))
    _sw_ng(clear) == _sw_ng(cloudy) ||
        throw(DimensionMismatch("clear and cloudy shortwave optics must have the same number of g-points"))
    length(cloud_fraction) == _sw_nlayers(clear) ||
        throw(DimensionMismatch("cloud_fraction must have one value per layer"))
    overlap = overlap_parameter === nothing ?
        fill(one(FT), max(_sw_nlayers(clear) - 1, 0)) :
        FT.(overlap_parameter)
    length(overlap) == max(_sw_nlayers(clear) - 1, 0) ||
        throw(DimensionMismatch("overlap_parameter must have one value between each adjacent layer"))
    fsd = fractional_std === nothing ?
        fill(one(FT), _sw_nlayers(clear)) :
        FT.(fractional_std)
    length(fsd) == _sw_nlayers(clear) ||
        throw(DimensionMismatch("fractional_std must have one value per layer"))
    return ShortwaveCloudOverlapOpticalProperties{FT, typeof(clear),
                                                  typeof(cloud_fraction),
                                                  typeof(overlap),
                                                  typeof(fsd)}(
        clear,
        cloudy,
        cloud_fraction,
        overlap,
        fsd,
    )
end

Base.eltype(::ShortwaveCloudOverlapOpticalProperties{FT}) where FT = FT

"""
$(TYPEDEF)

First deterministic all-sky shortwave overlap solver.

This solver computes clear-region and cloudy-region fluxes independently using
[`CloudlessShortwave`](@ref), then blends each interface by an explicit
interface cloud fraction. It is a staged all-sky access point, not a full
ecRad McICA/Tripleclouds implementation.

`overlap=:maximum` uses the maximum adjacent layer cloud fraction at interior
interfaces, which preserves vertically contiguous cloud cover more strongly
than averaging. `overlap=:average` uses the arithmetic mean. `overlap=:adding`
mixes clear/cloudy layer reflectance and transmittance before the adding pass.
`overlap=:matrix_maximum` carries separate clear/cloudy region fluxes through
a two-region maximum-overlap matrix during the adding pass. `overlap=:matrix_alpha`
uses the supplied ecRad/Hogan-Illingworth alpha overlap parameter between
adjacent layers. `overlap=:tripleclouds_alpha` additionally splits the cloudy
region into thin and thick regions using ecRad's gamma optical-depth scaling.
These latter modes are diagnostics between final-flux blending and a full
Tripleclouds/McICA solver.

Fields are

$(TYPEDFIELDS)
"""
struct CloudOverlapShortwave{FT, S} <: AbstractRadiativeTransferSolver
    "Underlying two-stream shortwave solver."
    clear_solver::S
    "Cloud-fraction overlap rule: `:maximum` or `:average`."
    overlap::Symbol
    "Exponent applied to layer cloud fraction before interface blending."
    cloud_fraction_exponent::FT
    "Exponent applied to alpha overlap inside the Tripleclouds inhomogeneity split."
    inhomogeneity_overlap_exponent::FT
end

function CloudOverlapShortwave(; clear_solver = CloudlessShortwave(),
                               overlap::Symbol = :maximum,
                               cloud_fraction_exponent = 1,
                               inhomogeneity_overlap_exponent = 2)
    overlap in (:maximum, :average, :adding, :matrix_maximum, :matrix_alpha,
                :tripleclouds_alpha) ||
        throw(ArgumentError("overlap must be `:maximum`, `:average`, `:adding`, `:matrix_maximum`, `:matrix_alpha`, or `:tripleclouds_alpha`"))
    FT = typeof(float(cloud_fraction_exponent))
    return CloudOverlapShortwave{FT, typeof(clear_solver)}(
        clear_solver,
        overlap,
        FT(cloud_fraction_exponent),
        FT(inhomogeneity_overlap_exponent),
    )
end

@inline function _clear_region_fraction(::Type{FT}, cloud_fraction) where FT
    return one(FT) - clamp(FT(cloud_fraction), zero(FT), one(FT))
end

@inline function _cloud_region_fraction(::Type{FT}, cloud_fraction) where FT
    return clamp(FT(cloud_fraction), zero(FT), one(FT))
end

function _v_overlap_matrix_alpha!(v::AbstractMatrix{FT},
                                  alpha,
                                  upper_clear,
                                  upper_cloud,
                                  lower_clear,
                                  lower_cloud) where FT
    overlap = clamp(FT(alpha), zero(FT), one(FT))
    pair_cloud_cover = overlap * max(upper_cloud, lower_cloud) +
        (one(FT) - overlap) *
        (upper_cloud + lower_cloud - upper_cloud * lower_cloud)
    overlap11 = one(FT) - pair_cloud_cover
    overlap12 = pair_cloud_cover - upper_cloud
    overlap21 = pair_cloud_cover - lower_cloud
    overlap22 = upper_cloud + lower_cloud - pair_cloud_cover

    if upper_clear > sqrt(eps(FT))
        v[1, 1] = overlap11 / upper_clear
        v[2, 1] = overlap12 / upper_clear
    else
        v[1, 1] = zero(FT)
        v[2, 1] = zero(FT)
    end
    if upper_cloud > sqrt(eps(FT))
        v[1, 2] = overlap21 / upper_cloud
        v[2, 2] = overlap22 / upper_cloud
    else
        v[1, 2] = zero(FT)
        v[2, 2] = zero(FT)
    end
    return v
end

function _v_overlap_matrix_maximum!(v::AbstractMatrix{FT},
                                    upper_clear,
                                    upper_cloud,
                                    lower_clear,
                                    lower_cloud) where FT
    return _v_overlap_matrix_alpha!(v, one(FT), upper_clear, upper_cloud,
                                    lower_clear, lower_cloud)
end

@inline function _matrix_overlap_parameter(solver::CloudOverlapShortwave,
                                           optics,
                                           interface_index,
                                           ::Type{FT}) where FT
    solver.overlap in (:matrix_alpha, :tripleclouds_alpha) || return one(FT)
    if interface_index < 1 || interface_index > length(optics.overlap_parameter)
        return one(FT)
    end
    return clamp(FT(optics.overlap_parameter[interface_index]), zero(FT), one(FT))
end

@inline function _sw_layer_reflectance_transmittance(::Type{FT}, optics, ig, k, μ0,
                                                     direct_source_limit = Val(:unit)) where FT
    absorption_tau = max(FT(_sw_tau(optics, ig, k)), zero(FT))
    scattering_tau = max(FT(_sw_rayleigh_tau(optics, ig, k)), zero(FT))
    total_tau = absorption_tau + scattering_tau
    ssa = total_tau == zero(FT) ? zero(FT) : scattering_tau / total_tau
    asymmetry = clamp(FT(_sw_scattering_asymmetry(optics, ig, k)), -one(FT), one(FT))
    return _sw_two_stream_layer(FT, μ0, total_tau, ssa, asymmetry, direct_source_limit)
end

@inline function _sw_layer_reflectance_transmittance_scaled(::Type{FT},
                                                            clear,
                                                            cloudy,
                                                            scale,
                                                            ig,
                                                            k,
                                                            μ0,
                                                            direct_source_limit = Val(:unit)) where FT
    clear_absorption = max(FT(_sw_tau(clear, ig, k)), zero(FT))
    cloudy_absorption = max(FT(_sw_tau(cloudy, ig, k)), zero(FT))
    clear_scattering = max(FT(_sw_rayleigh_tau(clear, ig, k)), zero(FT))
    cloudy_scattering = max(FT(_sw_rayleigh_tau(cloudy, ig, k)), zero(FT))
    clear_g = clamp(FT(_sw_scattering_asymmetry(clear, ig, k)), -one(FT), one(FT))
    cloudy_g = clamp(FT(_sw_scattering_asymmetry(cloudy, ig, k)), -one(FT), one(FT))
    factor = max(FT(scale), zero(FT))

    absorption_tau =
        max(clear_absorption + factor * (cloudy_absorption - clear_absorption),
            zero(FT))
    scattering_tau =
        max(clear_scattering + factor * (cloudy_scattering - clear_scattering),
            zero(FT))
    scattering_moment =
        clear_scattering * clear_g +
        factor * (cloudy_scattering * cloudy_g - clear_scattering * clear_g)
    asymmetry = scattering_tau == zero(FT) ? zero(FT) :
        clamp(scattering_moment / scattering_tau, -one(FT), one(FT))
    total_tau = absorption_tau + scattering_tau
    ssa = total_tau == zero(FT) ? zero(FT) : scattering_tau / total_tau
    return _sw_two_stream_layer(FT, μ0, total_tau, ssa, asymmetry, direct_source_limit)
end

@inline function _gamma_tripleclouds_regions(::Type{FT}, cloud_fraction, fractional_std) where FT
    cf = clamp(FT(cloud_fraction), zero(FT), one(FT))
    fsd = max(FT(fractional_std), zero(FT))
    cf <= sqrt(eps(FT)) && return (one(FT), zero(FT), zero(FT), one(FT), one(FT))

    min_lower_frac = FT(0.5)
    max_lower_frac = FT(0.9)
    fsd_at_min = FT(1.5)
    fsd_at_max = FT(3.725)
    gradient = (max_lower_frac - min_lower_frac) / (fsd_at_max - fsd_at_min)
    intercept = min_lower_frac - fsd_at_min * gradient
    lower_cloud_fraction =
        clamp(intercept + fsd * gradient, min_lower_frac, max_lower_frac)
    thin_fraction = cf * lower_cloud_fraction
    thick_fraction = max(cf - thin_fraction, zero(FT))

    min_gamma_scaling = FT(0.025)
    thin_scaling = min_gamma_scaling + (one(FT) - min_gamma_scaling) *
        exp(-fsd * (one(FT) + FT(0.5) * fsd * (one(FT) + FT(0.5) * fsd)))
    thick_scaling = thick_fraction <= sqrt(eps(FT)) ? one(FT) :
        max((cf - thin_fraction * thin_scaling) / thick_fraction, zero(FT))
    return (one(FT) - cf, thin_fraction, thick_fraction,
            thin_scaling, thick_scaling)
end

function _v_overlap_matrix_tripleclouds_alpha!(v::AbstractMatrix{FT},
                                               alpha,
                                               inhomogeneity_exponent,
                                               upper_frac::AbstractVector{FT},
                                               lower_frac::AbstractVector{FT}) where FT
    fill!(v, zero(FT))
    cloud_v = zeros(FT, 2, 2)
    upper_clear = upper_frac[1]
    upper_cloud = upper_frac[2] + upper_frac[3]
    lower_cloud = lower_frac[2] + lower_frac[3]
    overlap = clamp(FT(alpha), zero(FT), one(FT))
    pair_cloud_cover = overlap * max(upper_cloud, lower_cloud) +
        (one(FT) - overlap) *
        (upper_cloud + lower_cloud - upper_cloud * lower_cloud)
    overlap11 = one(FT) - pair_cloud_cover
    overlap12 = pair_cloud_cover - upper_cloud
    overlap21 = pair_cloud_cover - lower_cloud
    overlap22 = upper_cloud + lower_cloud - pair_cloud_cover

    if upper_clear > sqrt(eps(FT))
        v[1, 1] = overlap11 / upper_clear
        if lower_cloud > sqrt(eps(FT))
            cloudy_from_clear = overlap12 / upper_clear
            v[2, 1] = cloudy_from_clear * lower_frac[2] / lower_cloud
            v[3, 1] = cloudy_from_clear * lower_frac[3] / lower_cloud
        end
    end

    inhom_alpha = overlap^max(FT(inhomogeneity_exponent), zero(FT))
    upper_thin = upper_cloud > sqrt(eps(FT)) ? upper_frac[2] / upper_cloud : zero(FT)
    upper_thick = upper_cloud > sqrt(eps(FT)) ? upper_frac[3] / upper_cloud : zero(FT)
    lower_thin = lower_cloud > sqrt(eps(FT)) ? lower_frac[2] / lower_cloud : zero(FT)
    lower_thick = lower_cloud > sqrt(eps(FT)) ? lower_frac[3] / lower_cloud : zero(FT)
    _v_overlap_matrix_alpha!(cloud_v, inhom_alpha,
                             upper_thin, upper_thick,
                             lower_thin, lower_thick)
    for upper in 2:3
        upper_mass = upper == 2 ? upper_frac[2] : upper_frac[3]
        upper_mass <= sqrt(eps(FT)) && continue
        v[1, upper] = overlap21 / upper_cloud
        cloudy_weight = overlap22 / upper_cloud
        for lower in 2:3
            v[lower, upper] = cloudy_weight * cloud_v[lower - 1, upper - 1]
        end
    end
    return v
end

function _tripleclouds_shortwave_column!(up::AbstractVector{FT},
                                         down::AbstractVector{FT},
                                         solver::CloudOverlapShortwave,
                                         optics::ShortwaveCloudOverlapOpticalProperties,
                                         ig,
                                         μ0,
                                         incoming_horizontal,
                                         surface_albedo,
                                         surface_albedo_direct = surface_albedo) where FT
    nlayers = _sw_nlayers(optics.clear)
    incoming_normal = incoming_horizontal / μ0
    exponent = max(FT(solver.cloud_fraction_exponent), zero(FT))

    region_frac = Matrix{FT}(undef, 3, nlayers)
    thin_scaling = Vector{FT}(undef, nlayers)
    thick_scaling = Vector{FT}(undef, nlayers)
    for k in 1:nlayers
        cf = clamp(FT(optics.cloud_fraction[k]), zero(FT), one(FT))^exponent
        region_frac[1, k], region_frac[2, k], region_frac[3, k],
            thin_scaling[k], thick_scaling[k] =
            _gamma_tripleclouds_regions(FT, cf, optics.fractional_std[k])
    end

    reflectance = Matrix{FT}(undef, 3, nlayers)
    transmittance = Matrix{FT}(undef, 3, nlayers)
    ref_dir = Matrix{FT}(undef, 3, nlayers)
    trans_dir_diff = Matrix{FT}(undef, 3, nlayers)
    trans_dir_dir = Matrix{FT}(undef, 3, nlayers)
    for k in 1:nlayers
        reflectance[1, k], transmittance[1, k], ref_dir[1, k],
            trans_dir_diff[1, k], trans_dir_dir[1, k] =
            _sw_layer_reflectance_transmittance(FT, optics.clear, ig, k, μ0)
        reflectance[2, k], transmittance[2, k], ref_dir[2, k],
            trans_dir_diff[2, k], trans_dir_dir[2, k] =
            _sw_layer_reflectance_transmittance_scaled(
                FT, optics.clear, optics.cloudy, thin_scaling[k], ig, k, μ0)
        reflectance[3, k], transmittance[3, k], ref_dir[3, k],
            trans_dir_diff[3, k], trans_dir_dir[3, k] =
            _sw_layer_reflectance_transmittance_scaled(
                FT, optics.clear, optics.cloudy, thick_scaling[k], ig, k, μ0)
    end

    total_albedo = zeros(FT, 3, nlayers + 1)
    total_albedo_direct = zeros(FT, 3, nlayers + 1)
    total_albedo[:, nlayers + 1] .= surface_albedo
    total_albedo_direct[:, nlayers + 1] .= μ0 * surface_albedo_direct
    v = zeros(FT, 3, 3)
    below = zeros(FT, 3)
    below_direct = zeros(FT, 3)

    for k in nlayers:-1:1
        for region in 1:3
            denom = inv(one(FT) - total_albedo[region, k + 1] *
                        reflectance[region, k])
            below[region] = reflectance[region, k] +
                transmittance[region, k]^2 * total_albedo[region, k + 1] *
                denom
            below_direct[region] = ref_dir[region, k] +
                (trans_dir_dir[region, k] * total_albedo_direct[region, k + 1] +
                 trans_dir_diff[region, k] * total_albedo[region, k + 1]) *
                transmittance[region, k] * denom
        end

        upper = k == 1 ? FT[one(FT), zero(FT), zero(FT)] : region_frac[:, k - 1]
        lower = region_frac[:, k]
        _v_overlap_matrix_tripleclouds_alpha!(
            v, _matrix_overlap_parameter(solver, optics, k - 1, FT),
            solver.inhomogeneity_overlap_exponent, upper, lower)
        for upper_region in 1:3
            total_albedo[upper_region, k] = zero(FT)
            total_albedo_direct[upper_region, k] = zero(FT)
            for lower_region in 1:3
                total_albedo[upper_region, k] +=
                    below[lower_region] * v[lower_region, upper_region]
                total_albedo_direct[upper_region, k] +=
                    below_direct[lower_region] * v[lower_region, upper_region]
            end
        end
    end

    flux_dn = zeros(FT, 3)
    direct_dn = zeros(FT, 3)
    flux_up = zeros(FT, 3)
    for region in 1:3
        direct_dn[region] = incoming_normal * region_frac[region, 1]
        flux_up[region] =
            direct_dn[region] * total_albedo_direct[region, 1]
    end
    up[1] += sum(flux_up)
    down[1] += μ0 * sum(direct_dn)

    next_flux_dn = zeros(FT, 3)
    next_direct_dn = zeros(FT, 3)
    for k in 1:nlayers
        for region in 1:3
            denom = inv(one(FT) - reflectance[region, k] *
                        total_albedo[region, k + 1])
            flux_dn[region] =
                (transmittance[region, k] * flux_dn[region] +
                 direct_dn[region] *
                 (trans_dir_dir[region, k] *
                  total_albedo_direct[region, k + 1] *
                  reflectance[region, k] +
                  trans_dir_diff[region, k])) * denom
            direct_dn[region] = trans_dir_dir[region, k] * direct_dn[region]
            flux_up[region] =
                direct_dn[region] * total_albedo_direct[region, k + 1] +
                flux_dn[region] * total_albedo[region, k + 1]
        end

        if k < nlayers
            _v_overlap_matrix_tripleclouds_alpha!(
                v, _matrix_overlap_parameter(solver, optics, k, FT),
                solver.inhomogeneity_overlap_exponent,
                region_frac[:, k], region_frac[:, k + 1])
            fill!(next_flux_dn, zero(FT))
            fill!(next_direct_dn, zero(FT))
            for upper in 1:3, lower in 1:3
                next_flux_dn[lower] += v[lower, upper] * flux_dn[upper]
                next_direct_dn[lower] += v[lower, upper] * direct_dn[upper]
            end
            flux_dn .= next_flux_dn
            direct_dn .= next_direct_dn
        end

        up[k + 1] += sum(flux_up)
        down[k + 1] += μ0 * sum(direct_dn) + sum(flux_dn)
    end
    return nothing
end

function _adding_shortwave_column!(up::AbstractVector{FT},
                                   down::AbstractVector{FT},
                                   solver::CloudOverlapShortwave,
                                   optics::ShortwaveCloudOverlapOpticalProperties,
                                   ig,
                                   μ0,
                                   incoming_horizontal,
                                   surface_albedo,
                                   surface_albedo_direct = surface_albedo) where FT
    nlayers = _sw_nlayers(optics.clear)
    incoming_normal = incoming_horizontal / μ0

    reflectance = Vector{FT}(undef, nlayers)
    transmittance = Vector{FT}(undef, nlayers)
    ref_dir = Vector{FT}(undef, nlayers)
    trans_dir_diff = Vector{FT}(undef, nlayers)
    trans_dir_dir = Vector{FT}(undef, nlayers)
    exponent = max(FT(solver.cloud_fraction_exponent), zero(FT))

    for k in 1:nlayers
        clear_r, clear_t, clear_ref_dir, clear_trans_diff, clear_trans_dir =
            _sw_layer_reflectance_transmittance(FT, optics.clear, ig, k, μ0)
        cloudy_r, cloudy_t, cloudy_ref_dir, cloudy_trans_diff, cloudy_trans_dir =
            _sw_layer_reflectance_transmittance(FT, optics.cloudy, ig, k, μ0)
        cloud_weight = clamp(FT(optics.cloud_fraction[k]), zero(FT), one(FT))^exponent
        clear_weight = one(FT) - cloud_weight
        reflectance[k] = clear_weight * clear_r + cloud_weight * cloudy_r
        transmittance[k] = clear_weight * clear_t + cloud_weight * cloudy_t
        ref_dir[k] = clear_weight * clear_ref_dir + cloud_weight * cloudy_ref_dir
        trans_dir_diff[k] =
            clear_weight * clear_trans_diff + cloud_weight * cloudy_trans_diff
        trans_dir_dir[k] =
            clear_weight * clear_trans_dir + cloud_weight * cloudy_trans_dir
    end

    flux_direct = Vector{FT}(undef, nlayers + 1)
    flux_diffuse = Vector{FT}(undef, nlayers + 1)
    source = Vector{FT}(undef, nlayers + 1)
    stack_albedo = Vector{FT}(undef, nlayers + 1)
    inv_denominator = Vector{FT}(undef, nlayers)

    flux_direct[1] = incoming_normal
    for k in 1:nlayers
        flux_direct[k + 1] = flux_direct[k] * trans_dir_dir[k]
    end

    stack_albedo[nlayers + 1] = surface_albedo
    source[nlayers + 1] = surface_albedo_direct * flux_direct[nlayers + 1] * μ0
    for k in nlayers:-1:1
        below = stack_albedo[k + 1]
        inv_denominator[k] = inv(one(FT) - below * reflectance[k])
        stack_albedo[k] = reflectance[k] +
            transmittance[k] * transmittance[k] * below * inv_denominator[k]
        source[k] = ref_dir[k] * flux_direct[k] +
            transmittance[k] *
            (source[k + 1] + below * trans_dir_diff[k] * flux_direct[k]) *
            inv_denominator[k]
    end

    flux_diffuse[1] = zero(FT)
    up[1] += source[1]
    down[1] += flux_direct[1] * μ0
    for k in 1:nlayers
        flux_diffuse[k + 1] =
            (transmittance[k] * flux_diffuse[k] +
             reflectance[k] * source[k + 1] +
             trans_dir_diff[k] * flux_direct[k]) * inv_denominator[k]
        up[k + 1] += stack_albedo[k + 1] * flux_diffuse[k + 1] + source[k + 1]
        down[k + 1] += flux_diffuse[k + 1] + flux_direct[k + 1] * μ0
    end
    return nothing
end

function _matrix_maximum_shortwave_column!(up::AbstractVector{FT},
                                           down::AbstractVector{FT},
                                           solver::CloudOverlapShortwave,
                                           optics::ShortwaveCloudOverlapOpticalProperties,
                                           ig,
                                           μ0,
                                           incoming_horizontal,
                                           surface_albedo,
                                           surface_albedo_direct = surface_albedo) where FT
    nlayers = _sw_nlayers(optics.clear)
    incoming_normal = incoming_horizontal / μ0
    exponent = max(FT(solver.cloud_fraction_exponent), zero(FT))

    cf = [clamp(FT(optics.cloud_fraction[k]), zero(FT), one(FT))^exponent
          for k in 1:nlayers]
    region_frac = Matrix{FT}(undef, 2, nlayers)
    for k in 1:nlayers
        region_frac[1, k] = one(FT) - cf[k]
        region_frac[2, k] = cf[k]
    end

    reflectance = Matrix{FT}(undef, 2, nlayers)
    transmittance = Matrix{FT}(undef, 2, nlayers)
    ref_dir = Matrix{FT}(undef, 2, nlayers)
    trans_dir_diff = Matrix{FT}(undef, 2, nlayers)
    trans_dir_dir = Matrix{FT}(undef, 2, nlayers)
    for k in 1:nlayers
        reflectance[1, k], transmittance[1, k], ref_dir[1, k],
            trans_dir_diff[1, k], trans_dir_dir[1, k] =
            _sw_layer_reflectance_transmittance(FT, optics.clear, ig, k, μ0)
        reflectance[2, k], transmittance[2, k], ref_dir[2, k],
            trans_dir_diff[2, k], trans_dir_dir[2, k] =
            _sw_layer_reflectance_transmittance(FT, optics.cloudy, ig, k, μ0)
    end

    total_albedo = zeros(FT, 2, nlayers + 1)
    total_albedo_direct = zeros(FT, 2, nlayers + 1)
    total_albedo[:, nlayers + 1] .= surface_albedo
    total_albedo_direct[:, nlayers + 1] .= μ0 * surface_albedo_direct
    v = zeros(FT, 2, 2)
    below = zeros(FT, 2)
    below_direct = zeros(FT, 2)

    for k in nlayers:-1:1
        for region in 1:2
            denom = inv(one(FT) - total_albedo[region, k + 1] *
                        reflectance[region, k])
            below[region] = reflectance[region, k] +
                transmittance[region, k]^2 * total_albedo[region, k + 1] *
                denom
            below_direct[region] = ref_dir[region, k] +
                (trans_dir_dir[region, k] * total_albedo_direct[region, k + 1] +
                 trans_dir_diff[region, k] * total_albedo[region, k + 1]) *
                transmittance[region, k] * denom
        end

        upper_clear = k == 1 ? one(FT) : region_frac[1, k - 1]
        upper_cloud = k == 1 ? zero(FT) : region_frac[2, k - 1]
        lower_clear = region_frac[1, k]
        lower_cloud = region_frac[2, k]
        _v_overlap_matrix_alpha!(v,
                                 _matrix_overlap_parameter(solver, optics, k - 1, FT),
                                 upper_clear, upper_cloud,
                                 lower_clear, lower_cloud)
        for upper in 1:2
            total_albedo[upper, k] = zero(FT)
            total_albedo_direct[upper, k] = zero(FT)
            for lower in 1:2
                total_albedo[upper, k] += below[lower] * v[lower, upper]
                total_albedo_direct[upper, k] += below_direct[lower] * v[lower, upper]
            end
        end
    end

    flux_dn = zeros(FT, 2)
    direct_dn = zeros(FT, 2)
    flux_up = zeros(FT, 2)
    direct_dn[1] = incoming_normal * region_frac[1, 1]
    direct_dn[2] = incoming_normal * region_frac[2, 1]
    for region in 1:2
        flux_up[region] =
            direct_dn[region] * total_albedo_direct[region, 1]
    end
    up[1] += sum(flux_up)
    down[1] += μ0 * sum(direct_dn)

    next_flux_dn = zeros(FT, 2)
    next_direct_dn = zeros(FT, 2)
    for k in 1:nlayers
        for region in 1:2
            denom = inv(one(FT) - reflectance[region, k] *
                        total_albedo[region, k + 1])
            flux_dn[region] =
                (transmittance[region, k] * flux_dn[region] +
                 direct_dn[region] *
                 (trans_dir_dir[region, k] *
                  total_albedo_direct[region, k + 1] *
                  reflectance[region, k] +
                  trans_dir_diff[region, k])) * denom
            direct_dn[region] = trans_dir_dir[region, k] * direct_dn[region]
            flux_up[region] =
                direct_dn[region] * total_albedo_direct[region, k + 1] +
                flux_dn[region] * total_albedo[region, k + 1]
        end

        if k < nlayers
            _v_overlap_matrix_alpha!(v,
                                     _matrix_overlap_parameter(solver, optics, k, FT),
                                     region_frac[1, k], region_frac[2, k],
                                     region_frac[1, k + 1],
                                     region_frac[2, k + 1])
            fill!(next_flux_dn, zero(FT))
            fill!(next_direct_dn, zero(FT))
            for upper in 1:2, lower in 1:2
                next_flux_dn[lower] += v[lower, upper] * flux_dn[upper]
                next_direct_dn[lower] += v[lower, upper] * direct_dn[upper]
            end
            flux_dn .= next_flux_dn
            direct_dn .= next_direct_dn
        end

        up[k + 1] += sum(flux_up)
        down[k + 1] += μ0 * sum(direct_dn) + sum(flux_dn)
    end
    return nothing
end

@inline function _interface_cloud_fraction(solver::CloudOverlapShortwave{FT},
                                           cloud_fraction,
                                           interface_index,
                                           nlayers) where FT
    exponent = max(solver.cloud_fraction_exponent, zero(FT))
    if interface_index == 1
        fraction = FT(cloud_fraction[1])
    elseif interface_index == nlayers + 1
        fraction = FT(cloud_fraction[nlayers])
    elseif solver.overlap == :average
        fraction = (FT(cloud_fraction[interface_index - 1]) +
                    FT(cloud_fraction[interface_index])) / FT(2)
    else
        fraction = max(FT(cloud_fraction[interface_index - 1]),
                       FT(cloud_fraction[interface_index]))
    end
    return clamp(fraction, zero(FT), one(FT))^exponent
end

"""
    radiative_fluxes!(fluxes, CloudOverlapShortwave(), optics, atmosphere, boundary_conditions)

Compute clear and cloudy shortwave fluxes independently and blend the results
with an explicit cloud-fraction overlap rule.
"""
function radiative_fluxes!(fluxes::RadiativeFluxes,
                           solver::CloudOverlapShortwave,
                           optics::ShortwaveCloudOverlapOpticalProperties{FT},
                           atmosphere,
                           boundary_conditions::ShortwaveBoundaryConditions{FT}) where FT
    nlayers = _sw_nlayers(optics.clear)
    if boundary_conditions.surface_albedo isa AbstractArray
        length(boundary_conditions.surface_albedo) == _sw_ng(optics.clear) ||
            throw(DimensionMismatch("surface_albedo vector must have length ng"))
    end
    if boundary_conditions.surface_albedo_direct isa AbstractArray
        length(boundary_conditions.surface_albedo_direct) == _sw_ng(optics.clear) ||
            throw(DimensionMismatch("surface_albedo_direct vector must have length ng"))
    end
    if solver.overlap in (:adding, :matrix_maximum, :matrix_alpha,
                          :tripleclouds_alpha)
        fluxes.shortwave_up .= zero(FT)
        fluxes.shortwave_down .= zero(FT)
        for ig in 1:_sw_ng(optics.clear)
            scratch_up = zeros(FT, nlayers + 1)
            scratch_down = zeros(FT, nlayers + 1)
            path_factor = _sw_path_factor(FT, atmosphere)
            μ0 = inv(path_factor)
            if solver.overlap == :tripleclouds_alpha
                _tripleclouds_shortwave_column!(
                    scratch_up,
                    scratch_down,
                    solver,
                    optics,
                    ig,
                    μ0,
                    boundary_conditions.toa_shortwave_down,
                    _surface_albedo(boundary_conditions, ig),
                    _surface_albedo_direct(boundary_conditions, ig),
                )
            elseif solver.overlap in (:matrix_maximum, :matrix_alpha)
                _matrix_maximum_shortwave_column!(
                    scratch_up,
                    scratch_down,
                    solver,
                    optics,
                    ig,
                    μ0,
                    boundary_conditions.toa_shortwave_down,
                    _surface_albedo(boundary_conditions, ig),
                    _surface_albedo_direct(boundary_conditions, ig),
                )
            else
                _adding_shortwave_column!(
                    scratch_up,
                    scratch_down,
                    solver,
                    optics,
                    ig,
                    μ0,
                    boundary_conditions.toa_shortwave_down,
                    _surface_albedo(boundary_conditions, ig),
                    _surface_albedo_direct(boundary_conditions, ig),
                )
            end
            w = FT(optics.clear.weights[ig])
            fluxes.shortwave_up .+= w .* scratch_up
            fluxes.shortwave_down .+= w .* scratch_down
        end
        return fluxes
    end

    clear_fluxes = RadiativeFluxes(
        longwave_up = similar(fluxes.longwave_up),
        longwave_down = similar(fluxes.longwave_down),
        shortwave_up = similar(fluxes.shortwave_up),
        shortwave_down = similar(fluxes.shortwave_down),
    )
    cloudy_fluxes = RadiativeFluxes(
        longwave_up = similar(fluxes.longwave_up),
        longwave_down = similar(fluxes.longwave_down),
        shortwave_up = similar(fluxes.shortwave_up),
        shortwave_down = similar(fluxes.shortwave_down),
    )

    radiative_fluxes!(clear_fluxes, solver.clear_solver, optics.clear,
                      atmosphere, boundary_conditions)
    radiative_fluxes!(cloudy_fluxes, solver.clear_solver, optics.cloudy,
                      atmosphere, boundary_conditions)

    fluxes.shortwave_up .= zero(FT)
    fluxes.shortwave_down .= zero(FT)
    for i in 1:(nlayers + 1)
        fraction = _interface_cloud_fraction(solver, optics.cloud_fraction, i, nlayers)
        clear_weight = one(FT) - fraction
        fluxes.shortwave_up[i] =
            clear_weight * clear_fluxes.shortwave_up[i] +
            fraction * cloudy_fluxes.shortwave_up[i]
        fluxes.shortwave_down[i] =
            clear_weight * clear_fluxes.shortwave_down[i] +
            fraction * cloudy_fluxes.shortwave_down[i]
    end
    return fluxes
end
