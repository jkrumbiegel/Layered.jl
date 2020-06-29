export topright, topleft, bottomright, bottomleft, topline, rightline, bottomline, leftline


Rect(p, w, h) = Rect(p, w, h, deg(0))

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

function Point(r::Rect, nx::Real, ny::Real, mode::Symbol=:norm)
    if mode == :norm
        r.center + Point(r.angle) * (nx - 0.5) * r.width + Point(r.angle + deg(90)) * (ny - 0.5) * r.height
    else
        error("Mode $mode is invalid")
    end
end

function Rect(t::Txt)
    w = t.extent.width
    h = t.extent.height
    wh = P(w, h)
    ang = t.angle
    xshift = @match t.halign begin
        :c => 0
        :l => w/2
        :r => -w/2
        _ => error("Not implemented")
    end
    yshift = @match t.valign begin
        :c => 0
        :t => h/2
        :b => -h/2
        # :bl => (t.pos - rotate(wh / 2, ang)).y
        _ => error("Not implemented")
    end
    center = t.pos + rotate(P(xshift, yshift), ang)
    Rect(center, w, h, ang)
end

function Rect(t::Txt, margin::Real)
    r = Rect(t)
    Rect(r.center, r.width + 2 * margin, r.height + 2 * margin, r.angle)
end

Rect(bb::BBox) = Rect((bb.from + bb.to) / 2, bb.to.x - bb.from.x, bb.to.y - bb.from.y, deg(0))
