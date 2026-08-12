# Gate-4 SW optical-depth RECONSTRUCTION parity — read-only validation unit.
#
# SW analog of the LW G1 per-gas OD parity gates (gate4_forward_map_g1.jl
# increment 1, which passed 8/8 LW gases): rebuilds per-gas SHORTWAVE optical
# depths from the PUBLISHED SW32 ecCKD definition via the campaign's bilinear
# interpolation chain and compares against the pinned upstream run_ckd SW
# smoke reference at Float32 storage precision. The G1 runner's SW section
# consumed the upstream-EMITTED optical_depth (+ rayleigh) for direct-beam
# flux parity only — it never reconstructed SW OD from the tables. This unit
# closes that gap and thereby authorizes (or refuses) SW binding of the
# future Gate-2 true-OD metric.
#
# Clamp semantics (binding review requirement): run_ckd's emitted total
# `optical_depth` is max(sum(per-gas OD), 0) while the per-gas fields are
# UNCLAMPED. Therefore (a) the six per-gas comparisons below are raw and
# unclamped; (b) only the emitted-total comparison applies max(., 0); and
# (c) raw negative-total statistics (count, minimum) are reported and gated
# separately so clamping can never hide a reconstruction issue. Negative raw
# totals are findings, not values to silently clamp.
#
# Expected per-gas contract (asserted, both directions): the SW32 smoke
# reference carries exactly SIX per-gas optical_depth fields — composite,
# h2o, o3, co2, ch4, n2o. rayleigh_optical_depth is NOT a parity target
# (Rayleigh is not an absorption-coefficient reconstruction); it is noted
# separately, informationally, and excluded from all totals.
#
# Upstream algorithm reimplemented from source (identical to the G1 LW OD
# path; ckd_model.cpp:925-1010, run_ckd.cpp:119-121):
#   log_pressure_fl = log(0.5*(p_hl[l+1]+p_hl[l]))       (even log-p LUT grid)
#   T_fl = (T_hl.*p_hl [l] + T_hl.*p_hl [l+1]) / (p_hl[l] + p_hl[l+1])
#   t_0 = pweight0*T_(0,ip0) + pweight1*T_(0,ip0+1); tindex = (T_fl - t_0)/d_t
#   weight by conc_dependence_code READ FROM THE DEFINITION:
#     0 NONE (composite):       simple_weight
#     1 LINEAR (o3, co2):       simple_weight * vmr
#     2 LUT (h2o):              simple_weight * vmr, extra even-log-conc axis
#     3 RELATIVE_LINEAR (ch4, n2o): simple_weight * (vmr - ref), with ref the
#       Float32 value STORED IN THE FILE (never the nominal constant — G1
#       lesson: run_ckd promotes the stored Float32, and nominal-vs-stored
#       differences flip (vmr - ref) near-cancellations).
# Index clamps [0, n-1.0001] throughout.
#
# Tolerances mirror the G1 LW OD gates exactly (Float32-storage framing:
# rel 1e-6 comfortably above the ~6e-8 Float32 quantization of the reference
# fields; abs floor 1e-9 below which relative error carries no information).
#
# Data mode: published tables + upstream-tool reference on CKDMIP
# evaluation-1 present-day concentrations. Read-only; no optimizer,
# objective-value, floor, or recovery claims. Writes ONLY
# validation/results/gate4_sw_od_parity.{json,md}.
#
# NOTE: gate4_forward_map_g1.jl is a READING template only — it ends in
# exit(main()) and must never be include()d. The OD helpers below are copied
# from it (with attribution) and adapted to the SW definition contract; only
# the include-safe library gate4_forward_map.jl is included.

include(joinpath(@__DIR__, "gate4_forward_map.jl"))   # library: include-safe

using Dates
import JSON

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))
using NumericalRadiation

const SWOD_REFERENCE_NC =
    "/shared/home/greg/ecckd-derived-flux-work/g1-references/sw32_run_ckd_smoke.nc"
const SWOD_CONC_NC = "/shared/home/greg/data/ckdmip/evaluation1/conc/" *
                     "ckdmip_evaluation1_concentrations_present.nc"
const SWOD_RESULTS_JSON = validation_results_path("gate4_sw_od_parity.json")
const SWOD_RESULTS_MD = validation_results_path("gate4_sw_od_parity.md")

# Same thresholds as the G1 LW OD gates (G1_OD_REL_TOL / G1_OD_ABS_TOL).
const SWOD_OD_REL_TOL = 1e-6
const SWOD_OD_ABS_TOL = 1e-9

# Expected-gas contract for the pinned SW32 smoke reference (run_ckd invoked
# with gases=composite,h2o,o3,co2,ch4,n2o per the G1 provenance record).
const SWOD_GASES = ("composite", "h2o", "o3", "co2", "ch4", "n2o")
const SWOD_EXPECTED_CONC_CODE = Dict(
    "composite" => 0,   # NONE
    "h2o" => 2,         # LUT
    "o3" => 1,          # LINEAR
    "co2" => 1,         # LINEAR
    "ch4" => 3,         # RELATIVE_LINEAR
    "n2o" => 3,         # RELATIVE_LINEAR
)

# --- orientation-asserted loaders (style copied from gate4_forward_map_g1.jl)
function swod_load_reference(path, fails)
    ref = Dict{String, Any}()
    pergas = Dict{String, Array{Float64, 3}}()
    NCDatasets.NCDataset(path) do ds
        names = collect(String.(keys(ds)))
        odvars = sort([n for n in names if endswith(n, "_optical_depth")])
        gasset = sort([replace(n, "_optical_depth" => "") for n in odvars])
        ref["rayleigh_present"] = "rayleigh" in gasset
        ref["per_gas_set"] = sort([g for g in gasset if g != "rayleigh"])
        for n in vcat(odvars, ["optical_depth"])
            haskey(ds, n) || (push!(fails, "reference missing $n"); continue)
            v = ds[n]
            dn = collect(String.(NCDatasets.dimnames(v)))
            dn in (["g_point", "level", "column"],
                   ["g_point", "level_or_layer", "column"]) ||
                push!(fails, "orientation: $n dims $(dn) not an accepted " *
                             "(g_point, level, column) form")
            size(v) == (32, 54, 50) ||
                push!(fails, "orientation: $n size $(size(v)) != (32,54,50)")
        end
        for gas in ref["per_gas_set"]
            pergas[gas] = Float64.(Array(ds["$(gas)_optical_depth"]))
        end
        if ref["rayleigh_present"]
            ref["rayleigh_optical_depth"] =
                Float64.(Array(ds["rayleigh_optical_depth"]))
        end
        if haskey(ds, "optical_depth")
            ref["optical_depth"] = Float64.(Array(ds["optical_depth"]))
        end
        let v = ds["pressure_hl"]
            size(v) == (55, 50) ||
                push!(fails, "orientation: pressure_hl size $(size(v)) != (55,50)")
            ref["pressure_hl"] = Float64.(Array(v))          # (hl, col)
        end
        # Finding (recorded, not failed): the SW smoke file carries NO
        # temperature_hl; T comes from the conc file, the G1 convention.
        ref["has_temperature_hl"] = haskey(ds, "temperature_hl")
    end
    ref["per_gas_od"] = pergas
    return ref
end

# copied from gate4_forward_map_g1.jl:g1_load_concentrations (SW gas list)
function swod_load_concentrations(path, fails)
    conc = Dict{String, Any}()
    NCDatasets.NCDataset(path) do ds
        conc["pressure_hl"] = Float64.(Array(ds["pressure_hl"]))
        conc["temperature_hl"] = Float64.(Array(ds["temperature_hl"]))
        size(conc["pressure_hl"], 1) == 55 ||
            push!(fails, "conc pressure_hl first dim expected half_level=55, " *
                         "got $(size(conc["pressure_hl"]))")
        for gas in ("h2o", "o3", "co2", "ch4", "n2o")
            key = "$(gas)_mole_fraction_fl"
            haskey(ds, key) || (push!(fails, "conc missing $key"); continue)
            conc[gas] = Float64.(Array(ds[key]))              # (lay, col)
        end
    end
    return conc
end

# copied from gate4_forward_map_g1.jl:g1_load_definition, adapted: SW gas set,
# conc_dependence codes read from the file, rayleigh coefficient for the
# informational note.
function swod_load_definition(path, fails)
    d = Dict{String, Any}()
    NCDatasets.NCDataset(path) do ds
        d["coeff_gas_names"] = sort([replace(String(k), "_molar_absorption_coeff" => "")
                                     for k in keys(ds)
                                     if endswith(String(k), "_molar_absorption_coeff")])
        d["pressure"] = Float64.(Array(ds["pressure"]))       # (np) LUT nodes, Pa
        tv = ds["temperature"]
        d["temperature"] = Float64.(Array(tv))
        d["temperature_dims"] = collect(String.(NCDatasets.dimnames(tv)))
        for gas in SWOD_GASES
            key = "$(gas)_molar_absorption_coeff"
            haskey(ds, key) || (push!(fails, "definition missing $key"); continue)
            v = ds[key]
            d[gas] = Float64.(Array(v))
            d["$(gas)_dims"] = collect(String.(NCDatasets.dimnames(v)))
            ckey = "$(gas)_conc_dependence_code"
            if haskey(ds, ckey)
                d[ckey] = Int(only(Array(ds[ckey])))
            else
                push!(fails, "definition missing $ckey")
            end
        end
        if haskey(ds, "h2o_mole_fraction")
            d["h2o_vmr_axis"] = Float64.(Array(ds["h2o_mole_fraction"]))
        end
        for gas in ("ch4", "n2o")
            key = "$(gas)_reference_mole_fraction"
            if haskey(ds, key)
                # stored Float32 upstream; run_ckd promotes the STORED value —
                # parity requires Float64(stored Float32), never the nominal
                # create-time constant (G1 hard-won lesson: the rounding digit
                # flips (vmr - ref) near-cancellations)
                d["$(gas)_reference_vmr"] = Float64(only(Array(ds[key])))
            end
        end
        if haskey(ds, "rayleigh_molar_scattering_coeff")
            d["rayleigh_molar_scattering_coeff"] =
                Float64.(Array(ds["rayleigh_molar_scattering_coeff"]))
        end
    end
    return d
end

# --- upstream OD reconstruction (copied from gate4_forward_map_g1.jl:
# G1ColumnGrid/g1_column_grid/g1_pt_stencil/g1_coeff/g1_gas_od!, verbatim
# except conc_dependence_code-driven weights) -------------------------------
struct SwodColumnGrid
    p_hl::Vector{Float64}
    t_fl::Vector{Float64}
    logp_fl::Vector{Float64}
    simple_weight::Vector{Float64}
end

function swod_column_grid(p_hl::AbstractVector, t_hl::AbstractVector)
    nlay = length(p_hl) - 1
    t_fl = similar(t_hl, nlay)
    logp_fl = similar(t_fl)
    sw = similar(t_fl)
    for l in 1:nlay
        pt1 = t_hl[l] * p_hl[l]
        pt2 = t_hl[l+1] * p_hl[l+1]
        t_fl[l] = (pt1 + pt2) / (p_hl[l] + p_hl[l+1])   # run_ckd.cpp:119-121
        logp_fl[l] = log(0.5 * (p_hl[l+1] + p_hl[l]))   # ckd_model.cpp:937
        sw[l] = g4_simple_weight(p_hl[l+1] - p_hl[l])
    end
    return SwodColumnGrid(collect(p_hl), t_fl, logp_fl, sw)
end

# per-layer (ip0, pw1, it0, tw1) indices per upstream even-grid rules
function swod_pt_stencil(defn, logp_fl::Real, t_fl::Real)
    p_nodes = defn["pressure"]
    logp0 = log(p_nodes[1])
    dlogp = log(p_nodes[2]) - log(p_nodes[1])
    np = length(p_nodes)
    pidx = clamp((logp_fl - logp0) / dlogp, 0.0, np - 1.0001)
    ip0 = floor(Int, pidx); pw1 = pidx - ip0
    Tm = defn["temperature"]
    tdims = defn["temperature_dims"]
    # verified layout (SW32 definition, same as LW32): dims (pressure, temperature)
    tdims == ["pressure", "temperature"] ||
        error("unexpected temperature dims: $tdims")
    t_row0 = Tm[:, 1]                         # first T node per pressure
    d_t = Tm[1, 2] - Tm[1, 1]                 # even spacing (ckd_model.cpp:925)
    nt = size(Tm, 2)
    t0 = (1 - pw1) * t_row0[ip0 + 1] + pw1 * t_row0[ip0 + 2 <= np ? ip0 + 2 : ip0 + 1]
    tidx = clamp((t_fl - t0) / d_t, 0.0, nt - 1.0001)
    it0 = floor(Int, tidx); tw1 = tidx - it0
    return ip0, pw1, it0, tw1
end

# coefficient lookup honoring the definition variable's dimension order
function swod_coeff(defn, gas, g::Int, ip0::Int, pw1, it0::Int, tw1;
                    ic0::Int = -1, cw1 = 0.0)
    A = defn[gas]
    dims = defn["$(gas)_dims"]
    # verified layout (SW32 definition): (g_point, pressure, temperature[, h2o_mole_fraction])
    dims[1] == "g_point" && dims[2] == "pressure" && dims[3] == "temperature" ||
        error("unexpected coefficient dims for $gas: $dims")
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

function swod_gas_od!(od, defn, gas, grid::SwodColumnGrid, vmr_fl)
    ng = size(od, 1)
    nlay = length(grid.t_fl)
    code = defn["$(gas)_conc_dependence_code"]
    for l in 1:nlay
        ip0, pw1, it0, tw1 = swod_pt_stencil(defn, grid.logp_fl[l], grid.t_fl[l])
        weight = if code == 0                       # NONE (composite)
            grid.simple_weight[l]
        elseif code == 1 || code == 2               # LINEAR / LUT
            grid.simple_weight[l] * vmr_fl[l]
        elseif code == 3                            # RELATIVE_LINEAR
            haskey(defn, "$(gas)_reference_vmr") ||
                error("$gas is RELATIVE_LINEAR but has no stored reference " *
                      "mole fraction in the definition")
            grid.simple_weight[l] * (vmr_fl[l] - defn["$(gas)_reference_vmr"])
        else
            error("unsupported conc_dependence_code $code for $gas")
        end
        ic0 = -1; cw1 = 0.0
        if code == 2
            haskey(defn, "h2o_vmr_axis") ||
                error("$gas is LUT but definition has no h2o_mole_fraction axis")
            va = defn["h2o_vmr_axis"]
            dlc = log(va[2] / va[1])
            cidx = clamp((log(vmr_fl[l]) - log(va[1])) / dlc,
                         0.0, length(va) - 1.0001)
            ic0 = floor(Int, cidx); cw1 = cidx - ic0
        end
        for g in 1:ng
            od[g, l] = swod_coeff(defn, gas, g, ip0, pw1, it0, tw1;
                                  ic0 = ic0, cw1 = cw1) * weight
        end
    end
    return od
end

# --- parity statistics (copied from gate4_forward_map_g1.jl:g1_parity_stats) ---
function swod_parity_stats(ours::AbstractArray, ref::AbstractArray)
    n = length(ref)
    max_abs = 0.0; max_rel = 0.0
    pos = 0; neg = 0
    worst = (0, 0.0, 0.0)
    for i in eachindex(ref)
        d = ours[i] - ref[i]
        ad = abs(d)
        rel = ad / max(abs(ref[i]), abs(ours[i]), 1e-300)
        if ad > max_abs
            max_abs = ad
        end
        if rel > max_rel && ad > SWOD_OD_ABS_TOL
            max_rel = rel
            worst = (i, ours[i], ref[i])
        end
        d > 0 && (pos += 1)
        d < 0 && (neg += 1)
    end
    signed = pos + neg == 0 ? 0.0 : (pos - neg) / (pos + neg)
    return Dict{String, Any}(
        "n" => n, "max_abs" => max_abs, "max_rel_above_abs_floor" => max_rel,
        "pos_residuals" => pos, "neg_residuals" => neg,
        "signed_bias_fraction" => signed,
        "worst_linear_index" => worst[1], "worst_ours" => worst[2],
        "worst_ref" => worst[3],
        "abs_tol" => SWOD_OD_ABS_TOL, "rel_tol" => SWOD_OD_REL_TOL,
    )
end

function swod_gate!(gates, fails, name, st)
    pass = (st["max_abs"] <= SWOD_OD_ABS_TOL) ||
           (st["max_rel_above_abs_floor"] <= SWOD_OD_REL_TOL)
    bias_ok = abs(st["signed_bias_fraction"]) < 0.9 ||
              st["max_abs"] <= SWOD_OD_ABS_TOL
    gates[name] = pass && bias_ok ? "passed" : "failed"
    pass || push!(fails, "$name: max_abs=$(st["max_abs"]) " *
                         "max_rel=$(st["max_rel_above_abs_floor"])")
    bias_ok || push!(fails, "$name signed bias: $(st["signed_bias_fraction"])")
    return st
end

function main()
    fails = String[]
    timings = Dict{String, Float64}()
    gates = Dict{String, String}()

    sw32 = NumericalRadiation.official_ecckd_definition_path(:shortwave_32)

    local ref, conc, defn
    timings["load_seconds"] = @elapsed begin
        ref = swod_load_reference(SWOD_REFERENCE_NC, fails)
        conc = swod_load_concentrations(SWOD_CONC_NC, fails)
        defn = swod_load_definition(sw32, fails)
    end
    orientation_ok = isempty(fails)

    # --- gate: exact per-gas variable set (both directions) --------------------
    expected = sort(collect(SWOD_GASES))
    gates["per_gas_variable_set"] =
        ref["per_gas_set"] == expected ? "passed" : "failed"
    ref["per_gas_set"] == expected ||
        push!(fails, "per-gas OD set $(ref["per_gas_set"]) != expected " *
                     "$(expected) (rayleigh excluded from the target set)")
    # definition-side bidirectional set gate (monitor fix 1): absorption-
    # coefficient tables must be EXACTLY the six expected gases -- an extra
    # or missing definition gas must be detected, not silently skipped.
    # (rayleigh_molar_scattering_coeff is a scattering table, not an
    # absorption coefficient, so it is outside this set by construction.)
    gates["definition_gas_set"] =
        defn["coeff_gas_names"] == expected ? "passed" : "failed"
    defn["coeff_gas_names"] == expected ||
        push!(fails, "definition coefficient set $(defn["coeff_gas_names"]) " *
                     "!= expected $(expected)")

    # --- gate: conc-dependence codes read from the published definition --------
    codes = Dict(gas => get(defn, "$(gas)_conc_dependence_code", nothing)
                 for gas in SWOD_GASES)
    codes_ok = all(codes[gas] == SWOD_EXPECTED_CONC_CODE[gas] for gas in SWOD_GASES)
    gates["conc_dependence_codes"] = codes_ok ? "passed" : "failed"
    codes_ok || push!(fails, "conc_dependence codes $(codes) != expected " *
                             "$(SWOD_EXPECTED_CONC_CODE)")

    # --- gate: smoke pressure_hl vs conc pressure_hl (monitor fix 3) -----------
    phl_max_rel = maximum(abs.(ref["pressure_hl"] .- conc["pressure_hl"]) ./
                          max.(abs.(conc["pressure_hl"]), 1e-300))
    gates["pressure_hl_smoke_conc_consistent"] =
        phl_max_rel <= 1e-6 ? "passed" : "failed"
    phl_max_rel <= 1e-6 ||
        push!(fails, "smoke pressure_hl != conc pressure_hl " *
                     "(max rel $(phl_max_rel)): wrong concentration input?")

    # --- per-gas RAW (unclamped) OD reconstruction parity ----------------------
    gas_stats = Dict{String, Any}()
    ours_all = Dict{String, Array{Float64, 3}}()
    timings["od_parity_seconds"] = @elapsed begin
        ncol = size(ref["pressure_hl"], 2)
        for gas in SWOD_GASES
            (haskey(defn, gas) && haskey(ref["per_gas_od"], gas)) || continue
            refod = ref["per_gas_od"][gas]         # (g, lay, col), raw/unclamped
            ng, nlay, _ = size(refod)
            ours = zeros(ng, nlay, ncol)
            for c in 1:ncol
                grid = swod_column_grid(view(ref["pressure_hl"], :, c),
                                        view(conc["temperature_hl"], :, c))
                vmr = gas == "composite" ? zeros(nlay) : view(conc[gas], :, c)
                swod_gas_od!(view(ours, :, :, c), defn, gas, grid, vmr)
            end
            ours_all[gas] = ours
            gas_stats[gas] = swod_gate!(gates, fails, "od_$(gas)",
                                        swod_parity_stats(ours, refod))
        end
    end

    # --- totals + negativity findings ------------------------------------------
    total_stats = Dict{String, Any}()
    timings["total_parity_seconds"] = @elapsed begin
        have_all = all(haskey(ours_all, g) && haskey(ref["per_gas_od"], g)
                       for g in SWOD_GASES)
        if have_all
            recon_total = sum(ours_all[g] for g in SWOD_GASES)       # raw double
            ref_raw_total = sum(ref["per_gas_od"][g] for g in SWOD_GASES)
            abs_sum = sum(abs.(ref["per_gas_od"][g]) for g in SWOD_GASES)

            # (raw) total absorption OD, ex-rayleigh, UNCLAMPED both sides
            total_stats["total_raw"] = swod_gate!(gates, fails, "od_total_raw",
                swod_parity_stats(recon_total, ref_raw_total))

            # clamped comparison ONLY against the upstream-emitted total,
            # documented as max(sum(per-gas OD), 0)
            if haskey(ref, "optical_depth")
                total_stats["total_clamped_vs_emitted"] =
                    swod_gate!(gates, fails, "od_total_clamped_vs_emitted",
                        swod_parity_stats(max.(recon_total, 0.0),
                                          ref["optical_depth"]))
                # informational (not gated): documented clamp semantics of the
                # reference file itself
                total_stats["emitted_vs_clamped_ref_gas_sum_note"] =
                    swod_parity_stats(max.(ref_raw_total, 0.0),
                                      ref["optical_depth"])
            else
                gates["od_total_clamped_vs_emitted"] = "failed"
                push!(fails, "reference carries no emitted total optical_depth")
            end

            # raw negative-total FINDINGS (never hidden by clamping): count,
            # minimum, and sign consistency vs the reference per-gas sum with a
            # per-entry Float32-storage band 4*eps32*sum(|per-gas ref|)+1e-12.
            neg_ours = count(<(0.0), recon_total)
            neg_ref = count(<(0.0), ref_raw_total)
            min_ours = isempty(recon_total) ? 0.0 : minimum(recon_total)
            min_ref = isempty(ref_raw_total) ? 0.0 : minimum(ref_raw_total)
            sign_mismatch = 0
            worst_band_excess = 0.0
            for i in eachindex(recon_total)
                (recon_total[i] < 0.0) == (ref_raw_total[i] < 0.0) && continue
                band = 4 * eps(Float32) * abs_sum[i] + 1e-12
                if min(abs(recon_total[i]), abs(ref_raw_total[i])) > band
                    sign_mismatch += 1
                    worst_band_excess = max(worst_band_excess,
                        min(abs(recon_total[i]), abs(ref_raw_total[i])) - band)
                end
            end
            min_ok = abs(min_ours - min_ref) <=
                     max(SWOD_OD_ABS_TOL, SWOD_OD_REL_TOL * abs(min_ref))
            # BINDING (monitor fix 2): zero raw negatives on BOTH sides with
            # finite minima. Matching negatives must NOT pass -- negative raw
            # totals are findings. Sign-band and min-agreement comparisons
            # are DIAGNOSTICS only (reported below, not gated).
            negativity_ok = neg_ours == 0 && neg_ref == 0 &&
                            isfinite(min_ours) && isfinite(min_ref)
            gates["raw_total_negativity"] = negativity_ok ? "passed" : "failed"
            negativity_ok ||
                push!(fails, "raw negative totals present: ours=$(neg_ours) " *
                             "(min $(min_ours)) ref-sum=$(neg_ref) " *
                             "(min $(min_ref)) -- findings, not clamped")
            total_stats["raw_negativity"] = Dict(
                "negative_count_ours" => neg_ours,
                "negative_count_ref_gas_sum" => neg_ref,
                "min_raw_total_ours" => min_ours,
                "min_raw_total_ref_gas_sum" => min_ref,
                "n_entries" => length(recon_total),
                "diagnostic_sign_mismatch_beyond_band" => sign_mismatch,
                "diagnostic_worst_band_excess" => worst_band_excess,
                "diagnostic_min_agreement_ok" => min_ok,
            )
        else
            for g in ("od_total_raw", "od_total_clamped_vs_emitted",
                      "raw_total_negativity")
                gates[g] = "failed"
            end
            push!(fails, "totals skipped: per-gas set incomplete")
        end
    end

    # --- rayleigh note (informational; NOT a parity target, NOT in totals) -----
    rayleigh_note = Dict{String, Any}("present" => ref["rayleigh_present"])
    if ref["rayleigh_present"] && haskey(defn, "rayleigh_molar_scattering_coeff")
        rc = defn["rayleigh_molar_scattering_coeff"]
        refray = ref["rayleigh_optical_depth"]
        ng, nlay, ncol = size(refray)
        ours = zeros(ng, nlay, ncol)
        for c in 1:ncol
            grid = swod_column_grid(view(ref["pressure_hl"], :, c),
                                    view(conc["temperature_hl"], :, c))
            for l in 1:nlay, g in 1:ng
                ours[g, l, c] = rc[g] * grid.simple_weight[l]
            end
        end
        rayleigh_note["informational_stats"] = swod_parity_stats(ours, refray)
        rayleigh_note["note"] = "rayleigh_od = rayleigh_molar_scattering_coeff" *
            " * simple_weight, reported informationally only; excluded from " *
            "the parity target set and from all totals"
    end

    status = (isempty(fails) && all(v == "passed" for v in values(gates))) ?
             "sw_od_parity_passed" : "sw_od_parity_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_sw_od_parity",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates,
        "failures" => fails,
        "gas_stats" => gas_stats,
        "total_stats" => total_stats,
        "rayleigh_note" => rayleigh_note,
        "conc_dependence_codes" => codes,
        "relative_linear_reference_vmr" => Dict(
            gas => get(defn, "$(gas)_reference_vmr", nothing)
            for gas in ("ch4", "n2o")),
        "orientation_check" => orientation_ok ? "passed" : "failed",
        "reference_has_temperature_hl" => ref["has_temperature_hl"],
        "pressure_hl_smoke_vs_conc_max_rel" => phl_max_rel,
        "thresholds" => Dict("od_abs" => SWOD_OD_ABS_TOL,
                             "od_rel" => SWOD_OD_REL_TOL),
        "timings_seconds" => timings,
        "maxrss_bytes" => Int(Sys.maxrss()),
        "provenance" => Dict(
            "branch" => branch, "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit",
            "reference_nc" => SWOD_REFERENCE_NC,
            "reference_tool" => "pinned run_ckd (ecckd source artifact " *
                "6115f9b8, May-2026 build in ecckd-derived-flux-work)",
            "reference_command" => "run_ckd ckd_model=<SW32 published " *
                "ecckd-1.4_sw_climate_rgb-32b> input=<evaluation1 present " *
                "conc> gases=composite,h2o,o3,co2,ch4,n2o tsi=1361.0",
            "sw32_path_authority" => "resolved via " *
                "NumericalRadiation.official_ecckd_definition_path(:shortwave_32)",
            "ckd_definition" => basename(sw32),
            "concentrations" => basename(SWOD_CONC_NC),
            "clamp_policy" => "per-gas + raw-total comparisons unclamped; " *
                "max(.,0) applied ONLY against the upstream-emitted total; " *
                "raw negativity gated separately",
        ),
        "disclaimer" => "read-only SW OD reconstruction parity (per-gas raw, " *
            "total raw, clamped-vs-emitted, raw negativity); authorizes (or " *
            "refuses) SW binding of the Gate-2 true-OD metric; no optimizer, " *
            "objective-value, floor, or recovery claims.",
    )

    mkpath(dirname(SWOD_RESULTS_JSON))
    open(SWOD_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(SWOD_RESULTS_MD, "w") do io
        println(io, "# Gate-4 SW optical-depth reconstruction parity\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "Per-gas RAW (unclamped) OD parity vs pinned run_ckd " *
                    "smoke reference, Float32 storage precision " *
                    "(abs floor $(SWOD_OD_ABS_TOL), rel tol $(SWOD_OD_REL_TOL)):\n")
        println(io, "| Gas | conc code | max_abs | max_rel (above abs floor) | signed bias | gate |")
        println(io, "|---|---|---|---|---|---|")
        for gas in SWOD_GASES
            haskey(gas_stats, gas) || continue
            st = gas_stats[gas]
            println(io, "| $gas | $(codes[gas]) | $(st["max_abs"]) | " *
                        "$(st["max_rel_above_abs_floor"]) | " *
                        "$(st["signed_bias_fraction"]) | $(gates["od_$gas"]) |")
        end
        println(io, "\n## Totals (ex-rayleigh)\n")
        println(io, "| Term | max_abs | max_rel (above abs floor) | signed bias | gate |")
        println(io, "|---|---|---|---|---|")
        for (label, key, gk) in (
                ("raw total vs ref per-gas sum", "total_raw", "od_total_raw"),
                ("max(raw,0) vs emitted optical_depth",
                 "total_clamped_vs_emitted", "od_total_clamped_vs_emitted"))
            haskey(total_stats, key) || continue
            st = total_stats[key]
            println(io, "| $label | $(st["max_abs"]) | " *
                        "$(st["max_rel_above_abs_floor"]) | " *
                        "$(st["signed_bias_fraction"]) | $(gates[gk]) |")
        end
        if haskey(total_stats, "raw_negativity")
            rn = total_stats["raw_negativity"]
            println(io, "\nRaw negative-total findings (gate " *
                "$(gates["raw_total_negativity"])): ours " *
                "$(rn["negative_count_ours"])/$(rn["n_entries"]) negative " *
                "(min $(rn["min_raw_total_ours"])); reference per-gas sum " *
                "$(rn["negative_count_ref_gas_sum"]) negative " *
                "(min $(rn["min_raw_total_ref_gas_sum"])); sign mismatches " *
                "beyond the Float32 band: $(rn["diagnostic_sign_mismatch_beyond_band"]) " *
                "(worst excess $(rn["diagnostic_worst_band_excess"])); " *
                "min-agreement diagnostic: $(rn["diagnostic_min_agreement_ok"]).")
        end
        if get(rayleigh_note, "present", false) &&
           haskey(rayleigh_note, "informational_stats")
            st = rayleigh_note["informational_stats"]
            println(io, "\nRayleigh (informational only, excluded from parity " *
                "targets and totals): max_abs $(st["max_abs"]), max_rel " *
                "$(st["max_rel_above_abs_floor"]).")
        end
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit); reference: pinned run_ckd SW " *
                    "smoke output; definition `$(basename(sw32))`.")
        if !isempty(fails)
            println(io, "\n## Failures\n")
            foreach(f -> println(io, "- ", f), fails)
        end
    end

    println("gate4_sw_od_parity: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), first(fails, 12))
    return status == "sw_od_parity_passed" ? 0 : 1
end

exit(main())
