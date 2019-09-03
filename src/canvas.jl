export Canvas, canvas

mutable struct Canvas
    size_in::Tuple{Float64, Float64}
    toplayer::Layer
    rect::Shape{Rect}
end


function canvas(
    width::Real, height::Real, toplayer::Union{Layer,Nothing}=nothing; bgcolor="white")
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
            Font("Helvetica Neue LT Std"),
            Clip(nothing)
        )
    else
        toplayer
    end
    r = rect!(l, (0, 0), size_pt..., deg(0), Fill(bgcolor), Stroke("transparent"))
    Canvas((width, height), l, r), l
end
