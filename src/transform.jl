struct Transform
    scale::Float64
    rotation::Float64
    translation::SVector{2, Float64}
end

function Transform(;scale=1, rotation=0, translation=(0, 0))
    Transform(scale, rotation, translation)
end

function rotmat(ang)
    SMatrix{2, 2}(cos(ang), sin(ang), -sin(ang), cos(ang))
end

function Base.:*(t1::Transform, t2::Transform)
    rmat = rotmat(t1.rotation)
    scale = t1.scale * t2.scale
    rotation = t2.rotation + t1.rotation
    translation = t1.scale * (rmat * t2.translation) + t1.translation
    Transform(scale, rotation, translation)
end
