#####
##### Shared helpers of the line-by-line benchmark scripts
#####
#
# Included by `ckdmip_evaluation1.jl` and `rfmip_irf.jl`. Everything a
# benchmark needs besides its own file layout lives here: building a
# `ColumnAtmosphere` from half-level pressures, temperatures and dry-air mole
# fractions with the moist-molar-mass column-amount convention; running one
# column through `optical_properties!` and the streaming solvers; the CKDMIP
# error statistics; gating through `RadiationThresholds`/`passes_thresholds`;
# and the JSON/Markdown report writers.

using NumericalRadiation
using NCDatasets
using Dates
using Printf
using Statistics
using Test

# The package's Earth defaults, which `hydrostatic_air_moles` and
# `heating_rates!` also read from every benchmark column.
const CONSTANTS = PhysicalConstants()
const GRAVITY = CONSTANTS.gravity                        # m s⁻²
const DRY_AIR_MOLAR_MASS = CONSTANTS.dry_air_molar_mass  # kg mol⁻¹ (mᵈ)
const WATER_MOLAR_MASS = CONSTANTS.water_molar_mass      # kg mol⁻¹ (mᵛ)
const HEAT_CAPACITY = CONSTANTS.heat_capacity            # J kg⁻¹ K⁻¹ (cₚ)
const SECONDS_PER_DAY = 86_400.0

# The gas set of the reference ecCKD "climate" models: dry air (`composite`,
# N₂ + O₂ at fixed ratio) plus the seven absorbers the tables carry.
const ECCKD_GAS_NAMES = (:composite, :h2o, :o3, :co2, :ch4, :n2o, :cfc11, :cfc12)

# Reports go to NUMERICAL_RADIATION_VALIDATION_RESULTS_DIR when set, otherwise
# to `validation/results/` in the package checkout.
function validation_results_dir()
    default = joinpath(dirname(@__DIR__), "validation", "results")
    dir = normpath(get(ENV, "NUMERICAL_RADIATION_VALIDATION_RESULTS_DIR", default))
    mkpath(dir)
    return dir
end

#####
##### Columns
#####

"""
    benchmark_column(pressure_interfaces, temperature_interfaces, mole_fractions;
                     pressure_layers, temperature_layers, surface, geometry,
                     column_amount_convention = :dry)

A top-down `ColumnAtmosphere` from half-level pressures (Pa) and temperatures
(K) and a `NamedTuple` of per-layer mole fractions relative to dry air. Layer
pressures and temperatures default to the arithmetic mean of the bounding
half levels, which is what the ecRad driver does with CKDMIP input.

The dry-air molar amount `nᵈ` of a layer of pressure thickness `Δp` follows
`column_amount_convention`, and every gas is `χ_gas nᵈ`:

* `:dry` — `nᵈ = Δp / (g mᵈ)`. This is how ecRad applies the ecCKD tables
  and how the ecCKD tool derived their molar absorption coefficients from
  the CKDMIP line-by-line optical depths (`average_optical_depth.cpp`), so
  it reproduces the reference optical depths and is the convention the
  gated benchmark runs use.
* `:moist` — `nᵈ = Δp / (g (mᵈ + mᵛ χ_H₂O))`, the moist-molar-mass
  convention of RRTMGP's column amounts, under which the layer mass closes
  as `mᵈ nᵈ + mᵛ n_H₂O = Δp / g`. It
  carries up to ~3 % less absorber than `:dry` in the humid boundary layer,
  which shows up as a small surface-flux bias; the benchmarks report it
  alongside.
"""
function benchmark_column(pressure_interfaces, temperature_interfaces, mole_fractions;
                          pressure_layers = nothing, temperature_layers = nothing,
                          surface, geometry, column_amount_convention = :dry)
    p_hl = Float64.(pressure_interfaces)
    T_hl = Float64.(temperature_interfaces)
    Nz = length(p_hl) - 1
    p_fl = pressure_layers === nothing ? 0.5 .* (p_hl[1:Nz] .+ p_hl[2:end]) : Float64.(pressure_layers)
    T_fl = temperature_layers === nothing ? 0.5 .* (T_hl[1:Nz] .+ T_hl[2:end]) : Float64.(temperature_layers)
    Δp = diff(p_hl)
    χ_H₂O = Float64.(mole_fractions.h2o) .* ones(Nz)
    dry_air = if column_amount_convention === :dry
        Δp ./ (GRAVITY * DRY_AIR_MOLAR_MASS)
    elseif column_amount_convention === :moist
        Δp ./ (GRAVITY .* (DRY_AIR_MOLAR_MASS .+ WATER_MOLAR_MASS .* χ_H₂O))
    else
        throw(ArgumentError("column_amount_convention must be :dry or :moist"))
    end
    gases = (; composite = dry_air,
               (name => Float64.(getproperty(mole_fractions, name)) .* dry_air
                for name in keys(mole_fractions))...)
    return ColumnAtmosphere(; pressure_layers = p_fl,
                              pressure_interfaces = p_hl,
                              temperature_layers = T_fl,
                              temperature_interfaces = T_hl,
                              gases, surface, geometry, constants = CONSTANTS)
end

#####
##### One column through the optics and the streaming solvers
#####

# Layer-optics functors over the `(Ngpoints, Nz)` arrays `optical_properties!`
# fills, in the form the streaming solvers take.
struct LongwaveLayerOptics{L}
    longwave :: L
end
@inline (o::LongwaveLayerOptics)(gpoint, k) = (o.longwave.optical_depth[gpoint, k],
                                               o.longwave.source_top[gpoint, k],
                                               o.longwave.source_bottom[gpoint, k])

struct ShortwaveLayerOptics{S}
    shortwave :: S
end
@inline (o::ShortwaveLayerOptics)(gpoint, k) = (o.shortwave.optical_depth[gpoint, k],
                                                o.shortwave.rayleigh_optical_depth[gpoint, k],
                                                o.shortwave.scattering_asymmetry[gpoint, k])

# Optics arrays and solver scratch for a model and layer count, allocated once
# and reused for every profile of a benchmark.
struct ColumnWorkspace{L, S, V, C}
    longwave :: L
    shortwave :: S
    transmittance :: V
    source_up :: V
    scratch :: C
end

function ColumnWorkspace(model, Nz)
    FT = eltype(model)
    Nlongwave_gpoints, Nshortwave_gpoints = length(model.longwave_weights), length(model.shortwave_weights)
    longwave = LongwaveOptics(zeros(FT, Nlongwave_gpoints, Nz), zeros(FT, Nlongwave_gpoints, Nz);
                              source_top = zeros(FT, Nlongwave_gpoints, Nz),
                              source_bottom = zeros(FT, Nlongwave_gpoints, Nz),
                              weights = zeros(FT, Nlongwave_gpoints))
    shortwave = ShortwaveOptics(zeros(FT, Nshortwave_gpoints, Nz); weights = zeros(FT, Nshortwave_gpoints))
    return ColumnWorkspace(longwave, shortwave, zeros(FT, Nz), zeros(FT, Nz),
                           ShortwaveColumnScratch(FT, Nz))
end

"""
    column_fluxes!(workspace, model, atmosphere; surface_temperature, emissivity,
                   albedo, cos_zeniths, solar_constant)

Clear-sky broadband fluxes of one column: `optical_properties!` once, then
`streaming_longwave_fluxes!` (surface emission `ε B_g(Tₛ)`, longwave surface
albedo `1 - ε`, no downwelling flux at the top) and, for each `μ₀` in
`cos_zeniths`, `streaming_shortwave_fluxes!` with the horizontal TOA
irradiance `S₀ max(μ₀, 0)` and one albedo for direct and diffuse light.
Returns `(; longwave_up, longwave_down, shortwave_up, shortwave_down)` with
the longwave vectors of length `Nz + 1` and the shortwave matrices of
size `(Nz + 1, length(cos_zeniths))`, all top-down and positive in their
own direction.
"""
function column_fluxes!(workspace::ColumnWorkspace, model, atmosphere;
                        surface_temperature, emissivity, albedo, cos_zeniths, solar_constant)
    FT = eltype(model)
    Nz = length(atmosphere.temperature_layers)
    optical_properties!(workspace.longwave, workspace.shortwave, model, atmosphere)

    longwave_up = zeros(FT, Nz + 1)
    longwave_down = zeros(FT, Nz + 1)
    surface_emission = TabulatedSurfaceEmission(model, surface_temperature; emissivity)
    streaming_longwave_fluxes!(longwave_up, longwave_down, LongwaveLayerOptics(workspace.longwave),
                               surface_emission, FT(1 - emissivity), zero(FT),
                               model.longwave_weights, length(model.longwave_weights), Nz,
                               workspace.transmittance, workspace.source_up)

    shortwave_up = zeros(FT, Nz + 1, length(cos_zeniths))
    shortwave_down = zeros(FT, Nz + 1, length(cos_zeniths))
    for (j, μ₀) in enumerate(cos_zeniths)
        streaming_shortwave_fluxes!(view(shortwave_up, :, j), view(shortwave_down, :, j),
                                    ShortwaveLayerOptics(workspace.shortwave), FT(μ₀),
                                    FT(solar_constant) * max(FT(μ₀), zero(FT)), FT(albedo), FT(albedo),
                                    model.shortwave_weights, length(model.shortwave_weights), Nz,
                                    workspace.scratch)
    end
    return (; longwave_up, longwave_down, shortwave_up, shortwave_down)
end

"""
    gauss_legendre_flux_nodes(n)

Angular quadrature of the hemispheric flux integral `F = 2π ∫₀¹ I(μ) μ dμ`
as `n` `(secant, weight)` pairs from the Gauss–Legendre nodes `μᵢ` on
`[0, 1]`: `F = Σ aᵢ I(μᵢ)` with `aᵢ = 2 μᵢ wᵢ`, so that isotropic radiance
`B` gives `F = B` (`Σ aᵢ = 1`). Three or four nodes integrate the angular
dependence of a no-scattering layer essentially exactly, which is what
line-by-line flux codes such as LBLRTM's RADSUM do, in place of the
diffusivity approximation `D = 1.66` of the two-stream solvers.
"""
function gauss_legendre_flux_nodes(n)
    nodes = Tuple{Float64, Float64}[]
    for i in 1:n
        # Newton iteration for the i-th root of Pₙ on [-1, 1].
        z = cos(π * (i - 0.25) / (n + 0.5))
        pp = 0.0
        for _ in 1:100
            p1, p2 = 1.0, 0.0
            for j in 1:n
                p3 = p2
                p2 = p1
                p1 = ((2j - 1) * z * p2 - (j - 1) * p3) / j
            end
            pp = n * (z * p1 - p2) / (z^2 - 1)
            step = p1 / pp
            z -= step
            abs(step) < 1e-15 && break
        end
        w = 2 / ((1 - z^2) * pp^2)
        μ = 0.5 * (z + 1)
        push!(nodes, (1 / μ, 2 * μ * 0.5 * w))
    end
    abs(sum(last, nodes) - 1) < 1e-12 || error("quadrature weights do not sum to one")
    return nodes
end

"""
    longwave_quadrature_fluxes!(up, down, longwave, weights, Ngpoints, Nz,
                                surface_emission, surface_albedo, nodes)

No-scattering longwave fluxes of one column with the layer transfer of
`streaming_longwave_fluxes!` (Planck function linear in optical depth
between the interfaces, thin-layer limit below `τ = 10⁻³`) evaluated at
each `(secant, weight)` node of `nodes` instead of the diffusivity 1.66, and
Lambertian surface reflection of the angle-integrated downwelling flux. With
`nodes = [(1.66, 1.0)]` it reproduces the streaming solver; with
[`gauss_legendre_flux_nodes`](@ref) it isolates the angular-integration part
of a difference to a line-by-line reference.
"""
function longwave_quadrature_fluxes!(up, down, longwave, weights, Ngpoints, Nz,
                                     surface_emission, surface_albedo, nodes)
    fill!(up, 0)
    fill!(down, 0)
    Nnodes = length(nodes)
    transmittance = zeros(Nz, Nnodes)
    source_up = zeros(Nz, Nnodes)
    for gpoint in 1:Ngpoints
        # Downward sweeps at every node; the reflected part of the total
        # downwelling flux at the surface is isotropic.
        down_surface = 0.0
        for (a, (secant, weight)) in enumerate(nodes)
            w = weights[gpoint] * weight
            d = 0.0
            for k in 1:Nz
                τ = longwave.optical_depth[gpoint, k]
                B_top, B_bottom = longwave.source_top[gpoint, k], longwave.source_bottom[gpoint, k]
                coefficient = secant * τ
                layer_transmittance = exp(-coefficient)
                if τ > 1e-3
                    gradient = (B_bottom - B_top) / coefficient
                    layer_source_up = gradient + B_top - layer_transmittance * (gradient + B_bottom)
                    layer_source_down = -gradient + B_bottom - layer_transmittance * (-gradient + B_top)
                else
                    layer_source_up = coefficient * 0.5 * (B_top + B_bottom)
                    layer_source_down = layer_source_up
                end
                transmittance[k, a] = layer_transmittance
                source_up[k, a] = layer_source_up
                d = d * layer_transmittance + layer_source_down
                down[k + 1] += w * d
            end
            down_surface += weight * d
        end
        surface_up = surface_emission[gpoint] + surface_albedo * down_surface
        for (a, (_, weight)) in enumerate(nodes)
            w = weights[gpoint] * weight
            u = surface_up
            up[Nz + 1] += w * u
            for k in Nz:-1:1
                u = u * transmittance[k, a] + source_up[k, a]
                up[k] += w * u
            end
        end
    end
    return up, down
end

"""
    heating_rate_per_day(up, down, atmosphere)

Layer heating rate (K day⁻¹) of one band from its interface fluxes, through
`heating_rates!` with the gravity and heat capacity of the column's
`PhysicalConstants`. The same function is applied to the candidate and the
reference, so those constants cancel in every error statistic.
"""
function heating_rate_per_day(up, down, atmosphere)
    Nz = length(atmosphere.temperature_layers)
    heating = zeros(Nz)
    zero_flux = zeros(Nz + 1)
    fluxes = RadiativeFluxes(longwave_up = Float64.(up), longwave_down = Float64.(down),
                             shortwave_up = zero_flux, shortwave_down = zero_flux)
    heating_rates!(heating, fluxes, atmosphere)
    return heating .* SECONDS_PER_DAY
end

#####
##### Error statistics
#####

rmse(x, y) = sqrt(mean((x .- y) .^ 2))
bias(x, y) = mean(x .- y)

"""
    weighted_heating_rate_rmse(pressure_interfaces, heating, reference, pressure_range)

The CKDMIP heating-rate error statistic (`calc_hr_error.m` of the ecRad
CKDMIP test suite): a root-mean-square error over the layers whose mid-level
pressure lies in `pressure_range = (low, high)` (Pa; `low ≤ p < high`),
weighting each layer by its increment of the cube root of pressure, with the
weights normalized per profile and the mean taken over profiles. All arrays
are `(n, Nprofiles)` matrices with `n = Nz + 1` for the interfaces;
`exclude_lowest` drops that many layers next to the surface from the statistic.
"""
function weighted_heating_rate_rmse(pressure_interfaces, heating, reference, pressure_range;
                                    exclude_lowest = 0)
    Nz, Nprofiles = size(heating)
    low, high = pressure_range
    total = 0.0
    for j in 1:Nprofiles
        weights = zeros(Nz)
        for k in 1:Nz - exclude_lowest
            p_top, p_bottom = pressure_interfaces[k, j], pressure_interfaces[k + 1, j]
            p_mid = 0.5 * (p_top + p_bottom)
            if low <= p_mid < high
                weights[k] = cbrt(p_bottom) - cbrt(p_top)
            end
        end
        weights ./= sum(weights)
        for k in 1:Nz
            total += weights[k] * (heating[k, j] - reference[k, j])^2
        end
    end
    return sqrt(total / Nprofiles)
end

# Pressure ranges (Pa) of the heating-rate statistics. The two gated ranges
# are those of the contract; the CKDMIP ranges are reported for comparison
# with Hogan and Matricardi (2020, 2022).
const HEATING_RATE_RANGES = (
    troposphere = (10_000.0, Inf),          # p > 100 hPa
    stratosphere = (4.0, 10_000.0),         # 4 Pa < p ≤ 100 hPa
    ckdmip_upper = (2.0, 400.0),            # 0.02–4 hPa
    ckdmip_lower = (400.0, 110_000.0),      # 4–1100 hPa
)

#####
##### Gates
#####

# One gate row: a `RadiationErrorMetrics` carrying only the statistics the
# row checks, and a `RadiationThresholds` that is `Inf` everywhere else.
struct Gate
    name :: String
    metrics :: RadiationErrorMetrics{Float64}
    thresholds :: RadiationThresholds{Float64}
end

function flux_gate(name; rmse, bias = 0.0, rmse_threshold, bias_threshold = Inf)
    metrics = RadiationErrorMetrics{Float64}(rmse, 0.0, bias, 0.0, 0.0, 0.0, 0.0, 0.0)
    thresholds = RadiationThresholds(flux_rmse = rmse_threshold, flux_absolute_bias = bias_threshold)
    return Gate(name, metrics, thresholds)
end

function heating_rate_gate(name; rmse, rmse_threshold)
    metrics = RadiationErrorMetrics{Float64}(0.0, 0.0, 0.0, rmse, 0.0, 0.0, 0.0, 0.0)
    thresholds = RadiationThresholds(heating_rate_rmse = rmse_threshold)
    return Gate(name, metrics, thresholds)
end

gate_passes(gate::Gate) = passes_thresholds(gate.metrics, gate.thresholds)

# The observed value(s) and threshold(s) of a gate as report strings.
function gate_summary(gate::Gate)
    m, t = gate.metrics, gate.thresholds
    if isfinite(t.heating_rate_rmse)
        return (observed = @sprintf("RMSE %.4f", m.heating_rate_rmse),
                threshold = @sprintf("RMSE ≤ %.2f", t.heating_rate_rmse),
                units = "K day⁻¹")
    elseif isfinite(t.flux_absolute_bias)
        return (observed = @sprintf("bias %+.3f, RMSE %.3f", m.flux_bias, m.flux_rmse),
                threshold = @sprintf("|bias| ≤ %.2f, RMSE ≤ %.2f", t.flux_absolute_bias, t.flux_rmse),
                units = "W m⁻²")
    else
        return (observed = @sprintf("RMSE %.3f", m.flux_rmse),
                threshold = @sprintf("RMSE ≤ %.2f", t.flux_rmse),
                units = "W m⁻²")
    end
end

function report_gates(gates)
    for gate in gates
        ok, _ = gate_passes(gate)
        s = gate_summary(gate)
        @printf("  %-48s %-32s %-24s %s\n", gate.name, s.observed * " " * s.units, s.threshold, ok ? "pass" : "FAIL")
    end
    return nothing
end

#####
##### Reports
#####

json_escape(text) = replace(text, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")

function json_value(value, indent)
    if value isa AbstractString || value isa Symbol
        return "\"" * json_escape(String(value)) * "\""
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value isa Integer
        return string(value)
    elseif value isa Real
        return isfinite(value) ? @sprintf("%.10g", value) : "null"
    elseif value isa NamedTuple || value isa AbstractDict
        return json_object(value, indent)
    elseif value isa AbstractVector || value isa Tuple
        return "[" * join((json_value(v, indent) for v in value), ", ") * "]"
    elseif value === nothing
        return "null"
    else
        return "\"" * json_escape(string(value)) * "\""
    end
end

function json_object(object, indent = 0)
    pad = " " ^ (indent + 2)
    entries = String[]
    for (key, value) in pairs(object)
        push!(entries, pad * "\"" * json_escape(String(key)) * "\": " * json_value(value, indent + 2))
    end
    return "{\n" * join(entries, ",\n") * "\n" * " " ^ indent * "}"
end

write_json(path, object) = (write(path, json_object(object) * "\n"); path)

markdown_row(cells) = "| " * join(cells, " | ") * " |"

function markdown_gate_table(gates)
    lines = [markdown_row(("Gate", "Observed", "Threshold", "Result")),
             markdown_row(("---", "---", "---", "---"))]
    for gate in gates
        ok, _ = gate_passes(gate)
        s = gate_summary(gate)
        push!(lines, markdown_row((gate.name, s.observed * " " * s.units, s.threshold, ok ? "pass" : "**FAIL**")))
    end
    return join(lines, "\n")
end

# Gate rows as JSON-ready objects.
gate_records(gates) = [(; name = g.name,
                          flux_rmse = g.metrics.flux_rmse,
                          flux_bias = g.metrics.flux_bias,
                          heating_rate_rmse = g.metrics.heating_rate_rmse,
                          flux_rmse_threshold = g.thresholds.flux_rmse,
                          flux_abs_bias_threshold = g.thresholds.flux_absolute_bias,
                          heating_rate_rmse_threshold = g.thresholds.heating_rate_rmse,
                          passes = first(gate_passes(g)))
                       for g in gates]

# NetCDF variables come back with `missing` for fill values; the benchmarks
# have none, so convert and check.
function dense(values)
    any(ismissing, values) && throw(ArgumentError("reference file contains missing values"))
    return Float64.(values)
end
