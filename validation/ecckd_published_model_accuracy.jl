include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

using NCDatasets

include(joinpath(@__DIR__, "reduced_ecckd_accuracy.jl"))

const PUBLISHED_MODEL_ACCURACY_JSON =
    validation_results_path("ecckd_published_model_accuracy.json")
const PUBLISHED_MODEL_ACCURACY_MD =
    validation_results_path("ecckd_published_model_accuracy.md")

const PUBLISHED_MODEL_SPECS = (
    (
        label = "official ecCKD 1.0 32-LW x 32-SW climate model",
        longwave = :longwave_32,
        shortwave = :shortwave_32,
    ),
    (
        label = "official ecCKD 1.0/1.2 32-LW x 64-SW climate/window model",
        longwave = :longwave_32,
        shortwave = :shortwave_64,
        reference_cases = (
            (
                case = "ecckd_32x64_clear_sky_tropical_column",
                path = "validation/reference/ecrad/ecckd_32x64_clear_sky_tropical_column.nc",
            ),
            (
                case = "ecckd_32x64_rcemip_style_column_subset",
                path = "validation/reference/ecrad/ecckd_32x64_rcemip_style_column_subset.nc",
            ),
        ),
    ),
    (
        label = "official ecCKD 1.0/1.4 32-LW x 96-SW climate/vfine model",
        longwave = :longwave_32,
        shortwave = :shortwave_96,
        reference_cases = (
            (
                case = "ecckd_32x96_clear_sky_tropical_column",
                path = "validation/reference/ecrad/ecckd_32x96_clear_sky_tropical_column.nc",
            ),
            (
                case = "ecckd_32x96_rcemip_style_column_subset",
                path = "validation/reference/ecrad/ecckd_32x96_rcemip_style_column_subset.nc",
            ),
        ),
    ),
    (
        label = "official ecCKD 1.2/1.4 64-LW x 32-SW narrow/rgb model",
        longwave = :longwave_64,
        shortwave = :shortwave_32,
        reference_cases = (
            (
                case = "ecckd_64x32_clear_sky_tropical_column",
                path = "validation/reference/ecrad/ecckd_64x32_clear_sky_tropical_column.nc",
            ),
            (
                case = "ecckd_64x32_rcemip_style_column_subset",
                path = "validation/reference/ecrad/ecckd_64x32_rcemip_style_column_subset.nc",
            ),
        ),
    ),
    (
        label = "official ecCKD 1.2 64-LW x 64-SW climate model",
        longwave = :longwave_64,
        shortwave = :shortwave_64,
        reference_cases = (
            (
                case = "ecckd_64x64_clear_sky_tropical_column",
                path = "validation/reference/ecrad/ecckd_64x64_clear_sky_tropical_column.nc",
            ),
            (
                case = "ecckd_64x64_rcemip_style_column_subset",
                path = "validation/reference/ecrad/ecckd_64x64_rcemip_style_column_subset.nc",
            ),
        ),
    ),
    (
        label = "official ecCKD 1.2/1.4 64-LW x 96-SW climate/vfine model",
        longwave = :longwave_64,
        shortwave = :shortwave_96,
        reference_cases = (
            (
                case = "ecckd_64x96_clear_sky_tropical_column",
                path = "validation/reference/ecrad/ecckd_64x96_clear_sky_tropical_column.nc",
            ),
            (
                case = "ecckd_64x96_rcemip_style_column_subset",
                path = "validation/reference/ecrad/ecckd_64x96_rcemip_style_column_subset.nc",
            ),
        ),
    ),
)

const PUBLISHED_MODEL_ISOLATION_SPECS = (
    (
        label = "component isolation: published 32-LW x 64-SW",
        longwave = :longwave_32,
        shortwave = :shortwave_64,
        diagnostic = "32-LW reference with 64-SW published component",
    ),
    (
        label = "component isolation: published 32-LW x 96-SW",
        longwave = :longwave_32,
        shortwave = :shortwave_96,
        diagnostic = "32-LW reference with 96-SW published component",
    ),
    (
        label = "component isolation: published 64-LW x 32-SW",
        longwave = :longwave_64,
        shortwave = :shortwave_32,
        diagnostic = "64-LW published component with 32-SW reference",
    ),
)

const PUBLISHED_MODEL_BOUNDARY_PROJECTION_SPECS = (
    (
        label = "boundary-projected diagnostic: official 64-LW x 64-SW",
        longwave = :longwave_64,
        shortwave = :shortwave_64,
        diagnostic = "64-LW x 64-SW with 32-g boundary arrays projected by gpoint_fraction overlap",
        project_boundaries = true,
    ),
    (
        label = "boundary-projected diagnostic: official 64-LW x 96-SW",
        longwave = :longwave_64,
        shortwave = :shortwave_96,
        diagnostic = "64-LW x 96-SW with 32-g boundary arrays projected by gpoint_fraction overlap",
        project_boundaries = true,
    ),
    (
        label = "boundary-projected diagnostic: published 32-LW x 64-SW",
        longwave = :longwave_32,
        shortwave = :shortwave_64,
        diagnostic = "32-LW x 64-SW with 32-g SW boundary arrays projected by gpoint_fraction overlap",
        project_boundaries = true,
    ),
    (
        label = "boundary-projected diagnostic: published 32-LW x 96-SW",
        longwave = :longwave_32,
        shortwave = :shortwave_96,
        diagnostic = "32-LW x 96-SW with 32-g SW boundary arrays projected by gpoint_fraction overlap",
        project_boundaries = true,
    ),
    (
        label = "boundary-projected diagnostic: published 64-LW x 32-SW",
        longwave = :longwave_64,
        shortwave = :shortwave_32,
        diagnostic = "64-LW x 32-SW with 32-g LW boundary arrays projected by gpoint_fraction overlap",
        project_boundaries = true,
    ),
)

function published_model(spec)
    longwave_path = official_ecckd_definition_path(spec.longwave)
    shortwave_path = official_ecckd_definition_path(spec.shortwave)
    model = read_ecckd_tabulated_gas_optics(
        longwave_path,
        shortwave_path;
        gas_names = OFFICIAL_ECCKD_GASES,
        h2o_mole_fraction = env_float("RH_ECCKD_H2O_MOLE_FRACTION", 0.005),
    )
    project_boundaries = hasproperty(spec, :project_boundaries) && spec.project_boundaries
    if project_boundaries
        register_reduced_model(
            model,
            lw_boundary_projection = spec.longwave == :longwave_32 ? nothing : (
                source_definition_path = official_ecckd_definition_path(:longwave_32),
                target_definition_path = longwave_path,
            ),
            sw_boundary_projection = spec.shortwave == :shortwave_32 ? nothing : (
                source_definition_path = official_ecckd_definition_path(:shortwave_32),
                target_definition_path = shortwave_path,
            ),
        )
    end
    return model
end

function hard_objective(cases)
    rows = NamedTuple[]
    for case in cases
        for variable in (:lw_up, :lw_down, :sw_up, :sw_down)
            metrics = getproperty(case.variables, variable)
            push!(rows, (
                case = case.case,
                metric = "$(variable)_rmse",
                value = metrics.rmse,
                threshold = ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
                normalized_value = metrics.rmse / ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
            ))
            push!(rows, (
                case = case.case,
                metric = "$(variable)_max_abs",
                value = metrics.max_abs,
                threshold = ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
                normalized_value = metrics.max_abs / ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
            ))
        end
        heating = case.variables.heating_rate
        push!(rows, (
            case = case.case,
            metric = "heating_rate_rmse",
            value = heating.rmse,
            threshold = ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day,
            normalized_value = heating.rmse / ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day,
        ))
        push!(rows, (
            case = case.case,
            metric = "heating_rate_max_abs",
            value = heating.max_abs,
            threshold = ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
            normalized_value = heating.max_abs / ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
        ))
        push!(rows, (
            case = case.case,
            metric = "toa_forcing",
            value = case.toa_forcing_max_abs,
            threshold = ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
            normalized_value =
                case.toa_forcing_max_abs / ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
        ))
        push!(rows, (
            case = case.case,
            metric = "surface_forcing",
            value = case.surface_forcing_max_abs,
            threshold = ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
            normalized_value =
                case.surface_forcing_max_abs /
                ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
        ))
    end
    worst = argmax(row -> row.normalized_value, rows)
    return (
        value = worst.normalized_value,
        case = worst.case,
        metric = worst.metric,
        metric_value = worst.value,
        threshold = worst.threshold,
    )
end

function boundary_array_dimension(dataset, variables, names::Tuple)
    for name in names
        if name in variables
            return size(dataset[name], 1)
        end
    end
    return nothing
end

function reference_cases_for_spec(spec)
    return hasproperty(spec, :reference_cases) ? spec.reference_cases : REDUCED_CASES
end

function boundary_compatibility(model, reference_cases)
    nc = require_ncdatasets()
    ng_lw = size(model.longwave_absorption, 1)
    ng_sw = size(model.shortwave_absorption, 1)
    rows = NamedTuple[]
    for case in reference_cases
        nc.NCDataset(reference_path(case.path)) do dataset
            variables = String.(collect(keys(dataset)))
            sw_surface_gpoints =
                boundary_array_dimension(dataset, variables,
                                         ("surface_albedo_spectral",))
            sw_direct_gpoints =
                boundary_array_dimension(dataset, variables,
                                         ("surface_albedo_direct_gpoint",
                                          "surface_albedo_direct_spectral"))
            sw_toa_gpoints =
                boundary_array_dimension(dataset, variables,
                                         ("toa_shortwave_down_spectral",))
            lw_surface_gpoints =
                boundary_array_dimension(dataset, variables,
                                         ("surface_longwave_up_spectral",))
            push!(rows, (
                case = case.case,
                expected_longwave_gpoints = ng_lw,
                expected_shortwave_gpoints = ng_sw,
                surface_longwave_up_spectral_gpoints = lw_surface_gpoints,
                surface_albedo_spectral_gpoints = sw_surface_gpoints,
                surface_albedo_direct_spectral_gpoints = sw_direct_gpoints,
                toa_shortwave_down_spectral_gpoints = sw_toa_gpoints,
                longwave_spectral_boundary_matches =
                    lw_surface_gpoints !== nothing && lw_surface_gpoints == ng_lw,
                shortwave_surface_albedo_matches =
                    sw_surface_gpoints !== nothing && sw_surface_gpoints == ng_sw,
                shortwave_direct_albedo_matches =
                    sw_direct_gpoints !== nothing && sw_direct_gpoints == ng_sw,
                shortwave_incoming_spectral_matches =
                    sw_toa_gpoints !== nothing && sw_toa_gpoints == ng_sw,
                shortwave_spectral_boundary_matches =
                    sw_surface_gpoints !== nothing && sw_surface_gpoints == ng_sw &&
                    sw_toa_gpoints !== nothing && sw_toa_gpoints == ng_sw &&
                    (sw_direct_gpoints === nothing || sw_direct_gpoints == ng_sw),
            ))
        end
    end
    return (
        all_longwave_spectral_boundaries_match =
            all(row -> row.longwave_spectral_boundary_matches, rows),
        all_shortwave_surface_albedo_boundaries_match =
            all(row -> row.shortwave_surface_albedo_matches, rows),
        all_shortwave_direct_albedo_boundaries_match =
            all(row -> row.shortwave_direct_albedo_matches, rows),
        all_shortwave_incoming_spectral_boundaries_match =
            all(row -> row.shortwave_incoming_spectral_matches, rows),
        all_shortwave_spectral_boundaries_match =
            all(row -> row.shortwave_spectral_boundary_matches, rows),
        cases = rows,
    )
end

function published_model_result(spec)
    model = published_model(spec)
    reference_cases = reference_cases_for_spec(spec)
    cases = [case_metrics(case, model) for case in reference_cases]
    objective = hard_objective(cases)
    return (
        label = spec.label,
        diagnostic = hasproperty(spec, :diagnostic) ? spec.diagnostic : "",
        longwave_key = String(spec.longwave),
        shortwave_key = String(spec.shortwave),
        ng_lw = size(model.longwave_absorption, 1),
        ng_sw = size(model.shortwave_absorption, 1),
        total_gpoints = size(model.longwave_absorption, 1) +
                        size(model.shortwave_absorption, 1),
        longwave_path = official_ecckd_definition_path(spec.longwave),
        shortwave_path = official_ecckd_definition_path(spec.shortwave),
        passed_hard_thresholds = all(case -> case.passed_hard_thresholds, cases),
        worst_toa_forcing_abs_error_w_m2 =
            maximum(case -> case.toa_forcing_max_abs, cases),
        worst_surface_forcing_abs_error_w_m2 =
            maximum(case -> case.surface_forcing_max_abs, cases),
        hard_objective = objective,
        boundary_compatibility = boundary_compatibility(model, reference_cases),
        cases = cases,
    )
end

function published_model_accuracy()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    models = [published_model_result(spec) for spec in PUBLISHED_MODEL_SPECS]
    isolation_diagnostics =
        [published_model_result(spec) for spec in PUBLISHED_MODEL_ISOLATION_SPECS]
    boundary_projection_diagnostics =
        [published_model_result(spec) for spec in PUBLISHED_MODEL_BOUNDARY_PROJECTION_SPECS]
    return (
        case = "ecckd_published_model_accuracy",
        timestamp_utc = string(Dates.now()),
        status = all(model -> model.passed_hard_thresholds, models) ? "passed" :
                 "failed_threshold",
        reference_scope = "published rows use matched package-native ecRad references for every promoted non-32x32 combination; 32x32 uses $(join(REDUCED_CASE_NAMES, ", "))",
        acceptance_thresholds = ACCEPTANCE_THRESHOLDS,
        models = models,
        isolation_diagnostics = isolation_diagnostics,
        boundary_projection_diagnostics = boundary_projection_diagnostics,
    )
end

function markdown_report(result)
    lines = String[
        "# Published ecCKD Model Accuracy",
        "",
        "Status: **$(result.status)**",
        "",
        "Reference scope: clean ecCKD cloudless/no-aerosol tropical and RCEMIP-style cases, using matched ecRad reference products for every promoted non-32x32 published combination.",
        "",
        "| Model | LW | SW | Passed | Worst TOA forcing | Worst surface forcing | Hard objective | Limiting metric |",
        "|---|---:|---:|---:|---:|---:|---:|---|",
    ]
    for model in result.models
        push!(lines,
              "| $(model.label) | $(model.ng_lw) | $(model.ng_sw) | $(model.passed_hard_thresholds) | $(@sprintf("%.12g", model.worst_toa_forcing_abs_error_w_m2)) W m^-2 | $(@sprintf("%.12g", model.worst_surface_forcing_abs_error_w_m2)) W m^-2 | $(@sprintf("%.12g", model.hard_objective.value)) | $(model.hard_objective.metric) |")
    end
    append!(lines, [
        "",
        "## Boundary compatibility",
        "",
        "| Model | LW surface spectral matches | SW surface albedo matches | SW direct albedo matches | SW incoming spectral matches |",
        "|---|---:|---:|---:|---:|",
    ])
    for model in result.models
        push!(lines,
              "| $(model.label) | $(model.boundary_compatibility.all_longwave_spectral_boundaries_match) | $(model.boundary_compatibility.all_shortwave_surface_albedo_boundaries_match) | $(model.boundary_compatibility.all_shortwave_direct_albedo_boundaries_match) | $(model.boundary_compatibility.all_shortwave_incoming_spectral_boundaries_match) |")
    end
    append!(lines, [
        "",
        "## Mixed-component isolation diagnostics",
        "",
        "| Diagnostic | LW | SW | Passed | Worst TOA forcing | Worst surface forcing | Hard objective | Limiting metric |",
        "|---|---:|---:|---:|---:|---:|---:|---|",
    ])
    for model in result.isolation_diagnostics
        push!(lines,
              "| $(model.diagnostic) | $(model.ng_lw) | $(model.ng_sw) | $(model.passed_hard_thresholds) | $(@sprintf("%.12g", model.worst_toa_forcing_abs_error_w_m2)) W m^-2 | $(@sprintf("%.12g", model.worst_surface_forcing_abs_error_w_m2)) W m^-2 | $(@sprintf("%.12g", model.hard_objective.value)) | $(model.hard_objective.metric) |")
    end
    append!(lines, [
        "",
        "## Boundary-projection experiment",
        "",
        "| Diagnostic | LW | SW | Passed | Worst TOA forcing | Worst surface forcing | Hard objective | Limiting metric |",
        "|---|---:|---:|---:|---:|---:|---:|---|",
    ])
    for model in result.boundary_projection_diagnostics
        push!(lines,
              "| $(model.diagnostic) | $(model.ng_lw) | $(model.ng_sw) | $(model.passed_hard_thresholds) | $(@sprintf("%.12g", model.worst_toa_forcing_abs_error_w_m2)) W m^-2 | $(@sprintf("%.12g", model.worst_surface_forcing_abs_error_w_m2)) W m^-2 | $(@sprintf("%.12g", model.hard_objective.value)) | $(model.hard_objective.metric) |")
    end
    append!(lines, [
        "",
        "This artifact evaluates published full-accuracy ecCKD CKD-definition combinations directly against the same clean package-native ecRad reference cases used by the reduced-model gate.",
        "The mixed-component rows are old-reference diagnostics only: they evaluate promoted definition combinations against the original 32x32 package-native references to show why matched spectral-boundary products are required.",
        "Boundary compatibility records whether the package-native reference files contain spectral boundary arrays with the same g-point count as the tested model; mismatches fall back to broadband boundary treatment in the current evaluator.",
        "The boundary-projection experiment is also diagnostic only: it projects available 32-g boundary arrays onto 64/96 g-grids by official `gpoint_fraction` overlap to test whether missing boundary-grid compatibility is the dominant error source.",
    ])
    return join(lines, "\n") * "\n"
end

function main()
    result = published_model_accuracy()
    mkpath(dirname(PUBLISHED_MODEL_ACCURACY_JSON))
    write(PUBLISHED_MODEL_ACCURACY_JSON, json_object(result) * "\n")
    write(PUBLISHED_MODEL_ACCURACY_MD, markdown_report(result))
    print(markdown_report(result))
    println("Wrote $PUBLISHED_MODEL_ACCURACY_JSON")
    println("Wrote $PUBLISHED_MODEL_ACCURACY_MD")
    return result
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
