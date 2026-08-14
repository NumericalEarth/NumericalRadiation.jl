# Gate-4 X1 DIRECT-CAPTURE COMPLETION LEDGER (job 4561; DIAGNOSIS unit;
# writes ONLY its own JSON/MD results + transient private temp files).
#
# CONTRACT (monitor COMPLETION-LEDGER GO + Agent 42 predeclared
# omission-probe checklist with the monitor's item-4/item-5
# corrections, 2026-08-14):
#   - pin and classify commit 9725cbb, the package/sbatch, all custody
#     receipts, job/arm logs, raw2 outputs, sidecars, sources, helper,
#     and binaries; re-run the FROZEN committed validators fail-closed
#   - AXIS A (exact predicates): on lower_class != 0 count
#     returned_x_log < bound_lo_log; on upper_active == 1 count
#     returned_x_log > bound_hi_log; denominators, worst dlog,
#     exact-at-bound counts, per gas AND per lower class; violation
#     index sets preserved verbatim
#   - AXIS B: exact-bit mapped_x_phys vs caller_phys mismatch count
#     with per-gas counts and index sets; max abs/relative/dlog where
#     defined; zero-floor transitions; Float32(mapped) vs
#     caller_phys_f32 mismatch count. The callback mapping is
#     replicated EXACTLY including the MIN_X asymmetry (x <= MIN_X
#     maps to 0.0, never exp(x)).
#   - AXIS C (THE gate; like-with-like ONLY): positional raw2 ==
#     caller_phys_f32 across all 152,640 rows MUST be zero-mismatch or
#     the completion REFUSES; reported per gas. Any Float64-domain
#     comparison is a separately labeled descriptive report, never the
#     gate.
#   - CENSUS: the source-faithful S1 log-space kernel is reused BY
#     EXACT PINNED DEFINITION (verbatim extraction from the committed
#     S1 completion-ledger source, sha-gated, byte-containment-gated,
#     evaluated via include_string) on pristine raw2, X1 raw2, caller
#     F64, caller F32, mapped F64, mapped F32; below/above reported
#     separately with denominators/worst dlog per gas; explicit set
#     intersections with the Axis-B mismatch set; event counts AND
#     unique-coordinate overlap sets reported side by side; unique
#     is NEVER inferred as below+above without the overlap
#     calculation.
#   - PROBE CONTROL (Agent 42 item 4 as corrected by the monitor): the
#     probe sidecar is validated STRUCTURALLY only
#     (validator/schema/status/order/projection consistency are the
#     refusal conditions); probe Axis-A/B outcomes are DESCRIPTIVE
#     OBSERVATIONS recorded alongside the full-run outcomes, never a
#     gate; a nonzero probe A or B result is a real observed result,
#     not an instrument failure; no expected probe scientific value is
#     encoded or retrofitted.
#   - OBJECTIVE (secondary, pre-registered): the same pinned
#     deterministic comparator as S1 scores (a) the serialized X1 raw2
#     and (b) a temp/private logically verified reconstruction that
#     replaces ONLY the four active coefficient arrays with
#     Float32(mapped_x_phys); every other variable is PROVEN unchanged;
#     each artifact is scored TWICE with bit-equality required
#     (PER-ARTIFACT determinism); serialized-vs-reconstructed equality
#     is a SCIENTIFIC OUTCOME, never an acceptance gate; the exact
#     delta is preserved at full precision; the reconstruction is
#     labeled returned-state reconstruction, EXPLORATORY SECONDARY,
#     with no materiality threshold and no causal claim.
#   - INTERPRETATION CEILING: findings are LOCAL to this rebuilt
#     trajectory; the identity gate licenses non-perturbation ONLY for
#     this pristine/X1 pair; Axis-A/B/C statements are DESCRIPTIVE and
#     all mechanism classes remain OPEN and UNRANKED globally; any
#     Axis-C, validator, like-with-like census, pin, or
#     reconstruction-integrity inconsistency REFUSES rather than
#     concludes; refusal branches fire on domain-matched comparisons
#     only.
#
# COMPLETION STATUS IS INDEPENDENT OF SCIENTIFIC OUTCOME:
#   x1_run_completed_verified     -- every evidence group green (exit 0)
#   x1_completion_ledger_refused  -- ANY discrepancy (exit 1)

const XL_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
include(joinpath(XL_PROJECT_ROOT, "validation", "validation_results.jl"))

import JSON
using SHA: sha256
using NCDatasets

include(joinpath(XL_PROJECT_ROOT, "validation",
                 "ecckd_published_model_accuracy.jl"))

const XL_RUNROOT = "/shared/home/greg/ecckd-derived-flux-work/" *
    "g4-init-generation/g4-diag/4561/lw-x1"
const XL_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"

# --- commit + package pins ---------------------------------------------------------
const XL_COMMIT = "9725cbb502dc91d834cffc5ef76cd051de394acc"
const XL_COMMITTED = [
    ("validation/gate4_x1_direct_capture_checkpoint.jl",
     "ab00dc7751e7cf90cbd7bf1e6658fc1261fb9e64e9be131b4fb5a0f72fafc83d"),
    ("validation/gate4_x1_sidecar_validator.jl",
     "163363a693d6b0f273221c7eb51be7e468915659faa7794f125d7f5b3c08ff76"),
    ("validation/gate4_x1_capture.h",
     "183d8a534781e6378ee40ce348402ec491beaa1b58357a7f26560a6c57ec1872"),
    ("validation/gate4_x1_frozen_design.md",
     "d4f8a689aa4fcadb91922120b7806939bba88c115fb6281d51b2fc3dbe325398"),
    ("validation/results/gate4_x1_lw_direct_capture.sbatch",
     "12b7bfeb5d20b595bd755436fa45a2e82a887febd999787e155385730b1c1e88"),
    ("validation/results/gate4_x1_direct_capture_checkpoint.json",
     "baeb15f4fc11ead171c0aec2030839323d88bb21ba8bb6b9d0db92f4f4bd6447"),
    ("validation/results/gate4_x1_direct_capture_checkpoint.md",
     "5de662bc2438b7dc565748419e7d9cca8ff1141868ffe8835a423c5771390228")]
const XL_VALIDATOR = joinpath(XL_PROJECT_ROOT,
    "validation/gate4_x1_sidecar_validator.jl")
const XL_VALIDATOR_SHA = XL_COMMITTED[2][2]

# --- custody receipts (dual custody; raw fields before classification) -------------
const XL_RECEIPT_SUBMISSION = ("$XL_LOG_DIR/g4-x1-lw-4561-submission-session40.txt",
    1925, "a597e9b9f18251f6b75dd391bab407269b3f2cac4d123d0fbdfe15409bf16906")
const XL_RECEIPT_AGENT42 = ("$XL_LOG_DIR/g4-x1-lw-4561-scontrol-final-agent42.txt",
    1659, "2db62b6dbcbf3488a9b88ad3dea53cd6d92686bed0af75f81a5cc121a852dcc6")
const XL_RECEIPT_SESSION40 = ("$XL_LOG_DIR/g4-x1-lw-4561-scontrol-final-session40.txt",
    1824, "04982a612980b7cdb8264985e967c4bf70be39bcb8fe74438d901eda3673464b")
const XL_TOKEN_KEYS = ("JobId", "JobName", "JobState", "Reason",
    "ExitCode", "DerivedExitCode", "Restarts", "RunTime",
    "SubmitTime", "StartTime", "EndTime")
const XL_RECEIPT_EXPECT = Dict(
    "JobId" => "4561", "JobName" => "g4-x1-lw-direct-capture",
    "JobState" => "COMPLETED", "Reason" => "None",
    "ExitCode" => "0:0", "DerivedExitCode" => "0:0",
    "Restarts" => "0", "RunTime" => "01:22:01",
    "SubmitTime" => "2026-08-14T02:29:32",
    "StartTime" => "2026-08-14T02:32:39",
    "EndTime" => "2026-08-14T03:54:40")
# fixed evidence timestamp = job EndTime, never wall-clock
const XL_EVIDENCE_TS = "2026-08-14T03:54:40"

# --- job + arm logs -----------------------------------------------------------------
const XL_LOG = ("$XL_LOG_DIR/g4-x1-lw-4561.log", 471138,
    "651a9a880fa69a8385aaeabeb0a62816dd6685e026d3b1741093619b6c2dfaaf")
const XL_ARM_LOGS = [
    ("probe", "$XL_RUNROOT/probe-base-run.log", 6761,
     "1b048d16d314d219bb70e12e8e91c7504345ea84c9163ad2f8fdface9fd15074"),
    ("pristine", "$XL_RUNROOT/pristine-base-run.log", 202377,
     "6d0a537cc1be385a33ff9dc16a57ebff2b52d11d79080e394dab7ff7cf67eeb2"),
    ("x1", "$XL_RUNROOT/x1-base-run.log", 202779,
     "1381a6cc99527d09d7d1f48ec40310bf1c2dca18c888fcd11e600ec0f2dabaf9")]
const XL_STAGES = ["0a", "0b", "0c", "0d", "1", "2", "3", "4", "5", "6",
                   "7-probe", "7-pristine", "7-x1", "8"]
const XL_DONE_MARK = "=== X1-lw done 2026-08-14T03:54:40Z ==="
const XL_FAILURE_RE = r"REFUSED|SCHEMA-INVALID|sha mismatch|MISSING/nonexecutable|[Qq]uota exceeded|CANCELLED|slurmstepd: error|Traceback \(most recent call last\)|\bERROR\b|\bFATAL\b|\bFAILED\b|CHILD KILLED|CHILD FAILED|SIGFPE|Floating point exception"
const XL_BANNER_3000 = "Optimizing coefficients with Adept LBFGS " *
    "algorithm: max iterations = 3000, convergence criterion = 0.02"
const XL_BANNER_1 = "Optimizing coefficients with Adept LBFGS " *
    "algorithm: max iterations = 1, convergence criterion = 0.02"
const XL_CONV_LINE = "Convergence status: Maximum iterations reached"
const XL_STATUS_RECORD = "STATUS RECORD (descriptive, for the " *
    "completion ledger): probe='Maximum iterations reached' " *
    "pristine='Maximum iterations reached' x1='Maximum iterations reached'"
const XL_IDENTITY_PASS = "X1 IDENTITY GATE: PASS (X1-arm raw2 " *
    "logically identical to pristine-arm raw2 across all variables; " *
    "non-perturbation licensed by this empirical gate)"

# --- RUNROOT artifacts ----------------------------------------------------------------
const XL_RAW2 = [
    ("probe", "$XL_RUNROOT/work-probe/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
     2415304, "465240e20104e15294d962a88554389ebe7e3bcd87ae45b691ea42550fb7aa62"),
    ("pristine", "$XL_RUNROOT/work-pristine/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
     2415304, "49ff3df8c02a1b62f7bfa6cd4b8dc2c6c96e93079c1d042eb8cfb5fc49c61e37"),
    ("x1", "$XL_RUNROOT/work-x1/lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
     2415248, "bc86c83448f498f8678b2af2d564e81dabc505c668a7d6fbb62ce1a1d3fabe00")]
const XL_SIDECAR_PROBE = ("$XL_RUNROOT/sidecar/probe/x1_sidecar_probe.nc",
    12212716, "63c4927c00a0d9ad5fb54c24aefe865f260d4fc8fe6b2eb5a82c72676650f0c0")
const XL_SIDECAR_X1 = ("$XL_RUNROOT/sidecar/x1/x1_sidecar.nc",
    12212712, "cd41a4e7726a312bedb4ff5fdb24708414a726d0c40204a288c160ab4a516df1")
const XL_SRC_ORIG = ("$XL_RUNROOT/solve_adept.cpp.orig",
    "8c9822fac6e6efebadc3fd76c104fe563236221ca6297922e5e8a9467ee32091")
const XL_SRC_PATCHED = ("$XL_RUNROOT/src/ecckd-modern-x1/src/ecckd/solve_adept.cpp",
    "7405c87905aae02971476e4b7585ce8267c28ce01fab216be12a938bdd7b0fa1")
const XL_SRC_HELPER = ("$XL_RUNROOT/src/ecckd-modern-x1/src/ecckd/gate4_x1_capture.h",
    "183d8a534781e6378ee40ce348402ec491beaa1b58357a7f26560a6c57ec1872")
const XL_BIN_PRISTINE = ("$XL_RUNROOT/bin/optimize_lut_pristine", 22141392,
    "4695c49305821d942db6cfbe03ac7f1a5a82105f9cc7cd028a0091c61e76471d")
const XL_BIN_X1 = ("$XL_RUNROOT/bin/optimize_lut_x1", 22593304,
    "bb666a8100f6db78b41550d55ebc012b6ba9bc994091171c671f7e225ffd782a")
const XL_CONFIG_STATUS = ("$XL_RUNROOT/config.status.config.txt",
    "--with-adept=/shared/home/greg/local/adept-2-install " *
    "--with-netcdf=/shared/home/greg/local/ckdmip-stack " *
    "'LDFLAGS=-L/shared/home/greg/local/adept-2-install/lib " *
    "-Wl,-rpath,/shared/home/greg/local/adept-2-install/lib' LIBS=-ladept")
const XL_MIN_X = -1.0e20

# initial raw definition (bounds/init source for the census; identical
# pinned original the job staged per run-set)
const XL_INIT = ("/shared/home/greg/ecckd-derived-flux-work/g4-init-generation/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc",
    2413144, "ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43")

# --- S1 kernel/comparator EXACT PINNED DEFINITION reuse -----------------------------
const XL_S1_SOURCE = joinpath(XL_PROJECT_ROOT,
    "validation/gate4_s1_state_sync_completion_ledger.jl")
const XL_S1_SOURCE_SHA = "844acaa615d1ab139272c7425bbd0a5241d2b489b8a7a2ae2fdc9786f2463a3b"
# committed S1 census expectation (raw2 domain; INFORMATIONAL
# comparison target for this NEW build; never a hard gate here)
const XL_S1_CENSUS = (below = 134, above = 19, lo_den = 152631,
    hi_den = 152640, active = 152640,
    worst_lo = 0.41887799902470135, worst_hi = 0.6268579421960787)
const XL_S1_CENSUS_PER_GAS = Dict(
    "composite" => (below = 0, above = 15),
    "h2o" => (below = 134, above = 4),
    "o3" => (below = 0, above = 0),
    "co2" => (below = 0, above = 0))
const XL_ACTIVE_GASES = ("composite", "h2o", "o3", "co2")

# verbatim extractions from the pinned S1 source (byte-containment
# gated in main; evaluated via include_string so the EXECUTED
# definitions are the committed pinned bytes)
const XL_KERNEL_TEXT = raw"""function sl_census_gas(X, lo, hi, ini)
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
const XL_H2O_TEXT = "const SL_H2O = 0.005"
const XL_COMPARATOR_TEXT = """function sl_swap_objective(lw_path, sw_path, cases)
    model = read_ecckd_tabulated_gas_optics(lw_path, sw_path;
        gas_names = OFFICIAL_ECCKD_GASES, h2o_mole_fraction = SL_H2O)
    hard_objective([case_metrics(c, model) for c in cases]).value
end"""

# --- comparator pins (identical manifest to the reviewed S1 ledger) ------------------
const XL_CODE_PINS = [
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
const XL_SRC_TREE = "7eaf80136e313c073416a815334493fc3b5434e7"
const XL_CASE_INPUTS = [
    ("ecckd_clear_sky_tropical_column",
     joinpath(XL_PROJECT_ROOT,
              "validation/reference/ecrad/ecckd_clear_sky_tropical_column.nc"),
     207210,
     "3a1634b7c7b4e22ae4064ace9826ac76b6810fb4074a5437bfd30b5c911e68e7"),
    ("ecckd_rcemip_style_column_subset",
     joinpath(XL_PROJECT_ROOT,
              "validation/reference/ecrad/ecckd_rcemip_style_column_subset.nc"),
     612490,
     "8c4a6974d74d09ae5f6679f76495538d1b9812edada7d87b1ed6737303710db3")]
const XL_PUB_SW_BYTES = 851724
const XL_PUB_SW_SHA = "49abc7bf88b80252e4f9934f8659d108ffee6a101124b2fd080f2eb65d144eb3"
const XL_PUB_LW_BYTES = 869280
const XL_PUB_LW_SHA = "6087f62f9052653f8e7dbee26cef8bf1977c2516669a169bee8d110b62912ed9"
const XL_PUBLISHED_BASELINE = 0.18218645425029933

const XL_COEFF_VARS = [g * "_molar_absorption_coeff" for g in XL_ACTIVE_GASES]

const XL_RESULTS_JSON = validation_results_path("gate4_x1_direct_capture_completion_ledger.json")
const XL_RESULTS_MD = validation_results_path("gate4_x1_direct_capture_completion_ledger.md")

# --- interpretation ceiling (verbatim; fixture-guarded) ------------------------------
const XL_CEILING = "Findings are LOCAL to this rebuilt trajectory; the " *
    "identity gate licenses non-perturbation ONLY for this " *
    "pristine/X1 pair; Axis-A/B/C statements are DESCRIPTIVE and all " *
    "three mechanism classes (final-state synchronization, " *
    "mapping/write, bounded-algorithm behavior) remain OPEN and " *
    "UNRANKED globally, with no localization and no causal " *
    "attribution; any Axis-C, validator, like-with-like census, pin, " *
    "or reconstruction-integrity inconsistency REFUSES rather than " *
    "concludes, and refusal branches fire on domain-matched " *
    "comparisons only. Historical byte differences license no causal " *
    "inference; no expected probe scientific value was encoded or " *
    "retrofitted."
# durable observed-outcome record (monitor review finding): the LOCAL
# branch that fired, with exact link-by-link semantics; the computed
# values are gated against these literals at runtime (any disagreement
# refuses), and the prose is fixture-guarded against drift
const XL_OBSERVED_OUTCOME = "OBSERVED LOCAL OUTCOME (the branch that " *
    "fired in THIS run): returned_x_log lies outside the CAPTURED " *
    "supplied lower/upper bound vectors at 134 lower + 19 upper " *
    "coordinates. The sidecar-recorded C++ callback mapping " *
    "(mapped_x_phys) equals caller_phys bit-for-bit at all 152640 " *
    "rows; Float32(mapped_x_phys) equals caller_phys_f32 bit-for-bit; " *
    "and caller_phys_f32 equals the serialized raw2 coefficients " *
    "bit-for-bit at every mapped position. The returned-log -> " *
    "mapped-physical SEMANTIC validation relies on the frozen " *
    "validator's declared <=4-ULP cross-library exp tolerance, so " *
    "that link is NOT claimed bit-exact end-to-end: the chain is " *
    "MIXED, one tolerance-bounded link followed by exact-bit links. " *
    "The Axis-A exceedance counts are computed in the log domain " *
    "directly against the exact captured bound vectors and are " *
    "unaffected by the exp-tolerance caveat. The " *
    "returned-state reconstruction changes zero coefficient values " *
    "and the objective delta is exactly 0.0. LICENSED CONCLUSION: no " *
    "observed returned-vs-caller or caller-vs-serialization " *
    "discrepancy in this run; the ORIGIN of the returned-x bound " *
    "exceedances and their relationship to the 22.791293464348826 " *
    "objective remain UNRESOLVED; no historical or global claim."

const XL_RECON_LABEL = "returned-state reconstruction; EXPLORATORY " *
    "SECONDARY; private temp artifact only; no materiality threshold; " *
    "no causal claim; serialized-vs-reconstructed objective equality " *
    "is a scientific outcome, never an acceptance gate; the exact " *
    "delta is preserved at full precision"

# --- primitives -----------------------------------------------------------------------

xl_try_sha(path) = try
    isfile(path) || return nothing
    open(io -> bytes2hex(sha256(io)), path)
catch
    nothing
end

function xl_read_pinned(path, sha; size = nothing, label = basename(path))
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

function xl_pinned_snapshot(path, size, sha; label = basename(path))
    iss, bytes = xl_read_pinned(path, sha; size = size, label = label)
    bytes === nothing && return (iss, nothing)
    snap = joinpath(mktempdir(), "snap_" * basename(path))
    write(snap, bytes)
    (String[], snap)
end

xl_count(text, needle) = length(collect(eachmatch(
    Regex("\\Q" * needle * "\\E"), text)))

function xl_parse_receipt(text)
    f = Dict{String, String}()
    for m in eachmatch(r"([A-Za-z]+)=([^\s]+)", text)
        k = String(m.captures[1])
        k in XL_TOKEN_KEYS && !haskey(f, k) && (f[k] = String(m.captures[2]))
    end
    f
end

# NetCDF opens are sha-BRACKETED: hash before open and after close must
# both equal the pin (coupled-read discipline for files we cannot
# parse from bytes in memory)
function xl_bracketed(fn, path, sha)
    pre = xl_try_sha(path)
    pre == sha || return (["pre-open sha $(pre) != pinned $sha: $path"], nothing)
    out = try
        NCDataset(fn, path)
    catch err
        return (["NetCDF read failed for $path: " *
                 sprint(showerror, err)], nothing)
    end
    post = xl_try_sha(path)
    post == sha || return (["post-close sha $(post) != pinned $sha: $path"],
                           nothing)
    (String[], out)
end

# --- pure axis kernels (fixture-covered) ----------------------------------------------

# AXIS A: exact contract predicates on the log-space sidecar fields
function xl_axis_a(ret, lo, hi, lc, ua, gid, gxi, gas_names)
    n = length(ret)
    below = 0; above = 0; lo_den = 0; hi_den = 0
    exact_lo = 0; exact_hi = 0
    worst_lo = 0.0; worst_hi = 0.0
    below_set = Int[]; above_set = Int[]
    pg = Dict(g => Dict{String, Any}("below" => 0, "above" => 0,
                                     "lo_den" => 0, "hi_den" => 0,
                                     "exact_lo" => 0, "exact_hi" => 0,
                                     "worst_lo_dlog" => 0.0,
                                     "worst_hi_dlog" => 0.0)
              for g in gas_names)
    pc = Dict(string(c) => Dict{String, Any}("den" => 0, "below" => 0,
                                             "exact_lo" => 0)
              for c in (0, 1, 2))
    for i in 1:n
        g = gas_names[gid[i] + 1]
        c = pc[string(lc[i])]
        if lc[i] != 0
            lo_den += 1
            pg[g]["lo_den"] += 1
            c["den"] += 1
            if ret[i] < lo[i]
                below += 1
                pg[g]["below"] += 1
                c["below"] += 1
                push!(below_set, gxi[i])
                d = lo[i] - ret[i]
                worst_lo = max(worst_lo, d)
                pg[g]["worst_lo_dlog"] = max(pg[g]["worst_lo_dlog"], d)
            elseif ret[i] == lo[i]
                exact_lo += 1
                pg[g]["exact_lo"] += 1
                c["exact_lo"] += 1
            end
        else
            c["den"] += 1
        end
        if ua[i] == 1
            hi_den += 1
            pg[g]["hi_den"] += 1
            if ret[i] > hi[i]
                above += 1
                pg[g]["above"] += 1
                push!(above_set, gxi[i])
                d = ret[i] - hi[i]
                worst_hi = max(worst_hi, d)
                pg[g]["worst_hi_dlog"] = max(pg[g]["worst_hi_dlog"], d)
            elseif ret[i] == hi[i]
                exact_hi += 1
                pg[g]["exact_hi"] += 1
            end
        end
    end
    (below = below, above = above, lo_den = lo_den, hi_den = hi_den,
     exact_lo = exact_lo, exact_hi = exact_hi,
     worst_lo_dlog = worst_lo, worst_hi_dlog = worst_hi,
     below_set = below_set, above_set = above_set,
     per_gas = pg, per_lower_class = pc)
end

# callback replication INCLUDING the MIN_X asymmetry: x <= MIN_X -> 0.0
xl_callback_map(x, mfl) = x > mfl ? exp(x) : 0.0

# AXIS B: exact-bit recorded-mapped vs caller comparisons
function xl_axis_b(mapped, caller, f32, gid, gxi, gas_names)
    n = length(mapped)
    mismatch = 0
    mset = Int[]
    pg = Dict(g => 0 for g in gas_names)
    max_abs = 0.0; max_rel = 0.0; max_dlog = 0.0
    m0_c1 = 0; c0_m1 = 0; m0 = 0; c0 = 0
    f32_mismatch = 0
    for i in 1:n
        mapped[i] == 0.0 && (m0 += 1)
        caller[i] == 0.0 && (c0 += 1)
        (mapped[i] == 0.0 && caller[i] != 0.0) && (m0_c1 += 1)
        (caller[i] == 0.0 && mapped[i] != 0.0) && (c0_m1 += 1)
        if mapped[i] !== caller[i]
            mismatch += 1
            push!(mset, gxi[i])
            pg[gas_names[gid[i] + 1]] += 1
            max_abs = max(max_abs, abs(mapped[i] - caller[i]))
            caller[i] != 0.0 &&
                (max_rel = max(max_rel,
                               abs(mapped[i] - caller[i]) / abs(caller[i])))
            (mapped[i] > 0.0 && caller[i] > 0.0) &&
                (max_dlog = max(max_dlog,
                                abs(log(mapped[i]) - log(caller[i]))))
        end
        Float32(mapped[i]) !== f32[i] && (f32_mismatch += 1)
    end
    (mismatch = mismatch, mismatch_set = mset, per_gas = pg,
     max_abs = max_abs, max_rel = max_rel, max_dlog = max_dlog,
     zero_floor = (mapped_zero_caller_nonzero = m0_c1,
                   caller_zero_mapped_nonzero = c0_m1,
                   mapped_zero_total = m0, caller_zero_total = c0),
     f32_of_mapped_vs_caller_f32_mismatch = f32_mismatch)
end

# AXIS C core: like-with-like Float32 positional readback counts per gas
function xl_axis_c_gas(f32rows, ic, it, ip, ig, A, r, nc)
    nbad = 0
    for i in r
        val = nc == -1 ? A[ig[i] + 1, ip[i] + 1, it[i] + 1] :
            A[ig[i] + 1, ip[i] + 1, it[i] + 1, ic[i] + 1]
        val === f32rows[i] || (nbad += 1)
    end
    nbad
end

# census SET mirror of the pinned kernel (same predicates, returning
# index sets); its counts are CROSS-CHECKED against the extracted
# pinned kernel on every real target and in fixtures
function xl_census_sets(X, lo, hi, ini, gxi)
    below_set = Int[]; above_set = Int[]
    lo_den = 0; hi_den = 0
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
                push!(below_set, gxi[i])
                worst_lo = Inf
            elseif log(X[i]) < log_lo_eff
                push!(below_set, gxi[i])
                worst_lo = max(worst_lo, log_lo_eff - log(X[i]))
            end
        end
        if hi[i] > 0
            hi_den += 1
            if X[i] > 0 && log(X[i]) > log(hi[i])
                push!(above_set, gxi[i])
                worst_hi = max(worst_hi, log(X[i]) - log(hi[i]))
            end
        end
    end
    (below_set = below_set, above_set = above_set,
     lo_den = lo_den, hi_den = hi_den,
     worst_lo = worst_lo, worst_hi = worst_hi)
end

# --- sidecar/raw2/init array loading ---------------------------------------------------

function xl_load_sidecar(path, sha)
    xl_bracketed(path, sha) do ds
        (gxi = Array(ds["global_x_index"]),
         gid = Array(ds["gas_id"]),
         goff = Array(ds["gas_offset"]),
         ic = Array(ds["iconc"]),
         it = Array(ds["itemp"]),
         ip = Array(ds["ipress"]),
         ig = Array(ds["igpoint"]),
         lc = Array(ds["lower_class"]),
         ua = Array(ds["upper_active"]),
         ret = Array(ds["returned_x_log"]),
         lo = Array(ds["bound_lo_log"]),
         hi = Array(ds["bound_hi_log"]),
         mapped = Array(ds["mapped_x_phys"]),
         caller = Array(ds["caller_phys"]),
         f32 = Array(ds["caller_phys_f32"]),
         status = Int(Array(ds["minimizer_status"])[]),
         mfl = Array(ds["min_x_log_floor"])[],
         boff = Array(ds["gas_block_offset"]),
         bsize = Array(ds["gas_block_size"]),
         bnconc = Array(ds["gas_block_nconc"]))
    end
end

function xl_load_coeffs(path, sha, vars)
    xl_bracketed(path, sha) do ds
        Dict(v => Array(ds[v]) for v in vars)
    end
end

function xl_load_init(path, sha)
    xl_bracketed(path, sha) do ds
        Dict(g => (mn = Array(ds[g * "_molar_absorption_coeff_min"]),
                   mx = Array(ds[g * "_molar_absorption_coeff_max"]),
                   ini = Array(ds[g * "_molar_absorption_coeff"]))
             for g in XL_ACTIVE_GASES)
    end
end

# per-row positional flattening of init bound/ini arrays via the
# runtime-derived sidecar mapping (the proven index order)
function xl_rowwise_bounds(sc, init, expect)
    n = length(sc.ret)
    lo = Vector{Float64}(undef, n)
    hi = Vector{Float64}(undef, n)
    ini = Vector{Float64}(undef, n)
    for k in 1:length(expect.gas_names)
        g = expect.gas_names[k]
        nc = expect.nconc[k]
        r = (expect.offsets[k] + 1):(expect.offsets[k] + expect.sizes[k])
        A = init[g]
        for i in r
            if nc == -1
                lo[i] = Float64(A.mn[sc.ig[i] + 1, sc.ip[i] + 1, sc.it[i] + 1])
                hi[i] = Float64(A.mx[sc.ig[i] + 1, sc.ip[i] + 1, sc.it[i] + 1])
                ini[i] = Float64(A.ini[sc.ig[i] + 1, sc.ip[i] + 1, sc.it[i] + 1])
            else
                lo[i] = Float64(A.mn[sc.ig[i] + 1, sc.ip[i] + 1, sc.it[i] + 1, sc.ic[i] + 1])
                hi[i] = Float64(A.mx[sc.ig[i] + 1, sc.ip[i] + 1, sc.it[i] + 1, sc.ic[i] + 1])
                ini[i] = Float64(A.ini[sc.ig[i] + 1, sc.ip[i] + 1, sc.it[i] + 1, sc.ic[i] + 1])
            end
        end
    end
    (lo = lo, hi = hi, ini = ini)
end

# census one sidecar-domain target: per-gas pinned kernel + set mirror
# with mandatory count agreement (refusal on any disagreement)
function xl_census_target(label, X, rows_bounds, sc, expect, bset)
    iss = String[]
    per_gas = Dict{String, Any}()
    tot_below = 0; tot_above = 0; tot_lo_den = 0; tot_hi_den = 0
    worst_lo = 0.0; worst_hi = 0.0
    below_all = Int[]; above_all = Int[]
    for k in 1:length(expect.gas_names)
        g = expect.gas_names[k]
        r = (expect.offsets[k] + 1):(expect.offsets[k] + expect.sizes[k])
        Xg = X[r]
        log_ = rows_bounds
        kres = sl_census_gas(Xg, log_.lo[r], log_.hi[r], log_.ini[r])
        sres = xl_census_sets(Xg, log_.lo[r], log_.hi[r], log_.ini[r],
                              sc.gxi[r])
        (length(sres.below_set) == kres.below &&
         length(sres.above_set) == kres.above &&
         sres.lo_den == kres.lo_den && sres.hi_den == kres.hi_den &&
         sres.worst_lo == kres.worst_lo &&
         sres.worst_hi == kres.worst_hi) ||
            push!(iss, "$label/$g: set-mirror disagrees with the pinned kernel (instrument refusal)")
        per_gas[g] = Dict("below" => kres.below, "above" => kres.above,
                          "lo_den" => kres.lo_den, "hi_den" => kres.hi_den,
                          "worst_lo_dlog" => kres.worst_lo,
                          "worst_hi_dlog" => kres.worst_hi)
        tot_below += kres.below; tot_above += kres.above
        tot_lo_den += kres.lo_den; tot_hi_den += kres.hi_den
        worst_lo = max(worst_lo, kres.worst_lo)
        worst_hi = max(worst_hi, kres.worst_hi)
        append!(below_all, sres.below_set)
        append!(above_all, sres.above_set)
    end
    uniq = sort(union(below_all, above_all))
    inter_ba = sort(intersect(below_all, above_all))
    res = Dict(
        "label" => label,
        "below" => tot_below, "above" => tot_above,
        "lo_den" => tot_lo_den, "hi_den" => tot_hi_den,
        "active" => length(X),
        "worst_lo_dlog" => worst_lo, "worst_hi_dlog" => worst_hi,
        "per_gas" => per_gas,
        "below_set" => sort(below_all), "above_set" => sort(above_all),
        "event_sum" => tot_below + tot_above,
        "unique_coordinates" => length(uniq),
        "below_above_overlap_set" => inter_ba,
        "overlap_note" => "event counts and unique-coordinate overlap " *
            "reported side by side; unique is COMPUTED from the sets, " *
            "never inferred as below+above",
        "axis_b_intersections" => Dict(
            "below_and_b_mismatch" => length(intersect(below_all, bset)),
            "above_and_b_mismatch" => length(intersect(above_all, bset))))
    (iss, res)
end

# reconstruction: private temp copy of X1 raw2 with ONLY the four
# active coefficient arrays replaced by Float32(mapped_x_phys) under
# the proven mapping; write-verified by bitwise readback
function xl_reconstruct(x1_path, x1_sha, sc, expect, dir)
    iss = String[]
    _, bytes = xl_read_pinned(x1_path, x1_sha)
    bytes === nothing && return (["reconstruction source read failed"],
                                 nothing, nothing)
    recon = joinpath(dir, "x1_raw2_returned_state_reconstruction.nc")
    write(recon, bytes)
    f32m = Float32.(sc.mapped)
    arrays = Dict{String, Any}()
    NCDataset(recon, "a") do ds
        for k in 1:length(expect.gas_names)
            g = expect.gas_names[k]
            nc = expect.nconc[k]
            r = (expect.offsets[k] + 1):(expect.offsets[k] + expect.sizes[k])
            A = nc == -1 ?
                zeros(Float32, expect.ng[k], expect.np[k], expect.nt[k]) :
                zeros(Float32, expect.ng[k], expect.np[k], expect.nt[k], nc)
            for i in r
                if nc == -1
                    A[sc.ig[i] + 1, sc.ip[i] + 1, sc.it[i] + 1] = f32m[i]
                else
                    A[sc.ig[i] + 1, sc.ip[i] + 1, sc.it[i] + 1, sc.ic[i] + 1] = f32m[i]
                end
            end
            v = ds[g * "_molar_absorption_coeff"]
            if nc == -1
                v[:, :, :] = A
            else
                v[:, :, :, :] = A
            end
            arrays[g] = A
        end
    end
    # bitwise write-verification readback
    NCDataset(recon) do ds
        for g in XL_ACTIVE_GASES
            B = Array(ds[g * "_molar_absorption_coeff"])
            (size(B) == size(arrays[g]) &&
             all(B[j] === arrays[g][j] for j in eachindex(B))) ||
                push!(iss, "reconstruction readback mismatch for $g")
        end
    end
    (iss, recon, arrays)
end

# integrity: every variable OUTSIDE the allowed coefficient set must be
# logically identical (dims, stored types, typed attrs, values), the
# dimension census and global attributes must be identical, and only
# the allowed variables may differ
function xl_recon_integrity(orig_path, recon_path;
                            allowed = XL_COEFF_VARS)
    iss = String[]
    changed = String[]
    NCDataset(orig_path) do da
        NCDataset(recon_path) do db
            ka = sort(collect(keys(da.dim)))
            kb = sort(collect(keys(db.dim)))
            ka == kb || push!(iss, "dimension name sets differ")
            for d in intersect(ka, kb)
                da.dim[d] == db.dim[d] || push!(iss, "dim $d differs")
            end
            ga = sort([String(k) for k in keys(da.attrib)])
            gb = sort([String(k) for k in keys(db.attrib)])
            ga == gb || push!(iss, "global attribute name sets differ")
            for at in intersect(ga, gb)
                va = da.attrib[at]; vb = db.attrib[at]
                (typeof(va) == typeof(vb) && isequal(va, vb)) ||
                    push!(iss, "global attribute $at differs")
            end
            va_names = sort([String(k) for k in keys(da)])
            vb_names = sort([String(k) for k in keys(db)])
            va_names == vb_names ||
                push!(iss, "variable name sets differ")
            for v in intersect(va_names, vb_names)
                xa = da[v]; xb = db[v]
                Tuple(dimnames(xa)) == Tuple(dimnames(xb)) ||
                    push!(iss, "var $v dims differ")
                eltype(xa.var) == eltype(xb.var) ||
                    push!(iss, "var $v stored types differ")
                aa = sort([String(k) for k in keys(xa.attrib)])
                ab = sort([String(k) for k in keys(xb.attrib)])
                aa == ab || push!(iss, "var $v attribute name sets differ")
                for at in intersect(aa, ab)
                    isequal(xa.attrib[at], xb.attrib[at]) ||
                        push!(iss, "var $v attribute $at differs")
                end
                same = isequal(Array(xa), Array(xb))
                if !same
                    push!(changed, v)
                    v in allowed ||
                        push!(iss, "var $v changed but is OUTSIDE the allowed coefficient set (reconstruction scope violation)")
                end
            end
        end
    end
    (iss, sort(changed))
end

xl_overall(groups) = all(isempty, values(groups)) ?
    "x1_run_completed_verified" : "x1_completion_ledger_refused"

# --- TOP-LEVEL pinned-definition extraction + frozen-validator include
# (must happen before main() executes so the definitions live in an
# older world than every call site; fail-closed flags graded in main)
const XL_EXTRACTION_ISSUES = String[]
let
    iss, bytes = xl_read_pinned(XL_S1_SOURCE, XL_S1_SOURCE_SHA;
                                label = "pinned S1 ledger source")
    append!(XL_EXTRACTION_ISSUES, iss)
    if bytes !== nothing
        s1txt = String(copy(bytes))
        for (txt, what) in ((XL_KERNEL_TEXT, "census kernel"),
                            (XL_H2O_TEXT, "H2O constant"),
                            (XL_COMPARATOR_TEXT, "comparator"))
            occursin(txt, s1txt) ||
                push!(XL_EXTRACTION_ISSUES,
                      "$what text not contained byte-for-byte in the pinned S1 source")
        end
    end
end
if isempty(XL_EXTRACTION_ISSUES)
    include_string(@__MODULE__, XL_H2O_TEXT)
    include_string(@__MODULE__, XL_KERNEL_TEXT)
    include_string(@__MODULE__, XL_COMPARATOR_TEXT)
end
const XL_VALIDATOR_ISSUES =
    xl_try_sha(XL_VALIDATOR) == XL_VALIDATOR_SHA ? String[] :
    ["committed validator sha $(xl_try_sha(XL_VALIDATOR)) != pinned $XL_VALIDATOR_SHA"]
isempty(XL_VALIDATOR_ISSUES) && include(XL_VALIDATOR)

function xl_emit_refusal(gates, fails, tests, note)
    result = Dict(
        "case" => "gate4_x1_direct_capture_completion_ledger",
        "data_mode" => "completion_ledger",
        "status" => "x1_completion_ledger_refused",
        "refusal_stage" => note,
        "gates" => gates, "failures" => fails,
        "fixture_verdicts" => tests,
        "evidence_timestamp_utc" => XL_EVIDENCE_TS)
    mkpath(dirname(XL_RESULTS_JSON))
    open(XL_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(XL_RESULTS_MD, "w") do io
        println(io, "# Gate-4 X1 direct-capture completion ledger (job 4561)\n")
        println(io, "Status: **x1_completion_ledger_refused** ($note)\n")
        foreach(f -> println(io, "- ", f), fails)
    end
end

# --- fixtures ---------------------------------------------------------------------------

function xl_fixtures()
    t = Dict{String, Bool}()
    G = ["composite", "h2o", "o3", "co2"]

    # AXIS A kernel
    ret = [-5.0, -7.0, -5.0, -4.0, -1.0, -3.0, -6.0, -2.0]
    lo  = [-6.0, -6.0, -5.0, -6.0, -6.0, -floatmax(Float64), -5.5, -6.0]
    hi  = [ 2.0,  2.0,  2.0, -4.5,  2.0,  floatmax(Float64), 2.0, -2.5]
    lc  = Int32[1, 2, 1, 1, 0, 0, 2, 1]
    ua  = Int32[1, 1, 1, 1, 0, 0, 1, 1]
    gid = Int32[0, 0, 1, 1, 2, 2, 3, 3]
    gxi = Int32[0, 1, 2, 3, 4, 5, 6, 7]
    a = xl_axis_a(ret, lo, hi, lc, ua, gid, gxi, G)
    t["axis_a_counts_exact"] = a.below == 2 && a.above == 2 &&
        a.lo_den == 6 && a.hi_den == 6
    t["axis_a_sets_exact"] = a.below_set == [1, 6] && a.above_set == [3, 7]
    t["axis_a_exact_at_bound_not_violation"] = a.exact_lo == 1
    t["axis_a_worst_dlog"] = a.worst_lo_dlog == 1.0 &&
        a.worst_hi_dlog == 0.5
    t["axis_a_per_gas"] = a.per_gas["composite"]["below"] == 1 &&
        a.per_gas["h2o"]["above"] == 1 && a.per_gas["co2"]["below"] == 1 &&
        a.per_gas["o3"]["lo_den"] == 0
    t["axis_a_per_class"] =
        a.per_lower_class["2"]["below"] == 2 &&
        a.per_lower_class["1"]["below"] == 0 &&
        a.per_lower_class["0"]["den"] == 2
    t["axis_a_inactive_excluded"] = begin
        # rows with lc==0 / ua==0 never enter denominators or sets
        a2 = xl_axis_a([-100.0], [-6.0], [2.0], Int32[0], Int32[0],
                       Int32[0], Int32[9], G)
        a2.below == 0 && a2.above == 0 && a2.lo_den == 0 && a2.hi_den == 0
    end

    # callback replication incl. MIN_X asymmetry
    t["callback_map_asymmetry_at_floor"] =
        xl_callback_map(XL_MIN_X, XL_MIN_X) === 0.0 &&
        xl_callback_map(-745.0, XL_MIN_X) == exp(-745.0) &&
        xl_callback_map(nextfloat(XL_MIN_X), XL_MIN_X) ==
            exp(nextfloat(XL_MIN_X))

    # AXIS B kernel
    mp = [1.0, 2.0, 0.0, 4.0, 0.0, -0.0]
    cl = [1.0, 2.5, 3.0, 4.0, 0.0, 0.0]
    f32 = Float32[1.0f0, 2.5f0, 0.0f0, 4.0f0, 0.0f0, 1.0f0]
    b = xl_axis_b(mp, cl, f32, Int32[0, 0, 1, 1, 2, 3],
                  Int32[0, 1, 2, 3, 4, 5], G)
    t["axis_b_bitwise_mismatch"] = b.mismatch == 3 &&
        b.mismatch_set == [1, 2, 5]
    t["axis_b_negzero_is_mismatch"] = 5 in b.mismatch_set
    t["axis_b_equal_direction"] = begin
        b0 = xl_axis_b([1.0, 0.0], [1.0, 0.0], Float32[1, 0],
                       Int32[0, 1], Int32[0, 1], G)
        b0.mismatch == 0 && isempty(b0.mismatch_set)
    end
    t["axis_b_zero_floor_transitions"] =
        b.zero_floor.mapped_zero_caller_nonzero == 1 &&
        b.zero_floor.caller_zero_mapped_nonzero == 0
    t["axis_b_max_metrics"] = b.max_abs == 3.0 &&
        b.max_rel == 1.0 && b.max_dlog == abs(log(2.0) - log(2.5))
    t["axis_b_f32_projection_mismatch"] = b.f32_of_mapped_vs_caller_f32_mismatch == 2

    # AXIS C core (tiny 3-D block)
    A3 = zeros(Float32, 2, 1, 1)
    A3[1, 1, 1] = 7.0f0; A3[2, 1, 1] = 8.0f0
    f32c = Float32[7.0f0, 8.0f0]
    ic0 = Int32[-1, -1]; it0 = Int32[0, 0]; ip0 = Int32[0, 0]
    ig0 = Int32[0, 1]
    t["axis_c_zero_mismatch_passes"] =
        xl_axis_c_gas(f32c, ic0, it0, ip0, ig0, A3, 1:2, -1) == 0
    t["axis_c_single_mismatch_detected"] = begin
        A3b = copy(A3); A3b[2, 1, 1] = nextfloat(8.0f0)
        xl_axis_c_gas(f32c, ic0, it0, ip0, ig0, A3b, 1:2, -1) == 1
    end

    # census kernel (extracted pinned definition) + set mirror
    X = [1.0e-3, 1.0e-9, 0.0, 5.0, 1.0e-2]
    klo = [1.0e-4, 1.0e-4, 1.0e-4, 0.0, 0.0]
    khi = [1.0, 1.0, 1.0, 2.0, 0.0]
    kini = [1.0e-2, 1.0e-2, 1.0e-2, 1.0e-1, 0.0]
    kr = sl_census_gas(X, klo, khi, kini)
    t["census_kernel_hand_case"] = kr.below == 2 && kr.above == 1 &&
        kr.lo_den == 4 && kr.hi_den == 4 && kr.worst_lo == Inf
    sr = xl_census_sets(X, klo, khi, kini, Int32[10, 11, 12, 13, 14])
    t["census_set_mirror_agrees"] =
        length(sr.below_set) == kr.below &&
        length(sr.above_set) == kr.above &&
        sr.below_set == [11, 12] && sr.above_set == [13] &&
        sr.lo_den == kr.lo_den && sr.hi_den == kr.hi_den &&
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
        uniq = length(union(below_s, above_s))
        uniq == 4 && uniq != length(below_s) + length(above_s) &&
            intersect(below_s, above_s) == [3]
    end
    t["census_axis_b_intersections"] = begin
        length(intersect([1, 2, 3], [2, 9])) == 1 &&
            length(intersect([4], [2, 9])) == 0
    end

    # pin machinery
    fx = mktempdir()
    p = joinpath(fx, "x.bin"); write(p, "abc")
    sh = bytes2hex(sha256("abc"))
    t["pin_green_accepted"] = isempty(xl_read_pinned(p, sh; size = 3)[1])
    t["pin_sha_drift_refuses"] = !isempty(xl_read_pinned(p, "0"^64)[1])
    t["pin_size_drift_refuses"] = !isempty(xl_read_pinned(p, sh; size = 4)[1])
    t["pin_missing_refuses"] =
        !isempty(xl_read_pinned(joinpath(fx, "none"), sh)[1])

    # receipt parsing/agreement
    r1 = xl_parse_receipt("JobId=4561 JobName=g4-x1-lw-direct-capture\n" *
        "JobState=COMPLETED Reason=None ExitCode=0:0 DerivedExitCode=0:0\n" *
        "Restarts=0 RunTime=01:22:01 SubmitTime=2026-08-14T02:29:32 " *
        "StartTime=2026-08-14T02:32:39 EndTime=2026-08-14T03:54:40")
    t["receipt_tokens_parse"] = all(haskey(r1, k) for k in XL_TOKEN_KEYS) &&
        r1 == XL_RECEIPT_EXPECT
    t["receipt_disagreement_detected"] = begin
        r2 = copy(r1); r2["ExitCode"] = "1:0"
        any(r1[k] != r2[k] for k in XL_TOKEN_KEYS)
    end

    # reconstruction integrity scope (tiny synthetic pair)
    rd = mktempdir()
    pa = joinpath(rd, "a.nc"); pb = joinpath(rd, "b.nc")
    for (pp, mutate_coeff, mutate_other) in ((pa, false, false),
                                             (pb, true, false))
        isfile(pp) && rm(pp)
        NCDataset(pp, "c") do ds
            defDim(ds, "n", 2)
            for g in XL_ACTIVE_GASES
                v = defVar(ds, g * "_molar_absorption_coeff", Float32, ("n",))
                v[:] = Float32[1, mutate_coeff && g == "h2o" ? 9 : 2]
            end
            w = defVar(ds, "planck_function", Float64, ("n",))
            w[:] = [1.0, 2.0]
            ds.attrib["config"] = "same"
        end
    end
    iss_ok, changed_ok = xl_recon_integrity(pa, pb)
    t["recon_scope_coeff_only_accepted"] = isempty(iss_ok) &&
        changed_ok == ["h2o_molar_absorption_coeff"]
    t["recon_scope_violation_refuses"] = begin
        pc = joinpath(rd, "c.nc")
        isfile(pc) && rm(pc)
        NCDataset(pc, "c") do ds
            defDim(ds, "n", 2)
            for g in XL_ACTIVE_GASES
                v = defVar(ds, g * "_molar_absorption_coeff", Float32, ("n",))
                v[:] = Float32[1, 2]
            end
            w = defVar(ds, "planck_function", Float64, ("n",))
            w[:] = [1.0, 99.0]
            ds.attrib["config"] = "same"
        end
        !isempty(xl_recon_integrity(pa, pc)[1])
    end
    t["recon_global_attr_change_refuses"] = begin
        pd = joinpath(rd, "d.nc")
        isfile(pd) && rm(pd)
        NCDataset(pd, "c") do ds
            defDim(ds, "n", 2)
            for g in XL_ACTIVE_GASES
                v = defVar(ds, g * "_molar_absorption_coeff", Float32, ("n",))
                v[:] = Float32[1, 2]
            end
            w = defVar(ds, "planck_function", Float64, ("n",))
            w[:] = [1.0, 2.0]
            ds.attrib["config"] = "DIFFERENT"
        end
        !isempty(xl_recon_integrity(pa, pd)[1])
    end

    # like-with-like domain gate (tuple equality helper used in main)
    t["like_with_like_equality_detects_mismatch"] = begin
        c1 = Dict("below" => 134, "above" => 19)
        c2 = Dict("below" => 134, "above" => 20)
        (c1 == c1) && (c1 != c2)
    end

    # comparator execution mode: candidate_mode() must discriminate and
    # the ledger's comparator entry gate must fire on the wrong mode
    # (KeyError("composite") root cause: default "toy" omits the
    # synthesized :composite column amounts)
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

    # extraction containment (live: the pinned S1 source must CONTAIN
    # the executed definitions byte-for-byte)
    s1iss, s1bytes = xl_read_pinned(XL_S1_SOURCE, XL_S1_SOURCE_SHA)
    s1txt = s1bytes === nothing ? "" : String(copy(s1bytes))
    t["kernel_text_contained_in_pinned_s1"] =
        occursin(XL_KERNEL_TEXT, s1txt)
    t["h2o_text_contained_in_pinned_s1"] = occursin(XL_H2O_TEXT, s1txt)
    t["comparator_text_contained_in_pinned_s1"] =
        occursin(XL_COMPARATOR_TEXT, s1txt)
    # observed-outcome prose regression: exact semantics required, the
    # withdrawn over-claim banned
    t["observed_outcome_prose_guards"] =
        occursin("134 lower + 19 upper", XL_OBSERVED_OUTCOME) &&
        occursin("bit-for-bit at all 152640 rows", XL_OBSERVED_OUTCOME) &&
        occursin("<=4-ULP cross-library exp tolerance",
                 XL_OBSERVED_OUTCOME) &&
        occursin("NOT claimed bit-exact end-to-end", XL_OBSERVED_OUTCOME) &&
        occursin("MIXED, one tolerance-bounded link followed by " *
                 "exact-bit links", XL_OBSERVED_OUTCOME) &&
        occursin("computed in the log domain directly against the " *
                 "exact captured bound vectors", XL_OBSERVED_OUTCOME) &&
        occursin("changes zero coefficient values", XL_OBSERVED_OUTCOME) &&
        occursin("remain UNRESOLVED", XL_OBSERVED_OUTCOME) &&
        occursin("no historical or global claim", XL_OBSERVED_OUTCOME) &&
        occursin("no observed returned-vs-caller or " *
                 "caller-vs-serialization discrepancy",
                 XL_OBSERVED_OUTCOME) &&
        !occursin("bit-consistent chain", XL_OBSERVED_OUTCOME)
    t["ceiling_prose_guards"] =
        occursin("OPEN and UNRANKED globally", XL_CEILING) &&
        occursin("REFUSES rather than concludes", XL_CEILING) &&
        occursin("domain-matched", XL_CEILING) &&
        !occursin("trivially fresh", XL_CEILING) &&
        occursin("EXPLORATORY SECONDARY", XL_RECON_LABEL) &&
        occursin("never an acceptance gate", XL_RECON_LABEL)
    t
end

# --- main -------------------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()
    groups = Dict{String, Vector{String}}()

    # extraction + validator pins were graded at TOP LEVEL (world-age
    # correctness); refuse here if either failed
    groups["pinned_definition_extraction"] = XL_EXTRACTION_ISSUES
    groups["frozen_validator_pin"] = XL_VALIDATOR_ISSUES
    if !isempty(XL_EXTRACTION_ISSUES) || !isempty(XL_VALIDATOR_ISSUES)
        for (k, v) in groups
            gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
            isempty(v) || append!(fails, ["$k: " * i for i in v])
        end
        xl_emit_refusal(gates, fails, Dict{String, Bool}(),
                        "pinned-definition extraction / validator pin")
        println("gate4_x1_direct_capture_completion_ledger: x1_completion_ledger_refused (extraction/validator)")
        isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
        return 1
    end
    expect = X1V_LW_EXPECT

    tests = xl_fixtures()
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    # 1. commit + package pins
    cm = String[]
    head = try
        strip(read(`git -C $XL_PROJECT_ROOT rev-parse HEAD`, String))
    catch
        "unreadable"
    end
    commit_ref = XL_COMMIT * "^" * "{commit}"
    commit_ok = try
        strip(read(`git -C $XL_PROJECT_ROOT rev-parse $commit_ref`,
                   String)) == XL_COMMIT
    catch
        false
    end
    commit_ok || push!(cm, "pinned commit $XL_COMMIT not resolvable")
    for (rel, sha) in XL_COMMITTED
        spec = "$(XL_COMMIT):$(rel)"
        blob = try
            bytes2hex(sha256(read(`git -C $XL_PROJECT_ROOT show $spec`)))
        catch
            "unreadable"
        end
        blob == sha ||
            push!(cm, "blob at $XL_COMMIT:$rel sha $blob != pinned $sha")
        xl_try_sha(joinpath(XL_PROJECT_ROOT, rel)) == sha ||
            push!(cm, "on-disk $rel sha != pinned $sha")
    end
    groups["commit_and_package_pins"] = cm

    # 2. custody receipts (dual custody; raw fields before classification)
    rc = String[]
    parsed = Dict{String, Dict{String, String}}()
    for (label, (path, size, sha)) in (
            ("submission_session40", XL_RECEIPT_SUBMISSION),
            ("terminal_agent42", XL_RECEIPT_AGENT42),
            ("terminal_session40", XL_RECEIPT_SESSION40))
        iss, bytes = xl_read_pinned(path, sha; size = size, label = label)
        append!(rc, iss)
        bytes === nothing && continue
        parsed[label] = xl_parse_receipt(String(copy(bytes)))
    end
    if haskey(parsed, "terminal_agent42") && haskey(parsed, "terminal_session40")
        for k in XL_TOKEN_KEYS
            a = get(parsed["terminal_agent42"], k, "<absent-a42>")
            s = get(parsed["terminal_session40"], k, "<absent-s40>")
            a == s || push!(rc, "terminal receipts disagree on $k: $a vs $s")
            s == XL_RECEIPT_EXPECT[k] ||
                push!(rc, "receipt token $k = $s != pinned $(XL_RECEIPT_EXPECT[k])")
        end
    end
    groups["custody_receipts"] = rc

    # 3. job log
    jl = String[]
    log_iss, log_bytes = xl_read_pinned(XL_LOG[1], XL_LOG[3];
                                        size = XL_LOG[2], label = "job log")
    append!(jl, log_iss)
    if log_bytes !== nothing
        lt = String(copy(log_bytes))
        for s in XL_STAGES
            xl_count(lt, "=== X1-lw stage $s:") == 1 ||
                push!(jl, "stage marker $s not exactly once")
        end
        for (needle, n) in ((XL_DONE_MARK, 1), (XL_IDENTITY_PASS, 1),
                            (XL_STATUS_RECORD, 1),
                            ("staged data tree locked read-only (zero writable entries)", 1),
                            ("staged data inputs re-verified post-run (6 files, size+sha, zero writable entries)", 1),
                            ("X1 ALIAS PROBE: shallow-link semantics CONFIRMED", 1),
                            ("X1 CAPTURE WRITTEN: ", 2),
                            ("X1 CAPTURE REFUSED", 0),
                            ("X1 VALIDATOR PASSED (sidecar)", 2),
                            ("X1 VALIDATOR PASSED (identity)", 1),
                            ("raw2 independent schema/finite verification passed", 3),
                            (XL_BANNER_1, 1), (XL_BANNER_3000, 2),
                            ("Minimization is bounded", 3),
                            ("Optimizing coefficients of: composite h2o o3 co2", 3),
                            (XL_CONV_LINE, 3))
            xl_count(lt, needle) == n ||
                push!(jl, "log line count for $(repr(needle)) != $n")
        end
        hits = [m.match for m in eachmatch(XL_FAILURE_RE, lt)]
        isempty(hits) ||
            push!(jl, "failure tokens present in job log: $(join(unique(hits), ", "))")
        # done mark carries the EndTime (fixed evidence timestamp)
        occursin(XL_EVIDENCE_TS * "Z", XL_DONE_MARK) ||
            push!(jl, "done mark inconsistent with pinned EndTime")
    end
    groups["job_log"] = jl

    # 4. arm logs
    al = String[]
    for (arm, path, size, sha) in XL_ARM_LOGS
        iss, bytes = xl_read_pinned(path, sha; size = size,
                                    label = "$arm arm log")
        append!(al, iss)
        bytes === nothing && continue
        txt = String(copy(bytes))
        banner = arm == "probe" ? XL_BANNER_1 : XL_BANNER_3000
        xl_count(txt, banner) == 1 ||
            push!(al, "$arm banner not exactly once")
        xl_count(txt, XL_CONV_LINE) == 1 ||
            push!(al, "$arm convergence line not exactly once")
        xl_count(txt, "Minimization is bounded") == 1 ||
            push!(al, "$arm bounded line not exactly once")
    end
    groups["arm_logs"] = al

    # 5. RUNROOT artifacts
    ar = String[]
    for (label, path, size, sha) in XL_RAW2
        a_iss, _ = xl_read_pinned(path, sha; size = size,
                                  label = "$label raw2")
        append!(ar, a_iss)
    end
    for (t3, label) in ((XL_SIDECAR_PROBE, "probe sidecar"),
                        (XL_SIDECAR_X1, "x1 sidecar"))
        a_iss, _ = xl_read_pinned(t3[1], t3[3]; size = t3[2], label = label)
        append!(ar, a_iss)
    end
    for (t2, label) in ((XL_SRC_ORIG, "solve_adept orig"),
                        (XL_SRC_PATCHED, "solve_adept instrumented"),
                        (XL_SRC_HELPER, "capture helper"))
        xl_try_sha(t2[1]) == t2[2] || push!(ar, "$label sha drift")
    end
    for (t3, label) in ((XL_BIN_PRISTINE, "pristine binary"),
                        (XL_BIN_X1, "x1 binary"))
        a_iss, _ = xl_read_pinned(t3[1], t3[3]; size = t3[2], label = label)
        append!(ar, a_iss)
    end
    cs_iss, cs_bytes = xl_read_pinned(XL_CONFIG_STATUS[1], nothing;
                                      label = "config.status rendering")
    append!(ar, cs_iss)
    cs_bytes !== nothing &&
        strip(String(copy(cs_bytes))) != XL_CONFIG_STATUS[2] &&
        push!(ar, "config.status rendering != corrected reviewed recipe")
    groups["runroot_artifacts"] = ar

    # 6. frozen validator reruns (fail-closed)
    vr = String[]
    for (sc_pin, arm, raw2_pin) in ((XL_SIDECAR_PROBE, "probe", XL_RAW2[1]),
                                    (XL_SIDECAR_X1, "x1", XL_RAW2[3]))
        vi = x1v_sidecar_issues(sc_pin[1]; arm = arm,
                                expected_status = "Maximum iterations reached")
        append!(vr, ["validator sidecar ($arm): " * i for i in vi])
        ai = x1v_axis_c_issues(sc_pin[1], raw2_pin[2])
        append!(vr, ["validator axis-C ($arm): " * i for i in ai])
    end
    append!(vr, ["validator identity: " * i for i in
                 x1v_identity_issues(XL_RAW2[2][2], XL_RAW2[3][2];
                     allowed_value_diff = ["config", "history"],
                     required_value_diffs = ["config", "history"],
                     expected_var_count = 47)])
    groups["frozen_validator_rerun"] = vr

    # 7. array loads (sha-bracketed)
    ld = String[]
    sc_iss, sc = xl_load_sidecar(XL_SIDECAR_X1[1], XL_SIDECAR_X1[3])
    append!(ld, sc_iss)
    pb_iss, pb = xl_load_sidecar(XL_SIDECAR_PROBE[1], XL_SIDECAR_PROBE[3])
    append!(ld, pb_iss)
    init_iss, init = xl_load_init(XL_INIT[1], XL_INIT[3])
    append!(ld, init_iss)
    x1c_iss, x1_coeffs = xl_load_coeffs(XL_RAW2[3][2], XL_RAW2[3][4],
                                        XL_COEFF_VARS)
    append!(ld, x1c_iss)
    prc_iss, pr_coeffs = xl_load_coeffs(XL_RAW2[2][2], XL_RAW2[2][4],
                                        XL_COEFF_VARS)
    append!(ld, prc_iss)
    pbc_iss, pb_coeffs = xl_load_coeffs(XL_RAW2[1][2], XL_RAW2[1][4],
                                        XL_COEFF_VARS)
    append!(ld, pbc_iss)
    groups["array_loads"] = ld
    if !all(isempty, values(groups))
        # refuse before any science on missing/drifted evidence
        for (k, v) in groups
            gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
            isempty(v) || append!(fails, ["$k: " * i for i in v])
        end
        status = "x1_completion_ledger_refused"
        println("gate4_x1_direct_capture_completion_ledger: $status (evidence)")
        for k in sort(collect(keys(gates)))
            println("  $k: $(gates[k])")
        end
        isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
        return 1
    end

    # 8. axes on the FULL X1 sidecar
    ax = String[]
    sc.mfl == XL_MIN_X || push!(ax, "sidecar MIN_X floor != pinned")
    axis_a = xl_axis_a(sc.ret, sc.lo, sc.hi, sc.lc, sc.ua, sc.gid,
                       sc.gxi, expect.gas_names)
    axis_b = xl_axis_b(sc.mapped, sc.caller, sc.f32, sc.gid, sc.gxi,
                       expect.gas_names)
    axis_c_pg = Dict{String, Int}()
    f64_domain_pg = Dict{String, Int}()
    for k in 1:length(expect.gas_names)
        g = expect.gas_names[k]
        r = (expect.offsets[k] + 1):(expect.offsets[k] + expect.sizes[k])
        A = x1_coeffs[g * "_molar_absorption_coeff"]
        axis_c_pg[g] = xl_axis_c_gas(sc.f32, sc.ic, sc.it, sc.ip, sc.ig,
                                     A, r, expect.nconc[k])
        # SEPARATE LABELED Float64-domain report (NEVER the gate):
        # raw2 (F32 promoted to F64) vs caller_phys F64
        nb = 0
        for i in r
            val = expect.nconc[k] == -1 ?
                A[sc.ig[i] + 1, sc.ip[i] + 1, sc.it[i] + 1] :
                A[sc.ig[i] + 1, sc.ip[i] + 1, sc.it[i] + 1, sc.ic[i] + 1]
            Float64(val) !== sc.caller[i] && (nb += 1)
        end
        f64_domain_pg[g] = nb
    end
    axis_c_total = sum(values(axis_c_pg))
    axis_c_total == 0 ||
        push!(ax, "AXIS C mismatch total $axis_c_total != 0 (like-with-like Float32 positional readback): COMPLETION REFUSAL")
    groups["axis_c_gate"] = ax

    # probe control: STRUCTURAL gates already enforced by the frozen
    # validator rerun above; A/B here are DESCRIPTIVE observations only
    probe_axis_a = xl_axis_a(pb.ret, pb.lo, pb.hi, pb.lc, pb.ua, pb.gid,
                             pb.gxi, expect.gas_names)
    probe_axis_b = xl_axis_b(pb.mapped, pb.caller, pb.f32, pb.gid,
                             pb.gxi, expect.gas_names)
    probe_axis_c_pg = Dict{String, Int}()
    pc_iss = String[]
    for k in 1:length(expect.gas_names)
        g = expect.gas_names[k]
        r = (expect.offsets[k] + 1):(expect.offsets[k] + expect.sizes[k])
        probe_axis_c_pg[g] = xl_axis_c_gas(pb.f32, pb.ic, pb.it, pb.ip,
            pb.ig, pb_coeffs[g * "_molar_absorption_coeff"], r,
            expect.nconc[k])
    end
    sum(values(probe_axis_c_pg)) == 0 ||
        push!(pc_iss, "probe Axis-C mismatch (projection/order contract): instrument refusal")
    groups["probe_control_contract"] = pc_iss

    # 9. censuses (pinned kernel; six targets) + intersections
    cs = String[]
    rowsb = xl_rowwise_bounds(sc, init, expect)
    bset = axis_b.mismatch_set
    census = Dict{String, Any}()
    # build serialized-domain X vectors positionally (same mapping)
    function rows_from_coeffs(coeffs)
        X = Vector{Float64}(undef, length(sc.ret))
        for k in 1:length(expect.gas_names)
            g = expect.gas_names[k]
            A = coeffs[g * "_molar_absorption_coeff"]
            r = (expect.offsets[k] + 1):(expect.offsets[k] + expect.sizes[k])
            for i in r
                X[i] = expect.nconc[k] == -1 ?
                    Float64(A[sc.ig[i] + 1, sc.ip[i] + 1, sc.it[i] + 1]) :
                    Float64(A[sc.ig[i] + 1, sc.ip[i] + 1, sc.it[i] + 1, sc.ic[i] + 1])
            end
        end
        X
    end
    for (label, X) in (
            ("pristine_raw2", rows_from_coeffs(pr_coeffs)),
            ("x1_raw2", rows_from_coeffs(x1_coeffs)),
            ("caller_f64", copy(sc.caller)),
            ("caller_f32", Float64.(sc.f32)),
            ("mapped_f64", copy(sc.mapped)),
            ("mapped_f32", Float64.(Float32.(sc.mapped))))
        c_iss, cres = xl_census_target(label, X, rowsb, sc, expect, bset)
        append!(cs, c_iss)
        census[label] = cres
    end
    # like-with-like domain gate: Axis C == 0 forces the x1-raw2 and
    # caller-F32 censuses to be identical; any difference is a logical
    # inconsistency and refuses (domain-matched comparison only)
    for f in ("below", "above", "lo_den", "hi_den", "worst_lo_dlog",
              "worst_hi_dlog")
        census["x1_raw2"][f] == census["caller_f32"][f] ||
            push!(cs, "like-with-like census inconsistency: x1_raw2 vs caller_f32 field $f (Axis C zero-mismatch makes this logically impossible): REFUSAL")
    end
    census["x1_raw2"]["below_set"] == census["caller_f32"]["below_set"] &&
        census["x1_raw2"]["above_set"] == census["caller_f32"]["above_set"] ||
        push!(cs, "like-with-like census inconsistency: x1_raw2 vs caller_f32 index sets differ: REFUSAL")
    # committed-census comparison: INFORMATIONAL for this NEW build
    # (domain-matched raw2 comparison; a difference is recorded, never
    # concluded from)
    committed_match = census["x1_raw2"]["below"] == XL_S1_CENSUS.below &&
        census["x1_raw2"]["above"] == XL_S1_CENSUS.above &&
        census["x1_raw2"]["lo_den"] == XL_S1_CENSUS.lo_den &&
        census["x1_raw2"]["hi_den"] == XL_S1_CENSUS.hi_den &&
        census["x1_raw2"]["worst_lo_dlog"] == XL_S1_CENSUS.worst_lo &&
        census["x1_raw2"]["worst_hi_dlog"] == XL_S1_CENSUS.worst_hi
    groups["census_consistency"] = cs

    # 10. comparator (secondary, pre-registered)
    cp = String[]
    for (rel, sha) in XL_CODE_PINS
        xl_try_sha(joinpath(XL_PROJECT_ROOT, rel)) == sha ||
            push!(cp, "comparator code pin drift: $rel")
    end
    src_spec = "$(XL_COMMIT):src"
    src_tree = try
        strip(read(`git -C $XL_PROJECT_ROOT rev-parse $src_spec`, String))
    catch
        "unreadable"
    end
    src_tree == XL_SRC_TREE || push!(cp, "src tree at $XL_COMMIT != reviewed")
    groups["comparator_code_pins"] = cp

    ci = String[]
    objectives = Dict{String, Any}()
    recon_changed = String[]
    if isempty(cp)
        # identical comparator configuration to the pinned S1 ledger:
        # official-ecckd candidate gas optics (synthesizes the
        # :composite column amounts); gated, not assumed
        ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
        candidate_mode() == "official_ecckd" ||
            push!(ci, "comparator candidate mode != official_ecckd")
        sw_iss, sw_snap = xl_pinned_snapshot(
            official_ecckd_definition_path(:shortwave_32),
            XL_PUB_SW_BYTES, XL_PUB_SW_SHA; label = "published SW32")
        append!(ci, sw_iss)
        lw_iss, lw_snap = xl_pinned_snapshot(
            official_ecckd_definition_path(:longwave_32),
            XL_PUB_LW_BYTES, XL_PUB_LW_SHA; label = "published LW32")
        append!(ci, lw_iss)
        x1_iss, x1_snap = xl_pinned_snapshot(XL_RAW2[3][2], XL_RAW2[3][3],
                                             XL_RAW2[3][4];
                                             label = "x1 raw2 snapshot")
        append!(ci, x1_iss)
        snapshot_cases = Any[]
        for (name, path, size, sha) in XL_CASE_INPUTS
            k_iss, k_snap = xl_pinned_snapshot(path, size, sha;
                                               label = "case input $name")
            append!(ci, k_iss)
            k_snap === nothing || push!(snapshot_cases,
                                        (case = name, path = k_snap))
        end
        r_iss, recon, _ = xl_reconstruct(XL_RAW2[3][2], XL_RAW2[3][4],
                                         sc, expect, mktempdir())
        append!(ci, r_iss)
        if recon !== nothing
            ri_iss, recon_changed = xl_recon_integrity(XL_RAW2[3][2], recon)
            append!(ci, ri_iss)
        end
        if isempty(ci) && sw_snap !== nothing
            try
                # PER-ARTIFACT determinism: each artifact scored TWICE,
                # bit-equality required. Serialized-vs-reconstructed
                # equality is a SCIENTIFIC OUTCOME, never a gate.
                for (label, snap, expected) in (
                        ("published_selfcheck", lw_snap,
                         XL_PUBLISHED_BASELINE),
                        ("x1_serialized", x1_snap, nothing),
                        ("returned_state_reconstruction", recon, nothing))
                    v1 = sl_swap_objective(snap, sw_snap, snapshot_cases)
                    v2 = sl_swap_objective(snap, sw_snap, snapshot_cases)
                    v1 == v2 ||
                        push!(ci, "$label objective not repeatable in-run ($v1 vs $v2)")
                    objectives[label] = v1
                    expected === nothing || v1 == expected ||
                        push!(ci, "$label objective $v1 != pinned $expected (bit-exact required)")
                end
                if haskey(objectives, "x1_serialized") &&
                   haskey(objectives, "returned_state_reconstruction")
                    objectives["delta_reconstruction_minus_serialized"] =
                        objectives["returned_state_reconstruction"] -
                        objectives["x1_serialized"]
                end
            catch err
                push!(ci, "comparator evaluation failed: " *
                          sprint(showerror, err))
            end
        end
    else
        push!(ci, "comparator not run (code pins failed)")
    end
    groups["comparator_integrity"] = ci

    # durable observed-outcome consistency: the fixed-text literals
    # must EQUAL the computed values (fail closed; the durable record
    # can never disagree with the arithmetic)
    oo = String[]
    (axis_a.below == 134 && axis_a.above == 19) ||
        push!(oo, "observed_outcome literals disagree with computed Axis A ($(axis_a.below)/$(axis_a.above))")
    axis_b.mismatch == 0 ||
        push!(oo, "observed_outcome contradicted: Axis B mismatch $(axis_b.mismatch) != 0")
    axis_b.f32_of_mapped_vs_caller_f32_mismatch == 0 ||
        push!(oo, "observed_outcome contradicted: Float32(mapped) vs caller_f32 mismatch != 0")
    axis_c_total == 0 ||
        push!(oo, "observed_outcome contradicted: Axis C total != 0")
    isempty(recon_changed) ||
        push!(oo, "observed_outcome contradicted: reconstruction changed $(length(recon_changed)) variables")
    get(objectives, "delta_reconstruction_minus_serialized", nothing) == 0.0 ||
        push!(oo, "observed_outcome contradicted: objective delta != 0.0")
    get(objectives, "x1_serialized", nothing) == 22.791293464348826 ||
        push!(oo, "observed_outcome contradicted: serialized objective != quoted value")
    groups["observed_outcome_consistency"] = oo

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end
    status = gates["fixtures"] == "passed" ? xl_overall(groups) :
        "x1_completion_ledger_refused"

    axis_pack(a) = Dict(
        "below" => a.below, "above" => a.above,
        "lo_den" => a.lo_den, "hi_den" => a.hi_den,
        "exact_at_lower_bound" => a.exact_lo,
        "exact_at_upper_bound" => a.exact_hi,
        "worst_lo_dlog" => a.worst_lo_dlog,
        "worst_hi_dlog" => a.worst_hi_dlog,
        "below_index_set" => a.below_set,
        "above_index_set" => a.above_set,
        "per_gas" => a.per_gas,
        "per_lower_class" => a.per_lower_class)
    b_pack(b) = Dict(
        "exact_bit_mismatch" => b.mismatch,
        "mismatch_index_set" => b.mismatch_set,
        "per_gas" => b.per_gas,
        "max_abs" => b.max_abs, "max_rel" => b.max_rel,
        "max_dlog" => b.max_dlog,
        "zero_floor_transitions" => Dict(
            "mapped_zero_caller_nonzero" => b.zero_floor.mapped_zero_caller_nonzero,
            "caller_zero_mapped_nonzero" => b.zero_floor.caller_zero_mapped_nonzero,
            "mapped_zero_total" => b.zero_floor.mapped_zero_total,
            "caller_zero_total" => b.zero_floor.caller_zero_total),
        "f32_of_mapped_vs_caller_f32_mismatch" =>
            b.f32_of_mapped_vs_caller_f32_mismatch,
        "mapping_semantics" => "callback replicated EXACTLY incl. the " *
            "MIN_X asymmetry: x <= MIN_X maps to 0.0, never exp(x)")

    result = Dict(
        "case" => "gate4_x1_direct_capture_completion_ledger",
        "data_mode" => "completion_ledger",
        "status" => status,
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "fixture_count" => length(tests),
        "evidence_timestamp_utc" => XL_EVIDENCE_TS,
        "job" => Dict("id" => 4561,
                      "receipt_tokens" => get(parsed, "terminal_session40",
                                              Dict()),
                      "dual_custody" => "terminal receipts agree token-" *
                          "for-token; raw fields recorded before " *
                          "classification"),
        "pins" => Dict(
            "commit" => XL_COMMIT,
            "committed_files" => Dict(rel => sha for (rel, sha) in XL_COMMITTED),
            "runroot" => XL_RUNROOT,
            "raw2" => Dict(l => s for (l, _, _, s) in XL_RAW2),
            "sidecars" => Dict("probe" => XL_SIDECAR_PROBE[3],
                               "x1" => XL_SIDECAR_X1[3]),
            "sources" => Dict("orig" => XL_SRC_ORIG[2],
                              "instrumented" => XL_SRC_PATCHED[2],
                              "helper" => XL_SRC_HELPER[2]),
            "binaries" => Dict("pristine" => XL_BIN_PRISTINE[3],
                               "x1" => XL_BIN_X1[3]),
            "init_bounds_source" => XL_INIT[3],
            "s1_ledger_source" => XL_S1_SOURCE_SHA,
            "receipts" => Dict(
                "submission_session40" => XL_RECEIPT_SUBMISSION[3],
                "terminal_agent42" => XL_RECEIPT_AGENT42[3],
                "terminal_session40" => XL_RECEIPT_SESSION40[3]),
            "job_log" => XL_LOG[3],
            "arm_logs" => Dict(a => s for (a, _, _, s) in XL_ARM_LOGS)),
        "axes_full_x1" => Dict(
            "axis_a" => axis_pack(axis_a),
            "axis_b" => b_pack(axis_b),
            "axis_c" => Dict(
                "per_gas_mismatch" => axis_c_pg,
                "total_mismatch" => axis_c_total,
                "gate" => "like-with-like Float32 positional readback; " *
                    "zero-mismatch REQUIRED or completion refusal",
                "f64_domain_descriptive_report" => Dict(
                    "per_gas_nonidentical_f64" => f64_domain_pg,
                    "label" => "SEPARATE Float64-domain comparison " *
                        "(raw2 promoted to F64 vs caller_phys); " *
                        "DESCRIPTIVE ONLY, never the gate; nonzero " *
                        "counts here reflect the F32 serialization " *
                        "projection, not an instrument fault"))),
        "probe_control" => Dict(
            "label" => "DESCRIPTIVE semantic control (Agent 42 item 4 " *
                "as corrected by the monitor): structural validator/" *
                "schema/status/order/projection gates are the ONLY " *
                "refusal conditions; probe Axis-A/B outcomes are real " *
                "observed results, never gates; no expected probe " *
                "scientific value encoded or retrofitted",
            "axis_a" => axis_pack(probe_axis_a),
            "axis_b" => b_pack(probe_axis_b),
            "axis_c_per_gas_mismatch" => probe_axis_c_pg),
        "census" => Dict(
            "kernel" => "source-faithful S1 log-space kernel reused BY " *
                "EXACT PINNED DEFINITION (byte-containment in the " *
                "committed S1 ledger source $XL_S1_SOURCE_SHA, " *
                "evaluated via include_string); set mirror " *
                "cross-checked against kernel counts on every target",
            "bounds_source" => "pinned initial raw definition " *
                "$(XL_INIT[3]); sidecar-domain targets aligned " *
                "positionally via the runtime-derived proven mapping",
            "targets" => census,
            "committed_census_comparison" => Dict(
                "committed" => Dict("below" => XL_S1_CENSUS.below,
                    "above" => XL_S1_CENSUS.above,
                    "lo_den" => XL_S1_CENSUS.lo_den,
                    "hi_den" => XL_S1_CENSUS.hi_den,
                    "worst_lo_dlog" => XL_S1_CENSUS.worst_lo,
                    "worst_hi_dlog" => XL_S1_CENSUS.worst_hi,
                    "per_gas" => Dict(g => Dict(
                        "below" => XL_S1_CENSUS_PER_GAS[g].below,
                        "above" => XL_S1_CENSUS_PER_GAS[g].above)
                        for g in XL_ACTIVE_GASES)),
                "x1_raw2_matches_committed" => committed_match,
                "semantics" => "INFORMATIONAL domain-matched " *
                    "comparison for this NEW build; a difference is " *
                    "recorded, never concluded from; refusal is " *
                    "reserved for logical inconsistencies within this " *
                    "run's domain-matched triangle (Axis C == 0 forces " *
                    "x1_raw2 census == caller_f32 census)")),
        "objectives" => Dict(
            "comparator" => "pinned deterministic comparator (identical " *
                "code pins AND configuration to the reviewed S1 ledger: " *
                "RH_CANDIDATE_GAS_OPTICS=official_ecckd, snapshot-set " *
                "evaluation, H2O=0.005 hard-coded); PER-ARTIFACT " *
                "determinism: each artifact scored twice, bit-equality " *
                "required",
            "values" => objectives,
            "published_selfcheck_pinned" => XL_PUBLISHED_BASELINE,
            "labels" => Dict(
                "x1_serialized" => "primary serialized state of THIS " *
                    "new build (no pinned expectation; recorded exact)",
                "returned_state_reconstruction" => XL_RECON_LABEL)),
        "reconstruction" => Dict(
            "definition" => "private temp copy of the X1 raw2 with " *
                "ONLY the four active coefficient arrays replaced by " *
                "Float32(mapped_x_phys) under the proven mapping",
            "changed_variables" => recon_changed,
            "integrity" => "every other variable PROVEN unchanged " *
                "(dims/types/typed attrs/values + global attributes), " *
                "bitwise write-verification readback; any scope " *
                "violation refuses"),
        "interpretation" => Dict(
            "observed_outcome" => XL_OBSERVED_OUTCOME,
            "ceiling" => XL_CEILING,
            "identity_gate" => "non-perturbation licensed ONLY for " *
                "this pristine/X1 pair by the in-job all-variable " *
                "identity gate (re-verified here by the frozen " *
                "validator identity rerun)",
            "checklist" => "Agent 42 predeclared omission-probe items " *
                "1-7 adopted with the monitor's item-4 correction " *
                "(probe = structural gates only; descriptive A/B) and " *
                "item-5 clarification (per-artifact repeat equality; " *
                "delta preserved, never gated)"),
        "non_authorizing_note" => "this ledger interprets nothing " *
            "beyond its committed ceiling and authorizes nothing; " *
            "next steps require explicit monitor rulings",
        "disclaimer" => "completion ledger; writes nothing except its " *
            "own JSON/MD results and transient private temp files " *
            "(mktempdir); zero canonical writes; RUNROOT untouched")

    mkpath(dirname(XL_RESULTS_JSON))
    open(XL_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(XL_RESULTS_MD, "w") do io
        println(io, "# Gate-4 X1 direct-capture completion ledger (job 4561)\n")
        println(io, "Status: **$status**\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nFixtures: $(length(tests)) ($(count(values(tests))) passed)")
        println(io, "\n## Axis results (FULL X1 arm; descriptive)")
        println(io, "- AXIS A: below $(axis_a.below)/$(axis_a.lo_den), " *
            "above $(axis_a.above)/$(axis_a.hi_den); worst dlog " *
            "$(axis_a.worst_lo_dlog) / $(axis_a.worst_hi_dlog); " *
            "exact-at-bound $(axis_a.exact_lo) / $(axis_a.exact_hi)")
        println(io, "- AXIS B: exact-bit mapped-vs-caller mismatches " *
            "$(axis_b.mismatch); max abs $(axis_b.max_abs), max rel " *
            "$(axis_b.max_rel), max dlog $(axis_b.max_dlog); " *
            "Float32(mapped) vs caller_f32 mismatches " *
            "$(axis_b.f32_of_mapped_vs_caller_f32_mismatch)")
        println(io, "- AXIS C: total mismatch $(axis_c_total) " *
            "(zero required; per gas $(axis_c_pg))")
        println(io, "\n## Probe control (descriptive)")
        println(io, "- AXIS A: below $(probe_axis_a.below)/$(probe_axis_a.lo_den), " *
            "above $(probe_axis_a.above)/$(probe_axis_a.hi_den)")
        println(io, "- AXIS B: exact-bit mismatches $(probe_axis_b.mismatch)")
        println(io, "\n## Census (pinned kernel)")
        for lbl in ("pristine_raw2", "x1_raw2", "caller_f64",
                    "caller_f32", "mapped_f64", "mapped_f32")
            c = census[lbl]
            println(io, "- $lbl: below $(c["below"])/$(c["lo_den"]), " *
                "above $(c["above"])/$(c["hi_den"]); worst dlog " *
                "$(c["worst_lo_dlog"]) / $(c["worst_hi_dlog"]); " *
                "event sum $(c["event_sum"]), unique coordinates " *
                "$(c["unique_coordinates"]); B-intersections " *
                "$(c["axis_b_intersections"])")
        end
        println(io, "- x1_raw2 matches committed S1 census: $committed_match (informational)")
        println(io, "\n## Objectives (secondary, pre-registered)")
        for k in sort(collect(keys(objectives)))
            println(io, "- $k: $(objectives[k])")
        end
        println(io, "\n## Observed outcome (local branch fired)\n")
        println(io, XL_OBSERVED_OUTCOME)
        println(io, "\n## Interpretation ceiling\n")
        println(io, XL_CEILING)
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_x1_direct_capture_completion_ledger: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    println("  fixtures: $(count(values(tests)))/$(length(tests)) passed")
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "x1_run_completed_verified" ? 0 : 1
end

exit(main())
