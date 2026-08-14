# Gate-4 C3-IB ITERATION-BUDGET CHECKPOINT (generator; r2 RECOVERY
# REVISION after job 4578 FAILED 134:0, staging-manifest-completeness
# gap). CLI ACTIVE: running this file regenerates the checkpoint
# artifacts fail-closed. Recovery scope (harness/provenance only; the
# scientific design, selected modes, budgets, and scoring are byte-
# unchanged): eval1 staging manifest = the EXACT 20-name selected-mode
# closure (relative-base/ch4/n2o/cfc), generation-derived from the
# pinned structured published-training manifest and cross-checked
# against the generation-derived deployed script blocks plus the
# G3 executor staged sets; the 4578 failure ledger is a structured fail-closed
# prerequisite; an early pre-build staged-census gate refuses input-
# closure gaps in seconds.
#
# FROZEN DESIGN AUTHORITY (monitor freeze):
# gate4_c3_ib_iteration_budget_frozen_design.md sha256
# e5af535f2d1c9efb478bb1b856f632fe05a5dfd01dec634cfecc41a67e44bb63.
#
# SHAPE (binding): probe(1) + sandwich C0a(3000) -> C3IB(9000) ->
# C0b(3000), bounded mode default-on; two-script discipline with
# generation-derived byte pins (hardened downstream template + three
# hardened base variants); complete private LW chains per arm with
# per-pass upstream token records (3x4 census); EXACTLY 13
# staged-evaluator scores (12 arm-panel + fixed current-G1 anchor,
# severability: a miss refuses only the current-G1-adjacent label);
# structural scans before scoring; full masters/env/code staging with
# the stage-0 preflight -> stage-1 copy/verify/freeze bracket and
# post-run reverification; ZERO canonical writes; RUNROOT preserved.
# Shared gate code: committed P1 checker + committed P2 checker + the
# C3 checker, env-pinned single-include chain.

const P2_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
include(joinpath(P2_PROJECT_ROOT, "validation", "validation_results.jl"))

# SECTION A (C3-IB adaptation): single include chain via the C3
# checker -- it owns the P2 include, which owns P1 + the evaluator
# chain, each exactly once (generation-time semantics: live reads are
# lawful pre-freeze; the JOB reads only staged copies). Fail-closed
# env pins per the C3 checker contract.
ENV["P2C_P1_CHECKER"] = joinpath(P2_PROJECT_ROOT, "validation",
                                 "gate4_p1_splice_checker.jl")
ENV["C3C_P2_CHECKER"] = joinpath(P2_PROJECT_ROOT, "validation",
                                 "gate4_p2_hard_objective_checker.jl")
ENV["P2C_CHAIN_DIR"] = joinpath(P2_PROJECT_ROOT, "validation")
include(joinpath(P2_PROJECT_ROOT, "validation",
                 "gate4_c3_ib_checker.jl"))

import JSON

const C3G_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"

# SECTION B (C3-IB adaptation): design + results identity, C3 checker
# pin, run-side C1 constants, and the three pinned scoring masters.
const C3G_DESIGN_SHA = "e5af535f2d1c9efb478bb1b856f632fe05a5dfd01dec634cfecc41a67e44bb63"
const C3G_TERMINAL_CONTRACT =
    "TERMINAL POLICY (BINDING SUPERSESSION): ANY terminal state of " *
    "this job -- COMPLETED, FAILED, CANCELLED, NODE_FAIL, " *
    "OUT_OF_MEMORY, and TIMEOUT alike -- is a HOLD; TIMEOUT is NOT " *
    "a continuity exception, and the old campaign protocol's " *
    "TIMEOUT-continuity default is EXPLICITLY SUPERSEDED for this " *
    "unit; NO automatic retry or resubmission in any terminal " *
    "state; the next action after ANY terminal state requires a " *
    "new explicit Codex-monitor review and GO with hash " *
    "verification; the RUNROOT, once created, is preserved as " *
    "forensics in every terminal state."
const C3G_DESIGN_FILE = joinpath(@__DIR__, "gate4_c3_ib_iteration_budget_frozen_design.md")
const C3G_DESIGN_REPO_PATH = "validation/gate4_c3_ib_iteration_budget_frozen_design.md"
const C3G_CHECKER_REPO = "validation/gate4_c3_ib_checker.jl"
# STOPPED checker pins (update on every reviewed checker revision)
const C3G_P2_CHECKER_SHA = "2ba2fac1947fa727bd35d5931923a62edd77f8a82646024781fd2f74960ac575"
const C3G_CHECKER_SHA = "06ce129768bafaa8dcf18e6cff063e030dafeeeca428447342c2a6033e5a1b82"
const C3G_TEST_PROJECT_BYTES = 606
const C3G_TEST_MANIFEST_BYTES = 58343
# run-side constants (committed C1 generator forms, 6db5a23 family)
const C3G_SRC_ARTIFACT = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"
const C3G_TREE_FILES = 119
const C3G_TREE_EXEC = 24
const C3G_ADEPT = "/shared/home/greg/local/adept-2-install"
const C3G_MINIMIZER_H_SHA = "dad747936a66304266d0dd31990afa3a7534c589ac6b7a9230eaafbe671a1f8d"
const C3G_MINIMIZER_H_BYTES = 13383
const C3G_LIBADEPT_SHA = "1f9016af1b6982493dc8d53dd3a11b2b0c54d4e84c4dbb548b4b06093d43dbcb"
const C3G_LIBADEPT_BYTES = 7172632
const C3G_ADEPT_SOURCE_H_SHA = "8f29a64a2d8227e881a7a541e154d80b752f7746c8607f6a9f280b54f0312351"
const C3G_ADEPT_SOURCE_H_BYTES = 157986
const C3G_NETCDF = "/shared/home/greg/local/ckdmip-stack"
const C3G_CONFIGURE_ARGV = "./configure --with-adept=$C3G_ADEPT " *
    "--with-netcdf=$C3G_NETCDF " *
    "'LDFLAGS=-L$C3G_ADEPT/lib -Wl,-rpath,$C3G_ADEPT/lib' 'LIBS=-ladept'"
const C3G_CONFIG_STATUS_EXPECT = "--with-adept=$C3G_ADEPT " *
    "--with-netcdf=$C3G_NETCDF " *
    "'LDFLAGS=-L$C3G_ADEPT/lib -Wl,-rpath,$C3G_ADEPT/lib' LIBS=-ladept"
const C3G_TOOLCHAIN = [
    ("gcc", "/usr/bin/gcc", "gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"),
    ("g++", "/usr/bin/g++", "g++ (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"),
    ("make", "/usr/bin/make", "GNU Make 4.3"),
    ("autoreconf", "/usr/bin/autoreconf", "autoreconf (GNU Autoconf) 2.71")]
const C3G_AUTOMAKE_VER = "1.16.5"
const C3G_LIBTOOLIZE_VER = "2.4.7"
const C3G_SHIM_SO = "/shared/home/greg/ecckd-derived-flux-work/" *
    "g4-init-generation/tools/h5open_before_traps.so"
const C3G_SHIM_SO_SHA = "28003281a7f1c8470c1bfd94a654999a210581261a5c3e9cd662af2a13dd492f"
const C3G_SHIM_SO_BYTES = 15328
const C3G_NETLIB_BLAS = "/usr/lib/x86_64-linux-gnu/blas/libblas.so.3.12.0"
const C3G_NETLIB_BLAS_SHA = "e748efcae5753fe4a652877fccdb5895ac6f7605668a2db878b19c914e78e3a8"
const C3G_NETLIB_BLAS_BYTES = 677880
const C3G_NETLIB_LAPACK = "/usr/lib/x86_64-linux-gnu/lapack/liblapack.so.3.12.0"
const C3G_NETLIB_LAPACK_SHA = "851bb1fc5833ede9ed704b4417a251a899976d5e0915de40452615187a65278f"
const C3G_NETLIB_LAPACK_BYTES = 7268368
const C3G_CKDMIP_ROOT = "/shared/home/greg/data/ckdmip"
const C3G_DATA_INPUTS = [
    ("dde735608e57af934a2c1e99932c0ccce530883ab48910c7e17b621de7fa0bee", 450863,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-180.h5"),
    ("b0932f2648f720af74191d2a9d62f6178f73dfb9a620b773e55670f06ce2db85", 450863,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-280.h5"),
    ("01836becbc96e7da2b3b33d586d148948df136457216625b7e60225e093e1792", 450863,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-415.h5"),
    ("c8aa819b9e7ea7ed73a0af74862ab49d4209866b74988529b2dfce0ef99710e2", 450863,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-560.h5"),
    ("cfbda1d66decc14e6e91e8465f32f5a5e4bcf0310a73f620fe45bafbcec9ba7c", 450873,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-1120.h5"),
    ("75239df6dbf578b3be6267c09995ff050f5c846be3c75492fad96dcab25610e8", 450873,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_rel-2240.h5"),
    ("98ccb738a2cc9fe72a3da18ab1da9e10e1c639302e16b43640dcf4011b7aecb4", 469175,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_present.h5"),
    ("67e386755139d0623dab0f0d45036940c1d7c497c3eeabb6bb046ad9a8c885e4", 469174,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-350.h5"),
    ("5097a2044a6cc471a6658129bdbea48bdd7fb5da11c6f372a66fb9c5642f5759", 469174,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-700.h5"),
    ("0db74ee83f804a826a03dcfc4a3b426294504f0251b3c67847c451609b8bd842", 469184,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-1200.h5"),
    ("6560283bebe8696b34f609eef7907caaedb23775279ad4512915bce2a5de7ba4", 469184,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-2600.h5"),
    ("f601efa7c37f58b56256d83f00686d09e48db06621b4ec802cf973b89a878edb", 469184,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_ch4-3500.h5"),
    ("eee1cad7a4cc3c01bddf4149ff861ddea1fb90c9ee0c173d276f1463e9e9a560", 469175,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_n2o-190.h5"),
    ("34048c6aacd362769c592d829f81f6bf3b3634af6baec292f0d397a9eee1bcc0", 469175,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_n2o-270.h5"),
    ("ed6f69658fa5e4c82f53d7f03741c87e511673f08928c61f6864a348c01ce4f8", 469175,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_n2o-405.h5"),
    ("e670a3f7a5e7e59194b06fcab2d075d4ac855dc366e032a789f8b956c1215bb2", 469175,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_n2o-540.h5"),
    ("f80167edd631b12b55e98a3c652e5691f45cdafc69f34a8d414f853b317b36d2", 469173,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_cfc11-0.h5"),
    ("557b0e96e1c591b6906feeeae3768cb41f01dcac46002efde0e14ee4d9e948b4", 469203,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_cfc11-2000.h5"),
    ("d71cc1697a645320a0b027ce2d69e5643c2939c4f8e636b67b1cf75baf67377c", 469173,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_cfc12-0.h5"),
    ("9d8ea06d70a374a8d20a1812f30d4dc0159bdf4dfbeb202373778cf3b8eb4d1b", 469193,
     "$C3G_CKDMIP_ROOT/evaluation1/lw_fluxes/ckdmip_evaluation1_lw_fluxes_cfc12-550.h5")]
const C3G_G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const C3G_LBL_INPUT =
    ("e799eae4421afe12481533678963237198338b3979ec938c6e61c2759522d4bc", 451045,
     "$C3G_G4WORK/work/lw_lbl_fluxes/ckdmip_evaluation2_lw_fluxes_rel-415.h5",
     "lw_lbl_fluxes")
const C3G_GPOINTS_INPUT =
    ("c96e64927c4d0d706d35f376be59f17517dae6d6d7041d0791d164641a017a3e", 58404939,
     "$C3G_G4WORK/work/lw_gpoints/ecckd-1.2_lw_gpoints_climate_fsck-tol0.0161.h5",
     "lw_gpoints")
const C3G_V12_TEST_PINS = [
    ("f0d77b16b97612687818e85615a103adaa948627846c9819e40e7754ab0743ba",
     11792, "$C3G_SRC_ARTIFACT/test/optimize_lut_lw.sh"),
    ("44dcddf099d69becab1c5e6674d013d6c676685e0b8a4ae51e85a1dda33cfc69",
     6357, "$C3G_SRC_ARTIFACT/test/config.h"),
    ("34323fd3ecbcd64980b328eec463eedc692497ed3cdd685f2505ca4d1fdc5e2c",
     1369, "$C3G_SRC_ARTIFACT/test/check_configuration.h"),
    ("a5fe514dbcb656c99c11ca39d1c88eba953bda592ca35983de9c42da33dab810",
     92, "$C3G_SRC_ARTIFACT/test/version.h.in")]

# EVAL1 SELECTED-MODE CLOSURE (4578 recovery): the staging manifest
# must EQUAL (never superset) the union of eval1 basenames referenced
# by exactly the executed modes, derived at generation time from the
# pinned structured published-training manifest and cross-checked
# against the generation-derived deployed script blocks plus the
# G3 executor staged sets. Unselected branches (5gas/co2) must remain absent.
const C3G_EVAL1_SELECTED_MODES = ["relative-base", "relative-ch4",
                                  "relative-n2o", "relative-cfc"]
const C3G_EVAL1_UNSELECTED_TOKENS = ["_5gas-", "_co2-"]
const C3G_G3_EXECUTOR_EVAL1_DIRS = [
    "$C3G_G4WORK/g3-runs/4505/lw/data/evaluation1/lw_fluxes",
    "$C3G_G4WORK/g3-runs/4515/lw/data/evaluation1/lw_fluxes"]
const C3G_TRAINING_MANIFEST_FILE = joinpath(P2_PROJECT_ROOT,
    "validation", "results", "ecckd_published_training_manifest.json")
const C3G_TRAINING_MANIFEST_SHA =
    "bb421c92087449524d9bb8772c73ff87fcf5a42e1a435ad7ed3ced53b5f03715"
c3g_eval1_manifest() = sort([basename(t[3]) for t in C3G_DATA_INPUTS])
c3g_astext(x) = x isa String ? x : String(copy(Vector{UInt8}(x)))

function c3g_eval1_mode_names(text, mode)
    m = match(Regex("(?ms)^\\s*" * mode * "\\)\\s*(.*?);;"), text)
    m === nothing && return nothing
    names = String[]
    for ln in split(m.captures[1], '\n')
        startswith(strip(ln), "#") && continue
        for x in eachmatch(
            r"ckdmip_evaluation1_lw_fluxes_[A-Za-z0-9.\-]+\.h5", ln)
            push!(names, x.match)
        end
    end
    names
end

function c3g_manifest_mode_names(mdata, mode)
    for scr in get(mdata, "optimization_scripts", Any[])
        get(scr, "path", "") == "test/optimize_lut_lw.sh" || continue
        for m in get(scr, "modes", Any[])
            mode in get(m, "names", Any[]) || continue
            names = String[]
            for a in get(m, "assignments", Any[])
                for x in eachmatch(
                    r"ckdmip_evaluation1_lw_fluxes_[A-Za-z0-9.\-]+\.h5",
                    String(a))
                    push!(names, x.match)
                end
            end
            return names
        end
    end
    nothing
end

function c3g_eval1_closure_issues(mdata, derived_base, derived_down;
        manifest = c3g_eval1_manifest(),
        modes = C3G_EVAL1_SELECTED_MODES)
    iss = String[]
    length(manifest) == length(unique(manifest)) ||
        push!(iss, "eval1 manifest carries duplicate basenames")
    length(manifest) == 20 ||
        push!(iss, "eval1 manifest count $(length(manifest)) != 20")
    for n in manifest, tok in C3G_EVAL1_UNSELECTED_TOKENS
        occursin(tok, n) &&
            push!(iss, "eval1 manifest contains unselected-branch name: $n")
    end
    expected = sort(unique(manifest))
    namesfor(label, mode) =
        label == "structured-manifest" ?
            c3g_manifest_mode_names(mdata, mode) :
            c3g_eval1_mode_names(
                mode == "relative-base" ? derived_base : derived_down,
                mode)
    for label in ("structured-manifest", "deployed")
        u = Set{String}()
        for mode in modes
            names = namesfor(label, mode)
            if names === nothing
                push!(iss, "$label authority lacks mode block: $mode")
                continue
            end
            union!(u, names)
        end
        cl = sort(collect(u))
        for n in cl, tok in C3G_EVAL1_UNSELECTED_TOKENS
            occursin(tok, n) && push!(iss,
                "$label closure contains unselected-branch name: $n")
        end
        cl == expected || push!(iss,
            "$label selected-mode closure != pinned manifest " *
            "(closure $(length(cl)), manifest $(length(expected)))")
    end
    iss
end

function c3g_g3_executor_issues(; manifest = c3g_eval1_manifest(),
        dirs = C3G_G3_EXECUTOR_EVAL1_DIRS)
    iss = String[]
    for d in dirs
        isdir(d) ||
            (push!(iss, "G3 executor evidence dir missing: $d"); continue)
        sort(readdir(d)) == sort(unique(manifest)) ||
            push!(iss, "G3 executor staged set != pinned manifest: $d")
    end
    iss
end
# three pinned scoring masters (frozen design; verified on disk at
# design time)
const C3G_ANCHOR_LW_PATH = "$C3G_G4WORK/work/lw_ckd-definition/" *
    "ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc"
const C3G_ANCHOR_LW_BYTES = 872004
const C3G_PRIMARY_SW_PATH = "$C3G_G4WORK/work-v14/sw_ckd-definition/" *
    "ecckd-1.4_sw_ckd-definition_climate_rgb-tol0.047.nc"
const C3G_PRIMARY_SW_BYTES = 854508
const C3G_SECONDARY_SW_PATH = "/shared/home/greg/.julia/artifacts/" *
    "49ce668ce0861f9d5e8299d68af7138485eb5f19/" *
    "ecrad-131ac980517719b7a859e3ccc117919a1d888a20/data/" *
    "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc"
const C3G_SECONDARY_SW_BYTES = 851724
# (P2 design identifiers swept; C3G identity above is authoritative)
const P2_P1_CHECKER_REPO = "validation/gate4_p1_splice_checker.jl"
const P2_P1_CHECKER_SHA = "abebffc6146c93adc4d0ea9ed7d6d0e16cc62fd82805f34c63976418a8bb7e51"
const P2_CHECKER_REPO = "validation/gate4_p2_hard_objective_checker.jl"

# --- julia gate-instrument provenance (P1 pattern) ------------------------------
const P2_JULIA_BIN = "/shared/home/greg/.juliaup/bin/julia"
const P2_JULIA_VERSION_LINE = "julia version 1.12.6"
const P2_TEST_PROJECT = joinpath(P2_PROJECT_ROOT, "test", "Project.toml")
const P2_TEST_MANIFEST = joinpath(P2_PROJECT_ROOT, "test", "Manifest.toml")

# --- masters (THREE external LW + ONE SW; splice is NOT a master) ---------------
const P2_INIT_PATH = P1C_INIT_PATH
const P2_INIT_SHA = P1C_INIT_SHA
const P2_INIT_BYTES = P1C_INIT_BYTES

# --- prerequisites (fail-closed, sha-chained; SECTION B-2: the
# evidence C3-IB actually grounds on -- monitor prerequisite reminder;
# G1 additionally carries SEMANTIC value/pair gates below, not just the
# file hash) --------------------------------------------------------------
const C3G_LEDGERS = [
    (name = "G3RUN", case = "gate4_g3_run_ledger",
     status = "reviewed-complete",
     sha = "6fd7791834fe1ceb184afd4623c0f95ab311685bb849cfad0837b3c6ffd4aa4e",
     file = "gate4_g3_run_ledger.json"),
    (name = "G1", case = "gate4_g1_objective_ratio",
     status = "g1_objective_ratio_failed",
     sha = "5e65cbb184037195b0c60c8462547c4c695b2a63157c62e007c18240933bc4a7",
     file = "gate4_g1_objective_ratio.json"),
    (name = "C1", case = "gate4_c1_bounds_flag_completion_ledger",
     status = "c1_run_completed_verified",
     sha = "3c584417d4eba3459f58bbd182b395f7f8ed6c2cddb48e4fef54c057799d116f",
     file = "gate4_c1_bounds_flag_completion_ledger.json"),
    (name = "P1", case = "gate4_p1_completion_ledger",
     status = "p1_run_completed_verified",
     sha = "9605cf64deb5cb14f2f3403d73c976b00ddfa2c7fc50adba9cb24e1dd51f2403",
     file = "gate4_p1_completion_ledger.json"),
    (name = "P2", case = "gate4_p2_completion_ledger",
     status = "p2_run_completed_verified",
     sha = "41cc574b28b1c55a6f2235d2dc9914e42c4806bb4ff5aac23b98e1379fdc2b2d",
     file = "gate4_p2_completion_ledger.json"),
    (name = "C3IBF4578", case = "gate4_c3_ib_4578_failure_ledger",
     status = "c3ib_4578_failed_staging_manifest_gap",
     sha = "472088a799ab4bc53b54dedd405509835dbeef923d8bb39a84f89268d272bf84",
     file = "gate4_c3_ib_4578_failure_ledger.json")]
c3g_ledger_path(l) = joinpath(P2_PROJECT_ROOT, "validation", "results",
                              l.file)
# G1 SEMANTIC gates (value/pair provenance inside the pinned JSON):
const C3G_G1_VALUE_TOKEN = "22.824617997003102"
const C3G_G1_LW_SHA = "a3d93d3eb4e69894862fad682563d25a5636e7dbbcc59c197ecaa1cceb6f24b4"
const C3G_G1_SW_SHA = "8b54392eeddd303299881d6405dcf3de4d738667a3dfe605964a64863e2fbee4"
# fix 9: EXACT-FIELD semantic gates (whole-JSON occursin is
# decoy-satisfiable; note/detail fields must never satisfy value/sha
# gates). Field paths verified against the committed ledger:
# recovered.hard_objective.value, recovered.lw_sha256,
# recovered.sw_sha256, recovered.status.
function c3g_g1_semantic_issues(data)
    iss = String[]
    rec = get(data, "recovered", nothing)
    rec isa AbstractDict ||
        (push!(iss, "G1 ledger lacks a recovered object");
         return iss)
    ho = get(rec, "hard_objective", nothing)
    v = ho isa AbstractDict ? get(ho, "value", nothing) : nothing
    (v isa Real && @sprintf("%.17g", Float64(v)) == C3G_G1_VALUE_TOKEN) ||
        push!(iss, "recovered.hard_objective.value != committed token " *
              C3G_G1_VALUE_TOKEN * " (exact token discipline)")
    get(rec, "lw_sha256", nothing) == C3G_G1_LW_SHA ||
        push!(iss, "recovered.lw_sha256 != pinned recovered LW sha")
    get(rec, "sw_sha256", nothing) == C3G_G1_SW_SHA ||
        push!(iss, "recovered.sw_sha256 != pinned recovered SW sha")
    get(rec, "status", nothing) == "g1_objective_ratio_failed" ||
        push!(iss, "recovered.status != g1_objective_ratio_failed " *
              "(exact nested-status equality; presence alone is not " *
              "authority)")
    iss
end
# --- staged evaluator working set (package tree + chain + references) ------------
const P2_CHAIN_FILES = ["validation_results.jl",
    "ecrad_reference_manifest.jl", "write_ecrad_candidates.jl",
    "reduced_ecckd_accuracy.jl", "ecckd_published_model_accuracy.jl"]


p2_sha(path) = p2c_sha(path)
p2_try_sha(path) = isfile(path) ? p2_sha(path) : nothing

# package-tree manifest: Project.toml + src/** + ext/** + the chain
# files + the resolved REDUCED reference files, as repo-relative rows
# 4578 FAILURE-LEDGER SEMANTIC gates (exact-field; the classifier
# covers case/status/sha, these gate the raw terminal fields and the
# staging-gap classification inside the pinned JSON):
function c3g_4578_semantic_issues(data)
    iss = String[]
    job = get(data, "job", Dict{String, Any}())
    for (k, v) in (("state", "FAILED"), ("reason", "NonZeroExitCode"),
                   ("exit_code", "134:0"), ("run_time", "00:38:32"),
                   ("end_time", "2026-08-14T15:31:43"),
                   ("job_id", "4578"))
        get(job, k, nothing) == v ||
            push!(iss, "4578 ledger job.$k != $v")
    end
    de = get(data, "durable_evidence", Dict{String, Any}())
    get(get(de, "receipt", Dict{String, Any}()), "sha256", nothing) ==
        "f6f3a3618b5207c5e9a6645586cbe65a69038636fcfb2c406bd7dd953797c5c7" ||
        push!(iss, "4578 ledger receipt sha != pinned")
    get(get(de, "log", Dict{String, Any}()), "sha256", nothing) ==
        "698cab0bdf65d42ebcd29796e15ece5848d679a9cbf04b4f31d7f5e535f1fbba" ||
        push!(iss, "4578 ledger log sha != pinned")
    get(de, "first_missing_input", nothing) ==
        "ckdmip_evaluation1_lw_fluxes_present.h5" ||
        push!(iss, "4578 ledger first_missing_input mismatch")
    mo = get(data, "monitor_observations", Dict{String, Any}())
    get(mo, "classification", nothing) ==
        "staging_manifest_completeness_gap" ||
        push!(iss, "4578 ledger classification mismatch")
    get(mo, "selected_mode_eval1_closure", nothing) == 20 ||
        push!(iss, "4578 ledger closure count != 20")
    iss
end

function p2_pkg_manifest()
    entries = NamedTuple[]
    add(rel) = begin
        p = joinpath(P2_PROJECT_ROOT, rel)
        isfile(p) || error("pkg manifest source missing: $p")
        islink(p) && error("unexpected symlink in pkg set: $p")
        push!(entries, (rel = rel, sha = p2_sha(p), bytes = filesize(p),
                        exec = (uperm(p) & 0x01) != 0))
    end
    add("Project.toml")
    # REQUIRED for staged-form loadability (monitor hard-hold finding):
    # @artifact_str("ecrad_data") resolves (Julia)Artifacts.toml
    # relative to the package root at macro time during `using`
    add("Artifacts.toml")
    for (root, _, files) in walkdir(joinpath(P2_PROJECT_ROOT, "src"))
        for f in files
            add(relpath(joinpath(root, f), P2_PROJECT_ROOT))
        end
    end
    for (root, _, files) in walkdir(joinpath(P2_PROJECT_ROOT, "ext"))
        for f in files
            add(relpath(joinpath(root, f), P2_PROJECT_ROOT))
        end
    end
    for f in P2_CHAIN_FILES
        add(joinpath("validation", f))
    end
    for case in REDUCED_CASES
        add(String(case.path))
    end
    sort!(entries, by = e -> e.rel)
    entries
end

function p2_snapshot(path)
    isfile(path) || return (ok = false, reason = "missing", sha = nothing,
                            data = nothing)
    bytes = read(path)
    sha = bytes2hex(sha256(bytes))
    data = try
        JSON.parse(String(copy(bytes)))
    catch
        return (ok = false, reason = "unparseable", sha = sha,
                data = nothing)
    end
    data isa AbstractDict || return (ok = false, reason = "non-object",
                                     sha = sha, data = nothing)
    (ok = true, reason = "", sha = sha, data = data)
end


# --- sbatch generation (SECTION C: c3g_make_sbatch; fail-closed
# C3-IB renderer -- probe + sandwich + two-script discipline + full
# chains + 13 scores + identity + anchor + compare + post-run) --------

function c3g_make_sbatch(pkg)
    c3sha = p2_sha(joinpath(P2_PROJECT_ROOT, C3G_CHECKER_REPO))
    p2csha = p2_sha(joinpath(P2_PROJECT_ROOT, P2_CHECKER_REPO))
    p1csha = P2_P1_CHECKER_SHA
    gate_pins = join(vcat(
        ["$(p2_sha(joinpath(P2_PROJECT_ROOT, f)))  $(joinpath(P2_PROJECT_ROOT, f))"
         for f in ("validation/gate4_quota_guard.sh",
                   "validation/validation_results.jl")],
        ["$(p2_sha(abspath(@__FILE__)))  $P2_PROJECT_ROOT/validation/gate4_c3_ib_checkpoint.jl",
         "$p1csha  $P2_PROJECT_ROOT/$P2_P1_CHECKER_REPO",
         "$p2csha  $P2_PROJECT_ROOT/$P2_CHECKER_REPO",
         "$c3sha  $P2_PROJECT_ROOT/$C3G_CHECKER_REPO",
         "$C3G_DESIGN_SHA  $P2_PROJECT_ROOT/$C3G_DESIGN_REPO_PATH",
         "$C3G_TRAINING_MANIFEST_SHA  $C3G_TRAINING_MANIFEST_FILE",
         "$(p2_sha(P2_TEST_PROJECT))  $P2_TEST_PROJECT",
         "$(p2_sha(P2_TEST_MANIFEST))  $P2_TEST_MANIFEST"],
        ["$(l.sha)  $(c3g_ledger_path(l))" for l in C3G_LEDGERS]), "\n")
    master_rows = vcat(
        ["$sha $sz $path \$RUNROOT/data/evaluation1/lw_fluxes/$(basename(path))"
         for (sha, sz, path) in C3G_DATA_INPUTS],
        vcat([["$(C3G_LBL_INPUT[1]) $(C3G_LBL_INPUT[2]) $(C3G_LBL_INPUT[3]) \$RUNROOT/work-$arm/lw_lbl_fluxes/$(basename(C3G_LBL_INPUT[3]))",
               "$(C3G_GPOINTS_INPUT[1]) $(C3G_GPOINTS_INPUT[2]) $(C3G_GPOINTS_INPUT[3]) \$RUNROOT/work-$arm/lw_gpoints/$(basename(C3G_GPOINTS_INPUT[3]))",
               "$P2_INIT_SHA $P2_INIT_BYTES $P2_INIT_PATH \$RUNROOT/work-$arm/lw_raw-ckd-definition/$(basename(P2_INIT_PATH))"]
              for arm in ("probe", "c0a", "c3ib", "c0b")]...),
        ["$C3C_ANCHOR_LW_SHA $C3G_ANCHOR_LW_BYTES $C3G_ANCHOR_LW_PATH \$RUNROOT/source-inputs/anchor_lw.nc",
         "$C3C_PRIMARY_SW_SHA $C3G_PRIMARY_SW_BYTES $C3G_PRIMARY_SW_PATH \$RUNROOT/source-inputs/primary_sw.nc",
         "$C3C_SECONDARY_SW_SHA $C3G_SECONDARY_SW_BYTES $C3G_SECONDARY_SW_PATH \$RUNROOT/source-inputs/secondary_sw.nc"])
    stage_lines = join(master_rows, "\n")
    post_stage_lines = join([begin
        parts = split(r, ' ')
        "$(parts[1])  $(parts[4])"
    end for r in master_rows], "\n") *
        "\n$(p2_sha(P2_TEST_PROJECT))  \$RUNROOT/julia-env/Project.toml" *
        "\n$(p2_sha(P2_TEST_MANIFEST))  \$RUNROOT/julia-env/Manifest.toml"
    pkg_rows = join(["$(e.sha) $(e.bytes) $P2_PROJECT_ROOT/$(e.rel) \$RUNROOT/pkg/$(e.rel)"
                     for e in pkg], "\n")
    pkg_exec_rows = join(["$(e.exec ? 1 : 0) $(e.rel)" for e in pkg], "\n")
    pkg_census = length(pkg)
    post_pkg = join(["$(e.sha)  \$RUNROOT/pkg/$(e.rel)" for e in pkg], "\n")
    tree = p1_tree_manifest_c3()
    artifact_tree_lines = join(["$(e.sha)  $C3G_SRC_ARTIFACT/$(e.rel)"
                                for e in tree], "\n")
    copy_tree_lines = join(["$(e.sha)  $(e.rel)" for e in tree], "\n")
    execbit_lines = join(["$(e.exec ? 1 : 0) $(e.rel)" for e in tree], "\n")
    toolchain_checks = join([begin
        V = uppercase(replace(t, "+" => "X"))
        """
$(V)_P=\$(command -v $t) || { echo "REFUSED: $t missing" >&2; exit 65; }
[ "\$$(V)_P" = "$pth" ] || { echo "REFUSED: $t path \$$(V)_P != pinned $pth" >&2; exit 65; }
$(V)_FULL=\$($t --version); $(V)_L1=\${$(V)_FULL%%\$'\\n'*}
[ "\$$(V)_L1" = "$l1" ] || { echo "REFUSED: $t version line '\$$(V)_L1' != pinned '$l1'" >&2; exit 65; }"""
    end for (t, pth, l1) in C3G_TOOLCHAIN], "\n")
    template_pins = join(["$sha  \$RUNROOT/test-template/$(basename(path))"
                          for (sha, _, path) in C3G_V12_TEST_PINS], "\n")
    downstream_sha = bytes2hex(sha256(c3g_derive_downstream()))
    base_sha_1 = bytes2hex(sha256(c3g_derive_base(1)))
    base_sha_3000 = bytes2hex(sha256(c3g_derive_base(3000)))
    base_sha_9000 = bytes2hex(sha256(c3g_derive_base(9000)))
    banner(n) = "Optimizing coefficients with Adept LBFGS algorithm: " *
        "max iterations = $n, convergence criterion = 0.02"
    ev1_names = join(c3g_eval1_manifest(), "\n")
    """
#!/bin/bash
#SBATCH --job-name=g4-c3ib-lw-iteration-budget
#SBATCH --output=$C3G_LOG_DIR/g4-c3ib-lw-%j.log
#SBATCH --time=06:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=36
#SBATCH --mem=60G
#SBATCH --partition=cpu-large

# Gate-4 C3-IB: MODERN LW ITERATION-BUDGET CONTROL (DIAGNOSIS unit;
# PRIVATE outputs only). Generated by gate4_c3_ib_checkpoint.jl under
# the frozen design $C3G_DESIGN_SHA. Probe(1) + sandwich C0a(3000) ->
# C3IB(9000) -> C0b(3000); bounded mode ON everywhere; TWO-SCRIPT
# DISCIPLINE (base-only injected copy for relative-base; pinned
# child-status-hardened downstream script, scientifically unchanged); complete private LW chains
# per arm; EXACTLY 13 staged-evaluator scores (12 arm-panel + fixed
# current-G1 anchor); severability: an anchor miss refuses ONLY the
# adjacency label. ZERO canonical writes; RUNROOT preserved on success
# AND failure.
#
# $C3G_TERMINAL_CONTRACT
set -euo pipefail
if [ -z "\${SLURM_JOB_ID:-}" ]; then
    echo "REFUSED: head-node execution is not permitted; submit via sbatch." >&2
    exit 64
fi
case "\$SLURM_JOB_ID" in
    ''|*[!0-9]*) echo "REFUSED: SLURM_JOB_ID is not a positive integer" >&2; exit 64;;
esac

G4WORK=$C3G_G4WORK
RUNROOT="\$G4WORK/g4-diag/\${SLURM_JOB_ID}/lw-c3ib"
SRCDIR="\$RUNROOT/src/ecckd-modern-c3ib"
P1CHECKER="\$RUNROOT/tools/gate4_p1_splice_checker.jl"
P2CHECKER="\$RUNROOT/tools/gate4_p2_hard_objective_checker.jl"
C3CHECKER="\$RUNROOT/tools/gate4_c3_ib_checker.jl"

echo "=== C3IB stage 0a: gate-code identity (verify BEFORE sourcing) ==="
sha256sum -c <<'GATEPINS' || { echo "REFUSED: gate code/prerequisite changed since generation; regenerate" >&2; exit 75; }
$gate_pins
GATEPINS

echo "=== C3IB stage 0b: quota health (50 GiB soft-quota headroom) ==="
source $P2_PROJECT_ROOT/validation/gate4_quota_guard.sh
quota_health \$((50*1024*1024*1024)) || { echo "REFUSED: quota not healthy" >&2; exit 67; }

echo "=== C3IB stage 0c: stage-0 preflight pins (live reads lawful HERE ONLY) ==="
sha256sum -c <<'HASHES' || { echo "REFUSED: pinned master/input hash mismatch" >&2; exit 69; }
$(join(vcat(["$sha  $path" for (sha, _, path) in C3G_DATA_INPUTS],
            ["$(C3G_LBL_INPUT[1])  $(C3G_LBL_INPUT[3])",
             "$P2_INIT_SHA  $P2_INIT_PATH",
             "$(C3G_GPOINTS_INPUT[1])  $(C3G_GPOINTS_INPUT[3])",
             "$C3C_ANCHOR_LW_SHA  $C3G_ANCHOR_LW_PATH",
             "$C3C_PRIMARY_SW_SHA  $C3G_PRIMARY_SW_PATH",
             "$C3C_SECONDARY_SW_SHA  $C3G_SECONDARY_SW_PATH"],
            ["$sha  $path" for (sha, _, path) in C3G_V12_TEST_PINS],
            ["$C3G_MINIMIZER_H_SHA  $C3G_ADEPT/include/adept/Minimizer.h",
             "$C3G_LIBADEPT_SHA  $C3G_ADEPT/lib/libadept.so.0.0.0",
             "$C3G_ADEPT_SOURCE_H_SHA  $C3G_ADEPT/include/adept_source.h"]), "\n"))
HASHES
sha256sum -c <<'ARTTREE' >/dev/null || { echo "REFUSED: artifact tree content manifest mismatch" >&2; exit 69; }
$artifact_tree_lines
ARTTREE
[ "\$(find "$C3G_SRC_ARTIFACT" \\( -type f -o -type l \\) | wc -l)" = "$C3G_TREE_FILES" ] || { echo "REFUSED: artifact tree census != $C3G_TREE_FILES" >&2; exit 69; }
[ "\$(find "$C3G_SRC_ARTIFACT" -type l | wc -l)" = 0 ] || { echo "REFUSED: symlink in artifact tree" >&2; exit 69; }
[ "\$(find "$C3G_SRC_ARTIFACT" -type f -perm -u+x | wc -l)" = "$C3G_TREE_EXEC" ] || { echo "REFUSED: artifact exec census != $C3G_TREE_EXEC" >&2; exit 69; }
while read -r xf rel; do
    if [ "\$xf" = 1 ]; then [ -x "$C3G_SRC_ARTIFACT/\$rel" ] || { echo "REFUSED: artifact exec bit lost: \$rel" >&2; exit 69; }
    else [ ! -x "$C3G_SRC_ARTIFACT/\$rel" ] || { echo "REFUSED: artifact exec bit gained: \$rel" >&2; exit 69; }
    fi
done <<'EXECBITS'
$execbit_lines
EXECBITS
sha256sum -c <<'PKGPRE' >/dev/null || { echo "REFUSED: live package/evaluator/reference preflight mismatch" >&2; exit 69; }
$(join(["$(e.sha)  $P2_PROJECT_ROOT/$(e.rel)" for e in pkg], "\n"))
PKGPRE
[ "\$(find "$P2_PROJECT_ROOT/src" "$P2_PROJECT_ROOT/ext" -type f | wc -l)" = "$(count(e -> startswith(e.rel, "src/") || startswith(e.rel, "ext/"), pkg))" ] || { echo "REFUSED: live src/ext census != manifest (injected/missing file in the declared scope)" >&2; exit 69; }
$toolchain_checks
AM_FULL=\$(automake --version); AM_LINE1=\${AM_FULL%%\$'\\n'*}; AM_V=\${AM_LINE1##* }
LT_FULL=\$(libtoolize --version); LT_LINE1=\${LT_FULL%%\$'\\n'*}; LT_V=\${LT_LINE1##* }
[ "\$AM_V" = "$C3G_AUTOMAKE_VER" ] || { echo "REFUSED: automake \$AM_V != pinned" >&2; exit 65; }
[ "\$LT_V" = "$C3G_LIBTOOLIZE_VER" ] || { echo "REFUSED: libtoolize \$LT_V != pinned" >&2; exit 65; }
JULIA_BIN=$P2_JULIA_BIN
[ -x "\$JULIA_BIN" ] || { echo "REFUSED: pinned julia launcher missing" >&2; exit 65; }
JL_FULL=\$("\$JULIA_BIN" --version); JL_L1=\${JL_FULL%%\$'\\n'*}
[ "\$JL_L1" = "$P2_JULIA_VERSION_LINE" ] || { echo "REFUSED: julia version line '\$JL_L1' != pinned" >&2; exit 65; }

echo "=== C3IB stage 0d: experiment lock ==="
mkdir -p "\$G4WORK/locks"
exec 9>"\$G4WORK/locks/c3ib-lw.lock"
flock -n 9 || { echo "REFUSED: another C3IB-lw diagnosis job holds the lock" >&2; exit 73; }

echo "=== C3IB stage 1: copy live->RUNROOT with IMMEDIATE verification, then FREEZE ==="
[ ! -e "\$RUNROOT" ] || { echo "REFUSED: RUNROOT already exists: \$RUNROOT" >&2; exit 72; }
mkdir -p "\$RUNROOT/data/evaluation1/lw_fluxes" "\$RUNROOT/src" "\$RUNROOT/bin" "\$RUNROOT/tools" "\$RUNROOT/runtime" "\$RUNROOT/pkg" "\$RUNROOT/julia-env" "\$RUNROOT/source-inputs"
for arm in probe c0a c3ib c0b; do
    mkdir -p "\$RUNROOT/work-\$arm/lw_lbl_fluxes" "\$RUNROOT/work-\$arm/lw_raw-ckd-definition" "\$RUNROOT/work-\$arm/lw_ckd-definition" "\$RUNROOT/work-\$arm/lw_gpoints"
done
while read -r esha esz src dst; do
    cp -L -- "\$src" "\$dst" || { echo "REFUSED: staging copy failed: \$src" >&2; exit 76; }
    asz=\$(stat -Lc %s "\$dst"); [ "\$asz" = "\$esz" ] || { echo "REFUSED: staged size mismatch \$dst" >&2; exit 76; }
    echo "\$esha  \$dst" | sha256sum -c - >/dev/null || { echo "REFUSED: staged hash mismatch: \$dst" >&2; exit 76; }
done <<STAGE
$stage_lines
STAGE
echo "=== C3IB stage 1b: eval1 selected-mode closure census (pre-build gate) ==="
find "\$RUNROOT/data/evaluation1/lw_fluxes" -mindepth 1 -maxdepth 1 -printf '%f\\n' | LC_ALL=C sort > "\$RUNROOT/ev1-actual.txt"
cat <<'EV1NAMES' > "\$RUNROOT/ev1-expected.txt"
$ev1_names
EV1NAMES
cmp -s "\$RUNROOT/ev1-expected.txt" "\$RUNROOT/ev1-actual.txt" || { echo "REFUSED: staged eval1 census != generation-derived 20-name selected-mode closure (pre-build gate)" >&2; exit 76; }
[ "\$(wc -l < "\$RUNROOT/ev1-actual.txt")" = 20 ] || { echo "REFUSED: staged eval1 count != 20 (pre-build gate)" >&2; exit 76; }
while read -r esha esz src dst; do
    mkdir -p "\$(dirname "\$dst")"
    cp -L -- "\$src" "\$dst" || { echo "REFUSED: pkg staging copy failed: \$src" >&2; exit 76; }
    asz=\$(stat -Lc %s "\$dst"); [ "\$asz" = "\$esz" ] || { echo "REFUSED: staged pkg size mismatch \$dst" >&2; exit 76; }
    echo "\$esha  \$dst" | sha256sum -c - >/dev/null || { echo "REFUSED: staged pkg hash mismatch: \$dst" >&2; exit 76; }
done <<PKGSTAGE
$pkg_rows
PKGSTAGE
[ "\$(find "\$RUNROOT/pkg" -type f | wc -l)" = "$pkg_census" ] || { echo "REFUSED: staged pkg census != $pkg_census" >&2; exit 76; }
while read -r xf rel; do
    if [ "\$xf" = 1 ]; then [ -x "\$RUNROOT/pkg/\$rel" ] || { echo "REFUSED: staged pkg exec bit lost: \$rel" >&2; exit 76; }
    else [ ! -x "\$RUNROOT/pkg/\$rel" ] || { echo "REFUSED: staged pkg exec bit gained: \$rel" >&2; exit 76; }
    fi
done <<'PKGEXEC'
$pkg_exec_rows
PKGEXEC
cp -- "$P2_TEST_PROJECT" "\$RUNROOT/julia-env/Project.toml"
cp -- "$P2_TEST_MANIFEST" "\$RUNROOT/julia-env/Manifest.toml"
sha256sum -c <<JENVPINS >/dev/null || { echo "REFUSED: julia-env staged copy hash mismatch" >&2; exit 76; }
$(p2_sha(P2_TEST_PROJECT))  \$RUNROOT/julia-env/Project.toml
$(p2_sha(P2_TEST_MANIFEST))  \$RUNROOT/julia-env/Manifest.toml
JENVPINS
cp -- "$P2_PROJECT_ROOT/$P2_P1_CHECKER_REPO" "\$P1CHECKER"
cp -- "$P2_PROJECT_ROOT/$P2_CHECKER_REPO" "\$P2CHECKER"
cp -- "$P2_PROJECT_ROOT/$C3G_CHECKER_REPO" "\$C3CHECKER"
sha256sum -c <<CHECKPINS >/dev/null || { echo "REFUSED: staged checker hash mismatch" >&2; exit 76; }
$p1csha  \$P1CHECKER
$p2csha  \$P2CHECKER
$c3sha  \$C3CHECKER
CHECKPINS
# immutable SOURCE TEMPLATE staged PRE-freeze (monitor TOCTOU blocker:
# no live artifact read after the marker)
cp -rT "$C3G_SRC_ARTIFACT" "\$RUNROOT/source-template"
( cd "\$RUNROOT/source-template" && sha256sum -c <<'SRCTPL' >/dev/null ) || { echo "REFUSED: staged source-template manifest mismatch" >&2; exit 76; }
$copy_tree_lines
SRCTPL
[ "\$(find "\$RUNROOT/source-template" -type f | wc -l)" = "$C3G_TREE_FILES" ] || { echo "REFUSED: staged source-template census != $C3G_TREE_FILES" >&2; exit 76; }
[ "\$(find "\$RUNROOT/source-template" -type l | wc -l)" = 0 ] || { echo "REFUSED: symlink in staged source-template" >&2; exit 76; }
[ "\$(find "\$RUNROOT/source-template" -type f -perm -u+x | wc -l)" = "$C3G_TREE_EXEC" ] || { echo "REFUSED: source-template exec census != $C3G_TREE_EXEC" >&2; exit 76; }
while read -r xf rel; do
    if [ "\$xf" = 1 ]; then [ -x "\$RUNROOT/source-template/\$rel" ] || { echo "REFUSED: source-template exec bit lost: \$rel" >&2; exit 76; }
    else [ ! -x "\$RUNROOT/source-template/\$rel" ] || { echo "REFUSED: source-template exec bit gained: \$rel" >&2; exit 76; }
    fi
done <<'SRCEXEC'
$execbit_lines
SRCEXEC
chmod -R a-w "\$RUNROOT/source-template"
cp -L -- "$C3G_SHIM_SO" "\$RUNROOT/tools/h5open_before_traps.so"
echo "$C3G_SHIM_SO_SHA  \$RUNROOT/tools/h5open_before_traps.so" | sha256sum -c - >/dev/null || { echo "REFUSED: staged shim hash mismatch" >&2; exit 76; }
MANC="\$RUNROOT/source-inputs/anchor_lw.nc"
MSWP="\$RUNROOT/source-inputs/primary_sw.nc"
MSWS="\$RUNROOT/source-inputs/secondary_sw.nc"
JENV="\$RUNROOT/julia-env"
chmod -R a-w "\$RUNROOT/data" "\$RUNROOT/source-inputs" "\$RUNROOT/julia-env" "\$RUNROOT/pkg" "\$RUNROOT/tools" "\$RUNROOT/source-template"
WLIST=\$(find "\$RUNROOT/data" "\$RUNROOT/source-inputs" "\$RUNROOT/julia-env" "\$RUNROOT/pkg" "\$RUNROOT/tools" "\$RUNROOT/source-template" -writable) || { echo "REFUSED: writable scan failed" >&2; exit 76; }
[ -z "\$WLIST" ] || { echo "REFUSED: writable entries remain after the freeze" >&2; exit 76; }
echo "STAGE-1 FREEZE COMPLETE: all EXPLICIT evaluator/checker/scientific input PATHS resolve inside \$RUNROOT from here on (live-depot package-load metadata remains the recorded residual)"
export JULIA_LOAD_PATH="@:\$RUNROOT/pkg:@stdlib"
export NUMERICAL_RADIATION_VALIDATION_REFERENCE_DIR="\$RUNROOT/pkg/validation/reference"
export P2C_CHAIN_DIR="\$RUNROOT/pkg/validation"
export P2C_P1_CHECKER="\$P1CHECKER"
export C3C_P2_CHECKER="\$P2CHECKER"

echo "=== C3IB stage 2: writable source copy + tree identity + frozen test template ==="
mkdir -p "\$SRCDIR"
cp -rT "\$RUNROOT/source-template" "\$SRCDIR"
chmod -R u+w "\$SRCDIR"
( cd "\$SRCDIR" && sha256sum -c <<'COPYTREE' >/dev/null ) || { echo "REFUSED: copied tree manifest mismatch" >&2; exit 69; }
$copy_tree_lines
COPYTREE
while read -r xf rel; do
    if [ "\$xf" = 1 ]; then [ -x "\$SRCDIR/\$rel" ] || { echo "REFUSED: copy exec bit lost: \$rel" >&2; exit 69; }
    else [ ! -x "\$SRCDIR/\$rel" ] || { echo "REFUSED: copy exec bit gained: \$rel" >&2; exit 69; }
    fi
done <<'EXECBITS2'
$execbit_lines
EXECBITS2
[ "\$(find "\$SRCDIR" -type l | wc -l)" = 0 ] || { echo "REFUSED: symlink in copied tree" >&2; exit 69; }
cp -r "\$SRCDIR/test" "\$RUNROOT/test-template"
sha256sum -c <<TEMPLATEPINS >/dev/null || { echo "REFUSED: frozen test-template pin mismatch" >&2; exit 69; }
$template_pins
TEMPLATEPINS
chmod -R a-w "\$RUNROOT/test-template"
WLTT=\$(find "\$RUNROOT/test-template" -writable)
[ -z "\$WLTT" ] || { echo "REFUSED: writable entries remain in the frozen test-template" >&2; exit 69; }
# ONE hardened downstream template (child-status rewrite applied ONCE;
# generation-derived pin; cloned byte-identically to all arms)
cp "\$RUNROOT/test-template/optimize_lut_lw.sh" "\$RUNROOT/downstream_template.sh" || { echo "REFUSED: downstream template source copy failed" >&2; exit 69; }
chmod u+w "\$RUNROOT/downstream_template.sh"
sed -i 's|^[[:space:]]*test "\\\${PIPESTATUS\\[0\\]}" -eq 0[[:space:]]*\$|\\trc="\${PIPESTATUS[0]}"; if [ "\$rc" -ne 0 ]; then echo "OPTIMIZE_LUT CHILD FAILED rc=\$rc" >\\&2; exit "\$rc"; fi|' "\$RUNROOT/downstream_template.sh"
echo "$downstream_sha  \$RUNROOT/downstream_template.sh" | sha256sum -c - >/dev/null || { echo "REFUSED: hardened downstream template != generation-derived pin" >&2; exit 69; }
[ "\$(grep -cF 'max_iterations' "\$RUNROOT/downstream_template.sh" || true)" = 0 ] || { echo "REFUSED: downstream template carries max_iterations" >&2; exit 69; }
chmod a-w "\$RUNROOT/downstream_template.sh"

echo "=== C3IB stage 3: SINGLE pristine build (NO patch; ONE binary for ALL arms) ==="
cd "\$SRCDIR"
autoreconf -i
$C3G_CONFIGURE_ARGV
make -j"\$SLURM_CPUS_PER_TASK"
test -x "\$SRCDIR/src/ecckd/optimize_lut" || { echo "REFUSED: optimize_lut not built" >&2; exit 68; }
cp -- "\$SRCDIR/src/ecckd/optimize_lut" "\$RUNROOT/bin/optimize_lut_c3ib"
chmod a-w "\$RUNROOT/bin/optimize_lut_c3ib"
./config.status --config > "\$RUNROOT/config.status.config.txt"
[ "\$(cat "\$RUNROOT/config.status.config.txt")" = "$C3G_CONFIG_STATUS_EXPECT" ] || { echo "REFUSED: config.status --config != reviewed recipe" >&2; exit 68; }
BIN_SHA=\$(sha256sum "\$RUNROOT/bin/optimize_lut_c3ib" | cut -d' ' -f1)
echo "immutable binary content pin (verified before EVERY arm and post-run): \$BIN_SHA"

echo "=== C3IB stage 4: wrappers (staged shim; Netlib canonical, root-owned) + ldd ==="
# Netlib rows only: root-owned explicit runtime residual; the SHIM is
# consumed ONLY from its pre-freeze staged copy (no live shim read
# post-freeze)
sha256sum -c <<'RUNTIMEPINS' || { echo "REFUSED: runtime BLAS/LAPACK pin mismatch" >&2; exit 79; }
$C3G_NETLIB_BLAS_SHA  $C3G_NETLIB_BLAS
$C3G_NETLIB_LAPACK_SHA  $C3G_NETLIB_LAPACK
RUNTIMEPINS
SHIM="\$RUNROOT/tools/h5open_before_traps.so"
echo "$C3G_SHIM_SO_SHA  \$SHIM" | sha256sum -c - >/dev/null || { echo "REFUSED: staged shim missing/drifted (pre-freeze staging)" >&2; exit 79; }
command -v readelf >/dev/null || { echo "MISSING readelf" >&2; exit 65; }
RE_BLAS=\$(readelf -d "$C3G_NETLIB_BLAS")
RE_LAPACK=\$(readelf -d "$C3G_NETLIB_LAPACK")
[ "\$(grep -cF 'Library soname: [libblas.so.3]' <<<"\$RE_BLAS" || true)" = 1 ] || { echo "REFUSED: netlib BLAS SONAME != libblas.so.3" >&2; exit 79; }
[ "\$(grep -cF 'Library soname: [liblapack.so.3]' <<<"\$RE_LAPACK" || true)" = 1 ] || { echo "REFUSED: netlib LAPACK SONAME != liblapack.so.3" >&2; exit 79; }
for arm in probe c0a c3ib c0b; do
    W="\$RUNROOT/runtime/optimize_lut_wrap_\$arm"
    cat > "\$W" <<WRAP
#!/bin/bash
export LD_PRELOAD="$C3G_NETLIB_BLAS:$C3G_NETLIB_LAPACK:\$SHIM"
exec "\$RUNROOT/bin/optimize_lut_c3ib" "\\\$@"
WRAP
    chmod +x "\$W"; chmod a-w "\$W"
    [ "\$(grep -cxF "export LD_PRELOAD=\\"$C3G_NETLIB_BLAS:$C3G_NETLIB_LAPACK:\$SHIM\\"" "\$W" || true)" = 1 ] || { echo "REFUSED: wrapper preload line/order drifted (\$arm; staged shim required)" >&2; exit 79; }
done
WRAP_SHA=\$(sha256sum "\$RUNROOT/runtime/optimize_lut_wrap_probe" | cut -d' ' -f1)
for arm in probe c0a c3ib c0b; do
    echo "\$WRAP_SHA  \$RUNROOT/runtime/optimize_lut_wrap_\$arm" | sha256sum -c - >/dev/null || { echo "REFUSED: wrapper bytes differ across arms (\$arm)" >&2; exit 79; }
done
[ "\$(find "\$RUNROOT/runtime" -type f | wc -l)" = 4 ] || { echo "REFUSED: runtime dir census != 4 wrappers" >&2; exit 79; }
WLRT=\$(find "\$RUNROOT/runtime" -type f -writable)
[ -z "\$WLRT" ] || { echo "REFUSED: writable wrapper files remain" >&2; exit 79; }
LDD_OUT=\$(LD_PRELOAD="$C3G_NETLIB_BLAS:$C3G_NETLIB_LAPACK:\$SHIM" ldd "\$RUNROOT/bin/optimize_lut_c3ib")
echo "--- ldd (single binary) ---"
echo "\$LDD_OUT"
[ "\$(grep -cF "$C3G_NETLIB_BLAS" <<<"\$LDD_OUT" || true)" = 1 ] || { echo "REFUSED: exact BLAS preload row count != 1" >&2; exit 79; }
[ "\$(grep -cF "$C3G_NETLIB_LAPACK" <<<"\$LDD_OUT" || true)" = 1 ] || { echo "REFUSED: exact LAPACK preload row count != 1" >&2; exit 79; }
[ "\$(grep -cF 'liblapack.so.3 =>' <<<"\$LDD_OUT" || true)" = 0 ] || { echo "REFUSED: liblapack.so.3 alias row present" >&2; exit 79; }
[ "\$(grep -cF 'libblas.so.3 =>' <<<"\$LDD_OUT" || true)" = 0 ] || { echo "REFUSED: libblas.so.3 alias row present" >&2; exit 79; }
LN_B=\$(awk -v pat="$C3G_NETLIB_BLAS" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
LN_L=\$(awk -v pat="$C3G_NETLIB_LAPACK" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
LN_S=\$(awk -v pat="\$SHIM" 'index(\$0, pat) && !ln { ln = NR } END { if (ln) print ln }' <<<"\$LDD_OUT")
{ [ -n "\$LN_B" ] && [ -n "\$LN_L" ] && [ -n "\$LN_S" ] && [ "\$LN_B" -lt "\$LN_L" ] && [ "\$LN_L" -lt "\$LN_S" ]; } || { echo "REFUSED: preload row order is not BLAS<LAPACK<H5shim" >&2; exit 79; }

# SANDWICH RUN ORDER: probe -> c0a -> c3ib -> c0b; TWO-SCRIPT
# DISCIPLINE per arm; full downstream chain for the three sandwich arms
for arm in probe c0a c3ib c0b; do
    echo "=== C3IB stage 5-\$arm ==="
    echo "\$BIN_SHA  \$RUNROOT/bin/optimize_lut_c3ib" | sha256sum -c - >/dev/null || { echo "REFUSED: binary drift before arm \$arm" >&2; exit 71; }
    TC="\$RUNROOT/testcopy-\$arm"
    cp -r "\$RUNROOT/test-template" "\$TC"
    chmod -R u+w "\$TC"
    cd "\$TC"
    sed 's/@PACKAGE_VERSION@/1.2/g' version.h.in > version.h
    sed -i \\
      -e "s|^CKDMIP_DIR=.*|CKDMIP_DIR=/shared/home/greg/build/ckdmip-1.0|" \\
      -e "s|^CKDMIP_DATA_DIR=.*|CKDMIP_DATA_DIR=\$RUNROOT/data|" \\
      -e "s|^WORK_DIR=.*|WORK_DIR=\$RUNROOT/work-\$arm|" \\
      -e "s|^BINDIR=.*|BINDIR=\$RUNROOT/bin|" \\
      -e "s|^TRAINING_BOTH=no\$|TRAINING_BOTH=yes|" \\
      -e "s|^OPTIMIZE_LUT=.*|OPTIMIZE_LUT=\$RUNROOT/runtime/optimize_lut_wrap_\$arm|" \\
      config.h
    for kv in "CKDMIP_DIR=/shared/home/greg/build/ckdmip-1.0" "CKDMIP_DATA_DIR=\$RUNROOT/data" "WORK_DIR=\$RUNROOT/work-\$arm" "BINDIR=\$RUNROOT/bin" "TRAINING_BOTH=yes" "OPTIMIZE_LUT=\$RUNROOT/runtime/optimize_lut_wrap_\$arm"; do
        [ "\$(grep -cxF "\$kv" config.h || true)" = 1 ] || { echo "REFUSED: config override not exactly once (\$arm): \$kv" >&2; exit 68; }
    done
    # TWO-SCRIPT DISCIPLINE from the ONE hardened template (fix 3):
    # both scripts descend from the same child-status-hardened bytes;
    # ONLY the base copy receives the max_iterations injection
    cp "\$RUNROOT/downstream_template.sh" optimize_lut_lw.sh
    chmod u+w optimize_lut_lw.sh
    echo "$downstream_sha  \$TC/optimize_lut_lw.sh" | sha256sum -c - >/dev/null || { echo "REFUSED: \$arm downstream clone != hardened pin" >&2; exit 68; }
    cp optimize_lut_lw.sh optimize_lut_lw_base.sh
    chmod u+w optimize_lut_lw_base.sh
    case "\$arm" in
        probe) NIT=1; BPIN=$base_sha_1;;
        c3ib) NIT=9000; BPIN=$base_sha_9000;;
        *) NIT=3000; BPIN=$base_sha_3000;;
    esac
    sed -i 's|model_id=lw_\${APPLICATION}_\${BANDSTRUCT}-tol\${TOL} \\\\\$|&\\n\\t    max_iterations='"\$NIT"' \\\\|' optimize_lut_lw_base.sh
    [ "\$(grep -cF "max_iterations=\$NIT \\\\" optimize_lut_lw_base.sh || true)" = 1 ] || { echo "REFUSED: \$arm base injection not exactly once" >&2; exit 68; }
    [ "\$(grep -cF 'max_iterations' optimize_lut_lw_base.sh || true)" = 1 ] || { echo "REFUSED: \$arm base carries an extra max_iterations token" >&2; exit 68; }
    echo "\$BPIN  \$TC/optimize_lut_lw_base.sh" | sha256sum -c - >/dev/null || { echo "REFUSED: \$arm hardened base script != generation-derived byte pin (sole-factor proof)" >&2; exit 68; }
    [ "\$(grep -cF 'max_iterations' optimize_lut_lw.sh || true)" = 0 ] || { echo "REFUSED: \$arm downstream script carries a max_iterations override (LEAK)" >&2; exit 68; }
    [ "\$(grep -cF 'bounded_minimization' optimize_lut_lw_base.sh || true)" = 0 ] || { echo "REFUSED: \$arm bounded override present" >&2; exit 68; }
    OMPSET="OMP_NUM_THREADS=\$SLURM_CPUS_PER_TASK OMP_DYNAMIC=FALSE"
    echo "arm \$arm: \$OMPSET NIT=\$NIT" | tee "\$RUNROOT/\$arm-base.log"
    OMP_NUM_THREADS="\$SLURM_CPUS_PER_TASK" OMP_DYNAMIC=FALSE \\
        APPLICATION=climate BAND_STRUCTURE=fsck TOLERANCE=0.0161 \\
        bash optimize_lut_lw_base.sh relative-base |& tee -a "\$RUNROOT/\$arm-base.log"
    RL="\$RUNROOT/\$arm-base.log"
    [ "\$(grep -cF "max iterations = \$NIT, convergence criterion = 0.02" "\$RL" || true)" = 1 ] || { echo "REFUSED: \$arm Adept banner (max iterations = \$NIT) not exactly once" >&2; exit 71; }
    for N in 1 3000 9000; do
        [ "\$N" = "\$NIT" ] && continue
        [ "\$(grep -cF "max iterations = \$N, convergence criterion = 0.02" "\$RL" || true)" = 0 ] || { echo "REFUSED: \$arm base log shows forbidden budget banner (\$N)" >&2; exit 71; }
    done
    [ "\$(grep -cF 'max iterations = ' "\$RL" || true)" = 1 ] || { echo "REFUSED: \$arm base log total budget banners != 1" >&2; exit 71; }
    [ "\$(grep -cF 'Minimization is bounded' "\$RL" || true)" = 1 ] || { echo "REFUSED: \$arm did not log bounded mode" >&2; exit 71; }
    [ "\$(grep -cF 'Minimization is unbounded' "\$RL" || true)" = 0 ] || { echo "REFUSED: \$arm logged unbounded mode" >&2; exit 71; }
    [ "\$(grep -cF 'Convergence status: ' "\$RL" || true)" = 1 ] || { echo "REFUSED: \$arm base convergence-status not exactly once" >&2; exit 71; }
    ST=\$(grep -F 'Convergence status: ' "\$RL"); RUN_STATUS="\${ST#*Convergence status: }"
    [ -n "\$RUN_STATUS" ] || { echo "REFUSED: \$arm status capture empty" >&2; exit 71; }
    printf '%s' "\$RUN_STATUS" > "\$RUNROOT/\$arm-base-status.txt"
    # LAST anchored iteration line; exact grammar; printed tokens only
    IT_LINE=\$(grep -E '^Iteration [0-9]+: cost function = ' "\$RL" | tail -n 1)
    [ -n "\$IT_LINE" ] || { echo "REFUSED: \$arm no iteration line" >&2; exit 71; }
    ITRE='^Iteration [0-9]+: cost function = ([^,]+), gradient norm = (.+)\$'
    if [[ "\$IT_LINE" =~ \$ITRE ]]; then
        printf 'status=%s\\ncost_token=%s\\ngradient_token=%s\\n' "\$RUN_STATUS" "\${BASH_REMATCH[1]}" "\${BASH_REMATCH[2]}" > "\$RUNROOT/\$arm-base-upstream.txt"
    else
        echo "REFUSED: \$arm terminal iteration line grammar mismatch" >&2; exit 71
    fi
    R2="\$RUNROOT/work-\$arm/lw_raw-ckd-definition/$P2_RAW2_BASENAME_C3"
    test -s "\$R2" || { echo "MISSING \$arm raw2 output" >&2; exit 71; }
    if [ "\$arm" != probe ]; then
        # pinned child-status-hardened downstream copy (scientifically
        # unchanged invocation); per-mode sha re-gates below
        for mode in relative-ch4 relative-n2o relative-cfc; do
            echo "$downstream_sha  \$TC/optimize_lut_lw.sh" | sha256sum -c - >/dev/null || { echo "REFUSED: \$arm downstream script drifted before \$mode" >&2; exit 68; }
            OMP_NUM_THREADS="\$SLURM_CPUS_PER_TASK" OMP_DYNAMIC=FALSE \\
                APPLICATION=climate BAND_STRUCTURE=fsck TOLERANCE=0.0161 \\
                bash optimize_lut_lw.sh "\$mode" |& tee "\$RUNROOT/\$arm-\$mode.log"
            ML="\$RUNROOT/\$arm-\$mode.log"
            [ "\$(grep -cF 'Convergence status: ' "\$ML" || true)" = 1 ] || { echo "REFUSED: \$arm \$mode convergence-status not exactly once" >&2; exit 71; }
            [ "\$(grep -cF 'max iterations = 3000, convergence criterion = 0.02' "\$ML" || true)" = 1 ] || { echo "REFUSED: \$arm \$mode default-3000 banner not exactly once" >&2; exit 71; }
            [ "\$(grep -cF 'max iterations = ' "\$ML" || true)" = 1 ] || { echo "REFUSED: \$arm \$mode carries an extra budget banner" >&2; exit 71; }
            [ "\$(grep -cF 'max iterations = 9000' "\$ML" || true)" = 0 ] || { echo "REFUSED: \$arm \$mode shows 9000 budget (RUNTIME LEAK)" >&2; exit 71; }
            [ "\$(grep -cF 'max iterations = 1,' "\$ML" || true)" = 0 ] || { echo "REFUSED: \$arm \$mode shows probe budget (RUNTIME LEAK)" >&2; exit 71; }
            MST=\$(grep -F 'Convergence status: ' "\$ML"); MRS="\${MST#*Convergence status: }"
            [ -n "\$MRS" ] || { echo "REFUSED: \$arm \$mode status empty" >&2; exit 71; }
            printf '%s' "\$MRS" > "\$RUNROOT/\$arm-\$mode-status.txt"
            MIT=\$(grep -E '^Iteration [0-9]+: cost function = ' "\$ML" | tail -n 1)
            ITRE='^Iteration [0-9]+: cost function = ([^,]+), gradient norm = (.+)\$'
            if [ -n "\$MIT" ] && [[ "\$MIT" =~ \$ITRE ]]; then
                printf 'status=%s\\ncost_token=%s\\ngradient_token=%s\\n' "\$MRS" "\${BASH_REMATCH[1]}" "\${BASH_REMATCH[2]}" > "\$RUNROOT/\$arm-\$mode-upstream.txt"
            else
                echo "REFUSED: \$arm \$mode iteration-line grammar mismatch" >&2; exit 71
            fi
        done
        FINAL="\$RUNROOT/work-\$arm/lw_ckd-definition/$P2_FINAL_BASENAME_C3"
        test -s "\$FINAL" || { echo "MISSING \$arm final LW definition" >&2; exit 71; }
    fi
done

echo "=== C3IB stage 6: structural scans + upstream census + EXACTLY 13 scores + anchor + identity + compare ==="
for arm in probe c0a c3ib c0b; do
    R2="\$RUNROOT/work-\$arm/lw_raw-ckd-definition/$P2_RAW2_BASENAME_C3"
    "\$JULIA_BIN" --project="\$JENV" "\$C3CHECKER" scan "\$R2" "\$RUNROOT/work-\$arm/lw_raw-ckd-definition/$(basename(P2_INIT_PATH))" "$P2_INIT_SHA" "\$arm-raw2" |& tee -a "\$RUNROOT/c3ib-scans.log" || { echo "REFUSED: \$arm raw2 structural scan failed" >&2; exit 74; }
done
for arm in c0a c3ib c0b; do
    FINAL="\$RUNROOT/work-\$arm/lw_ckd-definition/$P2_FINAL_BASENAME_C3"
    "\$JULIA_BIN" --project="\$JENV" "\$C3CHECKER" scan "\$FINAL" "\$MANC" "$C3C_ANCHOR_LW_SHA" "\$arm-final" |& tee -a "\$RUNROOT/c3ib-scans.log" || { echo "REFUSED: \$arm final structural scan failed" >&2; exit 74; }
done
"\$JULIA_BIN" --project="\$JENV" "\$C3CHECKER" upstream "\$RUNROOT" |& tee "\$RUNROOT/c3ib-upstream.log" || { echo "REFUSED: upstream 3x4 census/equality/partition gates failed" >&2; exit 74; }
score() {
    "\$JULIA_BIN" --project="\$JENV" "\$C3CHECKER" score "\$1" "\$2" "\$RUNROOT/score-\$3.txt" "\$4" "\$5" "\$6" "\$7" "\$8" |& tee -a "\$RUNROOT/c3ib-scores.log" || { echo "REFUSED: score \$3 failed" >&2; exit 74; }
}
for arm in c0a c3ib c0b; do
    R2="\$RUNROOT/work-\$arm/lw_raw-ckd-definition/$P2_RAW2_BASENAME_C3"
    FINAL="\$RUNROOT/work-\$arm/lw_ckd-definition/$P2_FINAL_BASENAME_C3"
    R2SHA=\$(sha256sum "\$R2" | cut -d' ' -f1)
    FSHA=\$(sha256sum "\$FINAL" | cut -d' ' -f1)
    score "\$R2" "\$MSWP" "\$arm-raw2-primary" "\$arm" raw2 primary "\$R2SHA" "$C3C_PRIMARY_SW_SHA"
    score "\$R2" "\$MSWS" "\$arm-raw2-secondary" "\$arm" raw2 secondary "\$R2SHA" "$C3C_SECONDARY_SW_SHA"
    score "\$FINAL" "\$MSWP" "\$arm-final-primary" "\$arm" final primary "\$FSHA" "$C3C_PRIMARY_SW_SHA"
    score "\$FINAL" "\$MSWS" "\$arm-final-secondary" "\$arm" final secondary "\$FSHA" "$C3C_SECONDARY_SW_SHA"
done
score "\$MANC" "\$MSWP" "anchor-anchor-primary" anchor anchor primary "$C3C_ANCHOR_LW_SHA" "$C3C_PRIMARY_SW_SHA"
[ "\$(grep -cF 'C3C PASS: score' "\$RUNROOT/c3ib-scores.log" || true)" = 13 ] || { echo "REFUSED: successful score invocations != 13" >&2; exit 74; }
"\$JULIA_BIN" --project="\$JENV" "\$C3CHECKER" anchor "\$RUNROOT/score-anchor-anchor-primary.txt" "\$RUNROOT/anchor-marker.txt" |& tee "\$RUNROOT/c3ib-anchor.log" || { echo "REFUSED: anchor determination structurally failed" >&2; exit 74; }
for ep in raw2 final; do
    if [ "\$ep" = raw2 ]; then A="\$RUNROOT/work-c0a/lw_raw-ckd-definition/$P2_RAW2_BASENAME_C3"; B="\$RUNROOT/work-c0b/lw_raw-ckd-definition/$P2_RAW2_BASENAME_C3"
    else A="\$RUNROOT/work-c0a/lw_ckd-definition/$P2_FINAL_BASENAME_C3"; B="\$RUNROOT/work-c0b/lw_ckd-definition/$P2_FINAL_BASENAME_C3"; fi
    "\$JULIA_BIN" --project="\$JENV" "\$C3CHECKER" identity "\$A" "\$B" "controls-\$ep" |& tee -a "\$RUNROOT/c3ib-identity.log" || { echo "REFUSED: control logical identity failed (\$ep)" >&2; exit 74; }
done
"\$JULIA_BIN" --project="\$JENV" "\$C3CHECKER" compare "\$RUNROOT" |& tee "\$RUNROOT/c3ib-compare.log" || { echo "REFUSED: compare finalizer gates failed" >&2; exit 74; }

echo "=== C3IB stage 7: post-run no-mutation reverification ==="
sha256sum -c <<POSTSTAGE >/dev/null || { echo "REFUSED: staged input drifted during the runs (target-defining input mutation)" >&2; exit 78; }
$post_stage_lines
POSTSTAGE
sha256sum -c <<POSTPKG >/dev/null || { echo "REFUSED: staged package tree/chain/reference drifted during the runs" >&2; exit 78; }
$post_pkg
POSTPKG
[ "\$(find "\$RUNROOT/pkg" -type f | wc -l)" = "$pkg_census" ] || { echo "REFUSED: post-run staged pkg census != $pkg_census" >&2; exit 78; }
sha256sum -c <<CHECKPOST >/dev/null || { echo "REFUSED: staged checker drifted during the runs" >&2; exit 78; }
$p1csha  \$P1CHECKER
$p2csha  \$P2CHECKER
$c3sha  \$C3CHECKER
CHECKPOST
echo "\$BIN_SHA  \$RUNROOT/bin/optimize_lut_c3ib" | sha256sum -c - >/dev/null || { echo "REFUSED: binary drift post-run" >&2; exit 78; }
echo "$C3G_SHIM_SO_SHA  \$SHIM" | sha256sum -c - >/dev/null || { echo "REFUSED: staged shim drifted during the runs" >&2; exit 78; }
sha256sum -c <<TEMPLATEPOST >/dev/null || { echo "REFUSED: frozen test-template drifted during the runs" >&2; exit 78; }
$template_pins
TEMPLATEPOST
( cd "\$RUNROOT/source-template" && sha256sum -c <<'SRCTPLPOST' >/dev/null ) || { echo "REFUSED: source-template drifted during the runs" >&2; exit 78; }
$copy_tree_lines
SRCTPLPOST
[ "\$(find "\$RUNROOT/source-template" -type f | wc -l)" = "$C3G_TREE_FILES" ] || { echo "REFUSED: post-run source-template census != $C3G_TREE_FILES" >&2; exit 78; }
[ "\$(find "\$RUNROOT/source-template" -type l | wc -l)" = 0 ] || { echo "REFUSED: post-run symlink in source-template" >&2; exit 78; }
[ "\$(find "\$RUNROOT/source-template" -type f -perm -u+x | wc -l)" = "$C3G_TREE_EXEC" ] || { echo "REFUSED: post-run source-template exec census != $C3G_TREE_EXEC" >&2; exit 78; }
while read -r xf rel; do
    if [ "\$xf" = 1 ]; then [ -x "\$RUNROOT/source-template/\$rel" ] || { echo "REFUSED: post-run source-template exec bit lost: \$rel" >&2; exit 78; }
    else [ ! -x "\$RUNROOT/source-template/\$rel" ] || { echo "REFUSED: post-run source-template exec bit gained: \$rel" >&2; exit 78; }
    fi
done <<'SRCEXECPOST'
$execbit_lines
SRCEXECPOST
echo "$downstream_sha  \$RUNROOT/downstream_template.sh" | sha256sum -c - >/dev/null || { echo "REFUSED: hardened downstream template drifted during the runs" >&2; exit 78; }
for arm in probe c0a c3ib c0b; do
    echo "\$WRAP_SHA  \$RUNROOT/runtime/optimize_lut_wrap_\$arm" | sha256sum -c - >/dev/null || { echo "REFUSED: wrapper drifted during the runs (\$arm)" >&2; exit 78; }
done
[ "\$(find "\$RUNROOT/runtime" -type f | wc -l)" = 4 ] || { echo "REFUSED: post-run runtime census != 4" >&2; exit 78; }
echo "staged inputs re-verified post-run -- ZERO canonical writes by design"
for f in "\$RUNROOT"/score-*.txt; do sha256sum "\$f"; done
sha256sum "\$RUNROOT/c3ib-scores.log" "\$RUNROOT/c3ib-anchor.log" "\$RUNROOT/c3ib-identity.log" "\$RUNROOT/c3ib-compare.log"
echo "RUNROOT preserved for diagnosis/forensics: \$RUNROOT (no cleanup by design)"
echo "=== C3IB done \$(date -u +%FT%TZ) ==="
"""
end

# generation-derived CHILD-STATUS-HARDENED downstream template
# (fix 3: ONE hardened template, pinned by derived sha, cloned
# byte-identically to every arm; the raw-template pin caused a
# guaranteed refusal and is withdrawn)
const C3G_CHILD_LINE = "\trc=\"\${PIPESTATUS[0]}\"; if [ \"\$rc\" -ne 0 ]; then echo \"OPTIMIZE_LUT CHILD FAILED rc=\$rc\" >&2; exit \"\$rc\"; fi"
function c3g_derive_downstream()
    txt = read(joinpath(C3G_SRC_ARTIFACT, "test/optimize_lut_lw.sh"),
               String)
    lines = [String(l) for l in split(txt, '\n'; keepempty = true)]
    hits = [i for (i, l) in enumerate(lines)
            if occursin(r"^\s*test \"\$\{PIPESTATUS\[0\]\}\" -eq 0\s*$", l)]
    length(hits) == 1 ||
        error("PIPESTATUS anchor not exactly once ($(length(hits)))")
    lines[hits[1]] = C3G_CHILD_LINE
    join(lines, '\n')
end

# generation-derived HARDENED BASE variants (fix 1: sole-factor
# injection proven by BYTE PIN, not grep inference): hardened
# downstream text + the anchored max_iterations injection, per budget
const C3G_MODEL_ID_ANCHOR = "model_id=lw_\${APPLICATION}_\${BANDSTRUCT}-tol\${TOL} \\"
function c3g_derive_base(nit)
    txt = c3g_derive_downstream()
    lines = [String(l) for l in split(txt, '\n'; keepempty = true)]
    hits = [i for (i, l) in enumerate(lines)
            if endswith(l, C3G_MODEL_ID_ANCHOR)]
    length(hits) == 1 ||
        error("model_id anchor not exactly once ($(length(hits)))")
    join(vcat(lines[1:hits[1]], ["\t    max_iterations=$nit \\"],
              lines[(hits[1] + 1):end]), '\n')
end

# tree manifest for the C3 run-side artifact (C1-form walker)
function p1_tree_manifest_c3()
    entries = NamedTuple[]
    for (root, _, files) in walkdir(C3G_SRC_ARTIFACT)
        for f in files
            pth = joinpath(root, f)
            islink(pth) && error("unexpected symlink in artifact: $pth")
            push!(entries, (rel = relpath(pth, C3G_SRC_ARTIFACT),
                            sha = p2_sha(pth), bytes = filesize(pth),
                            exec = (uperm(pth) & 0x01) != 0))
        end
    end
    sort!(entries, by = e -> e.rel)
    entries
end
const P2_RAW2_BASENAME_C3 = "ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
const P2_FINAL_BASENAME_C3 = "ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc"

# --- text gates -----------------------------------------------------------------

function c3g_bash_syntax_ok(text)
    try
        pth = joinpath(mktempdir(), "c3ib_syntax_check.sbatch")
        write(pth, text)
        success(pipeline(`bash -n $pth`, stdout = devnull,
                         stderr = devnull))
    catch
        false
    end
end

# EVAL1 RENDERED-COVERAGE gate (item-4 binding): every manifest entry
# must appear in ALL FOUR rendered contexts -- live preflight hash
# row, stage source+destination row, expected-name census block, and
# post-run reverify row -- each exactly once.
function c3g_eval1_coverage_issues(text)
    iss = String[]
    m = match(r"(?s)cat <<'EV1NAMES' > \"\$RUNROOT/ev1-expected\.txt\"\n(.*?)\nEV1NAMES",
              text)
    if m === nothing
        push!(iss, "eval1 expected-name census block missing")
    else
        census = [String(l) for l in split(m.captures[1], '\n')]
        census == c3g_eval1_manifest() ||
            push!(iss, "eval1 census block != pinned manifest")
    end
    for (sha, sz, path) in C3G_DATA_INPUTS
        n = basename(path)
        for (what, row) in (
            ("live preflight", "$sha  $path"),
            ("stage copy",
             "$sha $sz $path \$RUNROOT/data/evaluation1/lw_fluxes/$n"),
            ("post-run reverify",
             "$sha  \$RUNROOT/data/evaluation1/lw_fluxes/$n"))
            c = length(collect(eachmatch(Regex("\\Q" * row * "\\E"),
                                         text)))
            c == 1 || push!(iss, "eval1 coverage: $what row for $n " *
                                 "expected exactly 1, got $c")
        end
    end
    iss
end

function c3g_text_gate_issues(text, downstream_sha, base_pins)
    iss = String[]
    req = [
        "REFUSED: head-node execution is not permitted",
        "RUNROOT=\"\$G4WORK/g4-diag/\${SLURM_JOB_ID}/lw-c3ib\"",
        C3G_DESIGN_SHA, P2_P1_CHECKER_SHA,
        C3C_ANCHOR_LW_SHA, C3C_PRIMARY_SW_SHA, C3C_SECONDARY_SW_SHA,
        P2_INIT_SHA,
        downstream_sha, base_pins[1], base_pins[2], base_pins[3],
        "quota_health \$((50*1024*1024*1024))",
        "locks/c3ib-lw.lock",
        "JULIA_BIN=$P2_JULIA_BIN", P2_JULIA_VERSION_LINE,
        "STAGE-1 FREEZE COMPLETE",
        "export JULIA_LOAD_PATH=\"@:\$RUNROOT/pkg:@stdlib\"",
        "export NUMERICAL_RADIATION_VALIDATION_REFERENCE_DIR=\"\$RUNROOT/pkg/validation/reference\"",
        "export P2C_CHAIN_DIR=\"\$RUNROOT/pkg/validation\"",
        "export P2C_P1_CHECKER=\"\$P1CHECKER\"",
        "export C3C_P2_CHECKER=\"\$P2CHECKER\"",
        "cp -rT \"\$RUNROOT/source-template\" \"\$SRCDIR\"",
        "REFUSED: staged source-template manifest mismatch",
        "REFUSED: source-template exec census != $C3G_TREE_EXEC",
        "REFUSED: hardened downstream template != generation-derived pin",
        "REFUSED: \$arm hardened base script != generation-derived byte pin (sole-factor proof)",
        "REFUSED: \$arm base carries an extra max_iterations token",
        "REFUSED: \$arm base log total budget banners != 1",
        "REFUSED: \$arm \$mode default-3000 banner not exactly once",
        "REFUSED: \$arm \$mode shows 9000 budget (RUNTIME LEAK)",
        "REFUSED: \$arm \$mode convergence-status not exactly once",
        "REFUSED: \$arm downstream script drifted before \$mode",
        "REFUSED: config override not exactly once",
        "REFUSED: wrapper bytes differ across arms",
        "REFUSED: runtime dir census != 4 wrappers",
        "REFUSED: preload row order is not BLAS<LAPACK<H5shim",
        "REFUSED: upstream 3x4 census/equality/partition gates failed",
        "REFUSED: successful score invocations != 13",
        "REFUSED: anchor determination structurally failed",
        "REFUSED: control logical identity failed",
        "REFUSED: compare finalizer gates failed",
        "REFUSED: source-template drifted during the runs",
        "REFUSED: hardened downstream template drifted during the runs",
        "REFUSED: wrapper drifted during the runs",
        "GATEPINS", "HASHES", "ARTTREE", "EXECBITS", "PKGPRE",
        "PKGSTAGE", "PKGEXEC", "JENVPINS", "CHECKPINS", "SRCTPL",
        "SRCEXEC", "COPYTREE", "EXECBITS2", "TEMPLATEPINS",
        "RUNTIMEPINS", "POSTSTAGE", "POSTPKG", "CHECKPOST",
        "SRCTPLPOST", "SRCEXECPOST",
        "#SBATCH --time=06:00:00", "#SBATCH --partition=cpu-large",
        "$(p2_sha(joinpath(P2_PROJECT_ROOT, P2_CHECKER_REPO)))",
        "$(p2_sha(joinpath(P2_PROJECT_ROOT, C3G_CHECKER_REPO)))",
        C3G_LEDGERS[1].sha, C3G_LEDGERS[2].sha, C3G_LEDGERS[3].sha,
        C3G_LEDGERS[4].sha, C3G_LEDGERS[5].sha,
        C3G_LEDGERS[6].sha * "  " * c3g_ledger_path(C3G_LEDGERS[6]),
        C3G_TRAINING_MANIFEST_SHA * "  " * C3G_TRAINING_MANIFEST_FILE,
        "artifact tree census != $C3G_TREE_FILES",
        "artifact exec census != $C3G_TREE_EXEC",
        "symlink in artifact tree",
        "source-template census != $C3G_TREE_FILES",
        "symlink in staged source-template",
        "post-run source-template exec census != $C3G_TREE_EXEC",
        "ZERO canonical writes",
        "RUNROOT preserved for diagnosis/forensics",
        "# " * C3G_TERMINAL_CONTRACT,
        "REFUSED: staged eval1 census != generation-derived 20-name selected-mode closure (pre-build gate)",
        "REFUSED: staged eval1 count != 20 (pre-build gate)",
        "find \"\$RUNROOT/data/evaluation1/lw_fluxes\" -mindepth 1 " *
        "-maxdepth 1 -printf '%f\\n' | LC_ALL=C sort"]
    append!(req, ["\$RUNROOT/data/evaluation1/lw_fluxes/" * n
                  for n in c3g_eval1_manifest()])
    for r in req
        occursin(r, text) || push!(iss, "required text missing: $r")
    end
    for (pat, n, what) in (
        (Regex("\\Qfor arm in probe c0a c3ib c0b; do\\E"), 6,
         "four-arm loops (mkdir, wrappers, wrapper-sha, runs, raw2-scans, post-run wrapper reverify)"),
        (Regex("\\Q\"\$JULIA_BIN\" --project=\"\$JENV\" \"\$C3CHECKER\"\\E"), 7,
         "checker CLI call sites (raw2-scan, final-scan, upstream, score fn, anchor, identity, compare)"),
        (Regex("\\Q\" scan \"\\E"), 2, "scan call sites (raw2 + final loops = 7 scans at runtime)"),
        (Regex("\\Q\" upstream \"\\E"), 1, "upstream finalizer call site (12-record census at runtime)"),
        (Regex("\\Qbash optimize_lut_lw_base.sh relative-base\\E"), 1,
         "base invocation exactly once (inside the arm loop)"),
        (Regex("\\Qbash optimize_lut_lw.sh \"\$mode\"\\E"), 1,
         "downstream invocation exactly once (inside the mode loop)"),
        (Regex("\\QC3C PASS: score\\E"), 1, "13-invocation log gate"),
        (Regex("\\Q# " * C3G_TERMINAL_CONTRACT * "\\E"), 1,
         "terminal policy line"),
        (Regex("\\QEV1NAMES\\E"), 2,
         "eval1 expected-name heredoc delimiters"),
        (Regex("\\Q" * C3G_TRAINING_MANIFEST_SHA * "  " *
               C3G_TRAINING_MANIFEST_FILE * "\\E"), 1,
         "training-manifest stage-0 pin"),
        (Regex("\\Q" * C3G_LEDGERS[6].sha * "  " *
               c3g_ledger_path(C3G_LEDGERS[6]) * "\\E"), 1,
         "4578 failure-ledger stage-0 pin"))
        m = length(collect(eachmatch(pat, text)))
        m == n || push!(iss, "$what expected exactly $n, got $m")
    end
    # ACTIVE-LINE bounded_minimization assignment refusal (any value)
    for m in eachmatch(r"(?m)^[^#\n]*bounded_minimization=", text)
        push!(iss, "active bounded_minimization assignment present: " *
              first(m.match, 60))
    end
    for bad in ("--project=test", "cd $P2_PROJECT_ROOT &&",
                "GATE4_X1_CAPTURE_PATH",
                "CANON_FINAL", "mv -n", ".g3.publish.",
                "recovered acceptance was", "acceptance-equivalent",
                "ecckd-1.0_sw_", "ckdmip_evaluation1_lw_fluxes_5gas",
                "ckdmip_evaluation1_lw_fluxes_co2-", "g4-diag/4578",
                "ls \"\$RUNROOT/data/evaluation1/lw_fluxes\"")
        occursin(bad, text) && push!(iss, "forbidden text present: $bad")
    end
    marks = length(collect(eachmatch(r"STAGE-1 FREEZE COMPLETE", text)))
    if marks == 1
        post = split(text, "STAGE-1 FREEZE COMPLETE"; limit = 2)[2]
        # documented live residuals ALLOWED post-freeze: Adept/netCDF
        # stack + toolchain (build inputs) and root-owned Netlib;
        # everything scientific/code-input is banned
        postbans = vcat([pth for (_, _, pth) in C3G_DATA_INPUTS],
            [C3G_LBL_INPUT[3], C3G_GPOINTS_INPUT[3],
             C3G_SRC_ARTIFACT, C3G_SHIM_SO, P2_INIT_PATH,
             C3G_ANCHOR_LW_PATH, C3G_PRIMARY_SW_PATH,
             C3G_SECONDARY_SW_PATH, P2_TEST_PROJECT, P2_TEST_MANIFEST,
             P2_PROJECT_ROOT, "/.julia/artifacts/"])
        for bad in postbans
            occursin(bad, post) &&
                push!(iss, "post-freeze live-path reference: " *
                      first(bad, 60))
        end
    else
        push!(iss, "freeze marker count $marks != 1 (segment scan ambiguous)")
    end
    for m in eachmatch(r"\|\s*head\b", text)
        push!(iss, "early-closing head pipeline present: $(m.match)")
    end
    for m in eachmatch(r"(?m)^[^#\n]*> *\"?\$G4WORK/(?!g4-diag|locks/c3ib-lw\.lock)", text)
        push!(iss, "redirect toward shared G4WORK area: $(m.match)")
    end
    append!(iss, c3g_eval1_coverage_issues(text))
    iss
end

# live source-scope census (restored: lost in the Section-D splice)
function p2_source_census_issues(pkg; base = P2_PROJECT_ROOT)
    iss = String[]
    want = count(e -> startswith(e.rel, "src/") ||
                 startswith(e.rel, "ext/"), pkg)
    got = 0
    for root in ("src", "ext")
        d = joinpath(base, root)
        isdir(d) || (push!(iss, "scoped live root missing: $d"); continue)
        for (_, _, files) in walkdir(d)
            got += length(files)
        end
    end
    got == want ||
        push!(iss, "live src/ext census $got != manifest $want " *
              "(injected/missing file in the declared scope)")
    iss
end

# PRODUCTION identifier scanner (F-E): parse + walk Symbols only
function c3g_identifier_hits(src, forbidden)
    hits = String[]
    ex = Meta.parseall(src)
    walk(e) = e isa Symbol ?
        (String(e) in forbidden && push!(hits, String(e)); nothing) :
        e isa Expr ? (foreach(walk, e.args); nothing) : nothing
    walk(ex)
    sort(unique(hits))
end

# SHARED downstream-leak predicate (monitor E-item 6): the ONE
# production predicate gating the derived downstream template at
# generation AND driven by the negative fixture
c3g_downstream_leak_issues(text) =
    occursin("max_iterations", text) ?
        ["downstream text carries a max_iterations override (LEAK)"] :
        String[]

# --- C3 staged-form behavioral probe (replaces the P2 probe: the
# rendered staged set + the pinned anchor LW + primary recovered SW
# through the ACTUAL C3/P2 evaluator path, expecting the bit-exact
# committed anchor value; negative = Artifacts.toml omitted) ------------
function c3g_staged_form_probe(pkg; omit_artifacts = false)
    tmp = mktempdir()
    pkgdir = joinpath(tmp, "pkg")
    for e in pkg
        (omit_artifacts && e.rel == "Artifacts.toml") && continue
        dst = joinpath(pkgdir, e.rel)
        mkpath(dirname(dst))
        cp(joinpath(P2_PROJECT_ROOT, e.rel), dst)
    end
    envdir = joinpath(tmp, "julia-env")
    mkpath(envdir)
    cp(P2_TEST_PROJECT, joinpath(envdir, "Project.toml"))
    cp(P2_TEST_MANIFEST, joinpath(envdir, "Manifest.toml"))
    tools = joinpath(tmp, "tools")
    mkpath(tools)
    for f in (P2_P1_CHECKER_REPO, P2_CHECKER_REPO, C3G_CHECKER_REPO)
        cp(joinpath(P2_PROJECT_ROOT, f), joinpath(tools, basename(f)))
    end
    si = joinpath(tmp, "source-inputs")
    mkpath(si)
    cp(C3G_ANCHOR_LW_PATH, joinpath(si, "anchor_lw.nc"))
    cp(C3G_PRIMARY_SW_PATH, joinpath(si, "primary_sw.nc"))
    outp = joinpath(tmp, "score-anchor-anchor-primary.txt")
    cmd = addenv(`$P2_JULIA_BIN --project=$envdir $(joinpath(tools, "gate4_c3_ib_checker.jl")) score $(joinpath(si, "anchor_lw.nc")) $(joinpath(si, "primary_sw.nc")) $outp anchor anchor primary $C3C_ANCHOR_LW_SHA $C3C_PRIMARY_SW_SHA`,
        "JULIA_LOAD_PATH" => "@:$pkgdir:@stdlib",
        "NUMERICAL_RADIATION_VALIDATION_REFERENCE_DIR" =>
            joinpath(pkgdir, "validation", "reference"),
        "P2C_CHAIN_DIR" => joinpath(pkgdir, "validation"),
        "P2C_P1_CHECKER" => joinpath(tools, "gate4_p1_splice_checker.jl"),
        "C3C_P2_CHECKER" => joinpath(tools,
                                     "gate4_p2_hard_objective_checker.jl"))
    ok = try
        success(pipeline(cmd; stdout = devnull, stderr = devnull))
    catch
        false
    end
    ok || return false
    rec = read(outp, String)
    occursin("objective_token=" * C3C_ANCHOR_TOKEN, rec) &&
        occursin("objective_bits=" * c3c_anchor_bits_hex(), rec) &&
        isempty(c3c_record_issues(rec, "anchor", "anchor", "primary"))
end

# --- fixtures -------------------------------------------------------------------

function c3g_fixtures(pkg, text, downstream_sha, base_pins)
    t = Dict{String, Bool}()
    fx = mktempdir()
    tg(x) = c3g_text_gate_issues(x, downstream_sha, base_pins)

    # derivations: deterministic + distinct + leak negatives
    t["downstream_derivation_deterministic"] =
        bytes2hex(sha256(c3g_derive_downstream())) == downstream_sha
    t["base_variants_distinct_and_deterministic"] = begin
        p1_, p3, p9 = bytes2hex(sha256(c3g_derive_base(1))),
            bytes2hex(sha256(c3g_derive_base(3000))),
            bytes2hex(sha256(c3g_derive_base(9000)))
        (p1_, p3, p9) == (base_pins[1], base_pins[2], base_pins[3]) &&
            length(unique([p1_, p3, p9])) == 3
    end
    t["downstream_has_zero_max_iterations"] =
        !occursin("max_iterations", c3g_derive_downstream())
    t["base_variant_has_exactly_one_injection"] = begin
        b = c3g_derive_base(9000)
        count(==("\t    max_iterations=9000 \\"),
              split(b, '\n')) == 1
    end
    t["downstream_child_hardening_applied"] =
        occursin("OPTIMIZE_LUT CHILD FAILED", c3g_derive_downstream())

    # ledger classifier + G1 semantics
    cls(l) = c3g_classify_ledger(l)
    t["ledgers_all_green"] = all(cls(l).ok for l in C3G_LEDGERS)
    g1 = JSON.parse(read(c3g_ledger_path(C3G_LEDGERS[2]), String))
    t["g1_semantic_exact_fields_pass"] =
        isempty(c3g_g1_semantic_issues(g1))
    t["g1_semantic_moved_value_refuses"] = begin
        d = deepcopy(g1)
        d["recovered"]["hard_objective"]["value"] = 1.0
        d["note"] = "22.824617997003102 decoy in prose"
        !isempty(c3g_g1_semantic_issues(d))
    end
    t["g1_semantic_decoy_sha_refuses"] = begin
        d = deepcopy(g1)
        d["recovered"]["lw_sha256"] = "0"^64
        d["detail_note"] = C3G_G1_LW_SHA
        !isempty(c3g_g1_semantic_issues(d))
    end
    t["g1_semantic_wrong_nested_status_refuses"] = begin
        d = deepcopy(g1)
        d["recovered"]["status"] = "g1_objective_ratio_passed"
        !isempty(c3g_g1_semantic_issues(d))
    end

    # record schema: a REAL record derived in-process at generation
    # (the anchor pair through the actual evaluator; bit-exact value)
    riss, rres = c3c_score_record(C3G_ANCHOR_LW_PATH,
                                  C3G_PRIMARY_SW_PATH, "anchor",
                                  "anchor", "primary",
                                  C3C_ANCHOR_LW_SHA, C3C_PRIMARY_SW_SHA)
    t["real_score_record_derives"] = isempty(riss) && rres !== nothing
    rec = rres === nothing ? "" : rres.record
    t["real_anchor_record_schema_pass"] =
        isempty(c3c_record_issues(rec, "anchor", "anchor", "primary"))
    rows = [l for l in split(rec, '\n') if startswith(l, "row ")]
    t["row_permutation_refuses"] = begin
        r2 = replace(rec, rows[1] * "\n" * rows[2] =>
                     rows[2] * "\n" * rows[1])
        any(occursin("sequence", i) for i in
            c3c_record_issues(r2, "anchor", "anchor", "primary"))
    end
    t["malformed_bits_refuse"] = begin
        r2 = replace(rec, r"(?m)^objective_bits=[0-9a-f]{16}$" =>
                     "objective_bits=zz36d31a2a40d244")
        !isempty(c3c_record_issues(r2, "anchor", "anchor", "primary"))
    end
    t["token_bits_mismatch_refuses"] = begin
        r2 = replace(rec, "objective_token=" * C3C_ANCHOR_TOKEN =>
                     "objective_token=22.824617997003105")
        any(occursin("token<->bits mismatch", i) for i in
            c3c_record_issues(r2, "anchor", "anchor", "primary"))
    end
    t["alternate_token_same_bits_refuses"] =
        !c3c_tok_bits_ok("22.8246179970031020", c3c_anchor_bits_hex())
    t["missing_summary_refuses"] = begin
        r2 = replace(rec, r"(?m)^objective_case=.*\n" => "")
        !isempty(c3c_record_issues(r2, "anchor", "anchor", "primary"))
    end
    t["duplicate_header_refuses"] = begin
        r2 = rec * "objective_token=" * C3C_ANCHOR_TOKEN * "\n"
        !isempty(c3c_record_issues(r2, "anchor", "anchor", "primary"))
    end

    # anchor determination + severability language (production compare)
    t["anchor_hit_derived"] = begin
        iss, hit = c3c_anchor_determination(rec)
        isempty(iss) && hit === true
    end
    t["anchor_miss_derived_on_tamper"] = begin
        r2 = replace(rec,
            "objective_bits=" * c3c_anchor_bits_hex() =>
            "objective_bits=" * string(C3C_ANCHOR_BITS_U64 + 1,
                                       base = 16, pad = 16))
        iss, hit = c3c_anchor_determination(r2)
        isempty(iss) && hit === false
    end
    t["compare_missing_records_fail_closed"] = begin
        iss, _ = c3c_compare(Dict("anchor-anchor-primary" => rec), "HIT")
        !isempty(iss)
    end
    t["marker_invalid_text_refuses"] = begin
        iss, _ = c3c_compare(Dict("anchor-anchor-primary" => rec),
                             "MAYBE")
        any(occursin("marker text invalid", i) for i in iss)
    end

    # upstream census machinery
    t["upstream_good_parses"] = begin
        iss, r = c3c_upstream_parse(
            "status=Converged\ncost_token=1.5\ngradient_token=2.5\n")
        isempty(iss) && r.status == "Converged"
    end
    t["upstream_duplicate_key_refuses"] =
        !isempty(c3c_upstream_parse(
            "status=A\nstatus=B\ncost_token=1\ngradient_token=2\n")[1])
    t["upstream_extra_line_refuses"] =
        !isempty(c3c_upstream_parse(
            "status=A\ncost_token=1\ngradient_token=2\nnote=x\n")[1])
    t["upstream_3x4_census_and_partitions"] = begin
        recs = Dict{String, Any}()
        for arm in C3C_ARMS, pass in C3C_PASSES
            c = arm == "c3ib" ? "9.5" : "10.25"
            recs["$arm-$pass"] = (status = "Maximum iterations reached",
                                  cost = c, gradient = "0.5")
        end
        iss, out = c3c_upstream_compare(recs)
        isempty(iss) &&
            any(occursin("BRANCH=NEGATIVE", o) for o in out) &&
            count(occursin("UPSTREAM DELTA", o) for o in out) == 8
    end
    t["upstream_status_inequality_refuses"] = begin
        recs = Dict{String, Any}()
        for arm in C3C_ARMS, pass in C3C_PASSES
            st = (arm == "c0b" && pass == "base") ? "Converged" :
                "Maximum iterations reached"
            recs["$arm-$pass"] = (status = st, cost = "1.0",
                                  gradient = "1.0")
        end
        iss, _ = c3c_upstream_compare(recs)
        any(occursin("terminal-status inequality", i) for i in iss)
    end
    t["upstream_census_short_refuses"] = begin
        iss, _ = c3c_upstream_compare(Dict{String, Any}(
            "c0a-base" => (status = "Converged", cost = "1",
                           gradient = "1")))
        any(occursin("census", i) for i in iss)
    end

    # staged-form probes (C3 form; bit-exact anchor path)
    t["staged_form_anchor_bitexact"] = c3g_staged_form_probe(pkg)
    t["staged_form_omitted_artifacts_refuses"] =
        !c3g_staged_form_probe(pkg; omit_artifacts = true)

    # source census + pkg manifest
    t["source_census_clean_and_injected"] = begin
        tmpb = mktempdir()
        for e in pkg
            (startswith(e.rel, "src/") || startswith(e.rel, "ext/")) ||
                continue
            dst = joinpath(tmpb, e.rel)
            mkpath(dirname(dst))
            write(dst, "x")
        end
        clean = isempty(p2_source_census_issues(pkg; base = tmpb))
        write(joinpath(tmpb, "src", "injected.jl"), "#")
        clean && !isempty(p2_source_census_issues(pkg; base = tmpb))
    end
    t["pkg_manifest_complete"] =
        any(e -> e.rel == "Artifacts.toml", pkg) &&
        any(e -> e.rel == "Project.toml", pkg) &&
        all(any(e -> e.rel == joinpath("validation", f), pkg)
            for f in P2_CHAIN_FILES)
    t["tree_manifest_119_24"] = begin
        tr = p1_tree_manifest_c3()
        length(tr) == C3G_TREE_FILES &&
            count(e -> e.exec, tr) == C3G_TREE_EXEC
    end

    # text gates (mutations per class)
    t["text_good_accepted"] = isempty(tg(text))
    t["text_design_pin_drift_refuses"] =
        !isempty(tg(replace(text, C3G_DESIGN_SHA => "0"^64)))
    t["text_anchor_pin_drift_refuses"] =
        !isempty(tg(replace(text, C3C_ANCHOR_LW_SHA => "0"^64)))
    t["text_base_pin_drift_refuses"] =
        !isempty(tg(replace(text, base_pins[3] => "0"^64)))
    t["text_downstream_pin_drift_refuses"] =
        !isempty(tg(replace(text, downstream_sha => "0"^64)))
    t["text_loop_role_removed_refuses"] = !isempty(tg(replace(text,
        "for arm in probe c0a c3ib c0b; do\n    W=" => "for arm in probe; do\n    W=", count = 1)))
    t["text_loop_role_duplicated_refuses"] = !isempty(tg(text *
        "\nfor arm in probe c0a c3ib c0b; do :; done\n"))
    t["text_bounded_override_refuses"] = !isempty(tg(text *
        "\nfoo bounded_minimization=1 bar\n"))
    t["text_postfreeze_live_artifact_refuses"] = !isempty(tg(text *
        "\ncat $C3G_SRC_ARTIFACT/src/ecckd/solve_adept.cpp\n"))
    t["text_postfreeze_live_master_refuses"] = !isempty(tg(text *
        "\ncat $C3G_ANCHOR_LW_PATH\n"))
    t["text_postfreeze_live_repo_refuses"] = !isempty(tg(text *
        "\ncat $P2_PROJECT_ROOT/validation/x.jl\n"))
    t["text_13_gate_removed_refuses"] = !isempty(tg(replace(text,
        "REFUSED: successful score invocations != 13" => "note")))
    t["text_leak_gate_removed_refuses"] = !isempty(tg(replace(text,
        "REFUSED: \$arm \$mode shows 9000 budget (RUNTIME LEAK)" =>
        "note")))
    t["text_duplicate_marker_refuses"] =
        !isempty(tg(text * "\necho STAGE-1 FREEZE COMPLETE\n"))
    t["text_head_pipeline_refuses"] =
        !isempty(tg(text * "\nfoo | head -1\n"))
    t["bash_syntax_good"] = c3g_bash_syntax_ok(text)
    t["bash_syntax_broken_refuses"] =
        !c3g_bash_syntax_ok(text * "\nif true; then\n")

    # E-HOLD class 1: severability through PRODUCTION c3c_compare with
    # 13 schema-valid synthetics built from the real anchor template
    function mk13(anchor_rec; miss = false)
        recs = Dict{String, String}()
        for arm in C3C_ARMS, ep in C3C_ENDPOINTS, pn in C3C_PANELS
            r = anchor_rec
            r = replace(r, "c3ib_arm=anchor" => "c3ib_arm=$arm")
            r = replace(r, "c3ib_endpoint=anchor" => "c3ib_endpoint=$ep")
            r = replace(r, "c3ib_panel=primary" => "c3ib_panel=$pn")
            r = replace(r, "arm_label=anchor-anchor-primary" =>
                        "arm_label=$arm-$ep-$pn")
            r = replace(r, "state=" * p2c_state("anchor-anchor-primary") =>
                        "state=" * p2c_state("$arm-$ep-$pn"))
            if pn == "secondary"
                r = replace(r, "sw_sha=" * C3C_PRIMARY_SW_SHA =>
                            "sw_sha=" * C3C_SECONDARY_SW_SHA)
            end
            recs["$arm-$ep-$pn"] = r
        end
        recs["anchor-anchor-primary"] = anchor_rec
        recs
    end
    # self-consistent record surgery: rescale value+normalized of the
    # ARGMAX row (factor f) keeping token<->bits and the exact
    # normalized == value/threshold relation; objective fields updated
    function c3fx_rescale_argmax(r, f)
        oc = match(r"(?m)^objective_case=(\S+)$", r).captures[1]
        om = match(r"(?m)^objective_metric=(\S+)$", r).captures[1]
        for line in split(r, '\n')
            startswith(line, "row ") || continue
            fld = split(line[5:end], "|")
            (fld[1] == oc && fld[2] == om) || continue
            v = parse(Float64, String(fld[3])) * f
            th = parse(Float64, String(fld[5]))
            nv = v / th
            newrow = "row " * join([String(fld[1]), String(fld[2]),
                p2c_tok(v), p2c_bits(v), String(fld[5]), String(fld[6]),
                p2c_tok(nv), p2c_bits(nv)], "|")
            r = replace(r, line => newrow)
            r = replace(r, r"(?m)^objective_token=\S+$" =>
                        "objective_token=" * p2c_tok(nv))
            r = replace(r, r"(?m)^objective_bits=[0-9a-f]{16}$" =>
                        "objective_bits=" * p2c_bits(nv))
            r = replace(r, r"(?m)^objective_metric_value_bits=[0-9a-f]{16}$" =>
                        "objective_metric_value_bits=" * p2c_bits(v))
            break
        end
        r
    end
    # rescale ALL 24 rows self-consistently and recompute the argmax
    # header (monitor blocker: single-row rescale breaks argmax
    # correspondence and never exercises placement language)
    function c3fx_rescale_all(r, f)
        rows0 = [l for l in split(r, '\n') if startswith(l, "row ")]
        best = (-Inf, "", "", "", "")
        for line in rows0
            fld = split(line[5:end], "|")
            v = parse(Float64, String(fld[3])) * f
            th = parse(Float64, String(fld[5]))
            nv = v / th
            newrow = "row " * join([String(fld[1]), String(fld[2]),
                p2c_tok(v), p2c_bits(v), String(fld[5]), String(fld[6]),
                p2c_tok(nv), p2c_bits(nv)], "|")
            r = replace(r, line => newrow)
            if nv > best[1]
                best = (nv, String(fld[1]), String(fld[2]),
                        p2c_bits(v), String(fld[6]))
            end
        end
        r = replace(r, r"(?m)^objective_token=\S+$" =>
                    "objective_token=" * p2c_tok(best[1]))
        r = replace(r, r"(?m)^objective_bits=[0-9a-f]{16}$" =>
                    "objective_bits=" * p2c_bits(best[1]))
        r = replace(r, r"(?m)^objective_case=\S+$" =>
                    "objective_case=" * best[2])
        r = replace(r, r"(?m)^objective_metric=\S+$" =>
                    "objective_metric=" * best[3])
        r = replace(r, r"(?m)^objective_metric_value_bits=[0-9a-f]{16}$" =>
                    "objective_metric_value_bits=" * best[4])
        r = replace(r, r"(?m)^objective_threshold_bits=[0-9a-f]{16}$" =>
                    "objective_threshold_bits=" * best[5])
        r
    end
    good13 = mk13(rec)
    t["severability_hit_licenses_phrase_once"] = begin
        iss, out = c3c_compare(good13, "HIT")
        isempty(iss) &&
            count(occursin("current-G1-adjacent", o) for o in out) == 1 &&
            count(occursin("UPSTREAM", o) for o in out) == 0 &&
            count(occursin("C3IB DELTA", o) for o in out) == 4 &&
            count(occursin("G1-BOUND PLACEMENT", o) for o in out) == 6 &&
            any(occursin("C3IB CEILING", o) for o in out)
    end
    t["severability_marker_mismatch_refuses"] = begin
        iss, _ = c3c_compare(good13, "MISS")
        any(occursin("cross-check mismatch", i) for i in iss)
    end
    t["severability_miss_schema_valid_suppresses_phrase"] = begin
        miss13 = mk13(rec)
        miss13["anchor-anchor-primary"] = c3fx_rescale_argmax(rec, 2.0)
        iss, out = c3c_compare(miss13, "MISS")
        isempty(iss) &&
            count(occursin("current-G1-adjacent", o) for o in out) == 0 &&
            count(occursin("C3IB DELTA", o) for o in out) == 4 &&
            count(occursin("G1-BOUND PLACEMENT", o) for o in out) == 6 &&
            any(occursin("C3IB CEILING", o) for o in out) &&
            any(occursin("ADJACENCY: REFUSED", o) for o in out)
    end
    t["placement_sub105_private_not_acceptance"] = begin
        low = c3fx_rescale_all(rec, 1.0e-3)
        low13 = mk13(low)
        low13["anchor-anchor-primary"] = rec
        iss, out = c3c_compare(low13, "HIT")
        au = [o for o in out if occursin("AT-OR-UNDER", o)]
        isempty(iss) && length(au) == 6 &&
            all(occursin("PRIVATE PLACEMENT", o) &&
                occursin("NOT recovered acceptance", o) for o in au) &&
            !any(occursin("PASSED", o) for o in out)
    end
    t["cross_panel_lw_mismatch_refuses"] = begin
        r2 = copy(good13)
        r2["c0a-raw2-secondary"] = replace(r2["c0a-raw2-secondary"],
            r"(?m)^lw_sha=[0-9a-f]{64}$" => "lw_sha=" * "1"^64)
        iss, _ = c3c_compare(r2, "HIT")
        any(occursin("cross-panel LW provenance mismatch", i)
            for i in iss)
    end
    t["wrong_anchor_lw_mapping_refuses"] = begin
        r2 = replace(rec, "lw_sha=" * C3C_ANCHOR_LW_SHA =>
                     "lw_sha=" * "2"^64)
        any(occursin("pinned anchor LW sha", i) for i in
            c3c_record_issues(r2, "anchor", "anchor", "primary"))
    end
    t["normalized_ratio_violation_refuses"] = begin
        rows0 = [l for l in split(rec, '\n') if startswith(l, "row ")]
        f = split(rows0[1][5:end], "|")
        v2 = parse(Float64, String(f[3])) * 2
        badrow = "row " * join([String(f[1]), String(f[2]),
            p2c_tok(v2), p2c_bits(v2), String(f[5]), String(f[6]),
            String(f[7]), String(f[8])], "|")
        r2 = replace(rec, rows0[1] => badrow)
        any(occursin("normalized != value/threshold", i) for i in
            c3c_record_issues(r2, "anchor", "anchor", "primary"))
    end
    t["upstream_three_branches"] = begin
        function mkrecs(tc, tgr)
            recs = Dict{String, Any}()
            for arm in C3C_ARMS, pass in C3C_PASSES
                c = arm == "c3ib" ? tc : "10.25"
                g = arm == "c3ib" ? tgr : "0.5"
                recs["$arm-$pass"] = (status = "Converged", cost = c,
                                      gradient = g)
            end
            recs
        end
        i1, o1 = c3c_upstream_compare(mkrecs("9.5", "0.25"))
        i2, o2 = c3c_upstream_compare(mkrecs("10.25", "0.5"))
        i3, o3 = c3c_upstream_compare(mkrecs("11.5", "0.75"))
        d1 = [o for o in o1 if occursin("UPSTREAM DELTA", o)]
        d2 = [o for o in o2 if occursin("UPSTREAM DELTA", o)]
        d3 = [o for o in o3 if occursin("UPSTREAM DELTA", o)]
        isempty(i1) && isempty(i2) && isempty(i3) &&
            length(d1) == 8 && length(d2) == 8 && length(d3) == 8 &&
            all(occursin("BRANCH=NEGATIVE", o) for o in d1) &&
            all(occursin("BRANCH=ZERO-AT-TOKEN-REPRESENTATION", o)
                for o in d2) &&
            all(occursin("BRANCH=POSITIVE", o) for o in d3)
    end
    t["compare_extra_scorefile_census_refuses"] = begin
        rr = mktempdir()
        for (k, v) in good13
            write(joinpath(rr, "score-$k.txt"), v)
        end
        write(joinpath(rr, "score-evil-extra-primary.txt"), "x")
        write(joinpath(rr, "anchor-marker.txt"), "HIT")
        # production path: c3c_main compare must refuse on the extra
        # score file (directory census); stdout noise is acceptable
        c3c_main(["compare", rr]) != 0
    end
    t["record_key_permutation_refuses"] = begin
        r2 = copy(good13)
        r2["c0a-raw2-primary"], r2["c0b-raw2-primary"] =
            r2["c0b-raw2-primary"], r2["c0a-raw2-primary"]
        iss, _ = c3c_compare(r2, "HIT")
        !isempty(iss)
    end
    t["wrong_panel_sw_mapping_refuses"] = begin
        r2 = copy(good13)
        r2["c0a-raw2-secondary"] = replace(r2["c0a-raw2-secondary"],
            "sw_sha=" * C3C_SECONDARY_SW_SHA =>
            "sw_sha=" * C3C_PRIMARY_SW_SHA)
        iss, _ = c3c_compare(r2, "HIT")
        !isempty(iss)
    end
    t["objective_argmax_mismatch_refuses"] = begin
        r2 = replace(rec, r"(?m)^objective_metric=.*$" =>
                     "objective_metric=lw_up_rmse")
        any(occursin("argmax", i) for i in
            c3c_record_issues(r2, "anchor", "anchor", "primary"))
    end
    t["unknown_line_decoy_refuses"] = begin
        r2 = rec * "note=decoy\n"
        !isempty(c3c_record_issues(r2, "anchor", "anchor", "primary"))
    end
    # E-HOLD class 3: partitions incl. exact 1.05 boundary
    t["placement_exact_boundary"] = c3c_placement("1.05") === true &&
        c3c_placement("1.0500000000000001") === false
    t["delta_partitions_all_three"] = begin
        d1 = c3c_delta("1.5", "2.5"); d2 = c3c_delta("2.5", "2.5")
        d3 = c3c_delta("3.5", "2.5")
        d1.branch == "NEGATIVE" && d2.branch ==
            "ZERO-AT-TOKEN-REPRESENTATION" && d3.branch == "POSITIVE"
    end
    # E-HOLD class 4: scan fixtures (tiny synthetic states)
    t["scan_good_and_faults"] = begin
        sd = mktempdir()
        function wst(path; ty = Float32, val = 1.0f0)
            NCDataset(path, "c") do ds
                defDim(ds, "n", 3)
                v = defVar(ds, "alpha", ty, ("n",))
                v[:] = fill(convert(ty, val), 3)
            end
            path
        end
        g = wst(joinpath(sd, "ref.nc"))
        gsha = p2_sha(g)
        ok = wst(joinpath(sd, "ok.nc"))
        i1, o1 = c3c_scan_structural(ok, g, gsha, "ok")
        bad = wst(joinpath(sd, "bad.nc"); ty = Float64)
        i2, _ = c3c_scan_structural(bad, g, gsha, "bad")
        nf = wst(joinpath(sd, "nf.nc"); val = Inf32)
        i3, o3 = c3c_scan_structural(nf, g, gsha, "nf")
        isempty(i1) && !isempty(i2) && isempty(i3) &&
            any(occursin("NONFINITE RECORD", x) for x in o3)
    end
    # E-HOLD class 5: mutations through the PRODUCTION classifier
    t["ledger_mutations_refuse_via_classifier"] = begin
        fxl = mktempdir()
        src = read(c3g_ledger_path(C3G_LEDGERS[5]), String)
        pgood = joinpath(fxl, "good.json"); write(pgood, src)
        l0 = (name = "T", case = C3G_LEDGERS[5].case,
              status = C3G_LEDGERS[5].status, sha = p2_sha(pgood),
              file = "good.json")
        green = c3g_classify_ledger(l0; path = pgood).ok
        pst = joinpath(fxl, "st.json")
        write(pst, replace(src, C3G_LEDGERS[5].status => "wrong_status"))
        stbad = !c3g_classify_ledger((name = "T", case = l0.case,
            status = l0.status, sha = p2_sha(pst), file = "st.json");
            path = pst).ok
        pca = joinpath(fxl, "ca.json")
        write(pca, replace(src, C3G_LEDGERS[5].case => "wrong_case"))
        cabad = !c3g_classify_ledger((name = "T", case = l0.case,
            status = l0.status, sha = p2_sha(pca), file = "ca.json");
            path = pca).ok
        shabad = !c3g_classify_ledger((name = "T", case = l0.case,
            status = l0.status, sha = "0"^64, file = "good.json");
            path = pgood).ok
        green && stbad && cabad && shabad
    end
    # E-HOLD class 6: leak negative through the shared predicate
    t["downstream_leak_negative_via_predicate"] = begin
        mut = replace(c3g_derive_downstream(),
                      "OPTIMIZE_LUT CHILD FAILED" =>
                      "max_iterations=9000 OPTIMIZE_LUT CHILD FAILED")
        !isempty(c3g_downstream_leak_issues(mut)) &&
            isempty(c3g_downstream_leak_issues(c3g_derive_downstream()))
    end
    # E-HOLD class 7: additional text mutations
    t["text_scan_call_removed_refuses"] = !isempty(tg(replace(text,
        "\" scan \"" => "\" scanx \"")))
    t["text_upstream_call_removed_refuses"] = !isempty(tg(replace(text,
        "\" upstream \"" => "\" upstreamx \"")))
    t["text_time_partition_refuses"] = !isempty(tg(replace(text,
        "#SBATCH --time=06:00:00" => "#SBATCH --time=12:00:00")))
    t["text_ledger_pin_drift_refuses"] = !isempty(tg(replace(text,
        C3G_LEDGERS[2].sha => "0"^64)))
    t["text_census_row_drift_refuses"] = !isempty(tg(replace(text,
        "artifact tree census != $C3G_TREE_FILES" => "note")))
    t["text_wrapper_gate_removed_refuses"] = !isempty(tg(replace(text,
        "REFUSED: wrapper bytes differ across arms" => "note")))
    t["text_config_gate_removed_refuses"] = !isempty(tg(replace(text,
        "REFUSED: config override not exactly once" => "note")))
    t["text_base_extra_token_gate_removed_refuses"] = !isempty(tg(
        replace(text,
        "REFUSED: \$arm base carries an extra max_iterations token" =>
        "note")))
    t["text_postrun_reverify_removed_refuses"] = !isempty(tg(replace(
        text, "REFUSED: source-template drifted during the runs" =>
        "note")))
    t["text_canonical_write_refuses"] =
        !isempty(tg(text * "\nmv -n -- x \$CANON_FINAL\n"))
    # stale-identifier sweep (F-E): PRODUCTION identifier scanner --
    # Meta.parseall + recursive Symbol walk (comments/string literals
    # never match; the forbidden list here is strings, not symbols)
    t["stale_p2_identifier_sweep"] = begin
        src = read(joinpath(P2_PROJECT_ROOT,
                            "validation/gate4_c3_ib_checkpoint.jl"),
                   String)
        isempty(c3g_identifier_hits(src,
            ["P2_PLATEAU_PATH", "P2_PUB_PATH", "P2_SW_PATH",
             "P2_ARM_LIST", "P2_RESULTS_JSON", "P2_RESULTS_MD",
             "P2_SBATCH", "p2_classify_ledger", "P2_LEDGERS",
             "P2_DESIGN_SHA", "P2_G4WORK", "P2_LOG_DIR"]))
    end
    t["identifier_scanner_detects_synthetic"] = begin
        hits = c3g_identifier_hits("const P2_SBATCH = 1\n",
                                   ["P2_SBATCH"])
        hits == ["P2_SBATCH"] &&
            isempty(c3g_identifier_hits(
                "# P2_SBATCH in comment\nx = \"P2_SBATCH string\"\n",
                ["P2_SBATCH"]))
    end
    # eval1 selected-mode closure fixtures (4578 recovery class):
    # primary authority = pinned structured published-training
    # manifest; independent cross-check = deployed script blocks;
    # corroborating = G3 executor staged sets
    mdata = JSON.parse(read(C3G_TRAINING_MANIFEST_FILE, String))
    dbase = c3g_astext(c3g_derive_base(3000))
    ddown = c3g_astext(c3g_derive_downstream())
    mani = c3g_eval1_manifest()
    t["eval1_manifest_pin_exact"] =
        p2_try_sha(C3G_TRAINING_MANIFEST_FILE) ==
        C3G_TRAINING_MANIFEST_SHA
    t["eval1_closure_exact_20"] =
        isempty(c3g_eval1_closure_issues(mdata, dbase, ddown)) &&
        isempty(c3g_g3_executor_issues())
    t["eval1_manifest_missing_refuses"] = begin
        iss = c3g_eval1_closure_issues(mdata, dbase, ddown;
            manifest = mani[1:end-1])
        ("eval1 manifest count 19 != 20") in iss &&
            any(occursin("closure != pinned manifest", i) for i in iss)
    end
    t["eval1_manifest_duplicate_refuses"] = begin
        iss = c3g_eval1_closure_issues(mdata, dbase, ddown;
            manifest = vcat(mani, [mani[1]]))
        ("eval1 manifest carries duplicate basenames") in iss &&
            ("eval1 manifest count 21 != 20") in iss
    end
    t["eval1_manifest_extra_unselected_refuses"] = begin
        iss = c3g_eval1_closure_issues(mdata, dbase, ddown;
            manifest = vcat(mani,
                ["ckdmip_evaluation1_lw_fluxes_5gas-415.h5"]))
        any(occursin("unselected-branch name", i) for i in iss) &&
            any(occursin("closure != pinned manifest", i) for i in iss)
    end
    t["eval1_wrong_mode_refuses"] = begin
        iss = c3g_eval1_closure_issues(mdata, dbase, ddown;
            modes = vcat(C3G_EVAL1_SELECTED_MODES, ["zero-minor2"]))
        any(occursin("closure contains unselected-branch name", i)
            for i in iss)
    end
    t["eval1_authority_drift_refuses"] = begin
        mm = JSON.parse(replace(JSON.json(mdata),
            "ckdmip_evaluation1_lw_fluxes_n2o-405.h5" =>
            "ckdmip_evaluation1_lw_fluxes_n2o-406.h5"))
        iss = c3g_eval1_closure_issues(mm, dbase, ddown)
        any(occursin("structured-manifest selected-mode closure != " *
                     "pinned manifest", i) for i in iss) &&
            !any(occursin("deployed selected-mode closure", i)
                 for i in iss)
    end
    t["eval1_g3_evidence_drift_refuses"] = begin
        fxd = mktempdir()
        for n in mani[1:end-1]
            write(joinpath(fxd, n), "x")
        end
        !isempty(c3g_g3_executor_issues(dirs = [fxd]))
    end
    t["eval1_census_gate_deletion_refuses"] = begin
        mut = replace(text,
            "REFUSED: staged eval1 census != generation-derived " *
            "20-name selected-mode closure (pre-build gate)" => "removed")
        iss = c3g_text_gate_issues(mut, downstream_sha, base_pins)
        any(occursin("staged eval1 census", i) for i in iss)
    end
    t["eval1_unselected_row_injection_refuses"] = begin
        mut = text * "\n# ckdmip_evaluation1_lw_fluxes_5gas-415.h5\n"
        iss = c3g_text_gate_issues(mut, downstream_sha, base_pins)
        any(occursin("forbidden text present: " *
                     "ckdmip_evaluation1_lw_fluxes_5gas", i)
            for i in iss)
    end
    t["eval1_coverage_stage_drop_refuses"] = begin
        t3 = first(x for x in C3G_DATA_INPUTS
                   if endswith(x[3], "_present.h5"))
        n = basename(t3[3])
        row = "$(t3[1]) $(t3[2]) $(t3[3]) " *
              "\$RUNROOT/data/evaluation1/lw_fluxes/$n"
        mut = replace(text, row * "\n" => "")
        iss = c3g_text_gate_issues(mut, downstream_sha, base_pins)
        any(occursin("stage copy row for $n", i) for i in iss)
    end
    t["eval1_coverage_reverify_drop_refuses"] = begin
        t3 = first(x for x in C3G_DATA_INPUTS
                   if endswith(x[3], "_present.h5"))
        n = basename(t3[3])
        row = "$(t3[1])  \$RUNROOT/data/evaluation1/lw_fluxes/$n"
        mut = replace(text, row * "\n" => "")
        iss = c3g_text_gate_issues(mut, downstream_sha, base_pins)
        any(occursin("post-run reverify row for $n", i) for i in iss)
    end
    t["eval1_census_ls_weakening_refuses"] = begin
        mut = replace(text,
            "find \"\$RUNROOT/data/evaluation1/lw_fluxes\" -mindepth 1 " *
            "-maxdepth 1 -printf '%f\\n'" =>
            "ls \"\$RUNROOT/data/evaluation1/lw_fluxes\"")
        iss = c3g_text_gate_issues(mut, downstream_sha, base_pins)
        any(occursin("required text missing: find", i) for i in iss) &&
            any(occursin("forbidden text present: ls \"\$RUNROOT/data",
                         i) for i in iss)
    end
    t["eval1_coverage_census_removal_refuses"] = begin
        mut = replace(text,
            "cat <<'EV1NAMES' > \"\$RUNROOT/ev1-expected.txt\"" => "true")
        iss = c3g_text_gate_issues(mut, downstream_sha, base_pins)
        any(occursin("census block missing", i) for i in iss)
    end
    t["ledger_4578_gatepins_deletion_refuses"] = begin
        row = C3G_LEDGERS[6].sha * "  " *
              c3g_ledger_path(C3G_LEDGERS[6])
        mut = replace(text, row * "\n" => "")
        iss = c3g_text_gate_issues(mut, downstream_sha, base_pins)
        ("required text missing: " * row) in iss &&
            ("4578 failure-ledger stage-0 pin expected exactly 1, " *
             "got 0") in iss
    end
    t["ledger_4578_gatepins_duplicate_refuses"] = begin
        row = C3G_LEDGERS[6].sha * "  " *
              c3g_ledger_path(C3G_LEDGERS[6])
        mut = replace(text, row * "\n" => row * "\n" * row * "\n")
        iss = c3g_text_gate_issues(mut, downstream_sha, base_pins)
        ("4578 failure-ledger stage-0 pin expected exactly 1, " *
         "got 2") in iss
    end
    t["training_manifest_pin_deletion_refuses"] = begin
        row = C3G_TRAINING_MANIFEST_SHA * "  " *
              C3G_TRAINING_MANIFEST_FILE
        mut = replace(text, row * "\n" => "")
        iss = c3g_text_gate_issues(mut, downstream_sha, base_pins)
        ("required text missing: " * row) in iss &&
            ("training-manifest stage-0 pin expected exactly 1, got 0") in iss
    end
    t["training_manifest_pin_drift_refuses"] = begin
        mut = replace(text, C3G_TRAINING_MANIFEST_SHA => "0"^64)
        iss = c3g_text_gate_issues(mut, downstream_sha, base_pins)
        any(occursin("training-manifest stage-0 pin", i) for i in iss)
    end
    t["ledger_4578_classifier_mutations_refuse"] = begin
        fxl = mktempdir()
        src = read(c3g_ledger_path(C3G_LEDGERS[6]), String)
        pgood = joinpath(fxl, "good.json"); write(pgood, src)
        l0 = (name = "T", case = C3G_LEDGERS[6].case,
              status = C3G_LEDGERS[6].status, sha = p2_sha(pgood),
              file = "good.json")
        green = c3g_classify_ledger(l0; path = pgood).ok
        pst = joinpath(fxl, "st.json")
        write(pst, replace(src, C3G_LEDGERS[6].status => "wrong"))
        stbad = !c3g_classify_ledger((name = "T", case = l0.case,
            status = l0.status, sha = p2_sha(pst), file = "st.json");
            path = pst).ok
        shabad = !c3g_classify_ledger((name = "T", case = l0.case,
            status = l0.status, sha = "0"^64, file = "good.json");
            path = pgood).ok
        green && stbad && shabad
    end
    t["ledger_4578_semantic_mutations_refuse"] = begin
        data = JSON.parse(read(c3g_ledger_path(C3G_LEDGERS[6]), String))
        ok0 = isempty(c3g_4578_semantic_issues(data))
        m1 = deepcopy(data); m1["job"]["exit_code"] = "0:0"
        m2 = deepcopy(data)
        m2["monitor_observations"]["classification"] = "other"
        m3 = deepcopy(data)
        m3["durable_evidence"]["receipt"]["sha256"] = "0"^64
        ok0 && !isempty(c3g_4578_semantic_issues(m1)) &&
            !isempty(c3g_4578_semantic_issues(m2)) &&
            !isempty(c3g_4578_semantic_issues(m3))
    end

    # design guards
    design = read(C3G_DESIGN_FILE, String)
    t["design_two_script_discipline"] =
        occursin("TWO-SCRIPT", design) &&
        occursin("NEGATIVE LEAK FIXTURE", design)
    t["design_thirteen_scores"] = occursin("EXACTLY THIRTEEN", design)
    t["design_anchor_properties"] =
        occursin("SEVERABILITY", design) &&
        occursin("NON-CIRCULARITY", design) &&
        occursin("current-G1-adjacent", design)
    t["design_ceiling_language"] =
        occursin("NO recovered", design) &&
        occursin("NO automatic escalation", design)
    t["design_terminal_supersession_rule"] =
        occursin("TERMINAL SUPERSESSION RULE (BINDING FOR THIS UNIT)",
                 design) &&
        occursin("EXPLICITLY SUPERSEDED", design) &&
        occursin("explicit Codex-monitor review and GO", design) &&
        occursin("NO automatic retry or resubmission", design)
    t["terminal_policy_deletion_refuses"] = begin
        mut = replace(text, "# " * C3G_TERMINAL_CONTRACT * "\n" => "")
        iss = c3g_text_gate_issues(mut, downstream_sha, base_pins)
        ("required text missing: # " * C3G_TERMINAL_CONTRACT) in iss &&
            ("terminal policy line expected exactly 1, got 0") in iss
    end
    t["terminal_policy_duplication_refuses"] = begin
        line = "# " * C3G_TERMINAL_CONTRACT * "\n"
        mut = replace(text, line => line * line)
        iss = c3g_text_gate_issues(mut, downstream_sha, base_pins)
        ("terminal policy line expected exactly 1, got 2") in iss
    end
    t["terminal_policy_token_mutation_refuses"] = begin
        mut = replace(text,
            "TIMEOUT is NOT a continuity exception" =>
            "TIMEOUT is a continuity exception")
        iss = c3g_text_gate_issues(mut, downstream_sha, base_pins)
        ("required text missing: # " * C3G_TERMINAL_CONTRACT) in iss &&
            ("terminal policy line expected exactly 1, got 0") in iss
    end
    t
end

# --- prerequisite classifier + main (SECTION F) -----------------------------

function c3g_classify_ledger(l; path = c3g_ledger_path(l))
    snap = p2_snapshot(path)
    snap.ok || return (ok = false,
                       reason = "$(l.name) ledger $(snap.reason)")
    get(snap.data, "case", nothing) == l.case ||
        return (ok = false, reason = "$(l.name) ledger case mismatch")
    get(snap.data, "status", nothing) == l.status ||
        return (ok = false, reason = "$(l.name) ledger status mismatch")
    snap.sha == l.sha ||
        return (ok = false, reason = "$(l.name) ledger sha drift")
    (ok = true, reason = "")
end

const C3G_RESULTS_JSON = validation_results_path("gate4_c3_ib_checkpoint.json")
const C3G_RESULTS_MD = validation_results_path("gate4_c3_ib_checkpoint.md")
const C3G_SBATCH = validation_results_path("gate4_c3_ib_lw_iteration_budget.sbatch")

function main()
    fails = String[]
    gates = Dict{String, String}()
    groups = Dict{String, Vector{String}}()

    pkg = p2_pkg_manifest()
    tree = p1_tree_manifest_c3()

    dd = String[]
    p2_try_sha(C3G_DESIGN_FILE) == C3G_DESIGN_SHA ||
        push!(dd, "frozen design sha drift")
    p2_try_sha(joinpath(P2_PROJECT_ROOT, P2_P1_CHECKER_REPO)) ==
        P2_P1_CHECKER_SHA || push!(dd, "P1 checker sha drift")
    p2_try_sha(joinpath(P2_PROJECT_ROOT, P2_CHECKER_REPO)) ==
        C3G_P2_CHECKER_SHA || push!(dd, "P2 checker sha != committed pin")
    p2_try_sha(joinpath(P2_PROJECT_ROOT, C3G_CHECKER_REPO)) ==
        C3G_CHECKER_SHA ||
        push!(dd, "C3 checker sha != stopped pin (update the pin on " *
              "every reviewed checker revision)")
    for (pth, lbl, wsz) in ((P2_TEST_PROJECT, "test Project.toml",
                             C3G_TEST_PROJECT_BYTES),
                            (P2_TEST_MANIFEST, "test Manifest.toml",
                             C3G_TEST_MANIFEST_BYTES))
        isfile(pth) || (push!(dd, "$lbl missing"); continue)
        filesize(pth) == wsz ||
            push!(dd, "$lbl bytes $(filesize(pth)) != pinned $wsz")
    end
    p2_try_sha(P2_TEST_PROJECT) ==
        "9136a5f68b97123017182b5afaf30c93148188a0ea8681ac3d17a808f6012ef0" ||
        push!(dd, "test Project.toml sha drift")
    p2_try_sha(P2_TEST_MANIFEST) ==
        "cf9f318d43221280a8ca1116fbfea20d66678267f4e9d5dd1bdf519093ceb186" ||
        push!(dd, "test Manifest.toml sha drift")
    groups["frozen_pins"] = dd

    # F-B: generation-time runtime/build provenance (mirrors the sbatch)
    bp_ = String[]
    for (t_, pth_, l1) in C3G_TOOLCHAIN
        got = try
            strip(read(`which $t_`, String))
        catch
            "missing"
        end
        got == pth_ || push!(bp_, "$t_ path $got != pinned")
        gl = try
            first(split(read(`$t_ --version`, String), '\n'))
        catch
            "unreadable"
        end
        gl == l1 || push!(bp_, "$t_ version drift: $gl")
    end
    amv = try
        strip(last(split(first(split(read(`automake --version`,
            String), '\n')), ' ')))
    catch
        "unreadable"
    end
    amv == C3G_AUTOMAKE_VER || push!(bp_, "automake $amv != pinned")
    ltv = try
        strip(last(split(first(split(read(`libtoolize --version`,
            String), '\n')), ' ')))
    catch
        "unreadable"
    end
    ltv == C3G_LIBTOOLIZE_VER || push!(bp_, "libtoolize $ltv != pinned")
    for (what, pth_, sha_, sz_) in (
        ("Minimizer.h", "$C3G_ADEPT/include/adept/Minimizer.h",
         C3G_MINIMIZER_H_SHA, C3G_MINIMIZER_H_BYTES),
        ("adept_source.h", "$C3G_ADEPT/include/adept_source.h",
         C3G_ADEPT_SOURCE_H_SHA, C3G_ADEPT_SOURCE_H_BYTES),
        ("libadept", "$C3G_ADEPT/lib/libadept.so.0.0.0",
         C3G_LIBADEPT_SHA, C3G_LIBADEPT_BYTES),
        ("shim", C3G_SHIM_SO, C3G_SHIM_SO_SHA, C3G_SHIM_SO_BYTES),
        ("netlib BLAS", C3G_NETLIB_BLAS, C3G_NETLIB_BLAS_SHA,
         C3G_NETLIB_BLAS_BYTES),
        ("netlib LAPACK", C3G_NETLIB_LAPACK, C3G_NETLIB_LAPACK_SHA,
         C3G_NETLIB_LAPACK_BYTES))
        isfile(pth_) || (push!(bp_, "$what missing: $pth_"); continue)
        filesize(pth_) == sz_ ||
            push!(bp_, "$what size drift: $pth_")
        p2_try_sha(pth_) == sha_ || push!(bp_, "$what sha drift: $pth_")
    end
    isdir(joinpath(C3G_NETCDF, "lib")) && isdir(joinpath(C3G_NETCDF, "include")) ||
        push!(bp_, "netcdf prefix lib/include missing")
    groups["runtime_build_provenance"] = bp_

    lg = String[]
    for l in C3G_LEDGERS
        c = c3g_classify_ledger(l)
        c.ok || push!(lg, c.reason)
    end
    g1data = try
        JSON.parse(read(c3g_ledger_path(C3G_LEDGERS[2]), String))
    catch
        push!(lg, "G1 ledger unreadable")
        nothing
    end
    g1data === nothing || append!(lg, c3g_g1_semantic_issues(g1data))
    fdata = try
        JSON.parse(read(c3g_ledger_path(C3G_LEDGERS[6]), String))
    catch
        push!(lg, "4578 failure ledger unreadable")
        nothing
    end
    fdata === nothing || append!(lg, c3g_4578_semantic_issues(fdata))
    groups["prerequisite_ledgers"] = lg

    inp = String[]
    for (sha, sz, path) in vcat(C3G_DATA_INPUTS,
        [(C3G_LBL_INPUT[1], C3G_LBL_INPUT[2], C3G_LBL_INPUT[3]),
         (P2_INIT_SHA, P2_INIT_BYTES, P2_INIT_PATH),
         (C3G_GPOINTS_INPUT[1], C3G_GPOINTS_INPUT[2], C3G_GPOINTS_INPUT[3]),
         (C3C_ANCHOR_LW_SHA, C3G_ANCHOR_LW_BYTES, C3G_ANCHOR_LW_PATH),
         (C3C_PRIMARY_SW_SHA, C3G_PRIMARY_SW_BYTES, C3G_PRIMARY_SW_PATH),
         (C3C_SECONDARY_SW_SHA, C3G_SECONDARY_SW_BYTES, C3G_SECONDARY_SW_PATH)])
        isfile(path) || (push!(inp, "missing master: $path"); continue)
        filesize(path) == sz || push!(inp, "master size drift: $path")
        p2_try_sha(path) == sha || push!(inp, "master sha drift: $path")
    end
    for (sha, sz, path) in C3G_V12_TEST_PINS
        isfile(path) || (push!(inp, "missing test pin: $path"); continue)
        filesize(path) == sz || push!(inp, "test pin size drift: $path")
        p2_try_sha(path) == sha || push!(inp, "test pin drift: $path")
    end
    groups["master_pins"] = inp

    tr = String[]
    length(tree) == C3G_TREE_FILES ||
        push!(tr, "tree census $(length(tree)) != $C3G_TREE_FILES")
    count(e -> e.exec, tree) == C3G_TREE_EXEC ||
        push!(tr, "tree exec census != $C3G_TREE_EXEC")
    groups["source_tree"] = tr
    groups["source_census"] = p2_source_census_issues(pkg)

    tc = String[]
    jl1 = try
        first(split(read(`$P2_JULIA_BIN --version`, String), '\n'))
    catch
        "unreadable"
    end
    jl1 == P2_JULIA_VERSION_LINE || push!(tc, "julia version drift: $jl1")
    groups["julia_provenance"] = tc

    downstream_sha = bytes2hex(sha256(c3g_derive_downstream()))
    base_pins = (bytes2hex(sha256(c3g_derive_base(1))),
                 bytes2hex(sha256(c3g_derive_base(3000))),
                 bytes2hex(sha256(c3g_derive_base(9000))))
    groups["derivations"] =
        c3g_downstream_leak_issues(c3g_derive_downstream())
    mferr = String[]
    p2_try_sha(C3G_TRAINING_MANIFEST_FILE) == C3G_TRAINING_MANIFEST_SHA ||
        push!(mferr, "structured training manifest sha != pinned")
    mdata = try
        JSON.parse(read(C3G_TRAINING_MANIFEST_FILE, String))
    catch
        push!(mferr, "structured training manifest unreadable")
        nothing
    end
    groups["eval1_closure"] = mdata === nothing ? mferr :
        vcat(mferr,
             c3g_eval1_closure_issues(mdata,
                 c3g_astext(c3g_derive_base(3000)),
                 c3g_astext(c3g_derive_downstream())),
             c3g_g3_executor_issues())

    text = c3g_make_sbatch(pkg)
    groups["sbatch_deterministic_render"] =
        text == c3g_make_sbatch(pkg) ? String[] :
        ["sbatch render is not deterministic"]
    groups["sbatch_text_gates"] =
        c3g_text_gate_issues(text, downstream_sha, base_pins)
    groups["sbatch_bash_syntax"] = c3g_bash_syntax_ok(text) ? String[] :
        ["generated sbatch fails bash -n"]

    tests = c3g_fixtures(pkg, text, downstream_sha, base_pins)
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end
    ready = gates["fixtures"] == "passed" && all(isempty, values(groups))
    status = ready ? "c3ib_checkpoint_ready" : "c3ib_checkpoint_refused"
    if ready
        mkpath(dirname(C3G_SBATCH))
        write(C3G_SBATCH, text)
    end
    sb_sha = ready ? p2_sha(C3G_SBATCH) : nothing

    result = Dict(
        "case" => "gate4_c3_ib_checkpoint",
        "data_mode" => "generator_checkpoint",
        "status" => status,
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "fixture_count" => length(tests),
        "sbatch_path" => C3G_SBATCH,
        "sbatch_sha256" => sb_sha,
        "frozen_design" => Dict("sha256" => C3G_DESIGN_SHA,
            "durable_file" => C3G_DESIGN_REPO_PATH,
            "verbatim_text" => read(C3G_DESIGN_FILE, String)),
        "derived_pins" => Dict(
            "downstream_template_sha256" => downstream_sha,
            "base_1_sha256" => base_pins[1],
            "base_3000_sha256" => base_pins[2],
            "base_9000_sha256" => base_pins[3]),
        "score_matrix" => "EXACTLY 13 (12 arm-panel: 3 arms x raw2/final " *
            "x primary/secondary + 1 fixed current-G1 anchor); " *
            "severability: anchor miss refuses only the " *
            "current-G1-adjacent label",
        "checkers" => Dict(
            "p1" => P2_P1_CHECKER_SHA,
            "p2" => p2_sha(joinpath(P2_PROJECT_ROOT, P2_CHECKER_REPO)),
            "c3" => p2_sha(joinpath(P2_PROJECT_ROOT, C3G_CHECKER_REPO))),
        "prerequisites" => [Dict("name" => l.name, "case" => l.case,
                                 "status" => l.status, "sha256" => l.sha)
                            for l in C3G_LEDGERS],
        "source_tree" => Dict("files" => length(tree),
            "exec_census" => count(e -> e.exec, tree),
            "manifest_sha256" => bytes2hex(sha256(join(
                ["$(e.sha) $(e.bytes) $(e.exec ? 1 : 0) $(e.rel)"
                 for e in tree], "\n")))),
        "package_tree" => Dict("files" => length(pkg),
            "exec_census" => count(e -> e.exec, pkg),
            "manifest_sha256" => bytes2hex(sha256(join(
                ["$(e.sha) $(e.bytes) $(e.exec ? 1 : 0) $(e.rel)"
                 for e in pkg], "\n")))),
        "julia_provenance" => Dict("launcher" => P2_JULIA_BIN,
            "version_line" => P2_JULIA_VERSION_LINE,
            "test_project_sha256" => p2_sha(P2_TEST_PROJECT),
            "test_project_bytes" => filesize(P2_TEST_PROJECT),
            "test_manifest_sha256" => p2_sha(P2_TEST_MANIFEST),
            "test_manifest_bytes" => filesize(P2_TEST_MANIFEST)),
        "runtime_build_provenance" => Dict(
            "toolchain" => [Dict("tool" => t_, "path" => pth_,
                                 "version_line" => l1)
                            for (t_, pth_, l1) in C3G_TOOLCHAIN],
            "automake" => C3G_AUTOMAKE_VER,
            "libtoolize" => C3G_LIBTOOLIZE_VER,
            "adept" => Dict(
                "minimizer_h" => Dict(
                    "path" => "$C3G_ADEPT/include/adept/Minimizer.h",
                    "sha256" => C3G_MINIMIZER_H_SHA,
                    "bytes" => C3G_MINIMIZER_H_BYTES),
                "adept_source_h" => Dict(
                    "path" => "$C3G_ADEPT/include/adept_source.h",
                    "sha256" => C3G_ADEPT_SOURCE_H_SHA,
                    "bytes" => C3G_ADEPT_SOURCE_H_BYTES),
                "libadept" => Dict(
                    "path" => "$C3G_ADEPT/lib/libadept.so.0.0.0",
                    "sha256" => C3G_LIBADEPT_SHA,
                    "bytes" => C3G_LIBADEPT_BYTES)),
            "netcdf" => Dict("prefix" => C3G_NETCDF,
                "lib_dir_verified" => isdir(joinpath(C3G_NETCDF, "lib")),
                "include_dir_verified" =>
                    isdir(joinpath(C3G_NETCDF, "include"))),
            "shim" => Dict("path" => C3G_SHIM_SO,
                           "sha256" => C3G_SHIM_SO_SHA,
                           "bytes" => C3G_SHIM_SO_BYTES),
            "netlib_blas" => Dict("path" => C3G_NETLIB_BLAS,
                "sha256" => C3G_NETLIB_BLAS_SHA,
                "bytes" => C3G_NETLIB_BLAS_BYTES),
            "netlib_lapack" => Dict("path" => C3G_NETLIB_LAPACK,
                "sha256" => C3G_NETLIB_LAPACK_SHA,
                "bytes" => C3G_NETLIB_LAPACK_BYTES)),
        "masters" => vcat(
            [Dict("path" => path, "sha256" => sha, "bytes" => sz)
             for (sha, sz, path) in C3G_DATA_INPUTS],
            [Dict("path" => C3G_LBL_INPUT[3],
                  "sha256" => C3G_LBL_INPUT[1],
                  "bytes" => C3G_LBL_INPUT[2]),
             Dict("path" => P2_INIT_PATH, "sha256" => P2_INIT_SHA,
                  "bytes" => P2_INIT_BYTES),
             Dict("path" => C3G_GPOINTS_INPUT[3],
                  "sha256" => C3G_GPOINTS_INPUT[1],
                  "bytes" => C3G_GPOINTS_INPUT[2]),
             Dict("path" => C3G_ANCHOR_LW_PATH,
                  "sha256" => C3C_ANCHOR_LW_SHA,
                  "bytes" => C3G_ANCHOR_LW_BYTES),
             Dict("path" => C3G_PRIMARY_SW_PATH,
                  "sha256" => C3C_PRIMARY_SW_SHA,
                  "bytes" => C3G_PRIMARY_SW_BYTES),
             Dict("path" => C3G_SECONDARY_SW_PATH,
                  "sha256" => C3C_SECONDARY_SW_SHA,
                  "bytes" => C3G_SECONDARY_SW_BYTES)]),
        "conclusion_ceiling" => "BINDING (frozen design): private " *
            "fixed-setup budget association only; any sub-1.05 " *
            "placement is PRIVATE PLACEMENT, NOT recovered acceptance; " *
            "no recovery claim; no mechanism localization or ranking; " *
            "no objective/data change authorization; no automatic " *
            "escalation; the external <=1.05 gate untouched; ZERO " *
            "canonical writes; RUNROOT preserved",
        "terminal_contract" => C3G_TERMINAL_CONTRACT,
        "eval1_staging" => Dict(
            "selected_modes" => C3G_EVAL1_SELECTED_MODES,
            "closure_count" => 20,
            "names" => c3g_eval1_manifest(),
            "structured_manifest" => Dict(
                "path" => C3G_TRAINING_MANIFEST_FILE,
                "sha256" => C3G_TRAINING_MANIFEST_SHA),
            "derivation" => "PRIMARY: pinned structured " *
                "published-training manifest " *
                "(ecckd_published_training_manifest.json); " *
                "INDEPENDENT CROSS-CHECK: generation-derived " *
                "deployed script blocks; CORROBORATING: G3 executor " *
                "staged sets (g3-runs 4505/4515); equality asserted, " *
                "never superset; rendered four-context coverage " *
                "gated per entry; unselected 5gas/co2 branches " *
                "excluded",
            "recovery_of" => "gate4_c3_ib_4578_failure_ledger"),
        "non_authorizing_note" => "generates and verifies the C3-IB " *
            "sbatch; never submits; submission requires explicit " *
            "monitor GO.",
        "disclaimer" => "generator checkpoint; writes nothing except " *
            "its own JSON/MD results and the generated sbatch plus " *
            "transient private temp fixtures (mktempdir).")

    mkpath(dirname(C3G_RESULTS_JSON))
    open(C3G_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(C3G_RESULTS_MD, "w") do io
        println(io, "# Gate-4 C3-IB iteration-budget checkpoint\n")
        println(io, "Status: **$status**\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nFrozen design: `$C3G_DESIGN_SHA`")
        println(io, "\nTerminal policy: $C3G_TERMINAL_CONTRACT")
        println(io, "\nGenerated sbatch: `$C3G_SBATCH`" *
                    (sb_sha === nothing ? " (NOT written; refused)" :
                     " sha256 `$sb_sha`"))
        println(io, "\nFixtures: $(length(tests)) " *
                    "($(count(values(tests))) passed)")
        println(io, "\nConclusion ceiling (binding): private " *
                    "fixed-setup budget association only; sub-1.05 = " *
                    "PRIVATE PLACEMENT, NOT recovered acceptance; no " *
                    "mechanism localization/ranking; no automatic " *
                    "escalation; ZERO canonical writes.")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_c3_ib_checkpoint: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    println("  fixtures: $(count(values(tests)))/$(length(tests)) passed")
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return ready ? 0 : 1
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end
