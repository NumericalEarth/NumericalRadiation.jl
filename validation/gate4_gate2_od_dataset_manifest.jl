# Gate-4 GATE-2 FIXED-DATASET MANIFEST (read-only inventory; NO aggregation
# choice, NO candidate acceptance, NO metric evaluation).
#
# Inventories the candidate fixed dataset for the Gate-2 true-OD metric —
# the exact union of the optimizer training scenarios (design note rev 2):
#   LW: 20 plain evaluation1 flux scenarios (rel x6, present, ch4 x5,
#       n2o x4, cfc11 x2, cfc12 x2)
#   SW: 16 rgb evaluation1 flux scenarios (rel x6, present, ch4 x5, n2o x4)
#   eval2: rel-415 pair (LW plain + SW rgb) -- PENDING until G2c/G2d
# with per-file presence/size/sha256. The BINDING dataset choice and the
# aggregation (worst-case vs pooled) remain UNRESOLVED decisions recorded
# in the design note -- this unit decides neither.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"
const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const CO2 = ["180", "280", "415", "560", "1120", "2240"]
const LW_SCEN = vcat(["rel-$c" for c in CO2],
    ["present", "ch4-350", "ch4-700", "ch4-1200", "ch4-2600", "ch4-3500",
     "n2o-190", "n2o-270", "n2o-405", "n2o-540",
     "cfc11-0", "cfc11-2000", "cfc12-0", "cfc12-550"])
const SW_SCEN = vcat(["rel-$c" for c in CO2],
    ["present", "ch4-350", "ch4-700", "ch4-1200", "ch4-2600", "ch4-3500",
     "n2o-190", "n2o-270", "n2o-405", "n2o-540"])
const EVAL2 = [
    ("eval2_lw_rel-415", "$G4WORK/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5"),
    ("eval2_sw_rgb_rel-415", "$G4WORK/work-v14/sw_lbl_fluxes/ckdmip_evaluation2_sw_fluxes-rgb_rel-415.h5")]

const DM_RESULTS_JSON = validation_results_path("gate4_gate2_od_dataset_manifest.json")
const DM_RESULTS_MD = validation_results_path("gate4_gate2_od_dataset_manifest.md")

filesha(p) = split(strip(read(`sha256sum $p`, String)))[1]

function entry(label, path)
    present = isfile(path) && filesize(path) > 0
    Dict("label" => label, "path" => path, "present" => present,
         "size_bytes" => present ? filesize(path) : 0,
         "sha256" => present ? filesha(path) : "PENDING")
end

function main()
    inv = Any[]
    for s in LW_SCEN
        push!(inv, entry("lw_$s",
            joinpath(CKDMIP_ROOT, "evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_$s.h5")))
    end
    for s in SW_SCEN
        push!(inv, entry("sw_rgb_$s",
            joinpath(CKDMIP_ROOT, "evaluation1/sw_fluxes-rgb/ckdmip_evaluation1_sw_fluxes-rgb_$s.h5")))
    end
    for (label, path) in EVAL2
        push!(inv, entry(label, path))
    end

    n_lw = count(e -> startswith(e["label"], "lw_") && e["present"], inv)
    n_sw = count(e -> startswith(e["label"], "sw_rgb_") && e["present"], inv)
    n_e2 = count(e -> startswith(e["label"], "eval2_") && e["present"], inv)
    gates = Dict{String, String}(
        "lw_20_present" => n_lw == 20 ? "passed" : "failed",
        "sw_16_present" => n_sw == 16 ? "passed" : "failed",
        "eval2_pair_present" => n_e2 == 2 ? "passed" : "pending")
    status = if gates["lw_20_present"] == "passed" &&
                gates["sw_16_present"] == "passed"
        n_e2 == 2 ? "gate2_dataset_manifest_complete" :
                    "gate2_dataset_manifest_pending_eval2"
    else
        "gate2_dataset_manifest_failed"
    end

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    ghead = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_gate2_od_dataset_manifest",
        "data_mode" => "read_only_inventory",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates,
        "counts" => Dict("lw_present" => n_lw, "of_lw" => 20,
                         "sw_present" => n_sw, "of_sw" => 16,
                         "eval2_present" => n_e2, "of_eval2" => 2),
        "inventory" => inv,
        "unresolved_decisions" => [
            "BINDING dataset choice (this optimizer-training union is the " *
            "candidate per design note rev 2; not yet ruled)",
            "aggregation: worst-case vs pooled log-RMSE across scenarios"],
        "disclaimer" => "inventory only; no aggregation choice, no metric " *
                        "evaluation, no candidate acceptance; eval2 " *
                        "entries pending G2c/G2d honestly.",
        "provenance" => Dict("branch" => branch, "generated_from_head" => ghead),
    )
    mkpath(dirname(DM_RESULTS_JSON))
    open(DM_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(DM_RESULTS_MD, "w") do io
        println(io, "# Gate-2 fixed-dataset manifest\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "Counts: LW $n_lw/20, SW-rgb $n_sw/16, eval2 $n_e2/2\n")
        println(io, "| Label | Present | Size | sha256 (16) |")
        println(io, "|---|---|---|---|")
        for e in inv
            sh = e["sha256"] == "PENDING" ? "PENDING" : e["sha256"][1:16]
            println(io, "| $(e["label"]) | $(e["present"]) | $(e["size_bytes"]) | $sh |")
        end
        println(io, "\nUnresolved: ", join(result["unresolved_decisions"], "; "))
    end
    println("gate4_gate2_od_dataset_manifest: $status")
    for (k, v) in sort(collect(gates))
        println("  $k: $v")
    end
    return status == "gate2_dataset_manifest_failed" ? 1 : 0
end

exit(main())
