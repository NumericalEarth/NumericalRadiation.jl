# Runs the SpeedyWeather extension tests from their own environment, see Project.toml here.
using Test
using NumericalRadiation

@testset "SpeedyWeather Extension" begin
    include(joinpath(@__DIR__, "..", "test_with_speedyweather.jl"))
end
