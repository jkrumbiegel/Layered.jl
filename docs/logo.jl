function makelogo()

    defaultfont("Helvetica Neue Bold")

    c, l = canvas(92, 92, color = "transparent")

    colors = Colors.JULIA_LOGO_COLORS

    rect!(l, O, 92, 92) + Fill(colors.blue) + Stroke(nothing)

    layers = map(P.([-34, 0, 28], [-5, 0, 11]), -15:15:15, [1.1, 1.0, 0.9]) do p, ang, scale
        layer(translation = p + X(5), rotation = deg(ang), scale = scale)
    end .+ Opacity(0.9)

    for ll in reverse(layers)
        push!(l, ll)
    end


    map(layers) do l
        rect!(l, O, 35, 35)
    end .+ Fill.([colors.red, colors.green, colors.purple])

    textparts = ["Lay", "ere", "d.jl"]
    map(layers, textparts) do l, t
        txt!(l, O, t, 11, :c, :c)
    end .+ Textfill("white")

    circ = circle!(l, O, 45) + Invisible
    l + Clip(circ)

    c
    mkdir("assets")

    Layered.png(c, "assets/logo.png", px_per_pt = 3)
    Layered.svg(c, "assets/logo.svg")
end