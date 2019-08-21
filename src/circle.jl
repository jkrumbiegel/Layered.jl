struct Circle <: GeometricObject
    center::Point
    radius::Float64
end

function Circle(p1::Point, p2::Point, p3::Point)
    circlethrough(p1, p2, p3)
end

function circlethrough(p1::Point, p2::Point, p3::Point)
    l1 = Line(p1, p2)
    c1 = fraction(l1, 0.5)
    l2 = Line(p2, p3)
    c2 = fraction(l2, 0.5)

    dl1 = vector(l1)
    dl2 = vector(l2)
    cl1 = Line(c1, c1 + Point(dl1.y, -dl1.x))
    cl2 = Line(c2, c2 + Point(dl2.y, -dl2.x))

    center = intersection(cl1, cl2)
    radius = from_to(p1, center) |> magnitude
    Circle(center, radius)
end

function Circle(center::Point, p1::Point)
    radius = from_to(center, p1) |> magnitude
    Circle(center, radius)
end

circle(args...) = Shape(Circle(args...))
circle(f::Function, deps::Vararg{Shape,N}) where N = Shape(f, Circle, deps...)

function intersection(c::Circle, l::Line)
    # algorithm works for circle at (0, 0)
    frm_moved = l.from - c.center
    to_moved = l.to - c.center
    dx, dy = from_to(frm_moved, to_moved).xy
    dr = sqrt(dx ^ 2 + dy ^ 2)
    D = cross(frm_moved, to_moved)

    delta = (c.radius ^ 2) * (dr ^ 2) - (D ^ 2)

    if abs(delta) < 1e-10
        # tangent
        x = D * dy / (dr ^ 2)
        y = -D * dx / (dr ^ 2)
        return Point(x, y) + c.center
    elseif delta < 0
        return nothing
    else
        xplusminus = sign(dy) * dx * sqrt(delta)
        yplusminus = abs(dy) * sqrt(delta)

        x1 = (D * dy + xplusminus) / (dr ^ 2)
        x2 = (D * dy - xplusminus) / (dr ^ 2)
        y1 = (-D * dx + yplusminus) / (dr ^ 2)
        y2 = (-D * dx - yplusminus) / (dr ^ 2)
        return (Point(x1, y1) + c.center, Point(x2, y2) + c.center)
    end
end

function tangentpoints(c::Circle, through::Point)
    p_to_center = from_to(through, c.center)
    a = asin(c.radius / magnitude(p_to_center))
    b = atan(p_to_center.y, p_to_center.x)
    t1 = b - a
    p_tangent_1 = Point(sin(t1), -cos(t1)) * c.radius + c.center
    t2 = b + a
    p_tangent_2 = Point(-sin(t2), cos(t2)) * c.radius + c.center
    return p_tangent_1, p_tangent_2
end

function tangents(c::Circle, through::Point)
    p_tangent_1, p_tangent_2 = tangentpoints(c, through)
    return Line(through, p_tangent_1), Line(through, p_tangent_2)
end

function outertangents(c1::Circle, c2::Circle)
    big_circle, small_circle = c1.radius > c2.radius ? (c1, c2) : (c2, c1)
    radius_difference = big_circle.radius - small_circle.radius
    gamma = -atan(big_circle.center.y - small_circle.center.y, big_circle.center.x - small_circle.center.x)

    beta = asin(radius_difference / magnitude(from_to(small_circle.center, big_circle.center)))
    alpha1 = gamma - beta
    alpha2 = gamma + beta

    small_tangent_point_1 = small_circle.center + Point(
        small_circle.radius * cos(pi / 2 - alpha1),
        small_circle.radius * sin(pi / 2 - alpha1),
    )

    big_tangent_point_1 = big_circle.center + Point(
        big_circle.radius * cos(pi / 2 - alpha1),
        big_circle.radius * sin(pi / 2 - alpha1),
    )

    small_tangent_point_2 = small_circle.center + Point(
        small_circle.radius * cos(-pi / 2 - alpha2),
        small_circle.radius * sin(-pi / 2 - alpha2),
    )

    big_tangent_point_2 = big_circle.center + Point(
        big_circle.radius * cos(-pi / 2 - alpha2),
        big_circle.radius * sin(-pi / 2 - alpha2),
    )

    return Line(small_tangent_point_1, big_tangent_point_1), Line(small_tangent_point_2, big_tangent_point_2)
end

function point_at_angle(c::Circle, angle::Angle)
    c.center + Point(cos(angle), sin(angle)) * c.radius
end

function closestto(c::Circle, p::Point)
    normalize(from_to(c.center, p)) * c.radius
end

area(c::Circle) = pi * (c.radius ^ 2)
circumference(c::Circle) = 2pi * r
