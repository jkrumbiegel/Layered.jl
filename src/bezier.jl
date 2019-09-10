export horizontalbezier, perpendicularbezier
export bracket, arrow, arcarrow
export reversed, concat
export scaleby
export rotate


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

needed_attributes(::Type{Bezier}) = (Linewidth, Stroke, Linestyle, Fill, Visible)

function Path(closed::Bool, segments::Vararg{<: BezierSegment, N}) where N
    Path([segments...], closed)
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


abstract type PathCommand end
struct Move <: PathCommand
    p::Point
end

struct RelMove <: PathCommand
    p::Point
end

struct Lineto <: PathCommand
    p::Point
end

struct RelLineto <: PathCommand
    p::Point
end

struct HLineto <: PathCommand
    x::Float64
end

struct RelHLineto <: PathCommand
    x::Float64
end

struct VLineto <: PathCommand
    x::Float64
end

struct RelVLineto <: PathCommand
    x::Float64
end

struct CurveTo <: PathCommand
    p::Point
end

struct RelCurveTo <: PathCommand
    p::Point
end

struct Close <: PathCommand
end

function Path(svg::String)

    # args = split(svg, r"[\s,]+", keepempty=false)
    args = split(svg, r"((?<=[a-zA-Z])(?=\d)|(?<=\d)(?=[a-zA-Z])|([\s,]+)|((?<=\d)(?=\-))|((?<=[a-zA-Z])(?=\-)))", keepempty=false)

    println(args)

    i = 1

    commands = PathCommand[]
    lastcomm = nothing

    while i <= length(args)

        comm = args[i]

        if isnothing(match(r"[a-zA-Z]", comm))
            comm = lastcomm
            i -= 1
        end

        if comm == "M"
            x, y = parse.(Float64, args[i+1:i+2])
            push!(commands, Move(P(x, y)))
            i += 3
        elseif comm == "m"
            x, y = parse.(Float64, args[i+1:i+2])
            push!(commands, RelMove(P(x, y)))
            i += 3
        elseif comm == "L"
            x, y = parse.(Float64, args[i+1:i+2])
            push!(commands, Lineto(P(x, y)))
            i += 3
        elseif comm == "l"
            x, y = parse.(Float64, args[i+1:i+2])
            push!(commands, RelLineto(P(x, y)))
            i += 3
        elseif comm == "H"
            x = parse(Float64, args[i+1])
            push!(commands, HLineto(x))
            i += 2
        elseif comm == "h"
            x = parse(Float64, args[i+1])
            push!(commands, RelHLineto(x))
            i += 2
        elseif comm == "Z"
            push!(commands, Close())
            i += 1
        elseif comm == "z"
            push!(commands, Close())
            i += 1
        elseif comm == "C"
            x1, y1, x2, y2, x3, y3 = parse.(Float64, args[i+1:i+6])
            push!(commands, CurveTo(P(x1, y1)))
            push!(commands, CurveTo(P(x2, y2)))
            push!(commands, CurveTo(P(x3, y3)))
            i += 7
        elseif comm == "c"
            x1, y1, x2, y2, x3, y3 = parse.(Float64, args[i+1:i+6])
            push!(commands, RelCurveTo(P(x1, y1)))
            push!(commands, RelCurveTo(P(x2, y2)))
            push!(commands, RelCurveTo(P(x3, y3)))
            i += 7
        else
            for c in commands
                println(c)
            end
            error("Parsing $comm not implemented.")
        end

        lastcomm = comm

    end

    Path(commands)

end

function Path(comms::Vector{<:PathCommand})

    segments = BezierSegment[]

    last = O
    closed = false


    i = 1
    while i <= length(comms)

        c = comms[i]

        if typeof(c) <: Move
            last = c.p
            i += 1
        elseif typeof(c) <: Lineto
            curr = c.p
            push!(segments, Line(last, curr))
            last = curr
            i += 1
        elseif typeof(c) <: RelLineto
            curr = last + c.p
            push!(segments, Line(last, curr))
            last = curr
            i += 1
        elseif typeof(c) <: CurveTo
            c1 = c.p
            c2 = comms[i+1].p
            curr = comms[i+2].p
            push!(segments, Bezier(last, c1, c2, curr))
            last = curr
            i += 3
        elseif typeof(c) <: RelCurveTo
            c1 = c.p + last
            c2 = comms[i+1].p + last
            curr = comms[i+2].p + last
            push!(segments, Bezier(last, c1, c2, curr))
            last = curr
            i += 3
        elseif typeof(c) <: Close
            println("broke")
            closed = true
            break
        else
            error("$(typeof(c)) not implemented")
        end
    end

    Path(closed, segments...)

end

Path("M 165.097656 39.6875 L 165.097656 40.3125 L 159.503906 40.3125 L 162.992188 44.683594 L 162.503906 45.074219 L 159.015625 40.699219 L 157.773438 46.152344 L 157.164062 46.015625 L 158.410156 40.5625 L 153.371094 42.988281 L 153.101562 42.425781 L 158.136719 40 L 153.101562 37.574219 L 153.371094 37.011719 L 158.410156 39.4375 L 157.164062 33.984375 L 157.773438 33.847656 L 159.015625 39.300781 L 162.503906 34.925781 L 162.992188 35.316406 L 159.503906 39.6875 Z M 165.097656 39.6875 ")
Path("M500,225.2c73.6,0,133.2,58.1,133.2,129.9c0,71.7-59.6,129.8-133.2,129.8c-73.6,0-133.2-58.1-133.2-129.8C366.8,283.4,426.4,225.2,500,225.2z M852.4,351.7C852.4,162,694.6,10,500,10c-194.6,0-352.4,151.2-352.4,340.8c0,3,0.4,6.5,0.5,6.5h-0.5C143,568.7,397.4,895.1,500,990c102.6-94.9,357-421.3,352.4-632.7h-0.5C852,357.3,852.4,354.7,852.4,351.7z")


function pathtest()

    # svgstr = "M500,225.2c73.6,0,133.2,58.1,133.2,129.9c0,71.7-59.6,129.8-133.2,129.8c-73.6,0-133.2-58.1-133.2-129.8C366.8,283.4,426.4,225.2,500,225.2z M852.4,351.7C852.4,162,694.6,10,500,10c-194.6,0-352.4,151.2-352.4,340.8c0,3,0.4,6.5,0.5,6.5h-0.5C143,568.7,397.4,895.1,500,990c102.6-94.9,357-421.3,352.4-632.7h-0.5C852,357.3,852.4,354.7,852.4,351.7z"
    svgstr = "M 509.18838,395.16009 C 491.67535,410.75205 468.29486,431.4073 437.98958,444.4974 326.88012,492.49442 195.81534,442.33805 145.83768,332.62845 116.00894,267.07372 120.77439,192.09233 157.48325,125.71854 194.41549,58.98735 267.83321,0 267.83321,0 c 0,0 -54.3857,11.64557 -102.50186,34.90693 C 61.02755,85.34624 0,191.09457 0,300.69993 c 0,40.89352 8.5629188,82.4274 26.597171,122.04021 32.688011,71.66046 91.377509,126.40357 165.376019,154.04318 74.05808,27.68429 154.26657,24.89948 226.00149,-7.74385 C 489.93299,536.23232 543.97617,475.1452 572.76247,401.6828 595.91958,342.69546 599.94043,276.60462 600,276.44081 c 0,0 -37.58749,71.19881 -90.81162,118.71928"

    # svgstr = "m61.1 18.2c-6.4-17-27.2-9.4-29.1-.9-2.6-9-22.9-15.7-29.1.9-6.9 18.5 26.7 35.1 29.1 37.8 2.4-2.2 36-19.6 29.1-37.8"
    c, l = canvas(4, 4)

    ll = layer!(l, scale=0.1)

    path!(ll, svgstr)

    c

end; pathtest()
