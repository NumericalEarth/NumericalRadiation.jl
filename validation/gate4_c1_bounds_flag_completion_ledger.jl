# Gate-4 C1 BOUNDS-FLAG COMPLETION LEDGER (job 4562; DIAGNOSIS unit;
# writes ONLY its own JSON/MD results + transient private temp files).
#
# BINDING EVIDENCE CONTRACT (monitor, 2026-08-14, 8 points):
#   1) pin commit 6db5a238..., all five C1 package hashes, all custody
#      receipts, job/arm logs, RUNROOT artifacts; evidence time fixed
#      to EndTime 2026-08-14T07:27:13Z; exact COMPLETED fields and
#      exact stage/mode/status counts; failure regex empty.
#   2) INTERNAL VALIDITY: C0a-vs-C0b logical scientific identity via
#      the frozen 47-variable typed semantics (value differences
#      allowed ONLY in config/history) AND terminal-status exact
#      equality. Byte inequality is informational only; exact
#      differing attrs/vars reported; nothing inferred from hashes.
#   3) HISTORICAL BRIDGE: EACH control separately vs the pinned 4561
#      pristine raw2 under the same logical semantics; the bridge
#      cannot substitute for internal validity (and vice versa).
#   4) C1-vs-EACH-control NONFINITE-AWARE full logical diff: exact
#      schema/type/dim/typed attrs; per-variable elementwise isequal
#      deltas and explicit nonfinite masks/counts; NO materiality
#      threshold. The C1 serialized raw2 is all-finite HERE; the
#      returned minimizer x remains UNOBSERVED.
#   5) CENSUS: the committed S1 effective-bound kernel reused by exact
#      pinned source extraction/containment; both controls ALWAYS and
#      C1 BECAUSE FINITE (conditional branch preserved); per gas
#      lower/upper events separately, denominators, worst dlog, exact
#      index sets, event sum and computed unique union/overlap. The C1
#      census is labeled POST-HOC SERIALIZED output vs file-derived
#      bounds NOT supplied to the unbounded solver; it measures
#      neither returned-x feasibility nor enforcement.
#   6) COMPARATOR: pinned deterministic official_ecckd configuration,
#      H2O=0.005, published self-check bit-exact; C0a/C0b/C1 scored
#      TWICE EACH with per-artifact bit equality; exact objectives and
#      deltas; no threshold or repair language; the conditional
#      nonfinite skip branch is preserved and fixture-tested although
#      the finite branch fired.
#   7) PREREGISTERED MATRIX applied MECHANICALLY: only if C0a/C0b
#      logical identity AND terminal equality hold may differences be
#      called flag-associated FOR THIS FIXED SETUP; the bridge is
#      separate; C1 changes the bounded solver path AND the log-space
#      bound construction together (no mechanism isolation); all three
#      mechanism classes remain OPEN/UNRANKED globally; the internal
#      optimizer endpoint 16.7358 / 0.0290207 is DESCRIPTIVE, not a
#      comparator objective.
#   8) fixtures for every refusal direction (see cc_fixtures).
#
# COMPLETION STATUS IS INDEPENDENT OF SCIENTIFIC OUTCOME:
#   c1_run_completed_verified     -- every evidence group green (exit 0)
#   c1_completion_ledger_refused  -- ANY discrepancy (exit 1)

const CC_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
include(joinpath(CC_PROJECT_ROOT, "validation", "validation_results.jl"))

import JSON
using SHA: sha256
using NCDatasets

include(joinpath(CC_PROJECT_ROOT, "validation",
                 "ecckd_published_model_accuracy.jl"))

const CC_RUNROOT = "/shared/home/greg/ecckd-derived-flux-work/" *
    "g4-init-generation/g4-diag/4562/lw-c1"
const CC_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"

# --- commit + package pins (contract point 1) ---------------------------------------
const CC_COMMIT = "6db5a2381d49acac63f99194dce439f7caca0824"
const CC_COMMITTED = [
    ("validation/gate4_c1_bounds_flag_checkpoint.jl",
     "dd7bfe3f6de770218420bf0e80cd390819dd690c4abb241c5a599582ecc5c0f7"),
    ("validation/gate4_c1_frozen_design.md",
     "60f55abec74287a9aaec62070bbd393420de16dd10042fa63fbb5094a3ffa888"),
    ("validation/results/gate4_c1_lw_bounds_flag.sbatch",
     "817c16083af8eac2b335b70f68c10a6ecf3f465d171d22d17a3d4043f121017f"),
    ("validation/results/gate4_c1_bounds_flag_checkpoint.json",
     "95f982b4f961db21603910c7fca586e135e0a682f64d91de0c05678006f69a55"),
    ("validation/results/gate4_c1_bounds_flag_checkpoint.md",
     "bc6c253328deb4ccf4b59ce2c56785542954edc8cc0df1f612455a306550fdfa")]
const CC_VALIDATOR = joinpath(CC_PROJECT_ROOT,
    "validation/gate4_x1_sidecar_validator.jl")
const CC_VALIDATOR_SHA = "163363a693d6b0f273221c7eb51be7e468915659faa7794f125d7f5b3c08ff76"

# --- custody receipts ------------------------------------------------------------------
const CC_RECEIPT_SUBMISSION = ("$CC_LOG_DIR/g4-c1-lw-4562-submission-session40.txt",
    1925, "a20f6afabec2d98da80b9444984ecddbc2619cc9e05164def14c1eb34f57cd7e")
const CC_RECEIPT_AGENT42 = ("$CC_LOG_DIR/g4-c1-lw-4562-scontrol-final-agent42.txt",
    1654, "d09fe9f1e362cf239d35f5ccc6340c95aa9d463016374568f7084e02e4d21633")
const CC_RECEIPT_SESSION40 = ("$CC_LOG_DIR/g4-c1-lw-4562-scontrol-final-session40.txt",
    1819, "c7f0c2bd0b7b527403327890ba221ccf4b48d19fb15efae47a8afe350bfd4db4")
const CC_TOKEN_KEYS = ("JobId", "JobName", "JobState", "Reason",
    "ExitCode", "DerivedExitCode", "Restarts", "RunTime",
    "SubmitTime", "StartTime", "EndTime")
const CC_RECEIPT_EXPECT = Dict(
    "JobId" => "4562", "JobName" => "g4-c1-lw-bounds-flag",
    "JobState" => "COMPLETED", "Reason" => "None",
    "ExitCode" => "0:0", "DerivedExitCode" => "0:0",
    "Restarts" => "0", "RunTime" => "01:54:04",
    "SubmitTime" => "2026-08-14T05:30:11",
    "StartTime" => "2026-08-14T05:33:09",
    "EndTime" => "2026-08-14T07:27:13")
const CC_EVIDENCE_TS = "2026-08-14T07:27:13"

# --- job + arm logs ----------------------------------------------------------------------
const CC_LOG = ("$CC_LOG_DIR/g4-c1-lw-4562.log", 654838,
    "3bc44f893d06a3c994f486b81abba5745142141ee754b4dc1e5b2ed96dea3130")
const CC_ARM_LOGS = [
    ("probe", "$CC_RUNROOT/probe-base-run.log", 6177,
     "431b11c940fec0d067205c514ed7e6ff217b2935316afc8f8aa6395b42e73c07"),
    ("c0a", "$CC_RUNROOT/c0a-base-run.log", 202311,
     "32bccd921a276145ac9ad7eb777bfec034bf0efb9aff0992dfdba98cd2ef616c"),
    ("c1", "$CC_RUNROOT/c1-base-run.log", 202419,
     "79ea8dc592e8f4206931eb16ae603b51c08c49704d37f94d35b1e46655e4eeb6"),
    ("c0b", "$CC_RUNROOT/c0b-base-run.log", 202311,
     "7506d780774a67ea60eb3ab4ae1c1a92e2eb10657ba2e5d0c1a3a433e1e1d833")]
const CC_STAGES = ["0a", "0b", "0c", "0d", "1", "2", "3", "4",
                   "5-probe", "5-c0a", "5-c1", "5-c0b", "6"]
const CC_DONE_MARK = "=== C1-lw done 2026-08-14T07:27:13Z ==="
const CC_FAILURE_RE = r"REFUSED|SCHEMA-INVALID|sha mismatch|MISSING/nonexecutable|[Qq]uota exceeded|CANCELLED|slurmstepd: error|Traceback \(most recent call last\)|\bERROR\b|\bFATAL\b|\bFAILED\b|CHILD KILLED|CHILD FAILED|SIGFPE|Floating point exception"
const CC_BANNER_3000 = "Optimizing coefficients with Adept LBFGS " *
    "algorithm: max iterations = 3000, convergence criterion = 0.02"
const CC_BANNER_1 = "Optimizing coefficients with Adept LBFGS " *
    "algorithm: max iterations = 1, convergence criterion = 0.02"
const CC_STATUS_RECORD = "STATUS RECORD (descriptive, for the " *
    "completion ledger): probe='Maximum iterations reached' " *
    "c0a='Maximum iterations reached' c1='Maximum iterations reached' " *
    "c0b='Maximum iterations reached'"
const CC_BASELINE_ECHO = "BASELINE ECHO: C0a and C0b raw2 DIFFER at " *
    "byte level (informational; the ledger decides the internal gate)"
const CC_FLAG_ECHO = "FLAG ECHO: C1 and C0a raw2 DIFFER at byte level " *
    "(informational; expected -- the flag is upstream of the solve)"
const CC_C1_ENDPOINT = "Iteration 2999: cost function = 16.7358, gradient norm = 0.0290207"
const CC_CTRL_ENDPOINT = "Iteration 2999: cost function = 16.7768, gradient norm = 0.114057"

# --- RUNROOT artifacts ----------------------------------------------------------------
const CC_RAW2 = Dict(
    "probe" => ("$CC_RUNROOT/work-probe/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
                2415348, "377396e3fea8431f0edc189689f0e82558c198ec28bc588fc09b575ffdc5e1e9"),
    "c0a" => ("$CC_RUNROOT/work-c0a/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
              2415252, "39f3b75039077ae3bc4ef2437ec2c77f82ad117ad1b057aa02f6619103f70ca4"),
    "c1" => ("$CC_RUNROOT/work-c1/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
             2415292, "0f0189fa907e36370001b4cb78795990cea6ba80a9ebb135db8862f09dce6796"),
    "c0b" => ("$CC_RUNROOT/work-c0b/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
              2415252, "cb229f0a8a72e6699e2d64f11e90b566bc1d2624708f747da478108795925ea7"))
const CC_BIN = ("$CC_RUNROOT/bin/optimize_lut_c", 22141392,
    "26dac0eaa20269bffbf95efa796cd58a4fc47e356cc0a8436ebb67435ff9842e")
const CC_CONFIG_STATUS = ("$CC_RUNROOT/config.status.config.txt", 228,
    "0cd6e63d241aa3ee89d463cf2525244379e0a46fd1fa02acc8a450ecbb7b1884")
const CC_STATUS_FILES = [(r, "$CC_RUNROOT/$r-status.txt", 26,
    "6a1ab34df5844a46f729a6d7a200b4f2d0d2439f1aa31528c2f2f26202a9d027")
    for r in ("probe", "c0a", "c1", "c0b")]
const CC_STATUS_TEXT = "Maximum iterations reached"

const CC_BRIDGE_RAW2 = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/g4-diag/4561/lw-x1/work-pristine/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
const CC_BRIDGE_RAW2_BYTES = 2415304
const CC_BRIDGE_RAW2_SHA = "49ff3df8c02a1b62f7bfa6cd4b8dc2c6c96e93079c1d042eb8cfb5fc49c61e37"
const CC_INIT = ("/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc",
    2413144, "ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43")

# --- S1 kernel/comparator EXACT PINNED DEFINITION reuse (as X1 ledger) -----------------
const CC_S1_SOURCE = joinpath(CC_PROJECT_ROOT,
    "validation/gate4_s1_state_sync_completion_ledger.jl")
const CC_S1_SOURCE_SHA = "844acaa615d1ab139272c7425bbd0a5241d2b489b8a7a2ae2fdc9786f2463a3b"
const CC_S1_CENSUS = (below = 134, above = 19, lo_den = 152631,
    hi_den = 152640, active = 152640,
    worst_lo = 0.41887799902470135, worst_hi = 0.6268579421960787)
const CC_ACTIVE_GASES = ("composite", "h2o", "o3", "co2")
const CC_GAS_OFFSETS = Dict("composite" => 0, "h2o" => 10176,
                            "o3" => 132288, "co2" => 142464)

const CC_KERNEL_TEXT = raw"""function sl_census_gas(X, lo, hi, ini)
    # fail closed on nonfinite inputs: NaNs are never silently omitted
    # from predicates (the live job's finite gates should make this
    # unreachable; a violation is an instrument error, not a skip)
    for (nm, arr) in (("X", X), ("lo", lo), ("hi", hi), ("init", ini))
        all(isfinite, arr) ||
            throw(ArgumentError("nonfinite values in census input $nm"))
    end
    below = 0; above = 0; lo_den = 0; hi_den = 0
    worst_lo = 0.0; worst_hi = 0.0
    for i in eachindex(X)
        log_lo_eff = NaN
        if lo[i] > 0
            log_lo_eff = log(lo[i])
        elseif lo[i] == 0 && ini[i] > 0 && hi[i] > 0
            log_lo_eff = 3 * log(ini[i]) - 2 * log(hi[i])
        end
        if !isnan(log_lo_eff)
            lo_den += 1
            if X[i] <= 0
                # dlog exceedance of a positive lower bound by a
                # nonpositive value is +Inf, not zero
                below += 1
                worst_lo = Inf
            elseif log(X[i]) < log_lo_eff
                below += 1
                worst_lo = max(worst_lo, log_lo_eff - log(X[i]))
            end
        end
        if hi[i] > 0
            hi_den += 1
            if X[i] > 0 && log(X[i]) > log(hi[i])
                above += 1
                worst_hi = max(worst_hi, log(X[i]) - log(hi[i]))
            end
        end
    end
    (below = below, above = above, lo_den = lo_den, hi_den = hi_den,
     active = length(X), worst_lo = worst_lo, worst_hi = worst_hi)
end"""
const CC_H2O_TEXT = "const SL_H2O = 0.005"
const CC_COMPARATOR_TEXT = """function sl_swap_objective(lw_path, sw_path, cases)
    model = read_ecckd_tabulated_gas_optics(lw_path, sw_path;
        gas_names = OFFICIAL_ECCKD_GASES, h2o_mole_fraction = SL_H2O)
    hard_objective([case_metrics(c, model) for c in cases]).value
end"""

const CC_CODE_PINS = [
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
    ("Project.toml",
     "e3921c81ac9c8f6f6d2210f59e6195399643b4c8f66625b59b1d950da3493058")]
const CC_SRC_TREE = "7eaf80136e313c073416a815334493fc3b5434e7"
const CC_CASE_INPUTS = [
    ("ecckd_clear_sky_tropical_column",
     joinpath(CC_PROJECT_ROOT,
              "validation/reference/ecrad/ecckd_clear_sky_tropical_column.nc"),
     207210,
     "3a1634b7c7b4e22ae4064ace9826ac76b6810fb4074a5437bfd30b5c911e68e7"),
    ("ecckd_rcemip_style_column_subset",
     joinpath(CC_PROJECT_ROOT,
              "validation/reference/ecrad/ecckd_rcemip_style_column_subset.nc"),
     612490,
     "8c4a6974d74d09ae5f6679f76495538d1b9812edada7d87b1ed6737303710db3")]
const CC_PUB_SW_BYTES = 851724
const CC_PUB_SW_SHA = "49abc7bf88b80252e4f9934f8659d108ffee6a101124b2fd080f2eb65d144eb3"
const CC_PUB_LW_BYTES = 869280
const CC_PUB_LW_SHA = "6087f62f9052653f8e7dbee26cef8bf1977c2516669a169bee8d110b62912ed9"
const CC_PUBLISHED_BASELINE = 0.18218645425029933
const CC_COEFF_VARS = [g * "_molar_absorption_coeff" for g in CC_ACTIVE_GASES]

const CC_RESULTS_JSON = validation_results_path("gate4_c1_bounds_flag_completion_ledger.json")
const CC_RESULTS_MD = validation_results_path("gate4_c1_bounds_flag_completion_ledger.md")

# --- binding prose (fixture-guarded) -----------------------------------------------------
const CC_C1_CENSUS_LABEL = "POST-HOC SERIALIZED-OUTPUT census of the " *
    "C1 arm's serialized state against file-derived bounds that were " *
    "NOT supplied to the unbounded solver; it measures NEITHER " *
    "returned-x feasibility NOR bound enforcement (no capture " *
    "instrument; callback-state lag possible; the returned minimizer " *
    "x remains UNOBSERVED in C1 by design)"
const CC_PROBE_SCAN_LABEL = "the probe scan record is STRUCTURAL " *
    "EVIDENCE ONLY (frozen-design promise); the probe is NOT a fourth " *
    "scientific arm and its values never enter census, comparator, or " *
    "scientific interpretation"
const CC_CEILING = "C1 quantifies the bounded_minimization flag factor " *
    "for this fixed setup only. It discriminates NO mechanism: the " *
    "flag removes the bounded solver path AND the log-space bound " *
    "construction simultaneously. Only if C0a-vs-C0b logical identity " *
    "AND terminal-status exact equality hold may C1-vs-control " *
    "differences be called flag-associated FOR THIS FIXED SETUP; the " *
    "historical bridge is a SEPARATE question and neither substitutes " *
    "for the other. No repair, recovery, or causal claim is made about " *
    "any objective; the internal optimizer endpoint 16.7358 / " *
    "0.0290207 is descriptive and is not a comparator objective. All " *
    "three mechanism classes -- final-state synchronization, " *
    "mapping/write, bounded-algorithm behavior -- remain OPEN and " *
    "UNRANKED globally; findings are LOCAL to this rebuilt trajectory; " *
    "no historical or global claim."

# --- primitives ---------------------------------------------------------------------------

cc_try_sha(path) = try
    isfile(path) || return nothing
    open(io -> bytes2hex(sha256(io)), path)
catch
    nothing
end

function cc_read_pinned(path, sha; size = nothing, label = basename(path))
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

function cc_pinned_snapshot(path, size, sha; label = basename(path))
    iss, bytes = cc_read_pinned(path, sha; size = size, label = label)
    bytes === nothing && return (iss, nothing)
    snap = joinpath(mktempdir(), "snap_" * basename(path))
    write(snap, bytes)
    (String[], snap)
end

cc_count(text, needle) = length(collect(eachmatch(
    Regex("\\Q" * needle * "\\E"), text)))

function cc_parse_receipt(text)
    f = Dict{String, String}()
    for m in eachmatch(r"([A-Za-z]+)=([^\s]+)", text)
        k = String(m.captures[1])
        k in CC_TOKEN_KEYS && !haskey(f, k) && (f[k] = String(m.captures[2]))
    end
    f
end

function cc_bracketed(fn, path, sha)
    pre = cc_try_sha(path)
    pre == sha || return (["pre-open sha $pre != pinned $sha: $path"],
                          nothing)
    out = try
        NCDataset(fn, path)
    catch err
        return (["NetCDF read failed for $path: " *
                 sprint(showerror, err)], nothing)
    end
    post = cc_try_sha(path)
    post == sha || return (["post-close sha $post != pinned $sha: $path"],
                           nothing)
    (String[], out)
end

# pinned 47-variable stored-type+dim signature and COMPLETE dims map,
# derived under SHA brackets from the PINNED INITIAL RAW ONLY (the
# signature authority; live outputs are never treated as authority)
function cc_signature_of(path, sha)
    pre = cc_try_sha(path)
    pre == sha || return (["pre-open sha $pre != pinned $sha: $path"],
                          nothing, nothing)
    out = try
        NCDataset(path) do ds
            sig = Dict(String(k) =>
                (string(eltype(ds[k].var)),
                 collect(String.(dimnames(ds[k]))))
                for k in keys(ds))
            dims = sort([(String(k), Int(ds.dim[k])) for k in keys(ds.dim)];
                        by = first)
            (sig, dims)
        end
    catch err
        return (["signature read failed for $path: " *
                 sprint(showerror, err)], nothing, nothing)
    end
    post = cc_try_sha(path)
    post == sha || return (["post-close sha $post != pinned $sha: $path"],
                           nothing, nothing)
    (String[], out[1], out[2])
end

# SHARED full 47-variable scanner (monitor blocker 1): exact pinned
# stored-type/dim signature + complete dims map enforced; per-variable
# MISSING and NONFINITE counts recorded across ALL variables. Routing
# (by the caller): structural faults and MISSING values refuse in
# EVERY arm; numeric NaN/Inf is lawful for C1 only and drives the
# shared census+comparator skip with identical counts/reason.
function cc_full_scan(path, sha, sig, dims)
    iss = String[]
    per_missing = Dict{String, Int}()
    per_nonfinite = Dict{String, Int}()
    b_iss, _ = cc_read_pinned(path, sha)
    append!(iss, b_iss)
    isempty(iss) || return (iss, per_missing, per_nonfinite)
    NCDataset(path) do ds
        dims_have = sort([(String(k), Int(ds.dim[k])) for k in keys(ds.dim)];
                         by = first)
        dims_have == dims ||
            push!(iss, "dimension map != pinned signature authority")
        have = sort([String(k) for k in keys(ds)])
        expected = sort(collect(keys(sig)))
        for v in setdiff(expected, have)
            push!(iss, "var missing: " * v)
        end
        for v in setdiff(have, expected)
            push!(iss, "unexpected extra var: " * v)
        end
        for k in intersect(expected, have)
            et, dn = sig[k]
            string(eltype(ds[k].var)) == et ||
                push!(iss, "var $k stored type $(string(eltype(ds[k].var))) != pinned $et")
            collect(String.(dimnames(ds[k]))) == dn ||
                push!(iss, "var $k dims != pinned signature")
            a = try
                Array(ds[k])
            catch
                push!(iss, "unreadable var $k")
                continue
            end
            nm = count(ismissing, a)
            nm > 0 && (per_missing[k] = nm)
            nf = count(x -> !ismissing(x) && !isfinite(x), a)
            nf > 0 && (per_nonfinite[k] = nf)
        end
    end
    post = cc_try_sha(path)
    post == sha || push!(iss, "post-scan sha != pinned: $path")
    (iss, per_missing, per_nonfinite)
end

# helper-wired twice-scoring gate (monitor blocker 3 + Agent 42 A3):
# the SAME helper runs in main (real comparator closure) and in
# fixtures (stub scorers); BOTH repeats are returned so the JSON can
# record per-artifact determinism evidence auditable on its own
function cc_score_twice(scorer, label, expected)
    iss = String[]
    v1 = scorer()
    v2 = scorer()
    v1 == v2 ||
        push!(iss, "$label objective not repeatable in-run ($v1 vs $v2)")
    expected === nothing || v1 == expected ||
        push!(iss, "$label objective $v1 != pinned $expected (bit-exact required)")
    (iss, v1, v2)
end

# real gate-path helpers (Agent 42 A1/A2): the SAME code runs in main
# and in fixtures -- never literal-vs-literal tautologies
cc_control_status_equal(statuses) =
    haskey(statuses, "c0a") && haskey(statuses, "c0b") &&
    statuses["c0a"] == statuses["c0b"]

function cc_receipt_token_issues(a, s, expect)
    iss = String[]
    for k in CC_TOKEN_KEYS
        av = get(a, k, "<absent-a42>")
        sv = get(s, k, "<absent-s40>")
        av == sv ||
            push!(iss, "terminal receipts disagree on $k: $av vs $sv")
        sv == expect[k] ||
            push!(iss, "receipt token $k = $sv != pinned $(expect[k])")
    end
    iss
end

# census set mirror (X1-ledger convention adapted): zero-based linear
# indices in the Julia storage order of each coefficient array, offset
# by the fixed gas-block layout (an internal set convention,
# cross-checked against the extracted kernel counts on every target)
function cc_census_sets(X, lo, hi, ini, offset)
    below_set = Int[]; above_set = Int[]
    lo_den = 0; hi_den = 0
    worst_lo = 0.0; worst_hi = 0.0
    for i in eachindex(X)
        gxi = offset + i - 1
        log_lo_eff = NaN
        if lo[i] > 0
            log_lo_eff = log(lo[i])
        elseif lo[i] == 0 && ini[i] > 0 && hi[i] > 0
            log_lo_eff = 3 * log(ini[i]) - 2 * log(hi[i])
        end
        if !isnan(log_lo_eff)
            lo_den += 1
            if X[i] <= 0
                push!(below_set, gxi)
                worst_lo = Inf
            elseif log(X[i]) < log_lo_eff
                push!(below_set, gxi)
                worst_lo = max(worst_lo, log_lo_eff - log(X[i]))
            end
        end
        if hi[i] > 0
            hi_den += 1
            if X[i] > 0 && log(X[i]) > log(hi[i])
                push!(above_set, gxi)
                worst_hi = max(worst_hi, log(X[i]) - log(hi[i]))
            end
        end
    end
    (below_set = below_set, above_set = above_set,
     lo_den = lo_den, hi_den = hi_den,
     worst_lo = worst_lo, worst_hi = worst_hi)
end

# census of one raw2 (conditional two-tier: label + finite pre-scan;
# nonfinite in the target => recorded skip for C1, refusal-class issue
# for controls, decided by the CALLER)
function cc_census_file(coeffs, init)
    iss = String[]
    per_gas = Dict{String, Any}()
    tot = Dict("below" => 0, "above" => 0, "lo_den" => 0, "hi_den" => 0,
               "active" => 0)
    worst_lo = 0.0; worst_hi = 0.0
    below_all = Int[]; above_all = Int[]
    for g in CC_ACTIVE_GASES
        X = Float64.(vec(coeffs[g * "_molar_absorption_coeff"]))
        lo = Float64.(vec(init[g].mn))
        hi = Float64.(vec(init[g].mx))
        ini = Float64.(vec(init[g].ini))
        kres = sl_census_gas(X, lo, hi, ini)
        sres = cc_census_sets(X, lo, hi, ini, CC_GAS_OFFSETS[g])
        (length(sres.below_set) == kres.below &&
         length(sres.above_set) == kres.above &&
         sres.lo_den == kres.lo_den && sres.hi_den == kres.hi_den &&
         sres.worst_lo == kres.worst_lo &&
         sres.worst_hi == kres.worst_hi) ||
            push!(iss, "$g: set mirror disagrees with the pinned kernel (instrument refusal)")
        per_gas[g] = Dict("below" => kres.below, "above" => kres.above,
                          "lo_den" => kres.lo_den,
                          "hi_den" => kres.hi_den,
                          "worst_lo_dlog" => kres.worst_lo,
                          "worst_hi_dlog" => kres.worst_hi)
        tot["below"] += kres.below; tot["above"] += kres.above
        tot["lo_den"] += kres.lo_den; tot["hi_den"] += kres.hi_den
        tot["active"] += kres.active
        worst_lo = max(worst_lo, kres.worst_lo)
        worst_hi = max(worst_hi, kres.worst_hi)
        append!(below_all, sres.below_set)
        append!(above_all, sres.above_set)
    end
    uniq = sort(union(below_all, above_all))
    res = Dict(
        "below" => tot["below"], "above" => tot["above"],
        "lo_den" => tot["lo_den"], "hi_den" => tot["hi_den"],
        "active" => tot["active"],
        "worst_lo_dlog" => worst_lo, "worst_hi_dlog" => worst_hi,
        "per_gas" => per_gas,
        "below_set" => sort(below_all), "above_set" => sort(above_all),
        "event_sum" => tot["below"] + tot["above"],
        "unique_coordinates" => length(uniq),
        "below_above_overlap_set" => sort(intersect(below_all, above_all)),
        "index_convention" => "zero-based linear indices in the Julia " *
            "storage order of each coefficient array, offset by the " *
            "fixed gas-block layout (composite 0, h2o 10176, o3 " *
            "132288, co2 142464); internal to this ledger and " *
            "cross-checked against the pinned kernel counts")
    (iss, res)
end

# nonfinite-aware full logical diff (contract point 4): structure
# strictly (dims/vars/stored types/typed attrs; global attr name set +
# values outside allowed); values via elementwise isequal deltas with
# explicit nonfinite counts per side; NO materiality threshold
function cc_nonfinite_aware_diff(a_path, a_sha, b_path, b_sha;
                                 allowed_value_diff = ["config", "history"],
                                 required_value_diffs = ["config", "history"])
    iss = String[]
    per_var = Dict{String, Any}()
    actual_global_diffs = String[]
    a_iss, _ = cc_read_pinned(a_path, a_sha)
    append!(iss, a_iss)
    b_iss, _ = cc_read_pinned(b_path, b_sha)
    append!(iss, b_iss)
    isempty(iss) || return (iss, per_var, actual_global_diffs)
    NCDataset(a_path) do da
        NCDataset(b_path) do db
            # PHASE 1: structure -- any fault refuses CLEANLY before
            # value traversal (no indexing across mismatched shapes)
            ka = sort(collect(keys(da.dim)))
            kb = sort(collect(keys(db.dim)))
            ka == kb || push!(iss, "dimension name sets differ: $ka vs $kb")
            for d in intersect(ka, kb)
                da.dim[d] == db.dim[d] ||
                    push!(iss, "dim $d extent differs: $(da.dim[d]) vs $(db.dim[d])")
            end
            ga = sort([String(k) for k in keys(da.attrib)])
            gb = sort([String(k) for k in keys(db.attrib)])
            ga == gb || push!(iss, "global attribute name sets differ")
            for at in intersect(ga, gb)
                va = da.attrib[at]; vb = db.attrib[at]
                if typeof(va) != typeof(vb)
                    push!(iss, "global attribute $at differs IN TYPE " *
                        "($(typeof(va)) vs $(typeof(vb)))")
                elseif !isequal(va, vb)
                    push!(actual_global_diffs, at)
                    at in allowed_value_diff ||
                        push!(iss, "global attribute $at differs outside the allowed set")
                end
            end
            # the ACTUAL typed difference set is REQUIRED to equal the
            # preregistered set exactly (monitor blocker 2)
            if required_value_diffs !== nothing
                sort(actual_global_diffs) ==
                    sort(String.(collect(required_value_diffs))) ||
                    push!(iss, "actual differing-global-attribute set " *
                        "$(sort(actual_global_diffs)) != required exact " *
                        "set $(sort(String.(collect(required_value_diffs))))")
            end
            va_names = sort([String(k) for k in keys(da)])
            vb_names = sort([String(k) for k in keys(db)])
            va_names == vb_names ||
                push!(iss, "variable name sets differ")
            for v in intersect(va_names, vb_names)
                xa = da[v]; xb = db[v]
                Tuple(dimnames(xa)) == Tuple(dimnames(xb)) ||
                    push!(iss, "var $v dims differ (structural)")
                eltype(xa.var) == eltype(xb.var) ||
                    push!(iss, "var $v stored type differs (structural)")
                aa = sort([String(k) for k in keys(xa.attrib)])
                ab = sort([String(k) for k in keys(xb.attrib)])
                aa == ab || push!(iss, "var $v attribute name sets differ")
                for at in intersect(aa, ab)
                    pa = xa.attrib[at]; pb = xb.attrib[at]
                    if typeof(pa) != typeof(pb)
                        push!(iss, "var $v attribute $at differs IN TYPE " *
                            "($(typeof(pa)) vs $(typeof(pb)))")
                    elseif !isequal(pa, pb)
                        push!(iss, "var $v attribute $at differs IN VALUE (typed comparison)")
                    end
                end
            end
            # any structural fault: refuse before value traversal
            isempty(iss) || return nothing
            # PHASE 2: values (shapes proven equal by phase 1)
            for v in va_names
                Aa = Array(da[v]); Ab = Array(db[v])
                if size(Aa) != size(Ab)
                    push!(iss, "var $v shapes differ (guarded; no traversal)")
                    continue
                end
                nd = count(i -> !isequal(Aa[i], Ab[i]), eachindex(Aa))
                nfa = count(x -> !ismissing(x) && !isfinite(x), Aa)
                nfb = count(x -> !ismissing(x) && !isfinite(x), Ab)
                maxabs = 0.0
                if nd > 0 && eltype(Aa) <: Union{Missing, Real}
                    for i in eachindex(Aa)
                        (ismissing(Aa[i]) || ismissing(Ab[i])) && continue
                        (isfinite(Aa[i]) && isfinite(Ab[i])) || continue
                        maxabs = max(maxabs, abs(Float64(Aa[i]) -
                                                 Float64(Ab[i])))
                    end
                end
                (nd > 0 || nfa > 0 || nfb > 0) &&
                    (per_var[v] = Dict("elementwise_diff_count" => nd,
                                       "max_abs_diff_finite" => maxabs,
                                       "nonfinite_count_a" => nfa,
                                       "nonfinite_count_b" => nfb))
            end
            nothing
        end
    end
    (iss, per_var, sort(actual_global_diffs))
end

# mechanical preregistered-matrix classifier (contract point 7)
function cc_matrix(identity_ok, status_equal, bridge_a_ok, bridge_b_ok)
    internal = identity_ok && status_equal
    internal_txt = internal ?
        "INTERNAL VALIDITY HOLDS: C0a == C0b logically AND terminal " *
        "statuses exactly equal; C1-vs-control differences are " *
        "flag-associated FOR THIS FIXED SETUP (no mechanism claim)" :
        "INTERNAL VALIDITY FAILED (" *
        (identity_ok ? "" : "logical identity failed") *
        (identity_ok || status_equal ? "" : "; ") *
        (status_equal ? "" : "terminal statuses differ") *
        "): flag attribution is INCONCLUSIVE; all C1 comparisons/" *
        "objectives/censuses are DESCRIPTIVE; no post-hoc noise rule"
    bridge_txt = (bridge_a_ok && bridge_b_ok) ?
        "HISTORICAL BRIDGE HOLDS for both controls vs the 4561 " *
        "pristine raw2 (extends the connection to the X1 trajectory; " *
        "does NOT replace the internal gate)" :
        "HISTORICAL BRIDGE " *
        ((bridge_a_ok || bridge_b_ok) ? "PARTIAL" : "FAILED") *
        " (limits the connection to X1/history; does NOT invalidate " *
        "a repeatable same-job one-factor comparison)"
    (internal = internal, internal_txt = internal_txt,
     bridge_txt = bridge_txt)
end

cc_overall(groups) = all(isempty, values(groups)) ?
    "c1_run_completed_verified" : "c1_completion_ledger_refused"

# --- TOP-LEVEL extraction + frozen-validator include (world-age safe) --------------------
const CC_EXTRACTION_ISSUES = String[]
let
    iss, bytes = cc_read_pinned(CC_S1_SOURCE, CC_S1_SOURCE_SHA;
                                label = "pinned S1 ledger source")
    append!(CC_EXTRACTION_ISSUES, iss)
    if bytes !== nothing
        s1txt = String(copy(bytes))
        for (txt, what) in ((CC_KERNEL_TEXT, "census kernel"),
                            (CC_H2O_TEXT, "H2O constant"),
                            (CC_COMPARATOR_TEXT, "comparator"))
            occursin(txt, s1txt) ||
                push!(CC_EXTRACTION_ISSUES,
                      "$what text not contained byte-for-byte in the pinned S1 source")
        end
    end
end
if isempty(CC_EXTRACTION_ISSUES)
    include_string(@__MODULE__, CC_H2O_TEXT)
    include_string(@__MODULE__, CC_KERNEL_TEXT)
    include_string(@__MODULE__, CC_COMPARATOR_TEXT)
end
const CC_VALIDATOR_ISSUES =
    cc_try_sha(CC_VALIDATOR) == CC_VALIDATOR_SHA ? String[] :
    ["frozen validator sha $(cc_try_sha(CC_VALIDATOR)) != pinned $CC_VALIDATOR_SHA"]
isempty(CC_VALIDATOR_ISSUES) && include(CC_VALIDATOR)

# --- fixtures ------------------------------------------------------------------------------

function cc_fixtures()
    t = Dict{String, Bool}()
    fx = mktempdir()

    # pin machinery
    p = joinpath(fx, "x.bin"); write(p, "abc")
    sh = bytes2hex(sha256("abc"))
    t["pin_green_accepted"] = isempty(cc_read_pinned(p, sh; size = 3)[1])
    t["pin_sha_drift_refuses"] = !isempty(cc_read_pinned(p, "0"^64)[1])
    t["pin_size_drift_refuses"] =
        !isempty(cc_read_pinned(p, sh; size = 4)[1])
    t["pin_missing_refuses"] =
        !isempty(cc_read_pinned(joinpath(fx, "none"), sh)[1])

    # receipt tokens
    r1 = cc_parse_receipt("JobId=4562 JobName=g4-c1-lw-bounds-flag " *
        "JobState=COMPLETED Reason=None ExitCode=0:0 " *
        "DerivedExitCode=0:0 Restarts=0 RunTime=01:54:04 " *
        "SubmitTime=2026-08-14T05:30:11 StartTime=2026-08-14T05:33:09 " *
        "EndTime=2026-08-14T07:27:13")
    t["receipt_tokens_parse"] = r1 == CC_RECEIPT_EXPECT &&
        isempty(cc_receipt_token_issues(r1, r1, CC_RECEIPT_EXPECT))
    t["receipt_malformed_string_refuses"] = begin
        # failure direction from the RAW STRING through the real path
        bad = cc_parse_receipt("completely malformed receipt; no tokens")
        !isempty(cc_receipt_token_issues(bad, bad, CC_RECEIPT_EXPECT))
    end
    t["receipt_token_drift_string_refuses"] = begin
        drift = cc_parse_receipt("JobId=4562 " *
            "JobName=g4-c1-lw-bounds-flag JobState=COMPLETED " *
            "Reason=None ExitCode=1:0 DerivedExitCode=0:0 Restarts=0 " *
            "RunTime=01:54:04 SubmitTime=2026-08-14T05:30:11 " *
            "StartTime=2026-08-14T05:33:09 EndTime=2026-08-14T07:27:13")
        iss2 = cc_receipt_token_issues(r1, drift, CC_RECEIPT_EXPECT)
        any(occursin("disagree on ExitCode", i) for i in iss2) &&
            any(occursin("ExitCode = 1:0 != pinned 0:0", i) for i in iss2)
    end
    t["control_status_gate_real_path"] = begin
        # the ACTUAL gate helper used by main, mutated-status direction
        eq = cc_control_status_equal(Dict(
            "c0a" => "Maximum iterations reached",
            "c0b" => "Maximum iterations reached"))
        ne = cc_control_status_equal(Dict(
            "c0a" => "Maximum iterations reached",
            "c0b" => "Converged"))
        mk = cc_control_status_equal(Dict(
            "c0a" => "Maximum iterations reached"))
        eq && !ne && !mk
    end

    # census kernel + set mirror + overlap accounting
    X = [1.0e-3, 1.0e-9, 0.0, 5.0, 1.0e-2]
    klo = [1.0e-4, 1.0e-4, 1.0e-4, 0.0, 0.0]
    khi = [1.0, 1.0, 1.0, 2.0, 0.0]
    kini = [1.0e-2, 1.0e-2, 1.0e-2, 1.0e-1, 0.0]
    kr = sl_census_gas(X, klo, khi, kini)
    t["census_kernel_hand_case"] = kr.below == 2 && kr.above == 1 &&
        kr.lo_den == 4 && kr.hi_den == 4 && kr.worst_lo == Inf
    sr = cc_census_sets(X, klo, khi, kini, 100)
    t["census_set_mirror_agrees"] =
        length(sr.below_set) == kr.below &&
        length(sr.above_set) == kr.above &&
        sr.below_set == [101, 102] && sr.above_set == [103] &&
        sr.worst_lo == kr.worst_lo && sr.worst_hi == kr.worst_hi
    t["census_kernel_nonfinite_refuses"] = begin
        ok = false
        try
            sl_census_gas([NaN], [1.0], [2.0], [1.0])
        catch
            ok = true
        end
        ok
    end
    t["census_overlap_computed_not_inferred"] = begin
        below_s = [1, 2, 3]; above_s = [3, 4]
        length(union(below_s, above_s)) == 4 &&
            intersect(below_s, above_s) == [3]
    end

    # nonfinite-aware diff (synthetic pair; config AND history differ so
    # the required actual-diff set {config,history} is satisfied)
    d = mktempdir()
    for (pp, second) in ((joinpath(d, "a.nc"), false),
                         (joinpath(d, "b.nc"), true))
        NCDataset(pp, "c") do ds
            defDim(ds, "n", 4)
            v = defVar(ds, "alpha", Float64, ("n",))
            v[:] = second ? [1.0, 2.5, NaN, 4.0] : [1.0, 2.0, 3.0, 4.0]
            w = defVar(ds, "beta", Float32, ("n",))
            w[:] = Float32[1, 2, 3, 4]
            ds.attrib["config"] = second ? "B" : "A"
            ds.attrib["history"] = second ? "hB" : "hA"
            ds.attrib["title"] = "same"
        end
    end
    sha_a = cc_try_sha(joinpath(d, "a.nc"))
    sha_b = cc_try_sha(joinpath(d, "b.nc"))
    iss_d, pv, gd = cc_nonfinite_aware_diff(joinpath(d, "a.nc"), sha_a,
                                            joinpath(d, "b.nc"), sha_b)
    t["diff_structure_clean_values_counted"] = isempty(iss_d) &&
        haskey(pv, "alpha") && pv["alpha"]["elementwise_diff_count"] == 2 &&
        pv["alpha"]["nonfinite_count_b"] == 1 &&
        pv["alpha"]["nonfinite_count_a"] == 0 &&
        pv["alpha"]["max_abs_diff_finite"] == 0.5 && !haskey(pv, "beta")
    t["diff_actual_global_set_reported"] = gd == ["config", "history"]
    t["diff_required_set_missing_member_refuses"] = begin
        # history identical although required: actual != required
        d2 = mktempdir()
        for (pp, second) in ((joinpath(d2, "a.nc"), false),
                             (joinpath(d2, "b.nc"), true))
            NCDataset(pp, "c") do ds
                defDim(ds, "n", 2)
                v = defVar(ds, "alpha", Float64, ("n",))
                v[:] = [1.0, 2.0]
                ds.attrib["config"] = second ? "B" : "A"
                ds.attrib["history"] = "same"
            end
        end
        iss2, _, _ = cc_nonfinite_aware_diff(joinpath(d2, "a.nc"),
            cc_try_sha(joinpath(d2, "a.nc")), joinpath(d2, "b.nc"),
            cc_try_sha(joinpath(d2, "b.nc")))
        any(occursin("!= required exact", i) for i in iss2)
    end
    t["diff_shape_drift_refuses_before_traversal"] = begin
        # dim extent drift must refuse CLEANLY (no cross-shape indexing)
        d2 = mktempdir()
        for (pp, n) in ((joinpath(d2, "a.nc"), 2), (joinpath(d2, "b.nc"), 3))
            NCDataset(pp, "c") do ds
                defDim(ds, "n", n)
                v = defVar(ds, "alpha", Float64, ("n",))
                v[:] = ones(n)
                ds.attrib["config"] = "same"
                ds.attrib["history"] = "same"
            end
        end
        iss2, pv2, _ = cc_nonfinite_aware_diff(joinpath(d2, "a.nc"),
            cc_try_sha(joinpath(d2, "a.nc")), joinpath(d2, "b.nc"),
            cc_try_sha(joinpath(d2, "b.nc")))
        any(occursin("extent differs", i) for i in iss2) && isempty(pv2)
    end
    t["diff_var_attr_type_drift_refuses"] = begin
        d2 = mktempdir()
        for (pp, second) in ((joinpath(d2, "a.nc"), false),
                             (joinpath(d2, "b.nc"), true))
            NCDataset(pp, "c") do ds
                defDim(ds, "n", 2)
                v = defVar(ds, "alpha", Float64, ("n",))
                v[:] = [1.0, 2.0]
                v.attrib["units"] = second ? Int32(7) : "m"
                ds.attrib["config"] = second ? "B" : "A"
                ds.attrib["history"] = second ? "hB" : "hA"
            end
        end
        iss2, _, _ = cc_nonfinite_aware_diff(joinpath(d2, "a.nc"),
            cc_try_sha(joinpath(d2, "a.nc")), joinpath(d2, "b.nc"),
            cc_try_sha(joinpath(d2, "b.nc")))
        any(occursin("attribute units differs IN TYPE", i) for i in iss2)
    end
    t["diff_global_attr_type_drift_refuses"] = begin
        d2 = mktempdir()
        for (pp, second) in ((joinpath(d2, "a.nc"), false),
                             (joinpath(d2, "b.nc"), true))
            NCDataset(pp, "c") do ds
                defDim(ds, "n", 2)
                v = defVar(ds, "alpha", Float64, ("n",))
                v[:] = [1.0, 2.0]
                if second
                    ds.attrib["config"] = Int32(9)
                else
                    ds.attrib["config"] = "A"
                end
                ds.attrib["history"] = second ? "hB" : "hA"
            end
        end
        iss2, _, _ = cc_nonfinite_aware_diff(joinpath(d2, "a.nc"),
            cc_try_sha(joinpath(d2, "a.nc")), joinpath(d2, "b.nc"),
            cc_try_sha(joinpath(d2, "b.nc")))
        any(occursin("global attribute config differs IN TYPE", i)
            for i in iss2)
    end
    t["diff_missing_and_extra_var_refuses"] = begin
        d2 = mktempdir()
        NCDataset(joinpath(d2, "a.nc"), "c") do ds
            defDim(ds, "n", 2)
            v = defVar(ds, "alpha", Float64, ("n",))
            v[:] = [1.0, 2.0]
            ds.attrib["config"] = "A"; ds.attrib["history"] = "hA"
        end
        NCDataset(joinpath(d2, "b.nc"), "c") do ds
            defDim(ds, "n", 2)
            v = defVar(ds, "gamma", Float64, ("n",))
            v[:] = [1.0, 2.0]
            ds.attrib["config"] = "B"; ds.attrib["history"] = "hB"
        end
        iss2, _, _ = cc_nonfinite_aware_diff(joinpath(d2, "a.nc"),
            cc_try_sha(joinpath(d2, "a.nc")), joinpath(d2, "b.nc"),
            cc_try_sha(joinpath(d2, "b.nc")))
        any(occursin("variable name sets differ", i) for i in iss2)
    end

    # SHARED full-scan behavioral fixtures (blocker 1): tiny pinned
    # signature; nonfinite in a NON-coefficient variable
    fsd = mktempdir()
    tsig = Dict("coeff" => ("Float32", ["n"]),
                "planck_like" => ("Float64", ["n"]))
    tdims = [("n", 3)]
    function write_scan(path; planck = [1.0, 2.0, 3.0],
                        with_missing = false, coeff_ty = Float32,
                        drop = false, extra = false, n = 3)
        isfile(path) && rm(path)
        NCDataset(path, "c") do ds
            defDim(ds, "n", n)
            if !drop
                v = defVar(ds, "coeff", coeff_ty, ("n",))
                v[:] = coeff_ty.(1:n)
            end
            if with_missing
                w = defVar(ds, "planck_like", Float64, ("n",);
                           fillvalue = -999.0)
                w[:] = [1.0, missing, 3.0]
            else
                w = defVar(ds, "planck_like", Float64, ("n",))
                w[:] = planck
            end
            if extra
                e = defVar(ds, "surprise", Float64, ("n",))
                e[:] = zeros(n)
            end
        end
        path
    end
    gp = write_scan(joinpath(fsd, "good.nc"))
    scn(p) = cc_full_scan(p, cc_try_sha(p), tsig, tdims)
    t["scan_conforming_clean"] = begin
        i, pm, pnf = scn(gp)
        isempty(i) && isempty(pm) && isempty(pnf)
    end
    t["scan_noncoeff_nonfinite_recorded_and_routed"] = begin
        p2 = write_scan(joinpath(fsd, "nf.nc"); planck = [1.0, Inf, NaN])
        i, pm, pnf = scn(p2)
        # scan itself clean structurally; counts recorded; ROUTING:
        # control branch refuses; C1 branch takes the SHARED dual skip
        control_refuses = !isempty(pnf)
        c1_total = sum(values(pnf); init = 0)
        c1_dual_skip = c1_total > 0
        isempty(i) && isempty(pm) && pnf == Dict("planck_like" => 2) &&
            control_refuses && c1_dual_skip
    end
    t["scan_missing_refuses_every_arm"] = begin
        p2 = write_scan(joinpath(fsd, "ms.nc"); with_missing = true)
        i, pm, pnf = scn(p2)
        # per-missing recorded; routing treats ANY missing as a
        # structural/value-integrity fault in EVERY arm
        pm == Dict("planck_like" => 1)
    end
    t["scan_type_drift_refuses"] = begin
        p2 = write_scan(joinpath(fsd, "ty.nc"); coeff_ty = Float64)
        i, _, _ = scn(p2)
        any(occursin("stored type", x) for x in i)
    end
    t["scan_missing_var_refuses"] = begin
        p2 = write_scan(joinpath(fsd, "dv.nc"); drop = true)
        i, _, _ = scn(p2)
        any(occursin("var missing", x) for x in i)
    end
    t["scan_extra_var_refuses"] = begin
        p2 = write_scan(joinpath(fsd, "xv.nc"); extra = true)
        i, _, _ = scn(p2)
        any(occursin("unexpected extra var", x) for x in i)
    end
    t["scan_dim_extent_drift_refuses"] = begin
        p2 = write_scan(joinpath(fsd, "de.nc"); n = 4,
                        planck = [1.0, 2.0, 3.0, 4.0])
        i, _, _ = scn(p2)
        any(occursin("dimension map != pinned", x) for x in i)
    end

    # helper-wired comparator gates (blocker 3)
    t["score_twice_repeat_gate_fires"] = begin
        c = Ref(0)
        stub = () -> (c[] += 1; c[] == 1 ? 1.25 : 1.26)
        iss2, _ = cc_score_twice(stub, "stub", nothing)
        any(occursin("not repeatable", i) for i in iss2)
    end
    t["score_twice_pin_gate_fires"] = begin
        iss2, _ = cc_score_twice(() -> 1.25, "stub", 9.9)
        any(occursin("!= pinned", i) for i in iss2)
    end
    t["score_twice_clean_passes_and_returns_both"] = begin
        iss2, v1, v2 = cc_score_twice(() -> 1.25, "stub", 1.25)
        isempty(iss2) && v1 == 1.25 && v2 == 1.25 && (v1 == v2)
    end
    t["diff_disallowed_global_attr_refuses"] = begin
        d2 = mktempdir()
        for (pp, second) in ((joinpath(d2, "a.nc"), false),
                             (joinpath(d2, "b.nc"), true))
            NCDataset(pp, "c") do ds
                defDim(ds, "n", 2)
                v = defVar(ds, "alpha", Float64, ("n",))
                v[:] = [1.0, 2.0]
                ds.attrib["config"] = "same"
                ds.attrib["history"] = "same"
                ds.attrib["title"] = second ? "B" : "A"
            end
        end
        iss2, _ = cc_nonfinite_aware_diff(joinpath(d2, "a.nc"),
            cc_try_sha(joinpath(d2, "a.nc")), joinpath(d2, "b.nc"),
            cc_try_sha(joinpath(d2, "b.nc")))
        any(occursin("outside the allowed set", i) for i in iss2)
    end
    t["diff_type_structure_refuses"] = begin
        d2 = mktempdir()
        for (pp, second) in ((joinpath(d2, "a.nc"), false),
                             (joinpath(d2, "b.nc"), true))
            NCDataset(pp, "c") do ds
                defDim(ds, "n", 2)
                v = defVar(ds, "alpha", second ? Float32 : Float64, ("n",))
                v[:] = second ? Float32[1, 2] : [1.0, 2.0]
                ds.attrib["config"] = "same"
                ds.attrib["history"] = "same"
            end
        end
        iss2, _ = cc_nonfinite_aware_diff(joinpath(d2, "a.nc"),
            cc_try_sha(joinpath(d2, "a.nc")), joinpath(d2, "b.nc"),
            cc_try_sha(joinpath(d2, "b.nc")))
        any(occursin("stored type differs", i) for i in iss2)
    end

    # frozen-validator identity semantics (behavioral, tiny pairs)
    idn(x, y; kw...) = x1v_identity_issues(x, y; kw...)
    t["identity_valid_accepted"] = begin
        d2 = mktempdir()
        for pp in (joinpath(d2, "a.nc"), joinpath(d2, "b.nc"))
            NCDataset(pp, "c") do ds
                defDim(ds, "n", 2)
                v = defVar(ds, "alpha", Float64, ("n",))
                v[:] = [1.0, 2.0]
                ds.attrib["config"] = pp == joinpath(d2, "b.nc") ? "B" : "A"
                ds.attrib["history"] = pp == joinpath(d2, "b.nc") ? "hB" : "hA"
            end
        end
        isempty(idn(joinpath(d2, "a.nc"), joinpath(d2, "b.nc");
                    allowed_value_diff = ["config", "history"],
                    required_value_diffs = ["config", "history"],
                    expected_var_count = 1))
    end
    t["identity_value_change_detected"] = begin
        d2 = mktempdir()
        for (pp, second) in ((joinpath(d2, "a.nc"), false),
                             (joinpath(d2, "b.nc"), true))
            NCDataset(pp, "c") do ds
                defDim(ds, "n", 2)
                v = defVar(ds, "alpha", Float64, ("n",))
                v[:] = second ? [1.0, 9.0] : [1.0, 2.0]
                ds.attrib["config"] = second ? "B" : "A"
                ds.attrib["history"] = second ? "hB" : "hA"
            end
        end
        !isempty(idn(joinpath(d2, "a.nc"), joinpath(d2, "b.nc");
                     allowed_value_diff = ["config", "history"],
                     required_value_diffs = ["config", "history"],
                     expected_var_count = 1))
    end
    t["identity_var_count_enforced"] = begin
        d2 = mktempdir()
        for pp in (joinpath(d2, "a.nc"), joinpath(d2, "b.nc"))
            NCDataset(pp, "c") do ds
                defDim(ds, "n", 2)
                v = defVar(ds, "alpha", Float64, ("n",))
                v[:] = [1.0, 2.0]
                ds.attrib["config"] = pp == joinpath(d2, "b.nc") ? "B" : "A"
                ds.attrib["history"] = pp == joinpath(d2, "b.nc") ? "hB" : "hA"
            end
        end
        !isempty(idn(joinpath(d2, "a.nc"), joinpath(d2, "b.nc");
                     allowed_value_diff = ["config", "history"],
                     required_value_diffs = ["config", "history"],
                     expected_var_count = 47))
    end

    # matrix classifier: internal vs bridge independence, mechanically
    m1 = cc_matrix(true, true, true, true)
    m2 = cc_matrix(true, true, false, false)
    m3 = cc_matrix(false, true, true, true)
    m4 = cc_matrix(true, false, true, true)
    t["matrix_internal_requires_both"] = m1.internal && !m3.internal &&
        !m4.internal
    t["matrix_bridge_independent_of_internal"] =
        occursin("BRIDGE FAILED", m2.bridge_txt) && m2.internal &&
        occursin("does NOT invalidate", m2.bridge_txt)
    t["matrix_inconclusive_wording"] =
        occursin("INCONCLUSIVE", m3.internal_txt) &&
        occursin("no post-hoc noise rule", m3.internal_txt)

    # comparator mode discrimination
    t["comparator_mode_gate_discriminates"] = begin
        saved = get(ENV, "RH_CANDIDATE_GAS_OPTICS", nothing)
        ENV["RH_CANDIDATE_GAS_OPTICS"] = "toy"
        wrong = candidate_mode() != "official_ecckd"
        ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
        right = candidate_mode() == "official_ecckd"
        saved === nothing ? delete!(ENV, "RH_CANDIDATE_GAS_OPTICS") :
            (ENV["RH_CANDIDATE_GAS_OPTICS"] = saved)
        wrong && right
    end

    # extraction containment (live)
    s1iss, s1bytes = cc_read_pinned(CC_S1_SOURCE, CC_S1_SOURCE_SHA)
    s1txt = s1bytes === nothing ? "" : String(copy(s1bytes))
    t["kernel_text_contained_in_pinned_s1"] =
        occursin(CC_KERNEL_TEXT, s1txt)
    t["comparator_text_contained_in_pinned_s1"] =
        occursin(CC_COMPARATOR_TEXT, s1txt)

    # forbidden-prose guards on the ACTUAL durable rendered text
    # (contract point 8; no tautologies)
    t["probe_scan_label_guard"] =
        occursin("STRUCTURAL EVIDENCE ONLY", CC_PROBE_SCAN_LABEL) &&
        occursin("NOT a fourth scientific arm", CC_PROBE_SCAN_LABEL) &&
        occursin("never enter census, comparator, or scientific " *
                 "interpretation", CC_PROBE_SCAN_LABEL)
    t["prose_required_phrases_in_durable_text"] =
        occursin("UNOBSERVED", CC_C1_CENSUS_LABEL) &&
        occursin("NOT supplied to the unbounded solver",
                 CC_C1_CENSUS_LABEL) &&
        occursin("NEITHER returned-x feasibility NOR bound enforcement",
                 CC_C1_CENSUS_LABEL) &&
        occursin("OPEN and UNRANKED globally", CC_CEILING) &&
        occursin("descriptive and is not a comparator objective",
                 CC_CEILING) &&
        occursin("discriminates NO mechanism", CC_CEILING) &&
        occursin("No repair, recovery, or causal claim", CC_CEILING) &&
        occursin("no historical or global claim", CC_CEILING)
    t["prose_forbidden_positive_claims_absent"] = begin
        blob = CC_C1_CENSUS_LABEL * " " * CC_CEILING
        stripped = replace(blob,
            "No repair, recovery, or causal claim" => "",
            "no historical or global claim" => "")
        !occursin("unbounded solution", blob) &&
            !occursin("stayed finite", blob) &&
            !occursin("solution is finite", blob) &&
            !occursin("returned x respects", blob) &&
            !occursin("repair", lowercase(stripped)) &&
            !occursin("recover", lowercase(stripped)) &&
            !occursin("causal", lowercase(stripped)) &&
            !occursin("resolves the mechanism", blob)
    end
    t
end

# --- main -----------------------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()
    groups = Dict{String, Vector{String}}()

    groups["pinned_definition_extraction"] = CC_EXTRACTION_ISSUES
    groups["frozen_validator_pin"] = CC_VALIDATOR_ISSUES
    if !isempty(CC_EXTRACTION_ISSUES) || !isempty(CC_VALIDATOR_ISSUES)
        for (k, v) in groups
            gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
            isempty(v) || append!(fails, ["$k: " * i for i in v])
        end
        println("gate4_c1_bounds_flag_completion_ledger: c1_completion_ledger_refused (extraction/validator)")
        isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
        return 1
    end

    tests = cc_fixtures()
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    # 1. commit + package pins
    cm = String[]
    commit_ref = CC_COMMIT * "^" * "{commit}"
    commit_ok = try
        strip(read(`git -C $CC_PROJECT_ROOT rev-parse $commit_ref`,
                   String)) == CC_COMMIT
    catch
        false
    end
    commit_ok || push!(cm, "pinned commit $CC_COMMIT not resolvable")
    for (rel, sha) in CC_COMMITTED
        spec = "$(CC_COMMIT):$(rel)"
        blob = try
            bytes2hex(sha256(read(`git -C $CC_PROJECT_ROOT show $spec`)))
        catch
            "unreadable"
        end
        blob == sha ||
            push!(cm, "blob at $CC_COMMIT:$rel sha $blob != pinned $sha")
        cc_try_sha(joinpath(CC_PROJECT_ROOT, rel)) == sha ||
            push!(cm, "on-disk $rel sha != pinned $sha")
    end
    groups["commit_and_package_pins"] = cm

    # 2. custody receipts
    rc = String[]
    parsed = Dict{String, Dict{String, String}}()
    for (label, (path, size, sha)) in (
            ("submission_session40", CC_RECEIPT_SUBMISSION),
            ("terminal_agent42", CC_RECEIPT_AGENT42),
            ("terminal_session40", CC_RECEIPT_SESSION40))
        iss, bytes = cc_read_pinned(path, sha; size = size, label = label)
        append!(rc, iss)
        bytes === nothing && continue
        parsed[label] = cc_parse_receipt(String(copy(bytes)))
    end
    if haskey(parsed, "terminal_agent42") && haskey(parsed, "terminal_session40")
        append!(rc, cc_receipt_token_issues(parsed["terminal_agent42"],
                                            parsed["terminal_session40"],
                                            CC_RECEIPT_EXPECT))
    end
    groups["custody_receipts"] = rc

    # 3. job log gates (exact stage/mode/status counts)
    jl = String[]
    log_iss, log_bytes = cc_read_pinned(CC_LOG[1], CC_LOG[3];
                                        size = CC_LOG[2], label = "job log")
    append!(jl, log_iss)
    if log_bytes !== nothing
        lt = String(copy(log_bytes))
        for s in CC_STAGES
            cc_count(lt, "=== C1-lw stage $s:") == 1 ||
                push!(jl, "stage marker $s not exactly once")
        end
        for (needle, n) in ((CC_DONE_MARK, 1),
                            (CC_STATUS_RECORD, 1),
                            (CC_BASELINE_ECHO, 1), (CC_FLAG_ECHO, 1),
                            ("staged data tree locked read-only (zero writable entries)", 1),
                            ("staged data inputs re-verified post-run (6 files, size+sha, zero writable entries)", 1),
                            (CC_BANNER_1, 1), (CC_BANNER_3000, 3),
                            ("Minimization is unbounded", 2),
                            ("Minimization is bounded", 2),
                            ("number bounded below:", 2),
                            ("Optimizing coefficients of: composite h2o o3 co2", 4),
                            ("Convergence status: ", 4),
                            ("raw2 strict schema/finite verification passed (control)", 2),
                            ("nonfinite values recorded: 0", 2),
                            ("NONFINITE RECORD", 0),
                            ("X1 CAPTURE", 0))
            cc_count(lt, needle) == n ||
                push!(jl, "log line count for $(repr(needle)) != $n")
        end
        hits = [m.match for m in eachmatch(CC_FAILURE_RE, lt)]
        isempty(hits) ||
            push!(jl, "failure tokens present: $(join(unique(hits), ", "))")
        occursin(CC_EVIDENCE_TS * "Z", CC_DONE_MARK) ||
            push!(jl, "done mark inconsistent with pinned EndTime")
    end
    groups["job_log"] = jl

    # 4. arm logs (per-arm mode banners + descriptive endpoints)
    al = String[]
    for (arm, path, size, sha) in CC_ARM_LOGS
        iss, bytes = cc_read_pinned(path, sha; size = size,
                                    label = "$arm arm log")
        append!(al, iss)
        bytes === nothing && continue
        txt = String(copy(bytes))
        if arm == "probe"
            cc_count(txt, CC_BANNER_1) == 1 ||
                push!(al, "probe 1-iteration banner not exactly once")
            cc_count(txt, "Minimization is unbounded") == 1 ||
                push!(al, "probe unbounded banner not exactly once")
            cc_count(txt, "Minimization is bounded") == 0 ||
                push!(al, "probe bounded banner present")
        elseif arm == "c1"
            cc_count(txt, CC_BANNER_3000) == 1 ||
                push!(al, "c1 banner not exactly once")
            cc_count(txt, "Minimization is unbounded") == 1 ||
                push!(al, "c1 unbounded banner not exactly once")
            cc_count(txt, "Minimization is bounded") == 0 ||
                push!(al, "c1 bounded banner present")
            cc_count(txt, CC_C1_ENDPOINT) == 1 ||
                push!(al, "c1 descriptive endpoint line not exactly once")
        else
            cc_count(txt, CC_BANNER_3000) == 1 ||
                push!(al, "$arm banner not exactly once")
            cc_count(txt, "Minimization is bounded") == 1 ||
                push!(al, "$arm bounded banner not exactly once")
            cc_count(txt, "Minimization is unbounded") == 0 ||
                push!(al, "$arm unbounded banner present")
            cc_count(txt, CC_CTRL_ENDPOINT) == 1 ||
                push!(al, "$arm descriptive endpoint line not exactly once")
        end
        cc_count(txt, "Convergence status: Maximum iterations reached") == 1 ||
            push!(al, "$arm convergence line not exactly once")
    end
    groups["arm_logs"] = al

    # 5. RUNROOT artifacts (binary/config/status files/raw2)
    ar = String[]
    for (label, (path, size, sha)) in CC_RAW2
        a_iss, _ = cc_read_pinned(path, sha; size = size,
                                  label = "$label raw2")
        append!(ar, a_iss)
    end
    b_iss, _ = cc_read_pinned(CC_BIN[1], CC_BIN[3]; size = CC_BIN[2],
                              label = "binary")
    append!(ar, b_iss)
    cs_iss, cs_bytes = cc_read_pinned(CC_CONFIG_STATUS[1],
                                      CC_CONFIG_STATUS[3];
                                      size = CC_CONFIG_STATUS[2],
                                      label = "config.status rendering")
    append!(ar, cs_iss)
    statuses = Dict{String, String}()
    for (r, path, size, sha) in CC_STATUS_FILES
        s_iss, s_bytes = cc_read_pinned(path, sha; size = size,
                                        label = "$r status file")
        append!(ar, s_iss)
        s_bytes === nothing && continue
        statuses[r] = String(copy(s_bytes))
        statuses[r] == CC_STATUS_TEXT ||
            push!(ar, "$r status text != $(repr(CC_STATUS_TEXT))")
    end
    br_iss, _ = cc_read_pinned(CC_BRIDGE_RAW2, CC_BRIDGE_RAW2_SHA;
                               size = CC_BRIDGE_RAW2_BYTES,
                               label = "4561 pristine raw2 (bridge)")
    append!(ar, br_iss)
    groups["runroot_artifacts"] = ar

    # 5b. SHARED full 47-variable two-tier scans (monitor blocker 1):
    # signature authority = the PINNED INITIAL RAW ONLY (sha-bracketed);
    # MISSING refuses in EVERY arm; nonfinite refuses in controls; C1
    # numeric NaN/Inf is lawful and drives the shared census+comparator
    # skip below with identical counts/reason
    fs = String[]
    sig_iss, sig, dims = cc_signature_of(CC_INIT[1], CC_INIT[3])
    append!(fs, sig_iss)
    scans = Dict{String, Any}()
    if sig !== nothing
        length(sig) == 47 ||
            push!(fs, "signature entry count $(length(sig)) != 47")
        length(dims) == 8 ||
            push!(fs, "dimension map count $(length(dims)) != 8")
        # probe included (monitor probe-closure item): structural
        # drift/missing refuse; probe numeric nonfinite is recorded as
        # lawful STRUCTURAL EVIDENCE ONLY and never enters
        # census/comparator or scientific interpretation
        for arm in ("probe", "c0a", "c0b", "c1")
            s_iss, pm, pnf = cc_full_scan(CC_RAW2[arm][1],
                                          CC_RAW2[arm][3], sig, dims)
            append!(fs, ["$arm full-scan: " * i for i in s_iss])
            scans[arm] = (missing = pm, nonfinite = pnf)
            isempty(pm) ||
                push!(fs, "$arm contains MISSING values (structural/value-integrity fault in EVERY arm): $pm")
        end
        for arm in ("c0a", "c0b")
            haskey(scans, arm) && !isempty(scans[arm].nonfinite) &&
                push!(fs, "control $arm contains nonfinite values (strict policy refusal): $(scans[arm].nonfinite)")
        end
    end
    groups["full_scan_two_tier"] = fs
    c1_nonfinite = (sig !== nothing && haskey(scans, "c1")) ?
        sum(values(scans["c1"].nonfinite); init = 0) : -1
    c1_evaluated = c1_nonfinite == 0
    c1_skip_reason = c1_evaluated ? "" :
        "skipped_by_preregistered_policy: full-file scan found " *
        "$c1_nonfinite numeric nonfinite values in the C1 raw2 " *
        "(per-variable: $(get(scans, "c1", (nonfinite = Dict(),)).nonfinite)); " *
        "lawful recorded observation (SAME decision for census AND comparator)"

    if !all(isempty, values(groups)) || gates["fixtures"] != "passed"
        for (k, v) in groups
            gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
            isempty(v) || append!(fails, ["$k: " * i for i in v])
        end
        println("gate4_c1_bounds_flag_completion_ledger: c1_completion_ledger_refused (evidence)")
        for k in sort(collect(keys(gates)))
            println("  $k: $(gates[k])")
        end
        isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
        return 1
    end

    # 6. INTERNAL VALIDITY (contract point 2) -- classification, not
    # refusal: identity issues are the exact-differences report
    internal_id_issues = x1v_identity_issues(CC_RAW2["c0a"][1],
        CC_RAW2["c0b"][1];
        allowed_value_diff = ["config", "history"],
        required_value_diffs = ["config", "history"],
        expected_var_count = 47)
    status_equal = cc_control_status_equal(statuses)
    identity_ok = isempty(internal_id_issues)

    # 7. HISTORICAL BRIDGE (contract point 3) -- separate per control
    bridge_a_issues = x1v_identity_issues(CC_RAW2["c0a"][1],
        CC_BRIDGE_RAW2; allowed_value_diff = ["config", "history"],
        required_value_diffs = ["config", "history"],
        expected_var_count = 47)
    bridge_b_issues = x1v_identity_issues(CC_RAW2["c0b"][1],
        CC_BRIDGE_RAW2; allowed_value_diff = ["config", "history"],
        required_value_diffs = ["config", "history"],
        expected_var_count = 47)
    mat = cc_matrix(identity_ok, status_equal,
                    isempty(bridge_a_issues), isempty(bridge_b_issues))

    # 8. C1-vs-EACH-control nonfinite-aware diffs (contract point 4;
    # actual typed global-diff set REQUIRED exactly {config, history})
    df = String[]
    diff_a_iss, diff_a, gdiff_a = cc_nonfinite_aware_diff(
        CC_RAW2["c1"][1], CC_RAW2["c1"][3],
        CC_RAW2["c0a"][1], CC_RAW2["c0a"][3])
    append!(df, ["c1-vs-c0a: " * i for i in diff_a_iss])
    diff_b_iss, diff_b, gdiff_b = cc_nonfinite_aware_diff(
        CC_RAW2["c1"][1], CC_RAW2["c1"][3],
        CC_RAW2["c0b"][1], CC_RAW2["c0b"][3])
    append!(df, ["c1-vs-c0b: " * i for i in diff_b_iss])
    groups["nonfinite_aware_diff_structure"] = df

    # 9. coefficient/init loads for the census (values only; the
    # two-tier policy is decided by the full-file scans above)
    ld = String[]
    coeffs = Dict{String, Any}()
    for arm in ("c0a", "c0b", "c1")
        a_iss, cf = cc_bracketed(CC_RAW2[arm][1], CC_RAW2[arm][3]) do ds
            Dict(v => Array(ds[v]) for v in CC_COEFF_VARS)
        end
        append!(ld, a_iss)
        cf === nothing || (coeffs[arm] = cf)
    end
    init_iss, init = cc_bracketed(CC_INIT[1], CC_INIT[3]) do ds
        Dict(g => (mn = Array(ds[g * "_molar_absorption_coeff_min"]),
                   mx = Array(ds[g * "_molar_absorption_coeff_max"]),
                   ini = Array(ds[g * "_molar_absorption_coeff"]))
             for g in CC_ACTIVE_GASES)
    end
    append!(ld, init_iss)
    groups["array_loads"] = ld
    if !all(isempty, values(groups))
        for (k, v) in groups
            gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
            isempty(v) || append!(fails, ["$k: " * i for i in v])
        end
        println("gate4_c1_bounds_flag_completion_ledger: c1_completion_ledger_refused (loads)")
        isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
        return 1
    end

    # 10. censuses (contract point 5): controls always; C1 conditional
    cs = String[]
    census = Dict{String, Any}()
    for arm in ("c0a", "c0b")
        c_iss, cres = cc_census_file(coeffs[arm], init)
        append!(cs, ["census $arm: " * i for i in c_iss])
        census[arm] = cres
    end
    if c1_evaluated
        c_iss, cres = cc_census_file(coeffs["c1"], init)
        append!(cs, ["census c1: " * i for i in c_iss])
        cres["label"] = CC_C1_CENSUS_LABEL
        census["c1"] = cres
    else
        census["c1"] = Dict(
            "evaluated" => false,
            "reason" => c1_skip_reason,
            "label" => CC_C1_CENSUS_LABEL)
    end
    groups["census_consistency"] = cs

    # 11. comparator (contract point 6): conditional for C1
    cp = String[]
    for (rel, sha) in CC_CODE_PINS
        cc_try_sha(joinpath(CC_PROJECT_ROOT, rel)) == sha ||
            push!(cp, "comparator code pin drift: $rel")
    end
    src_spec = "$(CC_COMMIT):src"
    src_tree = try
        strip(read(`git -C $CC_PROJECT_ROOT rev-parse $src_spec`, String))
    catch
        "unreadable"
    end
    src_tree == CC_SRC_TREE || push!(cp, "src tree at $CC_COMMIT != reviewed")
    groups["comparator_code_pins"] = cp

    ci = String[]
    objectives = Dict{String, Any}()
    repeat_evidence = Dict{String, Any}()
    if isempty(cp)
        ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
        candidate_mode() == "official_ecckd" ||
            push!(ci, "comparator candidate mode != official_ecckd")
        sw_iss, sw_snap = cc_pinned_snapshot(
            official_ecckd_definition_path(:shortwave_32),
            CC_PUB_SW_BYTES, CC_PUB_SW_SHA; label = "published SW32")
        append!(ci, sw_iss)
        lw_iss, lw_snap = cc_pinned_snapshot(
            official_ecckd_definition_path(:longwave_32),
            CC_PUB_LW_BYTES, CC_PUB_LW_SHA; label = "published LW32")
        append!(ci, lw_iss)
        snapshot_cases = Any[]
        for (name, path, size, sha) in CC_CASE_INPUTS
            k_iss, k_snap = cc_pinned_snapshot(path, size, sha;
                                               label = "case input $name")
            append!(ci, k_iss)
            k_snap === nothing || push!(snapshot_cases,
                                        (case = name, path = k_snap))
        end
        targets = Any[("published_selfcheck", lw_snap,
                       CC_PUBLISHED_BASELINE)]
        for arm in ("c0a", "c0b")
            a_iss, snap = cc_pinned_snapshot(CC_RAW2[arm][1],
                CC_RAW2[arm][2], CC_RAW2[arm][3]; label = "$arm raw2")
            append!(ci, a_iss)
            snap === nothing || push!(targets, (arm, snap, nothing))
        end
        # the SAME full-file two-tier decision as the census
        if c1_evaluated
            a_iss, snap = cc_pinned_snapshot(CC_RAW2["c1"][1],
                CC_RAW2["c1"][2], CC_RAW2["c1"][3]; label = "c1 raw2")
            append!(ci, a_iss)
            snap === nothing || push!(targets, ("c1", snap, nothing))
        else
            objectives["c1"] = Dict("evaluated" => false,
                "reason" => c1_skip_reason)
        end
        if isempty(ci) && sw_snap !== nothing
            try
                for (label, snap, expected) in targets
                    t_iss, v1, v2 = cc_score_twice(
                        () -> sl_swap_objective(snap, sw_snap,
                                                snapshot_cases),
                        label, expected)
                    append!(ci, t_iss)
                    objectives[label] = v1
                    repeat_evidence[label] = Dict(
                        "repeat1" => v1, "repeat2" => v2,
                        "bit_equal" => v1 == v2)
                end
                if haskey(objectives, "c1") && objectives["c1"] isa Float64
                    objectives["delta_c1_minus_c0a"] =
                        objectives["c1"] - objectives["c0a"]
                    objectives["delta_c1_minus_c0b"] =
                        objectives["c1"] - objectives["c0b"]
                end
                haskey(objectives, "c0a") && haskey(objectives, "c0b") &&
                    (objectives["delta_c0b_minus_c0a"] =
                        objectives["c0b"] - objectives["c0a"])
            catch err
                push!(ci, "comparator evaluation failed: " *
                          sprint(showerror, err))
            end
        end
    else
        push!(ci, "comparator not run (code pins failed)")
    end
    groups["comparator_integrity"] = ci

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end
    status = gates["fixtures"] == "passed" ? cc_overall(groups) :
        "c1_completion_ledger_refused"

    result = Dict(
        "case" => "gate4_c1_bounds_flag_completion_ledger",
        "data_mode" => "completion_ledger",
        "status" => status,
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "fixture_count" => length(tests),
        "evidence_timestamp_utc" => CC_EVIDENCE_TS,
        "job" => Dict("id" => 4562,
                      "receipt_tokens" => get(parsed, "terminal_session40",
                                              Dict()),
                      "dual_custody" => "terminal receipts agree " *
                          "token-for-token; raw fields before " *
                          "classification"),
        "pins" => Dict(
            "commit" => CC_COMMIT,
            "committed_files" => Dict(rel => sha
                                      for (rel, sha) in CC_COMMITTED),
            "runroot" => CC_RUNROOT,
            "raw2" => Dict(k => v[3] for (k, v) in CC_RAW2),
            "binary" => CC_BIN[3],
            "bridge_raw2" => CC_BRIDGE_RAW2_SHA,
            "init_bounds_source" => CC_INIT[3],
            "s1_ledger_source" => CC_S1_SOURCE_SHA,
            "frozen_validator" => CC_VALIDATOR_SHA,
            "receipts" => Dict(
                "submission_session40" => CC_RECEIPT_SUBMISSION[3],
                "terminal_agent42" => CC_RECEIPT_AGENT42[3],
                "terminal_session40" => CC_RECEIPT_SESSION40[3]),
            "job_log" => CC_LOG[3],
            "arm_logs" => Dict(a => s for (a, _, _, s) in CC_ARM_LOGS)),
        "internal_validity" => Dict(
            "logical_identity_holds" => identity_ok,
            "identity_differences" => internal_id_issues,
            "terminal_status_equal" => status_equal,
            "statuses" => statuses,
            "gate" => "BOTH conditions required (frozen 47-variable " *
                "typed semantics, value differences allowed ONLY in " *
                "config/history, AND terminal-status exact equality); " *
                "byte inequality is informational only; nothing " *
                "inferred from hashes"),
        "historical_bridge" => Dict(
            "c0a_vs_4561_pristine_holds" => isempty(bridge_a_issues),
            "c0a_differences" => bridge_a_issues,
            "c0b_vs_4561_pristine_holds" => isempty(bridge_b_issues),
            "c0b_differences" => bridge_b_issues,
            "semantics" => "SEPARATE from internal validity; neither " *
                "substitutes for the other"),
        "preregistered_matrix" => Dict(
            "internal" => mat.internal_txt,
            "bridge" => mat.bridge_txt),
        "full_scan_two_tier" => Dict(
            "signature_authority" => "PINNED INITIAL RAW ONLY " *
                "($(CC_INIT[3])), sha-bracketed; 47-variable " *
                "stored-type+dim signature + complete 8-dim map " *
                "enforced on every output; live outputs never treated " *
                "as authority",
            "per_arm_missing" => Dict(a => scans[a].missing
                                      for a in keys(scans)),
            "per_arm_nonfinite" => Dict(a => scans[a].nonfinite
                                        for a in keys(scans)),
            "routing" => "MISSING refuses in EVERY arm (incl. probe); " *
                "nonfinite refuses in controls; C1 numeric NaN/Inf is " *
                "lawful and drives the SHARED census+comparator skip " *
                "with identical counts/reason; PROBE numeric nonfinite " *
                "is lawful STRUCTURAL EVIDENCE ONLY and never enters " *
                "census/comparator or scientific interpretation",
            "c1_decision" => c1_evaluated ? "evaluated (all-finite)" :
                c1_skip_reason,
            "probe_record_label" => CC_PROBE_SCAN_LABEL),
        "c1_vs_controls_diff" => Dict(
            "semantics" => "nonfinite-aware full logical diff; " *
                "structure strict and refused BEFORE value traversal; " *
                "values via elementwise isequal deltas with explicit " *
                "nonfinite counts; NO materiality threshold; the C1 " *
                "serialized raw2 is all-finite here; the returned " *
                "minimizer x remains UNOBSERVED",
            "actual_global_attr_diffs_c1_vs_c0a" => gdiff_a,
            "actual_global_attr_diffs_c1_vs_c0b" => gdiff_b,
            "required_global_attr_diff_set" => ["config", "history"],
            "c1_vs_c0a" => diff_a,
            "c1_vs_c0b" => diff_b),
        "census" => Dict(
            "kernel" => "committed S1 kernel by exact pinned " *
                "extraction/containment ($CC_S1_SOURCE_SHA)",
            "bounds_source" => "pinned initial raw definition " *
                "$(CC_INIT[3])",
            "committed_reference" => Dict("below" => CC_S1_CENSUS.below,
                "above" => CC_S1_CENSUS.above,
                "note" => "informational reference for bounded-family " *
                    "arms; never a gate"),
            "targets" => census,
            "c1_conditional" => Dict(
                "evaluated" => c1_evaluated,
                "policy" => "controls ALWAYS censused; C1 censused " *
                    "only if structurally valid and all-finite; " *
                    "otherwise per-variable nonfinite counts and the " *
                    "explicit reason replace the census (never a " *
                    "refusal)")),
        "objectives" => Dict(
            "comparator" => "pinned deterministic comparator " *
                "(official_ecckd mode gated, H2O=0.005, snapshot-set " *
                "evaluation); PER-ARTIFACT determinism: each artifact " *
                "scored twice, bit-equality required; no threshold or " *
                "repair language",
            "values" => objectives,
            "per_artifact_repeat_evidence" => repeat_evidence,
            "published_selfcheck_pinned" => CC_PUBLISHED_BASELINE,
            "internal_endpoints_descriptive" => Dict(
                "c1" => CC_C1_ENDPOINT,
                "c0a_c0b" => CC_CTRL_ENDPOINT,
                "note" => "internal optimizer endpoints are " *
                    "DESCRIPTIVE and are not comparator objectives; " *
                    "identical printed control endpoints license " *
                    "nothing (the array-level identity gate is the " *
                    "instrument)")),
        "interpretation" => Dict(
            "c1_census_label" => CC_C1_CENSUS_LABEL,
            "ceiling" => CC_CEILING),
        "non_authorizing_note" => "this ledger interprets nothing " *
            "beyond its committed ceiling and authorizes nothing; " *
            "next steps require explicit monitor rulings",
        "disclaimer" => "completion ledger; writes nothing except its " *
            "own JSON/MD results and transient private temp files " *
            "(mktempdir); zero canonical writes; RUNROOT untouched")

    mkpath(dirname(CC_RESULTS_JSON))
    open(CC_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(CC_RESULTS_MD, "w") do io
        println(io, "# Gate-4 C1 bounds-flag completion ledger (job 4562)\n")
        println(io, "Status: **$status**\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nFixtures: $(length(tests)) ($(count(values(tests))) passed)")
        println(io, "\n## Preregistered matrix (mechanical)")
        println(io, "- ", mat.internal_txt)
        println(io, "- ", mat.bridge_txt)
        println(io, "\n## Census (pinned kernel)")
        for arm in ("c0a", "c0b", "c1")
            c = census[arm]
            if get(c, "evaluated", true) == false
                println(io, "- $arm: NOT EVALUATED -- $(c["reason"])")
            else
                println(io, "- $arm: below $(c["below"])/$(c["lo_den"]), " *
                    "above $(c["above"])/$(c["hi_den"]); worst dlog " *
                    "$(c["worst_lo_dlog"]) / $(c["worst_hi_dlog"]); " *
                    "event sum $(c["event_sum"]), unique " *
                    "$(c["unique_coordinates"])")
            end
        end
        println(io, "\nC1 census label: ", CC_C1_CENSUS_LABEL)
        println(io, "\n## Objectives (comparator; secondary)")
        for k in sort(collect(keys(objectives)))
            println(io, "- $k: $(objectives[k])")
        end
        println(io, "\n## C1-vs-control value differences (counts only here; full per-variable table in JSON)")
        println(io, "- c1-vs-c0a differing vars: $(length(diff_a))")
        println(io, "- c1-vs-c0b differing vars: $(length(diff_b))")
        println(io, "\n## Interpretation ceiling\n")
        println(io, CC_CEILING)
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_c1_bounds_flag_completion_ledger: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    println("  fixtures: $(count(values(tests)))/$(length(tests)) passed")
    println("  internal: ", mat.internal_txt)
    println("  bridge: ", mat.bridge_txt)
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "c1_run_completed_verified" ? 0 : 1
end

exit(main())
