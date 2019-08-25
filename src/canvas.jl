export Canvas, canvas

mutable struct Canvas
    size_in::Tuple{Float64, Float64}
    toplayer::Layer
    rect::Shape{Rect}
end


function canvas(
    width::Real, height::Real, toplayer::Union{Layer,Nothing}=nothing)
    pt_per_in = 72
    size_in = (width, height)
    size_pt = size_in .* pt_per_in

    l = if isnothing(toplayer)
        layer(
            Transform(1, rad(0), (0, 0)),
            Markersize(20),
            Marker(:.),
            Fill("transparent"),
            Stroke("black"),
            Linewidth(1),
            Linestyle(:solid),
            Font("Helvetica Neue LT Std")
        )
    else
        toplayer
    end
    r = rect!(l, (0, 0), size_pt..., deg(0), Fill("transparent"), Stroke("transparent"), Linewidth(0), Linestyle(:solid))
    Canvas((width, height), l, r), l
end
