# gate4_x1_sidecar_validator.jl -- shared validation core for the
# Gate-4 X1 direct-capture instrument: sidecar structural gates, the
# Axis-C Float32 positional readback, and the all-variable logical
# identity gate. This ONE file is used BOTH by the checkpoint
# generator's fixtures and in-job (probe + X1 arm), so the fixtures
# exercise exactly the code the job runs. Pure functions return
# issue-lists; empty == pass. Fail-closed: anything missing,
# unreadable, or unexpected is an issue, never a skip.
#
# Frozen X1 design: d4f8a689aa4fcadb91922120b7806939bba88c115fb6281d
# 51b2fc3dbe325398. Vocabulary notes: value comparisons on NetCDF
# content are LOGICAL (decoded dims/attrs/values); literal on-disk
# encoding/layout is not examined here. A validation failure is an
# INSTRUMENT REFUSAL, never a scientific finding.

using NCDatasets

const X1V_CONTRACT = "gate4-x1-sidecar-v1"
const X1V_CAPTURE_LOCATION = "solve_adept.cpp is_bounded post-minimize"
const X1V_MIN_X_LOG_FLOOR = -1.0e20

# Pinned Adept minimizer status table, source-observed from the
# AUTHORITATIVE INSTALLED source (monitor ruling):
# /shared/home/greg/local/adept-2-install/include/adept_source.h
# lines 464-499, sha256
# 8f29a64a2d8227e881a7a541e154d80b752f7746c8607f6a9f280b54f0312351
# (MinimizerStatus enum: installed Minimizer.h lines 27-38, sha256
# dad747936a66304266d0dd31990afa3a7534c589ac6b7a9230eaafbe671a1f8d).
# The default branch, including enum sentinel 9
# (MINIMIZER_STATUS_NUMBER_AVAILABLE), returns "Status unrecognized";
# it is NOT pinned and any unpinned code is a refusal.
const X1V_STATUS_TABLE = Dict{Int, String}(
    0 => "Converged",
    1 => "Empty state vector, no minimization performed",
    2 => "Maximum iterations reached",
    3 => "Failed to converge",
    4 => "Search direction points uphill",
    5 => "Bound reached",
    6 => "Non-finite cost function",
    7 => "Non-finite gradient",
    8 => "Invalid bounds for bounded minimization",
    10 => "Minimization still in progress")
# This experiment accepts ONLY these terminal statuses; anything else
# (failed to converge, non-finite cost/gradient, invalid bounds, ...)
# is a refusal even when a raw2 output exists.
const X1V_ALLOWED_STATUS = Dict{Int, String}(
    0 => "Converged",
    2 => "Maximum iterations reached")

# LW relative-base expectation (binding): active-gas concatenation
# order composite, h2o, o3, co2 with block offsets 0 / 10,176 /
# 132,288 / 142,464 and total 152,640 == the committed census active
# count. Any deviation observed in a real sidecar is instrument
# refusal.
const X1V_LW_EXPECT = (
    nrows = 152640,
    gas_names = ["composite", "h2o", "o3", "co2"],
    offsets = [0, 10176, 132288, 142464],
    sizes = [10176, 122112, 10176, 10176],
    nconc = [-1, 12, -1, -1],
    nt = [6, 6, 6, 6],
    np = [53, 53, 53, 53],
    ng = [32, 32, 32, 32])

# exact-set variable census: name => (stored eltype, dims)
const X1V_VARS = Dict{String, Tuple{DataType, Tuple{Vararg{String}}}}(
    "global_x_index" => (Int32, ("x_index",)),
    "gas_id" => (Int32, ("x_index",)),
    "gas_offset" => (Int32, ("x_index",)),
    "iconc" => (Int32, ("x_index",)),
    "itemp" => (Int32, ("x_index",)),
    "ipress" => (Int32, ("x_index",)),
    "igpoint" => (Int32, ("x_index",)),
    "lower_class" => (Int32, ("x_index",)),
    "upper_active" => (Int32, ("x_index",)),
    "returned_x_log" => (Float64, ("x_index",)),
    "bound_lo_log" => (Float64, ("x_index",)),
    "bound_hi_log" => (Float64, ("x_index",)),
    "mapped_x_phys" => (Float64, ("x_index",)),
    "caller_phys" => (Float64, ("x_index",)),
    "caller_phys_f32" => (Float32, ("x_index",)),
    "gas_block_offset" => (Int32, ("active_gas",)),
    "gas_block_size" => (Int32, ("active_gas",)),
    "gas_block_nconc" => (Int32, ("active_gas",)),
    "gas_block_ntemperature" => (Int32, ("active_gas",)),
    "gas_block_npressure" => (Int32, ("active_gas",)),
    "gas_block_ng_point" => (Int32, ("active_gas",)),
    "minimizer_status" => (Int32, ()),
    "min_x_log_floor" => (Float64, ()))

const X1V_GLOBAL_ATTRS = sort(["arm", "capture_location", "contract",
    "gas_names", "index_base", "job_id", "minimizer_status_string"])

# Structural + content gates on one sidecar file. `arm` (when given)
# must match the sidecar's arm attribute exactly; `expected_status`
# (when given, e.g. the exact string extracted from the arm's run log)
# must match the sidecar's minimizer_status_string attribute exactly.
function x1v_sidecar_issues(path; expect = X1V_LW_EXPECT, arm = nothing,
                            expected_status = nothing)
    iss = String[]
    isfile(path) ||
        return ["sidecar missing (fail closed, never a skip): $path"]
    endswith(path, ".nc") ||
        push!(iss, "sidecar name violates the .nc naming rule: $path")
    filesize(path) > 0 || return vcat(iss, ["sidecar file is empty: $path"])
    # non-atomic / partial capture remnant scan (same directory)
    for f in sort(readdir(dirname(abspath(path))))
        startswith(f, ".x1-capture.") &&
            push!(iss, "non-atomic/partial capture remnant present: $f")
    end
    ds = try
        NCDataset(path)
    catch
        return vcat(iss, ["sidecar unreadable as NetCDF: $path"])
    end
    try
        nblk = length(expect.gas_names)
        dn = sort(collect(keys(ds.dim)))
        dn == ["active_gas", "x_index"] ||
            push!(iss, "dimension census != [active_gas, x_index]: $dn")
        haskey(ds.dim, "x_index") && ds.dim["x_index"] != expect.nrows &&
            push!(iss, "x_index dim $(ds.dim["x_index"]) != $(expect.nrows)")
        haskey(ds.dim, "active_gas") && ds.dim["active_gas"] != nblk &&
            push!(iss, "active_gas dim $(ds.dim["active_gas"]) != $nblk")
        ul = try
            sort(collect(unlimited(ds.dim)))
        catch
            nothing
        end
        ul === nothing &&
            push!(iss, "unlimited-dimension introspection failed (fail closed)")
        ul !== nothing && !isempty(ul) &&
            push!(iss, "unexpected unlimited dimension(s): $ul")
        have = sort([String(k) for k in keys(ds)])
        expect_vars = sort(collect(keys(X1V_VARS)))
        for v in setdiff(expect_vars, have)
            push!(iss, "var missing: $v")
        end
        for v in setdiff(have, expect_vars)
            push!(iss, "unexpected extra var: $v")
        end
        for v in intersect(expect_vars, have)
            et, edims = X1V_VARS[v]
            st = eltype(ds[v].var)
            st == et || push!(iss, "var $v stored type $st != $et")
            Tuple(dimnames(ds[v])) == edims ||
                push!(iss, "var $v dims $(Tuple(dimnames(ds[v]))) != $edims")
        end
        # structural failures make positional content reads unsafe
        isempty(iss) || return iss

        gat = sort([String(k) for k in keys(ds.attrib)])
        gat == X1V_GLOBAL_ATTRS ||
            push!(iss, "global attribute set $gat != $X1V_GLOBAL_ATTRS")
        att(name) = haskey(ds.attrib, name) ? ds.attrib[name] : nothing
        att("contract") == X1V_CONTRACT ||
            push!(iss, "contract attr $(repr(att("contract"))) != $(repr(X1V_CONTRACT))")
        att("capture_location") == X1V_CAPTURE_LOCATION ||
            push!(iss, "capture_location attr mismatch: $(repr(att("capture_location")))")
        att("gas_names") == join(expect.gas_names, " ") ||
            push!(iss, "gas_names attr $(repr(att("gas_names"))) != $(repr(join(expect.gas_names, " ")))")
        ib = att("index_base")
        (ib isa Integer && ib == 0) ||
            push!(iss, "index_base attr is not numeric zero: $(repr(ib))")
        if arm !== nothing
            att("arm") == arm ||
                push!(iss, "arm attr $(repr(att("arm"))) != expected $(repr(arm))")
        end
        jid = att("job_id")
        (jid isa AbstractString && occursin(r"^[0-9]+$", jid)) ||
            push!(iss, "job_id attr is not a positive integer string: $(repr(jid))")
        mss = att("minimizer_status_string")
        (mss isa AbstractString && !isempty(strip(mss))) ||
            push!(iss, "minimizer_status_string attr empty/missing")

        gx = Array(ds["global_x_index"])
        gx == collect(Int32, 0:(expect.nrows - 1)) ||
            push!(iss, "global_x_index != 0:$(expect.nrows - 1) (zero-based)")
        boff = Array(ds["gas_block_offset"])
        bsize = Array(ds["gas_block_size"])
        boff == expect.offsets ||
            push!(iss, "gas_block_offset $boff != $(expect.offsets) (active read order violated)")
        bsize == expect.sizes ||
            push!(iss, "gas_block_size $bsize != $(expect.sizes)")
        Array(ds["gas_block_nconc"]) == expect.nconc ||
            push!(iss, "gas_block_nconc != $(expect.nconc)")
        Array(ds["gas_block_ntemperature"]) == expect.nt ||
            push!(iss, "gas_block_ntemperature != $(expect.nt)")
        Array(ds["gas_block_npressure"]) == expect.np ||
            push!(iss, "gas_block_npressure != $(expect.np)")
        Array(ds["gas_block_ng_point"]) == expect.ng ||
            push!(iss, "gas_block_ng_point != $(expect.ng)")
        sum(bsize) == expect.nrows ||
            push!(iss, "sum(gas_block_size) $(sum(bsize)) != $(expect.nrows)")
        boff == vcat(0, cumsum(bsize)[1:end - 1]) ||
            push!(iss, "gas_block_offset is not the cumulative block layout")

        gid = Array(ds["gas_id"])
        goff = Array(ds["gas_offset"])
        ic = Array(ds["iconc"])
        it = Array(ds["itemp"])
        ip = Array(ds["ipress"])
        ig = Array(ds["igpoint"])
        for k in 1:nblk
            gas = expect.gas_names[k]
            r = (expect.offsets[k] + 1):(expect.offsets[k] + expect.sizes[k])
            all(==(k - 1), view(gid, r)) ||
                push!(iss, "gas_id rows for $gas are not uniformly $(k - 1)")
            all(==(expect.offsets[k]), view(goff, r)) ||
                push!(iss, "gas_offset rows for $gas are not uniformly $(expect.offsets[k])")
            nc = expect.nconc[k]
            ntk, npk, ngk = expect.nt[k], expect.np[k], expect.ng[k]
            if nc == -1
                all(==(-1), view(ic, r)) ||
                    push!(iss, "iconc for 3-D gas $gas is not uniformly -1")
            else
                all(x -> 0 <= x < nc, view(ic, r)) ||
                    push!(iss, "iconc out of range for $gas")
            end
            all(x -> 0 <= x < ntk, view(it, r)) ||
                push!(iss, "itemp out of range for $gas")
            all(x -> 0 <= x < npk, view(ip, r)) ||
                push!(iss, "ipress out of range for $gas")
            all(x -> 0 <= x < ngk, view(ig, r)) ||
                push!(iss, "igpoint out of range for $gas")
            codes = Set{Int64}()
            dup = 0
            for i in r
                c = ((Int64(nc == -1 ? 0 : ic[i]) * ntk + Int64(it[i])) *
                     npk + Int64(ip[i])) * ngk + Int64(ig[i])
                c in codes ? (dup += 1) : push!(codes, c)
            end
            dup == 0 ||
                push!(iss, "duplicate multi-index within gas $gas ($dup rows; mapping not bijective)")
        end

        lc = Array(ds["lower_class"])
        ua = Array(ds["upper_active"])
        all(x -> x in (0, 1, 2), lc) ||
            push!(iss, "lower_class values outside {0,1,2}")
        all(x -> x in (0, 1), ua) ||
            push!(iss, "upper_active values outside {0,1}")

        ret = Array(ds["returned_x_log"])
        all(isfinite, ret) || push!(iss, "nonfinite returned_x_log values")
        lo = Array(ds["bound_lo_log"])
        hi = Array(ds["bound_hi_log"])
        any(isnan, lo) &&
            push!(iss, "NaN in bound_lo_log (sentinel substitution or corruption; exact passed vectors required)")
        any(isnan, hi) &&
            push!(iss, "NaN in bound_hi_log (sentinel substitution or corruption; exact passed vectors required)")
        FMAX = floatmax(Float64)
        nbad_lo = count(i -> lc[i] == 0 ? lo[i] != -FMAX : !isfinite(lo[i]),
                        eachindex(lo))
        nbad_lo == 0 ||
            push!(iss, "bound_lo_log not preserved verbatim at $nbad_lo rows " *
                "(inactive rows must hold the exact -floatmax initialization " *
                "from minimizer_initialize_bounds; active rows must be finite)")
        nbad_hi = count(i -> ua[i] == 0 ? hi[i] != FMAX : !isfinite(hi[i]),
                        eachindex(hi))
        nbad_hi == 0 ||
            push!(iss, "bound_hi_log not preserved verbatim at $nbad_hi rows " *
                "(inactive rows must hold the exact +floatmax initialization)")

        mfl = Array(ds["min_x_log_floor"])[]
        mfl == X1V_MIN_X_LOG_FLOOR ||
            push!(iss, "min_x_log_floor $mfl != $X1V_MIN_X_LOG_FLOOR")
        status = Int(Array(ds["minimizer_status"])[])
        if !haskey(X1V_STATUS_TABLE, status)
            push!(iss, "minimizer_status $status is not a pinned Adept status code")
        elseif mss isa AbstractString && mss != X1V_STATUS_TABLE[status]
            push!(iss, "minimizer_status_string $(repr(mss)) != pinned " *
                "Adept table entry $(repr(X1V_STATUS_TABLE[status])) " *
                "for code $status (exact code/string consistency required)")
        end
        haskey(X1V_ALLOWED_STATUS, status) ||
            push!(iss, "minimizer_status $status outside the " *
                "experiment-allowed set {0 => Converged, 2 => Maximum " *
                "iterations reached}; error/non-converged terminals are " *
                "refusals even when raw2 exists")
        if expected_status !== nothing && mss isa AbstractString
            mss == expected_status ||
                push!(iss, "sidecar minimizer_status_string $(repr(mss)) " *
                    "!= the arm's log-extracted status $(repr(expected_status))")
        end

        ph = Array(ds["caller_phys"])
        f32 = Array(ds["caller_phys_f32"])
        mp = Array(ds["mapped_x_phys"])
        all(isfinite, ph) || push!(iss, "nonfinite caller_phys values")
        all(isfinite, f32) || push!(iss, "nonfinite caller_phys_f32 values")
        all(isfinite, mp) || push!(iss, "nonfinite mapped_x_phys values")
        # bit-exact IEEE round-to-nearest-even projection gate
        nbad_prj = count(i -> f32[i] !== Float32(ph[i]), eachindex(ph))
        nbad_prj == 0 ||
            push!(iss, "caller_phys_f32 != Float32(caller_phys) at $nbad_prj rows (projection gate)")
        # exp/MIN_X-floor replication gate. The zero-floor branch is
        # exact; the exp branch allows 4 ulp for libm-vs-openlibm
        # implementation differences (instrument-integrity gate only;
        # Axis-B scoring is a ledger matter, never decided here).
        nbad_map = 0
        for i in eachindex(ret)
            okm = if ret[i] > mfl
                jm = exp(ret[i])
                (mp[i] == jm) || (isfinite(jm) && abs(mp[i] - jm) <= 4 * eps(jm))
            else
                mp[i] === 0.0
            end
            okm || (nbad_map += 1)
        end
        nbad_map == 0 ||
            push!(iss, "mapped_x_phys inconsistent with the exp/MIN_X-floor callback replication at $nbad_map rows")
        return iss
    finally
        close(ds)
    end
end

# Axis-C Float32 positional readback: raw2 coefficient values must
# EQUAL (bitwise, ===) the sidecar caller_phys_f32 rows under the
# runtime-derived per-index mapping. ANY mismatch in order,
# dimensions, or the expected Float32 projection is INSTRUMENT
# REFUSAL, never a finding.
function x1v_axis_c_issues(sidecar_path, raw2_path; expect = X1V_LW_EXPECT)
    iss = String[]
    isfile(sidecar_path) || push!(iss, "sidecar missing: $sidecar_path")
    isfile(raw2_path) || push!(iss, "raw2 missing: $raw2_path")
    isempty(iss) || return iss
    NCDataset(sidecar_path) do sd
        needed = ["caller_phys_f32", "iconc", "itemp", "ipress", "igpoint"]
        for v in needed
            haskey(sd, v) || push!(iss, "sidecar var missing: $v")
        end
        isempty(iss) || return iss
        f32 = Array(sd["caller_phys_f32"])
        ic = Array(sd["iconc"])
        it = Array(sd["itemp"])
        ip = Array(sd["ipress"])
        ig = Array(sd["igpoint"])
        length(f32) == expect.nrows ||
            push!(iss, "sidecar row count $(length(f32)) != $(expect.nrows)")
        isempty(iss) || return iss
        NCDataset(raw2_path) do rd
            for k in 1:length(expect.gas_names)
                gas = expect.gas_names[k]
                vname = gas * "_molar_absorption_coeff"
                haskey(rd, vname) ||
                    (push!(iss, "raw2 var missing: $vname"); continue)
                v = rd[vname]
                eltype(v.var) == Float32 ||
                    push!(iss, "raw2 $vname stored type $(eltype(v.var)) != Float32 (expected FLOAT projection)")
                nc = expect.nconc[k]
                want = nc == -1 ?
                    ("g_point", "pressure", "temperature") :
                    ("g_point", "pressure", "temperature", gas * "_mole_fraction")
                Tuple(dimnames(v)) == want ||
                    (push!(iss, "raw2 $vname dims $(Tuple(dimnames(v))) != $want"); continue)
                A = Array(v)
                any(ismissing, A) &&
                    (push!(iss, "raw2 $vname contains missing values"); continue)
                wantsz = nc == -1 ? (expect.ng[k], expect.np[k], expect.nt[k]) :
                    (expect.ng[k], expect.np[k], expect.nt[k], nc)
                size(A) == wantsz ||
                    (push!(iss, "raw2 $vname size $(size(A)) != $wantsz"); continue)
                nbad = 0
                for i in (expect.offsets[k] + 1):(expect.offsets[k] + expect.sizes[k])
                    val = nc == -1 ? A[ig[i] + 1, ip[i] + 1, it[i] + 1] :
                        A[ig[i] + 1, ip[i] + 1, it[i] + 1, ic[i] + 1]
                    val === f32[i] || (nbad += 1)
                end
                nbad == 0 ||
                    push!(iss, "Axis-C Float32 positional readback mismatch for $gas at $nbad of $(expect.sizes[k]) rows")
            end
        end
        return iss
    end
end

# All-variable logical identity gate between two NetCDF files:
# dimension census, per-variable dims/stored types/typed attributes/
# elementwise values (isequal), global attribute NAME-set equality,
# and global attribute VALUE equality outside `allowed_value_diff`
# (for raw2 arms only config/history may differ: they embed per-arm
# paths/command lines). Attribute TYPE equality is required even for
# allowed value differences. When `required_value_diffs` is given, the
# ACTUAL set of differing global attributes must EQUAL it exactly;
# when `expected_var_count` is given, each file must hold exactly that
# many variables (the full-arm raw2 call requires 47). Differences are
# reported as observed NetCDF LOGICAL differences.
function x1v_identity_issues(a_path, b_path;
                             allowed_value_diff = String[],
                             required_value_diffs = nothing,
                             expected_var_count = nothing,
                             required_global_attrs = nothing)
    iss = String[]
    isfile(a_path) || push!(iss, "file missing (A): $a_path")
    isfile(b_path) || push!(iss, "file missing (B): $b_path")
    isempty(iss) || return iss
    NCDataset(a_path) do da
        NCDataset(b_path) do db
            ka = sort(collect(keys(da.dim)))
            kb = sort(collect(keys(db.dim)))
            ka == kb ||
                push!(iss, "dimension name sets differ: $ka vs $kb")
            for d in intersect(ka, kb)
                da.dim[d] == db.dim[d] ||
                    push!(iss, "dim $d length differs: $(da.dim[d]) vs $(db.dim[d])")
            end
            ua = try
                sort(collect(unlimited(da.dim)))
            catch
                nothing
            end
            ub = try
                sort(collect(unlimited(db.dim)))
            catch
                nothing
            end
            (ua === nothing || ub === nothing) &&
                push!(iss, "unlimited-dimension introspection failed (fail closed)")
            ua !== nothing && ub !== nothing && ua != ub &&
                push!(iss, "unlimited dimension sets differ: $ua vs $ub")
            ga = sort([String(k) for k in keys(da.attrib)])
            gb = sort([String(k) for k in keys(db.attrib)])
            ga == gb ||
                push!(iss, "global attribute name sets differ: $ga vs $gb")
            if required_global_attrs !== nothing
                req = sort(String.(collect(required_global_attrs)))
                ga == req ||
                    push!(iss, "global attribute set $ga != required $req")
            end
            actual_diffs = String[]
            for at in intersect(ga, gb)
                va = da.attrib[at]
                vb = db.attrib[at]
                if typeof(va) != typeof(vb)
                    push!(iss, "global attribute $at differs IN TYPE " *
                        "($(typeof(va)) vs $(typeof(vb))); type equality " *
                        "is required even for allowed value differences")
                elseif !isequal(va, vb)
                    push!(actual_diffs, at)
                    at in allowed_value_diff ||
                        push!(iss, "global attribute $at differs (typed comparison) and is not in the allowed-difference set")
                end
            end
            if required_value_diffs !== nothing
                req = sort(String.(collect(required_value_diffs)))
                sort(actual_diffs) == req ||
                    push!(iss, "actual differing-global-attribute set " *
                        "$(sort(actual_diffs)) != required exact set $req")
            end
            va_names = sort([String(k) for k in keys(da)])
            vb_names = sort([String(k) for k in keys(db)])
            if expected_var_count !== nothing
                length(va_names) == expected_var_count ||
                    push!(iss, "variable count in A $(length(va_names)) != expected $expected_var_count")
                length(vb_names) == expected_var_count ||
                    push!(iss, "variable count in B $(length(vb_names)) != expected $expected_var_count")
            end
            for v in setdiff(va_names, vb_names)
                push!(iss, "var only in A: $v")
            end
            for v in setdiff(vb_names, va_names)
                push!(iss, "var only in B: $v")
            end
            for v in intersect(va_names, vb_names)
                xa = da[v]
                xb = db[v]
                if Tuple(dimnames(xa)) != Tuple(dimnames(xb))
                    push!(iss, "var $v dims differ")
                    continue
                end
                eltype(xa.var) == eltype(xb.var) ||
                    push!(iss, "var $v stored types differ: $(eltype(xa.var)) vs $(eltype(xb.var))")
                aa = sort([String(k) for k in keys(xa.attrib)])
                ab = sort([String(k) for k in keys(xb.attrib)])
                aa == ab ||
                    push!(iss, "var $v attribute name sets differ: $aa vs $ab")
                for at in intersect(aa, ab)
                    pa = xa.attrib[at]
                    pb = xb.attrib[at]
                    ((typeof(pa) == typeof(pb)) && isequal(pa, pb)) ||
                        push!(iss, "var $v attribute $at differs (typed comparison)")
                end
                Aa = try
                    Array(xa)
                catch
                    push!(iss, "var $v unreadable in A")
                    continue
                end
                Ab = try
                    Array(xb)
                catch
                    push!(iss, "var $v unreadable in B")
                    continue
                end
                if size(Aa) != size(Ab)
                    push!(iss, "var $v shapes differ")
                    continue
                end
                isequal(Aa, Ab) ||
                    push!(iss, "var $v values differ elementwise (observed NetCDF LOGICAL difference)")
            end
        end
    end
    iss
end

function x1v_main(args)
    usage = "usage: gate4_x1_sidecar_validator.jl sidecar <sidecar.nc> " *
        "<arm> <raw2.nc> [expected_status_string] | identity <a.nc> " *
        "<b.nc> [required_value_diff_csv] [expected_var_count]"
    isempty(args) && (println(usage); return 2)
    mode = args[1]
    iss = if mode == "sidecar" && length(args) in (4, 5)
        vcat(x1v_sidecar_issues(args[2]; arm = args[3],
                 expected_status = length(args) == 5 ? args[5] : nothing),
             x1v_axis_c_issues(args[2], args[4]))
    elseif mode == "identity" && length(args) in (3, 4, 5)
        # the CSV names both the ALLOWED and the REQUIRED exact set of
        # differing global attributes (the full-arm call passes
        # config,history 47)
        diffs = length(args) >= 4 ?
            String.(split(args[4], ","; keepempty = false)) : String[]
        nvar = length(args) == 5 ? tryparse(Int, args[5]) : nothing
        (length(args) == 5 && nvar === nothing) &&
            ((println(usage); return 2))
        x1v_identity_issues(args[2], args[3];
            allowed_value_diff = diffs,
            required_value_diffs = isempty(diffs) ? nothing : diffs,
            expected_var_count = nvar)
    else
        println(usage)
        return 2
    end
    if isempty(iss)
        println("X1 VALIDATOR PASSED ($mode)")
        return 0
    end
    for i in iss
        println("X1 VALIDATOR ISSUE: ", i)
    end
    println("X1 VALIDATOR REFUSED ($mode): $(length(iss)) issue(s)")
    return 1
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(x1v_main(ARGS))
end
