export scaleby

function Transform(;scale=1, rotation=rad(0), translation=(0, 0))
    Transform(scale, rotation, translation)
end

Base.Broadcast.broadcastable(t::Transform) = Ref(t)

function rotmat(ang::Angle)
    SMatrix{2, 2}(cos(ang.rad), sin(ang.rad), -sin(ang.rad), cos(ang.rad))
end

function Base.:*(t1::Transform, t2::Transform)
    rmat = rotmat(t1.rotation)
    scale = t1.scale * t2.scale
    rotation = t2.rotation + t1.rotation
    translation = t1.scale * (rmat * t2.translation) + t1.translation
    Transform(scale, rotation, translation)
end

function inverse(t::Transform)
    scale = 1 / t.scale
    rotation = -1 * t.rotation
    rmat = rotmat(rotation)

    translation = -scale * rmat * t.translation
    Transform(scale, rotation, translation)
end

function from_to(t1::Transform, t2::Transform)
    t2 * inverse(t1)
end

function scaleby(t::Transform, s::Real)
    Transform(t.scale * s, t.rotation, t.translation)
end
