# Gate-4 G2/G3 runner SCAFFOLD (dry-run manifest) -- HISTORICAL/SUPERSEDED.
#
# SUPERSEDED (monitor-directed marking, 2026-08-12): the execution path
# this scaffold anticipated landed as a DIFFERENT gated chain -- the
# scoped input preflight (gate4_g3_scoped_input_preflight.jl) + G3
# executor checkpoint (gate4_g3_executor_checkpoint.jl, token-gated
# sbatch generation with human submission) + the G2a-G2d training-flux
# chain. The execute_g2_g3 entrypoint below is RETIRED: intentionally
# unimplemented and superseded; its broad ckdmip_training_data_preflight
# gating was superseded by the SCOPED preflight (the broad preflight
# would go red under a Path-D cleanup by design). The unit is RETAINED as read-only
# manifest evidence: its pass-chain/audit gates (OUTCODE continuity, no
# 4angle, init provenance, rel-415 relative_to, support-array exclusion)
# remain valid historical checks of the pinned upstream scripts.
#
# Original contract: builds the exact ordered LW/SW pass manifest sourced
# from committed audit artifacts (stage-config audit, covariance-stride
# audit) and the pinned create/optimize scripts -- never memory. REFUSES
# to compute any objective or floor value; enumerates configuration, init
# files, OUTCODE chains, relative_to files, trainable sets, band
# mappings, and expected derived-data paths with present/missing status.
#
# No floor, objective-value, or recovery claim.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const ECCKD_SRC = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"
const CKDMIP_ROOT = get(ENV, "RH_CKDMIP_DATA_PATH",
                        "/shared/home/greg/data/ckdmip")

const RS_RESULTS_JSON = validation_results_path("gate4_g2_g3_runner_scaffold.json")
const RS_RESULTS_MD = validation_results_path("gate4_g2_g3_runner_scaffold.md")

const CO2_LEVELS = ["180", "280", "415", "560", "1120", "2240"]

# HISTORICAL entrypoint, intentionally unimplemented and now SUPERSEDED:
# the real execution path landed as the scoped-preflight + executor-
# checkpoint chain (token g3_recovery_go; submission is a reviewed human
# sbatch step). This function refuses on EVERY path, including the old
# authorization token.
function execute_g2_g3(manifest; authorize::Symbol = :refused)
    authorize === :real_data_preflight_green ||
        error("execute_g2_g3 refused: this is a dry-run scaffold and is " *
              "SUPERSEDED by the gate4_g3_scoped_input_preflight + " *
              "gate4_g3_executor_checkpoint chain.")
    error("execute_g2_g3 SUPERSEDED: even with the historical " *
          "authorization token, no execution happens here. The G3 " *
          "executor landed as gate4_g3_executor_checkpoint.jl " *
          "(token-gated sbatch generation, human submission); this " *
          "scaffold entrypoint is retired, intentionally unimplemented, " *
          "and superseded.")
end

function main()
    fails = String[]
    gates = Dict{String, String}()

    cfg = JSON.parsefile(validation_results_path("gate4_stage_config_audit.json"))
    stride = JSON.parsefile(validation_results_path("gate4_covariance_stride_audit.json"))
    cfg["status"] == "stage_config_audit_passed" ||
        push!(fails, "stage-config audit not green: $(cfg["status"])")
    stride["status"] == "covariance_stride_audit_passed" ||
        push!(fails, "covariance-stride audit not green: $(stride["status"])")

    # init CKD filename templates verbatim from the pinned create scripts
    create_lw = read(joinpath(ECCKD_SRC, "test/create_lut_lw.sh"), String)
    create_sw = read(joinpath(ECCKD_SRC, "test/create_lut_sw.sh"), String)
    scale_sw = read(joinpath(ECCKD_SRC, "test/scale_lut_sw.sh"), String)
    init_templates = Dict(
        "lw_raw" => [strip(l) for l in split(create_lw, '\n')
                     if occursin("raw-ckd-definition", l) && occursin("OUTPUT", l)],
        "sw_raw" => [strip(l) for l in split(create_sw, '\n')
                     if occursin("raw-ckd-definition", l) && occursin("OUTPUT", l)],
        "sw_scaled" => [strip(l) for l in split(scale_sw, '\n')
                        if occursin("scaled-ckd-definition", l)][1:min(4, end)],
    )

    # SW rgb rewrite lines (verbatim) from optimize_lut_sw.sh
    opt_sw = read(joinpath(ECCKD_SRC, "test/optimize_lut_sw.sh"), String)
    rewrites = [(i, strip(l)) for (i, l) in enumerate(split(opt_sw, '\n'))
                if occursin("sw_fluxes", l) &&
                   (occursin("//", l) || occursin("-rgb", l) ||
                    occursin("BANDSTRUCT", l))]

    # ordered pass manifest with merged options
    support_arrays = Vector{String}(
        stride["stats"]["support_frozen"]["support_arrays_in_state_vector"])
    manifest = Dict{String, Any}()
    for (band, order_key, passes_key) in (("lw", "lw_pass_order", "lw_passes"),
                                          ("sw", "sw_pass_order", "sw_passes"))
        order = Vector{String}(cfg[order_key])
        entries = Any[]
        prev_out = band == "lw" ? "raw-ckd-definition" : "scaled-ckd-definition"
        for pass in order
            d = cfg[passes_key][pass]
            trainable = split(get(d, "GASLIST", ""))
            training = split(get(d, "TRAINING", ""))
            rel = get(d, "relative_to", nothing)
            # SW rgb rewrite: upstream rewrites flux dirs per band structure;
            # record the post-rewrite relative_to token
            rel_after = rel === nothing ? nothing :
                (band == "sw" && !isempty(rewrites) ?
                 replace(rel, "sw_fluxes" => "sw_fluxes-rgb") : rel)
            push!(entries, Dict(
                "pass" => pass,
                "incode" => get(d, "INCODE", missing),
                "outcode" => get(d, "OUTCODE", missing),
                "expected_incode_from_chain" => prev_out,
                "trainable_gases" => trainable,
                "trainable_arrays" => [g * "_molar_absorption_coeff"
                                       for g in trainable],
                "training_files" => training,
                "relative_to" => rel,
                "relative_to_after_rgb_rewrite" => rel_after,
                "specific_options" => get(d, "SPECIFIC_OPTIONS", ""),
            ))
            prev_out = get(d, "OUTCODE", prev_out)
        end
        manifest[band] = entries
    end
    manifest["sw_band_mapping"] = "0 0 0 0 1 2 3 4 4"
    manifest["sw_rgb_rewrite_lines"] = rewrites
    manifest["init_templates"] = init_templates
    manifest["merge_precedence"] = cfg["merge_precedence"]
    manifest["cpp_defaults"] = cfg["optimize_lut_cpp_defaults"]
    manifest["common_options"] = cfg["common_options_all_assignments_last_wins"]

    # Gate: OUTCODE chain continuity (each pass consumes previous OUTCODE)
    ok_chain = true
    for band in ("lw", "sw")
        for e in manifest[band]
            e["incode"] == e["expected_incode_from_chain"] ||
                (ok_chain = false;
                 push!(fails, "$band $(e["pass"]): INCODE $(e["incode"]) != " *
                              "chain $(e["expected_incode_from_chain"])"))
        end
    end
    gates["outcode_chain_continuous"] = ok_chain ? "passed" : "failed"

    # Gate: no 4angle products anywhere
    ok_4a = true
    for band in ("lw", "sw"), e in manifest[band]
        for f in e["training_files"]
            occursin("4angle", f) && (ok_4a = false;
                push!(fails, "4angle product in $band $(e["pass"]): $f"))
        end
        rel = e["relative_to"]
        rel !== nothing && occursin("4angle", rel) && (ok_4a = false;
            push!(fails, "4angle relative_to in $band $(e["pass"])"))
    end
    gates["no_external_sw_4angle_products"] = ok_4a ? "passed" : "failed"

    # Gates: init provenance
    gates["sw_base_init_scaled_ckd"] =
        manifest["sw"][1]["incode"] == "scaled-ckd-definition" ? "passed" : "failed"
    manifest["sw"][1]["incode"] == "scaled-ckd-definition" ||
        push!(fails, "SW base init not scaled-ckd-definition")
    gates["lw_base_init_raw_ckd"] =
        manifest["lw"][1]["incode"] == "raw-ckd-definition" &&
        !isempty(init_templates["lw_raw"]) ? "passed" : "failed"
    (manifest["lw"][1]["incode"] == "raw-ckd-definition" &&
     !isempty(init_templates["lw_raw"])) ||
        push!(fails, "LW base init not raw-ckd-definition from create_lut_lw")

    # Gate: minor passes rel-415 relative_to (post-rewrite for SW)
    ok_rel = true
    for band in ("lw", "sw")
        for e in manifest[band][2:end]
            rel = e["relative_to_after_rgb_rewrite"]
            (rel !== nothing && occursin("rel-415", rel)) ||
                (ok_rel = false;
                 push!(fails, "$band $(e["pass"]) relative_to (post-rewrite) " *
                              "missing rel-415: $rel"))
        end
    end
    gates["minor_pass_relative_to_rel415"] = ok_rel ? "passed" : "failed"

    # Gate: support arrays excluded from every trainable set
    ok_sup = true
    for band in ("lw", "sw"), e in manifest[band]
        bad = intersect(Set(e["trainable_arrays"]), Set(support_arrays))
        isempty(bad) || (ok_sup = false;
            push!(fails, "support arrays trainable in $band $(e["pass"]): $bad"))
    end
    gates["support_excluded_from_trainable"] = ok_sup ? "passed" : "failed"

    # Derived-product enumeration with present/missing status
    expected = Any[]
    for co2 in CO2_LEVELS, kind in ("5gas", "rel")
        push!(expected, "evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_" *
                        "$(kind)-$(co2).h5")
    end
    for co2 in CO2_LEVELS
        push!(expected, "evaluation1/sw_fluxes/ckdmip_evaluation1_sw_fluxes_" *
                        "rel-$(co2).h5")
    end
    derived = [Dict("path" => p,
                    "present" => isfile(joinpath(CKDMIP_ROOT, p)))
               for p in expected]
    n_present = count(d -> d["present"], derived)
    manifest["derived_products"] = derived
    gates["derived_products_enumerated"] =
        length(derived) == 18 ? "passed" : "failed"
    length(derived) == 18 || push!(fails, "expected 18 derived products")

    # "ready" here is HISTORICAL manifest coherence + 4078-era derived-data
    # presence, NOT execution readiness (execution authority moved to the
    # scoped-preflight + executor-checkpoint chain). The prefix
    # "runner_scaffold_ready" is preserved for the init-generation-manifest
    # consumer (gate4_init_generation_manifest.jl).
    data_ready = n_present == length(derived)
    status = !isempty(fails) ? "runner_scaffold_failed" :
             data_ready ?
             "runner_scaffold_ready_historical_superseded" :
             "runner_scaffold_ready_historical_superseded_waiting_for_data"

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_g2_g3_runner_scaffold",
        "data_mode" => "dry_run_manifest_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "manifest" => manifest,
        "derived_present" => n_present,
        "derived_expected" => length(derived),
        "superseded_by" => "gate4_g3_scoped_input_preflight.jl + " *
            "gate4_g3_executor_checkpoint.jl (token g3_recovery_go, " *
            "human sbatch submission) + the G2a-G2d training-flux chain; " *
            "the previously advertised execute_g2_g3 future command is " *
            "WITHDRAWN -- that entrypoint is retired (intentionally " *
            "unimplemented, refuses on every path) and the broad " *
            "ckdmip_training_data_preflight gating was replaced by " *
            "the scoped preflight",
        "historical_note" => "retained as read-only manifest evidence; " *
            "pass-chain/audit gates remain valid checks of the pinned " *
            "upstream scripts; 'ready' statuses assert manifest coherence " *
            "+ 4078-era derived-data presence, never execution readiness",
        "dry_run_refusal" => "execute_g2_g3 errors on EVERY path " *
            "(superseded); the scaffold never computes objective or " *
            "floor values",
        "provenance" => Dict("branch" => branch, "generated_from_head" => head,
            "sources" => ["gate4_stage_config_audit.json",
                          "gate4_covariance_stride_audit.json",
                          "pinned create_lut_{lw,sw}.sh / scale_lut_sw.sh / " *
                          "optimize_lut_sw.sh at $ECCKD_SRC"],
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "HISTORICAL/SUPERSEDED dry-run manifest; no floor, " *
                        "objective-value, or recovery claim; execution " *
                        "refused on every path -- authority moved to the " *
                        "scoped-preflight + executor-checkpoint chain.",
    )
    mkpath(dirname(RS_RESULTS_JSON))
    open(RS_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(RS_RESULTS_MD, "w") do io
        println(io, "# Gate-4 G2/G3 runner scaffold (dry-run manifest) — " *
                    "HISTORICAL/SUPERSEDED\n")
        println(io, "Status: **$status**\n")
        println(io, "**Superseded by**: ", result["superseded_by"], "\n")
        println(io, result["historical_note"], "\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        for band in ("lw", "sw")
            println(io, "\n## $(uppercase(band)) pass chain\n")
            for e in manifest[band]
                println(io, "- $(e["pass"]): $(e["incode"]) -> " *
                            "$(e["outcode"]); gases = " *
                            "$(join(e["trainable_gases"], ", ")); " *
                            "relative_to = $(e["relative_to_after_rgb_rewrite"])")
            end
        end
        println(io, "\nDerived products present: $n_present / $(length(derived))")
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_g2_g3_runner_scaffold: $status ($n_present/" *
            "$(length(derived)) derived present)")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return startswith(status, "runner_scaffold_ready") ? 0 : 1
end

exit(main())
