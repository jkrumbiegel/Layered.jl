export layer, layer!

mutable struct Layer <: LayerContent
    transform::Transform
    content::Vector{LayerContent}
    parent::Union{Layer, Nothing}
    attrs::Attributes
end

Base.Broadcast.broadcastable(l::Layer) = Ref(l)

function layer()
    Layer(Transform(), Vector{LayerContent}[], nothing, Attributes())
end

function layer(t::Transform, varargs::Vararg{Attribute, N}) where N
    Layer(t, Vector{LayerContent}[], nothing, Attributes(varargs...))
end

function layer!(parent::Layer, t::Transform, varargs::Vararg{Attribute, N}) where N
    l = Layer(t, Vector{LayerContent}[], nothing, Attributes(varargs...))
    push!(parent, l)
    l
end

function Base.push!(l::Layer, lc::LayerContent)
    push!(l.content, lc)
    lc.parent = l
end

function upward_transform(l::Layer)
    if isnothing(l.parent)
        return l.transform
    else
        return upward_transform(l.parent) * l.transform
    end
end

# current_layer =
# function currentlayer()
# end
