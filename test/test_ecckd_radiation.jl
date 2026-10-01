module TestEcCKDRadiation

using Test
using NumericalRadiation
using NCDatasets     # reference ecCKD tables

@testset "ClearSkyEcCKDRadiation: configured clear-sky ecCKD scheme" begin
    gas_optics = read_reference_ecckd_gas_optics("32x32"; names = (:composite, :h2o, :o3, :co2))

    scheme = ClearSkyEcCKDRadiation(gas_optics)
    @test scheme isa AbstractRadiationScheme
    @test eltype(scheme) === Float64
    @test scheme.gas_optics === gas_optics
    @test keys(scheme.mole_fractions) == (:o3, :co2)
    @test scheme.mole_fractions.o3 === default_ozone_profile
    @test scheme.mole_fractions.co2 == 280e-6
    @test scheme.surface_emissivity == 0.98
    @test default_ozone_profile(3000.0) ≈ 8e-6
    @test default_ozone_profile(1e5) < 1e-7
    @test occursin("32 longwave × 32 shortwave", sprint(show, scheme))

    # number format conversion, overrides, numbers converted
    scheme32 = ClearSkyEcCKDRadiation{Float32}(gas_optics; mole_fractions = (; co2 = 400e-6), surface_emissivity = 0.97)
    @test eltype(scheme32) === Float32
    @test eltype(scheme32.gas_optics) === Float32
    @test scheme32.mole_fractions.co2 === 400f-6
    @test scheme32.surface_emissivity === 0.97f0
    @test ClearSkyEcCKDRadiation(gas_optics; ozone = 5e-6).mole_fractions.o3 == 5e-6
    @test ClearSkyEcCKDRadiation(gas_optics; ozone = p -> 1e-6).mole_fractions.o3(1.0) == 1e-6

    # from the reference tables directly
    @test eltype(ClearSkyEcCKDRadiation(Float32, "32x32")) === Float32
    @test gas_names(ClearSkyEcCKDRadiation(Float64, "32x32"; names = (:composite, :h2o, :co2)).gas_optics) == (:composite, :h2o, :co2)

    # every gas the host does not carry must be prescribed
    with_ch4 = read_reference_ecckd_gas_optics("32x32"; names = (:composite, :h2o, :o3, :co2, :ch4))
    @test_throws ArgumentError ClearSkyEcCKDRadiation(with_ch4)
    @test ClearSkyEcCKDRadiation(with_ch4; mole_fractions = (; ch4 = 1.8e-6)).mole_fractions.ch4 == 1.8e-6
end

end # module
