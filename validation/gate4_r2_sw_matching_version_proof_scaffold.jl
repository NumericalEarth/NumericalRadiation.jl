# Gate-4 R2 SW MATCHING-VERSION proof scaffold (dry-run PLAN ONLY; refuses
# execution without an explicit authorization token).
#
# Plan: build ecCKD at commit 23adaca (= the v1.4 configure.ac bump; R1
# established this as the strong source mapping for the published SW32
# file) in a QUARANTINED tree, then rerun the SW raw create_lut proof with
# the EXISTING 4082 SW gpoints candidate, and re-run the SW comparisons.
#
# EXPECTED OUTCOME (pre-registered, from R1): the solar_spectral_irradiance
# ABSENCE is expected to RESOLVE (v1.4 ckd_model.cpp persists the variable);
# the small gpoint_fraction/solar_irradiance/rayleigh support-array drift
# MAY REMAIN UNRESOLVED -- it is not localized to any identified source
# diff and may stem from input/provenance/build-config differences.
#
# THIS UNIT EXECUTES NOTHING: no checkout, no build, no run, no submission,
# no floor/objective/acceptance/init promotion.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const R2_RESULTS_JSON = validation_results_path("gate4_r2_sw_matching_version_proof_scaffold.json")
const R2_RESULTS_MD = validation_results_path("gate4_r2_sw_matching_version_proof_scaffold.md")

const V14_COMMIT = "23adaca3344f4b53f109f3bd9533a5ed62998ec0"
const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const V14_TREE = "/shared/home/greg/ecckd-derived-flux-work/ecckd-v1.4-23adaca"
const SW_CANDIDATE = "$G4WORK/work/sw_gpoints/ecckd-1.2_sw_gpoints_climate_rgb-tol0.047.h5"
const SW_CANDIDATE_SHA = "13dd686acd0c3ca2201775270f876ce3e3a326576b58b24323b5ce95659b9b57"

# execution refusal: the future executor must be called with this exact
# token by a human-authorized turn; this scaffold NEVER supplies it
function execute_r2(; authorize::Symbol = :refused)
    authorize === :r2_matching_version_go ||
        error("REFUSED: R2 execution requires authorize=:r2_matching_version_go " *
              "(explicit go from Greg/monitor); this scaffold never executes")
    error("not implemented in the scaffold unit; the executor lands only " *
          "after authorization")
end

function main()
    fails = String[]
    gates = Dict{String, String}()

    plan = Dict(
        "objective" => "SW-only matching-version proof: does a v1.4 " *
            "(23adaca) build emit solar_spectral_irradiance and reproduce " *
            "the published SW32 support arrays exactly?",
        "source_checkout" => Dict(
            "repo" => "https://github.com/ecmwf-ifs/ecckd.git",
            "commit" => V14_COMMIT,
            "verify_after_checkout" => [
                "configure.ac AC_INIT version string reads 1.4",
                "ChangeLog head contains 'version 1.4 (November 2022)' " *
                "with the SSI-save entry",
                "ckd_model.cpp references solar_spectral_irradiance " *
                "(read/define/write persistence present)"],
            "tree" => "$V14_TREE (QUARANTINED; the pinned v1.2 workcopy " *
                      "and its built binaries are never touched)"),
        "build_prerequisites" => Dict(
            "toolchain_parity" => "same deps and flags as the pinned v1.2 " *
                "build, from its config.log: ./configure " *
                "--with-adept=/shared/home/greg/local/adept-2-install " *
                "--with-netcdf=/shared/home/greg/local/ckdmip-stack",
            "steps" => ["autoreconf -i (if configure absent)",
                        "./configure <flags above>", "make -j",
                        "record: gcc/adept/netcdf versions + sha256 of the " *
                        "built create_look_up_table binary"],
            "where" => "Slurm cpu partition or cpu-large; NEVER the head " *
                       "node for the proof run itself; build may be " *
                       "head-node-acceptable if quick but default to Slurm"),
        "proof_run" => Dict(
            "input_candidate" => Dict(
                "path" => SW_CANDIDATE,
                "sha256_must_match" => SW_CANDIDATE_SHA,
                "reuse_rationale" => "R1/monitor verified v1.2..23adaca " *
                    "does NOT change find_g_points.cpp, so a v1.4 " *
                    "candidate regeneration would be code-identical; " *
                    "reusing the hash-pinned 4082 candidate isolates the " *
                    "create_lut version delta"),
            "mechanism" => "TESTCOPY-style isolated test dir from the " *
                "v1.4 checkout; sed-patch the same five config.h vars as " *
                "the 4091 proof (CKDMIP_DATA_DIR, WORK_DIR -> a NEW " *
                "quarantined v1.4 work subtree, BINDIR -> the v1.4 build, " *
                "MMM_SW_SPECTRA_DIR overlay, CLOUD_SPECTRUM absolute); " *
                "stage-0 refuses on candidate hash mismatch or stale " *
                "outputs; then APPLICATION=climate BAND_STRUCTURE=rgb " *
                "TOLERANCE=0.047 bash create_lut_sw.sh ONLY",
            "expected_output" => "$G4WORK/work-v14/sw_raw-ckd-definition/" *
                "ecckd-1.4_sw_raw-ckd-definition_climate_rgb-tol0.047.nc " *
                "(prefix follows the v1.4 ECCKD_PREFIX; sha256 echoed to " *
                "the job log and recorded in the outcome ledger)"),
        "comparisons" => [
            "g_count == 32",
            "gpoint_fraction elementwise EXACT vs published SW32",
            "wavenumber1_band / wavenumber2_band EXACT",
            "band_number EXACT",
            "wavenumber1 / wavenumber2 fine grids EXACT",
            "solar_irradiance EXACT",
            "rayleigh_molar_scattering_coeff EXACT",
            "solar_spectral_irradiance PRESENT and elementwise EXACT " *
            "(the headline question)"],
        "verdict_rules" => Dict(
            "ssi_emitted_and_exact" => "SSI-absence finding RESOLVED as " *
                "version skew (strong confirmation of R1)",
            "ssi_emitted_but_inexact" => "absence resolved; SSI values " *
                "join the unresolved-drift set",
            "ssi_still_absent" => "R1 mapping hypothesis WRONG for the " *
                "build path used; escalate as new finding",
            "all_sw_fields_exact" => "SW candidate promotable PENDING " *
                "Greg's rule decision AND the open LW-1.0 mapping " *
                "ambiguity; promotion is NOT automatic",
            "drift_persists" => "EXPECTED possibility: drift attributed to " *
                "non-source factors (input data provenance, build config); " *
                "remains sensitivity-only; feeds Greg's A/B decision",
            "drift_worsens" => "investigate before any further use"),
        "guardrails" => [
            "this scaffold executes NOTHING (gated below)",
            "executor requires authorize=:r2_matching_version_go",
            "quarantined v1.4 tree + separate work-v14 subtree; pinned " *
            "v1.2 workcopy, its binaries, and the 4091 proof outputs are " *
            "never modified",
            "no floor/objective/acceptance/init-generation promotion " *
            "regardless of outcome; promotion remains Greg's rule decision"],
        "expected_outcome_statement" => "SSI emission expected to resolve; " *
            "support-array drift may remain unresolved (per R1's cautious " *
            "statement -- not localized to any identified source diff)",
    )

    # --- gates ------------------------------------------------------------
    cand_ok = isfile(SW_CANDIDATE)
    sha_ok = cand_ok &&
        split(strip(read(`sha256sum $SW_CANDIDATE`, String)))[1] == SW_CANDIDATE_SHA
    gates["sw_candidate_present_hash_pinned"] = sha_ok ? "passed" : "failed"
    sha_ok || push!(fails, "SW candidate missing or hash-mismatched")
    r1 = JSON.parsefile(validation_results_path("gate4_r1_release_provenance_probe.json"))
    gates["r1_mapping_prerequisite"] =
        r1["status"] == "r1_sw_mapping_found_lw_ambiguous" ? "passed" : "failed"
    gates["v14_tree_not_yet_created"] = !ispath(V14_TREE) ? "passed" : "failed"
    gates["refuses_without_token"] = try
        execute_r2(); "failed"
    catch err
        occursin("REFUSED", sprint(showerror, err)) ? "passed" : "failed"
    end
    self_src = read(@__FILE__, String)
    exec_tokens = [Regex("run\\(`" * "git clone"), Regex("run\\(`" * "make"),
                   Regex("run\\(`" * "sb" * "atch"),
                   Regex("run\\(`[^`]*configure")]
    gates["no_exec_in_this_unit"] =
        all(t -> !occursin(t, self_src), exec_tokens) ? "passed" : "failed"
    gates["expected_outcome_pre_registered"] =
        occursin("may remain unresolved",
                 plan["expected_outcome_statement"]) ? "passed" : "failed"
    gates["promotion_not_automatic"] =
        occursin("NOT automatic", plan["verdict_rules"]["all_sw_fields_exact"]) ?
        "passed" : "failed"

    status = isempty(fails) && all(v -> v == "passed", values(gates)) ?
        "r2_scaffold_ready_awaiting_authorization" : "r2_scaffold_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    ghead = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_r2_sw_matching_version_proof_scaffold",
        "data_mode" => "dry_run_plan_only_no_execution",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "authorization_token_required" => "r2_matching_version_go",
        "plan" => plan,
        "provenance" => Dict("branch" => branch, "generated_from_head" => ghead,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "plan artifact only; no checkout, build, run, or " *
                        "submission; no floor, objective, acceptance, or " *
                        "init-generation promotion; execution requires the " *
                        "explicit authorization token.",
    )
    mkpath(dirname(R2_RESULTS_JSON))
    open(R2_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(R2_RESULTS_MD, "w") do io
        println(io, "# Gate-4 R2 SW matching-version proof scaffold\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nAuthorization token required: " *
                    "`r2_matching_version_go`\n")
        println(io, "## Plan\n")
        println(io, "- **Objective**: ", plan["objective"])
        println(io, "- **Checkout**: `$(V14_COMMIT)` into `$(V14_TREE)` " *
                    "with post-checkout verifications (configure.ac 1.4, " *
                    "ChangeLog v1.4 SSI entry, ckd_model.cpp persistence)")
        println(io, "- **Build**: toolchain parity with the pinned v1.2 " *
                    "build (`--with-adept`/`--with-netcdf` flags from its " *
                    "config.log); record dep versions + binary sha256")
        println(io, "- **Proof run**: reuse the hash-pinned 4082 SW " *
                    "candidate (find_g_points.cpp unchanged in " *
                    "v1.2..23adaca), isolated TESTCOPY with the five " *
                    "sed-patched vars, create_lut_sw.sh ONLY, new " *
                    "quarantined work-v14 subtree")
        println(io, "- **Comparisons**: the 8 SW checks incl. the headline " *
                    "solar_spectral_irradiance PRESENT+EXACT")
        println(io, "\n## Verdict rules\n")
        for (k, v) in plan["verdict_rules"]
            println(io, "- **$k**: $v")
        end
        println(io, "\n**Expected outcome (pre-registered)**: ",
                plan["expected_outcome_statement"])
        println(io, "\nGuardrails: ", join(plan["guardrails"], "; "), ".")
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$ghead` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_r2_sw_matching_version_proof_scaffold: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "r2_scaffold_ready_awaiting_authorization" ? 0 : 1
end

exit(main())
