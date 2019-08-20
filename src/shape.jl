mutable struct Shape{T <: GeometricObject} <: LayerContent
    content::Union{Tuple{Function, Vector{Shape}}, T}
    parent::Union{Layer, Nothing}
    solved::Union{T, Nothing}
end

Shape(g::GeometricObject) = Shape(g, nothing, nothing)
Shape(f::Function, ::Type{T}, deps::Vararg{Shape,N}) where {N, T} = Shape{T}((f, Shape[deps...]), nothing, nothing)

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
