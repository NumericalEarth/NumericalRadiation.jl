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
#
# 2026-08-13 fail-closed readiness (monitor-directed): the informational
# waiting-for-eval2 semantics are REMOVED. Readiness now requires the
# committed G2d flux completion ledger (coupled-byte snapshot; exact
# case/status/sha; source commit ancestry) AND full validation of all
# three live Eval2 targets (exact size + sha + full HDF5 schema via the
# validator extracted from the sha-pinned G2d sbatch; SW copies
# byte-identical). Anything less is g3_scoped_preflight_failed with a
# nonzero exit -- there is no waiting exit-0 path.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON
import SHA

const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"
const V12_BIN = "/shared/home/greg/ecckd-derived-flux-work/ecckd/src/ecckd/optimize_lut"
const V14_BIN = "/shared/home/greg/ecckd-derived-flux-work/ecckd-v1.4-23adaca/src/ecckd/optimize_lut"

const LW_INIT = "$G4WORK/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc"
const LW_INIT_SHA = "ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43"
const SW_INIT = "$G4WORK/work-v14/sw_raw-ckd-definition/ecckd-1.4_sw_scaled-ckd-definition_climate_rgb-tol0.047.nc"
const SW_INIT_SHA = "74d8be65226f081f3d2882520ab374ed102d73cc3dd43bb2fa7c5a5c27602d74"
const LW_GPTS = "$G4WORK/work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5"
const LW_GPTS_SHA = "c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e"
const SW_GPTS_V14 = "$G4WORK/work-v14/sw_gpoints/ecckd-1.4_sw_gpoints_climate_rgb-tol0.047.h5"
const SW_GPTS_SHA = "13dd686acd0c3ca2201775270f876ce3e3a326576b58b24323b5ce95659b9b57"
const SW_GPTS_TARGET = "$G4WORK/work/sw_gpoints/ecckd-1.2_sw_gpoints_climate_rgb-tol0.047.h5"
const V12_BIN_SHA = "6c3600fe6001d92e0d067cde1d57f19c82bae0c208a32dd2c48cd77031c05692"
const V14_BIN_SHA = "101e41ed77c83c81c138494a2b950bbffd12caad27b0c64028666550d7c30d65"
const SHIM_SO = "$G4WORK/tools/h5open_before_traps.so"
const SHIM_SO_SHA = "28003281a7f1c8470c1bfd94a654999a210581261a5c3e9cd662af2a13dd492f"
const ECCKD_SRC = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"

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

# fail-closed Eval2 readiness pins (from the verified G2d completion).
# Repo root derived from THIS source (checkout dir names are transient
# and must never be bound into evidence).
const PF_PROJECT_ROOT = dirname(@__DIR__)
const PF_LEDGER_JSON = validation_results_path("gate4_g2d_flux_completion_ledger.json")
const PF_LEDGER_CASE = "gate4_g2d_flux_completion_ledger"
const PF_LEDGER_STATUS = "g2d_flux_completed_verified"
const PF_LEDGER_SHA = "46ee8d2a2d6a3f662c3f937d8fec644e83b94fd2a4f21254c703b112e9dd9dab"
const PF_LEDGER_SRC = joinpath(PF_PROJECT_ROOT,
    "validation/gate4_g2d_flux_completion_ledger.jl")
const PF_LEDGER_SRC_SHA = "1729c820235293852860720af8921608f3d91c34e5c6a637ad222f1de4ac096a"
const PF_ANCESTOR_COMMIT = "7735a034ffbdcacc5c5892fab76a08d9cc083897"
const PF_G2D_SBATCH = validation_results_path("gate4_g2d_eval2_rel415_flux.sbatch")
const PF_G2D_SBATCH_SHA = "06c1a97d49e289cb29a462bb1f1fb750d650c170f6aab8d5ab333568f7e2329d"
const PF_LW_BYTES = 451045
const PF_LW_SHA = "e799eae4421afe12481533678963237198338b3979ec938c6e61c2759522d4bc"
const PF_SW_BYTES = 1817493
const PF_SW_SHA = "4ec6e8eb810dd4ad02f710dcbac4115f6d4d2002b28057ec68d20220a5b92291"

const GP_RESULTS_JSON = validation_results_path("gate4_g3_scoped_input_preflight.json")
const GP_RESULTS_MD = validation_results_path("gate4_g3_scoped_input_preflight.md")

sha256(p) = split(strip(read(`sha256sum $p`, String)))[1]

# nonthrowing streaming digest (Eval2 targets and pins)
pf_try_sha(p) = try
    isfile(p) || return nothing
    open(io -> bytes2hex(SHA.sha256(io)), p)
catch
    nothing
end

# coupled byte snapshot: one read supplies digest AND parsed content
function pf_snapshot(path)
    isfile(path) || return (ok = false, reason = "missing", sha = nothing,
                            data = nothing)
    bytes = try
        read(path)
    catch
        return (ok = false, reason = "unreadable", sha = nothing,
                data = nothing)
    end
    sha = bytes2hex(SHA.sha256(bytes))
    data = try
        JSON.parse(String(copy(bytes)))
    catch
        return (ok = false, reason = "unparseable (parse failure)",
                sha = sha, data = nothing)
    end
    data isa AbstractDict || return (ok = false,
        reason = "parses to a non-object (JSON null/array/scalar)",
        sha = sha, data = nothing)
    (ok = true, reason = "", sha = sha, data = data)
end

# guarded G2d completion-ledger classifier: exact case/status/byte-sha
# returns the OBSERVED sha/case/status from the SAME coupled snapshot
# (one read supplies digest and parse) so expected-vs-observed evidence
# can be recorded without a second read
function pf_classify_g2d_ledger(path; expected_case = PF_LEDGER_CASE,
                                expected_status = PF_LEDGER_STATUS,
                                expected_sha = PF_LEDGER_SHA)
    snap = pf_snapshot(path)
    obs_case = snap.data === nothing ? nothing : get(snap.data, "case", nothing)
    obs_status = snap.data === nothing ? nothing : get(snap.data, "status", nothing)
    base = (observed_sha = snap.sha, observed_case = obs_case,
            observed_status = obs_status)
    snap.ok || return merge((ok = false, class = snap.reason,
        reason = "G2d completion ledger $(snap.reason)"), base)
    obs_case == expected_case || return merge((ok = false,
        class = "case mismatch",
        reason = "G2d completion ledger case mismatch (got $(repr(obs_case)))"),
        base)
    obs_status == expected_status || return merge((ok = false,
        class = "not verified",
        reason = "G2d completion ledger status $(repr(obs_status)) != " *
                 "$expected_status"), base)
    snap.sha == expected_sha || return merge((ok = false, class = "sha drift",
        reason = "G2d completion ledger sha $(snap.sha) != pinned"), base)
    merge((ok = true, class = "green", reason = ""), base)
end

# single observation per path (present/size/sha captured ONCE); issue
# classification, inventory, and pins all consume the same observation
pf_observe(path) = (present = isfile(path),
                    size = isfile(path) ? Int(filesize(path)) : nothing,
                    sha = pf_try_sha(path))

function pf_obs_issues(obs, path, size, sha)
    iss = String[]
    if !obs.present
        push!(iss, "missing: $path")
        return iss
    end
    obs.size == size || push!(iss, "size $(obs.size) != $size: $path")
    obs.sha == sha || push!(iss, "sha mismatch: $path")
    iss
end

pf_file_issues(path, size, sha) =
    pf_obs_issues(pf_observe(path), path, size, sha)

# full HDF5 schema validator, extracted from the sha-pinned G2d sbatch;
# returns (val, observed_sha) so the pin evidence reuses ONE observation
function pf_extract_validator()
    obs_sha = pf_try_sha(PF_G2D_SBATCH)
    obs_sha == PF_G2D_SBATCH_SHA || return (val = nothing, sha = obs_sha)
    text = read(PF_G2D_SBATCH, String)
    m1 = findfirst("cat > \"\$VAL\" <<'PYEOF'\n", text)
    m2 = findfirst("\nPYEOF\n", text)
    (m1 === nothing || m2 === nothing) &&
        return (val = nothing, sha = obs_sha)
    p = joinpath(mktempdir(), "g2d_validator.py")
    write(p, text[last(m1)+1:first(m2)])
    (val = p, sha = obs_sha)
end

pf_schema_ok(val, mode, path) =
    val !== nothing && success(pipeline(`python3 $val $mode $path`,
                                        stdout=devnull, stderr=devnull))

# ready/failure selection: fail-closed (no waiting state exists)
pf_status(all_ok) = all_ok ? "g3_scoped_preflight_ready" :
                             "g3_scoped_preflight_failed"

function pf_fixtures(val)
    t = Dict{String, Bool}()
    fx = mktempdir()
    shaof(p) = bytes2hex(SHA.sha256(read(p)))
    cls(p; kw...) = pf_classify_g2d_ledger(p; kw...)
    # ledger refusal classes
    t["ledger_missing_refuses"] =
        cls(joinpath(fx, "absent.json")).class == "missing"
    p = joinpath(fx, "bad.json"); write(p, "{nope")
    t["ledger_unparseable_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "unparseable (parse failure)"
    p = joinpath(fx, "arr.json"); write(p, "[1]")
    t["ledger_non_object_refuses"] =
        cls(p; expected_sha = shaof(p)).class ==
        "parses to a non-object (JSON null/array/scalar)"
    p = joinpath(fx, "case.json")
    write(p, JSON.json(Dict("case" => "x", "status" => PF_LEDGER_STATUS)))
    t["ledger_case_mismatch_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "case mismatch"
    p = joinpath(fx, "st.json")
    write(p, JSON.json(Dict("case" => PF_LEDGER_CASE,
                            "status" => "g2d_flux_ledger_refused")))
    t["ledger_wrong_status_refuses"] =
        cls(p; expected_sha = shaof(p)).class == "not verified"
    p = joinpath(fx, "green.json")
    write(p, JSON.json(Dict("case" => PF_LEDGER_CASE,
                            "status" => PF_LEDGER_STATUS)))
    t["ledger_wrong_sha_refuses"] =
        cls(p; expected_sha = "0" ^ 64).class == "sha drift"
    t["ledger_green_accepted"] = cls(p; expected_sha = shaof(p)).ok
    # Eval2 drift classes on tmp files
    p = joinpath(fx, "t.h5"); write(p, "DATA")
    t["eval2_missing_refuses"] =
        !isempty(pf_file_issues(joinpath(fx, "no.h5"), 4, "0" ^ 64))
    t["eval2_size_drift_refuses"] = !isempty(pf_file_issues(p, 5, shaof(p)))
    t["eval2_hash_drift_refuses"] = !isempty(pf_file_issues(p, 4, "0" ^ 64))
    t["eval2_good_accepted"] = isempty(pf_file_issues(p, 4, shaof(p)))
    # copy drift: second copy expected at the SAME pin
    q = joinpath(fx, "t2.h5"); write(q, "DIFF")
    t["eval2_copy_drift_refuses"] = !isempty(pf_file_issues(q, 4, shaof(p)))
    # schema drift, evidence-based: LW validator must reject the SW file
    t["eval2_schema_drift_refuses"] =
        val !== nothing && !pf_schema_ok(val, "lw", SW_EVAL2)
    # ready/failure selection
    t["status_ready_selection"] = pf_status(true) == "g3_scoped_preflight_ready"
    t["status_failed_selection"] = pf_status(false) == "g3_scoped_preflight_failed"
    t
end

function main()
    fails = String[]
    gates = Dict{String, String}()
    inv = Any[]

    # ALWAYS fail-closed: every checked input records a failure on any
    # deficiency (the former informational waiting branch is deleted)
    check(label, path; sha=nothing, exec=false) = begin
        present = isfile(path) && filesize(path) > 0
        sha_ok = present && sha !== nothing ? (sha256(path) == sha) : nothing
        exec_ok = exec ? (present && Sys.isexecutable(path)) : nothing
        push!(inv, Dict("input" => label, "path" => path,
            "present" => present,
            (sha === nothing ? () : ("sha256_matches" => sha_ok,))...,
            (exec ? ("executable" => exec_ok,) : ())...))
        ok = present && (sha === nothing || sha_ok === true) &&
             (!exec || exec_ok === true)
        ok || push!(fails, "missing/mismatched/not-executable: $label")
        ok
    end

    # --- LW actual inputs ---
    gates["lw_init"] = check("LW raw init", LW_INIT; sha=LW_INIT_SHA) ? "passed" : "failed"
    gates["lw_gpoints"] = check("LW gpoints", LW_GPTS; sha=LW_GPTS_SHA) ? "passed" : "failed"
    lw_train_bools = [check("LW flux $s",
        joinpath(CKDMIP_ROOT, "evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_$s.h5"))
        for s in LW_TRAIN]
    lw_train_ok = all(lw_train_bools)
    gates["lw_training_fluxes_20"] = lw_train_ok ? "passed" : "failed"
    gates["lw_optimize_binary"] = check("v1.2 optimize_lut", V12_BIN; sha=V12_BIN_SHA, exec=true) ? "passed" : "failed"

    # --- SW actual inputs ---
    gates["sw_init"] = check("SW scaled init", SW_INIT; sha=SW_INIT_SHA) ? "passed" : "failed"
    sw_resolved = try
        islink(SW_GPTS_V14) ? realpath(SW_GPTS_V14) : nothing
    catch; nothing end   # realpath throws on a dangling link: fail-closed
    sw_gpts_ok = sw_resolved !== nothing && isfile(sw_resolved) &&
                 sw_resolved == SW_GPTS_TARGET &&
                 sha256(sw_resolved) == SW_GPTS_SHA
    push!(inv, Dict("input" => "SW gpoints v1.4 symlink", "path" => SW_GPTS_V14,
        "present" => sw_gpts_ok,
        "resolves_to" => sw_resolved === nothing ? "BROKEN/DANGLING" : sw_resolved,
        "resolved_path_equals_accepted_candidate" =>
            sw_resolved == SW_GPTS_TARGET,
        "resolved_target_sha256_matches" => sw_gpts_ok))
    gates["sw_gpoints_symlink"] = sw_gpts_ok ? "passed" : "failed"
    sw_gpts_ok || push!(fails, "SW gpoints symlink missing/dangling/wrong-target/hash-mismatch")
    sw_train_bools = [check("SW rgb flux $s",
        joinpath(CKDMIP_ROOT, "evaluation1/sw_fluxes-rgb/ckdmip_evaluation1_sw_fluxes-rgb_$s.h5"))
        for s in SW_TRAIN]
    sw_train_ok = all(sw_train_bools)
    gates["sw_training_fluxes_16"] = sw_train_ok ? "passed" : "failed"
    gates["sw_optimize_binary"] = check("v1.4 optimize_lut", V14_BIN; sha=V14_BIN_SHA, exec=true) ? "passed" : "failed"

    # --- eval2 TRAINING_BOTH pair: FAIL-CLOSED readiness (no waiting) ---
    vext = pf_extract_validator()
    val = vext.val
    val_sha = vext.sha
    gates["g2d_sbatch_pin_and_validator"] = val === nothing ? "failed" : "passed"
    val === nothing &&
        push!(fails, "G2d sbatch sha drift or validator heredoc missing")
    tests = pf_fixtures(val)
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))
    led = pf_classify_g2d_ledger(PF_LEDGER_JSON)
    gates["g2d_completion_ledger_green"] = led.ok ? "passed" : "failed"
    led.ok || push!(fails, led.reason)
    src_sha = pf_try_sha(PF_LEDGER_SRC)
    gates["g2d_ledger_source_pin"] =
        src_sha == PF_LEDGER_SRC_SHA ? "passed" : "failed"
    gates["g2d_ledger_source_pin"] == "passed" ||
        push!(fails, "G2d ledger source sha drift")
    anc = try
        success(`git -C $PF_PROJECT_ROOT merge-base --is-ancestor $PF_ANCESTOR_COMMIT HEAD`)
    catch; false end
    gates["g2d_commit_ancestry"] = anc ? "passed" : "failed"
    anc || push!(fails, "reviewed G2d completion commit not an ancestor of HEAD")
    # all THREE live targets: exact size + sha + full schema; SW copies
    # byte-identical (both bound to the same pinned digest)
    e2_specs = [("eval2 LW rel-415 flux (work)", LW_EVAL2, PF_LW_BYTES,
                 PF_LW_SHA, "lw"),
                ("eval2 SW rgb rel-415 flux (work-v14)", SW_EVAL2,
                 PF_SW_BYTES, PF_SW_SHA, "sw"),
                ("eval2 SW rgb rel-415 flux (work alt)", SW_EVAL2_ALT,
                 PF_SW_BYTES, PF_SW_SHA, "sw")]
    e2_issues = String[]
    e2_obs = Dict{String, Any}()
    for (label, path, size, sha, mode) in e2_specs
        obs = pf_observe(path)   # ONE observation drives everything below
        e2_obs[path] = obs
        iss = pf_obs_issues(obs, path, size, sha)
        schema_ok = isempty(iss) && pf_schema_ok(val, mode, path)
        (isempty(iss) && !schema_ok) && push!(iss, "schema failed: $path")
        append!(e2_issues, iss)
        push!(inv, Dict("input" => label, "path" => path,
            "present" => obs.present,
            "observed_bytes" => obs.size,
            "observed_sha256" => obs.sha,
            "size_matches" => obs.present && obs.size == size,
            "sha256_matches" => obs.sha == sha,
            "schema_valid" => schema_ok))
    end
    append!(fails, e2_issues)
    eval2_ready = isempty(e2_issues) && led.ok && anc &&
                  gates["g2d_ledger_source_pin"] == "passed" &&
                  val !== nothing
    gates["eval2_training_both_pair"] = eval2_ready ? "passed" : "failed"
    gates["sw_copies_byte_identical"] =
        (e2_obs[SW_EVAL2].sha == PF_SW_SHA &&
         e2_obs[SW_EVAL2_ALT].sha == PF_SW_SHA) ? "passed" : "failed"

    # --- executor requirements (verified, not asserted) ---
    # FP shim artifact: optimize_lut.cpp:51 enables FP traps (4098 ledger);
    # the executor must wrap optimize_lut with the H5open-preinit LD_PRELOAD
    # shim. The .so from job 4099 is hash-pinned here; an OPTIMIZER-SPECIFIC
    # wrapper must still be generated by the executor (the scale wrapper is
    # deliberately NOT checked as an executable input).
    gates["fp_shim_so_hash"] =
        check("H5open-preinit shim .so (4099)", SHIM_SO; sha=SHIM_SO_SHA) ?
        "passed" : "failed"
    # runtime audit: zero executable idealized references in the pinned
    # optimizer scripts (comments stripped), so Path D cleanup cannot
    # affect G3; this preflight reads nothing under idealized/
    ideal_hits = String[]
    for scr in ("optimize_lut_lw.sh", "optimize_lut_sw.sh")
        for (i, l) in enumerate(eachline(joinpath(ECCKD_SRC, "test", scr)))
            startswith(strip(l), "#") && continue
            occursin(r"idealized"i, l) && push!(ideal_hits, "$scr:$i: $(strip(l))")
        end
    end
    gates["no_idealized_dependency"] = isempty(ideal_hits) ? "passed" : "failed"
    isempty(ideal_hits) ||
        push!(fails, "executable idealized refs: " * join(ideal_hits, "; "))
    # drift gate: expected basename sets derived from the PINNED scripts'
    # default-order case blocks (TRAINING + relative_to; SW rgb rewrite
    # applied) must equal the hardcoded 20/16 lists above
    function pinned_flux_set(script, band, passes)
        src = read(joinpath(ECCKD_SRC, "test", script), String)
        names = Set{String}()
        for p in passes
            m = match(Regex("^\\s{4}" * p * "\\)\$(.*?)^\\s{8};;", "ms"), src)
            m === nothing && match(Regex(p * "\\)(.*?);;", "s"), src) !== nothing &&
                (m = match(Regex(p * "\\)(.*?);;", "s"), src))
            m === nothing && continue
            for fm in eachmatch(Regex("ckdmip_evaluation1_" * band *
                                      "_fluxes_[A-Za-z0-9.-]+\\.h5"), m.captures[1])
                push!(names, fm.match)
            end
        end
        names
    end
    lw_pinned = pinned_flux_set("optimize_lut_lw.sh", "lw",
        ["relative-base", "relative-ch4", "relative-n2o", "relative-cfc"])
    sw_pinned_raw = pinned_flux_set("optimize_lut_sw.sh", "sw",
        ["relative-base", "relative-ch4", "relative-n2o"])
    sw_pinned = Set(replace(n, "sw_fluxes_" => "sw_fluxes-rgb_") for n in sw_pinned_raw)
    lw_expected = Set("ckdmip_evaluation1_lw_fluxes_$s.h5" for s in LW_TRAIN)
    sw_expected = Set("ckdmip_evaluation1_sw_fluxes-rgb_$s.h5" for s in SW_TRAIN)
    gates["expected_sets_match_pinned_scripts"] =
        (lw_pinned == lw_expected && sw_pinned == sw_expected) ? "passed" : "failed"
    if lw_pinned != lw_expected || sw_pinned != sw_expected
        push!(fails, "training-set drift vs pinned scripts: lw only-pinned=" *
            join(sort(collect(setdiff(lw_pinned, lw_expected))), ",") *
            " lw only-hardcoded=" *
            join(sort(collect(setdiff(lw_expected, lw_pinned))), ",") *
            " sw only-pinned=" *
            join(sort(collect(setdiff(sw_pinned, sw_expected))), ",") *
            " sw only-hardcoded=" *
            join(sort(collect(setdiff(sw_expected, sw_pinned))), ","))
    end

    # FAIL-CLOSED selection: ready ONLY when every gate passed and no
    # failure was recorded; there is no waiting state
    status = pf_status(all(v -> v == "passed", values(gates)) &&
                       isempty(fails))

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    ghead = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_g3_scoped_input_preflight",
        "data_mode" => "dry_run_input_manifest_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "fixture_verdicts" => tests,
        "inventory" => inv,
        "readiness_pins" => Dict(
            "g2d_completion_ledger" => Dict(
                "path" => PF_LEDGER_JSON,
                "expected_case" => PF_LEDGER_CASE,
                "expected_status" => PF_LEDGER_STATUS,
                "expected_sha256" => PF_LEDGER_SHA,
                "observed_case" => led.observed_case,
                "observed_status" => led.observed_status,
                "observed_sha256" => led.observed_sha,
                "classifier_verdict" => led.ok ? "green" : led.class),
            "g2d_ledger_source" => Dict(
                "expected_sha256" => PF_LEDGER_SRC_SHA,
                "observed_sha256" => src_sha),
            "g2d_commit_ancestor" => Dict(
                "expected" => PF_ANCESTOR_COMMIT, "observed" => anc),
            "g2d_sbatch" => Dict(
                "expected_sha256" => PF_G2D_SBATCH_SHA,
                "observed_sha256" => val_sha),
            "eval2_targets" => Dict(
                "lw_bytes" => PF_LW_BYTES, "lw_sha256" => PF_LW_SHA,
                "sw_bytes" => PF_SW_BYTES, "sw_sha256" => PF_SW_SHA,
                "observed_lw_sha256" => e2_obs[LW_EVAL2].sha,
                "observed_sw_v14_sha256" => e2_obs[SW_EVAL2].sha,
                "observed_sw_alt_sha256" => e2_obs[SW_EVAL2_ALT].sha)),
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
    check_only = get(ENV, "G3_PREFLIGHT_CHECK_ONLY", "0") == "1"
    if !check_only
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
        println(io, "\nInventory: $n_present/$(length(inv)) inputs present; " *
                    "Eval2 readiness is FAIL-CLOSED (ledger + " *
                    "size/sha/schema/copy gates; no waiting state).")
        println(io, "\nScope: ", result["scope_rationale"])
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$ghead` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    end  # !check_only (no-write mode for execution-time require-ready)
    println("gate4_g3_scoped_input_preflight: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "g3_scoped_preflight_ready" ? 0 : 1
end

exit(main())
