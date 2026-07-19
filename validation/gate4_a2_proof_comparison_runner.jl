# Gate-4 A2 PROOF COMPARISON runner (refuses until the proof raw
# definitions exist; read-only when it does run).
#
# Executes the 10 exact comparisons pinned by the reproduction-proof
# scaffold between the proof raw create_lut outputs (built from the 4082
# candidates) and the published LW32/SW32 definitions. Verdict rule (binding,
# from the scaffold): ALL exact -> candidates promotable to acceptance raw
# inits (subject to review); ANY mismatch -> candidates are SENSITIVITY-ONLY
# and the acceptance floor cannot use them without an explicit rule change
# from Greg.
#
# PROVENANCE GUARD (binding): path existence alone is NOT proof provenance.
# The exact comparisons below are valid evidence ONLY when the raw files
# were created by an explicitly authorized proof sbatch whose completion,
# log, and output hashes have been reviewed. Raw files of unreviewed origin
# are UNPROVEN: comparison results against them must not promote anything.
#
# This unit never runs create_lut, optimization, objective, floor, or
# recovery computation; it only READS NetCDF files once they exist.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON
using NCDatasets

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))
using NumericalRadiation

const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const LW_RAW = "$G4WORK/work/lw_raw-ckd-definition/ecckd-1.2_lw_raw-ckd-definition_climate_fsck-tol0.0161.nc"
const SW_RAW = "$G4WORK/work/sw_raw-ckd-definition/ecckd-1.2_sw_raw-ckd-definition_climate_rgb-tol0.047.nc"

const CR_RESULTS_JSON = validation_results_path("gate4_a2_proof_comparison_runner.json")
const CR_RESULTS_MD = validation_results_path("gate4_a2_proof_comparison_runner.md")

sha256(p) = split(strip(read(`sha256sum $p`, String)))[1]

function compare_var(raw, pub, name)
    haskey(raw, name) || return Dict("name" => name, "exact" => false,
        "detail" => "variable missing from proof raw definition")
    haskey(pub, name) || return Dict("name" => name, "exact" => false,
        "detail" => "variable missing from published definition")
    a = Array(raw[name][:]); b = Array(pub[name][:])
    size(a) == size(b) || return Dict("name" => name, "exact" => false,
        "detail" => "shape mismatch: raw $(size(a)) vs published $(size(b))")
    exact = all(isequal.(a, b))
    d = Dict{String, Any}("name" => name, "exact" => exact,
        "shape" => string(size(a)))
    if !exact && eltype(a) <: Number && eltype(b) <: Number
        diffs = abs.(Float64.(a) .- Float64.(b))
        d["max_abs_diff"] = maximum(diffs)
        d["n_mismatched"] = count(.!isequal.(a, b))
    end
    return d
end

function main()
    if !(isfile(LW_RAW) && isfile(SW_RAW))
        status = "proof_comparisons_waiting_for_raw_outputs"
        result = Dict(
            "case" => "gate4_a2_proof_comparison_runner",
            "data_mode" => "refusal_no_proof_outputs",
            "status" => status,
            "timestamp_utc" => string(Dates.now(Dates.UTC)),
            "missing" => filter(!isfile, [LW_RAW, SW_RAW]),
            "provenance_requirement" => "path existence alone is NOT proof " *
                "provenance: comparisons are valid only after an explicitly " *
                "authorized proof sbatch completion with log/hash review; " *
                "raw files of unreviewed origin are unproven and promote " *
                "nothing",
            "disclaimer" => "refuses until the proof raw definitions exist; " *
                "no create_lut, objective, floor, or recovery computation.",
        )
        mkpath(dirname(CR_RESULTS_JSON))
        open(CR_RESULTS_JSON, "w") do io
            JSON.print(io, result, 2)
        end
        open(CR_RESULTS_MD, "w") do io
            println(io, "# Gate-4 A2 proof comparisons\n")
            println(io, "Status: **$status**\n")
            println(io, result["disclaimer"], "\n")
            println(io, "**Provenance requirement**: ",
                    result["provenance_requirement"])
        end
        println("gate4_a2_proof_comparison_runner: $status")
        return 0
    end

    lw32 = NumericalRadiation.official_ecckd_definition_path(:longwave_32)
    sw32 = NumericalRadiation.official_ecckd_definition_path(:shortwave_32)

    raw_lw = NCDataset(LW_RAW); pub_lw = NCDataset(lw32)
    raw_sw = NCDataset(SW_RAW); pub_sw = NCDataset(sw32)

    comparisons = Any[]
    push!(comparisons, Dict("name" => "g_count", "band" => "lw",
        "exact" => raw_lw.dim["g_point"] == 32 && pub_lw.dim["g_point"] == 32,
        "detail" => "raw $(raw_lw.dim["g_point"]) vs published $(pub_lw.dim["g_point"]) (must both be 32)"))
    push!(comparisons, Dict("name" => "g_count", "band" => "sw",
        "exact" => raw_sw.dim["g_point"] == 32 && pub_sw.dim["g_point"] == 32,
        "detail" => "raw $(raw_sw.dim["g_point"]) vs published $(pub_sw.dim["g_point"]) (must both be 32)"))
    for name in ("gpoint_fraction", "wavenumber1_band", "wavenumber2_band",
                 "band_number", "wavenumber1", "wavenumber2")
        push!(comparisons, merge(compare_var(raw_lw, pub_lw, name),
                                 Dict("band" => "lw")))
        push!(comparisons, merge(compare_var(raw_sw, pub_sw, name),
                                 Dict("band" => "sw")))
    end
    for name in ("solar_irradiance", "rayleigh_molar_scattering_coeff",
                 "solar_spectral_irradiance")
        push!(comparisons, merge(compare_var(raw_sw, pub_sw, name),
                                 Dict("band" => "sw")))
    end
    close(raw_lw); close(pub_lw); close(raw_sw); close(pub_sw)

    all_exact = all(c -> c["exact"], comparisons)
    status = all_exact ? "proof_all_exact_candidates_promotable" :
                         "proof_mismatch_sensitivity_only"

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_a2_proof_comparison_runner",
        "data_mode" => "read_only_exact_comparisons",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "inputs" => Dict(
            "lw_raw" => Dict("path" => LW_RAW, "sha256" => sha256(LW_RAW)),
            "sw_raw" => Dict("path" => SW_RAW, "sha256" => sha256(SW_RAW)),
            "lw_published" => basename(lw32), "sw_published" => basename(sw32)),
        "comparisons" => comparisons,
        "provenance_requirement" => "path existence alone is NOT proof " *
            "provenance: these comparisons are valid evidence ONLY if the " *
            "raw inputs above were created by an explicitly authorized " *
            "proof sbatch whose completion, log, and output hashes have " *
            "been reviewed; otherwise the raw files are UNPROVEN and this " *
            "result promotes nothing",
        "verdict" => all_exact ?
            "ALL EXACT: candidates promotable to acceptance raw inits ONLY " *
            "after the provenance requirement above is satisfied (reviewed " *
            "authorized proof run) AND explicit go; init-generation may " *
            "then proceed" :
            "MISMATCH: candidates are SENSITIVITY-ONLY; the acceptance " *
            "floor cannot use them unless Greg explicitly changes the " *
            "optimizer-only-delta rule; record as finding (pre-registered " *
            "risk: ecckd version skew 1.0/1.4 published vs 1.2 rerun)",
        "provenance" => Dict("branch" => branch, "generated_from_head" => head),
        "disclaimer" => "read-only comparisons; no create_lut, objective, " *
                        "floor, or recovery computation.",
    )
    mkpath(dirname(CR_RESULTS_JSON))
    open(CR_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(CR_RESULTS_MD, "w") do io
        println(io, "# Gate-4 A2 proof comparisons\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "**Provenance requirement**: ",
                result["provenance_requirement"], "\n")
        println(io, "| Band | Comparison | Exact | Detail |")
        println(io, "|---|---|---|---|")
        for c in comparisons
            det = get(c, "detail", get(c, "shape", ""))
            extra = haskey(c, "max_abs_diff") ?
                " max_abs_diff=$(c["max_abs_diff"]) n=$(c["n_mismatched"])" : ""
            println(io, "| $(c["band"]) | $(c["name"]) | $(c["exact"]) | $det$extra |")
        end
        println(io, "\nVerdict: ", result["verdict"])
    end
    println("gate4_a2_proof_comparison_runner: $status")
    for c in comparisons
        println("  [$(c["band"])] $(c["name"]): $(c["exact"] ? "EXACT" : "MISMATCH")")
    end
    return 0
end

exit(main())
