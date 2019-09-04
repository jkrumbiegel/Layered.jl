import Cairo
const C = Cairo

export draw

CLOSEPOLY = 79
CURVE3 = 3
CURVE4 = 4
LINETO = 2
MOVETO = 1


function fill!(cc, g::Gradient)
    pat = C.pattern_create_linear(g.from.xy..., g.to.xy...);
    for (stop, col) in zip(g.stops, g.colors)
        C.pattern_add_color_stop_rgba(pat, stop, rgba(col)...);
    end
    C.set_source(cc, pat);
    C.fill_preserve(cc);
    C.destroy(pat);
end

function fill!(cc, rg::RadialGradient)
    pat = C.pattern_create_radial(rg.from.center.xy..., rg.from.radius, rg.to.center.xy..., rg.to.radius);
    for (stop, col) in zip(rg.stops, rg.colors)
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

    pt_per_in = 72
    size_pt = canvas.size_in .* pt_per_in
    size_pixel = canvas.size_in .* dpi

    c = C.CairoARGBSurface(size_pixel...);
    cc = C.CairoContext(c);

    C.rectangle(cc, 0, 0, size_pixel...)
    C.set_source_rgba(cc, rgba(canvas.bgcolor)...)
    C.fill(cc)

    C.scale(cc, dpi / pt_per_in, dpi / pt_per_in)
    C.translate(cc, (size_pt./2)...)

    draw!(cc, canvas.toplayer)
    c
end

function draw!(cc::C.CairoContext, l::Layer)
    C.save(cc)
    setclippath!(cc, l.clip)
    for content in l.content
        draw!(cc, content)
    end
    C.restore(cc)
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
    setclippath!(cc, s.clip)
    draw!(cc, transformed_to_toplevel, attributes)
    C.restore(cc)
end

function draw!(cc, p::Point, a::Attributes)
    C.move_to(cc, (p + 0.5 * a[Markersize].size * X(1)).xy...)
    C.arc(cc, p.x, p.y, 0.5 * a[Markersize].size, 0, 2pi)
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

function makepath!(cc, l::Line)
    C.move_to(cc, l.from.xy...)
    C.line_to(cc, l.to.xy...)
end

function continuepath!(cc, l::Line)
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

function continuepath!(cc, a::Arc)
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

struct TextExtent
    xbearing::Float64
    ybearing::Float64
    width::Float64
    height::Float64
    xadvance::Float64
    yadvance::Float64
end

function TextExtent(cc, t::Txt)
    C.save(cc)
    C.select_font_face(cc, t.font, Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
    C.set_font_size(cc, t.size)
    e = C.text_extents(cc, t.text);
    C.restore(cc)
    TextExtent(e...)
    # typedef struct {
    #     double x_bearing;
    #     double y_bearing;
    #     double width;
    #     double height;
    #     double x_advance;
    #     double y_advance;
    # } cairo_text_extents_t;
end

function draw!(cc, t::Txt, a::Attributes)

    C.set_source_rgba(cc, rgba(a[Fill].content)...)
    C.select_font_face(cc, t.font, Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL)
    C.set_font_size(cc, t.size)

    ex = TextExtent(cc, t)

    shiftx = @match t.halign begin
        :l => 0
        :c => -ex.width/2
        :r => -ex.width
    end

    shifty = @match t.valign begin
        :t => ex.height
        :c => ex.height/2
        :bl => 0
        :b => -(ex.ybearing + ex.height)
    end

    shift = rotate(P(shiftx, shifty), t.angle)

    pos = t.pos + shift


    C.move_to(cc, pos.xy...)
    C.rotate(cc, rad(t.angle))

    C.show_text(cc, t.text)
end

function makepath!(cc, b::Bezier)
    C.move_to(cc, b.from.xy...)
    C.curve_to(cc, b.c1.xy..., b.c2.xy..., b.to.xy...)
end

function continuepath!(cc, b::Bezier)
    C.curve_to(cc, b.c1.xy..., b.c2.xy..., b.to.xy...)
end

function draw!(cc, b::Bezier, a::Attributes)
    makepath!(cc, b)
    lineattrs!(cc, b)
    stroke!(cc, b)
end

start(a::Arc) = fraction(a, 0)
stop(a::Arc) = fraction(a, 1)
start(b::Bezier) = b.from
stop(b::Bezier) = b.to
start(l::Line) = l.from
stop(l::Line) = l.to

function makepath!(cc, p::Path)
    makepath!(cc, p.segments[1])
    for i in 2:length(p.segments)
        news = p.segments[i]
        olds = p.segments[i-1]
        if isapprox(start(news), stop(olds))
            continuepath!(cc, news)
        else
            makepath!(cc, news)
        end
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

function setclippath!(cc, c::Clip)
    sh = c.shape
    if isnothing(sh)
        return
    end
    if typeof(sh) <: Shape
        makepath!(cc, solve!(sh))
    else
        makepath!(cc, solve!(sh[1]))
        makepath!(cc, solve!(sh[2]))
    end
    C.clip(cc)
end

function draw!(cc, c::Circle, a::Attributes)
    C.save(cc)
    makepath!(cc, c)
    lineattrs!(cc, a)
    fillstroke!(cc, a)
    C.restore(cc)
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
