module Layered

using StaticArrays

export Point, Transform, Layer, Shape, upward_transform, solve!, →, point, line, Angle, rad, deg

abstract type LayerContent end
abstract type GeometricObject <: LayerContent end

Base.Broadcast.broadcastable(g::GeometricObject) = Ref(g)
Base.Broadcast.broadcastable(s::Shape) = Ref(s)

struct Angle
    rad::Float64
end
deg(ang::Real) = Angle(deg2rad(ang))
rad(ang::Real) = Angle(ang)
Base.:+(a1::Angle, a2::Angle) = Angle(a1.rad + a2.rad)
Base.:-(a1::Angle, a2::Angle) = Angle(a1.rad - a2.rad)
Base.cos(a::Angle) = cos(a.rad)
Base.sin(a::Angle) = sin(a.rad)
Base.tan(a::Angle) = tan(a.rad)

include("transform.jl")
include("layer.jl")
include("shape.jl")
include("geometry.jl")
include("drawing.jl")

function Base.:*(t::Transform, p::Point)
    rmat = rotmat(t.rotation)
    Point(rmat * t.scale * p.xy + t.translation)
end

function Base.:*(t::Transform, c::Circle)
    Circle(t * c.center, t.scale * c.radius)
end

function Base.:*(t::Transform, r::Rect)
    Rect(t * r.center, t.scale * r.width, t.scale * r.height, r.angle + t.rotation)
end

end # module
