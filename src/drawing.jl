import PyPlot

export draw

function draw(l::Layer)
    for c in l.content
        draw(c)
    end
end

function draw(s::Shape)
    draw(solve!(s))
end

function draw(p::Point)
    PyPlot.scatter(p.x, p.y)
end

function draw(l::Line)
    PyPlot.plot([l.from, l.to])
end

function PyPlot.plot(v::Vector{Point})
    xx = [p.x for p in v]
    yy = [p.y for p in v]
    PyPlot.plot(xx, yy)
end

function draw(c::Circle)
    vertices = point_at_angle.(c, deg.(range(0, 360, length=100)))
    PyPlot.plot(vertices)
end

function draw(r::Rect)
    vertices = [topleft(r), topright(r), bottomright(r), bottomleft(r), topleft(r)]
    PyPlot.plot(vertices)
end
