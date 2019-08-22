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
    l = Layer(Transform(), Markersize(20), Marker(:.), Fill("transparent"), Stroke("black"), Linewidth(1), Linestyle(:solid))
    l2 = Layer(Transform(2, deg(15), (2, 2)))
    push!(l, l2)

    r1 = rect((0, 0), 10, 5, deg(0))
    n = 5
    rs = rect.([(30, (y - (n+1)/2) * 10) for y in 1:n], 10, 5, deg(0), Fill.(LCHuv.(90, 10, range(0, 360, length=n+1)[1:end-1])))
    bs = bezier.(
        [
            (r1, r2) -> horizontalbezier(fraction(rightline(r1), (i-1)/(n-1)), fraction(leftline(r2), 0.5))
        for i in 1:n],
        r1, rs)

    push!(l2, r1)
    push!.(l, rs)
    push!.(l, bs)

    c1 = circle(r1) do r1
        Circle((0, 0), r1.height / 2 - 1)
    end

    c2 = circle(r1) do r1
        Circle((0, 0), r1.height / 2 - 1)
    end

    push!(l, c1)
    push!(l2, c2)

    fig, ax = PyPlot.subplots(1)
    draw(l)
    ax.axis("equal")
    display(fig)
    nothing
end

test()

PyPlot.close_figs()
