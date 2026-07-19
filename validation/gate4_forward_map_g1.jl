# Gate-4 P2 G1 parity runner — increment 1: per-gas OPTICAL-DEPTH parity.
#
# Compares this repo's forward-map optical-depth reconstruction against the
# pinned upstream run_ckd tool's emitted per-gas optical depths for the
# published LW32 model on CKDMIP evaluation-1 present-day concentrations
# (reference NetCDF produced by the provenance-recorded smoke invocation).
# Term-resolved and target-split per the design (section 7): this increment
# covers OD only; spectral/broadband flux and heating parity follow.
#
# Upstream algorithm reimplemented from source (ckd_model.cpp:925-1010):
#   log_pressure_fl = log(0.5*(p_hl[l+1]+p_hl[l]))      (even log-p LUT grid)
#   t_0 = pweight0*T_(0,ip0) + pweight1*T_(0,ip0+1); tindex = (T_fl - t_0)/d_t
#   T_fl = (T_hl.*p_hl [l] + T_hl.*p_hl [l+1]) / (p_hl[l] + p_hl[l+1])
#          (run_ckd.cpp:119-121, pressure-weighted)
#   weight = simple_weight * vmr        (linear; composite uses dry-air moles)
#          = simple_weight * (vmr-ref)  (relative-linear: ch4, n2o)
#   LUT gases (h2o): extra even log-conc axis, trilinear.
# Index clamps [0, n-1.0001] throughout.
#
# Data mode: published tables + upstream-tool reference on CKDMIP
# concentrations. No objective-value, floor, or recovery claims.

include(joinpath(@__DIR__, "gate4_forward_map.jl"))

using Dates
import JSON

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))
using NumericalRadiation

const G1_REFERENCE_NC =
    "/shared/home/greg/ecckd-derived-flux-work/g1-references/lw32_run_ckd_smoke.nc"
const G1_SW_REFERENCE_NC =
    "/shared/home/greg/ecckd-derived-flux-work/g1-references/sw32_run_ckd_smoke.nc"
const G1_SW_REFERENCE_COS_SZA = 0.5   # run_ckd REFERENCE_COS_SZA (run_ckd.cpp)
const G1_RESULTS_JSON = validation_results_path("gate4_forward_map_g1.json")
const G1_RESULTS_MD = validation_results_path("gate4_forward_map_g1.md")

const G1_OD_REL_TOL = 1e-6
const G1_OD_ABS_TOL = 1e-9

const G1_RELATIVE_LINEAR_REF = Dict("ch4" => 1921.0e-9, "n2o" => 332.0e-9)

# --- orientation-asserted loaders ------------------------------------------------
function g1_assert_dims(var, wanted::Vector{String}, name::String, fails)
    dn = collect(String.(NCDatasets.dimnames(var)))
    dn == wanted ||
        push!(fails, "orientation: $name dims $(dn) != expected $(wanted)")
    return dn == wanted
end

function g1_load_reference(path, fails)
    ref = Dict{String, Any}()
    NCDatasets.NCDataset(path) do ds
        for gas in ("composite", "h2o", "o3", "co2", "ch4", "n2o", "cfc11", "cfc12")
            v = ds["$(gas)_optical_depth"]
            dn = collect(String.(NCDatasets.dimnames(v)))
            dn in (["g_point", "level", "column"],
                   ["g_point", "level_or_layer", "column"]) ||
                push!(fails, "orientation: $(gas)_optical_depth dims $(dn) " *
                             "not an accepted (g_point, level, column) form")
            ref[gas] = Float64.(Array(v))          # julia sees (g, lay, col)
        end
        for n in ("spectral_flux_up_lw", "spectral_flux_dn_lw")
            v = ds[n]
            size(v) == (32, 55, 50) ||
                push!(fails, "orientation: $n size $(size(v)) != (32,55,50)")
            ref[n] = Float64.(Array(v))
        end
        for n in ("flux_up_lw", "flux_dn_lw")
            v = ds[n]
            size(v) == (55, 50) ||
                push!(fails, "orientation: $n size $(size(v)) != (55,50)")
            ref[n] = Float64.(Array(v))
        end
        let v = ds["optical_depth"]
            dn = collect(String.(NCDatasets.dimnames(v)))
            dn in (["g_point", "level", "column"],
                   ["g_point", "level_or_layer", "column"]) ||
                push!(fails, "orientation: optical_depth dims $(dn) unexpected")
            ref["optical_depth"] = Float64.(Array(v))   # upstream-clamped total
        end
        let v = ds["planck_hl"]
            size(v) == (32, 55, 50) ||
                push!(fails, "orientation: planck_hl size $(size(v)) != (32,55,50)")
        end
        let v = ds["planck_surf"]
            size(v) == (32, 50) ||
                push!(fails, "orientation: planck_surf size $(size(v)) != (32,50)")
        end
        ref["pressure_hl"] = Float64.(Array(ds["pressure_hl"]))   # (hl, col)
        ref["planck_hl"] = Float64.(Array(ds["planck_hl"]))       # (g, hl, col)
        ref["planck_surf"] = Float64.(Array(ds["planck_surf"]))   # (g, col)
    end
    return ref
end

function g1_load_concentrations(path, fails)
    conc = Dict{String, Any}()
    NCDatasets.NCDataset(path) do ds
        conc["pressure_hl"] = Float64.(Array(ds["pressure_hl"]))
        conc["temperature_hl"] = Float64.(Array(ds["temperature_hl"]))
        size(conc["pressure_hl"], 1) == 55 ||
            push!(fails, "conc pressure_hl first dim expected half_level=55, " *
                         "got $(size(conc["pressure_hl"]))")
        for gas in ("h2o", "o3", "co2", "ch4", "n2o", "cfc11", "cfc12")
            key = "$(gas)_mole_fraction_fl"
            haskey(ds, key) || (push!(fails, "conc missing $key"); continue)
            conc[gas] = Float64.(Array(ds[key]))                  # (lay, col)
        end
    end
    return conc
end

# definition tables: coefficient dims and axes, orientation-asserted
function g1_load_definition(path, fails)
    d = Dict{String, Any}()
    NCDatasets.NCDataset(path) do ds
        d["pressure"] = Float64.(Array(ds["pressure"]))           # (np) LUT nodes, Pa
        tv = ds["temperature"]
        d["temperature"] = Float64.(Array(tv))                    # expect (nt?, np?)...
        d["temperature_dims"] = collect(String.(NCDatasets.dimnames(tv)))
        for gas in ("composite", "h2o", "o3", "co2", "ch4", "n2o", "cfc11", "cfc12")
            key = "$(gas)_molar_absorption_coeff"
            haskey(ds, key) || (push!(fails, "definition missing $key"); continue)
            v = ds[key]
            d[gas] = Float64.(Array(v))
            d["$(gas)_dims"] = collect(String.(NCDatasets.dimnames(v)))
        end
        if haskey(ds, "h2o_mole_fraction")
            d["h2o_vmr_axis"] = Float64.(Array(ds["h2o_mole_fraction"]))
        end
        for gas in ("ch4", "n2o")
            key = "$(gas)_reference_mole_fraction"
            if haskey(ds, key)
                # stored Float32 upstream; run_ckd promotes the stored value,
                # so parity requires Float64(Float32 value), not the nominal
                # create-time constant (which differs at the rounding digit
                # and flips (vmr - ref) near-cancellations)
                d["$(gas)_reference_vmr"] = Float64(only(Array(ds[key])))
            end
        end
    end
    return d
end

# --- upstream OD reconstruction (exact algorithm) --------------------------------
struct G1ColumnGrid
    p_hl::Vector{Float64}
    t_fl::Vector{Float64}
    logp_fl::Vector{Float64}
    simple_weight::Vector{Float64}
end

function g1_column_grid(p_hl::AbstractVector, t_hl::AbstractVector)
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
    return G1ColumnGrid(collect(p_hl), t_fl, logp_fl, sw)
end

# per-layer (ip0, pw1, it0, tw1) indices per upstream even-grid rules
function g1_pt_stencil(defn, logp_fl::Real, t_fl::Real)
    p_nodes = defn["pressure"]
    logp0 = log(p_nodes[1])
    dlogp = log(p_nodes[2]) - log(p_nodes[1])
    np = length(p_nodes)
    pidx = clamp((logp_fl - logp0) / dlogp, 0.0, np - 1.0001)
    ip0 = floor(Int, pidx); pw1 = pidx - ip0
    Tm = defn["temperature"]
    tdims = defn["temperature_dims"]
    # verified layout (LW32 definition): temperature dims (pressure, temperature)
    tdims == ["pressure", "temperature"] ||
        error("unexpected temperature dims: $tdims")
    t_row0 = Tm[:, 1]                         # first T node per pressure
    d_t = Tm[1, 2] - Tm[1, 1]                 # even spacing (ckd_model.cpp:925)
    nt = size(Tm, 2)
    t0 = (1 - pw1) * t_row0[ip0 + 1] + pw1 * t_row0[ip0 + 2 <= np ? ip0 + 2 : ip0 + 1]
    tidx = clamp((t_fl - t0) / d_t, 0.0, nt - 1.0001)
    it0 = floor(Int, tidx); tw1 = tidx - it0
    return ip0, pw1, it0, tw1, tdims
end

# coefficient lookup honoring the definition variable's dimension order
function g1_coeff(defn, gas, g::Int, ip0::Int, pw1, it0::Int, tw1;
                  ic0::Int = -1, cw1 = 0.0)
    A = defn[gas]
    dims = defn["$(gas)_dims"]
    # verified layout (LW32 definition): (g_point, pressure, temperature[, h2o_mole_fraction])
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

function g1_gas_od!(od, defn, gas, grid::G1ColumnGrid, vmr_fl)
    ng = size(od, 1)
    nlay = length(grid.t_fl)
    for l in 1:nlay
        ip0, pw1, it0, tw1, _ = g1_pt_stencil(defn, grid.logp_fl[l], grid.t_fl[l])
        weight = if gas == "composite"
            grid.simple_weight[l]
        elseif haskey(defn, "$(gas)_reference_vmr")
            grid.simple_weight[l] * (vmr_fl[l] - defn["$(gas)_reference_vmr"])
        elseif haskey(G1_RELATIVE_LINEAR_REF, gas)
            grid.simple_weight[l] * (vmr_fl[l] - G1_RELATIVE_LINEAR_REF[gas])
        else
            grid.simple_weight[l] * vmr_fl[l]
        end
        ic0 = -1; cw1 = 0.0
        if gas == "h2o" && haskey(defn, "h2o_vmr_axis")
            va = defn["h2o_vmr_axis"]
            dlc = log(va[2] / va[1])
            cidx = clamp((log(vmr_fl[l]) - log(va[1])) / dlc,
                         0.0, length(va) - 1.0001)
            ic0 = floor(Int, cidx); cw1 = cidx - ic0
        end
        for g in 1:ng
            od[g, l] = g1_coeff(defn, gas, g, ip0, pw1, it0, tw1;
                                ic0 = ic0, cw1 = cw1) * weight
        end
    end
    return od
end

# --- parity statistics ------------------------------------------------------------
function g1_parity_stats(ours::AbstractArray, ref::AbstractArray)
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
        if rel > max_rel && ad > G1_OD_ABS_TOL
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
    )
end

function g1_parity_stats_flux(ours::AbstractArray, ref::AbstractArray)
    max_abs = 0.0; max_rel = 0.0
    pos = 0; neg = 0
    for i in eachindex(ref)
        d = ours[i] - ref[i]
        ad = abs(d)
        ad > max_abs && (max_abs = ad)
        rel = ad / max(abs(ref[i]), abs(ours[i]), 1e-300)
        if rel > max_rel && ad > 1e-9
            max_rel = rel
        end
        d > 0 && (pos += 1)
        d < 0 && (neg += 1)
    end
    signed = pos + neg == 0 ? 0.0 : (pos - neg) / (pos + neg)
    return Dict{String, Any}("n" => length(ref), "max_abs" => max_abs,
        "max_rel_above_abs_floor" => max_rel, "pos_residuals" => pos,
        "neg_residuals" => neg, "signed_bias_fraction" => signed)
end

function g1_load_sw_reference(path, fails)
    ref = Dict{String, Any}()
    NCDatasets.NCDataset(path) do ds
        for (n, want) in (("spectral_flux_dn_direct_sw",
                           ["g_point", "half_level", "column"]),
                          ("optical_depth", ["g_point", "level", "column"]),
                          ("rayleigh_optical_depth", ["g_point", "level", "column"]),
                          ("incoming_sw", ["g_point", "column"]),
                          ("flux_dn_direct_sw", ["half_level", "column"]))
            v = ds[n]
            dn = collect(String.(NCDatasets.dimnames(v)))
            dn == want ||
                push!(fails, "orientation: SW $n dims $(dn) != $(want)")
            ref[n] = Float64.(Array(v))
        end
    end
    return ref
end

function main()
    fails = String[]
    timings = Dict{String, Float64}()

    lw32 = NumericalRadiation.official_ecckd_definition_path(:longwave_32)
    conc_path = "/shared/home/greg/data/ckdmip/evaluation1/conc/" *
                "ckdmip_evaluation1_concentrations_present.nc"

    local ref, conc, defn
    timings["load_seconds"] = @elapsed begin
        ref = g1_load_reference(G1_REFERENCE_NC, fails)
        conc = g1_load_concentrations(conc_path, fails)
        defn = g1_load_definition(lw32, fails)
    end
    orientation_ok = isempty(fails)

    gas_stats = Dict{String, Any}()
    gates = Dict{String, String}()
    timings["od_parity_seconds"] = @elapsed begin
        ncol = size(ref["pressure_hl"], 2)
        for gas in ("composite", "h2o", "o3", "co2", "ch4", "n2o", "cfc11", "cfc12")
            haskey(defn, gas) || continue
            refod = ref[gas]                       # (g, lay, col)
            ng, nlay, _ = size(refod)
            ours = zeros(ng, nlay, ncol)
            for c in 1:ncol
                grid = g1_column_grid(view(ref["pressure_hl"], :, c),
                                      view(conc["temperature_hl"], :, c))
                vmr = gas == "composite" ? Float64[] : view(conc[gas], :, c)
                g1_gas_od!(view(ours, :, :, c), defn, gas, grid,
                           gas == "composite" ? zeros(nlay) : vmr)
            end
            st = g1_parity_stats(ours, refod)
            gas_stats[gas] = st
            pass = (st["max_abs"] <= G1_OD_ABS_TOL) ||
                   (st["max_rel_above_abs_floor"] <= G1_OD_REL_TOL)
            bias_ok = abs(st["signed_bias_fraction"]) < 0.9 ||
                      st["max_abs"] <= G1_OD_ABS_TOL
            gates["od_$(gas)"] = pass && bias_ok ? "passed" : "failed"
            pass || push!(fails,
                "od parity $gas: max_abs=$(st["max_abs"]) " *
                "max_rel=$(st["max_rel_above_abs_floor"])")
            bias_ok || push!(fails,
                "od parity $gas signed bias: $(st["signed_bias_fraction"])")
        end
    end

    # --- increment 2: LW flux parity (RT isolation) ------------------------------
    # Input: run_ckd's emitted total optical_depth (already clamped upstream via
    # od = max(od, 0)); reference planck_hl/planck_surf; surf_emissivity = 1.0.
    flux_stats = Dict{String, Any}()
    timings["flux_parity_seconds"] = @elapsed begin
        od = ref["optical_depth"]
        ng, nlay, ncol = size(od)
        sp_dn = zeros(ng, nlay + 1, ncol)
        sp_up = zeros(ng, nlay + 1, ncol)
        for c in 1:ncol, g in 1:ng
            r = g4_lw_fluxes(view(od, g, :, c), view(ref["planck_hl"], g, :, c),
                             ref["planck_surf"][g, c], 1.0)
            sp_dn[g, :, c] = r.flux_dn
            sp_up[g, :, c] = r.flux_up
        end
        for (name, ours, target) in (
                ("spectral_flux_dn_lw", sp_dn, ref["spectral_flux_dn_lw"]),
                ("spectral_flux_up_lw", sp_up, ref["spectral_flux_up_lw"]),
                ("flux_dn_lw", dropdims(sum(sp_dn; dims = 1); dims = 1),
                 ref["flux_dn_lw"]),
                ("flux_up_lw", dropdims(sum(sp_up; dims = 1); dims = 1),
                 ref["flux_up_lw"]))
            st = g1_parity_stats_flux(ours, target)
            flux_stats[name] = st
            pass = st["max_abs"] <= 1e-3 || st["max_rel_above_abs_floor"] <= 1e-6
            bias_ok = abs(st["signed_bias_fraction"]) < 0.9 || st["max_abs"] <= 1e-9
            gates["flux_$(name)"] = pass && bias_ok ? "passed" : "failed"
            pass || push!(fails, "flux parity $name: max_abs=$(st["max_abs"]) " *
                                 "max_rel=$(st["max_rel_above_abs_floor"])")
            bias_ok || push!(fails,
                "flux parity $name signed bias: $(st["signed_bias_fraction"])")
        end
        # derived heating cross-check (NO external heating target in the
        # reference file: this compares heating computed from ref fluxes vs
        # from our fluxes, both via the item-12 LW net-flux convention)
        bb_dn_ours = dropdims(sum(sp_dn; dims = 1); dims = 1)
        bb_up_ours = dropdims(sum(sp_up; dims = 1); dims = 1)
        max_rel_hr = 0.0
        for c in 1:ncol
            hr_ref = g4_heating_rate(view(ref["pressure_hl"], :, c),
                                     view(ref["flux_dn_lw"], :, c),
                                     view(ref["flux_up_lw"], :, c))
            hr_ours = g4_heating_rate(view(ref["pressure_hl"], :, c),
                                      view(bb_dn_ours, :, c),
                                      view(bb_up_ours, :, c))
            p_hl_c = view(ref["pressure_hl"], :, c)
            for l in 1:nlay
                ad = abs(hr_ref[l] - hr_ours[l])
                # propagated Float32-storage bound: the reference NetCDF stores
                # fluxes in Float32, so heating inherits ~(g/cp)/dp * 4*eps32*F
                # of quantization noise; differences inside that bound carry no
                # information about RT parity.
                fscale = max(abs(ref["flux_dn_lw"][l, c]),
                             abs(ref["flux_dn_lw"][l+1, c]),
                             abs(ref["flux_up_lw"][l, c]),
                             abs(ref["flux_up_lw"][l+1, c]), 1.0)
                bound = (9.80665 / 1004.0) / (p_hl_c[l+1] - p_hl_c[l]) *
                        4 * eps(Float32) * fscale + 1e-12
                ad <= bound && continue
                denom = max(abs(hr_ref[l]), abs(hr_ours[l]), 1e-300)
                max_rel_hr = max(max_rel_hr, ad / denom)
            end
        end
        flux_stats["derived_heating_max_rel"] = max_rel_hr
        gates["heating_derived_crosscheck"] = max_rel_hr <= 1e-5 ?
            "passed" : "failed"
        max_rel_hr <= 1e-5 ||
            push!(fails, "derived heating cross-check max rel $max_rel_hr")
    end

    # --- increment 3: SW DIRECT-DOWN parity (target-split: the ONLY external
    # SW target; upwelling/heating/objective parity stay against the
    # cost-function recurrences + G0 fixtures; never 4-angle products) --------
    sw_stats = Dict{String, Any}()
    timings["sw_direct_parity_seconds"] = @elapsed begin
        swref = g1_load_sw_reference(G1_SW_REFERENCE_NC, fails)
        odsw = swref["optical_depth"] .+ swref["rayleigh_optical_depth"]
        ngsw, nlaysw, ncolsw = size(odsw)
        sp = zeros(ngsw, nlaysw + 1, ncolsw)
        for c in 1:ncolsw, g in 1:ngsw
            sp[g, :, c] = g4_sw_direct(view(odsw, g, :, c),
                                       G1_SW_REFERENCE_COS_SZA,
                                       swref["incoming_sw"][g, c])
        end
        # explicit TOA scaling assertion (reviewer): g4_sw_direct applies
        # cos_sza internally (flux_dn[1] = cos_sza*ssi), and incoming_sw is the
        # per-g SSI run_ckd used — so ours[g,1,c] must equal the reference TOA
        # row to storage precision; any factor-2/half error fails HERE, not in
        # downstream residual interpretation.
        toa_max = maximum(abs.(sp[:, 1, :] .-
                               swref["spectral_flux_dn_direct_sw"][:, 1, :]))
        sw_stats["toa_scaling_max_abs"] = toa_max
        gates["sw_toa_scaling_check"] = toa_max <= 1e-4 ? "passed" : "failed"
        toa_max <= 1e-4 ||
            push!(fails, "SW TOA scaling check failed: max_abs=$toa_max " *
                         "(cos_sza/ssi double- or un-scaling suspected)")
        for (name, ours, target) in (
                ("spectral_flux_dn_direct_sw", sp,
                 swref["spectral_flux_dn_direct_sw"]),
                ("flux_dn_direct_sw", dropdims(sum(sp; dims = 1); dims = 1),
                 swref["flux_dn_direct_sw"]))
            st = g1_parity_stats_flux(ours, target)
            sw_stats[name] = st
            pass = st["max_abs"] <= 1e-3 || st["max_rel_above_abs_floor"] <= 1e-6
            bias_ok = abs(st["signed_bias_fraction"]) < 0.9 || st["max_abs"] <= 1e-9
            gates["sw_direct_$(name)"] = pass && bias_ok ? "passed" : "failed"
            pass || push!(fails, "SW direct parity $name: " *
                "max_abs=$(st["max_abs"]) max_rel=$(st["max_rel_above_abs_floor"])")
            bias_ok || push!(fails,
                "SW direct parity $name signed bias: $(st["signed_bias_fraction"])")
        end
    end

    status = isempty(fails) ? "g1_od_lw_flux_and_sw_direct_parity_passed" :
                              "g1_parity_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_forward_map_g1",
        "increment" => "1_od_2_lw_flux_3_sw_direct_parity",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates,
        "failures" => fails,
        "gas_stats" => gas_stats,
        "flux_stats" => flux_stats,
        "sw_direct_stats" => sw_stats,
        "orientation_check" => orientation_ok ? "passed" : "failed",
        "thresholds" => Dict("od_abs" => G1_OD_ABS_TOL, "od_rel" => G1_OD_REL_TOL),
        "timings_seconds" => timings,
        "maxrss_bytes" => Int(Sys.maxrss()),
        "provenance" => Dict(
            "branch" => branch, "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit",
            "reference_nc" => G1_REFERENCE_NC,
            "sw_reference_nc" => G1_SW_REFERENCE_NC,
            "sw32_path_authority" => "resolved via " *
                "NumericalRadiation.official_ecckd_definition_path(:shortwave_32) " *
                "-> ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc (the repo " *
                "API is the authoritative published SW32; no 1.0-versioned " *
                "SW rgb file exists in the pinned ecrad_data artifact)",
            "sw_reference_command" => "run_ckd ckd_model=<SW32 published " *
                "ecckd-1.4_sw_climate_rgb-32b> input=<evaluation1 present " *
                "conc> gases=composite,h2o,o3,co2,ch4,n2o tsi=1361.0 " *
                "(direct SW at REFERENCE_COS_SZA=0.5, OD + Rayleigh)",
            "reference_tool" => "pinned run_ckd (ecckd source artifact " *
                "6115f9b8, May-2026 build in ecckd-derived-flux-work)",
            "reference_command" => "run_ckd ckd_model=<LW32 published> " *
                "input=<evaluation1 present conc> output=<smoke nc> " *
                "gases='composite h2o o3 co2 ch4 n2o cfc11 cfc12'",
            "ckd_definition" => basename(lw32),
            "concentrations" => basename(conc_path),
            "sw_target_policy" => "G1 external SW parity COMPLETE for the " *
                "direct-down mu0=0.5 component (the only external SW target); " *
                "SW upwelling/heating/objective checks remain against the " *
                "cost-function recurrences and internal analytic fixtures; " *
                "*_fluxes-4angle_*/ckdmip_sw products are NEVER G1 targets",
        ),
        "disclaimer" => "term-resolved OD, LW flux/derived-heating, and SW " *
                        "direct-down parity; no objective-value, floor, or " *
                        "recovery claims.",
    )

    mkpath(dirname(G1_RESULTS_JSON))
    open(G1_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(G1_RESULTS_MD, "w") do io
        println(io, "# Gate-4 forward map G1 (increments 1-3: OD + LW flux + SW direct parity)\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gas | max_abs | max_rel (above abs floor) | signed bias | gate |")
        println(io, "|---|---|---|---|---|")
        for gas in sort(collect(keys(gas_stats)))
            st = gas_stats[gas]
            println(io, "| $gas | $(st["max_abs"]) | " *
                        "$(st["max_rel_above_abs_floor"]) | " *
                        "$(st["signed_bias_fraction"]) | $(gates["od_$gas"]) |")
        end
        println(io, "\n## LW flux parity (RT driven by reference OD + Planck)\n")
        println(io, "| Term | max_abs (W m^-2) | max_rel (above 1e-9 floor) | signed bias | gate |")
        println(io, "|---|---|---|---|---|")
        for name in ("spectral_flux_dn_lw", "spectral_flux_up_lw",
                     "flux_dn_lw", "flux_up_lw")
            st = flux_stats[name]
            println(io, "| $name | $(st["max_abs"]) | " *
                        "$(st["max_rel_above_abs_floor"]) | " *
                        "$(st["signed_bias_fraction"]) | $(gates["flux_$name"]) |")
        end
        println(io, "\nDerived-heating cross-check (both sides via the LW " *
                    "net-flux convention; NO external heating target exists " *
                    "in the reference): max rel above the propagated " *
                    "Float32-storage bound (g/cp)/dp*4*eps32*F = " *
                    "$(flux_stats["derived_heating_max_rel"]) " *
                    "(gate $(gates["heating_derived_crosscheck"])). " *
                    "Flux thresholds: abs <= 1e-3 W m^-2 or rel <= 1e-6, " *
                    "plus signed-bias check.")
        println(io, "\n## SW direct-down parity (the only external SW target)\n")
        println(io, "| Term | max_abs (W m^-2) | max_rel (above 1e-9 floor) | signed bias | gate |")
        println(io, "|---|---|---|---|---|")
        for name in ("spectral_flux_dn_direct_sw", "flux_dn_direct_sw")
            st = sw_stats[name]
            println(io, "| $name | $(st["max_abs"]) | " *
                        "$(st["max_rel_above_abs_floor"]) | " *
                        "$(st["signed_bias_fraction"]) | " *
                        "$(gates["sw_direct_$name"]) |")
        end
        println(io, "\nTOA scaling gate (cos_sza/ssi handling asserted in " *
                    "code): max_abs = $(sw_stats["toa_scaling_max_abs"]) " *
                    "($(gates["sw_toa_scaling_check"])). SW upwelling/heating/" *
                    "objective checks remain recurrence/internal-fixture " *
                    "based; 4-angle products are never targets.")
        println(io, "\nProvenance: branch `$branch`, generated_from_head `$head` " *
                    "(pre-own-commit); reference: pinned run_ckd smoke output.")
        if !isempty(fails)
            println(io, "\n## Failures\n")
            foreach(f -> println(io, "- ", f), fails)
        end
    end

    println("gate4_forward_map_g1 increment 1: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), first(fails, 12))
    return status == "g1_od_lw_flux_and_sw_direct_parity_passed" ? 0 : 1
end

exit(main())
