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

Use `@livemacro`:

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

This defines the macro as normal, but also allows you to debug what each individual quoted expression expands to with `@showmacro`.

```julia
@showmacro @fill_assign arr f() 3
```

Prints:
```
The outer macro call:
  @fill_assign arr f() 3
expanded to:
  begin
      var"#16###312" = Main.f()
      arr = [[var"#16###312"], [var"#16###312"], [var"#16###312"]]
  end

====

The contained quote:
  quote
      $x_computed = $x
      $(esc(var)) = [$([:([$x_computed]) for _ = 1:N]...)]
  end
expanded to
  begin
      var"##312" = f()
      $(Expr(:escape, :arr)) = [[var"##312"], [var"##312"], [var"##312"]]
  end

====

The contained quote:
  :([$x_computed])
expanded to
  [var"##312"]
and
  [var"##312"]
and
  [var"##312"]
```

To try, run `julia test.jl`.