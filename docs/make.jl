using Documenter, TowSty

makedocs(;
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    authors = "J. Morvan <morvan.josselin@gmail.com>",
    pages = [
        "TowSty.jl" => "index.md",
    ],
    sitename = "TowSty.jl"
)


deploydocs(
    repo = "github.com/juliadh/TowSty.jl.git",
)
