# Gate-4 init-generation MANIFEST (spec unit; nothing is generated here).
#
# Records the exact future commands and inputs needed to produce the
# acceptance-run initial states with the pinned tool: LW raw-ckd-definition
# (create_lut_lw, APP=climate, BAND_STRUCTURE fsck), SW raw-ckd-definition
# (create_lut_sw, BAND_STRUCTURE rgb), and SW scaled-ckd-definition
# (scale_lut_sw with a direct-only, mu0=0.5, no-Rayleigh MMM reference LBL
# flux file). Sourced from the pinned test/{create_lut_lw,create_lut_sw,
# scale_lut_sw}.sh and test/config.h plus the committed G2/G3 scaffold --
# never memory. GATES GUARANTEE nothing executes create_lut/scale_lut and no
# optimizer/objective/floor computation occurs. Missing inputs produce
# status init_generation_manifest_ready_waiting_for_inputs, not a failure.
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
const WORKROOT = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"

const IG_RESULTS_JSON = validation_results_path("gate4_init_generation_manifest.json")
const IG_RESULTS_MD = validation_results_path("gate4_init_generation_manifest.md")

grepn(text, pat) = [(i, strip(l)) for (i, l) in enumerate(split(text, '\n'))
                    if occursin(pat, l) && !occursin(r"^\s*#", l)]

function main()
    fails = String[]
    gates = Dict{String, String}()

    src = Dict(
        "create_lw" => read(joinpath(ECCKD_SRC, "test/create_lut_lw.sh"), String),
        "create_sw" => read(joinpath(ECCKD_SRC, "test/create_lut_sw.sh"), String),
        "scale_sw" => read(joinpath(ECCKD_SRC, "test/scale_lut_sw.sh"), String),
        "config" => read(joinpath(ECCKD_SRC, "test/config.h"), String),
    )
    scaffold = JSON.parsefile(
        validation_results_path("gate4_g2_g3_runner_scaffold.json"))
    startswith(scaffold["status"], "runner_scaffold_ready") ||
        push!(fails, "runner scaffold not green: $(scaffold["status"])")

    # verbatim command/config evidence with line anchors
    evidence = Dict{String, Any}(
        "create_lut_lw_invocation" => grepn(src["create_lw"], "create_look_up_table"),
        "create_lut_sw_invocation" => grepn(src["create_sw"], "create_look_up_table"),
        "create_lut_sw_ssi" => grepn(src["create_sw"], "ssi="),
        "scale_lut_invocation" => grepn(src["scale_sw"], "scale_lut"),
        "scale_lut_reference_settings" => grepn(src["scale_sw"], "direct") ∪
                                          grepn(src["scale_sw"], "cos_solar") ∪
                                          grepn(src["scale_sw"], "albedo") ∪
                                          grepn(src["scale_sw"], "rayleigh"),
        "raw_output_templates" => grepn(src["create_lw"], "raw-ckd-definition") ∪
                                  grepn(src["create_sw"], "raw-ckd-definition"),
        "scaled_output_template" => grepn(src["scale_sw"], "scaled-ckd-definition"),
        "conc_inputs" => grepn(src["create_lw"], "conc_input") ∪
                         grepn(src["create_sw"], "conc_input"),
    )

    # the three future commands (spec form; variables per pinned config.h with
    # CKDMIP_DATA_DIR remapped to the local restored tree)
    commands = Dict(
        "lw_raw" => Dict(
            "app" => "climate", "band_structure" => "fsck",
            "tool" => "$(ECCKD_SRC)/src/ecckd/create_look_up_table (pinned; " *
                      "prebuilt copy in ecckd-derived-flux-work/ecckd)",
            "driver" => "test/create_lut_lw.sh with CKDMIP_DATA_DIR=" *
                        "$(CKDMIP_ROOT), WORK_DIR=$(WORKROOT)/lw",
            "gpoint_file" => "required input (find_g_points output or the " *
                             "published model's gpoint file) -- see gates",
            "spectra" => "$(CKDMIP_ROOT)/idealized/lw_spectra",
            "conc" => ["ckdmip_mmm_concentrations.nc",
                       "ckdmip_mmm-const_concentrations.nc (composite)"],
            "output" => "$(WORKROOT)/lw/lw_raw-ckd-definition/" *
                        "ecckd-<VER>_lw_raw-ckd-definition_climate_fsck-" *
                        "<TOL>.nc"),
        "sw_raw" => Dict(
            "app" => "climate", "band_structure" => "rgb",
            "driver" => "test/create_lut_sw.sh with CKDMIP_DATA_DIR=" *
                        "$(CKDMIP_ROOT), WORK_DIR=$(WORKROOT)/sw",
            "ssi" => "$(CKDMIP_ROOT)/mmm/sw_spectra_extras/ckdmip_ssi.h5",
            "spectra" => "$(CKDMIP_ROOT)/idealized/sw_spectra",
            "conc" => ["ckdmip_mmm_concentrations.nc",
                       "ckdmip_mmm-const_concentrations.nc (composite)"],
            "output" => "$(WORKROOT)/sw/sw_raw-ckd-definition/" *
                        "ecckd-<VER>_sw_raw-ckd-definition_climate_rgb-" *
                        "<TOL>.nc"),
        "sw_scaled" => Dict(
            "driver" => "test/scale_lut_sw.sh",
            "input" => "the sw_raw output above",
            "reference_lbl" => "ckdmip_mmm_sw_fluxes-raw_present_1.h5 " *
                "produced by the CKDMIP tool (ckdmip_sw at " *
                "/shared/home/greg/build/ckdmip-1.0/bin) with " *
                "do_write_direct_only=true, cos_solar_zenith_angle=0.5, " *
                "surf_albedo=0.15, NO Rayleigh in the scale reference " *
                "(direct-beam-only)",
            "output" => "$(WORKROOT)/sw/sw_raw-ckd-definition/" *
                        "ecckd-<VER>_sw_scaled-ckd-definition_climate_rgb-" *
                        "<TOL>.nc"),
    )

    # required-input enumeration with present/missing
    req = Any[]
    function need(label, path; dir = false)
        present = dir ? isdir(path) : isfile(path)
        push!(req, Dict("label" => label, "path" => path,
                        "present" => present))
        return present
    end
    need("idealized LW spectra", joinpath(CKDMIP_ROOT, "idealized/lw_spectra");
         dir = true)
    need("idealized SW spectra", joinpath(CKDMIP_ROOT, "idealized/sw_spectra");
         dir = true)
    need("idealized conc", joinpath(CKDMIP_ROOT,
         "idealized/conc/ckdmip_idealized_concentrations.nc"))
    need("MMM conc", joinpath(CKDMIP_ROOT,
         "mmm/conc/ckdmip_mmm_concentrations.nc"))
    need("MMM const conc (composite)", joinpath(CKDMIP_ROOT,
         "mmm/conc/ckdmip_mmm-const_concentrations.nc"))
    need("MMM SSI", joinpath(CKDMIP_ROOT,
         "mmm/sw_spectra_extras/ckdmip_ssi.h5"))
    need("MMM LW spectra (create_lut averaging)", joinpath(CKDMIP_ROOT,
         "mmm/lw_spectra"); dir = true)
    need("MMM SW spectra", joinpath(CKDMIP_ROOT, "mmm/sw_spectra"); dir = true)
    # gpoint files: search plausible locations (find_g_points outputs)
    gpoint_hits = String[]
    for root in (WORKROOT, "/shared/home/greg/ecckd-derived-flux-work")
        isdir(root) || continue
        for (dir, _, fs) in walkdir(root)
            for f in fs
                # actual find_g_points DATA outputs only: HDF5 files with a
                # gpoints token; plot scripts (e.g. plot_gpoints.m) never count
                (endswith(f, ".h5") &&
                 occursin(r"(_|^)g_?points(_|\.)", f)) &&
                    push!(gpoint_hits, joinpath(dir, f))
            end
        end
    end
    push!(req, Dict("label" => "g-point files (find_g_points output)",
                    "path" => isempty(gpoint_hits) ?
                        "NOT FOUND (must be produced by find_g_points or " *
                        "extracted from the published workflow)" :
                        join(gpoint_hits, "; "),
                    "present" => !isempty(gpoint_hits)))
    n_present = count(r -> r["present"], req)
    inputs_ready = n_present == length(req)

    # gates
    gates["no_generation_executed"] = "passed"   # structural: this unit only
    # reads files; verify no run of the tools appears in this script itself
    self_src = read(@__FILE__, String)
    for tok in ("run(`", "read(`\$(ECCKD", "create_look_up_table ")
        # allow mentions inside strings; forbid actual backtick invocations of
        # the generation tools
        if occursin("run(`", self_src) &&
           (occursin(r"run\(`[^`]*create_look_up_table", self_src) ||
            occursin(r"run\(`[^`]*scale_lut", self_src) ||
            occursin(r"run\(`[^`]*ckdmip_sw", self_src))
            gates["no_generation_executed"] = "failed"
            push!(fails, "generation tool invocation found in scaffold")
        end
    end
    gates["required_inputs_enumerated"] = length(req) >= 9 ? "passed" : "failed"
    length(req) >= 9 || push!(fails, "input enumeration incomplete")
    sw_accept = scaffold["manifest"]["sw"][1]["incode"]
    gates["sw_acceptance_init_is_scaled"] =
        sw_accept == "scaled-ckd-definition" ? "passed" : "failed"
    sw_accept == "scaled-ckd-definition" ||
        push!(fails, "SW acceptance init: $sw_accept")
    lw_accept = scaffold["manifest"]["lw"][1]["incode"]
    gates["lw_acceptance_init_is_raw"] =
        lw_accept == "raw-ckd-definition" ? "passed" : "failed"
    lw_accept == "raw-ckd-definition" ||
        push!(fails, "LW acceptance init: $lw_accept")
    gates["no_optimizer_or_floor_computation"] = "passed"  # by construction:
    # this unit imports no loss kernels, no forward map, no Enzyme. The token
    # is split below so the check cannot match its own source line.
    kernel_token = "ecckd_lw_" * "ckd_loss"
    include_token = "ecckd_original_" * "objective_loss"
    if occursin(kernel_token, replace(self_src, "\"ecckd_lw_\" * \"ckd_loss\"" => "")) ||
       occursin(include_token, replace(self_src, "\"ecckd_original_\" * \"objective_loss\"" => ""))
        gates["no_optimizer_or_floor_computation"] = "failed"
        push!(fails, "loss kernel or objective include referenced in init manifest")
    end
    gates["scale_reference_direct_only_mu05"] =
        any(occursin("0.5", l) for (_, l) in
            evidence["scale_lut_reference_settings"]) &&
        any(occursin("direct", lowercase(l)) for (_, l) in
            evidence["scale_lut_reference_settings"]) ? "passed" : "failed"
    gates["scale_reference_direct_only_mu05"] == "passed" ||
        push!(fails, "scale-lut direct-only mu0=0.5 evidence not found")

    status = !isempty(fails) ? "init_generation_manifest_failed" :
             inputs_ready ? "init_generation_manifest_ready" :
                            "init_generation_manifest_ready_waiting_for_inputs"

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_init_generation_manifest",
        "data_mode" => "spec_manifest_only_nothing_generated",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "commands" => commands, "evidence" => evidence,
        "required_inputs" => req,
        "inputs_present" => n_present, "inputs_expected" => length(req),
        "provenance" => Dict("branch" => branch, "generated_from_head" => head,
            "pinned_source" => ECCKD_SRC,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "init-generation specification only; nothing is " *
                        "generated; no optimizer, objective, floor, or " *
                        "recovery computation.",
    )
    mkpath(dirname(IG_RESULTS_JSON))
    open(IG_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(IG_RESULTS_MD, "w") do io
        println(io, "# Gate-4 init-generation manifest\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\n## Required inputs ($n_present/$(length(req)) present)\n")
        for r in req
            mark = r["present"] ? "present" : "MISSING"
            println(io, "- [$mark] $(r["label"]): `$(r["path"])`")
        end
        println(io, "\nSW acceptance init resolves to the scaled-ckd-definition " *
                    "output; LW to the raw-ckd-definition output (gated).")
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_init_generation_manifest: $status " *
            "($n_present/$(length(req)) inputs present)")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return startswith(status, "init_generation_manifest_ready") ? 0 : 1
end

exit(main())
