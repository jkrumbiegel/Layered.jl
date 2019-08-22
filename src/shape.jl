mutable struct Shape{T <: GeometricObject} <: LayerContent
    content::Union{Tuple{Function, Vector{Shape}}, T}
    parent::Union{Layer, Nothing}
    solved::Union{T, Nothing}
    attrs::Attributes
end

function Shape(g::GeometricObject, varargs::Vararg{Attribute})
    Shape(g, nothing, nothing, Attributes(varargs...))
end
function Shape(f::Function, ::Type{T}, varargs::Vararg{Union{Shape, Attribute},N}) where {N, T}

    deps = Tuple(v for v in varargs if typeof(v) <: Shape)

    attributes = Attributes()
    attrs = Tuple(v for v in varargs if typeof(v) <: Attribute)
    for a in attrs
        if haskey(attributes, typeof(a))
            error("Attribute of type $(typeof(a)) was added more than once.")
        end
        attributes[typeof(a)] = a
    end

    Shape{T}((f, Shape[deps...]), nothing, nothing, attributes)
end

Base.Broadcast.broadcastable(s::Shape) = Ref(s)

function upward_transform(s::Shape)
    return upward_transform(s.parent)
end

function solve!(s::Shape{T}) where T

    if !isnothing(s.solved)
        return s.solved
    end

    if typeof(s.content) <: GeometricObject
        s.solved = s.content
        return s.solved
    else
        closure = s.content[1]
        dependencies = s.content[2]
        solved_deps = solve!.(dependencies)

        println(typeof(solved_deps))
        println(typeof(dependencies))
        println(typeof(s))

        # convert dependencies into own transform
        converted_deps = transform_from_to.(dependencies, s) .* solved_deps
        # converted_deps = transform_from_to(dependencies[1], s)

        s.solved = closure(converted_deps...)
        return s.solved
    end
    # the dependencies should be converted into this shapes's transform
    # then the solution is also in this shape's transform
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

function lowestcommonancestorchainfromto(s1::Shape, s2::Shape)
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
                return hcat(part1, part2)
            end
        end
    end
    # all ancestors so far were the same, so the last one (i) is the common one
    part1 = reverse(ancestors1[n:end])
    part2 = ancestors2[n+1:end]
    println("blabla")
    println(typeof(part1))
    println(typeof(part2))
    lca_index = Base.length(part1)
    println(size(part1), "   ", size(part2))
    return lca_index, vcat(part1, part2)
end


function transform_from_to(s1::Shape, s2::Shape)
    lca_index, chain = lowestcommonancestorchainfromto(s1, s2)

    if Base.length(chain) == 1
        return Transform()
    else
        t = Transform()
        for i in 1:Base.length(chain)
            if i <= lca_index # up the chain
                t = chain[i].transform * t
            else # down the chain
                t = inverse(chain[i].transform) * t
            end
        end
        return t
    end
end
