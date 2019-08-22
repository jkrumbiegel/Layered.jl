export Polygon, polygon, polygon!, ncross

struct Polygon <: GeometricObject
    points::Vector{Point}
end

polygon(args...) = Shape(Polygon(args[1:fieldcount(Polygon)]...), args[fieldcount(Polygon)+1:end]...)
function polygon!(layer::Layer, args...)
    r = polygon(args...)
    push!(layer, r)
    r
end
polygon(f::Function, args...) = Shape(f, Polygon, args...)
function polygon!(f::Function, layer::Layer, args...)
    r = polygon(f, args...)
    push!(layer, r)
    r
end

needed_attributes(::Type{Polygon}) = (Linewidth, Stroke, Linestyle, Fill)

Base.convert(::Type{Polygon}, ps::Vector{Point}) = Polygon(ps)


function ncross(pos::Point, n::Int, r::Real, thickness::Real, angle::Angle=deg(0))
    if n < 3
        error("ncross needs at least three arms")
    end
    angles = deg.(range(0, 360, length=n+1)[1:end-1]) .+ angle
    routcorners = rotate.(Point(r, -0.5*thickness * r), angles)
    loutcorners = rotate.(Point(r,  0.5*thickness * r), angles)
    inner_point1 = intersection(
        Line(loutcorners[1], Point(0, loutcorners[1].y)),
        Line(routcorners[2], routcorners[2] - Point(angles[2]))
    )
    inner_points = rotate.(inner_point1, angles)
    collect(Iterators.flatten((r, l, i) for (r, l, i) in zip(routcorners, loutcorners, inner_points)))
end
