export Bezier, bezier, horizontalbezier

struct Bezier <: GeometricObject
    from::Point
    c1::Point
    c2::Point
    to::Point
end

bezier(args...) = Shape(Bezier(args[1:4]...), args[5:end]...)
bezier(f::Function, args...) = Shape(f, Bezier, args...)

function horizontalbezier(p1::Point, p2::Point, strength=1)
    diff = p1 → p2
    Bezier(
        p1,
        Point(p1.x + 0.5 * strength * diff.x, p1.y),
        Point(p2.x - 0.5 * strength * diff.x, p2.y),
        p2
    )
end

needed_attributes(::Type{Bezier}) = (Linewidth, Stroke, Linestyle, Fill)
