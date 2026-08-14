# Gate-4 P1 SPLICE/TOKEN CHECKER (shared in-job + fixture functions).
#
# Frozen design authority: gate4_p1_frozen_design.md sha256
# 288dda9e8549da32bed972d55a58c0a3e2ca1d2f9c05cce3d2ad6001b4cdb4e1.
#
# This ONE file is (a) staged read-only into the P1 RUNROOT and invoked
# by the generated sbatch as a CLI (modes: build-splice / gate-splice /
# gate-plateau / scan-structural / tokens / compare), and (b) included
# by the checkpoint generator so every gate function is behaviorally
# fixture-tested against the SAME code the job runs -- no dual
# implementation. All functions are parameterized (pins as keyword
# defaults) so fixtures exercise the same code paths on tiny synthetic
# files. Fail-closed everywhere: any issue prints "P1C REFUSE:" and
# exits 1; value policy is the committed two-tier policy (STRUCTURE
# failures and MISSING values refuse in every mode; numeric
# nonfinite values are lawful RECORDED observations in structural
# mode only). J0_reported token semantics (binding): the extracted
# tokens are max_digits10 round-trip decimal representations of the
# represented Real values; comparisons are EXACT TEXTUAL equality and
# token-derived signed decimal deltas bounded by stream precision;
# values are never averaged; "bit-equality" language is banned.

using NCDatasets
using Printf
using SHA: sha256

# --- pinned input states (content pins; location-neutral) --------------------
const P1C_INIT_PATH = "/shared/home/greg/ecckd-derived-flux-work/" *
    "g4-init-generation/work/lw_raw-ckd-definition/" *
    "ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc"
const P1C_INIT_SHA = "ce05707934e89dfea27c52352f8ca22f0cc28467daac3c122dae7c81edaf7b43"
const P1C_INIT_BYTES = 2413144
const P1C_PUB_PATH = "/shared/home/greg/.julia/artifacts/" *
    "49ce668ce0861f9d5e8299d68af7138485eb5f19/" *
    "ecrad-131ac980517719b7a859e3ccc117919a1d888a20/data/" *
    "ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc"
const P1C_PUB_SHA = "6087f62f9052653f8e7dbee26cef8bf1977c2516669a169bee8d110b62912ed9"
const P1C_PUB_BYTES = 869280
const P1C_PLATEAU_SHA = "49ff3df8c02a1b62f7bfa6cd4b8dc2c6c96e93079c1d042eb8cfb5fc49c61e37"
const P1C_PLATEAU_BYTES = 2415304

# --- the eight-gas coefficient block + pinned differing-element counts -------
p1c_coeff(g) = g * "_molar_absorption_coeff"
const P1C_GASES = ["composite", "h2o", "o3", "co2", "ch4", "n2o",
                   "cfc11", "cfc12"]
const P1C_ACTIVE = ["composite", "h2o", "o3", "co2"]
const P1C_PUB_DIFF = [("composite", 9686), ("h2o", 121016), ("o3", 9936),
                      ("co2", 9643), ("ch4", 7039), ("n2o", 8752),
                      ("cfc11", 3207), ("cfc12", 3395)]
const P1C_PLAT_DIFF = [("composite", 9677), ("h2o", 121461), ("o3", 9997),
                       ("co2", 9641)]

# --- probe/token pins ---------------------------------------------------------
const P1C_WS = ["init-a", "published-a", "plateau-a", "plateau-b",
                "published-b", "init-b"]
const P1C_TARGETS = ["init", "plateau", "published"]
p1c_target(ws) = String(rsplit(ws, "-"; limit = 2)[1])
const P1C_ROUNDED_INIT = ("2357.13", "1026.13")
const P1C_PROOF = (8, 53, 15, 17)   # sizeof_Real/mantissa_digits/digits10/max_digits10 (OBSERVED values binding)

p1c_sha(path) = open(io -> bytes2hex(sha256(io)), path)

# sha-bracketed read: verify the pin BEFORE and AFTER f() (re-bracketing)
function p1c_bracketed(f, path, sha)
    iss = String[]
    isfile(path) || (push!(iss, "missing pinned file: $path");
                     return (iss, nothing))
    pre = p1c_sha(path)
    pre == sha || (push!(iss, "pre-open sha $pre != pinned $sha: $path");
                   return (iss, nothing))
    val = f()
    post = p1c_sha(path)
    post == sha ||
        push!(iss, "post-close sha $post != pinned $sha: $path")
    (iss, val)
end

# --- signature/dims derivation (pinned-init sole authority) -------------------
function p1c_signature_and_dims(path)
    NCDataset(path) do ds
        sig = [k * "|" * string(eltype(ds[k].var)) * "|" *
               join(String.(dimnames(ds[k])), ",")
               for k in sort([String(x) for x in keys(ds)])]
        dims = sort([(String(k), Int(ds.dim[k])) for k in keys(ds.dim)];
                    by = first)
        (sig, dims)
    end
end

# --- shared schema+value check (reviewed C1 semantics, carried forward) ------
# STRUCTURE faults (schema/dims/vars/types/missing/unreadable/empty)
# refuse in EVERY mode; nonfinite VALUES refuse in strict mode and are
# RECORDED (never refused) in structural mode.
function p1c_schema_value_check(path, mode, sig_lines, dims_expect)
    bad = String[]
    nf = Tuple{String, Int}[]
    sig = Dict{String, Tuple{String, Vector{String}}}()
    for l in sig_lines
        parts = split(l, "|")
        if length(parts) != 3
            push!(bad, "malformed signature line: " * l)
            continue
        end
        sig[String(parts[1])] = (String(parts[2]),
            String.(split(parts[3], ","; keepempty = false)))
    end
    NCDataset(path) do ds
        dims_have = sort([String(k) for k in keys(ds.dim)])
        dims_want = sort([String(first(d)) for d in dims_expect])
        dims_have == dims_want ||
            push!(bad, "dimension name set " * string(dims_have) *
                " != pinned " * string(dims_want))
        for (d, v) in dims_expect
            (haskey(ds.dim, d) && ds.dim[d] == v) ||
                push!(bad, "dim " * d * " != " * string(v))
        end
        have = sort([String(k) for k in keys(ds)])
        expected = sort(collect(keys(sig)))
        for v in setdiff(expected, have)
            push!(bad, "var missing: " * v)
        end
        for v in setdiff(have, expected)
            push!(bad, "unexpected extra var: " * v)
        end
        for k in intersect(expected, have)
            et, dn = sig[k]
            tok = true
            if string(eltype(ds[k].var)) != et
                push!(bad, "var " * k * " stored type " *
                    string(eltype(ds[k].var)) * " != pinned " * et)
                tok = false
            end
            if collect(String.(dimnames(ds[k]))) != dn
                push!(bad, "var " * k * " dims " *
                    string(collect(String.(dimnames(ds[k])))) *
                    " != pinned signature")
                tok = false
            end
            tok || continue
            a = try
                Array(ds[k])
            catch
                push!(bad, "unreadable var " * k)
                continue
            end
            length(a) > 0 || push!(bad, "var empty: " * k)
            any(ismissing, a) && push!(bad, "missing values in " * k)
            n = count(!isfinite, skipmissing(a))
            if mode == "strict"
                n == 0 || push!(bad, "nonfinite values in " * k)
            elseif n > 0
                push!(nf, (String(k), n))
            end
        end
    end
    (bad, nf)
end

# raw (egal, nonfinite-aware) elementwise differing count on stored values
function p1c_raw_diff_count(dsa, dsb, name)
    a = Array(dsa[name].var)
    b = Array(dsb[name].var)
    size(a) == size(b) || return -1
    count(x -> x[1] !== x[2], zip(a, b))
end

p1c_attrs(obj) = Dict(String(k) => obj.attrib[k] for k in keys(obj.attrib))

# --- splice construction (private temp only; never canonical) -----------------
function p1c_build_splice(initp, pubp, outp; gases = P1C_GASES,
                          init_sha = P1C_INIT_SHA, pub_sha = P1C_PUB_SHA)
    iss = String[]
    biss, _ = p1c_bracketed(initp, init_sha) do
        write(outp, read(initp))
        nothing
    end
    append!(iss, biss)
    isempty(iss) || return iss
    piss, _ = p1c_bracketed(pubp, pub_sha) do
        NCDataset(outp, "a") do dso
            NCDataset(pubp) do dsp
                for g in gases
                    v = p1c_coeff(g)
                    haskey(dso, v) ||
                        (push!(iss, "splice target var missing in init copy: $v");
                         continue)
                    haskey(dsp, v) ||
                        (push!(iss, "published var missing: $v"); continue)
                    to, tp = dso[v].var, dsp[v].var
                    eltype(to) == eltype(tp) ||
                        (push!(iss, "type mismatch for $v: init " *
                               string(eltype(to)) * " vs published " *
                               string(eltype(tp))); continue)
                    collect(String.(dimnames(dso[v]))) ==
                        collect(String.(dimnames(dsp[v]))) ||
                        (push!(iss, "dimension-name mismatch for $v");
                         continue)
                    size(to) == size(tp) ||
                        (push!(iss, "shape mismatch for $v"); continue)
                    arr = Array(tp)
                    to[ntuple(_ -> Colon(), ndims(arr))...] = arr
                end
            end
        end
        nothing
    end
    append!(iss, piss)
    iss
end

# --- splice integrity gate -----------------------------------------------------
# exact EIGHT-variable logical typed diff vs init (nonfinite-aware egal
# semantics); exact published-value equality per gas; pinned per-array
# differing-element counts (each must be > 0: identical array is
# evidence and refuses); all other vars/dims/attrs unchanged from init;
# full pinned-signature strict scan (finite/nonmissing).
function p1c_gate_splice(splicep, initp, pubp; gases = P1C_GASES,
                         pub_diff = P1C_PUB_DIFF,
                         init_sha = P1C_INIT_SHA, pub_sha = P1C_PUB_SHA)
    iss = String[]
    diffcounts = Dict{String, Int}()
    biss, sd = p1c_bracketed(initp, init_sha) do
        p1c_signature_and_dims(initp)
    end
    append!(iss, biss)
    sd === nothing && return (iss, diffcounts)
    sig, dims = sd
    bad, _ = p1c_schema_value_check(splicep, "strict", sig, dims)
    append!(iss, ["splice strict scan: " * b for b in bad])
    giss, _ = p1c_bracketed(initp, init_sha) do
        piss, _ = p1c_bracketed(pubp, pub_sha) do
            NCDataset(splicep) do dss
                NCDataset(initp) do dsi
                    NCDataset(pubp) do dsp
                        gaset = sort([p1c_coeff(g) for g in gases])
                        allv = sort([String(k) for k in keys(dsi)])
                        difflist = String[]
                        for k in allv
                            haskey(dss, k) || continue  # strict scan already refused
                            n = p1c_raw_diff_count(dss, dsi, k)
                            n == -1 && (push!(iss, "shape drift vs init: $k");
                                        continue)
                            n > 0 && push!(difflist, k)
                            (k in gaset) && (diffcounts[k] = n)
                        end
                        difflist == gaset ||
                            push!(iss, "logical typed diff set vs init " *
                                  string(difflist) * " != the eight-gas " *
                                  "coefficient block " * string(gaset))
                        for (g, want) in pub_diff
                            v = p1c_coeff(g)
                            got = get(diffcounts, v, -2)
                            got == want ||
                                push!(iss, "differing-element count for $v " *
                                      "$got != pinned $want")
                            got > 0 ||
                                push!(iss, "per-variable nonzero-diff gate: " *
                                      "$v identical to init (evidence; refuse)")
                            haskey(dsp, v) || continue
                            pe = p1c_raw_diff_count(dss, dsp, v)
                            pe == 0 ||
                                push!(iss, "splice $v != published values " *
                                      "exactly (differing elements: $pe)")
                        end
                        isequal(p1c_attrs(dss), p1c_attrs(dsi)) ||
                            push!(iss, "global attributes differ from init")
                        for k in allv
                            haskey(dss, k) || continue
                            isequal(p1c_attrs(dss[k]), p1c_attrs(dsi[k])) ||
                                push!(iss, "attributes differ from init: $k")
                        end
                    end
                end
            end
            nothing
        end
        append!(iss, piss)
        nothing
    end
    append!(iss, giss)
    (iss, diffcounts)
end

# --- plateau state gate ---------------------------------------------------------
# pinned four-active diff counts vs init + four-minor exact equality +
# full pinned-signature strict scan (contract point 4).
function p1c_gate_plateau(platp, initp; gases = P1C_GASES,
                          active = P1C_ACTIVE, plat_diff = P1C_PLAT_DIFF,
                          init_sha = P1C_INIT_SHA,
                          plat_sha = P1C_PLATEAU_SHA)
    iss = String[]
    diffcounts = Dict{String, Int}()
    biss, sd = p1c_bracketed(initp, init_sha) do
        p1c_signature_and_dims(initp)
    end
    append!(iss, biss)
    sd === nothing && return (iss, diffcounts)
    sig, dims = sd
    piss, _ = p1c_bracketed(platp, plat_sha) do
        bad, _ = p1c_schema_value_check(platp, "strict", sig, dims)
        append!(iss, ["plateau strict scan: " * b for b in bad])
        NCDataset(platp) do dsl
            NCDataset(initp) do dsi
                activeset = sort([p1c_coeff(g) for g in active])
                allv = sort([String(k) for k in keys(dsi)])
                difflist = String[]
                for k in allv
                    haskey(dsl, k) || continue
                    n = p1c_raw_diff_count(dsl, dsi, k)
                    n == -1 && (push!(iss, "shape drift vs init: $k");
                                continue)
                    n > 0 && push!(difflist, k)
                    any(p1c_coeff(g) == k for g in gases) &&
                        (diffcounts[k] = n)
                end
                difflist == activeset ||
                    push!(iss, "plateau logical diff set vs init " *
                          string(difflist) * " != the four base-active " *
                          "arrays " * string(activeset))
                for (g, want) in plat_diff
                    v = p1c_coeff(g)
                    got = get(diffcounts, v, -2)
                    got == want ||
                        push!(iss, "plateau differing-element count for " *
                              "$v $got != pinned $want")
                end
                for g in setdiff(gases, active)
                    v = p1c_coeff(g)
                    got = get(diffcounts, v, -2)
                    got == 0 ||
                        push!(iss, "minor-gas array $v not exactly equal " *
                              "to init (differing elements: $got)")
                end
            end
        end
        nothing
    end
    append!(iss, piss)
    (iss, diffcounts)
end

# --- iteration-0 token extraction (J0_reported semantics) ------------------------
# The rounded line is the six-significant-figure formatted log token
# family; P1_ITER0_FULL carries max_digits10 round-trip tokens plus the
# four inline proof fields (OBSERVED values binding). Nonfinite or
# unparseable tokens REFUSE; each full token must round back to its
# ordinary token at 6 significant figures (both-direction bridge).
function p1c_extract_tokens(text; proof = P1C_PROOF)
    iss = String[]
    lines = split(text, '\n')
    rl = [l for l in lines if startswith(l, "Iteration 0: cost function = ")]
    fl = [l for l in lines if startswith(l, "P1_ITER0_FULL: ")]
    length(rl) == 1 ||
        push!(iss, "rounded Iteration-0 line count $(length(rl)) != 1")
    length(fl) == 1 ||
        push!(iss, "P1_ITER0_FULL line count $(length(fl)) != 1")
    isempty(iss) || return (iss, nothing)
    m = match(r"^Iteration 0: cost function = (\S+), gradient norm = (\S+)$",
              rl[1])
    m === nothing && (push!(iss, "malformed rounded Iteration-0 line");
                      return (iss, nothing))
    fm = match(r"^P1_ITER0_FULL: cost_function = (\S+), gradient_norm = (\S+), sizeof_Real = (\d+), mantissa_digits = (\d+), digits10 = (\d+), max_digits10 = (\d+)$",
               fl[1])
    fm === nothing && (push!(iss, "malformed P1_ITER0_FULL line");
                       return (iss, nothing))
    got_proof = (parse(Int, fm[3]), parse(Int, fm[4]), parse(Int, fm[5]),
                 parse(Int, fm[6]))
    got_proof == proof ||
        push!(iss, "OBSERVED Real proof fields (sizeof_Real, " *
              "mantissa_digits, digits10, max_digits10) $got_proof != " *
              "binding $proof")
    fc = tryparse(Float64, fm[1])
    fg = tryparse(Float64, fm[2])
    (fc === nothing || !isfinite(fc)) &&
        push!(iss, "full cost token unparseable or nonfinite: $(fm[1])")
    (fg === nothing || !isfinite(fg)) &&
        push!(iss, "full gradient token unparseable or nonfinite: $(fm[2])")
    isempty(iss) || return (iss, nothing)
    @sprintf("%.6g", fc) == m[1] ||
        push!(iss, "full cost token $(fm[1]) does not round back to " *
              "ordinary token $(m[1]) at 6 significant figures")
    @sprintf("%.6g", fg) == m[2] ||
        push!(iss, "full gradient token $(fm[2]) does not round back to " *
              "ordinary token $(m[2]) at 6 significant figures")
    tokens = (full_cost = String(fm[1]), full_gnorm = String(fm[2]),
              rounded_cost = String(m[1]), rounded_gnorm = String(m[2]))
    (iss, isempty(iss) ? tokens : nothing)
end

p1c_tokens_to_lines(t) = ["full_cost=" * t.full_cost,
                          "full_gnorm=" * t.full_gnorm,
                          "rounded_cost=" * t.rounded_cost,
                          "rounded_gnorm=" * t.rounded_gnorm]

function p1c_tokens_from_lines(text)
    d = Dict{String, String}()
    for l in split(text, '\n'; keepempty = false)
        parts = split(l, "="; limit = 2)
        length(parts) == 2 && (d[String(parts[1])] = String(parts[2]))
    end
    all(haskey(d, k) for k in ("full_cost", "full_gnorm", "rounded_cost",
                               "rounded_gnorm")) || return nothing
    (full_cost = d["full_cost"], full_gnorm = d["full_gnorm"],
     rounded_cost = d["rounded_cost"], rounded_gnorm = d["rounded_gnorm"])
end

# --- exact decimal token arithmetic (monitor blocker fix) ------------------------
# The reported tokens are DECIMAL strings; rev6 defines the deltas as
# token-derived signed DECIMAL deltas. Binary Float64 subtraction can
# round/collapse near-equal tokens and misplace the
# zero-at-token-representation branch, so tokens are parsed EXACTLY
# (sign, decimal point, e/E exponent) into Rational{BigInt}; the three
# deltas are computed exactly; the sign branch is the exact rational
# sign; formatting is the canonical exact terminating decimal (token
# differences always have a 2^a*5^b denominator, so they terminate).
function p1c_decimal_to_rational(tok)
    m = match(r"^([+-]?)(\d+)(?:\.(\d+))?(?:[eE]([+-]?\d+))?$", tok)
    m === nothing && return nothing
    sgn = m[1] == "-" ? -1 : 1
    frac = m[3] === nothing ? "" : m[3]
    ex = m[4] === nothing ? 0 : parse(Int, m[4])
    val = parse(BigInt, m[2] * frac)
    scale = ex - length(frac)
    r = Rational{BigInt}(sgn * val)
    scale >= 0 ? r * BigInt(10)^scale : r // BigInt(10)^(-scale)
end

function p1c_rational_to_decimal(r)
    r == 0 && return "0"
    neg = r < 0
    a = abs(r)
    den = denominator(a)
    k = 0
    d = den
    while d != 1
        if d % 2 == 0
            d = div(d, 2)
        elseif d % 5 == 0
            d = div(d, 5)
        else
            return nothing   # non-terminating decimal: cannot arise from token differences
        end
        k += 1
    end
    scaled = numerator(a) * BigInt(10)^k
    scaled % den == 0 || return nothing
    s = string(div(scaled, den))
    if k == 0
        dec = s
    else
        s = lpad(s, k + 1, '0')
        ip = s[1:(end - k)]
        fp = rstrip(s[(end - k + 1):end], '0')
        dec = isempty(fp) ? ip : ip * "." * fp
    end
    (neg ? "-" : "") * dec
end

# --- six-probe comparison (duplicate gates, deltas, sign branch) -----------------
# ONLY after every duplicate and schema gate: per-target duplicate
# EXACT TEXTUAL token equality + terminal-status equality; probe
# statuses are RECORDED observations, NOT gated against a membership
# allowlist (frozen rev6 section 5: allowlist NOT applied to probes --
# probe status is not scientific evidence; monitor ruling supersedes
# the C1-era pattern); status capture must be NONEMPTY and per-target
# EXACTLY EQUAL. Then Ji/Jp/Js and the three token-derived signed
# decimal deltas (exact decimal arithmetic) with the sign partition on
# D_splice_plateau. Values are NEVER averaged; a duplicate mismatch is
# recorded drift AND a refusal for branch assignment. No acceptance,
# reachability, mechanism, floor/ratio, comparator, data/objective-
# change, or next-control claim is emitted in any branch.
function p1c_compare(tok, st; ws = P1C_WS, targets = P1C_TARGETS,
                     rounded_init = P1C_ROUNDED_INIT)
    iss = String[]
    out = String[]
    for w in ws
        haskey(tok, w) || push!(iss, "missing token record: $w")
        haskey(st, w) || push!(iss, "missing status record: $w")
    end
    isempty(iss) || return (iss, out)
    for w in ws
        isempty(st[w]) &&
            push!(iss, "probe $w terminal status capture is empty " *
                  "(capture fault; statuses are recorded, never gated " *
                  "by membership)")
    end
    for t in targets
        a, b = "$t-a", "$t-b"
        st[a] == st[b] ||
            push!(iss, "target $t terminal-status inequality: " *
                  repr(st[a]) * " vs " * repr(st[b]))
        for f in (:full_cost, :full_gnorm, :rounded_cost, :rounded_gnorm)
            getfield(tok[a], f) == getfield(tok[b], f) ||
                push!(iss, "target $t duplicate token drift in $f: " *
                      getfield(tok[a], f) * " vs " * getfield(tok[b], f) *
                      " (recorded drift; refusal for branch assignment; " *
                      "values are never averaged)")
        end
    end
    (tok["init-a"].rounded_cost == rounded_init[1] &&
     tok["init-a"].rounded_gnorm == rounded_init[2]) ||
        push!(iss, "init ordinary tokens (" * tok["init-a"].rounded_cost *
              ", " * tok["init-a"].rounded_gnorm * ") != committed bridge " *
              "tokens $(rounded_init) (drift is evidence, not absorbed)")
    isempty(iss) || return (iss, out)
    ji = p1c_decimal_to_rational(tok["init-a"].full_cost)
    jp = p1c_decimal_to_rational(tok["plateau-a"].full_cost)
    js = p1c_decimal_to_rational(tok["published-a"].full_cost)
    for (n, v) in (("Ji", ji), ("Jp", jp), ("Js", js))
        v === nothing &&
            push!(iss, "$n token is not an exact-decimal-parseable token")
    end
    isempty(iss) || return (iss, out)
    d_sp = js - jp
    d_si = js - ji
    d_pi = jp - ji
    dd = Dict("D_splice_plateau" => p1c_rational_to_decimal(d_sp),
              "D_splice_init" => p1c_rational_to_decimal(d_si),
              "D_plateau_init" => p1c_rational_to_decimal(d_pi))
    for (n, v) in dd
        v === nothing &&
            push!(iss, "$n has no terminating decimal representation " *
                  "(impossible for decimal-token differences; refusing)")
    end
    isempty(iss) || return (iss, out)
    branch = d_sp < 0 ? "NEGATIVE (D_reported < 0)" :
        d_sp > 0 ? "POSITIVE (D_reported > 0)" :
        "ZERO AT MAX_DIGITS10 TOKEN REPRESENTATION (exact decimal " *
        "equality of the reported tokens; distinct from exact " *
        "mathematical equality of the underlying Reals)"
    push!(out, "P1 J0_reported TOKENS (max_digits10 round-trip; " *
          "represented Real values only): Ji(init)=" *
          tok["init-a"].full_cost * " Jp(plateau)=" *
          tok["plateau-a"].full_cost * " Js(splice)=" *
          tok["published-a"].full_cost)
    push!(out, "P1 GRADIENT-NORM TOKENS (descriptive): init=" *
          tok["init-a"].full_gnorm * " plateau=" *
          tok["plateau-a"].full_gnorm * " splice=" *
          tok["published-a"].full_gnorm)
    push!(out, "P1 TOKEN-DERIVED SIGNED DECIMAL DELTAS (EXACT decimal " *
          "arithmetic on the reported tokens; canonical terminating " *
          "decimals; bounded by stream precision, never beyond the " *
          "represented Real values): " *
          "D_splice_plateau=" * dd["D_splice_plateau"] *
          " D_splice_init=" * dd["D_splice_init"] *
          " D_plateau_init=" * dd["D_plateau_init"])
    push!(out, "P1 SIGN BRANCH on D_reported = J0_reported(splice) - " *
          "J0_reported(plateau): " * branch)
    push!(out, "P1 STATUS RECORD (recorded observations; per-target " *
          "a/b equality gated; membership NOT gated per the frozen " *
          "design): " * join(["$w='$(st[w])'" for w in ws], " "))
    push!(out, "P1 CEILING: initial-cost placement under THIS fixed " *
          "configuration/binary/inputs only; NO acceptance, NO optimizer " *
          "reachability, NO mechanism ranking, NO floor or ratio claim, " *
          "NO comparator statement, NO objective/data change, NO " *
          "next-control decision; the completion ledger applies the " *
          "preregistered outcome matrix mechanically.")
    (iss, out)
end

# --- CLI ------------------------------------------------------------------------
function p1c_main(args)
    isempty(args) && (println("P1C REFUSE: no mode given"); return 1)
    mode = args[1]
    iss = String[]
    out = String[]
    if mode == "build-splice" && length(args) == 4
        iss = p1c_build_splice(args[2], args[3], args[4])
    elseif mode == "gate-splice" && length(args) == 4
        iss, counts = p1c_gate_splice(args[2], args[3], args[4])
        isempty(iss) && push!(out,
            "splice eight-gas differing-element counts vs init: " *
            join(sort(collect(counts); by = first),
                 ", ") |> String)
    elseif mode == "gate-plateau" && length(args) == 3
        iss, counts = p1c_gate_plateau(args[2], args[3])
        isempty(iss) && push!(out,
            "plateau four-active differing-element counts vs init: " *
            join(sort(collect(counts); by = first), ", ") |> String)
    elseif mode == "scan-structural" && length(args) == 4
        path, label, initp = args[2], args[3], args[4]
        biss, sd = p1c_bracketed(initp, P1C_INIT_SHA) do
            p1c_signature_and_dims(initp)
        end
        append!(iss, biss)
        if sd !== nothing
            bad, nf = p1c_schema_value_check(path, "structural", sd[1],
                                             sd[2])
            append!(iss, ["$label structural scan: " * b for b in bad])
            for (k, n) in nf
                push!(out, "NONFINITE RECORD ($label): var=$k count=$n " *
                      "-- lawful recorded observation under the " *
                      "preregistered two-tier policy, never a refusal")
            end
            isempty(bad) && push!(out, "one-step serialized output " *
                "($label): STRUCTURAL EVIDENCE ONLY (no scientific value " *
                "read; no census claim)")
        end
    elseif mode == "tokens" && length(args) == 4
        logp, outp = args[2], args[3]
        # args[4] = probe label (echo only)
        text = try
            read(logp, String)
        catch
            push!(iss, "unreadable probe log: $logp")
            ""
        end
        if isempty(iss)
            tiss, tokens = p1c_extract_tokens(text)
            append!(iss, tiss)
            if tokens !== nothing
                write(outp, join(p1c_tokens_to_lines(tokens), "\n") * "\n")
                push!(out, "tokens ($(args[4])): full_cost=" *
                      tokens.full_cost * " full_gnorm=" * tokens.full_gnorm *
                      " rounded=(" * tokens.rounded_cost * ", " *
                      tokens.rounded_gnorm * ")")
            end
        end
    elseif mode == "compare" && length(args) == 2
        runroot = args[2]
        tok = Dict{String, Any}()
        st = Dict{String, String}()
        for w in P1C_WS
            tp = joinpath(runroot, "$w-tokens.txt")
            sp = joinpath(runroot, "$w-status.txt")
            isfile(tp) || (push!(iss, "missing token file: $tp"); continue)
            isfile(sp) || (push!(iss, "missing status file: $sp"); continue)
            t = p1c_tokens_from_lines(read(tp, String))
            t === nothing && (push!(iss, "malformed token file: $tp");
                              continue)
            tok[w] = t
            # stripped read (monitor blocker fix: newline/whitespace-
            # robust status deserialization; the sbatch also writes
            # newline-free via printf '%s')
            st[w] = String(strip(read(sp, String)))
        end
        if isempty(iss)
            iss, out = p1c_compare(tok, st)
        end
    else
        push!(iss, "unknown mode or wrong arity: " * join(args, " "))
    end
    foreach(println, out)
    if isempty(iss)
        println("P1C PASS: $mode")
        return 0
    end
    foreach(i -> println("P1C REFUSE: $i"), iss)
    return 1
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(p1c_main(ARGS))
end
