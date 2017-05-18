##############################################################################
##
## Weight
## 
##############################################################################
function get_weight(df::AbstractDataFrame, esample::BitVector, weight::Symbol) 
    out = df[esample, weight]
    # there are no NA in it. DataVector to Vector
    out = convert(Vector{Float64}, out)
    map!(sqrt, out, out)
    return out
end
get_weight(df::AbstractDataFrame, esample::BitVector, ::Void) = Ones{Float64}(sum(esample))
