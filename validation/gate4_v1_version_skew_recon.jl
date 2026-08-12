# Gate-4 V1 VERSION-SKEW reconnaissance (read-only; no builds, no
# submissions, no rule change) -- HISTORICAL: follow-up options executed.
#
# EXECUTED FOLLOW-UPS (monitor-directed marking, 2026-08-12; the recon
# evidence and hypothesis assessment below are preserved verbatim):
# R1 was executed (gate4_r1_release_provenance_probe:
# r1_sw_mapping_found_lw_ambiguous -- 23adaca is the strong SW source
# mapping; the LW-1.0 mapping remains unproven, a permanent caveat).
# R2 was executed with Greg's go ("go for R2") building 23adaca per R1's
# refinement -- NOT master b1482b2 as first sketched here -- as jobs
# 4094/4095 (configure failures) and 4096 (rc=0): SSI PRESENT +
# elementwise EXACT (absence RESOLVED as version skew); residual drift
# VERSION-INDEPENDENT (gate4_r2_finding_ledger). R3 was closed by Greg
# adopting Option B (gate4_option_b_decision_record). This recon's core
# status token remains TRUE and unchanged: the version-skew hypothesis is
# supported and the published-file-to-tag mapping remains unproven for
# LW-1.0. NOTE: this unit performs network reads (git ls-remote + GitHub
# API); reruns re-query live upstream state and were deliberately NOT
# performed for this marking -- the committed artifact carries an
# additive current-disposition annotation instead.
#
# Tests the pre-registered hypothesis that the proof mismatches
# (gate4_a2_proof_finding_ledger) are caused by ecCKD toolchain version skew:
# published LW32 is labeled ecckd-1.0, published SW32 ecckd-1.4, while the
# pinned rerun toolchain is tag v1.2 (6115f9b8...). Evidence: upstream tag
# listing, pinned commit metadata for three post-v1.2 commits, and a local
# grep proving the pinned writer cannot emit solar_spectral_irradiance.
#
# STATED LIMIT (binding): these source diffs SUPPORT the version-skew
# hypothesis but do NOT prove the published ecckd-1.0/1.4 files map to any
# buildable tag -- GitHub exposes only v1.2 and master; release provenance
# for 1.0/1.4 (ECPDS release notes, upstream contact, or ecRad data
# packaging history) would be required before any matching-version rebuild
# is even possible.

include(joinpath(@__DIR__, "validation_results.jl"))

using Dates
import JSON

const ECCKD_SRC = "/shared/home/greg/.julia/artifacts/" *
    "7b210aef53e908cfe3c709945f0763c37ca82aaa/" *
    "ecckd-6115f9b8e29a55cb0f48916857bdc77fec41badd"
const PINNED_TAG_COMMIT = "6115f9b8e29a55cb0f48916857bdc77fec41badd"

const V1_RESULTS_JSON = validation_results_path("gate4_v1_version_skew_recon.json")
const V1_RESULTS_MD = validation_results_path("gate4_v1_version_skew_recon.md")

# exact upstream commits cited (verified via GitHub API; monitor's parallel
# check and local API fetch agree)
const CITED_COMMITS = [
    Dict("sha7" => "23adaca", "date" => "2022-11-14T18:11:59Z",
         "title" => "Add solar spectral irradiance to output file",
         "relevance" => "adds ckd_model.cpp read/define/write persistence " *
             "of solar_spectral_irradiance in CKD definition files; " *
             "post-v1.2. The v1.2 contrast is NARROW: SSI-input reads " *
             "exist in v1.2 (find_g_points/create_look_up_table/" *
             "reorder_spectrum), but ckd_model.cpp has no CKD-definition " *
             "persistence for the variable -- accounts for the STRUCTURAL " *
             "absence in the proof SW raw definition"),
    Dict("sha7" => "4a3686f", "date" => "2023-05-03T21:18:48Z",
         "title" => "Added hybrid-logarithmic-transmission-3 averaging, " *
                    "better min/max bounds",
         "relevance" => "changes averaging/bound handling in the optical-" *
             "depth averaging used at create_lut time; candidate cause for " *
             "1e-6..1e-5 gpoint_fraction/solar/rayleigh value drift IF the " *
             "published 1.4 build postdates it"),
    Dict("sha7" => "a4fdf0a", "date" => "2023-05-18T11:57:09Z",
         "title" => "Improved handling of average absorptions outside " *
                    "min-max bounds which can happen with transmission " *
                    "averaging",
         "relevance" => "directly touches the min/max-bound correction " *
             "path behind the 117 average_optical_depth.cpp:105 warnings " *
             "in proof job 4091"),
]

function main()
    fails = String[]
    gates = Dict{String, String}()

    # --- local corroboration: pinned writer lacks SSI output support -----
    hits = String[]
    for (dir, _, fs) in walkdir(joinpath(ECCKD_SRC, "src/ecckd"))
        for f in fs
            (endswith(f, ".cpp") || endswith(f, ".h")) || continue
            for (i, line) in enumerate(eachline(joinpath(dir, f)))
                occursin("solar_spectral_irradiance", line) &&
                    push!(hits, "$f:$i: $(strip(line))")
            end
        end
    end
    # NARROW contrast (per review): SSI-INPUT reads are present and expected
    # in v1.2 (find_g_points/create_look_up_table/reorder_spectrum read the
    # ssi input file); what v1.2 lacks is ckd_model.cpp read/define/write
    # persistence of the variable in CKD DEFINITION files.
    ckd_model_hits = filter(h -> startswith(h, "ckd_model."), hits)
    input_read_hits = filter(h -> occursin("ssi_file.read", h), hits)
    gates["pinned_ckd_model_lacks_ssi_persistence"] =
        isempty(ckd_model_hits) && !isempty(input_read_hits) ?
        "passed" : "failed"
    gates["pinned_ckd_model_lacks_ssi_persistence"] == "passed" ||
        push!(fails, "expected zero ckd_model.cpp SSI hits and nonzero " *
                     "SSI-input reads; got ckd_model hits: $(ckd_model_hits)")

    # --- remote listing: which refs are buildable upstream ---------------
    tags = try
        read(`git ls-remote --tags https://github.com/ecmwf-ifs/ecckd.git`, String)
    catch err
        sprint(showerror, err)
    end
    head = try
        read(`git ls-remote https://github.com/ecmwf-ifs/ecckd.git HEAD`, String)
    catch err
        sprint(showerror, err)
    end
    only_v12_tag = occursin("refs/tags/v1.2", tags) &&
                   length(collect(eachmatch(r"refs/tags/", tags))) == 1
    pinned_matches_tag = occursin(PINNED_TAG_COMMIT, tags)
    gates["upstream_exposes_only_v12_tag"] = only_v12_tag ? "passed" : "failed"
    gates["pinned_artifact_is_exactly_v12"] =
        pinned_matches_tag ? "passed" : "failed"

    # --- cited commits verified via API (metadata only) ------------------
    verified = Any[]
    for c in CITED_COMMITS
        meta = try
            JSON.parse(read(`curl -sL --max-time 30 https://api.github.com/repos/ecmwf-ifs/ecckd/commits/$(c["sha7"])`, String))
        catch err
            Dict("error" => sprint(showerror, err))
        end
        ok = haskey(meta, "sha") &&
             startswith(meta["sha"], c["sha7"]) &&
             occursin(split(c["title"], ",")[1],
                      get(get(meta, "commit", Dict()), "message", ""))
        push!(verified, merge(c, Dict("api_verified" => ok,
            "full_sha" => get(meta, "sha", "unavailable"))))
    end
    gates["cited_commits_api_verified"] =
        all(v -> v["api_verified"], verified) ? "passed" : "failed"
    gates["cited_commits_api_verified"] == "passed" ||
        push!(fails, "one or more cited commits failed API verification")

    # --- recon-only structural gates -------------------------------------
    self_src = read(@__FILE__, String)
    gates["no_build_or_submission"] =
        !occursin(r"run\(`make", self_src) &&
        !occursin(r"run\(`.?/?configure", self_src) &&
        !occursin(Regex("run\\(`" * "sb" * "atch"), self_src) ? "passed" : "failed"
    gates["limit_stated"] = occursin("do NOT prove", read(@__FILE__, String)) ?
        "passed" : "failed"

    hypothesis = Dict(
        "sw_missing_variable" => "ACCOUNTED (strong): published SW32 is " *
            "ecckd-1.4; commit 23adaca (2022-11-14, post-v1.2) added " *
            "ckd_model.cpp read/define/write persistence of " *
            "solar_spectral_irradiance in CKD definition files. The v1.2 " *
            "contrast is narrow, NOT 'variable unknown': v1.2 reads the " *
            "variable from SSI inputs ($(length(input_read_hits)) " *
            "ssi_file.read hits in find_g_points/create_look_up_table/" *
            "reorder_spectrum) but ckd_model.cpp has zero references " *
            "($(length(ckd_model_hits)) hits), so v1.2 CKD definitions " *
            "structurally cannot carry it",
        "sw_value_drift" => "SUPPORTED (plausible): 4a3686f + a4fdf0a " *
            "(2023-05) change averaging and min/max-bound handling in the " *
            "exact code path that produced 117 correction warnings in the " *
            "proof run; IF the 1.4 build postdates them, drift is expected",
        "lw_value_drift" => "WEAKLY SUPPORTED: published LW32 is ecckd-1.0, " *
            "which PREdates v1.2, and no v1.0 tag or 1.0->1.2 diff is " *
            "visible upstream; attribution for the LW 2.7e-6 drift is " *
            "plausible but unverifiable from exposed source history",
        "limit" => "source diffs support version skew but do NOT prove the " *
            "published ecckd-1.0/1.4 files map to buildable tags; only " *
            "v1.2 ($(PINNED_TAG_COMMIT[1:7])) and master (b1482b2) are " *
            "exposed; matching-version rebuild requires release provenance " *
            "first",
    )
    # HISTORICAL: follow-up dispositions are VERIFIED against the result
    # artifacts before rendering, never hardcoded (the original option
    # texts are preserved in the committed at-recon artifact)
    ledger_status(name) = try
        String(JSON.parsefile(validation_results_path(name))["status"])
    catch; "unreadable" end
    r1_status = ledger_status("gate4_r1_release_provenance_probe.json")
    r2_status = ledger_status("gate4_r2_finding_ledger.json")
    ob_status = ledger_status("gate4_option_b_decision_record.json")
    followups_ok = r1_status == "r1_sw_mapping_found_lw_ambiguous" &&
                   r2_status == "r2_ssi_resolved_drift_version_independent" &&
                   ob_status == "option_b_adopted_candidates_promoted"
    gates["followup_statuses_verified"] = followups_ok ? "passed" : "failed"
    followups_ok ||
        push!(fails, "follow-up artifact statuses failed verification: " *
                     "r1=$r1_status r2=$r2_status option_b=$ob_status -- " *
                     "executed/closed claims withheld")
    next_options = followups_ok ? [
        "R1 EXECUTED (verified: $r1_status): 23adaca strong SW mapping; " *
        "LW-1.0 mapping permanently ambiguous",
        "R2 EXECUTED (verified: $r2_status; Greg: 'go for R2'; built " *
        "23adaca per R1 refinement, not master b1482b2 as first " *
        "sketched): SSI PRESENT + elementwise EXACT (absence RESOLVED " *
        "as version skew); residual drift VERSION-INDEPENDENT",
        "R3 CLOSED (verified: $ob_status): Greg adopted Option B; the " *
        "A/B choice from the proof finding ledger is no longer open",
    ] : [
        "FOLLOW-UP VERIFICATION FAILED (r1=$r1_status r2=$r2_status " *
        "option_b=$ob_status): executed/closed claims withheld",
    ]

    status = isempty(fails) ? "v1_version_skew_supported_mapping_unproven" :
                              "v1_recon_failed"
    branch = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --abbrev-ref HEAD`, String)) catch; "unknown" end
    ghead = try strip(read(`git -C $(dirname(@__DIR__)) rev-parse --short HEAD`, String)) catch; "unknown" end

    result = Dict(
        "case" => "gate4_v1_version_skew_recon",
        "data_mode" => "read_only_source_reconnaissance",
        "status" => status,
        "timestamp_utc" => string(Dates.now(Dates.UTC)),
        "gates" => gates, "failures" => fails,
        "pinned_toolchain" => Dict("tag" => "v1.2",
            "commit" => PINNED_TAG_COMMIT, "artifact" => ECCKD_SRC),
        "upstream_refs" => Dict("tags_raw" => strip(tags),
                                "head_raw" => strip(head)),
        "cited_commits" => verified,
        "local_ssi_references" => hits,
        "hypothesis_assessment" => hypothesis,
        "next_options" => next_options,
        "provenance" => Dict("branch" => branch, "generated_from_head" => ghead,
            "provenance_note" => "artifact generated from the working tree " *
                "before its own commit"),
        "disclaimer" => "read-only reconnaissance; no builds, submissions, " *
                        "floor, objective, acceptance, or rule changes.",
    )
    mkpath(dirname(V1_RESULTS_JSON))
    open(V1_RESULTS_JSON, "w") do io
        JSON.print(io, result, 2)
    end
    open(V1_RESULTS_MD, "w") do io
        println(io, "# Gate-4 V1 version-skew reconnaissance\n")
        println(io, "Status: **$status**\n")
        println(io, result["disclaimer"], "\n")
        println(io, "| Gate | Result |")
        println(io, "|---|---|")
        for k in sort(collect(keys(gates)))
            println(io, "| $k | $(gates[k]) |")
        end
        println(io, "\nPinned toolchain: tag v1.2 = `$(PINNED_TAG_COMMIT)` " *
                    "(exactly the artifact commit). Upstream exposes ONLY " *
                    "v1.2 and master (b1482b2) -- no v1.0/v1.4 tags.\n")
        println(io, "## Cited upstream commits (API-verified)\n")
        for v in verified
            println(io, "- `$(v["sha7"])` ($(v["date"])): $(v["title"]) -- " *
                        "$(v["relevance"]) [verified: $(v["api_verified"])]")
        end
        println(io, "\n## Hypothesis assessment\n")
        for k in ("sw_missing_variable", "sw_value_drift", "lw_value_drift",
                  "limit")
            println(io, "- **$k**: $(hypothesis[k])")
        end
        println(io, "\n## Follow-up options (all executed/closed)\n")
        foreach(o -> println(io, "- ", o), next_options)
        println(io, "\nProvenance: branch `$branch`, generated_from_head " *
                    "`$ghead` (pre-own-commit).")
        isempty(fails) || (println(io, "\n## Failures\n");
                           foreach(f -> println(io, "- ", f), fails))
    end
    println("gate4_v1_version_skew_recon: $status")
    for k in sort(collect(keys(gates)))
        println("  $k: $(gates[k])")
    end
    isempty(fails) || foreach(f -> println("  FAIL: $f"), fails)
    return status == "v1_version_skew_supported_mapping_unproven" ? 0 : 1
end

exit(main())
