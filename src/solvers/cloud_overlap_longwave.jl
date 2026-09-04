"""
$(TYPEDEF)

Longwave optical properties for a two-region all-sky column.

`clear` contains gas/aerosol optical properties for the clear region. `cloudy`
contains cloudy-region optical properties, including gas plus in-cloud optical
properties. `cloud_fraction` is kept separate so validation and host-model
integrations do not have to represent cloud cover by weakening cloudy optical
depth before transport.

Fields are

$(TYPEDFIELDS)
"""
struct LongwaveCloudOverlapOpticalProperties{FT, L, F, O, D}
    "Clear-region longwave optical properties."
    clear::L
    "Cloudy-region longwave optical properties."
    cloudy::L
    "Layer cloud fraction."
    cloud_fraction::F
    "Interface overlap parameter between adjacent cloudy layers."
    overlap_parameter::O
    "Layer fractional standard deviation of in-cloud condensate."
    fractional_std::D
end

function LongwaveCloudOverlapOpticalProperties(clear::LongwaveOpticalProperties{FT},
                                               cloudy::LongwaveOpticalProperties{FT},
                                               cloud_fraction::AbstractVector{FT};
                                               overlap_parameter = nothing,
                                               fractional_std = nothing) where FT
    _nlayers(clear) == _nlayers(cloudy) ||
        throw(DimensionMismatch("clear and cloudy longwave optics must have the same number of layers"))
    _ng(clear) == _ng(cloudy) ||
        throw(DimensionMismatch("clear and cloudy longwave optics must have the same number of g-points"))
    length(cloud_fraction) == _nlayers(clear) ||
        throw(DimensionMismatch("cloud_fraction must have one value per layer"))
    overlap = overlap_parameter === nothing ?
        fill(one(FT), max(_nlayers(clear) - 1, 0)) :
        FT.(overlap_parameter)
    length(overlap) == max(_nlayers(clear) - 1, 0) ||
        throw(DimensionMismatch("overlap_parameter must have one value between each adjacent layer"))
    fsd = fractional_std === nothing ?
        fill(one(FT), _nlayers(clear)) :
        FT.(fractional_std)
    length(fsd) == _nlayers(clear) ||
        throw(DimensionMismatch("fractional_std must have one value per layer"))
    _has_interface_sources(clear) == _has_interface_sources(cloudy) ||
        throw(ArgumentError("clear and cloudy longwave optics must both use interface sources or both omit them"))
    return LongwaveCloudOverlapOpticalProperties{FT, typeof(clear),
                                                 typeof(cloud_fraction),
                                                 typeof(overlap),
                                                 typeof(fsd)}(
        clear, cloudy, cloud_fraction, overlap, fsd)
end

Base.eltype(::LongwaveCloudOverlapOpticalProperties{FT}) where FT = FT

"""
$(TYPEDEF)

First deterministic all-sky longwave overlap solver.

`overlap=:adding` mixes clear/cloudy layer reflectance, transmittance, and
source terms before a scalar longwave adding pass. `overlap=:tripleclouds_alpha`
splits cloudy layers into thin and thick regions using the same gamma
inhomogeneity scaling as the staged shortwave Tripleclouds access point. This
is still a diagnostic solver, not a bit-for-bit ecRad McICA implementation.
"""
struct CloudOverlapLongwave{FT} <: AbstractRadiativeTransferSolver
    "Cloud-fraction overlap rule."
    overlap::Symbol
    "Exponent applied to layer cloud fraction before mixing."
    cloud_fraction_exponent::FT
    "Exponent applied to alpha overlap inside the Tripleclouds inhomogeneity split."
    inhomogeneity_overlap_exponent::FT
end

function CloudOverlapLongwave(; overlap::Symbol = :adding,
                              cloud_fraction_exponent = 1,
                              inhomogeneity_overlap_exponent = 2)
    overlap in (:adding, :tripleclouds_alpha) ||
        throw(ArgumentError("overlap must be `:adding` or `:tripleclouds_alpha`"))
    FT = typeof(float(cloud_fraction_exponent))
    return CloudOverlapLongwave{FT}(
        overlap, FT(cloud_fraction_exponent), FT(inhomogeneity_overlap_exponent))
end

@inline function _matrix_overlap_parameter(solver::CloudOverlapLongwave,
                                           optics,
                                           interface_index,
                                           ::Type{FT}) where FT
    solver.overlap == :tripleclouds_alpha || return one(FT)
    if interface_index < 1 || interface_index > length(optics.overlap_parameter)
        return one(FT)
    end
    return clamp(FT(optics.overlap_parameter[interface_index]), zero(FT), one(FT))
end

function _u_overlap_matrix_tripleclouds_alpha!(u::AbstractMatrix{FT},
                                               v::AbstractMatrix{FT},
                                               alpha,
                                               inhomogeneity_exponent,
                                               upper_frac::AbstractVector{FT},
                                               lower_frac::AbstractVector{FT}) where FT
    _v_overlap_matrix_tripleclouds_alpha!(
        v, alpha, inhomogeneity_exponent, upper_frac, lower_frac)
    fill!(u, zero(FT))
    for upper in 1:3, lower in 1:3
        lower_frac[lower] <= sqrt(eps(FT)) && continue
        u[upper, lower] = v[lower, upper] * upper_frac[upper] / lower_frac[lower]
    end
    return u
end

@inline function _lw_layer_terms(::Type{FT}, optics, ig, k) where FT
    tau = _tau(optics, ig, k)
    top, bottom = _lw_fallback_planck_sources(FT, optics, ig, k)
    if _has_lw_scattering(optics)
        return _lw_ref_trans_sources(
            FT, tau, _lw_ssa(optics, ig, k), _lw_asymmetry(optics, ig, k),
            top, bottom)
    elseif _has_interface_sources(optics)
        transmittance, source_up, source_down =
            _no_scattering_lw_sources(FT, tau, top, bottom)
        return zero(FT), transmittance, source_up, source_down
    end
    transmittance = exp(-FT(tau))
    source = FT(_source(optics, ig, k)) * (one(FT) - transmittance)
    return zero(FT), transmittance, source, source
end

@inline function _lw_layer_terms_scaled(::Type{FT}, clear, cloudy, scale, ig, k) where FT
    clear_tau = max(FT(_tau(clear, ig, k)), zero(FT))
    cloudy_tau = max(FT(_tau(cloudy, ig, k)), zero(FT))
    tau = max(clear_tau + max(FT(scale), zero(FT)) * (cloudy_tau - clear_tau),
              zero(FT))
    top, bottom = _lw_fallback_planck_sources(FT, clear, ig, k)

    if _has_lw_scattering(clear) || _has_lw_scattering(cloudy)
        clear_ssa = _has_lw_scattering(clear) ?
            clamp(FT(_lw_ssa(clear, ig, k)), zero(FT), one(FT)) : zero(FT)
        cloudy_ssa = _has_lw_scattering(cloudy) ?
            clamp(FT(_lw_ssa(cloudy, ig, k)), zero(FT), one(FT)) : zero(FT)
        clear_g = _has_lw_scattering(clear) ?
            clamp(FT(_lw_asymmetry(clear, ig, k)), -one(FT), one(FT)) : zero(FT)
        cloudy_g = _has_lw_scattering(cloudy) ?
            clamp(FT(_lw_asymmetry(cloudy, ig, k)), -one(FT), one(FT)) : zero(FT)
        scattering =
            clear_tau * clear_ssa +
            max(FT(scale), zero(FT)) * (cloudy_tau * cloudy_ssa - clear_tau * clear_ssa)
        moment =
            clear_tau * clear_ssa * clear_g +
            max(FT(scale), zero(FT)) *
            (cloudy_tau * cloudy_ssa * cloudy_g - clear_tau * clear_ssa * clear_g)
        ssa = tau <= 0 ? zero(FT) : clamp(scattering / tau, zero(FT), one(FT))
        asymmetry = scattering <= 0 ? zero(FT) :
            clamp(moment / scattering, -one(FT), one(FT))
        return _lw_ref_trans_sources(FT, tau, ssa, asymmetry, top, bottom)
    elseif _has_interface_sources(clear)
        transmittance, source_up, source_down =
            _no_scattering_lw_sources(FT, tau, top, bottom)
        return zero(FT), transmittance, source_up, source_down
    end
    transmittance = exp(-tau)
    source = FT(_source(clear, ig, k)) * (one(FT) - transmittance)
    return zero(FT), transmittance, source, source
end

function _adding_lw_column!(up::AbstractVector{FT},
                            down::AbstractVector{FT},
                            solver::CloudOverlapLongwave,
                            optics::LongwaveCloudOverlapOpticalProperties,
                            ig,
                            surface_up,
                            surface_albedo,
                            toa_down) where FT
    nlayers = _nlayers(optics.clear)
    exponent = max(FT(solver.cloud_fraction_exponent), zero(FT))
    reflectance = Vector{FT}(undef, nlayers)
    transmittance = Vector{FT}(undef, nlayers)
    source_up = Vector{FT}(undef, nlayers)
    source_down = Vector{FT}(undef, nlayers)

    for k in 1:nlayers
        clear_r, clear_t, clear_up, clear_down =
            _lw_layer_terms(FT, optics.clear, ig, k)
        cloudy_r, cloudy_t, cloudy_up, cloudy_down =
            _lw_layer_terms(FT, optics.cloudy, ig, k)
        cloud_weight = clamp(FT(optics.cloud_fraction[k]), zero(FT), one(FT))^exponent
        clear_weight = one(FT) - cloud_weight
        reflectance[k] = clear_weight * clear_r + cloud_weight * cloudy_r
        transmittance[k] = clear_weight * clear_t + cloud_weight * cloudy_t
        source_up[k] = clear_weight * clear_up + cloud_weight * cloudy_up
        source_down[k] = clear_weight * clear_down + cloud_weight * cloudy_down
    end

    albedo = Vector{FT}(undef, nlayers + 1)
    source = Vector{FT}(undef, nlayers + 1)
    inv_denominator = Vector{FT}(undef, nlayers)
    albedo[nlayers + 1] = clamp(FT(surface_albedo), zero(FT), one(FT))
    source[nlayers + 1] = FT(surface_up)
    for k in nlayers:-1:1
        inv_denominator[k] = inv(one(FT) - albedo[k + 1] * reflectance[k])
        albedo[k] = reflectance[k] +
            transmittance[k]^2 * albedo[k + 1] * inv_denominator[k]
        source[k] = source_up[k] +
            transmittance[k] *
            (source[k + 1] + albedo[k + 1] * source_down[k]) *
            inv_denominator[k]
    end

    diffuse_down = FT(toa_down)
    down[1] += diffuse_down
    up[1] += source[1] + albedo[1] * diffuse_down
    for k in 1:nlayers
        diffuse_down = (transmittance[k] * diffuse_down +
                        reflectance[k] * source[k + 1] +
                        source_down[k]) * inv_denominator[k]
        down[k + 1] += diffuse_down
        up[k + 1] += albedo[k + 1] * diffuse_down + source[k + 1]
    end
    return nothing
end

function _tripleclouds_lw_column!(up::AbstractVector{FT},
                                  down::AbstractVector{FT},
                                  solver::CloudOverlapLongwave,
                                  optics::LongwaveCloudOverlapOpticalProperties,
                                  ig,
                                  surface_up,
                                  surface_albedo,
                                  toa_down) where FT
    nlayers = _nlayers(optics.clear)
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
    source_up = Matrix{FT}(undef, 3, nlayers)
    source_down = Matrix{FT}(undef, 3, nlayers)
    for k in 1:nlayers
        reflectance[1, k], transmittance[1, k], source_up[1, k],
            source_down[1, k] = _lw_layer_terms(FT, optics.clear, ig, k)
        reflectance[2, k], transmittance[2, k], source_up[2, k],
            source_down[2, k] =
            _lw_layer_terms_scaled(FT, optics.clear, optics.cloudy,
                                   thin_scaling[k], ig, k)
        reflectance[3, k], transmittance[3, k], source_up[3, k],
            source_down[3, k] =
            _lw_layer_terms_scaled(FT, optics.clear, optics.cloudy,
                                   thick_scaling[k], ig, k)
        for region in 1:3
            source_up[region, k] *= region_frac[region, k]
            source_down[region, k] *= region_frac[region, k]
        end
    end

    total_albedo = zeros(FT, 3, nlayers + 1)
    total_source = zeros(FT, 3, nlayers + 1)
    total_albedo[:, nlayers + 1] .= clamp(FT(surface_albedo), zero(FT), one(FT))
    for region in 1:3
        total_source[region, nlayers + 1] =
            region_frac[region, nlayers] * FT(surface_up)
    end
    v = zeros(FT, 3, 3)
    u = zeros(FT, 3, 3)
    below_albedo = zeros(FT, 3)
    below_source = zeros(FT, 3)

    for k in nlayers:-1:1
        for region in 1:3
            denom = inv(one(FT) - total_albedo[region, k + 1] *
                        reflectance[region, k])
            below_albedo[region] = reflectance[region, k] +
                transmittance[region, k]^2 * total_albedo[region, k + 1] *
                denom
            below_source[region] = source_up[region, k] +
                transmittance[region, k] *
                (total_source[region, k + 1] +
                 total_albedo[region, k + 1] * source_down[region, k]) *
                denom
        end

        upper = k == 1 ? FT[one(FT), zero(FT), zero(FT)] : region_frac[:, k - 1]
        lower = region_frac[:, k]
        _u_overlap_matrix_tripleclouds_alpha!(
            u, v, _matrix_overlap_parameter(solver, optics, k - 1, FT),
            solver.inhomogeneity_overlap_exponent, upper, lower)
        for upper_region in 1:3
            total_albedo[upper_region, k] = zero(FT)
            total_source[upper_region, k] = zero(FT)
            for lower_region in 1:3
                total_albedo[upper_region, k] +=
                    below_albedo[lower_region] * v[lower_region, upper_region]
                total_source[upper_region, k] +=
                    below_source[lower_region] * u[upper_region, lower_region]
            end
        end
    end

    flux_down = zeros(FT, 3)
    flux_up = zeros(FT, 3)
    upper = FT[one(FT), zero(FT), zero(FT)]
    _v_overlap_matrix_tripleclouds_alpha!(
        v, one(FT), solver.inhomogeneity_overlap_exponent, upper, region_frac[:, 1])
    for region in 1:3
        flux_down[region] = v[region, 1] * FT(toa_down)
    end
    flux_up[1] = total_source[1, 1] + total_albedo[1, 1] * FT(toa_down)
    up[1] += flux_up[1]
    down[1] += FT(toa_down)

    next_flux_down = zeros(FT, 3)
    for k in 1:nlayers
        for region in 1:3
            denom = inv(one(FT) - reflectance[region, k] *
                        total_albedo[region, k + 1])
            flux_down[region] =
                (transmittance[region, k] * flux_down[region] +
                 reflectance[region, k] * total_source[region, k + 1] +
                 source_down[region, k]) * denom
            flux_up[region] =
                total_albedo[region, k + 1] * flux_down[region] +
                total_source[region, k + 1]
        end

        if k < nlayers
            _v_overlap_matrix_tripleclouds_alpha!(
                v, _matrix_overlap_parameter(solver, optics, k, FT),
                solver.inhomogeneity_overlap_exponent,
                region_frac[:, k], region_frac[:, k + 1])
            fill!(next_flux_down, zero(FT))
            for upper_region in 1:3, lower_region in 1:3
                next_flux_down[lower_region] +=
                    v[lower_region, upper_region] * flux_down[upper_region]
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
                           optics::LongwaveCloudOverlapOpticalProperties{FT},
                           atmosphere,
                           boundary_conditions::LongwaveBoundaryConditions{FT}) where FT
    nlayers = _nlayers(optics.clear)
    length(fluxes.longwave_up) == nlayers + 1 ||
        throw(DimensionMismatch("longwave_up must have length nlayers + 1"))
    length(fluxes.longwave_down) == nlayers + 1 ||
        throw(DimensionMismatch("longwave_down must have length nlayers + 1"))
    fluxes.longwave_up .= zero(FT)
    fluxes.longwave_down .= zero(FT)

    for ig in 1:_ng(optics.clear)
        w = FT(optics.clear.weights[ig])
        spectral_up = zeros(FT, nlayers + 1)
        spectral_down = zeros(FT, nlayers + 1)
        if solver.overlap == :tripleclouds_alpha
            _tripleclouds_lw_column!(
                spectral_up,
                spectral_down,
                solver,
                optics,
                ig,
                _surface_longwave_up(boundary_conditions, ig),
                _surface_longwave_albedo(boundary_conditions, ig),
                boundary_conditions.toa_longwave_down,
            )
        else
            _adding_lw_column!(
                spectral_up,
                spectral_down,
                solver,
                optics,
                ig,
                _surface_longwave_up(boundary_conditions, ig),
                _surface_longwave_albedo(boundary_conditions, ig),
                boundary_conditions.toa_longwave_down,
            )
        end
        fluxes.longwave_up .+= w .* spectral_up
        fluxes.longwave_down .+= w .* spectral_down
    end

    return fluxes
end
