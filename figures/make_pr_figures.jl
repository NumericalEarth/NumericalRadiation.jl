using CairoMakie
using JSON
using NCDatasets
using Statistics

const REPO_ROOT = abspath(joinpath(@__DIR__, ".."))
const OUT_DIR = @__DIR__
const LOCAL_BENCH_RESULTS = joinpath(REPO_ROOT, "benchmarking", "results")
const BREEZE_RESULTS = "/shared/home/greg/Projects/BreezeRadiativeHeatingDev/Breeze.jl/benchmarking/results"

set_theme!(theme_minimal())

# -----------------------------------------------------------------------------
# Figure 1. Clear-sky tropical column: official 32x32 ecCKD vs ecRad reference
# -----------------------------------------------------------------------------

function figure_flux_profiles()
    path = joinpath(REPO_ROOT, "validation/reference/ecrad/ecckd_clear_sky_tropical_column.nc")
    ds = NCDataset(path)

    p_iface = ds["pressure_interface"][:, :] ./ 100.0  # hPa
    p_layer = ds["pressure_layer"][:, :] ./ 100.0
    ref_lw_up = ds["lw_up"][:, :]
    ref_lw_dn = ds["lw_down"][:, :]
    ref_sw_up = ds["sw_up"][:, :]
    ref_sw_dn = ds["sw_down"][:, :]
    ref_hr = ds["heating_rate"][:, :]
    cand_lw_up = ds["radiative_heating_lw_up"][:, :]
    cand_lw_dn = ds["radiative_heating_lw_down"][:, :]
    cand_sw_up = ds["radiative_heating_sw_up"][:, :]
    cand_sw_dn = ds["radiative_heating_sw_down"][:, :]
    cand_hr = ds["radiative_heating_heating_rate"][:, :]
    close(ds)

    column = 1
    fig = Figure(size = (1100, 720))
    Label(fig[0, 1:3],
          "ecCKD 32x32 (RadiativeHeating.jl) vs ecRad on the clear-sky tropical column";
          fontsize = 18, font = :bold, tellwidth = false)

    panels = [
        ("LW up", ref_lw_up, cand_lw_up, p_iface, "W m⁻²"),
        ("LW down", ref_lw_dn, cand_lw_dn, p_iface, "W m⁻²"),
        ("Heating rate", ref_hr, cand_hr, p_layer, "K day⁻¹"),
        ("SW up", ref_sw_up, cand_sw_up, p_iface, "W m⁻²"),
        ("SW down", ref_sw_dn, cand_sw_dn, p_iface, "W m⁻²"),
    ]

    locs = [(1, 1), (1, 2), (1, 3), (2, 1), (2, 2)]
    for ((title, ref, cand, p, units), (row, col)) in zip(panels, locs)
        ax = Axis(fig[row, col]; title = title, xlabel = units,
                  ylabel = "pressure [hPa]", yreversed = true, yscale = log10)
        lines!(ax, ref[:, column], p[:, column]; color = :black, label = "ecRad", linewidth = 2)
        lines!(ax, cand[:, column], p[:, column]; color = :tomato,
               linestyle = :dash, label = "RadiativeHeating 32x32", linewidth = 2)
        ylims!(ax, 1000.0, 1.0)
    end

    # Error summary panel
    n_lev_iface = size(ref_lw_up, 1)
    n_lev_layer = size(ref_hr, 1)
    rmse_lw = sqrt(mean((vec(cand_lw_up) .- vec(ref_lw_up)).^2 .+ (vec(cand_lw_dn) .- vec(ref_lw_dn)).^2))
    rmse_sw = sqrt(mean((vec(cand_sw_up) .- vec(ref_sw_up)).^2 .+ (vec(cand_sw_dn) .- vec(ref_sw_dn)).^2))
    rmse_hr = sqrt(mean((vec(cand_hr) .- vec(ref_hr)).^2))
    toa_err = (cand_lw_up[1, column] - cand_lw_dn[1, column]) -
              (ref_lw_up[1, column] - ref_lw_dn[1, column])
    sfc_err = (cand_lw_dn[end, column] - cand_lw_up[end, column]) -
              (ref_lw_dn[end, column] - ref_lw_up[end, column])

    summary = """
    Flux RMSE (LW): $(round(rmse_lw; digits=3)) W m⁻²
    Flux RMSE (SW): $(round(rmse_sw; digits=3)) W m⁻²
    Heating-rate RMSE: $(round(rmse_hr; digits=4)) K day⁻¹
    TOA LW net forcing err (col 1): $(round(toa_err; digits=4)) W m⁻²
    Surface LW net forcing err (col 1): $(round(sfc_err; digits=4)) W m⁻²

    10 columns, 137 layers, 138 interfaces.
    Hard ecCKD gate: passed.
    """
    Label(fig[2, 3], summary; tellwidth = false, tellheight = false,
          halign = :left, valign = :top, font = :regular)

    Legend(fig[3, 1:3], fig.content[2], orientation = :horizontal, tellheight = true, tellwidth = false)

    save(joinpath(OUT_DIR, "fig1_ecckd_vs_ecrad_profiles.png"), fig; px_per_unit = 2)
    return fig
end

# -----------------------------------------------------------------------------
# Figure 2. H100 speedup bar chart across k-model configurations
# -----------------------------------------------------------------------------

function figure_h100_speedup()
    # Prefer the independent benchmarking project's results (this repo); fall
    # back to the dedicated Breeze checkout for older runs that haven't been
    # re-measured under the new streaming kernel yet.
    function load_local(label)
        path = joinpath(LOCAL_BENCH_RESULTS, "rcemip_h100_$(label)",
                        "radiative_heating_rcemip_latest.json")
        isfile(path) ? JSON.parsefile(path) : nothing
    end

    local_kmodels = [
        ("32x32_validated_ecckd", 32, 32),
        ("32x64_validated_ecckd", 32, 64),
        ("32x96_validated_ecckd", 32, 96),
        ("64x32_validated_ecckd", 64, 32),
        ("64x64_validated_ecckd", 64, 64),
    ]

    rh_rows = Vector{NamedTuple}(undef, 0)

    # Single, defensible RRTMGP baseline: pull from the 32x32 local run if
    # available (consistent grid size with the rest of the local sweep);
    # otherwise fall back to the dedicated Breeze production run.
    local_32x32 = load_local("32x32_validated_ecckd")
    if local_32x32 !== nothing && local_32x32["rrtmgp_update_median_ms"] !== nothing
        rrtmgp_baseline_ms = Float64(local_32x32["rrtmgp_update_median_ms"])
        rrtmgp_samples = Int(get(local_32x32, "samples", 0))
        baseline_source = "local benchmarking/results/rcemip_h100_32x32_validated_ecckd"
    else
        rcemip32 = JSON.parsefile(joinpath(BREEZE_RESULTS,
                                           "rcemip_h100_32x32x64/radiative_heating_rcemip_latest.json"))
        rrtmgp_baseline_ms = Float64(rcemip32["rrtmgp_update_median_ms"])
        rrtmgp_samples = Int(get(rcemip32, "samples", 0))
        baseline_source = "Breeze checkout rcemip_h100_32x32x64 (legacy)"
        # Seed the headline 32x32 row from the legacy artifact if local doesn't exist.
        push!(rh_rows, (
            label = "32 LW × 32 SW",
            ng_lw = 32, ng_sw = 32,
            rh_ms = Float64(rcemip32["radiative_heating_update_median_ms"]),
            source = :validated,
            samples = Int(get(rcemip32, "samples", 0)),
            grid = (32, 32, 64),
            origin = :legacy))
    end

    # Local benchmarking/results sweep (preferred — these are streaming-kernel
    # runs at the production grid).
    for (label, ng_lw, ng_sw) in local_kmodels
        d = load_local(label)
        d === nothing && continue
        rh = get(d, "radiative_heating_update_median_ms", nothing)
        rh === nothing && continue
        grid = get(d, "grid", Dict{String, Any}())
        nx = Int(get(grid, "nx", 0)); ny = Int(get(grid, "ny", 0)); nz = Int(get(grid, "nz", 0))
        # Drop legacy row if local replaces it.
        filter!(r -> !(r.ng_lw == ng_lw && r.ng_sw == ng_sw), rh_rows)
        push!(rh_rows, (
            label = "$(ng_lw) LW × $(ng_sw) SW",
            ng_lw = ng_lw, ng_sw = ng_sw,
            rh_ms = Float64(rh),
            source = :validated,
            samples = Int(get(d, "samples", 0)),
            grid = (nx, ny, nz),
            origin = :local))
    end

    # Mark any remaining published ecCKD k-models that have no measurement yet.
    benchmarked = Set((r.ng_lw, r.ng_sw) for r in rh_rows)
    for (ng_lw, ng_sw) in [(64, 32), (32, 64), (32, 96), (64, 64)]
        if !((ng_lw, ng_sw) in benchmarked)
            push!(rh_rows, (
                label = "$(ng_lw) LW × $(ng_sw) SW",
                ng_lw = ng_lw, ng_sw = ng_sw,
                rh_ms = NaN,
                source = :pending,
                samples = 0,
                grid = (0, 0, 0),
                origin = :pending))
        end
    end

    # Sort by total g-points descending
    sort!(rh_rows; by = r -> -(r.ng_lw + r.ng_sw))

    # Title carries the grid size for the local rows so the figure is honest
    # about workload. Mixed-origin sweeps annotate each bar with its own grid.
    local_grids = unique(r.grid for r in rh_rows if r.origin == :local)
    grid_title = if length(local_grids) == 1
        nx, ny, nz = local_grids[1]
        "RCEMIP-style $(nx)×$(ny)×$(nz) / $(nx*ny) columns"
    elseif !isempty(local_grids)
        "RCEMIP-style — grid per bar"
    else
        "RCEMIP-style (legacy 32×32×64 / 1024 columns)"
    end

    fig = Figure(size = (1400, 760))
    Label(fig[1, 1:2],
          "RadiativeHeating.jl vs a single RRTMGP baseline on H100\n" * grid_title;
          fontsize = 18, font = :bold, tellwidth = false, justification = :center)

    # Left panel: head-to-head against the validated 32×32 production target.
    headline_idx = findfirst(r -> r.source == :validated && r.ng_lw == 32 && r.ng_sw == 32, rh_rows)
    if headline_idx === nothing
        headline_idx = findfirst(r -> r.source == :validated, rh_rows)
    end
    headline = rh_rows[headline_idx]
    ax1 = Axis(fig[2, 1];
               title = "Head-to-head (production, post-warmup median)",
               ylabel = "radiation update median [ms]\n(lower is faster)",
               xticks = ([1, 2], ["RadiativeHeating.jl\n$(headline.label)\nvalidated ecCKD",
                                  "RRTMGP.jl\nstandard model\n(256 LW × 224 SW)"]))
    barplot!(ax1, [1.0], [headline.rh_ms]; width = 0.55, color = :tomato)
    barplot!(ax1, [2.0], [rrtmgp_baseline_ms]; width = 0.55, color = :steelblue)
    text!(ax1, 1, headline.rh_ms + rrtmgp_baseline_ms * 0.03,
          text = "$(round(headline.rh_ms; digits=2)) ms",
          align = (:center, :bottom), fontsize = 14, font = :bold, color = :tomato)
    text!(ax1, 2, rrtmgp_baseline_ms + rrtmgp_baseline_ms * 0.03,
          text = "$(round(rrtmgp_baseline_ms; digits=1)) ms",
          align = (:center, :bottom), fontsize = 14, font = :bold, color = :steelblue)
    text!(ax1, 1.5, rrtmgp_baseline_ms * 0.6,
          text = "$(round(rrtmgp_baseline_ms / headline.rh_ms; digits=1))×\nspeedup",
          align = (:center, :center), fontsize = 22, font = :bold, color = :black)
    ylims!(ax1, 0, rrtmgp_baseline_ms * 1.18)

    # Right panel: RadiativeHeating timing across k-models, with the single
    # RRTMGP baseline as a horizontal reference line.
    n = length(rh_rows)
    ax2 = Axis(fig[2, 2];
               title = "RadiativeHeating across ecCKD k-models\n(↑ on bar: speedup vs RRTMGP baseline)",
               ylabel = "radiation update median [ms]",
               xticks = (1:n, [r.label for r in rh_rows]),
               xticklabelrotation = pi/6,
               xticklabelsize = 11,
               yscale = log10)

    # Plot each RadiativeHeating bar in a color matching its provenance
    color_map = Dict(:validated => :tomato, :scaffold => RGBf(1.0, 0.65, 0.4),
                     :pending => RGBf(0.85, 0.85, 0.85))
    for (i, r) in enumerate(rh_rows)
        if r.source == :pending
            # placeholder grey bar at floor; annotated as not measured
            barplot!(ax2, [Float64(i)], [0.5]; width = 0.6,
                     color = color_map[:pending], strokecolor = :gray, strokewidth = 1)
            text!(ax2, i, 0.6,
                  text = "no H100\ntiming yet",
                  align = (:center, :bottom), fontsize = 9, color = :gray35)
        else
            barplot!(ax2, [Float64(i)], [r.rh_ms]; width = 0.6,
                     color = color_map[r.source])
            speedup = rrtmgp_baseline_ms / r.rh_ms
            text!(ax2, i, r.rh_ms * 1.15,
                  text = "$(round(speedup; digits=1))×",
                  align = (:center, :bottom), fontsize = 13, font = :bold, color = :black)
            text!(ax2, i, r.rh_ms * 0.55,
                  text = "$(round(r.rh_ms; digits=1)) ms",
                  align = (:center, :center), fontsize = 10, color = :white)
        end
    end

    # RRTMGP baseline reference line
    hlines!(ax2, [rrtmgp_baseline_ms]; color = :steelblue, linestyle = :dash, linewidth = 2)
    text!(ax2, n * 0.5, rrtmgp_baseline_ms * 1.08,
          text = "RRTMGP baseline: $(round(rrtmgp_baseline_ms; digits=1)) ms (n=$(rrtmgp_samples))",
          color = :steelblue, fontsize = 11, align = (:center, :bottom), font = :bold)

    ylims!(ax2, 0.3, rrtmgp_baseline_ms * 3)

    # Provenance legend — only include the categories actually present.
    elems = []
    labels = String[]
    if any(r -> r.source == :validated, rh_rows)
        push!(elems, PolyElement(color = color_map[:validated]))
        push!(labels, "validated ecCKD (samples=$(rrtmgp_samples), post-warmup median)")
    end
    if any(r -> r.source == :scaffold, rh_rows)
        push!(elems, PolyElement(color = color_map[:scaffold]))
        push!(labels, "fixed-coeff scaffold (samples=1, single-shot legacy)")
    end
    if any(r -> r.source == :pending, rh_rows)
        push!(elems, PolyElement(color = color_map[:pending],
                                 strokecolor = :gray, strokewidth = 1))
        push!(labels, "published ecCKD model, no H100 timing yet")
    end
    if !isempty(elems)
        Legend(fig[3, 1:2], elems, labels;
               orientation = :horizontal, framecolor = (:gray, 0.6),
               tellheight = true, tellwidth = false)
    end

    colsize!(fig.layout, 1, Relative(0.32))
    save(joinpath(OUT_DIR, "fig2_h100_speedup.png"), fig; px_per_unit = 2)
    return fig
end

# -----------------------------------------------------------------------------
# Figure 3. Training / recovery curves
# -----------------------------------------------------------------------------

function figure_training_curves()
    toy = JSON.parsefile(joinpath(REPO_ROOT, "validation/results/toy_ecckd_training.json"))
    ad = JSON.parsefile(joinpath(REPO_ROOT, "validation/results/rrtmgp_target_16g_ad_calibration.json"))

    toy_loss = Float64.(toy["loss_history"])
    toy_it = collect(0:length(toy_loss)-1)

    ad_traj = ad["training"]["trajectory"]
    ad_it = [Int(t["iteration"]) for t in ad_traj]
    ad_loss = [Float64(t["loss"]) for t in ad_traj]
    if haskey(ad_traj[end], "best_trial_loss") && ad_traj[end]["best_trial_loss"] !== nothing
        push!(ad_it, ad_it[end] + 1)
        push!(ad_loss, Float64(ad_traj[end]["best_trial_loss"]))
    end

    fig = Figure(size = (1100, 560))
    Label(fig[0, 1:2],
          "Reactant/Enzyme calibration of ecCKD coefficients";
          fontsize = 18, font = :bold, tellwidth = false)

    # Left: toy fixed-topology gradient descent
    ax1 = Axis(fig[1, 1]; xlabel = "epoch", ylabel = "training loss (MSE flux + heating rate)",
               title = "toy fixed-topology ecCKD recovery\n(Enzyme-pure gradient checked)",
               yscale = log10)
    lines!(ax1, toy_it, toy_loss; color = :tomato, linewidth = 2.5)
    scatter!(ax1, toy_it, toy_loss; color = :tomato, markersize = 8)
    flux_ratio = round(Float64(toy["flux_rmse_ratio"]); digits = 3)
    hr_ratio = round(Float64(toy["heating_rate_rmse_ratio"]); digits = 3)
    loss_ratio = round(Float64(toy["loss_ratio"]); digits = 4)
    text!(ax1, 1.0, toy_loss[1] * 0.45,
          text = "loss × $(loss_ratio)\nflux RMSE × $(flux_ratio)\nheating-rate RMSE × $(hr_ratio)",
          align = (:left, :top), font = "DejaVu Sans Mono", fontsize = 11)

    # Right: production 16-g RRTMGP-target AD calibration
    ax2 = Axis(fig[1, 2]; xlabel = "epoch", ylabel = "shortwave loss",
               title = "16-g shortwave RRTMGP-target calibration\n(Reactant-compiled, Enzyme reverse-mode)")
    lines!(ax2, ad_it, ad_loss; color = :steelblue, linewidth = 2.5)
    scatter!(ax2, ad_it, ad_loss; color = :steelblue, markersize = 8)
    text!(ax2, ad_it[1] + 0.3, ad_loss[1] - 1.0,
          text = "Δloss = $(round(ad_loss[1] - ad_loss[end]; digits = 2))\n($(ad["parameter_count"]) params)",
          align = (:left, :top), font = "DejaVu Sans Mono", fontsize = 11)

    save(joinpath(OUT_DIR, "fig3_training_curves.png"), fig; px_per_unit = 2)
    return fig
end

# -----------------------------------------------------------------------------
# Figure 4. Reduced-model objective descent over the optimizer chain
# -----------------------------------------------------------------------------

function figure_reduced_descent()
    # Time-ordered chain from the retired campaign narrative (archived ref
    # audit-trail-2026-07-17; frozen endpoints in validation/FROZEN_DIAGNOSTICS.md);
    # each entry is (step label, hard-gate objective after the accepted move).
    chain = [
        ("baseline (no shortwave subset)", 0.014033547037797689),  # passing 32x32 reference
        ("weighted-greedy 16-g subset",     7.17718646855576),
        ("+ boundary-weighted shortwave weights", 5.557632544628063),
        ("+ projected hard-gate max-norm weights", 5.518843803513278),
        ("+ preflight-optimized scales",          2.588652944311036),
        ("+ pressure-band table moves",           2.311709885137816),
        ("+ active-entry table moves",            8.39187324383),
        ("+ exact post-table weight refit",       8.32190990405),
        ("+ slot-blend table moves",              7.47836712724),
        ("+ post-slot weight refit",              7.45725553248),
        ("+ constrained-table continuations",     7.42818441105),
        ("+ all-case active-entry continuation",  7.42405122402),
        ("+ residual-probe scope",                7.42094851978),
        ("+ Rayleigh-inclusive residual probe",   7.41977527859),
        ("+ boundary-aware weight refit",         7.355912280200036),
        ("+ smaller-step continuation",           7.311608077751165),
        ("+ half-step continuation",              7.297431753704113),
        ("+ quarter-step continuation",           7.297425585382674),
        ("+ Rayleigh exact coordinate scan",      7.29601319503),
        ("+ pair coordinate scan",                7.29587581499),
        ("+ coordinate-descent continuation",     7.29585929551),
        ("+ component-scale refit",               7.13988657025),
        ("+ pressure-component scale",            7.13985474639),
        ("+ temperature-component scale",         7.13985031352),
        ("+ H₂O / gas component scale",           7.13985029534),
        ("retained 32×16 (current best)",         7.13985029534),
    ]

    labels = [c[1] for c in chain]
    objs = [Float64(c[2]) for c in chain]

    fig = Figure(size = (1400, 900))
    Label(fig[1, 1],
          "Reduced 16-g shortwave optimizer:\nworst boundary forcing error vs accepted optimizer moves";
          fontsize = 18, font = :bold, tellwidth = false, justification = :center)

    ax = Axis(fig[2, 1];
              ylabel = "worst boundary forcing error [W m⁻²]",
              xticks = (1:length(labels), labels),
              xticklabelrotation = pi/3,
              xticklabelsize = 11,
              yscale = log10)

    # Plot in physical units (W m⁻²) by multiplying normalized objective by 0.3
    physical = objs .* 0.3
    lines!(ax, 1:length(physical), physical; color = :tomato, linewidth = 2)
    scatter!(ax, 1:length(physical), physical; color = :tomato, markersize = 9)
    hlines!(ax, [0.3]; color = :forestgreen, linestyle = :dash, linewidth = 2)

    ylims!(ax, 0.001, 5.0)
    text!(ax, length(labels) * 0.5, 0.34,
          text = "hard-gate threshold: 0.3 W m⁻²",
          color = :forestgreen, align = (:center, :bottom), fontsize = 13, font = :bold)
    text!(ax, 1.3, physical[1] * 1.8,
          text = "official 32×32 baseline:\n$(round(physical[1]; digits=4)) W m⁻² (passes)",
          align = (:left, :bottom), fontsize = 11, color = :black)
    text!(ax, length(physical) - 0.5, physical[end] * 1.4,
          text = "current best 32×16:\n$(round(physical[end]; digits=2)) W m⁻²\n(≈ $(round(physical[end]/0.3; digits=1))× threshold)",
          align = (:right, :bottom), fontsize = 11, color = :black, font = :bold)

    rowsize!(fig.layout, 1, Auto(0.08))
    rowsize!(fig.layout, 2, Auto(1.0))
    save(joinpath(OUT_DIR, "fig4_reduced_descent.png"), fig; px_per_unit = 2)
    return fig
end

# -----------------------------------------------------------------------------

println("generating fig1...")
figure_flux_profiles()
println("generating fig2...")
figure_h100_speedup()
println("generating fig3...")
figure_training_curves()
println("generating fig4...")
figure_reduced_descent()
println("done. PNGs in: ", OUT_DIR)
