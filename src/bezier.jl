export Bezier, bezier, bezier!, horizontalbezier, perpendicularbezier
export BezierPath, bezierpath, bezierpath!
export bracket

struct Bezier <: GeometricObject
    from::Point
    c1::Point
    c2::Point
    to::Point
end

bezier(args...) = Shape(Bezier(args[1:fieldcount(Bezier)]...), args[fieldcount(Bezier)+1:end]...)
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

move(b::Bezier, p::Point) = Bezier(b.from + p, b.c1 + p, b.c2 + p, b.to + p)
Base.:+(b::Bezier, p::Point) = move(b, p)
Base.:+(p::Point, b::Bezier) = move(b, p)

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

struct BezierPath <: GeometricObject
    segments::Vector{Union{Bezier, Line}}
    closed::Bool
end

bezierpath(args...) = Shape(BezierPath(args[1:fieldcount(BezierPath)]...), args[fieldcount(BezierPath)+1:end]...)
bezierpath(f::Function, args...) = Shape(f, BezierPath, args...)
function bezierpath!(layer::Layer, args...)
    b = bezierpath(args...)
    push!(layer, b)
    b
end
bezierpath(f::Function, args...) = Shape(f, BezierPath, args...)
function bezierpath!(f::Function, layer::Layer, args...)
    b = bezierpath(f, args...)
    push!(layer, b)
    b
end

move(b::BezierPath, p::Point) = BezierPath(move.(b.segments, p), b.closed)
Base.:+(b::BezierPath, p::Point) = move(b, p)
Base.:+(p::Point, b::BezierPath) = move(b, p)

function bracket(p1::Point, p2::Point, widthscale::Real = 0.1, innerstrength=1, outerstrength=1; flip=false)
    l = Line(p1, p2)
    perp1 = perpendicular(l, flip)
    tipdist = widthscale * distance(l)
    tipvec = perp1 * tipdist
    tip = fraction(l, 0.5) + tipvec
    bez1 = Bezier(p1, p1 + 0.5tipvec * outerstrength, tip - 0.5tipvec * innerstrength, tip)
    bez2 = Bezier(tip, tip - 0.5tipvec * innerstrength, p2 + 0.5tipvec * outerstrength, p2)
    BezierPath([bez1, bez2], false)
end

needed_attributes(::Type{BezierPath}) = (Linewidth, Stroke, Linestyle, Fill)
