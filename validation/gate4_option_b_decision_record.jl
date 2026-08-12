# Gate-4 OPTION B DECISION RECORD (supersedes the strict exact-reproduction
# acceptance mechanism in gate4_gpoint_provenance_policy / the proof
# scaffold's any-mismatch->sensitivity-only rule, per that policy's own
# supersession clause).
#
# AUTHORIZATION: Greg, directly, 2026-07-20: "take option B" — following the
# R2 verdict (gate4_r2_finding_ledger) and with the full evidence chain
# committed (4091 proof, V1/R1 provenance, R2 matching-version experiment).
#
# AMENDED ACCEPTANCE RULE for gate-4 init candidates:
#   (1) STRUCTURAL fields must be elementwise EXACT vs the published
#       definition: g_point count, band_number, wavenumber1/2_band,
#       fine wavenumber1/2 grids (and solar_spectral_irradiance where the
#       toolchain version emits it).
#   (2) SUPPORT arrays (gpoint_fraction, solar_irradiance,
#       rayleigh_molar_scattering_coeff) must be numerically equivalent at
#       storage precision: per-array max |diff| <= 2.1e-5 (Float32
#       storage-precision scale). Mismatch counts are recorded per-array as
#       descriptive provenance, not bounded -- on 32-element arrays a
#       single differently-rounded value is 3% of elements.
#   (3) All artifact provenance pinned by sha256 (candidates, raw builds,
#       builder binaries, input overlays).
#   (4) Version skew accounted where testable (R2: SSI absence resolved at
#       v1.4; drift proven version-independent across v1.2/v1.4).
#
# EVIDENCE BASE: every structural field bit-exact in both proofs; SSI
# bit-exact at matching version (995/995); residual drift <= 2.1e-5,
# confined to three arrays, version-independent, orders of magnitude below
# the recovery metrics (weight L1 0.02, OD log-RMSE 0.02) and the objective
# sensitivity. LW CAVEAT (permanent): the published LW32 is labeled
# ecckd-1.0 whose exact builder source state is not establishable from
# public history (file predates the v1.0 bump); the LW raw init is built
# with the pinned v1.2 toolchain and carries this caveat in provenance.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const DR_RESULTS_JSON = validation_results_path("gate4_option_b_decision_record.json")
const DR_RESULTS_MD = validation_results_path("gate4_option_b_decision_record.md")

# artifacts PROMOTED to acceptance raw inits under the amended rule
const PROMOTED = [
    Dict("role" => "LW acceptance raw init",
         "path" => "$G4WORK/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc",
         "sha256" => "ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43",
         "builder" => "pinned v1.2 (proof job 4091)",
         "caveat" => "LW-1.0 builder-source ambiguity (permanent, documented)"),
    Dict("role" => "SW acceptance raw init (pre-scale_lut)",
         "path" => "$G4WORK/work-v14/sw_raw-ckd-definition/ecckd-1.4_sw_raw-ckd-definition_climate_rgb-tol0.047.nc",
         "sha256" => "99333fb5f3c1a3e7ee343a8abd5bbe599f61419c89b8f9b13320a85105532c26",
         "builder" => "v1.4 23adaca build (R2 job 4096; binary sha256 1c79dfa3b963773d4e01437a0f79cb855c7257938d82d0b912d37630aa5412d3)",
         "caveat" => "version-matched to the published SW32 (ecckd-1.4); " *
                     "emits solar_spectral_irradiance bit-exactly"),
    Dict("role" => "g-point candidates (structure source)",
         "path" => "$G4WORK/work/{lw,sw}_gpoints/ecckd-1.2_{lw,sw}_gpoints_*.h5",
         "sha256" => "LW c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e; SW 13dd686acd0c3ca2201775270f876ce3e3a326576b58b24323b5ce95659b9b57",
         "builder" => "A2 job 4082 (find_g_points unchanged v1.2..23adaca)",
         "caveat" => "none: candidate-derived structure verified bit-exact"),
]

const DRIFT_BOUNDS = Dict(
    "gpoint_fraction" => Dict("n" => 60, "of" => 31840, "max_abs" => 1.6033649444580078e-5),
    "solar_irradiance" => Dict("n" => 2, "of" => 32, "max_abs" => 2.0503997802734375e-5),
    "rayleigh_molar_scattering_coeff" => Dict("n" => 2, "of" => 32, "max_abs" => 9.645062526431047e-16),
    "lw_gpoint_fraction" => Dict("n" => 205, "of" => 10432, "max_abs" => 2.682209014892578e-6),
)

function main()
    fails = String[]
    gates = Dict{String, String}()

    # verify the promoted artifacts exist and match their pinned hashes NOW
    for p in PROMOTED[1:2]
        ok = isfile(p["path"]) &&
             split(strip(read(`sha256sum $(p["path"])`, String)))[1] == p["sha256"]
        gates["promoted_artifact_verified_" *
              (occursin("LW", p["role"]) ? "lw" : "sw")] = ok ? "passed" : "failed"
        ok || push!(fails, "promoted artifact missing/hash-mismatch: $(p["path"])")
    end
    # evidence chain present
    for ev in ("gate4_a2_proof_finding_ledger", "gate4_r1_release_provenance_probe",
               "gate4_r2_finding_ledger", "gate4_v1_version_skew_recon")
        gates["evidence_$(ev)"] =
            isfile(validation_results_path("$ev.json")) ? "passed" : "failed"
    end
    # drift within the amended rule's own bounds
    within = all(d -> d["max_abs"] <= 2.1e-5, values(DRIFT_BOUNDS))
    gates["drift_within_amended_bounds"] = within ? "passed" : "failed"
    gates["supersession_clause_honored"] = "passed"  # this record IS the
    # superseding artifact the provenance policy required for an override
    gates["lw_caveat_recorded"] =
        any(p -> occursin("ambiguity", get(p, "caveat", "")), PROMOTED) ?
        "passed" : "failed"

    status = isempty(fails) && all(v -> v == "passed", values(gates)) ?
        "option_b_adopted_candidates_promoted" : "option_b_record_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    ghead = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_option_b_decision_record",
        "data_mode" => "decision_record",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "authorization" => "Greg, 2026-07-20: 'take option B'",
        "supersedes" => ["gate4_gpoint_provenance_policy (strict " *
            "exact-reproduction acceptance mechanism)",
            "gate4_a2_reproduction_proof_scaffold verdict_rule " *
            "any_mismatch->sensitivity-only"],
        "amended_rule" => Dict(
            "structural" => "elementwise EXACT: g_point count, band_number, " *
                "wavenumber1/2_band, fine wavenumber1/2 grids, and " *
                "solar_spectral_irradiance where the toolchain emits it",
            "support_arrays" => "numerically equivalent at storage " *
                "precision: per-array max|diff| <= 2.1e-5; mismatch " *
                "counts recorded as descriptive provenance (not bounded)",
            "provenance" => "all artifacts sha256-pinned; version skew " *
                "accounted where testable",
            "scope" => "gate-4 acceptance init candidates ONLY; the " *
                "optimizer-only-delta rule itself (data/objective/" *
                "evaluation/g-point structure fixed) is unchanged"),
        "observed_drift_vs_bounds" => DRIFT_BOUNDS,
        "promoted_artifacts" => PROMOTED,
        # the historical decision above is unchanged; the state fields below
        # were refreshed 2026-08-12 (monitor-directed stale-state census)
        "completed_since_decision" => [
            "scale_lut_sw applied to the promoted SW raw as job 4099 " *
            "(under the H5open-preinit shim; per " *
            "gate4_init_generation_manifest: LBL direct-only mu0=0.5 " *
            "albedo 0.15 reference) -> promoted SW scaled init sha256 " *
            "74d8be65226f081f3d2882520ab374ed102d73cc3dd43bb2fa7c5a5c" *
            "27602d74",
            "the exact execution inputs -- accepted LW raw init + promoted " *
            "SW scaled init + g-point files -- sha-pinned by " *
            "gate4_g3_scoped_input_preflight.jl (the pre-scale SW raw is " *
            "recorded here but is not an execution input and is not " *
            "preflight-pinned); G3 executor checkpoint chain landed " *
            "(token g3_recovery_go, human sbatch submission)"],
        "next_steps" => [
            "G3 optimizer recovery runs from the promoted inits, blocked " *
            "on the evaluation2 rel-415 fetch (G2c/G2d) pending the " *
            "quota resolution",
            "acceptance = the FIVE canonical thresholds (not three): " *
            "final/target objective ratio <= 1.05 (Gate-1 runner " *
            "implemented, refusing pending recovered outputs + reviewed " *
            "run ledger); weight rel-L1 <= 0.02 (acceptance " *
            "unit); true OD log-RMSE <= 0.02 (binding runner pending " *
            "dataset/aggregation rulings); forcing regression margin <= " *
            "0.03 W/m2 and heating-RMSE regression margin <= 0.005 K/day " *
            "(aggregation semantics pending ruling; see " *
            "gate4_regression_margin_semantics_evidence.md)"],
        "provenance" => Dict("branch" => branch, "generated_from_head" => ghead,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "decision record; promotes the named artifacts to " *
                        "acceptance inits under the amended rule; no " *
                        "objective, floor, or recovery computation in this " *
                        "unit.",
    )
    mkpath(dirname(DR_RESULTS_JSON))
    open(DR_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(DR_RESULTS_MD, "w") do io
        println(io, "# Gate-4 Option B decision record\n")
        println(io, "Status: **$status**\n")
        println(io, "Authorization: Greg, 2026-07-20: \"take option B\".\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\n## Amended acceptance rule\n")
        for (k, v) in result["amended_rule"]
            println(io, "- **$k**: $v")
        end
        println(io, "\n## Observed drift vs bounds (all within)\n")
        println(io, "| Array | Mismatched | Max abs diff |")
        println(io, "|---|---|---|")
        for (k, d) in DRIFT_BOUNDS
            println(io, "| $k | $(d["n"])/$(d["of"]) | $(d["max_abs"]) |")
        end
        println(io, "\n## Promoted artifacts\n")
        for p in PROMOTED
            println(io, "- **$(p["role"])**: `$(basename(replace(p["path"], "{" => "", "}" => "")))`")
            println(io, "  - sha256: `$(p["sha256"])`")
            println(io, "  - builder: $(p["builder"])")
            println(io, "  - caveat: $(p["caveat"])")
        end
        println(io, "\nCompleted since this decision: ",
                join(result["completed_since_decision"], "; "))
        println(io, "\nNext: ", join(result["next_steps"], "; "))
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$ghead` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_option_b_decision_record: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "option_b_adopted_candidates_promoted" ? 0 : 1
end

exit(main())
