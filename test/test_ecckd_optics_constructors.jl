using Test
using NumericalRadiation

# Focused coverage for the ecCKD optics/flux convenience allocators added so
# host code doesn't have to hand-roll caller-owned work arrays:
# LongwaveOptics(model, atmosphere), ShortwaveOptics(model, atmosphere), and
# RadiativeFluxes(atmosphere). Exercises both ecCKD model families, mixed
# host/model precision, zero-initialized fluxes under partial (one-band) use,
# shape correctness, and @inferred.

synthetic_analytic_model(::Type{FT}) where FT =
    EcCKDGasOpticsModel(names = (:composite,),
                        longwave_absorption = ones(FT, 2, 1),
                        shortwave_absorption = ones(FT, 2, 1))

synthetic_tabulated_model(::Type{FT}) where FT =
    EcCKDTabulatedGasOpticsModel(names = (:composite,),
                                pressure_grid = FT[10_000, 100_000],
                                temperature_grid = FT[220, 300],
                                longwave_absorption = ones(FT, 2, 1, 2, 2),
                                shortwave_absorption = ones(FT, 2, 1, 2, 2))

synthetic_atmosphere(::Type{FT}) where FT =
    ColumnAtmosphere(pressure_layers = FT[30_000, 70_000],
                     pressure_interfaces = FT[10_000, 50_000, 90_000],
                     temperature_layers = FT[230, 270],
                     temperature_interfaces = FT[220, 250, 290],
                     gases = (composite = FT[50, 80],),
                     surface = nothing,
                     geometry = (cos_zenith = FT(0.6),))

@testset "ecCKD optics/flux convenience allocators" begin
    @testset "both model families, default construction" begin
        for model_fn in (synthetic_analytic_model, synthetic_tabulated_model)
            model = model_fn(Float64)
            atmosphere = synthetic_atmosphere(Float64)
            longwave = LongwaveOptics(model, atmosphere)
            shortwave = ShortwaveOptics(model, atmosphere)
            @test size(longwave.optical_depth) == (2, 2)
            @test size(shortwave.optical_depth) == (2, 2)
            @test longwave.source_top !== nothing
            @test longwave.source_bottom !== nothing
            optical_properties!(longwave, shortwave, model, atmosphere)
            @test all(isfinite, longwave.optical_depth)
            @test all(isfinite, shortwave.optical_depth)
        end
    end

    @testset "model/atmosphere precision mismatch" begin
        # Element type must follow the model, not the atmosphere: only the
        # model's element type is guaranteed to match what optical_properties!
        # writes, and it requires optics/model element types to agree.
        for (model_FT, atmosphere_FT) in ((Float64, Float32), (Float32, Float64))
            model = synthetic_tabulated_model(model_FT)
            atmosphere = synthetic_atmosphere(atmosphere_FT)
            longwave = LongwaveOptics(model, atmosphere)
            shortwave = ShortwaveOptics(model, atmosphere)
            @test eltype(longwave.optical_depth) == model_FT
            @test eltype(shortwave.optical_depth) == model_FT
            optical_properties!(longwave, shortwave, model, atmosphere)
            @test all(isfinite, longwave.optical_depth)
        end
    end

    @testset "RadiativeFluxes is zero-initialized; one-band use stays zero" begin
        atmosphere = synthetic_atmosphere(Float64)
        model = synthetic_tabulated_model(Float64)
        fluxes = RadiativeFluxes(atmosphere)
        @test all(iszero, fluxes.longwave_up)
        @test all(iszero, fluxes.longwave_down)
        @test all(iszero, fluxes.shortwave_up)
        @test all(iszero, fluxes.shortwave_down)

        longwave = LongwaveOptics(model, atmosphere)
        shortwave = ShortwaveOptics(model, atmosphere)
        optical_properties!(longwave, shortwave, model, atmosphere)
        longwave_boundary = LongwaveBoundaryConditions(surface_longwave_up = zeros(2))
        radiative_fluxes!(fluxes, CloudlessLongwave(), longwave, atmosphere, longwave_boundary)

        # The untouched shortwave pair must remain exactly zero, not
        # uninitialized memory, so a longwave-only caller's heating_rates!
        # sees a clean zero shortwave contribution.
        @test all(iszero, fluxes.shortwave_up)
        @test all(iszero, fluxes.shortwave_down)
        @test any(!iszero, fluxes.longwave_up)

        heating = zeros(2)
        heating_rates!(heating, fluxes, atmosphere; gravity = 9.80665, heat_capacity = 1004.0)
        @test all(isfinite, heating)
    end

    @testset "@inferred" begin
        model = synthetic_tabulated_model(Float64)
        atmosphere = synthetic_atmosphere(Float64)
        @inferred LongwaveOptics(model, atmosphere)
        @inferred ShortwaveOptics(model, atmosphere)
        @inferred RadiativeFluxes(atmosphere)
    end

    @testset "explicit no-interface-source construction is still available" begin
        # The convenience constructor always includes interface sources for a
        # concrete, @inferred-stable return type; a no-source LongwaveOptics
        # is built explicitly from bare arrays instead.
        longwave = LongwaveOptics(zeros(2, 2), zeros(2, 2))
        @test longwave.source_top === nothing
        @test longwave.source_bottom === nothing
    end
end
