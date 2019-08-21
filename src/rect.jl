struct Rect <: GeometricObject
    center::Point
    width::Float64
    height::Float64
    angle::Angle
end

rect(args...) = Shape(Rect(args[1:4]...), args[5:end]...)
rect(f::Function, args...) where N = Shape(f, Rect, args...)

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
