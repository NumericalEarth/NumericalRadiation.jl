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
struct ShortwaveCloudOverlapOptics{FT, S, F, O, D}
    "Clear-region shortwave optical properties."
    clear::S
    "Cloudy-region shortwave optical properties."
    cloudy::S
    "Layer cloud fraction."
    cloud_fraction::F
    "Interface overlap parameter between adjacent cloudy layers."
    overlap_parameter::O
    "Layer fractional standard deviation of in-cloud condensate."
    fractional_standard_deviation::D
end

function ShortwaveCloudOverlapOptics(clear::ShortwaveOptics{FT},
                                                cloudy::ShortwaveOptics{FT},
                                                cloud_fraction::AbstractVector{FT};
                                                overlap_parameter = nothing,
                                                fractional_standard_deviation = nothing) where FT
    number_of_layers(clear) == number_of_layers(cloudy) ||
        throw(DimensionMismatch("clear and cloudy shortwave optics must have the same number of layers"))
    number_of_gpoints(clear) == number_of_gpoints(cloudy) ||
        throw(DimensionMismatch("clear and cloudy shortwave optics must have the same number of g-points"))
    length(cloud_fraction) == number_of_layers(clear) ||
        throw(DimensionMismatch("cloud_fraction must have one value per layer"))
    overlap = overlap_parameter === nothing ?
        fill(one(FT), max(number_of_layers(clear) - 1, 0)) :
        FT.(overlap_parameter)
    length(overlap) == max(number_of_layers(clear) - 1, 0) ||
        throw(DimensionMismatch("overlap_parameter must have one value between each adjacent layer"))
    fractional_standard_deviation = fractional_standard_deviation === nothing ?
        fill(one(FT), number_of_layers(clear)) :
        FT.(fractional_standard_deviation)
    length(fractional_standard_deviation) == number_of_layers(clear) ||
        throw(DimensionMismatch("fractional_standard_deviation must have one value per layer"))
    return ShortwaveCloudOverlapOptics{FT, typeof(clear),
                                                  typeof(cloud_fraction),
                                                  typeof(overlap),
                                                  typeof(fractional_standard_deviation)}(
        clear,
        cloudy,
        cloud_fraction,
        overlap,
        fractional_standard_deviation,
    )
end

Base.eltype(::ShortwaveCloudOverlapOptics{FT}) where FT = FT

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

@inline function clear_region_fraction(::Type{FT}, cloud_fraction) where FT
    return one(FT) - clamp(FT(cloud_fraction), zero(FT), one(FT))
end

@inline function cloud_region_fraction(::Type{FT}, cloud_fraction) where FT
    return clamp(FT(cloud_fraction), zero(FT), one(FT))
end

function v_overlap_matrix_alpha!(v::AbstractMatrix{FT},
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

function v_overlap_matrix_maximum!(v::AbstractMatrix{FT},
                                    upper_clear,
                                    upper_cloud,
                                    lower_clear,
                                    lower_cloud) where FT
    return v_overlap_matrix_alpha!(v, one(FT), upper_clear, upper_cloud,
                                    lower_clear, lower_cloud)
end

@inline function matrix_overlap_parameter(solver::CloudOverlapShortwave,
                                           optics,
                                           interface_index,
                                           ::Type{FT}) where FT
    solver.overlap in (:matrix_alpha, :tripleclouds_alpha) || return one(FT)
    if interface_index < 1 || interface_index > length(optics.overlap_parameter)
        return one(FT)
    end
    return clamp(FT(optics.overlap_parameter[interface_index]), zero(FT), one(FT))
end

@inline function shortwave_layer_reflectance_transmittance(::Type{FT}, optics, gpoint, k, μ₀,
                                                     direct_source_limit = Val(:unit)) where FT
    τ_absorption = max(FT(optical_depth_at(optics, gpoint, k)), zero(FT))
    τ_scattering = max(FT(rayleigh_optical_depth_at(optics, gpoint, k)), zero(FT))
    τ_total = τ_absorption + τ_scattering
    ω = τ_total == zero(FT) ? zero(FT) : τ_scattering / τ_total
    asymmetry = clamp(FT(scattering_asymmetry_at(optics, gpoint, k)), -one(FT), one(FT))
    return shortwave_two_stream_layer(FT, μ₀, τ_total, ω, asymmetry, direct_source_limit)
end

@inline function shortwave_layer_reflectance_transmittance_scaled(::Type{FT},
                                                            clear,
                                                            cloudy,
                                                            scale,
                                                            gpoint,
                                                            k,
                                                            μ₀,
                                                            direct_source_limit = Val(:unit)) where FT
    clear_absorption = max(FT(optical_depth_at(clear, gpoint, k)), zero(FT))
    cloudy_absorption = max(FT(optical_depth_at(cloudy, gpoint, k)), zero(FT))
    clear_scattering = max(FT(rayleigh_optical_depth_at(clear, gpoint, k)), zero(FT))
    cloudy_scattering = max(FT(rayleigh_optical_depth_at(cloudy, gpoint, k)), zero(FT))
    g_clear = clamp(FT(scattering_asymmetry_at(clear, gpoint, k)), -one(FT), one(FT))
    g_cloudy = clamp(FT(scattering_asymmetry_at(cloudy, gpoint, k)), -one(FT), one(FT))
    factor = max(FT(scale), zero(FT))

    τ_absorption =
        max(clear_absorption + factor * (cloudy_absorption - clear_absorption),
            zero(FT))
    τ_scattering =
        max(clear_scattering + factor * (cloudy_scattering - clear_scattering),
            zero(FT))
    scattering_moment =
        clear_scattering * g_clear +
        factor * (cloudy_scattering * g_cloudy - clear_scattering * g_clear)
    asymmetry = τ_scattering == zero(FT) ? zero(FT) :
        clamp(scattering_moment / τ_scattering, -one(FT), one(FT))
    τ_total = τ_absorption + τ_scattering
    ω = τ_total == zero(FT) ? zero(FT) : τ_scattering / τ_total
    return shortwave_two_stream_layer(FT, μ₀, τ_total, ω, asymmetry, direct_source_limit)
end

@inline function gamma_tripleclouds_regions(::Type{FT}, cloud_fraction, fractional_standard_deviation) where FT
    cloud_fraction = clamp(FT(cloud_fraction), zero(FT), one(FT))
    fractional_standard_deviation = max(FT(fractional_standard_deviation), zero(FT))
    cloud_fraction <= sqrt(eps(FT)) && return (one(FT), zero(FT), zero(FT), one(FT), one(FT))

    minimum_lower_fraction = FT(0.5)
    maximum_lower_fraction = FT(0.9)
    fractional_standard_deviation_at_minimum = FT(1.5)
    fractional_standard_deviation_at_maximum = FT(3.725)
    gradient = (maximum_lower_fraction - minimum_lower_fraction) / (fractional_standard_deviation_at_maximum - fractional_standard_deviation_at_minimum)
    intercept = minimum_lower_fraction - fractional_standard_deviation_at_minimum * gradient
    lower_cloud_fraction =
        clamp(intercept + fractional_standard_deviation * gradient, minimum_lower_fraction, maximum_lower_fraction)
    thin_fraction = cloud_fraction * lower_cloud_fraction
    thick_fraction = max(cloud_fraction - thin_fraction, zero(FT))

    min_gamma_scaling = FT(0.025)
    thin_scaling = min_gamma_scaling + (one(FT) - min_gamma_scaling) *
        exp(-fractional_standard_deviation * (one(FT) + FT(0.5) * fractional_standard_deviation * (one(FT) + FT(0.5) * fractional_standard_deviation)))
    thick_scaling = thick_fraction <= sqrt(eps(FT)) ? one(FT) :
        max((cloud_fraction - thin_fraction * thin_scaling) / thick_fraction, zero(FT))
    return (one(FT) - cloud_fraction, thin_fraction, thick_fraction,
            thin_scaling, thick_scaling)
end

function v_overlap_matrix_tripleclouds_alpha!(v::AbstractMatrix{FT},
                                               alpha,
                                               inhomogeneity_exponent,
                                               upper_fraction::AbstractVector{FT},
                                               lower_fraction::AbstractVector{FT}) where FT
    fill!(v, zero(FT))
    cloud_v = zeros(FT, 2, 2)
    upper_clear = upper_fraction[1]
    upper_cloud = upper_fraction[2] + upper_fraction[3]
    lower_cloud = lower_fraction[2] + lower_fraction[3]
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
            v[2, 1] = cloudy_from_clear * lower_fraction[2] / lower_cloud
            v[3, 1] = cloudy_from_clear * lower_fraction[3] / lower_cloud
        end
    end

    inhom_alpha = overlap^max(FT(inhomogeneity_exponent), zero(FT))
    upper_thin = upper_cloud > sqrt(eps(FT)) ? upper_fraction[2] / upper_cloud : zero(FT)
    upper_thick = upper_cloud > sqrt(eps(FT)) ? upper_fraction[3] / upper_cloud : zero(FT)
    lower_thin = lower_cloud > sqrt(eps(FT)) ? lower_fraction[2] / lower_cloud : zero(FT)
    lower_thick = lower_cloud > sqrt(eps(FT)) ? lower_fraction[3] / lower_cloud : zero(FT)
    v_overlap_matrix_alpha!(cloud_v, inhom_alpha,
                             upper_thin, upper_thick,
                             lower_thin, lower_thick)
    for upper in 2:3
        upper_mass = upper == 2 ? upper_fraction[2] : upper_fraction[3]
        upper_mass <= sqrt(eps(FT)) && continue
        v[1, upper] = overlap21 / upper_cloud
        cloudy_weight = overlap22 / upper_cloud
        for lower in 2:3
            v[lower, upper] = cloudy_weight * cloud_v[lower - 1, upper - 1]
        end
    end
    return v
end

function tripleclouds_shortwave_column!(up::AbstractVector{FT},
                                         down::AbstractVector{FT},
                                         solver::CloudOverlapShortwave,
                                         optics::ShortwaveCloudOverlapOptics,
                                         gpoint,
                                         μ₀,
                                         incoming_horizontal,
                                         surface_albedo,
                                         surface_albedo_direct = surface_albedo) where FT
    Nz = number_of_layers(optics.clear)
    incoming_normal = incoming_horizontal / μ₀
    exponent = max(FT(solver.cloud_fraction_exponent), zero(FT))

    region_fraction = Matrix{FT}(undef, 3, Nz)
    thin_scaling = Vector{FT}(undef, Nz)
    thick_scaling = Vector{FT}(undef, Nz)
    for k in 1:Nz
        cloud_fraction = clamp(FT(optics.cloud_fraction[k]), zero(FT), one(FT))^exponent
        region_fraction[1, k], region_fraction[2, k], region_fraction[3, k],
            thin_scaling[k], thick_scaling[k] =
            gamma_tripleclouds_regions(FT, cloud_fraction, optics.fractional_standard_deviation[k])
    end

    reflectance = Matrix{FT}(undef, 3, Nz)
    transmittance = Matrix{FT}(undef, 3, Nz)
    direct_reflectance = Matrix{FT}(undef, 3, Nz)
    direct_diffuse_transmittance = Matrix{FT}(undef, 3, Nz)
    direct_transmittance = Matrix{FT}(undef, 3, Nz)
    for k in 1:Nz
        reflectance[1, k], transmittance[1, k], direct_reflectance[1, k],
            direct_diffuse_transmittance[1, k], direct_transmittance[1, k] =
            shortwave_layer_reflectance_transmittance(FT, optics.clear, gpoint, k, μ₀)
        reflectance[2, k], transmittance[2, k], direct_reflectance[2, k],
            direct_diffuse_transmittance[2, k], direct_transmittance[2, k] =
            shortwave_layer_reflectance_transmittance_scaled(
                FT, optics.clear, optics.cloudy, thin_scaling[k], gpoint, k, μ₀)
        reflectance[3, k], transmittance[3, k], direct_reflectance[3, k],
            direct_diffuse_transmittance[3, k], direct_transmittance[3, k] =
            shortwave_layer_reflectance_transmittance_scaled(
                FT, optics.clear, optics.cloudy, thick_scaling[k], gpoint, k, μ₀)
    end

    total_albedo = zeros(FT, 3, Nz + 1)
    total_albedo_direct = zeros(FT, 3, Nz + 1)
    total_albedo[:, Nz + 1] .= surface_albedo
    total_albedo_direct[:, Nz + 1] .= μ₀ * surface_albedo_direct
    v = zeros(FT, 3, 3)
    below = zeros(FT, 3)
    below_direct = zeros(FT, 3)

    for k in Nz:-1:1
        for region in 1:3
            inverse_denominator = inv(one(FT) - total_albedo[region, k + 1] *
                        reflectance[region, k])
            below[region] = reflectance[region, k] +
                transmittance[region, k]^2 * total_albedo[region, k + 1] *
                inverse_denominator
            below_direct[region] = direct_reflectance[region, k] +
                (direct_transmittance[region, k] * total_albedo_direct[region, k + 1] +
                 direct_diffuse_transmittance[region, k] * total_albedo[region, k + 1]) *
                transmittance[region, k] * inverse_denominator
        end

        upper = k == 1 ? FT[one(FT), zero(FT), zero(FT)] : region_fraction[:, k - 1]
        lower = region_fraction[:, k]
        v_overlap_matrix_tripleclouds_alpha!(
            v, matrix_overlap_parameter(solver, optics, k - 1, FT),
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
        direct_dn[region] = incoming_normal * region_fraction[region, 1]
        flux_up[region] =
            direct_dn[region] * total_albedo_direct[region, 1]
    end
    up[1] += sum(flux_up)
    down[1] += μ₀ * sum(direct_dn)

    next_flux_dn = zeros(FT, 3)
    next_direct_dn = zeros(FT, 3)
    for k in 1:Nz
        for region in 1:3
            inverse_denominator = inv(one(FT) - reflectance[region, k] *
                        total_albedo[region, k + 1])
            flux_dn[region] =
                (transmittance[region, k] * flux_dn[region] +
                 direct_dn[region] *
                 (direct_transmittance[region, k] *
                  total_albedo_direct[region, k + 1] *
                  reflectance[region, k] +
                  direct_diffuse_transmittance[region, k])) * inverse_denominator
            direct_dn[region] = direct_transmittance[region, k] * direct_dn[region]
            flux_up[region] =
                direct_dn[region] * total_albedo_direct[region, k + 1] +
                flux_dn[region] * total_albedo[region, k + 1]
        end

        if k < Nz
            v_overlap_matrix_tripleclouds_alpha!(
                v, matrix_overlap_parameter(solver, optics, k, FT),
                solver.inhomogeneity_overlap_exponent,
                region_fraction[:, k], region_fraction[:, k + 1])
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
        down[k + 1] += μ₀ * sum(direct_dn) + sum(flux_dn)
    end
    return nothing
end

function adding_shortwave_column!(up::AbstractVector{FT},
                                   down::AbstractVector{FT},
                                   solver::CloudOverlapShortwave,
                                   optics::ShortwaveCloudOverlapOptics,
                                   gpoint,
                                   μ₀,
                                   incoming_horizontal,
                                   surface_albedo,
                                   surface_albedo_direct = surface_albedo) where FT
    Nz = number_of_layers(optics.clear)
    incoming_normal = incoming_horizontal / μ₀

    reflectance = Vector{FT}(undef, Nz)
    transmittance = Vector{FT}(undef, Nz)
    direct_reflectance = Vector{FT}(undef, Nz)
    direct_diffuse_transmittance = Vector{FT}(undef, Nz)
    direct_transmittance = Vector{FT}(undef, Nz)
    exponent = max(FT(solver.cloud_fraction_exponent), zero(FT))

    for k in 1:Nz
        clear_reflectance, clear_transmittance, clear_direct_reflectance, clear_direct_diffuse_transmittance, clear_direct_transmittance =
            shortwave_layer_reflectance_transmittance(FT, optics.clear, gpoint, k, μ₀)
        cloudy_reflectance, cloudy_transmittance, cloudy_direct_reflectance, cloudy_direct_diffuse_transmittance, cloudy_direct_transmittance =
            shortwave_layer_reflectance_transmittance(FT, optics.cloudy, gpoint, k, μ₀)
        cloud_weight = clamp(FT(optics.cloud_fraction[k]), zero(FT), one(FT))^exponent
        clear_weight = one(FT) - cloud_weight
        reflectance[k] = clear_weight * clear_reflectance + cloud_weight * cloudy_reflectance
        transmittance[k] = clear_weight * clear_transmittance + cloud_weight * cloudy_transmittance
        direct_reflectance[k] = clear_weight * clear_direct_reflectance + cloud_weight * cloudy_direct_reflectance
        direct_diffuse_transmittance[k] =
            clear_weight * clear_direct_diffuse_transmittance + cloud_weight * cloudy_direct_diffuse_transmittance
        direct_transmittance[k] =
            clear_weight * clear_direct_transmittance + cloud_weight * cloudy_direct_transmittance
    end

    flux_direct = Vector{FT}(undef, Nz + 1)
    flux_diffuse = Vector{FT}(undef, Nz + 1)
    source = Vector{FT}(undef, Nz + 1)
    stack_albedo = Vector{FT}(undef, Nz + 1)
    inv_denominator = Vector{FT}(undef, Nz)

    flux_direct[1] = incoming_normal
    for k in 1:Nz
        flux_direct[k + 1] = flux_direct[k] * direct_transmittance[k]
    end

    stack_albedo[Nz + 1] = surface_albedo
    source[Nz + 1] = surface_albedo_direct * flux_direct[Nz + 1] * μ₀
    for k in Nz:-1:1
        below = stack_albedo[k + 1]
        inv_denominator[k] = inv(one(FT) - below * reflectance[k])
        stack_albedo[k] = reflectance[k] +
            transmittance[k] * transmittance[k] * below * inv_denominator[k]
        source[k] = direct_reflectance[k] * flux_direct[k] +
            transmittance[k] *
            (source[k + 1] + below * direct_diffuse_transmittance[k] * flux_direct[k]) *
            inv_denominator[k]
    end

    flux_diffuse[1] = zero(FT)
    up[1] += source[1]
    down[1] += flux_direct[1] * μ₀
    for k in 1:Nz
        flux_diffuse[k + 1] =
            (transmittance[k] * flux_diffuse[k] +
             reflectance[k] * source[k + 1] +
             direct_diffuse_transmittance[k] * flux_direct[k]) * inv_denominator[k]
        up[k + 1] += stack_albedo[k + 1] * flux_diffuse[k + 1] + source[k + 1]
        down[k + 1] += flux_diffuse[k + 1] + flux_direct[k + 1] * μ₀
    end
    return nothing
end

function matrix_maximum_shortwave_column!(up::AbstractVector{FT},
                                           down::AbstractVector{FT},
                                           solver::CloudOverlapShortwave,
                                           optics::ShortwaveCloudOverlapOptics,
                                           gpoint,
                                           μ₀,
                                           incoming_horizontal,
                                           surface_albedo,
                                           surface_albedo_direct = surface_albedo) where FT
    Nz = number_of_layers(optics.clear)
    incoming_normal = incoming_horizontal / μ₀
    exponent = max(FT(solver.cloud_fraction_exponent), zero(FT))

    cloud_fraction = [clamp(FT(optics.cloud_fraction[k]), zero(FT), one(FT))^exponent
          for k in 1:Nz]
    region_fraction = Matrix{FT}(undef, 2, Nz)
    for k in 1:Nz
        region_fraction[1, k] = one(FT) - cloud_fraction[k]
        region_fraction[2, k] = cloud_fraction[k]
    end

    reflectance = Matrix{FT}(undef, 2, Nz)
    transmittance = Matrix{FT}(undef, 2, Nz)
    direct_reflectance = Matrix{FT}(undef, 2, Nz)
    direct_diffuse_transmittance = Matrix{FT}(undef, 2, Nz)
    direct_transmittance = Matrix{FT}(undef, 2, Nz)
    for k in 1:Nz
        reflectance[1, k], transmittance[1, k], direct_reflectance[1, k],
            direct_diffuse_transmittance[1, k], direct_transmittance[1, k] =
            shortwave_layer_reflectance_transmittance(FT, optics.clear, gpoint, k, μ₀)
        reflectance[2, k], transmittance[2, k], direct_reflectance[2, k],
            direct_diffuse_transmittance[2, k], direct_transmittance[2, k] =
            shortwave_layer_reflectance_transmittance(FT, optics.cloudy, gpoint, k, μ₀)
    end

    total_albedo = zeros(FT, 2, Nz + 1)
    total_albedo_direct = zeros(FT, 2, Nz + 1)
    total_albedo[:, Nz + 1] .= surface_albedo
    total_albedo_direct[:, Nz + 1] .= μ₀ * surface_albedo_direct
    v = zeros(FT, 2, 2)
    below = zeros(FT, 2)
    below_direct = zeros(FT, 2)

    for k in Nz:-1:1
        for region in 1:2
            inverse_denominator = inv(one(FT) - total_albedo[region, k + 1] *
                        reflectance[region, k])
            below[region] = reflectance[region, k] +
                transmittance[region, k]^2 * total_albedo[region, k + 1] *
                inverse_denominator
            below_direct[region] = direct_reflectance[region, k] +
                (direct_transmittance[region, k] * total_albedo_direct[region, k + 1] +
                 direct_diffuse_transmittance[region, k] * total_albedo[region, k + 1]) *
                transmittance[region, k] * inverse_denominator
        end

        upper_clear = k == 1 ? one(FT) : region_fraction[1, k - 1]
        upper_cloud = k == 1 ? zero(FT) : region_fraction[2, k - 1]
        lower_clear = region_fraction[1, k]
        lower_cloud = region_fraction[2, k]
        v_overlap_matrix_alpha!(v,
                                 matrix_overlap_parameter(solver, optics, k - 1, FT),
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
    direct_dn[1] = incoming_normal * region_fraction[1, 1]
    direct_dn[2] = incoming_normal * region_fraction[2, 1]
    for region in 1:2
        flux_up[region] =
            direct_dn[region] * total_albedo_direct[region, 1]
    end
    up[1] += sum(flux_up)
    down[1] += μ₀ * sum(direct_dn)

    next_flux_dn = zeros(FT, 2)
    next_direct_dn = zeros(FT, 2)
    for k in 1:Nz
        for region in 1:2
            inverse_denominator = inv(one(FT) - reflectance[region, k] *
                        total_albedo[region, k + 1])
            flux_dn[region] =
                (transmittance[region, k] * flux_dn[region] +
                 direct_dn[region] *
                 (direct_transmittance[region, k] *
                  total_albedo_direct[region, k + 1] *
                  reflectance[region, k] +
                  direct_diffuse_transmittance[region, k])) * inverse_denominator
            direct_dn[region] = direct_transmittance[region, k] * direct_dn[region]
            flux_up[region] =
                direct_dn[region] * total_albedo_direct[region, k + 1] +
                flux_dn[region] * total_albedo[region, k + 1]
        end

        if k < Nz
            v_overlap_matrix_alpha!(v,
                                     matrix_overlap_parameter(solver, optics, k, FT),
                                     region_fraction[1, k], region_fraction[2, k],
                                     region_fraction[1, k + 1],
                                     region_fraction[2, k + 1])
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
        down[k + 1] += μ₀ * sum(direct_dn) + sum(flux_dn)
    end
    return nothing
end

@inline function interface_cloud_fraction(solver::CloudOverlapShortwave{FT},
                                           cloud_fraction,
                                           interface_index,
                                           Nz) where FT
    exponent = max(solver.cloud_fraction_exponent, zero(FT))
    if interface_index == 1
        fraction = FT(cloud_fraction[1])
    elseif interface_index == Nz + 1
        fraction = FT(cloud_fraction[Nz])
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
                           optics::ShortwaveCloudOverlapOptics{FT},
                           atmosphere,
                           boundary_conditions::ShortwaveBoundaryConditions{FT}) where FT
    Nz = number_of_layers(optics.clear)
    if boundary_conditions.surface_albedo isa AbstractArray
        length(boundary_conditions.surface_albedo) == number_of_gpoints(optics.clear) ||
            throw(DimensionMismatch("surface_albedo vector must have length Ngpoints"))
    end
    if boundary_conditions.surface_albedo_direct isa AbstractArray
        length(boundary_conditions.surface_albedo_direct) == number_of_gpoints(optics.clear) ||
            throw(DimensionMismatch("surface_albedo_direct vector must have length Ngpoints"))
    end
    if solver.overlap in (:adding, :matrix_maximum, :matrix_alpha,
                          :tripleclouds_alpha)
        fluxes.shortwave_up .= zero(FT)
        fluxes.shortwave_down .= zero(FT)
        for gpoint in 1:number_of_gpoints(optics.clear)
            scratch_up = zeros(FT, Nz + 1)
            scratch_down = zeros(FT, Nz + 1)
            path_factor = shortwave_path_factor(FT, atmosphere)
            μ₀ = inv(path_factor)
            if solver.overlap == :tripleclouds_alpha
                tripleclouds_shortwave_column!(
                    scratch_up,
                    scratch_down,
                    solver,
                    optics,
                    gpoint,
                    μ₀,
                    boundary_conditions.toa_shortwave_down,
                    surface_albedo_at(boundary_conditions, gpoint),
                    surface_albedo_direct_at(boundary_conditions, gpoint),
                )
            elseif solver.overlap in (:matrix_maximum, :matrix_alpha)
                matrix_maximum_shortwave_column!(
                    scratch_up,
                    scratch_down,
                    solver,
                    optics,
                    gpoint,
                    μ₀,
                    boundary_conditions.toa_shortwave_down,
                    surface_albedo_at(boundary_conditions, gpoint),
                    surface_albedo_direct_at(boundary_conditions, gpoint),
                )
            else
                adding_shortwave_column!(
                    scratch_up,
                    scratch_down,
                    solver,
                    optics,
                    gpoint,
                    μ₀,
                    boundary_conditions.toa_shortwave_down,
                    surface_albedo_at(boundary_conditions, gpoint),
                    surface_albedo_direct_at(boundary_conditions, gpoint),
                )
            end
            w = FT(optics.clear.weights[gpoint])
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
    for i in 1:(Nz + 1)
        fraction = interface_cloud_fraction(solver, optics.cloud_fraction, i, Nz)
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
