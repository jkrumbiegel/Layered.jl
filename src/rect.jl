struct Rect <: GeometricObject
    center::Point
    width::Float64
    height::Float64
    angle::Float64
    degrees::Bool
end

function lowerleft(r::Rect)
    r.center + rotate(Point(-r.width * 0.5, -r.height * 0.5), r.angle, degrees=r.degrees)
end

function lowerright(r::Rect)
    r.center + rotate(Point( r.width * 0.5, -r.height * 0.5), r.angle, degrees=r.degrees)
end

function upperleft(r::Rect)
    r.center + rotate(Point(-r.width * 0.5,  r.height * 0.5), r.angle, degrees=r.degrees)
end

function upperright(r::Rect)
    r.center + rotate(Point( r.width * 0.5,  r.height * 0.5), r.angle, degrees=r.degrees)
end

topline(r::Rect) = Line(upperleft(r), upperright(r))
bottomline(r::Rect) = Line(lowerleft(r), lowerright(r))
leftline(r::Rect) = Line(lowerleft(r), upperleft(r))
rightline(r::Rect) = Line(lowerright(r), upperright(r))
