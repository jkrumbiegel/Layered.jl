module Layered

using StaticArrays

export Point, Transform, Layer, Shape, upward_transform, solve!, →, point, line, Angle, rad, deg, needed_attributes

abstract type LayerContent end
abstract type GeometricObject <: LayerContent end

Base.Broadcast.broadcastable(g::GeometricObject) = Ref(g)

struct Angle
    rad::Float64
end

Base.Broadcast.broadcastable(a::Angle) = Ref(a)

deg(ang::Real) = Angle(deg2rad(ang))
rad(ang::Real) = Angle(ang)
deg(ang::Angle) = rad2deg(ang.rad)
rad(ang::Angle) = ang.rad

Base.:+(a1::Angle, a2::Angle) = Angle(a1.rad + a2.rad)
Base.:-(a1::Angle, a2::Angle) = Angle(a1.rad - a2.rad)
Base.:-(a::Angle) = Angle(-a.rad)
Base.:*(a::Angle, r::Real) = Angle(a.rad * r)
Base.:*(r::Real, a::Angle) = a * r
Base.:/(a::Angle, r::Real) = Angle(a.rad / r)
Base.:/(a1::Angle, a2::Angle) = a1.rad / a2.rad
Base.cos(a::Angle) = cos(a.rad)
Base.sin(a::Angle) = sin(a.rad)
Base.tan(a::Angle) = tan(a.rad)
Base.isless(a1::Angle, a2::Angle) = a1.rad < a2.rad
Base.isgreater(a1::Angle, a2::Angle) = a1.rad > a2.rad
Base.isequal(a1::Angle, a2::Angle) = a1.rad == a2.rad

include("attributes.jl")
include("transform.jl")
include("layer.jl")
include("shape.jl")
include("geometry.jl")
include("canvas.jl")
include("drawing.jl")
include("video.jl")

function Base.:*(t::Transform, p::Point)
    rmat = rotmat(t.rotation)
    Point(rmat * t.scale * p.xy + t.translation)
end

function Base.:*(t::Transform, l::Line)
    Line(t * l.from, t * l.to)
end

function Base.:*(t::Transform, c::Circle)
    Circle(t * c.center, t.scale * c.radius)
end

function Base.:*(t::Transform, r::Rect)
    Rect(t * r.center, t.scale * r.width, t.scale * r.height, r.angle + t.rotation)
end

function Base.:*(t::Transform, b::Bezier)
    Bezier((t .* (b.from, b.c1, b.c2, b.to))...)
end

function Base.:*(t::Transform, bp::BezierPath)
    BezierPath(BezierSegment[t * s for s in bp.segments], bp.closed)
end

function Base.:*(t::Transform, bps::BezierPaths)
    BezierPaths(t .* bps.paths)
end

function Base.:*(t::Transform, ls::LineSegments)
    LineSegments(t .* ls.segments)
end

function Base.:*(t::Transform, p::Polygon)
    Polygon(t .* p.points)
end

function Base.:*(t::Transform, ps::Polygons)
    Polygons(t .* p.polys)
end

function Base.:*(tr::Transform, t::Txt)
    Txt(
        tr * t.pos,
        t.text,
        tr.scale * t.size,
        t.halign,
        t.valign,
        tr.rotation + t.angle,
    )
end

function Base.:*(t::Transform, a::Arc)
    Arc(
        t * a.center,
        t.scale * a.radius,
        t.rotation + a.start_angle,
        t.rotation + a.end_angle,
    )
end

end # module
