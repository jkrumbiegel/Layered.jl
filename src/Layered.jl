module Layered

using StaticArrays
import Colors
using Match
import Juno

export Point, Transform, Layer, Shape, upward_transform, solve!, →, point, line, Angle, rad, deg, needed_attributes
export Opacity, Operator

include("alltypes.jl")
include("angles.jl")
include("geometry.jl")
include("gradient.jl")
include("attributes.jl")
include("transform.jl")
include("layer.jl")
include("shape.jl")
include("canvas.jl")
include("drawing.jl")
include("video.jl")

Base.Broadcast.broadcastable(g::GeometricObject) = Ref(g)

end # module
