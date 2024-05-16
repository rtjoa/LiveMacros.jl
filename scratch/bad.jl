# There are some weird things with Julia macros that generate macros
macro mk_macro(hd, body)
    @assert hd.head == :call
    name, args... = hd.args
    quote
        macro $(esc(name))($([esc(arg) for arg in args]...))
            $(esc(body))
        end
    end
end

# Let's define a macro equivalent to:
#   macro double(x)
#       quote
#           2 * $(x)
#       end
#   end
@mk_macro double(x) begin
    quote
        2 * $(esc(x))
    end
end

# It works as intended
@assert (@double 2) == 4

# But the macro expanded code is weird, and errors if uncommented.
println(
    @macroexpand (@mk_macro double(x) begin
        quote
            2 * $(esc(x))
        end
end))
# begin
#     #= /space/tjoa/LiveMacros.jl/bad.jl:6 =#
#     macro double(x)
#         #= /space/tjoa/LiveMacros.jl/bad.jl:6 =#
#         #= /space/tjoa/LiveMacros.jl/bad.jl:7 =#
#         begin
#             #= /space/tjoa/LiveMacros.jl/bad.jl:29 =#
#             Core._expr(:block, $(QuoteNode(:(#= /space/tjoa/LiveMacros.jl/bad.jl:30 =#))), Core._expr(:call, :*, 2, esc(x)))
#         end
#     end
# end