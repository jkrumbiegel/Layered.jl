export Bezier, bezier, bezier!, horizontalbezier, perpendicularbezier
export BezierPath, bezierpath, bezierpath!
export BezierPaths, bezierpaths, bezierpaths!
export bracket, arrow, arcarrow

struct Bezier <: GeometricObject
    from::Point
    c1::Point
    c2::Point
    to::Point
end

bezier(args...) = Shape(Bezier(args[1:fieldcount(Bezier)]...), args[fieldcount(Bezier)+1:end]...)
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

const BezierSegment = Union{Bezier, Line}

struct BezierPath <: GeometricObject
    segments::Vector{<:BezierSegment}
    closed::Bool
end

bezierpath(args...) = Shape(BezierPath(args[1:fieldcount(BezierPath)]...), args[fieldcount(BezierPath)+1:end]...)
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
    tipdist = widthscale * length(l)
    tipvec = perp1 * tipdist
    tip = fraction(l, 0.5) + tipvec
    bez1 = Bezier(p1, p1 + 0.5tipvec * outerstrength, tip - 0.5tipvec * innerstrength, tip)
    bez2 = Bezier(tip, tip - 0.5tipvec * innerstrength, p2 + 0.5tipvec * outerstrength, p2)
    BezierPath([bez1, bez2], false)
end

needed_attributes(::Type{BezierPath}) = (Visible, Linewidth, Stroke, Linestyle, Fill)

struct BezierPaths <: GeometricObject
    paths::Vector{BezierPath}
end

bezierpaths(args...) = Shape(BezierPaths(args[1:fieldcount(BezierPaths)]...), args[fieldcount(BezierPaths)+1:end]...)
function bezierpaths!(layer::Layer, args...)
    b = bezierpaths(args...)
    push!(layer, b)
    b
end
bezierpaths(f::Function, args...) = Shape(f, BezierPaths, args...)
function bezierpaths!(f::Function, layer::Layer, args...)
    b = bezierpaths(f, args...)
    push!(layer, b)
    b
end

needed_attributes(::Type{BezierPaths}) = (Visible, Linewidths, Strokes, Linestyle, Fills)

Base.convert(::Type{BezierPaths}, paths::Vector{BezierPath}) = BezierPaths(paths)

function arrow(from::Point, to::Point, tiplength, tipwidth, shaftwidthback, shaftwidthfront, tipretraction)
    vector = from → to
    tipconnection = to - normalize(vector) * tiplength
    tipconnection_retracted = to - normalize(vector) * tiplength * (1-tipretraction)
    ortholeft = normalize(rotate(vector, deg(90)))
    tipleft = tipconnection + 0.5tipwidth * ortholeft
    tipright = tipconnection - 0.5tipwidth * ortholeft
    endleft = from + 0.5shaftwidthback * ortholeft
    endright = from - 0.5shaftwidthback * ortholeft
    tipconnleft = tipconnection_retracted + 0.5shaftwidthfront * ortholeft
    tipconnright = tipconnection_retracted - 0.5shaftwidthfront * ortholeft
    BezierPath([
        Line(endleft, tipconnleft),
        Line(tipconnleft, tipleft),
        Line(tipleft, to),
        Line(to, tipright),
        Line(tipright, tipconnright),
        Line(tipconnright, endright),
        Line(endright, endleft),
    ], false)
end


function Base.convert(::Type{BezierPath}, a::Arc)
    # https://stackoverflow.com/a/44829356/2279303

    function uptoquarter(center, p1, p2)
        x1, y1 = p1.xy
        x4, y4 = p2.xy
        xc, yc = center.xy

        ax = x1 - xc
        ay = y1 - yc
        bx = x4 - xc
        by = y4 - yc
        q1 = ax * ax + ay * ay
        q2 = q1 + ax * bx + ay * by
        k2 = 4/3 * (√(2 * q1 * q2) - q2) / (ax * by - ay * bx)


        x2 = xc + ax - k2 * ay
        y2 = yc + ay + k2 * ax
        x3 = xc + bx + k2 * by
        y3 = yc + by - k2 * bx
        Bezier(p1, P(x2, y2), P(x3, y3), p2)
    end

    quarterfractions = (a.end_angle - a.start_angle) / deg(90)
    nsegments=ceil(abs(quarterfractions))

    points = [fraction(a, i / nsegments) for i in 0:nsegments]
    segments = [uptoquarter(a.center, p1, p2) for (p1, p2) in zip(points[1:end-1], points[2:end])]
    BezierPath(segments, false)
end

reversed(b::Bezier) = Bezier(b.to, b.c2, b.c1, b.from)
reversed(b::BezierPath) = BezierPath(reverse!(reversed.(b.segments)), b.closed)

function arcarrow(from::Point, to::Point, radiusfraction::Real, tiplength::Real, tipwidth::Real, tipretraction::Real=0)
    arc = Arc(from, to, radiusfraction)
    alength = arclength(arc)

    tipconnection = fraction(arc, 1 - tiplength / alength)
    tipconnection_retracted = fraction(arc, 1 - tiplength * (1 - tipretraction) / alength)

    arc_retracted = lengthen(arc, (arc.end_angle - arc.start_angle) * -tiplength * (1 - tipretraction) / alength)
    arcbezier = Base.convert(BezierPath, arc_retracted)

    ortholeft = normalize(rotate(tipconnection → to, deg(90)))
    tipleft = tipconnection + 0.5tipwidth * ortholeft
    tipright = tipconnection - 0.5tipwidth * ortholeft

    segments = BezierSegment[
        arcbezier.segments...,
        Line(tipconnection_retracted, tipright),
        Line(tipright, to),
        Line(to, tipleft),
        Line(tipleft, tipconnection_retracted),
        reversed(arcbezier).segments...
    ]
    BezierPath(segments, false)
end
