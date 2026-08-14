# Gate-4 C3-IB CHECKER/EVALUATOR (shared in-job + fixture functions;
# CLI). Frozen design authority: gate4_c3_ib_iteration_budget_frozen_design.md
# sha256 e5af535f2d1c9efb478bb1b856f632fe05a5dfd01dec634cfecc41a67e44bb63.
#
# Reuses the COMMITTED P1 checker (egal/decimal machinery) and the
# COMMITTED P2 checker (row-mirror/record/payload machinery) via
# env-pinned includes (caller byte-verifies both BEFORE setting):
#   P2C_P1_CHECKER  -> gate4_p1_splice_checker.jl (always)
#   C3C_P2_CHECKER  -> gate4_p2_hard_objective_checker.jl (always)
#   P2C_CHAIN_DIR   -> staged/live evaluator chain (score mode only)
# This file adds ONLY the C3-IB gates: per-arm dual-endpoint score
# records (arm x {raw2, final} x {primary, secondary}), same-job
# control repeatability (logical payload + record equality), the fixed
# current-G1 anchor gate with SEVERABILITY semantics (hit/miss is a
# recorded determination -- a miss refuses ONLY the adjacency label,
# never the arm evidence; structural faults refuse hard), and the
# exhaustive treatment-minus-control sign/equality partitions plus the
# primary-panel-only <=1.05 placement test.
#
# CLI modes (wired by the generated sbatch):
#   score <lw> <sw> <out> <arm> <endpoint> <panel> <lw_sha> <sw_sha>
#   identity <a_path> <b_path> <label>
#   anchor <record_path> <marker_out>
#   compare <runroot>

using Printf
using SHA: sha256

# SINGLE include chain (monitor assist 2): the P2 checker OWNS the P1
# include and the evaluator-chain include exactly once; this file never
# includes P1 directly. FAIL CLOSED if the required env pins are absent.
haskey(ENV, "C3C_P2_CHECKER") ||
    error("C3C REFUSE: C3C_P2_CHECKER env pin absent (fail closed)")
haskey(ENV, "P2C_P1_CHECKER") ||
    error("C3C REFUSE: P2C_P1_CHECKER env pin absent (fail closed; " *
          "consumed by the P2 checker include)")
include(ENV["C3C_P2_CHECKER"])

# --- frozen pins (design e5af535f) ------------------------------------------------
const C3C_ARMS = ["c0a", "c3ib", "c0b"]
const C3C_ENDPOINTS = ["raw2", "final"]
const C3C_PANELS = ["primary", "secondary"]
const C3C_SCORE_COUNT = 13          # 12 arm-panel + 1 fixed anchor
const C3C_ANCHOR_TOKEN = "22.824617997003102"
const C3C_ANCHOR_BITS_U64 = UInt64(4627117776501264964)
c3c_anchor_bits_hex() = string(C3C_ANCHOR_BITS_U64, base = 16, pad = 16)
const C3C_G1_BOUND = 21 // big(20)   # <=1.05, exact rational
# pinned authorities (supplied shas are validated AGAINST these; a
# supplied sha alone is never authority -- monitor blocker 3)
const C3C_ANCHOR_LW_SHA = "a3d93d3eb4e69894862fad682563d25a5636e7dbbcc59c197ecaa1cceb6f24b4"
const C3C_PRIMARY_SW_SHA = "8b54392eeddd303299881d6405dcf3de4d738667a3dfe605964a64863e2fbee4"
const C3C_SECONDARY_SW_SHA = "49abc7bf88b80252e4f9934f8659d108ffee6a101124b2fd080f2eb65d144eb3"
const C3C_ADJ_LICENSED = "C3IB-G1-ADJACENCY: LICENSED"
const C3C_ADJ_REFUSED = "C3IB-G1-ADJACENCY: REFUSED"

c3c_sha(path) = open(io -> bytes2hex(sha256(io)), path)

# --- score records (P2 record machinery + C3-IB provenance fields) -----------------
function c3c_score_record(lw, sw, arm, endpoint, panel, lw_sha, sw_sha)
    iss = String[]
    arm in C3C_ARMS || arm == "anchor" ||
        push!(iss, "unknown arm token: $arm")
    endpoint in C3C_ENDPOINTS || endpoint == "anchor" ||
        push!(iss, "unknown endpoint token: $endpoint")
    panel in C3C_PANELS ||
        push!(iss, "unknown panel token: $panel")
    # C3 OWNS its mapping (monitor blocker 3/4): panel -> SW pin exact;
    # the anchor row requires arm=anchor/endpoint=anchor/panel=primary
    # and the pinned anchor LW
    want_sw = panel == "primary" ? C3C_PRIMARY_SW_SHA :
        C3C_SECONDARY_SW_SHA
    sw_sha == want_sw ||
        push!(iss, "panel $panel SW sha != pinned panel authority")
    if arm == "anchor" || endpoint == "anchor"
        (arm == "anchor" && endpoint == "anchor" && panel == "primary") ||
            push!(iss, "anchor row must be anchor/anchor/primary")
        lw_sha == C3C_ANCHOR_LW_SHA ||
            push!(iss, "anchor LW sha != pinned anchor authority")
    end
    isempty(iss) || return (iss, nothing)
    aiss, res = p2c_arm_record(lw, sw, "$arm-$endpoint-$panel",
                               lw_sha, sw_sha)
    append!(iss, aiss)
    res === nothing && return (iss, nothing)
    record = "c3ib_arm=" * arm * "\nc3ib_endpoint=" * endpoint *
        "\nc3ib_panel=" * panel * "\n" * res.record
    (iss, (obj = res.obj, record = record))
end

# --- logical identity (control repeatability; committed egal semantics) ------------
function c3c_logical_identical(pa, pb, label)
    iss = String[]
    NCDataset(pa) do da
        NCDataset(pb) do db
            va = sort([String(k) for k in keys(da)])
            vb = sort([String(k) for k in keys(db)])
            va == vb || push!(iss, "$label: variable sets differ")
            for k in intersect(va, vb)
                n = p1c_raw_diff_count(da, db, k)
                n == 0 ||
                    push!(iss, "$label: var $k differs (n=$n or shape)")
            end
        end
    end
    iss
end

# --- anchor gate (severability: recorded determination, never arm-fatal) -----------
function c3c_anchor_determination(record_text)
    iss = String[]
    hits = collect(eachmatch(r"(?m)^objective_bits=([0-9a-f]{16})$",
                             record_text))
    toks = collect(eachmatch(r"(?m)^objective_token=(\S+)$", record_text))
    (length(hits) == 1 && length(toks) == 1) ||
        (push!(iss, "anchor record malformed (objective lines not " *
               "exactly once)"); return (iss, nothing))
    hit = String(hits[1].captures[1]) == c3c_anchor_bits_hex() &&
        String(toks[1].captures[1]) == C3C_ANCHOR_TOKEN
    (iss, hit)
end

# --- full per-record schema map (monitor assist 2: EVERY record is
# schema-mapped to its expected filename key; permutation/tampering
# refuses; anchor validated by exact lines, never occursin)
c3c_line_once(rec, line) = count(==(line), split(rec, '\n')) == 1
# frozen case-set identity pin (design: SL_CASE_INPUTS == REDUCED set)
const C3C_CASE_NAMES = ("ecckd_clear_sky_tropical_column",
                        "ecckd_rcemip_style_column_subset")
c3c_hex16(x) = occursin(r"^[0-9a-f]{16}$", x)
function c3c_tok_bits_ok(tok, bits)
    # canonical-token discipline (monitor fix a): the token must BE the
    # canonical max_digits10 rendering of its value -- a noncanonical
    # alternate decimal with the same bits refuses
    v = tryparse(Float64, tok)
    v !== nothing && isfinite(v) && c3c_hex16(bits) &&
        string(reinterpret(UInt64, v), base = 16, pad = 16) == bits &&
        tok == p2c_tok(v)
end
# FULL 39-line schema (monitor finalizer hold): 3 C3 mapping + 12 P2
# header + 24 ordered rows; hex validity; token<->bits round-trip;
# ordered (case,metric) sequence; objective==argmax-row correspondence
function c3c_record_issues(rec, arm, ep, pn)
    iss = String[]
    label = "$arm-$ep-$pn"
    lines = [String(l) for l in split(rec, '\n') if !isempty(l)]
    length(lines) == 39 ||
        push!(iss, "record $label: line census $(length(lines)) != 39")
    want_sw = pn == "primary" ? C3C_PRIMARY_SW_SHA : C3C_SECONDARY_SW_SHA
    for line in ("c3ib_arm=" * arm, "c3ib_endpoint=" * ep,
                 "c3ib_panel=" * pn, "arm_label=" * label,
                 "state=" * p2c_state(label), "sw_sha=" * want_sw,
                 "invocation=" * P2C_INVOCATION, "rows=24")
        c3c_line_once(rec, line) ||
            push!(iss, "record $label: expected exact-once line " *
                  "missing/duplicated: " * first(line, 40))
    end
    length(collect(eachmatch(r"(?m)^lw_sha=[0-9a-f]{64}$", rec))) == 1 ||
        push!(iss, "record $label: lw_sha line not exactly once/valid")
    arm == "anchor" &&
        (c3c_line_once(rec, "lw_sha=" * C3C_ANCHOR_LW_SHA) ||
         push!(iss, "anchor record: pinned anchor LW sha line not exact-once"))
    hdr = Dict{String, String}()
    for k in ("objective_token", "objective_bits", "objective_case",
              "objective_metric", "objective_metric_value_bits",
              "objective_threshold_bits")
        ms = collect(eachmatch(Regex("(?m)^" * k * "=(\\S+)\$"), rec))
        length(ms) == 1 ?
            (hdr[k] = String(ms[1].captures[1])) :
            push!(iss, "record $label: $k not exactly once")
    end
    rows = [String(l[5:end]) for l in lines if startswith(l, "row ")]
    length(rows) == 24 ||
        push!(iss, "record $label: row lines != 24")
    isempty(iss) || return iss
    c3c_tok_bits_ok(hdr["objective_token"], hdr["objective_bits"]) ||
        push!(iss, "record $label: objective token<->bits mismatch")
    expected_keys = [(c, m) for c in C3C_CASE_NAMES
                     for m in P2C_METRIC_SEQ]
    parsed = NamedTuple[]
    for (ri, r) in enumerate(rows)
        f = split(r, "|")
        length(f) == 8 ||
            (push!(iss, "record $label: row $ri field count != 8");
             continue)
        c3c_tok_bits_ok(String(f[3]), String(f[4])) ||
            push!(iss, "record $label: row $ri value token<->bits mismatch")
        c3c_tok_bits_ok(String(f[5]), String(f[6])) ||
            push!(iss, "record $label: row $ri threshold token<->bits mismatch")
        c3c_tok_bits_ok(String(f[7]), String(f[8])) ||
            push!(iss, "record $label: row $ri normalized token<->bits mismatch")
        let v = tryparse(Float64, String(f[3])),
            th = tryparse(Float64, String(f[5])),
            nv = tryparse(Float64, String(f[7]))
            (v !== nothing && th !== nothing && nv !== nothing &&
             reinterpret(UInt64, v / th) == reinterpret(UInt64, nv)) ||
                push!(iss, "record $label: row $ri normalized != " *
                      "value/threshold (exact Float64 relation)")
        end
        push!(parsed, (case = String(f[1]), metric = String(f[2]),
                       vbits = String(f[4]), tbits = String(f[6]),
                       ntok = String(f[7]), nbits = String(f[8])))
    end
    isempty(iss) || return iss
    [(r.case, r.metric) for r in parsed] == expected_keys ||
        push!(iss, "record $label: row (case,metric) sequence != " *
              "REDUCED_CASES x metric sequence (permutation refused)")
    worst = argmax(r -> parse(Float64, r.ntok), parsed)
    (worst.case == hdr["objective_case"] &&
     worst.metric == hdr["objective_metric"] &&
     worst.vbits == hdr["objective_metric_value_bits"] &&
     worst.tbits == hdr["objective_threshold_bits"] &&
     worst.nbits == hdr["objective_bits"]) ||
        push!(iss, "record $label: objective summary does not " *
              "correspond to the argmax row")
    iss
end

# --- exact-decimal helpers -----------------------------------------------------------
function c3c_delta(t_tok, c_tok)
    a = p1c_decimal_to_rational(t_tok)
    b = p1c_decimal_to_rational(c_tok)
    (a === nothing || b === nothing) && return nothing
    d = a - b
    dec = p1c_rational_to_decimal(d)
    dec === nothing && return nothing
    branch = d < 0 ? "NEGATIVE" : d > 0 ? "POSITIVE" :
        "ZERO-AT-TOKEN-REPRESENTATION"
    (dec = dec, branch = branch)
end

function c3c_placement(tok)
    r = p1c_decimal_to_rational(tok)
    r === nothing && return nothing
    r <= C3C_G1_BOUND
end

# --- compare (duplicates, partitions, placement, severability finalizer) -------------
function c3c_compare(records, marker_text)
    iss = String[]
    out = String[]
    tok = Dict{String, String}()
    for arm in C3C_ARMS, ep in C3C_ENDPOINTS, pn in C3C_PANELS
        key = "$arm-$ep-$pn"
        haskey(records, key) ||
            (push!(iss, "missing score record: $key"); continue)
        m = collect(eachmatch(r"(?m)^objective_token=(\S+)$",
                              records[key]))
        length(m) == 1 ? (tok[key] = String(m[1].captures[1])) :
            push!(iss, "objective token not exactly once: $key")
    end
    # TRUE 13-record finalizer: EVERY record schema-mapped to its key;
    # anchor validated by exact lines and HIT/MISS derived HERE; marker
    # cross-check only
    length(records) == 13 ||
        push!(iss, "record census $(length(records)) != 13")
    for arm in C3C_ARMS, ep in C3C_ENDPOINTS, pn in C3C_PANELS
        haskey(records, "$arm-$ep-$pn") &&
            append!(iss, c3c_record_issues(records["$arm-$ep-$pn"],
                                           arm, ep, pn))
    end
    # cross-panel LW-provenance cross-check (monitor addition): the
    # primary and secondary records of the same arm+endpoint score the
    # SAME file and must carry the identical lw_sha; SW stays
    # panel-pinned; the anchor LW stays the fixed authority
    for arm in C3C_ARMS, ep in C3C_ENDPOINTS
        (haskey(records, "$arm-$ep-primary") &&
         haskey(records, "$arm-$ep-secondary")) ||
            (push!(iss, "cross-panel LW cross-check: record(s) missing " *
                   "($arm/$ep); fail-closed refusal"); continue)
        ma = match(r"(?m)^lw_sha=([0-9a-f]{64})$",
                   records["$arm-$ep-primary"])
        mb = match(r"(?m)^lw_sha=([0-9a-f]{64})$",
                   records["$arm-$ep-secondary"])
        (ma === nothing || mb === nothing) &&
            (push!(iss, "lw_sha line unparseable ($arm/$ep)"); continue)
        String(ma.captures[1]) == String(mb.captures[1]) ||
            push!(iss, "cross-panel LW provenance mismatch ($arm/$ep): " *
                  "primary and secondary scored different files")
    end
    anchor_hit = nothing
    if haskey(records, "anchor-anchor-primary")
        ar = records["anchor-anchor-primary"]
        append!(iss, c3c_record_issues(ar, "anchor", "anchor", "primary"))
        aiss, hit = c3c_anchor_determination(ar)
        append!(iss, aiss)
        anchor_hit = hit
    else
        push!(iss, "anchor score record missing from census")
    end
    marker_text in ("HIT", "MISS") ||
        push!(iss, "anchor marker text invalid (must be exactly HIT or MISS)")
    (anchor_hit !== nothing && marker_text in ("HIT", "MISS") &&
     (anchor_hit ? "HIT" : "MISS") != marker_text) &&
        push!(iss, "anchor marker cross-check mismatch vs derived determination")
    isempty(iss) || return (iss, out)
    # same-job control repeatability on score records (payload equality
    # minus the arm_label line; c3ib_arm line differs lawfully)
    # strip arm-identifying lines INCLUDING the P2-embedded state= line
    # (p2c_state of a C3 label differs across arms; C3 owns its own
    # arm/endpoint/panel mapping -- monitor implementation assist)
    # equality payload = endpoint/panel/SW/invocation/objective/rows;
    # arm identity AND per-file LW provenance stripped (control outputs
    # are logically identical but byte-distinct files -- S1 precedent;
    # provenance stays in the records, just not in this equality)
    strip_arm(r) = join([l for l in split(r, '\n')
                         if !startswith(l, "arm_label=") &&
                            !startswith(l, "state=") &&
                            !startswith(l, "lw_sha=") &&
                            !startswith(l, "c3ib_arm=")], "\n")
    for ep in C3C_ENDPOINTS, pn in C3C_PANELS
        strip_arm(records["c0a-$ep-$pn"]) ==
            strip_arm(records["c0b-$ep-$pn"]) ||
            push!(iss, "control score records differ (c0a vs c0b, " *
                  "$ep/$pn): recorded drift; delta assignment refused; " *
                  "values never averaged")
    end
    isempty(iss) || return (iss, out)
    for ep in C3C_ENDPOINTS, pn in C3C_PANELS
        d = c3c_delta(tok["c3ib-$ep-$pn"], tok["c0a-$ep-$pn"])
        d === nothing &&
            (push!(iss, "delta unparseable for $ep/$pn"); continue)
        push!(out, "C3IB DELTA treatment-minus-control [$ep/$pn]: " *
              d.dec * " BRANCH=" * d.branch *
              " (exact decimal on recorded tokens; no threshold; no " *
              "descent-implies-improvement inference)")
    end
    for arm in C3C_ARMS, ep in C3C_ENDPOINTS
        pl = c3c_placement(tok["$arm-$ep-primary"])
        pl === nothing && (push!(iss, "placement unparseable $arm/$ep");
                           continue)
        push!(out, "C3IB G1-BOUND PLACEMENT [primary $arm/$ep]: " *
              (pl ? "AT-OR-UNDER 1.05 -- PRIVATE PLACEMENT under this " *
                    "fixed setup, NOT recovered acceptance (acceptance " *
                    "remains exclusively the committed external gate)" :
                    "ABOVE 1.05 (descriptive placement)"))
    end
    # fix 8: the anchor licenses EXACTLY the bridge phrase
    # "current-G1-adjacent"; a hit emits it, a miss suppresses it
    # entirely while preserving every arm output line above
    push!(out, anchor_hit === true ?
        C3C_ADJ_LICENSED * " -- arm placements are current-G1-adjacent " *
        "(anchor reproduced " * C3C_ANCHOR_TOKEN * " bit-exactly; hit " *
        "does not refresh or reconfirm the committed terminal Gate-1 " *
        "state)" :
        C3C_ADJ_REFUSED * " (anchor miss RECORDED; adjacency labels " *
        "suppressed; arm evidence preserved as fixed-setup placements; " *
        "the committed Gate-1 state stands on its own ledger)")
    push!(out, "C3IB CEILING: private fixed-setup budget association " *
          "only; no recovered acceptance; no recovery claim; no " *
          "mechanism localization or ranking; no objective/data change " *
          "authorization; no automatic escalation; the external <=1.05 " *
          "gate untouched.")
    (iss, out)
end

# --- parameterized structural scan (fix 4: every raw2/final gated
# BEFORE scoring; raw2 vs the staged init signature, final vs the
# staged anchor-LW signature; nonfinite recorded, never refused) -------
function c3c_scan_structural(path, ref, ref_sha, label)
    iss = String[]
    out = String[]
    biss, sd = p1c_bracketed(ref, ref_sha) do
        p1c_signature_and_dims(ref)
    end
    append!(iss, biss)
    sd === nothing && return (iss, out)
    bad, nf = p1c_schema_value_check(path, "structural", sd[1], sd[2])
    append!(iss, ["$label structural: " * b for b in bad])
    for (k, n) in nf
        push!(out, "NONFINITE RECORD ($label): var=$k count=$n -- " *
              "lawful recorded observation, never a refusal")
    end
    isempty(bad) && push!(out, "structural scan passed ($label)")
    (iss, out)
end

# --- upstream endpoint records (fix 1: base terminal status/cost/
# gradient tokens at PRINTED precision; C0a=C0b terminal-status
# equality; exact-partition treatment-minus-control upstream deltas;
# NEVER numerically mixed with package objectives) ----------------------
const C3C_STATUS_ALLOWED = ("Converged", "Maximum iterations reached")
function c3c_upstream_parse(text)
    # exact three-key census (monitor Delta-1 hardening): each key
    # exactly once, NO unknown/extra lines -- duplicate/decoy/moved
    # fields refuse
    iss = String[]
    lines = [String(l) for l in split(text, '\n') if !isempty(l)]
    length(lines) == 3 ||
        push!(iss, "upstream record line census $(length(lines)) != 3")
    st = collect(eachmatch(r"(?m)^status=(.+)$", text))
    co = collect(eachmatch(r"(?m)^cost_token=(\S+)$", text))
    gr = collect(eachmatch(r"(?m)^gradient_token=(\S+)$", text))
    (length(st) == 1 && length(co) == 1 && length(gr) == 1) ||
        push!(iss, "upstream record keys not exactly once each " *
              "(status=$(length(st)) cost=$(length(co)) " *
              "gradient=$(length(gr)))")
    for l in lines
        (startswith(l, "status=") || startswith(l, "cost_token=") ||
         startswith(l, "gradient_token=")) ||
            push!(iss, "upstream record unknown line: " * first(l, 40))
    end
    isempty(iss) || return (iss, nothing)
    (iss, (status = String(st[1].captures[1]),
           cost = String(co[1].captures[1]),
           gradient = String(gr[1].captures[1])))
end
# frozen ss5-7 scope (monitor clarification): per-pass = base +
# relative-ch4 + relative-n2o + relative-cfc for EACH sandwich arm --
# exact 3x4 census, per-pass C0a=C0b terminal-status equality, per-pass
# treatment-minus-control partitions for cost AND gradient; the probe
# is structural-only (terminal evidence recorded/gated separately,
# never in treatment deltas)
const C3C_PASSES = ["base", "relative-ch4", "relative-n2o",
                    "relative-cfc"]
function c3c_upstream_compare(recs)
    iss = String[]
    out = String[]
    length(recs) == 12 ||
        push!(iss, "upstream record census $(length(recs)) != 12 (3x4)")
    for arm in C3C_ARMS, pass in C3C_PASSES
        haskey(recs, "$arm-$pass") ||
            push!(iss, "missing upstream record: $arm-$pass")
    end
    isempty(iss) || return (iss, out)
    for arm in C3C_ARMS, pass in C3C_PASSES
        recs["$arm-$pass"].status in C3C_STATUS_ALLOWED ||
            push!(iss, "$arm-$pass terminal status " *
                  repr(recs["$arm-$pass"].status) *
                  " outside the allowed set")
    end
    for pass in C3C_PASSES
        recs["c0a-$pass"].status == recs["c0b-$pass"].status ||
            push!(iss, "C0a/C0b terminal-status inequality at pass " *
                  "$pass (control repeatability refusal)")
    end
    isempty(iss) || return (iss, out)
    for pass in C3C_PASSES, f in (:cost, :gradient)
        a = p1c_decimal_to_rational(getfield(recs["c3ib-$pass"], f))
        b = p1c_decimal_to_rational(getfield(recs["c0a-$pass"], f))
        (a === nothing || b === nothing) &&
            (push!(iss, "upstream $f token unparseable at $pass");
             continue)
        d = a - b
        dec = p1c_rational_to_decimal(d)
        br = d < 0 ? "NEGATIVE" : d > 0 ? "POSITIVE" :
            "ZERO-AT-TOKEN-REPRESENTATION"
        push!(out, "C3IB UPSTREAM DELTA treatment-minus-control " *
              "[$pass $f]: " * dec * " BRANCH=" * br *
              " (exact decimal on tokens AT PRINTED PRECISION; " *
              "upstream instrument only; never numerically compared " *
              "to package objectives)")
    end
    for pass in C3C_PASSES
        push!(out, "C3IB UPSTREAM STATUS RECORD [$pass]: c0a='" *
              recs["c0a-$pass"].status * "' c3ib='" *
              recs["c3ib-$pass"].status * "' c0b='" *
              recs["c0b-$pass"].status * "'")
    end
    (iss, out)
end

# --- CLI -------------------------------------------------------------------------------
function c3c_main(args)
    isempty(args) && (println("C3C REFUSE: no mode given"); return 1)
    mode = args[1]
    iss = String[]
    out = String[]
    if mode == "score" && length(args) == 9
        lw, sw, outp, arm, ep, pn, lsha, ssha = args[2:9]
        c3c_sha(lw) == lsha ||
            push!(iss, "score $arm/$ep/$pn: LW sha != provenance pin")
        c3c_sha(sw) == ssha ||
            push!(iss, "score $arm/$ep/$pn: SW sha != provenance pin")
        if isempty(iss)
            siss, res = c3c_score_record(lw, sw, arm, ep, pn, lsha, ssha)
            append!(iss, siss)
            if res !== nothing && isempty(iss)
                write(outp, res.record)
                push!(out, "score $arm/$ep/$pn: objective=" *
                      @sprintf("%.17g", res.obj.value))
            end
        end
    elseif mode == "scan" && length(args) == 5
        siss, sout = c3c_scan_structural(args[2], args[3], args[4],
                                         args[5])
        append!(iss, siss)
        append!(out, sout)
    elseif mode == "upstream" && length(args) == 2
        recs = Dict{String, Any}()
        for arm in C3C_ARMS, pass in C3C_PASSES
            f = joinpath(args[2], "$arm-$pass-upstream.txt")
            isfile(f) || (push!(iss, "missing upstream file: " *
                                "$arm-$pass"); continue)
            uiss, r = c3c_upstream_parse(read(f, String))
            append!(iss, uiss)
            r !== nothing && (recs["$arm-$pass"] = r)
        end
        pf = joinpath(args[2], "probe-base-upstream.txt")
        if isfile(pf)
            piss, pr = c3c_upstream_parse(read(pf, String))
            append!(iss, piss)
            if pr !== nothing
                pr.status in C3C_STATUS_ALLOWED ||
                    push!(iss, "probe terminal status " *
                          repr(pr.status) * " outside the allowed set")
                push!(out,
                    "C3IB PROBE TERMINAL RECORD (structural-only; " *
                    "outside treatment deltas): status='" *
                    pr.status * "'")
            end
        else
            push!(iss, "probe upstream record missing")
        end
        if isempty(iss)
            uiss, uout = c3c_upstream_compare(recs)
            append!(iss, uiss)
            append!(out, uout)
        end
    elseif mode == "identity" && length(args) == 4
        iss = c3c_logical_identical(args[2], args[3], args[4])
        isempty(iss) && push!(out,
            "logical identity holds: " * args[4])
    elseif mode == "anchor" && length(args) == 3
        rec, marker = args[2], args[3]
        isfile(rec) || (push!(iss, "anchor record missing"); rec = "")
        if isempty(iss)
            aiss, hit = c3c_anchor_determination(read(rec, String))
            append!(iss, aiss)
            if hit !== nothing
                write(marker, hit ? "HIT\n" : "MISS\n")
                push!(out, hit ?
                    "anchor HIT recorded (adjacency licensable)" :
                    "anchor MISS recorded (adjacency will be refused; " *
                    "arm evidence unaffected)")
            end
        end
    elseif mode == "compare" && length(args) == 2
        runroot = args[2]
        records = Dict{String, String}()
        names = vcat(["$arm-$ep-$pn" for arm in C3C_ARMS
                      for ep in C3C_ENDPOINTS for pn in C3C_PANELS],
                     ["anchor-anchor-primary"])
        # directory scan census: the EXACT expected 13-name set; any
        # extra score-*.txt refuses (monitor assist 3)
        found = sort([f for f in readdir(runroot)
                      if startswith(f, "score-") && endswith(f, ".txt")])
        expected = sort(["score-$nm.txt" for nm in names])
        found == expected ||
            push!(iss, "score-record directory census mismatch: found " *
                  string(found) * " != expected " * string(expected))
        for nm in names
            p = joinpath(runroot, "score-$nm.txt")
            isfile(p) ? (records[nm] = read(p, String)) :
                push!(iss, "missing score record file: $p")
        end
        mk = joinpath(runroot, "anchor-marker.txt")
        marker = isfile(mk) ? String(strip(read(mk, String))) :
            (push!(iss, "anchor marker missing"); "")
        if isempty(iss)
            ciss, cout = c3c_compare(records, marker)
            append!(iss, ciss)
            append!(out, cout)
        end
    else
        push!(iss, "unknown mode or wrong arity: " * join(args, " "))
    end
    foreach(println, out)
    if isempty(iss)
        println("C3C PASS: $mode")
        return 0
    end
    foreach(i -> println("C3C REFUSE: $i"), iss)
    return 1
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(c3c_main(ARGS))
end
