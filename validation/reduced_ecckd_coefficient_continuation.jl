include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
using Printf

include(joinpath(@__DIR__, "reduced_ecckd_optimization_preflight.jl"))

const COEFFICIENT_CONTINUATION_JSON =
    validation_results_path("reduced_ecckd_coefficient_continuation.json")
const COEFFICIENT_CONTINUATION_MD =
    validation_results_path("reduced_ecckd_coefficient_continuation.md")

function coefficient_continuation_saved_states(f)
    states = NamedTuple[]
    for (label, path, section) in (
            ("preflight_post_coefficient_weight_refinement", PREFLIGHT_JSON,
             "post_coefficient_weight_refinement"),
            ("preflight_post_joint_coordinate_refinement", PREFLIGHT_JSON,
             "post_joint_coordinate_refinement"),
            ("preflight_coefficient_joint_direction_scan", PREFLIGHT_JSON,
             "coefficient_joint_direction_scan"),
            ("preflight_greedy_coordinate_descent", PREFLIGHT_JSON,
             "greedy_coordinate_descent"),
            ("coefficient_continuation_final", COEFFICIENT_CONTINUATION_JSON,
             nothing),
        )
        parameters = section === nothing ?
            final_parameters_from_json(path) :
            final_parameters_from_preflight_section(section; path)
        parameters === nothing && continue
        push!(states, (
            label = label,
            objective = f(parameters),
            parameters = parameters,
        ))
    end
    return states
end

function final_parameters_from_json(path)
    isfile(path) || return nothing
    match = Base.match(r"\"final_parameters\"\s*:\s*\[([^\]]+)\]",
                       read(path, String))
    match === nothing && return nothing
    values = parse.(Float64, split(match.captures[1], ","))
    length(values) == 3length(WEIGHTED_GREEDY_SW_16_INDICES) || return nothing
    return values
end

function coefficient_continuation_result()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    full_model = candidate_gas_optics(Float64)
    parameters = initial_parameters()
    f(x) = reduced_objective(full_model, x)
    initial_objective = f(parameters)
    saved_states = coefficient_continuation_saved_states(f)

    greedy, checkpoint_used = greedy_coordinate_descent_with_checkpoint(
        f,
        parameters,
        initial_objective,
    )
    joint_scan = coefficient_joint_direction_scan(f, greedy.final_parameters)
    joint_parameters = joint_scan.best_objective < greedy.final_objective ?
        joint_scan.final_parameters : greedy.final_parameters
    post_joint = post_joint_coordinate_refinement(f, joint_parameters)
    candidate_states = copy(saved_states)
    push!(candidate_states, (
        label = "resumed_greedy_coordinate_descent",
        objective = greedy.final_objective,
        parameters = greedy.final_parameters,
    ))
    push!(candidate_states, (
        label = "resumed_coefficient_joint_direction_scan",
        objective = joint_scan.best_objective,
        parameters = joint_scan.final_parameters,
    ))
    push!(candidate_states, (
        label = "resumed_post_joint_coordinate_refinement",
        objective = post_joint.final_objective,
        parameters = post_joint.final_parameters,
    ))
    best_state = argmin(state -> state.objective, candidate_states)
    weight_refinement =
        post_coefficient_weight_refinement(f, best_state.parameters)
    best_parameters = weight_refinement.final_objective < best_state.objective ?
        weight_refinement.final_parameters : best_state.parameters
    breakdown = final_objective_breakdown(full_model, best_parameters)

    return (
        case = "reduced_ecckd_coefficient_continuation",
        timestamp_utc = Dates.format(now(UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
        status = breakdown.objective <= 1.0 ? "coefficient_continuation_passed" :
                 "coefficient_continuation_above_target",
        objective_target = 1.0,
        initial_objective = initial_objective,
        greedy_checkpoint_used = checkpoint_used,
        saved_state_count = length(saved_states),
        best_start_label = best_state.label,
        best_start_objective = best_state.objective,
        greedy_coordinate_descent = greedy,
        coefficient_joint_direction_scan = joint_scan,
        post_joint_coordinate_refinement = post_joint,
        post_coefficient_weight_refinement = weight_refinement,
        final_objective_breakdown = breakdown,
        final_objective = breakdown.objective,
        final_objective_target_ratio = breakdown.objective,
        final_parameters = collect(best_parameters),
    )
end

function coefficient_continuation_markdown(result)
    lines = String[
        "# Reduced ecCKD Coefficient Continuation",
        "",
        "Status: **$(result.status)**",
        "",
        "| Field | Value |",
        "|---|---:|",
        "| Initial objective | $(@sprintf("%.12g", result.initial_objective)) |",
        "| Objective target | $(@sprintf("%.12g", result.objective_target)) |",
        "| Final objective | $(@sprintf("%.12g", result.final_objective)) |",
        "| Greedy checkpoint used | $(result.greedy_checkpoint_used) |",
        "| Saved states evaluated | $(result.saved_state_count) |",
        "| Best start label | $(result.best_start_label) |",
        "| Best start objective | $(@sprintf("%.12g", result.best_start_objective)) |",
        "| Greedy iterations | $(result.greedy_coordinate_descent.iterations_completed) |",
        "| Greedy final objective | $(@sprintf("%.12g", result.greedy_coordinate_descent.final_objective)) |",
        "| Joint direction best objective | $(@sprintf("%.12g", result.coefficient_joint_direction_scan.best_objective)) |",
        "| Post-joint iterations | $(result.post_joint_coordinate_refinement.iterations_completed) |",
        "| Post-joint final objective | $(@sprintf("%.12g", result.post_joint_coordinate_refinement.final_objective)) |",
        "| Weight refinement iterations | $(result.post_coefficient_weight_refinement.iterations_completed) |",
        "| Weight refinement final objective | $(@sprintf("%.12g", result.post_coefficient_weight_refinement.final_objective)) |",
        "| Worst case | $(result.final_objective_breakdown.worst_case) |",
        "| Worst metric | $(result.final_objective_breakdown.worst_metric) |",
        "| Worst value | $(@sprintf("%.12g", result.final_objective_breakdown.worst_value)) |",
        "| Worst threshold | $(@sprintf("%.12g", result.final_objective_breakdown.worst_threshold)) |",
        "",
        "This artifact intentionally stops before topology, pressure-band table,",
        "and active-entry table scans. It captures only the cheap-to-resume",
        "48-parameter coefficient/weight continuation so useful progress is not",
        "lost when the full preflight becomes too expensive.",
    ]
    return join(lines, "\n") * "\n"
end

function main(; result = nothing)
    result = result === nothing ? coefficient_continuation_result() : result
    mkpath(dirname(COEFFICIENT_CONTINUATION_JSON))
    write(COEFFICIENT_CONTINUATION_JSON, json_object(result) * "\n")
    write(COEFFICIENT_CONTINUATION_MD, coefficient_continuation_markdown(result))
    print(coefficient_continuation_markdown(result))
    println("Wrote $COEFFICIENT_CONTINUATION_JSON")
    println("Wrote $COEFFICIENT_CONTINUATION_MD")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
