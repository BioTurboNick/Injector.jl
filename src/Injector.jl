module Injector

using ExprTools

export @inject

const fdict = Dict{Symbol, Core.OpaqueClosure}()

macro inject(fname, before = nothing, after = nothing)
    f = eval(fname)
    # avoid interjecting an already-interjected function
    fbase = haskey(fdict, fname) ?
        fdict[fname] :
        Base.Experimental.@opaque (args...) -> f(args...)
    for m ∈ methods(f)
        func = signature(m)
        varnames = [a isa Symbol ? a : a.args[1] for a ∈ func[:args]]
        func[:body] = Expr(:block,
            if before !== nothing
                Expr(:call, before)
            end,
            #Expr(:(=), :fbase, fbase),
            Expr(:(=), :result, Expr(:call, fbase, [v for v ∈ varnames]...)),
            if after !== nothing
                Expr(:call, after, :result)
            end,
            Expr(:return, :result))
        eval(combinedef(func))
    end
    fdict[fname] = fbase
    nothing
end

end # module
