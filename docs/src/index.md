# Layered.jl

`Layered.jl` is a library for creating layer-based 2D vector graphics.

## Assemble first, then draw

Opposed to imperative packages like `Luxor.jl` or `Cairo.jl` (which `Layered.jl` is based on) you assemble a graphic out of layers and shapes before drawing it. This frees you from having to draw all shapes sequentially, from bottom to top.

## Transforms and relative shapes

`Layered.jl` uses simple transforms for each layer. You can uniformly scale, translate and rotate, but not skew. This keeps any circle a circle, no matter what layer it is in. That in turn allows you to refer to geometric objects across different layers to build up your graphic.

## Attributes

Things like linewidths, fill colors, and so on can be assigned to each shape. Unspecified attributes are inherited from parent layers, freeing you from copying common attributes all over your code.