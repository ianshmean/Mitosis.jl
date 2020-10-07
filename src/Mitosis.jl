module Mitosis

using LinearAlgebra
using Random
using MeasureTheory

import Base: iterate, length
function ⊕ end
const ∅ = nothing

abstract type Context end

struct BFFG <: Context
end

inner(x) = dot(x,x)
outer(x) = x*x'

macro F(f) :(::typeof($f)) end


export Traced
struct Traced{T}
    x::T
end


include("gauss.jl")
include("markov.jl")
include("rules.jl")

end # module
