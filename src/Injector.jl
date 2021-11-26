module Injector

const fdict = Dict{Symbol, Core.OpaqueClosure}()

macro inject(fname, before = nothing, after = nothing)
    f = eval(fname)
    # avoid interjecting an already-interjected function
    fbase = haskey(fdict, fname) ?
        fdict[fname] :
        Base.Experimental.@opaque (args...) -> f(args...)
    for m ∈ methods(f)
        sig = m.sig
        if m.sig isa UnionAll
            typeparams = Symbol[]
            while sig isa UnionAll
                push!(typeparams, Symbol(sig.var))
                sig = sig.body
            end
            println(typeparams)
            params = sig.parameters[2:end]
            varnames = [gensym() for i ∈ eachindex(params)]
            call = Expr(:call, fname, [Expr(:(::), v, eval(p)) for (v, p) ∈ zip(varnames, params)]...)
            block = Expr(:block,
                if before !== nothing
                    Expr(:call, before)
                end,
                Expr(:(=), :fbase, fbase),
                Expr(:(=), :result, Expr(:call, :fbase, [v for v ∈ varnames]...)),
                if after !== nothing
                    Expr(:call, after, :result)
                end,
                Expr(:return, :result))
            global aaa = (Expr(:function,
                Expr(:where, 
                    call,
                    typeparams...),
                block))
            eval(Expr(:function,
                Expr(:where, 
                    call,
                    typeparams...),
                block))
        else
            params = sig.parameters[2:end]
            varnames = [gensym() for i ∈ eachindex(params)]
            call = Expr(:call, fname, [Expr(:(::), v, p) for (v, p) ∈ zip(varnames, params)]...)
            block = Expr(:block,
                if before !== nothing
                    Expr(:call, before)
                end,
                Expr(:(=), :fbase, fbase),
                Expr(:(=), :result, Expr(:call, :fbase, [v for v ∈ varnames]...)),
                if after !== nothing
                    Expr(:call, after, :result)
                end,
                Expr(:return, :result))
            eval(Expr(:function,
                    call,
                    block))
        end
    end
    fdict[fname] = fbase
    nothing
end

end # module
