export scaleby, inverse, from_to, gettransform!

function Transform(;scale=1, rotation=rad(0), translation=(0, 0))
    Transform(scale, rotation, translation)
end

Base.Broadcast.broadcastable(t::Transform) = Ref(t)

function rotmat(ang::Angle)
    SMatrix{2, 2}(cos(ang.rad), sin(ang.rad), -sin(ang.rad), cos(ang.rad))
end

function Base.:*(t1::Transform, t2::Transform)
    rmat = rotmat(t1.rotation)
    scale = t1.scale * t2.scale
    rotation = t2.rotation + t1.rotation
    translation = t1.scale * (rmat * t2.translation) + t1.translation
    Transform(scale, rotation, translation)
end

function Base.:*(t::Transform, r::Real)
    t.scale * r
end

function inverse(t::Transform)
    scale = 1 / t.scale
    rotation = -1 * t.rotation
    rmat = rotmat(rotation)

    translation = -scale * rmat * t.translation
    Transform(scale, rotation, translation)
end

function from_to(t1::Transform, t2::Transform)
    t2 * inverse(t1)
end

function scaleby(t::Transform, s::Real)
    Transform(t.scale * s, t.rotation, t.translation)
end

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

function Base.:*(t::Transform, x::T) where T <: Union{Move, Lineto}
    T(t * x.p)
end

function Base.:*(t::Transform, x::Close)
    x
end

function Base.:*(t::Transform, c::CurveTo)
    CurveTo(t * c.c1, t * c.c2, t * c.p)
end

function Base.:*(t::Transform, bp::Path)
    Path([t * c for c in bp.commands])
end

function Base.:*(t::Transform, p::Polygon)
    Polygon(t .* p.points)
end

function Base.:*(tr::Transform, t::Txt)
    Txt(
        tr * t.pos,
        t.text,
        tr.scale * t.size,
        t.halign,
        t.valign,
        tr.rotation + t.angle,
        t.font,
        tr.scale * t.extent
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
