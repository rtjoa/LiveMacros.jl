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
            ),
            e
        )
    else
        e
    end
end

function prewalk_rvalues(f, e)
    if @capture(e, lhs_ = rhs_)
        :($(lhs) = $(prewalk_rvalues(f, rhs)))
    elseif e isa Expr
        e = f(e)
        Expr(
            e.head,
            [prewalk_rvalues(f, arg) for arg in e.args]...
        )
    else
        e
    end
end


source_to_expansions = Dict()
macro_to_source = Dict()
macro_to_orig_source = Dict()
macro livemacro(hd, body)
    captured = @capture(hd, name_(args__))
    @assert captured

    macro_to_orig_source[name] = quote
        macro $(esc(name))($([esc(arg) for arg in args]...))
            $(esc(body))
        end
    end

    body = postwalk_rvalues(body) do e, orig_e
        if @capture(e, :(quoted_))
            # println("found quoted! $(quoted)")
            quote
                get!(source_to_expansions, $(QuoteNode(orig_e)), [])
                expansion = $e
                push!(source_to_expansions[$(QuoteNode(orig_e))], expansion)
                expansion
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

function indent(lines)
    join([
        "    $(line)"
        for line in split(lines, "\n")
    ], "\n")
end

walkrmlines(e) = postwalk(rmlines, e)

macro showmacro(args...)
    println("The outer macro call:")
    println(indent((join([rmlines(arg) for arg in args], " "))))
    println("expanded to")
    empty!(source_to_expansions)
    quote
        println(indent(string(walkrmlines(@macroexpand $(args...)))))

        for (source, expansions) in source_to_expansions
            println()
            println("====")
            println()
            source = walkrmlines(source)
            println("The contained quote")
            println(indent("$(source)"))
            println("expanded to")
            println(join(
                [
                    indent("$(walkrmlines(expansion))")
                    for expansion in expansions
                ], "\nand\n"
            ))
        end
    end
end
