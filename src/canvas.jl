export Canvas, canvas, write_to_png

mutable struct Canvas
    size_in::Tuple{Float64, Float64}
    toplayer::Layer
    rect::Shape{Rect}
    bgcolor::Colors.Colorant
end


function canvas(
    width::Real, height::Real, toplayer::Union{Layer,Nothing}=nothing; bgcolor::Union{String, Colors.Colorant}="white")
    pt_per_in = 72
    size_in = (width, height)
    size_pt = size_in .* pt_per_in

    l = if isnothing(toplayer)
        layer(
            Transform(1, rad(0), (0, 0)),
            Visible(true),
            Markersize(3),
            Markersizes(3),
            Marker(:.),
            Fill("transparent"),
            Fills("transparent"),
            Stroke("black"),
            Strokes("black"),
            Linewidth(1),
            Linestyle(:solid),
            Textfill("black"),
        )
    else
        toplayer
    end
    r = rect!(l, (0, 0), size_pt..., deg(0)) + Visible(false)
    bgcolor = typeof(bgcolor) <: String ? parse(Colors.Colorant, bgcolor) : bgcolor
    Canvas((width, height), l, r, bgcolor), l
end

function write_to_png(c::Canvas, filename::String; dpi=200)
    cc = draw(c, :rgba; dpi=dpi)
    Cairo.write_to_png(cc, filename);
end

function Base.show(io::IO, ::MIME"image/svg+xml", c::Canvas)
    csurf, svgbuffer = draw_svg(c)
    print(io, String(take!(svgbuffer)))
end
