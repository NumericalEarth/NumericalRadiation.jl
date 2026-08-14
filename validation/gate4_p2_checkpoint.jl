# Gate-4 P2 FOUR-STATE HARD-OBJECTIVE CHECKPOINT (generator; writes
# ONLY its own JSON/MD results + the generated sbatch, plus transient
# private temp fixtures).
#
# FROZEN DESIGN AUTHORITY (monitor freeze):
# gate4_p2_frozen_design.md sha256
# c6c7638542f371ae1e44c91214d028e8f7ce9a9a61ca2be4fb0b2923f3b9f420.
#
# BINDING SHAPE: four LW states (init, plateau, in-RUNROOT
# reconstructed published-coefficient splice, published-final), each
# scored twice in the palindromic order
# init-a plateau-a splice-a published-a published-b splice-b plateau-b
# init-b, against ONE pinned published v1.4 SW32, through ONE immutable
# canonical eight-gas evaluator (h2o_mole_fraction=0.005,
# candidate_mode=official_ecckd). Per-arm records carry
# provenance + max_digits10 tokens + UInt64 bit patterns + the complete
# ordered 24-row vector; duplicate gates are exact scientific-payload
# equality; the three same-job control-reproduction gates
# (0.18218645425029933 / 102.67056437657112 / 22.791293464348826)
# refuse interpretation on miss. Residual-label license per the frozen
# design (ordered longwave_absorption gas slices + the complete
# longwave_h2o_absorption table; gas axis FIXED at 2), fourteen-field
# exact-name inventory + separate gas_names type-parameter gate,
# fixed-SW fields exact-equal across all four states.
# STAGING READ BRACKET (frozen): stage 0 pins/preflights live sources;
# stage 1 copies live->RUNROOT with immediate sha/size verification and
# freezes (a-w + writable scans); ZERO live repo/env/reference/input
# reads after the stage-1 freeze -- the evaluator consumes ONLY the
# staged package tree/chain/references/env/masters
# (JULIA_LOAD_PATH="@:$RUNROOT/pkg:@stdlib",
# NUMERICAL_RADIATION_VALIDATION_REFERENCE_DIR pinned to the staged
# reference dir). The SPLICE IS NOT A MASTER: reconstructed in-RUNROOT
# from staged init+published by the staged committed P1 checker.
# Zero canonical writes; RUNROOT preserved; submission/commit only on
# explicit monitor GO.

const P2_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
include(joinpath(P2_PROJECT_ROOT, "validation", "validation_results.jl"))

# evaluator chain + both checkers (generation-time semantics: live
# reads are lawful pre-freeze; the JOB reads only staged copies)
ENV["P2C_P1_CHECKER"] = joinpath(P2_PROJECT_ROOT, "validation",
                                 "gate4_p1_splice_checker.jl")
ENV["P2C_CHAIN_DIR"] = joinpath(P2_PROJECT_ROOT, "validation")
include(joinpath(P2_PROJECT_ROOT, "validation",
                 "gate4_p2_hard_objective_checker.jl"))

import JSON

const P2_G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const P2_LOG_DIR = "/shared/home/greg/data/ckdmip-logs"

const P2_DESIGN_SHA = "c6c7638542f371ae1e44c91214d028e8f7ce9a9a61ca2be4fb0b2923f3b9f420"
const P2_DESIGN_FILE = joinpath(@__DIR__, "gate4_p2_frozen_design.md")
const P2_DESIGN_REPO_PATH = "validation/gate4_p2_frozen_design.md"
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
const P2_PLATEAU_PATH = "$P2_G4WORK/g4-diag/4561/lw-x1/work-pristine/" *
    "lw_raw-ckd-definition/ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc"
const P2_PLATEAU_SHA = P1C_PLATEAU_SHA
const P2_PLATEAU_BYTES = P1C_PLATEAU_BYTES
const P2_PUB_PATH = P1C_PUB_PATH
const P2_PUB_SHA = P1C_PUB_SHA
const P2_PUB_BYTES = P1C_PUB_BYTES
const P2_SW_PATH = "/shared/home/greg/.julia/artifacts/" *
    "49ce668ce0861f9d5e8299d68af7138485eb5f19/" *
    "ecrad-131ac980517719b7a859e3ccc117919a1d888a20/data/" *
    "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc"
const P2_SW_SHA = "49abc7bf88b80252e4f9934f8659d108ffee6a101124b2fd080f2eb65d144eb3"
const P2_SW_BYTES = 851724

# --- prerequisites (fail-closed, sha-chained) ------------------------------------
const P2_LEDGERS = [
    (name = "B0", case = "gate4_b0_era_stack_completion_ledger",
     status = "b0_run_completed_verified",
     sha = "d109c0b6e5aa157716247cb05bdfdf806c96e7fc3367e3d5628c55baeda66012"),
    (name = "S1", case = "gate4_s1_state_sync_completion_ledger",
     status = "s1_run_completed_verified",
     sha = "de5b349e07b1f085e01f8a8fe6902ea50ac9ecce0821844ae99d8b3f9f40a586"),
    (name = "X1", case = "gate4_x1_direct_capture_completion_ledger",
     status = "x1_run_completed_verified",
     sha = "bb1f87c597e673c8a5b5181d325d46eff7b4619c106e28e7ecf121db32c34170"),
    (name = "C1", case = "gate4_c1_bounds_flag_completion_ledger",
     status = "c1_run_completed_verified",
     sha = "3c584417d4eba3459f58bbd182b395f7f8ed6c2cddb48e4fef54c057799d116f"),
    (name = "P1CKPT", case = "gate4_p1_checkpoint",
     status = "p1_checkpoint_ready",
     sha = "1e3a48d3c0495497aeba60560baab7fe3e23a15d8b52566dc3c3a90a2b51cb93"),
    (name = "P1LEDGER", case = "gate4_p1_completion_ledger",
     status = "p1_run_completed_verified",
     sha = "9605cf64deb5cb14f2f3403d73c976b00ddfa2c7fc50adba9cb24e1dd51f2403")]
p2_ledger_path(l) = joinpath(P2_PROJECT_ROOT, "validation", "results",
    Dict("B0" => "gate4_b0_era_stack_completion_ledger.json",
         "S1" => "gate4_s1_state_sync_completion_ledger.json",
         "X1" => "gate4_x1_direct_capture_completion_ledger.json",
         "C1" => "gate4_c1_bounds_flag_completion_ledger.json",
         "P1CKPT" => "gate4_p1_checkpoint.json",
         "P1LEDGER" => "gate4_p1_completion_ledger.json")[l.name])

# --- staged evaluator working set (package tree + chain + references) ------------
const P2_CHAIN_FILES = ["validation_results.jl",
    "ecrad_reference_manifest.jl", "write_ecrad_candidates.jl",
    "reduced_ecckd_accuracy.jl", "ecckd_published_model_accuracy.jl"]
const P2_ARM_LIST = join(P2C_ARMS, " ")

const P2_RESULTS_JSON = validation_results_path("gate4_p2_checkpoint.json")
const P2_RESULTS_MD = validation_results_path("gate4_p2_checkpoint.md")
const P2_SBATCH = validation_results_path("gate4_p2_lw_hard_objective.sbatch")

p2_sha(path) = p2c_sha(path)
p2_try_sha(path) = isfile(path) ? p2_sha(path) : nothing

# package-tree manifest: Project.toml + src/** + ext/** + the chain
# files + the resolved REDUCED reference files, as repo-relative rows
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

function p2_classify_ledger(l)
    snap = p2_snapshot(p2_ledger_path(l))
    snap.ok || return (ok = false, reason = "$(l.name) ledger $(snap.reason)")
    get(snap.data, "case", nothing) == l.case ||
        return (ok = false, reason = "$(l.name) ledger case mismatch")
    get(snap.data, "status", nothing) == l.status ||
        return (ok = false, reason = "$(l.name) ledger status mismatch")
    snap.sha == l.sha ||
        return (ok = false, reason = "$(l.name) ledger sha drift")
    (ok = true, reason = "")
end

# --- sbatch generation ----------------------------------------------------------

function p2_make_sbatch(pkg)
    checker_sha = p2_sha(joinpath(P2_PROJECT_ROOT, P2_CHECKER_REPO))
    gate_pins = join(vcat(
        ["$(p2_sha(joinpath(P2_PROJECT_ROOT, f)))  $(joinpath(P2_PROJECT_ROOT, f))"
         for f in ("validation/gate4_quota_guard.sh",
                   "validation/validation_results.jl")],
        ["$(p2_sha(abspath(@__FILE__)))  $P2_PROJECT_ROOT/validation/gate4_p2_checkpoint.jl",
         "$P2_P1_CHECKER_SHA  $P2_PROJECT_ROOT/$P2_P1_CHECKER_REPO",
         "$checker_sha  $P2_PROJECT_ROOT/$P2_CHECKER_REPO",
         "$P2_DESIGN_SHA  $P2_PROJECT_ROOT/$P2_DESIGN_REPO_PATH",
         "$(p2_sha(P2_TEST_PROJECT))  $P2_TEST_PROJECT",
         "$(p2_sha(P2_TEST_MANIFEST))  $P2_TEST_MANIFEST",
         "$(p2_sha(joinpath(P2_PROJECT_ROOT, P2_S1_SRC_REL)))  $P2_PROJECT_ROOT/$P2_S1_SRC_REL"],
        ["$(l.sha)  $(p2_ledger_path(l))" for l in P2_LEDGERS]), "\n")
    master_rows = [
        "$P2_INIT_SHA $P2_INIT_BYTES $P2_INIT_PATH \$RUNROOT/source-inputs/init.nc",
        "$P2_PLATEAU_SHA $P2_PLATEAU_BYTES $P2_PLATEAU_PATH \$RUNROOT/source-inputs/plateau.nc",
        "$P2_PUB_SHA $P2_PUB_BYTES $P2_PUB_PATH \$RUNROOT/source-inputs/published.nc",
        "$P2_SW_SHA $P2_SW_BYTES $P2_SW_PATH \$RUNROOT/source-inputs/sw.nc"]
    stage_lines = join(master_rows, "\n")
    pkg_rows = join(["$(e.sha) $(e.bytes) $P2_PROJECT_ROOT/$(e.rel) \$RUNROOT/pkg/$(e.rel)"
                     for e in pkg], "\n")
    pkg_exec_rows = join(["$(e.exec ? 1 : 0) $(e.rel)" for e in pkg], "\n")
    pkg_census = length(pkg)
    post_pkg = join(["$(e.sha)  \$RUNROOT/pkg/$(e.rel)" for e in pkg], "\n")
    post_masters = join([
        "$P2_INIT_SHA  \$RUNROOT/source-inputs/init.nc",
        "$P2_PLATEAU_SHA  \$RUNROOT/source-inputs/plateau.nc",
        "$P2_PUB_SHA  \$RUNROOT/source-inputs/published.nc",
        "$P2_SW_SHA  \$RUNROOT/source-inputs/sw.nc",
        "$(p2_sha(P2_TEST_PROJECT))  \$RUNROOT/julia-env/Project.toml",
        "$(p2_sha(P2_TEST_MANIFEST))  \$RUNROOT/julia-env/Manifest.toml"], "\n")
    arm_state_case = """
    case "\$arm" in
        init-*) LW="\$MI"; LSHA=$P2_INIT_SHA;;
        plateau-*) LW="\$MPL"; LSHA=$P2_PLATEAU_SHA;;
        splice-*) LW="\$RUNROOT/splice/splice_input.nc"; LSHA="\$SPLICE_SHA";;
        published-*) LW="\$MPUB"; LSHA=$P2_PUB_SHA;;
        *) echo "REFUSED: unknown arm \$arm" >&2; exit 70;;
    esac"""
    """
#!/bin/bash
#SBATCH --job-name=g4-p2-lw-hard-objective
#SBATCH --output=$P2_LOG_DIR/g4-p2-lw-%j.log
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=cpu-large

# Gate-4 P2: FOUR-STATE PACKAGE-NATIVE HARD-OBJECTIVE PLACEMENT
# (DIAGNOSIS unit; PRIVATE outputs only). Generated by
# gate4_p2_checkpoint.jl under the frozen design $P2_DESIGN_SHA.
# Staging read bracket: stage 0 pins live sources; stage 1 copies
# live->RUNROOT with immediate verification then freezes; ZERO live
# repo/env/reference/input reads after the freeze. The splice is NOT a
# master: reconstructed in-RUNROOT from staged init+published by the
# staged committed P1 checker. Eight palindromic arms; per-arm
# provenance records; bit-exact duplicate payload gates; three
# control-reproduction gates refusing interpretation on miss;
# residual-label license + fourteen-field inventory. ZERO canonical
# writes; RUNROOT preserved on success AND failure.
set -euo pipefail
if [ -z "\${SLURM_JOB_ID:-}" ]; then
    echo "REFUSED: head-node execution is not permitted; submit via sbatch." >&2
    exit 64
fi
case "\$SLURM_JOB_ID" in
    ''|*[!0-9]*) echo "REFUSED: SLURM_JOB_ID is not a positive integer" >&2; exit 64;;
esac

G4WORK=$P2_G4WORK
RUNROOT="\$G4WORK/g4-diag/\${SLURM_JOB_ID}/lw-p2"
P1CHECKER="\$RUNROOT/tools/gate4_p1_splice_checker.jl"
P2CHECKER="\$RUNROOT/tools/gate4_p2_hard_objective_checker.jl"

echo "=== P2-lw stage 0a: gate-code identity (verify BEFORE sourcing) ==="
sha256sum -c <<'GATEPINS' || { echo "REFUSED: gate code/reviewed prerequisite changed since generation; regenerate the checkpoint" >&2; exit 75; }
$gate_pins
GATEPINS

echo "=== P2-lw stage 0b: quota health (read-only; 50 GiB soft-quota headroom) ==="
source $P2_PROJECT_ROOT/validation/gate4_quota_guard.sh
quota_health \$((50*1024*1024*1024)) || { echo "REFUSED: quota not healthy (need soft-quota minus 50 GiB headroom)" >&2; exit 67; }

echo "=== P2-lw stage 0c: stage-0 preflight pins (live reads lawful HERE ONLY, pre-freeze) ==="
sha256sum -c <<'HASHES' || { echo "REFUSED: pinned master/env hash mismatch" >&2; exit 69; }
$P2_INIT_SHA  $P2_INIT_PATH
$P2_PLATEAU_SHA  $P2_PLATEAU_PATH
$P2_PUB_SHA  $P2_PUB_PATH
$P2_SW_SHA  $P2_SW_PATH
HASHES
sha256sum -c <<'PKGPRE' >/dev/null || { echo "REFUSED: live package-tree/evaluator-chain/reference preflight mismatch" >&2; exit 69; }
$(join(["$(e.sha)  $P2_PROJECT_ROOT/$(e.rel)" for e in pkg], "\n"))
PKGPRE
while read -r xf rel; do
    if [ "\$xf" = 1 ]; then
        [ -x "$P2_PROJECT_ROOT/\$rel" ] || { echo "REFUSED: source pkg exec bit lost: \$rel" >&2; exit 69; }
    else
        [ ! -x "$P2_PROJECT_ROOT/\$rel" ] || { echo "REFUSED: source pkg exec bit gained: \$rel" >&2; exit 69; }
    fi
done <<'PKGEXECSRC'
$pkg_exec_rows
PKGEXECSRC
[ "\$(find "$P2_PROJECT_ROOT/src" "$P2_PROJECT_ROOT/ext" -type f | wc -l)" = "$(count(e -> startswith(e.rel, "src/") || startswith(e.rel, "ext/"), pkg))" ] || { echo "REFUSED: live src/ext census != manifest (injected/missing file in the declared scope)" >&2; exit 69; }
[ "\$(find "$P2_PROJECT_ROOT/src" "$P2_PROJECT_ROOT/ext" -type l | wc -l)" = 0 ] || { echo "REFUSED: symlink in the scoped live source set" >&2; exit 69; }
JULIA_BIN=$P2_JULIA_BIN
[ -x "\$JULIA_BIN" ] || { echo "REFUSED: pinned julia launcher missing/not executable: \$JULIA_BIN" >&2; exit 65; }
JL_FULL=\$("\$JULIA_BIN" --version); JL_L1=\${JL_FULL%%\$'\\n'*}
[ "\$JL_L1" = "$P2_JULIA_VERSION_LINE" ] || { echo "REFUSED: julia version line '\$JL_L1' != pinned '$P2_JULIA_VERSION_LINE'" >&2; exit 65; }

echo "=== P2-lw stage 0d: P2 experiment lock ==="
mkdir -p "\$G4WORK/locks"
exec 9>"\$G4WORK/locks/p2-lw.lock"
flock -n 9 || { echo "REFUSED: another P2-lw diagnosis job holds the lock" >&2; exit 73; }

echo "=== P2-lw stage 1: copy live->RUNROOT with IMMEDIATE verification, then FREEZE (staging read bracket) ==="
[ ! -e "\$RUNROOT" ] || { echo "REFUSED: RUNROOT already exists: \$RUNROOT" >&2; exit 72; }
mkdir -p "\$RUNROOT/source-inputs" "\$RUNROOT/julia-env" "\$RUNROOT/tools" "\$RUNROOT/splice" "\$RUNROOT/pkg"
while read -r esha esz src dst; do
    cp -L -- "\$src" "\$dst" || { echo "REFUSED: staging copy failed: \$src" >&2; exit 76; }
    asz=\$(stat -Lc %s "\$dst") || { echo "REFUSED: cannot stat staged copy \$dst" >&2; exit 76; }
    [ "\$asz" = "\$esz" ] || { echo "REFUSED: staged copy size mismatch \$dst (\$asz != \$esz)" >&2; exit 76; }
    echo "\$esha  \$dst" | sha256sum -c - >/dev/null || { echo "REFUSED: staged copy hash mismatch: \$dst" >&2; exit 76; }
done <<STAGE
$stage_lines
STAGE
while read -r esha esz src dst; do
    mkdir -p "\$(dirname "\$dst")"
    cp -L -- "\$src" "\$dst" || { echo "REFUSED: pkg staging copy failed: \$src" >&2; exit 76; }
    asz=\$(stat -Lc %s "\$dst") || { echo "REFUSED: cannot stat staged pkg file \$dst" >&2; exit 76; }
    [ "\$asz" = "\$esz" ] || { echo "REFUSED: staged pkg size mismatch \$dst" >&2; exit 76; }
    echo "\$esha  \$dst" | sha256sum -c - >/dev/null || { echo "REFUSED: staged pkg hash mismatch: \$dst" >&2; exit 76; }
done <<PKGSTAGE
$pkg_rows
PKGSTAGE
[ "\$(find "\$RUNROOT/pkg" -type f | wc -l)" = "$pkg_census" ] || { echo "REFUSED: staged pkg census != $pkg_census (injected/missing file)" >&2; exit 76; }
while read -r xf rel; do
    if [ "\$xf" = 1 ]; then
        [ -x "\$RUNROOT/pkg/\$rel" ] || { echo "REFUSED: staged pkg exec bit lost: \$rel" >&2; exit 76; }
    else
        [ ! -x "\$RUNROOT/pkg/\$rel" ] || { echo "REFUSED: staged pkg exec bit gained: \$rel" >&2; exit 76; }
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
echo "$P2_P1_CHECKER_SHA  \$P1CHECKER" | sha256sum -c - >/dev/null || { echo "REFUSED: staged P1 checker hash mismatch" >&2; exit 76; }
cp -- "$P2_PROJECT_ROOT/$P2_CHECKER_REPO" "\$P2CHECKER"
echo "$checker_sha  \$P2CHECKER" | sha256sum -c - >/dev/null || { echo "REFUSED: staged P2 checker hash mismatch" >&2; exit 76; }
MI="\$RUNROOT/source-inputs/init.nc"
MPL="\$RUNROOT/source-inputs/plateau.nc"
MPUB="\$RUNROOT/source-inputs/published.nc"
MSW="\$RUNROOT/source-inputs/sw.nc"
JENV="\$RUNROOT/julia-env"
chmod -R a-w "\$RUNROOT/source-inputs" "\$RUNROOT/julia-env" "\$RUNROOT/pkg" "\$RUNROOT/tools"
WLIST=\$(find "\$RUNROOT/source-inputs" "\$RUNROOT/julia-env" "\$RUNROOT/pkg" "\$RUNROOT/tools" -writable) || { echo "REFUSED: writable-entry scan failed on the staged trees" >&2; exit 76; }
[ -z "\$WLIST" ] || { echo "REFUSED: writable entries remain in the staged trees after the freeze" >&2; printf '%s\\n' "\$WLIST" >&2; exit 76; }
echo "STAGE-1 FREEZE COMPLETE: all EXPLICIT evaluator/checker/scientific input PATHS resolve inside \$RUNROOT from here on (live-depot package-load metadata remains the recorded residual)"
export JULIA_LOAD_PATH="@:\$RUNROOT/pkg:@stdlib"
export NUMERICAL_RADIATION_VALIDATION_REFERENCE_DIR="\$RUNROOT/pkg/validation/reference"
export P2C_CHAIN_DIR="\$RUNROOT/pkg/validation"
export P2C_P1_CHECKER="\$P1CHECKER"

echo "=== P2-lw stage 2: in-RUNROOT splice reconstruction from STAGED masters (the splice is NOT a master) ==="
"\$JULIA_BIN" --project="\$JENV" "\$P1CHECKER" build-splice "\$MI" "\$MPUB" "\$RUNROOT/splice/splice_input.nc" || { echo "REFUSED: splice construction failed (fail-closed)" >&2; exit 77; }
"\$JULIA_BIN" --project="\$JENV" "\$P1CHECKER" gate-splice "\$RUNROOT/splice/splice_input.nc" "\$MI" "\$MPUB" || { echo "REFUSED: splice integrity gate failed (exact eight-variable typed diff / published equality / pinned counts / attrs / signature)" >&2; exit 77; }
"\$JULIA_BIN" --project="\$JENV" "\$P1CHECKER" gate-plateau "\$MPL" "\$MI" || { echo "REFUSED: plateau state gate failed (four-active pinned counts / minor-four exact equality / signature)" >&2; exit 77; }
SPLICE_SHA=\$(sha256sum "\$RUNROOT/splice/splice_input.nc" | cut -d' ' -f1)
echo "splice runtime content sha (PRIVATE in-RUNROOT state; recorded, never canonical): \$SPLICE_SHA"
chmod a-w "\$RUNROOT/splice/splice_input.nc"

echo "=== P2-lw stage 3: residual-label license assessment + fourteen-field inventory (staged evaluator) ==="
"\$JULIA_BIN" --project="\$JENV" "\$P2CHECKER" license "\$MI" "\$MPL" "\$RUNROOT/splice/splice_input.nc" "\$MPUB" "\$MSW" |& tee "\$RUNROOT/p2-license.log" || { echo "REFUSED: license/inventory gates failed (fieldnames/gas-ordering/fixed-SW equality)" >&2; exit 78; }

echo "=== P2-lw stage 4: EIGHT palindromic arms (fresh load each; ONE immutable staged evaluator) ==="
for arm in $P2_ARM_LIST; do
    echo "=== P2-lw stage 4-\$arm ==="
$arm_state_case
    "\$JULIA_BIN" --project="\$JENV" "\$P2CHECKER" arm "\$LW" "\$MSW" "\$RUNROOT/\$arm-record.txt" "\$arm" "\$LSHA" "$P2_SW_SHA" |& tee "\$RUNROOT/\$arm-arm.log" || { echo "REFUSED: arm \$arm evaluation/instrument gates failed" >&2; exit 71; }
    [ "\$(grep -cF 'P2C PASS: arm' "\$RUNROOT/\$arm-arm.log" || true)" = 1 ] || { echo "REFUSED: arm \$arm pass line not exactly once" >&2; exit 71; }
done

echo "=== P2-lw stage 5: duplicate/control/branch comparison (bit-exact payloads; controls refuse interpretation on miss) ==="
"\$JULIA_BIN" --project="\$JENV" "\$P2CHECKER" compare "\$RUNROOT" |& tee "\$RUNROOT/p2-compare.log" || { echo "REFUSED: duplicate/control/branch gates failed (drift recorded; ordering assignment refused; values never averaged)" >&2; exit 74; }

echo "=== P2-lw stage 6: post-run no-mutation reverification (every staged input) + inventory ==="
sha256sum -c <<POSTMASTERS >/dev/null || { echo "REFUSED: staged master/env drifted during the runs (target-defining input mutation)" >&2; exit 79; }
$post_masters
POSTMASTERS
sha256sum -c <<POSTPKG >/dev/null || { echo "REFUSED: staged package tree/evaluator chain/reference drifted during the runs" >&2; exit 79; }
$post_pkg
POSTPKG
[ "\$(find "\$RUNROOT/pkg" -type f | wc -l)" = "$pkg_census" ] || { echo "REFUSED: post-run staged pkg census != $pkg_census (injected/missing file)" >&2; exit 79; }
while read -r xf rel; do
    if [ "\$xf" = 1 ]; then
        [ -x "\$RUNROOT/pkg/\$rel" ] || { echo "REFUSED: post-run staged pkg exec bit lost: \$rel" >&2; exit 79; }
    else
        [ ! -x "\$RUNROOT/pkg/\$rel" ] || { echo "REFUSED: post-run staged pkg exec bit gained: \$rel" >&2; exit 79; }
    fi
done <<'PKGEXEC2'
$pkg_exec_rows
PKGEXEC2
echo "$P2_P1_CHECKER_SHA  \$P1CHECKER" | sha256sum -c - >/dev/null || { echo "REFUSED: staged P1 checker drifted during the runs" >&2; exit 79; }
echo "$checker_sha  \$P2CHECKER" | sha256sum -c - >/dev/null || { echo "REFUSED: staged P2 checker drifted during the runs" >&2; exit 79; }
echo "\$SPLICE_SHA  \$RUNROOT/splice/splice_input.nc" | sha256sum -c - >/dev/null || { echo "REFUSED: in-RUNROOT splice drifted during the runs" >&2; exit 79; }
WLIST2=\$(find "\$RUNROOT/source-inputs" "\$RUNROOT/julia-env" "\$RUNROOT/pkg" "\$RUNROOT/tools" -writable) || { echo "REFUSED: post-run writable-entry scan failed" >&2; exit 79; }
[ -z "\$WLIST2" ] || { echo "REFUSED: writable entries appeared in the staged trees during the runs" >&2; printf '%s\\n' "\$WLIST2" >&2; exit 79; }
echo "staged inputs re-verified post-run (masters+SW, julia-env, full package tree/chain/references, both checkers, splice; no-mutation evidence for same-input comparison) -- ZERO canonical writes by design"
for arm in $P2_ARM_LIST; do
    sha256sum "\$RUNROOT/\$arm-record.txt" "\$RUNROOT/\$arm-arm.log"
done
sha256sum "\$RUNROOT/splice/splice_input.nc" "\$RUNROOT/p2-license.log" "\$RUNROOT/p2-compare.log"
echo "RUNROOT preserved for diagnosis/forensics: \$RUNROOT (no cleanup by design)"
echo "=== P2-lw done \$(date -u +%FT%TZ) ==="
"""
end

# --- text gates -----------------------------------------------------------------

function p2_bash_syntax_ok(text)
    try
        p = joinpath(mktempdir(), "p2_syntax_check.sbatch")
        write(p, text)
        success(pipeline(`bash -n $p`, stdout = devnull, stderr = devnull))
    catch
        false
    end
end

function p2_text_gate_issues(text)
    iss = String[]
    req = [
        "REFUSED: head-node execution is not permitted",
        "RUNROOT=\"\$G4WORK/g4-diag/\${SLURM_JOB_ID}/lw-p2\"",
        P2_DESIGN_SHA, P2_P1_CHECKER_SHA,
        P2_INIT_SHA, P2_PLATEAU_SHA, P2_PUB_SHA, P2_SW_SHA,
        "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc",
        "quota_health \$((50*1024*1024*1024))",
        "locks/p2-lw.lock",
        "JULIA_BIN=$P2_JULIA_BIN",
        P2_JULIA_VERSION_LINE,
        "STAGE-1 FREEZE COMPLETE",
        "export JULIA_LOAD_PATH=\"@:\$RUNROOT/pkg:@stdlib\"",
        "export NUMERICAL_RADIATION_VALIDATION_REFERENCE_DIR=\"\$RUNROOT/pkg/validation/reference\"",
        "export P2C_CHAIN_DIR=\"\$RUNROOT/pkg/validation\"",
        "the splice is NOT a master",
        "build-splice \"\$MI\" \"\$MPUB\" \"\$RUNROOT/splice/splice_input.nc\"",
        "gate-plateau \"\$MPL\" \"\$MI\"",
        "license \"\$MI\" \"\$MPL\" \"\$RUNROOT/splice/splice_input.nc\" \"\$MPUB\" \"\$MSW\"",
        "compare \"\$RUNROOT\"",
        "REFUSED: staged pkg hash mismatch",
        "REFUSED: staged package tree/evaluator chain/reference drifted during the runs",
        "REFUSED: staged master/env drifted during the runs (target-defining input mutation)",
        "REFUSED: duplicate/control/branch gates failed (drift recorded; ordering assignment refused; values never averaged)",
        "ZERO canonical writes by design",
        "RUNROOT preserved for diagnosis/forensics",
        "GATEPINS", "HASHES", "PKGPRE", "STAGE", "PKGSTAGE", "JENVPINS",
        "POSTMASTERS", "POSTPKG", "PKGEXECSRC", "PKGEXEC", "PKGEXEC2",
        "\$RUNROOT/pkg/Artifacts.toml",
        "REFUSED: staged pkg census != ",
        "REFUSED: post-run staged pkg census != ",
        "REFUSED: staged pkg exec bit lost",
        "REFUSED: post-run staged pkg exec bit lost",
        "REFUSED: live src/ext census != manifest (injected/missing file in the declared scope)",
        "REFUSED: symlink in the scoped live source set",
        "init-*) LW=\"\$MI\"; LSHA=$P2_INIT_SHA;;",
        "plateau-*) LW=\"\$MPL\"; LSHA=$P2_PLATEAU_SHA;;",
        "splice-*) LW=\"\$RUNROOT/splice/splice_input.nc\"; LSHA=\"\$SPLICE_SHA\";;",
        "published-*) LW=\"\$MPUB\"; LSHA=$P2_PUB_SHA;;",
        "arm \"\$LW\" \"\$MSW\" \"\$RUNROOT/\$arm-record.txt\" \"\$arm\" \"\$LSHA\" \"$P2_SW_SHA\"",
        "all EXPLICIT evaluator/checker/scientific input PATHS resolve inside \$RUNROOT",
        "live-depot package-load metadata remains the recorded residual"]
    for r in req
        occursin(r, text) || push!(iss, "required text missing: $r")
    end
    for (pat, n, what) in (
        (Regex("\\Qfor arm in $P2_ARM_LIST; do\\E"), 2,
         "palindromic arm loops (runs + record hash echoes)"),
        (Regex("\\Q\"\$JULIA_BIN\" --project=\"\$JENV\"\\E"), 6,
         "staged-env julia invocations (3 splice/plateau + license + arm + compare)"),
        (Regex("\\Qsha256sum -c <<\\E"), 6,
         "sha heredoc gates (GATEPINS/HASHES/PKGPRE/JENVPINS/POSTMASTERS/POSTPKG)"),
        (Regex("\\QSPLICE_SHA=\\E"), 1, "splice sha capture"),
        (Regex("(?m)^[ \\t]+\\Q\"\$JULIA_BIN\" --project=\"\$JENV\" \"\$P2CHECKER\" arm \"\$LW\" \"\$MSW\" \"\$RUNROOT/\$arm-record.txt\" \"\$arm\" \"\$LSHA\" \"$P2_SW_SHA\"\\E[^\\n]*\$"), 1,
         "full arm CLI invocation (anchored active line)"),
        (Regex("(?m)^[ \\t]+\\Qinit-*) LW=\"\$MI\"; LSHA=$P2_INIT_SHA;;\\E\$"), 1,
         "init arm-to-state mapping (active line)"),
        (Regex("(?m)^[ \\t]+\\Qplateau-*) LW=\"\$MPL\"; LSHA=$P2_PLATEAU_SHA;;\\E\$"), 1,
         "plateau arm-to-state mapping"),
        (Regex("(?m)^[ \\t]+\\Qsplice-*) LW=\"\$RUNROOT/splice/splice_input.nc\"; LSHA=\"\$SPLICE_SHA\";;\\E\$"), 1,
         "splice arm-to-state mapping"),
        (Regex("(?m)^[ \\t]+\\Qpublished-*) LW=\"\$MPUB\"; LSHA=$P2_PUB_SHA;;\\E\$"), 1,
         "published arm-to-state mapping"))
        m = length(collect(eachmatch(pat, text)))
        m == n || push!(iss, "$what expected exactly $n, got $m")
    end
    for bad in ("ecckd-1.0_sw", "g4-diag/4567", "--project=test",
                "cd $P2_PROJECT_ROOT &&", "CANON_FINAL", "mv -n",
                ".g3.publish.", "bit-exact J0", "published floor",
                "recovered-upstream", "optimize_lut")
        occursin(bad, text) && push!(iss, "forbidden text present: $bad")
    end
    # no-external-splice-path: splice may only ever be $RUNROOT-resident
    for m in eachmatch(r"(?m)^.*splice[^\n]*$", text)
        line = m.match
        (occursin("splice_input.nc", line) &&
         !occursin("\$RUNROOT/splice/splice_input.nc", line)) &&
            push!(iss, "splice referenced outside \$RUNROOT: $line")
    end
    # exactly-once freeze marker + post-freeze live-path segment scan
    # (monitor addendum C; Agent 42 exactly-once refinement)
    marks = length(collect(eachmatch(r"STAGE-1 FREEZE COMPLETE", text)))
    marks == 1 ||
        push!(iss, "STAGE-1 FREEZE COMPLETE marker not exactly once ($marks); split point ambiguous")
    if marks == 1
        post = split(text, "STAGE-1 FREEZE COMPLETE"; limit = 2)[2]
        for bad in (P2_PROJECT_ROOT, P2_INIT_PATH, P2_PLATEAU_PATH,
                    P2_PUB_PATH, P2_SW_PATH, P2_TEST_PROJECT,
                    P2_TEST_MANIFEST, "--project=test",
                    "/.julia/artifacts/")
            occursin(bad, post) &&
                push!(iss, "post-freeze live-path reference: $bad")
        end
    end
    for m in eachmatch(r"\|\s*head\b", text)
        push!(iss, "early-closing head pipeline present: $(m.match)")
    end
    for m in eachmatch(r"(?m)^[^#\n]*> *\"?\$G4WORK/(?!g4-diag|locks/p2-lw\.lock)", text)
        push!(iss, "redirect toward shared G4WORK area: $(m.match)")
    end
    iss
end

# instrument-identity evidence (monitor second review hold): the
# same-instrument claim is GATED, not prose -- mechanical region
# extraction + fragment containment for hard_objective, case_metrics,
# the REDUCED_CASES/REQUIRED_CASES link, and the committed S1
# sl_swap_objective kernel (call shape + case-input tuple + SL_H2O);
# region hashes exposed in the checkpoint JSON; parameterized so
# mutation fixtures exercise the real extraction paths.
const P2_S1_SRC_REL = "validation/gate4_s1_state_sync_completion_ledger.jl"
# frozen expected region SHAs (monitor delta-implementation hold:
# regions are extracted with unambiguous boundaries -- header to the
# next column-0 `end` for functions, explicit closers for consts --
# COMPARED against these hard-coded constants frozen from the reviewed
# sources, with required fragments evaluated INSIDE the regions)
const P2_EXPECT_REGIONS = Dict(
    "hard_objective" => "4b784c16d1e85a5b1647e59680f84e510d4da6fc2d84b136dbb51e2ed39fef5f",
    "case_metrics" => "96bfed7d3b24b5dda59a3684ffde5b18d70f5a8e64248bc988bd8dd746bf43df",
    "s1_kernel" => "c80b7bc54c8b34908be3ffb39ef3847956847e102a57847c21dfd5a629d141ba",
    "required_cases" => "4925ba0a844823e1e5e745918c3b8ec39796dd784f571f75364430a0db78f5ef",
    "reduced_link" => "04ecb565d56459da23d519da506d9298ff9af76b8de03a9502f6748f08e083ef",
    "sl_case_inputs" => "4b2a0401b6baded30dc5fda074c99ec9b130d79a7343583f6bb2ba7053131480",
    "p2c_rows_mirror" => "17a8d8dcc803475639ef34668b5a1b23211547129a681b849188575ec331f645",
    "reduced_cases_binding_line" => "150915e65fcae11d7d31465f68c2c4c7ddda53a216a85408a7878c7ce5ceab67",
    "official_gases_line" => "b267b0c693f908e3b86169463d31d61d0b99d31ed763f9b9bf182ef18a29b4c1",
    "sl_h2o_line" => "340e928f103481494b140d09d03353715477e2854d1394517b2abcda0c9c3477",
    "p2c_gases_line" => "8eb801ca67b051705fc0005c4c22073785d5189a4b3ef2734d2ec93f4d6a4485",
    "p2c_h2o_line" => "ac762498ac94ccfa6ae42bb219a93b89b65b0456513beb41a7b200eae334c7ee",
    "p2c_arm_record" => "78bb92816cbaeaa406b8d368bb11e18dc78e9cf843883333da8b7108ae434504")
# anchored active-line extraction (exactly-once; a comment decoy can
# neither satisfy nor duplicate it)
function p2_line_region(text, re, label, iss)
    ms = collect(eachmatch(re, text))
    length(ms) == 1 ||
        (push!(iss, "$label active line not exactly once ($(length(ms)))");
         return nothing)
    String(ms[1].match)
end
function p2_extract_region(text, startfrag, endpat, label, iss)
    i = findfirst(startfrag, text)
    i === nothing && (push!(iss, "$label region start not found");
                      return nothing)
    j = findnext(endpat, text, last(i))
    j === nothing && (push!(iss, "$label region end not found");
                      return nothing)
    text[first(i):last(j)]
end
function p2_instrument_identity(;
        acc = joinpath(P2_PROJECT_ROOT, "validation", "ecckd_published_model_accuracy.jl"),
        red = joinpath(P2_PROJECT_ROOT, "validation", "reduced_ecckd_accuracy.jl"),
        erm = joinpath(P2_PROJECT_ROOT, "validation", "ecrad_reference_manifest.jl"),
        wec = joinpath(P2_PROJECT_ROOT, "validation", "write_ecrad_candidates.jl"),
        s1 = joinpath(P2_PROJECT_ROOT, P2_S1_SRC_REL),
        p2c = joinpath(P2_PROJECT_ROOT, P2_CHECKER_REPO))
    iss = String[]
    pins = Dict{String, Any}()
    e0 = r"(?m)^end$"
    specs = [
        ("hard_objective", read(acc, String),
         "function hard_objective(cases)", e0,
         ["metric = \"\$(variable)_rmse\"", "metric = \"\$(variable)_max_abs\"",
          "metric = \"heating_rate_rmse\"", "metric = \"heating_rate_max_abs\"",
          "metric = \"toa_forcing\"", "metric = \"surface_forcing\"",
          "worst = argmax(row -> row.normalized_value, rows)"]),
        ("case_metrics", read(red, String),
         "function case_metrics(case, gas_optics)", e0, String[]),
        ("s1_kernel", read(s1, String),
         "function sl_swap_objective(lw_path, sw_path, cases)", e0,
         ["gas_names = OFFICIAL_ECCKD_GASES, h2o_mole_fraction = SL_H2O)",
          "hard_objective([case_metrics(c, model) for c in cases]).value",
          "read_ecckd_tabulated_gas_optics(lw_path, sw_path;"]),
        ("required_cases", read(erm, String),
         "const REQUIRED_CASES = (", r"(?m)^\)",
         ["ecckd_clear_sky_tropical_column", "ecckd_rcemip_style_column_subset"]),
        ("reduced_link", read(red, String),
         "const REDUCED_CASE_NAMES = (", r"(?m)^\)",
         ["ecckd_clear_sky_tropical_column", "ecckd_rcemip_style_column_subset"]),
        ("sl_case_inputs", read(s1, String),
         "const SL_CASE_INPUTS = [", r"\)\]",
         ["ecckd_clear_sky_tropical_column", "ecckd_rcemip_style_column_subset",
          "207210", "3a1634b7c7b4e22ae4064ace9826ac76b6810fb4074a5437bfd30b5c911e68e7"]),
        ("p2c_rows_mirror", read(p2c, String),
         "function p2c_rows(cases)", e0,
         ["heating_rate_rmse", "toa_forcing", "surface_forcing"])]
    for (label, text, startfrag, endpat, frags) in specs
        r = p2_extract_region(text, startfrag, endpat, label, iss)
        r === nothing && continue
        got = bytes2hex(sha256(r))
        pins[label] = Dict("expected" => P2_EXPECT_REGIONS[label],
                           "observed" => got)
        got == P2_EXPECT_REGIONS[label] ||
            push!(iss, "$label region sha $got != frozen expected " *
                  P2_EXPECT_REGIONS[label] * " (body drift refused)")
        for f in frags
            occursin(f, r) ||
                push!(iss, "$label required fragment missing INSIDE region: $f")
        end
    end
    # anchored active-line pins (no global occursin decoys): the actual
    # binding/constant lines plus the PRODUCTION P2 constants and the
    # complete p2c_arm_record region (pinning the S1 kernel proves the
    # authority; these prove P2 EXECUTES the same shape)
    for (label, text, re, frag) in (
        ("reduced_cases_binding_line", read(red, String),
         r"(?m)^const REDUCED_CASES = .*$", "REQUIRED_CASES"),
        ("official_gases_line", read(wec, String),
         r"(?m)^const OFFICIAL_ECCKD_GASES = .*$", ":composite"),
        ("sl_h2o_line", read(s1, String),
         r"(?m)^const SL_H2O = .*$", "0.005"),
        ("p2c_gases_line", read(p2c, String),
         r"(?m)^const P2C_GASES = .*$", ":composite"),
        ("p2c_h2o_line", read(p2c, String),
         r"(?m)^const P2C_H2O = .*$", "0.005"))
        l = p2_line_region(text, re, label, iss)
        l === nothing && continue
        got = bytes2hex(sha256(l))
        pins[label] = Dict("expected" => P2_EXPECT_REGIONS[label],
                           "observed" => got)
        got == P2_EXPECT_REGIONS[label] ||
            push!(iss, "$label sha $got != frozen expected (drift refused)")
        occursin(frag, l) ||
            push!(iss, "$label required fragment missing INSIDE line: $frag")
    end
    let r = p2_extract_region(read(p2c, String),
            "function p2c_arm_record(lw_path, sw_path, label, lw_sha, sw_sha)",
            r"(?m)^end$", "p2c_arm_record", iss)
        if r !== nothing
            got = bytes2hex(sha256(r))
            pins["p2c_arm_record"] = Dict(
                "expected" => P2_EXPECT_REGIONS["p2c_arm_record"],
                "observed" => got)
            got == P2_EXPECT_REGIONS["p2c_arm_record"] ||
                push!(iss, "p2c_arm_record region sha $got != frozen " *
                      "expected (body drift refused)")
            for f in ("gas_names = P2C_GASES, h2o_mole_fraction = P2C_H2O",
                      "REDUCED_CASES", "hard_objective(metrics)")
                occursin(f, r) ||
                    push!(iss, "p2c_arm_record required fragment missing " *
                          "INSIDE region: $f")
            end
        end
    end
    pins["s1_source_sha256"] = bytes2hex(sha256(read(s1)))
    (iss, pins)
end

# live source-scope census# live source-scope census (monitor review hold): the walked roots
# src/ + ext/ are counted mechanically against the manifest BEFORE
# staging -- an injected live file in scope must refuse at stage 0;
# chain/reference/root files are enumerated-by-name scope (sha-gated
# individually). Used at generation AND mirrored as an in-job gate.
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

# --- staged-form behavioral probe (monitor hard hold: a text gate is
# insufficient; this executes the RENDERED staged set + invocation form
# in a temp tree and proves staged package/extension/reader resolution)
function p2_staged_form_probe(pkg; omit_artifacts = false)
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
    # RENDERED scientific invocation (monitor third delta): stage the
    # pinned published LW + SW masters and ACTUALLY call the reader on
    # the staged paths with the canonical eight-gas tuple + H2O=0.005,
    # asserting reader OUTPUT, not just load/extension/hasmethod
    lwp = joinpath(tmp, "source-inputs", "published.nc")
    swp = joinpath(tmp, "source-inputs", "sw.nc")
    mkpath(dirname(lwp))
    cp(P2_PUB_PATH, lwp)
    cp(P2_SW_PATH, swp)
    probe = "using NumericalRadiation, NCDatasets; " *
        "ok1 = startswith(pathof(NumericalRadiation), raw\"$pkgdir\"); " *
        "ok2 = Base.get_extension(NumericalRadiation, " *
        ":NumericalRadiationNCDatasetsExt) !== nothing; " *
        "m = NumericalRadiation.read_ecckd_tabulated_gas_optics(" *
        "raw\"$lwp\", raw\"$swp\"; gas_names = (:composite, :h2o, " *
        ":o3, :co2, :ch4, :n2o, :cfc11, :cfc12), " *
        "h2o_mole_fraction = 0.005); " *
        "ok3 = length(fieldnames(typeof(m))) == 14 && " *
        "size(m.longwave_absorption, 2) == 8; " *
        "println(\"P2PROBE \", ok1 && ok2 && ok3)"
    cmd = addenv(`$P2_JULIA_BIN --project=$envdir -e $probe`,
                 "JULIA_LOAD_PATH" => "@:$pkgdir:@stdlib")
    out = try
        read(pipeline(cmd; stderr = devnull), String)
    catch
        ""
    end
    occursin("P2PROBE true", out)
end

# --- fixtures --------------------------------------------------------------------

function p2_fixtures(pkg, text)
    t = Dict{String, Bool}()
    tg(x) = p2_text_gate_issues(x)
    # mirrored row construction on synthetic case metrics
    mkvar(r, m) = (rmse = r, max_abs = m)
    mkcase(name, k) = (case = name,
        variables = (lw_up = mkvar(1.0k, 2.0k), lw_down = mkvar(3.0k, 4.0k),
                     sw_up = mkvar(5.0k, 6.0k), sw_down = mkvar(7.0k, 8.0k),
                     heating_rate = mkvar(9.0k, 10.0k)),
        toa_forcing_max_abs = 11.0k, surface_forcing_max_abs = 12.0k)
    cases = [mkcase("caseA", 1.0), mkcase("caseB", 2.0)]
    rows = p2c_rows(cases)
    t["rows_24_exact"] = length(rows) == 24
    t["rows_key_order_exact"] =
        [(String(r.case), String(r.metric)) for r in rows] ==
        [(c, m) for c in ("caseA", "caseB") for m in P2C_METRIC_SEQ]
    t["row_line_has_8_fields"] =
        count(==('|'), p2c_row_line(rows[1])) == 7
    # payload/label machinery
    reca = "arm_label=init-a\nlw_sha=x\nsw_sha=y\ninvocation=z\n" *
           "objective_token=1\nobjective_bits=" * p2c_bits(1.0) * "\n"
    recb = replace(reca, "arm_label=init-a" => "arm_label=init-b")
    t["payload_excludes_label"] = p2c_payload(reca) == p2c_payload(recb)
    t["label_parse"] = p2c_arm_label(reca) == "init-a"
    recs = Dict{String, String}()
    for arm in P2C_ARMS
        st = p2c_state(arm)
        v = Dict("init" => 102.67056437657112,
                 "plateau" => 22.791293464348826,
                 "splice" => 30.5,
                 "published" => 0.18218645425029933)[st]
        recs[arm] = "arm_label=$arm\nstate=$st\nlw_sha=sha_$st\nsw_sha=swsha\n" *
            "invocation=inv\nobjective_token=" * p2c_tok(v) *
            "\nobjective_bits=" * p2c_bits(v) * "\n"
    end
    t["duplicates_pass_on_equal_payloads"] =
        isempty(p2c_duplicate_issues(recs))
    t["duplicate_drift_refuses"] = begin
        r2 = copy(recs)
        r2["splice-b"] = replace(r2["splice-b"],
            "objective_bits=" * p2c_bits(30.5) =>
            "objective_bits=" * p2c_bits(nextfloat(30.5)))
        any(occursin("duplicate scientific payloads", i)
            for i in p2c_duplicate_issues(r2))
    end
    t["label_mapping_violation_refuses"] = begin
        r2 = copy(recs)
        r2["init-b"] = replace(r2["init-b"],
                               "arm_label=init-b" => "arm_label=splice-b")
        any(occursin("arm-label/state mapping violation", i)
            for i in p2c_duplicate_issues(r2))
    end
    t["controls_pass_on_pinned_values"] =
        isempty(p2c_control_issues(recs))
    t["control_miss_refuses"] = begin
        r2 = copy(recs)
        for arm in ("plateau-a", "plateau-b")
            r2[arm] = replace(r2[arm], p2c_bits(22.791293464348826) =>
                              p2c_bits(22.791293464348828))
        end
        any(occursin("control reproduction gate MISS", i)
            for i in p2c_control_issues(r2))
    end
    t["control_double_line_refuses"] = begin
        r2 = copy(recs)
        r2["init-a"] *= "objective_bits=" *
            p2c_bits(102.67056437657112) * "\n"
        any(occursin("not exactly once", i)
            for i in p2c_control_issues(r2))
    end
    # branches (exact decimal; exhaustive partition)
    biss, bout = p2c_branches(recs)
    t["branches_emit_both_deltas"] = isempty(biss) &&
        any(occursin("D_splice_plateau=", o) for o in bout) &&
        any(occursin("D_splice_published=", o) for o in bout)
    t["branch_positive_exact"] =
        any(occursin("D_splice_published=30.31781354574970067", o) &&
            occursin("BRANCH=POSITIVE", o) for o in bout)
    t["branch_zero_on_equal_tokens"] = begin
        r2 = copy(recs)
        for arm in ("splice-a", "splice-b")
            r2[arm] = replace(r2[arm], p2c_tok(30.5) =>
                              p2c_tok(22.791293464348826))
        end
        _, b2 = p2c_branches(r2)
        any(occursin("ZERO-AT-TOKEN-REPRESENTATION", o) for o in b2)
    end
    t["branch_ceiling_line_present"] =
        any(occursin("P2 CEILING", o) for o in bout)
    # gas-axis contract (adversarial extent-8 on a non-gas axis)
    t["fields_tuple_is_fourteen"] = length(P2C_FIELDS) == 14
    t["metric_seq_is_twelve"] = length(P2C_METRIC_SEQ) == 12
    # gas-axis contract: REAL adversarial fixture (monitor addendum B)
    t["gas_axis_contract_real"] = begin
        adversarial = zeros(8, 2, 3, 4)   # extent 8 on a NON-gas axis only
        good = zeros(3, 8, 2, 4)
        amb = zeros(8, 8, 2, 4)           # extent 8 on axes 1 AND 2: contract picks 2
        sel = begin
            x = zeros(2, 8, 3, 4)
            x[:, 3, :, :] .= 1.0          # only gas index 3 differs
            y = zeros(2, 8, 3, 4)
            diffs = [count(a_ -> a_[1] !== a_[2],
                           zip(collect(selectdim(x, 2, gi)),
                               collect(selectdim(y, 2, gi))))
                     for gi in 1:8]
            diffs[3] > 0 && all(diffs[i] == 0 for i in 1:8 if i != 3)
        end
        !p2c_gas_axis_ok(adversarial) && p2c_gas_axis_ok(good) &&
            p2c_gas_axis_ok(amb) && sel
    end
    # staged-form behavioral fixtures (rendered set + rendered
    # invocation form; NOT a simplification -- subprocess execution)
    t["staged_form_loads_package_extension_reader"] =
        p2_staged_form_probe(pkg)
    t["staged_form_omitted_artifacts_refuses"] =
        !p2_staged_form_probe(pkg; omit_artifacts = true)
    t["text_cli_comment_decoy_refuses"] = !isempty(tg(replace(text,
        "    \"\$JULIA_BIN\" --project=\"\$JENV\" \"\$P2CHECKER\" arm " =>
        "    # \"\$JULIA_BIN\" --project=\"\$JENV\" \"\$P2CHECKER\" arm ")))
    t["identity_binding_line_decoy_refuses"] = begin
        fxd = mktempdir()
        redp = joinpath(P2_PROJECT_ROOT, "validation", "reduced_ecckd_accuracy.jl")
        q = joinpath(fxd, "red.mut")
        write(q, replace(read(redp, String),
            "const REDUCED_CASES = Tuple" =>
            "# const REDUCED_CASES = Tuple(case for case in REQUIRED_CASES if case.case in REDUCED_CASE_NAMES)\nconst REDUCED_CASES_X = Tuple"))
        iss2, _ = p2_instrument_identity(red = q)
        any(occursin("reduced_cases_binding_line active line not exactly once", i)
            for i in iss2)
    end
    t["identity_arm_record_drift_refuses"] = begin
        fxd = mktempdir()
        q = joinpath(fxd, "p2c.mut")
        write(q, replace(read(joinpath(P2_PROJECT_ROOT, P2_CHECKER_REPO), String),
            "    metrics = [case_metrics(c, model) for c in REDUCED_CASES]" =>
            "    nothing # drift\n    metrics = [case_metrics(c, model) for c in REDUCED_CASES]"))
        iss2, _ = p2_instrument_identity(p2c = q)
        any(occursin("p2c_arm_record region sha", i) for i in iss2)
    end
    t["tampered_manifest_refuses_via_pin_predicate"] = begin
        # routed THROUGH the rendered SHA/pin gate (the same check the
        # sbatch JENVPINS heredoc performs), never assuming TOML
        # tampering breaks package load
        tmpm = joinpath(mktempdir(), "Manifest.toml")
        write(tmpm, read(P2_TEST_MANIFEST, String) * "\n# tampered\n")
        pin = p2_sha(P2_TEST_MANIFEST)
        !success(pipeline(`sha256sum -c -`,
                          stdin = IOBuffer("$pin  $tmpm\n"),
                          stdout = devnull, stderr = devnull))
    end
    t["duplicate_arm_label_line_refuses"] = begin
        r2 = Dict("init-a" => "arm_label=init-a\narm_label=init-a\nx=1\n")
        any(occursin("arm_label lines != 1", i)
            for i in p2c_duplicate_issues(r2))
    end
    t["duplicate_objective_token_line_refuses"] = begin
        rec = "arm_label=STATE-a\nobjective_token=1.0\nobjective_token=1.0\n"
        r2 = Dict("$st-a" => replace(rec, "STATE" => st)
                  for st in P2C_STATES)
        for st in P2C_STATES
            r2["$st-b"] = replace(r2["$st-a"], "-a" => "-b")
        end
        iss2, _ = p2c_branches(r2)
        !isempty(iss2)
    end
    t["source_census_clean_passes_and_injected_refuses"] = begin
        tmpb = mktempdir()
        for e in pkg
            (startswith(e.rel, "src/") || startswith(e.rel, "ext/")) ||
                continue
            dst = joinpath(tmpb, e.rel)
            mkpath(dirname(dst))
            write(dst, "x")
        end
        clean = isempty(p2_source_census_issues(pkg; base = tmpb))
        write(joinpath(tmpb, "src", "injected_extra.jl"), "# injected")
        bad = any(occursin("injected/missing file", i)
                  for i in p2_source_census_issues(pkg; base = tmpb))
        clean && bad
    end
    t["text_missing_source_census_refuses"] = !isempty(tg(replace(text,
        "REFUSED: live src/ext census != manifest (injected/missing file in the declared scope)" =>
        "note")))
    t["instrument_identity_clean_passes"] =
        isempty(p2_instrument_identity()[1])
    t["instrument_identity_mutations_refuse"] = begin
        fxdir = mktempdir()
        function mut(src, from, to)
            q = joinpath(fxdir, basename(src) * ".mut")
            write(q, replace(read(src, String), from => to))
            q
        end
        accp = joinpath(P2_PROJECT_ROOT, "validation", "ecckd_published_model_accuracy.jl")
        redp = joinpath(P2_PROJECT_ROOT, "validation", "reduced_ecckd_accuracy.jl")
        wecp = joinpath(P2_PROJECT_ROOT, "validation", "write_ecrad_candidates.jl")
        s1p = joinpath(P2_PROJECT_ROOT, P2_S1_SRC_REL)
        r1 = !isempty(p2_instrument_identity(acc = mut(accp,
            "function hard_objective(cases)", "function hard_objectiveX(cases)"))[1])
        r2 = !isempty(p2_instrument_identity(acc = mut(accp,
            "worst = argmax(row -> row.normalized_value, rows)", "# gone"))[1])
        r3 = !isempty(p2_instrument_identity(red = mut(redp,
            "const REDUCED_CASES = Tuple(case for case in REQUIRED_CASES if case.case in REDUCED_CASE_NAMES)",
            "# link removed"))[1])
        r4 = !isempty(p2_instrument_identity(wec = mut(wecp,
            "const OFFICIAL_ECCKD_GASES = (:composite, :h2o, :o3, :co2, :ch4, :n2o, :cfc11, :cfc12)",
            "# tuple removed"))[1])
        r5 = !isempty(p2_instrument_identity(s1 = mut(s1p,
            "gas_names = OFFICIAL_ECCKD_GASES, h2o_mole_fraction = SL_H2O)",
            "gas_names = OTHER)"))[1])
        r1 && r2 && r3 && r4 && r5
    end
    t["text_splice_mapped_to_plateau_refuses"] = !isempty(tg(replace(text,
        "splice-*) LW=\"\$RUNROOT/splice/splice_input.nc\"; LSHA=\"\$SPLICE_SHA\";;" =>
        "splice-*) LW=\"\$MPL\"; LSHA=$P2_PLATEAU_SHA;;")))
    t["text_published_mapped_to_wrong_master_refuses"] = !isempty(tg(replace(text,
        "published-*) LW=\"\$MPUB\"; LSHA=$P2_PUB_SHA;;" =>
        "published-*) LW=\"\$MI\"; LSHA=$P2_INIT_SHA;;")))
    t["record_state_line_mismatch_refuses"] = begin
        r2 = Dict("init-a" => "arm_label=init-a\nstate=plateau\nx=1\n")
        any(occursin("record state line", i)
            for i in p2c_duplicate_issues(r2))
    end
    t["identity_body_drift_refuses_by_region_sha"] = begin
        fxd = mktempdir()
        accp = joinpath(P2_PROJECT_ROOT, "validation", "ecckd_published_model_accuracy.jl")
        q = joinpath(fxd, "acc.mut")
        write(q, replace(read(accp, String),
            "    worst = argmax(row -> row.normalized_value, rows)" =>
            "    nothing # innocuous drift preserving markers\n    worst = argmax(row -> row.normalized_value, rows)"))
        iss2, _ = p2_instrument_identity(acc = q)
        any(occursin("body drift refused", i) for i in iss2) &&
            !any(occursin("fragment missing", i) for i in iss2)
    end
    t["mirror_body_drift_refuses_by_region_sha"] = begin
        fxd = mktempdir()
        p2cp = joinpath(P2_PROJECT_ROOT, P2_CHECKER_REPO)
        q = joinpath(fxd, "p2c.mut")
        write(q, replace(read(p2cp, String),
            "function p2c_rows(cases)\n    rows = NamedTuple[]" =>
            "function p2c_rows(cases)\n    nothing # drift\n    rows = NamedTuple[]"))
        iss2, _ = p2_instrument_identity(p2c = q)
        any(occursin("p2c_rows_mirror region sha", i) for i in iss2)
    end
    t["tampered_pkg_artifacts_refuses_via_pin_predicate"] = begin
        fxd = mktempdir()
        q = joinpath(fxd, "Artifacts.toml")
        write(q, read(joinpath(P2_PROJECT_ROOT, "Artifacts.toml"), String) *
              "\n# tampered\n")
        pin = [e.sha for e in pkg if e.rel == "Artifacts.toml"][1]
        !success(pipeline(
            `sha256sum -c -`,
            stdin = IOBuffer("$pin  $q\n"), stdout = devnull,
            stderr = devnull))
    end
    t["text_comment_decoy_mapping_refuses"] = !isempty(tg(replace(text,
        "    init-*) LW=\"\$MI\"; LSHA=$P2_INIT_SHA;;" =>
        "    # init-*) LW=\"\$MI\"; LSHA=$P2_INIT_SHA;;")))
    t["record_duplicate_state_line_refuses"] = begin
        r2 = Dict("init-a" =>
            "arm_label=init-a\nstate=init\nstate=init\nx=1\n")
        any(occursin("state lines != 1", i)
            for i in p2c_duplicate_issues(r2))
    end
    t["pkg_manifest_includes_artifacts_toml"] =
        any(e -> e.rel == "Artifacts.toml", pkg)
    t["pkg_manifest_carries_exec_bits"] =
        all(haskey(pairs(e), :exec) || hasproperty(e, :exec) for e in pkg)
    # post-freeze live-read injections (both directions; clean text is
    # covered by text_good_accepted)
    t["text_postfreeze_live_master_read_refuses"] =
        !isempty(tg(text * "\ncat $P2_INIT_PATH\n"))
    t["text_postfreeze_live_repo_read_refuses"] =
        !isempty(tg(text * "\ncat $P2_PROJECT_ROOT/validation/x.jl\n"))
    t["text_duplicate_freeze_marker_refuses"] =
        !isempty(tg(text * "\necho STAGE-1 FREEZE COMPLETE\n"))
    t["text_missing_census_gate_refuses"] = !isempty(tg(replace(text,
        "REFUSED: staged pkg census != " => "note ")))
    t["text_missing_exec_gate_refuses"] =
        !isempty(tg(replace(text, "PKGEXEC" => "NOPE")))
    t["text_missing_postrun_census_refuses"] = !isempty(tg(replace(text,
        "REFUSED: post-run staged pkg census != " => "note ")))
    # pkg manifest sanity
    t["pkg_manifest_has_project_src_ext_chain_refs"] =
        any(e -> e.rel == "Project.toml", pkg) &&
        any(e -> startswith(e.rel, "src/"), pkg) &&
        any(e -> startswith(e.rel, "ext/"), pkg) &&
        all(any(e -> e.rel == joinpath("validation", f), pkg)
            for f in P2_CHAIN_FILES) &&
        all(any(e -> e.rel == String(c.path), pkg) for c in REDUCED_CASES)
    t["pkg_manifest_reference_files_are_nc"] =
        all(endswith(String(c.path), ".nc") for c in REDUCED_CASES)
    # text gates
    t["text_good_accepted"] = isempty(tg(text))
    t["text_design_pin_drift_refuses"] =
        !isempty(tg(replace(text, P2_DESIGN_SHA => "0"^64)))
    t["text_sw_pin_drift_refuses"] =
        !isempty(tg(replace(text, P2_SW_SHA => "0"^64)))
    t["text_v10_sw_substitution_refuses"] = !isempty(tg(replace(text,
        "ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc" =>
        "ecckd-1.0_sw_climate_rgb-32b_ckd-definition.nc")))
    t["text_external_splice_path_refuses"] = !isempty(tg(text *
        "\ncp -- \$G4WORK/g4-diag/4567/lw-p1/splice/splice_input.nc x\n"))
    t["text_live_project_refuses"] =
        !isempty(tg(text * "\n\"\$JULIA_BIN\" --project=test x\n"))
    t["text_missing_freeze_echo_refuses"] =
        !isempty(tg(replace(text, "STAGE-1 FREEZE COMPLETE" => "note")))
    t["text_missing_loadpath_pin_refuses"] = !isempty(tg(replace(text,
        "export JULIA_LOAD_PATH=\"@:\$RUNROOT/pkg:@stdlib\"" => "true")))
    t["text_missing_refdir_pin_refuses"] = !isempty(tg(replace(text,
        "export NUMERICAL_RADIATION_VALIDATION_REFERENCE_DIR=\"\$RUNROOT/pkg/validation/reference\"" =>
        "true")))
    t["text_missing_postpkg_refuses"] = !isempty(tg(replace(text,
        "REFUSED: staged package tree/evaluator chain/reference drifted during the runs" =>
        "note")))
    t["text_missing_compare_gate_refuses"] = !isempty(tg(replace(text,
        "REFUSED: duplicate/control/branch gates failed (drift recorded; ordering assignment refused; values never averaged)" =>
        "note")))
    t["text_head_pipeline_refuses"] =
        !isempty(tg(text * "\nfoo --version | head -1\n"))
    t["text_shared_redirect_refuses"] =
        !isempty(tg(text * "\necho x > \"\$G4WORK/work/evil.txt\"\n"))
    t["bash_syntax_good_accepted"] = p2_bash_syntax_ok(text)
    t["bash_syntax_broken_refuses"] =
        !p2_bash_syntax_ok(text * "\nif true; then\n")
    # frozen-design guards
    design = read(P2_DESIGN_FILE, String)
    t["design_staging_bracket_present"] =
        occursin("STAGING READ BRACKET", design) &&
        occursin("freeze (chmod a-w + writable-scan)", design)
    t["design_three_masters_present"] =
        occursin("THREE external LW masters", design) &&
        occursin("NO-EXTERNAL-SPLICE-PATH", design)
    t["design_license_covers_h2o_table"] =
        occursin("longwave_h2o_absorption", design) &&
        occursin("NumericalRadiationNCDatasetsExt.jl:151", design)
    t["design_controls_present"] =
        occursin("0.18218645425029933", design) &&
        occursin("102.67056437657112", design) &&
        occursin("22.791293464348826", design)
    t["design_palindromic_order"] = occursin(P2_ARM_LIST, design)
    t
end

# --- main -------------------------------------------------------------------------

function main()
    fails = String[]
    gates = Dict{String, String}()
    groups = Dict{String, Vector{String}}()

    pkg = p2_pkg_manifest()

    dd = String[]
    p2_try_sha(P2_DESIGN_FILE) == P2_DESIGN_SHA ||
        push!(dd, "frozen design sha drift")
    p2_try_sha(joinpath(P2_PROJECT_ROOT, P2_P1_CHECKER_REPO)) ==
        P2_P1_CHECKER_SHA || push!(dd, "committed P1 checker sha drift")
    groups["frozen_pins"] = dd

    lg = String[]
    for l in P2_LEDGERS
        c = p2_classify_ledger(l)
        c.ok || push!(lg, c.reason)
    end
    groups["prerequisite_ledgers"] = lg

    inp = String[]
    for (sha, sz, path) in ((P2_INIT_SHA, P2_INIT_BYTES, P2_INIT_PATH),
                            (P2_PLATEAU_SHA, P2_PLATEAU_BYTES, P2_PLATEAU_PATH),
                            (P2_PUB_SHA, P2_PUB_BYTES, P2_PUB_PATH),
                            (P2_SW_SHA, P2_SW_BYTES, P2_SW_PATH))
        isfile(path) || (push!(inp, "missing master: $path"); continue)
        filesize(path) == sz || push!(inp, "master size drift: $path")
        p2_try_sha(path) == sha || push!(inp, "master sha drift: $path")
    end
    groups["master_pins"] = inp

    groups["source_census"] = p2_source_census_issues(pkg)

    id_iss, id_pins = p2_instrument_identity()
    groups["instrument_identity"] = id_iss

    tc = String[]
    jl1 = try
        first(split(read(`$P2_JULIA_BIN --version`, String), '\n'))
    catch
        "unreadable"
    end
    jl1 == P2_JULIA_VERSION_LINE || push!(tc, "julia version drift: $jl1")
    isfile(P2_TEST_PROJECT) || push!(tc, "test Project.toml missing")
    isfile(P2_TEST_MANIFEST) || push!(tc, "test Manifest.toml missing")
    groups["julia_provenance"] = tc

    # generation-time REAL verification: splice build + license path on
    # live trees (pre-freeze semantics), proving the staged-form job
    # gates run on genuine states
    rv = String[]
    tmp = mktempdir()
    spl = joinpath(tmp, "splice_preview.nc")
    append!(rv, p1c_build_splice(P2_INIT_PATH, P2_PUB_PATH, spl))
    if isempty(rv)
        gs, _ = p1c_gate_splice(spl, P2_INIT_PATH, P2_PUB_PATH)
        append!(rv, gs)
    end
    if isempty(rv)
        models = Dict(st => read_ecckd_tabulated_gas_optics(p, P2_SW_PATH;
                          gas_names = P2C_GASES,
                          h2o_mole_fraction = P2C_H2O)
                      for (st, p) in (("init", P2_INIT_PATH),
                                      ("plateau", P2_PLATEAU_PATH),
                                      ("splice", spl),
                                      ("published", P2_PUB_PATH)))
        liss, inv, lic = p2c_license_and_inventory(models)
        append!(rv, liss)
        isempty(liss) || nothing
        # record-only: license outcome is the JOB's determination; here
        # we only prove the assessment path executes and gates hold
        push!(rv, isempty(liss) ? "" : "license assessment path failed")
        filter!(x -> !isempty(x), rv)
    end
    groups["real_state_verification"] = rv

    text = p2_make_sbatch(pkg)
    groups["sbatch_deterministic_render"] =
        text == p2_make_sbatch(pkg) ? String[] :
        ["sbatch render is not deterministic"]
    groups["sbatch_text_gates"] = p2_text_gate_issues(text)
    groups["sbatch_bash_syntax"] = p2_bash_syntax_ok(text) ? String[] :
        ["generated sbatch fails bash -n syntax verification"]

    tests = p2_fixtures(pkg, text)
    gates["fixtures"] = all(values(tests)) ? "passed" : "failed"
    all(values(tests)) ||
        push!(fails, "fixture failures: " *
              join(sort([k for (k, v) in tests if !v]), ", "))

    for (k, v) in groups
        gates["evidence_" * k] = isempty(v) ? "passed" : "failed"
        isempty(v) || append!(fails, ["$k: " * i for i in v])
    end
    ready = gates["fixtures"] == "passed" && all(isempty, values(groups))
    status = ready ? "p2_checkpoint_ready" : "p2_checkpoint_refused"
    if ready
        mkpath(dirname(P2_SBATCH))
        write(P2_SBATCH, text)
    end
    sb_sha = ready ? p2_sha(P2_SBATCH) : nothing

    design_text = read(P2_DESIGN_FILE, String)
    result = Dict(
        "case" => "gate4_p2_checkpoint",
        "data_mode" => "generator_checkpoint",
        "status" => status,
        "gates" => gates,
        "failures" => fails,
        "fixture_verdicts" => tests,
        "fixture_count" => length(tests),
        "sbatch_path" => P2_SBATCH,
        "sbatch_sha256" => sb_sha,
        "frozen_design" => Dict("sha256" => P2_DESIGN_SHA,
                                "durable_file" => P2_DESIGN_REPO_PATH,
                                "verbatim_text" => design_text),
        "arms" => P2C_ARMS,
        "states" => Dict(
            "init" => Dict("sha256" => P2_INIT_SHA, "bytes" => P2_INIT_BYTES),
            "plateau" => Dict("sha256" => P2_PLATEAU_SHA,
                              "bytes" => P2_PLATEAU_BYTES),
            "published_final" => Dict("sha256" => P2_PUB_SHA,
                                      "bytes" => P2_PUB_BYTES),
            "splice" => "in-RUNROOT reconstruction (NOT a master); " *
                "P1 checker $P2_P1_CHECKER_SHA gates",
            "fixed_sw" => Dict("file" => basename(P2_SW_PATH),
                               "sha256" => P2_SW_SHA,
                               "bytes" => P2_SW_BYTES)),
        "controls" => Dict(st => p2c_tok(v)
                           for (st, v) in P2C_CONTROLS),
        "invocation_identity" => P2C_INVOCATION,
        "instrument_identity" => id_pins,
        "package_tree" => Dict("files" => length(pkg),
            "exec_census" => count(e -> e.exec, pkg),
            "artifacts_toml_staged" => true,
            "manifest_sha256" => bytes2hex(sha256(join(
                ["$(e.sha) $(e.rel)" for e in pkg], "\n")))),
        "gate_instrument_provenance" => Dict(
            "p1_checker_sha256" => P2_P1_CHECKER_SHA,
            "p2_checker_sha256" => p2_sha(joinpath(P2_PROJECT_ROOT,
                                                   P2_CHECKER_REPO)),
            "julia" => P2_JULIA_BIN,
            "julia_version_line" => P2_JULIA_VERSION_LINE,
            "test_project_sha256" => p2_sha(P2_TEST_PROJECT),
            "test_manifest_sha256" => p2_sha(P2_TEST_MANIFEST)),
        "non_authorizing_note" => "this checkpoint generates and " *
            "verifies the P2 sbatch; it never submits; submission " *
            "requires explicit monitor GO.",
        "disclaimer" => "generator checkpoint; writes nothing except " *
            "its own JSON/MD results and the generated sbatch plus " *
            "transient private temp fixtures (mktempdir).")

    mkpath(dirname(P2_RESULTS_JSON))
    open(P2_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(P2_RESULTS_MD, "w") do io
        println(io, "# Gate-4 P2 four-state hard-objective checkpoint\n")
        println(io, "Status: **$status**\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nFrozen design: `$P2_DESIGN_SHA`")
        println(io, "\nGenerated sbatch: `$P2_SBATCH`" *
                    (sb_sha === nothing ? " (NOT written; refused)" :
                     " sha256 `$sb_sha`"))
        println(io, "\nFixtures: $(length(tests)) " *
                    "($(count(values(tests))) passed)")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_p2_checkpoint: $status")
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
