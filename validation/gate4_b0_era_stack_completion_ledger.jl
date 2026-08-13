# Gate-4 B0 ERA-STACK COMPLETION LEDGER (evidence unit; writes nothing
# except validation/results/gate4_b0_era_stack_completion_ledger.{json,md}
# plus transient private temp fixtures/snapshots under mktempdir; ZERO
# campaign/canonical writes).
# Closes the B0 bundled TARGET-ERA STACK viability experiment (job 4546,
# attempt 3) with strict receipts/log/schema/hash evidence plus the
# pinned external comparator, and records the two failed attempts
# (4540, 4545) content-coupled.
#
# BINDING FRAMING (monitor corrections 2026-08-13): B0 held
# init/g-points/training/config FIXED and swapped in the bundled
# v1.0/b42e5c0 stack -- a full executable source version change (incl.
# optimize_lut/ckd_model/lbl_fluxes plus average_optical_depth and
# build/script changes; calc_cost_function_lw/radiative_transfer_lw
# identical across b42e5c0..23adaca), plus the old in-tree solve_lbfgs
# backend and no v1.2 bounds, CONFOUNDED together. The experiment is
# NEVER described as single-variable, mechanism-isolated, or
# backend-confirmed. Explicit exception: the literal token 'isolation'
# persists only inside legacy filenames/case identifiers
# (gate4_b0_era_lbfgs_isolation_*) retained for path stability.
#
# BINDING BOUNDED INTERPRETATION (monitor, 2026-08-13, verbatim scope):
# B0 execution completed and the bundled target-era stack is viable,
# but its fixed-input raw2 still fails the 1.05 objective gate and
# offers no material recovery versus the v1.2 raw2. This is ONE
# deterministic bundled comparison with confounded source/backend/
# bounds; it is never phrased as statistically equivalent/
# indistinguishable, backend disproven, hypothesis collapsed, or
# causality shifted.
#
# COMPLETION STATUS IS INDEPENDENT OF SCIENTIFIC OUTCOME:
#   b0_run_completed_verified   -- every evidence group green (exit 0)
#   b0_completion_ledger_refused -- ANY evidence discrepancy (exit 1)
# The objective/delta section is reporting, never a completion gate;
# the comparator-INTEGRITY gates (pinned code/dependency chain, pinned
# case inputs, bit-exact recomputation of every reference value and of
# the reviewed era value) do gate, because they verify the evidence
# pipeline rather than judge the science.
#
# WRITE FOOTPRINT: this unit writes nothing except its own JSON/MD
# results plus TRANSIENT PRIVATE temp fixtures/snapshots (mktempdir);
# it performs ZERO campaign/canonical writes.

include(joinpath(@__DIR__, "validation_results.jl"))
include(joinpath(@__DIR__, "ecckd_published_model_accuracy.jl"))

import JSON
using SHA: sha256

const BL_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
const BL_G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const BL_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"

# reviewed provenance chain
const BL_REVIEWED_COMMIT = "28f7274666effe3a40b401bd110d83e3840faa0f"
const BL_GEN_SRC = joinpath(BL_PROJECT_ROOT,
    "validation/gate4_b0_era_lbfgs_isolation_checkpoint.jl")
const BL_GEN_SRC_SHA = "259f7b32b6cba4fd85ea4e1646dd0c89c6977dae11613a706a44b106b9569b55"
const BL_SBATCH = validation_results_path("gate4_b0_lw_era_lbfgs.sbatch")
const BL_SBATCH_SHA = "87a529e865633133e9f6d548720c597c5e1021a2143af1a52c17c590ac76e575"

# fixed evidence timestamp = job 4546 EndTime (never wall-clock)
const BL_EVIDENCE_TIME = "2026-08-13T20:38:33Z"

# --- attempt registry pins ------------------------------------------------------
const BL_SBATCH_ABS = joinpath(BL_PROJECT_ROOT,
    "validation/results/gate4_b0_lw_era_lbfgs.sbatch")
const BL_SUBMIT_LINE = "sbatch --parsable validation/results/gate4_b0_lw_era_lbfgs.sbatch"

bl_receipt_pair(job) = (
    "$BL_LOG_DIR/g4-b0-lw-$job-scontrol-final-session40.txt",
    "$BL_LOG_DIR/g4-b0-lw-$job-scontrol-final-agent42.txt")

bl_expect(job, state, reason, exit_, runtime, submit, start, endt) = Dict(
    "JobId" => string(job), "JobName" => "g4-b0-lw-era-lbfgs",
    "JobState" => state, "Reason" => reason,
    "ExitCode" => exit_, "DerivedExitCode" => "0:0",
    "Restarts" => "0", "RunTime" => runtime,
    "SubmitTime" => submit, "StartTime" => start, "EndTime" => endt,
    "Command" => BL_SBATCH_ABS, "SubmitLine" => BL_SUBMIT_LINE,
    "WorkDir" => BL_PROJECT_ROOT,
    "StdOut" => "$BL_LOG_DIR/g4-b0-lw-$job.log")

const BL_A4540_RECEIPT_SHA = "b9e7542d21085f3fb8af9a63d4234e9f78768124b6d91e86e8a41b9591f0e79d"
const BL_A4540_LOG_SHA = "6c72105b1a748c12dd5d85232c0898443f9840af90178aecf55815f4b3f9b284"
const BL_A4540_EXPECT = bl_expect(4540, "FAILED", "NonZeroExitCode",
    "141:0", "00:00:02", "2026-08-13T19:19:31", "2026-08-13T19:22:38",
    "2026-08-13T19:22:40")

const BL_A4545_RECEIPT_SHA = "6f3632adab027e05ace8095a06ab4de62fe6cd4a62ccc2e514c4f2eb62f9ddad"
const BL_A4545_LOG_SHA = "ccad0ca47f096ad74aead4aa0634c1a40acf741e17f5e5ef63191dbdf91b59d9"
const BL_A4545_REFUSAL_LINE = "REFUSED: Adept LBFGS string present in era binary"
const BL_A4545_EXPECT = bl_expect(4545, "FAILED", "NonZeroExitCode",
    "68:0", "00:00:46", "2026-08-13T19:37:23", "2026-08-13T19:40:38",
    "2026-08-13T19:41:24")

const BL_A4546_RECEIPT_SHA = "31c4f054320997be7950e623018e18819cfcea43965d6405e34c63c9af5ad0eb"
const BL_A4546_LOG = "$BL_LOG_DIR/g4-b0-lw-4546.log"
const BL_A4546_LOG_SHA = "b6aac36459f86310aba8a93cf2382c200f1736b88449641cd053b73419c4c50b"
const BL_A4546_EXPECT = bl_expect(4546, "COMPLETED", "None",
    "0:0", "00:37:54", "2026-08-13T19:57:44", "2026-08-13T20:00:39",
    "2026-08-13T20:38:33")

# --- job 4546 log contract ------------------------------------------------------
const BL_STAGES = [
    "=== B0-lw stage 0a: gate-code identity (verify BEFORE sourcing) ===",
    "=== B0-lw stage 0b: quota health (read-only) ===",
    "=== B0-lw stage 0c: era-source identity (pinned commit/tree/archive; read-only on the shared repo) ===",
    "=== B0-lw stage 0d: exact size+sha pin of EVERY input + toolchain versions ===",
    "=== B0-lw stage 0e: B0 experiment lock (duplicate-diagnosis guard) ===",
    "=== B0-lw stage 1: job-private RUNROOT + scientific-input snapshot ===",
    "=== B0-lw stage 2: pinned era source extraction (git archive; job-private; no worktree) ===",
    "=== B0-lw stage 3: era build (autoreconf + pinned configure argv; config.log preserved in RUNROOT) ===",
    "=== B0-lw stage 4: optimizer wrapper (Netlib preload + FP-trap shim; env-only) ===",
    "=== B0-lw stage 5: isolated v1.2 testcopy (exact 4515 config overrides; era binary via wrapper) ===",
    "=== B0-lw stage 5b: controlled schema-open probe (max_iterations=1; REFUSES rather than strips) ===",
    "=== B0-lw stage 6: era relative-base run (3000 iterations / 0.02 criterion; all writes under RUNROOT) ===",
    "=== B0-lw stage 7: private outputs (independent schema verification; ZERO canonical writes by design) ==="]
const BL_DONE_MARK = "=== B0-lw done 2026-08-13T20:38:33Z ==="
const BL_PROBE_PASSED = "schema-open probe PASSED: old reader accepted " *
    "the v1.2 init with min/max arrays present (no strip needed)"
const BL_RAW2_VERIFIED = "raw2 independent schema/finite verification passed"
# ERROR/FATAL/FAILED case-sensitive (benign lowercase "error covariance"
# lines are expected); verified ZERO matches on the clean 4546 log
const BL_FAILURE_RE = r"REFUSED|SCHEMA-INVALID|sha mismatch|MISSING/nonexecutable|[Qq]uota exceeded|CANCELLED|slurmstepd: error|Traceback \(most recent call last\)|\bERROR\b|\bFATAL\b|\bFAILED\b|CHILD KILLED|CHILD FAILED|SIGFPE|Floating point exception"

# --- RUNROOT artifacts (job 4546; preserved forensics) --------------------------
const BL_RUNROOT = "$BL_G4WORK/g4-diag/4546/lw-b0"
const BL_RAW2 = "$BL_RUNROOT/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
const BL_RAW2_BYTES = 865748
const BL_RAW2_SHA = "92f7be59bac9ae5cca74d4110bf878b3bbf50ff0ba5f45d1de1d77ab8cd8fa1a"
const BL_PROBE_LOG = "$BL_RUNROOT/probe-run.log"
const BL_PROBE_LOG_SHA = "3a67ae9ca9b29171d0c24983c40783b563cf02aac1388a523311b429113b2ead"
const BL_BASE_LOG = "$BL_RUNROOT/b0-base-run.log"
const BL_BASE_LOG_SHA = "7cd0309ae5aecd312ca4dcb01d6e71175ee4ce644717daffbb7ed8b957eee6e5"
const BL_CONFIG_LOG = "$BL_RUNROOT/src/ecckd-b42e5c0/config.log"
const BL_CONFIG_LOG_BYTES = 37851
const BL_CONFIG_LOG_SHA = "4ce8f345a35e70f5749d53f406df82fecf4146be15dee0dcf8a5ba182fc0bbba"
const BL_ERA_BLOBS = [
    ("$BL_RUNROOT/src/ecckd-b42e5c0/src/ecckd/optimize_lut.cpp", 8850,
     "c0ec54b57c25be734f7dcde1d1afadd812df73e188d8f152b465390b0bb519a9"),
    ("$BL_RUNROOT/src/ecckd-b42e5c0/src/ecckd/solve_lbfgs.cpp", 5786,
     "c10dec6bd4bdb6b3589ca0e2fa82c48886384ed8213d67c873c7040a70807f4a"),
    ("$BL_RUNROOT/src/ecckd-b42e5c0/src/lbfgs/lbfgs.c", 41557,
     "2f0e2a1a8b1bb278e17691ce65d0421d518d5d05c7efc41052bd8f91633e6e3f"),
    ("$BL_RUNROOT/src/ecckd-b42e5c0/test/optimize_lut_lw.sh", 11051,
     "06e7fb62a17cef5106ade44c12a54618006fe8a966402c8cf31200a2e7e6e906"),
    ("$BL_RUNROOT/src/ecckd-b42e5c0/configure.ac", 1702,
     "30d590aa8240f2760f0ee68bdd34ac0b8041ba299124d00667f9cb0d4697f260")]
const BL_PROBE_RAW2 = "$BL_RUNROOT/probe-work/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
const BL_PROBE_RAW2_BYTES = 865808
const BL_PROBE_RAW2_SHA = "f451cf1a65317f19cc6773558e672064161b4f9d58e88c09c764687e29db067a"

# per-file runtime bindings
const BL_ERA_BANNER = "Optimizing coefficients with LBFGS algorithm: " *
    "max iterations = 3000, convergence criterion = 0.02"
const BL_PROBE_BANNER = "Optimizing coefficients with LBFGS algorithm: " *
    "max iterations = 1, convergence criterion = 0.02"
const BL_GAS_BANNER = "Optimizing coefficients of: composite h2o o3 co2"
const BL_FIRST_ITER = "Iteration 1: cost function = 1906.44, gradient norm = 788.674"
const BL_FINAL_ITER = "Iteration 3000: cost function = 16.7789, gradient norm = 0.0825603"
const BL_CONV_LINE = "Convergence status: Maximum iterations reached"
const BL_COV_SEQ = [
    "  Creating 318x318 error covariance matrix for COMPOSITE",
    "  Creating 3816x3816 error covariance matrix for H2O",
    "  Creating 318x318 error covariance matrix for O3",
    "  Creating 318x318 error covariance matrix for CO2"]

# --- comparator pins (monitor-verified 2026-08-13) ------------------------------
# HARDENING (monitor contract): the three non-published reference
# objectives are NEVER unexplained numeric constants -- every reference
# INPUT is content-pinned (exact size+sha), evaluated from a coupled
# private snapshot through the identical comparator path, and the
# recomputed objective must equal the reviewed value BIT-EXACT. The
# SAME pinned published SW snapshot is used for every swap evaluation.
const BL_PUB_LW = official_ecckd_definition_path(:longwave_32)
const BL_PUB_LW_BYTES = 869280
const BL_PUB_LW_SHA = "6087f62f9052653f8e7dbee26cef8bf1977c2516669a169bee8d110b62912ed9"
const BL_PUB_SW = official_ecckd_definition_path(:shortwave_32)
const BL_PUB_SW_BYTES = 851724
const BL_PUB_SW_SHA = "49abc7bf88b80252e4f9934f8659d108ffee6a101124b2fd080f2eb65d144eb3"
# (name, lw_input_path, size, sha, reviewed objective)
const BL_REF_INPUTS = [
    ("raw_init",
     "$BL_G4WORK/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc",
     2413144,
     "ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43",
     102.67056437657112),
    ("v12_raw2",
     "$BL_G4WORK/g3-runs/4515/lw/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
     2415168,
     "4205489923dbc50c3c148a06f20e5781b3f1dbeb5a13d55d36b460c5f7b4378c",
     22.791293464348826),
    ("recovered_final_lw",
     "$BL_G4WORK/work/lw_ckd-definition/ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc",
     872004,
     "a3d93d3eb4e69894862fad682563d25a5636e7dbbcc59c197ecaa1cceb6f24b4",
     22.824890243604344),
    ("published_pair", BL_PUB_LW, BL_PUB_LW_BYTES, BL_PUB_LW_SHA,
     0.18218645425029933)]
const BL_REFS = [(n, v) for (n, _, _, _, v) in BL_REF_INPUTS]
const BL_PUBLISHED_BASELINE = 0.18218645425029933
# reviewed era-raw2 swap objective; reproduction must be bit-exact
# (comparator-INTEGRITY gate: verifies the evidence pipeline, never a
# scientific pass/fail judgement)
const BL_ERA_EXPECTED = 22.788012978663616

# --- comparator code/dependency/input chain pins (fail-closed BEFORE any
# --- objective is accepted; monitor contract 2026-08-13) ------------------------
const BL_CODE_PINS = [
    ("validation/ecckd_published_model_accuracy.jl",
     "e6a10832650e668d88e9e903f222ba130d1e549489a637fbb75c67d1e0520446"),
    ("validation/reduced_ecckd_accuracy.jl",
     "a62520b88f460da681e7fb94eb0d852c863248f98c3cfe1dbaf49b46c8843e02"),
    ("validation/validation_results.jl",
     "60fbaa93cf5f7e34eac2fcf6e054ae4caaf99c2e4e0a63a6c74aa74eeff31d12"),
    ("validation/write_ecrad_candidates.jl",
     "89a2cf69ca036a1762418853f72a09fd352fbe9904adf6c9f10eadbcaeb0c267"),
    ("validation/ecrad_reference_manifest.jl",
     "6bf4787a7fa2f5057217562d423dd6337dbf9702cfe29245276f6205fe1e6b23"),
    ("test/Project.toml",
     "9136a5f68b97123017182b5afaf30c93148188a0ea8681ac3d17a808f6012ef0"),
    ("test/Manifest.toml",
     "cf9f318d43221280a8ca1116fbfea20d66678267f4e9d5dd1bdf519093ceb186"),
    # root Project.toml pinned by CONTENT: a clean later commit could
    # change it while HEAD:src stays identical (monitor blocker 1)
    ("Project.toml",
     "e3921c81ac9c8f6f6d2210f59e6195399643b4c8f66625b59b1d950da3493058")]
# tracked src/Project state must be EXACTLY the reviewed tree (never
# merely an ancestor): HEAD:src tree hash + clean porcelain status
const BL_SRC_TREE = "7eaf80136e313c073416a815334493fc3b5434e7"
# the two comparator case inputs, coupled-snapshot pinned; the SAME
# snapshot set backs every objective evaluation
const BL_CASE_INPUTS = [
    ("ecckd_clear_sky_tropical_column",
     joinpath(BL_PROJECT_ROOT,
              "validation/reference/ecrad/ecckd_clear_sky_tropical_column.nc"),
     207210,
     "3a1634b7c7b4e22ae4064ace9826ac76b6810fb4074a5437bfd30b5c911e68e7"),
    ("ecckd_rcemip_style_column_subset",
     joinpath(BL_PROJECT_ROOT,
              "validation/reference/ecrad/ecckd_rcemip_style_column_subset.nc"),
     612490,
     "8c4a6974d74d09ae5f6679f76495538d1b9812edada7d87b1ed6737303710db3")]
# hard-coded comparator water-vapour mole fraction; the env override is
# deliberately NEVER read (monitor contract)
const BL_H2O = 0.005

# exact 31-name variable census of the pinned era raw2 (monitor
# contract); every numeric variable must be readable/nonempty/finite
const BL_RAW2_VARS = sort([
    "band_number", "cfc11_conc_dependence_code",
    "cfc11_molar_absorption_coeff", "cfc12_conc_dependence_code",
    "cfc12_molar_absorption_coeff", "ch4_conc_dependence_code",
    "ch4_molar_absorption_coeff", "ch4_reference_mole_fraction",
    "co2_conc_dependence_code", "co2_molar_absorption_coeff",
    "composite_conc_dependence_code", "composite_molar_absorption_coeff",
    "composite_mole_fraction", "gpoint_fraction",
    "h2o_conc_dependence_code", "h2o_molar_absorption_coeff",
    "h2o_mole_fraction", "n2o_conc_dependence_code",
    "n2o_molar_absorption_coeff", "n2o_reference_mole_fraction",
    "n_gases", "o3_conc_dependence_code", "o3_molar_absorption_coeff",
    "planck_function", "pressure", "temperature", "temperature_planck",
    "wavenumber1", "wavenumber1_band", "wavenumber2", "wavenumber2_band"])

const BL_RESULTS_JSON = validation_results_path("gate4_b0_era_stack_completion_ledger.json")
const BL_RESULTS_MD = validation_results_path("gate4_b0_era_stack_completion_ledger.md")

# --- primitives -----------------------------------------------------------------

bl_try_sha(path) = try
    isfile(path) || return nothing
    open(io -> bytes2hex(sha256(io)), path)
catch
    nothing
end

# coupled pinned read: ONE byte read supplies the digest check AND the
# content that gets parsed (no hash-then-reread TOCTOU); size optional
function bl_read_pinned(path, sha; size = nothing, label = basename(path))
    isfile(path) || return (["$label missing: $path"], nothing)
    bytes = try
        read(path)
    catch
        return (["$label unreadable: $path"], nothing)
    end
    size === nothing || length(bytes) == size ||
        return (["$label size $(length(bytes)) != $size"], nothing)
    got = bytes2hex(sha256(bytes))
    (sha === nothing || got == sha) ||
        return (["$label sha $got != pinned $sha"], nothing)
    (String[], bytes)
end

bl_count(text, needle) = length(collect(eachmatch(
    Regex("\\Q" * needle * "\\E"), text)))

const BL_TOKEN_KEYS = ("JobId", "JobName", "JobState", "Reason",
    "ExitCode", "DerivedExitCode", "Restarts", "RunTime",
    "SubmitTime", "StartTime", "EndTime")

function bl_parse_receipt(text)
    f = Dict{String, String}()
    for k in BL_TOKEN_KEYS
        m = match(Regex("\\b" * k * "=(\\S+)"), text)
        m === nothing || (f[k] = String(m.captures[1]))
    end
    for k in ("Command", "SubmitLine", "WorkDir", "StdOut")
        m = match(Regex("^\\s*" * k * "=(.*)\$", "m"), text)
        m === nothing || (f[k] = String(strip(m.captures[1])))
    end
    f
end

function bl_receipt_issues(f, expect)
    iss = String[]
    for (k, v) in expect
        get(f, k, "") == v ||
            push!(iss, "$k mismatch (got $(repr(get(f, k, ""))))")
    end
    sort(iss)
end

# content-coupled attempt binding (identical contract to the committed
# generator): custody byte-identity, every field from EACH receipt,
# exact log stage shape, exactly-once required lines
function bl_attempt_issues(job, r40bytes, r42bytes, logtext;
                           expect, present_stages, absent_markers,
                           required_lines = String[])
    iss = String[]
    r40bytes == r42bytes ||
        push!(iss, "$job receipts not byte-identical across custody")
    for (label, bytes) in (("session40", r40bytes), ("agent42", r42bytes))
        f = bl_parse_receipt(String(copy(bytes)))
        for i in bl_receipt_issues(f, expect)
            push!(iss, "$job $label receipt: $i")
        end
    end
    for s in present_stages
        occursin("=== B0-lw stage $s", logtext) ||
            push!(iss, "$job log missing stage $s marker")
    end
    for bad in absent_markers
        occursin(bad, logtext) &&
            push!(iss, "$job log falsely contains: $bad")
    end
    for r in required_lines
        n = bl_count(logtext, r)
        n == 1 ||
            push!(iss, "$job log required line not exactly once ($n): $r")
    end
    iss
end

bl_a4540_issues(r40, r42, logtext) =
    bl_attempt_issues(4540, r40, r42, logtext; expect = BL_A4540_EXPECT,
        present_stages = ["0a", "0b", "0c", "0d"],
        absent_markers = ["=== B0-lw stage 0e", "=== B0-lw stage 1",
                          "staged scientific-input snapshot verified",
                          "RUNROOT", "=== B0-lw done "])

bl_a4545_issues(r40, r42, logtext) =
    bl_attempt_issues(4545, r40, r42, logtext; expect = BL_A4545_EXPECT,
        present_stages = ["0a", "0b", "0c", "0d", "0e", "1", "2", "3"],
        absent_markers = ["=== B0-lw stage 4", "=== B0-lw stage 5",
                          "=== B0-lw stage 6", "=== B0-lw stage 7",
                          "=== B0-lw done "],
        required_lines = [BL_A4545_REFUSAL_LINE])

bl_a4546_issues(r40, r42, logtext) =
    bl_attempt_issues(4546, r40, r42, logtext; expect = BL_A4546_EXPECT,
        present_stages = ["0a", "0b", "0c", "0d", "0e", "1", "2", "3",
                          "4", "5", "5b", "6", "7"],
        absent_markers = String[],
        required_lines = [BL_DONE_MARK])

# --- job-log structural contract (pure) ------------------------------------------

function bl_marker_issues(text, stages, done)
    iss = String[]
    lastpos = 0
    for s in stages
        n = bl_count(text, s)
        n == 1 || push!(iss, "stage marker not exactly once ($n): $s")
        p = findfirst(s, text)
        if p !== nothing
            first(p) > lastpos || push!(iss, "stage marker out of order: $s")
            lastpos = first(p)
        end
    end
    n = bl_count(text, done)
    n == 1 || push!(iss, "done marker not exactly once ($n)")
    p = findfirst(done, text)
    (p === nothing || first(p) > lastpos) ||
        push!(iss, "done marker out of order")
    iss
end

function bl_joblog_issues(text)
    iss = String[]
    append!(iss, bl_marker_issues(text, BL_STAGES, BL_DONE_MARK))
    for (label, needle) in (("probe PASSED", BL_PROBE_PASSED),
                            ("raw2 verified", BL_RAW2_VERIFIED),
                            ("raw2 stage-7 hash echo",
                             "$BL_RAW2_SHA  $BL_RAW2"),
                            ("probe-log hash echo",
                             "$BL_PROBE_LOG_SHA  $BL_PROBE_LOG"),
                            ("base-log hash echo",
                             "$BL_BASE_LOG_SHA  $BL_BASE_LOG"))
        n = bl_count(text, needle)
        n == 1 || push!(iss, "$label not exactly once ($n)")
    end
    m = match(BL_FAILURE_RE, text)
    m === nothing || push!(iss, "failure marker present: $(m.match)")
    iss
end

# per-file runtime bindings over the sha-pinned probe/base logs
function bl_probelog_issues(text)
    iss = String[]
    for (label, needle, n_exp) in (
            ("probe banner", BL_PROBE_BANNER, 1),
            ("gas banner", BL_GAS_BANNER, 1),
            ("convergence line", BL_CONV_LINE, 1),
            ("runtime Adept banner", "Adept LBFGS", 0))
        n = bl_count(text, needle)
        n == n_exp || push!(iss, "probe log $label count $n != $n_exp")
    end
    iss
end

function bl_baselog_issues(text)
    iss = String[]
    for (label, needle, n_exp) in (
            ("era banner", BL_ERA_BANNER, 1),
            ("gas banner", BL_GAS_BANNER, 1),
            ("first iteration record", BL_FIRST_ITER, 1),
            ("final iteration record", BL_FINAL_ITER, 1),
            ("convergence line", BL_CONV_LINE, 1),
            ("runtime Adept banner", "Adept LBFGS", 0))
        n = bl_count(text, needle)
        n == n_exp || push!(iss, "base log $label count $n != $n_exp")
    end
    lastpos = 0
    for c in BL_COV_SEQ
        n = bl_count(text, c)
        n == 1 || push!(iss, "covariance line not exactly once ($n): $c")
        p = findfirst(c, text)
        if p !== nothing
            first(p) > lastpos ||
                push!(iss, "covariance line out of order: $c")
            lastpos = first(p)
        end
    end
    iss
end

# --- era raw2 schema gate (coupled read; parameterized for fixtures) --------------

bl_all_finite(a) = !any(ismissing, a) && all(isfinite, skipmissing(a))

function bl_schema_issues_ds(ds; band_dim = 1, expected_vars = BL_RAW2_VARS)
    iss = String[]
    for (d, v) in (("g_point", 32), ("pressure", 53), ("temperature", 6),
                   ("composite_gas", 4), ("h2o_mole_fraction", 12),
                   ("band", band_dim))
        haskey(ds.dim, d) || (push!(iss, "dim missing: $d"); continue)
        ds.dim[d] == v || push!(iss, "dim $d = $(ds.dim[d]) != $v")
    end
    # EXACT variable-name census: missing AND extra variables both refuse
    have = sort([String(k) for k in keys(ds)])
    for v in setdiff(expected_vars, have)
        push!(iss, "var missing: $v")
    end
    for v in setdiff(have, expected_vars)
        push!(iss, "unexpected extra var: $v")
    end
    # EVERY present variable: readable + nonempty; every NUMERIC
    # variable additionally finite with no missing values
    for k in have
        a = try
            Array(ds[k])
        catch
            push!(iss, "var unreadable: $k")
            continue
        end
        length(a) > 0 || push!(iss, "var empty: $k")
        eltype(a) <: Union{Missing, Real} || continue
        bl_all_finite(a) || push!(iss, "var has nonfinite/missing values: $k")
    end
    # explicit min/max-absent gate retained (subsumed by the exact
    # census; kept as a named refusal for bound-array reappearance)
    nmm = count(k -> endswith(String(k), "_min") ||
                     endswith(String(k), "_max"), keys(ds))
    nmm == 0 || push!(iss, "era raw2 unexpectedly carries $nmm " *
                           "min/max bound arrays (v1.2 artifact?)")
    iss
end

function bl_raw2_group()
    isfile(BL_RAW2) || return (["era raw2 missing: $BL_RAW2"], nothing)
    bytes = try
        read(BL_RAW2)
    catch
        return (["era raw2 unreadable"], nothing)
    end
    length(bytes) == BL_RAW2_BYTES ||
        return (["era raw2 size $(length(bytes)) != $BL_RAW2_BYTES"], nothing)
    sha = bytes2hex(sha256(bytes))
    sha == BL_RAW2_SHA ||
        return (["era raw2 sha $sha != pinned $BL_RAW2_SHA"], nothing)
    snap = joinpath(mktempdir(), "era_raw2_snap.nc")
    write(snap, bytes)
    iss = try
        NCDataset(ds -> bl_schema_issues_ds(ds), snap)
    catch err
        ["era raw2 not openable as netCDF: $(sprint(showerror, err))"]
    end
    (iss, snap)
end

# --- pinned external comparator (fully reconstructed in this unit) ----------------

# coupled private snapshot: ONE byte read supplies exact size check,
# digest check, and the snapshot content that gets evaluated
function bl_pinned_snapshot(path, size, sha; label = basename(path))
    isfile(path) || return (["$label missing: $path"], nothing)
    bytes = try
        read(path)
    catch
        return (["$label unreadable: $path"], nothing)
    end
    length(bytes) == size ||
        return (["$label size $(length(bytes)) != $size"], nothing)
    got = bytes2hex(sha256(bytes))
    got == sha || return (["$label sha $got != pinned $sha"], nothing)
    snap = joinpath(mktempdir(), "snap_" * basename(path))
    write(snap, bytes)
    (String[], snap)
end

# the resolved comparator H2O never consults the environment (fixture-
# proven immunity)
bl_h2o_resolved() = BL_H2O

# every objective evaluates against the SAME private snapshot set:
# snapshot-backed case tuples (reference_path passes absolute paths
# through unchanged) + the pinned SW snapshot
function bl_swap_objective(lw_path, sw_path, cases)
    model = read_ecckd_tabulated_gas_optics(lw_path, sw_path;
        gas_names = OFFICIAL_ECCKD_GASES,
        h2o_mole_fraction = bl_h2o_resolved())
    hard_objective([case_metrics(c, model) for c in cases]).value
end

bl_deltas(v) = [Dict("reference" => n, "value" => r,
                     "delta" => v - r, "ratio" => v / r)
                for (n, r) in BL_REFS]
bl_value_ok(v) = v == BL_ERA_EXPECTED
bl_ref_value_ok(v, expected) = v == expected

# pure classifiers for the comparator code/src pins (injectable
# observations so fixtures exercise the SAME logic main uses)
function bl_code_pin_issues(shafn = p -> bl_try_sha(joinpath(BL_PROJECT_ROOT, p)))
    iss = String[]
    for (rel, sha) in BL_CODE_PINS
        shafn(rel) == sha || push!(iss, "comparator code pin drift: $rel")
    end
    iss
end

bl_src_state_issues(tree, dirty) = vcat(
    tree == BL_SRC_TREE ? String[] :
        ["src tree $tree != reviewed $BL_SRC_TREE " *
         "(exact match required, never merely ancestor)"],
    dirty == "" ? String[] :
        ["tracked src/Project state not exactly reviewed: $dirty"])

# pure fail-closed scientific-reporting classifier (fixture-tested): on
# ANY missing era/reference recomputation the deltas/ratios are null and
# the bounded interpretation is WITHHELD; the expected value is NEVER
# substituted for a failed evaluation
function bl_scientific_section(era_value, refs_recomputed, pub_value)
    # complete requires the era value BIT-EXACT equal to the reviewed
    # value (a drifted era fails comparator_integrity AND withholds the
    # scientific section), every reference recomputed bit-exact, AND the
    # classifier's own published self-check bit-exact
    complete = era_value == BL_ERA_EXPECTED &&
        pub_value == BL_PUBLISHED_BASELINE &&
        all(get(refs_recomputed, n, nothing) == v for (n, v) in BL_REFS)
    refs = [Dict(
            "reference" => name,
            "input_path" => path,
            "input_bytes" => size,
            "input_sha256" => sha,
            "reviewed_value" => expected,
            "recomputed_value" => get(refs_recomputed, name, nothing),
            "recomputed_bit_exact" =>
                get(refs_recomputed, name, nothing) == expected,
            "delta_era_minus_ref" =>
                complete ? era_value - expected : nothing,
            "ratio_era_over_ref" =>
                complete ? era_value / expected : nothing)
        for (name, path, size, sha, expected) in BL_REF_INPUTS]
    Dict(
        "era_raw2_swap_objective" => era_value,
        "published_context_selfcheck" => pub_value,
        "scientific_reporting_complete" => complete,
        "objective_gate_note" => complete ?
            ("the recovered-model objective gate is <= 1.05 " *
             "(gate4_g1_objective_ratio contract); the era raw2 value " *
             "reported here fails that gate") :
            ("WITHHELD: era/reference recomputation incomplete or " *
             "drifted; no gate statement is made"),
        "published_sw_pin" => Dict("path" => BL_PUB_SW,
            "bytes" => BL_PUB_SW_BYTES, "sha256" => BL_PUB_SW_SHA,
            "note" => "the SAME pinned published SW snapshot is used " *
                      "for every swap evaluation"),
        "references" => refs,
        "bounded_interpretation" => complete ?
            ("B0 execution completed and the bundled target-era stack " *
             "is viable, but its fixed-input raw2 still fails the 1.05 " *
             "objective gate and offers no material recovery versus " *
             "the v1.2 raw2. This is one deterministic bundled " *
             "comparison with confounded source/backend/bounds; it is " *
             "never phrased as statistically equivalent/" *
             "indistinguishable, backend disproven, hypothesis " *
             "collapsed, or causality shifted (binding monitor wording " *
             "2026-08-13).") :
            ("WITHHELD: era/reference recomputation incomplete; no " *
             "deltas, ratios, or scientific interpretation are " *
             "reported, and expected values are never substituted for " *
             "failed evaluations."),
        "internal_cost_note" => "era internal LBFGS cost/gradient " *
            "records are runtime evidence only and are never compared " *
            "across stacks as a verdict; the pinned external comparator " *
            "is the sole scoring instrument.")
end

# --- overall ----------------------------------------------------------------------

bl_overall(groups) = all(isempty, values(groups)) ?
    "b0_run_completed_verified" : "b0_completion_ledger_refused"

function bl_close_failed_gates!(fails, gates)
    bad = sort([k for (k, v) in gates if v != "passed"])
    isempty(bad) ||
        push!(fails, "failed gates (fail-closed census): " * join(bad, ", "))
end

# --- fixtures -----------------------------------------------------------------------

function bl_mkreceipt(expect, over...)
    e = Dict{String, String}(expect)
    for (k, v) in over
        e[k] = v
    end
    Vector{UInt8}(codeunits(
        "JobId=$(e["JobId"]) JobName=$(e["JobName"])\n" *
        "   JobState=$(e["JobState"]) Reason=$(e["Reason"]) Dependency=(null)\n" *
        "   Requeue=1 Restarts=$(e["Restarts"]) BatchFlag=1 ExitCode=$(e["ExitCode"])\n" *
        "   DerivedExitCode=$(e["DerivedExitCode"])\n" *
        "   RunTime=$(e["RunTime"]) TimeLimit=06:00:00 TimeMin=N/A\n" *
        "   SubmitTime=$(e["SubmitTime"]) EligibleTime=$(e["SubmitTime"])\n" *
        "   StartTime=$(e["StartTime"]) EndTime=$(e["EndTime"]) Deadline=N/A\n" *
        "   Command=$(e["Command"])\n" *
        "   SubmitLine=$(e["SubmitLine"])\n" *
        "   WorkDir=$(e["WorkDir"])\n" *
        "   StdOut=$(e["StdOut"])\n"))
end

function bl_mkjoblog()
    io = IOBuffer()
    for s in BL_STAGES
        println(io, s)
        println(io, "ok lines")
        if s == BL_STAGES[11]
            println(io, BL_PROBE_PASSED)
        end
    end
    println(io, BL_RAW2_VERIFIED)
    println(io, "$BL_RAW2_SHA  $BL_RAW2")
    println(io, "$BL_PROBE_LOG_SHA  $BL_PROBE_LOG")
    println(io, "$BL_BASE_LOG_SHA  $BL_BASE_LOG")
    println(io, BL_DONE_MARK)
    String(take!(io))
end

function bl_mkbaselog()
    io = IOBuffer()
    println(io, BL_ERA_BANNER)
    println(io, BL_GAS_BANNER)
    for c in BL_COV_SEQ
        println(io, c)
        println(io, "    fraction of elements less than 1e-06 is 0.9")
    end
    println(io, BL_FIRST_ITER)
    println(io, "Iteration 2: cost function = 900.0, gradient norm = 100.0")
    println(io, BL_FINAL_ITER)
    println(io, BL_CONV_LINE)
    String(take!(io))
end

bl_mkprobelog() = BL_PROBE_BANNER * "\n" * BL_GAS_BANNER * "\n" *
    "Iteration 1: cost function = 1906.44, gradient norm = 788.674\n" *
    BL_CONV_LINE * "\n"

function bl_fixtures()
    t = Dict{String, Bool}()
    fx = mktempdir()

    # receipt binding: each attempt's expectation table
    for (label, expect) in (("a4540", BL_A4540_EXPECT),
                            ("a4545", BL_A4545_EXPECT),
                            ("a4546", BL_A4546_EXPECT))
        good = bl_parse_receipt(String(copy(bl_mkreceipt(expect))))
        t["$(label)_receipt_good_binds"] =
            isempty(bl_receipt_issues(good, expect))
    end
    t["receipt_wrong_state_refuses"] =
        !isempty(bl_receipt_issues(bl_parse_receipt(String(copy(
            bl_mkreceipt(BL_A4546_EXPECT, "JobState" => "FAILED")))),
            BL_A4546_EXPECT))
    t["receipt_nonzero_exit_refuses"] =
        !isempty(bl_receipt_issues(bl_parse_receipt(String(copy(
            bl_mkreceipt(BL_A4546_EXPECT, "ExitCode" => "1:0")))),
            BL_A4546_EXPECT))
    t["receipt_wrong_runtime_refuses"] =
        !isempty(bl_receipt_issues(bl_parse_receipt(String(copy(
            bl_mkreceipt(BL_A4546_EXPECT, "RunTime" => "00:00:01")))),
            BL_A4546_EXPECT))

    # attempt bindings: good accepted + key mutations refuse
    log40 = join(["=== B0-lw stage $s: x ===" for s in
                  ("0a", "0b", "0c", "0d")], "\nok\n") * "\n"
    log45 = join(["=== B0-lw stage $s: x ===" for s in
                  ("0a", "0b", "0c", "0d", "0e", "1", "2", "3")],
                 "\nok\n") * "\n" * BL_A4545_REFUSAL_LINE * "\n"
    log46 = bl_mkjoblog()
    r(e) = bl_mkreceipt(e)
    t["a4540_good"] = isempty(bl_a4540_issues(r(BL_A4540_EXPECT),
                                              r(BL_A4540_EXPECT), log40))
    t["a4540_runroot_refuses"] = !isempty(bl_a4540_issues(
        r(BL_A4540_EXPECT), r(BL_A4540_EXPECT), log40 * "RUNROOT x\n"))
    t["a4545_good"] = isempty(bl_a4545_issues(r(BL_A4545_EXPECT),
                                              r(BL_A4545_EXPECT), log45))
    t["a4545_duplicate_refusal_refuses"] = !isempty(bl_a4545_issues(
        r(BL_A4545_EXPECT), r(BL_A4545_EXPECT),
        log45 * BL_A4545_REFUSAL_LINE * "\n"))
    t["a4546_good"] = isempty(bl_a4546_issues(r(BL_A4546_EXPECT),
                                              r(BL_A4546_EXPECT), log46))
    t["a4546_custody_divergence_refuses"] = !isempty(bl_a4546_issues(
        r(BL_A4546_EXPECT),
        bl_mkreceipt(BL_A4546_EXPECT, "EndTime" => "2026-08-13T20:38:34"),
        log46))
    t["a4546_missing_done_refuses"] = !isempty(bl_a4546_issues(
        r(BL_A4546_EXPECT), r(BL_A4546_EXPECT),
        replace(log46, BL_DONE_MARK * "\n" => "")))

    # job-log contract
    t["joblog_good"] = isempty(bl_joblog_issues(log46))
    t["joblog_missing_stage_refuses"] = !isempty(bl_joblog_issues(
        replace(log46, BL_STAGES[11] * "\n" => "")))
    t["joblog_stage_out_of_order_refuses"] = !isempty(bl_joblog_issues(
        BL_STAGES[5] * "\n" * replace(log46, BL_STAGES[5] * "\n" => "")))
    t["joblog_duplicate_done_refuses"] = !isempty(bl_joblog_issues(
        log46 * BL_DONE_MARK * "\n"))
    t["joblog_missing_raw2_echo_refuses"] = !isempty(bl_joblog_issues(
        replace(log46, "$BL_RAW2_SHA  $BL_RAW2" => "")))
    t["joblog_failure_marker_refuses"] = !isempty(bl_joblog_issues(
        log46 * "OPTIMIZE_LUT CHILD FAILED rc=1\n"))
    t["joblog_lowercase_error_covariance_accepted"] =
        match(BL_FAILURE_RE, "Creating a-priori error covariance\n") ===
        nothing

    # per-file runtime bindings
    t["probelog_good"] = isempty(bl_probelog_issues(bl_mkprobelog()))
    t["probelog_adept_banner_refuses"] = !isempty(bl_probelog_issues(
        bl_mkprobelog() * "Optimizing coefficients with Adept LBFGS " *
        "algorithm: max iterations = 1, convergence criterion = 0.02\n"))
    t["probelog_missing_banner_refuses"] = !isempty(bl_probelog_issues(
        replace(bl_mkprobelog(), BL_PROBE_BANNER => "banner")))
    t["baselog_good"] = isempty(bl_baselog_issues(bl_mkbaselog()))
    t["baselog_adept_banner_refuses"] = !isempty(bl_baselog_issues(
        bl_mkbaselog() * "Adept LBFGS\n"))
    t["baselog_wrong_final_iteration_refuses"] = !isempty(bl_baselog_issues(
        replace(bl_mkbaselog(), BL_FINAL_ITER =>
            "Iteration 3000: cost function = 17.0, gradient norm = 0.1")))
    t["baselog_missing_cov_refuses"] = !isempty(bl_baselog_issues(
        replace(bl_mkbaselog(), BL_COV_SEQ[2] * "\n" => "")))
    t["baselog_cov_out_of_order_refuses"] = !isempty(bl_baselog_issues(
        BL_COV_SEQ[3] * "\n" * replace(bl_mkbaselog(),
                                       BL_COV_SEQ[3] * "\n" => "")))

    # schema gate on tiny parameterized fixtures (full 31-name census)
    mknc(path; drop = nothing, poison = nothing, band = 1,
         extra = nothing) = begin
        NCDataset(path, "c") do ds
            for (d, v) in (("g_point", 32), ("pressure", 53),
                           ("temperature", 6), ("composite_gas", 4),
                           ("h2o_mole_fraction", 12), ("band", band))
                defDim(ds, d, v)
            end
            for v in vcat(BL_RAW2_VARS, extra === nothing ? String[] : [extra])
                v == drop && continue
                var = defVar(ds, v, Float64, ("g_point",))
                var[:] = fill(v == poison ? NaN : 1.0, 32)
            end
        end
        path
    end
    run_schema(p) = NCDataset(ds -> bl_schema_issues_ds(ds), p)
    t["schema_good_accepted"] =
        isempty(run_schema(mknc(joinpath(fx, "good.nc"))))
    t["schema_missing_var_refuses"] =
        any(i -> i == "var missing: planck_function",
            run_schema(mknc(joinpath(fx, "drop.nc");
                            drop = "planck_function")))
    t["schema_core_nonfinite_refuses"] =
        any(i -> occursin("nonfinite", i),
            run_schema(mknc(joinpath(fx, "nan.nc");
                            poison = "h2o_molar_absorption_coeff")))
    # non-core numeric variable poisoned with NaN must ALSO refuse
    t["schema_noncore_nonfinite_refuses"] =
        any(i -> i == "var has nonfinite/missing values: pressure",
            run_schema(mknc(joinpath(fx, "nan2.nc"); poison = "pressure")))
    t["schema_wrong_band_refuses"] =
        any(i -> occursin("dim band", i),
            run_schema(mknc(joinpath(fx, "band.nc"); band = 2)))
    # ANY extra variable refuses (exact census)
    t["schema_extra_var_refuses"] =
        any(i -> i == "unexpected extra var: rogue_extra_variable",
            run_schema(mknc(joinpath(fx, "extra.nc");
                            extra = "rogue_extra_variable")))
    # min/max reappearance refuses (named gate + census)
    t["schema_unexpected_minmax_refuses"] =
        any(i -> occursin("min/max bound arrays", i),
            run_schema(mknc(joinpath(fx, "mm.nc");
                            extra = "h2o_molar_absorption_coeff_min")))

    # H2O env-override immunity: the resolved comparator H2O ignores the
    # environment entirely
    t["h2o_env_immunity"] = withenv(
        "RH_ECCKD_H2O_MOLE_FRACTION" => "0.9") do
        bl_h2o_resolved() == 0.005
    end

    # comparator code/src pin logic mutations (same classifiers main uses)
    t["code_pins_live_green"] = isempty(bl_code_pin_issues())
    t["code_pin_mutation_refuses"] =
        !isempty(bl_code_pin_issues(p ->
            p == BL_CODE_PINS[1][1] ? "0" ^ 64 :
                bl_try_sha(joinpath(BL_PROJECT_ROOT, p))))
    t["code_pin_missing_refuses"] =
        !isempty(bl_code_pin_issues(_ -> nothing))
    t["src_state_good_accepted"] =
        isempty(bl_src_state_issues(BL_SRC_TREE, ""))
    t["src_tree_mutation_refuses"] =
        !isempty(bl_src_state_issues("f" ^ 40, ""))
    t["src_dirty_state_refuses"] =
        !isempty(bl_src_state_issues(BL_SRC_TREE, " M src/x.jl"))

    # comparator integrity + delta arithmetic (pure)
    t["value_bitexact_accepted"] = bl_value_ok(BL_ERA_EXPECTED)
    t["value_drift_refuses"] = !bl_value_ok(nextfloat(BL_ERA_EXPECTED))
    d = bl_deltas(BL_ERA_EXPECTED)
    t["deltas_arithmetic_exact"] =
        length(d) == 4 &&
        d[2]["delta"] == BL_ERA_EXPECTED - 22.791293464348826 &&
        d[4]["ratio"] == BL_ERA_EXPECTED / 0.18218645425029933

    # reference-input pinning + bit-exact reference-value logic
    rp = joinpath(fx, "ref.bin"); write(rp, "REFERENCE-BYTES")
    rsha = bytes2hex(sha256(read(rp)))
    t["ref_snapshot_good_accepted"] = begin
        iss, sn = bl_pinned_snapshot(rp, filesize(rp), rsha)
        isempty(iss) && sn !== nothing && read(sn) == read(rp)
    end
    t["ref_snapshot_sha_mutation_refuses"] =
        !isempty(bl_pinned_snapshot(rp, filesize(rp), "0" ^ 64)[1])
    t["ref_snapshot_size_mutation_refuses"] =
        !isempty(bl_pinned_snapshot(rp, 1, rsha)[1])
    t["ref_snapshot_missing_refuses"] =
        !isempty(bl_pinned_snapshot(joinpath(fx, "no.bin"), 1, rsha)[1])
    # per-reference value + input-pin mutations: EVERY reference, both
    # case inputs, and the shared SW pin (real files, wrong pins refuse)
    for (name, path, size, sha, expected) in BL_REF_INPUTS
        t["ref_$(name)_value_bitexact_accepted"] =
            bl_ref_value_ok(expected, expected)
        t["ref_$(name)_value_mutation_refuses"] =
            !bl_ref_value_ok(nextfloat(expected), expected)
        t["ref_$(name)_sha_mutation_refuses"] =
            !isempty(bl_pinned_snapshot(path, size, "0" ^ 64)[1])
        t["ref_$(name)_size_mutation_refuses"] =
            !isempty(bl_pinned_snapshot(path, size + 1, sha)[1])
    end
    for (name, path, size, sha) in BL_CASE_INPUTS
        t["case_$(name)_sha_mutation_refuses"] =
            !isempty(bl_pinned_snapshot(path, size, "0" ^ 64)[1])
    end
    t["sw_pin_sha_mutation_refuses"] =
        !isempty(bl_pinned_snapshot(BL_PUB_SW, BL_PUB_SW_BYTES, "0" ^ 64)[1])

    # fail-closed scientific-reporting classifier: missing era, DRIFTED
    # era, missing reference, drifted reference -- each yields null
    # deltas/ratios and WITHHELD interpretation/note; complete case
    # yields exact deltas and the bounded interpretation
    full_refs = Dict(n => v for (n, v) in BL_REFS)
    withheld_ok(s) = !s["scientific_reporting_complete"] &&
        startswith(s["bounded_interpretation"], "WITHHELD") &&
        startswith(s["objective_gate_note"], "WITHHELD") &&
        all(r["delta_era_minus_ref"] === nothing &&
            r["ratio_era_over_ref"] === nothing for r in s["references"])
    t["scientific_missing_era_withheld"] =
        withheld_ok(bl_scientific_section(nothing, full_refs, nothing))
    t["scientific_drifted_era_withheld"] =
        withheld_ok(bl_scientific_section(nextfloat(BL_ERA_EXPECTED),
                                          full_refs, nothing))
    t["scientific_missing_reference_withheld"] = begin
        d = Dict(n => v for (n, v) in BL_REFS if n != "v12_raw2")
        withheld_ok(bl_scientific_section(BL_ERA_EXPECTED, d, nothing))
    end
    t["scientific_drifted_reference_withheld"] = begin
        d = Dict(n => (n == "v12_raw2" ? nextfloat(v) : v)
                 for (n, v) in BL_REFS)
        withheld_ok(bl_scientific_section(BL_ERA_EXPECTED, d, nothing))
    end
    t["scientific_wrong_pub_withheld"] =
        withheld_ok(bl_scientific_section(BL_ERA_EXPECTED, full_refs,
                                          nextfloat(BL_PUBLISHED_BASELINE)))
    t["scientific_complete_reports"] = begin
        s = bl_scientific_section(BL_ERA_EXPECTED, full_refs,
                                  BL_PUBLISHED_BASELINE)
        s["scientific_reporting_complete"] &&
            !startswith(s["bounded_interpretation"], "WITHHELD") &&
            !startswith(s["objective_gate_note"], "WITHHELD") &&
            s["references"][2]["delta_era_minus_ref"] ==
                BL_ERA_EXPECTED - 22.791293464348826
    end

    # overall composition
    t["overall_all_green"] =
        bl_overall(Dict("a" => String[])) == "b0_run_completed_verified"
    t["overall_any_issue_refuses"] =
        bl_overall(Dict("a" => ["x"])) == "b0_completion_ledger_refused"
    t
end

# --- main -----------------------------------------------------------------------

function main()
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    fails = String[]
    gates = Dict{String, String}()

    tests = bl_fixtures()
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    groups = Dict{String, Vector{String}}()

    anc = try
        success(`git -C $BL_PROJECT_ROOT merge-base --is-ancestor $BL_REVIEWED_COMMIT HEAD`)
    catch; false end
    groups["commit_ancestry"] = anc ? String[] :
        ["reviewed commit $BL_REVIEWED_COMMIT is not an ancestor of HEAD"]
    gp = String[]
    bl_try_sha(BL_GEN_SRC) == BL_GEN_SRC_SHA ||
        push!(gp, "generator source sha != pinned")
    bl_try_sha(BL_SBATCH) == BL_SBATCH_SHA ||
        push!(gp, "sbatch sha != pinned")
    groups["generator_and_sbatch_pins"] = gp

    # attempts: coupled byte reads (one read per file supplies pin digest
    # AND parsed content)
    function attempt_group(job, pin_receipt, pin_log, issues_fn)
        iss = String[]
        reads = Dict{String, Union{Nothing, Vector{UInt8}}}()
        p40, p42 = bl_receipt_pair(job)
        for (p, pin, label) in ((p40, pin_receipt, "session40 receipt"),
                                (p42, pin_receipt, "agent42 receipt"),
                                ("$BL_LOG_DIR/g4-b0-lw-$job.log", pin_log,
                                 "log"))
            bytes = try
                isfile(p) ? read(p) : nothing
            catch
                nothing
            end
            reads[label] = bytes
            if bytes === nothing
                push!(iss, "$job $label missing/unreadable: $p")
            elseif bytes2hex(sha256(bytes)) != pin
                push!(iss, "$job $label pin mismatch: $p")
            end
        end
        isempty(iss) &&
            append!(iss, issues_fn(reads["session40 receipt"],
                                   reads["agent42 receipt"],
                                   String(copy(reads["log"]))))
        iss
    end
    groups["attempt_4540_evidence"] = attempt_group(4540,
        BL_A4540_RECEIPT_SHA, BL_A4540_LOG_SHA, bl_a4540_issues)
    groups["attempt_4545_evidence"] = attempt_group(4545,
        BL_A4545_RECEIPT_SHA, BL_A4545_LOG_SHA, bl_a4545_issues)
    groups["attempt_4546_evidence"] = attempt_group(4546,
        BL_A4546_RECEIPT_SHA, BL_A4546_LOG_SHA, bl_a4546_issues)

    # job-log structural contract: ONE coupled byte read supplies the
    # digest check and the parsed text (no hash-then-reread TOCTOU)
    jl_issues, jl_bytes = bl_read_pinned(BL_A4546_LOG, BL_A4546_LOG_SHA;
                                         label = "job log")
    jl_bytes === nothing ||
        append!(jl_issues, bl_joblog_issues(String(copy(jl_bytes))))
    groups["job_log_contract"] = jl_issues

    # RUNROOT artifacts: every claimed artifact has coupled size/SHA
    # content evidence -- probe/base logs (with runtime bindings parsed
    # from the SAME bytes), era source blobs, build config.log, probe raw2
    rr = String[]
    pl_iss, pl_bytes = bl_read_pinned(BL_PROBE_LOG, BL_PROBE_LOG_SHA;
                                      label = "probe log")
    append!(rr, pl_iss)
    pl_bytes === nothing ||
        append!(rr, bl_probelog_issues(String(copy(pl_bytes))))
    b_iss, b_bytes = bl_read_pinned(BL_BASE_LOG, BL_BASE_LOG_SHA;
                                    label = "base log")
    append!(rr, b_iss)
    b_bytes === nothing ||
        append!(rr, bl_baselog_issues(String(copy(b_bytes))))
    for (path, size, sha) in BL_ERA_BLOBS
        e_iss, _ = bl_read_pinned(path, sha; size = size,
                                  label = "era source blob $(basename(path))")
        append!(rr, e_iss)
    end
    c_iss, _ = bl_read_pinned(BL_CONFIG_LOG, BL_CONFIG_LOG_SHA;
                              size = BL_CONFIG_LOG_BYTES,
                              label = "build config.log")
    append!(rr, c_iss)
    p2_iss, _ = bl_read_pinned(BL_PROBE_RAW2, BL_PROBE_RAW2_SHA;
                               size = BL_PROBE_RAW2_BYTES,
                               label = "probe raw2")
    append!(rr, p2_iss)
    groups["runroot_artifacts"] = rr

    # era raw2: exact size+sha + invariant schema (coupled read)
    raw2_issues, snap = bl_raw2_group()
    groups["era_raw2_schema"] = raw2_issues

    # comparator code/dependency/state pins: fail closed BEFORE any
    # objective is accepted
    cp = bl_code_pin_issues()
    src_tree = try
        strip(read(`git -C $BL_PROJECT_ROOT rev-parse HEAD:src`, String))
    catch
        "unreadable"
    end
    dirty = try
        strip(read(`git -C $BL_PROJECT_ROOT status --porcelain -- src Project.toml`, String))
    catch
        "unreadable"
    end
    append!(cp, bl_src_state_issues(src_tree, dirty))
    groups["comparator_code_pins"] = cp

    # comparator integrity: pinned published SW + the two pinned case
    # inputs are read once to bytes, size/SHA checked, written to ONE
    # private snapshot set; ALL FIVE objectives evaluate against that
    # same snapshot set; every reference recomputed BIT-EXACT
    ci = String[]
    era_value = nothing
    pub_value = nothing
    refs_recomputed = Dict{String, Any}()
    if !isempty(cp)
        push!(ci, "comparator not run (code/dependency pins failed)")
    else
        sw_iss, sw_snap = bl_pinned_snapshot(BL_PUB_SW, BL_PUB_SW_BYTES,
                                             BL_PUB_SW_SHA;
                                             label = "published SW32")
        append!(ci, sw_iss)
        snapshot_cases = Any[]
        for (name, path, size, sha) in BL_CASE_INPUTS
            k_iss, k_snap = bl_pinned_snapshot(path, size, sha;
                                               label = "case input $name")
            append!(ci, k_iss)
            k_snap === nothing && continue
            push!(snapshot_cases, (case = name, path = k_snap))
        end
        if sw_snap !== nothing && length(snapshot_cases) == length(BL_CASE_INPUTS)
            for (name, path, size, sha, expected) in BL_REF_INPUTS
                r_iss, r_snap = bl_pinned_snapshot(path, size, sha;
                                                   label = "reference $name")
                append!(ci, r_iss)
                r_snap === nothing && continue
                v = try
                    bl_swap_objective(r_snap, sw_snap, snapshot_cases)
                catch err
                    push!(ci, "reference $name evaluation failed: " *
                              sprint(showerror, err))
                    continue
                end
                refs_recomputed[name] = v
                bl_ref_value_ok(v, expected) ||
                    push!(ci, "reference $name recomputed $v != reviewed " *
                              "$expected (bit-exact required)")
            end
            pub_value = get(refs_recomputed, "published_pair", nothing)
            if snap !== nothing && isempty(raw2_issues)
                try
                    era_value = bl_swap_objective(snap, sw_snap,
                                                  snapshot_cases)
                    bl_value_ok(era_value) ||
                        push!(ci, "era raw2 objective $era_value != " *
                                  "reviewed $BL_ERA_EXPECTED " *
                                  "(evidence-pipeline drift)")
                catch err
                    push!(ci, "era comparator evaluation failed: " *
                              sprint(showerror, err))
                end
            else
                push!(ci, "era comparator not run (era raw2 evidence failed)")
            end
        end
    end
    groups["comparator_integrity"] = ci

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end
    status = gates["fixtures"] == "passed" ? bl_overall(groups) :
        "b0_completion_ledger_refused"
    bl_close_failed_gates!(fails, gates)

    scientific = bl_scientific_section(era_value, refs_recomputed,
                                       pub_value)

    result = Dict(
        "case" => "gate4_b0_era_stack_completion_ledger",
        "data_mode" => "evidence_ledger_no_campaign_writes",
        "status" => status,
        "timestamp_utc" => BL_EVIDENCE_TIME,
        "evidence_timestamp_utc" => BL_EVIDENCE_TIME,
        "evidence_timestamp_rule" => "fixed at job 4546 EndTime; never " *
            "wall-clock, so double runs are byte-identical",
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "scientific" => scientific,
        # self-auditing comparator provenance (monitor blocker 2): the
        # complete pin manifest this run verified is preserved verbatim
        "reviewed" => Dict(
            "commit_ancestor" => BL_REVIEWED_COMMIT,
            "generator_source_sha256" => BL_GEN_SRC_SHA,
            "sbatch_sha256" => BL_SBATCH_SHA,
            "comparator_code_pins" => [Dict("path" => rel, "sha256" => sha)
                                       for (rel, sha) in BL_CODE_PINS],
            "reviewed_src_tree" => BL_SRC_TREE,
            "case_input_pins" => [Dict("case" => name, "path" => path,
                                       "bytes" => size, "sha256" => sha)
                                  for (name, path, size, sha) in BL_CASE_INPUTS],
            "published_lw_pin" => Dict("path" => BL_PUB_LW,
                "bytes" => BL_PUB_LW_BYTES, "sha256" => BL_PUB_LW_SHA),
            "published_sw_pin" => Dict("path" => BL_PUB_SW,
                "bytes" => BL_PUB_SW_BYTES, "sha256" => BL_PUB_SW_SHA),
            "h2o_mole_fraction" => BL_H2O),
        "attempts" => [
            Dict("job_id" => 4540, "job_state" => "FAILED",
                 "exit_code_raw" => "141:0",
                 "receipt_sha256" => BL_A4540_RECEIPT_SHA,
                 "log_sha256" => BL_A4540_LOG_SHA,
                 "classification" => "stage-0d SIGPIPE (pipefail + " *
                     "version/head pipelines); pre-RUNROOT; fixed and " *
                     "text-gate banned"),
            Dict("job_id" => 4545, "job_state" => "FAILED",
                 "exit_code_raw" => "68:0",
                 "receipt_sha256" => BL_A4545_RECEIPT_SHA,
                 "log_sha256" => BL_A4545_LOG_SHA,
                 "classification" => "designed proof-gate false positive " *
                     "after a green era build (solve_adept.o pulled into " *
                     "the executable via the shared " *
                     "calc_cost_function_and_gradient symbol); replaced " *
                     "by the layered call-path proof"),
            Dict("job_id" => 4546, "job_state" => "COMPLETED",
                 "exit_code_raw" => "0:0",
                 "run_time" => "00:37:54",
                 "receipt_sha256" => BL_A4546_RECEIPT_SHA,
                 "log_sha256" => BL_A4546_LOG_SHA,
                 "raw2_bytes" => BL_RAW2_BYTES,
                 "raw2_sha256" => BL_RAW2_SHA,
                 "probe_log_sha256" => BL_PROBE_LOG_SHA,
                 "base_log_sha256" => BL_BASE_LOG_SHA,
                 "runroot_preserved" => BL_RUNROOT,
                 "classification" => "COMPLETED to design; base pass at " *
                     "the 3000-iteration cap (first record $BL_FIRST_ITER; " *
                     "final record $BL_FINAL_ITER); probe accepted the " *
                     "unchanged v1.2 init with min/max arrays present; " *
                     "zero canonical writes")],
        "confound_note" => "the b42e5c0..23adaca diff includes " *
            "optimize_lut.cpp, ckd_model.cpp/.h, lbl_fluxes.cpp, and " *
            "average_optical_depth, plus build/script changes, the " *
            "solve_lbfgs backend switch, and removal of the v1.2 " *
            "bounded minimization -- changed TOGETHER; some underlying " *
            "files (calc_cost_function_lw.cpp, radiative_transfer_lw.cpp) " *
            "remain identical across that range. The experiment is " *
            "never described as single-variable, mechanism-isolated, or " *
            "backend-confirmed; the token 'isolation' persists only in " *
            "legacy filenames/case identifiers for path stability.",
        "followup_controls_proposed" => [
            "C1: PROPOSED one-factor fixed-run control -- v1.2 stack " *
                "with bounded_minimization=false, all other factors " *
                "held. C1 can quantify the one-factor effect of the " *
                "bounds flag for this fixed setup; a null result shows " *
                "no material effect under this setup ONLY and is never " *
                "described as formally retiring the bounds factor",
            "C2: PROPOSED, deferred -- era b42e5c0 stack with a " *
                "one-line USE_LBFGS_LIBRARY removal (era-Adept backend " *
                "inside the era stack; still source-confounded vs v1.2)",
            "C3: bound-position census and the associated " *
                "bounded-mode serialization anomaly are DEFERRED to a " *
                "dedicated ledger with full pinned computation; no " *
                "census numbers are recorded here because this ledger " *
                "does not compute or evidence them; no causal claim",
            "note: objective scoring is stack-independent (external " *
                "package objective); the confound lives in optimization " *
                "dynamics, not in scoring"],
        "non_authorizing_note" => "this ledger records and classifies " *
            "evidence; it does not itself submit, publish, or select " *
            "follow-up experiments -- downstream steps require explicit " *
            "monitor rulings",
        "disclaimer" => "evidence ledger; writes nothing except its own " *
            "JSON/MD results plus transient private temp " *
            "fixtures/snapshots (mktempdir); zero campaign/canonical " *
            "writes.")

    mkpath(dirname(BL_RESULTS_JSON))
    open(BL_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(BL_RESULTS_MD, "w") do io
        println(io, "# Gate-4 B0 era-stack completion ledger\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "Evidence timestamp (fixed, = job 4546 EndTime): " *
                    "$BL_EVIDENCE_TIME\n")
        println(io, "## Scientific result (reported; never a completion gate)\n")
        println(io, "| Quantity | Value |")
        println(io, "|---|---|")
        println(io, "| era raw2 swap objective | " *
                    "$(something(era_value, "NOT COMPUTED (evidence failed)")) |")
        println(io, "| published-context self-check | " *
                    "$(something(pub_value, "NOT COMPUTED")) |")
        for dd in scientific["references"]
            println(io, "| delta vs $(dd["reference"]) " *
                        "($(dd["reviewed_value"]); recomputed bit-exact: " *
                        "$(dd["recomputed_bit_exact"])) | " *
                        "$(dd["delta_era_minus_ref"]) " *
                        "(ratio $(dd["ratio_era_over_ref"])) |")
        end
        println(io, "\n", scientific["bounded_interpretation"])
        println(io, "\n## Gates\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\n## Attempts\n")
        println(io, "| Job | State | Exit | Classification |")
        println(io, "|---|---|---|---|")
        for a in result["attempts"]
            println(io, "| $(a["job_id"]) | $(a["job_state"]) | " *
                        "$(a["exit_code_raw"]) | " *
                        "$(first(a["classification"], 90))... |")
        end
        println(io, "\nConfound note: ", result["confound_note"])
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_b0_era_stack_completion_ledger: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "b0_run_completed_verified" ? 0 : 1
end

exit(main())
