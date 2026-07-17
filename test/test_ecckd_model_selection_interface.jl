@testset "ecCKD model selection interface" begin
    specs = official_ecckd_model_specs()
    @test haskey(specs, :climate_32x32)
    @test haskey(specs, :climate_64x64)
    @test haskey(specs, :climate_64x96)

    spec = official_ecckd_model_spec("32x96")
    @test spec.name == :climate_32x96
    @test spec.longwave == :longwave_32
    @test spec.shortwave == :shortwave_96

    @test official_ecckd_model_spec(:climate_64x32).longwave == :longwave_64
    @test official_ecckd_model_spec("64x96").shortwave == :shortwave_96
    @test_throws ArgumentError official_ecckd_model_spec("16x16")

    paths = official_ecckd_definition_paths("32x32"; require = false)
    @test hasproperty(paths, :longwave)
    @test hasproperty(paths, :shortwave)

    if isnothing(paths.longwave) || isnothing(paths.shortwave)
        @test read_official_ecckd_gas_optics("32x32"; require = false) === nothing
    elseif isnothing(Base.get_extension(NumericalRadiation, :NumericalRadiationNCDatasetsExt))
        @test_throws ArgumentError read_official_ecckd_gas_optics("32x32")
    else
        model = read_official_ecckd_gas_optics("32x32")
        @test model isa EcCKDTabulatedGasOpticsModel
        @test length(model.longwave_weights) == 32
        @test length(model.shortwave_weights) == 32
    end
end
