using Documenter, TowSty

makedocs(;
  format = Documenter.HTML(;
    prettyurls = get(ENV, "CI", nothing) == "true"
  ),
  authors = "J. Morvan <josselin.morvan@univ-rouen.fr>, \nJ. Dehut <julien.dehut@univ-rouen.fr>",
  pages = [
    "TowSty" => "index.md",
    "Getting started" => "gettingstarted.md"
  ],
  sitename = "Guide - TowSty",
  repo = "https://gitlab.huma-num.fr/ceen/towsty/towsty.jl"
  #remotes=nothing
)


