using Test
using NumericalRadiation
using Dates

include_test(filename::AbstractString) = include(joinpath(@__DIR__, filename))

@testset "NumericalRadiation" begin
    include_test("test_solvers.jl")
    include_test("test_ecckd_io.jl")
    include_test("test_misc.jl")
    include_test("test_rrtmgp_adapter.jl")
    include_test("test_ecckd_surface_emission_and_clamp.jl")
    include_test("test_streaming.jl")
    include_test("test_spectral_cloud_optics.jl")
    include_test("test_exact_solutions.jl")
end

@testset "SpeedyWeather Extension" begin
    include_test("test_with_speedyweather.jl")
end
