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
using Colors

function test2()
    c, l = canvas(4, 3)
    n = 5

    sls = layer!.((r, i) -> begin
        margin = 20
        avail_w = (r.width - 2margin) / n
        avail_h = (r.height - 2margin) / n
        Transform(translation = topleft(r) + P(margin + (i-0.5) * avail_w, margin + (i-0.5) * avail_h))
    end, l, c.rect, 1:n) .+ Opacity.(0.6:0.1:1)

    rs = rect!.((r, i) -> begin
        Rect(P(0, 0), 80, 50, deg(0))
    end, sls, c.rect, 0:n-1) .+ Fill(Gray(0.5)) .+ Visible(true)

    crosses = polygon!.(r -> begin
        ncross(r.center, 4, 3, 0.3)
    end, sls, rs) .+ Fill("black") .+ Stroke("transparent")

    circlesleft = circle!.(r -> begin
        Circle(r.center - X(r.width/4), 10)
    end, sls, rs) .+ Linestyle(:dashed)

    circlesright = circle!.(r -> begin
        Circle(r.center + X(r.width/4), 10)
    end, sls, rs) .+ Linestyle(:dashed)

    focuscircle = circle!.(r -> begin
        Circle(bottomleft(r) + P(35, -35), 30)
    end, l, c.rect) .+ Linestyle(:dashed)

    textl = layer!(l, Transform())

    text!.((r, phase) -> begin
        Txt(bottomleft(r) + Y(0), "phase $phase", 10, :l, :t, deg(0), "Helvetica")
    end, textl, rs, 1:5) .+ Fill("black")

    path!((c1, c2) -> begin
        Path(false, outertangents(c1, c2)...)
    end, l, focuscircle, circlesright[2]) + Linestyle(:dashed)

    arr = path!(l, rs[1], rs[end]) do r1, r2
        a = arrow(topright(r1), topright(r2), 9, 9, 1, 1, 0)
        a + normal(a.segments[1], -5)
    end + Fill("tomato") + Stroke("transparent")

    te = text!(l, arr) do arr
        pos = normfrom(arr.segments[1], 0.5, -3)
        Txt(pos, "time", 10, :c, :b, angle(arr.segments[1]), "Helvetica")
    end + Fill("black")

    rect!(l, te) do t
        Rect(t, 2.5)
    end + Stroke("tomato")

    c
end; test2()


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

    text!(tl, circ) do c
        Txt(P(c, deg(-90), 0.5), "Hello", 20, :c, :c, deg(0), "Helvetica Neue Light")
    end + Fill("black")

    # write_to_png(c, "transformtest.png")
    c

end; transformtest()

function transtest()

    c, tl = canvas(5, 5)

    l1 = rectlayer!(tl, c.rect, :h)

    pinky = circle!(l1, P(-0.5, 0), 0.2) + Stroke("red") + Linewidth(1)

    l2 = layer!(l1, Transform(rotation=deg(-45), translation=X(100)))

    l3 = layer!(l2, Transform(scale=2, translation=Y(-50)))

    pinkyclone = circle!(l3, pinky) do pin
        pin
    end + Fill("transparent") + Stroke("black") + Linestyle(:dashed)

    pinkyclone2 = circle!(tl, pinkyclone) do pin
        grow(pin, 1)
    end + Fill("transparent") + Stroke("green") + Linestyle(:dashed)

    # write_to_png(c, "transtest.png")

    # Layered.preview(c)
    c

end; transtest()

using Pkg
pkg"activate ."
using Revise
using Layered
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


function theresa()

    c, l = canvas(3, 3, bgcolor=LCHuv(20, 30, 240))

    text!(l, P(0, 0), "Morning", 40, :c, :c, deg(0), "Helvetica") +
        Fill(LCHuv(18, 30, 240))

    c

end; theresa()
