# Gate-4 MATCHED-STATE OD EVALUATOR (aggregation-independent library +
# self-tests). Design note rev 2 step 2, authored under the monitor-approved
# scope of 2026-08-12.
#
# Contract: (definition path, scenario file with a stacked gas axis) ->
# total absorption optical depth EX-RAYLEIGH per (g-point, layer, column) on
# the scenario's matched states, with per-gas fields as RAW UNCLAMPED
# diagnostics. Negative values are findings (counted, minima recorded),
# never clamped; the run_ckd output convention max(total, 0) is provided as
# a SEPARATE labeled field (run_ckd.cpp:316) and the raw total is always
# preserved. No positive_eps / metric epsilon here -- that belongs to the
# future metric layer with excluded-pair accounting. This unit makes NO
# Gate-2 dataset choice, NO aggregation choice, and NO thresholds-4/5
# semantics choice.
#
# GAS-SCOPE SEMANTICS (monitor-mandated, pinned from upstream source):
# upstream active-gas selection is EXPLICIT, not derived from the scenario
# gas axis: run_ckd reads a `gases` list (run_ckd.cpp:66-73) and iterates
# DEFINITION molecules, skipping any not in that list (run_ckd.cpp:264-273);
# optimizer passes use explicit GASLIST (optimize_lut_lw.sh:43-260,
# optimize_lut_sw.sh:73-244). If an included molecule lacks a concentration,
# run_ckd.cpp:277-279 falls to concentration-free OD, and ckd_model.cpp
# throws for concentration-dependent gases (LUT :988-990, LINEAR/
# RELATIVE_LINEAR :1022-1024); only conc_dependence NONE (the composite)
# computes concentration-free (ckd_model.cpp:1042-1058). THEREFORE:
#   - the caller MUST pass `active_absorption_gases` explicitly; this
#     evaluator NEVER intersects definition and scenario gas sets;
#   - every active gas with conc_dependence_code != 0 MUST be present in
#     the scenario constituent_id map (refusal otherwise -- mirroring the
#     upstream THROW, never an implicit inclusion or a silent skip);
#   - the composite (code 0) is permitted WITHOUT a scenario axis entry
#     (it has none in any CKDMIP flux file);
#   - inactive scenario axis IDs (n2, o2, rayleigh) are never absorption
#     gases here: they are refused if requested as active, and ignored
#     (recorded) when present on the axis. Rayleigh exclusion is by GAS ID,
#     never by axis index. Ex-Rayleigh totals hold by construction.
#   - definition gas set and scenario axis IDs are recorded SEPARATELY and
#     never compared to each other.
# The gas axis is mapped per file via the GLOBAL constituent_id attribute
# (mandatory: the Gate-2 manifest census proved the axis ORDER differs
# between rel and non-rel scenarios, so fixed-order assumptions misassign
# co2/ch4/n2o on 24 of 36 files).
#
# conc_dependence_code semantics (ckd_model.cpp:178-199, 963-1058), weights
# per layer with simple_weight = dp / (g * 0.001 * M_air):
#   0 NONE            simple_weight                  (concentration-free)
#   1 LINEAR          simple_weight * vmr
#   2 LUT             simple_weight * vmr, extra even-log-conc axis
#   3 RELATIVE_LINEAR simple_weight * (vmr - ref), ref = STORED Float32
#     value from the definition (G1 lesson); negative per-gas OD is
#     legitimate at source.
# Codes are READ FROM THE DEFINITION FILE, never assumed from optimizer
# staging (proof of necessity: published LW32 stores cfc11/cfc12 as
# LINEAR code 1, not relative-linear).
#
# Values are promoted to Float64 on load. States use the G1-verified
# construction: T_fl pressure-weighted (run_ckd.cpp:119-121), logp_fl =
# log(mean adjacent p_hl) (ckd_model.cpp:937), index clamps [0, n-1.0001].
#
# The OD chain below is copied from gate4_sw_od_parity.jl (itself from
# gate4_forward_map_g1.jl -- a runner template that must never be
# include()d), with an `mso_` prefix; this file IS include-safe (guarded
# main) so the future Gate-2 runner can reuse it.

include(joinpath(@__DIR__, "validation_results.jl"))
include(joinpath(@__DIR__, "gate4_forward_map.jl"))   # library: include-safe

using Dates
import JSON
using NCDatasets

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))
using NumericalRadiation

const MSO_RESULTS_JSON =
    validation_results_path("gate4_g2_matched_state_od_evaluator.json")
const MSO_RESULTS_MD =
    validation_results_path("gate4_g2_matched_state_od_evaluator.md")

# Same Float32-storage parity tolerances as the G1 LW / SW OD gates.
const MSO_OD_REL_TOL = 1e-6
const MSO_OD_ABS_TOL = 1e-9

# Scenario axis IDs that are never absorption gases for this evaluator:
# n2/o2 are folded into the composite background; rayleigh is scattering.
const MSO_INACTIVE_IDS = ("n2", "o2", "rayleigh")

# Full definition gas-set contract (monitor hardening 2): the band is
# classified from unambiguous support variables (planck_function -> LW,
# solar_irradiance -> SW; exactly one must be present) and the definition
# must carry EXACTLY the published absorption-gas set for that band. This
# is a definition-side gate, independent of (and never compared to)
# scenario axis IDs.
const MSO_EXPECTED_DEFINITION_GASES = Dict(
    "lw" => ["cfc11", "cfc12", "ch4", "co2", "composite", "h2o", "n2o", "o3"],
    "sw" => ["ch4", "co2", "composite", "h2o", "n2o", "o3"])

# Exact published conc-code map (canonical: the target schema is already
# hardcoded above; codes verified on both published definitions --
# LW cfc11/cfc12 are LINEAR code 1, not relative-linear)
const MSO_EXPECTED_CONC_CODES = Dict(
    "lw" => Dict("composite" => 0, "h2o" => 2, "o3" => 1, "co2" => 1,
                 "ch4" => 3, "n2o" => 3, "cfc11" => 1, "cfc12" => 1),
    "sw" => Dict("composite" => 0, "h2o" => 2, "o3" => 1, "co2" => 1,
                 "ch4" => 3, "n2o" => 3))

# The interpolation stencils assume EVEN spacing (upstream uses the first
# increment as the grid constant: ckd_model.cpp:925,937 and the code-2
# log-conc axis). Near-uniformity is enforced with a Float32-aware
# relative tolerance; monitor-measured published maxima: log-p 5.55e-7,
# T 7.63e-7, log-c 7.23e-8 -- 1e-5 is conservative. Malformed recovered
# axes must refuse, never silently produce wrong OD.
const MSO_EVEN_RTOL = 1e-5

function mso_require_even(vals, label)
    diffs = diff(collect(Float64, vals))
    dref = diffs[1]
    abs(dref) > 0.0 || refuse("$label has zero spacing")
    dev = maximum(abs.(diffs .- dref)) / abs(dref)
    dev <= MSO_EVEN_RTOL ||
        refuse("$label not evenly spaced: max relative deviation $dev > " *
               "$(MSO_EVEN_RTOL)")
end

struct MsoRefusal <: Exception
    reason::String
end
Base.showerror(io::IO, e::MsoRefusal) = print(io, "MsoRefusal: ", e.reason)
refuse(reason) = throw(MsoRefusal(reason))

mso_dimnames(v) = collect(String.(NCDatasets.dimnames(v)))

# --- definition loading -----------------------------------------------------
function mso_read_definition(path)
    d = Dict{String, Any}()
    isfile(path) || refuse("definition file missing: $path")
    NCDataset(path) do ds
        # band classification from unambiguous support variables, then the
        # ENFORCED full definition gas-set gate (monitor hardening 2)
        has_planck = haskey(ds, "planck_function")
        has_solar = haskey(ds, "solar_irradiance")
        (has_planck && !has_solar) || (has_solar && !has_planck) ||
            refuse("definition band classification ambiguous: " *
                   "planck_function=$has_planck solar_irradiance=$has_solar")
        band = has_planck ? "lw" : "sw"
        d["band"] = band
        gases = sort([replace(String(k), "_molar_absorption_coeff" => "")
                      for k in keys(ds)
                      if endswith(String(k), "_molar_absorption_coeff")])
        gases == MSO_EXPECTED_DEFINITION_GASES[band] ||
            refuse("definition gas set $gases != expected $band set " *
                   "$(MSO_EXPECTED_DEFINITION_GASES[band])")
        d["gas_set"] = gases

        p_nodes = Float64.(Array(ds["pressure"]))
        (all(isfinite, p_nodes) && all(>(0.0), p_nodes) &&
         issorted(p_nodes, lt = <=)) ||
            refuse("definition pressure LUT axis must be finite, positive, " *
                   "strictly increasing")
        length(p_nodes) >= 2 || refuse("pressure LUT axis too short")
        mso_require_even(log.(p_nodes), "log-pressure LUT axis")
        d["pressure"] = p_nodes
        tv = ds["temperature"]
        Tm = Float64.(Array(tv))
        d["temperature_dims"] = mso_dimnames(tv)
        d["temperature_dims"] == ["pressure", "temperature"] ||
            refuse("definition temperature dims $(d["temperature_dims"]) " *
                   "!= [pressure, temperature]")
        size(Tm, 1) == length(p_nodes) ||
            refuse("temperature LUT first dim $(size(Tm, 1)) != pressure " *
                   "node count $(length(p_nodes))")
        size(Tm, 2) >= 2 || refuse("temperature LUT axis too short")
        all(isfinite, Tm) || refuse("temperature LUT has non-finite entries")
        let d_t = Tm[1, 2] - Tm[1, 1]
            # published temperature axis is increasing; a descending uniform
            # axis must refuse under this hardcoded target schema
            d_t > 0.0 || refuse("temperature LUT spacing must be positive " *
                                "(increasing axis), got d_t=$d_t")
            maximum(abs.(diff(Tm, dims = 2) .- d_t)) / abs(d_t) <=
                MSO_EVEN_RTOL ||
                refuse("temperature LUT increments not near-uniform " *
                       "(stencil assumes even d_t from the first increment)")
        end
        d["temperature"] = Tm

        np = length(p_nodes)
        nt = size(Tm, 2)
        ng = -1
        expected_codes = MSO_EXPECTED_CONC_CODES[band]
        for gas in gases
            v = ds["$(gas)_molar_absorption_coeff"]
            dims = mso_dimnames(v)
            (length(dims) in (3, 4) && dims[1] == "g_point" &&
             dims[2] == "pressure" && dims[3] == "temperature") ||
                refuse("definition coefficient dims for $gas: $dims")
            A = Float64.(Array(v))
            all(x -> isfinite(x) && x >= 0.0, A) ||
                refuse("non-finite or negative coefficients for $gas " *
                       "(negative per-gas OD arises only from " *
                       "relative-linear weights, never from tables)")
            (size(A, 2) == np && size(A, 3) == nt) ||
                refuse("coefficient p/t shape for $gas $(size(A)) " *
                       "inconsistent with LUT nodes ($np, $nt)")
            # common g-point count across ALL gases (monitor hardening 4):
            # cross-gas drift must refuse here, never BoundsError later
            if ng < 0
                ng = size(A, 1)
            elseif size(A, 1) != ng
                refuse("g-point count drift for $gas: $(size(A, 1)) != $ng")
            end
            d[gas] = A
            d["$(gas)_dims"] = dims
            ckey = "$(gas)_conc_dependence_code"
            haskey(ds, ckey) || refuse("definition missing $ckey")
            code = Int(only(Array(ds[ckey])))
            # exact published conc-code map (canonical for this hardcoded
            # target schema)
            code == expected_codes[gas] ||
                refuse("conc_dependence_code $code for $gas != published " *
                       "$band map value $(expected_codes[gas])")
            d[ckey] = code
            if code == 3
                rkey = "$(gas)_reference_mole_fraction"
                haskey(ds, rkey) ||
                    refuse("$gas is RELATIVE_LINEAR but definition has no $rkey")
                # stored Float32; run_ckd promotes the STORED value (G1 lesson)
                ref_vmr = Float64(only(Array(ds[rkey])))
                (isfinite(ref_vmr) && ref_vmr >= 0.0) ||
                    refuse("non-finite or negative reference mole fraction " *
                           "for $gas")
                d["$(gas)_reference_vmr"] = ref_vmr
            elseif code == 2
                akey = "$(gas)_mole_fraction"
                haskey(ds, akey) ||
                    refuse("$gas is LUT but definition has no $akey axis")
                va = Float64.(Array(ds[akey]))
                (all(isfinite, va) && all(>(0.0), va) &&
                 issorted(va, lt = <=) && length(va) >= 2) ||
                    refuse("LUT concentration axis for $gas must be finite, " *
                           "positive, strictly increasing")
                mso_require_even(log.(va), "log-concentration axis for $gas")
                (length(dims) == 4 && dims[4] == akey) ||
                    refuse("LUT coefficient for $gas must have fourth dim " *
                           "$akey, got $dims")
                size(A, 4) == length(va) ||
                    refuse("LUT coefficient fourth-axis length " *
                           "$(size(A, 4)) != $akey length $(length(va))")
                d["$(gas)_vmr_axis"] = va
            else
                # non-LUT coefficients are exactly 3-D
                length(dims) == 3 ||
                    refuse("non-LUT coefficient for $gas must be exactly " *
                           "3-D, got $dims")
            end
        end
        d["ng"] = ng
    end
    return d
end

# --- scenario loading (stacked gas axis + global constituent_id) -----------
function mso_read_scenario(path)
    s = Dict{String, Any}()
    isfile(path) || refuse("scenario file missing: $path")
    NCDataset(path) do ds
        att = get(ds.attrib, "scenario", nothing)
        att isa AbstractString || refuse("scenario attr missing in $path")
        s["scenario"] = String(att)
        cid = get(ds.attrib, "constituent_id", nothing)
        (cid isa AbstractString && !isempty(strip(cid))) ||
            refuse("global constituent_id attr missing/empty in $path")
        gas_ids = String.(split(strip(cid)))
        length(unique(gas_ids)) == length(gas_ids) ||
            refuse("duplicate IDs in constituent_id: $gas_ids")
        s["gas_ids"] = gas_ids

        for v in ("pressure_hl", "temperature_hl", "mole_fraction_fl")
            haskey(ds, v) || refuse("scenario missing $v")
        end
        mso_dimnames(ds["pressure_hl"]) == ["half_level", "column"] ||
            refuse("pressure_hl dims $(mso_dimnames(ds["pressure_hl"]))" *
                   " != [half_level, column]")
        mso_dimnames(ds["temperature_hl"]) == ["half_level", "column"] ||
            refuse("temperature_hl dims != [half_level, column]")
        mso_dimnames(ds["mole_fraction_fl"]) == ["level", "gas", "column"] ||
            refuse("mole_fraction_fl dims " *
                   "$(mso_dimnames(ds["mole_fraction_fl"]))" *
                   " != [level, gas, column]")

        p = Float64.(Array(ds["pressure_hl"]))
        t = Float64.(Array(ds["temperature_hl"]))
        mf = Float64.(Array(ds["mole_fraction_fl"]))
        nhl, ncol = size(p)
        size(t) == (nhl, ncol) ||
            refuse("temperature_hl $(size(t)) != pressure_hl $(size(p))")
        (size(mf, 1) == nhl - 1 && size(mf, 3) == ncol) ||
            refuse("mole_fraction_fl $(size(mf)) inconsistent with " *
                   "pressure_hl $(size(p))")
        size(mf, 2) == length(gas_ids) ||
            refuse("mole_fraction_fl gas dim $(size(mf, 2)) != " *
                   "constituent_id count $(length(gas_ids))")
        all(isfinite, p) || refuse("pressure_hl has non-finite entries")
        all(>(0.0), p) || refuse("pressure_hl has non-positive entries")
        for c in 1:ncol, l in 1:(nhl - 1)
            p[l + 1, c] > p[l, c] ||
                refuse("pressure_hl not strictly increasing downward at " *
                       "half_level $l column $c")
        end
        all(x -> isfinite(x) && x > 0.0, t) ||
            refuse("temperature_hl has non-finite/non-positive entries")
        all(isfinite, mf) || refuse("mole_fraction_fl has non-finite entries")

        # REQUIRED per the hardened manifest schema contract (monitor
        # hardening 1): exact [gas] dims, exact length, finite nonnegative
        haskey(ds, "reference_surface_mole_fraction") ||
            refuse("scenario missing reference_surface_mole_fraction")
        rs = ds["reference_surface_mole_fraction"]
        mso_dimnames(rs) == ["gas"] ||
            refuse("reference_surface_mole_fraction dims != [gas]")
        length(rs) == length(gas_ids) ||
            refuse("reference_surface_mole_fraction length != gas count")
        rsv = Float64.(Array(rs))
        all(x -> isfinite(x) && x >= 0.0, rsv) ||
            refuse("reference_surface_mole_fraction has non-finite or " *
                   "negative stored values")
        s["reference_surface_mole_fraction"] = rsv
        s["pressure_hl"] = p
        s["temperature_hl"] = t
        s["mole_fraction_fl"] = mf
    end
    return s
end

# --- upstream OD chain (copied from gate4_sw_od_parity.jl, mso_ prefix) ----
struct MsoColumnGrid
    p_hl::Vector{Float64}
    t_fl::Vector{Float64}
    logp_fl::Vector{Float64}
    simple_weight::Vector{Float64}
end

function mso_column_grid(p_hl::AbstractVector, t_hl::AbstractVector)
    nlay = length(p_hl) - 1
    t_fl = Vector{Float64}(undef, nlay)
    logp_fl = similar(t_fl)
    sw = similar(t_fl)
    for l in 1:nlay
        pt1 = t_hl[l] * p_hl[l]
        pt2 = t_hl[l + 1] * p_hl[l + 1]
        t_fl[l] = (pt1 + pt2) / (p_hl[l] + p_hl[l + 1])  # run_ckd.cpp:119-121
        logp_fl[l] = log(0.5 * (p_hl[l + 1] + p_hl[l]))  # ckd_model.cpp:937
        sw[l] = g4_simple_weight(p_hl[l + 1] - p_hl[l])
    end
    return MsoColumnGrid(collect(p_hl), t_fl, logp_fl, sw)
end

function mso_pt_stencil(defn, logp_fl::Real, t_fl::Real)
    p_nodes = defn["pressure"]
    logp0 = log(p_nodes[1])
    dlogp = log(p_nodes[2]) - log(p_nodes[1])
    np = length(p_nodes)
    pidx = clamp((logp_fl - logp0) / dlogp, 0.0, np - 1.0001)
    ip0 = floor(Int, pidx); pw1 = pidx - ip0
    Tm = defn["temperature"]
    t_row0 = Tm[:, 1]
    d_t = Tm[1, 2] - Tm[1, 1]                 # even spacing (ckd_model.cpp:925)
    nt = size(Tm, 2)
    t0 = (1 - pw1) * t_row0[ip0 + 1] +
         pw1 * t_row0[ip0 + 2 <= np ? ip0 + 2 : ip0 + 1]
    tidx = clamp((t_fl - t0) / d_t, 0.0, nt - 1.0001)
    it0 = floor(Int, tidx); tw1 = tidx - it0
    return ip0, pw1, it0, tw1
end

function mso_coeff(defn, gas, g::Int, ip0::Int, pw1, it0::Int, tw1;
                   ic0::Int = -1, cw1 = 0.0)
    A = defn[gas]
    dims = defn["$(gas)_dims"]
    function at(itp, ipp, icc)
        if length(dims) == 3
            return A[g, ipp, itp]
        else
            return A[g, ipp, itp, icc]
        end
    end
    val(icc) = (1 - pw1) * ((1 - tw1) * at(it0 + 1, ip0 + 1, icc) +
                            tw1 * at(it0 + 2, ip0 + 1, icc)) +
               pw1 * ((1 - tw1) * at(it0 + 1, ip0 + 2, icc) +
                      tw1 * at(it0 + 2, ip0 + 2, icc))
    if ic0 < 0
        return val(1)
    else
        return (1 - cw1) * val(ic0 + 1) + cw1 * val(ic0 + 2)
    end
end

function mso_gas_od!(od, defn, gas, grid::MsoColumnGrid, vmr_fl)
    ng = size(od, 1)
    nlay = length(grid.t_fl)
    code = defn["$(gas)_conc_dependence_code"]
    for l in 1:nlay
        ip0, pw1, it0, tw1 = mso_pt_stencil(defn, grid.logp_fl[l], grid.t_fl[l])
        weight = if code == 0
            grid.simple_weight[l]
        elseif code == 1 || code == 2
            grid.simple_weight[l] * vmr_fl[l]
        else
            grid.simple_weight[l] * (vmr_fl[l] - defn["$(gas)_reference_vmr"])
        end
        ic0 = -1; cw1 = 0.0
        if code == 2
            va = defn["$(gas)_vmr_axis"]
            dlc = log(va[2] / va[1])
            cidx = clamp((log(vmr_fl[l]) - log(va[1])) / dlc,
                         0.0, length(va) - 1.0001)
            ic0 = floor(Int, cidx); cw1 = cidx - ic0
        end
        for g in 1:ng
            od[g, l] = mso_coeff(defn, gas, g, ip0, pw1, it0, tw1;
                                 ic0 = ic0, cw1 = cw1) * weight
        end
    end
    return od
end

# --- the evaluator ----------------------------------------------------------
function matched_state_od(definition_path, scenario_path;
                          active_absorption_gases)
    active = collect(String.(active_absorption_gases))
    isempty(active) && refuse("active_absorption_gases must be explicit and " *
                              "non-empty (no implicit gas selection)")
    length(unique(active)) == length(active) ||
        refuse("duplicate gases in active_absorption_gases: $active")
    for gas in active
        gas in MSO_INACTIVE_IDS &&
            refuse("$gas is not an absorption gas for this evaluator " *
                   "(inactive scenario-axis ID); it cannot be active")
    end

    defn = mso_read_definition(definition_path)
    scen = mso_read_scenario(scenario_path)

    for gas in active
        gas in defn["gas_set"] ||
            refuse("active gas $gas is not in the definition gas set " *
                   "$(defn["gas_set"])")
    end

    gas_ids = scen["gas_ids"]
    # unknown-axis refusal (monitor hardening 3): every scenario axis ID
    # must be a definition gas or an allowed inactive ID -- membership
    # validation only, never a selection rule
    for g in gas_ids
        (g in defn["gas_set"] || g in MSO_INACTIVE_IDS) ||
            refuse("unknown scenario gas ID $g: not a definition gas and " *
                   "not an allowed inactive ID $(MSO_INACTIVE_IDS)")
    end
    axis_index = Dict(g => i for (i, g) in enumerate(gas_ids))
    mapping = Dict{String, Any}()
    for gas in active
        code = defn["$(gas)_conc_dependence_code"]
        if code == 0
            # composite: concentration-free (ckd_model.cpp:1042-1058);
            # permitted without a scenario axis entry
            mapping[gas] = "concentration_free"
        else
            haskey(axis_index, gas) ||
                refuse("active gas $gas (conc_dependence_code $code) is " *
                       "missing from the scenario constituent_id map " *
                       "$(gas_ids); upstream throws here (ckd_model.cpp:" *
                       "988-990,1022-1024) -- refusing, never skipping or " *
                       "including implicitly")
            mapping[gas] = axis_index[gas]
        end
    end

    mf = scen["mole_fraction_fl"]              # (level, gas, column), Float64
    for gas in active
        mapping[gas] == "concentration_free" && continue
        slice = view(mf, :, mapping[gas], :)
        all(>=(0.0), slice) ||
            refuse("active gas $gas has negative mole fractions in scenario")
    end

    p = scen["pressure_hl"]
    t = scen["temperature_hl"]
    ncol = size(p, 2)
    nlay = size(p, 1) - 1
    ng = defn["ng"]        # common g-count enforced in mso_read_definition

    per_gas = Dict{String, Array{Float64, 3}}()
    for gas in active
        per_gas[gas] = zeros(ng, nlay, ncol)
    end
    for c in 1:ncol
        grid = mso_column_grid(view(p, :, c), view(t, :, c))
        for gas in active
            vmr = mapping[gas] == "concentration_free" ?
                  zeros(nlay) : Vector(view(mf, :, mapping[gas], c))
            mso_gas_od!(view(per_gas[gas], :, :, c), defn, gas, grid, vmr)
        end
    end

    total_raw = sum(per_gas[g] for g in active)
    negativity = Dict{String, Any}(
        gas => Dict("negative_count" => count(<(0.0), per_gas[gas]),
                    "min" => minimum(per_gas[gas]))
        for gas in active)
    negativity["total_raw"] = Dict(
        "negative_count" => count(<(0.0), total_raw),
        "min" => minimum(total_raw))

    return (
        per_gas_od = per_gas,                       # RAW, unclamped
        total_raw = total_raw,                      # RAW, unclamped
        # separate labeled field mirroring run_ckd.cpp:316 output convention;
        # never replaces the raw total
        total_clamped_run_ckd_convention = max.(total_raw, 0.0),
        negativity = negativity,
        gas_mapping = mapping,
        definition_gas_set = defn["gas_set"],       # recorded separately;
        scenario_gas_ids = gas_ids,                 # NEVER compared directly
        scenario = scen["scenario"],
        n_gpoints = ng, n_layers = nlay, n_columns = ncol,
    )
end

# --- parity statistics (copied from gate4_sw_od_parity.jl) ------------------
function mso_parity_stats(ours::AbstractArray, ref::AbstractArray)
    # identical axes required (monitor hardening 5): equal-length or even
    # equal-size views with different index ranges must refuse, not
    # compare linearly
    axes(ours) == axes(ref) ||
        refuse("parity stats require identical shapes: " *
               "axes $(axes(ours)) vs $(axes(ref))")
    max_abs = 0.0; max_rel = 0.0
    pos = 0; neg = 0
    for i in eachindex(ref)
        d = ours[i] - ref[i]
        ad = abs(d)
        rel = ad / max(abs(ref[i]), abs(ours[i]), 1e-300)
        ad > max_abs && (max_abs = ad)
        if rel > max_rel && ad > MSO_OD_ABS_TOL
            max_rel = rel
        end
        d > 0 && (pos += 1)
        d < 0 && (neg += 1)
    end
    signed = pos + neg == 0 ? 0.0 : (pos - neg) / (pos + neg)
    return Dict{String, Any}(
        "n" => length(ref), "max_abs" => max_abs,
        "max_rel_above_abs_floor" => max_rel,
        "signed_bias_fraction" => signed)
end

mso_parity_ok(st) = (st["max_abs"] <= MSO_OD_ABS_TOL ||
                     st["max_rel_above_abs_floor"] <= MSO_OD_REL_TOL) &&
                    (abs(st["signed_bias_fraction"]) < 0.9 ||
                     st["max_abs"] <= MSO_OD_ABS_TOL)

# ============================================================================
# SELF-TESTS (guarded main; the library above is include-safe)
# ============================================================================

const MSO_SCRATCH = get(ENV, "MSO_SCRATCH_DIR",
                        joinpath(tempdir(), "mso_evaluator_fixtures"))

# build a stacked-axis scenario file from per-gas conc arrays
function mso_write_stacked(path, p_hl, t_hl, gas_ids, vmr_by_gas;
                           scenario = "synthetic-eval1-present",
                           mf_dim_order = ("level", "gas", "column"),
                           constituent_id = join(gas_ids, " "),
                           write_rsmf = true, rsmf = nothing)
    nhl, ncol = size(p_hl)
    nlay = nhl - 1
    ngas = length(gas_ids)
    mf = zeros(nlay, ngas, ncol)
    for (i, g) in enumerate(gas_ids)
        mf[:, i, :] = vmr_by_gas[g]
    end
    rm(path, force = true)
    NCDataset(path, "c") do ds
        defDim(ds, "half_level", nhl)
        defDim(ds, "level", nlay)
        defDim(ds, "gas", ngas)
        defDim(ds, "column", ncol)
        ds.attrib["scenario"] = scenario
        ds.attrib["constituent_id"] = constituent_id
        vp = defVar(ds, "pressure_hl", Float64, ("half_level", "column"))
        vp[:, :] = p_hl
        vt = defVar(ds, "temperature_hl", Float64, ("half_level", "column"))
        vt[:, :] = t_hl
        vm = defVar(ds, "mole_fraction_fl", Float64, mf_dim_order)
        if mf_dim_order == ("level", "gas", "column")
            vm[:, :, :] = mf
        else
            vm[:, :, :] = permutedims(mf, (2, 1, 3))   # (gas, level, column)
        end
        if write_rsmf
            vr = defVar(ds, "reference_surface_mole_fraction", Float64,
                        ("gas",))
            vr[:] = rsmf === nothing ?
                    [vmr_by_gas[g][end, 1] for g in gas_ids] : rsmf
        end
    end
    return path
end

# tiny synthetic CKD definition (refusal fixtures only; a few hundred
# bytes -- no published definition is ever copied). Emits the CORRECT
# published conc-code map by default (composite 0, h2o 2 with LUT axis,
# ch4/n2o 3 with reference scalar, others 1); fixtures perturb via kwargs.
function mso_write_tiny_definition(path; gases, planck = true,
                                   bad_gpoint_gases = String[],
                                   pressure_nodes = [100.0, 1000.0, 10000.0],
                                   coeff_value = 1.0,
                                   code_override = Dict{String, Int}())
    rm(path, force = true)
    NCDataset(path, "c") do ds
        defDim(ds, "g_point", 2)
        defDim(ds, "g_point_drift", 3)
        defDim(ds, "pressure", 3)
        defDim(ds, "temperature", 2)
        defDim(ds, "h2o_mole_fraction", 2)
        vp = defVar(ds, "pressure", Float64, ("pressure",))
        vp[:] = pressure_nodes
        vt = defVar(ds, "temperature", Float64, ("pressure", "temperature"))
        vt[:, :] = [200.0 250.0; 210.0 260.0; 220.0 270.0]
        if planck
            vpl = defVar(ds, "planck_function", Float64, ("temperature",))
            vpl[:] = [1.0, 2.0]
        else
            vs = defVar(ds, "solar_irradiance", Float64, ("g_point",))
            vs[:] = [1.0, 2.0]
        end
        default_code(gas) = gas == "composite" ? 0 :
                            gas == "h2o" ? 2 :
                            gas in ("ch4", "n2o") ? 3 : 1
        for gas in gases
            code = get(code_override, gas, default_code(gas))
            drift = gas in bad_gpoint_gases
            gdim = drift ? "g_point_drift" : "g_point"
            ngg = drift ? 3 : 2
            if code == 2
                vc = defVar(ds, "$(gas)_molar_absorption_coeff", Float64,
                            (gdim, "pressure", "temperature",
                             "h2o_mole_fraction"))
                vc[:, :, :, :] = fill(coeff_value, ngg, 3, 2, 2)
                va = defVar(ds, "$(gas)_mole_fraction", Float64,
                            ("h2o_mole_fraction",))
                va[:] = [1.0e-4, 1.0e-3]
            else
                vc = defVar(ds, "$(gas)_molar_absorption_coeff", Float64,
                            (gdim, "pressure", "temperature"))
                vc[:, :, :] = fill(coeff_value, ngg, 3, 2)
            end
            if code == 3
                vr = defVar(ds, "$(gas)_reference_mole_fraction",
                            Float64, ())
                vr[] = 1.0e-6
            end
            vcode = defVar(ds, "$(gas)_conc_dependence_code", Int32, ())
            vcode[] = code
        end
    end
    return path
end

function mso_load_smoke(path)
    ref = Dict{String, Any}()
    pergas = Dict{String, Array{Float64, 3}}()
    NCDataset(path) do ds
        odvars = [n for n in String.(keys(ds)) if endswith(n, "_optical_depth")]
        for n in odvars
            gas = replace(n, "_optical_depth" => "")
            gas == "rayleigh" && continue
            pergas[gas] = Float64.(Array(ds[n]))
        end
        ref["pressure_hl"] = Float64.(Array(ds["pressure_hl"]))
    end
    ref["per_gas_od"] = pergas
    return ref
end

function mso_load_conc(path, gases)
    conc = Dict{String, Any}()
    NCDataset(path) do ds
        conc["pressure_hl"] = Float64.(Array(ds["pressure_hl"]))
        conc["temperature_hl"] = Float64.(Array(ds["temperature_hl"]))
        for gas in gases
            conc[gas] = Float64.(Array(ds["$(gas)_mole_fraction_fl"]))
        end
    end
    return conc
end

function mso_expect_refusal!(gates, fails, name, substring, thunk)
    outcome = try
        thunk()
        "no_refusal"
    catch err
        err isa MsoRefusal ?
            (occursin(substring, err.reason) ? "refused_as_expected" :
             "refused_wrong_reason: $(err.reason)") :
            "wrong_exception: $(sprint(showerror, err))"
    end
    gates[name] = outcome == "refused_as_expected" ? "passed" : "failed"
    outcome == "refused_as_expected" ||
        push!(fails, "$name: $outcome (wanted refusal containing " *
                     "'$substring')")
end

function main()
    fails = String[]
    gates = Dict{String, String}()
    stats = Dict{String, Any}()
    mkpath(MSO_SCRATCH)

    lw32 = NumericalRadiation.official_ecckd_definition_path(:longwave_32)
    sw32 = NumericalRadiation.official_ecckd_definition_path(:shortwave_32)
    lw_smoke_nc = "/shared/home/greg/ecckd-derived-flux-work/g1-references/" *
                  "lw32_run_ckd_smoke.nc"
    sw_smoke_nc = "/shared/home/greg/ecckd-derived-flux-work/g1-references/" *
                  "sw32_run_ckd_smoke.nc"
    conc_nc = "/shared/home/greg/data/ckdmip/evaluation1/conc/" *
              "ckdmip_evaluation1_concentrations_present.nc"

    conc = mso_load_conc(conc_nc, ("h2o", "o3", "co2", "ch4", "n2o",
                                   "cfc11", "cfc12", "n2", "o2"))
    nlay, ncol = size(conc["h2o"])

    # --- synthetic stacked scenarios (scrambled axis order + inactive IDs,
    # deliberately exercising the constituent_id mapping; composite absent
    # from the axis as in every real CKDMIP file) ---------------------------
    lw_active = ["composite", "h2o", "o3", "co2", "ch4", "n2o",
                 "cfc11", "cfc12"]
    sw_active = ["composite", "h2o", "o3", "co2", "ch4", "n2o"]
    lw_axis = ["n2", "o2", "cfc12", "ch4", "h2o", "co2", "o3", "n2o", "cfc11"]
    sw_axis = ["rayleigh", "o3", "h2o", "n2", "o2", "co2", "n2o", "ch4"]
    vmrs = Dict{String, Any}(g => conc[g] for g in
                             ("h2o", "o3", "co2", "ch4", "n2o",
                              "cfc11", "cfc12", "n2", "o2"))
    vmrs["rayleigh"] = fill(1.0, nlay, ncol)   # dummy; must be ignored by ID

    lw_scen = mso_write_stacked(joinpath(MSO_SCRATCH, "lw_stacked.nc"),
        conc["pressure_hl"], conc["temperature_hl"], lw_axis, vmrs)
    sw_scen = mso_write_stacked(joinpath(MSO_SCRATCH, "sw_stacked.nc"),
        conc["pressure_hl"], conc["temperature_hl"], sw_axis, vmrs)

    # --- parity vs pinned run_ckd smoke references -------------------------
    for (name, defpath, scenpath, active, smoke_nc) in (
            ("lw", lw32, lw_scen, lw_active, lw_smoke_nc),
            ("sw", sw32, sw_scen, sw_active, sw_smoke_nc))
        smoke = mso_load_smoke(smoke_nc)
        # states consistency: synthetic scenario is built on the conc grid,
        # which the SW/G1 parity units proved equals the smoke grid
        phl_rel = maximum(abs.(smoke["pressure_hl"] .- conc["pressure_hl"]) ./
                          max.(abs.(conc["pressure_hl"]), 1e-300))
        gates["$(name)_pressure_grid_consistent"] =
            phl_rel <= 1e-6 ? "passed" : "failed"
        phl_rel <= 1e-6 ||
            push!(fails, "$name smoke pressure grid != conc grid ($phl_rel)")

        r = matched_state_od(defpath, scenpath;
                             active_absorption_gases = active)
        sort(collect(keys(smoke["per_gas_od"]))) == sort(active) ||
            push!(fails, "$name smoke per-gas set != active set")
        allok = true
        for gas in active
            st = mso_parity_stats(r.per_gas_od[gas], smoke["per_gas_od"][gas])
            stats["$(name)_od_$(gas)"] = st
            ok = mso_parity_ok(st)
            allok &= ok
            ok || push!(fails, "$name od parity failed for $gas: $st")
        end
        ref_total = sum(smoke["per_gas_od"][g] for g in active)
        st = mso_parity_stats(r.total_raw, ref_total)
        stats["$(name)_od_total_raw"] = st
        allok &= mso_parity_ok(st)
        mso_parity_ok(st) || push!(fails, "$name raw total parity failed: $st")
        gates["$(name)_od_parity"] = allok ? "passed" : "failed"
        stats["$(name)_negativity"] = r.negativity
        # clamped field is a separate convention mirror, raw is preserved
        clamp_ok = r.total_clamped_run_ckd_convention == max.(r.total_raw, 0.0)
        gates["$(name)_clamp_field_separate"] = clamp_ok ? "passed" : "failed"
        clamp_ok || push!(fails, "$name clamped field != max(raw, 0)")
    end

    # --- permutation invariance: same data, different axis order ----------
    sw_axis_perm = ["ch4", "co2", "o2", "rayleigh", "h2o", "n2", "o3", "n2o"]
    sw_scen_perm = mso_write_stacked(joinpath(MSO_SCRATCH, "sw_perm.nc"),
        conc["pressure_hl"], conc["temperature_hl"], sw_axis_perm, vmrs)
    ra = matched_state_od(sw32, sw_scen;
                          active_absorption_gases = sw_active)
    rb = matched_state_od(sw32, sw_scen_perm;
                          active_absorption_gases = sw_active)
    perm_ok = all(ra.per_gas_od[g] == rb.per_gas_od[g] for g in sw_active) &&
              ra.total_raw == rb.total_raw
    gates["gas_axis_permutation_invariance"] = perm_ok ? "passed" : "failed"
    perm_ok || push!(fails, "permuted gas axis changed results: mapping by " *
                            "constituent_id is broken")

    # --- negativity accounting: ch4 vmr = 0 forces (vmr - ref) < 0 --------
    vmrs_neg = Dict{String, Any}(g => vmrs[g][:, 1:1] for g in keys(vmrs))
    vmrs_neg["ch4"] = zeros(nlay, 1)
    neg_scen = mso_write_stacked(joinpath(MSO_SCRATCH, "lw_neg.nc"),
        conc["pressure_hl"][:, 1:1], conc["temperature_hl"][:, 1:1],
        lw_axis, vmrs_neg)
    rn = matched_state_od(lw32, neg_scen;
                          active_absorption_gases = lw_active)
    neg_ok = rn.negativity["ch4"]["negative_count"] > 0 &&
             rn.negativity["ch4"]["min"] < 0.0 &&
             isfinite(rn.negativity["ch4"]["min"]) &&
             rn.total_clamped_run_ckd_convention ==
                 max.(rn.total_raw, 0.0) &&
             minimum(rn.total_raw) ==
                 rn.negativity["total_raw"]["min"]
    gates["negativity_findings_unclamped"] = neg_ok ? "passed" : "failed"
    neg_ok || push!(fails, "negativity fixture: ch4 zero-vmr must yield " *
                    "recorded negative per-gas OD with raw total preserved; " *
                    "got $(rn.negativity["ch4"])")
    stats["negativity_fixture"] = rn.negativity

    # --- refusal fixtures ---------------------------------------------------
    mso_expect_refusal!(gates, fails, "refuse_active_rayleigh",
        "cannot be active",
        () -> matched_state_od(sw32, sw_scen;
                               active_absorption_gases = ["composite", "rayleigh"]))
    mso_expect_refusal!(gates, fails, "refuse_active_n2",
        "cannot be active",
        () -> matched_state_od(sw32, sw_scen;
                               active_absorption_gases = ["n2"]))
    mso_expect_refusal!(gates, fails, "refuse_missing_conc_dependent_gas",
        "missing from the scenario constituent_id map",
        () -> matched_state_od(lw32, sw_scen;      # SW axis has no cfc11
                               active_absorption_gases = ["composite", "cfc11"]))
    mso_expect_refusal!(gates, fails, "refuse_gas_not_in_definition",
        "not in the definition gas set",
        () -> matched_state_od(sw32, sw_scen;
                               active_absorption_gases = ["so2"]))
    mso_expect_refusal!(gates, fails, "refuse_duplicate_active_gas",
        "duplicate gases",
        () -> matched_state_od(sw32, sw_scen;
                               active_absorption_gases = ["h2o", "h2o"]))
    mso_expect_refusal!(gates, fails, "refuse_empty_active_list",
        "non-empty",
        () -> matched_state_od(sw32, sw_scen;
                               active_absorption_gases = String[]))

    p_bad = copy(conc["pressure_hl"][:, 1:1]); p_bad[3, 1] = p_bad[2, 1]
    bad1 = mso_write_stacked(joinpath(MSO_SCRATCH, "bad_pressure.nc"),
        p_bad, conc["temperature_hl"][:, 1:1], sw_axis,
        Dict{String, Any}(g => vmrs[g][:, 1:1] for g in keys(vmrs)))
    mso_expect_refusal!(gates, fails, "refuse_nonmonotone_pressure",
        "strictly increasing",
        () -> matched_state_od(sw32, bad1;
                               active_absorption_gases = sw_active))

    t_bad = copy(conc["temperature_hl"][:, 1:1]); t_bad[5, 1] = NaN
    bad2 = mso_write_stacked(joinpath(MSO_SCRATCH, "bad_temperature.nc"),
        conc["pressure_hl"][:, 1:1], t_bad, sw_axis,
        Dict{String, Any}(g => vmrs[g][:, 1:1] for g in keys(vmrs)))
    mso_expect_refusal!(gates, fails, "refuse_nonfinite_temperature",
        "temperature_hl",
        () -> matched_state_od(sw32, bad2;
                               active_absorption_gases = sw_active))

    vmrs_bad = Dict{String, Any}(g => vmrs[g][:, 1:1] for g in keys(vmrs))
    vmrs_bad["h2o"] = copy(vmrs_bad["h2o"]); vmrs_bad["h2o"][7, 1] = -1e-6
    bad3 = mso_write_stacked(joinpath(MSO_SCRATCH, "bad_vmr.nc"),
        conc["pressure_hl"][:, 1:1], conc["temperature_hl"][:, 1:1],
        sw_axis, vmrs_bad)
    mso_expect_refusal!(gates, fails, "refuse_negative_active_vmr",
        "negative mole fractions",
        () -> matched_state_od(sw32, bad3;
                               active_absorption_gases = sw_active))

    bad4 = mso_write_stacked(joinpath(MSO_SCRATCH, "bad_dimorder.nc"),
        conc["pressure_hl"][:, 1:1], conc["temperature_hl"][:, 1:1],
        sw_axis, Dict{String, Any}(g => vmrs[g][:, 1:1] for g in keys(vmrs));
        mf_dim_order = ("gas", "level", "column"))
    mso_expect_refusal!(gates, fails, "refuse_wrong_dim_order",
        "!= [level, gas, column]",
        () -> matched_state_od(sw32, bad4;
                               active_absorption_gases = sw_active))

    bad5 = mso_write_stacked(joinpath(MSO_SCRATCH, "bad_cid.nc"),
        conc["pressure_hl"][:, 1:1], conc["temperature_hl"][:, 1:1],
        sw_axis, Dict{String, Any}(g => vmrs[g][:, 1:1] for g in keys(vmrs));
        constituent_id = join(sw_axis[1:end-1], " "))
    mso_expect_refusal!(gates, fails, "refuse_constituent_count_mismatch",
        "constituent_id count",
        () -> matched_state_od(sw32, bad5;
                               active_absorption_gases = sw_active))

    vmr1 = Dict{String, Any}(g => vmrs[g][:, 1:1] for g in keys(vmrs))
    bad6 = mso_write_stacked(joinpath(MSO_SCRATCH, "bad_no_rsmf.nc"),
        conc["pressure_hl"][:, 1:1], conc["temperature_hl"][:, 1:1],
        sw_axis, vmr1; write_rsmf = false)
    mso_expect_refusal!(gates, fails, "refuse_missing_reference_surface_mf",
        "missing reference_surface_mole_fraction",
        () -> matched_state_od(sw32, bad6;
                               active_absorption_gases = sw_active))

    bad_rsmf = fill(1e-6, length(sw_axis)); bad_rsmf[2] = -1e-9
    bad7 = mso_write_stacked(joinpath(MSO_SCRATCH, "bad_neg_rsmf.nc"),
        conc["pressure_hl"][:, 1:1], conc["temperature_hl"][:, 1:1],
        sw_axis, vmr1; rsmf = bad_rsmf)
    mso_expect_refusal!(gates, fails, "refuse_negative_reference_surface_mf",
        "reference_surface_mole_fraction has non-finite or negative",
        () -> matched_state_od(sw32, bad7;
                               active_absorption_gases = sw_active))

    vmr_unk = Dict{String, Any}(vmr1); vmr_unk["xyz"] = fill(1e-9, nlay, 1)
    bad8 = mso_write_stacked(joinpath(MSO_SCRATCH, "bad_unknown_axis.nc"),
        conc["pressure_hl"][:, 1:1], conc["temperature_hl"][:, 1:1],
        vcat(sw_axis, ["xyz"]), vmr_unk)
    mso_expect_refusal!(gates, fails, "refuse_unknown_scenario_axis_id",
        "unknown scenario gas ID xyz",
        () -> matched_state_od(sw32, bad8;
                               active_absorption_gases = sw_active))

    tiny_a = mso_write_tiny_definition(
        joinpath(MSO_SCRATCH, "tiny_def_wrong_set.nc");
        gases = ["composite", "h2o"], planck = true)
    mso_expect_refusal!(gates, fails, "refuse_definition_gas_set_mismatch",
        "definition gas set",
        () -> matched_state_od(tiny_a, sw_scen;
                               active_absorption_gases = ["composite"]))

    tiny_b = mso_write_tiny_definition(
        joinpath(MSO_SCRATCH, "tiny_def_gcount_drift.nc");
        gases = MSO_EXPECTED_DEFINITION_GASES["lw"], planck = true,
        bad_gpoint_gases = ["ch4"])
    mso_expect_refusal!(gates, fails, "refuse_definition_gcount_drift",
        "for ch4",
        () -> matched_state_od(tiny_b, sw_scen;
                               active_absorption_gases = ["composite"]))

    mso_expect_refusal!(gates, fails, "refuse_parity_stats_shape_mismatch",
        "identical shapes",
        () -> mso_parity_stats(zeros(2, 3), zeros(3, 2)))

    tiny_c = mso_write_tiny_definition(
        joinpath(MSO_SCRATCH, "tiny_def_wrong_code.nc");
        gases = MSO_EXPECTED_DEFINITION_GASES["lw"], planck = true,
        code_override = Dict("ch4" => 1))
    mso_expect_refusal!(gates, fails, "refuse_conc_code_map_violation",
        "!= published",
        () -> matched_state_od(tiny_c, sw_scen;
                               active_absorption_gases = ["composite"]))

    tiny_d = mso_write_tiny_definition(
        joinpath(MSO_SCRATCH, "tiny_def_uneven_p.nc");
        gases = MSO_EXPECTED_DEFINITION_GASES["lw"], planck = true,
        pressure_nodes = [100.0, 1000.0, 5000.0])
    mso_expect_refusal!(gates, fails, "refuse_uneven_logp_axis",
        "log-pressure LUT axis not evenly spaced",
        () -> matched_state_od(tiny_d, sw_scen;
                               active_absorption_gases = ["composite"]))

    tiny_e = mso_write_tiny_definition(
        joinpath(MSO_SCRATCH, "tiny_def_negative_coeff.nc");
        gases = MSO_EXPECTED_DEFINITION_GASES["lw"], planck = true,
        coeff_value = -1.0)
    mso_expect_refusal!(gates, fails, "refuse_negative_coefficients",
        "negative coefficients",
        () -> matched_state_od(tiny_e, sw_scen;
                               active_absorption_gases = ["composite"]))

    # --- verdict + artifacts ------------------------------------------------
    status = (isempty(fails) && all(v == "passed" for v in values(gates))) ?
             "matched_state_od_evaluator_passed" :
             "matched_state_od_evaluator_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_g2_matched_state_od_evaluator",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates,
        "failures" => fails,
        "parity_stats" => stats,
        "thresholds" => Dict("od_abs" => MSO_OD_ABS_TOL,
                             "od_rel" => MSO_OD_REL_TOL),
        "semantics" => Dict(
            "active_gas_selection" => "caller-explicit " *
                "active_absorption_gases; no definition-scenario " *
                "intersection; conc-dependent active gases required in " *
                "constituent_id; composite permitted without axis entry; " *
                "n2/o2/rayleigh refused as active; rayleigh excluded by ID",
            "clamp_policy" => "per-gas + total raw unclamped; " *
                "max(total, 0) provided only as the separate " *
                "run_ckd-output-convention field",
            "aggregation_choice" => "none -- evaluator is " *
                "aggregation-independent; Gate-2 dataset/aggregation and " *
                "thresholds-4/5 semantics remain unresolved rulings",
            "upstream_evidence" => "run_ckd.cpp:66-73,264-281,316; " *
                "ckd_model.cpp:178-199,963-1058 (LUT throw :988-990, " *
                "LINEAR/RELATIVE_LINEAR throw :1022-1024); " *
                "optimize_lut_lw.sh GASLIST :43-260; " *
                "optimize_lut_sw.sh GASLIST :73-244; published LW32 " *
                "stores cfc11/cfc12 as LINEAR code 1 (codes are read " *
                "from the file, never assumed)"),
        "provenance" => Dict(
            "branch" => branch, "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working " *
                "tree before its own commit",
            "lw_definition" => basename(lw32),
            "sw_definition" => basename(sw32),
            "lw_smoke" => lw_smoke_nc, "sw_smoke" => sw_smoke_nc,
            "concentrations" => basename(conc_nc),
            "fixture_dir" => MSO_SCRATCH),
        "disclaimer" => "aggregation-independent matched-state OD " *
            "evaluator library + self-tests; parity vs pinned run_ckd " *
            "smoke references through the stacked-axis scenario contract; " *
            "no Gate-2 dataset choice, no aggregation choice, no " *
            "thresholds-4/5 semantics, no optimizer/floor/recovery claims.",
    )
    mkpath(dirname(MSO_RESULTS_JSON))
    open(MSO_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(MSO_RESULTS_MD, "w") do io
        println(io, "# Gate-4 matched-state OD evaluator (aggregation-independent)\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Verdict |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nParity (Float32-storage tolerances: abs floor " *
                    "$(MSO_OD_ABS_TOL), rel $(MSO_OD_REL_TOL)):\n")
        println(io, "| Term | max_abs | max_rel (above floor) | signed bias |")
        println(io, "|---|---|---|---|")
        for k in sort(collect(keys(stats)))
            startswith(k, "lw_od_") || startswith(k, "sw_od_") || continue
            st = stats[k]
            println(io, "| $k | $(st["max_abs"]) | " *
                        "$(st["max_rel_above_abs_floor"]) | " *
                        "$(st["signed_bias_fraction"]) |")
        end
        if !isempty(fails)
            println(io, "\n## Failures\n")
            foreach(f -> println(io, "- ", f), fails)
        end
        println(io, "\nProvenance: branch `$branch`, head `$head` " *
                    "(pre-own-commit).")
    end
    println("gate4_g2_matched_state_od_evaluator: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), first(fails, 12))
    return status == "matched_state_od_evaluator_passed" ? 0 : 1
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end
