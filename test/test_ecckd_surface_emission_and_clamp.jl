using Test
using NumericalRadiation
using NCDatasets

# Focused coverage for the two behaviors introduced by the spectral-boundary
# fix: surface_longwave_emission (tabulated and fallback source paths,
# weighting, emissivity, eltype) and the total optical-depth clamp
# (negative totals clamped, positive totals preserved).

const σ_SB = 5.670374419e-8

@testset "surface_longwave_emission" begin
    @testset "fallback source path (no source table)" begin
        for FT in (Float64, Float32)
            model = EcCKDTabulatedGasOpticsModel(
                names = (:h2o, :co2),
                pressure_grid = FT[10_000, 100_000],
                temperature_grid = FT[220, 300],
                longwave_absorption = ones(FT, 2, 2, 2, 2),
                shortwave_absorption = ones(FT, 2, 2, 2, 2),
                longwave_source_scale = FT[0.5, 1.0],
                longwave_weights = FT[0.25, 0.75],
                shortwave_weights = FT[0.5, 0.5],
            )
            emission = surface_longwave_emission(model, FT(290))
            @test emission isa Vector{FT}
            @test length(emission) == 2
            # Without a source table each g point emits scale * σT⁴.
            @test emission ≈ FT[0.5, 1.0] .* FT(σ_SB) * FT(290)^4 rtol = 1e-6
            # Emissivity scales linearly.
            scaled = surface_longwave_emission(model, FT(290); emissivity = FT(0.9))
            @test scaled ≈ FT(0.9) .* emission rtol = 1e-6
        end
    end

    @testset "tabulated source path (reference 32x32)" begin
        model = read_reference_ecckd_gas_optics("32x32";
            names = (:composite, :h2o, :o3, :co2, :ch4, :n2o, :cfc11, :cfc12))
        emission = surface_longwave_emission(model, 300.0)
        @test length(emission) == length(model.longwave_weights)
        @test all(>(0), emission)
        # The weighted broadband total must recover the file's integrated
        # Planck flux, which sits within the gray-vs-spectral closure
        # difference of σT⁴.
        broadband = sum(model.longwave_weights .* emission)
        @test isapprox(broadband, σ_SB * 300.0^4; atol = 0.2)
        # Spectral, not gray: per-unit-weight emission varies strongly
        # across g points.
        weighted = model.longwave_weights .* emission
        @test maximum(weighted) / minimum(weighted) > 10
        # Emissivity scaling on the tabulated path too.
        @test surface_longwave_emission(model, 300.0; emissivity = 0.98) ≈
              0.98 .* emission rtol = 1e-12
    end
end

@testset "total optical-depth clamp" begin
    nlayers = 1
    atmosphere_gases(ch4_amount) = (composite = [100.0], ch4 = [ch4_amount])
    # Synthetic tabulated model with a relative-linear CH4-like gas: with a
    # reference mole fraction and zero requested amount, the CH4 term is
    # -reference * composite * k and can exceed the composite term, driving
    # the summed optical depth negative before the clamp.
    model = EcCKDTabulatedGasOpticsModel(
        names = (:composite, :ch4),
        pressure_grid = [10_000.0, 100_000.0],
        temperature_grid = [220.0, 300.0],
        longwave_absorption = cat(fill(1e-4, 1, 1, 2, 2),   # composite: weak
                                  fill(1.0, 1, 1, 2, 2);    # ch4: strong
                                  dims = 2),
        shortwave_absorption = cat(fill(1e-4, 1, 1, 2, 2),
                                   fill(1.0, 1, 1, 2, 2);
                                   dims = 2),
        gas_reference_mole_fractions = [0.0, 1e-3],
        longwave_weights = [1.0],
        shortwave_weights = [1.0],
    )
    atmosphere(gases) = ColumnAtmosphere(
        pressure_layers = [50_000.0],
        pressure_interfaces = [45_000.0, 55_000.0],
        temperature_layers = [260.0],
        temperature_interfaces = [255.0, 265.0],
        gases = gases,
        surface = nothing,
        geometry = (;),
    )
    longwave = LongwaveOptics(zeros(1, nlayers), zeros(1, nlayers);
                                         weights = zeros(1))
    shortwave = ShortwaveOptics(zeros(1, nlayers);
                                           rayleigh_optical_depth = zeros(1, nlayers),
                                           scattering_asymmetry = zeros(1, nlayers),
                                           weights = zeros(1))

    # Zero CH4 amount: total = composite - reference * composite * k_ch4 < 0
    # before the clamp; the stored value must be exactly zero.
    optical_properties!(longwave, shortwave, model, atmosphere(atmosphere_gases(0.0)))
    @test longwave.optical_depth[1, 1] == 0.0
    @test shortwave.optical_depth[1, 1] == 0.0

    # CH4 at its reference abundance: the subtraction cancels and the
    # positive composite total must be preserved, not clamped.
    reference_amount = 1e-3 * 100.0
    optical_properties!(longwave, shortwave, model,
                        atmosphere(atmosphere_gases(reference_amount)))
    @test longwave.optical_depth[1, 1] > 0
    @test isapprox(longwave.optical_depth[1, 1], 1e-4 * 100.0; rtol = 1e-10)
    @test shortwave.optical_depth[1, 1] > 0
    @test isapprox(shortwave.optical_depth[1, 1], 1e-4 * 100.0; rtol = 1e-10)
end
