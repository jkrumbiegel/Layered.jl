using Layered
using Test
using FileIO

generate_images = false
originalimagepath(str) = joinpath("original_images", str)
testimagepath(str) = joinpath("test_images", str)

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
    if generate_images
        png(c, originalimagepath(filename); dpi=100)
    else
        png(c, testimagepath(filename); dpi=100)
        testimg = load(testimagepath(filename))
        originalimg = load(originalimagepath(filename))
        @test testimg == originalimg
    end
end

@testset "image_circle_1" begin
    c, tl = canvas(1, 1)
    circle!(tl, O, 25) + Fill("orange") + Stroke("black") + Linewidth(5)

    filename = "image_circle_1.png"
    if generate_images
        png(c, originalimagepath(filename); dpi=100)
    else
        png(c, testimagepath(filename); dpi=100)
        testimg = load(testimagepath(filename))
        originalimg = load(originalimagepath(filename))
        @test testimg == originalimg
    end
end
