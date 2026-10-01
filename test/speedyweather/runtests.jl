# Runs the SpeedyWeather extension tests from their own environment, see Project.toml here.
using Test
using NumericalRadiation

@testset "SpeedyWeather coupling" begin
    include(joinpath(@__DIR__, "..", "test_speedyweather_analytic_band_longwave.jl"))
    include(joinpath(@__DIR__, "..", "test_speedyweather_clear_sky_ecckd.jl"))
end
