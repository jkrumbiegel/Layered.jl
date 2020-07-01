var documenterSearchIndex = {"docs":
[{"location":"#Layered.jl","page":"Start","title":"Layered.jl","text":"","category":"section"},{"location":"","page":"Start","title":"Start","text":"Layered.jl is a library for creating layer-based 2D vector graphics.","category":"page"},{"location":"#Assemble-first,-then-draw","page":"Start","title":"Assemble first, then draw","text":"","category":"section"},{"location":"","page":"Start","title":"Start","text":"Opposed to imperative packages like Luxor.jl or Cairo.jl (which Layered.jl is based on) you assemble a graphic out of layers and shapes before drawing it. This frees you from having to draw all shapes sequentially, from bottom to top.","category":"page"},{"location":"","page":"Start","title":"Start","text":"using Layered\n\nc, l = canvas(200, 200)\n\nl + Stroke(nothing)\n\nl1 = layer!(l)\nl2 = layer!(l)\n\nrect!(l2, O, 100, 100, deg(0)) + Fill(\"teal\")\ncircle!(l1, O, 100) + Fill(\"tomato\")\ncircle!(l2, O, 20) + Fill(\"yellow\")\n\nc","category":"page"},{"location":"#Transforms-and-relative-shapes","page":"Start","title":"Transforms and relative shapes","text":"","category":"section"},{"location":"","page":"Start","title":"Start","text":"Layered.jl uses simple transforms for each layer. You can uniformly scale, translate and rotate, but not skew. This restriction is applied because it makes a circle stay a circle, no matter what layer it is in. Because you can create new shapes based on their relationships to existing shapes, like a tangent from a point in one layer to a circle in another, it's desirable that circles don't turn into ovals along the way.","category":"page"},{"location":"#Attributes","page":"Start","title":"Attributes","text":"","category":"section"},{"location":"","page":"Start","title":"Start","text":"Shapes have attributes such as linewidth, fill color, and line style. Unspecified attributes are inherited from parent layers, freeing you from copying common attributes all over your code.","category":"page"},{"location":"","page":"Start","title":"Start","text":"using Layered\n\nc, l = canvas(300, 300, color = Gray(0.95))\n\ncirc = circle!(l, O, 50)\nrect!(l, O, 120, 120, deg(45))\nline!(l, Y(100), Y(-100))\n\nLayered.svg(c, \"1.svg\")\nc\nnothing # hide","category":"page"},{"location":"","page":"Start","title":"Start","text":"(Image: )","category":"page"},{"location":"","page":"Start","title":"Start","text":"circ + Stroke(\"red\")\nl + Linewidth(4) + Stroke(\"blue\")\n\nc\nLayered.svg(c, \"2.svg\") # hide","category":"page"},{"location":"","page":"Start","title":"Start","text":"(Image: )","category":"page"},{"location":"tutorial/#Layered.jl","page":"Tutorial","title":"Layered.jl","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"First, we create a square canvas. The canvas function returns the canvas and the top layer. There is only one top layer and we add all other layers and shapes to it.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"using Layered\n\ndefaultfont(\"Arial\")\n\nc, l = canvas(250, 250, color = \"tomato\")\nc","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Returning the canvas c displays the image in some environments. Alternatively, you can save a canvas with the svg, pdf or png functions.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"We can add a circle shape to the top layer using circle!. O is a shorthand for origin, i.e., the point (0, 0). Adding Fill(\"teal\") to the returned Shape object sets an attribute.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"c1 = circle!(l, O, 50) + Fill(\"teal\")\n\nc","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"We add another circle, this time with a non-mutating syntax. The returned object is not yet placed in any layer, but we can add it via push! or, as in this example pushfirst!, which means it is placed below the first circle and therefore partially occluded by it.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"There's another attribute Linestyle which we can just add after Fill.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"X(50) is a shorthand for P(50, 0).","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"c2 = circle(-X(50), 50) + Fill(\"orange\") + Linestyle(:dashed)\npushfirst!(l, c2)\n\nc","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Let's add another circle. Y(80) is a shorthand for P(0, 80).","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"c3 = circle!(l, Y(80), 20) + Fill(\"red\")\n\nc","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"We can also pass a function as a first argument to shape methods like circle or lines. The lines function expects an array of Line objects as input. This is returned by the function outertangents, which is called at drawing time with the Circle objects inside c1 and c3.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"All geometric objects used as arguments for such closures are first transformed into the reference space of the layer in which the new shape is placed. In this case, that is just l, so really no transformation is necessary. But through this technique, the two circles could theoretically be in two different layers, and the lines drawn into a third layer, and it would still work.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"lines!(outertangents, l, c1, c3) + Linestyle(:dashed)\n\nc","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"We can also add text. This time we pass the first argument function using the do syntax. In this case, we refer to the c1 circle and we use its center as the text's anchor point.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"\ntxt!(l, c1) do c1\n    Txt(c1.center, \"Layered.jl\", 14, :c, :c, deg(0))\nend + Textfill(\"white\")\n\nc","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"You can also pass a function without arguments if that helps you organize your code a little more neatly. In this case, we create a 2D grid of points and place crosses at these points. The array of cross point vectors is drawn by the polygons function. We use pushfirst! again to put the stars below the other content.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"polys = polygons() do\n    ps = P.(grid(-100:20:100, -100:20:100)...)\n    ncross.(ps, 8, 5, 0.3)\nend + Fill(\"white\", 0.3) + Stroke(nothing)\npushfirst!(l, polys)\n\nc","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"A piece of art, really.","category":"page"}]
}
