using Test

include(joinpath(@__DIR__, "..", "validation", "reduced_ecckd_constrained_table_optimizer.jl"))

@testset "constrained table optimizer candidate pool" begin
    old_include = get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH", nothing)
    old_multiplier = get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_PROBE_POOL_MULTIPLIER", nothing)
    old_progress = get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_PROGRESS", nothing)
    old_max_probe_seconds =
        get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_MAX_PROBE_SECONDS", nothing)
    old_residual_mode = get(ENV, "RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE", nothing)
    try
        ENV["RH_REDUCED_CONSTRAINED_TABLE_PROBE_POOL_MULTIPLIER"] = "2"
        candidates = [
            (component = "static_absorption", priority = 5.0),
            (component = "dynamic_h2o", priority = 4.0),
            (component = "static_absorption", priority = 3.0),
            (component = "rayleigh", priority = 100.0),
            (component = "rayleigh", priority = 90.0),
        ]

        ENV["RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH"] = "false"
        @test constrained_table_probe_pool(candidates, 2) == candidates[1:4]
        @test constrained_table_limit_candidates(candidates, 2) == candidates[1:2]

        ENV["RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH"] = "true"
        pool = constrained_table_probe_pool(candidates, 2)
        @test length(pool) == 5
        @test count(candidate -> candidate.component == "rayleigh", pool) == 2
        @test pool[1:3] == candidates[1:3]

        limited = constrained_table_limit_candidates(candidates, 2)
        @test length(limited) == 2
        @test count(candidate -> candidate.component == "rayleigh", limited) == 2

        ENV["RH_REDUCED_CONSTRAINED_TABLE_PROGRESS"] = "true"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_MAX_PROBE_SECONDS"] = "12.5"
        @test constrained_table_progress()
        @test constrained_table_max_probe_seconds() == 12.5
        ENV["RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE"] = "boundary"
        @test constrained_table_residual_mode() == "boundary"
        ENV["RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE"] = "toa"
        @test constrained_table_residual_mode() == "toa"
    finally
        if old_include === nothing
            delete!(ENV, "RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH")
        else
            ENV["RH_REDUCED_CONSTRAINED_TABLE_INCLUDE_RAYLEIGH"] = old_include
        end
        if old_multiplier === nothing
            delete!(ENV, "RH_REDUCED_CONSTRAINED_TABLE_PROBE_POOL_MULTIPLIER")
        else
            ENV["RH_REDUCED_CONSTRAINED_TABLE_PROBE_POOL_MULTIPLIER"] = old_multiplier
        end
        if old_progress === nothing
            delete!(ENV, "RH_REDUCED_CONSTRAINED_TABLE_PROGRESS")
        else
            ENV["RH_REDUCED_CONSTRAINED_TABLE_PROGRESS"] = old_progress
        end
        if old_max_probe_seconds === nothing
            delete!(ENV, "RH_REDUCED_CONSTRAINED_TABLE_MAX_PROBE_SECONDS")
        else
            ENV["RH_REDUCED_CONSTRAINED_TABLE_MAX_PROBE_SECONDS"] = old_max_probe_seconds
        end
        if old_residual_mode === nothing
            delete!(ENV, "RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE")
        else
            ENV["RH_REDUCED_CONSTRAINED_TABLE_RESIDUAL_MODE"] = old_residual_mode
        end
    end
end

@testset "constrained table base modes" begin
    old_candidate = get(ENV, "RH_CANDIDATE_GAS_OPTICS", nothing)
    try
        ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
        require_ncdatasets()
        Base.retry_load_extensions()
        full_model = candidate_gas_optics(Float64)
        canonical = current_constrained_table_model(
            full_model;
            base_mode = "canonical",
        )
        boundary_refit = current_constrained_table_model(
            full_model;
            base_mode = "boundary_weight_refit",
        )
        boundary_base_table = current_constrained_table_model(
            full_model;
            base_mode = "boundary_base_table",
        )
        boundary_continuation = current_constrained_table_model(
            full_model;
            base_mode = "boundary_table_continuation",
        )
        boundary_post_descent = current_constrained_table_model(
            full_model;
            base_mode = "boundary_table_post_descent",
        )
        @test size(canonical.shortwave_absorption, 1) == 16
        @test size(boundary_refit.shortwave_absorption, 1) == 16
        @test size(boundary_base_table.shortwave_absorption, 1) == 16
        @test size(boundary_continuation.shortwave_absorption, 1) == 16
        @test size(boundary_post_descent.shortwave_absorption, 1) == 16
        @test length(boundary_continuation.shortwave_weights) == 16
        @test length(boundary_post_descent.shortwave_weights) == 16
        @test all(isfinite, boundary_continuation.shortwave_weights)
        @test all(isfinite, boundary_post_descent.shortwave_weights)
        @test sum(boundary_continuation.shortwave_weights) ≈ 1
        @test sum(boundary_post_descent.shortwave_weights) ≈ 1
    finally
        if old_candidate === nothing
            delete!(ENV, "RH_CANDIDATE_GAS_OPTICS")
        else
            ENV["RH_CANDIDATE_GAS_OPTICS"] = old_candidate
        end
    end
end
