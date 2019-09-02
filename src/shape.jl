function Shape(g::GeometricObject, varargs::Vararg{Attribute})
    Shape(g, nothing, nothing, Attributes(varargs...))
end
function Shape(f::Function, ::Type{T}, varargs...) where {N, T}

    deps = Tuple(v for v in varargs if !(typeof(v) <: Attribute))

    attributes = Attributes()
    attrs = Tuple(v for v in varargs if typeof(v) <: Attribute)
    for a in attrs
        if haskey(attributes, typeof(a))
            error("Attribute of type $(typeof(a)) was added more than once.")
        end
        attributes[typeof(a)] = a
    end

    Shape{T}((f, [deps...]), nothing, nothing, attributes)
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

        solved_deps = []
        for d in dependencies
            if typeof(d) <: Shape
                solved = solve!(d)
                transformed = transform_from_to(d, s) * solved
                push!(solved_deps, transformed)
            else
                # for other arguments that are not shapes
                push!(solved_deps, d)
            end
        end

        return_values = closure(solved_deps...)

        if typeof(return_values) <: Tuple
            s.solved = return_values[1]
            for a in return_values[2:end]
                if !(typeof(a) <: Attribute)
                    error("You can't return a non-attribute with type $(typeof(a)) in a tuple from a closure.")
                end
                s.attrs[typeof(a)] = a
            end
        else
            s.solved = return_values
        end

        return s.solved
    end
    # the dependencies should be converted into this shapes's transform
    # then the solution is also in this shape's transform
end
