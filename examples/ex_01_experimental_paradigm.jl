using Pkg
pkg"activate ."
using Revise
using Layered
using Colors


function example()
    c, l = canvas(4.5, 3)
    n = 5

    defaultfont("Helvetica Neue Light")

    sls = layer!.((r, i) -> begin
        margin = 20
        avail_w = (r.width - 2margin) / n
        avail_h = (r.height - 2margin) / n
        Transform(translation = topleft(r) + P(margin + (i-0.5) * avail_w, margin + (i-0.5) * avail_h))
    end, l, c.rect, 1:n)

    rs = rect!.((r, i) -> begin
        Rect(P(0, 0), 80, 50, deg(0))
    end, sls, c.rect, 0:n-1) .+ Fill(Gray(0.5)) .+ Visible(true)

    crosses = polygon!.(r -> begin
        ncross(r.center, 4, 3, 0.3)
    end, sls, rs) .+ Fill("black") .+ Stroke("transparent")

    circlesleft = circle!.(r -> begin
        Circle(r.center - X(r.width/4), 10)
    end, sls, rs) .+ Linestyle(:dashed) .+
        Stroke.([i == 2 ? "lime" : "black" for i in 1:n])

    circlesright = circle!.(r -> begin
        Circle(r.center + X(r.width/4), 10)
    end, sls, rs) .+ Linestyle(:dashed) .+
        Stroke.([i == 4 ? "tomato" : "black" for i in 1:n])

    focuscircle = circle!(r -> begin
        Circle(topright(r) + P(-35, 35), 30)
    end, l, c.rect) + Linestyle(:dashed)

    textl = layer!(l, Transform())

    phases = txt!.((r, phase) -> begin
        Txt(bottomleft(r) + Y(0), "phase $phase", 10, :l, :t)
    end, textl, rs, 1:5)

    path!((c1, c2) -> begin
        Path(false, outertangents(c1, c2)...)
    end, l, focuscircle, circlesright[4]) + Opacity(0.3)#+ Linestyle(:dashed)

    arr = path!(l, rs[1], rs[end]) do r1, r2
        a = arrow(topright(r1), topright(r2), 9, 9, 1, 1, 0)
        a + normal(a.segments[1], -5)
    end + Fill("tomato") + Stroke("transparent")

    te = txt!(textl, arr) do arr
        pos = normfrom(arr.segments[1], 0.5, -4)
        Txt(pos, "time", 10, :c, :b, angle(arr.segments[1]))
    end

    r = rect_pre!(textl, te, te) do t
        Rect(t, 4)
    end + Fill("tomato") + Stroke("transparent")

    txt!(textl, focuscircle) do fc
        Txt(fc.center, "focus circle", 10, :c, :c)
    end

    txt!(textl, c.rect) do r
        Txt(bottomleft(r) + P(5, -5), "experimental paradigm", 12, :l, :b)
    end

    c

    # draw_svg(c, "example.svg")

end; example()
