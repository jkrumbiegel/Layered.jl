using Documenter
using Layered

makedocs(
    sitename = "Layered",
    format = Documenter.HTML(),
    pages = [
        "Start" => "index.md",
        "Tutorial" => "tutorial.md",
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
