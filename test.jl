using MacroTools
using MacroTools: postwalk

function postwalk_rvalues(f, e)
    if @capture(e, lhs_ = rhs_)
        :($(lhs) = $(postwalk_rvalues(f, rhs)))
    elseif e isa Expr
        f(
            Expr(
                e.head,
                [postwalk_rvalues(f, arg) for arg in e.args]...
            )
        )
    else
        e
    end
end

sym_to_source = Dict()
macro_to_source = Dict()
macro livemacro(hd, body)
    captured = @capture(hd, name_(args__))
    @assert captured

    body = postwalk_rvalues(body) do e
        if @capture(e, gensym())
            println("found sym! $(e)")
            quote
                begin
                    sym = $e
                    sym_to_source[sym] = "$(@__FILE__):$(@__LINE__)"
                    sym
                end
            end
        else
            e
        end
    end
    # wrap all rvalue unquotes in a block to track more line nums
    body = postwalk_rvalues(body) do e
        if e isa Expr && e.head == :$
            println("found unquote! $(e)")
            quote
                begin
                    sym_to_source[length(sym_to_source) + 1] = string(@__FILE__) * ":" * string(@__LINE__)
                    # sym_to_source[QuoteNode($e)] = string(@__FILE__) * ":" * string(@__LINE__)
                    e
                end
            end
        else
            e
        end
    end
    macro_source = quote
        macro $(esc(name))($([esc(arg) for arg in args]...))
            $(esc(body))
        end
    end
    macro_to_source[name] = esc(macro_source)
    macro_source
end

meta = @macroexpand begin
    @livemacro fill_assign(var, x, N) begin
        # println(@__FILE__, ":", @__LINE__)
        x_computed = gensym()
        quote
            $(x_computed) = $(x)
            $(esc(var)) = [$([
                :[$x_computed]
                for _ in 1:N
            ]...)]
        end
    end
end
eval(meta)

println("macro code:")
println(prettify(meta))

println()
println("expanded:")
expanded = prettify(@macroexpand @fill_assign arr f() 3)
code = string(expanded)
println(code)

# open("/tmp/macrocode.jl", "w") do file
#     println(file, macro_to_source[:fill_assign])
# end
# println("macroexpand")
# println(sym_to_source)
