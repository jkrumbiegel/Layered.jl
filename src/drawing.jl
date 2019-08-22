import PyPlot

export draw

CLOSEPOLY = 79
CURVE3 = 3
CURVE4 = 4
LINETO = 2
MOVETO = 1

function draw(l::Layer)
    for c in l.content
        draw(c)
    end
end

function getattributes(s::Shape{T}) where T
    needed = needed_attributes(T)
    attributes = Attributes(Dict(attr => getattribute(s, attr) for attr in needed))
end

function getattribute(l::LayerContent, attr)
    if haskey(l.attrs, attr)
        return l.attrs[attr]
    else
        if isnothing(l.parent)
            error("Attribute $(attr) could not be found in the layer chain.")
        else
            return getattribute(l.parent, attr)
        end
    end
end

function draw(s::Shape)
    geom = solve!(s)
    transformed_to_toplevel = upward_transform(s) * geom
    attributes = getattributes(s)
    draw(transformed_to_toplevel, attributes)
end

import Colors

function rgba(c::Colors.Colorant)
    rgba = Colors.RGBA(c)
    Float64.((rgba.r, rgba.g, rgba.b, rgba.alpha))
end

function draw(p::Point, a::Attributes)
    PyPlot.scatter(
        p.x, p.y,
        s = a[Markersize].size,
        color = rgba(a[Stroke].color),
        marker = a[Marker].marker,
    )
end

function PyPlot.matplotlib.path.Path(l::Line; kwargs...)
    vertices = [l.from.xy, l.to.xy]
    codes = UInt8[MOVETO, LINETO]
    PyPlot.matplotlib.path.Path(vertices, codes; kwargs...)
end

function PyPlot.matplotlib.path.Path(ls::LineSegments; kwargs...)
    vertices = SVector{2, Float64}[]
    codes = UInt8[]

    for l in ls.segments
        push!(vertices, l.from.xy)
        push!(vertices, l.to.xy)
        push!(codes, MOVETO)
        push!(codes, LINETO)
    end
    PyPlot.matplotlib.path.Path(vertices, codes; kwargs...)
end

function PyPlot.matplotlib.path.Path(p::Polygon; kwargs...)
    vertices = SVector{2, Float64}[]
    codes = UInt8[]

    push!(vertices, p.points[1].xy)
    push!(codes, MOVETO)

    for po in p.points[2:end]
        push!(vertices, po.xy)
        push!(codes, LINETO)
    end
    PyPlot.matplotlib.path.Path(vertices, codes; kwargs...)
end

function PyPlot.matplotlib.path.Path(bp::BezierPath; kwargs...)
    vertices = SVector{2, Float64}[]
    codes = UInt8[]

    n = length(bp.segments)
    for i in 1:n
        s = bp.segments[i]
        if i == 1
            push!(vertices, s.from)
            push!(codes, MOVETO)
        else
            if s.from != bp.segments[i-1].to
                push!(vertices, s.from)
                push!(codes, MOVETO)
            end
        end
        if typeof(s) <: Bezier
            push!(vertices, s.c1)
            push!(vertices, s.c2)
            push!(vertices, s.to)
            push!(codes, CURVE4)
            push!(codes, CURVE4)
            push!(codes, CURVE4)
        elseif typeof(s) <: Line
            push!(vertices, s.to)
            push!(codes, LINETO)
        end
    end
    PyPlot.matplotlib.path.Path(vertices, codes; kwargs...)
end

function draw(l::Line, a::Attributes)
    path = PyPlot.matplotlib.path.Path(l, closed=false)
    ax = PyPlot.gca()
    pathpatch = PyPlot.matplotlib.patches.PathPatch(
        path,
        edgecolor = rgba(a[Stroke].color),
        linewidth = a[Linewidth].width,
        linestyle = a[Linestyle].style,
    )
    ax.add_patch(pathpatch)
end

function draw(ls::LineSegments, a::Attributes)
    path = PyPlot.matplotlib.path.Path(ls, closed=false)
    pathpatch = PyPlot.matplotlib.patches.PathPatch(
        path,
        edgecolor = rgba(a[Stroke].color),
        linewidth = a[Linewidth].width,
        linestyle = a[Linestyle].style,
    )
    PyPlot.gca().add_patch(pathpatch)
end

function draw(p::Polygon, a::Attributes)
    path = PyPlot.matplotlib.path.Path(p, closed=true)
    pathpatch = PyPlot.matplotlib.patches.PathPatch(
        path,
        edgecolor = rgba(a[Stroke].color),
        linewidth = a[Linewidth].width,
        linestyle = a[Linestyle].style,
        facecolor = rgba(a[Fill].color),
    )
    PyPlot.gca().add_patch(pathpatch)
end


function PyPlot.matplotlib.path.Path(b::Bezier; kwargs...)
    vertices = [b.from.xy, b.c1.xy, b.c2.xy, b.to.xy]
    codes = UInt8[MOVETO, CURVE4, CURVE4, CURVE4]
    PyPlot.matplotlib.path.Path(vertices, codes; kwargs...)
end

function draw(b::Bezier, a::Attributes)
    path = PyPlot.matplotlib.path.Path(b, closed=false)
    ax = PyPlot.gca()
    pathpatch = PyPlot.matplotlib.patches.PathPatch(
        path,
        edgecolor = rgba(a[Stroke].color),
        linewidth = a[Linewidth].width,
        linestyle = a[Linestyle].style,
        facecolor = rgba(a[Fill].color),
    )
    ax.add_patch(pathpatch)
end

function draw(b::BezierPath, a::Attributes)
    path = PyPlot.matplotlib.path.Path(b, closed=b.closed)
    ax = PyPlot.gca()
    pathpatch = PyPlot.matplotlib.patches.PathPatch(
        path,
        edgecolor = rgba(a[Stroke].color),
        linewidth = a[Linewidth].width,
        linestyle = a[Linestyle].style,
        facecolor = rgba(a[Fill].color),
    )
    ax.add_patch(pathpatch)
end

function PyPlot.plot(v::Vector{Point}; kwargs...)
    xx = [p.x for p in v]
    yy = [p.y for p in v]
    PyPlot.plot(xx, yy; kwargs...)
end

function draw(c::Circle, a::Attributes)
    vertices = point_at_angle.(c, deg.(range(0, 360, length=100)))
    ax = PyPlot.gca()
    circlepatch = PyPlot.matplotlib.patches.Circle(
        (c.center.x, c.center.y), c.radius,
        facecolor = rgba(a[Fill].color),
        edgecolor = rgba(a[Stroke].color),
        linewidth = a[Linewidth].width,
        linestyle = a[Linestyle].style,
    )
    ax.add_patch(circlepatch)
end

function draw(r::Rect, a::Attributes)
    ax = PyPlot.gca()
    rectpatch = PyPlot.matplotlib.patches.Rectangle(
        (bottomleft(r).xy...,),
        r.width,
        r.height,
        deg(r.angle),
        facecolor = rgba(a[Fill].color),
        edgecolor = rgba(a[Stroke].color),
        linewidth = a[Linewidth].width,
        linestyle = a[Linestyle].style,
    )
    ax.add_patch(rectpatch)
end
