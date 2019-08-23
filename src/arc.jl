export Arc, arc, arc!, fraction

struct Arc <: GeometricObject
    center::Point
    radius::Float64
    start_angle::Angle
    end_angle::Angle
end

function Arc(p1::Point, p2::Point, p3::Point)
    circle = Circle(p1, p2, p3)
    start_angle = angle(from_to(circle.center, p1))
    end_angle = angle(from_to(circle.center, p3))

    if signed_angle_to(from_to(p1, p3), from_to(p1, p2)) > 0
        start_angle, end_angle = end_angle, start_angle
    end
    Arc(circle.center, circle.radius, start_angle, end_angle)
end

arc(args...) = Shape(Arc(args[1:fieldcount(Arc)]...), args[fieldcount(Arc)+1:end]...)
function arc!(layer::Layer, args...)
    r = arc(args...)
    push!(layer, r)
    r
end
arc(f::Function, args...) = Shape(f, Arc, args...)
function arc!(f::Function, layer::Layer, args...)
    r = arc(f, args...)
    push!(layer, r)
    r
end

function fraction(a::Arc, f::Real)
    angle = (a.end_angle - a.start_angle) / 2
    a.center + Point(angle) * a.radius
end

needed_attributes(::Type{Arc}) = (Linewidth, Stroke, Linestyle)
