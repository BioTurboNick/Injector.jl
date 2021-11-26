Injector.jl

Inject code before or after any existing function.

```
a(::Int) = 1
a(::Float64) = 2
a(::Any) = 3

@inject a () -> println("hello!") x -> println("world $x!")

a(1)
#=
hello!
world 1!
1
=#

a(1.0)
#=
hello!
world 2!
2
=#

a("")
#=
hello!
world 3!
3
=#

# remove the injected code
# note that this still passes through an underlying opaque closure
# while program behavior will be restored, performance characteristics may be different
@inject a

a(1)
#=
1
=#
```