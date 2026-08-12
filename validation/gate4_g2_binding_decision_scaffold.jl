# Gate-4 GATE-2 BINDING-DECISION SCAFFOLD (decision map + neutral
# deterministic calculations; NO scientific rule is chosen here).
#
# Purpose (monitor-directed; interface ACKed with revisions, numerical-
# policy/hash blockers applied 2026-08-12): map the exact open decision
# points that block the binding Gate-2 runner and provide the neutral
# per-scenario total-OD statistics the runner will need. THREE independent
# binding choices remain open (dataset union; cross-scenario aggregation;
# nonpositive-pair policy) plus per-scenario active-gas lists; this unit
# computes BOTH defensible nonnegative policies and BOTH aggregation
# candidates side by side and never emits a binding pass/fail or election.
#
# Neutrality rules (monitor):
#   - identical reference/candidate active-gas lists ENFORCED (single-list
#     API) for campaign-comparable metrics;
#   - NEGATIVE total OD in either definition is a finding/refusal, never
#     excluded or clamped (shared precondition of BOTH policies);
#   - zero counts (both-zero / reference-only / candidate-only), selected
#     and excluded pair counts, and per-scenario SSE/count/RMSE are always
#     preserved;
#   - pooled RMSE is sqrt(sum SSE / sum selected count); the unweighted
#     mean of scenario RMSEs stays OUTSIDE the candidates as an explicit
#     non-candidate demonstrator;
#   - per-policy outcomes: pair_selection is explicitly undefined/refused
#     on zero selected pairs while eps_clamping still reports its valid
#     result (e.g. zero over all-zero arrays); never NaN;
#   - fail-closed shape/axes and non-finite checks precede all metric work;
#   - metric artifacts join each scenario to its manifest label + sha256
#     with LIVE size+hash verification against the file on disk; pending
#     (eval2) entries can never become metric rows.
#
# Nonpositive-pair policy variants (both computed; NEITHER elected). BOTH
# use the UNMODIFIED positive_eps of ecckd_recovery_metrics.jl (reused by
# include, not copied) and log(x + eps) - log(y + eps):
#   pair_selection: pairs with BOTH totals > 0 selected; exact-zero pairs
#     excluded and counted; eps from positive_eps over the SELECTED
#     values (matching the prior helper pattern).
#   eps_clamping: ALL nonnegative pairs included (zeros in); eps from
#     positive_eps over all values.
# With no zero totals the two policies are IDENTICAL (same pairs, same
# eps) -- asserted numerically below; they CAN DIVERGE ONLY WHEN ZEROS
# ARE PRESENT, which is what the D3 ruling must decide.
#
# The binding Gate-2 runner remains UNIMPLEMENTED pending the rulings.

include(joinpath(@__DIR__, "gate4_g2_matched_state_od_evaluator.jl"))
include(joinpath(@__DIR__, "ecckd_recovery_metrics.jl"))   # positive_eps

const BDS_RESULTS_JSON =
    validation_results_path("gate4_g2_binding_decision_scaffold.json")
const BDS_RESULTS_MD =
    validation_results_path("gate4_g2_binding_decision_scaffold.md")
const BDS_MANIFEST_JSON =
    validation_results_path("gate4_gate2_od_dataset_manifest.json")

const BDS_CKDMIP = get(ENV, "RH_CKDMIP_DATA_PATH",
                       "/shared/home/greg/data/ckdmip")

# --- shared preconditions (fail-closed, ordered) ---------------------------
function bds_shared_checks(ref_total, cand_total)
    axes(ref_total) == axes(cand_total) ||
        refuse("total-OD axes differ: $(axes(ref_total)) vs " *
               "$(axes(cand_total))")
    isempty(ref_total) &&
        refuse("empty total-OD arrays: no pairs exist, metric undefined " *
               "(explicit refusal, never sqrt(0/0) = NaN)")
    all(isfinite, ref_total) && all(isfinite, cand_total) ||
        refuse("non-finite total OD encountered (finding; no metric is " *
               "computed)")
    neg_ref = count(<(0.0), ref_total)
    neg_cand = count(<(0.0), cand_total)
    (neg_ref == 0 && neg_cand == 0) ||
        refuse("negative total OD is a FINDING, never excluded or " *
               "clamped: reference $neg_ref, candidate $neg_cand " *
               "negative entries")
    return nothing
end

# --- policy-selectable metric core (pure arrays; synthetic-testable) -------
function total_od_policy_stats(ref_total::AbstractArray,
                               cand_total::AbstractArray, policy::Symbol)
    bds_shared_checks(ref_total, cand_total)
    n_total = length(ref_total)
    if policy == :pair_selection
        sel = (ref_total .> 0.0) .& (cand_total .> 0.0)
        n_sel = count(sel)
        n_sel > 0 ||
            refuse("zero selected pairs under pair_selection: the metric " *
                   "is undefined (explicit refusal, not NaN)")
        eps_floor = positive_eps(ref_total[sel], cand_total[sel])
        logd = log.(cand_total[sel] .+ eps_floor) .-
               log.(ref_total[sel] .+ eps_floor)
        sse = sum(abs2, logd)
        return (policy = "pair_selection", n_selected = n_sel,
                n_excluded_zero_pairs = n_total - n_sel,
                sse = sse, log_rmse = sqrt(sse / n_sel),
                epsilon_used = eps_floor)
    elseif policy == :eps_clamping
        eps_floor = positive_eps(ref_total, cand_total)
        logd = log.(cand_total .+ eps_floor) .-
               log.(ref_total .+ eps_floor)
        sse = sum(abs2, logd)
        return (policy = "eps_clamping", n_selected = n_total,
                n_excluded_zero_pairs = 0,
                sse = sse, log_rmse = sqrt(sse / n_total),
                epsilon_used = eps_floor)
    else
        refuse("unknown nonpositive-pair policy: $policy")
    end
end

# --- both-policy wrapper with per-policy outcomes --------------------------
# Shared preconditions refuse for both; a policy-specific undefined state
# (pair_selection on zero selected pairs) is CAPTURED per policy so the
# other policy's valid result is still reported (neutrality).
function total_od_pair_stats(ref_total::AbstractArray,
                             cand_total::AbstractArray)
    bds_shared_checks(ref_total, cand_total)
    zero_ref = ref_total .== 0.0
    zero_cand = cand_total .== 0.0
    function attempt(policy)
        try
            (defined = true, stats = total_od_policy_stats(ref_total,
                                                           cand_total, policy))
        catch err
            err isa MsoRefusal || rethrow()
            (defined = false, reason = err.reason)
        end
    end
    return (
        n_pairs_total = length(ref_total),
        zero_totals = (
            reference = count(zero_ref),
            candidate = count(zero_cand),
            both = count(zero_ref .& zero_cand),
            reference_only = count(zero_ref .& .!zero_cand),
            candidate_only = count(.!zero_ref .& zero_cand)),
        policies = (pair_selection = attempt(:pair_selection),
                    eps_clamping = attempt(:eps_clamping)),
    )
end

# --- path-level wrapper (identical active-gas lists by construction) -------
function per_scenario_total_od_stats(reference_def, candidate_def,
                                     scenario_path;
                                     active_absorption_gases)
    r = matched_state_od(reference_def, scenario_path;
                         active_absorption_gases = active_absorption_gases)
    c = matched_state_od(candidate_def, scenario_path;
                         active_absorption_gases = active_absorption_gases)
    stats = total_od_pair_stats(r.total_raw, c.total_raw)
    return merge(stats, (scenario = r.scenario,
                         scenario_path = scenario_path))
end

# --- manifest join (live, fail-closed) --------------------------------------
# A scenario may become a metric row ONLY if its manifest entry is present,
# schema_ok, carries a 64-hex sha, AND the file on disk currently matches
# the manifest's recorded size and hash. Pending entries (eval2) refuse.
function manifest_fingerprint(scenario_path)
    m = JSON.parsefile(BDS_MANIFEST_JSON)
    for e in m["inventory"]
        e["path"] == scenario_path || continue
        get(e, "present", false) == true ||
            refuse("manifest entry $(e["label"]) is PENDING/absent; it " *
                   "cannot become a metric row")
        get(e, "schema_ok", false) == true ||
            refuse("manifest entry $(e["label"]) is not schema_ok")
        sha = get(e, "sha256", "")
        occursin(r"^[0-9a-f]{64}$", sha) ||
            refuse("manifest entry $(e["label"]) sha256 malformed")
        isfile(scenario_path) ||
            refuse("manifest entry $(e["label"]) file missing on disk")
        filesize(scenario_path) == e["size_bytes"] ||
            refuse("manifest entry $(e["label"]) size drifted vs manifest")
        live = split(strip(read(`sha256sum $scenario_path`, String)))[1]
        live == sha ||
            refuse("manifest entry $(e["label"]) hash drifted vs manifest")
        return Dict("manifest_label" => e["label"],
                    "manifest_sha256" => sha,
                    "manifest_status" => m["status"])
    end
    refuse("scenario $scenario_path is not in the Gate-2 dataset " *
           "manifest inventory; campaign-comparable metrics are joined " *
           "to manifest labels/fingerprints")
end

# --- aggregation candidates (both; NO election) -----------------------------
function aggregation_candidates(per_scenario, policy::Symbol)
    policy in (:pair_selection, :eps_clamping) ||
        refuse("unknown nonpositive-pair policy: $policy")
    isempty(per_scenario) && refuse("no per-scenario results to aggregate")
    rows = map(per_scenario) do p
        o = getproperty(p.policies, policy)
        o.defined || refuse("policy $policy undefined for scenario " *
                            "$(p.scenario): $(o.reason)")
        (p.scenario, o.stats)
    end
    worst = maximum(r[2].log_rmse for r in rows)
    sum_sse = sum(r[2].sse for r in rows)
    sum_n = sum(r[2].n_selected for r in rows)
    sum_n > 0 || refuse("zero total selected pairs across scenarios")
    return (
        policy = String(policy),
        worst_case_candidate = worst,
        pooled_candidate = sqrt(sum_sse / sum_n),
        n_scenarios = length(per_scenario),
        sum_sse = sum_sse,
        sum_selected = sum_n,
        binding_election = "NONE -- both aggregations are candidates; " *
            "the binding choice requires a recorded ruling",
    )
end

# explicit NON-candidate demonstrator, kept outside the candidates tuple
unweighted_mean_rmse_demonstrator(per_scenario, policy::Symbol) =
    sum(getproperty(p.policies, policy).stats.log_rmse
        for p in per_scenario) / length(per_scenario)

# ============================================================================
# SELF-TESTS (guarded main; the library above is include-safe)
# ============================================================================

function bds_expect_refusal!(gates, fails, name, substring, thunk)
    outcome = try
        thunk()
        "no_refusal"
    catch err
        err isa MsoRefusal ?
            (occursin(substring, err.reason) ? "refused_as_expected" :
             "refused_wrong_reason: $(first(err.reason, 100))") :
            "wrong_exception: $(first(sprint(showerror, err), 100))"
    end
    gates[name] = outcome == "refused_as_expected" ? "passed" : "failed"
    outcome == "refused_as_expected" ||
        push!(fails, "$name: $outcome (wanted refusal containing " *
                     "'$substring')")
end

function bds_main()
    fails = String[]
    gates = Dict{String, String}()

    lw32 = NumericalRadiation.official_ecckd_definition_path(:longwave_32)
    sw32 = NumericalRadiation.official_ecckd_definition_path(:shortwave_32)
    sw_scen1 = joinpath(BDS_CKDMIP,
        "evaluation1/sw_fluxes-rgb/ckdmip_evaluation1_sw_fluxes-rgb_rel-415.h5")
    sw_scen2 = joinpath(BDS_CKDMIP,
        "evaluation1/sw_fluxes-rgb/ckdmip_evaluation1_sw_fluxes-rgb_present.h5")
    lw_scen1 = joinpath(BDS_CKDMIP,
        "evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-415.h5")
    # TEST gas lists (labeled; NOT a binding choice -- decision point D4)
    sw_gases_test = ["composite", "h2o", "o3", "co2", "ch4", "n2o"]
    lw_gases_test = ["composite", "h2o", "o3", "co2", "ch4", "n2o"]

    # --- self-zero on real scenarios, both policies defined and zero ------
    sz = per_scenario_total_od_stats(sw32, sw32, sw_scen1;
                                     active_absorption_gases = sw_gases_test)
    lz = per_scenario_total_od_stats(lw32, lw32, lw_scen1;
                                     active_absorption_gases = lw_gases_test)
    self_ok = all(o.defined && o.stats.log_rmse == 0.0
                  for o in (sz.policies.pair_selection,
                            sz.policies.eps_clamping,
                            lz.policies.pair_selection,
                            lz.policies.eps_clamping))
    gates["self_zero_both_policies_lw_sw"] = self_ok ? "passed" : "failed"
    self_ok || push!(fails, "self comparison nonzero/undefined under some " *
                            "policy")

    # --- with no zero totals the two policies are NUMERICALLY IDENTICAL:
    # same pairs, same positive_eps, equal SSE/RMSE/epsilon ------------------
    no_zeros = sz.zero_totals.reference == 0 && sz.zero_totals.candidate == 0
    a = sz.policies.pair_selection.stats
    b = sz.policies.eps_clamping.stats
    coincide_ok = no_zeros && a.n_selected == b.n_selected &&
                  a.sse == b.sse && a.log_rmse == b.log_rmse &&
                  a.epsilon_used == b.epsilon_used
    gates["policies_numerically_identical_without_zeros"] =
        coincide_ok ? "passed" : "failed"
    coincide_ok || push!(fails, "no-zero policy equality failed: " *
        "sse $(a.sse) vs $(b.sse), eps $(a.epsilon_used) vs " *
        "$(b.epsilon_used)")

    # --- one-sided zero: policies DIVERGE, with side-resolved counts ------
    st_div = total_od_pair_stats([1.0, 0.0, 2.0], [1.0, 1.0, 2.0])
    div_ok = st_div.zero_totals.reference_only == 1 &&
             st_div.zero_totals.candidate_only == 0 &&
             st_div.zero_totals.both == 0 &&
             st_div.policies.pair_selection.defined &&
             st_div.policies.eps_clamping.defined &&
             st_div.policies.pair_selection.stats.log_rmse == 0.0 &&
             st_div.policies.eps_clamping.stats.log_rmse > 0.0
    gates["one_sided_zero_divergence"] = div_ok ? "passed" : "failed"
    div_ok || push!(fails, "one-sided-zero divergence not as expected")

    # --- all-zero arrays: per-policy outcomes (neutrality) ----------------
    st_zero = total_od_pair_stats(zeros(4), zeros(4))
    allzero_ok = !st_zero.policies.pair_selection.defined &&
        occursin("zero selected pairs",
                 st_zero.policies.pair_selection.reason) &&
        st_zero.policies.eps_clamping.defined &&
        st_zero.policies.eps_clamping.stats.log_rmse == 0.0 &&
        st_zero.zero_totals.both == 4
    gates["all_zero_per_policy_outcomes"] = allzero_ok ? "passed" : "failed"
    allzero_ok || push!(fails, "all-zero arrays: pair_selection must be " *
        "captured-undefined while eps_clamping reports zero")

    # --- manifest join: fail-closed live size+hash verification -----------
    fps = [manifest_fingerprint(p) for p in (sw_scen1, sw_scen2, lw_scen1)]
    join_ok = all(occursin(r"^[0-9a-f]{64}$", f["manifest_sha256"])
                  for f in fps) &&
              fps[1]["manifest_label"] == "sw_rgb_rel-415" &&
              fps[3]["manifest_label"] == "lw_rel-415"
    gates["manifest_join_live_verified"] = join_ok ? "passed" : "failed"
    join_ok || push!(fails, "manifest label/fingerprint join failed")
    bds_expect_refusal!(gates, fails, "refuse_scenario_outside_manifest",
        "not in the Gate-2 dataset manifest",
        () -> manifest_fingerprint("/nonexistent/scenario.h5"))
    eval2_path = JSON.parsefile(BDS_MANIFEST_JSON)["inventory"][end]["path"]
    bds_expect_refusal!(gates, fails, "refuse_pending_eval2_as_metric_row",
        "PENDING/absent",
        () -> manifest_fingerprint(eval2_path))

    # --- SYNTHETIC same-quantity perturbation (pure core). The epsilon
    # floor makes the scaled-positive RMSE only ASYMPTOTICALLY
    # |log 1.001|, so no exact-value claim is made: assert positive
    # detection, zero exclusions, and exact policy equality (no zeros in
    # these totals, so the two policies must coincide numerically) ---------
    r = matched_state_od(sw32, sw_scen1;
                         active_absorption_gases = sw_gases_test)
    pert = total_od_pair_stats(r.total_raw, r.total_raw .* 1.001)
    pa = pert.policies.pair_selection
    pb = pert.policies.eps_clamping
    pert_ok = pa.defined && pb.defined &&
        pa.stats.log_rmse > 0.0 &&
        pa.stats.n_excluded_zero_pairs == 0 &&
        pa.stats.sse == pb.stats.sse &&
        pa.stats.log_rmse == pb.stats.log_rmse &&
        pa.stats.epsilon_used == pb.stats.epsilon_used
    gates["synthetic_perturbation_detected"] = pert_ok ? "passed" : "failed"
    pert_ok || push!(fails, "synthetic x1.001 perturbation: expected " *
        "positive detection with zero exclusions and exact policy " *
        "equality; got $(pa) vs $(pb)")

    # --- aggregation: pooled == sqrt(sum SSE / sum n); unweighted mean is
    # outside the candidates and differs on unequal counts (synthetic) ------
    per_syn = [
        (scenario = "syn_small", policies = (pair_selection =
            (defined = true, stats = (policy = "pair_selection",
             n_selected = 10, n_excluded_zero_pairs = 0,
             sse = 10 * 0.04, log_rmse = 0.2, epsilon_used = 0.0)),)),
        (scenario = "syn_large", policies = (pair_selection =
            (defined = true, stats = (policy = "pair_selection",
             n_selected = 1000, n_excluded_zero_pairs = 0,
             sse = 1000 * 0.0001, log_rmse = 0.01, epsilon_used = 0.0)),)),
    ]
    agg_syn = aggregation_candidates(per_syn, :pair_selection)
    expected_pooled = sqrt((10 * 0.04 + 1000 * 0.0001) / 1010)
    unweighted = unweighted_mean_rmse_demonstrator(per_syn, :pair_selection)
    agg_ok = isapprox(agg_syn.pooled_candidate, expected_pooled;
                      rtol = 1e-12) &&
             agg_syn.worst_case_candidate == 0.2 &&
             !isapprox(unweighted, agg_syn.pooled_candidate; rtol = 1e-3) &&
             occursin("NONE", agg_syn.binding_election) &&
             !any(k == :unweighted_mean_rmse_demonstrator
                  for k in keys(pairs(agg_syn)))
    gates["pooled_is_sse_over_count_not_mean_of_rmse"] =
        agg_ok ? "passed" : "failed"
    agg_ok || push!(fails, "pooled=$(agg_syn.pooled_candidate) expected " *
        "$expected_pooled; unweighted=$unweighted must differ and stay " *
        "outside the candidates")

    # --- real two-scenario aggregation (synthetic x1.001 candidates) ------
    per_real = Any[]
    for p in (sw_scen1, sw_scen2)
        rr = matched_state_od(sw32, p; active_absorption_gases = sw_gases_test)
        st = total_od_pair_stats(rr.total_raw, rr.total_raw .* 1.001)
        push!(per_real, merge(st, (scenario = rr.scenario,
                                   scenario_path = p)))
    end
    agg_real = aggregation_candidates(per_real, :pair_selection)
    # the pooled expectation is DERIVED from the per-scenario SSE/count
    # fields themselves (exact equality), never from an eps-free formula
    exp_pooled_real = sqrt(
        sum(p.policies.pair_selection.stats.sse for p in per_real) /
        sum(p.policies.pair_selection.stats.n_selected for p in per_real))
    exp_worst_real = maximum(
        p.policies.pair_selection.stats.log_rmse for p in per_real)
    real_agg_ok = agg_real.n_scenarios == 2 &&
                  agg_real.pooled_candidate == exp_pooled_real &&
                  agg_real.worst_case_candidate == exp_worst_real
    gates["real_two_scenario_aggregation"] = real_agg_ok ? "passed" : "failed"
    real_agg_ok || push!(fails, "real two-scenario aggregation failed: " *
        "pooled=$(agg_real.pooled_candidate) expected $exp_pooled_real " *
        "(derived from per-scenario SSE/count); worst=" *
        "$(agg_real.worst_case_candidate) expected $exp_worst_real")

    # --- fail-closed pure-core fixtures ------------------------------------
    bds_expect_refusal!(gates, fails, "refuse_axes_mismatch",
        "axes differ", () -> total_od_pair_stats(zeros(2, 3), zeros(3, 2)))
    bds_expect_refusal!(gates, fails, "refuse_nonfinite",
        "non-finite total OD",
        () -> total_od_pair_stats([1.0, NaN], [1.0, 1.0]))
    bds_expect_refusal!(gates, fails, "refuse_inf",
        "non-finite total OD",
        () -> total_od_pair_stats([1.0, Inf], [1.0, 1.0]))
    bds_expect_refusal!(gates, fails, "refuse_negative_total_finding",
        "negative total OD is a FINDING",
        () -> total_od_pair_stats([1.0, -1.0e-9], [1.0, 1.0]))
    bds_expect_refusal!(gates, fails, "refuse_unknown_policy",
        "unknown nonpositive-pair policy",
        () -> total_od_policy_stats([1.0], [1.0], :bogus))
    bds_expect_refusal!(gates, fails, "refuse_unknown_policy_aggregation",
        "unknown nonpositive-pair policy",
        () -> aggregation_candidates(per_syn, :bogus))
    bds_expect_refusal!(gates, fails, "refuse_empty_arrays",
        "empty total-OD arrays",
        () -> total_od_pair_stats(Float64[], Float64[]))
    # DIAGNOSTIC refusal fixture (labeled; NOT campaign evidence): on the
    # ch4-350 scenario the ch4 mole fraction sits BELOW the stored
    # reference, so a ch4-only LW total (relative-linear per-gas OD) is
    # genuinely negative on real data -- the negative-total finding fires
    # through the full path-level API, and the exact negative
    # reference/candidate counts are retained in the reason and recorded
    # as an artifact diagnostic (negative totals are findings). Note:
    # rel-415 would NOT trigger this (ch4 at reference there).
    lw_ch4_350 = joinpath(BDS_CKDMIP,
        "evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-350.h5")
    ch4_reason = try
        per_scenario_total_od_stats(lw32, lw32, lw_ch4_350;
                                    active_absorption_gases = ["ch4"])
        "no_refusal"
    catch err
        err isa MsoRefusal ? err.reason : "wrong_exception"
    end
    ch4_ok = occursin("negative total OD is a FINDING", ch4_reason) &&
             occursin(r"reference \d+, candidate \d+ negative", ch4_reason)
    gates["diagnostic_ch4_only_negative_total_refuses"] =
        ch4_ok ? "passed" : "failed"
    ch4_ok || push!(fails, "ch4-only diagnostic refusal lacked exact " *
                           "negative counts: $(first(ch4_reason, 120))")

    # --- decision map (derived live where it cites the manifest) ----------
    manifest = JSON.parsefile(BDS_MANIFEST_JSON)
    decision_map = Dict(
        "D1_dataset_binding" => Dict(
            "state" => "UNRESOLVED (requires recorded ruling)",
            "candidate_set" => Dict(
                "source_manifest" => basename(BDS_MANIFEST_JSON),
                "manifest_status" => manifest["status"],
                "counts" => manifest["counts"],
                "note" => "entries remain tied to the manifest inventory " *
                    "labels/sha256 fingerprints, joined live per scenario " *
                    "by manifest_fingerprint with size+hash re-" *
                    "verification; eval2 rel-415 pair PENDING G2c/G2d and " *
                    "refused as a metric row until present"),
            "alternative" => "single present-day 50-column file " *
                "(explicitly NOT the campaign set per design note rev 3)"),
        "D2_aggregation" => Dict(
            "state" => "UNRESOLVED (requires recorded ruling)",
            "candidates" => "worst-case (max per-scenario log-RMSE) vs " *
                "pooled (sqrt(sum SSE / sum selected count)) -- BOTH " *
                "computed by aggregation_candidates(); the unweighted " *
                "mean of scenario RMSEs is NOT a candidate and is kept " *
                "outside as a demonstrator"),
        "D3_nonpositive_pair_policy" => Dict(
            "state" => "UNRESOLVED (requires recorded ruling) -- the " *
                "design-note wording 'positive-pair selection / epsilon " *
                "clamping' is not a unique algorithm",
            "variant_pair_selection" => "both totals > 0 selected; " *
                "exact-zero pairs excluded and counted; log(x+eps) with " *
                "eps = positive_eps over the SELECTED values",
            "variant_eps_clamping" => "all nonnegative pairs included; " *
                "log(x+eps) with eps = positive_eps over ALL values " *
                "(unmodified positive_eps of ecckd_recovery_metrics.jl, " *
                "reused by include)",
            "invariant" => "NEGATIVE totals in either definition are a " *
                "finding/refusal under BOTH variants, never excluded or " *
                "clamped; with no zeros the variants are numerically " *
                "identical; they can diverge only when zeros are present"),
        "D4_active_gas_lists" => Dict(
            "state" => "UNRESOLVED (requires recorded ruling)",
            "constraint" => "identical reference/candidate lists are " *
                "ENFORCED for campaign-comparable metrics (single-list " *
                "API); the binding runner needs recorded per-scenario " *
                "lists (rel scenarios omit cfc11/cfc12 from their axes, " *
                "so LW lists are scenario-dependent)",
            "self_test_lists" => "labeled TEST inputs only"),
        "cross_reference" => "thresholds 4-5 aggregation semantics are a " *
            "SEPARATE ruling: gate4_regression_margin_semantics_" *
            "evidence.md (four open axes)")

    # metric rows joined to live-verified manifest fingerprints
    metric_rows = [merge(Dict(
        "scenario_path" => p.scenario_path,
        "n_pairs_total" => p.n_pairs_total,
        "zero_totals" => Dict(
            "reference" => p.zero_totals.reference,
            "candidate" => p.zero_totals.candidate,
            "both" => p.zero_totals.both,
            "reference_only" => p.zero_totals.reference_only,
            "candidate_only" => p.zero_totals.candidate_only),
        "pair_selection" => Dict(
            "n_selected" => p.policies.pair_selection.stats.n_selected,
            "n_excluded_zero_pairs" =>
                p.policies.pair_selection.stats.n_excluded_zero_pairs,
            "sse" => p.policies.pair_selection.stats.sse,
            "log_rmse" => p.policies.pair_selection.stats.log_rmse,
            "epsilon" => p.policies.pair_selection.stats.epsilon_used),
        "eps_clamping" => Dict(
            "n_selected" => p.policies.eps_clamping.stats.n_selected,
            "sse" => p.policies.eps_clamping.stats.sse,
            "log_rmse" => p.policies.eps_clamping.stats.log_rmse,
            "epsilon" => p.policies.eps_clamping.stats.epsilon_used)),
        manifest_fingerprint(p.scenario_path)) for p in per_real]

    status = (isempty(fails) && all(v == "passed" for v in values(gates))) ?
             "g2_binding_scaffold_ready_awaiting_rulings" :
             "g2_binding_scaffold_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_g2_binding_decision_scaffold",
        "data_mode" => "neutral_calculations_and_decision_map_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "decision_map" => decision_map,
        "negative_total_diagnostic" => Dict(
            "label" => "DIAGNOSTIC ONLY -- NOT campaign or acceptance " *
                "evidence: real-data demonstration that a ch4-only LW " *
                "total (relative-linear per-gas OD) is negative when the " *
                "scenario mole fraction sits below the stored reference",
            "scenario" => manifest_fingerprint(lw_ch4_350),
            "active_absorption_gases" => ["ch4"],
            "refusal_reason_with_counts" => ch4_reason),
        "demo_metric_rows_manifest_joined" => metric_rows,
        "demo_aggregation" => Dict(
            "candidates" => Dict(
                "worst_case" => agg_real.worst_case_candidate,
                "pooled_sse_over_count" => agg_real.pooled_candidate,
                "sum_sse" => agg_real.sum_sse,
                "sum_selected" => agg_real.sum_selected),
            "non_candidate_demonstrator" => Dict(
                "unweighted_mean_rmse" =>
                    unweighted_mean_rmse_demonstrator(per_real,
                                                      :pair_selection),
                "note" => "NOT an aggregation candidate; shown only to " *
                    "demonstrate it differs from pooled on unequal counts"),
            "note" => "synthetic x1.001 candidate totals on two manifest " *
                "scenarios; labeled demo, no acceptance meaning, no " *
                "election"),
        "provenance" => Dict("branch" => branch,
            "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working " *
                "tree before its own commit",
            "lw32" => basename(lw32), "sw32" => basename(sw32)),
        "disclaimer" => "decision map + neutral deterministic " *
            "calculations only; NO dataset, aggregation, nonpositive-" *
            "pair-policy, or gas-list election; NO threshold verdict; " *
            "the binding Gate-2 runner remains unimplemented pending " *
            "the D1-D4 rulings.",
    )
    mkpath(dirname(BDS_RESULTS_JSON))
    open(BDS_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(BDS_RESULTS_MD, "w") do io
        println(io, "# Gate-4 Gate-2 binding-decision scaffold\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Verdict |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\n## Open decision points\n")
        for k in ("D1_dataset_binding", "D2_aggregation",
                  "D3_nonpositive_pair_policy", "D4_active_gas_lists")
            d = decision_map[k]
            println(io, "- **$k** [$(d["state"])]")
            for f in sort(collect(keys(d)))
                f == "state" && continue
                v = d[f]
                println(io, "  - $f: ", v isa AbstractDict ?
                        JSON.json(v) : v isa AbstractVector ?
                        join(v, "; ") : v)
            end
        end
        println(io, "\n", decision_map["cross_reference"])
        da = result["demo_aggregation"]
        println(io, "\nDemo aggregation (labeled synthetic x1.001, no " *
                    "election): worst $(da["candidates"]["worst_case"]) / " *
                    "pooled sqrt(SSE-sum/n-sum) " *
                    "$(da["candidates"]["pooled_sse_over_count"]); " *
                    "non-candidate unweighted mean " *
                    "$(da["non_candidate_demonstrator"]["unweighted_mean_rmse"]).")
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_g2_binding_decision_scaffold: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), first(fails, 8))
    return status == "g2_binding_scaffold_ready_awaiting_rulings" ? 0 : 1
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(bds_main())
end
