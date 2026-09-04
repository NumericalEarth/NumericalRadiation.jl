"""
$(TYPEDEF)

Error metrics for radiation validation against a reference solution.

All flux-like quantities are in the units of the inputs, normally W m^-2.
Heating-rate quantities are in the units of the heating-rate inputs, normally
K day^-1 for validation reports. `bias` is `mean(candidate - reference)`.

Fields are

$(TYPEDFIELDS)
"""
struct RadiationErrorMetrics{FT}
    "Root-mean-square flux error."
    flux_rmse::FT
    "Maximum absolute flux error."
    flux_max_abs::FT
    "Mean signed flux error, candidate minus reference."
    flux_bias::FT
    "Root-mean-square heating-rate error."
    heating_rate_rmse::FT
    "Maximum absolute heating-rate error."
    heating_rate_max_abs::FT
    "Mean signed heating-rate error, candidate minus reference."
    heating_rate_bias::FT
    "Top-of-atmosphere forcing error."
    toa_forcing_error::FT
    "Surface forcing error."
    surface_forcing_error::FT
end

"""
$(TYPEDEF)

Hard validation thresholds for [`RadiationErrorMetrics`](@ref).

Each field defaults to `Inf`, so callers can enforce only the metrics relevant
to a validation gate.

Fields are

$(TYPEDFIELDS)
"""
struct RadiationThresholds{FT}
    flux_rmse::FT
    flux_max_abs::FT
    flux_abs_bias::FT
    heating_rate_rmse::FT
    heating_rate_max_abs::FT
    heating_rate_abs_bias::FT
    toa_forcing_abs_error::FT
    surface_forcing_abs_error::FT
end

function RadiationThresholds(; flux_rmse = Inf,
                             flux_max_abs = Inf,
                             flux_abs_bias = Inf,
                             heating_rate_rmse = Inf,
                             heating_rate_max_abs = Inf,
                             heating_rate_abs_bias = Inf,
                             toa_forcing_abs_error = Inf,
                             surface_forcing_abs_error = Inf)
    FT = promote_type(typeof(flux_rmse), typeof(flux_max_abs), typeof(flux_abs_bias),
                      typeof(heating_rate_rmse), typeof(heating_rate_max_abs),
                      typeof(heating_rate_abs_bias), typeof(toa_forcing_abs_error),
                      typeof(surface_forcing_abs_error))
    return RadiationThresholds{FT}(
        FT(flux_rmse),
        FT(flux_max_abs),
        FT(flux_abs_bias),
        FT(heating_rate_rmse),
        FT(heating_rate_max_abs),
        FT(heating_rate_abs_bias),
        FT(toa_forcing_abs_error),
        FT(surface_forcing_abs_error),
    )
end

@inline _squared(x) = x * x

function _rmse(candidate, reference)
    length(candidate) == length(reference) ||
        throw(DimensionMismatch("candidate and reference arrays must have equal length"))
    isempty(candidate) && throw(ArgumentError("metric arrays must be non-empty"))
    err2 = zero(promote_type(eltype(candidate), eltype(reference)))
    for i in eachindex(candidate, reference)
        err2 += _squared(candidate[i] - reference[i])
    end
    return sqrt(err2 / length(candidate))
end

function _max_abs_error(candidate, reference)
    length(candidate) == length(reference) ||
        throw(DimensionMismatch("candidate and reference arrays must have equal length"))
    isempty(candidate) && throw(ArgumentError("metric arrays must be non-empty"))
    err = zero(promote_type(eltype(candidate), eltype(reference)))
    for i in eachindex(candidate, reference)
        err = max(err, abs(candidate[i] - reference[i]))
    end
    return err
end

function _bias(candidate, reference)
    length(candidate) == length(reference) ||
        throw(DimensionMismatch("candidate and reference arrays must have equal length"))
    isempty(candidate) && throw(ArgumentError("metric arrays must be non-empty"))
    err = zero(promote_type(eltype(candidate), eltype(reference)))
    for i in eachindex(candidate, reference)
        err += candidate[i] - reference[i]
    end
    return err / length(candidate)
end

"""
    radiation_error_metrics(; candidate_flux, reference_flux,
                              candidate_heating_rate, reference_heating_rate,
                              candidate_toa_flux, reference_toa_flux,
                              candidate_surface_flux, reference_surface_flux)

Compute validation metrics used by accuracy reports and acceptance gates.
Flux and heating-rate arrays may be flattened vectors or any array with
matching linear indexing. Forcing errors are candidate-minus-reference at TOA
and surface.
"""
function radiation_error_metrics(; candidate_flux,
                                 reference_flux,
                                 candidate_heating_rate,
                                 reference_heating_rate,
                                 candidate_toa_flux,
                                 reference_toa_flux,
                                 candidate_surface_flux,
                                 reference_surface_flux)
    FT = promote_type(eltype(candidate_flux), eltype(reference_flux),
                      eltype(candidate_heating_rate), eltype(reference_heating_rate),
                      typeof(candidate_toa_flux), typeof(reference_toa_flux),
                      typeof(candidate_surface_flux), typeof(reference_surface_flux))
    return RadiationErrorMetrics{FT}(
        FT(_rmse(candidate_flux, reference_flux)),
        FT(_max_abs_error(candidate_flux, reference_flux)),
        FT(_bias(candidate_flux, reference_flux)),
        FT(_rmse(candidate_heating_rate, reference_heating_rate)),
        FT(_max_abs_error(candidate_heating_rate, reference_heating_rate)),
        FT(_bias(candidate_heating_rate, reference_heating_rate)),
        FT(candidate_toa_flux - reference_toa_flux),
        FT(candidate_surface_flux - reference_surface_flux),
    )
end

function _append_flux_components!(storage, fluxes::RadiativeFluxes)
    append!(storage, fluxes.longwave_up)
    append!(storage, fluxes.longwave_down)
    append!(storage, fluxes.shortwave_up)
    append!(storage, fluxes.shortwave_down)
    return storage
end

function _net_flux_at(fluxes::RadiativeFluxes, index)
    return fluxes.longwave_down[index] - fluxes.longwave_up[index] +
           fluxes.shortwave_down[index] - fluxes.shortwave_up[index]
end

"""
    radiative_flux_error_metrics(candidate_fluxes, reference_fluxes, atmosphere;
                                 gravity, heat_capacity)

Compare two [`RadiativeFluxes`](@ref) objects on the same
[`ColumnAtmosphere`](@ref). The flux metric is computed over all longwave and
shortwave up/down interface flux components, while heating-rate metrics are
computed from the native flux-divergence convention in [`heating_rates!`](@ref).
TOA and surface forcing errors use net downward flux.
"""
function radiative_flux_error_metrics(candidate_fluxes::RadiativeFluxes,
                                      reference_fluxes::RadiativeFluxes,
                                      atmosphere::ColumnAtmosphere;
                                      gravity,
                                      heat_capacity)
    nlayers = length(atmosphere.temperature_layers)
    candidate_heating = zeros(promote_type(eltype(candidate_fluxes),
                                           eltype(reference_fluxes)), nlayers)
    reference_heating = similar(candidate_heating)
    heating_rates!(candidate_heating, candidate_fluxes, atmosphere;
                   gravity, heat_capacity)
    heating_rates!(reference_heating, reference_fluxes, atmosphere;
                   gravity, heat_capacity)

    candidate_flux = eltype(candidate_heating)[]
    reference_flux = eltype(candidate_heating)[]
    _append_flux_components!(candidate_flux, candidate_fluxes)
    _append_flux_components!(reference_flux, reference_fluxes)

    return radiation_error_metrics(
        candidate_flux = candidate_flux,
        reference_flux = reference_flux,
        candidate_heating_rate = candidate_heating,
        reference_heating_rate = reference_heating,
        candidate_toa_flux = _net_flux_at(candidate_fluxes, firstindex(candidate_fluxes.longwave_up)),
        reference_toa_flux = _net_flux_at(reference_fluxes, firstindex(reference_fluxes.longwave_up)),
        candidate_surface_flux = _net_flux_at(candidate_fluxes, lastindex(candidate_fluxes.longwave_up)),
        reference_surface_flux = _net_flux_at(reference_fluxes, lastindex(reference_fluxes.longwave_up)),
    )
end

"""
    passes_thresholds(metrics, thresholds; throw_on_error=false)

Validate [`RadiationErrorMetrics`](@ref) against hard
[`RadiationThresholds`](@ref). Returns `true` when all thresholds pass. With
`throw_on_error=false`, returns `(valid, errors)`.
"""
function passes_thresholds(metrics::RadiationErrorMetrics,
                           thresholds::RadiationThresholds;
                           throw_on_error::Bool = false)
    errors = String[]
    metrics.flux_rmse <= thresholds.flux_rmse ||
        push!(errors, "flux_rmse exceeds threshold")
    metrics.flux_max_abs <= thresholds.flux_max_abs ||
        push!(errors, "flux_max_abs exceeds threshold")
    abs(metrics.flux_bias) <= thresholds.flux_abs_bias ||
        push!(errors, "flux_abs_bias exceeds threshold")
    metrics.heating_rate_rmse <= thresholds.heating_rate_rmse ||
        push!(errors, "heating_rate_rmse exceeds threshold")
    metrics.heating_rate_max_abs <= thresholds.heating_rate_max_abs ||
        push!(errors, "heating_rate_max_abs exceeds threshold")
    abs(metrics.heating_rate_bias) <= thresholds.heating_rate_abs_bias ||
        push!(errors, "heating_rate_abs_bias exceeds threshold")
    abs(metrics.toa_forcing_error) <= thresholds.toa_forcing_abs_error ||
        push!(errors, "toa_forcing_abs_error exceeds threshold")
    abs(metrics.surface_forcing_error) <= thresholds.surface_forcing_abs_error ||
        push!(errors, "surface_forcing_abs_error exceeds threshold")

    if !isempty(errors)
        throw_on_error &&
            throw(ArgumentError("radiation metrics failed thresholds:\n" * join(errors, "\n")))
        return false, errors
    end
    return throw_on_error ? true : (true, errors)
end
