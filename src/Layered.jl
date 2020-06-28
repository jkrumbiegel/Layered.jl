module Layered

using StaticArrays

using Reexport
@reexport using Colors
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

function add_shape!(shape, layer::Layer, args...)

end

for geom in geoms

    lowerc = Symbol(lowercase(String(geom)))
    lowerc_plural = Symbol(lowercase(String(geom)) * "s")
    lowerc_mutating = Symbol(lowercase(String(geom)) * "!")
    lowerc_plural_mutating = Symbol(lowercase(String(geom)) * "s!")


    @eval begin
        $geom(g::$geom) = $geom((getfield(g, k) for k ∈ fieldnames($geom))...)


        """
        $($lowerc)(args...)

        Creates a shape containing a `GeometricObject` of type `$($geom)`,
        passing any trailing arguments to the constructor `$($geom)()`."""
        $lowerc(args...) = Shape($geom, args...)

        """
        $($lowerc)(f::Function, args...)

        Creates a shape containing a `GeometricObject` of type `$($geom)`,
        storing any trailing arguments as dependencies, later to be passed as arguments
        to the given `Function` `f` that should return a `GeometricObject` of type `$($geom)`
        and will be evaluated when `solve!` is called on the shape during
        the drawing process."""
        $lowerc(f::Function, args...) = Shape(f, $geom, args...)

        """
        $($lowerc_mutating)(layer::Layer, args...)

        Creates a shape containing a `GeometricObject` of type `$($geom)`,
        passing any trailing arguments to the constructor `$($geom)()`. Then
        appends the created shape to the given `Layer` `layer`."""
        function $lowerc_mutating(layer::Layer, args...)
            x = $lowerc(args...)
            push!(layer, x)
            x
        end

        """
        $($lowerc_mutating)(f::Function, layer::Layer, args...)

        Creates a shape containing a `GeometricObject` of type `$($geom)`,
        storing any trailing arguments as dependencies, later to be passed as arguments
        to the given `Function` `f` that should return a `GeometricObject` of type `$($geom)`
        and will be evaluated when `solve!` is called on the shape during
        the drawing process. This function then appends the created shape to the given `Layer` `layer`."""
        function $lowerc_mutating(f::Function, layer::Layer, args...)
            x = $lowerc(f, args...)
            push!(layer, x)
            x
        end



        """
        $($lowerc_plural)(args...)

        Creates `Shapes` containing `GeometricObject`s of type `$($geom)`,
        passing any trailing arguments to the constructor `$($geom).()`."""
        $lowerc_plural(args...) = Shapes($geom, args...)

        """
        $($lowerc_plural)(f::Function, args...)

        Creates shapes containing `GeometricObject`s of type `$($geom)`,
        storing any trailing arguments as dependencies, later to be passed as arguments
        to the given `Function` `f` that should return `GeometricObject`s of type `$($geom)`
        and will be evaluated when `solve!` is called on the shapes during
        the drawing process."""
        $lowerc_plural(f::Function, args...) = Shapes(f, $geom, args...)

        """
        $($lowerc_plural_mutating)(layer::Layer, args...)

        Creates `Shapes` containing `GeometricObject`s of type `$($geom)`,
        passing any trailing arguments to the constructor `$($geom).()`. Then
        appends the created `Shapes` to the given `Layer` `layer`."""
        function $lowerc_plural_mutating(layer::Layer, args...)
            x = $lowerc_plural(args...)
            push!(layer, x)
            x
        end

        """
        $($lowerc_plural_mutating)(f::Function, layer::Layer, args...)

        Creates multiple shapes containing `GeometricObject`s of type `$($geom)`,
        storing any trailing arguments as dependencies, later to be passed as arguments
        to the given `Function` `f` that should return the `GeometricObject`s of type `$($geom)`
        and will be evaluated when `solve!` is called on the shapes during
        the drawing process. This function then appends the created shapes to the given `Layer` `layer`."""
        function $lowerc_plural_mutating(f::Function, layer::Layer, args...)
            x = $lowerc_plural(f, args...)
            push!(layer, x)
            x
        end        

        export $geom, $lowerc, $lowerc_mutating, $lowerc_plural, $lowerc_plural_mutating

    end
end

end # module
