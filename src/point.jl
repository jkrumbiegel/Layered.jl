struct Point <: GeometricObject
    xy::SVector{2, Float64}

    Point(x::Real, y::Real) = new(SVector(convert(Float64, x), convert(Float64, y)))
    function Point(xy)
        if Base.length(xy) != 2
            error("need 2 elements")
        end
        new(SVector{2, Float64}(xy...))
    end
end

point(args...) = Shape(Point(args...))
point(f::Function, deps::Vararg{Shape,N}) where N = Shape(f, Point, deps...)

Base.show(io::IO, p::Point) = print(io, "Point($(p.xy[1]), $(p.xy[2]))")

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

Base.:+(p1::Point, p2::Point) = Point(p1.xy + p2.xy)
Base.:-(p1::Point, p2::Point) = Point(p1.xy - p2.xy)
Base.:*(p::Point, factor::Real) = Point(p.xy .* factor)
Base.:*(factor::Real, p::Point) = p * factor
Base.:/(p::Point, r::Real) = Point(p.xy ./ r)
from_to(p1::Point, p2::Point) = p2 - p1
const → = from_to
between(p1::Point, p2::Point, fraction::Real) = p1 + (p2 - p1) * fraction
cross(p1::Point, p2::Point) = p1.x * p2.y - p1.y * p2.x
dot(p1::Point, p2::Point) = p1.x * p2.x + p1.y * p2.y

function angle(p::Point; degrees=True)
    radians = atan(p.y, p.x)
    degrees ? rad2deg(radians) : radians
end

function signed_angle_to(p1::Point, p2::Point; degrees::Bool=true)
    radians = atan(cross(p1, p2), dot(p1, p2))
    return degrees ? rad2deg(radians) : radians
end

function _rotation_matrix(angle; degrees=true)
    angle = degrees ? deg2rad(angle) : angle
    c = cos(angle)
    s = sin(angle)
    SMatrix{2, 2, Float64}(c, s, -s, c)
end

function rotate(p::Point, angle::Real; around::Point=Point(0, 0), degrees=true)
    vector = from_to(around, p)
    rotated_vector = Point(_rotation_matrix(angle, degrees=degrees) * vector.xy)
    rotated_vector + around
end
