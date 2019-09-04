abstract type LayerContent end
abstract type GeometricObject <: LayerContent end

struct Angle
    rad::Float64
end

struct Transform
    scale::Float64
    rotation::Angle
    translation::SVector{2, Float64}
end

struct Point <: GeometricObject
    xy::SVector{2, Float64}

    Point(x::Real, y::Real) = new(SVector(convert(Float64, x), convert(Float64, y)))
    function Point(xy)
        if Base.length(xy) != 2
            error("need 2 elements")
        end
        new(SVector{2, Float64}(xy...))
    end
end

const P = Point

struct Arc <: GeometricObject
    center::Point
    radius::Float64
    start_angle::Angle
    end_angle::Angle
end

struct Rect <: GeometricObject
    center::Point
    width::Float64
    height::Float64
    angle::Angle
end

struct Polygon <: GeometricObject
    points::Vector{Point}
end

struct Polygons <: GeometricObject
    polys::Vector{Polygon}
end

struct Circle <: GeometricObject
    center::Point
    radius::Float64
end

abstract type Attribute end

mutable struct Attributes
    attrs::Dict{Type{<:Attribute}, Union{Function, Attribute}}
end

struct Clip
    shape
    # shape::Union{Nothing, Shape, Tuple{Shape, Shape}}
end

mutable struct Layer <: LayerContent
    transform::Union{Tuple{Function, Vector}, Transform}
    content::Vector{LayerContent}
    parent::Union{Layer, Nothing}
    attrs::Attributes
    clip::Clip
end

mutable struct Shape{T <: GeometricObject} <: LayerContent
    # make this nicer and more julian
    content::Union{Tuple{Function, Vector}, T}
    parent::Union{Layer, Nothing}
    solved::Union{T, Nothing}
    attrs::Attributes
    clip::Clip
end

struct Gradient
    from::Point
    to::Point
    stops::Vector{Float64}
    colors::Vector{<:Colors.Colorant}
end

struct RadialGradient
    from::Circle
    to::Circle
    stops::Vector{Float64}
    colors::Vector{<:Colors.Colorant}
end

Clip(s1::Shape, s2::Shape) = Clip((s1, s2))

struct Fill <: Attribute
    content::Union{Colors.Colorant, Gradient, RadialGradient}
end

struct Fills <: Attribute
    colors::Union{Colors.Colorant, Array{<:Colors.Colorant}} # if it's a real parametric type then the dict lookup of the type doesn't work..
end

struct Stroke <: Attribute
    color::Colors.Colorant
end

struct Strokes <: Attribute
    colors::Union{Colors.Colorant, Array{<:Colors.Colorant}} # if it's a real parametric type then the dict lookup of the type doesn't work..
end

struct Linestyle <: Attribute
    style::Symbol
end

struct Linewidth <: Attribute
    width::Float64
end

struct Linewidths <: Attribute
    widths::Union{Real, Array{<:Real}} # if it's a real parametric type then the dict lookup of the type doesn't work..
end

struct Markersize <: Attribute
    size::Float64
end

struct Markersizes <: Attribute
    sizes::Union{Real, Array{<:Real}}
end

struct Marker <: Attribute
    marker::Symbol
end

struct Font <: Attribute
    family::String
end

struct Visible <: Attribute
    visible::Bool
end
