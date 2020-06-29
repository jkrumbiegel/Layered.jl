# Layered.jl

`Layered.jl` is a library for creating layer-based 2D vector graphics.

## Assemble first, then draw

Opposed to imperative packages like `Luxor.jl` or `Cairo.jl` (which `Layered.jl` is based on) you assemble a graphic out of layers and shapes before drawing it. This frees you from having to draw all shapes sequentially, from bottom to top.

```@example
using Layered

c, l = canvas(200, 200)

l + Stroke(nothing)

l1 = layer!(l)
l2 = layer!(l)

rect!(l2, O, 100, 100, deg(0)) + Fill("teal")
circle!(l1, O, 100) + Fill("tomato")
circle!(l2, O, 20) + Fill("yellow")

c
```

## Transforms and relative shapes

`Layered.jl` uses simple transforms for each layer. You can uniformly scale, translate and rotate, but not skew. This restriction is applied because it makes a circle stay a circle, no matter what layer it is in. Because you can create new shapes based on their relationships to existing shapes, like a tangent from a point in one layer to a circle in another, it's desirable that circles don't turn into ovals along the way.

```@example
using Layered

c, l = canvas(200, 200)

layers = map(-50:50:50, -15:15:15) do x, ang
    layer!(l, translation = X(x), rotation = deg(ang))
end

rs = map(layers) do l
    rect!(l, O, 50, 50)
end .+ Fill.(["tomato", "teal", "bisque"])

ts = map(layers, ["one", "two", "three"]) do l, s
    txt!(l, O, s, 14, :c, :c)
end

p = point!(l, Y(90)) + Fill("orange")

arrs = map(rs) do r
    path!(l, r, p) do r, p
        arrow(p, topleft(r), 6, 6, 2, 2, 0)
    end
end .+ Fill("black") .+ Stroke(nothing)

c
```

## Attributes

Shapes have attributes such as linewidth, fill color, and line style. Unspecified attributes are inherited from parent layers, freeing you from copying common attributes all over your code.


```@example attrs
using Layered

c, l = canvas(300, 300, color = Gray(0.95))

circ = circle!(l, O, 50)
rect!(l, O, 120, 120, deg(45))
line!(l, Y(100), Y(-100))

c
Layered.svg(c, "1.svg") # hide
```
![](1.svg)

```@example attrs
circ + Stroke("red")
l + Linewidth(4) + Stroke("blue")

c
Layered.svg(c, "2.svg") # hide
```

![](2.svg)