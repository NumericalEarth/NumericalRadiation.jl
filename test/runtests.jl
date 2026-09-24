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

# The SpeedyWeather extension needs SpeedyWeather >= 0.23, not registered yet, so it
# is not part of test/Project.toml; its tests run from test/speedyweather/ (own
# environment and CI job) and here only when SpeedyWeather happens to be loadable.
if Base.find_package("SpeedyWeather") === nothing
    @info "SpeedyWeather is not in this environment; skipping the extension tests (see test/speedyweather/)"
else
    @testset "SpeedyWeather Extension" begin
        include_test("test_with_speedyweather.jl")
    end
end
