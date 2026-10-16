# Optional compiler regression test. Run with NumericalRadiation, Reactant,
# KernelAbstractions, CUDA, Enzyme, and Test available in the active environment.
# CUDA supplies Reactant's kernel-raising integration even on the CPU backend.
using NumericalRadiation
using Reactant
using KernelAbstractions
using CUDA
using Enzyme
using Test

Reactant.set_default_backend("cpu")

@inline function lookup_value(model::EcCKDTabulatedGasOpticsModel, query)
    return longwave_source(model, 1, query, source_table_bracket(model, query))
end

@inline function lookup_value(cloud::SpectralCloudOptics, query)
    return first(cloud_layer_optics(cloud, 1, effective_radius_bracket(cloud, query)))
end

@kernel function lookup_values_kernel!(output, queries, model)
    i = @index(Global, Linear)
    @inbounds output[i] = lookup_value(model, queries[i])
end

function lookup_loss!(output, queries, model)
    backend = KernelAbstractions.get_backend(output)
    lookup_values_kernel!(backend, 1)(output, queries, model; ndrange=length(queries))
    return sum(abs2, output)
end

function lookup_gradient!(output, doutput, queries, dqueries, model)
    doutput .= 0
    dqueries .= 0
    _, value = Enzyme.autodiff(Enzyme.ReverseWithPrimal, lookup_loss!, Enzyme.Active,
                              Enzyme.Duplicated(output, doutput),
                              Enzyme.Duplicated(queries, dqueries), Enzyme.Const(model))
    return value, dqueries
end

@testset "Reactant fixed lookup derivatives" begin
    gas = EcCKDTabulatedGasOpticsModel(
        names = (:composite,),
        pressure_grid = [10_000.0, 100_000.0],
        temperature_grid = [200.0, 300.0],
        longwave_absorption = ones(1, 1, 2, 2),
        shortwave_absorption = ones(1, 1, 2, 2),
        longwave_source_temperature_grid = [200.0, 230.0, 270.0, 300.0],
        longwave_source_table = [10.0 20.0 60.0 100.0],
        lookup_search = FixedBinarySearch(),
    )
    cloud = SpectralCloudOptics([1e-6, 3e-6, 7e-6, 10e-6], [1.0 4.0 8.0 15.0],
                                zeros(1, 4), zeros(1, 4); lookup_search=FixedBinarySearch())

    for (name, model, queries) in (("Planck source", gas, [150.0, 215.0, 255.0, 285.0, 350.0]),
                                  ("cloud radius", cloud, [0.5e-6, 2e-6, 5e-6, 9e-6, 12e-6]))
        @testset "$name" begin
            # Queries lie away from knots and clamp transitions. Include both
            # ends to check Planck extrapolation and clamped cloud derivatives.
            expected = lookup_value.(Ref(model), queries)
            difference_gradient = map(queries) do x
                step = abs(x) * 1e-5
                (lookup_value(model, x + step)^2 - lookup_value(model, x - step)^2) / (2step)
            end
            rmodel = Reactant.to_rarray(model)
            rqueries = Reactant.to_rarray(queries)
            output = Reactant.to_rarray(zero(queries))
            doutput, dqueries = zero(output), zero(rqueries)
            println("Compiling $name forward lookup"); flush(stdout)
            forward = Reactant.@compile raise=true raise_first=true lookup_loss!(output, rqueries, rmodel)
            @test Float64(forward(output, rqueries, rmodel)) ≈ sum(abs2, expected)
            @test Array(output) ≈ expected
            println("Compiling $name reverse derivative"); flush(stdout)
            reverse = Reactant.@compile raise=true raise_first=true lookup_gradient!(output, doutput, rqueries, dqueries, rmodel)
            for repetition in 1:2
                value, gradient = reverse(output, doutput, rqueries, dqueries, rmodel)
                @test Float64(value) ≈ sum(abs2, expected)
                @test Array(gradient) ≈ difference_gradient rtol=1e-6
            end
        end
    end
end
