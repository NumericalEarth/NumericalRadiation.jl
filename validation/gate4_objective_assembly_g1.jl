# Gate-4 objective-term parity ASSEMBLY gates: verifies that the full training
# objective assembles exactly from its components -- the ported flux/heating
# kernels (ecckd_{lw,sw}_ckd_loss), the correlated prior (g4_prior_term /
# g4_prior_term_conc), and the negative-OD penalty (g4_negative_od_penalty) --
# with the upstream semantic guards (SW downwelling-only heating, per-band
# TOA-up 20x placement, separable spectral-boundary term) holding through
# assembly. Pure plumbing over existing functions; NO new physics.
#
# Data mode: synthetic objective-assembly only. No real-data floor, objective
# value, or recovery claim.

include(joinpath(@__DIR__, "gate4_forward_map.jl"))

using Dates
import JSON
import Enzyme

const GA_RESULTS_JSON = validation_results_path("gate4_objective_assembly_g1.json")
const GA_RESULTS_MD = validation_results_path("gate4_objective_assembly_g1.md")

approx(a, b, rtol) = abs(a - b) <= rtol * max(abs(a), abs(b), 1e-300)

# --- synthetic fixtures ----------------------------------------------------------
function lw_fixture(nlay, nband)
    lwr = sqrt.(collect(range(2000.0, 98000.0; length = nlay + 1)))
    layer_weight = (lwr[2:end] .- lwr[1:end-1]) ./ sum(lwr[2:end] .- lwr[1:end-1])
    mk(shape, scale, ph) = [scale * (1 + 0.1 * sin(1.3 * i + 0.7 * j + ph))
                            for i in 1:shape[1], j in 1:shape[2]]
    return (
        heating_rate_fwd = mk((nlay, nband), 2e-5, 0.1),
        heating_rate_true = mk((nlay, nband), 2e-5, 0.4),
        flux_dn_fwd = mk((nlay + 1, nband), 120.0, 0.2),
        flux_dn_true = mk((nlay + 1, nband), 120.0, 0.5),
        flux_up_fwd = mk((nlay + 1, nband), 90.0, 0.3),
        flux_up_true = mk((nlay + 1, nband), 90.0, 0.6),
        layer_weight = layer_weight,
    )
end

function assembled_total(lw, sw, theta, theta_prior, Sinv, bg, od_proxy;
                         lw_w = (0.02, 0.2, 0.8), sw_w = (0.4, 0.1, 0.4),
                         sbw_lw = 0.0, sp_dn = nothing, sp_up = nothing)
    L_lw = ecckd_lw_ckd_loss(; lw...,
        flux_weight = lw_w[1], flux_profile_weight = lw_w[2],
        broadband_weight = lw_w[3], spectral_boundary_weight = sbw_lw,
        spectral_flux_dn_surf = sp_dn, spectral_flux_up_toa = sp_up)
    L_sw = ecckd_sw_ckd_loss(; sw...,
        flux_weight = sw_w[1], flux_profile_weight = sw_w[2],
        broadband_weight = sw_w[3], all_albedo_positive = true)
    J_pr = g4_prior_term(theta, theta_prior, Sinv, bg)
    J_pen = g4_negative_od_penalty(od_proxy, 1.0e4)
    return L_lw + L_sw + J_pr + J_pen, (L_lw, L_sw, J_pr, J_pen)
end

function main()
    fails = String[]
    gates = Dict{String, String}()
    stats = Dict{String, Any}()
    nlay = 8

    lw = lw_fixture(nlay, 1)
    sw = lw_fixture(nlay, 3)          # multi-band SW for the 20x placement gate
    ngass, np_, nt_ = 2, 3, 2
    theta = zeros(ngass, np_, nt_)
    for g in 1:ngass, i in 1:np_, j in 1:nt_
        theta[g, i, j] = 0.05 * g - 0.02 * i + 0.01 * j
    end
    theta_prior = zero(theta)
    Sinv = inv(g4_prior_shape_matrix(nt_, np_, 0.8, 0.8))
    bg = 8.0
    od_proxy = [0.4, -0.15, 0.02, -0.05, 1.1]

    # Gate A: component sum equals assembled total (LW and SW fixtures)
    total, comps = assembled_total(lw, sw, theta, theta_prior, Sinv, bg, od_proxy)
    stats["components"] = Dict("lw_kernel" => comps[1], "sw_kernel" => comps[2],
                               "prior" => comps[3], "penalty" => comps[4])
    stats["assembled_total"] = total
    err_sum = abs(total - sum(comps))
    stats["component_sum_abs_err"] = err_sum
    gates["component_sum_equals_total"] = err_sum == 0.0 ? "passed" : "failed"
    err_sum == 0.0 || push!(fails, "component sum != total: $err_sum")

    # Gate B: SW heating is downwelling-only in the assembled objective.
    # Construct dn-only heating targets/fwd; a net-flux variant must CHANGE the
    # kernel value (proving the assembly is sensitive to the convention), and
    # the assembled total must use the dn-only value exactly.
    p_hl = collect(range(3000.0, 97000.0; length = nlay + 1))
    hr_dn_fwd = reduce(hcat, [g4_sw_heating_rate(p_hl, lw.flux_dn_fwd[:, 1] .*
                                                 (1 + 0.01b)) for b in 1:3])
    hr_dn_true = reduce(hcat, [g4_sw_heating_rate(p_hl, lw.flux_dn_true[:, 1] .*
                                                  (1 + 0.01b)) for b in 1:3])
    hr_net_fwd = reduce(hcat, [g4_heating_rate(p_hl, lw.flux_dn_fwd[:, 1] .*
                                               (1 + 0.01b),
                                               lw.flux_up_fwd[:, 1]) for b in 1:3])
    sw_dn = merge(sw, (heating_rate_fwd = hr_dn_fwd, heating_rate_true = hr_dn_true))
    sw_net = merge(sw, (heating_rate_fwd = hr_net_fwd, heating_rate_true = hr_dn_true))
    L_dn = ecckd_sw_ckd_loss(; sw_dn..., flux_weight = 0.4,
        flux_profile_weight = 0.1, broadband_weight = 0.4,
        all_albedo_positive = true)
    L_net = ecckd_sw_ckd_loss(; sw_net..., flux_weight = 0.4,
        flux_profile_weight = 0.1, broadband_weight = 0.4,
        all_albedo_positive = true)
    conv_sensitive = abs(L_dn - L_net) > 1e-12 * max(L_dn, L_net)
    tot_dn, comps_dn = assembled_total(lw, sw_dn, theta, theta_prior, Sinv, bg, od_proxy)
    uses_dn = comps_dn[2] == L_dn
    stats["sw_heating_dn_only"] = Dict("L_dn" => L_dn, "L_net_variant" => L_net,
        "convention_sensitive" => conv_sensitive, "assembly_uses_dn" => uses_dn)
    gates["sw_heating_downwelling_only"] = conv_sensitive && uses_dn ?
        "passed" : "failed"
    (conv_sensitive && uses_dn) ||
        push!(fails, "SW dn-only heating gate: sensitive=$conv_sensitive uses_dn=$uses_dn")

    # Gate C: per-band TOA-up 20x placement (SW), no 20x in broadband blend.
    # Perturb ONLY TOA-up of band 2 by delta on an otherwise perfect fixture.
    delta = 0.37
    sw0 = (heating_rate_fwd = copy(sw.heating_rate_true),
           heating_rate_true = sw.heating_rate_true,
           flux_dn_fwd = copy(sw.flux_dn_true), flux_dn_true = sw.flux_dn_true,
           flux_up_fwd = copy(sw.flux_up_true), flux_up_true = sw.flux_up_true,
           layer_weight = sw.layer_weight)
    sw0.flux_up_fwd[1, 2] += delta
    fw, fpw, bbw = 0.4, 0.0, 0.4
    L_pert = ecckd_sw_ckd_loss(; sw0..., flux_weight = fw,
        flux_profile_weight = fpw, broadband_weight = bbw,
        all_albedo_positive = true)
    nband = 3
    expected = (1 - bbw) / nband * fw * 20 * delta^2 + bbw * fw * delta^2
    stats["toa20"] = Dict("loss" => L_pert, "expected" => expected)
    ok20 = approx(L_pert, expected, 1e-12)
    gates["sw_toa_up_20x_placement"] = ok20 ? "passed" : "failed"
    ok20 || push!(fails, "TOA-up 20x placement: $L_pert vs $expected")

    # Gate D: spectral-boundary optional term separates exactly (LW), with
    # SHAPE-MATCHED per-g spectral arrays: orig arrays are (nlay+1, 32) and the
    # boundary targets are 32-element vectors -- no broadcasting shortcuts.
    sbw = 0.1
    ng_sp = 32
    spd = collect(range(1.0, 4.0; length = ng_sp))
    spu = collect(range(2.0, 5.0; length = ng_sp))
    orig_dn = [lw.flux_dn_fwd[i, 1] * (1 + 0.01 * g) for i in 1:nlay+1, g in 1:ng_sp]
    orig_up = [lw.flux_up_fwd[i, 1] * (1 + 0.02 * g) for i in 1:nlay+1, g in 1:ng_sp]
    L_no = ecckd_lw_ckd_loss(; lw..., flux_weight = 0.02,
        flux_profile_weight = 0.2, broadband_weight = 0.8,
        flux_dn_fwd_orig = orig_dn, flux_up_fwd_orig = orig_up)
    L_sb = ecckd_lw_ckd_loss(; lw..., flux_weight = 0.02,
        flux_profile_weight = 0.2, broadband_weight = 0.8,
        spectral_boundary_weight = sbw,
        flux_dn_fwd_orig = orig_dn, flux_up_fwd_orig = orig_up,
        spectral_flux_dn_surf = spd, spectral_flux_up_toa = spu)
    term = sbw * (sum(abs2, orig_dn[end, :] .- spd) +
                  sum(abs2, orig_up[1, :] .- spu))
    ok_sb = approx(L_sb - L_no, term, 1e-10)
    stats["spectral_boundary"] = Dict("with" => L_sb, "without" => L_no,
        "independent_term" => term, "difference" => L_sb - L_no)
    gates["spectral_boundary_separable"] = ok_sb ? "passed" : "failed"
    ok_sb || push!(fails,
        "spectral boundary separation: diff=$(L_sb - L_no) vs term=$term")

    # Gate E: prior + penalty add exactly and gradients agree (Enzyme vs FD).
    f_pr(t) = g4_prior_term(t, theta_prior, Sinv, bg)
    f_pen(x) = g4_negative_od_penalty(x, 1.0e4)
    gpr = zero(theta)
    Enzyme.autodiff(Enzyme.Reverse, Enzyme.Const(f_pr), Enzyme.Active,
                    Enzyme.Duplicated(copy(theta), gpr))
    max_rel_pr = 0.0
    for idx in 1:length(theta)
        h = 6e-6
        tp = copy(theta); tm = copy(theta)
        tp[idx] += h; tm[idx] -= h
        fd = (f_pr(tp) - f_pr(tm)) / (2h)
        max_rel_pr = max(max_rel_pr,
            abs(fd - gpr[idx]) / max(abs(fd), abs(gpr[idx]), 1e-300))
    end
    gpen = zero(od_proxy)
    Enzyme.autodiff(Enzyme.Reverse, Enzyme.Const(f_pen), Enzyme.Active,
                    Enzyme.Duplicated(copy(od_proxy), gpen))
    max_rel_pen = 0.0
    for idx in 1:length(od_proxy)
        h = 1e-7
        xp = copy(od_proxy); xm = copy(od_proxy)
        xp[idx] += h; xm[idx] -= h
        fd = (f_pen(xp) - f_pen(xm)) / (2h)
        max_rel_pen = max(max_rel_pen,
            abs(fd - gpen[idx]) / max(abs(fd), abs(gpen[idx]), 1e-6))
    end
    # direct 4-D concentration-axis prior exercise (not delegated to G0)
    nc4, np4, nt4 = 2, 2, 2
    th4 = zeros(1, nc4, np4, nt4)
    for c in 1:nc4, i in 1:np4, j in 1:nt4
        th4[1, c, i, j] = 0.04 * c - 0.015 * i + 0.007 * j
    end
    S4inv = inv(g4_prior_shape_matrix_3d(nt4, np4, nc4, 0.8, 0.8, 0.8))
    f_pr4(t) = g4_prior_term_conc(t, zero(th4), S4inv, 2.0)
    g4d = zero(th4)
    Enzyme.autodiff(Enzyme.Reverse, Enzyme.Const(f_pr4), Enzyme.Active,
                    Enzyme.Duplicated(copy(th4), g4d))
    max_rel_pr4 = 0.0
    for idx in 1:length(th4)
        h = 6e-6
        tp = copy(th4); tm = copy(th4)
        tp[idx] += h; tm[idx] -= h
        fd = (f_pr4(tp) - f_pr4(tm)) / (2h)
        max_rel_pr4 = max(max_rel_pr4,
            abs(fd - g4d[idx]) / max(abs(fd), abs(g4d[idx]), 1e-300))
    end
    stats["prior_grad_max_rel"] = max_rel_pr
    stats["prior_conc_grad_max_rel"] = max_rel_pr4
    stats["penalty_grad_max_rel"] = max_rel_pen
    okE = max_rel_pr < 1e-6 && max_rel_pen < 1e-6 && max_rel_pr4 < 1e-6
    gates["prior_penalty_gradients"] = okE ? "passed" : "failed"
    okE || push!(fails, "prior/penalty gradients: $max_rel_pr / " *
        "$max_rel_pen / conc4d=$max_rel_pr4")

    # Gate F: total-objective gradient equals sum of component gradients.
    # assembled scalar over theta with fixed kernel inputs; only the prior
    # depends on theta, so grad(assembled) must equal the prior gradient
    f_asm(t) = assembled_total(lw, sw, t, theta_prior, Sinv, bg, od_proxy)[1]
    gasm = zero(theta)
    Enzyme.autodiff(Enzyme.Reverse, Enzyme.Const(f_asm), Enzyme.Active,
                    Enzyme.Duplicated(copy(theta), gasm))
    # only the prior depends on theta here, so grad(assembled) must equal gpr
    max_rel_F = maximum(abs.(gasm .- gpr) ./
                        max.(abs.(gasm), abs.(gpr), 1e-300))
    stats["total_vs_component_grad_max_rel"] = max_rel_F
    okF = max_rel_F < 1e-12
    gates["total_grad_equals_component_sum"] = okF ? "passed" : "failed"
    okF || push!(fails, "total vs component gradient: $max_rel_F")

    status = isempty(fails) ? "assembly_gates_passed" : "assembly_gates_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_objective_assembly_g1",
        "data_mode" => "synthetic_objective_assembly_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "term_list" => ["ecckd_lw_ckd_loss", "ecckd_sw_ckd_loss",
                        "g4_prior_term", "g4_prior_term_conc (4-D, gated here directly)",
                        "g4_negative_od_penalty"],
        "gates" => gates, "failures" => fails, "stats" => stats,
        "tolerances" => Dict("component_sum" => "exact",
            "toa20_analytic" => 1e-12, "spectral_boundary" => 1e-10,
            "gradients" => 1e-6, "grad_additivity" => 1e-12),
        "maxrss_bytes" => Int(Sys.maxrss()),
        "provenance" => Dict("branch" => branch,
            "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "synthetic objective-assembly gates only; no " *
                        "real-data floor, objective value, or recovery claim.",
    )
    mkpath(dirname(GA_RESULTS_JSON))
    open(GA_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(GA_RESULTS_MD, "w") do io
        println(io, "# Gate-4 objective assembly gates\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nProvenance: branch `$branch`, generated_from_head `$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_objective_assembly_g1: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "assembly_gates_passed" ? 0 : 1
end

exit(main())
