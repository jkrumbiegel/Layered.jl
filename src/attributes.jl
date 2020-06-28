export Attribute, Attributes, Fill, Fills, Stroke, Strokes, Linestyle, Linewidth, Linewidths, Markersize, Markersizes, Marker, Font, Visible
export Clip, Textfill, Opacity, Operator, Invisible


Base.Broadcast.broadcastable(a::Attribute) = Ref(a)

Fill(s::String) = Fill(parse(Colors.Colorant, s))
Fill(s::String, r::Real) = Fill(Colors.RGBA(parse(Colors.Colorant, s), r))

Textfill(s::String) = Textfill(parse(Colors.Colorant, s))

Stroke(s::String) = Stroke(parse(Colors.Colorant, s))
Stroke(s::String, r::Real) = Stroke(Colors.RGBA(parse(Colors.Colorant, s), r))


Attributes() = Attributes(Dict{Type{<:Attribute}, Union{Function, Attribute}}())

Operator() = Operator(:over)

const Invisible = Visible(false)

parameterlesstypeof(a::Attribute) = typeof(a).name.wrapper

function Attributes(att::Attribute, varargs::Vararg{Attribute, N}) where N
    attributes = Attributes()
    for a in (att, varargs...)
        insert!(attributes, a)
    end
    attributes
end

function Base.insert!(attrs::Attributes, a::Attribute)
    pltype = parameterlesstypeof(a)
    attrs[pltype] = a
end

Base.haskey(a::Attributes, key) = haskey(a.attrs, key)
Base.setindex!(a::Attributes, value, key) = setindex!(a.attrs, value, key)
Base.getindex(a::Attributes, key) = getindex(a.attrs, key)


ismultiattr(a::Attribute) = false
ismultiattr(f::Fill{T}) where T <: Union{Array, Pair{Symbol, <:Function}} = true
ismultiattr(s::Stroke{T}) where T <: Union{Array, Pair{Symbol, <:Function}} = true
