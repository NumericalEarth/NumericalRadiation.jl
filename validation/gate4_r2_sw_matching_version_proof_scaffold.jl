# Gate-4 R2 SW MATCHING-VERSION proof scaffold (dry-run PLAN ONLY; refuses
# execution without an explicit authorization token) -- HISTORICAL
# POST-EXECUTION MODE when the quarantined v1.4 tree exists.
#
# EXECUTED (monitor-directed marking, 2026-08-12): Greg authorized R2
# ("go for R2", 2026-07-20); the plan below was executed via
# gate4_r2_execution_checkpoint.jl as jobs 4094/4095 (configure failures:
# adept.m4 -ladept dropped by --as-needed; bare LIBS breaking the first
# conftest) and job 4096 (COMPLETED rc=0 with the LDFLAGS+LIBS fix). The
# PRE-REGISTERED expectation was CONFIRMED: solar_spectral_irradiance is
# PRESENT and elementwise EXACT in the v1.4 output (absence RESOLVED as
# version skew) while the residual support-array drift is
# VERSION-INDEPENDENT (gate4_r2_finding_ledger:
# r2_ssi_resolved_drift_version_independent). The v1.4 raw output
# (99333fb5...) later became the accepted pre-scale SW execution artifact
# under Option B. When the v1.4 tree exists, this unit runs READ-ONLY
# HISTORICAL VERIFICATION (tree commit, built binary, output vs the
# finding ledger) and emits r2_scaffold_historical_executed; the
# pre-execution plan/pre-registration below is preserved VERBATIM as
# hypothesis evidence, and the original gate set is retained for the
# tree-absent world.
#
# Original plan (historical): build ecCKD at commit 23adaca (= the v1.4
# configure.ac bump; R1 established this as the strong source mapping for
# the published SW32 file) in a QUARANTINED tree, then rerun the SW raw
# create_lut proof with the EXISTING 4082 SW gpoints candidate, and
# re-run the SW comparisons.
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
    error("execute_r2 retired: intentionally unimplemented and superseded " *
          "-- the R2 executor landed as gate4_r2_execution_checkpoint.jl " *
          "(Greg-authorized) and was executed as jobs 4094/4095/4096; no " *
          "execution happens here on any path")
end

# fail-closed JSON normalizers (never a thrown MethodError on shape)
rp_obj(x) = x isa AbstractDict ? x : Dict{String, Any}()
rp_str(x) = x isa AbstractString ? String(x) : ""

# nonthrowing hash for the OUTPUT boundary: a vanished/unreadable file
# classifies as a failed gate with a reason, never a crash
rp_try_sha(p) = try
    # early missing-file return: deliberate missing-file fixtures never
    # leak sha256sum stderr; the try still covers TOCTOU races
    isfile(p) || return nothing
    split(strip(read(`sha256sum $p`, String)))[1]
catch
    nothing
end

# shared guarded pinned-artifact loader (fixture-run on tmp files via
# the absolute-path passthrough; the unit's SINGLE parsefile site,
# serving all four artifact edges): FIVE stable, distinct refusal
# classes with FIXED reasons -- missing; unparseable (parse failure);
# parses to a non-object (JSON null/array/scalar); case mismatch; not
# green (wrong status). Exact case is bound before the status check.
function rp_parse_pinned(name, expected_case, expected_status)
    path = isabspath(name) ? name : validation_results_path(name)
    isfile(path) ||
        return (false, "$expected_case missing", nothing)
    raw = try
        JSON.parsefile(path)
    catch
        return (false, "$expected_case unparseable (parse failure)",
                nothing)
    end
    raw isa AbstractDict ||
        return (false, "$expected_case parses to a non-object " *
                       "(JSON null/array/scalar)", nothing)
    c = rp_str(get(raw, "case", ""))
    c == expected_case ||
        return (false, "$expected_case case mismatch: " *
                       (isempty(c) ? "(missing/non-string)" : c), raw)
    s = rp_str(get(raw, "status", ""))
    s == expected_status ||
        return (false, "$expected_case not green: " *
                       (isempty(s) ? "(missing/non-string)" : s), raw)
    return (true, "ok", raw)
end

# PURE safe navigators used identically by production and fixtures (a
# fixture can never pass while production drifts):
# finding-ledger build/output shas -- shape deficiencies yield ""
rp_finding_shas(fin) = (
    rp_str(get(rp_obj(get(rp_obj(get(rp_obj(fin), "r2_run", nothing)),
        "build_provenance", nothing)),
        "create_look_up_table_sha256", nothing)),
    rp_str(get(rp_obj(get(rp_obj(get(rp_obj(fin), "r2_run", nothing)),
        "output", nothing)), "sha256", nothing)))

# finding-ledger attempt strings -- shape deficiencies yield ""
function rp_finding_attempts(fin)
    att = rp_obj(get(rp_obj(get(rp_obj(fin), "r2_run", nothing)),
                     "attempts", nothing))
    return (rp_str(get(att, "attempt_1", "")),
            rp_str(get(att, "attempt_2", "")),
            rp_str(get(att, "attempt_3", "")))
end

# promoted-artifacts access + normalized sha membership: a non-vector
# list never matches; non-dict entries normalize (never throw or
# falsely match)
rp_promoted_list(ob) = get(rp_obj(ob), "promoted_artifacts", nothing)
function rp_has_promoted_sha(ob, sha)
    arts = rp_promoted_list(ob)
    return arts isa AbstractVector &&
           any(rp_str(get(rp_obj(p), "sha256", "")) == sha for p in arts)
end

# precise Option-B promotion diagnostics (pure; fixture-run): a parse/
# case/status failure already carries ob_why and adds NOTHING here (no
# contradictory membership claim); a malformed finding sha means the
# promotion CANNOT BE VERIFIED; only then are non-vector and
# exact-sha-absence distinguished
function rp_ob_promotion_reason(ob_ok0, ledger_shape_ok, arts, member)
    ob_ok0 || return nothing
    ledger_shape_ok ||
        return "Option-B promotion cannot be verified: finding-ledger " *
               "output sha missing/malformed"
    arts isa AbstractVector ||
        return "Option-B promoted_artifacts missing/non-vector"
    member && return nothing
    return "Option-B record does not list the v1.4 raw output among " *
           "promoted artifacts"
end

# init-ledger SW acceptance sha (pure; fixture-run; same-helper
# standard as the finding-ledger fields)
rp_init_sw_sha(ip) = rp_str(get(rp_obj(get(rp_obj(get(rp_obj(ip),
    "acceptance_inits", nothing)), "sw", nothing)), "sha256", ""))

function main()
    fails = String[]
    gates = Dict{String, String}()

    # loader/navigator fixtures FIRST, through the SAME guarded code
    tdir = mktempdir()
    lt = Dict{String, Bool}()
    lt["missing_fails"] = begin
        r = rp_parse_pinned(joinpath(tdir, "absent.json"), "c", "s")
        !r[1] && r[2] == "c missing"
    end
    fpx = joinpath(tdir, "pa.json")
    write(fpx, "{")
    lt["malformed_fails"] = begin
        r = rp_parse_pinned(fpx, "c", "s")
        !r[1] && r[2] == "c unparseable (parse failure)"
    end
    write(fpx, "null")
    lt["null_non_object_fails"] = begin
        r = rp_parse_pinned(fpx, "c", "s")
        !r[1] && occursin("non-object", r[2])
    end
    write(fpx, "[1]")
    lt["array_non_object_fails"] = begin
        r = rp_parse_pinned(fpx, "c", "s")
        !r[1] && occursin("non-object", r[2])
    end
    write(fpx, "{\"case\": \"other\", \"status\": \"s\"}")
    lt["wrong_case_fails"] = begin
        r = rp_parse_pinned(fpx, "c", "s")
        !r[1] && occursin("case mismatch", r[2])
    end
    write(fpx, "{\"case\": \"c\", \"status\": \"totally_bogus\"}")
    lt["tampered_status_fails"] = begin
        r = rp_parse_pinned(fpx, "c", "s")
        !r[1] && occursin("not green", r[2])
    end
    write(fpx, "{\"case\": \"c\", \"status\": \"s\"}")
    lt["exact_green_captures"] = begin
        r = rp_parse_pinned(fpx, "c", "s")
        r[1] && r[2] == "ok" && r[3] isa AbstractDict
    end
    # finding-ledger deep-field navigation through the SAME production
    # helpers: every shape deficiency yields empty strings (controlled
    # failed gates), never a throw
    lt["ledger_shape_navigation"] = begin
        good = Dict("r2_run" => Dict(
            "build_provenance" =>
                Dict("create_look_up_table_sha256" => "a" ^ 64),
            "output" => Dict("sha256" => "b" ^ 64)))
        rp_finding_shas(good) == ("a" ^ 64, "b" ^ 64) &&
            rp_finding_shas(Dict{String, Any}()) == ("", "") &&
            rp_finding_shas(Dict("r2_run" => "x")) == ("", "") &&
            rp_finding_shas(Dict("r2_run" => Dict("output" =>
                Dict("sha256" => 5)))) == ("", "") &&
            rp_finding_shas(nothing) == ("", "")
    end
    lt["attempts_shape_navigation"] = begin
        good = Dict("r2_run" => Dict("attempts" => Dict(
            "attempt_1" => "j1", "attempt_2" => "j2",
            "attempt_3" => "j3")))
        rp_finding_attempts(good) == ("j1", "j2", "j3") &&
            rp_finding_attempts(Dict{String, Any}()) == ("", "", "") &&
            rp_finding_attempts(Dict("r2_run" =>
                Dict("attempts" => "x"))) == ("", "", "") &&
            rp_finding_attempts(Dict("r2_run" => Dict("attempts" =>
                Dict("attempt_1" => 7)))) == ("", "", "")
    end
    # promoted-artifacts scan through the SAME production helper:
    # non-vector refuses; non-dict entries normalize (never throw or
    # falsely match); exact sha matches
    lt["promotion_scan_normalized"] = begin
        mko(arts) = Dict("promoted_artifacts" => arts)
        rp_has_promoted_sha(mko([Dict("sha256" => "c" ^ 64)]), "c" ^ 64) &&
            !rp_has_promoted_sha(mko("not-a-vector"), "c" ^ 64) &&
            !rp_has_promoted_sha(Dict{String, Any}(), "c" ^ 64) &&
            !rp_has_promoted_sha(mko([1, "x",
                Dict("sha256" => "d" ^ 64)]), "c" ^ 64) &&
            rp_has_promoted_sha(mko([1, Dict("sha256" => "c" ^ 64)]),
                                "c" ^ 64)
    end
    # Option-B diagnostic branches through the SAME pure helper: a
    # classification failure adds nothing; malformed sha says cannot be
    # verified; non-vector and exact-absence stay distinct
    lt["ob_promotion_reason_branches"] = begin
        rp_ob_promotion_reason(false, false, "x", false) === nothing &&
            occursin("cannot be verified",
                     rp_ob_promotion_reason(true, false, "x", false)) &&
            occursin("missing/non-vector",
                     rp_ob_promotion_reason(true, true, "x", false)) &&
            occursin("does not list",
                     rp_ob_promotion_reason(true, true, Any[], false)) &&
            rp_ob_promotion_reason(true, true, Any[], true) === nothing
    end
    # init-ledger SW sha through the SAME pure helper: missing/wrong
    # nested containers and a non-string sha all yield ""
    lt["init_sw_sha_navigation"] = begin
        good = Dict("acceptance_inits" =>
                    Dict("sw" => Dict("sha256" => "e" ^ 64)))
        rp_init_sw_sha(good) == "e" ^ 64 &&
            rp_init_sw_sha(Dict{String, Any}()) == "" &&
            rp_init_sw_sha(Dict("acceptance_inits" => "x")) == "" &&
            rp_init_sw_sha(Dict("acceptance_inits" =>
                Dict("sw" => "y"))) == "" &&
            rp_init_sw_sha(Dict("acceptance_inits" =>
                Dict("sw" => Dict("sha256" => 5)))) == "" &&
            rp_init_sw_sha(nothing) == ""
    end
    lt["try_sha_nonthrowing"] =
        rp_try_sha(joinpath(tdir, "gone.bin")) === nothing &&
        rp_try_sha(fpx) isa AbstractString
    rm(tdir, recursive = true, force = true)
    gates["prerequisite_loader_fixture_tests"] =
        all(values(lt)) ? "passed" : "failed"
    all(values(lt)) || push!(fails, "prerequisite loader fixture " *
        "failures: " * join(sort([k for (k, v) in lt if !v]), ", "))

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
        rp_try_sha(SW_CANDIDATE) == SW_CANDIDATE_SHA
    gates["sw_candidate_present_hash_pinned"] = sha_ok ? "passed" : "failed"
    sha_ok || push!(fails, "SW candidate missing, unreadable, or " *
                           "hash-mismatched")
    r1_ok, r1_why, _ = rp_parse_pinned(
        validation_results_path("gate4_r1_release_provenance_probe.json"),
        "gate4_r1_release_provenance_probe",
        "r1_sw_mapping_found_lw_ambiguous")
    gates["r1_mapping_prerequisite"] = r1_ok ? "passed" : "failed"
    r1_ok || push!(fails, r1_why)

    # POST-EXECUTION: the quarantined v1.4 tree exists -> read-only
    # historical verification against the R2 finding ledger (never a
    # stale-state failure). The tree-absent original gate is retained in
    # the else-branch.
    historical = ispath(V14_TREE)
    executed = Dict{String, Any}()
    if historical
        fin_ok, fin_why, fin = rp_parse_pinned(
            validation_results_path("gate4_r2_finding_ledger.json"),
            "gate4_r2_finding_ledger",
            "r2_ssi_resolved_drift_version_independent")
        gates["r2_finding_ledger_verified"] = fin_ok ? "passed" : "failed"
        fin_ok || push!(fails, fin_why)
        fin_obj = rp_obj(fin)
        tree_commit = try
            strip(read(`git -C $V14_TREE rev-parse HEAD`, String))
        catch; "unreadable" end
        gates["v14_tree_matches_executed_commit"] =
            tree_commit == V14_COMMIT ? "passed" : "failed"
        tree_commit == V14_COMMIT ||
            push!(fails, "v1.4 tree HEAD $tree_commit != $V14_COMMIT")
        # ledger deep fields via the SAME pure navigators the fixtures
        # exercise: shape deficiencies are failed gates with reasons,
        # never a deep-index throw
        exp_bin, exp_out = rp_finding_shas(fin)
        ledger_shape_ok = occursin(r"^[0-9a-f]{64}$", exp_bin) &&
                          occursin(r"^[0-9a-f]{64}$", exp_out)
        gates["finding_ledger_structure_valid"] =
            ledger_shape_ok ? "passed" : "failed"
        ledger_shape_ok || push!(fails, "finding ledger r2_run build/" *
            "output sha fields missing or malformed (safe navigation)")
        bin_path = "$V14_TREE/src/ecckd/create_look_up_table"
        bin_ok = ledger_shape_ok && rp_try_sha(bin_path) == exp_bin
        gates["v14_binary_matches_finding_ledger"] = bin_ok ? "passed" : "failed"
        bin_ok || push!(fails, "v1.4 built binary missing, unreadable, " *
                               "or != ledger sha")
        out_path = "$G4WORK/work-v14/sw_raw-ckd-definition/" *
                   "ecckd-1.4_sw_raw-ckd-definition_climate_rgb-tol0.047.nc"
        out_ok = ledger_shape_ok && rp_try_sha(out_path) == exp_out
        gates["v14_output_matches_finding_ledger"] = out_ok ? "passed" : "failed"
        out_ok || push!(fails, "v1.4 raw output missing, unreadable, " *
                               "or != ledger sha")
        ob_ok0, ob_why, ob = rp_parse_pinned(
            validation_results_path("gate4_option_b_decision_record.json"),
            "gate4_option_b_decision_record",
            "option_b_adopted_candidates_promoted")
        ob_ok0 || push!(fails, ob_why)
        # promotion scan and PRECISE diagnostics through the SAME pure
        # helpers the fixtures exercise: non-dict entries normalize and
        # can neither throw nor falsely match; a classification failure
        # never appends a contradictory membership claim
        arts = rp_promoted_list(ob)
        member = rp_has_promoted_sha(ob, exp_out)
        ob_ok = ob_ok0 && ledger_shape_ok && member
        gates["option_b_promotion_of_v14_raw_verified"] = ob_ok ? "passed" : "failed"
        ob_reason = rp_ob_promotion_reason(ob_ok0, ledger_shape_ok,
                                           arts, member)
        ob_reason === nothing || push!(fails, ob_reason)
        # attempt history VERIFIED from the finding ledger through the
        # SAME pure navigator, never hardcoded
        a1, a2, a3 = rp_finding_attempts(fin)
        attempts_ok = occursin("4094", a1) && occursin("FAILED", a1) &&
                      occursin("4095", a2) && occursin("FAILED", a2) &&
                      occursin("4096", a3) && occursin("COMPLETED", a3) &&
                      occursin("rc=0", a3)
        gates["attempt_history_verified"] = attempts_ok ? "passed" : "failed"
        attempts_ok || push!(fails, "finding-ledger attempt strings do not " *
            "carry 4094 FAILED / 4095 FAILED / 4096 COMPLETED rc=0")
        # later job-4099 scaled-SW claim VERIFIED against the init
        # provenance ledger + live file hash, never hardcoded
        ip_ok, ip_why, ip = rp_parse_pinned(
            validation_results_path("gate4_init_provenance_ledger.json"),
            "gate4_init_provenance_ledger",
            "acceptance_inits_complete")
        ip_ok || push!(fails, ip_why)
        exp_scaled = rp_init_sw_sha(ip)
        sw_init_path = "$G4WORK/work-v14/sw_raw-ckd-definition/" *
            "ecckd-1.4_sw_scaled-ckd-definition_climate_rgb-tol0.047.nc"
        scaled_ok = ip_ok &&
            occursin(r"^[0-9a-f]{64}$", exp_scaled) &&
            startswith(exp_scaled, "74d8be65") &&
            rp_try_sha(sw_init_path) == exp_scaled
        gates["scaled_sw_init_4099_verified"] = scaled_ok ? "passed" : "failed"
        scaled_ok || push!(fails, "job-4099 scaled SW init claim failed " *
            "verification (init ledger status/sha or live file hash)")
        executed = Dict(
            "authorization" => "Greg, 2026-07-20: 'go for R2'",
            # rendered summary DERIVED from the verified ledger fields
            "jobs" => "$a1; $a2; $a3",
            "outcome_verified" => "finding ledger status " *
                "$(rp_str(get(fin_obj, "status", "?"))): SSI PRESENT + " *
                "elementwise EXACT (absence resolved as version skew); " *
                "residual drift version-independent",
            "v14_binary_sha256" => exp_bin,
            "v14_raw_output_sha256" => exp_out,
            "later_disposition" => "v1.4 raw promoted under Option B as " *
                "the accepted pre-scale SW artifact; scaled SW acceptance " *
                "init verified against gate4_init_provenance_ledger " *
                "($(rp_str(get(rp_obj(ip), "status", "?")))) and the " *
                "live file: $exp_scaled")
    else
        gates["v14_tree_not_yet_created"] = !ispath(V14_TREE) ? "passed" : "failed"
    end
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

    # NOTE: gate4_r2_execution_checkpoint.jl:124 requires the pre-execution
    # token by exact match; that unit is itself post-execution and will
    # need its own historical marking before any rerun (flagged to the
    # monitor) -- honesty of THIS unit's status takes precedence.
    status = !(isempty(fails) && all(v -> v == "passed", values(gates))) ?
        "r2_scaffold_failed" :
        historical ? "r2_scaffold_historical_executed" :
                     "r2_scaffold_ready_awaiting_authorization"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    ghead = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_r2_sw_matching_version_proof_scaffold",
        "data_mode" => historical ?
            "historical_post_execution_verification_only" :
            "dry_run_plan_only_no_execution",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "prerequisite_loader_fixture_verdicts" => lt,
        "authorization_token_required" => "r2_matching_version_go " *
            "(historical: authorization was given and consumed)",
        "plan" => plan,
        "executed" => executed,
        "provenance" => Dict("branch" => branch, "generated_from_head" => ghead,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => historical ?
            "HISTORICAL post-execution record: the plan below was executed " *
            "(Greg-authorized) as jobs 4094/4095/4096 and verified against " *
            "the R2 finding ledger; the pre-registered plan/expectation is " *
            "preserved verbatim; nothing executed by this unit." :
            "plan artifact only; no checkout, build, run, or " *
            "submission; no floor, objective, acceptance, or " *
            "init-generation promotion; execution requires the " *
            "explicit authorization token.",
    )
    mkpath(dirname(R2_RESULTS_JSON))
    open(R2_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(R2_RESULTS_MD, "w") do io
        println(io, historical ?
            "# Gate-4 R2 SW matching-version proof scaffold — HISTORICAL " *
            "(executed as jobs 4094/4095/4096)\n" :
            "# Gate-4 R2 SW matching-version proof scaffold\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        if historical
            println(io, "**Executed**: $(executed["authorization"]); " *
                        "$(executed["jobs"]). $(executed["outcome_verified"]). " *
                        "$(executed["later_disposition"]).\n")
        end
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, historical ?
            "\nAuthorization token at plan time (consumed): " *
            "`r2_matching_version_go`\n" :
            "\nAuthorization token required: `r2_matching_version_go`\n")
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
    return status in ("r2_scaffold_ready_awaiting_authorization",
                      "r2_scaffold_historical_executed") ? 0 : 1
end

exit(main())
