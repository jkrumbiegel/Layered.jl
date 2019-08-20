module Layered

using StaticArrays

export Point, Transform, Layer, Shape, upward_transform, solve!, →, point

abstract type LayerContent end
abstract type GeometricObject <: LayerContent end

include("transform.jl")
include("layer.jl")
include("shape.jl")
include("geometry.jl")

function Base.:*(t::Transform, p::Point)
    rmat = rotmat(t.rotation)
    Point(rmat * t.scale * p.xy + t.translation)
end

end # module
