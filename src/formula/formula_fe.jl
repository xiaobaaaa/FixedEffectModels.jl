##############################################################################
##
## Parse FixedEffect
##
##
##############################################################################

function parse_fixedeffect(df::AbstractDataFrame, feformula::FormulaTerm)
    fe = FixedEffect[]
    id = Symbol[]
    for term in eachterm(feformula.rhs)
        result = parse_fixedeffect(df, term, feformula)
        if result != nothing
            push!(fe, result[1])
            push!(id, result[2])
        end
    end
    return fe, id
end

# Constructors from dataframe + Term
function parse_fixedeffect(df::AbstractDataFrame, a::Term, feformula::FormulaTerm)
    v = df[!, Symbol(a)]
    if isa(v, CategoricalVector)
        return FixedEffect(v), Symbol(a)
    else
        # x from x*id -> x + id + x&id
        if !any(isa(term, InteractionTerm) & (a ∈ terms(term)) for term in eachterm(feformula.rhs))
               error("The term $(a) in fe= is a continuous variable. Convert it to a categorical variable using 'categorical'.")
        end
    end
end

# Constructors from dataframe + InteractionTerm
function parse_fixedeffect(df::AbstractDataFrame, a::InteractionTerm, feformula::FormulaTerm)
    factorvars, interactionvars = _split(df, a)
    if !isempty(factorvars)
        # x1&x2 from (x1&x2)*id
        fe = FixedEffect((df[!, v] for v in factorvars)...; interaction = _multiply(df, interactionvars))
        id = _name(Symbol.(terms(a)))
        return fe, id
    end
end

function _split(df::AbstractDataFrame, a::InteractionTerm)
    factorvars, interactionvars = Symbol[], Symbol[]
    for s in terms(a)
        s = Symbol(s)
        isa(df[!, s], CategoricalVector) ? push!(factorvars, s) : push!(interactionvars, s)
    end
    return factorvars, interactionvars
end

function _multiply(df, ss::Vector{Symbol})
    if isempty(ss)
        out = Ones(size(df, 1))
    else
        out = ones(size(df, 1))
        for j in eachindex(ss)
            _multiply!(out, df[!, ss[j]])
        end
    end
    return out
end

function _multiply!(out, v)
    for i in eachindex(out)
        if v[i] === missing
            # may be missing when I remove singletons
            out[i] = 0.0
        else
            out[i] = out[i] * v[i]
        end
    end
end

function _name(s::Vector{Symbol})
    if isempty(s)
        out = nothing
    else
        out = Symbol(reduce((x1, x2) -> string(x1)*"x"*string(x2), s))
    end
    return out
end



