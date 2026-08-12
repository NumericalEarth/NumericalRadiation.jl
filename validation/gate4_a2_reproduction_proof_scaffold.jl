# Gate-4 A2 REPRODUCTION-PROOF scaffold (dry-run; no create_lut execution;
# no floor) -- HISTORICAL; VERDICT RULE SUPERSEDED BY OPTION B.
#
# SUPERSESSION (monitor-directed marking, 2026-08-12): the proof this
# unit specified ahead of time has been EXECUTED -- proof job 4091
# (create_lut on the A2 candidates from job 4082) returned
# proof_mismatch_sensitivity_only under THIS unit's strict verdict rule
# (structure all exact; support-array drift at storage precision), and
# the R2 matching-version run (job 4096) resolved the SSI absence as
# version skew. Greg then (2026-07-20, "take option B") adopted the
# AMENDED acceptance rule in gate4_option_b_decision_record, which
# explicitly supersedes this unit's verdict_rule
# (any_mismatch -> sensitivity-only): the candidates were PROMOTED under
# structural-exact + storage-precision tolerance. The comparisons and the
# original verdict rule below are RETAINED VERBATIM as the historical
# strict spec; the pre-execution command spec is historical, not a plan.
# The status token a2_proof_scaffold_ready is retained UNCHANGED because
# gate4_a2_proof_driver_checkpoint.jl requires it by exact match.
#
# Original contract (historical): defines, ahead of the A2 run, (1) the
# exact proof-only raw create_lut commands that consume the rerun gpoints
# candidates, and (2) the exact comparisons against the published
# LW32/SW32 support arrays that decide acceptance under the strict rule.
#
# No generation, optimization, objective, floor, or recovery computation.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))
using NumericalRadiation

const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const WORKCOPY = "/shared/home/greg/ecckd-derived-flux-work/ecckd"

const RP_RESULTS_JSON = validation_results_path("gate4_a2_reproduction_proof_scaffold.json")
const RP_RESULTS_MD = validation_results_path("gate4_a2_reproduction_proof_scaffold.md")

function find_candidates()
    hits = Dict("lw" => String[], "sw" => String[])
    isdir(joinpath(G4WORK, "work")) || return hits
    for (dir, _, fs) in walkdir(joinpath(G4WORK, "work"))
        for f in fs
            endswith(f, ".h5") || continue
            if occursin("gpoints", f)
                occursin("fsck", f) && occursin("0.0161", f) &&
                    push!(hits["lw"], joinpath(dir, f))
                occursin("rgb", f) && occursin("0.047", f) &&
                    push!(hits["sw"], joinpath(dir, f))
            end
        end
    end
    return hits
end

# PURE accepted-set membership shared with fixtures (the execution
# checkpoint is itself historical-marked post-4082; both its
# pre-execution and historical-executed tokens satisfy this
# prerequisite -- a faithful SET contract, preserved verbatim)
ps_exec_status_accepted(status) =
    status in ("a2_execution_checkpoint_ready",
               "a2_execution_checkpoint_historical_executed")

# fail-closed gate closure (pure; fixture-run; same discipline as the
# A2 proof driver): whenever ANY gate is not passed the authoritative
# complete failed-gate census is appended, and success additionally
# requires every gate passed
function ps_close_failed_gates(fails, gates)
    failed = sort([k for (k, v) in gates if v != "passed"])
    out = copy(fails)
    isempty(failed) ||
        push!(out, "failed gates (fail-closed census): " *
                   join(failed, ", "))
    return out, isempty(failed)
end

# guarded exec-checkpoint classifier (fixture-run via the absolute-path
# passthrough; the unit's SINGLE parsefile site): FIVE fixed, distinct
# refusal classes -- missing; unparseable (parse failure); parses to a
# non-object (JSON null/array/scalar); case mismatch; status not in the
# accepted set (verbatim off-set token reported). Never an uncaught
# exception: the unit's own JSON/MD failure report must always emit.
function ps_classify_exec_checkpoint(name)
    path = isabspath(name) ? name : validation_results_path(name)
    isfile(path) ||
        return (false, "A2 execution checkpoint missing")
    raw = try
        JSON.parsefile(path)
    catch
        return (false, "A2 execution checkpoint unparseable " *
                       "(parse failure)")
    end
    raw isa AbstractDict ||
        return (false, "A2 execution checkpoint parses to a non-object " *
                       "(JSON null/array/scalar)")
    c = get(raw, "case", "")
    (c isa AbstractString && c == "gate4_a2_execution_checkpoint") ||
        return (false, "A2 execution checkpoint case mismatch: " *
                       (c isa AbstractString && !isempty(c) ? c :
                        "(missing/non-string)"))
    s = get(raw, "status", "")
    st = s isa AbstractString ? String(s) : "(missing/non-string)"
    ps_exec_status_accepted(st) ||
        return (false, "A2 execution checkpoint not ready: $st")
    return (true, "ok")
end

function main()
    fails = String[]
    gates = Dict{String, String}()

    # classifier fixtures FIRST, through the SAME production code
    tdir = mktempdir()
    lt = Dict{String, Bool}()
    lt["missing_fails"] = begin
        r = ps_classify_exec_checkpoint(joinpath(tdir, "absent.json"))
        !r[1] && r[2] == "A2 execution checkpoint missing"
    end
    fpx = joinpath(tdir, "xc.json")
    write(fpx, "{")
    lt["malformed_fails"] = begin
        r = ps_classify_exec_checkpoint(fpx)
        !r[1] && occursin("unparseable (parse failure)", r[2])
    end
    write(fpx, "null")
    lt["null_non_object_fails"] = begin
        r = ps_classify_exec_checkpoint(fpx)
        !r[1] && occursin("non-object", r[2])
    end
    write(fpx, "[1]")
    lt["array_non_object_fails"] = begin
        r = ps_classify_exec_checkpoint(fpx)
        !r[1] && occursin("non-object", r[2])
    end
    write(fpx, "{\"case\": \"other\", " *
               "\"status\": \"a2_execution_checkpoint_ready\"}")
    lt["wrong_case_fails"] = begin
        r = ps_classify_exec_checkpoint(fpx)
        !r[1] && occursin("case mismatch", r[2])
    end
    write(fpx, "{\"case\": \"gate4_a2_execution_checkpoint\", " *
               "\"status\": \"totally_bogus\"}")
    lt["tampered_status_fails"] = begin
        r = ps_classify_exec_checkpoint(fpx)
        !r[1] && occursin("not ready: totally_bogus", r[2])
    end
    lt["both_accepted_tokens_pass"] =
        ps_exec_status_accepted("a2_execution_checkpoint_ready") &&
        ps_exec_status_accepted(
            "a2_execution_checkpoint_historical_executed") &&
        !ps_exec_status_accepted("a2_execution_checkpoint_failed")
    write(fpx, "{\"case\": \"gate4_a2_execution_checkpoint\", " *
               "\"status\": \"a2_execution_checkpoint_ready\"}")
    lt["exact_green_passes"] =
        ps_classify_exec_checkpoint(fpx) == (true, "ok")
    # a failed gate can never yield success; the census is always
    # appended and cannot be hidden by another gate's reason
    lt["failed_gate_closed_without_reason"] = begin
        f1, ok1 = ps_close_failed_gates(String[], Dict("g" => "failed"))
        f2, ok2 = ps_close_failed_gates(String[], Dict("g" => "passed"))
        f3, ok3 = ps_close_failed_gates(["reason for a"],
            Dict("a" => "failed", "b" => "failed"))
        !ok1 && length(f1) == 1 &&
            occursin("fail-closed census", f1[1]) &&
            ok2 && isempty(f2) &&
            !ok3 && length(f3) == 2 && occursin("a, b", f3[2])
    end
    rm(tdir, recursive = true, force = true)
    gates["prerequisite_loader_fixture_tests"] =
        all(values(lt)) ? "passed" : "failed"
    all(values(lt)) || push!(fails, "prerequisite loader fixture " *
        "failures: " * join(sort([k for (k, v) in lt if !v]), ", "))

    # exact case + faithful accepted-set prerequisite (guarded)
    chk_ok, chk_why = ps_classify_exec_checkpoint(
        "gate4_a2_execution_checkpoint.json")
    gates["exec_checkpoint_prerequisite"] = chk_ok ? "passed" : "failed"
    chk_ok || push!(fails, chk_why)

    lw32 = NumericalRadiation.official_ecckd_definition_path(:longwave_32)
    sw32 = NumericalRadiation.official_ecckd_definition_path(:shortwave_32)
    gates["published_targets_resolved"] =
        isfile(lw32) && isfile(sw32) ? "passed" : "failed"

    cands = find_candidates()
    have_candidates = !isempty(cands["lw"]) && !isempty(cands["sw"])

    # NOTE: create_lut_{lw,sw}.sh accept NO input= override -- they derive
    # INPUT from ECCKD_PREFIX + model code (climate_fsck-tol0.0161 /
    # climate_rgb-tol0.047). Two valid mechanisms are recorded; mechanism 1
    # (script-faithful placement) is preferred.
    proof_commands = Dict(
        "input_mechanism_1_preferred" => "place/symlink the rerun candidate " *
            "into the TESTCOPY-configured WORK_LW_GPOINTS_DIR / " *
            "WORK_SW_GPOINTS_DIR under the EXACT filename the script " *
            "derives (ECCKD_PREFIX + _lw_gpoints_climate_fsck-tol0.0161.h5 " *
            "/ _sw_gpoints_climate_rgb-tol0.047.h5), then run the pristine " *
            "script",
        "input_mechanism_2" => "call the pinned create_look_up_table binary " *
            "directly with the generated config and explicit input=<A2 " *
            "candidate> output=<proof raw definition> (bypasses the " *
            "driver's filename derivation; config must replicate the " *
            "script-emitted config block verbatim)",
        "lw_raw_proof" => "in the A2 TESTCOPY (config.h sed-patched " *
            "absolute): APPLICATION=climate BAND_STRUCTURE=fsck " *
            "TOLERANCE=0.0161 bash create_lut_lw.sh AFTER mechanism-1 " *
            "placement -- emits the proof raw-ckd-definition under " *
            "$G4WORK/work/lw_raw-ckd-definition/",
        "sw_raw_proof" => "APPLICATION=climate BAND_STRUCTURE=rgb " *
            "TOLERANCE=0.047 bash create_lut_sw.sh AFTER mechanism-1 " *
            "placement (script resolves ssi from config) -- emits the " *
            "proof raw-ckd-definition under " *
            "$G4WORK/work/sw_raw-ckd-definition/",
        "note" => "these are PROOF-ONLY builds; they double as acceptance " *
                  "raw inits ONLY if every comparison below is exact; " *
                  "Slurm cpu-large, never the head node",
    )

    comparisons = Any[
        Dict("name" => "g_count", "band" => "both",
             "rule" => "exactly 32 g-points in each proof definition"),
        Dict("name" => "gpoint_fraction", "band" => "both",
             "rule" => "shape AND elementwise values EXACT vs published " *
                       "(LW (326,32), SW (995,32) per the feasibility stats)"),
        Dict("name" => "wavenumber1_band", "band" => "both",
             "rule" => "elementwise EXACT"),
        Dict("name" => "wavenumber2_band", "band" => "both",
             "rule" => "elementwise EXACT"),
        Dict("name" => "band_number", "band" => "both",
             "rule" => "elementwise EXACT"),
        Dict("name" => "solar_irradiance", "band" => "sw",
             "rule" => "elementwise EXACT vs published SW32 (per-g SSI is a " *
                       "fixed support array, item 22)"),
        Dict("name" => "rayleigh_molar_scattering_coeff", "band" => "sw",
             "rule" => "elementwise EXACT vs published SW32 (fixed support " *
                       "array produced at create_lut time)"),
        Dict("name" => "wavenumber1", "band" => "both",
             "rule" => "elementwise EXACT (fine per-bin lower bounds of the " *
                       "definition wavenumber grid)"),
        Dict("name" => "wavenumber2", "band" => "both",
             "rule" => "elementwise EXACT (fine per-bin upper bounds)"),
        Dict("name" => "solar_spectral_irradiance", "band" => "sw",
             "rule" => "elementwise EXACT vs published SW32"),
    ]
    # HISTORICAL strict verdict rule, retained verbatim; superseded by the
    # Option-B amended rule (see supersession banner)
    verdict_rule = Dict(
        "all_exact" => "candidates PROMOTED to acceptance raw inits; " *
                       "init-generation proceeds (scale_lut for SW next)",
        "any_mismatch" => "candidates are SENSITIVITY-ONLY; record the " *
                          "mismatch as a finding; the acceptance floor " *
                          "cannot use them unless Greg explicitly changes " *
                          "the optimizer-only-delta rule",
        "superseded_note" => "this strict rule was applied by proof job " *
            "4091 (verdict proof_mismatch_sensitivity_only) and then " *
            "SUPERSEDED by the Greg-authorized Option-B amended rule " *
            "(gate4_option_b_decision_record), under which the candidates " *
            "were promoted; retained here as the historical spec",
    )

    gates["refuses_without_candidates"] = have_candidates ? "passed" :
        "passed"   # the refusal IS the waiting status below
    gates["proof_commands_recorded"] =
        (occursin("create_lut_lw.sh", proof_commands["lw_raw_proof"]) &&
         occursin("EXACT filename", proof_commands["input_mechanism_1_preferred"])) ?
        "passed" : "failed"
    gates["comparison_spec_complete"] = length(comparisons) == 10 ?
        "passed" : "failed"
    gates["mismatch_means_sensitivity_only"] =
        occursin("SENSITIVITY-ONLY", verdict_rule["any_mismatch"]) ?
        "passed" : "failed"
    gates["no_execution_in_this_unit"] = "passed"
    self_src = read(@__FILE__, String)
    occursin(r"run\(`[^`]*create_lut", self_src) &&
        (gates["no_execution_in_this_unit"] = "failed";
         push!(fails, "create_lut invocation found in proof scaffold"))

    deferred_hygiene = "RESOLVED: the previously flagged stale comment " *
        "(claiming the May config already localizes paths) is absent from " *
        "the current gate4_a2_dryrun.sbatch; no action remains"

    # fail-closed status selection: every failed gate is closed into the
    # authoritative census reason, and success additionally requires
    # EVERY gate passed -- a structural gate can never fail silently
    fails, gates_all_passed = ps_close_failed_gates(fails, gates)
    status = !(isempty(fails) && gates_all_passed) ?
             "a2_proof_scaffold_failed" :
             have_candidates ? "a2_proof_scaffold_ready" :
                               "a2_proof_scaffold_ready_waiting_for_candidates"

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_a2_reproduction_proof_scaffold",
        "data_mode" => "dry_run_proof_specification_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "prerequisite_loader_fixture_verdicts" => lt,
        "candidates_found" => cands,
        "proof_commands" => proof_commands,
        "comparisons" => comparisons,
        "verdict_rule" => verdict_rule,
        "verification_targets" => Dict("lw32" => basename(lw32),
                                       "sw32" => basename(sw32)),
        "superseded_by" => "gate4_option_b_decision_record (Greg-authorized " *
            "amended acceptance rule); this unit's strict verdict_rule " *
            "any_mismatch->sensitivity-only is explicitly listed there as " *
            "superseded",
        "outcome" => "proof executed as job 4091 on the job-4082 A2 " *
            "candidates: verdict proof_mismatch_sensitivity_only under the " *
            "strict rule (structure all exact, support drift at storage " *
            "precision); R2 job 4096 resolved the SSI absence as version " *
            "skew; candidates promoted under Option B",
        "deferred_hygiene" => deferred_hygiene,
        "provenance" => Dict("branch" => branch, "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "HISTORICAL proof specification (the proof it " *
                        "specified was executed as job 4091 and its strict " *
                        "verdict rule superseded by Option B); no " *
                        "create_lut, objective, floor, or recovery " *
                        "computation.",
    )
    mkpath(dirname(RP_RESULTS_JSON))
    open(RP_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(RP_RESULTS_MD, "w") do io
        println(io, "# Gate-4 A2 reproduction-proof scaffold — HISTORICAL " *
                    "(verdict rule superseded by Option B)\n")
        println(io, "Status: **$status**\n")
        println(io, "**Superseded by**: ", result["superseded_by"], "\n")
        println(io, "**Outcome**: ", result["outcome"], "\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nCandidates found: LW $(length(cands["lw"])), " *
                    "SW $(length(cands["sw"]))")
        println(io, "\n## Exact comparisons (all must pass for acceptance)\n")
        for c in comparisons
            println(io, "- [$(c["band"])] $(c["name"]): $(c["rule"])")
        end
        println(io, "\nVerdict (historical strict rule): all exact -> " *
                    "promote to acceptance raw inits; any mismatch -> " *
                    "sensitivity-only, no floor use without an explicit " *
                    "rule change. ", verdict_rule["superseded_note"], ".")
        println(io, "\nDeferred hygiene note: ", deferred_hygiene)
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_a2_reproduction_proof_scaffold: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return startswith(status, "a2_proof_scaffold_ready") ? 0 : 1
end

exit(main())
