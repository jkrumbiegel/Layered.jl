struct CircularArc <: GeometricObject
    center::Point
    radius::Float64
    start_angle::Angle
    end_angle::Angle
end

function CircularArc(p1::Point, p2::Point, p3::Point)
    circle = Circle(p1, p2, p3)
    start_angle = angle(from_to(circle.center, p1))
    end_angle = angle(from_to(circle.center, p3))

    if signed_angle_to(from_to(p1, p3), from_to(p1, p2)) > 0
        start_angle, end_angle = end_angle, start_angle
    end
    CircularArc(circle.center, circle.radius, start_angle, end_angle)
end
