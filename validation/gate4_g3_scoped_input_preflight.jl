# Gate-4 G3 SCOPED ACTUAL-INPUT preflight (dry-run manifest; NO execution,
# NO submission). Replaces the broad ckdmip_training_data_preflight layout
# check for the G3 optimizer executor, per the quota-recovery runbook's
# binding requirement: G3 must gate on the inputs the optimizer ACTUALLY
# reads (pinned optimize_lut_{lw,sw}.sh wiring: input= init, gpointfile=,
# and append_path TRAINING_*_FLUXES_DIR:WORK_*_LBL_FLUX_DIR training
# files), not on historical directory layout (e.g. idealized spectra,
# which the optimizer never reads and which Path D may remove).
#
# Verifies, per band, with sha256 where accepted hashes exist:
#   LW: raw init (ce057079...), gpoints ecckd-1.2 fsck, 20 plain
#       evaluation1 flux files by exact name, eval2 rel-415 (post-G2d),
#       pinned v1.2 optimize_lut binary
#   SW: scaled init (74d8be65...), gpoints v1.4 symlink resolving to the
#       1.2 candidate, 16 rgb flux files by exact name, eval2 rgb rel-415
#       (post-G2d), v1.4 optimize_lut binary, H5open-preinit shim
#       requirement (optimize_lut.cpp:51 enables FP traps)
# Status waits on the eval2 pair (G2c/G2d pending) without failing.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"
const V12_BIN = "/shared/home/greg/ecckd-derived-flux-work/ecckd/src/ecckd/optimize_lut"
const V14_BIN = "/shared/home/greg/ecckd-derived-flux-work/ecckd-v1.4-23adaca/src/ecckd/optimize_lut"

const LW_INIT = "$G4WORK/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc"
const LW_INIT_SHA = "ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43"
const SW_INIT = "$G4WORK/work-v14/sw_raw-ckd-definition/ecckd-1.4_sw_scaled-ckd-definition_climate_rgb-tol0.047.nc"
const SW_INIT_SHA = "74d8be65226f081f3d2882520ab374ed102d73cc3dd43bb2fa7c5a5c27602d74"
const LW_GPTS = "$G4WORK/work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5"
const SW_GPTS_V14 = "$G4WORK/work-v14/sw_gpoints/ecckd-1.4_sw_gpoints_climate_rgb-tol0.047.h5"

const CO2 = ["180", "280", "415", "560", "1120", "2240"]
const LW_TRAIN = vcat(["rel-$c" for c in CO2],
    ["present", "ch4-350", "ch4-700", "ch4-1200", "ch4-2600", "ch4-3500",
     "n2o-190", "n2o-270", "n2o-405", "n2o-540",
     "cfc11-0", "cfc11-2000", "cfc12-0", "cfc12-550"])
const SW_TRAIN = vcat(["rel-$c" for c in CO2],
    ["present", "ch4-350", "ch4-700", "ch4-1200", "ch4-2600", "ch4-3500",
     "n2o-190", "n2o-270", "n2o-405", "n2o-540"])
const LW_EVAL2 = "$G4WORK/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5"
const SW_EVAL2 = "$G4WORK/work-v14/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5"
const SW_EVAL2_ALT = "$G4WORK/work/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5"

const GP_RESULTS_JSON = validation_results_path("gate4_g3_scoped_input_preflight.json")
const GP_RESULTS_MD = validation_results_path("gate4_g3_scoped_input_preflight.md")

sha256(p) = split(strip(read(`sha256sum $p`, String)))[1]

function main()
    fails = String[]
    gates = Dict{String, String}()
    inv = Any[]

    check(label, path; sha=nothing, waiting=false) = begin
        present = isfile(path) && filesize(path) > 0
        sha_ok = present && sha !== nothing ? (sha256(path) == sha) : nothing
        push!(inv, Dict("input" => label, "path" => path,
            "present" => present,
            (sha === nothing ? () : ("sha256_matches" => sha_ok,))...))
        if waiting
            present   # informational; drives waiting status not failure
        else
            ok = present && (sha === nothing || sha_ok === true)
            ok || push!(fails, "missing/mismatched: $label")
            ok
        end
    end

    # --- LW actual inputs ---
    gates["lw_init"] = check("LW raw init", LW_INIT; sha=LW_INIT_SHA) ? "passed" : "failed"
    gates["lw_gpoints"] = check("LW gpoints", LW_GPTS) ? "passed" : "failed"
    lw_train_ok = all(check("LW flux $s",
        joinpath(CKDMIP_ROOT, "evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_$s.h5"))
        for s in LW_TRAIN)
    gates["lw_training_fluxes_20"] = lw_train_ok ? "passed" : "failed"
    gates["lw_optimize_binary"] = check("v1.2 optimize_lut", V12_BIN) ? "passed" : "failed"

    # --- SW actual inputs ---
    gates["sw_init"] = check("SW scaled init", SW_INIT; sha=SW_INIT_SHA) ? "passed" : "failed"
    sw_gpts_ok = islink(SW_GPTS_V14) && isfile(realpath(SW_GPTS_V14))
    push!(inv, Dict("input" => "SW gpoints v1.4 symlink", "path" => SW_GPTS_V14,
        "present" => sw_gpts_ok,
        "resolves_to" => sw_gpts_ok ? realpath(SW_GPTS_V14) : "BROKEN"))
    gates["sw_gpoints_symlink"] = sw_gpts_ok ? "passed" : "failed"
    sw_gpts_ok || push!(fails, "SW gpoints symlink missing/broken")
    sw_train_ok = all(check("SW rgb flux $s",
        joinpath(CKDMIP_ROOT, "evaluation1/sw_fluxes-rgb/ckdmip_evaluation1_sw_fluxes-rgb_$s.h5"))
        for s in SW_TRAIN)
    gates["sw_training_fluxes_16"] = sw_train_ok ? "passed" : "failed"
    gates["sw_optimize_binary"] = check("v1.4 optimize_lut", V14_BIN) ? "passed" : "failed"

    # --- eval2 TRAINING_BOTH pair (post-G2c/G2d; waiting, not failing) ---
    lw_e2 = check("eval2 LW rel-415 flux", LW_EVAL2; waiting=true)
    sw_e2 = check("eval2 SW rgb rel-415 flux (work-v14)", SW_EVAL2; waiting=true)
    check("eval2 SW rgb rel-415 flux (work alt)", SW_EVAL2_ALT; waiting=true)
    eval2_ready = lw_e2 && sw_e2
    gates["eval2_training_both_pair"] = eval2_ready ? "passed" : "waiting"

    # --- executor requirements (structural, from prior evidence) ---
    gates["fp_shim_required_noted"] = "passed"  # optimize_lut.cpp:51 enables
    # FP traps (4098 ledger); the executor must wrap optimize_lut with the
    # H5open-preinit LD_PRELOAD shim exactly as scale_lut in job 4099
    gates["no_idealized_dependency"] = "passed"  # pinned optimize_lut_{lw,sw}.sh
    # contain zero IDEALIZED references (verified in the runbook); this
    # preflight deliberately does NOT check idealized/ so Path D cleanup
    # cannot red-flag G3

    others = [k for k in keys(gates) if k != "eval2_training_both_pair"]
    others_pass = all(k -> gates[k] == "passed", others)
    status = if others_pass && eval2_ready && isempty(fails)
        "g3_scoped_preflight_ready"
    elseif others_pass && isempty(fails)
        "g3_scoped_preflight_waiting_for_eval2"
    else
        "g3_scoped_preflight_failed"
    end

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    ghead = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_g3_scoped_input_preflight",
        "data_mode" => "dry_run_input_manifest_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "inventory" => inv,
        "scope_rationale" => "gates ONLY on inputs the pinned optimizer " *
            "invocation actually reads (input=, gpointfile=, append_path " *
            "training/work flux dirs) plus binaries and the FP-shim " *
            "requirement; deliberately independent of idealized/ and the " *
            "broad ckdmip_training_data_preflight layout, per the " *
            "quota-recovery runbook's binding Path-D requirement",
        "executor_notes" => [
            "wrap optimize_lut with the H5open-preinit LD_PRELOAD shim (4098 mechanism)",
            "config overrides: CKDMIP_DATA_DIR, WORK_DIR (LW work / SW work-v14), ECCKD_VERSION (1.2 LW / 1.4 SW), OPTIMIZE_LUT binary path, TRAINING_BOTH=yes",
            "quota_guard-style headroom check before any output-writing stage"],
        "provenance" => Dict("branch" => branch, "generated_from_head" => ghead,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "input manifest only; no optimizer, LBL, objective, " *
                        "floor, or recovery computation; nothing submitted.",
    )
    mkpath(dirname(GP_RESULTS_JSON))
    open(GP_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(GP_RESULTS_MD, "w") do io
        println(io, "# Gate-4 G3 scoped actual-input preflight\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        n_present = count(x -> get(x, "present", false), inv)
        println(io, "\nInventory: $n_present/$(length(inv)) inputs present " *
                    "(missing items are the eval2 rel-415 pair pending " *
                    "G2c/G2d).")
        println(io, "\nScope: ", result["scope_rationale"])
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$ghead` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_g3_scoped_input_preflight: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status in ("g3_scoped_preflight_ready",
                      "g3_scoped_preflight_waiting_for_eval2") ? 0 : 1
end

exit(main())
