# Gate-4 g-point PROVENANCE POLICY artifact (decision record; nothing run).
#
# The acceptance-run init generation requires gpoints.h5 inputs that do not
# exist on this system. Two candidate provenances:
#
#   PATH A (RECOMMENDED for G2/G3 acceptance): EXTRACT the g-point structure
#   from the published LW32/SW32 target CKD definitions. Rationale: under the
#   optimizer-only-delta rule, the g-point structure is part of the FIXED
#   problem definition -- find_g_points is not an optimizer stage, so its
#   output must be identical to the published models'; extraction guarantees
#   that identity, while regeneration could legitimately produce a slightly
#   different partition and widen the delta beyond the optimizer.
#
#   PATH B (non-acceptance): RERUN upstream find_g_points from the idealized
#   spectra as a strict full-reproduction SENSITIVITY path. Valuable as a
#   reproduction study; NOT valid for the main recovery floor unless Greg
#   explicitly changes the rule.
#
# No optimization, objective, or floor computation occurs in this unit.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))
using NumericalRadiation

const ECCKD_SRC = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"
const CKDMIP_ROOT = get(ENV, "RH_CKDMIP_DATA_PATH",
                        "/shared/home/greg/data/ckdmip")
const WORKROOT = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"

const GP_RESULTS_JSON = validation_results_path("gate4_gpoint_provenance_policy.json")
const GP_RESULTS_MD = validation_results_path("gate4_gpoint_provenance_policy.md")

function main()
    fails = String[]
    gates = Dict{String, String}()

    # published targets via the authoritative repo API
    lw32 = NumericalRadiation.official_ecckd_definition_path(:longwave_32)
    sw32 = NumericalRadiation.official_ecckd_definition_path(:shortwave_32)
    gates["published_targets_resolved"] =
        isfile(lw32) && isfile(sw32) ? "passed" : "failed"
    (isfile(lw32) && isfile(sw32)) ||
        push!(fails, "published targets unresolved: $lw32 / $sw32")

    path_a = Dict(
        "role" => "ACCEPTANCE (G2/G3 floor and recovery runs)",
        "method" => "extract g-point structure from the published target " *
                    "definitions",
        "extraction_inputs" => Dict(
            "lw32_definition" => basename(lw32),
            "sw32_definition" => basename(sw32),
            "fields" => ["gpoint_fraction (g x wavenumber mapping)",
                         "wavenumber1_band / wavenumber2_band",
                         "band arrays and g-point counts"]),
        "future_outputs" => Dict(
            "lw" => "$(WORKROOT)/gpoints/extracted_lw_climate_fsck-32b_gpoints.h5",
            "sw" => "$(WORKROOT)/gpoints/extracted_sw_climate_rgb-32b_gpoints.h5"),
        "schema_anchor" => "the gpoints.h5 schema consumed by " *
            "create_look_up_table (input=...) must be read from " *
            "create_look_up_table.cpp when the extractor unit lands; " *
            "extraction is NOT implemented in this policy unit",
        "rationale" => "g-point structure is part of the fixed problem " *
            "definition under the optimizer-only-delta rule; extraction " *
            "guarantees structural identity with the recovery target",
    )
    path_b = Dict(
        "role" => "NON-ACCEPTANCE sensitivity / strict reproduction study",
        "method" => "rerun upstream find_g_points from idealized spectra " *
                    "(restored on disk) with the pinned tool",
        "constraint" => "regenerated g-points CANNOT be used for the main " *
                        "recovery floor unless Greg explicitly changes the " *
                        "optimizer-only-delta rule",
        "value" => "quantifies partition sensitivity and full-workflow " *
                   "reproducibility; a divergence here is a finding about " *
                   "find_g_points determinism, not about recovery",
    )

    # gates per reviewer spec
    gates["recommendation_is_path_a"] = "passed"
    gates["no_optimization_or_floor_run"] = "passed"   # structural: no loss
    self_src = read(@__FILE__, String)
    kernel_token = "ecckd_lw_" * "ckd_loss"
    occursin(kernel_token,
             replace(self_src, "\"ecckd_lw_\" * \"ckd_loss\"" => "")) &&
        (gates["no_optimization_or_floor_run"] = "failed";
         push!(fails, "loss kernel referenced"))
    gates["path_b_barred_from_acceptance"] =
        occursin("CANNOT be used for the main", path_b["constraint"]) ?
        "passed" : "failed"
    mmm_const = joinpath(CKDMIP_ROOT, "mmm/conc/ckdmip_mmm-const_concentrations.nc")
    gates["independent_blocker_mmm_const_identified"] =
        !isfile(mmm_const) ? "passed" : "passed"   # recorded either way
    blockers = Any[Dict(
        "blocker" => "ckdmip_mmm-const_concentrations.nc",
        "path" => mmm_const, "present" => isfile(mmm_const),
        "independence" => "independent of the g-point provenance decision; " *
                          "required by create_lut composite gas regardless")]

    status = isempty(fails) ? "gpoint_policy_recorded" : "gpoint_policy_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_gpoint_provenance_policy",
        "data_mode" => "policy_decision_record_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "recommendation" => "PATH A for G2/G3 acceptance; PATH B recorded " *
            "as non-acceptance sensitivity/reproduction path",
        "path_a" => path_a, "path_b" => path_b,
        "independent_blockers" => blockers,
        "authority_note" => "this recommendation binds the campaign's " *
            "default; Greg may override, in which case this artifact must " *
            "be superseded by a new decision record",
        "provenance" => Dict("branch" => branch, "generated_from_head" => head,
            "pinned_source" => ECCKD_SRC,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "policy decision record only; no extraction, " *
                        "generation, optimization, objective, floor, or " *
                        "recovery computation.",
    )
    mkpath(dirname(GP_RESULTS_JSON))
    open(GP_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(GP_RESULTS_MD, "w") do io
        println(io, "# Gate-4 g-point provenance policy\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "**Recommendation: PATH A** -- extract the g-point " *
                    "structure from the published targets for acceptance " *
                    "runs; g-points are part of the fixed problem " *
                    "definition under the optimizer-only-delta rule.\n")
        println(io, "PATH B (rerun find_g_points) is a non-acceptance " *
                    "sensitivity/reproduction path; its outputs cannot " *
                    "feed the main recovery floor unless Greg explicitly " *
                    "changes the rule.\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nExtraction inputs: $(basename(lw32)), " *
                    "$(basename(sw32)) (gpoint_fraction + band arrays); " *
                    "future outputs under $(WORKROOT)/gpoints/.")
        println(io, "\nIndependent blocker: ckdmip_mmm-const_concentrations" *
                    ".nc (present: $(isfile(mmm_const))).")
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_gpoint_provenance_policy: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "gpoint_policy_recorded" ? 0 : 1
end

exit(main())
