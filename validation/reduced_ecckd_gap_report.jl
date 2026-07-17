include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

const GAP_ROOT = normpath(joinpath(@__DIR__, ".."))
const REDUCED_ACCURACY_MD = validation_results_path("reduced_ecckd_accuracy.md")
const REDUCED_OPTIMIZATION_JSON = validation_results_path("reduced_ecckd_optimization_preflight.json")
const REDUCED_COEFFICIENT_CONTINUATION_JSON =
    validation_results_path("reduced_ecckd_coefficient_continuation.json")
const REDUCED_SUBSET_SEARCH_JSON = validation_results_path("reduced_ecckd_subset_search.json")
const REDUCED_OPTICAL_DEPTH_FIT_JSON =
    validation_results_path("reduced_ecckd_optical_depth_fit_preflight.json")
const REDUCED_SIZE_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_size_weight_refit.json")
const REDUCED_LEAVE_ONE_OUT_SCAN_JSON =
    validation_results_path("reduced_ecckd_leave_one_out_scan.json")
const REDUCED_LEAVE_ONE_OUT_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_leave_one_out_weight_refit.json")
const REDUCED_IMPORTANCE_GROUP_SCAN_JSON =
    validation_results_path("reduced_ecckd_importance_group_scan.json")
const REDUCED_SUPPORT_SWAP_SCAN_JSON =
    validation_results_path("reduced_ecckd_support_swap_scan.json")
const REDUCED_SUPPORT_SWAP_CONTINUATION_SCAN_JSON =
    validation_results_path("reduced_ecckd_support_swap_continuation_scan.json")
const REDUCED_SUPPORT_EXPANSION_SCAN_JSON =
    validation_results_path("reduced_ecckd_support_expansion_scan.json")
const REDUCED_SUPPORT_EXPANSION_REFIT_SCAN_JSON =
    validation_results_path("reduced_ecckd_support_expansion_refit_scan.json")
const REDUCED_RANDOM_SUPPORT_SEARCH_JSON =
    validation_results_path("reduced_ecckd_random_support_search.json")
const REDUCED_CURRENT_METRIC_BREAKDOWN_JSON =
    validation_results_path("reduced_ecckd_current_metric_breakdown.json")
const REDUCED_PRESSURE_BAND_JSON =
    validation_results_path("reduced_ecckd_pressure_band_refinement_preflight.json")
const REDUCED_TARGETED_ENTRY_JSON =
    validation_results_path("reduced_ecckd_targeted_entry_refinement.json")
const REDUCED_GLOBAL_ENTRY_JSON =
    validation_results_path("reduced_ecckd_global_entry_refinement.json")
const REDUCED_GLOBAL_BLOCK_ENTRY_JSON =
    validation_results_path("reduced_ecckd_global_block_refinement.json")
const REDUCED_GLOBAL_BLOCK_LINEARIZED_ENTRY_JSON =
    validation_results_path("reduced_ecckd_global_block_linearized_refit.json")
const REDUCED_LINEARIZED_ENTRY_JSON =
    validation_results_path("reduced_ecckd_targeted_entry_linearized_refit.json")
const REDUCED_GLOBAL_LINEARIZED_ENTRY_JSON =
    validation_results_path("reduced_ecckd_global_entry_linearized_refit.json")
const REDUCED_TOPOLOGY_SLOT_JSON =
    validation_results_path("reduced_ecckd_topology_slot_refit.json")
const REDUCED_POST_TABLE_WEIGHT_JSON =
    validation_results_path("reduced_ecckd_post_table_weight_refit.json")
const REDUCED_EXACT_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_exact_weight_refit.json")
const REDUCED_JOINT_WEIGHT_BLOCK_REFIT_JSON =
    validation_results_path("reduced_ecckd_joint_weight_block_refit.json")
const REDUCED_BOUNDARY_COLUMN_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_boundary_column_refinement.json")
const REDUCED_SLOT_BLEND_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_slot_blend_refinement.json")
const REDUCED_PAIR_SLOT_BLEND_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_pair_slot_blend_refinement.json")
const REDUCED_SLOT_BLEND_LINEARIZED_REFIT_JSON =
    validation_results_path("reduced_ecckd_slot_blend_linearized_refit.json")
const REDUCED_POST_SLOT_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_post_slot_weight_refit.json")
const REDUCED_BOUNDARY_COLUMN_BLOCK_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_boundary_column_block_refinement.json")
const REDUCED_GAS_PRESSURE_BAND_REFINEMENT_JSON =
    validation_results_path("reduced_ecckd_gas_pressure_band_refinement.json")
const REDUCED_GAS_PRESSURE_BAND_LINEARIZED_JSON =
    validation_results_path("reduced_ecckd_gas_pressure_band_linearized_refit.json")
const REDUCED_FLUX_PAIR_BINS_JSON =
    validation_results_path("reduced_ecckd_flux_pair_bins.json")
const REDUCED_GROUPED_QUADRATURE_SEARCH_JSON =
    validation_results_path("reduced_ecckd_grouped_quadrature_search.json")
const REDUCED_GROUPED_QUADRATURE_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_grouped_quadrature_weight_refit.json")
const REDUCED_WEIGHT_MAXNORM_REFIT_JSON =
    validation_results_path("reduced_ecckd_weight_maxnorm_refit.json")
const REDUCED_CONSTRAINED_TABLE_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_constrained_table_optimizer.json")
const REDUCED_TOPOLOGY_CONSTRAINED_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_topology_constrained_optimizer.json")
const REDUCED_POST_CONSTRAINED_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_post_constrained_weight_refit.json")
const REDUCED_POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_post_constrained_boundary_weight_refit.json")
const REDUCED_HARDGATE_SUBSET_SEARCH_JSON =
    validation_results_path("reduced_ecckd_hardgate_subset_search.json")
const REDUCED_BOUNDARY_TOPOLOGY_REPLACEMENT_JSON =
    validation_results_path("reduced_ecckd_boundary_topology_replacement.json")
const REDUCED_BOUNDARY_TOPOLOGY_WEIGHT_REFIT_JSON =
    validation_results_path("reduced_ecckd_boundary_topology_weight_refit.json")
const REDUCED_BOUNDARY_TABLE_COORDINATE_SCAN_JSON =
    validation_results_path("reduced_ecckd_boundary_table_coordinate_scan.json")
const REDUCED_BOUNDARY_TABLE_PAIR_COORDINATE_SCAN_JSON =
    validation_results_path("reduced_ecckd_boundary_table_pair_coordinate_scan.json")
const REDUCED_BOUNDARY_TABLE_COORDINATE_DESCENT_JSON =
    validation_results_path("reduced_ecckd_boundary_table_coordinate_descent.json")
const REDUCED_BOUNDARY_TABLE_CONTINUATION_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_boundary_table_continuation_optimizer.json")
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
const REDUCED_RETAINED_TOPOLOGY_NEIGHBOR_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_topology_neighbor_scan.json")
const REDUCED_RETAINED_TOPOLOGY_CONSTRAINED_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_topology_constrained_optimizer.json")
const REDUCED_STRUCTURAL_OPTIMIZER_SWEEP_JSON =
    validation_results_path("reduced_ecckd_structural_optimizer_sweep.json")
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
const REDUCED_RETAINED_STRUCTURAL_PARETO_PROBE_JSON =
    validation_results_path("reduced_ecckd_retained_structural_pareto_probe.json")
const REDUCED_RETAINED_QUADRATURE_PARETO_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_quadrature_pareto_scan.json")
const REDUCED_RETAINED_QUADRATURE_PAIR_PARETO_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_quadrature_pair_pareto_scan.json")
const REDUCED_RETAINED_QUADRATURE_LINEARIZED_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_quadrature_linearized_optimizer.json")
const REDUCED_RETAINED_CURRENT_QUADRATURE_LINEARIZED_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_current_quadrature_linearized_optimizer.json")
const REDUCED_RETAINED_CURRENT_BOUNDED_TABLE_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_current_bounded_table_optimizer.json")
const REDUCED_RETAINED_CURRENT_HEATING_PROFILE_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_current_heating_profile_optimizer.json")
const REDUCED_RETAINED_CURRENT_JOINT_HEATING_OPTIMIZER_JSON =
    validation_results_path("reduced_ecckd_retained_current_joint_heating_optimizer.json")
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
const REDUCED_RETAINED_CURRENT_PRESSURE_COMPONENT_RAYLEIGH_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_pressure_component_rayleigh_scan.json")
const REDUCED_RETAINED_CURRENT_PRESSURE_COMPONENT_SURFACE_GUARD_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_pressure_component_surface_guard_scan.json")
const REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_scan.json")
const REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_continuation_scan.json")
const REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION2_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_continuation2_scan.json")
const REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION3_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_current_gas_pressure_component_continuation3_scan.json")
const REDUCED_BROADER_SUPPORT_REFIT_SEARCH_JSON =
    validation_results_path("reduced_ecckd_broader_support_refit_search.json")
const REDUCED_NONLOCAL_SUPPORT_REFIT_SEARCH_JSON =
    validation_results_path("reduced_ecckd_nonlocal_support_refit_search.json")
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
const REDUCED_RETAINED_TABLE_COORDINATE_PARETO_SCAN_JSON =
    validation_results_path("reduced_ecckd_retained_table_coordinate_pareto_scan.json")
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
const REDUCED_RETAINED_BOUNDARY_PROBE_EXPANSION_JSON =
    validation_results_path("reduced_ecckd_retained_boundary_probe_expansion.json")
const REDUCED_RETAINED_TOA_PROBE_EXPANSION_JSON =
    validation_results_path("reduced_ecckd_retained_toa_probe_expansion.json")
const REDUCED_BOUNDARY_TABLE_TRIPLE_COORDINATE_SCAN_JSON =
    validation_results_path("reduced_ecckd_boundary_table_triple_coordinate_scan.json")
const GAP_JSON = validation_results_path("reduced_ecckd_gap_report.json")
const GAP_MD = validation_results_path("reduced_ecckd_gap_report.md")

function table_rows(markdown)
    rows = NamedTuple[]
    for line in split(markdown, '\n')
        startswith(line, "| 32 |") || startswith(line, "| 16 |") || continue
        occursin("Method", line) && continue
        columns = strip.(split(strip(line, ['|', ' ']), "|"))
        length(columns) >= 6 || continue
        push!(rows, (
            ng_lw = parse(Int, columns[1]),
            ng_sw = parse(Int, columns[2]),
            method = columns[3],
            passed = columns[4] == "true",
            toa_forcing_error_w_m2 = parse(Float64, split(columns[5])[1]),
            surface_forcing_error_w_m2 = parse(Float64, split(columns[6])[1]),
        ))
    end
    return rows
end

function json_escape(text)
    return replace(text, "\\" => "\\\\", "\"" => "\\\"", "\n" => "\\n")
end

function json_value(value)
    if value === nothing
        return "null"
    elseif value isa AbstractString
        return "\"" * json_escape(value) * "\""
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value isa NamedTuple
        return json_object(value)
    elseif value isa AbstractVector || value isa Tuple
        return "[" * join(json_value.(value), ", ") * "]"
    else
        return string(value)
    end
end

metric_or_na(value) = value === nothing || isnan(value) ? "n/a" : string(value)

function json_object(object)
    names = propertynames(object)
    lines = ["{"]
    for (i, name) in enumerate(names)
        comma = i == length(names) ? "" : ","
        push!(lines, "  \"$(name)\": $(json_value(getproperty(object, name)))$(comma)")
    end
    push!(lines, "}")
    return join(lines, "\n")
end

function json_string_field(text, key)
    match = Base.match(Regex("\"$key\"\\s*:\\s*\"([^\"]*)\""), text)
    return match === nothing ? "" : match.captures[1]
end

function json_number_field(text, key)
    match = Base.match(Regex("\"$key\"\\s*:\\s*([-+0-9.eE]+)"), text)
    return match === nothing ? NaN : parse(Float64, match.captures[1])
end

function json_number_field_or(text, key, default)
    value = json_number_field(text, key)
    return isnan(value) ? default : value
end

function json_nullable_number_field(text, key)
    number_match = Base.match(Regex("\"$key\"\\s*:\\s*([-+0-9.eE]+)"), text)
    number_match !== nothing && return parse(Float64, number_match.captures[1])
    null_match = Base.match(Regex("\"$key\"\\s*:\\s*null"), text)
    return null_match === nothing ? NaN : nothing
end

function json_top_level_number_field(text, key)
    pattern = "\"$key\""
    depth = 0
    in_string = false
    escaped = false
    i = firstindex(text)
    while i <= lastindex(text)
        char = text[i]
        if in_string
            if escaped
                escaped = false
            elseif char == '\\'
                escaped = true
            elseif char == '"'
                in_string = false
            end
        elseif char == '"'
            if depth == 1 && startswith(SubString(text, i), pattern)
                rest = SubString(text, i)
                match = Base.match(Regex("^\"$key\"\\s*:\\s*([-+0-9.eE]+)"), rest)
                match === nothing || return parse(Float64, match.captures[1])
            end
            in_string = true
        elseif char == '{' || char == '['
            depth += 1
        elseif char == '}' || char == ']'
            depth -= 1
        end
        i = nextind(text, i)
    end
    return NaN
end

function json_top_level_bool_field(text, key)
    pattern = "\"$key\""
    depth = 0
    in_string = false
    escaped = false
    i = firstindex(text)
    while i <= lastindex(text)
        char = text[i]
        if in_string
            if escaped
                escaped = false
            elseif char == '\\'
                escaped = true
            elseif char == '"'
                in_string = false
            end
        elseif char == '"'
            if depth == 1 && startswith(SubString(text, i), pattern)
                rest = SubString(text, i)
                match = Base.match(Regex("^\"$key\"\\s*:\\s*(true|false)"), rest)
                match === nothing || return match.captures[1] == "true"
            end
            in_string = true
        elseif char == '{' || char == '['
            depth += 1
        elseif char == '}' || char == ']'
            depth -= 1
        end
        i = nextind(text, i)
    end
    return false
end

function json_numbers(text, key)
    values = [
        parse(Float64, match.captures[1])
        for match in eachmatch(Regex("\"$key\"\\s*:\\s*([-+0-9.eE]+)"), text)
    ]
    isempty(values) ? [NaN] : values
end

function json_int_field(text, key)
    match = Base.match(Regex("\"$key\"\\s*:\\s*([0-9]+)"), text)
    return match === nothing ? 0 : parse(Int, match.captures[1])
end

function json_object_section(text, key)
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

function json_array_section(text, key)
    marker = "\"$key\": ["
    start = findfirst(marker, text)
    start === nothing && return ""
    section_start = last(start) + 1
    depth = 1
    for i in section_start:lastindex(text)
        char = text[i]
        if char == '['
            depth += 1
        elseif char == ']'
            depth -= 1
            depth == 0 && return text[section_start:i - 1]
        end
    end
    return ""
end

function json_array_object(text, key, index)
    section = json_array_section(text, key)
    section == "" && return ""
    object_index = 0
    object_start = nothing
    depth = 0
    in_string = false
    escaped = false
    i = firstindex(section)
    while i <= lastindex(section)
        char = section[i]
        if in_string
            if escaped
                escaped = false
            elseif char == '\\'
                escaped = true
            elseif char == '"'
                in_string = false
            end
        elseif char == '"'
            in_string = true
        elseif char == '{'
            depth == 0 && (object_start = i)
            depth += 1
        elseif char == '}'
            depth -= 1
            if depth == 0 && object_start !== nothing
                object_index += 1
                object_index == index && return section[object_start:i]
                object_start = nothing
            end
        end
        i = nextind(section, i)
    end
    return ""
end

function json_nested_max_number(text, section_key, value_key)
    section = json_array_section(text, section_key)
    section == "" && return NaN
    values = json_numbers(section, value_key)
    return all(isnan, values) ? NaN : maximum(values)
end

function selected_gpoints_from_section(text, key)
    section = json_object_section(text, key)
    section == "" && return Int[]
    match = Base.match(r"\"selected_shortwave_gpoints\"\s*:\s*\[([^\]]*)\]", section)
    match === nothing && return Int[]
    return [parse(Int, capture) for capture in split(match.captures[1], ',')]
end

function json_int_array_field(text, key)
    match = Base.match(Regex("\"$key\"\\s*:\\s*\\[([^\\]]*)\\]"), text)
    match === nothing && return Int[]
    raw = strip(match.captures[1])
    isempty(raw) && return Int[]
    return [parse(Int, strip(capture)) for capture in split(raw, ',')
            if !isempty(strip(capture))]
end

function optimization_summary()
    isfile(REDUCED_OPTIMIZATION_JSON) || return (
        present = false,
        acceptance_gap_status = "",
        final_objective_target_ratio = NaN,
        best_block = "",
        topology_scan_status = "",
        topology_candidate_count = 0,
        best_topology_method = "",
        best_topology_forcing_objective_lower_bound = NaN,
        final_worst_case = "",
        final_worst_metric = "",
        final_worst_value = NaN,
        final_worst_threshold = NaN,
        targeted_candidate_count = 0,
        targeted_best_objective = NaN,
        targeted_accepted = false,
        separated_candidate_count = 0,
        separated_best_objective = NaN,
        separated_accepted = false,
        next_optimizer_required_absolute_reduction = NaN,
        next_optimizer_required_relative_reduction = NaN,
        next_optimizer_recommended_parameterization = "",
        warm_topology_candidate_count = 0,
        warm_topology_best_objective = NaN,
        warm_topology_improved = false,
        finite_difference_candidate_count = 0,
        finite_difference_best_objective = NaN,
        finite_difference_improved = false,
        next_required_work = "",
    )
    text = read(REDUCED_OPTIMIZATION_JSON, String)
    topology = json_object_section(text, "topology_candidate_scan")
    final_breakdown = json_object_section(text, "final_objective_breakdown")
    targeted = json_object_section(text, "targeted_worst_metric_refinement")
    targeted_scan = json_object_section(targeted, "scan")
    separated = json_object_section(text, "separated_component_refinement")
    separated_scan = json_object_section(separated, "scan")
    next_optimizer = json_object_section(text, "constrained_table_optimizer_target")
    warm_topology = json_object_section(text, "warm_started_topology_neighbor_refinement")
    finite_difference =
        json_object_section(text, "finite_difference_coefficient_direction_refinement")
    return (
        present = true,
        acceptance_gap_status = json_string_field(text, "acceptance_gap_status"),
        final_objective_target_ratio = json_number_field(text, "final_objective_target_ratio"),
        best_block = json_string_field(text, "best_block"),
        topology_scan_status = json_string_field(topology, "status"),
        topology_candidate_count = json_int_field(topology, "candidate_count"),
        best_topology_method = json_string_field(topology, "best_method"),
        best_topology_forcing_objective_lower_bound =
            json_number_field(topology, "best_forcing_objective_lower_bound"),
        final_worst_case = json_string_field(final_breakdown, "worst_case"),
        final_worst_metric = json_string_field(final_breakdown, "worst_metric"),
        final_worst_value = json_number_field(final_breakdown, "worst_value"),
        final_worst_threshold = json_number_field(final_breakdown, "worst_threshold"),
        targeted_candidate_count = json_int_field(targeted_scan, "candidate_count"),
        targeted_best_objective = json_number_field(targeted, "target_best_objective"),
        targeted_accepted = occursin("\"accepted\": true", targeted),
        separated_candidate_count = json_int_field(separated_scan, "candidate_count"),
        separated_best_objective = json_number_field(separated, "target_best_objective"),
        separated_accepted = occursin("\"accepted\": true", separated),
        next_optimizer_required_absolute_reduction =
            json_number_field(next_optimizer, "required_absolute_reduction"),
        next_optimizer_required_relative_reduction =
            json_number_field(next_optimizer, "required_relative_reduction"),
        next_optimizer_recommended_parameterization =
            json_string_field(next_optimizer, "recommended_next_parameterization"),
        warm_topology_candidate_count = json_int_field(warm_topology, "candidate_count"),
        warm_topology_best_objective = json_number_field(warm_topology, "best_objective"),
        warm_topology_improved = occursin("\"improved\": true", warm_topology),
        finite_difference_candidate_count =
            json_int_field(finite_difference, "candidate_count"),
        finite_difference_best_objective =
            json_number_field(finite_difference, "best_objective"),
        finite_difference_improved =
            occursin("\"improved\": true", finite_difference),
        next_required_work = json_string_field(text, "next_required_work"),
    )
end

function coefficient_continuation_summary()
    isfile(REDUCED_COEFFICIENT_CONTINUATION_JSON) || return (
        present = false,
        status = "",
        initial_objective = NaN,
        final_objective = NaN,
        final_objective_target_ratio = NaN,
        best_start_label = "",
        best_start_objective = NaN,
        greedy_checkpoint_used = false,
        saved_state_count = 0,
        worst_case = "",
        worst_metric = "",
        worst_value = NaN,
        worst_threshold = NaN,
    )
    text = read(REDUCED_COEFFICIENT_CONTINUATION_JSON, String)
    breakdown = json_object_section(text, "final_objective_breakdown")
    return (
        present = true,
        status = json_string_field(text, "status"),
        initial_objective = json_top_level_number_field(text, "initial_objective"),
        final_objective = json_top_level_number_field(text, "final_objective"),
        final_objective_target_ratio =
            json_top_level_number_field(text, "final_objective_target_ratio"),
        best_start_label = json_string_field(text, "best_start_label"),
        best_start_objective =
            json_top_level_number_field(text, "best_start_objective"),
        greedy_checkpoint_used = occursin("\"greedy_checkpoint_used\": true", text),
        saved_state_count = json_int_field(text, "saved_state_count"),
        worst_case = json_string_field(breakdown, "worst_case"),
        worst_metric = json_string_field(breakdown, "worst_metric"),
        worst_value = json_number_field(breakdown, "worst_value"),
        worst_threshold = json_number_field(breakdown, "worst_threshold"),
    )
end

function subset_search_summary()
    isfile(REDUCED_SUBSET_SEARCH_JSON) || return (
        present = false,
        status = "",
        weighted_selected_shortwave_gpoints = Int[],
        pruned_full_fit_selected_shortwave_gpoints = Int[],
        hardgate_selected_shortwave_gpoints = Int[],
        selected_shortwave_weights_present = false,
    )
    text = read(REDUCED_SUBSET_SEARCH_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        weighted_selected_shortwave_gpoints =
            selected_gpoints_from_section(text, "best_weighted_subset"),
        pruned_full_fit_selected_shortwave_gpoints =
            selected_gpoints_from_section(text, "best_pruned_full_fit_subset"),
        hardgate_selected_shortwave_gpoints =
            selected_gpoints_from_section(text, "best_hardgate_weighted_subset"),
        selected_shortwave_weights_present = occursin("\"selected_shortwave_weights\"", text),
    )
end

function optical_depth_fit_summary()
    isfile(REDUCED_OPTICAL_DEPTH_FIT_JSON) || return (
        present = false,
        status = "",
        baseline_rmse = NaN,
        fitted_rmse = NaN,
        component_fitted_rmse = NaN,
        relative_rmse_reduction = NaN,
        component_relative_rmse_reduction = NaN,
        flux_baseline_objective = NaN,
        flux_scaled_objective = NaN,
        flux_component_scaled_objective = NaN,
        flux_scaled_improved = false,
        flux_component_scaled_improved = false,
        coefficient_table_fit_raw_optical_depth_rmse = NaN,
        coefficient_table_fit_clipped_optical_depth_rmse = NaN,
        coefficient_table_fit_physical_target_optical_depth_rmse = NaN,
        coefficient_table_fit_physical_target_flux_objective = NaN,
        coefficient_table_fit_flux_objective = NaN,
        coefficient_table_fit_flux_improved = false,
        coefficient_table_fit_passed_hard_thresholds = false,
        next_required_work = "",
    )
    text = read(REDUCED_OPTICAL_DEPTH_FIT_JSON, String)
    baseline = json_object_section(text, "baseline")
    fitted = json_object_section(text, "fitted")
    component_fitted = json_object_section(text, "component_fitted")
    coefficient_table_fit = json_object_section(text, "coefficient_table_fit")
    coefficient_table_raw_optical_depth =
        json_object_section(coefficient_table_fit, "raw_least_squares_optical_depth")
    coefficient_table_clipped_optical_depth =
        json_object_section(coefficient_table_fit, "clipped_model_optical_depth")
    coefficient_table_physical_target_optical_depth =
        json_object_section(coefficient_table_fit, "physical_target_optical_depth")
    return (
        present = true,
        status = json_string_field(text, "status"),
        baseline_rmse = json_number_field(baseline, "rmse"),
        fitted_rmse = json_number_field(fitted, "rmse"),
        component_fitted_rmse = json_number_field(component_fitted, "rmse"),
        relative_rmse_reduction = json_number_field(text, "relative_rmse_reduction"),
        component_relative_rmse_reduction =
            json_number_field(text, "component_relative_rmse_reduction"),
        flux_baseline_objective = json_number_field(text, "flux_baseline_objective"),
        flux_scaled_objective = json_number_field(text, "flux_scaled_objective"),
        flux_component_scaled_objective =
            json_number_field(text, "flux_component_scaled_objective"),
        flux_scaled_improved = occursin("\"flux_scaled_improved\": true", text),
        flux_component_scaled_improved =
            occursin("\"flux_component_scaled_improved\": true", text),
        coefficient_table_fit_raw_optical_depth_rmse =
            json_number_field(coefficient_table_raw_optical_depth, "rmse"),
        coefficient_table_fit_clipped_optical_depth_rmse =
            json_number_field(coefficient_table_clipped_optical_depth, "rmse"),
        coefficient_table_fit_physical_target_optical_depth_rmse =
            json_number_field(coefficient_table_physical_target_optical_depth, "rmse"),
        coefficient_table_fit_physical_target_flux_objective =
            json_number_field(coefficient_table_fit, "physical_target_flux_objective"),
        coefficient_table_fit_flux_objective =
            json_number_field(coefficient_table_fit, "flux_objective"),
        coefficient_table_fit_flux_improved =
            occursin("\"flux_improved\": true", coefficient_table_fit),
        coefficient_table_fit_passed_hard_thresholds =
            occursin("\"flux_passed_hard_thresholds\": true", coefficient_table_fit),
        next_required_work = json_string_field(text, "next_required_work"),
    )
end

function size_weight_refit_summary()
    isfile(REDUCED_SIZE_WEIGHT_REFIT_JSON) || return (
        present = false,
        status = "",
        best_ng_sw = 0,
        best_method = "",
        best_refit_objective = NaN,
        best_toa_forcing_error = NaN,
        best_surface_forcing_error = NaN,
        any_passed = false,
    )
    text = read(REDUCED_SIZE_WEIGHT_REFIT_JSON, String)
    rows = eachmatch(r"\{[\s\S]*?\"method\"\s*:\s*\"([^\"]+)\"[\s\S]*?\"ng_sw\"\s*:\s*([0-9]+)[\s\S]*?\"refit_objective\"\s*:\s*([-+0-9.eE]+)[\s\S]*?\"passed_hard_thresholds\"\s*:\s*(true|false)[\s\S]*?\"worst_toa_forcing_error\"\s*:\s*([-+0-9.eE]+)[\s\S]*?\"worst_surface_forcing_error\"\s*:\s*([-+0-9.eE]+)[\s\S]*?\}", text)
    parsed = [
        (
            method = match.captures[1],
            ng_sw = parse(Int, match.captures[2]),
            refit_objective = parse(Float64, match.captures[3]),
            passed = match.captures[4] == "true",
            toa = parse(Float64, match.captures[5]),
            surface = parse(Float64, match.captures[6]),
        )
        for match in rows
    ]
    isempty(parsed) && return (
        present = true,
        status = json_string_field(text, "status"),
        best_ng_sw = 0,
        best_method = "",
        best_refit_objective = NaN,
        best_toa_forcing_error = NaN,
        best_surface_forcing_error = NaN,
        any_passed = occursin("\"passed_hard_thresholds\": true", text),
    )
    best = argmin(row -> row.refit_objective, parsed)
    return (
        present = true,
        status = json_string_field(text, "status"),
        best_ng_sw = best.ng_sw,
        best_method = best.method,
        best_refit_objective = best.refit_objective,
        best_toa_forcing_error = best.toa,
        best_surface_forcing_error = best.surface,
        any_passed = any(row -> row.passed, parsed),
    )
end

function leave_one_out_scan_summary()
    isfile(REDUCED_LEAVE_ONE_OUT_SCAN_JSON) || return (
        present = false,
        status = "",
        candidate_count = 0,
        pass_count = 0,
        best_omitted_gpoint = 0,
        best_objective = NaN,
        best_toa_forcing_error_w_m2 = NaN,
        best_surface_forcing_error_w_m2 = NaN,
        worst_omitted_gpoint = 0,
        worst_objective = NaN,
        worst_toa_forcing_error_w_m2 = NaN,
        worst_surface_forcing_error_w_m2 = NaN,
    )
    text = read(REDUCED_LEAVE_ONE_OUT_SCAN_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        candidate_count = Int(round(json_number_field(text, "candidate_count"))),
        pass_count = Int(round(json_number_field(text, "pass_count"))),
        best_omitted_gpoint = Int(round(json_number_field(text, "best_omitted_gpoint"))),
        best_objective = json_number_field(text, "best_objective"),
        best_toa_forcing_error_w_m2 =
            json_number_field(text, "best_toa_forcing_error_w_m2"),
        best_surface_forcing_error_w_m2 =
            json_number_field(text, "best_surface_forcing_error_w_m2"),
        worst_omitted_gpoint = Int(round(json_number_field(text, "worst_omitted_gpoint"))),
        worst_objective = json_number_field(text, "worst_objective"),
        worst_toa_forcing_error_w_m2 =
            json_number_field(text, "worst_toa_forcing_error_w_m2"),
        worst_surface_forcing_error_w_m2 =
            json_number_field(text, "worst_surface_forcing_error_w_m2"),
    )
end

function leave_one_out_weight_refit_summary()
    isfile(REDUCED_LEAVE_ONE_OUT_WEIGHT_REFIT_JSON) || return (
        present = false,
        status = "",
        candidate_count = 0,
        pass_count = 0,
        best_omitted_gpoint = 0,
        best_initial_objective = NaN,
        best_refit_objective = NaN,
        best_objective_reduction = NaN,
        best_refit_toa_forcing_error_w_m2 = NaN,
        best_refit_surface_forcing_error_w_m2 = NaN,
        worst_omitted_gpoint = 0,
        worst_refit_objective = NaN,
        worst_refit_toa_forcing_error_w_m2 = NaN,
        worst_refit_surface_forcing_error_w_m2 = NaN,
    )
    text = read(REDUCED_LEAVE_ONE_OUT_WEIGHT_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        candidate_count = Int(round(json_number_field(text, "candidate_count"))),
        pass_count = Int(round(json_number_field(text, "pass_count"))),
        best_omitted_gpoint = Int(round(json_number_field(text, "best_omitted_gpoint"))),
        best_initial_objective = json_number_field(text, "best_initial_objective"),
        best_refit_objective = json_number_field(text, "best_refit_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_refit_toa_forcing_error_w_m2 =
            json_number_field(text, "best_refit_toa_forcing_error_w_m2"),
        best_refit_surface_forcing_error_w_m2 =
            json_number_field(text, "best_refit_surface_forcing_error_w_m2"),
        worst_omitted_gpoint = Int(round(json_number_field(text, "worst_omitted_gpoint"))),
        worst_refit_objective = json_number_field(text, "worst_refit_objective"),
        worst_refit_toa_forcing_error_w_m2 =
            json_number_field(text, "worst_refit_toa_forcing_error_w_m2"),
        worst_refit_surface_forcing_error_w_m2 =
            json_number_field(text, "worst_refit_surface_forcing_error_w_m2"),
    )
end

function importance_group_scan_summary()
    isfile(REDUCED_IMPORTANCE_GROUP_SCAN_JSON) || return (
        present = false,
        status = "",
        importance_source = "",
        grouping_rule = "",
        candidate_count = 0,
        pass_count = 0,
        best_label = "",
        best_refit_objective = NaN,
        best_toa_forcing_error_w_m2 = NaN,
        best_surface_forcing_error_w_m2 = NaN,
    )
    text = read(REDUCED_IMPORTANCE_GROUP_SCAN_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        importance_source = json_string_field(text, "importance_source"),
        grouping_rule = json_string_field(text, "grouping_rule"),
        candidate_count = Int(round(json_number_field(text, "candidate_count"))),
        pass_count = Int(round(json_number_field(text, "pass_count"))),
        best_label = json_string_field(text, "best_label"),
        best_refit_objective = json_number_field(text, "best_refit_objective"),
        best_toa_forcing_error_w_m2 =
            json_number_field(text, "best_toa_forcing_error_w_m2"),
        best_surface_forcing_error_w_m2 =
            json_number_field(text, "best_surface_forcing_error_w_m2"),
    )
end

function support_swap_scan_summary()
    isfile(REDUCED_SUPPORT_SWAP_SCAN_JSON) || return (
        present = false,
        status = "",
        seed_count = 0,
        exact_top_n = 0,
        best_overall_objective = NaN,
        best_overall_indices = Int[],
        best_overall_removed_gpoint = 0,
        best_overall_added_gpoint = 0,
        best_overall_passed_hard_thresholds = false,
    )
    text = read(REDUCED_SUPPORT_SWAP_SCAN_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        seed_count = json_int_field(text, "seed_count"),
        exact_top_n = json_int_field(text, "exact_top_n"),
        best_overall_objective = json_number_field(text, "best_overall_objective"),
        best_overall_indices = json_int_array_field(text, "best_overall_indices"),
        best_overall_removed_gpoint =
            json_int_field(text, "best_overall_removed_gpoint"),
        best_overall_added_gpoint =
            json_int_field(text, "best_overall_added_gpoint"),
        best_overall_passed_hard_thresholds =
            occursin("\"best_overall_passed_hard_thresholds\": true", text),
    )
end

function support_swap_continuation_scan_summary()
    isfile(REDUCED_SUPPORT_SWAP_CONTINUATION_SCAN_JSON) || return (
        present = false,
        status = "",
        exact_top_n = 0,
        seed_exact_objective = NaN,
        best_objective = NaN,
        best_objective_reduction = NaN,
        best_indices = Int[],
        best_removed_gpoint = 0,
        best_added_gpoint = 0,
        best_passed_hard_thresholds = false,
    )
    text = read(REDUCED_SUPPORT_SWAP_CONTINUATION_SCAN_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        exact_top_n = json_int_field(text, "exact_top_n"),
        seed_exact_objective = json_number_field(text, "seed_exact_objective"),
        best_objective = json_number_field(text, "best_objective"),
        best_objective_reduction =
            json_number_field(text, "best_objective_reduction"),
        best_indices = json_int_array_field(text, "best_indices"),
        best_removed_gpoint = json_int_field(text, "best_removed_gpoint"),
        best_added_gpoint = json_int_field(text, "best_added_gpoint"),
        best_passed_hard_thresholds =
            occursin("\"best_passed_hard_thresholds\": true", text),
    )
end

function support_expansion_scan_summary()
    isfile(REDUCED_SUPPORT_EXPANSION_SCAN_JSON) || return (
        present = false,
        status = "",
        seed_count = 0,
        exact_top_n = 0,
        best_overall_objective = NaN,
        best_overall_ng = 0,
        best_overall_added_gpoints = Int[],
        best_overall_indices = Int[],
        best_overall_passed_hard_thresholds = false,
    )
    text = read(REDUCED_SUPPORT_EXPANSION_SCAN_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        seed_count = json_int_field(text, "seed_count"),
        exact_top_n = json_int_field(text, "exact_top_n"),
        best_overall_objective = json_number_field(text, "best_overall_objective"),
        best_overall_ng = json_int_field(text, "best_overall_ng"),
        best_overall_added_gpoints =
            json_int_array_field(text, "best_overall_added_gpoints"),
        best_overall_indices = json_int_array_field(text, "best_overall_indices"),
        best_overall_passed_hard_thresholds =
            occursin("\"best_overall_passed_hard_thresholds\": true", text),
    )
end

function support_expansion_refit_scan_summary()
    isfile(REDUCED_SUPPORT_EXPANSION_REFIT_SCAN_JSON) || return (
        present = false,
        status = "",
        iterations = 0,
        pnorm = 0,
        candidate_count = 0,
        start_count = 0,
        best_label = "",
        best_objective = NaN,
        best_start_label = "",
        best_ng = 0,
        best_added_gpoints = Int[],
        best_indices = Int[],
        best_passed_hard_thresholds = false,
    )
    text = read(REDUCED_SUPPORT_EXPANSION_REFIT_SCAN_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        iterations = json_int_field(text, "iterations"),
        pnorm = json_int_field(text, "pnorm"),
        candidate_count = json_int_field(text, "candidate_count"),
        start_count = json_int_field(text, "start_count"),
        best_label = json_string_field(text, "best_label"),
        best_objective = json_number_field(text, "best_objective"),
        best_start_label = json_string_field(text, "best_start_label"),
        best_ng = json_int_field(text, "best_ng"),
        best_added_gpoints = json_int_array_field(text, "best_added_gpoints"),
        best_indices = json_int_array_field(text, "best_indices"),
        best_passed_hard_thresholds =
            occursin("\"best_passed_hard_thresholds\": true", text),
    )
end

function random_support_search_summary()
    isfile(REDUCED_RANDOM_SUPPORT_SEARCH_JSON) || return (
        present = false,
        status = "",
        rng_seed = 0,
        random_seed_count = 0,
        candidate_count = 0,
        exact_top_n = 0,
        iterations = 0,
        pnorm = 0,
        best_label = "",
        best_objective = NaN,
        best_indices = Int[],
        best_passed_hard_thresholds = false,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        best_worst_heating_rate_rmse_k_day = NaN,
        canonical_seed_objective = NaN,
        subset_hardgate_seed_objective = NaN,
    )
    text = read(REDUCED_RANDOM_SUPPORT_SEARCH_JSON, String)
    deterministic_seed_objective(label) = begin
        section = json_array_section(text, "deterministic_seed_candidates")
        section == "" && return NaN
        for match in eachmatch(r"\{[^{}]*\}", section)
            object = match.match
            occursin("\"label\": \"$label\"", object) || continue
            return json_number_field(object, "exact_objective")
        end
        return NaN
    end
    return (
        present = true,
        status = json_string_field(text, "status"),
        rng_seed = json_int_field(text, "rng_seed"),
        random_seed_count = json_int_field(text, "random_seed_count"),
        candidate_count = json_int_field(text, "candidate_count"),
        exact_top_n = json_int_field(text, "exact_top_n"),
        iterations = json_int_field(text, "iterations"),
        pnorm = json_int_field(text, "pnorm"),
        best_label = json_string_field(text, "best_label"),
        best_objective = json_number_field(text, "best_objective"),
        best_indices = json_int_array_field(text, "best_indices"),
        best_passed_hard_thresholds =
            occursin("\"best_passed_hard_thresholds\": true", text),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        best_worst_heating_rate_rmse_k_day =
            json_number_field(text, "best_worst_heating_rate_rmse_k_day"),
        canonical_seed_objective =
            deterministic_seed_objective("canonical_weighted_greedy_support"),
        subset_hardgate_seed_objective =
            deterministic_seed_objective("subset_search_hardgate_support"),
    )
end

function current_metric_breakdown_summary()
    isfile(REDUCED_CURRENT_METRIC_BREAKDOWN_JSON) || return (
        present = false,
        status = "",
        hard_objective = NaN,
        worst_case = "",
        worst_variable = "",
        worst_metric = "",
        worst_value = NaN,
        worst_threshold = NaN,
        second_case = "",
        second_variable = "",
        second_metric = "",
        second_value = NaN,
        second_threshold = NaN,
        second_normalized_value = NaN,
        selected_shortwave_gpoint_count = 0,
    )
    text = read(REDUCED_CURRENT_METRIC_BREAKDOWN_JSON, String)
    second = json_array_object(text, "rows", 2)
    return (
        present = true,
        status = json_string_field(text, "status"),
        hard_objective = json_number_field(text, "hard_objective"),
        worst_case = json_string_field(text, "worst_case"),
        worst_variable = json_string_field(text, "worst_variable"),
        worst_metric = json_string_field(text, "worst_metric"),
        worst_value = json_number_field(text, "worst_value"),
        worst_threshold = json_number_field(text, "worst_threshold"),
        second_case = json_string_field(second, "case"),
        second_variable = json_string_field(second, "variable"),
        second_metric = json_string_field(second, "metric"),
        second_value = json_number_field(second, "value"),
        second_threshold = json_number_field(second, "threshold"),
        second_normalized_value = json_number_field(second, "normalized_value"),
        selected_shortwave_gpoint_count =
            let match = Base.match(r"\"selected_shortwave_gpoints\"\s*:\s*\[([^\]]*)\]", text)
                match === nothing ? 0 :
                count(item -> !isempty(item), strip.(split(match.captures[1], ",")))
            end,
    )
end

function reduced_acceptance_decision_summary(
    current_metric_breakdown,
    random_support_search,
    support_swap_scan,
    support_swap_continuation_scan,
    support_expansion_scan,
    support_expansion_refit_scan,
    broader_support_refit_search,
    nonlocal_support_refit_search,
)
    local_support_rejected =
        support_swap_scan.present &&
        support_swap_continuation_scan.present &&
        support_expansion_scan.present &&
        support_expansion_refit_scan.present &&
        random_support_search.present &&
        support_swap_scan.status == "failed_threshold" &&
        support_swap_continuation_scan.status == "failed_threshold" &&
        support_expansion_scan.status == "failed_threshold" &&
        support_expansion_refit_scan.status == "failed_threshold" &&
        random_support_search.status == "failed_threshold"
    local_refit_chain_required =
        random_support_search.present &&
        isfinite(random_support_search.canonical_seed_objective) &&
        isfinite(current_metric_breakdown.hard_objective) &&
        random_support_search.canonical_seed_objective >
        current_metric_breakdown.hard_objective
    bounded_broader_support_refit_rejected =
        broader_support_refit_search.present &&
        broader_support_refit_search.status == "support_refit_rejected" &&
        broader_support_refit_search.evaluated_candidate_count > 0 &&
        broader_support_refit_search.best_objective >
        current_metric_breakdown.hard_objective
    nonlocal_support_refit_rejected =
        nonlocal_support_refit_search.present &&
        nonlocal_support_refit_search.status == "nonlocal_support_refit_rejected" &&
        nonlocal_support_refit_search.evaluated_candidate_count ==
        nonlocal_support_refit_search.total_candidate_count &&
        nonlocal_support_refit_search.best_objective >
        current_metric_breakdown.hard_objective
    status =
        current_metric_breakdown.status == "passed" ? "passed" :
        local_support_rejected ? "decision_required" : "more_diagnostic_search_required"
    recommended_next_decision =
        status == "passed" ? "accept reduced 16-g model" :
        nonlocal_support_refit_rejected ?
        "choose between revising the reduced-model acceptance target or allowing a different reduced basis" :
        bounded_broader_support_refit_rejected ?
        "choose between a full global/nonlocal support-plus-refit search, revising the reduced-model acceptance target, or allowing a different reduced basis" :
        local_support_rejected ?
        "choose between a broader joint support-plus-refit search and revising the reduced-model acceptance target" :
        "complete the bounded support and refit diagnostics before changing acceptance criteria"
    remaining_options =
        nonlocal_support_refit_rejected ? [
            "revise the hard reduced 16-g acceptance target or split it from the validated 32-g production acceptance target",
            "allow a different reduced basis, such as more shortwave g-points or a non-subset coefficient table, for the Breeze/RRTMG-compatible reduced path",
        ] : bounded_broader_support_refit_rejected ? [
            "run a full global/nonlocal support-plus-refit search beyond the rejected bounded radius-$(broader_support_refit_search.radius) neighborhood",
            "revise the hard reduced 16-g acceptance target or split it from the validated 32-g production acceptance target",
            "allow a different reduced basis, such as more shortwave g-points or a non-subset coefficient table, for the Breeze/RRTMG-compatible reduced path",
        ] : [
            "run a qualitatively broader joint support-plus-refit search that evaluates candidate supports through the composed table/component/gas-pressure refit chain",
            "revise the hard reduced 16-g acceptance target or split it from the validated 32-g production acceptance target",
            "allow a different reduced basis, such as more shortwave g-points or a non-subset coefficient table, for the Breeze/RRTMG-compatible reduced path",
        ]
    return (
        present = true,
        status = status,
        blocker = "reduced_16g_hard_threshold",
        objective_target = 1.0,
        current_hard_objective = current_metric_breakdown.hard_objective,
        current_objective_target_ratio = current_metric_breakdown.hard_objective,
        worst_case = current_metric_breakdown.worst_case,
        worst_metric = current_metric_breakdown.worst_metric,
        worst_value = current_metric_breakdown.worst_value,
        worst_threshold = current_metric_breakdown.worst_threshold,
        second_case = current_metric_breakdown.second_case,
        second_metric = current_metric_breakdown.second_metric,
        second_normalized_value = current_metric_breakdown.second_normalized_value,
        local_support_searches_rejected = local_support_rejected,
        current_chain_required_for_best_row = local_refit_chain_required,
        bounded_broader_support_refit_rejected =
            bounded_broader_support_refit_rejected,
        bounded_broader_support_refit_best_objective =
            broader_support_refit_search.best_objective,
        bounded_broader_support_refit_evaluated_candidate_count =
            broader_support_refit_search.evaluated_candidate_count,
        nonlocal_support_refit_rejected = nonlocal_support_refit_rejected,
        nonlocal_support_refit_best_objective =
            nonlocal_support_refit_search.best_objective,
        nonlocal_support_refit_evaluated_candidate_count =
            nonlocal_support_refit_search.evaluated_candidate_count,
        random_support_best_objective = random_support_search.best_objective,
        bare_canonical_support_objective =
            random_support_search.canonical_seed_objective,
        recommended_next_decision = recommended_next_decision,
        remaining_options = remaining_options,
    )
end

function pressure_band_refinement_summary()
    isfile(REDUCED_PRESSURE_BAND_JSON) || return (
        present = false,
        status = "",
        current_objective = NaN,
        target_case = "",
        target_metric = "",
        target_metric_objective = NaN,
        candidate_count = 0,
        best_metric_objective = NaN,
        best_full_objective = NaN,
        accepted = false,
        iterative_accepted_move_count = 0,
        iterative_final_objective = NaN,
        iterative_objective_reduction = NaN,
        iterative_improved = false,
        next_required_work = "",
    )
    text = read(REDUCED_PRESSURE_BAND_JSON, String)
    scan = json_object_section(text, "scan")
    best_metric = json_object_section(scan, "best_metric_candidate")
    best_full = json_object_section(scan, "best_full_candidate")
    iterative = json_object_section(text, "iterative_gpoint_scan")
    return (
        present = true,
        status = json_string_field(text, "status"),
        current_objective = json_number_field(text, "current_objective"),
        target_case = json_string_field(text, "target_case"),
        target_metric = json_string_field(text, "target_metric"),
        target_metric_objective = json_number_field(text, "target_metric_objective"),
        candidate_count = json_int_field(text, "candidate_count"),
        best_metric_objective = json_number_field(best_metric, "metric_objective"),
        best_full_objective = json_number_field(best_full, "full_objective"),
        accepted = occursin("\"accepted\": true", scan),
        iterative_accepted_move_count =
            json_int_field(iterative, "accepted_move_count"),
        iterative_final_objective =
            json_number_field(iterative, "final_full_objective"),
        iterative_objective_reduction =
            json_number_field(iterative, "objective_reduction"),
        iterative_improved = occursin("\"improved\": true", iterative),
        next_required_work = json_string_field(text, "next_required_work"),
    )
end

function targeted_entry_summary()
    isfile(REDUCED_TARGETED_ENTRY_JSON) || return (
        present = false,
        final_objective = NaN,
        objective_reduction = NaN,
        accepted_move_count = 0,
        targeted_candidate_count = 0,
        iterations_requested = 0,
    )
    text = read(REDUCED_TARGETED_ENTRY_JSON, String)
    return (
        present = true,
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted_move_count = json_int_field(text, "accepted_move_count"),
        targeted_candidate_count = json_int_field(text, "targeted_candidate_count"),
        iterations_requested = json_int_field(text, "iterations_requested"),
    )
end

function global_entry_summary()
    isfile(REDUCED_GLOBAL_ENTRY_JSON) || return (
        present = false,
        final_objective = NaN,
        objective_reduction = NaN,
        accepted_move_count = 0,
        cumulative_active_move_count = 0,
        total_ranked_candidate_count = 0,
        candidate_limit = 0,
        candidate_offset = 0,
        iterations_requested = 0,
    )
    text = read(REDUCED_GLOBAL_ENTRY_JSON, String)
    starting_count = json_int_field(text, "starting_active_move_count")
    accepted_count = json_int_field(text, "accepted_move_count")
    return (
        present = true,
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted_move_count = accepted_count,
        cumulative_active_move_count = starting_count + accepted_count,
        total_ranked_candidate_count =
            json_int_field(text, "total_ranked_candidate_count"),
        candidate_limit = json_int_field(text, "candidate_limit"),
        candidate_offset = json_int_field(text, "candidate_offset"),
        iterations_requested = json_int_field(text, "iterations_requested"),
    )
end

function global_block_entry_summary()
    isfile(REDUCED_GLOBAL_BLOCK_ENTRY_JSON) || return (
        present = false,
        final_objective = NaN,
        objective_reduction = NaN,
        accepted_move_count = 0,
        cumulative_active_move_count = 0,
        group_limit = 0,
        iterations_requested = 0,
    )
    text = read(REDUCED_GLOBAL_BLOCK_ENTRY_JSON, String)
    starting_count = json_int_field(text, "starting_active_move_count")
    accepted_count = json_int_field(text, "accepted_move_count")
    return (
        present = true,
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted_move_count = accepted_count,
        cumulative_active_move_count = starting_count + accepted_count,
        group_limit = json_int_field(text, "group_limit"),
        iterations_requested = json_int_field(text, "iterations_requested"),
    )
end

function global_block_linearized_entry_summary()
    isfile(REDUCED_GLOBAL_BLOCK_LINEARIZED_ENTRY_JSON) || return (
        present = false,
        basis_count = 0,
        best_ridge_lambda = NaN,
        base_objective = NaN,
        candidate_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        accepted = false,
        accepted_move_count = 0,
        cumulative_active_move_count = 0,
    )
    text = read(REDUCED_GLOBAL_BLOCK_LINEARIZED_ENTRY_JSON, String)
    starting_count = json_int_field(text, "starting_active_move_count")
    accepted_count = json_int_field(text, "accepted_move_count")
    return (
        present = true,
        basis_count = json_int_field(text, "basis_count"),
        best_ridge_lambda = json_number_field(text, "best_ridge_lambda"),
        base_objective = json_number_field(text, "base_objective"),
        candidate_objective = json_number_field(text, "candidate_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted = occursin("\"accepted\": true", text),
        accepted_move_count = accepted_count,
        cumulative_active_move_count = starting_count + accepted_count,
    )
end

function linearized_entry_summary()
    isfile(REDUCED_LINEARIZED_ENTRY_JSON) || return (
        present = false,
        fitted_candidate_count = 0,
        best_ridge_lambda = NaN,
        base_objective = NaN,
        candidate_objective = NaN,
        objective_reduction = NaN,
        accepted = false,
    )
    text = read(REDUCED_LINEARIZED_ENTRY_JSON, String)
    return (
        present = true,
        fitted_candidate_count = json_int_field(text, "fitted_candidate_count"),
        best_ridge_lambda = json_number_field(text, "best_ridge_lambda"),
        base_objective = json_number_field(text, "base_objective"),
        candidate_objective = json_number_field(text, "candidate_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted = occursin("\"accepted\": true", text),
    )
end

function global_linearized_entry_summary()
    isfile(REDUCED_GLOBAL_LINEARIZED_ENTRY_JSON) || return (
        present = false,
        fitted_candidate_count = 0,
        best_ridge_lambda = NaN,
        base_objective = NaN,
        candidate_objective = NaN,
        objective_reduction = NaN,
        accepted = false,
    )
    text = read(REDUCED_GLOBAL_LINEARIZED_ENTRY_JSON, String)
    return (
        present = true,
        fitted_candidate_count = json_int_field(text, "fitted_candidate_count"),
        best_ridge_lambda = json_number_field(text, "best_ridge_lambda"),
        base_objective = json_number_field(text, "base_objective"),
        candidate_objective = json_number_field(text, "candidate_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted = occursin("\"accepted\": true", text),
    )
end

function topology_slot_summary()
    isfile(REDUCED_TOPOLOGY_SLOT_JSON) || return (
        present = false,
        radius = 0,
        candidate_count = 0,
        pair_candidate_count = 0,
        base_objective = NaN,
        best_objective = NaN,
        best_improvement = NaN,
        improved = false,
        best_removed_gpoint = 0,
        best_added_gpoint = 0,
    )
    text = read(REDUCED_TOPOLOGY_SLOT_JSON, String)
    return (
        present = true,
        radius = json_int_field(text, "radius"),
        candidate_count = json_int_field(text, "candidate_count"),
        pair_candidate_count = json_int_field(text, "pair_candidate_count"),
        base_objective = json_number_field(text, "base_objective"),
        best_objective = json_number_field(text, "best_objective"),
        best_improvement = json_number_field(text, "best_improvement"),
        improved = occursin("\"improved\": true", text),
        best_removed_gpoint = json_int_field(text, "best_removed_gpoint"),
        best_added_gpoint = json_int_field(text, "best_added_gpoint"),
    )
end

function post_table_weight_summary()
    isfile(REDUCED_POST_TABLE_WEIGHT_JSON) || return (
        present = false,
        base_objective = NaN,
        refit_objective = NaN,
        objective_reduction = NaN,
        accepted = false,
        iterations = 0,
    )
    text = read(REDUCED_POST_TABLE_WEIGHT_JSON, String)
    return (
        present = true,
        base_objective = json_number_field(text, "base_objective"),
        refit_objective = json_number_field(text, "refit_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted = occursin("\"accepted\": true", text),
        iterations = json_int_field(text, "iterations"),
    )
end

function exact_weight_refit_summary()
    isfile(REDUCED_EXACT_WEIGHT_REFIT_JSON) || return (
        present = false,
        initial_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        accepted = false,
        iterations_completed = 0,
    )
    text = read(REDUCED_EXACT_WEIGHT_REFIT_JSON, String)
    return (
        present = true,
        initial_objective = json_number_field(text, "initial_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted = occursin("\"accepted\": true", text),
        iterations_completed = json_int_field(text, "iterations_completed"),
    )
end

function joint_weight_block_refit_summary()
    isfile(REDUCED_JOINT_WEIGHT_BLOCK_REFIT_JSON) || return (
        present = false,
        basis_count = 0,
        best_ridge_lambda = NaN,
        best_direction = "",
        residual_mode = "",
        base_objective = NaN,
        candidate_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        accepted = false,
        accepted_move_count = 0,
        cumulative_active_move_count = 0,
    )
    text = read(REDUCED_JOINT_WEIGHT_BLOCK_REFIT_JSON, String)
    starting_count = json_int_field(text, "starting_active_move_count")
    accepted_count = json_int_field(text, "accepted_move_count")
    return (
        present = true,
        basis_count = json_int_field(text, "basis_count"),
        best_ridge_lambda = json_number_field(text, "best_ridge_lambda"),
        best_direction = json_string_field(text, "best_direction"),
        residual_mode = json_string_field(text, "residual_mode"),
        base_objective = json_number_field(text, "base_objective"),
        candidate_objective = json_number_field(text, "candidate_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted = occursin("\"accepted\": true", text),
        accepted_move_count = accepted_count,
        cumulative_active_move_count = starting_count + accepted_count,
    )
end

function boundary_column_refinement_summary()
    isfile(REDUCED_BOUNDARY_COLUMN_REFINEMENT_JSON) || return (
        present = false,
        target_case = "",
        target_metric = "",
        target_column = 0,
        target_residual_w_m2 = NaN,
        evaluated_candidate_count = 0,
        evaluated_trial_count = 0,
        base_objective = NaN,
        candidate_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        accepted = false,
        accepted_move_count = 0,
        cumulative_active_move_count = 0,
    )
    text = read(REDUCED_BOUNDARY_COLUMN_REFINEMENT_JSON, String)
    starting_count = json_int_field(text, "starting_active_move_count")
    accepted_count = json_int_field(text, "accepted_move_count")
    return (
        present = true,
        target_case = json_string_field(text, "target_case"),
        target_metric = json_string_field(text, "target_metric"),
        target_column = json_int_field(text, "target_column"),
        target_residual_w_m2 = json_number_field(text, "target_residual_w_m2"),
        evaluated_candidate_count = json_int_field(text, "evaluated_candidate_count"),
        evaluated_trial_count = json_int_field(text, "evaluated_trial_count"),
        base_objective = json_number_field(text, "base_objective"),
        candidate_objective = json_number_field(text, "candidate_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted = occursin("\"accepted\": true", text),
        accepted_move_count = accepted_count,
        cumulative_active_move_count = starting_count + accepted_count,
    )
end

function slot_blend_refinement_summary()
    isfile(REDUCED_SLOT_BLEND_REFINEMENT_JSON) || return (
        present = false,
        radius = 0,
        candidate_count = 0,
        evaluated_trial_count = 0,
        base_objective = NaN,
        candidate_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        accepted = false,
        accepted_blend_count = 0,
        best_source_gpoint = 0,
        best_blend_gpoint = 0,
        best_alpha = NaN,
    )
    text = read(REDUCED_SLOT_BLEND_REFINEMENT_JSON, String)
    return (
        present = true,
        radius = json_int_field(text, "radius"),
        candidate_count = json_int_field(text, "candidate_count"),
        evaluated_trial_count = json_int_field(text, "evaluated_trial_count"),
        base_objective = json_number_field(text, "base_objective"),
        candidate_objective = json_number_field(text, "candidate_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted = occursin("\"accepted\": true", text),
        accepted_blend_count = json_int_field(text, "accepted_blend_count"),
        best_source_gpoint = json_int_field(text, "best_source_gpoint"),
        best_blend_gpoint = json_int_field(text, "best_blend_gpoint"),
        best_alpha = json_number_field(text, "best_alpha"),
    )
end

function pair_slot_blend_refinement_summary()
    isfile(REDUCED_PAIR_SLOT_BLEND_REFINEMENT_JSON) || return (
        present = false,
        base_blend_count = 0,
        ranked_single_count = 0,
        evaluated_pair_count = 0,
        base_objective = NaN,
        best_single_objective = NaN,
        best_pair_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        accepted = false,
        accepted_blend_count = 0,
        total_blend_count = 0,
    )
    text = read(REDUCED_PAIR_SLOT_BLEND_REFINEMENT_JSON, String)
    return (
        present = true,
        base_blend_count = json_int_field(text, "base_blend_count"),
        ranked_single_count = json_int_field(text, "ranked_single_count"),
        evaluated_pair_count = json_int_field(text, "evaluated_pair_count"),
        base_objective = json_number_field(text, "base_objective"),
        best_single_objective = json_number_field(text, "best_single_objective"),
        best_pair_objective = json_number_field(text, "best_pair_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted = occursin("\"accepted\": true", text),
        accepted_blend_count = json_int_field(text, "accepted_blend_count"),
        total_blend_count = json_int_field(text, "total_blend_count"),
    )
end

function slot_blend_linearized_summary()
    isfile(REDUCED_SLOT_BLEND_LINEARIZED_REFIT_JSON) || return (
        present = false,
        status = "",
        base_blend_count = 0,
        candidate_count = 0,
        single_trial_count = 0,
        probe_alpha = NaN,
        max_alpha = NaN,
        base_objective = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_positive_delta_count = 0,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        accepted = false,
        accepted_blend_count = 0,
        total_blend_count = 0,
    )
    text = read(REDUCED_SLOT_BLEND_LINEARIZED_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_blend_count = json_int_field(text, "base_blend_count"),
        candidate_count = json_int_field(text, "candidate_count"),
        single_trial_count = json_int_field(text, "single_trial_count"),
        probe_alpha = json_number_field(text, "probe_alpha"),
        max_alpha = json_number_field(text, "max_alpha"),
        base_objective = json_number_field(text, "base_objective"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_positive_delta_count = json_int_field(text, "best_positive_delta_count"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        accepted = occursin("\"accepted\": true", text),
        accepted_blend_count = json_int_field(text, "accepted_blend_count"),
        total_blend_count = json_int_field(text, "total_blend_count"),
    )
end

function post_slot_weight_refit_summary()
    isfile(REDUCED_POST_SLOT_WEIGHT_REFIT_JSON) || return (
        present = false,
        status = "",
        base_blend_count = 0,
        iterations_completed = 0,
        initial_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        accepted = false,
        initial_worst_toa_forcing_error_w_m2 = NaN,
        initial_worst_surface_forcing_error_w_m2 = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
    )
    text = read(REDUCED_POST_SLOT_WEIGHT_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_blend_count = json_int_field(text, "base_blend_count"),
        iterations_completed = json_int_field(text, "iterations_completed"),
        initial_objective = json_number_field(text, "initial_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted = occursin("\"accepted\": true", text),
        initial_worst_toa_forcing_error_w_m2 =
            json_nested_max_number(text, "initial_cases", "toa_forcing_max_abs"),
        initial_worst_surface_forcing_error_w_m2 =
            json_nested_max_number(text, "initial_cases", "surface_forcing_max_abs"),
        final_worst_toa_forcing_error_w_m2 =
            json_nested_max_number(text, "final_cases", "toa_forcing_max_abs"),
        final_worst_surface_forcing_error_w_m2 =
            json_nested_max_number(text, "final_cases", "surface_forcing_max_abs"),
    )
end

function boundary_column_block_refinement_summary()
    isfile(REDUCED_BOUNDARY_COLUMN_BLOCK_REFINEMENT_JSON) || return (
        present = false,
        target_case = "",
        target_metric = "",
        target_column = 0,
        evaluated_trial_count = 0,
        base_objective = NaN,
        candidate_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        accepted = false,
        accepted_move_count = 0,
        cumulative_active_move_count = 0,
        best_component = "",
        best_block_size = 0,
    )
    text = read(REDUCED_BOUNDARY_COLUMN_BLOCK_REFINEMENT_JSON, String)
    starting_count = json_int_field(text, "starting_active_move_count")
    accepted_count = json_int_field(text, "accepted_move_count")
    return (
        present = true,
        target_case = json_string_field(text, "target_case"),
        target_metric = json_string_field(text, "target_metric"),
        target_column = json_int_field(text, "target_column"),
        evaluated_trial_count = json_int_field(text, "evaluated_trial_count"),
        base_objective = json_number_field(text, "base_objective"),
        candidate_objective = json_number_field(text, "candidate_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted = occursin("\"accepted\": true", text),
        accepted_move_count = accepted_count,
        cumulative_active_move_count = starting_count + accepted_count,
        best_component = json_string_field(text, "best_component"),
        best_block_size = json_int_field(text, "best_block_size"),
    )
end

function gas_pressure_band_refinement_summary()
    isfile(REDUCED_GAS_PRESSURE_BAND_REFINEMENT_JSON) || return (
        present = false,
        target_case = "",
        target_metric = "",
        target_column = 0,
        pressure_band_count = 0,
        evaluated_candidate_count = 0,
        evaluated_trial_count = 0,
        base_objective = NaN,
        candidate_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        accepted = false,
        accepted_move_count = 0,
        best_component = "",
        best_gpoint = 0,
        best_gas_index = 0,
    )
    text = read(REDUCED_GAS_PRESSURE_BAND_REFINEMENT_JSON, String)
    return (
        present = true,
        target_case = json_string_field(text, "target_case"),
        target_metric = json_string_field(text, "target_metric"),
        target_column = json_int_field(text, "target_column"),
        pressure_band_count = json_int_field(text, "pressure_band_count"),
        evaluated_candidate_count = json_int_field(text, "evaluated_candidate_count"),
        evaluated_trial_count = json_int_field(text, "evaluated_trial_count"),
        base_objective = json_number_field(text, "base_objective"),
        candidate_objective = json_number_field(text, "candidate_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted = occursin("\"accepted\": true", text),
        accepted_move_count = json_int_field(text, "accepted_move_count"),
        best_component = json_string_field(text, "best_component"),
        best_gpoint = json_int_field(text, "best_gpoint"),
        best_gas_index = json_int_field(text, "best_gas_index"),
    )
end

function gas_pressure_band_linearized_summary()
    isfile(REDUCED_GAS_PRESSURE_BAND_LINEARIZED_JSON) || return (
        present = false,
        fitted_candidate_count = 0,
        best_ridge_lambda = NaN,
        best_direction = "",
        base_objective = NaN,
        candidate_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        accepted = false,
        accepted_move_count = 0,
    )
    text = read(REDUCED_GAS_PRESSURE_BAND_LINEARIZED_JSON, String)
    return (
        present = true,
        fitted_candidate_count = json_int_field(text, "fitted_candidate_count"),
        best_ridge_lambda = json_number_field(text, "best_ridge_lambda"),
        best_direction = json_string_field(text, "best_direction"),
        base_objective = json_number_field(text, "base_objective"),
        candidate_objective = json_number_field(text, "candidate_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted = occursin("\"accepted\": true", text),
        accepted_move_count = json_int_field(text, "accepted_move_count"),
    )
end

function flux_pair_bins_summary()
    isfile(REDUCED_FLUX_PAIR_BINS_JSON) || return (
        present = false,
        status = "",
        objective = NaN,
        worst_toa_forcing_error = NaN,
        worst_surface_forcing_error = NaN,
        passed_hard_thresholds = false,
    )
    text = read(REDUCED_FLUX_PAIR_BINS_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        objective = json_number_field(text, "objective"),
        worst_toa_forcing_error = json_number_field(text, "worst_toa_forcing_error"),
        worst_surface_forcing_error =
            json_number_field(text, "worst_surface_forcing_error"),
        passed_hard_thresholds = occursin("\"passed_hard_thresholds\": true", text),
    )
end

function grouped_quadrature_search_summary()
    isfile(REDUCED_GROUPED_QUADRATURE_SEARCH_JSON) || return (
        present = false,
        status = "",
        candidate_count = 0,
        best_label = "",
        best_objective = NaN,
        best_worst_toa_forcing_error = NaN,
        best_worst_surface_forcing_error = NaN,
        passed_hard_thresholds = false,
    )
    text = read(REDUCED_GROUPED_QUADRATURE_SEARCH_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        candidate_count = json_int_field(text, "candidate_count"),
        best_label = json_string_field(text, "best_label"),
        best_objective = json_number_field(text, "best_objective"),
        best_worst_toa_forcing_error =
            json_number_field(text, "best_worst_toa_forcing_error"),
        best_worst_surface_forcing_error =
            json_number_field(text, "best_worst_surface_forcing_error"),
        passed_hard_thresholds = occursin("\"passed_hard_thresholds\": true", text),
    )
end

function grouped_quadrature_weight_refit_summary()
    isfile(REDUCED_GROUPED_QUADRATURE_WEIGHT_REFIT_JSON) || return (
        present = false,
        status = "",
        candidate_count = 0,
        iterations = 0,
        best_label = "",
        best_base_objective = NaN,
        best_refit_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error = NaN,
        best_worst_surface_forcing_error = NaN,
        passed_hard_thresholds = false,
    )
    text = read(REDUCED_GROUPED_QUADRATURE_WEIGHT_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        candidate_count = json_int_field(text, "candidate_count"),
        iterations = json_int_field(text, "iterations"),
        best_label = json_string_field(text, "best_label"),
        best_base_objective = json_number_field(text, "best_base_objective"),
        best_refit_objective = json_number_field(text, "best_refit_objective"),
        best_objective_reduction =
            json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error =
            json_number_field(text, "best_worst_toa_forcing_error"),
        best_worst_surface_forcing_error =
            json_number_field(text, "best_worst_surface_forcing_error"),
        passed_hard_thresholds =
            occursin("\"passed_hard_thresholds\": true", text),
    )
end

function weight_maxnorm_refit_summary()
    isfile(REDUCED_WEIGHT_MAXNORM_REFIT_JSON) || return (
        present = false,
        status = "",
        base_exact_objective = NaN,
        base_linear_objective = NaN,
        best_label = "",
        best_exact_objective = NaN,
        best_approximate_objective = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        best_max_abs_weight_delta = NaN,
        accepted = false,
    )
    text = read(REDUCED_WEIGHT_MAXNORM_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_exact_objective = json_number_field(text, "base_exact_objective"),
        base_linear_objective = json_number_field(text, "base_linear_objective"),
        best_label = json_string_field(text, "best_label"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_approximate_objective = json_number_field(text, "best_approximate_objective"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        best_max_abs_weight_delta = json_number_field(text, "best_max_abs_weight_delta"),
        accepted = occursin("\"accepted\": true", text),
    )
end

function constrained_table_optimizer_summary()
    isfile(REDUCED_CONSTRAINED_TABLE_OPTIMIZER_JSON) || return (
        present = false,
        status = "",
        candidate_scope = "",
        include_rayleigh = false,
        candidate_count = 0,
        probe_step = NaN,
        max_log_scale = NaN,
        base_objective = NaN,
        best_ridge_lambda = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        accepted = false,
    )
    text = read(REDUCED_CONSTRAINED_TABLE_OPTIMIZER_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        candidate_scope = json_string_field(text, "candidate_scope"),
        include_rayleigh = occursin("\"include_rayleigh\": true", text),
        candidate_count = json_int_field(text, "candidate_count"),
        probe_step = json_number_field(text, "probe_step"),
        max_log_scale = json_number_field(text, "max_log_scale"),
        base_objective = json_number_field(text, "base_objective"),
        best_ridge_lambda = json_number_field(text, "best_ridge_lambda"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        accepted = occursin("\"accepted\": true", text),
    )
end

function topology_constrained_optimizer_summary()
    isfile(REDUCED_TOPOLOGY_CONSTRAINED_OPTIMIZER_JSON) || return (
        present = false,
        status = "",
        candidate_count = 0,
        max_log_scale = NaN,
        best_label = "",
        best_exact_objective = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        topology_count = 0,
    )
    text = read(REDUCED_TOPOLOGY_CONSTRAINED_OPTIMIZER_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        candidate_count = json_int_field(text, "candidates_per_topology"),
        max_log_scale = json_number_field(text, "max_log_scale"),
        best_label = json_string_field(text, "best_label"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        topology_count = length(collect(eachmatch(r"\"label\"\s*:", text))),
    )
end

function post_constrained_weight_refit_summary()
    isfile(REDUCED_POST_CONSTRAINED_WEIGHT_REFIT_JSON) || return (
        present = false,
        status = "",
        initial_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        accepted = false,
        initial_worst_toa_forcing_error_w_m2 = NaN,
        initial_worst_surface_forcing_error_w_m2 = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
    )
    text = read(REDUCED_POST_CONSTRAINED_WEIGHT_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        initial_objective = json_number_field(text, "initial_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        accepted = occursin("\"accepted\": true", text),
        initial_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "initial_worst_toa_forcing_error_w_m2"),
        initial_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "initial_worst_surface_forcing_error_w_m2"),
        final_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "final_worst_toa_forcing_error_w_m2"),
        final_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "final_worst_surface_forcing_error_w_m2"),
    )
end

function post_constrained_boundary_weight_refit_summary()
    isfile(REDUCED_POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_JSON) || return (
        present = false,
        status = "",
        initial_boundary_objective = NaN,
        final_boundary_objective = NaN,
        boundary_objective_reduction = NaN,
        initial_full_objective = NaN,
        final_full_objective = NaN,
        accepted = false,
        initial_worst_toa_forcing_error_w_m2 = NaN,
        initial_worst_surface_forcing_error_w_m2 = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
    )
    text = read(REDUCED_POST_CONSTRAINED_BOUNDARY_WEIGHT_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        initial_boundary_objective =
            json_number_field(text, "initial_boundary_objective"),
        final_boundary_objective =
            json_number_field(text, "final_boundary_objective"),
        boundary_objective_reduction =
            json_number_field(text, "boundary_objective_reduction"),
        initial_full_objective = json_number_field(text, "initial_full_objective"),
        final_full_objective = json_number_field(text, "final_full_objective"),
        accepted = occursin("\"accepted\": true", text),
        initial_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "initial_worst_toa_forcing_error_w_m2"),
        initial_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "initial_worst_surface_forcing_error_w_m2"),
        final_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "final_worst_toa_forcing_error_w_m2"),
        final_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "final_worst_surface_forcing_error_w_m2"),
    )
end

function hardgate_subset_search_summary()
    isfile(REDUCED_HARDGATE_SUBSET_SEARCH_JSON) || return (
        present = false,
        status = "",
        exact_objective = NaN,
        approximate_objective = NaN,
        worst_toa_forcing_error_w_m2 = NaN,
        worst_surface_forcing_error_w_m2 = NaN,
        passed_hard_thresholds = false,
        selected_shortwave_gpoints = Int[],
    )
    text = read(REDUCED_HARDGATE_SUBSET_SEARCH_JSON, String)
    best = json_object_section(text, "best")
    indices_match = Base.match(r"\"indices\"\s*:\s*\[([^\]]*)\]", best)
    selected = indices_match === nothing ? Int[] :
        [parse(Int, strip(token)) for token in split(indices_match.captures[1], ",")
         if !isempty(strip(token))]
    return (
        present = true,
        status = json_string_field(text, "status"),
        exact_objective = json_number_field(best, "exact_objective"),
        approximate_objective = json_number_field(best, "approximate_objective"),
        worst_toa_forcing_error_w_m2 =
            json_number_field(best, "worst_toa_forcing_error_w_m2"),
        worst_surface_forcing_error_w_m2 =
            json_number_field(best, "worst_surface_forcing_error_w_m2"),
        passed_hard_thresholds = occursin("\"passed_hard_thresholds\": true", best),
        selected_shortwave_gpoints = selected,
    )
end

function boundary_topology_replacement_summary()
    isfile(REDUCED_BOUNDARY_TOPOLOGY_REPLACEMENT_JSON) || return (
        present = false,
        status = "",
        radius = 0,
        evaluated_candidate_count = 0,
        base_objective = NaN,
        best_objective = NaN,
        best_improvement = NaN,
        best_removed_gpoint = 0,
        best_added_gpoint = 0,
    )
    text = read(REDUCED_BOUNDARY_TOPOLOGY_REPLACEMENT_JSON, String)
    best = json_object_section(text, "best")
    return (
        present = true,
        status = json_string_field(text, "status"),
        radius = json_int_field(text, "radius"),
        evaluated_candidate_count = json_int_field(text, "evaluated_candidate_count"),
        base_objective = json_number_field(text, "base_objective"),
        best_objective = json_number_field(best, "objective"),
        best_improvement = json_number_field(best, "improvement"),
        best_removed_gpoint = json_int_field(best, "removed_gpoint"),
        best_added_gpoint = json_int_field(best, "added_gpoint"),
    )
end

function boundary_topology_weight_refit_summary()
    isfile(REDUCED_BOUNDARY_TOPOLOGY_WEIGHT_REFIT_JSON) || return (
        present = false,
        status = "",
        radius = 0,
        weight_iterations = 0,
        evaluated_candidate_count = 0,
        base_objective = NaN,
        best_objective = NaN,
        best_improvement = NaN,
        best_removed_gpoint = 0,
        best_added_gpoint = 0,
    )
    text = read(REDUCED_BOUNDARY_TOPOLOGY_WEIGHT_REFIT_JSON, String)
    best = json_object_section(text, "best")
    return (
        present = true,
        status = json_string_field(text, "status"),
        radius = json_int_field(text, "radius"),
        weight_iterations = json_int_field(text, "weight_iterations"),
        evaluated_candidate_count = json_int_field(text, "evaluated_candidate_count"),
        base_objective = json_number_field(text, "base_objective"),
        best_objective = json_number_field(best, "objective"),
        best_improvement = json_number_field(best, "improvement"),
        best_removed_gpoint = json_int_field(best, "removed_gpoint"),
        best_added_gpoint = json_int_field(best, "added_gpoint"),
    )
end

function broader_support_refit_search_summary()
    isfile(REDUCED_BROADER_SUPPORT_REFIT_SEARCH_JSON) || return (
        present = false,
        status = "",
        objective_target = NaN,
        radius = 0,
        prefilter_evaluated_count = 0,
        evaluated_candidate_count = 0,
        total_neighbor_candidate_count = 0,
        current_objective = NaN,
        best_objective = NaN,
        best_objective_reduction = NaN,
        best_passed_hard_objective = false,
        best_removed_gpoint = 0,
        best_added_gpoint = 0,
    )
    text = read(REDUCED_BROADER_SUPPORT_REFIT_SEARCH_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        objective_target = json_top_level_number_field(text, "objective_target"),
        radius = json_int_field(text, "radius"),
        prefilter_evaluated_count = json_int_field(text, "prefilter_evaluated_count"),
        evaluated_candidate_count = json_int_field(text, "evaluated_candidate_count"),
        total_neighbor_candidate_count = json_int_field(text, "total_neighbor_candidate_count"),
        current_objective = json_top_level_number_field(text, "current_objective"),
        best_objective = json_top_level_number_field(text, "best_objective"),
        best_objective_reduction =
            json_top_level_number_field(text, "best_objective_reduction"),
        best_passed_hard_objective =
            json_top_level_bool_field(text, "best_passed_hard_objective"),
        best_removed_gpoint = json_int_field(text, "best_removed_gpoint"),
        best_added_gpoint = json_int_field(text, "best_added_gpoint"),
    )
end

function nonlocal_support_refit_search_summary()
    isfile(REDUCED_NONLOCAL_SUPPORT_REFIT_SEARCH_JSON) || return (
        present = false,
        status = "",
        objective_target = NaN,
        evaluated_candidate_count = 0,
        total_candidate_count = 0,
        current_objective = NaN,
        best_objective = NaN,
        best_objective_reduction = NaN,
        best_passed_hard_objective = false,
        best_label = "",
    )
    text = read(REDUCED_NONLOCAL_SUPPORT_REFIT_SEARCH_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        objective_target = json_top_level_number_field(text, "objective_target"),
        evaluated_candidate_count = json_int_field(text, "evaluated_candidate_count"),
        total_candidate_count = json_int_field(text, "total_candidate_count"),
        current_objective = json_top_level_number_field(text, "current_objective"),
        best_objective = json_top_level_number_field(text, "best_objective"),
        best_objective_reduction =
            json_top_level_number_field(text, "best_objective_reduction"),
        best_passed_hard_objective =
            json_top_level_bool_field(text, "best_passed_hard_objective"),
        best_label = json_string_field(text, "best_label"),
    )
end

function boundary_table_coordinate_scan_summary()
    isfile(REDUCED_BOUNDARY_TABLE_COORDINATE_SCAN_JSON) || return (
        present = false,
        status = "",
        acceptance_rule = "",
        pareto_tolerance = NaN,
        surface_cap_w_m2 = NaN,
        candidate_count = 0,
        trial_count = 0,
        base_objective = NaN,
        best_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        accepted = false,
    )
    text = read(REDUCED_BOUNDARY_TABLE_COORDINATE_SCAN_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        candidate_count = json_int_field(text, "candidate_count"),
        trial_count = json_int_field(text, "trial_count"),
        base_objective = json_number_field(text, "base_objective"),
        best_objective = json_number_field(text, "best_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        accepted = occursin("\"accepted\": true", text),
    )
end

function boundary_table_pair_coordinate_scan_summary()
    isfile(REDUCED_BOUNDARY_TABLE_PAIR_COORDINATE_SCAN_JSON) || return (
        present = false,
        status = "",
        single_trial_count = 0,
        selected_single_count = 0,
        pair_trial_count = 0,
        base_objective = NaN,
        best_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        accepted = false,
    )
    text = read(REDUCED_BOUNDARY_TABLE_PAIR_COORDINATE_SCAN_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        single_trial_count = json_int_field(text, "single_trial_count"),
        selected_single_count = json_int_field(text, "selected_single_count"),
        pair_trial_count = json_int_field(text, "pair_trial_count"),
        base_objective = json_number_field(text, "base_objective"),
        best_objective = json_number_field(text, "best_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        accepted = occursin("\"accepted\": true", text),
    )
end

function boundary_table_coordinate_descent_summary()
    isfile(REDUCED_BOUNDARY_TABLE_COORDINATE_DESCENT_JSON) || return (
        present = false,
        status = "",
        candidate_count = 0,
        iteration_limit = 0,
        completed_iterations = 0,
        baseline_objective = NaN,
        final_objective = NaN,
        final_objective_reduction = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
        accepted = false,
    )
    text = read(REDUCED_BOUNDARY_TABLE_COORDINATE_DESCENT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        candidate_count = json_int_field(text, "candidate_count"),
        iteration_limit = json_int_field(text, "iteration_limit"),
        completed_iterations = json_int_field(text, "completed_iterations"),
        baseline_objective = json_number_field(text, "baseline_objective"),
        final_objective = json_number_field(text, "final_objective"),
        final_objective_reduction = json_number_field(text, "final_objective_reduction"),
        final_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "final_worst_toa_forcing_error_w_m2"),
        final_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "final_worst_surface_forcing_error_w_m2"),
        accepted = occursin("\"accepted\": true", text),
    )
end

function boundary_table_continuation_optimizer_summary()
    isfile(REDUCED_BOUNDARY_TABLE_CONTINUATION_OPTIMIZER_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        candidate_scope = "",
        residual_mode = "",
        include_rayleigh = false,
        candidate_count = 0,
        probe_step = NaN,
        max_log_scale = NaN,
        base_objective = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        accepted = false,
    )
    text = read(REDUCED_BOUNDARY_TABLE_CONTINUATION_OPTIMIZER_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        candidate_scope = json_string_field(text, "candidate_scope"),
        residual_mode = json_string_field(text, "residual_mode"),
        include_rayleigh = occursin("\"include_rayleigh\": true", text),
        candidate_count = json_int_field(text, "candidate_count"),
        probe_step = json_number_field(text, "probe_step"),
        max_log_scale = json_number_field(text, "max_log_scale"),
        base_objective = json_number_field(text, "base_objective"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        accepted = occursin("\"accepted\": true", text),
    )
end

function component_scale_refit_summary()
    isfile(REDUCED_COMPONENT_SCALE_REFIT_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        parameter_count = 0,
        coordinate_iterations_requested = 0,
        coordinate_iteration_count = 0,
        base_objective = NaN,
        coordinate_final_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
        accepted = false,
    )
    text = read(REDUCED_COMPONENT_SCALE_REFIT_JSON, String)
    iteration_count = length(collect(eachmatch(r"\"iteration\"\s*:", text)))
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        parameter_count = json_int_field(text, "parameter_count"),
        coordinate_iterations_requested =
            json_int_field(text, "coordinate_iterations_requested"),
        coordinate_iteration_count = iteration_count,
        base_objective = json_number_field(text, "base_objective"),
        coordinate_final_objective =
            json_number_field(text, "coordinate_final_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        final_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "final_worst_toa_forcing_error_w_m2"),
        final_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "final_worst_surface_forcing_error_w_m2"),
        accepted_move_count =
            length(collect(eachmatch(r"\"accepted_move\"\s*:", text))),
        accepted = occursin("\"accepted\": true", text),
    )
end

function pressure_component_scale_refit_summary()
    isfile(REDUCED_PRESSURE_COMPONENT_SCALE_REFIT_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        pressure_band_count = 0,
        candidate_count = 0,
        iteration_limit = 0,
        completed_iterations = 0,
        base_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
        accepted = false,
    )
    text = read(REDUCED_PRESSURE_COMPONENT_SCALE_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        pressure_band_count = json_int_field(text, "pressure_band_count"),
        candidate_count = json_int_field(text, "candidate_count"),
        iteration_limit = json_int_field(text, "iteration_limit"),
        completed_iterations = json_int_field(text, "completed_iterations"),
        base_objective = json_number_field(text, "base_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        final_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "final_worst_toa_forcing_error_w_m2"),
        final_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "final_worst_surface_forcing_error_w_m2"),
        accepted_move_count =
            length(collect(eachmatch(r"\"accepted_move\"\s*:", text))),
        accepted = occursin("\"accepted\": true", text),
    )
end

function temperature_component_scale_refit_summary()
    isfile(REDUCED_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        temperature_band_count = 0,
        candidate_count = 0,
        iteration_limit = 0,
        completed_iterations = 0,
        base_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
        accepted = false,
    )
    text = read(REDUCED_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        temperature_band_count = json_int_field(text, "temperature_band_count"),
        candidate_count = json_int_field(text, "candidate_count"),
        iteration_limit = json_int_field(text, "iteration_limit"),
        completed_iterations = json_int_field(text, "completed_iterations"),
        base_objective = json_number_field(text, "base_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        final_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "final_worst_toa_forcing_error_w_m2"),
        final_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "final_worst_surface_forcing_error_w_m2"),
        accepted_move_count =
            length(collect(eachmatch(r"\"accepted_move\"\s*:", text))),
        accepted = occursin("\"accepted\": true", text),
    )
end

function h2o_component_scale_refit_summary()
    isfile(REDUCED_H2O_COMPONENT_SCALE_REFIT_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        h2o_band_count = 0,
        candidate_count = 0,
        iteration_limit = 0,
        completed_iterations = 0,
        base_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
        accepted = false,
    )
    text = read(REDUCED_H2O_COMPONENT_SCALE_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        h2o_band_count = json_int_field(text, "h2o_band_count"),
        candidate_count = json_int_field(text, "candidate_count"),
        iteration_limit = json_int_field(text, "iteration_limit"),
        completed_iterations = json_int_field(text, "completed_iterations"),
        base_objective = json_number_field(text, "base_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        final_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "final_worst_toa_forcing_error_w_m2"),
        final_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "final_worst_surface_forcing_error_w_m2"),
        accepted_move_count =
            length(collect(eachmatch(r"\"accepted_move\"\s*:", text))),
        accepted = occursin("\"accepted\": true", text),
    )
end

function gas_component_scale_refit_summary()
    isfile(REDUCED_GAS_COMPONENT_SCALE_REFIT_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        candidate_count = 0,
        iteration_limit = 0,
        completed_iterations = 0,
        base_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
        accepted = false,
    )
    text = read(REDUCED_GAS_COMPONENT_SCALE_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        candidate_count = json_int_field(text, "candidate_count"),
        iteration_limit = json_int_field(text, "iteration_limit"),
        completed_iterations = json_int_field(text, "completed_iterations"),
        base_objective = json_number_field(text, "base_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        final_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "final_worst_toa_forcing_error_w_m2"),
        final_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "final_worst_surface_forcing_error_w_m2"),
        accepted_move_count =
            length(collect(eachmatch(r"\"accepted_move\"\s*:", text))),
        accepted = occursin("\"accepted\": true", text),
    )
end

function pressure_temperature_component_scale_refit_summary()
    isfile(REDUCED_PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        objective_mode = "",
        candidate_count = 0,
        iteration_limit = 0,
        completed_iterations = 0,
        base_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
        accepted = false,
    )
    text = read(REDUCED_PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        objective_mode = json_string_field(text, "objective_mode"),
        candidate_count = json_int_field(text, "candidate_count"),
        iteration_limit = json_int_field(text, "iteration_limit"),
        completed_iterations = json_int_field(text, "completed_iterations"),
        base_objective = json_number_field(text, "base_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        final_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "final_worst_toa_forcing_error_w_m2"),
        final_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "final_worst_surface_forcing_error_w_m2"),
        accepted_move_count =
            length(collect(eachmatch(r"\"accepted_move\"\s*:", text))),
        accepted = occursin("\"accepted\": true", text),
    )
end

function gas_pressure_temperature_component_scale_refit_summary()
    isfile(REDUCED_GAS_PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        candidate_count = 0,
        iteration_limit = 0,
        completed_iterations = 0,
        base_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
        accepted = false,
    )
    text = read(REDUCED_GAS_PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        candidate_count = json_int_field(text, "candidate_count"),
        iteration_limit = json_int_field(text, "iteration_limit"),
        completed_iterations = json_int_field(text, "completed_iterations"),
        base_objective = json_number_field(text, "base_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        final_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "final_worst_toa_forcing_error_w_m2"),
        final_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "final_worst_surface_forcing_error_w_m2"),
        accepted_move_count =
            length(collect(eachmatch(r"\"accepted_move\"\s*:", text))),
        accepted = occursin("\"accepted\": true", text),
    )
end

function h2o_pressure_temperature_component_scale_refit_summary()
    isfile(REDUCED_H2O_PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        candidate_count = 0,
        iteration_limit = 0,
        completed_iterations = 0,
        base_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
        accepted = false,
    )
    text = read(REDUCED_H2O_PRESSURE_TEMPERATURE_COMPONENT_SCALE_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        candidate_count = json_int_field(text, "candidate_count"),
        iteration_limit = json_int_field(text, "iteration_limit"),
        completed_iterations = json_int_field(text, "completed_iterations"),
        base_objective = json_number_field(text, "base_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        final_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "final_worst_toa_forcing_error_w_m2"),
        final_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "final_worst_surface_forcing_error_w_m2"),
        accepted_move_count =
            length(collect(eachmatch(r"\"accepted_move\"\s*:", text))),
        accepted = occursin("\"accepted\": true", text),
    )
end

function mixed_pressure_temperature_component_refit_summary()
    isfile(REDUCED_MIXED_PRESSURE_TEMPERATURE_COMPONENT_REFIT_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        candidate_count = 0,
        iteration_limit = 0,
        completed_iterations = 0,
        base_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
        accepted = false,
    )
    text = read(REDUCED_MIXED_PRESSURE_TEMPERATURE_COMPONENT_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        candidate_count = json_int_field(text, "candidate_count"),
        iteration_limit = json_int_field(text, "iteration_limit"),
        completed_iterations = json_int_field(text, "completed_iterations"),
        base_objective = json_number_field(text, "base_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        final_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "final_worst_toa_forcing_error_w_m2"),
        final_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "final_worst_surface_forcing_error_w_m2"),
        accepted_move_count =
            length(collect(eachmatch(r"\"accepted_move\"\s*:", text))),
        accepted = occursin("\"accepted\": true", text),
    )
end

function retained_mixed_component_pareto_scan_summary()
    isfile(REDUCED_RETAINED_MIXED_COMPONENT_PARETO_SCAN_JSON) || return (
        present = false,
        status = "",
        candidate_count = 0,
        trial_count = 0,
        base_objective = NaN,
        final_objective = NaN,
        objective_reduction = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        any_strict_pareto_safe = false,
        any_surface_cap_safe = false,
        any_pareto_safe = false,
        accepted = false,
    )
    text = read(REDUCED_RETAINED_MIXED_COMPONENT_PARETO_SCAN_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        acceptance_rule = json_string_field(text, "acceptance_rule"),
        pareto_tolerance = json_number_field(text, "pareto_tolerance"),
        surface_cap_w_m2 = json_number_field(text, "surface_cap_w_m2"),
        candidate_count = json_int_field(text, "candidate_count"),
        trial_count = json_int_field(text, "trial_count"),
        base_objective = json_number_field(text, "base_objective"),
        final_objective = json_number_field(text, "final_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        final_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "final_worst_toa_forcing_error_w_m2"),
        final_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "final_worst_surface_forcing_error_w_m2"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        any_strict_pareto_safe =
            occursin("\"any_strict_pareto_safe\": true", text),
        any_surface_cap_safe =
            occursin("\"any_surface_cap_safe\": true", text),
        any_pareto_safe = occursin("\"any_pareto_safe\": true", text),
        accepted = occursin("\"accepted\": true", text),
    )
end

function retained_topology_neighbor_scan_summary()
    isfile(REDUCED_RETAINED_TOPOLOGY_NEIGHBOR_SCAN_JSON) || return (
        present = false,
        status = "",
        radius = 0,
        candidate_count = 0,
        pair_candidate_count = 0,
        base_objective = NaN,
        best_objective = NaN,
        best_objective_reduction = NaN,
        best_slot = 0,
        best_old_gpoint = 0,
        best_new_gpoint = 0,
        base_worst_toa_forcing_error_w_m2 = NaN,
        base_worst_surface_forcing_error_w_m2 = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        pareto_safe = false,
        passed_hard_thresholds = false,
    )
    text = read(REDUCED_RETAINED_TOPOLOGY_NEIGHBOR_SCAN_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        radius = json_int_field(text, "radius"),
        candidate_count = json_int_field(text, "candidate_count"),
        pair_candidate_count = json_int_field(text, "pair_candidate_count"),
        base_objective = json_number_field(text, "base_objective"),
        best_objective = json_number_field(text, "best_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_slot = json_int_field(text, "best_slot"),
        best_old_gpoint = json_int_field(text, "best_old_gpoint"),
        best_new_gpoint = json_int_field(text, "best_new_gpoint"),
        base_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "base_worst_toa_forcing_error_w_m2"),
        base_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "base_worst_surface_forcing_error_w_m2"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        pareto_safe = occursin("\"pareto_safe\": true", text),
        passed_hard_thresholds = occursin("\"passed_hard_thresholds\": true", text),
    )
end

function retained_topology_constrained_optimizer_summary()
    isfile(REDUCED_RETAINED_TOPOLOGY_CONSTRAINED_OPTIMIZER_JSON) || return (
        present = false,
        status = "",
        candidate_scope = "",
        residual_mode = "",
        candidate_count = 0,
        base_objective = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        pareto_safe = false,
        accepted = false,
        proposed_move_count = 0,
    )
    text = read(REDUCED_RETAINED_TOPOLOGY_CONSTRAINED_OPTIMIZER_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        candidate_scope = json_string_field(text, "candidate_scope"),
        residual_mode = json_string_field(text, "residual_mode"),
        candidate_count = json_int_field(text, "candidate_count"),
        base_objective = json_number_field(text, "base_objective"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        pareto_safe = occursin("\"pareto_safe\": true", text),
        accepted = occursin("\"accepted\": true", text),
        proposed_move_count = length(collect(eachmatch(r"\"log_scale\"\s*:", text))),
    )
end

function structural_optimizer_sweep_summary()
    isfile(REDUCED_STRUCTURAL_OPTIMIZER_SWEEP_JSON) || return (
        present = false,
        status = "",
        config_count = 0,
        best_label = "",
        best_base_objective = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
    )
    text = read(REDUCED_STRUCTURAL_OPTIMIZER_SWEEP_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        config_count = json_int_field(text, "config_count"),
        best_label = json_string_field(text, "best_label"),
        best_base_objective = json_number_field(text, "best_base_objective"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction =
            json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
    )
end

function retained_structural_optimizer_summary()
    isfile(REDUCED_RETAINED_STRUCTURAL_OPTIMIZER_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        candidate_scope = "",
        residual_mode = "",
        include_rayleigh = false,
        candidate_count = 0,
        probe_step = NaN,
        max_log_scale = NaN,
        base_objective = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
        accepted = false,
    )
    text = read(REDUCED_RETAINED_STRUCTURAL_OPTIMIZER_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        candidate_scope = json_string_field(text, "candidate_scope"),
        residual_mode = json_string_field(text, "residual_mode"),
        include_rayleigh = occursin("\"include_rayleigh\": true", text),
        candidate_count = json_int_field(text, "candidate_count"),
        probe_step = json_number_field(text, "probe_step"),
        max_log_scale = json_number_field(text, "max_log_scale"),
        base_objective = json_number_field(text, "base_objective"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction =
            json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        accepted_move_count =
            length(collect(eachmatch(r"\"component\"\s*:", json_array_section(text, "accepted_moves")))),
        accepted = occursin("\"accepted\": true", text),
    )
end

function retained_structural_continuation_summary()
    isfile(REDUCED_RETAINED_STRUCTURAL_CONTINUATION_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        candidate_scope = "",
        residual_mode = "",
        include_rayleigh = false,
        candidate_count = 0,
        probe_step = NaN,
        max_log_scale = NaN,
        base_objective = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
        accepted = false,
    )
    text = read(REDUCED_RETAINED_STRUCTURAL_CONTINUATION_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        candidate_scope = json_string_field(text, "candidate_scope"),
        residual_mode = json_string_field(text, "residual_mode"),
        include_rayleigh = occursin("\"include_rayleigh\": true", text),
        candidate_count = json_int_field(text, "candidate_count"),
        probe_step = json_number_field(text, "probe_step"),
        max_log_scale = json_number_field(text, "max_log_scale"),
        base_objective = json_number_field(text, "base_objective"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction =
            json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        accepted_move_count =
            length(collect(eachmatch(r"\"component\"\s*:", json_array_section(text, "accepted_moves")))),
        accepted = occursin("\"accepted\": true", text),
    )
end

function retained_structural_continuation2_summary()
    isfile(REDUCED_RETAINED_STRUCTURAL_CONTINUATION2_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        candidate_scope = "",
        residual_mode = "",
        include_rayleigh = false,
        candidate_count = 0,
        probe_step = NaN,
        max_log_scale = NaN,
        base_objective = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
        accepted = false,
    )
    text = read(REDUCED_RETAINED_STRUCTURAL_CONTINUATION2_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        candidate_scope = json_string_field(text, "candidate_scope"),
        residual_mode = json_string_field(text, "residual_mode"),
        include_rayleigh = occursin("\"include_rayleigh\": true", text),
        candidate_count = json_int_field(text, "candidate_count"),
        probe_step = json_number_field(text, "probe_step"),
        max_log_scale = json_number_field(text, "max_log_scale"),
        base_objective = json_number_field(text, "base_objective"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction =
            json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        accepted_move_count =
            length(collect(eachmatch(r"\"component\"\s*:", json_array_section(text, "accepted_moves")))),
        accepted = occursin("\"accepted\": true", text),
    )
end

function retained_structural_continuation3_summary()
    isfile(REDUCED_RETAINED_STRUCTURAL_CONTINUATION3_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        candidate_scope = "",
        residual_mode = "",
        include_rayleigh = false,
        candidate_count = 0,
        probe_step = NaN,
        max_log_scale = NaN,
        base_objective = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
        accepted = false,
    )
    text = read(REDUCED_RETAINED_STRUCTURAL_CONTINUATION3_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        candidate_scope = json_string_field(text, "candidate_scope"),
        residual_mode = json_string_field(text, "residual_mode"),
        include_rayleigh = occursin("\"include_rayleigh\": true", text),
        candidate_count = json_int_field(text, "candidate_count"),
        probe_step = json_number_field(text, "probe_step"),
        max_log_scale = json_number_field(text, "max_log_scale"),
        base_objective = json_number_field(text, "base_objective"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction =
            json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        accepted_move_count =
            length(collect(eachmatch(r"\"component\"\s*:", json_array_section(text, "accepted_moves")))),
        accepted = occursin("\"accepted\": true", text),
    )
end

function retained_structural_continuation4_summary()
    isfile(REDUCED_RETAINED_STRUCTURAL_CONTINUATION4_JSON) || return (
        present = false,
        status = "",
        base_mode = "",
        candidate_scope = "",
        residual_mode = "",
        include_rayleigh = false,
        candidate_count = 0,
        probe_step = NaN,
        max_log_scale = NaN,
        base_objective = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
        accepted = false,
    )
    text = read(REDUCED_RETAINED_STRUCTURAL_CONTINUATION4_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        base_mode = json_string_field(text, "base_mode"),
        candidate_scope = json_string_field(text, "candidate_scope"),
        residual_mode = json_string_field(text, "residual_mode"),
        include_rayleigh = occursin("\"include_rayleigh\": true", text),
        candidate_count = json_int_field(text, "candidate_count"),
        probe_step = json_number_field(text, "probe_step"),
        max_log_scale = json_number_field(text, "max_log_scale"),
        base_objective = json_number_field(text, "base_objective"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction =
            json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        accepted_move_count =
            length(collect(eachmatch(r"\"component\"\s*:", json_array_section(text, "accepted_moves")))),
        accepted = occursin("\"accepted\": true", text),
    )
end

function retained_structural_pareto_probe_summary()
    isfile(REDUCED_RETAINED_STRUCTURAL_PARETO_PROBE_JSON) || return (
        present = false,
        status = "",
        config_count = 0,
        best_label = "",
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        any_accepted = false,
        any_pareto_safe = false,
    )
    text = read(REDUCED_RETAINED_STRUCTURAL_PARETO_PROBE_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        config_count = json_int_field(text, "config_count"),
        best_label = json_string_field(text, "best_label"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction =
            json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        any_accepted = occursin("\"any_accepted\": true", text),
        any_pareto_safe = occursin("\"any_pareto_safe\": true", text),
    )
end

function retained_quadrature_pareto_scan_summary()
    isfile(REDUCED_RETAINED_QUADRATURE_PARETO_SCAN_JSON) || return (
        present = false,
        status = "",
        candidate_count = 0,
        base_objective = NaN,
        best_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        best_gpoint = 0,
        best_step = NaN,
        best_direction = "",
        best_toa_regressed = false,
        best_surface_regressed = false,
        any_pareto_safe = false,
        best_safe_objective = NaN,
    )
    text = read(REDUCED_RETAINED_QUADRATURE_PARETO_SCAN_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        candidate_count = json_int_field(text, "candidate_count"),
        base_objective = json_number_field(text, "base_objective"),
        best_objective = json_number_field(text, "best_objective"),
        best_objective_reduction =
            json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        best_gpoint = json_int_field(text, "best_gpoint"),
        best_step = json_number_field(text, "best_step"),
        best_direction = json_string_field(text, "best_direction"),
        best_toa_regressed = occursin("\"best_toa_regressed\": true", text),
        best_surface_regressed =
            occursin("\"best_surface_regressed\": true", text),
        any_pareto_safe = occursin("\"any_pareto_safe\": true", text),
        best_safe_objective = json_number_field(text, "best_safe_objective"),
    )
end

function retained_quadrature_pair_pareto_scan_summary()
    isfile(REDUCED_RETAINED_QUADRATURE_PAIR_PARETO_SCAN_JSON) || return (
        present = false,
        status = "",
        pair_count = 0,
        candidate_count = 0,
        base_objective = NaN,
        best_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        best_up_gpoint = 0,
        best_down_gpoint = 0,
        best_step = NaN,
        best_toa_regressed = false,
        best_surface_regressed = false,
        any_pareto_safe = false,
        best_safe_objective = NaN,
    )
    text = read(REDUCED_RETAINED_QUADRATURE_PAIR_PARETO_SCAN_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        pair_count = json_int_field(text, "pair_count"),
        candidate_count = json_int_field(text, "candidate_count"),
        base_objective = json_number_field(text, "base_objective"),
        best_objective = json_number_field(text, "best_objective"),
        best_objective_reduction =
            json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        best_up_gpoint = json_int_field(text, "best_up_gpoint"),
        best_down_gpoint = json_int_field(text, "best_down_gpoint"),
        best_step = json_number_field(text, "best_step"),
        best_toa_regressed = occursin("\"best_toa_regressed\": true", text),
        best_surface_regressed =
            occursin("\"best_surface_regressed\": true", text),
        any_pareto_safe = occursin("\"any_pareto_safe\": true", text),
        best_safe_objective = json_number_field(text, "best_safe_objective"),
    )
end

function retained_quadrature_linearized_optimizer_summary()
    isfile(REDUCED_RETAINED_QUADRATURE_LINEARIZED_OPTIMIZER_JSON) || return (
        present = false,
        status = "",
        residual_mode = "",
        basis_count = 0,
        base_objective = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        any_pareto_safe = false,
        accepted = false,
    )
    text = read(REDUCED_RETAINED_QUADRATURE_LINEARIZED_OPTIMIZER_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        residual_mode = json_string_field(text, "residual_mode"),
        basis_count = json_int_field(text, "basis_count"),
        base_objective = json_number_field(text, "base_objective"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        any_pareto_safe = occursin("\"any_pareto_safe\": true", text),
        accepted = occursin("\"accepted\": true", text),
    )
end

function retained_current_quadrature_linearized_optimizer_summary()
    isfile(REDUCED_RETAINED_CURRENT_QUADRATURE_LINEARIZED_OPTIMIZER_JSON) || return (
        present = false,
        status = "",
        residual_mode = "",
        basis_count = 0,
        surface_cap_w_m2 = NaN,
        toa_tolerance_w_m2 = NaN,
        base_objective = NaN,
        base_worst_toa_forcing_error_w_m2 = NaN,
        base_worst_surface_forcing_error_w_m2 = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        accepted_objective = NaN,
        accepted_objective_reduction = NaN,
        accepted_worst_toa_forcing_error_w_m2 = NaN,
        accepted_worst_surface_forcing_error_w_m2 = NaN,
        accepted = false,
    )
    text = read(REDUCED_RETAINED_CURRENT_QUADRATURE_LINEARIZED_OPTIMIZER_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        residual_mode = json_string_field(text, "residual_mode"),
        basis_count = json_int_field(text, "basis_count"),
        surface_cap_w_m2 = json_number_field(text, "surface_cap_w_m2"),
        toa_tolerance_w_m2 = json_number_field(text, "toa_tolerance_w_m2"),
        base_objective = json_number_field(text, "base_objective"),
        base_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "base_worst_toa_forcing_error_w_m2"),
        base_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "base_worst_surface_forcing_error_w_m2"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        accepted_objective = json_number_field(text, "accepted_objective"),
        accepted_objective_reduction =
            json_number_field(text, "accepted_objective_reduction"),
        accepted_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "accepted_worst_toa_forcing_error_w_m2"),
        accepted_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "accepted_worst_surface_forcing_error_w_m2"),
        accepted = occursin("\"accepted\": true", text),
    )
end

function retained_current_bounded_table_optimizer_summary()
    isfile(REDUCED_RETAINED_CURRENT_BOUNDED_TABLE_OPTIMIZER_JSON) || return (
        present = false,
        status = "",
        residual_mode = "",
        candidate_count = 0,
        surface_cap_w_m2 = NaN,
        toa_tolerance_w_m2 = NaN,
        min_objective_reduction = NaN,
        base_objective = NaN,
        base_worst_toa_forcing_error_w_m2 = NaN,
        base_worst_surface_forcing_error_w_m2 = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        accepted_objective = NaN,
        accepted_objective_reduction = NaN,
        accepted_worst_toa_forcing_error_w_m2 = NaN,
        accepted_worst_surface_forcing_error_w_m2 = NaN,
        accepted = false,
        accepted_move_count = 0,
    )
    text = read(REDUCED_RETAINED_CURRENT_BOUNDED_TABLE_OPTIMIZER_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        residual_mode = json_string_field(text, "residual_mode"),
        candidate_count = json_int_field(text, "candidate_count"),
        surface_cap_w_m2 = json_number_field(text, "surface_cap_w_m2"),
        toa_tolerance_w_m2 = json_number_field(text, "toa_tolerance_w_m2"),
        min_objective_reduction = json_number_field(text, "min_objective_reduction"),
        base_objective = json_number_field(text, "base_objective"),
        base_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "base_worst_toa_forcing_error_w_m2"),
        base_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "base_worst_surface_forcing_error_w_m2"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        accepted_objective = json_number_field(text, "accepted_objective"),
        accepted_objective_reduction =
            json_number_field(text, "accepted_objective_reduction"),
        accepted_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "accepted_worst_toa_forcing_error_w_m2"),
        accepted_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "accepted_worst_surface_forcing_error_w_m2"),
        accepted = occursin("\"accepted\": true", text),
        accepted_move_count = json_int_field(text, "accepted_move_count"),
    )
end

function retained_current_heating_profile_optimizer_summary()
    isfile(REDUCED_RETAINED_CURRENT_HEATING_PROFILE_OPTIMIZER_JSON) || return (
        present = false,
        status = "",
        residual_mode = "",
        candidate_count = 0,
        surface_cap_w_m2 = NaN,
        toa_tolerance_w_m2 = NaN,
        min_objective_reduction = NaN,
        base_objective = NaN,
        base_worst_toa_forcing_error_w_m2 = NaN,
        base_worst_surface_forcing_error_w_m2 = NaN,
        base_worst_heating_rate_rmse_k_day = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        best_worst_heating_rate_rmse_k_day = NaN,
        accepted_objective = NaN,
        accepted_objective_reduction = NaN,
        accepted_worst_toa_forcing_error_w_m2 = NaN,
        accepted_worst_surface_forcing_error_w_m2 = NaN,
        accepted_worst_heating_rate_rmse_k_day = NaN,
        accepted = false,
        accepted_move_count = 0,
    )
    text = read(REDUCED_RETAINED_CURRENT_HEATING_PROFILE_OPTIMIZER_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        residual_mode = json_string_field(text, "residual_mode"),
        candidate_count = json_int_field(text, "candidate_count"),
        surface_cap_w_m2 = json_number_field(text, "surface_cap_w_m2"),
        toa_tolerance_w_m2 = json_number_field(text, "toa_tolerance_w_m2"),
        min_objective_reduction = json_number_field(text, "min_objective_reduction"),
        base_objective = json_number_field(text, "base_objective"),
        base_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "base_worst_toa_forcing_error_w_m2"),
        base_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "base_worst_surface_forcing_error_w_m2"),
        base_worst_heating_rate_rmse_k_day =
            json_number_field(text, "base_worst_heating_rate_rmse_k_day"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        best_worst_heating_rate_rmse_k_day =
            json_number_field(text, "best_worst_heating_rate_rmse_k_day"),
        accepted_objective = json_number_field(text, "accepted_objective"),
        accepted_objective_reduction =
            json_number_field(text, "accepted_objective_reduction"),
        accepted_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "accepted_worst_toa_forcing_error_w_m2"),
        accepted_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "accepted_worst_surface_forcing_error_w_m2"),
        accepted_worst_heating_rate_rmse_k_day =
            json_number_field(text, "accepted_worst_heating_rate_rmse_k_day"),
        accepted = occursin("\"accepted\": true", text),
        accepted_move_count = json_int_field(text, "accepted_move_count"),
    )
end

function retained_current_joint_heating_optimizer_summary()
    isfile(REDUCED_RETAINED_CURRENT_JOINT_HEATING_OPTIMIZER_JSON) || return (
        present = false,
        status = "",
        residual_mode = "",
        basis = "",
        logit_basis_count = 0,
        table_candidate_count = 0,
        basis_count = 0,
        surface_cap_w_m2 = NaN,
        toa_tolerance_w_m2 = NaN,
        min_objective_reduction = NaN,
        base_objective = NaN,
        base_worst_toa_forcing_error_w_m2 = NaN,
        base_worst_surface_forcing_error_w_m2 = NaN,
        base_worst_heating_rate_rmse_k_day = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        best_worst_heating_rate_rmse_k_day = NaN,
        accepted_objective = NaN,
        accepted_objective_reduction = NaN,
        accepted_worst_toa_forcing_error_w_m2 = NaN,
        accepted_worst_surface_forcing_error_w_m2 = NaN,
        accepted_worst_heating_rate_rmse_k_day = NaN,
        accepted = false,
        accepted_table_move_count = 0,
    )
    text = read(REDUCED_RETAINED_CURRENT_JOINT_HEATING_OPTIMIZER_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        residual_mode = json_string_field(text, "residual_mode"),
        basis = json_string_field(text, "basis"),
        logit_basis_count = json_int_field(text, "logit_basis_count"),
        table_candidate_count = json_int_field(text, "table_candidate_count"),
        basis_count = json_int_field(text, "basis_count"),
        surface_cap_w_m2 = json_number_field(text, "surface_cap_w_m2"),
        toa_tolerance_w_m2 = json_number_field(text, "toa_tolerance_w_m2"),
        min_objective_reduction = json_number_field(text, "min_objective_reduction"),
        base_objective = json_number_field(text, "base_objective"),
        base_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "base_worst_toa_forcing_error_w_m2"),
        base_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "base_worst_surface_forcing_error_w_m2"),
        base_worst_heating_rate_rmse_k_day =
            json_number_field(text, "base_worst_heating_rate_rmse_k_day"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        best_worst_heating_rate_rmse_k_day =
            json_number_field(text, "best_worst_heating_rate_rmse_k_day"),
        accepted_objective = json_number_field(text, "accepted_objective"),
        accepted_objective_reduction =
            json_number_field(text, "accepted_objective_reduction"),
        accepted_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "accepted_worst_toa_forcing_error_w_m2"),
        accepted_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "accepted_worst_surface_forcing_error_w_m2"),
        accepted_worst_heating_rate_rmse_k_day =
            json_number_field(text, "accepted_worst_heating_rate_rmse_k_day"),
        accepted = occursin("\"accepted\": true", text),
        accepted_table_move_count = json_int_field(text, "accepted_table_move_count"),
    )
end

function retained_current_component_scale_optimizer_summary()
    retained_current_component_scale_optimizer_summary(
        REDUCED_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER_JSON,
    )
end

function retained_current_component_scale_optimizer2_summary()
    retained_current_component_scale_optimizer_summary(
        REDUCED_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER2_JSON,
    )
end

function retained_current_component_scale_optimizer3_summary()
    retained_current_component_scale_optimizer_summary(
        REDUCED_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER3_JSON,
    )
end

function retained_current_component_scale_optimizer4_summary()
    retained_current_component_scale_optimizer_summary(
        REDUCED_RETAINED_CURRENT_COMPONENT_SCALE_OPTIMIZER4_JSON,
    )
end

function retained_current_pressure_component_optimizer_summary()
    retained_current_component_scale_optimizer_summary(
        REDUCED_RETAINED_CURRENT_PRESSURE_COMPONENT_OPTIMIZER_JSON,
    )
end

function retained_current_pressure_component_scan_summary()
    retained_current_pressure_component_scan_summary(
        REDUCED_RETAINED_CURRENT_PRESSURE_COMPONENT_SCAN_JSON,
    )
end

function retained_current_pressure_component_rayleigh_scan_summary()
    retained_current_pressure_component_scan_summary(
        REDUCED_RETAINED_CURRENT_PRESSURE_COMPONENT_RAYLEIGH_SCAN_JSON,
    )
end

function retained_current_pressure_component_surface_guard_scan_summary()
    retained_current_pressure_component_scan_summary(
        REDUCED_RETAINED_CURRENT_PRESSURE_COMPONENT_SURFACE_GUARD_SCAN_JSON,
    )
end

function retained_current_gas_pressure_component_scan_summary()
    retained_current_pressure_component_scan_summary(
        REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_SCAN_JSON,
    )
end

function retained_current_gas_pressure_component_continuation_scan_summary()
    retained_current_pressure_component_scan_summary(
        REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION_SCAN_JSON,
    )
end

function retained_current_gas_pressure_component_continuation2_scan_summary()
    retained_current_pressure_component_scan_summary(
        REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION2_SCAN_JSON,
    )
end

function retained_current_gas_pressure_component_continuation3_scan_summary()
    retained_current_pressure_component_scan_summary(
        REDUCED_RETAINED_CURRENT_GAS_PRESSURE_COMPONENT_CONTINUATION3_SCAN_JSON,
    )
end

function retained_current_pressure_component_scan_summary(path)
    isfile(path) || return (
        present = false,
        status = "",
        residual_mode = "",
        basis = "",
        include_rayleigh = false,
        static_gas_split = false,
        heating_weight = 1.0,
        boundary_weight = 1.0,
        surface_cap_w_m2 = NaN,
        toa_tolerance_w_m2 = NaN,
        min_objective_reduction = NaN,
        base_objective = NaN,
        base_worst_toa_forcing_error_w_m2 = NaN,
        base_worst_surface_forcing_error_w_m2 = NaN,
        base_worst_heating_rate_rmse_k_day = NaN,
        selected_partition = "",
        selected_pressure_band_count = 0,
        selected_basis_count = 0,
        selected_accepted_move_count = 0,
        selected_objective = NaN,
        selected_worst_toa_forcing_error_w_m2 = NaN,
        selected_worst_surface_forcing_error_w_m2 = NaN,
        selected_worst_heating_rate_rmse_k_day = NaN,
        accepted = false,
    )
    text = read(path, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        residual_mode = json_string_field(text, "residual_mode"),
        basis = json_string_field(text, "basis"),
        include_rayleigh = occursin("\"include_rayleigh\": true", text),
        static_gas_split = occursin("\"static_gas_split\": true", text),
        heating_weight = json_number_field_or(text, "heating_weight", 1.0),
        boundary_weight = json_number_field_or(text, "boundary_weight", 1.0),
        surface_cap_w_m2 = json_number_field(text, "surface_cap_w_m2"),
        toa_tolerance_w_m2 = json_number_field(text, "toa_tolerance_w_m2"),
        min_objective_reduction = json_number_field(text, "min_objective_reduction"),
        base_objective = json_number_field(text, "base_objective"),
        base_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "base_worst_toa_forcing_error_w_m2"),
        base_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "base_worst_surface_forcing_error_w_m2"),
        base_worst_heating_rate_rmse_k_day =
            json_number_field(text, "base_worst_heating_rate_rmse_k_day"),
        selected_partition = json_string_field(text, "selected_partition"),
        selected_pressure_band_count =
            json_int_field(text, "selected_pressure_band_count"),
        selected_basis_count = json_int_field(text, "selected_basis_count"),
        selected_accepted_move_count =
            json_int_field(text, "selected_accepted_move_count"),
        selected_objective = json_number_field(text, "selected_objective"),
        selected_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "selected_worst_toa_forcing_error_w_m2"),
        selected_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "selected_worst_surface_forcing_error_w_m2"),
        selected_worst_heating_rate_rmse_k_day =
            json_number_field(text, "selected_worst_heating_rate_rmse_k_day"),
        accepted = occursin("\"status\": \"current_pressure_component_scan_improved\"",
                            text),
    )
end

function retained_current_component_scale_optimizer_summary(path)
    isfile(path) || return (
        present = false,
        status = "",
        residual_mode = "",
        basis = "",
        basis_count = 0,
        pressure_band_count = 0,
        surface_cap_w_m2 = NaN,
        toa_tolerance_w_m2 = NaN,
        min_objective_reduction = NaN,
        base_objective = NaN,
        base_worst_toa_forcing_error_w_m2 = NaN,
        base_worst_surface_forcing_error_w_m2 = NaN,
        base_worst_heating_rate_rmse_k_day = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        best_worst_heating_rate_rmse_k_day = NaN,
        accepted_objective = NaN,
        accepted_objective_reduction = NaN,
        accepted_worst_toa_forcing_error_w_m2 = NaN,
        accepted_worst_surface_forcing_error_w_m2 = NaN,
        accepted_worst_heating_rate_rmse_k_day = NaN,
        accepted = false,
    )
    text = read(path, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        residual_mode = json_string_field(text, "residual_mode"),
        basis = json_string_field(text, "basis"),
        basis_count = json_int_field(text, "basis_count"),
        pressure_band_count = occursin("\"pressure_band_count\"", text) ?
                              json_int_field(text, "pressure_band_count") : 0,
        surface_cap_w_m2 = json_number_field(text, "surface_cap_w_m2"),
        toa_tolerance_w_m2 = json_number_field(text, "toa_tolerance_w_m2"),
        min_objective_reduction = json_number_field(text, "min_objective_reduction"),
        base_objective = json_number_field(text, "base_objective"),
        base_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "base_worst_toa_forcing_error_w_m2"),
        base_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "base_worst_surface_forcing_error_w_m2"),
        base_worst_heating_rate_rmse_k_day =
            json_number_field(text, "base_worst_heating_rate_rmse_k_day"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        best_worst_heating_rate_rmse_k_day =
            json_number_field(text, "best_worst_heating_rate_rmse_k_day"),
        accepted_objective = json_number_field(text, "accepted_objective"),
        accepted_objective_reduction =
            json_number_field(text, "accepted_objective_reduction"),
        accepted_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "accepted_worst_toa_forcing_error_w_m2"),
        accepted_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "accepted_worst_surface_forcing_error_w_m2"),
        accepted_worst_heating_rate_rmse_k_day =
            json_number_field(text, "accepted_worst_heating_rate_rmse_k_day"),
        accepted = occursin("\"accepted\": true", text),
    )
end

function retained_capped_table_optimizer_summary()
    isfile(REDUCED_RETAINED_CAPPED_TABLE_OPTIMIZER_JSON) || return (
        present = false,
        status = "",
        candidate_scope = "",
        residual_mode = "",
        surface_cap_w_m2 = NaN,
        toa_tolerance_w_m2 = NaN,
        candidate_count = 0,
        base_objective = NaN,
        base_worst_toa_forcing_error_w_m2 = NaN,
        base_worst_surface_forcing_error_w_m2 = NaN,
        best_cap_safe_exact_objective = NaN,
        best_cap_safe_toa_forcing_error_w_m2 = NaN,
        best_cap_safe_surface_forcing_error_w_m2 = NaN,
        cap_safe_present = false,
        best_overall_exact_objective = NaN,
        best_overall_toa_forcing_error_w_m2 = NaN,
        best_overall_surface_forcing_error_w_m2 = NaN,
        best_unsafe_exact_objective = NaN,
        best_unsafe_toa_forcing_error_w_m2 = NaN,
        best_unsafe_surface_forcing_error_w_m2 = NaN,
        accepted = false,
        accepted_move_count = 0,
    )
    text = read(REDUCED_RETAINED_CAPPED_TABLE_OPTIMIZER_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        candidate_scope = json_string_field(text, "candidate_scope"),
        residual_mode = json_string_field(text, "residual_mode"),
        surface_cap_w_m2 = json_number_field(text, "surface_cap_w_m2"),
        toa_tolerance_w_m2 = json_number_field(text, "toa_tolerance_w_m2"),
        candidate_count = json_int_field(text, "candidate_count"),
        base_objective = json_number_field(text, "base_objective"),
        base_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "base_worst_toa_forcing_error_w_m2"),
        base_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "base_worst_surface_forcing_error_w_m2"),
        best_cap_safe_exact_objective =
            json_nullable_number_field(text, "best_cap_safe_exact_objective"),
        best_cap_safe_toa_forcing_error_w_m2 =
            json_nullable_number_field(text, "best_cap_safe_toa_forcing_error_w_m2"),
        best_cap_safe_surface_forcing_error_w_m2 =
            json_nullable_number_field(text, "best_cap_safe_surface_forcing_error_w_m2"),
        cap_safe_present = json_top_level_bool_field(text, "cap_safe_present"),
        best_overall_exact_objective =
            json_nullable_number_field(text, "best_overall_exact_objective"),
        best_overall_toa_forcing_error_w_m2 =
            json_nullable_number_field(text, "best_overall_toa_forcing_error_w_m2"),
        best_overall_surface_forcing_error_w_m2 =
            json_nullable_number_field(text, "best_overall_surface_forcing_error_w_m2"),
        best_unsafe_exact_objective =
            json_nullable_number_field(text, "best_unsafe_exact_objective"),
        best_unsafe_toa_forcing_error_w_m2 =
            json_nullable_number_field(text, "best_unsafe_toa_forcing_error_w_m2"),
        best_unsafe_surface_forcing_error_w_m2 =
            json_nullable_number_field(text, "best_unsafe_surface_forcing_error_w_m2"),
        accepted = json_top_level_bool_field(text, "accepted"),
        accepted_move_count = json_int_field(text, "accepted_move_count"),
    )
end

function retained_capped_table_continuation_summary()
    isfile(REDUCED_RETAINED_CAPPED_TABLE_CONTINUATION_JSON) || return (
        present = false,
        status = "",
        candidate_scope = "",
        residual_mode = "",
        surface_cap_w_m2 = NaN,
        toa_tolerance_w_m2 = NaN,
        base_capped_move_count = 0,
        candidate_count = 0,
        base_objective = NaN,
        base_worst_toa_forcing_error_w_m2 = NaN,
        base_worst_surface_forcing_error_w_m2 = NaN,
        best_cap_safe_exact_objective = NaN,
        best_cap_safe_toa_forcing_error_w_m2 = NaN,
        best_cap_safe_surface_forcing_error_w_m2 = NaN,
        cap_safe_present = false,
        best_overall_exact_objective = NaN,
        best_overall_toa_forcing_error_w_m2 = NaN,
        best_overall_surface_forcing_error_w_m2 = NaN,
        best_unsafe_exact_objective = NaN,
        best_unsafe_toa_forcing_error_w_m2 = NaN,
        best_unsafe_surface_forcing_error_w_m2 = NaN,
        accepted = false,
        accepted_move_count = 0,
    )
    text = read(REDUCED_RETAINED_CAPPED_TABLE_CONTINUATION_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        candidate_scope = json_string_field(text, "candidate_scope"),
        residual_mode = json_string_field(text, "residual_mode"),
        surface_cap_w_m2 = json_number_field(text, "surface_cap_w_m2"),
        toa_tolerance_w_m2 = json_number_field(text, "toa_tolerance_w_m2"),
        base_capped_move_count = json_int_field(text, "base_capped_move_count"),
        candidate_count = json_int_field(text, "candidate_count"),
        base_objective = json_number_field(text, "base_objective"),
        base_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "base_worst_toa_forcing_error_w_m2"),
        base_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "base_worst_surface_forcing_error_w_m2"),
        best_cap_safe_exact_objective =
            json_nullable_number_field(text, "best_cap_safe_exact_objective"),
        best_cap_safe_toa_forcing_error_w_m2 =
            json_nullable_number_field(text, "best_cap_safe_toa_forcing_error_w_m2"),
        best_cap_safe_surface_forcing_error_w_m2 =
            json_nullable_number_field(text, "best_cap_safe_surface_forcing_error_w_m2"),
        cap_safe_present = json_top_level_bool_field(text, "cap_safe_present"),
        best_overall_exact_objective =
            json_nullable_number_field(text, "best_overall_exact_objective"),
        best_overall_toa_forcing_error_w_m2 =
            json_nullable_number_field(text, "best_overall_toa_forcing_error_w_m2"),
        best_overall_surface_forcing_error_w_m2 =
            json_nullable_number_field(text, "best_overall_surface_forcing_error_w_m2"),
        best_unsafe_exact_objective =
            json_nullable_number_field(text, "best_unsafe_exact_objective"),
        best_unsafe_toa_forcing_error_w_m2 =
            json_nullable_number_field(text, "best_unsafe_toa_forcing_error_w_m2"),
        best_unsafe_surface_forcing_error_w_m2 =
            json_nullable_number_field(text, "best_unsafe_surface_forcing_error_w_m2"),
        accepted = json_top_level_bool_field(text, "accepted"),
        accepted_move_count = json_int_field(text, "accepted_move_count"),
    )
end

function retained_post_capped_weight_refit_summary()
    isfile(REDUCED_RETAINED_POST_CAPPED_WEIGHT_REFIT_JSON) || return (
        present = false,
        status = "",
        iterations = 0,
        base_objective = NaN,
        final_objective = NaN,
        refit_objective = NaN,
        objective_reduction = NaN,
        base_worst_toa_forcing_error_w_m2 = NaN,
        base_worst_surface_forcing_error_w_m2 = NaN,
        refit_worst_toa_forcing_error_w_m2 = NaN,
        refit_worst_surface_forcing_error_w_m2 = NaN,
        final_worst_toa_forcing_error_w_m2 = NaN,
        final_worst_surface_forcing_error_w_m2 = NaN,
        accepted = false,
        max_abs_weight_delta = NaN,
    )
    text = read(REDUCED_RETAINED_POST_CAPPED_WEIGHT_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        iterations = json_int_field(text, "iterations"),
        base_objective = json_number_field(text, "base_objective"),
        final_objective = json_number_field(text, "final_objective"),
        refit_objective = json_number_field(text, "refit_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        base_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "base_worst_toa_forcing_error_w_m2"),
        base_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "base_worst_surface_forcing_error_w_m2"),
        refit_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "refit_worst_toa_forcing_error_w_m2"),
        refit_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "refit_worst_surface_forcing_error_w_m2"),
        final_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "final_worst_toa_forcing_error_w_m2"),
        final_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "final_worst_surface_forcing_error_w_m2"),
        accepted = json_top_level_bool_field(text, "accepted"),
        max_abs_weight_delta = json_number_field(text, "max_abs_weight_delta"),
    )
end

function retained_post_weight_surface_table_refit_summary()
    isfile(REDUCED_RETAINED_POST_WEIGHT_SURFACE_TABLE_REFIT_JSON) || return (
        present = false,
        status = "",
        residual_mode = "",
        candidate_count = 0,
        probe_step = NaN,
        max_log_scale = NaN,
        base_objective = NaN,
        base_worst_toa_forcing_error_w_m2 = NaN,
        base_worst_surface_forcing_error_w_m2 = NaN,
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        accepted = false,
        accepted_objective = NaN,
        accepted_objective_reduction = NaN,
        accepted_worst_toa_forcing_error_w_m2 = NaN,
        accepted_worst_surface_forcing_error_w_m2 = NaN,
        accepted_move_count = 0,
    )
    text = read(REDUCED_RETAINED_POST_WEIGHT_SURFACE_TABLE_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        residual_mode = json_string_field(text, "residual_mode"),
        candidate_count = json_int_field(text, "candidate_count"),
        probe_step = json_number_field(text, "probe_step"),
        max_log_scale = json_number_field(text, "max_log_scale"),
        base_objective = json_number_field(text, "base_objective"),
        base_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "base_worst_toa_forcing_error_w_m2"),
        base_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "base_worst_surface_forcing_error_w_m2"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        accepted = json_top_level_bool_field(text, "accepted"),
        accepted_objective = json_number_field(text, "accepted_objective"),
        accepted_objective_reduction =
            json_number_field(text, "accepted_objective_reduction"),
        accepted_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "accepted_worst_toa_forcing_error_w_m2"),
        accepted_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "accepted_worst_surface_forcing_error_w_m2"),
        accepted_move_count = json_int_field(text, "accepted_move_count"),
    )
end

function retained_post_weight_bounded_weight_refit_summary()
    isfile(REDUCED_RETAINED_POST_WEIGHT_BOUNDED_WEIGHT_REFIT_JSON) || return (
        present = false,
        status = "",
        iterations = 0,
        surface_cap_w_m2 = NaN,
        toa_tolerance_w_m2 = NaN,
        base_objective = NaN,
        refit_objective = NaN,
        objective_reduction = NaN,
        base_worst_toa_forcing_error_w_m2 = NaN,
        base_worst_surface_forcing_error_w_m2 = NaN,
        refit_worst_toa_forcing_error_w_m2 = NaN,
        refit_worst_surface_forcing_error_w_m2 = NaN,
        accepted = false,
        max_abs_weight_delta = NaN,
    )
    text = read(REDUCED_RETAINED_POST_WEIGHT_BOUNDED_WEIGHT_REFIT_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        iterations = json_int_field(text, "iterations"),
        surface_cap_w_m2 = json_number_field(text, "surface_cap_w_m2"),
        toa_tolerance_w_m2 = json_number_field(text, "toa_tolerance_w_m2"),
        base_objective = json_number_field(text, "base_objective"),
        refit_objective = json_number_field(text, "refit_objective"),
        objective_reduction = json_number_field(text, "objective_reduction"),
        base_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "base_worst_toa_forcing_error_w_m2"),
        base_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "base_worst_surface_forcing_error_w_m2"),
        refit_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "refit_worst_toa_forcing_error_w_m2"),
        refit_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "refit_worst_surface_forcing_error_w_m2"),
        accepted = json_top_level_bool_field(text, "accepted"),
        max_abs_weight_delta = json_number_field(text, "max_abs_weight_delta"),
    )
end

function retained_table_coordinate_pareto_scan_summary()
    isfile(REDUCED_RETAINED_TABLE_COORDINATE_PARETO_SCAN_JSON) || return (
        present = false,
        status = "",
        candidate_count = 0,
        trial_count = 0,
        base_objective = NaN,
        best_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        best_component = "",
        best_gpoint = 0,
        best_step = NaN,
        best_direction = "",
        best_toa_regressed = false,
        best_surface_regressed = false,
        any_pareto_safe = false,
        best_safe_objective = NaN,
    )
    text = read(REDUCED_RETAINED_TABLE_COORDINATE_PARETO_SCAN_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        candidate_count = json_int_field(text, "candidate_count"),
        trial_count = json_int_field(text, "trial_count"),
        base_objective = json_number_field(text, "base_objective"),
        best_objective = json_number_field(text, "best_objective"),
        best_objective_reduction =
            json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        best_component = json_string_field(text, "best_component"),
        best_gpoint = json_int_field(text, "best_gpoint"),
        best_step = json_number_field(text, "best_step"),
        best_direction = json_string_field(text, "best_direction"),
        best_toa_regressed = occursin("\"best_toa_regressed\": true", text),
        best_surface_regressed =
            occursin("\"best_surface_regressed\": true", text),
        any_pareto_safe = occursin("\"any_pareto_safe\": true", text),
        best_safe_objective = json_number_field(text, "best_safe_objective"),
    )
end

function retained_objective_probe_expansion_summary(path)
    isfile(path) || return (
        present = false,
        status = "",
        config_count = 0,
        best_label = "",
        best_exact_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        any_pareto_safe = false,
        any_accepted = false,
    )
    text = read(path, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        config_count = json_int_field(text, "config_count"),
        best_label = json_string_field(text, "best_label"),
        best_exact_objective = json_number_field(text, "best_exact_objective"),
        best_objective_reduction =
            json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        any_pareto_safe = occursin("\"pareto_safe\": true", text),
        any_accepted = occursin("\"any_accepted\": true", text),
    )
end

retained_objective_probe_expansion_summary() =
    retained_objective_probe_expansion_summary(REDUCED_RETAINED_OBJECTIVE_PROBE_EXPANSION_JSON)

retained_objective_probe_expansion2_summary() =
    retained_objective_probe_expansion_summary(REDUCED_RETAINED_OBJECTIVE_PROBE_EXPANSION2_JSON)

retained_objective_probe_expansion3_summary() =
    retained_objective_probe_expansion_summary(REDUCED_RETAINED_OBJECTIVE_PROBE_EXPANSION3_JSON)

retained_objective_probe_expansion4_summary() =
    retained_objective_probe_expansion_summary(REDUCED_RETAINED_OBJECTIVE_PROBE_EXPANSION4_JSON)

retained_surface_probe_expansion_summary() =
    retained_objective_probe_expansion_summary(REDUCED_RETAINED_SURFACE_PROBE_EXPANSION_JSON)

retained_surface_probe_expansion2_summary() =
    retained_objective_probe_expansion_summary(REDUCED_RETAINED_SURFACE_PROBE_EXPANSION2_JSON)

retained_surface_probe_expansion3_summary() =
    retained_objective_probe_expansion_summary(REDUCED_RETAINED_SURFACE_PROBE_EXPANSION3_JSON)

retained_boundary_probe_expansion_summary() =
    retained_objective_probe_expansion_summary(REDUCED_RETAINED_BOUNDARY_PROBE_EXPANSION_JSON)

retained_toa_probe_expansion_summary() =
    retained_objective_probe_expansion_summary(REDUCED_RETAINED_TOA_PROBE_EXPANSION_JSON)

function boundary_table_triple_coordinate_scan_summary()
    isfile(REDUCED_BOUNDARY_TABLE_TRIPLE_COORDINATE_SCAN_JSON) || return (
        present = false,
        status = "",
        single_trial_count = 0,
        selected_single_count = 0,
        triple_trial_count = 0,
        base_objective = NaN,
        best_objective = NaN,
        best_objective_reduction = NaN,
        best_worst_toa_forcing_error_w_m2 = NaN,
        best_worst_surface_forcing_error_w_m2 = NaN,
        accepted = false,
    )
    text = read(REDUCED_BOUNDARY_TABLE_TRIPLE_COORDINATE_SCAN_JSON, String)
    return (
        present = true,
        status = json_string_field(text, "status"),
        single_trial_count = json_int_field(text, "single_trial_count"),
        selected_single_count = json_int_field(text, "selected_single_count"),
        triple_trial_count = json_int_field(text, "triple_trial_count"),
        base_objective = json_number_field(text, "base_objective"),
        best_objective = json_number_field(text, "best_objective"),
        best_objective_reduction = json_number_field(text, "best_objective_reduction"),
        best_worst_toa_forcing_error_w_m2 =
            json_number_field(text, "best_worst_toa_forcing_error_w_m2"),
        best_worst_surface_forcing_error_w_m2 =
            json_number_field(text, "best_worst_surface_forcing_error_w_m2"),
        accepted = occursin("\"accepted\": true", text),
    )
end

function markdown_report(result)
    lines = String[
        "# Reduced ecCKD Gap Report",
        "",
        "Status: **$(result.status)**",
        "",
        "Reference scope: clean official ecCKD tropical and RCEMIP-style cloudless/no-aerosol cases.",
        "",
        "Hard forcing threshold: `$(result.hard_forcing_threshold_w_m2)` W m^-2.",
        "",
        "| Category | Method | Passed | TOA forcing error | Surface forcing error |",
        "|---|---|---:|---:|---:|",
    ]
    for row in result.rows
        category = row.ng_sw == 32 ? "full shortwave" : "reduced shortwave"
        push!(lines, "| $(category) | $(row.method) | $(row.passed) | $(row.toa_forcing_error_w_m2) W m^-2 | $(row.surface_forcing_error_w_m2) W m^-2 |")
    end
    append!(lines, [
        "",
        "## Conclusion",
        "",
        result.conclusion,
        "",
        "## Optimization Preflight",
        "",
        "- present: $(result.optimization.present)",
        "- acceptance gap status: `$(result.optimization.acceptance_gap_status)`",
        "- final objective / target: $(result.optimization.final_objective_target_ratio)",
        "- best local block: `$(result.optimization.best_block)`",
        "- topology scan status: `$(result.optimization.topology_scan_status)`",
        "- topology candidates: $(result.optimization.topology_candidate_count)",
        "- best topology forcing lower bound: $(result.optimization.best_topology_forcing_objective_lower_bound)",
        "- best topology method: $(result.optimization.best_topology_method)",
        "- final worst case: `$(result.optimization.final_worst_case)`",
        "- final worst metric: `$(result.optimization.final_worst_metric)`",
        "- final worst value: $(result.optimization.final_worst_value)",
        "- final worst threshold: $(result.optimization.final_worst_threshold)",
        "- targeted worst-metric candidates: $(result.optimization.targeted_candidate_count)",
        "- targeted worst-metric objective: $(result.optimization.targeted_best_objective)",
        "- targeted move accepted: $(result.optimization.targeted_accepted)",
        "- separated-component candidates: $(result.optimization.separated_candidate_count)",
        "- separated-component target objective: $(result.optimization.separated_best_objective)",
        "- separated-component move accepted: $(result.optimization.separated_accepted)",
        "- next optimizer required absolute reduction: $(result.optimization.next_optimizer_required_absolute_reduction)",
        "- next optimizer required relative reduction: $(result.optimization.next_optimizer_required_relative_reduction)",
        "- next optimizer parameterization: $(result.optimization.next_optimizer_recommended_parameterization)",
        "- warm-start topology candidates: $(result.optimization.warm_topology_candidate_count)",
        "- warm-start topology best objective: $(result.optimization.warm_topology_best_objective)",
        "- warm-start topology improved: $(result.optimization.warm_topology_improved)",
        "- finite-difference coefficient-gradient candidates: $(result.optimization.finite_difference_candidate_count)",
        "- finite-difference coefficient-gradient best objective: $(result.optimization.finite_difference_best_objective)",
        "- finite-difference coefficient-gradient improved: $(result.optimization.finite_difference_improved)",
        "",
        "## Coefficient Continuation",
        "",
        "- present: $(result.coefficient_continuation.present)",
        "- status: `$(result.coefficient_continuation.status)`",
        "- initial objective: $(result.coefficient_continuation.initial_objective)",
        "- final objective: $(result.coefficient_continuation.final_objective)",
        "- final objective / target: $(result.coefficient_continuation.final_objective_target_ratio)",
        "- best start label: `$(result.coefficient_continuation.best_start_label)`",
        "- best start objective: $(result.coefficient_continuation.best_start_objective)",
        "- greedy checkpoint used: $(result.coefficient_continuation.greedy_checkpoint_used)",
        "- saved states evaluated: $(result.coefficient_continuation.saved_state_count)",
        "- worst case: `$(result.coefficient_continuation.worst_case)`",
        "- worst metric: `$(result.coefficient_continuation.worst_metric)`",
        "- worst value: $(result.coefficient_continuation.worst_value)",
        "- worst threshold: $(result.coefficient_continuation.worst_threshold)",
        "",
        "## Subset Search Artifact",
        "",
        "- present: $(result.subset_search.present)",
        "- status: `$(result.subset_search.status)`",
        "- weighted selected shortwave g-points: `$(join(result.subset_search.weighted_selected_shortwave_gpoints, ", "))`",
        "- pruned full-fit selected shortwave g-points: `$(join(result.subset_search.pruned_full_fit_selected_shortwave_gpoints, ", "))`",
        "- hard-gate max-norm selected shortwave g-points: `$(join(result.subset_search.hardgate_selected_shortwave_gpoints, ", "))`",
        "- fitted weights present: $(result.subset_search.selected_shortwave_weights_present)",
        "",
        "## Optical-Depth Fit Preflight",
        "",
        "- present: $(result.optical_depth_fit.present)",
        "- status: `$(result.optical_depth_fit.status)`",
        "- baseline RMSE: $(result.optical_depth_fit.baseline_rmse)",
        "- per-g fitted RMSE: $(result.optical_depth_fit.fitted_rmse)",
        "- component-fitted RMSE: $(result.optical_depth_fit.component_fitted_rmse)",
        "- component relative RMSE reduction: $(result.optical_depth_fit.component_relative_rmse_reduction)",
        "- baseline flux objective: $(result.optical_depth_fit.flux_baseline_objective)",
        "- per-g scaled flux objective: $(result.optical_depth_fit.flux_scaled_objective)",
        "- component-scaled flux objective: $(result.optical_depth_fit.flux_component_scaled_objective)",
        "- per-g scaled flux improved: $(result.optical_depth_fit.flux_scaled_improved)",
        "- component-scaled flux improved: $(result.optical_depth_fit.flux_component_scaled_improved)",
        "- coefficient-table raw LS optical-depth RMSE: $(result.optical_depth_fit.coefficient_table_fit_raw_optical_depth_rmse)",
        "- coefficient-table clipped-model optical-depth RMSE: $(result.optical_depth_fit.coefficient_table_fit_clipped_optical_depth_rmse)",
        "- physical projected table optical-depth RMSE: $(result.optical_depth_fit.coefficient_table_fit_physical_target_optical_depth_rmse)",
        "- physical projected table flux objective: $(result.optical_depth_fit.coefficient_table_fit_physical_target_flux_objective)",
        "- coefficient-table fit flux objective: $(result.optical_depth_fit.coefficient_table_fit_flux_objective)",
        "- coefficient-table fit flux improved: $(result.optical_depth_fit.coefficient_table_fit_flux_improved)",
        "- coefficient-table fit passed hard thresholds: $(result.optical_depth_fit.coefficient_table_fit_passed_hard_thresholds)",
        "",
        "## Size Weight Refit",
        "",
        "- present: $(result.size_weight_refit.present)",
        "- status: `$(result.size_weight_refit.status)`",
        "- any passed: $(result.size_weight_refit.any_passed)",
        "- best method: $(result.size_weight_refit.best_method)",
        "- best ng_sw: $(result.size_weight_refit.best_ng_sw)",
        "- best refit objective: $(result.size_weight_refit.best_refit_objective)",
        "- best TOA forcing error: $(result.size_weight_refit.best_toa_forcing_error)",
        "- best surface forcing error: $(result.size_weight_refit.best_surface_forcing_error)",
        "",
        "## Leave-One-Out Scan",
        "",
        "- present: $(result.leave_one_out_scan.present)",
        "- status: `$(result.leave_one_out_scan.status)`",
        "- candidates: $(result.leave_one_out_scan.candidate_count)",
        "- passes: $(result.leave_one_out_scan.pass_count)",
        "- best omitted g-point: $(result.leave_one_out_scan.best_omitted_gpoint)",
        "- best objective: $(result.leave_one_out_scan.best_objective)",
        "- best TOA forcing error: $(result.leave_one_out_scan.best_toa_forcing_error_w_m2)",
        "- best surface forcing error: $(result.leave_one_out_scan.best_surface_forcing_error_w_m2)",
        "- worst omitted g-point: $(result.leave_one_out_scan.worst_omitted_gpoint)",
        "- worst objective: $(result.leave_one_out_scan.worst_objective)",
        "- worst TOA forcing error: $(result.leave_one_out_scan.worst_toa_forcing_error_w_m2)",
        "- worst surface forcing error: $(result.leave_one_out_scan.worst_surface_forcing_error_w_m2)",
        "",
        "## Leave-One-Out Weight Refit",
        "",
        "- present: $(result.leave_one_out_weight_refit.present)",
        "- status: `$(result.leave_one_out_weight_refit.status)`",
        "- candidates: $(result.leave_one_out_weight_refit.candidate_count)",
        "- passes: $(result.leave_one_out_weight_refit.pass_count)",
        "- best omitted g-point: $(result.leave_one_out_weight_refit.best_omitted_gpoint)",
        "- best initial objective: $(result.leave_one_out_weight_refit.best_initial_objective)",
        "- best refit objective: $(result.leave_one_out_weight_refit.best_refit_objective)",
        "- best objective reduction: $(result.leave_one_out_weight_refit.best_objective_reduction)",
        "- best refit TOA forcing error: $(result.leave_one_out_weight_refit.best_refit_toa_forcing_error_w_m2)",
        "- best refit surface forcing error: $(result.leave_one_out_weight_refit.best_refit_surface_forcing_error_w_m2)",
        "- worst omitted g-point: $(result.leave_one_out_weight_refit.worst_omitted_gpoint)",
        "- worst refit objective: $(result.leave_one_out_weight_refit.worst_refit_objective)",
        "- worst refit TOA forcing error: $(result.leave_one_out_weight_refit.worst_refit_toa_forcing_error_w_m2)",
        "- worst refit surface forcing error: $(result.leave_one_out_weight_refit.worst_refit_surface_forcing_error_w_m2)",
        "",
        "## Importance-Guided Group Scan",
        "",
        "- present: $(result.importance_group_scan.present)",
        "- status: `$(result.importance_group_scan.status)`",
        "- importance source: `$(result.importance_group_scan.importance_source)`",
        "- grouping rule: $(result.importance_group_scan.grouping_rule)",
        "- candidates: $(result.importance_group_scan.candidate_count)",
        "- passes: $(result.importance_group_scan.pass_count)",
        "- best label: `$(result.importance_group_scan.best_label)`",
        "- best refit objective: $(result.importance_group_scan.best_refit_objective)",
        "- best TOA forcing error: $(result.importance_group_scan.best_toa_forcing_error_w_m2)",
        "- best surface forcing error: $(result.importance_group_scan.best_surface_forcing_error_w_m2)",
        "",
        "## Support-Swap Scan",
        "",
        "- present: $(result.support_swap_scan.present)",
        "- status: `$(result.support_swap_scan.status)`",
        "- seed count: $(result.support_swap_scan.seed_count)",
        "- exact candidates per seed: $(result.support_swap_scan.exact_top_n)",
        "- best objective: $(result.support_swap_scan.best_overall_objective)",
        "- best removed g-point: $(result.support_swap_scan.best_overall_removed_gpoint)",
        "- best added g-point: $(result.support_swap_scan.best_overall_added_gpoint)",
        "- best selected shortwave g-points: `$(join(result.support_swap_scan.best_overall_indices, ", "))`",
        "- passed hard thresholds: $(result.support_swap_scan.best_overall_passed_hard_thresholds)",
        "",
        "## Support-Swap Continuation Scan",
        "",
        "- present: $(result.support_swap_continuation_scan.present)",
        "- status: `$(result.support_swap_continuation_scan.status)`",
        "- exact candidates: $(result.support_swap_continuation_scan.exact_top_n)",
        "- seed objective: $(result.support_swap_continuation_scan.seed_exact_objective)",
        "- best objective: $(result.support_swap_continuation_scan.best_objective)",
        "- best objective reduction: $(result.support_swap_continuation_scan.best_objective_reduction)",
        "- best removed g-point: $(result.support_swap_continuation_scan.best_removed_gpoint)",
        "- best added g-point: $(result.support_swap_continuation_scan.best_added_gpoint)",
        "- best selected shortwave g-points: `$(join(result.support_swap_continuation_scan.best_indices, ", "))`",
        "- passed hard thresholds: $(result.support_swap_continuation_scan.best_passed_hard_thresholds)",
        "",
        "## Support Expansion Scan",
        "",
        "- present: $(result.support_expansion_scan.present)",
        "- status: `$(result.support_expansion_scan.status)`",
        "- seed count: $(result.support_expansion_scan.seed_count)",
        "- exact candidates per seed: $(result.support_expansion_scan.exact_top_n)",
        "- best objective: $(result.support_expansion_scan.best_overall_objective)",
        "- best shortwave g-point count: $(result.support_expansion_scan.best_overall_ng)",
        "- best added g-points: `$(join(result.support_expansion_scan.best_overall_added_gpoints, ", "))`",
        "- best selected shortwave g-points: `$(join(result.support_expansion_scan.best_overall_indices, ", "))`",
        "- passed hard thresholds: $(result.support_expansion_scan.best_overall_passed_hard_thresholds)",
        "",
        "## Support Expansion Refit Scan",
        "",
        "- present: $(result.support_expansion_refit_scan.present)",
        "- status: `$(result.support_expansion_refit_scan.status)`",
        "- iterations: $(result.support_expansion_refit_scan.iterations)",
        "- p-norm: $(result.support_expansion_refit_scan.pnorm)",
        "- candidates: $(result.support_expansion_refit_scan.candidate_count)",
        "- starts per candidate: $(result.support_expansion_refit_scan.start_count)",
        "- best label: `$(result.support_expansion_refit_scan.best_label)`",
        "- best objective: $(result.support_expansion_refit_scan.best_objective)",
        "- best start: `$(result.support_expansion_refit_scan.best_start_label)`",
        "- best shortwave g-point count: $(result.support_expansion_refit_scan.best_ng)",
        "- best added g-points: `$(join(result.support_expansion_refit_scan.best_added_gpoints, ", "))`",
        "- best selected shortwave g-points: `$(join(result.support_expansion_refit_scan.best_indices, ", "))`",
        "- passed hard thresholds: $(result.support_expansion_refit_scan.best_passed_hard_thresholds)",
        "",
        "## Random Support Search",
        "",
        "- present: $(result.random_support_search.present)",
        "- status: `$(result.random_support_search.status)`",
        "- RNG seed: $(result.random_support_search.rng_seed)",
        "- random seed count: $(result.random_support_search.random_seed_count)",
        "- candidates: $(result.random_support_search.candidate_count)",
        "- exact candidates: $(result.random_support_search.exact_top_n)",
        "- iterations: $(result.random_support_search.iterations)",
        "- p-norm: $(result.random_support_search.pnorm)",
        "- best label: `$(result.random_support_search.best_label)`",
        "- best objective: $(result.random_support_search.best_objective)",
        "- best selected shortwave g-points: `$(join(result.random_support_search.best_indices, ", "))`",
        "- best TOA forcing error: $(result.random_support_search.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing error: $(result.random_support_search.best_worst_surface_forcing_error_w_m2)",
        "- best heating RMSE: $(result.random_support_search.best_worst_heating_rate_rmse_k_day)",
        "- canonical seed objective: $(result.random_support_search.canonical_seed_objective)",
        "- subset-search hardgate seed objective: $(result.random_support_search.subset_hardgate_seed_objective)",
        "- passed hard thresholds: $(result.random_support_search.best_passed_hard_thresholds)",
        "",
        "## Current Metric Breakdown",
        "",
        "- present: $(result.current_metric_breakdown.present)",
        "- status: `$(result.current_metric_breakdown.status)`",
        "- hard objective: $(result.current_metric_breakdown.hard_objective)",
        "- worst case: `$(result.current_metric_breakdown.worst_case)`",
        "- worst variable: `$(result.current_metric_breakdown.worst_variable)`",
        "- worst metric: `$(result.current_metric_breakdown.worst_metric)`",
        "- worst value: $(result.current_metric_breakdown.worst_value)",
        "- worst threshold: $(result.current_metric_breakdown.worst_threshold)",
        "- second case: `$(result.current_metric_breakdown.second_case)`",
        "- second variable: `$(result.current_metric_breakdown.second_variable)`",
        "- second metric: `$(result.current_metric_breakdown.second_metric)`",
        "- second value: $(result.current_metric_breakdown.second_value)",
        "- second threshold: $(result.current_metric_breakdown.second_threshold)",
        "- second normalized: $(result.current_metric_breakdown.second_normalized_value)",
        "",
        "## Reduced Acceptance Decision",
        "",
        "- present: $(result.reduced_acceptance_decision.present)",
        "- status: `$(result.reduced_acceptance_decision.status)`",
        "- blocker: `$(result.reduced_acceptance_decision.blocker)`",
        "- objective target: $(result.reduced_acceptance_decision.objective_target)",
        "- current hard objective: $(result.reduced_acceptance_decision.current_hard_objective)",
        "- worst case: `$(result.reduced_acceptance_decision.worst_case)`",
        "- worst metric: `$(result.reduced_acceptance_decision.worst_metric)`",
        "- worst value: $(result.reduced_acceptance_decision.worst_value)",
        "- worst threshold: $(result.reduced_acceptance_decision.worst_threshold)",
        "- second case: `$(result.reduced_acceptance_decision.second_case)`",
        "- second metric: `$(result.reduced_acceptance_decision.second_metric)`",
        "- second normalized: $(result.reduced_acceptance_decision.second_normalized_value)",
        "- local support searches rejected: $(result.reduced_acceptance_decision.local_support_searches_rejected)",
        "- current chain required for best row: $(result.reduced_acceptance_decision.current_chain_required_for_best_row)",
        "- random-support best objective: $(result.reduced_acceptance_decision.random_support_best_objective)",
        "- bare canonical support objective: $(result.reduced_acceptance_decision.bare_canonical_support_objective)",
        "- recommended next decision: $(result.reduced_acceptance_decision.recommended_next_decision)",
        "- remaining options: $(join(result.reduced_acceptance_decision.remaining_options, "; "))",
        "",
        "## Pressure-Band Table Refinement Preflight",
        "",
        "- present: $(result.pressure_band_refinement.present)",
        "- status: `$(result.pressure_band_refinement.status)`",
        "- current objective: $(result.pressure_band_refinement.current_objective)",
        "- target case: `$(result.pressure_band_refinement.target_case)`",
        "- target metric: `$(result.pressure_band_refinement.target_metric)`",
        "- target metric objective: $(result.pressure_band_refinement.target_metric_objective)",
        "- candidates: $(result.pressure_band_refinement.candidate_count)",
        "- best target-metric objective: $(result.pressure_band_refinement.best_metric_objective)",
        "- best full objective: $(result.pressure_band_refinement.best_full_objective)",
        "- accepted: $(result.pressure_band_refinement.accepted)",
        "- iterative accepted moves: $(result.pressure_band_refinement.iterative_accepted_move_count)",
        "- iterative final objective: $(result.pressure_band_refinement.iterative_final_objective)",
        "- iterative objective reduction: $(result.pressure_band_refinement.iterative_objective_reduction)",
        "- iterative improved: $(result.pressure_band_refinement.iterative_improved)",
        "",
        "## Targeted Active-Entry Refinement",
        "",
        "- present: $(result.targeted_entry.present)",
        "- final objective: $(result.targeted_entry.final_objective)",
        "- objective reduction: $(result.targeted_entry.objective_reduction)",
        "- accepted moves: $(result.targeted_entry.accepted_move_count)",
        "- targeted candidates: $(result.targeted_entry.targeted_candidate_count)",
        "- iterations requested: $(result.targeted_entry.iterations_requested)",
        "",
        "## Global Active-Entry Refinement",
        "",
        "- present: $(result.global_entry.present)",
        "- final objective: $(result.global_entry.final_objective)",
        "- objective reduction: $(result.global_entry.objective_reduction)",
        "- accepted moves in latest window: $(result.global_entry.accepted_move_count)",
        "- cumulative active moves: $(result.global_entry.cumulative_active_move_count)",
        "- ranked candidates: $(result.global_entry.total_ranked_candidate_count)",
        "- candidate limit: $(result.global_entry.candidate_limit)",
        "- candidate offset: $(result.global_entry.candidate_offset)",
        "- iterations requested: $(result.global_entry.iterations_requested)",
        "",
        "## Global Block Active-Entry Refinement",
        "",
        "- present: $(result.global_block_entry.present)",
        "- final objective: $(result.global_block_entry.final_objective)",
        "- objective reduction: $(result.global_block_entry.objective_reduction)",
        "- accepted grouped moves: $(result.global_block_entry.accepted_move_count)",
        "- cumulative active moves: $(result.global_block_entry.cumulative_active_move_count)",
        "- group limit: $(result.global_block_entry.group_limit)",
        "- iterations requested: $(result.global_block_entry.iterations_requested)",
        "",
        "## Global Block Linearized Active-Entry Refit",
        "",
        "- present: $(result.global_block_linearized_entry.present)",
        "- basis count: $(result.global_block_linearized_entry.basis_count)",
        "- best ridge lambda: $(result.global_block_linearized_entry.best_ridge_lambda)",
        "- base objective: $(result.global_block_linearized_entry.base_objective)",
        "- candidate objective: $(result.global_block_linearized_entry.candidate_objective)",
        "- final objective: $(result.global_block_linearized_entry.final_objective)",
        "- objective reduction: $(result.global_block_linearized_entry.objective_reduction)",
        "- accepted: $(result.global_block_linearized_entry.accepted)",
        "- accepted moves: $(result.global_block_linearized_entry.accepted_move_count)",
        "- cumulative active moves: $(result.global_block_linearized_entry.cumulative_active_move_count)",
        "",
        "## Linearized Active-Entry Refit",
        "",
        "- present: $(result.linearized_entry.present)",
        "- fitted candidates: $(result.linearized_entry.fitted_candidate_count)",
        "- best ridge lambda: $(result.linearized_entry.best_ridge_lambda)",
        "- base objective: $(result.linearized_entry.base_objective)",
        "- candidate objective: $(result.linearized_entry.candidate_objective)",
        "- objective reduction: $(result.linearized_entry.objective_reduction)",
        "- accepted: $(result.linearized_entry.accepted)",
        "",
        "## Global Linearized Active-Entry Refit",
        "",
        "- present: $(result.global_linearized_entry.present)",
        "- fitted candidates: $(result.global_linearized_entry.fitted_candidate_count)",
        "- best ridge lambda: $(result.global_linearized_entry.best_ridge_lambda)",
        "- base objective: $(result.global_linearized_entry.base_objective)",
        "- candidate objective: $(result.global_linearized_entry.candidate_objective)",
        "- objective reduction: $(result.global_linearized_entry.objective_reduction)",
        "- accepted: $(result.global_linearized_entry.accepted)",
        "",
        "## Topology Slot Refit",
        "",
        "- present: $(result.topology_slot.present)",
        "- radius: $(result.topology_slot.radius)",
        "- candidates: $(result.topology_slot.candidate_count)",
        "- base objective: $(result.topology_slot.base_objective)",
        "- best objective: $(result.topology_slot.best_objective)",
        "- best improvement: $(result.topology_slot.best_improvement)",
        "- improved: $(result.topology_slot.improved)",
        "- best move: g$(result.topology_slot.best_removed_gpoint) -> g$(result.topology_slot.best_added_gpoint)",
        "",
        "## Post-Table Weight Refit",
        "",
        "- present: $(result.post_table_weight.present)",
        "- iterations: $(result.post_table_weight.iterations)",
        "- base objective: $(result.post_table_weight.base_objective)",
        "- refit objective: $(result.post_table_weight.refit_objective)",
        "- objective reduction: $(result.post_table_weight.objective_reduction)",
        "- accepted: $(result.post_table_weight.accepted)",
        "",
        "## Exact Weight Refit",
        "",
        "- present: $(result.exact_weight_refit.present)",
        "- iterations completed: $(result.exact_weight_refit.iterations_completed)",
        "- initial objective: $(result.exact_weight_refit.initial_objective)",
        "- final objective: $(result.exact_weight_refit.final_objective)",
        "- objective reduction: $(result.exact_weight_refit.objective_reduction)",
        "- accepted: $(result.exact_weight_refit.accepted)",
        "",
        "## Joint Weight/Block Refit",
        "",
        "- present: $(result.joint_weight_block_refit.present)",
        "- residual mode: $(result.joint_weight_block_refit.residual_mode)",
        "- basis count: $(result.joint_weight_block_refit.basis_count)",
        "- best ridge lambda: $(result.joint_weight_block_refit.best_ridge_lambda)",
        "- best direction: $(result.joint_weight_block_refit.best_direction)",
        "- base objective: $(result.joint_weight_block_refit.base_objective)",
        "- candidate objective: $(result.joint_weight_block_refit.candidate_objective)",
        "- final objective: $(result.joint_weight_block_refit.final_objective)",
        "- objective reduction: $(result.joint_weight_block_refit.objective_reduction)",
        "- accepted: $(result.joint_weight_block_refit.accepted)",
        "- accepted moves: $(result.joint_weight_block_refit.accepted_move_count)",
        "- cumulative active moves: $(result.joint_weight_block_refit.cumulative_active_move_count)",
        "",
        "## Boundary-Column Refinement",
        "",
        "- present: $(result.boundary_column_refinement.present)",
        "- target case: $(result.boundary_column_refinement.target_case)",
        "- target metric: $(result.boundary_column_refinement.target_metric)",
        "- target column: $(result.boundary_column_refinement.target_column)",
        "- target residual: $(result.boundary_column_refinement.target_residual_w_m2)",
        "- evaluated candidates: $(result.boundary_column_refinement.evaluated_candidate_count)",
        "- evaluated trials: $(result.boundary_column_refinement.evaluated_trial_count)",
        "- base objective: $(result.boundary_column_refinement.base_objective)",
        "- candidate objective: $(result.boundary_column_refinement.candidate_objective)",
        "- final objective: $(result.boundary_column_refinement.final_objective)",
        "- objective reduction: $(result.boundary_column_refinement.objective_reduction)",
        "- accepted: $(result.boundary_column_refinement.accepted)",
        "- accepted moves: $(result.boundary_column_refinement.accepted_move_count)",
        "- cumulative active moves: $(result.boundary_column_refinement.cumulative_active_move_count)",
        "",
        "## Slot-Blend Refinement",
        "",
        "- present: $(result.slot_blend_refinement.present)",
        "- radius: $(result.slot_blend_refinement.radius)",
        "- candidates: $(result.slot_blend_refinement.candidate_count)",
        "- evaluated trials: $(result.slot_blend_refinement.evaluated_trial_count)",
        "- base objective: $(result.slot_blend_refinement.base_objective)",
        "- candidate objective: $(result.slot_blend_refinement.candidate_objective)",
        "- final objective: $(result.slot_blend_refinement.final_objective)",
        "- objective reduction: $(result.slot_blend_refinement.objective_reduction)",
        "- accepted: $(result.slot_blend_refinement.accepted)",
        "- accepted blends: $(result.slot_blend_refinement.accepted_blend_count)",
        "- best move: g$(result.slot_blend_refinement.best_source_gpoint) -> g$(result.slot_blend_refinement.best_blend_gpoint)",
        "- best alpha: $(result.slot_blend_refinement.best_alpha)",
        "",
        "## Pair Slot-Blend Refinement",
        "",
        "- present: $(result.pair_slot_blend_refinement.present)",
        "- base blends: $(result.pair_slot_blend_refinement.base_blend_count)",
        "- ranked singles: $(result.pair_slot_blend_refinement.ranked_single_count)",
        "- evaluated pairs: $(result.pair_slot_blend_refinement.evaluated_pair_count)",
        "- base objective: $(result.pair_slot_blend_refinement.base_objective)",
        "- best single objective: $(result.pair_slot_blend_refinement.best_single_objective)",
        "- best pair objective: $(result.pair_slot_blend_refinement.best_pair_objective)",
        "- final objective: $(result.pair_slot_blend_refinement.final_objective)",
        "- objective reduction: $(result.pair_slot_blend_refinement.objective_reduction)",
        "- accepted: $(result.pair_slot_blend_refinement.accepted)",
        "- accepted blends: $(result.pair_slot_blend_refinement.accepted_blend_count)",
        "- total blends: $(result.pair_slot_blend_refinement.total_blend_count)",
        "",
        "## Slot-Blend Linearized Refit",
        "",
        "- present: $(result.slot_blend_linearized.present)",
        "- status: `$(result.slot_blend_linearized.status)`",
        "- base blends: $(result.slot_blend_linearized.base_blend_count)",
        "- candidates: $(result.slot_blend_linearized.candidate_count)",
        "- single trials: $(result.slot_blend_linearized.single_trial_count)",
        "- probe alpha: $(result.slot_blend_linearized.probe_alpha)",
        "- max alpha: $(result.slot_blend_linearized.max_alpha)",
        "- base objective: $(result.slot_blend_linearized.base_objective)",
        "- best exact objective: $(result.slot_blend_linearized.best_exact_objective)",
        "- best objective reduction: $(result.slot_blend_linearized.best_objective_reduction)",
        "- best positive deltas: $(result.slot_blend_linearized.best_positive_delta_count)",
        "- best TOA forcing: $(result.slot_blend_linearized.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.slot_blend_linearized.best_worst_surface_forcing_error_w_m2)",
        "- accepted: $(result.slot_blend_linearized.accepted)",
        "- accepted blends: $(result.slot_blend_linearized.accepted_blend_count)",
        "- total blends: $(result.slot_blend_linearized.total_blend_count)",
        "",
        "## Post-Slot Weight Refit",
        "",
        "- present: $(result.post_slot_weight_refit.present)",
        "- status: `$(result.post_slot_weight_refit.status)`",
        "- base blends: $(result.post_slot_weight_refit.base_blend_count)",
        "- iterations completed: $(result.post_slot_weight_refit.iterations_completed)",
        "- initial objective: $(result.post_slot_weight_refit.initial_objective)",
        "- final objective: $(result.post_slot_weight_refit.final_objective)",
        "- objective reduction: $(result.post_slot_weight_refit.objective_reduction)",
        "- accepted: $(result.post_slot_weight_refit.accepted)",
        "- initial TOA forcing: $(result.post_slot_weight_refit.initial_worst_toa_forcing_error_w_m2)",
        "- initial surface forcing: $(result.post_slot_weight_refit.initial_worst_surface_forcing_error_w_m2)",
        "- final TOA forcing: $(result.post_slot_weight_refit.final_worst_toa_forcing_error_w_m2)",
        "- final surface forcing: $(result.post_slot_weight_refit.final_worst_surface_forcing_error_w_m2)",
        "",
        "## Boundary-Column Block Refinement",
        "",
        "- present: $(result.boundary_column_block_refinement.present)",
        "- target case: $(result.boundary_column_block_refinement.target_case)",
        "- target metric: $(result.boundary_column_block_refinement.target_metric)",
        "- target column: $(result.boundary_column_block_refinement.target_column)",
        "- evaluated trials: $(result.boundary_column_block_refinement.evaluated_trial_count)",
        "- base objective: $(result.boundary_column_block_refinement.base_objective)",
        "- candidate objective: $(result.boundary_column_block_refinement.candidate_objective)",
        "- final objective: $(result.boundary_column_block_refinement.final_objective)",
        "- objective reduction: $(result.boundary_column_block_refinement.objective_reduction)",
        "- accepted: $(result.boundary_column_block_refinement.accepted)",
        "- accepted moves: $(result.boundary_column_block_refinement.accepted_move_count)",
        "- cumulative active moves: $(result.boundary_column_block_refinement.cumulative_active_move_count)",
        "- best component: $(result.boundary_column_block_refinement.best_component)",
        "- best block size: $(result.boundary_column_block_refinement.best_block_size)",
        "",
        "## Gas Pressure-Band Refinement",
        "",
        "- present: $(result.gas_pressure_band_refinement.present)",
        "- target case: $(result.gas_pressure_band_refinement.target_case)",
        "- target metric: $(result.gas_pressure_band_refinement.target_metric)",
        "- target column: $(result.gas_pressure_band_refinement.target_column)",
        "- pressure-band count: $(result.gas_pressure_band_refinement.pressure_band_count)",
        "- evaluated candidates: $(result.gas_pressure_band_refinement.evaluated_candidate_count)",
        "- evaluated trials: $(result.gas_pressure_band_refinement.evaluated_trial_count)",
        "- base objective: $(result.gas_pressure_band_refinement.base_objective)",
        "- candidate objective: $(result.gas_pressure_band_refinement.candidate_objective)",
        "- final objective: $(result.gas_pressure_band_refinement.final_objective)",
        "- objective reduction: $(result.gas_pressure_band_refinement.objective_reduction)",
        "- accepted: $(result.gas_pressure_band_refinement.accepted)",
        "- accepted moves: $(result.gas_pressure_band_refinement.accepted_move_count)",
        "- best component: $(result.gas_pressure_band_refinement.best_component)",
        "- best g-point: $(result.gas_pressure_band_refinement.best_gpoint)",
        "- best gas index: $(result.gas_pressure_band_refinement.best_gas_index)",
        "",
        "## Gas Pressure-Band Linearized Refit",
        "",
        "- present: $(result.gas_pressure_band_linearized.present)",
        "- fitted candidates: $(result.gas_pressure_band_linearized.fitted_candidate_count)",
        "- best ridge lambda: $(result.gas_pressure_band_linearized.best_ridge_lambda)",
        "- best direction: $(result.gas_pressure_band_linearized.best_direction)",
        "- base objective: $(result.gas_pressure_band_linearized.base_objective)",
        "- candidate objective: $(result.gas_pressure_band_linearized.candidate_objective)",
        "- final objective: $(result.gas_pressure_band_linearized.final_objective)",
        "- objective reduction: $(result.gas_pressure_band_linearized.objective_reduction)",
        "- accepted: $(result.gas_pressure_band_linearized.accepted)",
        "- accepted moves: $(result.gas_pressure_band_linearized.accepted_move_count)",
        "",
        "## Flux-Pair Bins",
        "",
        "- present: $(result.flux_pair_bins.present)",
        "- status: `$(result.flux_pair_bins.status)`",
        "- objective: $(result.flux_pair_bins.objective)",
        "- worst TOA forcing: $(result.flux_pair_bins.worst_toa_forcing_error)",
        "- worst surface forcing: $(result.flux_pair_bins.worst_surface_forcing_error)",
        "- passed hard thresholds: $(result.flux_pair_bins.passed_hard_thresholds)",
        "",
        "## Grouped Quadrature Search",
        "",
        "- present: $(result.grouped_quadrature_search.present)",
        "- status: `$(result.grouped_quadrature_search.status)`",
        "- candidates: $(result.grouped_quadrature_search.candidate_count)",
        "- best label: `$(result.grouped_quadrature_search.best_label)`",
        "- best objective: $(result.grouped_quadrature_search.best_objective)",
        "- best TOA forcing: $(result.grouped_quadrature_search.best_worst_toa_forcing_error)",
        "- best surface forcing: $(result.grouped_quadrature_search.best_worst_surface_forcing_error)",
        "- passed hard thresholds: $(result.grouped_quadrature_search.passed_hard_thresholds)",
        "",
        "## Grouped Quadrature Weight Refit",
        "",
        "- present: $(result.grouped_quadrature_weight_refit.present)",
        "- status: `$(result.grouped_quadrature_weight_refit.status)`",
        "- candidates: $(result.grouped_quadrature_weight_refit.candidate_count)",
        "- iterations: $(result.grouped_quadrature_weight_refit.iterations)",
        "- best label: `$(result.grouped_quadrature_weight_refit.best_label)`",
        "- best base objective: $(result.grouped_quadrature_weight_refit.best_base_objective)",
        "- best refit objective: $(result.grouped_quadrature_weight_refit.best_refit_objective)",
        "- best objective reduction: $(result.grouped_quadrature_weight_refit.best_objective_reduction)",
        "- best TOA forcing: $(result.grouped_quadrature_weight_refit.best_worst_toa_forcing_error)",
        "- best surface forcing: $(result.grouped_quadrature_weight_refit.best_worst_surface_forcing_error)",
        "- passed hard thresholds: $(result.grouped_quadrature_weight_refit.passed_hard_thresholds)",
        "",
        "## Weight Max-Norm Refit",
        "",
        "- present: $(result.weight_maxnorm_refit.present)",
        "- status: `$(result.weight_maxnorm_refit.status)`",
        "- base exact objective: $(result.weight_maxnorm_refit.base_exact_objective)",
        "- base linear objective: $(result.weight_maxnorm_refit.base_linear_objective)",
        "- best candidate: $(result.weight_maxnorm_refit.best_label)",
        "- best exact objective: $(result.weight_maxnorm_refit.best_exact_objective)",
        "- best approximate objective: $(result.weight_maxnorm_refit.best_approximate_objective)",
        "- best TOA forcing: $(result.weight_maxnorm_refit.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.weight_maxnorm_refit.best_worst_surface_forcing_error_w_m2)",
        "- max absolute weight delta: $(result.weight_maxnorm_refit.best_max_abs_weight_delta)",
        "- accepted: $(result.weight_maxnorm_refit.accepted)",
        "",
        "## Constrained Table Optimizer",
        "",
        "- present: $(result.constrained_table_optimizer.present)",
        "- status: `$(result.constrained_table_optimizer.status)`",
        "- candidate scope: `$(result.constrained_table_optimizer.candidate_scope)`",
        "- include Rayleigh candidates: $(result.constrained_table_optimizer.include_rayleigh)",
        "- candidates: $(result.constrained_table_optimizer.candidate_count)",
        "- probe step: $(result.constrained_table_optimizer.probe_step)",
        "- max log scale: $(result.constrained_table_optimizer.max_log_scale)",
        "- base objective: $(result.constrained_table_optimizer.base_objective)",
        "- best ridge lambda: $(result.constrained_table_optimizer.best_ridge_lambda)",
        "- best exact objective: $(result.constrained_table_optimizer.best_exact_objective)",
        "- best objective reduction: $(result.constrained_table_optimizer.best_objective_reduction)",
        "- best TOA forcing: $(result.constrained_table_optimizer.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.constrained_table_optimizer.best_worst_surface_forcing_error_w_m2)",
        "- accepted: $(result.constrained_table_optimizer.accepted)",
        "",
        "## Topology Constrained Optimizer",
        "",
        "- present: $(result.topology_constrained_optimizer.present)",
        "- status: `$(result.topology_constrained_optimizer.status)`",
        "- topologies: $(result.topology_constrained_optimizer.topology_count)",
        "- candidates per topology: $(result.topology_constrained_optimizer.candidate_count)",
        "- max log scale: $(result.topology_constrained_optimizer.max_log_scale)",
        "- best topology: $(result.topology_constrained_optimizer.best_label)",
        "- best exact objective: $(result.topology_constrained_optimizer.best_exact_objective)",
        "- best TOA forcing: $(result.topology_constrained_optimizer.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.topology_constrained_optimizer.best_worst_surface_forcing_error_w_m2)",
        "",
        "## Post-Constrained Weight Refit",
        "",
        "- present: $(result.post_constrained_weight_refit.present)",
        "- status: `$(result.post_constrained_weight_refit.status)`",
        "- initial objective: $(result.post_constrained_weight_refit.initial_objective)",
        "- final objective: $(result.post_constrained_weight_refit.final_objective)",
        "- objective reduction: $(result.post_constrained_weight_refit.objective_reduction)",
        "- accepted: $(result.post_constrained_weight_refit.accepted)",
        "- initial TOA forcing: $(result.post_constrained_weight_refit.initial_worst_toa_forcing_error_w_m2)",
        "- initial surface forcing: $(result.post_constrained_weight_refit.initial_worst_surface_forcing_error_w_m2)",
        "- final TOA forcing: $(result.post_constrained_weight_refit.final_worst_toa_forcing_error_w_m2)",
        "- final surface forcing: $(result.post_constrained_weight_refit.final_worst_surface_forcing_error_w_m2)",
        "",
        "## Post-Constrained Boundary Weight Refit",
        "",
        "- present: $(result.post_constrained_boundary_weight_refit.present)",
        "- status: `$(result.post_constrained_boundary_weight_refit.status)`",
        "- initial boundary objective: $(result.post_constrained_boundary_weight_refit.initial_boundary_objective)",
        "- final boundary objective: $(result.post_constrained_boundary_weight_refit.final_boundary_objective)",
        "- boundary objective reduction: $(result.post_constrained_boundary_weight_refit.boundary_objective_reduction)",
        "- initial full objective: $(result.post_constrained_boundary_weight_refit.initial_full_objective)",
        "- final full objective: $(result.post_constrained_boundary_weight_refit.final_full_objective)",
        "- accepted: $(result.post_constrained_boundary_weight_refit.accepted)",
        "- initial TOA forcing: $(result.post_constrained_boundary_weight_refit.initial_worst_toa_forcing_error_w_m2)",
        "- initial surface forcing: $(result.post_constrained_boundary_weight_refit.initial_worst_surface_forcing_error_w_m2)",
        "- final TOA forcing: $(result.post_constrained_boundary_weight_refit.final_worst_toa_forcing_error_w_m2)",
        "- final surface forcing: $(result.post_constrained_boundary_weight_refit.final_worst_surface_forcing_error_w_m2)",
        "",
        "## Hard-Gate Sparse Subset Search",
        "",
        "- present: $(result.hardgate_subset_search.present)",
        "- status: `$(result.hardgate_subset_search.status)`",
        "- selected shortwave g-points: `$(join(result.hardgate_subset_search.selected_shortwave_gpoints, ", "))`",
        "- exact objective: $(result.hardgate_subset_search.exact_objective)",
        "- approximate objective: $(result.hardgate_subset_search.approximate_objective)",
        "- worst TOA forcing: $(result.hardgate_subset_search.worst_toa_forcing_error_w_m2)",
        "- worst surface forcing: $(result.hardgate_subset_search.worst_surface_forcing_error_w_m2)",
        "- passed hard thresholds: $(result.hardgate_subset_search.passed_hard_thresholds)",
        "",
        "## Boundary-Table Topology Replacement",
        "",
        "- present: $(result.boundary_topology_replacement.present)",
        "- status: `$(result.boundary_topology_replacement.status)`",
        "- radius: $(result.boundary_topology_replacement.radius)",
        "- evaluated candidates: $(result.boundary_topology_replacement.evaluated_candidate_count)",
        "- base objective: $(result.boundary_topology_replacement.base_objective)",
        "- best objective: $(result.boundary_topology_replacement.best_objective)",
        "- best improvement: $(result.boundary_topology_replacement.best_improvement)",
        "- best replacement: g$(result.boundary_topology_replacement.best_removed_gpoint) -> g$(result.boundary_topology_replacement.best_added_gpoint)",
        "",
        "## Boundary-Table Topology Weight Refit",
        "",
        "- present: $(result.boundary_topology_weight_refit.present)",
        "- status: `$(result.boundary_topology_weight_refit.status)`",
        "- radius: $(result.boundary_topology_weight_refit.radius)",
        "- weight iterations: $(result.boundary_topology_weight_refit.weight_iterations)",
        "- evaluated candidates: $(result.boundary_topology_weight_refit.evaluated_candidate_count)",
        "- base objective: $(result.boundary_topology_weight_refit.base_objective)",
        "- best objective: $(result.boundary_topology_weight_refit.best_objective)",
        "- best improvement: $(result.boundary_topology_weight_refit.best_improvement)",
        "- best replacement: g$(result.boundary_topology_weight_refit.best_removed_gpoint) -> g$(result.boundary_topology_weight_refit.best_added_gpoint)",
        "",
        "## Boundary-Table Coordinate Scan",
        "",
        "- present: $(result.boundary_table_coordinate_scan.present)",
        "- status: `$(result.boundary_table_coordinate_scan.status)`",
        "- candidates: $(result.boundary_table_coordinate_scan.candidate_count)",
        "- trials: $(result.boundary_table_coordinate_scan.trial_count)",
        "- base objective: $(result.boundary_table_coordinate_scan.base_objective)",
        "- best objective: $(result.boundary_table_coordinate_scan.best_objective)",
        "- best objective reduction: $(result.boundary_table_coordinate_scan.best_objective_reduction)",
        "- best TOA forcing: $(result.boundary_table_coordinate_scan.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.boundary_table_coordinate_scan.best_worst_surface_forcing_error_w_m2)",
        "- accepted: $(result.boundary_table_coordinate_scan.accepted)",
        "",
        "## Boundary-Table Pair Coordinate Scan",
        "",
        "- present: $(result.boundary_table_pair_coordinate_scan.present)",
        "- status: `$(result.boundary_table_pair_coordinate_scan.status)`",
        "- single trials: $(result.boundary_table_pair_coordinate_scan.single_trial_count)",
        "- selected singles: $(result.boundary_table_pair_coordinate_scan.selected_single_count)",
        "- pair trials: $(result.boundary_table_pair_coordinate_scan.pair_trial_count)",
        "- base objective: $(result.boundary_table_pair_coordinate_scan.base_objective)",
        "- best objective: $(result.boundary_table_pair_coordinate_scan.best_objective)",
        "- best objective reduction: $(result.boundary_table_pair_coordinate_scan.best_objective_reduction)",
        "- best TOA forcing: $(result.boundary_table_pair_coordinate_scan.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.boundary_table_pair_coordinate_scan.best_worst_surface_forcing_error_w_m2)",
        "- accepted: $(result.boundary_table_pair_coordinate_scan.accepted)",
        "",
        "## Boundary-Table Coordinate Descent",
        "",
        "- present: $(result.boundary_table_coordinate_descent.present)",
        "- status: `$(result.boundary_table_coordinate_descent.status)`",
        "- candidates: $(result.boundary_table_coordinate_descent.candidate_count)",
        "- iteration limit: $(result.boundary_table_coordinate_descent.iteration_limit)",
        "- completed iterations: $(result.boundary_table_coordinate_descent.completed_iterations)",
        "- baseline objective: $(result.boundary_table_coordinate_descent.baseline_objective)",
        "- final objective: $(result.boundary_table_coordinate_descent.final_objective)",
        "- final objective reduction: $(result.boundary_table_coordinate_descent.final_objective_reduction)",
        "- final TOA forcing: $(result.boundary_table_coordinate_descent.final_worst_toa_forcing_error_w_m2)",
        "- final surface forcing: $(result.boundary_table_coordinate_descent.final_worst_surface_forcing_error_w_m2)",
        "- accepted: $(result.boundary_table_coordinate_descent.accepted)",
        "",
        "## Boundary-Table Continuation Optimizer",
        "",
        "- present: $(result.boundary_table_continuation_optimizer.present)",
        "- status: `$(result.boundary_table_continuation_optimizer.status)`",
        "- base mode: `$(result.boundary_table_continuation_optimizer.base_mode)`",
        "- candidate scope: `$(result.boundary_table_continuation_optimizer.candidate_scope)`",
        "- residual mode: `$(result.boundary_table_continuation_optimizer.residual_mode)`",
        "- include Rayleigh candidates: $(result.boundary_table_continuation_optimizer.include_rayleigh)",
        "- candidates: $(result.boundary_table_continuation_optimizer.candidate_count)",
        "- probe step: $(result.boundary_table_continuation_optimizer.probe_step)",
        "- max log scale: $(result.boundary_table_continuation_optimizer.max_log_scale)",
        "- base objective: $(result.boundary_table_continuation_optimizer.base_objective)",
        "- best exact objective: $(result.boundary_table_continuation_optimizer.best_exact_objective)",
        "- best objective reduction: $(result.boundary_table_continuation_optimizer.best_objective_reduction)",
        "- best TOA forcing: $(result.boundary_table_continuation_optimizer.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.boundary_table_continuation_optimizer.best_worst_surface_forcing_error_w_m2)",
        "- accepted: $(result.boundary_table_continuation_optimizer.accepted)",
        "",
        "## Component-Scale Refit",
        "",
        "- present: $(result.component_scale_refit.present)",
        "- status: `$(result.component_scale_refit.status)`",
        "- base mode: `$(result.component_scale_refit.base_mode)`",
        "- parameter count: $(result.component_scale_refit.parameter_count)",
        "- coordinate iterations: $(result.component_scale_refit.coordinate_iteration_count) / $(result.component_scale_refit.coordinate_iterations_requested)",
        "- base objective: $(result.component_scale_refit.base_objective)",
        "- coordinate final objective: $(result.component_scale_refit.coordinate_final_objective)",
        "- final objective: $(result.component_scale_refit.final_objective)",
        "- objective reduction: $(result.component_scale_refit.objective_reduction)",
        "- final TOA forcing: $(result.component_scale_refit.final_worst_toa_forcing_error_w_m2)",
        "- final surface forcing: $(result.component_scale_refit.final_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.component_scale_refit.accepted_move_count)",
        "- accepted: $(result.component_scale_refit.accepted)",
        "",
        "## Pressure-Component Scale Refit",
        "",
        "- present: $(result.pressure_component_scale_refit.present)",
        "- status: `$(result.pressure_component_scale_refit.status)`",
        "- base mode: `$(result.pressure_component_scale_refit.base_mode)`",
        "- pressure bands: $(result.pressure_component_scale_refit.pressure_band_count)",
        "- candidates: $(result.pressure_component_scale_refit.candidate_count)",
        "- iterations: $(result.pressure_component_scale_refit.completed_iterations) / $(result.pressure_component_scale_refit.iteration_limit)",
        "- base objective: $(result.pressure_component_scale_refit.base_objective)",
        "- final objective: $(result.pressure_component_scale_refit.final_objective)",
        "- objective reduction: $(result.pressure_component_scale_refit.objective_reduction)",
        "- final TOA forcing: $(result.pressure_component_scale_refit.final_worst_toa_forcing_error_w_m2)",
        "- final surface forcing: $(result.pressure_component_scale_refit.final_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.pressure_component_scale_refit.accepted_move_count)",
        "- accepted: $(result.pressure_component_scale_refit.accepted)",
        "",
        "## Temperature-Component Scale Refit",
        "",
        "- present: $(result.temperature_component_scale_refit.present)",
        "- status: `$(result.temperature_component_scale_refit.status)`",
        "- base mode: `$(result.temperature_component_scale_refit.base_mode)`",
        "- temperature bands: $(result.temperature_component_scale_refit.temperature_band_count)",
        "- candidates: $(result.temperature_component_scale_refit.candidate_count)",
        "- iterations: $(result.temperature_component_scale_refit.completed_iterations) / $(result.temperature_component_scale_refit.iteration_limit)",
        "- base objective: $(result.temperature_component_scale_refit.base_objective)",
        "- final objective: $(result.temperature_component_scale_refit.final_objective)",
        "- objective reduction: $(result.temperature_component_scale_refit.objective_reduction)",
        "- final TOA forcing: $(result.temperature_component_scale_refit.final_worst_toa_forcing_error_w_m2)",
        "- final surface forcing: $(result.temperature_component_scale_refit.final_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.temperature_component_scale_refit.accepted_move_count)",
        "- accepted: $(result.temperature_component_scale_refit.accepted)",
        "",
        "## H2O-Component Scale Refit",
        "",
        "- present: $(result.h2o_component_scale_refit.present)",
        "- status: `$(result.h2o_component_scale_refit.status)`",
        "- base mode: `$(result.h2o_component_scale_refit.base_mode)`",
        "- H2O bands: $(result.h2o_component_scale_refit.h2o_band_count)",
        "- candidates: $(result.h2o_component_scale_refit.candidate_count)",
        "- iterations: $(result.h2o_component_scale_refit.completed_iterations) / $(result.h2o_component_scale_refit.iteration_limit)",
        "- base objective: $(result.h2o_component_scale_refit.base_objective)",
        "- final objective: $(result.h2o_component_scale_refit.final_objective)",
        "- objective reduction: $(result.h2o_component_scale_refit.objective_reduction)",
        "- final TOA forcing: $(result.h2o_component_scale_refit.final_worst_toa_forcing_error_w_m2)",
        "- final surface forcing: $(result.h2o_component_scale_refit.final_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.h2o_component_scale_refit.accepted_move_count)",
        "- accepted: $(result.h2o_component_scale_refit.accepted)",
        "",
        "## Gas-Component Scale Refit",
        "",
        "- present: $(result.gas_component_scale_refit.present)",
        "- status: `$(result.gas_component_scale_refit.status)`",
        "- base mode: `$(result.gas_component_scale_refit.base_mode)`",
        "- candidates: $(result.gas_component_scale_refit.candidate_count)",
        "- iterations: $(result.gas_component_scale_refit.completed_iterations) / $(result.gas_component_scale_refit.iteration_limit)",
        "- base objective: $(result.gas_component_scale_refit.base_objective)",
        "- final objective: $(result.gas_component_scale_refit.final_objective)",
        "- objective reduction: $(result.gas_component_scale_refit.objective_reduction)",
        "- final TOA forcing: $(result.gas_component_scale_refit.final_worst_toa_forcing_error_w_m2)",
        "- final surface forcing: $(result.gas_component_scale_refit.final_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.gas_component_scale_refit.accepted_move_count)",
        "- accepted: $(result.gas_component_scale_refit.accepted)",
        "",
        "## Pressure-Temperature Component Scale Refit",
        "",
        "- present: $(result.pressure_temperature_component_scale_refit.present)",
        "- status: `$(result.pressure_temperature_component_scale_refit.status)`",
        "- base mode: `$(result.pressure_temperature_component_scale_refit.base_mode)`",
        "- objective mode: `$(result.pressure_temperature_component_scale_refit.objective_mode)`",
        "- candidates: $(result.pressure_temperature_component_scale_refit.candidate_count)",
        "- iterations: $(result.pressure_temperature_component_scale_refit.completed_iterations) / $(result.pressure_temperature_component_scale_refit.iteration_limit)",
        "- base objective: $(result.pressure_temperature_component_scale_refit.base_objective)",
        "- final objective: $(result.pressure_temperature_component_scale_refit.final_objective)",
        "- objective reduction: $(result.pressure_temperature_component_scale_refit.objective_reduction)",
        "- final TOA forcing: $(result.pressure_temperature_component_scale_refit.final_worst_toa_forcing_error_w_m2)",
        "- final surface forcing: $(result.pressure_temperature_component_scale_refit.final_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.pressure_temperature_component_scale_refit.accepted_move_count)",
        "- accepted: $(result.pressure_temperature_component_scale_refit.accepted)",
        "",
        "## Gas Pressure-Temperature Component Scale Refit",
        "",
        "- present: $(result.gas_pressure_temperature_component_scale_refit.present)",
        "- status: `$(result.gas_pressure_temperature_component_scale_refit.status)`",
        "- base mode: `$(result.gas_pressure_temperature_component_scale_refit.base_mode)`",
        "- candidates: $(result.gas_pressure_temperature_component_scale_refit.candidate_count)",
        "- iterations: $(result.gas_pressure_temperature_component_scale_refit.completed_iterations) / $(result.gas_pressure_temperature_component_scale_refit.iteration_limit)",
        "- base objective: $(result.gas_pressure_temperature_component_scale_refit.base_objective)",
        "- final objective: $(result.gas_pressure_temperature_component_scale_refit.final_objective)",
        "- objective reduction: $(result.gas_pressure_temperature_component_scale_refit.objective_reduction)",
        "- final TOA forcing: $(result.gas_pressure_temperature_component_scale_refit.final_worst_toa_forcing_error_w_m2)",
        "- final surface forcing: $(result.gas_pressure_temperature_component_scale_refit.final_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.gas_pressure_temperature_component_scale_refit.accepted_move_count)",
        "- accepted: $(result.gas_pressure_temperature_component_scale_refit.accepted)",
        "",
        "## H2O Pressure-Temperature Component Scale Refit",
        "",
        "- present: $(result.h2o_pressure_temperature_component_scale_refit.present)",
        "- status: `$(result.h2o_pressure_temperature_component_scale_refit.status)`",
        "- base mode: `$(result.h2o_pressure_temperature_component_scale_refit.base_mode)`",
        "- candidates: $(result.h2o_pressure_temperature_component_scale_refit.candidate_count)",
        "- iterations: $(result.h2o_pressure_temperature_component_scale_refit.completed_iterations) / $(result.h2o_pressure_temperature_component_scale_refit.iteration_limit)",
        "- base objective: $(result.h2o_pressure_temperature_component_scale_refit.base_objective)",
        "- final objective: $(result.h2o_pressure_temperature_component_scale_refit.final_objective)",
        "- objective reduction: $(result.h2o_pressure_temperature_component_scale_refit.objective_reduction)",
        "- final TOA forcing: $(result.h2o_pressure_temperature_component_scale_refit.final_worst_toa_forcing_error_w_m2)",
        "- final surface forcing: $(result.h2o_pressure_temperature_component_scale_refit.final_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.h2o_pressure_temperature_component_scale_refit.accepted_move_count)",
        "- accepted: $(result.h2o_pressure_temperature_component_scale_refit.accepted)",
        "",
        "## Mixed Pressure-Temperature Component Refit",
        "",
        "- present: $(result.mixed_pressure_temperature_component_refit.present)",
        "- status: `$(result.mixed_pressure_temperature_component_refit.status)`",
        "- base mode: `$(result.mixed_pressure_temperature_component_refit.base_mode)`",
        "- candidates: $(result.mixed_pressure_temperature_component_refit.candidate_count)",
        "- iterations: $(result.mixed_pressure_temperature_component_refit.completed_iterations) / $(result.mixed_pressure_temperature_component_refit.iteration_limit)",
        "- base objective: $(result.mixed_pressure_temperature_component_refit.base_objective)",
        "- final objective: $(result.mixed_pressure_temperature_component_refit.final_objective)",
        "- objective reduction: $(result.mixed_pressure_temperature_component_refit.objective_reduction)",
        "- final TOA forcing: $(result.mixed_pressure_temperature_component_refit.final_worst_toa_forcing_error_w_m2)",
        "- final surface forcing: $(result.mixed_pressure_temperature_component_refit.final_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.mixed_pressure_temperature_component_refit.accepted_move_count)",
        "- accepted: $(result.mixed_pressure_temperature_component_refit.accepted)",
        "",
        "## Retained Mixed Component Pareto Scan",
        "",
        "- present: $(result.retained_mixed_component_pareto_scan.present)",
        "- status: `$(result.retained_mixed_component_pareto_scan.status)`",
        "- acceptance rule: `$(result.retained_mixed_component_pareto_scan.acceptance_rule)`",
        "- forcing-error tolerance: $(result.retained_mixed_component_pareto_scan.pareto_tolerance)",
        "- surface cap: $(result.retained_mixed_component_pareto_scan.surface_cap_w_m2)",
        "- candidates: $(result.retained_mixed_component_pareto_scan.candidate_count)",
        "- trials: $(result.retained_mixed_component_pareto_scan.trial_count)",
        "- base objective: $(result.retained_mixed_component_pareto_scan.base_objective)",
        "- final objective: $(result.retained_mixed_component_pareto_scan.final_objective)",
        "- objective reduction: $(result.retained_mixed_component_pareto_scan.objective_reduction)",
        "- best exact objective: $(result.retained_mixed_component_pareto_scan.best_exact_objective)",
        "- best objective reduction: $(result.retained_mixed_component_pareto_scan.best_objective_reduction)",
        "- final TOA forcing: $(result.retained_mixed_component_pareto_scan.final_worst_toa_forcing_error_w_m2)",
        "- final surface forcing: $(result.retained_mixed_component_pareto_scan.final_worst_surface_forcing_error_w_m2)",
        "- best TOA forcing: $(result.retained_mixed_component_pareto_scan.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_mixed_component_pareto_scan.best_worst_surface_forcing_error_w_m2)",
        "- any strict Pareto-safe: $(result.retained_mixed_component_pareto_scan.any_strict_pareto_safe)",
        "- any surface-cap-safe: $(result.retained_mixed_component_pareto_scan.any_surface_cap_safe)",
        "- any tolerance Pareto-safe: $(result.retained_mixed_component_pareto_scan.any_pareto_safe)",
        "- accepted: $(result.retained_mixed_component_pareto_scan.accepted)",
        "",
        "## Retained Topology Neighbor Scan",
        "",
        "- present: $(result.retained_topology_neighbor_scan.present)",
        "- status: `$(result.retained_topology_neighbor_scan.status)`",
        "- radius: $(result.retained_topology_neighbor_scan.radius)",
        "- candidates: $(result.retained_topology_neighbor_scan.candidate_count)",
        "- pair candidates: $(result.retained_topology_neighbor_scan.pair_candidate_count)",
        "- base objective: $(result.retained_topology_neighbor_scan.base_objective)",
        "- best objective: $(result.retained_topology_neighbor_scan.best_objective)",
        "- best objective reduction: $(result.retained_topology_neighbor_scan.best_objective_reduction)",
        "- base TOA forcing: $(result.retained_topology_neighbor_scan.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_topology_neighbor_scan.base_worst_surface_forcing_error_w_m2)",
        "- best TOA forcing: $(result.retained_topology_neighbor_scan.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_topology_neighbor_scan.best_worst_surface_forcing_error_w_m2)",
        "- best replacement: slot $(result.retained_topology_neighbor_scan.best_slot), g$(result.retained_topology_neighbor_scan.best_old_gpoint) -> g$(result.retained_topology_neighbor_scan.best_new_gpoint)",
        "- Pareto safe: $(result.retained_topology_neighbor_scan.pareto_safe)",
        "- passed hard thresholds: $(result.retained_topology_neighbor_scan.passed_hard_thresholds)",
        "",
        "## Retained Topology Constrained Optimizer",
        "",
        "- present: $(result.retained_topology_constrained_optimizer.present)",
        "- status: `$(result.retained_topology_constrained_optimizer.status)`",
        "- candidate scope: `$(result.retained_topology_constrained_optimizer.candidate_scope)`",
        "- residual mode: `$(result.retained_topology_constrained_optimizer.residual_mode)`",
        "- candidates: $(result.retained_topology_constrained_optimizer.candidate_count)",
        "- base objective: $(result.retained_topology_constrained_optimizer.base_objective)",
        "- best exact objective: $(result.retained_topology_constrained_optimizer.best_exact_objective)",
        "- best objective reduction: $(result.retained_topology_constrained_optimizer.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_topology_constrained_optimizer.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_topology_constrained_optimizer.best_worst_surface_forcing_error_w_m2)",
        "- Pareto safe: $(result.retained_topology_constrained_optimizer.pareto_safe)",
        "- proposed moves: $(result.retained_topology_constrained_optimizer.proposed_move_count)",
        "- accepted: $(result.retained_topology_constrained_optimizer.accepted)",
        "",
        "## Structural Optimizer Sweep",
        "",
        "- present: $(result.structural_optimizer_sweep.present)",
        "- status: `$(result.structural_optimizer_sweep.status)`",
        "- configurations: $(result.structural_optimizer_sweep.config_count)",
        "- best label: `$(result.structural_optimizer_sweep.best_label)`",
        "- best base objective: $(result.structural_optimizer_sweep.best_base_objective)",
        "- best exact objective: $(result.structural_optimizer_sweep.best_exact_objective)",
        "- best objective reduction: $(result.structural_optimizer_sweep.best_objective_reduction)",
        "- best TOA forcing: $(result.structural_optimizer_sweep.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.structural_optimizer_sweep.best_worst_surface_forcing_error_w_m2)",
        "",
        "## Retained Structural Optimizer",
        "",
        "- present: $(result.retained_structural_optimizer.present)",
        "- status: `$(result.retained_structural_optimizer.status)`",
        "- base mode: `$(result.retained_structural_optimizer.base_mode)`",
        "- candidate scope: `$(result.retained_structural_optimizer.candidate_scope)`",
        "- residual mode: `$(result.retained_structural_optimizer.residual_mode)`",
        "- include Rayleigh candidates: $(result.retained_structural_optimizer.include_rayleigh)",
        "- candidates: $(result.retained_structural_optimizer.candidate_count)",
        "- probe step: $(result.retained_structural_optimizer.probe_step)",
        "- max log scale: $(result.retained_structural_optimizer.max_log_scale)",
        "- base objective: $(result.retained_structural_optimizer.base_objective)",
        "- best exact objective: $(result.retained_structural_optimizer.best_exact_objective)",
        "- best objective reduction: $(result.retained_structural_optimizer.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_structural_optimizer.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_structural_optimizer.best_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.retained_structural_optimizer.accepted_move_count)",
        "- accepted: $(result.retained_structural_optimizer.accepted)",
        "",
        "## Retained Structural Continuation",
        "",
        "- present: $(result.retained_structural_continuation.present)",
        "- status: `$(result.retained_structural_continuation.status)`",
        "- base mode: `$(result.retained_structural_continuation.base_mode)`",
        "- candidate scope: `$(result.retained_structural_continuation.candidate_scope)`",
        "- residual mode: `$(result.retained_structural_continuation.residual_mode)`",
        "- include Rayleigh candidates: $(result.retained_structural_continuation.include_rayleigh)",
        "- candidates: $(result.retained_structural_continuation.candidate_count)",
        "- probe step: $(result.retained_structural_continuation.probe_step)",
        "- max log scale: $(result.retained_structural_continuation.max_log_scale)",
        "- base objective: $(result.retained_structural_continuation.base_objective)",
        "- best exact objective: $(result.retained_structural_continuation.best_exact_objective)",
        "- best objective reduction: $(result.retained_structural_continuation.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_structural_continuation.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_structural_continuation.best_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.retained_structural_continuation.accepted_move_count)",
        "- accepted: $(result.retained_structural_continuation.accepted)",
        "",
        "## Retained Structural Continuation 2",
        "",
        "- present: $(result.retained_structural_continuation2.present)",
        "- status: `$(result.retained_structural_continuation2.status)`",
        "- base mode: `$(result.retained_structural_continuation2.base_mode)`",
        "- candidate scope: `$(result.retained_structural_continuation2.candidate_scope)`",
        "- residual mode: `$(result.retained_structural_continuation2.residual_mode)`",
        "- include Rayleigh candidates: $(result.retained_structural_continuation2.include_rayleigh)",
        "- candidates: $(result.retained_structural_continuation2.candidate_count)",
        "- probe step: $(result.retained_structural_continuation2.probe_step)",
        "- max log scale: $(result.retained_structural_continuation2.max_log_scale)",
        "- base objective: $(result.retained_structural_continuation2.base_objective)",
        "- best exact objective: $(result.retained_structural_continuation2.best_exact_objective)",
        "- best objective reduction: $(result.retained_structural_continuation2.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_structural_continuation2.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_structural_continuation2.best_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.retained_structural_continuation2.accepted_move_count)",
        "- accepted: $(result.retained_structural_continuation2.accepted)",
        "",
        "## Retained Structural Continuation 3",
        "",
        "- present: $(result.retained_structural_continuation3.present)",
        "- status: `$(result.retained_structural_continuation3.status)`",
        "- base mode: `$(result.retained_structural_continuation3.base_mode)`",
        "- candidate scope: `$(result.retained_structural_continuation3.candidate_scope)`",
        "- residual mode: `$(result.retained_structural_continuation3.residual_mode)`",
        "- include Rayleigh candidates: $(result.retained_structural_continuation3.include_rayleigh)",
        "- candidates: $(result.retained_structural_continuation3.candidate_count)",
        "- probe step: $(result.retained_structural_continuation3.probe_step)",
        "- max log scale: $(result.retained_structural_continuation3.max_log_scale)",
        "- base objective: $(result.retained_structural_continuation3.base_objective)",
        "- best exact objective: $(result.retained_structural_continuation3.best_exact_objective)",
        "- best objective reduction: $(result.retained_structural_continuation3.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_structural_continuation3.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_structural_continuation3.best_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.retained_structural_continuation3.accepted_move_count)",
        "- accepted: $(result.retained_structural_continuation3.accepted)",
        "",
        "## Retained Structural Continuation 4",
        "",
        "- present: $(result.retained_structural_continuation4.present)",
        "- status: `$(result.retained_structural_continuation4.status)`",
        "- base mode: `$(result.retained_structural_continuation4.base_mode)`",
        "- candidate scope: `$(result.retained_structural_continuation4.candidate_scope)`",
        "- residual mode: `$(result.retained_structural_continuation4.residual_mode)`",
        "- include Rayleigh candidates: $(result.retained_structural_continuation4.include_rayleigh)",
        "- candidates: $(result.retained_structural_continuation4.candidate_count)",
        "- probe step: $(result.retained_structural_continuation4.probe_step)",
        "- max log scale: $(result.retained_structural_continuation4.max_log_scale)",
        "- base objective: $(result.retained_structural_continuation4.base_objective)",
        "- best exact objective: $(result.retained_structural_continuation4.best_exact_objective)",
        "- best objective reduction: $(result.retained_structural_continuation4.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_structural_continuation4.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_structural_continuation4.best_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.retained_structural_continuation4.accepted_move_count)",
        "- accepted: $(result.retained_structural_continuation4.accepted)",
        "",
        "## Retained Structural Pareto Probe",
        "",
        "- present: $(result.retained_structural_pareto_probe.present)",
        "- status: `$(result.retained_structural_pareto_probe.status)`",
        "- configurations: $(result.retained_structural_pareto_probe.config_count)",
        "- best label: `$(result.retained_structural_pareto_probe.best_label)`",
        "- best exact objective: $(result.retained_structural_pareto_probe.best_exact_objective)",
        "- best objective reduction: $(result.retained_structural_pareto_probe.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_structural_pareto_probe.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_structural_pareto_probe.best_worst_surface_forcing_error_w_m2)",
        "- any accepted: $(result.retained_structural_pareto_probe.any_accepted)",
        "- any Pareto-safe accepted: $(result.retained_structural_pareto_probe.any_pareto_safe)",
        "",
        "## Retained Quadrature Pareto Scan",
        "",
        "- present: $(result.retained_quadrature_pareto_scan.present)",
        "- status: `$(result.retained_quadrature_pareto_scan.status)`",
        "- candidates: $(result.retained_quadrature_pareto_scan.candidate_count)",
        "- base objective: $(result.retained_quadrature_pareto_scan.base_objective)",
        "- best objective: $(result.retained_quadrature_pareto_scan.best_objective)",
        "- best objective reduction: $(result.retained_quadrature_pareto_scan.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_quadrature_pareto_scan.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_quadrature_pareto_scan.best_worst_surface_forcing_error_w_m2)",
        "- best move: g$(result.retained_quadrature_pareto_scan.best_gpoint) $(result.retained_quadrature_pareto_scan.best_direction) $(result.retained_quadrature_pareto_scan.best_step)",
        "- best TOA regressed: $(result.retained_quadrature_pareto_scan.best_toa_regressed)",
        "- best surface regressed: $(result.retained_quadrature_pareto_scan.best_surface_regressed)",
        "- any Pareto-safe: $(result.retained_quadrature_pareto_scan.any_pareto_safe)",
        "- best Pareto-safe objective: $(result.retained_quadrature_pareto_scan.best_safe_objective)",
        "",
        "## Retained Quadrature Pair Pareto Scan",
        "",
        "- present: $(result.retained_quadrature_pair_pareto_scan.present)",
        "- status: `$(result.retained_quadrature_pair_pareto_scan.status)`",
        "- pairs: $(result.retained_quadrature_pair_pareto_scan.pair_count)",
        "- candidates: $(result.retained_quadrature_pair_pareto_scan.candidate_count)",
        "- base objective: $(result.retained_quadrature_pair_pareto_scan.base_objective)",
        "- best objective: $(result.retained_quadrature_pair_pareto_scan.best_objective)",
        "- best objective reduction: $(result.retained_quadrature_pair_pareto_scan.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_quadrature_pair_pareto_scan.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_quadrature_pair_pareto_scan.best_worst_surface_forcing_error_w_m2)",
        "- best move: g$(result.retained_quadrature_pair_pareto_scan.best_up_gpoint) up, g$(result.retained_quadrature_pair_pareto_scan.best_down_gpoint) down, $(result.retained_quadrature_pair_pareto_scan.best_step)",
        "- best TOA regressed: $(result.retained_quadrature_pair_pareto_scan.best_toa_regressed)",
        "- best surface regressed: $(result.retained_quadrature_pair_pareto_scan.best_surface_regressed)",
        "- any Pareto-safe: $(result.retained_quadrature_pair_pareto_scan.any_pareto_safe)",
        "- best Pareto-safe objective: $(result.retained_quadrature_pair_pareto_scan.best_safe_objective)",
        "",
        "## Retained Quadrature Linearized Optimizer",
        "",
        "- present: $(result.retained_quadrature_linearized_optimizer.present)",
        "- status: `$(result.retained_quadrature_linearized_optimizer.status)`",
        "- residual mode: `$(result.retained_quadrature_linearized_optimizer.residual_mode)`",
        "- basis count: $(result.retained_quadrature_linearized_optimizer.basis_count)",
        "- base objective: $(result.retained_quadrature_linearized_optimizer.base_objective)",
        "- best exact objective: $(result.retained_quadrature_linearized_optimizer.best_exact_objective)",
        "- best objective reduction: $(result.retained_quadrature_linearized_optimizer.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_quadrature_linearized_optimizer.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_quadrature_linearized_optimizer.best_worst_surface_forcing_error_w_m2)",
        "- any Pareto-safe: $(result.retained_quadrature_linearized_optimizer.any_pareto_safe)",
        "- accepted: $(result.retained_quadrature_linearized_optimizer.accepted)",
        "",
        "## Retained Current Quadrature Linearized Optimizer",
        "",
        "- present: $(result.retained_current_quadrature_linearized_optimizer.present)",
        "- status: `$(result.retained_current_quadrature_linearized_optimizer.status)`",
        "- residual mode: `$(result.retained_current_quadrature_linearized_optimizer.residual_mode)`",
        "- basis count: $(result.retained_current_quadrature_linearized_optimizer.basis_count)",
        "- surface cap: $(result.retained_current_quadrature_linearized_optimizer.surface_cap_w_m2)",
        "- TOA tolerance: $(result.retained_current_quadrature_linearized_optimizer.toa_tolerance_w_m2)",
        "- base objective: $(result.retained_current_quadrature_linearized_optimizer.base_objective)",
        "- base TOA forcing: $(result.retained_current_quadrature_linearized_optimizer.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_current_quadrature_linearized_optimizer.base_worst_surface_forcing_error_w_m2)",
        "- best exact objective: $(result.retained_current_quadrature_linearized_optimizer.best_exact_objective)",
        "- best objective reduction: $(result.retained_current_quadrature_linearized_optimizer.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_current_quadrature_linearized_optimizer.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_current_quadrature_linearized_optimizer.best_worst_surface_forcing_error_w_m2)",
        "- accepted objective: $(result.retained_current_quadrature_linearized_optimizer.accepted_objective)",
        "- accepted TOA forcing: $(result.retained_current_quadrature_linearized_optimizer.accepted_worst_toa_forcing_error_w_m2)",
        "- accepted surface forcing: $(result.retained_current_quadrature_linearized_optimizer.accepted_worst_surface_forcing_error_w_m2)",
        "- accepted: $(result.retained_current_quadrature_linearized_optimizer.accepted)",
        "",
        "## Retained Current Bounded Table Optimizer",
        "",
        "- present: $(result.retained_current_bounded_table_optimizer.present)",
        "- status: `$(result.retained_current_bounded_table_optimizer.status)`",
        "- residual mode: `$(result.retained_current_bounded_table_optimizer.residual_mode)`",
        "- candidates: $(result.retained_current_bounded_table_optimizer.candidate_count)",
        "- surface cap: $(result.retained_current_bounded_table_optimizer.surface_cap_w_m2)",
        "- TOA tolerance: $(result.retained_current_bounded_table_optimizer.toa_tolerance_w_m2)",
        "- minimum objective reduction: $(result.retained_current_bounded_table_optimizer.min_objective_reduction)",
        "- base objective: $(result.retained_current_bounded_table_optimizer.base_objective)",
        "- base TOA forcing: $(result.retained_current_bounded_table_optimizer.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_current_bounded_table_optimizer.base_worst_surface_forcing_error_w_m2)",
        "- best exact objective: $(result.retained_current_bounded_table_optimizer.best_exact_objective)",
        "- best objective reduction: $(result.retained_current_bounded_table_optimizer.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_current_bounded_table_optimizer.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_current_bounded_table_optimizer.best_worst_surface_forcing_error_w_m2)",
        "- accepted objective: $(result.retained_current_bounded_table_optimizer.accepted_objective)",
        "- accepted objective reduction: $(result.retained_current_bounded_table_optimizer.accepted_objective_reduction)",
        "- accepted TOA forcing: $(result.retained_current_bounded_table_optimizer.accepted_worst_toa_forcing_error_w_m2)",
        "- accepted surface forcing: $(result.retained_current_bounded_table_optimizer.accepted_worst_surface_forcing_error_w_m2)",
        "- accepted moves: $(result.retained_current_bounded_table_optimizer.accepted_move_count)",
        "- accepted: $(result.retained_current_bounded_table_optimizer.accepted)",
        "",
        "## Retained Current Heating-Profile Optimizer",
        "",
        "- present: $(result.retained_current_heating_profile_optimizer.present)",
        "- status: `$(result.retained_current_heating_profile_optimizer.status)`",
        "- residual mode: `$(result.retained_current_heating_profile_optimizer.residual_mode)`",
        "- candidates: $(result.retained_current_heating_profile_optimizer.candidate_count)",
        "- surface cap: $(result.retained_current_heating_profile_optimizer.surface_cap_w_m2)",
        "- TOA tolerance: $(result.retained_current_heating_profile_optimizer.toa_tolerance_w_m2)",
        "- minimum objective reduction: $(result.retained_current_heating_profile_optimizer.min_objective_reduction)",
        "- base objective: $(result.retained_current_heating_profile_optimizer.base_objective)",
        "- base TOA forcing: $(result.retained_current_heating_profile_optimizer.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_current_heating_profile_optimizer.base_worst_surface_forcing_error_w_m2)",
        "- base heating RMSE: $(result.retained_current_heating_profile_optimizer.base_worst_heating_rate_rmse_k_day)",
        "- best exact objective: $(result.retained_current_heating_profile_optimizer.best_exact_objective)",
        "- best objective reduction: $(result.retained_current_heating_profile_optimizer.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_current_heating_profile_optimizer.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_current_heating_profile_optimizer.best_worst_surface_forcing_error_w_m2)",
        "- best heating RMSE: $(result.retained_current_heating_profile_optimizer.best_worst_heating_rate_rmse_k_day)",
        "- accepted objective: $(result.retained_current_heating_profile_optimizer.accepted_objective)",
        "- accepted objective reduction: $(result.retained_current_heating_profile_optimizer.accepted_objective_reduction)",
        "- accepted TOA forcing: $(result.retained_current_heating_profile_optimizer.accepted_worst_toa_forcing_error_w_m2)",
        "- accepted surface forcing: $(result.retained_current_heating_profile_optimizer.accepted_worst_surface_forcing_error_w_m2)",
        "- accepted heating RMSE: $(result.retained_current_heating_profile_optimizer.accepted_worst_heating_rate_rmse_k_day)",
        "- accepted moves: $(result.retained_current_heating_profile_optimizer.accepted_move_count)",
        "- accepted: $(result.retained_current_heating_profile_optimizer.accepted)",
        "",
        "## Retained Current Joint Heating Optimizer",
        "",
        "- present: $(result.retained_current_joint_heating_optimizer.present)",
        "- status: `$(result.retained_current_joint_heating_optimizer.status)`",
        "- residual mode: `$(result.retained_current_joint_heating_optimizer.residual_mode)`",
        "- basis: `$(result.retained_current_joint_heating_optimizer.basis)`",
        "- logit basis count: $(result.retained_current_joint_heating_optimizer.logit_basis_count)",
        "- table candidates: $(result.retained_current_joint_heating_optimizer.table_candidate_count)",
        "- basis count: $(result.retained_current_joint_heating_optimizer.basis_count)",
        "- surface cap: $(result.retained_current_joint_heating_optimizer.surface_cap_w_m2)",
        "- TOA tolerance: $(result.retained_current_joint_heating_optimizer.toa_tolerance_w_m2)",
        "- minimum objective reduction: $(result.retained_current_joint_heating_optimizer.min_objective_reduction)",
        "- base objective: $(result.retained_current_joint_heating_optimizer.base_objective)",
        "- base TOA forcing: $(result.retained_current_joint_heating_optimizer.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_current_joint_heating_optimizer.base_worst_surface_forcing_error_w_m2)",
        "- base heating RMSE: $(result.retained_current_joint_heating_optimizer.base_worst_heating_rate_rmse_k_day)",
        "- best exact objective: $(result.retained_current_joint_heating_optimizer.best_exact_objective)",
        "- best objective reduction: $(result.retained_current_joint_heating_optimizer.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_current_joint_heating_optimizer.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_current_joint_heating_optimizer.best_worst_surface_forcing_error_w_m2)",
        "- best heating RMSE: $(result.retained_current_joint_heating_optimizer.best_worst_heating_rate_rmse_k_day)",
        "- accepted objective: $(result.retained_current_joint_heating_optimizer.accepted_objective)",
        "- accepted objective reduction: $(result.retained_current_joint_heating_optimizer.accepted_objective_reduction)",
        "- accepted TOA forcing: $(result.retained_current_joint_heating_optimizer.accepted_worst_toa_forcing_error_w_m2)",
        "- accepted surface forcing: $(result.retained_current_joint_heating_optimizer.accepted_worst_surface_forcing_error_w_m2)",
        "- accepted heating RMSE: $(result.retained_current_joint_heating_optimizer.accepted_worst_heating_rate_rmse_k_day)",
        "- accepted table moves: $(result.retained_current_joint_heating_optimizer.accepted_table_move_count)",
        "- accepted: $(result.retained_current_joint_heating_optimizer.accepted)",
        "",
        "## Retained Current Component-Scale Optimizer",
        "",
        "- present: $(result.retained_current_component_scale_optimizer.present)",
        "- status: `$(result.retained_current_component_scale_optimizer.status)`",
        "- residual mode: `$(result.retained_current_component_scale_optimizer.residual_mode)`",
        "- basis: `$(result.retained_current_component_scale_optimizer.basis)`",
        "- basis count: $(result.retained_current_component_scale_optimizer.basis_count)",
        "- surface cap: $(result.retained_current_component_scale_optimizer.surface_cap_w_m2)",
        "- TOA tolerance: $(result.retained_current_component_scale_optimizer.toa_tolerance_w_m2)",
        "- minimum objective reduction: $(result.retained_current_component_scale_optimizer.min_objective_reduction)",
        "- base objective: $(result.retained_current_component_scale_optimizer.base_objective)",
        "- base TOA forcing: $(result.retained_current_component_scale_optimizer.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_current_component_scale_optimizer.base_worst_surface_forcing_error_w_m2)",
        "- base heating RMSE: $(result.retained_current_component_scale_optimizer.base_worst_heating_rate_rmse_k_day)",
        "- best exact objective: $(result.retained_current_component_scale_optimizer.best_exact_objective)",
        "- best objective reduction: $(result.retained_current_component_scale_optimizer.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_current_component_scale_optimizer.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_current_component_scale_optimizer.best_worst_surface_forcing_error_w_m2)",
        "- best heating RMSE: $(result.retained_current_component_scale_optimizer.best_worst_heating_rate_rmse_k_day)",
        "- accepted objective: $(result.retained_current_component_scale_optimizer.accepted_objective)",
        "- accepted objective reduction: $(result.retained_current_component_scale_optimizer.accepted_objective_reduction)",
        "- accepted TOA forcing: $(result.retained_current_component_scale_optimizer.accepted_worst_toa_forcing_error_w_m2)",
        "- accepted surface forcing: $(result.retained_current_component_scale_optimizer.accepted_worst_surface_forcing_error_w_m2)",
        "- accepted heating RMSE: $(result.retained_current_component_scale_optimizer.accepted_worst_heating_rate_rmse_k_day)",
        "- accepted: $(result.retained_current_component_scale_optimizer.accepted)",
        "",
        "## Retained Current Component-Scale Optimizer 2",
        "",
        "- present: $(result.retained_current_component_scale_optimizer2.present)",
        "- status: `$(result.retained_current_component_scale_optimizer2.status)`",
        "- residual mode: `$(result.retained_current_component_scale_optimizer2.residual_mode)`",
        "- basis: `$(result.retained_current_component_scale_optimizer2.basis)`",
        "- basis count: $(result.retained_current_component_scale_optimizer2.basis_count)",
        "- surface cap: $(result.retained_current_component_scale_optimizer2.surface_cap_w_m2)",
        "- TOA tolerance: $(result.retained_current_component_scale_optimizer2.toa_tolerance_w_m2)",
        "- minimum objective reduction: $(result.retained_current_component_scale_optimizer2.min_objective_reduction)",
        "- base objective: $(result.retained_current_component_scale_optimizer2.base_objective)",
        "- base TOA forcing: $(result.retained_current_component_scale_optimizer2.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_current_component_scale_optimizer2.base_worst_surface_forcing_error_w_m2)",
        "- base heating RMSE: $(result.retained_current_component_scale_optimizer2.base_worst_heating_rate_rmse_k_day)",
        "- best exact objective: $(result.retained_current_component_scale_optimizer2.best_exact_objective)",
        "- best objective reduction: $(result.retained_current_component_scale_optimizer2.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_current_component_scale_optimizer2.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_current_component_scale_optimizer2.best_worst_surface_forcing_error_w_m2)",
        "- best heating RMSE: $(result.retained_current_component_scale_optimizer2.best_worst_heating_rate_rmse_k_day)",
        "- accepted objective: $(result.retained_current_component_scale_optimizer2.accepted_objective)",
        "- accepted objective reduction: $(result.retained_current_component_scale_optimizer2.accepted_objective_reduction)",
        "- accepted TOA forcing: $(result.retained_current_component_scale_optimizer2.accepted_worst_toa_forcing_error_w_m2)",
        "- accepted surface forcing: $(result.retained_current_component_scale_optimizer2.accepted_worst_surface_forcing_error_w_m2)",
        "- accepted heating RMSE: $(result.retained_current_component_scale_optimizer2.accepted_worst_heating_rate_rmse_k_day)",
        "- accepted: $(result.retained_current_component_scale_optimizer2.accepted)",
        "",
        "## Retained Current Component-Scale Optimizer 3",
        "",
        "- present: $(result.retained_current_component_scale_optimizer3.present)",
        "- status: `$(result.retained_current_component_scale_optimizer3.status)`",
        "- residual mode: `$(result.retained_current_component_scale_optimizer3.residual_mode)`",
        "- basis: `$(result.retained_current_component_scale_optimizer3.basis)`",
        "- basis count: $(result.retained_current_component_scale_optimizer3.basis_count)",
        "- surface cap: $(result.retained_current_component_scale_optimizer3.surface_cap_w_m2)",
        "- TOA tolerance: $(result.retained_current_component_scale_optimizer3.toa_tolerance_w_m2)",
        "- minimum objective reduction: $(result.retained_current_component_scale_optimizer3.min_objective_reduction)",
        "- base objective: $(result.retained_current_component_scale_optimizer3.base_objective)",
        "- base TOA forcing: $(result.retained_current_component_scale_optimizer3.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_current_component_scale_optimizer3.base_worst_surface_forcing_error_w_m2)",
        "- base heating RMSE: $(result.retained_current_component_scale_optimizer3.base_worst_heating_rate_rmse_k_day)",
        "- best exact objective: $(result.retained_current_component_scale_optimizer3.best_exact_objective)",
        "- best objective reduction: $(result.retained_current_component_scale_optimizer3.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_current_component_scale_optimizer3.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_current_component_scale_optimizer3.best_worst_surface_forcing_error_w_m2)",
        "- best heating RMSE: $(result.retained_current_component_scale_optimizer3.best_worst_heating_rate_rmse_k_day)",
        "- accepted objective: $(result.retained_current_component_scale_optimizer3.accepted_objective)",
        "- accepted objective reduction: $(result.retained_current_component_scale_optimizer3.accepted_objective_reduction)",
        "- accepted TOA forcing: $(result.retained_current_component_scale_optimizer3.accepted_worst_toa_forcing_error_w_m2)",
        "- accepted surface forcing: $(result.retained_current_component_scale_optimizer3.accepted_worst_surface_forcing_error_w_m2)",
        "- accepted heating RMSE: $(result.retained_current_component_scale_optimizer3.accepted_worst_heating_rate_rmse_k_day)",
        "- accepted: $(result.retained_current_component_scale_optimizer3.accepted)",
        "",
        "## Retained Current Component-Scale Optimizer 4",
        "",
        "- present: $(result.retained_current_component_scale_optimizer4.present)",
        "- status: `$(result.retained_current_component_scale_optimizer4.status)`",
        "- residual mode: `$(result.retained_current_component_scale_optimizer4.residual_mode)`",
        "- basis: `$(result.retained_current_component_scale_optimizer4.basis)`",
        "- basis count: $(result.retained_current_component_scale_optimizer4.basis_count)",
        "- surface cap: $(result.retained_current_component_scale_optimizer4.surface_cap_w_m2)",
        "- TOA tolerance: $(result.retained_current_component_scale_optimizer4.toa_tolerance_w_m2)",
        "- minimum objective reduction: $(result.retained_current_component_scale_optimizer4.min_objective_reduction)",
        "- base objective: $(result.retained_current_component_scale_optimizer4.base_objective)",
        "- base TOA forcing: $(result.retained_current_component_scale_optimizer4.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_current_component_scale_optimizer4.base_worst_surface_forcing_error_w_m2)",
        "- base heating RMSE: $(result.retained_current_component_scale_optimizer4.base_worst_heating_rate_rmse_k_day)",
        "- best exact objective: $(result.retained_current_component_scale_optimizer4.best_exact_objective)",
        "- best objective reduction: $(result.retained_current_component_scale_optimizer4.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_current_component_scale_optimizer4.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_current_component_scale_optimizer4.best_worst_surface_forcing_error_w_m2)",
        "- best heating RMSE: $(result.retained_current_component_scale_optimizer4.best_worst_heating_rate_rmse_k_day)",
        "- accepted objective: $(result.retained_current_component_scale_optimizer4.accepted_objective)",
        "- accepted objective reduction: $(result.retained_current_component_scale_optimizer4.accepted_objective_reduction)",
        "- accepted TOA forcing: $(result.retained_current_component_scale_optimizer4.accepted_worst_toa_forcing_error_w_m2)",
        "- accepted surface forcing: $(result.retained_current_component_scale_optimizer4.accepted_worst_surface_forcing_error_w_m2)",
        "- accepted heating RMSE: $(result.retained_current_component_scale_optimizer4.accepted_worst_heating_rate_rmse_k_day)",
        "- accepted: $(result.retained_current_component_scale_optimizer4.accepted)",
        "",
        "## Retained Current Pressure-Component Optimizer",
        "",
        "- present: $(result.retained_current_pressure_component_optimizer.present)",
        "- status: `$(result.retained_current_pressure_component_optimizer.status)`",
        "- residual mode: `$(result.retained_current_pressure_component_optimizer.residual_mode)`",
        "- basis: `$(result.retained_current_pressure_component_optimizer.basis)`",
        "- basis count: $(result.retained_current_pressure_component_optimizer.basis_count)",
        "- pressure-band count: $(result.retained_current_pressure_component_optimizer.pressure_band_count)",
        "- surface cap: $(result.retained_current_pressure_component_optimizer.surface_cap_w_m2)",
        "- TOA tolerance: $(result.retained_current_pressure_component_optimizer.toa_tolerance_w_m2)",
        "- minimum objective reduction: $(result.retained_current_pressure_component_optimizer.min_objective_reduction)",
        "- base objective: $(result.retained_current_pressure_component_optimizer.base_objective)",
        "- base TOA forcing: $(result.retained_current_pressure_component_optimizer.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_current_pressure_component_optimizer.base_worst_surface_forcing_error_w_m2)",
        "- base heating RMSE: $(result.retained_current_pressure_component_optimizer.base_worst_heating_rate_rmse_k_day)",
        "- best exact objective: $(result.retained_current_pressure_component_optimizer.best_exact_objective)",
        "- best objective reduction: $(result.retained_current_pressure_component_optimizer.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_current_pressure_component_optimizer.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_current_pressure_component_optimizer.best_worst_surface_forcing_error_w_m2)",
        "- best heating RMSE: $(result.retained_current_pressure_component_optimizer.best_worst_heating_rate_rmse_k_day)",
        "- accepted objective: $(result.retained_current_pressure_component_optimizer.accepted_objective)",
        "- accepted objective reduction: $(result.retained_current_pressure_component_optimizer.accepted_objective_reduction)",
        "- accepted TOA forcing: $(result.retained_current_pressure_component_optimizer.accepted_worst_toa_forcing_error_w_m2)",
        "- accepted surface forcing: $(result.retained_current_pressure_component_optimizer.accepted_worst_surface_forcing_error_w_m2)",
        "- accepted heating RMSE: $(result.retained_current_pressure_component_optimizer.accepted_worst_heating_rate_rmse_k_day)",
        "- accepted: $(result.retained_current_pressure_component_optimizer.accepted)",
        "",
        "## Retained Current Pressure-Component Scan",
        "",
        "- present: $(result.retained_current_pressure_component_scan.present)",
        "- status: `$(result.retained_current_pressure_component_scan.status)`",
        "- residual mode: `$(result.retained_current_pressure_component_scan.residual_mode)`",
        "- basis: `$(result.retained_current_pressure_component_scan.basis)`",
        "- include Rayleigh: $(result.retained_current_pressure_component_scan.include_rayleigh)",
        "- static gas split: $(result.retained_current_pressure_component_scan.static_gas_split)",
        "- selected partition: `$(result.retained_current_pressure_component_scan.selected_partition)`",
        "- selected pressure-band count: $(result.retained_current_pressure_component_scan.selected_pressure_band_count)",
        "- selected basis count: $(result.retained_current_pressure_component_scan.selected_basis_count)",
        "- selected accepted moves: $(result.retained_current_pressure_component_scan.selected_accepted_move_count)",
        "- surface cap: $(result.retained_current_pressure_component_scan.surface_cap_w_m2)",
        "- TOA tolerance: $(result.retained_current_pressure_component_scan.toa_tolerance_w_m2)",
        "- minimum objective reduction: $(result.retained_current_pressure_component_scan.min_objective_reduction)",
        "- base objective: $(result.retained_current_pressure_component_scan.base_objective)",
        "- base TOA forcing: $(result.retained_current_pressure_component_scan.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_current_pressure_component_scan.base_worst_surface_forcing_error_w_m2)",
        "- base heating RMSE: $(result.retained_current_pressure_component_scan.base_worst_heating_rate_rmse_k_day)",
        "- selected objective: $(result.retained_current_pressure_component_scan.selected_objective)",
        "- selected TOA forcing: $(result.retained_current_pressure_component_scan.selected_worst_toa_forcing_error_w_m2)",
        "- selected surface forcing: $(result.retained_current_pressure_component_scan.selected_worst_surface_forcing_error_w_m2)",
        "- selected heating RMSE: $(result.retained_current_pressure_component_scan.selected_worst_heating_rate_rmse_k_day)",
        "- accepted: $(result.retained_current_pressure_component_scan.accepted)",
        "",
        "## Retained Current Pressure-Component Rayleigh Scan",
        "",
        "- present: $(result.retained_current_pressure_component_rayleigh_scan.present)",
        "- status: `$(result.retained_current_pressure_component_rayleigh_scan.status)`",
        "- residual mode: `$(result.retained_current_pressure_component_rayleigh_scan.residual_mode)`",
        "- basis: `$(result.retained_current_pressure_component_rayleigh_scan.basis)`",
        "- include Rayleigh: $(result.retained_current_pressure_component_rayleigh_scan.include_rayleigh)",
        "- static gas split: $(result.retained_current_pressure_component_rayleigh_scan.static_gas_split)",
        "- selected partition: `$(result.retained_current_pressure_component_rayleigh_scan.selected_partition)`",
        "- selected pressure-band count: $(result.retained_current_pressure_component_rayleigh_scan.selected_pressure_band_count)",
        "- selected basis count: $(result.retained_current_pressure_component_rayleigh_scan.selected_basis_count)",
        "- selected accepted moves: $(result.retained_current_pressure_component_rayleigh_scan.selected_accepted_move_count)",
        "- surface cap: $(result.retained_current_pressure_component_rayleigh_scan.surface_cap_w_m2)",
        "- selected objective: $(result.retained_current_pressure_component_rayleigh_scan.selected_objective)",
        "- selected TOA forcing: $(result.retained_current_pressure_component_rayleigh_scan.selected_worst_toa_forcing_error_w_m2)",
        "- selected surface forcing: $(result.retained_current_pressure_component_rayleigh_scan.selected_worst_surface_forcing_error_w_m2)",
        "- selected heating RMSE: $(result.retained_current_pressure_component_rayleigh_scan.selected_worst_heating_rate_rmse_k_day)",
        "- accepted: $(result.retained_current_pressure_component_rayleigh_scan.accepted)",
        "",
        "## Retained Current Pressure-Component Surface-Guard Scan",
        "",
        "- present: $(result.retained_current_pressure_component_surface_guard_scan.present)",
        "- status: `$(result.retained_current_pressure_component_surface_guard_scan.status)`",
        "- residual mode: `$(result.retained_current_pressure_component_surface_guard_scan.residual_mode)`",
        "- basis: `$(result.retained_current_pressure_component_surface_guard_scan.basis)`",
        "- include Rayleigh: $(result.retained_current_pressure_component_surface_guard_scan.include_rayleigh)",
        "- static gas split: $(result.retained_current_pressure_component_surface_guard_scan.static_gas_split)",
        "- selected partition: `$(result.retained_current_pressure_component_surface_guard_scan.selected_partition)`",
        "- selected pressure-band count: $(result.retained_current_pressure_component_surface_guard_scan.selected_pressure_band_count)",
        "- selected basis count: $(result.retained_current_pressure_component_surface_guard_scan.selected_basis_count)",
        "- selected accepted moves: $(result.retained_current_pressure_component_surface_guard_scan.selected_accepted_move_count)",
        "- surface cap: $(result.retained_current_pressure_component_surface_guard_scan.surface_cap_w_m2)",
        "- selected objective: $(result.retained_current_pressure_component_surface_guard_scan.selected_objective)",
        "- selected TOA forcing: $(result.retained_current_pressure_component_surface_guard_scan.selected_worst_toa_forcing_error_w_m2)",
        "- selected surface forcing: $(result.retained_current_pressure_component_surface_guard_scan.selected_worst_surface_forcing_error_w_m2)",
        "- selected heating RMSE: $(result.retained_current_pressure_component_surface_guard_scan.selected_worst_heating_rate_rmse_k_day)",
        "- accepted: $(result.retained_current_pressure_component_surface_guard_scan.accepted)",
        "",
        "## Retained Current Gas-Pressure Component Scan",
        "",
        "- present: $(result.retained_current_gas_pressure_component_scan.present)",
        "- status: `$(result.retained_current_gas_pressure_component_scan.status)`",
        "- residual mode: `$(result.retained_current_gas_pressure_component_scan.residual_mode)`",
        "- basis: `$(result.retained_current_gas_pressure_component_scan.basis)`",
        "- include Rayleigh: $(result.retained_current_gas_pressure_component_scan.include_rayleigh)",
        "- static gas split: $(result.retained_current_gas_pressure_component_scan.static_gas_split)",
        "- selected partition: `$(result.retained_current_gas_pressure_component_scan.selected_partition)`",
        "- selected pressure-band count: $(result.retained_current_gas_pressure_component_scan.selected_pressure_band_count)",
        "- selected basis count: $(result.retained_current_gas_pressure_component_scan.selected_basis_count)",
        "- selected accepted moves: $(result.retained_current_gas_pressure_component_scan.selected_accepted_move_count)",
        "- surface cap: $(result.retained_current_gas_pressure_component_scan.surface_cap_w_m2)",
        "- selected objective: $(result.retained_current_gas_pressure_component_scan.selected_objective)",
        "- selected TOA forcing: $(result.retained_current_gas_pressure_component_scan.selected_worst_toa_forcing_error_w_m2)",
        "- selected surface forcing: $(result.retained_current_gas_pressure_component_scan.selected_worst_surface_forcing_error_w_m2)",
        "- selected heating RMSE: $(result.retained_current_gas_pressure_component_scan.selected_worst_heating_rate_rmse_k_day)",
        "- accepted: $(result.retained_current_gas_pressure_component_scan.accepted)",
        "",
        "## Retained Current Gas-Pressure Component Continuation Scan",
        "",
        "- present: $(result.retained_current_gas_pressure_component_continuation_scan.present)",
        "- status: `$(result.retained_current_gas_pressure_component_continuation_scan.status)`",
        "- residual mode: `$(result.retained_current_gas_pressure_component_continuation_scan.residual_mode)`",
        "- basis: `$(result.retained_current_gas_pressure_component_continuation_scan.basis)`",
        "- include Rayleigh: $(result.retained_current_gas_pressure_component_continuation_scan.include_rayleigh)",
        "- static gas split: $(result.retained_current_gas_pressure_component_continuation_scan.static_gas_split)",
        "- selected partition: `$(result.retained_current_gas_pressure_component_continuation_scan.selected_partition)`",
        "- selected pressure-band count: $(result.retained_current_gas_pressure_component_continuation_scan.selected_pressure_band_count)",
        "- selected basis count: $(result.retained_current_gas_pressure_component_continuation_scan.selected_basis_count)",
        "- selected accepted moves: $(result.retained_current_gas_pressure_component_continuation_scan.selected_accepted_move_count)",
        "- surface cap: $(result.retained_current_gas_pressure_component_continuation_scan.surface_cap_w_m2)",
        "- selected objective: $(result.retained_current_gas_pressure_component_continuation_scan.selected_objective)",
        "- selected TOA forcing: $(result.retained_current_gas_pressure_component_continuation_scan.selected_worst_toa_forcing_error_w_m2)",
        "- selected surface forcing: $(result.retained_current_gas_pressure_component_continuation_scan.selected_worst_surface_forcing_error_w_m2)",
        "- selected heating RMSE: $(result.retained_current_gas_pressure_component_continuation_scan.selected_worst_heating_rate_rmse_k_day)",
        "- accepted: $(result.retained_current_gas_pressure_component_continuation_scan.accepted)",
        "",
        "## Retained Current Weighted Gas-Pressure Component Continuation Scan",
        "",
        "- present: $(result.retained_current_gas_pressure_component_continuation2_scan.present)",
        "- status: `$(result.retained_current_gas_pressure_component_continuation2_scan.status)`",
        "- residual mode: `$(result.retained_current_gas_pressure_component_continuation2_scan.residual_mode)`",
        "- basis: `$(result.retained_current_gas_pressure_component_continuation2_scan.basis)`",
        "- include Rayleigh: $(result.retained_current_gas_pressure_component_continuation2_scan.include_rayleigh)",
        "- static gas split: $(result.retained_current_gas_pressure_component_continuation2_scan.static_gas_split)",
        "- heating residual weight: $(result.retained_current_gas_pressure_component_continuation2_scan.heating_weight)",
        "- boundary residual weight: $(result.retained_current_gas_pressure_component_continuation2_scan.boundary_weight)",
        "- selected partition: `$(result.retained_current_gas_pressure_component_continuation2_scan.selected_partition)`",
        "- selected pressure-band count: $(result.retained_current_gas_pressure_component_continuation2_scan.selected_pressure_band_count)",
        "- selected basis count: $(result.retained_current_gas_pressure_component_continuation2_scan.selected_basis_count)",
        "- selected accepted moves: $(result.retained_current_gas_pressure_component_continuation2_scan.selected_accepted_move_count)",
        "- surface cap: $(result.retained_current_gas_pressure_component_continuation2_scan.surface_cap_w_m2)",
        "- selected objective: $(result.retained_current_gas_pressure_component_continuation2_scan.selected_objective)",
        "- selected TOA forcing: $(result.retained_current_gas_pressure_component_continuation2_scan.selected_worst_toa_forcing_error_w_m2)",
        "- selected surface forcing: $(result.retained_current_gas_pressure_component_continuation2_scan.selected_worst_surface_forcing_error_w_m2)",
        "- selected heating RMSE: $(result.retained_current_gas_pressure_component_continuation2_scan.selected_worst_heating_rate_rmse_k_day)",
        "- accepted: $(result.retained_current_gas_pressure_component_continuation2_scan.accepted)",
        "",
        "## Retained Current High-Weight Gas-Pressure Component Continuation Scan",
        "",
        "- present: $(result.retained_current_gas_pressure_component_continuation3_scan.present)",
        "- status: `$(result.retained_current_gas_pressure_component_continuation3_scan.status)`",
        "- residual mode: `$(result.retained_current_gas_pressure_component_continuation3_scan.residual_mode)`",
        "- basis: `$(result.retained_current_gas_pressure_component_continuation3_scan.basis)`",
        "- include Rayleigh: $(result.retained_current_gas_pressure_component_continuation3_scan.include_rayleigh)",
        "- static gas split: $(result.retained_current_gas_pressure_component_continuation3_scan.static_gas_split)",
        "- heating residual weight: $(result.retained_current_gas_pressure_component_continuation3_scan.heating_weight)",
        "- boundary residual weight: $(result.retained_current_gas_pressure_component_continuation3_scan.boundary_weight)",
        "- selected partition: `$(result.retained_current_gas_pressure_component_continuation3_scan.selected_partition)`",
        "- selected pressure-band count: $(result.retained_current_gas_pressure_component_continuation3_scan.selected_pressure_band_count)",
        "- selected basis count: $(result.retained_current_gas_pressure_component_continuation3_scan.selected_basis_count)",
        "- selected accepted moves: $(result.retained_current_gas_pressure_component_continuation3_scan.selected_accepted_move_count)",
        "- surface cap: $(result.retained_current_gas_pressure_component_continuation3_scan.surface_cap_w_m2)",
        "- selected objective: $(result.retained_current_gas_pressure_component_continuation3_scan.selected_objective)",
        "- selected TOA forcing: $(result.retained_current_gas_pressure_component_continuation3_scan.selected_worst_toa_forcing_error_w_m2)",
        "- selected surface forcing: $(result.retained_current_gas_pressure_component_continuation3_scan.selected_worst_surface_forcing_error_w_m2)",
        "- selected heating RMSE: $(result.retained_current_gas_pressure_component_continuation3_scan.selected_worst_heating_rate_rmse_k_day)",
        "- accepted: $(result.retained_current_gas_pressure_component_continuation3_scan.accepted)",
        "",
        "## Broader Support-Plus-Refit Search",
        "",
        "- present: $(result.broader_support_refit_search.present)",
        "- status: `$(result.broader_support_refit_search.status)`",
        "- objective target: $(result.broader_support_refit_search.objective_target)",
        "- current objective: $(result.broader_support_refit_search.current_objective)",
        "- best objective: $(result.broader_support_refit_search.best_objective)",
        "- best objective reduction: $(result.broader_support_refit_search.best_objective_reduction)",
        "- radius: $(result.broader_support_refit_search.radius)",
        "- prefilter candidates: $(result.broader_support_refit_search.prefilter_evaluated_count) / $(result.broader_support_refit_search.total_neighbor_candidate_count)",
        "- refit candidates: $(result.broader_support_refit_search.evaluated_candidate_count) / $(result.broader_support_refit_search.total_neighbor_candidate_count)",
        "- best move: g$(result.broader_support_refit_search.best_removed_gpoint) -> g$(result.broader_support_refit_search.best_added_gpoint)",
        "- passed hard objective: $(result.broader_support_refit_search.best_passed_hard_objective)",
        "",
        "## Nonlocal Support-Plus-Refit Search",
        "",
        "- present: $(result.nonlocal_support_refit_search.present)",
        "- status: `$(result.nonlocal_support_refit_search.status)`",
        "- objective target: $(result.nonlocal_support_refit_search.objective_target)",
        "- current objective: $(result.nonlocal_support_refit_search.current_objective)",
        "- best objective: $(result.nonlocal_support_refit_search.best_objective)",
        "- best objective reduction: $(result.nonlocal_support_refit_search.best_objective_reduction)",
        "- candidates: $(result.nonlocal_support_refit_search.evaluated_candidate_count) / $(result.nonlocal_support_refit_search.total_candidate_count)",
        "- best label: `$(result.nonlocal_support_refit_search.best_label)`",
        "- passed hard objective: $(result.nonlocal_support_refit_search.best_passed_hard_objective)",
        "",
        "## Retained Capped Table Optimizer",
        "",
        "- present: $(result.retained_capped_table_optimizer.present)",
        "- status: `$(result.retained_capped_table_optimizer.status)`",
        "- candidate scope: `$(result.retained_capped_table_optimizer.candidate_scope)`",
        "- residual mode: `$(result.retained_capped_table_optimizer.residual_mode)`",
        "- surface cap: $(result.retained_capped_table_optimizer.surface_cap_w_m2)",
        "- TOA tolerance: $(result.retained_capped_table_optimizer.toa_tolerance_w_m2)",
        "- candidates: $(result.retained_capped_table_optimizer.candidate_count)",
        "- base objective: $(result.retained_capped_table_optimizer.base_objective)",
        "- base TOA forcing: $(result.retained_capped_table_optimizer.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_capped_table_optimizer.base_worst_surface_forcing_error_w_m2)",
        "- cap-safe row present: $(result.retained_capped_table_optimizer.cap_safe_present)",
        "- best cap-safe objective: $(metric_or_na(result.retained_capped_table_optimizer.best_cap_safe_exact_objective))",
        "- best cap-safe TOA forcing: $(metric_or_na(result.retained_capped_table_optimizer.best_cap_safe_toa_forcing_error_w_m2))",
        "- best cap-safe surface forcing: $(metric_or_na(result.retained_capped_table_optimizer.best_cap_safe_surface_forcing_error_w_m2))",
        "- best overall objective: $(metric_or_na(result.retained_capped_table_optimizer.best_overall_exact_objective))",
        "- best overall TOA forcing: $(metric_or_na(result.retained_capped_table_optimizer.best_overall_toa_forcing_error_w_m2))",
        "- best overall surface forcing: $(metric_or_na(result.retained_capped_table_optimizer.best_overall_surface_forcing_error_w_m2))",
        "- best unsafe objective: $(metric_or_na(result.retained_capped_table_optimizer.best_unsafe_exact_objective))",
        "- best unsafe TOA forcing: $(metric_or_na(result.retained_capped_table_optimizer.best_unsafe_toa_forcing_error_w_m2))",
        "- best unsafe surface forcing: $(metric_or_na(result.retained_capped_table_optimizer.best_unsafe_surface_forcing_error_w_m2))",
        "- accepted: $(result.retained_capped_table_optimizer.accepted)",
        "- accepted moves: $(result.retained_capped_table_optimizer.accepted_move_count)",
        "",
        "## Retained Capped Table Continuation",
        "",
        "- present: $(result.retained_capped_table_continuation.present)",
        "- status: `$(result.retained_capped_table_continuation.status)`",
        "- candidate scope: `$(result.retained_capped_table_continuation.candidate_scope)`",
        "- residual mode: `$(result.retained_capped_table_continuation.residual_mode)`",
        "- surface cap: $(result.retained_capped_table_continuation.surface_cap_w_m2)",
        "- TOA tolerance: $(result.retained_capped_table_continuation.toa_tolerance_w_m2)",
        "- base capped moves: $(result.retained_capped_table_continuation.base_capped_move_count)",
        "- candidates: $(result.retained_capped_table_continuation.candidate_count)",
        "- base objective: $(result.retained_capped_table_continuation.base_objective)",
        "- base TOA forcing: $(result.retained_capped_table_continuation.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_capped_table_continuation.base_worst_surface_forcing_error_w_m2)",
        "- cap-safe row present: $(result.retained_capped_table_continuation.cap_safe_present)",
        "- best cap-safe objective: $(metric_or_na(result.retained_capped_table_continuation.best_cap_safe_exact_objective))",
        "- best cap-safe TOA forcing: $(metric_or_na(result.retained_capped_table_continuation.best_cap_safe_toa_forcing_error_w_m2))",
        "- best cap-safe surface forcing: $(metric_or_na(result.retained_capped_table_continuation.best_cap_safe_surface_forcing_error_w_m2))",
        "- best overall objective: $(metric_or_na(result.retained_capped_table_continuation.best_overall_exact_objective))",
        "- best overall TOA forcing: $(metric_or_na(result.retained_capped_table_continuation.best_overall_toa_forcing_error_w_m2))",
        "- best overall surface forcing: $(metric_or_na(result.retained_capped_table_continuation.best_overall_surface_forcing_error_w_m2))",
        "- best unsafe objective: $(metric_or_na(result.retained_capped_table_continuation.best_unsafe_exact_objective))",
        "- best unsafe TOA forcing: $(metric_or_na(result.retained_capped_table_continuation.best_unsafe_toa_forcing_error_w_m2))",
        "- best unsafe surface forcing: $(metric_or_na(result.retained_capped_table_continuation.best_unsafe_surface_forcing_error_w_m2))",
        "- accepted: $(result.retained_capped_table_continuation.accepted)",
        "- accepted moves: $(result.retained_capped_table_continuation.accepted_move_count)",
        "",
        "## Retained Post-Capped Weight Refit",
        "",
        "- present: $(result.retained_post_capped_weight_refit.present)",
        "- status: `$(result.retained_post_capped_weight_refit.status)`",
        "- iterations: $(result.retained_post_capped_weight_refit.iterations)",
        "- base objective: $(result.retained_post_capped_weight_refit.base_objective)",
        "- refit objective: $(result.retained_post_capped_weight_refit.refit_objective)",
        "- objective reduction: $(result.retained_post_capped_weight_refit.objective_reduction)",
        "- base TOA forcing: $(result.retained_post_capped_weight_refit.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_post_capped_weight_refit.base_worst_surface_forcing_error_w_m2)",
        "- refit TOA forcing: $(result.retained_post_capped_weight_refit.refit_worst_toa_forcing_error_w_m2)",
        "- refit surface forcing: $(result.retained_post_capped_weight_refit.refit_worst_surface_forcing_error_w_m2)",
        "- accepted: $(result.retained_post_capped_weight_refit.accepted)",
        "- max abs weight delta: $(result.retained_post_capped_weight_refit.max_abs_weight_delta)",
        "",
        "## Retained Post-Weight Surface Table Refit",
        "",
        "- present: $(result.retained_post_weight_surface_table_refit.present)",
        "- status: `$(result.retained_post_weight_surface_table_refit.status)`",
        "- residual mode: `$(result.retained_post_weight_surface_table_refit.residual_mode)`",
        "- candidates: $(result.retained_post_weight_surface_table_refit.candidate_count)",
        "- base objective: $(result.retained_post_weight_surface_table_refit.base_objective)",
        "- best objective: $(result.retained_post_weight_surface_table_refit.best_exact_objective)",
        "- best objective reduction: $(result.retained_post_weight_surface_table_refit.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_post_weight_surface_table_refit.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_post_weight_surface_table_refit.best_worst_surface_forcing_error_w_m2)",
        "- accepted: $(result.retained_post_weight_surface_table_refit.accepted)",
        "- accepted moves: $(result.retained_post_weight_surface_table_refit.accepted_move_count)",
        "",
        "## Retained Post-Weight Bounded Weight Refit",
        "",
        "- present: $(result.retained_post_weight_bounded_weight_refit.present)",
        "- status: `$(result.retained_post_weight_bounded_weight_refit.status)`",
        "- iterations: $(result.retained_post_weight_bounded_weight_refit.iterations)",
        "- surface cap: $(result.retained_post_weight_bounded_weight_refit.surface_cap_w_m2)",
        "- base objective: $(result.retained_post_weight_bounded_weight_refit.base_objective)",
        "- refit objective: $(result.retained_post_weight_bounded_weight_refit.refit_objective)",
        "- objective reduction: $(result.retained_post_weight_bounded_weight_refit.objective_reduction)",
        "- base TOA forcing: $(result.retained_post_weight_bounded_weight_refit.base_worst_toa_forcing_error_w_m2)",
        "- base surface forcing: $(result.retained_post_weight_bounded_weight_refit.base_worst_surface_forcing_error_w_m2)",
        "- refit TOA forcing: $(result.retained_post_weight_bounded_weight_refit.refit_worst_toa_forcing_error_w_m2)",
        "- refit surface forcing: $(result.retained_post_weight_bounded_weight_refit.refit_worst_surface_forcing_error_w_m2)",
        "- accepted: $(result.retained_post_weight_bounded_weight_refit.accepted)",
        "- max abs weight delta: $(result.retained_post_weight_bounded_weight_refit.max_abs_weight_delta)",
        "",
        "## Retained Table Coordinate Pareto Scan",
        "",
        "- present: $(result.retained_table_coordinate_pareto_scan.present)",
        "- status: `$(result.retained_table_coordinate_pareto_scan.status)`",
        "- candidates: $(result.retained_table_coordinate_pareto_scan.candidate_count)",
        "- trials: $(result.retained_table_coordinate_pareto_scan.trial_count)",
        "- base objective: $(result.retained_table_coordinate_pareto_scan.base_objective)",
        "- best objective: $(result.retained_table_coordinate_pareto_scan.best_objective)",
        "- best objective reduction: $(result.retained_table_coordinate_pareto_scan.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_table_coordinate_pareto_scan.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_table_coordinate_pareto_scan.best_worst_surface_forcing_error_w_m2)",
        "- best component: `$(result.retained_table_coordinate_pareto_scan.best_component)`",
        "- best move: g$(result.retained_table_coordinate_pareto_scan.best_gpoint) $(result.retained_table_coordinate_pareto_scan.best_direction) $(result.retained_table_coordinate_pareto_scan.best_step)",
        "- best TOA regressed: $(result.retained_table_coordinate_pareto_scan.best_toa_regressed)",
        "- best surface regressed: $(result.retained_table_coordinate_pareto_scan.best_surface_regressed)",
        "- any Pareto-safe: $(result.retained_table_coordinate_pareto_scan.any_pareto_safe)",
        "- best Pareto-safe objective: $(result.retained_table_coordinate_pareto_scan.best_safe_objective)",
        "",
        "## Retained Objective-Probe Expansion",
        "",
        "- present: $(result.retained_objective_probe_expansion.present)",
        "- status: `$(result.retained_objective_probe_expansion.status)`",
        "- configurations: $(result.retained_objective_probe_expansion.config_count)",
        "- best label: `$(result.retained_objective_probe_expansion.best_label)`",
        "- best exact objective: $(result.retained_objective_probe_expansion.best_exact_objective)",
        "- best objective reduction: $(result.retained_objective_probe_expansion.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_objective_probe_expansion.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_objective_probe_expansion.best_worst_surface_forcing_error_w_m2)",
        "- any accepted: $(result.retained_objective_probe_expansion.any_accepted)",
        "",
        "## Retained Objective-Probe Expansion 2",
        "",
        "- present: $(result.retained_objective_probe_expansion2.present)",
        "- status: `$(result.retained_objective_probe_expansion2.status)`",
        "- configurations: $(result.retained_objective_probe_expansion2.config_count)",
        "- best label: `$(result.retained_objective_probe_expansion2.best_label)`",
        "- best exact objective: $(result.retained_objective_probe_expansion2.best_exact_objective)",
        "- best objective reduction: $(result.retained_objective_probe_expansion2.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_objective_probe_expansion2.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_objective_probe_expansion2.best_worst_surface_forcing_error_w_m2)",
        "- any accepted: $(result.retained_objective_probe_expansion2.any_accepted)",
        "",
        "## Retained Objective-Probe Expansion 3",
        "",
        "- present: $(result.retained_objective_probe_expansion3.present)",
        "- status: `$(result.retained_objective_probe_expansion3.status)`",
        "- configurations: $(result.retained_objective_probe_expansion3.config_count)",
        "- best label: `$(result.retained_objective_probe_expansion3.best_label)`",
        "- best exact objective: $(result.retained_objective_probe_expansion3.best_exact_objective)",
        "- best objective reduction: $(result.retained_objective_probe_expansion3.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_objective_probe_expansion3.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_objective_probe_expansion3.best_worst_surface_forcing_error_w_m2)",
        "- any accepted: $(result.retained_objective_probe_expansion3.any_accepted)",
        "",
        "## Retained Objective-Probe Expansion 4",
        "",
        "- present: $(result.retained_objective_probe_expansion4.present)",
        "- status: `$(result.retained_objective_probe_expansion4.status)`",
        "- configurations: $(result.retained_objective_probe_expansion4.config_count)",
        "- best label: `$(result.retained_objective_probe_expansion4.best_label)`",
        "- best exact objective: $(result.retained_objective_probe_expansion4.best_exact_objective)",
        "- best objective reduction: $(result.retained_objective_probe_expansion4.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_objective_probe_expansion4.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_objective_probe_expansion4.best_worst_surface_forcing_error_w_m2)",
        "- any accepted: $(result.retained_objective_probe_expansion4.any_accepted)",
        "",
        "## Retained Surface-Probe Expansion",
        "",
        "- present: $(result.retained_surface_probe_expansion.present)",
        "- status: `$(result.retained_surface_probe_expansion.status)`",
        "- configurations: $(result.retained_surface_probe_expansion.config_count)",
        "- best label: `$(result.retained_surface_probe_expansion.best_label)`",
        "- best exact objective: $(result.retained_surface_probe_expansion.best_exact_objective)",
        "- best objective reduction: $(result.retained_surface_probe_expansion.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_surface_probe_expansion.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_surface_probe_expansion.best_worst_surface_forcing_error_w_m2)",
        "- any accepted: $(result.retained_surface_probe_expansion.any_accepted)",
        "",
        "## Retained Surface-Probe Expansion 2",
        "",
        "- present: $(result.retained_surface_probe_expansion2.present)",
        "- status: `$(result.retained_surface_probe_expansion2.status)`",
        "- configurations: $(result.retained_surface_probe_expansion2.config_count)",
        "- best label: `$(result.retained_surface_probe_expansion2.best_label)`",
        "- best exact objective: $(result.retained_surface_probe_expansion2.best_exact_objective)",
        "- best objective reduction: $(result.retained_surface_probe_expansion2.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_surface_probe_expansion2.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_surface_probe_expansion2.best_worst_surface_forcing_error_w_m2)",
        "- any accepted: $(result.retained_surface_probe_expansion2.any_accepted)",
        "",
        "## Retained Surface-Probe Expansion 3",
        "",
        "- present: $(result.retained_surface_probe_expansion3.present)",
        "- status: `$(result.retained_surface_probe_expansion3.status)`",
        "- configurations: $(result.retained_surface_probe_expansion3.config_count)",
        "- best label: `$(result.retained_surface_probe_expansion3.best_label)`",
        "- best exact objective: $(result.retained_surface_probe_expansion3.best_exact_objective)",
        "- best objective reduction: $(result.retained_surface_probe_expansion3.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_surface_probe_expansion3.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_surface_probe_expansion3.best_worst_surface_forcing_error_w_m2)",
        "- any accepted: $(result.retained_surface_probe_expansion3.any_accepted)",
        "",
        "## Retained Boundary-Probe Expansion",
        "",
        "- present: $(result.retained_boundary_probe_expansion.present)",
        "- status: `$(result.retained_boundary_probe_expansion.status)`",
        "- configurations: $(result.retained_boundary_probe_expansion.config_count)",
        "- best label: `$(result.retained_boundary_probe_expansion.best_label)`",
        "- best exact objective: $(result.retained_boundary_probe_expansion.best_exact_objective)",
        "- best objective reduction: $(result.retained_boundary_probe_expansion.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_boundary_probe_expansion.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_boundary_probe_expansion.best_worst_surface_forcing_error_w_m2)",
        "- any accepted: $(result.retained_boundary_probe_expansion.any_accepted)",
        "",
        "## Retained TOA-Probe Expansion",
        "",
        "- present: $(result.retained_toa_probe_expansion.present)",
        "- status: `$(result.retained_toa_probe_expansion.status)`",
        "- configurations: $(result.retained_toa_probe_expansion.config_count)",
        "- best label: `$(result.retained_toa_probe_expansion.best_label)`",
        "- best exact objective: $(result.retained_toa_probe_expansion.best_exact_objective)",
        "- best objective reduction: $(result.retained_toa_probe_expansion.best_objective_reduction)",
        "- best TOA forcing: $(result.retained_toa_probe_expansion.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.retained_toa_probe_expansion.best_worst_surface_forcing_error_w_m2)",
        "- any Pareto-safe: $(result.retained_toa_probe_expansion.any_pareto_safe)",
        "- any accepted: $(result.retained_toa_probe_expansion.any_accepted)",
        "",
        "## Boundary-Table Triple Coordinate Scan",
        "",
        "- present: $(result.boundary_table_triple_coordinate_scan.present)",
        "- status: `$(result.boundary_table_triple_coordinate_scan.status)`",
        "- single trials: $(result.boundary_table_triple_coordinate_scan.single_trial_count)",
        "- selected singles: $(result.boundary_table_triple_coordinate_scan.selected_single_count)",
        "- triple trials: $(result.boundary_table_triple_coordinate_scan.triple_trial_count)",
        "- base objective: $(result.boundary_table_triple_coordinate_scan.base_objective)",
        "- best objective: $(result.boundary_table_triple_coordinate_scan.best_objective)",
        "- best objective reduction: $(result.boundary_table_triple_coordinate_scan.best_objective_reduction)",
        "- best TOA forcing: $(result.boundary_table_triple_coordinate_scan.best_worst_toa_forcing_error_w_m2)",
        "- best surface forcing: $(result.boundary_table_triple_coordinate_scan.best_worst_surface_forcing_error_w_m2)",
        "- accepted: $(result.boundary_table_triple_coordinate_scan.accepted)",
        "",
        "## Next Required Work",
        "",
        result.next_required_work,
    ])
    return join(lines, "\n") * "\n"
end

function reduced_gap_report()
    isfile(REDUCED_ACCURACY_MD) ||
        error("missing reduced accuracy report: $REDUCED_ACCURACY_MD")
    rows = table_rows(read(REDUCED_ACCURACY_MD, String))
    isempty(rows) && error("no reduced accuracy table rows found")
    reduced_rows = filter(row -> row.ng_sw < 32, rows)
    full_rows = filter(row -> row.ng_sw == 32, rows)
    passing_reduced = filter(row -> row.passed, reduced_rows)
    best_reduced = isempty(reduced_rows) ? nothing :
        argmin(row -> max(row.toa_forcing_error_w_m2,
                          row.surface_forcing_error_w_m2),
               reduced_rows)
    status = isempty(passing_reduced) ? "reduced_shortwave_blocked" : "reduced_shortwave_passed"
    conclusion = isempty(passing_reduced) ?
        "The full 32-g shortwave official ecCKD path passes, but every tested reduced shortwave strategy fails the hard forcing threshold. Simple g-point selection, larger 20/24/28/30-term reduced sets with refit weights, weighted/coefficient-averaged bins, flux-profile-paired bins, grouped-quadrature searches, fitted weights, projected p-norm and max-norm simplex weights, sparse hard-gate flux-basis support search, scalar coefficient tuning, pressure-limited and global local active-entry scaling, grouped local active-entry blocks, pressure-limited and global linearized active-entry refits, grouped global linearized active-entry refits, post-table weight refits, exact post-table weight coordinate refits, joint weight/block linearized refits, boundary-column local entry scans, boundary-column block scans, gas-specific pressure-band scans and linearized refits, slot-blend table/quadrature deformations, radius-2 slot-inherited topology swaps, boundary-table single-slot topology replacements with and without hard-gate weight refits, boundary-table exact coordinate scans, boundary-table exact pair-coordinate scans, boundary-table exact coordinate descent, boundary-table exact triple-coordinate scans, and the first bounded multi-parameter constrained active-entry table optimizer have been ruled out as sufficient for the current reference set; the accepted local moves are retained but remain far above threshold." :
        "At least one reduced shortwave strategy passes the hard forcing threshold."
    next_required_work = isempty(passing_reduced) ?
        "Use `validation/reduced_ecckd_optimization_preflight.jl` as the executable starting point for a real reduced shortwave optimization/generation workflow. The workflow must drive the official ecCKD normalized hard-gate objective to <= 1, then regenerate `validation/results/reduced_ecckd_accuracy.*` and the Breeze reduced Pareto artifacts." :
        "Promote the passing reduced model into the Breeze Pareto and H100 production benchmark path."
    optimization = optimization_summary()
    coefficient_continuation = coefficient_continuation_summary()
    subset_search = subset_search_summary()
    optical_depth_fit = optical_depth_fit_summary()
    size_weight_refit = size_weight_refit_summary()
    leave_one_out_scan = leave_one_out_scan_summary()
    leave_one_out_weight_refit = leave_one_out_weight_refit_summary()
    importance_group_scan = importance_group_scan_summary()
    support_swap_scan = support_swap_scan_summary()
    support_swap_continuation_scan = support_swap_continuation_scan_summary()
    support_expansion_scan = support_expansion_scan_summary()
    support_expansion_refit_scan = support_expansion_refit_scan_summary()
    random_support_search = random_support_search_summary()
    current_metric_breakdown = current_metric_breakdown_summary()
    broader_support_refit_search = broader_support_refit_search_summary()
    nonlocal_support_refit_search = nonlocal_support_refit_search_summary()
    reduced_acceptance_decision = reduced_acceptance_decision_summary(
        current_metric_breakdown,
        random_support_search,
        support_swap_scan,
        support_swap_continuation_scan,
        support_expansion_scan,
        support_expansion_refit_scan,
        broader_support_refit_search,
        nonlocal_support_refit_search,
    )
    pressure_band_refinement = pressure_band_refinement_summary()
    targeted_entry = targeted_entry_summary()
    global_entry = global_entry_summary()
    global_block_entry = global_block_entry_summary()
    global_block_linearized_entry = global_block_linearized_entry_summary()
    linearized_entry = linearized_entry_summary()
    global_linearized_entry = global_linearized_entry_summary()
    topology_slot = topology_slot_summary()
    post_table_weight = post_table_weight_summary()
    exact_weight_refit = exact_weight_refit_summary()
    joint_weight_block_refit = joint_weight_block_refit_summary()
    boundary_column_refinement = boundary_column_refinement_summary()
    slot_blend_refinement = slot_blend_refinement_summary()
    pair_slot_blend_refinement = pair_slot_blend_refinement_summary()
    slot_blend_linearized = slot_blend_linearized_summary()
    post_slot_weight_refit = post_slot_weight_refit_summary()
    boundary_column_block_refinement = boundary_column_block_refinement_summary()
    gas_pressure_band_refinement = gas_pressure_band_refinement_summary()
    gas_pressure_band_linearized = gas_pressure_band_linearized_summary()
    flux_pair_bins = flux_pair_bins_summary()
    grouped_quadrature_search = grouped_quadrature_search_summary()
    grouped_quadrature_weight_refit = grouped_quadrature_weight_refit_summary()
    weight_maxnorm_refit = weight_maxnorm_refit_summary()
    constrained_table_optimizer = constrained_table_optimizer_summary()
    topology_constrained_optimizer = topology_constrained_optimizer_summary()
    post_constrained_weight_refit = post_constrained_weight_refit_summary()
    post_constrained_boundary_weight_refit =
        post_constrained_boundary_weight_refit_summary()
    hardgate_subset_search = hardgate_subset_search_summary()
    boundary_topology_replacement = boundary_topology_replacement_summary()
    boundary_topology_weight_refit = boundary_topology_weight_refit_summary()
    boundary_table_coordinate_scan = boundary_table_coordinate_scan_summary()
    boundary_table_pair_coordinate_scan = boundary_table_pair_coordinate_scan_summary()
    boundary_table_coordinate_descent = boundary_table_coordinate_descent_summary()
    boundary_table_continuation_optimizer =
        boundary_table_continuation_optimizer_summary()
    component_scale_refit = component_scale_refit_summary()
    pressure_component_scale_refit = pressure_component_scale_refit_summary()
    temperature_component_scale_refit = temperature_component_scale_refit_summary()
    h2o_component_scale_refit = h2o_component_scale_refit_summary()
    gas_component_scale_refit = gas_component_scale_refit_summary()
    pressure_temperature_component_scale_refit =
        pressure_temperature_component_scale_refit_summary()
    gas_pressure_temperature_component_scale_refit =
        gas_pressure_temperature_component_scale_refit_summary()
    h2o_pressure_temperature_component_scale_refit =
        h2o_pressure_temperature_component_scale_refit_summary()
    mixed_pressure_temperature_component_refit =
        mixed_pressure_temperature_component_refit_summary()
    retained_mixed_component_pareto_scan =
        retained_mixed_component_pareto_scan_summary()
    retained_topology_neighbor_scan = retained_topology_neighbor_scan_summary()
    retained_topology_constrained_optimizer =
        retained_topology_constrained_optimizer_summary()
    structural_optimizer_sweep = structural_optimizer_sweep_summary()
    retained_structural_optimizer = retained_structural_optimizer_summary()
    retained_structural_continuation = retained_structural_continuation_summary()
    retained_structural_continuation2 = retained_structural_continuation2_summary()
    retained_structural_continuation3 = retained_structural_continuation3_summary()
    retained_structural_continuation4 = retained_structural_continuation4_summary()
    retained_structural_pareto_probe = retained_structural_pareto_probe_summary()
    retained_quadrature_pareto_scan = retained_quadrature_pareto_scan_summary()
    retained_quadrature_pair_pareto_scan =
        retained_quadrature_pair_pareto_scan_summary()
    retained_quadrature_linearized_optimizer =
        retained_quadrature_linearized_optimizer_summary()
    retained_current_quadrature_linearized_optimizer =
        retained_current_quadrature_linearized_optimizer_summary()
    retained_current_bounded_table_optimizer =
        retained_current_bounded_table_optimizer_summary()
    retained_current_heating_profile_optimizer =
        retained_current_heating_profile_optimizer_summary()
    retained_current_joint_heating_optimizer =
        retained_current_joint_heating_optimizer_summary()
    retained_current_component_scale_optimizer =
        retained_current_component_scale_optimizer_summary()
    retained_current_component_scale_optimizer2 =
        retained_current_component_scale_optimizer2_summary()
    retained_current_component_scale_optimizer3 =
        retained_current_component_scale_optimizer3_summary()
    retained_current_component_scale_optimizer4 =
        retained_current_component_scale_optimizer4_summary()
    retained_current_pressure_component_optimizer =
        retained_current_pressure_component_optimizer_summary()
    retained_current_pressure_component_scan =
        retained_current_pressure_component_scan_summary()
    retained_current_pressure_component_rayleigh_scan =
        retained_current_pressure_component_rayleigh_scan_summary()
    retained_current_pressure_component_surface_guard_scan =
        retained_current_pressure_component_surface_guard_scan_summary()
    retained_current_gas_pressure_component_scan =
        retained_current_gas_pressure_component_scan_summary()
    retained_current_gas_pressure_component_continuation_scan =
        retained_current_gas_pressure_component_continuation_scan_summary()
    retained_current_gas_pressure_component_continuation2_scan =
        retained_current_gas_pressure_component_continuation2_scan_summary()
    retained_current_gas_pressure_component_continuation3_scan =
        retained_current_gas_pressure_component_continuation3_scan_summary()
    retained_capped_table_optimizer = retained_capped_table_optimizer_summary()
    retained_capped_table_continuation =
        retained_capped_table_continuation_summary()
    retained_post_capped_weight_refit =
        retained_post_capped_weight_refit_summary()
    retained_post_weight_surface_table_refit =
        retained_post_weight_surface_table_refit_summary()
    retained_post_weight_bounded_weight_refit =
        retained_post_weight_bounded_weight_refit_summary()
    retained_table_coordinate_pareto_scan =
        retained_table_coordinate_pareto_scan_summary()
    retained_objective_probe_expansion =
        retained_objective_probe_expansion_summary()
    retained_objective_probe_expansion2 =
        retained_objective_probe_expansion2_summary()
    retained_objective_probe_expansion3 =
        retained_objective_probe_expansion3_summary()
    retained_objective_probe_expansion4 =
        retained_objective_probe_expansion4_summary()
    retained_surface_probe_expansion =
        retained_surface_probe_expansion_summary()
    retained_surface_probe_expansion2 =
        retained_surface_probe_expansion2_summary()
    retained_surface_probe_expansion3 =
        retained_surface_probe_expansion3_summary()
    retained_boundary_probe_expansion =
        retained_boundary_probe_expansion_summary()
    retained_toa_probe_expansion =
        retained_toa_probe_expansion_summary()
    boundary_table_triple_coordinate_scan = boundary_table_triple_coordinate_scan_summary()
    if isempty(passing_reduced) && optical_depth_fit.present &&
       optical_depth_fit.next_required_work != ""
        next_required_work = optical_depth_fit.next_required_work
    end
    if isempty(passing_reduced) && optimization.present && optimization.next_required_work != ""
        next_required_work = optimization.next_required_work
    end
    if isempty(passing_reduced) && constrained_table_optimizer.present
        capped_table_sentence = retained_capped_table_optimizer.accepted ?
            "The retained capped constrained-table optimizer now accepts a surface-residual table update composing $(retained_capped_table_optimizer.accepted_move_count) cap-safe moves, dropping TOA forcing to about $(@sprintf("%.3f", retained_capped_table_optimizer.best_cap_safe_toa_forcing_error_w_m2)) W m^-2 while keeping surface forcing at about $(@sprintf("%.3f", retained_capped_table_optimizer.best_cap_safe_surface_forcing_error_w_m2)) W m^-2." :
            "The retained capped constrained-table optimizer found no cap-safe row: its best unsafe table update lowers TOA forcing to about $(@sprintf("%.3f", retained_capped_table_optimizer.best_unsafe_toa_forcing_error_w_m2)) W m^-2 but raises surface forcing to about $(@sprintf("%.3f", retained_capped_table_optimizer.best_unsafe_surface_forcing_error_w_m2)) W m^-2."
        capped_table_continuation_sentence = retained_capped_table_continuation.accepted ?
            "A retained capped-table continuation composes another $(retained_capped_table_continuation.accepted_move_count) cap-safe moves, dropping TOA forcing to about $(@sprintf("%.3f", retained_capped_table_continuation.best_cap_safe_toa_forcing_error_w_m2)) W m^-2 while keeping surface forcing at about $(@sprintf("%.3f", retained_capped_table_continuation.best_cap_safe_surface_forcing_error_w_m2)) W m^-2." :
            "A retained capped-table continuation found no additional cap-safe row from the capped-table base."
        post_capped_weight_sentence = retained_post_capped_weight_refit.accepted ?
            "A post-capped shortwave-weight refit then makes a small strict improvement to TOA $(@sprintf("%.3f", retained_post_capped_weight_refit.refit_worst_toa_forcing_error_w_m2)) W m^-2 and surface $(@sprintf("%.3f", retained_post_capped_weight_refit.refit_worst_surface_forcing_error_w_m2)) W m^-2 without changing the retained table topology." :
            "A post-capped shortwave-weight refit found no strict non-regressing improvement from the capped-table continuation base."
        post_weight_surface_table_sentence = retained_post_weight_surface_table_refit.accepted ?
            "A post-weight surface-table refit adds $(retained_post_weight_surface_table_refit.accepted_move_count) tiny non-regressing table moves, lowering the exact objective to $(@sprintf("%.6f", retained_post_weight_surface_table_refit.accepted_objective)) while leaving the current worst boundary forcing unchanged at reported precision." :
            "A post-weight surface-table refit found no strict non-regressing table update from the post-capped weight base."
        post_weight_bounded_weight_sentence = retained_post_weight_bounded_weight_refit.accepted ?
            "A bounded post-weight shortwave-weight refit trades within the surface cap, lowering TOA forcing to $(@sprintf("%.3f", retained_post_weight_bounded_weight_refit.refit_worst_toa_forcing_error_w_m2)) W m^-2 while keeping surface forcing at $(@sprintf("%.3f", retained_post_weight_bounded_weight_refit.refit_worst_surface_forcing_error_w_m2)) W m^-2." :
            "A bounded post-weight shortwave-weight refit found no objective/TOA-improving row below the surface cap."
        heating_profile_sentence = retained_current_heating_profile_optimizer.present ?
            "A current-base heating-profile residual table update is now also rejected: its best row lowers heating-rate RMSE to $(@sprintf("%.3f", retained_current_heating_profile_optimizer.best_worst_heating_rate_rmse_k_day)) K day^-1, but worsens the hard objective to $(@sprintf("%.3f", retained_current_heating_profile_optimizer.best_exact_objective)) and raises surface forcing to about $(@sprintf("%.3f", retained_current_heating_profile_optimizer.best_worst_surface_forcing_error_w_m2)) W m^-2, so the coupled boundary/heating failure cannot be fixed by this local residual fit." :
            "A current-base heating-profile residual table update has not yet been generated."
        joint_heating_sentence = retained_current_joint_heating_optimizer.present ?
            "A joint current-base heating residual solve with both quadrature-logit and active-entry table columns reduces the table-only surface blow-up but is still rejected: its best row lowers heating RMSE to $(@sprintf("%.3f", retained_current_joint_heating_optimizer.best_worst_heating_rate_rmse_k_day)) K day^-1, while worsening the hard objective to $(@sprintf("%.3f", retained_current_joint_heating_optimizer.best_exact_objective)) and surface forcing to $(@sprintf("%.3f", retained_current_joint_heating_optimizer.best_worst_surface_forcing_error_w_m2)) W m^-2." :
            "A joint current-base heating residual solve with quadrature-logit and active-entry table columns has not yet been generated."
        current_component_sentence = retained_current_component_scale_optimizer.accepted ?
            "A current-base component-scale solve now composes the remaining cap-safe component direction into the canonical row, lowering TOA forcing to $(@sprintf("%.3f", retained_current_component_scale_optimizer.accepted_worst_toa_forcing_error_w_m2)) W m^-2 and heating RMSE to $(@sprintf("%.3f", retained_current_component_scale_optimizer.accepted_worst_heating_rate_rmse_k_day)) K day^-1 while keeping surface forcing at $(@sprintf("%.3f", retained_current_component_scale_optimizer.accepted_worst_surface_forcing_error_w_m2)) W m^-2." :
            "A current-base component-scale solve found no cap-safe accepted row on the fully composed base."
        current_component2_sentence = retained_current_component_scale_optimizer2.accepted ?
            "A second current-base component-scale solve composes another cap-safe low-rank direction, lowering TOA forcing to $(@sprintf("%.3f", retained_current_component_scale_optimizer2.accepted_worst_toa_forcing_error_w_m2)) W m^-2 and heating RMSE to $(@sprintf("%.3f", retained_current_component_scale_optimizer2.accepted_worst_heating_rate_rmse_k_day)) K day^-1 while keeping surface forcing at $(@sprintf("%.3f", retained_current_component_scale_optimizer2.accepted_worst_surface_forcing_error_w_m2)) W m^-2." :
            "A second current-base component-scale solve found no additional cap-safe accepted row after the first component-scale move."
        current_component3_sentence = retained_current_component_scale_optimizer3.accepted ?
            "A third current-base component-scale solve composes a still smaller cap-safe low-rank direction, lowering TOA forcing to $(@sprintf("%.3f", retained_current_component_scale_optimizer3.accepted_worst_toa_forcing_error_w_m2)) W m^-2 and heating RMSE to $(@sprintf("%.3f", retained_current_component_scale_optimizer3.accepted_worst_heating_rate_rmse_k_day)) K day^-1 while keeping surface forcing at $(@sprintf("%.3f", retained_current_component_scale_optimizer3.accepted_worst_surface_forcing_error_w_m2)) W m^-2." :
            "A third current-base component-scale solve found no additional cap-safe accepted row after the first two component-scale moves."
        current_component4_sentence = retained_current_component_scale_optimizer4.accepted ?
            "A fourth current-base component-scale solve composes another smaller cap-safe low-rank direction, lowering TOA forcing to $(@sprintf("%.3f", retained_current_component_scale_optimizer4.accepted_worst_toa_forcing_error_w_m2)) W m^-2 and heating RMSE to $(@sprintf("%.3f", retained_current_component_scale_optimizer4.accepted_worst_heating_rate_rmse_k_day)) K day^-1 while keeping surface forcing at $(@sprintf("%.3f", retained_current_component_scale_optimizer4.accepted_worst_surface_forcing_error_w_m2)) W m^-2." :
            "A fourth current-base component-scale solve found no additional cap-safe accepted row after the first three component-scale moves."
        current_pressure_component_sentence = retained_current_pressure_component_optimizer.accepted ?
            "A current-base pressure-component solve composes a richer 128-column pressure-band static/H2O direction, lowering TOA forcing to $(@sprintf("%.3f", retained_current_pressure_component_optimizer.accepted_worst_toa_forcing_error_w_m2)) W m^-2 and heating RMSE to $(@sprintf("%.3f", retained_current_pressure_component_optimizer.accepted_worst_heating_rate_rmse_k_day)) K day^-1 while keeping surface forcing at $(@sprintf("%.3f", retained_current_pressure_component_optimizer.accepted_worst_surface_forcing_error_w_m2)) W m^-2." :
            "A current-base pressure-component solve found no accepted cap-safe row on top of the component-scale chain."
        current_pressure_scan_sentence = retained_current_pressure_component_scan.accepted ?
            "A pressure-component scan then selects a $(retained_current_pressure_component_scan.selected_pressure_band_count)-band $(retained_current_pressure_component_scan.selected_partition) basis, lowering canonical TOA forcing to $(@sprintf("%.3f", retained_current_pressure_component_scan.selected_worst_toa_forcing_error_w_m2)) W m^-2 while keeping surface forcing at $(@sprintf("%.3f", retained_current_pressure_component_scan.selected_worst_surface_forcing_error_w_m2)) W m^-2." :
            "A pressure-component scan found no accepted variant beyond the fixed 4-band pressure-component solve."
        current_pressure_rayleigh_scan_sentence =
            retained_current_pressure_component_rayleigh_scan.accepted ?
            "A Rayleigh-augmented pressure-component scan is diagnostic-only: its best $(retained_current_pressure_component_rayleigh_scan.selected_pressure_band_count)-band $(retained_current_pressure_component_rayleigh_scan.selected_partition) row reaches objective $(@sprintf("%.3f", retained_current_pressure_component_rayleigh_scan.selected_objective)), worse than the selected non-Rayleigh scan, so it is not promoted." :
            "A Rayleigh-augmented pressure-component scan found no accepted row and is not promoted."
        current_pressure_surface_guard_sentence =
            retained_current_pressure_component_surface_guard_scan.accepted ?
            "A stricter surface-guard pressure-component scan with cap $(@sprintf("%.3f", retained_current_pressure_component_surface_guard_scan.surface_cap_w_m2)) selects a $(retained_current_pressure_component_surface_guard_scan.selected_pressure_band_count)-band $(retained_current_pressure_component_surface_guard_scan.selected_partition) row at objective $(@sprintf("%.3f", retained_current_pressure_component_surface_guard_scan.selected_objective)); it preserves surface margin but gives up most of the 8-band objective gain, so it is diagnostic-only." :
            "A stricter surface-guard pressure-component scan found no accepted row and is not promoted."
        current_gas_pressure_scan_sentence =
            retained_current_gas_pressure_component_scan.accepted ?
            "A gas-pressure component scan supersedes the non-gas scan with a $(retained_current_gas_pressure_component_scan.selected_pressure_band_count)-band $(retained_current_gas_pressure_component_scan.selected_partition) static-gas/H2O basis, lowering canonical TOA forcing to $(@sprintf("%.3f", retained_current_gas_pressure_component_scan.selected_worst_toa_forcing_error_w_m2)) W m^-2 and heating RMSE to $(@sprintf("%.3f", retained_current_gas_pressure_component_scan.selected_worst_heating_rate_rmse_k_day)) K day^-1 while tightening surface-margin headroom to about $(@sprintf("%.4f", retained_current_gas_pressure_component_scan.surface_cap_w_m2 - retained_current_gas_pressure_component_scan.selected_worst_surface_forcing_error_w_m2)) W m^-2." :
            "A gas-pressure component scan has not found an accepted static-gas/H2O split variant to supersede the non-gas scan."
        current_gas_pressure_continuation_sentence =
            retained_current_gas_pressure_component_continuation_scan.accepted ?
            "A quarter-step gas-pressure continuation composes a second cap-safe static-gas/H2O pressure move, lowering canonical TOA forcing to $(@sprintf("%.3f", retained_current_gas_pressure_component_continuation_scan.selected_worst_toa_forcing_error_w_m2)) W m^-2 and heating RMSE to $(@sprintf("%.3f", retained_current_gas_pressure_component_continuation_scan.selected_worst_heating_rate_rmse_k_day)) K day^-1 while retaining about $(@sprintf("%.4f", retained_current_gas_pressure_component_continuation_scan.surface_cap_w_m2 - retained_current_gas_pressure_component_continuation_scan.selected_worst_surface_forcing_error_w_m2)) W m^-2 against its stricter surface cap." :
            "A gas-pressure continuation scan has not found a second cap-safe static-gas/H2O pressure move."
        current_gas_pressure_continuation2_sentence =
            retained_current_gas_pressure_component_continuation2_scan.accepted ?
            "A heating-weighted gas-pressure continuation then composes a third surface-neutral static-gas/H2O pressure move, lowering canonical TOA forcing to $(@sprintf("%.3f", retained_current_gas_pressure_component_continuation2_scan.selected_worst_toa_forcing_error_w_m2)) W m^-2 and heating RMSE to $(@sprintf("%.3f", retained_current_gas_pressure_component_continuation2_scan.selected_worst_heating_rate_rmse_k_day)) K day^-1 while holding surface forcing at $(@sprintf("%.3f", retained_current_gas_pressure_component_continuation2_scan.selected_worst_surface_forcing_error_w_m2)) W m^-2." :
            "A heating-weighted gas-pressure continuation found no surface-neutral third pressure move on top of the current continuation."
        current_gas_pressure_continuation3_sentence =
            retained_current_gas_pressure_component_continuation3_scan.accepted ?
            "A high-weight gas-pressure continuation composes a fourth surface-preserving static-gas/H2O pressure move, lowering canonical TOA forcing to $(@sprintf("%.3f", retained_current_gas_pressure_component_continuation3_scan.selected_worst_toa_forcing_error_w_m2)) W m^-2 and heating RMSE to $(@sprintf("%.3f", retained_current_gas_pressure_component_continuation3_scan.selected_worst_heating_rate_rmse_k_day)) K day^-1 while slightly reducing surface forcing to $(@sprintf("%.3f", retained_current_gas_pressure_component_continuation3_scan.selected_worst_surface_forcing_error_w_m2)) W m^-2." :
            "A high-weight gas-pressure continuation found no fourth surface-preserving pressure move on top of the weighted continuation."
        pressure_component_followup_sentence =
            retained_current_gas_pressure_component_continuation3_scan.accepted ?
            "The pressure/gas continuation path can still extract tiny surface-preserving improvements by increasing heating residual weight, but the improvement scale is now far below what is needed for the hard reduced gate; one-swap, shallow two-swap, bounded 17/18-g expansion, targeted multi-start expansion refits, and a bounded random 16-g support search now reject, so structural acceptance-plan or reduced-basis changes are the remaining options once the saved nonlocal support search is rejected." :
            retained_current_gas_pressure_component_continuation2_scan.accepted ?
            "The pressure/gas basis still moves the reduced objective only when the residual is weighted toward heating and constrained to preserve surface headroom; further work should target coupled heating/boundary structure instead of spending surface margin." :
            retained_current_gas_pressure_component_continuation_scan.accepted ?
            "The pressure/gas basis still moves the reduced objective, but continuation progress is now surface-margin limited; further work should target coupled heating and boundary errors without consuming the remaining surface-cap headroom." :
            retained_current_gas_pressure_component_scan.accepted ?
            "The pressure-component basis remains the productive reduced-model lever, but the gas-pressure promotion leaves little surface-cap margin; next variants need stronger surface-aware or coupled heating improvements rather than another narrow bounded-frontier surface trade." :
            retained_current_pressure_component_scan.accepted ?
            "The pressure-component basis remains the productive reduced-model lever; next variants should favor richer pressure/gas coupling or a surface-aware objective before adding another halved-step continuation." :
            retained_current_pressure_component_optimizer.accepted ?
            "The pressure-component basis is now the productive reduced-model lever; next variants should compare pressure-band counts, log-pressure partitioning, and Rayleigh inclusion before adding another halved-step continuation." :
            "The next pressure-component variant should test whether pressure-band counts, log-pressure partitioning, or Rayleigh inclusion expose a cap-safe direction."
        nonlocal_support_sentence =
            nonlocal_support_refit_search.present &&
            nonlocal_support_refit_search.status == "nonlocal_support_refit_rejected" &&
            nonlocal_support_refit_search.evaluated_candidate_count ==
            nonlocal_support_refit_search.total_candidate_count ?
            "A nonlocal support-plus-refit pass then evaluates all $(nonlocal_support_refit_search.evaluated_candidate_count) saved best supports from the random, swap, continuation, and hard-gate subset searches through the same chain replay; its best candidate $(nonlocal_support_refit_search.best_label) still rejects at objective $(@sprintf("%.3f", nonlocal_support_refit_search.best_objective)), above the canonical chain objective $(@sprintf("%.3f", nonlocal_support_refit_search.current_objective)), so the saved nonlocal support search no longer remains as a next technical branch." :
            "A full saved-candidate nonlocal support-plus-refit pass is still needed before dropping broader support search as a technical branch."
        next_required_work =
            "Continue beyond the current local active-entry, component-scale, scalar coefficient/weight, retained quadrature-logit, retained topology-neighbor, retained structural optimizer, and retained mixed-component bases. The latest boundary-aware 32x16 row still leaves the reduced model above the 0.3 W m^-2 hard threshold. Whole-component coordinate refits improve the retained model; pressure-, temperature-, H2O-band, and gas-specific component refinements test finer table parameterizations but remain local, radius-2 retained topology replacements are rejected, direct retained one-logit and pairwise quadrature redistributions are rejected, exact retained single table-coordinate moves are rejected, and five retained all-shortwave residual structural passes define the current retained state. The retained mixed-component scan is now composed into the canonical row under a bounded-frontier forcing-error tolerance plus an absolute 2.03 W m^-2 surface cap, not a strict Pareto rule; this improves TOA forcing while keeping the composed surface forcing below the current regression guard. An uncapped 16-iteration continuation reached lower TOA forcing near 2.109 W m^-2 but raised surface forcing to about 2.044 W m^-2, and the canonical mixed-component capped 20-iteration run exposes an unsafe diagnostic best candidate near surface 2.037 W m^-2, so only cap-safe accepted moves are composed. Four expanded objective-probed table updates reduce the scalar objective only by regressing surface forcing and are rejected by the strict-Pareto probe gate; three surface-residual table updates also reject on the cleaned base. $capped_table_sentence $capped_table_continuation_sentence $post_capped_weight_sentence $post_weight_surface_table_sentence $post_weight_bounded_weight_sentence $current_component_sentence $current_component2_sentence $current_component3_sentence $current_component4_sentence $current_pressure_component_sentence $current_pressure_scan_sentence $current_pressure_rayleigh_scan_sentence $current_pressure_surface_guard_sentence $current_gas_pressure_scan_sentence $current_gas_pressure_continuation_sentence $current_gas_pressure_continuation2_sentence $current_gas_pressure_continuation3_sentence $pressure_component_followup_sentence Current-base quadrature-logit and bounded table-entry updates on the capped/post-weight base are also rejected: their best ridge rows worsen the exact objective and push surface forcing far beyond the 2.03 W m^-2 cap. A current-base TOA-residual table update likewise improves the scalar objective only by regressing surface forcing, so it remains diagnostic-only and is not composed into the canonical reduced row. $heating_profile_sentence $joint_heating_sentence A leave-one-out scan of the official 32-g shortwave path shows that every 31-g single-omission candidate fails the full hard gate; the best omission keeps boundary forcing small but still fails through the full flux/RMSE objective. A matching 31-g nonnegative weight refit also fails every single-omission support, with the best refit still at objective $(@sprintf("%.3f", leave_one_out_weight_refit.best_refit_objective)); this confirms the near-full gate sensitivity is not just naive official weights. Importance-guided 16-bin coefficient averaging, which preserves high-impact leave-one-out g-points as singleton bins and refits group weights, is also rejected; its best objective is $(@sprintf("%.3f", importance_group_scan.best_refit_objective)), far worse than the current retained subset. A one-g-point support-swap scan around the canonical and hard-gate subset supports is also rejected; its best exact weight-refit objective is $(@sprintf("%.3f", support_swap_scan.best_overall_objective)), so local support edits are not a shortcut to the hard gate. A second support-swap pass from that one-swap winner improves only to objective $(@sprintf("%.3f", support_swap_continuation_scan.best_objective)), still far above the canonical hard objective and the acceptance target. A bounded 17/18-g support-expansion scan is also rejected with the current limited nonnegative weight refit, with best objective $(@sprintf("%.3f", support_expansion_scan.best_overall_objective)). A targeted 4000-iteration multi-start refit of the best expanded supports still rejects at objective $(@sprintf("%.3f", support_expansion_refit_scan.best_objective)), so the tested expansion supports do not appear limited by the initial official-weight start. A bounded random 16-g support search over $(random_support_search.random_seed_count) random seeds also rejects, with best objective $(@sprintf("%.3f", random_support_search.best_objective)); the bare deterministic canonical support is worse at objective $(@sprintf("%.3f", random_support_search.canonical_seed_objective)), which confirms that the current canonical row at objective $(@sprintf("%.3f", current_metric_breakdown.hard_objective)) depends on the composed table/component/gas-pressure refit chain rather than support choice alone. A bounded broader support-plus-refit pass now replays the composed chain and gas-pressure refit on $(broader_support_refit_search.evaluated_candidate_count) of $(broader_support_refit_search.total_neighbor_candidate_count) radius-$(broader_support_refit_search.radius) support neighbors after prefiltering $(broader_support_refit_search.prefilter_evaluated_count); it rejects with best selected objective $(@sprintf("%.3f", broader_support_refit_search.best_objective)), showing that the shallow local support neighborhood does not break the canonical chain dependence. $nonlocal_support_sentence This points next at revisiting the hard reduced acceptance plan or allowing a different reduced basis rather than more local coefficient polishing, naive support growth, targeted expansion refits, or support search. The current metric breakdown shows the active hard-objective blocker is a coupled boundary/heating problem, not a single scalar boundary outlier: the worst row is $(current_metric_breakdown.worst_case) $(current_metric_breakdown.worst_metric) at normalized objective $(@sprintf("%.3f", current_metric_breakdown.hard_objective)), and the next ranked row is tropical heating-rate RMSE at essentially the same normalized value. The coefficient-continuation artifact recovers the best saved 48-parameter scalar state but remains far above target."
    end
    return (
        case = "reduced_ecckd_gap_report",
        timestamp_utc = string(Dates.now()),
        status = status,
        hard_forcing_threshold_w_m2 = 0.3,
        full_shortwave_passed = any(row -> row.passed, full_rows),
        reduced_shortwave_passed = !isempty(passing_reduced),
        best_reduced_method = best_reduced === nothing ? "" : best_reduced.method,
        best_reduced_toa_forcing_error_w_m2 = best_reduced === nothing ? NaN : best_reduced.toa_forcing_error_w_m2,
        best_reduced_surface_forcing_error_w_m2 = best_reduced === nothing ? NaN : best_reduced.surface_forcing_error_w_m2,
        optimization = optimization,
        coefficient_continuation = coefficient_continuation,
        subset_search = subset_search,
        optical_depth_fit = optical_depth_fit,
        size_weight_refit = size_weight_refit,
        leave_one_out_scan = leave_one_out_scan,
        leave_one_out_weight_refit = leave_one_out_weight_refit,
        importance_group_scan = importance_group_scan,
        support_swap_scan = support_swap_scan,
        support_swap_continuation_scan = support_swap_continuation_scan,
        support_expansion_scan = support_expansion_scan,
        support_expansion_refit_scan = support_expansion_refit_scan,
        random_support_search = random_support_search,
        current_metric_breakdown = current_metric_breakdown,
        reduced_acceptance_decision = reduced_acceptance_decision,
        pressure_band_refinement = pressure_band_refinement,
        targeted_entry = targeted_entry,
        global_entry = global_entry,
        global_block_entry = global_block_entry,
        global_block_linearized_entry = global_block_linearized_entry,
        linearized_entry = linearized_entry,
        global_linearized_entry = global_linearized_entry,
        topology_slot = topology_slot,
        post_table_weight = post_table_weight,
        exact_weight_refit = exact_weight_refit,
        joint_weight_block_refit = joint_weight_block_refit,
        boundary_column_refinement = boundary_column_refinement,
        slot_blend_refinement = slot_blend_refinement,
        pair_slot_blend_refinement = pair_slot_blend_refinement,
        slot_blend_linearized = slot_blend_linearized,
        post_slot_weight_refit = post_slot_weight_refit,
        boundary_column_block_refinement = boundary_column_block_refinement,
        gas_pressure_band_refinement = gas_pressure_band_refinement,
        gas_pressure_band_linearized = gas_pressure_band_linearized,
        flux_pair_bins = flux_pair_bins,
        grouped_quadrature_search = grouped_quadrature_search,
        grouped_quadrature_weight_refit = grouped_quadrature_weight_refit,
        weight_maxnorm_refit = weight_maxnorm_refit,
        constrained_table_optimizer = constrained_table_optimizer,
        topology_constrained_optimizer = topology_constrained_optimizer,
        post_constrained_weight_refit = post_constrained_weight_refit,
        post_constrained_boundary_weight_refit =
            post_constrained_boundary_weight_refit,
        hardgate_subset_search = hardgate_subset_search,
        boundary_topology_replacement = boundary_topology_replacement,
        boundary_topology_weight_refit = boundary_topology_weight_refit,
        boundary_table_coordinate_scan = boundary_table_coordinate_scan,
        boundary_table_pair_coordinate_scan = boundary_table_pair_coordinate_scan,
        boundary_table_coordinate_descent = boundary_table_coordinate_descent,
        boundary_table_continuation_optimizer =
            boundary_table_continuation_optimizer,
        component_scale_refit = component_scale_refit,
        pressure_component_scale_refit = pressure_component_scale_refit,
        temperature_component_scale_refit = temperature_component_scale_refit,
        h2o_component_scale_refit = h2o_component_scale_refit,
        gas_component_scale_refit = gas_component_scale_refit,
        pressure_temperature_component_scale_refit =
            pressure_temperature_component_scale_refit,
        gas_pressure_temperature_component_scale_refit =
            gas_pressure_temperature_component_scale_refit,
        h2o_pressure_temperature_component_scale_refit =
            h2o_pressure_temperature_component_scale_refit,
        mixed_pressure_temperature_component_refit =
            mixed_pressure_temperature_component_refit,
        retained_mixed_component_pareto_scan =
            retained_mixed_component_pareto_scan,
        retained_topology_neighbor_scan = retained_topology_neighbor_scan,
        retained_topology_constrained_optimizer =
            retained_topology_constrained_optimizer,
        structural_optimizer_sweep = structural_optimizer_sweep,
        retained_structural_optimizer = retained_structural_optimizer,
        retained_structural_continuation = retained_structural_continuation,
        retained_structural_continuation2 = retained_structural_continuation2,
        retained_structural_continuation3 = retained_structural_continuation3,
        retained_structural_continuation4 = retained_structural_continuation4,
        retained_structural_pareto_probe = retained_structural_pareto_probe,
        retained_quadrature_pareto_scan = retained_quadrature_pareto_scan,
        retained_quadrature_pair_pareto_scan =
            retained_quadrature_pair_pareto_scan,
        retained_quadrature_linearized_optimizer =
            retained_quadrature_linearized_optimizer,
        retained_current_quadrature_linearized_optimizer =
            retained_current_quadrature_linearized_optimizer,
        retained_current_bounded_table_optimizer =
            retained_current_bounded_table_optimizer,
        retained_current_heating_profile_optimizer =
            retained_current_heating_profile_optimizer,
        retained_current_joint_heating_optimizer =
            retained_current_joint_heating_optimizer,
        retained_current_component_scale_optimizer =
            retained_current_component_scale_optimizer,
        retained_current_component_scale_optimizer2 =
            retained_current_component_scale_optimizer2,
        retained_current_component_scale_optimizer3 =
            retained_current_component_scale_optimizer3,
        retained_current_component_scale_optimizer4 =
            retained_current_component_scale_optimizer4,
        retained_current_pressure_component_optimizer =
            retained_current_pressure_component_optimizer,
        retained_current_pressure_component_scan =
            retained_current_pressure_component_scan,
        retained_current_pressure_component_rayleigh_scan =
            retained_current_pressure_component_rayleigh_scan,
        retained_current_pressure_component_surface_guard_scan =
            retained_current_pressure_component_surface_guard_scan,
        retained_current_gas_pressure_component_scan =
            retained_current_gas_pressure_component_scan,
        retained_current_gas_pressure_component_continuation_scan =
            retained_current_gas_pressure_component_continuation_scan,
        retained_current_gas_pressure_component_continuation2_scan =
            retained_current_gas_pressure_component_continuation2_scan,
        retained_current_gas_pressure_component_continuation3_scan =
            retained_current_gas_pressure_component_continuation3_scan,
        broader_support_refit_search = broader_support_refit_search,
        nonlocal_support_refit_search = nonlocal_support_refit_search,
        retained_capped_table_optimizer = retained_capped_table_optimizer,
        retained_capped_table_continuation = retained_capped_table_continuation,
        retained_post_capped_weight_refit = retained_post_capped_weight_refit,
        retained_post_weight_surface_table_refit =
            retained_post_weight_surface_table_refit,
        retained_post_weight_bounded_weight_refit =
            retained_post_weight_bounded_weight_refit,
        retained_table_coordinate_pareto_scan =
            retained_table_coordinate_pareto_scan,
        retained_objective_probe_expansion =
            retained_objective_probe_expansion,
        retained_objective_probe_expansion2 =
            retained_objective_probe_expansion2,
        retained_objective_probe_expansion3 =
            retained_objective_probe_expansion3,
        retained_objective_probe_expansion4 =
            retained_objective_probe_expansion4,
        retained_surface_probe_expansion =
            retained_surface_probe_expansion,
        retained_surface_probe_expansion2 =
            retained_surface_probe_expansion2,
        retained_surface_probe_expansion3 =
            retained_surface_probe_expansion3,
        retained_boundary_probe_expansion =
            retained_boundary_probe_expansion,
        retained_toa_probe_expansion =
            retained_toa_probe_expansion,
        boundary_table_triple_coordinate_scan = boundary_table_triple_coordinate_scan,
        conclusion = conclusion,
        next_required_work = next_required_work,
        rows = rows,
    )
end

function main()
    result = reduced_gap_report()
    mkpath(dirname(GAP_JSON))
    write(GAP_JSON, json_object(result) * "\n")
    write(GAP_MD, markdown_report(result))
    print(markdown_report(result))
    println("Wrote $GAP_JSON")
    println("Wrote $GAP_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
