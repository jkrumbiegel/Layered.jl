export horizontalbezier, perpendicularbezier
export bracket, arrow, arcarrow
export reversed, concat
export rotate
export centeredin


Base.:*(b::Bezier, r::Real) = Bezier(r * b.from, r * b.c1, r * b.c2, r * b.to)
Base.:+(b::Bezier, p::Point) = Bezier(b.from + p, b.c1 + p, b.c2 + p, b.to + p)
Base.:-(b::Bezier, p::Point) = Bezier(b.from - p, b.c1 - p, b.c2 - p, b.to - p)
rotate(b::Bezier, ang::Angle) = Bezier(rotate.((b.from, b.c1, b.c2, b.to), ang)...)

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

# function Path(closed::Bool, segments::Vararg{<: BezierSegment, N}) where N
#     Path([segments...], closed)
# end

Base.:+(path::Path, p::Point) = Path(path.commands .+ p)
Base.:-(path::Path, p::Point) = Path(path.commands .- p)
Base.:*(path::Path, r::Real) = Path(path.commands .* r)
Base.:*(r::Real, path::Path) = Path(path.commands .* r)

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
        Move(endleft),
        Lineto(tipconnleft),
        Lineto(tipleft),
        Lineto(to),
        Lineto(tipright),
        Lineto(tipconnright),
        Lineto(endright),
        Close()
    ])
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

function rotate(p::Path, ang::Angle)
    Path(rotate.(p.commands, ang))
end

continuecommands(l::Line) = PathCommand[Lineto(stop(l))]
continuecommand(b::Bezier) = CurveTo(b.c1, b.c2, b.to)
continuecommands(b::Bezier) = PathCommand[continuecommand(b)]
function continuecommands(a::Arc)
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
    PathCommand[continuecommand.(segments)...]
end

function Path(segments::Vector{T}) where T <:Union{Line, Bezier, Arc}

    laststop = nothing
    commands = PathCommand[]

    i = 1
    while i <= length(segments)
        seg = segments[i]

        if i == 1 || !(start(seg) ≈ laststop)
            push!(commands, Move(start(seg)))
        end

        append!(commands, continuecommands(seg))
        laststop = stop(seg)

        i += 1

    end

    if laststop ≈ start(segments[1])
        # replace first value so start and stop are exactly the same
        commands[1] = Move(laststop)
        push!(commands, Close())
    end

    Path(commands)

end

function Path(svg::AbstractString)

    # args = split(svg, r"[\s,]+", keepempty=false)
    # args = split(svg, r"((?<=[a-zA-Z])(?=\d)|(?<=\d)(?=[a-zA-Z])|([\s,]+)|((?<=\d)(?=\-))|((?<=[a-zA-Z])(?=\-)))|((?<=\.\d+))", keepempty=false)
    args = [e.match for e in eachmatch(r"([a-zA-Z])|(\-?\d*\.?\d+)", svg)]

    i = 1

    commands = PathCommand[]
    lastcomm = nothing
    lastp() = isnothing(lastcomm) ? O : commands[end].p

    while i <= length(args)

        comm = args[i]

        # command letter is omitted, use last command
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
            push!(commands, Move(P(x, y) + lastp()))
            i += 3
        elseif comm == "L"
            x, y = parse.(Float64, args[i+1:i+2])
            push!(commands, Lineto(P(x, y)))
            i += 3
        elseif comm == "l"
            x, y = parse.(Float64, args[i+1:i+2])
            push!(commands, Lineto(P(x, y) + lastp()))
            i += 3
        elseif comm == "H"
            x = parse(Float64, args[i+1])
            push!(commands, Lineto(P(x, lastp().y)))
            i += 2
        elseif comm == "h"
            x = parse(Float64, args[i+1])
            push!(commands, Lineto(X(x) + lastp()))
            i += 2
        elseif comm == "Z"
            push!(commands, Close())
            i += 1
        elseif comm == "z"
            push!(commands, Close())
            i += 1
        elseif comm == "C"
            x1, y1, x2, y2, x3, y3 = parse.(Float64, args[i+1:i+6])
            push!(commands, CurveTo(P(x1, y1), P(x2, y2), P(x3, y3)))
            i += 7
        elseif comm == "c"
            x1, y1, x2, y2, x3, y3 = parse.(Float64, args[i+1:i+6])
            l = lastp()
            push!(commands, CurveTo(P(x1, y1) + l, P(x2, y2) + l, P(x3, y3) + l))
            i += 7
        elseif comm == "S"
            x1, y1, x2, y2 = parse.(Float64, args[i+1:i+4])
            prev_control = commands[end-1]
            prev = commands[end]
            reflected = prev.p + (prev_control → prev.p)
            push!(commands, CurveTo(reflected, P(x1, y1), P(x2, y2)))
            i += 5
        elseif comm == "s"
            x1, y1, x2, y2 = parse.(Float64, args[i+1:i+4])
            prev_control = commands[end-1]
            prev = commands[end]
            reflected = prev.p + (prev_control.p → prev.p)
            l = lastp()
            push!(commands, CurveTo(reflected, P(x1, y1) + l, P(x2, y2) + l))
            i += 5
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

function Path(ps::AbstractArray{Point}, closed::Bool=false)
    segs = [Move(ps[1]), Lineto.(ps[2:end])...]
    closed && push!(segs, Close())
    Path(segs)
end

function Path(xs::AbstractArray, ys::AbstractArray, closed::Bool=false)
    Path(P.(xs, ys), closed)
end


function bbox(b::Bezier)

    p0 = [b.from.xy...]
    p1 = [b.c1.xy...]
    p2 = [b.c2.xy...]
    p3 = [b.to.xy...]

    mi = min.(p0, p3)
    ma = max.(p0, p3)

    c = -p0 + p1
    b =  p0 - 2p1 + p2
    a = -p0 + 3p1 - 3p2 + 1p3

    h = b.*b - a.*c

    if h[1] > 0
        h[1] = sqrt(h[1])
        t = (-b[1] - h[1]) / a[1]
        if t > 0 && t < 1
            s = 1.0-t
            q = s*s*s*p0[1] + 3.0*s*s*t*p1[1] + 3.0*s*t*t*p2[1] + t*t*t*p3[1]
            mi[1] = min(mi[1],q)
            ma[1] = max(ma[1],q)
        end
        t = (-b[1] + h[1])/a[1]
        if t>0 && t<1
            s = 1.0-t
            q = s*s*s*p0[1] + 3.0*s*s*t*p1[1] + 3.0*s*t*t*p2[1] + t*t*t*p3[1]
            mi[1] = min(mi[1],q)
            ma[1] = max(ma[1],q)
        end
    end

    if h[2]>0.0
        h[2] = sqrt(h[2])
        t = (-b[2] - h[2])/a[2]
        if t>0.0 && t<1.0
            s = 1.0-t
            q = s*s*s*p0[2] + 3.0*s*s*t*p1[2] + 3.0*s*t*t*p2[2] + t*t*t*p3[2]
            mi[2] = min(mi[2],q)
            ma[2] = max(ma[2],q)
        end
        t = (-b[2] + h[2])/a[2]
        if t>0.0 && t<1.0
            s = 1.0-t
            q = s*s*s*p0[2] + 3.0*s*s*t*p1[2] + 3.0*s*t*t*p2[2] + t*t*t*p3[2]
            mi[2] = min(mi[2],q)
            ma[2] = max(ma[2],q)
        end
    end

    BBox(P(mi...), P(ma...))
end

function bbox(bboxes::Array{BBox})
    mi = [bboxes[1].from.xy...]
    ma = [bboxes[1].to.xy...]

    for i in 2:length(bboxes)
        mi .= min.(mi, bboxes[i].from.xy)
        ma .= max.(ma, bboxes[i].to.xy)
    end
    BBox(P(mi...), P(ma...))
end

function segments(p::Path)
    segs = []
    last = nothing
    for c in p.commands
        if typeof(c) <: Move
            last = c.p
        elseif typeof(c) <: Lineto
            push!(segs, Line(last, c.p))
            last = c.p
        elseif typeof(c) <: CurveTo
            push!(segs, Bezier(last, c.c1, c.c2, c.p))
            last = c.p
        elseif typeof(c) <: Close
            # what doing
        end
    end
    segs
end

bbox(p::Path) = bbox(bbox.(segments(p)))

function centeredin(p::Path, squarelength::Real)
    bb = bbox(p)
    r = Rect(bb)
    factor = squarelength / max(r.width, r.height)
    (p - r.center) * factor
end

Base.:+(m::Move, p::Point) = Move(m.p + p)
Base.:+(l::Lineto, p::Point) = Lineto(l.p + p)
Base.:+(c::CurveTo, p::Point) = CurveTo(c.c1 + p, c.c2 + p, c.p + p)
Base.:+(c::Close, p::Point) = c

Base.:-(m::Move, p::Point) = Move(m.p - p)
Base.:-(l::Lineto, p::Point) = Lineto(l.p - p)
Base.:-(c::CurveTo, p::Point) = CurveTo(c.c1 - p, c.c2 - p, c.p - p)
Base.:-(c::Close, p::Point) = c

Base.:*(m::Move, s::Real) = Move(m.p * s)
Base.:*(l::Lineto, s::Real) = Lineto(l.p * s)
Base.:*(c::CurveTo, s::Real) = CurveTo(c.c1 * s, c.c2 * s, c.p * s)
Base.:*(c::Close, s::Real) = c

Base.:*(s::Real, m::Move) = m * s
Base.:*(s::Real, l::Lineto) = l * s
Base.:*(s::Real, c::CurveTo) = c * s
Base.:*(s::Real, c::Close) = c * s

rotate(m::Move, a::Angle) = Move(rotate(m.p, a))
rotate(l::Lineto, a::Angle) = Lineto(rotate(l.p, a))
rotate(c::CurveTo, a::Angle) = CurveTo(rotate.([c.c1, c.c2, c.p], a)...)
rotate(c::Close, a::Angle) = c
