# # RRTMGP Validation Report
#
# This example turns the current reduced ecCKD/RRTMGP validation artifact into a
# compact table and figure. It does not run RRTMGP itself; the expensive
# comparison is owned by `validation/reduced_ecckd_32g_rrtmgp_comparison.jl`.

using CairoMakie
using Printf

function repo_root()
    dir = @__DIR__
    for _ in 1:8
        if isfile(joinpath(dir, "Project.toml")) && isdir(joinpath(dir, "validation", "results"))
            return dir
        end
        parent = dirname(dir)
        parent == dir && break
        dir = parent
    end
    error("could not locate repository root")
end

function parse_csv_line(line)
    fields = String[]
    buffer = IOBuffer()
    quoted = false
    i = firstindex(line)
    while i <= lastindex(line)
        c = line[i]
        if c == '"'
            if quoted && i < lastindex(line) && line[nextind(line, i)] == '"'
                print(buffer, '"')
                i = nextind(line, i)
            else
                quoted = !quoted
            end
        elseif c == ',' && !quoted
            push!(fields, String(take!(buffer)))
        else
            print(buffer, c)
        end
        i = nextind(line, i)
    end
    push!(fields, String(take!(buffer)))
    return fields
end

function read_csv(path)
    lines = collect(eachline(path))
    header = parse_csv_line(first(lines))
    rows = Dict{String, String}[]
    for line in Iterators.drop(lines, 1)
        isempty(strip(line)) && continue
        values = parse_csv_line(line)
        push!(rows, Dict(header[i] => values[i] for i in eachindex(header)))
    end
    return rows
end

csv_path = joinpath(repo_root(), "validation", "results", "reduced_ecckd_rrtmgp_accuracy_vs_bands.csv")
rows = read_csv(csv_path)

println("RRTMGP comparison rows: ", length(rows))
println()
@printf("%-18s %7s %10s %12s %8s\n", "model", "gpoints", "forcing", "base RMSE", "passes")
for row in rows
    @printf("%-18s %7s %10.3f %12.3f %8s\n",
        row["model"],
        row["total_gpoints"],
        parse(Float64, row["max_abs_forcing_error_w_m2"]),
        parse(Float64, row["max_base_flux_rmse_w_m2"]),
        row["passes_forcing_threshold"],
    )
end

gpoints = [parse(Float64, row["total_gpoints"]) for row in rows]
forcing = [parse(Float64, row["max_abs_forcing_error_w_m2"]) for row in rows]
labels = [row["model"] for row in rows]
passes = [row["passes_forcing_threshold"] == "true" for row in rows]

fig = Figure(size = (760, 420))
ax = Axis(fig[1, 1],
    xlabel = "Total g points",
    ylabel = "Max forcing error against RRTMGP (W m^-2)",
    title = "Reduced ecCKD/RRTMGP comparison")
scatter!(ax, gpoints, forcing; color = ifelse.(passes, :seagreen, :firebrick), markersize = 12)
hlines!(ax, [0.3]; color = :gray40, linestyle = :dash, label = "0.30 W m^-2 gate")
for (x, y, label) in zip(gpoints, forcing, labels)
    text!(ax, x, y; text = label, fontsize = 9, align = (:left, :bottom), offset = (4, 4))
end
axislegend(ax; position = :rt)

asset_dir = normpath(joinpath(repo_root(), "docs", "src", "assets"))
mkpath(asset_dir)
save(joinpath(asset_dir, "rrtmgp_accuracy_vs_bands.png"), fig)

# ![RRTMGP comparison forcing error by total g points](../assets/rrtmgp_accuracy_vs_bands.png)

