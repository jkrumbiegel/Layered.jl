export ncross, grow, center

Polygon(points::Vararg{T, N}) where {T <: Point, N} = Polygon([points...])

needed_attributes(::Type{Polygon}) = (Visible, Linewidth, Stroke, Linestyle, Fill)

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
    collect(Iterators.flatten((r, l, i) for (r, l, i) in zip(routcorners, loutcorners, inner_points))) .+ pos
end

# function nstar(pos::Point)

function center(pol::Polygon)
    Point(sum([p.xy for p in pol.points]) / length(pol.points))
end

function grow(p::Polygon, factor::Real; from::Union{Point, Nothing}=nothing)
    c = isnothing(from) ? center(p) : from
    dists = from_to.(c, p.points)
    Polygon(dists .* factor .+ c)
end
