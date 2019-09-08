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

    te = text!(tl, circ) do c
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


function petals()

    c, tl = canvas(5, 5)

    l = rectlayer!(tl, c.rect, :w, margin=20)

    degrees = range(0, 360, length=21)[1:end-1]

    petals = path!.(ang -> begin
        endpoint = P(ang)
        Path(true, Arc(O, endpoint, 0.2), Arc(endpoint, O, 0.2))
    end, l, deg.(degrees)) .+ Fill.(LCHuv.(70, 50, degrees)) .+ Stroke("transparent") .+ Operator(:mult)

    circ = circle!(l, O, 0.2) + Visible(false)

    petals .+ Clip(circ, c.rect)

    c

end; petals()

function tpoints()

    c, tl = canvas(4, 4)

    l = rectlayer!(tl, c.rect, :w, :norm, margin=40)

    rect!(l, P(.5, .5), 1, 1, deg(0)) + Linewidth(1)

    ps = point!.(l, grid(0:0.1:1, 0:0.1:1)...) .+
        Fill("red") .+ Markersize(10) .+ Marker(:+) .+ Stroke(nothing)

    c

end; tpoints()
