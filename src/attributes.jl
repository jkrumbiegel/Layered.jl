export Attribute, Attributes, Fill, Fills, Stroke, Strokes, Linestyle, Linewidth, Linewidths, Markersize, Markersizes, Marker, Font, Visible
export Clip

Base.Broadcast.broadcastable(a::Attribute) = Ref(a)

Fill(s::String) = Fill(parse(Colors.Colorant, s))

Fills(s::String) = Fills(parse(Colors.Colorant, s))

Stroke(s::String) = Stroke(parse(Colors.Colorant, s))

Strokes(s::String) = Strokes(parse(Colors.Colorant, s))

Attributes() = Attributes(Dict{Type{<:Attribute}, Union{Function, Attribute}}())

Operator() = Operator(:over)

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
