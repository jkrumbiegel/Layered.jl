import PyPlot

export draw

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
    attributes = getattributes(s)
    draw(geom, attributes)
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

function draw(l::Line, a::Attributes)
    PyPlot.plot(
        [l.from, l.to],
        color = rgba(a[Stroke].color),
        linewidth = a[Linewidth].width,
        linestyle = a[Linestyle].style,
    )
end

CLOSEPOLY = 79
CURVE3 = 3
CURVE4 = 4
LINETO = 2
MOVETO = 1

function PyPlot.matplotlib.path.Path(b::Bezier; kwargs...)
    vertices = [b.from.xy, b.c1.xy, b.c2.xy, b.to.xy]
    println(vertices)
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
