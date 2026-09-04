# Implementation for the Manabe radiative-convective equilibrium tutorial
# (examples/manabe_rce.jl). The tutorial page defines the headline
# experiment parameters, includes this file, and shows only the experiment
# calls and results; physical constants, the initial-state prescription,
# and the solver live here. The formulation follows the RRTMGP.jl Manabe tutorial: level
# temperatures are prognostic, convective adjustment is a one-line clamp
# onto the critical profile anchored at a fixed trial surface temperature,
# and the surface temperature is solved externally from top-of-atmosphere
# balance by a bracketed secant iteration. RRTMGP is a source reference
# only — nothing here imports or calls it.

g  = 9.80665         # gravitational acceleration, m s⁻²
cₚ = 1004            # isobaric heat capacity, J kg⁻¹ K⁻¹
σ  = 5.670374419e-8  # Stefan-Boltzmann constant, W m⁻² K⁻⁴
Rᵈ = 287.05          # dry-air gas constant, J kg⁻¹ K⁻¹
mᵈ = 0.028964        # dry-air molar mass, kg mol⁻¹
mᵛ = 0.018016        # water molar mass, kg mol⁻¹
day = 86_400         # s


gas_optics = read_reference_ecckd_gas_optics("32x32";
    names = (:composite, :h2o, :o3, :co2, :ch4, :n2o))

# Analytic midlatitude-summer initial state, transcribed locally from
# RRTMGP.jl's `standard_atmosphere` source (src/api/atmosphere_profile.jl;
# AFGL-style two-segment temperature, exact hydrostatic pressure,
# log-pressure-Gaussian ozone). Transcribed, not imported.

t_sfc_mls = 294      # K, midlatitude-summer surface temperature
z_trop    = 13e3     # m, idealized tropopause height
Γ_strat   = 2e-3     # K m⁻¹, idealized stratospheric warming rate

standard_T(z) = z <= z_trop ? t_sfc_mls - Γ * z :
                (t_sfc_mls - Γ * z_trop) + Γ_strat * (z - z_trop)

function standard_p(z)
    T_trop = t_sfc_mls - Γ * z_trop
    z <= z_trop && return pₛ * (standard_T(z) / t_sfc_mls)^(g / (Rᵈ * Γ))
    p_trop = pₛ * (T_trop / t_sfc_mls)^(g / (Rᵈ * Γ))
    return p_trop * (standard_T(z) / T_trop)^(-g / (Rᵈ * Γ_strat))
end

standard_χO₃(p) = 3e-8 + 7.5e-6 * exp(-(log(p / 1_200))^2 / (2 * 1.2^2))

# Physical grid: levels uniform in altitude from the surface to zₜ, stored
# TOA-first (our column convention). One separate isothermal lookup-boundary
# layer spans from the gas-optics table's minimum pressure down to the top
# physical level; it is excluded from all prognostic, adjustment, and
# convergence arrays — its temperature and gas state are copied from the top
# physical level before every radiation call and its heating is discarded.

zᵢ = collect(range(0, zₜ; length = N + 1))
z = 0.5 .* (zᵢ[1:N] .+ zᵢ[2:N+1])
pᵢ = reverse(standard_p.(zᵢ))          # TOA-first, increasing downward
p = reverse(standard_p.(z))          # standard_p at altitude midpoints
nlev  = N + 1

p_min_table = first(gas_optics.pressure_grid)
p_min_table < pᵢ[1] ||
    error("lookup-table minimum pressure does not lie above the physical top")

N_ext = N + 1                             # extension layer + physical layers
p_ext = vcat(0.5 * (p_min_table + pᵢ[1]), p)   # arithmetic midpoint
pᵢ_ext = vcat(p_min_table, pᵢ)                      # for the extension only
χO₃_phys = standard_χO₃.(p)
χO₃_ext = vcat(χO₃_phys[1], χO₃_phys)        # extension copies the top layer

# Humidity closure on layer temperatures (fixed relative humidity, Magnus
# saturation vapor pressure, stratospheric floor), applied to the full
# radiation column including the extension layer:

saturation_vapor_pressure(T) = 610.94 * exp(17.625 * (T - 273.15) / (T - 30.11))

function fixed_relative_humidity!(χH₂O_ext, T_ext)
    for k in eachindex(χH₂O_ext)
        h = max(surface_relative_humidity * (p_ext[k] / pₛ - 0.02) / 0.98, 0)
        eₛ = saturation_vapor_pressure(T_ext[k])
        χH₂O_ext[k] = max(h * eₛ / max(p_ext[k] - h * eₛ, 1), water_vapor_floor)
    end
    return χH₂O_ext
end

function radiation_work_arrays(gas_optics, N)
    longwave_gpoints = length(gas_optics.longwave_weights)
    shortwave_gpoints = length(gas_optics.shortwave_weights)
    longwave = LongwaveOptics(zeros(longwave_gpoints, N),
                                         zeros(longwave_gpoints, N);
                                         source_top = zeros(longwave_gpoints, N),
                                         source_bottom = zeros(longwave_gpoints, N),
                                         weights = zeros(longwave_gpoints))
    shortwave = ShortwaveOptics(zeros(shortwave_gpoints, N);
                                           rayleigh_optical_depth = zeros(shortwave_gpoints, N),
                                           scattering_asymmetry = zeros(shortwave_gpoints, N),
                                           weights = zeros(shortwave_gpoints))
    fluxes = RadiativeFluxes(longwave_up = zeros(N + 1),
                             longwave_down = zeros(N + 1),
                             shortwave_up = zeros(N + 1),
                             shortwave_down = zeros(N + 1))
    return longwave, shortwave, fluxes
end

# Inner equilibration at a FIXED trial surface temperature, in the RRTMGP
# tutorial's exact order and stopping rule: clamp levels onto the critical
# profile T_c(p) = Tₛ (p/pₛ)^(Γ Rᵈ/g); set layer temperatures to
# adjacent-level means; update humidity and fluxes; stop when one
# successive adjusted level profile changes by less than `tolerance`
# (kelvin); otherwise save the profile, map layer heating to level
# tendencies (interior levels take the mean of the adjacent layer rates,
# the end levels take the edge rate), and march with the tutorial's ±2 K
# increment clamp, up to `maxsteps` steps.

function equilibrate!(Tᵢ, Tₛ; χCO₂, ozone = χO₃_ext, fixed_water_vapor = nothing,
                      Δt = 8 * 3_600, maxsteps = 20_000, tolerance = 1e-4)
    T_ext = zeros(N_ext)
    Tᵢ_ext = zeros(N_ext + 1)
    χH₂O_ext = zeros(N_ext)
    nᵈ = zeros(N_ext)
    gases = (composite = zeros(N_ext), h2o = zeros(N_ext), o3 = zeros(N_ext),
             co2 = zeros(N_ext), ch4 = zeros(N_ext), n2o = zeros(N_ext))
    atmosphere = ColumnAtmosphere(; pressure_layers = p_ext,
                                  pressure_interfaces = pᵢ_ext,
                                  temperature_layers = T_ext,
                                  temperature_interfaces = Tᵢ_ext,
                                  gases, surface = nothing,
                                  geometry = (cos_zenith = μ₀,))
    longwave, shortwave, fluxes = radiation_work_arrays(gas_optics, N_ext)
    shortwave_boundary = ShortwaveBoundaryConditions(toa_shortwave_down = S₀,
                                                     surface_albedo = α)
    surface_emission = surface_longwave_emission(gas_optics, Tₛ)
    longwave_boundary = LongwaveBoundaryConditions(surface_longwave_up = surface_emission)
    Q = zeros(N_ext)
    dT_lev = zeros(nlev)
    previous = zeros(nlev)

    solve_radiation!() = begin
        # extension layer: isothermal with, and gas state tied to, the top level
        T_ext[1] = Tᵢ[1]
        @views @. T_ext[2:N_ext] = (Tᵢ[1:N] + Tᵢ[2:nlev]) / 2
        Tᵢ_ext[1] = Tᵢ[1]
        @views Tᵢ_ext[2:N_ext+1] .= Tᵢ
        if fixed_water_vapor === nothing
            fixed_relative_humidity!(χH₂O_ext, T_ext)
        else
            χH₂O_ext .= fixed_water_vapor
        end
        χH₂O_ext[1] = χH₂O_ext[2]      # extension copies the top physical layer
        for k in 1:N_ext
            nᵈ[k] = (pᵢ_ext[k + 1] - pᵢ_ext[k]) / (g * (mᵈ + mᵛ * χH₂O_ext[k]))
            gases.composite[k] = nᵈ[k]
            gases.h2o[k] = χH₂O_ext[k] * nᵈ[k]
            gases.o3[k] = ozone[k] * nᵈ[k]
            gases.co2[k] = χCO₂ * nᵈ[k]
            gases.ch4[k] = χCH₄ * nᵈ[k]
            gases.n2o[k] = χN₂O * nᵈ[k]
        end
        optical_properties!(longwave, shortwave, gas_optics, atmosphere)
        radiative_fluxes!(fluxes, CloudlessLongwave(), longwave, atmosphere,
                          longwave_boundary)
        radiative_fluxes!(fluxes, CloudlessShortwave(), shortwave, atmosphere,
                          shortwave_boundary)
    end

    critical = Tₛ .* (pᵢ ./ pₛ) .^ (Γ * Rᵈ / g)
    fill!(previous, 0)
    final_difference = Inf
    steps = maxsteps
    converged = false
    for step in 1:maxsteps
        @. Tᵢ = max(Tᵢ, critical)
        solve_radiation!()
        final_difference = maximum(abs, Tᵢ .- previous)
        if final_difference < tolerance
            steps = step
            converged = true
            break
        end
        previous .= Tᵢ
        heating_rates!(Q, fluxes, atmosphere; gravity = g, heat_capacity = cₚ)
        # discard the extension tendency Q[1]; physical layer j is Q[j + 1]
        dT_lev[1] = Q[2]
        dT_lev[nlev] = Q[N_ext]
        @views @. dT_lev[2:N] = (Q[2:N_ext-1] + Q[3:N_ext]) / 2
        @. Tᵢ += clamp(Δt * dT_lev, -2, 2)
    end
    return (; Tᵢ = copy(Tᵢ), Tₛ, converged, final_difference, steps,
            days = steps * Δt / day,
            χH₂O = copy(χH₂O_ext),
            T_ext = copy(T_ext),
            extension_temperature = T_ext[1],
            olr = fluxes.longwave_up[1],
            asr = fluxes.shortwave_down[1] - fluxes.shortwave_up[1])
end

# Outer closure: solve F(Tₛ) = ASR − OLR = 0 by a bracketed secant iteration.
# The bracket expands repeatedly (doubling, hard-bounded) until it changes
# sign — necessary because absorber-removal roots sit tens of kelvin from
# the control. Every inner equilibration must converge, or the build fails.

function rce(χCO₂; ozone = χO₃_ext, fixed_water_vapor = nothing,
             Tₛ_guesses = (285, 295), warm_start = nothing,
             imbalance_tolerance = 0.1, max_expansions = 8, max_iterations = 12)
    T_state = warm_start === nothing ? standard_T.(reverse(zᵢ)) : copy(warm_start)
    evaluate(Tₛ) = begin
        r = equilibrate!(T_state, Tₛ; χCO₂, ozone, fixed_water_vapor)
        r.converged || error("inner equilibration at trial Tₛ = $Tₛ did not converge")
        F = r.asr - r.olr
        isfinite(F) || error("nonfinite TOA residual at trial Tₛ = $Tₛ")
        (F, r)
    end
    lo, hi = min(Tₛ_guesses...), max(Tₛ_guesses...)
    F_lo, r_lo = evaluate(lo)
    F_hi, r_hi = evaluate(hi)
    expansion = 8
    expansions = 0
    while sign(F_lo) == sign(F_hi)
        expansions < max_expansions ||
            error("no sign-changing Tₛ bracket after $max_expansions expansions")
        saturated = lo == 150 && hi == 350
        saturated &&
            error("Tₛ bracket saturated the [150, 350] K domain without a sign change")
        lo = max(lo - expansion, 150)
        hi = min(hi + expansion, 350)
        expansion *= 2
        expansions += 1
        F_lo, r_lo = evaluate(lo)
        F_hi, r_hi = evaluate(hi)
    end
    Tₛ, F, r = abs(F_lo) < abs(F_hi) ? (lo, F_lo, r_lo) : (hi, F_hi, r_hi)
    a, b, F_a, F_b = lo, hi, F_lo, F_hi
    iterations = 0
    step_size = Inf
    while abs(F) > imbalance_tolerance || step_size > 0.01
        iterations < max_iterations ||
            error("surface-temperature solve exceeded $max_iterations iterations")
        candidate = F_b == F_a ? (a + b) / 2 : b - F_b * (b - a) / (F_b - F_a)
        (a < candidate < b) || (candidate = (a + b) / 2)
        F_c, r_c = evaluate(candidate)
        if sign(F_c) == sign(F_a)
            a, F_a = candidate, F_c
        else
            b, F_b = candidate, F_c
        end
        step_size = abs(candidate - Tₛ)
        Tₛ, F, r = candidate, F_c, r_c
        iterations += 1
    end
    return (; r..., Tₛ, secant_iterations = iterations,
            bracket_expansions = expansions)
end

# Verification gates, executed silently; every one is build-failing.

function verify_equilibria(states; imbalance_gate = 0.1)
    for (name, r) in states
        r.converged || error("$name: final equilibration not converged")
        abs(r.asr - r.olr) < imbalance_gate ||
            error("$name: TOA imbalance $(r.asr - r.olr) W/m²")
        layer_means = (r.Tᵢ[1:N] .+ r.Tᵢ[2:nlev]) ./ 2
        isequal(layer_means, r.T_ext[2:N_ext]) ||
            error("$name: layer temperatures are not adjacent-level means")
        r.extension_temperature == r.Tᵢ[1] ||
            error("$name: lookup-boundary layer is not isothermal with the top level")
        inversion_limit = minimum(diff(r.Tᵢ)[pᵢ[1:nlev-1] .> 40_000])
        inversion_limit > -0.05 ||
            error("$name: tropospheric inversion-limit gate: $(inversion_limit) K per level")
    end
    control = last(first(states))
    weighted_emission = sum(gas_optics.longwave_weights .*
                            surface_longwave_emission(gas_optics, control.Tₛ))
    abs(weighted_emission - σ * control.Tₛ^4) < 0.2 ||
        error("weighted surface emission inconsistent with σTₛ⁴")
    return nothing
end
