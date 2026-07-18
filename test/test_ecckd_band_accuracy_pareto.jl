using JSON

@testset "ecCKD band-count accuracy Pareto artifact" begin
    root = normpath(joinpath(@__DIR__, ".."))
    script = joinpath(root, "validation", "ecckd_band_accuracy_pareto.jl")
    test_project = Base.active_project()
    output = read(`$(Base.julia_cmd()) --project=$test_project $script`, String)

    @test occursin("ecCKD Band-Count Accuracy Pareto", output)
    @test occursin("Status: **passed**", output)
    @test occursin("Published ecCKD inventory entries: 6", output)

    md_path = joinpath(root, "validation", "results", "ecckd_band_accuracy_pareto.md")
    json_path = joinpath(root, "validation", "results", "ecckd_band_accuracy_pareto.json")
    csv_path = joinpath(root, "validation", "results", "ecckd_band_accuracy_pareto.csv")
    svg_path = joinpath(root, "validation", "results", "ecckd_band_accuracy_pareto.svg")
    @test isfile(md_path)
    @test isfile(json_path)
    @test isfile(csv_path)
    @test isfile(svg_path)

    result = JSON.parsefile(json_path)
    @test result["status"] == "passed"
    @test result["point_count"] >= 10
    @test result["published_inventory_count"] == 6
    @test result["passed_point_count"] >= 1
    @test haskey(result, "objective_front")
    @test length(result["objective_front"]) >= 2
    @test any(row -> row["ng_lw"] == 32 && row["ng_sw"] == 32 && row["passed"],
              result["accuracy_points"])
    @test any(row -> row["source"] == "reduced_accuracy" &&
                     row["ng_lw"] == 32 &&
                     row["ng_sw"] == 31 &&
                     row["passed"] &&
                     occursin("boundary-polished", row["label"]),
              result["accuracy_points"])
    @test any(row -> row["ng_lw"] == 32 && row["ng_sw"] == 16,
              result["accuracy_points"])
    @test any(row -> row["source"] == "leave_one_out_weight_coordinate_boundary_polish" &&
                     row["ng_lw"] == 32 &&
                     row["ng_sw"] == 31,
              result["accuracy_points"])
    @test any(row -> row["source"] == "published_model_accuracy" &&
                     row["ng_lw"] == 64 &&
                     row["ng_sw"] == 64 &&
                     row["passed"],
              result["accuracy_points"])
    @test any(row -> row["source"] == "published_model_accuracy" &&
                     row["ng_lw"] == 64 &&
                     row["ng_sw"] == 96 &&
                     row["passed"],
              result["accuracy_points"])

    weight_polish_31 =
        only(filter(row -> row["source"] ==
                           "leave_one_out_weight_coordinate_boundary_polish",
                    result["accuracy_points"]))
    @test weight_polish_31["passed"]
    @test weight_polish_31["worst_boundary_forcing_error_w_m2"] < 0.3
    @test 0.99 < weight_polish_31["normalized_objective"] < 1.0
    @test weight_polish_31["limiting_metric"] in
          ("reported_weight_coordinate_boundary_polish_objective", "boundary_forcing")
    canonical_polish_31 =
        only(filter(row -> row["source"] == "reduced_accuracy" &&
                           row["ng_lw"] == 32 &&
                           row["ng_sw"] == 31,
                    result["accuracy_points"]))
    @test canonical_polish_31["passed"]
    @test any(row -> row["label"] == canonical_polish_31["label"],
              result["objective_front"])

    md = read(md_path, String)
    @test occursin("Boundary-Forcing Pareto Front", md)
    @test occursin("Normalized-Objective Pareto Front", md)

    csv = read(csv_path, String)
    @test occursin("source,label,ng_lw,ng_sw,total_gpoints,passed", csv)
    @test occursin("normalized_objective,objective_source,limiting_metric", csv)
    @test length(split(chomp(csv), "\n")) == result["point_count"] + 1

    svg = read(svg_path, String)
    @test occursin("<svg", svg)
    @test occursin("ecCKD Accuracy vs Total G-points", svg)
    @test occursin("0.3 W m^-2 hard threshold", svg)
end
