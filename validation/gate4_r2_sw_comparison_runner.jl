# Gate-4 R2 SW COMPARISON runner (refuses until the v1.4 proof raw
# definition exists; read-only when it does run).
#
# The 8 SW checks from the R2 scaffold, headlined by
# solar_spectral_irradiance PRESENT + elementwise EXACT. Verdict rules per
# the scaffold: promotion is NEVER automatic regardless of outcome.
#
# PROVENANCE GUARD (binding, same as the 4091 runner): path existence alone
# is NOT proof provenance -- comparisons are valid evidence only after an
# explicitly authorized R2 sbatch completion with log/hash review.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON
using NCDatasets

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))
using NumericalRadiation

const G4WORK = "/shared/home/greg/ecckd-derived-flux-work/g4-init-generation"
const SW_RAW_V14 = "$G4WORK/work-v14/sw_raw-ckd-definition/ecckd-1.4_sw_raw-ckd-definition_climate_rgb-tol0.047.nc"

const RC_RESULTS_JSON = validation_results_path("gate4_r2_sw_comparison_runner.json")
const RC_RESULTS_MD = validation_results_path("gate4_r2_sw_comparison_runner.md")

sha256(p) = split(strip(read(`sha256sum $p`, String)))[1]

function compare_var(raw, pub, name)
    haskey(raw, name) || return Dict("name" => name, "exact" => false,
        "detail" => "variable missing from v1.4 proof raw definition")
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
    if !isfile(SW_RAW_V14)
        status = "r2_comparisons_waiting_for_v14_raw_output"
        result = Dict(
            "case" => "gate4_r2_sw_comparison_runner",
            "data_mode" => "refusal_no_v14_output",
            "status" => status,
            "timestamp_utc" => string(Dates.now(Dates.UTC)),
            "missing" => [SW_RAW_V14],
            "provenance_requirement" => "comparisons are valid only after " *
                "an explicitly authorized R2 sbatch completion with " *
                "log/hash review; raw files of unreviewed origin are " *
                "unproven and promote nothing",
            "disclaimer" => "refuses until the v1.4 proof raw definition " *
                "exists; no build, objective, floor, or promotion.",
        )
        mkpath(dirname(RC_RESULTS_JSON))
        open(RC_RESULTS_JSON, "w") do io
            JSON.print(io, result, 2)
        end
        open(RC_RESULTS_MD, "w") do io
            println(io, "# Gate-4 R2 SW comparisons\n")
            println(io, "Status: **$status**\n")
            println(io, result["disclaimer"], "\n")
            println(io, "**Provenance requirement**: ",
                    result["provenance_requirement"])
        end
        println("gate4_r2_sw_comparison_runner: $status")
        return 0
    end

    sw32 = NumericalRadiation.official_ecckd_definition_path(:shortwave_32)
    raw = NCDataset(SW_RAW_V14); pub = NCDataset(sw32)

    comparisons = Any[]
    push!(comparisons, Dict("name" => "g_count",
        "exact" => raw.dim["g_point"] == 32 && pub.dim["g_point"] == 32,
        "detail" => "raw $(raw.dim["g_point"]) vs published $(pub.dim["g_point"])"))
    for name in ("gpoint_fraction", "wavenumber1_band", "wavenumber2_band",
                 "band_number", "wavenumber1", "wavenumber2",
                 "solar_irradiance", "rayleigh_molar_scattering_coeff",
                 "solar_spectral_irradiance")
        push!(comparisons, compare_var(raw, pub, name))
    end
    close(raw); close(pub)

    ssi = only(filter(c -> c["name"] == "solar_spectral_irradiance", comparisons))
    ssi_present = !occursin("missing from v1.4", get(ssi, "detail", ""))
    all_exact = all(c -> c["exact"], comparisons)
    status = all_exact ? "r2_all_sw_fields_exact_promotion_pending_review" :
             ssi_present ? "r2_ssi_emitted_drift_remains" :
                           "r2_ssi_still_absent_mapping_hypothesis_wrong"

    verdict =
        all_exact ? "ALL SW fields exact at v1.4: SSI-absence finding " *
            "RESOLVED as version skew AND drift resolved. Promotion " *
            "remains NOT automatic -- pending Greg's rule decision and " *
            "the open LW-1.0 mapping ambiguity." :
        ssi_present ? "SSI absence RESOLVED as version skew (v1.4 emits " *
            "the variable) -- strong confirmation of R1. Remaining " *
            "mismatches join the unresolved-drift set (expected " *
            "possibility per the pre-registered outcome): attributed to " *
            "non-source factors (input data provenance, build config); " *
            "candidates remain sensitivity-only; feeds Greg's A/B " *
            "decision." :
        "SSI STILL ABSENT at v1.4: the R1 mapping hypothesis is WRONG " *
        "for this build path; escalate as a new finding before any " *
        "further use."

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    ghead = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end
    result = Dict(
        "case" => "gate4_r2_sw_comparison_runner",
        "data_mode" => "read_only_exact_comparisons",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "inputs" => Dict(
            "sw_raw_v14" => Dict("path" => SW_RAW_V14,
                                 "sha256" => sha256(SW_RAW_V14)),
            "sw_published" => basename(sw32)),
        "comparisons" => comparisons,
        "provenance_requirement" => "valid evidence ONLY if the raw input " *
            "above came from the authorized R2 sbatch (completion + " *
            "log/hash review); otherwise unproven, promotes nothing",
        "verdict" => verdict,
        "provenance" => Dict("branch" => branch, "generated_from_head" => ghead),
        "disclaimer" => "read-only comparisons; no build, objective, " *
                        "floor, or promotion.",
    )
    mkpath(dirname(RC_RESULTS_JSON))
    open(RC_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(RC_RESULTS_MD, "w") do io
        println(io, "# Gate-4 R2 SW comparisons (v1.4 build vs published SW32)\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "**Provenance requirement**: ",
                result["provenance_requirement"], "\n")
        println(io, "| Comparison | Exact | Detail |")
        println(io, "|---|---|---|")
        for c in comparisons
            det = get(c, "detail", get(c, "shape", ""))
            extra = haskey(c, "max_abs_diff") ?
                " max_abs_diff=$(c["max_abs_diff"]) n=$(c["n_mismatched"])" : ""
            println(io, "| $(c["name"]) | $(c["exact"]) | $det$extra |")
        end
        println(io, "\nVerdict: ", verdict)
    end
    println("gate4_r2_sw_comparison_runner: $status")
    for c in comparisons
        println("  $(c["name"]): $(c["exact"] ? "EXACT" : "MISMATCH")")
    end
    return 0
end

exit(main())
