export layer, layer!, layerfirst!, rectlayer!, upward_transform, transform_from_to

Base.Broadcast.broadcastable(l::Layer) = Ref(l)

function Base.:+(l::LayerContent, c::Clip)
    l.clip = c
    l
end

function Base.:+(l::LayerContent, o::Opacity)
    l.opacity = o
    l
end

function Base.:+(l::LayerContent, o::Operator)
    l.operator = o
    l
end

function Base.:+(l::LayerContent, a::T) where T <: Attribute
    add!(l.attrs, a)
    l
end

function layer(;scale=1, rotation=deg(0), translation=O)
    Layer(
        Transform(scale=scale, rotation=rotation, translation=translation),
        Vector{LayerContent}[], nothing, Attributes(), Clip(nothing), Opacity(1), Operator())
end

function layer(t::Transform)
    Layer(t, Vector{LayerContent}[], nothing, Attributes(), Clip(nothing), Opacity(1), Operator())
end

function layer!(parent::Layer; scale=1, rotation=deg(0), translation=O)
    l = layer(scale=scale, rotation=rotation, translation=translation)
    push!(parent, l)
    l
end

function layer!(parent::Layer, t::Transform)
    l = Layer(t, Vector{LayerContent}[], nothing, Attributes(), Clip(nothing), Opacity(1), Operator())
    push!(parent, l)
    l
end

function layerfirst!(parent::Layer, t::Transform)
    l = Layer(t, Vector{LayerContent}[], nothing, Attributes(), Clip(nothing), Opacity(1), Operator())
    pushfirst!(parent, l)
    l
end

function layer!(f::Function, parent::Layer, deps...)
    l = Layer((f, [deps...]), Vector{LayerContent}[], nothing, Attributes(), Clip(nothing), Opacity(1), Operator())
    push!(parent, l)
    l
end

function rectlayer!(l::Layer, sr::Shape{Rect}, wh::Symbol, mode::Symbol=:center; margin=0)
    layer!(l, sr) do r
        d = @match wh begin
            :w => r.width
            :h => r.height
            _ => error("Symbol not allowed")
        end

        @match mode begin
            :center => Transform(translation=r.center, scale=(d - margin)/2, rotation=r.angle)
            :norm => Transform(translation=topleft(r) + P(margin, margin), scale=(d - 2*margin), rotation=r.angle)
        end

    end
end

function Base.push!(l::Layer, lc::LayerContent)
    push!(l.content, lc)
    lc.parent = l
end

function Base.pushfirst!(l::Layer, lc::LayerContent)
    pushfirst!(l.content, lc)
    lc.parent = l
end

function Base.insert!(l::Layer, index::Integer, lc::LayerContent)
    insert!(l.content, index, lc)
    lc.parent = l
end

function upward_transform(l::Layer, cc::Cairo.CairoContext)
    if isnothing(l.parent)
        return gettransform!(l, cc)
    else
        return upward_transform(l.parent, cc) * gettransform!(l, cc)
    end
end

function ancestorchain(l::LayerContent)
    chain = LayerContent[]
    current = l
    while true
        if isnothing(current.parent)
            break
        else
            pushfirst!(chain, current.parent)
            current = current.parent
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
                return ancestors1[i:end], ancestors2[i:end]
            end
        end
    end
    # all ancestors so far were the same, so the last one (i) is the common one
    return ancestors1[n+1:end], ancestors2[n+1:end]
end

function gettransform! end

function transform_from_to(from::LayerContent, to::LayerContent, cc::Cairo.CairoContext)
    from_ancestors, to_ancestors = lowestcommonancestorchainfromto(from, to)

    #start with identity
    t = Transform()

    for a in reverse(from_ancestors)
        t = gettransform!(a, cc) * t
    end

    for a in to_ancestors
        t = inverse(gettransform!(a, cc)) * t
    end

    t
end

function gettransform!(l::Layer, cc::Cairo.CairoContext)
    if typeof(l.transform) <: Transform
        l.transform
    else
        closure = l.transform[1]
        deps = l.transform[2]
        solved_deps = []
        for d in deps
            if typeof(d) <: Shape
                solved = solve!(d, cc)
                t = transform_from_to(d, l, cc)
                transformed = t * solved
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


# function scale!(l::Layer, s::Real)
#     trans = gettransform!(l)
#     tnew = Transform(trans.scale * s, trans.rotation, trans.translation)
#     l.transform = tnew
# end
