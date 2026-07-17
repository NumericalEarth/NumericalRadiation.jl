@testset "reduced ecCKD subset search artifact" begin
    script = joinpath(@__DIR__, "..", "validation", "reduced_ecckd_subset_search.jl")
    test_project = Base.active_project()
    result = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)

    @test occursin("Reduced ecCKD Shortwave Subset Search", result)
    @test occursin("Selected shortwave g-points", result)

    json_path = joinpath(@__DIR__, "..", "validation", "results", "reduced_ecckd_subset_search.json")
    md_path = joinpath(@__DIR__, "..", "validation", "results", "reduced_ecckd_subset_search.md")
    @test isfile(json_path)
    @test isfile(md_path)

    json = read(json_path, String)
    @test occursin("\"case\": \"radiative_heating_reduced_subset_search\"", json)
    @test occursin("\"status\": \"failed_threshold\"", json) ||
          occursin("\"status\": \"passed\"", json)
    @test occursin("\"search_objective\": \"flux_boundary_and_shortwave_heating_rate\"", json)
    @test occursin("\"selected_shortwave_gpoints\"", json)
    @test occursin("\"heating_rate\"", json)
    @test occursin("\"boundary_weighted_searches\"", json)
    @test occursin("\"boundary_weight\":", json)
    @test occursin("\"pruned_full_fit_search\"", json)
    @test occursin("\"best_pruned_full_fit_subset\"", json)
    @test occursin("\"hardgate_weighted_search\"", json)
    @test occursin("\"best_hardgate_weighted_subset\"", json)
end
