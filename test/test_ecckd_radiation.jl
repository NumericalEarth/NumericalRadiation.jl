module TestEcCKDRadiation

using Test
using NumericalRadiation
using NCDatasets     # reference ecCKD tables

@testset "ClearSkyEcCKDRadiation: configured clear-sky ecCKD scheme" begin
    gas_optics = read_reference_ecckd_gas_optics("32x32"; names = (:dry_air, :H₂O, :O₃, :CO₂))

    scheme = ClearSkyEcCKDRadiation(gas_optics)
    @test scheme isa AbstractRadiationScheme
    @test eltype(scheme) === Float64
    @test scheme.gas_optics === gas_optics
    @test keys(scheme.mole_fractions) == (:O₃, :CO₂)
    @test scheme.mole_fractions.O₃ === default_ozone_profile
    @test scheme.mole_fractions.CO₂ == 280e-6
    @test scheme.surface_emissivity == 0.98
    @test default_ozone_profile(3000.0) ≈ 8e-6
    @test default_ozone_profile(1e5) < 1e-7
    @test occursin("32 longwave × 32 shortwave", sprint(show, scheme))

    # number format conversion, overrides, numbers converted
    scheme32 = ClearSkyEcCKDRadiation{Float32}(gas_optics; mole_fractions = (; CO₂ = 400e-6), surface_emissivity = 0.97)
    @test eltype(scheme32) === Float32
    @test eltype(scheme32.gas_optics) === Float32
    @test scheme32.mole_fractions.CO₂ === 400f-6
    @test scheme32.surface_emissivity === 0.97f0
    @test ClearSkyEcCKDRadiation(gas_optics; ozone = 5e-6).mole_fractions.O₃ == 5e-6
    @test ClearSkyEcCKDRadiation(gas_optics; ozone = p -> 1e-6).mole_fractions.O₃(1.0) == 1e-6

    # from the reference tables directly
    @test eltype(ClearSkyEcCKDRadiation(Float32, "32x32")) === Float32
    @test gas_names(ClearSkyEcCKDRadiation(Float64, "32x32"; names = (:dry_air, :H₂O, :CO₂)).gas_optics) == (:dry_air, :H₂O, :CO₂)

    # every gas the host does not carry must be prescribed
    with_ch4 = read_reference_ecckd_gas_optics("32x32"; names = (:dry_air, :H₂O, :O₃, :CO₂, :CH₄))
    @test_throws ArgumentError ClearSkyEcCKDRadiation(with_ch4)
    @test ClearSkyEcCKDRadiation(with_ch4; mole_fractions = (; CH₄ = 1.8e-6)).mole_fractions.CH₄ == 1.8e-6
end

end # module
