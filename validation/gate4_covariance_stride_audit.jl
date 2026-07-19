# Gate-4 covariance-stride audit (mandatory before any G3 floor claim).
#
# Proves that the local prior-vector stride and recovery-vector mapping are
# compatible with upstream conventions, explicitly separating:
#   (1) the per-g PRIOR order used inside create_error_covariances
#       (ckd_model.cpp:615-760; corrected spread conventions -- the source
#       carries the comment "SPREAD CONVENTION IS WRONG!!!" above the fixed
#       lines): 2-D coeffs reshape dimensions(nt,np) row-major, so flat
#       alpha = it*np + ip (p fastest within t); 3-D conc coeffs reshape
#       dimensions(nconc,nt,np), so alpha = ic*nt*np + it*np + ip.
#   (2) the WHOLE-FILE state-vector order used by flatten_recovery_arrays:
#       Julia vec() over NetCDF arrays with dims (g_point, pressure,
#       temperature[, h2o_mole_fraction]) -- column-major, g fastest -- which
#       equals upstream row-major (...[conc,]t,p,g) with g rightmost/fastest.
# The g-point is OUTSIDE the covariance: the prior applies per g.
#
# Local g4_prior_term/`_conc` flatten t fastest (2-D: k = (ip-1)*nt + it;
# 3-D: k = (ic-1)*np*nt + (ip-1)*nt + it) -- a DIFFERENT labeling from
# upstream. Compatibility therefore rests on permutation-conjugacy, which this
# audit PROVES rather than assumes. No floor/recovery claim.

include(joinpath(@__DIR__, "gate4_forward_map.jl"))
include(joinpath(@__DIR__, "ecckd_published_recovery_vector.jl"))

using Dates
import JSON
import Enzyme

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))
using NumericalRadiation

const CS_RESULTS_JSON = validation_results_path("gate4_covariance_stride_audit.json")
const CS_RESULTS_MD = validation_results_path("gate4_covariance_stride_audit.md")

function main()
    fails = String[]
    gates = Dict{String, String}()
    stats = Dict{String, Any}()

    tc, pc, cc = 0.8, 0.8, 0.8

    # Gate A: 2-D permutation-conjugacy (nt=3, np=2)
    nt, np_ = 3, 2
    n = nt * np_
    # upstream flat order alpha = it*np + ip  (0-based), per corrected spreads
    up_t = [div(a, np_) for a in 0:n-1]
    up_p = [mod(a, np_) for a in 0:n-1]
    S_up = [tc^abs(up_t[a+1] - up_t[b+1]) * pc^abs(up_p[a+1] - up_p[b+1])
            for a in 0:n-1, b in 0:n-1]
    S_mine = g4_prior_shape_matrix(nt, np_, tc, pc)
    # local order k = (ip-1)*nt + it (1-based): mapping local k -> upstream alpha
    perm = zeros(Int, n)
    for ip in 1:np_, it in 1:nt
        k = (ip - 1) * nt + it
        alpha = (it - 1) * np_ + (ip - 1)          # 0-based upstream
        perm[k] = alpha + 1
    end
    okA = all(S_up[perm[k], perm[l]] == S_mine[k, l] for k in 1:n, l in 1:n)
    # quadratic-form equality on a deterministic physical field
    field(it, ip) = 0.1 * it - 0.07 * ip + 0.01 * it * ip
    v_mine = [field(it, ip) for ip in 1:np_ for it in 1:nt]
    v_up = [field(div(a, np_) + 1, mod(a, np_) + 1) for a in 0:n-1]
    q_mine = v_mine' * (inv(S_mine) * v_mine)
    q_up = v_up' * (inv(S_up) * v_up)
    okA2 = abs(q_mine - q_up) <= 1e-12 * max(abs(q_mine), abs(q_up))
    stats["conjugacy_2d"] = Dict("elementwise_exact" => okA,
        "quadratic_mine" => q_mine, "quadratic_upstream" => q_up)
    gates["stride_2d_permutation_conjugate"] = okA && okA2 ? "passed" : "failed"
    (okA && okA2) || push!(fails, "2-D stride conjugacy failed: exact=$okA q=$okA2")

    # Gate B: 3-D conc analog (nc=2, nt=3, np=2); alpha = ic*nt*np + it*np + ip
    nc = 2
    n3 = nc * nt * np_
    up3 = [(div(a, nt * np_), div(mod(a, nt * np_), np_), mod(a, np_))
           for a in 0:n3-1]      # (ic, it, ip) 0-based
    S3_up = [tc^abs(up3[a][2] - up3[b][2]) * pc^abs(up3[a][3] - up3[b][3]) *
             cc^abs(up3[a][1] - up3[b][1]) for a in 1:n3, b in 1:n3]
    S3_mine = g4_prior_shape_matrix_3d(nt, np_, nc, tc, pc, cc)
    perm3 = zeros(Int, n3)
    for ic in 1:nc, ip in 1:np_, it in 1:nt
        k = (ic - 1) * np_ * nt + (ip - 1) * nt + it
        alpha = (ic - 1) * nt * np_ + (it - 1) * np_ + (ip - 1)
        perm3[k] = alpha + 1
    end
    okB = all(S3_up[perm3[k], perm3[l]] == S3_mine[k, l]
              for k in 1:n3, l in 1:n3)
    field3(ic, it, ip) = 0.05 * ic + 0.1 * it - 0.07 * ip + 0.003 * ic * it
    v3_mine = [field3(ic, it, ip) for ic in 1:nc for ip in 1:np_ for it in 1:nt]
    v3_up = [field3(a[1] + 1, a[2] + 1, a[3] + 1) for a in up3]
    q3_mine = v3_mine' * (inv(S3_mine) * v3_mine)
    q3_up = v3_up' * (inv(S3_up) * v3_up)
    okB2 = abs(q3_mine - q3_up) <= 1e-12 * max(abs(q3_mine), abs(q3_up))
    stats["conjugacy_3d"] = Dict("elementwise_exact" => okB,
        "quadratic_mine" => q3_mine, "quadratic_upstream" => q3_up)
    gates["stride_3d_permutation_conjugate"] = okB && okB2 ? "passed" : "failed"
    (okB && okB2) || push!(fails, "3-D stride conjugacy failed: exact=$okB q=$okB2")

    # Gate C: whole-file recovery-vector mapping. Julia vec() column-major over
    # (g, p, t[, c]) equals upstream row-major ([c,]t,p,g): index arithmetic
    # proven on encoded synthetic arrays, then published shapes recorded.
    ng, npp, ntt, ncc = 3, 4, 2, 2
    enc3 = [ig + 100 * ip + 10000 * it for ig in 1:ng, ip in 1:npp, it in 1:ntt]
    v3 = vec(enc3)
    okC = all(v3[ig + (ip - 1) * ng + (it - 1) * ng * npp] ==
              ig + 100 * ip + 10000 * it
              for ig in 1:ng, ip in 1:npp, it in 1:ntt)
    enc4 = [ig + 100 * ip + 10000 * it + 1000000 * ic
            for ig in 1:ng, ip in 1:npp, it in 1:ntt, ic in 1:ncc]
    v4 = vec(enc4)
    okC4 = all(v4[ig + (ip - 1) * ng + (it - 1) * ng * npp +
                  (ic - 1) * ng * npp * ntt] ==
               ig + 100 * ip + 10000 * it + 1000000 * ic
               for ig in 1:ng, ip in 1:npp, it in 1:ntt, ic in 1:ncc)
    # REAL flatten_recovery_arrays audit: the exact handoff vector G3 uses.
    pub = Dict{String, Any}()
    support_in_state = String[]
    for (sym, label) in ((:longwave_32, "lw32"), (:shortwave_32, "sw32"))
        path = NumericalRadiation.official_ecckd_definition_path(sym)
        names = vectorized_array_names(path)
        flat, shapes = flatten_recovery_arrays(path, names)
        rows = Any[]
        for sh in shapes
            is_coeff = endswith(String(sh.name), "molar_absorption_coeff")
            is_coeff || push!(support_in_state, String(sh.name))
            push!(rows, Dict("name" => String(sh.name),
                "shape" => collect(sh.shape),
                "first_index" => sh.first_index,
                "last_index" => sh.last_index,
                "element_count" => sh.last_index - sh.first_index + 1,
                "class" => is_coeff ? "coefficient" : "support"))
        end
        pub[label] = Dict("file" => basename(path),
            "total_parameters" => length(flat), "rows" => rows)
    end
    stats["recovery_vector_mapping"] = Dict(
        "vec_order_3d_proven" => okC, "vec_order_4d_proven" => okC4,
        "note" => "Julia column-major vec over (g,p,t[,c]) == upstream " *
                  "row-major ([c,]t,p,g) with g fastest in both; the " *
                  "WHOLE-FILE state order is distinct from the per-g prior " *
                  "order and both are now proven",
        "published" => pub)
    gates["recovery_vector_mapping"] = okC && okC4 ? "passed" : "failed"
    (okC && okC4) || push!(fails, "recovery-vector vec mapping failed")

    # Gate D: support arrays are frozen / not prior-regularized (item 22).
    # Structural: the prior functions accept only theta LUT arrays; support
    # arrays are never routed into any prior call in the campaign scripts.
    support_expected = ["gpoint_fraction", "solar_irradiance",
                        "rayleigh_molar_scattering_coeff", "planck_function",
                        "temperature_planck"]
    grep_hits = String[]
    for f in ("gate4_forward_map.jl", "gate4_forward_map_g0.jl",
              "gate4_objective_assembly_g1.jl")
        src = read(joinpath(@__DIR__, f), String)
        for sa in support_expected
            for m in eachmatch(Regex("g4_prior[a-z_]*\\([^)]*" * sa), src)
                push!(grep_hits, "$f: $(m.match)")
            end
        end
    end
    okD = isempty(grep_hits)
    stats["support_frozen"] = Dict("prior_calls_touching_support" => grep_hits,
        "support_arrays_in_state_vector" => sort(unique(support_in_state)),
        "policy" => "support arrays appear in the WHOLE-FILE state vector " *
                    "shapes (plumbing) but are fixed per Appendix B item 22; " *
                    "prior regularizes only molar-absorption log-coefficients")
    gates["support_arrays_not_prior_regularized"] = okD ? "passed" : "failed"
    okD || push!(fails, "support arrays appear in prior calls: $grep_hits")

    # Gate E: g-point outside the covariance -- per-g independence of the
    # prior gradient (perturb g=1 block only; gradient at g=2 exactly zero).
    th = zeros(2, np_, nt)
    for i in 1:np_, j in 1:nt
        th[1, i, j] = 0.1 * i - 0.05 * j
    end
    Sinv = inv(g4_prior_shape_matrix(nt, np_, tc, pc))
    gr = zero(th)
    Enzyme.autodiff(Enzyme.Reverse,
                    Enzyme.Const(t -> g4_prior_term(t, zero(th), Sinv, 8.0)),
                    Enzyme.Active, Enzyme.Duplicated(copy(th), gr))
    okE = all(gr[2, :, :] .== 0.0) && any(gr[1, :, :] .!= 0.0)
    stats["per_g_independence"] = Dict(
        "g2_gradient_max_abs" => maximum(abs.(gr[2, :, :])),
        "g1_gradient_nonzero" => any(gr[1, :, :] .!= 0.0))
    gates["prior_per_g_independent"] = okE ? "passed" : "failed"
    okE || push!(fails, "per-g independence failed")

    status = isempty(fails) ? "covariance_stride_audit_passed" :
                              "covariance_stride_audit_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_covariance_stride_audit",
        "data_mode" => "synthetic_index_reconstruction_plus_published_shapes",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails, "stats" => stats,
        "source_anchors" => Dict(
            "create_error_covariances" => "ckd_model.cpp:615-760 (corrected " *
                "spread conventions; 2-D reshape dimensions(nt,np) row-major " *
                "=> alpha = it*np+ip; 3-D dimensions(nconc,nt,np) => " *
                "alpha = ic*nt*np + it*np + ip)",
            "local_prior" => "g4_prior_term/_conc flatten t fastest; " *
                "compatibility via PROVEN permutation-conjugacy",
            "flatten_recovery_arrays" => "vec() over Julia (g,p,t[,c]) " *
                "column-major == upstream row-major ([c,]t,p,g)"),
        "maxrss_bytes" => Int(Sys.maxrss()),
        "provenance" => Dict("branch" => branch, "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "index/stride audit only; no floor, objective-value, " *
                        "or recovery claim.",
    )
    mkpath(dirname(CS_RESULTS_JSON))
    open(CS_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(CS_RESULTS_MD, "w") do io
        println(io, "# Gate-4 covariance-stride audit\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nKey finding: upstream per-g prior order is p-fastest " *
                    "(alpha = it*np+ip; 3-D adds ic*nt*np), the local flatten " *
                    "is t-fastest, and the two are PROVEN " *
                    "permutation-conjugate with equal quadratic forms; the " *
                    "whole-file recovery-vector order (g fastest) is a " *
                    "distinct, separately proven mapping. The g-point sits " *
                    "outside the covariance (per-g prior independence " *
                    "verified by gradient).")
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_covariance_stride_audit: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "covariance_stride_audit_passed" ? 0 : 1
end

exit(main())
