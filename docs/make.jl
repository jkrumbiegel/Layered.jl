using Documenter
using Layered

makedocs(
    sitename = "Layered.jl",
    pages = [
        "Start" => "index.md",
        "Tutorial" => "tutorial.md",
    ],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    )
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/jkrumbiegel/Layered.jl.git",
)
