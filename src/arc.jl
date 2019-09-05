export Arc, arc, arc!, fraction, arclength, intersection

function Arc(from::Point, through::Point, to::Point)
    circle = Circle(from, through, to)
    start_angle = angle(from_to(circle.center, from))
    end_angle = angle(from_to(circle.center, to))

    # correct for the angle points being incorrectly transformed on the unit circle
    is_cw = rad(signed_angle_to(through → from, through → to)) >= 0
    if is_cw && end_angle > start_angle
        end_angle -= rad(2π)
    elseif !is_cw && end_angle < start_angle
        end_angle += rad(2π)
    end

    Arc(circle.center, circle.radius, start_angle, end_angle)
end

function Arc(from::Point, to::Point, radiusfraction::Real)
    heightpoint = between(from, to, 0.5) + rotate(from → to, deg(90)) * radiusfraction / 2
    arc = Arc(from, heightpoint, to)
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
    angle = a.start_angle + (a.end_angle - a.start_angle) * f
    a.center + Point(angle) * a.radius
end

function fractionangle(a::Arc, f::Real)
    angle = a.start_angle + (a.end_angle - a.start_angle) * f
end

needed_attributes(::Type{Arc}) = (Visible, Linewidth, Stroke, Linestyle)

function arclength(a::Arc)
    a.radius * abs(rad(a.end_angle - a.start_angle))
end

function lengthen(a::Arc, ang::Angle)
    Arc(a.center, a.radius, a.start_angle, a.end_angle + ang)
end

function intersection(a::Arc, l::Line)
    c = Circle(a.center, a.radius)
    @show c
    points = intersection(c, l)
    angles = angle.(points .- a.center)
    [p for (an, p) in zip(angles, points) if a.start_angle <= an <= a.end_angle]
end
