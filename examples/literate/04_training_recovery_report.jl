# # Training and Recovery Report
#
# This example summarizes the current ecCKD recovery state from validation
# artifacts. It is intentionally evidence-backed: the status text and plot come
# from `validation/results`, not from duplicated prose.

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
            quoted = !quoted
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

root = repo_root()
targets_md = joinpath(root, "validation", "results", "ecckd_training_recovery_targets.md")
pareto_csv = joinpath(root, "validation", "results", "ecckd_band_accuracy_pareto.csv")

println(read(targets_md, String))

rows = read_csv(pareto_csv)
front = Dict{Int, Dict{String, String}}()
for row in rows
    total = parse(Int, row["total_gpoints"])
    boundary = parse(Float64, row["worst_boundary_forcing_error_w_m2"])
    current = get(front, total, nothing)
    if current === nothing || boundary < parse(Float64, current["worst_boundary_forcing_error_w_m2"])
        front[total] = row
    end
end

totals = sort(collect(keys(front)))
boundary = [parse(Float64, front[n]["worst_boundary_forcing_error_w_m2"]) for n in totals]
passed = [front[n]["passed"] == "true" for n in totals]

println()
println("Best available boundary-forcing row by total g points")
@printf("%8s %6s %6s %10s %8s\n", "total", "LW", "SW", "boundary", "passed")
for total in totals
    row = front[total]
    @printf("%8d %6s %6s %10.4f %8s\n",
        total,
        row["ng_lw"],
        row["ng_sw"],
        parse(Float64, row["worst_boundary_forcing_error_w_m2"]),
        row["passed"],
    )
end

fig = Figure(size = (760, 420))
ax = Axis(fig[1, 1],
    xlabel = "Total g points",
    ylabel = "Best boundary forcing error (W m^-2)",
    yscale = log10,
    title = "ecCKD recovery accuracy frontier")
lines!(ax, totals, boundary; color = :gray45, linewidth = 2)
scatter!(ax, totals, boundary; color = ifelse.(passed, :seagreen, :firebrick), markersize = 12)
hlines!(ax, [0.3]; color = :gray40, linestyle = :dash, label = "0.30 W m^-2 gate")
axislegend(ax; position = :rt)

asset_dir = normpath(joinpath(root, "docs", "src", "assets"))
mkpath(asset_dir)
save(joinpath(asset_dir, "ecckd_recovery_frontier.png"), fig)

# ![ecCKD recovery boundary-forcing frontier](../assets/ecckd_recovery_frontier.png)

