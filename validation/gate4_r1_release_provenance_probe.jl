# Gate-4 R1 RELEASE-PROVENANCE probe (read-only, A1-style: HEAD/listing/
# source-history metadata only; no large downloads, no builds, no Slurm, no
# rule change, no promotion).
#
# Question: is there an accessible ECPDS/ecRad/release-history source
# mapping for the published ecckd-1.0 (LW32) and ecckd-1.4 (SW32) files?
#
# ANSWER (established by the probes below):
#   ecckd-1.4 (SW): mapping FOUND (strong) -- commit 23adaca IS the v1.4
#     configure.ac bump (in-repo ChangeLog v1.4's only listed change is the
#     SSI save), and ecRad packaged the SW 1.4 file one week later with a
#     commit message naming that exact feature. Buildable from master
#     history.
#   ecckd-1.0 (LW): mapping AMBIGUOUS -- b42e5c0 is the v1.0 configure.ac
#     bump (2022-01-13; ChangeLog "version 1.0 (January 2022)"), but the
#     released LW file was already in ecRad by 2021-09-08, PREdating the
#     bump by ~4 months; the released file's builder source state is not
#     established by public history.
#
# REFINEMENT of V1 (two-part, per review):
#   STRONG: the SW solar_spectral_irradiance ABSENCE is accounted by v1.4
#     code (23adaca ckd_model.cpp persistence; ChangeLog v1.4).
#   CAUTIOUS: the small gpoint_fraction/solar_irradiance/rayleigh drift is
#     NOT explained by any identified source diff. 4a3686f/a4fdf0a are
#     v1.5-era and postdate the ecrad-tracked 1.4 file (no rebuild
#     evidence). The v1.2..23adaca window touches average_optical_depth.cpp
#     (transmission-3/10), ckd_model.cpp (SSI), and create_look_up_table
#     logging -- NOT find_g_points.cpp -- and average_optical_depth affects
#     gas OD table generation, not the gpoint_fraction/solar/rayleigh
#     support arrays that mismatched. The drift remains UNRESOLVED:
#     version-skew-plausible, or input/provenance/build-config differences.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const R1_RESULTS_JSON = validation_results_path("gate4_r1_release_provenance_probe.json")
const R1_RESULTS_MD = validation_results_path("gate4_r1_release_provenance_probe.md")

gh(url) = try
    JSON.parse(read(`curl -sL --max-time 30 $url`, String))
catch err
    Dict("error" => sprint(showerror, err))
end

function main()
    fails = String[]
    gates = Dict{String, String}()
    probes = Any[]

    # --- P1: ecckd configure.ac bump history (version -> commit map) -----
    hist = gh("https://api.github.com/repos/ecmwf-ifs/ecckd/commits?path=configure.ac&per_page=100")
    bumps = Any[]
    if hist isa Vector
        for c in hist
            msg = split(c["commit"]["message"], "\n")[1]
            push!(bumps, Dict("sha7" => c["sha"][1:7],
                "date" => c["commit"]["author"]["date"], "title" => msg))
        end
    end
    push!(probes, Dict("probe" => "P1 ecckd configure.ac history",
        "url" => "api.github.com/repos/ecmwf-ifs/ecckd/commits?path=configure.ac",
        "n_commits" => length(bumps)))
    v10 = findfirst(b -> b["sha7"] == "b42e5c0", bumps)
    v14 = findfirst(b -> b["sha7"] == "23adaca", bumps)
    gates["v10_bump_commit_found"] =
        (!isnothing(v10) && occursin("version 1.0", bumps[v10]["title"])) ?
        "passed" : "failed"
    gates["v14_bump_commit_found"] =
        (!isnothing(v14) && occursin("solar spectral irradiance",
                                     bumps[v14]["title"])) ? "passed" : "failed"

    # --- P2: master ChangeLog (authoritative in-repo release notes) ------
    changelog = try
        read(`curl -sL --max-time 30 https://raw.githubusercontent.com/ecmwf-ifs/ecckd/master/ChangeLog`, String)
    catch err
        sprint(showerror, err)
    end
    push!(probes, Dict("probe" => "P2 master ChangeLog",
        "url" => "raw.githubusercontent.com/ecmwf-ifs/ecckd/master/ChangeLog",
        "bytes" => length(changelog)))
    gates["changelog_v14_is_ssi_save"] =
        occursin(r"version 1\.4 \(November 2022\)\s*\n\s*- Save solar spectral irradiance", changelog) ?
        "passed" : "failed"
    gates["changelog_v15_owns_hybrid_averaging"] =
        occursin(r"version 1\.5 \(July 2023\)\s*\n\s*- Added hybrid-logarithmic-transmission-3", changelog) ?
        "passed" : "failed"
    gates["changelog_v10_january_2022"] =
        occursin("version 1.0 (January 2022)", changelog) ? "passed" : "failed"

    # --- P3: ecRad data packaging history for the two published files ----
    ecrad_pack = Dict{String, Any}()
    for (key, path) in [("lw10", "data/ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc"),
                        ("sw14", "data/ecckd-1.4_sw_climate_rgb-32b_ckd-definition.nc")]
        r = gh("https://api.github.com/repos/ecmwf-ifs/ecrad/commits?path=$path&per_page=5")
        ecrad_pack[key] = r isa Vector ? [Dict("sha7" => c["sha"][1:7],
            "date" => c["commit"]["author"]["date"],
            "title" => split(c["commit"]["message"], "\n")[1]) for c in r] :
            Dict("error" => "listing failed")
        push!(probes, Dict("probe" => "P3 ecrad packaging $key", "path" => path))
    end
    sw_ok = ecrad_pack["sw14"] isa Vector && !isempty(ecrad_pack["sw14"]) &&
            any(c -> c["sha7"] == "8936a8c" &&
                     occursin("ecCKD-1.4", c["title"]), ecrad_pack["sw14"])
    lw_pre = ecrad_pack["lw10"] isa Vector && !isempty(ecrad_pack["lw10"]) &&
             all(c -> c["date"] < "2022-01-13", ecrad_pack["lw10"])
    gates["ecrad_sw14_packaged_week_after_v14_bump"] = sw_ok ? "passed" : "failed"
    gates["ecrad_lw10_predates_v10_bump"] = lw_pre ? "passed" : "failed"

    # --- P4: ECPDS probes (HEAD only; negative recorded) ------------------
    ecpds = Any[]
    for u in ("https://aux.ecmwf.int/ecpds/home/ckdmip/ecckd/",
              "https://aux.ecmwf.int/ecpds/home/ckdmip/ecckd/ecckd-1.0_lw_climate_fsck-32b_ckd-definition.nc")
        code = try
            strip(read(`curl -sIL --max-time 20 -o /dev/null -w "%{http_code}" $u`, String))
        catch err
            sprint(showerror, err)
        end
        push!(ecpds, Dict("url" => u, "http_status" => code))
    end
    push!(probes, Dict("probe" => "P4 ECPDS HEAD probes", "results" => ecpds))
    gates["ecpds_probed_and_recorded"] = length(ecpds) == 2 ? "passed" : "failed"

    # --- P5: refs (tags/branches) -----------------------------------------
    tags = try read(`git ls-remote --tags https://github.com/ecmwf-ifs/ecckd.git`, String) catch e; sprint(showerror, e) end
    heads = try read(`git ls-remote --heads https://github.com/ecmwf-ifs/ecckd.git`, String) catch e; sprint(showerror, e) end
    push!(probes, Dict("probe" => "P5 refs", "tags" => strip(tags),
                       "heads" => strip(heads)))
    gates["only_v12_tag_and_master"] =
        (occursin("refs/tags/v1.2", tags) &&
         length(collect(eachmatch(r"refs/tags/", tags))) == 1 &&
         length(collect(eachmatch(r"refs/heads/", heads))) == 1) ?
        "passed" : "failed"

    # recon-only structural gate
    self_src = read(@__FILE__, String)
    gates["no_build_or_submission"] =
        !occursin(r"run\(`make", self_src) &&
        !occursin(Regex("run\\(`" * "sb" * "atch"), self_src) ? "passed" : "failed"

    mapping = Dict(
        "ecckd_1.4_sw" => Dict(
            "verdict" => "MAPPING FOUND (strong)",
            "source_state" => "commit 23adaca (2022-11-14) = the v1.4 " *
                "configure.ac bump; ChangeLog v1.4 (November 2022) lists " *
                "exactly one change: 'Save solar spectral irradiance " *
                "(corresponding to gpoint_fraction) in output file'",
            "corroboration" => "ecRad packaged the SW 1.4 file at 8936a8c " *
                "(2022-11-21), one week later, commit message naming the " *
                "solar-spectrum feature",
            "buildable" => "yes: git checkout 23adaca on master history"),
        "ecckd_1.0_lw" => Dict(
            "verdict" => "MAPPING AMBIGUOUS",
            "candidate_source_state" => "commit b42e5c0 (2022-01-13) = the " *
                "v1.0 configure.ac bump; ChangeLog 'version 1.0 (January " *
                "2022)'",
            "anomaly" => "the released LW file was already in ecRad by " *
                "2021-09-08 (5be474e 'Changed default ecCKD definition " *
                "files to 32 term'), PREdating the repo v1.0 bump by ~4 " *
                "months; the released file's true builder source state is " *
                "not established by public history (pre-release 0.7/0.8-era " *
                "code or a private state labeled 1.0 in anticipation)",
            "buildable" => "b42e5c0 is buildable, but identity with the " *
                "released file's builder is UNPROVEN"),
        "ssi_absence_strong_statement" => "the SW solar_spectral_irradiance " *
            "ABSENCE is accounted by v1.4 code: 23adaca adds ckd_model.cpp " *
            "persistence and is the v1.4 configure.ac bump; ChangeLog v1.4 " *
            "lists exactly this feature; ecRad packaged the 1.4 SW file a " *
            "week later naming it",
        "support_array_drift_cautious_statement" => "the small " *
            "gpoint_fraction/solar_irradiance/rayleigh drift is NOT " *
            "explained by any identified source diff: 4a3686f/a4fdf0a are " *
            "v1.5-era and postdate the ecrad-tracked 1.4 file (no rebuild " *
            "evidence); the v1.2..23adaca window changes " *
            "average_optical_depth.cpp (transmission-3/10), ckd_model.cpp " *
            "(SSI), and create_look_up_table logging but NOT " *
            "find_g_points.cpp, and average_optical_depth affects gas OD " *
            "table generation rather than the mismatched support arrays. " *
            "The 117 proof-run warnings therefore do NOT explain the " *
            "support-array mismatches. Drift remains UNRESOLVED: " *
            "version-skew-plausible, or input/provenance/build-config " *
            "differences",
        "remaining_blockers" => [
            "LW: released-file builder source state unestablished " *
            "(ecRad packaging predates the v1.0 bump)",
            "SW/LW support-array drift unlocalized: no identified source " *
            "diff explains it; input data, provenance, or build-config " *
            "differences remain candidates",
            "both: build-time config (tolerances, averaging method) of the " *
            "published builds is not pinned by version labels alone",
        ],
    )
    next_option = "R2 (needs go): build 23adaca and rerun the SW proof -- " *
        "a targeted matching-version test that definitively answers the " *
        "SSI-emission question; whether it also resolves the support-array " *
        "value drift is UNCERTAIN since the drift is not localized to any " *
        "identified source diff. LW rebuild at b42e5c0 is possible but its " *
        "verdict would be conditional on the unproven 1.0 mapping."

    status = isempty(fails) && all(v -> v == "passed", values(gates)) ?
        "r1_sw_mapping_found_lw_ambiguous" : "r1_probe_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    ghead = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_r1_release_provenance_probe",
        "data_mode" => "read_only_metadata_probes",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "probes" => probes,
        "version_bump_history" => bumps,
        "ecrad_packaging" => ecrad_pack,
        "mapping_findings" => mapping,
        "next_option" => next_option,
        "provenance" => Dict("branch" => branch, "generated_from_head" => ghead,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "read-only metadata probes; no large downloads, " *
                        "builds, submissions, floor, objective, acceptance, " *
                        "or rule changes.",
    )
    mkpath(dirname(R1_RESULTS_JSON))
    open(R1_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(R1_RESULTS_MD, "w") do io
        println(io, "# Gate-4 R1 release-provenance probe\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\n## Version -> commit map (configure.ac bump history)\n")
        for b in bumps
            println(io, "- `$(b["sha7"])` $(b["date"]): $(b["title"])")
        end
        println(io, "\n## Mapping findings\n")
        for k in ("ecckd_1.4_sw", "ecckd_1.0_lw")
            m = mapping[k]
            println(io, "**$k**: $(m["verdict"])")
            for (kk, vv) in m
                kk == "verdict" && continue
                println(io, "- $kk: $vv")
            end
            println(io)
        end
        println(io, "**SSI absence (strong)**: ",
                mapping["ssi_absence_strong_statement"], "\n")
        println(io, "**Support-array drift (cautious)**: ",
                mapping["support_array_drift_cautious_statement"], "\n")
        println(io, "**Remaining blockers**:")
        foreach(b -> println(io, "- ", b), mapping["remaining_blockers"])
        println(io, "\n**Next option**: ", next_option)
        println(io, "\nECPDS probes: " *
            join(["$(p["http_status"]) $(p["url"])" for p in ecpds], "; "))
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$ghead` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_r1_release_provenance_probe: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return startswith(status, "r1_probe_failed") ? 1 : 0
end

exit(main())
