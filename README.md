### Layered.jl

Layered.jl's purpose is to help with the creation of vector graphics.
There are many packages out there that do this, like Luxor.jl or Compose.jl, so
what is different here?

While Luxor.jl is good for drawing an image stroke by stroke in a sequential
fashion, it is a very manual process in which a lot of thought has to go into the
effect of active transformations on what you're drawing. Also it can be annoying
to constantly switch hues, linewidths, whatever attributes you can think of and
keep track of the state of the Cairo engine.

Compose.jl is good for hierarchically organizing shapes in a tree, where the objects
lower in the tree are probably contained inside larger objects further up, because
they are defined in the context of their parents coordinate systems. This can also
get confusing fast if you're just trying to piece together a graphic bit by
bit and not building a whole plotting package on top of that architecture.

Layered.jl's main goal is to draw graphics with Cairo.jl.
In these graphics, shapes are derived from other shapes, because this is usually how we think about what's in a scene.
For example, drawing two circles and connecting them with their outer tangents, then drawing
text at the center of the tangent lines as annotations. You can calculate this manually,
but if there are coordinate transformations involved along the way, have fun keeping
all those in mind. Maybe one circle exists in a rectangle and its size is defined
relative to the rectangle's width, and the other circle lives in a different
coordinate system that's relative to the canvas boundary. But you still just want to
connect them with lines, and this package should help you do that.

Layered also works with layers, as the name suggests. You put your shapes in layers which
can be nested and keep track of transforms for you. A shape should always exist in a layer
so a circle at (0, 0) with radius 1 can mean different things depending on which layer
it is in.

Because you can add things to layers in any order you want and the graphic is drawn bottom to top in the very end, this can be very helpful to keep the order of your code separate from the
order of visuals. Maybe you want a rectangle that depends on everything else in the scene, but
it's supposed to be below everything. So you can just add it to the lowest layer.

You can also add a shape as a clipping mask on any layer, or any shape living in a different layer, it doesn't matter.

This library is very much a work in progress, so if you find it's lacking some vital functionality, I'm open to suggestions.

Here's an example:
<p align="center">
  <img src="https://raw.githubusercontent.com/jkrumbiegel/Layered.jl/master/examples/01_experimental_paradigm/example.svg?sanitize=true">
</p>
