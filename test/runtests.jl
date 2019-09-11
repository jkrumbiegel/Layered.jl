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


function transformtest()

    c, tl = canvas(4, 4)

    l = layer!(tl, c.rect) do r
        d = min(r.width, r.height)
        Transform(translation=r.center, scale=(d-20)/2, rotation=r.angle)
    end

    line!(tl, P(0, 0), P(100, 0))

    circ = circle!(l, P(0, 0), 1) + Fill(Gradient(X(-1), X(1), "green", "yellow"))

    polygon!(l, circ) do c
        poly = Polygon(P.(c, deg.([0, 50, 150])))
        f = Fill(Gradient(poly.points[1:2:3]..., "red", "blue"))
        (poly, f)
    end

    te = txt!(tl, circ) do c
        Txt(P(c, deg(-90), 0.5), "Hello", 20, :c, :c, deg(0), "Helvetica Neue Light")
    end + Fill("black")

    # write_to_png(c, "transformtest.png")
    c

end; transformtest()


using Pkg
pkg"activate ."
using Revise
using Layered
using Colors
import Cairo
const C = Cairo

function Transform(cm::Cairo.CairoMatrix)
    trans = P(cm.x0, cm.y0)
    x = P(cm.xx, cm.yx)
    y = P(cm.xy, cm.yy)
    rot = signed_angle_to(X(1), x)
    scale = magnitude(x)
    Transform(scale, rot, trans)
end

function transinvestigation()

    c = C.CairoARGBSurface(100, 100);
    cc = C.CairoContext(c);

    l1 = layer(Transform())
    l2 = layer!(l1, Transform(scale=2, rotation=deg(90), translation=P(1, 1)))
    l3 = layer!(l2, Transform(scale=0.5, rotation=deg(-50), translation=P(-0.5, 0.5)))
    l4 = layer!(l3, Transform(scale=3, rotation=deg(40), translation=P(3, 0)))

    # p = point!()

    applytransform!(cc, l1.transform)
    applytransform!(cc, l2.transform)
    applytransform!(cc, l3.transform)
    applytransform!(cc, l4.transform)

    Juno.clearconsole()

    m = C.get_matrix(cc)
    @show Transform(m)
    @show upward_transform(l4)

    C.finish(c)

end; transinvestigation()


function fontaliasing()

    c = C.CairoARGBSurface(100, 100);
    cc = C.CairoContext(c);

    font_options_ptr = ccall((:cairo_font_options_create, C.libcairo), Ptr{Nothing}, ())

    CAIRO_HINT_STYLE_NONE = 1
    ccall((:cairo_font_options_set_hint_style, C.libcairo), Nothing, (Ptr{Nothing}, Int32), font_options_ptr, CAIRO_HINT_STYLE_NONE)

    ccall((:cairo_set_font_options, C.libcairo), Nothing, (Ptr{Nothing}, Ptr{Nothing}), cc.ptr, font_options_ptr)

    ccall((:cairo_font_options_destroy, C.libcairo), Nothing, (Ptr{Nothing},), font_options_ptr)

    C.finish(c)

end; fontaliasing()


function tpoints()

    c, tl = canvas(4, 4)

    l = rectlayer!(tl, c.rect, :w, :norm, margin=40)

    rect!(l, P(0.5, 0.5), 2, 2, deg(0)) +
        Fill(Gradient(P(0, 0), P(0, 1), LCHuv.(40, 20, -120:40)...))

    ls = lines!(l, P.(0, 0:0.05:1), P.(1, 0:0.05:1)) +
        Stroke(:frac => f -> LCHuv(30, 25, -140 + f * 100)) +
        Linewidth(8)

    circ = circle!(l, P(0.5, 0.5), 0.5) + Invisible

    ls + Clip(circ)

    c

end; tpoints()


function polys()

    c, tl = canvas(4, 4)

    l = rectlayer!(tl, c.rect, :h, :norm, margin=40)

    n = 6
    polygons!(
        l,
        grid(range(0, 1, length=n), range(0, 1, length=n))...,
        grid(1:n, range(0.1, 0.5, length=n))...) do x, y, i, d
            Polygon.(ncross.(P.(x, y), i .+ 2, 0.03, d))
    end +
        Stroke(nothing) +
        Fill(:frac => f -> LCHuv(60, 40, f * 360))

    c

end; polys()


Path("M 165.097656 39.6875 L 165.097656 40.3125 L 159.503906 40.3125 L 162.992188 44.683594 L 162.503906 45.074219 L 159.015625 40.699219 L 157.773438 46.152344 L 157.164062 46.015625 L 158.410156 40.5625 L 153.371094 42.988281 L 153.101562 42.425781 L 158.136719 40 L 153.101562 37.574219 L 153.371094 37.011719 L 158.410156 39.4375 L 157.164062 33.984375 L 157.773438 33.847656 L 159.015625 39.300781 L 162.503906 34.925781 L 162.992188 35.316406 L 159.503906 39.6875 Z M 165.097656 39.6875 ")
Path("M500,225.2c73.6,0,133.2,58.1,133.2,129.9c0,71.7-59.6,129.8-133.2,129.8c-73.6,0-133.2-58.1-133.2-129.8C366.8,283.4,426.4,225.2,500,225.2z M852.4,351.7C852.4,162,694.6,10,500,10c-194.6,0-352.4,151.2-352.4,340.8c0,3,0.4,6.5,0.5,6.5h-0.5C143,568.7,397.4,895.1,500,990c102.6-94.9,357-421.3,352.4-632.7h-0.5C852,357.3,852.4,354.7,852.4,351.7z")


function pathtest()

    # svgstr = "M500,225.2c73.6,0,133.2,58.1,133.2,129.9c0,71.7-59.6,129.8-133.2,129.8c-73.6,0-133.2-58.1-133.2-129.8C366.8,283.4,426.4,225.2,500,225.2z M852.4,351.7C852.4,162,694.6,10,500,10c-194.6,0-352.4,151.2-352.4,340.8c0,3,0.4,6.5,0.5,6.5h-0.5C143,568.7,397.4,895.1,500,990c102.6-94.9,357-421.3,352.4-632.7h-0.5C852,357.3,852.4,354.7,852.4,351.7z"
    # svgstr = "M 509.18838,395.16009 C 491.67535,410.75205 468.29486,431.4073 437.98958,444.4974 326.88012,492.49442 195.81534,442.33805 145.83768,332.62845 116.00894,267.07372 120.77439,192.09233 157.48325,125.71854 194.41549,58.98735 267.83321,0 267.83321,0 c 0,0 -54.3857,11.64557 -102.50186,34.90693 C 61.02755,85.34624 0,191.09457 0,300.69993 c 0,40.89352 8.5629188,82.4274 26.597171,122.04021 32.688011,71.66046 91.377509,126.40357 165.376019,154.04318 74.05808,27.68429 154.26657,24.89948 226.00149,-7.74385 C 489.93299,536.23232 543.97617,475.1452 572.76247,401.6828 595.91958,342.69546 599.94043,276.60462 600,276.44081 c 0,0 -37.58749,71.19881 -90.81162,118.71928"

    # svgstr = "m61.1 18.2c-6.4-17-27.2-9.4-29.1-.9-2.6-9-22.9-15.7-29.1.9-6.9 18.5 26.7 35.1 29.1 37.8 2.4-2.2 36-19.6 29.1-37.8"

    # svgstr = "M95.365,16.12c-1.311-1.072-4.964-3.813-4.964-3.813s-1.668-3.614-3.177-4.527c0,0,1.144-0.737,1.509-2.303 c0.556-2.383,0.318-4.686-0.979-5.322c-1.297-0.635-4.955,0.926-9.055,0.397c-4.925-0.635-10.031-0.06-12.907,4.964 c-2.979,5.203-6.95,6.95-8.936,12.113c-1.642,4.269-1.382,9.293-1.382,9.293s-15.975,7.02-19.428,7.387 c-2.255,0.239-7.387,0.477-12.287,4c-2.621,1.957-7.315,2.859-10.286,1.084c-3.257-1.946-2.888-5.86,1.033-8.261 c3.892-2.383,7.784-0.794,12.374,0.016c2.936,0.518,7.884,1.289,10.104-0.85c2.184-2.105,0.524-5.314-2.923-8.014 c-0.318-1.477-1.882-2.748-3.908-3.026c-2.758-0.379-7.069,1.628-10.246,1.946c2.423,1.708,4.289,2.939,7.03,3.733 c2.814,0.816,4.091,0.437,5.917-0.516c1.509,0.874,3.217,2.423,2.343,3.614c-0.743,1.013-2.767,1.1-4.885,0.715 c-5.369-0.976-11.191-3.375-17.157-0.874c-6.156,2.582-8.452,9.208-4.21,14.377c3.168,3.553,8.896,3.733,8.896,3.733 s-3.641,2.841-6.927,10.167c-1.382,3.082-6.312,5.014-8.737,5.957c-1.43,0.556-1.144,2.367-1.191,2.78 C0.945,65.236,0,75.914,0,75.914l2.772,4.067h6.696c-0.302-3.495-4.178-4.877-4.178-4.877l1.652-7.514c0,0,7.069-2.065,9.929-3.495 c3.704-1.852,6.91-5.322,6.91-5.322l1.747-0.318c0,0,0.56,0.556,0.635,3.098c0.079,2.669-0.922,5.446-1.144,6.577 c-0.175,0.89,0.111,1.207,1.303,2.319c1.191,1.112,7.578,7.546,7.578,7.546h7.435c-0.461-3.971-5.004-4.805-5.004-4.805 l-4.845-4.488L36.728,57.9c4.866-0.33,6.291,0.495,9.532,0.556c3.368,0.063,5.401-0.715,5.401-0.715s-0.827,9.186-0.874,9.468 c-0.159,0.953,0.111,1.493,0.175,1.684c0.129,0.386,3.558,9.103,3.558,9.103h8.419c-0.397-3.892-4.956-5.163-4.956-5.163 l-0.763-4.766l3.971-11.358c1.525-0.127,3.018-0.556,3.018-0.556s-0.516,11.519-0.556,11.914c-0.079,0.794,0.048,1.017,0.238,1.461 c0.135,0.314,5.404,10.453,5.404,10.453h8.401c-0.556-3.971-4.988-5.163-4.988-5.163l-1.732-5.56l3.743-15.468 c0,0,9.076-9.493,11.324-12.447c2.511-3.3,2.688-6.16,2.688-9.972c0-2.145,1.271-3.495,1.271-3.495s2.61,0.319,3.177,0.119 c1.509-0.532,2.621-7.427,2.621-7.427s0.874-0.758,1.152-2.145C97.112,17.629,96.676,17.192,95.365,16.12"

    svgstr = "M81.4,243.7c2-4.5,4.2-8.9,6.7-13.2c1-1.8,2.2-3.5,3.3-5.3c2.8-4.3,6.8-6.9,11.6-8.3c2.8-0.8,4.5-2.4,5.4-5.2
		c1.6-5.1,3.1-10.2,3.7-15.5c0.2-1.3,0.1-2.7,0-4c-0.3-4.3,0.8-8.2,2.9-11.8c0.5-0.9,0.9-1.9,1.2-2.9c0.3-1.2-0.2-1.9-1.3-2.2
		c-1.8-0.6-3.7-0.6-5.5-0.7c-4.7-0.3-9.4-0.5-14.1-1.4c-5-1.1-7.6-5-6.8-10.1c0.2-1.1,0.3-2.3,0.4-3.4c0.1-1.9-0.4-3.7-1.5-5.3
		c-1.3-1.8-1.1-3.6,0.3-5.2c0.3-0.4,0.2-0.5-0.2-0.7c-1.5-0.5-2.4-1.7-3.2-3c-0.8-1.5-0.7-2.5,0.6-3.6c1.5-1.2,1.1-2.8,1.2-4.3
		c0-0.5-0.5-0.3-0.8-0.4c-2.4-0.1-4.7-0.7-6.7-2.1c-1-0.7-1.4-1.6-1.3-2.8c0.1-2.2,0.7-4.2,2.3-5.8c2.6-2.5,4-5.7,6.1-8.5
		c1-1.3,2.1-2.6,3.3-3.7c1.1-1,1.9-2.3,2.5-3.7c0.6-1.4,0.6-2.9-0.3-4c-2.1-2.7-2.1-5.5-1.2-8.5c2.2-7.8,4.4-15.7,8.2-22.9
		c3.2-6.1,8-10.7,13.8-14.3c7.7-4.8,16.1-7.1,25.1-7.4c11.2-0.4,22,1.7,32.2,6.3c6.5,2.9,12.2,7.2,17.2,12.2
		c6.8,6.8,11,14.9,12.8,24.4c0.9,4.9,0.8,9.8,0.6,14.7c-0.3,5.8-1.3,11.4-3.3,16.8c-1.4,3.7-3.2,7.2-5.7,10.2
		c-3.6,4.3-5.8,9.2-7.1,14.6c-1.8,7.2-3.9,14.3-4.7,21.7c-0.7,6.5-1.1,13.1,0.5,19.6c1.1,4.3,3.7,7.9,6.3,11.4
		c2.3,3.1,5.1,5.8,7.8,8.5c4.8,4.9,9.2,10.1,13.8,15.2c4.1,4.6,7.7,9.4,10.8,14.7"

    c, tl = canvas(4, 4)

    l = rectlayer!(tl, c.rect, :h, margin=0)

    p = centeredin(Path(svgstr), 1)

    # p = Path(svgstr)

    head = path!(l, p) do p
        p
        # Path([Move(O), Lineto(P(1, 0)), Lineto(P(0.5, 1)), Close()])
    end


    # sines = paths!(l) do
    #     xs = (-1:0.01:1)
    #     xs = xs
    #     ys = sin.(xs .* 8π) .* 0.05
    #
    #     ps = P.(xs, ys)
    #
    #     p = Path([Line(a, b) for (a, b) in zip(ps[1:end-1], ps[2:end])], false)
    #     pths = p .+ Y.(-1:0.02:1)
    #     pths .+ X.(rand(length(pths)) * 0.1)
    # end + Clip(head) + Stroke(:frac => f -> LCHuv(50, 40, f * 360)) + Linewidth(0.5)

    # ls = lines!(l, P.(-1, -3:0.04:1), P.(1, -2:0.04:2)) + Linewidth(1) + Clip(lion)

    c

end; pathtest()
