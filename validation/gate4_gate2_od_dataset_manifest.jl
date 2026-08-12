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
using NCDatasets

const ECCKD_SRC = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"

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

# fail-closed per-file schema + scenario-attribute checks (monitor):
# pressure_hl (55,50), temperature_hl (55,50), mole_fraction_fl (54,N,50)
# with N recorded (varies by scenario: e.g. LW rel-415 N=7, LW ch4-350 N=9),
# reference_surface_mole_fraction present, scenario attr == exact token.
function schema_check(path, scenario_token; expect_gas_n = nothing)
    issues = String[]
    gas_n = -1
    try
        NCDataset(path) do ds
            att = get(ds.attrib, "scenario", nothing)
            att == scenario_token ||
                push!(issues, "scenario attr '$att' != '$scenario_token'")
            size(ds["pressure_hl"]) == (55, 50) ||
                push!(issues, "pressure_hl $(size(ds["pressure_hl"])) != (55,50)")
            size(ds["temperature_hl"]) == (55, 50) ||
                push!(issues, "temperature_hl $(size(ds["temperature_hl"])) != (55,50)")
            if haskey(ds, "mole_fraction_fl")
                mf = size(ds["mole_fraction_fl"])
                (length(mf) == 3 && mf[1] == 54 && mf[3] == 50) ||
                    push!(issues, "mole_fraction_fl $mf != (54,N,50)")
                gas_n = length(mf) == 3 ? mf[2] : -1
                expect_gas_n !== nothing && gas_n != expect_gas_n &&
                    push!(issues, "mole_fraction_fl N=$gas_n != expected $expect_gas_n")
            else
                push!(issues, "mole_fraction_fl missing")
            end
            haskey(ds, "reference_surface_mole_fraction") ||
                push!(issues, "reference_surface_mole_fraction missing")
        end
    catch err
        push!(issues, "open/read failed: $(sprint(showerror, err))")
    end
    return issues, gas_n
end

function entry(label, path; scenario = nothing, expect_gas_n = nothing)
    present = isfile(path) && filesize(path) > 0
    d = Dict{String, Any}("label" => label, "path" => path,
        "present" => present,
        "size_bytes" => present ? filesize(path) : 0,
        "sha256" => present ? filesha(path) : "PENDING")
    if present && scenario !== nothing
        issues, gas_n = schema_check(path, scenario; expect_gas_n = expect_gas_n)
        d["schema_ok"] = isempty(issues)
        d["mole_fraction_gas_n"] = gas_n
        isempty(issues) || (d["schema_issues"] = issues)
    end
    d
end

# pinned-script set-drift proof (same mechanism as gate4_g3_scoped_input_
# preflight): the 20/16 lists must equal the default-order case blocks of
# the pinned optimizer scripts (TRAINING + relative_to, SW rgb rewrite)
function pinned_flux_set(script, band, passes)
    src = read(joinpath(ECCKD_SRC, "test", script), String)
    names = Set{String}()
    for pss in passes
        m = match(Regex(pss * "\\)(.*?);;", "s"), src)
        m === nothing && continue
        for fm in eachmatch(Regex("ckdmip_evaluation1_" * band *
                                  "_fluxes_[A-Za-z0-9.-]+\\.h5"), m.captures[1])
            push!(names, fm.match)
        end
    end
    names
end

function main()
    inv = Any[]
    for s in LW_SCEN
        push!(inv, entry("lw_$s",
            joinpath(CKDMIP_ROOT, "evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_$s.h5");
            scenario = s))
    end
    for s in SW_SCEN
        push!(inv, entry("sw_rgb_$s",
            joinpath(CKDMIP_ROOT, "evaluation1/sw_fluxes-rgb/ckdmip_evaluation1_sw_fluxes-rgb_$s.h5");
            scenario = s))
    end
    # eval2 rel-415 pair: monitor-verified schema pins N=7 (LW) / N=8 (SW)
    push!(inv, entry(EVAL2[1][1], EVAL2[1][2]; scenario = "rel-415",
                     expect_gas_n = 7))
    push!(inv, entry(EVAL2[2][1], EVAL2[2][2]; scenario = "rel-415",
                     expect_gas_n = 8))

    n_lw = count(e -> startswith(e["label"], "lw_") && e["present"], inv)
    n_sw = count(e -> startswith(e["label"], "sw_rgb_") && e["present"], inv)
    n_e2 = count(e -> startswith(e["label"], "eval2_") && e["present"], inv)
    schema_bad = [e["label"] for e in inv
                  if get(e, "schema_ok", true) == false]
    gates = Dict{String, String}(
        "lw_20_present" => n_lw == 20 ? "passed" : "failed",
        "sw_16_present" => n_sw == 16 ? "passed" : "failed",
        "eval2_pair_present" => n_e2 == 2 ? "passed" : "pending",
        "schema_all_present_ok" => isempty(schema_bad) ? "passed" : "failed")
    lw_pinned = pinned_flux_set("optimize_lut_lw.sh", "lw",
        ["relative-base", "relative-ch4", "relative-n2o", "relative-cfc"])
    sw_pinned = Set(replace(n, "sw_fluxes_" => "sw_fluxes-rgb_") for n in
        pinned_flux_set("optimize_lut_sw.sh", "sw",
            ["relative-base", "relative-ch4", "relative-n2o"]))
    lw_expected = Set("ckdmip_evaluation1_lw_fluxes_$s.h5" for s in LW_SCEN)
    sw_expected = Set("ckdmip_evaluation1_sw_fluxes-rgb_$s.h5" for s in SW_SCEN)
    gates["expected_sets_match_pinned_scripts"] =
        (lw_pinned == lw_expected && sw_pinned == sw_expected) ?
        "passed" : "failed"
    status = if gates["lw_20_present"] == "passed" &&
                gates["sw_16_present"] == "passed" &&
                gates["schema_all_present_ok"] == "passed" &&
                gates["expected_sets_match_pinned_scripts"] == "passed"
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
