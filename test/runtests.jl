using Layered
using Test
import PyPlot

@testset "points" begin
    p1 = Point(0, 0)
    p2 = Point(1, 1)
end

@testset "transform" begin
    t1 = Transform(1, rad(0), (0, 0))
    t2 = Transform(1, rad(0), (1, 1))

    t3 = t1 * t2

    p1 = Point(1, 1)

    p1_t1 = t1 * p1
    println(p1_t1)

    p1_t2 = t2 * p1
    println(p1_t2)
end

@testset "layer" begin
    l = Layer()

    p1 = Shape(Point(0, 0))

    push!(l, p1)
end

@testset "upward_transform" begin
    ltop = Layer(Transform(scale=2))
    lmiddle = Layer(Transform(rotation=rad(pi)))
    lbottom = Layer(Transform(translation=(1, 1)))
    push!(ltop, lmiddle)
    push!(lmiddle, lbottom)

    p1 = point(1, 1)
    p2 = point(1, 1)
    p3 = point(→, p1, p2)

    push!(lbottom, p1)
    push!(ltop, p2)
    push!(lmiddle, p3)

    println(upward_transform(p1))

    println(solve!(p1))
    println(solve!(p2))
    println(solve!(p3))
end

@testset "circle" begin
    ltop = Layer(Transform(scale=2))
    lmiddle = Layer(Transform(rotation=rad(pi)))
    lbottom = Layer(Transform(translation=(1, 1)))
    push!(ltop, lmiddle)
    push!(lmiddle, lbottom)

    p1 = point(1, 1)
    p2 = point(1, 1)
    p3 = point(→, p1, p2)

    push!(lbottom, p1)
    push!(ltop, p2)
    push!(lmiddle, p3)

    c = circle(circlethrough, p1, p2, p3)
    println(solve!(c))
end

@testset "draw" begin
    ltop = Layer(Transform(scale=2))
    lmiddle = Layer(Transform(rotation=rad(pi)))
    lbottom = Layer(Transform(translation=(1, 1)))
    push!(ltop, lmiddle)
    push!(lmiddle, lbottom)

    p1 = point(1, 1)
    p2 = point(1, 1)
    p3 = point(→, p1, p2)

    push!(lbottom, p1)
    push!(ltop, p2)
    push!(lmiddle, p3)

    c = circle(circlethrough, p1, p2, p3)
    fig, ax = PyPlot.subplots(1)
    draw(ltop)
    display(fig)
end

using Pkg
pkg"activate ."
using Revise
import PyPlot
using Layered
using Colors

function test2()
    c, l = canvas(6.14, 3.81)
    n = 5

    sls = layer!.((r, i) -> begin
        margin = 20
        avail_w = (r.width - 2margin) / n
        avail_h = (r.height - 2margin) / n
        Transform(translation = topleft(r) + P(margin + (i-0.5) * avail_w, -margin - (i-0.5) * avail_h))
    end, l, c.rect, 1:n)

    rs = rect!.((r, i) -> begin
        Rect(P(0, 0), 90, 60, deg(0))
    end, sls, c.rect, 0:n-1, Fill(Gray(0.5)), Visible(true))

    crosses = polygon!.(r -> begin
        ncross(r.center, 4, 3, 0.3)
    end, sls, rs, Fill("black"), Stroke("transparent"))

    circlesleft = circle!.(r -> begin
        Circle(r.center - X(r.width/4), 10)
    end, sls, rs, Linestyle(:dashed))

    circlesright = circle!.(r -> begin
        Circle(r.center + X(r.width/4), 10)
    end, sls, rs, Linestyle(:dashed))

    focuscircle = circle!.(r -> begin
        Circle(bottomleft(r) + P(60, 60), 50)
    end, l, c.rect,  Linestyle(:dashed))

    textl = layer!(l, Transform())

    text!.(r -> begin
        Txt(bottomleft(r) - Y(1), "test", 10, :l, :t, deg(0))
    end, textl, rs)

    linesegments!((c1, c2) -> begin
        outertangents(c1, c2)
    end, l, focuscircle, circlesright[2], Linestyle(:dashed))

    arr = bezierpath!(l, rs[1], rs[end], Fill("tomato"), Stroke("transparent")) do r1, r2
        a = arrow(topright(r1), topright(r2), 9, 9, 1, 1, 0)
        move(a, perpendicular(Line(topright(r1), topright(r2))) * 5)
    end

    text!(l, arr) do arr
        p = fraction(arr.segments[1], 0.5)
        Txt(p, "time", 10, :c, :b, angle(arr.segments[1]))
    end

    draw(c)
end

test2()

PyPlot.close_figs()

using Animations

function testvideo()

    duration = 2.0

    a_fill = Animation(range(0, duration, length=4), [RGB(1, 0, 0), RGB(0, 1, 0), RGB(0, 0, 1), RGB(1, 0, 0)])
    a_ang = Animation([0, duration], [deg(0), deg(360)], sineio())
    a_zoom = Animation([0, duration], [1, 1.5], sineio(yoyo=true, n=2))

    record("test.mp4", 60, duration; excludelast=true) do t
        c, l = canvas(3, 3)

        bigcirc = circle!(l, c.rect, Visible(false)) do r
            Circle(r.center, r.height * 0.3)
        end

        c1 = circle!(l, bigcirc, Fill(a_fill(t))) do c
            Circle(at_angle(c, a_ang(t)), 5)
        end

        ps = points!(l, c.rect, c1, Visible(true)) do r, c
            points = [P(r, x, y) for x in range(0, 1, length=15) for y in range(0, 1, length=15)]
            directions = directions = normalize.(points .→ c.center) .* 10
            colors = LCHuv.(70, 50, deg.(angle.(directions)))
            (points, Strokes(colors))
        end

        # colors = [LCHuv(60, magnitude(p), deg(angle(p))) for p in points]

        bps = bezierpaths(c1, ps, Linewidths(1), Strokes("transparent")) do c, ps

            directions = normalize.(ps.points .→ c.center) .* 10
            arros = arrow.(ps.points, ps.points .+ directions, 3, 3, 1, 1, 0)
            colors = LCHuv.(70, 50, deg.(angle.(directions)))
            (arros, Fills(colors))
        end

        pushfirst!(l, bps)

        draw(c, dpi=256)
    end
end

PyPlot.pygui(false)
testvideo()

PyPlot.close_figs()
