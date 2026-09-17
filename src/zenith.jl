# Scalar solar geometry. Hosts (SpeedyWeather, Breeze) call these per grid
# point; this package does no grid-level launches itself. Signs and
# normalisations follow Spencer (1971), doi:10.1071/SR971971.

"""$(TYPEDSIGNATURES)
Solar declination [rad] from the fractional day of year `γ ∈ [0, 2π]` using
the Spencer (1971) four-term Fourier series (accurate to ≈0.01°).
"""
@inline function solar_declination(γ::NF) where NF
    return NF(0.006918) -
           NF(0.399912) * cos(γ)     + NF(0.070257) * sin(γ) -
           NF(0.006758) * cos(2*γ)   + NF(0.000907) * sin(2*γ) -
           NF(0.002697) * cos(3*γ)   + NF(0.001480) * sin(3*γ)
end

"""$(TYPEDSIGNATURES)
Equation of time [rad] from the fractional day of year `γ ∈ [0, 2π]`
(Spencer 1971).
"""
@inline function equation_of_time(γ::NF) where NF
    return NF(0.000075) +
           NF(0.001868) * cos(γ)   - NF(0.032077) * sin(γ) -
           NF(0.014615) * cos(2*γ) - NF(0.040849) * sin(2*γ)
end

"""$(TYPEDSIGNATURES)
Fractional year angle `γ = 2π (day − 1) / days_per_year` for a `DateTime`.
"""
@inline function fractional_year_angle(time::DateTime,
                                       equinox::DateTime = DateTime(year(time), 3, 20, 12, 0, 0),
                                       days_per_year::Real = 365.25)
    day_of_year_mid = (time - DateTime(year(time), 1, 1)).value / 1000 / 86400
    return 2π * day_of_year_mid / days_per_year
end

"""$(TYPEDSIGNATURES)
Cosine of the solar zenith angle at `longitude` and `latitude` [rad] and UT
`time`. Clipped to `max(μ₀, 0)` so the night side returns 0.

For seasonal-only (daily-average) insolation the caller should average over
a day or set `time` to noon and absorb the daily mean separately.
"""
@inline function cosine_solar_zenith(longitude, latitude, time::DateTime;
                                     axial_tilt::Real = 23.44 * π / 180,
                                     equinox::DateTime = DateTime(year(time), 3, 20, 12, 0, 0),
                                     days_per_year::Real = 365.25,
                                     seconds_per_day::Real = 86400)
    NF = float(promote_type(typeof(longitude), typeof(latitude)))
    longitude = NF(longitude); latitude = NF(latitude)
    γ = NF(fractional_year_angle(time, equinox, days_per_year))
    δ = solar_declination(γ)
    time_correction = equation_of_time(γ)
    day_fraction = NF(((time - DateTime(year(time), month(time), day(time))).value / 1000) /
               seconds_per_day)
    hour_angle = NF(2π) * (day_fraction - NF(0.5)) + longitude + time_correction
    μ₀ = sin(δ) * sin(latitude) + cos(δ) * cos(latitude) * cos(hour_angle)
    return max(zero(NF), μ₀)
end
