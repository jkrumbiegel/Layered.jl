import Cairo
const C = Cairo

export draw

CLOSEPOLY = 79
CURVE3 = 3
CURVE4 = 4
LINETO = 2
MOVETO = 1

z = 0
function zorder()
    global z
    z += 1
end

function fillstroke!(cc, a::Attributes)
    C.set_source_rgba(cc, rgba(a[Fill].color)...)
    C.fill_preserve(cc)
    C.set_source_rgba(cc, rgba(a[Stroke].color)...)
    C.stroke(cc)
end

function stroke!(cc, a::Attributes)
    C.set_source_rgba(cc, rgba(a[Stroke].color)...)
    C.stroke(cc)
end

function linestyle!(cc, a::Attributes)
    style = a[Linestyle].style
    lw = a[Linewidth].width
    if style == :solid
        #
    elseif style == :dashed
        C.set_dash(cc, [4.0, 2] .* lw, 0)
    elseif style == :dotted
        C.set_dash(cc, [1.0, 1] .* lw, 0)
    else
        error("$style not implemented")
    end
end

import Colors

function rgba(c::Colors.Colorant)
    rgba = Colors.RGBA(c)
    Float64.((rgba.r, rgba.g, rgba.b, rgba.alpha))
end

function rgbas(f::T) where T <: Union{Fills,Strokes}
    c = f.colors
    if typeof(c) <: Colors.Colorant
        return rgba(c)
    else
        return rgba.(c)
    end
end

function draw(canvas::Canvas; dpi=100)


    # fig = PyPlot.figure(figsize=(c.size_in), dpi=dpi)
    # ax = fig.add_axes((0, 0, 1, 1), frameon=false)
    # ax.set_axis_off()

    pt_per_in = 72
    size_pt = canvas.size_in .* pt_per_in
    size_pixel = canvas.size_in .* dpi

    c = C.CairoRGBSurface(size_pixel...);
    cc = C.CairoContext(c);

    C.scale(cc, dpi / pt_per_in, dpi / pt_per_in)
    C.translate(cc, (size_pt./2)...)

    # ax.set_xlim(-size_pt[1]/2, size_pt[1]/2)
    # ax.set_ylim(-size_pt[2]/2, size_pt[2]/2)

    draw!(cc, canvas.toplayer)
    C.write_to_png(c, "cairotest.png");
    # fig
end

function draw!(cc::C.CairoContext, l::Layer)
    z = 0
    for content in l.content
        draw!(cc, content)
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

function draw!(cc, s::Shape)
    geom = solve!(s)
    attributes = getattributes(s)
    if !attributes[Visible].visible
        return
    end
    transformed_to_toplevel = upward_transform(s) * geom

    C.save(cc)
    draw!(cc, transformed_to_toplevel, attributes)
    C.restore(cc)
end

function draw!(cc, p::Point, a::Attributes)
    C.arc(cc, p.x, p.y, a[Markersize].size, 0, 2pi)
    fillstroke!(cc, a)
end

function draw(ps::Points, a::Attributes)
    PyPlot.scatter(
        xs(ps.points), ys(ps.points),
        s = a[Markersizes].sizes,
        color = rgba.(a[Strokes].colors),
        marker = a[Marker].marker,
    )
end

# function PyPlot.matplotlib.path.Path(l::Line; kwargs...)
#     vertices = [l.from.xy, l.to.xy]
#     codes = UInt8[MOVETO, LINETO]
#     PyPlot.matplotlib.path.Path(vertices, codes; kwargs...)
# end
#
# function PyPlot.matplotlib.path.Path(ls::LineSegments; kwargs...)
#     vertices = SVector{2, Float64}[]
#     codes = UInt8[]
#
#     for l in ls.segments
#         push!(vertices, l.from.xy)
#         push!(vertices, l.to.xy)
#         push!(codes, MOVETO)
#         push!(codes, LINETO)
#     end
#     PyPlot.matplotlib.path.Path(vertices, codes; kwargs...)
# end
#
# function PyPlot.matplotlib.path.Path(p::Polygon; kwargs...)
#     vertices = SVector{2, Float64}[]
#     codes = UInt8[]
#
#     push!(vertices, p.points[1].xy)
#     push!(codes, MOVETO)
#
#     for po in p.points[2:end]
#         push!(vertices, po.xy)
#         push!(codes, LINETO)
#     end
#
#     push!(vertices, p.points[1].xy)
#     push!(codes, LINETO)
#
#     PyPlot.matplotlib.path.Path(vertices; kwargs...)
# end
#
# function PyPlot.matplotlib.path.Path(a::Arc; kwargs...)
#     path = PyPlot.matplotlib.path.Path.arc(deg(a.start_angle), deg(a.end_angle))
#
#     # numpy broadcasting here
#     verts = path.vertices * a.radius + a.center.xy
#
#     PyPlot.matplotlib.path.Path(verts, path.codes; kwargs...)
# end
#
# function PyPlot.matplotlib.path.Path(bp::BezierPath; kwargs...)
#     vertices = SVector{2, Float64}[]
#     codes = UInt8[]
#
#     n = length(bp.segments)
#     for i in 1:n
#         s = bp.segments[i]
#         if i == 1
#             push!(vertices, s.from)
#             push!(codes, MOVETO)
#         else
#             if s.from != bp.segments[i-1].to
#                 push!(vertices, s.from)
#                 push!(codes, MOVETO)
#             end
#         end
#         if typeof(s) <: Bezier
#             push!(vertices, s.c1)
#             push!(vertices, s.c2)
#             push!(vertices, s.to)
#             push!(codes, CURVE4)
#             push!(codes, CURVE4)
#             push!(codes, CURVE4)
#         elseif typeof(s) <: Line
#             push!(vertices, s.to)
#             push!(codes, LINETO)
#         end
#     end
#     PyPlot.matplotlib.path.Path(vertices, codes; kwargs...)
# end

function path!(cc, l::Line)
    C.move_to(cc, l.from.xy...)
    C.line_to(cc, l.to.xy...)
end

function draw!(cc, l::Line, a::Attributes)
    path!(cc, l)
    C.set_source_rgba(cc, rgba(a[Stroke].color)...)
    C.set_line_width(cc, a[Linewidth].width)
    linestyle!(cc, a)
    C.stroke(cc)
end

function draw(ls::LineSegments, a::Attributes)
    path = PyPlot.matplotlib.path.Path(ls, closed=false)
    pathpatch = PyPlot.matplotlib.patches.PathPatch(
        path,
        edgecolor = rgba(a[Stroke].color),
        linewidth = a[Linewidth].width,
        linestyle = a[Linestyle].style,
        zorder=zorder(),
    )
    PyPlot.gca().add_patch(pathpatch)
end

function path!(cc, p::Polygon)
    C.move_to(cc, p.points[1].xy...)

    for po in p.points[2:end]
        C.line_to(cc, po.xy...)
    end

    C.line_to(cc, p.points[1].xy...)
end

function draw!(cc, p::Polygon, a::Attributes)
    path!(cc, p)
    linestyle!(cc, a)
    fillstroke!(cc, a)
end

function path!(cc, a::Arc)
    C.arc(cc, a.center.xy..., a.radius, rad(a.start_angle), rad(a.end_angle))
end

function draw!(cc, arc::Arc, a::Attributes)
    path!(cc, arc)
    linestyle!(cc, a)
    stroke!(cc, a)
end

alignments = Dict(
    :c => "center",
    :t => "top",
    :b => "bottom",
    :l => "left",
    :r => "right",
    :bl => "baseline",
    :cbl => "center_baseline"
)

function draw(t::Txt, a::Attributes)
    PyPlot.gca().text(
        t.pos.xy...,
        t.text,
        fontsize = t.size,
        fontfamily = a[Font].family,
        color = rgba(a[Stroke].color),
        va = alignments[t.valign],
        ha = alignments[t.halign],
        rotation = deg(t.angle),
        rotation_mode = "anchor",
        zorder=zorder(),
        snap=false,
    )
end


# function PyPlot.matplotlib.path.Path(b::Bezier; kwargs...)
#     vertices = [b.from.xy, b.c1.xy, b.c2.xy, b.to.xy]
#     codes = UInt8[MOVETO, CURVE4, CURVE4, CURVE4]
#     PyPlot.matplotlib.path.Path(vertices, codes; kwargs...)
# end

function draw(b::Bezier, a::Attributes)
    path = PyPlot.matplotlib.path.Path(b, closed=false)
    ax = PyPlot.gca()
    pathpatch = PyPlot.matplotlib.patches.PathPatch(
        path,
        edgecolor = rgba(a[Stroke].color),
        linewidth = a[Linewidth].width,
        linestyle = a[Linestyle].style,
        facecolor = rgba(a[Fill].color),
        zorder=zorder(),
        snap=false,
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
        zorder=zorder(),
        snap=false,
    )
    ax.add_patch(pathpatch)
end

function draw(bs::BezierPaths, a::Attributes)
    paths = PyPlot.matplotlib.path.Path.(bs.paths)
    collection = PyPlot.matplotlib.collections.PathCollection(
        paths,
        edgecolors = rgbas(a[Strokes]),
        facecolors = rgbas(a[Fills]),
        linewidths = a[Linewidths].widths,
        zorder=zorder(),
        antialiaseds=true,
        snap=false,
    )
    PyPlot.gca().add_collection(collection)
end

# function PyPlot.plot(v::Vector{Point}; kwargs...)
#     xx = [p.x for p in v]
#     yy = [p.y for p in v]
#     PyPlot.plot(xx, yy; kwargs...)
# end

function path!(cc, c::Circle)
    C.arc(cc, c.center.xy..., c.radius, 0, 2pi)
end

function draw!(cc, c::Circle, a::Attributes)
    # ax = PyPlot.gca()
    # circlepatch = PyPlot.matplotlib.patches.Circle(
    #     (c.center.x, c.center.y), c.radius,
    #     facecolor = rgba(a[Fill].color),
    #     edgecolor = rgba(a[Stroke].color),
    #     linewidth = a[Linewidth].width,
    #     linestyle = a[Linestyle].style,
    #     zorder=zorder(),
    #     snap=false,
    # )
    # ax.add_patch(circlepatch)
    path!(cc, c)
    linestyle!(cc, a)
    C.set_line_width(cc, a[Linewidth].width)
    fillstroke!(cc, a)
end

function draw!(cc, r::Rect, a::Attributes)
    # ax = PyPlot.gca()
    # rectpatch = PyPlot.matplotlib.patches.Rectangle(
    #     (bottomleft(r).xy...,),
    #     r.width,
    #     r.height,
    #     deg(r.angle),
    #     facecolor = rgba(a[Fill].color),
    #     edgecolor = rgba(a[Stroke].color),
    #     linewidth = a[Linewidth].width,
    #     linestyle = a[Linestyle].style,
    #     zorder=zorder(),
    #     snap=false,
    # )
    # ax.add_patch(rectpatch)
    path!(cc, r)
    linestyle!(cc, a)
    C.set_line_width(cc, a[Linewidth].width)
    fillstroke!(cc, a)
end

function path!(cc, r::Rect)
    C.move_to(cc, bottomleft(r).xy...)
    C.line_to(cc, bottomright(r).xy...)
    C.line_to(cc, topright(r).xy...)
    C.line_to(cc, topleft(r).xy...)
end
