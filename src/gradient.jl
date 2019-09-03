export Gradient, RadialGradient

function Gradient(from::Point, to::Point, color1::Union{String, Colors.Colorant}, morecolors...)
    colors_unparsed = (color1, morecolors...)
    colors = [typeof(c) <: String ? parse(Colors.Colorant, c) : c for c in colors_unparsed]
    n = length(colors)
    stops = collect(range(0, 1, length=n))
    Gradient(from, to, stops, colors)
end

function RadialGradient(from::Circle, to::Circle, color1::Union{String, Colors.Colorant}, morecolors...)
    colors_unparsed = (color1, morecolors...)
    colors = [typeof(c) <: String ? parse(Colors.Colorant, c) : c for c in colors_unparsed]
    n = length(colors)
    stops = collect(range(0, 1, length=n))
    RadialGradient(from, to, stops, colors)
end
