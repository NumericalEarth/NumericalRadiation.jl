# Gate-4 G3 ACCEPTANCE COMPARISON (refuses until G3 outputs exist AND a
# reviewed run ledger pins their hashes; read-only; NEVER computes
# objective/floor itself).
#
# METRIC DEFINITIONS (monitor-reviewed):
#   - weight relative L1 (BINDING, <= 0.02): weights from the existing
#     gpoint_weights helper (LW: normalized planck_function sums; SW:
#     normalized solar_irradiance); rel L1 = sum(abs(cand-ref))/sum(abs(ref))
#     with shape/finite/nonnegative fail-closed checks.
#   - coefficient log-RMSE (DIAGNOSTIC, NON-BINDING, reported vs 0.02):
#     worst *_molar_absorption_coeff log-RMSE from recovery_metrics. This
#     is NOT the campaign's "OD log-RMSE": true OD remains an explicit
#     UNEVALUATED gate HERE. The SW parity precondition is satisfied
#     (gate4_sw_od_parity.jl 13/13) and the aggregation-independent
#     matched-state OD evaluator is implemented
#     (gate4_g2_matched_state_od_evaluator.jl 28/28), but the BINDING
#     Gate-2 runner (dataset choice, aggregation, log-RMSE) remains
#     unresolved/unimplemented pending recorded rulings.
#   - final/target objective ratio (<= 1.05): UNEVALUATED gate HERE --
#     deliberately NOT consumed by this unit, and no claim is made about
#     its state. The authoritative verdict is the SEPARATE Gate-1
#     artifact (validation/results/gate4_g1_objective_ratio.json), named
#     under objective_authority in this unit's JSON; consult that
#     artifact for the current verdict (monitor correction 2026-08-13:
#     this unit must never describe the G1 result, e.g. as "pending
#     outputs/ledger"; authority is the separate artifact alone).
# Because two acceptance gates are unevaluated in this unit, the overall
# status after a metric run is ALWAYS
# g3_acceptance_incomplete_pending_objective_and_od -- never a pass.
#
# PROVENANCE (concrete, not prose): metrics run ONLY when
# validation/results/gate4_g3_run_ledger.json exists (written at post-G3
# log/hash review) and its recovered-file sha256s match the files on disk.
#
# SELF-TESTS run on EVERY invocation (fail-closed): band self-comparisons
# (all metrics exactly 0), controlled perturbations that must fail each
# implemented metric, cross-band shape mismatch must throw, and the
# waiting-path JSON must parse back.

include(joinpath(@__DIR__, "validation_results.jl"))
include(joinpath(@__DIR__, "ecckd_recovery_metrics.jl"))
import JSON

const G4 = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const LW_RECOVERED = "$G4/work/lw_ckd-definition/ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc"
const SW_RECOVERED = "$G4/work-v14/sw_ckd-definition/ecckd-1.4_sw_ckd-definition_climate_rgb-tol0.047.nc"
const WEIGHT_REL_L1_ACCEPT = 0.02
const COEFF_LOG_RMSE_DIAG = 0.02
const RUN_LEDGER = validation_results_path("gate4_g3_run_ledger.json")

const AC_RESULTS_JSON = validation_results_path("gate4_g3_acceptance_comparison.json")
const AC_RESULTS_MD = validation_results_path("gate4_g3_acceptance_comparison.md")

filesha(p) = split(strip(read(`sha256sum $p`, String)))[1]

function weight_rel_l1(ref_path, cand_path, kind)
    NCDataset(ref_path) do ref
        NCDataset(cand_path) do cand
            wr = gpoint_weights(ref, kind)
            wc = gpoint_weights(cand, kind)
            size(wr) == size(wc) ||
                throw(ArgumentError("weight shapes differ: $(size(wr)) vs $(size(wc))"))
            all(isfinite, wr) && all(isfinite, wc) ||
                throw(ArgumentError("non-finite weights"))
            all(>=(0), wr) && all(>=(0), wc) ||
                throw(ArgumentError("negative weights"))
            sum(abs, wr) > 0 || throw(ArgumentError("zero reference weight norm"))
            return sum(abs, wc .- wr) / sum(abs, wr)
        end
    end
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

# strict run-ledger schema: a JSON with only recovered hashes must NOT
# authorize metrics
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

# guarded ledger LOADER (fixture-run on tmp files): an unreadable or
# unparseable present ledger and a parsed NON-OBJECT (JSON null parses
# successfully to nothing -- a non-object, NOT a parse failure; arrays
# and scalars likewise) are DISTINGUISHED, and both classify as invalid
# with a stable reason instead of an uncaught exception. Only a valid
# object reaches validate_run_ledger.
function classify_run_ledger(path)
    parse_failed = false
    ledger = try
        JSON.parsefile(path)
    catch
        parse_failed = true
        nothing
    end
    parse_failed && return (nothing, false,
        "run ledger unparseable (parse failure)")
    ledger isa AbstractDict ||
        return (nothing, false,
            "run ledger parses to a non-object (JSON null/array/scalar)")
    lok, lreason = validate_run_ledger(ledger)
    return (lok ? ledger : nothing, lok, lreason)
end

# pure verdict helpers (fixture-testable)
function band_verdict(pub, cand, kind)
    m = recovery_metrics(pub, cand)
    wl1 = weight_rel_l1(pub, cand, kind)
    Dict("weight_rel_l1" => wl1,
         "weight_rel_l1_pass_binding" => wl1 <= WEIGHT_REL_L1_ACCEPT,
         "coeff_log_rmse_worst" => m.worst_log_coefficient_rmse,
         "coeff_log_rmse_diagnostic_below_0p02_nonbinding" =>
             m.worst_log_coefficient_rmse <= COEFF_LOG_RMSE_DIAG,
         "recovery_metrics_full" => m)
end
status_render_md(status) = "Status: **" * status * "**"
status_render_console(status) = "gate4_g3_acceptance_comparison: " * status
acceptance_status(verdicts) =
    all(v["weight_rel_l1_pass_binding"] for v in values(verdicts)) ?
        "g3_acceptance_incomplete_pending_objective_and_od" :
        "g3_acceptance_failed_weight_l1"

function perturb_copy(src, dest, varname, factor_fn)
    cp(src, dest; force=true)
    chmod(dest, 0o644)   # artifact sources are read-only; cp preserves mode
    NCDataset(dest, "a") do ds
        arr = Float64.(Array(ds[varname]))
        ds[varname][ntuple(_ -> :, ndims(arr))...] = factor_fn(arr)
    end
    dest
end

function selftests(lw32, sw32)
    t = Dict{String, Bool}()
    # exact-zero self-comparisons, both bands, both metrics
    for (band, pub, kind) in (("lw", lw32, "longwave"), ("sw", sw32, "shortwave"))
        m = recovery_metrics(pub, pub)
        t["$(band)_self_coeff_zero"] = m.worst_log_coefficient_rmse == 0.0
        t["$(band)_self_weight_zero"] = weight_rel_l1(pub, pub, kind) == 0.0
    end
    tmp = mktempdir()
    # perturbation must fail the coefficient diagnostic (exp(0.05) shift)
    plw = perturb_copy(lw32, joinpath(tmp, "lw_coeff.nc"),
                       "h2o_molar_absorption_coeff", a -> a .* exp(0.05))
    t["lw_perturb_fails_coeff_diag"] =
        recovery_metrics(lw32, plw).worst_log_coefficient_rmse > COEFF_LOG_RMSE_DIAG
    # perturbations must fail the binding weight metric (nonuniform tilt)
    plw2 = perturb_copy(lw32, joinpath(tmp, "lw_weight.nc"), "planck_function",
                        a -> a .* (1.0 .+ 0.5 .* (0:size(a, 1)-1) ./ size(a, 1)))
    t["lw_perturb_fails_weight_l1"] =
        weight_rel_l1(lw32, plw2, "longwave") > WEIGHT_REL_L1_ACCEPT
    psw = perturb_copy(sw32, joinpath(tmp, "sw_weight.nc"), "solar_irradiance",
                       a -> a .* (1.0 .+ 0.5 .* (0:size(a, 1)-1) ./ size(a, 1)))
    t["sw_perturb_fails_weight_l1"] =
        weight_rel_l1(sw32, psw, "shortwave") > WEIGHT_REL_L1_ACCEPT
    # genuine shape mismatch must throw in the metrics layer: synthetic
    # 16-g-point candidate vs the 32-g published reference
    syn = joinpath(tmp, "synthetic_wrong_shape.nc")
    NCDataset(syn, "c") do ds
        defDim(ds, "g_point", 16); defDim(ds, "pressure", 53)
        defDim(ds, "temperature", 6); defDim(ds, "h2o_mole_fraction", 12)
        defDim(ds, "wavenumber", 10)
        v = defVar(ds, "h2o_molar_absorption_coeff", Float32,
                   ("g_point", "pressure", "temperature", "h2o_mole_fraction"))
        v[:, :, :, :] = zeros(Float32, 16, 53, 6, 12)
        g = defVar(ds, "gpoint_fraction", Float32, ("wavenumber", "g_point"))
        g[:, :] = ones(Float32, 10, 16)
    end
    t["shape_mismatch_metrics_throw"] = try
        recovery_metrics(lw32, syn); false
    catch; true end
    # cross-band comparability is (correctly) caught by the STRUCTURAL
    # gate, not the metrics layer: shared gas coefficient tables have
    # identical dims across bands, so metrics alone cannot distinguish
    # them -- structural_compatible must be false cross-band
    t["cross_band_structural_false"] = !structural_compatible(lw32, sw32)
    # same-shape structural VALUE drift must fail the structural gate
    pdrift = perturb_copy(lw32, joinpath(tmp, "lw_drift.nc"),
                          "wavenumber1_band", a -> a .* 1.01)
    t["structural_value_drift_false"] = !structural_compatible(lw32, pdrift)
    # negative and nonfinite weights must throw (fail-closed)
    pneg = perturb_copy(lw32, joinpath(tmp, "lw_neg.nc"),
                        "planck_function", a -> a .* -1.0)
    t["negative_weight_throws"] = try
        weight_rel_l1(lw32, pneg, "longwave"); false
    catch; true end
    pnan = perturb_copy(lw32, joinpath(tmp, "lw_nan.nc"),
                        "planck_function", a -> (a[1] = NaN; a))
    t["nonfinite_weight_throws"] = try
        weight_rel_l1(lw32, pnan, "longwave"); false
    catch; true end
    # run-ledger schema: minimal hash-only JSON must NOT authorize
    t["minimal_ledger_rejected"] =
        !validate_run_ledger(Dict("recovered_sha256" => Dict("lw" => "0"^64)))[1]
    good = Dict("case" => "gate4_g3_run_ledger", "status" => "reviewed-complete",
        "jobs" => Dict(b => Dict("job_id" => 4999, "exit_code" => 0,
            "sbatch_sha256" => "0"^64, "log_sha256" => "0"^64,
            "output_sha256" => "0"^64) for b in ("lw", "sw")))
    t["complete_ledger_accepted"] = validate_run_ledger(good)[1]
    # guarded LOADER classification through the SAME function main uses:
    # malformed JSON, JSON null, and an array all refuse with stable
    # reasons (parse failure never conflated with parsed-non-object);
    # a valid object flows through validate_run_ledger
    mal = joinpath(tmp, "ledger_malformed.json"); write(mal, "{")
    _, mok, mreason = classify_run_ledger(mal)
    t["unparseable_ledger_classified_invalid"] =
        !mok && mreason == "run ledger unparseable (parse failure)"
    nul = joinpath(tmp, "ledger_null.json"); write(nul, "null")
    _, nok, nreason = classify_run_ledger(nul)
    t["null_ledger_classified_non_object"] =
        !nok && nreason ==
            "run ledger parses to a non-object (JSON null/array/scalar)"
    arr = joinpath(tmp, "ledger_array.json"); write(arr, "[1]")
    _, aok, areason = classify_run_ledger(arr)
    t["array_ledger_classified_non_object"] =
        !aok && occursin("non-object", areason)
    gl = joinpath(tmp, "ledger_good.json")
    open(gl, "w") do io; JSON.print(io, good) end
    gld, gok, greason = classify_run_ledger(gl)
    t["valid_object_ledger_loads"] =
        gok && greason == "ok" && gld isa AbstractDict
    # verdict selection through the SAME helpers main uses: a controlled
    # weight-perturbed candidate must select the explicit failed status;
    # all-pass selects incomplete-pending
    v_fail = band_verdict(lw32, plw2, "longwave")
    v_pass = band_verdict(sw32, sw32, "shortwave")
    t["weight_failure_selects_failed_status"] =
        !v_fail["weight_rel_l1_pass_binding"] &&
        acceptance_status(Dict("lw" => v_fail, "sw" => v_pass)) ==
            "g3_acceptance_failed_weight_l1"
    for st in ("g3_acceptance_failed_weight_l1",
               "g3_acceptance_incomplete_pending_objective_and_od")
        t["render_md_interpolates_" * st] =
            status_render_md(st) == "Status: **" * st * "**" &&
            !occursin("\\", status_render_md(st))
        t["render_console_interpolates_" * st] =
            endswith(status_render_console(st), st)
    end
    badjid = Dict("case" => "gate4_g3_run_ledger", "status" => "reviewed-complete",
        "jobs" => Dict(b => Dict("job_id" => "0", "exit_code" => 0,
            "sbatch_sha256" => "0"^64, "log_sha256" => "0"^64,
            "output_sha256" => "0"^64) for b in ("lw", "sw")))
    t["zero_string_job_id_rejected"] = !validate_run_ledger(badjid)[1]
    t["all_pass_selects_incomplete_pending"] =
        acceptance_status(Dict("lw" => v_pass, "sw" => v_pass)) ==
            "g3_acceptance_incomplete_pending_objective_and_od"
    return t
end

function write_results(result, md_lines)
    mkpath(dirname(AC_RESULTS_JSON))
    open(AC_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(AC_RESULTS_MD, "w") do io
        foreach(l -> println(io, l), md_lines)
    end
    # parse-back: the artifact we just wrote must be valid JSON
    JSON.parsefile(AC_RESULTS_JSON)
end

function acceptance_main()
    lw32 = NumericalRadiation.official_ecckd_definition_path(:longwave_32)
    sw32 = NumericalRadiation.official_ecckd_definition_path(:shortwave_32)

    tests = selftests(lw32, sw32)
    selftests_ok = all(values(tests))

    missing_out = [p for p in (LW_RECOVERED, SW_RECOVERED) if !isfile(p)]
    base = Dict(
        "case" => "gate4_g3_acceptance_comparison",
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "selftests" => tests,
        "objective_authority" => Dict(
            "unit" => "gate4_g1_objective_ratio.jl",
            "artifact" => "validation/results/gate4_g1_objective_ratio.json",
            "note" => "authoritative separate artifact for the " *
                "objective-ratio gate; deliberately not consumed here; " *
                "consult it for the current verdict"),
        "unevaluated_acceptance_gates" => [
            "final/target objective ratio <= 1.05: deliberately NOT " *
            "consumed by this unit; the authoritative verdict is the " *
            "separate G1 artifact named under objective_authority",
            "true OD log-RMSE <= 0.02: SW parity satisfied + " *
            "aggregation-independent matched-state evaluator IMPLEMENTED " *
            "(gate4_g2_matched_state_od_evaluator.jl); BINDING runner " *
            "unimplemented pending dataset/aggregation rulings; " *
            "coefficient log-RMSE is only a diagnostic"],
        "binding_metric" => "weight relative L1 <= $WEIGHT_REL_L1_ACCEPT " *
            "(gpoint_weights: LW planck-derived, SW solar-derived)",
        "malformed_cases_covered" => [
            "16g synthetic shape mismatch (metrics layer throws)",
            "cross-band structural false", "structural value drift false",
            "negative weights throw", "nonfinite (NaN) weights throw",
            "hash-only run ledger rejected",
            "unparseable ledger JSON classified blocked_invalid " *
                "(guarded loader; no uncaught exception)",
            "JSON null/array ledger classified non-object " *
                "blocked_invalid (parse success distinguished from " *
                "parse failure)"],
        "provenance_requirement" => "metrics run only with " *
            "gate4_g3_run_ledger.json present and hash-matching (written " *
            "at post-G3 log/hash review)")

    if !selftests_ok
        result = merge(base, Dict(
            "data_mode" => "selftest_failure",
            "status" => "g3_acceptance_selftest_failed"))
        write_results(result, ["# Gate-4 G3 acceptance comparison", "",
            "Status: **g3_acceptance_selftest_failed**", "",
            "Self-test failures: " *
            join([k for (k, v) in tests if !v], ", ")])
        println("gate4_g3_acceptance_comparison: g3_acceptance_selftest_failed")
        return 1
    end

    if !isempty(missing_out)
        result = merge(base, Dict(
            "data_mode" => "refusal_no_g3_outputs",
            "status" => "g3_acceptance_waiting_for_optimizer_outputs",
            "missing" => missing_out,
            "expected_outputs" => Dict("lw" => LW_RECOVERED, "sw" => SW_RECOVERED),
            "published_targets" => Dict("lw" => basename(lw32), "sw" => basename(sw32)),
            "disclaimer" => "refuses until both recovered ckd-definitions " *
                "exist; no objective, floor, or recovery computation."))
        write_results(result, ["# Gate-4 G3 acceptance comparison", "",
            "Status: **g3_acceptance_waiting_for_optimizer_outputs**", "",
            "Self-tests: all passed. Waiting on G3 optimizer outputs; " *
            "binding weight rel-L1 and the two unevaluated gates are " *
            "documented in the JSON."])
        println("gate4_g3_acceptance_comparison: g3_acceptance_waiting_for_optimizer_outputs")
        return 0
    end

    if !isfile(RUN_LEDGER)
        result = merge(base, Dict(
            "data_mode" => "refusal_no_run_ledger",
            "status" => "g3_acceptance_blocked_missing_run_ledger",
            "note" => "recovered files exist but no reviewed run ledger " *
                "pins their provenance; metrics deliberately NOT computed"))
        write_results(result, ["# Gate-4 G3 acceptance comparison", "",
            "Status: **g3_acceptance_blocked_missing_run_ledger**"])
        println("gate4_g3_acceptance_comparison: g3_acceptance_blocked_missing_run_ledger")
        return 0
    end
    # guarded loader: unreadable/unparseable and parsed-non-object both
    # classify as blocked_invalid with a stable reason (never an
    # uncaught exception); consulted ONLY after outputs exist -- the
    # waiting path above never touches the ledger
    ledger, lok, lreason = classify_run_ledger(RUN_LEDGER)
    if !lok
        result = merge(base, Dict(
            "data_mode" => "refusal_invalid_run_ledger",
            "status" => "g3_acceptance_blocked_invalid_run_ledger",
            "reason" => lreason))
        write_results(result, ["# Gate-4 G3 acceptance comparison", "",
            "Status: **g3_acceptance_blocked_invalid_run_ledger** ($lreason)"])
        println("gate4_g3_acceptance_comparison: g3_acceptance_blocked_invalid_run_ledger")
        return 1
    end
    for (band, path) in (("lw", LW_RECOVERED), ("sw", SW_RECOVERED))
        expect = ledger["jobs"][band]["output_sha256"]
        if filesha(path) != expect
            result = merge(base, Dict(
                "data_mode" => "refusal_ledger_hash_mismatch",
                "status" => "g3_acceptance_blocked_ledger_hash_mismatch",
                "band" => band))
            write_results(result, ["# Gate-4 G3 acceptance comparison", "",
                "Status: **g3_acceptance_blocked_ledger_hash_mismatch** ($band)"])
            println("gate4_g3_acceptance_comparison: g3_acceptance_blocked_ledger_hash_mismatch")
            return 1
        end
    end

    comparisons = Dict{String, Any}()
    for (band, rec, pub, kind) in (("lw", LW_RECOVERED, lw32, "longwave"),
                                   ("sw", SW_RECOVERED, sw32, "shortwave"))
        structural_compatible(pub, rec) || begin
            result = merge(base, Dict(
                "data_mode" => "structural_mismatch",
                "status" => "g3_acceptance_structural_mismatch", "band" => band))
            write_results(result, ["# Gate-4 G3 acceptance comparison", "",
                "Status: **g3_acceptance_structural_mismatch** ($band)"])
            println("gate4_g3_acceptance_comparison: g3_acceptance_structural_mismatch")
            return 1
        end
        comparisons[band] = merge(band_verdict(pub, rec, kind),
                                  Dict("recovered_sha256" => filesha(rec)))
    end
    status = acceptance_status(comparisons)
    result = merge(base, Dict(
        "data_mode" => "read_only_metric_comparison",
        "status" => status,
        "comparisons" => comparisons,
        "disclaimer" => status == "g3_acceptance_failed_weight_l1" ?
            "binding weight rel-L1 exceeded 0.02 in at least one band: " *
            "EXPLICIT acceptance failure; monitor review required." :
            "two acceptance gates unevaluated in this unit (objective " *
            "ratio: deliberately not consumed here -- the authoritative " *
            "separate G1 artifact carries the current verdict; true OD " *
            "log-RMSE: evaluator implemented, binding runner pending " *
            "rulings); this status is NEVER a pass; monitor review " *
            "required."))
    write_results(result, ["# Gate-4 G3 acceptance comparison", "",
        status_render_md(status), "",
        "See JSON for per-band binding weight rel-L1 and diagnostic " *
        "coefficient log-RMSE. The objective-ratio gate is deliberately " *
        "NOT consumed by this unit: the authoritative verdict lives in " *
        "the separate gate4_g1_objective_ratio.json -- consult it for " *
        "the current verdict. True OD (evaluator implemented; binding " *
        "runner pending rulings) remains an unevaluated gate in this " *
        "unit."])
    println(status_render_console(status))
    return status == "g3_acceptance_failed_weight_l1" ? 1 : 0
end

exit(acceptance_main())
