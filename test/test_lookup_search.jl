module TestLookupSearch

using Test
using NumericalRadiation
using NCDatasets

const Adapt = NumericalRadiation.Adapt

function lookup_model(FT; lookup_search=BinarySearch(), matrix_temperature_grid=false)
    temperature_grid = matrix_temperature_grid ? FT[200 250 300; 210 260 310] : FT[200, 230, 300]
    return EcCKDTabulatedGasOpticsModel(
        names = (:dry_air,),
        pressure_grid = FT[10_000, 100_000],
        temperature_grid = temperature_grid,
        longwave_absorption = reshape(FT.(1:12) ./ 1000, 2, 1, 2, 3),
        shortwave_absorption = reshape(FT.(1:12) ./ 2000, 2, 1, 2, 3),
        longwave_source_temperature_grid = FT[200, 230, 270, 300],
        longwave_source_table = FT[10 20 60 100; 30 50 90 140],
        lookup_search = lookup_search,
    )
end

Base.@noinline bracket_allocation(grid, x, search) = @allocated NumericalRadiation.bracket(grid, x, search)

@testset "Fixed lookup search" begin
    @testset "brackets, endpoints, and nonfinite queries" for FT in (Float32, Float64)
        for count in (2:35..., 63, 64, 65, 231, 256, 257)
            grid = cumsum(FT[1 + mod(i, 5) / 8 for i in 1:count])
            midpoints = (grid[1:end-1] .+ grid[2:end]) ./ 2
            queries = [grid; midpoints; prevfloat.(grid); nextfloat.(grid);
                       FT[-Inf, Inf, NaN, grid[1] - 1, grid[end] + 1]]
            for x in queries
                fixed = @inferred NumericalRadiation.bracket(grid, x, FixedBinarySearch())
                dynamic = NumericalRadiation.bracket(grid, x)
                @test isequal(fixed, dynamic)
            end
        end
        grid = FT[0, 1, 3, 5]
        bracket_allocation(grid, FT(2), FixedBinarySearch())
        @test bracket_allocation(grid, FT(2), FixedBinarySearch()) == 0
    end

    @testset "model selection, adaptation, and optics" for FT in (Float32, Float64), matrix_grid in (false, true)
        dynamic = lookup_model(FT; matrix_temperature_grid=matrix_grid)
        fixed = lookup_model(FT; lookup_search=FixedBinarySearch(), matrix_temperature_grid=matrix_grid)
        @test dynamic.lookup_search === BinarySearch()
        @test fixed.lookup_search === FixedBinarySearch()
        @test_throws TypeError lookup_model(FT; lookup_search=:fixed)
        @test Adapt.adapt(Array, fixed).lookup_search === FixedBinarySearch()
        @test EcCKDTabulatedGasOpticsModel{Float32}(fixed).lookup_search === FixedBinarySearch()

        for temperature in FT[150, 200, 215, 230, 255, 270, 285, 300, 350, NaN]
            actual = @inferred source_table_bracket(fixed, temperature)
            @test isequal(actual, source_table_bracket(dynamic, temperature))
            for g in 1:2
                @test isequal(longwave_source(fixed, g, temperature, actual),
                              longwave_source(dynamic, g, temperature, source_table_bracket(dynamic, temperature)))
            end
            for pressure in FT[5_000, 30_000, 120_000]
                a = @inferred gas_optics_stencil(fixed, pressure, temperature, FT(0.001))
                b = gas_optics_stencil(dynamic, pressure, temperature, FT(0.001))
                @test all(name -> isequal(getfield(a, name), getfield(b, name)), fieldnames(typeof(a)))
            end
        end

        atmosphere = ColumnAtmosphere(
            layer_pressures = FT[15_000, 40_000, 85_000],
            interface_pressures = FT[10_000, 25_000, 60_000, 100_000],
            layer_temperatures = FT[215, 255, 285],
            interface_temperatures = FT[190, 235, 275, 320],
            gases = (dry_air = FT[10, 20, 30],),
            surface = (;), geometry = (;),
        )
        outputs = map((dynamic, fixed)) do model
            longwave = LongwaveOptics(zeros(FT, 2, 3), zeros(FT, 2, 3);
                                      source_top=zeros(FT, 2, 3), source_bottom=zeros(FT, 2, 3))
            shortwave = ShortwaveOptics(zeros(FT, 2, 3))
            @test (@inferred optical_properties!(longwave, shortwave, model, atmosphere)) isa Tuple
            fluxes = RadiativeFluxes(longwave_up=zeros(FT, 4), longwave_down=zeros(FT, 4),
                                     shortwave_up=zeros(FT, 4), shortwave_down=zeros(FT, 4))
            radiative_fluxes!(fluxes, CloudlessLongwave(), longwave, atmosphere,
                              LongwaveBoundaryConditions(surface_longwave_up=surface_longwave_emission(model, FT(320))))
            radiative_fluxes!(fluxes, CloudlessShortwave(), shortwave, atmosphere,
                              ShortwaveBoundaryConditions(toa_shortwave_down=FT(600), surface_albedo=FT(0.1)))
            heating = zeros(FT, 3)
            heating_rates!(heating, fluxes, atmosphere)
            return (; longwave, shortwave, fluxes, heating)
        end
        @test outputs[1].heating == outputs[2].heating
        for name in (:longwave, :shortwave, :fluxes)
            a, b = getproperty(outputs[1], name), getproperty(outputs[2], name)
            @test all(field -> isequal(getfield(a, field), getfield(b, field)), fieldnames(typeof(a)))
        end
    end

    @testset "cloud lookup selection" for FT in (Float32, Float64), count in (1, 4)
        radius = FT[1, 3, 7, 10][1:count] .* FT(1e-6)
        properties = reshape(FT.(1:2count), 2, count)
        dynamic = SpectralCloudOptics(radius, properties, properties ./ 10, properties ./ 10)
        fixed = SpectralCloudOptics(FT, radius, properties, properties ./ 10, properties ./ 10; lookup_search=FixedBinarySearch())
        inferred_type = SpectralCloudOptics(radius, properties, properties ./ 10, properties ./ 10; lookup_search=FixedBinarySearch())
        @test inferred_type.lookup_search === FixedBinarySearch()
        @test_throws TypeError SpectralCloudOptics(radius, properties, properties, properties; lookup_search=:fixed)
        @test Adapt.adapt(Array{Float32}, fixed).lookup_search === FixedBinarySearch()
        for query in FT[0, 1, 2, 5, 9, 10, 12, NaN] .* FT(1e-6)
            a = @inferred effective_radius_bracket(fixed, query)
            b = effective_radius_bracket(dynamic, query)
            @test isequal(a, b)
            @test isequal(cloud_layer_optics(fixed, 1, a), cloud_layer_optics(dynamic, 1, b))
        end
    end

    @testset "reference loader forwards lookup selection" begin
        paths = reference_ecckd_definition_paths("32x32"; require=false)
        if paths.longwave === nothing || paths.shortwave === nothing
            @test_skip "ecRad data artifact not installed"
        else
            fixed = read_reference_ecckd_gas_optics(Float32, "32x32"; lookup_search=FixedBinarySearch())
            dynamic = read_reference_ecckd_gas_optics(Float32, "32x32")
            @test fixed.lookup_search === FixedBinarySearch()
            @test dynamic.lookup_search === BinarySearch()
            @test surface_longwave_emission(fixed, 290f0) == surface_longwave_emission(dynamic, 290f0)
        end
    end
end

function uniform_lookup_model(FT; lookup_search=BinarySearch())
    return EcCKDTabulatedGasOpticsModel(
        names = (:dry_air,),
        pressure_grid = FT[10_000, 100_000],
        temperature_grid = FT[200, 250, 300],
        longwave_absorption = reshape(FT.(1:12) ./ 1000, 2, 1, 2, 3),
        shortwave_absorption = reshape(FT.(1:12) ./ 2000, 2, 1, 2, 3),
        longwave_source_temperature_grid = FT[200, 225, 250, 275, 300],
        longwave_source_table = FT[10 20 45 70 100; 30 50 70 105 140],
        lookup_search = lookup_search,
    )
end

@testset "Direct indexing of uniform tables" begin
    @testset "brackets and endpoints" for FT in (Float32, Float64)
        line(x) = 3x + 1
        for count in (2, 3, 4, 5, 17, 231)
            grid = FT.(collect(range(120, 350; length = count)))
            values = line.(grid)
            midpoints = (grid[1:end-1] .+ grid[2:end]) ./ 2
            for x in [grid; midpoints; FT[grid[1] - 7, grid[end] + 7, -Inf, Inf]]
                i₀, i₁, w = @inferred NumericalRadiation.bracket(grid, x, DirectIndexing())
                @test i₁ == i₀ + 1 && 0 <= w <= 1
                # Equal interpolants; on a node either neighbouring interval is exact
                @test (1 - w) * values[i₀] + w * values[i₁] ≈ line(clamp(x, grid[1], grid[end])) rtol = 8eps(FT)
            end
            for x in midpoints
                @test NumericalRadiation.bracket(grid, x, DirectIndexing())[1:2] == NumericalRadiation.bracket(grid, x)[1:2]
            end
        end
        @test isnan(NumericalRadiation.bracket(FT[1, 2, 3], FT(NaN), DirectIndexing())[3])
        bracket_allocation(FT[0, 1, 2, 3], FT(2), DirectIndexing())
        @test bracket_allocation(FT[0, 1, 2, 3], FT(2), DirectIndexing()) == 0
    end

    @testset "model selection and Planck sources" for FT in (Float32, Float64)
        direct = uniform_lookup_model(FT; lookup_search = DirectIndexing())
        searched = uniform_lookup_model(FT)
        @test direct.lookup_search === DirectIndexing()
        @test Adapt.adapt(Array, direct).lookup_search === DirectIndexing()
        @test EcCKDTabulatedGasOpticsModel{Float32}(direct).lookup_search === DirectIndexing()
        # Direct indexing needs uniform vector temperature and Planck-source grids
        @test_throws ArgumentError lookup_model(FT; lookup_search = DirectIndexing())
        @test_throws ArgumentError lookup_model(FT; lookup_search = DirectIndexing(), matrix_temperature_grid = true)
        for temperature in FT[150, 200, 212.5, 225, 260, 299, 300, 350]
            b = @inferred source_table_bracket(direct, temperature)
            for g in 1:2
                @test longwave_source(direct, g, temperature, b) ≈
                      longwave_source(searched, g, temperature, source_table_bracket(searched, temperature)) rtol = 8eps(FT)
            end
            for pressure in FT[5_000, 30_000, 120_000]
                a = gas_optics_stencil(direct, pressure, temperature, FT(0.001))
                c = gas_optics_stencil(searched, pressure, temperature, FT(0.001))
                @test longwave_optical_depth(direct, 1, (dry_air = FT(10),), a) ≈
                      longwave_optical_depth(searched, 1, (dry_air = FT(10),), c) rtol = 8eps(FT)
            end
        end
        @test isnan(source_table_bracket(direct, FT(NaN))[3])
    end

    @testset "cloud effective radii" for FT in (Float32, Float64)
        uniform = FT[1, 3, 5, 7] .* FT(1e-6)
        properties = reshape(FT.(1:8), 2, 4)
        direct = SpectralCloudOptics(FT, uniform, properties, properties ./ 10, properties ./ 10; lookup_search = DirectIndexing())
        searched = SpectralCloudOptics(FT, uniform, properties, properties ./ 10, properties ./ 10)
        @test Adapt.adapt(Array{Float32}, direct).lookup_search === DirectIndexing()
        @test_throws ArgumentError SpectralCloudOptics(FT, FT[1, 3, 7, 10] .* FT(1e-6), properties, properties, properties;
                                                       lookup_search = DirectIndexing())
        single = SpectralCloudOptics(FT, uniform[1:1], properties[:, 1:1], properties[:, 1:1], properties[:, 1:1];
                                     lookup_search = DirectIndexing())
        @test effective_radius_bracket(single, FT(4e-6)) == (1, 1, zero(FT))
        for query in FT[0, 1, 2, 4.5, 7, 9] .* FT(1e-6)
            a = effective_radius_bracket(direct, query)
            b = effective_radius_bracket(searched, query)
            @test all(cloud_layer_optics(direct, 1, a) .≈ cloud_layer_optics(searched, 1, b))
        end
    end
end

end # module
