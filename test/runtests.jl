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
    ltop = Layer(Transform(), Markersize(20), Marker(:.), Fill("transparent"), Stroke("black"), Linewidth(1), Linestyle(:solid))
    lmiddle = Layer(Transform(rotation=rad(pi)))
    lbottom = Layer(Transform(translation=(1, 1)))
    push!(ltop, lmiddle)
    push!(lmiddle, lbottom)

    p1 = point(1, 1, Stroke("red"))
    p2 = point(10, 1)
    p3 = point(→, p1, p2)

    push!(lbottom, p1)
    push!(ltop, p2)
    push!(lmiddle, p3)

    c = circle(circlethrough, p1, p2, p3, Fill(RGBA(0.4, 0.3, 0.5, 0.2)))

    push!(lbottom, c)

    l = line(p1, c) do p1, c
        Line(p1, c.center)
    end
    push!(ltop, l)

    l2 = line(l, p3) do l, p3
        Line(fraction(l, 0.5), p3)
    end
    push!(lbottom, l2)

    rectlayers = Layer.(Transform.(range(0.5, 2, length=10), deg.(range(0, 20, length=10)), [(i*10, i*10) for i in 1:10] ))

    push!.(ltop, rectlayers)

    rects = rect.(Ref((0, 0)), 5, 4, deg(0), Fill.(LCHuvA.(60, 70, range(0, 360, length=11)[1:end-1], 0.3)))
    push!.(rectlayers, rects)
    push!.(rectlayers, point.(0, zeros(10)))
    push!.(ltop, line.((r1, r2) -> Line(r1.center, bottomleft(r2)), rects[1:end-1], rects[2:end]))

    fig, ax = PyPlot.subplots(1)
    draw(ltop)
    ax.axis("equal")
    display(fig)
    nothing
end

test()

PyPlot.close_figs()
