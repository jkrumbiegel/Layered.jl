export Canvas, canvas, png, svg, pdf

mutable struct Canvas
    size::Tuple{Int, Int}
    toplayer::Layer
    rect::Shape{Rect}
    color::Colors.Colorant
end


function canvas(
    width, height, toplayer::Union{Layer,Nothing}=nothing; color::Union{String, Colors.Colorant}="white")

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
    r = rect!(l, (0, 0), width, height, deg(0)) + Visible(false)
    color = typeof(color) <: String ? parse(Colors.Colorant, color) : color
    Canvas((width, height), l, r, color), l
end

function png(c::Canvas, filename::String; px_per_pt=1/0.75)
    csurface = draw_rgba(c, px_per_pt=px_per_pt)
    bufdata = UInt8[]
    iobuf = IOBuffer(bufdata, read=true, write=true)
    Cairo.write_to_png(csurface, iobuf)
    Cairo.finish(csurface)
    Cairo.destroy(csurface)
    write(filename, bufdata)
    nothing
end

function svg(c::Canvas, filename::String)
    draw_svg(c, filename)
end

function pdf(c::Canvas, filename::String)
    csurface = draw_pdf(c, filename)
    Cairo.finish(csurface)
    Cairo.destroy(csurface)
    nothing
end

function Base.show(io::IO, ::MIME"image/svg+xml", c::Canvas)
    svgbuffer = draw_svg(c)
    print(io, String(take!(svgbuffer)))
end

# function Base.show(io::IO, ::MIME"image/png", c::Canvas)
#     mktempdir() do path
#         p = joinpath(path, "layered.png")
#         png(c, p)
#         write(io, read(p))
#     end
# end
