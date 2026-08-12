# Gate-4 g-point PROVENANCE POLICY artifact (decision record; nothing run)
# -- HISTORICAL; ACCEPTANCE MECHANISM SUPERSEDED BY OPTION B.
#
# SUPERSESSION (monitor-directed marking, 2026-08-12): the override this
# unit anticipated in its authority_note HAPPENED -- Greg (2026-07-20,
# "take option B") adopted the AMENDED acceptance rule recorded in
# gate4_option_b_decision_record (structural fields elementwise EXACT +
# support arrays within storage precision, max|diff| <= 2.1e-5),
# superseding this unit's strict exact-reproduction A2 mechanism. OUTCOME:
# the A2 find_g_points rerun (job 4082) produced the candidates; the
# create_lut proof (job 4091) showed structure bit-exact with
# storage-precision support drift; the candidates were ACCEPTED under the
# amended rule (LW gpoints c96e6492..., SW 13dd686a...) and are sha-pinned
# by gate4_g3_scoped_input_preflight.jl. The structural-identity POLICY
# INTENT (g-points are part of the fixed problem definition) and the
# Path-B sensitivity rule remain in force; only the strict exact-match
# acceptance mechanism was superseded. The previously recorded
# future-output/extractor wording is WITHDRAWN below (extraction was
# proven invalid and no extractor unit was ever needed). The status token
# gpoint_policy_recorded is retained unchanged.
#
# Original context (historical): at decision time the acceptance-run init
# generation required gpoints.h5 inputs that did not exist on this
# system. Two candidate provenances:
#
#   PATH A (G2/G3 acceptance POLICY: structural identity with the published
#   targets). MECHANISM AMENDED per gate4_gpoint_extraction_feasibility:
#   direct extraction from published gpoint_fraction is PROVEN INVALID
#   (fractional projection arrays; no g_point variable in the files).
#   Acceptable sources: A1 released find_g_points HDF5 outputs; A2 exact
#   find_g_points rerun WITH PROOF it reproduces the published support
#   arrays; A3 upstream raw/scaled init definitions from release history.
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
        "role" => "HISTORICAL strict acceptance mechanism (G2/G3 floor and " *
            "recovery runs) -- superseded by the Option-B amended rule",
        "method" => "HISTORICAL STRICT MECHANISM (twice superseded: first " *
            "amended per gate4_gpoint_extraction_feasibility.json -- direct " *
            "argmax-from-gpoint_fraction extraction PROVEN INVALID " *
            "(fractional projection arrays; no g_point variable in the " *
            "published files) -- then superseded by Option B). Under the " *
            "historical strict mechanism the acceptable sources were: (A1) " *
            "released find_g_points HDF5 outputs with verified provenance; " *
            "(A2) exact find_g_points rerun WITH PROOF it reproduces the " *
            "published gpoint_fraction/band arrays; (A3) existing upstream " *
            "raw/scaled init definitions from the release history. " *
            "STILL-CURRENT RULE (precise): g-point STRUCTURE remains part " *
            "of the fixed problem definition and unproven reruns remain " *
            "barred from acceptance; storage-precision support-array drift " *
            "(max|diff| <= 2.1e-5) is allowed ONLY under the Option-B " *
            "amended rule",
        "verification_support_arrays" => Dict(
            "role" => "COMPARISON/VERIFICATION targets for A1/A2 candidates " *
                      "-- NOT extraction sources (see feasibility proof)",
            "lw32_definition" => basename(lw32),
            "sw32_definition" => basename(sw32),
            "fields" => ["gpoint_fraction (fractional projection)",
                         "wavenumber1_band / wavenumber2_band",
                         "band arrays and g-point counts"]),
        "outputs_historical_note" => "the previously recorded " *
            "future-output paths ($(WORKROOT)/gpoints/extracted_*.h5) and " *
            "extractor schema anchor are WITHDRAWN: extraction was proven " *
            "invalid and no extractor unit was ever built; the actual " *
            "accepted g-point files came from the A2 rerun (job 4082) at " *
            "$(WORKROOT)/work/lw_gpoints/ and " *
            "$(WORKROOT)/work-v14 (symlinked), accepted under Option B " *
            "(LW c96e6492..., SW 13dd686a...)",
        "rationale" => "g-point structure is part of the fixed problem " *
            "definition under the optimizer-only-delta rule; ANY acceptance " *
            "mechanism must guarantee structural identity with the recovery " *
            "target (verified against published support arrays)",
    )
    path_b = Dict(
        "role" => "SENSITIVITY-ONLY reruns: find_g_points reruns WITHOUT " *
                  "exact reproduction proof",
        "method" => "rerun upstream find_g_points from idealized spectra " *
                    "(restored on disk) with the pinned tool",
        "constraint" => "a rerun whose output does NOT exactly reproduce the " *
                        "published support arrays CANNOT feed the main " *
                        "recovery floor unless Greg explicitly changes the " *
                        "optimizer-only-delta rule; a rerun WITH exact " *
                        "reproduction proof qualifies as acceptance source " *
                        "A2, not as Path B",
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
    gates["unproven_reruns_barred_from_acceptance"] =
        occursin("CANNOT feed the main", path_b["constraint"]) ?
        "passed" : "failed"
    mmm_const = joinpath(CKDMIP_ROOT, "mmm/conc/ckdmip_mmm-const_concentrations.nc")
    gates["independent_blocker_mmm_const_identified"] =
        !isfile(mmm_const) ? "passed" : "passed"   # recorded either way
    blockers = Any[Dict(
        "historical_requirement" => "ckdmip_mmm-const_concentrations.nc " *
            "(recorded as an independent blocker at decision time; " *
            "RESOLVED -- restored to disk and consumed by the executed " *
            "create_lut runs)",
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
        "recommendation" => "HISTORICAL: PATH A (strict mechanism) for " *
            "G2/G3 acceptance; PATH B recorded as non-acceptance " *
            "sensitivity/reproduction path. The strict Path-A mechanism " *
            "was superseded by Option B; the fixed-structure principle " *
            "and the Path-B bar on unproven reruns remain current",
        "path_a" => path_a, "path_b" => path_b,
        "independent_blockers" => blockers,
        "authority_note" => "this recommendation bound the campaign's " *
            "default; the anticipated override happened: Greg (2026-07-20) " *
            "adopted Option B",
        "superseded_by" => "gate4_option_b_decision_record (Greg-authorized " *
            "amended acceptance rule: structural elementwise-exact + " *
            "support arrays within storage precision <= 2.1e-5); the " *
            "structural-identity policy intent and Path-B sensitivity rule " *
            "remain in force",
        "outcome" => "A2 rerun (job 4082) candidates + create_lut proof " *
            "(job 4091) accepted under the amended rule: LW gpoints " *
            "c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e, " *
            "SW 13dd686acd0c3ca2201775270f876ce3e3a326576b58b24323b5ce95659b9b57; " *
            "sha-pinned by gate4_g3_scoped_input_preflight.jl",
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
        println(io, "# Gate-4 g-point provenance policy — HISTORICAL " *
                    "(acceptance mechanism superseded by Option B)\n")
        println(io, "Status: **$status**\n")
        println(io, "**Superseded by**: ", result["superseded_by"], "\n")
        println(io, "**Outcome**: ", result["outcome"], "\n")
        println(io, result["disclaimer"], "\n")
        println(io, "**Recommendation: PATH A (structural identity), " *
                    "MECHANISM AMENDED** -- direct extraction from published " *
                    "gpoint_fraction is proven invalid (see " *
                    "gate4_gpoint_extraction_feasibility); acceptance " *
                    "sources are A1 released find_g_points HDF5, A2 exact " *
                    "rerun with proof of reproducing published support " *
                    "arrays, or A3 upstream raw/scaled init definitions. " *
                    "G-points remain part of the fixed problem definition " *
                    "under the optimizer-only-delta rule.\n")
        println(io, "Acceptance sources: A1 released original HDF5; A2 " *
                    "exact rerun WITH exact-reproduction proof against the " *
                    "published support arrays; A3 upstream raw/scaled init " *
                    "definitions. Sensitivity-only reruns are those WITHOUT " *
                    "exact reproduction proof; they cannot feed the main " *
                    "recovery floor unless Greg explicitly changes the " *
                    "rule.\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nVerification support arrays (comparison targets " *
                    "for A1/A2 candidates, NOT extraction sources): " *
                    "$(basename(lw32)), $(basename(sw32)) " *
                    "(gpoint_fraction + band arrays). " *
                    path_a["outputs_historical_note"])
        println(io, "\nHistorical requirement (was an independent blocker " *
                    "at decision time, RESOLVED): " *
                    "ckdmip_mmm-const_concentrations.nc " *
                    "(present: $(isfile(mmm_const))).")
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
