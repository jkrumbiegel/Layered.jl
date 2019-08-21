mutable struct Layer <: LayerContent
    transform::Transform
    content::Vector{LayerContent}
    parent::Union{Layer, Nothing}
end

Base.Broadcast.broadcastable(l::Layer) = Ref(l)

function Layer()
    Layer(Transform(), Vector{LayerContent}[], nothing)
end

function Layer(t::Transform)
    Layer(t, Vector{LayerContent}[], nothing)
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
