include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using LinearAlgebra
using Printf

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))

using NumericalRadiation

include(joinpath(@__DIR__, "write_ecrad_candidates.jl"))

const REDUCED_CASE_NAMES = (
    "ecckd_clear_sky_tropical_column",
    "ecckd_rcemip_style_column_subset",
)
const REDUCED_CASES = Tuple(case for case in REQUIRED_CASES if case.case in REDUCED_CASE_NAMES)
const REDUCED_MODELS = (
    (ng_lw = 32, ng_sw = 32, method = "full_official"),
    (ng_lw = 32, ng_sw = 31, method = "leave_one_out_weight_coordinate_boundary_polish"),
    (ng_lw = 32, ng_sw = 16, method = "even_select"),
    (ng_lw = 32, ng_sw = 16, method = "greedy_subset"),
    (ng_lw = 32, ng_sw = 16, method = "greedy_subset_fit_sw_weights"),
    (ng_lw = 32, ng_sw = 16, method = "greedy_subset_boundary_fit_sw_weights"),
    (ng_lw = 32, ng_sw = 16, method = "weighted_greedy_subset_projected"),
    (ng_lw = 32, ng_sw = 16, method = "weighted_greedy_subset_maxnorm"),
    (ng_lw = 32, ng_sw = 16, method = "weighted_greedy_subset_scaled_coefficients"),
    (ng_lw = 32, ng_sw = 16, method = "weighted_greedy_subset_preflight_optimized"),
    (ng_lw = 32, ng_sw = 16, method = "weighted_greedy_subset_preflight_table_refined"),
    (ng_lw = 32, ng_sw = 16, method = "weighted_greedy_subset_preflight_table_refined_incoming_weighted"),
    (ng_lw = 32, ng_sw = 16, method = "weighted_greedy_subset_boundary_weight_refit"),
    (ng_lw = 32, ng_sw = 16, method = "weighted_greedy_subset_boundary_table_continuation"),
    (ng_lw = 32, ng_sw = 16, method = "even_select_fit_sw_weights"),
    (ng_lw = 16, ng_sw = 16, method = "even_select"),
    (ng_lw = 32, ng_sw = 16, method = "weighted_bins"),
    (ng_lw = 16, ng_sw = 16, method = "weighted_bins"),
    (ng_lw = 32, ng_sw = 16, method = "cumulative_weight_bins"),
    (ng_lw = 16, ng_sw = 16, method = "cumulative_weight_bins"),
    (ng_lw = 32, ng_sw = 16, method = "similarity_pair_bins"),
    (ng_lw = 32, ng_sw = 16, method = "anchored_similarity_bins"),
    (ng_lw = 32, ng_sw = 16, method = "anchored_voronoi_bins"),
)
const REDUCED_BREEZE_DIR = joinpath(ABR_ROOT, "..", "BreezeRadiativeHeatingDev",
                                    "Breeze.jl", "benchmarking", "results",
                                    "reduced_accuracy")
const REDUCED_OPTIMIZATION_PREFLIGHT_JSON =
    validation_results_path("reduced_ecckd_optimization_preflight.json")
const REDUCED_TARGETED_ENTRY_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_targeted_entry_refinement.json")
const REDUCED_GLOBAL_ENTRY_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_global_entry_refinement.json")
const REDUCED_GLOBAL_BLOCK_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_global_block_refinement.json")
const REDUCED_GLOBAL_BLOCK_LINEARIZED_REFIT_JSON =
    validation_results_path("reduced_ecckd_global_block_linearized_refit.json")
const REDUCED_EXACT_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_exact_weight_refit.json")
const REDUCED_JOINT_WEIGHT_BLOCK_REFIT_JSON =
    validation_results_path("reduced_ecckd_joint_weight_block_refit.json")
const REDUCED_BOUNDARY_COLUMN_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_boundary_column_refinement.json")
const REDUCED_SLOT_BLEND_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_slot_blend_refinement.json")
const REDUCED_BOUNDARY_COLUMN_BLOCK_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_boundary_column_block_refinement.json")
const REDUCED_GAS_PRESSURE_BAND_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_gas_pressure_band_refinement.json")
const REDUCED_CONSTRAINED_TABLE_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_constrained_table_optimizer.json")
const REDUCED_BOUNDARY_BASE_CONSTRAINED_TABLE_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_boundary_base_constrained_table_optimizer.json")
const REDUCED_BOUNDARY_TABLE_CONTINUATION_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_boundary_table_continuation_optimizer.json")
const REDUCED_BOUNDARY_TABLE_COORDINATE_SCAN_JSON =
    validation_results_path("reduced_ecckd_boundary_table_coordinate_scan.json")
const REDUCED_BOUNDARY_TABLE_PAIR_COORDINATE_SCAN_JSON =
    validation_results_path("reduced_ecckd_boundary_table_pair_coordinate_scan.json")
const REDUCED_BOUNDARY_TABLE_COORDINATE_DESCENT_JSON =
    validation_results_path("reduced_ecckd_boundary_table_coordinate_descent.json")
const REDUCED_COMPONENT_SCALE_REFIT_JSON =
    validation_results_path("reduced_ecckd_component_scale_refit.json")
const REDUCED_PRESSURE_COMPONENT_SCALE_REFIT_JSON =
    validation_results_path("reduced_ecckd_pressure_component_scale_refit.json")
const REDUCED_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON =
    validation_results_path("reduced_ecckd_temperature_component_scale_refit.json")
const REDUCED_H2O_COMPONENT_SCALE_REFIT_JSON =
    validation_results_path("reduced_ecckd_h2o_component_scale_refit.json")
const REDUCED_GAS_COMPONENT_SCALE_REFIT_JSON =
    validation_results_path("reduced_ecckd_gas_component_scale_refit.json")
const REDUCED_PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON =
    validation_results_path("reduced_ecckd_pressure_temperature_component_scale_refit.json")
const REDUCED_GAS_PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON =
    validation_results_path("reduced_ecckd_gas_pressure_temperature_component_scale_refit.json")
const REDUCED_H2O_PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON =
    validation_results_path("reduced_ecckd_h2o_pressure_temperature_component_scale_refit.json")
const REDUCED_MIXED_PRESSURE_TEMPERATURE_COMPONENT_REFIT_JSON =
    validation_results_path("reduced_ecckd_mixed_pressure_temperature_component_refit.json")
const REDUCED_RETAINED_MIXED_COMPONENT_PARETO_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_mixed_component_pareto_scan.json")
const REDUCED_RETAINED_CAPPED_TABLE_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_capped_table_optimizer.json")
const REDUCED_RETAINED_CAPPED_TABLE_CONTINUATION_JSON =
    validation_results_path("reduced_ecckd_retained_capped_table_continuation.json")
const REDUCED_RETAINED_POST_CAPPED_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_retained_post_capped_weight_refit.json")
const REDUCED_RETAINED_POST_WEIGHT_SURFACE_TABLE_REFIT_JSON =
    validation_results_path("reduced_ecckd_retained_post_weight_surface_table_refit.json")
const REDUCED_RETAINED_POST_WEIGHT_BOUNDED_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_retained_post_weight_bounded_weight_refit.json")
const REDUCED_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_current_component_scale_optimizer.json")
const REDUCED_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER2_JSON =
    validation_results_path("reduced_ecckd_retained_current_component_scale_optimizer2.json")
const REDUCED_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER3_JSON =
    validation_results_path("reduced_ecckd_retained_current_component_scale_optimizer3.json")
const REDUCED_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER4_JSON =
    validation_results_path("reduced_ecckd_retained_current_component_scale_optimizer4.json")
const REDUCED_RETAINED_CURRENT_PRESSURE_COMPONENT_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_current_pressure_component_optimizer.json")
const REDUCED_RETAINED_CURRENT_PRESSURE_COMPONENT_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_pressure_component_scan.json")
const REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_scan.json")
const REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_continuation_scan.json")
const REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION2_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_continuation2_scan.json")
const REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION3_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_continuation3_scan.json")
const REDUCED_RETAINED_STRUCTURAL_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_structural_optimizer.json")
const REDUCED_RETAINED_STRUCTURAL_CONTINUATION_JSON =
    validation_results_path("reduced_ecckd_retained_structural_continuation.json")
const REDUCED_RETAINED_STRUCTURAL_CONTINUATION2_JSON =
    validation_results_path("reduced_ecckd_retained_structural_continuation2.json")
const REDUCED_RETAINED_STRUCTURAL_CONTINUATION3_JSON =
    validation_results_path("reduced_ecckd_retained_structural_continuation3.json")
const REDUCED_RETAINED_STRUCTURAL_CONTINUATION4_JSON =
    validation_results_path("reduced_ecckd_retained_structural_continuation4.json")
const REDUCED_RETAINED_OBJECTIVE_PROBE_EXPANSION_JSON =
    validation_results_path("reduced_ecckd_retained_objective_probe_expansion.json")
const REDUCED_RETAINED_OBJECTIVE_PROBE_EXPANSION2_JSON =
    validation_results_path("reduced_ecckd_retained_objective_probe_expansion2.json")
const REDUCED_RETAINED_OBJECTIVE_PROBE_EXPANSION3_JSON =
    validation_results_path("reduced_ecckd_retained_objective_probe_expansion3.json")
const REDUCED_RETAINED_OBJECTIVE_PROBE_EXPANSION4_JSON =
    validation_results_path("reduced_ecckd_retained_objective_probe_expansion4.json")
const REDUCED_RETAINED_SURFACE_PROBE_EXPANSION_JSON =
    validation_results_path("reduced_ecckd_retained_surface_probe_expansion.json")
const REDUCED_RETAINED_SURFACE_PROBE_EXPANSION2_JSON =
    validation_results_path("reduced_ecckd_retained_surface_probe_expansion2.json")
const REDUCED_RETAINED_SURFACE_PROBE_EXPANSION3_JSON =
    validation_results_path("reduced_ecckd_retained_surface_probe_expansion3.json")
const REDUCED_RETAINED_TOA_PROBE_EXPANSION_JSON =
    validation_results_path("reduced_ecckd_retained_toa_probe_expansion.json")
const REDUCED_POST_CONSTRAINED_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_post_constrained_weight_refit.json")
const REDUCED_POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_post_constrained_boundary_weight_refit.json")
const REDUCED_POST_SLOT_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_post_slot_weight_refit.json")
const REDUCED_LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_JSON =
    validation_results_path("reduced_ecckd_leave_one_out_weight_coordinate_boundary_polish.json")
const GREEDY_SW_16_INDICES = [1, 3, 4, 5, 6, 9, 10, 12, 13, 14, 16, 18, 21, 22, 27, 28]
const WEIGHTED_GREEDY_SW_16_INDICES = [1, 4, 9, 10, 12, 13, 14, 16, 21, 22, 25, 27, 28, 30, 31, 32]
const WEIGHTED_GREEDY_SW_16_WEIGHTS = [
    0.17702426479749597,
    0.03815408244118855,
    0.015579301860285315,
    0.20367879528292673,
    0.04200925659973763,
    0.016455490940877802,
    0.01974518735155143,
    0.026502831286670296,
    0.016856231416409018,
    0.0026632936984052353,
    0.0006871228074808986,
    0.20656413811365726,
    0.22368702192850093,
    0.0044141291625588875,
    0.0030199527744255643,
    0.0029588995378284455,
]
const WEIGHTED_GREEDY_SW_16_COEFFICIENT_SCALES = [
    0.8789, 1.0, 1.2791, 2.5312,
    1.0972, 1.0005, 0.5483, 2.1386,
    0.3031, 0.938, 0.0769, 0.5273,
    1.485, 1.8453, 1.6875, 0.8438,
]
const REDUCED_MODEL_METADATA = IdDict{Any, NamedTuple}()

function register_reduced_model(model; lw_indices = nothing, sw_indices = nothing,
                                lw_groups = nothing, sw_groups = nothing,
                                full_lw_weights = nothing, full_sw_weights = nothing,
                                use_reduced_incoming_weights = false,
                                lw_boundary_projection = nothing,
                                sw_boundary_projection = nothing)
    REDUCED_MODEL_METADATA[model] = (
        lw_indices = lw_indices,
        sw_indices = sw_indices,
        lw_groups = lw_groups,
        sw_groups = sw_groups,
        full_lw_weights = full_lw_weights,
        full_sw_weights = full_sw_weights,
        use_reduced_incoming_weights = use_reduced_incoming_weights,
        lw_boundary_projection = lw_boundary_projection,
        sw_boundary_projection = sw_boundary_projection,
    )
    return model
end

function uses_full_official_shortwave_weights(gas_optics)
    metadata = get(REDUCED_MODEL_METADATA, gas_optics, nothing)
    return metadata === nothing
end

function uses_reduced_incoming_shortwave_weights(gas_optics)
    metadata = get(REDUCED_MODEL_METADATA, gas_optics, nothing)
    metadata === nothing && return false
    return hasproperty(metadata, :use_reduced_incoming_weights) &&
           metadata.use_reduced_incoming_weights
end

function copy_reduced_metadata!(target, source)
    metadata = get(REDUCED_MODEL_METADATA, source, nothing)
    metadata === nothing || (REDUCED_MODEL_METADATA[target] = metadata)
    return target
end

function reduced_accuracy_softmax(values)
    shifted = values .- maximum(values)
    exps = exp.(shifted)
    return exps ./ sum(exps)
end

function reduced_accuracy_json_object_section(text, key)
    marker = "\"$key\": {"
    start = findfirst(marker, text)
    start === nothing && return ""
    section_start = last(start) + 1
    depth = 1
    for i in section_start:lastindex(text)
        char = text[i]
        if char == '{'
            depth += 1
        elseif char == '}'
            depth -= 1
            depth == 0 && return text[section_start:i - 1]
        end
    end
    return ""
end

function final_parameters_from_preflight_section(section_key;
                                                 path = REDUCED_OPTIMIZATION_PREFLIGHT_JSON)
    isfile(path) || return nothing
    section = reduced_accuracy_json_object_section(read(path, String), section_key)
    section == "" && return nothing
    match = Base.match(r"\"final_parameters\"\s*:\s*\[([^\]]+)\]", section)
    match === nothing && return nothing
    values = parse.(Float64, split(match.captures[1], ","))
    length(values) == 3length(WEIGHTED_GREEDY_SW_16_INDICES) || return nothing
    return values
end

function latest_preflight_reduced_parameters()
    for section in (
            "post_coefficient_weight_refinement",
            "post_joint_coordinate_refinement",
            "coefficient_joint_direction_scan",
            "greedy_coordinate_descent",
        )
        parameters = final_parameters_from_preflight_section(section)
        parameters === nothing || return parameters
    end
    return nothing
end

function latest_preflight_pressure_band_table_moves(;
                                                    path =
                                                        REDUCED_OPTIMIZATION_PREFLIGHT_JSON)
    isfile(path) || return NamedTuple[]
    section = reduced_accuracy_json_object_section(
        read(path, String),
        "pressure_band_table_refinement",
    )
    section == "" && return NamedTuple[]
    moves_match = Base.match(r"\"accepted_moves\"\s*:\s*\[([\s\S]*?)\]\s*,\s*\"trajectory\"", section)
    moves_match === nothing && return NamedTuple[]
    moves_text = moves_match.captures[1]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_text)
        object = match.captures[1]
        component_match = Base.match(r"\"component\"\s*:\s*\"([^\"]+)\"", object)
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        gpoint_match = Base.match(r"\"gpoint\"\s*:\s*([0-9]+)", object)
        band_match = Base.match(r"\"band\"\s*:\s*([0-9]+)", object)
        start_match = Base.match(r"\"pressure_index_start\"\s*:\s*([0-9]+)", object)
        end_match = Base.match(r"\"pressure_index_end\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if component_match === nothing ||
           local_match === nothing ||
           gpoint_match === nothing ||
           band_match === nothing ||
           start_match === nothing ||
           end_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = component_match.captures[1],
            local_gpoint_index = parse(Int, local_match.captures[1]),
            gpoint = parse(Int, gpoint_match.captures[1]),
            band = parse(Int, band_match.captures[1]),
            pressure_index_start = parse(Int, start_match.captures[1]),
            pressure_index_end = parse(Int, end_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function latest_active_table_entry_moves_from_section(section_key;
                                                      path =
                                                          REDUCED_OPTIMIZATION_PREFLIGHT_JSON)
    isfile(path) || return NamedTuple[]
    section = reduced_accuracy_json_object_section(
        read(path, String),
        section_key,
    )
    section == "" && return NamedTuple[]
    return latest_active_table_entry_moves_from_text(section, "accepted_moves")
end

function latest_active_table_entry_moves_from_text(text, array_key)
    moves_match = Base.match(
        Regex("\"$(array_key)\"\\s*:\\s*\\[([\\s\\S]*?)\\]\\s*(?:,|\\})"),
        text,
    )
    moves_match === nothing && return NamedTuple[]
    moves_text = moves_match.captures[1]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_text)
        object = match.captures[1]
        component_match = Base.match(r"\"component\"\s*:\s*\"([^\"]+)\"", object)
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        gpoint_match = Base.match(r"\"gpoint\"\s*:\s*([0-9]+)", object)
        gas_match = Base.match(r"\"gas_index\"\s*:\s*([0-9]+)", object)
        pressure_match = Base.match(r"\"pressure_index\"\s*:\s*([0-9]+)", object)
        temperature_match = Base.match(r"\"temperature_index\"\s*:\s*([0-9]+)", object)
        h2o_match = Base.match(r"\"h2o_index\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if component_match === nothing ||
           local_match === nothing ||
           gpoint_match === nothing ||
           gas_match === nothing ||
           pressure_match === nothing ||
           temperature_match === nothing ||
           h2o_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = component_match.captures[1],
            local_gpoint_index = parse(Int, local_match.captures[1]),
            gpoint = parse(Int, gpoint_match.captures[1]),
            gas_index = parse(Int, gas_match.captures[1]),
            pressure_index = parse(Int, pressure_match.captures[1]),
            temperature_index = parse(Int, temperature_match.captures[1]),
            h2o_index = parse(Int, h2o_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

latest_preflight_active_table_entry_moves(;
                                          path =
                                              REDUCED_OPTIMIZATION_PREFLIGHT_JSON) =
    latest_active_table_entry_moves_from_section(
        "active_table_entry_refinement";
        path,
    )

latest_targeted_active_table_entry_moves(;
                                         path =
                                             REDUCED_TARGETED_ENTRY_REFINEMENT_JSON) =
    latest_active_table_entry_moves_from_section(
        "refinement";
        path,
    )

function latest_global_active_table_entry_moves(;
                                                path =
                                                    REDUCED_GLOBAL_ENTRY_REFINEMENT_JSON)
    isfile(path) || return NamedTuple[]
    section = reduced_accuracy_json_object_section(read(path, String), "refinement")
    section == "" && return NamedTuple[]
    return latest_active_table_entry_moves_from_text(section, "all_active_moves")
end

latest_global_block_active_table_entry_moves(;
                                             path =
                                                 REDUCED_GLOBAL_BLOCK_REFINEMENT_JSON) =
    latest_global_active_table_entry_moves(; path)

latest_global_block_linearized_active_table_entry_moves(;
                                                        path =
                                                            REDUCED_GLOBAL_BLOCK_LINEARIZED_REFIT_JSON) =
    isfile(path) ?
        latest_active_table_entry_moves_from_text(read(path, String), "all_active_moves") :
        NamedTuple[]

latest_joint_weight_block_active_table_entry_moves(;
                                                   path =
                                                       REDUCED_JOINT_WEIGHT_BLOCK_REFIT_JSON) =
    isfile(path) ?
        latest_active_table_entry_moves_from_text(read(path, String), "all_active_moves") :
        NamedTuple[]

latest_boundary_column_active_table_entry_moves(;
                                                path =
                                                    REDUCED_BOUNDARY_COLUMN_REFINEMENT_JSON) =
    isfile(path) ?
        latest_active_table_entry_moves_from_text(read(path, String), "all_active_moves") :
        NamedTuple[]

latest_boundary_column_block_active_table_entry_moves(;
                                                      path =
                                                          REDUCED_BOUNDARY_COLUMN_BLOCK_REFINEMENT_JSON) =
    isfile(path) ?
        latest_active_table_entry_moves_from_text(read(path, String), "all_active_moves") :
        NamedTuple[]

function latest_active_table_entry_final_objective(section_key;
                                                   path =
                                                       REDUCED_OPTIMIZATION_PREFLIGHT_JSON)
    isfile(path) || return Inf
    if isempty(section_key)
        text = read(path, String)
        match = Base.match(r"\"final_objective\"\s*:\s*([-+0-9.eE]+)", text)
        match === nothing && return Inf
        return parse(Float64, match.captures[1])
    end
    section = reduced_accuracy_json_object_section(read(path, String), section_key)
    section == "" && return Inf
    match = Base.match(r"\"final_objective\"\s*:\s*([-+0-9.eE]+)", section)
    match === nothing && return Inf
    return parse(Float64, match.captures[1])
end

function latest_exact_weight_refit_weights(; path = REDUCED_EXACT_WEIGHT_REFIT_JSON)
    isfile(path) || return nothing
    text = read(path, String)
    objective_match = Base.match(r"\"final_objective\"\s*:\s*([-+0-9.eE]+)", text)
    objective_match === nothing && return nothing
    weights_match = Base.match(r"\"final_weights\"\s*:\s*\[([^\]]+)\]", text)
    weights_match === nothing && return nothing
    weights = parse.(Float64, split(weights_match.captures[1], ","))
    length(weights) == length(WEIGHTED_GREEDY_SW_16_INDICES) || return nothing
    return (
        objective = parse(Float64, objective_match.captures[1]),
        weights = weights,
    )
end

function latest_joint_weight_block_refit_weights(;
                                                 path =
                                                     REDUCED_JOINT_WEIGHT_BLOCK_REFIT_JSON)
    isfile(path) || return nothing
    text = read(path, String)
    objective_match = Base.match(r"\"final_objective\"\s*:\s*([-+0-9.eE]+)", text)
    objective_match === nothing && return nothing
    weights_match = Base.match(r"\"final_weights\"\s*:\s*\[([^\]]+)\]", text)
    weights_match === nothing && return nothing
    weights = parse.(Float64, split(weights_match.captures[1], ","))
    length(weights) == length(WEIGHTED_GREEDY_SW_16_INDICES) || return nothing
    return (
        objective = parse(Float64, objective_match.captures[1]),
        weights = weights,
    )
end

function latest_post_constrained_weight_refit_weights(;
                                                      path =
                                                          REDUCED_POST_CONSTRAINED_WEIGHT_REFIT_JSON)
    isfile(path) || return nothing
    text = read(path, String)
    objective_match = Base.match(r"\"final_objective\"\s*:\s*([-+0-9.eE]+)", text)
    objective_match === nothing && return nothing
    initial_objective_match =
        Base.match(r"\"initial_objective\"\s*:\s*([-+0-9.eE]+)", text)
    initial_objective_match === nothing && return nothing
    final_objective = parse(Float64, objective_match.captures[1])
    initial_objective = parse(Float64, initial_objective_match.captures[1])
    final_objective <= initial_objective || return nothing
    weights_match = Base.match(r"\"final_weights\"\s*:\s*\[([^\]]+)\]", text)
    weights_match === nothing && return nothing
    weights = parse.(Float64, split(weights_match.captures[1], ","))
    length(weights) == length(WEIGHTED_GREEDY_SW_16_INDICES) || return nothing
    return (
        objective = final_objective,
        weights = weights,
    )
end

function latest_post_constrained_boundary_weight_refit_weights(;
                                                               path =
                                                                   REDUCED_POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_JSON)
    isfile(path) || return nothing
    text = read(path, String)
    occursin("\"accepted\": true", text) || return nothing
    objective_match =
        Base.match(r"\"final_boundary_objective\"\s*:\s*([-+0-9.eE]+)", text)
    objective_match === nothing && return nothing
    weights_match = Base.match(r"\"final_weights\"\s*:\s*\[([^\]]+)\]", text)
    weights_match === nothing && return nothing
    weights = parse.(Float64, split(weights_match.captures[1], ","))
    length(weights) == length(WEIGHTED_GREEDY_SW_16_INDICES) || return nothing
    return (
        objective = parse(Float64, objective_match.captures[1]),
        weights = weights,
    )
end

function latest_post_slot_weight_refit_weights(;
                                               path =
                                                   REDUCED_POST_SLOT_WEIGHT_REFIT_JSON)
    isfile(path) || return nothing
    text = read(path, String)
    objective_match = Base.match(r"\"final_objective\"\s*:\s*([-+0-9.eE]+)", text)
    objective_match === nothing && return nothing
    initial_objective_match =
        Base.match(r"\"initial_objective\"\s*:\s*([-+0-9.eE]+)", text)
    initial_objective_match === nothing && return nothing
    final_objective = parse(Float64, objective_match.captures[1])
    initial_objective = parse(Float64, initial_objective_match.captures[1])
    final_objective < initial_objective || return nothing
    weights_match = Base.match(r"\"final_weights\"\s*:\s*\[([^\]]+)\]", text)
    weights_match === nothing && return nothing
    weights = parse.(Float64, split(weights_match.captures[1], ","))
    length(weights) == length(WEIGHTED_GREEDY_SW_16_INDICES) || return nothing
    return (
        objective = final_objective,
        weights = weights,
    )
end

function latest_leave_one_out_boundary_polish_weights(;
                                                      path =
                                                          REDUCED_LEAVE_ONE_OUT_WEIGHT_COORDINATE_BOUNDARY_POLISH_JSON)
    isfile(path) || return nothing
    text = read(path, String)
    objective_match = Base.match(r"\"final_objective\"\s*:\s*([-+0-9.eE]+)", text)
    objective_match === nothing && return nothing
    final_objective = parse(Float64, objective_match.captures[1])
    final_objective <= 1.0 || return nothing
    gpoints_match =
        Base.match(r"\"selected_shortwave_gpoints\"\s*:\s*\[([^\]]+)\]", text)
    weights_match = Base.match(r"\"final_weights\"\s*:\s*\[([^\]]+)\]", text)
    gpoints_match === nothing && return nothing
    weights_match === nothing && return nothing
    gpoints = parse.(Int, split(gpoints_match.captures[1], ","))
    weights = parse.(Float64, split(weights_match.captures[1], ","))
    length(gpoints) == length(weights) || return nothing
    length(gpoints) == 31 || return nothing
    return (
        objective = final_objective,
        gpoints = gpoints,
        weights = weights,
    )
end

function leave_one_out_boundary_polish_model(model)
    polish = latest_leave_one_out_boundary_polish_weights()
    polish === nothing &&
        error("missing passing leave-one-out weight-coordinate boundary-polish artifact")
    reduced = indexed_tabulated_model(
        model,
        collect(1:size(model.longwave_absorption, 1)),
        polish.gpoints,
    )
    reduced.shortwave_weights .= polish.weights
    return reduced
end

function latest_slot_blend_refinement_moves(;
                                           path =
                                               REDUCED_SLOT_BLEND_REFINEMENT_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    section_match = Base.match(r"\"all_blends\"\s*:\s*\[([\s\S]*?)\]\s*,", text)
    if section_match === nothing
        section_match = Base.match(
            r"\"accepted_blends\"\s*:\s*\[([\s\S]*?)\]\s*,",
            text,
        )
    end
    section_match === nothing && return NamedTuple[]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", section_match.captures[1])
        object = match.captures[1]
        local_match = Base.match(r"\"local_index\"\s*:\s*([0-9]+)", object)
        source_match = Base.match(r"\"source_gpoint\"\s*:\s*([0-9]+)", object)
        blend_match = Base.match(r"\"blend_gpoint\"\s*:\s*([0-9]+)", object)
        alpha_match = Base.match(r"\"alpha\"\s*:\s*([-+0-9.eE]+)", object)
        if local_match === nothing || source_match === nothing ||
           blend_match === nothing || alpha_match === nothing
            continue
        end
        push!(moves, (
            local_index = parse(Int, local_match.captures[1]),
            source_gpoint = parse(Int, source_match.captures[1]),
            blend_gpoint = parse(Int, blend_match.captures[1]),
            alpha = parse(Float64, alpha_match.captures[1]),
        ))
    end
    return moves
end

function apply_slot_blend_refinement_moves!(model, full_model, moves)
    for move in moves
        alpha = clamp(move.alpha, 0.0, 1.0)
        ig = move.local_index
        jg = move.blend_gpoint
        model.shortwave_absorption[ig, :, :, :] .=
            (1 - alpha) .* model.shortwave_absorption[ig, :, :, :] .+
            alpha .* full_model.shortwave_absorption[jg, :, :, :]
        if length(model.shortwave_h2o_absorption) != 0 &&
           length(full_model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[ig, :, :, :] .=
                (1 - alpha) .* model.shortwave_h2o_absorption[ig, :, :, :] .+
                alpha .* full_model.shortwave_h2o_absorption[jg, :, :, :]
        end
        model.shortwave_rayleigh_molar_scattering[ig] =
            (1 - alpha) * model.shortwave_rayleigh_molar_scattering[ig] +
            alpha * full_model.shortwave_rayleigh_molar_scattering[jg]
    end
    return model
end

function latest_gas_pressure_band_refinement_moves(;
                                                   path =
                                                       REDUCED_GAS_PRESSURE_BAND_REFINEMENT_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    moves = latest_gas_pressure_band_moves_from_text(text, "all_moves")
    isempty(moves) ? latest_gas_pressure_band_moves_from_text(text, "accepted_moves") :
    moves
end

function latest_gas_pressure_band_moves_from_text(text, array_key)
    moves_match = Base.match(Regex("\"$(array_key)\"\\s*:\\s*\\[([\\s\\S]*?)\\]\\s*,"),
                             text)
    moves_match === nothing && return NamedTuple[]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_match.captures[1])
        object = match.captures[1]
        component_match = Base.match(r"\"component\"\s*:\s*\"([^\"]+)\"", object)
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        gpoint_match = Base.match(r"\"gpoint\"\s*:\s*([0-9]+)", object)
        gas_match = Base.match(r"\"gas_index\"\s*:\s*([0-9]+)", object)
        start_match = Base.match(r"\"pressure_index_start\"\s*:\s*([0-9]+)", object)
        end_match = Base.match(r"\"pressure_index_end\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if component_match === nothing || local_match === nothing ||
           gpoint_match === nothing || gas_match === nothing ||
           start_match === nothing || end_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = component_match.captures[1],
            local_gpoint_index = parse(Int, local_match.captures[1]),
            gpoint = parse(Int, gpoint_match.captures[1]),
            gas_index = parse(Int, gas_match.captures[1]),
            pressure_index_start = parse(Int, start_match.captures[1]),
            pressure_index_end = parse(Int, end_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function apply_gas_pressure_band_refinement_moves!(model, moves)
    for move in moves
        scale = exp(clamp(move.log_scale, -5.0, 5.0))
        band = move.pressure_index_start:move.pressure_index_end
        ig = move.local_gpoint_index
        if move.component == "static_absorption"
            model.shortwave_absorption[ig, move.gas_index, band, :] .*= scale
        elseif move.component == "dynamic_h2o"
            if length(model.shortwave_h2o_absorption) != 0
                model.shortwave_h2o_absorption[ig, band, :, :] .*= scale
            end
        else
            throw(ArgumentError("unsupported gas pressure-band component $(move.component)"))
        end
    end
    return model
end

function apply_best_exact_weight_refit!(model; base_objective = Inf)
    candidates = filter(!isnothing, Any[
        latest_exact_weight_refit_weights(),
        latest_joint_weight_block_refit_weights(),
    ])
    isempty(candidates) && return model
    _, best_index = findmin(candidate -> candidate.objective, candidates)
    refit = candidates[best_index]
    refit.objective < base_objective || isinf(base_objective) || return model
    model.shortwave_weights .= refit.weights
    return model
end

function apply_post_constrained_weight_refit!(model)
    refit = latest_post_constrained_weight_refit_weights()
    refit === nothing && return model
    model.shortwave_weights .= refit.weights
    return model
end

function apply_post_constrained_boundary_weight_refit!(model)
    refit = latest_post_constrained_boundary_weight_refit_weights()
    refit === nothing && return model
    model.shortwave_weights .= refit.weights
    return model
end

function apply_post_slot_weight_refit!(model)
    refit = latest_post_slot_weight_refit_weights()
    refit === nothing && return model
    model.shortwave_weights .= refit.weights
    return model
end

function best_available_active_table_entry_moves()
    preflight_moves = latest_preflight_active_table_entry_moves()
    preflight_objective = latest_active_table_entry_final_objective(
        "active_table_entry_refinement",
    )
    targeted_moves = latest_targeted_active_table_entry_moves()
    targeted_objective = latest_active_table_entry_final_objective(
        "refinement";
        path = REDUCED_TARGETED_ENTRY_REFINEMENT_JSON,
    )
    global_moves = latest_global_active_table_entry_moves()
    global_objective = latest_active_table_entry_final_objective(
        "refinement";
        path = REDUCED_GLOBAL_ENTRY_REFINEMENT_JSON,
    )
    global_block_moves = latest_global_block_active_table_entry_moves()
    global_block_objective = latest_active_table_entry_final_objective(
        "refinement";
        path = REDUCED_GLOBAL_BLOCK_REFINEMENT_JSON,
    )
    global_block_linearized_moves =
        latest_global_block_linearized_active_table_entry_moves()
    global_block_linearized_objective = latest_active_table_entry_final_objective(
        "";
        path = REDUCED_GLOBAL_BLOCK_LINEARIZED_REFIT_JSON,
    )
    joint_weight_block_moves =
        latest_joint_weight_block_active_table_entry_moves()
    joint_weight_block_objective = latest_active_table_entry_final_objective(
        "";
        path = REDUCED_JOINT_WEIGHT_BLOCK_REFIT_JSON,
    )
    boundary_column_moves = latest_boundary_column_active_table_entry_moves()
    boundary_column_objective = latest_active_table_entry_final_objective(
        "";
        path = REDUCED_BOUNDARY_COLUMN_REFINEMENT_JSON,
    )
    boundary_column_block_moves =
        latest_boundary_column_block_active_table_entry_moves()
    boundary_column_block_objective = latest_active_table_entry_final_objective(
        "";
        path = REDUCED_BOUNDARY_COLUMN_BLOCK_REFINEMENT_JSON,
    )
    best_moves = preflight_moves
    best_objective = preflight_objective
    if !isempty(targeted_moves) && targeted_objective < best_objective
        best_moves = targeted_moves
        best_objective = targeted_objective
    end
    if !isempty(global_moves) && global_objective < best_objective
        best_moves = global_moves
        best_objective = global_objective
    end
    if !isempty(global_block_moves) && global_block_objective < best_objective
        best_moves = global_block_moves
        best_objective = global_block_objective
    end
    if !isempty(global_block_linearized_moves) &&
       global_block_linearized_objective < best_objective
        best_moves = global_block_linearized_moves
        best_objective = global_block_linearized_objective
    end
    if !isempty(joint_weight_block_moves) &&
       joint_weight_block_objective < best_objective
        best_moves = joint_weight_block_moves
        best_objective = joint_weight_block_objective
    end
    if !isempty(boundary_column_moves) && boundary_column_objective < best_objective
        best_moves = boundary_column_moves
        best_objective = boundary_column_objective
    end
    if !isempty(boundary_column_block_moves) &&
       boundary_column_block_objective < best_objective
        best_moves = boundary_column_block_moves
    end
    return best_moves
end

function apply_weight_absorption_rayleigh_parameters!(model, parameters)
    ng = size(model.shortwave_absorption, 1)
    length(parameters) == 3ng ||
        throw(DimensionMismatch("optimized reduced parameter vector must have 3 * ng_sw entries"))
    model.shortwave_weights .= reduced_accuracy_softmax(parameters[1:ng])
    absorption_scales = exp.(clamp.(parameters[(ng + 1):(2ng)], -5.0, 5.0))
    rayleigh_scales = exp.(clamp.(parameters[(2ng + 1):(3ng)], -5.0, 5.0))
    for ig in 1:ng
        model.shortwave_absorption[ig, :, :, :] .*= absorption_scales[ig]
        if length(model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[ig, :, :, :] .*= absorption_scales[ig]
        end
        model.shortwave_rayleigh_molar_scattering[ig] *= rayleigh_scales[ig]
    end
    return model
end

function apply_pressure_band_table_moves!(model, moves)
    for move in moves
        scale = exp(clamp(move.log_scale, -5.0, 5.0))
        band = move.pressure_index_start:move.pressure_index_end
        ig = move.local_gpoint_index
        if move.component == "static_absorption"
            model.shortwave_absorption[ig, :, band, :] .*= scale
        elseif move.component == "dynamic_h2o"
            if length(model.shortwave_h2o_absorption) != 0
                model.shortwave_h2o_absorption[ig, band, :, :] .*= scale
            end
        else
            throw(ArgumentError("unsupported pressure-band table component $(move.component)"))
        end
    end
    return model
end

function latest_constrained_table_optimizer_moves(;
                                                  path =
                                                      REDUCED_CONSTRAINED_TABLE_OPTIMIZER_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    moves = latest_active_table_entry_moves_from_text(text, "all_active_moves")
    !isempty(moves) && return moves
    occursin("\"accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_boundary_base_constrained_table_optimizer_moves(;
                                                                path =
                                                                    REDUCED_BOUNDARY_BASE_CONSTRAINED_TABLE_OPTIMIZER_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_boundary_table_continuation_optimizer_moves(;
                                                            path =
                                                                REDUCED_BOUNDARY_TABLE_CONTINUATION_OPTIMIZER_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_structural_optimizer_moves(;
                                                    path =
                                                        REDUCED_RETAINED_STRUCTURAL_OPTIMIZER_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_STRUCTURAL_OPTIMIZER", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_structural_continuation_moves(;
                                                       path =
                                                           REDUCED_RETAINED_STRUCTURAL_CONTINUATION_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_STRUCTURAL_CONTINUATION", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_structural_continuation2_moves(;
                                                        path =
                                                            REDUCED_RETAINED_STRUCTURAL_CONTINUATION2_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_STRUCTURAL_CONTINUATION2", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_structural_continuation3_moves(;
                                                        path =
                                                            REDUCED_RETAINED_STRUCTURAL_CONTINUATION3_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_STRUCTURAL_CONTINUATION3", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_structural_continuation4_moves(;
                                                        path =
                                                            REDUCED_RETAINED_STRUCTURAL_CONTINUATION4_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_STRUCTURAL_CONTINUATION4", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_objective_probe_expansion_moves(;
                                                         path =
                                                             REDUCED_RETAINED_OBJECTIVE_PROBE_EXPANSION_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_OBJECTIVE_PROBE_EXPANSION", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"any_accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_objective_probe_expansion2_moves(;
                                                          path =
                                                              REDUCED_RETAINED_OBJECTIVE_PROBE_EXPANSION2_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_OBJECTIVE_PROBE_EXPANSION2", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"any_accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_objective_probe_expansion3_moves(;
                                                          path =
                                                              REDUCED_RETAINED_OBJECTIVE_PROBE_EXPANSION3_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_OBJECTIVE_PROBE_EXPANSION3", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"any_accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_objective_probe_expansion4_moves(;
                                                          path =
                                                              REDUCED_RETAINED_OBJECTIVE_PROBE_EXPANSION4_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_OBJECTIVE_PROBE_EXPANSION4", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"any_accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_surface_probe_expansion_moves(;
                                                       path =
                                                           REDUCED_RETAINED_SURFACE_PROBE_EXPANSION_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_SURFACE_PROBE_EXPANSION", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"any_accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_surface_probe_expansion2_moves(;
                                                        path =
                                                            REDUCED_RETAINED_SURFACE_PROBE_EXPANSION2_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_SURFACE_PROBE_EXPANSION2", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"any_accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_surface_probe_expansion3_moves(;
                                                        path =
                                                            REDUCED_RETAINED_SURFACE_PROBE_EXPANSION3_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_SURFACE_PROBE_EXPANSION3", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"any_accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_toa_probe_expansion_moves(;
                                                   path =
                                                       REDUCED_RETAINED_TOA_PROBE_EXPANSION_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_TOA_PROBE_EXPANSION", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"any_accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_boundary_table_coordinate_scan_moves(;
                                                     path =
                                                        REDUCED_BOUNDARY_TABLE_COORDINATE_SCAN_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_boundary_table_pair_coordinate_scan_moves(;
                                                          path =
                                                            REDUCED_BOUNDARY_TABLE_PAIR_COORDINATE_SCAN_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_boundary_table_coordinate_descent_moves(;
                                                        path =
                                                            REDUCED_BOUNDARY_TABLE_COORDINATE_DESCENT_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_component_scale_refit_moves(;
                                            path =
                                                REDUCED_COMPONENT_SCALE_REFIT_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    moves_match = Base.match(
        r"\"accepted_moves\"\s*:\s*\[([\s\S]*?)\]\s*,\s*\"component_log_scales\"",
        text,
    )
    moves_match === nothing && return NamedTuple[]
    moves_text = moves_match.captures[1]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_text)
        object = match.captures[1]
        component_match = Base.match(r"\"component\"\s*:\s*\"([^\"]+)\"", object)
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        parameter_match = Base.match(r"\"parameter_index\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if component_match === nothing ||
           local_match === nothing ||
           parameter_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = component_match.captures[1],
            local_gpoint_index = parse(Int, local_match.captures[1]),
            parameter_index = parse(Int, parameter_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function latest_pressure_component_scale_refit_moves(;
                                                     path =
                                                        REDUCED_PRESSURE_COMPONENT_SCALE_REFIT_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    moves_match = Base.match(
        r"\"accepted_moves\"\s*:\s*\[([\s\S]*?)\]\s*,\s*\"iterations\"",
        text,
    )
    moves_match === nothing && return NamedTuple[]
    moves_text = moves_match.captures[1]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_text)
        object = match.captures[1]
        component_match = Base.match(r"\"component\"\s*:\s*\"([^\"]+)\"", object)
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        start_match = Base.match(r"\"pressure_index_start\"\s*:\s*([0-9]+)", object)
        end_match = Base.match(r"\"pressure_index_end\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if component_match === nothing ||
           local_match === nothing ||
           start_match === nothing ||
           end_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = component_match.captures[1],
            local_gpoint_index = parse(Int, local_match.captures[1]),
            pressure_index_start = parse(Int, start_match.captures[1]),
            pressure_index_end = parse(Int, end_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function latest_temperature_component_scale_refit_moves(;
                                                        path =
                                                            REDUCED_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    moves_match = Base.match(
        r"\"accepted_moves\"\s*:\s*\[([\s\S]*?)\]\s*,\s*\"iterations\"",
        text,
    )
    moves_match === nothing && return NamedTuple[]
    moves_text = moves_match.captures[1]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_text)
        object = match.captures[1]
        component_match = Base.match(r"\"component\"\s*:\s*\"([^\"]+)\"", object)
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        start_match = Base.match(r"\"temperature_index_start\"\s*:\s*([0-9]+)", object)
        end_match = Base.match(r"\"temperature_index_end\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if component_match === nothing ||
           local_match === nothing ||
           start_match === nothing ||
           end_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = component_match.captures[1],
            local_gpoint_index = parse(Int, local_match.captures[1]),
            temperature_index_start = parse(Int, start_match.captures[1]),
            temperature_index_end = parse(Int, end_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function latest_h2o_component_scale_refit_moves(;
                                                path = REDUCED_H2O_COMPONENT_SCALE_REFIT_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    moves_match = Base.match(
        r"\"accepted_moves\"\s*:\s*\[([\s\S]*?)\]\s*,\s*\"iterations\"",
        text,
    )
    moves_match === nothing && return NamedTuple[]
    moves_text = moves_match.captures[1]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_text)
        object = match.captures[1]
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        start_match = Base.match(r"\"h2o_index_start\"\s*:\s*([0-9]+)", object)
        end_match = Base.match(r"\"h2o_index_end\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if local_match === nothing ||
           start_match === nothing ||
           end_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = "h2o_absorption",
            local_gpoint_index = parse(Int, local_match.captures[1]),
            h2o_index_start = parse(Int, start_match.captures[1]),
            h2o_index_end = parse(Int, end_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function latest_gas_component_scale_refit_moves(;
                                                path = REDUCED_GAS_COMPONENT_SCALE_REFIT_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    moves_match = Base.match(
        r"\"accepted_moves\"\s*:\s*\[([\s\S]*?)\]\s*,\s*\"iterations\"",
        text,
    )
    moves_match === nothing && return NamedTuple[]
    moves_text = moves_match.captures[1]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_text)
        object = match.captures[1]
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        gas_match = Base.match(r"\"gas_index\"\s*:\s*([0-9]+)", object)
        gas_name_match = Base.match(r"\"gas_name\"\s*:\s*\"([^\"]+)\"", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if local_match === nothing ||
           gas_match === nothing ||
           gas_name_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = "static_absorption",
            local_gpoint_index = parse(Int, local_match.captures[1]),
            gas_index = parse(Int, gas_match.captures[1]),
            gas_name = gas_name_match.captures[1],
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function latest_pressure_temperature_component_scale_refit_moves(;
                                                                 path =
                                                                    REDUCED_PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    moves_match = Base.match(
        r"\"accepted_moves\"\s*:\s*\[([\s\S]*?)\]\s*,\s*\"iterations\"",
        text,
    )
    moves_match === nothing && return NamedTuple[]
    moves_text = moves_match.captures[1]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_text)
        object = match.captures[1]
        component_match = Base.match(r"\"component\"\s*:\s*\"([^\"]+)\"", object)
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        pressure_start_match =
            Base.match(r"\"pressure_index_start\"\s*:\s*([0-9]+)", object)
        pressure_end_match =
            Base.match(r"\"pressure_index_end\"\s*:\s*([0-9]+)", object)
        temperature_start_match =
            Base.match(r"\"temperature_index_start\"\s*:\s*([0-9]+)", object)
        temperature_end_match =
            Base.match(r"\"temperature_index_end\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if component_match === nothing ||
           local_match === nothing ||
           pressure_start_match === nothing ||
           pressure_end_match === nothing ||
           temperature_start_match === nothing ||
           temperature_end_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = component_match.captures[1],
            local_gpoint_index = parse(Int, local_match.captures[1]),
            pressure_index_start = parse(Int, pressure_start_match.captures[1]),
            pressure_index_end = parse(Int, pressure_end_match.captures[1]),
            temperature_index_start = parse(Int, temperature_start_match.captures[1]),
            temperature_index_end = parse(Int, temperature_end_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function latest_gas_pressure_temperature_component_scale_refit_moves(;
                                                                     path =
                                                                        REDUCED_GAS_PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    moves_match = Base.match(
        r"\"accepted_moves\"\s*:\s*\[([\s\S]*?)\]\s*,\s*\"iterations\"",
        text,
    )
    moves_match === nothing && return NamedTuple[]
    moves_text = moves_match.captures[1]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_text)
        object = match.captures[1]
        component_match = Base.match(r"\"component\"\s*:\s*\"([^\"]+)\"", object)
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        gas_match = Base.match(r"\"gas_index\"\s*:\s*([0-9]+)", object)
        pressure_start_match =
            Base.match(r"\"pressure_index_start\"\s*:\s*([0-9]+)", object)
        pressure_end_match =
            Base.match(r"\"pressure_index_end\"\s*:\s*([0-9]+)", object)
        temperature_start_match =
            Base.match(r"\"temperature_index_start\"\s*:\s*([0-9]+)", object)
        temperature_end_match =
            Base.match(r"\"temperature_index_end\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if component_match === nothing ||
           local_match === nothing ||
           gas_match === nothing ||
           pressure_start_match === nothing ||
           pressure_end_match === nothing ||
           temperature_start_match === nothing ||
           temperature_end_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = component_match.captures[1],
            local_gpoint_index = parse(Int, local_match.captures[1]),
            gas_index = parse(Int, gas_match.captures[1]),
            pressure_index_start = parse(Int, pressure_start_match.captures[1]),
            pressure_index_end = parse(Int, pressure_end_match.captures[1]),
            temperature_index_start = parse(Int, temperature_start_match.captures[1]),
            temperature_index_end = parse(Int, temperature_end_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function latest_h2o_pressure_temperature_component_scale_refit_moves(;
                                                                     path =
                                                                        REDUCED_H2O_PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    moves_match = Base.match(
        r"\"accepted_moves\"\s*:\s*\[([\s\S]*?)\]\s*,\s*\"iterations\"",
        text,
    )
    moves_match === nothing && return NamedTuple[]
    moves_text = moves_match.captures[1]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_text)
        object = match.captures[1]
        component_match = Base.match(r"\"component\"\s*:\s*\"([^\"]+)\"", object)
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        pressure_start_match =
            Base.match(r"\"pressure_index_start\"\s*:\s*([0-9]+)", object)
        pressure_end_match =
            Base.match(r"\"pressure_index_end\"\s*:\s*([0-9]+)", object)
        temperature_start_match =
            Base.match(r"\"temperature_index_start\"\s*:\s*([0-9]+)", object)
        temperature_end_match =
            Base.match(r"\"temperature_index_end\"\s*:\s*([0-9]+)", object)
        h2o_start_match =
            Base.match(r"\"h2o_index_start\"\s*:\s*([0-9]+)", object)
        h2o_end_match =
            Base.match(r"\"h2o_index_end\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if component_match === nothing ||
           local_match === nothing ||
           pressure_start_match === nothing ||
           pressure_end_match === nothing ||
           temperature_start_match === nothing ||
           temperature_end_match === nothing ||
           h2o_start_match === nothing ||
           h2o_end_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = component_match.captures[1],
            local_gpoint_index = parse(Int, local_match.captures[1]),
            pressure_index_start = parse(Int, pressure_start_match.captures[1]),
            pressure_index_end = parse(Int, pressure_end_match.captures[1]),
            temperature_index_start = parse(Int, temperature_start_match.captures[1]),
            temperature_index_end = parse(Int, temperature_end_match.captures[1]),
            h2o_index_start = parse(Int, h2o_start_match.captures[1]),
            h2o_index_end = parse(Int, h2o_end_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function latest_mixed_pressure_temperature_component_refit_moves(;
                                                                 path =
                                                                    REDUCED_MIXED_PRESSURE_TEMPERATURE_COMPONENT_REFIT_JSON)
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    moves_match = Base.match(
        r"\"accepted_moves\"\s*:\s*\[([\s\S]*?)\]\s*,\s*\"iterations\"",
        text,
    )
    moves_match === nothing && return NamedTuple[]
    moves_text = moves_match.captures[1]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_text)
        object = match.captures[1]
        component_match = Base.match(r"\"component\"\s*:\s*\"([^\"]+)\"", object)
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        gas_match = Base.match(r"\"gas_index\"\s*:\s*([0-9]+)", object)
        pressure_start_match =
            Base.match(r"\"pressure_index_start\"\s*:\s*([0-9]+)", object)
        pressure_end_match =
            Base.match(r"\"pressure_index_end\"\s*:\s*([0-9]+)", object)
        temperature_start_match =
            Base.match(r"\"temperature_index_start\"\s*:\s*([0-9]+)", object)
        temperature_end_match =
            Base.match(r"\"temperature_index_end\"\s*:\s*([0-9]+)", object)
        h2o_start_match =
            Base.match(r"\"h2o_index_start\"\s*:\s*([0-9]+)", object)
        h2o_end_match =
            Base.match(r"\"h2o_index_end\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if component_match === nothing ||
           local_match === nothing ||
           gas_match === nothing ||
           pressure_start_match === nothing ||
           pressure_end_match === nothing ||
           temperature_start_match === nothing ||
           temperature_end_match === nothing ||
           h2o_start_match === nothing ||
           h2o_end_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = component_match.captures[1],
            local_gpoint_index = parse(Int, local_match.captures[1]),
            gas_index = parse(Int, gas_match.captures[1]),
            pressure_index_start = parse(Int, pressure_start_match.captures[1]),
            pressure_index_end = parse(Int, pressure_end_match.captures[1]),
            temperature_index_start = parse(Int, temperature_start_match.captures[1]),
            temperature_index_end = parse(Int, temperature_end_match.captures[1]),
            h2o_index_start = parse(Int, h2o_start_match.captures[1]),
            h2o_index_end = parse(Int, h2o_end_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function latest_retained_mixed_component_pareto_scan_moves(;
                                                           path =
                                                            REDUCED_RETAINED_MIXED_COMPONENT_PARETO_SCAN_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_MIXED_COMPONENT_PARETO_SCAN", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    return latest_mixed_pressure_temperature_component_refit_moves(; path)
end

function latest_retained_capped_table_optimizer_moves(;
                                                      path =
                                                          REDUCED_RETAINED_CAPPED_TABLE_OPTIMIZER_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_CAPPED_TABLE_OPTIMIZER", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_capped_table_continuation_moves(;
                                                         path =
                                                             REDUCED_RETAINED_CAPPED_TABLE_CONTINUATION_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_CAPPED_TABLE_CONTINUATION", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_post_capped_weight_refit_weights(;
                                                          path =
                                                              REDUCED_RETAINED_POST_CAPPED_WEIGHT_REFIT_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_POST_CAPPED_WEIGHT_REFIT", "false")) in
    ("1", "true", "yes") && return nothing
    isfile(path) || return nothing
    text = read(path, String)
    occursin("\"accepted\": true", text) || return nothing
    weights_match = Base.match(r"\"final_weights\"\s*:\s*\[([^\]]+)\]", text)
    weights_match === nothing && return nothing
    weights = parse.(Float64, split(weights_match.captures[1], ","))
    length(weights) == length(WEIGHTED_GREEDY_SW_16_INDICES) || return nothing
    objective_match = Base.match(r"\"final_objective\"\s*:\s*([-+0-9.eE]+)", text)
    objective_match === nothing && return nothing
    return (
        objective = parse(Float64, objective_match.captures[1]),
        weights = weights,
    )
end

function latest_retained_post_weight_surface_table_refit_moves(;
                                                               path =
                                                                   REDUCED_RETAINED_POST_WEIGHT_SURFACE_TABLE_REFIT_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_POST_WEIGHT_SURFACE_TABLE_REFIT", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    return latest_active_table_entry_moves_from_text(text, "accepted_moves")
end

function latest_retained_post_weight_bounded_weight_refit_weights(;
                                                                  path =
                                                                      REDUCED_RETAINED_POST_WEIGHT_BOUNDED_WEIGHT_REFIT_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_POST_WEIGHT_BOUNDED_WEIGHT_REFIT", "false")) in
    ("1", "true", "yes") && return nothing
    isfile(path) || return nothing
    text = read(path, String)
    occursin("\"accepted\": true", text) || return nothing
    weights_match = Base.match(r"\"final_weights\"\s*:\s*\[([^\]]+)\]", text)
    weights_match === nothing && return nothing
    weights = parse.(Float64, split(weights_match.captures[1], ","))
    length(weights) == length(WEIGHTED_GREEDY_SW_16_INDICES) || return nothing
    objective_match = Base.match(r"\"final_objective\"\s*:\s*([-+0-9.eE]+)", text)
    objective_match === nothing && return nothing
    return (
        objective = parse(Float64, objective_match.captures[1]),
        weights = weights,
    )
end

function latest_retained_current_component_scale_optimizer_moves(;
                                                                 path =
                                                                     REDUCED_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    deltas_match = Base.match(r"\"accepted_deltas\"\s*:\s*\[([^\]]+)\]", text)
    deltas_match === nothing && return NamedTuple[]
    deltas = parse.(Float64, split(deltas_match.captures[1], ","))
    ng = length(WEIGHTED_GREEDY_SW_16_INDICES)
    length(deltas) == 3ng || return NamedTuple[]
    moves = NamedTuple[]
    for (index, delta) in enumerate(deltas)
        delta == 0 && continue
        component = index <= ng ? "static_absorption" :
            index <= 2ng ? "h2o_absorption" : "rayleigh"
        local_gpoint_index = index <= ng ? index :
            index <= 2ng ? index - ng : index - 2ng
        push!(moves, (
            component = component,
            local_gpoint_index = local_gpoint_index,
            parameter_index = index,
            log_scale = delta,
            scale = exp(delta),
        ))
    end
    return moves
end

function latest_retained_current_component_scale_optimizer2_moves(;
                                                                  path =
                                                                      REDUCED_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER2_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER2", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    return latest_retained_current_component_scale_optimizer_moves(; path = path)
end

function latest_retained_current_component_scale_optimizer3_moves(;
                                                                  path =
                                                                      REDUCED_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER3_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER3", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    return latest_retained_current_component_scale_optimizer_moves(; path = path)
end

function latest_retained_current_component_scale_optimizer4_moves(;
                                                                  path =
                                                                      REDUCED_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER4_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER4", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    return latest_retained_current_component_scale_optimizer_moves(; path = path)
end

function latest_retained_current_pressure_component_optimizer_moves(;
                                                                    path =
                                                                        REDUCED_RETAINED_CURRENT_PRESSURE_COMPONENT_OPTIMIZER_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_CURRENT_PRESSURE_COMPONENT_OPTIMIZER", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"accepted\": true", text) || return NamedTuple[]
    moves_match = Base.match(
        r"\"accepted_moves\"\s*:\s*\[([\s\S]*?)\]\s*,\s*\"rows\"",
        text,
    )
    moves_match === nothing && return NamedTuple[]
    moves_text = moves_match.captures[1]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_text)
        object = match.captures[1]
        component_match = Base.match(r"\"component\"\s*:\s*\"([^\"]+)\"", object)
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        start_match = Base.match(r"\"pressure_index_start\"\s*:\s*([0-9]+)", object)
        end_match = Base.match(r"\"pressure_index_end\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if component_match === nothing ||
           local_match === nothing ||
           start_match === nothing ||
           end_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = component_match.captures[1],
            local_gpoint_index = parse(Int, local_match.captures[1]),
            pressure_index_start = parse(Int, start_match.captures[1]),
            pressure_index_end = parse(Int, end_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function latest_retained_current_pressure_component_scan_moves(;
                                                               path =
                                                                   REDUCED_RETAINED_CURRENT_PRESSURE_COMPONENT_SCAN_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_CURRENT_PRESSURE_COMPONENT_SCAN", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    isfile(path) || return NamedTuple[]
    text = read(path, String)
    occursin("\"status\": \"current_pressure_component_scan_improved\"", text) ||
        return NamedTuple[]
    moves_match = Base.match(
        r"\"selected_accepted_moves\"\s*:\s*\[([\s\S]*?)\]\s*,\s*\"variants\"",
        text,
    )
    moves_match === nothing && return NamedTuple[]
    moves_text = moves_match.captures[1]
    moves = NamedTuple[]
    for match in eachmatch(r"\{([\s\S]*?)\}", moves_text)
        object = match.captures[1]
        component_match = Base.match(r"\"component\"\s*:\s*\"([^\"]+)\"", object)
        local_match = Base.match(r"\"local_gpoint_index\"\s*:\s*([0-9]+)", object)
        start_match = Base.match(r"\"pressure_index_start\"\s*:\s*([0-9]+)", object)
        end_match = Base.match(r"\"pressure_index_end\"\s*:\s*([0-9]+)", object)
        scale_match = Base.match(r"\"log_scale\"\s*:\s*([-+0-9.eE]+)", object)
        if component_match === nothing ||
           local_match === nothing ||
           start_match === nothing ||
           end_match === nothing ||
           scale_match === nothing
            continue
        end
        push!(moves, (
            component = component_match.captures[1],
            local_gpoint_index = parse(Int, local_match.captures[1]),
            gas_index = begin
                gas_match = Base.match(r"\"gas_index\"\s*:\s*([0-9]+)", object)
                gas_match === nothing ? 0 : parse(Int, gas_match.captures[1])
            end,
            pressure_index_start = parse(Int, start_match.captures[1]),
            pressure_index_end = parse(Int, end_match.captures[1]),
            log_scale = parse(Float64, scale_match.captures[1]),
        ))
    end
    return moves
end

function latest_retained_current_gas_pressure_component_scan_moves(;
                                                                   path =
                                                                       REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_SCAN_JSON)
    lowercase(get(ENV, "RH_REDUCED_IGNORE_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_SCAN", "false")) in
    ("1", "true", "yes") && return NamedTuple[]
    return latest_retained_current_pressure_component_scan_moves(; path = path)
end

function latest_retained_current_gas_pressure_component_continuation_scan_moves(;
                                                                                path =
                                                                                    REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION_SCAN_JSON)
    lowercase(get(ENV,
                  "RH_REDUCED_IGNORE_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION_SCAN",
                  "false")) in ("1", "true", "yes") && return NamedTuple[]
    return latest_retained_current_pressure_component_scan_moves(; path = path)
end

function latest_retained_current_gas_pressure_component_continuation2_scan_moves(;
                                                                                 path =
                                                                                     REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION2_SCAN_JSON)
    lowercase(get(ENV,
                  "RH_REDUCED_IGNORE_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION2_SCAN",
                  "false")) in ("1", "true", "yes") && return NamedTuple[]
    return latest_retained_current_pressure_component_scan_moves(; path = path)
end

function latest_retained_current_gas_pressure_component_continuation3_scan_moves(;
                                                                                 path =
                                                                                     REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION3_SCAN_JSON)
    lowercase(get(ENV,
                  "RH_REDUCED_IGNORE_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION3_SCAN",
                  "false")) in ("1", "true", "yes") && return NamedTuple[]
    return latest_retained_current_pressure_component_scan_moves(; path = path)
end

function apply_active_table_entry_moves!(model, moves)
    for move in moves
        scale = exp(clamp(move.log_scale, -5.0, 5.0))
        ig = move.local_gpoint_index
        if move.component == "static_absorption"
            model.shortwave_absorption[
                ig,
                move.gas_index,
                move.pressure_index,
                move.temperature_index,
            ] *= scale
        elseif move.component == "dynamic_h2o"
            if length(model.shortwave_h2o_absorption) != 0
                model.shortwave_h2o_absorption[
                    ig,
                    move.pressure_index,
                    move.temperature_index,
                    move.h2o_index,
                ] *= scale
            end
        elseif move.component == "rayleigh"
            model.shortwave_rayleigh_molar_scattering[ig] *= scale
        else
            throw(ArgumentError("unsupported active table-entry component $(move.component)"))
        end
    end
    return model
end

function apply_component_scale_refit_moves!(model, moves)
    for move in moves
        scale = exp(clamp(move.log_scale, -5.0, 5.0))
        ig = move.local_gpoint_index
        if move.component == "static_absorption"
            model.shortwave_absorption[ig, :, :, :] .*= scale
        elseif move.component == "h2o_absorption"
            if length(model.shortwave_h2o_absorption) != 0
                model.shortwave_h2o_absorption[ig, :, :, :] .*= scale
            end
        elseif move.component == "rayleigh"
            model.shortwave_rayleigh_molar_scattering[ig] *= scale
        else
            throw(ArgumentError("unsupported component scale move $(move.component)"))
        end
    end
    return model
end

function apply_pressure_component_scale_refit_moves!(model, moves)
    for move in moves
        scale = exp(clamp(move.log_scale, -5.0, 5.0))
        ig = move.local_gpoint_index
        band = move.pressure_index_start:move.pressure_index_end
        if move.component == "static_absorption"
            gas_index = hasproperty(move, :gas_index) ? move.gas_index : 0
            if gas_index == 0
                model.shortwave_absorption[ig, :, band, :] .*= scale
            else
                model.shortwave_absorption[ig, gas_index, band, :] .*= scale
            end
        elseif move.component == "h2o_absorption"
            if length(model.shortwave_h2o_absorption) != 0
                model.shortwave_h2o_absorption[ig, band, :, :] .*= scale
            end
        else
            throw(ArgumentError("unsupported pressure component scale move $(move.component)"))
        end
    end
    return model
end

function apply_temperature_component_scale_refit_moves!(model, moves)
    for move in moves
        scale = exp(clamp(move.log_scale, -5.0, 5.0))
        ig = move.local_gpoint_index
        band = move.temperature_index_start:move.temperature_index_end
        if move.component == "static_absorption"
            model.shortwave_absorption[ig, :, :, band] .*= scale
        elseif move.component == "h2o_absorption"
            if length(model.shortwave_h2o_absorption) != 0
                model.shortwave_h2o_absorption[ig, :, band, :] .*= scale
            end
        else
            throw(ArgumentError("unsupported temperature component scale move $(move.component)"))
        end
    end
    return model
end

function apply_h2o_component_scale_refit_moves!(model, moves)
    for move in moves
        length(model.shortwave_h2o_absorption) == 0 && continue
        scale = exp(clamp(move.log_scale, -5.0, 5.0))
        ig = move.local_gpoint_index
        band = move.h2o_index_start:move.h2o_index_end
        model.shortwave_h2o_absorption[ig, :, :, band] .*= scale
    end
    return model
end

function apply_gas_component_scale_refit_moves!(model, moves)
    for move in moves
        scale = exp(clamp(move.log_scale, -5.0, 5.0))
        model.shortwave_absorption[
            move.local_gpoint_index,
            move.gas_index,
            :,
            :,
        ] .*= scale
    end
    return model
end

function apply_pressure_temperature_component_scale_refit_moves!(model, moves)
    for move in moves
        scale = exp(clamp(move.log_scale, -5.0, 5.0))
        ig = move.local_gpoint_index
        pressure_range = move.pressure_index_start:move.pressure_index_end
        temperature_range = move.temperature_index_start:move.temperature_index_end
        if move.component == "static_absorption"
            model.shortwave_absorption[ig, :, pressure_range, temperature_range] .*= scale
        elseif move.component == "h2o_absorption"
            if length(model.shortwave_h2o_absorption) != 0
                model.shortwave_h2o_absorption[ig, pressure_range, temperature_range, :] .*= scale
            end
        else
            throw(ArgumentError("unsupported pressure-temperature component scale move $(move.component)"))
        end
    end
    return model
end

function apply_gas_pressure_temperature_component_scale_refit_moves!(model, moves)
    for move in moves
        scale = exp(clamp(move.log_scale, -5.0, 5.0))
        model.shortwave_absorption[
            move.local_gpoint_index,
            move.gas_index,
            move.pressure_index_start:move.pressure_index_end,
            move.temperature_index_start:move.temperature_index_end,
        ] .*= scale
    end
    return model
end

function apply_h2o_pressure_temperature_component_scale_refit_moves!(model, moves)
    for move in moves
        length(model.shortwave_h2o_absorption) == 0 && continue
        scale = exp(clamp(move.log_scale, -5.0, 5.0))
        model.shortwave_h2o_absorption[
            move.local_gpoint_index,
            move.pressure_index_start:move.pressure_index_end,
            move.temperature_index_start:move.temperature_index_end,
            move.h2o_index_start:move.h2o_index_end,
        ] .*= scale
    end
    return model
end

function apply_mixed_pressure_temperature_component_refit_moves!(model, moves)
    for move in moves
        scale = exp(clamp(move.log_scale, -5.0, 5.0))
        pressure_range = move.pressure_index_start:move.pressure_index_end
        temperature_range = move.temperature_index_start:move.temperature_index_end
        if move.component == "static_absorption"
            model.shortwave_absorption[
                move.local_gpoint_index,
                move.gas_index,
                pressure_range,
                temperature_range,
            ] .*= scale
        elseif move.component == "h2o_absorption"
            length(model.shortwave_h2o_absorption) == 0 && continue
            model.shortwave_h2o_absorption[
                move.local_gpoint_index,
                pressure_range,
                temperature_range,
                move.h2o_index_start:move.h2o_index_end,
            ] .*= scale
        else
            throw(ArgumentError("unsupported mixed pressure-temperature move $(move.component)"))
        end
    end
    return model
end

function use_reduced_incoming_weights!(model)
    metadata = get(REDUCED_MODEL_METADATA, model, nothing)
    metadata === nothing && return model
    REDUCED_MODEL_METADATA[model] = (
        lw_indices = metadata.lw_indices,
        sw_indices = metadata.sw_indices,
        lw_groups = metadata.lw_groups,
        sw_groups = metadata.sw_groups,
        full_lw_weights = metadata.full_lw_weights,
        full_sw_weights = metadata.full_sw_weights,
        use_reduced_incoming_weights = true,
    )
    return model
end

function selected_gpoints(nfull, nreduced)
    nreduced <= nfull ||
        throw(ArgumentError("cannot select $nreduced g-points from $nfull"))
    nreduced == nfull && return collect(1:nfull)
    return unique(round.(Int, range(1, nfull; length = nreduced)))
end

function normalized_subset(weights, indices)
    subset = collect(weights[indices])
    total = sum(subset)
    total > 0 || error("selected spectral weights must have positive sum")
    return subset ./ total
end

function subset_or_empty(array, indices)
    length(array) == 0 && return array
    return array[indices, :, :, :]
end

function subset_or_empty(array::AbstractMatrix, indices)
    length(array) == 0 && return array
    return array[indices, :]
end

function gpoint_groups(nfull, nreduced)
    nreduced <= nfull ||
        throw(ArgumentError("cannot reduce $nfull g-points to $nreduced"))
    edges = round.(Int, range(1, nfull + 1; length = nreduced + 1))
    groups = [edges[i]:(edges[i + 1] - 1) for i in 1:nreduced]
    all(!isempty, groups) || error("empty g-point group generated")
    return groups
end

function normalized_group_weights(weights, groups)
    subset = [sum(weights[group]) for group in groups]
    total = sum(subset)
    total > 0 || error("selected spectral weights must have positive sum")
    return subset ./ total
end

function weighted_group_reduce(array::AbstractArray{FT, 4}, weights, groups) where FT
    length(array) == 0 && return array
    reduced = zeros(FT, length(groups), size(array, 2), size(array, 3), size(array, 4))
    for (i, group) in enumerate(groups)
        group_weight = sum(weights[group])
        group_weight > 0 || error("g-point group weight must be positive")
        for local_index in group
            reduced[i, :, :, :] .+= (weights[local_index] / group_weight) .* array[local_index, :, :, :]
        end
    end
    return reduced
end

function weighted_group_reduce(array::AbstractMatrix{FT}, weights, groups) where FT
    length(array) == 0 && return array
    reduced = zeros(FT, length(groups), size(array, 2))
    for (i, group) in enumerate(groups)
        group_weight = sum(weights[group])
        group_weight > 0 || error("g-point group weight must be positive")
        for local_index in group
            reduced[i, :] .+= (weights[local_index] / group_weight) .* array[local_index, :]
        end
    end
    return reduced
end

function weighted_group_reduce(vector::AbstractVector{FT}, weights, groups) where FT
    length(vector) == 0 && return vector
    reduced = zeros(FT, length(groups))
    for (i, group) in enumerate(groups)
        group_weight = sum(weights[group])
        group_weight > 0 || error("g-point group weight must be positive")
        for local_index in group
            reduced[i] += (weights[local_index] / group_weight) * vector[local_index]
        end
    end
    return reduced
end

function cumulative_weight_groups(weights, nreduced)
    nreduced <= length(weights) ||
        throw(ArgumentError("cannot reduce $(length(weights)) g-points to $nreduced"))
    total = sum(weights)
    total > 0 || error("spectral weights must have positive sum")
    targets = total .* collect(1:(nreduced - 1)) ./ nreduced
    groups = Vector{Vector{Int}}()
    current = Int[]
    cumulative = zero(eltype(weights))
    target_index = 1
    for ig in eachindex(weights)
        push!(current, ig)
        cumulative += weights[ig]
        remaining_points = length(weights) - ig
        remaining_groups = nreduced - length(groups) - 1
        should_split = target_index <= length(targets) &&
            cumulative >= targets[target_index] &&
            remaining_points >= remaining_groups
        if should_split
            push!(groups, current)
            current = Int[]
            target_index += 1
        end
    end
    isempty(current) || push!(groups, current)
    while length(groups) > nreduced
        append!(groups[end - 1], groups[end])
        pop!(groups)
    end
    while length(groups) < nreduced
        lengths = length.(groups)
        split_index = argmax(lengths)
        lengths[split_index] > 1 ||
            error("failed to split cumulative-weight groups to $nreduced bins")
        group = groups[split_index]
        midpoint = length(group) ÷ 2
        groups[split_index] = group[1:midpoint]
        insert!(groups, split_index + 1, group[(midpoint + 1):end])
    end
    length(groups) == nreduced || error("failed to build $nreduced cumulative-weight groups")
    all(!isempty, groups) || error("empty cumulative-weight group generated")
    return groups
end

function indexed_tabulated_model(model, lw_indices, sw_indices)
    source_table = model.longwave_source_table === nothing ||
        length(model.longwave_source_table) == 0 ?
        model.longwave_source_table :
        model.longwave_source_table[lw_indices, :]

    reduced = EcCKDTabulatedGasOpticsModel(
        gas_names = NumericalRadiation.gas_names(model),
        pressure_grid = model.pressure_grid,
        temperature_grid = model.temperature_grid,
        h2o_mole_fraction_grid = model.h2o_mole_fraction_grid,
        gas_reference_mole_fractions = model.gas_reference_mole_fractions,
        longwave_absorption = model.longwave_absorption[lw_indices, :, :, :],
        shortwave_absorption = model.shortwave_absorption[sw_indices, :, :, :],
        longwave_h2o_absorption = subset_or_empty(model.longwave_h2o_absorption, lw_indices),
        shortwave_h2o_absorption = subset_or_empty(model.shortwave_h2o_absorption, sw_indices),
        shortwave_rayleigh_molar_scattering = model.shortwave_rayleigh_molar_scattering[sw_indices],
        longwave_source_scale = model.longwave_source_scale[lw_indices],
        longwave_source_temperature_grid = model.longwave_source_temperature_grid,
        longwave_source_table = source_table,
        longwave_weights = normalized_subset(model.longwave_weights, lw_indices),
        shortwave_weights = normalized_subset(model.shortwave_weights, sw_indices),
    )
    return register_reduced_model(reduced;
        lw_indices = collect(lw_indices),
        sw_indices = collect(sw_indices),
        full_lw_weights = model.longwave_weights,
        full_sw_weights = model.shortwave_weights,
    )
end

function selected_tabulated_model(model, ng_lw, ng_sw)
    lw_indices = selected_gpoints(size(model.longwave_absorption, 1), ng_lw)
    sw_indices = selected_gpoints(size(model.shortwave_absorption, 1), ng_sw)
    return indexed_tabulated_model(model, lw_indices, sw_indices)
end

function weighted_tabulated_model(model, ng_lw, ng_sw)
    lw_groups = gpoint_groups(size(model.longwave_absorption, 1), ng_lw)
    sw_groups = gpoint_groups(size(model.shortwave_absorption, 1), ng_sw)

    reduced = EcCKDTabulatedGasOpticsModel(
        gas_names = NumericalRadiation.gas_names(model),
        pressure_grid = model.pressure_grid,
        temperature_grid = model.temperature_grid,
        h2o_mole_fraction_grid = model.h2o_mole_fraction_grid,
        gas_reference_mole_fractions = model.gas_reference_mole_fractions,
        longwave_absorption = weighted_group_reduce(model.longwave_absorption,
                                                    model.longwave_weights,
                                                    lw_groups),
        shortwave_absorption = weighted_group_reduce(model.shortwave_absorption,
                                                     model.shortwave_weights,
                                                     sw_groups),
        longwave_h2o_absorption = weighted_group_reduce(model.longwave_h2o_absorption,
                                                        model.longwave_weights,
                                                        lw_groups),
        shortwave_h2o_absorption = weighted_group_reduce(model.shortwave_h2o_absorption,
                                                         model.shortwave_weights,
                                                         sw_groups),
        shortwave_rayleigh_molar_scattering =
            weighted_group_reduce(model.shortwave_rayleigh_molar_scattering,
                                  model.shortwave_weights,
                                  sw_groups),
        longwave_source_scale = weighted_group_reduce(model.longwave_source_scale,
                                                      model.longwave_weights,
                                                      lw_groups),
        longwave_source_temperature_grid = model.longwave_source_temperature_grid,
        longwave_source_table = weighted_group_reduce(model.longwave_source_table,
                                                      model.longwave_weights,
                                                      lw_groups),
        longwave_weights = normalized_group_weights(model.longwave_weights, lw_groups),
        shortwave_weights = normalized_group_weights(model.shortwave_weights, sw_groups),
    )
    return register_reduced_model(reduced;
        lw_groups = lw_groups,
        sw_groups = sw_groups,
        full_lw_weights = model.longwave_weights,
        full_sw_weights = model.shortwave_weights,
    )
end

function cumulative_weight_tabulated_model(model, ng_lw, ng_sw)
    lw_groups = cumulative_weight_groups(model.longwave_weights, ng_lw)
    sw_groups = cumulative_weight_groups(model.shortwave_weights, ng_sw)

    reduced = EcCKDTabulatedGasOpticsModel(
        gas_names = NumericalRadiation.gas_names(model),
        pressure_grid = model.pressure_grid,
        temperature_grid = model.temperature_grid,
        h2o_mole_fraction_grid = model.h2o_mole_fraction_grid,
        gas_reference_mole_fractions = model.gas_reference_mole_fractions,
        longwave_absorption = weighted_group_reduce(model.longwave_absorption,
                                                    model.longwave_weights,
                                                    lw_groups),
        shortwave_absorption = weighted_group_reduce(model.shortwave_absorption,
                                                     model.shortwave_weights,
                                                     sw_groups),
        longwave_h2o_absorption = weighted_group_reduce(model.longwave_h2o_absorption,
                                                        model.longwave_weights,
                                                        lw_groups),
        shortwave_h2o_absorption = weighted_group_reduce(model.shortwave_h2o_absorption,
                                                         model.shortwave_weights,
                                                         sw_groups),
        shortwave_rayleigh_molar_scattering =
            weighted_group_reduce(model.shortwave_rayleigh_molar_scattering,
                                  model.shortwave_weights,
                                  sw_groups),
        longwave_source_scale = weighted_group_reduce(model.longwave_source_scale,
                                                      model.longwave_weights,
                                                      lw_groups),
        longwave_source_temperature_grid = model.longwave_source_temperature_grid,
        longwave_source_table = weighted_group_reduce(model.longwave_source_table,
                                                      model.longwave_weights,
                                                      lw_groups),
        longwave_weights = normalized_group_weights(model.longwave_weights, lw_groups),
        shortwave_weights = normalized_group_weights(model.shortwave_weights, sw_groups),
    )
    return register_reduced_model(reduced;
        lw_groups = lw_groups,
        sw_groups = sw_groups,
        full_lw_weights = model.longwave_weights,
        full_sw_weights = model.shortwave_weights,
    )
end

function shortwave_similarity_feature(model, ig)
    feature = Float64[]
    append!(feature, log1p.(vec(model.shortwave_absorption[ig, :, :, :])))
    if length(model.shortwave_h2o_absorption) != 0
        append!(feature, log1p.(vec(model.shortwave_h2o_absorption[ig, :, :, :])))
    end
    push!(feature, log1p(model.shortwave_rayleigh_molar_scattering[ig]))
    return feature
end

function shortwave_similarity_groups(model, ng_sw)
    nfull = size(model.shortwave_absorption, 1)
    ng_sw * 2 == nfull ||
        throw(ArgumentError("similarity_pair_bins currently requires halving the shortwave g-point count"))
    features = [shortwave_similarity_feature(model, ig) for ig in 1:nfull]
    remaining = collect(1:nfull)
    groups = Vector{Vector{Int}}()
    while !isempty(remaining)
        i = remaining[argmax(model.shortwave_weights[remaining])]
        deleteat!(remaining, findfirst(==(i), remaining))
        if isempty(remaining)
            push!(groups, [i])
            break
        end
        _, nearest_position = findmin(j -> norm(features[i] .- features[j]), remaining)
        j = remaining[nearest_position]
        deleteat!(remaining, nearest_position)
        push!(groups, sort([i, j]))
    end
    return groups
end

function similarity_pair_tabulated_model(model, ng_sw)
    sw_groups = shortwave_similarity_groups(model, ng_sw)
    reduced = EcCKDTabulatedGasOpticsModel(
        gas_names = NumericalRadiation.gas_names(model),
        pressure_grid = model.pressure_grid,
        temperature_grid = model.temperature_grid,
        h2o_mole_fraction_grid = model.h2o_mole_fraction_grid,
        gas_reference_mole_fractions = model.gas_reference_mole_fractions,
        longwave_absorption = model.longwave_absorption,
        shortwave_absorption = weighted_group_reduce(model.shortwave_absorption,
                                                     model.shortwave_weights,
                                                     sw_groups),
        longwave_h2o_absorption = model.longwave_h2o_absorption,
        shortwave_h2o_absorption = weighted_group_reduce(model.shortwave_h2o_absorption,
                                                         model.shortwave_weights,
                                                         sw_groups),
        shortwave_rayleigh_molar_scattering =
            weighted_group_reduce(model.shortwave_rayleigh_molar_scattering,
                                  model.shortwave_weights,
                                  sw_groups),
        longwave_source_scale = model.longwave_source_scale,
        longwave_source_temperature_grid = model.longwave_source_temperature_grid,
        longwave_source_table = model.longwave_source_table,
        longwave_weights = model.longwave_weights,
        shortwave_weights = normalized_group_weights(model.shortwave_weights, sw_groups),
    )
    return register_reduced_model(reduced;
        sw_groups = sw_groups,
        full_sw_weights = model.shortwave_weights,
    )
end

function anchored_similarity_groups(model, anchor_indices)
    nfull = size(model.shortwave_absorption, 1)
    anchors = collect(anchor_indices)
    length(unique(anchors)) == length(anchors) ||
        throw(ArgumentError("anchor g-point indices must be unique"))
    all(1 <= ig <= nfull for ig in anchors) ||
        throw(ArgumentError("anchor g-point index outside official shortwave range"))

    features = [shortwave_similarity_feature(model, ig) for ig in 1:nfull]
    groups = [[anchor] for anchor in anchors]
    for ig in 1:nfull
        ig in anchors && continue
        _, anchor_position = findmin(anchor -> norm(features[ig] .- features[anchor]),
                                     anchors)
        push!(groups[anchor_position], ig)
    end
    return sort!.(groups)
end

function anchored_similarity_tabulated_model(model, anchor_indices)
    sw_groups = anchored_similarity_groups(model, anchor_indices)
    reduced = EcCKDTabulatedGasOpticsModel(
        gas_names = NumericalRadiation.gas_names(model),
        pressure_grid = model.pressure_grid,
        temperature_grid = model.temperature_grid,
        h2o_mole_fraction_grid = model.h2o_mole_fraction_grid,
        gas_reference_mole_fractions = model.gas_reference_mole_fractions,
        longwave_absorption = model.longwave_absorption,
        shortwave_absorption = weighted_group_reduce(model.shortwave_absorption,
                                                     model.shortwave_weights,
                                                     sw_groups),
        longwave_h2o_absorption = model.longwave_h2o_absorption,
        shortwave_h2o_absorption = weighted_group_reduce(model.shortwave_h2o_absorption,
                                                         model.shortwave_weights,
                                                         sw_groups),
        shortwave_rayleigh_molar_scattering =
            weighted_group_reduce(model.shortwave_rayleigh_molar_scattering,
                                  model.shortwave_weights,
                                  sw_groups),
        longwave_source_scale = model.longwave_source_scale,
        longwave_source_temperature_grid = model.longwave_source_temperature_grid,
        longwave_source_table = model.longwave_source_table,
        longwave_weights = model.longwave_weights,
        shortwave_weights = normalized_group_weights(model.shortwave_weights, sw_groups),
    )
    return register_reduced_model(reduced;
        sw_groups = sw_groups,
        full_sw_weights = model.shortwave_weights,
    )
end

function anchored_voronoi_groups(model, anchor_indices)
    nfull = size(model.shortwave_absorption, 1)
    anchors = collect(anchor_indices)
    length(unique(anchors)) == length(anchors) ||
        throw(ArgumentError("anchor g-point indices must be unique"))
    all(1 <= ig <= nfull for ig in anchors) ||
        throw(ArgumentError("anchor g-point index outside official shortwave range"))

    groups = [[anchor] for anchor in anchors]
    for ig in 1:nfull
        ig in anchors && continue
        _, anchor_position = findmin(anchor -> abs(ig - anchor), anchors)
        push!(groups[anchor_position], ig)
    end
    return sort!.(groups)
end

function anchored_voronoi_tabulated_model(model, anchor_indices)
    sw_groups = anchored_voronoi_groups(model, anchor_indices)
    reduced = EcCKDTabulatedGasOpticsModel(
        gas_names = NumericalRadiation.gas_names(model),
        pressure_grid = model.pressure_grid,
        temperature_grid = model.temperature_grid,
        h2o_mole_fraction_grid = model.h2o_mole_fraction_grid,
        gas_reference_mole_fractions = model.gas_reference_mole_fractions,
        longwave_absorption = model.longwave_absorption,
        shortwave_absorption = weighted_group_reduce(model.shortwave_absorption,
                                                     model.shortwave_weights,
                                                     sw_groups),
        longwave_h2o_absorption = model.longwave_h2o_absorption,
        shortwave_h2o_absorption = weighted_group_reduce(model.shortwave_h2o_absorption,
                                                         model.shortwave_weights,
                                                         sw_groups),
        shortwave_rayleigh_molar_scattering =
            weighted_group_reduce(model.shortwave_rayleigh_molar_scattering,
                                  model.shortwave_weights,
                                  sw_groups),
        longwave_source_scale = model.longwave_source_scale,
        longwave_source_temperature_grid = model.longwave_source_temperature_grid,
        longwave_source_table = model.longwave_source_table,
        longwave_weights = model.longwave_weights,
        shortwave_weights = normalized_group_weights(model.shortwave_weights, sw_groups),
    )
    return register_reduced_model(reduced;
        sw_groups = sw_groups,
        full_sw_weights = model.shortwave_weights,
    )
end

function reduced_tabulated_model(model, spec)
    if spec.method == "full_official"
        return model
    elseif spec.method == "leave_one_out_weight_coordinate_boundary_polish"
        return leave_one_out_boundary_polish_model(model)
    elseif spec.method == "even_select"
        return selected_tabulated_model(model, spec.ng_lw, spec.ng_sw)
    elseif spec.method == "greedy_subset"
        return indexed_tabulated_model(model,
                                       collect(1:size(model.longwave_absorption, 1)),
                                       GREEDY_SW_16_INDICES)
    elseif spec.method == "greedy_subset_fit_sw_weights"
        reduced = indexed_tabulated_model(model,
                                          collect(1:size(model.longwave_absorption, 1)),
                                          GREEDY_SW_16_INDICES)
        reduced.shortwave_weights .= optimized_shortwave_weights(reduced)
        return reduced
    elseif spec.method == "greedy_subset_boundary_fit_sw_weights"
        reduced = indexed_tabulated_model(model,
                                          collect(1:size(model.longwave_absorption, 1)),
                                          GREEDY_SW_16_INDICES)
        reduced.shortwave_weights .= optimized_shortwave_weights_projected(
            reduced;
            boundary_weight = 10.0,
            max_iterations = 2_000,
        )
        return reduced
    elseif spec.method == "weighted_greedy_subset_projected"
        reduced = indexed_tabulated_model(model,
                                          collect(1:size(model.longwave_absorption, 1)),
                                          WEIGHTED_GREEDY_SW_16_INDICES)
        reduced.shortwave_weights .= WEIGHTED_GREEDY_SW_16_WEIGHTS
        return reduced
    elseif spec.method == "weighted_greedy_subset_maxnorm"
        reduced = indexed_tabulated_model(model,
                                          collect(1:size(model.longwave_absorption, 1)),
                                          WEIGHTED_GREEDY_SW_16_INDICES)
        reduced.shortwave_weights .= optimized_shortwave_weights_maxnorm(
            reduced;
            initial_weights = WEIGHTED_GREEDY_SW_16_WEIGHTS,
            max_iterations = 2_000,
        )
        return reduced
    elseif spec.method == "weighted_greedy_subset_scaled_coefficients"
        reduced = indexed_tabulated_model(model,
                                          collect(1:size(model.longwave_absorption, 1)),
                                          WEIGHTED_GREEDY_SW_16_INDICES)
        reduced.shortwave_weights .= WEIGHTED_GREEDY_SW_16_WEIGHTS
        return scale_shortwave_coefficients!(
            reduced,
            WEIGHTED_GREEDY_SW_16_COEFFICIENT_SCALES,
        )
    elseif spec.method == "weighted_greedy_subset_preflight_optimized"
        reduced = indexed_tabulated_model(model,
                                          collect(1:size(model.longwave_absorption, 1)),
                                          WEIGHTED_GREEDY_SW_16_INDICES)
        parameters = latest_preflight_reduced_parameters()
        if parameters === nothing
            reduced.shortwave_weights .= WEIGHTED_GREEDY_SW_16_WEIGHTS
            return scale_shortwave_coefficients!(
                reduced,
                WEIGHTED_GREEDY_SW_16_COEFFICIENT_SCALES,
            )
        end
        return apply_weight_absorption_rayleigh_parameters!(reduced, parameters)
    elseif spec.method == "weighted_greedy_subset_preflight_table_refined"
        reduced = indexed_tabulated_model(model,
                                          collect(1:size(model.longwave_absorption, 1)),
                                          WEIGHTED_GREEDY_SW_16_INDICES)
        parameters = latest_preflight_reduced_parameters()
        if parameters === nothing
            reduced.shortwave_weights .= WEIGHTED_GREEDY_SW_16_WEIGHTS
            scale_shortwave_coefficients!(
                reduced,
                WEIGHTED_GREEDY_SW_16_COEFFICIENT_SCALES,
            )
        else
            apply_weight_absorption_rayleigh_parameters!(reduced, parameters)
        end
        apply_pressure_band_table_moves!(
            reduced,
            latest_preflight_pressure_band_table_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            best_available_active_table_entry_moves(),
        )
        apply_best_exact_weight_refit!(reduced)
        apply_gas_pressure_band_refinement_moves!(
            reduced,
            latest_gas_pressure_band_refinement_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_constrained_table_optimizer_moves(),
        )
        apply_post_constrained_weight_refit!(reduced)
        apply_slot_blend_refinement_moves!(
            reduced,
            model,
            latest_slot_blend_refinement_moves(),
        )
        apply_post_slot_weight_refit!(reduced)
        return reduced
    elseif spec.method == "weighted_greedy_subset_preflight_table_refined_incoming_weighted"
        reduced = reduced_tabulated_model(model, (
            ng_lw = spec.ng_lw,
            ng_sw = spec.ng_sw,
            method = "weighted_greedy_subset_preflight_table_refined",
        ))
        return use_reduced_incoming_weights!(reduced)
    elseif spec.method == "weighted_greedy_subset_boundary_weight_refit"
        reduced = reduced_tabulated_model(model, (
            ng_lw = spec.ng_lw,
            ng_sw = spec.ng_sw,
            method = "weighted_greedy_subset_preflight_table_refined",
        ))
        return apply_post_constrained_boundary_weight_refit!(reduced)
    elseif spec.method == "weighted_greedy_subset_boundary_table_continuation"
        reduced = reduced_tabulated_model(model, (
            ng_lw = spec.ng_lw,
            ng_sw = spec.ng_sw,
            method = "weighted_greedy_subset_boundary_weight_refit",
        ))
        apply_active_table_entry_moves!(
            reduced,
            latest_boundary_base_constrained_table_optimizer_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_boundary_table_coordinate_scan_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_boundary_table_pair_coordinate_scan_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_boundary_table_coordinate_descent_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_boundary_table_continuation_optimizer_moves(),
        )
        apply_component_scale_refit_moves!(
            reduced,
            latest_component_scale_refit_moves(),
        )
        apply_pressure_component_scale_refit_moves!(
            reduced,
            latest_pressure_component_scale_refit_moves(),
        )
        apply_temperature_component_scale_refit_moves!(
            reduced,
            latest_temperature_component_scale_refit_moves(),
        )
        apply_h2o_component_scale_refit_moves!(
            reduced,
            latest_h2o_component_scale_refit_moves(),
        )
        apply_gas_component_scale_refit_moves!(
            reduced,
            latest_gas_component_scale_refit_moves(),
        )
        apply_pressure_temperature_component_scale_refit_moves!(
            reduced,
            latest_pressure_temperature_component_scale_refit_moves(),
        )
        apply_gas_pressure_temperature_component_scale_refit_moves!(
            reduced,
            latest_gas_pressure_temperature_component_scale_refit_moves(),
        )
        apply_h2o_pressure_temperature_component_scale_refit_moves!(
            reduced,
            latest_h2o_pressure_temperature_component_scale_refit_moves(),
        )
        apply_mixed_pressure_temperature_component_refit_moves!(
            reduced,
            latest_mixed_pressure_temperature_component_refit_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_structural_optimizer_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_structural_continuation_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_structural_continuation2_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_structural_continuation3_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_structural_continuation4_moves(),
        )
        apply_mixed_pressure_temperature_component_refit_moves!(
            reduced,
            latest_retained_mixed_component_pareto_scan_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_capped_table_optimizer_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_capped_table_continuation_moves(),
        )
        post_capped_weight_refit = latest_retained_post_capped_weight_refit_weights()
        post_capped_weight_refit === nothing ||
            (reduced.shortwave_weights .= post_capped_weight_refit.weights)
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_post_weight_surface_table_refit_moves(),
        )
        post_weight_bounded_weight_refit =
            latest_retained_post_weight_bounded_weight_refit_weights()
        post_weight_bounded_weight_refit === nothing ||
            (reduced.shortwave_weights .= post_weight_bounded_weight_refit.weights)
        apply_component_scale_refit_moves!(
            reduced,
            latest_retained_current_component_scale_optimizer_moves(),
        )
        apply_component_scale_refit_moves!(
            reduced,
            latest_retained_current_component_scale_optimizer2_moves(),
        )
        apply_component_scale_refit_moves!(
            reduced,
            latest_retained_current_component_scale_optimizer3_moves(),
        )
        apply_component_scale_refit_moves!(
            reduced,
            latest_retained_current_component_scale_optimizer4_moves(),
        )
        current_pressure_scan_moves =
            latest_retained_current_gas_pressure_component_scan_moves()
        if isempty(current_pressure_scan_moves)
            current_pressure_scan_moves =
                latest_retained_current_pressure_component_scan_moves()
        end
        if isempty(current_pressure_scan_moves)
            current_pressure_scan_moves =
                latest_retained_current_pressure_component_optimizer_moves()
        end
        apply_pressure_component_scale_refit_moves!(reduced, current_pressure_scan_moves)
        apply_pressure_component_scale_refit_moves!(
            reduced,
            latest_retained_current_gas_pressure_component_continuation_scan_moves(),
        )
        apply_pressure_component_scale_refit_moves!(
            reduced,
            latest_retained_current_gas_pressure_component_continuation2_scan_moves(),
        )
        apply_pressure_component_scale_refit_moves!(
            reduced,
            latest_retained_current_gas_pressure_component_continuation3_scan_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_objective_probe_expansion_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_objective_probe_expansion2_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_objective_probe_expansion3_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_objective_probe_expansion4_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_surface_probe_expansion_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_surface_probe_expansion2_moves(),
        )
        apply_active_table_entry_moves!(
            reduced,
            latest_retained_surface_probe_expansion3_moves(),
        )
        return reduced
    elseif spec.method == "even_select_fit_sw_weights"
        reduced = selected_tabulated_model(model, spec.ng_lw, spec.ng_sw)
        reduced.shortwave_weights .= optimized_shortwave_weights(reduced)
        return reduced
    elseif spec.method == "weighted_bins"
        return weighted_tabulated_model(model, spec.ng_lw, spec.ng_sw)
    elseif spec.method == "cumulative_weight_bins"
        return cumulative_weight_tabulated_model(model, spec.ng_lw, spec.ng_sw)
    elseif spec.method == "similarity_pair_bins"
        return similarity_pair_tabulated_model(model, spec.ng_sw)
    elseif spec.method == "anchored_similarity_bins"
        return anchored_similarity_tabulated_model(model, WEIGHTED_GREEDY_SW_16_INDICES)
    elseif spec.method == "anchored_voronoi_bins"
        return anchored_voronoi_tabulated_model(model, WEIGHTED_GREEDY_SW_16_INDICES)
    end
    error("unknown reduced model method $(spec.method)")
end

function with_shortwave_weights(model, weights)
    weighted = EcCKDTabulatedGasOpticsModel(
        gas_names = NumericalRadiation.gas_names(model),
        pressure_grid = model.pressure_grid,
        temperature_grid = model.temperature_grid,
        h2o_mole_fraction_grid = model.h2o_mole_fraction_grid,
        gas_reference_mole_fractions = model.gas_reference_mole_fractions,
        longwave_absorption = model.longwave_absorption,
        shortwave_absorption = model.shortwave_absorption,
        longwave_h2o_absorption = model.longwave_h2o_absorption,
        shortwave_h2o_absorption = model.shortwave_h2o_absorption,
        shortwave_rayleigh_molar_scattering = model.shortwave_rayleigh_molar_scattering,
        longwave_source_scale = model.longwave_source_scale,
        longwave_source_temperature_grid = model.longwave_source_temperature_grid,
        longwave_source_table = model.longwave_source_table,
        longwave_weights = model.longwave_weights,
        shortwave_weights = weights,
    )
    return copy_reduced_metadata!(weighted, model)
end

function scale_shortwave_coefficients!(model, scales)
    length(scales) == size(model.shortwave_absorption, 1) ||
        throw(DimensionMismatch("shortwave coefficient scales must match ng_sw"))
    for ig in eachindex(scales)
        model.shortwave_absorption[ig, :, :, :] .*= scales[ig]
        if length(model.shortwave_h2o_absorption) != 0
            model.shortwave_h2o_absorption[ig, :, :, :] .*= scales[ig]
        end
        model.shortwave_rayleigh_molar_scattering[ig] *= scales[ig]
    end
    return model
end

function reduce_gpoint_matrix(values, weights; indices = nothing, groups = nothing)
    values === nothing && return nothing
    size(values, 1) == length(weights) || return values
    if indices !== nothing
        return values[indices, :]
    elseif groups !== nothing
        reduced = zeros(eltype(values), length(groups), size(values, 2))
        for (i, group) in enumerate(groups)
            group_weight = sum(weights[group])
            group_weight > 0 || error("g-point group weight must be positive")
            for local_index in group
                reduced[i, :] .+= (weights[local_index] / group_weight) .* values[local_index, :]
            end
        end
        return reduced
    end
    return values
end

function gpoint_fraction_projection(source_definition_path, target_definition_path)
    nc = require_ncdatasets()
    nc.NCDataset(source_definition_path) do source_dataset
        nc.NCDataset(target_definition_path) do target_dataset
            source_fraction = Array(source_dataset["gpoint_fraction"])
            target_fraction = Array(target_dataset["gpoint_fraction"])
            size(source_fraction, 1) == size(target_fraction, 1) ||
                throw(DimensionMismatch("source and target gpoint_fraction grids differ"))
            wavenumber1 = Array(target_dataset["wavenumber1"])
            wavenumber2 = Array(target_dataset["wavenumber2"])
            widths = abs.(wavenumber2 .- wavenumber1)
            overlap = target_fraction' * (source_fraction .* widths)
            projection = similar(overlap)
            for target_index in axes(overlap, 1)
                total = sum(overlap[target_index, :])
                projection[target_index, :] .=
                    total > 0 ? overlap[target_index, :] ./ total :
                    fill(inv(size(overlap, 2)), size(overlap, 2))
            end
            return projection
        end
    end
end

function project_gpoint_matrix(values, projection)
    values === nothing && return nothing
    size(values, 1) == size(projection, 2) || return values
    return projection * values
end

function reduced_shortwave_boundary_arrays(surface_albedo_spectral,
                                           surface_albedo_direct_spectral,
                                           toa_shortwave_down_spectral,
                                           gas_optics)
    metadata = get(REDUCED_MODEL_METADATA, gas_optics, nothing)
    metadata === nothing &&
        return surface_albedo_spectral, surface_albedo_direct_spectral,
            toa_shortwave_down_spectral
    full_sw_weights = metadata.full_sw_weights === nothing ?
        gas_optics.shortwave_weights : metadata.full_sw_weights
    if hasproperty(metadata, :sw_boundary_projection) &&
       metadata.sw_boundary_projection !== nothing
        projection = gpoint_fraction_projection(
            metadata.sw_boundary_projection.source_definition_path,
            metadata.sw_boundary_projection.target_definition_path,
        )
        return (
            project_gpoint_matrix(surface_albedo_spectral, projection),
            project_gpoint_matrix(surface_albedo_direct_spectral, projection),
            project_gpoint_matrix(toa_shortwave_down_spectral, projection),
        )
    end
    return (
        reduce_gpoint_matrix(surface_albedo_spectral, full_sw_weights;
            indices = metadata.sw_indices,
            groups = metadata.sw_groups),
        reduce_gpoint_matrix(surface_albedo_direct_spectral, full_sw_weights;
            indices = metadata.sw_indices,
            groups = metadata.sw_groups),
        reduce_gpoint_matrix(toa_shortwave_down_spectral, full_sw_weights;
            indices = metadata.sw_indices,
            groups = metadata.sw_groups),
    )
end

function projected_longwave_boundary_array(surface_longwave_up_spectral, gas_optics)
    surface_longwave_up_spectral === nothing && return nothing
    metadata = get(REDUCED_MODEL_METADATA, gas_optics, nothing)
    metadata === nothing && return surface_longwave_up_spectral
    if hasproperty(metadata, :lw_boundary_projection) &&
       metadata.lw_boundary_projection !== nothing
        projection = gpoint_fraction_projection(
            metadata.lw_boundary_projection.source_definition_path,
            metadata.lw_boundary_projection.target_definition_path,
        )
        return project_gpoint_matrix(surface_longwave_up_spectral, projection)
    end
    return surface_longwave_up_spectral
end

function sw_reference_vector(case)
    nc = require_ncdatasets()
    nc.NCDataset(reference_path(case.path)) do dataset
        return vcat(vec(Array(dataset["sw_up"])), vec(Array(dataset["sw_down"])))
    end
end

function sw_candidate_vector(case, model)
    arrays = candidate_arrays(case.path, model)
    return vcat(vec(arrays.sw_up), vec(arrays.sw_down))
end

function simplex_project(values)
    nonnegative = max.(values, 0)
    total = sum(nonnegative)
    if total <= 0
        return fill(inv(length(values)), length(values))
    end
    return nonnegative ./ total
end

function optimized_shortwave_weights(model)
    ng = size(model.shortwave_absorption, 1)
    basis_vectors = Vector{Vector{Float64}}(undef, ng)
    for ig in 1:ng
        weights = zeros(Float64, ng)
        weights[ig] = 1
        basis_model = with_shortwave_weights(model, weights)
        basis_vectors[ig] = vcat([sw_candidate_vector(case, basis_model) for case in REDUCED_CASES]...)
    end
    target = vcat([sw_reference_vector(case) for case in REDUCED_CASES]...)
    design = reduce(hcat, basis_vectors)
    augmented_design = vcat(design, fill(1.0e4, 1, ng))
    augmented_target = vcat(target, [1.0e4])
    weights = augmented_design \ augmented_target
    return simplex_project(weights)
end

function simplex_projection(values)
    u = sort(collect(values), rev = true)
    cssv = cumsum(u)
    rho = 0
    theta = 0.0
    for j in eachindex(u)
        candidate = u[j] + (1 - cssv[j]) / j
        if candidate > 0
            rho = j
            theta = (cssv[j] - 1) / j
        end
    end
    rho == 0 && return fill(inv(length(values)), length(values))
    return max.(values .- theta, 0)
end

function weighted_shortwave_design(model; boundary_weight)
    ng = size(model.shortwave_absorption, 1)
    basis_columns = Vector{Vector{Float64}}(undef, ng)
    target_blocks = Vector{Float64}[]
    for case in REDUCED_CASES
        reference = sw_reference_arrays_for_weights(case; boundary_weight = boundary_weight)
        push!(target_blocks, reference.vector)
    end
    target = vcat(target_blocks...)

    for ig in 1:ng
        weights = zeros(Float64, ng)
        weights[ig] = 1
        basis_model = with_shortwave_weights(model, weights)
        blocks = Vector{Float64}[]
        for case in REDUCED_CASES
            arrays = candidate_arrays(case.path, basis_model)
            push!(blocks, sw_metric_vector(arrays; boundary_weight = boundary_weight))
        end
        basis_columns[ig] = vcat(blocks...)
    end
    return reduce(hcat, basis_columns), target
end

function sw_metric_vector(arrays; boundary_weight)
    toa = arrays.sw_down[1, :] .- arrays.sw_up[1, :]
    surface = arrays.sw_down[end, :] .- arrays.sw_up[end, :]
    return vcat(vec(arrays.sw_up), vec(arrays.sw_down),
                boundary_weight .* vec(toa),
                boundary_weight .* vec(surface))
end

function sw_reference_arrays_for_weights(case; boundary_weight)
    nc = require_ncdatasets()
    nc.NCDataset(reference_path(case.path)) do dataset
        arrays = (
            sw_up = Array(dataset["sw_up"]),
            sw_down = Array(dataset["sw_down"]),
        )
        return (
            arrays...,
            vector = sw_metric_vector(arrays; boundary_weight = boundary_weight),
        )
    end
end

function optimized_shortwave_weights_projected(model;
                                               boundary_weight = 10.0,
                                               max_iterations = 1_000)
    design, target = weighted_shortwave_design(model; boundary_weight)
    ng = size(design, 2)
    weights = fill(inv(ng), ng)
    lipschitz = opnorm(design)^2
    step = lipschitz > 0 ? inv(lipschitz) : 1.0
    for _ in 1:max_iterations
        gradient = design' * (design * weights - target)
        weights = simplex_projection(weights - step * gradient)
    end
    return weights
end

function hard_gate_shortwave_design(model)
    ng = size(model.shortwave_absorption, 1)
    columns = Vector{Vector{Float64}}(undef, ng)
    targets = Vector{Float64}[]
    for case in REDUCED_CASES
        reference = sw_reference_arrays_for_weights(case;
            boundary_weight = inv(ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2))
        push!(targets, hard_gate_sw_metric_vector(reference))
    end
    target = vcat(targets...)

    for ig in 1:ng
        weights = zeros(Float64, ng)
        weights[ig] = 1
        basis_model = with_shortwave_weights(model, weights)
        blocks = Vector{Float64}[]
        for case in REDUCED_CASES
            arrays = candidate_arrays(case.path, basis_model)
            push!(blocks, hard_gate_sw_metric_vector(arrays))
        end
        columns[ig] = vcat(blocks...)
    end
    return reduce(hcat, columns), target
end

function hard_gate_sw_metric_vector(arrays)
    toa = arrays.sw_down[1, :] .- arrays.sw_up[1, :]
    surface = arrays.sw_down[end, :] .- arrays.sw_up[end, :]
    return vcat(
        vec(arrays.sw_up) ./ ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        vec(arrays.sw_down) ./ ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
        vec(toa) ./ ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
        vec(surface) ./ ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
    )
end

function optimized_shortwave_weights_maxnorm(model;
                                             initial_weights = nothing,
                                             max_iterations = 1_000,
                                             p = 16)
    design, target = hard_gate_shortwave_design(model)
    ng = size(design, 2)
    weights = initial_weights === nothing ? fill(inv(ng), ng) :
        simplex_projection(collect(initial_weights))
    lipschitz = opnorm(design)^2
    step0 = lipschitz > 0 ? inv(lipschitz) : 1.0
    best_weights = copy(weights)
    best_objective = Inf
    for iter in 1:max_iterations
        residual = design * weights - target
        abs_residual = abs.(residual) .+ eps(Float64)
        objective = sum(abs_residual .^ p)^(1 / p)
        if objective < best_objective
            best_objective = objective
            best_weights .= weights
        end
        scale = objective > 0 ? objective^(p - 1) : one(objective)
        gradient_residual = sign.(residual) .* (abs_residual .^ (p - 1)) ./ scale
        gradient = design' * gradient_residual
        step = step0 / sqrt(iter)
        weights = simplex_projection(weights - step * gradient)
    end
    return best_weights
end

function flux_workspace(gas_optics, nlayers)
    longwave = LongwaveOpticalProperties(
        zeros(Float64, size(gas_optics.longwave_absorption, 1), nlayers),
        zeros(Float64, size(gas_optics.longwave_absorption, 1), nlayers),
        source_top = zeros(Float64, size(gas_optics.longwave_absorption, 1), nlayers),
        source_bottom = zeros(Float64, size(gas_optics.longwave_absorption, 1), nlayers),
    )
    shortwave = ShortwaveOpticalProperties(
        zeros(Float64, size(gas_optics.shortwave_absorption, 1), nlayers),
    )
    fluxes = RadiativeFluxes(
        longwave_up = zeros(Float64, nlayers + 1),
        longwave_down = zeros(Float64, nlayers + 1),
        shortwave_up = zeros(Float64, nlayers + 1),
        shortwave_down = zeros(Float64, nlayers + 1),
    )
    heating = zeros(Float64, nlayers)
    return longwave, shortwave, fluxes, heating
end

function candidate_arrays(path, gas_optics)
    nc = require_ncdatasets()
    nc.NCDataset(reference_path(path)) do dataset
        pressure_layers = Array(dataset["pressure_layer"])
        pressure_interfaces = Array(dataset["pressure_interface"])
        temperature_layers = Array(dataset["temperature_layer"])
        temperature_interfaces = Array(dataset["temperature_interface"])
        gas_amounts = gas_column_amounts(dataset, pressure_interfaces)
        surface_temperature = Array(dataset["surface_temperature"])
        surface_albedo = Array(dataset["surface_albedo"])
        variables = String.(collect(keys(dataset)))
        surface_albedo_spectral = "surface_albedo_spectral" in variables ?
            Array(dataset["surface_albedo_spectral"]) : nothing
        surface_albedo_direct_spectral =
            "surface_albedo_direct_gpoint" in variables ?
            Array(dataset["surface_albedo_direct_gpoint"]) :
            "surface_albedo_direct_spectral" in variables ?
            Array(dataset["surface_albedo_direct_spectral"]) : nothing
        surface_longwave_up_spectral = "surface_longwave_up_spectral" in variables ?
            Array(dataset["surface_longwave_up_spectral"]) : nothing
        surface_longwave_up_spectral =
            projected_longwave_boundary_array(surface_longwave_up_spectral, gas_optics)
        toa_shortwave_down_spectral = "toa_shortwave_down_spectral" in variables ?
            Array(dataset["toa_shortwave_down_spectral"]) : nothing
        surface_albedo_spectral, surface_albedo_direct_spectral,
            toa_shortwave_down_spectral =
            reduced_shortwave_boundary_arrays(surface_albedo_spectral,
                                              surface_albedo_direct_spectral,
                                              toa_shortwave_down_spectral,
                                              gas_optics)
        if surface_albedo_spectral !== nothing &&
           size(surface_albedo_spectral, 1) != size(gas_optics.shortwave_absorption, 1)
            surface_albedo_spectral = nothing
        end
        if surface_albedo_direct_spectral !== nothing &&
           size(surface_albedo_direct_spectral, 1) != size(gas_optics.shortwave_absorption, 1)
            surface_albedo_direct_spectral = nothing
        end
        if toa_shortwave_down_spectral !== nothing &&
           size(toa_shortwave_down_spectral, 1) != size(gas_optics.shortwave_absorption, 1)
            toa_shortwave_down_spectral = nothing
        end
        if surface_longwave_up_spectral !== nothing &&
           size(surface_longwave_up_spectral, 1) != size(gas_optics.longwave_absorption, 1)
            surface_longwave_up_spectral = nothing
        end
        reference_lw_up = Array(dataset["lw_up"])
        reference_sw_up = Array(dataset["sw_up"])
        reference_sw_down = Array(dataset["sw_down"])
        toa_shortwave_down = reference_sw_down[1, :]
        solar_irradiance = "solar_irradiance" in variables ?
            Array(dataset["solar_irradiance"]) :
            fill(DEFAULT_SOLAR_IRRADIANCE, length(toa_shortwave_down))
        cos_zenith = "cos_solar_zenith_angle" in variables ?
            Array(dataset["cos_solar_zenith_angle"]) :
            clamp.(toa_shortwave_down ./ solar_irradiance, 0.0, 1.0)

        nlayers, ncolumns = size(pressure_layers)
        lw_up = zeros(Float64, nlayers + 1, ncolumns)
        lw_down = zeros(Float64, nlayers + 1, ncolumns)
        sw_up = zeros(Float64, nlayers + 1, ncolumns)
        sw_down = zeros(Float64, nlayers + 1, ncolumns)
        heating = zeros(Float64, nlayers, ncolumns)
        longwave, shortwave, fluxes, column_heating = flux_workspace(gas_optics, nlayers)

        for j in 1:ncolumns
            atmosphere = ColumnAtmosphere(
                pressure_layers = pressure_layers[:, j],
                pressure_interfaces = pressure_interfaces[:, j],
                temperature_layers = temperature_layers[:, j],
                temperature_interfaces = temperature_interfaces[:, j],
                gases = Dict(name => values[:, j] for (name, values) in gas_amounts.amounts),
                surface = (;),
                geometry = (; cos_zenith = cos_zenith[j]),
            )
            optical_properties!(longwave, shortwave, gas_optics, atmosphere)
            if toa_shortwave_down_spectral !== nothing &&
               (uses_full_official_shortwave_weights(gas_optics) ||
                uses_reduced_incoming_shortwave_weights(gas_optics))
                column_toa = max.(toa_shortwave_down_spectral[:, j], 0.0)
                column_total = sum(column_toa)
                if column_total > 0
                    shortwave.weights .= column_toa ./ column_total
                end
            end
            radiative_fluxes!(
                fluxes,
                CloudlessLongwave(),
                longwave,
                atmosphere,
                LongwaveBoundaryConditions(
                    surface_longwave_up = surface_longwave_up_spectral === nothing ?
                        longwave_surface_boundary(gas_optics, surface_temperature[j],
                                                  reference_lw_up[end, j]) :
                        surface_longwave_up_spectral[:, j] ./ gas_optics.longwave_weights,
                ),
            )
            effective_surface_albedo = reference_sw_down[end, j] <= 0 ?
                surface_albedo[j] :
                clamp(reference_sw_up[end, j] / reference_sw_down[end, j], 0.0, 1.0)
            radiative_fluxes!(
                fluxes,
                CloudlessShortwave(rayleigh_backscatter_fraction =
                    env_float("RH_SW_RAYLEIGH_BACKSCATTER_FRACTION", 0.5)),
                shortwave,
                atmosphere,
                ShortwaveBoundaryConditions(
                    toa_shortwave_down = max(toa_shortwave_down[j], 0.0),
                    surface_albedo = surface_albedo_spectral === nothing ?
                        effective_surface_albedo :
                        surface_albedo_spectral[:, j],
                    surface_albedo_direct = surface_albedo_direct_spectral === nothing ?
                        surface_albedo_spectral === nothing ?
                            effective_surface_albedo :
                            surface_albedo_spectral[:, j] :
                        surface_albedo_direct_spectral[:, j],
                ),
            )
            heating_rates!(column_heating, fluxes, atmosphere;
                           gravity = GRAVITY, heat_capacity = 1004.0)
            lw_up[:, j] = fluxes.longwave_up
            lw_down[:, j] = fluxes.longwave_down
            sw_up[:, j] = fluxes.shortwave_up
            sw_down[:, j] = fluxes.shortwave_down
            heating[:, j] = 86400.0 .* column_heating
        end
        return (
            lw_up = lw_up,
            lw_down = lw_down,
            sw_up = sw_up,
            sw_down = sw_down,
            heating_rate = heating,
        )
    end
end

function metric_pair(candidate, reference)
    difference = candidate .- reference
    return (
        rmse = sqrt(sum(abs2, difference) / length(difference)),
        max_abs = maximum(abs, difference),
    )
end

function boundary_net(arrays, boundary)
    i = boundary == :toa ? 1 : size(arrays.lw_up, 1)
    return arrays.lw_down[i, :] .- arrays.lw_up[i, :] .+
           arrays.sw_down[i, :] .- arrays.sw_up[i, :]
end

function case_metrics(case, gas_optics)
    nc = require_ncdatasets()
    candidate = candidate_arrays(case.path, gas_optics)
    nc.NCDataset(reference_path(case.path)) do dataset
        reference = (
            lw_up = Array(dataset["lw_up"]),
            lw_down = Array(dataset["lw_down"]),
            sw_up = Array(dataset["sw_up"]),
            sw_down = Array(dataset["sw_down"]),
            heating_rate = Array(dataset["heating_rate"]),
        )
        variable_metrics = (
            lw_up = metric_pair(candidate.lw_up, reference.lw_up),
            lw_down = metric_pair(candidate.lw_down, reference.lw_down),
            sw_up = metric_pair(candidate.sw_up, reference.sw_up),
            sw_down = metric_pair(candidate.sw_down, reference.sw_down),
            heating_rate = metric_pair(candidate.heating_rate, reference.heating_rate),
        )
        toa = maximum(abs, boundary_net(candidate, :toa) .- boundary_net(reference, :toa))
        surface = maximum(abs, boundary_net(candidate, :surface) .-
                               boundary_net(reference, :surface))
        passed = variable_metrics.lw_up.rmse <= ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2 &&
                 variable_metrics.lw_down.rmse <= ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2 &&
                 variable_metrics.sw_up.rmse <= ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2 &&
                 variable_metrics.sw_down.rmse <= ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2 &&
                 variable_metrics.heating_rate.rmse <= ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day &&
                 variable_metrics.lw_up.max_abs <= ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2 &&
                 variable_metrics.lw_down.max_abs <= ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2 &&
                 variable_metrics.sw_up.max_abs <= ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2 &&
                 variable_metrics.sw_down.max_abs <= ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2 &&
                 variable_metrics.heating_rate.max_abs <= ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day &&
                 toa <= ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2 &&
                 surface <= ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2
        return (
            case = case.case,
            path = case.path,
            passed_hard_thresholds = passed,
            variables = variable_metrics,
            toa_forcing_max_abs = toa,
            surface_forcing_max_abs = surface,
        )
    end
end

function model_metrics(full_model, model_spec)
    model = reduced_tabulated_model(full_model, model_spec)
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    return (
        ng_lw = model_spec.ng_lw,
        ng_sw = model_spec.ng_sw,
        reduction_method = model_spec.method == "full_official" ?
            "official ecCKD 32x32 baseline without shortwave reduction" :
            model_spec.method == "leave_one_out_weight_coordinate_boundary_polish" ?
            "official ecCKD 32x31 leave-one-out g23 support with exact boundary-polished quadrature weights" :
            model_spec.method == "even_select" ?
            "evenly selected official ecCKD g-points with renormalized weights" :
            model_spec.method == "greedy_subset" ?
            "greedy searched 16 shortwave g-point subset with official weights renormalized" :
            model_spec.method == "greedy_subset_fit_sw_weights" ?
            "greedy searched 16 shortwave g-point subset with least-squares fitted shortwave weights" :
            model_spec.method == "greedy_subset_boundary_fit_sw_weights" ?
            "greedy searched 16 shortwave g-point subset with projected boundary-weighted fitted shortwave weights" :
            model_spec.method == "weighted_greedy_subset_projected" ?
            "weighted greedy 16 shortwave g-point subset with projected simplex weights" :
            model_spec.method == "weighted_greedy_subset_maxnorm" ?
            "weighted greedy 16 shortwave g-point subset with projected hard-gate max-norm weights" :
            model_spec.method == "weighted_greedy_subset_scaled_coefficients" ?
            "weighted greedy 16 shortwave g-point subset with diagnostic fitted coefficient scales" :
            model_spec.method == "weighted_greedy_subset_preflight_optimized" ?
            "weighted greedy 16 shortwave g-point subset with latest preflight-optimized weights and coefficient scales" :
            model_spec.method == "weighted_greedy_subset_preflight_table_refined" ?
            "weighted greedy 16 shortwave g-point subset with latest preflight-optimized weights, coefficient scales, and pressure-band table moves" :
            model_spec.method == "weighted_greedy_subset_preflight_table_refined_incoming_weighted" ?
            "weighted greedy 16 shortwave g-point subset with latest preflight table moves and reduced incoming shortwave spectral weights" :
            model_spec.method == "weighted_greedy_subset_boundary_weight_refit" ?
            "weighted greedy 16 shortwave g-point subset with boundary-aware post-constrained weight refit" :
            model_spec.method == "weighted_greedy_subset_boundary_table_continuation" ?
            "weighted greedy 16 shortwave g-point subset with boundary-aware table, component, structural, objective-probe, surface-probe, capped table, continuation, post-capped weight, post-weight surface-table, bounded weight, four current component-scale refits, selected current gas-pressure component scan refit, gas-pressure continuation refit, weighted gas-pressure continuation refit, and high-weight gas-pressure continuation refit" :
            model_spec.method == "even_select_fit_sw_weights" ?
            "evenly selected official ecCKD g-points with least-squares fitted shortwave weights" :
            model_spec.method == "similarity_pair_bins" ?
            "non-adjacent coefficient-similarity shortwave g-point pairs with spectral-weighted coefficient averages" :
            model_spec.method == "anchored_similarity_bins" ?
            "weighted-greedy anchor g-points plus nearest-neighbor coefficient-similarity bins" :
            model_spec.method == "anchored_voronoi_bins" ?
            "weighted-greedy anchor g-points plus nearest spectral-order Voronoi bins" :
            model_spec.method == "cumulative_weight_bins" ?
            "cumulative spectral-weight bins with coefficient averages" :
            "adjacent official ecCKD g-point bins with spectral-weighted coefficient averages",
        passed_hard_thresholds = all(case -> case.passed_hard_thresholds, cases),
        cases = cases,
    )
end

function markdown_report(result)
    lines = String[
        "# Reduced ecCKD Accuracy",
        "",
        "Status: **$(result.status)**",
        "",
        "Reference scope: clean ecCKD cloudless/no-aerosol tropical and RCEMIP-style cases.",
        "",
        "| ng_lw | ng_sw | Method | Passed | Worst TOA forcing error | Worst surface forcing error |",
        "|---:|---:|---|---:|---:|---:|",
    ]
    for model in result.models
        worst_toa = maximum(case.toa_forcing_max_abs for case in model.cases)
        worst_surface = maximum(case.surface_forcing_max_abs for case in model.cases)
        push!(lines, "| $(model.ng_lw) | $(model.ng_sw) | $(model.reduction_method) | $(model.passed_hard_thresholds) | $(@sprintf("%.12g", worst_toa)) W m^-2 | $(@sprintf("%.12g", worst_surface)) W m^-2 |")
    end
    append!(lines, [
        "",
        "This is real reduced-model evidence, not a placeholder. A `failed_threshold` status means the selected reduced g-point subset does not yet meet the hard clean ecCKD thresholds.",
    ])
    return join(lines, "\n") * "\n"
end

function reduced_accuracy_main()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    models = [model_metrics(full_model, spec) for spec in REDUCED_MODELS]
    status = all(model -> model.passed_hard_thresholds, models) ? "passed" : "failed_threshold"
    result = (
        case = "radiative_heating_reduced_accuracy",
        timestamp_utc = string(Dates.now()),
        status = status,
        reference_scope = collect(REDUCED_CASE_NAMES),
        acceptance_thresholds = ACCEPTANCE_THRESHOLDS,
        models = models,
    )
    results_dir = validation_results_dir()
    mkpath(results_dir)
    abr_json = joinpath(results_dir, "reduced_ecckd_accuracy.json")
    abr_md = joinpath(results_dir, "reduced_ecckd_accuracy.md")
    write(abr_json, json_object(result))
    write(abr_md, markdown_report(result))

    mkpath(REDUCED_BREEZE_DIR)
    breeze_json = joinpath(REDUCED_BREEZE_DIR, "radiative_heating_reduced_accuracy_latest.json")
    breeze_md = joinpath(REDUCED_BREEZE_DIR, "radiative_heating_reduced_accuracy_latest.md")
    write(breeze_json, json_object(result))
    write(breeze_md, markdown_report(result))

    print(markdown_report(result))
    println("Wrote $abr_json")
    println("Wrote $abr_md")
    println("Wrote $breeze_json")
    println("Wrote $breeze_md")
end

if abspath(PROGRAM_FILE) == @__FILE__
    reduced_accuracy_main()
end
