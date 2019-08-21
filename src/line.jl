struct Line <: GeometricObject
    from::Point
    to::Point
end

xs(l::Line) = SVector(l.from.x, l.to.x)
ys(l::Line) = SVector(l.from.y, l.to.y)

function intersection(l1::Line, l2::Line)
    x1, x2 = xs(l1)
    y1, y2 = ys(l1)
    x3, x4 = xs(l2)
    y3, y4 = ys(l2)
    t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) /
        ((x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4))

    px = x1 + t * (x2 - x1)
    py = y1 + t * (y2 - y1)
    Point(px, py)
end

vector(l::Line) = from_to(l.from, l.to)
angle(l::Line) = angle(vector(l))
length(l::Line) = magnitude(vector(l))
fraction(l::Line, frac::Real) = between(l.from, l.to, frac)
reversed(l::Line) = Line(l.to, l.from)
direction(l::Line) = normalize(vector(l))

function scale(l::Line, scalar::Real)
    movement = (scalar - 1) * vector(l) / 2
    Line(l.from - movement, l.to + movement)
end

function scaleto(l::Line, len::Real)
    scalar = len / length(l)
    scale(l, scalar)
end

function addlength(l::Line, len::Real)
    dir = direction(l)
    movement = len / 2 * dir
    Line(l.from - movement, l.to + movement)
end

function rotate(l::Line, angle::Angle; around::Point=Point(0, 0))
    Line(
        rotate(l.from, angle, around=around),
        rotate(l.to, angle, around=around)
    )
end

line(args...) = Shape(Line(args...))
line(f::Function, args...) = Shape(f, Line, args...)

needed_attributes(::Type{Line}) = (Linewidth, Stroke, Linestyle)
