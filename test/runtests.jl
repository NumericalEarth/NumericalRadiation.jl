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
    include_test("test_ecckd_radiation.jl")
    include_test("test_streaming.jl")
    include_test("test_spectral_cloud_optics.jl")
    include_test("test_exact_solutions.jl")
    include_test("test_host_interface.jl")
end

# The coupling tests need SpeedyWeather >= 0.23 (with its NumericalRadiation extension),
# not registered yet, so SpeedyWeather is not part of test/Project.toml; they run from
# test/speedyweather/ (own environment and CI job) and here only when SpeedyWeather
# happens to be loadable.
if Base.find_package("SpeedyWeather") === nothing
    @info "SpeedyWeather is not in this environment; skipping the coupling tests (see test/speedyweather/)"
else
    @testset "SpeedyWeather coupling" begin
        include_test("test_speedyweather_analytic_band_longwave.jl")
        include_test("test_speedyweather_clear_sky_ecckd.jl")
    end
end
