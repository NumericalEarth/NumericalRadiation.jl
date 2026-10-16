"""
$(TYPEDEF)

Search strategy for bracketing lookup-table queries. Pass a concrete strategy
as `lookup_search` when constructing gas or cloud optics.
"""
abstract type AbstractLookupSearch end

"""
$(TYPEDSIGNATURES)

Binary search that exits when the interpolation interval is found. This is
the default `lookup_search` for gas and cloud optics.
"""
struct BinarySearch <: AbstractLookupSearch end

"""
$(TYPEDSIGNATURES)

Binary search with a fixed iteration count determined by the table size.
Completed intervals stay unchanged during the remaining iterations. Use
`lookup_search=FixedBinarySearch()` for batched kernel compilation that cannot
raise a data-dependent search loop. Interpolation and endpoint behavior match
[`BinarySearch`](@ref).
"""
struct FixedBinarySearch <: AbstractLookupSearch end

"""
$(TYPEDSIGNATURES)

Direct indexing of a uniformly spaced table: the bracket is computed from the
first node and the spacing, with no search and no loop. Requires uniformly
spaced vector temperature and Planck-source grids (or effective-radius nodes,
for cloud optics), which the constructors check. The ecCKD reference tables'
Planck-source grid is uniform. Interpolation and endpoint behavior match
[`BinarySearch`](@ref), except that a `NaN` query brackets the first interval
(its weight is `NaN`, as for the searches).
"""
struct DirectIndexing <: AbstractLookupSearch end

@inline bracket(grid, x) = bracket(grid, x, BinarySearch())

@inline function bracket(grid, x, ::BinarySearch)
    x <= grid[begin] && return firstindex(grid), firstindex(grid) + 1, zero(eltype(grid))
    last = lastindex(grid)
    x >= grid[last] && return last - 1, last, one(eltype(grid))

    lower = firstindex(grid)
    upper = last
    while upper - lower > 1
        mid = (lower + upper) >>> 1
        if x < grid[mid]
            upper = mid
        else
            lower = mid
        end
    end
    weight = (x - grid[lower]) / (grid[upper] - grid[lower])
    return lower, upper, weight
end

@inline function bracket(grid, x, ::FixedBinarySearch)
    lower = firstindex(grid)
    upper = lastindex(grid)
    # ceil(log2(N - 1)), including zero iterations for a two-node table.
    # Freeze completed intervals because different queries finish at
    # different iterations. The loop bound depends only on the table size.
    iterations = 8sizeof(Int) - leading_zeros(length(grid) - 2)
    for iteration in 1:iterations
        mid = (lower + upper) >>> 1
        left = @inbounds x < grid[mid]
        searching = upper - lower > 1
        upper = ifelse(searching & left, mid, upper)
        lower = ifelse(searching & !left, mid, lower)
    end
    @inbounds weight = (x - grid[lower]) / (grid[upper] - grid[lower])
    # Preserve the dynamic search's exact endpoint values, including infinities;
    # a NaN query retains a NaN weight.
    @inbounds weight = ifelse(x <= grid[begin], zero(eltype(grid)), weight)
    @inbounds weight = ifelse(x >= grid[end], one(eltype(grid)), weight)
    return lower, upper, weight
end

@inline function bracket(grid, x, ::DirectIndexing)
    first = firstindex(grid)
    @inbounds offset = (x - grid[first]) / (grid[first + 1] - grid[first])
    i₀ = first + clamped_lower_index(offset, length(grid) - 2)
    # The weight is taken from the bracketing nodes rather than as the fractional part of
    # `offset`, so the index enters only as an address: Reactant differentiates a truncated
    # index as if it were the identity, which would cancel the weight's derivative.
    @inbounds weight = (x - grid[i₀]) / (grid[i₀ + 1] - grid[i₀])
    return i₀, i₀ + 1, clamp(weight, zero(weight), one(weight))
end

# Strategies that index directly need uniformly spaced axes
validate_lookup_axis(::AbstractLookupSearch, grid, name) = nothing
validate_lookup_axis(::DirectIndexing, grid, name) = length(grid) < 2 ? nothing : validate_uniform_grid(grid, name)
