# Gate-4 A2 rerun-with-proof MANIFEST (dry-run; nothing heavy executes).
#
# Operative path after the A1 negative result: rerun the upstream g-point
# construction with the pinned tool as fixed-input PROBLEM-DEFINITION
# reconstruction. Full chain per the pinned scripts:
#   reorder_spectrum_{lw,sw}.sh  (MMM median present-day spectra ->
#                                 {lw,sw}_order_<bandstruct>_<gas>.h5)
#   find_g_points_{lw,sw}.sh     (MMM spectra + reordering outputs,
#                                 per-TOLERANCE loop -> gpoints h5 outputs;
#                                 idealized spectra enter LATER, at the
#                                 create_lut proof stage)
# ACCEPTANCE HINGE (binding): a rerun output feeds the recovery floor ONLY if
# rerun gpoints + raw create_lut EXACTLY reproduce the published
# gpoint_fraction and band support arrays (and g-counts 32/32). Anything
# short of exact reproduction is SENSITIVITY-ONLY per the amended policy
# (gate4_gpoint_provenance_policy @ 270044e amendment).
#
# No find_g_points/create_lut/objective/floor execution in this unit.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const ECCKD_SRC = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"
const CKDMIP_ROOT = get(ENV, "RH_CKDMIP_DATA_PATH",
                        "/shared/home/greg/data/ckdmip")
const WORKROOT = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const TOOLDIR = "/shared/home/greg/ecckd-derived-flux-work/ecckd/src/ecckd"

const A2_RESULTS_JSON = validation_results_path("gate4_a2_find_g_points_rerun_manifest.json")
const A2_RESULTS_MD = validation_results_path("gate4_a2_find_g_points_rerun_manifest.md")

grepn(text, pat) = [(i, strip(l)) for (i, l) in enumerate(split(text, '\n'))
                    if occursin(pat, l) && !occursin(r"^\s*#", l)]

# guarded A1-recon classifier (fixture-run via the absolute-path
# passthrough; the unit's SINGLE parsefile site; the A1 PRODUCER is a
# network unit and is never rerun -- only its committed artifact is
# parsed here): FIVE fixed, distinct refusal classes -- missing;
# unparseable (parse failure); parses to a non-object (JSON null/array/
# scalar); case mismatch (exact gate4_a1_upstream_recon); unexpected
# status with the verbatim token and the faithful operative-path caveat.
function am_classify_a1(name)
    path = isabspath(name) ? name : validation_results_path(name)
    isfile(path) ||
        return (false, "A1 recon artifact missing")
    raw = try
        JSON.parsefile(path)
    catch
        return (false, "A1 recon artifact unparseable (parse failure)")
    end
    raw isa AbstractDict ||
        return (false, "A1 recon artifact parses to a non-object " *
                       "(JSON null/array/scalar)")
    c = get(raw, "case", "")
    (c isa AbstractString && c == "gate4_a1_upstream_recon") ||
        return (false, "A1 recon artifact case mismatch: " *
                       (c isa AbstractString && !isempty(c) ? c :
                        "(missing/non-string)"))
    s = get(raw, "status", "")
    st = s isa AbstractString ? String(s) : "(missing/non-string)"
    st == "a1_recon_no_exact_upstream_source_found" ||
        return (false, "A1 recon status unexpected: $st -- A2 may " *
                       "not be the operative path")
    return (true, "ok")
end

# nonthrowing pinned-script reader: an unreadable pinned script yields
# nothing and a controlled failed gate/reason, never an exception
# before the unit's own JSON/MD failure report
am_try_read(p) = try
    read(p, String)
catch
    nothing
end

# fail-closed gate closure (pure; fixture-run; standard discipline):
# any non-passed gate appends the authoritative complete census and
# blocks success, which additionally requires every gate passed
function am_close_failed_gates(fails, gates)
    failed = sort([k for (k, v) in gates if v != "passed"])
    out = copy(fails)
    isempty(failed) ||
        push!(out, "failed gates (fail-closed census): " *
                   join(failed, ", "))
    return out, isempty(failed)
end

function main()
    fails = String[]
    gates = Dict{String, String}()

    # classifier fixtures FIRST, through the SAME production code
    tdir = mktempdir()
    lt = Dict{String, Bool}()
    lt["missing_fails"] = begin
        r = am_classify_a1(joinpath(tdir, "absent.json"))
        !r[1] && r[2] == "A1 recon artifact missing"
    end
    fpx = joinpath(tdir, "a1.json")
    write(fpx, "{")
    lt["malformed_fails"] = begin
        r = am_classify_a1(fpx)
        !r[1] && occursin("unparseable (parse failure)", r[2])
    end
    write(fpx, "null")
    lt["null_non_object_fails"] = begin
        r = am_classify_a1(fpx)
        !r[1] && occursin("non-object", r[2])
    end
    write(fpx, "[1]")
    lt["array_non_object_fails"] = begin
        r = am_classify_a1(fpx)
        !r[1] && occursin("non-object", r[2])
    end
    write(fpx, "{\"case\": \"other\", \"status\": " *
               "\"a1_recon_no_exact_upstream_source_found\"}")
    lt["wrong_case_fails"] = begin
        r = am_classify_a1(fpx)
        !r[1] && occursin("case mismatch", r[2])
    end
    write(fpx, "{\"case\": \"gate4_a1_upstream_recon\", " *
               "\"status\": \"totally_bogus\"}")
    lt["tampered_status_fails"] = begin
        r = am_classify_a1(fpx)
        !r[1] && occursin("status unexpected: totally_bogus", r[2]) &&
            occursin("operative path", r[2])
    end
    write(fpx, "{\"case\": \"gate4_a1_upstream_recon\", \"status\": " *
               "\"a1_recon_no_exact_upstream_source_found\"}")
    lt["exact_green_passes"] = am_classify_a1(fpx) == (true, "ok")
    lt["failed_gate_closed_without_reason"] = begin
        f1, ok1 = am_close_failed_gates(String[], Dict("g" => "failed"))
        f2, ok2 = am_close_failed_gates(String[], Dict("g" => "passed"))
        f3, ok3 = am_close_failed_gates(["reason for a"],
            Dict("a" => "failed", "b" => "failed"))
        !ok1 && length(f1) == 1 &&
            occursin("fail-closed census", f1[1]) &&
            ok2 && isempty(f2) &&
            !ok3 && length(f3) == 2 && occursin("a, b", f3[2])
    end
    lt["pinned_reader_nonthrowing"] = begin
        rp = joinpath(tdir, "r.txt")
        write(rp, "x")
        am_try_read(rp) == "x" &&
            am_try_read(joinpath(tdir, "gone.txt")) === nothing
    end
    rm(tdir, recursive = true, force = true)
    gates["prerequisite_loader_fixture_tests"] =
        all(values(lt)) ? "passed" : "failed"
    all(values(lt)) || push!(fails, "prerequisite loader fixture " *
        "failures: " * join(sort([k for (k, v) in lt if !v]), ", "))

    # all six pinned-script reads go through the SAME nonthrowing
    # reader: unreadable text becomes "" plus a controlled failed gate,
    # so downstream evidence extraction yields empty (failed) evidence
    # rather than an exception
    src_paths = Dict(
        "find_lw" => joinpath(ECCKD_SRC, "test/find_g_points_lw.sh"),
        "find_sw" => joinpath(ECCKD_SRC, "test/find_g_points_sw.sh"),
        "reorder_lw" => joinpath(ECCKD_SRC, "test/reorder_spectrum_lw.sh"),
        "reorder_sw" => joinpath(ECCKD_SRC, "test/reorder_spectrum_sw.sh"),
        "do_lw" => joinpath(ECCKD_SRC, "test/do_all_lw.sh"),
        "do_sw" => joinpath(ECCKD_SRC, "test/do_all_sw.sh"),
    )
    src = Dict{String, String}()
    unreadable = String[]
    for (k, p) in sort(collect(src_paths); by = first)
        t = am_try_read(p)
        t === nothing ? (push!(unreadable, k); src[k] = "") : (src[k] = t)
    end
    gates["pinned_source_scripts_readable"] =
        isempty(unreadable) ? "passed" : "failed"
    isempty(unreadable) ||
        push!(fails, "pinned scripts missing/unreadable: " *
                     join(sort(unreadable), ", "))
    # exact case + exact status prerequisite (guarded; artifact-only,
    # the A1 network producer is never rerun)
    a1_ok, a1_why = am_classify_a1("gate4_a1_upstream_recon.json")
    gates["a1_recon_prerequisite"] = a1_ok ? "passed" : "failed"
    a1_ok || push!(fails, a1_why)

    evidence = Dict{String, Any}(
        "tolerance_lists" => grepn(src["do_lw"], "TOLERANCE") ∪
                             grepn(src["do_sw"], "TOLERANCE") ∪
                             grepn(src["find_lw"], "TOLERANCE")[1:min(4, end)],
        "reorder_inputs_lw" => grepn(src["find_lw"], "median") ∪
                               grepn(src["find_lw"], "reordering_input"),
        "reorder_inputs_sw" => grepn(src["find_sw"], "median") ∪
                               grepn(src["find_sw"], "reordering_input"),
        "gpoint_outputs" => grepn(src["find_lw"], "gpoints") ∪
                            grepn(src["find_sw"], "gpoints"),
        "bandstructs" => grepn(src["do_lw"], "BANDSTRUCT") ∪
                         grepn(src["do_sw"], "BANDSTRUCT"),
    )

    # required inputs with presence, STAGE-TAGGED: find_g_points rows
    # gate the rerun itself; create_lut_proof rows gate only the later
    # proof stage
    req = Any[]
    function need(label, path; dir = false, glob = nothing,
                  stage = "find_g_points")
        present = if glob !== nothing
            isdir(path) && any(occursin(glob, f) for f in readdir(path))
        else
            dir ? isdir(path) : isfile(path)
        end
        push!(req, Dict("label" => label, "path" => string(path),
                        "glob" => glob, "stage" => stage,
                        "present" => present))
        return present
    end
    need("pinned find_g_points binary", joinpath(TOOLDIR, "find_g_points"))
    need("pinned reorder_spectrum binary",
         joinpath(TOOLDIR, "reorder_spectrum"))
    need("MMM LW median spectra", joinpath(CKDMIP_ROOT, "mmm/lw_spectra");
         glob = "median")
    need("MMM SW median spectra", joinpath(CKDMIP_ROOT, "mmm/sw_spectra");
         glob = "median")
    need("idealized LW spectra (create_lut PROOF stage, not find_g_points)",
         joinpath(CKDMIP_ROOT, "idealized/lw_spectra"); dir = true,
         stage = "create_lut_proof")
    need("idealized SW spectra (create_lut PROOF stage, not find_g_points)",
         joinpath(CKDMIP_ROOT, "idealized/sw_spectra"); dir = true,
         stage = "create_lut_proof")
    need("MMM SSI", joinpath(CKDMIP_ROOT, "mmm/sw_spectra_extras/ckdmip_ssi.h5"))
    n_present = count(r -> r["present"], req)
    inputs_ready = n_present == length(req)
    # per-stage readiness rollup (stage-explicit truthfulness for the
    # overall waiting token)
    stage_readiness = Dict{String, Any}()
    for st in ("find_g_points", "create_lut_proof")
        rows = [r for r in req if r["stage"] == st]
        np = count(r -> r["present"], rows)
        stage_readiness[st] = Dict("present" => np,
                                   "expected" => length(rows),
                                   "ready" => np == length(rows))
    end
    stage_readiness_note =
        (stage_readiness["find_g_points"]["ready"] &&
         !stage_readiness["create_lut_proof"]["ready"]) ?
        "find_g_points prerequisites are currently COMPLETE; the " *
        "overall rerun-with-proof manifest waits only on the absent " *
        "create_lut proof-stage idealized spectra (the registered " *
        "Path-D deletion scope)" :
        "see per-stage readiness fields"

    commands = Dict(
        "step1_reorder" => Dict(
            "lw" => "test/reorder_spectrum_lw.sh (pinned) with " *
                    "CKDMIP_DATA_DIR=$CKDMIP_ROOT, WORK_DIR=$WORKROOT/lw " *
                    "-- consumes MMM median present-day spectra, emits " *
                    "lw_order_<bandstruct>_<gas>.h5",
            "sw" => "test/reorder_spectrum_sw.sh analog for SW"),
        "step2_find_g_points" => Dict(
            "lw" => "test/find_g_points_lw.sh, BANDSTRUCT=fsck; 32-g TARGET " *
                    "TOLERANCE = 0.0161 (pinned do_all_lw.sh); optional " *
                    "0.061 only as 16-g sanity product",
            "sw" => "test/find_g_points_sw.sh, BANDSTRUCT=rgb; 32-g TARGET " *
                    "TOLERANCE = 0.047 (pinned do_all_sw.sh:43, " *
                    "TOLERANCE=\"0.16 0.047\"); optional 0.16 only as 16-g " *
                    "sanity product"),
        "future_outputs" => Dict(
            "lw" => "$WORKROOT/lw/lw_gpoints/ecckd-<VER>_lw_gpoints_" *
                    "climate_fsck-tol0.0161.h5 (A2 candidate; 32-g check " *
                    "gates it); optional ...tol0.061.h5 16-g sanity",
            "sw" => "$WORKROOT/sw/sw_gpoints/ecckd-<VER>_sw_gpoints_" *
                    "climate_rgb-tol0.047.h5 (A2 candidate); optional " *
                    "...tol0.16.h5 16-g sanity"),
        "runtime_estimate" => Dict(
            "basis" => "reorder + find_g_points stream the MMM spectra " *
                       "(median present-day) per band; idealized spectra " *
                       "are consumed later at the create_lut proof stage; " *
                       "LBL-scale IO-bound",
            "estimate" => "1-4 h per band per tolerance on cpu-large " *
                          "(60 GB, 16 cpu); tolerance loop multiplies -- " *
                          "run the published-matching tolerances first",
            "placement" => "Slurm cpu-large, never the head node"),
        "refusal" => "no execution from this manifest; the A2 runner unit " *
                     "must re-check inputs and carry the acceptance hinge " *
                     "gates before any invocation",
    )

    acceptance_hinge = Dict(
        "rule" => "rerun gpoints.h5 + raw create_lut output must EXACTLY " *
                  "reproduce the published gpoint_fraction and band support " *
                  "arrays (wavenumber1/2_band, band_number) AND the g-counts " *
                  "(32 LW fsck / 32 SW rgb) BEFORE any floor use",
        "if_not_exact" => "outputs are SENSITIVITY-ONLY; they cannot feed " *
                          "the acceptance floor unless Greg explicitly " *
                          "changes the optimizer-only-delta rule",
        "verification_targets" => "published LW32/SW32 definitions " *
                                  "(gate4_covariance_stride_audit rows; " *
                                  "gate4_gpoint_extraction_feasibility stats)",
    )

    gates["pinned_scripts_discovered"] = length(src) == 6 ? "passed" : "failed"
    gates["required_inputs_enumerated"] = length(req) >= 7 ? "passed" : "failed"
    gates["future_outputs_named"] = "passed"
    gates["acceptance_hinge_exact_reproduction"] =
        occursin("EXACTLY reproduce", acceptance_hinge["rule"]) ? "passed" : "failed"
    gates["unproven_reruns_sensitivity_only"] =
        occursin("SENSITIVITY-ONLY", acceptance_hinge["if_not_exact"]) ?
        "passed" : "failed"
    gates["runtime_estimate_recorded"] = "passed"
    gates["no_heavy_execution"] = "passed"
    self_src = read(@__FILE__, String)
    for tool in ("find_g_points ", "create_look_up_table ")
        occursin(Regex("run\\(`[^`]*" * strip(tool)), self_src) &&
            (gates["no_heavy_execution"] = "failed";
             push!(fails, "tool invocation found in manifest"))
    end

    # fail-closed status selection: every failed gate is closed into the
    # authoritative census reason, and success additionally requires
    # EVERY gate passed
    fails, gates_all_passed = am_close_failed_gates(fails, gates)
    status = !(isempty(fails) && gates_all_passed) ?
             "a2_manifest_failed" :
             inputs_ready ? "a2_manifest_ready" :
                            "a2_manifest_ready_waiting_for_inputs"

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_a2_find_g_points_rerun_manifest",
        "data_mode" => "dry_run_manifest_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "prerequisite_loader_fixture_verdicts" => lt,
        "required_inputs" => req,
        "stage_readiness" => stage_readiness,
        "stage_readiness_note" => stage_readiness_note,
        "inputs_present" => n_present, "inputs_expected" => length(req),
        "commands" => commands,
        "acceptance_hinge" => acceptance_hinge,
        "evidence" => evidence,
        "provenance" => Dict("branch" => branch, "generated_from_head" => head,
            "pinned_source" => ECCKD_SRC,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "dry-run A2 manifest only; no find_g_points, " *
                        "create_lut, objective, floor, or recovery " *
                        "computation.",
    )
    mkpath(dirname(A2_RESULTS_JSON))
    open(A2_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(A2_RESULTS_MD, "w") do io
        println(io, "# Gate-4 A2 find_g_points rerun-with-proof manifest\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\n## Stage readiness\n")
        println(io, "| Stage | Present/Expected | Ready |")
        println(io, "|---|---|---|")
        for st in ("find_g_points", "create_lut_proof")
            s = stage_readiness[st]
            println(io, "| $st | $(s["present"])/$(s["expected"]) | " *
                        "$(s["ready"]) |")
        end
        println(io, "\n", stage_readiness_note)
        println(io, "\n## Required inputs ($n_present/$(length(req)))\n")
        for r in req
            println(io, "- [$(r["present"] ? "present" : "MISSING")] " *
                        "[stage: $(r["stage"])] " *
                        "$(r["label"]): `$(r["path"])`" *
                        (r["glob"] === nothing ? "" : " (glob: $(r["glob"]))"))
        end
        println(io, "\n## Acceptance hinge\n")
        println(io, acceptance_hinge["rule"])
        println(io, "\nIf not exact: ", acceptance_hinge["if_not_exact"])
        println(io, "\nRuntime estimate: ",
                commands["runtime_estimate"]["estimate"], " (",
                commands["runtime_estimate"]["placement"], ")")
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_a2_find_g_points_rerun_manifest: $status " *
            "($n_present/$(length(req)) inputs)")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return startswith(status, "a2_manifest_ready") ? 0 : 1
end

exit(main())
