export Attribute, Attributes, Fill, Fills, Stroke, Strokes, Linestyle, Linewidth, Linewidths, Markersize, Markersizes, Marker, Font, Visible

abstract type Attribute end

Base.Broadcast.broadcastable(a::Attribute) = Ref(a)

import Colors

struct Fill <: Attribute
    color::Colors.Colorant
end

Fill(s::String) = Fill(parse(Colors.Colorant, s))

struct Fills <: Attribute
    colors::Union{Colors.Colorant, Array{<:Colors.Colorant}} # if it's a real parametric type then the dict lookup of the type doesn't work..
end

Fills(s::String) = Fills(parse(Colors.Colorant, s))


struct Stroke <: Attribute
    color::Colors.Colorant
end

Stroke(s::String) = Stroke(parse(Colors.Colorant, s))

struct Strokes <: Attribute
    colors::Union{Colors.Colorant, Array{<:Colors.Colorant}} # if it's a real parametric type then the dict lookup of the type doesn't work..
end

Strokes(s::String) = Strokes(parse(Colors.Colorant, s))

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

mutable struct Attributes
    attrs::Dict{Type{<:Attribute}, Union{Function, Attribute}}
end

Attributes() = Attributes(Dict{Type{<:Attribute}, Union{Function, Attribute}}())

function Attributes(att::Attribute, varargs::Vararg{Attribute, N}) where N
    attributes = Attributes()
    for a in (att, varargs...)
        if haskey(attributes, typeof(a))
            error("Attribute of type $(typeof(a)) was added more than once.")
        end
        attributes[typeof(a)] = a
    end
    attributes
end

Base.haskey(a::Attributes, key) = haskey(a.attrs, key)
Base.setindex!(a::Attributes, value, key) = setindex!(a.attrs, value, key)
Base.getindex(a::Attributes, key) = getindex(a.attrs, key)
