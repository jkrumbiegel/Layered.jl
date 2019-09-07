export Txt, text, text!

struct Txt{T <: Union{Nothing, TextExtent}} <: GeometricObject
    pos::Point
    text::String
    size::Float64
    halign::Symbol
    valign::Symbol
    angle::Angle
    font::String
    extent::T
end

Txt(pos::Point,
    text::String,
    size::Real,
    halign::Symbol,
    valign::Symbol,
    angle::Angle,
    font::String) = Txt{Nothing}(pos, text, size, halign, valign, angle, font, nothing)

Txt(t::Txt, extent::TextExtent) = Txt(t.pos, t.text, t.size, t.halign, t.valign, t.angle, t.font, extent)

text(args...) = Shape(Txt, args...)
function text!(layer::Layer, args...)
    r = text(args...)
    push!(layer, r)
    r
end
text(f::Function, args...) = Shape(f, Txt, args...)
function text!(f::Function, layer::Layer, args...)
    r = text(f, args...)
    push!(layer, r)
    r
end

needed_attributes(::Type{Txt}) = (Visible, Fill, Font)
