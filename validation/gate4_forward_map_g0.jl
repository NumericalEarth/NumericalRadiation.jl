# Gate-4 P2 G0 unit gates, Stage 1: interpolation node-exactness (with explicit
# upstream top-edge clamp semantics), analytic LW/SW radiative-transfer hand
# fixtures, and a published-table load gate for validation/gate4_forward_map.jl.
#
# Data mode: synthetic values plus published CKD definition tables (shapes and
# node values only). No CKDMIP flux data; no objective-value, floor, or
# recovery claims. Expected values in gates 2-3 are computed with independent
# scalar arithmetic, NOT by calling the implementation under test.

include(joinpath(@__DIR__, "gate4_forward_map.jl"))

using Dates
using Printf
import JSON
import Enzyme

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))
using NumericalRadiation

const G0_RESULTS_JSON = validation_results_path("gate4_forward_map_g0.json")
const G0_RESULTS_MD = validation_results_path("gate4_forward_map_g0.md")

approx_equal(a, b, rtol) = abs(a - b) <= rtol * max(abs(a), abs(b), 1e-300)

# --- Gate 1: interpolation node semantics ---------------------------------------
# Interior and lower-edge nodes reproduce table values to 1e-12. Top-edge nodes
# follow the UPSTREAM INDEX CLAMP (fractional index <= n-1.0001, item 17), so
# the expected value at a top node is the analytically clamped one: weight
# 0.9999 on the final interval, i.e. 0.0001*T[n-1] + 0.9999*T[n] along the
# clamped axis — verified to 1e-12 against that expression, not the raw node.
function run_gate1()
    fails = String[]
    logp_axis = collect(range(log(100.0), log(100000.0); length = 5))
    t_axis = collect(range(180.0, 320.0; length = 4))
    np, nt = 5, 4
    table = [3.0 + 2.0 * i + 0.5 * j^2 for i in 1:np, j in 1:nt]
    # clamped 1-D reconstruction along one axis (0.9999 weight on last interval)
    clamp1(v_prev, v_last) = 0.0001 * v_prev + 0.9999 * v_last
    expected_node(i, j) = begin
        vi(jj) = i < np ? table[i, jj] : clamp1(table[np-1, jj], table[np, jj])
        j < nt ? vi(j) : clamp1(vi(nt-1), vi(nt))
    end
    for i in 1:np, j in 1:nt
        s = g4_bilinear_stencil(logp_axis, t_axis, logp_axis[i], t_axis[j])
        v = g4_bilinear_apply(table, s)
        want = expected_node(i, j)
        kind = (i == np || j == nt) ? "top-edge-clamped" : "interior"
        approx_equal(v, want, 1e-12) ||
            push!(fails, "gate1 $kind node ($i,$j): got $v want $want")
    end
    let q_logp = 0.5 * (logp_axis[2] + logp_axis[3]),
        q_t = 0.5 * (t_axis[1] + t_axis[2])
        s = g4_bilinear_stencil(logp_axis, t_axis, q_logp, q_t)
        v = g4_bilinear_apply(table, s)
        want = 0.25 * (table[2,1] + table[3,1] + table[2,2] + table[3,2])
        approx_equal(v, want, 1e-12) ||
            push!(fails, "gate1 midpoint: $v vs $want")
    end
    return fails
end

# --- Gate 2: LW analytic 2-layer fixture ----------------------------------------
function run_gate2()
    fails = String[]
    tau1 = 0.5; tau2 = 1.0e-9
    B = [100.0, 110.0, 120.0]; Bs = 130.0; eps_s = 1.0
    e1 = 1 - exp(-1.66 * tau1)
    f1 = 1 - e1 / (1.66 * tau1)
    e2 = 1 - exp(-1.66 * tau2)
    f2 = 0.5 * e2
    e2 < 1.0e-5 || push!(fails, "gate2 fixture invalid: e2=$e2 not below threshold")
    dn2 = 0.0 * (1 - e1) + B[1] * (e1 - f1) + B[2] * f1
    dn3 = dn2 * (1 - e2) + B[2] * (e2 - f2) + B[3] * f2
    up3 = Bs * eps_s + (1 - eps_s) * dn3
    up2 = up3 * (1 - e2) + B[3] * (e2 - f2) + B[2] * f2
    up1 = up2 * (1 - e1) + B[2] * (e1 - f1) + B[1] * f1
    r = g4_lw_fluxes([tau1, tau2], B, Bs, eps_s)
    ok = r.flux_dn[1] == 0.0 &&
         approx_equal(r.flux_dn[2], dn2, 1e-12) &&
         approx_equal(r.flux_dn[3], dn3, 1e-12) &&
         approx_equal(r.flux_up[3], up3, 1e-12) &&
         approx_equal(r.flux_up[2], up2, 1e-12) &&
         approx_equal(r.flux_up[1], up1, 1e-12)
    ok || push!(fails,
        "gate2 LW fixture mismatch: impl dn=$(r.flux_dn) up=$(r.flux_up) " *
        "want dn=[0,$dn2,$dn3] up=[$up1,$up2,$up3]")
    return fails
end

# --- Gate 3: SW analytic 2-layer fixture ----------------------------------------
function run_gate3()
    fails = String[]
    tau = [0.3, 0.2]; mu0 = 0.5; ssi = 1361.0
    p_hl = [20000.0, 60000.0, 100000.0]
    d1 = mu0 * ssi
    d2 = d1 * exp(-tau[1] / mu0)
    d3 = d2 * exp(-tau[2] / mu0)
    r0 = g4_sw_fluxes(tau, mu0, ssi, 0.0)
    (approx_equal(r0.flux_dn[1], d1, 1e-12) &&
     approx_equal(r0.flux_dn[2], d2, 1e-12) &&
     approx_equal(r0.flux_dn[3], d3, 1e-12) &&
     r0.flux_up === nothing) ||
        push!(fails, "gate3 direct-only path mismatch")
    hr = g4_sw_heating_rate(p_hl, r0.flux_dn)
    hr1 = -(9.80665 / 1004.0) / (p_hl[2] - p_hl[1]) * (d2 - d1)
    hr2 = -(9.80665 / 1004.0) / (p_hl[3] - p_hl[2]) * (d3 - d2)
    (approx_equal(hr[1], hr1, 1e-12) && approx_equal(hr[2], hr2, 1e-12) &&
     hr[1] > 0 && hr[2] > 0) ||
        push!(fails, "gate3 SW dn-only heating mismatch: $hr vs [$hr1,$hr2]")
    alb = 0.3
    u3 = d3 * alb
    u2 = u3 * exp(-2.0 * tau[2])
    u1 = u2 * exp(-2.0 * tau[1])
    r1 = g4_sw_fluxes(tau, mu0, ssi, alb)
    (r1.flux_up !== nothing &&
     approx_equal(r1.flux_up[3], u3, 1e-12) &&
     approx_equal(r1.flux_up[2], u2, 1e-12) &&
     approx_equal(r1.flux_up[1], u1, 1e-12)) ||
        push!(fails, "gate3 albedo path mismatch")
    hr_alb = g4_sw_heating_rate(p_hl, r1.flux_dn)
    hr_alb == hr ||
        push!(fails, "gate3 SW heating must ignore upwelling (Appendix A)")
    return fails
end

# --- Gate 4 (Stage 1 hard gate): published SW32 table load -----------------------
# The deliverable requires published tables, not just synthetic: loading the
# published SW32 definition and finding at least one *_molar_absorption_coeff
# array is a REAL gate; failure fails the artifact.
function run_gate_published()
    fails = String[]
    record = Dict{String, Any}()
    try
        sw_path = NumericalRadiation.official_ecckd_definition_path(:shortwave_32)
        st = g4_load_ckd_definition(sw_path)
        record["file"] = basename(sw_path)
        record["coefficient_arrays"] = sort(collect(keys(st.coefficients)))
        record["support_arrays"] = sort(collect(keys(st.support)))
        record["note"] = "axis-semantics alignment deferred to G1 (Stage 2+)"
        if isempty(st.coefficients)
            push!(fails, "gate4 published load: no *_molar_absorption_coeff arrays found")
            record["status"] = "loaded_but_no_coefficient_arrays"
        else
            record["status"] = "loaded"
        end
    catch err
        record["status"] = "load_failed"
        record["error"] = sprint(showerror, err)
        push!(fails, "gate4 published load failed: " * record["error"])
    end
    return fails, record
end

# --- Gate 5 (Stage 2): Enzyme full-chain adjoint vs central FD --------------------
# loss ∘ RT ∘ interpolation w.r.t. LOG-COEFFICIENTS on a synthetic single-gas,
# single-band LW configuration. Self-loss-zero validates array orientation.
function build_chain_context()
    nlay = 6
    np, nt = 5, 4
    logp_axis = collect(range(log(1000.0), log(100000.0); length = np))
    t_axis = collect(range(180.0, 320.0; length = nt))
    p_hl = collect(range(5000.0, 95000.0; length = nlay + 1))
    p_fl = 0.5 .* (p_hl[1:end-1] .+ p_hl[2:end])
    t_fl = collect(range(220.0, 300.0; length = nlay))
    stencils = [g4_bilinear_stencil(logp_axis, t_axis, log(p_fl[l]), t_fl[l])
                for l in 1:nlay]
    vmr = 400e-6
    layer_moles = [g4_simple_weight(p_hl[l+1] - p_hl[l]) * vmr for l in 1:nlay]
    planck_hl = collect(range(80.0, 130.0; length = nlay + 1))
    lw_raw = sqrt.(p_hl[2:end]) .- sqrt.(p_hl[1:end-1])
    layer_weight = lw_raw ./ sum(lw_raw)
    return (nlay = nlay, np = np, nt = nt, stencils = stencils,
            layer_moles = layer_moles, planck_hl = planck_hl,
            p_hl = p_hl, layer_weight = layer_weight)
end

function run_gate5()
    fails = String[]
    ng = 4
    c = build_chain_context()
    # deterministic theta_true: coefficients giving tau of order 0.05-1
    theta_true = Array{Float64}(undef, ng, c.np, c.nt)
    for g in 1:ng, i in 1:c.np, j in 1:c.nt
        theta_true[g, i, j] = log(2.0e-4 * (1 + 0.15 * g) *
                                  (1 + 0.05 * i) * (1 + 0.03 * j))
    end
    # targets = chain outputs at theta_true (self-consistent truth)
    ctx0 = G4LwChainContext(collect(c.stencils), c.layer_moles, c.planck_hl,
        140.0, c.p_hl, c.layer_weight,
        zeros(c.nlay, 1), zeros(c.nlay + 1, 1), zeros(c.nlay + 1, 1),
        0.02, 0.2, 0.8)
    fdn0, fup0 = g4_lw_chain_fluxes(theta_true, ctx0)
    hr0 = g4_heating_rate(c.p_hl, fdn0, fup0)
    ctx = G4LwChainContext(collect(c.stencils), c.layer_moles, c.planck_hl,
        140.0, c.p_hl, c.layer_weight,
        reshape(copy(hr0), :, 1), reshape(copy(fdn0), :, 1),
        reshape(copy(fup0), :, 1), 0.02, 0.2, 0.8)
    # self-loss must be ~0 at theta_true (validates orientation and wiring)
    l0 = g4_lw_chain_loss(theta_true, ctx)
    abs(l0) <= 1e-18 * max(1.0, sum(abs2, hr0)) ||
        push!(fails, "gate5 self-loss not ~0: $l0")
    # perturbed point with nonzero loss/gradient
    theta = copy(theta_true)
    for g in 1:ng, i in 1:c.np, j in 1:c.nt
        theta[g, i, j] += 0.1 * sin(3.1 * g + 1.7 * i + 0.9 * j)
    end
    l1 = g4_lw_chain_loss(theta, ctx)
    l1 > 0 || push!(fails, "gate5 perturbed loss not positive: $l1")
    # Enzyme reverse gradient w.r.t. theta (full chain)
    grad = zero(theta)
    Enzyme.autodiff(Enzyme.Reverse,
                    Enzyme.Const(t -> g4_lw_chain_loss(t, ctx)),
                    Enzyme.Active,
                    Enzyme.Duplicated(theta, grad))
    # central FD on 32 deterministic entries, rel err < 1e-6
    n = length(theta)
    # deterministic full-span index set: stride coprime with n gives distinct
    # entries; fall back to all indices when the space is small
    idxs = n <= 32 ? collect(1:n) :
           [1 + mod(k * 7, n) for k in 0:31]
    length(unique(idxs)) == length(idxs) ||
        error("gate5 FD index set not unique for n=$n")
    max_rel = 0.0
    worst = (index = 0, fd = 0.0, enzyme = 0.0, abs_err = 0.0, rel_err = 0.0)
    for idx in idxs
        # near-optimal central-difference step: h ~ cbrt(eps) * scale
        h = 6.0e-6 * max(1.0, abs(theta[idx]))
        tp = copy(theta); tm = copy(theta)
        tp[idx] += h; tm[idx] -= h
        fd = (g4_lw_chain_loss(tp, ctx) - g4_lw_chain_loss(tm, ctx)) / (2h)
        denom = max(abs(fd), abs(grad[idx]), 1e-300)
        rel = abs(fd - grad[idx]) / denom
        if rel > max_rel
            max_rel = rel
            worst = (index = idx, fd = fd, enzyme = grad[idx],
                     abs_err = abs(fd - grad[idx]), rel_err = rel)
        end
    end
    max_rel < 1e-6 ||
        push!(fails, "gate5 Enzyme vs FD max rel err $max_rel >= 1e-6")
    any(!iszero, grad) || push!(fails, "gate5 gradient identically zero")
    return fails, Dict{String, Any}(
        "self_loss" => l0, "perturbed_loss" => l1,
        "enzyme_fd_max_rel_err" => max_rel,
        "fd_entries_checked" => length(idxs),
        "worst_index" => worst.index,
        "worst_fd_value" => worst.fd,
        "worst_enzyme_value" => worst.enzyme,
        "worst_abs_err" => worst.abs_err,
        "worst_rel_err" => worst.rel_err,
        "theta_parameters" => n,
        "note" => "synthetic single-gas single-band LW chain; " *
                  "loss-input-to-coefficient chain gradient DEMONSTRATED on " *
                  "synthetic configuration; published-model full chain is " *
                  "later-stage work",
    )
end


# --- Gate 6 (Stage 3): prior term — analytic + gradient checks --------------------
function run_gate6()
    fails = String[]
    ng, np_, nt_ = 2, 3, 2
    n = np_ * nt_
    theta_p = zeros(ng, np_, nt_)
    theta = zeros(ng, np_, nt_)
    for g in 1:ng, i in 1:np_, j in 1:nt_
        theta[g, i, j] = 0.1 * g + 0.03 * i - 0.02 * j
    end
    # identity case: tcorr = pcorr = 0 => S = I => J = 0.5/bg^2 * sum(dtheta^2)
    S0 = g4_prior_shape_matrix(nt_, np_, 0.0, 0.0)
    J0 = g4_prior_term(theta, theta_p, inv(S0), 2.0)
    J0_want = 0.5 / 4.0 * sum(abs2, theta)
    approx_equal(J0, J0_want, 1e-12) ||
        push!(fails, "gate6 identity prior: $J0 vs $J0_want")
    # correlated case vs independent quadratic-form arithmetic in the test
    tc, pc, bg = 0.8, 0.8, 8.0
    S = [tc^abs(mod(a-1, nt_) - mod(b-1, nt_)) *
         pc^abs(div(a-1, nt_) - div(b-1, nt_)) for a in 1:n, b in 1:n]
    Jw = 0.0
    for g in 1:ng
        v = [theta[g, ip, it] - theta_p[g, ip, it] for ip in 1:np_ for it in 1:nt_]
        Jw += 0.5 / bg^2 * (v' * (S \ v))
    end
    Sinv = inv(g4_prior_shape_matrix(nt_, np_, tc, pc))
    J = g4_prior_term(theta, theta_p, Sinv, bg)
    approx_equal(J, Jw, 1e-10) ||
        push!(fails, "gate6 correlated prior: $J vs $Jw")
    # Enzyme gradient vs analytic (1/bg^2) * Sinv * v
    grad = zero(theta)
    Enzyme.autodiff(Enzyme.Reverse,
                    Enzyme.Const(t -> g4_prior_term(t, theta_p, Sinv, bg)),
                    Enzyme.Active, Enzyme.Duplicated(copy(theta), grad))
    max_rel = 0.0
    for g in 1:ng
        v = [theta[g, ip, it] for ip in 1:np_ for it in 1:nt_]
        ga = (1 / bg^2) .* (Sinv * v)
        k = 0
        for ip in 1:np_, it in 1:nt_
            k += 1
            denom = max(abs(ga[k]), abs(grad[g, ip, it]), 1e-300)
            max_rel = max(max_rel, abs(ga[k] - grad[g, ip, it]) / denom)
        end
    end
    max_rel < 1e-10 ||
        push!(fails, "gate6 Enzyme vs analytic prior gradient: $max_rel")
    # 3-D concentration-axis case (ccorr): tiny (2,2,2) LUT per g
    nc3, np3, nt3 = 2, 2, 2
    n3 = nc3 * np3 * nt3
    th3 = zeros(1, nc3, np3, nt3)
    for c in 1:nc3, i in 1:np3, j in 1:nt3
        th3[1, c, i, j] = 0.05 * c - 0.02 * i + 0.01 * j
    end
    tc3, pc3, cc3, bg3 = 0.8, 0.8, 0.8, 2.0
    S3t = [tc3^abs(mod(a-1, nt3) - mod(b-1, nt3)) *
           pc3^abs(mod(div(a-1, nt3), np3) - mod(div(b-1, nt3), np3)) *
           cc3^abs(div(a-1, nt3*np3) - div(b-1, nt3*np3))
           for a in 1:n3, b in 1:n3]
    v3 = [th3[1, ic, ip, it] for ic in 1:nc3 for ip in 1:np3 for it in 1:nt3]
    J3_want = 0.5 / bg3^2 * (v3' * (S3t \ v3))
    S3inv = inv(g4_prior_shape_matrix_3d(nt3, np3, nc3, tc3, pc3, cc3))
    J3 = g4_prior_term_conc(th3, zero(th3), S3inv, bg3)
    approx_equal(J3, J3_want, 1e-10) ||
        push!(fails, "gate6 ccorr prior: $J3 vs $J3_want")
    grad3 = zero(th3)
    Enzyme.autodiff(Enzyme.Reverse,
                    Enzyme.Const(t -> g4_prior_term_conc(t, zero(th3), S3inv, bg3)),
                    Enzyme.Active, Enzyme.Duplicated(copy(th3), grad3))
    ga3 = (1 / bg3^2) .* (S3inv * v3)
    max_rel3 = 0.0
    k3 = 0
    for ic in 1:nc3, ip in 1:np3, it in 1:nt3
        k3 += 1
        denom = max(abs(ga3[k3]), abs(grad3[1, ic, ip, it]), 1e-300)
        max_rel3 = max(max_rel3, abs(ga3[k3] - grad3[1, ic, ip, it]) / denom)
    end
    max_rel3 < 1e-10 ||
        push!(fails, "gate6 ccorr Enzyme vs analytic gradient: $max_rel3")
    return fails, Dict{String, Any}("prior_identity" => J0,
        "prior_correlated" => J, "enzyme_analytic_max_rel_err" => max_rel,
        "prior_ccorr_3d" => J3, "ccorr_enzyme_analytic_max_rel_err" => max_rel3)
end

# --- Gate 7 (Stage 3): negative-OD penalty — analytic + gradient + clamp ---------
function run_gate7()
    fails = String[]
    od = [0.5, -0.2, 0.0, -0.1, 1.3]
    w = 1.0e4
    pen = g4_negative_od_penalty(od, w)
    pen_want = w * (0.04 + 0.01)
    approx_equal(pen, pen_want, 1e-12) ||
        push!(fails, "gate7 penalty value: $pen vs $pen_want")
    clamped = g4_clamp_od(od)
    (clamped == [0.5, 0.0, 0.0, 0.0, 1.3]) ||
        push!(fails, "gate7 clamp wrong: $clamped")
    grad = zero(od)
    Enzyme.autodiff(Enzyme.Reverse,
                    Enzyme.Const(x -> g4_negative_od_penalty(x, w)),
                    Enzyme.Active, Enzyme.Duplicated(copy(od), grad))
    grad_want = [0.0, 2w * (-0.2), 0.0, 2w * (-0.1), 0.0]
    all(approx_equal(grad[i], grad_want[i], 1e-12) || (grad[i] == grad_want[i])
        for i in eachindex(od)) ||
        push!(fails, "gate7 penalty gradient: $grad vs $grad_want")
    return fails, Dict{String, Any}("penalty_value" => pen,
        "penalty_gradient" => grad)
end

function main()
    gates = Dict{String, String}()
    timings = Dict{String, Float64}()
    failures = String[]

    timings["gate1_seconds"] = @elapsed f1 = run_gate1()
    append!(failures, f1); gates["gate1_interpolation_nodes"] = isempty(f1) ? "passed" : "failed"
    timings["gate2_seconds"] = @elapsed f2 = run_gate2()
    append!(failures, f2); gates["gate2_lw_analytic"] = isempty(f2) ? "passed" : "failed"
    timings["gate3_seconds"] = @elapsed f3 = run_gate3()
    append!(failures, f3); gates["gate3_sw_analytic"] = isempty(f3) ? "passed" : "failed"
    local fp, record
    timings["gate4_published_load_seconds"] = @elapsed ((fp, record) = run_gate_published())
    append!(failures, fp); gates["gate4_published_table_load"] = isempty(fp) ? "passed" : "failed"
    local f5, chain_record
    timings["gate5_enzyme_chain_seconds"] = @elapsed ((f5, chain_record) = run_gate5())
    append!(failures, f5); gates["gate5_enzyme_chain_fd"] = isempty(f5) ? "passed" : "failed"
    local f6, prior_record
    timings["gate6_prior_seconds"] = @elapsed ((f6, prior_record) = run_gate6())
    append!(failures, f6); gates["gate6_prior_term"] = isempty(f6) ? "passed" : "failed"
    local f7, penalty_record
    timings["gate7_penalty_seconds"] = @elapsed ((f7, penalty_record) = run_gate7())
    append!(failures, f7); gates["gate7_negative_od_penalty"] = isempty(f7) ? "passed" : "failed"

    status = isempty(failures) ? "stage3_gates_passed" : "stage3_gates_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_forward_map_g0",
        "stage" => "stage3_objective_completion_plumbing",
        "chain_gate" => chain_record,
        "prior_gate" => prior_record,
        "penalty_gate" => penalty_record,
        "objective_scope" => "objective-completion plumbing; NOT real-data acceptance; no floor/recovery claims",
        "data_mode" => "synthetic_and_published_tables_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates,
        "failures" => failures,
        "timings_seconds" => timings,
        "maxrss_bytes" => Int(Sys.maxrss()),
        "published_table_load" => record,
        "provenance" => Dict(
            "branch" => branch, "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit; generated_from_head is the parent " *
                "commit at generation time",
            "checklist" => "Appendix B of gate4_p2_forward_map_design.md",
            "sw_heating_convention" => "downwelling_only_per_appendix_a",
            "top_edge_node_semantics" =>
                "top-axis nodes follow the upstream fractional-index clamp " *
                "(<= n-1.0001), verified against the analytically clamped " *
                "value, not the raw table node",
        ),
        "coefficient_gradient_status" =>
            "demonstrated_synthetic_single_gas_lw_chain_stage2",
        "disclaimer" => "no objective-value, floor, or recovery claims; synthetic " *
                        "shapes and published tables only; stages 1-3 cover " *
                        "interpolation, RT recurrences, the Enzyme chain " *
                        "gradient, and the prior/negative-OD " *
                        "objective-completion terms.",
    )

    mkpath(dirname(G0_RESULTS_JSON))
    open(G0_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(G0_RESULTS_MD, "w") do io
        println(io, "# Gate-4 forward map G0 (", result["stage"], ")\n")
        println(io, "Status: **$(status)**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nSW heating convention: downwelling-only divergence " *
                    "(design Appendix A, high-risk parity requirement).")
        println(io, "\nTop-edge interpolation nodes follow the upstream index " *
                    "clamp (fractional index <= n-1.0001) and are verified " *
                    "against the analytically clamped value.")
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (artifact generated from the working tree before " *
                    "its own commit), checklist " *
                    "Appendix B; published SW32 load: $(get(record, "status", "?")).")
        if !isempty(failures)
            println(io, "\n## Failures\n")
            for f in failures
                println(io, "- ", f)
            end
        end
    end

    println("gate4_forward_map_g0: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(failures) || foreach(f -> println("  FAIL: $f"), failures)
    println("Wrote $G0_RESULTS_JSON")
    println("Wrote $G0_RESULTS_MD")
    return status == "stage3_gates_passed" ? 0 : 1
end

exit(main())
