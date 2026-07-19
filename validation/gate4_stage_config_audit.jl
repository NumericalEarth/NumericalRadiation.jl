# Gate-4 stage/objective CONFIGURATION audit for G2/G3 (no-data unit).
#
# Sources the staged-training configuration from the PINNED ecCKD scripts and
# optimize_lut defaults -- never from memory: do_all_{lw,sw}.sh pass orders,
# optimize_lut_{lw,sw}.sh per-pass case blocks (GASLIST, TRAINING, EXTRA_ARGS/
# relative_to, INCODE, OUTCODE, SPECIFIC_OPTIONS), COMMON_OPTIONS lines
# (recording ALL assignments; bash last-wins), SW band_mapping and rgb path
# rewrites, and optimize_lut.cpp compiled defaults. Configuration audit only;
# no floor, objective-value, or recovery claim.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const ECCKD_SRC = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"

const SC_RESULTS_JSON = validation_results_path("gate4_stage_config_audit.json")
const SC_RESULTS_MD = validation_results_path("gate4_stage_config_audit.md")

const EXPECTED_LW_ORDER = ["relative-base", "relative-ch4", "relative-n2o",
                           "relative-cfc"]
const EXPECTED_SW_ORDER = ["relative-base", "relative-ch4", "relative-n2o"]

grepn(text, pat) = [(i, strip(l)) for (i, l) in enumerate(split(text, '\n'))
                    if occursin(pat, l)]

# capture a bash `case` block: from a line ending "<pass>)" to the next ";;",
# with comment lines stripped so commented-out assignments are never captured
function case_block(text, pass)
    lines = [occursin(r"^\s*#", l) ? "" : l for l in split(text, '\n')]
    i0 = findfirst(l -> occursin(Regex("^\\s*" * pass * "\\)\\s*\$"), l), lines)
    i0 === nothing && return nothing, 0, 0
    i1 = findnext(l -> occursin(r"^\s*;;\s*$", l), lines, i0)
    i1 === nothing && return nothing, 0, 0
    return join(lines[i0:i1], '\n'), i0, i1
end

# LAST active assignment wins (bash semantics); comment lines were already
# blanked in case_block, so every match here is active.
function extract(block, key)
    quoted = collect(eachmatch(Regex(key * "=\"([^\"]*)\"", "s"), block))
    bare = collect(eachmatch(Regex(key * "=([^\\s\"]+)"), block))
    best = nothing; best_off = -1
    for m in quoted
        m.offset > best_off && (best = String(m.captures[1]); best_off = m.offset)
    end
    for m in bare
        m.offset > best_off && (best = String(m.captures[1]); best_off = m.offset)
    end
    return best
end

function audit_band(text, passes, band)
    out = Dict{String, Any}()
    for pass in passes
        blk, i0, i1 = case_block(text, pass)
        blk === nothing && (out[pass] = Dict("error" => "case block not found");
                            continue)
        d = Dict{String, Any}("block_lines" => [i0, i1])
        for key in ("GASLIST", "TRAINING", "INCODE", "OUTCODE",
                    "SPECIFIC_OPTIONS", "EXTRA_ARGS")
            v = extract(blk, key)
            v !== nothing && (d[key] = replace(v, r"\s+" => " "))
        end
        m = match(r"relative_to=([^\s\"]+)", blk)
        m !== nothing && (d["relative_to"] = String(m.captures[1]))
        out[pass] = d
    end
    return out
end

function main()
    fails = String[]
    gates = Dict{String, String}()

    files = Dict(
        "do_all_lw" => read(joinpath(ECCKD_SRC, "test/do_all_lw.sh"), String),
        "do_all_sw" => read(joinpath(ECCKD_SRC, "test/do_all_sw.sh"), String),
        "opt_lw" => read(joinpath(ECCKD_SRC, "test/optimize_lut_lw.sh"), String),
        "opt_sw" => read(joinpath(ECCKD_SRC, "test/optimize_lut_sw.sh"), String),
        "opt_cpp" => read(joinpath(ECCKD_SRC, "src/ecckd/optimize_lut.cpp"), String),
    )

    # pass orders from do_all scripts (the OPT_MODES/loop line)
    function pass_order(text)
        for (_, l) in grepn(text, "relative-base")
            toks = [String(m.match) for m in eachmatch(r"relative-[a-z0-9]+", l)]
            length(toks) >= 3 && return toks
        end
        return String[]
    end
    lw_order = pass_order(files["do_all_lw"])
    sw_order = pass_order(files["do_all_sw"])
    gates["lw_pass_order"] = lw_order == EXPECTED_LW_ORDER ? "passed" : "failed"
    gates["sw_pass_order"] = sw_order == EXPECTED_SW_ORDER ? "passed" : "failed"
    lw_order == EXPECTED_LW_ORDER ||
        push!(fails, "LW pass order $(lw_order) != $(EXPECTED_LW_ORDER)")
    sw_order == EXPECTED_SW_ORDER ||
        push!(fails, "SW pass order $(sw_order) != $(EXPECTED_SW_ORDER)")

    # COMMON_OPTIONS: record ALL assignments with line numbers (last wins)
    common = Dict(
        "lw" => grepn(files["opt_lw"], "COMMON_OPTIONS="),
        "sw" => grepn(files["opt_sw"], "COMMON_OPTIONS="),
    )

    lw_cfg = audit_band(files["opt_lw"], EXPECTED_LW_ORDER, "lw")
    sw_cfg = audit_band(files["opt_sw"], EXPECTED_SW_ORDER, "sw")

    # explicitness gate: every pass has GASLIST + INCODE + OUTCODE
    ok_explicit = true
    for (band, cfg) in (("lw", lw_cfg), ("sw", sw_cfg))
        for (pass, d) in cfg
            for key in ("GASLIST", "INCODE", "OUTCODE")
                haskey(d, key) ||
                    (ok_explicit = false;
                     push!(fails, "$band $pass missing $key"))
            end
        end
    end
    gates["per_pass_options_explicit"] = ok_explicit ? "passed" : "failed"

    # minor-gas passes record relative_to (rel-415)
    ok_rel = true
    for (band, cfg, minors) in (("lw", lw_cfg, ["relative-ch4", "relative-n2o",
                                                "relative-cfc"]),
                                ("sw", sw_cfg, ["relative-ch4", "relative-n2o"]))
        for pass in minors
            rt = get(cfg[pass], "relative_to", nothing)
            (rt !== nothing && occursin("rel-415", rt)) ||
                (ok_rel = false;
                 push!(fails, "$band $pass relative_to missing/wrong: $rt"))
        end
    end
    gates["relative_to_recorded"] = ok_rel ? "passed" : "failed"

    # SW relative-base starts from scaled-ckd-definition
    sw_base_in = get(sw_cfg["relative-base"], "INCODE", "")
    gates["sw_base_from_scaled"] = occursin("scaled-ckd-definition", sw_base_in) ?
        "passed" : "failed"
    occursin("scaled-ckd-definition", sw_base_in) ||
        push!(fails, "SW relative-base INCODE=$sw_base_in not scaled-ckd-definition")

    # LW relative-cfc includes cfc11 + cfc12
    cfc_gas = get(lw_cfg["relative-cfc"], "GASLIST", "")
    ok_cfc = occursin("cfc11", cfc_gas) && occursin("cfc12", cfc_gas)
    gates["lw_cfc_gaslist"] = ok_cfc ? "passed" : "failed"
    ok_cfc || push!(fails, "LW relative-cfc GASLIST=$cfc_gas lacks cfc11+cfc12")

    # overrides preserved: negative_od_penalty=1.0e1 (LW ch4);
    # remove_min_max on final passes (LW cfc, SW n2o)
    lw_ch4_opts = get(lw_cfg["relative-ch4"], "SPECIFIC_OPTIONS", "")
    ok_pen = occursin("negative_od_penalty=1.0e1", lw_ch4_opts)
    gates["lw_ch4_negative_od_override"] = ok_pen ? "passed" : "failed"
    ok_pen || push!(fails, "LW ch4 SPECIFIC_OPTIONS lacks negative_od_penalty=1.0e1: $lw_ch4_opts")
    rmm_lw = occursin("remove_min_max",
                      get(lw_cfg["relative-cfc"], "SPECIFIC_OPTIONS", "") *
                      get(lw_cfg["relative-cfc"], "EXTRA_ARGS", ""))
    rmm_sw = occursin("remove_min_max",
                      get(sw_cfg["relative-n2o"], "SPECIFIC_OPTIONS", "") *
                      get(sw_cfg["relative-n2o"], "EXTRA_ARGS", ""))
    gates["remove_min_max_final_passes"] = rmm_lw && rmm_sw ? "passed" : "failed"
    (rmm_lw && rmm_sw) ||
        push!(fails, "remove_min_max missing: lw_cfc=$rmm_lw sw_n2o=$rmm_sw")

    # SW script bounded_optimization=0: a DEAD KEY (the code reads
    # "bounded_minimization"), flagged separately in merged options so nobody
    # believes bounds were disabled in the SW climate passes.
    dead_key = grepn(files["opt_sw"], "bounded_optimization")
    gates["sw_bounded_optimization_dead_key_flagged"] =
        !isempty(dead_key) ? "passed" : "failed"
    isempty(dead_key) &&
        push!(fails, "expected SW COMMON_OPTIONS bounded_optimization=0 line not found")

    # SW rgb band_mapping + rgb flux-path rewrite recorded
    bm = grepn(files["opt_sw"], "band_mapping")
    rgb = grepn(files["opt_sw"], "rgb")
    ok_bm = any(occursin("0 0 0 0 1 2 3 4 4", l) for (_, l) in bm)
    gates["sw_rgb_band_mapping"] = ok_bm ? "passed" : "failed"
    ok_bm || push!(fails, "SW rgb band_mapping '0 0 0 0 1 2 3 4 4' not found")
    gates["sw_rgb_rewrite_recorded"] = !isempty(rgb) ? "passed" : "failed"
    isempty(rgb) && push!(fails, "no rgb path/rewrite lines found in optimize_lut_sw.sh")

    # optimize_lut.cpp compiled defaults (verbatim evidence lines)
    cpp_defaults = Dict{String, Any}()
    ok_cpp = true
    for (key, pat) in (("flux_weight", r"flux_weight\s*=\s*0\.02"),
                       ("flux_profile_weight", r"flux_profile_weight\s*=\s*0\.0"),
                       ("broadband_weight", r"broadband_weight\s*=\s*0\.5"),
                       ("spectral_boundary_weight", r"spectral_boundary_weight\s*=\s*0"),
                       ("prior_error", r"prior_error\s*=\s*-1"),
                       ("convergence_criterion", r"convergence_criterion\s*=\s*0\.02"),
                       ("max_iterations", r"max_iterations\s*=\s*3000"),
                       ("negative_od_penalty", r"negative_od_penalty\s*=\s*1\.0?e\+?4"),
                       ("bounded_minimization_default_true",
                        r"is_bounded\s*=\s*true"),
                       ("bounded_minimization_config_key",
                        r"config\.read\(is_bounded,\s*\"bounded_minimization\""))
        hits = [(i, strip(l)) for (i, l) in
                enumerate(split(files["opt_cpp"], '\n')) if occursin(pat, l)]
        cpp_defaults[key] = hits
        isempty(hits) && (ok_cpp = false;
                          push!(fails, "cpp default not found: $key"))
    end
    gates["optimize_lut_cpp_defaults"] = ok_cpp ? "passed" : "failed"

    status = isempty(fails) ? "stage_config_audit_passed" :
                              "stage_config_audit_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_stage_config_audit",
        "data_mode" => "pinned_source_configuration_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "lw_pass_order" => lw_order, "sw_pass_order" => sw_order,
        "lw_passes" => lw_cfg, "sw_passes" => sw_cfg,
        "common_options_all_assignments_last_wins" => common,
        "optimize_lut_cpp_defaults" => cpp_defaults,
        "merge_precedence" => "SPECIFIC_OPTIONS/EXTRA_ARGS > COMMON_OPTIONS " *
                              "(last assignment wins) > optimize_lut.cpp " *
                              "compiled defaults",
        "bounded_semantics" => Dict(
            "compiled_default" => "Real is_bounded = true (optimize_lut.cpp:148)",
            "config_key" => "bounded_minimization (optimize_lut.cpp:149)",
            "sw_script_dead_key" => "COMMON_OPTIONS carries " *
                "bounded_optimization=0 -- a key the code never reads; " *
                "bounded minimization therefore stays ON in SW passes",
            "dead_key_lines" => dead_key),
        "provenance" => Dict("branch" => branch, "generated_from_head" => head,
            "pinned_source" => ECCKD_SRC,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "configuration audit of the pinned upstream staged-" *
                        "training scripts only; no floor, objective-value, " *
                        "or recovery claim.",
    )
    mkpath(dirname(SC_RESULTS_JSON))
    open(SC_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(SC_RESULTS_MD, "w") do io
        println(io, "# Gate-4 stage/objective configuration audit\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nLW passes: ", join(lw_order, " -> "))
        println(io, "\nSW passes: ", join(sw_order, " -> "))
        for (band, cfg, order) in (("LW", lw_cfg, lw_order),
                                   ("SW", sw_cfg, sw_order))
            println(io, "\n## $band per-pass configuration\n")
            for pass in order
                d = cfg[pass]
                println(io, "### $pass (lines $(get(d, "block_lines", "?")))")
                for key in ("GASLIST", "INCODE", "OUTCODE", "relative_to",
                            "SPECIFIC_OPTIONS")
                    haskey(d, key) && println(io, "- $key: `$(d[key])`")
                end
            end
        end
        println(io, "\nMerge precedence: ", result["merge_precedence"])
        println(io, "\nProvenance: pinned source `$(ECCKD_SRC)`; branch " *
                    "`$branch`, generated_from_head `$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_stage_config_audit: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "stage_config_audit_passed" ? 0 : 1
end

exit(main())
