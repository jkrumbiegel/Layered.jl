export Canvas, canvas, png, svg, pdf

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
        layer() +
            Visible(true) +
            Markersize(3) +
            Marker(:o) +
            Fill("transparent") +
            Stroke("black") +
            Linewidth(1) +
            Linestyle(:solid) +
            Textfill("black")
    else
        toplayer
    end
    r = rect!(l, (0, 0), size_pt..., deg(0)) + Visible(false)
    bgcolor = typeof(bgcolor) <: String ? parse(Colors.Colorant, bgcolor) : bgcolor
    Canvas((width, height), l, r, bgcolor), l
end

function png(c::Canvas, filename::String; dpi=200)
    csurface = draw_rgba(c, dpi=dpi)
    bufdata = UInt8[]
    iobuf = IOBuffer(bufdata, read=true, write=true)
    Cairo.write_to_png(csurface, iobuf)
    Cairo.finish(csurface)
    Cairo.destroy(csurface)
    write(filename, bufdata)
    nothing
end

function svg(c::Canvas, filename::String)
    csurface = draw_svg(c, filename)
    Cairo.finish(csurface)
    Cairo.destroy(csurface)
    nothing
end

function pdf(c::Canvas, filename::String)
    csurface = draw_pdf(c, filename)
    Cairo.finish(csurface)
    Cairo.destroy(csurface)
    nothing
end

# function Base.show(io::IO, ::MIME"image/svg+xml", c::Canvas)
#     csurface, svgbuffer = draw_svg(c)
#     print(io, String(take!(svgbuffer)))
# end

function Base.show(io::IO, ::MIME"image/png", c::Canvas)
    p = "/tmp/layered.png"
    png(c, p, dpi=100)
    write(io, read(p))
end
