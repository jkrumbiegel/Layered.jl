export rect!

struct Rect <: GeometricObject
    center::Point
    width::Float64
    height::Float64
    angle::Angle
end

rect(args...) = Shape(Rect(args[1:4]...), args[5:end]...)
function rect!(layer::Layer, args...)
    r = rect(args...)
    push!(layer, r)
    r
end
rect(f::Function, args...) = Shape(f, Rect, args...)
function rect!(f::Function, layer::Layer, args...)
    r = rect(f, args...)
    push!(layer, r)
    r
end

needed_attributes(::Type{Rect}) = needed_attributes(Circle)

function bottomleft(r::Rect)
    r.center + rotate(Point(-r.width * 0.5, -r.height * 0.5), r.angle)
end

function bottomright(r::Rect)
    r.center + rotate(Point( r.width * 0.5, -r.height * 0.5), r.angle)
end

function topleft(r::Rect)
    r.center + rotate(Point(-r.width * 0.5,  r.height * 0.5), r.angle)
end

function topright(r::Rect)
    r.center + rotate(Point( r.width * 0.5,  r.height * 0.5), r.angle)
end

topline(r::Rect) = Line(topleft(r), topright(r))
bottomline(r::Rect) = Line(bottomleft(r), bottomright(r))
leftline(r::Rect) = Line(bottomleft(r), topleft(r))
rightline(r::Rect) = Line(bottomright(r), topright(r))

function Point(r::Rect, nx::Real, ny::Real, mode::Symbol=:norm)
    if mode == :norm
        r.center + Point(r.angle) * (nx - 0.5) * r.width + Point(r.angle + deg(90)) * (ny - 0.5) * r.height
    else
        error("Mode $mode is invalid")
    end
end
