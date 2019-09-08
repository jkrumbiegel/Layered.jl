export grid

function grid(xiter, yiter)
    xs = (x for x in xiter, _ in yiter)
    ys = (y for _ in xiter, y in yiter)
    xs, ys
end
