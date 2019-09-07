module Layered

using StaticArrays
import Colors
using Match
import Juno
import Cairo

export Transform, Layer, Shape, upward_transform, solve!, →, Angle, rad, deg, needed_attributes

include("types.jl")
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


for geom in (:Circle, :Rect, :Point, :Points, :Arc, :Bezier, :Path, :Paths, :Line, :Polygon, :Polygons, :Txt, :LineSegments)

    lowerc = Symbol(lowercase(String(geom)))
    lowerc_exc = Symbol(lowercase(String(geom)) * "!")
    lowerc_first_exc = Symbol(lowercase(String(geom)) * "_first!")


    @eval begin
        $lowerc(args...) = Shape($geom, args...)

        function $lowerc_exc(layer::Layer, args...)
            x = $lowerc(args...)
            push!(layer, x)
            x
        end

        function $lowerc_first_exc(layer::Layer, args...)
            x = $lowerc(args...)
            pushfirst!(layer, x)
            x
        end

        $lowerc(f::Function, args...) = Shape(f, $geom, args...)

        function $lowerc_exc(f::Function, layer::Layer, args...)
            x = $lowerc(f, args...)
            push!(layer, x)
            x
        end

        function $lowerc_first_exc(f::Function, layer::Layer, args...)
            x = $lowerc(f, args...)
            pushfirst!(layer, x)
            x
        end

        export $geom, $lowerc, $lowerc_exc, $lowerc_first_exc

    end
end

end # module
