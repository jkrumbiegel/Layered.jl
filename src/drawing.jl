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

function fill!(cc, g::Gradient)
    pat = C.pattern_create_linear(g.from.xy..., g.to.xy...);
    for (stop, col) in zip(g.stops, g.colors)
        C.pattern_add_color_stop_rgba(pat, stop, rgba(col)...);
    end
    C.set_source(cc, pat);
    C.fill_preserve(cc);
    C.destroy(pat);
end

function fill!(cc, c::Colors.Colorant)
    C.set_source_rgba(cc, rgba(c)...)
    C.fill_preserve(cc)
end

function fillstroke!(cc, a::Attributes)
    fill!(cc, a[Fill].content)
    C.set_source_rgba(cc, rgba(a[Stroke].color)...)
    C.stroke(cc)
end

function stroke!(cc, a::Attributes)
    C.set_source_rgba(cc, rgba(a[Stroke].color)...)
    C.stroke(cc)
end

function lineattrs!(cc, a::Attributes)
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
    C.set_line_width(cc, lw)
end

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
# function PyPlot.matplotlib.path.Path(bp::Path; kwargs...)
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

function makepath!(cc, l::Line)
    C.move_to(cc, l.from.xy...)
    C.line_to(cc, l.to.xy...)
end

function draw!(cc, l::Line, a::Attributes)
    makepath!(cc, l)
    C.set_source_rgba(cc, rgba(a[Stroke].color)...)
    C.set_line_width(cc, a[Linewidth].width)
    lineattrs!(cc, a)
    C.stroke(cc)
end

function draw(ls::LineSegments, a::Attributes)
    path = PyPlot.matplotlib.path.Path(ls, closed=false)
    pathpatch = PyPlot.matplotlib.patches.PathPatch(
        path,
        edgecolor = rgba(a[Stroke].color),
        linewidth = a[Linewidth].width,
        lineattrs = a[Linestyle].style,
        zorder=zorder(),
    )
    PyPlot.gca().add_patch(pathpatch)
end

function makepath!(cc, p::Polygon)
    C.move_to(cc, p.points[1].xy...)

    for po in p.points[2:end]
        C.line_to(cc, po.xy...)
    end

    C.line_to(cc, p.points[1].xy...)
end

function draw!(cc, p::Polygon, a::Attributes)
    makepath!(cc, p)
    lineattrs!(cc, a)
    fillstroke!(cc, a)
end

function makepath!(cc, a::Arc)
    pstart = fraction(a, 0)
    C.move_to(cc, pstart.xy...)

    if a.end_angle - a.start_angle >= rad(0)
        C.arc(cc, a.center.xy..., a.radius, rad(a.start_angle), rad(a.end_angle))
    else
        C.arc_negative(cc, a.center.xy..., a.radius, rad(a.start_angle), rad(a.end_angle))
    end

end

function draw!(cc, arc::Arc, a::Attributes)
    makepath!(cc, arc)
    lineattrs!(cc, a)
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

function makepath!(cc, b::Bezier)
    C.move_to(cc, b.from.xy...)
    C.curve_to(cc, b.c1.xy..., b.c2.xy..., b.to.xy...)
end

function draw!(cc, b::Bezier, a::Attributes)
    makepath!(cc, b)
    lineattrs!(cc, b)
    stroke!(cc, b)
end

function makepath!(cc, p::Path)
    for s in p.segments
        makepath!(cc, s)
    end
end

function draw!(cc, p::Path, a::Attributes)
    makepath!(cc, p)
    lineattrs!(cc, a)
    fillstroke!(cc, a)
end

function draw(bs::Paths, a::Attributes)
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

function makepath!(cc, c::Circle)
    C.arc(cc, c.center.xy..., c.radius, 0, 2pi)
end

function draw!(cc, c::Circle, a::Attributes)
    makepath!(cc, c)
    lineattrs!(cc, a)
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
    #     lineattrs = a[Linestyle].style,
    #     zorder=zorder(),
    #     snap=false,
    # )
    # ax.add_patch(rectpatch)
    makepath!(cc, r)
    lineattrs!(cc, a)
    fillstroke!(cc, a)
end

function makepath!(cc, r::Rect)
    C.move_to(cc, bottomleft(r).xy...)
    C.line_to(cc, bottomright(r).xy...)
    C.line_to(cc, topright(r).xy...)
    C.line_to(cc, topleft(r).xy...)
end
