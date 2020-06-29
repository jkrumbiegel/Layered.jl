# Layered.jl

First, we create a square canvas. The `canvas` function returns the canvas and the top layer.
There is only one top layer and we add all other layers and shapes to it.

```@example tut
using Layered

defaultfont("Arial")

c, l = canvas(250, 250, color = "tomato")
c
```

Returning the canvas `c` displays the image in some environments. Alternatively, you can save a canvas with the `svg`, `pdf` or `png` functions.

We can add a circle shape to the top layer using `circle!`. `O` is a shorthand for origin, i.e., the point (0, 0). Adding `Fill("teal")` to the returned `Shape` object sets an attribute.

```@example tut
c1 = circle!(l, O, 50) + Fill("teal")

c
```

You can see that the circle also has a black stroke, which it inherited from the default attributes of the top layer.

We add another circle, this time with a non-mutating syntax. The returned object is not yet placed in any layer, but we can add it via `push!` or, as in this example `pushfirst!`, which means it is placed below the first circle and therefore partially occluded by it.

There's another attribute `Linestyle` which we can just add after `Fill`.

`X(50)` is a shorthand for `P(50, 0)`.

```@example tut
c2 = circle(-X(50), 50) + Fill("orange") + Linestyle(:dashed)
pushfirst!(l, c2)

c
```

Let's add another circle. `Y(80)` is a shorthand for `P(0, 80)`.

```@example tut
c3 = circle!(l, Y(80), 20) + Fill("red")

c
```

We can also pass a function as a first argument to shape methods like `circle` or `lines`. The `lines` function expects an array of `Line` objects as input. This is returned by the function `outertangents`, which is called at drawing time with the `Circle` objects inside `c1` and `c3`.

 All geometric objects used as arguments for such closures are first transformed into the reference space of the layer in which the new shape is placed. In this case, that is just `l`, so really no transformation is necessary. But through this technique, the two circles could theoretically be in two different layers, and the lines drawn into a third layer, and it would still work.

```@example tut
lines!(outertangents, l, c1, c3) + Linestyle(:dashed)

c
```

We can also add text. This time we pass the first argument function using the `do` syntax. In this case, we refer to the `c1` circle and we use its center as the text's anchor point.

```@example tut

txt!(l, c1) do c1
    Txt(c1.center, "Layered.jl", 14, :c, :c, deg(0))
end + Textfill("white")

c
```

You can also pass a function without arguments if that helps you organize your code a little more neatly. In this case, we create a 2D `grid` of points and place crosses at these points. The array of cross point vectors is drawn by the `polygons` function. We use `pushfirst!` again to put the stars below the other content.

```@example tut
polys = polygons() do
    ps = P.(grid(-100:20:100, -100:20:100)...)
    ncross.(ps, 8, 5, 0.3)
end + Fill("white", 0.3) + Stroke(nothing)
pushfirst!(l, polys)

c
```

A piece of art, really.



