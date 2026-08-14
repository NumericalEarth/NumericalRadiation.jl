# Gate-4 P2 HARD-OBJECTIVE CHECKER/EVALUATOR (shared in-job + fixture
# functions; CLI). Frozen design authority: gate4_p2_frozen_design.md
# sha256 c6c7638542f371ae1e44c91214d028e8f7ce9a9a61ca2be4fb0b2923f3b9f420.
#
# This ONE file is (a) staged read-only into the P2 RUNROOT and invoked
# by the generated sbatch as a CLI (modes: arm / license / compare),
# and (b) included by the checkpoint generator so every gate function
# is behaviorally fixture-tested against the SAME code the job runs.
#
# EVALUATOR CHAIN RESOLUTION (staging read bracket): this file NEVER
# hardcodes the chain location. The includer sets ENV["P2C_CHAIN_DIR"]
# BEFORE include: the generator points it at the live validation dir
# (generation-time only, pre-freeze semantics); the sbatch points it at
# the STAGED $RUNROOT/pkg/validation so no live file is read after the
# stage-1 freeze. The P1 checker is included the same way via
# ENV["P2C_P1_CHECKER"] (byte-pinned by the caller before use).
#
# ROW-VECTOR SEMANTICS (binding; shape fact verified at design time):
# hard_objective returns ONLY the worst-row summary. The COMPLETE
# ORDERED row vector required by the frozen design is rebuilt here by
# p2c_rows in the EXACT order the pinned hard_objective text builds its
# internal rows (12 per case: lw_up/lw_down/sw_up/sw_down x rmse and
# max_abs interleaved per variable, heating_rate rmse/max_abs,
# toa_forcing, surface_forcing); the mirrored construction is gated by
# (i) byte-containment of the pinned hard_objective text (generator
# gate) and (ii) a PER-ARM cross-gate requiring the mirror's worst-row
# value to be BIT-EQUAL to hard_objective(...).value -- the instrument
# stays authoritative; the mirror only serializes rows.
#
# PRECISION DISCIPLINE (binding): every value is recorded as BOTH a
# max_digits10 (%.17g) round-trip token AND the UInt64 bit pattern
# (16-hex); duplicate gates are EXACT-STRING equality of the full
# serialized record (hence bit-pattern equality of every row and the
# objective); values are NEVER averaged. Control-reproduction gates are
# exact Float64 bit equality with the committed pinned literals.

using Printf
using SHA: sha256

if haskey(ENV, "P2C_P1_CHECKER")
    include(ENV["P2C_P1_CHECKER"])
end
if haskey(ENV, "P2C_CHAIN_DIR")
    # S1-committed comparator config (binding): the chain's candidate
    # mode defaults to "toy", which omits :composite and KeyErrors on
    # the canonical eight-gas evaluation; official_ecckd is the pinned
    # committed mode (S1 ledger discipline).
    ENV["RH_CANDIDATE_GAS_OPTICS"] = "official_ecckd"
    include(joinpath(ENV["P2C_CHAIN_DIR"], "ecckd_published_model_accuracy.jl"))
end

# --- pins (frozen design) -------------------------------------------------------
const P2C_GASES = (:composite, :h2o, :o3, :co2, :ch4, :n2o, :cfc11, :cfc12)
const P2C_H2O = 0.005
const P2C_STATES = ["init", "plateau", "splice", "published"]
const P2C_ARMS = ["init-a", "plateau-a", "splice-a", "published-a",
                  "published-b", "splice-b", "plateau-b", "init-b"]
p2c_state(arm) = String(rsplit(arm, "-"; limit = 2)[1])
# committed same-instrument-same-caseset control values (B0/S1 provenance)
const P2C_CONTROLS = Dict(
    "published" => 0.18218645425029933,
    "init" => 102.67056437657112,
    "plateau" => 22.791293464348826)
# exact ordered stored-field tuple (monitor precision correction:
# FOURTEEN fields; gas_names is a TYPE PARAMETER checked separately)
const P2C_FIELDS = (:pressure_grid, :temperature_grid,
    :h2o_mole_fraction_grid, :gas_reference_mole_fractions,
    :longwave_absorption, :shortwave_absorption,
    :longwave_h2o_absorption, :shortwave_h2o_absorption,
    :shortwave_rayleigh_molar_scattering, :longwave_source_scale,
    :longwave_source_temperature_grid, :longwave_source_table,
    :longwave_weights, :shortwave_weights)
const P2C_SW_FIELDS = (:shortwave_absorption, :shortwave_h2o_absorption,
    :shortwave_rayleigh_molar_scattering, :shortwave_weights)

p2c_sha(path) = open(io -> bytes2hex(sha256(io)), path)
p2c_tok(v) = @sprintf("%.17g", Float64(v))
p2c_bits(v) = string(reinterpret(UInt64, Float64(v)), base = 16, pad = 16)

# --- mirrored ordered row construction (see header; gated vs hard_objective) ----
function p2c_rows(cases)
    rows = NamedTuple[]
    for case in cases
        for variable in (:lw_up, :lw_down, :sw_up, :sw_down)
            metrics = getproperty(case.variables, variable)
            push!(rows, (case = case.case, metric = "$(variable)_rmse",
                value = metrics.rmse,
                threshold = ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2,
                normalized_value = metrics.rmse /
                    ACCEPTANCE_THRESHOLDS.flux_rmse_w_m2))
            push!(rows, (case = case.case, metric = "$(variable)_max_abs",
                value = metrics.max_abs,
                threshold = ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2,
                normalized_value = metrics.max_abs /
                    ACCEPTANCE_THRESHOLDS.flux_max_abs_w_m2))
        end
        heating = case.variables.heating_rate
        push!(rows, (case = case.case, metric = "heating_rate_rmse",
            value = heating.rmse,
            threshold = ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day,
            normalized_value = heating.rmse /
                ACCEPTANCE_THRESHOLDS.heating_rate_rmse_k_day))
        push!(rows, (case = case.case, metric = "heating_rate_max_abs",
            value = heating.max_abs,
            threshold = ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day,
            normalized_value = heating.max_abs /
                ACCEPTANCE_THRESHOLDS.heating_rate_max_abs_k_day))
        push!(rows, (case = case.case, metric = "toa_forcing",
            value = case.toa_forcing_max_abs,
            threshold = ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2,
            normalized_value = case.toa_forcing_max_abs /
                ACCEPTANCE_THRESHOLDS.toa_forcing_abs_error_w_m2))
        push!(rows, (case = case.case, metric = "surface_forcing",
            value = case.surface_forcing_max_abs,
            threshold = ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2,
            normalized_value = case.surface_forcing_max_abs /
                ACCEPTANCE_THRESHOLDS.surface_forcing_abs_error_w_m2))
    end
    rows
end

p2c_row_line(r) = join([String(r.case), String(r.metric),
    p2c_tok(r.value), p2c_bits(r.value), p2c_tok(r.threshold),
    p2c_bits(r.threshold), p2c_tok(r.normalized_value),
    p2c_bits(r.normalized_value)], "|")

const P2C_METRIC_SEQ = ("lw_up_rmse", "lw_up_max_abs", "lw_down_rmse",
    "lw_down_max_abs", "sw_up_rmse", "sw_up_max_abs", "sw_down_rmse",
    "sw_down_max_abs", "heating_rate_rmse", "heating_rate_max_abs",
    "toa_forcing", "surface_forcing")
const P2C_INVOCATION = "read_ecckd_tabulated_gas_optics;gas_names=" *
    join(String.(P2C_GASES), ",") * ";h2o_mole_fraction=0.005;" *
    "candidate_mode=official_ecckd"

# --- per-arm evaluation (fresh load; instrument authoritative;
# --- provenance-carrying record per monitor early-checker HOLD 1/2) ---------------
function p2c_arm_record(lw_path, sw_path, label, lw_sha, sw_sha)
    iss = String[]
    model = read_ecckd_tabulated_gas_optics(lw_path, sw_path;
        gas_names = P2C_GASES, h2o_mole_fraction = P2C_H2O)
    metrics = [case_metrics(c, model) for c in REDUCED_CASES]
    obj = hard_objective(metrics)
    rows = p2c_rows(metrics)
    # mirror authority gates: exactly 2x12=24 rows with the exact
    # ordered case/metric key sequence, and ALL hard_objective summary
    # fields bit/name-equal to the mirrored argmax
    length(rows) == 24 ||
        push!(iss, "mirrored row count $(length(rows)) != 24")
    expected_keys = [(String(c.case), m) for c in REDUCED_CASES
                     for m in P2C_METRIC_SEQ]
    got_keys = [(String(r.case), String(r.metric)) for r in rows]
    got_keys == expected_keys ||
        push!(iss, "mirrored row key sequence != the pinned ordered " *
              "2x12 case/metric sequence")
    if !isempty(rows)
        worst = argmax(r -> r.normalized_value, rows)
        p2c_bits(worst.normalized_value) == p2c_bits(obj.value) ||
            push!(iss, "cross-gate: worst normalized value bits != " *
                  "hard_objective.value bits")
        String(worst.case) == String(obj.case) ||
            push!(iss, "cross-gate: worst case != hard_objective.case")
        String(worst.metric) == String(obj.metric) ||
            push!(iss, "cross-gate: worst metric != hard_objective.metric")
        p2c_bits(worst.value) == p2c_bits(obj.metric_value) ||
            push!(iss, "cross-gate: worst metric value bits != " *
                  "hard_objective.metric_value bits")
        p2c_bits(worst.threshold) == p2c_bits(obj.threshold) ||
            push!(iss, "cross-gate: worst threshold bits != " *
                  "hard_objective.threshold bits")
    end
    lines = vcat(
        ["arm_label=" * label,
         "state=" * p2c_state(label),
         "lw_sha=" * lw_sha,
         "sw_sha=" * sw_sha,
         "invocation=" * P2C_INVOCATION,
         "objective_token=" * p2c_tok(obj.value),
         "objective_bits=" * p2c_bits(obj.value),
         "objective_case=" * String(obj.case),
         "objective_metric=" * String(obj.metric),
         "objective_metric_value_bits=" * p2c_bits(obj.metric_value),
         "objective_threshold_bits=" * p2c_bits(obj.threshold),
         "rows=" * string(length(rows))],
        ["row " * p2c_row_line(r) for r in rows])
    (iss, (obj = obj, rows = rows, record = join(lines, "\n") * "\n",
           model = model))
end

# scientific payload = the record minus its arm_label line (arm labels
# legitimately differ between duplicates; everything else must be
# exact-string equal, incl. state/SW shas and the invocation identity)
p2c_payload(record) = join(
    [l for l in split(record, '\n') if !startswith(l, "arm_label=")],
    "\n")

p2c_arm_label(record) = begin
    m = match(r"(?m)^arm_label=(\S+)$", record)
    m === nothing ? nothing : String(m.captures[1])
end

# --- gates --------------------------------------------------------------------------
function p2c_duplicate_issues(records)
    iss = String[]
    for arm in P2C_ARMS
        haskey(records, arm) || continue
        got = p2c_arm_label(records[arm])
        got == arm ||
            push!(iss, "arm-label/state mapping violation: record for " *
                  "$arm carries arm_label=" * repr(got))
        nst = length(collect(eachmatch(r"(?m)^state=", records[arm])))
        nst == 1 ||
            push!(iss, "record for $arm carries $nst state lines != 1")
        stm = match(r"(?m)^state=(\S+)$", records[arm])
        (stm !== nothing && String(stm.captures[1]) == p2c_state(arm)) ||
            push!(iss, "record state line for $arm != its arm state " *
                  "(belt to the rendered mapping gates)")
    end
    for arm in P2C_ARMS
        haskey(records, arm) || continue
        n = count(l -> startswith(l, "arm_label="),
                  split(records[arm], '\n'))
        n == 1 ||
            push!(iss, "record for $arm carries $n arm_label lines != 1 " *
                  "(schema violation; payload stripping refused)")
    end
    for st in P2C_STATES
        a, b = "$st-a", "$st-b"
        (haskey(records, a) && haskey(records, b)) ||
            (push!(iss, "missing duplicate records for state $st");
             continue)
        p2c_payload(records[a]) == p2c_payload(records[b]) ||
            push!(iss, "state $st duplicate scientific payloads not " *
                  "exact-string equal (objective/rows/state-sha/SW-sha/" *
                  "invocation; bit-pattern drift; recorded drift; " *
                  "ordering assignment refused; values never averaged)")
    end
    iss
end

function p2c_control_issues(records)
    iss = String[]
    for (st, pin) in P2C_CONTROLS
        for arm in ("$st-a", "$st-b")
            rec = get(records, arm, "")
            hits = collect(eachmatch(r"(?m)^objective_bits=([0-9a-f]{16})$",
                                     rec))
            length(hits) == 1 ||
                (push!(iss, "control gate: objective_bits line not " *
                       "exactly once in $arm record"); continue)
            String(hits[1].captures[1]) == p2c_bits(pin) ||
                push!(iss, "control reproduction gate MISS for $arm: " *
                      "pinned " * p2c_tok(pin) * " not reproduced " *
                      "bit-exact (interpretation refused; same-job " *
                      "duplicates decide)")
        end
    end
    iss
end

p2c_eltok(x) = p2c_tok(x) * ":" * p2c_bits(x)

# gas axis is FIXED BY MODEL CONTRACT at axis 2 (monitor ruling); this
# predicate is the single authority used by the license gate and is
# directly fixture-tested with adversarial non-gas-axis extent-8 arrays
p2c_gas_axis_ok(a) = ndims(a) == 4 && size(a, 2) == length(P2C_GASES)

function p2c_field_equal(a, b)
    (size(a) == size(b)) || return (false, -1)
    n = count(x -> x[1] !== x[2], zip(a, b))
    (n == 0, n)
end

# residual-label license + fourteen-field inventory (frozen design;
# monitor precision correction: fieldnames tuple gate + separate
# gas_names type-parameter gate; NO 15-entry getproperty loop)
function p2c_license_and_inventory(models)
    iss = String[]
    inv = String[]
    for (label, m) in models
        fieldnames(typeof(m)) == P2C_FIELDS ||
            push!(iss, "$label: fieldnames(typeof(model)) != the exact " *
                  "ordered fourteen-name tuple")
        Tuple(NumericalRadiation.gas_names(m)) == P2C_GASES ||
            push!(iss, "$label: gas_names(model) != the canonical " *
                  "eight-gas type-parameter ordering")
    end
    isempty(iss) || return (iss, inv, false)
    sp = models["splice"]
    pb = models["published"]
    # license part (a): every ordered gas slice of longwave_absorption
    ga = getfield(sp, :longwave_absorption)
    gb = getfield(pb, :longwave_absorption)
    lic = true
    # gas axis is FIXED BY MODEL CONTRACT at axis 2 (monitor ruling;
    # findfirst-by-extent is ambiguous when another axis has extent 8)
    if size(ga) != size(gb)
        push!(iss, "longwave_absorption shape differs splice vs published")
        lic = false
    elseif !p2c_gas_axis_ok(ga)
        push!(iss, "longwave_absorption violates the model contract " *
              "(ndims $(ndims(ga)) != 4 or size(...,2) " *
              "$(size(ga, 2)) != 8)")
        lic = false
    else
        for (gi, g) in enumerate(P2C_GASES)
            sa = selectdim(ga, 2, gi)
            sb = selectdim(gb, 2, gi)
            eq, n = p2c_field_equal(collect(sa), collect(sb))
            push!(inv, "slice longwave_absorption[$g] " *
                  (eq ? "EQUAL n=0" : "DIFFERS n=$n") *
                  " shape=" * string(size(sa)))
            eq || (lic = false)
        end
    end
    # license part (b): the complete dynamic-H2O table (the operative
    # payload; the :h2o slice above is zeroed on this path --
    # NumericalRadiationNCDatasetsExt.jl:151)
    eqh, nh = p2c_field_equal(getfield(sp, :longwave_h2o_absorption),
                              getfield(pb, :longwave_h2o_absorption))
    push!(inv, "table longwave_h2o_absorption " *
          (eqh ? "EQUAL n=0" : "DIFFERS n=$nh") * " shape=" *
          string(size(getfield(sp, :longwave_h2o_absorption))))
    eqh || (lic = false)
    # fourteen-field inventory BY EXACT NAME, splice vs published
    # (counts + shapes emitted for EVERY field, equal or not)
    for f in P2C_FIELDS
        eq, n = p2c_field_equal(getfield(sp, f), getfield(pb, f))
        push!(inv, "field $f " * (eq ? "EQUAL n=0" : "DIFFERS n=$n") *
              " shape=" * string(size(getfield(sp, f))))
    end
    push!(inv, "gas_names " * join(String.(Tuple(NumericalRadiation.gas_names(sp))), ",") *
          " (type-parameter ordering; gated equal to canonical)")
    # fixed-SW fields: EXACT-EQUALITY GATES across ALL FOUR states,
    # each demonstrated with an explicit inventory row
    for f in P2C_SW_FIELDS
        ref = getfield(models["init"], f)
        for st in P2C_STATES
            eq, n = p2c_field_equal(getfield(models[st], f), ref)
            push!(inv, "fixed-SW $f[$st] " *
                  (eq ? "EQUAL n=0" : "DIFFERS n=$n") * " shape=" *
                  string(size(getfield(models[st], f))))
            eq || push!(iss, "fixed-SW field $f differs in state $st " *
                        "(n=$n); constant-by-construction must be " *
                        "demonstrated, not assumed")
        end
    end
    (iss, inv, lic)
end

# preregistered exhaustive branches (exact decimal on tokens; requires
# the byte-pinned P1 checker to be included by the caller)
function p2c_branches(records)
    iss = String[]
    out = String[]
    tokof(st) = begin
        hits = collect(eachmatch(r"(?m)^objective_token=(\S+)$",
                                 get(records, "$st-a", "")))
        length(hits) == 1 || return nothing
        String(hits[1].captures[1])
    end
    toks = Dict(st => tokof(st) for st in P2C_STATES)
    any(v -> v === nothing, values(toks)) &&
        (push!(iss, "missing objective token(s); branches refused");
         return (iss, out))
    rs = Dict(st => p1c_decimal_to_rational(toks[st])
              for st in P2C_STATES)
    any(v -> v === nothing, values(rs)) &&
        (push!(iss, "unparseable objective token(s); branches refused");
         return (iss, out))
    for (name, a, b) in (("D_splice_plateau", "splice", "plateau"),
                         ("D_splice_published", "splice", "published"))
        d = rs[a] - rs[b]
        dec = p1c_rational_to_decimal(d)
        dec === nothing &&
            (push!(iss, "$name has no terminating decimal (impossible " *
                   "for token differences; refused)"); continue)
        branch = d < 0 ? "NEGATIVE" : d > 0 ? "POSITIVE" :
            "ZERO-AT-TOKEN-REPRESENTATION (exact decimal equality of " *
            "the reported tokens)"
        push!(out, "P2 $name=$dec BRANCH=$branch (exact decimal on " *
              "max_digits10 tokens; token-derived; never averaged)")
    end
    push!(out, "P2 CEILING: private diagnostic placement only under " *
          "this fixed configuration/instrument/SW/inputs; no recovered " *
          "acceptance, no objective-change authorization, no optimizer " *
          "reachability, no mechanism localization or ranking, no " *
          "automatic next-control decision; the <=1.05 gate is untouched.")
    (iss, out)
end

# --- CLI ------------------------------------------------------------------------------
function p2c_main(args)
    isempty(args) && (println("P2C REFUSE: no mode given"); return 1)
    mode = args[1]
    iss = String[]
    out = String[]
    if mode == "arm" && length(args) == 7
        lw, sw, outp, label = args[2], args[3], args[4], args[5]
        lw_sha, sw_sha = args[6], args[7]
        label in P2C_ARMS ||
            push!(iss, "arm label " * repr(label) *
                  " not in the palindromic arm set")
        p2c_sha(lw) == lw_sha ||
            push!(iss, "arm $label: LW state sha != supplied provenance pin")
        p2c_sha(sw) == sw_sha ||
            push!(iss, "arm $label: SW sha != supplied provenance pin")
        if isempty(iss)
            aiss, res = p2c_arm_record(lw, sw, label, lw_sha, sw_sha)
            append!(iss, aiss)
            if isempty(iss)
                write(outp, res.record)
                push!(out, "arm $label: objective=" *
                      p2c_tok(res.obj.value) * " (" *
                      String(res.obj.case) * "/" *
                      String(res.obj.metric) * "; rows=" *
                      string(length(res.rows)) * ")")
            end
        end
    elseif mode == "license" && length(args) == 6
        # args: init_lw plateau_lw splice_lw published_lw sw
        paths = Dict(zip(P2C_STATES, args[2:5]))
        sw = args[6]
        models = Dict(st => read_ecckd_tabulated_gas_optics(paths[st], sw;
            gas_names = P2C_GASES, h2o_mole_fraction = P2C_H2O)
                      for st in P2C_STATES)
        liss, inv, lic = p2c_license_and_inventory(models)
        append!(iss, liss)
        append!(out, ["P2 INVENTORY " * l for l in inv])
        # WITHHELD (not REFUSED) distinguishes the lawful
        # license-assessment outcome from a gate refusal, so no log can
        # carry a contradictory REFUSED-then-PASS pair (monitor item 5)
        push!(out, "P2 RESIDUAL-LABEL LICENSE: " *
              (lic ? "GRANTED (materialized slices + dynamic-H2O table " *
                     "exact-equal)" :
                     "WITHHELD (difference recorded as evidence; " *
                     "residual label not licensed)"))
        isempty(iss) && push!(out,
            "license assessment completed (outcome above is a recorded " *
            "determination, not a gate verdict)")
    elseif mode == "compare" && length(args) == 2
        runroot = args[2]
        records = Dict{String, String}()
        for arm in P2C_ARMS
            p = joinpath(runroot, "$arm-record.txt")
            isfile(p) || (push!(iss, "missing arm record: $p"); continue)
            records[arm] = read(p, String)
        end
        if isempty(iss)
            append!(iss, p2c_duplicate_issues(records))
            append!(iss, p2c_control_issues(records))
        end
        if isempty(iss)
            biss, bout = p2c_branches(records)
            append!(iss, biss)
            append!(out, bout)
        end
    else
        push!(iss, "unknown mode or wrong arity: " * join(args, " "))
    end
    foreach(println, out)
    if isempty(iss)
        println("P2C PASS: $mode")
        return 0
    end
    foreach(i -> println("P2C REFUSE: $i"), iss)
    return 1
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(p2c_main(ARGS))
end
