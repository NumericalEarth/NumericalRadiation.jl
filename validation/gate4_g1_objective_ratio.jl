# Gate-4 GATE-1 OBJECTIVE-RATIO RUNNER (refusing; design note rev 2).
#
# Binding quantity (canonical, pinned from the archived campaign path):
# the PACKAGE-NATIVE normalized hard radiation objective -- hard_objective
# (ecckd_published_model_accuracy.jl:183-244) = the WORST threshold-
# normalized (case, metric) row over REDUCED_CASES (2 clear-sky cases x
# 12 rows: 4 flux RMSE, 4 flux max-abs, heating RMSE/max-abs, TOA/surface
# forcing), evaluated on the recovered LW32+SW32 pair JOINTLY through
# read_ecckd_tabulated_gas_optics -> case_metrics -> hard_objective.
# Gate-1 binds hard_objective.value / 1.0 <= 1.05
# (final_objective_target_ratio_max, ecckd_training_recovery_targets.jl:32).
# It is NOT a ratio of upstream optimizer costs; the full real-data
# UPSTREAM objective/floor comparison remains a separate outstanding item.
#
# REFUSING RUNNER (monitor directive): this unit refuses until a
# REVIEWED run ledger and recovered pair exist. The published-pair
# evaluation below is SELF-TEST CONTEXT ONLY and is never reported as
# recovered acceptance. Refusal ladder mirrors the acceptance unit
# (gate4_g3_acceptance_comparison.jl):
#   1 missing recovered outputs -> g1_waiting_for_optimizer_outputs
#   2 missing run ledger        -> g1_blocked_missing_run_ledger
#   3 invalid run ledger        -> g1_blocked_invalid_run_ledger
#   4 ledger/output sha drift   -> g1_blocked_ledger_hash_mismatch
#   5 boundary-compat drift vs the published pair through the SAME
#     references -> g1_blocked_boundary_compatibility_drift
#     (the published 32x32 row itself has PARTIAL SW incoming/direct
#     spectral compatibility -- pass #5419 -- so the gate is
#     flag-pattern EQUALITY with the published pair, not all-true)
# then g1_objective_ratio_passed / g1_objective_ratio_failed.
#
# Reuses the include-safe published-accuracy chain; validate_run_ledger +
# hex64 are copied VERBATIM from gate4_g3_acceptance_comparison.jl (that
# file ends in exit(main()) and must never be include()d).

include(joinpath(@__DIR__, "ecckd_published_model_accuracy.jl"))

import JSON
using Dates

const G1OR_RESULTS_JSON = validation_results_path("gate4_g1_objective_ratio.json")
const G1OR_RESULTS_MD = validation_results_path("gate4_g1_objective_ratio.md")

# same recovered-output conventions as the acceptance unit
const G1OR_G4 = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const G1OR_LW_RECOVERED = "$G1OR_G4/work/lw_ckd-definition/" *
    "ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc"
const G1OR_SW_RECOVERED = "$G1OR_G4/work-v14/sw_ckd-definition/" *
    "ecckd-1.4_sw_ckd-definition_climate_rgb-tol0.047.nc"
const G1OR_RUN_LEDGER = validation_results_path("gate4_g3_run_ledger.json")

const G1OR_RATIO_MAX = 1.05      # final_objective_target_ratio_max
const G1OR_HARD_TARGET = 1.0

# archived published 32x32 baseline (audit-trail-2026-07-17
# ecckd_published_model_accuracy.json, extraction sha c16591d2...): the
# self-test context value guarding environment drift
const G1OR_PUBLISHED_BASELINE = 0.18218645425029933
const G1OR_BASELINE_REL_TOL = 1e-6

g1or_filesha(p) = split(strip(read(`sha256sum $p`, String)))[1]

# --- copied VERBATIM from gate4_g3_acceptance_comparison.jl:91-113 ---------
hex64(x) = x isa AbstractString && occursin(r"^[0-9a-f]{64}$", x)

function validate_run_ledger(ld)
    get(ld, "case", "") == "gate4_g3_run_ledger" ||
        return (false, "case != gate4_g3_run_ledger")
    get(ld, "status", "") == "reviewed-complete" ||
        return (false, "status != reviewed-complete")
    jobs = get(ld, "jobs", nothing)
    jobs isa AbstractDict || return (false, "missing jobs section")
    for band in ("lw", "sw")
        j = get(jobs, band, nothing)
        j isa AbstractDict || return (false, "missing jobs.$band")
        jid = get(j, "job_id", nothing)
        jid_ok = (jid isa Integer && jid > 0) ||
            (jid isa AbstractString && occursin(r"^[0-9]+$", jid) &&
             tryparse(Int, jid) !== nothing && tryparse(Int, jid) > 0)
        jid_ok || return (false, "jobs.$band.job_id not a positive numeric id")
        get(j, "exit_code", -1) == 0 || return (false, "jobs.$band.exit_code != 0")
        for f in ("sbatch_sha256", "log_sha256", "output_sha256")
            hex64(get(j, f, "")) || return (false, "jobs.$band.$f not 64-hex")
        end
    end
    return (true, "ok")
end

function structural_compatible(ref_path, cand_path)
    NCDataset(ref_path) do ref
        NCDataset(cand_path) do cand
            for d in ("g_point", "band", "pressure", "temperature")
                (haskey(ref.dim, d) && haskey(cand.dim, d)) || return false
                ref.dim[d] == cand.dim[d] || return false
            end
            # Option-B structural fields must be ELEMENTWISE equal, not
            # merely present with matching dims
            for name in ("band_number", "wavenumber1_band", "wavenumber2_band",
                         "wavenumber1", "wavenumber2")
                (haskey(ref, name) && haskey(cand, name)) || return false
                a = Array(ref[name]); b = Array(cand[name])
                size(a) == size(b) || return false
                all(isequal.(a, b)) || return false
            end
            for name in keys(ref)
                endswith(String(name), "_molar_absorption_coeff") || continue
                haskey(cand, String(name)) || return false
                size(ref[String(name)]) == size(cand[String(name)]) || return false
            end
            return true
        end
    end
end
# ---------------------------------------------------------------------------

# fail-closed structural gate: unreadable/malformed candidate files are a
# mismatch, never an uncaught exception
g1or_structural_ok(ref_path, cand_path) =
    try structural_compatible(ref_path, cand_path) catch; false end

# pure refusal ladder (fixture-testable without real recovered outputs);
# returns (status, detail) where status == "ready" authorizes evaluation
function g1or_gate(lw_path, sw_path, ledger_path)
    (isfile(lw_path) && isfile(sw_path)) ||
        return ("g1_waiting_for_optimizer_outputs",
                "recovered pair absent (expected at the G3 executor " *
                "output conventions); refusing to evaluate")
    isfile(ledger_path) ||
        return ("g1_blocked_missing_run_ledger",
                "recovered files exist but no reviewed run ledger pins " *
                "their provenance")
    # unparseable ledger JSON must produce a refusal artifact, not an
    # uncaught exception (monitor gap)
    ledger = try
        JSON.parsefile(ledger_path)
    catch err
        return ("g1_blocked_invalid_run_ledger",
                "ledger unparseable: $(sprint(showerror, err))")
    end
    ledger isa AbstractDict ||
        return ("g1_blocked_invalid_run_ledger", "ledger is not an object")
    lok, lreason = validate_run_ledger(ledger)
    lok || return ("g1_blocked_invalid_run_ledger", lreason)
    for (band, path) in (("lw", lw_path), ("sw", sw_path))
        expect = ledger["jobs"][band]["output_sha256"]
        g1or_filesha(path) == expect ||
            return ("g1_blocked_ledger_hash_mismatch",
                    "$band output sha != ledger output_sha256")
    end
    return ("ready", "ok")
end

# joint pair evaluation through the canonical published-accuracy path
function g1or_evaluate_pair(lw_path, sw_path)
    model = read_ecckd_tabulated_gas_optics(
        lw_path, sw_path;
        gas_names = OFFICIAL_ECCKD_GASES,
        h2o_mole_fraction = env_float("RH_ECCKD_H2O_MOLE_FRACTION", 0.005))
    cases = [case_metrics(case, model) for case in REDUCED_CASES]
    objective = hard_objective(cases)
    return (model = model, cases = cases, objective = objective,
            boundary = boundary_compatibility(model, REDUCED_CASES))
end

g1or_boundary_flags(b) = Dict(
    "lw_spectral" => b.all_longwave_spectral_boundaries_match,
    "sw_surface_albedo" => b.all_shortwave_surface_albedo_boundaries_match,
    "sw_direct_albedo" => b.all_shortwave_direct_albedo_boundaries_match,
    "sw_incoming_spectral" => b.all_shortwave_incoming_spectral_boundaries_match,
    "sw_spectral" => b.all_shortwave_spectral_boundaries_match)

function g1or_write(result, md_lines)
    mkpath(dirname(G1OR_RESULTS_JSON))
    open(G1OR_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(G1OR_RESULTS_MD, "w") do io
        foreach(l -> println(io, l), md_lines)
    end
end

function g1or_main()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    fails = String[]
    gates = Dict{String, String}()

    # --- SELF-TEST CONTEXT: published pair through the identical path.
    # NEVER recovered acceptance -- labeled context in every artifact.
    lw32 = official_ecckd_definition_path(:longwave_32)
    sw32 = official_ecckd_definition_path(:shortwave_32)
    published = g1or_evaluate_pair(lw32, sw32)
    pub_value = published.objective.value
    baseline_rel = abs(pub_value - G1OR_PUBLISHED_BASELINE) /
                   G1OR_PUBLISHED_BASELINE
    gates["published_context_matches_archived_baseline"] =
        baseline_rel <= G1OR_BASELINE_REL_TOL ? "passed" : "failed"
    baseline_rel <= G1OR_BASELINE_REL_TOL ||
        push!(fails, "published-pair hard objective $pub_value != archived " *
                     "baseline $(G1OR_PUBLISHED_BASELINE) (rel $baseline_rel)")

    # perturbation self-test: scaling the published LW absorption in-memory
    # must STRICTLY raise the objective through the same path
    perturbed = read_ecckd_tabulated_gas_optics(
        lw32, sw32;
        gas_names = OFFICIAL_ECCKD_GASES,
        h2o_mole_fraction = env_float("RH_ECCKD_H2O_MOLE_FRACTION", 0.005))
    perturbed.longwave_absorption .*= 1.5
    pert_cases = [case_metrics(case, perturbed) for case in REDUCED_CASES]
    pert_value = hard_objective(pert_cases).value
    gates["perturbed_candidate_raises_objective"] =
        pert_value > pub_value ? "passed" : "failed"
    pert_value > pub_value ||
        push!(fails, "perturbed objective $pert_value !> published $pub_value")

    # run-ledger schema fixtures (subset of the acceptance unit's set)
    good = Dict("case" => "gate4_g3_run_ledger",
                "status" => "reviewed-complete",
                "jobs" => Dict(b => Dict("job_id" => 4999, "exit_code" => 0,
                    "sbatch_sha256" => "0"^64, "log_sha256" => "0"^64,
                    "output_sha256" => "0"^64) for b in ("lw", "sw")))
    t_ok = validate_run_ledger(good)[1]
    bad_status = merge(good, Dict("status" => "draft"))
    bad_jid = deepcopy(good); bad_jid["jobs"]["lw"]["job_id"] = "0"
    bad_hex = deepcopy(good); bad_hex["jobs"]["sw"]["output_sha256"] = "xyz"
    ledger_fixture_ok = t_ok && !validate_run_ledger(bad_status)[1] &&
                        !validate_run_ledger(bad_jid)[1] &&
                        !validate_run_ledger(bad_hex)[1]
    gates["run_ledger_schema_fixtures"] =
        ledger_fixture_ok ? "passed" : "failed"
    ledger_fixture_ok || push!(fails, "run-ledger schema fixtures failed")

    # refusal-ladder fixtures (tmp files; proves every rung without real
    # recovered outputs)
    fdir = mktempdir()
    f_lw = joinpath(fdir, "lw.nc"); f_sw = joinpath(fdir, "sw.nc")
    f_ledger = joinpath(fdir, "ledger.json")
    ladder = String[]
    push!(ladder, g1or_gate(f_lw, f_sw, f_ledger)[1])          # absent files
    write(f_lw, "x"); write(f_sw, "y")
    push!(ladder, g1or_gate(f_lw, f_sw, f_ledger)[1])          # no ledger
    write(f_ledger, "{ this is not json")
    push!(ladder, g1or_gate(f_lw, f_sw, f_ledger)[1])          # unparseable
    write(f_ledger, JSON.json(bad_status))
    push!(ladder, g1or_gate(f_lw, f_sw, f_ledger)[1])          # invalid
    write(f_ledger, JSON.json(good))
    push!(ladder, g1or_gate(f_lw, f_sw, f_ledger)[1])          # sha mismatch
    good_sha = deepcopy(good)
    good_sha["jobs"]["lw"]["output_sha256"] = g1or_filesha(f_lw)
    good_sha["jobs"]["sw"]["output_sha256"] = g1or_filesha(f_sw)
    write(f_ledger, JSON.json(good_sha))
    push!(ladder, g1or_gate(f_lw, f_sw, f_ledger)[1])          # ready
    ladder_expected = ["g1_waiting_for_optimizer_outputs",
                       "g1_blocked_missing_run_ledger",
                       "g1_blocked_invalid_run_ledger",
                       "g1_blocked_invalid_run_ledger",
                       "g1_blocked_ledger_hash_mismatch", "ready"]
    gates["refusal_ladder_fixtures"] =
        ladder == ladder_expected ? "passed" : "failed"
    ladder == ladder_expected ||
        push!(fails, "refusal ladder $ladder != $ladder_expected")

    # structural gate fixtures: self-compatible published file, swapped
    # bands (the malformed/swapped-hash-approved-file scenario), and an
    # unreadable candidate (fail-closed, no uncaught exception)
    structural_ok = g1or_structural_ok(lw32, lw32) &&
                    !g1or_structural_ok(lw32, sw32) &&
                    !g1or_structural_ok(lw32, f_lw)
    gates["structural_gate_fixtures"] = structural_ok ? "passed" : "failed"
    structural_ok || push!(fails, "structural gate fixtures failed " *
        "(self=$(g1or_structural_ok(lw32, lw32)) " *
        "swapped=$(g1or_structural_ok(lw32, sw32)) " *
        "unreadable=$(g1or_structural_ok(lw32, f_lw)))")
    rm(fdir, recursive = true, force = true)

    # materialize_reference_payloads fixture (monitor): the live run sees
    # already-materialized .nc files and never exercises artifact branch 3,
    # so the tracked-README protection is proven here on temp dirs: nested
    # payload .nc copied writable, stale artifact README NEVER copied over
    # the tracked sentinel
    adir = mktempdir(); rdir = mktempdir()
    mkpath(joinpath(adir, "ecrad"))
    write(joinpath(adir, "ecrad", "payload.nc"), "NCPAYLOAD")
    write(joinpath(adir, "ecrad", "README.md"), "STALE ARTIFACT README")
    mkpath(joinpath(rdir, "ecrad"))
    write(joinpath(rdir, "ecrad", "README.md"), "TRACKED SENTINEL")
    materialize_reference_payloads(adir, rdir)
    m_dest = joinpath(rdir, "ecrad", "payload.nc")
    mat_ok = isfile(m_dest) && read(m_dest, String) == "NCPAYLOAD" &&
             (stat(m_dest).mode & 0o200) != 0 &&
             read(joinpath(rdir, "ecrad", "README.md"), String) ==
                 "TRACKED SENTINEL" &&
             sort(readdir(joinpath(rdir, "ecrad"))) ==
                 ["README.md", "payload.nc"]
    gates["materialize_payloads_fixture"] = mat_ok ? "passed" : "failed"
    mat_ok || push!(fails, "materialize_reference_payloads fixture failed: " *
        ".nc must copy writable while the tracked README stays byte-unchanged")
    rm(adir, recursive = true, force = true)
    rm(rdir, recursive = true, force = true)

    selftests_ok = isempty(fails)

    # --- LIVE gate on the real recovered-output conventions ----------------
    live_status, live_detail = g1or_gate(G1OR_LW_RECOVERED, G1OR_SW_RECOVERED,
                                         G1OR_RUN_LEDGER)
    recovered_section = Dict{String, Any}(
        "status" => live_status, "detail" => live_detail)
    status = live_status
    if live_status == "ready"
        # structural gate BEFORE any package evaluation (mirrors the
        # acceptance unit): hash-approved but malformed/swapped files must
        # never reach case_metrics
        structural_bad = [band for (band, pub, rec) in
                          (("lw", lw32, G1OR_LW_RECOVERED),
                           ("sw", sw32, G1OR_SW_RECOVERED))
                          if !g1or_structural_ok(pub, rec)]
        if !isempty(structural_bad)
            status = "g1_blocked_structural_mismatch"
            recovered_section["structural_mismatch_bands"] = structural_bad
            recovered_section["detail"] =
                "structural_compatible failed for $(join(structural_bad, ", ")); " *
                "package evaluation deliberately NOT run"
        else
            recovered = g1or_evaluate_pair(G1OR_LW_RECOVERED, G1OR_SW_RECOVERED)
            rec_flags = g1or_boundary_flags(recovered.boundary)
            pub_flags = g1or_boundary_flags(published.boundary)
            if rec_flags != pub_flags
                status = "g1_blocked_boundary_compatibility_drift"
                recovered_section["boundary_recovered"] = rec_flags
                recovered_section["boundary_published"] = pub_flags
                recovered_section["detail"] =
                    "recovered boundary-compatibility flag pattern differs " *
                    "from the published pair through the same references"
            else
                ratio = recovered.objective.value / G1OR_HARD_TARGET
                recovered_section["hard_objective"] =
                    Dict(pairs(recovered.objective))
                recovered_section["ratio"] = ratio
                recovered_section["ratio_max"] = G1OR_RATIO_MAX
                recovered_section["lw_sha256"] = g1or_filesha(G1OR_LW_RECOVERED)
                recovered_section["sw_sha256"] = g1or_filesha(G1OR_SW_RECOVERED)
                status = ratio <= G1OR_RATIO_MAX ? "g1_objective_ratio_passed" :
                                                   "g1_objective_ratio_failed"
            end
        end
        recovered_section["status"] = status
    end
    selftests_ok || (status = "g1_selftests_failed")

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_g1_objective_ratio",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates,
        "failures" => fails,
        "binding_definition" => "package-native hard_objective (worst " *
            "threshold-normalized (case, metric) row over REDUCED_CASES) " *
            "on the recovered LW32+SW32 pair evaluated jointly; " *
            "ratio = value / $(G1OR_HARD_TARGET) <= $(G1OR_RATIO_MAX)",
        "published_context" => Dict(
            "NOTE" => "SELF-TEST CONTEXT ONLY -- this is the PUBLISHED " *
                "pair through the same path; it is NOT recovered " *
                "acceptance and must never be reported as such",
            "hard_objective_value" => pub_value,
            "hard_objective_metric" => published.objective.metric,
            "hard_objective_case" => published.objective.case,
            "archived_baseline" => G1OR_PUBLISHED_BASELINE,
            "baseline_rel_diff" => baseline_rel,
            "perturbed_value" => pert_value,
            "boundary_flags" => g1or_boundary_flags(published.boundary)),
        "recovered" => recovered_section,
        "reduced_cases" => [case.case for case in REDUCED_CASES],
        "recovered_conventions" => Dict(
            "lw" => G1OR_LW_RECOVERED, "sw" => G1OR_SW_RECOVERED,
            "run_ledger" => G1OR_RUN_LEDGER),
        "provenance" => Dict("branch" => branch,
            "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working " *
                "tree before its own commit",
            "lw32" => basename(lw32), "sw32" => basename(sw32)),
        "disclaimer" => "refusing Gate-1 runner: binds ONLY on a reviewed " *
            "run ledger + sha-matched recovered pair; published-pair " *
            "numbers are self-test context, not recovered acceptance; " *
            "the upstream objective/floor comparison is a separate " *
            "outstanding item.",
    )
    md = ["# Gate-4 Gate-1 objective-ratio runner", "",
          "Status: **$status**", "",
          result["disclaimer"], "",
          "| Gate | Verdict |", "|---|---|"]
    for k in sort(collect(keys(gates)))
        push!(md, "| $k | $(gates[k]) |")
    end
    push!(md, "",
          "Published-pair CONTEXT (not recovered acceptance): " *
          "hard objective $(pub_value) " *
          "($(published.objective.metric) on $(published.objective.case)); " *
          "archived baseline $(G1OR_PUBLISHED_BASELINE), rel diff " *
          "$(baseline_rel); perturbed $(pert_value).", "",
          "Live recovered-pair gate: **$(recovered_section["status"])** " *
          "($(recovered_section["detail"]))")
    isempty(fails) || begin
        push!(md, "", "## Failures", "")
        foreach(f -> push!(md, "- $f"), fails)
    end
    g1or_write(result, md)
    println("gate4_g1_objective_ratio: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    println("  live: $(recovered_section["status"])")
    isempty(fails) || foreach(f -> println("  FAIL: $f"), first(fails, 8))
    acceptable = ("g1_waiting_for_optimizer_outputs",
                  "g1_blocked_missing_run_ledger", "g1_objective_ratio_passed")
    return (selftests_ok && status in acceptable) ? 0 : 1
end

exit(g1or_main())
