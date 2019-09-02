Base.Broadcast.broadcastable(a::Angle) = Ref(a)

deg(ang::Real) = Angle(deg2rad(ang))
rad(ang::Real) = Angle(ang)
deg(ang::Angle) = rad2deg(ang.rad)
rad(ang::Angle) = ang.rad

Base.:+(a1::Angle, a2::Angle) = Angle(a1.rad + a2.rad)
Base.:-(a1::Angle, a2::Angle) = Angle(a1.rad - a2.rad)
Base.:-(a::Angle) = Angle(-a.rad)
Base.:*(a::Angle, r::Real) = Angle(a.rad * r)
Base.:*(r::Real, a::Angle) = a * r
Base.:/(a::Angle, r::Real) = Angle(a.rad / r)
Base.:/(a1::Angle, a2::Angle) = a1.rad / a2.rad
Base.cos(a::Angle) = cos(a.rad)
Base.sin(a::Angle) = sin(a.rad)
Base.tan(a::Angle) = tan(a.rad)
Base.isless(a1::Angle, a2::Angle) = a1.rad < a2.rad
Base.isgreater(a1::Angle, a2::Angle) = a1.rad > a2.rad
Base.isequal(a1::Angle, a2::Angle) = a1.rad == a2.rad
