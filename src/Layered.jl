module Layered

using StaticArrays
import Colors
using Match
import Cairo

export Transform, Layer, Shape, upward_transform, solve!, →, Angle, rad, deg, needed_attributes

include("types.jl")
include("angles.jl")
include("geometry.jl")
include("gradient.jl")
include("attributes.jl")
include("transform.jl")
include("layer.jl")
include("shape.jl")
include("canvas.jl")
include("drawing.jl")
include("video.jl")
include("helpers.jl")

Base.Broadcast.broadcastable(g::GeometricObject) = Ref(g)


for geom in geoms

    lowerc = Symbol(lowercase(String(geom)))
    lowerc_plural = Symbol(lowercase(String(geom)) * "s")
    lowerc_exc = Symbol(lowercase(String(geom)) * "!")
    lowerc_plural_exc = Symbol(lowercase(String(geom)) * "s!")
    lowerc_first_exc = Symbol(lowercase(String(geom)) * "_first!")
    lowerc_pre_exc = Symbol(lowercase(String(geom)) * "_pre!")
    lowerc_post_exc = Symbol(lowercase(String(geom)) * "_post!")


    @eval begin
        $geom(g::$geom) = $geom((getfield(g, k) for k ∈ fieldnames($geom))...)


        """
        $($lowerc)(args...)

        Creates a shape containing a `GeometricObject` of type `$($geom)`,
        passing any trailing arguments to the constructor `$($geom)()`."""
        $lowerc(args...) = Shape($geom, args...)

        """
        $($lowerc_plural)(args...)

        Creates `Shapes` containing `GeometricObject`s of type `$($geom)`,
        passing any trailing arguments to the constructor `$($geom).()`."""
        $lowerc_plural(args...) = Shapes($geom, args...)

        """
        $($lowerc_exc)(layer::Layer, args...)

        Creates a shape containing a `GeometricObject` of type `$($geom)`,
        passing any trailing arguments to the constructor `$($geom)()`. Then
        appends the created shape to the given `Layer` `layer`."""
        function $lowerc_exc(layer::Layer, args...)
            x = $lowerc(args...)
            push!(layer, x)
            x
        end

        """
        $($lowerc_plural_exc)(layer::Layer, args...)

        Creates `Shapes` containing `GeometricObject`s of type `$($geom)`,
        passing any trailing arguments to the constructor `$($geom).()`. Then
        appends the created `Shapes` to the given `Layer` `layer`."""
        function $lowerc_plural_exc(layer::Layer, args...)
            x = $lowerc_plural(args...)
            push!(layer, x)
            x
        end

        """
        $($lowerc_first_exc)(layer::Layer, args...)

        Creates a shape containing a `GeometricObject` of type `$($geom)`,
        passing any trailing arguments to the constructor `$($geom)()`. Then
        prepends the created shape to the given `Layer` `layer`."""
        function $lowerc_first_exc(layer::Layer, args...)
            x = $lowerc(args...)
            pushfirst!(layer, x)
            x
        end

        """
        $($lowerc_pre_exc)(layer::Layer, pre::LayerContent, args...)

        Creates a shape containing a `GeometricObject` of type `$($geom)`,
        passing any trailing arguments to the constructor `$($geom)()`. Then
        inserts the created shape into the given `Layer` `layer` before the given
        `LayerContent` object."""
        function $lowerc_pre_exc(layer::Layer, pre::LayerContent, args...)
            x = $lowerc(args...)
            for (i, c) in enumerate(layer.content)
                if c === pre
                    insert!(layer, i, x)
                    return x
                end
            end
            error("Could not find given shape in layer.")
        end

        """
        $($lowerc_post_exc)(layer::Layer, post::LayerContent, args...)

        Creates a shape containing a `GeometricObject` of type `$($geom)`,
        passing any trailing arguments to the constructor `$($geom)()`. Then
        inserts the created shape into the given `Layer` `layer` after the given
        `LayerContent` object."""
        function $lowerc_post_exc(layer::Layer, post::LayerContent, args...)
            x = $lowerc(args...)
            for (i, c) in enumerate(layer.content)
                if c === post
                    insert!(layer, i+1, x)
                    return x
                end
            end
            error("Could not find given shape in layer.")
        end

        """
        $($lowerc)(f::Function, args...)

        Creates a shape containing a `GeometricObject` of type `$($geom)`,
        storing any trailing arguments as dependencies, later to be passed as arguments
        to the given `Function` `f` that should return a `GeometricObject` of type `$($geom)`
        and will be evaluated when `solve!` is called on the shape during
        the drawing process."""
        $lowerc(f::Function, args...) = Shape(f, $geom, args...)

        """
        $($lowerc_plural)(f::Function, args...)

        Creates shapes containing `GeometricObject`s of type `$($geom)`,
        storing any trailing arguments as dependencies, later to be passed as arguments
        to the given `Function` `f` that should return `GeometricObject`s of type `$($geom)`
        and will be evaluated when `solve!` is called on the shapes during
        the drawing process."""
        $lowerc_plural(f::Function, args...) = Shapes(f, $geom, args...)


        """
        $($lowerc_exc)(f::Function, layer::Layer, args...)

        Creates a shape containing a `GeometricObject` of type `$($geom)`,
        storing any trailing arguments as dependencies, later to be passed as arguments
        to the given `Function` `f` that should return a `GeometricObject` of type `$($geom)`
        and will be evaluated when `solve!` is called on the shape during
        the drawing process. This function then appends the created shape to the given `Layer` `layer`."""
        function $lowerc_exc(f::Function, layer::Layer, args...)
            x = $lowerc(f, args...)
            push!(layer, x)
            x
        end

        """
        $($lowerc_plural_exc)(f::Function, layer::Layer, args...)

        Creates multiple shapes containing `GeometricObject`s of type `$($geom)`,
        storing any trailing arguments as dependencies, later to be passed as arguments
        to the given `Function` `f` that should return the `GeometricObject`s of type `$($geom)`
        and will be evaluated when `solve!` is called on the shapes during
        the drawing process. This function then appends the created shapes to the given `Layer` `layer`."""
        function $lowerc_plural_exc(f::Function, layer::Layer, args...)
            x = $lowerc_plural(f, args...)
            push!(layer, x)
            x
        end


        """
        $($lowerc_first_exc)(f::Function, layer::Layer, args...)

        Creates a shape containing a `GeometricObject` of type `$($geom)`,
        storing any trailing arguments as dependencies, later to be passed as arguments
        to the given `Function` `f` that should return a `GeometricObject` of type `$($geom)`
        and will be evaluated when `solve!` is called on the shape during
        the drawing process. This function then prepends the created shape to the given `Layer` `layer`."""
        function $lowerc_first_exc(f::Function, layer::Layer, args...)
            x = $lowerc(f, args...)
            pushfirst!(layer, x)
            x
        end

        """
        $($lowerc_pre_exc)(f::Function, layer::Layer,  pre::LayerContent, args...)

        Creates a shape containing a `GeometricObject` of type `$($geom)`,
        storing any trailing arguments as dependencies, later to be passed as arguments
        to the given `Function` `f` that should return a `GeometricObject` of type `$($geom)`
        and will be evaluated when `solve!` is called on the shape during
        the drawing process. This function then inserts the created shape into the given `Layer` `layer` before the given
        `LayerContent` object."""
        function $lowerc_pre_exc(f::Function, layer::Layer, pre::LayerContent, args...)
            x = $lowerc(f, args...)
            for (i, c) in enumerate(layer.content)
                if c === pre
                    insert!(layer, i, x)
                    return x
                end
            end
            error("Could not find given shape in layer.")
        end

        """
        $($lowerc_post_exc)(f::Function, layer::Layer, post::LayerContent, args...)

        Creates a shape containing a `GeometricObject` of type `$($geom)`,
        storing any trailing arguments as dependencies, later to be passed as arguments
        to the given `Function` `f` that should return a `GeometricObject` of type `$($geom)`
        and will be evaluated when `solve!` is called on the shape during
        the drawing process. This function then inserts the created shape into the given `Layer` `layer` after the given
        `LayerContent` object."""
        function $lowerc_post_exc(f::Function, layer::Layer, post::LayerContent, args...)
            x = $lowerc(f, args...)
            for (i, c) in enumerate(layer.content)
                if c === post
                    insert!(layer, i+1, x)
                    return x
                end
            end
            error("Could not find given shape in layer.")
        end

        export $geom, $lowerc, $lowerc_exc, $lowerc_first_exc, $lowerc_pre_exc, $lowerc_post_exc, $lowerc_plural, $lowerc_plural_exc

    end
end

end # module
