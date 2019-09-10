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

struct Line <: GeometricObject
    from::Point
    to::Point
end

struct Arc <: GeometricObject
    center::Point
    radius::Float64
    start_angle::Angle
    end_angle::Angle
end

struct Bezier <: GeometricObject
    from::Point
    c1::Point
    c2::Point
    to::Point
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

struct Circle <: GeometricObject
    center::Point
    radius::Float64
end

struct TextExtent
    xbearing::Float64
    ybearing::Float64
    width::Float64
    height::Float64
    xadvance::Float64
    yadvance::Float64
end

struct Txt <: GeometricObject
    pos::Point
    text::String
    size::Float64
    halign::Symbol
    valign::Symbol
    angle::Angle
    font::String
    extent::Union{Nothing, TextExtent}
end

const BezierSegment = Union{Bezier, Line, Arc}

struct Path <: GeometricObject
    segments::Vector{<:BezierSegment}
    closed::Bool
end


geoms = (:Point, :Line, :Arc, :Circle, :Rect, :Bezier, :Path, :Polygon, :Txt)


abstract type Attribute end

mutable struct Attributes
    attrs::Dict{Type{<:Attribute}, Union{Function, Attribute}}
end

struct Clip
    shape
    # shape::Union{Nothing, Shape, Tuple{Shape, Shape}}
end

Base.Broadcast.broadcastable(c::Clip) = Ref(c)

struct Opacity
    opacity::Float64
end

Base.Broadcast.broadcastable(o::Opacity) = Ref(o)

struct Operator
    operator::Symbol
end

Base.Broadcast.broadcastable(o::Operator) = Ref(o)

mutable struct Layer <: LayerContent
    transform::Union{Tuple{Function, Vector}, Transform}
    content::Vector{LayerContent}
    parent::Union{Layer, Nothing}
    attrs::Attributes
    clip::Clip
    opacity::Opacity
    operator::Operator
end

mutable struct Shape{T <: GeometricObject} <: LayerContent
    # make this nicer and more julian
    content::Union{Tuple{Function, Vector}, T}
    parent::Union{Layer, Nothing}
    solved::Union{T, Nothing}
    attrs::Attributes
    clip::Clip
    opacity::Opacity
    operator::Operator
end

mutable struct Shapes{T <: GeometricObject} <: LayerContent
    # make this nicer and more julian
    content::Union{Tuple{Function, Vector}, Array{T}}
    parent::Union{Layer, Nothing}
    solved::Union{Array{T}, Nothing}
    attrs::Attributes
    clip::Clip
    opacity::Opacity
    operator::Operator
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

const FillContent = Union{Nothing, Colors.Colorant, Gradient, RadialGradient}
struct Fill{T<:FillContent} <: Attribute
    content::T
end

const TextfillContent = FillContent
struct Textfill{T<:TextfillContent} <: Attribute
    content::T
end

const StrokeContent = Union{Nothing, Colors.Colorant}
struct Stroke{T<:StrokeContent} <: Attribute
    color::T
end

const LinestyleContent = Symbol
struct Linestyle{T<:LinestyleContent} <: Attribute
    style::T
end

const LinewidthContent = Real
struct Linewidth{T<:LinewidthContent} <: Attribute
    width::T
end

const MarkersizeContent = Real
struct Markersize{T<:MarkersizeContent} <: Attribute
    size::T
end

const MarkerContent = Symbol
struct Marker{T<:MarkerContent} <: Attribute
    marker::T
end

const VisibleContent = Bool
struct Visible{T<:VisibleContent} <: Attribute
    visible::T
end
