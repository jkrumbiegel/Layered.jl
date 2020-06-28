const C = Cairo

export applytransform!


function fill!(cc, f::Fill)
    fill!(cc, f.val)
end

function fill!(cc, g::Gradient)
    C.save(cc)
    pat = C.pattern_create_linear(g.from.xy..., g.to.xy...)
    for (stop, col) in zip(g.stops, g.colors)
        C.pattern_add_color_stop_rgba(pat, stop, rgba(col)...)
    end
    C.set_source(cc, pat)
    C.fill_preserve(cc)
    C.destroy(pat)
    C.restore(cc)
end

function fill!(cc, rg::RadialGradient)
    C.save(cc)
    pat = C.pattern_create_radial(rg.from.center.xy..., rg.from.radius, rg.to.center.xy..., rg.to.radius)
    for (stop, col) in zip(rg.stops, rg.colors)
        C.pattern_add_color_stop_rgba(pat, stop, rgba(col)...)
    end
    C.set_source(cc, pat)
    C.fill_preserve(cc)
    C.destroy(pat)
    C.restore(cc)
end

function fill!(cc, c::Colors.Colorant)
    C.save(cc)
    C.set_source_rgba(cc, rgba(c)...)
    C.fill_preserve(cc)
    C.restore(cc)
end

function fill!(cc, n::Nothing)
    # do nothing
end

function stroke!(cc, canvasmatrix, s::Stroke)
    stroke!(cc, canvasmatrix, s.val)
end

function stroke!(cc, canvasmatrix, c::Colors.Colorant)
    C.save(cc)
    C.set_source_rgba(cc, rgba(c)...)
    C.set_matrix(cc, canvasmatrix)
    C.stroke_transformed_preserve(cc)
    C.restore(cc)
end

function stroke!(cc, canvasmatrix, c::Nothing)
    # do nothing
end

function stroke!(cc, canvasmatrix, g::Gradient)
    C.save(cc)
    pat = C.pattern_create_linear(g.from.xy..., g.to.xy...)
    for (stop, col) in zip(g.stops, g.colors)
        C.pattern_add_color_stop_rgba(pat, stop, rgba(col)...)
    end
    C.set_source(cc, pat)
    C.set_matrix(cc, canvasmatrix)
    C.stroke_transformed_preserve(cc)
    C.destroy(pat)
    C.restore(cc)
end

function stroke!(cc, canvasmatrix, rg::RadialGradient)
    C.save(cc)
    pat = C.pattern_create_radial(rg.from.center.xy..., rg.from.radius, rg.to.center.xy..., rg.to.radius)
    for (stop, col) in zip(rg.stops, rg.colors)
        C.pattern_add_color_stop_rgba(pat, stop, rgba(col)...)
    end
    C.set_source(cc, pat)
    C.set_matrix(cc, canvasmatrix)
    C.stroke_transformed_preserve(cc)
    C.destroy(pat)
    C.restore(cc)
end

function clearpath!(cc)
    Cairo.new_path(cc)
end

function lineattrs!(cc, a::Attributes)
    style = a[Linestyle].val
    lw = a[Linewidth].val
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


function draw_svg(canvas::Canvas)
    pt_per_in = 72
    size_pt = canvas.size_in .* pt_per_in

    bufferdata = UInt8[]
    iobuffer = IOBuffer(bufferdata, read=true, write=true)

    c = C.CairoSVGSurface(iobuffer, size_pt...);
    cc = C.CairoContext(c);

    C.rectangle(cc, 0, 0, size_pt...)
    C.set_source_rgba(cc, rgba(canvas.bgcolor)...)
    C.fill(cc)

    C.translate(cc, (size_pt./2)...)
    # flip all y-coordinates
    C.scale(cc, 1, -1)

    canvasmatrix = C.get_matrix(cc)

    draw!(cc, canvasmatrix, canvas.toplayer)
    Cairo.finish(c)
    Cairo.destroy(c)
    iobuffer
end

function draw_svg(canvas::Canvas, filename::String)
    pt_per_in = 72
    size_pt = canvas.size_in .* pt_per_in

    c = C.CairoSVGSurface(filename, size_pt...);
    cc = C.CairoContext(c);

    C.rectangle(cc, 0, 0, size_pt...)
    C.set_source_rgba(cc, rgba(canvas.bgcolor)...)
    C.fill(cc)

    C.translate(cc, (size_pt./2)...)

    canvasmatrix = C.get_matrix(cc)

    draw!(cc, canvasmatrix, canvas.toplayer)
    Cairo.finish(c)
    Cairo.destroy(c)
    nothing
end

function draw_pdf(canvas::Canvas, filename::String)
    pt_per_in = 72
    size_pt = canvas.size_in .* pt_per_in

    c = C.CairoPDFSurface(filename, size_pt...);
    cc = C.CairoContext(c);

    C.rectangle(cc, 0, 0, size_pt...)
    C.set_source_rgba(cc, rgba(canvas.bgcolor)...)
    C.fill(cc)

    C.translate(cc, (size_pt./2)...)

    canvasmatrix = C.get_matrix(cc)

    draw!(cc, canvasmatrix, canvas.toplayer)
    c
end

function draw_rgba(canvas::Canvas; dpi=100)

    pt_per_in = 72
    size_pt = canvas.size_in .* pt_per_in
    size_pixel = canvas.size_in .* dpi

    c = C.CairoARGBSurface(size_pixel...);
    cc = C.CairoContext(c);

    begin
        font_options_ptr = ccall((:cairo_font_options_create, C.libcairo), Ptr{Nothing}, ())

        CAIRO_HINT_STYLE_NONE = 1
        CAIRO_HINT_STYLE_SLIGHT = 2
        CAIRO_HINT_STYLE_FULL = 4
        ccall(
            (:cairo_font_options_set_hint_style, C.libcairo), Nothing,
            (Ptr{Nothing}, Int32),
            font_options_ptr, CAIRO_HINT_STYLE_NONE)

        CAIRO_HINT_METRICS_DEFAULT = 0
        CAIRO_HINT_METRICS_OFF = 1
        CAIRO_HINT_METRICS_ON = 2

        ccall(
            (:cairo_font_options_set_hint_metrics, C.libcairo), Nothing,
            (Ptr{Nothing}, Int32),
            font_options_ptr, CAIRO_HINT_METRICS_OFF)

        # ccall(
        #     (:cairo_font_options_set_antialias, C.libcairo), Nothing,
        #     (Ptr{Nothing}, Int32),
        #     font_options_ptr, 3)

        ccall(
            (:cairo_set_font_options, C.libcairo), Nothing,
            (Ptr{Nothing}, Ptr{Nothing}),
            cc.ptr, font_options_ptr)

        ccall(
            (:cairo_font_options_destroy, C.libcairo), Nothing,
            (Ptr{Nothing},),
            font_options_ptr)
    end

    C.rectangle(cc, 0, 0, size_pixel...)
    C.set_source_rgba(cc, rgba(canvas.bgcolor)...)
    C.fill(cc)

    C.scale(cc, dpi / pt_per_in, dpi / pt_per_in)
    C.translate(cc, (size_pt./2)...)

    canvasmatrix = C.get_matrix(cc)

    draw!(cc, canvasmatrix, canvas.toplayer)
    c
end

function applytransform!(cc, t::Transform)
    C.translate(cc, t.translation...)
    C.scale(cc, t.scale, t.scale)
    C.rotate(cc, rad(t.rotation))
end

function Base.convert(::Type{Int32}, op::Operator)
    @match op.operator begin
        :over => C.OPERATOR_OVER
        :add => C.OPERATOR_ADD
        :mult => C.OPERATOR_MULTIPLY
        :screen => C.OPERATOR_SCREEN
        :sat => C.OPERATOR_SATURATE
        :darken => C.OPERATOR_DARKEN
        :overlay => C.OPERATOR_OVERLAY
    end
end

function draw!(cc::C.CairoContext, canvasmatrix, l::Layer)

    C.save(cc)
    C.push_group(cc)
    applytransform!(cc, gettransform!(l, cc))

    for content in l.content
        draw!(cc, canvasmatrix, content)
    end

    gr = C.pop_group(cc)
    C.set_source(cc, gr);

    # I guess this should go here so it only takes effect on the layer after
    # that is drawn, so there will be better fringes than if two antialiased clips
    # are applied on perfectly overlapping objects
    setclippath!(cc, l)

    C.set_operator(cc, Base.convert(Int32, l.operator))

    C.paint_with_alpha(cc, l.opacity.opacity)
    C.restore(cc)
end

function getattributes(s::Shape{T}) where T
    needed = needed_attributes(T)
    attributes = Attributes(Dict(attr => getattribute(s, attr) for attr in needed))
end

function getattributes(s::Shapes{T}) where T
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

function draw!(cc, canvasmatrix, s::Shape)
    geom = solve!(s, cc)
    attributes = getattributes(s)

    #fast exit for invisible shapes
    if !attributes[Visible].val
        return
    end

    C.save(cc)
    C.push_group(cc)
    draw!(cc, canvasmatrix, geom, attributes)
    gr = C.pop_group(cc)

    C.set_source(cc, gr);
    setclippath!(cc, s)

    C.set_operator(cc, Base.convert(Int32, s.operator))

    C.paint_with_alpha(cc, s.opacity.opacity)

    C.restore(cc)
end

function getattributes(attr::Attributes, i::Int, n::Int, geom::GeometricObject)
    singleattrs = Attributes()
    for (typ, a) in attr.attrs
        if ismultiattr(a)
            if typeof(a.val) <: Pair{Symbol, <:Function}
                sym = a.val[1]
                func = a.val[2]
                value = @match sym begin
                    :i => func(i)
                    :frac => func((i - 1) / (n - 1))
                    :geom => func(geom)
                    _ => error("Not implemented")
                end
                insert!(singleattrs, typ(value))
            elseif typeof(a.val) <: AbstractArray
                insert!(singleattrs, typ(a.val[i]))
            else
                error("Not implemented")
            end
        else
            insert!(singleattrs, a)
        end
    end
    singleattrs
end

function draw!(cc, canvasmatrix, s::Shapes)
    geoms = solve!(s, cc)
    attributes = getattributes(s)

    #fast exit for invisible shapes
    if attributes[Visible].val == false
        return
    end

    C.save(cc)
    C.push_group(cc)

    n = length(geoms)
    for (i, g) in enumerate(geoms)
        singleattrs = getattributes(attributes, i, n, g)
        draw!(cc, canvasmatrix, g, singleattrs)
    end

    gr = C.pop_group(cc)

    C.set_source(cc, gr);
    setclippath!(cc, s)

    C.set_operator(cc, Base.convert(Int32, s.operator))

    C.paint_with_alpha(cc, s.opacity.opacity)

    C.restore(cc)
end

needslineattrs(g) = false
needslineattrs(g::Union{Point, Line, Bezier, Rect, Circle, Polygon, Path}) = true
needsstroke(g) = false
needsstroke(g::Union{Point, Line, Bezier, Rect, Circle, Polygon, Path}) = true
needsfill(g) = false
needsfill(g::Union{Point, Bezier, Rect, Circle, Polygon, Path}) = true

function draw!(cc, canvasmatrix, g::GeometricObject, a::Attributes)
    if typeof(g) <: Point
        makepath!(cc, g, canvasmatrix, a[Marker], a[Markersize])
    else
        makepath!(cc, g)
    end

    needslineattrs(g) && lineattrs!(cc, a)
    needsfill(g) && fill!(cc, a[Fill])
    needsstroke(g) && stroke!(cc, canvasmatrix, a[Stroke])

    clearpath!(cc)
end

# function draw!(cc, canvasmatrix, p::Point, a::Attributes)
#     C.move_to(cc, (p + 0.5 * a[Markersize].size * X(1)).xy...)
#     C.arc(cc, p.x, p.y, 0.5 * a[Markersize].size, 0, 2pi)
#     fill!(cc, canvasmatrix, a[Fill])
#     stroke!(cc, canvasmatrix, a[Stroke])
#     clearpath!(cc)
# end

# function draw(ps::Points, a::Attributes)
#     PyPlot.scatter(
#         xs(ps.points), ys(ps.points),
#         s = a[Markersizes].sizes,
#         color = rgba.(a[Strokes].colors),
#         marker = a[Marker].marker,
#     )
# end

function makepath!(cc, p::Point, canvasmatrix, m::Marker, ms::Markersize)
    m = m.val
    s = ms.val

    # save the position of the point in device coordinates
    xdev, ydev = C.user_to_device!(cc, [p.xy...])
    C.save(cc)
    # set the canvasmatrix and convert the device space point to this space
    C.set_matrix(cc, canvasmatrix)
    xuser, yuser = C.device_to_user!(cc, [xdev, ydev])
    # translate onto the point
    C.translate(cc, xuser, yuser)

    # now the shapes can be defined with origin (0, 0) and size in canvas units
    shape = @match m begin
        :square => Rect(O, s, s, deg(0))
        :circle || :o => Circle(O, 0.5s)
        :cross || :+ => Polygon(ncross(O, 4, 0.5s, 1 / Base.MathConstants.golden))
        _ => error("Markertype $m is not implemented")
    end

    makepath!(cc, shape)
    C.restore(cc)
end

function makepath!(cc, l::Line)
    C.move_to(cc, l.from.xy...)
    C.line_to(cc, l.to.xy...)
end

function continuepath!(cc, l::Line)
    C.line_to(cc, l.to.xy...)
end


# function draw(ls::LineSegments, a::Attributes)
#     path = PyPlot.matplotlib.path.Path(ls, closed=false)
#     pathpatch = PyPlot.matplotlib.patches.PathPatch(
#         path,
#         edgecolor = rgba(a[Stroke].color),
#         linewidth = a[Linewidth].width,
#         lineattrs = a[Linestyle].style,
#         zorder=zorder(),
#     )
#     PyPlot.gca().add_patch(pathpatch)
# end

function makepath!(cc, p::Polygon)
    C.move_to(cc, p.points[1].xy...)

    for po in p.points[2:end]
        C.line_to(cc, po.xy...)
    end

    C.close_path(cc)
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

alignments = Dict(
    :c => "center",
    :t => "top",
    :b => "bottom",
    :l => "left",
    :r => "right",
    :bl => "baseline",
    :cbl => "center_baseline"
)

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

function draw!(cc, canvasmatrix, t::Txt, a::Attributes)

    # if typeof(a[Fill]) <: Gradient
    #     g = a[Fill]
    #     pat = C.pattern_create_linear(g.from.xy..., g.to.xy...);
    #     for (stop, col) in zip(g.stops, g.colors)
    #         C.pattern_add_color_stop_rgba(pat, stop, rgba(col)...);
    #     end
    #     C.set_source(cc, pat);
    #     C.fill_preserve(cc);
    #     C.destroy(pat);
    #     end
    # end
    ex = TextExtent(cc, t)

    C.set_source_rgba(cc, rgba(a[Textfill].val)...)
    C.set_font_face(cc, "$(t.font) $(t.size)")

    C.set_text(cc, t.text, false)
    C.update_layout(cc)


    function get_layout_size(ctx::C.CairoContext)
        w = Vector{Int32}(undef, 2)
        ccall((:pango_layout_get_size, C.libpango), Nothing,
              (Ptr{Nothing},Ptr{Int32},Ptr{Int32}), ctx.layout, pointer(w,1), pointer(w,2))
        w ./ 1024
    end

    w, h = get_layout_size(cc)
    # C.set_font_size(cc, t.size)



    shiftx = @match t.halign begin
        :l => 0
        :c => -w/2
        :r => -w
        _ => error("Alignment $(t.halign) doesn't exist")
    end

    shifty = @match t.valign begin
        :t => 0
        :c => -h/2
        :b => -h
        _ => error("Alignment $(t.valign) doesn't exist")
        # :bl => 0
        # :b => -(ex.ybearing + ex.height)
    end

    shift = rotate(P(shiftx, shifty), -t.angle)

    pos = t.pos + shift

    C.save(cc) # this is needed if multiple texts are drawn in one go

    C.scale(cc, 1, -1)

    C.move_to(cc, pos.xy...)

    C.rotate(cc, rad(-t.angle))

    C.show_layout(cc)
    C.restore(cc)
end

function makepath!(cc, b::Bezier)
    C.move_to(cc, b.from.xy...)
    C.curve_to(cc, b.c1.xy..., b.c2.xy..., b.to.xy...)
end

function continuepath!(cc, b::Bezier)
    C.curve_to(cc, b.c1.xy..., b.c2.xy..., b.to.xy...)
end

start(a::Arc) = fraction(a, 0)
stop(a::Arc) = fraction(a, 1)
start(b::Bezier) = b.from
stop(b::Bezier) = b.to
start(l::Line) = l.from
stop(l::Line) = l.to

function makepath!(cc, m::Move)
    C.move_to(cc, m.p.xy...)
end

function makepath!(cc, l::Lineto)
    C.line_to(cc, l.p.xy...)
end

function makepath!(cc, c::CurveTo)
    C.curve_to(cc, c.c1.xy..., c.c2.xy..., c.p.xy...)
end

function makepath!(cc, c::Close)
    C.close_path(cc)
end


function makepath!(cc, p::Path)
    makepath!.(Ref(cc), p.commands)
    # makepath!(cc, p.segments[1])
    # for i in 2:length(p.segments)
    #     news = p.segments[i]
    #     olds = p.segments[i-1]
    #     if isapprox(start(news), stop(olds))
    #         continuepath!(cc, news)
    #     else
    #         makepath!(cc, news)
    #     end
    # end
    # if p.closed
    #     C.close_path(cc)
    # end
end


# function draw(bs::Paths, a::Attributes)
#     paths = PyPlot.matplotlib.path.Path.(bs.paths)
#     collection = PyPlot.matplotlib.collections.PathCollection(
#         paths,
#         edgecolors = rgbas(a[Strokes]),
#         facecolors = rgbas(a[Fills]),
#         linewidths = a[Linewidths].widths,
#         zorder=zorder(),
#         antialiaseds=true,
#         snap=false,
#     )
#     PyPlot.gca().add_collection(collection)
# end

# function PyPlot.plot(v::Vector{Point}; kwargs...)
#     xx = [p.x for p in v]
#     yy = [p.y for p in v]
#     PyPlot.plot(xx, yy; kwargs...)
# end

function makepath!(cc, c::Circle)
    # C.move_to(cc, c.center.xy...)
    C.new_sub_path(cc)
    C.arc(cc, c.center.xy..., c.radius, 0, 2pi)
end

function setclippath!(cc, l::LayerContent)

    sh = l.clip.shape
    if isnothing(sh)
        return
    end
    if typeof(sh) <: Shape
        s = transform_from_to(sh, l, cc) * solve!(sh, cc)
        makepath!(cc, s)
    else
        s_inner = transform_from_to(sh[1], l, cc) * solve!(sh[1], cc)
        s_outer = transform_from_to(sh[2], l, cc) * solve!(sh[2], cc)
        makepath!(cc, s_inner)
        makepath!(cc, s_outer)
    end
    C.clip(cc)
end


function makepath!(cc, r::Rect)
    C.move_to(cc, bottomleft(r).xy...)
    C.line_to(cc, bottomright(r).xy...)
    C.line_to(cc, topright(r).xy...)
    C.line_to(cc, topleft(r).xy...)
    C.close_path(cc)
end
