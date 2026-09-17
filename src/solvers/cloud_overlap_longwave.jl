"""
$(TYPEDEF)

Longwave optical properties for a two-region all-sky column.

`clear` contains gas/aerosol optical properties for the clear region. `cloudy`
contains cloudy-region optical properties, including gas plus in-cloud optical
properties. `cloud_fraction` is kept separate so validation and host-model
integrations do not have to represent cloud cover by weakening cloudy optical
depth before transport.

Fields:
- `clear`: Clear-region longwave optical properties
- `cloudy`: Cloudy-region longwave optical properties
- `cloud_fraction`: Layer cloud fraction
- `overlap_parameter`: Interface overlap parameter between adjacent cloudy layers
- `fractional_standard_deviation`: Layer fractional standard deviation of in-cloud
  condensate
"""
struct LongwaveCloudOverlapOptics{FT, L, F, O, D}
    clear::L
    cloudy::L
    cloud_fraction::F
    overlap_parameter::O
    fractional_standard_deviation::D
end

function LongwaveCloudOverlapOptics(clear::LongwaveOptics{FT},
                                    cloudy::LongwaveOptics{FT},
                                    cloud_fraction::AbstractVector{FT};
                                    overlap_parameter = nothing,
                                    fractional_standard_deviation = nothing) where FT
    number_of_layers(clear) == number_of_layers(cloudy) ||
        throw(DimensionMismatch("clear and cloudy longwave optics must have the same number of layers"))
    number_of_gpoints(clear) == number_of_gpoints(cloudy) ||
        throw(DimensionMismatch("clear and cloudy longwave optics must have the same number of g-points"))
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
    has_interface_sources(clear) == has_interface_sources(cloudy) ||
        throw(ArgumentError("clear and cloudy longwave optics must both use interface sources or both omit them"))
    return LongwaveCloudOverlapOptics{FT, typeof(clear),
                                      typeof(cloud_fraction),
                                      typeof(overlap),
                                      typeof(fractional_standard_deviation)}(
        clear, cloudy, cloud_fraction, overlap, fractional_standard_deviation)
end

Base.eltype(::LongwaveCloudOverlapOptics{FT}) where FT = FT

"""
$(TYPEDEF)

First deterministic all-sky longwave overlap solver.

`overlap=:adding` mixes clear/cloudy layer reflectance, transmittance, and
source terms before a scalar longwave adding pass. `overlap=:tripleclouds_alpha`
splits cloudy layers into thin and thick regions using the same gamma
inhomogeneity scaling as the staged shortwave Tripleclouds access point. This
is still a diagnostic solver, not a bit-for-bit ecRad McICA implementation.

Fields:
- `overlap`: Cloud-fraction overlap rule
- `cloud_fraction_exponent`: Exponent applied to layer cloud fraction before mixing
- `inhomogeneity_overlap_exponent`: Exponent applied to the ``α`` overlap inside the
  Tripleclouds inhomogeneity split
"""
struct CloudOverlapLongwave{FT} <: AbstractRadiativeTransferSolver
    overlap::Symbol
    cloud_fraction_exponent::FT
    inhomogeneity_overlap_exponent::FT
end

function CloudOverlapLongwave(; overlap::Symbol = :adding,
                                cloud_fraction_exponent = 1,
                                inhomogeneity_overlap_exponent = 2)
    overlap in (:adding, :tripleclouds_alpha) ||
        throw(ArgumentError("overlap must be `:adding` or `:tripleclouds_alpha`"))
    FT = typeof(float(cloud_fraction_exponent))
    return CloudOverlapLongwave{FT}(overlap, FT(cloud_fraction_exponent), FT(inhomogeneity_overlap_exponent))
end

@inline function matrix_overlap_parameter(solver::CloudOverlapLongwave, optics, interface_index, ::Type{FT}) where FT
    solver.overlap == :tripleclouds_alpha || return one(FT)
    if interface_index < 1 || interface_index > length(optics.overlap_parameter)
        return one(FT)
    end
    return clamp(FT(optics.overlap_parameter[interface_index]), zero(FT), one(FT))
end

function u_overlap_matrix_tripleclouds_alpha!(u::AbstractMatrix{FT},
                                              v::AbstractMatrix{FT},
                                              α,
                                              inhomogeneity_exponent,
                                              upper_fraction::AbstractVector{FT},
                                              lower_fraction::AbstractVector{FT}) where FT
    v_overlap_matrix_tripleclouds_alpha!(v, α, inhomogeneity_exponent, upper_fraction, lower_fraction)
    fill!(u, zero(FT))
    for upper in 1:3, lower in 1:3
        lower_fraction[lower] <= sqrt(eps(FT)) && continue
        u[upper, lower] = v[lower, upper] * upper_fraction[upper] / lower_fraction[lower]
    end
    return u
end

# Reflectance, transmittance and upward and downward sources `(ℛ, 𝒯, Sꜛ, Sꜜ)`
# of layer `k` at g point `g`: the scattering two-stream solution when
# the optics carry `ω` and `𝒢`, the linear-in-τ Planck path when they carry
# interface sources, and otherwise the isothermal layer `𝒯 = e^{-τ}`,
# `S = B (1 - 𝒯)`.
@inline function longwave_layer_terms(::Type{FT}, optics, g, k) where FT
    τ = optical_depth_at(optics, g, k)
    Bₖ, Bₖ₊₁ = longwave_fallback_planck_sources(FT, optics, g, k)
    if has_longwave_scattering(optics)
        ω = single_scattering_albedo_at(optics, g, k)
        𝒢 = scattering_asymmetry_at(optics, g, k)
        return longwave_reflectance_transmittance_sources(FT, τ, ω, 𝒢, Bₖ, Bₖ₊₁)
    elseif has_interface_sources(optics)
        𝒯, Sꜛ, Sꜜ = no_scattering_longwave_sources(FT, τ, Bₖ, Bₖ₊₁)
        return zero(FT), 𝒯, Sꜛ, Sꜜ
    end
    𝒯 = exp(-FT(τ))
    S = FT(source_at(optics, g, k)) * (one(FT) - 𝒯)
    return zero(FT), 𝒯, S, S
end

@inline function longwave_layer_terms_scaled(::Type{FT}, clear, cloudy, scale, g, k) where FT
    clear_optical_depth = max(FT(optical_depth_at(clear, g, k)), zero(FT))
    cloudy_optical_depth = max(FT(optical_depth_at(cloudy, g, k)), zero(FT))
    scale = max(FT(scale), zero(FT))
    optical_depth = max(clear_optical_depth + scale * (cloudy_optical_depth - clear_optical_depth), zero(FT))
    source_top, source_bottom = longwave_fallback_planck_sources(FT, clear, g, k)

    if has_longwave_scattering(clear) || has_longwave_scattering(cloudy)
        clear_albedo = has_longwave_scattering(clear) ?
            clamp(FT(single_scattering_albedo_at(clear, g, k)), zero(FT), one(FT)) : zero(FT)
        cloudy_albedo = has_longwave_scattering(cloudy) ?
            clamp(FT(single_scattering_albedo_at(cloudy, g, k)), zero(FT), one(FT)) : zero(FT)
        clear_asymmetry = has_longwave_scattering(clear) ?
            clamp(FT(scattering_asymmetry_at(clear, g, k)), -one(FT), one(FT)) : zero(FT)
        cloudy_asymmetry = has_longwave_scattering(cloudy) ?
            clamp(FT(scattering_asymmetry_at(cloudy, g, k)), -one(FT), one(FT)) : zero(FT)
        scattering_depth = clear_optical_depth * clear_albedo +
            scale * (cloudy_optical_depth * cloudy_albedo - clear_optical_depth * clear_albedo)
        weighted_asymmetry = clear_optical_depth * clear_albedo * clear_asymmetry +
            scale * (cloudy_optical_depth * cloudy_albedo * cloudy_asymmetry -
                     clear_optical_depth * clear_albedo * clear_asymmetry)
        albedo = optical_depth <= 0 ? zero(FT) : clamp(scattering_depth / optical_depth, zero(FT), one(FT))
        asymmetry = scattering_depth <= 0 ? zero(FT) : clamp(weighted_asymmetry / scattering_depth, -one(FT), one(FT))
        return longwave_reflectance_transmittance_sources(FT, optical_depth, albedo, asymmetry, source_top, source_bottom)
    elseif has_interface_sources(clear)
        transmittance, source_up, source_down =
            no_scattering_longwave_sources(FT, optical_depth, source_top, source_bottom)
        return zero(FT), transmittance, source_up, source_down
    end
    transmittance = exp(-optical_depth)
    source = FT(source_at(clear, g, k)) * (one(FT) - transmittance)
    return zero(FT), transmittance, source, source
end

function adding_longwave_column!(up::AbstractVector{FT},
                                 down::AbstractVector{FT},
                                 solver::CloudOverlapLongwave,
                                 optics::LongwaveCloudOverlapOptics,
                                 g,
                                 surface_up,
                                 surface_albedo,
                                 toa_down) where FT
    Nz = number_of_layers(optics.clear)
    exponent = max(FT(solver.cloud_fraction_exponent), zero(FT))
    reflectance = Vector{FT}(undef, Nz)
    transmittance = Vector{FT}(undef, Nz)
    source_up = Vector{FT}(undef, Nz)
    source_down = Vector{FT}(undef, Nz)

    for k in 1:Nz
        clear_reflectance, clear_transmittance, clear_up, clear_down = longwave_layer_terms(FT, optics.clear, g, k)
        cloudy_reflectance, cloudy_transmittance, cloudy_up, cloudy_down = longwave_layer_terms(FT, optics.cloudy, g, k)
        cloud_weight = clamp(FT(optics.cloud_fraction[k]), zero(FT), one(FT))^exponent
        clear_weight = one(FT) - cloud_weight
        reflectance[k] = clear_weight * clear_reflectance + cloud_weight * cloudy_reflectance
        transmittance[k] = clear_weight * clear_transmittance + cloud_weight * cloudy_transmittance
        source_up[k] = clear_weight * clear_up + cloud_weight * cloudy_up
        source_down[k] = clear_weight * clear_down + cloud_weight * cloudy_down
    end

    albedo = Vector{FT}(undef, Nz + 1)
    source = Vector{FT}(undef, Nz + 1)
    inverse_denominator = Vector{FT}(undef, Nz)
    albedo[Nz + 1] = clamp(FT(surface_albedo), zero(FT), one(FT))
    source[Nz + 1] = FT(surface_up)
    for k in Nz:-1:1
        inverse_denominator[k] = inv(one(FT) - albedo[k + 1] * reflectance[k])
        albedo[k] = reflectance[k] + transmittance[k]^2 * albedo[k + 1] * inverse_denominator[k]
        source[k] = source_up[k] +
            transmittance[k] *
            (source[k + 1] + albedo[k + 1] * source_down[k]) *
            inverse_denominator[k]
    end

    diffuse_down = FT(toa_down)
    down[1] += diffuse_down
    up[1] += source[1] + albedo[1] * diffuse_down
    for k in 1:Nz
        diffuse_down = (transmittance[k] * diffuse_down +
                        reflectance[k] * source[k + 1] +
                        source_down[k]) * inverse_denominator[k]
        down[k + 1] += diffuse_down
        up[k + 1] += albedo[k + 1] * diffuse_down + source[k + 1]
    end
    return nothing
end

function tripleclouds_longwave_column!(up::AbstractVector{FT},
                                       down::AbstractVector{FT},
                                       solver::CloudOverlapLongwave,
                                       optics::LongwaveCloudOverlapOptics,
                                       g,
                                       surface_up,
                                       surface_albedo,
                                       toa_down) where FT
    Nz = number_of_layers(optics.clear)
    exponent = max(FT(solver.cloud_fraction_exponent), zero(FT))

    region_fraction = Matrix{FT}(undef, 3, Nz)
    thin_scaling = Vector{FT}(undef, Nz)
    thick_scaling = Vector{FT}(undef, Nz)
    for k in 1:Nz
        cloud_fraction = clamp(FT(optics.cloud_fraction[k]), zero(FT), one(FT))^exponent
        region_fraction[1, k], region_fraction[2, k], region_fraction[3, k], thin_scaling[k], thick_scaling[k] =
            gamma_tripleclouds_regions(FT, cloud_fraction, optics.fractional_standard_deviation[k])
    end

    reflectance = Matrix{FT}(undef, 3, Nz)
    transmittance = Matrix{FT}(undef, 3, Nz)
    source_up = Matrix{FT}(undef, 3, Nz)
    source_down = Matrix{FT}(undef, 3, Nz)
    for k in 1:Nz
        reflectance[1, k], transmittance[1, k], source_up[1, k],
            source_down[1, k] = longwave_layer_terms(FT, optics.clear, g, k)
        reflectance[2, k], transmittance[2, k], source_up[2, k], source_down[2, k] =
            longwave_layer_terms_scaled(FT, optics.clear, optics.cloudy, thin_scaling[k], g, k)
        reflectance[3, k], transmittance[3, k], source_up[3, k], source_down[3, k] =
            longwave_layer_terms_scaled(FT, optics.clear, optics.cloudy, thick_scaling[k], g, k)
        for region in 1:3
            source_up[region, k] *= region_fraction[region, k]
            source_down[region, k] *= region_fraction[region, k]
        end
    end

    total_albedo = zeros(FT, 3, Nz + 1)
    total_source = zeros(FT, 3, Nz + 1)
    total_albedo[:, Nz + 1] .= clamp(FT(surface_albedo), zero(FT), one(FT))
    for region in 1:3
        total_source[region, Nz + 1] = region_fraction[region, Nz] * FT(surface_up)
    end
    v = zeros(FT, 3, 3)
    u = zeros(FT, 3, 3)
    below_albedo = zeros(FT, 3)
    below_source = zeros(FT, 3)

    for k in Nz:-1:1
        for region in 1:3
            inverse_denominator = inv(one(FT) - total_albedo[region, k + 1] * reflectance[region, k])
            below_albedo[region] = reflectance[region, k] +
                transmittance[region, k]^2 * total_albedo[region, k + 1] *
                inverse_denominator
            below_source[region] = source_up[region, k] +
                transmittance[region, k] *
                (total_source[region, k + 1] +
                 total_albedo[region, k + 1] * source_down[region, k]) *
                inverse_denominator
        end

        upper = k == 1 ? FT[one(FT), zero(FT), zero(FT)] : region_fraction[:, k - 1]
        lower = region_fraction[:, k]
        u_overlap_matrix_tripleclouds_alpha!(
            u, v, matrix_overlap_parameter(solver, optics, k - 1, FT),
            solver.inhomogeneity_overlap_exponent, upper, lower)
        for upper_region in 1:3
            total_albedo[upper_region, k] = zero(FT)
            total_source[upper_region, k] = zero(FT)
            for lower_region in 1:3
                total_albedo[upper_region, k] += below_albedo[lower_region] * v[lower_region, upper_region]
                total_source[upper_region, k] += below_source[lower_region] * u[upper_region, lower_region]
            end
        end
    end

    flux_down = zeros(FT, 3)
    flux_up = zeros(FT, 3)
    upper = FT[one(FT), zero(FT), zero(FT)]
    v_overlap_matrix_tripleclouds_alpha!(
        v, one(FT), solver.inhomogeneity_overlap_exponent, upper, region_fraction[:, 1])
    for region in 1:3
        flux_down[region] = v[region, 1] * FT(toa_down)
    end
    flux_up[1] = total_source[1, 1] + total_albedo[1, 1] * FT(toa_down)
    up[1] += flux_up[1]
    down[1] += FT(toa_down)

    next_flux_down = zeros(FT, 3)
    for k in 1:Nz
        for region in 1:3
            inverse_denominator = inv(one(FT) - reflectance[region, k] * total_albedo[region, k + 1])
            flux_down[region] = (transmittance[region, k] * flux_down[region] +
                                 reflectance[region, k] * total_source[region, k + 1] +
                                 source_down[region, k]) * inverse_denominator
            flux_up[region] = total_albedo[region, k + 1] * flux_down[region] + total_source[region, k + 1]
        end

        if k < Nz
            v_overlap_matrix_tripleclouds_alpha!(
                v, matrix_overlap_parameter(solver, optics, k, FT),
                solver.inhomogeneity_overlap_exponent,
                region_fraction[:, k], region_fraction[:, k + 1])
            fill!(next_flux_down, zero(FT))
            for upper_region in 1:3, lower_region in 1:3
                next_flux_down[lower_region] += v[lower_region, upper_region] * flux_down[upper_region]
            end
            flux_down .= next_flux_down
        end

        up[k + 1] += sum(flux_up)
        down[k + 1] += sum(flux_down)
    end
    return nothing
end

"""
    radiative_fluxes!(fluxes, CloudOverlapLongwave(), optics, atmosphere, boundary_conditions)

Compute all-sky longwave interface fluxes from clear/cloudy-region optical
properties and explicit layer cloud fractions.
"""
function radiative_fluxes!(fluxes::RadiativeFluxes,
                           solver::CloudOverlapLongwave,
                           optics::LongwaveCloudOverlapOptics{FT},
                           atmosphere,
                           boundary_conditions::LongwaveBoundaryConditions{FT}) where FT
    Nz = number_of_layers(optics.clear)
    length(fluxes.longwave_up) == Nz + 1 || throw(DimensionMismatch("longwave_up must have length Nz + 1"))
    length(fluxes.longwave_down) == Nz + 1 || throw(DimensionMismatch("longwave_down must have length Nz + 1"))
    fluxes.longwave_up .= zero(FT)
    fluxes.longwave_down .= zero(FT)

    for g in 1:number_of_gpoints(optics.clear)
        w = FT(optics.clear.weights[g])
        spectral_up = zeros(FT, Nz + 1)
        spectral_down = zeros(FT, Nz + 1)
        if solver.overlap == :tripleclouds_alpha
            tripleclouds_longwave_column!(
                spectral_up,
                spectral_down,
                solver,
                optics,
                g,
                surface_longwave_up_at(boundary_conditions, g),
                surface_longwave_albedo(boundary_conditions, g),
                boundary_conditions.toa_longwave_down,
            )
        else
            adding_longwave_column!(
                spectral_up,
                spectral_down,
                solver,
                optics,
                g,
                surface_longwave_up_at(boundary_conditions, g),
                surface_longwave_albedo(boundary_conditions, g),
                boundary_conditions.toa_longwave_down,
            )
        end
        fluxes.longwave_up .+= w .* spectral_up
        fluxes.longwave_down .+= w .* spectral_down
    end

    return fluxes
end
