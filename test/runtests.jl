using Layered
using Test
using FileIO
using Colors

generate_images = false
originalimagepath(str) = joinpath("original_images", str)
testimagepath(str) = joinpath("test_images", str)

if !isdir("test_images/")
    mkdir("test_images/")
end

function test_or_generate_png(surface, filename)
    if generate_images
        png(surface, originalimagepath(filename); dpi=100)
    else
        png(surface, testimagepath(filename); dpi=100)
        testimg = load(testimagepath(filename))
        originalimg = load(originalimagepath(filename))
        @test testimg == originalimg
    end
end

@testset "geometry" begin
    p1 = Point(0, 0)
    x1 = X(0)
    y1 = Y(0)
    @test p1 == x1
    @test p1 == y1

    p2 = P(3, 5.5)
    x2 = X(3)
    y2 = Y(5.5)
    @test p2 == x2 + y2

    p3 = P(-3, 5.5)
    @test p3 == y2 - x2

    p4 = P(1, 1)
    p5 = P(3, 5)
    v = p5 - p4
    @test v == P(2, 4)
    l = Line(p4, p5)
    @test vector(l) == v
    @test length(l) == magnitude(v) == sqrt(2 ^ 2 + 4 ^ 2)
    @test direction(l) == v ./ length(l)
    @test l * 3 == Line(P(3, 3), P(9, 15))
    @test l / 2 == Line(P(0.5, 0.5), P(1.5, 2.5))
end

@testset "image_lines_1" begin
    c, tl = canvas(1, 1)
    l = layer_in_rect!(tl, c.rect, :w; margin=5)
    line!(l, P(-1,  -1), P(1,  -1)) + Stroke("red") + Linewidth(2)
    line!(l, P(-1,  -0.8), P(1,  -0.8)) + Stroke("blue") + Linewidth(3)
    line!(l, P(-1,  -0.6), P(1,  -0.6)) + Stroke("green") + Linewidth(4)

    filename = "image_lines_1.png"
    test_or_generate_png(c, filename)
end

@testset "image_circle_1" begin
    c, tl = canvas(1, 1)
    circle!(tl, O, 25) + Fill("orange") + Stroke("black") + Linewidth(5)

    filename = "image_circle_1.png"
    test_or_generate_png(c, filename)
end

@testset "petals" begin

    c, tl = canvas(4, 4)

    l = layer_in_rect!(tl, c.rect, :w, margin=30)

    degrees = range(0, 360, length=21)[1:end-1]

    petals = path!.(ang -> begin
        ang
        endpoint = P(ang)
        segments = [Arc(O, endpoint, 0.2), Arc(endpoint, O, 0.2)]
        Path(segments)
    end, l, deg.(degrees)) .+ Stroke.(LCHuv.(70, 50, degrees)) .+ Linewidth(10) .+
        Fill.(LCHuvA.(70, 50, degrees, 0.5)) .+ Operator(:mult)

    circ = circle!(l, O, 0.25) + Visible(false)

    l + Clip(circ, c.rect)

    filename = "image_petals.png"
    test_or_generate_png(c, filename)
end

@testset "gradients" begin

    c, tl = canvas(1, 1)

    l = layer_in_rect!(tl, c.rect, :w) + Stroke(nothing)

    rect!(l, P(-0.5, -0.5), 1, 1, deg(0)) + Fill(Gradient(P(-1, -1), O, "red", "blue"))
    rect!(l, P(0.5, -0.5), 1, 1, deg(0)) + Fill(Gradient(P(1, -1), O, "yellow", "green", "orange"))
    rect!(l, P(-0.5, 0.5), 1, 1, deg(0)) + Fill(RadialGradient(O, 1, RGB(1, 0, 1), RGB(0, 1, 0)))
    rect!(l, P(0.5, 0.5), 1, 1, deg(0)) + Fill(RadialGradient(O, 0.3, 1.41, RGB(1, 0, 0), RGB(0, 1, 1)))

    filename = "image_gradients.png"
    test_or_generate_png(c, filename)

end

@testset "svg to path" begin
    c, tl = canvas(1, 1)

    l = layer_in_rect!(tl, c.rect, :w; margin=10)

    headsvg = open("head.svg") do file
        content = join(readlines(file))
        split(split(content, "<path d=\"")[2], "\"/>")[1]
    end

    headpath = centeredin(Path(headsvg), 2)

    path!(l, headpath) + Fill("black")

    filename = "image_headsvg_path.png"
    test_or_generate_png(c, filename)
end
