function Shape(g::GeometricObject)
    Shape(g, nothing, nothing, Attributes(), Clip(nothing), Opacity(1), Operator())
end

function Shape(::Type{T}, args...) where T <: GeometricObject
    Shape(T(args...), nothing, nothing, Attributes(), Clip(nothing), Opacity(1), Operator())
end

function Shape(f::Function, ::Type{T}, deps...) where T
    Shape{T}((f, [deps...]), nothing, nothing, Attributes(), Clip(nothing), Opacity(1), Operator())
end

function Shapes(arr::Array{T}) where T <: GeometricObject
    Shapes(arr, nothing, nothing, Attributes(), Clip(nothing), Opacity(1), Operator())
end

function Shapes(::Type{T}, args...) where T <: GeometricObject
    Shapes(T.(args...), nothing, nothing, Attributes(), Clip(nothing), Opacity(1), Operator())
end

function Shapes(f::Function, ::Type{T}, deps...) where T
    Shapes{T}((f, [deps...]), nothing, nothing, Attributes(), Clip(nothing), Opacity(1), Operator())
end

const Shapelike = Union{Shape, Shapes}

Base.Broadcast.broadcastable(s::Shapelike) = Ref(s)
Base.Broadcast.broadcastable(s::Shapes) = Ref(s)

function Base.copy!(l::Layer, s::Shape{T}) where T
    news = Shape{T}(s.content, nothing, nothing, Attributes(), s.clip, s.opacity, s.operator)
    for (Ta, attr) in s.attrs.attrs
        news + attr
    end
    push!(l, news)
    news
end

function upward_transform(s::Shapelike)
    return upward_transform(s.parent)
end

function solve!(s::Shape{T}, cc::Cairo.CairoContext) where T

    # the shape was already solved
    if !isnothing(s.solved)
        return s.solved
    end

    # the shape's content was given directly without a closure function
    if typeof(s.content) <: GeometricObject
        s.solved = s.content

        # extra logic for text, get the extents
        if T <: Txt
            t = s.solved
            if isnothing(t.extent)
                t_with_extent = Txt(t, TextExtent(cc, t))
                s.solved = t_with_extent
            end
        end

        return s.solved

    # the shape's content was given as a function with dependencies
    else
        closure = s.content[1]
        dependencies = s.content[2]

        solved_deps = []
        for d in dependencies
            if typeof(d) <: Shape
                solved = solve!(d, cc)

                t = transform_from_to(d, s, cc)
                transformed = t * solved
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

        if typeof(s.solved) <: Txt
            t = s.solved
            if isnothing(t.extent)
                t_with_extent = Txt(t, TextExtent(cc, t))
                s.solved = t_with_extent
            end
        end

        return s.solved
    end
    # the dependencies should be converted into this shapes's transform
    # then the solution is also in this shape's transform
end


function solve!(s::Shapes{T}, cc::Cairo.CairoContext) where T <: GeometricObject

    # the shape was already solved
    if !isnothing(s.solved)
        return s.solved
    end

    # the shape's content was given directly without a closure function
    if typeof(s.content) <: Array{T}
        s.solved = s.content

        # extra logic for text, get the extents
        if T <: Txt
            ts = s.solved
            for (i, t) in enumerate(ts)
                if isnothing(t.extent)
                    t_with_extent = Txt(t, TextExtent(cc, ts))
                    ts[i] = t_with_extent
                end
            end
        end

        return s.solved

    # the shape's content was given as a function with dependencies
    else
        closure = s.content[1]
        dependencies = s.content[2]

        solved_deps = []
        for d in dependencies
            if typeof(d) <: Shape
                solved = solve!(d, cc)

                t = transform_from_to(d, s, cc)
                transformed = t * solved
                push!(solved_deps, transformed)
            elseif typeof(d) <: Shapes
                solved = solve!(d, cc)

                t = transform_from_to(d, s, cc)
                transformed = t .* solved
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

        if typeof(s.solved) <: Array{Txt{Nothing}}
            ts = s.solved
            for (i, t) in enumerate(ts)
                if isnothing(t.extent)
                    t_with_extent = Txt(t, TextExtent(cc, ts))
                    ts[i] = t_with_extent
                end
            end
        end

        return s.solved
    end
    # the dependencies should be converted into this shapes's transform
    # then the solution is also in this shape's transform
end
