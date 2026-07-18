using Test
using NumericalRadiation
using Dates

const VALIDATION_DIR = abspath(joinpath(@__DIR__, "..", "validation"))
const VALIDATION_RESULTS_DIR_ENV = "NUMERICAL_RADIATION_VALIDATION_RESULTS_DIR"
const RUN_SLOW_VALIDATION_TESTS =
    lowercase(get(ENV, "NUMERICAL_RADIATION_RUN_SLOW_VALIDATION_TESTS", "false")) in
    ("1", "true", "yes", "on")

function with_temporary_validation_results(f::Function)
    source_results_dir = joinpath(VALIDATION_DIR, "results")
    previous_results_dir = get(ENV, VALIDATION_RESULTS_DIR_ENV, nothing)

    return mktempdir() do temp_root
        temp_results_dir = joinpath(temp_root, "results")
        if isdir(source_results_dir)
            cp(source_results_dir, temp_results_dir; force = true)
        else
            mkpath(temp_results_dir)
        end

        ENV[VALIDATION_RESULTS_DIR_ENV] = temp_results_dir
        try
            return f()
        finally
            if previous_results_dir === nothing
                delete!(ENV, VALIDATION_RESULTS_DIR_ENV)
            else
                ENV[VALIDATION_RESULTS_DIR_ENV] = previous_results_dir
            end
        end
    end
end

function print_stderr_without_method_overwrite_warnings(stderr_path)
    text = read(stderr_path, String)
    isempty(text) && return nothing

    for line in split(text, '\n'; keepempty=false)
        if !occursin(r"^WARNING: Method definition .* overwritten", line)
            println(stderr, line)
        end
    end

    return nothing
end

function rewrite_includes(expr)
    if expr isa Expr
        if expr.head == :call && length(expr.args) == 2 && expr.args[1] == :include
            return :(Main.include_dependency_quietly(@__MODULE__, $(rewrite_includes(expr.args[2]))))
        end
        return Expr(expr.head, map(rewrite_includes, expr.args)...)
    end

    return expr
end

function include_dependency_quietly(target_module::Module, path::AbstractString)
    resolved = abspath(path)
    is_validation = startswith(resolved, VALIDATION_DIR * Base.Filesystem.path_separator)
    if !is_validation
        return Base.include(rewrite_includes, target_module, resolved)
    end

    return mktemp() do stderr_path, stderr_io
        close(stderr_io)

        try
            result = open(stderr_path, "w") do redirected_stderr
                redirect_stderr(redirected_stderr) do
                    Base.include(rewrite_includes, target_module, resolved)
                end
            end
            print_stderr_without_method_overwrite_warnings(stderr_path)
            return result
        catch
            print(stderr, read(stderr_path, String))
            rethrow()
        end
    end
end

function include_test(filename::AbstractString)
    path = joinpath(@__DIR__, filename)
    return Base.include(rewrite_includes, @__MODULE__, path)
end

function include_slow_validation_test(filename::AbstractString)
    if RUN_SLOW_VALIDATION_TESTS
        return include_test(filename)
    end

    @testset "$(filename) (slow validation)" begin
        @test_skip(
            "set NUMERICAL_RADIATION_RUN_SLOW_VALIDATION_TESTS=true to run long optimizer/recovery validation"
        )
    end

    return nothing
end

with_temporary_validation_results() do
# Each subsystem file wraps the original per-topic test files verbatim in their
# own modules; slow validation tests stay as separate files behind
# include_slow_validation_test. Ordering matters where a test regenerates a
# results artifact that a later test (or included validation script) reads.
@testset "NumericalRadiation" begin
    include_test("test_solvers.jl")
    include_test("test_ecckd_io.jl")
    include_test("test_ecckd_accuracy.jl")
    include_test("test_ecrad_gates.jl")
    include_test("test_ckdmip_pipeline.jl")
    include_test("test_reduced_ecckd.jl")
    include_test("test_misc.jl")
end

@testset "SpeedyWeather Extension" begin
    include_test("test_with_speedyweather.jl")
end
end
