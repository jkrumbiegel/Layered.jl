export grid, gridrects

function grid(xiter, yiter)
    xs = (x for x in xiter, _ in yiter)
    ys = (y for _ in xiter, y in yiter)
    xs, ys
end

export LinAxis
struct LinAxis
    # rect::Rect
    xlim::Tuple{Float64, Float64}
    ylim::Tuple{Float64, Float64}
end

function LinAxis(xlim::Tuple{Real, Real}, ylim::Tuple{Real, Real}, xmargin, ymargin)
    xrange = xlim[2] - xlim[1]
    xlim_m = (xlim[1] - xmargin * xrange / 2, xlim[2] + xmargin * xrange / 2)
    yrange = ylim[2] - ylim[1]
    ylim_m = (ylim[1] - ymargin * yrange / 2, ylim[2] + ymargin * yrange / 2)
    LinAxis(xlim_m, ylim_m)
end

function (a::LinAxis)(r::Rect, p::Point)
    xscaled = (p.x - a.xlim[1]) / (a.xlim[2] - a.xlim[1])
    yscaled = (p.y - a.ylim[1]) / (a.ylim[2] - a.ylim[1])
    P(r, xscaled, yscaled)
end

function (a::LinAxis)(r::Rect, x, y)
    xscaled = (x - a.xlim[1]) / (a.xlim[2] - a.xlim[1])
    yscaled = (y - a.ylim[1]) / (a.ylim[2] - a.ylim[1])
    P(r, xscaled, yscaled)
end

Base.Broadcast.broadcastable(a::LinAxis) = Ref(a)


function gridrects(r::Rect, nrows, ncols, margins, rowgaps, colgaps, height_ratios, width_ratios)
    w = r.width
    h = r.height

    colswidth = (w - margins[1] - margins[3] - sum(colgaps))
    rowsheight = (h - margins[2] - margins[4] - sum(rowgaps))

    colwidths = width_ratios .* colswidth / sum(width_ratios)
    rowheights = height_ratios .* rowsheight / sum(height_ratios)

    xcenters = margins[1] .+ cumsum(colwidths) .- (colwidths ./ 2) .+ cumsum([0, colgaps...]) .+ r.center.x .- (r.width / 2)
    ycenters = margins[2] .+ cumsum(rowheights) .- (rowheights ./ 2) .+ cumsum([0, rowgaps...]) .+ r.center.y .- (r.height / 2)

    centers = P.(grid(xcenters, ycenters)...)

    Rect.(centers, grid(colwidths, rowheights)..., deg(0))
end

function gridrects(r::Rect, nrows, ncols, margin, rowgap, colgap)
    gridrects(
        r, nrows, ncols,
        [margin for _ in 1:4],
        [rowgap for _ in 1:nrows-1],
        [colgap for _ in 1:ncols-1],
        [1 for _ in 1:nrows],
        [1 for _ in 1:ncols])
end
