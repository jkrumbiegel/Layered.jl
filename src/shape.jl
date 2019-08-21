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
        s.solved = upward_transform(s) * s.content
        return s.solved
    else
        closure = s.content[1]
        dependencies = s.content[2]
        solved_deps = solve!.(dependencies)
        s.solved = closure(solved_deps...)
        return s.solved
    end
end
