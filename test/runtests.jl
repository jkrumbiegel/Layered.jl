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
using Layered
import PyPlot
using Colors


function test()
    l = layer(Transform(), Markersize(20), Marker(:.), Fill("transparent"), Stroke("black"), Linewidth(1), Linestyle(:solid))
    l2 = layer!(l, Transform(2, deg(10), (2, 2)))

    n = 5

    r1 = rect!(l2, (0, 0), 10, 5, deg(0))
    rs = rect!.(l, [(30, (y - (n+1)/2) * 10) for y in 1:n], 10, 5, deg(0), Fill.(LCHuv.(90, 10, range(0, 360, length=n+1)[1:end-1])))
    bs = bezier!.(
        l,
        [
            (r1, r2) -> perpendicularbezier(rightline(r1), leftline(r2), (i-1)/(n-1), 0.5, reverse1=true)
        for i in 1:n],
        r1, rs)

    c1 = circle!(l, r1) do r1
        Circle((0, 0), r1.height / 2 - 1)
    end

    c2 = circle!(l2, r1) do r1
        Circle((0, 0), r1.height / 2 - 1)
    end

    fig, ax = PyPlot.subplots(1)
    draw(l)
    ax.axis("equal")
    display(fig)
    nothing
end

test()

PyPlot.close_figs()

function test2()
    l = layer(Transform(), Markersize(20), Marker(:.), Fill("transparent"), Stroke("black"), Linewidth(1), Linestyle(:solid))
    n = 5
    sls = layer!.(l, Transform.(range(1, 1.5, length=n), deg(0), ((i * 50 + i * 10, -i * 20) for i in 0:n-1)))

    rs = rect!.(sls, Ref((0, 0)), 70, 50, deg(0), Fill(GrayA(0.5, 0.8)))
    crosses = polygon!.((r -> ncross(r.center, 4, 3, 0.3)), sls, rs, Fill("black"))

    eye = circle!(l, rs[1], rs[end], Fill("white")) do r1, r2
        p = intersection(leftline(r1), bottomline(r2))
        Circle(p, 20)
    end

    iris = circle!(l, eye, Fill("rosybrown3"), Stroke("transparent")) do eye
        scalearea(eye, 0.3)
    end

    pupil = circle!(l, eye, Fill("black"), Stroke("transparent")) do eye
        scalearea(eye, 0.1)
    end

    # linesegments!(sls[1], pupil, cs[1]) do cc, c
    #     outertangents(cc, c)
    # end

    bezierpath!(l, rs[1], rs[end]) do r1, r2
        b = bracket(topright(r1), topright(r2), 0.1, 1, 2.5)
        move(b, perpendicular(Line(topright(r1), topright(r2))) * 5)
    end

    fig, ax = PyPlot.subplots(1)
    draw(l)
    ax.axis("equal")
    display(fig)
    nothing
end

test2()
