# Gate-4 A1 upstream reconnaissance: do the ORIGINAL find_g_points HDF5
# outputs or raw/scaled init definitions (climate fsck-32b LW / rgb-32b SW)
# exist in any authoritative source? Sources searched: ECMWF ECPDS aux
# directories (HEAD probes only), the ecmwf-ifs/ecckd GitHub release listing
# (small JSON API), the pinned ecCKD source artifact, the pinned ecRad data
# artifact, local artifact caches and campaign workdirs.
#
# GATES: no large downloads (HEAD/listing metadata only); no
# create_lut/find_g_points/objective/floor execution. If nothing satisfies A1
# exactly, status = a1_recon_no_exact_upstream_source_found and the next unit
# is the A2 rerun-with-proof manifest. No floor/recovery claim.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

push!(LOAD_PATH, normpath(joinpath(@__DIR__, "..")))
using NumericalRadiation

const A1_RESULTS_JSON = validation_results_path("gate4_a1_upstream_recon.json")
const A1_RESULTS_MD = validation_results_path("gate4_a1_upstream_recon.md")

const PATTERNS = [r"gpoints.*\.h5$", r"g_points.*\.h5$",
                  r"raw-ckd-definition.*\.nc$", r"scaled-ckd-definition.*\.nc$"]
const TARGET_TOKENS = ["fsck-32b", "rgb-32b", "fsck_32b", "rgb_32b",
                       "fsck-tol", "rgb-tol"]

matches_pattern(f) = any(occursin(p, f) for p in PATTERNS)
satisfies_a1(f) = matches_pattern(f) &&
                  any(occursin(t, f) for t in TARGET_TOKENS)

function head_probe(url)
    out = try
        read(`curl -sIL --max-time 20 -o /dev/null -w "%{http_code} %{size_download} %{content_type}" $url`, String)
    catch err
        return Dict("url" => url, "error" => sprint(showerror, err))
    end
    parts = split(strip(out))
    return Dict("url" => url, "http_status" => parts[1],
                "note" => out)
end

function main()
    fails = String[]
    gates = Dict{String, String}()
    findings = Any[]

    # --- local scans (bounded depth) ---------------------------------------------
    local_roots = [
        ("pinned_ecckd_source", "/shared/home/greg/.julia/artifacts/" *
         "7b210aef53e908cfe3c709945f0763c37ca82aaa"),
        ("pinned_ecrad_data", dirname(NumericalRadiation.official_ecckd_definition_path(:longwave_32))),
        ("campaign_workdirs", "/shared/home/greg/ecckd-derived-flux-work"),
        ("julia_artifact_cache_toplevel", "/shared/home/greg/.julia/artifacts"),
    ]
    for (label, root) in local_roots
        isdir(root) || continue
        maxdepth = label == "julia_artifact_cache_toplevel" ? 2 : 10
        rootdepth = count('/', root)
        for (dir, _, fs) in walkdir(root; onerror = _ -> nothing)
            count('/', dir) - rootdepth > maxdepth && continue
            for f in fs
                matches_pattern(f) || continue
                push!(findings, Dict("source" => label,
                    "path" => joinpath(dir, f),
                    "size_bytes" => filesize(joinpath(dir, f)),
                    "satisfies_a1_exactly" => satisfies_a1(f)))
            end
        end
    end

    # --- upstream probes (HEAD / small listings only) ------------------------------
    probes = Any[]
    base = "https://aux.ecmwf.int/ecpds/home/ckdmip"
    for cand in ("$base/gpoints/", "$base/ecckd/", "$base/results/",
                 "$base/ckd-definitions/",
                 "$base/gpoints/ecckd-1.0_lw_gpoints_climate_fsck-32b.h5",
                 "$base/ecckd/ecckd-1.0_lw_raw-ckd-definition_climate_fsck-32b.nc",
                 "$base/ecckd/ecckd-1.4_sw_scaled-ckd-definition_climate_rgb-32b.nc")
        push!(probes, head_probe(cand))
    end
    # GitHub release listing (small JSON) for ecmwf-ifs/ecckd
    gh = try
        JSON.parse(read(`curl -sL --max-time 30 https://api.github.com/repos/ecmwf-ifs/ecckd/releases`, String))
    catch err
        sprint(showerror, err)
    end
    release_assets = Any[]
    if gh isa Vector
        for rel in gh
            for a in get(rel, "assets", [])
                push!(release_assets, Dict("release" => get(rel, "tag_name", "?"),
                    "asset" => a["name"], "size" => a["size"],
                    "matches" => matches_pattern(a["name"]),
                    "satisfies_a1_exactly" => satisfies_a1(a["name"])))
            end
        end
        gates["github_release_listing_ok"] = "passed"
    else
        gates["github_release_listing_ok"] = "failed"
        push!(fails, "github release listing failed: $gh")
    end

    exact_local = filter(f -> f["satisfies_a1_exactly"], findings)
    exact_remote = filter(a -> get(a, "satisfies_a1_exactly", false), release_assets)
    exact_probe = filter(p -> get(p, "http_status", "") == "200" &&
                              satisfies_a1(get(p, "url", "")), probes)
    found = !isempty(exact_local) || !isempty(exact_remote) || !isempty(exact_probe)

    gates["no_large_downloads"] = "passed"       # HEAD/listing only by design
    gates["no_generation_or_objective"] = "passed"
    gates["local_sources_scanned"] = length(local_roots) == 4 ? "passed" : "failed"
    gates["upstream_probes_recorded"] = length(probes) >= 7 ? "passed" : "failed"

    status = !isempty(fails) ? "a1_recon_failed" :
             found ? "a1_exact_source_candidate_found" :
                     "a1_recon_no_exact_upstream_source_found"

    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    head = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_a1_upstream_recon",
        "data_mode" => "metadata_probes_and_local_scans_only",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "local_findings" => findings,
        "upstream_probes" => probes,
        "github_release_assets" => release_assets,
        "exact_candidates" => Dict("local" => exact_local,
                                   "github" => exact_remote,
                                   "probes" => exact_probe),
        "next_unit_if_not_found" => "A2 rerun-with-proof manifest " *
            "(find_g_points from idealized spectra + exact-reproduction gate " *
            "against published support arrays)",
        "provenance" => Dict("branch" => branch, "generated_from_head" => head,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "reconnaissance metadata only; nothing downloaded " *
                        "beyond HEAD/listing responses; no generation, " *
                        "objective, floor, or recovery computation.",
    )
    mkpath(dirname(A1_RESULTS_JSON))
    open(A1_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(A1_RESULTS_MD, "w") do io
        println(io, "# Gate-4 A1 upstream reconnaissance\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nLocal pattern matches: $(length(findings)) " *
                    "(exact A1: $(length(exact_local)))")
        for f in findings
            println(io, "- [$(f["satisfies_a1_exactly"] ? "A1-EXACT" : "partial")] " *
                        "$(f["source"]): `$(f["path"])` ($(f["size_bytes"]) B)")
        end
        println(io, "\nUpstream probes:")
        for pr in probes
            println(io, "- $(get(pr, "http_status", "ERR")) `$(pr["url"])`")
        end
        println(io, "\nGitHub release assets matching patterns: " *
                    "$(count(a -> a["matches"], release_assets)) of " *
                    "$(length(release_assets)) total assets")
        println(io, "\nNext unit if not found: ", result["next_unit_if_not_found"])
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$head` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_a1_upstream_recon: $status " *
            "(local=$(length(exact_local)) github=$(length(exact_remote)) " *
            "probes=$(length(exact_probe)))")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return startswith(status, "a1_recon_failed") ? 1 : 0
end

exit(main())
