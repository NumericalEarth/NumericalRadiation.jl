# Gate-4 C3-IB job-4584 COMPLETION ledger writer (fail-closed).
# Durable verification record for the COMPLETED 0:0 terminal state of
# the recovered C3-IB iteration-budget control unit (commit 05f635b3,
# sbatch b5646995): pins receipt/log/commit/authorities, all seven run
# products, the 13 score records (with product<->score lw_sha linkage,
# token/bits agreement, and exact rational token arithmetic for the
# four preregistered treatment-minus-control deltas), the exact 13-file
# upstream pass census with record-identical controls (printed-precision
# tokens), the anchor HIT, and
# the stage-7 / no-refusal evidence. In-process refusal fixtures must
# pass before anything is written. Claims stay inside the frozen
# ceilings; the RUNROOT is preserved, reviewer accesses are read-only,
# and NO filesystem immutability seal is claimed. Writes only its own
# JSON/MD results.

const P2_PROJECT_ROOT = "/shared/home/greg/Projects/AnalyticBandRadiation-platform"
include(joinpath(P2_PROJECT_ROOT, "validation", "validation_results.jl"))
using SHA
using JSON

const C4584_RECEIPT = "/shared/home/greg/data/ckdmip-logs/" *
    "g4-c3ib-lw-4584-scontrol-final-agent42.txt"
const C4584_RECEIPT_SHA =
    "b90962764f0f2a8078b7d0d2b4c49721988ea67b4ecccab9a2f282e11a78e664"
const C4584_EPOCH = C4584_RECEIPT * ".epoch"
const C4584_EPOCH_VALUE = "1786742841"
const C4584_LOG = "/shared/home/greg/data/ckdmip-logs/g4-c3ib-lw-4584.log"
const C4584_LOG_SHA =
    "9b2a0d62aa5b66016ee05f033fd1330a8a7f4dc7e00dec3ef369554e91f0c112"
const C4584_RUNROOT = "/shared/home/greg/ecckd-derived-flux-work/" *
    "g4-init-generation/g4-diag/4584/lw-c3ib"
const C4584_COMMIT = "05f635b3ef025116d322a28f40ac22c51e5747f8"
const C4584_AUTHORITIES = [
    ("sbatch", "validation/results/gate4_c3_ib_lw_iteration_budget.sbatch",
     "b564699530af5fa4569a4e29631772df6a49c717cda381463e1ebaa9ba0b24d3"),
    ("generator", "validation/gate4_c3_ib_checkpoint.jl",
     "46e55471bb3ba3ad0392c33c3d690ef0f4feb9a9e824cc4eae646c5753b60503"),
    ("design", "validation/gate4_c3_ib_iteration_budget_frozen_design.md",
     "e5af535f2d1c9efb478bb1b856f632fe05a5dfd01dec634cfecc41a67e44bb63"),
    ("checker", "validation/gate4_c3_ib_checker.jl",
     "06ce129768bafaa8dcf18e6cff063e030dafeeeca428447342c2a6033e5a1b82")]
const C4584_RAW_REQUIRED = [
    "JobId=4584", "JobName=g4-c3ib-lw-iteration-budget",
    "JobState=COMPLETED", "Reason=None", "ExitCode=0:0",
    "DerivedExitCode=0:0", "Restarts=0", "RunTime=03:11:06",
    "TimeLimit=06:00:00", "StartTime=2026-08-14T18:16:06",
    "EndTime=2026-08-14T21:27:12",
    "Command=/shared/home/greg/Projects/AnalyticBandRadiation-platform/" *
        "validation/results/gate4_c3_ib_lw_iteration_budget.sbatch",
    "SubmitLine=sbatch --parsable " *
        "validation/results/gate4_c3_ib_lw_iteration_budget.sbatch",
    "StdOut=/shared/home/greg/data/ckdmip-logs/g4-c3ib-lw-4584.log"]
const C4584_PRODUCTS = [
    ("probe", "raw2", "work-probe/lw_raw-ckd-definition/" *
     "ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
     "64ca26c7dafe118e278d9a93a083f76418b7075b68b5b9f5c18d78ac82da59a1"),
    ("c0a", "raw2", "work-c0a/lw_raw-ckd-definition/" *
     "ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
     "7f52865910bf64c80a9df82a5e16e6dc13187c86d1a65132512a3d7d575c4756"),
    ("c3ib", "raw2", "work-c3ib/lw_raw-ckd-definition/" *
     "ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
     "b03d93d3af63a6b4a631463f0f3b747b8d10346dd18485ac0406467d81074f3d"),
    ("c0b", "raw2", "work-c0b/lw_raw-ckd-definition/" *
     "ecckd-1.2_lw_raw2-ckd-definition_climate_fsck-tol0.0161.nc",
     "a7af6baea792907839e118b46043e9b77d5640967bc595ae728191915472d25a"),
    ("c0a", "final", "work-c0a/lw_ckd-definition/" *
     "ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc",
     "e6037e9d57a9e04233628e8770e364ee538986e8824c05aee73d021debc69cca"),
    ("c3ib", "final", "work-c3ib/lw_ckd-definition/" *
     "ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc",
     "d272657bec96af016661bb68b13508da3bbc08ea49b9e0427b60e8cebbcd4ac4"),
    ("c0b", "final", "work-c0b/lw_ckd-definition/" *
     "ecckd-1.2_lw_ckd-definition_climate_fsck-tol0.0161.nc",
     "e64f9217acaaf72c8ff0d0889871b61be67357240e6341d8a5c0ecb19c62115d")]
const C4584_SCORE_NAMES = sort([
    "score-anchor-anchor-primary.txt",
    ["score-$a-$e-$p.txt" for a in ("c0a", "c3ib", "c0b")
     for e in ("raw2", "final") for p in ("primary", "secondary")]...])
const C4584_UPSTREAM_NAMES = sort([
    "probe-base-upstream.txt",
    ["$a-$p-upstream.txt" for a in ("c0a", "c3ib", "c0b")
     for p in ("base", "relative-ch4", "relative-n2o", "relative-cfc")]...])
const C4584_STATUS_ALLOWED = ["Converged", "Maximum iterations reached"]
const C4584_COMPARE_LOG = joinpath(C4584_RUNROOT, "c3ib-compare.log")
const C4584_COMPARE_SHA =
    "6465d61a662c09594c09f79b736bf2c7cb0a3d1ce6b707c505cf523692977155"
const C4584_COMPARE_BYTES = 1640
const C4584_DELTAS = [
    ("raw2", "primary", "0.012812853359393"),
    ("raw2", "secondary", "0.01281285335942"),
    ("final", "primary", "0.013840350139788"),
    ("final", "secondary", "0.013840350140555")]
const C4584_SW_SHA = Dict(
    "primary" =>
        "8b54392eeddd303299881d6405dcf3de4d738667a3dfe605964a64863e2fbee4",
    "secondary" =>
        "49abc7bf88b80252e4f9934f8659d108ffee6a101124b2fd080f2eb65d144eb3")
const C4584_ANCHOR_LW_SHA =
    "a3d93d3eb4e69894862fad682563d25a5636e7dbbcc59c197ecaa1cceb6f24b4"
const C4584_ANCHOR_TOKEN = "22.824617997003102"
const C4584_ANCHOR_BITS = "4036d31a2a40d244"
const C4584_TREATMENT_BASE = (status = "Converged",
    cost_token = "16.7515", gradient_token = "0.0178892")
const C4584_CONTROL_BASE_COST = "16.7768"
const C4584_RESULTS_JSON =
    validation_results_path("gate4_c3_ib_4584_completion_ledger.json")
const C4584_RESULTS_MD =
    validation_results_path("gate4_c3_ib_4584_completion_ledger.md")

c4584_sha(p) = bytes2hex(open(sha256, p))

# exact rational arithmetic on decimal tokens (no float rounding)
function c4584_rat(s)
    m = match(r"^(-?)(\d+)(?:\.(\d+))?$", s)
    m === nothing && return nothing
    sign = m.captures[1] == "-" ? -1 : 1
    frac = m.captures[3] === nothing ? "" : m.captures[3]
    sign * (parse(BigInt, m.captures[2] * frac) //
            BigInt(10)^length(frac))
end

c4584_bits(tok) = string(reinterpret(UInt64, parse(Float64, tok)),
                         base = 16, pad = 16)

function c4584_parse_upstream(text)
    lines = [String(l) for l in split(text, '\n'; keepempty = false)]
    length(lines) == 3 || return nothing
    d = Dict{String, String}()
    for (k, ln) in zip(("status", "cost_token", "gradient_token"), lines)
        startswith(ln, k * "=") || return nothing
        d[k] = ln[(length(k) + 2):end]
    end
    d
end

function c4584_score_header(text)
    d = Dict{String, String}()
    nrows = 0
    for ln in split(text, '\n'; keepempty = false)
        if startswith(ln, "row ")
            nrows += 1
        else
            m = match(r"^([a-z0-9_]+)=(.*)$", ln)
            m === nothing && continue
            haskey(d, m.captures[1]) && return nothing
            d[String(m.captures[1])] = String(m.captures[2])
        end
    end
    d["_nrows"] = string(nrows)
    d
end

const C4584_T_BANNER = "Optimizing coefficients with Adept LBFGS " *
    "algorithm: max iterations = 9000, convergence criterion = 0.02"
const C4584_T_ITLINE = "Iteration 4211: cost function = 16.7515, " *
    "gradient norm = 0.0178892"
const C4584_RULED_STATEMENT = "under this ONE fixed setup, the " *
    "higher-cap (9000) base arm reported Converged at iteration 4211, " *
    "and its pinned package objectives were +0.012812853359393 / " *
    "+0.01281285335942 (raw2, primary/secondary evaluator) and " *
    "+0.013840350139788 / +0.013840350140555 (final) relative to the " *
    "two token-identical 3000-budget controls; raising this cap did " *
    "not improve these measured pinned objectives. Nothing further. " *
    "Converged is a REPORTED STATUS under one criterion in one fixed " *
    "setup, never proof of an optimum"
const C4584_CEILINGS = "private fixed-setup budget association " *
    "only; all six primary placements ABOVE 1.05 are descriptive; NO " *
    "recovered acceptance; NO claim of a global or genuine optimum; " *
    "NO mechanism localization, candidate-space reduction, or " *
    "candidate ranking (all mechanism classes remain OPEN and " *
    "UNRANKED); NO optimizer- or backend-behavior characterization; " *
    "NO other-budget or next-campaign authorization; the anchor HIT " *
    "licenses the current-G1-adjacent label only and does NOT " *
    "refresh or reconfirm the committed terminal Gate-1 state; the " *
    "external <=1.05 gate untouched"
const C4584_BANNED_CLAIMS = [
    "genuine optimum", "global optimum", "budget starvation",
    "optimizer side", "exhausted", "exhaustion", "faithfully",
    "candidate space", "narrowed", "ranked",
    "recovered acceptance was", "acceptance-equivalent",
    "recover the target"]

# field-scoped language guard: the ceilings field is the ONLY place
# licensed negations may name the retracted claim classes; every other
# field is scanned and any banned phrase refuses unconditionally
function c4584_language_guard(result)
    iss = String[]
    scan = deepcopy(result)
    mo = get(scan, "monitor_observations", Dict{String, Any}())
    get(mo, "ceilings", nothing) == C4584_CEILINGS ||
        push!(iss, "ceilings field != the exact licensed constant")
    get(mo, "ruled_result_statement", nothing) == C4584_RULED_STATEMENT ||
        push!(iss, "ruled_result_statement != the exact licensed constant")
    haskey(mo, "ceilings") && delete!(mo, "ceilings")
    rendered = lowercase(JSON.json(scan))
    append!(iss, ["banned phrase outside the ceilings field: " * b
                  for b in C4584_BANNED_CLAIMS
                  if occursin(lowercase(b), rendered)])
    iss
end

# COMMITTED-CHECKER PASS CENSUS (mechanical bridge for the seven
# product structural scans and the logical product-identity claims):
# exact full-line counts in the pinned log, plus the two exact-one
# logical-identity lines
const C4584_PASS_CENSUS = [
    ("C3C PASS: scan", 7), ("C3C PASS: upstream", 1),
    ("C3C PASS: score", 13), ("C3C PASS: anchor", 1),
    ("C3C PASS: identity", 2), ("C3C PASS: compare", 1),
    ("logical identity holds: controls-raw2", 1),
    ("logical identity holds: controls-final", 1)]

function c4584_pass_census_issues(loglines)
    iss = String[]
    for (pat, want) in C4584_PASS_CENSUS
        c = count(==(pat), loglines)
        c == want ||
            push!(iss, "pass census: '$pat' count $c != $want")
    end
    iss
end

# mechanical treatment-terminal gate: exact-one 9000/0.02 banner,
# exact-one terminal iteration line, and that line followed by
# Convergence status: Converged with no further Iteration line between
function c4584_treatment_terminal_issues(log_text)
    iss = String[]
    lines = split(log_text, '\n')
    for (what, pat) in (("treatment 9000 banner", C4584_T_BANNER),
                        ("terminal iteration line", C4584_T_ITLINE))
        c = count(==(pat), lines)
        c == 1 || push!(iss, "$what count $c != 1")
    end
    idx = findall(==(C4584_T_ITLINE), lines)
    if length(idx) == 1
        rest = lines[(idx[1] + 1):end]
        j = findfirst(l -> startswith(l, "Convergence status: "), rest)
        k = findfirst(l -> startswith(l, "Iteration "), rest)
        (j !== nothing && (k === nothing || j < k) &&
         rest[j] == "Convergence status: Converged") ||
            push!(iss, "terminal iteration line not followed by " *
                       "Converged before any further iteration")
    end
    iss
end

# in-process refusal fixtures: MUST all pass before anything is written
function c4584_fixtures()
    t = Dict{String, Bool}()
    t["rat_exact_delta"] =
        c4584_rat("22.803834071106238") - c4584_rat("22.790000000000000") ==
        c4584_rat("0.013834071106238")
    t["rat_mutation_refuses"] =
        c4584_rat("0.012812853359393") !=
        c4584_rat("22.803834071106238") - c4584_rat("22.791021217746846")
    t["rat_malformed_refuses"] = c4584_rat("1.2.3") === nothing
    t["bits_agree"] = c4584_bits("22.824617997003102") ==
        "4036d31a2a40d244"
    t["bits_mutation_refuses"] = c4584_bits("22.8246179970032") !=
        "4036d31a2a40d244" && c4584_bits("1.5") == "3ff8000000000000"
    t["upstream_parse_ok"] = c4584_parse_upstream(
        "status=Converged\ncost_token=1.0\ngradient_token=2.0\n") !==
        nothing
    t["upstream_missing_line_refuses"] = c4584_parse_upstream(
        "status=Converged\ncost_token=1.0\n") === nothing
    t["upstream_wrong_key_refuses"] = c4584_parse_upstream(
        "state=Converged\ncost_token=1.0\ngradient_token=2.0\n") ===
        nothing
    t["score_header_dup_key_refuses"] = c4584_score_header(
        "objective_token=1\nobjective_token=2\n") === nothing
    t["census_extra_refuses"] =
        sort(vcat(C4584_SCORE_NAMES, ["score-evil.txt"])) !=
        C4584_SCORE_NAMES
    census_green = vcat([fill(pat, want)
                         for (pat, want) in C4584_PASS_CENSUS]...)
    t["pass_census_green_shape"] =
        isempty(c4584_pass_census_issues(census_green))
    t["pass_census_missing_refuses"] =
        ("pass census: 'C3C PASS: scan' count 6 != 7") in
        c4584_pass_census_issues(census_green[2:end])
    t["pass_census_duplicate_refuses"] =
        ("pass census: 'C3C PASS: compare' count 2 != 1") in
        c4584_pass_census_issues(vcat(census_green,
                                      ["C3C PASS: compare"]))
    green = "x\n" * C4584_T_BANNER *
        "\nIteration 1: cost function = 1, gradient norm = 2\n" *
        C4584_T_ITLINE * "\nConvergence status: Converged\ny\n"
    t["terminal_gate_green_shape"] =
        isempty(c4584_treatment_terminal_issues(green))
    t["terminal_gate_duplication_refuses"] =
        !isempty(c4584_treatment_terminal_issues(
            green * C4584_T_ITLINE * "\n"))
    t["terminal_gate_mutation_refuses"] =
        !isempty(c4584_treatment_terminal_issues(
            replace(green, "16.7515" => "16.7516")))
    t["terminal_gate_wrong_follow_refuses"] =
        !isempty(c4584_treatment_terminal_issues(
            replace(green, C4584_T_ITLINE * "\nConvergence status: " *
                    "Converged" => C4584_T_ITLINE *
                    "\nIteration 4212: cost function = 1, gradient " *
                    "norm = 2\nConvergence status: Converged")))
    t
end

function main()
    iss = String[]
    fx = c4584_fixtures()
    fxbad = sort([k for (k, v) in fx if !v])
    isempty(fxbad) ||
        push!(iss, "refusal fixtures failed: " * join(fxbad, ","))
    for (what, pth, pin) in (("receipt", C4584_RECEIPT, C4584_RECEIPT_SHA),
                             ("log", C4584_LOG, C4584_LOG_SHA),
                             ("compare log", C4584_COMPARE_LOG,
                              C4584_COMPARE_SHA))
        isfile(pth) || (push!(iss, "$what missing: $pth"); continue)
        c4584_sha(pth) == pin || push!(iss, "$what sha drift: $pth")
    end
    filesize(C4584_COMPARE_LOG) == C4584_COMPARE_BYTES ||
        push!(iss, "compare log byte drift")
    epoch = isfile(C4584_EPOCH) ? strip(read(C4584_EPOCH, String)) : nothing
    epoch == C4584_EPOCH_VALUE ||
        push!(iss, "epoch sidecar missing or value != $C4584_EPOCH_VALUE")
    receipt_text = isfile(C4584_RECEIPT) ? read(C4584_RECEIPT, String) : ""
    for r in C4584_RAW_REQUIRED
        occursin(r, receipt_text) ||
            push!(iss, "receipt missing raw field: $r")
    end
    # commit-blob and on-disk authority equality
    for (what, rel, pin) in C4584_AUTHORITIES
        blob = try
            read(`git -C $P2_PROJECT_ROOT show $C4584_COMMIT:$rel`, String)
        catch
            push!(iss, "$what committed blob unreadable")
            ""
        end
        isempty(blob) ||
            (bytes2hex(sha256(blob)) == pin ||
             push!(iss, "$what committed blob sha != pinned"))
        p = joinpath(P2_PROJECT_ROOT, rel)
        isfile(p) && c4584_sha(p) == pin ||
            push!(iss, "$what on-disk sha != pinned")
    end
    log_text = isfile(C4584_LOG) ? read(C4584_LOG, String) : ""
    loglines = split(log_text, '\n')
    count(l -> occursin("REFUSED", l), loglines) == 0 ||
        push!(iss, "log carries REFUSED markers")
    count(l -> occursin("CHILD FAILED", l), loglines) == 0 ||
        push!(iss, "log carries CHILD FAILED markers")
    append!(iss, c4584_pass_census_issues(loglines))
    count(l -> occursin("=== C3IB stage 7", l), loglines) >= 1 ||
        push!(iss, "stage-7 banner missing")
    count(==("=== C3IB done 2026-08-14T21:27:12Z ==="), loglines) == 1 ||
        push!(iss, "C3IB done timestamp line not exactly once")
    append!(iss, c4584_treatment_terminal_issues(log_text))
    count(l -> occursin("STAGE-1 FREEZE COMPLETE", l), loglines) == 1 ||
        push!(iss, "freeze marker not exactly once")
    # products (sha pinned, bytes recorded)
    products = Any[]
    prodsha = Dict{Tuple{String, String}, String}()
    for (arm, ep, rel, pin) in C4584_PRODUCTS
        p = joinpath(C4584_RUNROOT, rel)
        if !isfile(p)
            push!(iss, "product missing: $rel")
            continue
        end
        sh = c4584_sha(p)
        sh == pin || push!(iss, "product sha drift: $rel")
        prodsha[(arm, ep)] = sh
        push!(products, Dict("arm" => arm, "endpoint" => ep,
            "path" => p, "sha256" => sh, "bytes" => filesize(p)))
    end
    # score census + records
    scores = sort(filter(n -> startswith(n, "score-"),
                         readdir(C4584_RUNROOT)))
    scores == C4584_SCORE_NAMES ||
        push!(iss, "score-record census != the 13 canonical names")
    tok = Dict{Tuple{String, String, String}, String}()
    score_files = Any[]
    for n in C4584_SCORE_NAMES
        p = joinpath(C4584_RUNROOT, n)
        isfile(p) || (push!(iss, "score record missing: $n"); continue)
        txt = read(p, String)
        h = c4584_score_header(txt)
        h === nothing && (push!(iss, "score header malformed: $n"); continue)
        h["_nrows"] == "24" || push!(iss, "score rows != 24: $n")
        a, e, pn = h["c3ib_arm"], h["c3ib_endpoint"], h["c3ib_panel"]
        get(h, "sw_sha", "") ==
            C4584_SW_SHA[pn == "anchor" ? "primary" : pn] ||
            push!(iss, "score sw_sha != pinned panel authority: $n")
        n == "score-$a-$e-$pn.txt" ||
            push!(iss, "score mapping lines != filename: $n")
        get(h, "objective_bits", "") ==
            c4584_bits(get(h, "objective_token", "0")) ||
            push!(iss, "objective bits != token bits: $n")
        if a != "anchor"
            prodkey = (a, e)
            haskey(prodsha, prodkey) &&
                (h["lw_sha"] == prodsha[prodkey] ||
                 push!(iss, "score lw_sha != product sha: $n"))
            tok[(a, e, pn)] = h["objective_token"]
        else
            h["objective_token"] == C4584_ANCHOR_TOKEN ||
                push!(iss, "anchor token mismatch")
            h["objective_bits"] == C4584_ANCHOR_BITS ||
                push!(iss, "anchor bits mismatch")
            h["lw_sha"] == C4584_ANCHOR_LW_SHA ||
                push!(iss, "anchor lw_sha != pinned anchor master")
        end
        push!(score_files, Dict("name" => n, "sha256" => c4584_sha(p),
                                "bytes" => filesize(p)))
    end
    # controls identity at the score level = objective token AND
    # objective_bits identity (bits == bits(token) is gated per record,
    # so token equality implies bits equality) + exact rational deltas
    arithmetic = Any[]
    for (e, pn, dq) in C4584_DELTAS
        tc = get(tok, ("c3ib", e, pn), nothing)
        ta = get(tok, ("c0a", e, pn), nothing)
        tb = get(tok, ("c0b", e, pn), nothing)
        if tc === nothing || ta === nothing || tb === nothing
            push!(iss, "objective tokens incomplete for $e/$pn")
            continue
        end
        ta == tb ||
            push!(iss, "controls not token-identical for $e/$pn")
        d = c4584_rat(tc) - c4584_rat(ta)
        d == c4584_rat(dq) ||
            push!(iss, "delta arithmetic mismatch for $e/$pn")
        d > 0 || push!(iss, "delta branch not POSITIVE for $e/$pn")
        push!(arithmetic, Dict("endpoint" => e, "panel" => pn,
            "treatment_token" => tc, "control_token" => ta,
            "delta_token" => dq, "branch" => "POSITIVE"))
    end
    # upstream census (13 records) + bracket gates
    ups = sort(filter(n -> endswith(n, "-upstream.txt"),
                      readdir(C4584_RUNROOT)))
    ups == C4584_UPSTREAM_NAMES ||
        push!(iss, "upstream census != the 13 canonical names")
    urec = Dict{String, Dict{String, String}}()
    umeta = Dict{String, Any}()
    for n in C4584_UPSTREAM_NAMES
        p = joinpath(C4584_RUNROOT, n)
        isfile(p) || (push!(iss, "upstream record missing: $n"); continue)
        d = c4584_parse_upstream(read(p, String))
        d === nothing && (push!(iss, "upstream record malformed: $n");
                          continue)
        d["status"] in C4584_STATUS_ALLOWED ||
            push!(iss, "upstream status outside allowed set: $n")
        urec[n] = d
        umeta[n] = Dict("sha256" => c4584_sha(p),
                        "bytes" => filesize(p),
                        "status" => d["status"],
                        "cost_token" => d["cost_token"],
                        "gradient_token" => d["gradient_token"])
    end
    for p in ("base", "relative-ch4", "relative-n2o", "relative-cfc")
        a = get(urec, "c0a-$p-upstream.txt", nothing)
        b = get(urec, "c0b-$p-upstream.txt", nothing)
        (a === nothing || b === nothing) && continue
        a == b ||
            push!(iss, "controls upstream records differ for pass $p")
    end
    tb = get(urec, "c3ib-base-upstream.txt", nothing)
    if tb !== nothing
        (tb["status"] == C4584_TREATMENT_BASE.status &&
         tb["cost_token"] == C4584_TREATMENT_BASE.cost_token &&
         tb["gradient_token"] == C4584_TREATMENT_BASE.gradient_token) ||
            push!(iss, "treatment base record != pinned quote")
    end
    cb = get(urec, "c0a-base-upstream.txt", nothing)
    if cb !== nothing
        (cb["status"] == "Maximum iterations reached" &&
         cb["cost_token"] == C4584_CONTROL_BASE_COST) ||
            push!(iss, "control base record != pinned quote")
    end
    # compare-log preregistered lines (each exactly once)
    cmp_text = isfile(C4584_COMPARE_LOG) ?
        read(C4584_COMPARE_LOG, String) : ""
    expected_lines = vcat(
        ["C3IB DELTA treatment-minus-control [$e/$pn]: $dq " *
         "BRANCH=POSITIVE (exact decimal on recorded tokens; no " *
         "threshold; no descent-implies-improvement inference)"
         for (e, pn, dq) in C4584_DELTAS],
        ["C3IB G1-BOUND PLACEMENT [primary $a/$e]: ABOVE 1.05 " *
         "(descriptive placement)"
         for a in ("c0a", "c3ib", "c0b") for e in ("raw2", "final")],
        ["C3IB-G1-ADJACENCY: LICENSED -- arm placements are " *
         "current-G1-adjacent (anchor reproduced 22.824617997003102 " *
         "bit-exactly; hit does not refresh or reconfirm the " *
         "committed terminal Gate-1 state)"])
    for ln in expected_lines
        length(collect(eachmatch(Regex("\\Q" * ln * "\\E"),
                                 cmp_text))) == 1 ||
            push!(iss, "compare line not exactly once: " * first(ln, 60))
    end
    marker = joinpath(C4584_RUNROOT, "anchor-marker.txt")
    (isfile(marker) && strip(read(marker, String)) == "HIT") ||
        push!(iss, "anchor marker != HIT")
    if !isempty(iss)
        foreach(i -> println("C4584 LEDGER REFUSE: ", i), iss)
        println("gate4_c3_ib_4584_completion_ledger: refused " *
                "(nothing written)")
        return 1
    end
    result = Dict(
        "case" => "gate4_c3_ib_4584_completion_ledger",
        "data_mode" => "run_completion_ledger",
        "status" => "c3ib_4584_run_completed_verified",
        "job" => Dict("job_id" => "4584",
            "job_name" => "g4-c3ib-lw-iteration-budget",
            "state" => "COMPLETED", "reason" => "None",
            "exit_code" => "0:0", "derived_exit_code" => "0:0",
            "restarts" => "0", "run_time" => "03:11:06",
            "time_limit" => "06:00:00",
            "start_time" => "2026-08-14T18:16:06",
            "end_time" => "2026-08-14T21:27:12",
            "command" => "/shared/home/greg/Projects/" *
                "AnalyticBandRadiation-platform/validation/results/" *
                "gate4_c3_ib_lw_iteration_budget.sbatch",
            "submit_line" => "sbatch --parsable " *
                "validation/results/gate4_c3_ib_lw_iteration_budget.sbatch",
            "stdout" => C4584_LOG),
        "durable_evidence" => Dict(
            "receipt" => Dict("path" => C4584_RECEIPT,
                "sha256" => C4584_RECEIPT_SHA,
                "bytes" => filesize(C4584_RECEIPT),
                "epoch_sidecar" => C4584_EPOCH,
                "epoch" => C4584_EPOCH_VALUE,
                "custody" => "create-once noclobber scontrol -dd " *
                    "capture, -agent42 suffix (sole receipt writer)"),
            "log" => Dict("path" => C4584_LOG,
                "sha256" => C4584_LOG_SHA,
                "bytes" => filesize(C4584_LOG)),
            "authorities" => Dict(
                "commit" => C4584_COMMIT,
                [what => Dict("repo_path" => rel, "sha256" => pin)
                 for (what, rel, pin) in C4584_AUTHORITIES]...),
            "products" => products,
            "score_files" => score_files,
            "score_arithmetic" => Dict(
                "method" => "exact rational arithmetic on the " *
                    "recorded decimal tokens; controls verified " *
                    "token-identical at printed precision before " *
                    "differencing",
                "deltas" => arithmetic),
            "upstream_census" => Dict(
                "records" => umeta,
                "controls_record_identical_per_pass" => "true at " *
                    "printed status/cost/gradient token precision",
                "treatment_base" => Dict(
                    "status" => C4584_TREATMENT_BASE.status,
                    "terminal_iteration" => "4211",
                    "cost_token" => C4584_TREATMENT_BASE.cost_token,
                    "gradient_token" =>
                        C4584_TREATMENT_BASE.gradient_token,
                    "budget_consumed" => "no (converged under the " *
                        "9000 cap)")),
            "anchor" => Dict("marker" => "HIT",
                "token" => C4584_ANCHOR_TOKEN,
                "bits" => C4584_ANCHOR_BITS,
                "lw_sha256" => C4584_ANCHOR_LW_SHA),
            "compare_log" => Dict("path" => C4584_COMPARE_LOG,
                "sha256" => C4584_COMPARE_SHA,
                "bytes" => C4584_COMPARE_BYTES),
            "stage7_no_refusal" => Dict("refused_markers" => 0,
                "child_failed_markers" => 0,
                "checker_pass_census" => Dict(
                    pat => want for (pat, want) in C4584_PASS_CENSUS),
                "post_run_reverification" => "stage-7 executed; " *
                    "POSTSTAGE/POSTPKG/CHECKPOST/SRCTPLPOST/" *
                    "SRCEXECPOST gates passed (zero REFUSED markers " *
                    "in the pinned log)"),
            "runroot" => Dict("path" => C4584_RUNROOT,
                "preserved" => true,
                "access_policy" => "reviewer accesses read-only; no " *
                    "filesystem immutability seal applied")),
        "monitor_observations" => Dict(
            "ruled_result_statement" => C4584_RULED_STATEMENT,
            "ceilings" => C4584_CEILINGS,
            "nonwrite_review" => "REVIEWED, NON-EXHAUSTIVE: no " *
                "canonical scientific output publish/install step " *
                "was identified in the sha-verified committed sbatch " *
                "blob or observed in the pinned log; all experimental " *
                "CKD products reside under the 4584 RUNROOT; the " *
                "Slurm log, receipt, and lock/state surfaces are " *
                "expected writes outside this statement's scope",
            "terminal_contract_applied" => "COMPLETED is a HOLD " *
                "state for any next action; no follow-on unit, " *
                "budget change, or objective/data change without a " *
                "new frozen contract and explicit Codex-monitor GO"),
        "non_authorizing_note" => "this ledger records and verifies " *
            "a completed diagnosis unit; it authorizes NOTHING (no " *
            "recovered acceptance, no mechanism inference, no " *
            "follow-on unit)",
        "disclaimer" => "writer reads the receipt, epoch sidecar, " *
            "log, committed blobs, and preserved RUNROOT read-only; " *
            "writes only its own JSON/MD results")
    giss = c4584_language_guard(result)
    mutc = deepcopy(result)
    mutc["monitor_observations"]["ceilings"] =
        C4584_CEILINGS * " and one arm reached the genuine optimum"
    isempty(c4584_language_guard(mutc)) &&
        push!(giss, "guard ceilings-mutation fixture failed")
    mutr = deepcopy(result)
    mutr["monitor_observations"]["ruled_result_statement"] =
        "a harmless-sounding paraphrase of the licensed result"
    isempty(c4584_language_guard(mutr)) &&
        push!(giss, "guard ruled-statement-mutation fixture failed")
    for b in C4584_BANNED_CLAIMS
        mut = deepcopy(result)
        mut["non_authorizing_note"] =
            mut["non_authorizing_note"] * " " * b
        isempty(c4584_language_guard(mut)) &&
            push!(giss, "guard injection fixture failed for: " * b)
    end
    if !isempty(giss)
        foreach(i -> println("C4584 LEDGER REFUSE: ", i), giss)
        println("gate4_c3_ib_4584_completion_ledger: refused " *
                "(nothing written)")
        return 1
    end
    mkpath(dirname(C4584_RESULTS_JSON))
    open(C4584_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(C4584_RESULTS_MD, "w") do io
        println(io, "# Gate-4 C3-IB job 4584 completion ledger\n")
        println(io, "Status: **c3ib_4584_run_completed_verified**\n")
        println(io, "| Field | Value |")
        println(io, "|---|---|")
        println(io, "| JobState | COMPLETED (0:0), 03:11:06 |")
        println(io, "| Receipt | `$C4584_RECEIPT_SHA` (epoch $C4584_EPOCH_VALUE) |")
        println(io, "| Log | `$C4584_LOG_SHA` |")
        println(io, "| Commit | `$C4584_COMMIT` (sbatch `b5646995...`) |")
        println(io, "| Scores | 13/13 C3C PASS; census exact; " *
                    "product<->score lw_sha linkage verified |")
        println(io, "| Deltas (treatment-minus-control) | raw2 " *
                    "+0.012812853359393 / +0.01281285335942; final " *
                    "+0.013840350139788 / +0.013840350140555 -- all " *
                    "POSITIVE; controls token-identical at printed " *
                    "precision |")
        println(io, "| Placements | all six primary placements ABOVE " *
                    "1.05 (descriptive) |")
        println(io, "| Anchor | HIT, 22.824617997003102 bit-exact; " *
                    "adjacency licensed; NO Gate-1 refresh |")
        println(io, "| Upstream | treatment base Converged at 4211 " *
                    "(16.7515 / 0.0178892); controls capped " *
                    "(16.7768, record-identical per pass at printed " *
                    "precision) |")
        println(io, "| RUNROOT | `$C4584_RUNROOT` (preserved; " *
                    "reviewer accesses read-only) |")
        println(io, "\nRuled statement (exact licensed constant, " *
                    "the sole narrative conclusion): " *
                    C4584_RULED_STATEMENT)
    end
    println("gate4_c3_ib_4584_completion_ledger: written")
    return 0
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end
