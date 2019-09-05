export Bezier, bezier, bezier!, horizontalbezier, perpendicularbezier
export Path, path, path!
export Paths, paths, paths!
export bracket, arrow, arcarrow
export reversed, concat
export scaleby
export rotate

struct Bezier <: GeometricObject
    from::Point
    c1::Point
    c2::Point
    to::Point
end

bezier(args...) = Shape(Bezier, args...)
function bezier!(layer::Layer, args...)
    r = bezier(args...)
    push!(layer, r)
    r
end
bezier(f::Function, args...) = Shape(f, Bezier, args...)
function bezier!(f::Function, layer::Layer, args...)
    r = bezier(f, args...)
    push!(layer, r)
    r
end

move(b::Bezier, p::Point) = Bezier(b.from + p, b.c1 + p, b.c2 + p, b.to + p)
scaleby(b::Bezier, by::Real) = Bezier(by * b.from, by * b.c1, by * b.c2, by * b.to)
rotate(b::Bezier, ang::Angle) = Bezier(rotate.([b.from, b.c1, b.c2, b.to], ang)...)
Base.:+(b::Bezier, p::Point) = move(b, p)
Base.:-(b::Bezier, p::Point) = move(b, -p)
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

const BezierSegment = Union{Bezier, Line, Arc}

struct Path <: GeometricObject
    segments::Vector{<:BezierSegment}
    closed::Bool
end

function Path(closed::Bool, segments::Vararg{<: BezierSegment, N}) where N
    Path([segments...], closed)
end

path(args...) = Shape(Path, args...)
function path!(layer::Layer, args...)
    r = path(args...)
    push!(layer, r)
    r
end
path(f::Function, args...) = Shape(f, Path, args...)
function path!(f::Function, layer::Layer, args...)
    r = path(f, args...)
    push!(layer, r)
    r
end

move(b::Path, p::Point) = Path(move.(b.segments, p), b.closed)
Base.:+(b::Path, p::Point) = move(b, p)
Base.:+(p::Point, b::Path) = move(b, p)

function bracket(p1::Point, p2::Point, widthscale::Real = 0.1, innerstrength=1, outerstrength=1; flip=false)
    l = Line(p1, p2)
    perp1 = perpendicular(l, flip)
    tipdist = widthscale * length(l)
    tipvec = perp1 * tipdist
    tip = fraction(l, 0.5) + tipvec
    bez1 = Bezier(p1, p1 + 0.5tipvec * outerstrength, tip - 0.5tipvec * innerstrength, tip)
    bez2 = Bezier(tip, tip - 0.5tipvec * innerstrength, p2 + 0.5tipvec * outerstrength, p2)
    Path([bez1, bez2], false)
end

needed_attributes(::Type{Path}) = (Visible, Linewidth, Stroke, Linestyle, Fill)

struct Paths <: GeometricObject
    paths::Vector{Path}
end

paths(args...) = Shape(Paths, args...)
function paths!(layer::Layer, args...)
    r = paths(args...)
    push!(layer, r)
    r
end
paths(f::Function, args...) = Shape(f, Paths, args...)
function paths!(f::Function, layer::Layer, args...)
    r = paths(f, args...)
    push!(layer, r)
    r
end

needed_attributes(::Type{Paths}) = (Visible, Linewidths, Strokes, Linestyle, Fills)

Base.convert(::Type{Paths}, paths::Vector{Path}) = Paths(paths)

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
    Path([
        Line(endleft, tipconnleft),
        Line(tipconnleft, tipleft),
        Line(tipleft, to),
        Line(to, tipright),
        Line(tipright, tipconnright),
        Line(tipconnright, endright),
        Line(endright, endleft),
    ], false)
end


function Base.convert(::Type{Path}, a::Arc)
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
    Path(segments, false)
end

reversed(b::Bezier) = Bezier(b.to, b.c2, b.c1, b.from)
reversed(b::Path) = Path(reverse!(reversed.(b.segments)), b.closed)

function arcarrow(from::Point, to::Point, radiusfraction::Real, tiplength::Real, tipwidth::Real, tipretraction::Real=0)
    arc = Arc(from, to, radiusfraction)
    alength = arclength(arc)

    tipconnection = fraction(arc, 1 - tiplength / alength)
    tipconnection_retracted = fraction(arc, 1 - tiplength * (1 - tipretraction) / alength)

    arc_retracted = lengthen(arc, (arc.end_angle - arc.start_angle) * -tiplength * (1 - tipretraction) / alength)
    arcbezier = Base.convert(Path, arc_retracted)

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
    Path(segments, false)
end

function concat(bp::Path, paths...)
    segments = vcat((b.segments for b in (bp, paths...))...)
    Path(
        segments,
        false
    )
end

function center(bp::Path)
    com = centerofmass(bp)
    Path([s - com for s in bp.segments], false)
end

function centerofmass(bp::Path)
    p = P(0, 0)

    for s in bp.segments
        p += start(s)
        p += stop(s)
    end

    p /= 2 * length(bp.segments)
end

function scaleby(bp::Path, by::Real)

    Path([scaleby(s, by) for s in bp.segments], false)

end

function rotate(p::Path, ang::Angle)
    Path([rotate(s, ang) for s in p.segments], false)
end
