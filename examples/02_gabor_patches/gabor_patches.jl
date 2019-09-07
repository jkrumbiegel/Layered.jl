using Pkg
pkg"activate ."
using Revise
using Layered
using Colors


function example()
    c, tl = canvas(5, 5, bgcolor=Gray(0.5))

    l = rectlayer!(tl, c.rect, :w, :norm, margin=10)

    gaussian(x, μ, σ²) = 1 / √(2 * π * σ²) * exp(-(x - μ)^2 / (2σ²))
    scaled_gaussian(x) = (gaussian(x, 0, 1) - gaussian(1, 0, 1)) / (gaussian(0, 0, 1) - gaussian(1, 0, 1))

    nfreqs=6
    basefreqs = range(2, 10, length=nfreqs)
    ndegs = 6
    basedegs = range(0, 180, length=ndegs+1)[1:end-1]

    freqs = [f for f in basefreqs, d in basedegs]
    degs = [d for f in basefreqs, d in basedegs]

    rlayers = [layer!(l, Transform()) for f in freqs]

    rs = rect!.((i, j, freq, d) -> begin
        p = P((i - 0.5) / nfreqs, (j - 0.5) / ndegs)
        r = Rect(p, 1/nfreqs, 1/ndegs, deg(0))

        gfrom = r.center + P(deg(d)) * r.width/2
        gto = r.center - P(deg(d)) * r.width/2
        grad = Gradient(gfrom, gto, Gray.(sin.(range(0, freq*pi, length=50)) .* 0.5 .+ 0.5)...)
        r, Fill(grad)
    end, rlayers, 1:nfreqs, reshape(collect(1:ndegs), 1, :), freqs, degs)


    circs = circle!.((r, freq, d) -> begin
        radius = r.width * 0.4
        c = Circle(r.center, radius)

        alphas = scaled_gaussian.(range(1, 0, length=50))

        grad = RadialGradient(Circle(r.center, 0), Circle(r.center, radius), GrayA.(0.5, alphas)...)

        c, Fill(grad)

    end, rlayers, rs, freqs, degs) .+ Stroke(nothing)

    clipcircs = circle!.((c) -> begin
        scale(c, 0.99)
    end, rlayers, circs) .+ Visible(false)

    rs .+ Clip.(clipcircs)

    txt!.((r, f, d) -> begin
        Txt(center(topline(r)), "$f, $d", 6, :c, :t)
    end, tl, rs, freqs, degs)

    # rlayers .+ Operator(:mult)

    c

    draw_svg(c, "./examples/02_gabor_patches/gabors.svg")

end; example()
