"""
$(TYPEDEF)

Floating-point arithmetic of the radiative transfer kernels. Pass a concrete
arithmetic as `arithmetic` when constructing tabulated gas optics, or as the last
argument of the streaming solvers. It is a type, so the choice is made at compile
time and costs nothing at run time.
"""
abstract type AbstractArithmetic end

"""
$(TYPEDSIGNATURES)

IEEE arithmetic: correctly rounded division and square roots and the
full-precision `exp` and `expm1`. This is the default `arithmetic`.
"""
struct IEEEArithmetic <: AbstractArithmetic end

"""
$(TYPEDSIGNATURES)

`@fastmath` arithmetic in the two-stream layer solutions, the streaming sweeps
and the Planck-source interpolation. The compiler may reassociate and contract
sums and use approximate division, square roots and exponentials. On GPUs these
replace the IEEE division and square-root subroutines with a few instructions.
Each layer's fluxes change at the level of the rounding error of `FT`. The
`NaN` and infinity checks are dropped too, so inputs must be finite.
"""
struct FastArithmetic <: AbstractArithmetic end

# Evaluate `body` with `@fastmath` when `arithmetic` is a `FastArithmetic`.
# `arithmetic` is a singleton, so the branch is resolved at compile time.
macro arithmetic(arithmetic, body)
    return esc(quote
        if $arithmetic isa FastArithmetic
            Base.@fastmath $body
        else
            $body
        end
    end)
end
