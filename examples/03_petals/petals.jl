using Pkg
pkg"activate ."
using Revise
using Layered
using Colors


function petals()

    c, tl = canvas(4, 4)

    l = rectlayer!(tl, c.rect, :w, margin=30)

    degrees = range(0, 360, length=21)[1:end-1]

    petals = path!.(ang -> begin
        endpoint = P(ang)
        Path(true, Arc(O, endpoint, 0.2), Arc(endpoint, O, 0.2))
    end, l, deg.(degrees)) .+ Stroke.(LCHuv.(70, 50, degrees)) .+ Linewidth(10) .+
        Fill.(LCHuvA.(70, 50, degrees, 0.5)) .+ Operator(:mult)

    circ = circle!(l, O, 0.25) + Visible(false)

    l + Clip(circ, c.rect)

    draw_svg(c, "./examples/03_petals/petals.svg")
    # c

end; petals()
