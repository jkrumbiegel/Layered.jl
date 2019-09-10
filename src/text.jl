export defaultfont

Txt(pos::Point,
    text::String,
    size::Real,
    halign::Symbol,
    valign::Symbol=:c,
    angle::Angle=deg(0),
    font::String=defaultfont()) = Txt(pos, text, size, halign, valign, angle, font, nothing)

Txt(t::Txt, extent::TextExtent) = Txt(t.pos, t.text, t.size, t.halign, t.valign, t.angle, t.font, extent)

function Txt(pos::Point, text::String, size::Real; ha=:c, va=:c, angle=deg(0), font=defaultfont())
    Txt(pos, text, size, ha, va, angle, font)
end

needed_attributes(::Type{Txt}) = (Visible, Textfill)

function Base.:*(r::Real, te::TextExtent)
    TextExtent(
        te.xbearing * r,
        te.ybearing * r,
        te.width * r,
        te.height * r,
        te.xadvance * r,
        te.yadvance * r
    )
end

_defaultfont = "Helvetica Neue"

defaultfont() = _defaultfont
function defaultfont(font::String)
    global _defaultfont = font
end
