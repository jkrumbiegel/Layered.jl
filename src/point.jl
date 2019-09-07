export between, P, O, X, Y, xs, ys, magnitude, normalize, signed_angle_to

X(x::Real) = P(x, 0)
Y(y::Real) = P(0, y)
const O = P(0, 0)

xs(ps::Array{Point}) = [p.x for p in ps]
ys(ps::Array{Point}) = [p.y for p in ps]

Point(ang::Angle) = Point(cos(ang.rad), sin(ang.rad))

Base.convert(::Type{Point}, t::Tuple{S, T}) where {S<:Real,T<:Real} = Point(t[1], t[2])

Base.show(io::IO, p::Point) = print(io, "Point($(p.xy[1]), $(p.xy[2]))")

function needed_attributes(::Type{Point})
    (Visible, Fill, Stroke, Markersize, Marker)
end

magnitude(p::Point) = sqrt(sum(p.xy .^ 2))
normalize(p::Point) = p / magnitude(p)

function Base.getproperty(p::Point, sym::Symbol)
    if sym == :x
        return p.xy[1]
    elseif sym == :y
        return p.xy[2]
    else
        getfield(p, sym)
    end
end

Base.convert(::Type{SVector{2, Float64}}, p::Point) = p.xy

Base.:+(p1::Point, p2::Point) = Point(p1.xy + p2.xy)
Base.:-(p1::Point, p2::Point) = Point(p1.xy - p2.xy)
Base.:-(p::Point) = Point(-p.xy)
Base.:*(p::Point, factor::Real) = Point(p.xy .* factor)
Base.:*(factor::Real, p::Point) = p * factor
Base.:/(p::Point, r::Real) = Point(p.xy ./ r)
Base.:(==)(p1::Point, p2::Point) = p1.xy == p2.xy
Base.:(!=)(p1::Point, p2::Point) = p1.xy != p2.xy
from_to(p1::Point, p2::Point) = p2 - p1
const → = from_to
between(p1::Point, p2::Point, fraction::Real) = p1 + (p2 - p1) * fraction
cross(p1::Point, p2::Point) = p1.x * p2.y - p1.y * p2.x
dot(p1::Point, p2::Point) = p1.x * p2.x + p1.y * p2.y

Base.isapprox(p1::Point, p2::Point) = Base.isapprox(magnitude(p1 → p2), 0; atol=6)

function Base.angle(p::Point)
    Angle(atan(p.y, p.x))
end

function signed_angle_to(p1::Point, p2::Point)
    Angle(atan(cross(p1, p2), dot(p1, p2)))
end

function _rotation_matrix(angle::Angle)
    c = cos(angle)
    s = sin(angle)
    SMatrix{2, 2, Float64}(c, s, -s, c)
end

function rotate(p::Point, angle::Angle; around::Point=Point(0, 0))
    vector = from_to(around, p)
    rotated_vector = Point(_rotation_matrix(angle) * vector.xy)
    rotated_vector + around
end


needed_attributes(::Type{Points}) = (Visible, Fills, Strokes, Markersizes, Marker)

Base.convert(::Type{Points}, ps::Vector{Point}) = Points(ps)
