export layer, layer!, layerfirst!

mutable struct Layer <: LayerContent
    transform::Union{Tuple{Function, Vector}, Transform}
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

function layerfirst!(parent::Layer, t::Transform, varargs::Vararg{Attribute, N}) where N
    l = Layer(t, Vector{LayerContent}[], nothing, Attributes(varargs...))
    pushfirst!(parent, l)
    l
end

function layer!(f::Function, parent::Layer, varargs...)

    deps = Tuple(v for v in varargs if !(typeof(v) <: Attribute))

    attributes = Attributes()
    attrs = Tuple(v for v in varargs if typeof(v) <: Attribute)
    for a in attrs
        if haskey(attributes, typeof(a))
            error("Attribute of type $(typeof(a)) was added more than once.")
        end
        attributes[typeof(a)] = a
    end

    l = Layer((f, [deps...]), Vector{LayerContent}[], nothing, attributes)
    push!(parent, l)
    l
end

function Base.push!(l::Layer, lc::LayerContent)
    push!(l.content, lc)
    lc.parent = l
end

function Base.pushfirst!(l::Layer, lc::LayerContent)
    pushfirst!(l.content, lc)
    lc.parent = l
end

function upward_transform(l::Layer)
    if isnothing(l.parent)
        return l.transform
    else
        return upward_transform(l.parent) * l.transform
    end
end

function ancestorchain(l::LayerContent)
    chain = LayerContent[]
    current = l
    while true
        if !isnothing(current.parent)
            pushfirst!(chain, current.parent)
            current = current.parent
        else
            break
        end
    end
    chain
end

function lowestcommonancestorchainfromto(s1::LayerContent, s2::LayerContent)
    ancestors1 = ancestorchain(s1)
    ancestors2 = ancestorchain(s2)

    length1 = Base.length(ancestors1)
    length2 = Base.length(ancestors2)
    n = min(length1, length2)
    for i in 1:n
        if ancestors1[i] !== ancestors2[i]
            if i == 1
                error("No common ancestor")
            else
                part1 = reverse(ancestors1[i-1:end])
                part2 = ancestors2[i:end]
                lca_index = Base.length(part1)
                return lca_index, vcat(part1, part2)
            end
        end
    end
    # all ancestors so far were the same, so the last one (i) is the common one
    part1 = reverse(ancestors1[n:end])
    part2 = ancestors2[n+1:end]
    lca_index = Base.length(part1)
    return lca_index, vcat(part1, part2)
end

function gettransform! end

function transform_from_to(s1::LayerContent, s2::LayerContent)
    lca_index, chain = lowestcommonancestorchainfromto(s1, s2)

    if Base.length(chain) == 1
        return Transform()
    else
        t = Transform()
        for i in 1:Base.length(chain)
            trans = gettransform!(chain[i])
            t = i <= lca_index ? trans * t : inverse(trans) * t
        end
        return t
    end
end

function gettransform!(l::Layer)
    if typeof(l.transform) <: Transform
        l.transform
    else
        closure = l.transform[1]
        deps = l.transform[2]
        solved_deps = []
        for d in deps
            if typeof(d) <: Shape
                solved = solve!(d)
                transformed = transform_from_to(d, l) * solved
                push!(solved_deps, transformed)
            else
                # for other arguments that are not shapes
                # other layers not handled yet
                push!(solved_deps, d)
            end
        end
        l.transform = closure(solved_deps...)
    end
end
