export Bezier, bezier, bezier!, horizontalbezier, perpendicularbezier

struct Bezier <: GeometricObject
    from::Point
    c1::Point
    c2::Point
    to::Point
end

bezier(args...) = Shape(Bezier(args[1:4]...), args[5:end]...)
bezier(f::Function, args...) = Shape(f, Bezier, args...)
function bezier!(layer::Layer, args...)
    b = bezier(args...)
    push!(layer, b)
    b
end
bezier(f::Function, args...) = Shape(f, Bezier, args...)
function bezier!(f::Function, layer::Layer, args...)
    b = bezier(f, args...)
    push!(layer, b)
    b
end

function horizontalbezier(p1::Point, p2::Point, strength=1)
    diff = p1 → p2
    Bezier(
        p1,
        Point(p1.x + 0.5 * strength * diff.x, p1.y),
        Point(p2.x - 0.5 * strength * diff.x, p2.y),
        p2
    )
end

function perpendicularbezier(l1::Line, l2::Line, fraction1=0.5, fraction2=0.5; strength=1, reverse1=false, reverse2=false)
    fpoint1 = fraction(l1, fraction1)
    fpoint2 = fraction(l2, fraction2)
    perpendicular1 = perpendicular(l1, reverse1)
    perpendicular2 = perpendicular(l2, reverse2)
    dist = magnitude(fpoint1 → fpoint2)
    c1 = fpoint1 + perpendicular1 * 0.5dist * strength
    c2 = fpoint2 + perpendicular2 * 0.5dist * strength
    Bezier(fpoint1, c1, c2, fpoint2)
end

needed_attributes(::Type{Bezier}) = (Linewidth, Stroke, Linestyle, Fill)
