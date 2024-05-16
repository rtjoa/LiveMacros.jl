include("lib.jl")

@livemacro fill_assign(var, x, N) begin
    x_computed = gensym()
    quote
        $x_computed = $x
        $(esc(var)) = [$([
            :[$x_computed]
            for _ in 1:N
        ]...)]
    end
end

@fill_assign arr 5 3
println(arr) # [[5], [5], [5]]

@showmacro @fill_assign arr f() 3
