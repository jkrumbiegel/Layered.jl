module Layered

using StaticArrays
import Colors

export Point, Transform, Layer, Shape, upward_transform, solve!, →, point, line, Angle, rad, deg, needed_attributes

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

function Base.:*(t::Transform, p::Point)
    rmat = rotmat(t.rotation)
    Point(rmat * t.scale * p.xy + t.translation)
end

function Base.:*(t::Transform, ps::Points)
    mat = rotmat(t.rotation) * t.scale
    Points([Point(mat * p.xy + t.translation) for p in ps.points])
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

function Base.:*(t::Transform, bp::Path)
    Path(BezierSegment[t * s for s in bp.segments], bp.closed)
end

function Base.:*(t::Transform, bps::Paths)
    Paths(t .* bps.paths)
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
