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

    svgstr = "M500,225.2c73.6,0,133.2,58.1,133.2,129.9c0,71.7-59.6,129.8-133.2,129.8c-73.6,0-133.2-58.1-133.2-129.8C366.8,283.4,426.4,225.2,500,225.2z M852.4,351.7C852.4,162,694.6,10,500,10c-194.6,0-352.4,151.2-352.4,340.8c0,3,0.4,6.5,0.5,6.5h-0.5C143,568.7,397.4,895.1,500,990c102.6-94.9,357-421.3,352.4-632.7h-0.5C852,357.3,852.4,354.7,852.4,351.7z"
    # svgstr = "M 509.18838,395.16009 C 491.67535,410.75205 468.29486,431.4073 437.98958,444.4974 326.88012,492.49442 195.81534,442.33805 145.83768,332.62845 116.00894,267.07372 120.77439,192.09233 157.48325,125.71854 194.41549,58.98735 267.83321,0 267.83321,0 c 0,0 -54.3857,11.64557 -102.50186,34.90693 C 61.02755,85.34624 0,191.09457 0,300.69993 c 0,40.89352 8.5629188,82.4274 26.597171,122.04021 32.688011,71.66046 91.377509,126.40357 165.376019,154.04318 74.05808,27.68429 154.26657,24.89948 226.00149,-7.74385 C 489.93299,536.23232 543.97617,475.1452 572.76247,401.6828 595.91958,342.69546 599.94043,276.60462 600,276.44081 c 0,0 -37.58749,71.19881 -90.81162,118.71928"

    # svgstr = "m61.1 18.2c-6.4-17-27.2-9.4-29.1-.9-2.6-9-22.9-15.7-29.1.9-6.9 18.5 26.7 35.1 29.1 37.8 2.4-2.2 36-19.6 29.1-37.8"
    c, l = canvas(4, 4)

    paths!(l, svgstr) do str
        p = scaleby(center(Path(svgstr)), 0.05)
        p .+ X.(-100:30:200)
    end + Fill(:frac => f -> LCHuv(70, 70, f * 360))

    c

end; pathtest()
