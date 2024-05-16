# Live Julia macros

Instead of defining a macro like so:
```julia
macro fill_assign(var, x, N)
    x_computed = gensym()
    quote
        $x_computed = $x
        $(esc(var)) = [$([
            :[$x_computed]
            for _ in 1:N
        ]...)]
    end
end
```

Use `@livemacro` (only first line differs):

```julia
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
```

The macro can be called as normal:
```julia
@fill_assign arr 3 f()
```

But now, we can also debug what each individual quoted expression expands to with `@showmacro`.

```julia
@showmacro @fill_assign arr f() 3
```

Prints:
```
The outer macro call:
    @fill_assign arr f() 3
expanded to
    begin
        var"#17###313" = Main.f()
        arr = [[var"#17###313"], [var"#17###313"], [var"#17###313"]]
    end

====

The contained quote
    quote
        $x_computed = $x
        $(esc(var)) = [$([:([$x_computed]) for _ = 1:N]...)]
    end
expanded to
    begin
        var"##313" = f()
        $(Expr(:escape, :arr)) = [[var"##313"], [var"##313"], [var"##313"]]
    end

====

The contained quote
    :([$x_computed])
expanded to
    [var"##313"]
and
    [var"##313"]
and
    [var"##313"]
```

To try, run `julia test.jl`.