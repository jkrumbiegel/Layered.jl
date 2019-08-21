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

topline(r::Rect) = Line(upperleft(r), upperright(r))
bottomline(r::Rect) = Line(lowerleft(r), lowerright(r))
leftline(r::Rect) = Line(lowerleft(r), upperleft(r))
rightline(r::Rect) = Line(lowerright(r), upperright(r))
