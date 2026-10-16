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
