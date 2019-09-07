export move, normal, normfrom, direction


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
Base.angle(l::Line) = angle(vector(l))
Base.length(l::Line) = magnitude(vector(l))
fraction(l::Line, frac::Real) = between(l.from, l.to, frac)
reversed(l::Line) = Line(l.to, l.from)
direction(l::Line) = normalize(vector(l))
normal(l::Line, reverse::Bool=false) = rotate(direction(l), reverse ? deg(-90) : deg(90))
normal(l::Line, length::Real) = normal(l, false) * length
normfrom(l::Line, frac::Real, length::Real) = fraction(l, frac) + normal(l, length)
move(l::Line, p::Point) = Line(l.from + p, l.to + p)
Base.:+(l::Line, p::Point) = move(l, p)
Base.:+(p::Point, l::Line) = move(l, p)

scaleby(l::Line, by::Real) = Line(by * s.from, by * s.to)

function scale(l::Line, scalar::Real)
    movement = (scalar - 1) * vector(l) / 2
    Line(l.from - movement, l.to + movement)
end

function scaleto(l::Line, len::Real)
    scalar = len / length(l)
    scale(l, scalar)
end

function extend(l::Line, len::Real, fraction_to::Real=0.5)
    vec = len * direction(l)
    movement_to = fraction_to * vec
    movement_from = (1 - fraction_to) * vec
    Line(l.from - movement_from, l.to + movement_to)
end

function rotate(l::Line, angle::Angle; around::Point=Point(0, 0))
    Line(
        rotate(l.from, angle, around=around),
        rotate(l.to, angle, around=around)
    )
end

needed_attributes(::Type{Line}) = (Visible, Linewidth, Stroke, Linestyle)

needed_attributes(::Type{LineSegments}) = (Visible, Linewidth, Stroke, Linestyle)

Base.convert(::Type{LineSegments}, ls::Vector{Line}) = LineSegments(ls)
