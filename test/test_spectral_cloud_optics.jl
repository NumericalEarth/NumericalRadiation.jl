module TestSpectralCloudOptics
using Test
using NumericalRadiation
using NCDatasets   # extension trigger for the ecRad table and ecCKD mapping readers

# `SpectralCloudOptics` (src/solvers/spectral_cloud_optics.jl) is the
# kernel-facing form of the g-point mapped cloud optics: one phase, one
# spectral mapping, `(κ, ω, g)` per g point on effective-radius nodes. These
# tests pin (1) that the node values are exactly those of
# `cloud_scattering_gpoint_properties`, (2) that a host loop over
# `effective_radius_bracket` / `cloud_layer_optics` / `add_scattering_layer`
# reproduces the array method `add_mapped_cloud_scattering!`, which is itself
# pinned to its pre-rewrite arithmetic at rtol 1e-12, (3) inferrability and
# zero allocation of every device-path function, and (4) that the reference
# ecRad droplet and ice tables map onto the climate_32x32 longwave and
# shortwave mappings.

const Adapt = NumericalRadiation.Adapt

function synthetic_table()
    return CloudScatteringTable(
        medium = "liquid-water",
        particle_type = "droplet",
        wavenumber = [100.0, 200.0, 300.0],
        effective_radius = [1.0e-6, 3.0e-6],
        mass_extinction_coefficient = [10.0 20.0; 30.0 40.0; 50.0 60.0],
        single_scattering_albedo = [0.95 0.9; 0.7 0.8; 0.4 0.5],
        asymmetry_factor = [0.85 0.8; 0.6 0.65; 0.3 0.4],
    )
end

function synthetic_mapping()
    return EcCKDSpectralMapping(
        wavenumber1 = [90.0, 190.0, 290.0],
        wavenumber2 = [110.0, 210.0, 310.0],
        gpoint_fraction = [1.0 0.0; 0.5 0.5; 0.0 1.0],
    )
end

# The pre-rewrite body of `add_mapped_cloud_scattering!` (matrix method),
# kept verbatim as the reference the loop over `add_scattering_layer` must
# reproduce. Its delta-Eddington and scattering-scale steps act on the
# combined liquid+ice mixture, so the rewrite (which applies them per phase)
# is compared with those keywords only where the two agree: one phase only,
# or an unclamped scattering scale.
function legacy_add_mapped_cloud_scattering!(shortwave,
                                             liquid_properties,
                                             ice_properties,
                                             liquid_water_path,
                                             ice_water_path,
                                             cloud_fraction;
                                             cloud_fraction_exponent = 1,
                                             liquid_extinction_scale = 1,
                                             ice_extinction_scale = 1,
                                             shortwave_scattering_scale = 1,
                                             delta_eddington_scale = false)
    ng, nlayers = size(shortwave.optical_depth)
    FT = eltype(shortwave)
    exponent = max(FT(cloud_fraction_exponent), zero(FT))
    liquid_scale = FT(liquid_extinction_scale)
    ice_scale = FT(ice_extinction_scale)
    scattering_scale = max(FT(shortwave_scattering_scale), zero(FT))
    for k in 1:nlayers
        fraction_scale = clamp(FT(cloud_fraction[k]), zero(FT), one(FT))^exponent
        lwp = max(FT(liquid_water_path[k]), zero(FT))
        iwp = max(FT(ice_water_path[k]), zero(FT))
        for ig in 1:ng
            liquid_ext = liquid_scale * FT(liquid_properties.mass_extinction_coefficient[ig]) * lwp
            ice_ext = ice_scale * FT(ice_properties.mass_extinction_coefficient[ig]) * iwp
            liquid_ssa = clamp(FT(liquid_properties.single_scattering_albedo[ig]),
                               zero(FT), one(FT))
            ice_ssa = clamp(FT(ice_properties.single_scattering_albedo[ig]),
                            zero(FT), one(FT))
            liquid_scat = liquid_ssa * liquid_ext
            ice_scat = ice_ssa * ice_ext
            scattering_sum = liquid_scat + ice_scat
            incoming_asymmetry = scattering_sum == zero(FT) ?
                zero(FT) :
                (clamp(FT(liquid_properties.asymmetry_factor[ig]), -one(FT), one(FT)) *
                 liquid_scat +
                 clamp(FT(ice_properties.asymmetry_factor[ig]), -one(FT), one(FT)) *
                 ice_scat) / scattering_sum
            total_extinction = liquid_ext + ice_ext
            if delta_eddington_scale && scattering_sum > zero(FT)
                forward_fraction = incoming_asymmetry^2
                total_extinction -= scattering_sum * forward_fraction
                scattering_sum *= one(FT) - forward_fraction
                incoming_asymmetry /= one(FT) + incoming_asymmetry
            end
            if scattering_scale != one(FT)
                scattering_sum = min(scattering_sum * scattering_scale,
                                     max(total_extinction, zero(FT)))
            end
            absorption_tau = fraction_scale *
                max(total_extinction - scattering_sum, zero(FT))
            scattering_tau = fraction_scale * scattering_sum

            shortwave.optical_depth[ig, k] += absorption_tau
            existing_scattering = shortwave.rayleigh_optical_depth[ig, k]
            total_scattering = existing_scattering + scattering_tau
            shortwave.scattering_asymmetry[ig, k] = total_scattering == zero(FT) ?
                zero(FT) :
                (shortwave.scattering_asymmetry[ig, k] * existing_scattering +
                 incoming_asymmetry * scattering_tau) / total_scattering
            shortwave.rayleigh_optical_depth[ig, k] = total_scattering
        end
    end
    return shortwave
end

# Deterministic "gas" background with non-trivial Rayleigh scattering and
# asymmetry so the mixing weights are exercised.
function background_shortwave(FT, ng, nlayers)
    optical_depth = FT[0.01 + 0.003 * ig + 0.02 * k for ig in 1:ng, k in 1:nlayers]
    scattering = FT[0.05 + 0.001 * ig * k for ig in 1:ng, k in 1:nlayers]
    asymmetry = FT[0.1 * ((ig + k) % 3) for ig in 1:ng, k in 1:nlayers]
    return ShortwaveOptics(optical_depth;
                           scattering_optical_depth = scattering,
                           scattering_asymmetry = asymmetry)
end

copy_shortwave(sw) = ShortwaveOptics(copy(sw.optical_depth);
                                     scattering_optical_depth = copy(sw.rayleigh_optical_depth),
                                     scattering_asymmetry = copy(sw.scattering_asymmetry))

function assert_shortwave_close(a, b; rtol)
    @test isapprox(a.optical_depth, b.optical_depth; rtol)
    @test isapprox(a.rayleigh_optical_depth, b.rayleigh_optical_depth; rtol)
    @test isapprox(a.scattering_asymmetry, b.scattering_asymmetry; rtol)
end

const LIQUID_PROPERTIES = (
    mass_extinction_coefficient = [10.0, 20.0, 15.0, 5.0],
    single_scattering_albedo = [0.8, 0.5, 0.99, 0.0],
    asymmetry_factor = [0.7, 0.6, 0.85, 0.2],
)
const ICE_PROPERTIES = (
    mass_extinction_coefficient = [30.0, 40.0, 25.0, 12.0],
    single_scattering_albedo = [0.6, 0.25, 0.9, 1.0],
    asymmetry_factor = [0.5, 0.4, 0.75, 0.9],
)
const LIQUID_PATH = [0.1, 0.0, 0.05, 0.2]
const ICE_PATH = [0.0, 0.2, 0.03, 0.1]
const CLOUD_FRACTION = [1.0, 0.5, 0.25, 0.0]

# Allocation probes are `@noinline` so the measured call is the function
# itself and not its inlining into the test body.
Base.@noinline measure_bracket(cloud, radius) = @allocated effective_radius_bracket(cloud, radius)
Base.@noinline measure_layer_optics(cloud, b) = @allocated cloud_layer_optics(cloud, 1, b)
Base.@noinline measure_absorption(cloud, b, wp) =
    @allocated cloud_absorption_optical_depth(cloud, 1, b, wp)
Base.@noinline measure_add_scattering(κ, ω, g, wp) =
    @allocated add_scattering_layer(wp, wp, wp, κ, ω, g, wp)

@testset "Spectral cloud optics" begin
    table = synthetic_table()
    mapping = synthetic_mapping()

    @testset "node values equal cloud_scattering_gpoint_properties" begin
        for (method, delta, thick) in ((:midpoint, false, false),
                                       (:ecrad, true, false),
                                       (:ecrad, true, true),
                                       (:ecrad, false, false))
            radius = 2.0e-6
            reference = cloud_scattering_gpoint_properties(table, mapping, radius;
                                                           mapping_method = method,
                                                           delta_eddington_average = delta,
                                                           thick_averaging = thick)
            cloud = SpectralCloudOptics(table, mapping; effective_radius = radius,
                                        mapping_method = method,
                                        delta_eddington_average = delta,
                                        thick_averaging = thick)
            @test cloud isa SpectralCloudOptics{Float64, Vector{Float64}, Matrix{Float64}}
            @test eltype(cloud) === Float64
            @test cloud.effective_radius == [radius]
            @test size(cloud.mass_extinction_coefficient) == (2, 1)
            @test vec(cloud.mass_extinction_coefficient) == reference.mass_extinction_coefficient
            @test vec(cloud.single_scattering_albedo) == reference.single_scattering_albedo
            @test vec(cloud.asymmetry_factor) == reference.asymmetry_factor
        end

        # The defaults are ecRad's: `:ecrad` weighting with delta-Eddington averaging.
        default = SpectralCloudOptics(table, mapping; effective_radius = 2.0e-6)
        explicit = SpectralCloudOptics(table, mapping; effective_radius = 2.0e-6,
                                       mapping_method = :ecrad,
                                       delta_eddington_average = true,
                                       thick_averaging = false)
        @test default.mass_extinction_coefficient == explicit.mass_extinction_coefficient
        @test default.single_scattering_albedo == explicit.single_scattering_albedo
        @test default.asymmetry_factor == explicit.asymmetry_factor

        # `float_type` converts the stored arrays.
        single = SpectralCloudOptics(table, mapping; effective_radius = 2.0e-6,
                                     float_type = Float32)
        @test single isa SpectralCloudOptics{Float32, Vector{Float32}, Matrix{Float32}}
        @test single.mass_extinction_coefficient ==
              Float32.(default.mass_extinction_coefficient)

        @test occursin("2 g points", sprint(show, default))
        @test occursin("1 effective-radius node", sprint(show, default))
    end

    @testset "array constructor validates shapes and nodes" begin
        radius = [1.0e-6, 5.0e-6, 20.0e-6]
        κ = [1.0 2.0 3.0; 4.0 5.0 6.0]
        ω = fill(0.5, 2, 3)
        g = fill(0.7, 2, 3)
        cloud = SpectralCloudOptics(radius, κ, ω, g)
        @test cloud isa SpectralCloudOptics{Float64}
        @test cloud.effective_radius == radius
        @test cloud.mass_extinction_coefficient == κ
        @test_throws DimensionMismatch SpectralCloudOptics(radius, κ[:, 1:2], ω, g)
        @test_throws DimensionMismatch SpectralCloudOptics(radius, κ, ω, g[:, 1:2])
        @test_throws ArgumentError SpectralCloudOptics(radius[[3, 2, 1]], κ, ω, g)
        @test_throws ArgumentError SpectralCloudOptics(Float64[], κ[:, 1:0], ω[:, 1:0], g[:, 1:0])
        mixed = SpectralCloudOptics(Float32.(radius), κ, ω, g)
        @test mixed isa SpectralCloudOptics{Float64}
        @test occursin("3 effective-radius nodes", sprint(show, cloud))
    end

    @testset "effective_radius_bracket" begin
        one_node = SpectralCloudOptics(table, mapping; effective_radius = 2.0e-6)
        for radius in (0.0, 1.0e-6, 2.0e-6, 1.0e-3)
            @test effective_radius_bracket(one_node, radius) === (1, 1, 0.0)
        end
        @test effective_radius_bracket(nothing, 2.0e-6) === (1, 1, 0)

        radius = [1.0e-6, 5.0e-6, 20.0e-6]
        three = SpectralCloudOptics(radius, ones(2, 3), ones(2, 3), ones(2, 3))
        @test effective_radius_bracket(three, 0.5e-6) === (1, 2, 0.0)
        @test effective_radius_bracket(three, 1.0e-6) === (1, 2, 0.0)
        @test effective_radius_bracket(three, 20.0e-6) === (2, 3, 1.0)
        @test effective_radius_bracket(three, 50.0e-6) === (2, 3, 1.0)
        i₀, i₁, w = effective_radius_bracket(three, 3.0e-6)
        @test (i₀, i₁) == (1, 2)
        @test w ≈ 0.5
        i₀, i₁, w = effective_radius_bracket(three, 12.5e-6)
        @test (i₀, i₁) == (2, 3)
        @test w ≈ 0.5

        # A Float32 model brackets a Float64 radius in Float32.
        three32 = SpectralCloudOptics(radius, ones(2, 3), ones(2, 3), ones(2, 3);
                                      float_type = Float32)
        @test effective_radius_bracket(three32, 3.0e-6) isa Tuple{Int, Int, Float32}
    end

    @testset "cloud_layer_optics and cloud_absorption_optical_depth" begin
        one_node = SpectralCloudOptics(table, mapping; effective_radius = 2.0e-6)
        bracket = effective_radius_bracket(one_node, 7.0e-6)
        for ig in 1:2
            κ, ω, g = cloud_layer_optics(one_node, ig, bracket)
            @test κ == one_node.mass_extinction_coefficient[ig, 1]
            @test ω == one_node.single_scattering_albedo[ig, 1]
            @test g == one_node.asymmetry_factor[ig, 1]
            wp = 0.3
            @test cloud_absorption_optical_depth(one_node, ig, bracket, wp) == κ * (1 - ω) * wp
        end
        @test cloud_absorption_optical_depth(nothing, 1, effective_radius_bracket(nothing, 1.0e-6), 0.3) === 0.0
        @test cloud_absorption_optical_depth(nothing, 1, (1, 1, 0), 0.3f0) === 0.0f0

        radius = [1.0e-6, 5.0e-6, 20.0e-6]
        κ = [1.0 2.0 3.0; 4.0 5.0 6.0]
        ω = [0.9 0.8 0.7; 0.6 0.5 0.4]
        g = [0.1 0.2 0.3; 0.4 0.5 0.6]
        three = SpectralCloudOptics(radius, κ, ω, g)
        @test cloud_layer_optics(three, 2, effective_radius_bracket(three, 5.0e-6)) == (5.0, 0.5, 0.5)
        κ_mid, ω_mid, g_mid = cloud_layer_optics(three, 1, effective_radius_bracket(three, 3.0e-6))
        @test κ_mid ≈ 1.5
        @test ω_mid ≈ 0.85
        @test g_mid ≈ 0.15
        @test cloud_layer_optics(three, 1, effective_radius_bracket(three, 1.0e-3)) == (3.0, 0.7, 0.3)
    end

    @testset "add_scattering_layer" begin
        τa, τs, g = add_scattering_layer(0.1, 0.2, 0.3, 10.0, 0.8, 0.7, 0.05)
        @test τa ≈ 0.1 + 10.0 * 0.2 * 0.05
        @test τs ≈ 0.2 + 10.0 * 0.8 * 0.05
        @test g ≈ (0.3 * 0.2 + 0.7 * 10.0 * 0.8 * 0.05) / τs

        # Zero scattering leaves the asymmetry at zero, not NaN.
        @test add_scattering_layer(0.0, 0.0, 0.0, 10.0, 0.0, 0.7, 0.05) === (0.5, 0.0, 0.0)
        @test add_scattering_layer(0.0, 0.0, 0.0, 10.0, 0.8, 0.7, 0.0) === (0.0, 0.0, 0.0)

        # Zero water path is a bit-exact no-op on a layer with existing scattering.
        for (τa₀, τs₀, g₀) in ((0.1, 0.3, 0.1), (1.0e-3, 0.7, 0.55), (2.0, 1.0e-4, -0.2))
            @test add_scattering_layer(τa₀, τs₀, g₀, 10.0, 0.8, 0.7, 0.0) === (τa₀, τs₀, g₀)
        end

        # A first constituent on an empty layer takes its own asymmetry exactly.
        @test add_scattering_layer(0.0, 0.0, 0.0, 10.0, 0.8, 0.7, 0.05)[3] == 0.7

        # Float32 inputs stay Float32.
        @test add_scattering_layer(0.1f0, 0.2f0, 0.3f0, 10.0f0, 0.8f0, 0.7f0, 0.05f0) isa
              Tuple{Float32, Float32, Float32}
    end

    @testset "add_mapped_cloud_scattering! reproduces its pre-rewrite arithmetic" begin
        ng, nlayers = 4, 4
        for FT in (Float64, Float32)
            base = background_shortwave(FT, ng, nlayers)
            rtol = FT === Float64 ? 1e-12 : 1e-5
            cases = (
                (;),
                (; cloud_fraction_exponent = 0.5),
                (; liquid_extinction_scale = 1.3, ice_extinction_scale = 0.7),
                (; shortwave_scattering_scale = 0.5),
                (; cloud_fraction_exponent = 2, liquid_extinction_scale = 2.0,
                   ice_extinction_scale = 0.5, shortwave_scattering_scale = 0.9),
            )
            for kwargs in cases
                new = copy_shortwave(base)
                old = copy_shortwave(base)
                add_mapped_cloud_scattering!(new, LIQUID_PROPERTIES, ICE_PROPERTIES,
                                             LIQUID_PATH, ICE_PATH, CLOUD_FRACTION; kwargs...)
                legacy_add_mapped_cloud_scattering!(old, LIQUID_PROPERTIES, ICE_PROPERTIES,
                                                    LIQUID_PATH, ICE_PATH, CLOUD_FRACTION; kwargs...)
                assert_shortwave_close(new, old; rtol)
            end

            # Delta-Eddington scaling is applied per phase, which coincides with the
            # combined-mixture scaling of the old method when only one phase is present.
            for (lwp, iwp) in ((LIQUID_PATH, zero(ICE_PATH)), (zero(LIQUID_PATH), ICE_PATH))
                new = copy_shortwave(base)
                old = copy_shortwave(base)
                add_mapped_cloud_scattering!(new, LIQUID_PROPERTIES, ICE_PROPERTIES,
                                             lwp, iwp, CLOUD_FRACTION; delta_eddington_scale = true)
                legacy_add_mapped_cloud_scattering!(old, LIQUID_PROPERTIES, ICE_PROPERTIES,
                                                    lwp, iwp, CLOUD_FRACTION; delta_eddington_scale = true)
                assert_shortwave_close(new, old; rtol)
            end
        end

        # Negative water paths are treated as zero; zero paths leave the layer unchanged.
        base = background_shortwave(Float64, ng, nlayers)
        untouched = copy_shortwave(base)
        add_mapped_cloud_scattering!(untouched, LIQUID_PROPERTIES, ICE_PROPERTIES,
                                     zeros(nlayers), fill(-1.0, nlayers), ones(nlayers))
        @test untouched.optical_depth == base.optical_depth
        @test untouched.rayleigh_optical_depth == base.rayleigh_optical_depth
        @test untouched.scattering_asymmetry == base.scattering_asymmetry
    end

    @testset "host loop over add_scattering_layer reproduces add_mapped_cloud_scattering!" begin
        # A `SpectralCloudOptics` per phase at fixed radius, with the array method fed
        # the same node values through `cloud_scattering_gpoint_properties`.
        liquid_table = synthetic_table()
        ice_table = CloudScatteringTable(
            medium = "ice",
            particle_type = "cloud-ice",
            wavenumber = [100.0, 200.0, 300.0],
            effective_radius = [10.0e-6, 60.0e-6],
            mass_extinction_coefficient = [5.0 2.0; 8.0 3.0; 12.0 4.0],
            single_scattering_albedo = [0.9 0.85; 0.6 0.7; 0.3 0.45],
            asymmetry_factor = [0.8 0.75; 0.7 0.72; 0.4 0.5],
        )
        liquid_radius, ice_radius = 2.0e-6, 30.0e-6
        liquid = SpectralCloudOptics(liquid_table, mapping; effective_radius = liquid_radius)
        ice = SpectralCloudOptics(ice_table, mapping; effective_radius = ice_radius)
        liquid_nodes = cloud_scattering_gpoint_properties(liquid_table, mapping, liquid_radius;
                                                          mapping_method = :ecrad,
                                                          delta_eddington_average = true)
        ice_nodes = cloud_scattering_gpoint_properties(ice_table, mapping, ice_radius;
                                                       mapping_method = :ecrad,
                                                       delta_eddington_average = true)
        ng, nlayers = 2, 4
        lwp = [0.1, 0.0, 0.05, 0.2]
        iwp = [0.0, 0.2, 0.03, 0.1]
        fraction = [1.0, 0.5, 0.25, 0.0]
        exponent = 0.5

        for FT in (Float64, Float32)
            base = background_shortwave(FT, ng, nlayers)
            array = copy_shortwave(base)
            add_mapped_cloud_scattering!(array, liquid_nodes, ice_nodes, lwp, iwp, fraction;
                                         cloud_fraction_exponent = exponent)

            kernel = copy_shortwave(base)
            liquid_bracket = effective_radius_bracket(liquid, liquid_radius)
            ice_bracket = effective_radius_bracket(ice, ice_radius)
            for k in 1:nlayers
                weight = clamp(FT(fraction[k]), 0, 1)^FT(exponent)
                lwpₖ = weight * FT(lwp[k])
                iwpₖ = weight * FT(iwp[k])
                for ig in 1:ng
                    τa = kernel.optical_depth[ig, k]
                    τs = kernel.rayleigh_optical_depth[ig, k]
                    g = kernel.scattering_asymmetry[ig, k]
                    κ, ω, gᶜ = cloud_layer_optics(liquid, ig, liquid_bracket)
                    τa, τs, g = add_scattering_layer(τa, τs, g, κ, ω, gᶜ, lwpₖ)
                    κ, ω, gᶜ = cloud_layer_optics(ice, ig, ice_bracket)
                    τa, τs, g = add_scattering_layer(τa, τs, g, κ, ω, gᶜ, iwpₖ)
                    kernel.optical_depth[ig, k] = τa
                    kernel.rayleigh_optical_depth[ig, k] = τs
                    kernel.scattering_asymmetry[ig, k] = g
                end
            end
            rtol = FT === Float64 ? 1e-12 : 1e-5
            assert_shortwave_close(kernel, array; rtol)
            # Cloud-free layers are untouched by both paths.
            @test kernel.optical_depth[:, 4] == base.optical_depth[:, 4]
            @test kernel.scattering_asymmetry[:, 4] == base.scattering_asymmetry[:, 4]
        end

        # The longwave absorption of a layer is the same κ(1 - ω) wp the shortwave
        # absorption update adds.
        bracket = effective_radius_bracket(liquid, liquid_radius)
        for ig in 1:ng
            κ, ω, gᶜ = cloud_layer_optics(liquid, ig, bracket)
            τa, τs, g = add_scattering_layer(0.0, 0.0, 0.0, κ, ω, gᶜ, 0.1)
            @test cloud_absorption_optical_depth(liquid, ig, bracket, 0.1) == τa
        end
    end

    @testset "device-path functions are inferrable and allocation-free" begin
        for FT in (Float64, Float32)
            one_node = SpectralCloudOptics(table, mapping; effective_radius = 2.0e-6,
                                           float_type = FT)
            three = SpectralCloudOptics([1.0e-6, 5.0e-6, 20.0e-6],
                                        rand(2, 3), rand(2, 3), rand(2, 3); float_type = FT)
            radius = 3.0e-6
            wp = FT(0.1)
            for cloud in (one_node, three)
                b = @inferred effective_radius_bracket(cloud, radius)
                @test b isa Tuple{Int, Int, FT}
                props = @inferred cloud_layer_optics(cloud, 1, b)
                @test props isa Tuple{FT, FT, FT}
                τ = @inferred cloud_absorption_optical_depth(cloud, 1, b, wp)
                @test τ isa FT
                κ, ω, g = props
                updated = @inferred add_scattering_layer(wp, wp, wp, κ, ω, g, wp)
                @test updated isa Tuple{FT, FT, FT}
                @test measure_bracket(cloud, radius) == 0
                @test measure_layer_optics(cloud, b) == 0
                @test measure_absorption(cloud, b, wp) == 0
                @test measure_add_scattering(κ, ω, g, wp) == 0
            end
            @test (@inferred effective_radius_bracket(nothing, radius)) === (1, 1, 0)
            @test (@inferred cloud_absorption_optical_depth(nothing, 1, (1, 1, 0), wp)) === zero(FT)
            @test measure_bracket(nothing, radius) == 0
            @test measure_absorption(nothing, (1, 1, 0), wp) == 0
        end
    end

    @testset "Adapt threads the element type from the adapted arrays" begin
        cloud = SpectralCloudOptics(table, mapping; effective_radius = 2.0e-6)
        same = Adapt.adapt(Array, cloud)
        @test same isa SpectralCloudOptics{Float64, Vector{Float64}, Matrix{Float64}}
        @test same.mass_extinction_coefficient == cloud.mass_extinction_coefficient
        retyped = Adapt.adapt(Array{Float32}, cloud)
        @test retyped isa SpectralCloudOptics{Float32, Vector{Float32}, Matrix{Float32}}
        @test eltype(retyped) === Float32
        @test retyped.effective_radius == Float32.(cloud.effective_radius)
        @test retyped.asymmetry_factor == Float32.(cloud.asymmetry_factor)
        b = effective_radius_bracket(retyped, 2.0e-6)
        @test cloud_layer_optics(retyped, 1, b) isa Tuple{Float32, Float32, Float32}
    end

    @testset "reference ecRad tables map onto climate_32x32" begin
        liquid_path = NumericalRadiation.ecrad_data_file("mie_droplet_scattering.nc";
                                                          require = false)
        ice_path = NumericalRadiation.ecrad_data_file(
            "baum-general-habit-mixture_ice_scattering.nc"; require = false)
        longwave_path = reference_ecckd_definition_path(:longwave_32; require = false)
        shortwave_path = reference_ecckd_definition_path(:shortwave_32; require = false)

        if any(isnothing, (liquid_path, ice_path, longwave_path, shortwave_path))
            @info "Skipping reference cloud optics mapping check; ecRad data files are not present" liquid_path ice_path longwave_path shortwave_path
            @test_skip "reference ecRad data files are not present"
        else
            liquid_table = read_cloud_scattering_table(liquid_path)
            ice_table = read_cloud_scattering_table(ice_path)
            longwave_mapping = read_ecckd_spectral_mapping(longwave_path)
            shortwave_mapping = read_ecckd_spectral_mapping(shortwave_path)
            liquid_radius, ice_radius = 10.0e-6, 30.0e-6

            clouds = (
                liquid_longwave = SpectralCloudOptics(liquid_table, longwave_mapping;
                                                      effective_radius = liquid_radius),
                liquid_shortwave = SpectralCloudOptics(liquid_table, shortwave_mapping;
                                                       effective_radius = liquid_radius),
                ice_longwave = SpectralCloudOptics(ice_table, longwave_mapping;
                                                   effective_radius = ice_radius),
                ice_shortwave = SpectralCloudOptics(ice_table, shortwave_mapping;
                                                    effective_radius = ice_radius),
            )
            for (name, cloud) in pairs(clouds)
                @test size(cloud.mass_extinction_coefficient) == (32, 1)
                @test all(isfinite, cloud.mass_extinction_coefficient)
                @test all(>(0), cloud.mass_extinction_coefficient)
                @test all(0 .<= cloud.single_scattering_albedo .<= 1)
                @test all(-1 .<= cloud.asymmetry_factor .<= 1)
                bracket = effective_radius_bracket(cloud, liquid_radius)
                @test bracket === (1, 1, 0.0)
                τ = [cloud_absorption_optical_depth(cloud, ig, bracket, 0.05) for ig in 1:32]
                @test all(isfinite, τ)
                @test all(>=(0), τ)
            end

            # Node values are those of cloud_scattering_gpoint_properties with the
            # ecRad defaults.
            reference = cloud_scattering_gpoint_properties(liquid_table, shortwave_mapping,
                                                           liquid_radius;
                                                           mapping_method = :ecrad,
                                                           delta_eddington_average = true)
            @test vec(clouds.liquid_shortwave.mass_extinction_coefficient) ==
                  reference.mass_extinction_coefficient
            @test vec(clouds.liquid_shortwave.single_scattering_albedo) ==
                  reference.single_scattering_albedo
            @test vec(clouds.liquid_shortwave.asymmetry_factor) == reference.asymmetry_factor

            # Droplets scatter conservatively in the shortwave and absorb in the
            # longwave, so the Planck-weighted longwave albedo is well below the
            # solar-weighted shortwave one on average (individual near-infrared
            # and window g points overlap).
            mean(x) = sum(x) / length(x)
            @test mean(clouds.liquid_longwave.single_scattering_albedo) <
                  mean(clouds.liquid_shortwave.single_scattering_albedo) - 0.2
            # A 50 g m⁻² liquid cloud is optically thick in the longwave.
            bracket = effective_radius_bracket(clouds.liquid_longwave, liquid_radius)
            τ_longwave = [cloud_absorption_optical_depth(clouds.liquid_longwave, ig, bracket, 0.05)
                          for ig in 1:32]
            @test minimum(τ_longwave) > 1
        end
    end
end

end # module TestSpectralCloudOptics
