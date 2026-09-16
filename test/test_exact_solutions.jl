module TestExactSolutions
using Test
using NumericalRadiation

# Exact-answer tests of the streaming column solvers. Every case is built from
# hand-written layer-optics functors (and, where the physics is gray, from an
# `EcCKDGasOpticsModel` with one gas so the scalar `*_optical_depth` and
# `longwave_source` functions are on the path), needs no data artifact, and is
# compared with a closed form that is derived in a comment next to the test.
# Every layer has `Δτ > 1e-3`, so `no_scattering_lw_sources` always takes its
# exact linear-in-τ branch, never the thin-layer Taylor branch.
#
# Each case runs in Float64 at the tolerance of the contract table and in
# Float32 at `200 eps(Float32)`. Float32 tolerances are relative to the flux
# scale of the case (`σT⁴` or `S₀μ₀`): where a closed form is zero or is a
# small residual of O(1) fluxes, a relative tolerance would be meaningless, so
# the same `200 eps(Float32)` is applied as an absolute tolerance times that
# scale. Closed forms are always evaluated in Float64 from the exact Float32
# inputs the solver saw.

const σ = 5.670374419e-8   # Stefan–Boltzmann constant, W m⁻² K⁻⁴
const D = 1.66             # longwave diffusivity factor of the solver

const FLOAT_TYPES = (Float64, Float32)

#####
##### Deterministic pseudo-random draws (no Random dependency in the test project)
#####

mutable struct LinearCongruentialDraws
    state :: UInt64
end

# Knuth's MMIX multiplier; the top 53 bits give a uniform Float64 in [0, 1).
function draw!(rng::LinearCongruentialDraws)
    rng.state = rng.state * 0x5851f42d4c957f2d + 0x14057b7ef767814f
    return Float64(rng.state >> 11) / 2.0^53
end

draw!(rng::LinearCongruentialDraws, lo, hi) = lo + (hi - lo) * draw!(rng)

#####
##### Tolerances
#####

# `rtol` is the Float64 tolerance of the contract table; Float32 always uses
# `200 eps(Float32)`. `scale` is the case's flux scale, used only to give the
# Float32 comparison an absolute floor (see the header).
# `@test` cannot splat keyword tolerances inline, so comparisons go through this.
within(a, b, tol) = isapprox(a, b; tol...)

function tolerances(::Type{FT}, rtol, scale; atol = zero(rtol)) where FT
    FT === Float64 && return (; rtol, atol)
    tol = 200 * eps(Float32)
    return (; rtol = tol, atol = tol * scale)
end

#####
##### Gray gas model and layer-optics functors
#####

# One-gas ecCKD model whose scalar optics are `τ = κ n` per g point, with
# `longwave_source = scale σT⁴` (scale 1) and `rayleigh_optical_depth = 0`.
function gray_model(::Type{FT}, κ_longwave::AbstractVector, κ_shortwave::AbstractVector;
                    longwave_weights = nothing) where FT
    return EcCKDGasOpticsModel(names = (:composite,),
                               longwave_absorption = reshape(FT.(κ_longwave), :, 1),
                               shortwave_absorption = reshape(FT.(κ_shortwave), :, 1),
                               longwave_weights = longwave_weights === nothing ? nothing :
                                                  FT.(longwave_weights))
end

# `(ig, k) -> (τ, B_top, B_bottom)` from the gray model: layer amounts `n[k]`
# (mol m⁻², so `τ = κ_ig n[k]`) and Planck temperatures at the layer top and
# bottom. Isothermal layers pass the same vector twice.
struct GrayLongwaveLayerOptics{M, V, T}
    model :: M
    amounts :: V
    temperature_top :: T
    temperature_bottom :: T
end

@inline function (optics::GrayLongwaveLayerOptics)(ig, k)
    τ = longwave_optical_depth(optics.model, ig, (composite = optics.amounts[k],), nothing)
    B_top = longwave_source(optics.model, ig, optics.temperature_top[k], nothing)
    B_bottom = longwave_source(optics.model, ig, optics.temperature_bottom[k], nothing)
    return (τ, B_top, B_bottom)
end

# `(ig, k) -> (τ, B_top, B_bottom)` with the Planck function prescribed
# directly at the layer interfaces, for the linear-in-τ profile.
struct PlanckProfileLayerOptics{V}
    optical_depth :: V
    source_top :: V
    source_bottom :: V
end

@inline (optics::PlanckProfileLayerOptics)(ig, k) =
    (optics.optical_depth[k], optics.source_top[k], optics.source_bottom[k])

# `(ig, k) -> (τ_absorption, τ_scattering, asymmetry)` from the gray model:
# pure absorption `τ = κₛ n[k]`, no Rayleigh scattering, `g = 0`.
struct GrayShortwaveLayerOptics{M, V}
    model :: M
    amounts :: V
end

@inline function (optics::GrayShortwaveLayerOptics)(ig, k)
    n = optics.amounts[k]
    τ_absorption = shortwave_optical_depth(optics.model, ig, (composite = n,), nothing)
    τ_scattering = rayleigh_optical_depth(optics.model, ig, n)
    return (τ_absorption, τ_scattering, zero(τ_absorption))
end

# `(ig, k) -> (τ_absorption, τ_scattering, asymmetry)` prescribed per layer.
struct ScatteringLayerOptics{V}
    absorption :: V
    scattering :: V
    asymmetry :: V
end

@inline (optics::ScatteringLayerOptics)(ig, k) =
    (optics.absorption[k], optics.scattering[k], optics.asymmetry[k])

#####
##### Solver drivers
#####

function longwave_fluxes(::Type{FT}, layer_optics, surface_emission, surface_albedo, toa_down,
                         weights, nlayers) where FT
    flux_up = zeros(FT, nlayers + 1)
    flux_down = zeros(FT, nlayers + 1)
    transmittance = zeros(FT, nlayers)
    source_up = zeros(FT, nlayers)
    streaming_longwave_fluxes!(flux_up, flux_down, layer_optics, surface_emission,
                               FT(surface_albedo), FT(toa_down), weights, length(weights),
                               nlayers, transmittance, source_up)
    return flux_up, flux_down
end

function shortwave_fluxes(::Type{FT}, layer_optics, μ0, toa_irradiance, direct_albedo, diffuse_albedo,
                          nlayers; weights = [one(FT)]) where FT
    flux_up = zeros(FT, nlayers + 1)
    flux_down = zeros(FT, nlayers + 1)
    scratch = ShortwaveColumnScratch(FT, nlayers)
    streaming_shortwave_fluxes!(flux_up, flux_down, layer_optics, FT(μ0), FT(toa_irradiance),
                                FT(direct_albedo), FT(diffuse_albedo), weights, length(weights),
                                nlayers, scratch)
    return flux_up, flux_down
end

# Optical depths of every layer as the solver saw them, in Float64, for
# g point `ig`, and their cumulative sum at the interfaces (0 at the top).
function layer_optical_depths(layer_optics, nlayers, ig = 1)
    τ = [Float64(layer_optics(ig, k)[1]) for k in 1:nlayers]
    return τ, vcat(0.0, cumsum(τ))
end

#####
##### Longwave closed forms
#####
#
# The solver integrates the two-stream Schwarzschild equations with the
# diffusivity factor D on each layer, with the Planck function B linear in the
# optical depth τ measured downward from the top of the atmosphere:
#
#   dF↓/dτ = D (B - F↓),       dF↑/dτ = D (F↑ - B),       B(τ) = B₀ + β τ.
#
# Integrating factors e^{±Dτ} give, with F↓(0) the downwelling flux entering
# the top and F↑(τₛ) the upwelling flux leaving the surface at τ = τₛ,
#
#   F↓(τ) = B(τ) - β/D + e^{-Dτ}        (F↓(0)  - B(0)  + β/D),
#   F↑(τ) = B(τ) + β/D + e^{-D(τₛ - τ)} (F↑(τₛ) - B(τₛ) - β/D).
#
# A layer with a Planck function linear between its interfaces is a special
# case of the same equations, so the solver's per-layer transmittance
# `e^{-Dτ}` and sources `no_scattering_lw_sources` are its exact solution
# restricted to one layer, and chaining exact solutions of a linear ODE with
# the correct interface values reproduces the global closed form exactly.
# Setting β = 0 gives the isothermal profile: F↑ = B everywhere when
# F↑(τₛ) = B, and F↓(τ) = B (1 - e^{-Dτ}) when nothing enters the top.

function linear_planck_down(τ, F_top, B₀, β)
    return B₀ + β * τ - β / D + exp(-D * τ) * (F_top - B₀ + β / D)
end

function linear_planck_up(τ, τₛ, F_surface, B₀, β)
    Bₛ = B₀ + β * τₛ
    return B₀ + β * τ + β / D + exp(-D * (τₛ - τ)) * (F_surface - Bₛ - β / D)
end

#####
##### Tests
#####

@testset "Exact solutions: no-scattering longwave" begin
    for FT in FLOAT_TYPES
        @testset "isothermal column ($FT)" begin
            # Twelve layers of pseudo-random optical depth in [0.01, 5] at 280 K
            # with a black surface at the same temperature and nothing entering
            # the top; two g points with different absorption and weights
            # (0.4, 0.6) so the weighted accumulation is on the path.
            # Closed forms (β = 0):  up[k] = σT⁴ for every k, and
            #   down[k] = σT⁴ Σ_g w_g (1 - e^{-D τ_g,cum[k]}),  τ_g,cum[1] = 0.
            rng = LinearCongruentialDraws(0x2f6e2b1a5c3d4e01)
            nlayers = 12
            T = 280.0
            amounts = FT[draw!(rng, 0.01, 5.0) for _ in 1:nlayers]   # τ of g point 1
            κ = [1.0, 0.35]
            weights = [0.4, 0.6]
            model = gray_model(FT, κ, [1.0]; longwave_weights = weights)
            temperatures = fill(FT(T), nlayers)
            optics = GrayLongwaveLayerOptics(model, amounts, temperatures, temperatures)
            surface = TabulatedSurfaceEmission(model, T; emissivity = 1)
            up, down = longwave_fluxes(FT, optics, surface, 0, 0, model.longwave_weights, nlayers)

            B = σ * T^4
            τ_cum = [layer_optical_depths(optics, nlayers, ig)[2] for ig in 1:2]
            down_exact = [B * sum(weights[ig] * (1 - exp(-D * τ_cum[ig][k])) for ig in 1:2)
                          for k in 1:nlayers + 1]

            tol_up = tolerances(FT, 1e-13, B)
            tol_down = tolerances(FT, 1e-12, B)
            @test all(k -> within(up[k], B, tol_up), 1:nlayers + 1)
            @test down[1] == 0
            @test all(k -> within(down[k], down_exact[k], tol_down), 2:nlayers + 1)
        end

        @testset "black lid ($FT)" begin
            # Isothermal column below a black lid radiating at the same
            # temperature (`toa_down = σT⁴`): the radiation field is in
            # equilibrium with the Planck function, so up = down = σT⁴ at every
            # interface and the net flux down - up vanishes identically.
            rng = LinearCongruentialDraws(0x7a1b3c5d7e9f0123)
            nlayers = 6
            T = 265.0
            amounts = FT[draw!(rng, 0.05, 3.0) for _ in 1:nlayers]
            model = gray_model(FT, [1.0], [1.0])
            temperatures = fill(FT(T), nlayers)
            optics = GrayLongwaveLayerOptics(model, amounts, temperatures, temperatures)
            surface = TabulatedSurfaceEmission(model, T; emissivity = 1)
            B_model = longwave_source(model, 1, FT(T), nothing)   # the lid emits what the model emits
            up, down = longwave_fluxes(FT, optics, surface, 0, B_model, model.longwave_weights, nlayers)

            B = σ * T^4
            tol = tolerances(FT, 0, B; atol = 1e-9)
            @test all(k -> within(up[k], B, tol), 1:nlayers + 1)
            @test all(k -> within(down[k], B, tol), 1:nlayers + 1)
            @test all(k -> within(down[k] - up[k], 0, tol), 1:nlayers + 1)
        end

        @testset "surface reflection ($FT)" begin
            # Optically thick (τ = 50, Dτ = 83) isothermal layers at T over a
            # gray surface with ε = 0.9 and longwave albedo 0.1 at the same T.
            # The downwelling flux at the surface is σT⁴ (1 - e^{-83}) = σT⁴ to
            # double precision, so the surface boundary condition gives
            #   up[end] = ε σT⁴ + (1 - ε) down[end] = 0.9 σT⁴ + 0.1 σT⁴ = σT⁴:
            # a gray surface in equilibrium with a black cavity is
            # indistinguishable from a black one.
            nlayers = 2
            T = 300.0
            ε = 0.9
            amounts = fill(FT(50), nlayers)
            model = gray_model(FT, [1.0], [1.0])
            temperatures = fill(FT(T), nlayers)
            optics = GrayLongwaveLayerOptics(model, amounts, temperatures, temperatures)
            surface = TabulatedSurfaceEmission(model, T; emissivity = ε)
            up, down = longwave_fluxes(FT, optics, surface, 1 - ε, 0, model.longwave_weights, nlayers)

            B = σ * T^4
            tol = tolerances(FT, 1e-12, B)
            @test within(down[end], B, tol)
            @test within(up[end], ε * B + (1 - ε) * down[end], tol)
            @test within(up[end], B, tol)
        end

        @testset "linear-in-τ Planck profile ($FT)" begin
            # Eight non-uniform layers with B(τ) = B₀ + βτ prescribed at every
            # interface, a nonzero flux entering the top, and a gray surface
            # (ε = 0.9, albedo 0.1) with its own Planck source Bₛ. With
            #   F↑(τₛ) = ε Bₛ + (1 - ε) F↓(τₛ),
            # the closed forms in the header hold at every interface.
            rng = LinearCongruentialDraws(0x0123456789abcdef)
            nlayers = 8
            B₀, β = 250.0, 12.0
            F_top = 30.0
            ε, Bₛ = 0.9, 420.0
            τ = [draw!(rng, 0.01, 2.0) for _ in 1:nlayers]
            τ_FT = FT.(τ)
            τ = Float64.(τ_FT)          # the optical depths the solver sees
            τ_cum = vcat(0.0, cumsum(τ))
            B_interface = B₀ .+ β .* τ_cum
            optics = PlanckProfileLayerOptics(τ_FT,
                                              FT.(B_interface[1:nlayers]),
                                              FT.(B_interface[2:nlayers + 1]))
            surface_emission = [FT(ε * Bₛ)]
            up, down = longwave_fluxes(FT, optics, surface_emission, 1 - ε, F_top, [one(FT)], nlayers)

            τₛ = τ_cum[end]
            down_exact = [linear_planck_down(τ_cum[k], F_top, B₀, β) for k in 1:nlayers + 1]
            F_surface = ε * Bₛ + (1 - ε) * down_exact[end]
            up_exact = [linear_planck_up(τ_cum[k], τₛ, F_surface, B₀, β) for k in 1:nlayers + 1]

            tol = tolerances(FT, 1e-12, maximum(B_interface))
            @test all(k -> within(down[k], down_exact[k], tol), 1:nlayers + 1)
            @test all(k -> within(up[k], up_exact[k], tol), 1:nlayers + 1)
        end

        @testset "optically thin limit ($FT)" begin
            # Four isothermal layers at Tₐ, each of τ = 1.01e-3 (just above the
            # thin-layer switch, so the exact branch is used), over a gray
            # surface at Tₛ with ε = 0.95, albedo 0.05, nothing entering the
            # top. With Bₐ = σTₐ⁴, Bₛ = σTₛ⁴, x = D τₛ and the header closed
            # forms (β = 0):
            #   down[end] = Bₐ (1 - e^{-x}),
            #   up[1]     = Bₐ + e^{-x} (ε Bₛ + (1 - ε) down[end] - Bₐ).
            # Expanding in x:
            #   down[end] = x Bₐ - x²/2 Bₐ + O(x³),
            #   up[1]     = ε Bₛ + x (Bₐ - ε Bₛ + (1 - ε) Bₐ) + O(x²),
            # so the column is transparent to leading order — up[1] → ε Bₛ and
            # down[end] → 0 — with first-order departures pinned below to their
            # second-order remainders, |O(x²)| ≤ x² max(Bₐ, Bₛ) (1 + 2(1 - ε)).
            nlayers = 4
            Tₐ, Tₛ = 250.0, 300.0
            ε = 0.95
            amounts = fill(FT(1.01e-3), nlayers)
            model = gray_model(FT, [1.0], [1.0])
            temperatures = fill(FT(Tₐ), nlayers)
            optics = GrayLongwaveLayerOptics(model, amounts, temperatures, temperatures)
            surface = TabulatedSurfaceEmission(model, Tₛ; emissivity = ε)
            up, down = longwave_fluxes(FT, optics, surface, 1 - ε, 0, model.longwave_weights, nlayers)

            Bₐ, Bₛ = σ * Tₐ^4, σ * Tₛ^4
            _, τ_cum = layer_optical_depths(optics, nlayers)
            τₛ = τ_cum[end]
            x = D * τₛ
            @test all(k -> layer_optical_depths(optics, nlayers)[1][k] > 1e-3, 1:nlayers)

            # Exact closed forms at every interface.
            down_exact = [Bₐ * (1 - exp(-D * τ_cum[k])) for k in 1:nlayers + 1]
            F_surface = ε * Bₛ + (1 - ε) * down_exact[end]
            up_exact = [Bₐ + exp(-D * (τₛ - τ_cum[k])) * (F_surface - Bₐ) for k in 1:nlayers + 1]
            tol = tolerances(FT, 0, max(Bₐ, Bₛ); atol = 1e-6)
            @test all(k -> within(down[k], down_exact[k], tol), 1:nlayers + 1)
            @test all(k -> within(up[k], up_exact[k], tol), 1:nlayers + 1)

            # The limits with their first-order departures.
            remainder = x^2 * max(Bₐ, Bₛ) * (1 + 2 * (1 - ε))
            @test isapprox(up[1], ε * Bₛ; atol = 2 * x * max(Bₐ, Bₛ))
            @test isapprox(down[end], 0; atol = 2 * x * Bₐ)
            @test isapprox(up[1] - ε * Bₛ, x * (Bₐ - ε * Bₛ + (1 - ε) * Bₐ); atol = remainder)
            @test isapprox(down[end], x * Bₐ; atol = remainder)
        end

        @testset "optically thick limit ($FT)" begin
            # Three isothermal layers of τ = 50 (Dτ = 83, e^{-83} ≈ 1e-36) at
            # T_top, T_int, T_bot over a gray surface (ε = 0.9, albedo 0.1) at
            # Tₛ. Each layer is opaque, so every interface flux is the Planck
            # emission of the adjacent layer on its own side:
            #   up[1] = σT_top⁴,   down[2] = σT_top⁴,   up[2] = down[3] = σT_int⁴,
            #   up[3] = down[4] = σT_bot⁴,   up[4] = ε σTₛ⁴ + (1 - ε) σT_bot⁴.
            nlayers = 3
            T_top, T_int, T_bot, Tₛ = 230.0, 260.0, 290.0, 300.0
            ε = 0.9
            amounts = fill(FT(50), nlayers)
            model = gray_model(FT, [1.0], [1.0])
            temperatures = FT[T_top, T_int, T_bot]
            optics = GrayLongwaveLayerOptics(model, amounts, temperatures, temperatures)
            surface = TabulatedSurfaceEmission(model, Tₛ; emissivity = ε)
            up, down = longwave_fluxes(FT, optics, surface, 1 - ε, 0, model.longwave_weights, nlayers)

            B_top, B_int, B_bot, Bₛ = σ .* (T_top, T_int, T_bot, Tₛ) .^ 4
            tol = tolerances(FT, 1e-8, Bₛ)
            @test down[1] == 0
            @test within(up[1], B_top, tol)
            @test within(down[2], B_top, tol)
            @test within(up[2], B_int, tol)
            @test within(down[3], B_int, tol)
            @test within(up[3], B_bot, tol)
            @test within(down[4], B_bot, tol)
            @test within(up[4], ε * Bₛ + (1 - ε) * B_bot, tol)
        end
    end
end

#####
##### Shortwave closed forms
#####
#
# Beer–Lambert (ω = 0). With no scattering the two-stream coefficients are
# γ₁ = 2, γ₂ = 0, k = 2, so each layer has diffuse reflectance 0, diffuse
# transmittance e^{-2τ} (the two-stream diffusivity is 2), no direct-to-diffuse
# conversion, and direct transmittance e^{-τ/μ₀}. Hence with the direct beam
# S₀μ₀ at the top and τ_k the cumulative optical depth above interface k,
#   down[k] = S₀ μ₀ e^{-τ_k/μ₀}                            (all direct),
# the surface reflects α down[end] into the diffuse upward stream, and that
# diffuse flux is attenuated by e^{-2(τₛ - τ_k)} on its way up:
#   up[k] = α S₀ μ₀ e^{-τₛ/μ₀} e^{-2(τₛ - τ_k)}.
#
# Conservative scattering (ω = 1, black surface). Nothing is absorbed, so
# the net downward flux down[k] - up[k] is the same at every interface and
# equals the flux absorbed by the black surface, down[end]; at the top the
# net flux is S₀μ₀ - up[1]. Hence up[1] + down[end] = S₀μ₀.
#
# Reciprocity. Every homogeneous two-stream layer has the same diffuse
# transmittance T_k from either side, and the adding formula for two slabs,
# T₁₂ = T₁ T₂ / (1 - R₁ᵇ R₂ᵗ) (R₁ᵇ the lower slab albedo of the upper slab, R₂ᵗ
# the upper albedo of the lower one), is symmetric under swapping the slabs
# and their sides, so by induction the diffuse transmittance of any stack is
# the same from above and from below although its two albedos differ. The
# solver exposes the from-below transmittance through the surface source:
# with diffuse albedo 0 and direct albedo 1 the surface injects the upward
# diffuse flux J = S₀μ₀ Π_k e^{-τ'_k/μ₀} (τ' the delta-Eddington-scaled depth)
# and nothing that returns to it is re-reflected, so its adding recursion
#   source[k] = T_k source[k+1] / (1 - R_k stack_albedo[k+1])
# carries exactly T_below J to the top. Subtracting the run with direct albedo
# 0 removes the beam's own reflection, and reversing the layer order turns
# T_below into T_above; J is a product and hence order independent.

@testset "Exact solutions: shortwave adding" begin
    for FT in FLOAT_TYPES
        @testset "Beer–Lambert on the adding path ($FT)" begin
            rng = LinearCongruentialDraws(0x5eed5eed5eed5eed)
            nlayers = 6
            μ0, S₀, α = 0.6, 1361.0, 0.3
            amounts = FT[draw!(rng, 0.01, 1.0) for _ in 1:nlayers]
            model = gray_model(FT, [1.0], [1.0])
            optics = GrayShortwaveLayerOptics(model, amounts)
            up, down = shortwave_fluxes(FT, optics, μ0, S₀ * μ0, α, α, nlayers;
                                        weights = model.shortwave_weights)

            _, τ_cum = layer_optical_depths(optics, nlayers)
            τₛ = τ_cum[end]
            down_exact = [S₀ * μ0 * exp(-τ_cum[k] / μ0) for k in 1:nlayers + 1]
            up_exact = [α * S₀ * μ0 * exp(-τₛ / μ0) * exp(-2 * (τₛ - τ_cum[k])) for k in 1:nlayers + 1]

            tol = tolerances(FT, 1e-10, S₀ * μ0)
            @test down[1] == FT(S₀ * μ0)
            @test all(k -> within(down[k], down_exact[k], tol), 1:nlayers + 1)
            @test all(k -> within(up[k], up_exact[k], tol), 1:nlayers + 1)
        end

        @testset "conservative scattering ($FT)" begin
            nlayers = 4
            μ0, S₀ = 0.5, 1361.0
            scattering = FT[0.3, 1.0, 0.5, 2.0]
            absorption = zeros(FT, nlayers)
            tol = tolerances(FT, 1e-10, S₀ * μ0)
            for g in (-0.5, 0.0, 0.5, 0.85, 0.95)
                asymmetry = fill(FT(g), nlayers)
                optics = ScatteringLayerOptics(absorption, scattering, asymmetry)
                up, down = shortwave_fluxes(FT, optics, μ0, S₀ * μ0, 0, 0, nlayers)
                net = down .- up
                @test within(up[1] + down[end], S₀ * μ0, tol)
                @test all(k -> within(net[k], net[end], tol), 1:nlayers + 1)
                @test down[1] == FT(S₀ * μ0)
            end
        end

        @testset "reciprocity of the stack diffuse transmittance ($FT)" begin
            rng = LinearCongruentialDraws(0x9e3779b97f4a7c15)
            nlayers = 5
            μ0, S₀ = 0.7, 1000.0
            τ = [draw!(rng, 0.05, 1.0) for _ in 1:nlayers]
            ω = [draw!(rng, 0.3, 0.95) for _ in 1:nlayers]
            g = [draw!(rng, -0.3, 0.85) for _ in 1:nlayers]
            absorption = FT.((1 .- ω) .* τ)
            scattering = FT.(ω .* τ)
            asymmetry = FT.(g)

            function transmittance_from_below(order)
                optics = ScatteringLayerOptics(absorption[order], scattering[order], asymmetry[order])
                up_black, _ = shortwave_fluxes(FT, optics, μ0, S₀ * μ0, 0, 0, nlayers)
                up_source, _ = shortwave_fluxes(FT, optics, μ0, S₀ * μ0, 1, 0, nlayers)
                return up_source[1] - up_black[1]     # T_below · J
            end

            T_below = transmittance_from_below(1:nlayers)
            T_above = transmittance_from_below(nlayers:-1:1)
            tol = tolerances(FT, 1e-12, S₀ * μ0)
            @test T_below > 0
            @test within(T_below, T_above, tol)
        end
    end
end

end # module
