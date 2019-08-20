SVG drawing with conditional connections

Document is a tree structure made from layers
A layer represents just a linear transformation, so translation, scaling and rotation
Transformations only apply to geometry, but not to textsize and linewidth

Geometric objects are supposed to be able to be conditional on other geometry, e.g.,
  - a circle whose center is the top-left corner of a rectangle
  - a line that always connects two circles as their outer tangent

This is supposed to work across layers, so across transformations, to be more
intuitive and how one would normally think about the image.
Therefore, a geometric object can only exist in a layer, because without it it's
not clear what its properties refer to.

When drawing, the whole layer tree would be iterated and any conditional geometry
be evaluated depth first. Then there's a tree of absolutely positioned geometry.
This is then drawn.

The attributes for color, linewidth, fill, etc. are saved in a dict at the top.
At any level settings can be overwritten by other attribute dicts, all unspecified
settings are inherited.
