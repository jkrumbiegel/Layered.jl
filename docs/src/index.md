# Layered.jl

Tutorial

```@example tut
using Layered

c, l = canvas(4, 4, bgcolor = "tomato")

c
```

```@example tut
c1 = circle!(l, O, 50) + Fill("teal")

c
```

```@example tut
c2 = circle_first!(l, -X(50), 50) + Fill("orange")

c
```

```@example tut
c3 = circle!(l, Y(80), 20) + Fill("red")

c
```

```@example tut
lines!(outertangents, l, c1, c3)

c
```

```@example tut
txt!(l, c1, c2) do c1, c2
    Txt(between(c1.center, c2.center, 0.5), "hello", 14, :c, :c, deg(0))
end + Textfill("white")

c
```



